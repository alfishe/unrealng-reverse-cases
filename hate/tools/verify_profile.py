#!/usr/bin/env python3
"""The ground profile `$6000-$62FF` of a recording against the one rebuilt from the course data (docs/06-rendering.md
6.5): the anchors of `src/res/course/ground-anchors.bin` picked by the course bytes, the walls ORed back, the 7 bytes
between two anchors stepped in 8-bit arithmetic as `BuildGroundProfile` `$D0EF` does.

    python3 tools/verify_profile.py FRAME:T:ROUND ... [--unreal UNREAL_NG_CHECKOUT]

Needs an unreal-ng instance with work/p2 open (re_session.py open).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
ANCHORS = 0xC9FE


def build(course, anchors):
    """The 768 bytes `$D0EF` writes for a course (its first byte the player's type)"""
    buf = bytearray(0x300)
    de = 8
    for b in course[1:]:
        if b == 0xFF:
            break
        hl = ANCHORS + b // 2
        while True:
            if de >= 0x300:
                return bytes(buf)
            a = anchors[hl - ANCHORS]
            if a == 0xFF:
                break
            buf[de] = a
            hl += 1
            prev = de - 8
            buf[prev] |= a & 0xE0
            diff = ((buf[prev] & 0x1F) - (a & 0x1F)) & 0xFF
            step = (diff - 256 if diff & 0x80 else diff) >> 3 & 0xFF  # SRA x3
            v = buf[prev]
            for i in range(1, 8):
                v = (v - step) & 0xFF
                buf[prev + i] = v
            de += 8
    return bytes(buf)


def main():
    unreal = os.environ.get('UNREAL_NG', '')
    args = sys.argv[1:]
    if '--unreal' in args:
        i = args.index('--unreal')
        unreal = args[i + 1]
        del args[i:i + 2]
    sys.path.insert(0, os.path.join(unreal, 'tools', 'verification', 'analysis'))
    sys.path.insert(0, HERE)
    import re_session  # noqa: E402
    import memanim  # noqa: E402
    session, _ = re_session.session_of(os.path.join(ROOT, 'work', 'p2'))
    anchors = open(os.path.join(ROOT, 'src', 'res', 'course', 'ground-anchors.bin'), 'rb').read()
    for arg in args:
        f, t, rnd = map(int, arg.split(':'))
        mem = memanim.memory_at(session, f, t)[0x6000:0x6300]
        course = open(os.path.join(ROOT, 'src', 'res', 'course', f'round-{rnd:02d}.bin'), 'rb').read()
        rebuilt = build(course, anchors)
        diff = [i for i in range(0x300) if rebuilt[i] != mem[i]]
        text = 'equal, all 768 bytes' if not diff else \
            f'{len(diff)} bytes differ, ' + ', '.join(f'${0x6000 + i:04X} {mem[i]:02X}/{rebuilt[i]:02X}' for i in diff[:8])
        print(f'{f}:{t} round {rnd}: {text}')


if __name__ == '__main__':
    main()
