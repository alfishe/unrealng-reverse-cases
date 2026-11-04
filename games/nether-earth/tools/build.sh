#!/bin/sh
# Build the tape from the sources and compare it with orig/NETHER.TAP, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# The five blocks (docs/03-build-and-load.md): the BASIC (src/basic.asm), N1's header and N1 (src/loader.asm), the
# headerless game block $4000-$FCE8 ($5B00-$FCE8 from src/game/game.asm, written by kit/mkgame.py from
# src/game/game.ann and the recordings). orig/NETHER.TZX holds the same five blocks as standard-speed TZX blocks.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-sjasmplus}}
mkdir -p "$here/build"
cd "$here/build"
if [ -f "$here/tools/res_formats.py" ]; then
    python3 "$here/tools/res_formats.py" build --out "$here/build/res"
fi
"$asm" --nologo --msg=war --lst=basic.lst "$here/src/basic.asm"
"$asm" --nologo --msg=war --lst=loader.lst "$here/src/loader.asm"
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
# N1's header names an address the BASIC does not use: $F938 (63800); LOAD "" CODE 64730 puts it at $FCDA
# The block's first 6912 bytes, $4000-$5AFF, are a copy of the game's own $C350-$DE4F (the attributes zero: black on
# black while it loads); the start-up clears them before anything reads them (WALKTHROUGH 2)
python3 -c "g = open('game.bin', 'rb').read(); c = 0xC350 - 0x5B00
open('block.bin', 'wb').write(g[c:c + 0x1B00] + g)"
python3 "$here/../../kit/tap.py" NETHER.TAP basic:N.EARTH:0:basic.bin code:N1:63800:loader.bin data:-:-:block.bin
cmp NETHER.TAP "$here/orig/NETHER.TAP" && echo "build: identical to orig/NETHER.TAP"
