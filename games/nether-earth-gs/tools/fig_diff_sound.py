#!/usr/bin/env python3
"""Nether Earth's beeper against the GS card, event by event (docs/img/diff/sound-timeline.png), and what each sound
call costs the CPU in each edition (docs/img/diff/sound-cost.png).

    python3 tools/fig_diff_sound.py timeline [--out PNG]
    python3 tools/fig_diff_sound.py cost [--out PNG]

timeline: two windows of the tape game work/gsB/rT, the construction menu (frames 230-900) and a fight (frames
32440-32900). Three lanes each:

  NE beeper   modelled. The game's logic is NE's byte for byte, so the same events reach Beep and SoundFx. In the
              menu, each GS play's id gives NE's beep: 256 x (13A + 50) T at 3.5 MHz, the game halted while it
              sounds. In the fight, SoundFx $FD53 is read from the memory of every frame (work/gsB/cache/rT-fight.npz)
              and NE's PlayInterrupt is replayed on it: fresh writes taken from the game, then NE's count (positive
              up to $7F: the shot's sweep; negative to $FF: noise), with no clearing.
  GS tape     measured: the plays of work/gsB/an/rT-plays.json, each as long as the effect sounds in its render at
              note 47 (work/gsB/audio/gs-fx47-NN.wav, the time above 3 % of the peak). Effects start on a free
              channel, so they overlap.
  GS disk     the same ids would be sent (the code is the same but for the driver's bank); the disk driver's race
              loses every effect (docs/09-sound.md 9.5): ticks, no sound.

cost: L1 call counts and T-states of NE work/deep, the disk work/gsB/rD and deep recordings and the tape work/gsB/rT,
as given in docs/13-differences-from-nether-earth.md 13.7 (the bars of the left panel, the shares of the right).
"""

import argparse
import json
import os
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

plt.rcParams['text.parse_math'] = False
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
GS = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, HERE)
import fig_sound as F  # noqa: E402

BG, TEXT, DIM = '#0e0e14', '#d2d2dc', '#787887'
GS_FRAME = 71680 / 3500000                    # Pentagon
NE_FRAME = 69888 / 3500000                    # 48K
SOUNDFX = 0xFD53

# effect -> (NE Beep id(s) or None, label)
MENU = {10: ([0x14], 'cursor $14'), 11: ([0x64], 'choice $64'), 9: ([0x78], 'order $78'),
        12: (list(range(0x50, 0x13, -5)), 'START ROBOT chirp $50..$14'), 1: ([0xC8], 'robot leaves $C8'),
        5: (None, 'menu opens: NE silent')}
FX_COLOR = {10: '#26c6da', 11: '#4dd0e1', 9: '#7986cb', 12: '#ba68c8', 1: '#9575cd', 5: '#5c6bc0',
            6: '#f2e86d', 7: '#e8d84d', 13: '#e8913a', 3: '#e5534b', 4: '#c62828', 14: '#9c4dcc'}


def beep_seconds(ids):
    return sum(256 * (13 * a + 50) for a in ids) / 3500000


def effect_lengths():
    out = {}
    for n in range(1, 15):
        x, sr = F.read_wav(os.path.join(GS, f'work/gsB/audio/gs-fx47-{n:02d}.wav'))
        a, b = F.sounding(x, sr)
        out[n] = b - a
    return out


def ne_fight(npz):
    """NE's SoundFx replayed on the GS's frames: [(frame, kind)] for each frame NE sounds, plus the GS sends"""
    z = np.load(npz)
    frames = z['frames']
    s = z['mems'][:, SOUNDFX - 0x4000].astype(int)
    gs_after = ne_after = 0
    ne_sound, gs_sends = [], []
    for f, v in zip(frames, s):
        fresh = v != gs_after
        # the GS: count, send at 2 / $FD / $C9 and clear
        g = 0 if v == 0 else (v + 1) & 0xFF
        if 0 < v < 0x80 and g >= 0x80:
            g = 0
        if g in (2, 0xFD, 0xC9):
            gs_sends.append((int(f), g))
            g = 0
        gs_after = g
        # NE: the same writes, its own count, no clearing
        n = v if fresh else ne_after
        n2 = 0 if n == 0 else (n + 1) & 0xFF
        if 0 < n < 0x80 and n2 >= 0x80:
            n2 = 0
        ne_after = n2
        if n2:
            ne_sound.append((int(f), 'sweep' if n2 < 0x80 else 'noise'))
    return ne_sound, gs_sends


def lane_style(ax, lo, hi, lanes):
    ax.set_facecolor('#15151c')
    ax.set_xlim(lo, hi)
    ax.set_ylim(-0.6, len(lanes) - 0.4)
    ax.set_yticks(range(len(lanes)))
    ax.set_yticklabels(lanes, color=TEXT, fontsize=8.5)
    ax.tick_params(colors=DIM, labelsize=8)
    for sp in ax.spines.values():
        sp.set_color(DIM)


def fig_timeline(args):
    plays = json.load(open(os.path.join(GS, 'work/gsB/an/rT-plays.json')))
    length = effect_lengths()
    fig, axes = plt.subplots(2, 1, figsize=(14, 8.4), facecolor=BG,
                             gridspec_kw=dict(hspace=0.62, left=0.08, right=0.98, top=0.9, bottom=0.12))
    lanes = ['GS disk', 'GS tape', 'NE beeper']
    # the menu window
    ax = axes[0]
    lo, hi = 230, 900
    lane_style(ax, lo, hi, lanes)
    seen = set()
    halted = 0.0
    for p in plays:
        if not lo <= p['frame'] < hi:
            continue
        e, f = p['effect'], p['frame']
        ids, lab = MENU.get(e, (None, str(e)))
        k = (f, e)
        ax.broken_barh([(f, length[e] / GS_FRAME)], (0.7, 0.6), color=FX_COLOR[e], alpha=0.75)
        ax.plot([f, f], [-0.25, 0.25], color=FX_COLOR[e], lw=1.4)
        if ids:
            sec = beep_seconds(ids)
            halted += sec
            ax.broken_barh([(f, sec / NE_FRAME)], (1.7, 0.6), color=FX_COLOR[e], hatch='///', edgecolor=BG)
        seen.add(e)
    ax.text(hi - 2, -0.45, 'every command sent, none played (the #40 / #39 race)', ha='right', fontsize=7.5,
            color=DIM)
    ax.set_title(f'The construction menu, frames {lo}-{hi} of work/gsB/rT: NE\'s beeps (hatched) halt the game, '
                 f'{halted:.2f} s here; the GS effects run on and the game does not wait', color=TEXT,
                 fontsize=9.5, loc='left')
    ax.set_xlabel('frame (GS Pentagon frames; NE bars in NE frames of 20 ms from the same start)', color=DIM,
                  fontsize=8)
    ax.legend([plt.Rectangle((0, 0), 1, 1, color=FX_COLOR[e]) for e in sorted(seen)],
              [f'{e}: {MENU[e][1]}' for e in sorted(seen)], loc='upper center', bbox_to_anchor=(0.5, -0.2), ncol=6,
              frameon=False, labelcolor=TEXT, fontsize=7.5)
    # the fight window
    ax = axes[1]
    lo, hi = 32440, 32900
    lane_style(ax, lo, hi, lanes)
    ne, sends = ne_fight(os.path.join(GS, 'work/gsB/cache/rT-fight.npz'))
    for kind, col in (('sweep', '#f2e86d'), ('noise', '#e8913a')):
        fr = [f for f, k in ne if k == kind]
        ax.broken_barh([(f, 1) for f in fr], (1.7, 0.6), color=col)
    model = {(f, {2: 'shot', 0xFD: 'end', 0xC9: 'kill'}[v]) for f, v in sends}
    measured = set()
    for p in plays:
        if not lo <= p['frame'] < hi:
            continue
        e, f = p['effect'], p['frame']
        measured.add((f, {6: 'shot', 7: 'shot', 8: 'shot', 13: 'end', 2: 'kill', 3: 'kill', 4: 'kill'}[e]))
        ax.broken_barh([(f, length[e] / GS_FRAME)], (0.7, 0.6), color=FX_COLOR[e], alpha=0.45)
        ax.plot([f, f], [0.7, 1.3], color=FX_COLOR[e], lw=1.6)
        ax.plot([f, f], [-0.25, 0.25], color=FX_COLOR[e], lw=1.4)
    if model != measured:
        raise SystemExit(f'the SoundFx model does not give the measured sends: {sorted(model ^ measured)}')
    ne_frames = len(ne)
    ax.set_title(f'A fight, frames {lo}-{hi}: NE sounds {ne_frames} of {hi - lo} frames (the shot\'s sweep runs '
                 f'until the next event); the GS plays {len(measured)} effects, hit and miss alike (13)', color=TEXT,
                 fontsize=9.5, loc='left')
    ax.set_xlabel('frame of work/gsB/rT', color=DIM, fontsize=8)
    handles = [plt.Rectangle((0, 0), 1, 1, color='#f2e86d'), plt.Rectangle((0, 0), 1, 1, color='#e8913a'),
               plt.Rectangle((0, 0), 1, 1, color=FX_COLOR[6]), plt.Rectangle((0, 0), 1, 1, color=FX_COLOR[13]),
               plt.Rectangle((0, 0), 1, 1, color=FX_COLOR[3])]
    ax.legend(handles, ['NE shot sweep (SoundFx 2..$7F)', 'NE noise (miss 3, hit 5, kill 55 frames)',
                        'GS shot 6 / 7', 'GS end 13 (hit or miss)', 'GS kill 3 / 4'], loc='upper center',
              bbox_to_anchor=(0.5, -0.22), ncol=5, frameon=False, labelcolor=TEXT, fontsize=7.5)
    fig.suptitle('The same events, three sounds: NE\'s beeper (modelled on the same game), the GS tape (measured), '
                 'the GS disk (lost)', color=TEXT, fontsize=11, x=0.01, ha='left')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, dpi=100, facecolor=BG)
    print('wrote', args.out, 'NE sounding frames', ne_frames, 'GS plays', len(measured), 'menu NE halted',
          round(halted, 3))


# (routine, NE, GS disk, GS tape): T-states a call, from the L1 tables of the three recordings
COST = [('Beep (menus)', 211012, 492, 7776),
        ('SoundEffect (play)', 8398, 939, 10116),
        ('GsSound (bridge + driver)', None, 615, 9801)]
SHARE = [('NE work/deep', 36046, 54.65e6 + 11.39e6),
         ('GS disk deep', 24588, 127643 + 144608),
         ('GS tape rT', 40134, 443 * 7776 + 652 * 10116)]


def fig_cost(args):
    fig, axes = plt.subplots(1, 2, figsize=(13, 4.6), facecolor=BG,
                             gridspec_kw=dict(width_ratios=[1.6, 1], wspace=0.55, left=0.17, right=0.97, top=0.82,
                                              bottom=0.14))
    ax = axes[0]
    ax.set_facecolor(BG)
    cols = [('NE', '#3d6b47'), ('GS disk', '#26c6da'), ('GS tape', '#e8913a')]
    for i, (name, *vals) in enumerate(COST):
        for j, ((lab, col), v) in enumerate(zip(cols, vals)):
            y = len(COST) - 1 - i + (1 - j) * 0.26
            if v is None:
                ax.text(60, y, 'none', va='center', fontsize=7, color=DIM)
                continue
            ax.barh(y, v, height=0.24, color=col, label=lab if i == 0 else None)
            ax.text(v * 1.12, y, f'{v:,.0f} T', va='center', fontsize=7, color=TEXT)
    ax.set_xscale('log')
    ax.set_xlim(50, 3e6)
    from matplotlib.ticker import FuncFormatter
    ax.xaxis.set_major_formatter(FuncFormatter(lambda v, _: f'{v:,.0f}'))
    ax.set_yticks(range(len(COST)))
    ax.set_yticklabels([c[0] for c in COST][::-1], color=TEXT, fontsize=8.5)
    ax.axvline(71680, color='#e5534b', lw=0.8, ls='--')
    ax.text(71680 * 1.1, len(COST) - 0.45, 'one frame', color='#e5534b', fontsize=7)
    ax.tick_params(colors=DIM, labelsize=8)
    for sp in ax.spines.values():
        sp.set_color(DIM)
    ax.legend(loc='lower right', frameon=False, labelcolor=TEXT, fontsize=8)
    ax.set_title('T-states a call (log scale)', color=TEXT, fontsize=9.5, loc='left')
    ax = axes[1]
    ax.set_facecolor(BG)
    for i, (name, frames, t) in enumerate(SHARE):
        share = t / (frames * (69888 if name.startswith('NE') else 71680))
        ax.barh(len(SHARE) - 1 - i, share * 100, color=cols[i][1], height=0.55)
        ax.text(share * 100 + 0.03, len(SHARE) - 1 - i, f'{share:.2%}', va='center', fontsize=8, color=TEXT)
    ax.set_yticks(range(len(SHARE)))
    ax.set_yticklabels([s[0] for s in SHARE][::-1], color=TEXT, fontsize=8.5)
    ax.set_xlim(0, 0.3 + max(t / (f * 69888) for _, f, t in SHARE) * 100)
    ax.tick_params(colors=DIM, labelsize=8)
    for sp in ax.spines.values():
        sp.set_color(DIM)
    ax.set_title('Beep + SoundEffect: share of all the CPU\'s time', color=TEXT, fontsize=9.5, loc='left')
    ax.set_xlabel('% of the recording\'s T-states', color=DIM, fontsize=8)
    fig.suptitle('What a sound costs: NE\'s beeper loops against the GS bridge (disk: no wait; tape: waits for the '
                 'card with interrupts off)', color=TEXT, fontsize=11, x=0.01, ha='left')
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    fig.savefig(args.out, dpi=100, facecolor=BG)
    print('wrote', args.out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    t = sub.add_parser('timeline')
    t.add_argument('--out', default=os.path.join(GS, 'docs/img/diff/sound-timeline.png'))
    c = sub.add_parser('cost')
    c.add_argument('--out', default=os.path.join(GS, 'docs/img/diff/sound-cost.png'))
    a = ap.parse_args()
    {'timeline': fig_timeline, 'cost': fig_cost}[a.cmd](a)


if __name__ == '__main__':
    main()
