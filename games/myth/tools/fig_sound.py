#!/usr/bin/env python3
"""Doc 09's figures and sounds: the 13 AY effects stepped as ChannelStep steps them, their WAV renders, and the AY
registers per interrupt from a trace.

    python3 tools/fig_sound.py chart docs/img/sound/effects.png
    python3 tools/fig_sound.py wav docs/audio
    python3 tools/fig_sound.py regs WORK F0 F1 docs/img/play/ay-registers.gif
    python3 tools/fig_sound.py table

The effects are read from build/res/resident/effects.bin (EffectData `$F54D`, 13 effects: channel, noise flag,
segments, volume x 16, period (word), then 3 bytes a segment: frames, period change, volume change, both signed).
step() follows ChannelStep `$F7DE` and AyFrame `$F78A` instruction by instruction: on each interrupt the volume
register is written first (twice: WriteVolume falls into AyWrite, then CALL AyWrite), then the frame count goes down,
then the period and the volume move, and only then AyFrame writes the period. So the first period heard is already
moved once. chart draws, per effect, the AY volume (0-15) and the period written at each interrupt.
wav renders each effect at 44 100 Hz with one interrupt every 1/50 s, an AY clock of 1 773 400 Hz, square tones, a
17-bit noise generator and the AY's volume curve. The files are written, never played.
regs traces frames F0 - 2 to F1 of the recording held by the re_session work folder WORK (kitlib.load_trace, kept in
WORK/traces/), reads its OUT writes (`$FFFD` the register, `$BFFD` the value) and draws the 14 registers
after each frame, the registers written in that frame lit, and the frames with no interrupt (DI) marked.
table prints each effect's decoded bytes and its frames, for the doc.
"""

import os
import struct
import sys
import wave

from PIL import Image, ImageDraw

from figmyth import F, TEXT, DIM, HI, PANEL, COLOURS, CASE, canvas, save, kitlib

CLOCK = 1773400
RATE = 44100
FRAME = 1 / 50
AY_VOL = [0.0, 0.0137, 0.0205, 0.0291, 0.0423, 0.0618, 0.0847, 0.1369, 0.1691, 0.2647, 0.3527, 0.4499, 0.5704,
          0.6873, 0.8482, 1.0]
STARTS = [0x00, 0x09, 0x12, 0x1B, 0x24, 0x2D, 0x42, 0x4E, 0x57, 0x60, 0x6C, 0x78, 0x81]
USE = ['Dameron form beaten; burst missile', 'an actor bursts into particles',
       'a strike lands; Dameron fires', 'a piece rises; a fragment bounces',
       'an item taken; an extra life', 'a fragment picked up', 'an aimed shot; the demon\'s burst',
       'a life lost', 'the hero throws or fires', 'the pool (2); the rain (3)',
       'a splash (stage 2)', 'ammunition added', 'a piece taken; a fade-in (4)']


def effects():
    data = open(os.path.join(CASE, 'build', 'res', 'resident', 'effects.bin'), 'rb').read()
    out = []
    for s in STARTS:
        ch, noise, n, vol = data[s:s + 4]
        period = data[s + 4] | data[s + 5] << 8
        segs = [(data[s + 6 + 3 * k], struct.unpack('b', data[s + 7 + 3 * k:s + 8 + 3 * k])[0],
                 struct.unpack('b', data[s + 8 + 3 * k:s + 9 + 3 * k])[0]) for k in range(n)]
        out.append(dict(addr=0xF54D + s, ch=ch, noise=noise, vol=vol, period=period, segs=segs,
                        raw=data[s:s + 6 + 3 * n]))
    return out


def step(e):
    """[(volume register, period written or None)] for each interrupt, as ChannelStep and AyFrame do it"""
    segs_left, seg, frames = len(e['segs']), 0, e['segs'][0][0]
    period, vol = e['period'], e['vol']
    out = []
    while True:
        written = vol >> 4
        frames = (frames - 1) & 0xFF
        while frames == 0:
            segs_left -= 1
            if segs_left == 0:
                out.append((written, None, True))
                return out
            seg += 1
            frames = e['segs'][seg][0]
            written = vol >> 4          # ChannelStep again: the volume written again, the new segment's count
            frames = (frames - 1) & 0xFF
        dp, dv = e['segs'][seg][1], e['segs'][seg][2]
        period = (period + dp) & 0xFFFF
        vol = (vol + dv) & 0xFF
        out.append((written, period, False))


def ay_period(e, p):
    if e['noise']:
        return (p & 0x1F) or 1
    return (p & 0x0FFF) or 1


def hz(e, p):
    return CLOCK / (16 * ay_period(e, p))


def chart(out):
    effs = effects()
    cols, pw, ph = 3, 330, 150
    rows = (len(effs) + cols - 1) // cols
    im, d, y0 = canvas(120 + rows * (ph + 70), 'The 13 effects, one interrupt a step, as ChannelStep plays them',
                       'Bars: the AY volume (0-15) written at each interrupt.\nLine: the AY period the frame sounds '
                       '(a tone: 12 bits; a noise: 5 bits, reg 6), scaled from its lowest to its highest.\nHollow bar: the last interrupt, the volume written and then 0 '
                       '(ChannelDone).\nTitle: the effect, its channel, tone or noise; '
                       'under it what plays it. From build/res/resident/effects.bin (EffectData $F54D).')
    for i, e in enumerate(effs):
        x0 = 16 + (i % cols) * (pw + 12)
        y = y0 + 6 + (i // cols) * (ph + 70)
        st = step(e)
        c = COLOURS[i % len(COLOURS)]
        d.text((x0, y), 'effect %d: channel %s, %s, %d interrupts' % (
            i, 'ABC'[e['ch'] - 1], 'noise' if e['noise'] else 'tone', len(st)), font=F(13), fill=TEXT)
        d.text((x0, y + 18), USE[i], font=F(13), fill=DIM)
        by = y + 40
        d.rectangle((x0, by, x0 + pw, by + ph - 40), fill=PANEL)
        n = len(st)
        bw = max(1, (pw - 4) // max(n, 1))
        bh = ph - 50
        periods = [ay_period(e, p) for _, p, _ in st if p is not None]
        lo = min(periods) if periods else 0
        top = max(periods) if periods else 1
        span = max(top - lo, 1)
        pts = []
        for k, (v, p, last) in enumerate(st):
            bx = x0 + 2 + k * bw
            if last:   # the volume written, then ChannelDone's 0 a few hundred T later: silent
                d.rectangle((bx, by + 4 + bh - v * bh // 15, bx + max(bw - 2, 1), by + 4 + bh), outline=c)
            else:
                d.rectangle((bx, by + 4 + bh - v * bh // 15, bx + max(bw - 2, 1), by + 4 + bh), fill=c)
            if p is not None:
                pts.append((bx + bw // 2, by + 4 + bh - 6 - (ay_period(e, p) - lo) * (bh - 12) // span - (0 if top > lo else bh // 2)))
        if len(pts) > 1:
            d.line(pts, fill=TEXT, width=2)
        d.text((x0 + 4, by + ph - 38), 'period %d to %d' % (min(periods), max(periods)) if periods else '',
               font=F(13), fill=HI)
    save(im, out)


def render(e):
    st = step(e)
    n = int(RATE * FRAME)
    samples = []
    phase, nphase, lfsr, nbit = 0.0, 0.0, 1, 0
    for v, p, last in st:
        amp = AY_VOL[v]
        if p is None:
            samples.extend([0.0] * n)
            continue
        f = hz(e, p)
        for _ in range(n):
            if e['noise']:
                nphase += f / RATE
                while nphase >= 1:
                    nphase -= 1
                    nbit = (lfsr ^ (lfsr >> 3)) & 1
                    lfsr = (lfsr >> 1) | (nbit << 16)
                samples.append(amp if lfsr & 1 else 0.0)
            else:
                phase = (phase + f / RATE) % 1.0
                samples.append(amp if phase < 0.5 else 0.0)
    samples.extend([0.0] * (RATE // 10))
    return samples


def wav(folder):
    os.makedirs(folder, exist_ok=True)
    for i, e in enumerate(effects()):
        s = render(e)
        mean = sum(s) / len(s)
        path = os.path.join(folder, 'effect-%02d.wav' % i)
        with wave.open(path, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, (x - mean) * 0.9)) * 30000)) for x in s))
        print(path, '%.2f s' % (len(s) / RATE))


def table():
    for i, e in enumerate(effects()):
        st = step(e)
        print('%2d $%04X ch %d noise %d vol %d per %d segs %s | %s | %d ints | vols %s | first %s last %s' % (
            i, e['addr'], e['ch'], e['noise'], e['vol'], e['period'], e['segs'], ' '.join('%02X' % b for b in e['raw']),
            len(st), ' '.join(str(v) for v, _, _ in st), st[0][1], [p for _, p, _ in st if p is not None][-1:]))


REG_NAMES = ['A fine', 'A coarse', 'B fine', 'B coarse', 'C fine', 'C coarse', 'noise', 'mixer', 'A volume',
             'B volume', 'C volume', 'env fine', 'env coarse', 'env shape']


def regs(work, f0, f1, out):
    import argparse
    tr = kitlib.load_trace(argparse.Namespace(trace=None, work=work, window='%d:0-%d:0' % (f0 - 2, f1),
                                              max_cycles=None, unreal=None))
    writes = {}
    ints = set()
    reg = None
    for x in tr.instructions:
        if x.pc == 0xF9B3:
            ints.add(x.frame)
        for c in x.cycles:
            if c.tag == 'O' and c.address == 0xFFFD:
                reg = c.value
            elif c.tag == 'O' and c.address == 0xBFFD and reg is not None and reg < 14:
                writes.setdefault(x.frame, []).append((reg, c.value))
    state = [0] * 14
    state[7] = 0x38
    for fr in sorted(writes):
        if fr < f0:
            for r, v in writes[fr]:
                state[r] = v
    pictures = []
    history = []
    for fr in range(f0, f1):
        lit = set()
        for r, v in writes.get(fr, []):
            state[r] = v
            lit.add(r)
        history.append(([state[8] & 15, state[9] & 15, state[10] & 15], fr in ints))
        im, d, y = canvas(540, 'rzx-r1 frames %d-%d: the AY registers after each frame' % (f0, f1 - 1),
                          'Lit: the registers written in this frame (by AyFrame $F78A on the interrupt, or by '
                          'StartEffect\'s mixer write in the pass).\nA frame without an interrupt (DI in the pass) '
                          'writes nothing: the sound holds and the effect runs longer.')
        d.text((16, y), 'frame %d' % fr, font=F(19), fill=HI)
        d.text((180, y + 4), 'interrupt: AyFrame ran' if fr in ints else 'no interrupt: AyFrame did not run',
               font=F(15), fill=TEXT if fr in ints else (230, 110, 110))
        y += 36
        for r in range(14):
            cx = 16 + (r % 7) * 146
            cy = y + (r // 7) * 66
            on = r in lit
            d.rectangle((cx, cy, cx + 138, cy + 58), fill=(120, 96, 30) if on else PANEL, outline=HI if on else None)
            d.text((cx + 6, cy + 4), 'R%d %s' % (r, REG_NAMES[r]), font=F(13), fill=TEXT if on else DIM)
            d.text((cx + 6, cy + 26), '$%02X' % state[r], font=F(19), fill=HI if on else TEXT)
        y += 140
        mix = state[7]
        parts = []
        for k, name in enumerate('ABC'):
            parts.append('%s: tone %s, noise %s' % (name, 'on' if not mix & (1 << k) else 'off',
                                                   'on' if not mix & (8 << k) else 'off'))
        d.text((16, y), 'mixer $%02X  ' % mix + ';  '.join(parts), font=F(13), fill=TEXT)
        y += 22
        heard = []
        for k, name in enumerate('ABC'):
            if not state[8 + k] & 15:
                continue
            if not mix & (1 << k):
                p = (state[2 * k] | (state[2 * k + 1] & 15) << 8) or 1
                heard.append('%s: a tone of %d Hz (period %d)' % (name, round(CLOCK / (16 * p)), p))
            if not mix & (8 << k):
                p = (state[6] & 31) or 1
                heard.append('%s: noise, period %d (reg 6 $%02X, low 5 bits)' % (name, p, state[6]))
        d.text((16, y), 'heard: ' + ('; '.join(heard) if heard else 'nothing (all volumes 0)'), font=F(13),
               fill=HI if heard else DIM)
        y += 30
        # the volume history
        d.text((16, y), 'the three volumes, frame by frame (red tick: no interrupt)', font=F(13), fill=DIM)
        y += 20
        gx, gw, gh = 16, (1050 - 32) // (f1 - f0), 150
        for k, (vols, had) in enumerate(history):
            for j, v in enumerate(vols):
                c = COLOURS[j]
                bx = gx + k * gw + j * max(1, gw // 3)
                d.rectangle((bx, y + gh - v * gh // 15, bx + max(1, gw // 3) - 1, y + gh), fill=c)
            if not had:
                d.line((gx + k * gw, y + gh + 3, gx + k * gw + gw - 2, y + gh + 3), fill=(230, 110, 110), width=3)
        for j, name in enumerate('ABC'):
            d.rectangle((16 + j * 120, y + gh + 12, 28 + j * 120, y + gh + 24), fill=COLOURS[j])
            d.text((34 + j * 120, y + gh + 10), 'volume ' + name, font=F(13), fill=TEXT)
        pictures.append(im)
    pictures[0].save(out, save_all=True, append_images=pictures[1:], duration=[160] * (len(pictures) - 1) + [1500],
                     loop=0, optimize=True)
    print(out, len(pictures), 'pictures')


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'chart':
        chart(sys.argv[2])
    elif cmd == 'wav':
        wav(sys.argv[2])
    elif cmd == 'regs':
        regs(sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5])
    else:
        table()
