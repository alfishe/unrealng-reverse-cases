#!/bin/sh
# Build the tape of MASK III from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/mask3.tzx: the eight blocks of orig/MASKIII-VENOMStrikesBack.tzx.zip's "Mask III.tzx" (src/tape/tape.txt,
# docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: block 2, the BASIC "MASK3" (block 1 its header);
#   - src/loader/loader.asm: block 4, the loader at $FF00 that runs at $5E00 (block 3 its header);
#   - src/screen/screen.asm: block 5, the loading screen;
#   - src/game/game.asm: block 6, the game $6000-$FDFF;
#   - src/music/music.asm: block 7, the AY music for RAM 4 at $C000.
# Every .asm is written by kit/mkgame.py from its .ann (tools/regen.sh); src/res by tools/res_formats.py.
# build/orig.tzx is the original (tools/image.py --tzx); the two files must be identical.
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
a "$here/src/loader/loader.asm"
a "$here/src/screen/screen.asm"
a "$here/src/game/game.asm"
a "$here/src/music/music.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" mask3.tzx .
python3 "$here/tools/image.py" orig.tzx --tzx > /dev/null
cmp mask3.tzx orig.tzx && echo "build: identical to orig/MASKIII-VENOMStrikesBack.tzx.zip's \"Mask III.tzx\" (build/orig.tzx)"
