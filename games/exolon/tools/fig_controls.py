#!/usr/bin/env python3
"""The figures of doc 05 (controls) and the key-moment sheets of doc 01, from the listing and the recordings.

    python3 tools/fig_controls.py ports                      # docs/img/controls/ports.png (the image only)
    python3 tools/fig_controls.py fire   --work work/docs/fillP/x2   # docs/img/controls/fire.png
    python3 tools/fig_controls.py name   --work work/docs/fillP/d1   # docs/img/controls/name-entry.png
    python3 tools/fig_controls.py define --work work/docs/fillP/m1   # docs/img/controls/define-keys.png
    python3 tools/fig_controls.py menu   --work work/docs/fillP/m1   # docs/img/controls/menu-choice.png
    python3 tools/fig_controls.py hazards                    # docs/img/design/hazards.png
    python3 tools/fig_controls.py zoneend --work work/docs/fillP/w124  # docs/img/design/zone-end.gif

WORK is a folder that re_session.py open made for a recording (an instance of its own, muted). Every memory read
(TTD memory_at) is kept in work/docs/fillP/cache/<folder name>/, so a second run needs no instance.
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fig_docb as B  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

plt = B.plt
K = B.K
CACHE = os.path.join(B.WORK, 'docs', 'fillP', 'cache')
_SESSIONS = {}


def mem(work, frame, lo, n):
    """n bytes from lo at the end of frame, read once through TTD memory_at and then kept"""
    d = os.path.join(CACHE, os.path.basename(os.path.normpath(work)))
    path = os.path.join(d, f'{frame}_{lo:04X}_{n}.bin')
    if os.path.isfile(path):
        return open(path, 'rb').read()
    if work not in _SESSIONS:
        _SESSIONS[work] = B.session(work)
    data = B.read(_SESSIONS[work], frame, lo, n)
    os.makedirs(d, exist_ok=True)
    open(path, 'wb').write(data)
    return data


def scr(work, frame):
    """the screen at the end of a frame; a .scr path as WORK reads that file (frame ignored); fig_sheet.py's cache
    WORK/screens-at/FRAME_0.scr is used when it holds the frame"""
    if work.endswith('.scr'):
        return B.scr_file(work)
    sheet = os.path.join(work, 'screens-at', f'{frame}_0.scr')
    if os.path.isfile(sheet):
        return B.screen(open(sheet, 'rb').read()[:6912])
    return B.screen(mem(work, frame, 0x4000, 6912))


def font(size):
    return K.font(size)


def caption_block(d, x, y, lines, size=12, fill=None, gap=3):
    f = font(size)
    for ln in lines:
        d.text((x, y), ln, fill=fill or K.TEXT, font=f)
        y += size + gap
    return y


# --- ports: the bit layouts of every port the game reads ------------------------------------------------------------

PORT_ROWS = [
    ('Kempston, port $1F (ReadKempston $7B4A: IN D,(C)); 1 = pressed',
     ['fire', 'up: jump', 'down: duck', 'left', 'right'], 'bits 5-7: not read (SRL D takes bits 0-4 only)',
     (110, 200, 120)),
    ('Interface 2 on half-row $EFFE (ReadInterface2 $7B22: IN, CPL, AND $1F); key 0 = pressed',
     ['6: left', '7: right', '8: duck', '9: jump', '0: fire'],
     'bits 5-7 (bit 6 the EAR input) cleared by AND $1F after the CPL', (240, 160, 70)),
    ('Abort on the same half-row $EFFE (AbortKeys $9A19: AND $0F, all four 0 = abort)',
     ['6: -', '7: abort', '8: abort', '9: abort', '0: abort'], 'bit 4 (key 6) masked off', (230, 90, 90)),
    ('Pause, half-row $F7FE (PauseKey $AD21: AND $1F, CP $1B = only key 3 down)',
     ['5: up', '4: up', '3: down', '2: up', '1: up'], 'any other pattern: no pause', (230, 90, 90)),
    ('Keyboard, any half-row (ReadKeyboard $7AE9: one IN and one AND mask per control); key 0 = pressed',
     ['bit 4', 'bit 3', 'bit 2', 'bit 1', 'bit 0'], 'the image: O $DF/$02, P $DF/$01, Q $FB/$01, A $FD/$01, M $7F/$04',
     (120, 200, 120)),
]


def cmd_ports(args):
    W, rowh, top = 1050, 92, 70
    H = top + rowh * len(PORT_ROWS) + 30
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((16, 12), 'Every port Exolon reads in play: one byte, five bits, bit 4 on the left', fill=K.TEXT,
           font=font(17))
    d.text((16, 40), 'drawn from build/game.lst; the bit names are the control bytes the readers fill ($7B92-$7B96)',
           fill=K.DIM, font=font(13))
    bw = 120
    for k, (title, bits, note, col) in enumerate(PORT_ROWS):
        y = top + k * rowh
        d.text((16, y), title, fill=K.TEXT, font=font(13))
        x0 = 16
        for b in range(8):
            x = x0 + b * (bw + 4)
            bit = 7 - b
            box = (x, y + 22, x + bw, y + 62)
            if bit > 4:
                d.rectangle(box, outline=K.DIM)
                d.text((x + 6, y + 30), f'bit {bit}', fill=K.DIM, font=font(12))
                d.text((x + 6, y + 45), '-', fill=K.DIM, font=font(12))
            else:
                d.rectangle(box, outline=col, width=2)
                d.text((x + 6, y + 26), f'bit {bit}', fill=K.DIM, font=font(12))
                d.text((x + 6, y + 42), bits[4 - bit], fill=col, font=font(13))
        d.text((16, y + 66), note, fill=K.DIM, font=font(12))
    out = B.out('controls', 'ports.png')
    im.save(out)
    print('wrote', os.path.relpath(out, B.CASE), im.size)


# --- fire: one press, one shot; held 15 passes, a grenade -----------------------------------------------------------

def cmd_fire(args):
    w = args.work
    lo, hi = 300, 420
    frames = list(range(lo, hi + 1))
    held, fire, timer, score = [], [], [], []
    for f in frames:
        held.append(mem(w, f, 0x83DC, 1)[0])
        fire.append(mem(w, f, 0x7B96, 1)[0])
        timer.append(mem(w, f, 0x925A, 1)[0])
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 7.6))
    ax = fig.add_axes([0.07, 0.56, 0.88, 0.33])
    ax.step(frames, held, where='post', color=B.COLOURS[0], label='FireHeld $83DC (passes held)')
    ax.step(frames, timer, where='post', color=B.COLOURS[2], label='GrenadeTimer $925A (the flight)')
    ax.fill_between(frames, 0, [v * 3 for v in fire], step='post', color=B.COLOURS[1], alpha=0.35,
                    label='ControlFire $7B96 (shown as 3 when 1)')
    ax.axhline(15, color=(0.9, 0.3, 0.3), lw=1, ls='--')
    ax.text(lo + 1, 15.6, 'ThrowGrenade threshold: 15', color=(0.95, 0.4, 0.4), fontsize=10.5)
    first15 = next(f for f, v in zip(frames, held) if v >= 15)
    release = next(f for f, v, c in zip(frames, held, fire) if f > first15 and c == 0)
    blast = 411
    for f, t, yy, ha in ((312, 'press: a shot', 30.5, 'left'), (first15, f'f{first15}: FireHeld 15, the throw', 21.5,
                         'left'), (release, f'f{release}: release, FireHeld 0', 7.0, 'left'),
                         (blast, f'f{blast}: the blast, +150', 30.5, 'right')):
        ax.axvline(f, color=B.DIM, lw=0.8)
        ax.text(f + (0.6 if ha == 'left' else -0.6), yy, t, fontsize=10.5, ha=ha)
    ax.set_xlim(lo, hi)
    ax.set_ylim(0, 34)
    ax.set_xlabel('x2 frame')
    ax.set_ylabel('value')
    ax.legend(loc='upper right', bbox_to_anchor=(1.0, 0.82))
    B.suptitle(fig, 'Fire held: the press fires one shot, FireHeld counts the passes, and at 15 ThrowGrenade '
               'throws (x2 frames 300-420)')
    shots = [(312, 'f312: the shot leaves'), (342, 'f342: the throw'), (380, 'f380: the arc'),
             (412, 'f412: the rock blown, 150')]
    for k, (f, t) in enumerate(shots):
        a = fig.add_axes([0.03 + k * 0.245, 0.04, 0.23, 0.40])
        a.imshow(scr(w, f))
        a.set_axis_off()
        a.set_title(t, fontsize=11)
    B.save(fig, B.out('controls', 'fire.png'))


# --- name entry: NameBuffer after each key of d1 --------------------------------------------------------------------

NAME_KEYS = ['E', 'X', 'CAPS', 'O', 'L', 'O', 'N', 'A', 'B', 'C', 'CAPS', 'D', 'ENTER']


def name_frames():
    """the d1 frames of the name keys: from work/ann/exD/d1-inputs.txt, each key's press frame"""
    path = os.path.join(B.WORK, 'ann', 'exD', 'd1-inputs.txt')
    f, out = 0, []
    for ln in open(path):
        ln = ln.strip()
        if not ln or ln.startswith('#'):
            continue
        t, _, keys = ln.partition(' ')
        f = f + int(t[1:]) if t.startswith('+') else int(t)
        if keys in ('E', 'X', 'CS', 'O', 'L', 'N', 'A', 'B', 'C', 'D', 'ENTER'):
            out.append((f, keys))
    return out


def cmd_name(args):
    w = args.work
    keys = name_frames()
    cols, tw, th = 5, 200, 40
    shots = [(keys[0][0] - 10, 'before E')] + [(f + 19, 'CAPS' if k == 'CS' else k) for f, k in keys]
    rows = (len(shots) + cols - 1) // cols
    W = 1050
    gap = (W - cols * tw) // (cols + 1)
    top, cell = 70, 104
    H = top + rows * cell + 40
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((gap, 12), 'The name entry in d1: E X CAPS O L O N A B C CAPS D ENTER gives EOLONABD', fill=K.TEXT,
           font=font(17))
    d.text((gap, 40), 'row 15, columns 11-20 at 2.5x (the field is 12-19), 19 frames after each key; '
                      'under it NameBuffer $A232 (_ = space)', fill=K.DIM, font=font(12))
    for k, (f, key) in enumerate(shots):
        x = gap + (k % cols) * (tw + gap)
        y = top + (k // cols) * cell
        pic = scr(w, f).crop((88, 116, 168, 132)).resize((tw, th), Image.NEAREST)
        d.text((x, y), f'{key}  (frame {f})', fill=K.TEXT, font=font(13))
        im.paste(pic, (x, y + 20))
        nb = mem(w, f, 0xA232, 8).decode('latin-1').replace(' ', '_')
        d.text((x, y + 64), f'NameBuffer {nb}', fill=(240, 220, 120), font=font(13))
    last = shots[-1][0]
    top1 = mem(w, last, 0x71F1, 16).decode('latin-1')
    d.text((gap, H - 30), f'after ENTER (frame {last}): the table\'s first entry at $71F1 reads "{top1}"',
           fill=K.TEXT, font=font(13))
    out = B.out('controls', 'name-entry.png')
    im.save(out)
    print('wrote', os.path.relpath(out, B.CASE), im.size)


# --- define keys: m1 types P O Q A M --------------------------------------------------------------------------------

KEYNAMES = {}


def keyname(row, mask):
    table = B.image()[0xACEF:0xACEF + 40]
    rows = [0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F]
    if row not in rows or mask not in (1, 2, 4, 8, 16):
        return '?'
    c = table[rows.index(row) * 5 + [1, 2, 4, 8, 16].index(mask)]
    return {1: 'CS', 2: 'SS', 13: 'ENT', 32: 'SPC'}.get(c, chr(c))


def tests(m):
    """the five (row, mask) operands of ReadKeyboard from the bytes $7AF0-$7B21"""
    return [(m[10 * k + 2], m[10 * k + 6]) for k in range(5)]


def cmd_define(args):
    w = args.work
    shots = [(180, 'f180: SELECT KEY FOR'), (230, 'f230: P for LEFT'), (290, 'f290: O for RIGHT'),
             (350, 'f350: Q for JUMP'), (410, 'f410: A for DUCK'), (445, 'f445: M for FIRE')]
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 8.4))
    B.suptitle(fig, 'Define keys in m1: each key writes its half-row and mask into one test of ReadKeyboard '
               '(the bytes at $7AF2 + 10n and $7AF6 + 10n)')
    for k, (f, t) in enumerate(shots):
        a = fig.add_axes([0.02 + (k % 3) * 0.33, 0.56 - (k // 3) * 0.45, 0.30, 0.28])
        a.imshow(scr(w, f))
        a.set_axis_off()
        m = mem(w, f, 0x7AF0, 0x32)
        ty = mem(w, f, 0x708B, 5)
        ops = ' '.join(f'${r:02X}/${s:02X}' for r, s in tests(m))
        names = ' '.join(keyname(r, s) for r, s in tests(m))
        a.set_title(t, fontsize=11)
        a.text(0, 1.07 + 0.0, '', transform=a.transAxes)
        a.text(0.0, -0.08, f'tests: {names}', transform=a.transAxes, fontsize=10.5)
        a.text(0.0, -0.17, ops, transform=a.transAxes, fontsize=10)
        a.text(0.0, -0.26, 'TypedKeys ' + ''.join(chr(c) if 32 < c < 127 else '.' for c in ty),
               transform=a.transAxes, fontsize=10.5)
    B.save(fig, B.out('controls', 'define-keys.png'))


# --- the menu: 3, 4, 5 chosen ---------------------------------------------------------------------------------------

def cmd_menu(args):
    w = args.work
    shots = [(660, 'f660: after define keys'), (700, 'f700: 3, the same type'), (790, 'f790: 4, Interface 2'),
             (880, 'f880: 5, Kempston')]
    B.style()
    fig = plt.figure(figsize=(B.WIDTH, 3.6))
    B.suptitle(fig, 'Menu keys 3, 4 and 5 set ControlType $7B97; HighlightControl $6F90 paints the chosen line '
               'bright white (m1)')
    for k, (f, t) in enumerate(shots):
        a = fig.add_axes([0.01 + k * 0.248, 0.04, 0.235, 0.66])
        a.imshow(scr(w, f).crop((0, 48, 256, 168)))
        a.set_axis_off()
        ct = mem(w, f, 0x7B97, 1)[0]
        a.set_title(f'{t}\nControlType {ct}', fontsize=11)
    B.save(fig, B.out('controls', 'menu-choice.png'))


# --- doc 01: the hazards, each cut from a recording -----------------------------------------------------------------

def cmd_hazards(args):
    import json
    spec = json.load(open(args.spec))
    cols, tw, th = 4, 240, 150
    W = 1050
    gap = (W - cols * tw) // (cols + 1)
    top, caph = 66, 66
    rows = (len(spec) + cols - 1) // cols
    H = top + rows * (th + caph + 22) + 6
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((gap, 12), spec_title(args), fill=K.TEXT, font=font(17))
    d.text((gap, 40), 'each picture: a part of the screen at 2x, cut from the recording and frame under it',
           fill=K.DIM, font=font(12))
    for k, s in enumerate(spec):
        x = gap + (k % cols) * (tw + gap)
        y = top + (k // cols) * (th + caph + 22)
        x0, y0 = s['at']
        pic = scr(s['work'], s['frame']).crop((x0, y0, x0 + tw // 2, y0 + th // 2))
        im.paste(B.zoom(pic, 2), (x, y))
        yy = caption_block(d, x, y + th + 4, s['lines'][:1], size=13)
        caption_block(d, x, yy, s['lines'][1:], size=12, fill=K.DIM)
    out = B.out('design', os.path.basename(args.out))
    im.save(out)
    print('wrote', os.path.relpath(out, B.CASE), im.size)


def spec_title(args):
    return args.title


# --- doc 01: the zone end as an animation ---------------------------------------------------------------------------

def cmd_zoneend(args):
    w = args.work
    pics, durs = [], []
    for f in range(args.lo, args.hi + 1, args.step):
        s = scr(w, f)
        sn = mem(w, f, 0x8523, 1)[0]
        lives = mem(w, f, 0x8E7A, 1)[0]
        score = mem(w, f, 0xAD8A, 6).decode('latin-1')
        bp = mem(w, f, 0xA960, 1)[0]
        im = Image.new('RGB', (512, 384 + 60), K.BACKGROUND)
        im.paste(B.zoom(s, 2), (0, 0))
        d = ImageDraw.Draw(im)
        d.text((8, 390), f'w/124 frame {f}   ScreenNumber ${sn:02X} ({sn})   Lives {lives}', fill=K.TEXT,
               font=font(14))
        d.text((8, 412), f'Score {score}   BonusPointer {bp} (line {bp & 7})', fill=K.TEXT, font=font(14))
        pics.append(im)
        durs.append(120)
    durs[-1] = 1500
    out = B.out('design', 'zone-end.gif')
    K.save_gif(out, pics, durs)
    print('wrote', os.path.relpath(out, B.CASE), len(pics), 'pictures')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('what', choices=['ports', 'fire', 'name', 'define', 'menu', 'hazards', 'zoneend'])
    p.add_argument('--work')
    p.add_argument('--spec', help='hazards: a JSON list of {work, frame, at: [x, y], lines: [...]}')
    p.add_argument('--title', default='')
    p.add_argument('--out', default='hazards.png')
    p.add_argument('--lo', type=int, default=600)
    p.add_argument('--hi', type=int, default=1100)
    p.add_argument('--step', type=int, default=4)
    args = p.parse_args()
    globals()['cmd_' + args.what](args)


if __name__ == '__main__':
    main()
