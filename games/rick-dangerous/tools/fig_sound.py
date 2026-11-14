#!/usr/bin/env python3
"""Doc 09: the sound of Rick Dangerous, run on SkoolKit's Z80 simulator from the built images, never played.

The AY player (build/music.bin at RAM 1 `$C000`) is run as the game runs it: AyPlayTune `$C3E4` or AyPlayEffect `$C685`
once with A = the number, then AyTick `$C46C` once a frame, as the IM 2 handler calls it through SoundTick `$A030`.
Every OUT to `$FFFD` / `$BFFD` is logged with the registers after each frame. The 48K's BeeperEffect `$A08E`
(build/game.bin at `$5B00`) is run the same way, and every OUT to port `$FE` is logged with its T-state.

    python3 tools/fig_sound.py costs                       # T-states per frame of every tune and effect
    python3 tools/fig_sound.py audio docs/audio            # WAV of the effects up to 1 s, MP3 (lame -V 4) of the tunes and longer effects
    python3 tools/fig_sound.py chart 5 docs/img/sound/tune5.png
    python3 tools/fig_sound.py effects docs/img/sound/effects.png
    python3 tools/fig_sound.py beeper docs/img/sound/beeper.png
    python3 tools/fig_sound.py anim 0 docs/img/routines/AyTick.gif   # the AY registers per interrupt

The AY's PSG stream goes through unreal-ng's psg2wav.py (frame resolution, the 128K's 1.7734 MHz clock); the beeper's
edges become samples directly (3.5469 MHz T-states). Nothing here plays a sound.
"""
import json
import os
import struct
import subprocess
import sys
import wave

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.join(HERE, '..')
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
try:
    from skoolkit.simulator import Simulator
except ImportError:  # SkoolKit from the kit's venv (toolpaths.py venv)
    import glob
    venv = subprocess.check_output(['python3', os.path.join(CASE, '..', '..', 'kit', 'toolpaths.py'), 'venv']).decode()
    sys.path += glob.glob(os.path.join(venv.strip(), 'lib', 'python3*', 'site-packages'))
    from skoolkit.simulator import Simulator
from skoolkit import simutils as su  # noqa: E402

AY_PLAY_TUNE, AY_TICK, AY_PLAY_EFFECT, MUSIC_ON = 0xC3E4, 0xC46C, 0xC685, 0xC35A
BEEPER_EFFECT = 0xA08E
SENTINEL = 0x0000
FRAME_T = 70908
AY_CLOCK = 1773400
BG, TEXT, DIM, GRID = (24, 24, 30), (235, 235, 235), (170, 170, 180), (60, 60, 75)
CH = [(250, 110, 90), (110, 220, 120), (110, 150, 250)]
TUNE_NAMES = {0: 'a level\'s intro', 1: 'level 1 done', 2: 'level 2 done', 3: 'level 3 done', 4: 'level 4 done',
              5: 'the menu', 6: 'GAME OVER', 7: 'the bonus collected'}
EFFECT_NAMES = {0: 'a shot', 1: 'no bullets', 2: 'the dynamite\'s bang', 3: 'a trap set off, a poke',
                4: 'a footstep', 5: 'no call site', 6: 'a jump, a ceiling bump', 7: 'no call site',
                8: 'ammunition picked up', 9: 'a treasure', 10: 'the bonus count starts',
                11: 'Rick dies, an enemy hit'}
NOTES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']


class AY:
    def __init__(self):
        self.reg, self.regs, self.writes = 0, [0] * 16, []
        self.regs[7] = 0x3F

    def write_port(self, registers, port, value, *a):
        if port & 0xC002 == 0xC000:
            self.reg = value & 15
        elif port & 0xC002 == 0x8000:
            self.regs[self.reg] = value
            self.writes.append((self.reg, value))

    def read_port(self, registers, port):
        return self.regs[self.reg] if port & 0xC002 == 0xC000 else 0xFF


class Beeper:
    def __init__(self, sim):
        self.sim, self.edges = sim, []

    def write_port(self, registers, port, value, *a):
        if port & 1 == 0:
            self.edges.append((registers[su.T], (value >> 4) & 1))

    def read_port(self, registers, port):
        return 0xFF


def call(sim, addr, a=None, limit=5_000_000):
    r, mem = sim.registers, sim.memory
    if a is not None:
        r[su.A] = a
    sp = r[su.SP] - 2
    mem[sp], mem[sp + 1] = SENTINEL & 255, SENTINEL >> 8
    r[su.SP], r[su.PC] = sp, addr
    t0, ops = r[su.T], sim.opcodes
    while r[su.PC] != SENTINEL:
        ops[mem[r[su.PC]]]()
        if r[su.T] - t0 > limit:
            raise SystemExit(f'call {addr:04X} did not return')
    return r[su.T] - t0


def ay_run(kind, number, max_frames=6000, tail=0):
    """Frames of the AY player after AyPlayTune / AyPlayEffect: [(T of the call, writes, the 14 registers)]"""
    mem = [0] * 0x10000
    mem[SENTINEL] = 0x76
    data = open(os.path.join(CASE, 'build', 'music.bin'), 'rb').read()
    mem[0xC000:0xC000 + len(data)] = data
    ay = AY()
    sim = Simulator(mem, {'SP': 0xBFF0}, config={'fast_ldir': False, 'fast_djnz': False})
    sim.set_tracer(ay)
    t_start = call(sim, AY_PLAY_TUNE if kind == 'tune' else AY_PLAY_EFFECT, number)
    frames, quiet = [], 0
    for f in range(max_frames):
        ay.writes = []
        t = call(sim, AY_TICK)
        frames.append((t, list(ay.writes), ay.regs[:14]))
        silent = (ay.regs[7] & 0x3F) == 0x3F or all((ay.regs[8 + c] & 15) == 0 for c in range(3))
        done = mem[MUSIC_ON] == 0 if kind == 'tune' else silent
        quiet = quiet + 1 if done else 0
        if quiet > tail and f > 2:
            break
    return t_start, frames


def beeper_run(number):
    """The beeper's edges of one effect: [(T from the start, speaker bit)], the effect's T-states"""
    mem = [0] * 0x10000
    mem[SENTINEL] = 0x76
    data = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[0x5B00:0x5B00 + len(data)] = data
    bp = Beeper(None)
    sim = Simulator(mem, {'SP': 0xFF00}, config={'fast_ldir': False, 'fast_djnz': False})
    sim.set_tracer(bp)
    sim.registers[su.C] = number
    t = call(sim, BEEPER_EFFECT, number)
    return [(et, v) for et, v in bp.edges], t


def psg_bytes(frames):
    out = bytearray(b'PSG\x1a' + bytes(12))
    for _, writes, _ in frames:
        out.append(0xFF)
        for r, v in writes:
            out += bytes((r, v))
    out.append(0xFD)
    return bytes(out)


def unreal():
    return subprocess.check_output(['python3', os.path.join(CASE, '..', '..', 'kit', 'toolpaths.py'), 'unreal']).decode().strip()


def write_ay_wav(frames, path):
    psg = path[:-4] + '.psg'
    open(psg, 'wb').write(psg_bytes(frames))
    tool = os.path.join(unreal(), 'tools', 'verification', 'analysis', 'psg2wav.py')
    subprocess.check_call(['python3', tool, psg, path, '--clock', str(AY_CLOCK)], stdout=subprocess.DEVNULL)
    os.remove(psg)


def write_beeper_wav(edges, total, path, rate=44100, clock=3546900):
    n = int(total / clock * rate) + rate // 10
    level, samples, i = 0, bytearray(), 0
    for s in range(n):
        t = s * clock / rate
        while i < len(edges) and edges[i][0] <= t:
            level = edges[i][1]
            i += 1
        samples += struct.pack('<h', 9000 if level else -9000)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(bytes(samples))


def cmd_costs():
    print('kind n frames start_T tick_T(min/median/max)')
    for kind, rng in (('tune', range(8)), ('effect', range(12))):
        for n in rng:
            t0, fr = ay_run(kind, n)
            ts = sorted(t for t, _, _ in fr)
            print(kind, n, len(fr), t0, ts[0], ts[len(ts) // 2], ts[-1])
    for n in (0, 2, 4, 6, 11, 1):
        edges, t = beeper_run(n)
        print('beeper', n, 'T', t, f'{t / FRAME_T:.2f} frames', 'edges', len(edges))


def cmd_audio(out):
    os.makedirs(out, exist_ok=True)
    for n in range(8):
        _, fr = ay_run('tune', n, tail=25)
        wav = os.path.join(out, f'tune{n}.wav')
        write_ay_wav(fr, wav)
        subprocess.check_call(['lame', '--quiet', '-V', '4', wav, os.path.join(out, f'tune{n}.mp3')])
        os.remove(wav)
        print(f'tune{n}.mp3', len(fr), 'frames')
    for n in range(12):  # an effect up to a second (50 frames) as WAV, a longer one as MP3
        _, fr = ay_run('effect', n, tail=10)
        wav = os.path.join(out, f'effect{n}.wav')
        write_ay_wav(fr, wav)
        if len(fr) > 50:
            subprocess.check_call(['lame', '--quiet', '-V', '4', wav, os.path.join(out, f'effect{n}.mp3')])
            os.remove(wav)
        print(f'effect{n}.' + ('mp3' if len(fr) > 50 else 'wav'), len(fr), 'frames')
    for n in (0, 2, 4, 6, 11, 1):
        edges, t = beeper_run(n)
        write_beeper_wav(edges, t, os.path.join(out, f'beeper{n}.wav'))
        print(f'beeper{n}.wav', t, 'T')


def note_name(period):
    import math
    if not period:
        return ''
    f = AY_CLOCK / 16 / period
    m = round(12 * math.log2(f / 440.0) + 57)
    return f'{NOTES[m % 12]}{m // 12}'


def cmd_chart(n, png):
    """The tune as the AY plays it: a piano roll of the three channels' periods and volumes, frame by frame"""
    import math
    _, fr = ay_run('tune', n, tail=10)
    W, left, top = 1050, 70, 90
    nf = len(fr)
    lanes = 3
    lane_h = 160
    H = top + lanes * (lane_h + 30) + 70
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), f'Tune {n} ({TUNE_NAMES[n]}): {nf} frames, {nf / 50:.1f} s, as the AY plays it', fill=TEXT,
           font=K.font(22))
    d.text((12, 44), f'Lanes: channels A, B, C; height the note, brightness the volume. fig_sound.py chart {n}: '
           'AyPlayTune, AyTick a frame.', fill=DIM, font=K.font(14))
    x = (lambda f: left + f / max(nf, 1) * (W - left - 20))
    pitches = []
    for _, _, regs in fr:
        for c in range(3):
            p = regs[2 * c] | (regs[2 * c + 1] & 15) << 8
            if p and regs[8 + c] & 15 and not regs[7] >> c & 1:
                pitches.append(12 * math.log2(AY_CLOCK / 16 / p / 440.0) + 57)
    lo, hi = (min(pitches) - 1, max(pitches) + 1) if pitches else (40, 80)
    for c in range(3):
        y0 = top + c * (lane_h + 30)
        d.rectangle((left, y0, W - 20, y0 + lane_h), outline=GRID)
        d.text((12, y0 + lane_h // 2 - 10), 'ABC'[c], fill=CH[c], font=K.font(20))
        for m in range(int(lo) + 1, int(hi) + 1):
            if m % 12 == 0:
                y = y0 + lane_h - (m - lo) / (hi - lo) * lane_h
                d.line([(left, y), (W - 20, y)], fill=GRID)
                d.text((left - 40, y - 8), f'C{m // 12}', fill=DIM, font=K.font(13))
        for f, (_, _, regs) in enumerate(fr):
            p = regs[2 * c] | (regs[2 * c + 1] & 15) << 8
            v = regs[8 + c] & 15
            tone_on = not regs[7] >> c & 1
            noise_on = not regs[7] >> (c + 3) & 1
            if not v or not p or not (tone_on or noise_on):
                continue
            m = 12 * math.log2(AY_CLOCK / 16 / p / 440.0) + 57
            y = y0 + lane_h - (m - lo) / (hi - lo) * lane_h
            k = v / 15
            col = tuple(int(30 + (cc - 30) * k) for cc in CH[c]) if tone_on else (int(200 * k),) * 3
            d.rectangle((x(f), y - 2, x(f + 1) + 1, y + 2), fill=col)
    yb = top + lanes * (lane_h + 30)
    for s in range(0, int(nf / 50) + 1, max(1, int(nf / 50 / 10))):
        d.text((x(s * 50) - 8, yb - 22), f'{s} s', fill=DIM, font=K.font(14))
    d.text((12, yb + 10), 'Grey: noise only. Pitch: the AY period at 1.7734 MHz. The table was made for 2 MHz, so '
           'every note', fill=DIM, font=K.font(14))
    d.text((12, yb + 30), 'sounds about 2 semitones lower than its name.', fill=DIM, font=K.font(14))
    img.save(png)
    print(png, img.size, nf)


def cmd_effects(png):
    """The 12 effects: each channel's volume and period, frame by frame"""
    import math
    W = 1050
    cols, rows = 3, 4
    cw, chh = (W - 30) // cols, 170
    H = 90 + rows * (chh + 20)
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), 'The 12 AY effects: the volume (bars) and the pitch (line) a frame', fill=TEXT, font=K.font(22))
    d.text((12, 44), 'fig_sound.py effects: AyPlayEffect with A = n on a silent player, then AyTick a frame; '
           'the effect\'s channel only.', fill=DIM, font=K.font(14))
    for n in range(12):
        t0, fr = ay_run('effect', n, tail=0)
        ox, oy = 15 + (n % cols) * cw, 80 + (n // cols) * (chh + 20)
        d.rectangle((ox, oy, ox + cw - 10, oy + chh), outline=GRID)
        d.text((ox + 6, oy + 4), f'{n}: {EFFECT_NAMES[n]}', fill=TEXT, font=K.font(15))
        d.text((ox + 6, oy + 24), f'{len(fr)} frames', fill=DIM, font=K.font(13))
        # the channel the effect took (EffectChannel moves on from 0 before use: B on a fresh player)
        ch = max(range(3), key=lambda c: sum(regs[8 + c] & 15 for _, _, regs in fr))
        nf = max(len(fr), 1)
        bw = (cw - 30) / nf
        base = oy + chh - 8
        for f, (_, _, regs) in enumerate(fr):
            v = regs[8 + ch] & 15
            x0 = ox + 10 + f * bw
            d.rectangle((x0, base - v * 6, x0 + max(bw - 1, 1), base), fill=(80, 90, 140))
        pts = []
        for f, (_, _, regs) in enumerate(fr):
            noise = not regs[7] >> (ch + 3) & 1
            p = regs[6] & 31 if noise and regs[7] >> ch & 1 else regs[2 * ch] | (regs[2 * ch + 1] & 15) << 8
            if p:
                y = base - 4 - (math.log2(4096 / p) / 12) * (chh - 50) if not (noise and regs[7] >> ch & 1) \
                    else base - 4 - (math.log2(32 / p) / 5) * (chh - 50)
                pts.append((ox + 10 + (f + 0.5) * bw, y))
        if len(pts) > 1:
            d.line(pts, fill=(250, 200, 90), width=2)
    img.save(png)
    print(png, img.size)


def cmd_beeper(png):
    """The 48K's six beeper patterns: each half period (E) against time"""
    W = 1050
    effects = [(0, 'effect 0: the chirp'), (2, 'effect 2: the warble'), (6, 'effect 6: the steps down'),
               (11, 'effect 11: the falling note'), (4, 'effect 4: one click'), (1, 'effect 1 (3, 5, 7-10): the sweep')]
    cw, chh = (W - 30) // 3, 200
    H = 90 + 2 * (chh + 24)
    img = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(img)
    d.text((12, 10), 'The 48K\'s six beeper patterns: the length of each half wave', fill=TEXT, font=K.font(22))
    d.text((12, 44), 'fig_sound.py beeper: BeeperEffect $A08E with A = n; a dot is one half wave of port $FE bit 4, '
           'its length in T-states.', fill=DIM, font=K.font(14))
    for i, (n, name) in enumerate(effects):
        edges, total = beeper_run(n)
        ox, oy = 15 + (i % 3) * cw, 80 + (i // 3) * (chh + 24)
        d.rectangle((ox, oy, ox + cw - 10, oy + chh), outline=GRID)
        d.text((ox + 6, oy + 4), name, fill=TEXT, font=K.font(15))
        d.text((ox + 6, oy + 24), f'{total} T = {total / 3546.9:.1f} ms, {len(edges)} edges', fill=DIM,
               font=K.font(13))
        halves = [(edges[k][0], edges[k + 1][0] - edges[k][0]) for k in range(len(edges) - 1)]
        if not halves:
            continue
        mx = max(h for _, h in halves) or 1
        for t, h in halves:
            x = ox + 10 + t / max(total, 1) * (cw - 30)
            y = oy + chh - 8 - h / mx * (chh - 74)
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(250, 200, 90))
        d.text((ox + 6, oy + 42), f'the longest half wave: {mx} T', fill=DIM, font=K.font(13))
    img.save(png)
    print(png, img.size)


def cmd_anim(n, gif, frames_max=150):
    """The AY's 14 registers after each AyTick of tune n, one picture an interrupt"""
    _, fr = ay_run('tune', n, tail=0)
    fr = fr[:frames_max]
    names = ['A period lo', 'A period hi', 'B period lo', 'B period hi', 'C period lo', 'C period hi', 'noise',
             'mixer', 'A volume', 'B volume', 'C volume', 'env lo', 'env hi', 'env shape']
    W, H = 1050, 600
    pics = []
    hist = []
    for f, (t, writes, regs) in enumerate(fr):
        img = Image.new('RGB', (W, H), BG)
        d = ImageDraw.Draw(img)
        d.text((12, 10), f'AyTick: the AY registers after interrupt {f + 1} of tune {n} ({TUNE_NAMES[n]})', fill=TEXT,
               font=K.font(22))
        d.text((12, 44), f'{len(writes)} writes this interrupt, AyTick {t} T. Yellow: written now (the same value '
               'or a new one).', fill=DIM, font=K.font(15))
        written = {r for r, _ in writes}
        for r in range(14):
            y = 80 + r * 26
            col = (250, 210, 80) if r in written else TEXT
            d.text((12, y), f'R{r:<2} {names[r]}', fill=DIM, font=K.font(15))
            d.text((200, y), f'${regs[r]:02X}', fill=col, font=K.font(16))
            if r in (8, 9, 10):
                v = regs[r] & 15
                d.rectangle((260, y + 3, 260 + v * 14, y + 18), fill=CH[r - 8])
            if r in (0, 2, 4):
                c = r // 2
                p = regs[r] | (regs[r + 1] & 15) << 8
                d.text((260, y), f'period {p}  {note_name(p)}', fill=CH[c], font=K.font(15))
            if r == 7:
                bits = ''.join('-' if regs[7] >> b & 1 else 'ABC'[b % 3] for b in range(6))
                d.text((260, y), f'tone {bits[:3]}  noise {bits[3:]}', fill=TEXT, font=K.font(15))
        hist.append([regs[8 + c] & 15 for c in range(3)])
        # the volume history: the three channels over the last frames
        ox, oy, w, h = 520, 90, 510, 330
        d.rectangle((ox, oy, ox + w, oy + h), outline=GRID)
        d.text((ox + 4, oy + h + 6), f'the volumes, interrupts 1-{len(fr)}', fill=DIM, font=K.font(14))
        for c in range(3):
            pts = [(ox + 4 + k / max(len(fr) - 1, 1) * (w - 8), oy + 10 + c * (h // 3) + (15 - hv[c]) / 15 * (h // 3 - 20))
                   for k, hv in enumerate(hist)]
            if len(pts) > 1:
                d.line(pts, fill=CH[c], width=2)
            d.text((ox + w - 20, oy + 10 + c * (h // 3)), 'ABC'[c], fill=CH[c], font=K.font(15))
        d.text((12, H - 60), 'The writes this interrupt: ' + ' '.join(f'R{r}={v:02X}' for r, v in writes[:14]),
               fill=DIM, font=K.font(14))
        pics.append(img)
    K.save_gif(gif, pics, [80] * (len(pics) - 1) + [1500])
    print(gif, len(pics))


def main():
    a = sys.argv[1:]
    if not a:
        raise SystemExit(__doc__)
    if a[0] == 'costs':
        cmd_costs()
    elif a[0] == 'audio':
        cmd_audio(a[1])
    elif a[0] == 'chart':
        cmd_chart(int(a[1]), a[2])
    elif a[0] == 'effects':
        cmd_effects(a[1])
    elif a[0] == 'beeper':
        cmd_beeper(a[1])
    elif a[0] == 'anim':
        cmd_anim(int(a[1]), a[2])
    else:
        raise SystemExit(__doc__)


if __name__ == '__main__':
    main()
