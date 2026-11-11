#!/usr/bin/env python3
"""Read the game's state from a running instance of ours (one re_session.py capture kept alive): the variables
`$FD7E-$FDA7`, PC, and optionally a screenshot.

    python3 tools/peek.py [--port 37100] [--shot OUT.png]
"""
import argparse
import json
import urllib.request


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', type=int, default=37100)
    ap.add_argument('--shot')
    a = ap.parse_args()
    base = f'http://127.0.0.1:{a.port}/api/v1/emulator'
    ems = json.load(urllib.request.urlopen(base, timeout=10))
    ems = ems.get('emulators', ems) if isinstance(ems, dict) else ems
    url = f"{base}/{ems[0]['id']}"
    v = urllib.request.urlopen(f'{url}/memory/read/{0xFD7E}?length=42&format=binary', timeout=10).read()
    print('FD7E:', ' '.join('%02X' % x for x in v))
    regs = json.load(urllib.request.urlopen(f'{url}/registers', timeout=10))
    print('PC', regs.get('pc', regs))
    if a.shot:
        open(a.shot, 'wb').write(urllib.request.urlopen(f'{url}/screenshot?format=png', timeout=10).read())


if __name__ == '__main__':
    main()
