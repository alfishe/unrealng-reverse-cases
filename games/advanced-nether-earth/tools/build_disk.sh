#!/bin/sh
# The disk part (aneD) from its sources into build/disk, each image compared byte for byte with the raw file it
# replaces (while that file is still in src/res/img).
#
#   tools/build_disk.sh [SJASMPLUS]
#
#   build/disk/disk-io-c000-bank4.bin  bank 4 $C000-$CD2B: the disk module's set-up and the module run at $4000
#                                      (src/disk/diskio.asm)                  = src/res/img/disk-io-c000-bank4.bin
#   build/disk/d07-9c40.bin            the game starter and its title picture, $9C40-$B78F (src/disk/starter.asm)
#                                                                             = src/res/img/d07-9c40.bin
#   build/disk/d06-c000-bank7.bin      bank 7 $C000-$FFFF: $C000-$CE08 zero (the slot of HRUM block d07, the
#                                      starter), the boot menu's sample at $CE09 (src/disk/bank7.asm)
#                                                                             = src/res/img/d06-c000-bank7.bin
#
# The sources are written by kit/mkgame.py --part src/disk/*.json from src/disk/*.ann; the resources go first through
# tools/disk_res.py into build/disk/res, which the modules INCBIN as "res/diskmod/<file>": the module's font
# (font.png), the title picture (title.png), the sample (sample.wav), all in src/res/diskmod.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
b="$here/build/disk"
rm -rf "$b"
mkdir -p "$b/res"
python3 "$here/tools/disk_res.py" build --out "$b/res"
for part in diskio:disk-io-c000-bank4 starter:d07-9c40 bank7:d06-c000-bank7; do
    src=${part%%:*}
    bin=${part#*:}.bin
    (cd "$b" && "$asm" --nologo --msg=war -I"$here/src/disk" --lst="$b/$src.lst" "$here/src/disk/$src.asm")
    raw="$here/src/res/img/$bin"
    if [ -f "$raw" ]; then
        cmp "$b/$bin" "$raw" >/dev/null || { echo "build_disk: $b/$bin differs from $raw" >&2; exit 1; }
        echo "build_disk: $bin identical to src/res/img/$bin"
    fi
done
