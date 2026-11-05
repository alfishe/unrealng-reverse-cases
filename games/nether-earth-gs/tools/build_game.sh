#!/bin/sh
# The game image from source: the modules src/game/*.asm (written by tools/game_mkgame.py from src/game/game.ann)
# and the resources src/res/game (tools/res_formats.py), assembled twice into build/game/ and each checked byte for
# byte against the file neart001 of its medium (tools/game_image.py).
#
#   tools/build_game.sh [SJASMPLUS]          (from any folder; writes only build/game/)
#
# | Output (build/game/) | Assembled                    | Compared with                  |
# | -------------------- | ---------------------------- | ------------------------------ |
# | neart001-scl.bin     | src/game/game.asm            | neart001 of the SCL (and TRD)  |
# | neart001-tap.bin     | game.asm with -DHOOD_TAPE    | neart001 of Hood's tape (TAP) |
#
# The two differ in 4 bytes: DriverBank (the GS driver's RAM page, 1 / 6, in GsMenuSound and GsSound) and
# SaveBytesEntry (the ROM entry of the game's tape save, $04D0 / $04C2): case.json header, docs/03 3.5.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/game"
rm -rf "$b"
mkdir -p "$b"
cd "$here"
python3 tools/res_formats.py build --out "$b/res" >/dev/null
for target in scl tap; do
    def=
    [ $target = tap ] && def=-DHOOD_TAPE
    (cd "$b" && "$asm" --nologo --msg=war $def -I"$b" -I"$here/src/game" --lst=game-$target.lst \
        --sym=game-$target.sym "$here/src/game/game.asm")
    mv "$b/game.bin" "$b/neart001-$target.bin"
    python3 tools/game_image.py --medium $target --out "$b/ref-$target" >/dev/null
done
python3 - "$b" <<'PY'
import sys
b = sys.argv[1]
for target, medium in (('scl', 'the SCL'), ('tap', "Hood's tape")):
    built = open(f'{b}/neart001-{target}.bin', 'rb').read()
    orig = open(f'{b}/ref-{target}/original.bin', 'rb').read()[0x6590:]
    if built != orig:
        diff = [i for i in range(min(len(built), len(orig))) if built[i] != orig[i]]
        sys.exit(f'game: neart001-{target}.bin differs from neart001 of {medium}: {len(built)} / {len(orig)} bytes, '
                 f'{len(diff)} differ, the first at ${0x6590 + (diff[0] if diff else 0):04X}')
    print(f'game: neart001-{target}.bin identical to neart001 of {medium} ({len(built)} bytes, $6590-$FFFF)')
a = open(f'{b}/neart001-scl.bin', 'rb').read()
t = open(f'{b}/neart001-tap.bin', 'rb').read()
print('game: the two targets differ at ' + ', '.join(f'${0x6590 + i:04X}' for i in range(len(a)) if a[i] != t[i]))
PY
rm -rf "$b/ref-scl" "$b/ref-tap"
