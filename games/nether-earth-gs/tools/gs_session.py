#!/usr/bin/env python3
"""A live unreal-qt instance for the GS case: launch, drive in steps, stop. Exploration and capture of what a TTD
recording does not hold (the GS port trace, the card's memory, the audio): the evidence recordings themselves are
re_session.py's (`capture --record-load --inputs`), driven by the same input scripts.

  gs_session.py launch --work W --port-base P [--model PENTAGON] [--card neogs|gs|gs-lw|none] [--card-ram 512k]
                       [--binary unreal-qt] [--record]
  gs_session.py steps --work W STEP...
  gs_session.py stop --work W

W/session.json holds the process and the ports (the same keys as re_session.py's, so `re_session.py stop` works too).
The instance is muted at once; audio goes to files only (capture_media audio_capture).

Steps, run in order:
  run:N                  run N frames
  script:FILE            an input script (frame KEYS lines, re_session.py's format) from the current frame
  key:K[+K2]:N           hold the keys (type_input names: enter, cs, ss, a ...) for N frames, then release
  joy:B[+B2]:N           hold Kempston buttons (fire, left, right, up, down) for N frames
  insert:PATH            put a disk (SCL / TRD) into drive A, not autostarted; a tape (TAP) into the deck
  tape:play              start the tape
  shot:PATH              the shown screen to PATH.png
  scr:PATH               the 6912 bytes of the shown screen to PATH
  cpu:PATH               the 64 K Z80 view now
  pages:PREFIX           the 8 RAM pages now to PREFIX-bankN.bin
  gsram:PATH             the GS card's RAM (memory_access region) to PATH
  gscmd:HH / gsdata:HH   write a command / data byte to the card (POST /control/audio/gs)
  gsstate:PATH           the card report (GET /state/audio/gs) to PATH (JSON)
  hist:DEV:MODE[:FILE]   a device history's mode (off / ring / capture), FILE: its stream (JSONL) beside it
  histread:DEV:N:PATH    the last N records of a device history to PATH (JSON)
  gstrace:start|stop     the GS port trace (the zxbus.1 history as a ring of 65536)
  gstraceread:N:PATH     its last N events to PATH (JSON)
  audio:SECONDS:PATH     capture SECONDS of the master mix while the machine runs, to PATH.wav (+ .json analysis)
  audiogs:SECONDS:PATH   the same for the GS card alone
  poke:ADDR:HEX          write bytes at a Z80 address (an experiment: never in a recording)
  save:PATH / load:PATH  a snapshot (.szx)
  ttd:start / ttd:dump:PATH   start TTD recording / write it
  l1:PATH                build L1 from the recording (analysis build) to PATH (l1.json), waiting for it
  regs                   print the main CPU's registers
  frame                  print the frame counter
"""

import argparse
import json
import os
import shutil
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/wt-negs-stage1')
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import mcplib  # noqa: E402
import mm_session  # noqa: E402

BINARY = os.path.join(UNREAL, 'cmake-build-agent-release', 'bin', 'unreal-qt.app', 'Contents', 'MacOS', 'unreal-qt')


class Live:
    def __init__(self, work):
        self.work = os.path.abspath(work)
        self.state = json.load(open(os.path.join(self.work, 'session.json')))
        self.s = mcplib.Session(f"http://127.0.0.1:{self.state['port_base'] + 200}/mcp", self.state['model'])
        listing = self.s.call('emulator_manage', {'action': 'list'}, ok=False)
        self.id = listing.structured['emulators'][0]['id']
        self.url = f"http://127.0.0.1:{self.state['port_base']}/api/v1/emulator/{self.id}"

    def get(self, path, raw=False):
        with urllib.request.urlopen(self.url + path, timeout=60) as r:
            data = r.read()
        return data if raw else json.loads(data)

    def api(self, method, path, body=None):
        r = self.s.call('invoke_api', {'method': method, 'path': '/api/v1/emulator/{id}' + path,
                                       **({'body': body} if body is not None else {})}, ok=False)
        return (r.structured or {}).get('body') or {}, r

    def run(self, n):
        self.s.call('control_execution', {'action': 'run_frames', 'frames': int(n)})

    def key(self, name, down):
        action = 'press' if down else 'release'
        if name in mm_session.KEMPSTON:
            self.s.call('joystick_input', {'action': action, 'buttons': mm_session.KEMPSTON[name]}, ok=False)
        else:
            self.s.call('type_input', {'action': action,
                                       'key': mm_session.KEY_NAMES.get(name, name.lower())})

    def script(self, path):
        held, last = [], 0
        for frame, keys in mm_session.parse_script(path):
            if frame > last:
                self.run(frame - last)
                last = frame
            if keys is None:
                break
            for k in held:
                self.key(k, False)
            for k in keys:
                self.key(k, True)
            held = keys
        for k in held:
            self.key(k, False)
        return last


def launch(args):
    work = os.path.abspath(args.work)
    os.makedirs(work, exist_ok=True)
    process = mcplib.launch(args.binary, args.port_base)
    with open(os.path.join(work, 'session.json'), 'w') as f:
        json.dump({'pid': process.pid, 'binary': args.binary, 'port_base': args.port_base, 'model': args.model,
                   'card': args.card, 'card_ram': args.card_ram}, f)
    s = mcplib.Session(f'http://127.0.0.1:{args.port_base + 200}/mcp', args.model)
    s.fresh_machine(args.model, ram_power_on='zero')
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    if args.card != 'neogs':
        plug = {'action': 'slots_plug', 'slot': 'zxbus.1', 'card': args.card, 'replace_if_incompatible': True}
        if args.card == 'none':
            plug = {'action': 'slots_unplug', 'slot': 'zxbus.1'}
        elif args.card_ram:
            plug['options'] = f'ram={args.card_ram}'
        r = s.call('emulator_manage', plug, ok=False)
        print((r.text or '').splitlines()[:3])
        time.sleep(1)
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
    r = s.call('inspect_state', {'aspects': ['slots']}, ok=False)
    print('\n'.join((r.text or '').splitlines()[:12]))
    print(f'launched pid {process.pid}: WebAPI {args.port_base}, MCP {args.port_base + 200}')


def steps(args):
    L = Live(args.work)
    s = L.s
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    for step in args.steps:
        kind, _, rest = step.partition(':')
        if kind == 'run':
            L.run(rest)
        elif kind == 'script':
            print('script frames', L.script(rest))
        elif kind in ('key', 'joy'):
            keys, _, n = rest.rpartition(':')
            names = keys.split('+')
            for k in names:
                if kind == 'key':
                    s.call('type_input', {'action': 'press', 'key': k}, ok=False)
                else:
                    s.call('joystick_input', {'action': 'press', 'buttons': k}, ok=False)
            L.run(n)
            for k in names:
                if kind == 'key':
                    s.call('type_input', {'action': 'release', 'key': k}, ok=False)
                else:
                    s.call('joystick_input', {'action': 'release', 'buttons': k}, ok=False)
        elif kind == 'insert':
            r = s.call('load_software', {'path': os.path.abspath(rest), 'autostart': False, 'play': False}, ok=False)
            print((r.text or '').splitlines()[:2])
        elif kind == 'tape':
            print(L.api('POST', '/tape/play', None)[0])
        elif kind == 'shot':
            r = s.call('capture_media', {'action': 'screenshot', 'path': os.path.abspath(rest + '.png')}, ok=False)
            print((r.text or '').splitlines()[:1])
        elif kind == 'scr':
            data = L.get('/memory/read/16384?length=6912&format=binary', raw=True)
            open(rest, 'wb').write(data)
        elif kind == 'cpu':
            open(rest, 'wb').write(L.get('/memory/read/0?length=65536&format=binary', raw=True))
        elif kind == 'pages':
            for n in range(8):
                open(f'{rest}-bank{n}.bin', 'wb').write(
                    L.get(f'/memory/page/ram/{n}?length=16384&format=binary', raw=True))
        elif kind == 'gsram':
            regions = s.call('memory_access', {'action': 'regions'}, ok=False)
            names = [r for r in ((regions.structured or {}).get('regions') or [])]
            gs = [r for r in names if 'gs' in json.dumps(r).lower() and 'ram' in json.dumps(r).lower()]
            if not gs:
                print('no GS RAM region:', (regions.text or '')[:800])
                continue
            region = gs[0].get('name') or gs[0].get('id')
            r = s.call('memory_access', {'action': 'save', 'space': region, 'path': os.path.abspath(rest)}, ok=False)
            print(region, (r.text or '').splitlines()[:2])
        elif kind in ('gscmd', 'gsdata'):
            # host-side write to the card's command (#BB) or data (#B3) latch, as the Spectrum would
            action = 'send_command' if kind == 'gscmd' else 'send_data'
            print(kind, rest, L.api('POST', '/control/audio/gs', {'action': action, 'value': int(rest, 16)})[0])
        elif kind == 'gsstate':
            json.dump(L.get('/state/audio/gs'), open(rest, 'w'), indent=1)
        elif kind == 'hist':
            dev, _, more = rest.partition(':')
            mode, _, stream = more.partition(':')
            body = {'mode': mode}
            if stream:
                body['stream'] = os.path.abspath(stream)
            if mode == 'capture':
                body['limit'] = 4000000
            print(dev, L.api('POST', f'/history/{dev}/config', body)[1].text[:300])
        elif kind == 'histread':
            dev, n, path = rest.split(':', 2)
            json.dump(L.get(f'/history/{dev}?last={n}'), open(path, 'w'), indent=0)
        elif kind == 'gstrace':
            print(L.api('POST', '/control/audio/gs/porttrace', {'action': rest})[1].text[:200])
        elif kind == 'gstraceread':
            n, path = rest.split(':', 1)
            json.dump(L.get(f'/state/audio/gs/porttrace?events={n}'), open(path, 'w'), indent=0)
        elif kind in ('audio', 'audiogs'):
            secs, path = rest.split(':', 1)
            body = {'action': 'start', 'seconds': float(secs)}
            if kind == 'audiogs':
                body['source'] = 'gs'
            print(L.api('POST', '/audio/capture', body)[1].text[:200])
            L.run(int(float(secs) * 50) + 5)
            res = L.get('/audio/capture/result?wav=true')
            wav = res.get('wav_path')
            if wav and os.path.exists(wav):
                shutil.copy(wav, path + '.wav')
            res.pop('samples', None)
            json.dump(res, open(path + '.json', 'w'), indent=1)
            print({k: res.get(k) for k in ('duration_seconds', 'dominant_hz', 'left', 'right', 'wav_path')})
        elif kind == 'poke':
            a, _, h = rest.partition(':')
            s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': '0x' + a, 'hex': h})
        elif kind == 'save':
            print(L.api('POST', '/snapshot/save', {'path': os.path.abspath(rest), 'force': True})[0])
        elif kind == 'load':
            print(L.api('POST', '/snapshot/load', {'path': os.path.abspath(rest)})[0])
        elif kind == 'ttd':
            if rest == 'start':
                print(s.call('analysis', {'action': 'start', 'record': True}, ok=False).text[:200])
            else:
                _, _, path = rest.partition(':')
                print(s.call('time_travel', {'action': 'dump', 'path': os.path.abspath(path)}, ok=False).text[:200])
        elif kind == 'l1':
            print(s.call('analysis', {'action': 'build', 'path': os.path.abspath(rest), 'wait': 30000},
                         ok=False).text[:300])
            state = s.call('analysis', {'action': 'status'}, ok=False).text
            while ': running' in state:
                time.sleep(5)
                state = s.call('analysis', {'action': 'status'}, ok=False).text
            print(state[:400])
        elif kind == 'regs':
            print(json.dumps(L.get('/registers')))
        elif kind == 'frame':
            print(json.dumps(L.get('/state/basic') if False else L.get('/registers').get('frame', '?')))
        else:
            raise SystemExit(f'unknown step {step}')


def stop(args):
    state = json.load(open(os.path.join(args.work, 'session.json')))
    pid = state['pid']
    try:
        cmd = open(f'/proc/{pid}/cmdline').read()
    except OSError:
        import subprocess
        cmd = subprocess.run(['ps', '-p', str(pid), '-o', 'command='], capture_output=True, text=True).stdout
    if 'unreal-qt' not in cmd or state['binary'] not in cmd:
        print(f'pid {pid} is not the launched unreal-qt any more: nothing stopped')
        return
    os.kill(pid, 15)
    print(f'stopped {pid}')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('launch')
    a.add_argument('--work', required=True)
    a.add_argument('--port-base', type=int, required=True)
    a.add_argument('--model', default='PENTAGON')
    a.add_argument('--card', default='neogs')
    a.add_argument('--card-ram')
    a.add_argument('--binary', default=BINARY)
    b = sub.add_parser('steps')
    b.add_argument('--work', required=True)
    b.add_argument('steps', nargs='+')
    c = sub.add_parser('stop')
    c.add_argument('--work', required=True)
    args = p.parse_args()
    {'launch': launch, 'steps': steps, 'stop': stop}[args.cmd](args)


if __name__ == '__main__':
    main()
