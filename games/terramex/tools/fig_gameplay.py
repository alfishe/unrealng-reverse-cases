#!/usr/bin/env python3
"""The figures of doc 10 (the gameplay), from src/res, the built image and memory samples of the recordings.

    python3 tools/fig_gameplay.py docs/img/gameplay [--samples work/docs/tmC/go/vars.jsonl]

Writes into the folder:
- jump-fall.png: the hero's Y in the gameover recording: the jump onto the Spring and the bounce (frames 405-530),
  and the fall from room $10 into room $1C that kills him (frames 1278-1376), against JumpRise and FallPasses;
- death-frames.png: the four death frame lists (FallDeathFrames $A8BF) as the explorer's sprites;
- item-uses.png: where each item lies and where it is used, on the map.

The samples file holds one JSON line a frame: {"frame": F, "5B00": hex of $5B00-$5C47} (memory_at: the state at the
frame's start), made by work/docs/tmC/sample.py over the gameover recording.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import fig_rooms as FR  # noqa: E402
import res_formats as RF  # noqa: E402
from fig_objects import ITEMS, sprite_img, title, BG, TEXT, DIM, W, YEL  # noqa: E402

IMG = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
ORG = 0x7200


def mem(a, n):
    return IMG[a - ORG:a - ORG + n]


def samples(path):
    out = {}
    for line in open(path):
        d = json.loads(line)
        out[d['frame']] = bytes.fromhex(d['5B00'])
    return out


def jump_fall(sm, out):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    g = lambda m, a: m[a - 0x5B00]  # noqa: E731
    plt.rcParams.update({'text.parse_math': False, 'font.size': 11, 'axes.facecolor': '#16161e', 'figure.facecolor': '#0e0e14',
                         'text.color': '#d2d2dc', 'axes.labelcolor': '#d2d2dc', 'xtick.color': '#d2d2dc',
                         'ytick.color': '#d2d2dc', 'axes.edgecolor': '#555566'})
    fig, ax = plt.subplots(1, 2, figsize=(10.5, 5.4), dpi=100)
    fig.suptitle('The hero\'s Y, gameover recording (memory_at: the state at each frame\'s start)', fontsize=13)
    # the jump and the bounce
    fr = [f for f in range(405, 531) if f in sm]
    ys, rooms, st = [], [], []
    for f in fr:
        m = sm[f]
        ys.append(g(m, 0x5B05) + (0x68 if g(m, 0x5C01) == 0x1C else 0))
        rooms.append(g(m, 0x5C01))
        st.append(g(m, 0x5C06))
    cols = {0: '#d2d2dc', 2: '#ffdc5a', 5: '#e682dc'}
    for s_ in (0, 2, 5):
        ax[0].scatter([f for f, s in zip(fr, st) if s == s_], [y for y, s in zip(ys, st) if s == s_], s=10,
                      c=cols[s_], label={0: 'status 0', 2: 'status 2: JumpArc', 5: 'status 5: BounceUp'}[s_])
    rise = [4, 3, 3, 3, 2, 2, 1, 0, 0, 0, -1, -2, -2, -3, -3, -3, -4]
    y = 0x48 + 0x68
    pred = [y]
    for r in rise[:11]:
        y -= r
        pred.append(y)
    pf = [415 + 2.75 * i for i in range(len(pred))]
    ax[0].plot(pf, pred, c='#5ad2e6', lw=1, ls='--', label='JumpRise $AE9E, one step a pass')
    ax[0].axhline(0x68, c='#555566', lw=1)
    ax[0].text(404, 0x68 - 2, 'room $10 above, room $1C below', fontsize=10, color='#a0a0b0')
    ax[0].invert_yaxis()
    ax[0].set_xlabel('frame')
    ax[0].set_ylabel('Y $5B05 (room $1C: + $68)')
    ax[0].set_title('Jump straight up onto the Spring, then the bounce', fontsize=11)
    ax[0].legend(fontsize=9, facecolor='#16161e', edgecolor='#555566', loc='lower right')
    # the fall
    fr = [f for f in range(1278, 1377) if f in sm]
    ys, fp, st = [], [], []
    for f in fr:
        m = sm[f]
        ys.append(g(m, 0x5B05) + (0x68 if g(m, 0x5C01) == 0x1C else 0))
        fp.append(g(m, 0x5C05))
        st.append(g(m, 0x5C06))
    ax[1].scatter(fr, ys, s=10, c=['#f06e64' if s else '#d2d2dc' for s in st])
    ax[1].axhline(0x68, c='#555566', lw=1)
    ax[1].invert_yaxis()
    ax[1].set_xlabel('frame')
    ax[1].set_title('Off the edge in room $10 with the umbrella: 21 fall passes', fontsize=11)
    a2 = ax[1].twinx()
    a2.plot(fr, fp, c='#78a0ff', drawstyle='steps-post')
    a2.axhline(20, c='#78a0ff', lw=1, ls=':')
    a2.set_ylabel('FallPasses $5C05 (blue)', color='#78a0ff')
    a2.text(1279, 20.5, '20: a landing kills', fontsize=10, color='#78a0ff')
    ax[1].text(1322, 0x30 + 0x68 - 8, 'status 26 at 1361,\n18 at 1372 (red)', fontsize=10, color='#f06e64')
    for a in ax:
        a.grid(alpha=0.2)
    fig.tight_layout()
    fig.savefig(os.path.join(out, 'jump-fall.png'))


def death_frames(out):
    ex = RF.to_bytes('sprites/explorer-0.png', 'single',
                     open(os.path.join(RF.RES, 'sprites/explorer-0.png'), 'rb').read())['sprites/explorer-0.bin']
    cr = FR.resources()['sprites/creatures.bin']
    lists, a = [], 0xA8BF
    for _ in range(4):
        lst = []
        while IMG[a - ORG] != 0xFF:
            lst.append(IMG[a - ORG])
            a += 1
        a += 1
        lists.append(lst)
    names = ['status 26 FallDeath $A888: the fall, tile $A5, the balloon crash, room $2E',
             'status 23 SilentDeath $A8A8: room $20\'s pad, the radiation, room $39',
             'status 24 CreatureDeath $A89E: a creature\'s touch, the beam',
             'status 25 Room1ADeath $A88F: a snake\'s bite']
    sounds = ['sound 0 at the end', 'no sound', 'sound 3 every pass', 'sound 4 at the end']
    rowh = 118
    o = Image.new('RGB', (W, 80 + 5 * rowh + 40), BG)
    d = ImageDraw.Draw(o)
    title(d, 'The four death frame lists (FallDeathFrames $A8BF), explorer 0\'s sprites',
          'Runs of one frame merged (x n = n passes); then status 18 (LoseLifeWait $A9EE) for 50 passes')
    f14 = K.font(14)
    y = 74 - rowh
    for i, lst in enumerate(lists):
        y += rowh
        d.text((12, y), names[i], font=K.font(16), fill=YEL)
        d.text((12, y + 20), f'{len(lst)} frames, {sounds[i]}', font=f14, fill=DIM)
        runs = []
        for fr in lst:
            if runs and runs[-1][0] == fr:
                runs[-1][1] += 1
            else:
                runs.append([fr, 1])
        x = 12
        for fr, n in runs:
            if fr == 0x7F:
                sp = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
            elif fr < 0x40:
                sp = sprite_img(ex, fr)
            else:
                sp = sprite_img(cr, fr - 0x40)
            if x > W - 70:
                x = 12
                y += rowh - 20
            d.rectangle((x - 2, y + 42, x + 50, y + 92), outline=(60, 60, 75))
            o.paste(sp, (x, y + 44), sp)
            d.text((x, y + 94), f'${fr:02X}' + (f' x{n}' if n > 1 else ''), font=f14, fill=TEXT)
            x += 64
    d.text((12, y + 124), 'python3 tools/fig_gameplay.py docs/img/gameplay', font=f14, fill=DIM)
    o = o.crop((0, 0, W, y + 146))
    o.save(os.path.join(out, 'death-frames.png'))


USES = [  # item, from room(s), to room(s), what
    (10, [0x14], [0x14, 0x08], 'hover'),
    (12, [0x16], [0x17, 0x1A, 0x10], 'snakes, rope'),
    (9, [0x07], [0x1D], 'barrel ride'),
    (6, [0x10], [0x0F], 'balloon'),
    (2, [0x0C], [0x2D], 'throw'),
    (13, [0x0A], [0x43], 'Silver Cross'),
    (29, [0x43], [0x39], 'creature flees'),
    (16, [0x27], [0x3E, 0x40], 'lever'),
    (11, [0x08], [0x19], 'bridge'),
    (24, [0x2C], [0x30], 'teleports'),
    (22, [0x04], [0x3C], 'radiation'),
    (15, [0x2D], [0x3B], 'gift 1'),
    (19, [0x31], [0x3B], 'gift 2'),
    (18, [0x34], [0x3B], 'gift 3'),
    (21, [0x3C], [0x3B], 'gift 4'),
    (17, [0x42], [0x3B], 'gift 5'),
    (23, [0x45], [0x3B], 'gift 6'),
]


def item_uses(out):
    r = FR.resources()
    isheet = r['sprites/items.bin']
    cw, ch = 86, 62
    o = Image.new('RGB', (W, 78 + 6 * (ch + 4) + 90), BG)
    d = ImageDraw.Draw(o)
    title(d, 'The items the RZX run needs: where each lies and where it is used',
          'From the HeldItem tests of the room scripts and statuses; arrows from the item\'s room to the room of use')
    cent = {}
    for room in range(72):
        lv, col = divmod(room, 12)
        x, y = 12 + col * cw, 74 + lv * (ch + 4)
        th = FR.room_image(r, room).resize((cw - 2, ch - 2), Image.LANCZOS)
        th = Image.blend(th, Image.new('RGB', th.size, (0, 0, 0)), 0.72)
        o.paste(th, (x, y))
        d.text((x + 2, y), f'{room:02X}', font=K.font(14), fill=(190, 190, 190))
        cent[room] = (x + cw // 2, y + ch // 2)
    pal = [(255, 220, 90), (90, 210, 230), (120, 220, 120), (240, 110, 100), (250, 170, 70), (120, 160, 255),
           (230, 130, 220)]
    for i, (item, src, dst, what) in enumerate(USES):
        col = pal[i % len(pal)]
        for s in src:
            for t in dst:
                if s == t:
                    continue
                (x1, y1), (x2, y2) = cent[s], cent[t]
                off = (i % 5 - 2) * 3
                d.line((x1 + off, y1 + off, x2 + off, y2 + off), fill=col, width=2)
                d.ellipse((x2 + off - 5, y2 + off - 5, x2 + off + 5, y2 + off + 5), fill=col)
        for s in src:
            sp = sprite_img(isheet, item, scale=1, ink=col)
            x, y = cent[s]
            o.paste(sp, (x - 12, y - 14), sp)
    for room, lab in ((0x3B, 'professor'), (0x30, 'crystal pad'), (0x1D, 'barrels'), (0x0F, 'balloon')):
        x, y = cent[room]
        d.text((x - 38, y + 14), lab, font=K.font(14), fill=(255, 255, 255))
    y0 = 74 + 6 * (ch + 4) + 8
    f14 = K.font(14)
    d.text((12, y0), 'Not drawn: the Umbrella (5, room $00) works anywhere. The key items of the explorer rooms: '
           'Unicycle $0B -> $2F,', font=f14, fill=DIM)
    d.text((12, y0 + 18), 'Flashgun $22 -> $47, Beer Barrel $2A -> $2E, Spurs $10 -> $46. The Party Manifesto, the '
           'other barrels.', font=f14, fill=DIM)
    d.text((12, y0 + 36), 'The Spring and the Trampoline bounce where they lie; the Cannon is never taken. '
           'Dot: the room of use.', font=f14, fill=DIM)
    d.text((12, y0 + 60), 'python3 tools/fig_gameplay.py docs/img/gameplay', font=f14, fill=DIM)
    o.save(os.path.join(out, 'item-uses.png'))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CASE, 'docs', 'img', 'gameplay')
    path = os.path.join(CASE, 'work', 'docs', 'tmC', 'go', 'vars.jsonl')
    if '--samples' in sys.argv:
        path = sys.argv[sys.argv.index('--samples') + 1]
    os.makedirs(out, exist_ok=True)
    jump_fall(samples(path), out)
    death_frames(out)
    item_uses(out)


if __name__ == '__main__':
    main()
