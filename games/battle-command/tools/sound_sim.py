#!/usr/bin/env python3
"""Battle Command's two AY drivers run frame by frame in SkoolKit's Z80 simulator, from the case's build: the AY
register stream of each, a WAV render (written, never played), the decoded tune and the register charts of doc 9.

    python3 tools/sound_sim.py music  [--frames N] [--wav OUT.wav]      the bank 4 tune: StartTune A=0, MusicTick a frame
    python3 tools/sound_sim.py effect NAME [--speed S] [--frames N] [--wav OUT.wav]
    python3 tools/sound_sim.py engine --speeds 0,16,32 [--frames N] [--wav OUT.wav]
    python3 tools/sound_sim.py table                                  every effect: trigger, frames, registers (markdown)
    python3 tools/sound_sim.py score                                  the tune's order lists and patterns as text
    python3 tools/sound_sim.py loop [--frames N]                      the frame the tune's state repeats from
    python3 tools/sound_sim.py costs                                  T-states of one call of each driver per frame
    python3 tools/sound_sim.py state --frames N                       the channel records after StartTune and N ticks
    python3 tools/sound_sim.py fig-effects OUT.png | fig-tune OUT.png [--frames N] | fig-engine OUT.png
    python3 tools/sound_sim.py wavs DIR                               every effect, the engine and the tune into DIR

The sources are build/bank4.bin (bank 4 at $C000) and build/game.bin (the Z80 view $5B00-$FFFF with banks 5, 2, 0),
the outputs of tools/build.sh. The music: StartTune ($C000, A = 0, as Bank4Start $72C6 calls it), then MusicTick
($C0D2) once a frame, as Bank4Tick ($72D2) in the IM 2 handler. An effect: the gates of SoundFrame set as in play
($D691 = 1 as in the image, $D689 = 0 as StartMission leaves it), PlayerSpeed $75F7 = --speed, the trigger routine
called once, then SoundFrame ($D692) once a frame, as SoundTick ($7E6E) in the handler. The effects whose trigger no
routine calls are started the same way, from their trigger entries.

The register writes go to ports $FFFD (select) and $BFFD (data), decoded as the 128K does (A15 = 1, A1 = 0, A14 picks
the select). The state at the end of a frame's call is the frame's sound; a write of R13 restarts the envelope. The
AY clock is the 128K's 1 773 400 Hz. Needs SkoolKit ($SKOOLKIT_VENV), numpy, scipy, matplotlib.
"""
import argparse
import glob
import math
import os
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLOCK = 1773400
STOP = 0x5BF0
DAC = (0x0000, 0x0385, 0x053D, 0x0770, 0x0AD7, 0x0FD5, 0x15B0, 0x230C,
       0x2B4C, 0x43C1, 0x5A4B, 0x732F, 0x9204, 0xAFF1, 0xD921, 0xFFFF)
NAMES = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')

# the bank 0 effects: name, trigger entry, counter, start value, caller (or None), what it is
EFFECTS = [
    ('select', 0xD863, 0xD682, 0x12, 'SelectWeapon (player.asm, the weapon keys)', 'weapon selected'),
    ('select-short', 0xD85E, 0xD682, 0x01, None, 'one-frame blip'),
    ('explosion', 0xD86B, 0xD683, 0x20, 'PlayerHit (player.asm), MessageOnce (interrupt.asm)', 'explosion'),
    ('kill', 0xD873, 0xD684, 0x80, 'KillGunEmplacement / the kill path (enemies.asm)', 'object destroyed'),
    ('tone-c8', 0xD87B, 0xD685, 0x07, None, 'short tone'),
    ('fire', 0xD898, 0xD686, 0x14, 'FireCannon (player.asm)', 'cannon shot'),
    ('missile', 0xD883, 0xD687, 0x1E, 'LaunchMissile (player.asm, JP)', 'missile launched'),
    ('random-tone', 0xD856, 0xD68A, 0x01, None, 'random tone, one frame'),
    ('message', 0xD84E, 0xD68B, 0x1E, 'MessageOnce (interrupt.asm)', 'message beep'),
    ('noise-11', 0xD841, 0xD68C, 0x11, None, 'steady noise, 17 frames'),
    ('noise-23', 0xD846, 0xD68C, 0x23, None, 'steady noise, 35 frames'),
    ('sweep', 0xD839, 0xD68D, 0x1F, None, 'falling sweep'),
    # the entry's JR lands on the LD A,$40 of siren-40 (9.5, the siren bug): it stores 64, not $60
    ('siren-60', 0xD88B, 0xD68E, '64 (meant 96)', None, 'two-tone siren, 64 frames'),
    ('siren-40', 0xD890, 0xD68E, 0x40, None, 'two-tone siren, 64 frames'),
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


class Ports:
    def __init__(self):
        self.select, self.frame = 0, []

    def write_port(self, registers, port, value, *rest):
        if port & 0x8002 == 0x8000:
            if port & 0x4000:
                self.select = value & 15
            else:
                self.frame.append((self.select, value))


class Machine:
    """A 64 K memory with the image(s), the simulator, call(address, a) -> (the frame's AY writes, T-states)"""

    def __init__(self, kind):
        Simulator, self.su = skoolkit()
        mem = bytearray(0x10000)
        if kind == 'music':
            data = open(os.path.join(ROOT, 'build', 'bank4.bin'), 'rb').read()
            mem[0xC000:0xC000 + len(data)] = data
        else:
            data = open(os.path.join(ROOT, 'build', 'game.bin'), 'rb').read()
            mem[0x5B00:0x5B00 + len(data)] = data
            mem[0xD689] = 0  # StartMission clears it (missionflow); SilenceAY sets it in the menus
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
        self.ports.frame = []
        t0 = reg[su.T]
        self.sim.run(address, STOP)
        return self.ports.frame, reg[su.T] - t0


def stream(machine, start, tick, frames, before=None, each=None):
    """[(the 14 registers at the frame's end, R13 written)] and the T-states of each tick"""
    regs = [0] * 14
    regs[7] = 0x3F
    if before:
        before(machine)
    if start:
        for r, v in machine.call(*start)[0]:
            if r < 14:
                regs[r] = v
    out, costs = [], []
    for i in range(frames):
        if each:
            each(machine, i)
        writes, t = machine.call(tick)
        costs.append(t)
        for r, v in writes:
            if r < 14:
                regs[r] = v
        out.append((tuple(regs), any(r == 13 for r, _ in writes)))
    return out, costs


def music(frames, snap=None):
    m = Machine('music')
    snaps = []

    def each(machine, i):
        if snap is not None:
            snaps.append(bytes(machine.mem[0xC05A:0xC0D2]))
    out, costs = stream(m, (0xC000, 0), 0xC0D2, frames, each=each)
    return out, costs, snaps, m


def effect(name, frames, speed=0):
    e = [x for x in EFFECTS if x[0] == name]
    if not e:
        sys.exit(f'unknown effect {name}: ' + ', '.join(x[0] for x in EFFECTS))
    _, trig, *_ = e[0]
    m = Machine('game')
    m.mem[0x75F7] = speed & 255
    return stream(m, (trig, 0), 0xD692, frames)


def engine(speeds, frames):
    m = Machine('game')
    seq = []
    per = max(1, frames // len(speeds))

    def each(machine, i):
        machine.mem[0x75F7] = speeds[min(i // per, len(speeds) - 1)] & 255
    out, costs = stream(m, None, 0xD692, per * len(speeds), each=each)
    return out, costs


# ---------------------------------------------------------------------------------------------------------------
# the AY

def envelope_level(shape, steps):
    import numpy as np
    first = steps < 16
    up = shape & 4
    s = np.minimum(steps, 15)
    rise = s if up else 15 - s
    if shape < 8:
        return np.where(first, rise, 0)
    alt, hold = shape & 2, shape & 1
    pos = steps % 16
    if hold:
        after = (15 if up else 0) if not alt else (0 if up else 15)
        return np.where(first, rise, after)
    if alt:
        going_up = ((steps // 16) % 2 == 0) == bool(up)
        return np.where(going_up, pos, 15 - pos)
    return pos if up else 15 - pos


def render(frames, rate=44100, dc=True):
    """The AY's three channels summed, a sample a numpy float: squares (a period 0 counts as 1), the 17-bit noise
    LFSR, the envelope (16 steps of 16 x EP clocks... an envelope step every 256 x EP / 16 clocks)"""
    import numpy as np
    from scipy.signal import lfilter
    dac = np.array(DAC) / 0xFFFF
    per = rate / 50
    total = int(len(frames) * per)
    out = np.zeros((3, total))
    lfsr = np.zeros(1 << 17, dtype=np.uint8)
    st = 1
    for i in range(len(lfsr)):
        lfsr[i] = st & 1
        st = (st >> 1) | (((st ^ (st >> 3)) & 1) << 16)
    phase = [0.0] * 3
    npos = 0.0
    env = 0.0
    for f, (r, retrig) in enumerate(frames):
        a, b = int(f * per), int((f + 1) * per)
        n = b - a
        t = np.arange(n)
        ninc = CLOCK / (16 * ((r[6] & 31) or 1)) / rate
        noise = lfsr[((npos + t * ninc).astype(np.int64)) % len(lfsr)]
        npos = (npos + n * ninc) % len(lfsr)
        if retrig:
            env = 0.0
        einc = CLOCK / (16 * ((r[11] | (r[12] << 8)) or 1)) / rate
        steps = (env + t * einc).astype(np.int64)
        lev = envelope_level(r[13] & 15, steps)
        env += n * einc
        if r[13] & 8 and not r[13] & 1:
            env %= 32
        for ch in range(3):
            p = ((r[2 * ch] | (r[2 * ch + 1] << 8)) & 0xFFF) or 1
            inc = CLOCK / (16 * p) / rate
            ph = phase[ch] + t * inc
            phase[ch] = (phase[ch] + n * inc) % 1.0
            tone = (ph % 1.0) < 0.5 if inc < 0.5 else np.ones(n, dtype=bool)
            ton = not (r[7] >> ch) & 1
            non = not (r[7] >> (ch + 3)) & 1
            gate = (tone | (not ton)) & ((noise == 1) | (not non))
            level = lev if r[8 + ch] & 16 else np.full(n, r[8 + ch] & 15)
            out[ch, a:b] = gate * dac[level]
    if dc:  # the output's coupling: a first-order high-pass at about 3.5 Hz
        out = lfilter([1, -1], [1, -0.9995], out, axis=1)
    return out.sum(axis=0) / 3


def write_wav(path, samples, rate=44100):
    import numpy as np
    peak = np.abs(samples).max() or 1
    pcm = (samples / peak * 0.9 * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def note_name(period):
    if not period:
        return '-'
    f = CLOCK / (16 * period)
    m = 69 + 12 * math.log2(f / 440)
    n = int(round(m))
    return '%s%d' % (NAMES[n % 12], n // 12 - 1)


# ---------------------------------------------------------------------------------------------------------------
# the tune as text

COMMANDS = {0x80: ('rest', 0), 0x81: ('vib-off', 0), 0x82: ('vib-on', 0), 0x83: ('vib-half', 0),
            0x84: ('slide', 2), 0x85: ('bend-down', 0), 0x86: ('bend-up', 0), 0x87: ('end', 0),
            0x88: ('vibrato', 2), 0x89: ('transpose', 1), 0x8A: ('tone', 0), 0x8B: ('noise', 0),
            0x8C: ('tone+noise', 0), 0x8D: ('flag1', 0), 0x8E: ('stop', 0), 0x8F: ('hold', 0),
            0x90: ('drum', 0), 0x91: ('drum-off', 0), 0x92: ('inline', 0), 0x93: ('dur', 1)}


def tune_bytes():
    data = open(os.path.join(ROOT, 'build', 'bank4.bin'), 'rb').read()
    return lambda a: data[a - 0xC000]


def note_of_index(i):
    """the name of note i of NoteTable ($C494): its period played at the 128K's AY clock"""
    b = tune_bytes()
    return note_name(b(0xC494 + 2 * i) | b(0xC495 + 2 * i) << 8)


def decode_pattern(addr, inline=False, dur=None):
    """([(address, text)], inline after, duration after) of one pattern from a channel state: notes as
    name:duration (the duration inline after the note, or the fixed one of command $93)"""
    b = tune_bytes()
    out = []
    a = addr
    while True:
        c = b(a)
        if c < 0x80 or c in (0x80, 0x8F):
            if inline:
                d, a2 = b(a + 1), a + 2
            else:
                d, a2 = dur, a + 1
            name = note_of_index(c) if c < 0x80 else ('rest' if c == 0x80 else 'hold')
            out.append((a, f'{name}:{d}'))
            a = a2
            continue
        if c >= 0xE0:
            out.append((a, f'ins{c - 0xE0}'))
            a += 1
            continue
        if c >= 0xB0:
            out.append((a, f'orn{c - 0xB0}'))
            a += 1
            continue
        name, n = COMMANDS.get(c, ('?%02X' % c, 0))
        ops = [b(a + 1 + k) for k in range(n)]
        if c == 0x92:
            inline = True
        if c == 0x93:
            dur, inline = ops[0], False
        if c in (0x92, 0x93):
            name = 'inline' if c == 0x92 else f'dur={ops[0]}'
            ops = []
        out.append((a, name + ('(' + ','.join(str(o) for o in ops) + ')' if ops else '')))
        a += 1 + n
        if c in (0x87, 0x8E):
            break
    return out, inline, dur


def decode_order(addr):
    b = tune_bytes()
    out, a = [], addr
    while True:
        c = b(a)
        if c < 0x80:
            out.append(f'P{c}')
            a += 1
        elif c == 0xFF:
            t = b(a + 1)
            out.append(f'T{t - 256 if t > 127 else t:+d}')
            a += 2
        elif c == 0xFE:
            out.append(f'x{b(a + 1)}')
            a += 2
        elif c == 0xFD:
            out.append('restart')
            break
        elif c == 0xFC:
            out.append('jump $%04X' % (b(a + 1) | b(a + 2) << 8))
            break
        else:
            out.append('trap')
            break
    return out


def order_items(addr):
    """the order list's items to its end: ('P', n) | ('T', t) | ('x', n) | ('end', text)"""
    b = tune_bytes()
    out, a = [], addr
    while True:
        c = b(a)
        if c < 0x80:
            out.append(('P', c)); a += 1
        elif c == 0xFF:
            t = b(a + 1); out.append(('T', t - 256 if t > 127 else t)); a += 2
        elif c == 0xFE:
            out.append(('x', b(a + 1))); a += 2
        else:
            out.append(('end', decode_order(a)[-1] if c in (0xFC, 0xFD) else 'trap')); return out


def patterns_in_order():
    """{pattern: (channel, inline at entry, duration at entry)} the first time each pattern is played"""
    b = tune_bytes()
    seen = {}
    for ch, p in zip('ABC', (0xC86A, 0xC86C, 0xC86E)):
        inline, dur = False, None
        for kind, v in order_items(b(p) | b(p + 1) << 8):
            if kind != 'P':
                continue
            a = b(0xC870 + 2 * v) | b(0xC871 + 2 * v) << 8
            if v not in seen:
                seen[v] = (ch, inline, dur)
            _, inline, dur = decode_pattern(a, inline, dur)
    return seen


def cmd_score(args):
    b = tune_bytes()
    print('speed', b(0xC869))
    for ch, p in zip('ABC', (0xC86A, 0xC86C, 0xC86E)):
        a = b(p) | b(p + 1) << 8
        print(f'order {ch} ${a:04X}:', ' '.join(decode_order(a)))
    seen = patterns_in_order()
    for n in range(16):
        a = b(0xC870 + 2 * n) | b(0xC871 + 2 * n) << 8
        ch, inline, dur = seen.get(n, ('-', False, None))
        toks, _, _ = decode_pattern(a, inline, dur)
        frames = sum(int(t.split(':')[1]) for _, t in toks if ':' in t and t.split(':')[1] != 'None')
        print(f'P{n} ${a:04X} (channel {ch}, {frames} steps):', ' '.join(t for _, t in toks))


# ---------------------------------------------------------------------------------------------------------------

def cmd_music(args):
    out, costs, _, _ = music(args.frames)
    for i, (r, e) in enumerate(out[:args.print]):
        print(i, ' '.join('%02X' % x for x in r), 'R13' if e else '')
    print('T per tick: min %d max %d mean %.0f' % (min(costs), max(costs), sum(costs) / len(costs)))
    if args.wav:
        write_wav(args.wav, render(out))


def cmd_state(args):
    _, _, snaps, m = music(args.frames, snap=True)
    print(bytes(m.mem[0xC05A:0xC0D2]).hex())


def cmd_loop(args):
    out, costs, snaps, _ = music(args.frames, snap=True)
    n = len(snaps)
    for p in range(args.min, n - 400):
        if all(snaps[i] == snaps[i + p] for i in range(n - p - 200, n - p)):
            s = n - p - 200
            while s > 0 and snaps[s - 1] == snaps[s - 1 + p]:
                s -= 1
            print(f'the state repeats every {p} ticks from tick {s}')
            return
    print('no repeat within', n)


def cmd_effect(args):
    out, costs = effect(args.name, args.frames, args.speed)
    for i, (r, e) in enumerate(out[:args.print]):
        print(i, ' '.join('%02X' % x for x in r), 'R13' if e else '', costs[i])
    if args.wav:
        write_wav(args.wav, render(out))


def summary(out):
    """frames until silent on B and C, and a description of channel B/C per frame"""
    last = 0
    for i, (r, _) in enumerate(out):
        if (r[9] & 15) or (r[10] & 15):
            last = i + 1
    return last


def cmd_table(args):
    print('| Effect | Trigger | Counter = start | Called by | Frames heard | Channel | Tone B (first, last) | Noise (first, last) | Volume (first, last) | T per frame (max) |')
    print('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |')
    for name, trig, ctr, start, caller, what in EFFECTS:
        out, costs = effect(name, 200, 0)
        n = summary(out)
        heard = out[:n] or out[:1]
        chans = set()
        for r, _ in heard:
            if (r[9] & 15) and (not r[7] & 2 or not r[7] & 16):
                chans.add('B tone' if not r[7] & 2 else 'B noise')
            if r[10] & 15 and not r[7] & 32:
                chans.add('C noise')
        tb = [r[2] | r[3] << 8 for r, _ in heard]
        nz = [r[6] for r, _ in heard]
        vol = [max(r[9] & 15, r[10] & 15) for r, _ in heard]
        print(f'| {name} ({what}) | `${trig:04X}` | `${ctr:04X}` = {start} | {caller or "no caller"} | {n} | '
              f'{", ".join(sorted(chans)) or "-"} | `${tb[0]:03X}`, `${tb[-1]:03X}` | {nz[0]}, {nz[-1]} | '
              f'{vol[0]}, {vol[-1]} | {max(costs[:max(n, 1)])} |')


def cmd_engine(args):
    speeds = [int(s) for s in args.speeds.split(',')]
    out, costs = engine(speeds, args.frames)
    per = len(out) // len(speeds)
    for k, s in enumerate(speeds):
        r = out[k * per][0]
        ep = r[11] | r[12] << 8
        print(f'speed {s}: R11 {r[11]} R12 {r[12]} R13 {r[13]:#x} vol A {r[8]:#x} mixer {r[7]:#04x} '
              f'triangle {CLOCK / (512 * ep):.1f} Hz, T {costs[k * per]}')
    if args.wav:
        write_wav(args.wav, render(out))


def cmd_costs(args):
    out, costs, _, _ = music(3000)
    print('MusicTick (music on): min %d max %d mean %.0f T' % (min(costs), max(costs), sum(costs) / len(costs)))
    for name, *_ in EFFECTS:
        o, c = effect(name, 4, 0)
        print(f'SoundFrame with {name}: {c[1]} T')
    o, c = engine([0], 4)
    print('SoundFrame, no effect (engine only):', c[1], 'T')


def cmd_wavs(args):
    os.makedirs(args.dir, exist_ok=True)
    for name, *_ in EFFECTS:
        out, _ = effect(name, 200, 0)
        n = summary(out) + 10
        write_wav(os.path.join(args.dir, f'effect-{name}.wav'), render(out[:n]))
    out, _ = engine([0, 8, 16, 24, 32, 48], 300)
    write_wav(os.path.join(args.dir, 'engine.wav'), render(out))
    out, _, _, _ = music(args.tune_frames)
    wav = os.path.join(args.dir, 'tune-title.wav')
    write_wav(wav, render(out))
    # the whole tune is 13 MB as a WAV: kept as an MP3 (lame, 128 kbit/s) like the other cases' long tunes
    import subprocess
    subprocess.run(['lame', '--quiet', '-b', '128', wav, wav[:-4] + '.mp3'], check=True)
    os.remove(wav)
    print('written', args.dir)


# ---------------------------------------------------------------------------------------------------------------
# figures

def cmd_fig_effects(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    names = [e for e in EFFECTS]
    cols = 2
    rows = (len(names) + 1) // cols
    fig, axes = plt.subplots(rows, cols, figsize=(10.5, 1.55 * rows + 0.6), dpi=100, sharex=True)
    for ax, (name, trig, ctr, start, caller, what) in zip(axes.flat, names):
        out, _ = effect(name, 140, 0)
        n = min(140, max(summary(out) + 4, 12))
        out = out[:n]
        x = range(n)
        tb = [r[2] | r[3] << 8 for r, _ in out]
        vb = [r[9] & 15 for r, _ in out]
        vc = [r[10] & 15 for r, _ in out]
        nz = [r[6] & 31 for r, _ in out]
        tone_on = [not r[7] & 2 for r, _ in out]
        noise_b = [not r[7] & 16 for r, _ in out]
        ax.step(x, vb, where='post', color='tab:blue', label='volume B')
        ax.step(x, vc, where='post', color='tab:red', label='volume C')
        ax.set_ylim(-1, 33)
        ax.step(x, nz, where='post', color='tab:gray', lw=0.8, ls='--', label='noise period')
        ax2 = ax.twinx()
        ax2.step(x, [p if t else None for p, t in zip(tb, tone_on)], where='post', color='tab:green',
                 label='tone B period')
        ax2.set_yscale('log')
        ax2.set_ylim(40, 5000)
        ax2.tick_params(labelsize=9)
        ax.tick_params(labelsize=9)
        ax.set_title(f'{name}: \\${trig:04X} sets \\${ctr:04X} = {start}' + ('' if caller else ' (no caller)'),
                     fontsize=10, loc='left')
        ax.grid(alpha=0.3)
    for ax in axes.flat[len(names):]:
        ax.axis('off')
    h1, l1 = axes.flat[0].get_legend_handles_labels()
    fig.legend(h1 + [plt.Line2D([], [], color='tab:green')], l1 + ['tone B period (right, log)'],
               loc='lower right', fontsize=10, ncol=2)
    fig.suptitle('Every bank 0 effect, register by register: SoundFrame \\$D692 after the trigger, engine at speed 0 '
                 '(tools/sound_sim.py, x = frames)', fontsize=11)
    fig.tight_layout(rect=(0, 0.02, 1, 0.97))
    fig.savefig(args.out)
    print(args.out)


def cmd_fig_engine(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import numpy as np
    speeds = list(range(0, 117, 4))  # 120 and up wrap: (120 + 8) x 2 = 256 gives R11 = 0
    freqs = []
    for s in speeds:
        out, _ = engine([s], 2)
        r = out[1][0]
        ep = r[11] | r[12] << 8
        freqs.append(CLOCK / (512 * ep))
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10.5, 3.6), dpi=100)
    a1.plot(speeds, freqs, 'o-', ms=3)
    a1.set_xlabel('|speed| (\\$75F7 through AbsA)', fontsize=10)
    a1.set_ylabel('triangle frequency, Hz', fontsize=10)
    a1.set_title('Engine pitch: R11 = -(2 x (|speed| + 8)), triangle \\$0E', fontsize=10)
    a1.grid(alpha=0.3)
    out, _ = engine([0], 8)
    samples = render(out[:8], dc=False)
    a2.plot(np.arange(len(samples)) / 44.1, samples, lw=0.8)
    a2.set_xlabel('ms', fontsize=10)
    a2.set_title('Channel A at speed 0, 8 frames: the envelope is the waveform', fontsize=10)
    a2.set_ylabel('DAC level (sum / 3)', fontsize=10)
    a2.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(args.out)
    print(args.out)


def cmd_fig_tune(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    out, costs, snaps, _ = music(args.frames, snap=True)
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 7.2), dpi=100, sharex=True, layout='constrained')
    pat_addr = []
    b = tune_bytes()
    for n in range(17):
        pat_addr.append(b(0xC870 + 2 * n) | b(0xC871 + 2 * n) << 8)
    colours = plt.cm.tab20.colors
    for ch, ax in enumerate(axes):
        xs, ys, cs = [], [], []
        for i, (r, _) in enumerate(out):
            p = ((r[2 * ch] | r[2 * ch + 1] << 8) & 0xFFF)
            v = r[8 + ch] & 15
            if not p or not v or r[7] & (1 << ch):
                continue
            f = CLOCK / (16 * p)
            xs.append(i / 50)
            ys.append(69 + 12 * math.log2(f / 440))
            cs.append(v)
        sc = ax.scatter(xs, ys, c=cs, cmap='viridis', s=3, vmin=0, vmax=15)
        # the pattern being played (from the channel record's pattern pointer)
        last = None
        for i, s in enumerate(snaps):
            if i == 0:
                continue  # the state before the first tick
            ptr = s[ch * 39 + 1] | s[ch * 39 + 2] << 8
            k = max([n for n in range(16) if pat_addr[n] <= ptr] or [0])
            if k != last:
                ax.axvline(i / 50, color='0.7', lw=0.6)
                ax.text(i / 50, ax.get_ylim()[1] if False else 100, f'P{k}', fontsize=9, va='top')
                last = k
        ax.set_ylim(20, 102)
        ax.set_ylabel(f'channel {"ABC"[ch]}\nMIDI note', fontsize=10)
        ax.grid(alpha=0.25)
        ax.tick_params(labelsize=9)
    cb = fig.colorbar(sc, ax=list(axes), shrink=0.6, pad=0.01)
    cb.set_label('volume (0-15)', fontsize=10)
    axes[-1].set_xlabel('seconds (one MusicTick a frame, 50 a second, none lost)', fontsize=10)
    fig.suptitle(f'The title tune: the notes each channel sounds, coloured by volume, with the pattern it plays '
                 f'(tools/sound_sim.py fig-tune, {args.frames} ticks)', fontsize=11)
    fig.savefig(args.out)
    print(args.out)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest='cmd', required=True)
    a = s.add_parser('music'); a.add_argument('--frames', type=int, default=3000); a.add_argument('--wav'); a.add_argument('--print', type=int, default=0)
    a = s.add_parser('effect'); a.add_argument('name'); a.add_argument('--frames', type=int, default=150); a.add_argument('--speed', type=int, default=0); a.add_argument('--wav'); a.add_argument('--print', type=int, default=40)
    a = s.add_parser('engine'); a.add_argument('--speeds', default='0,16,32'); a.add_argument('--frames', type=int, default=150); a.add_argument('--wav')
    s.add_parser('table')
    s.add_parser('score')
    a = s.add_parser('loop'); a.add_argument('--frames', type=int, default=16000); a.add_argument('--min', type=int, default=100)
    s.add_parser('costs')
    a = s.add_parser('state'); a.add_argument('--frames', type=int, required=True)
    a = s.add_parser('fig-effects'); a.add_argument('out')
    a = s.add_parser('fig-engine'); a.add_argument('out')
    a = s.add_parser('fig-tune'); a.add_argument('out'); a.add_argument('--frames', type=int, default=3000)
    a = s.add_parser('wavs'); a.add_argument('dir'); a.add_argument('--tune-frames', type=int, default=3000)
    args = p.parse_args()
    {'music': cmd_music, 'effect': cmd_effect, 'engine': cmd_engine, 'table': cmd_table, 'score': cmd_score,
     'loop': cmd_loop, 'costs': cmd_costs, 'state': cmd_state, 'fig-effects': cmd_fig_effects,
     'fig-engine': cmd_fig_engine, 'fig-tune': cmd_fig_tune, 'wavs': cmd_wavs}[args.cmd](args)


if __name__ == '__main__':
    main()
