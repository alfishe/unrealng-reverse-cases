#!/usr/bin/env python3
"""Doc 05 experiment: the weapon pod with and without fire held, on an own live instance (no recording reached it).

    python3 tools/exp_pods.py --state work/zyA/exp/r1-200.szx --out work/zyA/exp/pods [--port-base 14530]

The state is r1 at frame 200 (level 0, Invulnerable `$FFD7` = 1, a pod is born at frame 225 in slot 5 at row 7;
`time_travel seek` + `/snapshot/save` on the r1 instance). Each run loads the state, puts the ship on the pod's row
(`$F36C` +5/+6 = 0/7), sets the pod selector (the player record `$7F9C` +7), then holds Kempston fire from the
start (`take`) or leaves it alone (`select`). It runs 260 frames, every frame logging FireHeld `$8184`, the record's
+7..+$0B, Fuel `$80E6` and the score, and keeping the screen every 2 frames. After the pod is touched a `take` run
taps fire every 6 frames so the weapon shows. Writes OUT/<run>.tsv and OUT/<run>.npz (screens) for
tools/fig_pods.py. The instance is launched muted and stopped at the end.
"""
import argparse
import json
import os
import subprocess
import sys

import numpy as np

import zynlib as Z

BINARY = ('/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/wt-nezs-stage1/cmake-build-agent-release/bin/'
          'unreal-qt.app/Contents/MacOS/unreal-qt')
RUNS = [('select', 0, False), ('take-0', 0, True), ('take-1', 1, True), ('take-2', 2, True), ('take-3', 3, True),
        ('take-4', 4, True)]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--state', required=True)
    p.add_argument('--out', required=True)
    p.add_argument('--port-base', type=int, default=14530)
    p.add_argument('--frames', type=int, default=260)
    args = p.parse_args()
    os.makedirs(args.out, exist_ok=True)
    root = Z.K.unreal_root(None)
    for sub in ('analysis', 'mcp'):
        sys.path.insert(0, os.path.join(root, 'tools', 'verification', sub))
    import mcplib  # noqa: E402
    import corpus  # noqa: E402
    process = mcplib.launch(BINARY, args.port_base)
    try:
        s = mcplib.Session(f'http://127.0.0.1:{args.port_base + 200}/mcp', '48K')
        s.fresh_machine('48K', ram_power_on='zero')
        s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
        m = corpus.Machine(s, args.port_base)

        def poke(addr, data):
            s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': f'0x{addr:04X}', 'hex': data.hex()})

        def fire(down):
            s.call('joystick_input', {'action': 'press' if down else 'release', 'buttons': 'fire'}, ok=False)

        for name, selector, hold in RUNS:
            m.post('/snapshot/load', {'path': os.path.abspath(args.state)})
            poke(0xF371, bytes([0x00, 0x07]))      # the ship's Y: row 7, the pod's
            poke(0x7F9C + 7, bytes([selector]))
            fire(hold)
            rows, screens, touched = [], [], None
            for f in range(args.frames):
                if hold and touched is not None and f > touched + 8:
                    fire((f - touched) % 6 < 3)
                s.call('control_execution', {'action': 'run_frames', 'frames': 1})
                v = m.read(0x7F60, 0x300)
                rec = v[0x7F9C - 0x7F60:0x7F9C - 0x7F60 + 16]
                row = dict(frame=f + 1, fire_held=v[0x8184 - 0x7F60], selector=rec[7], side=rec[8], double=rec[9],
                           laser=rec[10], speed=rec[11], fuel=v[0x80E6 - 0x7F60],
                           score=int(rec[0:4].hex()), lives=rec[4])
                if touched is None and rows and any(row[k] != rows[-1][k] for k in ('selector', 'side', 'double', 'laser', 'speed')):
                    touched = f
                rows.append(row)
                if f % 2 == 1:
                    screens.append(np.frombuffer(m.read(0x4000, 6912), dtype=np.uint8))
            fire(False)
            with open(os.path.join(args.out, name + '.tsv'), 'w') as out:
                keys = list(rows[0])
                out.write('\t'.join(keys) + '\n')
                for r in rows:
                    out.write('\t'.join(str(r[k]) for k in keys) + '\n')
            np.savez_compressed(os.path.join(args.out, name + '.npz'), screens=np.array(screens))
            first, last = rows[0], rows[-1]
            print(name, 'touched at frame', None if touched is None else touched + 1,
                  json.dumps({k: (first[k], last[k]) for k in ('selector', 'side', 'double', 'laser', 'speed', 'fuel',
                                                              'score')}))
    finally:
        process.terminate()
        try:
            process.wait(20)
        except subprocess.TimeoutExpired:
            process.kill()


if __name__ == '__main__':
    main()
