#!/usr/bin/env bash
# gopro-webcam: expose a USB-connected GoPro as a V4L2 webcam while this runs.
# Ctrl+C stops the camera and undoes the module and firewall changes it made.

set -u

RES=1080
FOV=wide
VIDEO_NR=42
PORT=8554
GOPRO_USB_VENDOR=2672

usage() {
    cat <<EOF
Usage: $(basename "$0") [--res 1080|720|480] [--fov wide|narrow|superview|linear] [--device N]

Options default to --res $RES --fov $FOV --device $VIDEO_NR (/dev/video$VIDEO_NR).
EOF
}

log() { printf '[%(%H:%M:%S)T] %s\n' -1 "$*"; }
die() { log "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --res) RES="${2:-}"; shift 2 || die "--res needs a value" ;;
        --fov) FOV="${2:-}"; shift 2 || die "--fov needs a value" ;;
        --device) VIDEO_NR="${2:-}"; shift 2 || die "--device needs a value" ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

case "$RES" in
    1080) RES_ID=12 ;; 720) RES_ID=7 ;; 480) RES_ID=4 ;;
    *) die "unsupported resolution: $RES" ;;
esac
case "$FOV" in
    wide) FOV_ID=0 ;; narrow) FOV_ID=2 ;; superview) FOV_ID=3 ;; linear) FOV_ID=4 ;;
    *) die "unsupported field of view: $FOV" ;;
esac
[[ "$VIDEO_NR" =~ ^[0-9]+$ ]] || die "--device must be a number"

DEVICE="/dev/video$VIDEO_NR"
IFACE=""
CAM=""
FFMPEG_PID=""
SUDO_PID=""
LOADED_MODULE=0
FIREWALL_IFACE=""
WAITING=0

for tool in curl ffmpeg ip sudo; do
    command -v "$tool" >/dev/null || die "missing required tool: $tool"
done
modinfo v4l2loopback >/dev/null 2>&1 || die "v4l2loopback module is not installed"

api() { curl -fsS -m "${2:-5}" "http://$CAM:8080/$1" >/dev/null 2>&1; }

find_camera() {
    local dir addr
    for dir in /sys/class/net/*; do
        [ "$(cat "$dir/device/../idVendor" 2>/dev/null)" = "$GOPRO_USB_VENDOR" ] || continue
        addr=$(ip -4 -br addr show dev "${dir##*/}" | awk '{print $3}')
        [ -n "$addr" ] || continue
        IFACE="${dir##*/}"
        addr="${addr%/*}"
        CAM="${addr%.*}.51"
        return 0
    done
    return 1
}

setup_device() {
    [ -e "$DEVICE" ] && return 0
    if lsmod | grep -q '^v4l2loopback'; then
        die "v4l2loopback is already loaded without $DEVICE. Use --device with its number."
    fi
    log "Creating virtual camera $DEVICE"
    sudo modprobe v4l2loopback video_nr="$VIDEO_NR" card_label="GoPro" exclusive_caps=1 \
        || die "could not load v4l2loopback"
    LOADED_MODULE=1
}

open_firewall() {
    [ "$FIREWALL_IFACE" = "$IFACE" ] && return 0
    systemctl is-active --quiet ufw || return 0
    sudo ufw status | grep -q "$PORT/udp on $IFACE" && return 0
    log "Allowing UDP $PORT on $IFACE"
    sudo ufw allow in on "$IFACE" proto udp to any port "$PORT" >/dev/null \
        || die "could not add firewall rule"
    FIREWALL_IFACE="$IFACE"
}

stop_ffmpeg() {
    [ -n "$FFMPEG_PID" ] || return 0
    kill "$FFMPEG_PID" 2>/dev/null
    wait "$FFMPEG_PID" 2>/dev/null
    FFMPEG_PID=""
}

cleanup() {
    trap - EXIT INT TERM
    log "Shutting down"
    stop_ffmpeg
    if [ -n "$CAM" ]; then
        api gopro/webcam/stop
        api gopro/webcam/exit
    fi
    if [ -n "$FIREWALL_IFACE" ]; then
        sudo ufw delete allow in on "$FIREWALL_IFACE" proto udp to any port "$PORT" >/dev/null \
            || log "warning: could not remove firewall rule"
    fi
    if [ "$LOADED_MODULE" = 1 ]; then
        sudo modprobe -r v4l2loopback 2>/dev/null \
            || log "warning: $DEVICE is still in use, so v4l2loopback stayed loaded"
    fi
    [ -n "$SUDO_PID" ] && kill "$SUDO_PID" 2>/dev/null
}

sudo -v || die "sudo is required to set up the virtual camera"
( while sleep 60; do sudo -n true 2>/dev/null; done ) &
SUDO_PID=$!

trap cleanup EXIT
trap 'exit 0' INT TERM

setup_device

while true; do
    if ! find_camera; then
        [ "$WAITING" = 1 ] || log "Waiting for GoPro on USB. Check that it is on and plugged in."
        WAITING=1
        sleep 2
        continue
    fi
    WAITING=0
    open_firewall

    if ! api gopro/version; then
        log "Camera at $CAM is not answering yet"
        sleep 3
        continue
    fi

    log "Starting webcam mode on $CAM (${RES}p, $FOV)"
    api gopro/webcam/stop 10
    api "gopro/camera/control/wired_usb?p=1"
    if ! api "gopro/webcam/start?res=$RES_ID&fov=$FOV_ID&port=$PORT" 15; then
        log "Camera refused webcam start, retrying"
        sleep 3
        continue
    fi

    ffmpeg -nostdin -hide_banner -loglevel error \
        -fflags nobuffer -flags low_delay \
        -i "udp://@0.0.0.0:$PORT?overrun_nonfatal=1&fifo_size=50000000&timeout=10000000" \
        -an -vf format=yuv420p -f v4l2 "$DEVICE" &
    FFMPEG_PID=$!
    log "Running. Select \"GoPro\" ($DEVICE) in your app. Press Ctrl+C to stop."

    failures=0
    while kill -0 "$FFMPEG_PID" 2>/dev/null; do
        sleep 2
        api gopro/camera/keep_alive
        if api gopro/webcam/status; then
            failures=0
        else
            failures=$((failures + 1))
            [ "$failures" -lt 3 ] && continue
            log "Lost contact with the camera"
            break
        fi
    done

    stop_ffmpeg
    log "Stream stopped, reconnecting"
    sleep 2
done
