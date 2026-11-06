#!/bin/sh
# Zynaps 2 in 1 from its sources: the SCL and the TRD, each compared with the original byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# 1. tools/build_sound.sh       the page-4 engine, its data, the STarKos player with SK10: build/sound/
# 2. tools/res_formats.py       the intro's three pictures: build/screens/*.scr; the game's graphics, levels, texts,
#                               effects and title tune: build/res/
# 3. sjasmplus (-Ibuild)        the parts, each to build/obj/: the game (src/game/game.asm, from game.ann by
#                               kit/mkgame.py), the hook stubs, the glue, the mouse driver (block 2 INCBINs them
#                               all), block 1 (the intro), block 2, the BASIC loader, the depacker, boot.B
# 4. tools/hrust1.py pack       block 1 (with src/intro/block1.hints) and block 2, each with the packer's tail:
#                               build/obj/block1.hr, block2.hr
# 5. tools/mkscl.py / mktrd.py  with src/media/{scl,trd}.txt: build/Zynaps(2In1)(km).scl and .trd
#
# The listings (build/lst/) are for kit/sig_add.py (signatures/sources.json).
#
# Each part is compared with the original's (tools/parts.py cuts them from the TRD into build/orig/parts/), so a
# difference is reported where it starts. One build at a time: build/.lock (a folder) is held while it runs.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=$(python3 ../../kit/toolpaths.py sjasmplus "${1:-}") || exit 1
NAME="Zynaps(2In1)(km)"

mkdir -p build
if ! mkdir build/.lock 2> /dev/null; then
    echo "build: build/.lock is held: another build is running (if none is, remove the folder build/.lock)" >&2
    exit 1
fi
trap 'rmdir build/.lock' EXIT INT TERM

fail=0
same() { # BUILT ORIGINAL
    if cmp -s "$1" "$2"; then echo "build: $1 identical"; else echo "build: $1 DIFFERS from $2"; fail=1; fi
}
asm() { # SOURCE: assembled from the case's folder with -Ibuild, no warnings allowed
    out=$("$SJASMPLUS" --nologo --msg=war --fullpath -Ibuild --lst="build/lst/$(basename "$1" .asm).lst" "$1" 2>&1) || { echo "$out"; exit 1; }
    [ -z "$out" ] || { echo "$out"; echo "build: $1: warnings"; exit 1; }
}

mkdir -p build/obj build/orig build/lst
python3 tools/parts.py --out build/orig/parts > /dev/null

# 1. the sound
if [ ! -f tools/build_sound.sh ]; then
    echo "build: tools/build_sound.sh is missing: build/sound/ cannot be made" >&2
    exit 1
fi
sh tools/build_sound.sh "$SJASMPLUS"
for f in engine-c968.bin engine-data-de48.bin starkos-8000.bin; do same build/sound/$f build/orig/parts/$f; done

# 2. the pictures and the game's resources
python3 tools/res_formats.py build --out build > /dev/null

# 3. the parts: the game first (kit/mkgame.py's game.asm saves game.bin where it runs: build/obj)
out=$(cd build/obj && "$SJASMPLUS" --nologo --msg=war -I.. -I../../src/game --lst=../lst/game.lst ../../src/game/game.asm 2>&1) || { echo "$out"; exit 1; }
[ -z "$out" ] || { echo "$out"; echo "build: src/game/game.asm: warnings"; exit 1; }
same build/obj/game.bin build/orig/parts/game-6800.bin
asm src/game/hooks.asm
asm src/game/glue128.asm
asm src/game/kmouse.asm
asm src/intro/block1.asm
asm src/game/block2.asm
asm src/loader/zynapsb.asm
asm src/loader/depacker.asm
asm src/boot/bootb.asm
asm tools/sig/depacker-end.asm  # the depacker again with a label after it: its listing for kit/sig_add.py
same build/obj/stubs-b30d.bin build/orig/parts/stubs-b30d.bin
same build/obj/glue-5b00.bin build/orig/parts/glue-5b00.bin
same build/obj/mouse-fe00.bin build/orig/parts/mouse-fe00.bin
same build/obj/block1.bin build/orig/parts/intro-6000.bin
same build/obj/block2.bin build/orig/parts/game-6000.bin
same build/obj/zynapsb-basic.bin build/orig/parts/loader-5d3b.bin
same build/obj/depacker.bin build/orig/parts/depacker-5b00.bin
same build/obj/boot-5d3b.bin build/orig/parts/boot-5d3b.bin

# 4. the packed blocks
python3 tools/hrust1.py pack build/obj/block1.bin build/obj/block1.hr --hints src/intro/block1.hints --file INTRO
python3 tools/hrust1.py pack build/obj/block2.bin build/obj/block2.hr --file BLOK
cat build/orig/parts/blk1-packed.bin build/orig/parts/blk1-trailer.bin > build/orig/parts/block1.hr
cat build/orig/parts/blk2-packed.bin build/orig/parts/blk2-trailer.bin > build/orig/parts/block2.hr
same build/obj/block1.hr build/orig/parts/block1.hr
same build/obj/block2.hr build/orig/parts/block2.hr

# 5. the media
unzip -oq "orig/$NAME.scl.zip" -d build/orig
unzip -oq "orig/$NAME.trd.zip" -d build/orig
python3 tools/mkscl.py src/media/scl.txt "build/$NAME.scl"
python3 tools/mktrd.py src/media/trd.txt "build/$NAME.trd"
same "build/$NAME.scl" "build/orig/$NAME.scl"
same "build/$NAME.trd" "build/orig/$NAME.trd"
[ $fail = 0 ] || { echo "build: FAILED"; exit 1; }
echo "build: the SCL and the TRD identical to the originals"
