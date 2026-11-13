#!/usr/bin/env python3
"""Sum several L1 builds (l1.json) into one for kit/heatmap.py: kit/merge_l1.py with Myth's stack range, the
lowest byte written in `$FF00-$FFFF` per build (Myth's stack sits under `$FFFF`, its turbo loader at `$FF01-$FFD6`:
give play windows, not loads, for that figure).

    python3 tools/merge_l1.py OUT.json L1 [L1 ...]
"""
import os
import sys

KIT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit', 'merge_l1.py')

if __name__ == '__main__':
    os.execv(sys.executable, [sys.executable, KIT] + sys.argv[1:] + ['--stack', 'FF00-FFFF'])
