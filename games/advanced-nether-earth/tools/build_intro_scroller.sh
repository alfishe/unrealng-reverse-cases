#!/bin/sh
# The credits scroller ($6600-$FFFF) from src/intro/scroller and src/res/intro/scroller into build/intro/d03-6600.bin,
# compared byte for byte with src/res/img/d03-6600.bin while that raw image is there. Called by tools/build_intro.sh.
#
#   tools/build_intro_scroller.sh [SJASMPLUS]
#
# The text, font, dither levels, screen and star path (tools/intro_scroller.py) -> build/intro/res/scroller/*.bin,
# which the sources INCBIN as "res/scroller/<file>".
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
b="$here/build/intro"
mkdir -p "$b/res/scroller"
python3 "$here/tools/intro_scroller.py" build --src "$here/src/res/intro/scroller" --out "$b/res/scroller"
(cd "$b" && "$asm" --nologo --msg=war -I"$b" --lst="$b/scroller.lst" "$here/src/intro/scroller/scroller.asm")
mv "$b/scroller.bin" "$b/d03-6600.bin"
raw="$here/src/res/img/d03-6600.bin"
if [ -f "$raw" ]; then
    cmp "$b/d03-6600.bin" "$raw" >/dev/null || { echo "build_intro_scroller: build/intro/d03-6600.bin differs from $raw" >&2; exit 1; }
fi
echo "build_intro_scroller: identical"
