#!/usr/bin/env python3
"""A long recorded game of the '98: Nether Earth's own bot (R/games/nether-earth/tools/bot.py, used as a library,
not changed) plays the '98 from its menu on a Pentagon 128, so the daily routines, robot builds, orders and fights
run under the recording.

    python3 tools/game98_deep.py --start work/stage2/game98/menu98.szx --work work/stage2/game98/deep \
        [--frames 30000] [--port-base 15010]

The '98 keeps NE's variables, robot records, map, menus and interrupt handlers at NE's addresses (only the changes
listed in work/stage2/STATE-game98.md differ), so the bot's reads and steering work unchanged. The instance: own
port base, muted, a Kempston card, the menu snapshot loaded, the analysis recording started; at the end the L1 build
(W/l1.json), the recording (W/session.ttd), W/play.log and W/screens/. The instance stays up for re_session.py
(stop it with re_session.py stop --work W).
"""
import argparse
import json
import os
import sys
import time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NE_TOOLS = os.path.join(ROOT, '..', 'nether-earth', 'tools')
UNREAL = toolpaths.unreal_ng(required=False) or 'unreal-ng'
BIN = os.path.join(UNREAL, 'cmake-build-agent-release', 'bin', 'unreal-qt.app', 'Contents', 'MacOS', 'unreal-qt')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--start', required=True)
    p.add_argument('--work', required=True)
    p.add_argument('--frames', type=int, default=30000)
    p.add_argument('--port-base', type=int, default=15010)
    p.add_argument('--binary', default=BIN)
    a = p.parse_args()
    sys.path.insert(0, NE_TOOLS)
    import bot  # noqa: E402
    g = bot.Game(UNREAL, a.work)
    work = g.work
    os.makedirs(work, exist_ok=True)
    start = os.path.abspath(a.start)
    here = os.getcwd()
    os.chdir(work)  # the emulator writes its features.ini where it starts
    try:
        process = g.mcplib.launch(a.binary, a.port_base)
    finally:
        os.chdir(here)
    s = g.mcplib.Session(f'http://127.0.0.1:{a.port_base + 200}/mcp', 'PENTAGON')
    s.fresh_machine('PENTAGON', ram_power_on='zero')
    s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
    for _ in range(100):  # the plug restarts the machine: wait for the wired stick
        if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
            break
        time.sleep(0.1)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    g.s = s
    g.m = g.corpus.Machine(s, a.port_base)
    g.m.post('/snapshot/load', {'path': start})
    with open(os.path.join(work, 'session.json'), 'w') as f:
        json.dump({'pid': process.pid, 'binary': a.binary, 'port_base': a.port_base, 'model': 'PENTAGON',
                   'ranges': '4000-FFFF'}, f)
    g.m.post('/snapshot/save', {'path': os.path.join(work, 'start.szx'), 'force': True})
    with open(os.path.join(work, 'start.bin'), 'wb') as f:
        f.write(g.m.read(0, 0x10000))
    s.call('analysis', {'action': 'start', 'record': True})
    print(f'pid {process.pid}, MCP http://127.0.0.1:{a.port_base + 200}/mcp', flush=True)
    shots = os.path.join(work, 'screens')
    os.makedirs(shots, exist_ok=True)
    try:
        bot.play(g, a.frames, shots)
    finally:
        with open(os.path.join(work, 'play.log'), 'w') as f:
            f.write('\n'.join(g.log) + '\n')
    g.finish()
    return 0


if __name__ == '__main__':
    sys.exit(main())
