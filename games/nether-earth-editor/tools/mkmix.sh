#!/bin/sh
# nee.mix's source from src/mix/mix.ann through kit/mkgame.py, installed in src/mix only when sjasmplus gives the
# tape's bytes.
#
#   tools/mkmix.sh VENV SJASMPLUS [RECORDING ...]
#
# mkgame takes a case folder (case.json, orig/, work/<build>/l1.json): a staging root in work/mkmix stands for it, with
# src/mix/case.json, orig/ and the recordings linked in (default: work/edB/tour, the L1 build of the whole editor tour,
# whose instructions count, and work/edB/tour-edit, the same from frame 2700, after the tape: its data reads count).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
venv=$1; asm=$2; shift 2
[ $# -gt 0 ] || set -- "$here/work/edB/tour" "$here/work/edB/tour-edit"
root=$here/work/mkmix/root
rm -rf "$root"
mkdir -p "$root/work/mkmix" "$root/tools"
cp "$here/src/mix/case.json" "$root/case.json"
ln -s "$here/orig" "$root/orig"
cp "$here/tools/mix_image.py" "$root/tools/"
for rec in "$@"; do ln -s "$rec" "$root/work/$(basename "$rec")"; done
out=$here/work/mkmix/out
rm -rf "$out"
python3 "$here/../../kit/mkgame.py" --case "$root" --venv "$venv" --sjasmplus "$asm" --ann "$here/src/mix/mix.ann" \
    --out "$out"
# mkgame exits non-zero unless the bytes are the original's: here they are
for f in "$out"/*.asm; do
    cp "$f" "$here/src/mix/"
done
# the tiles and the font as PNG in src/res/mix (tools/mix_res.py), built back to the bytes by the build
python3 "$here/tools/mix_res.py" export "$out/res"
echo "installed $(ls "$out"/*.asm | wc -l | tr -d ' ') files in src/mix, the resources in src/res/mix"
