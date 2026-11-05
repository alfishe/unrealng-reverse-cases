#!/usr/bin/env python3
"""Doc 02 figure: the 128K's eight RAM pages at each stage of recording c1, as heatmaps of what the CPU executed,
read and wrote in that stage, over the page's contents at the stage's end.

    python3 tools/fig_banks.py --work work/z128A/c1 --out docs/img/arch/banks-stages.png

The counts are the L1 builds of each stage window (work/stage2/<stage>/l1.json, WALKTHROUGH 4: `byte_counts` per
page for the reads and the writes, `instructions` for the executions, each by physical page, so a byte of page 4 is
counted as page 4 whatever slot it was mapped in). The grey under the colours is the page's bytes at the stage's last
frame (time_travel memory_at, space ram, from the recording c1 open in W): a page that is grey but dark in colour
holds data nobody touched in that stage. One square is one page: 128 bytes a row, 128 rows, offset 0 at the top
left. The text under a square names what the stage put there or used it for (docs/02 2.1, docs/03).
"""
import argparse
import json
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.normpath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

# (build, first frame, last frame, title, {page: caption})
STAGES = [
    ('boot', 1870, 2051, 'boot.B list',
     {5: 'screen, BASIC,\nboot code', 2: 'list blitter $8CA0,\nlist pixels $9AC0', 0: 'line table\n$D6D8'}),
    ('loader', 2051, 2183, 'loader, block 1',
     {5: 'loader $5D40,\ndepacker $5B00', 2: 'block 1\n(intro)', 0: 'block 1 end\n$C000-$E8D4',
      1: '$11 at $C000:\nthe paging test', 4: 'the intro starts\nits copy (2183)'}),
    ('intro', 2182, 2838, 'intro',
     {5: 'intro code $6000,\nthe pictures', 2: 'STarKos + SK10\nat $8000', 0: 'IM 2 table\n$FC00',
      4: 'engine + data\ncopied here'}),
    ('load2', 2838, 3302, 'block 2 load',
     {5: 'depacker,\nblock 2 start', 2: 'block 2', 0: 'block 2 end\nto $FB84'}),
    ('glue', 3302, 3314, 'set-up',
     {5: 'glue $5B00,\ngame from $6800', 2: 'game: stubs\n$B30D written', 0: 'game moved\nto $FFFF'}),
    ('game', 3313, 13702, 'game',
     {5: 'screen, glue,\ngame $6800-$7FFF', 2: 'game code\n$8000-$BFFF', 0: 'game: glyphs,\nsprites, records',
      4: 'AY engine,\nmusic + effects'}),
]
CELL, GAP, LABEL_W = 128, 10, 170
ORDER = [5, 2, 0, 4, 1, 3, 6, 7]


def session(work):
    sys.path.insert(0, os.path.join(K.unreal_root(None), 'tools', 'verification', 'analysis'))
    import re_session  # noqa: E402
    s, _ = re_session.session_of(work)
    return s


def page_bytes(s, frame, page):
    r = s.call('time_travel', {'action': 'memory_at', 'space': 'ram', 'frame': frame, 'offset': page * 0x4000,
                               'length': 0x4000}, ok=False)
    if not r.structured or not r.structured.get('exact'):
        raise SystemExit(f'memory_at ram page {page} frame {frame}: {r.text[:200]}')
    return bytes.fromhex(r.structured['hex'])


def counts(build):
    d = json.load(open(os.path.join(CASE, 'work', 'stage2', build, 'l1.json')))
    reads, writes, execs = {}, {}, {}
    for bc in d['byte_counts']:
        if bc['page'] < 8:
            reads[bc['page']], writes[bc['page']] = bc['reads'], bc['writes']
    for a, page, code, _kind, n, *_ in d['instructions']:
        if page < 8:
            e = execs.setdefault(page, [0] * 0x4000)
            off = int(a[1:], 16) & 0x3FFF
            for i in range(len(code) // 2):
                if off + i < 0x4000:
                    e[off + i] += n
    total = d['replay']['instructions']
    per_page = {}
    for a, page, code, _kind, n, *_ in d['instructions']:
        per_page[page] = per_page.get(page, 0) + n
    return reads, writes, execs, total, per_page


def level(n):
    return 0 if n <= 0 else min(1.0, 0.25 + math.log2(n + 1) / 16)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--out', required=True)
    args = p.parse_args()
    s = session(args.work)
    f, fb, fs, ft = K.font(12), K.font(14), K.font(11), K.font(17)
    row_h = CELL + 44
    width = LABEL_W + 8 * (CELL + GAP) + 10
    height = 104 + len(STAGES) * row_h + 70
    img = Image.new('RGB', (width, height), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((10, 8), 'The 128K pages stage by stage: the game lives in pages 5, 2 and 0; page 4 holds only the sound',
           fill=K.TEXT, font=ft)
    d.text((10, 32), 'c1 (Pentagon 128 + TR-DOS, power-on to play). Green executed, blue read, red/yellow written '
           '(brighter = more often, log scale);', fill=K.DIM, font=f)
    d.text((10, 48), 'magenta = read and written; grey under the colours = the byte\'s value at the stage\'s last frame. '
           'One square = one 16 K page, 128 bytes a row.', fill=K.DIM, font=f)
    for col, page in enumerate(ORDER):
        x = LABEL_W + col * (CELL + GAP)
        slot = {5: '$4000', 2: '$8000', 0: '$C000'}.get(page, 'at $C000 when paged')
        d.text((x, 66), f'page {page}', fill=K.TEXT, font=fb)
        d.text((x, 82), slot, fill=K.DIM, font=fs)
    for row, (build, f0, f1, title, captions) in enumerate(STAGES):
        reads, writes, execs, total, per_page = counts(build)
        y = 104 + row * row_h
        d.text((10, y), title, fill=K.TEXT, font=fb)
        d.text((10, y + 20), f'frames {f0}-{f1}', fill=K.DIM, font=fs)
        d.text((10, y + 36), f'{total:,} instructions', fill=K.DIM, font=fs)
        ram = sum(per_page.get(pg, 0) for pg in range(8))
        rom = total - ram
        d.text((10, y + 52), f'ROM: {100 * rom / total:.0f} %', fill=K.DIM, font=fs)
        if per_page.get(4):
            d.text((10, y + 68), f'page 4: {100 * per_page[4] / total:.1f} %', fill=(120, 230, 140), font=fs)
        for col, page in enumerate(ORDER):
            x = LABEL_W + col * (CELL + GAP)
            content = page_bytes(s, f1, page)
            sq = Image.new('RGB', (CELL, CELL))
            px = sq.load()
            r, w, e = reads.get(page), writes.get(page), execs.get(page)
            for off in range(0x4000):
                v = content[off]
                g = 18 + v * 50 // 255
                c = [g, g, g + 4]
                if w and w[off]:
                    lv = level(w[off])
                    c = [max(c[0], int(255 * lv)), max(c[1], int(170 * lv * lv)), c[2]]
                if r and r[off]:
                    c[2] = max(c[2], int(255 * level(r[off])))
                if e and e[off]:
                    c[1] = max(c[1], int(255 * level(e[off])))
                px[off & 127, off >> 7] = tuple(c)
            img.paste(sq, (x, y))
            d.rectangle((x - 1, y - 1, x + CELL, y + CELL), outline=(60, 60, 75))
            cap = captions.get(page)
            if cap:
                d.multiline_text((x, y + CELL + 3), cap, fill=K.TEXT, font=fs, spacing=1)
            elif not any((r and any(r), w and any(w), e and any(e))):
                d.text((x, y + CELL + 3), 'kept, not touched' if any(content) else 'not touched',
                       fill=(110, 110, 120), font=fs)
    yl = height - 56
    d.text((10, yl), 'Pages 1, 3, 6, 7: never used by the program (page 1 keeps the paging test\'s one byte $11; '
           'page 7 holds the Pentagon menu\'s leftovers).', fill=K.DIM, font=f)
    d.text((10, yl + 18), 'Page 4 is paged in at $C000 only inside the glue\'s FramePlay $5B00 and the hook stub '
           'HookSound $B30D (OUT $7FFD,$14 ... OUT $7FFD,$10).', fill=K.DIM, font=f)
    img.save(args.out)
    print(args.out, img.size)


if __name__ == '__main__':
    main()
