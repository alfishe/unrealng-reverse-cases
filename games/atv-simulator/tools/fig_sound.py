#!/usr/bin/env python3
"""ATV Simulator's sound for doc 9: the game's own sound code run in SkoolKit's Z80 simulator from the case's build
(build/game.bin at $6338, the 48K ROM under it for the bytes Random and DrumNoise read), its speaker edges written
as audio and drawn as charts. Nothing is played.

    python3 tools/fig_sound.py audio OUTDIR        every sound as WAV (MP3 by lame -V 4 when longer than 5 s) and
                                                   DATA/sound.json (the numbers of doc 9)
    python3 tools/fig_sound.py fig-tunes OUT.png   the two tunes as a piano roll (channels A and B, the drums)
    python3 tools/fig_sound.py fig-beeper OUT.png  the speaker against T-states: the engine at two speeds, the
                                                   landing, a bonus point, a stretch of the title tune
    python3 tools/fig_sound.py fig-engine OUT.png  the engine's pitch and its T-states a frame against the speed
    python3 tools/fig_sound.py fig-format OUT.png  the tune data byte by byte: TuneTable, a sequence list, a channel
                                                   pattern, a drum pattern
  DATA is work/docs/atC/sound (--data DIR).

How each sound is run (the addresses are src/game/game.ann's):
  - the engine: EngineSound $D97C, called once a frame as Interrupt calls it, with RecordP1's Mounted (+2) = 1 and
    Speed (+9) set; RecordP2 empty (one player);
  - the landing: Landing $E663 to its JP SlowDown ($E673);
  - the bonus count: CountBonus $ED52 with Finished = 1 and RecordP1's Bonus (+$29) = N, to its return;
  - the tunes: TunePlay $F852 with A = 0 or 1, under IM 2 with an interrupt every 69 888 T. Tune 1 runs as TrailEnd
    plays it (TuneHook three NOPs) and ends by itself; tune 0 runs with TuneHook = TuneKeyCheck and no key down (the
    port reads $FF), cut when channel B starts its sequence list again (its 14 patterns played once). The caller's
    stack is put at $6000: TunePlay fills $FE00-$FF00 with its vector table.
T-states are the simulator's: uncontended. The sound code is at $D97C-$DA1D and $F850-$FB71, above $8000, so the
real machine runs it at the same speed. The speaker is bit 4 of port $FE; bit 3 (MIC) is written with it by the
tune player ($18) and is left out of the audio.
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

CPU, FRAME = 3500000, 69888
RATE = 44100
SENTINEL = 0xFFF0
DATA = os.path.join(CASE, 'work', 'docs', 'atC', 'sound')
ROM = os.path.join(os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'), 'data', 'rom', '48.rom')

# the game's addresses (src/game/game.ann)
ENGINE_SOUND, LANDING, LANDING_END, COUNT_BONUS = 0xD97C, 0xE663, 0xE673, 0xED52
TUNE_PLAY, TUNE_HOOK, TUNE_KEY_CHECK = 0xF852, 0xF96C, 0xF977
RECORD_P1, RECORD_P2, FINISHED, BEEPER_BYTE = 0xD70E, 0xD740, 0xD7A5, 0xD7A4
NOTE_A, NOTE_B, MUTE_A, MUTE_B = 0xF8CC, 0xF91B, 0xF9DD, 0xF9D1
DRUM_NOISE, DRUM_HIT, TUNE_INT, ENVELOPE = 0xFA5D, 0xFA81, 0xF961, 0xFAC6
SEQ_A_NEXT, SEQ_B_NEXT, SEQ_D_NEXT = 0xFAF9, 0xFB16, 0xFB35
NOTE_TABLE, TUNE_TABLE = 0xFB72, 0xFBAE
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


class Ports:
    def __init__(self):
        self.edges = []          # (T, speaker bit 4)
        self.level = 0

    def write_port(self, registers, port, value, *a):
        if port & 1 == 0:
            b = (value >> 4) & 1
            self.edges.append((registers[su.T], b))
            self.level = b

    def read_port(self, registers, port):
        return 0xFF


class Machine:
    def __init__(self):
        mem = bytearray(0x10000)
        mem[0:0x4000] = open(ROM, 'rb').read()
        game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
        mem[0x6338:0x6338 + len(game)] = game
        self.ports = Ports()
        self.sim = Simulator(mem, {'SP': SENTINEL - 2}, config={'fast_ldir': False, 'fast_djnz': False})
        self.sim.set_tracer(self.ports)
        self.mem = self.sim.memory
        self.watch = {}
        self.hits = []

    def t(self):
        return self.sim.registers[su.T]

    def call(self, addr, stop=SENTINEL, regs=None, interrupts=False, limit=None):
        """run from addr until PC = stop (or the pushed sentinel returns); interrupts as the ULA gives them"""
        r = self.sim.registers
        for k, v in (regs or {}).items():
            r[getattr(su, k)] = v
        sp = (r[su.SP] - 2) & 0xFFFF if interrupts else SENTINEL - 2
        self.mem[sp], self.mem[sp + 1] = SENTINEL & 255, SENTINEL >> 8
        r[su.SP] = sp
        r[su.PC] = addr
        t0 = r[su.T]
        ops, mem, sim, watch = self.sim.opcodes, self.mem, self.sim, self.watch
        next_int = (r[su.T] // FRAME + 1) * FRAME
        while True:
            pc = r[su.PC]
            if pc == stop or pc == SENTINEL:
                break
            if pc in watch:
                self.hits.append((r[su.T], pc, r[su.A]))
            ops[mem[pc]]()
            if interrupts and r[su.T] >= next_int:
                if r[su.T] < next_int + 32:
                    if r[26]:
                        sim.accept_interrupt(r, mem, pc)
                        next_int += FRAME
                else:
                    next_int += FRAME
            if limit and r[su.T] - t0 > limit:
                break
        return r[su.T] - t0


# ---- the sounds ---------------------------------------------------------------------------------------------------

def engine(speeds, frames_each=1):
    """EngineSound once a frame at each speed; the edges and the T-states a call"""
    m = Machine()
    m.mem[RECORD_P1 + 2] = 1
    costs = []
    for sp in speeds:
        for _ in range(frames_each):
            m.mem[RECORD_P1 + 9] = sp
            start = (m.t() // FRAME + 1) * FRAME + 14000           # the interrupt's sound part, after ScanKeys
            m.sim.registers[su.T] = start
            costs.append((sp, m.call(ENGINE_SOUND)))
    return m.ports.edges, costs


def landing():
    m = Machine()
    m.sim.registers[su.T] = 1000
    t = m.call(LANDING, LANDING_END)
    return m.ports.edges, t


def bonus(points):
    m = Machine()
    m.mem[FINISHED] = 1
    m.mem[RECORD_P1 + 0x29], m.mem[RECORD_P1 + 0x2A] = points & 255, points >> 8
    m.mem[0x6948:0x694D] = b'00000'
    m.sim.registers[su.T] = 1000
    t = m.call(COUNT_BONUS)
    return m.ports.edges, t, bytes(m.mem[0x6948:0x694D]).decode()


def tune(number, cut=None):
    """TunePlay under IM 2: the edges, the note events (T, channel, note index), the drum events, the frames"""
    m = Machine()
    if number == 0:
        m.mem[TUNE_HOOK], m.mem[TUNE_HOOK + 1], m.mem[TUNE_HOOK + 2] = 0xCD, TUNE_KEY_CHECK & 255, TUNE_KEY_CHECK >> 8
    else:
        m.mem[TUNE_HOOK:TUNE_HOOK + 3] = b'\x00\x00\x00'     # TrailEnd: TuneHook = three NOPs
    for a in (NOTE_A, NOTE_B, MUTE_A, MUTE_B, DRUM_NOISE, DRUM_HIT, TUNE_INT, ENVELOPE, SEQ_A_NEXT, SEQ_B_NEXT,
              SEQ_D_NEXT):
        m.watch[a] = True
    m.sim.registers[su.SP] = 0x6000
    m.sim.registers[su.T] = FRAME - 200
    t = m.call(TUNE_PLAY, regs={'A': number}, interrupts=True, limit=cut)
    return m, t


def tune_events(m, t0):
    ev = {'A': [], 'B': [], 'muteA': [], 'muteB': [], 'noise': [], 'hit': [], 'int': [], 'env': [], 'seqA': [],
          'seqB': [], 'seqD': []}
    key = {NOTE_A: 'A', NOTE_B: 'B', MUTE_A: 'muteA', MUTE_B: 'muteB', DRUM_NOISE: 'noise', DRUM_HIT: 'hit',
           TUNE_INT: 'int', ENVELOPE: 'env', SEQ_A_NEXT: 'seqA', SEQ_B_NEXT: 'seqB', SEQ_D_NEXT: 'seqD'}
    for t, pc, a in m.hits:
        ev[key[pc]].append((t - t0, a))
    return ev


def title_cut():
    """tune 0 runs until channel B has started its sequence list a second time (its 14 patterns played once)"""
    m = Machine()
    m.mem[TUNE_HOOK], m.mem[TUNE_HOOK + 1], m.mem[TUNE_HOOK + 2] = 0xCD, TUNE_KEY_CHECK & 255, TUNE_KEY_CHECK >> 8
    m.watch[0xFB27] = True                       # NextSequenceB's restart: CALL TuneEntry
    m.sim.registers[su.SP] = 0x6000
    m.sim.registers[su.T] = FRAME - 200
    t0 = m.t()
    r = m.sim.registers
    ops, mem, sim = m.sim.opcodes, m.mem, m.sim
    sp = 0x6000 - 2
    mem[sp], mem[sp + 1] = SENTINEL & 255, SENTINEL >> 8
    r[su.SP], r[su.PC], r[su.A] = sp, TUNE_PLAY, 0
    next_int = (r[su.T] // FRAME + 1) * FRAME
    while True:
        pc = r[su.PC]
        if pc == 0xFB27:
            break
        ops[mem[pc]]()
        if r[su.T] >= next_int:
            if r[su.T] < next_int + 32 and r[26]:
                sim.accept_interrupt(r, mem, pc)
            next_int += FRAME
    return m.t() - t0


# ---- audio --------------------------------------------------------------------------------------------------------

def render(edges, t0, t1):
    """the speaker level as 16-bit samples: each sample the mean level over its T-states (a box filter)"""
    n = int((t1 - t0) * RATE / CPU) + 1
    acc = [0.0] * (n + 1)
    level, prev = 0, t0
    tps = CPU / RATE

    def add(a, b, lv):
        # add lv over T-states [a, b) to the samples they cover
        if not lv or b <= a:
            return
        ka, kb = int((a - t0) / tps), int((b - t0) / tps)
        if ka == kb:
            acc[min(ka, n)] += (b - a) / tps
            return
        acc[min(ka, n)] += (t0 + (ka + 1) * tps - a) / tps
        for k in range(ka + 1, min(kb, n + 1)):
            acc[k] += 1.0
        acc[min(kb, n)] += (b - (t0 + kb * tps)) / tps

    for t, b in sorted(edges) + [(t1, None)]:
        t = max(t0, min(t, t1))
        add(prev, t, level)
        prev = t
        if b is not None:
            level = b
    out = acc[:n]
    mean = sum(out) / len(out) if out else 0
    return [int(max(-1.0, min(1.0, (v - mean) * 1.6)) * 20000) for v in out]


def write_wav(path, samples):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(int(s).to_bytes(2, 'little', signed=True) for s in samples))


def write_audio(path, samples):
    """WAV, or MP3 (lame -V 4) when longer than 5 s; the file's name"""
    if len(samples) <= 5 * RATE:
        write_wav(path + '.wav', samples)
        return os.path.basename(path) + '.wav'
    write_wav(path + '.tmp.wav', samples)
    subprocess.run(['lame', '--quiet', '-V', '4', path + '.tmp.wav', path + '.mp3'], check=True)
    os.remove(path + '.tmp.wav')
    return os.path.basename(path) + '.mp3'


def edge_stats(edges):
    ts = [t for t, _ in edges]
    return {'edges': len(ts), 'first': ts[0] if ts else None, 'last': ts[-1] if ts else None}


def cmd_audio(out):
    os.makedirs(out, exist_ok=True)
    os.makedirs(DATA, exist_ok=True)
    nums = {}
    # the engine: 6 s, the speed rising from 1 to 21 by one a pass (7 frames), held, then falling by 2 a pass
    speeds = list(range(1, 22)) + [21] * 10 + list(range(19, 0, -2))
    edges, costs = engine(speeds, 7)
    samples = render(edges, FRAME, (len(speeds) * 7 + 2) * FRAME)
    nums['engine_file'] = write_audio(os.path.join(out, 'engine'), samples)
    per = {}
    for sp, c in costs:
        per.setdefault(sp, c)
    nums['engine_cost'] = per
    # the engine's half-period in T at each speed (the first two edges of a call)
    half = {}
    for sp in range(1, 22):
        e, _ = engine([sp])
        half[sp] = e[1][0] - e[0][0]
    nums['engine_half'] = half
    # the landing
    edges, t = landing()
    nums['landing_T'] = t
    nums['landing_edges'] = len(edges)
    nums['landing_file'] = write_audio(os.path.join(out, 'landing'), render(edges, 0, edges[-1][0] + 20000))
    # the bonus count: 25 points
    edges, t, score = bonus(25)
    nums['bonus_T'], nums['bonus_score'], nums['bonus_edges'] = t, score, len(edges)
    nums['bonus_file'] = write_audio(os.path.join(out, 'bonus-count'), render(edges, 0, edges[-1][0] + 20000))
    # the tunes
    for number, name in ((1, 'tune-finish'), (0, 'tune-title')):
        cut = title_cut() if number == 0 else None
        m, t = tune(number, cut)
        t0 = FRAME - 200
        ev = tune_events(m, t0)
        nums[name] = {'T': t, 'seconds': round(t / CPU, 2), 'frames': round(t / FRAME, 1),
                      'interrupts': len(ev['int']), 'envelope_calls': len(ev['env']),
                      'notesA': len(ev['A']), 'notesB': len(ev['B']), 'noise': len(ev['noise']),
                      'hit': len(ev['hit']), 'edges': len(m.ports.edges)}
        json.dump({k: v for k, v in ev.items()}, open(os.path.join(DATA, name + '-events.json'), 'w'))
        json.dump(m.ports.edges, open(os.path.join(DATA, name + '-edges.json'), 'w'))
        nums[name]['file'] = write_audio(os.path.join(out, name), render(m.ports.edges, t0, t0 + t))
    json.dump(nums, open(os.path.join(DATA, 'sound.json'), 'w'), indent=1)
    print(json.dumps({k: v for k, v in nums.items() if k not in ('engine_cost', 'engine_half')}, indent=1))


# ---- figures ------------------------------------------------------------------------------------------------------

def font(size):
    from PIL import ImageFont
    for p in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf',
              '/System/Library/Fonts/Helvetica.ttc'):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def note_name(i, table):
    """the note NoteTable index i stands for: from its half-period in loop turns and the loop's T-states"""
    return i


def cmd_fig_tunes(path):
    from PIL import Image, ImageDraw
    nums = json.load(open(os.path.join(DATA, 'sound.json')))
    W = 1050
    rows = []
    for name, title in (('tune-title', 'tune 0, the title (TunePlay from MenuLoop $7391): one pass of its lists'),
                        ('tune-finish', 'tune 1, the finish (TunePlay from TrailEnd $ED00): the whole tune')):
        ev = json.load(open(os.path.join(DATA, name + '-events.json')))
        rows.append((name, title, ev, nums[name]))
    H = 40 + sum(330 if r[0] == 'tune-title' else 250 for r in rows)
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    f, fs, fb = font(14), font(12), font(16)
    d.text((10, 8), 'The two tunes as the player reads them: a bar per note, its height the note number '
                    '(0 lowest), drums below', fill='black', font=fb)
    y0 = 40
    for name, title, ev, n in rows:
        h = 330 if name == 'tune-title' else 250
        total = n['T']
        x0, x1 = 60, W - 20
        plot_top, plot_bot = y0 + 26, y0 + h - 70
        d.text((10, y0 + 4), title + f': {n["seconds"]} s, {n["notesA"]} notes on A, {n["notesB"]} on B',
               fill='black', font=f)
        lo, hi = 0, 40

        def ny(k):
            return plot_bot - (k - lo) * (plot_bot - plot_top) / (hi - lo)

        for k in range(0, 41, 10):
            d.line((x0, ny(k), x1, ny(k)), fill=(225, 225, 225))
            d.text((x0 - 28, ny(k) - 7), str(k), fill='black', font=fs)

        def tx(t):
            return x0 + t * (x1 - x0) / total

        for ch, col, mk in (('A', (200, 60, 40), 'muteA'), ('B', (40, 90, 200), 'muteB')):
            pts = sorted([(t, a, 'n') for t, a in ev[ch]] + [(t, 0, 'm') for t, _ in ev[mk]])
            for i, (t, a, kind) in enumerate(pts):
                if kind != 'n':
                    continue
                t2 = pts[i + 1][0] if i + 1 < len(pts) else total
                yy = ny(a)
                d.rectangle((tx(t), yy - 2, max(tx(t) + 1, tx(t2) - 1), yy + 2), fill=col)
        dy = plot_bot + 18
        d.text((10, dy - 4), 'drums', fill='black', font=fs)
        for t, _ in ev['noise']:
            d.line((tx(t), dy, tx(t), dy + 10), fill=(90, 90, 90), width=2)
        for t, _ in ev['hit']:
            d.line((tx(t), dy + 14, tx(t), dy + 24), fill=(0, 140, 0), width=2)
        secs = int(total / CPU)
        step = 5 if secs > 12 else 1
        for s in range(0, secs + 1, step):
            x = tx(s * CPU)
            d.line((x, plot_bot, x, plot_bot + 4), fill='black')
            d.text((x - 6, plot_bot + 34), f'{s} s', fill='black', font=fs)
        d.rectangle((x1 - 330, y0 + 4, x1 - 318, y0 + 14), fill=(200, 60, 40))
        d.text((x1 - 314, y0 + 2), 'channel A', fill='black', font=fs)
        d.rectangle((x1 - 240, y0 + 4, x1 - 228, y0 + 14), fill=(40, 90, 200))
        d.text((x1 - 224, y0 + 2), 'channel B', fill='black', font=fs)
        d.line((x1 - 150, y0 + 4, x1 - 150, y0 + 14), fill=(90, 90, 90), width=2)
        d.text((x1 - 144, y0 + 2), 'noise', fill='black', font=fs)
        d.line((x1 - 95, y0 + 4, x1 - 95, y0 + 14), fill=(0, 140, 0), width=2)
        d.text((x1 - 89, y0 + 2), 'hit', fill='black', font=fs)
        y0 += h
    im.save(path)


def cmd_fig_beeper(path):
    from PIL import Image, ImageDraw
    panels = []
    e, _ = engine([5])
    panels.append(('the engine at speed 5, one frame: three Clicks %d T apart, then SpeakerOff' % (e[1][0] - e[0][0]), e))
    e, _ = engine([21])
    panels.append(('the engine at speed 21, one frame: three Clicks %d T apart, then SpeakerOff' % (e[1][0] - e[0][0]), e))
    e, t = landing()
    panels.append(('the landing: Tone (5 Clicks, C = 10) then Noise (10 Clicks, gaps from the ROM), %d T' % t, e))
    e, t, _ = bonus(1)
    panels.append(('a bonus of one point: the delay, the score, Tone (30 edges), the delay again; %d T' % t, e))
    m, t = tune(0, 3 * FRAME)
    e = [(tt, b) for tt, b in m.ports.edges if 2 * FRAME - 200 <= tt < 2 * FRAME - 200 + 12000]
    panels.append(('the title tune, 12 000 T of its loop: channel A and B pulses on one speaker', e))
    W, ph = 1050, 92
    im = Image.new('RGB', (W, 40 + ph * len(panels) + 30), 'white')
    d = ImageDraw.Draw(im)
    f, fs, fb = font(13), font(12), font(16)
    d.text((10, 8), 'The speaker bit (port $FE bit 4) against T-states, each sound from its first edge',
           fill='black', font=fb)
    x0, x1 = 70, W - 20
    for i, (title, edges) in enumerate(panels):
        y = 40 + i * ph
        d.text((10, y), title, fill='black', font=f)
        if not edges:
            continue
        t0 = edges[0][0]
        span = max(edges[-1][0] - t0, 1) * 1.08
        hi_y, lo_y = y + 22, y + 62
        lvl, px, py = 0, x0, lo_y
        for t, b in edges:
            x = x0 + (t - t0) * (x1 - x0) / span
            d.line((px, py, x, py), fill=(30, 30, 30), width=2)
            ny_ = hi_y if b else lo_y
            d.line((x, py, x, ny_), fill=(30, 30, 30), width=1)
            px, py = x, ny_
        d.line((px, py, x1, py), fill=(30, 30, 30), width=2)
        for k in range(5):
            tt = span * k / 4
            x = x0 + tt * (x1 - x0) / span
            d.line((x, lo_y + 2, x, lo_y + 6), fill='black')
            label = f'{int(tt):,} T'.replace(',', ' ')
            d.text((x - (d.textlength(label, font=fs) if k == 4 else 10), lo_y + 8), label, fill=(80, 80, 80),
                   font=fs)
        d.text((10, hi_y - 6), 'on', fill=(80, 80, 80), font=fs)
        d.text((10, lo_y - 8), 'off', fill=(80, 80, 80), font=fs)
    im.save(path)


def cmd_fig_engine(path):
    from PIL import Image, ImageDraw
    nums = json.load(open(os.path.join(DATA, 'sound.json')))
    half = {int(k): v for k, v in nums['engine_half'].items()}
    cost = {int(k): v for k, v in nums['engine_cost'].items()}
    W, H = 1050, 420
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    f, fs, fb = font(13), font(12), font(16)
    d.text((10, 8), 'The engine against Speed: the pitch of the burst rises, its cost a frame falls', fill='black',
           font=fb)
    for pi, (title, data, unit, top) in enumerate((
            ('the burst\'s pitch: 3 500 000 / (2 x half-period), Hz', {k: CPU / (2 * v) for k, v in half.items()},
             'Hz', 4000),
            ('EngineSound\'s T-states a frame (one player riding)', cost, 'T', 12000))):
        x0 = 70 + pi * 500
        x1, y0, y1 = x0 + 420, 60, H - 60
        d.text((x0 - 40, 34), title, fill='black', font=f)
        d.line((x0, y1, x1, y1), fill='black')
        d.line((x0, y0, x0, y1), fill='black')
        for k in range(0, 5):
            v = top * k / 4
            y = y1 - (y1 - y0) * k / 4
            d.line((x0 - 4, y, x1, y), fill=(225, 225, 225))
            d.text((x0 - 48, y - 7), f'{int(v)}', fill='black', font=fs)
        for s in range(0, 22, 3):
            x = x0 + s * (x1 - x0) / 21
            d.text((x - 5, y1 + 6), str(s), fill='black', font=fs)
        d.text(((x0 + x1) // 2 - 40, y1 + 24), 'Speed ($D77B)', fill='black', font=fs)
        pts = [(x0 + s * (x1 - x0) / 21, y1 - (y1 - y0) * data[s] / top) for s in sorted(data) if s > 0]
        d.line(pts, fill=(200, 60, 40), width=2)
        for x, y in pts:
            d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(200, 60, 40))
    im.save(path)


def cmd_fig_format(path):
    from PIL import Image, ImageDraw
    mem = bytearray(0x10000)
    game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[0x6338:0x6338 + len(game)] = game
    W, H = 1050, 600
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    f, fs, fb, fm = font(13), font(12), font(16), font(13)
    d.text((10, 8), 'The tune data byte by byte, from the image: a tune names three lists, a list names patterns, '
                    'a pattern is notes and commands', fill='black', font=fb)

    def row(y, label, addr, n, notes, colours):
        d.text((10, y + 6), label, fill='black', font=f)
        x = 250
        for i in range(n):
            b = mem[addr + i]
            c = colours[i] if i < len(colours) else (240, 240, 240)
            d.rectangle((x, y, x + 40, y + 28), fill=c, outline='black')
            d.text((x + 6, y + 6), f'{b:02X}', fill='black', font=fm)
            if i < len(notes) and notes[i]:
                d.text((x + 2, y + 32), notes[i], fill=(60, 60, 60), font=fs)
            x += 42
        d.text((250, y - 16), f'${addr:04X}', fill=(90, 90, 90), font=fs)

    pa, pb, pc = (255, 220, 200), (210, 225, 255), (215, 245, 210)
    row(60, 'TuneTable $FBAE: tunes 0, 1', TUNE_TABLE, 12,
        ['A lo', 'A hi', 'B lo', 'B hi', 'D lo', 'D hi', 'A lo', 'A hi', 'B lo', 'B hi', 'D lo', 'D hi'],
        [pa, pa, pb, pb, pc, pc] * 2)
    d.text((250, 112), 'tune 0: lists $FBBA, $FBEC, $FC0A; tune 1: $FD7E, $FD82, $FD86', fill='black', font=fs)
    row(160, 'SeqFBBA: channel A list', 0xFBBA, 8, ['FC0E', '', 'FC2B', '', 'FC0E', '', 'FC46', ''],
        [pa] * 8)
    d.text((250, 212), 'pattern addresses in turn; a 0 word ends the list and NextSequenceA starts it again',
           fill='black', font=fs)
    notes = []
    p = 0xFC0E
    toks = []
    i = 0
    while i < 14:
        b = mem[p + i]
        if b >= 0x80:
            c = b & 0x7F
            if c in (2, 3, 4):
                toks += [['next', 'mute', 'env', 'len', 'tr'][c], str(mem[p + i + 1])]
                i += 2
                continue
            toks.append(['next', 'mute', 'env', 'len', 'tr', 'end'][c])
        else:
            toks.append(f'n{b}')
        i += 1
    cols = []
    operand = False
    for k in range(14):
        b = mem[p + k]
        cols.append((255, 235, 160) if b >= 0x80 or operand else pa)
        operand = b in (0x82, 0x83, 0x84) and not operand
    row(260, 'PatFC0E: a channel pattern', p, 14, toks, cols)
    d.text((250, 312), '$80 + n is a command (n: 0 next, 1 mute, 2 env N, 3 len N, 4 tr N, 5 the end); '
                       'a byte under $80 a note: NoteTable[n + transposition]', fill='black', font=fs)
    row(360, 'PatFD62: the drum pattern', 0xFD62, 14,
        ['speed', '4', 'noise', 'speed', '2', 'noise', 'noise', 'speed', '4', 'hit', '50', 'speed', '2', 'noise'],
        [pc] * 14)
    d.text((250, 412), 'a byte every C\' interrupts (12, or 3 x speed N); AND $7F picks the command', fill='black',
           font=fs)
    row(460, 'NoteTable $FB72: notes 0-13', NOTE_TABLE, 14, [str(k) for k in range(14)], [(235, 235, 235)] * 14)
    d.text((250, 512), 'a note\'s period in turns of the player loop (60 notes, the lowest first); '
                       'channel A\'s pulse is 1/8 of it, channel B\'s 1/4', fill='black', font=fs)
    im.save(path)


def main():
    a = sys.argv[1:]
    global DATA
    if '--data' in a:
        i = a.index('--data')
        DATA = a[i + 1]
        del a[i:i + 2]
    if not a:
        sys.exit(__doc__)
    cmd = a[0]
    {'audio': cmd_audio, 'fig-tunes': cmd_fig_tunes, 'fig-beeper': cmd_fig_beeper, 'fig-engine': cmd_fig_engine,
     'fig-format': cmd_fig_format}[cmd](*a[1:])


if __name__ == '__main__':
    main()
