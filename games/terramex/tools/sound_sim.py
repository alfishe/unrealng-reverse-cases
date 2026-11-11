#!/usr/bin/env python3
"""Terramex's sound, run in SkoolKit's Z80 simulator from the case's build: the AY player of RAM 6 frame by frame,
the seven beeper sounds of the game, their WAV renders (written, never played) and the figures of doc 9.

    python3 tools/sound_sim.py loop                          the frames of tune 0's loop (StartTune to StartTune)
    python3 tools/sound_sim.py costs [--frames N]            T-states of MusicFrame a call: min, mean, max, by kind
    python3 tools/sound_sim.py regs --from F --frames N      the AY registers at the end of frames F.. (a table)
    python3 tools/sound_sim.py beeper                        the seven beeper sounds: T-states, toggles, half-periods
    python3 tools/sound_sim.py check --trace T.uatr --start S   the AY writes of a recording's trace against the model,
                                                             S = the recording frame of the model's frame 0 (StartTune)
    python3 tools/sound_sim.py trace-beeper --trace T.uatr --out OUT.wav   a recording's OUT ($FE) edges to a WAV
    python3 tools/sound_sim.py fig-tune OUT.png              tune 0 as a piano roll, the three channels, the loop
    python3 tools/sound_sim.py fig-regs OUT.png --from F --frames N   the 11 registers WriteAY writes, frame by frame
    python3 tools/sound_sim.py fig-witness OUT.png --trace T.uatr --sound N   a beeper sound on the machine vs the model
    python3 tools/sound_sim.py fig-instruments OUT.png       the volume envelope of each instrument (the real code)
    python3 tools/sound_sim.py fig-effects OUT.png           the seven beeper sounds: speaker bit and half-periods
    python3 tools/sound_sim.py fig-cost OUT.png              MusicFrame's T-states over the loop
    python3 tools/sound_sim.py wavs DIR                      tune 0 (WAV and MP3), tune 1 (WAV) and the beeper sounds

The music: build/music.bin at $C000 (RAM 6 as the IM 2 handler $9491 pages it), MusicFrame $C000 called once a
frame from the image's state (PlayerState 0: the first call starts tune 0), as the handler does. The AY writes go
through AYWrite $CD56: OUT ($FFFD) selects, OUT ($BFFD) writes. The state after a call is the frame's sound. The
128K ROM's power-on set-up leaves R7 = $FF and the volumes 0; R6 (noise) and R11-R13 are never written (the AY's
reset 0). AY clock 1 773 400 Hz.

The beeper: build/game.bin at $7200 and ROM 1 of the 128K (the 48 BASIC ROM the game runs with, $7FFD bit 4) at
$0000; PlaySound $C4B2 with A = the sound; the OUT ($FE) writes and their T-states give the speaker bit. The
simulator has no contention and no interrupt: on the machine the IM 2 handler (MusicFrame, about 3600 T a frame)
runs inside the loops and stretches them (doc 9, section 9.11; trace-beeper renders the real recording instead).
CPU clock 3 546 900 Hz. Needs SkoolKit ($SKOOLKIT_VENV), numpy, matplotlib; lame or ffmpeg for the MP3.
"""
import argparse
import glob
import math
import os
import shutil
import subprocess
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AY_CLOCK = 1773400
CPU_CLOCK = 3546900
FRAME_T = 70908
STOP = 0x5BF0
NAMES = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')
# the AY's volume curve (as unreal-ng's psg2wav.py)
LEVELS = (0.0, 0.0137, 0.0205, 0.0291, 0.0423, 0.0618, 0.0847, 0.1369, 0.1691, 0.2647, 0.3527, 0.4499,
          0.5704, 0.6873, 0.8482, 1.0)
# RAM 6 addresses (src/music/music.ann)
PLAYER_STATE = 0xC027
CHANNELS = (0xC153, 0xC180, 0xC1AD)
PATTERN_POINTERS = 0xC1DA
PATTERN_LO, PATTERN_HI = 0xCA37, 0xCA52
TUNE_TABLE = 0xC967
SLOT_TABLE = 0xC11B
# the beeper sounds: number, routine, name, the caller that plays it
SOUNDS = [
    (0, 0xC506, 'rise', 'SoundRise: six bursts, each longer'),
    (1, 0xC4E9, 'rom-fall', 'SoundRomFall: 2250 ROM bytes at a falling pitch, then sound 0'),
    (2, 0xC4CE, 'chirp', 'SoundChirp: four bursts, each shorter (the pickup)'),
    (3, 0xC521, 'hiss', 'SoundHiss: 100 ROM bits picked by R'),
    (4, 0xC54A, 'rom-burst', 'SoundRomBurst: 1280 ROM bytes, no delay'),
    (5, 0xC537, 'beep-high', 'SoundBeepHigh: 5 waves of $64 turns (the drop)'),
    (6, 0xC532, 'beep-low', 'SoundBeepLow: 3 waves of $C8 turns'),
]


def skoolkit():
    venv = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    site = glob.glob(os.path.join(venv, 'lib', 'python3*', 'site-packages'))
    if not site:
        sys.exit(f'no SkoolKit at {venv} ($SKOOLKIT_VENV)')
    sys.path.insert(0, site[0])
    from skoolkit.simulator import Simulator
    from skoolkit import simutils
    return Simulator, simutils


def rom1():
    unreal = os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng')
    data = open(os.path.join(unreal, 'data', 'rom', '128.rom'), 'rb').read()
    return data[16384:32768]


class Ports:
    def __init__(self, sim):
        self.sim = sim
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
    def __init__(self, kind):
        Simulator, self.su = skoolkit()
        mem = bytearray(0x10000)
        if kind == 'music':
            data = open(os.path.join(ROOT, 'build', 'music.bin'), 'rb').read()
            mem[0xC000:0xC000 + len(data)] = data
        else:
            mem[0:0x4000] = rom1()
            data = open(os.path.join(ROOT, 'build', 'game.bin'), 'rb').read()
            mem[0x7200:0x7200 + len(data)] = data
        mem[STOP] = 0x76
        self.mem = mem
        self.sim = Simulator(mem, {'SP': 0x5BE0})
        self.ports = Ports(self.sim)
        self.sim.set_tracer(self.ports)

    def call(self, address, a=0, r=0):
        su = self.su
        reg = self.sim.registers
        reg[su.A] = a
        reg[su.R] = r
        reg[su.SP] = 0x5BDE
        self.mem[0x5BDE], self.mem[0x5BDF] = STOP & 255, STOP >> 8
        self.ports.ay, self.ports.fe = [], []
        t0 = reg[su.T]
        self.sim.run(address, STOP)
        return reg[su.T] - t0


class Music:
    """MusicFrame a frame: regs[f] = the 14 registers after frame f's call; costs; snapshots of the state"""

    def __init__(self, machine=None):
        self.m = machine or Machine('music')
        self.r = [0] * 14
        self.r[7] = 0xFF
        self.regs, self.costs, self.writes, self.state = [], [], [], []

    def run(self, frames, keep=False):
        for _ in range(frames):
            t = self.m.call(0xC000)
            for reg, v in self.m.ports.ay:
                if reg < 14:
                    self.r[reg] = v
            self.regs.append(tuple(self.r))
            self.costs.append(t)
            self.writes.append(list(self.m.ports.ay))
            if keep:
                self.state.append(bytes(self.m.mem[0xC000:0xD200]))
        return self


def loop_frames(limit=30000):
    """the frames at which StartTune runs (PlayerState 0 before the call)"""
    m = Machine('music')
    starts = []
    for f in range(limit):
        if m.mem[PLAYER_STATE] == 0:
            starts.append(f)
        m.call(0xC000)
    return starts


def period_note(period):
    if not period:
        return None
    f = AY_CLOCK / (16 * period)
    return 69 + 12 * math.log2(f / 440)


def note_name(m):
    n = int(round(m))
    return '%s%d' % (NAMES[n % 12], n // 12 - 1)


# ---------------------------------------------------------------------------------------------------------------
# rendering

def render_ay(regs, rate=44100):
    """frames of 14 registers -> mono float samples; tone squares, the 17-bit noise, fixed volumes (the player never
    uses the envelope)"""
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
    out -= np.convolve(out, np.ones(2205) / 2205, mode='same')  # the DC taken away (a 50 ms mean)
    return out / 3


def render_edges(edges, clock=CPU_CLOCK, rate=44100, tail=0.05):
    """[(T, speaker 0/1)] from T 0 -> mono float samples, each the mean level over its interval"""
    import numpy as np
    if not edges:
        return np.zeros(1)
    ts = np.array([e[0] for e in edges], dtype=np.float64)
    vs = np.array([e[1] for e in edges], dtype=np.float64)
    end = ts[-1] + tail * clock
    seg_t = np.append(ts, end)
    # the integral of the level at each edge time
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


def beeper(n):
    """sound n in the simulator: (T-states of the call, [(T from the first OUT, speaker bit)])"""
    m = Machine('game')
    t = m.call(0xC4B2, n, r=0)
    fe = m.ports.fe
    t0 = fe[0][0] if fe else 0
    edges = []
    last = None
    for tt, v in fe:
        b = (v >> 4) & 1
        if b != last:
            edges.append((tt - t0, b))
            last = b
    return t, edges, len(fe)


def trace_edges(path, port_low=0xFE):
    sys.path.insert(0, os.path.join(os.path.dirname(ROOT), '..', 'kit'))
    import kitlib
    tr = kitlib.access_trace().load(path)
    out = []
    for x in tr.instructions:
        for c in x.cycles:
            if c.tag == 'O' and not c.address & 1:
                f, t = tr.cycle_t(x, c)
                out.append((f * tr.frame_t + t, (c.value >> 4) & 1, f, t))
    return tr, out


# ---------------------------------------------------------------------------------------------------------------
# commands

def cmd_loop(args):
    s = loop_frames(args.frames)
    print('StartTune at frames', s)
    print('loop lengths', [b - a for a, b in zip(s, s[1:])])


def cmd_costs(args):
    mu = Music().run(args.frames)
    c = mu.costs
    print('calls', len(c), 'T min', min(c), 'mean %.0f' % (sum(c) / len(c)), 'max', max(c))
    noaw = [t for t, w in zip(c, mu.writes) if not w]
    aw = [t for t, w in zip(c, mu.writes) if w]
    print('frames with AY writes', len(aw), 'mean %.0f' % (sum(aw) / max(1, len(aw))))
    print('frames with none (a note ended)', len(noaw), 'mean %.0f' % (sum(noaw) / max(1, len(noaw))))
    print('share of a 128K frame (70 908 T): %.2f %%' % (100 * sum(c) / len(c) / FRAME_T))


def cmd_regs(args):
    mu = Music().run(args.__dict__['from'] + args.frames)
    print('frame | R0-1 A | R2-3 B | R4-5 C | R7 | R8 R9 R10 | notes')
    for f in range(args.__dict__['from'], args.__dict__['from'] + args.frames):
        r = mu.regs[f]
        pa, pb, pc = (r[0] | r[1] << 8), (r[2] | r[3] << 8), (r[4] | r[5] << 8)
        names = ' '.join(note_name(period_note(p)) if p else '-' for p in (pa, pb, pc))
        print('%5d | %04X | %04X | %04X | %02X | %2d %2d %2d | %s %s' % (
            f, pa, pb, pc, r[7], r[8], r[9], r[10], names, '' if mu.writes[f] else '(no write)'))


def cmd_beeper(args):
    print('| Sound | Routine | T-states (simulator) | ms | OUT writes | speaker edges | half-period first / last (T) |')
    print('| --- | --- | ---: | ---: | ---: | ---: | --- |')
    for n, addr, name, what in SOUNDS:
        t, edges, outs = beeper(n)
        hp = [b[0] - a[0] for a, b in zip(edges, edges[1:])]
        print('| %d %s | `$%04X` | %d | %.1f | %d | %d | %s / %s |' % (
            n, name, addr, t, 1000 * t / CPU_CLOCK, outs, len(edges), hp[0] if hp else '-', hp[-1] if hp else '-'))


def cmd_check(args):
    tr_mod = None
    sys.path.insert(0, os.path.join(ROOT, '..', '..', 'kit'))
    import kitlib
    tr = kitlib.access_trace().load(args.trace)
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
    mu = Music().run(last - args.start + 2)
    same = diff = 0
    for f in sorted(frames):
        k = f - args.start
        model = mu.writes[k] if 0 <= k < len(mu.writes) else None
        if model == frames[f]:
            same += 1
        else:
            diff += 1
            if diff <= 5:
                print('frame', f, 'model frame', k, 'trace', frames[f], 'model', model)
    f_lo, f_hi = tr.from_frame, tr.to_frame
    quiet = [f for f in range(f_lo, f_hi) if f not in frames]
    quiet_model = [f for f in quiet if 0 <= f - args.start < len(mu.writes) and not mu.writes[f - args.start]]
    print('frames with AY writes in the trace: %d (%d-%d); equal to the model: %d, different: %d' % (
        len(frames), first, last, same, diff))
    print('frames of the window with no AY write: %d, of them silent in the model too: %d' % (
        len(quiet), len(quiet_model)))


def cmd_trace_beeper(args):
    tr, ev = trace_edges(args.trace)
    edges, last = [], None
    for T, b, f, t in ev:
        if b != last:
            edges.append((T, b))
            last = b
    if not edges:
        sys.exit('no OUT ($FE) in the trace')
    t0 = edges[0][0]
    print('OUT ($FE) writes', len(ev), 'speaker edges', len(edges), 'from %d:%d to %d:%d' % (
        ev[0][2], ev[0][3], ev[-1][2], ev[-1][3]), 'span %d T (%.1f ms)' % (edges[-1][0] - t0,
                                                                        1000 * (edges[-1][0] - t0) / CPU_CLOCK))
    if args.out:
        write_wav(args.out, render_edges([(T - t0, b) for T, b in edges]))
        print('wrote', args.out)


def cmd_fig_witness(args):
    """A beeper sound on the machine (an access trace) against the simulator: the half-periods edge by edge."""
    import numpy as np
    plt = plt_setup()
    tr, ev = trace_edges(args.trace)
    edges, last = [], None
    for T, b, f, t in ev:
        if b != last:
            edges.append((T, b, f, t))
            last = b
    t0 = edges[0][0]
    me = np.array([e[0] - t0 for e in edges], dtype=float)
    _, sim_edges, _ = beeper(args.sound)
    se = np.array([e[0] for e in sim_edges], dtype=float)
    se -= se[0]
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 6.4), gridspec_kw={'height_ratios': [1, 2]})
    ax = axes[0]
    ax.step(me / CPU_CLOCK * 1000, [e[1] for e in edges], where='post', lw=0.8, color='tab:blue', label='the machine (the recording)')
    ax.step(se / CPU_CLOCK * 1000, [e[1] * 0.8 + 0.1 for e in sim_edges], where='post', lw=0.8, color='tab:orange',
            label='simulator (scaled 0.1-0.9)')
    handler = [x.frame * tr.frame_t + x.t - t0 for x in tr.instructions if x.pc == 0x9491]
    for h in (h for h in handler if 0 < h < me[-1]):
        for a in axes:
            a.axvline(h / CPU_CLOCK * 1000, color='tab:red', lw=1, ls='--')
    ax.set_yticks([0, 1])
    ax.set_ylabel('bit 4')
    ax.legend(fontsize=10, loc='lower right', bbox_to_anchor=(1, 1), ncol=2, frameon=False)
    ax = axes[1]
    ax.plot(me[1:] / CPU_CLOCK * 1000, np.diff(me), 'o', ms=5, color='tab:blue', label='the machine: T between edges')
    ax.plot(se[1:] / CPU_CLOCK * 1000, np.diff(se), 'x', ms=6, color='tab:orange', label='simulator: T between edges')
    ax.set_yscale('log')
    import matplotlib.ticker as mt
    ax.yaxis.set_major_formatter(mt.ScalarFormatter())
    ax.yaxis.set_minor_formatter(mt.NullFormatter())
    ax.set_yticks([100, 300, 1000, 3000, 10000, 30000])
    ax.set_ylabel('T-states')
    ax.set_xlabel('ms from the first speaker edge; red dashes: the interrupt (IM 2 handler and MusicFrame run inside the sound)')
    ax.legend(fontsize=10, loc='upper right')
    for a in axes:
        a.set_xlim(-0.5, me[-1] / CPU_CLOCK * 1000 + 0.5)
    fig.suptitle('%s: sound %d on the machine (%s) against the simulator\n%d edges both; %d T on the machine, %d T in the simulator'
                 % (args.label, args.sound, os.path.basename(args.trace), len(me), me[-1], se[-1]), fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out, len(me), len(se), int(me[-1]), int(se[-1]))


def cmd_wavs(args):
    os.makedirs(args.dir, exist_ok=True)
    s = loop_frames(20000)
    n = s[1] - s[0]
    mu = Music().run(n)
    wav = os.path.join(args.dir, 'tune-0.wav')
    write_wav(wav, render_ay(mu.regs))
    print('wrote', wav, n, 'frames')
    mp3 = os.path.join(args.dir, 'tune-0.mp3')
    if shutil.which('lame'):
        subprocess.run(['lame', '--quiet', '-b', '128', wav, mp3], check=True)
    else:
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', wav, '-b:a', '128k', mp3], check=True)
    os.remove(wav)
    print('wrote', mp3)
    # tune 1: the same player, StartTune with A = 1 (no code does it: known only from the code)
    m = Machine('music')
    m.call(0xC79F, 1)
    mu1 = Music(m)
    frames = 0
    while m.mem[PLAYER_STATE] and frames < 12000:
        mu1.run(1)
        frames += 1
    p = os.path.join(args.dir, 'tune-1.wav')
    write_wav(p, render_ay(mu1.regs))
    print('wrote', p, frames, 'frames (model only)')
    for num, addr, name, what in SOUNDS:
        t, edges, outs = beeper(num)
        p = os.path.join(args.dir, 'beeper-%d-%s.wav' % (num, name))
        write_wav(p, render_edges(edges))
        print('wrote', p, '%.1f ms' % (1000 * t / CPU_CLOCK))


# ---------------------------------------------------------------------------------------------------------------
# figures

def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'figure.dpi': 100, 'text.parse_math': False})
    return plt


def channel_patterns(mu_state):
    """per frame and channel the pattern number playing (PatternPointers against PatternLo/Hi)"""
    out = []
    for st in mu_state:
        lo = st[PATTERN_LO - 0xC000:PATTERN_LO - 0xC000 + 27]
        hi = st[PATTERN_HI - 0xC000:PATTERN_HI - 0xC000 + 27]
        addr = {lo[i] | hi[i] << 8: i for i in range(27)}
        row = []
        for ch in range(3):
            o = PATTERN_POINTERS - 0xC000 + 2 * ch
            row.append(addr.get(st[o] | st[o + 1] << 8))
        out.append(row)
    return out


def cmd_fig_tune(args):
    import numpy as np
    plt = plt_setup()
    s = loop_frames(20000)
    n = s[1] - s[0]
    mu = Music().run(n, keep=True)
    pats = channel_patterns(mu.state)
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 9.6), sharex=True)
    colours = ('tab:blue', 'tab:orange', 'tab:green')
    t = np.arange(n) / 50
    for ch, ax in enumerate(axes):
        notes = np.full(n, np.nan)
        vol = np.zeros(n)
        noise = np.zeros(n, dtype=bool)
        for f, r in enumerate(mu.regs):
            p = r[2 * ch] | r[2 * ch + 1] << 8
            v = r[8 + ch] & 15
            vol[f] = v
            tone_on = not (r[7] >> ch) & 1
            noise[f] = not (r[7] >> (ch + 3)) & 1
            if p and v and tone_on:
                notes[f] = period_note(p)
        ax.scatter(t, notes, s=1.2, c=colours[ch], alpha=np.clip(vol / 15, 0.08, 1))
        nz = noise & (vol > 0)
        if nz.any():
            ax.scatter(t[nz], np.full(nz.sum(), 34), s=2, c='k', marker='|', label='noise (instrument 2 or 8)')
        prev, last_x, level = None, -99, 0
        for f in range(n):
            pn = pats[f][ch]
            if pn != prev and pn is not None:
                ax.axvline(f / 50, color='0.85', lw=0.6, zorder=0)
                level = level + 1 if f / 50 - last_x < 4 else 0
                ax.text(f / 50, 101 - 3.5 * (level % 3), str(pn), fontsize=10, color='0.3', ha='left', va='top')
                last_x = f / 50
            prev = pn
        ax.set_ylim(30, 102)
        ticks = [36, 48, 60, 72, 84]
        ax.set_yticks(ticks)
        ax.set_yticklabels([note_name(x) for x in ticks])
        ax.set_ylabel('channel %s' % 'ABC'[ch])
        ax.grid(axis='y', color='0.9')
    axes[-1].set_xlabel('seconds from StartTune (50 frames a second); grey lines: a new pattern, its number at the top;\n'
                        'black dashes at the bottom: noise on (instrument 2 or 8)')
    fig.suptitle('Tune 0, the only tune the game plays: %d frames (%.1f s) from StartTune to StartTune\n'
                 'each dot a frame\'s note as R0-R5 give it, its shade the volume (R8-R10)' % (n, n / 50), fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out, n, 'frames')


def cmd_fig_regs(args):
    import numpy as np
    plt = plt_setup()
    f0, nf = args.__dict__['from'], args.frames
    mu = Music().run(f0 + nf)
    regs = mu.regs[f0:f0 + nf]
    fr = np.arange(f0, f0 + nf)
    fig, axes = plt.subplots(4, 1, figsize=(10.5, 9), sharex=True,
                             gridspec_kw={'height_ratios': [3, 2, 1, 0.6]})
    for ch, c in enumerate(('tab:blue', 'tab:orange', 'tab:green')):
        p = np.array([r[2 * ch] | r[2 * ch + 1] << 8 for r in regs], dtype=float)
        p[p == 0] = np.nan
        axes[0].step(fr, p, where='post', color=c, label='R%d-R%d channel %s period' % (2 * ch, 2 * ch + 1, 'ABC'[ch]))
        v = [r[8 + ch] for r in regs]
        axes[1].step(fr, v, where='post', color=c, label='R%d volume %s' % (8 + ch, 'ABC'[ch]))
    import matplotlib.ticker as mt
    axes[0].set_yscale('log')
    axes[0].yaxis.set_major_formatter(mt.ScalarFormatter())
    axes[0].yaxis.set_minor_formatter(mt.NullFormatter())
    axes[0].set_yticks([50, 100, 200, 500, 1000, 2000])
    axes[0].set_ylabel('tone period (AY clock / 16)')
    axes[0].legend(fontsize=10, loc='lower right', bbox_to_anchor=(1, 1), ncol=3, frameon=False)
    axes[1].set_ylabel('volume 0-15')
    axes[1].legend(fontsize=10, loc='lower right', bbox_to_anchor=(1, 1), ncol=3, frameon=False)
    mix = np.array([[(r[7] >> b) & 1 for b in range(6)] for r in regs]).T
    axes[2].imshow(1 - mix, aspect='auto', cmap='Greys', interpolation='nearest',
                   extent=(f0, f0 + nf, 5.5, -0.5), vmin=0, vmax=1.6)
    axes[2].set_yticks(range(6))
    axes[2].set_yticklabels(['tone A', 'tone B', 'tone C', 'noise A', 'noise B', 'noise C'], fontsize=10)
    axes[2].set_ylabel('R7 on')
    nowr = np.array([0 if w else 1 for w in mu.writes[f0:f0 + nf]])
    axes[3].bar(fr, nowr, width=1.0, color='tab:red')
    axes[3].set_yticks([])
    axes[3].set_ylabel('no write', fontsize=10)
    axes[3].set_xlabel('frame from StartTune (the model, which the c1 trace matches write for write)')
    fig.suptitle('The 11 registers WriteAY sets, frames %d-%d of tune 0:\n'
                 'the periods, the volumes, the mixer, and the frames a note ends (no write)' % (f0, f0 + nf - 1),
                 fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_instruments(args):
    """each instrument on one note: a test pattern instr n, note 40 for 40 frames, $FF; tune entry 0 replaced"""
    import numpy as np
    plt = plt_setup()
    rows = []
    for inst in range(11):
        m = Machine('music')
        mem = m.mem
        # a pattern at $D100: instr slot 0, note 40 (48 frames), rest 20, $FF; channel A order list: pattern 26, $FF
        pat = 0xD100
        mem[pat:pat + 6] = bytes([0x80, 40, 48, 0xA0, 20, 0xFF])
        mem[PATTERN_LO + 26], mem[PATTERN_HI + 26] = pat & 255, pat >> 8
        order = 0xD110
        mem[order:order + 3] = bytes([0xE0, 9 * inst, 26])
        mem[order + 3] = 0xFF
        # channels B and C rest: order list "pattern 25" with pattern 25 = a rest of 256 frames (an order list
        # that ends at once would end the tune)
        rest = 0xD130
        mem[rest:rest + 3] = bytes([0xA0, 0x00, 0xFF])
        mem[PATTERN_LO + 25], mem[PATTERN_HI + 25] = rest & 255, rest >> 8
        empty = 0xD120
        mem[empty:empty + 2] = bytes([25, 0xFF])
        mem[TUNE_TABLE:TUNE_TABLE + 6] = bytes([order & 255, order >> 8, empty & 255, empty >> 8, empty & 255,
                                                empty >> 8])
        mu = Music(m).run(70)  # the call that starts the tune, an order-list frame, 48 note frames, 20 rest frames
        rows.append([r[8] for r in mu.regs][:69])  # frame 69 is EndTune's silence
    fig, axes = plt.subplots(3, 4, figsize=(10.5, 7.2), sharex=True, sharey=True)
    import csv
    recs = list(csv.reader(l for l in open(os.path.join(ROOT, 'src', 'res', 'music', 'instruments.csv'))
                           if not l.startswith('#')))[1:]
    for i, ax in enumerate(axes.flat):
        if i >= 11:
            ax.axis('off')
            continue
        ax.step(range(len(rows[i])), rows[i], where='post', color='tab:blue')
        ax.axvspan(2, 50, color='0.93', zorder=0)
        rec = recs[i]
        noise = int(rec[3][1:], 16) & 0x80
        ax.set_title('record %d: %s, peak %d\nAD %s, SR %s, vibrato %s' % (
            i, 'noise' if noise else 'tone', int(rec[9][1:], 16), rec[4], rec[5], rec[8]), fontsize=10)
        ax.set_ylim(-0.5, 15.5)
        ax.grid(color='0.9')
    for ax in axes[-1]:
        ax.set_xlabel('frame')
    for ax in axes[:, 0]:
        ax.set_ylabel('R8 volume')
    fig.suptitle('Each instrument\'s volume (R8) as the player\'s own code computes it: one note of 48 frames '
                 '(grey), then a rest of 20', fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_effects(args):
    import numpy as np
    plt = plt_setup()
    fig, axes = plt.subplots(7, 2, figsize=(10.5, 13), gridspec_kw={'width_ratios': [3, 2]})
    for row, (n, addr, name, what) in enumerate(SOUNDS):
        t, edges, outs = beeper(n)
        ts = np.array([e[0] for e in edges]) / CPU_CLOCK * 1000
        vs = np.array([e[1] for e in edges])
        ax = axes[row][0]
        ax.step(np.append(ts, t / CPU_CLOCK * 1000), np.append(vs, vs[-1]) if len(vs) else [0], where='post', lw=0.5,
                color='tab:blue')
        ax.set_xlim(0, t / CPU_CLOCK * 1000)
        ax.set_yticks([0, 1])
        ax.set_ylabel('bit 4', fontsize=10)
        ax.set_title('%d %s, $%04X: %s; %.1f ms' % (n, name, addr, what, 1000 * t / CPU_CLOCK), fontsize=10,
                     loc='left')
        ax2 = axes[row][1]
        hp = np.diff(ts) * 1000
        if len(hp):
            ax2.plot(ts[:-1], hp, '.', ms=2 if len(hp) > 50 else 5, color='tab:red')
        if len(hp) and hp.max() / hp.min() < 4:
            ax2.set_ylim(0, hp.max() * 1.25)
        elif len(hp):
            import matplotlib.ticker as mt
            ax2.set_yscale('log')
            ax2.yaxis.set_major_formatter(mt.ScalarFormatter())
            ax2.yaxis.set_minor_formatter(mt.NullFormatter())
        ax2.set_ylabel('half-period µs', fontsize=10)
        ax2.set_xlim(0, t / CPU_CLOCK * 1000)
    axes[-1][0].set_xlabel('ms from the first OUT ($FE)')
    axes[-1][1].set_xlabel('ms from the first OUT ($FE)')
    fig.suptitle('The seven beeper sounds as the speaker bit (left) and the time between its edges (right),\n'
                 'run in the simulator from PlaySound $C4B2 (no interrupt, no contention)', fontsize=12)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out)


def cmd_fig_cost(args):
    import numpy as np
    plt = plt_setup()
    s = loop_frames(20000)
    n = s[1] - s[0]
    mu = Music().run(n)
    c = np.array(mu.costs)
    fig, ax = plt.subplots(figsize=(10.5, 4.2))
    nw = np.array([0 if w else 1 for w in mu.writes], dtype=bool)
    fr = np.arange(n) / 50
    ax.plot(fr[~nw], c[~nw], '.', ms=1.5, color='tab:blue', label='frames with the AY written (%d)' % (~nw).sum())
    ax.plot(fr[nw], c[nw], '.', ms=2.5, color='tab:red', label='frames a note ends, no write (%d)' % nw.sum())
    ax.axhline(c.mean(), color='0.4', lw=0.8, ls='--')
    ax.text(fr[-1] / 2, 9600, 'dashed: the mean, %.0f T' % c.mean(), va='center', ha='center', fontsize=10)
    ax.set_xlabel('seconds from StartTune')
    ax.set_ylabel('T-states a call')
    ax.legend(fontsize=10, loc='upper left')
    ax.set_title('MusicFrame $C000 over the whole loop of tune 0 (%d calls, simulator, no contention):\n'
                 '%.1f %% of a 70 908 T frame on average, %d-%d T a call' % (n, 100 * c.mean() / FRAME_T, c.min(),
                                                                          c.max()), fontsize=11)
    fig.tight_layout()
    fig.savefig(args.out)
    print('wrote', args.out, 'min', c.min(), 'max', c.max(), 'mean %.0f' % c.mean())


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('loop')
    s.add_argument('--frames', type=int, default=20000)
    s = sub.add_parser('costs')
    s.add_argument('--frames', type=int, default=9698)
    s = sub.add_parser('regs')
    s.add_argument('--from', type=int, default=0)
    s.add_argument('--frames', type=int, default=50)
    sub.add_parser('beeper')
    s = sub.add_parser('check')
    s.add_argument('--trace', required=True)
    s.add_argument('--start', type=int, required=True)
    s = sub.add_parser('trace-beeper')
    s.add_argument('--trace', required=True)
    s.add_argument('--out')
    for name in ('fig-tune', 'fig-instruments', 'fig-effects', 'fig-cost'):
        s = sub.add_parser(name)
        s.add_argument('out')
    s = sub.add_parser('fig-regs')
    s.add_argument('out')
    s.add_argument('--from', type=int, default=0)
    s.add_argument('--frames', type=int, default=200)
    s = sub.add_parser('fig-witness')
    s.add_argument('out')
    s.add_argument('--trace', required=True)
    s.add_argument('--sound', type=int, required=True)
    s.add_argument('--label', default='')
    s = sub.add_parser('wavs')
    s.add_argument('dir')
    a = p.parse_args()
    {'loop': cmd_loop, 'costs': cmd_costs, 'regs': cmd_regs, 'beeper': cmd_beeper, 'check': cmd_check,
     'trace-beeper': cmd_trace_beeper, 'fig-tune': cmd_fig_tune, 'fig-regs': cmd_fig_regs, 'fig-witness': cmd_fig_witness,
     'fig-instruments': cmd_fig_instruments, 'fig-effects': cmd_fig_effects, 'fig-cost': cmd_fig_cost,
     'wavs': cmd_wavs}[a.cmd](a)


if __name__ == '__main__':
    main()
