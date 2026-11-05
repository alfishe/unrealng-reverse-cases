#!/bin/sh
# The sound of Zynaps 2 in 1 from its sources, into build/sound/ (nothing else is written):
#
#   tools/build_sound.sh [SJASMPLUS]
#
#   build/sound/sk10.bin              tools/sk10.py encode src/res/music/sk10.txt (the STarKos song, $8990)
#   build/sound/starkos-8000.bin      sjasmplus src/sound/starkos.asm: the STarKos player with sk10.bin ($8000-$90C4)
#   build/sound/engine-data-de48.bin  tools/sound_data.py encode src/res/sound/engine-data.txt ($DE48-$FE6F)
#   build/sound/engine-c968.bin       sjasmplus src/sound/engine.asm: the page-4 engine ($C968-$CD22)
#
# Each image is compared with the original's part (work/parts/, tools/parts.py; without work/parts the parts are cut
# from orig/ into build/sound/orig/): the script fails on the first difference. tools/build.sh calls it first.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
OUT=build/sound

mkdir -p "$OUT"
if [ -f work/parts/starkos-8000.bin ] && [ -f work/parts/engine-c968.bin ] && [ -f work/parts/engine-data-de48.bin ]; then
    ORIG=work/parts
else
    ORIG=$OUT/orig
    python3 tools/parts.py --out "$ORIG" > /dev/null
fi

asm() { # SOURCE: from the case's folder (SAVEBIN and INCBIN paths are relative to it), no warnings allowed
    out=$("$SJASMPLUS" --nologo --msg=war --fullpath -I. "$1" 2>&1) || { echo "$out"; exit 1; }
    [ -z "$out" ] || { echo "$out"; echo "build_sound: $1: warnings"; exit 1; }
}
same() { # NAME: build/sound/NAME against the original's part
    if cmp -s "$OUT/$1" "$ORIG/$1"; then
        echo "build_sound: $OUT/$1 identical"
    else
        cmp "$OUT/$1" "$ORIG/$1" || true
        echo "build_sound: $OUT/$1 DIFFERS from $ORIG/$1" >&2
        exit 1
    fi
}

python3 tools/sk10.py encode src/res/music/sk10.txt "$OUT/sk10.bin" > /dev/null
asm src/sound/starkos.asm
same starkos-8000.bin
python3 tools/sound_data.py encode src/res/sound/engine-data.txt "$OUT/engine-data-de48.bin" > /dev/null
same engine-data-de48.bin
asm src/sound/engine.asm
same engine-c968.bin
