#!/bin/sh
# Build the tape of Chuckie Egg from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/ChuckieEgg.tap: the four data blocks of orig/ChuckieEgg.tzx.zip ("Chuckie Egg.tzx" blocks 1-4) as TAP:
#   block 1, the header "CHUCKIE" (kit/tap.py: LINE 10, the program length 18 found by walking the lines);
#   block 2, the BASIC program $5CCB-$6322 from src/loader/loader.asm (written by kit/mkgame.py from
#     src/loader/loader.ann: line 10, the picture's graphics $5CE3, the loader $5EF3, the picture's codes $601C);
#   block 3, the two bytes `01 00` into ERR_SP from src/loader/errsp.asm (src/loader/errsp.ann);
#   block 4, the game $8214-$CBE7 from src/game/game.asm (src/game/game.ann) and src/res (tools/res_formats.py).
# Every block carries its flag and XOR checksum (kit/tap.py). build/orig.tap is the original's four blocks
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
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/loader" --lst=loader.lst "$here/src/loader/loader.asm"
"$asm" --nologo --msg=war -I"$here/src/loader" --lst=errsp.lst "$here/src/loader/errsp.asm"
python3 "$here/../../kit/tap.py" ChuckieEgg.tap basic:CHUCKIE:10:loader.bin data:-:-:errsp.bin data:-:-:game.bin
python3 "$here/tools/tape.py" --orig orig.tap
cmp ChuckieEgg.tap orig.tap && echo "build: identical to the original's blocks 1-4 (build/orig.tap)"
