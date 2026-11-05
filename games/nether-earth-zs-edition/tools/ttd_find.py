#!/usr/bin/env python3
"""Binary search over a recording's frames for the first frame at whose end memory matches, by time_travel
memory_at on the instance a work folder holds.

  ttd_find.py --work W --from F --to G --addr ADDR --hex BYTES [--space cpu] [--not]
      the first frame in [F, G] whose end holds BYTES at ADDR (--not: no longer holds them); assumes the condition,
      once true, stays true
  ttd_find.py --work W --read F[:T] ADDR LEN      the bytes at frame F (T-state T) as hex
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402


def session(work):
    st = json.load(open(os.path.join(work, 'session.json')))
    return mcplib.Session(f"http://127.0.0.1:{st['port_base'] + 200}/mcp", st['model'])


def read(s, frame, addr, length, tinframe=None, space='cpu'):
    body = {'action': 'memory_at', 'space': space, 'frame': frame, 'offset': addr, 'length': length}
    if tinframe is not None:
        body['tinframe'] = tinframe
    r = s.call('time_travel', body, ok=False)
    st = r.structured or {}
    if r.is_error or len(st.get('hex', '')) != 2 * length:
        raise SystemExit(f'memory_at {frame}: {(r.text or "")[:300]}')
    return bytes.fromhex(st['hex'])


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', required=True)
    p.add_argument('--from', dest='lo', type=int)
    p.add_argument('--to', dest='hi', type=int)
    p.add_argument('--addr')
    p.add_argument('--hex')
    p.add_argument('--space', default='cpu')
    p.add_argument('--not', dest='neg', action='store_true')
    p.add_argument('--read', nargs=3, metavar=('F[:T]', 'ADDR', 'LEN'))
    a = p.parse_args()
    s = session(a.work)
    if a.read:
        f, _, t = a.read[0].partition(':')
        print(read(s, int(f), int(a.read[1], 16), int(a.read[2]), int(t) if t else None, a.space).hex())
        return
    want = bytes.fromhex(a.hex)
    addr = int(a.addr, 16)
    ok = lambda f: (read(s, f, addr, len(want), space=a.space) == want) != a.neg
    lo, hi = a.lo, a.hi
    if not ok(hi):
        raise SystemExit(f'not true at {hi}')
    if ok(lo):
        print(lo)
        return
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if ok(mid):
            hi = mid
        else:
            lo = mid
    print(hi)


if __name__ == '__main__':
    main()
