#!/usr/bin/env python3
"""PlayTune `$88CE` and the ROM's BEEPER `$03B5` as a T-state model (doc 09): the speaker writes of a tune from its
bytes, without an emulator. Every instruction's T-states are the Z80's uncontended ones; the code runs at
`$88CE-$895C` and in the ROM, neither contended, so only the `OUT` itself can wait (the ULA port, in the display).

    from tune_model import play_tune, beeper
    writes, total = play_tune(tune_bytes, periods)   # [(t, value)], T-states from PlayTune's DI to its EI

    python3 tools/tune_model.py check work/docs/esD/ev-rzx01-400-700.json CaveTune1
          the model against a traced run: every speaker write's interval, side by side
    python3 tools/tune_model.py table      every tune: notes, length in T-states, frames and seconds
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
RES = os.path.join(CASE, 'build', 'res', 'music')
CLOCK, FT = 3_500_000, 69_888

TUNES = {  # name: (file, address, player routine)
    'TitleTune': ('title', 0xAD00, 'PlayTitleTune $8A35'),
    'CaveTune1': ('cave-1', 0xBB80, 'PlayCaveTune $EE34, caves 1-4'),
    'CaveTune2': ('cave-2', 0xF100, 'caves 5-8'),
    'CaveTune3': ('cave-3', 0xF1D0, 'caves 9-12'),
    'CaveTune4': ('cave-4', 0xF212, 'caves 13-16'),
    'CaveTune5': ('cave-5', 0xF302, 'caves 17-20'),
    'CaveTune6': ('cave-6', 0xF398, 'caves 21-24'),
    'CaveTune7': ('cave-7', 0xF298, 'caves 25-28'),
    'CaveTune8': ('cave-8', 0xF152, 'caves 29-32'),
    'MapTune': ('map', 0xE8E8, 'PlayMapTune $E8E1'),
    'LifeTune': ('life', 0xAC5F, 'PotionTune $91C1'),
    'GameOverTune': ('game-over', 0xAA00, 'PlayGameOverTune $8B78'),
    'WinTune': ('win', 0x6EF4, 'PlayWinTune $A615'),
}


def periods():
    b = open(os.path.join(RES, 'periods.bin'), 'rb').read()
    return [b[2 * i] << 8 | b[2 * i + 1] for i in range(len(b) // 2)]


def tune(name):
    return open(os.path.join(RES, TUNES[name][0] + '.bin'), 'rb').read()


def notes(data):
    """[(drum, n1, n2, length)] up to the end record (n1 = $FF)"""
    out = []
    i = 0
    while i + 1 < len(data):
        drum, n1 = data[i], data[i + 1]
        if n1 == 0xFF:
            break
        out.append((drum, n1, data[i + 2], data[i + 3]))
        i += 4
    return out


def beeper(t, hl, de):
    """ROM BEEPER $03B5 from its CALL at t: ([(t, value)], t at the RET's end). The ROM listing's loop:
    a half period is the delay loop (H + 1 turns of the outer loop, the inner one starting at (L >> 2) + 1 or + 2)
    plus the branch of the half; 2 x (DE + 1) writes; the border is 0 here, so the values are $18 and $08."""
    h, l = hl >> 8, hl & 0xFF
    w = []
    a = 0x08
    # entry: CALL 17, DI 4, LD A,L 4, SRL L 8 x 2, CPL 4, AND 7, LD C,A 4, LD B,0 7, LD IX 14, ADD IX,BC 15,
    # LD A,(BORDCR) 13, AND 7, RRCA x 3 12, OR 8 7
    t += 17 + 4 + 4 + 16 + 4 + 7 + 4 + 7 + 14 + 15 + 13 + 7 + 12 + 7
    nops = l & 3
    c = ((~l) & 3) + 1      # the first half: C = (~L AND 3), B = 0, then INC B / INC C at IX
    b = 1
    lq = l >> 2

    def delay(c, b):
        # NOPs, INC B 4, INC C 4, inner C turns (16 each, 11 the last), LD C,$3F 7, DEC B 4, JP NZ 10,
        # then (b - 1) more outer turns of 63 inner turns
        return 4 * nops + 8 + (16 * c - 5) + 21 + (b - 1) * (62 * 16 + 11 + 21)

    t += delay(c, b) + 7          # XOR $10
    while True:
        a ^= 0x10
        w.append((t + 11, a))     # the OUT's write, at its end (the model's convention)
        t += 11
        if a & 0x10:              # high: LD B,H; LD C,A; BIT 4,A; JR NZ (taken); LD C,L; INC C; JP (IX)
            t += 4 + 4 + 8 + 12 + 4 + 4 + 8
            t += delay(lq + 1 + 1, h + 1) + 7
        else:                     # low: ... JR NZ (not taken); LD A,D; OR E; JR Z
            t += 4 + 4 + 8 + 7 + 4 + 4
            if de == 0:
                t += 12 + 4 + 10  # JR Z taken, EI, RET
                return w, t
            t += 7 + 4 + 4 + 6 + 8  # JR Z not taken, LD A,C, LD C,L, DEC DE, JP (IX)
            de -= 1
            t += delay(lq + 1, h + 1) + 7


def play_tune(data, per=None, key_stop=None):
    """PlayTune from its DI: ([(t, value)], [(t, event)], t at TuneEnds' RET). key_stop is ignored (no key)."""
    per = per or periods()
    w, ev = [], []
    t = 4  # DI
    i = 0
    while True:
        drum = data[i]
        i += 1
        t += 7 + 6 + 7  # LD A,(HL); INC HL; CP $01
        if drum == 1:
            t += 7 + 44 + 10 + 10
            ev.append((t, 'drum1'))
            bw, t = beeper(t, 0x020B, 3)
            w += bw
            t += 4 + 40  # DI, POP x 4
        else:
            t += 12
        t += 7  # CP $02
        if drum == 2:
            t += 7 + 44 + 10 + 10
            ev.append((t, 'drum2'))
            bw, t = beeper(t, 0x0106, 5)
            w += bw
            t += 4 + 40
        else:
            t += 12
        t += 7 + 11 + 11 + 7 + 7 + 7 + 7 + 7  # LD A,$F7; OUT; IN; AND; CP; JR NZ (no key); LD A,(HL); CP $FF
        n1 = data[i]
        if n1 == 0xFF:
            t += 7 + 4 + 10  # JR NZ not taken, EI, RET
            return w, ev, t
        t += 12
        n2, length = data[i + 1], data[i + 2]
        p1, p2 = per[(2 * n1 & 0xFF) >> 1] if n1 < 128 else per[n1 & 0x7F], per[n2]
        # PlayNote's set-up: up to ToneLoop
        t += 11 + 4 + 4 + 7 + 7 + 6 + 7 + 11 + 14 + 10 + 7 + 6 + 12 + 10 + 11 + 7 + 4 + 4 + 7 + 7 + 6 + 7 + 11 + 14
        t += 10 + 6 + 11 + 7 + 7
        ev.append((t, f'note {n1} {n2} {length}'))
        de, ix, bc, iy = p1, (p1 - 1) & 0xFFFF, p2, p2
        hl = (length << 8) or 0x10000
        # ToneLoop: closed form per turn would be faster; turns are walked counter by counter
        turns = hl
        k = 0
        while k < turns:
            # the next turn in which DE or BC reaches 0
            step = min(de, bc, turns - k)
            if step > 1:
                # step - 1 quiet turns
                t += 78 * (step - 1)
                de -= step - 1
                bc -= step - 1
                k += step - 1
            # one turn
            de = (de - 1) & 0xFFFF
            t += 6 + 4 + 4
            if de == 0:
                t += 7 + 4
                w.append((t + 11, 0x00))
                t += 11 + 7
                w.append((t + 11, 0x10))
                t += 11 + 15 + 10
                de = ix
            else:
                t += 12
            bc = (bc - 1) & 0xFFFF
            t += 6 + 4 + 4
            if bc == 0:
                t += 7 + 7
                w.append((t + 11, 0x10))
                t += 11 + 4
                w.append((t + 11, 0x00))
                t += 11 + 15 + 10
                bc = iy
            else:
                t += 12
            t += 6 + 4 + 4 + 12  # DEC HL; LD A,H; OR L; JR NZ
            k += 1
        t -= 5  # the last JR NZ falls through
        t += 10 + 6 + 10  # POP HL; INC HL; JP NoteLoop
        i += 3


def check(path, name):
    d = json.load(open(path))
    call = [c for c in d['calls'] if c[2] == 'PlayTune'][0]
    t0 = call[0] * FT + call[1]
    tr = [((f * FT + t) - t0, v & 0x10) for f, t, v, pc in d['out_fe'] if (f * FT + t) >= t0]
    mw, ev, total = play_tune(tune(name))
    mw = [(t, v & 0x10) for t, v in mw]
    n = min(len(tr), len(mw))
    gaps_t = [tr[i + 1][0] - tr[i][0] for i in range(n - 1)]
    gaps_m = [mw[i + 1][0] - mw[i][0] for i in range(n - 1)]
    diff = [a - b for a, b in zip(gaps_t, gaps_m)]
    same_v = sum(1 for i in range(n) if tr[i][1] == mw[i][1])
    print(f'{name}: traced {len(tr)} writes, model {len(mw)}; values equal in {same_v} of {n}')
    print(f'interval difference (trace - model): min {min(diff)}, max {max(diff)}, '
          f'exact {sum(1 for x in diff if x == 0)} of {len(diff)}, total {sum(diff)} T')
    print(f'span: traced {tr[n - 1][0] - tr[0][0]} T, model {mw[n - 1][0] - mw[0][0]} T')
    ends = [c for c in d['calls'] if c[2] == 'PlayTune']
    return diff


def table():
    per = periods()
    print('tune address bytes notes T frames seconds drums')
    for name, (f, a, who) in TUNES.items():
        data = tune(name)
        ns = notes(data)
        w, ev, total = play_tune(data, per)
        print(name, f'${a:04X}', len(data), len(ns), total, round(total / FT, 1), round(total / CLOCK, 2),
              sum(1 for n in ns if n[0] in (1, 2)))


if __name__ == '__main__':
    if sys.argv[1] == 'check':
        check(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == 'table':
        table()
