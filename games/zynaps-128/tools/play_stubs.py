#!/usr/bin/env python3
"""The frames each of the 15 sound hook stubs ran in a recording, and the frames its page-4 engine entry ran in.

  play_stubs.py --work W [--from F] [--to G] [--out FILE]

W is a re_session.py capture folder whose instance is up (session.json). Each stub (`$B32F`-`$B39C`, RAM page 2)
loads L with its engine entry and jumps to the shared stub `$B30D`, which calls `$C900 + L` with page 4 in; the
table below is read from the stubs' code (`LD L,n`). time_travel coverage_scan (kind executed) is asked for the
stub's first byte on page 2 and for the entry on page 4. A frame listed for both is a frame the stub started its
effect in.
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402

# stub: (site, engine entry)
STUBS = {
    0xB32F: (0x9C77, 0xC971), 0xB334: (0xACA2, 0xC975), 0xB33C: (0x9EC2, 0xC97B), 0xB344: (0xA81B, 0xC97F),
    0xB34C: (0xA8B7, 0xC987), 0xB354: (0x9BFF, 0xC987), 0xB35C: (0x9CFA, 0xC98B), 0xB364: (0xA247, 0xC991),
    0xB36C: (0x9CB0, 0xC999), 0xB374: (0xA1C4, 0xC99D), 0xB379: (0xA21A, 0xC9A1), 0xB381: (0xA31D, 0xC9A9),
    0xB386: (0xA29F, 0xC9AD), 0xB38F: (0xA7BB, 0xC9B1), 0xB39C: (0xA5D1, 0xC9B1),
}


def scan(s, address, page, first, last):
    body = {'action': 'coverage_scan', 'kind': 'executed', 'addr_from': hex(address), 'addr_to': hex(address),
            'phys_page': page, 'limit': 10000}
    if first is not None:
        body['from_frame'] = first
    if last is not None:
        body['to_frame'] = last
    r = s.call('time_travel', body, ok=False)
    frames = (r.structured or {}).get('frames') or []
    return [int(f['frame']) if isinstance(f, dict) else int(f) for f in frames], (r.text or '').splitlines()[0]


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='first', type=int)
    p.add_argument('--to', dest='last', type=int)
    p.add_argument('--out')
    args = p.parse_args()
    state = json.load(open(os.path.join(args.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    lines = []
    for stub, (site, entry) in STUBS.items():
        sf, stext = scan(s, stub, 2, args.first, args.last)
        ef, etext = scan(s, entry, 4, args.first, args.last)
        both = sorted(set(sf) & set(ef))
        lines.append(f'stub ${stub:04X} site ${site:04X} entry ${entry:04X}: stub {len(sf)} frames, entry {len(ef)}, '
                     f'both {len(both)}')
        lines.append(f'  stub  {sf[:60]}  ({stext})')
        lines.append(f'  entry {ef[:60]}  ({etext})')
    text = '\n'.join(lines) + '\n'
    print(text, end='')
    if args.out:
        open(args.out, 'w').write(text)


if __name__ == '__main__':
    main()
