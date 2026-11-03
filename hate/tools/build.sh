#!/bin/sh
# Build orig/HATE.TAP from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# The game image is assembled from src/game (written by tools/mkgame.py from src/game/game.ann and the recordings;
# docs/03-build-and-load.md, 3.7), its resources from src/res (src/res/README.md). Without src/game it is unpacked from
# the original tape.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-sjasmplus}}
mkdir -p "$here/build"
cd "$here/build"
"$asm" --nologo --msg=war "$here/src/loader.asm"
python3 "$here/tools/screen_pack.py" "$here/src/res/screens/loading.scr" loading.pk
"$asm" --nologo --msg=war -I"$here/src" "$here/src/screen.asm"
if [ -f "$here/src/game/game.asm" ]; then
    "$asm" --nologo --msg=war -I"$here/src/game" -I"$here/src" "$here/src/game/game.asm"
    image=game.bin
else
    # Until the game's source is complete: the image unpacked from the original block (the recording holds the same
    # bytes after the depacker ran, frame 2613). This proves the packer, not the game's source.
    python3 "$here/tools/tapblocks.py" "$here/orig/HATE.TAP" 5 orig-block5.bin
    python3 "$here/tools/depack.py" orig-block5.bin game.bin
    image=game.bin
    echo "build: no src/game yet, the game image is unpacked from orig/HATE.TAP" >&2
fi
python3 "$here/tools/pack.py" "$image" game.pk
"$asm" --nologo --msg=war -I"$here/src" "$here/src/depacker.asm"
# The CODE headers' second parameter is $2020 (two spaces), not the ROM's 32768: the tape was written by a copier
python3 "$here/tools/tap.py" HATE.TAP \
    basic:H_A_T_E:10:loader.bin \
    code:H_A_T_E.1:0x9C40:screen.bin:0x2020 \
    code:H_A_T_E.2:0x5FB4:game-block.bin:0x2020
cmp HATE.TAP "$here/orig/HATE.TAP" && echo "build: HATE.TAP identical to orig/HATE.TAP"
