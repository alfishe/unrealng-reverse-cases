#!/bin/sh
# Build the tape of Deflektor from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Deflektor.tzx: the TZX orig/Deflektor.tzx.zip holds (src/tape/tape.txt, docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: TZX block 1, the BASIC line 0, its code and the loader's first stage it copies to $B626;
#   - src/loader/stage2.asm: the turbo block's first three loads, the loader's second stage at $B75A;
#   - src/res/loader: the loading screen's glyphs ($B326) and script ($998E), the turbo block's next two loads;
#   - src/head/head.asm and src/game/game.asm: the main block, which tools/cipher.py encrypts with src/head/keys.txt
#     into the bytes the tape loads at $5C00-$DDEF (the game at $6000-$DFFF, moved up by $1D00 and encrypted);
#   - tools/mktape.py: the turbo block's pulses are what the loader's own code asks for (tools/tapesim.py).
# Every .asm is written by kit/mkgame.py from its .ann; src/res by tools/res_formats.py.
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
a "$here/src/loader/stage2.asm"
a "$here/src/head/head.asm"
a "$here/src/game/game.asm"
python3 "$here/tools/cipher.py" encrypt head.bin game.bin "$here/src/head/keys.txt" main.bin
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" Deflektor.tzx .
python3 "$here/tools/mktape.py" --orig orig.tzx
cmp Deflektor.tzx orig.tzx && echo "build: Deflektor.tzx identical to orig/Deflektor.tzx.zip's Deflektor.tzx"
