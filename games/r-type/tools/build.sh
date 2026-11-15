#!/bin/sh
# Build the tape of R-Type from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/R-Type.tzx: every block of orig/R-Type.tzx.zip's R-Type.tzx (src/tape/tape.txt), from
#   - src/tape/basic.asm: the BASIC "R-TYPE", whose tail is the decryption chain as the tape holds it:
#     tools/speedlock7.py tape masters it from the plain view src/loader/chain.asm (the 119 rewrite loops and the
#     SpeedLock 7 reader);
#   - src/loader/stage2.asm, table2.asm, decipher.asm, stage2end.asm, tail.asm: the loader's later pieces;
#   - src/game/game.asm: $7000-$FFFF at the entry $85FD; the tape's code blocks are its slices, $7000-$C4AD XORed
#     with $92 (Decipher $FE40 undoes it);
#   - src/level1 ... src/level8: the eight level bodies, each loaded to $C4AE;
#   - src/res (the loading screen, the resources of every part);
#   tools/mktape.py enciphers every SpeedLock block with the reader's own keys, the inverse of its store.
# The Python steps run under SkoolKit's interpreter ($SKOOLKIT_VENV, kit/toolpaths.py venv): tools/speedlock7.py runs
# the chain in its simulator.
#
# One build at a time: a second one waits for build/.lock (a directory) to go away.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1  # $SJASMPLUS, PATH or a checkout
venv=$(python3 "$here/../../kit/toolpaths.py" venv "") || exit 1
py="$venv/bin/python"
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
for n in 1 2 3 4 5 6 7 8; do a "$here/src/level$n/level$n.asm"; done
a "$here/src/game/game.asm"
for p in chain stage2 table2 decipher stage2end tail; do a "$here/src/loader/$p.asm"; done
"$py" "$here/tools/speedlock7.py" tape chain.bin chain-tape.bin
a "$here/src/tape/basic.asm"
"$py" "$here/tools/mktape.py" "$here/src/tape/tape.txt" R-Type.tzx .
mkdir -p orig
unzip -p "$here/orig/R-Type.tzx.zip" R-Type.tzx > orig/r-type.tzx
cmp R-Type.tzx orig/r-type.tzx && echo "build: R-Type.tzx identical to orig/R-Type.tzx.zip's R-Type.tzx"
