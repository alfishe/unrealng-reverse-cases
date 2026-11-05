#!/bin/sh
# Regenerate src/**/*.asm from their .ann files (tools/part_mkasm.py), each checked to assemble to the original's
# bytes before it is installed. Run after editing an .ann; the build (tools/build.sh) needs only the .asm files.
#
#   tools/mkasm_all.sh
#
# Needs work/parts/ (tools/parts.py) and the analysis builds' L1 files in work/stage2/*/l1.json (WALKTHROUGH.md):
# without an L1 file a part's code comes from mkgame's static walk alone. The sound parts (src/sound/*.ann) come
# first: tools/build_sound.sh builds the song and the engine data they include.
set -eu
cd "$(dirname "$0")/.."
python3 tools/parts.py > /dev/null
l1() { for s in "$@"; do [ -f work/stage2/$s/l1.json ] && printf -- '--l1 work/stage2/%s/l1.json ' "$s"; done; return 0; }
gen() { python3 tools/part_mkasm.py --res src/res --install "$@" | tail -1; }

sh tools/build_sound.sh > /dev/null
gen --image work/parts/starkos-8000.bin --org '$8000' --ann src/sound/starkos.ann --top starkos --dest src/sound \
    $(l1 intro) --title 'The STarKos player and the intro tune SK10' --out work/stage2/sound/mk/starkos \
    --built music/sk10.bin=build/sound/sk10.bin --save build/sound/starkos-8000.bin
gen --image work/parts/engine-c968.bin --org '$C968' --ann src/sound/engine.ann --top engine --dest src/sound \
    $(l1 game) --title 'The page-4 sound engine of the 128K game' --out work/stage2/sound/mk/engine \
    --save build/sound/engine-c968.bin
gen --image work/parts/loader-5d3b.bin --org '$5D3B' --ann src/loader/loader.ann --top zynapsb --dest src/loader \
    $(l1 loader) --title 'Zynaps 2 in 1: ZYNAPS.B sector 0, the BASIC with the REM loader ($5D3B)' \
    --save build/obj/zynapsb-basic.bin
gen --image work/parts/depacker-5b00.bin --org '$5B00' --ann src/loader/depacker.ann --top depacker --dest src/loader \
    $(l1 loader load2) --title 'Zynaps 2 in 1: ZYNAPS.B sector 1, the Hrust 1 depacker ($5B00)' \
    --save build/obj/depacker.bin
gen --image work/parts/intro-6000.bin --org '$6000' --ann src/intro/intro.ann --top block1 --dest src/intro \
    $(l1 intro) --title 'Zynaps 2 in 1: block 1, the intro ($6000-$E8D4)' \
    --built sound/engine-c968.bin=sound/engine-c968.bin --built sound/engine-data-de48.bin=sound/engine-data-de48.bin \
    --built sound/starkos-8000.bin=sound/starkos-8000.bin --built screens/title.scr=screens/title.scr \
    --built screens/options.scr=screens/options.scr --built screens/hewson.scr=screens/hewson.scr \
    --save build/obj/block1.bin
gen --image work/parts/stubs-b30d.bin --org '$B30D' --ann src/game/stubs.ann --top hooks --dest src/game \
    $(l1 game) --title 'Zynaps 2 in 1: the 128K hook stubs ($B30D)' --save build/obj/stubs-b30d.bin
gen --image work/parts/glue-5b00.bin --org '$5B00' --ann src/game/glue.ann --top glue128 --dest src/game \
    $(l1 glue game) --title 'Zynaps 2 in 1: the 128K glue ($5B00)' --save build/obj/glue-5b00.bin
gen --image work/parts/mouse-fe00.bin --org '$FE00' --ann src/game/mouse.ann --top kmouse --dest src/game \
    --title 'Zynaps 2 in 1: the Kempston mouse driver ($FE00)' --save build/obj/mouse-fe00.bin
# block 2 includes the game as tools/build.sh assembles it (src/game/game.asm, tools/mkgame.sh's)
python3 tools/res_formats.py build --out build > /dev/null
mkdir -p build/obj
(cd build/obj && "${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}" --nologo \
    --msg=war -I.. -I../../src/game ../../src/game/game.asm)
gen --image work/parts/game-6000.bin --org '$6000' --ann src/game/setup.ann --top block2 --dest src/game \
    $(l1 load2 glue) --title 'Zynaps 2 in 1: block 2, the game and its 128K layer ($6000-$FB84)' \
    --built game/stubs-b30d.bin=obj/stubs-b30d.bin --built game/glue-5b00.bin=obj/glue-5b00.bin \
    --built game/mouse-fe00.bin=obj/mouse-fe00.bin \
    --built game/game-6800.bin=obj/game.bin --save build/obj/block2.bin
gen --image work/parts/boot-5d3b.bin --org '$5D3B' --ann src/boot/boot.ann --top bootb --dest src/boot \
    $(l1 boot) --title "Zynaps 2 in 1: the TRD's boot.B (\$5D3B)" --save build/obj/boot-5d3b.bin
