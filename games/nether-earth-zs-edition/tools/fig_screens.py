#!/usr/bin/env python3
"""The screenshots of docs 01 / 05 / 06: real frames of the case's recordings, 2x nearest neighbour.

    python3 tools/fig_screens.py [--port-base 16530] [--only NAME ...]

Writes docs/img/screens/<name>.png for every row of SHOTS (recording, frame), the sheets of SHEETS (a few frames side
by side, a short title over each) and the two intro GIFs of GIFS. tools/fig_common.py launches its own unreal-qt,
loads each recording and takes the screen at the end of the named frame. The recordings: fig_common.RECORDINGS
(stage 1 r98 / r99 / r99-48, the Scorpion runs s98 / s99, and this part's x98 / x99, made with
`re_session.py capture` from work/stage2/texts/inputs/x98.txt and x99.txt).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_common as F  # noqa: E402

OUT = os.path.join(F.ROOT, 'docs', 'img', 'screens')

# name: (recording, frame)
SHOTS = {
    # the '98
    '98-trdos-run': ('r98', 1903),
    '98-presents': ('r98', 2060),
    '98-intro': ('r98', 3000),
    '98-menu': ('r98', 4703),
    '98-play': ('r98', 5500),
    '98-load-new-level': ('x98', 5000),
    '98-load-new-level-start': ('x98', 5600),
    # the '99, Pentagon 128
    '99-trdos-boot': ('r99', 102),
    '99-intro-unpack': ('r99', 652),
    '99-intro': ('r99', 1002),
    '99-intro-wipe': ('r99', 1552),
    '99-system-checking': ('r99', 2652),
    '99-menu': ('r99', 3002),
    '99-menu-hard-phasers': ('r99', 6052),
    '99-description': ('r99', 4152),
    '99-advices': ('r99', 4552),
    '99-greets': ('r99', 4852),
    '99-about': ('r99', 5152),
    '99-load-map': ('r99', 5452),
    '99-load-map-nelev06': ('x99', 4127),
    '99-redefine': ('x99', 3477),
    '99-play-nelev00': ('r99', 6402),
    '99-play-nelev06': ('x99', 4602),
    '99-abort-to-menu': ('x99', 5302),
    # the '99 on Scorpion ZS-256 and on the 48 K path
    '99-system-checking-scorpion': ('s99', 2252),
    '99-play-builtin-scorpion': ('s99', 3302),
    '99-48-system-checking': ('r99-48', 5651),
    '99-48-end': ('r99-48', 6501),
}

# name: [(recording, frame, title), ...]
SHEETS = {
    'system-checking': [('r99', 2652, 'Pentagon 128'), ('s99', 2252, 'Scorpion ZS-256'),
                        ('r99-48', 5651, '48 BASIC, paging locked')],
    '99-text-pages': [('r99', 4152, 'DESCRIPTION'), ('r99', 4552, 'ADVICES'),
                      ('r99', 4852, 'GREETS'), ('r99', 5152, 'ABOUT ZS NE')],
}

# name: (recording, first frame, last frame, step, milliseconds a picture)
GIFS = {
    '98-intro-scroller': ('r98', 2400, 2700, 3, 60),
    '99-intro-scroller': ('r99', 900, 1300, 4, 80),
}


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--port-base', type=int, default=16530)
    p.add_argument('--only', nargs='*')
    args = p.parse_args()
    os.makedirs(OUT, exist_ok=True)
    wanted = set(args.only or [])

    def want(name):
        return not wanted or name in wanted

    with F.Recordings(args.port_base) as rec:
        for name, (recording, frame) in SHOTS.items():
            if want(name):
                F.scaled(rec.frame(recording, frame)).save(os.path.join(OUT, name + '.png'))
                print(name, recording, frame)
        for name, panels in SHEETS.items():
            if want(name):
                images = [rec.frame(r, f) for r, f, _t in panels]
                F.titled_row(images, [t for _r, _f, t in panels]).save(os.path.join(OUT, name + '.png'))
                print(name, panels)
        for name, (recording, first, last, step, ms) in GIFS.items():
            if want(name):
                pictures = [F.with_counter(F.scaled(rec.frame(recording, f)), f'{recording} frame {f}')
                            for f in range(first, last + 1, step)]
                durations = [ms] * len(pictures)
                durations[0] = durations[-1] = 1000
                path = os.path.join(OUT, name + '.gif')
                F.save_gif(path, pictures, durations)
                print(name, recording, first, last, step, os.path.getsize(path))


if __name__ == '__main__':
    main()
