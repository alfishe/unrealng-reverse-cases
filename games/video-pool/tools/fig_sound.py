#!/usr/bin/env python3
"""Figures, measurements and rendered audio of docs/09-sound.md (writer vpD), from the sound events of the
recordings (tools/sound_events.py). Output in docs/img/sound/.

    python3 tools/fig_sound.py table   [--events work/docs/vpD]   every sound instance measured, printed as tables
    python3 tools/fig_sound.py tones                              tones.png: the three SoundLoop tones, measured and
                                                                  modelled, with the interrupts that stretch them
    python3 tools/fig_sound.py roll                               roll.png: every sound as pitch against time
    python3 tools/fig_sound.py shot                               shot.png: the break shot of w1, requests taken,
                                                                  dropped and cut against the interrupts
    python3 tools/fig_sound.py tally                              tally.png: one score count-up, pitch and lost
                                                                  interrupts step by step
    python3 tools/fig_sound.py wav                                *.wav: each sound from its measured speaker edges,
                                                                  44 100 Hz mono 16 bit (never played here)
    python3 tools/fig_sound.py all

The events: work/docs/vpD/NAME-sound.json for w1, f1 and e1 (`tools/sound_events.py --work ... --frames 0-N`), each
from the recording replayed from work/snaps/entry.z80 with tests/inputs/NAME.txt (work/docs/vpD/replay.py).
A frame is 69 888 T at 3.5 MHz.
"""
import argparse
import json
import math
import os
import struct
import wave
from collections import defaultdict

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
OUT = os.path.join(CASE, 'docs', 'img', 'sound')
CLOCK = 3500000
FT = 69888
RATE = 44100
DPI = 100
WIDTH = 10.5  # inches: 1050 px

TONE_PCS = (0x8088, 0x808F)      # SoundCycle's OUT on / OUT off
ABORT_PC = 0x80AC                # SoundAbort's OUT
BEEPER_OUT = 0x03E1              # the ROM's BEEPER toggles the speaker here
REQUESTS = {1: ('ball', 20, 20), 2: ('cushion', 30, 12), 3: ('pocket', 250, 6)}   # B (delay passes), C (cycles)
CALLERS = {
    0x99EF: ('tally', 'AddScoreStep $99C1'),
    0xAF12: ('click', 'NameEntry step'),
    0xAF35: ('pick', 'NameEntryFire'),
    0x9791: ('foul 1', 'FoulJingleNotes $9786'),
    0x979F: ('foul 2', 'FoulJingleNotes $9786'),
    0xB2CD: ('click', 'MenuKey'),
    0xB6DE: ('click', 'VariationsKey'),
    0x9CB2: ('last shot', 'LastShotBeepTask $9CA7'),
    0xC264: ('editor', 'EditorPickBall $C258'),
    0xC3B7: ('editor', 'EditorBallLoop (potted)'),
    0xC3D4: ('editor', 'EditorDropBall'),
    0xC423: ('editor', 'EditorPlay $C41D'),
    0xC538: ('editor', 'EditorReset'),
}

plt.rcParams.update({'font.size': 11, 'font.family': 'DejaVu Sans'})


def ms(t):
    return t * 1000.0 / CLOCK


def beeper_hz(hl):
    return 437500.0 / (hl + 30.125)


def tone_cycle_t(b):
    """SoundCycle: on -> off 37B + 61 T, off -> on 37B + 77 T"""
    return 37 * b + 61, 37 * b + 77


def load(events_dir, name):
    path = os.path.join(events_dir, f'{name}-sound.json')
    if not os.path.isfile(path):
        return None
    d = json.load(open(path))
    d['name'] = name
    d['edges'] = sorted((f * FT + t, v, pc) for f, t, v, pc in d['out'])
    d['irqs'] = sorted(f * FT + t for f, t, _ in d['irq'])
    d['irq_frames'] = set(f for f, _, _ in d['irq'])
    d['int_t'] = min(t for _, t, _ in d['irq'])   # the interrupt's entry T in a frame (about 1825)
    return d


def irqs_between(d, a, b):
    import bisect
    i = bisect.bisect_left(d['irqs'], a)
    j = bisect.bisect_right(d['irqs'], b)
    return d['irqs'][i:j]


def tones(d):
    """Every SoundLoop tone: its request, its edges, cut short or not"""
    import bisect
    keys = [e[0] for e in d['edges']]
    out = []
    for f, t, r in d['request']:
        start = f * FT + t
        name, b, c = REQUESTS[r]
        i = bisect.bisect_left(keys, start)
        edges, cut = [], False
        while i < len(keys) and len(edges) < 2 * c:
            at, v, pc = d['edges'][i]
            if pc == ABORT_PC:
                cut = True
                edges.append((at, v, pc))
                break
            if pc in TONE_PCS:
                edges.append((at, v, pc))
            i += 1
        out.append(dict(kind=name, request=r, b=b, c=c, frame=f, t=t, start=start, edges=edges, cut=cut,
                        irqs=irqs_between(d, start, edges[-1][0]) if edges else []))
    return out


def beeps(d):
    """Every BEEPER call: HL, DE, the caller, its edges"""
    import bisect
    keys = [e[0] for e in d['edges']]
    out = []
    for f, t, hl, de, caller in d['beeper']:
        start = f * FT + t
        i = bisect.bisect_left(keys, start)
        edges = []
        # the ROM's BEEPER plays DE + 1 cycles: 2 DE + 2 writes, the first about 230 T after the call
        while i < len(keys) and len(edges) < 2 * de + 2:
            if d['edges'][i][2] == BEEPER_OUT:
                edges.append(d['edges'][i])
            i += 1
        name, site = CALLERS.get(caller, (f'? {caller:04X}', '?'))
        end = edges[-1][0] if edges else start
        # lost: a frame with no accepted interrupt whose INT (at the earliest accepted entry T of the recording)
        # falls between the call and the last write, with BEEPER's DI
        lost = sum(1 for g in range(start // FT, end // FT + 1)
                   if g not in d['irq_frames'] and start <= g * FT + d['int_t'] <= end)
        out.append(dict(kind=name, site=site, caller=caller, hl=hl, de=de, frame=f, t=t, start=start, edges=edges,
                        lost=lost))
    return out


def measured_hz(edges):
    if len(edges) < 3:
        return None
    span = edges[-1][0] - edges[0][0]
    return (len(edges) - 1) / 2.0 / (span / CLOCK)


def cmd_table(runs):
    for d in runs:
        print(f'== {d["name"]}: frames {d["frames"]}, {d["instructions"]} instructions, {len(d["irqs"])} '
              f'interrupts, {len(d["edges"])} speaker writes, {len(d["write"]) if "write" in d else "-"} '
              f'SoundRequest writes')
        per = defaultdict(list)
        for x in tones(d):
            per[x['kind']].append(x)
        for kind, xs in per.items():
            b = xs[0]['b']
            on, off = tone_cycle_t(b)
            full = [x for x in xs if not x['cut']]
            hz = [measured_hz(x['edges']) for x in full if measured_hz(x['edges'])]
            dur = [x['edges'][-1][0] - x['edges'][0][0] + off for x in full]
            stretched = sum(1 for x in xs if x['irqs'])
            print(f'  tone {kind:8s} n={len(xs):3d} cut={len(xs) - len(full)} with an interrupt inside={stretched}'
                  f'  model {CLOCK / (on + off):7.1f} Hz {ms(xs[0]["c"] * (on + off)):6.2f} ms'
                  f'  measured median {sorted(hz)[len(hz) // 2] if hz else 0:7.1f} Hz,'
                  f' {ms(sorted(dur)[len(dur) // 2]) if dur else 0:6.2f} ms (min {ms(min(dur)) if dur else 0:.2f},'
                  f' max {ms(max(dur)) if dur else 0:.2f})')
        per = defaultdict(list)
        for x in beeps(d):
            per[(x['kind'], x['site'])].append(x)
        for (kind, site), xs in per.items():
            hz = [measured_hz(x['edges']) for x in xs]
            durs = [x['edges'][-1][0] - x['edges'][0][0] for x in xs if x['edges']]
            print(f'  BEEPER {kind:9s} {site:24s} n={len(xs):3d} HL {min(x["hl"] for x in xs)}-'
                  f'{max(x["hl"] for x in xs)} DE {min(x["de"] for x in xs)}-{max(x["de"] for x in xs)}'
                  f'  model {beeper_hz(xs[0]["hl"]):6.1f} Hz measured {hz[0] or 0:6.1f} Hz'
                  f'  {ms(max(durs)) if durs else 0:6.1f} ms max, lost interrupts {sum(x["lost"] for x in xs)}')
        if d.get('write'):
            pcs = defaultdict(lambda: defaultdict(int))
            for f, t, v, pc in d['write']:
                pcs[pc][v] += 1
            print('  SoundRequest writes:', {f'{pc:04X}': dict(v) for pc, v in sorted(pcs.items())})
        print('  aborts', d['abort'])


def save(fig, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=DPI)
    plt.close(fig)
    print(path)


def step(edges, t0):
    xs, ys = [], []
    level = None
    for at, v, pc in edges:
        lv = (v >> 4) & 1
        if level is not None:
            xs.append(ms(at - t0))
            ys.append(level)
        xs.append(ms(at - t0))
        ys.append(lv)
        level = lv
    return xs, ys


def cmd_tones(runs):
    w1 = runs[0]
    xs = tones(w1)
    fig, axes = plt.subplots(3, 1, figsize=(WIDTH, 8.6))
    for ax, r in zip(axes, (1, 2, 3)):
        name, b, c = REQUESTS[r]
        cands = [x for x in xs if x['request'] == r and not x['cut']]
        # the instance with an interrupt inside that stretches it most
        pick = max(cands, key=lambda x: x['edges'][-1][0] - x['edges'][0][0])
        t0 = pick['edges'][0][0]
        px, py = step(pick['edges'], t0)
        on, off = tone_cycle_t(b)
        model, at = [], 0
        for i in range(2 * c):
            model.append((t0 + at, 0x17 if i % 2 == 0 else 0x07, 0))
            at += on if i % 2 == 0 else off
        mx, my = step(model, t0)
        ax.plot(mx, [y * 0.8 + 1.4 for y in my], color='#888888', lw=1.2, label='model (no interrupt)')
        ax.plot(px, [y * 0.8 for y in py], color='#c03030', lw=1.4, label='recorded')
        for q in pick['irqs']:
            ax.axvline(ms(q - t0), color='#3060c0', ls='--', lw=1)
            ax.text(ms(q - t0), 2.3, ' interrupt', color='#3060c0', fontsize=10, va='bottom')
        span = pick['edges'][-1][0] - t0 + off
        ax.set_xlim(-0.2, max(ms(span), ms(c * (on + off))) * 1.03)
        ax.set_ylim(-0.3, 2.8)
        ax.set_yticks([0.4, 1.8])
        ax.set_yticklabels(['recorded', 'model'])
        ax.set_title(f'request {r}, {name} (w1 frame {pick["frame"]}): B = {b}, C = {c}: half periods {on} / {off} T, '
                     f'{CLOCK / (on + off):.0f} Hz, {ms(c * (on + off)):.2f} ms modelled; '
                     f'{ms(span):.2f} ms recorded', fontsize=11, loc='left')
        ax.set_xlabel('ms from the first OUT')
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend([handles[0], handles[1], plt.Line2D([], [], color='#3060c0', ls='--')],
               ['model from the instruction timings (no interrupt)', 'recorded speaker bit (w1)',
                'an interrupt entry (Im2Jump)'], loc='lower center', ncol=3, fontsize=10)
    fig.suptitle('The three SoundLoop tones: every interrupt inside a tone lengthens the half period it falls in',
                 fontsize=12, x=0.01, ha='left')
    fig.tight_layout(rect=(0, 0.04, 1, 0.97))
    save(fig, 'tones.png')


def cmd_roll(runs):
    rows = []   # (label, start ms, end ms, Hz, colour)
    w1 = runs[0]
    for r in (1, 2, 3):
        name, b, c = REQUESTS[r]
        on, off = tone_cycle_t(b)
        rows.append((f'SoundLoop {r}: {name} (B {b}, C {c})', 0, ms(c * (on + off)), CLOCK / (on + off), '#c03030'))
    seen = set()
    for d in runs:
        for x in beeps(d):
            key = (x['hl'], x['de'])
            if x['kind'] == 'tally' or key in seen:
                continue
            seen.add(key)
            hz = beeper_hz(x['hl'])
            label = {'click': 'BEEPER click: HL 1000, DE 20 (menu, variations, name entry, editor)',
                     'pick': 'BEEPER pick: HL 1200, DE 22 (name entry fire)'}.get(
                         x['kind'], f'BEEPER {x["kind"]}: HL {x["hl"]}, DE {x["de"]}')
            if x['kind'] == 'last shot':
                label = f'BEEPER last shot: HL 500, DE 10 ({d["name"]}, LastShotBeepTask)'
            rows.append((label, 0, (x['de'] + 0.5) * 1000.0 / hz, hz, '#3060c0'))   # first to last write
    if (500, 10) not in seen:
        hz = beeper_hz(500)
        rows.append(('BEEPER last shot: HL 500, DE 10 (from the code)', 0, 10.5 * 1000.0 / hz, hz, '#909090'))
    fig, ax = plt.subplots(figsize=(WIDTH, 6.2))
    for label, a, b, hz, col in rows:
        ax.plot([a, b], [hz, hz], color=col, lw=6, solid_capstyle='butt')
        ax.text(b * 1.06, hz * (0.975 if 'pick' in label else 1.0), label, va='top' if 'pick' in label else 'center',
                fontsize=10)
    # the tally ladder: the longest count-up of w1
    lad = [x for x in beeps(w1) if x['kind'] == 'tally']
    groups, cur = [], []
    for x in lad:
        if cur and x['hl'] > cur[-1]['hl']:
            groups.append(cur)
            cur = []
        cur.append(x)
    groups.append(cur)
    first = max(groups, key=len)
    for x in first:
        hz = beeper_hz(x['hl'])
        d = (x['de'] + 0.5) * 1000.0 / hz
        ax.plot([0, d], [hz, hz], color='#30a050', lw=1.5)
    top = beeper_hz(first[-1]['hl'])
    ax.annotate(f'BEEPER tally: HL 1200 down by 10 a step, DE = 6000 / HL\n({len(first)} beeps of the longest '
                f'count-up in w1, {beeper_hz(1200):.0f} to {top:.0f} Hz, each 13-15.5 ms)',
                xy=(12, 352), xytext=(30, 120), fontsize=10, color='#207040', va='center',
                arrowprops=dict(arrowstyle='->', color='#207040'))
    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlim(5, 4000)
    ax.set_ylim(30, 3000)
    ax.set_xlabel('duration, ms (log)')
    ax.set_ylabel('pitch, Hz (log)')
    ax.set_title('Every sound of the game as pitch and length: three short SoundLoop tones, the ROM BEEPER for the rest',
                 fontsize=12, loc='left')
    ax.grid(True, which='both', color='#e0e0e0')
    fig.tight_layout()
    save(fig, 'roll.png')


def request_fates(d):
    """Each nonzero SoundRequest write and its fate: 'taken' (SoundLoop played it), 'replaced' (a later write came
    before SoundLoop took it), 'lost' (written while a tone played: SoundDelay only tests for zero, and the tone's end
    clears it), 'cleared' (a task wrote 0 before SoundLoop took it)"""
    ev = [(f * FT + t, 0, 'w', v, pc) for f, t, v, pc in d.get('write', [])]
    ev += [(f * FT + t, 1, 'take', a, 0) for f, t, a in d['request']]
    ev += [(f * FT + t, 1, 'abort', 0, 0) for f, t in d['abort']]
    ev.sort()
    out, pending, playing = [], None, False
    for t, _o, k, v, pc in ev:
        if k == 'take':
            if pending is not None:
                out[pending][3] = 'taken'
            pending, playing = None, True
        elif k == 'abort' or (k == 'w' and v == 0):
            if pending is not None:
                out[pending][3] = 'cleared'
            pending, playing = None, False   # tone done, aborted, or cleared (SoundDelay then aborts)
        elif playing:
            out.append([t, v, pc, 'lost'])
        else:
            if pending is not None:
                out[pending][3] = 'replaced'
            out.append([t, v, pc, 'pending'])
            pending = len(out) - 1
    return out


def cmd_shot(runs):
    w1 = runs[0]
    f0, f1 = 1106, 1206
    fig, ax = plt.subplots(figsize=(WIDTH, 4.6))
    colours = {1: '#c03030', 2: '#d08000', 3: '#7030a0'}
    for x in tones(w1):
        if not f0 <= x['frame'] < f1 or not x['edges']:
            continue
        a = x['edges'][0][0] / FT
        b = x['edges'][-1][0] / FT
        ax.plot([a, max(b, a + 0.15)], [x['request']] * 2, color=colours[x['request']], lw=8, solid_capstyle='butt')
    seen = set()
    for t, v, pc, fate in request_fates(w1):
        if f0 * FT <= t < f1 * FT:
            style = {'taken': dict(mfc=colours[v]), 'lost': dict(mfc='white'), 'replaced': dict(mfc='white'),
                     'cleared': dict(mfc='white')}[fate]
            m = 'v' if fate in ('taken', 'lost') else 'X'
            lab = {'taken': 'request taken', 'lost': 'request lost (a tone was playing)',
                   'replaced': 'request replaced by a later one', 'cleared': 'request cleared'}[fate]
            ax.plot([t / FT], [v + 0.32], marker=m, color=colours[v], ms=8, ls='none',
                    label=lab if lab not in seen else None, **style)
            seen.add(lab)
    for f, t, v, pc in w1.get('write', []):
        if f0 <= f < f1 and not v and pc not in (0x8098,):
            ax.plot([f + t / FT], [0.55], marker='x', color='black', ms=8)
    for q in w1['irqs']:
        if f0 * FT <= q < f1 * FT:
            ax.plot([q / FT, q / FT], [3.75, 3.95], color='#3060c0', lw=1)
    ax.set_yticks([0.55, 1, 2, 3, 3.85])
    ax.set_yticklabels(['cleared by a task', 'ball (1)', 'cushion (2)', 'pocket (3)', 'interrupt entries'])
    ax.set_ylim(0.3, 4.1)
    ax.set_xlim(f0, f1)
    ax.set_xlabel('frame (w1)')
    ax.set_title('The break shot of w1, frames 1106-1205: each request (triangle) and the tone it got (bar)',
                 fontsize=12, loc='left')
    ax.grid(True, axis='x', color='#e0e0e0')
    ax.legend(loc='upper left', bbox_to_anchor=(0.005, 0.86), fontsize=10, framealpha=0.95)
    fig.tight_layout()
    save(fig, 'shot.png')


def cmd_tally(runs):
    w1 = runs[0]
    lad = [x for x in beeps(w1) if x['kind'] == 'tally']
    groups, cur = [], []
    for x in lad:
        if cur and (x['hl'] > cur[-1]['hl'] or x['frame'] - cur[-1]['frame'] > 10):
            groups.append(cur)
            cur = []
        cur.append(x)
    groups.append(cur)
    g = max(groups, key=len)
    fig, (a1, a2) = plt.subplots(2, 1, figsize=(WIDTH, 6.4), sharex=True,
                                 gridspec_kw={'height_ratios': [2, 1.2]})
    fr = [x['frame'] for x in g]
    a1.plot(fr, [beeper_hz(x['hl']) for x in g], 'o-', color='#30a050', label='model 437 500 / (HL + 30.125)')
    a1.plot(fr, [measured_hz(x['edges']) for x in g], 'x', color='black', ms=7, label='measured from the OUTs')
    a1.set_ylabel('pitch, Hz')
    a1.set_ylim(None, beeper_hz(g[-1]['hl']) + 25)
    a1.legend(fontsize=10)
    for x in g[::6]:
        a1.annotate(f'HL {x["hl"]}\nDE {x["de"]}', (x['frame'], beeper_hz(x['hl'])), textcoords='offset points',
                    xytext=(0, 10), fontsize=10, ha='center')
    for x in g:
        a = x['edges'][0][0] % FT
        b = a + x['edges'][-1][0] - x['edges'][0][0]
        a2.plot([x['frame'], x['frame']], [a, b], color='#3060c0', lw=5, solid_capstyle='butt')
    nxt = FT + w1['int_t']
    a2.axhline(nxt, color='#c03030', ls='--', lw=1)
    a2.text(fr[-1], nxt * 0.985, f'the next interrupt (next frame T {w1["int_t"]})', color='#c03030',
            fontsize=10, va='top', ha='right', bbox=dict(facecolor='white', edgecolor='none', pad=1))
    for x in g:
        if x['lost']:
            a2.annotate(f'frame {x["frame"]}: the first beep starts at T {x["t"]}, after the printed total, and runs '
                        f'past the next interrupt: {x["lost"]} lost', (x['frame'], x['edges'][-1][0] % FT + FT),
                        textcoords='offset points', xytext=(30, 6), fontsize=10, color='#c03030', va='bottom',
                        arrowprops=dict(arrowstyle='->', color='#c03030'))
    a2.set_ylim(0, FT * 1.42)
    a2.set_ylabel('T in the frame')
    a2.set_title('where each beep sits in its frame: from the first OUT to the last, interrupts off (BEEPER)',
                 fontsize=11, loc='left')
    a2.set_xlabel('frame (w1)')
    a1.set_title(f'One score count-up of w1 (frames {fr[0]}-{fr[-1]}, {len(g)} beeps): the pitch rises 10 HL units a '
                 f'beep, each 13-15.5 ms', fontsize=12, loc='left')
    fig.tight_layout()
    save(fig, 'tally.png')


def render(edges, path, pad_ms=20):
    """The speaker bit from its edges, as a 44.1 kHz 16-bit WAV with a soft high-pass (no DC)"""
    if not edges:
        return
    t0 = edges[0][0]
    n = int((edges[-1][0] - t0) / CLOCK * RATE) + int(pad_ms * RATE / 1000)
    buf = [0.0] * n
    level, at = 0, t0
    for e, v, pc in edges + [(edges[-1][0] + CLOCK // 50, 0, 0)]:
        a = int((at - t0) / CLOCK * RATE)
        b = min(n, int((e - t0) / CLOCK * RATE))
        for i in range(a, b):
            buf[i] = level
        level, at = (v >> 4) & 1, e
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
    print(path)


def cmd_wav(runs):
    w1 = runs[0]
    done = set()
    for x in tones(w1):
        if x['kind'] in done or x['cut'] or x['irqs']:
            continue
        done.add(x['kind'])
        render(x['edges'], os.path.join(OUT, f'{x["kind"]}.wav'))
    for x in tones(w1):   # no pocket tone escaped an interrupt: the first complete one, as played
        if x['kind'] not in done and not x['cut']:
            done.add(x['kind'])
            render(x['edges'], os.path.join(OUT, f'{x["kind"]}.wav'))
    for d in runs:
        bs = beeps(d)
        for x in bs:
            if x['kind'] in ('click', 'pick', 'last shot') and x['kind'] not in done:
                done.add(x['kind'])
                render(x['edges'], os.path.join(OUT, x['kind'].replace(' ', '-') + '.wav'))
        foul = [x for x in bs if x['kind'].startswith('foul')]
        if foul and 'foul' not in done:
            done.add('foul')
            render(foul[0]['edges'] + foul[1]['edges'], os.path.join(OUT, 'foul.wav'))
        tal = [x for x in bs if x['kind'] == 'tally']
        if tal and 'tally' not in done:
            done.add('tally')
            groups = [[tal[0]]]
            for x in tal[1:]:
                if x['hl'] > groups[-1][-1]['hl']:
                    groups.append([])
                groups[-1].append(x)
            g = max(groups, key=len)   # the longest count-up
            print(f'tally.wav: frames {g[0]["frame"]}-{g[-1]["frame"]}, {len(g)} ticks')
            render([e for x in g for e in x['edges']], os.path.join(OUT, 'tally.wav'))


def cmd_cost(runs):
    """What each sound costs: the interrupts lost under BEEPER's DI (left) and how much the interrupts stretch the
    SoundLoop tones (right)"""
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(WIDTH, 4.6), gridspec_kw={'width_ratios': [1.25, 1]})
    colours = {'w1': '#1f77b4', 'f1': '#ff7f0e', 'e1': '#2ca02c'}
    kinds = ['tally', 'last shot', 'click', 'pick', 'editor', 'foul 1', 'foul 2']
    hgt = 0.8 / len(runs)
    for k, d in enumerate(runs):
        per = defaultdict(list)
        for x in beeps(d):
            per[x['kind']].append(x)
        for i, kind in enumerate(kinds):
            xs = per.get(kind, [])
            if not xs:
                continue
            lost = sum(x['lost'] for x in xs)
            y = i + (k - (len(runs) - 1) / 2) * hgt
            a1.barh(y, max(lost, 0.15), height=hgt, color=colours[d['name']],
                    label=d['name'] if i == next(j for j, kk in enumerate(kinds) if per.get(kk)) else None)
            a1.text(max(lost, 0.15) * 1.08, y, f'{lost} in {len(xs)}', va='center', fontsize=10)
    a1.set_yticks(range(len(kinds)), ['tally', 'last shot', 'click (keys, name)', 'name pick', 'editor', 'foul 1',
                                         'foul 2'])
    a1.invert_yaxis()
    a1.set_xscale('symlog', linthresh=1)
    a1.set_xlim(0, 400)
    a1.set_xlabel('interrupts lost (frame starts under DI), log scale')
    a1.set_title('BEEPER notes: interrupts lost per recording')
    a1.legend(loc='center right', fontsize=10)
    for k, d in enumerate(runs):
        per = defaultdict(list)
        for x in tones(d):
            if not x['cut']:
                per[x['kind']].append(x)
        for i, kind in enumerate(('ball', 'cushion', 'pocket')):
            xs = per.get(kind, [])
            if not xs:
                continue
            on, off = tone_cycle_t(xs[0]['b'])
            model = xs[0]['c'] * (on + off)
            r = [(x['edges'][-1][0] - x['edges'][0][0] + off) / model for x in xs]
            jit = [i + (k - 1) * 0.22 + ((j * 37) % 11 - 5) * 0.012 for j in range(len(r))]
            a2.scatter(jit, r, s=14, color=colours[d['name']], alpha=0.7,
                       label=d['name'] if i == 0 or (kind == 'ball' and not per.get('ball')) else None)
    a2.axhline(1, color='grey', lw=1, ls='--')
    a2.text(2.45, 0.9, 'model length', fontsize=10, color='grey', ha='right')
    a2.set_ylim(0.8, 13)
    a2.set_xticks(range(3), ['ball', 'cushion', 'pocket'])
    a2.set_yscale('log')
    a2.set_ylabel('measured length / model length')
    a2.set_title('SoundLoop tones: stretched by interrupts')
    a2.legend(loc='upper right', fontsize=10)
    fig.text(0.01, 0.01, 'recordings w1, f1, e1 replayed from work/snaps/entry.z80; python3 tools/fig_sound.py cost',
             fontsize=10, color='#555')
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    save(fig, 'cost.png')


def cmd_waves(runs):
    """The rendered WAV files drawn: one panel each, the samples against time"""
    names = [('ball', 'ball tone (w1, no interrupt)'), ('cushion', 'cushion tone (w1, no interrupt)'),
             ('pocket', 'pocket tone (w1, as played: interrupt gaps)'), ('last-shot', 'last-shot beep (f1)'),
             ('click', 'key click (w1 menu)'), ('pick', 'name pick (w1)'),
             ('tally', 'longest count-up (w1 frames 8456-8493)'), ('foul', 'foul jingle (w1)')]
    fig, axes = plt.subplots(4, 2, figsize=(WIDTH, 8.4))
    for ax, (n, title) in zip(axes.flat, names):
        path = os.path.join(OUT, n + '.wav')
        with wave.open(path) as w:
            raw = w.readframes(w.getnframes())
            rate = w.getframerate()
        ys = struct.unpack(f'<{len(raw) // 2}h', raw)
        step = max(1, len(ys) // 6000)
        xs = [i / rate * 1000 for i in range(0, len(ys), step)]
        ax.plot(xs, ys[::step], lw=0.6, color='#1f4e79')
        ax.set_title(f'{n}.wav: {title}', fontsize=10)
        ax.set_yticks([])
        ax.set_xlim(0, len(ys) / rate * 1000)
        ax.tick_params(labelsize=10)
    for ax in axes[-1]:
        ax.set_xlabel('ms')
    fig.text(0.01, 0.005, 'docs/img/sound/*.wav, 44.1 kHz 16-bit, from the recorded speaker writes; '
             'python3 tools/fig_sound.py wav waves', fontsize=10, color='#555')
    fig.tight_layout(rect=(0, 0.02, 1, 1))
    save(fig, 'waves.png')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['table', 'tones', 'roll', 'shot', 'tally', 'cost', 'wav', 'waves', 'all'])
    p.add_argument('--events', default=os.path.join(CASE, 'work', 'docs', 'vpD'))
    a = p.parse_args()
    runs = [r for r in (load(a.events, n) for n in ('w1', 'f1', 'e1')) if r]
    todo = ['table', 'tones', 'roll', 'shot', 'tally', 'cost', 'wav', 'waves'] if a.what == 'all' else [a.what]
    for w in todo:
        globals()['cmd_' + w](runs)


if __name__ == '__main__':
    main()
