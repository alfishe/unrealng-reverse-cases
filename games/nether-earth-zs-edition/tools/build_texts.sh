#!/bin/sh
# The five ZX Word texts of the '99 disk from src/res/text into build/texts, compared byte for byte with their
# sectors on the original disk (work/media/99/files, written by tools/zs_media.py when missing).
#
#   tools/build_texts.sh [SJASMPLUS]      (the assembler argument is accepted for tools/build.sh and not used)
#
#   build/texts/NEabout.W    15 sectors   = work/media/99/files/01_NEabout.W
#   build/texts/NEdescri.W   22 sectors   = work/media/99/files/02_NEdescri.W
#   build/texts/NEgreets.W    2 sectors   = work/media/99/files/03_NEgreets.W
#   build/texts/NEadvice.W   22 sectors   = work/media/99/files/04_NEadvice.W
#   build/texts/NEZSEd99.W   22 sectors   = work/media/99/files/05_NEZSEd99.W
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
[ -f "$here/work/media/99/files/05_NEZSEd99.W" ] || python3 "$here/tools/zs_media.py" >/dev/null
rm -rf "$here/build/texts"
python3 "$here/tools/texts_build.py" check --out "$here/build/texts"
