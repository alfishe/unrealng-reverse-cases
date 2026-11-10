#!/bin/sh
# Build the tape of Tujad from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Tujad.tap: the five data blocks of orig/Tujad.tzx.zip (Tujad.tzx blocks 1-5) as TAP:
#   block 1, the header "TUJAD" (kit/tap.py: LINE 10, the program length 88 found by walking the line);
#   block 2, the BASIC program $5CCB-$5D22 from src/tape/basic.asm (kit/mkgame.py from src/tape/basic.ann);
#   block 3, the header "TUJAD" of a CODE file, 6944 bytes at 32768;
#   block 4, the loading screen and the stub $4000-$5B1F from src/screen/screen.asm (src/screen/screen.ann and
#     src/res/screen);
#   block 5, headerless, the game $60C0-$FDFF from src/game/game.asm (src/game/game.ann and src/res).
# Every block carries its flag and XOR checksum (kit/tap.py). build/orig.tap is the original's five blocks
# (tools/tape.py --orig); the two files must be identical. The TZX's timings and pauses are not data.
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
python3 "$here/tools/res_formats.py" build --out "$here/build/res"
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
"$asm" --nologo --msg=war -I"$here/src/tape" --lst=basic.lst "$here/src/tape/basic.asm"
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/screen" --lst=screen.lst "$here/src/screen/screen.asm"
python3 "$here/../../kit/tap.py" Tujad.tap basic:TUJAD:10:basic.bin code:TUJAD:32768:screen.bin data:-:-:game.bin
python3 "$here/tools/tape.py" --orig orig.tap
cmp Tujad.tap orig.tap && echo "build: identical to the original's blocks 1-5 (build/orig.tap)"
