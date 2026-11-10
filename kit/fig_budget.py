#!/usr/bin/env python3
"""Where the CPU's time goes over a recording, per routine (or per module), from an L1 build (doc 02's figure).

    python3 ../../kit/fig_budget.py work/deep/l1.json docs/img/arch/budget.png --title "deep: where the time goes"
    python3 ../../kit/fig_budget.py L1 OUT --ann src/game/game.ann --ann src/sound/engine.ann,page=4,label=engine \\
        --ann src/game/glue.ann,range=5B00-5BFF [--top 24] [--by module] [--state "menu=work/menu/l1.json"]

Each instruction of l1.json carries its page, its count and its T-states summed over the recording (fields 2, 5 and
6). The T-states are summed per routine: the entry ("$ADDR c|b|w|t|s Name") at or before the instruction's address
in the .ann of the part it lies in; labels inside an entry count for it, code run inside a data entry counts for
that entry. A bar is a routine's share of all the recording's T-states (frames x the frame length); its colour is
its module, cut as kit/mkgame.py cuts the source: a @module runs from the first entry written after it up to the
next module's first entry, by address.

--ann PATH[,page=N[/N..]][,range=LO-HI][,delta=D][,label=L], one per part (default src/game/game.ann). The first
is the game: its modules are named as they are; the others' as "L (module)" (L defaults to the file's stem). An
instruction goes to the first part, filtered ones first, whose page (the L1's page of the instruction: on a 128K
the bank at $C000; give page=0/2/5 to the game of a 128K image) and range (hex, both ends included, default the
part's first entry to $FFFF) hold it; delta (signed hex) is added to the .ann's addresses when the code runs
elsewhere than the .ann writes it. Code in no part is one bar a page ("page N, no .ann", or the name --page-name
N=TEXT gives it); the ROM (the L1's pages named ROM n) is one bar; HALT is its own bar, its T-states the CPU
waiting for the interrupt.

The frame length: --frame, else the L1's T-states over its frames, taken as the nearest of 69888 (48K), 70908
(128K / +2 / +3) and 71680 (Pentagon) when it is within 1 % of one.

--state LABEL=L1 adds a panel for another window of the recording, e.g. the menu against play (the L1 sums over
its whole window, so a state is its own build: re_session.py build --from-frame F --to-frame G --into W);
--label names the first panel. The panels share the scale and the colours. The colours go to the modules by their
share in the first panel, the biggest first; --colour-order names modules that take the first colours, so the
figures of one case agree. --by module draws one bar a module instead of a routine.

The picture is --width pixels wide (1050, the figure limit) and as tall as its rows; a --note longer than the width
wraps onto more lines.
"""
import argparse
import json
import os
import re
import sys
from bisect import bisect_right

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib as K  # noqa: E402

ENTRY = re.compile(r'^\$([0-9A-Fa-f]{4}) ([cbwts]) (\w+)')
FRAMES = {69888: '48K', 70908: '128K', 71680: 'Pentagon'}
HALT_NAME = 'HALT (waiting)'
ROM_NAME = 'ROM'


class Part:
    def __init__(self, spec, first):
        path, *opts = spec.split(',')
        self.path, self.page, self.lo, self.hi, self.delta = path, None, None, 0xFFFF, 0
        self.label = os.path.splitext(os.path.basename(path))[0]
        for opt in opts:
            key, _, value = opt.partition('=')
            if key == 'page':
                self.page = {int(v) for v in value.split('/')}
            elif key == 'range':
                lo, _, hi = value.partition('-')
                self.lo, self.hi = int(lo.lstrip('$'), 16), int(hi.lstrip('$'), 16)
            elif key == 'delta':
                magnitude = int(value.lstrip('+-').lstrip('$'), 16)
                self.delta = -magnitude if value.startswith('-') else magnitude
            elif key == 'label':
                self.label = value
            else:
                sys.exit(f'--ann {spec}: unknown option {key}')
        self.first, self.filtered = first, self.page is not None or self.lo is not None
        # a module runs from the first entry written after its @module line to the next module's start, by
        # address, as kit/mkgame.py cuts the source (the .ann need not list the modules in address order)
        found, modules, pending = [], [], None
        for line in open(path, encoding='utf-8'):
            if line.startswith('@module '):
                pending = line.split()[1]
            m = ENTRY.match(line)
            if m:
                a = (int(m.group(1), 16) + self.delta) & 0xFFFF
                found.append((a, m.group(3)))
                if pending:
                    modules.append((a, pending))
                    pending = None
        if not found:
            sys.exit(f'{path}: no entries')
        modules.sort()
        module_starts = [a for a, _ in modules]

        def module_at(a):
            i = bisect_right(module_starts, a) - 1
            return modules[i][1] if i >= 0 else '?'
        self.entries = sorted((a, name, self.module(module_at(a))) for a, name in found)
        self.starts = [a for a, _, _ in self.entries]
        if self.lo is None:
            self.lo = self.starts[0]

    def module(self, name):
        return name if self.first else f'{self.label} ({name})'

    def holds(self, address, page):
        return (self.page is None or page in self.page) and self.lo <= address <= self.hi

    def routine(self, address):
        i = bisect_right(self.starts, address) - 1
        return self.entries[i][1:] if i >= 0 else (f'{self.label} ${address & 0xFF00:04X}', self.module('?'))


def frame_length(doc, given):
    if given:
        return given
    replay = doc['replay']
    if replay.get('frames') and replay.get('tstates'):
        ratio = replay['tstates'] / replay['frames']
        best = min(FRAMES, key=lambda f: abs(f - ratio))
        if abs(best - ratio) / best < 0.01:
            return best
        sys.exit(f'T-states per frame {ratio:.0f} is none of {sorted(FRAMES)}: give --frame')
    sys.exit('the L1 records no frames / T-states: give --frame')


def budget(path, parts, given_frame, page_names):
    doc = json.load(open(path))
    rom_pages = {p['page'] for p in doc.get('pages', []) if p.get('name', '').startswith('ROM')}
    frame = frame_length(doc, given_frame)
    frames = doc['replay']['frames']
    per, module_of, part_t, halt = {}, {}, {}, 0
    for z80, page, code, cls, count, tstates, *_ in doc['instructions']:
        a = int(z80[1:], 16)
        if code == '76':
            name, module, part = HALT_NAME, HALT_NAME, HALT_NAME
            halt += tstates
        elif page in rom_pages or page >= 256 or a < 0x4000:
            name, module, part = ROM_NAME, ROM_NAME, ROM_NAME
        else:
            owner = next((p for p in parts if p.holds(a, page)), None)
            if owner is None:
                name = module = part = page_names.get(page, f'page {page}, no .ann')
            else:
                name, module = owner.routine(a)
                part = owner.label
        per[name] = per.get(name, 0) + tstates
        module_of[name] = module
        part_t[part] = part_t.get(part, 0) + tstates
    return {'path': path, 'replay': doc['replay'], 'frame': frame, 'frames': frames, 'total': frames * frame,
            'per': per, 'module_of': module_of, 'part_t': part_t, 'halt': halt, 'busy': sum(per.values()) - halt}


def by_module(b):
    per = {}
    for name, t in b['per'].items():
        m = b['module_of'][name]
        per[m] = per.get(m, 0) + t
    return {**b, 'per': per, 'module_of': {m: m for m in per}}


def pct(t, total):
    v = 100 * t / total
    return f'{v:.2f}%' if v < 1 else f'{v:.1f}%'


def wrap(text, font, width, probe):
    """text cut into lines no wider than width pixels, at spaces"""
    lines, line = [], ''
    for word in text.split(' '):
        candidate = (line + ' ' + word) if line else word
        if line and probe.textlength(candidate, font=font) > width:
            lines.append(line)
            line = word
        else:
            line = candidate
    return lines + [line]


def draw(panels, args):
    W, bar_h, gap = args.width, 20, 4
    f, fb = K.font(12), K.font(15)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    rows_of = [sorted(b['per'].items(), key=lambda kv: -kv[1])[:args.top] for b in panels]
    names = [n for rows in rows_of for n, _ in rows]
    left = min(320, max(140, 20 + max(int(probe.textlength(n, font=f)) for n in names)))
    colours_used = []
    for b, rows in zip(panels, rows_of):
        for name, _ in rows:
            m = b['module_of'][name]
            if m not in colours_used:
                colours_used.append(m)
    # colours in the order of the modules' shares in the first panel (the biggest gets the first colour);
    # --colour-order puts named modules first, so the figures of one case can keep a module's colour
    palette = K.ROUTINE_COLOURS + [(255, 255, 255), (150, 110, 70), (90, 110, 200), (200, 200, 200)]
    share = {}
    for name, t in panels[0]['per'].items():
        m = panels[0]['module_of'][name]
        share[m] = share.get(m, 0) + t
    first = [m for m in args.colour_order if m != HALT_NAME]
    order = first + [m for m in sorted(share, key=lambda m: -share[m]) if m not in first and m != HALT_NAME]
    order += [m for m in colours_used if m not in order and m != HALT_NAME]
    colour_of = {m: palette[i % len(palette)] for i, m in enumerate(order)}
    colour_of[HALT_NAME] = K.DIM
    colours_used.sort(key=lambda m: order.index(m) if m in order else len(order))
    peak = max(t / b['total'] for b, rows in zip(panels, rows_of) for _, t in rows[:1])
    scale = (W - left - 90) / peak
    per_panel = [(40 if len(panels) > 1 else 0) + len(rows) * (bar_h + gap) + 8 for rows in rows_of]
    notes = [line for note in args.note for line in wrap(note, f, W - 20, probe)]
    # an upper bound: the legend may wrap after every module, each panel has two summary lines; cropped below
    footer = 70 + 16 * len(notes) + 16 * 6 * len(panels)
    H = 54 + sum(per_panel) + footer + 18 * (1 + len(colours_used))
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((10, 8), args.title, fill=K.TEXT, font=fb)
    y = 30
    for k, (b, rows) in enumerate(zip(panels, rows_of)):
        cover = 100 * sum(t for _, t in rows) / b['total']
        machine = FRAMES.get(b['frame'], 'frame')
        line = (f'share of all {b["total"]:,} T-states ({b["frames"]} frames x {b["frame"]}, {machine}); '
                f'the top {len(rows)} {"modules" if args.by == "module" else "routines"} cover {cover:.1f}%')
        if len(panels) > 1:
            r = b['replay']
            d.text((10, y + 12), f'{b["label"]}: frames {r.get("first_frame", 0)}-{r.get("last_frame", b["frames"])}',
                   fill=K.TEXT, font=fb)
            d.text((10, y + 32), line, fill=K.DIM, font=f)
            y += 54
        else:
            d.text((10, y), line, fill=K.DIM, font=f)
            y += 40
        for name, t in rows:
            colour = colour_of[b['module_of'][name]]
            d.text((10, y + 3), name, fill=K.TEXT, font=f)
            x1 = left + max(1, t / b['total'] * scale)
            d.rectangle((left, y, x1, y + bar_h), fill=colour)
            d.text((x1 + 6, y + 3), pct(t, b['total']), fill=K.TEXT, font=f)
            y += bar_h + gap
        y += 4
    y += 6
    x = 10
    d.text((x, y), 'module:' if args.by == 'routine' else 'part:', fill=K.DIM, font=f)
    x += 60
    for label in colours_used:
        w = 26 + int(d.textlength(label, font=f)) + 12
        if x + w > W:
            x, y = 70, y + 18
        d.rectangle((x, y + 2, x + 14, y + 12), fill=colour_of[label])
        d.text((x + 20, y), label, fill=K.TEXT, font=f)
        x += w
    y += 22
    for b in panels:
        head = f'{b["label"]}: ' if len(panels) > 1 else ''
        run = b['busy'] + b['halt']
        text = f'{head}all instructions together: {run:,} T = {pct(run, b["total"])} of the frames'
        if b['halt']:
            text += f'; HALT {pct(b["halt"], b["total"])}, the rest {pct(b["busy"], b["total"])}'
        for line in wrap(text, f, W - 20, probe):
            d.text((10, y), line, fill=K.DIM, font=f)
            y += 16
        parts = sorted(b['part_t'].items(), key=lambda kv: -kv[1])
        if len(parts) > 1:
            for line in wrap(head + 'by part: ' + ', '.join(f'{k} {pct(v, b["total"])}' for k, v in parts), f,
                             W - 20, probe):
                d.text((10, y), line, fill=K.DIM, font=f)
                y += 16
    for note in notes:
        d.text((10, y), note, fill=K.DIM, font=f)
        y += 16
    im = im.crop((0, 0, W, y + 8))
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    im.save(args.out)
    print(args.out, im.size)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0],
                                formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    p.add_argument('l1')
    p.add_argument('out')
    p.add_argument('--ann', action='append', help='PATH[,page=N[/N..]][,range=LO-HI][,delta=D][,label=L] (repeatable)')
    p.add_argument('--title', default='where the CPU time goes, per routine')
    p.add_argument('--top', type=int, default=24)
    p.add_argument('--by', choices=('routine', 'module'), default='routine')
    p.add_argument('--frame', type=int, help='T-states a frame (default: from the L1)')
    p.add_argument('--label', default='all', help="the first panel's name when there are --state panels")
    p.add_argument('--state', action='append', default=[], help='LABEL=L1: one more panel (repeatable)')
    p.add_argument('--page-name', action='append', default=[], help='N=TEXT: the bar of page N\'s code in no .ann')
    p.add_argument('--colour-order', type=lambda v: v.split(','), default=[],
                   help='MODULE,MODULE,...: these modules take the first colours (the same colours in every figure)')
    p.add_argument('--note', action='append', default=[],
                   help='a line under the figure (repeatable; a long one wraps at the picture\'s width)')
    p.add_argument('--width', type=int, default=1050, help='the picture\'s width in pixels (1050, the figure limit)')
    args = p.parse_args()
    specs = args.ann or ['src/game/game.ann']
    parts = [Part(s, i == 0) for i, s in enumerate(specs)]
    page_names = {int(k): v for k, _, v in (n.partition('=') for n in args.page_name)}
    parts.sort(key=lambda q: not q.filtered)  # filtered parts first, the order given kept otherwise
    panels = [dict(budget(args.l1, parts, args.frame, page_names), label=args.label)]
    for state in args.state:
        label, _, path = state.partition('=')
        panels.append(dict(budget(path, parts, args.frame, page_names), label=label))
    if args.by == 'module':
        panels = [by_module(b) for b in panels]
    draw(panels, args)
    for b in panels:
        print(f'== {b["label"]}: {b["path"]}, {b["frames"]} frames x {b["frame"]} = {b["total"]:,} T; '
              f'instructions {pct(b["busy"] + b["halt"], b["total"])}, HALT {pct(b["halt"], b["total"])}')
        rows = sorted(b['per'].items(), key=lambda kv: -kv[1])
        print(f'  the top {args.top} cover {100 * sum(t for _, t in rows[:args.top]) / b["total"]:.1f}%')
        for name, t in rows[:args.top]:
            print(f'  {name:28s} {b["module_of"][name]:24s} {100 * t / b["total"]:6.2f}%')
        print('  parts: ' + ', '.join(f'{k} {100 * v / b["total"]:.2f}%' for k, v in
                                       sorted(b['part_t'].items(), key=lambda kv: -kv[1])))


if __name__ == '__main__':
    main()
