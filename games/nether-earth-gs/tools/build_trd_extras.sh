#!/bin/sh
# The TRD's extra files (boot, Neart481, Neart482: on the TRD only, not on the SCL), each built whole, all its
# sectors, and checked byte for byte against the TRD in orig/.
#
#   tools/build_trd_extras.sh [SJASMPLUS]
#
# Writes build/trd/ only: boot.bin (13 sectors), Neart481.bin (171), Neart482.bin (112); build/trd/text/ the texts
# converted from src/res/text/trd-*.txt (tools/trd_text.py), build/trd/obj/ the intermediate images and streams:
#
#   boot      src/trd/boot/boot-menu.asm + boot-print64.asm -> menu.bin (4100 bytes) -> tools/hrum.py pack
#             (--prefer 2348:264) -> menu.hrum, taken by src/trd/boot/boot.asm
#   Neart482  src/res/trd/neart482/inner-61a8.bin -> tools/trd_lz.py pack --raw 2 -> n482-inner.lz, taken by
#             src/trd/neart482/intro.asm -> n482-outer.bin -> tools/trd_lz.py pack --raw 9 -> n482-outer.lz, taken
#             by src/trd/neart482/neart482.asm
#   Neart481  src/trd/neart481/neart481.asm (its blocks are resources)
#
# A lock (build/.lock-trd) keeps two runs apart. Prints "trd extras: identical" when all three match.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
TRD="orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2002 Tron Z].trd"

mkdir -p build
LOCK=build/.lock-trd
n=0
until mkdir "$LOCK" 2>/dev/null; do
    n=$((n + 1))
    [ $n -lt 600 ] || { echo "build_trd_extras: $LOCK held for 10 minutes: another run, or a stale lock to remove"; exit 1; }
    sleep 1
done
trap 'rmdir "$LOCK"' EXIT INT TERM

mkdir -p build/trd/obj build/trd/text
asm() { # SOURCE: assembled with -Ibuild, no warnings allowed
    out=$("$SJASMPLUS" --nologo --msg=war --fullpath -Ibuild "$1" 2>&1) || { echo "$out"; exit 1; }
    [ -z "$out" ] || { echo "$out"; echo "build_trd_extras: $1: warnings"; exit 1; }
}

for t in src/res/text/trd-*.txt; do
    python3 tools/trd_text.py encode "$t" "build/trd/text/$(basename "$t" .txt).bin"
done

# boot
asm src/trd/boot/boot-menu.asm
asm src/trd/boot/boot-print64.asm
cat build/trd/obj/boot-menu.bin build/trd/obj/boot-print64.bin > build/trd/obj/menu.bin
python3 tools/hrum.py pack build/trd/obj/menu.bin build/trd/obj/menu.hrum --prefer 2348:264 > /dev/null
asm src/trd/boot/boot.asm

# Neart482
python3 tools/trd_lz.py pack src/res/trd/neart482/inner-61a8.bin build/trd/obj/n482-inner.lz --raw 2 > /dev/null
asm src/trd/neart482/intro.asm
python3 tools/trd_lz.py pack build/trd/obj/n482-outer.bin build/trd/obj/n482-outer.lz --raw 9 > /dev/null
asm src/trd/neart482/neart482.asm

# Neart481
asm src/trd/neart481/neart481.asm

fail=0
check() { # BUILT TRACK SECTOR COUNT: the built file equals COUNT sectors of the TRD from TRACK:SECTOR
    if python3 -c 'import sys
t = open(sys.argv[1], "rb").read()
o = (int(sys.argv[3]) * 16 + int(sys.argv[4])) * 256
b = open(sys.argv[2], "rb").read()
sys.exit(b != t[o:o + int(sys.argv[5]) * 256])' "$TRD" "$1" "$2" "$3" "$4"; then
        echo "build_trd_extras: $1 identical ($4 sectors from $2:$3)"
    else
        echo "build_trd_extras: $1 DIFFERS from the TRD's $4 sectors at $2:$3"; fail=1
    fi
}
check build/trd/boot.bin 1 0 13
check build/trd/Neart481.bin 103 10 171
check build/trd/Neart482.bin 114 5 112
[ $fail = 0 ] || { echo "trd extras: FAILED"; exit 1; }
echo "trd extras: identical"
