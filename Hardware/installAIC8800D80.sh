#!/bin/bash
# Fresh install of the AIC8800D80 USB WiFi 6 + Bluetooth driver.
#
# For dongles reporting chip_id=7, chip_mcu_id=1 that enumerate:
#   a69c:5721 (storage) -> a69c:8d80 (bootrom) -> 368b:8d81 (wifi+bt)
#
# Uses the legacy-mcu1 branch of shenmintao/aic8800d80. That branch matters:
# other trees (notably the ademasi BT patches) force fmacfw_8800d80_h_u02.bin,
# which is firmware for a DIFFERENT silicon revision. It boots far enough to
# expose Bluetooth USB endpoints, but the BT core never runs -- hci0 comes up
# with BD Address 00:00:00:00:00:00 and HCI_Reset fails with -110.
#
# Run as a normal user; it sudos where needed.

REPO_DIR="$HOME/Documents/3dParty/aic8800d80-legacy-mcu1"
REPO_URL="https://github.com/shenmintao/aic8800d80.git"
BRANCH="legacy-mcu1"

echo "=============================================="
echo " AIC8800D80 WiFi + Bluetooth installer"
echo "=============================================="

#==============================================
# Warn early if this is the wrong hardware revision for this branch
#==============================================
MCU=$( { sudo dmesg 2>/dev/null || journalctl -k -b 2>/dev/null; } |
       grep -o 'chip_mcu_id = [0-9]' | tail -1 | grep -o '[0-9]$')
if [ -n "$MCU" ] && [ "$MCU" != "1" ]; then
  echo
  echo "WARNING: this dongle reports chip_mcu_id=$MCU, but this script installs"
  echo "the legacy-mcu1 branch (for chip_mcu_id=1). Use the 'main' branch instead."
  echo "Loading firmware for the wrong revision can freeze the machine."
  read -r -p "Continue anyway? [y/N] " a
  [ "$a" = "y" ] || exit 1
fi

#==============================================
# Dependencies
#==============================================
echo
echo "=== Installing dependencies ==="
sudo apt-get install -y git dkms build-essential usb-modeswitch eject mokutil || exit 1

#==============================================
# Get the driver source
#==============================================
echo
echo "=== Fetching driver source ($BRANCH) ==="
mkdir -p "$(dirname "$REPO_DIR")"
if [ -d "$REPO_DIR/.git" ]; then
  echo "Already cloned, updating..."
  git -C "$REPO_DIR" fetch origin "$BRANCH" && git -C "$REPO_DIR" reset --hard FETCH_HEAD
else
  git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$REPO_DIR" || exit 1
fi
[ -x "$REPO_DIR/install.sh" ] || { echo "install.sh missing in $REPO_DIR"; exit 1; }

#==============================================
# Unload cleanly BEFORE touching anything.
# Never pull this dongle while the driver holds a live connection -- the old
# driver's rwnx_close hits WARN_ON(1) on disconnect and can hard-hang the box.
#==============================================
echo
echo "=== Unloading any existing aic driver ==="
# Match on the USB vendor id: the net device's driver symlink just says "usb",
# so grepping it for "aic" never matches.
for DEV in $(ls /sys/class/net 2>/dev/null | grep '^wl'); do
  VID=$(cat "/sys/class/net/$DEV/device/idVendor" 2>/dev/null)
  case "$VID" in
    a69c|368b)
      echo "Disconnecting $DEV ($VID)"
      nmcli dev disconnect "$DEV" 2>/dev/null
      sudo ip link set "$DEV" down 2>/dev/null
      ;;
  esac
done
sleep 2
sudo modprobe -r aic8800_fdrv 2>/dev/null
sudo modprobe -r aic_load_fw 2>/dev/null
sudo modprobe -r aic_zlp_quirk 2>/dev/null

#==============================================
# Remove any previous install. Stale firmware from another revision is
# exactly what breaks Bluetooth, so wipe all of it.
#==============================================
echo
echo "=== Removing previous installs ==="
for V in $(dkms status 2>/dev/null | grep '^aic8800' | cut -d'/' -f2 | cut -d',' -f1 | sort -u); do
  echo "Removing aic8800/$V"
  sudo dkms remove "aic8800/$V" --all 2>/dev/null
done
sudo rm -rf /usr/src/aic8800-*
sudo rm -rf /lib/firmware/aic8800*

#==============================================
# Install (upstream installer: firmware, dkms, udev, initramfs)
#==============================================
echo
echo "=== Running upstream installer ==="
( cd "$REPO_DIR" && sudo ./install.sh ) || { echo "Installer failed"; exit 1; }

#==============================================
# Upstream builds only for the running kernel; cover the others too
#==============================================
echo
echo "=== Building for other installed kernels ==="
for KVER in $(ls /lib/modules); do
  if [ -d "/lib/modules/$KVER/build" ] && [ "$KVER" != "$(uname -r)" ]; then
    echo "--- $KVER ---"
    sudo dkms install aic8800/1.0.0 -k "$KVER" 2>/dev/null || echo "  skipped"
  fi
done

#==============================================
# This dongle ships as a mass-storage "driver CD" and must be mode-switched.
# Upstream ejects sd*; this rule drives usb_modeswitch directly, which is
# what has proven reliable on a69c:5721.
#==============================================
echo
echo "=== Installing usb_modeswitch rule for a69c:5721 ==="
sudo tee /etc/udev/rules.d/50-aic8800-modeswitch.rules >/dev/null <<'RULES'
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="a69c", ATTR{idProduct}=="5721", RUN+="/usr/sbin/usb_modeswitch -K -v a69c -p 5721"
RULES
sudo udevadm control --reload-rules

#==============================================
# aic_zlp_quirk is built by DKMS but is scoped strictly to 368b:8d81, both by
# MODULE_ALIAS and by a runtime VID/PID check. With the correct MCU1 firmware
# this dongle comes up as a69c:8d81, so the quirk stays inactive - that is the
# expected state, not a fault. Do not force-load it. (It fixes BT A2DP AAC
# stalls on 368b:8d81 only; see upstream issue #63.)
#==============================================

#==============================================
# Verify. dkms status lies -- it reported "installed" for modules that were
# 0 bytes after a crash ate them, so stat the real files. sync so a later
# crash cannot lose them again.
#==============================================
sync
echo
echo "=== Verifying ==="
FAIL=0
for M in aic8800_fdrv aic_load_fw aic_zlp_quirk; do
  F=$(find "/lib/modules/$(uname -r)/updates" -name "$M.ko*" 2>/dev/null | head -1)
  SZ=$(stat -c %s "$F" 2>/dev/null || echo 0)
  if [ "$SZ" -gt 1000 ]; then
    echo "  OK   $M ($SZ bytes)"
  else
    echo "  FAIL $M ($SZ bytes)"
    FAIL=1
  fi
done

FW=/lib/firmware/aic8800D80/fw_patch_table_8800d80_u02.bin
echo "  patch table: $(stat -c %s $FW 2>/dev/null) bytes (expect 984 = MCU1 set)"
if [ -e /lib/firmware/aic8800D80/fmacfw_8800d80_h_u02.bin ]; then
  echo "  WARNING: _h_ combo firmware present -- wrong revision for this chip"
  FAIL=1
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "Install INCOMPLETE - see failures above."
  exit 1
fi

echo "=============================================="
echo " Done. Unplug and replug the dongle."
echo "=============================================="
echo
echo "Verify with:"
echo "  sudo dmesg | grep -E 'chip_id|Upload|btmode'"
echo "  ip -br link                # wlan interface"
echo "  hciconfig -a               # BD Address must NOT be all zeros"
echo "  bluetoothctl list"
echo
echo "Correct output loads the PLAIN fmacfw_8800d80_u02.bin and btmode[4]:5."
echo
echo "NOTE: before ever unplugging this dongle, disconnect and unload first:"
echo "  nmcli dev disconnect <wlan>; sudo modprobe -r aic8800_fdrv aic_load_fw"

exit 0
