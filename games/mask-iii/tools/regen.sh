#!/bin/sh
# Write every .asm of the case from its .ann (kit/mkgame.py --install), then build: tools/regen.sh [--fix-witness]
set -e
cd "$(dirname "$0")/.."
python3 ../../kit/mkgame.py --case . --install "$@" | tail -2
for p in src/tape/basic.json src/loader/loader.json src/screen/screen.json src/music/music.json; do
    python3 ../../kit/mkgame.py --part "$p" --install "$@" | grep -v 'outside the image' | tail -1
done
