#!/usr/bin/env python3
"""Every resource file of src/res against the bot's recording (work/p2): for each `INCBIN` of src/game its address
in the assembler's listing (`build/game.lst`, written by tools/build.sh), then the recording's memory there at the
given frames. (Found by its bytes instead, a stale copy such as `sprite-gfx-copy.bin` would land on its original.)
A piece the game never writes equals the file at every frame; one it rewrites in play (the game screen under the
playfield, the buffers) is reported with the bytes that differ at each frame.

    python3 tools/verify_res.py [--work work/p2] [--frames 210 1000 5000 9000 11000] [--unreal UNREAL_NG_CHECKOUT]

Needs build/game.bin and an unreal-ng instance with the work folder's recording open (re_session.py open).
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import res_formats  # noqa: E402
import res_preview  # noqa: E402

FRAME_T = 69888
INCBIN = re.compile(r'^\s*\d+\+?\s+([0-9A-F]{4})\s+INCBIN\s+"([^"]+)"(?:\s*,\s*(\$?[0-9A-Fa-f]+))?'
                    r'(?:\s*,\s*(\$?[0-9A-Fa-f]+))?')


def number(text):
    return int(text[1:], 16) if text.startswith('$') else int(text)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--frames', type=int, nargs='*', default=[210, 1000, 5000, 9000, 11000])
    p.add_argument('--work', default='work/p2', help='the work folder of the open recording')
    p.add_argument('--unreal', default=os.environ.get('UNREAL_NG', ''))
    args = p.parse_args()
    sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(os.path.join(ROOT, args.work))
    image = bytes(res_preview.LO) + open(os.path.join(ROOT, 'build', 'game.bin'), 'rb').read()
    memory = {}
    for f in args.frames:
        data = bytearray()
        for offset in range(0, 0x10000, 0x4000):
            r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                             'offset': offset, 'length': 0x4000}, ok=False)
            data += bytes.fromhex(r.structured['hex'])
        memory[f] = bytes(data)
    pieces = []
    for line in open(os.path.join(ROOT, 'build', 'game.lst')):
        m = INCBIN.match(line)
        if not m:
            continue
        data = res_formats.load(m.group(2)[len('res/'):])
        start = number(m.group(3)) if m.group(3) else 0
        length = number(m.group(4)) if m.group(4) else len(data) - start
        pieces.append((m.group(2), start, data[start:start + length], int(m.group(1), 16)))
    failures, static, total = 0, 0, 0
    for name, start, data, a in pieces:
        if image[a:a + len(data)] != data:
            print(f'{name}+{start}: {len(data)} bytes, the assembled image differs at ${a:04X}')
            failures += 1
            continue
        diffs = [sum(memory[f][a + i] != data[i] for i in range(len(data))) for f in args.frames]
        total += 1
        if not any(diffs):
            static += 1
            state = 'equal at every frame'
        else:
            state = 'rewritten in play: ' + ', '.join(f'{f}: {d}' for f, d in zip(args.frames, diffs))
        print(f'${a:04X} {len(data):5} {name}+{start}: {state}')
    print(f'{static} of {total} pieces equal the recording at frames {", ".join(map(str, args.frames))}')
    sys.exit(1 if failures else 0)


if __name__ == '__main__':
    main()
