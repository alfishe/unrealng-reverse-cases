#!/bin/sh
# Build the tape of SimCity from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/SimCity.tap: the seven data blocks of orig/SimCity.tzx.zip ("Sim City.tzx" blocks 1-7) as TAP:
#   block 1, the header "Simcity" (kit/tap.py: LINE 0, the program length 144 found by walking the lines);
#   block 2, the BASIC program $5CCB-$5D5A from src/tape/basic.asm (kit/mkgame.py from src/tape/basic.ann);
#   block 3, the header "loader" of a CODE file, 512 bytes at 65024, parameter 2 32912;
#   block 4, the loader $FE00-$FFFF from src/loader/loader.asm, its tail $FE80-$FFFF XORed with the R register's
#     keys by tools/tape.py loader (the inverse of LoaderStart's decryption);
#   blocks 5-7, headerless, flag $00, each byte XORed with the key and the count by tools/tape.py blocks (the
#     inverse of LoadBlock's store): the loading screen from src/screen/screen.asm (src/res/screen), code1
#     $6B00-$FE00 and code2 $5B00-$6AFF from src/game/game.asm (src/game/game.ann and src/res), code2 followed by
#     the mover $5000-$501F from src/mover/mover.asm.
# Every block carries its flag and XOR checksum. build/orig.tap is the original's seven blocks (tools/tape.py
# --orig); the two files must be identical. The TZX's archive info, timings and pauses are not data.
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
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/game" --lst=game.lst "$here/src/game/game.asm"
"$asm" --nologo --msg=war -I"$here/src/tape" --lst=basic.lst "$here/src/tape/basic.asm"
"$asm" --nologo --msg=war -I"$here/src/loader" --lst=loader.lst "$here/src/loader/loader.asm"
"$asm" --nologo --msg=war -I"$here/build" -I"$here/src/screen" --lst=screen.lst "$here/src/screen/screen.asm"
"$asm" --nologo --msg=war -I"$here/src/mover" --lst=mover.lst "$here/src/mover/mover.asm"
python3 "$here/tools/tape.py" loader loader.bin loader-tape.bin
python3 "$here/../../kit/tap.py" SimCity.tap basic:Simcity:0:basic.bin code:loader:65024:loader-tape.bin:32912
python3 "$here/tools/tape.py" blocks SimCity.tap screen.bin game.bin mover.bin
python3 "$here/tools/tape.py" --orig orig.tap
cmp SimCity.tap orig.tap && echo "build: identical to the original's blocks 1-7 (build/orig.tap)"
