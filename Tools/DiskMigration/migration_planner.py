#!/usr/bin/env python3
"""
migration_planner.py — Phase 2: Analyse inventory and generate a migration plan.

Reads the SQLite database from disk_mapper.py and outputs migration_plan.json.

Run disk_mapper.py detect before this script so that frame directories (many
small files of the same type) are packed as tarballs instead of being copied
file-by-file.  Run disk_mapper.py hash --smart for reliable duplicate detection.

Operation types in the output plan
  COPY               File is unique to a faulty drive — copy it to a trusted drive.
  TARBALL_COPY       Directory of many small files — pack it as a .tar and copy.
  DELETE             Hash-confirmed duplicate on a trusted drive — safe to delete.
  VERIFY_THEN_DELETE Name+size match found but not yet hash-verified.  Re-run
                     disk_mapper.py hash --smart and then re-run this planner.
  REVIEW             Same name+size but different hash — possible corruption.
  NO_SPACE           Unique file but no trusted drive has room.

Faulty drives are processed fullest-first:
  CVRLDatasets (100%) → CVRL2 (97%) → MAGICIAN16TB (97%)

Example
  python migration_planner.py
  python migration_planner.py --db inventory.db --out migration_plan.json
"""

import argparse
import json
import sqlite3
import sys
import time
from pathlib import PurePosixPath

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import MofNCompleteColumn, Progress, SpinnerColumn, TextColumn
    from rich.table import Table
except ImportError:
    sys.exit("Install dependencies: pip install rich")

console = Console()


def fmt_bytes(n: int) -> str:
    n = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def open_db(path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def build_trusted_lookups(conn, trusted_labels: list[str]):
    """
    Build two in-memory lookups over the trusted drives, ONCE.

    The previous planner ran up to three correlated subqueries per faulty file —
    millions of point queries that made planning crawl.  Streaming every trusted
    file once into dicts turns each faulty-file decision into an O(1) lookup.

      hash_to_path : hash            -> full_path        (hash-confirmed dupes)
      namesize     : (filename,size) -> (full_path,hash) (name+size candidates)
    """
    trusted_ph = ",".join("?" * len(trusted_labels))
    hash_to_path: dict[str, str] = {}
    namesize: dict[tuple, tuple] = {}

    cur = conn.execute(
        f"SELECT filename, size, hash, full_path FROM files "
        f"WHERE drive_label IN ({trusted_ph})",
        trusted_labels,
    )
    for fn, size, h, path in cur:
        if h and h not in hash_to_path:
            hash_to_path[h] = path
        key = (fn, size)
        prev = namesize.get(key)
        # Prefer a hashed candidate so REVIEW/DELETE can resolve without a re-scan.
        if prev is None or (prev[1] is None and h is not None):
            namesize[key] = (path, h)
    return hash_to_path, namesize


# ── Core analysis ─────────────────────────────────────────────────────────────

def analyse_drive(
    rconn,
    faulty_label: str,
    hash_to_path: dict[str, str],
    namesize: dict[tuple, tuple],
    trusted_mounts: dict[str, str],
    trusted_free: dict[str, int],
    frame_dirs: set[str],
    faulty_mount: str,
) -> list[dict]:
    """Return ordered list of operations for one faulty drive."""
    # Stream faulty files from a dedicated read cursor — never fetchall() the
    # (potentially millions of) rows into memory at once.
    files = rconn.execute(
        "SELECT relative_path, full_path, filename, size, hash "
        "FROM files WHERE drive_label=?", (faulty_label,)
    )

    ops: list[dict] = []
    tarball_queued: dict[str, list] = {}

    for frp, fpath, fname, fsize, fhash in files:
        parent = str(PurePosixPath(frp).parent)

        # ── Hash-confirmed match on a trusted drive ───────────────────────────
        if fhash:
            trusted_match = hash_to_path.get(fhash)
            if trusted_match:
                ops.append({
                    "type":        "DELETE",
                    "path":        fpath,
                    "drive":       faulty_label,
                    "size":        fsize,
                    "reason":      "hash_confirmed_duplicate",
                    "verified_on": trusted_match,
                })
                continue

            cand = namesize.get((fname, fsize))
            if cand and cand[1] is not None and cand[1] != fhash:
                ops.append({
                    "type":         "REVIEW",
                    "faulty_path":  fpath,
                    "trusted_path": cand[0],
                    "drive":        faulty_label,
                    "size":         fsize,
                    "faulty_hash":  fhash,
                    "trusted_hash": cand[1],
                    "reason":       "hash_mismatch_same_name_and_size",
                })
                continue

        else:
            cand = namesize.get((fname, fsize))
            if cand:
                ops.append({
                    "type":         "VERIFY_THEN_DELETE",
                    "faulty_path":  fpath,
                    "trusted_path": cand[0],
                    "drive":        faulty_label,
                    "size":         fsize,
                    "reason":       "name_size_match_unverified",
                })
                continue

        # ── File is unique — needs to go to a trusted drive ──────────────────
        if parent in frame_dirs:
            tarball_queued.setdefault(parent, []).append(
                {"full_path": fpath, "size": fsize})
        else:
            _emit_copy(ops, fpath, frp, fsize, faulty_label,
                       trusted_mounts, trusted_free)

    # ── Emit one TARBALL_COPY per frame directory ─────────────────────────────
    for parent_rel, group in tarball_queued.items():
        total_size = sum(g["size"] for g in group)
        file_count = len(group)
        best       = max(trusted_free, key=trusted_free.get)
        if trusted_free[best] < total_size:
            for g in group:
                ops.append({
                    "type":   "NO_SPACE",
                    "path":   g["full_path"],
                    "drive":  faulty_label,
                    "size":   g["size"],
                    "reason": "no_trusted_drive_has_enough_free_space",
                })
        else:
            src_dir = str(PurePosixPath(faulty_mount) / parent_rel)
            dst_tar = str(PurePosixPath(trusted_mounts[best]) / parent_rel) + ".tar"
            ops.append({
                "type":       "TARBALL_COPY",
                "src_dir":    src_dir,
                "dst_tar":    dst_tar,
                "src_drive":  faulty_label,
                "dst_drive":  best,
                "file_count": file_count,
                "total_size": total_size,
                "reason":     "frame_directory_packed_as_tarball",
            })
            trusted_free[best] -= total_size

    return ops


def _emit_copy(ops, fpath, frp, fsize, faulty_label,
               trusted_mounts, trusted_free):
    best = max(trusted_free, key=trusted_free.get)
    if trusted_free[best] < fsize:
        ops.append({
            "type":   "NO_SPACE",
            "path":   fpath,
            "drive":  faulty_label,
            "size":   fsize,
            "reason": "no_trusted_drive_has_enough_free_space",
        })
    else:
        dst = str(PurePosixPath(trusted_mounts[best]) / frp)
        ops.append({
            "type":      "COPY",
            "src":       fpath,
            "dst":       dst,
            "src_drive": faulty_label,
            "dst_drive": best,
            "size":      fsize,
            "reason":    "unique_to_faulty_drive",
        })
        trusted_free[best] -= fsize


# ── Command ───────────────────────────────────────────────────────────────────

def cmd_plan(args):
    conn = open_db(args.db)
    drives = {row["label"]: dict(row) for row in conn.execute("SELECT * FROM drives")}

    if not drives:
        console.print("[red]No drives in database. Run disk_mapper.py scan first.")
        sys.exit(1)

    trusted = {k: v for k, v in drives.items() if     v["is_trusted"]}
    faulty  = {k: v for k, v in drives.items() if not v["is_trusted"]}

    if not trusted:
        console.print("[red]No trusted drives found. Re-scan with the 'trusted' flag.")
        sys.exit(1)

    fd_rows = conn.execute("SELECT drive_label, relative_path FROM frame_dirs").fetchall()
    frame_dirs_by_drive: dict[str, set] = {}
    for row in fd_rows:
        frame_dirs_by_drive.setdefault(row["drive_label"], set()).add(row["relative_path"])

    has_frame_dirs = bool(fd_rows)
    console.print(f"Trusted : [green]{', '.join(trusted)}")
    console.print(f"Faulty  : [red]{', '.join(faulty)}")
    if has_frame_dirs:
        total_fd = sum(len(v) for v in frame_dirs_by_drive.values())
        console.print(f"Frame dirs detected: [yellow]{total_fd}[/] (will be packed as tarballs)")
    else:
        console.print("[dim]No frame dirs detected — run disk_mapper.py detect for tarball packing")

    faulty_order = sorted(
        faulty, key=lambda k: faulty[k]["used_bytes"] / max(faulty[k]["total_bytes"], 1),
        reverse=True,
    )

    trusted_free   = {k: v["free_bytes"]  for k, v in trusted.items()}
    trusted_mounts = {k: v["mount_point"] for k, v in trusted.items()}
    trusted_labels = list(trusted)

    console.print("[dim]Indexing trusted drives in memory…")
    hash_to_path, namesize = build_trusted_lookups(conn, trusted_labels)
    console.print(
        f"[dim]  {len(hash_to_path):,} hashed + {len(namesize):,} name/size keys indexed"
    )

    rconn = open_db(args.db)   # dedicated streaming reader for faulty files

    all_ops: list[dict] = []
    op_id = 0

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description:<42}"),
        MofNCompleteColumn(),
        console=console, refresh_per_second=4,
    ) as prog:
        for faulty_label in faulty_order:
            n_files = conn.execute(
                "SELECT COUNT(*) FROM files WHERE drive_label=?", (faulty_label,)
            ).fetchone()[0]
            task = prog.add_task(f"[yellow]Analysing {faulty_label}", total=n_files)

            ops = analyse_drive(
                rconn, faulty_label, hash_to_path, namesize, trusted_mounts,
                trusted_free,
                frame_dirs_by_drive.get(faulty_label, set()),
                faulty[faulty_label]["mount_point"],
            )
            prog.advance(task, n_files)
            prog.update(task, description=f"[yellow]Done {faulty_label}")

            for op in ops:
                op_id += 1
                op["id"] = op_id
            all_ops.extend(ops)

    rconn.close()
    conn.close()

    # ── Summary tables ────────────────────────────────────────────────────────
    by_type: dict[str, dict] = {}
    for op in all_ops:
        t = op["type"]
        e = by_type.setdefault(t, {"count": 0, "bytes": 0})
        e["count"] += 1
        e["bytes"] += op.get("size") or op.get("total_size") or 0

    TYPE_META = {
        "TARBALL_COPY":       ("magenta",    "Frame dir → packed as .tar on trusted drive"),
        "COPY":               ("yellow",     "Unique file → copied to trusted drive"),
        "DELETE":             ("green",      "Hash-confirmed duplicate → safe to delete"),
        "VERIFY_THEN_DELETE": ("blue",       "Name+size match → needs hash confirmation"),
        "REVIEW":             ("red",        "Hash mismatch → manual inspection required"),
        "NO_SPACE":           ("bright_red", "No destination space — needs attention"),
    }

    st = Table(title="Migration Plan Summary", show_lines=True)
    st.add_column("Operation", style="cyan", no_wrap=True)
    st.add_column("Count",     justify="right")
    st.add_column("Data",      justify="right")
    st.add_column("Action")
    for op_type, (color, desc) in TYPE_META.items():
        stats = by_type.get(op_type)
        if not stats or stats["count"] == 0:
            continue
        st.add_row(f"[{color}]{op_type}", f"{stats['count']:,}", fmt_bytes(stats["bytes"]), desc)
    console.print(st)

    by_drive: dict[str, dict] = {}
    for op in all_ops:
        drv   = op.get("drive") or op.get("src_drive") or "?"
        entry = by_drive.setdefault(drv, {t: 0 for t in TYPE_META})
        entry[op["type"]] = entry.get(op["type"], 0) + 1
    dt = Table(title="Per-Drive Breakdown", show_lines=True)
    dt.add_column("Drive", style="cyan", no_wrap=True)
    for op_type, (color, _) in TYPE_META.items():
        dt.add_column(op_type, justify="right", style=color)
    for drv, counts in by_drive.items():
        dt.add_row(drv, *[str(counts.get(t, 0)) for t in TYPE_META])
    console.print(dt)

    spt = Table(title="Trusted Drive Space (after all COPYs)", show_lines=True)
    spt.add_column("Drive",      style="cyan")
    spt.add_column("Free now",   justify="right")
    spt.add_column("Free after", justify="right")
    for label, after in trusted_free.items():
        before = trusted[label]["free_bytes"]
        color  = "green" if after > 0 else "red"
        spt.add_row(label, fmt_bytes(before), f"[{color}]{fmt_bytes(after)}")
    console.print(spt)

    notes = []
    vtd = by_type.get("VERIFY_THEN_DELETE", {}).get("count", 0)
    if vtd:
        notes.append(
            f"[yellow]{vtd:,} VERIFY_THEN_DELETE[/] items: run  "
            "[cyan]python disk_mapper.py hash --smart[/]  then re-run this planner."
        )
    if by_type.get("REVIEW", {}).get("count", 0):
        notes.append(f"[red]{by_type['REVIEW']['count']:,} REVIEW[/] items need manual inspection.")
    if by_type.get("NO_SPACE", {}).get("count", 0):
        notes.append(f"[bright_red]{by_type['NO_SPACE']['count']:,} NO_SPACE[/] files need destination.")
    if not has_frame_dirs:
        notes.append(
            "Run [cyan]python disk_mapper.py detect[/] to identify frame directories "
            "and get TARBALL_COPY ops instead of millions of individual COPY ops."
        )
    if not notes:
        notes.append("[green]Plan looks clean — proceed to migration_executor.py")
    console.print(Panel("\n".join(notes), title="Next steps"))

    plan = {
        "generated_at":       time.strftime("%Y-%m-%dT%H:%M:%S"),
        "db_path":            args.db,
        "faulty_drive_order": faulty_order,
        "trusted_drives":     trusted_labels,
        "operations":         all_ops,
        "summary": {
            t: {"count": v["count"], "bytes": v["bytes"]}
            for t, v in by_type.items()
        },
    }
    with open(args.out, "w") as fh:
        json.dump(plan, fh, indent=2)

    console.print(f"\n[bold green]Plan written → {args.out}")
    console.print(
        f"Dry-run:  [cyan]python migration_executor.py --plan {args.out}[/]\n"
        f"Execute:  [cyan]python migration_executor.py --plan {args.out} --execute[/]"
    )


def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--db",  default="inventory.db",        help="Database from disk_mapper.py")
    p.add_argument("--out", default="migration_plan.json", help="Output plan file")
    cmd_plan(p.parse_args())


if __name__ == "__main__":
    main()
