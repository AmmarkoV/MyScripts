#!/usr/bin/env bash
# Run dvd_image.py with the downloaded Linux CLI (v1.6.0 release).
# Usage: ./run.sh disc-t2.png [--burn /dev/sr0] [other dvd_image.py options]
set -euo pipefail
HERE="$(dirname "$(readlink -f "$0")")"
export DISC_IMAGE_STUDIO="${DISC_IMAGE_STUDIO:-$HERE/runtime/disc-image-studio}"
exec "$HERE/dvd_image.py" "$@"
