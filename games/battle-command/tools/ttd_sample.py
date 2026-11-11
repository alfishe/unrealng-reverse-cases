#!/usr/bin/env python3
"""Samples memory of a recording frame by frame (TTD memory_at, the Z80 view at the frame's start, tinframe 0) from
the instance a re_session work folder holds, into one JSON line a frame ({"frame": F, "LLLL": "hex", ...}).

    python3 tools/ttd_sample.py --work W --frames A-B[:STEP] --range LO-HI [--range ...] --out F.jsonl

A sample of frame F is the state at the start of frame F: it shows what frame F-1 did. The checkout is $UNREAL_NG.
"""
import argparse, json, os, sys
sys.path.insert(0, os.path.join(os.environ['UNREAL_NG'], 'tools', 'verification', 'mcp'))
import mcplib
p = argparse.ArgumentParser()
p.add_argument('--work', required=True); p.add_argument('--frames', required=True)
p.add_argument('--range', action='append', required=True); p.add_argument('--out', required=True)
p.add_argument('--space', default='cpu')
a = p.parse_args()
st = json.load(open(os.path.join(a.work, 'session.json')))
s = mcplib.Session(f"http://127.0.0.1:{st['port_base'] + 200}/mcp", st['model'])
fr, _, step = a.frames.partition(':'); f0, _, f1 = fr.partition('-'); step = int(step or 1)
rs = [tuple(int(x, 16) for x in r.split('-')) for r in a.range]
with open(a.out, 'w') as out:
    for f in range(int(f0), int(f1 or f0) + 1, step):
        rec = {'frame': f}
        for lo, hi in rs:
            r = s.call('time_travel', {'action': 'memory_at', 'space': a.space, 'frame': f, 'tinframe': 0,
                                       'offset': lo, 'length': hi - lo + 1}, ok=False)
            stt = r.structured or {}
            if r.is_error or not stt.get('exact'):
                raise SystemExit(f'frame {f} {lo:x}: {r.text[:200]}')
            rec[f'{lo:04X}'] = stt['hex']
        out.write(json.dumps(rec) + '\n')
