#!/usr/bin/env python3
"""Enduro Racer's sound for doc 9: the game's own sound code run in SkoolKit's Z80 simulator from the case's build
(build/game.bin at $5B00, the 48K ROM under it for the ROM bytes the engine and the crash read), then written as
audio and charts. Nothing is played.

    python3 tools/fig_sound.py audio OUTDIR        every sound as WAV (MP3 by lame -V 4 when longer than 5 s), and
                                                   DATA/sound.json (the numbers of doc 9)
    python3 tools/fig_sound.py fig-tunes OUT.png   the two tunes as a piano roll (both AY channels)
    python3 tools/fig_sound.py fig-engine OUT.png  the engine's note against SPEED on the beeper and on the AY
    python3 tools/fig_sound.py fig-beeper OUT.png  the beeper's edges against T-states: an engine burst at two
                                                   speeds, the crash noise, the countdown beep, a name entry blip
    python3 tools/fig_sound.py fig-ay OUT.png      the AY registers a frame over a fall and a bounce on the 128K
    python3 tools/fig_sound.py fig-cost OUT.png    T-states: the interrupt's sound part a frame, and the main
                                                   loop's blocking beeps
    python3 tools/fig_sound.py fig-format OUT.png  the tune stream and the channel record, byte by byte
  DATA is work/docs/erC/sound (--data DIR).

The interrupt's sound part is IntSound $6476 (to IntExit $6516; $650F is the engine's call). It is called here as
the handler calls it, once a frame. The effects that run in the main loop (CrashSound $AC88, BeepTone $AB95,
NameEntrySound $8AF0, AyEffectTick $ACA5) are called as the loop calls them, once a pass; a pass is taken as 8
frames, the mean of c1's play (WALKTHROUGH 1). T-states are the simulator's: uncontended. The sound code at
$6430-$690E is in contended memory, so the real interrupt is longer while the beam is in the picture (doc 9, 9.4
gives the traced cost). AY clock 1 773 400 Hz, 70 908 T a 128K frame; 69 888 T a 48K frame at 3 500 000 Hz.
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
SENTINEL = 0xFFF8
PASS = 8                      # frames a pass (c1's play mean, WALKTHROUGH 1)
DATA = os.path.join(CASE, 'work', 'docs', 'erC', 'sound')
ROM = os.path.join(os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'), 'data', 'rom', '48.rom')

# the game's addresses (src/game/game.ann)
INT_SOUND, INT_ENGINE_CALL, INT_EXIT = 0x6476, 0x650F, 0x6516
ENGINE, CRASH, CRASH_D, BEEP, NAME_SOUND, AY_TICK, PLAY_EFFECT = 0x6851, 0xAC88, 0xAC8A, 0xAB95, 0x8AF0, 0xACA5, 0xA179
BEEPER, SPEED, JUMP_HI, SKID = 0x7C2F, 0x7C33, 0x5CEA, 0x645F
TUNE_MARK, TUNE_REQ, EFFECT_TIME, EFFECT_STEP, TUNE_HELD, TUNE_PLAYING = 0x6460, 0x6461, 0x6462, 0x6463, 0x643A, 0x643B
CHAN_A, CHAN_B = 0x6817, 0x6828
RESTART_PATH = 0x6612            # ChannelCommands' $C9 branch (XOR A)
NOTE_TABLE = 0x66AA
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


class Ports:
    def __init__(self):
        self.reg = 0
        self.regs = [0] * 16
        self.regs[7] = 0x3F
        self.writes = []
        self.beeper = []          # (T, speaker bit)

    def write_port(self, registers, port, value, *a):
        if port & 0xC002 == 0xC000:
            self.reg = value & 15
        elif port & 0xC002 == 0x8000:
            self.regs[self.reg] = value
            self.writes.append((self.reg, value))
        if port & 1 == 0:
            self.beeper.append((registers[su.T], (value >> 4) & 1))

    def read_port(self, registers, port):
        return 0xFF


class Machine:
    def __init__(self, model='48K'):
        mem = [0] * 0x10000
        rom = open(ROM, 'rb').read()
        mem[0:0x4000] = rom
        game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
        mem[0x5B00:0x5B00 + len(game)] = game
        mem[BEEPER] = 0xFF if model == '48K' else 0
        mem[JUMP_HI] = 0                  # on the ground (the image holds an old $12 there)
        mem[EFFECT_TIME], mem[EFFECT_STEP] = 0, 15   # as StartRace leaves them ($0F00)
        mem[SKID] = 0
        self.ports = Ports()
        self.sim = Simulator(mem, {'SP': SENTINEL - 2}, config={'fast_ldir': False, 'fast_djnz': False})
        self.sim.set_tracer(self.ports)
        self.mem = self.sim.memory
        self.watch, self.hits = set(), []

    def call(self, addr, stop=SENTINEL, regs=None, limit=4_000_000):
        r = self.sim.registers
        for k, v in (regs or {}).items():
            r[getattr(su, k)] = v
        sp = SENTINEL - 2
        self.mem[sp], self.mem[sp + 1] = SENTINEL & 255, SENTINEL >> 8
        r[su.SP] = sp
        r[su.PC] = addr
        t0 = r[su.T]
        ops, mem = self.sim.opcodes, self.mem
        watch = self.watch
        while r[su.PC] != stop and r[su.PC] != SENTINEL:
            if watch and r[su.PC] in watch:
                self.hits.append((r[su.PC], r[su.IXh] << 8 | r[su.IXl]))
            ops[mem[r[su.PC]]]()
            if r[su.T] - t0 > limit:
                raise SystemExit(f'call {addr:04X} did not return')
        return r[su.T] - t0

    def t(self):
        return self.sim.registers[su.T]

    def set_speed(self, kmh):
        v = int(round(kmh * 256))
        self.mem[SPEED], self.mem[SPEED + 1] = v & 255, v >> 8


# ---- running the code -------------------------------------------------------------------------------------------

def interrupt(m, engine=True):
    """one interrupt's sound part (IntSound to IntExit, or to the engine's call); its T-states"""
    return m.call(INT_SOUND, INT_EXIT if engine else INT_ENGINE_CALL)


def start_tune(m, tune):
    m.mem[TUNE_REQ], m.mem[TUNE_PLAYING], m.mem[TUNE_MARK] = tune, 0, 1


def run_tune(tune):
    """the tune on the 128K, the engine left out, until both channels have read their $C9 (restart) once; the AY
    registers a frame and the frame of each channel's restart"""
    m = Machine('128K')
    start_tune(m, tune)
    frames, loops = [], {}
    for f in range(20000):
        m.hits = []
        m.watch = {RESTART_PATH}
        interrupt(m, engine=False)
        frames.append(list(m.ports.regs[:14]))
        for pc, ix in m.hits:
            name = 'A' if ix == CHAN_A else 'B'
            loops.setdefault(name, f)
        if len(loops) == 2:
            break
    return frames, loops


def notes_of(frames):
    """(frame, AY channel, period) for every tone on, from the registers a frame"""
    out = []
    for f, r in enumerate(frames):
        for ch in range(3):
            if not (r[7] >> ch) & 1:
                out.append((f, ch, r[2 * ch] | (r[2 * ch + 1] & 15) << 8, r[8 + ch]))
    return out


def period_name(p, clock=AY_CLOCK):
    import math
    if p <= 0:
        return '-'
    f = clock / (16.0 * p)
    midi = 69 + 12 * math.log2(f / 440.0)
    n = int(round(midi))
    return f'{NAMES[n % 12]}{n // 12 - 1}', f, midi


def engine48(kmh, air=False):
    """one EngineSound call on the 48K at a speed: the edges (T from the call) and its T-states"""
    m = Machine('48K')
    m.set_speed(kmh)
    m.mem[JUMP_HI] = 1 if air else 0
    m.mem[ENGINE + 1] = 0xFF          # the toggle: this call plays
    m.ports.beeper = []
    t0 = m.t()
    t = m.call(ENGINE, regs={'L': 0})
    return [(tt - t0, b) for tt, b in m.ports.beeper], t


def engine_folded(kmh):
    a = kmh
    if a >= 60:
        a -= 60
        if a >= 70:
            a -= 60
    return a


def engine128_period(kmh):
    m = Machine('128K')
    m.set_speed(kmh)
    m.mem[ENGINE + 1] = 0xFF
    m.call(ENGINE)
    r = m.ports.regs
    return r[4] | (r[5] & 15) << 8


def throttle_profile(passes):
    """SPEED (8.8) a pass with THROTTLE held from 0 (RaceLoop's Throttle, $A9DC; no lean, no bounce)"""
    hl, out = 0, []
    for _ in range(passes):
        h = hl >> 8
        if h < 0x14:
            hl += ((hl + 0x100) & 0xFFFF) >> 2
        elif h < 0xA0:
            hl += 0x220
        else:
            hl += (0xC800 - hl) >> 4
        out.append(hl)
    return out


# ---- renderers --------------------------------------------------------------------------------------------------

def lfsr_sequence():
    import numpy as np
    out, lfsr = bytearray(131071), 1
    for k in range(131071):
        fb = (lfsr ^ (lfsr >> 3)) & 1
        lfsr = (lfsr >> 1) | (fb << 16)
        out[k] = lfsr & 1
    return np.frombuffer(bytes(out), dtype=np.uint8).astype(bool)


def render_ay(frames, frame_t=FRAME128, cpu=CPU128):
    """AY registers a frame (lists of 14) to 16-bit mono samples; no envelope (the game never uses it)"""
    import numpy as np
    seq = lfsr_sequence()
    out, phase, noise_pos, n_total = [], [0.0, 0.0, 0.0], 0.0, 0
    dur = frame_t / cpu
    for i, regs in enumerate(frames):
        n = int(round((i + 1) * dur * RATE)) - n_total
        n_total += n
        t = np.arange(n) / RATE
        mix = regs[7]
        noise_rate = AY_CLOCK / (16.0 * max(regs[6] & 31, 1))
        noise = seq[((noise_pos + t * noise_rate).astype(np.int64)) % len(seq)]
        noise_pos += n / RATE * noise_rate
        total = np.zeros(n)
        for ch in range(3):
            per = max(regs[2 * ch] | ((regs[2 * ch + 1] & 15) << 8), 1)
            f = AY_CLOCK / (16.0 * per)
            ph = phase[ch] + t * f
            phase[ch] = (phase[ch] + n / RATE * f) % 1.0
            tone = (ph % 1.0) < 0.5 if f < RATE / 2 else np.ones(n, bool)
            gate = np.ones(n, bool)
            if not (mix >> ch) & 1:
                gate &= tone
            if not (mix >> (ch + 3)) & 1:
                gate &= noise
            if (mix >> ch) & 1 and (mix >> (ch + 3)) & 1:
                gate = np.zeros(n, bool)
            total += gate * LEVELS[regs[8 + ch] & 15]
        out.append(total / 3.0)
    s = np.concatenate(out) if out else np.zeros(0)
    s = s - s.mean() if len(s) else s
    return (np.clip(s * 1.6, -1, 1) * 32000).astype(np.int16)


def render_beeper(edges, total_t, cpu=CPU48):
    """edges (T, bit) over total_t T-states to samples (4 x oversampled, averaged)"""
    import numpy as np
    over = 4
    n = int(total_t / cpu * RATE * over)
    ts = np.arange(n) * (cpu / (RATE * over))
    if edges:
        et = np.array([e[0] for e in edges], dtype=float)
        eb = np.array([e[1] for e in edges], dtype=float)
        idx = np.searchsorted(et, ts, side='right') - 1
        lev = np.where(idx >= 0, eb[np.clip(idx, 0, None)], 0.0)
    else:
        lev = np.zeros(n)
    lev = lev[: len(lev) // over * over].reshape(-1, over).mean(axis=1)
    lev = lev - lev.mean() if len(lev) else lev
    return (np.clip(lev * 1.2, -1, 1) * 26000).astype(np.int16)


def write_wav(path, samples):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(samples.tobytes())


def write_audio(base, samples):
    wav = base + '.wav'
    write_wav(wav, samples)
    if len(samples) > 5.0 * RATE:
        subprocess.run(['lame', '--quiet', '-V', '4', wav, base + '.mp3'], check=True)
        os.remove(wav)
        return base + '.mp3'
    return wav


# ---- scenarios --------------------------------------------------------------------------------------------------

def scenario_engine48(profile):
    """the 48K engine over a speed profile (SPEED a pass): the interrupt every frame, the burst every second one"""
    m = Machine('48K')
    m.mem[TUNE_REQ] = 1
    m.mem[TUNE_MARK] = 1
    edges, t_frames = [], []
    base = m.t()
    frame = 0
    for kmh in profile:
        for _ in range(PASS):
            m.set_speed(kmh)
            start = base + frame * FRAME48
            m.sim.registers[su.T] = start
            m.ports.beeper = []
            t = interrupt(m)
            t_frames.append(t)
            edges += [(tt - base, b) for tt, b in m.ports.beeper]
            frame += 1
    return edges, frame * FRAME48, t_frames


def scenario_engine128(profile):
    m = Machine('128K')
    m.mem[TUNE_REQ] = 1
    m.mem[TUNE_MARK] = 1
    frames, t_frames = [], []
    for kmh in profile:
        for _ in range(PASS):
            m.set_speed(kmh)
            t_frames.append(interrupt(m))
            regs = list(m.ports.regs[:14])
            frames.append(regs)
    return frames, t_frames


def engine_only128(frames):
    """the tune's channels muted: only channel C (the engine)"""
    out = []
    for r in frames:
        r = list(r)
        r[7] |= 0x03
        r[8] = r[9] = 0
        out.append(r)
    return out


def scenario_effect128(kind, passes=20):
    """PlayEffect(kind) on the 128K during tune 1 at 120 km/h, AyEffectTick once a pass: AY registers a frame"""
    m = Machine('128K')
    start_tune(m, 1)
    m.set_speed(120)
    frames = []
    for f in range(16):                      # the tune running first
        interrupt(m)
        frames.append(list(m.ports.regs[:14]))
    m.call(PLAY_EFFECT, regs={'A': kind})
    for p in range(passes):
        for k in range(PASS):
            if k == 0 and p > 0:
                m.call(AY_TICK)
            if k == 0 and p == 0:
                m.call(AY_TICK)
            interrupt(m)
            frames.append(list(m.ports.regs[:14]))
    return frames


def scenario_skid128(level=8, kmh=120, frames_n=100):
    m = Machine('128K')
    start_tune(m, 1)
    m.set_speed(kmh)
    m.mem[SKID] = level
    frames = []
    for f in range(frames_n):
        interrupt(m)
        frames.append(list(m.ports.regs[:14]))
    return frames


def blocking(addr, regs=None, mem=None, model='48K'):
    """a main-loop beeper routine's edges and T-states"""
    m = Machine(model)
    for a, v in (mem or {}).items():
        m.mem[a] = v
    m.ports.beeper = []
    t0 = m.t()
    t = m.call(addr, regs=regs)
    return [(tt - t0, b) for tt, b in m.ports.beeper], t


def countdown_edges():
    """the countdown's four beeps, a pass (8 frames) between Countdown values: 3, 2, 1 ($40E0) and GO ($0070)"""
    edges, t = [], 0
    for c in range(15, -1, -1):            # Countdown after RaceLoop's DEC: 15 .. 0
        if c & 3 == 2:
            de = 0x40E0 if c >= 4 else 0x0070
            e, dt = blocking(BEEP, regs={'D': de >> 8, 'E': de & 255})
            edges += [(t + x, b) for x, b in e]
        t += PASS * FRAME48
    return edges, t


def extended_edges():
    """EXTENDED PLAY: ExtendedTime 32 down a pass; a beep ($6080: 96 edges, 128 turns) at 30, 26, 22"""
    edges, t, at = [], 0, []
    for a in range(31, 0x13, -1):           # below 20 no beep: the window ends there
        if a & 2 and not a & 1:
            e, dt = blocking(BEEP, regs={'D': 0x60, 'E': 0x80})
            edges += [(t + x, b) for x, b in e]
            at.append(a)
        t += PASS * FRAME48
    return edges, t, at


def name_entry_edges(steps=12):
    """NameEntrySound once a step after a pick (NameSound = $28), each call as the entry loop makes it"""
    m = Machine('48K')
    m.mem[NAME_SOUND + 1] = 0x28
    edges, ts = [], []
    t0 = m.t()
    for k in range(steps):
        m.ports.beeper = []
        ts.append(m.call(NAME_SOUND))
        edges += [(tt - t0, b) for tt, b in m.ports.beeper]
    return edges, m.t() - t0, ts


# ---- commands ---------------------------------------------------------------------------------------------------

def cmd_audio(outdir):
    os.makedirs(outdir, exist_ok=True)
    os.makedirs(DATA, exist_ok=True)
    info = {}
    # the tunes
    for tune in (1, 2):
        frames, loops = run_tune(tune)
        n = max(loops.values())
        path = write_audio(os.path.join(outdir, f'tune-{tune}'), render_ay(frames[:n]))
        info[f'tune{tune}'] = {'frames': n, 'loops': loops, 'seconds': round(n * FRAME128 / CPU128, 2),
                               'file': os.path.basename(path)}
        json.dump(frames[:n], open(os.path.join(DATA, f'tune-{tune}.json'), 'w'))
        print('tune', tune, info[f'tune{tune}'])
    # the engine: THROTTLE held from 0 for 110 passes, both machines
    prof = [v / 256 for v in throttle_profile(110)]
    edges, total, tf48 = scenario_engine48(prof)
    path = write_audio(os.path.join(outdir, 'engine-48k'), render_beeper(edges, total))
    frames, tf128 = scenario_engine128(prof)
    path2 = write_audio(os.path.join(outdir, 'engine-128k'), render_ay(engine_only128(frames)))
    path3 = write_audio(os.path.join(outdir, 'race-128k'), render_ay(frames))
    info['engine'] = {'passes': len(prof), 'frames': len(prof) * PASS, 'file48': os.path.basename(path),
                      'file128': os.path.basename(path2), 'race128': os.path.basename(path3),
                      't48_max': max(tf48), 't48_min': min(tf48), 't128_max': max(tf128), 't128_min': min(tf128),
                      'profile_kmh': [round(v, 2) for v in prof]}
    # the engine's burst and the 128K period by speed
    table = []
    for kmh in range(0, 200):
        e, t = engine48(kmh)
        gaps = [e[i + 1][0] - e[i][0] for i in range(len(e) - 1)]
        table.append({'kmh': kmh, 'folded': engine_folded(kmh), 't48': t, 'edges': len(e),
                      'gap_mean': sum(gaps) / len(gaps), 'period128': engine128_period(kmh)})
    info['engine_table'] = table
    # the effects
    e, t = blocking(CRASH, regs={'L': 0})
    info['crash'] = {'edges': len(e), 't': t, 'file': os.path.basename(
        write_audio(os.path.join(outdir, 'crash-48k'), render_beeper(e, t + 20000)))}
    e, t = blocking(CRASH_D, regs={'D': 0xC0, 'L': 0})
    info['ramp_noise'] = {'edges': len(e), 't': t}
    e, t = blocking(BEEP, regs={'D': 0x40, 'E': 0xE0})
    info['beep321'] = {'edges': len(e), 't': t}
    e, t = blocking(BEEP, regs={'D': 0x00, 'E': 0x70})
    info['beepGO'] = {'edges': len(e), 't': t}
    e, t = blocking(BEEP, regs={'D': 0x60, 'E': 0x80})
    info['beepExt'] = {'edges': len(e), 't': t}
    e, total = countdown_edges()
    info['countdown'] = {'file': os.path.basename(write_audio(os.path.join(outdir, 'countdown'),
                                                              render_beeper(e, total)))}
    e, total, at = extended_edges()
    info['extended'] = {'at': at, 'file': os.path.basename(write_audio(os.path.join(outdir, 'extended-play'),
                                                                       render_beeper(e, total)))}
    e, total, ts = name_entry_edges()
    info['name_entry'] = {'t': ts, 'file': os.path.basename(write_audio(os.path.join(outdir, 'name-entry'),
                                                                        render_beeper(e, total)))}
    for kind, name in ((1, 'fall'), (2, 'bounce')):
        fr = scenario_effect128(kind)
        json.dump(fr, open(os.path.join(DATA, f'effect-{name}.json'), 'w'))
        info[f'ay_{name}'] = {'file': os.path.basename(write_audio(os.path.join(outdir, f'ay-{name}'),
                                                                   render_ay(fr)))}
    fr = scenario_skid128()
    info['skid'] = {'file': os.path.basename(write_audio(os.path.join(outdir, 'ay-skid'), render_ay(fr))),
                    'regs': fr[-1]}
    # the interrupt's cost with a tune, 48K and 128K, over a tune's loop at 120 km/h
    for model in ('48K', '128K'):
        m = Machine(model)
        start_tune(m, 1)
        m.set_speed(120)
        ts = [interrupt(m) for _ in range(info['tune1']['frames'])]
        ts_no = []
        m2 = Machine(model)
        start_tune(m2, 1)
        m2.set_speed(120)
        ts_no = [interrupt(m2, engine=False) for _ in range(info['tune1']['frames'])]
        info[f'cost{model}'] = {'max': max(ts), 'min': min(ts), 'mean': round(sum(ts) / len(ts)),
                                'no_engine_max': max(ts_no), 'no_engine_mean': round(sum(ts_no) / len(ts_no))}
    json.dump(info, open(os.path.join(DATA, 'sound.json'), 'w'), indent=1)
    for k, v in info.items():
        if k not in ('engine_table',):
            print(k, {a: b for a, b in v.items() if a != 'profile_kmh'} if isinstance(v, dict) else v)


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'axes.titlesize': 12, 'axes.labelsize': 11, 'legend.fontsize': 10,
                         'xtick.labelsize': 10, 'ytick.labelsize': 10})
    return plt


def cmd_fig_tunes(out):
    import math
    plt = plt_setup()
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 7.2), dpi=100)
    for ax, tune in zip(axes, (1, 2)):
        frames = json.load(open(os.path.join(DATA, f'tune-{tune}.json')))
        for ch, colour, label in ((1, '#1f77b4', 'AY B: stream A (Tune%dA)' % tune),
                                  (0, '#d62728', 'AY A: stream B (Tune%dB)' % tune)):
            xs, ys = [], []
            run = None
            for f, r in enumerate(frames + [[0] * 7 + [0x3F] + [0] * 6]):
                on = not (r[7] >> ch) & 1
                p = r[2 * ch] | (r[2 * ch + 1] & 15) << 8
                key = (on, p)
                if run and run[1] != key:
                    if run[1][0]:
                        midi = 69 + 12 * math.log2(AY_CLOCK / (16.0 * run[1][1]) / 440.0)
                        ax.plot([run[0] / 50, f / 50], [midi, midi], color=colour, lw=4, solid_capstyle='butt',
                                label=label if label not in [h.get_label() for h in ax.lines] else None)
                    run = None
                if run is None:
                    run = [f, key]
        ax.set_xlabel('seconds from the tune\'s start (50 interrupts a second)')
        ax.set_ylabel('note')
        ticks = list(range(36, 85, 4))
        ax.set_yticks(ticks)
        ax.set_yticklabels([f'{NAMES[t % 12]}{t // 12 - 1}' for t in ticks])
        ax.grid(alpha=0.3)
        ax.set_title(f'Tune {tune} ({"stages 1, 3, 5" if tune == 1 else "stages 2 and 4"}): '
                     f'{len(frames)} interrupts to the loop, then it starts again')
        ax.legend(loc='upper right')
    fig.suptitle('The two in-game tunes: each AY channel\'s note over time, from the game\'s own player (128K)')
    fig.tight_layout()
    fig.savefig(out)


def cmd_fig_engine(out):
    import math
    plt = plt_setup()
    info = json.load(open(os.path.join(DATA, 'sound.json')))
    tab = info['engine_table']
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.6), dpi=100)
    k = [r['kmh'] for r in tab]
    f48 = [CPU48 / (2 * r['gap_mean']) for r in tab]
    f128 = [AY_CLOCK / (16.0 * r['period128']) for r in tab]
    axes[0].plot(k, f48, color='#9467bd')
    axes[0].set_title('48K: the burst\'s edge rate (11 edges, every 2nd frame)')
    axes[0].set_ylabel('tone of the burst, Hz (mean gap)')
    axes[1].plot(k, f128, color='#1f77b4')
    axes[1].set_title('128K: AY channel C\'s tone')
    axes[1].set_ylabel('Hz')
    for ax in axes:
        ax.set_xlabel('SPEED km/h ($7C34)')
        for g in (60, 130):
            ax.axvline(g, color='grey', ls='--', lw=1)
        ax.text(30, ax.get_ylim()[1] * 0.97, 'gear 1', ha='center', va='top')
        ax.text(95, ax.get_ylim()[1] * 0.97, 'gear 2', ha='center', va='top')
        ax.text(165, ax.get_ylim()[1] * 0.97, 'gear 3', ha='center', va='top')
        ax.grid(alpha=0.3)
    fig.suptitle('The engine note against the speed: one table, folded at 60 and 130 km/h into three "gears"')
    fig.tight_layout()
    fig.savefig(out)


def cmd_fig_beeper(out):
    plt = plt_setup()
    fig, axes = plt.subplots(4, 1, figsize=(10.5, 7.6), dpi=100)
    cases = []
    e, t = engine48(20)
    cases.append(('EngineSound at 20 km/h (gear 1): 11 edges, %d T' % t, e, t))
    e, t = engine48(199)
    cases.append(('EngineSound at 199 km/h (gear 3): 11 edges, %d T' % t, e, t))
    e, t = blocking(CRASH, regs={'L': 0})
    cases.append(('CrashSound: 248 OUTs of a ROM bit, %d T (%.1f frames, the main loop held)' % (t, t / FRAME48),
                  e, t))
    e, t = blocking(BEEP, regs={'D': 0x40, 'E': 0xE0})
    cases.append(('BeepTone 3-2-1 (D 64, E 224): %d T' % t, e, t))
    for ax, (title, e, t) in zip(axes, cases):
        xs, ys = [0], [0]
        for tt, b in e:
            xs += [tt, tt]
            ys += [ys[-1], b]
        xs.append(t)
        ys.append(ys[-1])
        ax.plot([x / 1000 for x in xs], ys, color='#333333', lw=0.8)
        ax.set_ylim(-0.2, 1.2)
        ax.set_yticks([0, 1])
        ax.set_yticklabels(['0', 'bit 4'])
        ax.set_title(title, loc='left')
        ax.set_xlim(0, t / 1000)
    axes[-1].set_xlabel('thousands of T-states from the call (3.5 MHz: 3 500 T a millisecond)')
    fig.suptitle('The beeper\'s speaker bit (port $FE bit 4) against T-states, from the game\'s code in a simulator')
    fig.tight_layout()
    fig.savefig(out)


def cmd_fig_ay(out):
    plt = plt_setup()
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 6.4), dpi=100, sharex=True)
    for ax, name in zip(axes, ('fall', 'bounce')):
        fr = json.load(open(os.path.join(DATA, f'effect-{name}.json')))
        x = [i for i in range(len(fr))]
        for ch, colour, lab in ((0, '#d62728', 'volume A'), (1, '#1f77b4', 'volume B'), (2, '#2ca02c', 'volume C')):
            ax.step(x, [(r[8 + ch] & 15) + 0.18 * (ch - 1) for r in fr], where='post', color=colour, label=lab,
                    lw=1.6)
        noise = [15.5 if (r[7] & 0x38) != 0x38 else None for r in fr]
        ax.plot(x, noise, color='black', lw=6, solid_capstyle='butt', label='noise on (R7 bits 3-5 clear)')
        ax.axvline(16, color='grey', ls='--')
        ax.text(16.5, 2, 'PlayEffect(%d)' % (1 if name == 'fall' else 2), fontsize=10)
        ax.set_ylim(0, 16.5)
        ax.set_ylabel('AY volume')
        ax.set_title('%s: PlayEffect %d, then AyEffectTick once a pass (8 frames)' % (
            'A fall' if name == 'fall' else 'A bounce or a landing', 1 if name == 'fall' else 2), loc='left')
        ax.legend(loc='lower left', ncol=4)
        ax.grid(alpha=0.3)
    axes[-1].set_xlabel('frames (interrupts) from the tune\'s start; tune 1 at 120 km/h before the effect '
                        '(the three volumes drawn a little apart)')
    fig.suptitle('The 128K\'s noise effect: the AY volumes a frame, from the game\'s code in a simulator')
    fig.tight_layout()
    fig.savefig(out)


def cmd_fig_cost(out):
    plt = plt_setup()
    info = json.load(open(os.path.join(DATA, 'sound.json')))
    tab = info['engine_table']
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.6), dpi=100)
    axes[0].plot([r['kmh'] for r in tab], [r['t48'] for r in tab], color='#9467bd', label='EngineSound burst (48K)')
    axes[0].axhline(FRAME48, color='grey', ls=':', lw=1)
    axes[0].set_xlabel('SPEED km/h')
    axes[0].set_ylabel('T-states of one call')
    axes[0].set_title('The 48K burst, every second interrupt')
    axes[0].grid(alpha=0.3)
    bars = [('interrupt sound part\n48K, mean', info['cost48K']['mean']),
            ('interrupt sound part\n128K, mean', info['cost128K']['mean']),
            ('CrashSound\n(main loop)', info['crash']['t']),
            ('beep 3-2-1\n(main loop)', info['beep321']['t']),
            ('beep GO\n(main loop)', info['beepGO']['t']),
            ('EXTENDED PLAY\nbeep (main loop)', info['beepExt']['t'])]
    axes[1].barh([b[0] for b in bars], [b[1] for b in bars], color=['#9467bd', '#1f77b4', '#8c564b', '#7f7f7f',
                                                                   '#7f7f7f', '#7f7f7f'])
    for i, (_, v) in enumerate(bars):
        axes[1].text(v, i, ' %d T (%.2f frames)' % (v, v / FRAME48), va='center', fontsize=10)
    axes[1].set_xlim(0, max(b[1] for b in bars) * 1.75)
    axes[1].set_xlabel('T-states (uncontended)')
    axes[1].set_title('What each sound costs')
    axes[1].invert_yaxis()
    fig.suptitle('The cost of sound: the 48K pays with CPU time, the main loop\'s beeps stop the game')
    fig.tight_layout()
    fig.savefig(out)


def box_sheet(rows, title, out, width=1050, note=None):
    """a byte-by-byte data sheet: rows of (label, [(bytes, top text, bottom text, colour)]); a field is as wide as
    its text or 44 px a byte, the fields wrap onto a second line when the row is full"""
    from PIL import Image, ImageDraw
    import kitlib
    ft = kitlib.font(18)
    fl = kitlib.font(15)
    fs = kitlib.font(13)
    left, bh, gap = 230, 50, 14
    layout, y = [], 56
    for label, fields in rows:
        x, line_y = left, y
        placed = []
        for nbytes, top, bottom, colour in fields:
            w = max(44 * nbytes, int(max(fs.getlength(top), fs.getlength(bottom))) + 12)
            if x + w > width - 10:
                x, line_y = left, line_y + bh + 6
            placed.append((x, line_y, w, top, bottom, colour))
            x += w
        layout.append((label, y, placed))
        y = line_y + bh + gap
    h = y + (40 if note else 10)
    img = Image.new('RGB', (width, h), 'white')
    d = ImageDraw.Draw(img)
    d.text((12, 14), title, fill='black', font=ft)
    for label, ly, placed in layout:
        d.text((12, ly + 14), label, fill='black', font=fl)
        for x, yy, w, top, bottom, colour in placed:
            d.rectangle([x, yy, x + w - 3, yy + bh], fill=colour, outline='black')
            d.text((x + 5, yy + 6), top, fill='black', font=fs)
            d.text((x + 5, yy + 27), bottom, fill='#333333', font=fs)
    if note:
        d.text((12, h - 32), note, fill='#333333', font=fs)
    img.save(out)


def cmd_fig_format(out):
    rows = [
        ('A note: 2 bytes', [(1, 'LEN', '1-199 interrupts', '#c6dbef'),
                             (1, 'NOTE', 'hi nibble: octave, lo: 0 rest, 1-11 NoteTable', '#fdd0a2')]),
        ('Commands: one byte', [(1, '$C9', 'restart', '#e5e5e5'), (1, '$CA', 'mark (TuneMark)', '#e5e5e5'),
                                (2, '$FE n', 'repeat n times', '#d9f0d3'), (1, '$FD', 'repeat end', '#d9f0d3'),
                                (3, '$FC lo hi', 'call a phrase', '#fde0ef'), (1, '$FB', 'return', '#fde0ef'),
                                (2, '$C8-$FA k', 'k AY pairs (unused)', '#ffffff')]),
        ('Channel record: 17 bytes', [(1, '+0', 'count', '#c6dbef'), (2, '+1 +2', 'stream', '#c6dbef'),
                                      (1, '+3', 'transpose', '#fdd0a2'), (2, '+4 +5', 'restart', '#e5e5e5'),
                                      (1, '+6', 'depth', '#d9f0d3'), (6, '+7 .. +12', '2 repeats: count, address',
                                                                     '#d9f0d3'),
                                      (1, '+13', 'AY reg', '#ffffff'), (1, '+14', 'mixer bit', '#ffffff'),
                                      (2, '+15 +16', 'return', '#fde0ef')]),
        ('ChannelA $6817', [(1, '00', '', '#ffffff'), (2, '00 00', '', '#ffffff'), (1, '20', '2 halvings', '#fdd0a2'),
                            (2, '01 67', 'Tune1A', '#ffffff'), (1, '00', '', '#ffffff'),
                            (6, '00 00 00 00 00 00', '', '#ffffff'), (1, '02', 'tone B', '#ffffff'),
                            (1, '02', 'bit 1', '#ffffff'), (2, '00 00', '', '#ffffff')]),
        ('ChannelB $6828', [(1, '00', '', '#ffffff'), (2, '00 00', '', '#ffffff'), (1, '30', '3 halvings', '#fdd0a2'),
                            (2, '90 67', 'Tune1B', '#ffffff'), (1, '00', '', '#ffffff'),
                            (6, '00 00 00 00 00 00', '', '#ffffff'), (1, '00', 'tone A', '#ffffff'),
                            (1, '01', 'bit 0', '#ffffff'), (2, '00 00', '', '#ffffff')]),
    ]
    box_sheet(rows, 'The tune stream (PlayChannel $6588) and the channel record, byte by byte', out,
              note='The image\'s bytes: IntSound writes +0, +1/+2, +4/+5 and +6 at a tune\'s start; '
                   '+3, +13 and +14 are fixed.')


def main():
    global DATA
    args = sys.argv[1:]
    if '--data' in args:
        i = args.index('--data')
        DATA = args[i + 1]
        del args[i:i + 2]
    cmd = args[0]
    {'audio': cmd_audio, 'fig-tunes': cmd_fig_tunes, 'fig-engine': cmd_fig_engine, 'fig-beeper': cmd_fig_beeper,
     'fig-ay': cmd_fig_ay, 'fig-cost': cmd_fig_cost, 'fig-format': cmd_fig_format}[cmd](*args[1:])


if __name__ == '__main__':
    main()
