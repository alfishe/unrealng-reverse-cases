#!/usr/bin/env python3
"""Doc 09: the tunes and the beeper effects drawn and rendered.

The tunes come from build/res/music through the T-state model of PlayTune (tools/tune_model.py, checked against the
traced cave tune of rzx-earth01). The effects come from the speaker writes of the traced recordings
(tools/sound_events.py: work/docs/esD/ev-<recording>-<frames>.json).

    python3 tools/fig_sound.py tunes      docs/img/sound/tunes-caves.png, tunes-other.png: every tune as a piano roll
    python3 tools/fig_sound.py mix        docs/img/sound/playtune-mix.png: two voices, one speaker (trace and model)
    python3 tools/fig_sound.py shapes     docs/img/sound/effects.png: one call of each effect, the speaker bit
    python3 tools/fig_sound.py pitch      docs/img/sound/effects-pitch.png: each effect's half periods over time
    python3 tools/fig_sound.py models     docs/img/sound/effects-code-only.png: PasswordAccepted and the fizz, modelled
    python3 tools/fig_sound.py spectro    docs/img/sound/spectrograms.png: each effect's WAV as a spectrogram
    python3 tools/fig_sound.py irq        docs/img/sound/interrupts.png: the interrupts taken and lost, rzx-earth01
    python3 tools/fig_sound.py wav        docs/audio/*.wav (22 050 Hz, 8 bit, mono)
    python3 tools/fig_sound.py table      the numbers of doc 09 (each effect measured)
    python3 tools/fig_sound.py all
"""
import argparse
import json
import os
import sys
import wave

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import matplotlib.ticker  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import tune_model as TM  # noqa: E402

EV = os.path.join(CASE, 'work', 'docs', 'esD')
IMG = os.path.join(CASE, 'docs', 'img', 'sound')
AUDIO = os.path.join(CASE, 'docs', 'audio')
CLOCK, FT, RATE = 3_500_000, 69_888, 22_050
NAMES = ['F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E']

plt.rcParams.update({'font.size': 11, 'axes.titlesize': 11, 'axes.labelsize': 10.5, 'xtick.labelsize': 10,
                     'ytick.labelsize': 10, 'legend.fontsize': 10, 'text.parse_math': False})

# the effects: name -> (events file, routine, its entry name in the calls, which call (0 first), what)
EFFECTS = {
    'dig': ('rzx01-770-780', 'DigNoiseIfDug', 0, 'the dig noise: 255 ROM bytes AND $18 (DigNoiseLoop $854A)'),
    'gem': ('rzx01-812-818', 'GemSound', 0, 'a gem: three ROM BEEPER tones (GemSound $82F9)'),
    'fall': ('rzx01-1575-1582', 'FallSound', 0, 'an object falls: FallSound $E7A9'),
    'thud': ('rzx01-1836-1842', 'ThudSound', 0, 'a boulder lands: NoiseThud $E77C, 3 x NoiseBurst'),
    'jelly-bean': ('rzx01-1524-1570', 'JellyBean', 0, 'a jelly bean: 32 pairs of BEEPER notes (JellyBean $91F7)'),
    'exit-open': ('rzx01-3366-3410', 'ExitOpenSound', 0, 'the exit opens: ExitOpenSound $9072'),
    'time-bonus': ('rzx01-3660-3740', 'TimeBonus', 0, 'the time bonus: a BEEPER tick a bar pixel (TimeBonus $8702)'),
    'timer-click': ('rzx01-800-830', 'TimerStep', None, 'the timer: a 1-cycle BEEPER click every 4th pass'),
    'death': ('death-crush-25-75', 'DeathSound', 0, 'the death: 256 BEEPER notes from ROM bytes (DeathLoop $8630)'),
    'switch': ('rzx02-384-402', 'SwitchSound', 0, 'the switch: Jingle $A713 three times, self-modified'),
    'rasp': ('rzx02-2445-2465', 'RaspSound', 0, 'a bubble bursts: RaspSound $90A0, 255 BEEPER notes'),
    'anti-gravity': ('rzx03-540-620', 'AntiGravSound', 0, 'anti-gravity taken: AntiGravSound $8156'),
    'teleport': ('rzx04-1173-1282', 'TeleportOutEffect', 0, 'a teleport: TeleportOutEffect $E87B + TeleportInEffect'),
    'time-out': ('timer-6035-6095', 'TimeOutSound', 0, 'the time is out: TimeOutSound $86AD'),
    'key-click': ('hiscore-4955-4980', 'KeyClick', 0, 'a key typed: KeyClick $8E18'),
    'anti-gravity-tick': ('rzx03-540-620', 'AntiGravPass', 1, 'each anti-gravity pass: BEEPER HL = 2 x steps, DE = 10'),
}


def load(key):
    d = json.load(open(os.path.join(EV, f'ev-{key}.json')))
    d['outs'] = [(f * FT + t, v, pc) for f, t, v, pc in d['out_fe']]
    d['abs_calls'] = [(f * FT + t, n, a, bc, de, hl, c) for f, t, n, a, bc, de, hl, c in d['calls']]
    d['irqs'] = [f * FT + t for f, t, _ in d['irq']]
    d['ints'] = [(f * FT + t, v) for f, t, pc, v in d['di']]
    return d


def save(fig, name):
    os.makedirs(IMG, exist_ok=True)
    p = os.path.join(IMG, name)
    fig.savefig(p, dpi=100)
    plt.close(fig)
    print(p)


def note_name(n):
    return f'{NAMES[n % 12]}{1 + (n + 7) // 12}'


def note_hz(n, per):
    return CLOCK / (78 * per[n])


# ------------------------------------------------------------------------------------------------------------ tunes
def roll(ax, name, per):
    data = TM.tune(name)
    w, ev, total = TM.play_tune(data, per)
    starts = [t for t, e in ev if e.startswith('note')]
    ns = TM.notes(data)
    ends = starts[1:] + [total]
    lo = min(min(n[1], n[2]) for n in ns)
    hi = max(max(n[1], n[2]) for n in ns)
    for (drum, n1, n2, ln), s, e in zip(ns, starts, ends):
        s, e = s / CLOCK, e / CLOCK
        for n, col, dy in ((n1, '#1f77b4', 0.18), (n2, '#d62728', -0.18)):
            ax.plot([s, e], [n + dy, n + dy], color=col, lw=3.2, solid_capstyle='butt')
        if drum in (1, 2):
            ax.plot([s], [lo - 2], marker='|' if drum == 1 else '.', color='k', ms=7)
    ticks = [n for n in range(0, 73, 12) if lo - 3 <= n <= hi + 3] or [lo]
    ax.set_yticks(ticks)
    ax.set_yticklabels([f'{n} {note_name(n)}' for n in ticks])
    ax.set_ylim(lo - 3.5, hi + 1.5)
    ax.set_xlim(0, total / CLOCK)
    f, a, who = TM.TUNES[name]
    ax.set_title(f'{name} ${a:04X}, {len(ns)} notes, {total / CLOCK:.2f} s ({total / FT:.0f} frames): {who}',
                 loc='left', fontsize=10.5)
    ax.grid(axis='x', alpha=0.3)


def cmd_tunes(_a):
    per = TM.periods()
    groups = [('tunes-caves.png', [f'CaveTune{i}' for i in range(1, 9)],
               'The eight cave tunes (one per four caves): voice 1 blue, voice 2 red, drums black (| drum 1, . drum 2)'),
              ('tunes-other.png', ['TitleTune', 'MapTune', 'LifeTune', 'GameOverTune', 'WinTune'],
               'The other five tunes: title, map, extra life, game over, win (voice 1 blue, voice 2 red, drums black)')]
    for fname, names, title in groups:
        fig, axes = plt.subplots(len(names), 1, figsize=(10.5, 1.55 * len(names) + 0.9))
        for ax, n in zip(axes, names):
            roll(ax, n, per)
        axes[-1].set_xlabel('seconds from PlayTune\'s DI (the T-state model, tools/tune_model.py)')
        fig.suptitle(title, fontsize=11.5)
        fig.tight_layout(rect=(0, 0, 1, 0.97))
        save(fig, fname)


# ------------------------------------------------------------------------------------------------------------ mix
def steps(writes, t0, t1, scale=1e3):
    xs, ys = [], []
    lvl = None
    for t, v in writes:
        if t < t0:
            lvl = v >> 4 & 1
            continue
        break
    first = lvl
    for t, v in writes:
        if t < t0:
            continue
        if t > t1:
            break
        b = v >> 4 & 1
        if lvl is not None:
            xs += [(t - t0) / CLOCK * scale]
            ys += [lvl]
        xs += [(t - t0) / CLOCK * scale]
        ys += [b]
        lvl = b
    xs.append((t1 - t0) / CLOCK * scale)
    ys.append(lvl)
    if first is not None:
        xs.insert(0, 0)
        ys.insert(0, first)
    return xs, ys


def cmd_mix(_a):
    d = load('rzx01-400-700')
    call = [c for c in d['abs_calls'] if c[1] == 'PlayTune'][0]
    pn = [c for c in d['abs_calls'] if c[1] == 'PlayNote'][1]  # note 2: 0 24 29 30, no drum
    t0 = pn[0] + 400
    span = int(0.025 * CLOCK)
    outs = [(t, v) for t, v, pc in d['outs']]
    v1 = [(t, v) for t, v, pc in d['outs'] if 0x893B <= pc <= 0x8940]
    v2 = [(t, v) for t, v, pc in d['outs'] if 0x894A <= pc <= 0x8950]
    fig, axes = plt.subplots(4, 1, figsize=(10.5, 7.6), sharex=False)
    ax = axes[0]
    for t, v in v1:
        if t0 <= t <= t0 + span:
            ax.axvline((t - t0) / CLOCK * 1e3, color='#1f77b4', lw=1.4)
    for t, v in v2:
        if t0 <= t <= t0 + span:
            ax.axvline((t - t0) / CLOCK * 1e3, color='#d62728', lw=1.4, ls='--')
    ax.set_yticks([])
    ax.set_xlim(0, span / CLOCK * 1e3)
    ax.set_title('1. rzx-earth01, CaveTune1 note 2 (0 24 29 30): voice 1 writes (blue, every 255 turns), voice 2 '
                 '(red dashed, every 192)', loc='left', fontsize=10)
    xs, ys = steps(outs, t0, t0 + span)
    axes[1].plot(xs, ys, drawstyle='default', color='k', lw=1)
    axes[1].set_xlim(0, span / CLOCK * 1e3)
    axes[1].set_yticks([0, 1])
    axes[1].set_yticklabels(['low', 'high'])
    axes[1].set_title('2. The speaker bit as traced: voice 1 sets it high (after an 18 T dip), voice 2 sets it low '
                      '(after a 15 T spike)', loc='left', fontsize=10)
    axes[1].set_xlabel('ms from the second note\'s start (frame %d T %d)' % (t0 // FT, t0 % FT))
    # the model of the same note
    mw, ev, total = TM.play_tune(TM.tune('CaveTune1'))
    starts = [t for t, e in ev if e.startswith('note')]
    m0 = starts[1] + 400
    xs, ys = steps(mw, m0, m0 + span)
    axes[2].plot(xs, ys, color='#2ca02c', lw=1)
    axes[2].set_xlim(0, span / CLOCK * 1e3)
    axes[2].set_yticks([0, 1])
    axes[2].set_yticklabels(['low', 'high'])
    axes[2].set_title('3. The same note from the T-state model (tools/tune_model.py): the same edges', loc='left',
                      fontsize=10)
    # unison notes: the time high in each of voice 1's periods, three pitches, length 20
    per = TM.periods()
    for n, col in ((24, '#1f77b4'), (36, '#2ca02c'), (48, '#d62728')):
        uw, uev, ut = TM.play_tune(bytes([0, n, n, 20, 0, 0xFF]), per)
        ups = [t for t, v in uw if v & 0x10]
        xs, ys = [], []
        for i in range(0, len(ups) - 2, 2):  # voice 1 writes 0 then $10: every second high write is voice 2's
            pass
        hi_t, prev_t, prev_l = {}, uw[0][0], uw[0][1] >> 4 & 1
        p1 = (per[n] - 1) * 78
        for t, v in uw[1:]:
            if prev_l:
                k = prev_t // p1
                hi_t[k] = hi_t.get(k, 0) + (t - prev_t)
            prev_t, prev_l = t, v >> 4 & 1
        ks = sorted(hi_t)
        axes[3].plot([k * p1 / CLOCK * 1e3 for k in ks], [hi_t[k] / p1 * 100 for k in ks], color=col, marker='.',
                     ms=3, lw=1, label=f'note {n} ({note_name(n)}, period {per[n]})')
    axes[3].set_ylabel('% of the period high')
    axes[3].set_ylim(0, 100)
    axes[3].legend(loc='upper left', fontsize=9.5)
    axes[3].set_title('4. Unison notes (N1 = N2, length 20, model): voice 1 fires every P-1 turns, voice 2 every P, so the '
                      'pulse widens by one turn a period', loc='left', fontsize=10)
    axes[3].set_xlabel('ms from the note\'s start')
    fig.suptitle('PlayTune\'s two voices on one speaker bit: each voice is a train of events, the level is set by one and '
                 'reset by the other', fontsize=11.5)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    save(fig, 'playtune-mix.png')


# ------------------------------------------------------------------------------------------------------------ effects
def effect_writes(name):
    key, routine, which, what = EFFECTS[name]
    d = load(key)
    if routine == 'TimerStep':  # the click: the TimerStep that called BEEPER
        bc = [c for c in d['abs_calls'] if c[1] == 'RomBeeper' and c[5] == 0 and c[4] == 0][0]
        t0 = bc[0]
        t1 = t0 + 2000
    else:
        calls = [c for c in d['abs_calls'] if c[1] == routine]
        t0 = calls[which][0]
        # the end: the next pass's routine entry after it, or the window's end
        after = [c[0] for c in d['abs_calls'] if c[0] > t0 and c[1] in ('PassLoop', 'AntiGravPass', 'CaveIntro',
                                                                         'DigNoiseIfDug', 'FizzSound', 'WaitKey')]
        if routine == 'TeleportOutEffect':
            after = [c[0] for c in d['abs_calls'] if c[0] > t0 and c[1] == 'TeleportInEffect']
            ins = after[0]
            after = [c[0] for c in d['abs_calls'] if c[0] > ins and c[1] in ('PassLoop', 'AntiGravPass')]
        t1 = after[0] if after else d['frames'][1] * FT
    w = [(t, v) for t, v, pc in d['outs'] if t0 <= t < t1]
    irq = [t for t in d['irqs'] if t0 <= t < t1]
    return d, t0, t1, w, irq


def cmd_shapes(_a):
    names = list(EFFECTS)
    fig, axes = plt.subplots(len(names), 1, figsize=(10.5, 1.12 * len(names) + 0.8))
    for ax, n in zip(axes, names):
        d, t0, t1, w, irq = effect_writes(n)
        if not w:
            continue
        a, b = w[0][0], w[-1][0]
        xs, ys = steps(w, a - 10, b + 10)
        span_ms = (b - a) / CLOCK * 1e3
        ax.plot(xs, ys, color='k', lw=0.6)
        ax.set_yticks([])
        ax.set_xlim(0, max(xs))
        key = EFFECTS[n][0]
        ax.set_title(f'{n}: {EFFECTS[n][3]}; {key.split("-")[0]} frame {a // FT}, {len(w)} writes, {span_ms:.1f} ms',
                     loc='left', fontsize=9.5)
        ax.tick_params(axis='x', labelsize=9)
    axes[-1].set_xlabel('ms from the first write of the call')
    fig.suptitle('Every beeper effect, one call each, as traced: the speaker bit (port $FE bit 4) held to the next write',
                 fontsize=11.5)
    fig.tight_layout(rect=(0, 0, 1, 0.985))
    save(fig, 'effects.png')


def password_model():
    """PasswordAccepted $8EE4 from its DI (no recording reaches it): D = 1 ... 255, each 1024 turns of a loop that
    toggles the speaker every D turns, then PasswordFlashStep (an LDIR of 19 attribute bytes)"""
    w, t, a = [], 0, 0
    for dd in range(1, 256):
        e = dd
        t += 4 + 10                                  # LD E,D; LD BC,$0004
        for k in range(1024):
            e -= 1
            if e == 0:
                t += 4 + 7 + 7
                a ^= 0x18
                w.append((t + 11, a))
                t += 11 + 4                          # OUT, LD E,D
                e = dd
            else:
                t += 4 + 12
            t += 13 if (k % 256) != 255 else 8 + 4 + (12 if k != 1023 else 7)
        t += 11 + 11 + 17 + 13 + 10 + 10 + 10 + 19 * 21 - 5 + 13 + 10 + 10 + 10 + 4 + 12   # the flash step
    return w, t


def fizz_model(pass_t=6 * FT):
    """FizzSound's seven beeps, one a pass while FizzCount runs down from 7: BEEPER HL = 16 x count, DE = 20"""
    w, t = [], 0
    for count in range(6, -1, -1):
        bw, t_end = TM.beeper(t, 16 * count, 20)
        w += bw
        t += pass_t
    return w, t


def cmd_models(_a):
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 3.6))
    for ax, (name, (w, total), what) in zip(axes, (
            ('PasswordAccepted $8EE4', password_model(), 'D = 1 to 255: toggle every D turns, 1024 turns a step'),
            ('FizzSound $A773', fizz_model(), 'seven BEEPER calls HL = 96 ... 0, DE = 20, one a pass (6 frames here)'))):
        xs = [(w[i][0] - w[0][0]) / CLOCK * 1e3 for i in range(1, len(w))]
        ys = [w[i][0] - w[i - 1][0] for i in range(1, len(w))]
        ax.scatter(xs, ys, s=2)
        ax.set_yscale('log')
        ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f'{v:g}'))
        ax.yaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
        ax.set_title(f'{name}: {len(w)} writes, {total / CLOCK:.2f} s', loc='left', fontsize=10)
        ax.set_xlabel(what, fontsize=9.5)
        ax.grid(alpha=0.3)
    axes[0].set_ylabel('T to the next write')
    fig.suptitle('The two effects no recording reaches, from a T-state model of their code (half periods, log scale)',
                 fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    save(fig, 'effects-code-only.png')


def cmd_pitch(_a):
    names = [n for n in EFFECTS if n != 'timer-click']
    fig, axes = plt.subplots(5, 3, figsize=(10.5, 13.2))
    for ax, n in zip(axes.flat, names):
        d, t0, t1, w, irq = effect_writes(n)
        a = w[0][0]
        xs = [(w[i][0] - a) / CLOCK * 1e3 for i in range(1, len(w))]
        ys = [w[i][0] - w[i - 1][0] for i in range(1, len(w))]
        ax.scatter(xs, ys, s=2, color='#1f77b4')
        ax.set_yscale('log')
        ax.yaxis.set_major_locator(matplotlib.ticker.LogLocator(base=10, subs=(1, 3)))
        ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda v, _: f'{v:g}'))
        ax.yaxis.set_minor_formatter(matplotlib.ticker.NullFormatter())
        lo, hi = min(ys), max(ys)
        if hi < 3 * lo:
            ax.set_ylim(lo / 1.5, hi * 1.5)
        ax.set_title(f'{n} ({len(w)} writes)', loc='left', fontsize=10)
        ax.tick_params(labelsize=9)
        ax.grid(alpha=0.3)
    for ax in axes[:, 0]:
        ax.set_ylabel('T to the next write', fontsize=9.5)
    for ax in axes[-1]:
        ax.set_xlabel('ms from the first write', fontsize=9.5)
    fig.suptitle('The effects as half periods: each dot is the time from one speaker write to the next (log scale); '
                 'low = high pitch', fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.975))
    save(fig, 'effects-pitch.png')


def render(writes, path, pad_ms=30, t_end=None):
    """the speaker bit as audio: each output sample the average level over its interval"""
    if not writes:
        return
    t0 = writes[0][0] - int(pad_ms / 1e3 * CLOCK)
    t1 = (t_end or writes[-1][0]) + int(pad_ms / 1e3 * CLOCK)
    n = int((t1 - t0) / CLOCK * RATE) + 1
    level = np.zeros(n)
    edges = [(t - t0, v >> 4 & 1) for t, v in writes]
    # integrate the square wave per sample
    tpos = np.arange(n + 1) * CLOCK / RATE
    cur, ct = 0, 0.0
    acc = np.zeros(n)
    i = 0
    edges.append((t1 - t0, 0))
    for t, b in edges:
        # level cur from ct to t
        s0, s1 = int(ct * RATE / CLOCK), int(t * RATE / CLOCK)
        if s0 == s1:
            acc[min(s0, n - 1)] += cur * (t - ct)
        else:
            acc[min(s0, n - 1)] += cur * (tpos[s0 + 1] - ct)
            if s1 > s0 + 1:
                acc[s0 + 1:min(s1, n)] += cur * (CLOCK / RATE)
            if s1 < n:
                acc[s1] += cur * (t - tpos[s1])
        cur, ct = b, t
    level = acc / (CLOCK / RATE)
    level = level - level.mean()
    sig = np.clip(level * 0.8, -1, 1)
    out = (sig * 127 + 128).astype(np.uint8)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as wv:
        wv.setnchannels(1)
        wv.setsampwidth(1)
        wv.setframerate(RATE)
        wv.writeframes(out.tobytes())
    print(path, f'{n / RATE:.2f} s')


def cmd_wav(_a):
    for n in EFFECTS:
        d, t0, t1, w, irq = effect_writes(n)
        render(w, os.path.join(AUDIO, f'{n}.wav'))
    w, total = password_model()
    render(w, os.path.join(AUDIO, 'password-accepted.wav'), t_end=total)
    w, total = fizz_model()
    render(w, os.path.join(AUDIO, 'fizz.wav'), t_end=total)
    per = TM.periods()
    for name, (f, a, who) in TM.TUNES.items():
        w, ev, total = TM.play_tune(TM.tune(name), per)
        render(w, os.path.join(AUDIO, f'tune-{f}.wav'), t_end=total)


def cmd_spectro(_a):
    names = ['dig', 'gem', 'fall', 'thud', 'jelly-bean', 'exit-open', 'time-bonus', 'death', 'switch', 'rasp',
             'anti-gravity', 'teleport', 'time-out', 'key-click']
    fig, axes = plt.subplots(len(names) // 2, 2, figsize=(10.5, 1.6 * len(names) // 2 + 1.0))
    for ax, n in zip(axes.flat, names):
        with wave.open(os.path.join(AUDIO, f'{n}.wav')) as wv:
            x = np.frombuffer(wv.readframes(wv.getnframes()), dtype=np.uint8).astype(float) - 128
        nfft = 512 if len(x) > 4000 else 128
        ax.specgram(x, NFFT=nfft, Fs=RATE, noverlap=nfft // 2, cmap='magma', vmin=-40)
        ax.set_ylim(0, 6000)
        ax.set_title(f'{n}.wav, {len(x) / RATE * 1000:.0f} ms', loc='left', fontsize=9.5)
        ax.set_yticks([0, 2000, 4000, 6000])
        ax.set_yticklabels(['0', '2k', '4k', '6k'])
        ax.tick_params(labelsize=9)
    for ax in axes[-1]:
        ax.set_xlabel('seconds')
    fig.suptitle('The effects as spectrograms (Hz against seconds), from the WAVs of their traced speaker writes',
                 fontsize=11.5)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    save(fig, 'spectrograms.png')


def cmd_irq(_a):
    d = load('rzx01-400-700')
    f0, f1 = 400, 700
    taken = {f for f, t, pc in d['irq']}
    tune = [c for c in d['abs_calls'] if c[1] == 'PlayTune'][0][0]
    ends = [c for c in d['abs_calls'] if c[1] == 'PassLoop']
    play0 = ends[0][0] if ends else f1 * FT
    fig, ax = plt.subplots(figsize=(10.5, 2.9))
    xs = list(range(f0, f1))
    ax.scatter([f for f in xs if f in taken], [1] * sum(1 for f in xs if f in taken), marker='|', s=200, color='#2ca02c',
               label='interrupt taken')
    ax.scatter([f for f in xs if f not in taken], [0] * sum(1 for f in xs if f not in taken), marker='|', s=200,
               color='#d62728', label='interrupt lost (INT came while DI)')
    ax.axvspan(tune / FT, play0 / FT, color='#1f77b4', alpha=0.12, label='PlayTune: CaveTune1')
    ax.set_yticks([0, 1])
    ax.set_yticklabels(['lost', 'taken'])
    ax.set_ylim(-0.6, 1.6)
    ax.set_xlim(f0, f1)
    ax.set_xlabel('frame of rzx-earth01 (the frame in which the interrupt fell; trace convention)')
    ax.legend(loc='upper right', ncol=3, fontsize=9.5)
    ax.set_title(f'The interrupts of frames {f0}-{f1}: CaveIntro, the cave tune with interrupts off, then the first '
                 f'passes; {len(taken)} taken of {f1 - f0}', loc='left', fontsize=10.5)
    fig.tight_layout()
    save(fig, 'interrupts.png')


def cmd_table(_a):
    print('effect | recording frame | writes | span T | ms | DI span T | INT lost | edges/ms')
    for n in EFFECTS:
        d, t0, t1, w, irq = effect_writes(n)
        if not w:
            print(n, 'no writes')
            continue
        a, b = w[0][0], w[-1][0]
        ints = [(t, v) for t, v in d['ints'] if t0 - 200 <= t <= t1]
        # interrupts that fell in the span: one per frame start inside (a, b)
        frames = range(a // FT + 1, b // FT + 1)
        lost = [f for f in frames if not any(f * FT <= t < f * FT + 4000 for t in d['irqs'])]
        print(f'{n} | {EFFECTS[n][0]} {a // FT}:{a % FT} | {len(w)} | {b - a} | {(b - a) / CLOCK * 1e3:.1f} | '
              f'{len(frames)} frame starts | {len(lost)} lost')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['tunes', 'mix', 'shapes', 'pitch', 'models', 'spectro', 'irq', 'wav', 'table', 'all'])
    a = p.parse_args()
    cmds = {'tunes': cmd_tunes, 'mix': cmd_mix, 'shapes': cmd_shapes, 'wav': cmd_wav, 'spectro': cmd_spectro,
            'irq': cmd_irq, 'table': cmd_table, 'pitch': cmd_pitch, 'models': cmd_models}
    order = ['tunes', 'mix', 'irq', 'shapes', 'pitch', 'models', 'wav', 'spectro']
    for k in (order if a.what == 'all' else [a.what]):
        cmds[k](a)


if __name__ == '__main__':
    main()
