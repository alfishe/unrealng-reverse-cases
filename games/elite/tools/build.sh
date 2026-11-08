#!/bin/sh
# Build Side A of Elite from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Elite-SideA.tzx: the 38 blocks of orig/Elite.tzx.zip's "Elite - 48k - Side A.tzx" (docs/03-build-and-load.md
#   3.1, 3.10), from src/tape/basic.asm (the BASIC and the stub, its tail encrypted by tools/mktape.py),
#   src/tape/softlock.asm (the chunk reader, its patches, the decryptor, the plain loader in the filler chunks),
#   src/game/game.asm ($5B00-$FFA7, written by kit/mkgame.py from src/game/game.ann), src/lenslok/lenslok.asm
#   ($C000-$C7FF before the kickoff, from src/lenslok/lenslok.ann) and src/res; src/tape/elite-tzx.txt lists the
#   blocks. tools/mktape.py encrypts the game with the loading screen and the 48K ROM (unreal-ng's data/rom/48.rom).
#
# build/Elite-SideB.tzx: Side B ("With Adder ship") the same way, in build/sideb: src/sideb/sideb.asm lays Side B's
#   blueprints (src/sideb/ships-b.txt), slot 0's word and the mastering sysvars over Side A's game.bin, and
#   src/sideb/elite-tzx-b.txt lists the blocks (tools/sideb.py, docs/03-build-and-load.md 3.12).
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
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/lenslok" --lst=lenslok.lst "$here/src/lenslok/lenslok.asm"
"$asm" --nologo --msg=war --lst=basic.lst "$here/src/tape/basic.asm"
"$asm" --nologo --msg=war --lst=softlock.lst "$here/src/tape/softlock.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/elite-tzx.txt" Elite-SideA.tzx .
unzip -p "$here/orig/Elite.tzx.zip" "Elite - 48k - Side A.tzx" > orig-SideA.tzx
cmp Elite-SideA.tzx orig-SideA.tzx && echo "build: Elite-SideA.tzx identical to orig/Elite.tzx.zip's Side A"
mkdir -p sideb
for f in basic-plain.bin reader-page.bin patch-up.bin patch-key.bin patch-down.bin decrypt.bin lenslok.bin; do
    cp "$f" sideb/
done
rm -rf sideb/res && cp -R res sideb/res
python3 "$here/tools/sideb.py" res "$here/build/sideb"
(cd sideb && "$asm" --nologo --msg=war -I"$here/build" --lst=sideb.lst "$here/src/sideb/sideb.asm")
python3 "$here/tools/mktape.py" "$here/src/sideb/elite-tzx-b.txt" Elite-SideB.tzx sideb
unzip -p "$here/orig/Elite.tzx.zip" "Elite - 48k - Side B.tzx" > orig-SideB.tzx
cmp Elite-SideB.tzx orig-SideB.tzx && echo "build: Elite-SideB.tzx identical to orig/Elite.tzx.zip's Side B"
