#!/bin/sh
# Build the tape from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/MoonPatrol.tap: the four standard ROM blocks of orig/MoonPatrol.tap.zip (docs/03-build-and-load.md 3.1):
#   block 0+1: the header "MOONPATROL" LINE 20 and the BASIC, src/tape/basic.asm;
#   block 2+3: the header "MOON" 24824 and the game $60F8-$FFFF, src/game/game.asm (written by kit/mkgame.py from
#   src/game/game.ann) with the resources src/res (tools/res_formats.py build). kit/tap.py writes the blocks.
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
# The game: $60F8-$FFFF, block 3 (40712 bytes)
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
# The BASIC loader, block 1 (187 bytes)
"$asm" --nologo --msg=war --lst=basic.lst "$here/src/tape/basic.asm"
python3 "$here/../../kit/tap.py" MoonPatrol.tap basic:MOONPATROL:20:loader.bin code:MOON:24824:game.bin
unzip -p "$here/orig/MoonPatrol.tap.zip" "Moon Patrol.tap" > orig-MoonPatrol.tap
cmp MoonPatrol.tap orig-MoonPatrol.tap && echo "build: MoonPatrol.tap identical to orig/MoonPatrol.tap.zip's Moon Patrol.tap"
