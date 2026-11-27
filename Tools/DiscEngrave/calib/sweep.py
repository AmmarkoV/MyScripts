#!/usr/bin/env python3
"""Build a DVD "radius sweep" calibration ISO for a disc with unknown geometry.

The 24-58 mm area is split into narrow bands separated by solid black rings.
Each band is drawn with a different guess of the track radius (a shift d of
both generation radii) and shows one black 90-degree wedge. Where a guess is
within about +/-0.02 mm of the real track radius, the wedge edges come out
sharp and gently curved; elsewhere they smear. `fit-tool --sweep` fits the
real geometry to edges traced in a photo.

Every sector's bytes depend only on its own address and the image sample at
its assumed position, so bands are spliced from per-guess ISOs at ECC-block
(16-sector) boundaries.

Usage: ./sweep.py [-o calib/sweep.iso]   (writes <iso>.json next to it)
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
CLI = Path(os.environ.get(
    "DISC_IMAGE_STUDIO",
    HERE.parent / "runtime" / "disc-image-studio"))
SECTORS = 2_295_104
INNER, OUTER = 24.0, 58.0
SECTOR_BYTES = 2048
BAND_START, BAND_WIDTH, BAND_PITCH = 24.15, 0.8, 1.05
SHIFTS = [round(-0.18 + 0.04 * i, 2) for i in range(10)]  # -0.18 .. +0.18 mm
IMAGE_SIZE = 2400


def sector_at_radius(radius: float) -> int:
    """Nominal constant-pitch sector index at a radius, aligned to an ECC block."""
    progress = (radius**2 - INNER**2) / (OUTER**2 - INNER**2)
    return int(round(progress * SECTORS / 16)) * 16


def bands() -> list[dict]:
    result = []
    k = 0
    while BAND_START + BAND_PITCH * k + BAND_WIDTH <= OUTER - 0.1:
        r0 = BAND_START + BAND_PITCH * k
        result.append({
            "index": k,
            "innerRadiusMm": round(r0, 4),
            "outerRadiusMm": round(r0 + BAND_WIDTH, 4),
            "startSector": sector_at_radius(r0),
            "endSector": sector_at_radius(r0 + BAND_WIDTH),
            "shiftMm": SHIFTS[k % len(SHIFTS)],
        })
        k += 1
    return result


def make_images(folder: Path) -> tuple[Path, Path]:
    wedge = Image.new("L", (IMAGE_SIZE, IMAGE_SIZE), 255)
    c = (IMAGE_SIZE - 1) / 2
    # One quadrant, from the image centre to beyond the corners.
    ImageDraw.Draw(wedge).polygon([(c, c), (IMAGE_SIZE * 2, c), (IMAGE_SIZE * 2, -IMAGE_SIZE)], fill=0)
    black = Image.new("L", (IMAGE_SIZE, IMAGE_SIZE), 0)
    wedge_path, black_path = folder / "sweep-wedge.png", folder / "sweep-black.png"
    wedge.convert("RGB").save(wedge_path)
    black.convert("RGB").save(black_path)
    return wedge_path, black_path


def solve(image: Path, iso: Path, shift: float) -> None:
    command = [
        str(CLI), "solve", "--image", str(image), "--iso-output", str(iso),
        "--total-sectors", str(SECTORS),
        "--inner-radius-mm", repr(INNER + shift), "--outer-radius-mm", repr(OUTER + shift),
        "--spiral-direction", "cw", "--image-threshold", "128", "--alpha-threshold", "1",
        "--tone-dither", "0", "--tone-levels", "2", "--tone-brightness", "0", "--tone-gamma", "false",
        "--algorithm", "dispersion", "--iterations-per-block", "1", "--fast-output", "true",
        "--volume-label", "SWEEP", "--fill-sectors", str(SECTORS),
    ]
    print(f"generating shift {shift:+.2f} mm from {image.name}", flush=True)
    subprocess.run(command, check=True, stdout=subprocess.DEVNULL)


def splice(source: Path, target: Path, start: int, end: int) -> None:
    with open(source, "rb") as src, open(target, "r+b") as dst:
        src.seek(start * SECTOR_BYTES)
        dst.seek(start * SECTOR_BYTES)
        remaining = (end - start) * SECTOR_BYTES
        while remaining:
            chunk = src.read(min(remaining, 64 << 20))
            dst.write(chunk)
            remaining -= len(chunk)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("-o", "--output", type=Path, default=HERE / "sweep.iso")
    args = parser.parse_args()
    folder = args.output.parent
    layout = bands()
    wedge, black = make_images(folder)

    # Black everywhere first (the separating rings), then each guess's bands.
    solve(black, args.output, 0.0)
    temp = folder / "sweep-temp.iso"
    try:
        for shift in SHIFTS:
            mine = [band for band in layout if band["shiftMm"] == shift]
            solve(wedge, temp, shift)
            for band in mine:
                splice(temp, args.output, band["startSector"], band["endSector"])
    finally:
        temp.unlink(missing_ok=True)
        Path(str(temp) + ".json").unlink(missing_ok=True)
    Path(str(args.output) + ".json").unlink(missing_ok=True)  # the black ISO's sidecar

    description = {
        "format": "radius-sweep-v1",
        "totalSectors": SECTORS, "innerRadiusMm": INNER, "outerRadiusMm": OUTER,
        "channelBitNm": 133.3, "spiral": "cw", "wedgeImage": wedge.name, "bands": layout,
    }
    meta = args.output.with_suffix(".sweep.json")
    meta.write_text(json.dumps(description, indent=2))
    print(f"ISO:    {args.output}\nLayout: {meta} ({len(layout)} bands)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
