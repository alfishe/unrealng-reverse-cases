#!/bin/sh
# Regenerate every .asm of the case from its .ann (kit/mkgame.py), each checked to assemble to the original's bytes
# before it is installed. Run after editing an .ann; tools/build.sh needs only the .asm files.
#
#   tools/mkasm_all.sh [--fix-witness]
#
# Needs work/parts/ (tools/parts.py, from orig/ alone), work/mkgame/original.bin (tools/image.py) and the
# recordings' L1 files (WALKTHROUGH 6.0).
set -eu
cd "$(dirname "$0")/.."
python3 tools/parts.py > /dev/null
mk() { python3 ../../kit/mkgame.py "$@" --install | tail -1; }
mk --case . "$@"
for p in src/tape/basic.json src/screen/screen.json src/music/music.json src/select/select.json \
         src/explorers/explorers.json; do
    mk --part "$p" "$@"
done
