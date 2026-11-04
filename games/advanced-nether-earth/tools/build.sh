#!/bin/sh
# Build the SCL from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# 1. Nether Earth's game from its own source (games/nether-earth: resources, then src/game/game.asm) into build/ne.
# 2. ANE's game image: NE's bytes with ANE's patches (src/game/ane.asm).
# 3. HRUM 3.5 (tools/hrum.py, the original streams byte for byte): the two blocks that sit inside other images first
#    (src/sfx/blocks.asm with INNER), the two images that hold them (src/images.asm), then every other block.
# 4. The loader (src/loader.asm, the intro's block inside it).
# 5. The SCL (tools/mkdisk.py, src/disk.txt). The boot BASIC with its UltraXOR envelope, the saved game nether.N
#    and the unread filler bytes are kept as the original bytes (src/res/disk/README.md says why).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
ne="$here/../nether-earth"
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
scl="$here/orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl"
b="$here/build"
rm -rf "$b/pk" "$b/blk" "$b/img"
mkdir -p "$b/ne" "$b/pk" "$b/blk" "$b/img"

# 1. NE
python3 "$ne/tools/res_formats.py" build --out "$b/ne/res"
(cd "$b/ne" && "$asm" --nologo --msg=war -I"$b/ne" -I"$ne/src/game" --lst=game.lst --sym=ne.sym \
    "$ne/src/game/game.asm")
python3 -c "import sys; g = open(sys.argv[1], 'rb').read(); o = open(sys.argv[2], 'rb').read()
assert g == o[0x5B00:0x5B00 + len(g)], 'NE game.bin is not NE original image'" "$b/ne/game.bin" "$ne/work/mkgame/original.bin"

cd "$here"
# 2. the game image (the Cyrillic font from its PNG first)
python3 tools/res_formats.py build --out "$b/res"
"$asm" --nologo --msg=war -I"$here" --lst="$b/ane-game.lst" src/game/ane.asm

# 3. the blocks
python3 tools/packall.py "$b/pk" introscreen=src/res/img/intro-screen-c000.bin d07=src/res/img/d07-9c40.bin
"$asm" --nologo --msg=war -I"$here" -DINNER --lst="$b/blocks-inner.lst" src/sfx/blocks.asm
"$asm" --nologo --msg=war -I"$here" --lst="$b/images.lst" src/images.asm
python3 tools/packall.py "$b/pk" intro=build/img/intro-6600.bin d02=src/res/img/d02-6600.bin \
    d03=src/res/img/d03-6600.bin d04=src/res/img/d04-c000-bank1.bin d05=src/res/img/d05-6060.bin \
    d06=build/img/d06-c000-bank7.bin music=src/res/img/music-c000-bank1.bin \
    deadend=src/res/img/dead-end-c000-bank3.bin diskio=src/res/img/disk-io-c000-bank4.bin \
    game=build/img/game-6731.bin finalcut=src/res/img/final-cut-6060.bin
"$asm" --nologo --msg=war -I"$here" --lst="$b/blocks.lst" src/sfx/blocks.asm

# 4. the loader
"$asm" --nologo --msg=war -I"$here" --lst="$b/loader.lst" src/loader.asm

# 5. the disk
python3 tools/mkdisk.py src/disk.txt "$b/ane.scl"
cmp "$b/ane.scl" "$scl" && echo "build: identical to orig/$(basename "$scl")"
