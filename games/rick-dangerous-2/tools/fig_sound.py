#!/usr/bin/env python3
"""The sound of doc 09: the RAM 1 AY player and the 48K beeper, run in the kit's Z80 simulator from the case's build,
checked against the recordings' traces; tables, figures, an animation and the audio renders (written, never played).

    python3 tools/fig_sound.py tunes                         each tune: frames to MusicPlaying 0, notes per channel
    python3 tools/fig_sound.py effects                       the 28 AY effects: frames, period, note, peak
    python3 tools/fig_sound.py beeper [--pass-frames 2]      the 11 beeper effects: notes, pitch, T a note
    python3 tools/fig_sound.py check --work W --window F:T-F:T --at F:T
                                                             a recording's trace against the model: its tune starts,
                                                             effects and frames from --at replayed on the model, the
                                                             sound of each frame compared (start in silence or at a
                                                             tune start)
    python3 tools/fig_sound.py beeper-check --work W --window F:T-F:T --effect N
                                                             a 48K recording's OUT ($FE) edges against the model
    python3 tools/fig_sound.py fig-tune OUT.png --tune N [--frames K]   a tune as a piano roll, a panel a channel
    python3 tools/fig_sound.py fig-instruments OUT.png       instruments 0-6: the volume of one note, frame by frame
    python3 tools/fig_sound.py fig-effects OUT.png           the 28 AY effects: volume and pitch frame by frame
    python3 tools/fig_sound.py fig-beeper OUT.png            the 11 beeper effects: the notes pass by pass
    python3 tools/fig_sound.py fig-pattern OUT.png           tune 1 decoded by hand: the bytes, the notes, registers
    python3 tools/fig_sound.py anim-regs OUT.gif --work W --window F:T-F:T [--step 1]
                                                             AY registers 0-10 interrupt by interrupt from a trace
    python3 tools/fig_sound.py fig-beeper-trace OUT.png --work W --window F:T-F:T   its half periods against the beam
    python3 tools/fig_sound.py beeper-trace OUT.wav --work W --window F:T-F:T   a 48K recording's own beeper edges
    python3 tools/fig_sound.py audio DIR                     the tunes (MP3, lame -V 4) and the effects (WAV)

The 128K: build/music.bin at $C000 (RAM 1, as CopyMusic leaves it). A tune is started with MusicStartTune $CA27
(A = the tune), an effect with MusicEffect $CCC8 (A = the effect), and each frame is one call of MusicFrame $CAAF,
as MusicFrameCall $7AB6 does from the interrupt. The AY writes are WriteAyRegister's: OUT ($FFFD) the register,
OUT ($BFFD) the value. AY clock 1 773 400 Hz, 50 frames a second.

The 48K: build/game.bin at $7080; PlayBeeperStep $7B66 called once a pass with its note pointer ($7B67) set as
SelectBeeperEffect sets it. Its OUT ($FE) writes and their T-states give the speaker (bit 3, the MIC line, which
the 48K's speaker hears too). The pass is --pass-frames frames (2: c48's passes are 1.98 frames on average). CPU clock 3 500 000 Hz, 69 888 T
a frame. The simulator has no contention.
"""
import argparse
import math
import os
import re
import shutil
import subprocess
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import z80sim  # noqa: E402

AY_CLOCK = 1773400
CPU48 = 3500000
FRAME48 = 69888
STOP = 0xBFF0
NAMES = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')
# the AY's 16 volume steps as output levels (measured AY-3-8912 curve, normalised)
LEVELS = (0.0, 0.0106, 0.0150, 0.0222, 0.0320, 0.0466, 0.0665, 0.1039, 0.1237, 0.1986, 0.2803, 0.3548,
          0.4702, 0.6030, 0.7530, 1.0)
LINE = re.compile(r'^\s*\d+\+*\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):')
TUNE_NAMES = {0: 'the control menu, CONGRATULATIONS', 1: 'a signal (time bonus, cheats)', 2: 'GAME OVER',
              3: 'never started', 4: 'the tape load (silence)', 5: 'level 1', 6: 'level 2', 7: 'level 3',
              8: 'level 4', 9: 'level 5', 10: 'the Fat Guy\'s end'}
EFFECT_NAMES = {0: 'a step', 2: 'the fuse', 4: 'a shot', 5: 'a blast', 6: 'ammunition / detonators',
                7: 'a treasure', 9: 'an enemy punched', 10: 'a death, a life counted'}
BEEPER_NAMES = {0: 'a step', 1: '(no call)', 2: 'the fuse', 3: '(no call)', 4: 'a shot', 5: 'a blast',
                6: 'ammo / detonators', 7: 'a treasure', 8: '(no call)', 9: 'an enemy punched', 10: 'a death'}


def labels(name):
    out = {}
    for line in open(os.path.join(CASE, 'build', name + '.lst'), encoding='latin-1'):
        m = LINE.match(line)
        if m:
            out.setdefault(m.group(2), int(m.group(1), 16))
    return out


M = labels('music')
G = labels('game')


class Tracer:
    def __init__(self):
        self.select = 0
        self.ay = []
        self.fe = []

    def write_port(self, registers, port, value, *rest):
        if port & 0xC002 == 0xC000:
            self.select = value & 15
        elif port & 0xC002 == 0x8000:
            self.ay.append((self.select, value))
        if not port & 1:
            self.fe.append((registers[25], value))


class Machine:
    """kind 'music': RAM 1 at $C000; kind 'game': the game image at $7080"""

    def __init__(self, kind):
        mem = bytearray(0x10000)
        if kind == 'music':
            b = open(os.path.join(CASE, 'build', 'music.bin'), 'rb').read()
            mem[0xC000:0xC000 + len(b)] = b
        else:
            b = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
            mem[0x7080:0x7080 + len(b)] = b
        mem[STOP] = 0x76
        z80sim.need_skoolkit()
        from skoolkit.simulator import Simulator
        self.sim = Simulator(mem, {'SP': 0xBFE0})
        self.mem = self.sim.memory
        self.tr = Tracer()
        self.sim.set_tracer(self.tr)

    def call(self, address, a=0):
        reg = self.sim.registers
        reg[0] = a
        reg[12] = 0xBFDE
        self.mem[0xBFDE], self.mem[0xBFDF] = STOP & 255, STOP >> 8
        self.tr.ay, self.tr.fe = [], []
        t0 = reg[25]
        self.sim.run(address, STOP)
        return reg[25] - t0


class Ay:
    """the AY a frame: regs[f] = registers 0-13 after frame f's MusicFrame; writes[f]; costs[f]"""

    def __init__(self):
        self.m = Machine('music')
        self.r = [0] * 14
        self.r[7] = 0x3F
        self.regs, self.writes, self.costs, self.voices, self.left = [], [], [], [], []

    def apply(self):
        for reg, v in self.m.tr.ay:
            if reg < 14:
                self.r[reg] = v

    def start_tune(self, n):
        self.m.call(M['MusicStartTune'], n)
        self.apply()
        return list(self.m.tr.ay)

    def effect(self, n):
        self.m.call(M['MusicEffect'], n)
        self.apply()
        return list(self.m.tr.ay)

    def frame(self):
        t = self.m.call(M['MusicFrame'])
        self.apply()
        self.regs.append(tuple(self.r))
        self.writes.append(list(self.m.tr.ay))
        self.costs.append(t)
        self.voices.append(tuple(self.m.mem[M['VoiceA'] + 18 * v + 5] for v in range(3)))
        self.left.append(tuple(self.m.mem[M['ChannelA'] + 21 * c + 0x0C] for c in range(3)))

    def playing(self):
        return self.m.mem[M['MusicPlaying']]

    def free(self):
        return self.m.mem[M['MixerShadow']] & 0x3F == 0x3F


def tune_run(n, limit=20000):
    ay = Ay()
    ay.start_tune(n)
    ay.frame()
    while ay.playing() and len(ay.regs) < limit:
        ay.frame()
    return ay


def quiet_ay():
    """the player as the game leaves it after the load: tune 4 (silence) started and over, the voices zeroed"""
    ay = Ay()
    ay.start_tune(4)
    while True:
        ay.frame()
        if not ay.playing():
            break
    ay.regs, ay.writes, ay.costs, ay.voices, ay.left = [], [], [], [], []
    return ay


def effect_run(n, limit=600):
    ay = quiet_ay()
    ay.start_writes = ay.effect(n)
    ay.frame()
    while not ay.free() and len(ay.regs) < limit:
        ay.frame()
    return ay


def period(r, ch):
    return r[2 * ch] | (r[2 * ch + 1] & 15) << 8


def period_midi(p):
    if not p:
        return None
    return 69 + 12 * math.log2(AY_CLOCK / (16 * p) / 440)


def note_name(m):
    n = int(round(m))
    return '%s%d' % (NAMES[n % 12], n // 12 - 1)


def tone_on(r, ch):
    return not (r[7] >> ch) & 1


def noise_on(r, ch):
    return not (r[7] >> (ch + 3)) & 1


def music_byte(addr):
    return open(os.path.join(CASE, 'build', 'music.bin'), 'rb').read()[addr - 0xC000]


def music_bytes(addr, n):
    return open(os.path.join(CASE, 'build', 'music.bin'), 'rb').read()[addr - 0xC000:addr - 0xC000 + n]


# ---------------------------------------------------------------------------------------------------------------
# the beeper

def beeper_notes(n):
    b = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    t = 0x7AF2 - 0x7080
    a = b[t + 2 * n] | b[t + 2 * n + 1] << 8
    out = []
    while b[a - 0x7080] != 0xFF:
        out.append(b[a - 0x7080])
        a += 1
    return a, out


def beeper_run(n, pass_frames):
    """effect n: [(T, bit)] edges, one PlayBeeperStep call a pass, and per pass (note, T of the call)"""
    m = Machine('game')
    b = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    t = 0x7AF2 - 0x7080
    a = b[t + 2 * n] | b[t + 2 * n + 1] << 8
    m.mem[0x7B67], m.mem[0x7B68] = a & 255, a >> 8
    edges, rows = [], []
    k = 0
    while True:
        p = m.mem[0x7B67] | m.mem[0x7B68] << 8
        note = m.mem[p]
        cost = m.call(G['PlayBeeperStep'])
        if note == 0xFF:
            break
        base = k * pass_frames * FRAME48
        t0 = m.tr.fe[0][0] if m.tr.fe else 0
        for tt, v in m.tr.fe:
            edges.append((base + tt - t0, (v >> 3) & 1))
        edges.append((base + cost, 0))
        rows.append((note, cost, len(m.tr.fe)))
        k += 1
    return edges, rows


def beeper_hz(c):
    """a note's pitch: the high half is 32 C + 17 T (C turns of the 32 T loop, the LD A / OUT / LD B,C, a last DJNZ
    of 8), the low half 32 C + 27 T (and the JP back): a period of 64 C + 44 T"""
    return CPU48 / (64 * c + 44)


# ---------------------------------------------------------------------------------------------------------------
# the recordings

def trace_of(work, window):
    a = argparse.Namespace(trace=None, work=work, window=window, unreal=None, max_cycles=None)
    return K.load_trace(a)


def trace_ay(tr):
    """[(frame, t, register, value)] from WriteAyRegister's OUT (C),A in a trace (RAM 1 code)"""
    pc = M['WriteAyRegister'] + 9
    out = []
    for i in tr.instructions:
        if i.pc == pc:
            out.append((i.frame, i.t, i.de & 0xFF, i.af >> 8))
    return out


def trace_fe(tr):
    pcs = {G['PlayBeeperStep'] + 0x11, G['PlayBeeperStep'] + 0x1C}
    out = []
    for i in tr.instructions:
        if i.pc in pcs:
            out.append((i.frame, i.t, (i.af >> 8) >> 3 & 1))
    return out


def regs_by_frame(writes, f0, f1, start=None):
    """registers 0-13 after each frame's writes, frames f0..f1-1"""
    r = list(start or ([0] * 7 + [0x3F] + [0] * 6))
    out = []
    i = 0
    writes = sorted(writes)
    for f in range(f0, f1):
        while i < len(writes) and writes[i][0] <= f:
            r[writes[i][2]] = writes[i][3]
            i += 1
        out.append(tuple(r))
    return out


# ---------------------------------------------------------------------------------------------------------------
# rendering

def envelope_level(shape, s):
    """the AY envelope's volume step (0-15) at step s since register 13 was written"""
    import numpy as np
    s = np.asarray(s, dtype=np.int64)
    c16, c32 = s % 16, s % 32
    first = s < 16
    if shape == 8:
        return 15 - c16
    if shape == 12:
        return c16
    if shape == 10:
        return np.where(c32 < 16, 15 - c32, c32 - 16)
    if shape == 14:
        return np.where(c32 < 16, c32, 31 - c32)
    if shape == 11:
        return np.where(first, 15 - c16, 15)
    if shape == 13:
        return np.where(first, c16, 15)
    if shape in (4, 5, 6, 7, 15):
        return np.where(first, c16, 0)
    return np.where(first, 15 - c16, 0)


def render_ay(regs, restarts=(), rate=44100):
    """frames of registers 0-13 -> mono samples: tone squares, the 17-bit noise, fixed volumes or (volume bit 4) the
    envelope, restarted at the frames in `restarts` (register 13 written)"""
    import numpy as np
    per = rate / 50
    epos = 0.0
    out = np.zeros(int(len(regs) * per))
    lfsr = np.zeros(1 << 17, dtype=np.uint8)
    st = 1
    for i in range(len(lfsr)):
        lfsr[i] = st & 1
        st = (st >> 1) | (((st ^ (st >> 3)) & 1) << 16)
    phase = [0.0] * 3
    npos = 0.0
    for f, r in enumerate(regs):
        a, b = int(f * per), int((f + 1) * per)
        n = b - a
        t = np.arange(n)
        ninc = AY_CLOCK / (16 * ((r[6] & 31) or 1)) / rate
        noise = lfsr[((npos + t * ninc).astype(np.int64)) % len(lfsr)]
        npos = (npos + n * ninc) % len(lfsr)
        if f in restarts:
            epos = 0.0
        einc = AY_CLOCK / (16 * ((r[11] | r[12] << 8) or 1)) / rate
        env = np.array(LEVELS)[envelope_level(r[13] & 15, (epos + t * einc).astype(np.int64))]
        epos += n * einc
        for ch in range(3):
            p = period(r, ch) or 1
            inc = AY_CLOCK / (16 * p) / rate
            ph = phase[ch] + t * inc
            phase[ch] = (phase[ch] + n * inc) % 1.0
            tone = (ph % 1.0) < 0.5 if inc < 0.5 else np.ones(n, dtype=bool)
            gate = (tone | (not tone_on(r, ch))) & ((noise == 1) | (not noise_on(r, ch)))
            vol = env if r[8 + ch] & 16 else LEVELS[r[8 + ch] & 15]
            out[a:b] += gate * vol
    out -= np.convolve(out, np.ones(2205) / 2205, mode='same')
    return out / 3


def render_edges(edges, rate=44100, tail=0.05):
    import numpy as np
    ts = np.array([e[0] for e in edges], dtype=np.float64)
    vs = np.array([e[1] for e in edges], dtype=np.float64)
    end = ts[-1] + tail * CPU48
    seg = np.append(ts, end)
    cum = np.concatenate([[0.0], np.cumsum(vs * np.diff(seg))])
    n = int((end - ts[0]) / CPU48 * rate)
    st = ts[0] + np.arange(n + 1) * CPU48 / rate
    out = np.diff(np.interp(st, seg, cum)) / (CPU48 / rate)
    out -= np.convolve(out, np.ones(441) / 441, mode='same')
    return out


def write_audio(path, samples, rate=44100):
    import numpy as np
    peak = np.abs(samples).max() or 1
    pcm = (samples / peak * 0.9 * 32767).astype('<i2')
    wav = path if path.endswith('.wav') else path[:-4] + '.wav'
    with wave.open(wav, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())
    if path.endswith('.mp3'):
        if not shutil.which('lame'):
            sys.exit('no lame for ' + path)
        subprocess.run(['lame', '--quiet', '-V', '4', wav, path], check=True)
        os.remove(wav)
    return path


# ---------------------------------------------------------------------------------------------------------------
# tables

def cmd_tunes(a):
    for n in range(11):
        ay = tune_run(n)
        starts = [0, 0, 0]
        prev = (0, 0, 0)
        for v in ay.left:
            for c in range(3):
                if v[c] > prev[c]:
                    starts[c] += 1
            prev = v
        cost = max(ay.costs)
        print('tune %2d: %5d frames (%.1f s)  notes %s  max %d T a frame  mean %d T  %s' % (
            n, len(ay.regs), len(ay.regs) / 50, starts, cost, sum(ay.costs) // len(ay.costs), TUNE_NAMES[n]))


def cmd_effects(a):
    for n in range(28):
        ay = effect_run(n)
        rec = music_bytes(M['Effects'] + 13 * n, 13)
        p = rec[10] | rec[11] << 8
        vols = [max(r[8:11]) for r in ay.regs]
        m = period_midi(p)
        print('effect %2d: %4d frames  period %4d %-5s  peak %2d  flags %d  %s' % (
            n, len(ay.regs), p, note_name(m) if m and m > 0 else '-', max(vols), rec[9], EFFECT_NAMES.get(n, '')))


def cmd_beeper(a):
    for n in range(11):
        edges, rows = beeper_run(n, a.pass_frames)
        _, notes = beeper_notes(n)
        print('beeper %2d: %2d notes  %s  T a note %s  %s' % (
            n, len(rows), ' '.join('%d' % beeper_hz(c) for c in notes), sorted({r[1] for r in rows}),
            BEEPER_NAMES[n]))


def trace_events(tr, at):
    """the trace's calls into the player after the moment at: [(kind, frame, t, A, registers after it)], kind
    'tune' (MusicStartTune), 'effect' (MusicEffect) or 'frame' (MusicFrame)"""
    kinds = {M['MusicStartTune']: 'tune', M['MusicEffect']: 'effect', M['MusicFrame']: 'frame'}
    pc_write = M['WriteAyRegister'] + 9
    r = [0] * 7 + [0x3F] + [0] * 6
    out = []
    for i in tr.instructions:
        if (i.frame, i.t) < at:
            continue
        if i.pc in kinds:
            out.append([kinds[i.pc], i.frame, i.t, i.af >> 8, None, 0])
        elif i.pc == pc_write:
            r[i.de & 0xFF] = i.af >> 8
            if out:
                out[-1][5] += 1
        if out:
            out[-1][4] = tuple(r)
    return out


def ram_at(work, frame, t, offset, n):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)
    r = session.call('time_travel', {'action': 'memory_at', 'space': 'ram', 'frame': frame, 'tinframe': t,
                                     'offset': offset, 'length': n}, ok=False)
    return bytes.fromhex((r.structured or {})['hex'])


def audible(r):
    """what one hears: the mixer's tone/noise bits and, for a channel with volume, its volume and period"""
    out = [r[7] & 0x3F]
    for c in range(3):
        v = r[8 + c] & 15
        out += [v, period(r, c) if v and tone_on(r, c) else 0, r[6] & 31 if v and noise_on(r, c) else 0]
    return tuple(out)


def cmd_check(a):
    """replay the trace's tune starts, effects and frames on the model; compare what each frame sounds"""
    tr = trace_of(a.work, a.window)
    if a.at == 'quiet':
        # the first MusicFrame call that wrote nothing: all voices free, the AY silent, no tune
        events = trace_events(tr, (0, 0))
        k = next(i for i, e in enumerate(events) if i and e[0] == 'frame' and not e[5]
                 and events[i - 1][0] == 'frame' and not events[i - 1][5])
        a.at = '%d:%d' % (events[k][1], events[k][2])
    f, _, t = a.at.partition(':')
    events = trace_events(tr, (int(f), int(t or 0)))
    ay = Ay()
    if a.state:
        # RAM 1 as the recording holds it at the start (TTD memory_at, physical RAM: page 1 at $4000)
        ram1 = ram_at(a.work, int(f), int(t or 0), 0x4000, 0x1080)
        ay.m.mem[0xC000:0xD080] = ram1
    same = total = 0
    first = None
    counts = {'tune': 0, 'effect': 0, 'frame': 0}
    for kind, fr, tt, acc, r, _ in events:
        counts[kind] += 1
        if kind == 'tune':
            ay.start_tune(acc)
        elif kind == 'effect':
            ay.effect(acc)
        else:
            ay.frame()
            total += 1
            if audible(r) == audible(ay.regs[-1]):
                same += 1
            elif first is None:
                first = (fr, tt, audible(r), audible(ay.regs[-1]))
    frames = sorted({e[1] for e in events if e[0] == 'frame'})
    print('from %s: %d tune starts, %d effect calls (A = %s), %d MusicFrame calls (frames %d-%d): %d of the frames '
          'sound the same in the trace and the model' % (
              a.at, counts['tune'], counts['effect'], sorted({e[3] for e in events if e[0] == 'effect'}),
              total, frames[0], frames[-1], same))
    if first:
        print('first difference at %d:%d:\n  trace %s\n  model %s' % first)


def cmd_beeper_check(a):
    tr = trace_of(a.work, a.window)
    fe = trace_fe(tr)
    edges, rows = beeper_run(a.effect, 4)
    calls = [(i.frame, i.t) for i in tr.instructions if i.pc == G['PlayBeeperStep']]
    print('%d PlayBeeperStep calls, %d OUT ($FE) writes in the trace; the model: %d notes, %d writes' % (
        len(calls), len(fe), len(rows), sum(r[2] for r in rows)))
    gaps = [(calls[i + 1][0] - calls[i][0]) * FRAME48 + calls[i + 1][1] - calls[i][1] for i in range(len(calls) - 1)]
    if gaps:
        print('a pass: %s T (%.2f frames on average)' % (sorted(set(gaps))[:8], sum(gaps) / len(gaps) / FRAME48))
    # the half periods of the trace's square waves, in T, against the model's
    def halves(seq):
        out = []
        for i in range(1, len(seq)):
            d = seq[i][0] - seq[i - 1][0]
            if 0 < d < 20000:
                out.append(d)
        return out
    abs_t = [(f * FRAME48 + t, b) for f, t, b in fe]
    ht, hm = halves(abs_t), halves([(t, b) for t, b in edges if True])
    print('half periods: trace %d-%d T, model %d-%d T' % (min(ht), max(ht), min(hm), max(hm)) if ht and hm else '')


# ---------------------------------------------------------------------------------------------------------------
# figures

def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 10, 'axes.titlesize': 11, 'figure.dpi': 100, 'text.parse_math': False,
                         'axes.facecolor': '#fbfbf8', 'savefig.facecolor': 'white'})
    return plt


def save(fig, out):
    fig.savefig(out, dpi=100)
    print(out)


def cmd_fig_tune(a):
    plt = plt_setup()
    ay = tune_run(a.tune)
    regs = ay.regs[:a.frames] if a.frames else ay.regs
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 6.6), sharex=True)
    cols = ('#c0392b', '#2471a3', '#1e8449')
    for ch in range(3):
        ax = axes[ch]
        xs, ys, vs = [], [], []
        for f, r in enumerate(regs):
            v = r[8 + ch] & 15
            if v and tone_on(r, ch):
                m = period_midi(period(r, ch))
                if m:
                    xs.append(f)
                    ys.append(m)
                    vs.append(v)
        ax.scatter(xs, ys, c=[(0, 0, 0, 0.15 + 0.85 * v / 15) for v in vs], s=4, marker='s', linewidths=0)
        if ys:
            lo, hi = int(min(ys)) - 2, int(max(ys)) + 2
            ax.set_ylim(lo, hi)
            ticks = [m for m in range(lo, hi + 1) if m % 12 in (0, 4, 7)]
            ax.set_yticks(ticks)
            ax.set_yticklabels([note_name(m) for m in ticks])
        ax.set_ylabel('channel %s' % 'ABC'[ch], color=cols[ch])
        ax.grid(axis='y', alpha=0.3)
    axes[-1].set_xlabel('frame (50 a second) after MusicStartTune')
    fig.suptitle('Tune %d (%s): the notes the AY plays, the darker the louder; %d frames, %.1f s' % (
        a.tune, TUNE_NAMES[a.tune], len(ay.regs), len(ay.regs) / 50))
    fig.tight_layout()
    save(fig, a.out)


def note_curve(i, sustain=24, frames=70):
    ay = Ay()
    m = ay.m
    ins = M['Instruments'] + 10 * i
    # a small driver at $BF00: LD IX,VoiceA; LD IY,ins; LD HL,$01AB; LD C,sustain; CALL StartVoice; HALT-stop
    code = [0xDD, 0x21, M['VoiceA'] & 255, M['VoiceA'] >> 8, 0xFD, 0x21, ins & 255, ins >> 8,
            0x21, 0xAB, 0x01, 0x0E, sustain, 0xCD, M['StartVoice'] & 255, M['StartVoice'] >> 8, 0xC9]
    m.mem[0xBF00:0xBF00 + len(code)] = bytes(code)
    m.mem[M['VoiceA'] + 5] = 0          # from silence (the image's byte is leftover source text)
    m.call(0xBF00)
    vols, pers = [], []
    for _ in range(frames):
        ay.frame()
        vols.append(m.mem[M['VoiceA'] + 5])
        pers.append(period(ay.regs[-1], 0))
    return vols, pers


def cmd_fig_instruments(a):
    plt = plt_setup()
    fig, axes = plt.subplots(2, 4, figsize=(10.5, 5.4), sharex=True)
    for i in range(8):
        ax = axes[i // 4][i % 4]
        if i == 7:
            ax.axis('off')
            ax.text(0, 1, 'One note of 24 frames\n(dotted) from silence,\nstarted by StartVoice\nand run by '
                    'MusicFrame:\nattack to the peak,\ndecay to the sustain,\nhold to the end of the\nnote, '
                    'release to 0.\nAY volume = value / 8.\n\nRed, right axis: the\npitch swing (period\n'
                    'offset).', va='top', fontsize=10, transform=ax.transAxes)
            continue
        vols, pers = note_curve(i)
        rec = music_bytes(M['Instruments'] + 10 * i, 10)
        ax.plot(range(1, len(vols) + 1), vols, color='#2c3e50', drawstyle='steps-post')
        ax.axvline(24, color='#999', lw=0.8, ls=':')
        ax.set_ylim(0, 130)
        ax.set_title('instrument %d' % i)
        ax2 = ax.twinx()
        ax2.plot(range(1, len(pers) + 1), [p - 0x1AB for p in pers], color='#c0392b', lw=0.8)
        ax2.set_ylim(-8, 8)
        ax2.tick_params(labelsize=9)
        ax.text(0.97, 0.95, 'A %d D %d S %d R %d\npeak %d' % (rec[0], (rec[1] ^ 128) - 128, rec[2],
                                                               (rec[3] ^ 128) - 128, rec[4]),
                transform=ax.transAxes, ha='right', va='top', fontsize=9)
        if i % 4 == 0:
            ax.set_ylabel('volume (0-127)')
        if i >= 4:
            ax.set_xlabel('frame')
    fig.suptitle('Instruments $C4C0: the software envelope of one note, from the real code')
    fig.tight_layout()
    save(fig, a.out)


def cmd_fig_effects(a):
    plt = plt_setup()
    fig, axes = plt.subplots(4, 7, figsize=(10.5, 7.2))
    for n in range(28):
        ax = axes[n // 7][n % 7]
        ay = effect_run(n, limit=120)
        regs = ay.regs
        v = [max(r[8:11]) for r in regs]
        ch = [max(range(3), key=lambda c: r[8 + c]) for r in regs]
        p = [period(r, c) for r, c in zip(regs, ch)]
        x = range(1, len(v) + 1)
        ax.fill_between(x, v, step='post', color='#aab7b8')
        ax.set_ylim(0, 16)
        ax.set_xlim(0, max(10, len(v)))
        ax2 = ax.twinx()
        rec = music_bytes(M['Effects'] + 13 * n, 13)
        noise = rec[9] & 2
        ax2.plot(x, p, color='#8e44ad' if noise else '#c0392b', lw=1)
        ax2.tick_params(labelsize=8)
        ax.tick_params(labelsize=8)
        title = '%d' % n
        if n in EFFECT_NAMES:
            title += ' ' + EFFECT_NAMES[n].split(',')[0].split('/')[0].strip()
        ax.set_title(title, fontsize=10)
    fig.suptitle('The 28 AY effects $C506: grey the volume (0-15), red the tone period, purple a noise '
                 'effect\'s period; x the frames')
    fig.tight_layout()
    save(fig, a.out)


def cmd_fig_beeper(a):
    plt = plt_setup()
    fig, axes = plt.subplots(2, 6, figsize=(10.5, 4.6))
    for n in range(12):
        ax = axes[n // 6][n % 6]
        if n == 11:
            ax.axis('off')
            ax.text(0, 1, 'One byte a pass:\nthe half period C.\nEach note is\n$600 loop turns,\n'
                    'about 49 000 T,\n0.7 of a frame.\nThe pitch:\n3.5 MHz / (64 C + 44).',
                    va='top', fontsize=10, transform=ax.transAxes)
            continue
        _, notes = beeper_notes(n)
        hz = [beeper_hz(c) for c in notes]
        ax.bar(range(1, len(hz) + 1), hz, color='#7f8c8d', width=0.8)
        ax.set_yscale('log')
        ax.set_ylim(150, 60000)
        ax.set_title('%d %s' % (n, BEEPER_NAMES[n]), fontsize=10)
        from matplotlib.ticker import MaxNLocator
        ax.xaxis.set_major_locator(MaxNLocator(integer=True))
        ax.tick_params(labelsize=8)
        if n % 6 == 0:
            ax.set_ylabel('Hz')
        ax.set_xlabel('pass', fontsize=9)
    fig.suptitle('The 11 beeper effects $7B08 (48K): the pitch of each pass\'s note')
    fig.tight_layout()
    save(fig, a.out)


def cmd_fig_pattern(a):
    """tune 1 by hand: the tune table entry, the three order lists, the three patterns, the voices' volumes"""
    from PIL import Image, ImageDraw
    W = 1050
    f, fs, fb = K.font(13), K.font(12), K.font(16)
    img = Image.new('RGB', (W, 640), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((14, 10), 'Tune 1, "a signal", decoded by hand from RAM 1', fill=K.TEXT, font=fb)
    tt = M['TuneTable'] + 6
    tb = music_bytes(tt, 6)
    y = 42
    d.text((14, y), 'TuneTable $%04X + 6 x 1 = $%04X:  %s' % (M['TuneTable'], tt, ' '.join('%02X' % v for v in tb)),
           fill=K.TEXT, font=f)
    ol = [tb[0] | tb[1] << 8, tb[2] | tb[3] << 8, tb[4] | tb[5] << 8]
    d.text((14, y + 18), 'three words: the order lists of channels A, B, C at $%04X, $%04X, $%04X' % tuple(ol),
           fill=K.DIM, font=fs)
    y += 50
    cols = ((192, 57, 43), (36, 113, 163), (30, 132, 73))
    pats = []
    for c in range(3):
        o = music_bytes(ol[c], 2)
        pn = o[0]
        lo, hi = music_byte(M['PatternAddrLow'] + pn), music_byte(M['PatternAddrHigh'] + pn)
        pa = lo | hi << 8
        pats.append(pa)
        d.text((14, y), 'channel %s: order list $%04X = %02X %02X: pattern %d, then $FF the end.  PatternAddrLow/High[%d] '
               '= $%02X/$%02X: the pattern at $%04X' % ('ABC'[c], ol[c], o[0], o[1], pn, pn, lo, hi, pa),
               fill=cols[c], font=f)
        y += 20
    y += 12
    for c in range(3):
        pa = pats[c]
        b = music_bytes(pa, 8)
        d.text((14, y), 'pattern at $%04X:' % pa, fill=cols[c], font=f)
        x = 170
        cells = []
        i = 0
        while i < len(b):
            v = b[i]
            if v == 0xFF:
                cells.append(('FF', 'the end', ''))
                break
            if v >= 0x80:
                cells.append(('%02X' % v, 'instrument %d' % (v & 7), ''))
                i += 1
                continue
            per = music_bytes(M['Periods'] + 2 * (v + 12), 2)
            cells.append(('%02X %02X' % (v, b[i + 1]), '%s, %d frames' % (note_name(v + 34), b[i + 1]),
                          'index %d: period %d' % (v + 12, per[0] | per[1] << 8)))
            i += 2
        for hx, t1, t2 in cells:
            d.text((x, y), hx, fill=K.TEXT, font=f)
            d.text((x, y + 18), t1, fill=K.DIM, font=fs)
            d.text((x, y + 34), t2, fill=K.DIM, font=fs)
            x += 165 if t2 else 115
        y += 64
    d.text((14, y), 'A note byte n plays index n + 12 (+ the transpose, 0 here) of Periods $C672: MIDI n + 34. '
           'The next byte is its frames.', fill=K.TEXT, font=f)
    d.text((14, y + 18), 'Instrument 1 ($C4CA): attack 64, decay -4, sustain 0, release -4, peak 54: up to 54 '
           'in one frame, then 4 down a frame.', fill=K.TEXT, font=f)
    y += 46
    # the voices' volumes frame by frame (model)
    ay = tune_run(1)
    n = len(ay.regs)
    x0, h = 70, 22
    d.text((14, y), 'The registers the model writes, frame by frame (volume 8-10 as bars, the note under it):',
           fill=K.TEXT, font=f)
    y += 22
    sc = min(12, (W - x0 - 20) // n)
    for c in range(3):
        d.text((14, y + c * (h + 22) + 4), 'reg %d' % (8 + c), fill=cols[c], font=fs)
        last = None
        for k, r in enumerate(ay.regs):
            v = r[8 + c] & 15
            xa = x0 + k * sc
            d.rectangle((xa, y + c * (h + 22) + h - v * h // 15, xa + sc - 2, y + c * (h + 22) + h), fill=cols[c])
            m = period_midi(period(r, c))
            nm = note_name(m) if m and v else ''
            if nm != last and nm:
                d.text((xa, y + c * (h + 22) + h + 2), nm, fill=K.DIM, font=fs)
            last = nm
    y += 3 * (h + 22) + 4
    d.text((x0, y), 'frame 1 .. %d (%.2f s): three notes on three channels at once, the E major chord three times '
           '(E-G#-B in three voicings)' % (n, n / 50), fill=K.DIM, font=fs)
    img = img.crop((0, 0, W, y + 24))
    img.save(a.out)
    print(a.out, img.size)


def cmd_anim_regs(a):
    """AY registers 0-10 after each interrupt, from a trace; one picture a frame"""
    from PIL import Image, ImageDraw
    tr = trace_of(a.work, a.window)
    w = trace_ay(tr)
    f0, f1 = tr.from_frame, tr.to_frame
    rec = regs_by_frame(w, f0, f1)
    per_frame = {}
    for fr, t, reg, v in w:
        per_frame.setdefault(fr, []).append((t, reg, v))
    calls = {}
    for kind, fr, t, acc, _, _ in trace_events(tr, (0, 0)):
        if kind == 'effect':
            calls.setdefault(fr, []).append('MusicEffect A=%d (%s)' % (acc, EFFECT_NAMES.get(acc, '?')))
        elif kind == 'tune':
            calls.setdefault(fr, []).append('MusicStartTune A=%d' % acc)
    W = 1050
    f, fs, fb = K.font(13), K.font(12), K.font(15)
    cols = ((192, 57, 43), (36, 113, 163), (30, 132, 73))
    pics = []
    hist = []
    for k in range(0, len(rec), a.step):
        fr = f0 + k
        r = rec[k]
        hist.append(r)
        img = Image.new('RGB', (W, 470), K.BACKGROUND)
        d = ImageDraw.Draw(img)
        d.text((14, 8), a.title or 'AY registers after the interrupt', fill=K.TEXT, font=fb)
        d.text((14, 30), 'frame %d: %d writes by WriteAyRegister this frame' % (fr, len(per_frame.get(fr, []))),
               fill=K.DIM, font=f)
        d.text((360, 200), 'calls this frame:', fill=K.DIM, font=fs)
        for j, c in enumerate(calls.get(fr, [])[:3]):
            d.text((360, 218 + 17 * j), c, fill=(250, 220, 120), font=f)
        # register table
        y = 56
        for reg in range(14):
            v = r[reg]
            changed = k > 0 and rec[k - 1][reg] != v
            col = (250, 220, 120) if changed else K.TEXT
            name = ['tone A fine', 'tone A coarse', 'tone B fine', 'tone B coarse', 'tone C fine', 'tone C coarse',
                    'noise period', 'mixer', 'volume A', 'volume B', 'volume C', 'env. fine', 'env. coarse',
                    'env. shape'][reg]
            extra = ''
            if reg == 7:
                extra = ' tone %s noise %s' % (''.join('ABC'[c] if tone_on(r, c) else '-' for c in range(3)),
                                               ''.join('ABC'[c] if noise_on(r, c) else '-' for c in range(3)))
            d.text((14, y), 'R%-2d %-13s $%02X%s' % (reg, name, v, extra), fill=col, font=fs)
            y += 17
        # channel panels
        for c in range(3):
            x = 360 + c * 225
            p = period(r, c)
            v = r[8 + c] & 15
            m = period_midi(p)
            d.text((x, 56), 'channel %s' % 'ABC'[c], fill=cols[c], font=fb)
            d.text((x, 78), 'period %d' % p, fill=K.TEXT, font=f)
            d.text((x, 96), '%s%s' % (note_name(m) if m else '-', '' if tone_on(r, c) else ' (tone off)'),
                   fill=K.TEXT, font=f)
            d.text((x, 114), 'noise on' if noise_on(r, c) else '', fill=(142, 68, 173), font=f)
            d.rectangle((x, 136, x + 200, 156), outline=K.DIM)
            d.rectangle((x, 136, x + v * 200 // 15, 156), fill=cols[c])
            d.text((x, 160), 'volume %d' % v, fill=K.DIM, font=fs)
        # history strip
        y0 = 300
        d.text((360, y0 - 22), 'the last 64 frames: the volume of each channel', fill=K.DIM, font=fs)
        for j, hr in enumerate(hist[-64:]):
            for c in range(3):
                v = hr[8 + c] & 15
                xa = 360 + j * 10
                yb = y0 + c * 52 + 44
                d.rectangle((xa, yb - v * 3, xa + 8, yb), fill=cols[c])
        pics.append(img)
    K.save_gif(a.out, pics, [20 * a.step] * (len(pics) - 1) + [2000])
    print(a.out, len(pics), 'pictures')


# ---------------------------------------------------------------------------------------------------------------
# audio

def cmd_audio(a):
    os.makedirs(a.dir, exist_ok=True)
    for n in range(11):
        if n == 4:
            continue
        ay = tune_run(n)
        ext = 'mp3' if len(ay.regs) > 100 else 'wav'
        print(write_audio(os.path.join(a.dir, 'tune-%02d.%s' % (n, ext)), render_ay(ay.regs + [ay.regs[-1]] * 10)))
    for n in range(28):
        ay = effect_run(n)
        restarts = {0} if any(reg == 13 for reg, _ in ay.start_writes) else set()
        quiet = list(ay.regs[-1])
        quiet[8:11] = [0, 0, 0]
        print(write_audio(os.path.join(a.dir, 'ay-effect-%02d.wav' % n),
                          render_ay(ay.regs + [tuple(quiet)] * 5, restarts)))
    for n in range(11):
        edges, _ = beeper_run(n, a.pass_frames)
        print(write_audio(os.path.join(a.dir, 'beeper-effect-%02d.wav' % n), render_edges(edges)))


def cmd_fig_beeper_trace(a):
    """each half period of a 48K recording's beeper notes against the beam: contended in the display's 192 lines"""
    plt = plt_setup()
    tr = trace_of(a.work, a.window)
    pcs = {G['PlayBeeperStep'] + 0x11, G['PlayBeeperStep'] + 0x1C}
    pts = []
    c = None
    last = None
    for i in tr.instructions:
        if i.pc == G['PlayBeeperStep'] + 0x0B:
            c = i.af >> 8
            last = None
        elif i.pc in pcs and c:
            tt = i.frame * FRAME48 + i.t
            if last is not None and tt - last < 32 * c + 400:
                pts.append((i.t, (tt - last) / (32 * c + 22), c))
            last = tt
    fig, ax = plt.subplots(figsize=(10.5, 4.2))
    sc = ax.scatter([p[0] for p in pts], [p[1] for p in pts], c=[p[2] for p in pts], s=3, cmap='viridis')
    ax.axvspan(14336, 14336 + 192 * 224, color='#f5b7b1', alpha=0.35, lw=0)
    ax.axhline(1.0, color='#c0392b', lw=1)
    ax.text(14600, 1.62, 'the 192 display lines: the ULA reads the screen, a fetch from $4000-$7FFF waits',
            fontsize=10)
    ax.set_xlim(0, FRAME48)
    ax.set_ylim(0.9, 1.7)
    ax.set_xlabel('T in the frame when the half period ends')
    ax.set_ylabel('half period / the model\'s')
    fig.colorbar(sc, ax=ax, label='C (the note byte)')
    ax.set_title(a.title or 'Beeper half periods, %s' % a.window)
    fig.tight_layout()
    save(fig, a.out)
    print(len(pts), 'half periods')


def cmd_beeper_trace(a):
    """a 48K recording's own speaker edges (OUT ($FE) in PlayBeeperStep, real T-states with contention) as a WAV"""
    tr = trace_of(a.work, a.window)
    edges = [(f * FRAME48 + t, b) for f, t, b in trace_fe(tr)]
    print(write_audio(a.out, render_edges(edges)), len(edges), 'edges')


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('tunes').set_defaults(fn=cmd_tunes)
    sub.add_parser('effects').set_defaults(fn=cmd_effects)
    p = sub.add_parser('beeper')
    p.add_argument('--pass-frames', type=int, default=2)
    p.set_defaults(fn=cmd_beeper)
    p = sub.add_parser('check')
    p.add_argument('--work', required=True)
    p.add_argument('--window', required=True)
    p.add_argument('--at', required=True)
    p.add_argument('--state', action='store_true', help='start the model from the recording\'s RAM 1')
    p.set_defaults(fn=cmd_check)
    p = sub.add_parser('beeper-check')
    p.add_argument('--work', required=True)
    p.add_argument('--window', required=True)
    p.add_argument('--effect', type=int, required=True)
    p.set_defaults(fn=cmd_beeper_check)
    p = sub.add_parser('fig-tune')
    p.add_argument('out')
    p.add_argument('--tune', type=int, required=True)
    p.add_argument('--frames', type=int, default=0)
    p.set_defaults(fn=cmd_fig_tune)
    for name, fn in (('fig-instruments', cmd_fig_instruments), ('fig-effects', cmd_fig_effects),
                     ('fig-beeper', cmd_fig_beeper), ('fig-pattern', cmd_fig_pattern)):
        p = sub.add_parser(name)
        p.add_argument('out')
        p.set_defaults(fn=fn)
    p = sub.add_parser('anim-regs')
    p.add_argument('out')
    p.add_argument('--work', required=True)
    p.add_argument('--window', required=True)
    p.add_argument('--step', type=int, default=1)
    p.add_argument('--title', default='')
    p.set_defaults(fn=cmd_anim_regs)
    p = sub.add_parser('fig-beeper-trace')
    p.add_argument('out')
    p.add_argument('--work', required=True)
    p.add_argument('--window', required=True)
    p.add_argument('--title', default='')
    p.set_defaults(fn=cmd_fig_beeper_trace)
    p = sub.add_parser('beeper-trace')
    p.add_argument('out')
    p.add_argument('--work', required=True)
    p.add_argument('--window', required=True)
    p.set_defaults(fn=cmd_beeper_trace)
    p = sub.add_parser('audio')
    p.add_argument('dir')
    p.add_argument('--pass-frames', type=int, default=2)
    p.set_defaults(fn=cmd_audio)
    a = ap.parse_args()
    if getattr(a, 'out', None):
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    a.fn(a)


if __name__ == '__main__':
    main()
