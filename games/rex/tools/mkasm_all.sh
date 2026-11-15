#!/bin/sh
# Regenerate every .asm of the case from its .ann (kit/mkgame.py), each checked to assemble to the original's bytes
# before it is installed. Run after editing an .ann; tools/build.sh needs only the .asm files.
#
#   tools/mkasm_all.sh [--fix-witness]
#
# Needs work/parts/ and work/mkgame/original.bin (tools/parts.py, from orig/ alone) and the recordings' L1 files
# (WALKTHROUGH 6.0).
set -eu
cd "$(dirname "$0")/.."
python3 tools/parts.py > /dev/null
mk() { python3 ../../kit/mkgame.py "$@" --install | grep -v '^witness: \|lies outside the image' | tail -2; }
mk --case . "$@"
for p in src/tape/basic-rex1.json src/tape/basic-rex2.json src/tape/basic-demo.json \
         src/screen/screen-rex1.json src/screen/screen-rex2.json src/screen/screen-demo.json \
         src/rex2/rex2.json src/demo/demo.json; do
    mk --case . --part "$p" "$@"
done
