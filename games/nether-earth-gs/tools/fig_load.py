#!/usr/bin/env python3
"""Doc 03 figure: the disk load from RUN to the main menu as time (docs/img/load/disk-load.png).

    python3 tools/fig_load.py [--work work/gsA/load] [--out docs/img/load/disk-load.png]
    python3 tools/fig_load.py --gif docs/img/load/disk-load.gif [--step 40]
    python3 tools/fig_load.py --bar docs/img/load/progress.png

--bar: the top left corner of the screen (64 x 32 pixels from line 16), 8x, at seven moments of the recording: the
attribute cells $5861-$5864 that ShowByte paints with every byte sent, and DrawProgress's box with a tick per file
(TickX $6508 read at the same frame).

--gif: the screen of the same recording every --step frames from LoaderStart to the menu, 2x, each picture with
its frame and the file being read or sent (from the LoadFile frames).

The recording work/gsA/load: a Pentagon 128 + GS 512 KB from power-on, the SCL in drive A, `RUN "neart GS"` typed
by work/gsA/load/scl-boot.txt (ENTER at frame 326), 5650 frames recorded (TTD) with the card's port history
(zxbus.1.ports, capture mode) streamed to ports.jsonl. The loader's moments are the frames at which the recording
executed its entries (time_travel find_last, through the live instance of the recording, kept in --cache); the
port lanes are ports.jsonl, one bar a frame; the screens are memory_at of the same recording.

Top: the screen at eight moments. Below, one lane each: the loader's LoadFile calls (TR-DOS reads a file, the
name above), the bytes sent to the card's data port $B3 a frame, the commands written to $BB (labelled), the
status reads of WaitGs. The capture of the port history ends at frame 4546 (its file is cut there): the last
commands are drawn from the code's entries instead.
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
sys.path.insert(0, HERE)
import kitlib as K  # noqa: E402
import fig_render as R  # noqa: E402

LOAD_FILE, LOADER, DRIVER, GAME, START_MODULE, START = 0x639B, 0x61A8, 0x62AF, 0x62C3, 0x62DF, 0xA600
NAMES = ['neart000', 'neart002', 'neart003', 'neart004', 'neart005', 'neart006', 'neart007', 'neart008', 'neart009',
         'neart010', 'neart011', 'neart012', 'neart013', 'neart014', 'neart015', 'neart016', 'neart019', 'neart018',
         'neart023', 'neart019', 'neart020', 'neart021', 'neart001']     # the order of LoadFile calls in loader.asm
COMMANDS = {0xF4: '#F4 reset', 0x30: '#30', 0xD1: '#D1', 0xD2: '#D2', 0x3E: '#3E', 0x31: '#31', 0x2B: '#2B',
            0x2A: '#2A'}


def ports(path, last=None):
    data, cmds, stat = {}, [], {}
    with open(path) as f:
        for line in f:
            try:
                e = json.loads(line)
            except ValueError:
                break                      # the capture's file is cut in the middle of its last line
            low = e['port'] & 0xFF
            if e['dir'] == 'out' and low == 0xB3:
                data[e['frame']] = data.get(e['frame'], 0) + 1
            elif e['dir'] == 'out' and low == 0xBB:
                cmds.append((e['frame'], e['tacts'], e['value'], e['pc']))
            elif e['dir'] == 'in' and low == 0xBB:
                stat[e['frame']] = stat.get(e['frame'], 0) + 1
            last = e['frame']
    return data, cmds, stat, last


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', default=os.path.join(CASE, 'work', 'gsA', 'load'))
    p.add_argument('--cache', default=os.path.join(CASE, 'work', 'gsA', 'cache'))
    p.add_argument('--out', default=os.path.join(CASE, 'docs', 'img', 'load', 'disk-load.png'))
    p.add_argument('--last', type=int, default=5650)
    p.add_argument('--unreal')
    p.add_argument('--gif')
    p.add_argument('--bar')
    p.add_argument('--step', type=int, default=40)
    a = p.parse_args()
    rec = R.Recording(a.work, a.cache, a.unreal)
    loads = [f for f, t in rec.executions(LOAD_FILE, a.last, 40)]
    if a.gif:
        return gif(a, rec, loads)
    if a.bar:
        return bar(a, rec, loads)
    first = lambda addr: rec.executions(addr, a.last, 1)[0][0]
    f_loader, f_driver, f_game, f_module, f_start = (first(x) for x in (LOADER, DRIVER, GAME, START_MODULE, START))
    data, cmds, stat, cut = ports(os.path.join(a.work, 'ports.jsonl'))
    print('LoadFile at', loads)
    print('loader', f_loader, 'driver', f_driver, 'game', f_game, 'StartModule', f_module, 'Start', f_start,
          'port capture to', cut)
    print('commands', [(f, t, hex(v)) for f, t, v, _ in cmds[:6]], '...', len(cmds))
    print('data bytes', sum(data.values()), 'max a frame', max(data.values()), 'first status read', min(stat))

    F0, F1 = 300, a.last
    S = 1
    W = 1500
    LX, LW = 220, W - 240
    fx = lambda f: LX + (f - F0) * LW / (F1 - F0)
    moments = [(330, 'RUN typed'), (f_loader + 4, 'LoaderStart: screen cleared'), (loads[1] - 2, 'neart000 loaded'),
               (1500, 'the module streams'), (2700, 'effect 7 streams'), (f_game + 1, 'neart001 loading'),
               (f_start + 3, 'JP Start $A600'), (F1 - 2, 'the main menu')]
    thumbs = []
    for f, label in moments:
        mem = rec.read(f, 0x4000, 6912)
        thumbs.append((f, label, K.render_screen(mem, 0).resize((160, 120), Image.NEAREST)))
    H = 60 + 150 + 30 + 5 * 46 + 150
    img = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f14, f12, f11 = K.font(15), K.font(12), K.font(11)
    d.text((20, 12), f'The disk load, RUN to the menu: {len(loads)} TR-DOS file reads; each sound file is streamed '
           'from $8000 to the card; the module starts right after #F4', fill=K.TEXT, font=f14)
    d.text((20, 34), 'recording work/gsA/load (Pentagon 128 + GS 512 KB, the SCL, power-on = frame 0); every frame '
           'number below is of this recording', fill=K.DIM, font=f12)
    y = 60
    for k, (f, label, th) in enumerate(thumbs):
        x = 20 + k * 185
        img.paste(th, (x, y))
        d.text((x, y + 124), f'frame {f}', fill=K.TEXT, font=f11)
        d.text((x, y + 137), label, fill=K.DIM, font=f11)
        d.line([x + 80, y + 150, fx(f), y + 176], fill=(110, 110, 120), width=1)
    y0 = y + 180
    lanes = ['LoadFile (TR-DOS)', 'OUT ($B3): data a frame', 'OUT ($BB): commands', 'IN ($BB): WaitGs', 'stages']
    for i, name in enumerate(lanes):
        ly = y0 + i * 46
        d.rectangle([LX, ly, LX + LW, ly + 34], fill=(30, 31, 38))
        d.text((20, ly + 10), name, fill=K.TEXT, font=f12)
    # LoadFile: a mark per call, its file name
    ly = y0
    for k, f in enumerate(loads):
        x = fx(f)
        d.line([x, ly, x, ly + 34], fill=(240, 200, 80), width=2)
        if k < len(NAMES) and (k in (0, 1, 5, 6, 15, 16, 19, 20, 21, 22)):
            d.text((x + 2, ly + 2 + 14 * (k % 2)), NAMES[k][5:], fill=(240, 200, 80), font=f11)
    # data bytes a frame
    ly = y0 + 46
    top = max(data.values())
    for f, n in data.items():
        h = 32 * n / top
        d.line([fx(f), ly + 34, fx(f), ly + 34 - h], fill=(217, 164, 65))
    d.text((20, ly + 22), f'(up to {top}; to frame {cut})', fill=K.DIM, font=f11)
    # commands
    ly = y0 + 92
    last_x = -100
    for f, t, v, pc in cmds:
        x = fx(f)
        d.line([x, ly + 4, x, ly + 30], fill=(229, 83, 75), width=1)
        if x - last_x > 60 or v == 0xF4:
            d.text((x + 2, ly + 2), COMMANDS.get(v, f'#{v:02X}'), fill=(229, 83, 75), font=f11)
            last_x = x
    for f, label in ((f_module, '#31 #2B #2A'),):
        x = fx(f)
        d.line([x, ly + 4, x, ly + 30], fill=(229, 83, 75), width=1)
        d.text((x - 70, ly + 18), label, fill=(229, 83, 75), font=f11)
    # status reads
    ly = y0 + 138
    for f in stat:
        d.line([fx(f), ly + 6, fx(f), ly + 28], fill=(255, 159, 128))
    # stages
    ly = y0 + 184
    spans = [(F0, f_loader, 'BASIC + TR-DOS', (130, 130, 140)), (f_loader, loads[1], 'screen', (92, 143, 214)),
             (loads[1], loads[6], 'module: neart002-006', (199, 125, 219)),
             (loads[6], f_driver, 'effects 1-14', (64, 196, 196)), (f_driver, f_game, 'driver', (76, 175, 80)),
             (f_game, f_start, 'neart001', (240, 200, 80)), (f_start, F1, 'game: Start, menu', (229, 83, 75))]
    for a0, a1, label, colour in spans:
        d.rectangle([fx(a0), ly + 4, max(fx(a0) + 1, fx(a1) - 1), ly + 30], fill=colour)
        if fx(a1) - fx(a0) > 40:
            d.text((fx(a0) + 4, ly + 10), label, fill=(15, 15, 20), font=f11)
    for f in range(500, F1 + 1, 500):
        d.text((fx(f) - 12, y0 + 5 * 46 - 4), str(f), fill=K.DIM, font=f11)
    yy = y0 + 5 * 46 + 16
    for k, line in enumerate([
            f'#F4, #30 and #D1 go out in one frame ({cmds[0][0]}: T {cmds[0][1]}, {cmds[1][1]}, {cmds[2][1]}); the '
            f'first WaitGs status read is at frame {min(stat)}, after TR-DOS has read neart002',
            'Between two effects the gap is TR-DOS reading the next file; the bytes go out at the loop\'s pace '
            '(ShowByte colours four attribute cells with each one)',
            'The driver is read into bank 1 (OUT $7FFD,$11), then neart001 to $6590-$FFFF over the buffer at $8000; '
            'StartModule sends #31, the volumes follow, JP $A600',
            'python3 tools/fig_load.py --work work/gsA/load --out docs/img/load/disk-load.png']):
        d.text((20, yy + 16 * k), line, fill=K.DIM if k < 3 else (150, 150, 160), font=f12)
    os.makedirs(os.path.dirname(os.path.abspath(a.out)), exist_ok=True)
    img.save(a.out)
    print(a.out, img.size)


def bar(a, rec, loads):
    start = rec.executions(START, a.last, 1)[0][0]
    moments = [(loads[1] - 1, 'neart000 on, its own colours'), (1200, 'the module streams'),
               (loads[6] - 1, 'the module\'s last bytes'), (2160, 'effect 1 streams'), (3600, 'effect 10 sent'),
               (loads[22] + 10, 'neart001 being read'), (start + 2, 'Start has cleared the screen')]
    Z = 8
    cw, ch = 64 * Z, 32 * Z
    W = 20 + 4 * (cw + 24)
    H = 70 + 2 * (ch + 84) + 50
    img = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(img)
    f14, f12, f11 = K.font(15), K.font(12), K.font(11)
    d.text((20, 12), 'The loading display: four attribute cells take every byte sent as their colour (ShowByte $6345), '
           'and a box gets a tick per file (DrawProgress $64AF)', fill=K.TEXT, font=f14)
    d.text((20, 34), 'the screen\'s pixels 0-63 of lines 16-47 (character rows 2-5, columns 0-7), 8x; recording '
           'work/gsA/load; the cells are $5861-$5864 (row 3, columns 1-4), the box from line 32', fill=K.DIM, font=f12)
    for k, (f, label) in enumerate(moments):
        mem = rec.read(f, 0x4000, 6912)
        tick = rec.read(f, 0x6508, 1)[0]
        cells = rec.read(f, 0x5861, 4)
        crop = K.render_screen(mem, 0).crop((0, 16, 64, 48)).resize((cw, ch), Image.NEAREST)
        x = 20 + (k % 4) * (cw + 24)
        y = 64 + (k // 4) * (ch + 84)
        img.paste(crop, (x, y))
        dd = ImageDraw.Draw(img)
        dd.rectangle([x + 8 * Z, y + 8 * Z, x + 40 * Z - 1, y + 16 * Z - 1], outline=(255, 80, 200), width=2)
        dd.rectangle([x, y + 16 * Z, x + 24 * Z, y + 20 * Z], outline=(80, 220, 255), width=2)
        d.text((x, y + ch + 6), f'frame {f}: {label}', fill=K.TEXT, font=f12)
        d.text((x, y + ch + 24), f'cells {cells.hex(" ").upper()}, TickX {tick}', fill=K.DIM, font=f11)
    x = 20 + 3 * (cw + 24)
    y = 64 + (ch + 84)
    for i, (colour, line) in enumerate([((255, 80, 200), 'pink: the four cells ShowByte writes'),
                                        ((80, 220, 255), 'blue: DrawProgress\'s box, (0,140)-(22,143) in'),
                                        ((80, 220, 255), '  ROM coordinates, a tick at x = TickX'),
                                        ((200, 200, 200), 'TickX counts files: 23 LoadFile calls'),
                                        ((200, 200, 200), '$56 (BarDone): bright, red paper,'),
                                        ((200, 200, 200), '  yellow ink, after each stream')]):
        d.text((x, y + 18 * i), line, fill=colour, font=f12)
    d.text((20, H - 24), 'python3 tools/fig_load.py --bar docs/img/load/progress.png', fill=(150, 150, 160), font=f11)
    img.save(a.bar)
    print(a.bar, img.size)


def gif(a, rec, loads):
    start = rec.executions(START, a.last, 1)[0][0]
    pictures, durations = [], []
    frames = list(range(loads[0] - 2, a.last - 1, a.step))
    for f in frames:
        mem = rec.read(f, 0x4000, 6912)
        scr = K.render_screen(mem, 0).resize((512, 384), Image.NEAREST)
        k = max([i for i, x in enumerate(loads) if x <= f], default=-1)
        if f >= start:
            what = 'the game: Start $A600, the main menu'
        elif k < 0:
            what = 'TR-DOS: the BASIC runs neart022'
        else:
            name = NAMES[k]
            what = {'neart000': 'neart000: the loading screen', 'neart021': 'neart021: the driver, into bank 1',
                    'neart001': 'neart001: the game, to $6590-$FFFF'}.get(name, f'{name}: read by TR-DOS, then sent '
                                                                         'to the card')
        pic = Image.new('RGB', (512, 384 + 44), K.BACKGROUND)
        pic.paste(scr, (0, 0))
        d = ImageDraw.Draw(pic)
        d.text((6, 388), f'work/gsA/load  frame {f}', fill=K.DIM, font=K.font(12))
        d.text((6, 406), what, fill=(255, 200, 80), font=K.font(14))
        pictures.append(pic)
        durations.append(90)
    durations[0], durations[-1] = 1200, 2500
    K.save_gif(a.gif, pictures, durations)
    print(a.gif, len(pictures), 'pictures', os.path.getsize(a.gif) // 1024, 'KB')


if __name__ == '__main__':
    sys.exit(main())
