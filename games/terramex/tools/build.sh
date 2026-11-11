#!/bin/sh
# Build the tape of Terramex from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Terramex.tzx: the TZX orig/Terramex.tzx.zip holds (src/tape/tape.txt, docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: TZX block 2, the BASIC line 0 with the loader in its variables area;
#   - src/screen/screen.asm: block 3, the loading screen (src/res/screens);
#   - src/music/music.asm, src/select/select.asm, src/explorers/explorers.asm: block 4, the AY music player (run in
#     RAM 6 at $C000), the 128K setup and the explorer selector (run in RAM 1 at $C000; tools/mktape.py undoes its
#     relocation for the tape) and the five explorer data sets;
#   - src/game/game.asm: block 5, the game $7200-$FFFF.
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
a "$here/src/tape/basic.asm"
a "$here/src/screen/screen.asm"
a "$here/src/music/music.asm"
a "$here/src/select/select.asm"
a "$here/src/explorers/explorers.asm"
a "$here/src/game/game.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" Terramex.tzx .
python3 "$here/tools/mktape.py" --orig orig.tzx
cmp Terramex.tzx orig.tzx && echo "build: Terramex.tzx identical to orig/Terramex.tzx.zip's Terramex.tzx"
