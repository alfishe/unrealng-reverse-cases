#!/usr/bin/env python3
"""The ports a recording's code used: from an L1 (l1.json), every routine's ports_in / ports_out, summed by port,
with the routines that use each and how many distinct port values each used (the profile lists values, not
access counts). Answers "does the game write the AY (`$FFFD`, `$BFFD`), the 128K
paging (`$7FFD`), the beeper (`$FE`)" for one recording.

    python3 tools/l1_ports.py work/stage1/rec/m128/l1.json [--min-entry 6000]

--min-entry skips routines whose entry is below the address (the ROM and the loader's printer-buffer code).
"""
import argparse
import json
from collections import defaultdict


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('l1')
    ap.add_argument('--min-entry', default='0')
    a = ap.parse_args()
    lo = int(a.min_entry, 16)
    d = json.load(open(a.l1))
    use = defaultdict(lambda: defaultdict(int))
    for r in d['routines']:
        if int(r['entry'][1:], 16) < lo:
            continue
        prof = r.get('profile', {})
        for kind in ('ports_in', 'ports_out'):
            for p in prof.get(kind, []):
                v = int(p[1:], 16)
                # the Spectrum decodes: even = ULA ($FE); $FFFD / $BFFD AY; $7FFD paging; $1F Kempston
                if v & 1 == 0:
                    name = '$xxFE (ULA)'
                elif v & 0xC002 == 0xC000:
                    name = '$FFFD (AY select)'
                elif v & 0xC002 == 0x8000:
                    name = '$BFFD (AY data)'
                elif v & 0x8002 == 0:
                    name = '$7FFD (paging)'
                else:
                    name = p
                use[(kind, name)][r['entry']] += 1
    for (kind, port), rs in sorted(use.items()):
        tot = sum(rs.values())
        top = ', '.join(f'{e} x{n}' for e, n in sorted(rs.items(), key=lambda x: -x[1])[:6])
        print(f'{kind:9s} {port:>18}: {len(rs):3d} routines  {top}')


if __name__ == '__main__':
    main()
