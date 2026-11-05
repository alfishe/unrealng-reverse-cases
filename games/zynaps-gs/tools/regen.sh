#!/bin/sh
# Write the .asm sources again from their annotations, then build and compare (tools/build.sh).
#
#   tools/regen.sh
#
# The game: kit/mkgame.py from src/game/game.ann (case.json: the image from tools/game_image.py, the recordings
# work/z48c2 and work/z48r1). The disk parts: tools/part_mkasm.py from src/disk/*.ann over the original's bytes
# (work/stage2/*.bin, cut from the TRD in stage 1; Trush block 0 from work/media/unpacked) with the recording
# work/stage2/r1. Every part is assembled and compared with its image before it is installed.
set -eu
cd "$(dirname "$0")/.."
VENV=${VENV:-/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit}
SJASMPLUS=${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}
export SJASMPLUS
L1=work/stage2/r1/l1.json
part() {  # IMAGE ORG PAGE ANN TOP DEST TITLE [ARGS...]
    image=$1 org=$2 page=$3 ann=$4 top=$5 dest=$6 title=$7
    shift 7
    python3 tools/part_mkasm.py --image "$image" --org "$org" --page "$page" --ann "$ann" --top "$top" \
        --dest "$dest" --res src/res --l1 "$L1" --title "$title" --venv "$VENV" --sjasmplus "$SJASMPLUS" \
        --install "$@"
}
sh tools/build.sh "$SJASMPLUS"   # build/res and build/disk for the parts that INCBIN them
part work/stage2/boot.bin 0x5d3b 5 src/disk/boot.ann boot-sectors src/disk/boot \
    'The boot code (disk sectors 1:1-1:2, run at $5D3B)' --save build/disk/boot.bin
part work/media/unpacked/blk00-s0003-7F58.bin 0x7f58 5 src/disk/screen.ann screen-block src/disk/screen \
    "Trush block 0's contents: the loading screen (\$7F58-\$9AFF)" \
    --built screen/loading.scr=build/res/screen/loading.scr --save build/disk/screen.bin
part work/stage2/loader.bin 0x61a8 5 src/disk/loader.ann loader-copy src/disk/loader \
    'The level loader (bank 1 $C44A, run at $61A8)' --save build/disk/loader.bin
part work/stage2/menu.bin 0x6d60 5 src/disk/menu.ann menu-copy src/disk/menu \
    'The options menu (driver file $C8AD, run at $6D60)' --save build/disk/menu.bin
part work/stage2/driverfile.bin 0xc000 1 src/disk/driver.ann driver-file src/disk/driver \
    'The GS driver file (bank 1 $C000-$CF4C)' --built disk/loader.bin=build/disk/loader.bin \
    --built disk/menu.bin=build/disk/menu.bin --save build/disk/driver.bin
python3 ../../kit/mkgame.py --case . --venv "$VENV" --sjasmplus "$SJASMPLUS" --install
sh tools/build.sh "$SJASMPLUS"
