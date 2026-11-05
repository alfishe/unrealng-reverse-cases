#!/bin/sh
# The game's source from src/game/game.ann: kit/mkgame.py (case.json: the image $6800-$FFFF as block 2's set-up
# moves it, the L1 of work/c1, r1, r2), installed beside the 128K parts' sources.
#
#   tools/mkgame.sh [SJASMPLUS]
#
# kit/mkgame.py writes work/mkgame/ and says whether the modules assemble to the image's bytes. Only then are they
# installed: src/game/*.asm, except the parts tools/mkasm_all.sh writes (hooks, stubs, glue128, glue, kmouse, mouse,
# block2, setup), is replaced by work/mkgame/*.asm, and the resources go into src/res in their editable formats
# (tools/res_formats.py install). Needs SkoolKit ($SKOOLKIT_VENV) and work/c1, r1, r2 (WALKTHROUGH.md).
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
VENV=${SKOOLKIT_VENV:-/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit}
PARTS="hooks stubs glue128 glue kmouse mouse block2 setup"

rm -rf work/mkgame/res
python3 ../../kit/mkgame.py --case . --venv "$VENV" --sjasmplus "$SJASMPLUS" --out work/mkgame > work/mkgame.log
cat work/mkgame.log
grep -q '^assembled: identical' work/mkgame.log || { echo "mkgame: not installed" >&2; exit 1; }
for f in src/game/*.asm; do
    n=$(basename "$f" .asm)
    case " $PARTS " in *" $n "*) ;; *) rm "$f" ;; esac
done
for f in work/mkgame/*.asm; do
    n=$(basename "$f" .asm)
    case " $PARTS " in *" $n "*) echo "mkgame: module $n clashes with a part" >&2; exit 1 ;; esac
    cp "$f" src/game/
done
python3 tools/res_formats.py install work/mkgame
echo "mkgame: installed $(ls work/mkgame/*.asm | wc -l | tr -d ' ') files in src/game"
