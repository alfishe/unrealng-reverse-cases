#!/usr/bin/env python3
"""The 13 rooms no play reached (12, 13, 19, 21, 36, 47-50, 52, 55, 91, 92), each entered on a clone by a POKE of
the map position: the 48K machine loads the RZX's state 15 frames before Hiro walks right from room 4 into room 5
(work/stage2/rzx/rooms/snap-002015.z80, tools/rzx_snap.py), the map row `$69DF` and column `$69E0` are poked to the
target's row and column - 1, and right (key 7, menu option 1) is held: CheckRoomExit `$955A` steps the column and
EnterRoom `$95C3` / FindRoom `$95F9` build the target room. The POKE is in the machine only, never in the image;
record.json lists it. Then the screen, end.szx and the L1 of the entry (work/stage2/rec/poke-roomNNN/).

    python3 tools/poke_rooms.py [--port-base 37470] [--only 12,13]

The row and column of each room come from the map tables (`$7048`, `$70C7`, `$70DB`; tools/fig_rooms.py).
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402

ROOMS = (12, 13, 19, 21, 36, 47, 48, 49, 50, 52, 55, 91, 92)
SNAP = os.path.join(CASE, 'work', 'stage2', 'rzx', 'rooms', 'snap-002015.z80')


def position(room):
    m = open(os.path.join(CASE, 'work', 'mkgame', 'resident.bin'), 'rb').read()
    for row in range(20):
        start, count = m[0x70DB + row], m[0x70C7 + row]
        if start < room <= start + count:
            return row, m[0x7048 + room - 1]
    raise ValueError(room)


def build_l1(lab, work):
    s = lab.s
    try:
        s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 1000}, ok=False)
    except OSError:
        pass
    st = ''
    for _ in range(360):
        try:
            st = s.call('analysis', {'action': 'status'}, ok=False).text
        except OSError:
            st = ': running'
        if ': running' not in st and os.path.exists(os.path.join(work, 'l1.json')):
            break
        time.sleep(5)
    return st.splitlines()[-3:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port-base', type=int, default=37470)
    ap.add_argument('--only', default='')
    a = ap.parse_args()
    rooms = [int(x) for x in a.only.split(',')] if a.only else ROOMS
    for room in rooms:
        row, col = position(room)
        work = os.path.join(CASE, 'work', 'stage2', 'rec', f'poke-room{room:03d}')
        os.makedirs(work, exist_ok=True)
        lab = Lab(a.port_base, model='48K')
        lab.session_json(work)
        try:
            lab.load(SNAP)
            pokes = [[0x69DF, row], [0x69E0, col - 1]]
            for addr, v in pokes:
                lab.write(addr, bytes([v]))
            lab.start_recording()
            entered = None
            lab.keys(['7'])
            for _ in range(60):
                lab.run(1)
                if lab.read(0x6BDD, 1)[0] == room:
                    entered = lab.frame
                    break
            lab.run(10)
            lab.keys([])
            lab.run(100)
            got = lab.read(0x6BDD, 1)[0], lab.read(0x69DF, 1)[0], lab.read(0x69E0, 1)[0]
            lab.shot(os.path.join(work, 'screen.png'))
            lab.save(os.path.join(work, 'end.szx'))
            rec = {'plan': 'poke_rooms', 'note': __doc__.split('\n\n')[0], 'model': '48K',
                   'start': os.path.relpath(SNAP, CASE), 'pokes': [[f'${x:04X}', v] for x, v in pokes],
                   'room': room, 'row': row, 'col': col, 'entered_frame': entered, 'frames': lab.frame,
                   'end': {'room': got[0], 'row': got[1], 'col': got[2]}}
            rec['status'] = build_l1(lab, work)
            json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
            print(room, row, col, 'entered at', entered, 'end', got, flush=True)
        finally:
            lab.close()


if __name__ == '__main__':
    main()
