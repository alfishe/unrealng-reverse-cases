#!/bin/sh
# nee.mix's source from src/mix/mix.ann through kit/mkgame.py, installed in src/mix only when sjasmplus gives the
# tape's bytes.
#
#   tools/mkmix.sh [VENV [SJASMPLUS]]
#
# src/mix/case.json is the part: the image tools/mix_image.py cuts from the tape, the recordings work/edB/tour (the
# whole editor tour: its instructions count) and work/edB/tour-edit (the same from frame 2700, after the tape: its
# data reads count), src/mix as the destination and tools/mix_res.py install for the tiles and the font
# (src/res/mix/*.png). VENV and SJASMPLUS default to $SKOOLKIT_VENV / $SJASMPLUS or what kit/toolpaths.py finds.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
set -- ${1:+--venv "$1"} ${2:+--sjasmplus "$2"}
python3 "$here/../../kit/mkgame.py" --case "$here" --config "$here/src/mix/case.json" --ann "$here/src/mix/mix.ann" \
    --install "$@"
