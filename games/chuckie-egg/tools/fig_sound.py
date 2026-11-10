#!/usr/bin/env python3
"""Figures, measurements and rendered audio of docs/09-sound.md, from the sound events of the recordings
(tools/sound_events.py). Output in docs/img/sound/.

    python3 tools/fig_sound.py table      every Beep site, tune and phrase measured, printed as tables
    python3 tools/fig_sound.py effects    effects.png: one call of each Beep site, the speaker bit against time
    python3 tools/fig_sound.py sweep      sweep.png: the pickup sweep and the jump click, pitch against time
    python3 tools/fig_sound.py tunes      tunes.png: the title and death tunes, the file's notes and the BEEPER calls
    python3 tools/fig_sound.py speech     speech.png: four phrases as sent, the hold of each allophone against
                                          its SP0256-AL2 duration
    python3 tools/fig_sound.py phrases    phrases.png: the 33 phrases, held time against the datasheet's sum
    python3 tools/fig_sound.py cost       cost.png: T-states a frame in Beep (levels-1-3) and the interrupts BEEPER
                                          loses (c1)
    python3 tools/fig_sound.py wav        *.wav: each sound from its measured speaker edges, 44 100 Hz mono 16 bit
                                          (never played here)
    python3 tools/fig_sound.py waves      waves.png: every WAV drawn against time
    python3 tools/fig_sound.py all

The events (--events, default work/docs/ceD): l13-events.json (levels-1-3 frames 0-7023), c1-events.json (c1 frames
5280-8916), idle-1p-4700-5400-events.json, tour-type2-0-1000-events.json, gameover-name-38900-39800-events.json
(`tools/sound_events.py --work W --frames F0-F1`, W an instance holding the recording, work/docs/ceD/run_traces.sh).
A frame is 69 888 T at 3.5 MHz; one interrupt a frame (20 ms).
"""
import argparse
import bisect
import json
import math
import os
import re
import struct
import wave
from collections import defaultdict

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'sound')
EVENTS = os.path.join(CASE, 'work', 'docs', 'ceD')
CLOCK = 3500000
FT = 69888
RATE = 44100
DPI = 100
WIDTH = 10.5  # inches: 1050 px

BEEP_OUTS = (0x9CA6, 0x9CAC)     # Beep's OUT high / OUT low
BEEPER_OUT = 0x03E1              # the ROM's BEEPER toggles the speaker here
LOOP_CALLERS = (0x9CB2, 0x9CE9)  # Beep's JR NZ back to its label, an interrupt's RETI into the loop
SITES = {
    0x9D6A: ('walk left', 'WalkHarry $9D08'),
    0x9DA6: ('walk right', 'WalkHarry $9D08'),
    0x9EE8: ('climb up', 'ClimbLadder $9E98'),
    0x9F22: ('climb down', 'ClimbLadder $9E98'),
    0x9892: ('jump click', 'MainLoop $9858'),
    0x987B: ('pickup sweep', 'MainLoop $9858'),
    0x9932: ('time tick', 'MainLoopTick $98B7'),
    0xA688: ('bonus step', 'PlayLevelBonus $A675'),
}
# SP0256-AL2 allophones: address -> (name, duration in ms), General Instrument datasheet table
AL2 = ('PA1 10,PA2 30,PA3 50,PA4 100,PA5 200,OY 420,AY 260,EH 70,KK3 120,PP 210,JH 140,NN1 140,IH 70,TT2 140,'
       'RR1 170,AX 70,MM 180,TT1 100,DH1 290,IY 250,EY 280,DD1 70,UW1 100,AO 100,AA 100,YY2 180,AE 120,HH1 130,'
       'BB1 80,TH 180,UH 100,UW2 260,AW 370,DD2 160,GG3 140,VV 190,GG1 80,SH 160,ZH 190,RR2 120,FF 150,KK2 190,'
       'KK1 160,ZZ 210,NG 220,LL 110,WW 180,XR 360,WH 200,YY1 130,CH 190,ER1 160,ER2 300,OW 240,DH2 240,SS 90,'
       'NN2 190,HH2 180,OR 330,AR 290,YR 350,GG2 40,EL 190,BB2 50')
ALLOPHONES = [(p.split()[0], int(p.split()[1])) for p in AL2.split(',')]
CODE = {name: i for i, (name, _) in enumerate(ALLOPHONES)}
# what each phrase says (read from its allophones) and who speaks it
WORDS = {1: 'oh no', 2: 'go for it', 3: 'missed', 4: 'nicely', 5: 'next level', 6: "how's that",
         7: 'high score', 8: 'be alert', 9: 'well done', 10: 'have no fear', 11: 'go now', 12: "don't stop",
         13: 'going up', 14: 'game over', 15: '(unclear)', 16: 'wrong manoeuvre', 17: 'look out', 18: 'got it',
         19: 'tough one', 20: 'A and F software presents Chuckie Egg', 21: 'low on time', 22: 'super',
         23: 'hopeless case', 24: 'instructions', 25: 'naughty naughty', 26: 'player one', 27: 'player two',
         28: 'player three', 29: 'player four', 30: 'oh oy', 31: 'are you ready', 32: 'not good enough',
         33: 'hard luck'}
USERS = {20: 'title', 24: 'instructions', 26: 'turn', 27: 'turn', 28: 'turn', 29: 'turn', 7: 'name entry'}
for n in (2, 8, 10, 11, 12, 17):
    USERS[n] = 'level start'
for n in (4, 6, 9, 13, 18, 22):
    USERS[n] = 'lift'
for n in (1, 16, 19, 23, 30, 32, 33):
    USERS[n] = 'death'

plt.rcParams.update({'font.size': 12, 'font.family': 'DejaVu Sans', 'text.parse_math': False})


def load(name, events=EVENTS):
    with open(os.path.join(events, name)) as f:
        return json.load(f)


def save(fig, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=DPI)
    plt.close(fig)
    print(path)


def at(f, t):
    return f * FT + t


def beep_hz(h):
    return CLOCK / (26 * (h or 256) + 47)


def beeper_hz(hl):
    return 437500 / (hl + 30.125)


def calls(d):
    """Beep entries from a CALL (not the loop's jump back to the label, not an interrupt's return)"""
    return [x for x in d['beep'] if x[4] not in LOOP_CALLERS]


def edges_of_call(d, x, outs=None):
    """The speaker edges (T, value, pc) of one Beep call: L cycles, two edges each"""
    f, t, h, l, _ = x
    start = at(f, t)
    outs = outs if outs is not None else [(at(o[0], o[1]), o[2], o[3]) for o in d['out_fe']]
    i = bisect.bisect_left(outs, (start,))
    res = []
    while i < len(outs) and len(res) < 2 * (l or 256):
        if outs[i][2] in BEEP_OUTS:
            res.append(outs[i])
        i += 1
    return res


def longest_jump(cs):
    """The longest run of jump clicks with no gap over 3 frames: one whole jump"""
    runs, cur = [], []
    for x in (c for c in cs if c[4] == 0x9892):
        if cur and at(x[0], x[1]) - at(cur[-1][0], cur[-1][1]) > 3 * FT:
            runs.append(cur)
            cur = []
        cur.append(x)
    runs.append(cur)
    return max(runs, key=len)


def phrases_file():
    out = {}
    for line in open(os.path.join(CASE, 'src', 'res', 'sound', 'Phrases.txt')):
        m = re.match(r'phrase ([\d ]+):\s*(.*)', line)
        if m:
            pairs = [(int(p.split()[0]), p.split()[1]) for p in m.group(2).split(', ')]
            for n in m.group(1).split():
                out[int(n)] = pairs
    return out


def tune_file(name):
    notes = []
    for line in open(os.path.join(CASE, 'src', 'res', 'sound', name)):
        line = line.split('#')[0].strip()
        if line and line != 'end':
            dur, pitch = line.split()
            notes.append((int(dur), int(pitch)))
    return notes


def note_hz(pitch):
    return 261.6256 * 2 ** (pitch / 12)


def cmd_table(_a):
    d = load('l13-events.json')
    outs = [(at(o[0], o[1]), o[2], o[3]) for o in d['out_fe']]
    by = defaultdict(list)
    for x in calls(d):
        by[x[4]].append(x)
    print('| Site | Sound | Calls | H | L | Hz | T a call | edge span measured |')
    for site, xs in sorted(by.items()):
        hs = sorted({x[2] for x in xs})
        x = xs[len(xs) // 2]
        e = edges_of_call(d, x, outs)
        span = e[-1][0] - e[0][0] if len(e) > 1 else 0
        model = x[3] * (26 * x[2] + 47) + 20
        print(f'| ${site:04X} | {SITES.get(site, ("?",))[0]} | {len(xs)} | {hs[0]}-{hs[-1]} | {x[3]} | '
              f'{beep_hz(x[2]):.0f} | {model} | {span} (model {model - 20 - (13 * x[2] + 33)}) |')
    # the measured half periods
    x = [c for c in calls(d) if c[4] == 0x9DA6][0]
    e = edges_of_call(d, x, outs)
    print('walk right edges', [b[0] - a[0] for a, b in zip(e, e[1:])])
    for name, file, tune in (('c1', 'c1-events.json', 'TitleTune.txt'),
                             ('idle-1p', 'idle-1p-4700-5400-events.json', 'DeathTune.txt')):
        d = load(file)
        notes = tune_file(tune)
        bp = d['beeper']
        print(name, len(bp), 'BEEPER calls', len(notes), 'notes')
        for (dur, pitch), b in zip(notes, bp):
            f = beeper_hz(b[2])
            want = note_hz(pitch)
            print(f'  {dur} {pitch:3d} want {want:7.1f} Hz {want * dur / 10:6.1f} cyc | HL {b[2]:4d} {f:7.1f} Hz '
                  f'DE {b[3]:3d} -> {b[3] + 1} cycles, {(b[3] + 1) * (8 * b[2] + 241)} T, frame {b[0]}')
    ph = phrases_file()
    for n in sorted(ph):
        hold = sum(c for c, _ in ph[n]) * 20
        need = sum(dict(ALLOPHONES)[a] for _, a in ph[n])
        print(f'phrase {n:2d} {WORDS[n]:40s} hold {hold:5d} ms datasheet {need:5d} ms {USERS.get(n, "-")}')


def cmd_effects(_a):
    d = load('l13-events.json')
    outs = [(at(o[0], o[1]), o[2], o[3]) for o in d['out_fe']]
    by = defaultdict(list)
    for x in calls(d):
        by[x[4]].append(x)
    order = [0x9D6A, 0x9DA6, 0x9EE8, 0x9F22, 0x9892, 0x987B, 0x9932, 0xA688]
    fig, axes = plt.subplots(4, 2, figsize=(WIDTH, 11.5))
    for ax, site in zip(axes.flat, order):
        xs = by[site]
        x = xs[len(xs) // 2]
        e = edges_of_call(d, x, outs)
        t0 = e[0][0]
        ts, vs = [], []
        level = 0
        ts.append(0)
        vs.append(0)
        for t, v, _ in e:
            us = (t - t0) / CLOCK * 1e6
            ts += [us, us]
            vs += [level, v >> 4 & 1]
            level = v >> 4 & 1
        end = (e[-1][0] - t0) / CLOCK * 1e6 + (13 * x[2] + 33) / CLOCK * 1e6
        ts.append(end)
        vs.append(level)
        ax.plot(ts, vs, color='#1f77b4', lw=1.4)
        ax.set_ylim(-0.3, 1.5)
        ax.set_yticks([0, 1])
        name, who = SITES[site]
        ax.set_title(f'{name}: H {x[2]}, L {x[3]}, {beep_hz(x[2]):.0f} Hz', fontsize=12)
        ax.text(0.01, 0.93, f'CALL at ${site:04X} ({who}), frame {x[0]} T {x[1]}', transform=ax.transAxes,
                fontsize=10, va='top')
        if len(e) >= 3:
            hi = e[1][0] - e[0][0]
            lo = e[2][0] - e[1][0]
            ax.text(0.01, 0.78, f'high {hi} T, low {lo} T (model {13 * x[2] + 14} / {13 * x[2] + 33})',
                    transform=ax.transAxes, fontsize=10, va='top')
        ax.set_xlabel('microseconds from the first edge', fontsize=10)
        ax.grid(alpha=0.3)
    fig.suptitle('One call of each Beep site in levels-1-3: the speaker bit (port $FE bit 4) as written', fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    save(fig, 'effects.png')


def cmd_sweep(_a):
    d = load('l13-events.json')
    cs = calls(d)
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(WIDTH, 8.2))
    # the sweep after the first egg of the recording (AddScore B = 10 from $9A08)
    egg = [x for x in d['addscore'] if x[3] == 0x9A08][0]
    t0 = at(egg[0], egg[1])
    sweep = [x for x in cs if x[4] == 0x987B and at(x[0], x[1]) >= t0][:63]
    for i in range(1, len(sweep)):   # one sweep: stop at the first gap of more than 5 frames
        if at(sweep[i][0], sweep[i][1]) - at(sweep[i - 1][0], sweep[i - 1][1]) > 5 * FT:
            sweep = sweep[:i]
            break
    ms = [(at(x[0], x[1]) - t0) / CLOCK * 1000 for x in sweep]
    a1.plot(ms, [beep_hz(x[2]) for x in sweep], 'o-', ms=4, color='#d62728', lw=0.8)
    for m, x in list(zip(ms, sweep))[:8]:
        a1.annotate(f'H {x[2]}', (m, beep_hz(x[2])), textcoords='offset points', xytext=(4, 6), fontsize=10)
    a1.set_title(f'Pickup sweep after the egg of frame {egg[0]}: {len(sweep)} two-cycle beeps, '
                 'H = (SoundSweep AND $1F) + 6', fontsize=12)
    a1.set_xlabel('ms after AddScore')
    a1.set_ylabel('Hz')
    a1.grid(alpha=0.3)
    # a jump: the clicks and HarryY
    run = longest_jump(cs)
    first = run[0]
    j0 = at(first[0], first[1])
    ms = [(at(x[0], x[1]) - j0) / CLOCK * 1000 for x in run]
    a2.plot(ms, [255 - x[2] for x in run], 'o-', ms=4, color='#2ca02c', lw=0.8, label='HarryY = 255 - H')
    a2.set_ylabel('HarryY (pixels from the bottom)')
    b2 = a2.twinx()
    b2.plot(ms, [beep_hz(x[2]) for x in run], 's', ms=3, color='#9467bd', label='click pitch, Hz')
    b2.set_ylabel('Hz of the click (one cycle)')
    a2.set_title(f'The jump of frame {first[0]}: one click (H = HarryY XOR $FF, L 1) on the pass before each '
                 f'slow tick, {len(run)} clicks', fontsize=12)
    a2.set_xlabel('ms after the first click')
    a2.grid(alpha=0.3)
    h1, l1 = a2.get_legend_handles_labels()
    h2, l2 = b2.get_legend_handles_labels()
    a2.legend(h1 + h2, l1 + l2, loc='lower center', fontsize=10)
    fig.tight_layout()
    save(fig, 'sweep.png')


def cmd_tunes(_a):
    fig, axes = plt.subplots(2, 1, figsize=(WIDTH, 9))
    for ax, (name, file, tune) in zip(axes, (('TitleTune $AE0C, c1', 'c1-events.json', 'TitleTune.txt'),
                                              ('DeathTune $AE6A, idle-1p', 'idle-1p-4700-5400-events.json',
                                               'DeathTune.txt'))):
        d = load(file)
        notes = tune_file(tune)
        bp = d['beeper'][:len(notes)]
        f0 = at(bp[0][0], bp[0][1])
        for (dur, pitch), b in zip(notes, bp):
            s = (at(b[0], b[1]) - f0) / CLOCK
            ax.broken_barh([(s, dur / 10)], (pitch - 0.4, 0.8), color='#aec7e8', edgecolor='#1f77b4')
            measured = 12 * math.log2(beeper_hz(b[2]) / 261.6256)
            ax.plot(s + (b[3] + 1) / beeper_hz(b[2]), measured, '|', color='#d62728', ms=10, mew=2)
        names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
        ps = sorted({p for _, p in notes})
        ax.set_yticks(ps)
        ax.set_yticklabels([f'{names[p % 12]}{4 + p // 12} ({p})' for p in ps], fontsize=10)
        ax.set_xlabel('seconds from the first BEEPER call (bar: the file\'s duration; red tick: the end of the '
                      'DE + 1 cycles)', fontsize=10)
        ax.set_title(f'{name}: {len(notes)} notes, {len(bp)} BEEPER calls traced', fontsize=12)
        ax.grid(alpha=0.3)
    fig.tight_layout()
    save(fig, 'tunes.png')


def phrase_runs(d):
    """The OUT ($9F) writes grouped into phrases: (start time, [(T, allophone)])"""
    runs = []
    cur = [(at(o[0], o[1]), o[2]) for o in d['out_9f']]
    # a phrase ends where the next StartPhrase begins
    starts = [at(x[0], x[1]) for x in d['phrase']] + [1 << 60]
    for s, e, x in zip(starts, starts[1:], d['phrase']):
        runs.append((x, [c for c in cur if s <= c[0] < e]))
    return runs


def cmd_speech(_a):
    picks = [('c1-events.json', 20), ('tour-type2-0-1000-events.json', 24), ('tour-type2-0-1000-events.json', 26),
             ('gameover-name-38900-39800-events.json', 7)]
    fig, axes = plt.subplots(len(picks), 1, figsize=(WIDTH, 11.5))
    for ax, (file, n) in zip(axes, picks):
        d = load(file)
        run = [r for r in phrase_runs(d) if r[0][2] == n][0]
        x, outs = run
        t0 = outs[0][0]
        late = 0
        for i, (t, code) in enumerate(outs):
            nxt = outs[i + 1][0] if i + 1 < len(outs) else t + 2 * FT
            s = (t - t0) / CLOCK * 1000
            hold = (nxt - t) / CLOCK * 1000
            name, dur = ALLOPHONES[code]
            ax.broken_barh([(s, hold)], (0.55, 0.4), color='#c7e9c0', edgecolor='#2ca02c')
            colour = '#d62728' if dur > hold + 1 else '#1f77b4'
            late += dur > hold + 1
            lane = 0.08 if i % 2 else 0.3
            ax.broken_barh([(s, dur)], (lane, 0.2), color=colour, edgecolor='black', linewidth=0.4)
            if name != 'PA1' or i == 0:
                ax.text(s + 2, 1.0, name, fontsize=10, rotation=90, va='bottom')
        ax.set_ylim(0, 1.75)
        ax.set_yticks([0.29, 0.75])
        ax.set_yticklabels(['datasheet', 'held'], fontsize=10)
        ax.set_title(f'phrase {n} "{WORDS[n]}" ({USERS.get(n)}), {file.split("-events")[0]} frame {x[0]}: '
                     f'{len(outs)} writes, {late} longer than their hold (red)', fontsize=11)
        ax.text(0.995, 0.97, 'green: held (to the next OUT); lower bars: the datasheet duration, odd and even '
                'writes on two lanes', transform=ax.transAxes, ha='right', va='top', fontsize=10)
        ax.set_xlabel('ms from the first OUT ($9F)', fontsize=10)
        ax.grid(alpha=0.3, axis='x')
    fig.tight_layout()
    save(fig, 'speech.png')


def cmd_phrases(_a):
    ph = phrases_file()
    ns = sorted(ph)
    fig, ax = plt.subplots(figsize=(WIDTH, 11))
    holds = [sum(c for c, _ in ph[n]) * 20 for n in ns]
    needs = [sum(dict(ALLOPHONES)[a] for _, a in ph[n]) for n in ns]
    y = list(range(len(ns)))
    ax.barh([v + 0.2 for v in y], holds, height=0.38, color='#2ca02c', label='held: sum of counts x 20 ms')
    ax.barh([v - 0.2 for v in y], needs, height=0.38, color='#1f77b4', label='datasheet: sum of durations')
    ax.set_yticks(y)
    ax.set_yticklabels([f'{n} {WORDS[n]} [{USERS.get(n, "never")}]' for n in ns], fontsize=10)
    ax.invert_yaxis()
    ax.set_xlabel('ms')
    ax.legend(loc='lower right', fontsize=11)
    ax.set_title('The 33 phrases of PhraseTable $C8C8: what they say, who speaks them, how long', fontsize=12)
    ax.grid(alpha=0.3, axis='x')
    fig.tight_layout()
    save(fig, 'phrases.png')


def cmd_cost(_a):
    d = load('l13-events.json')
    per = defaultdict(int)
    kinds = defaultdict(lambda: defaultdict(int))
    for x in calls(d):
        cost = (x[3] or 256) * (26 * (x[2] or 256) + 47) + 20
        per[x[0]] += cost
        kinds[SITES.get(x[4], ('other',))[0]][x[0]] += cost
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(WIDTH, 8.5))
    frames = range(0, 7023)
    groups = [('walk left', 'walk right'), ('climb up', 'climb down'), ('jump click',), ('pickup sweep',),
              ('time tick',), ('bonus step',)]
    colours = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    bottom = [0] * len(frames)
    for g, col in zip(groups, colours):
        vals = [sum(kinds[k].get(f, 0) for k in g) / FT * 100 for f in frames]
        a1.bar(frames, vals, bottom=bottom, width=1.0, color=col, label=' + '.join(g))
        bottom = [b + v for b, v in zip(bottom, vals)]
    a1.set_xlim(0, 7023)
    a1.set_ylabel('% of the frame in Beep')
    a1.set_xlabel('frame of levels-1-3 (level ends at 2007, 3583, 6649)')
    a1.legend(fontsize=10, ncol=3, loc='upper left')
    a1.set_title(f'Beep a frame: at most {max(per.values())} T ({max(per.values()) / FT * 100:.0f} %), '
                 f'in play mostly under 10 %', fontsize=12)
    a1.grid(alpha=0.3)
    c1 = load('c1-events.json')
    irq_frames = {x[0] for x in c1['irq']}
    bp = c1['beeper'][:len(tune_file('TitleTune.txt'))]
    xs, cost, lost = [], [], []
    for b in bp:
        t = (b[3] + 1) * (8 * b[2] + 241)
        xs.append(b[0])
        cost.append(t / FT)
    a2.bar(xs, cost, width=3, color='#1f77b4', label='BEEPER note length in frames (DE + 1) x (8 HL + 241) T')
    missing = [f for f in range(bp[0][0], bp[-1][0] + 8) if f not in irq_frames]
    a2.plot(missing, [-0.15] * len(missing), '|', color='#d62728', ms=8, label='frame with no interrupt taken')
    a2.set_xlabel('frame of c1 (the title tune)')
    a2.set_ylabel('frames')
    a2.set_title(f'The title tune with interrupts off: {len(missing)} of {bp[-1][0] + 8 - bp[0][0]} frames take no '
                 'interrupt', fontsize=12)
    a2.legend(fontsize=10, loc='upper right')
    a2.grid(alpha=0.3)
    fig.tight_layout()
    save(fig, 'cost.png')


def render(edges, path, pad_ms=20):
    """The speaker bit from its edges, as a 44.1 kHz 16-bit WAV with a soft high-pass (no DC)"""
    if not edges:
        return
    t0 = edges[0][0]
    n = int((edges[-1][0] - t0) / CLOCK * RATE) + int(pad_ms * RATE / 1000)
    buf = [0.0] * n
    level, last = 0, t0
    for e, v, _ in edges + [(edges[-1][0] + CLOCK // 50, 0, 0)]:
        a = int((last - t0) / CLOCK * RATE)
        b = min(n, int((e - t0) / CLOCK * RATE))
        for i in range(a, b):
            buf[i] = level
        level, last = (v >> 4) & 1, e
    out, prev_in, prev_out = [], 0.0, 0.0
    for s in buf:
        y = 0.995 * (prev_out + s - prev_in)
        prev_in, prev_out = s, y
        out.append(int(max(-1, min(1, y)) * 12000))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack(f'<{len(out)}h', *out))
    print(path, f'{len(out) / RATE * 1000:.1f} ms')


def window(outs, a, b, pcs):
    return [o for o in outs if a <= o[0] < b and o[2] in pcs]


def cmd_wav(_a):
    d = load('l13-events.json')
    outs = [(at(o[0], o[1]), o[2], o[3]) for o in d['out_fe']]
    by = defaultdict(list)
    for x in calls(d):
        by[x[4]].append(x)
    names = {0x9D6A: 'walk-left', 0x9DA6: 'walk-right', 0x9EE8: 'climb-up', 0x9F22: 'climb-down',
             0x9932: 'time-tick', 0xA688: 'bonus-step'}
    for site, name in names.items():
        # a run of that sound as heard: every call of the site in the 30 frames from the call that starts the
        # busiest such window (the bonus step: one call)
        ts = [at(y[0], y[1]) for y in by[site]]
        best = max(range(len(ts)), key=lambda i: bisect.bisect_left(ts, ts[i] + 30 * FT) - i)
        start = ts[best] if site != 0xA688 else ts[0]
        if site == 0xA688:
            render(edges_of_call(d, by[site][0], outs), os.path.join(OUT, f'{name}.wav'))
            continue
        edges = []
        for y in by[site]:
            if start <= at(y[0], y[1]) < start + 30 * FT:
                edges += edges_of_call(d, y, outs)
        render(edges, os.path.join(OUT, f'{name}.wav'))
    # the pickup sweep: from the first egg's AddScore to its last beep
    egg = [x for x in d['addscore'] if x[3] == 0x9A08][0]
    t0 = at(egg[0], egg[1])
    sw = [x for x in by[0x987B] if at(x[0], x[1]) >= t0][:63]
    render(window(outs, at(sw[0][0], sw[0][1]), at(sw[-1][0], sw[-1][1]) + 2000, (0x9CA6, 0x9CAC)),
           os.path.join(OUT, 'pickup-sweep.wav'))
    # a whole jump of clicks
    run = longest_jump(calls(d))
    render(window(outs, at(run[0][0], run[0][1]), at(run[-1][0], run[-1][1]) + 2000, (0x9CA6, 0x9CAC)),
           os.path.join(OUT, 'jump.wav'))
    # the level 1 bonus count-down: frames 2007-2016
    render(window(outs, at(2007, 0), at(2017, 0), (0x9CA6, 0x9CAC)), os.path.join(OUT, 'level-end-bonus.wav'))
    # ten seconds of level 1 play: frames 500-1000, every Beep
    render(window(outs, at(500, 0), at(1000, 0), (0x9CA6, 0x9CAC)), os.path.join(OUT, 'level1-play.wav'))
    for file, name, tune in (('c1-events.json', 'title-tune.wav', 'TitleTune.txt'),
                             ('idle-1p-4700-5400-events.json', 'death-tune.wav', 'DeathTune.txt')):
        e = load(file)
        o = [(at(v[0], v[1]), v[2], v[3]) for v in e['out_fe'] if v[3] == BEEPER_OUT]
        bp = e['beeper'][:len(tune_file(tune))]
        a, b = at(bp[0][0], bp[0][1]), at(bp[-1][0], bp[-1][1]) + 2 * FT
        render(window(o, a, b, (BEEPER_OUT,)), os.path.join(OUT, name))


WAVS = ['walk-left', 'walk-right', 'climb-up', 'climb-down', 'jump', 'pickup-sweep', 'time-tick', 'bonus-step',
        'level-end-bonus', 'level1-play', 'title-tune', 'death-tune']


def cmd_waves(_a):
    fig, axes = plt.subplots(len(WAVS) // 2, 2, figsize=(WIDTH, 12))
    for ax, name in zip(axes.flat, WAVS):
        path = os.path.join(OUT, f'{name}.wav')
        with wave.open(path) as w:
            n = w.getnframes()
            data = struct.unpack(f'<{n}h', w.readframes(n))
        step = max(1, n // 4000)
        xs = [i / RATE * 1000 for i in range(0, n, step)]
        ax.plot(xs, data[::step], lw=0.5, color='#1f77b4')
        ax.set_title(f'{name}.wav, {n / RATE * 1000:.0f} ms', fontsize=11)
        ax.set_yticks([])
        ax.tick_params(labelsize=10)
        ax.set_xlabel('ms', fontsize=10)
    fig.tight_layout()
    save(fig, 'waves.png')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['table', 'effects', 'sweep', 'tunes', 'speech', 'phrases', 'cost', 'wav',
                                    'waves', 'all'])
    a = p.parse_args()
    cmds = {'table': cmd_table, 'effects': cmd_effects, 'sweep': cmd_sweep, 'tunes': cmd_tunes,
            'speech': cmd_speech, 'phrases': cmd_phrases, 'cost': cmd_cost, 'wav': cmd_wav, 'waves': cmd_waves}
    if a.what == 'all':
        for k in ('effects', 'sweep', 'tunes', 'speech', 'phrases', 'cost', 'wav', 'waves'):
            cmds[k](a)
    else:
        cmds[a.what](a)


if __name__ == '__main__':
    main()
