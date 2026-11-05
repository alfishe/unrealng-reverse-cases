#!/bin/sh
# Build the tapes from the sources and compare them with the originals, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Zynaps.tzx: the nine blocks of orig/Zynaps.tzx.zip's TZX (docs/03-build-and-load.md 3.1, 3.8), from
#   src/tape/basic.asm (block 2), src/tape/loader.asm (block 4, the XOR chain applied by tools/xorchain.py),
#   src/tape/picy.asm (block 6, the loading screen src/res/screens/loading.scr packed by tools/picy.py) and
#   src/game/game.asm (block 8, written by kit/mkgame.py from src/game/game.ann); src/tape/zynaps-tzx.txt lists the
#   blocks, their headers and pauses and the archive-info block (tools/tzx.py writes them).
# build/ZYNAPS.TAP: the 1993 re-tape of orig/Zynaps.tap.zip, from src/tape/drj/basic.asm, src/tape/drj/zynaps0.asm
#   (the same screen packed by tools/rle_drj.py) and the game from $6801.
#
# One build at a time: a second one waits for build/.lock (a directory) to go away.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-sjasmplus}}
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
# The game: $61A8-$FFFE as the loader's move leaves it (block 8 is these 40535 bytes)
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
# The Hewson tape
"$asm" --nologo --msg=war --lst=basic.lst "$here/src/tape/basic.asm"
"$asm" --nologo --msg=war --lst=loader.lst "$here/src/tape/loader.asm"
python3 "$here/tools/xorchain.py" encrypt loader-plain.bin loader.bin
python3 "$here/tools/picy.py" pack "$here/build/res/screens/loading.scr" "$here/build/res"
"$asm" --nologo --msg=war -I"$here/build" --lst=picy.lst "$here/src/tape/picy.asm"
python3 "$here/tools/tzx.py" "$here/src/tape/zynaps-tzx.txt" Zynaps.tzx .
unzip -p "$here/orig/Zynaps.tzx.zip" Zynaps.tzx > orig-Zynaps.tzx
cmp Zynaps.tzx orig-Zynaps.tzx && echo "build: Zynaps.tzx identical to orig/Zynaps.tzx.zip's Zynaps.tzx"
# The 1993 re-tape
"$asm" --nologo --msg=war --lst=drj-basic.lst "$here/src/tape/drj/basic.asm"
python3 "$here/tools/rle_drj.py" pack "$here/build/res/screens/loading.scr" "$here/build/res/drj-screen.rle"
"$asm" --nologo --msg=war -I"$here/build" --lst=zynaps0.lst "$here/src/tape/drj/zynaps0.asm"
python3 -c "open('zynaps1.bin', 'wb').write(open('game.bin', 'rb').read()[0x6801 - 0x61A8:])"
python3 "$here/../../kit/tap.py" ZYNAPS.TAP basic:Zynaps:10:drj-basic.bin code:zynaps0.c:50000:zynaps0.bin \
    code:zynaps1.c:26625:zynaps1.bin
unzip -p "$here/orig/Zynaps.tap.zip" ZYNAPS.TAP > orig-ZYNAPS.TAP
cmp ZYNAPS.TAP orig-ZYNAPS.TAP && echo "build: ZYNAPS.TAP identical to orig/Zynaps.tap.zip's ZYNAPS.TAP"
