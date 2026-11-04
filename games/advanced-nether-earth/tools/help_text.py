#!/usr/bin/env python3
"""The help and credits texts of Advanced Nether Earth (1998), out of RAM page dumps, decoded to Cyrillic.

  help_text.py PREFIX [--out FILE]

PREFIX-bankN.bin are the 16 K RAM pages with the help program loaded (drive.py pages:PREFIX at the help menu).
The texts are runs of printable ASCII, 33 characters a line, pages separated by one control byte. The game writes
Russian in the ZX "Latin-for-Cyrillic" convention (KOI-7 N2-like, the font draws the Cyrillic letters): a=а b=б
c=ц d=д e=е f=ф g=г h=х i=и j=й k=к l=л m=м n=н o=о p=п q=я r=р s=с t=т u=у v=ж w=в x=ь y=ы z=з, and [=ш ]=щ
^=ч @=ю _=ъ <=э, capitals {=Ш }=Щ ~=Ч |=Э, upper-case Latin = upper-case Cyrillic. Prints each run: the page,
the offset, the raw text and the decoded text.
"""

import argparse
import re

LOWER = dict(zip('abcdefghijklmnopqrstuvwxyz', 'абцдефгхийклмнопярстужвьыз'))
SPECIAL = {'[': 'ш', ']': 'щ', '^': 'ч', '@': 'ю', '_': 'ъ', '<': 'э', '{': 'Ш', '}': 'Щ', '~': 'Ч', '|': 'Э'}
WIDTH = 33


def decode(text):
    out = []
    for ch in text:
        if ch in SPECIAL:
            out.append(SPECIAL[ch])
        elif ch.islower() and ch in LOWER:
            out.append(LOWER[ch])
        elif ch.isupper() and ch.lower() in LOWER:
            out.append(LOWER[ch.lower()].upper())
        else:
            out.append(ch)
    return ''.join(out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('prefix')
    p.add_argument('--banks', default='0,2')
    p.add_argument('--out')
    args = p.parse_args()
    lines = []
    for n in (int(b) for b in args.banks.split(',')):
        data = open(f'{args.prefix}-bank{n}.bin', 'rb').read()
        for m in re.finditer(rb'[\x20-\x7e]{40,}', data):
            raw = m.group().decode('ascii')
            lines.append(f'## page {n} +${m.start():04X}-${m.end() - 1:04X} ({len(raw)} bytes)\n')
            rows = [raw[i:i + WIDTH] for i in range(0, len(raw), WIDTH)]
            lines.append('```text\n' + '\n'.join(r.rstrip() for r in rows) + '\n```\n')
            lines.append('```text\n' + '\n'.join(decode(r).rstrip() for r in rows) + '\n```\n')
    text = '\n'.join(lines)
    if args.out:
        open(args.out, 'w').write(text)
    else:
        print(text)


if __name__ == '__main__':
    main()
