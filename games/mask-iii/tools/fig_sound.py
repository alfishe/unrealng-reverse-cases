#!/usr/bin/env python3
"""MASK III's sound for doc 9: the AY player (RAM 4) and the beeper path run in SkoolKit's Z80 simulator from the
case's build, frame by frame as the interrupt runs them, then rendered to audio and charts (written, never played).

    python3 tools/fig_sound.py tunes OUTDIR                  the three tunes: OUTDIR/tune-N.mp3 (lame -V 4), and
                                                             DATA/tune-N.json (the AY registers a frame)
    python3 tools/fig_sound.py effects OUTDIR                each of the 18 effects on the AY (fx-NN-ay.wav) and on the
                                                             beeper (fx-NN-beeper.wav), and DATA/effects.json
  DATA is work/docs/mxC/sound (--data DIR); the fig- commands read it.
    python3 tools/fig_sound.py fig-tunes OUT.png             the tunes as a chart: each channel's note and volume
    python3 tools/fig_sound.py fig-effects OUT.png           the effects: AY volume and period, beeper bursts
    python3 tools/fig_sound.py fig-beeper OUT.png            one beeper frame of effect 9 (Matt materialises) against T-states
    python3 tools/fig_sound.py fig-cost OUT.png              the T-states a frame: MusicPlay, BeeperTick
    python3 tools/fig_sound.py chanc                         the channel C bug: the frames whose AY registers, and whose
                                                             audible part, change when StopEffects is fixed
    python3 tools/fig_sound.py fig-records OUT.png           the effect records and instruments as a data sheet

The memory is flat: build/game.bin at $6000, build/music.bin (RAM 4) at $C000 over it, as the interrupt sees it with
RAM 4 paged. Each frame does what Interrupt $9226 does on a 128K: a waiting tune (MusicStart, A = tune - 1),
StopEffects $946F, StartEffects $9421, MusicPlay $C003; in the menu (tune 1) a tune that ended starts again. On a 48K
(MachineFlag $FFFE non-zero) the frame is StopBeeper $949F and BeeperTick $94C8. The players touch no ROM and no
other port, so the simulator's T-states are the real ones (no contention: the code and the data are above $8000).
AY clock 1 773 400 Hz, 70 908 T a 128K frame; 69 888 T a 48K frame at 3 500 000 Hz.
"""
import json
import os
import subprocess
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import z80sim  # noqa: E402

z80sim.need_skoolkit()
from skoolkit.simulator import Simulator  # noqa: E402
from skoolkit import simutils as su  # noqa: E402

AY_CLOCK = 1773400
CPU128, FRAME128 = 3546900, 70908
CPU48, FRAME48 = 3500000, 69888
RATE = 44100
LEVELS = (0.0, 0.0137, 0.0205, 0.0291, 0.0423, 0.0618, 0.0847, 0.1369, 0.1691, 0.2647, 0.3527, 0.4499,
          0.5704, 0.6873, 0.8482, 1.0)
SENTINEL = 0x0000
MUSIC_START, MUSIC_PLAY, MUSIC_TUNE, MUSIC_STOP = 0xC000, 0xC003, 0xC006, 0xC00A
STOP_EFFECTS, START_EFFECTS, PLAY_EFFECT = 0x946F, 0x9421, 0x93DC
STOP_BEEPER, BEEPER_TICK = 0x949F, 0x94C8
EFFECT_TABLE, CHAN_C = 0x92E0, 0xC358
MACHINE_FLAG = 0xFFFE
TUNE_NAMES = {1: 'the menu', 2: 'game over', 3: 'the game start'}
EFFECT_NAMES = {
    0: 'JACKRABBIT shot', 1: 'LIFTER shot', 2: 'BLASTER shot', 3: 'BACKLASH shot', 4: 'LAVA SHOT shot',
    5: 'STREAMER shot', 6: 'wave flyer swoop', 7: 'PENETRATOR on', 8: 'death', 9: 'materialise / door warp',
    10: 'kind 16 enters (never)', 11: 'explosion 1', 12: 'explosion 2', 13: 'explosion 3', 14: 'explosion 4',
    15: 'chaser on screen', 16: 'wall death 1 (never)', 17: 'wall death 2 (never)'}


class Ports:
    def __init__(self):
        self.reg = 0
        self.regs = [0] * 16
        self.writes = []
        self.beeper = []          # (T, speaker bit)

    def write_port(self, registers, port, value, *a):
        if port & 0xC002 == 0xC000:
            self.reg = value & 15
        elif port & 0xC002 == 0x8000:
            self.regs[self.reg] = value
            self.writes.append((self.reg, value))
        elif port & 1 == 0:
            self.beeper.append((registers[su.T], (value >> 4) & 1))

    def read_port(self, registers, port):
        return 0xFF


class Machine:
    def __init__(self, model='128K'):
        mem = [0] * 0x10000
        game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
        mem[0x6000:0x6000 + len(game)] = game
        if model == '128K':
            music = open(os.path.join(CASE, 'build', 'music.bin'), 'rb').read()
            mem[0xC000:0xC000 + len(music)] = music
        mem[SENTINEL] = 0x76
        mem[MACHINE_FLAG] = 0 if model == '128K' else 1
        self.ports = Ports()
        self.sim = Simulator(mem, {'SP': 0xFFF0}, config={'fast_ldir': False, 'fast_djnz': False})
        self.sim.set_tracer(self.ports)
        self.mem = self.sim.memory

    def call(self, addr, a=None, limit=3_000_000):
        r = self.sim.registers
        if a is not None:
            r[su.A] = a
        sp = r[su.SP] - 2
        self.mem[sp], self.mem[sp + 1] = SENTINEL & 255, SENTINEL >> 8
        r[su.SP] = sp
        r[su.PC] = addr
        t0 = r[su.T]
        ops, mem = self.sim.opcodes, self.mem
        while r[su.PC] != SENTINEL:
            ops[mem[r[su.PC]]]()
            if r[su.T] - t0 > limit:
                raise SystemExit(f'call {addr:04X} did not return')
        return r[su.T] - t0

    def t(self):
        return self.sim.registers[su.T]


def frame128(m, tune_request=0, loop_tune=False, fix_c=False):
    """one 128K interrupt's sound part; returns the T-states of MusicPlay and the AY registers after it"""
    m.ports.writes = []
    if tune_request:
        m.call(MUSIC_START, tune_request - 1)
    if fix_c:                                  # StopEffects as meant: channel C's hold left alone
        saved = m.mem[CHAN_C + 6]
        m.call(STOP_EFFECTS)
        m.mem[CHAN_C + 6] = saved
    else:
        m.call(STOP_EFFECTS)
    m.call(START_EFFECTS)
    t = m.call(MUSIC_PLAY)
    if loop_tune and m.mem[MUSIC_TUNE] != 0xFF:
        m.call(MUSIC_START, 0)
    m.restart = any(r == 13 for r, v in m.ports.writes)
    return t, list(m.ports.regs[:14])


def run_tune(tune, frames, fix_c=False):
    m = Machine('128K')
    m.call(MUSIC_STOP)
    out, ended = [], None
    for f in range(frames):
        t, regs = frame128(m, tune if f == 0 else 0, fix_c=fix_c)
        out.append({'t': t, 'r': regs, 'tune': m.mem[MUSIC_TUNE], 'e': m.restart})
        if f > 0 and m.mem[MUSIC_TUNE] != 0xFF and ended is None:
            ended = f
            if tune != 1:
                break
    return out, ended


def tune_length(tune):
    """frames until every channel's order list ends (MusicTune leaves $FF)"""
    return run_tune(tune, 20000)[1]


# ---- the AY renderer -------------------------------------------------------------------------------------------

def env_levels(shape, steps):
    """the AY envelope's 16-level value for step indexes (0, 1, ...) of a shape (R13)"""
    import numpy as np
    s = np.asarray(steps)
    cont, att, alt, hold = (shape >> 3) & 1, (shape >> 2) & 1, (shape >> 1) & 1, shape & 1
    cyc, pos = s // 16, s % 16
    up = np.where(att == 1, pos, 15 - pos)
    if not cont:
        return np.where(cyc == 0, up, 0)
    if hold:
        last = (15 if att else 0) ^ (15 if alt else 0)
        return np.where(cyc == 0, up, last)
    if alt:
        return np.where(cyc % 2 == 0, up, 15 - up)
    return up


LFSR_SEQ = None


def lfsr_sequence():
    """the AY noise generator's 17-bit LFSR output over its whole period"""
    import numpy as np
    global LFSR_SEQ
    if LFSR_SEQ is None:
        out, lfsr = bytearray(131071), 1
        for k in range(131071):
            fb = (lfsr ^ (lfsr >> 3)) & 1
            lfsr = (lfsr >> 1) | (fb << 16)
            out[k] = lfsr & 1
        LFSR_SEQ = np.frombuffer(bytes(out), dtype=np.uint8).astype(bool)
    return LFSR_SEQ


def render_ay(frames, restarts=None, frame_t=FRAME128, cpu=CPU128):
    """the AY registers a frame (lists of 14) as 16-bit mono samples at RATE; RESTARTS[i] true when R13 was written
    in frame i (the envelope starts again)"""
    import numpy as np
    seq = lfsr_sequence()
    levels = np.asarray(LEVELS)
    out = []
    phase = [0.0, 0.0, 0.0]
    noise_pos = 0.0
    env_pos = 0.0
    dur = frame_t / cpu
    n_total = 0
    for i, regs in enumerate(frames):
        n = int(round((i + 1) * dur * RATE)) - n_total
        n_total += n
        t = np.arange(n) / RATE
        mix = regs[7]
        noise_rate = AY_CLOCK / (16.0 * max(regs[6] & 31, 1))
        noise = seq[((noise_pos + t * noise_rate).astype(np.int64)) % len(seq)]
        noise_pos += n / RATE * noise_rate
        if restarts and restarts[i]:
            env_pos = 0.0
        env_rate = AY_CLOCK / (16.0 * max(regs[11] | (regs[12] << 8), 1))
        env = env_levels(regs[13] & 15, (env_pos + t * env_rate).astype(np.int64))
        env_pos += n / RATE * env_rate
        total = np.zeros(n)
        for ch in range(3):
            per = max(regs[2 * ch] | ((regs[2 * ch + 1] & 15) << 8), 1)
            f = AY_CLOCK / (16.0 * per)
            ph = phase[ch] + t * f
            phase[ch] = (phase[ch] + n / RATE * f) % 1.0
            tone = (ph % 1.0) < 0.5 if f < RATE / 2 else np.ones(n, bool)
            tone_on = not (mix >> ch) & 1
            noise_on = not (mix >> (ch + 3)) & 1
            gate = np.ones(n, bool)
            if tone_on:
                gate &= tone
            if noise_on:
                gate &= noise
            vol = regs[8 + ch]
            amp = levels[env] if vol & 16 else LEVELS[vol & 15]
            total += gate * amp
        out.append(total / 3.0)
    s = np.concatenate(out) if out else np.zeros(0)
    s = s - s.mean() if len(s) else s
    return (np.clip(s * 1.6, -1, 1) * 32000).astype(np.int16)


def write_wav(path, samples):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(samples.tobytes())


def write_mp3(wav, mp3):
    subprocess.run(['lame', '--quiet', '-V', '4', wav, mp3], check=True)


# ---- effects ---------------------------------------------------------------------------------------------------

def effect_record(m, n):
    a = EFFECT_TABLE + 14 * n
    return m.mem[a:a + 14]


def run_effect_ay(n, max_frames=400, fix_c=False):
    m = Machine('128K')
    m.call(MUSIC_STOP)
    m.call(PLAY_EFFECT, n)
    frames = []
    for f in range(max_frames):
        t, regs = frame128(m, fix_c=fix_c)
        frames.append({'t': t, 'r': regs, 'e': m.restart})
        if f > 2 and (m.mem[0xC333] & 0x3F) == 0x3F:
            break
    return frames


def run_effect_beeper(n, max_frames=400):
    """the 48K path: PlayEffect (BeeperStart), then StopBeeper and BeeperTick each interrupt"""
    m = Machine('48K')
    m.call(PLAY_EFFECT, n)
    frames, bursts = [], []
    for f in range(max_frames):
        m.ports.beeper = []
        t0 = m.t()
        m.call(STOP_BEEPER)
        t = m.call(BEEPER_TICK)
        frames.append({'t': t, 'outs': [(tt - t0, b) for tt, b in m.ports.beeper]})
        if m.mem[0x94AB] == 0:
            break
    return frames


def render_beeper(frames, offset=400):
    """the speaker bit over each 48K frame (the interrupt's work before BeeperTick taken as OFFSET T) at RATE"""
    import numpy as np
    total_t = len(frames) * FRAME48 + FRAME48 // 4
    level = np.zeros(total_t, dtype=np.float32)
    for i, fr in enumerate(frames):
        base = i * FRAME48 + offset
        state, last = 0, base
        for tt, b in fr['outs']:
            pos = base + tt
            level[last:pos] = state
            state, last = b, pos
        level[last:base + FRAME48] = state
    step = CPU48 / RATE
    n = int(total_t / step)
    idx = (np.arange(n + 1) * step).astype(int)
    c = np.concatenate([[0], np.cumsum(level)])
    s = (c[idx[1:]] - c[idx[:-1]]) / np.diff(idx)
    s = s - 0.5 * (s.max() > 0)
    return (s * 0.6 * 32000).astype(np.int16)


DATA = os.path.join(CASE, 'work', 'docs', 'mxC', 'sound')


def cmd_tunes(outdir, frames):
    os.makedirs(outdir, exist_ok=True)
    os.makedirs(DATA, exist_ok=True)
    summary = {}
    for tune in (1, 2, 3):
        length = tune_length(tune)
        n = length
        data, _ = run_tune(tune, n + 25)
        regs = [d['r'] for d in data]
        wav = os.path.join(outdir, f'tune-{tune}.wav')
        write_wav(wav, render_ay(regs, [d['e'] for d in data]))
        write_mp3(wav, os.path.join(outdir, f'tune-{tune}.mp3'))
        os.remove(wav)
        ts = [d['t'] for d in data]
        summary[tune] = {'frames': length, 'seconds': round(length * FRAME128 / CPU128, 2),
                         't_min': min(ts), 't_median': sorted(ts)[len(ts) // 2], 't_max': max(ts)}
        json.dump({'tune': tune, 'frames': data}, open(os.path.join(DATA, f'tune-{tune}.json'), 'w'))
        print(tune, summary[tune])
    json.dump(summary, open(os.path.join(DATA, 'tunes-summary.json'), 'w'), indent=1)


def cmd_effects(outdir):
    os.makedirs(outdir, exist_ok=True)
    os.makedirs(DATA, exist_ok=True)
    out = {}
    for n in range(18):
        ay = run_effect_ay(n)
        ay_fixed = run_effect_ay(n, fix_c=True)
        bp = run_effect_beeper(n)
        write_wav(os.path.join(outdir, f'fx-{n:02d}-ay.wav'), render_ay([f['r'] for f in ay], [f['e'] for f in ay]))
        write_wav(os.path.join(outdir, f'fx-{n:02d}-beeper.wav'), render_beeper(bp))
        m = Machine('128K')
        rec = effect_record(m, n)
        out[n] = {'record': ' '.join('%02X' % b for b in rec), 'name': EFFECT_NAMES[n],
                  'ay_frames': len(ay), 'ay_frames_meant': len(ay_fixed),
                  'ay_t_max': max(f['t'] for f in ay), 'beeper_frames': len(bp),
                  'beeper_t_max': max(f['t'] for f in bp), 'beeper_t_median': sorted(f['t'] for f in bp)[len(bp) // 2],
                  'ay': [f['r'] for f in ay], 'ay_meant': [f['r'] for f in ay_fixed],
                  'beeper_t': [f['t'] for f in bp], 'beeper_outs': [len(f['outs']) for f in bp]}
        print(n, EFFECT_NAMES[n], 'AY', len(ay), '(meant', len(ay_fixed), ') beeper', len(bp), 'T max', out[n]['beeper_t_max'])
    json.dump(out, open(os.path.join(DATA, 'effects.json'), 'w'))


# ---- figures ---------------------------------------------------------------------------------------------------

def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'axes.labelsize': 11, 'legend.fontsize': 10,
                         'xtick.labelsize': 10, 'ytick.labelsize': 10})
    return plt


NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def period_to_midi(p):
    import math
    if p <= 0:
        return None
    f = AY_CLOCK / (16.0 * p)
    return 69 + 12 * math.log2(f / 440.0)


def cmd_fig_tunes(out):
    plt = plt_setup()
    import numpy as np
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 11), dpi=100)
    colours = ['#d62728', '#1f77b4', '#2ca02c']
    for ax, tune in zip(axes, (1, 2, 3)):
        data = json.load(open(os.path.join(DATA, f'tune-{tune}.json')))['frames']
        summary = json.load(open(os.path.join(DATA, 'tunes-summary.json')))[str(tune)]
        n = summary['frames'] if tune != 1 else min(len(data), summary['frames'])
        x = np.arange(n) / 50.0
        for ch in range(3):
            per = np.array([d['r'][2 * ch] | ((d['r'][2 * ch + 1] & 15) << 8) for d in data[:n]])
            vol = np.array([d['r'][8 + ch] & 15 for d in data[:n]])
            midi = np.array([period_to_midi(p) if p else np.nan for p in per])
            midi[vol == 0] = np.nan
            ax.scatter(x, midi, s=1.5 + vol * 0.6, c=colours[ch], label=f'channel {"ABC"[ch]}', alpha=0.8,
                       linewidths=0)
        ticks = list(range(36, 109, 12))
        ax.set_yticks(ticks)
        ax.set_yticklabels([f'C{t // 12 - 1}' for t in ticks])
        ax.set_ylim(30, 112)
        ax.set_xlim(0, n / 50.0)
        ax.grid(alpha=0.3)
        ax.set_ylabel('note (pitch)')
        ax.set_title(f'Tune {tune}, {TUNE_NAMES[tune]}: {summary["frames"]} frames ({summary["seconds"]} s), '
                     f'MusicPlay {summary["t_min"]}-{summary["t_max"]} T a frame')
        ax.legend(loc='upper right', markerscale=4)
    axes[-1].set_xlabel('seconds from MusicStart (50 frames a second)')
    fig.suptitle('The three AY tunes as the interrupt plays them: each channel\'s note a frame, the dot size its '
                 'volume', fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    fig.savefig(out)
    print(out)


def cmd_fig_effects(out):
    plt = plt_setup()
    import numpy as np
    eff = json.load(open(os.path.join(DATA, 'effects.json')))
    fig, axes = plt.subplots(6, 3, figsize=(10.5, 14), dpi=100, sharex=False)
    for n in range(18):
        ax = axes[n // 3][n % 3]
        e = eff[str(n)]
        rec = [int(b, 16) for b in e['record'].split()]
        ch = {1: 0, 2: 1}.get(rec[10], 2)
        ay = e['ay']
        vol = [r[8 + ch] & 15 if not r[8 + ch] & 16 else 15 for r in ay]
        per = [r[2 * ch] | ((r[2 * ch + 1] & 15) << 8) for r in ay]
        x = np.arange(len(ay))
        ax.step(x, vol, where='post', color='#d62728', label='volume')
        ax.set_ylim(-0.5, 16)
        ax2 = ax.twinx()
        ax2.plot(x, per, color='#1f77b4', lw=1, label='period')
        ax2.tick_params(labelsize=10)
        ax.set_title(f'{n}: {e["name"]}\nchannel {"ABC"[ch]}, {len(ay)} frames AY, {e["beeper_frames"]} beeper',
                     fontsize=10)
        ax.tick_params(labelsize=10)
        if rec[9] & 4:
            ax.text(0.98, 0.9, 'R13 envelope', transform=ax.transAxes, ha="right", fontsize=10)
    fig.suptitle('The 18 effects on the AY: volume (red, left axis 0-15) and tone period (blue, right axis) a frame, '
                 'from StartEffects to silence', fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.975))
    fig.savefig(out)
    print(out)


def cmd_fig_beeper(out):
    plt = plt_setup()
    import numpy as np
    frames = run_effect_beeper(9, 400)
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 6.5), dpi=100)
    fr = frames[0]['outs']
    xs, ys, state, last = [], [], 0, 0
    for tt, b in fr:
        xs += [last, tt]
        ys += [state, state]
        state, last = b, tt
    xs += [last, last + 200]
    ys += [state, state]
    axes[0].plot(xs, ys, color='#333', lw=1.2)
    axes[0].set_ylim(-0.3, 1.3)
    axes[0].set_yticks([0, 1])
    axes[0].set_yticklabels(['0', '1 (bit 4)'])
    axes[0].set_xlabel('T-states from BeeperTick\'s first instruction')
    hi = [fr[i + 1][0] - fr[i][0] for i in range(0, len(fr) - 1, 2)]
    lo = [fr[i + 1][0] - fr[i][0] for i in range(1, len(fr) - 1, 2)]
    axes[0].set_title(f'Effect 9 (Matt materialises), first frame: {len(fr) // 2} pulses, high {hi[0]} T, low {lo[0] if lo else 0} '
                      f'T: the low half never waits')
    t = [f['t'] for f in frames]
    axes[1].bar(np.arange(len(t)), t, color='#9467bd', width=1.0)
    axes[1].axhline(FRAME48, color='#d62728', lw=1)
    axes[1].text(len(t) * 0.99, FRAME48 * 0.95, 'one 48K frame, 69 888 T', ha='right', va='top', color='#d62728')
    axes[1].set_ylabel('T-states')
    axes[1].set_xlabel('frame of the effect')
    axes[1].set_title(f'BeeperTick\'s T-states a frame over the whole effect ({len(t)} frames, at most {max(t)} T)')
    fig.tight_layout()
    fig.savefig(out)
    print(out)


def cmd_fig_cost(out):
    plt = plt_setup()
    import numpy as np
    eff = json.load(open(os.path.join(DATA, 'effects.json')))
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.8), dpi=100)
    names, ay_t, bp_t = [], [], []
    for n in range(18):
        e = eff[str(n)]
        names.append(str(n))
        ay_t.append(e['ay_t_max'])
        bp_t.append(e['beeper_t_max'])
    x = np.arange(18)
    axes[0].bar(x - 0.2, ay_t, 0.4, label='128K: MusicPlay (AY)', color='#1f77b4')
    axes[0].bar(x + 0.2, bp_t, 0.4, label='48K: BeeperTick', color='#9467bd')
    axes[0].set_xticks(x)
    axes[0].set_xticklabels(names)
    axes[0].set_xlabel('effect')
    axes[0].set_ylabel('T-states in the worst frame')
    axes[0].legend()
    axes[0].set_title('An effect\'s worst frame')
    for tune, col in ((1, '#d62728'), (2, '#2ca02c'), (3, '#ff7f0e')):
        d = json.load(open(os.path.join(DATA, f'tune-{tune}.json')))['frames']
        axes[1].plot([f['t'] for f in d][:600], lw=0.8, color=col, label=f'tune {tune}')
    axes[1].set_xlabel('frame')
    axes[1].set_ylabel('MusicPlay T-states')
    axes[1].set_title('MusicPlay a frame, the tunes (first 600 frames)')
    axes[1].legend()
    fig.suptitle('The cost of sound in the interrupt: the beeper takes up to 10 845 T (15 % of a frame), the '
                 'AY player 2 000-7 400 T', fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    fig.savefig(out)
    print(out)


def audible(regs):
    """what reaches the ear: per channel (volume, tone period and mixer bits when the volume is not 0), the noise"""
    out = []
    for ch in range(3):
        v = regs[8 + ch]
        if v & 31:
            out.append((v, regs[2 * ch] | (regs[2 * ch + 1] << 8), (regs[7] >> ch) & 9, regs[6]))
        else:
            out.append(0)
    return out


def cmd_chanc():
    """the channel C bug measured: frames whose AY registers, and whose audible part, differ with StopEffects fixed"""
    for tune in (1, 2, 3):
        n = tune_length(tune) + 30
        a, _ = run_tune(tune, n)
        b, _ = run_tune(tune, n, fix_c=True)
        regs = sum(1 for x, y in zip(a, b) if x['r'] != y['r'])
        aud = sum(1 for x, y in zip(a, b) if audible(x['r']) != audible(y['r']))
        print(f'tune {tune}: {n} frames, registers differ in {regs}, the audible part in {aud}')
    for e in range(18):
        a = run_effect_ay(e)
        b = run_effect_ay(e, fix_c=True)
        aud = sum(1 for x, y in zip(a, b) if audible(x['r']) != audible(y['r'])) + abs(len(a) - len(b))
        if aud:
            print(f'effect {e}: the audible part differs in {aud} frames')
    print('effects: done')


def cmd_fig_records(out):
    plt = plt_setup()
    m = Machine('128K')
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 9.5), dpi=100, gridspec_kw={'height_ratios': [18, 8]})
    cols = ['+0\nattack', '+1\ndecay', '+2\nsustain', '+3\nrelease', '+4\npeak', '+5\nsweep\ndelay', '+6\nsweep\nsteps',
            '+7\nsweep\nlo', '+8\nsweep\nhi', '+9\nflags', '+A\nslot', '+B\nlength', '+C\nperiod\nlo', '+D\nperiod\nhi']
    rows = [effect_record(m, n) for n in range(18)]
    for ax, data, labels, ncol, title in (
            (axes[0], rows, [f'{n} {EFFECT_NAMES[n]}' for n in range(18)], 14,
             'EffectTable $92E0: 18 records of 14 bytes (hex)'),
            (axes[1], [m.mem[0xCBA2 + 10 * i:0xCBA2 + 10 * i + 10] for i in range(8)],
             [f'instrument {i} (map value {10 * i})' for i in range(8)], 10,
             'Instruments $CBA2 (RAM 4): 8 records of 10 bytes, the same layout as +0-+9')):
        ax.set_xlim(0, ncol)
        ax.set_ylim(len(data), 0)
        ax.set_xticks([i + 0.5 for i in range(ncol)])
        ax.set_xticklabels(cols[:ncol], fontsize=10)
        ax.xaxis.tick_top()
        ax.set_yticks([i + 0.5 for i in range(len(data))])
        ax.set_yticklabels(labels, fontsize=10)
        for r, rec in enumerate(data):
            for c in range(ncol):
                v = rec[c]
                colour = '#fde0dd' if c < 5 else '#deebf7' if c < 9 else '#e5f5e0' if c == 9 else '#fff7bc'
                ax.add_patch(plt.Rectangle((c, r), 1, 1, facecolor=colour, edgecolor='#999', lw=0.5))
                ax.text(c + 0.5, r + 0.5, '%02X' % v, ha='center', va='center', fontsize=10, family='monospace')
        ax.set_title(title, pad=48 if ax is axes[0] else 40)
        for s in ax.spines.values():
            s.set_visible(False)
    fig.suptitle('The sound records byte by byte: red the volume envelope, blue the pitch sweep, green the flags, '
                 'yellow the effect\'s start', fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    fig.savefig(out)
    print(out)


def main():
    a = sys.argv[1:]
    if not a:
        sys.exit(__doc__)
    c = a[0]
    global DATA
    if '--data' in a:
        DATA = os.path.abspath(a[a.index('--data') + 1])
    if c == 'tunes':
        cmd_tunes(a[1], 0)
    elif c == 'effects':
        cmd_effects(a[1])
    elif c == 'fig-tunes':
        cmd_fig_tunes(a[1])
    elif c == 'fig-effects':
        cmd_fig_effects(a[1])
    elif c == 'fig-beeper':
        cmd_fig_beeper(a[1])
    elif c == 'fig-cost':
        cmd_fig_cost(a[1])
    elif c == 'chanc':
        cmd_chanc()
    elif c == 'fig-records':
        cmd_fig_records(a[1])
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
