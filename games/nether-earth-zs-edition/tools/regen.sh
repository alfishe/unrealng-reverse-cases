#!/bin/sh
# Write every part's .asm again from its annotations (kit/mkgame.py --part, one part file each), each installed only
# when it assembles to the original's bytes, then build and compare the disks.
#
#   tools/regen.sh [SJASMPLUS]
#
# The part files: src/game99/game.json, src/patches99/patches.json (eight pieces, each at its run address),
# src/game98/game.json, src/intro98/intro.json, src/stage2/stage2.json, src/pictures99/pictures.json,
# src/music99/music.json, src/stage3/stage3.json, src/menu99/menu.json. Each names its image (tools/game99_image.py,
# tools/game98_image.py, tools/zs_media.py write them from orig/), its own L1 windows under work/stage2/<part>/ and
# the tool that installs its resources. SkoolKit: $SKOOLKIT_VENV, else what kit/toolpaths.py finds.
set -eu
cd "$(dirname "$0")/.."
SJASMPLUS=$(python3 ../../kit/toolpaths.py sjasmplus "${1:-${SJASMPLUS:-}}")
for p in game99/game patches99/patches game98/game intro98/intro stage2/stage2 pictures99/pictures music99/music \
         stage3/stage3 menu99/menu; do
    python3 ../../kit/mkgame.py --part "src/$p.json" --sjasmplus "$SJASMPLUS" --install | tail -1
done
sh tools/build.sh "$SJASMPLUS"
