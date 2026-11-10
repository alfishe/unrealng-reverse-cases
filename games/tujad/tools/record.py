#!/usr/bin/env python3
"""A recording of an input script from a saved state: the state loaded on a fresh muted instance, the TTD recording
started, the script played (one run call a segment, cut at every multiple of --shot and at each poke), a
screenshot and the game's state every --shot frames, then L1 built and the recording kept (W/session.ttd, W/l1.json, W/states.json, W/end.szx, W/screens/).

    python3 tools/record.py --start work/stage1/c1/menu.szx --inputs tests/inputs/menu-cursor.txt --work work/stage1/rec/menu-cursor \
        [--poke FRAME,ADDR,VALUE ...] [--shot 50] [--port-base 36910]

A --poke writes one byte at the frame it names (after that frame's run): the recording's NOTES row says so, and no
poked byte reaches the image (tools/image.py builds it from the tape alone).

The state logged (the variables found in stage 1): the room `$6363` (+1 east, -1 west, +8 south, -8 north,
`$7403-$7527`), the lives `$636D` and the energy `$636E` (BCD; a life is lost when the energy reaches 0, `$6A30`),
the controls `$63C2` (read in the interrupt by `$7161`), the PC.
"""
import argparse
import json
import os
import signal
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, mm_session  # noqa: E402


def segments(path):
    segs, last, keys = [], 0, []
    for frame, k in mm_session.parse_script(path):
        if frame > last:
            segs.append((keys, frame - last))
            last = frame
        if k is None:
            break
        keys = k
    return segs


def state(lab):
    v = lab.read(0x6363, 0x60)
    r = lab.regs() or {}
    return dict(room=v[0], lives=f'{v[0x0A]:02X}', energy=f'{v[0x0B]:02X}', ctrl=f'{v[0x5F]:02X}',
                pc=r.get('pc', r.get('PC', '')))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--start', required=True)
    ap.add_argument('--inputs', required=True)
    ap.add_argument('--work', required=True)
    ap.add_argument('--poke', action='append', default=[])
    ap.add_argument('--pokes', help='a file of pokes, one "FRAME ADDR VALUE" a line (hex with 0x or $)')
    ap.add_argument('--shot', type=int, default=50)
    ap.add_argument('--port-base', type=int, default=36910)
    ap.add_argument('--keep', action='store_true')
    ap.add_argument('--compare', help="frames.bin of tools/rzx_keys.py log: `$6300-$63FF` after each frame; the room, "
                    "lives and energy compared at every shot, the first difference printed")
    ap.add_argument('--compare-from', type=int, default=0, help='the --compare sample the start state was saved after')
    ap.add_argument('--dry', action='store_true', help='no recording, no L1 (a --compare check)')
    ap.add_argument('--frames', type=int, default=0, help='stop after this many frames (0: the whole script)')
    args = ap.parse_args()
    signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt()))
    os.makedirs(os.path.join(args.work, 'screens'), exist_ok=True)
    pokes = {}
    lines = [p.split(',') for p in args.poke]
    if args.pokes:
        lines += [ln.split() for ln in open(args.pokes) if ln.strip() and not ln.startswith('#')]
    for f, a, v in lines:
        pokes.setdefault(int(f), []).append((int(a.replace('$', '0x'), 0), int(v.replace('$', '0x'), 0)))
    lab = Lab(args.port_base)
    try:
        lab.load(os.path.abspath(args.start))
        lab.session_json(args.work)
        if not args.dry:
            lab.start_recording()
        ref = open(args.compare, 'rb').read() if args.compare else None
        frame, log, first_diff = 0, [], None
        segs, at = [], 0
        for keys, frames in segments(args.inputs):  # a segment is cut at each poke's frame and every --shot frames
            cuts = set(k for k in pokes if at < k < at + frames)
            cuts |= set(range((at // args.shot + 1) * args.shot, at + frames, args.shot))
            for cut in sorted(cuts):
                segs.append((keys, cut - at))
                frames -= cut - at
                at = cut
            segs.append((keys, frames))
            at += frames
        for keys, frames in segs:
            if args.frames and frame >= args.frames:
                break
            lab.keys(keys)
            before = frame
            lab.run(frames)
            frame += frames
            for f in sorted(k for k in pokes if before < k <= frame):
                for a, v in pokes[f]:
                    lab.write(a, bytes([v]))
            if frame // args.shot > before // args.shot:
                lab.shot(os.path.join(args.work, 'screens', f'{frame:06d}.png'), 1)
                log.append(dict(frame=frame, keys=keys, **state(lab)))
                at = frame + args.compare_from
                if ref and first_diff is None and at * 256 <= len(ref):
                    v = ref[(at - 1) * 256:at * 256]
                    want = (v[0x63], f'{v[0x6D]:02X}', f'{v[0x6E]:02X}')
                    got = (log[-1]['room'], log[-1]['lives'], log[-1]['energy'])
                    if want != got:
                        first_diff = dict(frame=frame, want=want, got=got)
                        print('first difference', first_diff, flush=True)
                if frame // 5000 > before // 5000:
                    print('frame', frame, log[-1], flush=True)
        lab.keys([])
        lab.shot(os.path.join(args.work, 'screens', f'{frame:06d}.png'), 1)
        log.append(dict(frame=frame, keys=[], **state(lab)))
        json.dump(log, open(os.path.join(args.work, 'states.json'), 'w'), indent=0)
        if ref:
            print('compare:', first_diff or 'no difference at the shots', flush=True)
        if args.dry:
            return
        lab.save(os.path.abspath(os.path.join(args.work, 'end.szx')))
        built = lab.s.call('analysis', {'action': 'build', 'path': os.path.abspath(os.path.join(args.work, 'l1.json')),
                                        'wait': 30000})
        st = lab.s.call('analysis', {'action': 'status'}).text
        while ': running' in st:
            time.sleep(5)
            st = lab.s.call('analysis', {'action': 'status'}).text
        print(st.splitlines()[-1] if st else built.text)
        r = lab.s.call('time_travel', {'action': 'dump',
                                       'path': os.path.abspath(os.path.join(args.work, 'session.ttd'))}, ok=False)
        print((r.text or '').splitlines()[:1])
        json.dump({'start': args.start, 'inputs': args.inputs, 'frames': frame, 'pokes': args.poke + (
                   [args.pokes] if args.pokes else []),
                   'compare': first_diff if ref else None,
                   'status': st.splitlines()}, open(os.path.join(args.work, 'record.json'), 'w'), indent=1)
        print(f'recorded {frame} frames')
    finally:
        if not args.keep:
            lab.close()


if __name__ == '__main__':
    main()
