"""Figures and audio of docs/09-sound.md drawn from access traces and the AY model (aymodel.py).

  python3 tools/fig_ay.py envelopes   docs/img/sound/ay-envelopes.png   the tune's volume envelopes and vibrato, c128
  python3 tools/fig_ay.py order       docs/img/sound/ay-order.png       the tune's order lists: pattern by tick
  python3 tools/fig_ay.py menuregs    docs/img/sound/ay-registers-menu.png   AY registers in the menu (c128 trace)
  python3 tools/fig_ay.py playregs    docs/img/sound/ay-registers-play.png   AY registers in play, slots to channels
  python3 tools/fig_ay.py channels    docs/img/sound/sfx-channels.png   four effects, three channels (x2 trace)
  python3 tools/fig_ay.py sheet       docs/img/sound/sfx-sheet.png      the 17 effects, model tick by tick
  python3 tools/fig_ay.py speaker     docs/img/sound/speaker-play.png   who drives the speaker in play (x2 traces)
  python3 tools/fig_ay.py sweep       docs/img/sound/sweep-halfwaves.png BeeperSweep's half-waves (x2 trace)
  python3 tools/fig_ay.py audio       docs/audio/*.mp3                  the renders, encoded (never played)
  python3 tools/fig_ay.py all

The traces were taken on the agent's own instance (work/docs/fillS/<rec>/traces, `analysis trace` over the
recording); work/docs/fillS/aywrites.py cut from them the AY register writes, the OUT ($FE) writes and the entries
of chosen routines (with A and BC) into the JSON files read here:

  menu-ay.json            c128 frames 12150-12400 (the menu, TuneStart at 12150-12175)
  play-ay.json            c128 frames 20000-20100 (play: a shot, two blasts, a grenade)
  x2-1600_0-1700_0.json   x2 frames 1600-1700 (four effects at once; a pod: five BeeperSweeps)
  x2-2125_0-2185_0.json   x2 frames 2125-2185 (a thing shot: the shot-hit rattle, a blast, a shot, a pod)
  x2-400_0-470_0.json     x2 frames 400-470 (36 debris pieces flying)
"""
import json
import os
import subprocess
import sys
import wave

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import aymodel as A  # noqa: E402
import fig_docb as B  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

FILLS = os.path.join(B.WORK, 'docs', 'fillS')
AUDIO_IN = os.path.join(B.DOCB, 'audio')
AUDIO_OUT = os.path.join(B.CASE, 'docs', 'audio')
AY_CLOCK = 1773400
CH = ['A', 'B', 'C']
CH_COL = [(0.35, 0.9, 0.45), (0.4, 0.65, 1.0), (1.0, 0.8, 0.3)]
ENV_FIRST, ENV_END = 0xBDE1, 0xBE7C


def load(name):
    return json.load(open(os.path.join(FILLS, name)))


def hz(period):
    return AY_CLOCK / (16 * period) if period else None


# --- the tune's envelopes ---------------------------------------------------------------------------------------------

def envelope_list():
    """the 17 envelope sub-streams of TuneEnvelopes: (address, the $8A bytes)"""
    M = B.image()
    out, p = [], ENV_FIRST
    while p < ENV_END:
        n = M[p + 1]
        out.append((p, bytes(M[p + 2:p + 2 + n])))
        p += n + 3
    return out


def volume_curve(entries, ticks, ceiling=13):
    """TuneVolumeStep on paper: the volume each tick after a note's read tick, from the $8A entries"""
    rec = bytearray(0x50)
    rec[0x3A] = len(entries)
    rec[0x3B:0x3B + len(entries)] = entries
    rec[8] = ceiling
    rec[0x37], rec[0x38], rec[0x39] = rec[0x3B], rec[0x3C], rec[0x3D]
    rec[0x36] = rec[0x3D]
    rec[0x35] = 0
    rec[3] = 0
    p = A.TunePlayer.__new__(A.TunePlayer)
    p.m = bytearray(0x10000)
    base = 0x8000
    p.m[base:base + 0x50] = rec
    p.m[base + 0x1B] = 0x80          # keep the pitch side quiet
    p.out = []
    vols = []
    for _ in range(ticks):
        p.envelopes(base)
        vols.append(p.m[base + 3])
    return vols


def pitch_curve(rec_addr, ticks):
    """the pitch offset +$19 each tick after a note, from the record's own table at +$1F (the image's bytes)"""
    M = bytearray(B.image())
    rec = rec_addr
    M[rec + 0x19] = 0
    M[rec + 0x1B] = M[rec + 0x1C] = 1
    M[rec + 0x1A] = 0xFD
    M[rec + 0x1D] = 0
    M[rec + 0x36] = 0x80
    p = A.TunePlayer.__new__(A.TunePlayer)
    p.m = M
    p.out = []
    out = []
    for _ in range(ticks):
        p.envelopes(rec)
        out.append(B.s8(M[rec + 0x19]))
    return out


def envelope_users():
    """how many times each channel's streams call each envelope sub-stream (a static walk of the calls)"""
    M = B.image()
    users = {}
    for ch, start in zip(CH, A.TUNE_STREAMS):
        p, stack = start, []
        while True:
            a = M[p]
            if a < 0x64:
                p += 2 if a >= 0x32 else 1
            elif a == 0x64:
                p += 1
            elif a == 0x79:
                p += 2
            elif a == 0x75:
                t = B.word(M, p + 1)
                if ENV_FIRST <= t <= ENV_END:
                    users.setdefault(t, {}).setdefault(ch, 0)
                    users[t][ch] += 1
                stack.append(p + 3)
                p = t
            elif a == 0x76:
                p = stack.pop()
            elif a == 0x8A:
                p += M[p + 1] + 2
            elif a == 0xFF:
                break
    return users


def envelopes():
    envs = envelope_list()
    users = envelope_users()
    menu = load('menu-ay.json')
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 13.5))
    gs = fig.add_gridspec(4, 2, height_ratios=[1.25, 0.55, 0.8, 1.1])
    ax = fig.add_subplot(gs[0, :])
    palette = [(0.35, 0.9, 0.45), (0.2, 0.75, 0.75), (1.0, 0.55, 0.3), (1.0, 0.85, 0.3), (0.95, 0.4, 0.9),
               (0.75, 0.5, 1.0), (0.4, 0.65, 1.0)]
    unused = []
    c = 0
    for k, (addr, e) in enumerate(envs):
        v = volume_curve(e, 60)
        if addr not in users:
            unused.append(addr)
            ax.step(range(1, 61), v, where='post', color=(0.5, 0.5, 0.55), lw=0.6, alpha=0.6,
                    label='10 envelopes no stream calls' if len(unused) == 1 else None)
            continue
        used = ', '.join(f'{ch} {n}' for ch, n in sorted(users[addr].items()))
        segs = ' / '.join(e[j:j + 3].hex(' ') for j in range(0, len(e), 3))
        ax.step(range(1, 61), v, where='post', color=palette[c % len(palette)], lw=1.8,
                label=f'env {k + 1} ${addr:04X} [{segs}]: {used}')
        c += 1
    ax.set_xlim(0, 60)
    ax.set_ylim(-0.5, 14)
    ax.set_xlabel('ticks after the tick that read the note (ceiling 13: channels A and C)')
    ax.set_ylabel('volume (register 8-10)')
    ax.set_title(B.wrap('The 17 volume envelopes of TuneEnvelopes ($8A sub-streams $BDE1-$BE7C), each from the read '
                        'tick of a note; legend: the entries [steps step ticks] and the calls per channel in the '
                        'whole tune', 110), fontsize=11)
    axl = fig.add_subplot(gs[1, :])
    axl.axis('off')
    axl.legend(*ax.get_legend_handles_labels(), fontsize=10, ncol=2, loc='center')
    ax.grid(True, alpha=0.3)
    ax2 = fig.add_subplot(gs[2, 0])
    for rec, name, col in ((A.TUNE_RECORDS[0], 'A ($BE7D +$1F: 02 01 02 / 04 FF 02 / 02 01 02)', CH_COL[0]),
                           (A.TUNE_RECORDS[1], 'B and C (03 01 01 / 06 FF 01 / 03 01 01)', CH_COL[1])):
        ax2.step(range(1, 41), pitch_curve(rec, 40), where='post', color=col, label=name)
    ax2.set_ylabel('period offset')
    ax2.set_xlabel('ticks after the read tick')
    ax2.set_title(B.wrap('The vibrato: the pitch tables left in the records (no stream sets one)', 52), fontsize=11)
    ax2.legend(fontsize=10, loc='lower left')
    ax2.set_ylim(-4.5, 4.5)
    ax2.grid(True, alpha=0.3)
    ax3 = fig.add_subplot(gs[2, 1])
    M = B.image()
    rows = [('entry', 'steps', 'step', 'ticks')]
    ax3.axis('off')
    txt = ['How an envelope entry is read (3 bytes):',
           '  steps: how many steps the segment has',
           '  step: added to the volume (signed) at each step',
           '  ticks: the ticks between two steps',
           '',
           'Example $BDF3 (env 3, channel A\'s first call):',
           '  8A 06 | 02 07 01 | 0F FF 03',
           '  2 steps of +7, one a tick: 0 > 7 > 13 (ceiling)',
           '  15 steps of -1, one every 3 ticks: 13 > 0',
           '  the table ends: step 0, counters $FF (held)']
    ax3.text(0, 1, '\n'.join(txt), va='top', fontsize=10.5, family='DejaVu Sans Mono', color=B.TEXT)
    del rows, M
    ax4 = fig.add_subplot(gs[3, :])
    ft = menu['frame_t']
    starts = [e[0] * ft + e[1] for e in menu['entries']['B767']]
    t0 = menu['entries']['B6EC'][0][0] * ft + menu['entries']['B6EC'][0][1]
    vol, per, cur_p = [], [], [0, 0]
    tick_of = lambda w: int(np.searchsorted(starts, w, side='right')) - 1  # noqa: E731
    for f, t, r, v in menu['writes']:
        w = f * ft + t
        if w < t0:
            continue
        k = tick_of(w)
        if r == 8:
            vol.append((k, v))
        elif r in (0, 1):
            cur_p[r] = v
            if r == 0:
                per.append((k, cur_p[0] | cur_p[1] << 8))
    lim = 90
    t, first, ticks = A.run_tune(len(starts))
    mv, mp, cp = [], [], [0, 0]
    for k, ws in enumerate(ticks):
        for r, v in ws:
            if r == 8:
                mv.append((k, v))
            elif r in (0, 1):
                cp[r] = v
                if r == 0:
                    mp.append((k, cp[0] | cp[1] << 8))
    sv = [(k, v) for k, v in vol if k < lim]
    ax4.step([k for k, v in mv if k < lim], [v for k, v in mv if k < lim], where='post', color=B.DIM, lw=3,
             label='model (aymodel.py): register 8')
    ax4.plot([k for k, v in sv], [v for k, v in sv], 'o', color=CH_COL[0], ms=5,
             label='c128 trace: each write to register 8 (channel A volume)')
    ax4.set_ylabel('volume A')
    fe = menu['entries']['B767']
    ax4.set_xlabel(f'tick (TuneTick calls from TuneStart; c128 frames {fe[0][0]}-{fe[lim - 1][0]})')
    ax4.set_xlim(-1, lim)
    ax5 = ax4.twinx()
    sp = [(k, p) for k, p in per if k < lim]
    ax5.plot([k for k, p in sp], [p for k, p in sp], 's', color=(1.0, 0.5, 0.8), ms=4,
             label='c128 trace: each period write (registers 0/1), right axis')
    ax5.set_ylabel('period A')
    h1, l1 = ax4.get_legend_handles_labels()
    h2, l2 = ax5.get_legend_handles_labels()
    ax4.legend(h1 + h2, l1 + l2, fontsize=10, loc='upper right')
    ax4.set_ylim(-0.5, 22)
    ax4.set_title(B.wrap('Witness: channel A\'s first notes in c128. Note 1 (period 159, 697 Hz) at tick 1: volume 7, 13, '
                         'then one less every 3 ticks; the period wobbles 159-161 (the vibrato); note 2 (period 213) at '
                         'tick 11. All 2218 writes of 360 ticks equal the model', 110), fontsize=11)
    ax4.grid(True, alpha=0.3)
    B.suptitle(fig, 'The AY tune\'s envelopes: each note restarts a volume envelope (set by an $8A sub-stream) and the '
               'vibrato table; TuneChannelStep steps both once a tick')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'ay-envelopes.png'))


# --- the order lists -------------------------------------------------------------------------------------------------

def order_walk():
    """per channel: the top-level calls of the order list with the ticks they span (static walk; B is one tick behind
    A and C two, the deferrals of the first ticks), and the envelope calls inside"""
    M = B.image()
    res = {}
    for ci, (ch, start) in enumerate(zip(CH, A.TUNE_STREAMS)):
        rec = A.TUNE_RECORDS[ci]
        length = M[rec + 0x0A]
        p, stack, t = start, [], ci
        top, cur, envs = [], None, []
        while True:
            a = M[p]
            if a < 0x64:
                if a >= 0x32:
                    length = M[p + 1]
                    p += 1
                t += length
                p += 1
                if cur is None:
                    top.append(['note', t - length, t])
                else:
                    cur[2] = t
            elif a in (0x64, 0x79):
                p += 1 if a == 0x64 else 2
            elif a == 0x75:
                tgt = B.word(M, p + 1)
                if not stack:
                    if ENV_FIRST <= tgt <= ENV_END:
                        envs.append((t, tgt))
                    else:
                        cur = [tgt, t, t]
                        top.append(cur)
                elif ENV_FIRST <= tgt <= ENV_END:
                    envs.append((t, tgt))
                stack.append(p + 3)
                p = tgt
            elif a == 0x76:
                p = stack.pop()
                if not stack:
                    cur = None
            elif a == 0x8A:
                p += M[p + 1] + 2
            elif a == 0xFF:
                break
        res[ch] = (top, envs, t)
    return res


def order():
    res = order_walk()
    envs_all = {a: k + 1 for k, (a, e) in enumerate(envelope_list())}
    B.style()
    fig, axs = plt.subplots(3, 1, figsize=(B.WIDTH, 13), gridspec_kw={'height_ratios': [1.15, 1.15, 1.5]})
    end = min(v[2] for v in res.values())
    for ax, ch in zip(axs, CH):
        top, envs, total = res[ch]
        pats = sorted({x[0] for x in top if x[0] != 'note'})
        row = {pp: k for k, pp in enumerate(pats)}
        for k, (pp, a, b) in enumerate(top):
            if pp == 'note':
                ax.broken_barh([(a, b - a)], (len(pats) - 0.4, 0.8), color=B.DIM)
                continue
            ax.broken_barh([(a, b - a - 4)], (row[pp] - 0.4, 0.8), color=CH_COL['ABC'.index(ch)])
        for t, e in envs:
            ax.plot([t], [-1], 'v', color=(1.0, 0.5, 0.8), ms=6)
        labels = [f'${pp:04X}' for pp in pats] + ['own note']
        ax.set_yticks([-1] + list(range(len(labels))))
        ax.set_yticklabels(['env set'] + labels, fontsize=10)
        ax.set_ylim(-1.7, len(labels) - 0.4)
        ax.invert_yaxis()
        ax.axvline(end, color=B.TEXT, ls='--', lw=1)
        ax.grid(True, axis='x', alpha=0.3)
        calls = sum(1 for x in top if x[0] != 'note')
        ax.set_title(B.wrap(f'channel {ch}: {calls} pattern calls from the order list at '
                            f'${A.TUNE_STREAMS["ABC".index(ch)]:04X}, {len(pats)} distinct patterns, {len(envs)} '
                            f'envelope settings (pink), its $FF at tick {total}', 110), fontsize=11)
        ax.set_xlim(0, 6600)
        ax.set_ylabel('pattern')
    axs[-1].set_xlabel(B.wrap(f'tick of TuneTick (B starts one tick after A, C two: the deferred first reads); '
                              f'dashed: tick {end}, C\'s $FF, TuneEnd stops all three', 110))
    del envs_all
    B.suptitle(fig, 'The tune\'s structure: each channel\'s order list calls patterns ($75 lo hi ... $76); the same '
               'pattern played again is the same row, so repeats read along a row')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'ay-order.png'))


# --- AY registers over time -------------------------------------------------------------------------------------------

def reg_series(d, f_from=None):
    """per register: (time in frames, value) of each write; mixer as is"""
    ft = d['frame_t']
    out = {r: [] for r in range(14)}
    for f, t, r, v in d['writes']:
        if r is None or r > 13:
            continue
        x = f + t / ft
        if f_from is not None and f < f_from:
            continue
        out[r].append((x, v))
    return out


def steps(ax, pts, x1, **kw):
    if not pts:
        return
    xs = [p[0] for p in pts] + [x1]
    ys = [p[1] for p in pts] + [pts[-1][1]]
    ax.step(xs, ys, where='post', **kw)


def period_series(s, lo, hi):
    cur, out = [0, 0], []
    for (x, v), r in sorted([(p, lo) for p in s[lo]] + [(p, hi) for p in s[hi]], key=lambda q: (q[0][0], q[1] == lo)):
        cur[0 if r == lo else 1] = v
        out.append((x, cur[0] | cur[1] << 8))
    return out


def mixer_rows(ax, s7, x1):
    """register 7 as six on/off rows: tone A-C, noise A-C (a bit 0 = on)"""
    names = ['tone A', 'tone B', 'tone C', 'noise A', 'noise B', 'noise C']
    pts = s7 + [(x1, s7[-1][1])] if s7 else []
    for b in range(6):
        for (x, v), (x2, _) in zip(pts, pts[1:]):
            if not v >> b & 1:
                ax.broken_barh([(x, x2 - x)], (b - 0.35, 0.7), color=CH_COL[b % 3] if b < 3 else
                               tuple(c * 0.7 for c in CH_COL[b % 3]))
    ax.set_yticks(range(6))
    ax.set_yticklabels(names, fontsize=10)
    ax.set_ylim(-0.6, 5.6)
    ax.invert_yaxis()


def menuregs():
    d = load('menu-ay.json')
    s = reg_series(d)
    x0, x1 = 12150, 12400
    B.style()
    fig, axs = plt.subplots(4, 1, figsize=(B.WIDTH, 12.5), sharex=True,
                            gridspec_kw={'height_ratios': [1.6, 1.3, 0.6, 1.0]})
    for ci in range(3):
        ps = period_series(s, 2 * ci, 2 * ci + 1)
        pts = [(x, hz(p)) for x, p in ps if p]
        steps(axs[0], pts, x1, color=CH_COL[ci], lw=1.2, label=f'channel {CH[ci]} (registers {2 * ci}/{2 * ci + 1})')
    axs[0].set_yscale('log')
    axs[0].set_yticks([100, 200, 400, 800, 1600])
    axs[0].set_yticklabels(['100', '200', '400', '800', '1600'])
    axs[0].minorticks_off()
    axs[0].set_ylabel('tone Hz')
    axs[0].legend(fontsize=10, ncol=3, loc='upper right')
    axs[0].set_title('Tone periods as Hz (1 773 400 / 16 P): melody on A, middle voice on C; B\'s period is written but\n'
                     'its tone is off (B plays the drums on noise); the small wobble on every note is the vibrato', fontsize=11)
    for ci in range(3):
        steps(axs[1], s[8 + ci], x1, color=CH_COL[ci], lw=1.2, label=f'{CH[ci]} (register {8 + ci})')
    axs[1].set_ylabel('volume')
    axs[1].set_ylim(-0.5, 15.5)
    axs[1].legend(fontsize=10, ncol=3, loc='upper right')
    axs[1].set_title('Volumes: each note a sawtooth (the attack, then a fall of one every few ticks)', fontsize=11)
    steps(axs[2], s[6], x1, color=(1.0, 0.5, 0.8), lw=1.4)
    axs[2].set_ylabel('noise P')
    axs[2].set_ylim(0, 34)
    axs[2].set_title('Noise period (register 6): $79 n in B\'s drum pattern, 31 (low) and 15 (high)', fontsize=11)
    mixer_rows(axs[3], s[7], x1)
    axs[3].set_title('Mixer (register 7, a bar = on): B switches from tone to noise for the drums ($64) and back',
                     fontsize=11)
    axs[3].set_xlabel('c128 frame (the menu; TuneStart at the left; 360 TuneTick calls, 1.44 a frame)')
    axs[3].set_xlim(x0, x1)
    n = len(d['writes'])
    B.suptitle(fig, f'The AY registers in the 128K menu, from the c128 trace: {n} writes in 250 frames, all from '
               'the tune (TuneTick and AySilence); the model gives the same writes')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'ay-registers-menu.png'))


SLOT_NAMES = {0xC5A1: 'shot', 0xC305: 'blast', 0xC366: 'grenade A', 0xC3D8: 'grenade B', 0xC264: 'noise burst',
              0xC462: 'pulse (teleport)', 0xC218: 'ammo refill', 0xC23E: 'grenade refill', 0xC33E: 'explosion',
              0xC35C: 'hum A', 0xC361: 'hum B', 0xC280: 'trill', 0xC2C7: 'noise sweep'}


def lanes(ax, p, log, ticks_x, title, extra=None, legend_out=False, legend_row=False):
    """one row per slot used: each tick coloured by the AY channel the slot got (grey: none, red x: freed)"""
    slots = sorted({u[0] for us in p.channels for u in us})
    names = {}
    for k, kind, slot, stream in log:
        names.setdefault(slot, set()).add(SLOT_NAMES.get(int(stream, 16), stream))
    for slot, name in (extra or {}).items():
        names.setdefault(slot, set()).add(name)
    row = {s: k for k, s in enumerate(slots)}
    for k, us in enumerate(p.channels):
        x = ticks_x[k]
        w = (ticks_x[k + 1] - x) if k + 1 < len(ticks_x) else (x - ticks_x[k - 1])
        for slot, chan, bits in us:
            y = row[slot]
            if chan in ('A', 'B', 'C'):
                ax.broken_barh([(x, w * 0.92)], (y - 0.38, 0.76), color=CH_COL['ABC'.index(chan)])
                if bits != {'A': 'F6', 'B': 'ED', 'C': 'DB'}[chan]:
                    ax.plot([x + w / 2], [y], marker='*', color=(1.0, 0.3, 0.3), ms=13)
            elif chan is None:
                ax.broken_barh([(x, w * 0.92)], (y - 0.38, 0.76), color=(0.45, 0.45, 0.5))
            else:
                ax.plot([x + w / 2], [y], marker='x', color=(1.0, 0.3, 0.3), ms=9, mew=2)
    ax.set_yticks(range(len(slots)))
    ax.set_yticklabels([f'slot {s}: ' + ' / '.join(sorted(names.get(s, {'?'}))) for s in slots], fontsize=10)
    ax.set_ylim(-0.6, len(slots) + (1.4 if legend_row else -0.4))
    ax.invert_yaxis()
    ax.set_title(title, fontsize=11)
    ax.legend(handles=[Patch(color=CH_COL[0], label='channel A'), Patch(color=CH_COL[1], label='channel B'),
                       Patch(color=CH_COL[2], label='channel C'), Patch(color=(0.45, 0.45, 0.5), label='no channel'),
                       plt.Line2D([], [], marker='x', ls='', color=(1.0, 0.3, 0.3), mew=2, label='freed ($FF)'),
                       plt.Line2D([], [], marker='*', ls='', color=(1.0, 0.3, 0.3), ms=11,
                                  label='mixer bits of the wrong channel')],
              **({'fontsize': 10, 'ncol': 3} | ({'loc': 'upper center', 'bbox_to_anchor': (0.5, -0.2)} if legend_out
                                      else {'loc': 'lower center', 'ncol': 3, 'fontsize': 10} if legend_row
                                      else {'loc': 'lower right'})))


def ticks_frames(d):
    ft = d['frame_t']
    return [e[0] + e[1] / ft for e in d['entries']['BF7E']]


def playregs():
    d = load('play-ay.json')
    p, log, bad = A.check_sfx()
    assert not bad
    tx = ticks_frames(d)
    s = reg_series(d)
    x0, x1 = 20000, 20100
    B.style()
    fig, axs = plt.subplots(4, 1, figsize=(B.WIDTH, 13), sharex=True,
                            gridspec_kw={'height_ratios': [1.0, 1.2, 1.2, 1.0]})
    lanes(axs[0], p, log, tx, 'Slots to channels, tick by tick (SoundEffectsTick, three a pass)', legend_row=True)
    k93 = tx[93]
    for ax in axs:
        ax.axvline(k93, color=(1.0, 0.3, 0.3), lw=0.8, ls=':')
    for ci in range(3):
        steps(axs[1], s[8 + ci], x1, color=CH_COL[ci], lw=1.3, label=f'{CH[ci]} (register {8 + ci})')
    axs[1].set_ylabel('volume')
    axs[1].set_ylim(-0.5, 15.5)
    axs[1].legend(fontsize=10, ncol=1, loc='lower left')
    axs[1].set_title('Volumes: each effect falls in the steps its stream gives ($FE n);\n'
                     'a freed channel keeps its last volume, the mixer turns it off', fontsize=11)
    for ci in range(3):
        ps = period_series(s, 2 * ci, 2 * ci + 1)
        pts = [(x, hz(pp)) for x, pp in ps if pp]
        steps(axs[2], pts, x1, color=CH_COL[ci], lw=1.3, label=CH[ci])
    axs[2].set_yscale('log')
    axs[2].set_yticks([50, 100, 200, 400, 800, 1600, 3200, 6400])
    axs[2].set_yticklabels(['50', '100', '200', '400', '800', '1600', '3200', '6400'])
    axs[2].minorticks_off()
    axs[2].set_ylabel('tone Hz')
    axs[2].set_title('Tone periods as Hz: the blast falls note by note, the grenade\'s two sweeps a fifth apart',
                     fontsize=11)
    mixer_rows(axs[3], s[7], x1)
    axs[3].set_title('Mixer (register 7): written every tick, all off ($BF) when no slot plays', fontsize=11)
    axs[3].set_xlabel(f'c128 frame (play; dotted red: tick 93 at frame {k93:.1f}, the blast freed, the next slots\' '
                      'bits one channel ahead)')
    axs[3].set_xlim(x0, x1)
    B.suptitle(fig, f'The AY registers in 128K play, from the c128 trace: {len(d["writes"])} writes in 100 frames; '
               'the first active slots take A, B, C in slot order; the model gives the same writes')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'ay-registers-play.png'))


def channels():
    d = load('x2-1600_0-1700_0.json')
    p, log, bad = A.check_sfx(os.path.join(FILLS, 'x2-1600_0-1700_0.json'), os.path.join(FILLS, 'x2-slots-1600.json'))
    assert not bad
    tx = ticks_frames(d)
    B.style()
    fig, ax = plt.subplots(1, 1, figsize=(B.WIDTH, 6.2))
    # slots 6, 9 and 15 were running at frame 1600 (memory_at): their streams lie in BlastSound, GrenadeSoundA/B
    lanes(ax, p, log, tx, '', extra={9: 'grenade A', 15: 'grenade B'}, legend_out=True)
    ax.set_xlim(1600, 1700)
    ax.set_xlabel('x2 frame (48K: the same engine runs, its OUTs reach no AY; 89 ticks, 772 writes, the model '
                  'gives the same)')
    B.suptitle(fig, 'Four effects, three channels: slot 15 (grenade B, then two shots) is the fourth active slot at '
               'frames 1610-1616 and 1668-1691 and gets no channel; at 1617 and 1625 a freed slot hands the pulse a '
               'channel with the next channel\'s bits')
    fig.tight_layout(rect=(0, 0, 1, 0.88))
    B.save(fig, B.out('sound', 'sfx-channels.png'))


# --- the 17 effects on paper -----------------------------------------------------------------------------------------

EFFECTS = [  # (name, starter, [(slot, stream)], trigger)
    ('shot', 0xC177, [(15, 0xC5A1)], 'FirePress $8372'),
    ('noise burst', 0xC0E7, [(13, 0xC264)], 'MoveShots $8417'),
    ('blast', 0xC148, [(6, 0xC305)], 'FireShell, GrenadeBlast'),
    ('explosion', 0xC155, [(8, 0xC33E)], 'a thing destroyed'),
    ('grenade', 0xC1BE, [(9, 0xC366), (15, 0xC3D8)], 'ThrowGrenade $9254'),
    ('noise sweep', 0xC13B, [(7, 0xC2C7)], 'Guns $9DBB'),
    ('trill', 0xC12E, [(5, 0xC280)], 'bonus $9EB1, $A32B'),
    ('ammo refill', 0xC0F4, [(2, 0xC218)], 'ammo pod $9980, $9F65'),
    ('grenade refill', 0xC101, [(2, 0xC23E)], 'grenade pod $99D6'),
    ('pulse', 0xC162, [(13, 0xC462)], 'Teleports $98F3, $9928'),
    ('hum', 0xC1A9, [(1, 0xC35C), (11, 0xC361)], 'ForceFieldStep $ABD6'),
    ('jingle A', 0xC10E, [(4, 0xC55D)], 'no caller'),
    ('jingle B', 0xC116, [(14, 0xC54D), (5, 0xC56D)], 'no caller'),
    ('wobble', 0xC126, [(13, 0xC5BA)], 'no caller'),
    ('rise', 0xC16F, [(12, 0xC5C8)], 'no caller'),
    ('chord', 0xC17F, [(8, 0xC577), (9, 0xC585), (10, 0xC593)], 'no caller'),
    ('fanfare', 0xC195, [(0, 0xC44A), (15, 0xC53F)], 'no caller'),
]


def stream_labels():
    """label addresses from the listing, to check the stream addresses above"""
    out = {}
    for line in open(os.path.join(B.CASE, 'build', 'game.lst')):
        parts = line.split()
        if len(parts) == 3 and parts[2].endswith('Sound:') and len(parts[1]) == 4:
            out[parts[2][:-1]] = int(parts[1], 16)
    return out


def effect_run(starts, max_ticks=400):
    """one effect alone from fresh slots: per tick, per voice (slot): (note period, volume, mixer mask) or None"""
    p = A.SfxPlayer()
    for k in range(16):
        p.m[A.SFX_SLOTS + 16 * k] = 0xFF
        for j in range(1, 16):
            p.m[A.SFX_SLOTS + 16 * k + j] = 0
    for slot, stream in starts:
        p.start(slot, stream)
    rows = []
    for _ in range(max_ticks):
        p.tick()
        row = []
        for slot, stream in starts:
            ix = A.SFX_SLOTS + 16 * slot
            if p.m[ix] == 0xFF:
                row.append(None)
            else:
                row.append((p.m[ix + 9] | p.m[ix + 10] << 8, p.m[ix + 4], p.m[ix + 0x0B], p.noise))
        rows.append(row)
        if all(r is None for r in row):
            break
    while rows and all(r is None for r in rows[-1]):
        rows.pop()
    return rows


def effect_lengths():
    return {name: len(effect_run(starts)) for name, _, starts, _ in EFFECTS}


def sheet():
    lab = stream_labels()
    B.style()
    fig, axs = plt.subplots(6, 3, figsize=(B.WIDTH, 15.5))
    axs = axs.ravel()
    for ax, (name, starter, starts, trig) in zip(axs, EFFECTS):
        rows = effect_run(starts)
        n = len(rows)
        for vi in range(len(starts)):
            for k, r in enumerate(rows):
                if not r[vi]:
                    continue
                per, vol, mask, noise = r[vi]
                f = hz(per)
                if mask != 0x07 and f:
                    ax.broken_barh([(k, 1)], (f / 1.04, f * 0.08), color=plt.cm.viridis(vol / 15))
                if mask != 0x38:
                    ax.broken_barh([(k, 1)], (25, 6), color=plt.cm.magma(0.3 + vol / 22))
        ax.set_yscale('log')
        ax.set_ylim(22, 4000)
        ax.set_yticks([100, 400, 1600])
        ax.set_yticklabels(['100', '400', '1600'], fontsize=10)
        ax.minorticks_off()
        ax.set_xlim(0, max(n, 4))
        slots = '+'.join(str(s) for s, _ in starts)
        ax.set_title(f'{name}: slot {slots}, {n} ticks\n{trig}', fontsize=10)
        ax.tick_params(axis='x', labelsize=10)
    axs[-1].axis('off')
    axs[-1].text(0, 0.95, 'How to read:\n- x: ticks from the start\n  (3 a pass, about 2/3 frame)\n- bars: the tone '
                 'note at its Hz,\n  colour = volume (dark 0,\n  yellow 15)\n- bottom strip: the noise on', va='top',
                 fontsize=10.5)
    B.suptitle(fig, 'The 17 AY effects as the engine plays them (aymodel.py, each alone from free slots): the tone '
               'of each tick at its pitch, its volume as colour, the noise strip below')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'sfx-sheet.png'))
    del lab


# --- the speaker in play -----------------------------------------------------------------------------------------------

SPEAKER_SOURCES = {0x95A3: ('debris crackle $95A3', (1.0, 0.85, 0.3)),
                   0x7C2F: ('BeeperNoise $7C2F (random level)', (0.4, 0.75, 1.0)),
                   0x7C37: ('BeeperNoise $7C37 (back to 0)', (0.25, 0.45, 0.8)),
                   0x7C4E: ('BeeperSweep $7C4E', (0.95, 0.4, 0.9))}
CALLERS = {0x9FF3: 'RunBlasts', 0x844E: 'ShotHitNoise', 0x835D: 'FirePress', 0x9EC1: 'PayBonusTick'}


def speaker_rows():
    """the rows of the speaker figure: (json, frame, what the row shows)"""
    return [('x2-400_0-470_0.json', 413, 'debris crackle (MoveDebris): one OUT per piece moved'),
            ('x2-2125_0-2185_0.json', 2128, 'ShotHitNoise: 20 bursts of B 20 (a thing shot)'),
            ('x2-2125_0-2185_0.json', 2130, 'RunBlasts: the end of ShotHitNoise, then a blast burst of B 24'),
            ('x2-2125_0-2185_0.json', 2136, 'FirePress: one burst of B 60 (the laser)'),
            ('x2-1600_0-1700_0.json', 1657, 'BeeperSweep: a pod taken (sweep 1 of 5)')]


def speaker():
    B.style()
    rows = speaker_rows()
    fig, axs = plt.subplots(len(rows), 1, figsize=(B.WIDTH, 2.0 * len(rows) + 1.6), sharex=True)
    cache = {}
    for ax, (src, frame, what) in zip(axs, rows):
        d = cache.setdefault(src, load(src))
        n = {}
        for f, t, pc, v in d['fe']:
            if f != frame:
                continue
            name, col = SPEAKER_SOURCES.get(pc, (f'other ${pc:04X}', (0.7, 0.7, 0.7)))
            up = v & 0x10
            ax.plot([t, t], [0.1, 0.95 if up else 0.35], color=col, lw=1.0)
            n[name] = n.get(name, 0) + 1
        for e in d['entries'].get('75BE', []):
            if e[0] == frame:
                ax.axvline(e[1], color=B.TEXT, lw=1, ls='--')
        ax.set_ylim(0, 1)
        ax.set_yticks([])
        ax.set_ylabel(f'{src[:2]} {frame}', rotation=0, ha='right', va='center', fontsize=10.5)
        cnt = ', '.join(f'{v} {k.split(" ")[0]}' for k, v in n.items())
        ax.set_title(f'{what}: {cnt} OUTs', fontsize=10.5, loc='left')
    axs[-1].set_xlim(0, 69888)
    axs[-1].set_xlabel('T-state in the frame (0-69 887); dashed: a main loop pass starts ($75BE)')
    fig.legend(handles=[Patch(color=c, label=n) for n, c in SPEAKER_SOURCES.values()], ncol=2, fontsize=10,
               loc='lower center', bbox_to_anchor=(0.5, 0.005))
    B.suptitle(fig, 'Who drives the 48K speaker in play (x2 traces): every OUT ($FE) of five frames, a tall tick '
               'sets the speaker bit, a short one clears it; the CPU stops for each burst')
    fig.tight_layout(rect=(0, 0.06, 1, 0.93))
    B.save(fig, B.out('sound', 'speaker-play.png'))


def sweep():
    d = load('x2-1600_0-1700_0.json')
    ft = d['frame_t']
    o = [(f * ft + t, v, f, t) for f, t, pc, v in d['fe'] if pc == 0x7C4E]
    first = o[:160]
    dt = [b[0] - a[0] for a, b in zip(first, first[1:])]
    model = [13 * (48 + k // 10) + 33 for k in range(159)]
    B.style()
    fig, ax = plt.subplots(1, 1, figsize=(B.WIDTH, 5.0))
    ax.plot(range(159), model, color=B.DIM, lw=3, label='model: 13 E + 33 T (E = 48 ... 63, uncontended)')
    contended = [k for k in range(159) if dt[k] > model[k] + 2]
    ax.plot(range(159), dt, 'o', color=(0.95, 0.4, 0.9), ms=3.5, label='x2 trace: the time between two OUTs')
    ax.set_xlabel(B.wrap(f'half-wave (10 a step; step 1 = E 48 on the left), x2 frame {first[0][2]} T {first[0][3]} on; '
                         f'{len(contended)} of 159 stretched by contention (the beam on the screen lines)', 110))
    ax.set_ylabel('T-states')
    for k in range(0, 160, 10):
        ax.axvline(k - 0.5, color=(0.3, 0.3, 0.35), lw=0.6)
    ax.legend(fontsize=10.5, loc='upper left')
    ax.grid(True, axis='y', alpha=0.3)
    tot = first[-1][0] - first[0][0]
    B.suptitle(fig, f'BeeperSweep $7C3C: 16 steps of 10 half-waves, each step 13 T longer (2664 Hz down to 2054 Hz '
               f'uncontended); one sweep took {tot} T ({tot / 3500:.1f} ms) against 120 720 T uncontended')
    fig.tight_layout(rect=(0, 0, 1, 0.9))
    B.save(fig, B.out('sound', 'sweep-halfwaves.png'))


# --- audio -------------------------------------------------------------------------------------------------------------

def speaker_wav(src, out, rate=44100):
    """the speaker bit (bit 4) of every OUT ($FE) of a trace as a waveform: a synthesis from the trace, not the
    emulator's audio output (a TTD replay produces no sound)"""
    d = load(src)
    ft = d['frame_t']
    t0 = d['from'] * ft
    t1 = (max(f for f, t, pc, v in d['fe']) + 1) * ft
    n = int((t1 - t0) / 3500000 * rate)
    x = np.zeros(n)
    level, last = 0.0, 0
    for f, t, pc, v in d['fe']:
        k = int((f * ft + t - t0) / 3500000 * rate)
        x[last:k] = level
        level = 1.0 if v & 0x10 else 0.0
        last = k
    x[last:] = level
    y = np.zeros_like(x)        # a 3.5 Hz high-pass (the DC of the speaker)
    a = 1 / (1 + 2 * np.pi * 3.5 / rate)
    for k in range(1, len(x)):
        y[k] = a * (y[k - 1] + x[k] - x[k - 1])
    pcm = (np.clip(y, -1, 1) * 12000).astype(np.int16)
    with wave.open(out, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())
    return n / rate


AUDIO = [  # (mp3 name, source wav in work/docs/docB/audio or 'speaker:<json>', cut (s from, s to) or None)
    ('beeper-title-tune', 'title-tune.wav', None),
    ('beeper-jingle', 'jingle.wav', None),
    ('beeper-fire', 'noise-3c-fire.wav', (0, 0.6)),
    ('beeper-shot-hit', 'noise-14x20-shot-hit.wav', (0, 0.6)),
    ('beeper-turret-shell', 'noise-1ex10-shell.wav', (0, 0.6)),
    ('beeper-bonus-tick', 'noise-28-bonus-tick.wav', (0, 0.6)),
    ('beeper-key-click', 'noise-c8-key-click.wav', (0, 0.6)),
    ('beeper-bravery-bonus', 'noise-3cx80-bravery.wav', (0, 1.6)),
    ('beeper-pod-sweep', 'sweep-pod.wav', (0, 0.6)),
    ('beeper-play-debris-x2-400', 'speaker:x2-400_0-470_0.json', None),
    ('beeper-play-x2-2125', 'speaker:x2-2125_0-2185_0.json', None),
    ('ay-title-tune', 'ay-title-tune.wav', 'tune'),
] + [(f'ay-{n}', f'sfx-{n}.wav', (0, 3.0)) for n in
     ('shot', 'noise-burst', 'blast', 'explosion', 'grenade', 'noise-sweep', 'trill', 'ammo-refill', 'grenade-refill',
      'pulse', 'hum', 'jingle-a', 'jingle-b', 'wobble', 'rise', 'chord', 'fanfare')]


def first_sound(path):
    w = wave.open(path)
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)[0::w.getnchannels()].astype(float)
    d = np.flatnonzero(np.abs(np.diff(x)) > 300)
    return (d[0] / w.getframerate() if len(d) else 0.0), w.getnframes() / w.getframerate()


def audio():
    os.makedirs(AUDIO_OUT, exist_ok=True)
    tmp = os.path.join(FILLS, 'audio')
    os.makedirs(tmp, exist_ok=True)
    made = []
    for name, src, cut in AUDIO:
        out = os.path.join(AUDIO_OUT, name + '.mp3')
        if src.startswith('speaker:'):
            wav = os.path.join(tmp, name + '.wav')
            secs = speaker_wav(src.split(':', 1)[1], wav)
            a, b = 0.0, secs
        else:
            wav = os.path.join(AUDIO_IN, src)
            start, total = first_sound(wav)
            if cut == 'tune':
                log = json.load(open(os.path.join(AUDIO_IN, 'ay-title-tune.json')))['log']
                per = total / len(log)
                a, b = 2505 * per, 6722 * per
            elif cut:
                a, b = max(0.0, start - 0.05), start - 0.05 + cut[1]
            else:
                a, b = max(0.0, start - 0.05), total
        cmd = ['ffmpeg', '-loglevel', 'error', '-y', '-ss', f'{a:.3f}', '-to', f'{b:.3f}', '-i', wav, '-ac', '1',
               '-af', 'highpass=f=3.5', '-codec:a', 'libmp3lame', '-b:a', '128k', out]
        subprocess.run(cmd, check=True)
        made.append((name, src, a, b, os.path.getsize(out)))
        print(f'{name}.mp3: {src} {a:.2f}-{b:.2f} s, {os.path.getsize(out) // 1024} KB')
    json.dump(made, open(os.path.join(tmp, 'made.json'), 'w'), indent=1)


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    jobs = {'envelopes': envelopes, 'order': order, 'menuregs': menuregs, 'playregs': playregs,
            'channels': channels, 'sheet': sheet, 'speaker': speaker, 'sweep': sweep, 'audio': audio}
    for k, f in jobs.items():
        if what in (k, 'all'):
            f()


if __name__ == '__main__':
    main()
