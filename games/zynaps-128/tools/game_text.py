#!/usr/bin/env python3
"""The texts of Zynaps 2 in 1 as UTF-8: every run of printable ASCII (2 characters or more) in a range of a
64 K image, with its address; the bytes between runs (print control codes: position, colour) as hex.

    python3 tools/game_text.py IMAGE [--from 83B0] [--to 8516] [--markdown]

Stage 1: the control codes are shown, not decoded (the print routine is stage 3's).
"""
import argparse
import re


def main():
    p = argparse.ArgumentParser()
    p.add_argument('image')
    p.add_argument('--from', dest='lo', default='83B0')
    p.add_argument('--to', dest='hi', default='8516')
    p.add_argument('--markdown', action='store_true')
    a = p.parse_args()
    img = open(a.image, 'rb').read()
    lo, hi = int(a.lo, 16), int(a.hi, 16)
    pos = lo
    rows = []
    for m in re.finditer(rb'[ -~]{2,}', img[lo:hi]):
        s, e = lo + m.start(), lo + m.end()
        rows.append((pos, img[pos:s].hex(' '), s, m.group().decode('ascii')))
        pos = e
    rows.append((pos, img[pos:hi].hex(' '), hi, ''))
    if a.markdown:
        print('| Address | Text | Control bytes before it |')
        print('| --- | --- | --- |')
        for _, ctl, s, t in rows:
            if t:
                print(f'| `{s:04X}` | `{t}` | `{ctl}` |' if ctl else f'| `{s:04X}` | `{t}` | |')
    else:
        for _, ctl, s, t in rows:
            print(f'{s:04X}  [{ctl}]  {t}')


if __name__ == '__main__':
    main()
