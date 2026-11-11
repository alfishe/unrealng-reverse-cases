#!/bin/sh
# Build both sides of Battle Command from the sources and compare them with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/BattleCommand-Side1.tzx: the 45 blocks of orig/BattleCommand.tzx.zip's "Battle Command - Side 1.tzx"
#   (src/tape/side1.txt, docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: the BASIC "BATTLE", whose tail is the decryption chain as the tape holds it: tools/speedlock.py
#     tape masters it from the plain view src/loader/chain.asm (the 103 layers and the SpeedLock loader);
#   - src/loader/stage2.asm, final-be5d.asm, final-bf21.asm: the loader's later pieces;
#   - src/game/game.asm ($5B00-$FFFF: banks 5, 2, 0 at the entry $68F4, the bootstrap at $8000), src/bank3, bank4,
#     bank6, bank7, and src/res (the loading screen);
#   tools/mktape.py enciphers every SpeedLock block with the loader's own keys, the inverse of its StoreByte.
# build/BattleCommand-Side2.tzx: the mission tape, src/tape/side2.txt from src/res/missions.
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
a "$here/src/game/game.asm"
a "$here/src/loader/chain.asm"
a "$here/src/loader/stage2.asm"
a "$here/src/loader/final-be5d.asm"
a "$here/src/loader/final-bf21.asm"
for n in 3 4 6 7; do a "$here/src/bank$n/bank$n.asm"; done
"$py" "$here/tools/speedlock.py" tape chain.bin chain-tape.bin
a "$here/src/tape/basic.asm"
"$py" "$here/tools/mktape.py" "$here/src/tape/side1.txt" BattleCommand-Side1.tzx .
"$py" "$here/tools/mktape.py" "$here/src/tape/side2.txt" BattleCommand-Side2.tzx .
mkdir -p orig
unzip -p "$here/orig/BattleCommand.tzx.zip" "Battle Command - Side 1.tzx" > orig/side1.tzx
unzip -p "$here/orig/BattleCommand.tzx.zip" "Battle Command - Side 2.tzx" > orig/side2.tzx
cmp BattleCommand-Side1.tzx orig/side1.tzx && echo "build: BattleCommand-Side1.tzx identical to orig/BattleCommand.tzx.zip's Side 1"
cmp BattleCommand-Side2.tzx orig/side2.tzx && echo "build: BattleCommand-Side2.tzx identical to orig/BattleCommand.tzx.zip's Side 2"
