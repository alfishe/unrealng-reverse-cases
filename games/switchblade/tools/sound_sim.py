#!/usr/bin/env python3
"""Switchblade's sound, run in SkoolKit's Z80 simulator from the case's build: the 48K beeper player, the 128K glue
and bank 4's AY player, frame by frame; the tables, the figures and the audio renders of doc 9 (written, never played).

    python3 tools/sound_sim.py tunes                       each tune's length in frames (StartTune to MusicState 0)
    python3 tools/sound_sim.py costs                       T-states of the 128K glue a frame over each tune, and of
                                                           the 48K player a frame over each effect
    python3 tools/sound_sim.py regs --tune N --from F --frames K   the AY registers after frames F.. of tune N
    python3 tools/sound_sim.py effects48                   the 14 beeper effects: frames, level, burst, T a frame
    python3 tools/sound_sim.py effects128                  the 14 AY effects: frames, period, volume
    python3 tools/sound_sim.py pattern --tune N --channel C --frames K   the sequencer's events on one channel
    python3 tools/sound_sim.py check --work W --window F:T-F:T --tune N --start S
                                                           the AY writes of a recording's trace against the model;
                                                           S = the recording frame whose glue call ran StartTune
    python3 tools/sound_sim.py fig-tune OUT.png --tune N [--frames K]   a tune as a piano roll, one panel a channel
    python3 tools/sound_sim.py fig-regs OUT.png --tune N --from F --frames K   registers 0-10 frame by frame
    python3 tools/sound_sim.py fig-instruments OUT.png     the volume of each instrument from the real code
    python3 tools/sound_sim.py fig-effects48 OUT.png       the 14 beeper effects: level and burst a frame
    python3 tools/sound_sim.py fig-effects128 OUT.png      the 14 AY effects: volume and pitch a frame
    python3 tools/sound_sim.py fig-cost OUT.png            the glue's T-states a frame over tune 0
    python3 tools/sound_sim.py wavs DIR                    the 3 tunes and the 28 effects: WAV up to 1 s, else MP3

The 128K: build/game.bin at $5C00, the glue (build/boot.bin $40A4-$4145, as the bootstrap copies it) at $853F and
build/bank4.bin at $C000 (bank 4, as the glue pages it). Each frame calls AyGlue $853F, as InterruptHandler $8456
does; a tune or an effect is asked for the way the game does it, through TuneRequest $8452 and EffectRequest $8454.
The AY writes go through WriteAyRegister $D3C6: OUT ($FFFD) selects, OUT ($BFFD) writes. The state after a call is
the frame's sound. AY clock 1 773 400 Hz.

The 48K: build/game.bin at $5C00; EffectPlayer $853F called once a frame, its OUT ($FE) writes with their T-states
give the speaker bit (bit 4). The simulator has no contention; on the machine the burst runs inside the interrupt,
after GameTick in play. CPU clock 3 500 000 Hz, 69 888 T a frame. Needs SkoolKit ($SKOOLKIT_VENV), numpy,
matplotlib; lame (or ffmpeg) for the MP3s, VBR quality 4 (`lame -V 4`).
"""
import argparse
import glob
import math
import os
import re
import shutil
import subprocess
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AY_CLOCK = 1773400
CPU48 = 3500000
FRAME48 = 69888
STOP = 0x5BF0
NAMES = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')
LEVELS = (0.0, 0.0137, 0.0205, 0.0291, 0.0423, 0.0618, 0.0847, 0.1369, 0.1691, 0.2647, 0.3527, 0.4499,
          0.5704, 0.6873, 0.8482, 1.0)
TUNE_NAMES = {0: 'the title', 1: 'the in-game music', 2: 'the start jingle'}
EFFECT_NAMES = ['Hiro hurt', 'a hard landing', 'an enemy killed', 'a boss killed', 'Havok killed',
                'a fragment counted', 'a boss shot / a shield struck', 'a footstep', 'a pickup taken',
                'an enemy turns', 'the strike or throw', 'a title piece arrives', 'an enemy hit',
                'a block broken']
LINE = re.compile(r'^\s*\d+\+*\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):')


def labels(name):
    out = {}
    for line in open(os.path.join(ROOT, 'build', name + '.lst'), encoding='latin-1'):
        m = LINE.match(line)
        if m:
            out.setdefault(m.group(2), int(m.group(1), 16))
    return out


G = labels('game')
B = labels('bank4')


def skoolkit():
    venv = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    site = glob.glob(os.path.join(venv, 'lib', 'python3*', 'site-packages'))
    if not site:
        sys.exit(f'no SkoolKit at {venv} ($SKOOLKIT_VENV)')
    sys.path.insert(0, site[0])
    from skoolkit.simulator import Simulator
    from skoolkit import simutils
    return Simulator, simutils


class Ports:
    def __init__(self):
        self.select = 0
        self.ay = []      # (register, value)
        self.fe = []      # (T, value)

    def write_port(self, registers, port, value, *rest):
        if port & 0x8002 == 0x8000:
            if port & 0x4000:
                self.select = value & 15
            else:
                self.ay.append((self.select, value))
        if not port & 1:
            self.fe.append((registers[25], value))


class Machine:
    """kind '128': the game, the glue at $853F and bank 4 at $C000; kind '48': the game alone"""

    def __init__(self, kind):
        Simulator, self.su = skoolkit()
        mem = bytearray(0x10000)
        game = open(os.path.join(ROOT, 'build', 'game.bin'), 'rb').read()
        mem[0x5C00:0x5C00 + len(game)] = game
        if kind == '128':
            boot = open(os.path.join(ROOT, 'build', 'boot.bin'), 'rb').read()
            mem[0x853F:0x853F + 162] = boot[0xA4:0xA4 + 162]
            bank = open(os.path.join(ROOT, 'build', 'bank4.bin'), 'rb').read()
            mem[0xC000:0xC000 + len(bank)] = bank
        mem[STOP] = 0x76
        self.mem = mem
        self.sim = Simulator(mem, {'SP': 0x5BE0})
        self.ports = Ports()
        self.sim.set_tracer(self.ports)

    def call(self, address, a=0):
        su = self.su
        reg = self.sim.registers
        reg[su.A] = a
        reg[su.SP] = 0x5BDE
        self.mem[0x5BDE], self.mem[0x5BDF] = STOP & 255, STOP >> 8
        self.ports.ay, self.ports.fe = [], []
        t0 = reg[su.T]
        self.sim.run(address, STOP)
        return reg[su.T] - t0


class Ay:
    """The 128K sound a frame: regs[f] = the 14 registers after frame f's glue call; costs; writes"""

    def __init__(self, machine=None):
        self.m = machine or Machine('128')
        self.r = [0] * 14
        self.r[7] = 0xFF
        self.regs, self.costs, self.writes, self.chan = [], [], [], []

    def request_tune(self, n):
        self.m.mem[G['TuneRequest']] = n

    def request_effect(self, n):
        self.m.mem[G['EffectRequest']] = n

    def state(self):
        return self.m.mem[B['MusicState']]

    def frame(self):
        t = self.m.call(0x853F)
        for reg, v in self.m.ports.ay:
            if reg < 14:
                self.r[reg] = v
        self.regs.append(tuple(self.r))
        self.costs.append(t)
        self.writes.append(list(self.m.ports.ay))
        a = B['AyChannelA']
        self.chan.append(tuple(self.m.mem[a + 20 * c + 5] for c in range(3)))
        return t

    def run(self, frames):
        for _ in range(frames):
            self.frame()
        return self


def tune_run(n, limit=12000):
    """tune n from the request to the frame MusicState is 0 again (the glue's restart turned off: no loop bit)"""
    ay = Ay()
    ay.m.mem[G['SoundMode']] = 1        # effects: tune 2 is not followed by tune 1
    ay.request_tune(n)
    ay.frame()
    while ay.state() and len(ay.regs) < limit:
        ay.frame()
    return ay


def period(r, ch):
    """the tone period channel ch sounds: R(2ch) and the low 4 bits of R(2ch+1); the AY ignores the rest"""
    return r[2 * ch] | (r[2 * ch + 1] & 15) << 8


def period_note(p):
    if not p:
        return None
    f = AY_CLOCK / (16 * p)
    return 69 + 12 * math.log2(f / 440)


def note_name(m):
    n = int(round(m))
    return '%s%d' % (NAMES[n % 12], n // 12 - 1)


# ---------------------------------------------------------------------------------------------------------------
# the 48K player

EFF = None


def effect48(n, frames=None, limit=600):
    """effect n on the beeper: per frame (level, burst toggles, DJNZ count, T of the call), and the edges [(T, bit)]"""
    m = Machine('48')
    level_op = G['EnvelopeStep'] + 4
    burst_op = G['EffectSound'] + 0x27
    delay_op = G['BeeperBurst'] + 1
    mixer = G['EffectMixer']
    m.mem[G['EffectRequest']] = n
    rows, edges = [], []
    f = 0
    last = 0
    while True:
        t = m.call(0x853F)
        active = m.mem[mixer] != 0x3F
        fe = m.ports.fe
        if fe:
            for tt, v in fe:
                b = (v >> 4) & 1
                if b != last:
                    edges.append((f * FRAME48 + tt - fe[0][0] + 200, b))
                    last = b
        rows.append((m.mem[level_op], (m.mem[burst_op] if fe else 0), m.mem[delay_op], t, len(fe)))
        f += 1
        if frames is not None:
            if f >= frames:
                break
        elif (f > 1 and not active) or f >= limit:
            break
    return rows, edges


# ---------------------------------------------------------------------------------------------------------------
# rendering

def render_ay(regs, rate=44100):
    """frames of 14 registers -> mono float samples; tone squares, the 17-bit noise, fixed volumes"""
    import numpy as np
    per = rate / 50
    total = int(len(regs) * per)
    out = np.zeros(total)
    lfsr = np.zeros(1 << 17, dtype=np.uint8)
    st = 1
    for i in range(len(lfsr)):
        lfsr[i] = st & 1
        st = (st >> 1) | (((st ^ (st >> 3)) & 1) << 16)
    phase = [0.0] * 3
    npos = 0.0
    lv = np.array(LEVELS)
    for f, r in enumerate(regs):
        a, b = int(f * per), int((f + 1) * per)
        n = b - a
        t = np.arange(n)
        ninc = AY_CLOCK / (16 * ((r[6] & 31) or 1)) / rate
        noise = lfsr[((npos + t * ninc).astype(np.int64)) % len(lfsr)]
        npos = (npos + n * ninc) % len(lfsr)
        for ch in range(3):
            p = ((r[2 * ch] | (r[2 * ch + 1] << 8)) & 0xFFF) or 1
            inc = AY_CLOCK / (16 * p) / rate
            ph = phase[ch] + t * inc
            phase[ch] = (phase[ch] + n * inc) % 1.0
            tone = (ph % 1.0) < 0.5 if inc < 0.5 else np.ones(n, dtype=bool)
            ton = not (r[7] >> ch) & 1
            non = not (r[7] >> (ch + 3)) & 1
            gate = (tone | (not ton)) & ((noise == 1) | (not non))
            out[a:b] += gate * lv[r[8 + ch] & 15]
    out -= np.convolve(out, np.ones(2205) / 2205, mode='same')
    return out / 3


def render_edges(edges, clock=CPU48, rate=44100, tail=0.05):
    """[(T, speaker 0/1)] -> mono float samples, each the mean level over its interval"""
    import numpy as np
    if not edges:
        return np.zeros(1)
    ts = np.array([e[0] for e in edges], dtype=np.float64)
    vs = np.array([e[1] for e in edges], dtype=np.float64)
    end = ts[-1] + tail * clock
    seg_t = np.append(ts, end)
    cum = np.concatenate([[0.0], np.cumsum(vs * np.diff(seg_t))])
    n = int((end - ts[0]) / clock * rate)
    st = ts[0] + np.arange(n + 1) * clock / rate
    integ = np.interp(st, seg_t, cum)
    out = np.diff(integ) / (clock / rate)
    out -= np.convolve(out, np.ones(441) / 441, mode='same')
    return out


def write_wav(path, samples, rate=44100):
    import numpy as np
    peak = np.abs(samples).max() or 1
    pcm = (samples / peak * 0.9 * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def to_mp3(wav, mp3):
    if shutil.which('lame'):
        subprocess.run(['lame', '--quiet', '-V', '4', wav, mp3], check=True)
    else:
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', wav, '-q:a', '4', mp3], check=True)
    os.remove(wav)


SHORT_WAV = 1.0     # seconds: a render up to this long stays a WAV, a longer one becomes an MP3 (lame -V 4)


def write_audio(path, samples, rate=44100):
    """path without its extension: NAME.wav when the render is short, else NAME.mp3; the other one is removed"""
    wav, mp3 = path + '.wav', path + '.mp3'
    write_wav(wav, samples, rate)
    if len(samples) / rate > SHORT_WAV:
        to_mp3(wav, mp3)
        return mp3
    if os.path.exists(mp3):
        os.remove(mp3)
    return wav


# ---------------------------------------------------------------------------------------------------------------
# commands

def cmd_tunes(args):
    for n in range(3):
        ay = tune_run(n)
        frames = len(ay.regs)
        print('tune %d (%s): %d frames, %.1f s; StartTune at frame 0, MusicState 0 after frame %d'
              % (n, TUNE_NAMES[n], frames, frames / 50, frames - 1))


def cmd_costs(args):
    for n in range(3):
        ay = tune_run(n)
        c = ay.costs
        print('tune %d: %d frames, glue T min %d mean %.0f max %d (%.1f %% of 69 888 T at the max)'
              % (n, len(c), min(c), sum(c) / len(c), max(c), 100 * max(c) / FRAME48))
    m = Ay()
    c = m.run(50).costs
    print('no tune, no effect: glue T %d' % c[-1])
    allc = []
    for n in range(14):
        rows, _ = effect48(n)
        ts = [r[3] for r in rows]
        allc += ts
        print('48K effect %2d: %3d frames, T a frame min %d mean %.0f max %d' % (n, len(rows), min(ts), sum(ts) / len(ts), max(ts)))
    print('48K all effects: max T %d (%.1f %% of a frame)' % (max(allc), 100 * max(allc) / FRAME48))


def cmd_regs(args):
    ay = tune_run(args.tune)
    f0 = args.__dict__['from']
    print('frame | R0-1 A | R2-3 B | R4-5 C | R6 | R7 | R8 R9 R10 | notes')
    for f in range(f0, min(f0 + args.frames, len(ay.regs))):
        r = ay.regs[f]
        pa, pb, pc = period(r, 0), period(r, 1), period(r, 2)
        names = ' '.join(note_name(period_note(p)) if p else '-' for p in (pa, pb, pc))
        print('%5d | %04X | %04X | %04X | %02X | %02X | %2d %2d %2d | %s | T %d' % (
            f, pa, pb, pc, r[6], r[7], r[8], r[9], r[10], names, ay.costs[f]))


def cmd_effects48(args):
    print('| # | Event | Frames | Peak level | Longest burst (toggles) | DJNZ count | Carrier | T a frame max |')
    print('| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |')
    for n in range(14):
        rows, edges = effect48(n)
        lv = [r[0] for r in rows]
        bursts = [r[1] for r in rows]
        d = rows[1][2] if len(rows) > 1 else rows[0][2]
        hp = 47 + 13 * (d - 1)
        print('| %d | %s | %d%s | %d | %d | %d | %.1f kHz | %d |' % (
            n, EFFECT_NAMES[n], len(rows), '+' if len(rows) >= 600 else '', max(lv), max(bursts), d,
            CPU48 / (2 * hp) / 1000, max(r[3] for r in rows)))
    if args.verbose is not None:
        rows, _ = effect48(args.verbose)
        for i, r in enumerate(rows[:40]):
            print(i, r)


def effect128(n, limit=300):
    """effect n on the AY, from silence (no tune): the registers a frame until channel A is off. Silence $D182 first,
    as the start jingle's StartTune did in the game: StartNote leaves the volume (+$05) alone, so the attack starts
    from the volume the channel had (0 after Silence or a release; the binary's leftover byte otherwise)"""
    ay = Ay()
    ay.m.call(B['Silence'])
    ay.request_effect(n)
    ay.frame()
    ay.frame()
    while (ay.m.mem[B['AyMixer']] & 9) != 9 and len(ay.regs) < limit:
        ay.frame()
    return ay


def cmd_effects128(args):
    print('| # | Event | Frames | Period | Peak volume | Tone / noise |')
    print('| ---: | --- | ---: | --- | ---: | --- |')
    for n in range(14):
        ay = effect128(n)
        per = [period(r, 0) for r in ay.regs]
        vol = [r[8] for r in ay.regs]
        mix = ay.regs[1][7]
        per = per[1:]
        print('| %d | %s | %d%s | `$%04X`-`$%04X` | %d | %s |' % (
            n, EFFECT_NAMES[n], len(ay.regs), '+' if len(ay.regs) >= 300 else '', min(per), max(per), max(vol),
            ('tone' if not mix & 1 else '') + (' noise' if not mix & 8 else '')))


def cmd_pattern(args):
    """the sequencer's view of one channel: each frame a note starts (the AY record's instrument, period, gate)"""
    ay = tune_run(args.tune, limit=args.frames + 1)
    seq = B['SeqChannelA'] + 33 * 'ABC'.index(args.channel)
    print('the regs of channel', args.channel)
    ch = 'ABC'.index(args.channel)
    prev = None
    for f, r in enumerate(ay.regs[:args.frames]):
        p = period(r, ch)
        v = r[8 + ch]
        if (p, v) != prev:
            print(f, '%04X' % p, v, note_name(period_note(p)) if p else '-')
            prev = (p, v)


def load_trace(args):
    sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
    import kitlib
    ns = argparse.Namespace(trace=args.trace, work=args.work, window=args.window, max_cycles=None, unreal=None)
    return kitlib.load_trace(ns)


def cmd_check(args):
    tr = load_trace(args)
    sel = 0
    frames = {}
    for x in tr.instructions:
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0x8002 == 0x8000:
                f, t = tr.cycle_t(x, c)
                if c.address & 0x4000:
                    sel = c.value & 15
                else:
                    frames.setdefault(f, []).append((sel, c.value))
    first, last = min(frames), max(frames)
    ay = Ay()
    ay.request_tune(args.tune)
    ay.run(last - args.start + 2)
    same = diff = 0
    for f in sorted(frames):
        k = f - args.start
        model = ay.writes[k] if 0 <= k < len(ay.writes) else None
        if model == frames[f]:
            same += 1
        else:
            diff += 1
            if diff <= 5:
                print('frame', f, 'model frame', k, '\n trace', frames[f], '\n model', model)
    print('frames with AY writes in the trace: %d (%d-%d); writes equal to the model: %d frames, different: %d'
          % (len(frames), first, last, same, diff))
    print('AY writes in the trace: %d' % sum(len(v) for v in frames.values()))


# ---------------------------------------------------------------------------------------------------------------
# figures

def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'figure.dpi': 100, 'text.parse_math': False})
    return plt


def cmd_fig_tune(args):
    import numpy as np
    plt = plt_setup()
    ay = tune_run(args.tune)
    regs = ay.regs[:args.frames] if args.frames else ay.regs
    n = len(regs)
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 8.4), sharex=True, layout='constrained')
    colours = ('tab:blue', 'tab:orange', 'tab:green')
    for ch, ax in enumerate(axes):
        xs, ys, vs = [], [], []
        nx, ny = [], []
        for f, r in enumerate(regs):
            p = period(r, ch)
            v = r[8 + ch]
            on = not (r[7] >> ch) & 1
            if v and on and p:
                xs.append(f / 50)
                ys.append(period_note(p))
                vs.append(v)
            if v and not (r[7] >> (ch + 3)) & 1:
                nx.append(f / 50)
                ny.append(v)
        ax.scatter(xs, ys, c=vs, cmap='viridis', vmin=0, vmax=15, s=2, marker='s', linewidths=0)
        if nx:
            ax2 = ax.twinx()
            ax2.vlines(nx, 0, 1, color='tab:red', lw=0.6, alpha=0.6)
            ax2.set_ylim(0, 8)
            ax2.set_yticks([])
        lo, hi = (min(ys), max(ys)) if ys else (40, 80)
        step = 12 if hi - lo > 18 else 2
        ticks = [m for m in range(int(lo) - 1, int(hi) + 2) if m % step == 0]
        ax.set_yticks(ticks)
        ax.set_yticklabels([note_name(m) for m in ticks])
        ax.set_ylim(lo - 2, hi + 2)
        ax.grid(axis='y', lw=0.4, alpha=0.5)
        ax.set_ylabel('channel %s%s' % ('ABC'[ch], '\n(period x 2)' if ch == 0 else ''))
    axes[-1].set_xlabel('seconds from StartTune (50 frames a second); red ticks under a channel: its noise on (the drum)')
    sm = plt.cm.ScalarMappable(cmap='viridis', norm=plt.Normalize(0, 15))
    cb = fig.colorbar(sm, ax=axes, shrink=0.6, pad=0.01)
    cb.set_label('volume (register 8-10)')
    fig.suptitle('Tune %d, %s: the note each channel sounds, frame by frame, from the player run in the simulator\n'
                 '%d frames (%.1f s); the pitch is the AY register period as a note (A4 = 440 Hz)'
                 % (args.tune, TUNE_NAMES[args.tune], n, n / 50), fontsize=12)
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_regs(args):
    plt = plt_setup()
    ay = tune_run(args.tune)
    f0 = args.__dict__['from']
    regs = ay.regs[f0:f0 + args.frames]
    xs = list(range(f0, f0 + len(regs)))
    fig, axes = plt.subplots(4, 1, figsize=(10.5, 8.6), sharex=True,
                             gridspec_kw={'height_ratios': [2, 1.2, 0.9, 0.9]})
    colours = ('tab:blue', 'tab:orange', 'tab:green')
    ax = axes[0]
    for ch in range(3):
        ax.step(xs, [period(r, ch) for r in regs], where='post', color=colours[ch],
                label='R%d-%d tone %s' % (2 * ch, 2 * ch + 1, 'ABC'[ch]))
    ax.set_yscale('log')
    import matplotlib.ticker as mt
    ax.yaxis.set_major_formatter(mt.ScalarFormatter())
    ax.yaxis.set_minor_formatter(mt.NullFormatter())
    ax.set_yticks([50, 100, 200, 500, 1000, 2000])
    ax.set_ylabel('tone period\n(12 bits)')
    ax.legend(fontsize=10, ncol=3, loc='upper right')
    ax = axes[1]
    for ch in range(3):
        ax.step(xs, [r[8 + ch] for r in regs], where='post', color=colours[ch], label='R%d volume %s' % (8 + ch, 'ABC'[ch]))
    ax.set_ylabel('volume')
    ax.set_ylim(-0.5, 15.5)
    ax.legend(fontsize=10, ncol=3, loc='upper right')
    ax = axes[2]
    for b in range(6):
        ax.step(xs, [((r[7] >> b) & 1) * 0.8 + b for r in regs], where='post', color=colours[b % 3])
    ax.set_yticks([0.4 + b for b in range(6)])
    ax.set_yticklabels(['tone A', 'tone B', 'tone C', 'noise A', 'noise B', 'noise C'], fontsize=10)
    ax.set_ylabel('R7 bits\n(1 = off)')
    ax = axes[3]
    ax.step(xs, [r[6] & 31 for r in regs], where='post', color='tab:red')
    ax.set_ylabel('R6 noise\n(5 bits)')
    ax.set_xlabel('frame of tune %d (StartTune = frame 0); one value a frame, as WriteAyRegister leaves it' % args.tune)
    fig.suptitle('The registers AyUpdate writes, tune %d (%s), frames %d-%d, from the simulator'
                 % (args.tune, TUNE_NAMES[args.tune], f0, f0 + len(regs) - 1), fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_instruments(args):
    """each instrument started on channel B with a gate of G frames, its volume a frame from the real code"""
    plt = plt_setup()
    m = Machine('128')
    ins = B['Instruments']
    fig, axes = plt.subplots(2, 7, figsize=(10.5, 4.8), sharey=True)
    gate = 20
    for n in range(14):
        ay = Ay(Machine('128'))
        mm = ay.m
        mm.call(B['Silence'])           # the volumes 0, as after StartTune: StartNote keeps the old volume
        # StartNote with IX = AyChannelB, IY = the instrument, HL = a period, C = the gate; then frames of the glue
        su = mm.su
        reg = mm.sim.registers
        reg[su.IXh], reg[su.IXl] = B['AyChannelB'] >> 8, B['AyChannelB'] & 255
        reg[su.IYh], reg[su.IYl] = (ins + 10 * n) >> 8, (ins + 10 * n) & 255
        reg[su.H], reg[su.L] = 0x01, 0x00
        reg[su.C] = gate
        mm.mem[B['DrumPending']] = 0
        mm.call(B['StartNote'])
        mm.mem[B['MusicState']] = 0     # the glue runs PlayFrame for the envelopes only
        vols = []
        for f in range(80):
            ay.frame()
            vols.append(ay.chan[-1][1] // 8)
        ax = axes[n // 7][n % 7]
        ax.step(range(len(vols)), vols, where='post', color='tab:orange')
        ax.axvline(gate, color='tab:red', lw=0.8, ls='--')
        flags = mm.mem[ins + 10 * n + 9]
        ax.set_title('ins %d %s' % (n, {1: 'tone', 2: 'noise', 3: 'tone+noise'}.get(flags & 3, '?')), fontsize=10)
        ax.set_ylim(-0.5, 16)
        ax.tick_params(labelsize=10)
    fig.suptitle('The 14 instruments: the volume register a frame (volume / 8), each started with a gate of %d frames '
                 '(red dashes),\nby StartNote and UpdateChannel run in the simulator' % gate, fontsize=11)
    fig.supxlabel('frames from the note', fontsize=10)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_effects48(args):
    plt = plt_setup()
    fig, axes = plt.subplots(7, 2, figsize=(10.5, 10.5), sharex=False)
    for n in range(14):
        rows, _ = effect48(n, limit=300)
        ax = axes[n % 7][n // 7]
        lv = [r[0] for r in rows]
        bu = [r[1] for r in rows]
        ax.step(range(len(lv)), lv, where='post', color='tab:blue', label='level (operand $85CA)')
        ax.bar(range(len(bu)), bu, width=1.0, color='tab:orange', alpha=0.5, label='burst: speaker toggles')
        ax.set_xlim(0, max(len(lv), 20))
        ax.set_ylim(0, 130)
        ax.set_title('%d %s: %d%s frames' % (n, EFFECT_NAMES[n], len(rows), '+' if len(rows) >= 300 else ''), fontsize=10)
        ax.tick_params(labelsize=10)
    axes[0][0].legend(fontsize=10, loc='upper right')
    fig.supxlabel('frames from the request (one burst a frame)', fontsize=10)
    fig.suptitle('The 14 beeper effects of the 48K: the envelope level and the burst a frame, EffectPlayer $853F run '
                 'in the simulator', fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_effects128(args):
    plt = plt_setup()
    fig, axes = plt.subplots(7, 2, figsize=(10.5, 10.5))
    for n in range(14):
        ay = effect128(n, limit=160)
        ax = axes[n % 7][n // 7]
        vol = [r[8] for r in ay.regs]
        per = [period(r, 0) for r in ay.regs]
        ax.step(range(len(vol)), vol, where='post', color='tab:blue')
        ax.set_ylim(-0.5, 16)
        ax2 = ax.twinx()
        ax2.step(range(len(per)), per, where='post', color='tab:orange', lw=0.9)
        ax2.set_yscale('log')
        import matplotlib.ticker as mt
        ax2.yaxis.set_major_formatter(mt.ScalarFormatter())
        ax2.yaxis.set_minor_formatter(mt.NullFormatter())
        ax2.tick_params(labelsize=10)
        mix = ay.regs[1][7]
        kind = ('tone' if not mix & 1 else '') + ('+noise' if not mix & 8 else '')
        ax.set_title('%d %s (%s): %d%s frames' % (n, EFFECT_NAMES[n], kind.strip('+'), len(ay.regs),
                                                   '+' if len(ay.regs) >= 160 else ''), fontsize=10)
        ax.tick_params(labelsize=10)
    fig.supxlabel('frames from the request; blue: volume R8 (left axis); orange: tone period R0-R1 (right axis, log)',
                  fontsize=10)
    fig.suptitle('The 14 AY effects of the 128K on channel A, the glue and PlayEffect run in the simulator', fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_cost(args):
    plt = plt_setup()
    ay = tune_run(0)
    c = ay.costs
    fig, ax = plt.subplots(figsize=(10.5, 4.2))
    ax.plot([f / 50 for f in range(len(c))], c, lw=0.5, color='tab:blue')
    mean = sum(c) / len(c)
    ax.axhline(mean, color='tab:red', lw=1, ls='--', label='mean %.0f T' % mean)
    ax.set_xlabel('seconds of tune 0 (the title)')
    ax.set_ylabel('T-states of AyGlue a frame')
    ax.legend(fontsize=10)
    ax.set_title('The 128K sound a frame: AyGlue, the sequencers and AyUpdate over tune 0 (%d frames); min %d, max %d T '
                 '(%.1f %% of a frame)' % (len(c), min(c), max(c), 100 * max(c) / 70908), fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_wavs(args):
    os.makedirs(args.dir, exist_ok=True)
    for n in range(3):
        ay = tune_run(n)
        if n == 2:
            ay.run(40)       # the release tail
        out = write_audio(os.path.join(args.dir, 'tune-%d' % n), render_ay(ay.regs))
        print('wrote', out, len(ay.regs), 'frames')
    for n in range(14):
        rows, edges = effect48(n, limit=300)
        p = write_audio(os.path.join(args.dir, 'beeper-%02d' % n), render_edges(edges))
        ay = effect128(n, limit=300)
        ay.run(10)
        q = write_audio(os.path.join(args.dir, 'ay-effect-%02d' % n), render_ay(ay.regs))
        print('wrote', p, len(rows), 'frames;', q, len(ay.regs), 'frames')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('tunes')
    sub.add_parser('costs')
    p = sub.add_parser('regs')
    p.add_argument('--tune', type=int, default=0)
    p.add_argument('--from', type=int, default=0)
    p.add_argument('--frames', type=int, default=50)
    p = sub.add_parser('effects48')
    p.add_argument('--verbose', type=int)
    sub.add_parser('effects128')
    p = sub.add_parser('pattern')
    p.add_argument('--tune', type=int, default=2)
    p.add_argument('--channel', default='A')
    p.add_argument('--frames', type=int, default=120)
    p = sub.add_parser('check')
    p.add_argument('--trace')
    p.add_argument('--work')
    p.add_argument('--window')
    p.add_argument('--tune', type=lambda s: int(s, 0), default=0x80)
    p.add_argument('--start', type=int, required=True)
    p = sub.add_parser('fig-tune')
    p.add_argument('out')
    p.add_argument('--tune', type=int, default=0)
    p.add_argument('--frames', type=int)
    p = sub.add_parser('fig-regs')
    p.add_argument('out')
    p.add_argument('--tune', type=int, default=0)
    p.add_argument('--from', type=int, default=0)
    p.add_argument('--frames', type=int, default=200)
    for name in ('fig-instruments', 'fig-effects48', 'fig-effects128', 'fig-cost'):
        p = sub.add_parser(name)
        p.add_argument('out')
    p = sub.add_parser('wavs')
    p.add_argument('dir')
    args = ap.parse_args()
    globals()['cmd_' + args.cmd.replace('-', '_')](args)


if __name__ == '__main__':
    main()
