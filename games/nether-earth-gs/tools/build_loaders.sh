#!/bin/sh
# The loaders, drivers, BASICs and loader resources of Nether Earth GS, each checked against the original bytes.
#
#   tools/build_loaders.sh [SJASMPLUS]
#
# Writes build/res/ (tools/res_media.py: the module, the effects, the loading screen, the texts), build/disk/
# {basic,loader,driver}.bin (the TR-DOS "neart GS", neart022, neart021) and build/tape/{basic,loader,driver}.bin
# (Hood's BASIC, neart0222, the tape neart021). The originals: the SCL inside orig/NE_GS_TZ.zip (unzipped to
# build/orig/) and the TAP in orig/, cut by tools/disk_files.py and kit/tapblocks.py into build/orig/{scl,tap}/.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
TAP="orig/Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2017 Hood, Tron Z].tap"
KIT=../../kit

mkdir -p build/res build/disk build/tape build/orig/scl build/orig/tap
python3 tools/res_media.py build --out build/res
for src in src/disk/basic src/disk/loader src/disk/driver src/tape/basic src/tape/loader src/tape/driver; do
    out=$("$SJASMPLUS" --nologo --msg=war --fullpath -Ibuild "$src.asm" 2>&1) || { echo "$out"; exit 1; }
    [ -z "$out" ] || { echo "$out"; echo "build_loaders: $src.asm: warnings"; exit 1; }
done

unzip -oq orig/NE_GS_TZ.zip -d build/orig
python3 tools/disk_files.py build/orig/NE_GS_TZ.SCL --out build/orig/scl > /dev/null
# tape blocks: 1 Hood's BASIC, 3 neart0222, 47 the tape neart021
python3 "$KIT/tapblocks.py" "$TAP" 1 build/orig/tap/basic.bin > /dev/null
python3 "$KIT/tapblocks.py" "$TAP" 3 build/orig/tap/loader.bin > /dev/null
python3 "$KIT/tapblocks.py" "$TAP" 47 build/orig/tap/driver.bin > /dev/null

fail=0
check() { # BUILT ORIGINAL [COUNT]: the built bytes equal the original's first COUNT bytes (default: all of both)
    if [ $# -gt 2 ]; then
        python3 -c 'import sys; a=open(sys.argv[1],"rb").read(); b=open(sys.argv[2],"rb").read()[:int(sys.argv[3])]
sys.exit(a!=b)' "$1" "$2" "$3" && r=0 || r=1
    else
        cmp -s "$1" "$2" && r=0 || r=1
    fi
    if [ $r = 0 ]; then echo "build_loaders: $1 identical"; else echo "build_loaders: $1 DIFFERS from $2"; fail=1; fi
}
O=build/orig/scl
for n in 002 003 004 005 006; do check build/res/music/neart$n.bin $O/neart$n.C; done
for n in 007 008 009 010 011 012 013 014 015 016 017 018 019 020 023; do check build/res/sfx/neart$n.bin $O/neart$n.C; done
check build/res/screen/neart000.bin $O/neart000.C
# "neart GS": the 67-byte program + $80 $AA + line 10, the first 71 bytes of its sector
check build/disk/basic.bin "$O/neart GS.B.sec" 71
check build/disk/loader.bin $O/neart022.C
check build/disk/driver.bin $O/neart021.C
check build/tape/basic.bin build/orig/tap/basic.bin
check build/tape/loader.bin build/orig/tap/loader.bin
check build/tape/driver.bin build/orig/tap/driver.bin
[ $fail = 0 ] || { echo "build_loaders: FAILED"; exit 1; }
