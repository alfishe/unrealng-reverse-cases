#!/usr/bin/env python3
"""Doc 05's figures: the keyboard as the game reads it, the key latch against the pass, the ATV answering the keys.

    python3 tools/fig_controls.py docs/img/controls [work/stage1/rec/turn/log.json]

keymap.png   the 40 keys in the Spectrum's layout, each with its KeyStates index (ScanKeys `$859C`: row x 5 + bit),
             the default keys of player 1 (KeyIndexes1 `$8109`: S D F C Z), of player 2 (KeyIndexes2 `$810E`: H J K
             M B), the Sinclair keys (6 7 9 8 0, fixed in P1Left-P2Jump), the four keys ReadNewKey `$7542` refuses
             (KeyChars `$80B3` holds `_` for them) and key 1, the one AbortKey `$DA01` reads.
latch.png    when the keys are scanned, read and cleared, from traces of recordings turn (one player, frames
             736-751) and kb (two players, frames 702-716). The times are the entries of ScanKeys, Pass `$D851`,
             ReadP1Controls `$D911`, ClearKeys `$858A` and Controls `$E105` in those traces (work/docs/atB/tr.py
             WORK F:T-F:T Label ...); they are written into TIMES below.
speed.png    recording turn (tools/rec_controls.py): Speed, Facing, TrackPos and the score sampled every 7 frames
             (log.json), with the keys held.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

CASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

W = 1050
FRAME_T = 69888

# The keyboard as ScanKeys reads it: half-row r (port $FEFE rotated left r times), bit b, index r * 5 + b
ROWS = [('CAPS', 'Z', 'X', 'C', 'V'), ('A', 'S', 'D', 'F', 'G'), ('Q', 'W', 'E', 'R', 'T'), ('1', '2', '3', '4', '5'),
        ('0', '9', '8', '7', '6'), ('P', 'O', 'I', 'U', 'Y'), ('ENTER', 'L', 'K', 'J', 'H'),
        ('SPACE', 'SYM', 'M', 'N', 'B')]
INDEX = {k: r * 5 + b for r, row in enumerate(ROWS) for b, k in enumerate(row)}
LAYOUT = ['1234567890', 'QWERTYUIOP', ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
          ['CAPS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SYM', 'SPACE']]
P1 = {'S': 'left', 'D': 'right', 'F': 'up', 'C': 'down', 'Z': 'jump'}
P2 = {'H': 'left', 'J': 'right', 'K': 'up', 'M': 'down', 'B': 'jump'}
SINCLAIR = {'6': 'left', '7': 'right', '9': 'up', '8': 'down', '0': 'fire'}
REFUSED = {'CAPS', 'SYM', 'ENTER', 'SPACE'}
C_P1, C_P2, C_SIN, C_REF, C_ABORT = (230, 90, 80), (90, 200, 220), (240, 200, 70), (120, 120, 135), (200, 110, 230)


def keymap(path):
    big, mid, small = K.font(15), K.font(13), K.font(11)
    H = 520
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The keyboard as ATV Simulator reads it: KeyStates index = half-row x 5 + bit',
           fill=K.TEXT, font=big)
    kw, kh, gap, x0, y0 = 88, 70, 8, 14, 46
    for r, row in enumerate(LAYOUT):
        for c, key in enumerate(row):
            x, y = x0 + c * (kw + gap) + r * 12, y0 + r * (kh + gap)
            colour, role = K.PANEL, ''
            if key in P1:
                colour, role = (90, 40, 40), 'P1 ' + P1[key]
            if key in P2:
                colour, role = (30, 70, 80), 'P2 ' + P2[key]
            if key in SINCLAIR:
                colour, role = (80, 70, 25), 'Sinc ' + SINCLAIR[key]
            if key in REFUSED:
                colour, role = (40, 40, 48), 'refused'
            d.rounded_rectangle((x, y, x + kw, y + kh), 8, fill=colour, outline=(70, 70, 85))
            d.text((x + 8, y + 6), key, fill=K.TEXT, font=big)
            d.text((x + kw - 30, y + 6), f'{INDEX[key]:2d}', fill=(170, 170, 185), font=small)
            if key == 'M':
                role = 'P2 down'
            if role:
                d.text((x + 8, y + 32), role, fill=(235, 235, 240), font=small)
            if key == '1':
                d.text((x + 8, y + 48), 'AbortKey', fill=C_ABORT, font=small)
    y = y0 + 4 * (kh + gap) + 14
    lines = [
        (C_P1, 'player 1 keyboard (KeyIndexes1 $8109 = 6 7 8 3 1): S left, D right, F up, C down, Z jump'),
        (C_P2, 'player 2 keyboard (KeyIndexes2 $810E = 34 33 32 37 39): H left, J right, K up, M down, B jump'),
        (C_SIN, 'Sinclair (fixed in P1Left-P2Jump): 6 left (24), 7 right (23), 9 up (21), 8 down (22), 0 fire (20)'),
        (C_REF, 'refused by ReadNewKey $7542 (KeyChars holds "_"): CAPS 0, ENTER 30, SPACE 35, SYMBOL SHIFT 36'),
        (C_ABORT, 'AbortKey $DA01 reads KeyStates+15: key 1 (no path reaches it)'),
    ]
    for colour, text in lines:
        d.rectangle((22, y + 3, 36, y + 15), fill=colour)
        d.text((46, y), text, fill=K.TEXT, font=mid)
        y += 22
    d.text((22, y + 6), 'Kempston (port 31, JoyBits $8089): bit 0 right, 1 left, 2 down, 3 up, 4 fire',
           fill=K.TEXT, font=mid)
    im.save(path)


# Entries in the traces (frame, T in the frame). turn: window 733:0-751:69888; kb: 702:0-716:0
TIMES = {
    'turn': {'title': 'one player (turn, frames 736-751): a pass is 7 frames',
             'frames': (736, 751), 'pass': [(736, 9550), (743, 9356), (750, 9208)],
             'clear': [(736, 10925), (740, 46121), (743, 10731), (748, 23945), (750, 10583)],
             'controls': [(737, 35974), (744, 67486)], 'scan_t': 2000},
    'kb': {'title': 'two players (kb, frames 702-716): a pass is 12 frames here, the work does not fit in 7',
           'frames': (702, 716), 'pass': [(702, 68897), (715, 17191)],
           'clear': [(703, 1124), (708, 30009), (715, 19239)],
           'controls': [(704, 64325), (711, 23139)], 'scan_t': 2000},
}


def latch(path):
    big, mid, small = K.font(15), K.font(13), K.font(11)
    H = 560
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The key latch: ScanKeys sets bits each frame, ClearKeys drops them twice a pass, Pass reads them',
           fill=K.TEXT, font=big)
    y = 50
    for name in ('turn', 'kb'):
        s = TIMES[name]
        f0, f1 = s['frames']
        x0, x1 = 60, W - 20
        scale = (x1 - x0) / ((f1 - f0) * FRAME_T)

        def X(f, t):
            return x0 + ((f - f0) * FRAME_T + t) * scale
        d.text((14, y), s['title'], fill=K.TEXT, font=mid)
        top = y + 26
        # frames
        for f in range(f0, f1 + 1):
            d.line((X(f, 0), top, X(f, 0), top + 150), fill=(50, 50, 62))
            if f < f1:
                d.text((X(f, 0) + 4, top + 152), str(f), fill=K.DIM, font=small)
        # which scans feed which read: a scan between the last ClearKeys and the read is kept
        reads = s['pass']
        clears = sorted(s['clear'])
        for f in range(f0, f1):
            t = s['scan_t']
            moment = (f, t)
            nxt = [r for r in reads if r > moment]
            kept = False
            if nxt:
                rd = nxt[0]
                kept = not any(moment < c < rd for c in clears)
            colour = (80, 230, 110) if kept else (175, 45, 65)
            d.rectangle((X(f, t) - 4, top + 10, X(f, t) + 4, top + 40), fill=colour)
        d.text((x0 - 50, top + 18), 'scan', fill=K.TEXT, font=small)
        for f, t in reads:
            d.polygon([(X(f, t), top + 50), (X(f, t) - 7, top + 66), (X(f, t) + 7, top + 66)], fill=(90, 150, 250))
        d.text((x0 - 50, top + 52), 'read', fill=K.TEXT, font=small)
        for f, t in clears:
            d.line((X(f, t), top + 74, X(f, t), top + 104), fill=(240, 200, 70), width=3)
        d.text((x0 - 50, top + 82), 'clear', fill=K.TEXT, font=small)
        for f, t in s['controls']:
            d.ellipse((X(f, t) - 6, top + 114, X(f, t) + 6, top + 126), fill=(200, 110, 230))
        d.text((x0 - 56, top + 112), 'Controls', fill=K.TEXT, font=small)
        y = top + 180
    legend = [((80, 230, 110), 'a scan whose keys reach the next read'),
              ((175, 45, 65), 'a scan cleared before any read: a key held only then is lost'),
              ((90, 150, 250), 'Pass: ReadP1Controls / ReadP2Controls build Controls1 / Controls2'),
              ((240, 200, 70), 'ClearKeys: in Pass after the read, and in PassP1 after player 1\'s Update'),
              ((200, 110, 230), 'Controls $E105 acts on the byte read at the pass start')]
    for colour, text in legend:
        d.rectangle((22, y + 3, 36, y + 15), fill=colour)
        d.text((46, y), text, fill=K.TEXT, font=mid)
        y += 20
    im.save(path)


def speed(path, log_path):
    log = json.load(open(log_path))
    big, mid, small = K.font(15), K.font(13), K.font(11)
    H = 600
    im = Image.new('RGB', (W, H), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    d.text((14, 10), 'The ATV answering the keys (recording turn, sampled every 7 frames)', fill=K.TEXT, font=big)
    rows = [v for v in log if v['frame_no'] >= 580]
    f0, f1 = rows[0]['frame_no'], rows[-1]['frame_no']
    x0, x1 = 110, W - 20

    def X(f):
        return x0 + (f - f0) * (x1 - x0) / (f1 - f0)
    # keys strip
    top = 44
    colours = {'KR': (230, 90, 80), 'KL': (90, 150, 250), 'KU': (240, 200, 70), 'KD': (200, 110, 230),
               'KF': (80, 230, 110)}
    for i, key in enumerate(['KR', 'KL', 'KU', 'KD', 'KF']):
        yy = top + i * 14
        d.text((14, yy - 2), {'KR': 'right', 'KL': 'left', 'KU': 'up', 'KD': 'down', 'KF': 'fire'}[key],
               fill=K.TEXT, font=small)
        for a, b in zip(rows, rows[1:]):
            if key in b['held'].split('+'):
                d.rectangle((X(a['frame_no']), yy, X(b['frame_no']), yy + 10), fill=colours[key])
    # speed panel
    def panel(top, height, field, lo, hi, label, colour, step=None):
        d.rectangle((x0, top, x1, top + height), outline=(60, 60, 72))
        d.text((10, top + height / 2 - 7), label, fill=K.TEXT, font=small)
        for v in (lo, hi):
            yy = top + height - (v - lo) * height / (hi - lo)
            d.text((x0 - 30, yy - 7), str(v), fill=K.DIM, font=small)
        pts = [(X(v['frame_no']), top + height - (field(v) - lo) * height / (hi - lo)) for v in rows]
        d.line(pts, fill=colour, width=2)
    panel(130, 120, lambda v: v['speed'], 0, 21, 'Speed', (230, 90, 80))
    panel(270, 30, lambda v: v['facing'], 0, 1, 'Facing', (90, 150, 250))
    panel(320, 120, lambda v: v['track'], 0, 600, 'TrackPos', (80, 230, 110))
    panel(460, 80, lambda v: int(v['score']), 0, 400, 'score', (240, 200, 70))
    # events
    marks = [(684, 'on the ATV'), (1174, 'turned: frame $5C'), (1489, 'turned back')]
    for f, text in marks:
        d.line((X(f), 120, X(f), 545), fill=(150, 150, 165))
        d.text((X(f) + 4, 548), text, fill=K.TEXT, font=small)
    for f in range(600, f1 + 1, 100):
        d.text((X(f) - 12, 570), str(f), fill=K.DIM, font=small)
    d.text((x1 - 60, 584), 'frame', fill=K.DIM, font=small)
    im.save(path)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    keymap(os.path.join(out, 'keymap.png'))
    latch(os.path.join(out, 'latch.png'))
    log = sys.argv[2] if len(sys.argv) > 2 else os.path.join(CASE, 'work/stage1/rec/turn/log.json')
    speed(os.path.join(out, 'speed.png'), log)


if __name__ == '__main__':
    main()
