#!/bin/sh
# Regenerate every .asm of the case from its .ann (kit/mkgame.py), each checked to assemble to the original's bytes
# before it is installed. Run after editing an .ann; tools/build.sh needs only the .asm files.
#
#   tools/mkasm_all.sh
#
# Needs work/parts/ ($SKOOLKIT_VENV/bin/python tools/parts.py, from orig/ alone), work/mkgame/ (tools/image.py, from
# the c1 recording) and the recordings' L1 files in work/stage1/rec/*/l1.json (WALKTHROUGH 6.0).
set -eu
cd "$(dirname "$0")/.."
[ -f work/parts/bank7-c000.bin ] || "$SKOOLKIT_VENV/bin/python" tools/parts.py
mk() { python3 ../../kit/mkgame.py "$@" --install | tail -1; }
mk --case .
for p in src/tape/basic.json src/loader/chain.json src/loader/stage2.json src/loader/final-be5d.json \
         src/loader/final-bf21.json src/bank3/bank3.json src/bank4/bank4.json src/bank6/bank6.json src/bank7/bank7.json; do
    mk --part "$p"
done
