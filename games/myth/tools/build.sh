#!/bin/sh
# Build the tape of Myth from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Myth.tzx: the 53 blocks of orig/Myth-HistoryInTheMaking.tzx.zip's "Myth - History In The Making.tzx"
#   (src/tape/tape.txt, docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: TZX block 2, the BASIC "MYTH", whose tail is the decryption chain as the tape holds it:
#     tools/speedlock.py tape masters it from the plain view src/loader/chain.asm (the 103 layers and the SpeedLock
#     loader);
#   - src/loader/sl1.asm, unxor.asm, sl1end.asm, boot.asm: the loader's later pieces;
#   - src/resident/resident.asm: the resident part $F000-$FFFF (three blocks, XORed with $DF on the tape);
#   - src/front/front.asm: the main block (logo, credits, menu); src/stage1 ... src/stage5: the five stage blocks;
#   - src/res (the loading screen, the resources of every part);
#   tools/mktape.py enciphers every SpeedLock block with the loader's own keys, the inverse of its store.
# The Python steps run under SkoolKit's interpreter ($SKOOLKIT_VENV, kit/toolpaths.py venv): tools/speedlock.py runs
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
for n in 1 2 3 4 5; do a "$here/src/stage$n/stage$n.asm"; done
a "$here/src/front/front.asm"
a "$here/src/resident/resident.asm"
for p in chain sl1 unxor sl1end boot; do a "$here/src/loader/$p.asm"; done
"$py" "$here/tools/speedlock.py" tape chain.bin chain-tape.bin
a "$here/src/tape/basic.asm"
"$py" "$here/tools/mktape.py" "$here/src/tape/tape.txt" Myth.tzx .
mkdir -p orig
unzip -p "$here/orig/Myth-HistoryInTheMaking.tzx.zip" "Myth - History In The Making.tzx" > orig/myth.tzx
cmp Myth.tzx orig/myth.tzx && echo "build: Myth.tzx identical to orig/Myth-HistoryInTheMaking.tzx.zip's Myth - History In The Making.tzx"
