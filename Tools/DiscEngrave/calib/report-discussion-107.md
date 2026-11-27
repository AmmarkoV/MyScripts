**Drive:** HL-DT-ST BD-RE BU40N (firmware 1.05), Linux, SG_IO (no root)
**Disc:** DVD+R, MID `MCC/004/0`, 2,295,104 sectors. Brand: <FILL IN brand / product code from the pack>
**Result:** `geo` + quadratic-pitch correction, preset used as is (no DIS fine calibration). The crosshair target and then a photo burned correctly on the first try.

### Measuring
- `timing`: CAV, 2380 rpm with `--speed 5540`, jitter 5.5 µs (about 0.12°). The default speed was noisy.
- `geo`: readable range LBA 68848–1950832 (25.64–54.255 mm). Constant-pitch fit r0 23.95271 mm, pitch 0.740018 µm, chi2/dof 3.14, residual rms 0.329°. Check points drifted at most −0.175° (±0.127).
- `tools/geo_polyfit.py` quadratic correction: peak-to-peak 1.32°. `disexport` matches the measured map to 0.004° max (0.0007° rms) over 25.64–54.255 mm. It differs by up to 1.24° when extrapolated to 24–58 mm.

Preset:
```json
{
  "id": "mcc004-bu40n",
  "displayName": "MCC/004/0 DVD+R (disc-probe, BU40N)",
  "totalSectors": 2295104,
  "innerRadiusMm": 23.952666320979557,
  "outerRadiusMm": 57.98089780919333,
  "channelBitLengthNm": 133.3,
  "pitchLinear": -2.7621923983206538e-05,
  "pitchQuadratic": 1.9480957534534254e-05,
  "pitchCubic": 3.77140978822723e-08
}
```

### Burning
- DiscImageStudio 1.6.0 Linux CLI `solve` (dispersion, two tone levels) with the preset values, burned with `growisofs -dvd-compat -Z` at the default speed (it reported about 5–8x).
- Before this, a burn with textbook values (24 / 58 mm, constant pitch) showed no picture. By my estimate it was about 36 turns off across the radius.
- Verification: `target_slim.png` burned with the preset and scanned at 600 dpi on a flatbed. All four arms come out straight and radial, at right angles to each other. Measured bend from centre to edge: −0.9°, +0.4°, +0.5° and −1.9°. There's no sign of the roughly 116° one-ECC-block twist (#88). The whole picture is rotated by about 20°, which doesn't matter.
- A photo burned with the same preset came out right.

Scans attached: raw 600 dpi crosshair scan, and a high-pass version.
