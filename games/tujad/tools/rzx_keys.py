#!/usr/bin/env python3
"""The keys of an RZX playthrough as an mm_session input script, so the play can be replayed with the TTD recording
on (unreal-ng does not record a TTD history while an RZX plays: WALKTHROUGH 5).

    python3 tools/rzx_keys.py log --rzx work/candidates/zxdb/tujad.rzx --out work/stage1/rzx   # frames.bin, start.szx
    python3 tools/rzx_keys.py script --log work/stage1/rzx --from 1000 --out tests/inputs/rzx-play.txt

`log` plays the RZX one frame a call (`/rzx/play`, tolerant) and keeps, after every frame, the game's variables
`$6300-$63FF` (256 bytes a frame in frames.bin) and the start state (start.szx, saved before the first frame).
`script` turns them into keys: the game reads its controls in the interrupt (`$7161`, called from the IM 2 handler
`$95D0`) into `$63C2`, whose bits 7 and 6 say the method (bit 7 keyboard, bit 6 the cursor keys, neither the
Kempston stick) and whose bits 0-4 are right, left, down, up, fire; SPACE (weapon select, `$7976`) is held while
bit 0 of `$6369` is clear (set again at the key's release). The script holds, for each frame, the keys of the
method in use that give those bits: cursor 8 right, 5 left, 6 down, 7 up, 0 fire.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

VARS, NVARS = 0x6300, 256
CURSOR = {0: '8', 1: '5', 2: '6', 3: '7', 4: '0'}
KEYBOARD = {0: 'X', 1: 'Z', 2: 'A', 3: 'Q', 4: '1'}
KEMPSTON = {0: 'KR', 1: 'KL', 2: 'KD', 3: 'KU', 4: 'KF'}


def log(args):
    from lab import Lab
    os.makedirs(args.out, exist_ok=True)
    lab = Lab(args.port_base)
    try:
        lab.post('/rzx/play', {'path': os.path.abspath(args.rzx), 'desync_mode': 'tolerant'})
        lab.mute()
        lab.s.call('control_execution', {'action': 'pause'}, ok=False)
        lab.save(os.path.join(args.out, 'start.szx'))
        with open(os.path.join(args.out, 'frames.bin'), 'wb') as f:
            n = 0
            while True:
                lab.run(1)
                n += 1
                f.write(lab.read(VARS, NVARS))
                if n % 1000 == 0:
                    st = lab.s.call('invoke_api', {'method': 'GET',
                                                   'path': '/api/v1/emulator/{id}/rzx/status'}).structured['body']
                    print(n, st.get('state'), st.get('frame'), st.get('total_frames'), flush=True)
                    if st.get('state') != 'playing':
                        break
                    lab.save(os.path.join(args.out, f'at{n:06d}.szx'))
        json.dump({'frames': n}, open(os.path.join(args.out, 'log.json'), 'w'))
    finally:
        lab.close()


def keys_of(ctrl, space):
    method = KEYBOARD if ctrl & 0x80 else CURSOR if ctrl & 0x40 else KEMPSTON
    keys = [method[b] for b in range(5) if ctrl & (1 << b)]
    if space:
        keys.append('SPACE')
    return keys


def script(args):
    data = open(os.path.join(args.log, 'frames.bin'), 'rb').read()
    n = len(data) // NVARS
    with open(args.out, 'w') as f:
        f.write(f'# rzx_keys.py script from {args.log}: the keys of the RZX playthrough, one line a change\n')
        held = None
        for i in range(args.from_frame, n):
            v = data[i * NVARS:(i + 1) * NVARS]
            # the sample after frame i holds the controls its interrupt read: hold them during frame i
            k = keys_of(v[0xC2], not (v[0x69] & 1))
            if k != held:
                f.write(f"{i - args.from_frame} {' '.join(k) if k else '-'}\n")
                held = k
        f.write(f'{n - args.from_frame} -\n{n - args.from_frame + 1} END\n')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('log')
    a.add_argument('--rzx', required=True)
    a.add_argument('--out', required=True)
    a.add_argument('--port-base', type=int, default=36900)
    b = sub.add_parser('script')
    b.add_argument('--log', required=True)
    b.add_argument('--out', required=True)
    b.add_argument('--from', dest='from_frame', type=int, default=0,
                   help='the first sample: the script starts from the state saved after it (at<N>.szx is saved '
                        'after N frames, so --from N plays from at<N>.szx)')
    args = p.parse_args()
    log(args) if args.cmd == 'log' else script(args)


if __name__ == '__main__':
    main()
