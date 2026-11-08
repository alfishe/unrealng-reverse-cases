"""The look of the case's matplotlib figures: the kit's dark panel, its text colours, one palette for routines.

    import rtplot as P
    fig, ax = P.figure(10, 5)
    ...
    P.save(fig, 'docs/img/runtime/x.png')
"""
import os

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)


def rgb(c):
    return tuple(x / 255 for x in c)


BACKGROUND = rgb((14, 14, 20))
PANEL = rgb((24, 24, 32))
TEXT = rgb((210, 210, 220))
DIM = rgb((120, 120, 135))
EXEC = rgb((80, 230, 110))
READ = rgb((80, 160, 255))
WRITE = rgb((255, 210, 70))
HOT = rgb((210, 80, 40))

# routines and modules: a fixed order of distinct colours (tab20 reordered, the first ones the strongest)
PALETTE = [rgb(c) for c in [
    (80, 160, 255), (255, 170, 60), (80, 230, 110), (240, 90, 90), (190, 130, 255), (255, 230, 90), (60, 210, 210),
    (255, 120, 200), (170, 200, 90), (150, 150, 255), (230, 150, 110), (120, 220, 170), (200, 200, 200),
    (255, 90, 160), (110, 170, 120), (180, 110, 70), (100, 120, 200), (220, 220, 140), (140, 90, 160),
    (90, 130, 140)]]
OTHER = rgb((70, 70, 85))

plt.rcParams.update({
    'figure.facecolor': BACKGROUND, 'axes.facecolor': PANEL, 'savefig.facecolor': BACKGROUND,
    'axes.edgecolor': DIM, 'axes.labelcolor': TEXT, 'xtick.color': TEXT, 'ytick.color': TEXT, 'text.color': TEXT,
    'axes.titlecolor': TEXT, 'grid.color': (0.25, 0.25, 0.3), 'font.size': 10, 'axes.titlesize': 12,
    'legend.facecolor': PANEL, 'legend.edgecolor': DIM, 'legend.labelcolor': TEXT, 'font.family': 'DejaVu Sans',
})


def colours(names, fixed=None):
    """name -> colour, in the order given (fixed: {name: colour} first)"""
    out = dict(fixed or {})
    i = 0
    for n in names:
        if n in out:
            continue
        out[n] = PALETTE[i % len(PALETTE)]
        i += 1
    return out


MAX_W = 9.6     # inches at 100 dpi: GitHub shows a page 900 px wide, so a wider figure only shrinks its text


def figure(w, h, **kw):
    """a figure of w x h inches, drawn at most MAX_W wide: a wider request is scaled down whole (its text keeps its
    point size, so it comes out larger against the plot; the height gets 10 % back for the labels)"""
    k = min(1.0, MAX_W / w)
    return plt.subplots(figsize=(w * k, h * k * (1.1 if k < 1 else 1)), **kw)


def wrap_titles(fig):
    """titles wider than the figure (the suptitle) or than their axes are broken into lines, so that the picture
    is not widened by them and shrunk on the page"""
    import textwrap
    fig.canvas.draw()
    r = fig.canvas.get_renderer()
    wide = [(fig._suptitle, fig.bbox.width * 0.98)] if fig._suptitle else []
    for ax in fig.axes:
        for tt in (ax.title, ax._left_title, ax._right_title):
            wide.append((tt, max(ax.bbox.width * 1.1, 200)))
    changed = False
    for tt, room in wide:
        text = tt.get_text()
        w = tt.get_window_extent(r).width
        if text and w > room:
            flat = ' '.join(x.strip() for x in text.split('\n'))
            n = max(1, len(text.split('\n')))
            per = max(20, int(len(flat) / n * room / w))
            tt.set_text(textwrap.fill(flat, per))
            changed = True
    if (changed or fig._suptitle) and not isinstance(fig.get_layout_engine(),
                                                     plt.matplotlib.layout_engine.ConstrainedLayoutEngine):
        bottom = 0.0
        for lg in fig.legends:                       # a figure legend under the axes keeps its room
            bb = lg.get_window_extent(r)
            if bb.y1 < fig.bbox.height / 2:
                bottom = max(bottom, (bb.y1 + 6) / fig.bbox.height)
        try:
            top = 1.0
            for _ in range(3):                       # tight_layout, then clear the suptitle if it still overlaps
                fig.tight_layout(rect=(0, bottom, 1, top))
                if not fig._suptitle:
                    break
                fig.canvas.draw()
                low = fig._suptitle.get_window_extent(r).y0
                high = max(max(a.get_tightbbox(r).y1 for a in fig.axes), 0)
                if high < low - 2:
                    break
                top -= (high - low + 8) / fig.bbox.height
        except Exception:
            pass


def save(fig, path, dpi=100):
    path = path if os.path.isabs(path) else os.path.join(CASE, path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    # an address is written $C000: the titles, labels and legends are plain text, never mathtext (the tick labels,
    # set at draw time, keep their mathtext for the log axes)
    for t in fig.findobj(plt.matplotlib.text.Text):
        if '$' in t.get_text() and '\\' not in t.get_text():
            t.set_parse_math(False)
    wrap_titles(fig)
    fig.savefig(path, dpi=dpi, bbox_inches='tight')
    plt.close(fig)
    print('wrote', os.path.relpath(path, CASE))


# the modules (src/game/<module>.asm) in plain words: a figure labels a block by what it does, the module small
OLD_MODULE = {'screen': 'backbuffer', 'screens': 'dockedscreens', 'cross': 'chartcursor', 'circle': 'circles',
              'memory': 'lowdata', 'main': 'startup', 'actions': 'combat', 'state': 'gamestate',
              'ui': 'menuhelpers', 'text': 'textprint', 'tables': 'squaretable', 'draw': 'drawships',
              'lines': 'linedraw', 'flight': 'flightloop', 'ships': 'shipmotion'}
MODULE_WORDS = {
    'backbuffer': 'back buffer: clear + copy to screen', 'drawships': '3D maths: rotate, project, faces',
    'linedraw': 'line drawing', 'shipmotion': 'ship motion', 'sound': 'sound (beeper)',
    'textprint': 'text printing', 'scanner': 'scanner (radar), energy bars', 'stardust': 'stardust dots',
    'circles': 'sun and planet circles', 'keyboard': 'keyboard poll, interrupt', 'dashboard': 'dashboard gauges',
    'halt': 'HALT (waiting)', 'startup': 'title, pause menu, rate copy', 'flightloop': 'flight loop',
    'tunnel': 'tunnel rings', 'galaxy': 'galaxy generator', 'dockedscreens': 'docked pages (charts, market)',
    'market': 'buying and selling', 'rom': 'ROM', 'tactics': 'ship tactics (AI)', 'combat': 'laser, collisions, spawning',
    'menuhelpers': 'menu helpers', 'chartcursor': 'chart cursor', 'gamestate': 'messages, cash, cargo',
    'commander': 'commander tape, message line', 'hyperspace': 'jumps and missions', 'lowdata': 'low data',
    'squaretable': 'table of squares', 'other': 'other (data)',
}


def module(m):
    """a module name as the annotation has it now (profiles cached before the rename keep the old names)"""
    return OLD_MODULE.get(m, m)


def module_label(m, small=True):
    """'plain words (module)' for a legend"""
    m = module(m)
    words = MODULE_WORDS.get(m, m)
    return '%s  [%s]' % (words, m) if small and words != m else words


# the heaviest routines in plain words (the profile figures' legends)
ROUTINE_WORDS = {
    'CopyThird': 'copy the back buffer to the screen', 'ClearView': 'clear the back buffer',
    'PrintOther': 'print a character', 'PrintCode': 'print a token', 'PlotChar': 'draw a character',
    'RotateNormal': 'rotate a face normal', 'LineDownX': 'line drawing', 'CopyRates': 'copy the steering rates',
    'FlightLoop': 'the main loop', 'ChartCursorKeys': 'move the chart cursor', 'SelectView': 'choose the view',
    'JumpKeys': 'the jump keys', 'PauseMenu': 'the pause check', 'ScanKeyboard': 'keyboard poll',
    'OutlinePixel': 'planet outline pixel', 'MulBits': 'multiply', 'StardustFront': 'stardust dots',
    'DivideFrac8': 'divide', 'Divide16': 'divide', 'SoundSweep': 'sound: a sweep', 'SoundPulses': 'sound: pulses',
    'SoundNoise': 'sound: noise', 'HALT': 'waiting for the interrupt', 'Multiply8': 'multiply',
    'ProjectVertices': 'project the vertices', 'DrawEdges': 'draw the edges', 'DrawLine': 'line drawing',
    'FaceVisibility': 'hidden faces', 'DrawScanner': 'the scanner (radar)', 'UpdateSlot': 'move a ship',
}


def routine_label(n):
    w = ROUTINE_WORDS.get(n)
    return '%s (%s)' % (n, w) if w else n


def place_labels(fig, ax, items, fontsize=8.5, colour=None):
    """labels beside points without overlaps: items are (x, y, text, 'left' | 'right'[, colour]); call it after the
    layout. Each label goes to its point's side; one that would overlap a label already placed moves down, step by
    step, and is joined to its point by a thin line."""
    fig.canvas.draw()
    k = fig.dpi / 72.0
    placed = []
    for it in sorted(items, key=lambda i: -ax.transData.transform((i[0], i[1]))[1]):
        x, y, text, side = it[:4]
        col = it[4] if len(it) > 4 else (colour or TEXT)
        px, py = ax.transData.transform((x, y))
        lines = text.split('\n')
        w = max(len(s) for s in lines) * fontsize * 0.6 * k
        h = len(lines) * fontsize * 1.25 * k
        x0 = px + 6 if side == 'right' else px - 6 - w
        dy = 0
        while any(x0 < bx1 and x0 + w > bx0 and py - dy - h / 2 < by1 and py - dy + h / 2 > by0
                  for bx0, by0, bx1, by1 in placed):
            dy += 3
        placed.append((x0, py - dy - h / 2, x0 + w, py - dy + h / 2))
        ax.annotate(text, (x, y), xytext=((6 if side == 'right' else -6) / k, -dy / k), textcoords='offset points',
                    fontsize=fontsize, color=col, va='center', ha='left' if side == 'right' else 'right', zorder=4,
                    arrowprops={'arrowstyle': '-', 'color': DIM, 'lw': 0.6, 'shrinkA': 0, 'shrinkB': 3}
                    if dy else None)
