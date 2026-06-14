#!/bin/bash
# Removes snap Firefox and installs the official Mozilla .deb package instead.
# Based on: https://gist.github.com/jfeilbach/78d0ef94190fb07dee9ebfc34094702f

set -e

MOZILLA_KEY_FP="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"

echo "==> Stopping Firefox snap hunspell mount (if active)..."
sudo systemctl stop "var-snap-firefox-common-host\\x2dhunspell.mount" 2>/dev/null || true
sudo systemctl disable "var-snap-firefox-common-host\\x2dhunspell.mount" 2>/dev/null || true
sudo umount /var/snap/firefox/common/host-hunspell 2>/dev/null || true

echo "==> Removing Firefox snap..."
sudo snap disable firefox 2>/dev/null || true
sudo snap remove --purge firefox 2>/dev/null || true

echo "==> Pinning apt to block future snap Firefox installs..."
sudo tee /etc/apt/preferences.d/firefox-no-snap > /dev/null <<'EOF'
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
EOF

echo "==> Setting up Mozilla apt repository..."
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- \
    | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

echo "==> Verifying Mozilla signing key fingerprint..."
DETECTED_FP=$(gpg -n -q --import --import-options import-show \
    /etc/apt/keyrings/packages.mozilla.org.asc \
    | awk '/pub/{getline; gsub(/^ +| +$/, ""); print; exit}')

if [ "$DETECTED_FP" != "$MOZILLA_KEY_FP" ]; then
    echo "ERROR: Key fingerprint mismatch!"
    echo "  Expected : $MOZILLA_KEY_FP"
    echo "  Got      : $DETECTED_FP"
    exit 1
fi
echo "Key fingerprint OK: $DETECTED_FP"

echo "==> Adding Mozilla apt source..."
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
    | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null

echo "==> Setting Mozilla repo priority..."
sudo tee /etc/apt/preferences.d/mozilla > /dev/null <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

echo "==> Installing Firefox .deb..."
sudo apt-get update && sudo apt-get install -y --allow-downgrades firefox

echo ""
echo "==> Migrating snap profile to ~/.mozilla/firefox/ ? (y/N)"
read -r MIGRATE
if [[ "$MIGRATE" =~ ^[Yy]$ ]]; then
    SNAP_PROFILE=~/snap/firefox/common/.mozilla/firefox
    if [ -d "$SNAP_PROFILE" ]; then
        mkdir -p ~/.mozilla/firefox/
        cp -a "$SNAP_PROFILE"/. ~/.mozilla/firefox/
        echo "Profile migrated."
    else
        echo "No snap profile found at $SNAP_PROFILE — skipping."
    fi
fi

echo ""
echo "==> Remove snapd completely? This will purge all snaps and prevent reinstallation. (y/N)"
read -r REMOVE_SNAPD
if [[ "$REMOVE_SNAPD" =~ ^[Yy]$ ]]; then
    echo "==> Removing all remaining snaps..."
    for snap in $(snap list 2>/dev/null | awk 'NR>1 {print $1}'); do
        sudo snap remove --purge "$snap" 2>/dev/null || true
    done
    echo "==> Purging snapd..."
    sudo apt-get remove --purge -y snapd
    sudo apt-mark hold snapd
    echo "==> Cleaning up snap directories..."
    sudo rm -rf /snap /var/snap /var/lib/snapd ~/snap
    echo "snapd removed and held."
fi

echo ""
echo "Done. Firefox .deb is installed and snap Firefox is blocked."
