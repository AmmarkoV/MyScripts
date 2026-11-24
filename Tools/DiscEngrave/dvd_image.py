#!/usr/bin/env python3
"""Generate a burnable DVD ISO from an image and render its calibration preview.

Thin launcher for the self-contained DiscImageStudio Linux CLI. The published
release archive embeds the .NET runtime, so no .NET installation is needed; set
--cli, DISC_IMAGE_STUDIO, or put `disc-image-studio` on PATH.

Examples:
    ./dvd_image.py cover.png
    ./dvd_image.py cover.png --total-sectors 160 -o test.iso
    ./dvd_image.py cover.png --actual-inner-radius-mm 23.99 \
        --actual-outer-radius-mm 57.96
    ./dvd_image.py cover.png --burn /dev/sr0
    ./dvd_image.py cover.png --preset dis_preset.json

--preset loads a DiscImageStudio DVD preset (such as disc-probe's
dis_preset.json): sectors, radii, channel-bit length and pitch shape. Explicit
options still override it.

Generation uses the GUI's DVD dispersion defaults. Calibration runs the CLI's
`calibrate` command, which projects the picture through the measured geometry.
Pass the measured radii for your disc; without them the generated radii are
reused and the preview only shows the nominal geometry.
"""

from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

DEFAULT_TOTAL_SECTORS = 2_295_104  # standard 12 cm single-layer DVD (DVD-5)
DEFAULT_INNER_RADIUS_MM = 24.0
DEFAULT_OUTER_RADIUS_MM = 58.0
CLI_NAME = "disc-image-studio"
RELEASES_URL = "https://github.com/JiaFeiMiao-K-Cat/DiscImageStudio/releases"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a DVD ISO from an image and render a calibration preview.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("image", type=Path, help="source picture (PNG, JPEG, BMP or GIF)")
    parser.add_argument(
        "--preset", type=Path,
        help="DiscImageStudio DVD preset JSON; sets the geometry options below",
    )
    parser.add_argument("--channel-bit-nm", type=float, default=133.3, help="channel-bit length")
    parser.add_argument("--pitch-linear", type=float, default=0.0, help="relative pitch shape, linear")
    parser.add_argument("--pitch-quadratic", type=float, default=0.0, help="relative pitch shape, quadratic")
    parser.add_argument("--pitch-cubic", type=float, default=0.0, help="relative pitch shape, cubic")
    parser.add_argument(
        "-o", "--output", type=Path,
        help="output ISO (default: <image>-dvd.iso next to the image)",
    )
    parser.add_argument(
        "--calibration-output", type=Path,
        help="calibration preview PNG (default: <output>-calibration.png)",
    )
    parser.add_argument("--cli", type=Path, help=f"path to the {CLI_NAME} executable")
    parser.add_argument(
        "--total-sectors", type=int, default=DEFAULT_TOTAL_SECTORS,
        help="reported 2048-byte sector count; must be a multiple of 16",
    )
    parser.add_argument(
        "--inner-radius-mm", type=float, default=DEFAULT_INNER_RADIUS_MM,
        help="generated track start radius",
    )
    parser.add_argument(
        "--outer-radius-mm", type=float, default=DEFAULT_OUTER_RADIUS_MM,
        help="generated track end radius",
    )
    parser.add_argument(
        "--actual-inner-radius-mm", type=float,
        help="measured track start radius (default: same as --inner-radius-mm)",
    )
    parser.add_argument(
        "--actual-outer-radius-mm", type=float,
        help="measured track end radius (default: same as --outer-radius-mm)",
    )
    parser.add_argument("--preview-size", type=int, default=1024, help="calibration PNG size")
    parser.add_argument(
        "--samples-per-sector", type=int, default=16,
        help="calibration samples per sector (1-16)",
    )
    parser.add_argument(
        "--tone-dither", type=float, default=0.75,
        help="mix black/white textures; 0 is a hard threshold (0-1)",
    )
    parser.add_argument("--volume-label", default="DISC_IMAGE", help="ISO volume label")
    parser.add_argument(
        "--data-dir", type=Path,
        help="also store this folder's files on the disc (readable ISO 9660 filesystem)",
    )
    parser.add_argument(
        "--file-position", choices=("inner", "outer"), default="inner",
        help="ring the --data-dir files occupy; the picture is drawn everywhere else",
    )
    parser.add_argument(
        "--burn", metavar="DEVICE",
        help="write the ISO to this device with growisofs after generation",
    )
    parser.add_argument(
        "--yes", action="store_true",
        help="skip the confirmation prompt before burning",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="print the commands without running them",
    )
    preset_path = parser.parse_known_args()[0].preset
    if preset_path is not None:
        try:
            preset = json.loads(preset_path.read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            parser.error(f"cannot read preset {preset_path}: {error}")
        preset = preset.get("preset", preset)  # disc-probe's disexport wraps it
        fields = {
            "total_sectors": "totalSectors", "inner_radius_mm": "innerRadiusMm",
            "outer_radius_mm": "outerRadiusMm", "channel_bit_nm": "channelBitLengthNm",
            "pitch_linear": "pitchLinear", "pitch_quadratic": "pitchQuadratic",
            "pitch_cubic": "pitchCubic",
        }
        missing = [key for key in ("totalSectors", "innerRadiusMm", "outerRadiusMm") if key not in preset]
        if missing:
            parser.error(f"preset {preset_path} lacks {', '.join(missing)}; is it a DVD preset?")
        parser.set_defaults(**{dest: preset[key] for dest, key in fields.items() if key in preset})
    args = parser.parse_args()

    if not args.image.is_file():
        parser.error(f"image not found: {args.image}")
    if args.total_sectors <= 0 or args.total_sectors % 16:
        parser.error("--total-sectors must be a positive multiple of 16")
    if not 0 < args.inner_radius_mm < args.outer_radius_mm:
        parser.error("radii must satisfy 0 < --inner-radius-mm < --outer-radius-mm")
    measured = args.actual_inner_radius_mm is not None or args.actual_outer_radius_mm is not None
    if measured and (args.actual_inner_radius_mm is None or args.actual_outer_radius_mm is None):
        parser.error("pass both --actual-inner-radius-mm and --actual-outer-radius-mm")
    actual_inner = args.actual_inner_radius_mm
    actual_outer = args.actual_outer_radius_mm
    if actual_inner is None:
        actual_inner = args.inner_radius_mm
    if actual_outer is None:
        actual_outer = args.outer_radius_mm
    if not 0 < actual_inner < actual_outer:
        parser.error("radii must satisfy 0 < --actual-inner-radius-mm < --actual-outer-radius-mm")
    if args.data_dir is not None and not args.data_dir.is_dir():
        parser.error(f"data folder not found: {args.data_dir}")
    if not 0 <= args.tone_dither <= 1:
        parser.error("--tone-dither must be between 0 and 1")
    if not 1 <= args.samples_per_sector <= 16:
        parser.error("--samples-per-sector must be between 1 and 16")
    args.actual_inner_radius_mm = actual_inner
    args.actual_outer_radius_mm = actual_outer
    args.measured_radii = measured
    return args


def locate_cli(explicit: Path | None) -> Path | None:
    candidates: list[Path] = []
    if explicit is not None:
        candidates.append(explicit)
    else:
        if os.environ.get("DISC_IMAGE_STUDIO"):
            candidates.append(Path(os.environ["DISC_IMAGE_STUDIO"]))
        if found := shutil.which(CLI_NAME):
            candidates.append(Path(found))
        candidates.append(Path(__file__).resolve().parent / CLI_NAME)

    for candidate in candidates:
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return candidate.resolve()
    return None


def run(command: list[str], dry_run: bool) -> None:
    print("+ " + " ".join(shlex.quote(part) for part in command), flush=True)
    if not dry_run:
        subprocess.run(command, check=True)


def number(value: float) -> str:
    return format(value, ".12g")


def generate_commands(args: argparse.Namespace, cli: Path) -> tuple[list[str], list[str]]:
    image = str(args.image)
    sector_count = str(args.total_sectors)
    tone = [
        "--image-threshold", "128",
        "--alpha-threshold", "1",
        "--tone-dither", number(args.tone_dither),
        "--tone-levels", "2",
        "--tone-brightness", "0",
        "--tone-gamma", "false",
    ]
    shape = [
        "--channel-bit-nm", number(args.channel_bit_nm),
        "--pitch-linear", number(args.pitch_linear),
        "--pitch-quadratic", number(args.pitch_quadratic),
        "--pitch-cubic", number(args.pitch_cubic),
    ]
    generation = [
        str(cli), "solve",
        "--image", image,
        "--iso-output", str(args.output),
        "--total-sectors", sector_count,
        "--inner-radius-mm", number(args.inner_radius_mm),
        "--outer-radius-mm", number(args.outer_radius_mm),
        *shape,
        "--spiral-direction", "cw",
        *tone,
        "--algorithm", "dispersion",
        "--iterations-per-block", "1",
        "--fast-output", "true",
        "--volume-label", args.volume_label,
    ]
    if args.data_dir is not None:
        # Hybrid mode: the CLI places the files and computes the drawing range itself.
        generation += ["--data-dir", str(args.data_dir), "--file-position", args.file_position]
    else:
        generation += ["--fill-sectors", sector_count]
    calibration = [
        str(cli), "calibrate",
        "--image", image,
        "--output", str(args.calibration_output),
        "--total-sectors", sector_count,
        "--generated-inner-radius-mm", number(args.inner_radius_mm),
        "--generated-outer-radius-mm", number(args.outer_radius_mm),
        "--actual-inner-radius-mm", number(args.actual_inner_radius_mm),
        "--actual-outer-radius-mm", number(args.actual_outer_radius_mm),
        *shape,
        "--actual-pitch-linear", number(args.pitch_linear),
        "--actual-pitch-quadratic", number(args.pitch_quadratic),
        "--actual-pitch-cubic", number(args.pitch_cubic),
        "--spiral-direction", "cw",
        *tone,
        "--preview-size", str(args.preview_size),
        "--samples-per-sector", str(args.samples_per_sector),
    ]
    return generation, calibration


def burn_iso(device: str, iso: Path, assume_yes: bool, dry_run: bool) -> None:
    tool = shutil.which("growisofs")
    if tool is None:
        print("error: --burn requires growisofs (install dvd+rw-tools).", file=sys.stderr)
        raise SystemExit(1)
    if not dry_run:
        if not Path(device).exists():
            print(f"error: burn device not found: {device}", file=sys.stderr)
            raise SystemExit(1)
        if not assume_yes:
            if not sys.stdin.isatty():
                print("error: refusing to burn without confirmation; pass --yes.", file=sys.stderr)
                raise SystemExit(1)
            answer = input(f"Write {iso} to {device}? This consumes the disc. [y/N] ")
            if answer.strip().lower() not in ("y", "yes"):
                print("Cancelled.")
                raise SystemExit(130)
    run([tool, "-dvd-compat", "-Z", f"{device}={iso}"], dry_run)


def main() -> int:
    args = parse_args()
    if args.output is None:
        args.output = args.image.with_name(f"{args.image.stem}-dvd.iso")
    if args.calibration_output is None:
        args.calibration_output = args.output.with_name(f"{args.output.stem}-calibration.png")

    if not args.measured_radii:
        print(
            "note: no measured radii supplied; calibration reuses the generated radii. "
            "Pass --actual-inner-radius-mm/--actual-outer-radius-mm for a real preview.",
            file=sys.stderr,
        )

    cli = locate_cli(args.cli)
    if cli is None:
        if not args.dry_run:
            print(
                f"error: {CLI_NAME} not found.\n"
                "Pass --cli PATH, set DISC_IMAGE_STUDIO, or put the self-contained Linux\n"
                f"CLI next to this script or on PATH. Releases: {RELEASES_URL}",
                file=sys.stderr,
            )
            return 1
        cli = Path(CLI_NAME)
    generation, calibration = generate_commands(args, cli)

    try:
        run(generation, args.dry_run)
        run(calibration, args.dry_run)
        if args.burn:
            burn_iso(args.burn, args.output, args.yes, args.dry_run)
    except subprocess.CalledProcessError as error:
        return error.returncode or 1
    except KeyboardInterrupt:
        return 130

    if not args.dry_run:
        print(f"DVD ISO:      {args.output}")
        print(f"Calibration:  {args.calibration_output}")
        if not args.burn:
            print(f"To burn:      growisofs -dvd-compat -Z /dev/sr0={shlex.quote(str(args.output))}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
