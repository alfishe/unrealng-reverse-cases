#!/usr/bin/env python3
"""Doc 09's sound: every beeper effect and the title tune run by SkoolKit's simulator over the entry image, the
speaker bit (bit 4 of port $FE) recorded at the T-state of each OUT, then rendered or drawn.

    python3 tools/sound_render.py wav DIR            # one WAV per effect, the tune as an MP3 (lame -V 4), into DIR (never played here)
    python3 tools/sound_render.py table              # each effect's T-states, frames, half-cycles, pitch range
    python3 tools/sound_render.py effects OUT        # pitch against time of every effect (a PNG)
    python3 tools/sound_render.py tune OUT           # the title tune as a three-voice piano roll (a PNG)
    python3 tools/sound_render.py anim OUT [NAME]    # an effect's routine against the beeper port (a GIF)

Needs SKOOLKIT_VENV (work/env.sh). The simulator counts T-states without contention (the routines run from
uncontended memory and write no screen, so the 48K's timing is the same). A pitch is 3 500 000 / (2 x the T of a
half-cycle). The WAVs are 44 100 Hz, 16-bit mono: the speaker level averaged over each sample.
"""
import math
import os
import struct
import sys
import wave

V = os.environ.get('SKOOLKIT_VENV')
if V:
    for d in os.listdir(os.path.join(V, 'lib')):
        sys.path.insert(0, os.path.join(V, 'lib', d, 'site-packages'))
from skoolkit.simulator import Simulator  # noqa: E402

from PIL import Image, ImageDraw  # noqa: E402

import figlib  # noqa: E402

CLOCK = 3500000
FRAME = 69888
RATE = 44100
IMG = bytes(figlib.image())

# name, entry, registers, label, caller
EFFECTS = [
    ('burn', 0xA8C0, {'HL': 0x81D4}, 'BurnSound $81D4 (sweep)', 'PassEnd $865A: a cell starts to burn'),
    ('mine', 0xA8C0, {'HL': 0x81D9}, 'MineSound $81D9 (sweep)', 'interrupt, SoundFlags bit 1: the beam on a mine'),
    ('laser-back', 0xA8C0, {'HL': 0x81DE}, 'LaserBackSound $81DE (sweep)', 'interrupt, bit 2: the beam in the laser'),
    ('burning', 0xA8C0, {'HL': 0x81E3}, 'BurningNoise $81E3 (noise)', 'interrupt, bit 3: a cell burning'),
    ('charge', 0xA8C0, {'HL': 0x81E8}, 'ChargeWarble $81E8 (tone)', 'interrupt, bit 4: the laser charging'),
    ('gremlin', 0xA8C0, {'HL': 0x81ED}, 'GremlinSound $81ED (sweep)', 'PassEnd $85B5, LevelCompletePause $8850'),
    ('charged', 0xA8C0, {'HL': 0x81F2}, 'ChargedSound $81F2 (sweep)', 'ChargeLaser $A60F, the ending'),
    ('contact', 0xA8C0, {'HL': 0x81F7}, 'ContactSound $81F7 (sweep)', 'LevelComplete $87E6: CONTACT!'),
    ('receiver-open', 0xA8C0, {'HL': 0x8660}, 'ReceiverOpenSound $8660 (sweep)', 'PassEnd $85E7: the door opens'),
    ('life-lost', 0xA8C0, {'HL': 0x8665}, 'LifeLostSound $8665 (sweep)', 'LoseLife $8683, $86C4'),
    ('energy-drained', 0xA8C0, {'HL': 0x8695}, 'EnergyDrainedSound $8695 (sweep)', 'LoseLifeDrained $869D'),
    ('tone-bonus', 0xA843, {'HL': 0x0A3C}, 'TwoTone $0A3C', 'LevelCompleteEnergy $880E: a bonus step'),
    ('tone-life', 0xA843, {'HL': 0x0204}, 'TwoTone $0204', 'LevelCompleteLife $8853 (HL left by the sweep)'),
    ('tone-pause', 0xA843, {'HL': 0x0F3C}, 'TwoTone $0F3C', 'the pause $9743, $97C4'),
    ('tone-option', 0xA843, {'HL': 0x1478}, 'TwoTone $1478', 'the options: a control chosen $A829'),
    ('tone-start', 0xA843, {'HL': 0x28A0}, 'TwoTone $28A0', 'the options: 5 DEMO, 6 PRACTICE or 7 START GAME $A7FF'),
    ('tone-name', 0xA843, {'HL': 0x3250}, 'TwoTone $3250', 'HallOfFame $9CA9: enter your name'),
    ('tone-menu', 0xA843, {'HL': 0x465A}, 'TwoTone $465A', 'the options screen $A75E, the name entered $9DDC'),
    ('tone-abort', 0xA843, {'HL': 0xC814}, 'TwoTone $C814', 'AbortGame $9828, game over $870E'),
]


class Port:
    def __init__(self):
        self.outs = []

    def write_port(self, registers, port, value, *rest):
        if port & 1 == 0:
            self.outs.append((registers[25] + 11, (value >> 4) & 1, registers[24]))


def run(entry, regs, mem=None, trace_pc=False):
    """Run a routine to its RET; (T, the OUTs as (T, level, pc), the PCs as (T, pc) if asked)."""
    m = bytearray(mem or IMG)
    sp = 0x5F00
    m[sp] = m[sp + 1] = 0
    r = {'PC': entry, 'SP': sp}
    r.update(regs)
    s = Simulator(m, r)
    p = Port()
    s.set_tracer(p)
    pcs = []
    while s.registers[24] != 0:
        if trace_pc:
            pcs.append((s.registers[25], s.registers[24], tuple(s.registers[:8])))
        s.run()
    return s.registers[25], p.outs, pcs


def edges(outs):
    """The level changes only: [(T, level)], starting at level 0 at T 0."""
    ev = []
    last = 0
    for t, v, _ in outs:
        if v != last:
            ev.append((t, v))
            last = v
    return ev


def halfcycles(ev, total):
    """(T at the middle, the half-cycle's T) of each level change to the next."""
    hs = []
    for (t0, _), (t1, _) in zip(ev, ev[1:] + [(total, 0)]):
        if t1 > t0:
            hs.append(((t0 + t1) / 2, t1 - t0))
    return hs


def tune_events():
    """The 176 notes one after another: (edges, total T, per note (start T, end T, periods))."""
    ev = []
    t0 = 0
    notes = []
    last = 0
    for n in range(0xB0):
        a = 0xADF0 + 3 * n
        regs = {'IX': a, 'H': IMG[a], 'L': IMG[a + 1], 'D': IMG[a + 2], 'BC': 0x1770}
        t, outs, _ = run(0xADA7, regs)
        for tt, v, _ in outs:
            if v != last:
                ev.append((t0 + tt, v))
                last = v
        notes.append((t0, t0 + t, IMG[a:a + 3]))
        t0 += t
    return ev, t0, notes


def write_wav(path, ev, total, amp=0.35):
    n = int(total * RATE / CLOCK) + 1
    per = CLOCK / RATE
    buf = bytearray()
    k = 0
    level = 0
    for i in range(n):
        a, b = i * per, (i + 1) * per
        high = 0.0
        t = a
        while k < len(ev) and ev[k][0] < b:
            if level:
                high += ev[k][0] - t
            t = max(t, ev[k][0])
            level = ev[k][1]
            k += 1
        if level:
            high += b - t
        v = (high / per - 0.5) * 2 * amp
        buf += struct.pack('<h', int(v * 32767))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(buf))


def cmd_wav(d):
    os.makedirs(d, exist_ok=True)
    for name, entry, regs, label, _ in EFFECTS:
        t, outs, _ = run(entry, regs)
        write_wav(os.path.join(d, name + '.wav'), edges(outs), t + 2000)
        print('%-16s %8d T' % (name, t))
    ev, total, _ = tune_events()
    wav = os.path.join(d, 'title-tune.wav')
    write_wav(wav, ev, total)
    # the 35 s tune as an MP3 (lame -V 4); the effects, all under a second, stay WAV
    import subprocess
    subprocess.run(['lame', '--quiet', '-V', '4', wav, os.path.join(d, 'title-tune.mp3')], check=True)
    os.remove(wav)
    print('title-tune %d T %.1f s (MP3)' % (total, total / CLOCK))


def stats():
    rows = []
    for name, entry, regs, label, caller in EFFECTS:
        t, outs, _ = run(entry, regs)
        ev = edges(outs)
        hs = halfcycles(ev, t)
        fr = [CLOCK / (2 * h) for _, h in hs if h > 0]
        rows.append((name, label, caller, t, len(ev), min(fr) if fr else 0, max(fr) if fr else 0, hs, ev))
    return rows


def cmd_table():
    for name, label, caller, t, n, lo, hi, _, _ in stats():
        print('%-16s %8d T %6.2f fr %5d edges %7.0f-%7.0f Hz  %s' % (name, t, t / FRAME, n, lo, hi, label))


def cmd_effects(out):
    rows = stats()
    W = 1050
    rh = 62
    x0, x1 = 300, W - 20
    o = Image.new('RGB', (W, 90 + rh * len(rows) + 50), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'Every beeper effect: the pitch of each half-cycle against time', 17, figlib.ACCENT)
    figlib.text(d, (10, 32), 'SkoolKit simulator over the image; x: 0 to the effect\'s own length (right), y: pitch '
                '100 Hz (bottom) to 20 kHz (top), log scale', 12, figlib.DIM)
    lf0, lf1 = math.log(100), math.log(20000)
    for i, (name, label, caller, t, n, lo, hi, hs, ev) in enumerate(rows):
        y = 60 + i * rh
        figlib.text(d, (10, y + 2), label, 12, figlib.FG)
        figlib.text(d, (10, y + 18), caller, 10, figlib.DIM)
        figlib.text(d, (10, y + 34), '%d T = %.2f frames, %d edges' % (t, t / FRAME, n), 10, figlib.DIM)
        d.rectangle([x0, y, x1, y + rh - 8], outline=(60, 60, 70))
        for f in (1000, 10000):
            yy = y + rh - 8 - (math.log(f) - lf0) / (lf1 - lf0) * (rh - 8)
            d.line([x0, yy, x1, yy], fill=(45, 45, 55))
        for tm, h in hs:
            f = CLOCK / (2 * h)
            f = min(max(f, 100), 20000)
            xx = x0 + tm / t * (x1 - x0)
            yy = y + rh - 8 - (math.log(f) - lf0) / (lf1 - lf0) * (rh - 8)
            d.rectangle([xx - 1, yy - 1, xx + 1, yy + 1], fill=(120, 220, 255))
    y = 60 + len(rows) * rh + 4
    figlib.text(d, (10, y), 'Grey lines: 1 kHz and 10 kHz. A sweep is a slope, a TwoTone two nearly equal lines (their '
                'beat), the noise a cloud.', 12, figlib.DIM)
    o.save(out)


NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def note_of(freq):
    m = 69 + 12 * math.log2(freq / 440)
    k = int(round(m))
    return '%s%d' % (NOTE_NAMES[k % 12], k // 12 - 1), m


def cmd_tune(out):
    # a loop of PlayNote with no voice firing is 108 T; a voice of period p fires every p loops
    W = 1050
    H = 560
    o = Image.new('RGB', (W, H), figlib.BG)
    d = ImageDraw.Draw(o)
    figlib.text(d, (10, 8), 'TitleTuneData $ADF0: 176 notes x 3 voices, as PlayNote $ADA7 plays them', 17,
                figlib.ACCENT)
    figlib.text(d, (10, 32), 'x: the note (about 10 frames each, 35 s in all); y: the pitch 3 500 000 / (108 x period)'
                ' as a MIDI note; the three voices in three colours', 12, figlib.DIM)
    cols = [(255, 120, 120), (120, 220, 120), (120, 170, 255)]
    x0, x1, y0, y1 = 60, W - 20, 70, H - 70
    ms = []
    for n in range(0xB0):
        for v in range(3):
            p = IMG[0xADF0 + 3 * n + v]
            ms.append(note_of(CLOCK / (108 * p))[1])
    lo, hi = math.floor(min(ms)) - 1, math.ceil(max(ms)) + 1
    for m in range(lo, hi + 1):
        yy = y1 - (m - lo) / (hi - lo) * (y1 - y0)
        if m % 12 == 0:
            d.line([x0, yy, x1, yy], fill=(60, 60, 72))
            figlib.text(d, (8, yy - 7), 'C%d' % (m // 12 - 1), 11, figlib.DIM)
        elif m % 12 in (1, 3, 6, 8, 10):
            d.line([x0, yy, x1, yy], fill=(34, 34, 42))
    cw = (x1 - x0) / 0xB0
    for n in range(0xB0):
        for v in range(3):
            m = ms[3 * n + v]
            yy = y1 - (m - lo) / (hi - lo) * (y1 - y0)
            d.rectangle([x0 + n * cw, yy - 2, x0 + (n + 1) * cw - 1, yy + 2], fill=cols[v])
    for n in range(0, 0xB0 + 1, 16):
        xx = x0 + n * cw
        d.line([xx, y1, xx, y1 + 5], fill=figlib.DIM)
        figlib.text(d, (xx - 8, y1 + 8), str(n), 11, figlib.DIM)
    for v in range(3):
        d.rectangle([x0 + v * 200, H - 34, x0 + v * 200 + 14, H - 20], fill=cols[v])
        figlib.text(d, (x0 + v * 200 + 20, H - 36), 'voice %d (IX+%d, %s)' % (v + 1, v, 'HLD'[v]), 12, figlib.FG)
    figlib.text(d, (x0 + 640, H - 36), 'notes 64-79: three voices a period apart', 12, figlib.DIM)
    o.save(out)


LISTING = [
    (0xA85E, 'LD B,(HL)', 'the record: B = the step'),
    (0xA85F, 'INC HL', ''),
    (0xA860, 'LD C,(HL)', 'C = half-cycles a step'),
    (0xA861, 'INC HL', ''),
    (0xA862, 'LD D,(HL)', 'D = the first delay'),
    (0xA863, 'INC HL', ''),
    (0xA864, 'LD E,(HL)', 'E = the steps'),
    (0xA865, 'LD H,B', ''),
    (0xA866, 'LD L,C', ''),
    (0xA867, 'XOR A', 'SweepStepLoop'),
    (0xA868, 'LD C,L', ''),
    (0xA869, 'XOR $18', 'SweepHalfCycle: flip the speaker'),
    (0xA86B, 'LD B,D', ''),
    (0xA86C, 'OUT ($FE),A', 'SweepDelay: the port, D times'),
    (0xA86E, 'DJNZ SweepDelay', ''),
    (0xA870, 'DEC C', ''),
    (0xA871, 'JR NZ,SweepHalfCycle', ''),
    (0xA873, 'LD A,D', 'the delay D - H'),
    (0xA874, 'SUB H', ''),
    (0xA875, 'LD D,A', ''),
    (0xA876, 'DEC E', ''),
    (0xA877, 'JR NZ,SweepStepLoop', ''),
    (0xA879, 'RET', ''),
]


def cmd_anim(out, name='gremlin'):
    ent = [e for e in EFFECTS if e[0] == name][0]
    hl = ent[2]['HL']
    total, outs, pcs = run(0xA85E, {'HL': hl + 1}, trace_pc=True)
    ev = edges(outs)
    rec = IMG[hl:hl + 5]
    W, H = 1050, 650
    pictures = 80
    frames = []
    k = 0
    for i in range(1, pictures + 1):
        T = total * i / pictures
        while k + 1 < len(pcs) and pcs[k + 1][0] <= T:
            k += 1
        t, pc, regs = pcs[k]
        o = Image.new('RGB', (W, H), figlib.BG)
        d = ImageDraw.Draw(o)
        figlib.text(d, (10, 8), 'PlaySweep $A85E playing %s against port $FE bit 4' % ent[3], 17, figlib.ACCENT)
        figlib.text(d, (10, 32), 'record %s: kind 1, H %d (the step), L %d (half-cycles a step), D %d (first delay), '
                    'E %d (steps)' % (' '.join('%02X' % b for b in rec), rec[1], rec[2], rec[3], rec[4]), 12, figlib.DIM)
        for j, (a, ins, cm) in enumerate(LISTING):
            y = 60 + j * 19
            if a == pc:
                d.rectangle([8, y - 1, 520, y + 16], fill=(70, 60, 20))
            figlib.text(d, (12, y), '$%04X  %-22s %s' % (a, ins, cm), 12, figlib.FG if a == pc else figlib.DIM)
        # registers: A F B C D E H L at indexes 0..7
        A, F, B, C, D, E, Hh, L = regs
        bx = 560
        figlib.text(d, (bx, 62), 'T %7d of %d (%.2f frames)' % (t, total, total / FRAME), 14, figlib.FG)
        for j, (lab, val) in enumerate([('D the delay', D), ('E steps left', E), ('C half-cycles left', C),
                                        ('B the DJNZ count', B), ('A the speaker bits', A)]):
            figlib.text(d, (bx, 92 + j * 24), '%-20s %3d  $%02X' % (lab, val, val), 13, figlib.FG)
        lvl = 0
        for tt, v in ev:
            if tt <= t:
                lvl = v
        d.rectangle([bx, 222, bx + 140, 262], fill=(240, 240, 120) if lvl else (60, 60, 70))
        figlib.text(d, (bx + 150, 232), 'the speaker now: %s' % ('in (bit 4 = 1)' if lvl else 'out (bit 4 = 0)'),
                    13, figlib.FG)
        # the port trace, whole length, drawn up to T
        px0, px1, py0, py1 = 20, W - 20, 590, 638
        figlib.text(d, (px0, 532), 'port $FE bit 4, the whole effect (%d T); the cursor at the routine\'s T' % total,
                    12, figlib.DIM)
        d.rectangle([px0, py0 - 30, px1, py1], outline=(60, 60, 70))
        last_x, last_y = px0, py1
        lv = 0
        for tt, v in ev + [(t, None)]:
            if tt > t:
                tt = t
            x = px0 + tt / total * (px1 - px0)
            y = py1 if lv == 0 else py0 - 20
            d.line([last_x, y, x, y], fill=(120, 220, 255))
            if v is None:
                break
            ny = py1 if v == 0 else py0 - 20
            d.line([x, y, x, ny], fill=(120, 220, 255))
            last_x, lv = x, v
        cx = px0 + t / total * (px1 - px0)
        d.line([cx, py0 - 30, cx, py1], fill=figlib.ACCENT)
        # the half-cycle lengths so far (the pitch rising as they shorten)
        hs = halfcycles([e for e in ev if e[0] <= t], t)
        figlib.text(d, (bx, 280), 'each half-cycle\'s T so far (shorter = higher pitch)', 12, figlib.DIM)
        if hs:
            mx = max(h for _, h in halfcycles(ev, total))
            for j, (_, h) in enumerate(hs):
                x = bx + j * (460 / max(1, len(halfcycles(ev, total))))
                d.line([x, 480, x, 480 - h / mx * 180], fill=(255, 150, 90), width=2)
        frames.append(o.convert('P', palette=Image.ADAPTIVE, colors=64))
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=[90] * (pictures - 1) + [1500], loop=0,
                   optimize=True)
    print('%s: %d T, %d edges' % (name, total, len(ev)))


if __name__ == '__main__':
    c = sys.argv[1]
    if c == 'wav':
        cmd_wav(sys.argv[2])
    elif c == 'table':
        cmd_table()
    elif c == 'effects':
        cmd_effects(sys.argv[2])
    elif c == 'tune':
        cmd_tune(sys.argv[2])
    elif c == 'anim':
        cmd_anim(sys.argv[2], *(sys.argv[3:4]))
