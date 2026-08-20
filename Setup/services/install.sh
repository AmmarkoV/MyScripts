#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

BIN="/usr/local/bin/nvidia-power-cap.sh"
UNIT="/etc/systemd/system/nvidia-power-cap.service"

sudo install -m 755 nvidia-power-cap.sh "$BIN"
sed "s|^ExecStart=.*|ExecStart=$BIN|" nvidia-power-cap.service | sudo tee "$UNIT" >/dev/null

sudo systemctl daemon-reload
sudo systemctl enable --now nvidia-power-cap.service

exit 0
