#!/bin/sh
# Nether Earth GS from its sources: the three media, each compared with the original.
#
#   tools/build.sh [SJASMPLUS]
#
# 1. tools/build_game.sh       the game image: build/game/neart001-scl.bin (disk), neart001-tap.bin (tape)
# 2. tools/build_loaders.sh    loaders, drivers, BASICs, the module, the effects, the screen, the texts
# 3. tools/build_trd_extras.sh the TRD's own files: build/trd/boot.bin, Neart481.bin, Neart482.bin (full sectors)
# 4. tools/mkscl.py / mktrd.py / mktap.py with src/media/{scl,trd,tap}.txt:
#    build/NE_GS_TZ.SCL, build/<the TRD's name>.trd, build/<the TAP's name>.tap
#
# A step whose script is missing is skipped with a warning (its files must then already be in build/). One build at a
# time: build/.lock (a folder) is held while it runs.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
TRD="Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2002 Tron Z].trd"
TAP="Nether Earth (1987)(Argus Press Software Ltd)(EN)(GS)[h 2017 Hood, Tron Z].tap"
# the media take the game and the TRD extras from build/ only
GAME_DIR=build/game
TRD_DIR=build/trd
export GAME_DIR TRD_DIR

mkdir -p build
if ! mkdir build/.lock 2> /dev/null; then
    echo "build: build/.lock is held: another build is running (if none is, remove the folder build/.lock)" >&2
    exit 1
fi
trap 'rmdir build/.lock' EXIT INT TERM

for step in build_game build_loaders build_trd_extras; do
    if [ -f tools/$step.sh ]; then
        sh tools/$step.sh "$SJASMPLUS"
    else
        echo "build: warning: tools/$step.sh is missing, skipped"
    fi
done

unzip -oq orig/NE_GS_TZ.zip -d build/orig
fail=0
same() { # BUILT ORIGINAL
    if cmp -s "$1" "$2"; then echo "build: identical to $2"; else echo "build: $1 DIFFERS from $2"; fail=1; fi
}
python3 tools/mkscl.py src/media/scl.txt build/NE_GS_TZ.SCL
same build/NE_GS_TZ.SCL build/orig/NE_GS_TZ.SCL
rm -f "build/$TRD"
if [ -f $TRD_DIR/boot.bin ] && [ -f $TRD_DIR/Neart481.bin ] && [ -f $TRD_DIR/Neart482.bin ]; then
    python3 tools/mktrd.py src/media/trd.txt "build/$TRD"
    same "build/$TRD" "orig/$TRD"
else
    echo "build: $TRD_DIR/{boot,Neart481,Neart482}.bin missing: the TRD is not written"
    fail=1
fi
python3 tools/mktap.py src/media/tap.txt "build/$TAP"
same "build/$TAP" "orig/$TAP"
[ $fail = 0 ] || { echo "build: FAILED"; exit 1; }
