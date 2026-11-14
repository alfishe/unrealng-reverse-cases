#!/usr/bin/env python3
"""One pass of TraceBeam $8ED6 replayed by SkoolKit's simulator from a recording's memory, drawn vertex by vertex
(doc 10).

    python3 tools/fig_trace.py DUMP.cpu.bin OUT.gif [--title T]      # the trace as an animation
    python3 tools/fig_trace.py DUMP.cpu.bin --list                   # the vertices as text
    python3 tools/fig_trace.py DUMP.cpu.bin --list --poke 6,5=3E     # an experiment: cell row 6, column 5 = $3E

--poke R,C=CODE (repeatable) puts a cell code into the dumped LevelGrid ($FD23 + 17R + C) and its four characters
from CellTable $8200 into the character map ($E000 + 32 (2R + 1) + 2C + 1), as RenderGrid would: an experiment,
not a recording.

DUMP is a 64 K CPU view from tools/ttd_dump.py. The beam's start is set as MainLoop $859B sets it (BeamDirection
$8ECB = $8378, BeamX $8ECD = $8376, BeamY $8ECE = $8377), then TraceBeam runs to its RET. Each BeamStep $8EDD entry
is a vertex: its x, y in half-cells, the direction, the step count $8EBF, and what the cell at a centre made of it
(the handler the trace jumped to). The level is drawn by the game's own BuildLevel from the dump's LevelGrid.
"""
import os
import sys

V = os.environ.get('SKOOLKIT_VENV')
if V:
    for d in os.listdir(os.path.join(V, 'lib')):
        sys.path.insert(0, os.path.join(V, 'lib', d, 'site-packages'))
from skoolkit.simulator import Simulator  # noqa: E402

from PIL import Image, ImageDraw  # noqa: E402

import figlib  # noqa: E402

HANDLERS = {
    0x8FFB: 'BeamMirror: a mirror turns the beam',
    0x8F40: 'BeamBurn: a cell burnt, the beam ends',
    0x8F6A: 'BeamMine: a mine, the beam ends (MINE ALERT)',
    0x8F7D: 'BeamBlock: a block',
    0x8F84: 'BeamReceiver: the receiver',
    0x8FAE: 'BeamAtLaser: the laser',
    0x8FC5: 'BeamBackToLaser: OVERLOAD',
    0x9014: 'PrismTurn: the prism, a random turn',
    0x903E: 'FibreEntry: a fibre-optic end',
    0x9344: 'BeamAbsorbIn: an absorbing wall, the beam ends',
    0x938F: 'BeamReflectIn: a reflecting wall',
    0x92FD: 'BeamInPolariser: a polariser',
    0x9317: 'PolariserPassIn: along its axis, passed',
    0x93DC: 'ReflectInSlant: InBounceTable $8140 bounce',
    0x93D7: 'ReflectInBack: straight back, OVERLOAD',
    0x965A: 'ReflectOutSlant: OutBounceTable $8080 bounce',
    0x9655: 'ReflectOutBack: straight back, OVERLOAD',
}
NAMES = ['E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW', 'N', 'NNE', 'NE', 'ENE']


def poke(mem, specs):
    m = bytearray(mem)
    for spec in specs:
        rc, code = spec.split('=')
        r, c = (int(v) for v in rc.split(','))
        code = int(code, 16)
        m[0xFD23 + 17 * r + c] = code
        ch = m[0x8200 + 4 * (code & 0x7F):0x8200 + 4 * (code & 0x7F) + 4]
        a = 0xE000 + 32 * (2 * r + 1) + 2 * c + 1
        m[a], m[a + 1], m[a + 32], m[a + 33] = ch
    return bytes(m)


def trace(mem):
    m = bytearray(mem)
    m[0x8ECB] = m[0x8378]
    m[0x8ECD] = m[0x8376]
    m[0x8ECE] = m[0x8377]
    m[0x8381] = 0
    sp = 0x5F00
    m[sp] = m[sp + 1] = 0
    s = Simulator(m, {'PC': 0x8ED6, 'SP': sp})
    steps = []
    events = []
    while s.registers[24] != 0:
        pc = s.registers[24]
        if pc == 0x8EDD:
            steps.append({'x': m[0x8ECD], 'y': m[0x8ECE], 'dir': m[0x8ECB], 'len': m[0x8EBF], 't': s.registers[25],
                          'ev': []})
        if pc in HANDLERS and steps:
            if HANDLERS[pc] not in steps[-1]['ev']:
                steps[-1]['ev'].append(HANDLERS[pc])
            events.append((len(steps) - 1, HANDLERS[pc]))
        s.run()
    flags = {'LevelDone': m[0x8ED2], 'LifeLost': m[0x8ED3], 'BeamOnMine': m[0x8ED4], 'BeamInLaser': m[0x8ED5]}
    return steps, s.registers[25], flags


def base_picture(mem):
    img = figlib.image()
    for r in range(9):
        img[0xB000 + 15 * r:0xB000 + 15 * r + 15] = mem[0xFD23 + 17 * r:0xFD23 + 17 * r + 15]
    pic, _ = figlib.play_area(img, 0)
    return pic


def main():
    dump = sys.argv[1]
    mem = open(dump, 'rb').read()
    pokes = [sys.argv[i + 1] for i, v in enumerate(sys.argv) if v == '--poke']
    mem = poke(mem, pokes)
    steps, total, flags = trace(mem)
    if '--list' in sys.argv:
        for i, st in enumerate(steps):
            print('%3d x %2d y %2d dir %2d len %2d %s' % (i, st['x'], st['y'], st['dir'], st['len'],
                                                         '; '.join(st['ev'])))
        print('T', total, flags)
        return
    out = sys.argv[2]
    title = sys.argv[sys.argv.index('--title') + 1] if '--title' in sys.argv else 'TraceBeam $8ED6, one pass'
    S = 3
    pic = base_picture(mem).resize((256 * S, 160 * S), Image.NEAREST)
    pic = Image.blend(pic, Image.new('RGB', pic.size, (0, 0, 0)), 0.35)
    W, H = 1050, 160 * S + 120
    frames = []
    for k in range(len(steps) + 1):
        o = Image.new('RGB', (W, H), figlib.BG)
        o.paste(pic, (10, 70))
        d = ImageDraw.Draw(o)
        figlib.text(d, (10, 8), title, 17, figlib.ACCENT)
        figlib.text(d, (10, 34), 'Each picture one BeamStep $8EDD: the vertex (half-cells), the direction, the length '
                    '$8EBF, what the cell did', 12, figlib.DIM)
        pts = [(10 + st['x'] * 8 * S, 70 + st['y'] * 8 * S) for st in steps[:k]]
        if len(pts) > 1:
            d.line(pts, fill=(255, 80, 255), width=3)
        for (x, y), st in zip(pts, steps[:k]):
            r = 5 if st['x'] % 2 == 0 and st['y'] % 2 == 0 else 3
            d.ellipse([x - r, y - r, x + r, y + r], outline=(255, 255, 255))
        px = 10 + 256 * S + 14
        if k == 0:
            figlib.text(d, (px, 80), 'the start: the half-cell', 13, figlib.FG)
            figlib.text(d, (px, 98), 'in front of the laser', 13, figlib.FG)
        else:
            st = steps[k - 1]
            x, y = pts[-1]
            d.ellipse([x - 8, y - 8, x + 8, y + 8], outline=figlib.ACCENT, width=2)
            centre = st['x'] % 2 == 0 and st['y'] % 2 == 0
            lines = ['step %d of %d' % (k, len(steps)),
                     'x %d  y %d' % (st['x'], st['y']),
                     'direction %d (%s)' % (st['dir'], NAMES[st['dir']] if st['dir'] < 16 else 'ended'),
                     'length %d' % st['len'],
                     'a cell\'s centre' if centre else 'between cells',
                     'cell row %d col %d' % (st['y'] // 2 - 1, st['x'] // 2 - 1) if centre else '']
            for j, s in enumerate(lines):
                figlib.text(d, (px, 80 + 20 * j), s, 13, figlib.FG)
            for j, e in enumerate(st['ev']):
                for jj, part in enumerate(e.split(': ')):
                    figlib.text(d, (px, 220 + 40 * j + 18 * jj), part, 12, figlib.ACCENT if jj == 0 else figlib.DIM)
        if k == len(steps):
            figlib.text(d, (px, 380), 'the trace ends: %d T' % total, 13, figlib.FG)
            for j, (n, v) in enumerate(flags.items()):
                figlib.text(d, (px, 400 + 18 * j), '%s $%02X' % (n, v), 12, figlib.ACCENT if v else figlib.DIM)
        figlib.text(d, (10, H - 40), 'Magenta: the beam\'s path so far; circles: vertices (large at a cell\'s centre);'
                    ' the level as BuildLevel draws the dumped grid (dimmed)', 12, figlib.DIM)
        frames.append(o.convert('P', palette=Image.ADAPTIVE, colors=128))
    dur = [260] * len(frames)
    dur[-1] = 3000
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=dur, loop=0, optimize=True)
    print(out, len(steps), 'steps', total, 'T', flags)


if __name__ == '__main__':
    main()
