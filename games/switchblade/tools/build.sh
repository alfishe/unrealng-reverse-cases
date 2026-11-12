#!/bin/sh
# Build the tape of Switchblade from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Switchblade.tzx: the TZX orig/Switchblade.tzx.zip holds ("Switch Blade.tzx"; src/tape/tape.txt,
# docs/03-build-and-load.md 3.1), from
#   - src/tape/basic.asm: TZX block 2, the BASIC line 0, its code and the tape loader it copies to $FF00;
#   - src/stage2/stage2.asm: block 3, the loader's second stage at $609C;
#   - src/game/game.asm: the game as it runs, $5C00-$FFFF: block 4 is its $6B5C-$FDFC, block 5 ends with its
#     $5C00-$6B4C and $FF01-$FFFE (the bootstrap's two copies);
#   - src/boot/boot.asm: block 5's first $146 bytes, the bootstrap at $4000 and the AY glue it copies to $853F;
#   - src/bank4/bank4.asm: block 6, bank 4 (128K only): the AY player, the tunes, the story pages.
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
a "$here/src/stage2/stage2.asm"
a "$here/src/game/game.asm"
a "$here/src/boot/boot.asm"
a "$here/src/bank4/bank4.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" Switchblade.tzx .
python3 "$here/tools/mktape.py" --orig orig.tzx
cmp Switchblade.tzx orig.tzx && echo "build: Switchblade.tzx identical to orig/Switchblade.tzx.zip's Switch Blade.tzx"
