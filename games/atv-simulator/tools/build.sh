#!/bin/sh
# Build orig/GAME.TAP from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1  # $SJASMPLUS, PATH or a checkout
mkdir -p "$here/build"
cd "$here/build"
if [ -f "$here/tools/res_formats.py" ]; then
    python3 "$here/tools/res_formats.py" build --out "$here/build/res"
fi
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
# The loader and the tape: the case writes its blocks here (kit/tap.py for standard ROM blocks)
# python3 "$here/../kit/tap.py" GAME.TAP basic:GAME:10:loader.bin code:GAME:24576:game.bin
cmp GAME.TAP "$here/orig/GAME.TAP" && echo "build: identical to orig/GAME.TAP"
