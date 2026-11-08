#!/usr/bin/env python3
"""The load's claims of docs/03-build-and-load.md, checked against the recording from power-on (c1).

    python3 tools/check_load.py --work work/c1

Reads the recording's memory at each stage's entry (re_session.py stages gives the moments) and compares it with
the static decode of the tape: the decrypted loader, the picy block, the unpacked loading screen, the code file as
loaded, the moved game image.
"""
import argparse

import picy
import exlib as X
import image
import xorchain


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--loader-entry', default='251:4431')
    p.add_argument('--picy-entry', default='1808:61301')
    p.add_argument('--stub-entry', default='12364:38072')
    p.add_argument('--game-entry', default='12376:62848')
    args = p.parse_args()
    s = X.session(args.work)
    blk = {k: b['data'][1:-1] for k, b in enumerate(image.blocks()) if 'data' in b}
    mom = lambda t: tuple(int(x) for x in t.split(':'))  # noqa: E731

    def report(what, f, t, lo, want):
        got = X.read(s, f, lo, len(want), t)
        diff = [i for i in range(len(want)) if got[i] != want[i]]
        print(f'{what} at {f}:{t}: {len(diff)} of {len(want)} bytes differ'
              + (f' (first ${lo + diff[0]:04X}, last ${lo + diff[-1]:04X})' if diff else ''))

    f, t = mom(args.loader_entry)
    report('decrypted loader $FC00 ($FC13 entered)', f, t, 0xFC00, xorchain.decrypt(blk[4]))
    f, t = mom(args.picy_entry)
    report('picy $8000 ($8001 entered)', f, t, 0x8000, blk[6])
    scr, _ = picy.unpack(blk[6])
    f, t = mom(args.stub_entry)
    report('screen $4000 ($5B00 entered)', f, t, 0x4000, scr)
    report('code $6590 ($5B00 entered)', f, t, 0x6590, blk[8])
    f, t = mom(args.game_entry)
    report('game $6D60 ($6D60 entered)', f, t, 0x6D60, image.image()[0x6D60:])


if __name__ == '__main__':
    main()
