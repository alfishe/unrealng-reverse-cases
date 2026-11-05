#!/bin/sh
# Build the '99 game block, the patches block and the twelve maps from their sources and compare each with the
# disk's bytes, byte for byte.
#
#   tools/build_game99.sh [SJASMPLUS]
#
# - The resources (src/res/game99, tools/game99_res.py) into build/game99/res; the maps (src/res/maps,
#   tools/zs_level.py) into build/maps/NELEV_00.N .. NELEV_11.N (512 bytes each), the built-in level into
#   build/game99/res/maps/builtin.bin.
# - src/game99/game.asm (tools/game99_mkgame.py from src/game99/game.ann) into build/game99/game-6780.bin, the game
#   block as it unpacks ($6780-$D7D2, 28755 bytes).
# - src/patches99/patches.asm (from src/patches99/patches.ann) into build/game99/patches-d800.bin, the patches block
#   as it unpacks ($D800-$DB6F, 880 bytes: eight pieces, each assembled at the address it runs at).
# The check reads orig/NEZSED.ZIP (tools/game99_image.py, tools/zs_media.py). src/disk99.txt packs the two blocks
# and lays the maps on the disk.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/game99"
m="$here/build/maps"
mkdir -p "$b" "$m"
rm -rf "$b/res" "$b/game.bin" "$b/patches.bin" "$b/game-6780.bin" "$b/patches-d800.bin" "$m"/NELEV_*.N
python3 "$here/tools/game99_res.py" build --out "$b/res" >/dev/null
python3 "$here/tools/zs_level.py" build --out "$m" >/dev/null
mkdir -p "$b/res/maps"
mv "$m/builtin.bin" "$b/res/maps/builtin.bin"
cd "$b"
"$asm" --nologo --msg=war -I"$b" -I"$here/src/game99" --lst=game.lst "$here/src/game99/game.asm"
mv game.bin game-6780.bin
"$asm" --nologo --msg=war -I"$here/src/patches99" --lst=patches.lst "$here/src/patches99/patches.asm"
mv patches.bin patches-d800.bin
python3 - "$here" <<'PY'
import os
import sys
here = sys.argv[1]
sys.path.insert(0, here + '/tools')
import game99_image
import zs_media
game, patches = game99_image.blocks()
bad = 0


def check(path, want, what, base=0):
    global bad
    built = open(path, 'rb').read()
    if built != want:
        at = next(i for i in range(max(len(built), len(want)))
                  if i >= len(built) or i >= len(want) or built[i] != want[i])
        print('build: %s differs from %s at $%04X' % (os.path.relpath(path, here), what, base + at))
        bad += 1
        return
    print('build: %s identical to %s (%d bytes)' % (os.path.relpath(path, here), what, len(want)))


check(here + '/build/game99/game-6780.bin', game, "the game block's output", game99_image.GAME_LO)
check(here + '/build/game99/patches-d800.bin', patches, "the patches block's output", game99_image.PATCH_LO)
files, _ = zs_media.scl_files(zs_media.scl_from_zip(zs_media.ZIP99))
maps = {f['name'].strip(): f['body'] for f in files if f['type'] == 'N'}
built = sorted(n[:-2] for n in os.listdir(here + '/build/maps') if n.endswith('.N'))
if built != sorted(maps):
    print('build: build/maps holds %s, the disk %s' % (built, sorted(maps)))
    bad += 1
for name in sorted(maps):
    check(here + '/build/maps/%s.N' % name, maps[name], 'the disk\'s %s.N' % name)
sys.exit(1 if bad else 0)
PY
