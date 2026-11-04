"""Shared pieces of the kit: the access trace reader, the sjasmplus listing, the Spectrum screen, fonts, colours.

The access trace reader lives in unreal-ng (tools/verification/analysis/access_trace.py); access_trace() finds it
through --unreal, $UNREAL_NG, or an unreal-ng checkout next to this repository.
"""
import importlib.util
import os
import re
from bisect import bisect_right

from PIL import Image, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------------------------------------------------------
# unreal-ng


def unreal_root(hint=None):
    for candidate in (hint, os.environ.get('UNREAL_NG'), os.path.join(HERE, '..', '..', '..', 'Test', 'unreal-ng'),
                      os.path.join(HERE, '..', '..', 'unreal-ng')):
        if candidate and os.path.isfile(os.path.join(candidate, 'tools/verification/analysis/access_trace.py')):
            return os.path.abspath(candidate)
    raise SystemExit('unreal-ng checkout not found: pass --unreal or set UNREAL_NG')


def access_trace(hint=None):
    """The access_trace module of unreal-ng"""
    path = os.path.join(unreal_root(hint), 'tools/verification/analysis/access_trace.py')
    spec = importlib.util.spec_from_file_location('access_trace', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def instruction_times(trace):
    """Each instruction's CPU T-state counted from the trace's start"""
    units = max(1, trace.units_per_t)
    base = trace.from_frame * trace.frame_t
    start = trace.instructions[0] if trace.instructions else None
    origin = start.frame * trace.frame_t + start.t // units - base if start else 0
    return [x.frame * trace.frame_t + x.t // units - base - origin for x in trace.instructions]


def parse_moment(text, frame_t):
    """F[:T] to (frame, t)"""
    frame, _, t = str(text).partition(':')
    return int(frame), int(t or 0)


# ---------------------------------------------------------------------------------------------------------------
# sjasmplus listing

# line number, address, the bytes column (hex pairs, its width varies with sjasmplus's layout), the source
LINE = re.compile(r'^\s*\d+\+*\s+([0-9A-F]{4}) ((?:[0-9A-F]{2}(?: |$))*)\s*(.*)$')
LABEL = re.compile(r'^([A-Za-z_][\w.]*):')


def buffer_cells(base, width, height, order='rows'):
    """(row, column, address) of each byte of an off-screen bitmap of width bytes by height lines.

    order 'rows': row by row, a row of width bytes (a linear bitmap). 'columns': column by column, a column of height
    bytes from the top (a strip buffer). 'columns-up': the same, each column from the bottom line up.
    """
    for row in range(height):
        for column in range(width):
            if order == 'rows':
                offset = row * width + column
            elif order == 'columns':
                offset = column * height + row
            elif order == 'columns-up':
                offset = column * height + (height - 1 - row)
            else:
                raise SystemExit(f'buffer order {order}: rows, columns or columns-up')
            yield row, column, (base + offset) & 0xFFFF


def save_gif(path, pictures, durations):
    """An animated GIF of RGB pictures, small: one palette for all (255 colours, no dithering) and, from the second
    picture on, every pixel that did not change since the previous picture written as the transparent index 255, so
    each picture costs only what changed (a routine animation of 90 pictures is about 1 MB, not 10)"""
    import numpy
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    picks = [pictures[i * (len(pictures) - 1) // 7] for i in range(8)] if len(pictures) > 8 else pictures
    width, height = pictures[0].size
    sample = Image.new('RGB', (width, height * len(picks)))
    for i, picture in enumerate(picks):
        sample.paste(picture, (0, i * height))
    palette = sample.quantize(colors=255, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    entries = palette.getpalette()[:255 * 3]
    palette.putpalette(entries + [0, 0, 0])
    frames, previous = [], None
    for picture in pictures:
        index = numpy.asarray(picture.quantize(palette=palette, dither=Image.Dither.NONE))
        out = index.copy()
        if previous is not None:
            out[index == previous] = 255
        previous = index
        frame = Image.fromarray(out, 'P')
        frame.putpalette(entries + [0, 0, 0])
        frames.append(frame)
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=False,
                   disposal=1, transparency=255)


class Listing:
    """The code lines and labels of a sjasmplus listing (sjasmplus --lst)

    lines: (address, kind, text) in listing order, kind 'label' or 'code'
    """

    def __init__(self, path):
        self.lines = []
        self.code_line = {}  # address -> index into lines of the instruction there
        self.labels = []     # (address, name), sorted, global labels only (no '.')
        for raw in open(path, encoding='utf-8', errors='replace'):
            m = LINE.match(raw.rstrip('\n'))
            if not m:
                continue
            address, data, source = int(m.group(1), 16), m.group(2).strip(), m.group(3).strip()
            label = LABEL.match(source)
            if label:
                self.lines.append((address, 'label', label.group(1)))
                if '.' not in label.group(1):
                    self.labels.append((address, label.group(1)))
                source = source[label.end():].strip()
            if data and source and not source.startswith(';'):
                upper = source.split(';')[0].strip().upper()
                if upper.startswith(('DB', 'DEFB', 'DW', 'DEFW', 'DS', 'DEFS', 'INCBIN', 'BLOCK')):
                    continue
                if address not in self.code_line:
                    self.code_line[address] = len(self.lines)
                self.lines.append((address, 'code', source))
        self.labels.sort()
        self._label_addresses = [a for a, _ in self.labels]

    def routine(self, address):
        """The global label at or before address"""
        i = bisect_right(self._label_addresses, address) - 1
        return self.labels[i][1] if i >= 0 else f'${address:04X}'

    def name(self, address):
        """label or label+offset"""
        i = bisect_right(self._label_addresses, address) - 1
        if i < 0:
            return f'${address:04X}'
        base, label = self.labels[i]
        return label if base == address else f'{label}+{address - base}'

    def window(self, address, rows):
        """rows listing lines round the instruction at address: [(address, kind, text, is_current)]"""
        at = self.code_line.get(address)
        if at is None:
            return []
        lo = max(0, at - rows // 3)
        hi = min(len(self.lines), lo + rows)
        lo = max(0, hi - rows)
        return [(a, k, t, i == at) for i, (a, k, t) in enumerate(self.lines[lo:hi], lo)]


class NoListing:
    lines = []
    code_line = {}

    def routine(self, address):
        return f'${address:04X}'

    name = routine

    def window(self, address, rows):
        return []


def listing(path):
    return Listing(path) if path else NoListing()


# ---------------------------------------------------------------------------------------------------------------
# the Spectrum screen

BASIC, BRIGHT = 0xCD, 0xFF


def ink_colour(index, bright):
    level = BRIGHT if bright else BASIC
    return (level if index & 2 else 0, level if index & 4 else 0, level if index & 1 else 0)


def screen_line(address):
    """The pixel line of bitmap byte $4000-$57FF"""
    return ((address >> 8) & 7) | ((address >> 2) & 0x38) | ((address >> 5) & 0xC0)


def screen_address(line, column):
    return 0x4000 | ((line & 0xC0) << 5) | ((line & 0x07) << 8) | ((line & 0x38) << 2) | column


def render_screen(memory, base=0x4000):
    """The screen at base as a 256 x 192 RGB image"""
    image = Image.new('RGB', (256, 192))
    px = image.load()
    for y in range(192):
        row = base + (screen_address(y, 0) - 0x4000)
        for column in range(32):
            bits = memory[row + column]
            attr = memory[base + 0x1800 + (y >> 3) * 32 + column]
            ink, paper = ink_colour(attr & 7, attr & 0x40), ink_colour((attr >> 3) & 7, attr & 0x40)
            for bit in range(8):
                px[column * 8 + bit, y] = ink if bits & (0x80 >> bit) else paper
    return image


# ---------------------------------------------------------------------------------------------------------------
# drawing

FONT_FILES = ['/System/Library/Fonts/Menlo.ttc', '/System/Library/Fonts/SFNSMono.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 'C:/Windows/Fonts/consola.ttf']


def font(size=12):
    for path in FONT_FILES:
        if os.path.isfile(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


# One palette for every figure of the kit (GUIDE.md 4.3)
BACKGROUND = (14, 14, 20)
PANEL = (24, 24, 32)
TEXT = (210, 210, 220)
DIM = (120, 120, 135)
EXEC = (80, 230, 110)
READ = (80, 160, 255)
WRITE_FADE = [(255, 255, 140), (255, 210, 70), (245, 140, 45), (210, 80, 40), (160, 50, 50), (115, 40, 60)]
WRITE_TRAIL = (80, 34, 52)
READ_TRAIL = (28, 46, 80)
EXEC_TRAIL = (26, 64, 36)

# Routine colours: distinct, readable on the dark background
ROUTINE_COLOURS = [(230, 90, 80), (90, 200, 120), (90, 150, 250), (240, 200, 70), (200, 110, 230), (70, 210, 220),
                   (250, 150, 60), (160, 220, 80), (240, 120, 180), (140, 140, 250), (200, 170, 120),
                   (120, 230, 190)]


def hex_address(text):
    text = str(text).strip().lstrip('$').replace('0x', '').replace('#', '')
    return int(text, 16)


def hex_range(text):
    lo, _, hi = text.partition('-')
    return hex_address(lo), hex_address(hi or lo)


# ---------------------------------------------------------------------------------------------------------------
# the trace: a file, or taken from the session that holds the recording


def add_trace_args(parser):
    parser.add_argument('--trace', help='an access trace file (analysis trace)')
    parser.add_argument('--work', help='a re_session work folder whose instance holds the recording')
    parser.add_argument('--window', help='with --work: F:T-F:T, the window to trace (kept in W/traces/)')
    parser.add_argument('--max-cycles', type=int, help='with --work: the trace\'s cap (default the emulator\'s)')
    parser.add_argument('--unreal', help='an unreal-ng checkout (else $UNREAL_NG or one next to this repository)')


def load_trace(args):
    """The trace of --trace, or of --work + --window (traced once, then read from W/traces/)"""
    module = access_trace(args.unreal)
    if args.trace:
        return module.load(args.trace)
    if not (args.work and args.window):
        raise SystemExit('give --trace FILE, or --work W --window F:T-F:T')
    start, _, end = args.window.partition('-')
    (f0, t0), (f1, t1) = parse_moment(start, 0), parse_moment(end or f'{int(start.partition(":")[0]) + 1}', 0)
    path = os.path.join(os.path.abspath(args.work), 'traces', f'{f0}_{t0}-{f1}_{t1}.uatr')
    if not os.path.isfile(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        import sys
        sys.path.insert(0, os.path.join(unreal_root(args.unreal), 'tools', 'verification', 'analysis'))
        import re_session  # noqa: E402
        session, _ = re_session.session_of(args.work)
        body = {'action': 'trace', 'path': path, 'from_frame': f0, 'from_tinframe': t0, 'to_frame': f1,
                'to_tinframe': t1}
        if args.max_cycles:
            body['max_cycles'] = args.max_cycles
        r = session.call('analysis', body, ok=False)
        if r.is_error:
            raise SystemExit(f'analysis trace: {r.text}')
        print(r.text)
    return module.load(path)
