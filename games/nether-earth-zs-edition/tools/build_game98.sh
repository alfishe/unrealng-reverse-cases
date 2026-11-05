#!/bin/sh
# Build the '98 game from its sources and compare it with the file's bytes, byte for byte.
#
#   tools/build_game98.sh [SJASMPLUS]
#
# The resources (src/res/game98, tools/game98_res.py) into build/game98/res/game98; src/game98/game98.asm (written by
# tools/game98_mkgame.py from src/game98/game.ann) assembled into build/game98/game98.bin, its SAVEBIN of
# $6780-$D87F (28928 bytes), renamed game98-6780.bin and compared with NEZSEd.B's sectors 44-156 in
# orig/NEZSED98.zip (tools/game98_image.py). src/disk98.txt puts game98-6780.bin back into the file.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/game98"
mkdir -p "$b"
python3 "$here/tools/game98_res.py" build --out "$b/res"
cd "$b"
rm -f game98.bin game98-6780.bin
"$asm" --nologo --msg=war -I"$b" -I"$here/src/game98" --lst=game98.lst "$here/src/game98/game98.asm"
mv game98.bin game98-6780.bin
python3 - "$here" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/tools')
import game98_image
built, want = open('game98-6780.bin', 'rb').read(), game98_image.game_bytes()
if built != want:
    at = next(i for i in range(len(want)) if i >= len(built) or built[i] != want[i])
    sys.exit('build: game98-6780.bin differs from the file at $%04X' % (game98_image.LO + at))
print('build: game98-6780.bin identical to NEZSEd.B sectors 44-156 (%d bytes)' % len(want))
PY
