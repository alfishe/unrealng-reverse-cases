#!/usr/bin/env python3
"""The last N frames before a reset: find the frame where a recording's game fell into the ROM's start, build L1
over the window just before it, and say who jumped there and what ran last.

    python3 ../../kit/last_frames.py --work W [--l1 L1] [--frames 100] [--into W2]      the reset found in L1
    python3 ../../kit/last_frames.py --work W --reset F [--frames 100] [--into W2]       the frame given
    python3 ../../kit/last_frames.py --l1 L1                                             find and report only

A game that crashes (a stack run into the ROM, a jump through a broken table) usually ends at `$0000`: the ROM's
start runs, its RAM test reads and writes every byte, and the game's state is gone. The TTD recording still holds
every frame up to that moment, and an L1 built over a short window before it names the routines that ran last and
the jump that reached `$0000` (Enduro Racer `reset3`: on stage 3 a high jump takes RoadTopRow below 0 and the row
builder writes past its table; work/stage1/crashseg.py found it the long way).

The reset frame: the last frame in which the routine at `$0000` on a ROM page ran (L1's routine profile; a recording
from power-on runs it at frame 0 too, which is not a reset), from --l1 (default W/l1.json, the whole recording's
build). --reset F gives it. Then, with --work W (a re_session work folder whose instance holds the recording:
`kit/rs.py open --work W --ttd session.ttd`), `kit/rs.py build --work W --from-frame F-N --to-frame F+1 --into W2`
(W2 defaults to W/last-F) and the report from W2/l1.json:

  - the calls into `$0000` (the caller, the kind, the sites) and into the ROM's other restart entries;
  - the routines outside the ROM that ran in the last frames before the reset, the latest first (entry, first and
    last frame, entries);
  - the build's own review (W2/review.txt, W2/findings.txt) for the rest.

--dry-run prints the build command and stops. Frames are the recording's (a window's L1 keeps them).
"""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def rom_pages(doc):
    return {p['page'] for p in doc.get('pages', []) if p.get('name', '').startswith('ROM')} or \
        {p['page'] for p in doc.get('pages', []) if p['page'] >= 256}


def reset_frames(doc):
    """[(frame, page)] the frames where the ROM's $0000 ran and was a reset (not the power-on of frame 0)"""
    roms, out = rom_pages(doc), []
    first = doc['replay'].get('first_frame', 0)
    for r in doc['routines']:
        if r['entry'] != '$0000' or r['page'] not in roms:
            continue
        p = r['profile']
        last = p.get('last_frame', 0)
        if last > first or p.get('first_frame', 0) > first or first > 0:
            out.append((last, r['page']))
    return sorted(out)


def report(doc, reset, lines=24, out=print):
    routines, roms = doc['routines'], rom_pages(doc)
    out(f'L1 frames {doc["replay"].get("first_frame")}-{doc["replay"].get("last_frame")}, the reset at frame {reset}')
    starts = {i for i, r in enumerate(routines) if r['page'] in roms and r['entry'] in ('$0000', '$0008', '$0038')}
    for c in doc.get('calls', []):
        if c['callee'] in starts and routines[c['caller']]['page'] not in roms:
            caller, callee = routines[c['caller']], routines[c['callee']]
            out(f'  into {callee["entry"]}: from the routine at {caller["entry"]} (page {caller["page"]}), '
                f'{c["kind"]} x{c["count"]} at {", ".join(c.get("sites", []))}')
    ran = [r for r in routines if r['page'] not in roms and r['profile'].get('last_frame', -1) <= reset]

    def line(r):
        p = r['profile']
        return (f'    {r["entry"]} p{r["page"]} {r["kinds"]:<16} frames {p.get("first_frame")}-{p.get("last_frame")}'
                f'  x{p.get("entries")}')
    first = doc['replay'].get('first_frame', 0)
    new = [r for r in ran if r['profile'].get('first_frame', 0) > first]
    new.sort(key=lambda r: (-r['profile'].get('first_frame', 0), r['entry']))
    out('  code first run after the window\'s first frame, the latest first (the crash\'s path: code that never ran '
        'before; entry, page, kinds, frames, entries):')
    for r in new[:lines]:
        out(line(r))
    if not new:
        out('    none')
    ran.sort(key=lambda r: (-r['profile'].get('last_frame', 0), -r['profile'].get('entries', 0)))
    out('  the routines outside the ROM that ran last, the latest first:')
    for r in ran[:lines]:
        out(line(r))


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0], epilog=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--work', help='the re_session work folder whose instance holds the recording')
    p.add_argument('--l1', help='the whole recording\'s L1 (default W/l1.json)')
    p.add_argument('--reset', type=int, help='the reset\'s frame (default: found in the L1)')
    p.add_argument('--frames', type=int, default=100, help='the window before the reset (default 100)')
    p.add_argument('--into', help='the window\'s folder (default W/last-F)')
    p.add_argument('--lines', type=int, default=24, help='routines to list (default 24)')
    p.add_argument('--dry-run', action='store_true', help='print the build command, run nothing')
    args = p.parse_args()
    l1 = args.l1 or (os.path.join(args.work, 'l1.json') if args.work else None)
    reset = args.reset
    if reset is None:
        if not l1 or not os.path.exists(l1):
            sys.exit('last_frames: give --l1 (or --work W with W/l1.json), or --reset F')
        doc = json.load(open(l1))
        found = reset_frames(doc)
        if not found:
            sys.exit(f'last_frames: {l1}: the ROM\'s $0000 never ran after the power-on: no reset in the recording')
        reset = found[-1][0]
        print(f'{l1}: the ROM\'s $0000 ran at frame {reset}' + (f' (and at {", ".join(str(f) for f, _ in found[:-1])})'
                                                               if len(found) > 1 else ''))
        if not args.work:
            report(doc, reset, args.lines)
            return 0
    if not args.work:
        sys.exit('last_frames: --work W (an instance holding the recording) to build the window')
    start = max(0, reset - args.frames)
    into = args.into or os.path.join(args.work, f'last-{reset}')
    cmd = [sys.executable, os.path.join(HERE, 'rs.py'), 'build', '--work', args.work, '--from-frame', str(start),
           '--to-frame', str(reset + 1), '--into', into]
    print(' '.join(cmd))
    if args.dry_run:
        return 0
    r = subprocess.run(cmd)
    if r.returncode:
        sys.exit(f'last_frames: the build failed ({r.returncode})')
    report(json.load(open(os.path.join(into, 'l1.json'))), reset, args.lines)
    print(f'review: {os.path.join(into, "review.txt")}, {os.path.join(into, "findings.txt")}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
