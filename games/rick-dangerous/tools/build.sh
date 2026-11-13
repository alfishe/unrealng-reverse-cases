#!/bin/sh
# Build the tape of Rick Dangerous from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Rick Dangerous.tzx: the whole TZX of orig/RickDangerous.tzx.zip, every block, timing and pause
# (src/tape/tape.txt lists them; tools/mktape.py writes them):
#   TZX block 2, the BASIC "Rick", from src/tape/basic.asm;
#   TZX block 4, Rick1 ($CD00), from src/loader/rick1.asm;
#   group 1 (48 turbo blocks): the key page and the decoy last block (src/res/loader), the loading screen
#     (src/res/screens), the second stage (src/loader/stage2.asm), the game's $5E00-$6DFF (game.bin) and LoadGroup
#     (src/loader/loadgroup.asm), enciphered by the key made from the key page and the built Rick1;
#   groups 2 and 3 (146 turbo blocks): the game's $6E00-$FFFF (game.bin), each byte XOR its page.
# The game (src/game/game.asm, $5B00-$FFFF) INCBINs the built stage2.bin and music.bin (src/music/music.asm, the AY
# player the entry copies to RAM 1), so they are assembled first. build/orig.tzx is the original (tools/mktape.py
# --orig); the two files must be identical.
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
"$asm" --nologo --msg=war -I"$here/src/tape" --lst=basic.lst "$here/src/tape/basic.asm"
for part in rick1 stage2 loadgroup; do
    "$asm" --nologo --msg=war -I"$here/src/loader" --lst=$part.lst "$here/src/loader/$part.asm"
done
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/music" --lst=music.lst "$here/src/music/music.asm"
# the game INCBINs the built second stage and AY player (case.json "built"; never kept in src/res)
mkdir -p res/loader res/music
cp stage2.bin res/loader/stage2.bin
cp music.bin res/music/music.bin
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" "Rick Dangerous.tzx" "$here/build"
python3 "$here/tools/mktape.py" --orig orig.tzx
cmp "Rick Dangerous.tzx" orig.tzx && echo "build: identical to orig/RickDangerous.tzx.zip's \"Rick Dangerous.tzx\" (build/orig.tzx)"
