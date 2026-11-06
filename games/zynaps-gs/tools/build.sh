#!/bin/sh
# Zynaps GS from its sources: the TRD, compared with the one in orig/ZYNAP_GS.ZIP byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# 1. tools/res_formats.py build and tools/disk_media.py build: the game's resources (graphics, levels, texts) and the
#    disk's media (the modules, the effects, the loading screen) to build/res/
# 2. sjasmplus: the game (src/game/game.asm, in build/: build/game.bin, $5C00-$FFFF); then from the case's folder the
#    BASIC, the boot, the screen block, the loader, the menu, the driver file (which holds the loader and the menu),
#    the installer and block 4 (installer + driver file + the game) to build/disk/
# 3. tools/mkdisk.py with src/media/trd.txt: the Trush blocks and the TRD, build/ZYNAP_GS.TRD
#
# One build at a time: build/.lock (a folder) is held while it runs.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=$(python3 ../../kit/toolpaths.py sjasmplus "${1:-}") || exit 1
export SJASMPLUS
mkdir -p build/disk
if ! mkdir build/.lock 2> /dev/null; then
    echo "build: build/.lock is held: another build is running (if none is, remove the folder build/.lock)" >&2
    exit 1
fi
trap 'rmdir build/.lock' EXIT INT TERM

python3 tools/res_formats.py build --out build/res
python3 tools/disk_media.py build --out build/res
(cd build && "$SJASMPLUS" --nologo --msg=war -I. -I../src/game --lst=game.lst ../src/game/game.asm)
for src in src/disk/basic.asm src/disk/boot/boot-sectors.asm src/disk/screen/screen-block.asm \
           src/disk/loader/loader-copy.asm src/disk/menu/menu-copy.asm src/disk/driver/driver-file.asm \
           src/disk/install.asm src/disk/block4.asm; do
    "$SJASMPLUS" --nologo --msg=war -I. -Ibuild -I"$(dirname $src)" "$src"
done
python3 tools/mkdisk.py src/media/trd.txt build/ZYNAP_GS.TRD

mkdir -p build/orig
unzip -oq orig/ZYNAP_GS.ZIP -d build/orig
if cmp -s build/ZYNAP_GS.TRD build/orig/ZYNAP_GS.TRD; then
    echo "build: identical to orig/ZYNAP_GS.ZIP's ZYNAP_GS.TRD"
else
    echo "build: build/ZYNAP_GS.TRD DIFFERS from orig/ZYNAP_GS.ZIP's ZYNAP_GS.TRD"
    cmp build/ZYNAP_GS.TRD build/orig/ZYNAP_GS.TRD | head -1
    exit 1
fi
