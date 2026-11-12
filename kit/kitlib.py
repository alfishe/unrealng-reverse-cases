"""Shared pieces of the kit: the access trace reader, the sjasmplus listing, the Spectrum screen, fonts, colours.

The access trace reader lives in unreal-ng (tools/verification/analysis/access_trace.py); access_trace() finds it
through --unreal, $UNREAL_NG, the unreal-ng submodule of this repository, or a checkout next to it.
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
    """the unreal-ng checkout: --unreal, $UNREAL_NG, the submodule, a checkout near this repository (toolpaths.py)"""
    import sys
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    import toolpaths
    return toolpaths.unreal_ng(hint)


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
    bytes from the top (a strip buffer). 'columns-up': the same, each column from the bottom line up. 'screen': laid
    out like the Spectrum screen's pixel lines (a back buffer of whole thirds, width 32).
    """
    for row in range(height):
        for column in range(width):
            if order == 'rows':
                offset = row * width + column
            elif order == 'columns':
                offset = column * height + row
            elif order == 'columns-up':
                offset = column * height + (height - 1 - row)
            elif order == 'screen':
                offset = (row & 0xC0) << 5 | (row & 7) << 8 | (row & 0x38) << 2 | column
            else:
                raise SystemExit(f'buffer order {order}: rows, columns, columns-up or screen')
            yield row, column, (base + offset) & 0xFFFF


def save_gif(path, pictures, durations):
    """An animated GIF of RGB pictures, small: one palette for all (255 colours, no dithering) and, from the second
    picture on, every pixel that did not change since the previous picture written as the transparent index 255, so
    each picture costs only what changed (a routine animation of 90 pictures is about 1 MB, not 10).

    No pixel is ever quantized to 255: the palette's unused entries and entry 255 repeat entry 0, and a pixel that
    lands on 255 all the same is moved to 0 (the same colour). Index 255 used to be black, so a pure black pixel the
    255 colours did not hold exactly (the Spectrum's black ink beside the kit's dark background) went to 255 and
    showed the page through in the first picture and in every later one"""
    import numpy
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    picks = [pictures[i * (len(pictures) - 1) // 7] for i in range(8)] if len(pictures) > 8 else pictures
    width, height = pictures[0].size
    sample = Image.new('RGB', (width, height * len(picks)))
    for i, picture in enumerate(picks):
        sample.paste(picture, (0, i * height))
    palette = sample.quantize(colors=255, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    entries = palette.getpalette()[:255 * 3]
    entries += entries[:3] * (255 - len(entries) // 3)  # unused entries: copies of entry 0, never nearer than it
    entries += entries[:3]                              # the transparent index 255: entry 0's colour as well
    palette.putpalette(entries)
    frames, previous = [], None
    for picture in pictures:
        index = numpy.asarray(picture.quantize(palette=palette, dither=Image.Dither.NONE)).copy()
        index[index == 255] = 0
        out = index.copy()
        if previous is not None:
            out[index == previous] = 255
        previous = index
        frame = Image.fromarray(out, 'P')
        frame.putpalette(entries)
        frames.append(frame)
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=False,
                   disposal=1, transparency=255)


class Listing:
    """The code lines and labels of a sjasmplus listing (sjasmplus --lst), or of several merged by address: one flat
    image built from several sources (a menu and the music at $C000), each listing for the addresses it holds

    lines: (address, kind, text) in listing order (several listings one after the other), kind 'label' or 'code';
    an address two listings both give code at is the first's
    """

    def __init__(self, path):
        self.lines = []
        self.code_line = {}  # address -> index into lines of the instruction there
        self.labels = []     # (address, name), sorted, global labels only (no '.')
        for one in ([path] if isinstance(path, str) else path):
            self._read(one)
        self.labels.sort()
        self._label_addresses = [a for a, _ in self.labels]

    def _read(self, path):
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
    """--listing: a path, or a list of them (--listing repeated: merged by address), or none"""
    return Listing(path) if path else NoListing()


def add_listing_arg(parser):
    parser.add_argument('--listing', action='append', metavar='LISTING',
                        help='the sjasmplus listing that names the code; repeated, several listings of one flat '
                             'image merged by address (build/main.lst and build/music.lst)')


# ---------------------------------------------------------------------------------------------------------------
# 128K pages: code at $C000-$FFFF told apart by the RAM page it ran in

PAGED = 0x10000  # a code location: the address, plus PAGED x the page for $C000-$FFFF in paged mode


def add_page_args(parser):
    parser.add_argument('--page', action='append', default=[], metavar='N=LISTING',
                        help='code at $C000-$FFFF run while RAM N is paged in is named from LISTING (repeatable)')
    parser.add_argument('--page-name', action='append', default=[], metavar='N=NAME',
                        help='code at $C000-$FFFF run while RAM N is paged in is NAME, one name for the page '
                             '(repeatable); with --page N=LISTING as well, the listing names the code and NAME '
                             'stands for "RAM N" after each name')


def code_listing(args):
    """--listing with the --page / --page-name of add_page_args: a PagedListing (paged mode when any is given)"""
    pages = {int(n): Listing(path) for n, _, path in (v.partition('=') for v in getattr(args, 'page', []))}
    names = {int(n): name for n, _, name in (v.partition('=') for v in getattr(args, 'page_name', []))}
    return PagedListing(listing(args.listing), pages, names)


def code_locations(trace, paged):
    """Each instruction's code location: its PC, or in paged mode, for $C000-$FFFF, PC + PAGED x the RAM page there
    as it ran (the trace's page at its start, then each OUT to the 128K's port $7FFD: A15 = 0, A14 = 1, A1 = 0, from
    the next instruction on). RAM 0 keeps the plain PC"""
    if not paged:
        return [x.pc for x in trace.instructions]
    page = trace.pages[3] & 7 if trace.pages and trace.pages[3] < 0x100 else 0
    out = []
    for x in trace.instructions:
        out.append(x.pc + PAGED * page if x.pc >= 0xC000 else x.pc)
        for c in x.cycles:
            if c.tag == 'O' and c.address & 0xC002 == 0x4000:
                page = c.value & 7
    return out


def code_ranges(texts, paged=False):
    """--pc values (comma-separated, repeated) to [(lo, hi)] of code locations: LO-HI, or N:LO-HI for RAM N at
    $C000-$FFFF. In paged mode a plain range at $C000-$FFFF is RAM 0's. None: every location"""
    if not texts:
        return [(0, 8 * PAGED - 1)]
    out = []
    for text in texts:
        for r in text.split(','):
            r = r.strip()
            if not r:
                continue
            page, _, span = r.rpartition(':')
            lo, hi = hex_range(span)
            base = PAGED * int(page) if page else 0
            out.append((base + lo, base + hi) if not page or lo >= 0xC000 else (lo, hi))
    return out


class PagedListing:
    """A listing for code locations (code_locations): RAM N's code at $C000-$FFFF from --page N's listing (its
    names with " (RAM N)" after them), or --page-name N's one name; both for one page combine: the listing names the
    code (and gives its lines) and the page name stands for "RAM N" ("AyFrame (bank 4: the AY player)"). Everything
    else from the main listing (a page with neither too). Without pages a location is the PC and this is the main
    listing"""

    def __init__(self, main, pages=None, names=None):
        self.main, self.pages, self.names = main, pages or {}, names or {}
        self.paged = bool(self.pages or self.names)

    def _of(self, loc):
        page, address = divmod(loc, PAGED)
        return page, address, (self.pages.get(page, self.main) if page else self.main)

    def _page(self, page):
        return self.names.get(page, f'RAM {page}')

    def routine(self, loc):
        page, address, lst = self._of(loc)
        if page in self.pages:
            return f'{lst.routine(address)} ({self._page(page)})'
        if page in self.names:
            return self.names[page]
        return lst.routine(address)

    def name(self, loc):
        page, address, lst = self._of(loc)
        if page in self.pages:
            return f'{lst.name(address)} ({self._page(page)})'
        if page in self.names:
            return f'{self.names[page]} ${address:04X}'
        return lst.name(address)

    def window(self, loc, rows):
        """as Listing.window, the addresses as code locations (so that counts by location find their line); a page
        with a name only has no lines"""
        page, address, lst = self._of(loc)
        if page in self.names and page not in self.pages:
            return []
        return [(a + PAGED * page if page and a >= 0xC000 else a, k, t, c) for a, k, t, c in lst.window(address, rows)]


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

# Routine colours: distinct, readable on the dark background. 28 of them, so that a figure of up to 28 routines or
# modules (Terramex's budget has 25) repeats none; the first 12 were the whole list once and keep their order
ROUTINE_COLOURS = [(230, 90, 80), (90, 200, 120), (90, 150, 250), (240, 200, 70), (200, 110, 230), (70, 210, 220),
                   (250, 150, 60), (160, 220, 80), (240, 120, 180), (140, 140, 250), (200, 170, 120),
                   (120, 230, 190),
                   (255, 255, 255), (150, 110, 70), (175, 45, 65), (45, 140, 85), (55, 85, 190), (170, 150, 40),
                   (130, 65, 190), (35, 145, 160), (195, 95, 35), (255, 190, 210), (185, 185, 185), (255, 235, 160),
                   (80, 120, 120), (200, 220, 160), (220, 160, 220), (150, 200, 255)]


def parse_colour(text):
    """#RRGGBB, RRGGBB or R,G,B to an (r, g, b) tuple"""
    text = text.strip()
    if ',' in text:
        return tuple(int(v) for v in text.split(','))
    text = text.lstrip('#')
    return tuple(int(text[i:i + 2], 16) for i in (0, 2, 4))


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
