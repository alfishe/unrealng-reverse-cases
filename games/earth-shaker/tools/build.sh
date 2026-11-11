#!/bin/sh
# Build the tape of Earth Shaker from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/EarthShaker.tap: Earth Shaker's four blocks of the Your Sinclair issue 63 covertape (Side 1, TZX blocks
# 10-13) as TAP:
#   block 10, the header "EARTH" of a BASIC program (kit/tap.py: LINE 1, the program length 107 found by walking
#     the line);
#   block 11, the BASIC program $5CCB-$5D35 from src/tape/basic.asm (kit/mkgame.py from src/tape/basic.ann);
#   block 12, the header "EARTH" of a CODE file, 37 566 bytes at 27970 ($6D42), parameter 2 32768;
#   block 13, the game $6D42-$FFFF from src/game/game.asm (src/game/game.ann and src/res).
# Every block carries its flag and XOR checksum (kit/tap.py). build/orig.tap is the original's four blocks
# (tools/tape.py --orig, which finds them by the BASIC header "EARTH"); the two files must be identical. The rest of
# the covertape, the TZX's text block, timings and pauses are not data.
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
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
"$asm" --nologo --msg=war -I"$here/src/tape" --lst=basic.lst "$here/src/tape/basic.asm"
python3 "$here/../../kit/tap.py" EarthShaker.tap basic:EARTH:1:basic.bin code:EARTH:27970:game.bin
python3 "$here/tools/tape.py" --orig orig.tap
cmp EarthShaker.tap orig.tap && echo "build: identical to the original's TZX blocks 10-13 (build/orig.tap)"
