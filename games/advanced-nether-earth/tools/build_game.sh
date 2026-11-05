#!/bin/sh
# The game image in play from source: the modules src/game/*.asm (written by tools/game_mkgame.py from
# src/game/game.ann) and the resources src/res/game (tools/game_res.py), into build/game/, checked byte for byte
# against the game block the SCL holds.
#
#   tools/build_game.sh [SJASMPLUS]          (from any folder; writes only build/game/)
#
# | Output (build/game/)  | Source                          |
# | --------------------- | ------------------------------- |
# | game-6731.bin         | src/game/game.asm, src/res/game |
#
# game.asm assembles $6731-$D7D2; the block's last 5 bytes ($D7D3-$D7D7, the first bytes of Shots, zero) are added
# here. The game's piece of bank 3 (the menu picture's code and stream, $E73B-$F1ED) is built with the bank 3 image
# by the endings part (src/endings/deadend/menupicture.asm). Reads nothing outside this case.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/game"
rm -rf "$b"
mkdir -p "$b"
cd "$here"
python3 tools/game_res.py build --out "$b/res/game" >/dev/null
(cd "$b" && "$asm" --nologo --msg=war -I"$b" -I"$here/src/game" --lst=game.lst --sym=game.sym \
    "$here/src/game/game.asm")
python3 - "$here" <<'PY'
import os
import subprocess
import sys
here = sys.argv[1]
b = f'{here}/build/game'
code = open(f'{b}/game.bin', 'rb').read()
assert len(code) == 0xD7D3 - 0x6731, f'game.bin: {len(code)} bytes, not $6731-$D7D2'
image = code + bytes(5)                       # $D7D3-$D7D7: the first 5 bytes of Shots, zero in the block
open(f'{b}/game-6731.bin', 'wb').write(image)
os.remove(f'{b}/game.bin')
ref = f'{b}/ref'
subprocess.run([sys.executable, f'{here}/tools/game_image.py', '--out', ref], check=True)
orig = open(f'{ref}/original.bin', 'rb').read()[0x6731:0xD7D8]
assert image == orig, 'game-6731.bin differs from the game block of the SCL'
print(f'game: game-6731.bin identical (the SCL\'s game block $6731-$D7D7, {len(image)} bytes)')
PY
rm -rf "$b/ref"
