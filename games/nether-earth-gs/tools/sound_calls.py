#!/usr/bin/env python3
"""Every call of the sound in the GS game image: CALL Beep ($CCAC), CALL GsSound ($A583), CALL GsMenuSound ($A569),
with the sound id loaded into A before it (LD A,n within the 6 bytes before the CALL), the NE entry that holds the
call (NE's game.ann) and the GS effect the driver in bank 1 ($C000, neart021) maps the id to.

  sound_calls.py IMAGE64K DRIVER.bin [--ann NE/src/game/game.ann]
"""
import argparse, os, re
HERE = os.path.dirname(os.path.abspath(__file__))
NE = os.path.join(HERE, '..', '..', 'nether-earth')
ap = argparse.ArgumentParser()
ap.add_argument('image'); ap.add_argument('driver')
ap.add_argument('--ann', default=os.path.join(NE, 'src', 'game', 'game.ann'))
a = ap.parse_args()
m = open(a.image, 'rb').read(); drv = open(a.driver, 'rb').read()
ents = []
for line in open(a.ann, encoding='utf-8'):
    g = re.match(r'\$([0-9A-F]{4}) ([cbwts]) (\w+)', line)
    if g: ents.append((int(g[1], 16), g[3]))
ents.sort()
def owner(x):
    best = None
    for s, n in ents:
        if s <= x: best = (s, n)
        else: break
    return f'{best[1]}+${x - best[0]:X}' if best else '?'
# the driver: CP n / JR NZ / (LD A,f / JP play) or (JP random-of-three)
fx = {}
p = 0
while p < len(drv) - 4 and drv[p] == 0xFE:
    n = drv[p + 1]; q = p + 4
    if n in fx:  # a second compare for the same id is never reached
        fx[n + 0x1000] = 'unreachable duplicate'
    if drv[q] == 0x3E: fx.setdefault(n, f'FX {drv[q + 1]}'); p = q + 5
    elif drv[q] == 0xC3:
        t = drv[q + 1] | drv[q + 2] << 8
        # a random pick: three LD A,f before JP play at the targets $C099/$C09E/$C0A3 (or $C0D8...)
        o = t - 0xC000
        picks = [drv[i + 1] for i in range(o, len(drv) - 1) if drv[i] == 0x3E and drv[i + 2] == 0xC3][:3]
        fx.setdefault(n, 'FX ' + '/'.join(map(str, picks)) + ' (R register pick)'); p = q + 3
    else: break
print('# driver ids:', ', '.join(f'${k:02X}->{v}' for k, v in sorted(fx.items()) if k < 0x1000))
targets = {0xCCAC: 'Beep', 0xA583: 'GsSound', 0xA569: 'GsMenuSound'}
for x in range(0x6590, 0xFFFD):
    if m[x] in (0xCD, 0xC3) and (m[x + 1] | m[x + 2] << 8) in targets:
        t = m[x + 1] | m[x + 2] << 8
        aval = None
        for b in range(x - 2, x - 9, -1):
            if m[b] == 0x3E: aval = m[b + 1]; break
        if t == 0xA569: aval = 3
        sid = f'${aval:02X}' if aval is not None else '?'
        print(f'${x:04X} {owner(x):28} {"CALL" if m[x] == 0xCD else "JP  "} {targets[t]:12} A={sid:4} -> '
              f'{fx.get(aval, "no id: silent") if aval is not None else "?"}')
