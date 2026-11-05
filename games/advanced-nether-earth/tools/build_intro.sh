#!/bin/sh
# The boot's pictures from their sources (src/intro, src/res/intro) into build/intro, each compared byte for byte
# with the raw image it replaces (src/res/img/<file>, while that file is still there).
#
#   tools/build_intro.sh [SJASMPLUS]
#
#   build/intro/plain-9c40.bin         the title picture at $9C40 (src/intro/title)      = src/res/img/plain-9c40.bin
#   build/intro/intro-screen-c000.bin  the Eternity Industry logo (src/res/intro/eternity.png)
#                                                                                         = src/res/img/intro-screen-c000.bin
#   build/intro/intro-6600.bin         the intro, $6600-$A3AC (src/intro/intro), its picture block's place zero
#                                                                                         = src/res/img/intro-6600.bin
#   build/intro/intro-6600-block.bin   the same with build/blk/introscreen.bin at $7537 (-DINTRO_SCREEN_BLOCK;
#                                      only when that block is built)                    = build/img/intro-6600.bin
#   build/intro/d02-6600.bin           "Presents" (src/intro/presents)                   = src/res/img/d02-6600.bin
#   build/intro/d03-6600.bin           the credits scroller (src/intro/scroller)         = src/res/img/d03-6600.bin
#
# The resources go first through tools/intro_screen.py (screens: PNG -> bytes; the screen LZ packed along the
# authors' parse) into build/intro/res, which the sources INCBIN as "res/<file>".
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/intro"
r="$here/src/res/intro"
rm -rf "$b"
mkdir -p "$b/res"
cd "$here"

same() {  # built file, raw file
    if [ -f "$2" ]; then
        cmp "$1" "$2" >/dev/null || { echo "build_intro: $1 differs from $2" >&2; exit 1; }
    fi
}

part() {  # folder under src/intro, its top file, the output name
    (cd "$b" && "$asm" --nologo --msg=war -I"$b" --lst="$b/$2.lst" "$here/src/intro/$1/$2.asm")
    mv "$b/$2.bin" "$b/$3"
}

# The intro: the plain logo (a screen for the packing step's HRUM block), the decorated logo's screen LZ, the
# player and MAD NIGHT (aneS's build of the tune), the picture block's place zero (and filled when it is built)
python3 tools/intro_screen.py to-scr "$r/eternity.png" "$b/intro-screen-c000.bin"
same "$b/intro-screen-c000.bin" src/res/img/intro-screen-c000.bin
python3 tools/intro_screen.py to-scr "$r/logo.png" "$b/res/logo.scr"
python3 tools/intro_screen.py pack "$b/res/logo.scr" "$b/res/logo.lz" "$r/logo.parse"
sh tools/build_music.sh >/dev/null
mkdir -p "$b/music" && cp build/music/intro-music-7d2d.bin "$b/music/"
(cd "$b" && "$asm" --nologo --msg=war -I"$b" -I"$here/src/intro" --lst="$b/intro.lst" "$here/src/intro/intro.asm")
mv "$b/intro.bin" "$b/intro-6600.bin"
same "$b/intro-6600.bin" src/res/img/intro-6600.bin
if [ -f build/blk/introscreen.bin ]; then
    mkdir -p "$b/blk" && cp build/blk/introscreen.bin "$b/blk/"
    (cd "$b" && "$asm" --nologo --msg=war -DINTRO_SCREEN_BLOCK -I"$b" -I"$here/src/intro" "$here/src/intro/intro.asm")
    mv "$b/intro.bin" "$b/intro-6600-block.bin"
    same "$b/intro-6600-block.bin" build/img/intro-6600.bin
fi

# The title picture: the screen LZ from the PNG along the authors' parse, the sector's leftover as it is
python3 tools/intro_screen.py to-scr "$r/title.png" "$b/res/title.scr"
python3 tools/intro_screen.py pack "$b/res/title.scr" "$b/res/title.lz" "$r/title.parse"
cp "$r/title-leftover.bin" "$b/res/"
part title title plain-9c40.bin
same "$b/plain-9c40.bin" src/res/img/plain-9c40.bin

# "Presents" and the scroller: their own steps (each writes build/intro/<file>.bin and compares it)
for sub in presents scroller; do
    if [ -f tools/build_intro_$sub.sh ]; then
        sh tools/build_intro_$sub.sh "$asm"
    fi
done

echo "build_intro: identical"
