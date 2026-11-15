#!/bin/sh
# Build both sides of the tape of Rex from the sources and compare them with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/side1.tzx and build/side2.tzx: the two TZX files orig/Rex.tzx.zip holds (src/tape/side1.txt, side2.txt;
# docs/03-build-and-load.md 3.1), from
#   - src/tape/basic-rex1.asm, basic-rex2.asm, basic-demo.asm: the BASIC programs "REX 1", "REX 2" and "DEMO";
#   - src/screen/screen-rex1.asm, screen-rex2.asm, screen-demo.asm: the three loading screens;
#   - src/game/game.asm: part 1 (REX 1), $6018-$FFF9;
#   - src/rex2/rex2.asm: part 2 (REX 2), $61A8-$FFF9;
#   - src/demo/demo.asm: DEMO, $61A8-$FFF9.
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
rm -rf "$here/build/res"
python3 "$here/tools/res_formats.py" build --out "$here/build/res"
a() { "$asm" --nologo --msg=war -I"$here/build" -I"$(dirname "$1")" --lst="$(basename "$1" .asm).lst" "$1"; }
for k in rex1 rex2 demo; do
    a "$here/src/tape/basic-$k.asm"
    a "$here/src/screen/screen-$k.asm"
done
a "$here/src/game/game.asm"
a "$here/src/rex2/rex2.asm"
a "$here/src/demo/demo.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/side1.txt" side1.tzx .
python3 "$here/tools/mktape.py" "$here/src/tape/side2.txt" side2.tzx .
python3 "$here/tools/mktape.py" --orig 1 orig-1.tzx
python3 "$here/tools/mktape.py" --orig 2 orig-2.tzx
cmp side1.tzx orig-1.tzx && cmp side2.tzx orig-2.tzx && \
    echo "build: side1.tzx and side2.tzx identical to orig/Rex.tzx.zip's Side 1 and Side 2"
