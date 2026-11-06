#!/bin/sh
# The game's source from src/game/game.ann: kit/mkgame.py (case.json: the image $6800-$FFFF as block 2's set-up
# moves it, the L1 of work/c1, r1, r2), installed beside the 128K parts' sources.
#
#   tools/mkgame.sh [SJASMPLUS]
#
# kit/mkgame.py writes work/mkgame/ and says whether the modules assemble to the image's bytes. Only then are they
# installed in src/game (the modules the earlier game.asm included and no more are removed; the parts
# tools/mkasm_all.sh writes there, hooks, stubs, glue128, glue, kmouse, mouse, block2 and setup, stay) and the
# resources go into src/res in their editable formats (tools/res_formats.py install). Needs SkoolKit
# ($SKOOLKIT_VENV, else kit/toolpaths.py finds one) and work/c1, r1, r2 (WALKTHROUGH.md).
set -eu
cd "$(dirname "$0")/.."
python3 ../../kit/mkgame.py --case . ${1:+--sjasmplus "$1"} --install
