#!/bin/sh
# Build the tape of Bumpy from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/BUMPY.TAP: the six blocks of orig/Bumpy.tap.zip's BUMPY.TAP:
#   block 1, the header "BUMPY" (kit/tap.py: LINE 10, the program length 191 found by walking the line);
#   block 2, the BASIC program $5CCB-$5D89 from src/tape/basic.asm (kit/mkgame.py from src/tape/basic.ann);
#   block 3, the header "BUMPY.SCR" of a CODE file, 6912 bytes at 32768 (param 2 32768);
#   block 4, the loading screen from src/screen/screen.asm (src/screen/screen.ann and src/res/screens);
#   block 5, the header "BUMPY.CDE" of a CODE file, 38700 bytes at 25000 (param 2 32782);
#   block 6, the game $61A8-$F8D3 from src/game/game.asm (src/game/game.ann and src/res).
# Every block carries its flag and XOR checksum (kit/tap.py). build/orig.tap is the original (tools/image.py --tap);
# the two files must be identical. The Proein TZX (stage 1) holds the same six data blocks.
#
# One build at a time: a second one waits for build/.lock (a directory) to go away.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1  # $SJASMPLUS, PATH or a checkout
mkdir -p "$here/build"
lock="$here/build/.lock"
waited=0
while ! mkdir "$lock" 2>/dev/null; do
    if [ $waited -ge 600 ]; then
        echo "build: $lock held for 10 minutes (a crashed build? remove it)" >&2
        exit 1
    fi
    [ $waited -eq 0 ] && echo "build: waiting for another build ($lock)" >&2
    sleep 1
    waited=$((waited + 1))
done
trap 'rmdir "$lock"' EXIT INT TERM
cd "$here/build"
rm -rf "$here/build/res"
python3 "$here/tools/res_formats.py" build --out "$here/build/res"
a() { "$asm" --nologo --msg=war -I"$here/build" -I"$(dirname "$1")" --lst="$(basename "$1" .asm).lst" "$1"; }
a "$here/src/tape/basic.asm"
a "$here/src/screen/screen.asm"
a "$here/src/game/game.asm"
python3 "$here/../../kit/tap.py" BUMPY.TAP basic:BUMPY:10:basic.bin code:BUMPY.SCR:32768:screen.bin:32768 \
    code:BUMPY.CDE:25000:game.bin:32782
python3 "$here/tools/image.py" --tap orig.tap
cmp BUMPY.TAP orig.tap && echo "build: identical to orig/Bumpy.tap.zip's BUMPY.TAP (build/orig.tap)"
