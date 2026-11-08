#!/usr/bin/env python3
"""The Lenslok atlas: every first-attempt challenge, the real ones from the emulator, the code matrix and two films.

    python3 tools/fig_lenslok_atlas.py [--atlas work/atlas] [--out docs/img/lenslok]
    (after tools/lenslok_sim.py enumerate and tools/lenslok_live.py)

- atlas-1.png, atlas-2.png: the 128 challenges of a first attempt (state byte $80-$FF). Each cell: the byte, the
  screen the game's code draws (DrawCode run in the Z80 simulator from c1's memory, tools/lenslok_sim.py), what
  the model lens shows, the code to type, and the read-back result;
- atlas-live.png: the 14 challenges met in the emulator (c1 and the runs of tools/lenslok_live.py), each the real
  frame at $C2A9, the lens view, the code, what was typed and what the game did;
- codes.png: every code any attempt can ask for (first character down, second across), coloured by the attempts
  that can give it;
- wrong.gif, accepted.gif: run a, a wrong answer "99" (the next code is drawn) and the computed answer (the game
  starts), real frames every 2 frames.
Also writes docs/lenslok-codes.md, the full list of codes (generated, do not edit).
"""
import argparse
import collections
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elitelib as E  # noqa: E402
import fig_lenslok as F  # noqa: E402
import lenslok as L  # noqa: E402
import lenslok_sim as S  # noqa: E402

sys.path.insert(0, E.KIT)
import zxscreen  # noqa: E402

CHARS = '012345678ABCDEFGHIJKLMNOPQRSTUVWXYabcdefghijklmnopqrstuvwxy'
CROP = (60, 50, 196, 84)          # screen x0, y0, x1, y1 of the slices (width 144: bar at row 55)


def crop(scr, S_=2):
    px = L.screen_pixels(scr)
    x0, y0, x1, y1 = CROP
    img = Image.new('RGB', ((x1 - x0) * S_, (y1 - y0) * S_), F.BG)
    d = ImageDraw.Draw(img)
    for x, y in px:
        if x0 <= x < x1 and y0 <= y < y1:
            d.rectangle([(x - x0) * S_, (y - y0) * S_, (x - x0) * S_ + S_ - 1, (y - y0) * S_ + S_ - 1], fill=F.FG)
    return img


def lens(scr, scale, cell=5):
    g = S.grid(scr, scale)
    img = Image.new('RGB', (13 * cell * 1 + 2, 8 * cell + 2), F.BG)
    d = ImageDraw.Draw(img)
    for r in range(8):
        for c in range(12):
            if g[r][c]:
                x = 1 + (c + (1 if c >= 6 else 0)) * cell
                d.rectangle([x, 1 + r * cell, x + cell - 2, 1 + (r + 1) * cell - 2], fill=F.hue(c))
    return img


def cell(scr, scale, lines, S_=2, lc=5):
    a = crop(scr, S_)
    b = lens(scr, scale, lc)
    f = F.fnt(15)
    tw = 270 if S_ <= 2 else 300
    W = a.width + 14 + b.width + 14 + tw
    H = max(a.height, b.height, 20 * len(lines)) + 10
    img = Image.new('RGB', (W, H), F.BG)
    d = ImageDraw.Draw(img)
    img.paste(a, (0, 5))
    img.paste(b, (a.width + 14, 5 + (a.height - b.height) // 2))
    for i, (txt, col) in enumerate(lines):
        d.text((a.width + b.width + 28, 5 + i * 20), txt, font=f, fill=col)
    d.rectangle([0, 0, W - 1, H - 1], outline=(50, 50, 58))
    return img


def sheet(cells, cols, title, out):
    import textwrap
    f = F.fnt(16)
    W, H = cells[0].width, max(c.height for c in cells)
    title = textwrap.wrap(title, max(40, (cols * (W + 8)) // 10))
    rows = (len(cells) + cols - 1) // cols
    top = 16 + 22 * len(title)
    img = Image.new('RGB', (cols * (W + 8) + 16, rows * (H + 6) + top + 4), F.BG)
    d = ImageDraw.Draw(img)
    for k, line in enumerate(title):
        d.text((12, 10 + 22 * k), line, font=f, fill=F.FG)
    for i, c in enumerate(cells):
        img.paste(c, (12 + (i % cols) * (W + 8), top + (i // cols) * (H + 6)))
    img.save(out)


def verdict(c):
    """green: read exactly; amber: the code's character among several (g / q, row 7 not drawn); red: wrong"""
    if c['ok']:
        return (120, 220, 120), '/'.join(c['read'])
    if all(c['code'][i] in c['read'][i] for i in range(2)):
        return (255, 170, 60), '/'.join(x if len(x) == 1 else '|'.join(x) for x in c['read']) + ' (row 7)'
    return (255, 90, 90), '/'.join(c['read'])


def atlas_first(at, out):
    check = {x['byte']: x for x in json.load(open(os.path.join(at, 'check.json'))) if x['kind'] == 'first'}
    base = open(S.START, 'rb').read()
    scale = base[0xC7B6]
    cells = []
    for byte in range(0x80, 0x100):
        k = '%02X' % byte
        scr = open(os.path.join(at, 'first', k + '.scr'), 'rb').read()
        c = check[k]
        good, rd = verdict(c)
        cells.append(cell(scr, scale, [(f'byte ${k}', F.DIM), (f'type  {c["code"]}', F.YEL),
                                       (f'lens reads {rd}', good)]))
    half = len(cells) // 2
    for i in range(2):
        sheet(cells[i * half:(i + 1) * half], 1,
              f'Lenslok atlas {i + 1}/2: first attempts, generator byte '
              f'${0x80 + i * half:02X}-${0x80 + (i + 1) * half - 1:02X}; screen by the game\'s DrawCode, lens = model', os.path.join(out, f'atlas-{i + 1}.png'))


def atlas_live(at, out):
    live = os.path.join(at, 'live')
    rows = json.load(open(os.path.join(live, 'runs.json')))
    check = {x['id']: x for x in json.load(open(os.path.join(at, 'check.json'))) if x['kind'] == 'live'}
    c1 = open(os.path.join(E.CASE, 'work', 'lenslok', '15900.scr'), 'rb').read()
    cells = [cell(c1, 13, [('c1, round 1 attempt 1', F.DIM), ('seed $FE81', F.DIM), ('type  si', F.YEL),
                           ('typed si: accepted', (120, 220, 120))], 3, 7)]
    for r in rows:
        rid = f"{r['run']}-{r['n']}"
        scr = open(os.path.join(live, rid + '.scr'), 'rb').read()
        mem = open(os.path.join(live, rid + '.bin'), 'rb').read()
        res = 'accepted' if r['accepted'] else ('wrong, reset' if r.get('reset') else 'wrong')
        good, rd = verdict(check[rid])
        cells.append(cell(scr, mem[0xC7B6], [(f"run {r['run']}, round {r['round']} attempt {r['attempt']}", F.DIM),
                                             (f"seed ${r['seed']}", F.DIM), (f"type  {r['code']}", F.YEL),
                                             (f"typed {r['typed']}: {res}", F.FG),
                                             (f"lens reads {rd}", good)], 3, 7))
    sheet(cells, 1, 'Lenslok in the emulator: the real frames at $C2A9 (c1 and three branches of it), the model '
          'lens, the code, the answer and the result', os.path.join(out, 'atlas-live.png'))


def codes_matrix(at, out, md):
    codes = json.load(open(os.path.join(at, 'codes.json')))
    kinds = {c: {s for s, _, _ in v} for c, v in codes.items()}
    C = 14
    f = F.fnt(13)
    n = len(CHARS)
    img = Image.new('RGB', (max(40 + n * C + 20, 860), 40 + n * C + 60), F.BG)
    d = ImageDraw.Draw(img)
    col = {'first': (255, 210, 60), 'later': (90, 160, 255), 'second': (200, 110, 255)}
    for i, a in enumerate(CHARS):
        d.text((24, 40 + i * C - 1), a, font=f, fill=F.FG)
        d.text((40 + i * C + 2, 24), a, font=f, fill=F.FG)
        for j, b in enumerate(CHARS):
            k = kinds.get(a + b)
            x, y = 40 + j * C, 40 + i * C
            if not k:
                d.rectangle([x, y, x + C - 2, y + C - 2], outline=(40, 40, 46))
                continue
            fill = col['first'] if 'first' in k else (col['later'] if 'later' in k else col['second'])
            d.rectangle([x, y, x + C - 2, y + C - 2], fill=fill)
    y = 40 + n * C + 10
    lx = 40
    for k, txt in (('first', 'a first attempt can ask it'), ('later', 'only a later attempt'),
                   ('second', 'only a second round\'s first attempt')):
        d.rectangle([lx, y + 2, lx + 12, y + 14], fill=col[k])
        d.text((lx + 18, y), txt, font=f, fill=F.FG)
        lx += 40 + int(d.textlength(txt, font=f))
    d.text((40, y + 22), f'{len(codes)} codes; first character down, second across', font=f, fill=F.FG)
    img.save(out)
    write_codes_md(at, codes, kinds, md)


def write_codes_md(at, codes, kinds, md):
    """docs/lenslok-codes.md: the codes for a reader who just wants to know what the game can show"""
    ch = json.load(open(os.path.join(at, 'challenges.json')))
    first = [r for r in ch if r['state'] == 'first' and r['reachable']]
    freq = collections.Counter(r['code'] for r in first)
    used = set(''.join(codes))
    never = [c for c in CHARS if c not in used]
    gq = sorted(c for c in codes if c[1] in 'gq')
    top, top_n = freq.most_common(1)[0]
    lines = [
        '# Lenslok: every code Elite can ask for', '',
        'When Elite starts, it shows two characters cut into thin strips and shuffled, so the screen looks like noise.',
        'Through the Lenslok lens the strips fall back into place and the two characters can be read. The player types',
        'them and the game starts. This page lists every pair the game can ever show. How it works inside:',
        '[lenslok.md](lenslok.md).', '',
        '![What the screen shows and what the lens makes of it](img/design/lenslok.png)', '',
        '**How to read it.** At the top, the real screen: a row of short white strips between two lines, which reads',
        'as nothing. At the bottom, another code\'s strip (left) and the same strip as the lens rearranges it (the',
        'coloured characters): "si". The player types "si" and the game starts.', '',
        '## In short', '',
        '- The game keeps no list of codes. It makes each code from a random number taken at the moment ENTER is',
        '  pressed, so the same tape asks different codes on every load.',
        f'- **{len(codes)}** different codes are possible, out of 3422 two-character pairs.',
        f'- Right after loading only **{len(freq)}** of them can come up. The most frequent, "{top}", comes {top_n} times',
        '  in 128.',
        '- Upper or lower case does not matter when typing: "SI" is as good as "si".',
        '- These characters never appear in a code: ' + ', '.join(f'"{c}"' for c in never) + '. Nor does the digit 9.',
        f'- {len(gq)} codes end in "g" or "q": ' + ', '.join(f'"{c}"' for c in gq) + '. Through the lens the two',
        '  letters look the same, because the game loses the bottom row of the second character (a bug of the original,',
        '  [lenslok.md](lenslok.md) 4.4). The player can only guess; a wrong guess just brings a new code.',
        '- After three wrong answers the game goes back to the screen where the lens width is set. After three more,',
        '  the computer resets.', '',
        f'## The first code after loading ({len(freq)} codes)', '',
        'The first code depends only on the random number (128 values), so its chances can be counted exactly.',
        'Each cell is a code and how many of the 128 values give it.', '']
    items = sorted(freq.items())
    cols = 8
    lines += ['| ' + ' | '.join(['Code', 'In 128'] * cols) + ' |', '|' + ' --- |' * (2 * cols)]
    for i in range(0, len(items), cols):
        row = items[i:i + cols]
        cells = [x for c, n in row for x in (f'`{c}`', str(n))]
        cells += [''] * (2 * cols - len(cells))
        lines.append('| ' + ' | '.join(cells) + ' |')
    lines += ['', f'## Every code the game can ask ({len(codes)} codes)', '',
              'A wrong answer brings a new code, made from the last one, so later attempts reach codes the first one',
              'never asks. The codes are grouped by their first character.', '',
              '| First | Codes |', '| --- | --- |']
    for a in CHARS:
        row = [a + b for b in CHARS if a + b in codes]
        if row:
            lines.append(f'| `{a}` | `' + ' '.join(row) + '` |')
    lines += ['', '![Every code: first character down, second across](img/lenslok/codes.png)', '',
              '**How to read it.** A square is a code: the first character is the row, the second the column. Amber',
              'squares can come right after loading, blue ones only after a wrong answer, violet ones only in the',
              'second round. Dark squares are pairs the game never shows; the empty rows and columns are the',
              'characters it never uses.', '',
              '## For the technically curious: which number gives which first code', '',
              'The random number is the Z80\'s R register, read at `$C29A` when ENTER is pressed. Its top bit is always',
              'set, so it takes 128 values, `$80-$FF`. The game also draws two random "marks" at the outer edges of the',
              'code, which the lens never shows; they do not change the code.', '']
    cols = 4
    byte_rows = [(r['byte'], r['code']) for r in first]
    lines += ['| ' + ' | '.join(['Number', 'Code'] * cols) + ' |', '|' + ' --- |' * (2 * cols)]
    per = (len(byte_rows) + cols - 1) // cols
    for i in range(per):
        cells = []
        for k in range(cols):
            j = k * per + i
            if j < len(byte_rows):
                cells += [f'`${byte_rows[j][0]:02X}`', f'`{byte_rows[j][1]}`']
        lines.append('| ' + ' | '.join(cells) + ' |')
    lines += ['', 'This page is generated by `python3 tools/fig_lenslok_atlas.py` from `tools/lenslok_sim.py enumerate`,',
              'which runs the game\'s own code in a Z80 simulator over every state the code maker can be in. Edit the',
              'script, not the page.']
    open(md, 'w').write('\n'.join(lines) + '\n')


FILMS = {'wrong': 'A wrong answer: "99" typed (run a, attempt 1), the screen clears and the next code is drawn',
         'accepted': 'The computed answer "Ns" typed with no lens (run a, attempt 3): the game takes it and starts'}


def film(src, out, title, step_ms=80):
    """the real screens of a run at 2x, every 2 frames, under a title, the picture's number in every one"""
    files = sorted(os.listdir(src))
    f16, f13 = F.fnt(16), F.fnt(13)
    probe = ImageDraw.Draw(Image.new('RGB', (1, 1)))
    lines = F.wrap(probe, title, f16, 512 - 12)
    top = 8 + 21 * len(lines) + 4
    fr = []
    for i, f in enumerate(files):
        im = Image.new('RGB', (512, top + 384 + 22), F.BG)
        d = ImageDraw.Draw(im)
        for k, line in enumerate(lines):
            d.text((6, 8 + 21 * k), line, font=f16, fill=F.FG)
        im.paste(zxscreen.render(open(os.path.join(src, f), 'rb').read(), 2), (0, top))
        d.text((6, top + 386), 'screen %d of %d, every 2nd frame' % (i + 1, len(files)), font=f13,
               fill=(150, 150, 160))
        fr.append(im)
    fr[0].save(out, save_all=True, append_images=fr[1:], duration=[step_ms] * (len(fr) - 1) + [1500], loop=0,
               optimize=True)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--atlas', default=os.path.join(E.CASE, 'work', 'atlas'))
    p.add_argument('--out', default=os.path.join(E.CASE, 'docs', 'img', 'lenslok'))
    a = p.parse_args()
    atlas_first(a.atlas, a.out)
    atlas_live(a.atlas, a.out)
    codes_matrix(a.atlas, os.path.join(a.out, 'codes.png'), os.path.join(E.CASE, 'docs', 'lenslok-codes.md'))
    for name in ('wrong', 'accepted'):
        film(os.path.join(a.atlas, 'live', 'gif-' + name), os.path.join(a.out, name + '.gif'), FILMS[name])
    print(a.out)


if __name__ == '__main__':
    sys.exit(main())
