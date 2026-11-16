#!/bin/sh
# Build the tape of ATV Simulator from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#
# build/ATV Simulator.tzx: every block of orig/ATVSimulator.tzx.zip's "ATV Simulator.tzx" (src/tape/tape.txt), from
#   - src/tape/basic.asm: the BASIC loader "ATV";
#   - src/loader/loader.asm: the machine-code loader at $FFDC;
#   - src/game/game.asm: the game, $6338-$FF77;
#   - src/res (the loading screen, the game's resources: tools/res_formats.py build);
#   tools/mktape.py writes the headers and the blocks with their pauses.
#
# One build at a time: a second one waits for build/.lock (a directory) to go away.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1  # $SJASMPLUS, PATH or a checkout
mkdir -p "$here/build"
lock="$here/build/.lock"
waited=0
while ! mkdir "$lock" 2>/dev/null; do
    if [ $waited -ge 600 ]; then
        echo "build: $lock held for 10 minutes (a crashed build? remove it)" >&2
        exit 1
    fi
    [ $waited -eq 0 ] && echo "build: waiting for another build ($lock)" >&2
    sleep 1
    waited=$((waited + 1))
done
trap 'rmdir "$lock"' EXIT INT TERM
cd "$here/build"
rm -rf "$here/build/res"
python3 "$here/tools/res_formats.py" build --out "$here/build/res"
a() { "$asm" --nologo --msg=war -I"$here/build" -I"$(dirname "$1")" --lst="$(basename "$1" .asm).lst" "$1"; }
a "$here/src/game/game.asm"
a "$here/src/tape/basic.asm"
a "$here/src/loader/loader.asm"
python3 "$here/tools/mktape.py" "$here/src/tape/tape.txt" "ATV Simulator.tzx" .
mkdir -p orig
unzip -p "$here/orig/ATVSimulator.tzx.zip" "ATV Simulator.tzx" > orig/atv-simulator.tzx
cmp "ATV Simulator.tzx" orig/atv-simulator.tzx && echo "build: ATV Simulator.tzx identical to orig/ATVSimulator.tzx.zip's ATV Simulator.tzx"
