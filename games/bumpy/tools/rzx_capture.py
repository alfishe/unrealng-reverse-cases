#!/usr/bin/env python3
"""The RZX archive's run as our own recordings, one a level: tools/record.py rzx --rzx K K for each play-start row K
of work/stage1/rzx/levels/plays.tsv (rows 0-100: levels 0-99 and the second loop's level 0, which row 99 already
reaches, so row 100 is skipped), into work/stage1/rzx/lNN/ (NN the level). A row whose l1.json exists is skipped.

    python3 tools/rzx_capture.py --port-base 37510 --rows 0-49
"""
import argparse
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port-base', type=int, required=True)
    ap.add_argument('--rows', default='0-99')
    a = ap.parse_args()
    lo, hi = map(int, a.rows.split('-'))
    plays = [l.split() for l in open(os.path.join(CASE, 'work', 'stage1', 'rzx', 'levels', 'plays.tsv'))
             if not l.startswith('#')]
    for k in range(lo, min(hi, 99) + 1):
        level = int(plays[k][1])
        work = os.path.join(CASE, 'work', 'stage1', 'rzx', f'l{level:02d}')
        if os.path.exists(os.path.join(work, 'l1.json')):
            continue
        cmd = [sys.executable, os.path.join(HERE, 'record.py'), 'rzx', '--rzx', str(k), str(k), '--work', work,
               '--port-base', str(a.port_base)]
        with open(work + '.log', 'w') as log:
            rc = subprocess.run(cmd, cwd=CASE, stdout=log, stderr=subprocess.STDOUT).returncode
        print(k, level, 'rc', rc, flush=True)


if __name__ == '__main__':
    main()
