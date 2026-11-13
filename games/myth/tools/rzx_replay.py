#!/usr/bin/env python3
"""A segment of the RZX Archive's Myth run (work/candidates/rzxarchive/myth.rzx, SPIN 0.5, 128K) as a normal
recording of our own, with its L1, replayed pass for pass rather than frame for frame.

Myth has no frame sync: a pass of the main loop takes about three frames, the IM 2 handler only steps the AY, and
the game's random word `$FE0A` is seeded from the R register. unreal-ng's 128K runs the passes at a slightly other
rate than the RZX's emulator, so keys held by frame number (tools/rzx_script.py) reach other passes, and R gives
other seeds: a frame-keyed replay leaves the run within a few hundred frames. This tool anchors both to the code:

- the keys: tools/rzx_inputs.py lists every IN of the run with its run count (OUT/reads.tsv) and the INs where a half
  row's keys change (OUT/changes.tsv). For each change an execution breakpoint stops on that IN's n-th run from the
  segment's start (`hits`), the keys are set as the RZX's value says, and the IN is stepped. So every IN reads what
  it read in the RZX, whatever the frame.
- the seeds: tools/rzx_seeds.py lists every store of a seed into `$FE0A` (the `LD ($FE0A),BC` after `LD A,R`) with
  its run count in its input block and the word the RZX's run stored. A breakpoint stops on that store's n-th run,
  the store is stepped, and the RZX's word is written over ours (a write to a variable, logged in record.json
  "pokes" as each POKE is; the image is never touched).

At each key change the game's state (room column `$FE21` and row `$FE22`, energy `$FE3F`, lives `$FE61`, score
`$F9FB`, the CRC-32 of the screen `$4000-$5AFF` and of the stage's variables `$6D00-$77FF`) is compared with the
RZX's at the same IN (changes.tsv); every difference is logged (record.json "diverged", "first"). After the last
change the machine runs on to the RZX's TO in frames. The machine: a fresh muted 128K loads the state when RZX frame
FROM begins (an input block's own snapshot work/stage1/rzx/snapN.z80 where FROM is the block's first frame, else
tools/rzx_inputs.py's work/stage2/rzx/snap-FROM.z80); the TTD records from there. Then end.szx, session.ttd, l1.json,
record.json, a screen at every --every frames passed, and tests/inputs/NAME.txt (the keys as held, by our frame,
as tools/record.py writes them; NAME is the work folder's name).

    python3 tools/rzx_replay.py FROM TO --work work/stage2/rec/NAME [--port-base 37470]
"""
import argparse
import bisect
import collections
import json
import os
import re
import sys
import time
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402
import rzx_script  # noqa: E402

RZX = os.path.join(CASE, 'work', 'stage2', 'rzx')
BLOCKS = os.path.join(CASE, 'work', 'stage1', 'rzx')
FIELDS = ('col', 'row', 'energy', 'lives', 'score', 'scr', 'vars')


def tsv(path):
    with open(path) as f:
        head = f.readline().split()
        for line in f:
            yield dict(zip(head, (int(x) for x in line.split())))


class Replay:
    def __init__(self, lab, work, every):
        self.lab, self.s, self.work, self.every = lab, lab.s, work, every
        self.keylog, self.pokes, self.moments, self.diverged, self.first = [], [], [], [], {}
        self.next_shot = 0

    def frame(self):
        t = self.s.call('analysis', {'action': 'status'}, ok=False).text
        m = re.search(r'frame (\d+)', t)
        return int(m.group(1)) if m else self.lab.frame

    def set_keys(self, rows, frame):
        keys = []
        for port, names in rzx_script.ROWS.items():
            v = rows.get(port, 0x1F)
            keys += [n for k, n in enumerate(names) if not v & (1 << k)]
        if sorted(keys) != sorted(self.lab.held):
            self.keylog.append((frame, keys))
            self.lab.keys(keys)

    def bp(self, pc, hits):
        r = self.s.call('control_execution', {'action': 'bp_add', 'type': 'execution', 'address': pc,
                                              'hits': str(hits)}, ok=False)
        return (r.structured or {}).get('id')

    def unbp(self, bid):
        self.s.call('control_execution', {'action': 'bp_remove', 'id': bid}, ok=False)

    def step(self):
        self.s.call('control_execution', {'action': 'step'}, ok=False)

    def run_to_break(self, limit_s):
        # the debug state's sequence before the resume: a breakpoint that stops the machine before the wait is
        # called still counts as a change since it
        w = self.s.call('control_execution', {'action': 'wait', 'timeout_ms': 0}, ok=False).text
        m = re.search(r'seq (\d+)', w or '')
        seq = int(m.group(1)) if m else 0
        self.s.call('control_execution', {'action': 'resume'}, ok=False)
        began = time.time()
        while time.time() - began < limit_s:
            w = self.s.call('control_execution', {'action': 'wait', 'timeout_ms': 30000, 'since': seq},
                            ok=False).text
            if 'breakpoint' in w:
                return self.lab.regs()['special']['pc']
        self.s.call('control_execution', {'action': 'pause'}, ok=False)
        return None

    def state(self):
        v = self.lab.read(0xFE21, 2) + self.lab.read(0xFE3F, 1) + self.lab.read(0xFE61, 1) + self.lab.read(0xF9FB, 2)
        return {'col': v[0], 'row': v[1], 'energy': v[2], 'lives': v[3], 'score': v[4] + 256 * v[5],
                'scr': zlib.crc32(self.lab.read(0x4000, 6912)), 'vars': zlib.crc32(self.lab.read(0x6D00, 0xB00))}

    def check(self, frame, want):
        now = self.state()
        bad = [k for k in FIELDS if now[k] != want[k]]
        for k in bad:
            self.first.setdefault(k, {'frame': frame, 'rzx_frame': want['frame']})
        if bad:
            self.diverged.append({'frame': frame, 'rzx_frame': want['frame'], 'fields': bad,
                                  'ours': {k: now[k] for k in bad if k not in ('scr', 'vars')},
                                  'rzx': {k: want[k] for k in bad if k not in ('scr', 'vars')}})

    def shots(self, frame):
        if frame >= self.next_shot:
            self.lab.shot(os.path.join(self.work, 'screens', f'{frame:06d}.png'))
            self.moments.append({'frame': frame})
            self.next_shot = (frame // self.every + 1) * self.every


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('start', type=int)
    ap.add_argument('stop', type=int)
    ap.add_argument('--work', required=True)
    ap.add_argument('--port-base', type=int, default=37470)
    ap.add_argument('--every', type=int, default=500)
    ap.add_argument('--no-build', action='store_true')
    a = ap.parse_args()
    work = os.path.abspath(a.work)
    os.makedirs(os.path.join(work, 'screens'), exist_ok=True)
    blocks = json.load(open(os.path.join(RZX, 'blocks.json')))
    block = bisect.bisect_right(blocks, a.start) - 1
    snap = (os.path.join(BLOCKS, f'snap{block}.z80') if a.start == blocks[block]
            else os.path.join(RZX, f'snap-{a.start:06d}.z80'))
    # the IN runs: each change's breakpoint is armed right after the change before it was stepped (the first at the
    # segment's start), so its hit count is the IN's runs from there to the change; the runs come from reads.tsv
    want = {}
    for c in tsv(os.path.join(RZX, 'changes.tsv')):
        if a.start <= c['frame'] < a.stop:
            want[(c['pc'], c['n'])] = c
    runs = collections.defaultdict(lambda: ([], []))   # pc: (lines, n) of its reads
    rows0, changes, line, start_line = {}, [], 0, 0
    for r in tsv(os.path.join(RZX, 'reads.tsv')):
        if r['frame'] >= a.stop:
            break
        line += 1
        lines, ns = runs[r['pc']]
        lines.append(line)
        ns.append(r['n'])
        if r['frame'] < a.start:
            if r['port'] in rzx_script.ROWS:
                rows0[r['port']] = r['value'] & 0x1F
            start_line = line
            continue
        c = want.get((r['pc'], r['n']))
        if c:
            c['line'] = line
            changes.append(c)

    def runs_at(pc, at):
        lines, ns = runs[pc]
        i = bisect.bisect_right(lines, at)
        return ns[i - 1] if i else 0

    for i, c in enumerate(changes):
        c['hits'] = c['n'] - runs_at(c['pc'], changes[i - 1]['line'] if i else start_line)
        c['rel'] = c['n'] - runs_at(c['pc'], start_line)
    seeds = [x for x in json.load(open(os.path.join(RZX, 'seeds.json')))['seeds'] if x['block'] == block]
    sbase = collections.Counter(x['site'] for x in seeds if x['rzx_frame'] < a.start)
    seeds = [dict(x, rel=x['n'] - sbase[x['site']], pc=int(x['site'][1:], 16)) for x in seeds
             if a.start <= x['rzx_frame'] < a.stop]
    lab = Lab(a.port_base, model='128K')
    lab.session_json(work)
    rp = Replay(lab, work, a.every)
    began = time.time()
    done = collections.Counter()   # runs of each seed store since the segment's start
    ki = si = 0
    kb = sb = None
    lost = None
    try:
        lab.load(snap)
        lab.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/settings/turbo_mode',
                                  'body': {'value': True}}, ok=False)
        lab.start_recording()
        lab.frame = 0
        rows = dict(rows0)
        rp.set_keys(rows, 0)
        rp.shots(0)
        while ki < len(changes) or si < len(seeds):
            if kb is None and ki < len(changes):
                c = changes[ki]
                kb = rp.bp(c['pc'], c['hits'])
            if sb is None and si < len(seeds):
                x = seeds[si]
                sb = rp.bp(x['pc'], x['rel'] - done[x['pc']])
            pc = rp.run_to_break(900)
            frame = rp.frame()
            if pc is None:
                lost = {'frame': frame, 'waiting_for': {'key': changes[ki] if ki < len(changes) else None,
                                                        'seed': seeds[si] if si < len(seeds) else None}}
                break
            if ki < len(changes) and pc == changes[ki]['pc'] and kb is not None:
                c = changes[ki]
                rp.unbp(kb)
                kb = None
                rp.check(frame, c)
                rows[c['port']] = c['value'] & 0x1F
                rp.set_keys(rows, frame)
                ki += 1
            elif si < len(seeds) and pc == seeds[si]['pc'] and sb is not None:
                x = seeds[si]
                rp.unbp(sb)
                sb = None
                done[pc] = x['rel']
                rp.step()
                v = x['value']
                lab.write(0xFE0A, bytes([v & 0xFF, v >> 8]))
                rp.pokes.append({'frame': frame, 'address': '$FE0A', 'bytes': [v & 0xFF, v >> 8],
                                 'why': f'the RZX run\'s seed after the store at {x["site"]} (run {x["rel"]})'})
                si += 1
                rp.shots(frame)
                continue
            else:
                lost = {'frame': frame, 'unexpected_pc': pc}
                break
            rp.step()
            rp.shots(frame)
        if lost is None:
            # after the last change, the frames the RZX still had to TO
            last_rzx = changes[-1]['frame'] if changes else a.start
            tail = a.stop - last_rzx
            f0 = rp.frame()
            while tail > 0:
                n = min(tail, a.every)
                lab.run(n)
                tail -= n
                rp.shots(f0 + (a.stop - last_rzx) - tail)
        lab.keys([])
        frames = rp.frame()
        lab.save(os.path.join(work, 'end.szx'))
        name = os.path.basename(work)
        sdir = work if 'rec-tmp' in work else os.path.join(CASE, 'tests', 'inputs')
        with open(os.path.join(sdir, f'{name}.txt'), 'w') as f:
            f.write(f'# The RZX Archive run (myth.rzx, 128K; someone else\'s play), RZX frames {a.start}-{a.stop - 1}, '
                    f'replayed pass for pass from {os.path.relpath(snap, CASE)} by tools/rzx_replay.py: the keys as '
                    f'held, by the recording\'s frame (each set on the IN that saw the change in the RZX); the seed '
                    f'writes are in record.json "pokes"\n')
            for fr, keys in rp.keylog:
                f.write(f'{fr} {" ".join(keys) if keys else "-"}\n')
            f.write(f'{frames} END\n')
        rec = {'plan': 'rzx_replay', 'note': __doc__.split('\n\n')[0], 'model': '128K',
               'start': os.path.relpath(snap, CASE), 'rzx_frames': [a.start, a.stop], 'frames': frames,
               'changes': len(changes), 'changes_done': ki, 'seeds': len(seeds), 'seeds_done': si, 'lost': lost,
               'first': rp.first, 'diverged_count': len(rp.diverged), 'diverged': rp.diverged[:200],
               'moments': rp.moments, 'pokes': rp.pokes, 'script': os.path.relpath(os.path.join(sdir, f'{name}.txt'),
                                                                                   CASE)}
        s = lab.s
        # a long segment's dump takes minutes (stage 1's 30 800 frames passed the default 120 s HTTP timeout)
        d = s.rpc('tools/call', {'name': 'time_travel', 'arguments': {
            'action': 'dump', 'path': os.path.join(work, 'session.ttd'), 'target': 'auto'}}, timeout=1800)
        rec['ttd'] = ''.join(c.get('text', '') for c in d.get('result', {}).get('content', [])).splitlines()[:2]
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        if not a.no_build:
            s.call('control_execution', {'action': 'bp_clear'}, ok=False)
            try:
                s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 1000}, ok=False)
            except OSError as e:
                rec['build_call'] = str(e)
            st = ''
            for _ in range(720):
                try:
                    st = s.call('analysis', {'action': 'status'}, ok=False).text
                except OSError:
                    st = ': running'
                if ': running' not in st and os.path.exists(os.path.join(work, 'l1.json')):
                    break
                time.sleep(10)
            rec['status'] = st.splitlines()[-3:]
        rec['seconds'] = round(time.time() - began)
        json.dump(rec, open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print(json.dumps({k: rec.get(k) for k in ('frames', 'changes', 'changes_done', 'seeds', 'seeds_done', 'lost',
                                                  'first', 'diverged_count', 'status', 'seconds')}, indent=1))
    finally:
        lab.close()


if __name__ == '__main__':
    main()
