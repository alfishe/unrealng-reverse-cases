#!/bin/sh
# The front99 part of the '99 from its sources into build/front99, each file compared byte for byte with the bytes
# it stands for (work/media/99, written from orig/ by tools/zs_media.py; never a recording):
#
#   tools/build_front99.sh [SJASMPLUS]
#
#   build/front99/basic.bin          src/basic99/basic.asm                  = work/media/99/basic.bin      sector 0
#   build/front99/stage2-61a8.bin    src/stage2/stage2.asm (+ stage2/*.asm) = work/media/99/stage2-out.bin the unpacked
#                                                                             stage 2, $61A8-$7D86
#   build/front99/pictures-7d87.bin  src/pictures99/pictures.asm            = work/media/99/pictures.bin   sectors 19-31
#   build/front99/music-c000.bin     src/music99/music.asm                  = work/media/99/music.bin      sectors 32-44
#
# The resources go first through tools/front99_res.py (the scroller text UTF-8 -> CP866, the font and the intro
# screen PNG -> bytes, the screen packed with the decoder's RLE, the .stc tune and the leftovers as they are) into
# build/front99/res, which the sources INCBIN as "res/<part>/<file>".
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=$(python3 "$here/../../kit/toolpaths.py" sjasmplus "${1:-}") || exit 1
b="$here/build/front99"
m="$here/work/media/99"
rm -rf "$b"
mkdir -p "$b"
cd "$here"

[ -f "$m/basic.bin" ] || python3 tools/zs_media.py >/dev/null

same() {  # built file, original
    cmp "$1" "$2" >/dev/null || { echo "build_front99: $1 differs from $2" >&2; cmp "$1" "$2" >&2 || true; exit 1; }
    echo "build_front99: $(basename "$1") = $(basename "$2") ($(wc -c < "$1" | tr -d ' ') bytes)"
}

part() {  # the top source, the file it saves, the original
    (cd "$b" && "$asm" --nologo --msg=war -I"$b" --lst="$b/$(basename "$1" .asm).lst" "$here/$1")
    same "$b/$2" "$3"
}

python3 tools/front99_res.py build "$b"
part src/basic99/basic.asm basic.bin "$m/basic.bin"
part src/stage2/stage2.asm stage2-61a8.bin "$m/stage2-out.bin"
part src/pictures99/pictures.asm pictures-7d87.bin "$m/pictures.bin"
part src/music99/music.asm music-c000.bin "$m/music.bin"
echo "build_front99: identical"
