#!/usr/bin/env python3
"""The figures of docs/09-sound.md: the General Sound side of the game, drawn from the module, the effect files,
the card's own renders and the host / card port histories of the recordings (docs/09-sound.md names each command).

    python3 tools/fig_sound.py module    --out docs/img/sound/module.png
    python3 tools/fig_sound.py effects   --renders work/gsB/audio --out docs/img/sound/effects.png
    python3 tools/fig_sound.py handshake --disk work/gsB/rD/zxbus.jsonl --disk-frame 266 \
                                         --tape work/gsB/rT/exp-zxbus.jsonl --out docs/img/sound/handshake.png
    python3 tools/fig_sound.py plays     --plays work/gsB/an/rT-plays.json --out docs/img/sound/plays.png
    python3 tools/fig_sound.py rreg      --rvalues work/gsB/an/r-values.json --out docs/img/sound/r-register.png

Inputs:
- the module `src/res/music/desert-dream.mod` and the effects `src/res/sfx/*.wav` (the files on the media);
- `--renders`: the card's output for each effect at note 47 (`gs-fx47-NN.wav`, gs_session.py `audiogs`, the card
  alone, after `#2E` n, data 47 + `#40`, data n + `#39` sent from the host: what Hood's driver sends);
- `--disk` / `--tape`: `zxbus.1` history streams (both sides of the card's ports, the card's clock in `timestamp`,
  12 MHz ticks);
- `--plays`: `tools/gs_ports.py plays --json` over a `zxbus.1.ports` stream;
- `--rvalues`: the R values the driver read at `LD A,R`, from access traces (`tools/gs_rreg.py`).
"""
import argparse
import json
import os
import struct
import wave

import matplotlib
import matplotlib.ticker
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#8a8c99'
GREEN, BLUE, YELLOW, RED, ORANGE, VIOLET = '#4caf50', '#5c8fd6', '#e0c341', '#e5534b', '#e08a3c', '#a77bd6'
GS_HZ = 12_000_000          # the card's clock (the history's timestamp unit)
HOST_HZ = 3_500_000         # Pentagon 128

# The driver's table (src/disk/driver.asm, src/tape/driver.asm): effect -> the game event that plays it
EFFECT_EVENT = {
    1: 'id 1 / $C8: a robot leaves the factory', 2: 'id 2: a robot destroyed (R $A1-$FF: never)',
    3: 'id 2: a robot destroyed (R $00-$50)', 4: 'id 2: a robot destroyed (R $51-$A0)',
    5: 'id 3: the construction menu opens', 6: 'id 4: a shot fired (R $00-$50)', 7: 'id 4: a shot fired (R $51-$A0)',
    8: 'id 4: a shot fired (R $A1-$FF: never)', 9: 'id $78: a menu choice', 10: 'id $14: a cursor step',
    11: 'id $64: a list choice, a part paid', 12: 'id $50: START ROBOT', 13: 'id $0A: a shot ends (miss or hit)',
    14: 'id 9: a nuclear blast'}
EFFECT_EVENT = {k: v.replace('$', r'\$') for k, v in EFFECT_EVENT.items()}  # an address, not mathematics
EFFECT_FILE = {1: 'neart007', 2: 'neart008', 3: 'neart009', 4: 'neart010', 5: 'neart011', 6: 'neart012',
               7: 'neart013', 8: 'neart014', 9: 'neart015', 10: 'neart016', 11: 'neart017', 12: 'neart018',
               13: 'neart023', 14: 'neart019+020'}


def style(fig, axes):
    fig.patch.set_facecolor(BG)
    for a in axes:
        a.set_facecolor(AX)
        a.tick_params(colors=FG, labelsize=9)
        for s in a.spines.values():
            s.set_color(DIM)
        a.xaxis.label.set_color(FG)
        a.yaxis.label.set_color(FG)
        a.title.set_color(FG)


def save(fig, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    fig.savefig(out, facecolor=fig.get_facecolor(), dpi=100)
    print('wrote', out)


# --- the module ------------------------------------------------------------------------------------------------

def read_mod(path):
    d = open(path, 'rb').read()
    samples = []
    for i in range(31):
        o = 20 + 30 * i
        samples.append({'n': i + 1, 'name': d[o:o + 22].split(b'\0')[0].decode('latin-1'),
                        'len': struct.unpack('>H', d[o + 22:o + 24])[0] * 2, 'vol': d[o + 25],
                        'rep': struct.unpack('>H', d[o + 26:o + 28])[0] * 2,
                        'replen': struct.unpack('>H', d[o + 28:o + 30])[0] * 2})
    npos = d[950]
    order = list(d[952:952 + npos])
    return d, d[:20].split(b'\0')[0].decode('latin-1'), samples, d[951], order


def mod_cell(d, pattern, row, ch):
    b = d[1084 + pattern * 1024 + row * 16 + ch * 4:][:4]
    return (b[0] & 0xF0) | (b[2] >> 4), ((b[0] & 15) << 8) | b[1], b[2] & 15, b[3]


def mod_song(d, order):
    """ProTracker timing (speed / tempo by Fxx, Bxx, Dxx): the rows in play order with their start time"""
    speed, bpm, t, pos, row, rows, seen = 6, 125, 0.0, 0, 0, [], set()
    while pos < len(order) and (pos, row) not in seen:
        seen.add((pos, row))
        pattern, jump, brk = order[pos], None, None
        cells = [mod_cell(d, pattern, row, c) for c in range(4)]
        for s, per, e, par in cells:
            if e == 0xF and par:
                speed, bpm = (par, bpm) if par < 32 else (speed, par)
            elif e == 0xB:
                jump = par
            elif e == 0xD:
                brk = (par >> 4) * 10 + (par & 15)
        rows.append((t, pos, pattern, row, cells))
        t += speed * 2.5 / bpm
        if jump is not None:
            pos, row = jump, brk or 0
        elif brk is not None:
            pos, row = pos + 1, brk
        else:
            row += 1
            if row == 64:
                pos, row = pos + 1, 0
    return rows, t


def fig_module(args):
    d, title, samples, restart, order = read_mod(os.path.join(CASE, 'src/res/music/desert-dream.mod'))
    rows, end = mod_song(d, order)
    used = [s for s in samples if s['len']]
    cmap = plt.get_cmap('tab20')
    colour = {s['n']: cmap(i % 20) for i, s in enumerate(used)}
    fig = plt.figure(figsize=(12, 9.6))
    gs = fig.add_gridspec(3, 1, height_ratios=[1.0, 2.1, 1.25], hspace=0.42)
    a0, a1, a2 = (fig.add_subplot(gs[i]) for i in range(3))
    style(fig, (a0, a1, a2))
    fig.suptitle(f'The module "{title}": 36 positions of 29 patterns, 4 voices, 26 samples: {end:.0f} s '
                 f'({int(end // 60)} min {int(end % 60)} s) a pass', color=FG, fontsize=13, y=0.975)
    # positions
    starts = {}
    for t, pos, pattern, row, cells in rows:
        starts.setdefault(pos, (t, pattern))
    for pos, (t, pattern) in starts.items():
        t1 = starts.get(pos + 1, (end,))[0]
        a0.add_patch(plt.Rectangle((t, 0), t1 - t, 1, facecolor=BLUE if pos % 2 else '#3d5f94', edgecolor=BG))
        a0.text((t + t1) / 2, 0.5, str(pattern), ha='center', va='center', color=FG, fontsize=8)
    a0.set_xlim(0, end)
    a0.set_ylim(0, 1)
    a0.set_yticks([])
    a0.set_title('the order list: one box a position, the pattern it plays written in it (pattern 28 twice, '
                 'then 1, 2, 3 ...); width = its time', fontsize=10, loc='left', color=FG)
    # the notes
    for t, pos, pattern, row, cells in rows:
        for ch, (s, per, e, par) in enumerate(cells):
            if per and s:
                a1.plot([t, t + 0.12], [ch + 0.5 + (per - 400) / 2400] * 2, color=colour.get(s, FG), lw=2.2)
    a1.set_xlim(0, end)
    a1.set_ylim(0, 4)
    a1.set_yticks([0.5, 1.5, 2.5, 3.5])
    a1.set_yticklabels(['voice 1', 'voice 2', 'voice 3', 'voice 4'])
    for y in (1, 2, 3):
        a1.axhline(y, color=DIM, lw=0.5)
    a1.set_xlabel('seconds from the start of the song (ProTracker timing: speed 6-7 at 125 BPM, 0.12-0.14 s a row)')
    a1.set_title('every note: one dash, coloured by its sample; within a lane higher = lower pitch (the period)',
                 fontsize=10, loc='left', color=FG)
    # samples
    xs = np.arange(len(used))
    a2.bar(xs, [s['len'] / 1024 for s in used], color=[colour[s['n']] for s in used])
    a2.set_xticks(xs)
    a2.set_xticklabels([str(s['n']) for s in used], fontsize=8)
    a2.set_ylabel('KB')
    credits = ' '.join(s['name'].strip('_ ').strip() for s in samples[:18] if s['name'].strip('_ '))
    a2.set_xlabel('sample number (14 and 27-31 are empty)')
    a2.text(0.99, 0.95, 'the sample names, read in order:\n' + credits[:76] + '\n' + credits[76:150] + '\n'
            + credits[150:], transform=a2.transAxes, ha='right', va='top', color=DIM, fontsize=8.5)
    a2.set_title(f'the 26 samples: {sum(s["len"] for s in used)} bytes of the module\'s {len(d)}; the GS ROM adds '
                 r'\$80 to each byte as it loads them', fontsize=10, loc='left', color=FG)
    fig.subplots_adjust(left=0.07, right=0.98, top=0.92, bottom=0.08)
    save(fig, args.out)


# --- the effects -----------------------------------------------------------------------------------------------

def read_wav(path):
    w = wave.open(path)
    raw = w.readframes(w.getnframes())
    if w.getsampwidth() == 1:
        x = np.frombuffer(raw, dtype=np.uint8).astype(float) - 128
    else:
        x = np.frombuffer(raw, dtype=np.int16).astype(float)
    return x.reshape(-1, w.getnchannels()).mean(1), w.getframerate()


def sounding(x, sr, level=0.03):
    a = np.abs(x - np.median(x))
    idx = np.nonzero(a > a.max() * level)[0]
    return (idx[0] / sr, idx[-1] / sr) if len(idx) else (0, 0)


def fig_effects(args):
    sfx = os.path.join(CASE, 'src/res/sfx')
    files = {int(f[2:4]): os.path.join(sfx, f) for f in os.listdir(sfx) if f.endswith('.wav')}
    fig, axes = plt.subplots(14, 2, figsize=(12, 15.5), gridspec_kw={'width_ratios': [1, 1.25]})
    style(fig, axes.ravel())
    rates = []
    for n in range(1, 15):
        x, _ = read_wav(files[n])
        y, sr = read_wav(os.path.join(args.renders, f'gs-fx47-{n:02d}.wav'))
        t0, t1 = sounding(y, sr)
        rate = len(x) / (t1 - t0) if t1 > t0 else 0
        rates.append(rate)
        a, b = axes[n - 1]
        never = n in (2, 8)
        a.plot(np.arange(len(x)) / 1000, x, color=RED if never else GREEN, lw=0.4)
        a.set_xlim(0, 50)
        a.set_ylim(-130, 130)
        a.set_yticks([])
        a.text(0.995, 0.88, f'effect {n}: {EFFECT_FILE[n]}, {len(x)} bytes', transform=a.transAxes, ha='right',
               va='top', color=FG, fontsize=8.5)
        a.text(0.995, 0.08, EFFECT_EVENT[n], transform=a.transAxes, ha='right', va='bottom', fontsize=8,
               color=RED if never else YELLOW)
        seg = y[int(max(0, t0 - 0.02) * sr):int((t1 + 0.05) * sr)]
        if len(seg) > 512:
            b.specgram(seg, NFFT=512, Fs=sr, noverlap=384, cmap='magma', vmin=-40)
        b.set_xlim(0, 3.1)
        b.set_ylim(0, 8000)
        b.set_yticks([0, 4000, 8000])
        b.set_yticklabels(['0', '4k', '8k'], fontsize=7)
        b.text(0.99, 0.85, f'{t1 - t0:.2f} s on the card', transform=b.transAxes, ha='right', va='top',
               color=FG, fontsize=8.5, bbox=dict(facecolor=AX, edgecolor='none', alpha=0.7, pad=1))
        if n < 14:
            a.set_xticklabels([])
            b.set_xticklabels([])
    axes[-1][0].set_xlabel('the file\'s bytes, in thousands (unsigned, \\$80 = silence)')
    axes[-1][1].set_xlabel('seconds; the card\'s output at note 47 (Hz up to 8 kHz)')
    med = float(np.median([r for r in rates if r]))
    fig.suptitle('The 14 effects: left the bytes of each file, right what the card plays at note 47 '
                 f'({med:.0f} bytes a second)', color=FG, fontsize=13, y=0.995)
    fig.text(0.5, 0.968, r'red: effects 2 and 8, which the driver would pick only for R = \$A1-\$FF: never (9.6)',
             ha='center', color=RED, fontsize=10)
    fig.subplots_adjust(left=0.03, right=0.99, top=0.955, bottom=0.04, hspace=0.18, wspace=0.05)
    save(fig, args.out)
    for n, r in enumerate(rates, 1):
        print(f'effect {n}: {r:.0f} bytes/s')


# --- the port handshake ----------------------------------------------------------------------------------------

def zxbus_rows(path, frame=None, limit=400):
    """The events of one driver call: from the host's first OUT on/after `frame` on (the card's idle polls of its
    own status, port 4, the frame interrupts and the DAC samples left out)"""
    rows = []
    for line in open(path):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        if d['side'] in ('idle', 'interrupt', 'dac') or (d['side'] == 'gs' and d['port'] == 4):
            continue
        rows.append(d)
    i0 = next(i for i, d in enumerate(rows) if d['side'] == 'host' and d.get('out') and
              (frame is None or d['frame'] >= frame))
    return rows[i0:i0 + limit]


CMD_NAME = {0x40: '#40 note', 0x39: '#39 play', 0x2E: '#2E select'}
CARD = {1: (BLUE, 'reads the command (port 1)'), 2: (GREEN, 'reads the data (port 2)'),
        3: (YELLOW, 'OUTRG (port 3)'), 5: (VIOLET, 'RSCOM: "command taken" (port 5)'), 0: (DIM, 'status out (port 0)')}


def lane_plot(a, rows, t0, until_us, title, notes):
    lanes = {'host OUT \\$B3 (data)': 3, 'host OUT \\$BB (command)': 2, 'host IN \\$BB (polls)': 1.3,
             'card (GS Z80)': 0.4}
    for d in rows:
        us = (d['timestamp'] - t0) / GS_HZ * 1e6
        if us > until_us:
            break
        if d['side'] == 'host' and d.get('out'):
            y = 3 if d['port'] == 0xB3 else 2
            lab = (f'{d["value"]}' if y == 3 else CMD_NAME.get(d['value'], f'#{d["value"]:02X}'))
            a.plot(us, y, 'v', color=YELLOW if y == 3 else ORANGE, ms=9)
            a.annotate(lab, (us, y), (0, 8), textcoords='offset points', ha='center', color=FG, fontsize=8.5)
        elif d['side'] == 'host':
            busy = d['value'] & 1
            a.plot(us, 1.3, '|', color=RED if busy else GREEN, ms=7)
        elif d['side'] == 'gs' and d['port'] in CARD:
            a.plot(us, 0.4, 'o', color=CARD[d['port']][0], ms=6)
    a.set_yticks(list(lanes.values()))
    a.set_yticklabels(list(lanes.keys()))
    a.set_ylim(-0.9, 3.8)
    a.set_xlim(-0.5, until_us)
    a.set_title(title, loc='left', fontsize=10.5, color=FG)
    for x, y, text, colour, dx, dy in notes:
        a.annotate(text, (x, y), (x + dx, y + dy), ha='center', va='center', fontsize=8.5,
                   color=colour, arrowprops=dict(arrowstyle='->', color=colour, lw=0.8),
                   bbox=dict(facecolor=AX, edgecolor='none', alpha=0.85, pad=1.5))


def fig_handshake(args):
    disk = zxbus_rows(args.disk, frame=args.disk_frame, limit=12)
    tape = zxbus_rows(args.tape, frame=args.tape_frame, limit=3000)
    fig, (a, b) = plt.subplots(2, 1, figsize=(12, 9.4), gridspec_kw={'height_ratios': [1, 1.1]})
    style(fig, (a, b))
    t0 = disk[0]['timestamp']
    hd = [d for d in disk if d['side'] == 'host' and d.get('out')]
    g1 = next(d for d in disk if d['side'] == 'gs' and d['port'] == 1)
    g2 = next(d for d in disk if d['side'] == 'gs' and d['port'] == 2)
    g5 = next(d for d in disk if d['side'] == 'gs' and d['port'] == 5)

    def u(d):
        return (d['timestamp'] - t0) / GS_HZ * 1e6
    lane_plot(a, disk, t0, u(g5) + 4, f'The disk driver, rD frame {disk[0]["frame"]}: four OUTs in {u(hd[3]):.1f} µs, '
              f'no poll.\nThe card takes #40, then reads the data latch, which by then holds the effect '
              f'number {hd[2]["value"]}', [
                  (u(g1), 0.4, f'takes #40\n{u(g1) - u(hd[1]):.1f} µs after it', BLUE, 0, 1.1),
                  (u(g2), 0.4, f'reads data = {g5["value"]}:\nthe note of #40', GREEN, -2.2, -0.9),
                  (u(g5), 0.4, 'RSCOM clears "command":\n#39 is gone unread', VIOLET, 0.5, 1.1),
                  (u(hd[3]), 2, '#39 written while\nthe card runs #40', RED, -2.0, -0.9)])
    a.set_xlabel('µs from the driver\'s first OUT (the card\'s clock, 12 MHz)')
    t0 = tape[0]['timestamp']
    hostcmd = [d for d in tape if d['side'] == 'host' and d.get('out') and d['port'] == 0xBB]
    reads = [d for d in tape if d['side'] == 'gs' and d['port'] == 1]
    rscom = [d for d in tape if d['side'] == 'gs' and d['port'] == 5]

    def v(d):
        return (d['timestamp'] - t0) / GS_HZ * 1e6
    end = v(rscom[2]) + 90
    notes = []
    for k, c in enumerate(hostcmd[:3]):
        r = next(x for x in reads if x['timestamp'] >= c['timestamp'])
        notes.append((v(r), 0.4, f'takes {CMD_NAME.get(c["value"])}\n{v(r) - v(c):.0f} µs after it', BLUE,
                      (-90, 10, 0)[k], 1.0))
    data = [d for d in tape if d['side'] == 'host' and d.get('out') and d['port'] == 0xB3]
    polls = [d for d in tape if d['side'] == 'host' and not d.get('out') and v(d) < end]
    lane_plot(b, tape, t0, end, f'Hood\'s tape driver, rT after the recording: effect {data[0]["value"]}.\nAfter each '
              f'command the host polls \\$BB until bit 0 clears ({len(polls)} polls: red busy, green taken)', notes)
    b.set_xlabel('µs from the driver\'s first OUT; interrupts are off all the while')
    handles = [plt.Line2D([], [], marker='o', ls='', color=c, label=t) for c, t in CARD.values()]
    for ax in (a, b):
        ax.legend(handles=handles, loc='lower left', ncol=1, facecolor=AX, edgecolor=DIM, labelcolor=FG, fontsize=8)
    fig.suptitle('One effect, two drivers: the disk\'s #39 never reaches the card, the tape\'s waits for it',
                 color=FG, fontsize=13)
    fig.subplots_adjust(left=0.16, right=0.98, top=0.88, bottom=0.07, hspace=0.5)
    save(fig, args.out)


# --- the plays over a game --------------------------------------------------------------------------------------

def fig_plays(args):
    ps = json.load(open(args.plays))
    frames = np.array([p['frame'] for p in ps])
    eff = np.array([p['effect'] for p in ps])
    wait = np.array([sum(c['wait'] or 0 for c in p['cmds']) for p in ps])
    fig, (a, b) = plt.subplots(2, 1, figsize=(12, 9), sharex=True, gridspec_kw={'height_ratios': [1.6, 1]})
    style(fig, (a, b))
    groups = [((1, 5, 9, 10, 11, 12), BLUE, 'menus and construction'), ((6, 7, 13), YELLOW, 'shots and misses'),
              ((3, 4), RED, 'kills'), ((14,), VIOLET, 'nuclear blast')]
    for members, colour, label in groups:
        m = np.isin(eff, members)
        a.plot(frames[m], eff[m], '|', color=colour, ms=9, mew=1.2, label=f'{label}: {m.sum()}')
    for n in range(1, 15):
        cnt = int((eff == n).sum())
        a.text(frames.max() * 1.005, n, f'{cnt}', va='center', color=RED if cnt == 0 else FG, fontsize=8.5)
    a.set_yticks(range(1, 15))
    a.set_yticklabels([f'{n}: {EFFECT_EVENT[n].split(":", 1)[1].strip()}' for n in range(1, 15)], fontsize=8)
    a.set_ylim(0.4, 14.6)
    a.axhspan(1.6, 2.4, color=RED, alpha=0.12)
    a.axhspan(7.6, 8.4, color=RED, alpha=0.12)
    a.legend(loc='lower left', bbox_to_anchor=(0.0, 1.09), ncol=4, facecolor=AX, edgecolor=DIM, labelcolor=FG,
             fontsize=9)
    a.set_title(f'{len(ps)} effects played in {frames.max() - frames.min()} frames; the count of each at the right: '
                'effects 2 and 8 (red bands) never', loc='left', fontsize=10.5, color=FG)
    b.semilogy(frames, np.maximum(wait, 1), '.', color=ORANGE, ms=3)
    b.axhline(71680, color=RED, lw=0.8)
    b.text(frames.min(), 71680 * 1.15, 'a whole frame (71 680 T): an interrupt is lost', color=RED, fontsize=8.5)
    b.axhline(np.median(wait), color=DIM, lw=0.8, ls='--')
    b.text(frames.min(), np.median(wait) * 1.15, f'median {np.median(wait):.0f} T', color=DIM, fontsize=8.5)
    b.set_ylabel('T-states the host waits\n(interrupts off)')
    b.set_xlabel('frame of the recording rT (Hood\'s tape, GS 512 KB, the bot\'s game)')
    b.set_title(f'the host\'s wait per play (all three commands): {(wait > 35840).sum()} plays over half a frame, '
                f'{(wait > 71680).sum()} over a frame', loc='left', fontsize=10.5, color=FG)
    fig.suptitle('Every General Sound effect of a 39 500-frame game on Hood\'s tape', color=FG, fontsize=13)
    fig.subplots_adjust(left=0.25, right=0.96, top=0.84, bottom=0.07, hspace=0.25)
    save(fig, args.out)


# --- the R register ---------------------------------------------------------------------------------------------

def fig_rreg(args):
    vals = json.load(open(args.rvalues))
    rs = np.array([v['r'] for v in vals])
    fig, a = plt.subplots(figsize=(12, 5.2))
    style(fig, (a,))
    windows = [(0x01, 0x50, GREEN, 'effect 3 / 6'), (0x51, 0xA0, BLUE, 'effect 4 / 7'),
               (0xA1, 0xFF, RED, 'effect 2 / 8')]
    for lo, hi, colour, label in windows:
        a.axvspan(lo - 0.5, hi + 0.5, color=colour, alpha=0.18)
        a.text((lo + hi) / 2, 0.93, label, transform=a.get_xaxis_transform(), ha='center', color=colour, fontsize=10)
    a.axvspan(-0.5, 0.5, color=GREEN, alpha=0.18)
    a.axvline(0x7F + 0.5, color=YELLOW, lw=1.2, ls='--')
    a.text(0x80, 0.75, 'bit 7 of R: the refresh counter\ncounts only bits 0-6, so R\nnever passes \\$7F here',
           transform=a.get_xaxis_transform(), color=YELLOW, fontsize=9)
    counts = np.bincount(rs, minlength=256)
    a.bar(np.arange(256), counts, width=1.0, color=FG)
    a.set_xlim(-1, 256)
    a.set_xticks([0, 0x20, 0x40, 0x50, 0x60, 0x80, 0xA0, 0xC0, 0xE0, 0xFF])
    a.set_xticklabels([r'\$' + h for h in ('00', '20', '40', '50', '60', '80', 'A0', 'C0', 'E0', 'FF')])
    a.set_xlabel(r'R as LD A,R read it (\$C069 for a kill, \$C0A8 for a shot)')
    a.set_ylabel('calls')
    a.yaxis.set_major_locator(matplotlib.ticker.MaxNLocator(integer=True))
    agree = sum(1 for v in vals if v['window_effect'] == v['played'])
    low = int(((rs <= 0x50)).sum())
    a.set_title(f'{len(rs)} calls of the driver with id 2 or 4 in rT: R from \\${rs.min():02X} to \\${rs.max():02X}; '
                f'{low} in the first window, {len(rs) - low} in the second, none in the third; the host sent the window\'s effect in {agree} of {len(rs)}', loc='left',
                fontsize=10.5, color=FG)
    fig.suptitle(r'Why effects 2 and 8 never sound: the driver picks them for R = \$A1-\$FF, which R never reaches',
                 color=FG, fontsize=13)
    fig.subplots_adjust(left=0.07, right=0.98, top=0.86, bottom=0.12)
    save(fig, args.out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('figure', choices=['module', 'effects', 'handshake', 'plays', 'rreg'])
    ap.add_argument('--out', required=True)
    ap.add_argument('--renders')
    ap.add_argument('--disk')
    ap.add_argument('--disk-frame', type=int)
    ap.add_argument('--tape')
    ap.add_argument('--tape-frame', type=int)
    ap.add_argument('--plays')
    ap.add_argument('--rvalues')
    args = ap.parse_args()
    {'module': fig_module, 'effects': fig_effects, 'handshake': fig_handshake, 'plays': fig_plays,
     'rreg': fig_rreg}[args.figure](args)


if __name__ == '__main__':
    main()
