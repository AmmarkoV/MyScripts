#!/bin/bash
# cpuPowersave.sh - force the CPU into its most conservative, lowest-heat/lowest-voltage
# state, for extra stability while diagnosing the RAM bit-flip issue (see
# knowledge/ for context). Sets the "powersave" cpufreq governor on every core
# and disables turbo boost, since turbo is what pushes frequency/voltage the
# highest and is the most likely software-controllable thing to aggravate a
# marginal power delivery / signal integrity problem.
#
# Needs root (writes to /sys). Run with sudo:
#   sudo ./scripts/cpuPowersave.sh
#
# Usage:
#   sudo ./scripts/cpuPowersave.sh            # powersave governor + turbo off
#   sudo ./scripts/cpuPowersave.sh --max-freq 3000000   # also cap max frequency to 3.0GHz (in kHz)
#   sudo ./scripts/cpuPowersave.sh --status   # just print current state, change nothing

set -euo pipefail

CPUFREQ_GLOB=/sys/devices/system/cpu/cpu*/cpufreq
INTEL_PSTATE_NO_TURBO=/sys/devices/system/cpu/intel_pstate/no_turbo
CPUFREQ_BOOST=/sys/devices/system/cpu/cpufreq/boost

print_status() {
    echo "=== Governors ==="
    for f in $CPUFREQ_GLOB/scaling_governor; do
        echo "$(dirname "$(dirname "$f")" | xargs basename): $(cat "$f")"
    done
    echo "=== Frequency range (kHz) ==="
    for f in $CPUFREQ_GLOB/scaling_min_freq; do
        cpu=$(dirname "$(dirname "$f")" | xargs basename)
        min=$(cat "$f")
        max=$(cat "$(dirname "$f")/scaling_max_freq")
        cur=$(cat "$(dirname "$f")/scaling_cur_freq" 2>/dev/null || echo "?")
        echo "$cpu: min=$min max=$max cur=$cur"
    done
    echo "=== Turbo boost ==="
    if [ -f "$INTEL_PSTATE_NO_TURBO" ]; then
        v=$(cat "$INTEL_PSTATE_NO_TURBO")
        echo "intel_pstate/no_turbo = $v ($( [ "$v" = "1" ] && echo disabled || echo ENABLED ))"
    elif [ -f "$CPUFREQ_BOOST" ]; then
        v=$(cat "$CPUFREQ_BOOST")
        echo "cpufreq/boost = $v ($( [ "$v" = "0" ] && echo disabled || echo ENABLED ))"
    else
        echo "No turbo control file found (unknown driver)"
    fi
}

if [ "${1:-}" = "--status" ]; then
    print_status
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: needs root (writes to /sys). Re-run with sudo." >&2
    exit 1
fi

MAX_FREQ=""
if [ "${1:-}" = "--max-freq" ]; then
    MAX_FREQ="${2:-}"
    if [ -z "$MAX_FREQ" ]; then
        echo "Error: --max-freq needs a value in kHz, e.g. --max-freq 3000000" >&2
        exit 1
    fi
fi

echo "Setting 'powersave' governor on all cores..."
for f in $CPUFREQ_GLOB/scaling_governor; do
    echo powersave > "$f"
done

if [ -n "$MAX_FREQ" ]; then
    echo "Capping max frequency to ${MAX_FREQ} kHz on all cores..."
    for f in $CPUFREQ_GLOB/scaling_max_freq; do
        echo "$MAX_FREQ" > "$f"
    done
fi

echo "Disabling turbo boost..."
if [ -f "$INTEL_PSTATE_NO_TURBO" ]; then
    echo 1 > "$INTEL_PSTATE_NO_TURBO"
elif [ -f "$CPUFREQ_BOOST" ]; then
    echo 0 > "$CPUFREQ_BOOST"
else
    echo "  Warning: no turbo control file found (unknown cpufreq driver) -- skipped."
fi

echo ""
echo "Done. Current state:"
print_status

echo ""
echo "Note: none of this persists across reboot by itself -- re-run after each"
echo "boot, or add it to a systemd unit / cron @reboot if you want it permanent."

