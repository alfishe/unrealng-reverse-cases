"""Shared pieces of the kit: the access trace reader, the sjasmplus listing, the Spectrum screen, fonts, colours.

The access trace reader lives in unreal-ng (tools/verification/analysis/access_trace.py); access_trace() finds it
through --unreal, $UNREAL_NG, the unreal-ng submodule of this repository, or a checkout next to it.
"""
import importlib.util
import os
import re
import sys
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


# Input scripts (mm_session.py's, zx-reaper's tests/inputs format): "FRAME KEYS..." holds the keys until the next
# line, "FRAME -" releases all, "FRAME END" ends, "+N" counts from the previous line. Keys held together are
# separated by spaces ("100 W O"); "W+O" is the same chord (zx-reaper's form), which mm_session.py does not take:
# kit/rs.py capture (capture_inputs) hands it a copy with the chords split
INPUT_KEYS = {chr(c) for c in range(ord('A'), ord('Z') + 1)} | set('0123456789') | \
    {'ENTER', 'SPACE', 'CS', 'SS', 'KF', 'KL', 'KR', 'KU', 'KD'}


def input_script(path, allow=()):
    """(lines, problems) of an input script: lines [(frame, keys or None at END, the line's text)], keys a list with
    the "+" chords split; problems ["path:N: ..."] for every word that is no key. allow: the first words of a case
    wrapper's own lines (Rex's tools/capture.py: TAPE, POKE), skipped"""
    lines, problems, frame = [], [], 0
    allow = {w.upper() for w in allow}
    for number, raw in enumerate(open(path), 1):
        text = raw.split('#', 1)[0].strip()
        if not text:
            continue
        stamp, *words = text.split()
        if not re.match(r'^\+?\d+$', stamp):
            problems.append(f'{path}:{number}: "{stamp}" is no frame (FRAME or +N first, then the keys)')
            continue
        frame = frame + int(stamp[1:]) if stamp.startswith('+') else int(stamp)
        if words == ['END']:
            lines.append((frame, None, text))
            break
        if words and words[0].upper() in allow:
            continue
        if words and words[0].upper() in ('TYPE', 'POKE', 'TAPE'):
            problems.append(f'{path}:{number}: {words[0]} lines are zx-reaper\'s (tools/zxrun.py): mm_session.py '
                            f'plays keys only')
            continue
        keys = []
        for word in ([] if words == ['-'] else words):
            parts = word.split('+')
            bad = [k for k in parts if k.upper() not in INPUT_KEYS]
            if bad:
                problems.append(f'{path}:{number}: "{word}" is no key: the keys are A-Z 0-9 ENTER SPACE CS SS and '
                                f'the Kempston KF KL KR KU KD, keys held together separated by spaces ("W O") or joined '
                                f'by "+" ("W+O"); "-" alone releases all')
                continue
            keys += [k.upper() for k in parts]
        lines.append((frame, keys, text))
    return lines, problems


def missing_end(path, lines):
    """a warning for an input script with no "FRAME END" line (it ends at its last event, frame N, silently: the
    recording stops there, or the next script starts there), else None"""
    if any(keys is None for _, keys, _ in lines):
        return None
    last = lines[-1][0] if lines else 0
    return (f'WARNING: {path}: no "FRAME END" line: the script ends at its last event, frame {last} (add '
            f'"N END" for a recording that goes on after it)')


def capture_inputs(args):
    """re_session.py capture's arguments with its --inputs scripts checked (input_script): a word that is no key
    stops here with the line and the reason (SystemExit), not in the emulator's "Unknown key"; a script with "+"
    chords ("W+O") is replaced by a copy with the chords split, in W/inputs/; a script with no END line is warned
    about (missing_end). Other commands go through unchanged.
    kit/rs.py calls it; so does a case's own capture wrapper that imports re_session (it never sees rs.py)"""
    if not args or args[0] != 'capture' or '--inputs' not in args:
        return list(args)
    work = args[args.index('--work') + 1] if '--work' in args[:-1] else '.'
    out, k = list(args), args.index('--inputs') + 1
    problems = []
    while k < len(out) and not out[k].startswith('--'):
        path = out[k]
        lines, bad = input_script(path)
        problems += bad
        warning = missing_end(path, lines)
        if warning and not bad:
            print(warning)
        if not bad and any(len(w.split('+')) > 1 for _, _, text in lines for w in text.split()[1:]):
            os.makedirs(os.path.join(work, 'inputs'), exist_ok=True)
            out[k] = os.path.join(work, 'inputs', os.path.basename(path))
            plain_input_script(path, out[k])
            print(f'{path}: its "+" chords split into {out[k]}')
        k += 1
    if problems:
        raise SystemExit('\n'.join(problems))
    return out


def plain_input_script(path, out):
    """write the input script with its "+" chords split into keys separated by spaces (the form mm_session.py
    plays) to out; returns the problems (input_script), nothing written when there are any"""
    lines, problems = input_script(path)
    if problems:
        return problems
    with open(out, 'w') as f:
        f.write(f'# {os.path.basename(path)} with its chords split (kit/rs.py)\n')
        for frame, keys, _ in lines:
            f.write(f'{frame} END\n' if keys is None else f'{frame} {" ".join(keys) if keys else "-"}\n')
    return []


def access_trace(hint=None):
    """The access_trace module of unreal-ng"""
    path = os.path.join(unreal_root(hint), 'tools/verification/analysis/access_trace.py')
    spec = importlib.util.spec_from_file_location('access_trace', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def emulator_ids(s):
    """the ids of the instances an MCP session (unreal-ng's mcplib.Session) lists"""
    listing = s.call('emulator_manage', {'action': 'list'}, ok=False)
    return [e.get('id') for e in (listing.structured or {}).get('emulators', [])]


def mute(s):
    """the instance's mixer master muted (every instance a kit tool starts makes no sound)"""
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)


def slots_set(s, port_base, slot, options=None, timeout=20.0, hint=None, **params):
    """emulator_manage slots_set (a card's options: Bumpy's Kempston card `decode=a5`) on the session's instance,
    and the instance made usable again. unreal-ng restarts the emulator under a new id to apply it, so what a probe
    held is gone: this waits until the list shows the new instance (an id other than the old one; the same id is
    taken after `timeout` seconds), pauses it, takes control of it, mutes it and returns (the tool's answer, a
    corpus.Machine on the new id: its WebAPI url for memory reads). `s` is unreal-ng's mcplib.Session, `port_base`
    the instance's WebAPI port; `params` go to the tool too (`card=...`).

        answer, m = kitlib.slots_set(lab.s, lab.port_base, 'edge.1', 'decode=a5'); lab.m, lab.url = m, m.url
    """
    import sys
    import time
    analysis = os.path.join(unreal_root(hint), 'tools', 'verification', 'analysis')
    if analysis not in sys.path:
        sys.path.insert(0, analysis)
    import corpus
    before = emulator_ids(s)
    args = dict(params, action='slots_set', slot=slot)
    if options is not None:
        args['options'] = options
    answer = s.call('emulator_manage', args, ok=False)
    end = time.monotonic() + timeout
    while True:
        try:
            ids = emulator_ids(s)
        except OSError:  # the endpoint is busy with the restart
            ids = []
        if ids and (ids != before or time.monotonic() >= end):
            break
        if time.monotonic() >= end:
            raise SystemExit(f'slots_set {slot}: no instance listed {timeout:.0f} s after the restart')
        time.sleep(0.1)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    mute(s)
    return answer, corpus.Machine(s, port_base)


def _api(s, method, path, body=None):
    """invoke_api on the session's instance: (the answer's JSON body or {}, the answer's last text line)"""
    params = {'method': method, 'path': '/api/v1/emulator/{id}' + path}
    if body is not None:
        params['body'] = body
    r = s.call('invoke_api', params, ok=False)
    text = (r.text or '').strip().splitlines()
    return ((r.structured or {}).get('body') or {}), (text[-1] if text else '')


def tape_blocks(s):
    """the tape's block count as GET /tape reports it (0: no tape, or not parsed yet)"""
    body, _ = _api(s, 'GET', '/tape')
    return int(body.get('block_count') or 0) if body.get('status') == 'loaded' else 0


def tape_wait(s, block=0, settle=None, frames=10, tries=5):
    """Waits until the inserted tape reports block @p block (GET /tape block_count > block), so a seek may follow
    (R-Type stage 1: a seek straight after the insert answered "Block 35 out of range";
    docs/unreal-ng-run-frames-faults.md). First polled with no frame run (@p tries times, 50 ms apart); then one
    frame is run and the count read again, up to @p frames frames. @p settle runs exactly that many frames first,
    whatever the count says (a case's timeline that ran a fixed number: R-Type's 2), and polls after it the same
    way. Returns the frames run; fails naming the count when the block never shows"""
    import time
    run = 0
    if settle:
        s.call('control_execution', {'action': 'run_frames', 'frames': settle})
        run = settle
    for _ in range(tries):
        if tape_blocks(s) > block:
            return run
        time.sleep(0.05)
    while run < (settle or 0) + frames:
        s.call('control_execution', {'action': 'run_frames', 'frames': 1})
        run += 1
        if tape_blocks(s) > block:
            return run
    raise SystemExit(f'tape_wait: block {block} not reported after {run} frames (block_count {tape_blocks(s)})')


def tape_insert(s, path, block=None, play=False, settle=None, signal=True):
    """Inserts the tape @p path into the running machine (POST /tape/load, no reset) and, with @p block, winds it
    there (POST /tape/seek) once the tape reports that block (tape_wait: no case needs its own frame run between the
    two). @p signal turns the fast and turbo tape off first (a game past ROM LD-BYTES' start, where the trap does not
    belong); @p play starts it, else it is left as the insert left it. @p settle as tape_wait's. Returns {"frames":
    the frames run while waiting, "seek": the seek's answer, "state": GET /tape's state, "at": its position's block}.

        kitlib.tape_insert(lab.s, 'work/stage1/media/rtype.tzx', block=35)
    """
    if signal:
        for name in ('fast_tape', 'turbo_tape'):
            _api(s, 'PUT', f'/settings/{name}', {'value': False})
    body, text = _api(s, 'POST', '/tape/load', {'path': os.path.abspath(path)})
    if body.get('status') != 'success':
        raise SystemExit(f'tape_insert {path}: {body.get("message") or text}')
    out = {'frames': 0, 'seek': None}
    if block is not None:
        out['frames'] = tape_wait(s, block, settle)
        body, text = _api(s, 'POST', '/tape/seek', {'block': block})
        out['seek'] = body.get('message') or text
        if body.get('status') != 'success':
            raise SystemExit(f'tape_insert {path}: seek {block}: {out["seek"]}')
    elif settle:
        out['frames'] = tape_wait(s, 0, settle)
    if play:
        _api(s, 'POST', '/tape/play', {})
    body, _ = _api(s, 'GET', '/tape')
    out['state'] = body.get('state')
    out['at'] = (body.get('position') or {}).get('block')
    return out


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

# line number, address, the bytes column (hex pairs, its width varies with sjasmplus's layout; a long DEFS / DS row
# ends its pairs with "00..."), the source. A one-byte instruction whose text is all hex letters (DEC A: "3D  DEC A")
# keeps its text: a pair must end at a space or the line's end
LINE = re.compile(r'^\s*\d+\+*\s+([0-9A-F]{4}) ((?:[0-9A-F]{2}(?: |$))*(?:[0-9A-F]{2}\.\.\.)?)\s*(.*)$')
LABEL = re.compile(r'^([A-Za-z_][\w.]*):')
# an address name of the top file: 'Name  EQU $XXXX' (mkgame.py's @equ, @const lines); an @bank line ('; bank N')
# names another bank's address and is left out
EQU = re.compile(r'^([A-Za-z_]\w*)\s+EQU\s+\$([0-9A-Fa-f]{4})\b\s*(;.*)?$')


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


def tool_command(argv=None):
    """the command that runs this tool as a case's caption gives it: python3 ../../kit/TOOL.py and its arguments
    (shell-quoted)"""
    import shlex
    argv = list(sys.argv if argv is None else argv)
    return 'python3 ../../kit/%s %s' % (os.path.basename(argv[0]), shlex.join(argv[1:]))


def gif_command(path):
    """the command save_gif recorded in a GIF (its comment extension), or None (a GIF drawn before 2026-11-16)"""
    try:
        with Image.open(path) as im:
            comment = im.info.get('comment')
    except OSError:
        return None
    if isinstance(comment, bytes):
        comment = comment.decode('utf-8', 'replace')
    return comment[len('command: '):] if comment and comment.startswith('command: ') else None


def save_gif(path, pictures, durations, command=True):
    """An animated GIF of RGB pictures, small: one palette for all (255 colours, no dithering) and, from the second
    picture on, every pixel that did not change since the previous picture written as the transparent index 255, so
    each picture costs only what changed (a routine animation of 90 pictures is about 1 MB, not 10).

    No pixel is ever quantized to 255: the palette's unused entries and entry 255 repeat entry 0, and a pixel that
    lands on 255 all the same is moved to 0 (the same colour). Index 255 used to be black, so a pure black pixel the
    255 colours did not hold exactly (the Spectrum's black ink beside the kit's dark background) went to 255 and
    showed the page through in the first picture and in every later one.

    command: the GIF's comment extension holds "command: " and the tool's command line (tool_command: every option,
    --title in full), so a caption that cuts the command short can be completed from the file
    (`kit/routine_anim.py --command GIF`, check_docs); a string gives the command, False writes none"""
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
    extra = {}
    if command:
        extra['comment'] = ('command: ' + (tool_command() if command is True else command)).encode('utf-8')
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=durations, loop=0, optimize=False,
                   disposal=1, transparency=255, **extra)


class Listing:
    """The code lines and labels of a sjasmplus listing (sjasmplus --lst), or of several merged by address: one flat
    image built from several sources (a menu and the music at $C000), each listing for the addresses it holds

    lines: (address, kind, text) in listing order (several listings one after the other), kind 'label' or 'code';
    an address two listings both give code at is the first's
    """

    def __init__(self, path, names=None, auto=None):
        self.lines = []
        self.code_line = {}  # address -> index into lines of the instruction there
        self.labels = []     # (address, name), sorted, global labels only (no '.')
        self.equates = {}    # address -> name: the EQU names of addresses (the .ann's @equ, @const)
        for one in ([path] if isinstance(path, str) else path):
            self._read(one)
        self.labels.sort()
        if auto == 'owner' or names:
            self._rename(names or {}, auto == 'owner')
        self._label_addresses = [a for a, _ in self.labels]
        names = dict(self.equates)
        names.update({a: n for a, n in self.labels})  # a label wins over an EQU of its address
        self._data = sorted(names.items())
        self._data_addresses = [a for a, _ in self._data]

    def _read(self, path):
        for raw in open(path, encoding='utf-8', errors='replace'):
            m = LINE.match(raw.rstrip('\n'))
            if not m:
                continue
            address, data, source = int(m.group(1), 16), m.group(2).strip(), m.group(3).strip()
            equ = EQU.match(source)
            if equ and not (equ.group(3) or '').startswith('; bank '):
                self.equates.setdefault(int(equ.group(2), 16), equ.group(1))
                continue
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

    def _rename(self, names, owner):
        """--auto-labels owner: SkoolKit's generated label l_XXXX becomes OWNER_XXXX, OWNER the nearest named label
        before it (ScrollRows' loops l_8846, l_8881, l_88B3 are ScrollRows_8846, ...); --label ADDR=NAME then names
        the code at ADDR NAME (the label there renamed, or one added). The listing's own lines show the same names"""
        new, last = {}, None
        for address, name in self.labels:
            if owner and AUTO_LABEL.match(name):
                if last:
                    new[(address, name)] = f'{last}_{name[2:]}'
            else:
                last = name
        renamed = {}
        for (address, name), to in new.items():
            renamed[name] = to
        self.labels = [(a, new.get((a, n), n)) for a, n in self.labels]
        at = {a for a, _ in self.labels}
        for address, name in names.items():
            if address in at:
                old = [n for a, n in self.labels if a == address]
                for n in old:
                    renamed[n] = name
                self.labels = [(a, name if a == address else n) for a, n in self.labels]
            else:
                self.labels.append((address, name))
                at.add(address)
        self.labels.sort()
        self.lines = [(a, k, renamed.get(t, t) if k == 'label' else t) for a, k, t in self.lines]

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

    def data_name(self, address):
        """label or label+offset for data: the nearest label or EQU name (an @equ past the image: DrawMarks+21, not
        the last label of the image + 789) at or before address"""
        i = bisect_right(self._data_addresses, address) - 1
        if i < 0:
            return f'${address:04X}'
        base, name = self._data[i]
        return name if base == address else f'{name}+{address - base}'

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

    name = data_name = routine

    def window(self, address, rows):
        return []


AUTO_LABEL = re.compile(r'^l_[0-9A-F]{4}$')  # SkoolKit's label for a branch target the .ann does not name


def label_names(values):
    """--label values (ADDR=NAME, comma-separated or repeated; hex, an optional $) to {address: name}"""
    names = {}
    for value in values or []:
        for item in value.replace(' ', ',').split(','):
            if not item:
                continue
            address, eq, name = item.partition('=')
            if not eq or not re.match(r'^[A-Za-z_][\w.]*$', name):
                raise SystemExit(f'--label {item}: ADDR=NAME (hex address, a label name)')
            names[hex_address(address)] = name
    return names


def listing(path, args=None):
    """--listing: a path, or a list of them (--listing repeated: merged by address), or none; with args, the
    --label / --auto-labels of add_listing_arg applied"""
    if not path:
        return NoListing()
    return Listing(path, label_names(getattr(args, 'label', None)), getattr(args, 'auto_labels', None))


def add_listing_arg(parser):
    parser.add_argument('--listing', action='append', metavar='LISTING',
                        help='the sjasmplus listing that names the code; repeated, several listings of one flat '
                             'image merged by address (build/main.lst and build/music.lst)')
    parser.add_argument('--label', action='append', metavar='ADDR=NAME',
                        help='the code at ADDR is NAME (the listing\'s label there renamed, or one added): a loop '
                             'the .ann leaves to SkoolKit\'s l_XXXX; comma-separated or repeated (hex, an optional $)')
    parser.add_argument('--auto-labels', choices=('keep', 'owner'), default='keep',
                        help='owner: each l_XXXX label (SkoolKit\'s, for a branch target the .ann does not name) is '
                             'OWNER_XXXX, OWNER the nearest named label before it (ScrollRows_8846); keep: as listed')


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
    return PagedListing(listing(args.listing, args), pages, names)


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
# memory images: a snapshot's or a dump's 64 K

def memory_image(path):
    """The 64 K the Z80 sees in a saved state: an SZX snapshot (RAM 5 at $4000, 2 at $8000, and at $C000 RAM 0 or,
    on a 128K, the page the last OUT to $7FFD chose; the ROM area left zero), or a dump of 65536 bytes (the whole
    memory) or 49152 (from $4000)"""
    import struct
    import zlib
    data = open(path, 'rb').read()
    mem = bytearray(0x10000)
    if data[:4] != b'ZXST':
        if len(data) == 0x10000:
            mem[:] = data
        elif len(data) == 0xC000:
            mem[0x4000:] = data
        else:
            raise SystemExit(f'{path}: neither an SZX snapshot nor a 64 K / 48 K memory dump ({len(data)} bytes)')
        return mem
    pages, top = {}, 0
    pos = 8
    while pos + 8 <= len(data):
        bid, size = data[pos:pos + 4], struct.unpack_from('<I', data, pos + 4)[0]
        body = data[pos + 8:pos + 8 + size]
        if bid == b'RAMP':
            flags, page = struct.unpack_from('<HB', body, 0)
            pages[page] = zlib.decompress(body[3:]) if flags & 1 else body[3:]
        elif bid == b'SPCR':
            top = body[1] & 7  # ch7ffd
        pos += 8 + size
    for page, base in ((5, 0x4000), (2, 0x8000), (top, 0xC000)):
        if page in pages:
            mem[base:base + 0x4000] = pages[page][:0x4000]
    return mem


# SZX chMachineId -> unreal-ng model (POST /emulator create, re_session.py --model)
SZX_MODELS = {0: '48K', 1: '48K', 2: '128K', 3: 'PLUS2', 4: 'PLUS2A', 5: 'PLUS3', 6: 'PLUS3', 7: 'PENTAGON',
              10: 'SCORPION', 15: '48K', 16: '128K'}
# .z80 version 3 hardware byte (34) -> model; version 2 differs at 3 and 4 (128K), see snapshot_model
Z80_V3_MODELS = {0: '48K', 1: '48K', 3: '48K', 4: '128K', 5: '128K', 6: '128K', 7: 'PLUS3', 8: 'PLUS3',
                 9: 'PENTAGON', 10: 'SCORPION', 12: 'PLUS2', 13: 'PLUS2A'}


def snapshot_model(path):
    """The unreal-ng model a snapshot was saved on, or None when the file does not say (an unknown machine id): an
    SZX's machine id, a .z80's version and hardware byte (version 1: 48K; byte 37 bit 7 turns 128K into +2 and +3
    into +2A), a .sna by its length (49179: 48K, 131103 / 147487: 128K)"""
    data = open(path, 'rb').read(64)
    size = os.path.getsize(path)
    if data[:4] == b'ZXST':
        return SZX_MODELS.get(data[6]) if len(data) > 6 else None
    if path.lower().endswith('.z80') and len(data) >= 35:
        if data[6] | data[7]:
            return '48K'  # version 1: PC in the header
        extra = data[30] | data[31] << 8
        hw, modified = data[34], len(data) > 37 and data[37] & 0x80
        model = ('48K' if hw < 3 else '128K') if extra == 23 else Z80_V3_MODELS.get(hw)
        if modified and model == '128K':
            return 'PLUS2'
        if modified and model == 'PLUS3':
            return 'PLUS2A'
        return model
    if path.lower().endswith('.sna'):
        return {49179: '48K', 131103: '128K', 147487: '128K'}.get(size)
    return None


def model_from_snapshot(args, who='capture'):
    """capture arguments with --model added from --snapshot's own model when no --model is given (re_session.py's
    default is 48K: a 128K state does not load there); a --model that differs from the snapshot's is kept, with a
    warning. args: the capture's argument list (the 'capture' word may be first)"""
    def value(name):
        for k, a in enumerate(args):
            if a == name and k + 1 < len(args):
                return args[k + 1]
            if a.startswith(name + '='):
                return a.split('=', 1)[1]
        return None
    snapshot, given = value('--snapshot'), value('--model')
    if not snapshot or not os.path.isfile(snapshot):
        return args
    model = snapshot_model(snapshot)
    if model is None:
        print(f'{who}: {snapshot}: the model is not known from the file; --model {given or "48K (the default)"}',
              flush=True)
        return args
    if given is None:
        print(f'{who}: --model {model} from {snapshot}', flush=True)
        return list(args) + ['--model', model]
    if given.upper() != model.upper():
        print(f'{who}: WARNING: --model {given}, but {snapshot} was saved on {model}', flush=True)
    return args


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


# ---------------------------------------------------------------------------------------------------------------
# a menu read from the screen's attributes (a highlighted line is a row of another paper)


def paper_rows(attributes, paper, lo=0, hi=24, cells=3, ink=None):
    """The character rows lo..hi-1 with at least @p cells cells of paper @p paper (0-7; and of ink @p ink when
    given) in @p attributes: the 768 bytes at $5800, or a callable read(address, count) -> bytes (a lab's memory
    read). A menu's highlighted line is the row of the highlight's paper (Enduro Racer: blue paper on the main menu,
    red in its popups). Key counts miss when a game ignores the first presses (an attract mode, a debounce); the
    attributes say where the highlight is"""
    a = attributes(0x5800, 768) if callable(attributes) else attributes
    return [y for y in range(lo, hi)
            if sum(1 for x in range(32) if (a[32 * y + x] >> 3) & 7 == paper and
                   (ink is None or a[32 * y + x] & 7 == ink)) >= cells]


def wait_paper(read, step, row, paper, tries=40, cells=3, ink=None, only=False):
    """Calls @p step() (a key press and the frames after it, or a run of frames) until character row @p row has
    paper @p paper (paper_rows over read(address, count)); @p only: and no other row has it. Returns the steps taken
    (0: the row had it already); fails naming the rows that had the paper after @p tries steps.

        kitlib.wait_paper(r.rd, lambda: r.tap('ENTER', 4, 25), 12, 1)      # the menu's line on row 12 highlighted
    """
    rows = []
    for k in range(tries + 1):
        rows = paper_rows(read, paper, cells=cells, ink=ink)
        if row in rows and (not only or rows == [row]):
            return k
        if k < tries:
            step()
    raise RuntimeError(f'wait_paper: row {row} has no paper {paper} after {tries} steps (rows with it: {rows})')


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
