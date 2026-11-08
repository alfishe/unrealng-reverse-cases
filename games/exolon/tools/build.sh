#!/bin/sh
# Build the tape from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Exolon.tzx: the nine blocks of orig/Exolon.tzx.zip's TZX (docs/03-build-and-load.md 3.1), from
#   src/tape/basic.asm (block 2), src/tape/loader.asm (block 4, the XOR chain applied by tools/xorchain.py),
#   src/tape/picy.asm (block 6, the loading screen src/res/screens/loading.scr packed by tools/picy.py) and
#   src/game/game.asm (block 8, written by kit/mkgame.py from src/game/game.ann); src/tape/exolon-tzx.txt lists the
#   blocks, their headers and pauses and the archive-info block (tools/tzx.py writes them).
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
# The game: $6D60-$FFFF as the loader's move leaves it (block 8 is these 37536 bytes)
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
# The Hewson tape
"$asm" --nologo --msg=war --lst=basic.lst "$here/src/tape/basic.asm"
"$asm" --nologo --msg=war --lst=loader.lst "$here/src/tape/loader.asm"
python3 "$here/tools/xorchain.py" encrypt loader-plain.bin loader.bin
python3 "$here/tools/picy.py" pack "$here/build/res/screens/loading.scr" "$here/build/res"
"$asm" --nologo --msg=war -I"$here/build" --lst=picy.lst "$here/src/tape/picy.asm"
python3 "$here/tools/tzx.py" "$here/src/tape/exolon-tzx.txt" Exolon.tzx .
unzip -p "$here/orig/Exolon.tzx.zip" Exolon.tzx > orig-Exolon.tzx
cmp Exolon.tzx orig-Exolon.tzx && echo "build: Exolon.tzx identical to orig/Exolon.tzx.zip's Exolon.tzx"
