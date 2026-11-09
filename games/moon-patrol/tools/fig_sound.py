#!/usr/bin/env python3
"""Figures and rendered audio of docs/09-sound.md (writer mpB). Output in docs/img/sound/.

  python3 tools/fig_sound.py tune     tune.png     the in-game tune ($B4E6) as a piano roll: one column a word
  python3 tools/fig_sound.py beeper   beeper.png   the speaker bit against T-states over three frames: one note,
                                                   the silence after it, and a rest; the CPU time each takes
  python3 tools/fig_sound.py bonus    bonus.png    the bonus screen's sounds: BonusTune $A773 (22 notes), the time
                                                   bonus fanfare (BonusBeep), the blip of each bonus second
  python3 tools/fig_sound.py wav      tune.wav, bonus-tune.wav, fanfare.wav, no-bonus.wav, blip.wav: the speaker
                                      bit rendered from the same model, 44 100 Hz mono 16 bit (never played here)
  python3 tools/fig_sound.py all

The model: BEEPER $03B5 (the 48K ROM) gives one full cycle in 8 x (HL + 30.125) T-states and DE cycles; a frame is
69 888 T at 3.5 MHz; TunePlayer $7F47 starts a note about 300 T after every third frame interrupt. The blip's
half-cycle lengths are the 48K ROM bytes $0B16-$0B24, read from the ROM file given by MPB_ROM48 (default: the
unreal-ng ROM folder). Data: work/mkgame/original.bin.
"""
import math
import os
import struct
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_rendering as R  # noqa: E402

K = R.K
MEM = R.MEM
W = R.W
F, FB, FS = R.F, R.FB, R.FS
R.OUT = os.path.join(R.CASE, 'docs', 'img', 'sound')
CLOCK = 3500000
FRAME = 69888
RATE = 44100
ROM48 = os.environ.get('MPB_ROM48', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/data/rom/48.rom')
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def word(a):
    return MEM[a] | MEM[a + 1] << 8


def tune_words():
    out = []
    a = 0xB4E6
    while True:
        w = word(a)
        if w == 0xFFFF:
            return out
        out.append(w)
        a += 2


def tune_note(w):
    """A tune word -> (period HL, cycles n) or None for a rest ($7F7C-$7F88)."""
    if w == 0:
        return None
    hl = w - 1
    h = hl >> 8
    n = 1
    while n * h < 16:
        n += 1
    return hl, n


def freq(hl):
    return CLOCK / (8 * (hl + 30.125))


def name(f):
    m = round(69 + 12 * math.log2(f / 440.0))
    return '%s%d' % (NAMES[m % 12], m // 12 - 1), m


def bonus_notes():
    out = []
    a = 0xA773
    for _ in range(22):
        out.append((word(a), MEM[a + 2]))
        a += 4
    return out


def blip_lengths():
    rom = open(ROM48, 'rb').read()
    return list(rom[0x0B16:0x0B16 + 15])


def blip_half_t(v):
    # $A5F5-$A60E: v x (LD B,10 7 + DJNZ 9x13+8 + DEC A 4 + JR NZ 12) + $77 x (7 + 8 + 4 + 12) + the rest
    return v * (7 + 125 + 4 + 12) + 0x77 * 31 + 7 + 6 + 4 + 11 + 4 + 4 + 12


# ---------------------------------------------------------------- figures
def fig_tune():
    ws = tune_words()
    notes = [tune_note(w) for w in ws]
    ms = [name(freq(n[0]))[1] for n in notes if n]
    lo, hi = min(ms), max(ms)
    top, left = 80, 70
    rowh = 18
    ph = (hi - lo + 1) * rowh
    im, d = R.canvas(top + ph + 120)
    R.title(d, 'The in-game tune at $B4E6: %d words, one every 3 interrupts (60 ms), then $FFFF' % len(ws),
            'One column a word, 2.5 px; a bar is a note (its pitch from BEEPER\'s period), a gap is a rest (word 0)')
    pw = len(ws) * 2.5
    for m in range(lo, hi + 1):
        y = top + (hi - m) * rowh
        if NAMES[m % 12] in ('C', 'E', 'G', 'A'):
            d.text((16, y), '%s%d' % (NAMES[m % 12], m // 12 - 1), font=FS, fill=K.DIM)
        d.line([left, y + rowh, left + pw, y + rowh], fill=(32, 32, 44))
    for i, n in enumerate(notes):
        if not n:
            continue
        m = name(freq(n[0]))[1]
        x = left + i * 2.5
        y = top + (hi - m) * rowh
        d.rectangle([x, y + 3, x + 1.8, y + rowh - 3], fill=(120, 200, 255))
    for s in range(0, len(ws) + 1, 48):
        x = left + s * 2.5
        d.line([x, top, x, top + ph], fill=(60, 60, 80))
        d.text((x - 8, top + ph + 6), str(s), font=FS, fill=K.DIM)
    d.text((left, top + ph + 30), 'words (x 3 frames: 48 words = 2.9 s); the whole tune %.1f s at 50 interrupts a second'
           % (len(ws) * 3 / 50.0), font=FS, fill=K.TEXT)
    rests = sum(1 for n in notes if not n)
    d.text((left, top + ph + 54), '%d notes, %d rests, %d different periods; each note sounds only 10-15 ms of its 60 ms'
           % (len(notes) - rests, rests, len(set(n[0] for n in notes if n))), font=FS, fill=K.TEXT)
    R.save(im.crop((0, 0, W, top + ph + 84)), 'tune.png')


def fig_beeper():
    w0 = tune_words()[0]
    hl, n = tune_note(w0)
    cyc = 8 * (hl + 30.125)
    im, d = R.canvas(560)
    R.title(d, 'The speaker bit over three frames: a note of the tune, then silence; below, a rest',
            'T-states along the bottom (69 888 a frame); high = the speaker bit 4 of port $FE set')
    left, pw = 60, 960
    span = 3 * FRAME
    def X(t):
        return left + t * pw / span
    def track(y, label, edges, busy):
        d.text((16, y - 56), label, font=FS, fill=K.TEXT)
        for b0, b1, c in busy:
            d.rectangle([X(b0), y - 22, X(b1), y + 22], fill=c)
        lvl = 0
        t0 = 0
        pts = []
        for t in edges + [span]:
            pts += [(X(t0), y + (12 if lvl == 0 else -12)), (X(t), y + (12 if lvl == 0 else -12))]
            t0 = t
            lvl ^= 1
        d.line(pts, fill=(255, 255, 255), width=1)
        for f in range(4):
            d.line([X(f * FRAME), y - 26, X(f * FRAME), y + 26], fill=(230, 210, 60), width=2)
    start = 300
    edges = [start + k * cyc / 2 for k in range(2 * n + 1)]
    t_note = n * cyc
    track(150, 'A note: word $%04X, period $%04X (%.0f Hz), n = %d cycles: %.0f T = %.1f ms in the interrupt'
          % (w0, hl, freq(hl), n, t_note, t_note / CLOCK * 1000), edges[:-1],
          [(start, start + t_note, (60, 40, 40))])
    track(300, 'A rest (word 0): the delay loop $05C0 x 26 T = 38 272 T, the speaker silent', [],
          [(start, start + 0x05C0 * 26, (60, 40, 40))])
    for i, t in enumerate(['yellow lines: the frame interrupts; TunePlayer takes a word on every third one',
                           'dark red: the time the interrupt handler holds the CPU for the note or the rest (DI)',
                           'the next two interrupts only count (TuneDivider $B240) and run the clock: about 300 T each',
                           'a note is %d full cycles: the waveform above is drawn to scale' % n]):
        d.text((16, 360 + i * 24), t, font=FS, fill=K.DIM if i else (230, 210, 60))
    d.text((16, 470), 'Cost: a note or a rest about 36 000-50 000 T every 3 frames, 17-24 % of the CPU; the game\'s main',
           font=FS, fill=K.TEXT)
    d.text((16, 494), 'loop gets the rest. With the tune off (T key) a note becomes a rest: the same cost, silent.',
           font=FS, fill=K.TEXT)
    R.save(im.crop((0, 0, W, 530)), 'beeper.png')


def fig_bonus():
    notes = bonus_notes()
    im, d = R.canvas(640)
    R.title(d, 'The bonus screen\'s sounds: BonusTune $A773, the fanfare, the blip of each second',
            'Top: the 22 notes, length to scale (ms) and pitch; middle: the fanfare; bottom: one blip, to scale')
    left, top = 70, 80
    tot = sum(c / freq(p) for p, c in notes)
    pw = 940
    ms_all = [name(freq(p))[1] for p, _ in notes]
    lo, hi = min(ms_all), max(ms_all)
    rowh = 16
    t = 0.0
    for p, c in notes:
        dur = c / freq(p)
        nm, m = name(freq(p))
        x0 = left + t / tot * pw
        x1 = left + (t + dur) / tot * pw
        y = top + (hi - m) * rowh
        d.rectangle([x0 + 1, y + 2, x1 - 1, y + rowh - 2], fill=(120, 200, 255))
        t += dur
    for m in range(lo, hi + 1):
        if NAMES[m % 12] in ('C', 'E', 'G', 'A'):
            d.text((16, top + (hi - m) * rowh), '%s%d' % (NAMES[m % 12], m // 12 - 1), font=FS, fill=K.DIM)
    yb = top + (hi - lo + 1) * rowh + 8
    d.text((left, yb), 'BonusTune: 22 notes, %.2f s, played back to back with BEEPER (IM 1, no game running)' % tot,
           font=FS, fill=K.TEXT)
    y2 = yb + 50
    f1 = freq(0x01B7)
    d.text((16, y2), 'Fanfare (BonusBeep $A690, HL $01B7, DE $00A8): %.0f Hz for %.0f ms, 7 frames (140 ms) silent, '
           'again' % (f1, 0xA8 / f1 * 1000), font=FS, fill=K.TEXT)
    sc = pw / 0.6
    for k, (a, b) in enumerate(((0, 0xA8 / f1), (0xA8 / f1 + 0.14, 2 * 0xA8 / f1 + 0.14))):
        d.rectangle([left + a * sc, y2 + 28, left + b * sc, y2 + 46], fill=(120, 200, 255))
    d.text((left + pw - 120, y2 + 28), '0.6 s', font=FS, fill=K.DIM)
    f2 = freq(0x1BBA)
    d.text((16, y2 + 60), 'No time bonus (HL $1BBA, DE $000B): %.0f Hz for %.0f ms, twice: not executed in any recording'
           % (f2, 11 / f2 * 1000), font=FS, fill=K.TEXT)
    y3 = y2 + 120
    ls = blip_lengths()
    halves = [blip_half_t(v) for v in ls]
    tt = sum(halves)
    d.text((16, y3), 'Blip ($A5E5-$A610, DI): 15 half-cycles timed by the ROM bytes $0B16 (%s): %.1f ms'
           % (' '.join('%02X' % v for v in ls[:6]) + ' ...', tt / CLOCK * 1000), font=FS, fill=K.TEXT)
    t0, lvl, pts = 0, 0, []
    for h in halves:
        pts += [(left + t0 / tt * pw, y3 + 60 - lvl * 24), (left + (t0 + h) / tt * pw, y3 + 60 - lvl * 24)]
        t0 += h
        lvl ^= 1
    d.line(pts, fill=(255, 255, 255), width=2)
    d.text((16, y3 + 80), 'one blip a bonus second, then 4 frames; uneven half-cycles (ROM code bytes as a table): a buzz', font=FS, fill=K.DIM)
    R.save(im.crop((0, 0, W, y3 + 110)), 'bonus.png')


# ---------------------------------------------------------------- audio
def render(edges, total_t, name_):
    """edges: sorted T-states where the speaker bit flips (starting low)."""
    n = int(total_t / CLOCK * RATE) + 1
    out = bytearray()
    lvl = 0
    k = 0
    for i in range(n):
        t = i * CLOCK / RATE
        while k < len(edges) and edges[k] <= t:
            lvl ^= 1
            k += 1
        out += struct.pack('<h', 9000 if lvl else -9000)
    path = os.path.join(R.OUT, name_)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(out))
    print(path, '%.2f s' % (n / RATE))


def beeper_edges(t, hl, n):
    half = 4 * (hl + 30.125)
    return [t + k * half for k in range(2 * n)], t + 2 * n * half


def wav_all():
    os.makedirs(R.OUT, exist_ok=True)
    edges = []
    t = 0
    for w in tune_words():
        nt = tune_note(w)
        if nt:
            e, _ = beeper_edges(t + 300, *nt)
            edges += e
        t += 3 * FRAME
    render(edges, t, 'tune.wav')
    edges, t = [], 0
    for p, c in bonus_notes():
        e, t = beeper_edges(t, p, c)
        edges += e
    render(edges, t + FRAME, 'bonus-tune.wav')
    for nm, hl, de in (('fanfare.wav', 0x01B7, 0xA8), ('no-bonus.wav', 0x1BBA, 0x0B)):
        e1, t1 = beeper_edges(0, hl, de)
        e2, t2 = beeper_edges(t1 + 7 * FRAME, hl, de)
        render(e1 + e2, t2 + FRAME, nm)
    edges, t = [], 0
    for sec in range(3):
        for h in [blip_half_t(v) for v in blip_lengths()]:
            t += h
            edges.append(t)
        t += 4 * FRAME
    render(edges, t, 'blip.wav')


FIGS = {'tune': fig_tune, 'beeper': fig_beeper, 'bonus': fig_bonus, 'wav': wav_all}

if __name__ == '__main__':
    names = sys.argv[1:] or ['all']
    for nm in (FIGS if names == ['all'] else names):
        FIGS[nm]()
