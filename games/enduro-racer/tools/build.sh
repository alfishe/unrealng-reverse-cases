#!/bin/sh
# Build the tape of Enduro Racer from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/Enduro Racer.tzx: every block of orig/EnduroRacer.tzx.zip's "Enduro Racer.tzx" (src/tape/tape.txt), from
#   - src/tape/basic1.asm: the BASIC "enduro" and Stage0;
#   - src/loader/loader.asm: the loader's plain view $FCA3-$FFBF (Chain2, Chain3, the SpeedLock 2 loader), which
#     tools/speedlock2.py tape enciphers into loader-tape.bin;
#   - src/tape/basic2.asm: the BASIC "end2", Chain1 and LoaderTape (INCBIN loader-tape.bin);
#   - src/loader/tail.asm: $FF63-$FF86 as blocks 12 and 14 load it;
#   - src/game/game.asm: $5B00-$FFFF at the entry $8000; the tape's game blocks are its slices before Mover's
#     LDDR (tape.txt names them by their place in the image);
#   - src/res (the loading screen, the game's resources);
#   tools/mktape.py stores every SpeedLock block with the loader's own keys, the inverse of its store.
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
a "$here/src/game/game.asm"
a "$here/src/tape/basic1.asm"
a "$here/src/loader/loader.asm"
a "$here/src/loader/tail.asm"
python3 "$here/tools/speedlock2.py" tape loader.bin loader-tape.bin
a "$here/src/tape/basic2.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" "Enduro Racer.tzx" .
mkdir -p orig
unzip -p "$here/orig/EnduroRacer.tzx.zip" "Enduro Racer.tzx" > orig/enduro-racer.tzx
cmp "Enduro Racer.tzx" orig/enduro-racer.tzx && echo "build: Enduro Racer.tzx identical to orig/EnduroRacer.tzx.zip's Enduro Racer.tzx"
