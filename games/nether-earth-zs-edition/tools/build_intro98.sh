#!/bin/sh
# The intro98 part of the '98 from its sources into build/intro98, each file compared byte for byte with the bytes
# it stands for (work/media/98, written from orig/ by tools/zs_media.py; never a recording):
#
#   tools/build_intro98.sh [SJASMPLUS]
#
#   build/intro98/basic.bin        src/basic98/basic.asm                    = work/media/98/basic.bin  NEZSEd.B
#                                                                             sectors 0-1 ($5D3B-$5F3A)
#   build/intro98/intro-c000.bin   src/intro98/intro98.asm (+ intro98/*.asm) = work/media/98/intro.bin  sectors 2-43
#                                                                             ($C000-$E9FF)
#
# The resources go first through tools/intro98_res.py build (the scroller text UTF-8 -> KOI-7 N2 with its loop
# word, the logo, robot and font PNG -> bytes, the robot's frames packed by robot.parse, the .pt3 tune and the
# leftovers as they are) into build/intro98/res, which the sources INCBIN as "res/intro98/<file>". The file's bytes
# are built, not the ones at run time (Pt3Init fills $C048-$C0FF when the intro starts).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
b="$here/build/intro98"
m="$here/work/media/98"
rm -rf "$b"
mkdir -p "$b"
cd "$here"

[ -f "$m/intro.bin" ] && [ -f "$m/basic.bin" ] || python3 tools/zs_media.py >/dev/null

same() {  # built file, original
    cmp "$1" "$2" >/dev/null || { echo "build_intro98: $1 differs from $2" >&2; cmp "$1" "$2" >&2 || true; exit 1; }
    echo "build_intro98: $(basename "$1") = $(basename "$2") ($(wc -c < "$1" | tr -d ' ') bytes)"
}

part() {  # the top source, the file it saves, the original
    (cd "$b" && "$asm" --nologo --msg=war -I"$b" --lst="$b/$(basename "$1" .asm).lst" "$here/$1")
    same "$b/$2" "$3"
}

python3 tools/intro98_res.py build --out "$b/res"
part src/basic98/basic.asm basic.bin "$m/basic.bin"
part src/intro98/intro98.asm intro-c000.bin "$m/intro.bin"
echo "build_intro98: identical"
