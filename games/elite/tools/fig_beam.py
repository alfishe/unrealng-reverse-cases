#!/usr/bin/env python3
"""kit/beam_timeline.py with its text three points larger, so that a 1064 px picture keeps 12 px text when GitHub
shows it 900 px wide (docs/04-game-loop.md 4.5). Same arguments as the kit tool.

    python3 tools/fig_beam.py --trace work/f1/traces/1500_0-1503_0.uatr --listing build/game.lst \
        --machine 48k --frames 3 --out docs/img/loop/beam-pass.png --title TEXT
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import beam_timeline as BT  # noqa: E402

_font = K.font
K.font = lambda size: _font(size + 3)

if __name__ == '__main__':
    sys.exit(BT.main())
