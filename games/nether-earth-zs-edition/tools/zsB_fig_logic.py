#!/usr/bin/env python3
"""Figures of docs 07 (objects), 08 (HUD) and 10 (gameplay logic), drawn from the memory of work/zsB/deep: the '99 on
HARD, played by tools/zsB_play99.py deep for 30 602 frames (2 224 turns, 7.7 game days).

    python3 tools/zsB_fig_logic.py sample                       # the memory every --step frames, kept in the cache
    python3 tools/zsB_fig_logic.py slots     --frame 30000 --out docs/img/objects/robot-slots.png
    python3 tools/zsB_fig_logic.py robots    --out docs/img/objects/robots-over-time.png
    python3 tools/zsB_fig_logic.py map       --frame 20000 --out docs/img/objects/world-ends.png
    python3 tools/zsB_fig_logic.py capture   --out docs/img/logic/capture-index.png
    python3 tools/zsB_fig_logic.py upgrade   --out docs/img/logic/enemy-upgrade.png
    python3 tools/zsB_fig_logic.py resources --out docs/img/logic/resources.png
    python3 tools/zsB_fig_logic.py panel     --frame 20000 --out docs/img/hud/panel.png
    python3 tools/zsB_fig_logic.py fonts     --out docs/img/hud/fonts.png
    python3 tools/zsB_fig_logic.py radar     --frame 9930 --out docs/img/hud/radar.png
    python3 tools/zsB_fig_logic.py battle    --out docs/img/logic/map0-battle.png     # work/zsB/deep-map0
    python3 tools/zsB_fig_logic.py fight     --frame 12400 --out docs/img/objects/first-fight.png   # deep-map0

The battle figure reads work/zsB/deep-map0: NELEV_00 loaded by LOAD MAP, HARD, the same bot, 24 416 frames
(tools/zsB_play99.py menu --map 0, then deep; the instance opened with --work work/zsB/deep-map0 --port-base 15430).

The memory comes from an own unreal-qt instance that holds the recording (re_session.py open --work work/zsB/deep
--ttd work/zsB/deep/session.ttd --model PENTAGON --ranges 4000-FFFF --port-base 15440): nether-earth's
tools/ill_render.py Recording (imported, not changed) asks it for memory_at and the executions of an address, and
keeps each answer in work/zsB/cache/deep, so a figure is redrawn later without an instance.
"""
import argparse
import os
import sys

import matplotlib
import numpy as np
from PIL import Image, ImageDraw

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, os.path.join(CASE, '..', 'nether-earth', 'tools'))
import kitlib as K  # noqa: E402
import ill_render as I  # noqa: E402

WORK = os.path.join(CASE, 'work', 'zsB', 'deep')
CACHE = os.path.join(CASE, 'work', 'zsB', 'cache')
ROBOTS, VARS, POINTS, BUILDINGS, MAP = 0xDA00, 0xFD00, 0xFD70, 0xFF01, 0xDD00
RESOURCES, ENEMY_RES = 0xFD22, 0xFD4A
PART_HEIGHTS = [0x0B, 7, 8, 6, 6, 7, 7, 7]      # PartHeights $D7B4
PARTS = ['bipod', 'tracks', 'anti-grav', 'cannon', 'missiles', 'phasers', 'nuclear', 'electronics']
SHORT = ['Bi', 'Tr', 'AG', 'Ca', 'Mi', 'Ph', 'Nu', 'El']
ORDERS = ['stop', 'advance', 'retreat', 'destroy robots', 'destroy factories', 'destroy warbases',
          'capture neutral f.', 'capture enemy f.', 'capture enemy w.']
EXEC = {'GiveFactory': 0xBB61, 'DailyProduction': 0xAE38, 'UpgradeEnemyRobots': 0xA5D6,
        'FillEnemyResources': 0xA5F2}
LAST = 30600
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#b8bcc8'
OURS, THEIRS = '#4caf50', '#e5534b'


def rec():
    return I.Recording(WORK, CACHE)


def rel(path):
    return os.path.relpath(os.path.abspath(path), CASE)


def frames(step):
    return list(range(step, LAST + 1, step))


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(AX)
        a.tick_params(colors=DIM, labelsize=9)
        for s in a.spines.values():
            s.set_color('#444')
        a.grid(color='#2c2d36', lw=0.5)


def esc(text):
    return text.replace('$', '\\$')


def footer(fig, a, what):
    fig.text(0.01, 0.005, f'python3 tools/zsB_fig_logic.py {what} --out {rel(a.out)}', color='#8a8e9a', fontsize=9)


def robot(m, i):
    return m[ROBOTS + 16 * i:ROBOTS + 16 * i + 16]


def alive(m, i):
    return robot(m, i)[1] != 0


def execs(r, name, count=200):
    return [f for f, _ in r.executions(EXEC[name], LAST + 2, count)]


# ---------------------------------------------------------------------------------------------------------------

def fig_sample(a):
    r = rec()
    for f in frames(a.step):
        r.read(f, VARS, 1)
    print('cached', len(frames(a.step)), 'moments in', r.dir)


def fig_slots(a):
    r = rec()
    m = r.memory(a.frame)
    W, ROW, TOP, L = 1240, 19, 78, 14
    H = TOP + 48 * ROW + 110
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    f14, f12, f11 = I.font(14), I.font(12), I.font(11)
    d.text((L, 10), f'The 48 robot records at $DA00 (16 bytes each) at frame {a.frame} of work/zsB/deep: slots 0-23 '
           'ours, 24-47 the enemy\'s', fill=K.TEXT, font=f14)
    d.text((L, 30), 'a free slot has +$01 = 0; on the right: the parts +$07 decoded, the height +$09 against the '
           'sum of PartHeights $D7B4 for those parts', fill=K.DIM, font=f12)
    cols = ['slot', 'address', '+0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F', 'X', 'Y', 'parts', 'h / sum',
            'control', 'order', 'str']
    xs = [L, L + 44, L + 112, L + 520, L + 560, L + 596, L + 816, L + 900, L + 980, L + 1140]
    for x, c in zip(xs, cols):
        d.text((x, TOP - 20), c, fill=K.DIM, font=f11)
    for i in range(48):
        rr = robot(m, i)
        y = TOP + i * ROW
        side = (90, 210, 110) if i < 24 else (235, 85, 80)
        live = rr[1] != 0
        if i == 24:
            d.line([L, y - 2, W - L, y - 2], fill=(120, 120, 135))
        if live:
            d.rectangle([L - 4, y - 1, W - L, y + ROW - 3], fill=tuple(c // 7 for c in side))
        col = side if live else (70, 70, 80)
        d.text((xs[0], y), f'{i:2d}', fill=col, font=f12)
        d.text((xs[1], y), f'${ROBOTS + 16 * i:04X}', fill=col, font=f12)
        d.text((xs[2], y), ' '.join(f'{b:02X}' for b in rr), fill=K.TEXT if live else (70, 70, 80), font=f12)
        if not live:
            continue
        hs = sum(PART_HEIGHTS[p] for p in range(8) if rr[7] >> p & 1)
        d.text((xs[3], y), f'{rr[2] | rr[3] << 8}', fill=K.TEXT, font=f12)
        d.text((xs[4], y), f'{rr[4]}', fill=K.TEXT, font=f12)
        d.text((xs[5], y), ' '.join(SHORT[p] for p in range(8) if rr[7] >> p & 1), fill=K.TEXT, font=f12)
        d.text((xs[6], y), f'{rr[9]} / {hs}', fill=(255, 200, 80) if hs != rr[9] else K.TEXT, font=f12)
        d.text((xs[7], y), {0: 'AI', 1: 'player', 2: 'direct', 0x80: 'enemy'}.get(rr[10], f'${rr[10]:02X}'),
               fill=K.TEXT, font=f12)
        d.text((xs[8], y), ORDERS[rr[11]] if rr[11] < 9 else '?', fill=K.TEXT, font=f12)
        d.text((xs[9], y), f'{rr[12]}', fill=K.TEXT, font=f12)
    y = TOP + 48 * ROW + 8
    d.text((L, y), 'green rows: ours, red: the enemy\'s, grey: free (a free enemy slot still gets parts each midnight). '
           'Yellow: +$09 no longer matches the parts', fill=K.DIM, font=f12)
    d.text((L, y + 36), '(UpgradeEnemyRobots $A5D6 rewrites +$07 at midnight and leaves +$09).', fill=K.DIM, font=f12)
    d.text((L, y + 18), 'Bi bipod, Tr tracks, AG anti-grav, Ca cannon, Mi missiles, Ph phasers, Nu nuclear, El '
           'electronics (bits 0-7 of +$07).', fill=K.DIM, font=f12)
    d.text((L, H - 22), f'python3 tools/zsB_fig_logic.py slots --frame {a.frame} --out {rel(a.out)}', fill=K.DIM,
           font=f11)
    out.save(a.out)
    print(a.out, out.size)


def series(r, step):
    rows = []
    for f in frames(step):
        m = r.memory(f)
        v = m[VARS:VARS + 256]
        rows.append(dict(frame=f, ours=sum(alive(m, i) for i in range(24)),
                         theirs=sum(alive(m, i) for i in range(24, 48)),
                         res=m[RESOURCES], eres=list(m[ENEMY_RES:ENEMY_RES + 7]),
                         count0=m[POINTS + 4], owner26=m[POINTS + 5 * 26 + 3],
                         day=v[0x37] | v[0x38] << 8, door=next((i for i in range(48)
                                                                if robot(m, i)[2] == m[POINTS]
                                                                and robot(m, i)[3] == m[POINTS + 1]
                                                                and robot(m, i)[4] == m[POINTS + 2]
                                                                and alive(m, i)), None)))
    return rows


def fig_robots(a):
    r = rec()
    rows = series(r, a.step)
    fx = [x['frame'] for x in rows]
    fig, ax = plt.subplots(figsize=(12, 4.6), dpi=90)
    style(fig, [ax])
    ax.step(fx, [x['ours'] for x in rows], where='post', color=OURS, lw=2, label='our robots (slots 0-23)')
    ax.step(fx, [x['theirs'] for x in rows], where='post', color=THEIRS, lw=2,
            label='the enemy\'s robots (slots 24-47)')
    for k, f in enumerate(execs(r, 'DailyProduction')):
        ax.axvline(f, color='#777', ls=':', lw=1)
        ax.text(f + 80, 23.2, f'midnight\n{f}', color=DIM, fontsize=8, va='top')
    ax.axhline(24, color='#555', lw=0.8)
    ax.set_ylim(0, 25)
    ax.set_xlim(0, LAST)
    ax.set_ylabel(esc('live records (+$01 not 0)'), color=DIM)
    ax.set_xlabel(esc(f'frame of work/zsB/deep (sampled every {a.step} frames); dotted: DailyProduction $AE38 ran'),
                  color=DIM)
    ax.legend(loc='center right', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    ours = [x['ours'] for x in rows]
    first_full = next(x['frame'] for x in rows if x['ours'] == max(ours))
    ax.annotate(f'7 robots from frame {first_full}: the bot builds no more\n(a robot of ours stands on the '
                'warbase door, so the pad is blocked)', xy=(first_full, max(ours)), xytext=(9500, 3.5),
                color=FG, fontsize=9, arrowprops=dict(arrowstyle='->', color=FG))
    ax.set_title(esc('The robots of each side over the deep game: the enemy builds to 16 while ours stop at 7'),
                 color=FG, fontsize=12, loc='left')
    footer(fig, a, 'robots')
    fig.tight_layout(rect=(0, 0.02, 1, 1))
    fig.savefig(a.out, facecolor=fig.get_facecolor())
    print(a.out)


def fig_map(a):
    r = rec()
    m = r.memory(a.frame)
    cs = 15
    parts = [(0, 32), (480, 32)]
    f14, f12, f11 = I.font(14), I.font(12), I.font(11)
    L, T = 20, 70
    W = max(L + sum(w for _, w in parts) * cs + 40 + 20, 1100)
    H = T + 16 * cs + 170
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((L, 10), f'Both ends of the 512-column map $DD00 at frame {a.frame} of work/zsB/deep: each warbase and the '
           'robots round it', fill=K.TEXT, font=f14)
    d.text((L, 30), f'{cs} pixels a cell; the terrain as BuildMap $BC6F leaves it (dark: open ground, grey: blocks, '
           'purple: the walls); robot anchors in the side\'s colour', fill=K.DIM, font=f12)
    x = L
    pts = m[POINTS:POINTS + 140]
    for x0, w in parts:
        im = I.terrain_strip(m, x0, w, cs, 0.6)
        dd = ImageDraw.Draw(im)
        for i in range(48):
            rr = robot(m, i)
            if rr[1]:
                rx, ry = (rr[2] | rr[3] << 8) - x0, rr[4]
                if 0 <= rx < w:
                    c = (90, 210, 110) if i < 24 else (235, 85, 80)
                    dd.rectangle([rx * cs + 1, ry * cs + 1, rx * cs + cs - 2, ry * cs + cs - 2], fill=c)
                    dd.text((rx * cs + 1, ry * cs - 12), str(i), fill=c, font=I.font(10))
        for k in range(28):
            px, py, own = pts[5 * k] | pts[5 * k + 1] << 8, pts[5 * k + 2], pts[5 * k + 3]
            if px == 0 and py == 0:
                continue
            if 0 <= px - x0 < w:
                cx, cy = (px - x0) * cs + cs // 2, py * cs + cs // 2
                dd.ellipse([cx - cs, cy - cs, cx + cs, cy + cs], outline=(255, 220, 90), width=2)
        out.paste(im, (x, T))
        for c in range(0, w, 8):
            d.text((x + c * cs, T - 14), str(x0 + c), fill=K.DIM, font=f11)
        x += w * cs + 40
    y = T + 16 * cs + 12
    used = [k for k in range(28) if pts[5 * k] or pts[5 * k + 1] or pts[5 * k + 2]]
    d.text((L, y), f'capture points in use: {len(used)} of 28 ({", ".join(str(k) for k in used)}): '
           + '; '.join(f'point {k} door ({pts[5 * k] | pts[5 * k + 1] << 8},{pts[5 * k + 2]}) owner '
                       f'${pts[5 * k + 3]:02X}' for k in used), fill=K.TEXT, font=f12)
    d.text((L, y + 20), 'the built-in level has two warbases and no factory: records 2-27 of $FD70 are zeros, only '
           'record 26 has an owner (the capture bug, doc 10)', fill=K.DIM, font=f12)
    bl = [(m[BUILDINGS + 3 * k] | m[BUILDINGS + 3 * k + 1] << 8, m[BUILDINGS + 3 * k + 2]) for k in range(56)]
    kinds = {0: 'pad', 7: 'our flag', 8: 'enemy flag'}

    def where(cell):
        off = cell - MAP
        return f'({off % 0x200},{off // 0x200})' if 0 <= off < 0x2000 else f'outside the map'
    d.text((L, y + 40), 'Buildings $FF01 (cell, type): ' + '; '.join(
        f'${c:04X} {where(c)} {kinds.get(t, t)}' for c, t in bl if c), fill=K.DIM, font=f12)
    d.text((L, y + 60), 'yellow ring: a door (CaptureLoop $ADB7 counts turns there); numbers: robot slots',
           fill=K.DIM, font=f12)
    d.text((L, H - 22), f'python3 tools/zsB_fig_logic.py map --frame {a.frame} --out {rel(a.out)}', fill=K.DIM,
           font=f11)
    out.save(a.out)
    print(a.out, out.size)


def fig_capture(a):
    r = rec()
    rows = series(r, a.step)
    fx = [x['frame'] for x in rows]
    gives = execs(r, 'GiveFactory')
    fig, (ax, bx) = plt.subplots(2, 1, figsize=(12, 6.4), dpi=90, sharex=True,
                                 gridspec_kw=dict(height_ratios=[3, 1]))
    style(fig, [ax, bx])
    ax.plot(fx, [x['count0'] for x in rows], color='#26c6da', lw=1.4,
            label='point 0 (our warbase door (18,8)): turns counted, $FD74')
    ax.axhline(0x90, color='#d9a441', ls='--', lw=1)
    ax.text(200, 0x90 + 3, esc('$90 = 144 turns: a capture'), color='#d9a441', fontsize=9)
    for k, f in enumerate(gives):
        ax.axvline(f, color='#e5534b', lw=1, alpha=0.7)
    ax.text(gives[0] + 100, 160, esc(f'GiveFactory $BB61 ran {len(gives)} times (red lines)'), color='#e5534b',
            fontsize=9)
    door = [x['door'] for x in rows]
    k = len(rows) - 1
    while k > 0 and rows[k - 1]['door'] is not None:
        k -= 1
    first, who = rows[k]['frame'], rows[-1]['door']
    ax.annotate(f'robot {who} (ours) stands on the door from about frame {first} on', xy=(first, 2),
                xytext=(first - 6000, 70), color=FG, fontsize=9, arrowprops=dict(arrowstyle='->', color=FG))
    ax.set_ylim(0, 175)
    ax.set_ylabel('turns on the door', color=DIM)
    ax.legend(loc='upper right', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    bx.step(fx, [x['owner26'] >> 6 & 1 for x in rows], where='post', color=OURS, lw=2)
    bx.set_yticks([0, 1])
    bx.set_yticklabels([esc('$00'), esc('$40 ours')])
    bx.set_ylim(-0.3, 1.4)
    bx.set_ylabel(esc('record 26\nowner $FDF5'), color=DIM)
    bx.set_xlabel(f'frame of work/zsB/deep (every {a.step} frames); the count of points B = 2, the index 28 - B = 26 '
                  '(factory 22): an empty record', color=DIM)
    bx.set_xlim(0, LAST)
    fig.suptitle(esc('The capture bug at work: a robot on our own warbase door "captures" record 26, a factory that '
                     'does not exist, every 144 turns'), color=FG, fontsize=12, x=0.01, ha='left')
    footer(fig, a, 'capture')
    fig.tight_layout(rect=(0, 0.02, 1, 0.96))
    fig.savefig(a.out, facecolor=fig.get_facecolor())
    print(a.out, 'GiveFactory at', gives)


def fig_upgrade(a):
    r = rec()
    nights = execs(r, 'UpgradeEnemyRobots')
    f14, f12, f11 = I.font(14), I.font(12), I.font(11)
    cells = []
    for f in nights:
        before, after = r.memory(f - 1), r.memory(f + 1)
        cells.append((f, before, after))
    slots = sorted({i for _, b, _ in cells for i in range(24, 48) if alive(b, i)})
    L, T, CW, RH = 20, 92, 150, 34
    W = L + 70 + CW * len(cells) + 20
    H = T + RH * len(slots) + 110
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((L, 10), 'UpgradeEnemyRobots $A5D6 at each midnight on HARD: every enemy record\'s parts +$07 become '
           '(+$07 AND $78) OR $84', fill=K.TEXT, font=f14)
    d.text((L, 30), 'each cell: parts before -> after (hex), the height +$09 the record keeps, and the sum of '
           'PartHeights $D7B4 for the new parts', fill=K.DIM, font=f12)
    d.text((L, 48), 'AND $78 keeps cannon, missiles, phasers, nuclear (bits 3-6) and drops the chassis and the '
           'electronics; OR $84 sets anti-grav (bit 2) and electronics (bit 7)', fill=K.DIM, font=f12)
    for k, (f, _, _) in enumerate(cells):
        d.text((L + 70 + k * CW, T - 22), f'frame {f}', fill=K.TEXT, font=f12)
    for j, i in enumerate(slots):
        y = T + j * RH
        d.text((L, y + 8), f'slot {i}', fill=(235, 85, 80), font=f12)
        for k, (f, b, aft) in enumerate(cells):
            x = L + 70 + k * CW
            rb, ra = robot(b, i), robot(aft, i)
            if not rb[1]:
                continue
            hs = sum(PART_HEIGHTS[p] for p in range(8) if ra[7] >> p & 1)
            changed = rb[7] != ra[7]
            d.rectangle([x, y, x + CW - 8, y + RH - 4], fill=(40, 24, 24) if changed else (26, 26, 32))
            d.text((x + 4, y + 2), f'${rb[7]:02X} -> ${ra[7]:02X}', fill=K.TEXT if changed else K.DIM, font=f12)
            d.text((x + 4, y + 16), f'h {ra[9]} / sum {hs}', fill=(255, 200, 80) if hs != ra[9] else K.DIM,
                   font=f11)
    y = T + RH * len(slots) + 8
    d.text((L, y), 'red cell: the parts changed that night; yellow: the stored height no longer matches the parts. '
           'Only slots alive at a midnight have cells.', fill=K.DIM, font=f12)
    d.text((L, y + 18), 'EASY and MEDIUM leave the routine out; HARD calls it from $AE41 (DailyProduction); CRITICAL makes '
           'it AND $00, OR $FC (the operands at $A5E5 / $A5E7).', fill=K.DIM, font=f12)
    d.text((L, H - 22), f'python3 tools/zsB_fig_logic.py upgrade --out {rel(a.out)}', fill=K.DIM, font=f11)
    out.save(a.out)
    print(a.out, out.size, nights)


def fig_resources(a):
    r = rec()
    rows = series(r, a.step)
    fx = [x['frame'] for x in rows]
    fig, (ax, bx) = plt.subplots(2, 1, figsize=(12, 6.6), dpi=90, sharex=True)
    style(fig, [ax, bx])
    ax.step(fx, [x['res'] for x in rows], where='post', color=OURS, lw=2, label=esc('our general resources $FD22'))
    for f in execs(r, 'DailyProduction'):
        ax.axvline(f, color='#777', ls=':', lw=1)
        bx.axvline(f, color='#777', ls=':', lw=1)
    ax.set_ylabel('resources', color=DIM)
    ax.legend(loc='upper right', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    ax.text(18000, 15, esc('each midnight +5: ProduceSide $AE4E gives 5 general a warbase; the bot spends on robots '
                           'until the pad is blocked'), color=FG, fontsize=9, ha='center')
    names = ['general', 'electronics', 'nuclear', 'phasers', 'missiles', 'cannon', 'chassis']
    cols = ['#e8e8ee', '#ffd54f', '#ef5350', '#ab47bc', '#42a5f5', '#66bb6a', '#8d6e63']
    for k in range(7):
        bx.step(fx, [x['eres'][k] for x in rows], where='post', color=cols[k], lw=1.4, label=names[k])
    for f in execs(r, 'FillEnemyResources'):
        bx.plot([f], [101], marker='v', color='#26c6da', ms=6)
    bx.text(200, 104, esc('triangles: FillEnemyResources $A5F2 ran (called from $B87E before each enemy build)'),
            color='#26c6da', fontsize=9)
    bx.set_ylim(0, 112)
    bx.set_ylabel(esc('enemy resources $FD4A-$FD50'), color=DIM)
    bx.legend(loc='lower right', fontsize=8, frameon=False, labelcolor='#d6d8e0', ncol=7)
    bx.set_xlim(0, LAST)
    bx.set_xlabel(esc(f'frame of work/zsB/deep (every {a.step} frames); dotted: DailyProduction $AE38'), color=DIM)
    fig.suptitle(esc('Resources on HARD: ours grow 5 a day, the enemy\'s are set back to 99 before each robot it builds'),
                 color=FG, fontsize=12, x=0.01, ha='left')
    footer(fig, a, 'resources')
    fig.tight_layout(rect=(0, 0.02, 1, 0.96))
    fig.savefig(a.out, facecolor=fig.get_facecolor())
    print(a.out)


def fig_panel(a):
    r = rec()
    m = r.memory(a.frame)
    S = 3
    scr = K.render_screen(m).resize((256 * S, 192 * S), Image.NEAREST)
    L, T = 20, 60
    W, H = L + 256 * S + 360, T + 192 * S + 70
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    out.paste(scr, (L, T))
    d = ImageDraw.Draw(out)
    f14, f12, f11 = I.font(14), I.font(12), I.font(11)
    d.text((L, 10), f'The play screen at frame {a.frame} of work/zsB/deep, its parts and who writes them', fill=K.TEXT,
           font=f14)
    d.text((L, 30), '3x; the boxes are 8x8 character cells (row, column) of the PrintInline strings', fill=K.DIM,
           font=f12)
    boxes = [
        ('A', (0, 22, 2, 10), (255, 90, 90), 'DAY / TIME: PlayScreenText $D1C5; the numbers by GameTurnEnd $AD90 '
                                              '(PrintNumber5, PrintNumber2Zero) every turn'),
        ('B', (3, 22, 11, 10), (255, 210, 80), 'STATUS: StatusPanelText $D1EB; INSG = the enemy, HUMN = ours; '
                                                'counts from CountBases $BB09, printed by UpdateStatusPanel $D293'),
        ('C', (15, 22, 9, 10), (90, 210, 110), 'RESOURCES: our seven resources $FD22, UpdateStatusPanel'),
        ('D', (22, 0, 2, 22), (90, 170, 255), 'RADAR: the label, PlayScreenText; the strip right of it is the radar '
                                              '(here the built-in level\'s scenery spells a word on it)'),
        ('E', (1, 1, 20, 20), (200, 120, 240), 'the view: 20 x 20 cells, drawn off screen and copied (doc 06)'),
    ]
    tx = L + 256 * S + 20
    ty = T
    for tag, (row, col, h, w), c, text in boxes:
        x0, y0 = L + col * 8 * S, T + row * 8 * S
        d.rectangle([x0, y0, x0 + w * 8 * S - 1, y0 + h * 8 * S - 1], outline=c, width=3)
        d.text((x0 + 4, y0 + 2), tag, fill=c, font=f14, stroke_width=2, stroke_fill=(0, 0, 0))
        d.text((tx, ty), tag, fill=c, font=f14)
        words, line, ly = text.split(), '', ty
        for w_ in words:
            if d.textlength(line + ' ' + w_, font=f12) > 300 and line:
                d.text((tx + 20, ly), line, fill=K.TEXT, font=f12)
                ly += 16
                line = w_
            else:
                line = (line + ' ' + w_).strip()
        d.text((tx + 20, ly), line, fill=K.TEXT, font=f12)
        ty = ly + 30
    d.text((L, H - 22), f'python3 tools/zsB_fig_logic.py panel --frame {a.frame} --out {rel(a.out)}', fill=K.DIM,
           font=f11)
    out.save(a.out)
    print(a.out, out.size)


def fig_fonts(a):
    sheets = [('src/res/game99/gfx/font.png', "the '99 game font Font $6780 (PrintChar $D4B1, PrintBigChar $D4DA): 64 "
               'glyphs 8 x 8, codes $20-$5F', 4),
              ('src/res/game98/gfx/font.png', "the '98 game font, same place and use: the 1987 game's own bytes "
               '(347 of the 512 differ from the \'99)', 4),
              ('src/res/intro98/font.png', "the '98 intro's scroller font IntroFont $E6CC: 96 glyphs from $20, "
               'KOI-7 N2 (Cyrillic capitals at $60-$7E)', 4),
              ('src/res/stage2/font64.png', "the '99 64-column font: Font64 $7587 (intro) = ViewerFont $DEF1 (menu "
               'viewer), 2 048 bytes each, CP866', 3)]
    ims = []
    for path, title, s in sheets:
        im = Image.open(os.path.join(CASE, path)).convert('RGB')
        ims.append((im.resize((im.width * s, im.height * s), Image.NEAREST), title, path))
    f14, f12, f11 = I.font(14), I.font(12), I.font(11)
    W = max(im.width for im, _, _ in ims) + 40
    H = 60 + sum(im.height + 50 for im, _, _ in ims) + 30
    out = Image.new('RGB', (max(W, 900), H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((20, 10), 'The fonts of both releases as the case keeps them (src/res): who prints with each', fill=K.TEXT, font=f14)
    d.text((20, 26), 'the 64-column font holds two 4-pixel glyphs a cell (left and right halves), so its sheet shows each letter twice', fill=K.DIM, font=f12)
    y = 54
    for im, title, path in ims:
        d.text((20, y), f'{title}: {path}', fill=K.DIM, font=f12)
        out.paste(im, (20, y + 20))
        y += im.height + 50
    d.text((20, H - 22), f'python3 tools/zsB_fig_logic.py fonts --out {rel(a.out)}', fill=K.DIM, font=f11)
    out.save(a.out)
    print(a.out, out.size)


def fig_radar(a):
    """both radar pictures before and after the capture at frame 9938, with the byte $D8FE marked"""
    r = rec()
    after = a.frame + 40
    rows = [(a.frame, 0xD800, 'RadarOwn $D800 (shown in $4D, cyan)'),
            (after, 0xD800, 'RadarOwn $D800 (shown in $4D, cyan)'),
            (after, 0xD900, 'RadarEnemy $D900 (shown in $4E, yellow)')]
    S = 6
    f14, f12, f11 = I.font(14), I.font(12), I.font(11)
    W, H = 40 + 128 * S + 200, 70 + len(rows) * (16 * S + 46) + 150
    out = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(out)
    d.text((20, 10), 'The radar: two 128 x 16 pictures built from the map; the capture bug writes a stray pixel into ours (A)',
           fill=K.TEXT, font=f14)
    d.text((20, 28), 'work/zsB/deep; one pixel a map cell (block type $0F and up), 6x; the robots of each side are dots in its picture',
           fill=K.DIM, font=f12)
    y = 56
    for f, base, title in rows:
        m = r.memory(f)
        col = m[0xFD1C] | (m[0xFD1D] << 8)
        ink = (90, 220, 230) if base == 0xD800 else (240, 220, 80)
        d.text((20, y), esc_none(f'frame {f}: {title}; window from map column {col}'), fill=K.TEXT, font=f12)
        y0 = y + 18
        d.rectangle([20 - 1, y0 - 1, 20 + 128 * S, y0 + 16 * S], outline=(80, 80, 90))
        for line in range(16):
            for byte in range(16):
                v = m[base + 16 * line + byte]
                for bit in range(8):
                    if v & (0x80 >> bit):
                        x = 20 + (byte * 8 + bit) * S
                        d.rectangle([x, y0 + line * S, x + S - 1, y0 + line * S + S - 1], fill=ink)
        if base == 0xD800:
            x = 20 + (14 * 8 + 1) * S
            yy = y0 + 15 * S
            on = m[0xD8FE] & 0x40
            d.rectangle([x - 4, yy - 4, x + S + 3, yy + S + 3], outline=(255, 90, 90), width=2)
            d.text((x + S + 8, yy - 10), f'A: $D8FE = ${m[0xD8FE]:02X}' + (' (bit 6 set)' if on else ''),
                   fill=(255, 90, 90), font=f12)
        y = y0 + 16 * S + 28
    notes = ['How to read:',
             '- each picture is 16 map rows of 128 columns; BuildRadar $D5F8 sets a pixel where the block type is $0F or more',
             '- PlayInterrupt $D566 shows one picture each frame at (22,6): the two alternate, so ours and theirs flicker',
             '- the built-in level\'s scenery spells a word (in Cyrillic) across the window: the level asks to LOAD MAP',
             '- A: byte $D8FE is line 15, column 113; GiveFactory $BB61 for record 26 sets its bit 6 at frame 9938',
             '  (AddBuilding $BC43 on the cell 4 pages above the empty record\'s door (0,0)), a pixel of nothing']
    for t in notes:
        d.text((20, y), t, fill=K.DIM if t.startswith('-') or t.startswith(' ') else K.TEXT, font=f12)
        y += 17
    d.text((20, H - 22), f'python3 tools/zsB_fig_logic.py radar --frame {a.frame} --out {rel(a.out)}', fill=K.DIM,
           font=f11)
    out.save(a.out)
    print(a.out, out.size)


def esc_none(text):
    return text


MAP0 = os.path.join(CASE, 'work', 'zsB', 'deep-map0')
LAST0 = 24416


def fig_battle(a):
    """NELEV_00 on HARD: robots, factories, shots, kills and captures over the game"""
    r = I.Recording(MAP0, CACHE)
    fx, ours, theirs, fo, ft = [], [], [], [], []
    for f in range(a.step, LAST0 + 1, a.step):
        m = r.memory(f)
        fx.append(f)
        ours.append(sum(alive(m, i) for i in range(24)))
        theirs.append(sum(alive(m, i) for i in range(24, 48)))
        own = [m[POINTS + 5 * k + 3] for k in range(4, 28)]
        fo.append(sum(1 for o in own if o & 0x40))
        ft.append(sum(1 for o in own if o & 0x20))
    ev = {n: [f for f, _ in r.executions(addr, LAST0 + 2, 300)] for n, addr in
          [('fire', 0xB6D6), ('kill', 0xB116), ('give', 0xBB61), ('day', 0xAE38)]}
    kills = []
    for f in ev['kill']:
        b0, b1 = r.memory(f - 1), r.memory(f + 2)
        gone = [i for i in range(48) if b0[ROBOTS + 16 * i + 1] and not b1[ROBOTS + 16 * i + 1]]
        kills.append((f, gone[0] if gone else None))
    gives = []
    for f in ev['give']:
        b0, b1 = r.memory(f - 1), r.memory(f + 2)
        ch = [k for k in range(28) if b0[POINTS + 5 * k + 3] != b1[POINTS + 5 * k + 3]]
        gives.append((f, ch[0] if ch else None, b1[POINTS + 5 * ch[0] + 3] if ch else 0))
    fig, (ax, bx, cx) = plt.subplots(3, 1, figsize=(12, 8.2), dpi=90, sharex=True,
                                     gridspec_kw=dict(height_ratios=[3, 2, 1.4]))
    style(fig, [ax, bx, cx])
    ax.step(fx, ours, where='post', color=OURS, lw=2, label='our robots (slots 0-23)')
    ax.step(fx, theirs, where='post', color=THEIRS, lw=2, label='the enemy\'s robots (slots 24-47)')
    for f in ev['day']:
        for x in (ax, bx, cx):
            x.axvline(f, color='#777', ls=':', lw=1)
        ax.text(f + 80, 25.5, 'midnight', color=DIM, fontsize=8, va='top')
    ax.set_ylim(0, 26)
    ax.set_ylabel('live robots', color=DIM)
    ax.legend(loc='center left', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    bx.step(fx, fo, where='post', color=OURS, lw=2, label='factories we own (owner bit 6)')
    bx.step(fx, ft, where='post', color=THEIRS, lw=2, label='factories the enemy owns (owner bit 5)')
    for f, k, o in gives:
        c = OURS if o & 0x40 else THEIRS
        bx.plot([f], [23.2], marker='v', color=c, ms=7)
        bx.text(f, 21.0, str(k), color=c, fontsize=7, ha='center', va='top')
    bx.text(150, 29.3, esc('triangles: GiveFactory $BB61, the record it handed over (index = record: 28 points)'),
            color=FG, fontsize=8.5, va='top')
    bx.set_ylim(0, 30)
    bx.set_ylabel('of 24 factories', color=DIM)
    bx.legend(loc='center left', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    cx.vlines(ev['fire'], 0.55, 0.95, color='#d9a441', lw=1)
    cx.text(150, 1.2, esc(f'FireShot $B6D6: {len(ev["fire"])} shots'), color='#d9a441', fontsize=8.5)
    for f, i in kills:
        c = OURS if i is not None and i < 24 else THEIRS
        cx.plot([f], [0.25], marker='x', color=c, ms=8, mew=2)
    nk_o = sum(1 for _, i in kills if i is not None and i < 24)
    cx.text(150, 0.1, esc(f'RobotDestroyed $B116: {len(kills)} robots, {nk_o} ours (green x), '
                          f'{len(kills) - nk_o} theirs (red x)'), color=FG, fontsize=8.5)
    cx.set_ylim(-0.1, 1.5)
    cx.set_yticks([])
    cx.set_xlim(0, LAST0)
    cx.set_xlabel(f'frame of work/zsB/deep-map0 (counts sampled every {a.step} frames); dotted: DailyProduction '
                  '$AE38'.replace('$', '\\$'), color=DIM)
    fig.suptitle(esc('NELEV_00 on HARD: the enemy takes most factories and outnumbers us; the fights start on day 3'),
                 color=FG, fontsize=12, x=0.01, ha='left')
    fig.text(0.01, 0.005, f'python3 tools/zsB_fig_logic.py battle --out {rel(a.out)}', color='#8a8e9a', fontsize=9)
    fig.tight_layout(rect=(0, 0.02, 1, 0.96))
    fig.savefig(a.out, facecolor=fig.get_facecolor())
    print(a.out, 'gives', gives, 'kills', kills)


def fig_fight(a):
    """the first fight of deep-map0: the strengths of the two robots, each hit's damage against MoveShot's formula"""
    r = I.Recording(MAP0, CACHE)
    f0, f1, st = a.frame, a.frame + 260, 2
    fx = list(range(f0, f1 + 1, st))
    mems = [r.memory(f) for f in fx]
    fires = [f for f, _ in r.executions(0xB6D6, LAST0 + 2, 300) if f0 <= f <= f1]
    kills = [f for f, _ in r.executions(0xB7D7, LAST0 + 2, 300) if f0 <= f <= f1]
    gone = [f for f, _ in r.executions(0xB116, LAST0 + 2, 300) if f0 <= f <= f1]
    fighters = sorted({i for m in mems for i in range(48) if m[ROBOTS + 16 * i + 1] and m[ROBOTS + 16 * i + 12] != 100})
    live_shots = sum(1 for m in mems for k in range(5) if m[0xD7D3 + 9 * k + 1])
    WEAP = {1: 'cannon', 2: 'missiles', 3: 'phasers'}
    fig, ax = plt.subplots(figsize=(12, 6.2), dpi=90)
    style(fig, [ax])
    notes = []
    for i in fighters:
        ys = [m[ROBOTS + 16 * i + 12] if m[ROBOTS + 16 * i + 1] else None for m in mems]
        ys = [(y - 256 if y is not None and y > 127 else y) for y in ys]
        c = OURS if i < 24 else THEIRS
        ax.step(fx, [y if y is not None else np.nan for y in ys], where='post', color=c, lw=2,
                label=f'slot {i} ({"ours" if i < 24 else "the enemy"})')
        for k in range(1, len(ys)):
            if ys[k - 1] is not None and ys[k] is not None and ys[k] < ys[k - 1]:
                m = mems[k - 1]
                rec_ = robot(m, i)
                h, g = rec_[9], rec_[13]
                per = (60 - h - g) // 4
                got = ys[k - 1] - ys[k] if ys[k] > 0 else None
                if got is None:
                    text = f'{ys[k - 1]} -> dying ($FC)'
                    w = None
                else:
                    w = next((w for w in (1, 2, 3) if per * (w + 1) == got), None)
                    text = f'-{got}'
                ax.annotate(esc(text), xy=(fx[k], ys[k]), xytext=(fx[k] + 3, ys[k] + 8), color=c, fontsize=9)
                notes.append(f'frame {fx[k - 1]}-{fx[k]}: slot {i} hit, height +$09 = {h}, ground +$0D = {g}: '
                             f'(60 - {h} - {g}) / 4 = {per} a point; ' +
                             (f'{per} x {w + 1} = {per * (w + 1)}: {WEAP[w]}' if w else
                              f'{ys[k - 1]} left: any weapon ({per * 2} or more) kills, strength $FC, dying'
                              if got is None else 'no weapon fits'))
    for f in fires:
        ax.axvline(f, color='#d9a441', lw=0.9, ls='--')
    for f in kills:
        ax.axvline(f, color='#ff5252', lw=1.6)
    for f in gone:
        ax.axvline(f, color='#ff5252', lw=1, ls=':')
        ax.text(f + 2, 104, esc('RobotDestroyed $B116'), color='#ff5252', fontsize=8)
    ax.text(fires[0] + 2, 112, esc('dashed: FireShot $B6D6; red line: MoveShotKill $B7D7'), color='#d9a441', fontsize=8.5)
    ax.set_ylim(-12, 118)
    ax.set_xlim(f0, f1 + 20)
    ax.set_ylabel('strength +$0C (signed)'.replace('$', '\\$'), color=DIM)
    ax.set_xlabel(f'frame of work/zsB/deep-map0 (every {st} frames); the robots whose strength left 100', color=DIM)
    ax.legend(loc='lower left', fontsize=9, frameon=False, labelcolor='#d6d8e0')
    y = 0.30
    for t in notes + [f'shot records $D7D3 live at the {len(fx)} sampled frames: {live_shots} '
                      '(each shot hit in the turn it was fired: FireShot takes the first step at once)']:
        fig.text(0.07, y, esc(t), color=DIM, fontsize=8.5)
        y -= 0.033
    fig.suptitle(esc('The first fight of the NELEV_00 game: each hit takes (60 - height - ground) / 4 x (weapon + 1) '
                     'of strength'), color=FG, fontsize=11.5, x=0.01, ha='left')
    fig.text(0.01, 0.005, f'python3 tools/zsB_fig_logic.py fight --frame {a.frame} --out {rel(a.out)}',
             color='#8a8e9a', fontsize=9)
    fig.tight_layout(rect=(0, 0.34, 1, 0.96))
    fig.savefig(a.out, facecolor=fig.get_facecolor())
    print(a.out, 'fires', fires, 'kills', kills, 'gone', gone, 'fighters', fighters)
    print('\n'.join(notes))

def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('what')
    p.add_argument('--out')
    p.add_argument('--frame', type=int, default=20000)
    p.add_argument('--step', type=int, default=120)
    a = p.parse_args()
    if a.out:
        os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    globals()['fig_' + a.what](a)


if __name__ == '__main__':
    main()
