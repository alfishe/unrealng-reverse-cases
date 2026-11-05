#!/usr/bin/env python3
"""The host's General Sound traffic in a recording: every effect the game played, with the wait for each command.

    python3 tools/gs_ports.py plays --ports work/gsB/rT/ports.jsonl [--json OUT]

--ports is a `zxbus.1.ports` history stream (gs_session.py `hist:zxbus.1.ports:capture:FILE`): one JSON line per
host IN / OUT on the card's ports, with the frame, the T-state in the frame and the PC. The history keeps the
T-state in 16 bits, so a Pentagon frame's T-states past 65535 wrap to 0: they are unwrapped here (a T-state lower
than the one before in the same frame adds 65536).

A play is the driver's command run: on Hood's tape `#2E` n, `#40` with data `$2F`, `#39` with data n, each followed
by polls of the status port until bit 0 clears (the card took it); on the disk `#40` and `#39` with no poll. Printed
per play: the frame, the effect, the T-state of the first OUT, the wait after each command (T-states).
"""
import argparse
import json

FRAME_T = 71680  # Pentagon 128


def load(path):
    rows, last = [], {}
    for line in open(path):
        try:
            d = json.loads(line)
        except ValueError:
            continue  # the stream's last line may be cut
        f, t = d['frame'], d['tacts']
        base = last.get(f, (0, -1))
        if t < base[1]:
            base = (base[0] + 65536, t)
        last[f] = (base[0], t)
        d['t'] = f * FRAME_T + base[0] + t
        rows.append(d)
    return rows


def plays(rows):
    """[{frame, t, effect, cmds: [{cmd, data, out, taken, wait, pc}]}]: one per #39, with the commands since the last"""
    out, cmds, data = [], [], None
    for d in rows:
        port = d['port'] & 0xFF
        if d['dir'] == 'out' and port == 0xB3:
            data = d['value']
        elif d['dir'] == 'out' and port == 0xBB:
            cmds.append({'cmd': d['value'], 'data': data, 'out': d['t'], 'taken': None, 'wait': None, 'pc': d['pc']})
            if d['value'] == 0x39:
                out.append({'frame': d['frame'], 't': cmds[0]['out'], 'effect': data, 'cmds': cmds})
                cmds = []
        elif d['dir'] == 'in' and port == 0xBB and not d['value'] & 1:
            last = out[-1]['cmds'][-1] if out and not cmds else (cmds[-1] if cmds else None)
            if last and last['taken'] is None:
                last['taken'] = d['t']
                last['wait'] = d['t'] - last['out']
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('command', choices=['plays'])
    ap.add_argument('--ports', required=True)
    ap.add_argument('--json')
    a = ap.parse_args()
    ps = plays(load(a.ports))
    for p in ps:
        print(p['frame'], p['effect'], ' '.join(f"#{c['cmd']:02X}:{c['wait']}" for c in p['cmds']))
    if a.json:
        json.dump(ps, open(a.json, 'w'), indent=0)


if __name__ == '__main__':
    main()
