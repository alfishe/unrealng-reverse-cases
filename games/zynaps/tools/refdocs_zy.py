#!/usr/bin/env python3
"""kit/refdocs.py with the weapon recordings of docs/10 added to case.json's ref_builds (case.json unchanged).

    python3 tools/refdocs_zy.py

Adds work/zyB/w1 (tools/podbot.py --plan 0,1,2,2,3,4 from work/run/play-imm.szx, 5986 frames: every weapon taken)
and work/zyB/w2 (--plan 3, 7600 frames: homing missiles to the end of level 0 and into level 1) to the builds the
reference reads, so the weapon, pod and lockable routines show their runs. Then runs the kit's refdocs on this case.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.normpath(os.path.join(CASE, '..', '..', 'kit')))
import mkgame  # noqa: E402
import refdocs  # noqa: E402

EXTRA = [['zyB/w1', 'tools/podbot.py taking every weapon from work/run/play-imm.szx, 5986 frames'],
         ['zyB/w2', 'tools/podbot.py with homing missiles to the end of level 0, 7600 frames']]
load = mkgame.load_case


def load_case(case):
    config = load(case)
    config['ref_builds'] = list(config.get('ref_builds', [])) + EXTRA
    return config


mkgame.load_case = load_case
sys.argv = [sys.argv[0], '--case', CASE]
refdocs.main()
