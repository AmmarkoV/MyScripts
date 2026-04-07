#!/bin/bash

# Post-installation script for Lubuntu 24.04+
# https://lubuntu.me/downloads/
# Repositories and software come and go — feel free to customize to match your preferences.

set -euo pipefail

# -----------------------------------------------------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Ensure we're NOT running as root (script uses sudo internally)
if [ "$EUID" -eq 0 ]; then
    echo "Run this as a normal user (not root). It will sudo as needed."
    exit 1
fi

# Reusable yes/no prompt: prompt_yn "Question text"  →  returns 0 for yes, 1 for no
prompt_yn() {
    local ans
    read -rp "$1 (Y/N)? " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# Append lines to a root-owned file safely
# Usage: sudo_append "line" /path/to/file
sudo_append() {
    echo "$1" | sudo tee -a "$2" > /dev/null
}

# Write to a root-owned file safely (overwrite)
# Usage: sudo_write "line" /path/to/file
sudo_write() {
    echo "$1" | sudo tee "$2" > /dev/null
}

clear
echo "Lubuntu handy packages — post-install automation"
echo "================================================="

# -----------------------------------------------------------------------------------------------------------------------
# NVIDIA
# -----------------------------------------------------------------------------------------------------------------------

NVIDIA_GPU=$(lspci | grep "NVIDIA" || true)
if [ -n "$NVIDIA_GPU" ]; then
    echo
    echo "Detected NVIDIA GPU: $NVIDIA_GPU"
    echo

    if prompt_yn "Install NVIDIA drivers (nvidia-driver-570, Vulkan, nvtop)?"; then
        sudo add-apt-repository -y ppa:graphics-drivers/ppa
        sudo apt-get update
        # Update the driver version below to match your GPU generation
        sudo apt-get install -y nvidia-driver-570 libglew-dev nvtop freeglut3-dev \
            vulkan-tools vulkan-utility-libraries-dev
        # Allow resolution saving via polkit helper
        POLKIT_HELPER="/usr/share/screen-resolution-extra/nvidia-polkit"
        [ -f "$POLKIT_HELPER" ] && sudo chmod u+x "$POLKIT_HELPER"
    fi

    if prompt_yn "Install NVIDIA CUDA toolkit (via official NVIDIA repo)?"; then
        CUDA_KEYRING_DEB="cuda-keyring_1.1-1_all.deb"
        CUDA_KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/$CUDA_KEYRING_DEB"
        CUDA_KEYRING_SHA256="9b9b4df8f29a6e64a0e6ab66e05be48caa4d45a14a2b6b34965dc89f1d0c5cc7"

        wget -q -O "/tmp/$CUDA_KEYRING_DEB" "$CUDA_KEYRING_URL"
        echo "$CUDA_KEYRING_SHA256  /tmp/$CUDA_KEYRING_DEB" | sha256sum -c - || {
            echo "ERROR: CUDA keyring checksum mismatch — aborting CUDA install."
            # Continue script despite CUDA failure
        } && {
            sudo dpkg -i "/tmp/$CUDA_KEYRING_DEB"
            sudo apt-get update
            # Pin to a specific version or use cuda-toolkit for the latest
            sudo apt-get install -y cuda-libraries-dev-12-6 cuda-toolkit-12-6
            echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
            echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
            source ~/.bashrc
        }
    fi
fi

# -----------------------------------------------------------------------------------------------------------------------
# Razer peripherals
# -----------------------------------------------------------------------------------------------------------------------

RAZER_DEVICE=$(lsusb | grep "Razer" || true)
if [ -n "$RAZER_DEVICE" ]; then
    echo
    echo "Detected Razer device: $RAZER_DEVICE"
    echo

    if prompt_yn "Install Razer drivers (openrazer) and Polychromatic RGB tool?"; then
        sudo apt-get install -y openrazer-meta
        sudo add-apt-repository -y ppa:polychromatic/stable
        sudo apt-get update
        sudo apt-get install -y polychromatic
    fi
fi

# -----------------------------------------------------------------------------------------------------------------------
# Package groups
# -----------------------------------------------------------------------------------------------------------------------

BASICAPPS="firefox thunderbird vlc mumble libreoffice myspell-el-gr synaptic catfish \
    usb-creator-gtk remmina baobab brasero aisleriot"
# pidgin removed (unmaintained); consider hexchat or fractal for chat

GRAPHICS="gimp darktable"

AUDIO="mixxx audacity audacious"

MOREAPPS="simplescreenrecorder units qrencode lm-sensors"

COMPATIBILITY="samba chntpw"
# wine/winetricks: uncomment if needed

SYSTEM="smartmontools iat iotop iftop iperf ifmetric htop screen traceroute powertop \
    x11vnc net-tools libvdpau-va-gl1 curl wget vdpauinfo fastfetch chrony gddrescue ntfs-3g"
# neofetch dropped (removed from Ubuntu 24.04 repos); using fastfetch instead

SCREENSAVERS="xscreensaver xscreensaver-data xscreensaver-data-extra xscreensaver-gl xscreensaver-gl-extra"

ADVLIBS="festival imagemagick numlockx gxmessage libnotify-bin"

CODECS="ubuntu-restricted-extras pavucontrol beep ffmpeg mplayer smplayer"

SECURITY="network-manager-openvpn network-manager-openvpn-gnome"

DIGITALSIGNING="poppler-utils poppler-data libnss3-tools"

sudo apt-get install -y \
    $BASICAPPS $MOREAPPS $ADVLIBS $COMPATIBILITY $SYSTEM \
    $SCREENSAVERS $AUDIO $CODECS $GRAPHICS $SECURITY $DIGITALSIGNING

# -----------------------------------------------------------------------------------------------------------------------
# System clock
# -----------------------------------------------------------------------------------------------------------------------

timedatectl

# -----------------------------------------------------------------------------------------------------------------------
# Dist-upgrade
# -----------------------------------------------------------------------------------------------------------------------

sudo apt-get dist-upgrade -y

# -----------------------------------------------------------------------------------------------------------------------
# PulseAudio / PipeWire anti-stutter tweaks
# -----------------------------------------------------------------------------------------------------------------------

# Ubuntu/Lubuntu 24.04 defaults to PipeWire. Only apply PulseAudio tweaks if actually using it.
if systemctl --user is-active --quiet pulseaudio 2>/dev/null || \
   { command -v pactl &>/dev/null && pactl info 2>/dev/null | grep -q "PulseAudio"; }; then

    if grep -q "ammar" /etc/pulse/daemon.conf 2>/dev/null; then
        echo "PulseAudio settings seem to be ok!"
    else
        echo "Applying PulseAudio anti-stutter settings..."
        sudo_append "#ammar's lower stutter settings" /etc/pulse/daemon.conf
        sudo_append "resample-method = trivial"          /etc/pulse/daemon.conf
        sudo_append "default-sample-rate=44100"          /etc/pulse/daemon.conf
        sudo_append "default-fragments = 14"             /etc/pulse/daemon.conf
        sudo_append "default-fragment-size-msec = 16"    /etc/pulse/daemon.conf
    fi
else
    echo "PipeWire detected (default on 24.04) — PulseAudio tweaks skipped."
    echo "For PipeWire tuning, see: /usr/share/pipewire/pipewire.conf"
fi

# -----------------------------------------------------------------------------------------------------------------------
# Kernel image symlinks
# -----------------------------------------------------------------------------------------------------------------------

if grep -q "do_symlinks" /etc/kernel-img.conf 2>/dev/null; then
    echo "Kernel image settings seem to be ok!"
else
    sudo_append "do_symlinks = no"  /etc/kernel-img.conf
    sudo_append "no_symlinks = yes" /etc/kernel-img.conf
fi

# -----------------------------------------------------------------------------------------------------------------------
# TCP BBR congestion control
# -----------------------------------------------------------------------------------------------------------------------

BBR_CONF="/etc/sysctl.d/10-custom-kernel-bbr.conf"
if grep -q "tcp_congestion_control=bbr" "$BBR_CONF" 2>/dev/null; then
    echo "TCP BBR congestion control is already set!"
else
    echo "Setting up TCP BBR congestion control..."
    sudo_append "net.core.default_qdisc=fq"              "$BBR_CONF"
    sudo_append "net.ipv4.tcp_congestion_control=bbr"     "$BBR_CONF"
    sudo sysctl --system
fi

# -----------------------------------------------------------------------------------------------------------------------
# Keyboard layout (English + Greek, toggled with Alt+Shift)
# -----------------------------------------------------------------------------------------------------------------------

LXSESSION_AUTOSTART="/etc/xdg/lxsession/Lubuntu/autostart"
if grep -q "setxkbmap" "$LXSESSION_AUTOSTART" 2>/dev/null; then
    echo "Language settings seem to be ok!"
else
    echo "Adding English/Greek keyboard layout (Alt+Shift to toggle)..."
    sudo sh -c "echo '@setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr' >> $LXSESSION_AUTOSTART"
fi

# -----------------------------------------------------------------------------------------------------------------------
# Memory / swappiness optimisation (only if >8 GB RAM)
# -----------------------------------------------------------------------------------------------------------------------

MEM_KB=$(awk '/MemTotal/{print $2}' /proc/meminfo)
MEM_THRESHOLD_KB=$(( 8 * 1024 * 1024 ))   # 8 GB in kB

if (( MEM_KB > MEM_THRESHOLD_KB )); then
    echo "Detected plenty of RAM (${MEM_KB} kB) — optimising swappiness..."

    if grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
        echo "Memory usage optimisations already set up."
    else
        echo "Optimising memory usage for better disk access..."
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.dirty_ratio=99
        sudo sysctl vm.dirty_background_ratio=50
        sudo sysctl vm.vfs_cache_pressure=10

        sudo sh -c 'cat >> /etc/sysctl.conf << EOF
vm.swappiness = 10
vm.dirty_ratio = 99
vm.dirty_background_ratio = 50
vm.vfs_cache_pressure = 10
vm.nr_hugepages = 128
EOF'
        sudo swapoff -a
        sudo swapon -a
    fi
fi

# -----------------------------------------------------------------------------------------------------------------------
# Autostart directory
# -----------------------------------------------------------------------------------------------------------------------

mkdir -p ~/.config/autostart

if [ -f ~/.config/autostart/autostart.desktop ]; then
    echo "Found per-user autostart shortcut."
else
    echo "Generating new per-user autostart shortcut..."
    cat > ~/.config/autostart/autostart.desktop << EOF
[Desktop Entry]
Type=Application
Name=MyThings
Exec=$HOME/.autostart.sh
EOF
    chmod +x ~/.config/autostart/autostart.desktop
fi

# -----------------------------------------------------------------------------------------------------------------------
# Autostart script (~/.autostart.sh)
# -----------------------------------------------------------------------------------------------------------------------

if [ -f ~/.autostart.sh ]; then
    echo "Found per-user autostart bash script."
else
    echo "Generating new per-user autostart bash script..."
    cat > ~/.autostart.sh << 'EOF'
#!/bin/bash
setxkbmap -option grp:switch,grp:alt_shift_toggle,grp_led:scroll us,gr
xset r on
# xscreensaver -nosplash &
nm-applet &
numlockx on &
firefox &
# mumble &
# audacious &
plasmawindowed org.kde.kdeconnect --statusnotifier &
# x11vnc -nap -wait 50 -noxdamage -passwd YOUR_PASSWORD -display :0 -forever -o ~/x11vnc.log -bg

sleep 38
xdotool key "Ctrl+Alt+Right"   # Move to right workspace
thunderbird &
sleep 30
xdotool key "Ctrl+Alt+Left"    # Move back to left workspace

exit 0
EOF
    chmod +x ~/.autostart.sh
fi

# -----------------------------------------------------------------------------------------------------------------------
# Samba shared directory
# -----------------------------------------------------------------------------------------------------------------------

if [ -f /etc/samba/smb.conf ]; then
    if grep -q "\[SHARED\]" /etc/samba/smb.conf; then
        echo "Samba share already configured."
    else
        echo "Configuring Samba share (guest access — LAN only, no password)..."
        # WARNING: This share is open to all local network guests.
        # Remove 'guest ok' and 'guest only' and add a samba password for better security:
        #   sudo smbpasswd -a $(whoami)
        mkdir -p ~/SHARED
        sudo sh -c "cat >> /etc/samba/smb.conf << EOF

[SHARED]
path = $HOME/SHARED
writable = yes
guest ok = yes
guest only = yes
read only = no
create mode = 0777
directory mode = 0777
force user = nobody
EOF"
        sudo systemctl restart smbd
    fi
fi

# -----------------------------------------------------------------------------------------------------------------------
# KDE Connect "Send to Phone" desktop shortcut
# -----------------------------------------------------------------------------------------------------------------------

KDE_SENDER_DESKTOP="$HOME/.local/share/applications/kde-sender.desktop"
if [ -f "$KDE_SENDER_DESKTOP" ] && grep -q "Desktop" "$KDE_SENDER_DESKTOP"; then
    echo "KDE Sender shortcut already exists."
else
    # TODO: Replace the device ID below with your own (run: kdeconnect-cli -l)
    KDE_DEVICE_ID="ef8c0afdfcbd48c5b50ca17838de0a56"
    mkdir -p ~/.local/share/applications/
    cat > "$KDE_SENDER_DESKTOP" << EOF
[Desktop Entry]
Type=Application
Name=Send to Phone
Exec=kdeconnect-cli --device $KDE_DEVICE_ID --share %F
Icon=phone
Terminal=false
MimeType=application/octet-stream;inode/directory;image/*;video/*;audio/*;text/*;
EOF
    update-desktop-database ~/.local/share/applications
fi

# -----------------------------------------------------------------------------------------------------------------------
# Apport (crash reporter) — disable to avoid spam
# -----------------------------------------------------------------------------------------------------------------------

echo "Disabling Apport crash reporter..."
sudo service apport stop || true
sudo sh -c 'cat > /etc/default/apport << EOF
# Set to 0 to disable apport, 1 to enable
# ammar: disabled to prevent crash report spam
# Re-enable temporarily: sudo service apport start force_start=1
enabled=0
EOF'

# -----------------------------------------------------------------------------------------------------------------------
# sudo askpass helper
# -----------------------------------------------------------------------------------------------------------------------

if [ -f /etc/sudo.conf ]; then
    echo "Found /etc/sudo.conf — not modifying."
else
    echo "Setting ssh-askpass as sudo -A helper..."
    sudo_write "Path askpass /usr/bin/ssh-askpass" /etc/sudo.conf
fi

# -----------------------------------------------------------------------------------------------------------------------
# Squid web proxy (only if already installed)
# -----------------------------------------------------------------------------------------------------------------------

if [ -f /etc/squid/squid.conf ]; then
    echo "Squid detected — configuring local cache..."
    mkdir -p ~/cache/
    sudo sh -c "cat >> /etc/squid/conf.d/myProxy.conf << EOF
http_access allow localnet
acl localnet src 192.168.1.0/255.255.255.0
cache_dir diskd $HOME/cache 100 16 256
# Run: sudo systemctl restart squid.service  after any changes here
EOF"
    sudo systemctl restart squid.service
fi

# -----------------------------------------------------------------------------------------------------------------------
# TRIM support check (works with both SATA SSDs and NVMe)
# -----------------------------------------------------------------------------------------------------------------------

echo "Checking for SSD TRIM support..."
for disk in $(lsblk -dno NAME | grep -E '^(sd|nvme)'); do
    if sudo hdparm -I "/dev/$disk" 2>/dev/null | grep -q "TRIM supported"; then
        echo "  TRIM supported: /dev/$disk"
    else
        echo "  TRIM not reported or N/A: /dev/$disk"
    fi
done

# -----------------------------------------------------------------------------------------------------------------------
# Disable intel_powerclamp (can cause thermal throttle jitter)
# -----------------------------------------------------------------------------------------------------------------------

sudo_write "blacklist intel_powerclamp" /etc/modprobe.d/disable-powerclamp.conf

# -----------------------------------------------------------------------------------------------------------------------
# Custom wallpaper
# -----------------------------------------------------------------------------------------------------------------------

WALLPAPER_DIR="/usr/share/lubuntu/wallpapers"
WALLPAPER_URL="https://raw.githubusercontent.com/AmmarkoV/MyScripts/master/Multimedia/startup.png"
WALLPAPER_DEST="$WALLPAPER_DIR/startup.png"
WALLPAPER_ORIG="$WALLPAPER_DIR/lubuntu-default-wallpaper.png"

if [ ! -f "$WALLPAPER_DEST" ]; then
    echo "Downloading custom wallpaper..."
    sudo wget -q -O "$WALLPAPER_DEST" "$WALLPAPER_URL" && {
        [ -f "$WALLPAPER_ORIG" ] && sudo mv "$WALLPAPER_ORIG" "${WALLPAPER_ORIG%.png}OLD.png"
        sudo ln -sf "$WALLPAPER_DEST" "$WALLPAPER_ORIG"
    } || echo "WARNING: Wallpaper download failed — original wallpaper preserved."
fi

# -----------------------------------------------------------------------------------------------------------------------
# Firefox extensions (opens tabs for manual install)
# -----------------------------------------------------------------------------------------------------------------------

echo "Opening Firefox extension pages..."
firefox "https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/" \
        "https://addons.mozilla.org/en-US/firefox/addon/user-agent-switcher-revived/" &
# uBlock Origin preferred over Adblock Plus (lighter, more effective)

# -----------------------------------------------------------------------------------------------------------------------
# XScreensaver config
# -----------------------------------------------------------------------------------------------------------------------

cd "$DIR"
if wget -q -O xscreensaver "https://raw.githubusercontent.com/AmmarkoV/MyScripts/master/Setup/xscreensaver"; then
    cp xscreensaver ~/.xscreensaver
    echo "XScreensaver config applied."
else
    echo "WARNING: Could not download xscreensaver config."
fi

# -----------------------------------------------------------------------------------------------------------------------
# Lock screen script (~/.lock.sh)
# -----------------------------------------------------------------------------------------------------------------------

if [ -f ~/.lock.sh ]; then
    echo "Found per-user lock script."
else
    echo "Generating lock screen script..."
    cat > ~/.lock.sh << 'EOF'
#!/bin/bash
RUNNING=$(ps -A | grep -c xscreensaver || true)
if [ "$RUNNING" -eq 0 ]; then
    echo "XScreensaver not running — starting..."
    xscreensaver -nosplash &
    sleep 1
fi
xscreensaver-command -lock
exit 0
EOF
    chmod +x ~/.lock.sh
fi

# -----------------------------------------------------------------------------------------------------------------------
# Lock screen desktop shortcut
# -----------------------------------------------------------------------------------------------------------------------

LOCK_DESKTOP="$HOME/Desktop/lock.desktop"
if [ -f "$LOCK_DESKTOP" ] && grep -q "NUMBEROFSCREENSAVERDAEMONSRUNNING" "$LOCK_DESKTOP"; then
    echo "XScreensaver lock shortcut already set up."
else
    cat > "$LOCK_DESKTOP" << EOF
[Desktop Entry]
Type=Application
Name=Lock
Exec=$HOME/.lock.sh
Icon=system-lock-screen
Terminal=false
EOF
fi

# -----------------------------------------------------------------------------------------------------------------------
# LibreOffice PDF export fix for Lubuntu (LXQt + Qt5 backend)
# -----------------------------------------------------------------------------------------------------------------------

LXQT_ENV="$HOME/.config/lxqt/session.conf"
if grep -q "SAL_VCL_QT5_USE_CAIRO" "$LXQT_ENV" 2>/dev/null; then
    echo "LibreOffice PDF export fix already applied."
else
    echo "Applying LibreOffice PDF export fix (SAL_VCL_QT5_USE_CAIRO=true)..."
    mkdir -p "$(dirname "$LXQT_ENV")"
    sudo_append "SAL_VCL_QT5_USE_CAIRO=true" /etc/environment
fi

# -----------------------------------------------------------------------------------------------------------------------
# SSH key generation
# -----------------------------------------------------------------------------------------------------------------------

KEY_FILE="$HOME/.ssh/id_ed25519.pub"
if [ -f "$KEY_FILE" ]; then
    echo "SSH key already exists at $KEY_FILE"
else
    echo "No SSH key found."
    read -rp "Enter your email for SSH key generation: " EMAIL
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$EMAIL"
fi

echo
echo "SSH Public Key (add to GitHub → https://github.com/settings/keys):"
cat "$KEY_FILE"

# -----------------------------------------------------------------------------------------------------------------------
# Kernel image conf — allow apt to update kernels without symlinks
# -----------------------------------------------------------------------------------------------------------------------

if grep -q "do_symlinks" /etc/kernel-img.conf 2>/dev/null; then
    echo "Kernel image settings already configured."
else
    sudo_append "do_symlinks = no"  /etc/kernel-img.conf
    sudo_append "no_symlinks = yes" /etc/kernel-img.conf
fi

# -----------------------------------------------------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------------------------------------------------

echo "Removing applications we don't need..."
# sudo apt-get remove -y abiword gnumeric

fastfetch
echo "Configuration Complete" | festival --tts

# -----------------------------------------------------------------------------------------------------------------------
# Commented-out optional extras (uncomment to enable)
# -----------------------------------------------------------------------------------------------------------------------

# --- Replace Firefox Snap with Mozilla's official .deb ---
# sudo snap remove firefox
# sudo install -d -m 0755 /etc/apt/keyrings
# wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
# echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
# echo 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000' | sudo tee /etc/apt/preferences.d/mozilla
# sudo apt update && sudo apt install firefox

# --- Spotify ---
# curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
# echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
# sudo apt-get update && sudo apt-get install spotify-client

# --- Signal ---
# wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
# cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
# wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources
# cat signal-desktop.sources | sudo tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null
# sudo apt update && sudo apt install signal-desktop

# --- Mullvad VPN ---
# sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
# echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$(dpkg --print-architecture)] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list
# sudo apt update && sudo apt install mullvad-vpn

# --- Discord ---
# wget -O /tmp/discord-installer.deb "https://discordapp.com/api/download?platform=linux&format=deb"
# sudo dpkg -i /tmp/discord-installer.deb

# --- Steam ---
# sudo apt-get install -y libc6-i386
# wget -O ~/Downloads/steam.deb "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb"
# sudo dpkg -i ~/Downloads/steam.deb

# --- Fingerprint auth (e.g. Lenovo laptops) ---
# sudo apt install fprintd libpam-fprintd
# fprintd-enroll
# sudo pam-auth-update

# --- Swap file (8 GB) ---
# sudo fallocate -l 8G /swapfile
# sudo chmod 600 /swapfile
# sudo mkswap /swapfile
# sudo swapon /swapfile
# echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# --- Disable CPU speculation mitigations (performance, reduces security!) ---
# https://make-linux-fast-again.com/
# sudo sh -c 'echo "GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash mitigations=off\"" >> /etc/default/grub'
# sudo update-grub

# --- DVD playback ---
# sudo apt-get install libdvdread4
# sudo /usr/share/doc/libdvdread4/install-css.sh

# --- Fail2ban (server hardening) ---
# sudo apt-get install fail2ban

# --- Boot sound via GRUB ---
# sudo sh -c 'echo "GRUB_INIT_TUNE=\"1750 523 1 392 1 523 1 659 1 784 1 1047 1 784 1\"" >> /etc/default/grub'
# sudo update-grub

exit 0
