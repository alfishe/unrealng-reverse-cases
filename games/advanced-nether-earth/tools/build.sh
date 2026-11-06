#!/bin/sh
# Build the SCL from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# 1-2. The game image $6731-$D7D7 (tools/build_game.sh: src/res/game, then src/game/game.asm, written by
#    kit/mkgame.py from src/game/game.ann).
# 3. HRUM 3.5 (tools/hrum.py, the original streams byte for byte): the two blocks that sit inside other images first
#    (src/sfx/blocks.asm with INNER), the two images that hold them (src/images.asm), then every other block.
# 4. The loader (src/loader.asm, the intro's block inside it).
# 5. The boot BASIC: UltraXOR's plain form (src/boot/a-nether.asm) encrypted by tools/ultraxor.py.
# 6. The SCL (tools/mkdisk.py, src/disk.txt). The saved game nether.N and the unread filler bytes are kept as the
#    original bytes (src/res/disk/README.md says why).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
scl="$here/orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl"
b="$here/build"
rm -rf "$b/pk" "$b/blk" "$b/img" "$b/boot"
mkdir -p "$b/pk" "$b/blk" "$b/img"

cd "$here"
# 1-2. the game image
sh tools/build_game.sh "$asm" >/dev/null

# 3. the blocks. The unpacked image of each block is its part's build output (tools/build_<part>.sh, build/<part>/)
sh tools/build_disk.sh "$asm" >/dev/null
sh tools/build_music.sh "$asm" >/dev/null
sh tools/build_intro.sh "$asm" >/dev/null
sh tools/build_endings.sh "$asm" >/dev/null
sh tools/build_bootmenu.sh "$asm" >/dev/null
img_introscreen=build/intro/intro-screen-c000.bin
img_d07=build/disk/d07-9c40.bin
img_d02=build/intro/d02-6600.bin
img_d03=build/intro/d03-6600.bin
img_d04=build/music/d04-c000-bank1.bin
img_d05=build/bootmenu/d05-6060.bin
img_music=build/music/music-c000-bank1.bin
img_deadend=build/endings/deadend-c000-bank3.bin
img_diskio=build/disk/disk-io-c000-bank4.bin
img_finalcut=build/endings/finalcut-6060.bin
python3 tools/packall.py "$b/pk" introscreen=$img_introscreen d07=$img_d07
"$asm" --nologo --msg=war -I"$here" -DINNER --lst="$b/blocks-inner.lst" src/sfx/blocks.asm
"$asm" --nologo --msg=war -I"$here" --lst="$b/images.lst" src/images.asm
python3 tools/packall.py "$b/pk" intro=build/img/intro-6600.bin d02=$img_d02 d03=$img_d03 d04=$img_d04 \
    d05=$img_d05 d06=build/img/d06-c000-bank7.bin music=$img_music deadend=$img_deadend diskio=$img_diskio \
    game=build/game/game-6731.bin finalcut=$img_finalcut
"$asm" --nologo --msg=war -I"$here" --lst="$b/blocks.lst" src/sfx/blocks.asm

# 4. the loader
"$asm" --nologo --msg=war -I"$here" --lst="$b/loader.lst" src/loader.asm

# 5. the boot BASIC: UltraXOR's plain form (src/boot/a-nether.asm), encrypted by tools/ultraxor.py
mkdir -p "$b/boot"
"$asm" --nologo --msg=war -I"$here" --lst="$b/boot.lst" src/boot/a-nether.asm
python3 tools/ultraxor.py encrypt "$b/boot/a-nether-plain.bin" "$b/boot/a-nether-b.bin"

# 6. the disk
python3 tools/mkdisk.py src/disk.txt "$b/ane.scl"
cmp "$b/ane.scl" "$scl" && echo "build: identical to orig/$(basename "$scl")"
