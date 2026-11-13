#!/bin/sh
# Regenerate every .asm of the case from its .ann (kit/mkgame.py), each checked to assemble to the original's bytes
# before it is installed. Run after editing an .ann; tools/build.sh needs only the .asm files.
#
#   tools/mkasm_all.sh [PART ...]      # all parts, or only the named ones (stage1, stage2, front, resident, ...)
#
# Needs work/parts/ ($SKOOLKIT_VENV/bin/python tools/parts.py, from orig/ alone), work/mkgame/ (tools/image.py, from
# orig/ alone) and the recordings' L1 files in work/stage1/ (WALKTHROUGH 6.0).
set -eu
cd "$(dirname "$0")/.."
[ -f work/parts/resident-f000.bin ] || "$SKOOLKIT_VENV/bin/python" tools/parts.py
[ -f work/mkgame/stage5.bin ] || python3 tools/image.py work/mkgame > /dev/null
mk() { python3 ../../kit/mkgame.py "$@" --install | tail -1; }
all="stage1 basic chain sl1 unxor sl1end boot resident front stage2 stage3 stage4 stage5"
for p in ${*:-$all}; do
    printf '%s: ' "$p"
    case $p in
        stage1) mk --case . ;;
        basic) mk --part src/tape/basic.json ;;
        chain|sl1|unxor|sl1end|boot) mk --part src/loader/$p.json ;;
        *) mk --part src/$p/$p.json ;;
    esac
done
