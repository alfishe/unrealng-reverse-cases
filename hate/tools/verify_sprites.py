#!/usr/bin/env python3
"""The sprite and explosion graphics of src/res against the bot's recording (work/p2; docs/06-rendering.md 6.6).

1. The graphics: each `src/res/gfx/{sprites,explosions}/slot-NN.bin` equals the recording's memory at the address the
   pointer table `$C300` + NN holds.
2. The drawing: for each pass picked, the moment `DrawSprites` (`$EAE3`) sets its list pointer `$DD68` to `$FF00`
   (after the shadows) is found to the T-state, and the end: the pointer on the `$FF` ending the list, the buffer
   then still for 2000 T. The sprite list `$FF00` (kind, strips, buffer address, sprite address; `$FF` ends it) is drawn from the files, as the
   routine does (AND mask, OR pixels; 21, 17 or 13 lines a strip, the next strip 2 rows of the buffer on less 4
   lines, wrapping in `$8000-$BFFF`), into the buffer of the first moment; the whole buffer must equal the second.
3. The frame rule: every sprite address is a block of the table plus whole frames (`$A8`, `$66`, `$34` bytes for
   kinds 0-3, 4-10, 11-13; an explosion block is one frame) plus whole strips, and the strips drawn fit the frame
   (frame 3 one strip short).

    python3 tools/verify_sprites.py [--frames 1000 5000 ...] [--scan FROM TO] [--unreal UNREAL_NG_CHECKOUT]

--scan reads the list at the start of every frame of a range and adds the first frames that show an explosion and
the largest list. Needs an unreal-ng instance with work/p2 open (re_session.py open).
"""
import argparse
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'src', 'res', 'gfx')
FRAME_T = 69888
LIST, LIST_PTR, SHADOW_PTR, SHADOWS = 0xFF00, 0xDD68, 0xDD66, 0xFE64
EXPLOSIONS = range(0x7C10, 0x8000)


def kind_shape(kind):
    """(lines a strip, bytes a frame, strips in frames 0-2)"""
    if kind < 4:
        return 21, 0xA8, 4
    if kind < 11:
        return 17, 0x66, 3
    return 13, 0x34, 2


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--frames', type=int, nargs='*', default=[1000, 5000, 9000])
    p.add_argument('--scan', type=int, nargs=2, metavar=('FROM', 'TO'))
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(os.path.join(ROOT, 'work', 'p2'))

    def read(T, offset, length):
        frame, t = divmod(T, FRAME_T)
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': t,
                                         'offset': offset, 'length': length}, ok=False)
        body = r.structured or {}
        if r.is_error or 'hex' not in body:
            raise SystemExit(f'memory_at {frame}:{t}: {r.text}')
        return bytes.fromhex(body['hex'])

    def word(T, address):
        b = read(T, address, 2)
        return b[0] | b[1] << 8

    failures = 0
    # 1: the files against the memory the pointer table names
    table = read(args.frames[0] * FRAME_T, 0xC300, 0x30)
    blocks = {}  # address -> (file, bytes)
    for kind in ('sprites', 'explosions'):
        for name in sorted(os.listdir(os.path.join(RES, kind))):
            slot = int(name[5:7], 16)
            data = open(os.path.join(RES, kind, name), 'rb').read()
            address = table[slot] | table[slot + 1] << 8
            same = read(args.frames[0] * FRAME_T, address, len(data)) == data
            failures += not same
            blocks[address] = (f'{kind}/{name}', data)
            print(f'{kind}/{name}: ${address:04X}, {len(data)} bytes, {"equal" if same else "DIFFERENT"} in memory')

    frames = list(args.frames)
    if args.scan:
        biggest, explosion = None, None
        for f in range(*args.scan):
            entries = read(f * FRAME_T, LIST, 0x60)
            n = 0
            while n < 16 and entries[6 * n] != 0xFF:
                if explosion is None and (entries[6 * n + 4] | entries[6 * n + 5] << 8) in EXPLOSIONS:
                    explosion = f
                n += 1
            if n == 16:  # no $FF: not a list yet (before the game)
                continue
            if biggest is None or n > biggest[1]:
                biggest = (f, n)
        print(f'scan {args.scan[0]}-{args.scan[1]}: the longest list {biggest[1]} at frame {biggest[0]}, '
              f'the first explosion at frame {explosion}')
        frames += [x for x in (biggest[0], explosion) if x is not None and x not in frames]

    def edge(lo, hi, test):
        """the last T in [lo, hi) where test is false, test(hi) being true"""
        while hi - lo > 1:
            mid = (lo + hi) // 2
            lo, hi = (lo, mid) if test(mid) else (mid, hi)
        return lo

    exploded, used = 0, set()
    for f in frames:
        # 2: the moment DrawSprites starts, after the shadows: $DD68 written $FF00, $DD66 left past its list
        T, step, pre = f * FRAME_T, 500, None
        last = word(T, LIST_PTR)
        while T < (f + 8) * FRAME_T:
            T += step
            now = word(T, LIST_PTR)
            if now < last:  # set back to $FF00 (held for some 250 T only, so seen as the pointer going down)
                at = edge(T - step, T, lambda x, old=last: word(x, LIST_PTR) != old)
                if word(at + 100, SHADOW_PTR) != SHADOWS:  # a second walk of both lists sets $FE64 36 T after
                    pre = at
                    break
            last = now
        if pre is None:
            print(f'frame {f}: no sprite drawing found')
            failures += 1
            continue
        # the end: the list pointer on the $FF that ends the list, then the buffer unchanged for 2000 T (the blit
        # only reads it; the restore comes some 50 000 T later)
        T = pre + 1
        while read(T, word(T, LIST_PTR), 1)[0] != 0xFF:
            T += 100
        post = T
        while read(post, 0x8000, 0x4000) != read(post + 2000, 0x8000, 0x4000):
            post += 2000
        before = read(pre, 0x8000, 0x4000)
        buf = bytearray(before)
        after = read(post, 0x8000, 0x4000)
        entries = read(post, LIST, 0x100)
        n, written, bad_rule = 0, set(), []
        while entries[6 * n] != 0xFF:
            kind, strips = entries[6 * n], entries[6 * n + 1]
            de = entries[6 * n + 2] | entries[6 * n + 3] << 8
            hl = entries[6 * n + 4] | entries[6 * n + 5] << 8
            base = max(a for a in blocks if a <= hl)
            name, data = blocks[base]
            used.add(name)
            lines, size, full = kind_shape(kind)
            offset = hl - base
            if hl in EXPLOSIONS:
                exploded += 1
                frame_no, rest, room = 0, offset, 4
            else:
                frame_no, rest = divmod(offset, size)
                room = full - (frame_no == 3)
            skipped, part = divmod(rest, 2 * lines)
            if part or frame_no > 3 or skipped + strips > room or kind > 13:
                bad_rule.append((n, kind, strips, f'${hl:04X}', name, offset))
            g = offset
            for _ in range(strips):
                d = de
                for _ in range(lines):
                    a = d - 0x8000
                    buf[a] = (buf[a] & data[g]) | data[g + 1]
                    written.add(a)
                    g += 2
                    d = (d & 0xFF00) | ((d + 1) & 0xFF)
                de = ((de & 0xFF00) + 0x200) & 0xBFFF | 0x8000 | ((de - 4) & 0xFF)
            n += 1
        diff = [a for a in range(0x4000) if buf[a] != after[a]]
        changed = sum(before[a] != after[a] for a in range(0x4000))
        failures += len(diff) + len(bad_rule)
        print(f'frame {f}: drawn {pre // FRAME_T}:{pre % FRAME_T}, done {post // FRAME_T}:{post % FRAME_T}; '
              f'{n} sprites, {len(written)} bytes written ({changed} changed), buffer {"equal" if not diff else f"{len(diff)} bytes differ"}'
              f'; frame rule {"holds" if not bad_rule else bad_rule}')
    print(f'explosion frames drawn: {exploded}; blocks drawn: {", ".join(sorted(used))}')
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
