#!/usr/bin/env python3
"""Pictures of every resource of the game (src/res, listed in src/res/README.md), written to docs/img/res. They are
for looking only: the source of the game is the .bin / .scr files, assembled with INCBIN.

    python3 tools/res_preview.py [--out docs/img/res] [--image build/game.bin]

- screens: the two .scr files as the Spectrum shows them;
- the font and the course tiles (a tile as on the screen: its first byte the bottom line, the blit draws a buffer
  column upward, docs/06-rendering.md 6.3);
- sprite blocks and explosion frames (6.6): the four pre-shifted frames, strips of mask and pixel pairs, the first
  pair the bottom line, drawn as the game draws them (AND mask, OR pixels; checkered where the mask keeps the
  background); a GIF of the frames in turn, and the explosion's seven frames in the order its counter steps;
- each course (6.5): the course expanded into rows through the row lists `$C8EA`, and the strips `FreshStrip` builds
  from them (tile i from row s + i at offset i, the edge tile below), side by side as the buffer stores them
  (unskewed); its ground profile (7.4): the 768 bytes `$D0EF` builds from the anchors of `$C9FE` (tools/verify_profile.py,
  equal to the recording's), height and walls;
- each round's objects (7.1-7.3): the 16 records placed by their position along and across, labelled by type;
- the title tune (9.2-9.5): the song and patterns run as the player runs them, a piano roll of the two voices
  (pitch by period, higher notes up; a note drawn until the next one of its voice: envelopes not modelled) and
  the drum steps;
- tables and leftovers: their bytes as 1-bit pixels, 32 bytes a row.

The row lists and the course table are in the source, not in src/res: they are read from the assembled image
(`build/game.bin`, written by tools/build.sh).
"""
import argparse
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import verify_profile  # noqa: E402
import zxscreen  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RES = os.path.join(ROOT, 'src', 'res')
LO = 0x5FB4

INK, PAPER, FRAME = (230, 230, 230), (24, 24, 32), (60, 60, 70)
TEXT = (220, 220, 200)
CHECK = ((70, 70, 80), (90, 90, 100))
GAP = 4

# Block size: (lines a strip, strips of frames 0-3), docs/06-rendering.md 6.6
SPRITE_LAYOUT = {
    630: (21, (4, 4, 4, 3)),  # types 0-3
    420: (14, (4, 4, 4, 3)),  # pads and dishes
    374: (17, (3, 3, 3, 2)),  # types 4-10
    182: (13, (2, 2, 2, 1)),  # types 11-13
    168: (21, (4,)),          # an explosion frame (drawn as a type 3)
}
EXPLOSION_ORDER = ('20', '22', '20', '26', '28', '2a', '2c')  # the counter $20-$2C by 2; $24 points at $7CB8 too
ROWS, ANCHORS, TILES = 0xC8EA, 0xC9FE, 0xC400
TYPE_NAMES = {2: 'dome', 3: 'dome+pod', 4: 'missile', 5: 'missile', 6: 'missile', 7: 'missile', 8: 'jet', 9: 'jet',
              10: 'cube', 14: 'pad', 15: 'dish'}
TYPE_COLOURS = {2: (90, 200, 90), 3: (150, 240, 120), 4: (240, 120, 90), 5: (240, 120, 90), 6: (240, 120, 90),
                7: (240, 120, 90), 8: (120, 170, 250), 9: (120, 170, 250), 10: (240, 220, 90), 14: (220, 120, 240),
                15: (240, 240, 240)}
FONT = ImageFont.load_default()


def read(name):
    return open(os.path.join(RES, name), 'rb').read()


def save(image, path, scale=1):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if scale != 1:
        image = image.resize((image.width * scale, image.height * scale), Image.NEAREST)
    image.save(path)
    print(os.path.relpath(path, ROOT))


def save_gif(frames, path, scale, ms):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    frames = [f.resize((f.width * scale, f.height * scale), Image.NEAREST) for f in frames]
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=ms, loop=0)
    print(os.path.relpath(path, ROOT))


def glyphs(data, columns, upward=False):
    """8 x 8 glyphs, one byte a line (the first the top, or the bottom when upward), in a grid"""
    count = len(data) // 8
    rows = (count + columns - 1) // columns
    image = Image.new('RGB', (columns * 9 + 1, rows * 9 + 1), FRAME)
    px = image.load()
    for g in range(count):
        x0, y0 = 1 + (g % columns) * 9, 1 + (g // columns) * 9
        for line in range(8):
            byte = data[g * 8 + line]
            y = y0 + (7 - line if upward else line)
            for bit in range(8):
                px[x0 + bit, y] = INK if byte & (0x80 >> bit) else PAPER
    return image


def sprite_frames(data):
    """One image a frame, all the width of the widest"""
    lines, frames = SPRITE_LAYOUT[len(data)]
    widest = max(frames)
    out, at = [], 0
    for strips in frames:
        image = Image.new('RGB', (widest * 8 + 2 * GAP, lines + 2 * GAP), FRAME)
        px = image.load()
        for x in range(widest * 8):
            for y in range(lines):
                px[GAP + x, GAP + y] = CHECK[(x // 2 + y // 2) & 1]
        for s in range(strips):
            for line in range(lines):
                mask, pixels = data[at + 2 * line], data[at + 2 * line + 1]
                y = GAP + lines - 1 - line
                for bit in range(8):
                    if pixels & (0x80 >> bit):
                        px[GAP + s * 8 + bit, y] = INK
                    elif not mask & (0x80 >> bit):
                        px[GAP + s * 8 + bit, y] = PAPER
            at += lines * 2
        out.append(image)
    assert at == len(data), (len(data), at)
    return out


def row_of(images):
    image = Image.new('RGB', (sum(i.width for i in images), images[0].height), FRAME)
    x = 0
    for i in images:
        image.paste(i, (x, 0))
        x += i.width
    return image


def bit_map(data, width=32):
    rows = (len(data) + width - 1) // width
    image = Image.new('RGB', (width * 8, rows), FRAME)
    px = image.load()
    for i, byte in enumerate(data):
        for bit in range(8):
            px[(i % width) * 8 + bit, i // width] = INK if byte & (0x80 >> bit) else PAPER
    return image


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


def course_rows(mem, course):
    """The rows CourseExpand ($D4D9) copies for a course: the word lists of its segment bytes, each ended by 0"""
    rows = []
    for b in course[1:]:
        if b == 0xFF:
            break
        a = ROWS + 2 * b
        while word(mem, a):
            rows.append(word(mem, a))
            a += 2
    return rows


def course_strips(mem, rows):
    """The strips FreshStrip ($D51D) builds, side by side as stored: 8 edge lines, then tile i of row s + i at offset
    i, byte 0 of each tile the lowest line"""
    count = len(rows) - 14
    image = Image.new('RGB', (count * 8, 128), PAPER)
    px = image.load()
    for s in range(count):
        edge = 0xC4C0 if (s + 1) & 3 == 0 else 0xC4B8
        column = [mem[edge + k] for k in range(8)]
        for i in range(15):
            tile = mem[rows[s + i] + i]
            column += [mem[TILES + 8 * tile + k] for k in range(8)]
        for k, byte in enumerate(column):
            for bit in range(8):
                if byte & (0x80 >> bit):
                    px[s * 8 + bit, 127 - k] = INK
    return image


def course_profile(course, title):
    """The 768 profile bytes `BuildGroundProfile` ($D0EF) writes at $6000 (verify_profile.build, checked against the
    recording): one byte for every 2 units along, height in bits 0-4, walls in bits 5-7"""
    profile = verify_profile.build(course, ANCHOR_BYTES)
    w, h, top = 2 * len(profile), 120, 18
    image = Image.new('RGB', (w + 40, h + top + 16), PAPER)
    draw = ImageDraw.Draw(image)
    draw.text((4, 2), title, fill=TEXT, font=FONT)
    base = top + h

    def y(height):
        return base - height * (h - 8) / 31

    draw.line([(20 + 2 * i, y(v & 31)) for i, v in enumerate(profile)], fill=(140, 200, 140), width=1)
    for i, v in enumerate(profile):
        if v & 0xE0:
            draw.line([(20 + 2 * i, top), (20 + 2 * i, top + 5)], fill=(240, 110, 90))
    draw.line([(18, base), (w + 30, base)], fill=FRAME)
    draw.text((4, base + 2), '0 .. %d units along; height 0-31 up; red: wall bits' % (2 * len(profile)),
              fill=(150, 150, 140), font=FONT)
    return image


ANCHOR_BYTES = None


def round_objects(data, title):
    w, h, top = 640, 150, 18
    image = Image.new('RGB', (w + 70, h + top + 30), PAPER)
    draw = ImageDraw.Draw(image)
    draw.text((4, 2), title, fill=TEXT, font=FONT)
    records = [data[i:i + 8] for i in range(0, len(data), 8)]
    alongs = [r[1] | r[2] << 8 for r in records if not r[0] & 0x80]
    span = max(alongs) if alongs else 1
    draw.rectangle([(10, top), (10 + w, top + h)], outline=FRAME)
    for r in records:
        if r[0] & 0x80:
            continue
        t = r[0] & 15
        x = 10 + (r[1] | r[2] << 8) * w / span
        yy = top + h - r[3] * h / 0x58
        colour = TYPE_COLOURS.get(t, INK)
        draw.ellipse([(x - 3, yy - 3), (x + 3, yy + 3)], fill=colour)
        draw.text((x + 4, yy - 6), TYPE_NAMES.get(t, str(t)), fill=colour, font=FONT)
    draw.text((10, top + h + 4), 'along 0 .. %d (scroll units, 2 a pass) ->   across up' % span,
              fill=(150, 150, 140), font=FONT)
    return image


def title_tune(mem):
    """Run tune 0 ($843F) as the player does: (voice notes [(start, end, period)] x2, drum steps [(frame, sound)],
    the frame the song jumps back)"""
    notes, drums = ([], []), []
    sounding = [None, None]
    length, t = 5, 0
    drum = None  # (address of the steps, speed, next frame)

    def start_note(voice, period):
        if sounding[voice]:
            notes[voice].append((sounding[voice][0], t, sounding[voice][1]))
        sounding[voice] = (t, period)

    def run_drums(until):
        nonlocal drum
        while drum and drum[2] < until:
            a, speed, at = drum
            if mem[a] == 1:  # 1 loops to the pattern's first step
                a = drum_start
            if mem[a]:
                drums.append((at, mem[a]))
            drum = (a + 1, speed, at + speed)

    def wait(frames):
        nonlocal t
        run_drums(t + frames)
        t += frames

    pos, seen, call = 0x843F, set(), None
    drum_start = None
    while t < 50 * 120:
        b = mem[pos]
        if b == 0xFC:
            break
        if b == 0xFF:
            pos = call
            continue
        target = word(mem, pos + 1)
        if b == 0xFE:
            call, pos = pos + 3, target
            continue
        if b == 0xFD:
            if target in seen:
                break
            pos = target
            continue
        seen.add(pos)
        if b == 0xFB:
            drum_start = target + 1
            drum = (drum_start, mem[target], t)
            pos += 3
            continue
        for _ in range(b):
            p = target
            while True:
                c = mem[p]
                p += 1
                if c == 9:
                    break
                if c in (1, 2, 3, 4):
                    p += 1
                elif c in (5, 6, 7, 8):
                    pass
                elif c == 10:
                    start_note(0, mem[p])
                    start_note(1, mem[p + 1])
                    p += 2
                    wait(length)
                elif c == 11:
                    start_note(0, mem[p])
                    p += 1
                    wait(length)
                elif c == 12:
                    start_note(1, mem[p])
                    p += 1
                    wait(length)
                elif c == 0:
                    wait(length)
                elif c == 16:
                    drum_start = word(mem, p) + 1
                    drum = (drum_start, mem[word(mem, p)], t)
                    p += 2
                elif c == 17:
                    length = mem[p]
                    p += 1
                elif c == 18:
                    wait(length * mem[p])
                    p += 1
                else:
                    sys.exit('title tune: command %d at $%04X not handled' % (c, p - 1))
        pos += 3
    for v in (0, 1):
        if sounding[v]:
            notes[v].append((sounding[v][0], t, sounding[v][1]))
    return notes, drums, t


def piano_roll(mem):
    notes, drums, end = title_tune(mem)
    periods = [n[2] for v in notes for n in v if n[2]]
    lo, hi = math.log(min(periods)), math.log(max(periods))
    px_frame = 1
    w, h, top, lane = end * px_frame, 220, 20, 34
    image = Image.new('RGB', (w + 60, top + h + lane + 30), PAPER)
    draw = ImageDraw.Draw(image)
    draw.text((4, 3), 'Title tune 0: voice A (orange), voice B (blue), drums below; %.1f s to the jump back' %
              (end / 50), fill=TEXT, font=FONT)
    x0 = 50
    for second in range(0, end // 50 + 1, 2):
        x = x0 + second * 50 * px_frame
        draw.line([(x, top), (x, top + h + lane)], fill=(40, 40, 52))
        draw.text((x + 2, top + h + lane + 4), '%ds' % second, fill=(150, 150, 140), font=FONT)

    def y(period):
        return top + 4 + (math.log(period) - lo) / (hi - lo) * (h - 12)

    for v, colour in ((0, (240, 160, 70)), (1, (110, 170, 250))):
        for start, stop, period in notes[v]:
            if period:
                yy = y(period)
                draw.rectangle([(x0 + start * px_frame, yy - 2), (x0 + stop * px_frame - 1, yy + 1)], fill=colour)
    draw.text((4, top), 'high', fill=(150, 150, 140), font=FONT)
    draw.text((4, top + h - 12), 'low', fill=(150, 150, 140), font=FONT)
    names = {2: 'click', 3: 'noise', 4: 'rise', 5: 'rise', 6: 'fall'}
    for frame, sound in drums:
        if frame < end:
            x = x0 + frame * px_frame
            yy = top + h + 6 + (sound - 2) * 6
            draw.rectangle([(x, yy), (x + 2, yy + 3)], fill=(200, 200, 200))
    for sound in range(2, 7):
        draw.text((4, top + h + 2 + (sound - 2) * 6), names[sound], fill=(150, 150, 140), font=ImageFont.load_default())
    return image


def main():
    global ANCHOR_BYTES
    p = argparse.ArgumentParser()
    p.add_argument('--out', default=os.path.join(ROOT, 'docs', 'img', 'res'))
    p.add_argument('--image', default=os.path.join(ROOT, 'build', 'game.bin'))
    p.add_argument('--scale', type=int, default=3)
    args = p.parse_args()
    if not os.path.exists(args.image):
        sys.exit(f'{args.image}: run tools/build.sh first (the row lists are read from the assembled image)')
    mem = bytes(LO) + open(args.image, 'rb').read()
    assert len(mem) == 0x10000
    out = args.out
    for name in ('loading', 'game'):
        save(zxscreen.render(read(f'screens/{name}.scr'), 1), os.path.join(out, f'screen-{name}.png'), 2)
    save(glyphs(read('gfx/font.bin'), 16), os.path.join(out, 'font.png'), args.scale)
    save(glyphs(read('gfx/tiles.bin'), 18, upward=True), os.path.join(out, 'tiles.png'), args.scale)
    for kind in ('sprites', 'explosions'):
        folder = os.path.join(RES, 'gfx', kind)
        for name in sorted(n for n in os.listdir(folder) if n.endswith('.bin')):
            frames = sprite_frames(read(f'gfx/{kind}/{name}'))
            save(row_of(frames), os.path.join(out, kind, name[:-4] + '.png'), args.scale)
            if len(frames) > 1:
                save_gif(frames, os.path.join(out, kind, name[:-4] + '.gif'), args.scale, 180)
    save_gif([sprite_frames(read(f'gfx/explosions/slot-{n}.bin'))[0] for n in EXPLOSION_ORDER],
             os.path.join(out, 'explosions', 'explosion.gif'), args.scale, 120)
    ANCHOR_BYTES = read('course/ground-anchors.bin')
    for n in range(1, 11):
        course = read(f'course/round-{n:02d}.bin')
        rows = course_rows(mem, course)
        save(course_strips(mem, rows), os.path.join(out, 'course', f'round-{n:02d}-strips.png'), 2)
        save(course_profile(course, f'Round {n}: ground profile ({"ground vehicle" if course[0] else "aircraft"})'),
             os.path.join(out, 'course', f'round-{n:02d}-profile.png'), 2)
        save(round_objects(read(f'course/objects-round-{n:02d}.bin'), f'Round {n}: the objects'),
             os.path.join(out, 'course', f'objects-round-{n:02d}.png'))
    save(bit_map(read('course/tile-runs.bin'), 16), os.path.join(out, 'course', 'tile-runs.png'), 2)
    save(piano_roll(mem), os.path.join(out, 'music', 'title-tune.png'))
    for name in ('tables/renderer-5b00', 'leftovers/profile-margin', 'leftovers/profile-buffer',
                 'leftovers/profile-buffer-tail', 'leftovers/screen-tail', 'leftovers/startup-copy',
                 'leftovers/sprite-gfx-copy', 'leftovers/title-player-copy', 'leftovers/sprite-save-buffer',
                 'leftovers/udg'):
        save(bit_map(read(name + '.bin')), os.path.join(out, name + '.png'), 2)
    return 0


if __name__ == '__main__':
    sys.exit(main())
