#!/usr/bin/env python3
"""The keys to hold in our replay of the RZX archive's run, frame by frame (RZX frame numbers): the player's own keys
(tools/rzx_script.frame_keys), except in each level's READY? wait. There the RZX's game was started by SPIN's own
port `$DF` reads (any non-idle value counts as a key in the wait `$B6DD`), which our machine does not give; so from
the RZX's level change to 10 frames before its play start (tools/rzx_levels.py: plays.tsv, levels.tsv) no key is
held, and B (a key no control uses) is held for the two frames 10 and 9 before it: our wait then ends on the frame
the RZX's did, and the timer `$AB04` first counts down on the RZX's play-start frame (work/stage1/ready_probe.py).

    from rzx_keys import replay_keys; keys = replay_keys(first_frame, last_frame)   # {frame: [keys]}
"""
import json
import os

from rzx_script import frame_keys

HERE = os.path.dirname(os.path.abspath(__file__))
RZX = os.path.join(os.path.dirname(HERE), 'work', 'stage1', 'rzx')
LEAD = 10


def starts():
    plays = [tuple(map(int, l.split())) for l in open(os.path.join(RZX, 'levels', 'plays.tsv')) if not l.startswith('#')]
    lchg = [int(l.split()[0]) for l in open(os.path.join(RZX, 'levels', 'levels.tsv')) if not l.startswith('#')]
    return plays, lchg


def replay_keys(a, b, reads=None):
    if reads is None:
        reads = json.load(open(os.path.join(RZX, 'inputs.json')))['reads']
    fk = frame_keys(reads, a, b)
    plays, lchg = starts()
    for p, _ in plays:
        prev = [c for c in lchg if c < p]
        if not prev or not (a < p <= b + LEAD):
            continue
        for f in range(prev[-1] + 1, p - LEAD + 1):
            if f in fk:
                fk[f] = []
        for f in (p - LEAD + 1, p - LEAD + 2):
            if f in fk:
                fk[f] = ['B']
    return fk
