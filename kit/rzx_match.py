#!/usr/bin/env python3
"""How long a recording made from an RZX state keeps to the RZX: each saved screen of the recording
(re_session.py's W/screens/NNNNNN.scr, after NNNNNN frames) against the RZX log's screen after FROM + NNNNNN frames
(a case's rzx_log.py: LOG/screens.bin, 6912 bytes a sample, one every LOG/log.json "every" frames).

    python3 kit/rzx_match.py LOG FROM REC [--bytes N] [--attrs N] [--window F] [--room ADDR]

Per screen: the bytes that differ (pixels and attributes apart). Exact is 0 bytes. A game that is not frame-locked,
replayed from the RZX's keys held per frame, drifts by a pass now and then: the sprites stand a few pixels apart and
a room changes a sample earlier or later, while the run follows the RZX room by room. The tolerance says so:

  --bytes N    a screen within N differing bytes (pixels and attributes) is in step (sprites a few pixels apart:
               a few hundred bytes; Rex 1500)
  --attrs N    and within N differing attribute bytes (the same room: a new room's colours differ in hundreds;
               default: no attribute limit of its own)
  --window F   compare with every RZX screen from F frames before to F frames after and take the closest (a room
               change a sample early or late; a multiple of the log's "every")
  --room ADDR  the game's room byte (hex; Rex $A0B8): at each frame where the recording saved its memory
               (W/snapshots/NNNNNN/ram-B.bin: $4000 bank 5, $8000 bank 2, $C000 bank 0, so a 128K game's byte under
               $C000) and the RZX log has a memory sample (LOG/mem.bin, the 64 K every log.json "mem" frames), the
               two must hold the same room; a screen of another room is out of step whatever its bytes. With
               --window F the RZX's rooms at its memory samples within F frames either side count too (F of the
               log's "mem" or more: a room change a sample early or late). The rooms are printed ("room 15/15":
               the recording's, the RZX's at the frame)

Prints a line a screen, then "in step with the RZX up to frame N" (exact: every screen from the first up to N differs
in 0 bytes) and, with a tolerance, "in step by the tolerance (...) up to frame N; K of M screens" (every screen from
the first up to N within it; K of the M compared). The measures combine: all given must hold; --window with no
--bytes, --attrs or --room is exact within the window; --room with no --bytes or --attrs asks the room alone. With
none of them it is the exact count alone, as the cases' copies printed it.
"""
import argparse
import json
import os

PIXELS = 6144


def differ(a, b):
    """(pixel bytes, attribute bytes) that differ"""
    pix = sum(1 for x, y in zip(a[:PIXELS], b[:PIXELS]) if x != y)
    att = sum(1 for x, y in zip(a[PIXELS:6912], b[PIXELS:6912]) if x != y)
    return pix, att


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('log', help='the RZX log folder (screens.bin, log.json)')
    ap.add_argument('start', type=int, help='the RZX frame the recording starts from')
    ap.add_argument('rec', help='the recording (W, with screens/NNNNNN.scr)')
    ap.add_argument('--bytes', type=int, default=None, help='in step within N differing bytes')
    ap.add_argument('--attrs', type=int, default=None, help='and within N differing attribute bytes')
    ap.add_argument('--window', type=int, default=0, help='the closest RZX screen within F frames either side')
    ap.add_argument('--room', type=lambda x: int(x.lstrip('$'), 16), default=None,
                    help='hex address of the room byte: the recording and the RZX must be in the same room')
    a = ap.parse_args()
    if a.room is not None and not 0x4000 <= a.room <= 0xFFFF:
        ap.error('--room: an address in $4000-$FFFF')
    every = json.load(open(os.path.join(a.log, 'log.json')))['every']
    s = open(os.path.join(a.log, 'screens.bin'), 'rb').read()
    count = len(s) // 6912
    tolerant = a.bytes is not None or a.attrs is not None or a.window or a.room is not None
    mem = mem_every = None
    if a.room is not None:
        mem_every = json.load(open(os.path.join(a.log, 'log.json'))).get('mem')
        path = os.path.join(a.log, 'mem.bin')
        mem = open(path, 'rb').read() if mem_every and os.path.isfile(path) else None
        if mem is None:
            ap.error(f'--room: no {path} with log.json "mem"')

    def rooms(n):
        """(the recording's room, the RZX's at the frame, the RZX's within --window) at frame n, or None where either
        has no memory there"""
        bank, off = {0x4000: (5, 0x4000), 0x8000: (2, 0x8000), 0xC000: (0, 0xC000)}[a.room & 0xC000]
        path = os.path.join(a.rec, 'snapshots', f'{n:06d}', f'ram-{bank}.bin')
        at = a.start + n
        if at % mem_every or not os.path.isfile(path) or (at // mem_every + 1) * 0x10000 > len(mem):
            return None
        with open(path, 'rb') as f:
            f.seek(a.room - off)
            ours = f.read(1)[0]
        k = at // mem_every
        near = {mem[j * 0x10000 + a.room] for j in range(k - a.window // mem_every, k + a.window // mem_every + 1)
                if 0 <= j < len(mem) // 0x10000}
        return ours, mem[k * 0x10000 + a.room], near
    limit = a.bytes if a.bytes is not None else (0 if a.room is None and a.attrs is None else None)
    exact, loose, chain_exact, chain_loose, inside, total = 0, 0, True, True, 0, 0
    for f in sorted(os.listdir(os.path.join(a.rec, 'screens'))):
        if not f.endswith('.scr'):
            continue
        n = int(f[:-4])
        at = a.start + n
        if at % every or at // every >= count:
            continue
        ours = open(os.path.join(a.rec, 'screens', f), 'rb').read()
        i = at // every
        pix, att = differ(ours, s[i * 6912:(i + 1) * 6912])
        d = pix + att
        line = f'frame {n}: {d} bytes differ'
        chain_exact = chain_exact and d == 0
        if chain_exact:
            exact = n
        if tolerant:
            best = (d, pix, att, 0)
            steps = a.window // every
            for k in range(-steps, steps + 1):
                j = i + k
                if k == 0 or not 0 <= j < count:
                    continue
                p2, a2 = differ(ours, s[j * 6912:(j + 1) * 6912])
                if p2 + a2 < best[0]:
                    best = (p2 + a2, p2, a2, k * every)
            ok = (limit is None or best[0] <= limit) and (a.attrs is None or best[2] <= a.attrs)
            line += f' (pixels {pix}, attributes {att})'
            if a.window:
                line += f'; closest within {a.window} frames: {best[0]} ({best[1]} + {best[2]}) at {best[3]:+d}'
            if a.room is not None:
                r = rooms(n)
                line += f'; room {r[0]}/{r[1]}' if r else '; room not sampled'
                ok = ok and (r is None or r[0] in r[2])
            line += '; in step' if ok else '; out of step'
            total += 1
            inside += ok
            chain_loose = chain_loose and ok
            if chain_loose:
                loose = n
        print(line)
    print(f'in step with the RZX up to frame {exact}')
    if tolerant:
        what = ', '.join(x for x in (f'{a.bytes} bytes' if a.bytes is not None else '',
                                     f'{a.attrs} attribute bytes' if a.attrs is not None else '',
                                     f'{a.window} frames either side' if a.window else '',
                                     f'the room byte ${a.room:04X}' if a.room is not None else '') if x)
        print(f'in step by the tolerance ({what}) up to frame {loose}; {inside} of {total} screens')


if __name__ == '__main__':
    main()
