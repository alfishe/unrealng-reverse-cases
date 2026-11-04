#!/bin/sh
# The whole tape orig/NETHER.TZX from src/, byte for byte: the game edition (a snapshot of Nether Earth's menu with
# its loader), the eight saved games (seven levels and the editor's own save) and the editor (two BASIC programs and
# the machine code nee.mix).
#
#   tools/build.sh [SJASMPLUS [PYTHON]]
#
# PYTHON must have SkoolKit (tools/zxbasic.py computes the ROM's inexact numbers with SkoolKit's simulator); the
# 48K ROM comes from the unreal-ng submodule (ROM48 overrides it).
#
# The edition's image is Nether Earth's own source (../nether-earth/src, read only, assembled here into
# build/edition/) plus src/edition/edition.asm; the saved games are src/res/levels/*.txt (tools/levels.py).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
ne=$(cd "$here/../nether-earth" && pwd)
asm=${1:-${SJASMPLUS:-sjasmplus}}
py=${2:-${PYTHON:-python3}}
rom=${ROM48:-$here/../../unreal-ng/data/rom/48.rom}
out="$here/build/edition"
mkdir -p "$out/levels" "$out/orig"
cd "$out"
# Nether Earth's image $5B00-$FCE8 and its loader N1, from its sources (written into this folder only)
python3 "$ne/tools/res_formats.py" build --out "$out/res" > /dev/null
"$asm" --nologo --msg=war -I"$out" -I"$ne/src/game" --lst=game.lst "$ne/src/game/game.asm"
"$asm" --nologo --msg=war --lst=loader.lst "$ne/src/loader.asm"
cp "$rom" 48.rom
"$asm" --nologo --msg=war -I"$out" --lst=edition.lst "$here/src/edition/edition.asm"
# The tape's blocks, as data without flag and checksum (TAP numbering: the TZX text blocks not counted)
python3 "$here/tools/tzx_blocks.py" "$here/orig/NETHER.TZX" orig/nether.tap > /dev/null
k=0
for name in basic block2 block3 block4 block5; do
    k=$((k + 1))
    python3 "$here/../../kit/tapblocks.py" orig/nether.tap $k orig/$name.bin
    cmp $name.bin orig/$name.bin && echo "edition $name.bin: identical"
done
python3 "$here/tools/levels.py" check orig/nether.tap "$here/src/res/levels"
for f in "$here"/src/res/levels/*.txt; do
    python3 "$here/tools/levels.py" build "$f" "levels/$(basename "$f" .txt).bin"
done
# The editor: nee.mix from src/mix and its PNG resources, the REM code of nee.bas, the two BASIC programs
ed="$out/editor"
mkdir -p "$ed"
python3 "$here/tools/mix_res.py" build "$ed" > /dev/null
(cd "$ed" && "$asm" --nologo --msg=war -I"$ed" -I"$here/src/mix" "$here/src/mix/game.asm" \
    && "$asm" --nologo --msg=war "$here/src/basic/nee-rem.asm")
"$py" "$here/tools/zxbasic.py" build -I "$ed" "$here/src/basic/ne-editor.bas" "$ed/ne-editor.bin"
"$py" "$here/tools/zxbasic.py" build -I "$ed" "$here/src/basic/nee.bas" "$ed/nee.bin"
cat > nether.manifest <<MANIFEST
text Nether Earth (game)
header 1000 program NetherEart 146 20
data 1000 0xFF basic.bin
data 1000 0xFF block2.bin
data 1000 0xFF block3.bin
data 1000 0xFF block4.bin
data 0 0xFF block5.bin
text Levels by V.O.software (loading as "saved game")
MANIFEST
n=0
for s in enemy-at-the-gates:Enemy_At_The_Gates break-through:Break_Through fortifications:Fortifications \
         the-chase:The_Chase jungle-of-stone:Jungle_Of_Stone double-frontline:Double_Frontline the-slogan:The_Slogan; do
    n=$((n + 1)); pause=1000; [ $n = 7 ] && pause=0
    echo "text $(echo ${s#*:} | tr _ ' ')" >> nether.manifest
    echo "data 1000 0x00 levels/${s%%:*}.sum" >> nether.manifest
    echo "data $pause 0x00 levels/${s%%:*}.bin" >> nether.manifest
done
cat >> nether.manifest <<MANIFEST
text Nether Earth Editor by V.O.software
header 1000 program NE_Editor_ 221 1
data 1000 0xFF editor/ne-editor.bin
header 1000 bytes nee.mix 2244 50000
data 1000 0xFF editor/game.bin
header 1000 program nee.bas 13625 1
data 1000 0xFF editor/nee.bin
data 1000 0x00 levels/editor-save.sum
data 0 0x00 levels/editor-save.bin
MANIFEST
python3 "$here/tools/tzx.py" nether.manifest NETHER.TZX
cmp NETHER.TZX "$here/orig/NETHER.TZX" && echo "build/edition/NETHER.TZX: identical to orig/NETHER.TZX"
