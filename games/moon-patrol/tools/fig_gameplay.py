#!/usr/bin/env python3
"""Figures of docs/10-gameplay-logic.md (writer mpB). Each subcommand draws one figure into docs/img/gameplay/.

  python3 tools/fig_gameplay.py jumps     jumps.png     the three jump arcs (JumpArcs $AAF0) as height against
                                                        passes, the 12-line clearance a rock needs and the 11-pass
                                                        window in which a rock touches the buggy
  python3 tools/fig_gameplay.py progress  progress.png  i1 and i2: the score against frames with the points, the
                                                        sector ends and the lives (work/stage1/i1-segments.txt,
                                                        i2-segments.txt: the course pointer and the player record
                                                        sampled every 20 frames of the L1 builds)
  python3 tools/fig_gameplay.py death     death.png     the death frames $1F-$26 and the wheels $3C-$3E, from the
                                                        sprite table
  python3 tools/fig_gameplay.py all
"""
import itertools
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_rendering as R  # noqa: E402
import fig_objects as O  # noqa: E402

K = R.K
MEM = R.MEM
W = R.W
F, FB, FS = R.F, R.FB, R.FS
R.OUT = os.path.join(R.CASE, 'docs', 'img', 'gameplay')
O.R.OUT = R.OUT

ARCS = [('back arc $AAF0 (x below $38)', 0xAAF0, (230, 120, 90)),
        ('centre arc $AAFD (x = $38)', 0xAAFD, (90, 200, 120)),
        ('forward arc $AB16 (x above $38)', 0xAB16, (90, 160, 255))]


def arc(a):
    out = []
    while MEM[a] != 0x80:
        v = MEM[a]
        out.append(v - 256 if v > 127 else v)
        a += 1
    return [-h for h in itertools.accumulate(out)]


def fig_jumps():
    im, d = R.canvas(640)
    R.title(d, 'The three jump arcs: height above the ground against main-loop passes',
            'One dot a pass from the jump key; the dashed line is 12 lines up, what a rock\'s box needs')
    ox, oy, pw, ph = 70, 90, 900, 330
    n = 34
    hmax = 22
    d.rectangle([ox, oy, ox + pw, oy + ph], outline=R.GRID)
    for hv in range(0, hmax + 1, 4):
        y = oy + ph - hv * ph / hmax
        d.text((ox - 40, y - 9), str(hv), font=FS, fill=K.DIM)
        d.line([ox, y, ox + pw, y], fill=(32, 32, 44))
    for pv in range(0, n + 1, 4):
        x = ox + pv * pw / n
        d.text((x - 6, oy + ph + 6), str(pv), font=FS, fill=K.DIM)
    y12 = oy + ph - 12 * ph / hmax
    for x in range(ox, ox + pw, 12):
        d.line([x, y12, x + 6, y12], fill=(230, 210, 60))
    ly = oy + ph + 40
    for k, (label, a, c) in enumerate(ARCS):
        hs = arc(a)
        pts = [(ox + (i + 1) * pw / n, oy + ph - h * ph / hmax) for i, h in enumerate(hs)]
        d.line([(ox, oy + ph)] + pts, fill=c, width=2)
        for p in pts:
            d.ellipse([p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3], fill=c)
        high = [i + 1 for i, h in enumerate(hs) if h >= 12]
        txt = '%s: %d passes, %d lines up, ' % (label, len(hs), max(hs))
        txt += ('above 12 lines in passes %d-%d (%d)' % (high[0], high[-1], len(high))) if high else 'never 12 lines up'
        d.text((ox, ly + k * 24), txt, font=FS, fill=c)
    # the rock window on the centre arc, earliest start
    hs = arc(0xAAFD)
    high = [i + 1 for i, h in enumerate(hs) if h >= 12]
    x0 = ox + high[0] * pw / n
    x1 = ox + (high[0] + 10) * pw / n
    d.rectangle([x0, oy + 8, x1, oy + 26], outline=(230, 210, 60), width=2)
    d.text((x1 + 8, oy + 8), 'a rock at x $54 ... $2C: 11 passes of contact', font=FS, fill=(230, 210, 60))
    d.text((ox, ly + 80), 'passes along the bottom; height = $92 - buggy y; the arcs sum to 0: the buggy lands where it '
           'took off', font=FS, fill=K.DIM)
    R.save(im.crop((0, 0, W, ly + 110)), 'jumps.png')


def segs(name):
    rows = []
    for ln in open(os.path.join(R.CASE, 'work', 'stage1', name + '-segments.txt')):
        m = re.match(r'\s*(\d+) (\d):(\S+(?: end)?)\s+\$(\w+) lives (\d+) score (\d+)', ln)
        if m:
            rows.append((int(m.group(1)), int(m.group(2)), m.group(3), int(m.group(5)), int(m.group(6))))
    return rows


def fig_progress():
    im, d = R.canvas(760)
    R.title(d, 'Progress through the courses: score against frames, i1 (Beginner) and i2 (Champion)',
            'A dot at each segment read (letter = the point, | = a sector end); the number above = lives in reserve')
    ox, pw, ph = 80, 920, 260
    for k, (name, label, c) in enumerate((('i1', 'i1: Beginner A-Z, then Champion A', (120, 200, 255)),
                                         ('i2', 'i2: Champion A-Z, then Beginner again', (230, 160, 90)))):
        oy = 80 + k * (ph + 80)
        rows = [r for r in segs(name) if r[2] != '-' and r[0] > 0]
        fmax = 34000
        smax = 60000
        d.rectangle([ox, oy, ox + pw, oy + ph], outline=R.GRID)
        d.text((ox, oy - 22), label, font=FS, fill=c)
        for sv in range(0, smax + 1, 20000):
            y = oy + ph - sv * ph / smax
            d.text((16, y - 9), '%d' % (sv // 1000) + 'k', font=FS, fill=K.DIM)
            d.line([ox, y, ox + pw, y], fill=(32, 32, 44))
        for fv in range(0, fmax + 1, 5000):
            x = ox + fv * pw / fmax
            d.text((x - 16, oy + ph + 4), str(fv), font=FS, fill=K.DIM)
        last_l = None
        for fr, course, pt, lives, score in rows:
            if pt == 'start' and score == 0 and fr > 1000:
                continue                   # the other player's empty record, sampled once
            x = ox + fr * pw / fmax
            y = oy + ph - score * ph / smax
            d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=c)
            tag = '|' if pt.startswith('sector') else ('' if pt == 'start' else pt)
            d.text((x - 4, y + 6), tag, font=FS, fill=K.TEXT if course == 1 else (255, 210, 70))
            if lives != last_l:
                d.text((x - 4, y - 26), str(lives), font=FS, fill=(255, 120, 120))
                last_l = lives
    d.text((ox, 80 + 2 * (ph + 80) - 50), 'frames along the bottom; white letters Beginner, yellow Champion; the jumps after | are the bonuses', font=FS, fill=K.DIM)
    R.save(im.crop((0, 0, W, 80 + 2 * (ph + 80) - 20)), 'progress.png')


def fig_death():
    im, d = R.canvas(400)
    R.title(d, 'A death: the eight frames $1F-$26 drawn in place of sprite 0, and the three wheels',
            '3 screen pixels a Spectrum pixel; one frame a pass ($B216 = 1 ... 8), then the life ends')
    s = 3
    x, y = 16, 76
    hmax = 0
    for n in [0] + list(range(0x1F, 0x27)):
        drw, g, wb, h = O.sprite(n)
        d.text((x, y), '$%02X' % n, font=FS, fill=K.DIM if n else K.TEXT)
        bw, bh = R.draw_bits(d, x, y + 22, R.bits(g, wb, h), s, bytelines=False)
        hmax = max(hmax, bh)
        x += bw + 10
        if x > W - 130:
            x, y = 16, y + 22 + hmax + 16
            hmax = 0
    y += 22 + hmax + 20
    d.text((16, y), 'The wheels, thrown off along WheelPaths $AC31 for 32 steps, four steps a pass:', font=FS,
           fill=K.TEXT)
    x = 16
    for n in (0x3C, 0x3D, 0x3E):
        drw, g, wb, h = O.sprite(n)
        d.text((x, y + 24), '$%02X' % n, font=FS, fill=K.DIM)
        bw, bh = R.draw_bits(d, x, y + 46, R.bits(g, wb, h), s, bytelines=False)
        x += bw + 30
    R.save(im.crop((0, 0, W, y + 46 + 9 * s + 16)), 'death.png')


FIGS = {'jumps': fig_jumps, 'progress': fig_progress, 'death': fig_death}

if __name__ == '__main__':
    names = sys.argv[1:] or ['all']
    for nm in (FIGS if names == ['all'] else names):
        FIGS[nm]()
