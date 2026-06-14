#!/usr/bin/env python3
"""
disk_recycler.py — Phase 4: Reclaim an evacuated faulty drive.

Once a faulty drive's unique data has been copied (and verified) onto the
trusted drives, that drive can be wiped and reused as a fresh, trusted
destination.  This tool does NOT format anything itself.  It:

  1. Proves the drive is fully evacuated, by checking — on the real
     filesystem, not just the log — that:
       * every COPY destination exists on a trusted drive with the right size,
       * every TARBALL_COPY archive exists and opens as a valid tar,
       * there are zero NO_SPACE and zero REVIEW operations for the drive,
       * no VERIFY_THEN_DELETE source file is still sitting on the faulty drive
         unverified (that would be data only present on the disk you're wiping).
  2. Maps the drive label to its block device via lsblk.
  3. Writes a vetted reformat_<LABEL>.sh containing the exact
     umount + wipefs + mkfs.ext4 commands, guarded so it refuses to run
     against the wrong disk or a system mount.

You then READ that script and run it yourself with sudo.  Nothing destructive
happens from Python.

Examples
  python disk_recycler.py                      # readiness table for all faulty drives
  python disk_recycler.py --drive CVRLDatasets # verify + emit reformat_CVRLDatasets.sh
  python disk_recycler.py --drive CVRL2 --deep # also count every tar member (slow)
"""

import argparse
import json
import os
import sqlite3
import subprocess
import sys
import tarfile
import time

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, MofNCompleteColumn, TextColumn
    from rich.table import Table
except ImportError:
    sys.exit("Install dependencies: pip install rich")

console = Console()

SYSTEM_MOUNTS = {"/", "/home", "/boot", "/boot/efi", "/usr", "/var", "/boot/firmware"}


def fmt_bytes(n: int) -> str:
    n = float(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


# ── Block-device discovery ─────────────────────────────────────────────────────

def lsblk_nodes() -> list[dict]:
    """Flatten `lsblk -J` into a list of {name,label,mountpoint,size,type,path}."""
    try:
        out = subprocess.run(
            ["lsblk", "-J", "-o", "NAME,LABEL,MOUNTPOINT,SIZE,TYPE,PATH"],
            capture_output=True, text=True, check=True,
        ).stdout
    except (OSError, subprocess.CalledProcessError) as e:
        console.print(f"[red]Could not run lsblk: {e}")
        return []

    nodes: list[dict] = []

    def walk(items):
        for it in items:
            nodes.append(it)
            if it.get("children"):
                walk(it["children"])

    walk(json.loads(out).get("blockdevices", []))
    return nodes


def find_device(label: str, mount_point: str) -> dict | None:
    """Locate the block device for a drive, preferring a current-mountpoint match."""
    nodes = lsblk_nodes()
    for n in nodes:                      # mountpoint is the strongest signal
        if n.get("mountpoint") and os.path.normpath(n["mountpoint"]) == os.path.normpath(mount_point):
            return n
    for n in nodes:                      # fall back to the filesystem label
        if n.get("label") == label:
            return n
    return None


# ── Evacuation verification ────────────────────────────────────────────────────

def verify_evacuated(plan: dict, label: str, deep: bool) -> dict:
    """
    Return a report dict describing whether `label` is safe to wipe.
    Checks the destination files on disk, not the migration log.
    """
    ops = plan["operations"]

    def drive_of(op):
        return op.get("drive") or op.get("src_drive")

    copies   = [o for o in ops if o["type"] == "COPY"               and drive_of(o) == label]
    tarballs = [o for o in ops if o["type"] == "TARBALL_COPY"       and drive_of(o) == label]
    no_space = [o for o in ops if o["type"] == "NO_SPACE"           and drive_of(o) == label]
    reviews  = [o for o in ops if o["type"] == "REVIEW"             and drive_of(o) == label]
    vtd      = [o for o in ops if o["type"] == "VERIFY_THEN_DELETE" and drive_of(o) == label]

    missing_copies: list[str] = []
    bad_tarballs:   list[str] = []
    unverified_vtd: list[str] = []

    total_checks = len(copies) + len(tarballs) + len(vtd)
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        MofNCompleteColumn(),
        console=console, refresh_per_second=2,
    ) as prog:
        task = prog.add_task(f"Verifying {label} on disk", total=max(total_checks, 1))

        for op in copies:
            dst = op["dst"]
            try:
                if not os.path.isfile(dst) or os.path.getsize(dst) != op["size"]:
                    missing_copies.append(dst)
            except OSError:
                missing_copies.append(dst)
            prog.advance(task)

        for op in tarballs:
            tar = op["dst_tar"]
            try:
                if not os.path.isfile(tar) or os.path.getsize(tar) == 0:
                    bad_tarballs.append(tar)
                elif deep:
                    with tarfile.open(tar, "r:") as tf:
                        n = sum(1 for m in tf if m.isfile())
                    if n != op.get("file_count", n):
                        bad_tarballs.append(f"{tar} (members {n} != {op.get('file_count')})")
                else:
                    with tarfile.open(tar, "r:") as tf:   # cheap openability check
                        tf.next()
            except (OSError, tarfile.TarError):
                bad_tarballs.append(tar)
            prog.advance(task)

        for op in vtd:
            # If the source still exists, its trusted twin was never hash-verified,
            # so this file might be unique. Wiping now could lose it.
            if os.path.exists(op["faulty_path"]):
                unverified_vtd.append(op["faulty_path"])
            prog.advance(task)

    blockers = (
        len(missing_copies) + len(bad_tarballs)
        + len(no_space) + len(reviews) + len(unverified_vtd)
    )
    return {
        "label":          label,
        "copies":         len(copies),
        "tarballs":       len(tarballs),
        "missing_copies": missing_copies,
        "bad_tarballs":   bad_tarballs,
        "no_space":       len(no_space),
        "reviews":        len(reviews),
        "unverified_vtd": unverified_vtd,
        "ready":          blockers == 0,
    }


def print_report(rep: dict):
    t = Table(title=f"Evacuation check — {rep['label']}", show_lines=True)
    t.add_column("Check"); t.add_column("Result")
    ok = "[green]OK"; bad = "[red]BLOCKER"
    t.add_row("COPY destinations present",
              ok if not rep["missing_copies"] else f"{bad} ({len(rep['missing_copies'])} missing/bad)")
    t.add_row("TARBALL archives present",
              ok if not rep["bad_tarballs"] else f"{bad} ({len(rep['bad_tarballs'])} missing/bad)")
    t.add_row("NO_SPACE files",
              ok if not rep["no_space"] else f"{bad} ({rep['no_space']})")
    t.add_row("REVIEW (hash mismatch) files",
              ok if not rep["reviews"] else f"{bad} ({rep['reviews']})")
    t.add_row("Unverified copies still on this disk",
              ok if not rep["unverified_vtd"] else f"{bad} ({len(rep['unverified_vtd'])})")
    console.print(t)

    for title, items in (("Missing/short COPY destinations", rep["missing_copies"]),
                         ("Missing/unreadable tarballs",      rep["bad_tarballs"]),
                         ("Unverified files still on disk",   rep["unverified_vtd"])):
        if items:
            console.print(f"[red]{title}:")
            for p in items[:10]:
                console.print(f"   {p}")
            if len(items) > 10:
                console.print(f"   [dim]… {len(items)-10} more")


# ── Script emission ────────────────────────────────────────────────────────────

REFORMAT_TEMPLATE = """\
#!/usr/bin/env bash
# Auto-generated by disk_recycler.py on {when}
#
# Reformat the EVACUATED drive "{label}" with a fresh ext4 filesystem.
# Evacuation was verified on disk: {copies} COPY destinations + {tarballs} tarballs
# present, 0 NO_SPACE, 0 REVIEW, 0 unverified files left on the source.
#
# *** THIS DESTROYS ALL DATA ON {dev}.  READ IT BEFORE YOU RUN IT. ***
set -euo pipefail

LABEL="{label}"
DEV="{dev}"
MOUNT="{mount}"

echo "About to ERASE $DEV  (label '$LABEL', mount '$MOUNT') and make a fresh ext4."

# Guard 1 — never touch a system mount.
case "$MOUNT" in
  {system_cases}) echo "REFUSING: '$MOUNT' is a system mount."; exit 1 ;;
esac

# Guard 2 — the device must STILL carry the label we evacuated, so a disk
# re-enumeration (sdc->sdd after a reboot) cannot send us at the wrong drive.
CUR_LABEL="$(lsblk -no LABEL "$DEV" | head -n1 | tr -d '[:space:]')"
if [ "$CUR_LABEL" != "$LABEL" ]; then
  echo "REFUSING: $DEV now has label '$CUR_LABEL', expected '$LABEL'."
  echo "Disks may have been re-ordered. Re-run: python disk_recycler.py --drive $LABEL"
  exit 1
fi

# Guard 3 — typed confirmation.
read -r -p "Type the label '$LABEL' to confirm the WIPE: " ANS
[ "$ANS" = "$LABEL" ] || {{ echo "Aborted."; exit 1; }}

# Unmount wherever it is mounted.
if mountpoint -q "$MOUNT"; then sudo umount "$MOUNT"; fi
sudo umount "$DEV" 2>/dev/null || true

# Fresh filesystem.
sudo wipefs -a "$DEV"
sudo mkfs.ext4 -L "$LABEL" "$DEV"

echo
echo "Done — $DEV is now a clean ext4 volume labelled '$LABEL'."
echo "Re-mount it, then scan it as 'trusted' so the next faulty drive can drain into it:"
echo "  python disk_mapper.py scan --drive $LABEL \\\"$MOUNT\\\" trusted"
"""


def emit_script(rep: dict, dev_node: dict, mount: str, out_path: str):
    system_cases = "|".join(sorted(SYSTEM_MOUNTS))
    script = REFORMAT_TEMPLATE.format(
        when=time.strftime("%Y-%m-%d %H:%M:%S"),
        label=rep["label"],
        dev=dev_node["path"],
        mount=mount,
        copies=rep["copies"],
        tarballs=rep["tarballs"],
        system_cases=system_cases,
    )
    with open(out_path, "w") as fh:
        fh.write(script)
    os.chmod(out_path, 0o755)


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--db",    default="inventory.db",        help="Inventory database")
    p.add_argument("--plan",  default="migration_plan.json", help="Plan from migration_planner.py")
    p.add_argument("--drive", metavar="LABEL", help="Faulty drive to verify + emit a reformat script for")
    p.add_argument("--out",   metavar="FILE",  help="Script path (default: reformat_<LABEL>.sh)")
    p.add_argument("--deep",  action="store_true", help="Count every tar member (thorough but slow)")
    args = p.parse_args()

    if not os.path.exists(args.plan):
        sys.exit(f"Plan not found: {args.plan} — run migration_planner.py first.")
    with open(args.plan) as fh:
        plan = json.load(fh)

    conn = sqlite3.connect(args.db)
    conn.row_factory = sqlite3.Row
    drives = {r["label"]: dict(r) for r in conn.execute("SELECT * FROM drives")}
    conn.close()
    faulty = [k for k, v in drives.items() if not v["is_trusted"]]

    # ── No drive given: readiness overview of every faulty drive ──────────────
    if not args.drive:
        t = Table(title="Faulty drives — recycle readiness", show_lines=True)
        t.add_column("Drive", style="cyan")
        t.add_column("Ready?")
        t.add_column("Blockers")
        for label in faulty:
            rep = verify_evacuated(plan, label, deep=False)
            if rep["ready"]:
                t.add_row(label, "[green]READY", "—")
            else:
                bl = []
                if rep["missing_copies"]: bl.append(f"{len(rep['missing_copies'])} copies")
                if rep["bad_tarballs"]:   bl.append(f"{len(rep['bad_tarballs'])} tars")
                if rep["no_space"]:       bl.append(f"{rep['no_space']} no-space")
                if rep["reviews"]:        bl.append(f"{rep['reviews']} review")
                if rep["unverified_vtd"]: bl.append(f"{len(rep['unverified_vtd'])} unverified")
                t.add_row(label, "[red]NOT YET", ", ".join(bl))
        console.print(t)
        console.print("\nRun [cyan]python disk_recycler.py --drive <LABEL>[/] to verify one "
                      "drive in detail and emit its reformat script.")
        return

    label = args.drive
    if label not in drives:
        sys.exit(f"Unknown drive '{label}'. Known: {', '.join(drives)}")
    if drives[label]["is_trusted"]:
        sys.exit(f"'{label}' is a TRUSTED drive — refusing to generate a wipe script for it.")

    mount = drives[label]["mount_point"]
    rep = verify_evacuated(plan, label, deep=args.deep)
    print_report(rep)

    if not rep["ready"]:
        console.print(Panel(
            f"[red]{label} is NOT fully evacuated — no reformat script written.[/]\n"
            "Resolve the blockers above (finish the COPY/TARBALL run, handle REVIEW/"
            "NO_SPACE items, run the executor's VERIFY_THEN_DELETE stage) and try again.",
            title="[red]Not safe to wipe", border_style="red",
        ))
        sys.exit(2)

    dev_node = find_device(label, mount)
    if not dev_node or not dev_node.get("path"):
        console.print(f"[red]Could not map '{label}' (mount {mount}) to a block device via lsblk.")
        console.print("Is the drive still connected? Re-run once it's visible.")
        sys.exit(3)

    if os.path.normpath(mount) in SYSTEM_MOUNTS or dev_node.get("mountpoint") in SYSTEM_MOUNTS:
        sys.exit(f"[red]'{mount}' looks like a system mount — refusing.")

    out_path = args.out or f"reformat_{label}.sh"
    emit_script(rep, dev_node, mount, out_path)

    console.print(Panel(
        f"[green]{label} is fully evacuated and safe to recycle.[/]\n\n"
        f"Device : [bold]{dev_node['path']}[/]  ({dev_node.get('size','?')})\n"
        f"Mount  : {mount}\n"
        f"Script : [bold]{out_path}[/]\n\n"
        "Next steps:\n"
        f"  1. [cyan]less {out_path}[/]      ← read it; confirm the device is correct\n"
        f"  2. [cyan]./{out_path}[/]         ← it will ask you to type the label to confirm\n"
        "  3. Re-mount the fresh disk and scan it as 'trusted' for the next drive.",
        title="[green]Reformat script ready", border_style="green",
    ))


if __name__ == "__main__":
    main()
