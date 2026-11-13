#!/usr/bin/env python3
"""Doc 06's figures: the screen with the room's open spans beside the memory the renderer uses, and the room change's
phases.

    python3 tools/fig_render.py spans WORK FRAME docs/img/render/spans.png
    python3 tools/fig_render.py phases docs/img/render/roomchange-phases.png

spans: WORK is a re_session work folder whose instance holds the recording (c1); at FRAME the screen `$4000-$5AFF`,
SpanCount `$FE1C` and the span table `$76A0` are read with TTD memory_at. Each span (6 bytes: the length in cells,
0, the play buffer's address, the screen's address) is outlined on the screen; the HUD rows 0-5 and the play area's
28 x 18 cells are marked. Right: the memory map of stage 1's drawing (from src/stage1/stage1.asm and variables.asm).
phases: the c1 room change 8 to 7 (frames 16531:33882-16549:64359), its T-states per phase, measured from the trace
(work/docs/myA/rc-spans.tsv and the routine entries; doc 06 6.3 gives the method).

    python3 tools/fig_render.py sprites docs/img/sprites/stage1-sprites.png
    python3 tools/fig_render.py shift docs/img/render/preshift.png
    python3 tools/fig_render.py colours WORK FRAME docs/img/render/colours.png

sprites: every sprite set and bitmap set of stage 1 that an actor or a missile draws, and stage 5's hero, from the
resources in src/res (the frames as the code holds them, ink white), each labelled with its address, size, frame
sizes and the routine that draws it (src/res/stage1/README.md, src/res/stage5/README.md).
shift: PreShiftSprite `$7F4D` on the warrior's flying head (sprites-warrior.png frame 9, 2 bytes x 6 lines): the copy
at `$7640` one byte wider, shifted right by +`$11` = 0-7 pixels; the byte columns are marked.
colours: at FRAME of the recording WORK holds (c1), the play area's 18 x 28 cells: RoomAttributes `$7042` (the
colours the solid cells get back), the shadow `$6DC2` (the open cells' colours with the actors painted in; gold: each
actor's box by ColourActor's rule, from the records at `$74E0`), and the screen's attributes `$58C2` (open cells, kind
0 at CellsPlay `$7282`, from the shadow; solid cells keep theirs).
"""
import json
import os
import re
import sys

from figmyth import F, TEXT, DIM, HI, PANEL, BG as BG_RGB, COLOURS, CASE as CASE_DIR, canvas, save, kitlib, zx_colour

sys.path.insert(0, os.path.join(kitlib.unreal_root(None), 'tools', 'verification', 'analysis'))
import zxscreen  # noqa: E402  (kit)

MEMORY = [
    (0x4000, 0x57FF, 'the screen bitmap', 'HUD drawn once; play area: RoomChange, CopyBuffer'),
    (0x5800, 0x5AFF, 'the attributes', 'UpdateAttributes writes the open cells'),
    (0x5B00, 0x6CFF, 'the play buffer, 4608 bytes', '18 rows x 8 lines x 32 bytes, linear; also the unpack area'),
    (0x6D00, 0x6FFF, 'ShadowAttributes, 768 bytes', 'the room colours with the actors painted in'),
    (0x7040, 0x727F, 'RoomAttributes', 'the scenery colours, put back after a room change'),
    (0x7280, 0x74BF, 'Cells', '32 x 18 tile numbers, then kinds (0 open)'),
    (0x74E0, 0x75DB, 'the actor records', '14 records of 18 bytes from HeroRecord'),
    (0x76A0, 0x76FF, 'SpanTable (and on)', '6 bytes a span: length, 0, buffer, screen'),
]


def spans(work, frame, out):
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def mem(addr, n):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                         'offset': addr, 'length': n}, ok=False)
        body = r.structured or {}
        if r.is_error or not body.get('exact', False):
            raise SystemExit(f'memory_at {frame}: {r.text}')
        return bytes.fromhex(body['hex'])

    scr = mem(0x4000, 0x1B00)
    count = int.from_bytes(mem(0xFE1C, 2), 'little')
    table = mem(0x76A0, count * 6)
    sc = 2
    pic = zxscreen.render(scr, sc).convert('RGB')
    im, d, y = canvas(40 + 60 + pic.height + 40, 'The screen at c1 frame %d, room 8: the %d open spans' % (frame, count),
                      'Outlined: each span CopyBuffer copies from the play buffer (BuildSpans made them at the room change).\n'
                      'The rest of the play area is scenery, drawn once onto the screen by RoomChange.\n'
                      'Boxes: the HUD (rows 0-5) and the play area (rows 6-23, columns 2-29).')
    x0, y0 = 16, y + 4
    im.paste(pic, (x0, y0))
    d.rectangle((x0, y0, x0 + 256 * sc - 1, y0 + 48 * sc - 1), outline=DIM)
    d.rectangle((x0 + 16 * sc, y0 + 48 * sc, x0 + 240 * sc - 1, y0 + 192 * sc - 1), outline=DIM)
    for i in range(count):
        n, _, blo, bhi, slo, shi = table[i * 6:i * 6 + 6]
        saddr = slo | shi << 8
        off = saddr - 0x4000
        col = off & 31
        line = ((off >> 8) & 7) | ((off >> 2) & 0x38) | ((off >> 5) & 0xC0)
        d.rectangle((x0 + col * 8 * sc, y0 + line * sc, x0 + (col + n) * 8 * sc - 1, y0 + (line + 8) * sc - 1),
                    outline=HI, width=1)
    d.text((x0, y0 + pic.height + 8), '%d spans, %d open cells of 504' % (
        count, sum(table[i * 6] for i in range(count))), font=F(14), fill=HI)
    # the memory map
    mx = x0 + pic.width + 24
    my = y0
    d.text((mx, my), 'Stage 1\'s drawing memory', font=F(15), fill=TEXT)
    my += 26
    for i, (lo, hi, name, what) in enumerate(MEMORY):
        c = COLOURS[i % len(COLOURS)]
        d.rectangle((mx, my, mx + 10, my + 40), fill=c)
        d.text((mx + 18, my), '$%04X-$%04X  %s' % (lo, hi, name), font=F(13), fill=TEXT)
        d.text((mx + 18, my + 20), what, font=F(13), fill=DIM)
        my += 50
    save(im.crop((0, 0, im.width, max(y0 + pic.height + 34, my + 4))), out)


# the c1 room change 8 to 7: (phase, T-states), from the trace 16531:33882-16549:64359
PHASES = [
    ('the pass to CheckRoomExits (ClearBuffer)', 35693),
    ('LeaveRoomLeft, ClearPlayBuffer (LDIR)', 123760),
    ('Unrle: StageGraphics $B4B2 to $5B00', 213849),
    ('ClearShots', 2555),
    ('RoomCells: 9 x 14 blocks to 28 x 18 cells', 98104),
    ('BlackOutPlayArea', 18570),
    ('the 18 rows: 504 tiles to the screen', 342677),
    ('BuildSpans', 126016),
    ('ClearBuffer (PUSH)', 32449),
    ('LoadRoomActors, the actors, DrawActors', 100671),
    ('UpdateAttributes after a HALT; the HUD', 194117),
]


def phases(out):
    total = sum(t for _, t in PHASES)
    im, d, y = canvas(118 + 34 * len(PHASES) + 60, 'The heaviest pass: c1\'s room change from room 8 to room 7',
                      'Frames 16531:33882-16549:64359, %s T-states (%.2f frames of 69 888 T).\nEach phase from the '
                      'trace\'s routine entries; its T-states from the instructions run.' % (
                          format(total, ',').replace(',', ' '), total / 69888))
    y += 10
    lx, bx, bw = 16, 400, 470
    scale = bw / max(t for _, t in PHASES)
    for i, (name, t) in enumerate(PHASES):
        c = COLOURS[i % len(COLOURS)]
        d.text((lx, y + 4), name, font=F(13), fill=TEXT)
        d.rectangle((bx, y + 2, bx + max(2, int(t * scale)), y + 24), fill=c)
        d.text((bx + int(t * scale) + 8, y + 4), '%s T  %.2f fr' % (format(t, ',').replace(',', ' '), t / 69888),
               font=F(13), fill=DIM)
        y += 34
    y += 10
    # the whole as one strip
    x = lx
    sw = 1050 - 2 * lx
    for i, (name, t) in enumerate(PHASES):
        w = t * sw / total
        d.rectangle((int(x), y, int(x + w), y + 22), fill=COLOURS[i % len(COLOURS)])
        x += w
    for k in range(0, int(total / 69888) + 1):
        fx = lx + k * 69888 * sw / total
        d.line((fx, y + 24, fx, y + 30), fill=DIM)
    d.text((lx, y + 32), 'the strip: the whole pass to scale, a tick every frame', font=F(13), fill=DIM)
    save(im.crop((0, 0, im.width, y + 54)), out)


SPRITE_SETS = [
    ('stage1', 'sprites-hero-walk.png'), ('stage1', 'sprites-hero-jump.png'), ('stage1', 'sprites-hero-leap.png'),
    ('stage1', 'sprites-hero-strike.png'), ('stage1', 'sprites-warrior.png'), ('stage1', 'sprites-warrior-collapse.png'),
    ('stage1', 'sprites-statue.png'), ('stage1', 'sprites-strikeable.png'), ('stage1', 'sprites-gate.png'),
    ('stage1', 'sprites-arena-head.png'), ('stage1', 'sprites-fire-pit.png'), ('stage1', 'sprites-flame-jet.png'),
    ('stage1', 'sprites-piece.png'), ('stage1', 'bitmaps-hanging-2x37.png'), ('stage1', 'bitmaps-boss-wing-3x33.png'),
    ('stage1', 'bitmaps-boss-body-6x32.png'), ('stage1', 'bitmaps-boss-head-2x20.png'),
    ('stage1', 'bitmaps-item-icons-2x16.png'), ('stage1', 'bitmaps-flat-shot-2x8.png'),
    ('stage1', 'bitmaps-thrown-2x6.png'), ('stage1', 'bitmaps-bounce-2x13.png'),
    ('stage1', 'bitmaps-drift-shots-3x13.png'), ('stage1', 'bitmaps-fragment-3x11.png'),
    ('stage5', 'bitmaps-hero-3x24.png'),
]


def readme_rows(stage):
    rows = {}
    for line in open(os.path.join(CASE_DIR, 'src', 'res', stage, 'README.md')):
        cells = [c.strip() for c in line.strip().strip('|').split('|')]
        if len(cells) == 5 and cells[0].startswith('`'):
            for name in re.findall(r'`([^`]+\.png)`', cells[0]):
                rows[name] = cells
    return rows


def frame_sizes(path):
    from PIL import Image
    im = Image.open(path)
    meta = im.info.get('tx-frames')
    if meta:
        return [tuple(s) for s in json.loads(meta)['sizes']]
    m = re.search(r'-(\d+)x(\d+)\.png$', path)
    w, h = int(m.group(1)), int(m.group(2))
    return [(w, h)] * ((im.width - 1) // (w * 8 + 1))


def plain(s):
    return s.replace('`', '')


def sprites(out):
    from PIL import Image
    rows = {'stage1': readme_rows('stage1'), 'stage5': readme_rows('stage5')}
    sc = 2
    items = []
    for stage, name in SPRITE_SETS:
        path = os.path.join(CASE_DIR, 'src', 'res', stage, name)
        im = Image.open(path).convert('RGB')
        r = rows[stage][name]
        sizes = frame_sizes(path)
        ws = sorted({w for w, _ in sizes})
        hs = sorted({h for _, h in sizes})
        wtxt = '%d' % ws[0] if len(ws) == 1 else '%d-%d' % (ws[0], ws[-1])
        htxt = '%d' % hs[0] if len(hs) == 1 else '%d-%d' % (hs[0], hs[-1])
        head = '%s%s  %s, %s bytes: %s' % ('stage 5 ' if stage == 'stage5' else '', name, plain(r[1]), r[2], plain(r[3]))
        if stage == 'stage5':
            plot = 'drawn by DrawHero $8576 straight to the screen; HeroFrames $85D9: 16 entries, 12 images'
        elif name.startswith('sprites-') or name in ('bitmaps-hanging-2x37.png', 'bitmaps-boss-wing-3x33.png',
                                                     'bitmaps-boss-body-6x32.png', 'bitmaps-boss-head-2x20.png',
                                                     'bitmaps-item-icons-2x16.png', 'bitmaps-fragment-3x11.png'):
            plot = ('%d frames of %s x %s; by %s through DrawActorSprite: PlotRowN for N = %s bytes, mirrored facing left'
                    % (len(sizes), wtxt, htxt, plain(r[4]), wtxt))
        else:
            plot = '%d frames of %s x %s; a missile, drawn by its own handler: %s' % (len(sizes), wtxt, htxt,
                                                                                  plain(r[4]))
        # wider than the page at 2x: cut at a frame boundary into two rows
        cuts, x = [], 1
        for w, _ in sizes:
            x += w * 8 + 1
            cuts.append(x)
        parts, start = [], 0
        while im.width - start > 1018 // sc:
            end = max(c for c in cuts if c - start <= 1018 // sc)
            parts.append(im.crop((start, 0, end, im.height)))
            start = end - 1
        parts.append(im.crop((start, 0, im.width, im.height)))
        pic = Image.new('RGB', (max(p.width for p in parts) * sc, sum(p.height * sc + 6 for p in parts)), BG_RGB)
        yy = 0
        for part in parts:
            pic.paste(part.resize((part.width * sc, part.height * sc), Image.NEAREST), (0, yy))
            yy += part.height * sc + 6
        items.append((pic, head, plot))
    height = sum(i[0].height + 82 for i in items) + 90
    im, d, y = canvas(height, 'The sprites of stage 1 (and the hero of stage 5), as the code holds them',
                      'Each set: the frames in a row, ink white, grey the frame boxes (2x). Above: the file in src/res, '
                      'its address and size, what it is;\nthen the frames\' sizes in bytes x lines and the routine that '
                      'draws them.\nNo set has a mask: the plotters OR the bytes into the play buffer. Facing left, '
                      'DrawActorSprite takes the mirrored plotter\nof the same width (none for 7 bytes).')
    for pic, head, plot in items:
        lines = []
        for text, colour in ((head, TEXT), (plot, DIM)):
            words, cur = text.split(' '), ''
            for wd in words:
                if cur and d.textlength(cur + ' ' + wd, font=F(13)) > 1010:
                    lines.append((cur, colour))
                    cur = wd
                else:
                    cur = (cur + ' ' + wd).strip()
            lines.append((cur, colour))
        for k, (text, colour) in enumerate(lines):
            d.text((16, y + 17 * k), text, font=F(13), fill=colour)
        im.paste(pic, (16, y + 17 * len(lines) + 4))
        y += pic.height + 17 * len(lines) + 14
    save(im.crop((0, 0, im.width, y + 4)), out)


def shift(out):
    sys.path.insert(0, os.path.join(CASE_DIR, 'tools'))
    import res_stage  # noqa: E402
    raw = open(os.path.join(CASE_DIR, 'src', 'res', 'stage1', 'sprites-warrior.png'), 'rb').read()
    bms, meta = res_stage.png_to_frames(raw, 'tx-frames')
    w, h = meta['sizes'][9]
    bm = bms[9]
    cell = 14
    block = h * cell + 40
    im, d, y = canvas(60 + 4 * block + 40, 'PreShiftSprite $7F4D: the warrior\'s flying head shifted right by +$11 pixels',
                      'The frame (2 bytes x 6 lines, sprites-warrior.png frame 9) is copied to $7640 with a zero byte '
                      'added to each line,\nthen each line is shifted right +$11 times (ShiftRoutines). Gold lines: the '
                      'byte columns. The copy is one byte wider,\nso DrawActorSprite takes the plotter one byte wider '
                      '(PlotRow3). StepFineBack $8B4E moves +$11.')
    for n in range(8):
        x0 = 16 + (n // 4) * 520
        y0 = y + (n % 4) * block
        d.text((x0, y0), '+$11 = %d' % n, font=F(14), fill=TEXT)
        y0 += 22
        for r in range(h):
            v = (bm[r * w] << 16 | bm[r * w + 1] << 8) >> n
            for x in range((w + 1) * 8):
                on = v & (0x800000 >> x)
                d.rectangle((x0 + x * cell, y0 + r * cell, x0 + x * cell + cell - 2, y0 + r * cell + cell - 2),
                            fill=(235, 235, 235) if on else PANEL)
            d.text((x0 + (w + 1) * 8 * cell + 14, y0 + r * cell - 1),
                   '  '.join('%02X' % ((v >> s) & 255) for s in (16, 8, 0)), font=F(12), fill=DIM)
        for b in range(w + 2):
            d.line((x0 + b * 8 * cell - 1, y0 - 3, x0 + b * 8 * cell - 1, y0 + h * cell + 1), fill=HI, width=2)
    save(im, out)


def colours(work, frame, out):
    import re_session  # noqa: E402
    session, _ = re_session.session_of(work)

    def mem(addr, n):
        r = session.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': frame, 'tinframe': 0,
                                         'offset': addr, 'length': n}, ok=False)
        body = r.structured or {}
        if r.is_error or not body.get('exact', False):
            raise SystemExit(f'memory_at {frame}: {r.text}')
        return bytes.fromhex(body['hex'])

    room, shadow, kinds, attrs = mem(0x7042, 576), mem(0x6DC2, 576), mem(0x7282, 576), mem(0x58C2, 576)
    recs = mem(0x74E0, 14 * 18)
    boxes = []  # (row0, row1, col0, col1, attribute) in play cells, ColourActor $A6FF's rule
    for k in range(14):
        x, yy, w, h = recs[k * 18:k * 18 + 4]
        flags, attr, fshift = recs[k * 18 + 9], recs[k * 18 + 12], recs[k * 18 + 17]
        if x == 0xFF or yy >= 0x90 or recs[k * 18 + 15] & 0x40 and not recs[k * 18 + 15] & 0x80:
            continue
        wide = w + (1 if 0 < fshift < 0x64 else 0)
        col = x if not flags & 0x80 else x - w + 1 + (1 if 0 < fshift < 0x64 else 0)
        bottom = min(yy + h, 0x90) - 1
        boxes.append((yy // 8, bottom // 8, col - 2, col - 2 + wide - 1, attr))
    cell = 11
    pw, ph = 28 * cell, 18 * cell
    im, d, y = canvas(40 + 80 + ph + 70, 'The colours at c1 frame %d: the scenery, the shadow with the actors, the screen' % frame,
                      'Each cell: its paper, with its ink as the inner square. Left: RoomAttributes $7042, what a solid '
                      'cell gets back.\nMiddle: the shadow $6DC2, the open cells\' colours with the actors painted in; '
                      'gold: each actor\'s box (ColourActor\'s rule,\nthe records at $74E0). Right: the screen\'s '
                      'attributes $58C2; grey dots: solid cells (kind not 0), which keep their own colour.')

    def attr_cell(x, yy, a):
        bright = bool(a & 0x40)
        d.rectangle((x, yy, x + cell - 2, yy + cell - 2), fill=zx_colour((a >> 3) & 7, bright))
        d.rectangle((x + 3, yy + 3, x + cell - 5, yy + cell - 5), fill=zx_colour(a & 7, bright))

    titles = ['RoomAttributes $7042', 'shadow $6DC2, actors\' boxes', 'screen $58C2 (open cells from the shadow)']
    changed = 0
    for p, (title, src) in enumerate(zip(titles, (room, shadow, attrs))):
        x0, y0 = 16 + p * (pw + 30), y + 22
        d.text((x0, y), title, font=F(13), fill=TEXT)
        for r in range(18):
            for c in range(28):
                i = r * 32 + c
                x, yy = x0 + c * cell, y0 + r * cell
                attr_cell(x, yy, src[i])
                if p == 2 and kinds[i]:
                    d.rectangle((x + cell // 2 - 1, yy + cell // 2 - 1, x + cell // 2, yy + cell // 2), fill=DIM)
        if p == 1:
            for r0, r1, c0, c1, a in boxes:
                c0, c1 = max(c0, 0), min(c1, 27)
                if c0 > c1:
                    continue
                d.rectangle((x0 + c0 * cell - 2, y0 + r0 * cell - 2, x0 + (c1 + 1) * cell, y0 + (r1 + 1) * cell),
                            outline=HI, width=2)
                changed += 1
    opened = sum(1 for r in range(18) for c in range(28) if not kinds[r * 32 + c])
    d.text((16, y + 30 + ph), '%d actors drawn in the play area; %d open cells of 504 take the shadow\'s colour on the screen.'
           % (changed, opened), font=F(14), fill=HI)
    save(im, out)


if __name__ == '__main__':
    if sys.argv[1] == 'spans':
        spans(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    elif sys.argv[1] == 'sprites':
        sprites(sys.argv[2])
    elif sys.argv[1] == 'shift':
        shift(sys.argv[2])
    elif sys.argv[1] == 'colours':
        colours(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    else:
        phases(sys.argv[2])
