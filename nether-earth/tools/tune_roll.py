#!/usr/bin/env python3
"""The menu tune of Nether Earth from its track data (docs/09-sound.md): a model of MenuMusic / MenuInterrupt that
plays the bass ($C678), lead ($C702) and drum ($C665) tracks frame by frame, a piano roll of it, and a check of the
model against a recording.

    python3 tune_roll.py roll docs/img/sound-menu-tune.png      the piano roll of one pass, with a zoom on its start
    python3 tune_roll.py events                                 the model's events as text
    python3 tune_roll.py verify --work work/docC/rec --from 0 --to 400
                                                                the model against the operands the player wrote,
                                                                read with TTD memory_at at every frame

The model follows the code: at each interrupt the drum's frame count C, then the bass's C', then the lead's B' are
decremented; one that reaches 0 reads its track's next record. A voice record is a note (period >= 9, frames) or a
command (1 aa goto, 2 aa call a pattern, 3 aa the drum track, 4 on, 5 off, 6 return). A drum record is
(frames, kind[, p]) or 1 aa (goto). All counts start at 1, so the first interrupt reads the first record of each.
The pitch of a period p is about 3.5 MHz / (125.5 * p): a tone-loop turn is about 122 T and the pulse of each
period adds 14 * p / 4 T.
"""
import argparse
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = 0x5B00
BASS, LEAD, DRUM = 0xC678, 0xC702, 0xC665
CLOCK = 3500000
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def image():
    data = open(os.path.join(HERE, '..', 'build', 'game.bin'), 'rb').read()
    return bytes(BASE) + data + bytes(0x10000 - BASE - len(data))


def hz(period):
    return CLOCK / (125.5 * period)


def note_name(period):
    """The note relative to period $7C taken as A3 (the tune's intervals are equal-tempered within a few cents; its
    absolute pitch by the T-state count lies about 40 cents above), and the offset in cents"""
    m = 57 + 12 * math.log2(0x7C / period)
    n = round(m)
    return f'{NAMES[n % 12]}{n // 12 - 1}', round(100 * (m - n))


class Voice:
    def __init__(self, mem, start):
        self.mem, self.pos, self.ret = mem, start, None
        self.count, self.period, self.on = 1, 0, True
        self.gotos = []

    def word(self, a):
        return self.mem[a] | self.mem[a + 1] << 8

    def next(self, frame, drum):
        """Read records until a note: (period, frames)"""
        m = self.mem
        while True:
            b = m[self.pos]
            if b >= 9:
                self.period, self.count = b, m[self.pos + 1]
                self.pos += 2
                return
            if b == 1:
                self.gotos.append(frame)
                self.pos = self.word(self.pos + 1)
            elif b == 2:
                self.ret = self.pos + 3
                self.pos = self.word(self.pos + 1)
            elif b in (3, 7, 8):
                drum.pos = self.word(self.pos + 1)
                self.pos += 3
            elif b == 4:
                self.on, self.pos = True, self.pos + 1
            elif b == 5:
                self.on, self.pos = False, self.pos + 1
            elif b == 6:
                self.pos = self.ret
            else:
                raise SystemExit(f'command 0 at ${self.pos:04X}')


class Drum:
    def __init__(self, mem, start):
        self.mem, self.pos, self.count = mem, start, 1

    def next(self):
        m = self.mem
        while m[self.pos] == 1:
            self.pos = m[self.pos + 1] | m[self.pos + 2] << 8
        self.count, kind = m[self.pos], m[self.pos + 1]
        self.pos += 2
        if kind == 2:
            p = m[self.pos]
            self.pos += 1
            return ('sweep', p)
        return ('hiss', 0) if kind == 0 else ('rasp', kind)


def notes(states, voice):
    """[(start, length, period)] of the sounding notes of voice 0 (bass) or 1 (lead)"""
    out, cur = [], None
    for f, s in enumerate(states):
        period, on = s[voice]
        key = (period, on)
        if cur and cur[2] == key and not restart(states, f, voice):
            cur[1] += 1
            continue
        if cur and cur[2][1]:
            out.append((cur[0], cur[1], cur[2][0]))
        cur = [f, 1, key]
    if cur and cur[2][1]:
        out.append((cur[0], cur[1], cur[2][0]))
    return out


RESTARTS = {}


def restart(states, f, voice):
    return f in RESTARTS.get(voice, ())


def model(frames, bass_on=True, lead_on=True):
    """states and the note starts (a record read restarts a note even at the same period). MenuMusic does not reset
    the voices' on / off operands ($C4EF, $C4D2): the image has both on, a restart keeps what the last run left"""
    mem = image()
    bass, lead, drum = Voice(mem, BASS), Voice(mem, LEAD), Drum(mem, DRUM)
    bass.on, lead.on = bass_on, lead_on
    states, starts = [], {0: set(), 1: set()}
    for f in range(frames):
        hit = None
        drum.count -= 1
        if drum.count == 0:
            hit = drum.next()
        bass.count -= 1
        if bass.count == 0:
            bass.next(f, drum)
            starts[0].add(f)
        lead.count -= 1
        if lead.count == 0:
            lead.next(f, drum)
            starts[1].add(f)
        states.append(((bass.period, bass.on), (lead.period, lead.on), hit))
    RESTARTS.update(starts)
    return states, bass, lead


def roll(out):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams['text.parse_math'] = False
    states, bass, lead = model(5200)
    length = bass.gotos[0] if bass.gotos else 5120
    states = states[:length]
    periods = sorted({p for s in states for p in (s[0][0], s[1][0]) if p})
    fig, axes = plt.subplots(2, 1, figsize=(13, 8.2), dpi=100, gridspec_kw={'height_ratios': [1, 1]})
    colours = {0: '#d07010', 1: '#1070d0'}
    names = {0: 'bass ($C678)', 1: 'lead ($C702)'}
    for ax, (lo, hi), title in ((axes[0], (0, length), f'one pass of the tune: {length} frames ({length / 50:.1f} s)'),
                                (axes[1], (0, 768), 'the first 768 frames')):
        for v in (0, 1):
            for start, n, p in notes(states, v):
                if start + n < lo or start > hi:
                    continue
                y = 12 * math.log2(hz(p) / 440)
                ax.add_patch(plt.Rectangle((start, y - 0.4), n - (0.6 if hi < 1000 else 0), 0.8, color=colours[v],
                                           lw=0))
        for f, s in enumerate(states):
            if s[2] and lo <= f <= hi:
                kind = s[2][0]
                ax.plot(f, -21.5, marker={'hiss': '|', 'rasp': 'x', 'sweep': 'v'}[kind], color='#606060',
                        ms=6 if hi < 1000 else 4)
        ys = [12 * math.log2(hz(p) / 440) for p in periods]
        ax.set_yticks(ys + [-21.5])
        ax.set_yticklabels([f'${p:02X} {note_name(p)[0]}' for p in periods] + ['drum'], fontsize=7)
        ax.set_xlim(lo, hi)
        ax.set_ylim(-23, max(ys) + 1)
        ax.grid(axis='x', alpha=0.25)
        ax.set_title(title, fontsize=10)
        ax.set_xlabel('frame (50 a second)')
    for v in (0, 1):
        axes[0].plot([], [], color=colours[v], lw=6, label=names[v])
    for kind, mk in (('hiss (kind 0)', '|'), ('rasp (kind 1)', 'x'), ('falling sweep (kind 2)', 'v')):
        axes[0].plot([], [], marker=mk, color='#606060', ls='', label=f'drum: {kind}')
    fig.legend(*axes[0].get_legend_handles_labels(), loc='upper center', fontsize=8, ncol=5, frameon=False)
    fig.tight_layout(rect=(0, 0, 1, 0.965))
    fig.savefig(out)


def events():
    states, bass, lead = model(5200)
    print('bass gotos at', bass.gotos, 'lead gotos at', lead.gotos)
    for v in (0, 1):
        ns = notes(states, v)
        print(['bass', 'lead'][v], len(ns), 'sounding notes, periods', sorted({p for _, _, p in ns}))
    drums = [(f, s[2]) for f, s in enumerate(states[:bass.gotos[0]]) if s[2]]
    print('drum hits', len(drums), {k: sum(1 for _, d in drums if d[0] == k) for k in ('hiss', 'rasp', 'sweep')})
    for p in sorted({s[v][0] for s in states for v in (0, 1) if s[v][0]}):
        print(f'${p:02X} {hz(p):6.1f} Hz {note_name(p)}')


def verify(args):
    """Read the operands the player writes ($C4D0 lead period, $C4D2 lead on, $C4ED bass period, $C4EF bass on) at
    the start of every frame and find the model's frame that agrees for the whole stretch"""
    sys.path.insert(0, os.path.join(HERE, '..', '..', 'kit'))
    import kitlib as K
    sys.path.insert(0, os.path.join(K.unreal_root(args.unreal), 'tools', 'verification', 'mcp'))
    import mcplib
    state = json.load(open(os.path.join(args.work, 'session.json')))
    s = mcplib.Session(f"http://127.0.0.1:{state['port_base'] + 200}/mcp", state['model'])
    seen = []
    for f in range(args.first, args.to):
        r = s.call('time_travel', {'action': 'memory_at', 'space': 'cpu', 'frame': f, 'tinframe': 0,
                                   'offset': 0xC4D0, 'length': 0x20}, ok=False)
        b = bytes.fromhex(r.structured['hex'])
        seen.append(((b[0x1D], b[0x1F] == 0x18), (b[0], b[2] == 0x18)))
    states, _, _ = model(5200 + len(seen), args.bass_on, args.lead_on)
    # the state the interrupt leaves in frame k is in memory at the start of frame k + 1
    best, full = None, []
    for off in range(5120):
        same = sum(1 for i, x in enumerate(seen) if (states[off + i][0], states[off + i][1]) == x)
        if same == len(seen):
            full.append(off)
        if not best or same > best[1]:
            best = (off, same)
    print('model offsets that agree everywhere:', full)
    print(f'frames {args.first}-{args.to - 1}: {len(seen)} samples; best model offset {best[0]}: '
          f'{best[1]} of {len(seen)} agree')
    first_bad = [args.first + i for i, x in enumerate(seen) if (states[best[0] + i][0], states[best[0] + i][1]) != x]
    print('disagree at', first_bad[:20])


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    sub = p.add_subparsers(dest='command', required=True)
    r = sub.add_parser('roll')
    r.add_argument('out')
    sub.add_parser('events')
    v = sub.add_parser('verify')
    v.add_argument('--work', required=True)
    v.add_argument('--from', dest='first', type=int, default=0)
    v.add_argument('--to', type=int, default=400)
    v.add_argument('--bass-on', type=int, default=1, help='the bass on / off operand MenuMusic starts with')
    v.add_argument('--lead-on', type=int, default=1)
    v.add_argument('--unreal')
    args = p.parse_args()
    if args.command == 'roll':
        roll(args.out)
    elif args.command == 'events':
        events()
    else:
        verify(args)


if __name__ == '__main__':
    main()
