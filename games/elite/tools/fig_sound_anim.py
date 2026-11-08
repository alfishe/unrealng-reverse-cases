#!/usr/bin/env python3
"""A beeper effect as an animation, in step with the game's frames (docs/09-sound.md): never played, only drawn.

    python3 tools/fig_sound_anim.py TRACE:FROM-TO OUT.gif --title TEXT [--pictures 40] [--window 30]

From an access trace: every OUT to port $FE (the speaker, bit 4) and every screen write. Each picture, 900 px wide:

  - the screen at that moment (2x), as the television would show it at the end of the last whole frame;
  - beside it the frame and T, the routine whose OUT made the last edge, the pitch now (from the last half cycle);
  - under it the speaker bit over the last --window ms, scrolling: the newest edge at the right;
  - and the whole effect as a pitch track (a dot a half cycle, at the pitch it implies, log scale), the part already
    played bright, a cursor at now, a tick at each frame start.

FROM-TO are frames; the pictures are spread evenly over the effect's edges (one a frame when --pictures is the
frame count).
"""
import argparse
import bisect
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_sound as FS  # noqa: E402

W = 900
CLOCK, FRAME = FS.CLOCK, FS.FRAME
LO_HZ, HI_HZ = 40, 20000
BRIGHT, FADED = (255, 210, 70), (90, 80, 50)


def load(path, first, last):
    """edges [(T, level after, pc)], screens {frame: 6912 bytes at its end}, frame start T {frame: T}"""
    trace = K.access_trace().load(path)
    times = K.instruction_times(trace)
    units = max(1, trace.units_per_t)
    mem = bytearray(trace.memory)
    edges, screens, starts = [], {}, {}
    level, frame = None, None
    for i, x in enumerate(trace.instructions):
        if x.frame != frame:
            if frame is not None and first - 1 <= frame <= last:
                screens[frame] = bytes(mem[0x4000:0x5B00])
            frame = x.frame
            starts.setdefault(frame, times[i])
        at = times[i]
        for c in x.cycles:
            at += c.dt / units
            if c.tag in 'WE':
                mem[c.address] = c.value
            elif c.tag == 'O' and c.address & 0xFF == 0xFE and first <= x.frame <= last:
                bit = c.value >> 4 & 1
                if level is not None and bit != level:
                    edges.append((at, bit, x.pc))
                level = bit
        if x.frame > last + 1:
            break
    if frame is not None:
        screens.setdefault(frame, bytes(mem[0x4000:0x5B00]))
    return edges, screens, starts


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('spec')
    p.add_argument('out')
    p.add_argument('--title', required=True)
    p.add_argument('--pictures', type=int, default=40)
    p.add_argument('--window', type=float, default=30.0, help='ms of the speaker bit shown')
    p.add_argument('--delay', type=int, default=100)
    a = p.parse_args()
    path, rng = a.spec.rsplit(':', 1)
    first, last = (int(v) for v in rng.split('-'))
    edges, screens, starts = load(path, first, last)
    if len(edges) < 2:
        raise SystemExit('no speaker edges in %s' % a.spec)
    addrs, names = FS.routines()

    def writer(pc):
        if FS.BEEPER[0] <= pc <= FS.BEEPER[1]:
            return 'ROM BEEPER'
        if pc < 0x4000:
            return 'ROM $%04X' % pc
        return names[bisect.bisect_right(addrs, pc) - 1]

    t0, t1 = edges[0][0], edges[-1][0]
    span = t1 - t0
    dots = [((ta - t0), CLOCK / (2 * (tb - ta)), pc) for (ta, _, pc), (tb, _, _) in zip(edges, edges[1:]) if tb > ta]
    frames = sorted(starts)
    f13, f14, f16, f17 = K.font(13), K.font(14), K.font(16), K.font(17)
    lines = wrap(a.title, f17, W - 20)
    top = 10 + 22 * len(lines) + 6
    sw, sh = 512, 384
    wave_y = top + sh + 50
    wave_h = 90
    pitch_y = wave_y + wave_h + 46
    pitch_h = 150
    height = pitch_y + pitch_h + 40
    px0, px1 = 60, W - 20                          # the plot area of both strips

    def tx(t):                                      # pitch track: T from the first edge -> x
        return px0 + (px1 - px0) * t / span

    def hy(hz):
        hz = min(max(hz, LO_HZ), HI_HZ)
        return pitch_y + pitch_h - pitch_h * math.log(hz / LO_HZ) / math.log(HI_HZ / LO_HZ)

    pics = []
    n = max(2, a.pictures)
    for k in range(n):
        now = t0 + span * k / (n - 1)
        fr = max([f for f in frames if starts[f] <= now] or [frames[0]])
        shown = max([f for f in screens if f < fr] or [min(screens)])
        im = Image.new('RGB', (W, height), K.BACKGROUND)
        d = ImageDraw.Draw(im)
        for i, line in enumerate(lines):
            d.text((10, 10 + 22 * i), line, fill=K.TEXT, font=f17)
        scr = screen(screens[shown])
        im.paste(scr.resize((sw, sh), Image.NEAREST), (10, top))
        d.text((10, top + sh + 4), 'the screen at the end of frame %d' % shown, fill=K.DIM, font=f13)
        # the state beside the screen
        x = 10 + sw + 18
        i = bisect.bisect_right([e[0] for e in edges], now) - 1
        e = edges[max(0, i)]
        prev = edges[i - 1] if i >= 1 else None
        quiet = now - e[0] > 0.01 * CLOCK
        hz = CLOCK / (2 * (e[0] - prev[0])) if prev and e[0] > prev[0] else None
        rows = [('frame %d' % fr, K.TEXT, f16),
                ('T %d into it' % int(now - starts[fr]), K.DIM, f14),
                ('%.1f ms into the effect' % ((now - t0) / CLOCK * 1000), K.DIM, f14),
                ('', K.DIM, f14),
                ('playing:', K.DIM, f14),
                ('silent' if quiet else writer(e[2]), K.EXEC if not quiet else K.DIM, f16),
                ('', K.DIM, f14),
                ('pitch now:', K.DIM, f14),
                ('-' if quiet or not hz else ('%.0f Hz' % hz if hz < 10000 else '%.1f kHz' % (hz / 1000)),
                 BRIGHT, f16),
                ('', K.DIM, f14),
                ('speaker bit: %d' % e[1], K.TEXT, f14),
                ('edges so far: %d of %d' % (i + 1, len(edges)), K.DIM, f14)]
        y = top
        for text, col, f in rows:
            d.text((x, y), text, fill=col, font=f)
            y += 24 if f is f16 else 21
        # the speaker bit, scrolling
        win = a.window / 1000 * CLOCK
        d.text((10, wave_y - 22), 'the speaker bit (port $FE bit 4), the last %.0f ms; now at the right' % a.window,
               fill=K.DIM, font=f13)
        d.rectangle([px0, wave_y, px1, wave_y + wave_h], outline=(60, 60, 72))

        def wx(t):
            return px1 - (px1 - px0) * (now - t) / win

        hi_y, lo_y = wave_y + 14, wave_y + wave_h - 14
        j = bisect.bisect_left([ed[0] for ed in edges], now - win)
        lvl = (edges[j - 1][1] if j >= 1 else 1 - edges[0][1])
        pts = [(px0, hi_y if lvl else lo_y)]
        for ta, bit, _ in edges[j:i + 1]:
            xx = wx(ta)
            pts += [(xx, hi_y if lvl else lo_y), (xx, hi_y if bit else lo_y)]
            lvl = bit
        pts.append((px1, hi_y if lvl else lo_y))
        d.line(pts, fill=BRIGHT, width=1)
        d.text((px0 - 50, hi_y - 8), '1', fill=K.DIM, font=f13)
        d.text((px0 - 50, lo_y - 8), '0', fill=K.DIM, font=f13)
        for ms in range(0, int(a.window) + 1, 5):
            xx = px1 - (px1 - px0) * ms / a.window
            d.line([(xx, wave_y + wave_h), (xx, wave_y + wave_h + 4)], fill=K.DIM)
            d.text((xx - 14, wave_y + wave_h + 6), '-%d ms' % ms if ms else 'now', fill=K.DIM, font=f13)
        # the whole effect's pitch
        d.text((10, pitch_y - 22), 'the whole effect, pitch of each half cycle (log); played bright, to come dim',
               fill=K.DIM, font=f13)
        d.rectangle([px0, pitch_y, px1, pitch_y + pitch_h], outline=(60, 60, 72))
        for hz_mark in (100, 1000, 10000):
            yy = hy(hz_mark)
            d.line([(px0, yy), (px1, yy)], fill=(40, 40, 50))
            d.text((10, yy - 8), '%s Hz' % ('%dk' % (hz_mark // 1000) if hz_mark >= 1000 else hz_mark),
                   fill=K.DIM, font=f13)
        for f in frames:
            ft = starts[f] - t0
            if 0 <= ft <= span:
                d.line([(tx(ft), pitch_y + 1), (tx(ft), pitch_y + pitch_h + 4)], fill=(48, 48, 60))
        for t, hz_v, _pc in dots:
            X, Y = tx(t), hy(hz_v)
            d.rectangle([X - 1, Y - 1, X + 1, Y + 1], fill=BRIGHT if t0 + t <= now else FADED)
        cx = tx(now - t0)
        d.line([(cx, pitch_y - 2), (cx, pitch_y + pitch_h + 2)], fill=(240, 240, 250))
        d.text((px0, pitch_y + pitch_h + 8), '0 ms', fill=K.DIM, font=f13)
        end = '%.0f ms (grey lines: frame starts)' % (span / CLOCK * 1000)
        d.text((px1 - d.textlength(end, font=f13), pitch_y + pitch_h + 8), end, fill=K.DIM, font=f13)
        pics.append(im)
    K.save_gif(a.out, pics, [a.delay] * (len(pics) - 1) + [1500])
    print('%s: %d pictures, %d edges, %.0f ms, frames %d-%d, %d KB' % (
        a.out, len(pics), len(edges), span / CLOCK * 1000, first, last, os.path.getsize(a.out) // 1024))


def screen(data):
    mem = bytearray(0x10000)
    mem[0x4000:0x5B00] = data
    return K.render_screen(mem, 0x4000)


def wrap(text, font, width):
    d = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    out, line = [], ''
    for word in text.split():
        cand = (line + ' ' + word).strip()
        if d.textlength(cand, font=font) > width and line:
            out.append(line)
            line = word
        else:
            line = cand
    return out + [line]


if __name__ == '__main__':
    sys.exit(main())
