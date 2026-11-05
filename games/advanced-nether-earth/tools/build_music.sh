#!/bin/sh
# The music part from source: the players (src/music/stp-player.asm, src/music/pt3-player.asm), the tunes
# (src/res/music/*.pt2 / *.pt3), bank 1's title cards (src/music/title-cards.asm, src/res/music/title-*.png), into
# build/music/, each output checked byte for byte against the bytes it replaces.
#
#   tools/build_music.sh [SJASMPLUS]          (from any folder; writes only build/music/)
#
# | Output (build/music/)        | Source                      | Replaces                                          |
# | ---------------------------- | --------------------------- | ------------------------------------------------- |
# | music-c000-bank1.bin         | src/music/music-bank1.asm   | src/res/img/music-c000-bank1.bin (all of it)      |
# | d04-c000-bank1.bin           | src/music/boot-music.asm    | src/res/img/d04-c000-bank1.bin (all of it)        |
# | dead-end-music-c000.bin      | src/music/dead-end-music.asm| dead-end-c000-bank3.bin $C000-$D2EE (aneE's image)|
# | intro-music-7d2d.bin         | src/music/intro-music.asm   | intro-6600.bin $7D2D-$A3AC (aneI's image)         |
# | final-cut-music-8bf5.bin     | src/music/final-cut-music.asm | final-cut-6060.bin $8BF5-$A66C (aneE's image)   |
#
# The Pro Tracker 2 tunes are compiled for $CA45 first (build/music/tunes/, tools/music_ptmodule.py build); the
# Pro Tracker 3 tunes are INCBINed as they are (the player relocates them at its init).
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
asm=${1:-${SJASMPLUS:-/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus}}
b="$here/build/music"
rm -rf "$b"
mkdir -p "$b/tunes"
cd "$here"
for t in taiga mad-night nether-earth-end; do
    python3 tools/music_ptmodule.py build "src/res/music/$t.pt2" CA45 "$b/tunes/$t.bin"
done
python3 tools/music_res.py build --out "$b/res"
for s in music-bank1 boot-music dead-end-music intro-music final-cut-music; do
    "$asm" --nologo --msg=war -I"$here" --lst="$b/$s.lst" "src/music/$s.asm"
done
python3 - "$here" <<'PY'
import sys
here = sys.argv[1]
def check(out, raw, base, start, end=None, tail=b''):
    built = open(f'{here}/build/music/{out}', 'rb').read()
    try:
        have = open(f'{here}/src/res/img/{raw}', 'rb').read()
    except FileNotFoundError:  # the raw image is gone once its part is wired into tools/build.sh
        print(f'music: {out} built ({len(built)} bytes; {raw} replaced, the SCL compare checks it)')
        return
    end = base + len(have) if end is None else end + 1
    have = have[start - base:end - base]
    assert built == have, f'{out}: differs from {raw} ${start:04X}-${end - 1:04X}'
    print(f'music: {out} identical ({raw} ${start:04X}-${end - 1:04X}, {len(built)} bytes)')
check('music-c000-bank1.bin', 'music-c000-bank1.bin', 0xC000, 0xC000)
check('d04-c000-bank1.bin', 'd04-c000-bank1.bin', 0xC000, 0xC000)
check('dead-end-music-c000.bin', 'dead-end-c000-bank3.bin', 0xC000, 0xC000, 0xD2EE)
check('intro-music-7d2d.bin', 'intro-6600.bin', 0x6600, 0x7D2D, 0xA3AC)
check('final-cut-music-8bf5.bin', 'final-cut-6060.bin', 0x6060, 0x8BF5, 0xA66C)
# the intro's LDIR copies one byte more than the image holds: the tune's last byte, 0 (RAM cleared by the 128 ROM)
full = open(f'{here}/build/music/intro-music-bank6.bin', 'rb').read()
assert len(full) == 0x2681 and full[-1] == 0, 'the intro copy: not $2681 bytes ending in 0'
print('music: intro-music-bank6.bin = the image bytes + the 0 the LDIR takes from $A3AD')
PY
