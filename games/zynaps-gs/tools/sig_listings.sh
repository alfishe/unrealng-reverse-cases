#!/bin/sh
# Listings for the signatures of the disk parts (R/signatures/sources.json, games/zynaps-gs items), in build/lst/:
#   build/lst/trush-block4.lst   src/disk/trush.asm (+ the label DepackEnd) with block 4's defines (base $607C, the output $61A8-$FFFF)
#   build/lst/driver-file.lst    src/disk/driver/driver-file.asm (the GS driver, bank 1 $C000)
#   build/lst/install.lst        src/disk/install.asm (the patch installer, $61A8)
# Run after tools/build.sh (it needs build/disk/*.bin and build/trush/blk04/stream.bin). The binaries the parts write
# are the build's own (the same bytes); the Trush block is assembled in work/sig-lst/.
#
#   tools/sig_listings.sh [SJASMPLUS]
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=$(python3 ../../kit/toolpaths.py sjasmplus "${1:-}") || exit 1
mkdir -p build/lst work/sig-lst
len=$((0x10000 - 0x61A8))
cp build/trush/blk04/stream.bin work/sig-lst/stream.bin
# the depacker runs displaced (DISP TRUSH_BASE .. ENT); DepackerEnd is past the ENT, at its load address, so a copy
# of trush.asm gets the label DepackEnd at the ENT, inside the displaced part (the bytes stay the same: cmp below)
sed 's/^  ENT$/DepackEnd:\
  ENT/' src/disk/trush.asm > work/sig-lst/trush.asm
(cd work/sig-lst && "$SJASMPLUS" --nologo --msg=war -DTRUSH_BASE=$((0x61A8 - 0x12C)) -DTRUSH_DEST_END=$((0xFFFF)) \
    -DTRUSH_LEN=$len --lst=../../build/lst/trush-block4.lst trush.asm)
cmp work/sig-lst/block.bin build/trush/blk04/block.bin
"$SJASMPLUS" --nologo --msg=war -I. -Ibuild -Isrc/disk/driver --lst=build/lst/driver-file.lst src/disk/driver/driver-file.asm
"$SJASMPLUS" --nologo --msg=war -I. -Ibuild -Isrc/disk --lst=build/lst/install.lst src/disk/install.asm
echo "sig_listings: build/lst/trush-block4.lst driver-file.lst install.lst"
