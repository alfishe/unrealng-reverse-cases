#!/bin/sh
# The endings from source: Dead End (bank 3) and Final Cut, into build/endings/, each checked byte for byte against
# the raw image it replaces.
#
#   tools/build_endings.sh [SJASMPLUS]          (from any folder; writes only build/endings/)
#
# | Output (build/endings/)    | Source                                         | Replaces                           |
# | -------------------------- | ---------------------------------------------- | ---------------------------------- |
# | deadend-c000-bank3.bin     | src/endings/deadend.asm + deadend/*.asm         | src/res/img/dead-end-c000-bank3.bin |
# | finalcut-6060.bin          | src/endings/finalcut.asm + finalcut/*.asm       | src/res/img/final-cut-6060.bin     |
#
# The resources (src/res/endings: PNG screens, the LZ hints, the scroll font PNG, the scroll text) and Dead End's
# tune (src/res/music/nether-earth-end.pt2 compiled for $CA45) go to build/endings/res first (tools/endings_res.py).
# The players are aneS's sources, included in place: src/music/stp-player.asm (module nst, Dead End $C000) and
# src/music/pt3-player.asm (module pt3, Final Cut $DB00, with src/res/music/rem.pt3 as it is).
# The sources are written by kit/mkgame.py --part src/endings/*.json from src/endings/*.ann (edit those, then
# --install).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
b="$here/build/endings"
rm -rf "$b"
mkdir -p "$b"
python3 "$here/tools/endings_res.py" build --out "$b" >/dev/null
for p in deadend finalcut; do
    (cd "$b" && "$asm" --nologo --msg=war -I"$b" -I"$here" --lst="$b/$p.lst" "$here/src/endings/$p.asm")
done
check() {
    if [ ! -f "$here/src/res/img/$2" ]; then  # replaced: tools/build.sh's SCL compare checks it
        echo "endings: $1 built ($(wc -c < "$b/$1" | tr -d ' ') bytes)"; return
    fi
    if cmp -s "$b/$1" "$here/src/res/img/$2"; then
        echo "endings: $1 identical (src/res/img/$2, $(wc -c < "$b/$1" | tr -d ' ') bytes)"
    else
        echo "endings: $1 DIFFERS from src/res/img/$2" >&2
        exit 1
    fi
}
check deadend-c000-bank3.bin dead-end-c000-bank3.bin
check finalcut-6060.bin final-cut-6060.bin
