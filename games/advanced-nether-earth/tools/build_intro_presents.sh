#!/bin/sh
# "Presents" ($6600-$D4A3) from src/intro/presents and src/res/intro/presents into build/intro/d02-6600.bin, compared
# byte for byte with src/res/img/d02-6600.bin while that raw image is there. Called by tools/build_intro.sh.
#
#   tools/build_intro_presents.sh [SJASMPLUS]
#
# The frames' PNG (tools/intro_presents.py) -> build/intro/res/presents/frames.bin, which presentsmain.asm INCBINs.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/intro"
mkdir -p "$b/res/presents"
python3 "$here/tools/intro_presents.py" to-bin "$here/src/res/intro/presents/frames.png" "$b/res/presents/frames.bin"
(cd "$b" && "$asm" --nologo --msg=war -I"$b" --lst="$b/presents.lst" "$here/src/intro/presents/presents.asm")
mv "$b/presents.bin" "$b/d02-6600.bin"
raw="$here/src/res/img/d02-6600.bin"
if [ -f "$raw" ]; then
    cmp "$b/d02-6600.bin" "$raw" >/dev/null || { echo "build_intro_presents: build/intro/d02-6600.bin differs from $raw" >&2; exit 1; }
fi
echo "build_intro_presents: identical"
