#!/usr/bin/env python3
"""
migration_executor.py — Phase 3: Execute the migration plan.

Dry-run is the default — shows exactly what would happen without touching files.
Pass --execute to perform operations for real.

Execution order (safest first)
  1. COPY          — Copy unique files; hash source during transfer and re-read
                     destination to confirm bit-perfect delivery.
  2. TARBALL_COPY  — Stream a .tar of frame/tile directories to the destination;
                     byte-level progress with ETA; verify by member count.
  3. VERIFY_THEN_DELETE — Hash both copies of name+size matches; delete from
                     faulty drive only if hashes agree.
  4. DELETE        — Delete hash-confirmed duplicates.

REVIEW and NO_SPACE items are always skipped and written to the log file.

Example
  python migration_executor.py --plan migration_plan.json           # dry run
  python migration_executor.py --plan migration_plan.json --execute
  python migration_executor.py --plan migration_plan.json --execute --yes
"""

import argparse
import hashlib
import json
import logging
import os
import sys
import tarfile
import time
from pathlib import Path, PurePosixPath

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import (
        BarColumn,
        MofNCompleteColumn,
        Progress,
        TaskProgressColumn,
        TextColumn,
        TimeRemainingColumn,
        TransferSpeedColumn,
    )
    from rich.prompt import Confirm
    from rich.table import Table
except ImportError:
    sys.exit("Install dependencies: pip install rich")

console = Console()
CHUNK = 4 << 20  # 4 MiB


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


def setup_log(path: str) -> logging.Logger:
    logging.basicConfig(
        filename=path, level=logging.INFO,
        format="%(asctime)s  %(levelname)-8s  %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    return logging.getLogger("executor")


# ── File operations ───────────────────────────────────────────────────────────

def copy_and_verify(
    src: str, dst: str, size: int,
    prog: Progress, overall, file_bar,
    log: logging.Logger,
) -> tuple[str | None, str | None]:
    """
    Copy src → dst while hashing the source bytes on-the-fly.
    Then re-read dst and hash it.
    Returns (src_hash, dst_hash); cleans up partial dst on failure.
    """
    Path(dst).parent.mkdir(parents=True, exist_ok=True)
    h_src = make_hasher()
    name  = PurePosixPath(src).name

    prog.update(file_bar, description=f"[yellow]COPY   {name[:52]}", total=max(size, 1), completed=0)
    try:
        with open(src, "rb") as sf, open(dst, "wb") as df:
            for chunk in iter(lambda: sf.read(CHUNK), b""):
                df.write(chunk)
                h_src.update(chunk)
                prog.advance(file_bar, len(chunk))
                prog.advance(overall,   len(chunk))
    except OSError as e:
        log.error(f"COPY FAIL  {src}  →  {dst}  :  {e}")
        try:
            os.remove(dst)
        except OSError:
            pass
        return None, None

    h_dst = make_hasher()
    prog.update(file_bar, description=f"[blue]VERIFY {name[:51]}", total=max(size, 1), completed=0)
    try:
        with open(dst, "rb") as f:
            for chunk in iter(lambda: f.read(CHUNK), b""):
                h_dst.update(chunk)
                prog.advance(file_bar, len(chunk))
                prog.advance(overall,   len(chunk))
    except OSError as e:
        log.error(f"VERIFY FAIL  {dst}  :  {e}")
        return h_src.hexdigest(), None

    return h_src.hexdigest(), h_dst.hexdigest()


def tarball_copy(
    src_dir: str, dst_tar: str, file_count: int, total_size: int,
    prog: Progress, overall, file_bar,
    log: logging.Logger,
) -> bool:
    """
    Stream all files under src_dir into dst_tar (.tar, no compression).
    Progress is tracked by bytes added.  Verifies by re-reading the member list.
    """
    dir_name = Path(src_dir).name
    Path(dst_tar).parent.mkdir(parents=True, exist_ok=True)

    prog.update(file_bar, description=f"[magenta]TAR    {dir_name[:52]}", total=max(total_size, 1), completed=0)

    bytes_written = 0
    try:
        with tarfile.open(dst_tar, "w:") as tar:
            src_root = Path(src_dir).parent  # archive preserves the dir name
            for item in sorted(Path(src_dir).rglob("*")):
                if not item.is_file():
                    continue
                arcname = str(item.relative_to(src_root))
                tar.add(str(item), arcname=arcname, recursive=False)
                item_size = item.stat().st_size
                bytes_written += item_size
                prog.advance(file_bar, item_size)
                prog.advance(overall,   item_size)
    except (OSError, tarfile.TarError) as e:
        log.error(f"TAR FAIL  {src_dir}  →  {dst_tar}  :  {e}")
        try:
            os.remove(dst_tar)
        except OSError:
            pass
        return False

    # Verify: open the tarball and count members
    try:
        with tarfile.open(dst_tar, "r:") as tar:
            actual_count = len([m for m in tar.getmembers() if m.isfile()])
    except tarfile.TarError as e:
        log.error(f"TAR VERIFY FAIL (unreadable)  {dst_tar}  :  {e}")
        return False

    if actual_count != file_count:
        log.warning(
            f"TAR member count mismatch  {dst_tar}  "
            f"expected={file_count}  got={actual_count}"
        )
    else:
        log.info(
            f"TAR OK  {src_dir}  →  {dst_tar}  "
            f"({actual_count} files, {fmt_bytes(bytes_written)})"
        )
    return True


def hash_file_with_progress(
    path: str, size: int, label: str,
    prog: Progress, overall, file_bar,
    log: logging.Logger,
) -> str | None:
    h = make_hasher()
    prog.update(file_bar, description=f"[blue]HASH   {label[:52]}", total=max(size, 1), completed=0)
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(CHUNK), b""):
                h.update(chunk)
                prog.advance(file_bar, len(chunk))
                prog.advance(overall,   len(chunk))
        return h.hexdigest()
    except OSError as e:
        log.error(f"HASH FAIL  {path}  :  {e}")
        return None


def delete_file(path: str, log: logging.Logger) -> bool:
    try:
        os.remove(path)
        log.info(f"DELETE OK  {path}")
        return True
    except OSError as e:
        log.error(f"DELETE FAIL  {path}  :  {e}")
        console.print(f"[red]  DELETE failed: {e}")
        return False


# ── Dry-run preview ───────────────────────────────────────────────────────────

def dry_run_table(ops: list[dict]):
    t = Table(title="[bold yellow]DRY RUN — no files will be changed", show_lines=True)
    t.add_column("Type",          style="cyan", no_wrap=True)
    t.add_column("Source / Path", overflow="fold")
    t.add_column("Destination",   overflow="fold")
    t.add_column("Size",          justify="right")

    shown = 0
    for op in ops:
        ot = op["type"]
        if ot == "COPY":
            t.add_row("[yellow]COPY",    op["src"],       op["dst"],     fmt_bytes(op["size"]))
        elif ot == "TARBALL_COPY":
            t.add_row("[magenta]TARBALL", op["src_dir"],  op["dst_tar"],
                      fmt_bytes(op["total_size"]) + f" ({op['file_count']:,} files)")
        elif ot == "DELETE":
            t.add_row("[green]DELETE",   op["path"],      "—",           fmt_bytes(op["size"]))
        elif ot == "VERIFY_THEN_DELETE":
            t.add_row("[blue]VTD",       op["faulty_path"], op["trusted_path"], fmt_bytes(op["size"]))
        elif ot == "REVIEW":
            t.add_row("[red]REVIEW",     op["faulty_path"], op["trusted_path"], fmt_bytes(op["size"]))
        elif ot == "NO_SPACE":
            t.add_row("[bright_red]NO_SPACE", op["path"], "—",           fmt_bytes(op["size"]))
        shown += 1
        if shown >= 30:
            t.add_row("[dim]…", f"[dim]{len(ops)-shown} more rows", "", "")
            break

    console.print(t)


# ── Main execution ────────────────────────────────────────────────────────────

def cmd_execute(args):
    with open(args.plan) as fh:
        plan = json.load(fh)

    log = setup_log(args.log)
    log.info(f"Session start  plan={args.plan}  execute={args.execute}")

    ops      = plan["operations"]
    copies   = [o for o in ops if o["type"] == "COPY"]
    tarballs = [o for o in ops if o["type"] == "TARBALL_COPY"]
    deletes  = [o for o in ops if o["type"] == "DELETE"]
    vtd      = [o for o in ops if o["type"] == "VERIFY_THEN_DELETE"]
    reviews  = [o for o in ops if o["type"] == "REVIEW"]
    no_spc   = [o for o in ops if o["type"] == "NO_SPACE"]

    # ── Pre-flight summary ────────────────────────────────────────────────────
    st = Table(title=f"Plan: {plan.get('generated_at','?')}", show_lines=True)
    st.add_column("Stage", style="cyan")
    st.add_column("Operation")
    st.add_column("Count",  justify="right")
    st.add_column("Data",   justify="right")
    for stage, desc, lst, color in [
        ("1", "COPY unique files + verify",        copies,   "yellow"),
        ("2", "TARBALL frame dirs + verify",        tarballs, "magenta"),
        ("3", "VERIFY_THEN_DELETE name+size match", vtd,      "blue"),
        ("4", "DELETE confirmed duplicates",         deletes,  "green"),
        ("—", "REVIEW (skipped — manual)",          reviews,  "red"),
        ("—", "NO_SPACE (skipped — no room)",       no_spc,   "bright_red"),
    ]:
        if lst:
            total = sum(o.get("size") or o.get("total_size") or 0 for o in lst)
            st.add_row(stage, f"[{color}]{desc}", f"{len(lst):,}", fmt_bytes(total))
    console.print(st)

    if reviews:
        console.print(f"\n[red]⚠  {len(reviews)} REVIEW items — inspect manually:[/]")
        for r in reviews[:8]:
            console.print(f"   F: {r['faulty_path']}")
            console.print(f"   T: {r['trusted_path']}")
        if len(reviews) > 8:
            console.print(f"   [dim]… {len(reviews)-8} more in {args.log}")
        for r in reviews:
            log.warning(f"REVIEW  {r['faulty_path']}  vs  {r['trusted_path']}")

    if no_spc:
        console.print(f"\n[bright_red]⚠  {len(no_spc)} files have no destination:[/]")
        for ns in no_spc[:8]:
            console.print(f"   {ns['path']}  ({fmt_bytes(ns['size'])})")
        for ns in no_spc:
            log.warning(f"NO_SPACE  {ns['path']}  {ns['size']} bytes")

    # ── Dry-run path ──────────────────────────────────────────────────────────
    if not args.execute:
        dry_run_table(ops)
        console.print(Panel(
            f"COPY           {len(copies):>6,} files   {fmt_bytes(sum(o['size'] for o in copies))}\n"
            f"TARBALL_COPY   {len(tarballs):>6,} dirs    {fmt_bytes(sum(o['total_size'] for o in tarballs))}\n"
            f"DELETE         {len(deletes):>6,} files   {fmt_bytes(sum(o['size'] for o in deletes))}\n"
            f"VTD            {len(vtd):>6,} files\n"
            f"REVIEW         {len(reviews):>6,} files   (skipped)\n"
            f"NO_SPACE       {len(no_spc):>6,} files   (skipped)\n\n"
            "Add [cyan]--execute[/] to perform these operations.",
            title="[bold yellow]Dry Run",
        ))
        return

    # ── Confirmation ──────────────────────────────────────────────────────────
    if not args.yes:
        console.print()
        n_write = len(copies) + len(tarballs)
        n_del   = len(deletes) + len(vtd)
        if not Confirm.ask(f"Proceed? Will write {n_write} items and delete up to {n_del} files"):
            console.print("[yellow]Aborted.")
            return

    # Overall byte budget:
    #  COPY: read src + read dst (verify) = 2 × bytes
    #  TAR:  read src files = 1 × bytes
    #  VTD:  read faulty + read trusted   = 2 × bytes
    total_bytes = (
        sum(o["size"]       for o in copies)   * 2
        + sum(o["total_size"] for o in tarballs)
        + sum(o["size"]       for o in vtd)    * 2
    )

    res = dict(copy_ok=0, copy_fail=0, tar_ok=0, tar_fail=0,
               vtd_ok=0, vtd_skip=0, del_ok=0, del_fail=0)

    with Progress(
        TextColumn("[progress.description]{task.description:<58}"),
        BarColumn(),
        TaskProgressColumn(),
        TransferSpeedColumn(),
        TimeRemainingColumn(),
        console=console, refresh_per_second=4,
    ) as prog:
        overall  = prog.add_task("[bold green]Overall", total=max(total_bytes, 1))
        file_bar = prog.add_task("[cyan]—", total=1)

        # ── Stage 1: COPY ─────────────────────────────────────────────────────
        if copies:
            stask = prog.add_task(f"[yellow]Stage 1 — COPY ({len(copies):,} files)", total=len(copies))
            for op in copies:
                sh, dh = copy_and_verify(
                    op["src"], op["dst"], op["size"],
                    prog, overall, file_bar, log,
                )
                if sh is None or dh is None:
                    res["copy_fail"] += 1
                elif sh != dh:
                    res["copy_fail"] += 1
                    log.error(f"HASH MISMATCH after copy  {op['src']}  src={sh}  dst={dh}")
                    console.print(f"[red]  Hash mismatch! Check: {op['dst']}")
                else:
                    res["copy_ok"] += 1
                    log.info(f"COPY+VERIFY OK  {op['src']}  →  {op['dst']}")
                prog.advance(stask)

        # ── Stage 2: TARBALL_COPY ─────────────────────────────────────────────
        if tarballs:
            stask = prog.add_task(
                f"[magenta]Stage 2 — TARBALL ({len(tarballs):,} dirs)", total=len(tarballs)
            )
            for op in tarballs:
                ok = tarball_copy(
                    op["src_dir"], op["dst_tar"],
                    op["file_count"], op["total_size"],
                    prog, overall, file_bar, log,
                )
                if ok:
                    res["tar_ok"] += 1
                else:
                    res["tar_fail"] += 1
                    console.print(f"[red]  Tarball failed: {op['src_dir']}")
                prog.advance(stask)

        # ── Stage 3: VERIFY_THEN_DELETE ───────────────────────────────────────
        if vtd:
            stask = prog.add_task(
                f"[blue]Stage 3 — VTD ({len(vtd):,} files)", total=len(vtd)
            )
            for op in vtd:
                fh = hash_file_with_progress(
                    op["faulty_path"], op["size"],
                    f"faulty/{PurePosixPath(op['faulty_path']).name}",
                    prog, overall, file_bar, log,
                )
                th = hash_file_with_progress(
                    op["trusted_path"], op["size"],
                    f"trusted/{PurePosixPath(op['trusted_path']).name}",
                    prog, overall, file_bar, log,
                )
                if fh and th and fh == th:
                    if delete_file(op["faulty_path"], log):
                        res["vtd_ok"] += 1
                    else:
                        res["vtd_skip"] += 1
                else:
                    reason = "hash mismatch" if fh and th else "read error"
                    log.warning(
                        f"VTD SKIP ({reason})  {op['faulty_path']}  "
                        f"faulty={fh}  trusted={th}"
                    )
                    console.print(
                        f"[yellow]  VTD skipped ({reason}): {PurePosixPath(op['faulty_path']).name}"
                    )
                    res["vtd_skip"] += 1
                prog.advance(stask)

        # ── Stage 4: DELETE confirmed duplicates ──────────────────────────────
        if deletes:
            stask = prog.add_task(
                f"[green]Stage 4 — DELETE ({len(deletes):,} files)", total=len(deletes)
            )
            for op in deletes:
                if delete_file(op["path"], log):
                    res["del_ok"] += 1
                else:
                    res["del_fail"] += 1
                prog.advance(stask)

        prog.update(file_bar, description="[green]Done", completed=1, total=1)

    # ── Final report ──────────────────────────────────────────────────────────
    color = "green" if (res["copy_fail"] + res["tar_fail"] + res["del_fail"]) == 0 else "red"
    console.print(Panel(
        f"COPY OK       : {res['copy_ok']:,}\n"
        f"COPY FAILED   : {res['copy_fail']:,}\n"
        f"TARBALL OK    : {res['tar_ok']:,}\n"
        f"TARBALL FAILED: {res['tar_fail']:,}\n"
        f"VTD OK        : {res['vtd_ok']:,}\n"
        f"VTD SKIPPED   : {res['vtd_skip']:,}\n"
        f"DELETE OK     : {res['del_ok']:,}\n"
        f"DELETE FAILED : {res['del_fail']:,}\n\n"
        f"Full log: {args.log}",
        title="[bold]Execution Complete",
        border_style=color,
    ))
    log.info(f"Session end  {res}")


def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--plan",    default="migration_plan.json", help="Plan file from migration_planner.py")
    p.add_argument("--execute", action="store_true",           help="Perform operations (default: dry run)")
    p.add_argument("--yes",     action="store_true",           help="Skip confirmation prompt")
    p.add_argument("--log",     default="migration.log",       help="Log file (default: migration.log)")
    cmd_execute(p.parse_args())


if __name__ == "__main__":
    main()
