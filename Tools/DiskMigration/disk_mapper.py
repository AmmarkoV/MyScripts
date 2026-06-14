#!/usr/bin/env python3
"""
disk_mapper.py — Phase 1: Scan drives and build a file inventory database.

Install: pip install rich xxhash

Subcommands
  scan    Walk drives and record file metadata (fast, no hashing).
  hash    Compute file hashes.
            --smart   Only hash files that share (name, size) across drives —
                      dramatically faster than hashing everything.
            --drive   Restrict to one drive label.
  detect  Identify directories packed with many small files (frame dumps,
          tile sets, etc.) that should be packed as tarballs during migration.
  status  Show database summary.

Example
  python disk_mapper.py scan \\
      --drive Magician     /media/ammar/Magician          trusted \\
      --drive MAGICIAN16TB /media/ammar/MAGICIAN16TB      faulty  \\
      --drive CVRL2        /media/ammar/CVRL2             faulty  \\
      --drive CVRLDatasets /media/ammar/CVRLDatasets      faulty

  python disk_mapper.py detect
  python disk_mapper.py hash --smart
  python disk_mapper.py status
"""

import argparse
import hashlib
import os
import shutil
import sqlite3
import sys
import time
from collections import Counter, defaultdict
from pathlib import PurePosixPath

try:
    from rich.console import Console
    from rich.progress import (
        BarColumn,
        MofNCompleteColumn,
        Progress,
        SpinnerColumn,
        TaskProgressColumn,
        TextColumn,
        TimeRemainingColumn,
        TransferSpeedColumn,
    )
    from rich.table import Table
except ImportError:
    sys.exit("Install dependencies: pip install rich xxhash")

console = Console()
CHUNK      = 4 << 20  # 4 MiB read chunks
SKIP_DIRS  = {"lost+found", ".Trash-1000", "$RECYCLE.BIN", ".cache"}


# ── Schema ────────────────────────────────────────────────────────────────────

SCHEMA = """
CREATE TABLE IF NOT EXISTS drives (
    label       TEXT PRIMARY KEY,
    mount_point TEXT NOT NULL,
    is_trusted  INTEGER NOT NULL DEFAULT 0,
    total_bytes INTEGER,
    used_bytes  INTEGER,
    free_bytes  INTEGER,
    last_scan   REAL
);
CREATE TABLE IF NOT EXISTS files (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    drive_label   TEXT    NOT NULL,
    relative_path TEXT    NOT NULL,
    full_path     TEXT    NOT NULL,
    filename      TEXT    NOT NULL,
    size          INTEGER NOT NULL,
    mtime         REAL    NOT NULL,
    hash          TEXT,
    hash_error    TEXT,
    scan_time     REAL    NOT NULL,
    hash_time     REAL,
    UNIQUE (drive_label, relative_path)
);
CREATE TABLE IF NOT EXISTS frame_dirs (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    drive_label   TEXT    NOT NULL,
    relative_path TEXT    NOT NULL,
    file_count    INTEGER NOT NULL,
    total_size    INTEGER NOT NULL,
    dominant_ext  TEXT,
    ext_ratio     REAL,
    UNIQUE (drive_label, relative_path)
);
CREATE INDEX IF NOT EXISTS idx_size_name ON files (size, filename);
CREATE INDEX IF NOT EXISTS idx_hash      ON files (hash) WHERE hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_drive     ON files (drive_label);
"""


def open_db(path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.executescript(SCHEMA)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    return conn


# ── Helpers ───────────────────────────────────────────────────────────────────

def fmt_bytes(n: int) -> str:
    n = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def make_hasher():
    try:
        import xxhash
        return xxhash.xxh64()
    except ImportError:
        return hashlib.sha256()


# ── Scan ──────────────────────────────────────────────────────────────────────

def cmd_scan(args):
    conn = open_db(args.db)

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description:<38}"),
        MofNCompleteColumn(),
        TextColumn("files"),
        TextColumn("[dim]{task.fields[rate]:>14}"),
        console=console,
        refresh_per_second=4,
    ) as prog:
        for label, mount, trust in args.drive:
            is_trusted = trust.lower() == "trusted"
            try:
                usage = shutil.disk_usage(mount)
            except FileNotFoundError:
                console.print(f"[red]Mount point not found: {mount}")
                continue

            conn.execute("""
                INSERT INTO drives VALUES (?,?,?,?,?,?,?)
                ON CONFLICT(label) DO UPDATE SET
                    mount_point=excluded.mount_point,
                    is_trusted=excluded.is_trusted,
                    total_bytes=excluded.total_bytes,
                    used_bytes=excluded.used_bytes,
                    free_bytes=excluded.free_bytes,
                    last_scan=excluded.last_scan
            """, (label, mount, int(is_trusted),
                  usage.total, usage.used, usage.free, time.time()))
            conn.commit()

            task = prog.add_task(
                f"[green]Scanning {label}", total=None, completed=0, rate=""
            )
            batch  = []
            t0     = time.monotonic()
            n_done = 0

            for dirpath, dirnames, filenames in os.walk(mount, onerror=lambda _: None):
                dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
                for fn in filenames:
                    fp = os.path.join(dirpath, fn)
                    try:
                        st = os.stat(fp, follow_symlinks=False)
                        if not os.path.isfile(fp):
                            continue
                        rp = os.path.relpath(fp, mount)
                        batch.append((label, rp, fp, fn, st.st_size, st.st_mtime, time.time()))
                    except OSError:
                        pass

                    if len(batch) >= 500:
                        _flush(conn, batch)
                        n_done += len(batch)
                        elapsed = time.monotonic() - t0
                        rate = f"{n_done / elapsed:,.0f} files/s" if elapsed > 0 else ""
                        prog.advance(task, len(batch))
                        prog.update(task, rate=rate)
                        batch.clear()

            if batch:
                _flush(conn, batch)
                n_done += len(batch)
                prog.advance(task, len(batch))

            prog.update(
                task,
                description=f"[green]Done: {label}",
                total=n_done, completed=n_done, rate="",
            )

    conn.close()
    cmd_status(args)


def _flush(conn, batch):
    conn.executemany("""
        INSERT INTO files
            (drive_label, relative_path, full_path, filename, size, mtime, scan_time)
        VALUES (?,?,?,?,?,?,?)
        ON CONFLICT(drive_label, relative_path) DO UPDATE SET
            full_path=excluded.full_path, size=excluded.size,
            mtime=excluded.mtime, scan_time=excluded.scan_time
    """, batch)
    conn.commit()


# ── Hash ──────────────────────────────────────────────────────────────────────

def cmd_hash(args):
    conn = open_db(args.db)

    if args.smart:
        rows = conn.execute("""
            SELECT f.id, f.full_path, f.size, f.drive_label
            FROM   files f
            WHERE  f.hash IS NULL AND f.hash_error IS NULL
              AND  EXISTS (
                       SELECT 1 FROM files f2
                       WHERE  f2.filename     = f.filename
                         AND  f2.size         = f.size
                         AND  f2.drive_label != f.drive_label
                   )
            ORDER  BY f.drive_label, f.size DESC
        """).fetchall()
        label = "smart-hash: match candidates only"
    elif args.drive:
        rows = conn.execute("""
            SELECT id, full_path, size, drive_label
            FROM   files
            WHERE  drive_label = ? AND hash IS NULL AND hash_error IS NULL
            ORDER  BY size DESC
        """, (args.drive,)).fetchall()
        label = f"hash all on {args.drive}"
    else:
        rows = conn.execute("""
            SELECT id, full_path, size, drive_label
            FROM   files
            WHERE  hash IS NULL AND hash_error IS NULL
            ORDER  BY drive_label, size DESC
        """).fetchall()
        label = "hash all files"

    if not rows:
        console.print("[yellow]Nothing to hash — all candidates already processed.")
        conn.close()
        return

    total_bytes = sum(r[2] for r in rows)
    console.print(f"[bold]{label}[/]  ·  {len(rows):,} files  ·  {fmt_bytes(total_bytes)}")

    with Progress(
        TextColumn("[progress.description]{task.description:<58}"),
        BarColumn(),
        TaskProgressColumn(),
        TransferSpeedColumn(),
        TimeRemainingColumn(),
        console=console,
        refresh_per_second=4,
    ) as prog:
        overall  = prog.add_task("[bold green]Overall", total=total_bytes)
        cur_file = prog.add_task("[cyan]—", total=1, completed=0)

        for fid, fpath, fsize, dlabel in rows:
            name = PurePosixPath(fpath).name
            prog.update(cur_file,
                        description=f"[cyan]{dlabel}/{name[:50]}",
                        total=max(fsize, 1), completed=0)
            h = make_hasher()
            try:
                with open(fpath, "rb") as f:
                    for chunk in iter(lambda: f.read(CHUNK), b""):
                        h.update(chunk)
                        prog.advance(cur_file, len(chunk))
                        prog.advance(overall, len(chunk))
                conn.execute("UPDATE files SET hash=?, hash_time=? WHERE id=?",
                             (h.hexdigest(), time.time(), fid))
            except OSError as e:
                conn.execute("UPDATE files SET hash_error=? WHERE id=?",
                             (str(e)[:200], fid))
            conn.commit()

    conn.close()
    console.print("[bold green]Hashing complete.")
    cmd_status(args)


# ── Detect frame directories ──────────────────────────────────────────────────

def cmd_detect(args):
    """
    Find directories on faulty drives that are packed with many small files
    of the same type (frame dumps, tile sets, numpy arrays, etc.) and store
    them in the frame_dirs table so the planner can pack them as tarballs.
    """
    conn = open_db(args.db)

    faulty_labels = [
        row[0] for row in
        conn.execute("SELECT label FROM drives WHERE is_trusted=0").fetchall()
    ]
    if not faulty_labels:
        console.print("[yellow]No faulty drives in database.")
        conn.close()
        return

    total_files = conn.execute(
        "SELECT COUNT(*) FROM files WHERE drive_label IN ({})".format(
            ",".join("?" * len(faulty_labels))
        ), faulty_labels
    ).fetchone()[0]

    console.print(f"Analysing {total_files:,} files on faulty drives for frame directories…")

    # Stream file records and build per-directory statistics in Python.
    # We only store counts + extension counter per directory, so memory is
    # bounded by the number of unique parent directories (not file count).
    dir_stats: dict[tuple, dict] = defaultdict(
        lambda: {"count": 0, "total": 0, "exts": Counter()}
    )

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        MofNCompleteColumn(),
        TextColumn("files"),
        console=console, refresh_per_second=4,
    ) as prog:
        task = prog.add_task("Grouping files by directory", total=total_files)

        cursor = conn.execute(
            "SELECT drive_label, relative_path, filename, size FROM files "
            "WHERE drive_label IN ({})".format(",".join("?" * len(faulty_labels))),
            faulty_labels,
        )
        for drive, rp, fn, size in cursor:
            parent = str(PurePosixPath(rp).parent)
            key    = (drive, parent)
            s      = dir_stats[key]
            s["count"]  += 1
            s["total"]  += size
            ext = PurePosixPath(fn).suffix.lower()
            if ext:
                s["exts"][ext] += 1
            prog.advance(task)

    # Filter to candidates matching the thresholds
    candidates = []
    for (drive, parent), s in dir_stats.items():
        if s["count"] < args.min_files:
            continue
        avg = s["total"] / s["count"]
        if avg > args.max_avg_size:
            continue
        if not s["exts"]:
            continue
        dom_ext, dom_count = s["exts"].most_common(1)[0]
        ratio = dom_count / s["count"]
        if ratio < args.min_ext_ratio:
            continue
        candidates.append({
            "drive":  drive,
            "parent": parent,
            "count":  s["count"],
            "total":  s["total"],
            "avg":    avg,
            "ext":    dom_ext,
            "ratio":  ratio,
        })

    # Persist to DB
    conn.execute("DELETE FROM frame_dirs")
    conn.executemany("""
        INSERT INTO frame_dirs
            (drive_label, relative_path, file_count, total_size, dominant_ext, ext_ratio)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(drive_label, relative_path) DO UPDATE SET
            file_count=excluded.file_count,
            total_size=excluded.total_size,
            dominant_ext=excluded.dominant_ext,
            ext_ratio=excluded.ext_ratio
    """, [(c["drive"], c["parent"], c["count"], c["total"], c["ext"], c["ratio"])
          for c in candidates])
    conn.commit()
    conn.close()

    if not candidates:
        console.print("[yellow]No frame directories detected with current thresholds.")
        console.print(f"  --min-files {args.min_files}  --max-avg-size {args.max_avg_size}  --min-ext-ratio {args.min_ext_ratio}")
        return

    t = Table(title=f"Frame Directories Detected ({len(candidates)})", show_lines=True)
    t.add_column("Drive",    style="cyan")
    t.add_column("Directory")
    t.add_column("Files",    justify="right")
    t.add_column("Total",    justify="right")
    t.add_column("Avg size", justify="right")
    t.add_column("Ext",      style="dim")
    t.add_column("Purity",   justify="right", style="dim")

    for c in sorted(candidates, key=lambda x: -x["count"])[:50]:
        t.add_row(
            c["drive"], c["parent"],
            f"{c['count']:,}", fmt_bytes(c["total"]), fmt_bytes(int(c["avg"])),
            c["ext"], f"{c['ratio']*100:.0f}%",
        )
    if len(candidates) > 50:
        t.add_row("[dim]…", f"[dim]{len(candidates)-50} more", "", "", "", "", "")
    console.print(t)

    total_files_affected = sum(c["count"] for c in candidates)
    total_bytes_affected = sum(c["total"] for c in candidates)
    console.print(
        f"\n[bold green]{len(candidates)} directories[/]  ·  "
        f"{total_files_affected:,} files  ·  {fmt_bytes(total_bytes_affected)}\n"
        "These will be packed as tarballs by migration_planner.py instead of\n"
        "being copied file-by-file, reducing inode pressure on the destination."
    )


# ── Status ────────────────────────────────────────────────────────────────────

def cmd_status(args):
    conn = open_db(args.db)

    rows = conn.execute("""
        SELECT
            d.label, d.is_trusted, d.free_bytes,
            COUNT(f.id)                                                AS total,
            SUM(CASE WHEN f.hash IS NOT NULL  THEN 1 ELSE 0 END)      AS hashed,
            SUM(CASE WHEN f.hash_error IS NOT NULL THEN 1 ELSE 0 END) AS errors,
            COALESCE(SUM(f.size), 0)                                   AS total_size
        FROM drives d
        LEFT JOIN files f ON f.drive_label = d.label
        GROUP BY d.label
        ORDER BY d.is_trusted DESC, d.label
    """).fetchall()

    frame_counts = {
        row[0]: row[1]
        for row in conn.execute(
            "SELECT drive_label, COUNT(*) FROM frame_dirs GROUP BY drive_label"
        ).fetchall()
    }
    conn.close()

    t = Table(title=f"Drive Inventory  [dim]({args.db})", show_lines=True)
    t.add_column("Label",      style="cyan", no_wrap=True)
    t.add_column("Trust",      justify="center")
    t.add_column("Free",       justify="right")
    t.add_column("Files",      justify="right")
    t.add_column("Hashed",     justify="right")
    t.add_column("Frame dirs", justify="right", style="dim")
    t.add_column("Errors",     justify="right", style="red")
    t.add_column("Size",       justify="right")

    for label, trusted, free, total, hashed, errors, size in rows:
        pct = f"{(hashed or 0)*100//(total or 1)}%" if total else "—"
        t.add_row(
            label,
            "[green]trusted[/]" if trusted else "[red]faulty[/]",
            fmt_bytes(free or 0),
            f"{total or 0:,}",
            f"{hashed or 0:,}  [dim]({pct})",
            str(frame_counts.get(label, 0)),
            f"{errors or 0:,}",
            fmt_bytes(size),
        )
    console.print(t)


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--db", default="inventory.db", metavar="FILE",
                   help="SQLite database (default: inventory.db)")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("scan", help="Scan drives for file metadata")
    sp.add_argument(
        "--drive", nargs=3, action="append", required=True,
        metavar=("LABEL", "MOUNTPOINT", "trusted|faulty"),
        help="Repeat for each drive",
    )

    hp = sub.add_parser("hash", help="Compute file hashes")
    hg = hp.add_mutually_exclusive_group()
    hg.add_argument("--smart", action="store_true",
                    help="Only hash (name, size) match candidates — recommended first pass")
    hg.add_argument("--drive", metavar="LABEL",
                    help="Hash all files on this drive label")

    dp = sub.add_parser("detect",
                        help="Find frame/tile directories to pack as tarballs")
    dp.add_argument("--min-files",     type=int,   default=500,
                    help="Minimum files in a directory (default: 500)")
    dp.add_argument("--max-avg-size",  type=int,   default=512*1024,
                    help="Maximum average file size in bytes (default: 524288 = 512 KB)")
    dp.add_argument("--min-ext-ratio", type=float, default=0.80,
                    help="Minimum fraction sharing the dominant extension (default: 0.80)")

    sub.add_parser("status", help="Show database summary")

    args = p.parse_args()
    {"scan": cmd_scan, "hash": cmd_hash, "detect": cmd_detect, "status": cmd_status}[args.cmd](args)


if __name__ == "__main__":
    main()
