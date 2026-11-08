#!/usr/bin/env python3
"""The pictures of docs/01-game-design.md (and a few the other documents share): the box beside the game, the
screens with their parts named, the recorded scenes as GIFs, the rating ladder.

    python3 tools/fig_design.py [NAME ...]          # all when none named; the list: python3 tools/fig_design.py --list

The scans are ZXDB's (work/extras: Elite_Front.jpg, Elite_KeyboardOverlay.jpg, Elite_ShipIdentificationChart.jpg);
the screens are the recordings' (work/<rec>/frames/FFFFFF.scr, read once by tools/grab.py; the snapshots' screens
work/<rec>/screens/FFFFFF.scr); nothing here runs an emulator.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, '..', '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen as Z  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

CASE = os.path.dirname(HERE)
EXTRAS = os.path.join(CASE, 'work', 'extras')
BG = (14, 14, 20)
TEXT = (220, 220, 230)
LABEL = (150, 200, 255)
DIM = (130, 130, 145)
CALLOUT = (255, 210, 70)


def out(*p):
    path = os.path.join(CASE, 'docs', 'img', *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def scr(rec, frame):
    for sub in ('frames', 'screens'):
        p = os.path.join(CASE, 'work', rec, sub, '%06d.scr' % frame)
        if os.path.isfile(p):
            return open(p, 'rb').read()
    raise SystemExit('no screen %s %d (tools/grab.py)' % (rec, frame))


def shot(rec, frame, scale=2):
    return Z.render(scr(rec, frame), scale).convert('RGB')


def caption(im, text, size=15, colour=TEXT, pad=8):
    f = K.font(size)
    w = im.width
    lines, line = [], ''
    for word in text.split():
        t = (line + ' ' + word).strip()
        if ImageDraw.Draw(im).textlength(t, font=f) > w - 2 * pad:
            lines.append(line)
            line = word
        else:
            line = t
    lines.append(line)
    h = (size + 5) * len(lines) + 2 * pad
    out_im = Image.new('RGB', (w, im.height + h), BG)
    out_im.paste(im, (0, 0))
    d = ImageDraw.Draw(out_im)
    for i, ln in enumerate(lines):
        d.text((pad, im.height + pad + i * (size + 5)), ln, fill=colour, font=f)
    return out_im


def pad(im, h):
    o = Image.new('RGB', (im.width, h), BG)
    o.paste(im, (0, 0))
    return o


def side_by_side(images, gap=16, title=None, size=17):
    h = max(i.height for i in images)
    top = size + 19 if title else 0
    w = sum(i.width for i in images) + gap * (len(images) - 1)
    im = Image.new('RGB', (w, h + top), BG)
    if title:
        ImageDraw.Draw(im).text((4, 8), title, fill=TEXT, font=K.font(size))
    x = 0
    for i in images:
        im.paste(i, (x, top))
        x += i.width + gap
    return im


def anim(rec, frames, path, label=None, delay=90, hold=1500, scale=2):
    """a GIF of recorded screens, each with a line under it: label(frame) or the frame"""
    pics = []
    for f in frames:
        im = shot(rec, f, scale)
        if label is not None:
            text = label(f) if callable(label) else '%s frame %d: %s' % (rec, f, label)
            im = caption(im, text, 14, LABEL, 6)
        pics.append(im)
    h = max(p.height for p in pics)
    pics = [p if p.height == h else pad(p, h) for p in pics]
    K.save_gif(path, pics, [delay] * (len(pics) - 1) + [hold])
    print('wrote', os.path.relpath(path, CASE), len(pics), 'pictures')


def staged(rec, stages, path, delay=90, hold=1500):
    """a GIF over several windows of one recording, each with its own label: [(first, last, step, text)]"""
    frames = []
    for lo, hi, st, text in stages:
        frames += [(f, text) for f in range(lo, hi + 1, st)]
    texts = dict(frames)
    anim(rec, [f for f, _t in frames], path, lambda f: '%s %d: %s' % (rec, f, texts[f]), delay, hold)


# --------------------------------------------------------------------------------------------------------------

def cover():
    front = Image.open(os.path.join(EXTRAS, 'Elite_Front.jpg')).convert('RGB')
    front = front.resize((int(front.width * 384 / front.height), 384), Image.LANCZOS)
    load = Image.open(out('loading-screen.png')).convert('RGB')
    im = side_by_side([caption(front, 'The box: Firebird\'s inlay (ZXDB scan)', 14, LABEL),
                       caption(load, 'The loading screen the tape draws first (TZX block 5; 3.1)', 14, LABEL)],
                      title='The box and the tape: what a buyer saw in 1985')
    im.save(out('design', 'cover.png'))
    print('wrote docs/img/design/cover.png')


def title():
    anim('d1', range(0, 451, 10), out('design', 'title.gif'), 'the title: the ship turns by roll $8C and pitch $94 '
         'a pass (TurnTitleShip)', 100)


# the flight screen's parts: (x, y) on the 256 x 192 screen, the label, the side the label goes ('b0'..'b2': below,
# in that row)
DASH = [
    ((14, 140), 'FS: fore shield', 'l'), ((14, 148), 'AS: aft shield', 'l'), ((14, 156), 'FU: fuel', 'l'),
    ((14, 164), 'CT: cabin temperature', 'l'), ((14, 172), 'LT: laser temperature', 'l'),
    ((14, 180), 'AL: altitude', 'l'), ((30, 186), 'the missiles: one block each', 'l'),
    ((72, 144), 'the condition: green, yellow, red', 'b2'),
    ((128, 168), 'the scanner: ships as dots on sticks (height)', 'b0'),
    ((180, 147), 'the compass: the planet or station', 'b1'),
    ((242, 140), 'SP: speed', 'r'), ((242, 148), 'RL: roll', 'r'), ((242, 156), 'DC: pitch (dive / climb)', 'r'),
    ((242, 172), '1-4: the four energy banks', 'r'),
    ((128, 64), 'the 3D view, 256 x 128, the sight in the middle', 'r'),
    ((10, 4), 'the view\'s frame and name', 'r'),
]


def dashboard(rec='f1', frame=1250):
    s = 3
    base = shot(rec, frame, s)
    f = K.font(21)
    meas = ImageDraw.Draw(base)
    L = 30 + max(meas.textlength(t, font=f) for _, t, side in DASH if side == 'l')     # room for the labels
    R = 30 + max(meas.textlength(t, font=f) for _, t, side in DASH if side == 'r')
    L, R = int(L), int(R)
    im = Image.new('RGB', (L + base.width + R, base.height + 56 + 100), BG)
    im.paste(base, (L, 48))
    d = ImageDraw.Draw(im)
    d.text((8, 10), 'The flight screen, every part named (%s frame %d, the front view after the launch)' % (rec, frame),
           fill=TEXT, font=K.font(25))
    for (x, y), text, side in DASH:
        px, py = L + x * s, 48 + y * s
        if side == 'l':
            d.line((px, py, L - 10, py), fill=CALLOUT, width=1)
            d.text((L - 14 - d.textlength(text, font=f), py - 11), text, fill=CALLOUT, font=f)
        elif side == 'r':
            d.line((px, py, L + base.width + 10, py), fill=CALLOUT, width=1)
            d.text((L + base.width + 14, py - 11), text, fill=CALLOUT, font=f)
        else:
            ty = 48 + base.height + 10 + 28 * int(side[1])
            d.line((px, py, px, ty), fill=CALLOUT, width=1)
            tw = d.textlength(text, font=f)
            d.text((px + 4 if px < L + base.width / 2 else px - tw - 4, ty - 2), text, fill=CALLOUT, font=f)
        d.ellipse((px - 3, py - 3, px + 3, py + 3), outline=CALLOUT)
    im.save(out('design', 'dashboard.png'))
    print('wrote docs/img/design/dashboard.png')


NAMES = {}


def scenes():
    staged('f1', [(948, 1148, 4, 'the launch: the tunnel rings, then space')], out('design', 'launch.gif'))
    staged('f1', [(1252, 1500, 4, 'flight: the planet ahead, the stardust, the station\'s dot')],
           out('design', 'flight.gif'))
    staged('w1', [(4200, 4560, 4, 'the energy gone: the ship explodes, GAME OVER')], out('design', 'gameover.gif'))
    staged('k2', [(2484, 2700, 4, 'witch space: a missile armed (T), locked, fired (F); E.C.M. (E)'),
                  (2704, 3300, 8, 'the military laser at the Thargoids and Thargons'),
                  (3304, 3460, 4, 'the energy bomb (W): the view flashes; Thargoids are spared')],
           out('design', 'fight.gif'))
    staged('dk', [(1704, 2200, 4, 'the manual dock: the slot lined up, flown in')], out('design', 'dock.gif'))
    staged('dk', [(3000, 3420, 8, 'the docking computer (C): the dock starts at once, the tunnel, the status page')],
           out('design', 'dockcomp.gif'))
    staged('cs', [(0, 400, 4, 'debris after a kill: the pilot turns onto a plate of alloys'),
                  (840, 1008, 4, 'the plate passed under the nose: scooped, Alloys on the message line')],
           out('design', 'scoop.gif'))
    staged('m1', [(2400, 2800, 8, 'the 32nd jump outside galaxy 1: the sun goes nova, the view red, the fuel leaks; '
                                  'the escape pod')], out('design', 'nova.gif'))
    staged('k2', [(2560, 2596, 1, 'a ship destroyed: ExplosionPoint at 2572, then HitFlash grows a red disc from its '
                                  'point, on the screen itself')], out('design', 'explosion.gif'), delay=80)


def ladder():
    """the rating ladder: the combat score's thresholds (RatingScores, RatingHigh) and the kills each needs"""
    import rtplot as P
    # thresholds as the score (24 bits): the middle byte 9, 17, 33, 65, 129 (top 0); the top byte 1, 3, 11, 26
    ranks = [('Harmless', 0), ('Mostly Harmless', 9 * 256), ('Poor', 17 * 256), ('Average', 33 * 256),
             ('Above Average', 65 * 256), ('Competent', 129 * 256), ('Dangerous', 3 * 65536),
             ('Deadly', 11 * 65536), ('Elite', 26 * 65536)]
    # per kill: half the blueprint's +$15 word (fig_ships.load headers)
    import fig_ships as F
    _shapes, headers = F.load()
    per = {}
    for name, _shape, b in headers:
        per[name] = (b[0x15] | b[0x16] << 8) // 2
    kinds = [('Thargoid', 'Thargoid'), ('Viper', 'Viper (police)'), ('Sidewinder', 'Sidewinder'),
             ('CobraPirate', 'Cobra pirate')]
    names = {'Thargoid': 'Thargoids', 'Viper': 'Vipers', 'Sidewinder': 'Sidewinders', 'CobraPirate': 'Cobra pirates'}
    fig, (ax, tx) = P.figure(9, 6.6, nrows=1, ncols=2, gridspec_kw={'width_ratios': [1, 1.25]})
    ys = range(len(ranks))
    for i, (r, score) in enumerate(ranks):
        ax.barh(i, max(score, 1), color=P.PALETTE[i % len(P.PALETTE)], height=0.6, log=True)
        n = ['%s %s' % (format(-(-score // per[k]), ','), names[k]) for k, _ in kinds if per.get(k)]
        txt = ('%s points: %s\nor %s' % (format(score, ','), ' or '.join(n[:2]), ' or '.join(n[2:]))
               if score else '0 points: the start')
        tx.text(0, i, txt, va='center', fontsize=9, color=P.TEXT)
    tx.set_ylim(-0.5, len(ranks) - 0.5)
    tx.axis('off')
    ax.set_yticks(list(ys))
    ax.set_yticklabels([r for r, _ in ranks], fontsize=10)
    ax.set_xscale('log')
    ax.set_xlim(1, 1e7)
    ax.set_xlabel('the combat score $D060 (24 bits), log scale', fontsize=9)
    ax.set_title('The rating ladder: Elite needs 26 x 65536 points,\nabout %s Thargoids or %s Sidewinders' % (
        format(-(-26 * 65536 // per['Thargoid']), ','), format(-(-26 * 65536 // per['Sidewinder']), ',')),
        fontsize=11, loc='left')
    P.save(fig, 'docs/img/design/ladder.png')


def status():
    ims = [caption(shot('d1', 500, 2), 'd1 500: a new commander, Harmless, 100.0 Cr', 23, LABEL),
           caption(shot('dk', 750, 2), 'dk 750: the rich fixture, every item fitted', 23, LABEL),
           caption(shot('m1', 9588, 2), 'm1 9588: Competent after the nova reward', 23, LABEL)]
    side_by_side(ims, size=28, title='The status page: rank, legal status, cash and equipment').save(out('design', 'status.png'))
    print('wrote docs/img/design/status.png')


def marked(im, boxes, scale=2):
    """yellow frames round screen areas (x0, y0, x1, y1 in Spectrum pixels)"""
    d = ImageDraw.Draw(im)
    for x0, y0, x1, y1 in boxes:
        d.rectangle((x0 * scale, y0 * scale - 1, x1 * scale - 1, y1 * scale), outline=CALLOUT, width=2)
    return im


def market():
    ims = [caption(shot('t1', 400, 2), 't1 400: Lave\'s market, 100.0 Cr, the hold empty', 23, LABEL),
           caption(marked(shot('t1', 1000, 2), [(0, 48, 256, 64)]), 't1 1000: after buying 5 t food and 2 t textiles: stock and cash down', 23,
                   LABEL),
           caption(shot('t1', 1500, 2), 't1 1500: the equip page (key 4): what Lave sells', 23, LABEL)]
    side_by_side(ims, size=28, title='Trading at Lave: the market before and after a buy, and the equip page').save(
        out('design', 'market.png'))
    print('wrote docs/img/design/market.png')


def charts():
    ims = [caption(shot('d1', 1500, 2), 'd1 1500: the galactic chart (I), 256 systems', 23, LABEL),
           caption(shot('d1', 1700, 2), 'd1 1700: the short range chart (O) round Lave', 23, LABEL),
           caption(shot('d1', 1300, 2), 'd1 1300: the data on Lave (P)', 23, LABEL)]
    side_by_side(ims, size=28, title='The charts and the data page').save(out('design', 'charts.png'))
    print('wrote docs/img/design/charts.png')


def shipchart():
    chart = Image.open(os.path.join(EXTRAS, 'Elite_ShipIdentificationChart.jpg')).convert('RGB')
    chart = chart.resize((int(chart.width * 620 / chart.height), 620), Image.LANCZOS)
    gal = Image.open(out('ships', 'gallery.png')).convert('RGB')
    gal = gal.resize((int(gal.width * 620 / gal.height), 620), Image.LANCZOS)
    side_by_side([caption(chart, 'The box\'s Ship Identification Chart (ZXDB scan)', 14, LABEL),
                  caption(gal, 'The game\'s own drawing of its 19 blueprints (tools/shipsim.py)', 14, LABEL)],
                 title='The ships as the box shows them, and as the game draws them').save(out('design', 'shipchart.png'))
    print('wrote docs/img/design/shipchart.png')


def hud():
    stages = [(2484, 2516, 4, 'witch space among four Thargoids: the light yellow, four missiles'),
              (2520, 2540, 4, 'T: the missile cell green (armed), red once locked'),
              (2544, 2608, 4, 'F: fired, one missile glyph fewer (4 to 3)'),
              (2612, 2696, 4, 'E lit: an E.C.M. is on (a Thargoid\'s, then ours)'),
              (2700, 3300, 8, 'FS empty: the fore shield is down, the light red; bank 1 drains under fire'),
              (3304, 3460, 4, 'W: the energy bomb used up; the fight goes on')]
    frames = [(f, t) for lo, hi, st, t in stages for f in range(lo, hi + 1, st)]
    pics = []
    for f, t in frames:
        im = shot('k2', f, 3).crop((0, 128 * 3, 768, 192 * 3))
        pics.append(caption(im, 'k2 %d: %s' % (f, t), 14, LABEL, 6))
    h = max(p.height for p in pics)
    pics = [p if p.height == h else pad(p, h) for p in pics]
    K.save_gif(out('hud', 'dashboard-fight.gif'), pics, [90] * (len(pics) - 1) + [1500])
    print('wrote docs/img/hud/dashboard-fight.gif', len(pics), 'pictures')


def reaction():
    staged('j1', [(1470, 1506, 2, 'Kempston left held from 1476: the RL marker slides left, roll -15 by 1506'),
                  (1508, 1544, 2, 'released at 1506: the damping eases the roll back, still not 0 after 40 frames'),
                  (1546, 1600, 2, 'right held from 1546: the roll swings through 0 to +15, then eases back')],
           out('controls', 'reaction.gif'), delay=70)


def keyboard():
    """the box's keyboard overlay alone, 900 px wide: the key map it is compared with is keymap.png just above it in
    doc 05 (a copy of the map under it only repeated that figure)"""
    ov = Image.open(os.path.join(EXTRAS, 'Elite_KeyboardOverlay.jpg')).convert('RGB')
    W = 900
    ov = ov.resize((W - 16, int(ov.height * (W - 16) / ov.width)), Image.LANCZOS)
    im = Image.new('RGB', (W, ov.height + 46), BG)
    d = ImageDraw.Draw(im)
    d.text((8, 9), 'The box\'s keyboard overlay (ZXDB scan): every label matches the code\'s key map; Y is blank',
           fill=TEXT, font=K.font(16))
    im.paste(ov, (8, 38))
    im.save(out('controls', 'overlay.png'))
    print('wrote docs/img/controls/overlay.png')


def lenslok():
    first = os.path.join(CASE, 'work', 'atlas', 'live', 'gif-accepted', '0000.scr')   # accepted.gif's first screen
    screen = Z.render(open(first, 'rb').read(), 2)
    atlas = Image.open(out('lenslok', 'atlas-live.png')).convert('RGB')
    cell = atlas.crop((12, 60, 841, 173))           # the first cell, under the two-line title
    W = 900
    parts = [caption(screen.crop((0, 0, 512, 240)), 'the top of the Lenslok screen (2x; run a, before "Ns" is '
                     'typed; the rest is black): the strip of slices, the lens held over it', 15, LABEL),
             caption(cell, 'c1\'s challenge: the strip at $C2A9 as drawn (left), through the model lens (colour), '
                     'the answer "si"', 15, LABEL)]
    im = Image.new('RGB', (W, 40 + sum(i.height + 14 for i in parts)), BG)
    ImageDraw.Draw(im).text((8, 9), 'The Lenslok: scrambled slices on the screen, two letters through the lens',
                            fill=TEXT, font=K.font(17))
    y = 40
    for i in parts:
        im.paste(i, ((W - i.width) // 2, y))
        y += i.height + 14
    im.save(out('design', 'lenslok.png'))
    print('wrote docs/img/design/lenslok.png')


ALL = ['cover', 'lenslok', 'title', 'dashboard', 'scenes', 'ladder', 'status', 'market', 'charts', 'shipchart', 'keyboard', 'reaction', 'hud']

if __name__ == '__main__':
    if sys.argv[1:] == ['--list']:
        print(' '.join(ALL))
        sys.exit()
    for n in sys.argv[1:] or ALL:
        globals()[n]()
