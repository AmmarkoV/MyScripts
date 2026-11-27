#!/usr/bin/env bash
# Free disk space: shows each cache's size and asks Y/N before cleaning it.
#   pip cache , HuggingFace models , torch hub , apt package cache (sudo)
#   cleanup.sh        ask for each
#   cleanup.sh -n     only show the sizes, clean nothing
set -uo pipefail

DRY=0
[ "${1:-}" = "-n" ] && DRY=1

size() { du -sh "$1" 2>/dev/null | cut -f1; }

ask() {   # ask "question" -> 0 for yes
  [ "$DRY" -eq 1 ] && return 1
  local a
  read -r -p "$1 [y/N] " a
  [[ "$a" =~ ^[Yy]$ ]]
}

echo "free before: $(df -h --output=avail "$HOME" | tail -1 | tr -d ' ') on $HOME"
echo

# --- pip -----------------------------------------------------------------------------------------
PIP_DIR="$(pip cache dir 2>/dev/null || echo "$HOME/.cache/pip")"
if [ -d "$PIP_DIR" ]; then
  echo "pip cache: $PIP_DIR ($(size "$PIP_DIR"))"
  if ask "  purge the pip cache?"; then
    pip cache purge 2>/dev/null || rm -rf "$PIP_DIR"
  fi
else
  echo "pip cache: none"
fi
echo

# --- HuggingFace: per model, they are big and some may still be needed -----------------------------
HF_DIR="${HF_HOME:-$HOME/.cache/huggingface}/hub"
if [ -d "$HF_DIR" ]; then
  echo "HuggingFace models: $HF_DIR ($(size "$HF_DIR"))"
  for m in "$HF_DIR"/models--* "$HF_DIR"/datasets--*; do
    [ -d "$m" ] || continue
    name="$(basename "$m" | sed 's/^models--//; s/^datasets--/dataset: /; s/--/\//g')"
    if ask "  delete $name ($(size "$m"))?"; then rm -rf "$m"; fi
    [ "$DRY" -eq 1 ] && echo "  $name ($(size "$m"))"
  done
else
  echo "HuggingFace models: none"
fi
echo

# --- torch hub -----------------------------------------------------------------------------------
TORCH_DIR="${TORCH_HOME:-$HOME/.cache/torch}"
if [ -d "$TORCH_DIR" ]; then
  echo "torch cache: $TORCH_DIR ($(size "$TORCH_DIR"))"
  if ask "  delete the torch cache (downloaded weights, re-downloaded when needed)?"; then rm -rf "$TORCH_DIR"; fi
else
  echo "torch cache: none"
fi
echo

# --- apt -----------------------------------------------------------------------------------------
echo "apt package cache: /var/cache/apt/archives ($(size /var/cache/apt/archives))"
if ask "  sudo apt clean?"; then sudo apt clean; fi
echo

echo "free after: $(df -h --output=avail "$HOME" | tail -1 | tr -d ' ') on $HOME"
