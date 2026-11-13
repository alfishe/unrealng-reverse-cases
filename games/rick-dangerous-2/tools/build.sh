#!/bin/sh
# Build both sides of the tape of Rick Dangerous 2 from the sources and compare them with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/side-a.tzx and build/side-b.tzx: the two TZX files orig/RickDangerous2.tzx.zip holds (src/tape/side-a.txt,
# side-b.txt; docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: side A block 2, the BASIC "RICK-II";
#   - src/loader/loader.asm: side A block 4, the loader at $FF00 (enciphered by tools/mktape.py);
#   - src/screen/screen.asm: side A block 5, the loading screen;
#   - src/music/music.asm: side A block 6's first 4224 bytes, the AY music as it runs in RAM 1 at $C000;
#   - src/game/game.asm: side A block 6's $7080-$A7FF, the game;
#   - src/levels/levelN/levelN.asm: the five levels at $A800 (level 1 also side A block 6's $A800-$FCFF); side B
#     holds each with its maps' last 768 bytes enciphered (tools/mktape.py).
# The blocks of side A 5-6 and side B are written in the loader's bit-reversed form (tools/mktape.py "reversed").
# Every .asm is written by kit/mkgame.py from its .ann (tools/mkasm_all.sh); src/res by tools/res_formats.py.
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
rm -rf "$here/build/res" "$here/build/lres"
python3 "$here/tools/res_formats.py" build --out "$here/build/res" --levels "$here/build/lres"
a() { "$asm" --nologo --msg=war -I"$2" -I"$(dirname "$1")" --lst="$(basename "$1" .asm).lst" "$1"; }
a "$here/src/tape/basic.asm" "$here/build"
a "$here/src/loader/loader.asm" "$here/build"
a "$here/src/screen/screen.asm" "$here/build"
a "$here/src/music/music.asm" "$here/build"
a "$here/src/game/game.asm" "$here/build"
for n in 1 2 3 4 5; do
    mkdir -p "$here/build/lres/level$n"
    a "$here/src/levels/level$n/level$n.asm" "$here/build/lres/level$n"
done
python3 "$here/tools/mktape.py" "$here/src/tape/side-a.txt" side-a.tzx .
python3 "$here/tools/mktape.py" "$here/src/tape/side-b.txt" side-b.tzx .
python3 "$here/tools/mktape.py" --orig A orig-a.tzx
python3 "$here/tools/mktape.py" --orig B orig-b.tzx
cmp side-a.tzx orig-a.tzx && cmp side-b.tzx orig-b.tzx && \
    echo "build: side-a.tzx and side-b.tzx identical to orig/RickDangerous2.tzx.zip's Side A and Side B"
