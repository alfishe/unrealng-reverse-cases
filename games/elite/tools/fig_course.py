#!/usr/bin/env python3
"""The course of the three recordings (docs/10-gameplay-logic.md): what each was doing frame by frame, the ships
about, and the game's events.

    python3 tools/fig_course.py [OUT.png]

The lower band is the state sampled every 10 frames by tools/timeline.py (work/prof/<rec>-timeline.json): the title,
a docked screen (ViewIndex 4 + the ScreenTable entry, named above it), flight, witch space, the game over. The white line is the
count of occupied ship slots. The events are the first frames of routines in the recording's L1
(work/<rec>/l1.json): NewGame, SceneLaunch, SoundJump, SoundArrive, ShipsWreck.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402

RECS = [('d1', 'd1: docked at Lave, the screens, then the launch'),
        ('f1', 'f1: the launch, the station, the jump to Diso, empty space'),
        ('w1', 'w1: the launch, the misjump, four Thargoids, the death')]
SCREENS = {7: 'galactic chart', 8: 'short range chart', 9: 'data on a system', 10: 'market prices', 11: 'status',
           12: 'inventory'}
STATES = [('title', P.rgb((90, 90, 110))), ('docked screen', P.READ), ('flight', P.rgb((40, 120, 120))),
          ('witch space', P.rgb((170, 90, 220))), ('game over', P.rgb((150, 60, 60)))]
EVENTS = [('NewGame', 'new game (title left)'), ('SceneLaunch', 'launch'), ('SoundJump', 'jump'),
          ('SoundArrive', 'arrival'), ('ShipsWreck', 'death')]


def states(rows, death):
    """the state of each sample: the title until a docked screen, the title again once only slot 7 (the title's
    ship) is left after the death"""
    out, seen, title = [], False, False
    for r in rows:
        seen = seen or r['view'] >= 7
        if death and r['frame'] >= death:
            title = title or [x[0] for x in r['slots']] == [7]
            out.append('title' if title else 'game over')
        elif r['witch']:
            out.append('witch space')
        elif r['condition'] == 0:
            out.append('docked screen' if seen else 'title')
        else:
            out.append('flight')
    return out


def events(rec):
    names = {}
    for line in open(os.path.join(P.CASE, 'src', 'game', 'game.ann')):
        m = re.match(r'^\$([0-9A-F]{4}) c (\w+)', line)
        if m:
            names['$' + m.group(1)] = m.group(2)
    d = json.load(open(os.path.join(P.CASE, 'work', rec, 'l1.json')))
    out = []
    for x in d['routines']:
        n = names.get(x['entry'])
        for name, label in EVENTS:
            if n == name:
                out.append((x['profile']['first_frame'], label))
    return sorted(out)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else 'docs/img/logic/course.png'
    colour = dict(STATES)
    fig, axes = P.figure(9, 9.6, nrows=3, ncols=1, sharex=True)
    for ax, (rec, title) in zip(axes, RECS):
        rows = json.load(open(os.path.join(P.CASE, 'work', 'prof', rec + '-timeline.json')))
        ev = events(rec)
        death = next((f for f, label in ev if label == 'death'), None)
        st = states(rows, death)
        for i, r in enumerate(rows):
            end = rows[i + 1]['frame'] if i + 1 < len(rows) else r['frame'] + 10
            ax.broken_barh([(r['frame'], end - r['frame'])], (-2.6, 2.0), color=colour[st[i]], lw=0)
        ax.plot([r['frame'] for r in rows], [len(r['slots']) for r in rows], color=P.TEXT, lw=1.2)
        prev = None
        for r, s_ in zip(rows, st):
            v = r['view'] if s_ == 'docked screen' and r['view'] in SCREENS else None
            if v and v != prev:
                ax.text(r['frame'] + 8, 2.4, SCREENS[v], fontsize=8.5, color=P.READ, rotation=90, va='bottom')
            prev = v
        for k, (f, label) in enumerate(ev):
            ax.axvline(f, color=P.DIM, lw=0.8, ls='--')
            ax.text(f + 25, 8.6 - 1.1 * (k % 2), '%s %d' % (label, f), fontsize=9, color=P.TEXT, va='top')
        ax.set_ylim(-3.1, 8.8)
        ax.set_yticks([0, 2, 4, 6, 8])
        ax.set_ylabel('ships in slots')
        ax.set_title(title, fontsize=10.5, loc='left')
    axes[-1].set_xlabel('frame (50 a second)')
    axes[-1].set_xlim(0, 6700)
    handles = [P.plt.matplotlib.patches.Patch(color=c, label=n) for n, c in STATES]
    handles.append(P.plt.matplotlib.lines.Line2D([], [], color=P.TEXT, label='occupied slots (the station counts)'))
    fig.legend(handles=handles, loc='lower center', ncol=3, fontsize=9, frameon=False)
    fig.suptitle('The three recordings as games: what was on, how many ships,\nand when the events came', fontsize=12)
    fig.tight_layout(rect=(0, 0.06, 1, 1))
    P.save(fig, out)


if __name__ == '__main__':
    main()
