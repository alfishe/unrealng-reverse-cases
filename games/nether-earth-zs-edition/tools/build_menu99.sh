#!/bin/sh
# The menu99 part of the '99 from its sources into build/menu99, each file compared byte for byte with the bytes
# it stands for (work/media/99, written from orig/ by tools/zs_media.py; never a recording):
#
#   tools/build_menu99.sh [SJASMPLUS]
#
#   build/menu99/stage3-61a8.bin   src/stage3/stage3.asm (+ s3*.asm)   = work/media/99/stage3-out.bin  the unpacked
#                                                                       stage 3, $61A8-$67EB
#   build/menu99/menu-d800.bin     src/menu99/menu.asm (+ menu*.asm)   = work/media/99/menu-out.bin    the unpacked
#                                                                       menu, $D800-$E6F3 (page 1)
#
# The menu's resources go first through tools/menu99_res.py (the PrintInline strings from text, the pointer and the
# viewer font from PNG) into build/menu99/res/menu99, which src/menu99 INCBINs as "res/menu99/<file>".
# The .asm files are written from src/stage3/stage3.ann and src/menu99/menu.ann by tools/menu99_mkgame.py --install.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/menu99"
m="$here/work/media/99"
rm -rf "$b"
mkdir -p "$b"
cd "$here"

[ -f "$m/stage3-out.bin" ] || python3 tools/zs_media.py >/dev/null

same() {  # built file, original
    cmp "$1" "$2" >/dev/null || { echo "build_menu99: $1 differs from $2" >&2; cmp "$1" "$2" >&2 || true; exit 1; }
    echo "build_menu99: $(basename "$1") = $(basename "$2") ($(wc -c < "$1" | tr -d ' ') bytes)"
}

part() {  # the top source, the file it saves, the original
    (cd "$b" && "$asm" --nologo --msg=war -I"$b" -I"$here/$(dirname "$1")" --lst="$b/$(basename "$1" .asm).lst" "$here/$1")
    same "$b/$2" "$3"
}

python3 tools/menu99_res.py build "$b"
part src/stage3/stage3.asm stage3-61a8.bin "$m/stage3-out.bin"
part src/menu99/menu.asm menu-d800.bin "$m/menu-out.bin"
echo "build_menu99: identical"
