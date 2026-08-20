#!/bin/bash

BIN="/usr/local/bin/nvidia-power-cap.sh"
UNIT="/etc/systemd/system/nvidia-power-cap.service"

sudo systemctl disable --now nvidia-power-cap.service
sudo rm -f "$UNIT" "$BIN"
sudo systemctl daemon-reload

exit 0
