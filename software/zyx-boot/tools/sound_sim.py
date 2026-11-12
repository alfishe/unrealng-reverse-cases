#!/usr/bin/env python3
"""ZYX boot's sound, run in SkoolKit's Z80 simulator from the case's build: the ASC Sound Master player frame by
frame, the bell, their WAV renders (written, never played) and the figures of doc 9.

    python3 tools/sound_sim.py loop                       the tune's length: rows, positions, frames to the loop
    python3 tools/sound_sim.py costs                      MusicPlay's T-states a call over one loop: min, mean, max
    python3 tools/sound_sim.py regs --from F --frames N   the 14 registers after frames F.. (a table)
    python3 tools/sound_sim.py pattern N                  pattern N's three streams byte by byte, with the rows
    python3 tools/sound_sim.py check --work W --window F:T-F:T   a recording's AY writes against the model
    python3 tools/sound_sim.py fig-tune OUT.png           the tune as a piano roll, the three channels, one loop
    python3 tools/sound_sim.py fig-regs OUT.png --from F --frames N   the registers WriteAY sends, frame by frame
    python3 tools/sound_sim.py fig-samples OUT.png        the samples and ornaments the tune uses, row by row
    python3 tools/sound_sim.py fig-bell OUT.png           the bell (ExitSound) and SoundOff as the AY makes them
    python3 tools/sound_sim.py wavs DIR                   the tune's first tune loop (WAV 22 kHz and MP3), the bell, the cut

The music: build/music.bin at $C000; MusicInit $C00B once, then MusicPlay $C00E once a frame, as Start and the IM 2
handler do. The AY writes go through WriteAY $C15F: OUT ($FFFD) selects, OUTD to $BEFD writes. The state after a
call is the frame's sound. The AY clock is the Pentagon's, 1 750 000 Hz (the recordings are Pentagon 128K); a 128K
plays the same periods 1.3 % (22 cents) higher.

The bell: the 14 bytes of ExitSound (build/main.bin) written once by PlayBell $6E48; the envelope (shape 1, period
$50C4) decays over 3.0 s. SoundOff $6E41 writes 14 zeros from $7530.

Needs SkoolKit ($SKOOLKIT_VENV), numpy, matplotlib; lame for the MP3.
"""
import argparse
import glob
import math
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = os.path.join(ROOT, '..', '..', 'kit')
AY_CLOCK = 1750000
FRAME_T = 71680
STOP = 0x5B00
# the AY's 16 volume levels (normalised, the measured log curve)
LEVELS = [0.0, 0.0137, 0.0205, 0.0291, 0.0423, 0.0618, 0.0847, 0.1369, 0.1691, 0.2647, 0.3527, 0.4499, 0.5704,
          0.6873, 0.8482, 1.0]
NAMES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
CHANNELS = (0xC0A9, 0xC0C2, 0xC0DB)
AYREGS = 0xC0F4
DELAY_COUNTER = 0xC103
POSITION_OP = 0xC195          # PositionOp+1: the next position
TUNE = 0xC478
GAME_BASE = 0x61A8
EXIT_SOUND = 0x6E64


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
        self.ay = []

    def write_port(self, registers, port, value, *rest):
        if port & 0x8002 == 0x8000:
            if port & 0x4000:
                self.select = value & 15
            else:
                self.ay.append((self.select, value))


class Player:
    """MusicInit, then MusicPlay a frame: regs[f] = the 14 registers after frame f; writes, costs, records"""

    def __init__(self):
        Simulator, self.su = skoolkit()
        mem = bytearray(0x10000)
        data = open(os.path.join(ROOT, 'build', 'music.bin'), 'rb').read()
        mem[0xC000:0xC000 + len(data)] = data
        mem[STOP] = 0x76
        self.mem = mem
        self.sim = Simulator(mem, {'SP': 0x5BE0})
        self.ports = Ports()
        self.sim.set_tracer(self.ports)
        self.r = [0] * 14
        self.regs, self.costs, self.writes, self.rows, self.positions, self.records = [], [], [], [], [], []
        self.init_cost = self.call(0xC00B)
        self.init_writes = list(self.ports.ay)
        self.apply()

    def call(self, address):
        su = self.su
        reg = self.sim.registers
        reg[su.SP] = 0x5BDE
        self.mem[0x5BDE], self.mem[0x5BDF] = STOP & 255, STOP >> 8
        self.ports.ay = []
        t0 = reg[su.T]
        self.sim.run(address, STOP)
        return reg[su.T] - t0

    def apply(self):
        for reg, v in self.ports.ay:
            if reg < 14:
                self.r[reg] = v

    def run(self, frames, keep=False):
        for _ in range(frames):
            row = self.mem[DELAY_COUNTER] == 1
            pos = self.mem[POSITION_OP]
            t = self.call(0xC00E)
            self.apply()
            self.regs.append(tuple(self.r))
            self.costs.append(t)
            self.writes.append(list(self.ports.ay))
            self.rows.append(row)
            self.positions.append(self.mem[POSITION_OP] if self.mem[POSITION_OP] != pos else None)
            if keep:
                self.records.append(bytes(self.mem[0xC0A9:0xC104]))
        return self


def module():
    d = open(os.path.join(ROOT, 'build', 'music.bin'), 'rb').read()
    m = d[TUNE - 0xC000:]
    word = lambda o: m[o] | (m[o + 1] << 8)  # noqa: E731
    pt, st, ot, n = word(1), word(3), word(5), m[7]
    return {'bytes': m, 'delay': m[0], 'patterns': pt, 'samples': st, 'ornaments': ot, 'positions': list(m[8:8 + n])}


def note_name(n):
    midi = n + 22
    return '%s%d' % (NAMES[midi % 12], midi // 12 - 1)


def stream_events(m, addr):
    """one stream from its module offset: [(offset, bytes, text, rows)]"""
    b = m['bytes']
    out, length, env, o = [], 1, False, addr
    while True:
        start, toks = o, []
        while b[o] >= 0x80 and b[o] != 0xFF:
            c = b[o]
            o += 1
            if c < 0xA0:
                toks.append('s%d' % (c - 0x80))
            elif c < 0xC0:
                toks.append('o%d' % (c - 0xA0))
            elif c == 0xC0:
                toks.append('env')
                env = True
            elif c < 0xD0:
                toks.append('v%d' % (c - 0xC0))
                env = False
            elif c < 0xF0:
                toks.append('n%d' % (c - 0xD0))
            elif c == 0xF0:
                length = b[o]
                o += 1
                toks.append('len%d' % length)
            else:
                toks.append('shape%d' % (c - 0xF0))
        c = b[o]
        o += 1
        if c == 0xFF:
            out.append((start, b[start:o], ' '.join(toks + ['end']), 0))
            return out
        if c < 0x56:
            toks.append(note_name(c))
            if env:
                toks.append('ep$%02X' % b[o])
                o += 1
        elif c < 0x7E:
            toks.append('---')
        elif c == 0x7E:
            toks.append('rel')
        else:
            toks.append('off')
        out.append((start, b[start:o], ' '.join(toks), length))


def pattern_streams(m, n):
    b = m['bytes']
    base = m['patterns'] + 6 * n
    return [m['patterns'] + (b[base + 2 * i] | (b[base + 2 * i + 1] << 8)) for i in range(3)]


def position_starts(frames):
    """the model's frames at which NextPosition starts a position, from MusicInit"""
    p = Player().run(frames)
    return p, [i for i, x in enumerate(p.positions) if x is not None]


# ---------------------------------------------------------------------------------------------------------------
# the AY

ENV_SHAPES = {}


def env_level(shape, step):
    """the envelope's volume 0-15 at step (0.. from the R13 write), the AY's 16 steps a cycle"""
    import numpy as np
    step = np.asarray(step)
    cyc, pos = step // 16, step % 16
    attack = bool(shape & 4)
    if shape < 8:  # one cycle, then 0
        first = pos if attack else 15 - pos
        return np.where(cyc == 0, first, 0)
    alt, hold = bool(shape & 2), bool(shape & 1)
    up = np.where(alt & (cyc % 2 == 1), not attack, attack) if alt else np.full(step.shape, attack)
    lvl = np.where(up, pos, 15 - pos)
    if hold:
        end = (not attack) if alt else attack
        lvl = np.where(cyc == 0, np.where(attack, pos, 15 - pos), 15 if end else 0)
    return lvl


def render_ay(regs, restarts=None, rate=44100, clock=AY_CLOCK):
    """frames of 14 registers -> mono float samples: tone squares, the 17-bit noise, the envelope (restarted in the
    frames of `restarts`)"""
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
    npos, epos = 0.0, 0.0
    lv = np.array(LEVELS)
    restarts = set(restarts or ())
    for f, r in enumerate(regs):
        a, b = int(f * per), int((f + 1) * per)
        n = b - a
        t = np.arange(n)
        if f in restarts:
            epos = 0.0
        ninc = clock / (16 * ((r[6] & 31) or 1)) / rate
        noise = lfsr[((npos + t * ninc).astype(np.int64)) % len(lfsr)]
        npos = (npos + n * ninc) % len(lfsr)
        ep = (r[11] | (r[12] << 8)) or 1
        einc = clock / (16 * ep) / rate
        env = env_level(r[13] & 15, (epos + t * einc).astype(np.int64))
        epos += n * einc
        for ch in range(3):
            p = ((r[2 * ch] | (r[2 * ch + 1] << 8)) & 0xFFF) or 1
            inc = clock / (16 * p) / rate
            ph = phase[ch] + t * inc
            phase[ch] = (phase[ch] + n * inc) % 1.0
            tone = (ph % 1.0) < 0.5 if inc < 0.5 else np.ones(n, dtype=bool)
            ton = not (r[7] >> ch) & 1
            non = not (r[7] >> (ch + 3)) & 1
            gate = (tone | (not ton)) & ((noise == 1) | (not non))
            vol = lv[env] if r[8 + ch] & 16 else lv[r[8 + ch] & 15]
            out[a:b] += gate * vol
    out -= np.convolve(out, np.ones(2205) / 2205, mode='same')
    return out / 3


def write_wav(path, samples, rate=44100):
    import numpy as np
    import wave
    peak = max(1e-9, float(np.max(np.abs(samples))))
    data = (samples / peak * 0.8 * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data.tobytes())
    print(path, '%.2f s' % (len(samples) / rate))


def exit_sound():
    g = open(os.path.join(ROOT, 'build', 'main.bin'), 'rb').read()
    return list(g[EXIT_SOUND - GAME_BASE:EXIT_SOUND - GAME_BASE + 14])


FIRST_PASS = 7704   # MusicInit to the second start of position 0 (cmd loop)
LOOP = 7764         # every later tune loop: position 0 waits 10 rows for pattern 14's releases


def player_loop():
    """the first tune loop from MusicInit: what the menu plays"""
    return Player().run(FIRST_PASS + 12, keep=True), FIRST_PASS


# ---------------------------------------------------------------------------------------------------------------
# commands

def cmd_loop(args):
    m = module()
    n = len(m['positions'])
    p, st = position_starts(FIRST_PASS + 2 * LOOP + 10)
    print('delay', m['delay'], 'positions', m['positions'])
    print('position  pattern  loop 1: start, frames   loop 2: start, frames')
    for k in range(n):
        a, b = st[k], st[k + 1]
        c, d = st[n + k], st[n + k + 1]
        print('%8d %8d %10d %6d %12d %6d' % (k, m['positions'][k], a, b - a, c, d - c))
    print('tune loop 1: %d frames, tune loop 2: %d frames, tune loop 3: %d frames' % (st[n], st[2 * n] - st[n],
                                                                     st[3 * n] - st[2 * n]))
    same = sum(p.regs[i] == p.regs[i + LOOP] for i in range(st[n], st[2 * n]))
    print('registers of tune loop 3 = tune loop 2 in %d of %d frames' % (same, st[2 * n] - st[n]))


def cmd_costs(args):
    p, frames = player_loop()
    c = p.costs[:frames]
    rowc = [t for t, r in zip(c, p.rows) if r]
    other = [t for t, r in zip(c, p.rows) if not r]
    print('MusicInit', p.init_cost, 'T')
    print('all frames: min %d mean %.0f max %d' % (min(c), sum(c) / len(c), max(c)))
    print('row frames %d: mean %.0f max %d' % (len(rowc), sum(rowc) / len(rowc), max(rowc)))
    print('other frames %d: mean %.0f max %d' % (len(other), sum(other) / len(other), max(other)))
    print('share of a Pentagon frame: mean %.1f %%, max %.1f %%' % (100 * sum(c) / len(c) / FRAME_T,
                                                                    100 * max(c) / FRAME_T))


def cmd_regs(args):
    p = Player().run(args.start + args.frames)
    print('frame row  ' + ' '.join('R%-3d' % i for i in range(14)))
    for f in range(args.start, args.start + args.frames):
        print('%5d %s  ' % (f, 'r' if p.rows[f] else ' ') + ' '.join('%-4s' % ('%02X' % v) for v in p.regs[f]))


def cmd_pattern(args):
    m = module()
    for ch, addr in zip('ABC', pattern_streams(m, args.n)):
        print('channel', ch, 'stream at TuneHeader+$%04X ($%04X)' % (addr, TUNE + addr))
        row = 0
        for off, bs, text, rows in stream_events(m, addr):
            print('  $%04X  %-14s %-28s row %2d, %d rows' % (TUNE + off, ' '.join('%02X' % x for x in bs), text,
                                                            row, rows))
            row += rows


def trace_ay(tr):
    """[(frame, t, register, value)] of the OUTs to the AY in a trace"""
    out, sel = [], 0
    for x in tr.instructions:
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0x8002 == 0x8000:
                f, t = tr.cycle_t(x, c)
                if c.address & 0x4000:
                    sel = c.value & 15
                else:
                    out.append((f, t, sel, c.value))
    return out


def load_trace(args):
    sys.path.insert(0, KIT)
    import kitlib
    ns = argparse.Namespace(trace=None, work=args.work, window=args.window, max_cycles=None, unreal=None)
    return kitlib.load_trace(ns)


def cmd_check(args):
    tr = load_trace(args)
    ay = trace_ay(tr)
    frames = {}
    for f, t, reg, v in ay:
        frames.setdefault(f, []).append((reg, v))
    p, n = player_loop()
    keys = sorted(frames)
    first = frames[keys[0]]
    cands = [k for k in range(n) if p.writes[k] == first]
    print('recording frames %d-%d: %d AY writes in %d frames' % (keys[0], keys[-1], len(ay), len(keys)))
    for k in cands:
        same = sum(1 for i, f in enumerate(keys) if k + i < len(p.writes) and p.writes[k + i] == frames[f])
        print('model frame %d (recording frame %d = model frame + %d): %d of %d frames write for write' % (
            k, keys[0], keys[0] - k, same, len(keys)))


# ---------------------------------------------------------------------------------------------------------------
# figures

def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'font.family': 'DejaVu Sans Mono', 'axes.titlesize': 12})
    return plt


def period_midi(p):
    if not p:
        return None
    return 69 + 12 * math.log2(AY_CLOCK / (16 * p) / 440)


def cmd_fig_tune(args):
    import numpy as np
    plt = plt_setup()
    p, frames = player_loop()
    regs = np.array(p.regs[:frames])
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 9), dpi=100, sharex=True)
    starts = [i for i, x in enumerate(p.positions[:frames]) if x is not None]
    m = module()
    names = ['A: the melody', 'B: the bass', 'C: the drums']
    for ch, ax in enumerate(axes):
        per = (regs[:, 2 * ch] | (regs[:, 2 * ch + 1] << 8)) & 0xFFF
        vol = regs[:, 8 + ch]
        tone = (regs[:, 7] >> ch) & 1 == 0
        noise = (regs[:, 7] >> (ch + 3)) & 1 == 0
        env = vol & 16 != 0
        x = np.arange(frames) / 50
        y = np.array([period_midi(v) or 0 for v in per])
        lvl = np.where(env, 15, vol & 15)
        on = (lvl > 0) & tone
        sc = ax.scatter(x[on & ~env], y[on & ~env], c=lvl[on & ~env], cmap='viridis', vmin=0, vmax=15, s=2,
                        marker='s', linewidths=0)
        fig.colorbar(sc, ax=ax, pad=0.01, label='volume')
        ax.scatter(x[on & env], y[on & env], color='#e0408a', s=2, marker='s', linewidths=0, label='envelope')
        nz = noise & (lvl > 0)
        if nz.any():
            ax.scatter(x[nz], np.full(nz.sum(), 28), color='#c08030', s=4, marker='|', label='noise on (row 28)')
        for s in starts:
            ax.axvline(s / 50, color='#888888', lw=0.5)
        ax.set_ylabel('MIDI note')
        ax.set_title(names[ch], loc='left', pad=18 if ch == 0 else 6)
        ax.set_ylim(26, 100)
        if ch == 0:
            for i, s in enumerate(starts):
                ax.text(s / 50 + 0.3, 101 + 4 * (i % 2), '%d' % m['positions'][i], fontsize=10, ha='left',
                        va='bottom')
        if nz.any() or env.any():
            ax.legend(loc='lower right', fontsize=10, markerscale=4)
    axes[-1].set_xlabel('seconds from MusicInit (50 frames a second)')
    fig.suptitle('"Disco music" by Ant P, the first tune loop from MusicInit: %d frames, %.1f s\n'
                 'numbers over A: the pattern of each position (grey lines)' % (frames, frames / 50), y=0.998)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


def cmd_fig_regs(args):
    import numpy as np
    plt = plt_setup()
    p = Player().run(args.start + args.frames)
    regs = np.array(p.regs[args.start:args.start + args.frames])
    fig, ax = plt.subplots(figsize=(10.5, 6.2), dpi=100)
    labels = ['R0 A fine', 'R1 A coarse', 'R2 B fine', 'R3 B coarse', 'R4 C fine', 'R5 C coarse', 'R6 noise',
              'R7 mixer', 'R8 A vol', 'R9 B vol', 'R10 C vol', 'R11 env fine', 'R12 env coarse', 'R13 shape']
    prev = np.vstack([regs[:1], regs[:-1]])
    changed = regs != prev
    changed[0] = True
    ax.imshow(changed.T, aspect='auto', cmap='Greys', vmin=0, vmax=3, interpolation='nearest')
    for f in range(regs.shape[0]):
        for r in range(14):
            if changed[f, r]:
                ax.text(f, r, '%02X' % regs[f, r], ha='center', va='center', fontsize=10, rotation=90)
    for f in range(regs.shape[0]):
        if p.rows[args.start + f]:
            ax.axvline(f - 0.5, color='#3070c0', lw=0.8)
    ax.set_yticks(range(14))
    ax.set_yticklabels(labels, fontsize=10)
    ax.set_xticks(range(0, regs.shape[0], 6))
    ax.set_xticklabels([str(args.start + f) for f in range(0, regs.shape[0], 6)], fontsize=10)
    ax.set_xlabel('the model frame (MusicPlay calls from MusicInit); blue line: a row frame (every 6th)')
    ax.set_title('The AY registers after each frame %d-%d; a value is printed where it changed'
                 % (args.start, args.start + args.frames - 1), loc='left')
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


def sample_rows(m, n, ornament=False):
    b = m['bytes']
    table = m['ornaments'] if ornament else m['samples']
    addr = table + (b[table + 2 * n] | (b[table + 2 * n + 1] << 8))
    rows, o, size = [], addr, 2 if ornament else 3
    while True:
        r = b[o:o + size]
        rows.append(r)
        o += size
        f = r[0]
        if f >= 0x20 and f & 0x40:  # loops back: the end of the drawn part
            break
        if not ornament and f >= 0x20 and f & 0x20:
            break
        if len(rows) > 64:
            break
    return addr, rows


def cmd_fig_samples(args):
    plt = plt_setup()
    m = module()
    used = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13]
    fig, axes = plt.subplots(4, 3, figsize=(10.5, 10.5), dpi=100)
    for ax, n in zip(axes.flat, used):
        addr, rows = sample_rows(m, n)
        vols = [r[2] >> 4 for r in rows]
        loop = [i for i, r in enumerate(rows) if r[0] >= 0x20 and r[0] & 0x80]
        x = range(len(rows))
        ax.bar(x, vols, color=['#e0408a' if r[2] & 2 else ('#c08030' if not r[2] & 8 else '#3a9a5a')
                               for r in rows], width=0.9)
        tone = 0
        ts = []
        for r in rows:
            d = r[1] - 256 if r[1] > 127 else r[1]
            tone += d
            ts.append(tone)
        ax2 = ax.twinx()
        ax2.plot(x, ts, color='#3070c0', lw=1.2)
        ax2.tick_params(labelsize=9, colors='#3070c0')
        if loop:
            ax.axvline(loop[0] - 0.5, color='black', lw=1, ls='--')
        end = rows[-1][0]
        how = 'loops' if end >= 0x20 and end & 0x40 else 'ends'
        ax.set_title('sample %d ($%04X): %d rows, %s' % (n, TUNE + addr, len(rows), how), fontsize=10, loc='left')
        ax.set_ylim(0, 16)
        ax.tick_params(labelsize=9)
    ax = axes.flat[len(used)]
    ax.axis('off')
    ax.text(0, 0.95, 'bars: the row volume 0-15\n green: tone, no noise\n orange: noise on\n pink: on the envelope\n'
                     'blue line: the tone offset\n (summed, right axis)\ndashed: the loop row\nx: rows (frames)',
            va='top', fontsize=10, transform=ax.transAxes)
    fig.suptitle('The 11 samples the tune plays, row by row as SampleStep reads them (src/res/music/disco.txt)',
                 y=0.995)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


def cmd_fig_bell(args):
    import numpy as np
    plt = plt_setup()
    bell = exit_sound()
    rate = 44100
    s = render_ay([tuple(bell)] * 175, restarts={0}, rate=rate)
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 5.6), dpi=100)
    t = np.arange(len(s)) / rate
    env = np.abs(s)
    w = 441
    envm = np.convolve(env, np.ones(w) / w, mode='same')
    axes[0].plot(t, envm, color='#e0408a')
    axes[0].set_xlabel('seconds after PlayBell (the 50 ms mean of |sample|)')
    axes[0].set_title('The bell: tones A 2279 Hz and C 1367 Hz on envelope shape 1 (one fall, then silence), '
                      'period $50C4: 3.0 s', loc='left', fontsize=11)
    i0 = int(0.1 * rate)
    axes[1].plot(np.arange(400) / rate * 1000, s[i0:i0 + 400], color='#3070c0', lw=1)
    axes[1].set_xlabel('milliseconds from 0.1 s: the two squares (B, period 1, is above hearing)')
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


def cmd_wavs(args):
    os.makedirs(args.dir, exist_ok=True)
    p, frames = player_loop()
    shapes = [i for i, w in enumerate(p.writes[:frames]) if any(r == 13 for r, _ in w)]
    tune = render_ay(p.regs[:frames], restarts=shapes, rate=22050)
    path = os.path.join(args.dir, 'disco-music.wav')
    write_wav(path, tune, rate=22050)
    mp3 = path[:-4] + '.mp3'
    subprocess.run(['lame', '--quiet', '-b', '128', path, mp3], check=False)
    if os.path.isfile(mp3):
        print(mp3)
    bell = exit_sound()
    write_wav(os.path.join(args.dir, 'bell.wav'), render_ay([tuple(bell)] * 175, restarts={0}))
    # the cut: 2 s of the tune from model frame 1336, SoundOff's zeros for the 8 frames a page takes, the tune again
    zeros = (0,) * 14
    seq = list(p.regs[1336:1436]) + [zeros] * 8 + list(p.regs[1436:1536])
    rs = [i for i in shapes if 1336 <= i < 1536]
    restarts = [i - 1336 + (8 if i >= 1436 else 0) for i in rs]
    write_wav(os.path.join(args.dir, 'soundoff-page.wav'), render_ay(seq, restarts=restarts))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('loop').set_defaults(fn=cmd_loop)
    sub.add_parser('costs').set_defaults(fn=cmd_costs)
    s = sub.add_parser('regs')
    s.add_argument('--from', dest='start', type=int, default=0)
    s.add_argument('--frames', type=int, default=24)
    s.set_defaults(fn=cmd_regs)
    s = sub.add_parser('pattern')
    s.add_argument('n', type=int)
    s.set_defaults(fn=cmd_pattern)
    s = sub.add_parser('check')
    s.add_argument('--work', required=True)
    s.add_argument('--window', required=True)
    s.set_defaults(fn=cmd_check)
    for name, fn in (('fig-tune', cmd_fig_tune), ('fig-samples', cmd_fig_samples), ('fig-bell', cmd_fig_bell)):
        s = sub.add_parser(name)
        s.add_argument('out')
        s.set_defaults(fn=fn)
    s = sub.add_parser('fig-regs')
    s.add_argument('out')
    s.add_argument('--from', dest='start', type=int, default=420)
    s.add_argument('--frames', type=int, default=36)
    s.set_defaults(fn=cmd_fig_regs)
    s = sub.add_parser('wavs')
    s.add_argument('dir')
    s.set_defaults(fn=cmd_wavs)
    a = ap.parse_args()
    a.fn(a)


if __name__ == '__main__':
    main()
