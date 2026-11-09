#!/bin/sh
# Build the tape from the sources and compare it with the original's data blocks, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/VideoPool.tap: the five data blocks of `Video Pool.tzx` in orig/VideoPool.tzx.zip (docs/03-build-and-load.md 3.1):
#   blocks 1+2: the header "VIDEO POOL" LINE 10 and the BASIC, src/tape/basic.asm;
#   blocks 3+4: the header "VIDEO POOL" 61440 (p2 32812) and the turbo loader $F000-$F0FF, src/turbo/turbo.asm
#   (written by kit/mkgame.py --part src/turbo/turbo.json from src/turbo/turbo.ann);
#   block 5: the turbo block, flag $FF, the game $8000-$E1A7, the XOR checksum: src/game/game.asm (written by
#   kit/mkgame.py from src/game/game.ann) with the resources src/res (tools/res_formats.py build).
# kit/tap.py writes the blocks; tools/origtap.py writes the original's blocks 1-5 the same way for the cmp. The TZX's
# timings (block 5's turbo pulses) and pauses are not rebuilt.
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
# The game: $8000-$E1A7, block 5 (25000 bytes)
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
# The turbo loader: $F000-$F0FF, block 4 (256 bytes)
"$asm" --nologo --msg=war -I"$here/src/turbo" --lst=turbo.lst "$here/src/turbo/turbo.asm"
# The BASIC loader, block 2 (44 bytes)
"$asm" --nologo --msg=war --lst=basic.lst "$here/src/tape/basic.asm"
python3 "$here/../../kit/tap.py" VideoPool.tap "basic:VIDEO POOL:10:loader.bin" "code:VIDEO POOL:61440:turbo.bin:32812" \
    data:-:-:game.bin
python3 "$here/tools/origtap.py" orig-VideoPool.tap
cmp VideoPool.tap orig-VideoPool.tap && echo "build: VideoPool.tap identical to the data blocks 1-5 of orig/VideoPool.tzx.zip's Video Pool.tzx"
