#!/usr/bin/env python3
"""Make a black/white guide overlay and a 2-level preview for a disc picture.

The DVD solver centres the picture on the disc and scales its shorter side to
the outer diameter (2 x --outer-radius-mm); only the ring between the inner and
outer radius is written. This script draws that geometry at the picture's size:

  <image>-guide.png    transparent ring, darkened outside it, white/black rims
                       and a centre cross. Open it as a layer in GIMP
                       (File > Open as Layers) on top of the picture.
  <image>-preview.png  the picture in black and white (Floyd-Steinberg dither)
                       with everything off the ring greyed out. The real
                       burn uses the solver's own dither, so this is a guide.

Examples:
    ./disc_guide.py cover.png
    ./disc_guide.py cover.png --inner-radius-mm 23.99 --outer-radius-mm 57.96
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

# Same luminance weights as the solver's RasterImage.SampleDisc.
REC709_LUMA = (0.2126, 0.7152, 0.0722, 0)


def ring_mask(size: tuple[int, int], inner_px: float, outer_px: float) -> Image.Image:
    """255 on the writable ring, 0 elsewhere."""
    cx, cy = (size[0] - 1) / 2, (size[1] - 1) / 2
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((cx - outer_px, cy - outer_px, cx + outer_px, cy + outer_px), fill=255)
    draw.ellipse((cx - inner_px, cy - inner_px, cx + inner_px, cy + inner_px), fill=0)
    return mask


def draw_rims(image: Image.Image, inner_px: float, outer_px: float) -> None:
    """White circles with a black edge so they show on any background."""
    cx, cy = (image.width - 1) / 2, (image.height - 1) / 2
    line = max(1, round(min(image.size) / 400))
    draw = ImageDraw.Draw(image)
    for radius in (inner_px, outer_px):
        box = (cx - radius, cy - radius, cx + radius, cy + radius)
        draw.ellipse(box, outline=(0, 0, 0, 255), width=line * 3)
        draw.ellipse((box[0] + line, box[1] + line, box[2] - line, box[3] - line),
                     outline=(255, 255, 255, 255), width=line)
    arm = inner_px / 4
    for color, width in (((0, 0, 0, 255), line * 3), ((255, 255, 255, 255), line)):
        draw.line((cx - arm, cy, cx + arm, cy), fill=color, width=width)
        draw.line((cx, cy - arm, cx, cy + arm), fill=color, width=width)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Make a GIMP guide overlay and black/white preview for a disc picture.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("image", type=Path, help="source picture")
    parser.add_argument("--inner-radius-mm", type=float, default=24.0, help="track start radius")
    parser.add_argument("--outer-radius-mm", type=float, default=58.0, help="track end radius")
    parser.add_argument("--shade", type=int, default=170,
                        help="opacity (0-255) of the black outside the ring in the guide")
    args = parser.parse_args()
    if not 0 < args.inner_radius_mm < args.outer_radius_mm:
        parser.error("radii must satisfy 0 < --inner-radius-mm < --outer-radius-mm")

    source = Image.open(args.image)
    size = source.size
    outer_px = (min(size) - 1) / 2
    inner_px = outer_px * args.inner_radius_mm / args.outer_radius_mm
    mask = ring_mask(size, inner_px, outer_px)

    guide = Image.new("RGBA", size, (0, 0, 0, 0))
    guide.putalpha(ImageChops.invert(mask).point(lambda v: args.shade if v else 0))
    draw_rims(guide, inner_px, outer_px)
    guide_path = args.image.with_name(f"{args.image.stem}-guide.png")
    guide.save(guide_path)

    gray = source.convert("RGB").convert("L", matrix=REC709_LUMA)
    bw = gray.convert("1").convert("L")
    preview = Image.composite(bw, Image.new("L", size, 128), mask).convert("RGBA")
    draw_rims(preview, inner_px, outer_px)
    preview_path = args.image.with_name(f"{args.image.stem}-preview.png")
    preview.convert("RGB").save(preview_path)

    print(f"Guide:    {guide_path}")
    print(f"Preview:  {preview_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
