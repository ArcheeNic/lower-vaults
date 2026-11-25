#!/usr/bin/env bash
# Builds the Linux and Windows archives from a committed revision plus the local EOS config.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REF=${REF:-HEAD}
GODOT=${GODOT:-$HOME/.local/share/latticefall/godot-4.7.1-stable}
OUT=${OUT:-$ROOT/build/release}
CONFIG=$ROOT/network/eos.cfg

[[ -f "$CONFIG" ]] || { echo "network/eos.cfg is missing; multiplayer would be disabled." >&2; exit 1; }
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

git -C "$ROOT" archive "$REF" | tar -x -C "$WORK"
install -m 600 "$CONFIG" "$WORK/network/eos.cfg"
python3 "$WORK/tools/install_eos.py"
cd "$WORK"
"$GODOT" --headless --import
mkdir -p build/linux build/windows
"$GODOT" --headless --export-release Linux "$WORK/build/linux/LowerVaults.x86_64"
"$GODOT" --headless --export-release Windows "$WORK/build/windows/LowerVaults.exe"

rm -rf "$OUT"
mkdir -p "$OUT"
(cd build/linux && zip -qr "$OUT/LowerVaults-linux-x86_64.zip" .)
(cd build/windows && zip -qr "$OUT/LowerVaults-windows-x86_64.zip" .)
ls -l "$OUT"
