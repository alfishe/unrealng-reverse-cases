#!/bin/sh
# Build orig/boot.scl from the sources and compare it with the original, byte for byte.
#
#   tools/build.sh [SJASMPLUS]
#   tools/build.sh [SJASMPLUS] --variant NAME     # variants/NAME over src/res, compared with its candidate image
#   tools/build.sh [SJASMPLUS] --all              # every variant, one line each (tools/variants.py)
#
# build/boot.scl: one file, boot (B, start 180, length 180, 46 sectors), whose body is
#   - src/basic/basic.asm: sector 0, the BASIC program at PROG $5D3B with the loader in line 4 (256 bytes);
#   - src/main/main.asm: the menu, $61A8-$70A7 (15 sectors), and its graphics, $A600-$ADFF (8 sectors);
#   - src/music/music.asm: the music, $C000-$D5FF (22 sectors).
# The order is the loader's (docs/03-build-and-load.md). Every .asm is written by kit/mkgame.py from its .ann;
# src/res by tools/res_formats.py.
#
# One build at a time: a second one waits for build/.lock (a directory) to go away.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
sj=""; variant=""
while [ $# -gt 0 ]; do
    case "$1" in
        --variant) variant="$2"; shift 2 ;;
        --all) variant="--all"; shift ;;
        *) sj="$1"; shift ;;
    esac
done
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "$sj") || exit 1  # $SJASMPLUS, PATH or a checkout
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
if [ -n "$variant" ]; then
    if [ "$variant" = "--all" ]; then
        python3 "$here/tools/variants.py" build --all --sjasmplus "$asm"
    else
        python3 "$here/tools/variants.py" build "$variant" --sjasmplus "$asm"
    fi
    exit $?
fi
cd "$here/build"
rm -rf "$here/build/res"
python3 "$here/tools/res_formats.py" build --out "$here/build/res"
a() { "$asm" --nologo --msg=war -I"$here/build" -I"$(dirname "$1")" --lst="$(basename "$1" .asm).lst" "$1"; }
a "$here/src/basic/basic.asm"
a "$here/src/main/main.asm"
a "$here/src/music/music.asm"
# The body: the BASIC sector, the code ($61A8, 15 sectors), the graphics ($A600, 8 sectors), the music (22 sectors)
python3 - <<'PY'
basic = open('basic.bin', 'rb').read()
main = open('main.bin', 'rb').read()
music = open('music.bin', 'rb').read()
code = main[:15 * 256]
graphics = main[0xA600 - 0x61A8:0xA600 - 0x61A8 + 8 * 256]
assert len(basic) == 256 and len(code) == 3840 and len(graphics) == 2048 and len(music) == 22 * 256
open('boot.body', 'wb').write(basic + code + graphics + music)
PY
python3 "$here/tools/disk.py" scl boot.scl "boot:B:180:180:boot.body"
cmp boot.scl "$here/orig/boot.scl" && echo "build: boot.scl identical to orig/boot.scl"
