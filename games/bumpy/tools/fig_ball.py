#!/usr/bin/env python3
"""Doc 10's ball figures, drawn from the game's own tables in build/game.bin (no emulator):

    python3 tools/fig_ball.py arcs      docs/img/ball/arcs.png: the five moves as strobes, each step's picture at the
                                        address the step's offset gives, from a ball resting on cell 14
    python3 tools/fig_ball.py steps     docs/img/ball/steps.png: the step handler each state runs at each step
    python3 tools/fig_ball.py levels    docs/img/ball/levels.png: per level, the hazards and tools of its record and
                                        the frames the RZX's player took (work/stage2/rzx-states.tsv)
    python3 tools/fig_ball.py all

The ball's place is a CPC screen address: $C000 + (line AND 7) x $800 + (line / 8) x 80 + byte. Each move step adds a
word of the state's offset table (BounceOffsets $AEBB, LeftOffsets $AF35, RightOffsets $AFAF, UpOffsets $B054,
DownOffsets $B10A) to it, as BallStepMove $AE30 does. A CPC byte is 4 Spectrum pixels (the blitters show its low
nibble); the Spectrum line is the CPC line - 7 (SpectrumLines $B52D).
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(CASE))
sys.path.insert(0, os.path.join(ROOT, 'kit'))
sys.path.insert(0, HERE)
import kitlib  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'ball')
BASE = 0x61A8
IMG = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
LST = kitlib.Listing(os.path.join(CASE, 'build', 'game.lst'))


def b(a):
    return IMG[a - BASE]


def w(a):
    return b(a) | b(a + 1) << 8


def words(a, n):
    return [w(a + 2 * i) for i in range(n)]


def cpc_xy(addr):
    """(x pixels, CPC line) of a CPC screen address"""
    rel = (addr - 0xC000) & 0x3FFF
    line8, rem = rel >> 11, rel & 0x7FF
    return (rem % 80) * 4, (rem // 80) * 8 + line8


def picture(addr, width, rows):
    """rows of pixels: the low nibble of each CPC byte, bit 3 first (as DrawSprite $E318 shows it)"""
    return [[(b(addr + y * width + c) >> (3 - i)) & 1 for c in range(width) for i in range(4)] for y in range(rows)]


STATES = [  # name, BallState, offsets table, checks table, steps, frames table or None
    ('bounce (state 0)', 0, 0xAEBB, 0xAE9B, 16, None),
    ('left (state 1)', 1, 0xAF35, 0xAF15, 16, 0xC502),
    ('right (state 2)', 2, 0xAFAF, 0xAF8F, 16, 0xC4E2),
    ('up (state 3)', 3, 0xB054, 0xB044, 8, None),
    ('down (state 4)', 4, 0xB10A, 0xB0FA, 8, None),
]


def arcs():
    scale = 2
    cell = 14
    cell_addr = w(0xE131 + 2 * cell)
    start = (cell_addr + 0x2F62) & 0xFFFF
    W = 1050
    font, small = kitlib.font(15), kitlib.font(12)
    panels = []
    for name, state, offs, _, n, frames in STATES:
        addr = start
        pts = []
        for step in range(n):
            addr = (addr + w(offs + 2 * step)) & 0xFFFF
            sprite = w(frames + 2 * step) if frames else 0x67E8
            pts.append((step, addr, sprite))
        panels.append((name, offs, pts))
    # the window round cell 14 in Spectrum pixels (x from the left edge, y the CPC line)
    x0, y0, vw, vh = 52, 42, 104, 92
    scale = 3
    pw, ph = vw * scale, vh * scale
    H = 64 + 2 * (ph + 40)
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'The ball\'s five moves from the offset tables, from a ball resting on cell 14 (x3)',
           fill=kitlib.TEXT, font=font)
    d.text((10, 30), 'dots: the ball\'s centre after each step (its number beside); outlines: the picture at the first '
           'and the last step; grey: platform type 1 ($7788)', fill=kitlib.DIM, font=small)
    plat = picture(0x7788, 8, 4)

    def put(ox, oy, px, py, pic, colour, fill=False):
        for y, rowp in enumerate(pic):
            for x, v in enumerate(rowp):
                if v:
                    X, Y = (px + x - x0) * scale, (py + y - y0) * scale
                    if 0 <= X < pw and 0 <= Y < ph:
                        if fill:
                            d.rectangle((ox + X, oy + Y, ox + X + scale - 1, oy + Y + scale - 1), fill=colour)
                        else:
                            d.rectangle((ox + X, oy + Y, ox + X + scale - 1, oy + Y + scale - 1), outline=colour)

    for i, (name, offs, pts) in enumerate(panels):
        col, row = i % 3, i // 3
        ox = 12 + col * (pw + 34)
        oy = 76 + row * (ph + 40)
        d.rectangle((ox - 1, oy - 1, ox + pw, oy + ph), fill=(0, 0, 0), outline=kitlib.DIM)
        d.text((ox, oy - 18), '%s: %s $%04X' % (name, LST.name(offs), offs), fill=kitlib.TEXT, font=small)
        for c in (7, 8, 13, 14, 15, 19, 20, 21):
            px, py = cpc_xy(w(0xE131 + 2 * c))
            put(ox, oy, px, py, plat, (130, 130, 140), True)
        n = len(pts)
        sx, sy = cpc_xy(start)
        put(ox, oy, sx, sy, picture(0x67E8, 4, 10), (70, 70, 200))
        for k, (step, addr, sprite) in enumerate(pts):
            t = (k + 1) / n
            colour = (int(60 + 195 * t), int(60 + 160 * t), int(220 - 140 * t))
            px, py = cpc_xy(addr)
            if k == n - 1:
                put(ox, oy, px, py, picture(sprite, 4, 10), colour)
            cx, cy = ox + (px + 8 - x0) * scale, oy + (py + 5 - y0) * scale
            d.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=colour)
            vertical = name.startswith(('bounce', 'up', 'down'))
            if vertical:
                tx = cx + (10 if k % 2 == 0 else -24)
                ty = cy - 7
            else:
                tx, ty = cx - 6, cy - (22 if k % 2 == 0 else -6)
            d.text((tx, ty), str(step), fill=colour, font=small)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'arcs.png')
    im.save(path)
    print('arcs:', os.path.relpath(path, CASE))
    for name, offs, pts in panels:
        print(name, ['%d:(%d,%d)' % ((s,) + cpc_xy(a)) for s, a, _ in pts])


ROLE = [  # (substring of the handler's name, colour, short text)
    ('Step0', (230, 90, 80), 'leave'), ('Step15', (200, 110, 230), 'land'), ('Step13', (240, 200, 70), 'object'),
    ('Step9', (90, 200, 120), 'spring'), ('Step1', (90, 150, 250), ''), ('Step5', (70, 210, 220), ''),
    ('Step8', (250, 150, 60), ''), ('Step3', (90, 150, 250), ''), ('Step4', (250, 150, 60), ''),
    ('Step6', (240, 200, 70), 'object'), ('Step7', (200, 110, 230), ''), ('Step2', (90, 150, 250), ''),
    ('Step1', (90, 150, 250), ''), ('Idle', (50, 50, 62), ''), ('Step1', (90, 150, 250), ''),
]
JOB = {
    'BounceStep0': 'sound, wear', 'BounceStep1': 'crumble', 'BounceStep9': 'spring', 'BounceStep11': 'spr. 2',
    'BounceStep13': 'object', 'BounceStep14': 'spr. 3', 'BounceStep15': 'spr. 4',
    'LeftStep0': 'sound, tilt', 'LeftStep5': 'wall?', 'LeftStep8': 'cell -1', 'LeftStep9': 'spring, water',
    'LeftStep11': 'spr. 2', 'LeftStep13': 'object', 'LeftStep14': 'spr. 3', 'LeftStep15': 'fire, spikes',
    'RightStep0': 'sound, tilt', 'RightStep5': 'wall?', 'RightStep8': 'cell +1', 'RightStep9': 'spring, water',
    'RightStep11': 'spr. 2', 'RightStep13': 'object', 'RightStep14': 'spr. 3', 'RightStep15': 'fire, spikes',
    'UpStep0': 'sound, bricks', 'UpStep1': 'bricks', 'UpStep2': 'bricks', 'UpStep3': 'spring, bricks',
    'UpStep4': 'above?', 'UpStep5': 'cell -6', 'UpStep6': 'object', 'UpStep7': 'bricks',
    'DownStep0': 'water', 'DownStep3': 'cell +6', 'DownStep4': 'spring', 'DownStep5': 'object',
    'DownStep7': 'fire, spikes',
}


KIND = {'sound': (140, 140, 250), 'crumble': (240, 200, 70), 'spring': (90, 200, 120), 'object': (250, 150, 60),
        'wall?': (70, 210, 220), 'above?': (70, 210, 220), 'cell': (240, 120, 180), 'fire': (230, 90, 80),
        'bricks': (200, 170, 120), 'water': (90, 150, 250)}


def steps():
    font, small, tiny = kitlib.font(15), kitlib.font(12), kitlib.font(11)
    W = 1050
    cw, chh, left = 54, 56, 122
    H = 90 + 5 * chh + 90
    im = Image.new('RGB', (W, H), kitlib.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), 'What each move does at each step: the check table\'s handler (StepDispatch $AE4B) before the '
           'move', fill=kitlib.TEXT, font=font)
    d.text((10, 30), 'grey: the tail only (move and draw). After the last step: LandingCheck $B09E (bounce, left, '
           'right, down) or ChooseNextState $B7E4 (up)', fill=kitlib.DIM, font=small)
    for s in range(16):
        d.text((left + s * cw + 20, 56), str(s), fill=kitlib.TEXT, font=small)
    for r, (name, state, offs, checks, n, _) in enumerate(STATES):
        y = 76 + r * chh
        d.text((10, y + 8), name, fill=kitlib.TEXT, font=small)
        d.text((10, y + 26), LST.name(checks), fill=kitlib.DIM, font=tiny)
        for s in range(n):
            h = LST.name(w(checks + 2 * s))
            job = JOB.get(h, '')
            colour = KIND.get(job.split(',')[0].split(' ')[0].replace('spr.', 'spring'), (200, 200, 200))
            x = left + s * cw
            d.rectangle((x, y, x + cw - 4, y + chh - 6), fill=colour if job else (36, 36, 46))
            if job:
                for k, part in enumerate(job.split(', ')):
                    d.text((x + 3, y + 3 + 14 * k), part, fill=(0, 0, 0), font=tiny)
            d.text((x + 3, y + chh - 20), '$%04X' % w(checks + 2 * s), fill=(0, 0, 0) if job else kitlib.DIM,
                   font=tiny)
    y = 76 + 5 * chh + 6
    for k, text in enumerate([
            'The handlers are BounceStep0 $C778 ... DownStep7 $CECC (src/game/ball.asm); the address under each box.',
            '"wall?" reads the screen byte beside the ball (LeftStep5, RightStep5); "above?" the cell above (UpStep4).',
            '"cell -1", "+1", "-6", "+6": BallCell $AA44 changes; the object is taken at step 13 (up 6, down 5).',
            '"fire spikes": the landing on a burning platform or spikes kills at the last step.']):
        d.text((10, y + 18 * k), text, fill=kitlib.DIM, font=small)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'steps.png')
    im.save(path)
    print('steps:', os.path.relpath(path, CASE))
    for name, state, offs, checks, n, _ in STATES:
        print(name, [LST.name(w(checks + 2 * s)) for s in range(n)])


def levels():
    import res_formats as RF
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'figure.facecolor': '#101018', 'axes.facecolor': '#16161f',
                         'axes.edgecolor': '#888', 'axes.labelcolor': '#ddd', 'xtick.color': '#ccc',
                         'ytick.color': '#ccc', 'text.color': '#eee', 'text.parse_math': False})
    lv = RF.levels_parse(open(os.path.join(RF.RES, 'levels', 'levels.txt'), 'rb').read())
    frames = {}
    rows = [ln.split('\t') for ln in open(os.path.join(CASE, 'work', 'stage2', 'rzx-states.tsv')).read().split('\n')[1:]
            if ln]
    first = {}
    for r in rows:
        f, level = int(r[0]), int(r[1])
        first.setdefault(level, f)
    order = sorted(first.items(), key=lambda x: x[1])
    for (a, fa), (bb, fb) in zip(order, order[1:]):
        frames[a] = fb - fa
    xs = list(range(100))
    hz = [sum(1 for c in L['cells'] if c & 15 in (8, 9, 12)) for L in lv]
    crumb = [sum(1 for c in L['cells'] if c & 15 in (2, 3, 4)) for L in lv]
    locks = [sum(1 for c in L['cells'] if c >> 4 in (1, 2, 3)) for L in lv]
    prizes = [L['prizes'] for L in lv]
    fig, axes = plt.subplots(3, 1, figsize=(10.5, 7.6), dpi=100, sharex=True)
    axes[0].bar(xs, [frames.get(x, 0) for x in xs], color='#60c0ff')
    axes[0].set_ylabel('RZX frames')
    axes[0].set_title('Frames the RZX\'s player took per level (from the level\'s first frame to the next level\'s; '
                      'the hall-of-fame pause included)', fontsize=10)
    axes[1].bar(xs, prizes, color='#f0c040', label='prizes (record byte 37)')
    axes[1].plot(xs, crumb, color='#90e060', label='crumbling platforms (2-4)')
    axes[1].legend(fontsize=9, loc='upper left')
    axes[1].set_title('What the level asks for', fontsize=10)
    axes[2].bar(xs, hz, color='#ff6040', label='deadly cells (fire 8/9, spikes 12)')
    axes[2].plot(xs, locks, color='#e0b0ff', label='locks (walls 1-3)')
    axes[2].legend(fontsize=9, loc='upper left')
    axes[2].set_title('What the level holds against the player', fontsize=10)
    axes[2].set_xlabel('level (0-99, as Level $AB00 counts)')
    fig.suptitle('The difficulty is the layout: per level, from src/res/levels/levels.txt and the RZX', fontsize=13)
    fig.tight_layout()
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, 'levels.png')
    fig.savefig(path)
    print('levels:', os.path.relpath(path, CASE))
    import statistics
    halves = [(lo, statistics.mean(frames[x] for x in range(lo, lo + 25) if x in frames),
               statistics.mean(hz[lo:lo + 25]), statistics.mean(prizes[lo:lo + 25])) for lo in (0, 25, 50, 75)]
    for h in halves:
        print('levels %d-%d: frames %.0f, deadly %.1f, prizes %.1f' % (h[0], h[0] + 24, h[1], h[2], h[3]))


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if what in ('arcs', 'all'):
        arcs()
    if what in ('steps', 'all'):
        steps()
    if what in ('levels', 'all'):
        levels()


if __name__ == '__main__':
    main()
