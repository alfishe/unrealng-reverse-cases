#!/usr/bin/env python3
"""A live instance for exploration and the bot, set up as re_session.py capture sets up its own (a fresh machine,
RAM zeroed, a Kempston card, muted), so a state and an input script found here replay the same in a capture.

  play_live.py start --work W [--model PENTAGON] [--port-base 14870] [--binary BIN]
  play_live.py stop --work W

W/session.json holds the process and the ports (drive.py --work W and play_bot.py --work W use it).
"""

import argparse
import json
import os
import signal
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402


def start(args):
    work = os.path.abspath(args.work)
    os.makedirs(work, exist_ok=True)
    process = mcplib.launch(args.binary, args.port_base)
    with open(os.path.join(work, 'session.json'), 'w') as f:
        json.dump({'pid': process.pid, 'binary': args.binary, 'port_base': args.port_base, 'model': args.model,
                   'ranges': '4000-FFFF'}, f)
    s = mcplib.Session(f'http://127.0.0.1:{args.port_base + 200}/mcp', args.model)
    s.fresh_machine(args.model, ram_power_on='zero')
    s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
    for _ in range(100):
        if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
            break
        time.sleep(0.1)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    print(f'pid {process.pid}  MCP http://127.0.0.1:{args.port_base + 200}/mcp  WebAPI http://127.0.0.1:{args.port_base}')


def stop(args):
    with open(os.path.join(args.work, 'session.json')) as f:
        state = json.load(f)
    pid = state.get('pid')
    if pid:
        try:
            name = os.popen(f'ps -p {pid} -o comm=').read()
            if 'unreal-qt' in name:
                os.kill(pid, signal.SIGTERM)
                print(f'stopped {pid}')
        except ProcessLookupError:
            pass


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='command', required=True)
    a = sub.add_parser('start')
    a.add_argument('--work', required=True)
    a.add_argument('--model', default='PENTAGON')
    a.add_argument('--port-base', type=int, default=14870)
    a.add_argument('--binary', required=True)
    a.set_defaults(func=start)
    b = sub.add_parser('stop')
    b.add_argument('--work', required=True)
    b.set_defaults(func=stop)
    args = p.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
