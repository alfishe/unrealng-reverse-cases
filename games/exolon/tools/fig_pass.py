#!/usr/bin/env python3
"""Doc 04 figure: MainLoop's passes against the frames and the beam, from an access trace.

    python3 tools/fig_pass.py --work work/docs/docA/c1 --window 16166:60000-16171:0 --rows 16166-16170 \
        --title '...' --out docs/img/loop/pass.png

One band a frame of the recording, the frame's T-states across (0 at the left, 69 888 at the right):

- the bar is coloured by what the CPU is doing: the group of the MainLoop call it is inside (MainLoop `$75BE`
  calls about 60 routines in a fixed order; each CALL from MainLoop starts its callee's group, BuildScreen and the
  beeper effects nested in a call get their own colour until they return);
- a white tick with "pass n" marks MainLoop's first instruction, with the pass's length in T-states;
- a red cross at frame T 1812 is the frame interrupt, never taken: the game runs with interrupts off;
- under the bar the beam: the screen's 192 lines top to bottom, the raster as a grey diagonal (line 0 at frame T
  14 336 + 1 812, 224 T a line), each screen write a dot in its group's colour at its line and time.

The table printed at the end: each group's T-states over the rows, the passes and their lengths.
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

MAIN_LO, MAIN_HI, PASS_START = 0x75BE, 0x768B, 0x75BE
INT_T, PAPER_T, LINE_T = 1812, 1812 + 14340, 224

GROUPS = [
    ('sound tick (AY, 3 a pass)', (90, 150, 250), 'SoundEffectsTick'),
    ('controls, pause, abort keys', (70, 210, 220), 'ReadControls PauseKey AbortKeys'),
    ('player: move, draw, fire, grenade', (90, 200, 120),
     'MovePlayer ScreenChangeCheck FireControl PlayerDeath ThrowGrenade MoveGrenade Teleports Pods ExoSuitBooth '
     'ZoneEnd'),
    ('shots (MoveShots, 5 a pass)', (240, 200, 70), 'MoveShots'),
    ('enemies and hazards', (230, 90, 80),
     'MoveShells Mines MoveBalls Traps AnimateTurrets Guns MoveGunShots AlienSpawn HomingMissileStep AliensStep '
     'ForceFieldStep IdleMissileStart IdleMissileStep FlickerPadStep'),
    ('effects: puffs, debris, flames, colours', (200, 110, 230),
     'AnimatePuffs ColourCycle MoveDebris AnimateFlames RunSparkles RunBlasts PayBonusTick'),
    ('contact tests', (250, 150, 60), 'ShellsHitPlayer BallsTouchPlayer TrapContact GunShotsVsPlayer AliensVsPlayer '
                                      'PickupsVsPlayer'),
    ('fixed delay (Delay, BC = 500)', (110, 110, 70), 'Delay'),
    ('time pads: blank sprite draws', (240, 120, 180), 'PadXorSprites PadSlotSprites'),
]
NESTED = [('screen build (BuildScreen)', (255, 255, 255), 'BuildScreen'),
          ('beeper noise / sweep', (160, 220, 80), 'BeeperNoise BeeperSweep'),
          ('the player turns: 24 frames mirrored', (120, 230, 190), 'FlipPlayerFrames'),
          ('player sprite draw (DrawBigSprite)', (40, 140, 60), 'DrawBigSprite')]
GLUE, OTHER = ('MainLoop itself', (70, 70, 90)), ('outside MainLoop (start, menu)', (40, 40, 52))


def ann_entries():
    out = {}
    for line in open(os.path.join(CASE, 'src', 'game', 'game.ann'), encoding='utf-8'):
        m = re.match(r'^\$([0-9A-F]{4}) c (\w+)', line)
        if m:
            out[m.group(2)] = int(m.group(1), 16)
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    K.add_trace_args(p)
    p.add_argument('--rows', required=True, help='F-F: the frames drawn, one band each')
    p.add_argument('--title', default='')
    p.add_argument('--note', action='append', default=[], help='a line under the subtitle (repeatable)')
    p.add_argument('--out', required=True)
    args = p.parse_args()
    names = ann_entries()
    callee_group, nested_at = {}, {}
    colours = {}
    for name, col, routines in GROUPS:
        colours[name] = col
        for r in routines.split():
            callee_group[names[r]] = name
    for name, col, routines in NESTED:
        colours[name] = col
        for r in routines.split():
            nested_at[names[r]] = name
    colours[GLUE[0]], colours[OTHER[0]] = GLUE[1], OTHER[1]
    trace = K.load_trace(args)
    units = max(1, trace.units_per_t)
    frame_t = trace.frame_t
    mem = bytearray(trace.memory)
    r0, r1 = (int(v) for v in args.rows.split('-'))
    xs = trace.instructions
    part, nest = OTHER[0], []
    spans, passes, writes = [], [], []
    pending = None
    for i, x in enumerate(xs):
        t = x.t // units
        while nest and x.sp >= nest[-1][0] + 2 and x.pc not in nested_at:
            part = nest.pop()[1]
        if pending is not None:
            part = pending
            pending = None
        if MAIN_LO <= x.pc <= MAIN_HI:
            nest.clear()
            part = GLUE[0]
            op = mem[x.pc]
            if op in (0xCD, 0xDC, 0xC3):  # CALL nn, CALL C,nn, JP nn
                target = mem[x.pc + 1] | mem[x.pc + 2] << 8
                if target in callee_group:
                    pending = callee_group[target]
            if x.pc == PASS_START:
                passes.append((x.frame, t))
        if x.pc in nested_at:
            nest.append((x.sp, part))
            part = nested_at[x.pc]
        for c in x.cycles:
            if c.tag == 'W':
                mem[c.address] = c.value
                if 0x4000 <= c.address < 0x5800:
                    writes.append((x.frame, t, K.screen_line(c.address), part))
        nxt = xs[i + 1] if i + 1 < len(xs) else None
        t_end = (nxt.t // units + (nxt.frame - x.frame) * frame_t) if nxt else t + 4
        spans.append((x.frame, t, t_end, part))
    # pass lengths
    abs_p = [f * frame_t + t for f, t in passes]
    lengths = {passes[k]: abs_p[k + 1] - abs_p[k] for k in range(len(passes) - 1)}
    # draw
    W, left = 900, 64
    plot_w = W - left - 14
    sx = plot_w / frame_t
    bar_h, beam_h, gap = 22, 64, 26
    band = bar_h + 4 + beam_h + gap
    rows = list(range(r0, r1 + 1))
    used = [g for g in list(colours) if any(s[3] == g for s in spans if r0 <= s[0] <= r1)]
    order = [g[0] for g in GROUPS] + [g[0] for g in NESTED] + [GLUE[0], OTHER[0]]
    used = [g for g in order if g in used]
    top = 92 + 16 * len(args.note)
    legend_rows = (len(used) + 1) // 2
    H = top + len(rows) * band + 34 + 18 * legend_rows + 50
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    f, fb, fs = K.font(12), K.font(15), K.font(11)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    d.text((10, 30), 'one band a frame: the bar = what the CPU runs; below it the beam (lines 0-191 down, '
                     'grey = raster), dots = screen writes', fill=K.DIM, font=f)
    for k, n in enumerate(args.note):
        d.text((10, 48 + 16 * k), n, fill=K.DIM, font=f)
    for k in range(0, frame_t, 10000):
        x = left + k * sx
        d.text((x - 8, top - 38), f'{k // 1000}k', fill=K.DIM, font=fs)
        d.line([(x, top - 24), (x, top - 21)], fill=K.DIM)
    totals = {}
    for ri, fr in enumerate(rows):
        y = top + ri * band
        d.text((6, y + 4), f'{fr}', fill=K.TEXT, font=f)
        for frame, t0, t1, prt in spans:
            if frame != fr:
                continue
            t1 = min(t1, frame_t)
            totals[prt] = totals.get(prt, 0) + (t1 - t0)
            x0, x1 = left + t0 * sx, left + t1 * sx
            d.rectangle((x0, y, max(x0, x1 - 0.01), y + bar_h), fill=colours[prt])
        by = y + bar_h + 4
        d.rectangle((left, by, left + plot_w, by + beam_h), fill=K.PANEL)
        d.text((left - 30, by), '0', fill=K.DIM, font=fs)
        d.text((left - 30, by + beam_h - 12), '191', fill=K.DIM, font=fs)
        x0, x1 = left + PAPER_T * sx, left + (PAPER_T + 192 * LINE_T) * sx
        d.line([(x0, by), (x1, by + beam_h)], fill=(110, 110, 120), width=1)
        for frame, t, line, prt in writes:
            if frame == fr:
                xx, yy = left + t * sx, by + line * beam_h / 192
                d.rectangle((xx - 1, yy - 1, xx + 1, yy + 1), fill=colours[prt])
        xi = left + INT_T * sx
        d.line([(xi - 4, y + 5), (xi + 4, y + 13)], fill=(255, 70, 70), width=2)
        d.line([(xi - 4, y + 13), (xi + 4, y + 5)], fill=(255, 70, 70), width=2)
        for (pf, pt) in passes:
            if pf != fr:
                continue
            xx = left + pt * sx
            d.line([(xx, y - 6), (xx, y + bar_h + 2)], fill=(255, 255, 255), width=2)
            n = passes.index((pf, pt))
            ln = lengths.get((pf, pt))
            lab = f'pass {n + 1}' + (f': {ln:,} T = {ln / frame_t:.2f} frames'.replace(',', ' ') if ln else '')
            d.text((min(xx + 4, W - 250), y - 15), lab, fill=(255, 255, 255), font=fs)
    y = top + len(rows) * band + 4
    d.text((10, y), 'what the CPU is doing (the share of these frames):', fill=K.TEXT, font=f)
    for i, g in enumerate(used):
        cx, cy = 10 + (i % 2) * 445, y + 20 + (i // 2) * 18
        d.rectangle((cx, cy + 2, cx + 14, cy + 12), fill=colours[g])
        share = 100 * totals.get(g, 0) / (len(rows) * frame_t)
        d.text((cx + 20, cy), f'{g} {share:.0f}%', fill=K.TEXT, font=f)
    cy = y + 24 + legend_rows * 18
    d.line([(14, cy + 2), (22, cy + 10)], fill=(255, 70, 70), width=2)
    d.line([(14, cy + 10), (22, cy + 2)], fill=(255, 70, 70), width=2)
    d.text((30, cy), 'the frame interrupt at T 1812: never taken (DI); white tick = a pass starts (MainLoop $75BE)',
           fill=K.DIM, font=f)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)
    for g, t in sorted(totals.items(), key=lambda kv: -kv[1]):
        print(f'{g:42s} {t:8d} T {100 * t / (len(rows) * frame_t):5.1f}%')
    for k, pp in enumerate(passes):
        print('pass', k + 1, pp, lengths.get(pp))
    print('screen writes', len(writes))


if __name__ == '__main__':
    main()
