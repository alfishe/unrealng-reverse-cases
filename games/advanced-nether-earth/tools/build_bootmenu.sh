#!/bin/sh
# The boot program (the boot menu and the help, $6060-$F6D4) from its sources into build/bootmenu, compared byte for
# byte with the raw image it replaces (src/res/img/d05-6060.bin, while that file is still there).
#
#   tools/build_bootmenu.sh [SJASMPLUS]
#
#   build/bootmenu/d05-6060.bin   the image HRUM block 5 unpacks to $6060 (src/bootmenu/bootmenu.asm and its
#                                 modules, written by tools/bootmenu_mkasm.py from src/bootmenu/bootmenu.ann)
#                                                                      = src/res/img/d05-6060.bin
#
# The resources go first through tools/bootmenu_res.py into build/bootmenu/res, which the modules INCBIN as
# "res/<file>": the 15 pictures from PNG, packed with Hrust 1 (tools/bootmenu_hrust.py), the two fonts from PNG,
# the menu and the 28 help pages from UTF-8 text.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/bootmenu"
rm -rf "$b"
mkdir -p "$b/res"
python3 "$here/tools/bootmenu_res.py" build --out "$b"
(cd "$b" && "$asm" --nologo --msg=war -I"$b" -I"$here/src/bootmenu" --lst="$b/bootmenu.lst" \
    "$here/src/bootmenu/bootmenu.asm")
raw="$here/src/res/img/d05-6060.bin"
if [ -f "$raw" ]; then
    cmp "$b/d05-6060.bin" "$raw" >/dev/null || { echo "build_bootmenu: $b/d05-6060.bin differs from $raw" >&2; exit 1; }
    echo "build_bootmenu: identical to src/res/img/d05-6060.bin"
fi
