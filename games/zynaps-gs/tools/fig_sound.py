#!/usr/bin/env python3
"""The figures of docs/09-sound.md (the module figure and the plotting style come from nether-earth-gs's
tools/fig_sound.py, copied and extended; that file is untouched).

    python3 tools/fig_sound.py modules  --out docs/img/sound                 # module-01.png .. module-13.png
    python3 tools/fig_sound.py overview --out docs/img/sound/modules.png     # the 13 side by side
    python3 tools/fig_sound.py effects  --renders work/audio/fx --out docs/img/sound   # effects-both.png, effects-fx.png
    python3 tools/fig_sound.py hooks    --out docs/img/sound/hooks.png       # the 28 hooks per level (h2 + zgsB runs)
    python3 tools/fig_sound.py timeline --ports work/zgsB/e1/ports.jsonl --bot work/zgsB/e1/bot.tsv \
                                        --out docs/img/sound/timeline.png    # a level as GS commands
    python3 tools/fig_sound.py waits    --ports work/zgsB/e1/ports.jsonl --out docs/img/sound/waits.png
    python3 tools/fig_sound.py cardmap  --out docs/img/sound/card-pages.png  # 128 KB vs 512 KB

Inputs:
- the modules `src/res/music/levelNN.mod` and the effects `src/res/sfx/fxNN.wav` (the bytes the loader uploads);
- `--renders`: the card's output for each effect at the note the game gives it (`fxNN-noteXX.wav`, stage 1's
  `gs_session.py audiogs`, the card alone);
- `--ports`: a `zxbus.1.ports` history stream (the host's IN / OUT on `$B3` / `$BB` with the frame, the T-state in
  the frame (16 bits, unwrapped here) and the PC);
- `work/stage2/h2/summary.txt` and the zgsB bot runs' `bot-counts.json` (the stub counts per level).
"""
import argparse
import json
import os
import struct
import wave

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, AX, FG, DIM = '#15161b', '#1c1d24', '#e8e8ee', '#8a8c99'
GREEN, BLUE, YELLOW, RED, ORANGE, VIOLET, CYAN = '#4caf50', '#5c8fd6', '#e0c341', '#e5534b', '#e08a3c', '#a77bd6', '#4cc3c9'
FRAME_T = 71680  # Pentagon 128

# The driver's entries (src/disk/driver.ann) and the game events that call them (docs/09 9.4): FX -> event
FX_EVENT = {
    'start': ('the game start jingle', 'GameStartHook'),
    1: ('a weapon pod appears', 'PodAppearsHook'),
    2: ('the pod selects the next weapon', 'NextWeaponHook'),
    3: ('a weapon switched on', 'WeaponOnHook'),
    4: ('an enemy fires; a plasma ball launched', 'EnemyFireHook, PlasmaLaunchHook'),
    5: ('a homing missile or a seeker launched', 'MissileLaunchHook'),
    6: ('a plasma ball bounces', 'PlasmaBounceHook'),
    7: ('an enemy explodes', 'ExplodeHook'),
    8: ('the ship explodes', 'ShipHitHook'),
    9: ('a laser shot (laser level 0-1)', 'ShotHook'),
    10: ('a laser shot (laser level 2-3)', 'ShotHook'),
    11: ('the big enemy destroyed (with 8, 7, 11)', 'BigEnemyDestroyedHook'),
    12: ('the big enemy hit, levels 7 and 11', 'BigEnemyHitHook'),
    13: ('the big enemy hit, other levels', 'BigEnemyHitHook'),
    14: ('the big enemy hit, other levels', 'BigEnemyHitHook'),
    15: ('an enemy bounces off the scenery', 'SceneryBounceHook'),
    16: ('path 2 + 6, 10 frames left', 'ObjectSoundStub'),
    17: ('an enemy starts its dive', 'DiveHook'),
    18: ('an enemy bounces off the arena edge', 'ArenaBounceHook'),
    19: ('an enemy aims (path 4 + 4)', 'AimPlayerHook'),
    20: ('an enemy aims (path 3 + 4); paths 5, 23', 'AimPlayerHook, ObjectSoundStub'),
    21: ('SATURNS: path 1 changes its movement', 'ObjectSoundStub'),
}
FX_NOTE = {'start': 0x33, 1: 0x26, 2: 0x32, 3: 0x32, 4: 0x2A, 5: 0x32, 6: 0x3C, 7: 0x2C, 8: 0x2D, 9: 0x34, 10: 0x32,
           11: 0x28, 12: 0x2C, 13: 0x31, 14: 0x32, 15: 0x2D, 16: 0x3C, 17: 0x28, 18: 0x3A, 19: 0x28, 20: 0x28, 21: 0x32}
LEVEL_VOLUME = {1: 0x1A, 2: 0x20, 3: 0x3C, 4: 0x28, 5: 0x40, 6: 0x20, 7: 0x40, 8: 0x20, 9: 0x40, 10: 0x20, 11: 0x20,
                12: 0x26, 13: 0x40}


def esc(s):
    return s.replace('$', r'\$')


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
    plt.close(fig)
    print('wrote', out)


# --- the modules -----------------------------------------------------------------------------------------------

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
    """ProTracker timing (speed / tempo by Fxx, Bxx, Dxx): the rows in play order with their start time; a jump
    back to a position already played ends the pass"""
    speed, bpm, t, pos, row, rows, seen = 6, 125, 0.0, 0, 0, [], set()
    speeds = set()
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
        speeds.add((speed, bpm))
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
    return rows, t, speeds


def mod_info(n):
    path = os.path.join(CASE, f'src/res/music/level{n:02d}.mod')
    d, title, samples, restart, order = read_mod(path)
    rows, end, speeds = mod_song(d, order)
    used = [s for s in samples if s['len']]
    notes = sum(1 for r in rows for c in r[4] if c[1])
    played = sorted({r[2] for r in rows})
    return dict(n=n, d=d, title=title, samples=samples, used=used, order=order, rows=rows, end=end, speeds=speeds,
                notes=notes, played=played, patterns=max(order) + 1 if order else 0)


def label_of(n):
    return 'the title' if n == 13 else f'level {n}'


def fig_module(n, out):
    m = mod_info(n)
    d, title, samples, used, order, rows, end = m['d'], m['title'], m['samples'], m['used'], m['order'], m['rows'], m['end']
    cmap = plt.get_cmap('tab20')
    colour = {s['n']: cmap(i % 20) for i, s in enumerate(used)}
    fig = plt.figure(figsize=(12, 9.2))
    g = fig.add_gridspec(3, 1, height_ratios=[0.8, 2.1, 1.3], hspace=0.45)
    a0, a1, a2 = (fig.add_subplot(g[i]) for i in range(3))
    style(fig, (a0, a1, a2))
    sp = sorted(m['speeds'])
    sptxt = ', '.join(f'speed {s} at {b} BPM' for s, b in sp[:3]) + (' ...' if len(sp) > 3 else '')
    name = f'"{title}"' if title.strip() else 'untitled'
    fig.suptitle(f'Module {n} ({label_of(n)}), {name}: {len(order)} positions of {m["patterns"]} patterns, '
                 f'{len(used)} samples, {m["notes"]} notes: {int(end // 60)} min {end % 60:04.1f} s a pass',
                 color=FG, fontsize=13, y=0.975)
    starts = {}
    for t, pos, pattern, row, cells in rows:
        starts.setdefault(pos, (t, pattern))
    poss = sorted(starts)
    for i, pos in enumerate(poss):
        t, pattern = starts[pos]
        t1 = starts[poss[i + 1]][0] if i + 1 < len(poss) else end
        a0.add_patch(plt.Rectangle((t, 0), t1 - t, 1, facecolor=BLUE if i % 2 else '#3d5f94', edgecolor=BG))
        if (t1 - t) > end / 90:
            a0.text((t + t1) / 2, 0.5, str(pattern), ha='center', va='center', color=FG, fontsize=8)
    a0.set_xlim(0, end)
    a0.set_ylim(0, 1)
    a0.set_yticks([])
    unplayed = len(order) - len(poss)
    a0.set_title('the order list as played: one box a position, its pattern number written in it; width = its time'
                 + (f' ({unplayed} positions after a jump never play)' if unplayed > 0 else ''),
                 fontsize=10, loc='left', color=FG)
    for t, pos, pattern, row, cells in rows:
        for ch, (s, per, e, par) in enumerate(cells):
            if per and s:
                a1.plot([t, t + max(0.12, end / 700)], [ch + 0.5 + (per - 400) / 2400] * 2, color=colour.get(s, FG),
                        lw=2.2, solid_capstyle='butt')
    a1.set_xlim(0, end)
    a1.set_ylim(0, 4)
    a1.set_yticks([0.5, 1.5, 2.5, 3.5])
    a1.set_yticklabels(['voice 1', 'voice 2', 'voice 3', 'voice 4'])
    for y in (1, 2, 3):
        a1.axhline(y, color=DIM, lw=0.5)
    a1.set_xlabel(f'seconds from the start of the song (ProTracker timing: {sptxt})')
    a1.set_title('every note: one dash, coloured by its sample; within a lane higher = lower pitch (the period)',
                 fontsize=10, loc='left', color=FG)
    xs = np.arange(len(used))
    a2.bar(xs, [s['len'] / 1024 for s in used], color=[colour[s['n']] for s in used])
    a2.set_xticks(xs)
    a2.set_xticklabels([str(s['n']) for s in used], fontsize=8)
    a2.set_ylabel('KB')
    named = [f'{s["n"]}: {s["name"].strip()}' for s in samples if s['name'].strip(' _-#.')]
    a2.set_xlabel('sample number (the samples with no bytes are left out)')
    if named:
        lines, cur = [], ''
        for t in named:
            t = t[:30]
            if len(cur) + len(t) > 70:
                lines.append(cur)
                cur = ''
            cur += ('   ' if cur else '') + t
        lines.append(cur)
        a2.text(0.99, 0.95, 'the sample names:\n' + '\n'.join(lines[:7]) + ('\n...' if len(lines) > 7 else ''),
                transform=a2.transAxes, ha='right', va='top', color=DIM, fontsize=8)
    total = sum(s['len'] for s in used)
    a2.set_title(f'the {len(used)} samples: {total} of the module\'s {len(d)} bytes ({100 * total / len(d):.0f} %); '
                 f'played at #2A {LEVEL_VOLUME[n]} of 64', fontsize=10, loc='left', color=FG)
    fig.subplots_adjust(left=0.07, right=0.98, top=0.91, bottom=0.07)
    save(fig, out)
    return m


def fig_modules(args):
    rows = []
    for n in range(1, 14):
        m = fig_module(n, os.path.join(args.out, f'module-{n:02d}.png'))
        rows.append((n, m['title'], len(m['d']), len(m['order']), m['patterns'], len(m['used']), m['notes'],
                     m['end'], sorted(m['speeds'])))
    for r in rows:
        print(f'module {r[0]:2d} "{r[1]}" {r[2]} bytes, {r[3]} positions, {r[4]} patterns, {r[5]} samples, '
              f'{r[6]} notes, {r[7]:.1f} s, {r[8][:4]}')


def fig_overview(args):
    ms = [mod_info(n) for n in range(1, 14)]
    fig, (a, b) = plt.subplots(1, 2, figsize=(12, 6.2), gridspec_kw={'width_ratios': [1.25, 1]})
    style(fig, (a, b))
    ys = np.arange(13)[::-1]
    for y, m in zip(ys, ms):
        smp = sum(s['len'] for s in m['used'])
        a.barh(y, smp / 1024, color=GREEN, height=0.7)
        a.barh(y, (len(m['d']) - smp) / 1024, left=smp / 1024, color=BLUE, height=0.7)
        a.text(len(m['d']) / 1024 + 0.8, y, f'{len(m["d"])}', va='center', color=FG, fontsize=8.5)
    a.set_yticks(ys)
    a.set_yticklabels([f'{label_of(m["n"])}  "{m["title"].strip()[:14]}"' if m['title'].strip() else label_of(m['n'])
                       for m in ms], fontsize=8.5)
    a.set_xlabel('KB')
    a.set_xlim(0, 84)
    a.legend(handles=[plt.Rectangle((0, 0), 1, 1, color=GREEN), plt.Rectangle((0, 0), 1, 1, color=BLUE)],
             labels=['samples', 'header + patterns'], loc='lower right', facecolor=AX, edgecolor=DIM, labelcolor=FG,
             fontsize=8.5)
    a.set_title('the bytes each upload sends: mostly samples', loc='left', fontsize=10.5, color=FG)
    for y, m in zip(ys, ms):
        b.barh(y, m['end'], color=YELLOW if m['end'] < 30 else ORANGE, height=0.7)
        b.text(m['end'] + 3, y, f'{int(m["end"] // 60)}:{int(m["end"] % 60):02d}, {len(m["order"])} pos.',
               va='center', color=FG, fontsize=8.5)
    b.set_yticks(ys)
    b.set_yticklabels([])
    b.set_xlim(0, 330)
    b.set_xlabel('seconds a pass (ProTracker timing; the card loops the module)')
    b.set_title('how long a pass lasts before the module loops', loc='left', fontsize=10.5, color=FG)
    fig.suptitle('The 13 modules: 26 to 58 KB each, from an 8 s loop (level 6) to 4 min 36 s (level 12)', color=FG,
                 fontsize=13)
    fig.subplots_adjust(left=0.2, right=0.98, top=0.87, bottom=0.1, wspace=0.05)
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


def effects_panel(keys, renders, title, sub, out):
    fig, axes = plt.subplots(len(keys), 2, figsize=(12, 1.25 * len(keys) + 1.6),
                             gridspec_kw={'width_ratios': [1, 1.25]})
    style(fig, axes.ravel())
    rates = []
    for i, k in enumerate(keys):
        name = 'fx-start' if k == 'start' else f'fx{k:02d}'
        x, _ = read_wav(os.path.join(CASE, 'src/res/sfx', name + '.wav'))
        rn = [f for f in os.listdir(renders) if f.startswith(('start' if k == 'start' else f'fx{k:02d}') + '-note')
              and f.endswith('.wav')]
        y, sr = read_wav(os.path.join(renders, rn[0]))
        t0, t1 = sounding(y, sr)
        rates.append(len(x) / (t1 - t0) if t1 > t0 else 0)
        a, b = axes[i]
        a.plot(np.arange(len(x)) / 1000, x, color=GREEN, lw=0.4)
        a.set_xlim(0, 12)
        a.set_ylim(-130, 130)
        a.set_yticks([])
        lab = 'start' if k == 'start' else f'FX {k}'
        a.text(0.995, 0.9, f'{lab}: {len(x)} bytes', transform=a.transAxes, ha='right', va='top', color=FG,
               fontsize=8.5, bbox=dict(facecolor=AX, edgecolor='none', alpha=0.7, pad=1))
        a.text(0.995, 0.06, FX_EVENT[k][0], transform=a.transAxes, ha='right', va='bottom', fontsize=8,
               color=YELLOW, bbox=dict(facecolor=AX, edgecolor='none', alpha=0.7, pad=1))
        seg = y[int(max(0, t0 - 0.02) * sr):int((t1 + 0.05) * sr)]
        if len(seg) > 512:
            b.specgram(seg, NFFT=512, Fs=sr, noverlap=384, cmap='magma', vmin=-40)
        b.set_xlim(0, 1.6)
        b.set_ylim(0, 8000)
        b.set_yticks([0, 4000, 8000])
        b.set_yticklabels(['0', '4k', '8k'], fontsize=7)
        b.text(0.99, 0.85, f'note \\${FX_NOTE[k]:02X}: {t1 - t0:.2f} s', transform=b.transAxes, ha='right',
               va='top', color=FG, fontsize=8.5, bbox=dict(facecolor=AX, edgecolor='none', alpha=0.7, pad=1))
        if i < len(keys) - 1:
            a.set_xticklabels([])
            b.set_xticklabels([])
    axes[-1][0].set_xlabel('the file\'s bytes, in thousands (8-bit unsigned, 0 = \\$80 = silence)')
    axes[-1][1].set_xlabel('seconds; the card\'s output at the game\'s note (Hz up to 8 kHz; the render is 1.6 s)')
    fig.suptitle(title, color=FG, fontsize=13, y=0.995)
    fig.text(0.5, 1 - 0.55 / (1.25 * len(keys) + 1.6), sub, ha='center', color=DIM, fontsize=10)
    top = 1 - 0.95 / (1.25 * len(keys) + 1.6)
    fig.subplots_adjust(left=0.03, right=0.99, top=top, bottom=0.6 / (1.25 * len(keys) + 1.6) + 0.02,
                        hspace=0.18, wspace=0.05)
    save(fig, out)
    return rates


def fig_effects(args):
    r1 = effects_panel(['start'] + list(range(1, 11)), args.renders,
                       'The jingle and FX 1-10: uploaded in both modes, the yellow line is the game event',
                       'left: the bytes the loader sends; right: what the card plays at the note the driver gives '
                       '(stage 1 renders, the card alone)', os.path.join(args.out, 'effects-both.png'))
    r2 = effects_panel(list(range(11, 22)), args.renders,
                       'FX 11-21: on the card only in the effects-only mode (the disk set)',
                       'their callers go through CallDriverFx, which returns at once in music mode',
                       os.path.join(args.out, 'effects-fx.png'))
    print('bytes a second (median):', np.median([r for r in r1 + r2 if r]))


# --- the hooks per level ---------------------------------------------------------------------------------------

HOOK_ROWS = [
    ('FF7B', 'PodAppearsHook', 'FX 1', 'a pod appears'),
    ('FF81', 'NextWeaponHook', 'FX 2', 'the pod selects the next weapon'),
    ('FF75', 'WeaponOnHook', 'FX 3', 'a weapon switched on'),
    ('FF60', 'EnemyFireHook', 'FX 4', 'an enemy fires'),
    ('FF56', 'PlasmaLaunchHook', 'FX 4', 'a plasma ball launched'),
    ('FF4D', 'MissileLaunchHook', 'FX 5', 'a homing missile / a seeker'),
    ('FF69', 'PlasmaBounceHook', 'FX 6', 'a plasma ball bounces'),
    ('FF3B', 'ExplodeHook', 'FX 7', 'an enemy explodes'),
    ('FF44', 'ShipHitHook', 'FX 8', 'the ship explodes'),
    ('FF6F', 'ShotHook', 'FX 9/10', 'a laser shot'),
    ('FFA3', 'BigEnemyDestroyedHook', 'FX 8 or 4 FX', 'big enemy destroyed'),
    ('FF99', 'BigEnemyHitHook', 'FX 12-14 *', 'the big enemy hit'),
    ('FF8F', 'SceneryBounceHook', 'FX 15 *', 'a bounce off the scenery'),
    ('FFAC', 'ArenaBounceHook', 'FX 18 *', 'a bounce off the arena edge'),
    ('FFB6', 'DiveHook', 'FX 17 *', 'a dive starts'),
    ('FFC3', 'AimPlayerHook', 'FX 19/20 *', 'an enemy aims'),
    ('B2F0', 'ObjectSoundStub', 'FX 16/20/21 *', 'a path moment'),
    ('B47F', 'SlotGoneHook', '-', 'an enemy slot freed'),
    ('FF87', 'NextLevelHook', '-', 'the next level chosen'),
    ('FF1C', 'RoundStartHook', 'upload', 'a round starts'),
    ('FF26', 'GameStartHook', 'jingle', 'PREPARE FOR COMBAT'),
    ('A6AE', 'WaitStub', 'fade', 'the wait between rounds'),
]


def fig_hooks(args):
    # h2: one row a level (summary.txt has a subset of columns: read the per-run tsv's instead)
    h2 = os.path.join(CASE, 'work/stage2/h2')
    cols = {}
    names = {'RoundStartHook': 'FF1C', 'GameStartHook': 'FF26', 'ExplodeHook FX7': 'FF3B', 'ShipHitHook FX8': 'FF44',
             'MissileLaunchHook FX5': 'FF4D', 'PlasmaLaunchHook FX4': 'FF56', 'EnemyFireHook FX4': 'FF60',
             'PlasmaBounceHook FX6': 'FF69', 'ShotHook shot': 'FF6F', 'WeaponOnHook FX3': 'FF75',
             'PodAppearsHook FX1': 'FF7B', 'NextWeaponHook FX2': 'FF81', 'NextLevelHook': 'FF87',
             'SceneryBounceHook FX15': 'FF8F', 'BigEnemyHitHook FX12-14': 'FF99', 'BigEnemyDestroyedHook': 'FFA3',
             'ArenaBounceHook FX18': 'FFAC', 'DiveHook FX17': 'FFB6', 'AimPlayerHook PathSound': 'FFC3',
             'ObjectSoundStub': 'B2F0', 'SlotGoneHook': 'B47F', 'WaitStub': 'A6AE'}
    runs = []
    lines = open(os.path.join(h2, 'fx-long.tsv')).read().splitlines()
    hdr = lines[0].split('\t')
    # fx-long.tsv names the stubs by the h2 script's older names; its 22 columns are in the order of `names`
    assert len(hdr) - 3 == len(names)
    addr = list(names.values())
    order = [0, 1, 2, 6, 7, 5, 3, 8, 4, 9, 10, 11]
    for ln in lines[1:]:
        f = ln.split('\t')
        c = {a: int(v) for a, v in zip(addr, f[3:])}
        runs.append((f'h2 L{order[int(f[0])] + 1}', int(f[2]) - int(f[1]), c, 'fx'))
    # the mortal run (the same columns): the only one where the ship could die
    for ln in open(os.path.join(h2, 'mortal.tsv')).read().splitlines()[1:]:
        f = ln.split('\t')
        runs.append(('mortal L1', int(f[2]) - int(f[1]), {a: int(v) for a, v in zip(addr, f[3:])}, 'fx'))
    for tag, path, mode in args.runs:
        # TAG=L1,L2: the level each counts interval played (bot-counts.json holds the level index only)
        tag, _, lv = tag.partition('=')
        lv = lv.split(',') if lv else []
        lc = json.load(open(path))
        for i, (a, b) in enumerate(zip(lc, lc[1:])):
            c = {k: b['counts'].get(k, 0) - a['counts'].get(k, 0) for k in b['counts']}
            lvl = lv[i] if i < len(lv) else f'i{a["level_index"]}'
            runs.append((f'{tag} {lvl}', b['frame'] - a['frame'], c, mode))
    M = np.array([[r[2].get(h[0], 0) for r in runs] for h in HOOK_ROWS], dtype=float)
    fig, a = plt.subplots(figsize=(13, 9.6))
    style(fig, (a,))
    a.imshow(np.log10(M + 1), aspect='auto', cmap='viridis', vmin=0, vmax=4.7)
    for i in range(M.shape[0]):
        for j in range(M.shape[1]):
            v = int(M[i, j])
            a.text(j, i, str(v) if v else '·', ha='center', va='center', fontsize=7.5,
                   color='black' if v and np.log10(v + 1) > 2.6 else FG)
    a.set_yticks(range(len(HOOK_ROWS)))
    a.set_yticklabels([f'{h[1]} ({h[2]}): {h[3]}' for h in HOOK_ROWS], fontsize=8.5)
    a.set_xticks(range(len(runs)))
    a.set_xticklabels([f'{r[0]}\n{r[1]} fr' for r in runs], fontsize=7.5, rotation=0)
    zero = [h[1] for i, h in enumerate(HOOK_ROWS) if M[i].sum() == 0]
    a.set_title('Cell: runs of the stub on that level of that run (memory profiler, kinds x); · = 0; '
                '* = sounds in effects-only mode' + (f'; never: {", ".join(zero)}' if zero else ''),
                loc='left', fontsize=10, color=FG)
    fig.suptitle(f'The 22 game-side hooks, level by level: {len(HOOK_ROWS) - len(zero)} of {len(HOOK_ROWS)} '
                 'ran in play' + ('' if zero else ' (all)') + '; ShipHitHook only where the ship could die',
                 color=FG, fontsize=13)
    fig.subplots_adjust(left=0.32, right=0.99, top=0.9, bottom=0.08)
    save(fig, args.out)


# --- the port history ------------------------------------------------------------------------------------------

def load_ports(path):
    rows, last = [], {}
    for line in open(path):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        f, t = d['frame'], d['tacts']
        base = last.get(f, (0, -1))
        if t < base[1]:
            base = (base[0] + 65536, t)
        last[f] = (base[0], t)
        d['t'] = f * FRAME_T + base[0] + t
        rows.append(d)
    return rows


def conversation(rows):
    """[{cmd, data:[...], t, frame, pc, wait}]: one per command, with the data bytes written since the previous one
    and the T-states the host polled after it (until bit 0 of $BB read clear); streams of data with no command are
    kept as one entry {cmd: 'stream', n, t, frame, t_end}"""
    out, data = [], []
    cur = None
    stream = None
    for d in rows:
        port = d['port'] & 0xFF
        if d['dir'] == 'out' and port == 0xB3:
            if cur is not None and cur['cmd'] == 0xD1 or stream is not None:
                if stream is None:
                    stream = {'cmd': 'stream', 'n': 0, 't': d['t'], 'frame': d['frame'], 'pc': d['pc']}
                    out.append(stream)
                stream['n'] += 1
                stream['t_end'] = d['t']
                stream['frame_end'] = d['frame']
                continue
            data.append(d['value'])
        elif d['dir'] == 'out' and port == 0xBB:
            stream = None
            cur = {'cmd': d['value'], 'data': data, 't': d['t'], 'frame': d['frame'], 'pc': d['pc'], 'wait': None}
            out.append(cur)
            data = []
        elif d['dir'] == 'in' and port == 0xBB and cur is not None and cur['wait'] is None and not d['value'] & 1:
            cur['wait'] = d['t'] - cur['t']
    return out


def plays(conv):
    """The FX plays: #2E n, #40 note, then #80+c (data n) or #45 / #39; FX number n as sent (handle)"""
    res = []
    i = 0
    while i < len(conv):
        c = conv[i]
        if c['cmd'] == 0x2E and i + 2 < len(conv) and conv[i + 1]['cmd'] == 0x40:
            fx = c['data'][-1] if c['data'] else None
            note = conv[i + 1]['data'][-1] if conv[i + 1]['data'] else None
            j = i + 2
            parts = [c, conv[i + 1]]
            while j < len(conv) and conv[j]['cmd'] in (0x45, 0x39, 0x41) or (j < len(conv) and isinstance(conv[j]['cmd'], int) and 0x80 <= conv[j]['cmd'] <= 0x83 and len(parts) < 4):
                parts.append(conv[j])
                j += 1
                if parts[-1]['cmd'] in (0x39,) or 0x80 <= parts[-1]['cmd'] <= 0x83:
                    break
            wait = sum((p['wait'] or 0) for p in parts) + sum(len(p['data']) for p in parts) * 0
            res.append({'frame': c['frame'], 't': c['t'], 'fx': fx, 'note': note, 'parts': parts,
                        'wait': wait, 'span': parts[-1]['t'] - c['t'] + (parts[-1]['wait'] or 0),
                        'chan': parts[-1]['cmd'] - 0x80 if 0x80 <= parts[-1]['cmd'] <= 0x83 else None})
            i = j
        else:
            i += 1
    return res



def command_waits(rows, f0, f1):
    """Every command OUT to $BB (not a stream) with the T-states until a status read showed bit 0 clear; the waits
    of the load commands (#30, #38, #D1, #D2) are left out"""
    out, cur = [], None
    for d in rows:
        if not f0 <= d['frame'] <= f1:
            continue
        port = d['port'] & 0xFF
        if d['dir'] == 'out' and port == 0xBB:
            cur = {'cmd': d['value'], 't': d['t'], 'frame': d['frame'], 'polls': 0}
        elif d['dir'] == 'in' and port == 0xBB and cur is not None:
            cur['polls'] += 1
            if not d['value'] & 1:
                cur['wait'] = d['t'] - cur['t']
                if cur['cmd'] in (0x2E, 0x40, 0x45, 0x39, 0x41) or 0x80 <= cur['cmd'] <= 0x83:
                    out.append(cur)
                cur = None
    return out


NOTE_EVENT = {(4, 0x30): 'enemy fire', (4, 0x31): 'enemy fire', (4, 0x2A): 'plasma launch', (4, 0x2B): 'plasma launch'}


def fx_label(fx, note, shift=0):
    n = fx - shift if fx is not None else None
    if fx == 1 and note == 0x33:
        return 'FX 0 the game start jingle (handle 1)'
    if n == 4:
        return 'FX 4 ' + ('plasma launch' if note in (0x2A, 0x2B) else 'enemy fire')
    if n in FX_EVENT:
        return f'FX {n} {FX_EVENT[n][0].split(";")[0]}'
    if n is not None and n > 21:
        return f'handle {fx}: SATURNS, one too high'
    return f'FX {fx}'


def fig_timeline(args):
    rows = load_ports(args.ports)
    conv = conversation(rows)
    ps = plays(conv)
    f0 = args.frm if args.frm is not None else rows[0]['frame']
    f1 = args.to if args.to is not None else rows[-1]['frame']
    ps = [p for p in ps if f0 <= p['frame'] <= f1]
    ups = [c for c in conv if c['cmd'] == 'stream' and f0 <= c['frame'] <= f1]
    other = [c for c in conv if isinstance(c['cmd'], int) and c['cmd'] in (0x23, 0xF3, 0x30, 0x38, 0x31, 0x32, 0x2A, 0x2B)
             and f0 <= c['frame'] <= f1]
    kinds = {}
    for p in ps:
        kinds.setdefault(fx_label(p['fx'], p['note'], args.shift), []).append(p)
    keys = sorted(kinds, key=lambda k: (int(k.split()[1].rstrip(':')), k))
    fig, (a, b) = plt.subplots(2, 1, figsize=(12, 9.6), sharex=True, gridspec_kw={'height_ratios': [2.2, 1]})
    style(fig, (a, b))
    cmap = plt.get_cmap('tab20')
    for i, k in enumerate(keys):
        fr = [p['frame'] for p in kinds[k]]
        a.plot(fr, [i] * len(fr), '|', color=cmap(i % 20), ms=10, mew=1.3)
        a.text(f1 + (f1 - f0) * 0.005, i, str(len(fr)), va='center', color=FG, fontsize=8.5)
    for u in ups:
        a.axvspan(u['frame'], u['frame_end'] + 1, color=RED, alpha=0.25)
        if u['n'] > 20000:
            right = u['frame_end'] > f0 + 0.8 * (f1 - f0)
            a.text(u['frame'] - 15 if right else u['frame_end'] + 15, len(keys) - 0.4,
                   f'module upload,\n{u["n"]} bytes', color=RED, fontsize=8, va='top', ha='right' if right else 'left')
    a.set_yticks(range(len(keys)))
    a.set_yticklabels(keys, fontsize=8.5)
    a.set_ylim(-0.7, len(keys) + 0.3)
    if args.bot:
        tsv = [ln.split('\t') for ln in open(args.bot).read().splitlines()[1:]]
        prev = None
        for r in tsv:
            fr = int(r[0]) + args.bot_offset
            w = int(r[2])
            if prev is not None and w != prev and f0 <= fr <= f1:
                a.axvline(fr, color=CYAN, lw=0.8, ls='--')
                a.text(fr, -0.65, ['none', '', 'plasma', 'homing', 'seeker'][w], color=CYAN, fontsize=7.5, rotation=90,
                       va='bottom', ha='right')
            prev = w
    a.set_title(f'{len(ps)} plays in frames {f0}-{f1}, one row per game event (count at the right); red bands: '
                'uploads, the game stopped', loc='left', fontsize=10, color=FG)
    waits = command_waits(rows, f0, f1)
    groups = [((0x2E,), BLUE, '#2E select FX'), ((0x40,), GREEN, '#40 note'), ((0x80, 0x81, 0x82, 0x83), YELLOW,
              '#80+c play in channel c'), ((0x45, 0x39), VIOLET, '#45 / #39 (the card picks the channel)')]
    allw = np.array([w['wait'] for w in waits])
    for members, colour, label in groups:
        sel = [w for w in waits if w['cmd'] in members]
        b.semilogy([w['frame'] for w in sel], [max(w['wait'], 1) for w in sel], '.', color=colour, ms=3.5,
                   label=f'{label}: {len(sel)}')
    med = float(np.median(allw)) if len(allw) else 0
    b.axhline(med, color=DIM, ls='--', lw=0.8)
    b.text(f0, med * 0.55, f'median {med:.0f} T', color=DIM, fontsize=8.5)
    b.axhline(FRAME_T, color=RED, lw=0.8)
    b.text(f0, FRAME_T * 1.15, 'one frame, 71 680 T', color=RED, fontsize=8.5)
    b.legend(loc='upper right', ncol=4, facecolor=AX, edgecolor=DIM, labelcolor=FG, fontsize=7.5)
    b.set_ylim(100, 400000)
    b.set_ylabel('T-states from the OUT\nto "command taken"')
    b.set_xlabel(f'frame of the recording ({args.label})')
    tot = allw.sum()
    b.set_title(f'the host polls \\$BB after every command until bit 0 clears: {len(allw)} commands, '
                f'{tot / (FRAME_T * (f1 - f0)) * 100:.1f} % of the Spectrum\'s time;\n'
                f'{(allw > 15000).sum()} waits over 15 000 T; medians: ' + ', '.join(
                    f'{lab.split()[0]} {np.median([w["wait"] for w in waits if w["cmd"] in mem]):.0f} T'
                    for mem, _, lab in groups if any(w['cmd'] in mem for w in waits)),
                loc='left', fontsize=10, color=FG)
    fig.suptitle(args.title, color=FG, fontsize=13)
    fig.subplots_adjust(left=0.25, right=0.96, top=0.9, bottom=0.07, hspace=0.18)
    save(fig, args.out)
    if args.json:
        json.dump({'plays': [{k: v for k, v in p.items() if k != 'parts'} for p in ps],
                   'uploads': [{k: u[k] for k in ('frame', 'frame_end', 'n', 'pc')} for u in ups],
                   'other': [{'cmd': c['cmd'], 'data': c['data'], 'frame': c['frame'], 'wait': c['wait']}
                             for c in other]}, open(args.json, 'w'), indent=0)
        print('wrote', args.json)
    for k in keys:
        print(f'{k}: {len(kinds[k])}')


def fig_handshake(args):
    """One play zoomed in: every OUT and every poll of one effect, T-state by T-state"""
    rows = load_ports(args.ports)
    conv = conversation(rows)
    ps = [p for p in plays(conv) if p['frame'] >= (args.frm or 0)]
    want = [p for p in ps if (args.fx is None or p['fx'] == args.fx)]
    p = want[0]
    t0 = p['t'] - 200
    t1 = p['t'] + p['span'] + 300
    sel = [d for d in rows if t0 <= d['t'] <= t1]
    fig, a = plt.subplots(figsize=(12, 4.6))
    style(fig, (a,))
    lanes = {'OUT \\$B3 data': 3, 'OUT \\$BB command': 2, 'IN \\$BB status': 1}
    cmdname = {0x2E: '#2E select FX', 0x40: '#40 note', 0x39: '#39 play', 0x45: '#45 volume'}
    polls = 0
    for d in sel:
        x = d['t'] - p['t']
        port = d['port'] & 0xFF
        if d['dir'] == 'out' and port == 0xB3:
            a.plot(x, 3, 'v', color=YELLOW, ms=9)
            a.annotate(f'\\${d["value"]:02X}', (x, 3), (0, 8), textcoords='offset points', ha='center', color=FG,
                       fontsize=8.5)
        elif d['dir'] == 'out' and port == 0xBB:
            a.plot(x, 2, 'v', color=ORANGE, ms=9)
            nm = cmdname.get(d['value'], f'#{d["value"]:02X} play in ch. {d["value"] - 0x80}' if d['value'] >= 0x80 else f'#{d["value"]:02X}')
            a.annotate(nm, (x, 2), (0, 8), textcoords='offset points', ha='center', color=FG, fontsize=8.5)
        elif d['dir'] == 'in' and port == 0xBB:
            polls += 1
            bit0, bit7 = d['value'] & 1, d['value'] >> 7
            a.plot(x, 1 + 0.12 * (bit7 - bit0) * 0, '|', color=RED if (bit0 or bit7) else GREEN, ms=12)
    a.set_yticks(list(lanes.values()))
    a.set_yticklabels(list(lanes.keys()))
    a.set_ylim(0.4, 3.7)
    a.set_xlabel(f'T-states from the OUT of the #2E command (frame {p["frame"]}; 3.5 MHz, so 1000 T = 286 µs)')
    a.set_title(f'{polls} status polls: red = the card has not yet taken the byte or command (bit 7 / bit 0 set), '
                'green = taken; the next OUT follows only a green poll', loc='left', fontsize=10, color=FG)
    fig.suptitle(f'One play ({fx_label(p["fx"], p["note"], args.shift)}, handle {p["fx"]}, note \\${p["note"]:02X}): '
                 f'{p["span"]} T, the host waits on the card after every byte', color=FG, fontsize=13)
    fig.subplots_adjust(left=0.14, right=0.98, top=0.82, bottom=0.14)
    save(fig, args.out)


def fig_upload(args):
    """A level change in music mode: the commands and the stream, frame by frame"""
    rows = load_ports(args.ports)
    conv = conversation(rows)
    f0, f1 = args.frm, args.to
    seg = [c for c in conv if f0 <= c['frame'] <= f1]
    fig, a = plt.subplots(figsize=(12, 5.4))
    style(fig, (a,))
    y = 0
    labels = []
    cmdname = {0x23: '#23 pages?', 0xF3: '#F3 warm reset', 0x30: '#30 load module', 0x38: '#38 load FX',
               0xD1: '#D1 open stream', 0xD2: '#D2 close', 0x2A: '#2A module volume', 0x2B: '#2B FX volume',
               0x31: '#31 play module', 0x32: '#32 stop module', 0x2E: '#2E select', 0x40: '#40 note'}
    streams = [c for c in seg if c['cmd'] == 'stream']
    for c in streams:
        a.barh(0, c['frame_end'] - c['frame'] + 1, left=c['frame'], color=GREEN if c['n'] > 20000 else BLUE,
               height=0.6, edgecolor=BG)
        if c['frame_end'] - c['frame'] >= 0.035 * (f1 - f0):
            a.text((c['frame'] + c['frame_end']) / 2, 0, f'{c["n"]}', ha='center', va='center', color='black',
                   fontsize=8)
    cmds = [c for c in seg if c['cmd'] != 'stream' and c['cmd'] not in (0xD1, 0xD2)]
    seen = {}
    for c in cmds:
        nm = cmdname.get(c['cmd'], f'#{c["cmd"]:02X}' + (' play FX' if c['cmd'] >= 0x80 else ''))
        k = seen.setdefault(nm, len(seen) + 1)
        a.plot(c['frame'], k, 'o', color=ORANGE, ms=5)
    a.set_yticks([0] + list(seen.values()))
    a.set_yticklabels(['the stream (bytes)'] + list(seen.keys()), fontsize=8.5)
    a.set_xlabel('frame')
    nmod = sum(c['n'] for c in streams if c['n'] > 20000)
    nfx = sum(c['n'] for c in streams if c['n'] <= 20000)
    nfxs = sum(1 for c in streams if c['n'] <= 20000)
    a.set_title((f'green: the module ({nmod} bytes); ' if nmod else 'no module; ') +
                f'blue: {nfxs} effect streams, {nfx} bytes, the first the jingle; {f1 - f0} frames, the game frozen '
                'meanwhile', loc='left', fontsize=10, color=FG)
    fig.suptitle(args.title, color=FG, fontsize=13)
    fig.subplots_adjust(left=0.2, right=0.98, top=0.86, bottom=0.12)
    save(fig, args.out)


# --- the card's pages ------------------------------------------------------------------------------------------

def fig_cardmap(args):
    """The card's sample memory on 128 KB (RAMPG 02 03 04 01, page 1 a half page) and 512 KB (pages 2-15 whole)"""
    media = json.load(open(os.path.join(CASE, 'work/media/gs/media.json')))
    fx = {os.path.basename(e['file']).split('.')[0]: e['bytes'] for e in media['fx']}
    mods = {os.path.basename(e['file']).split('.')[0]: e['bytes'] for e in media['mod']}
    loads = [
        ('music, level 1 (the largest module)', [('module 1', mods['level01'], GREEN)] +
         [(f'FX {n}', fx[f'fx{n:02d}'], BLUE) for n in range(1, 11)]),
        ('music, the title', [('module 13', mods['level13'], GREEN)]),
        ('effects only (128 KB: reloaded each level)', [(f'FX {n}', fx[f'fx{n:02d}'], VIOLET if n > 10 else BLUE)
                                                         for n in range(1, 22)]),
    ]
    fig, axes = plt.subplots(2, 1, figsize=(12, 8.2), gridspec_kw={'height_ratios': [1.1, 1]})
    style(fig, axes)
    # 128 KB: order 2, 3, 4, then page 1 low half
    a = axes[0]
    pages = [('page 2\n\\$08000-\\$0FFFF', 32768), ('page 3\n\\$10000-\\$17FFF', 32768),
             ('page 4\n\\$18000-\\$1FFFF', 32768), ('page 1, half\n\\$00000-\\$03FFF', 16384)]
    room = sum(p[1] for p in pages)
    x = 0
    for nm, n in pages:
        a.add_patch(plt.Rectangle((x / 1024, 3.3), n / 1024, 0.6, facecolor='#2c3140', edgecolor=FG))
        a.text((x + n / 2) / 1024, 3.6, nm, ha='center', va='center', color=FG, fontsize=9)
        x += n
    a.add_patch(plt.Rectangle((x / 1024, 3.3), 16384 / 1024, 0.6, facecolor='#3a2020', edgecolor=RED, hatch='//'))
    a.text((x + 16384) / 1024 + 1, 3.6, 'page 1 upper half (\\$04000-\\$07FFF):\nthe firmware\'s work memory,\n'
           'its fixed window at \\$4000-\\$7FFF', ha='left', va='center', color=RED, fontsize=7.5)
    for i, (nm, parts) in enumerate(loads):
        yy = 2.3 - i * 0.9
        x = 0
        for lab, n, col in parts:
            a.add_patch(plt.Rectangle((x / 1024, yy), n / 1024, 0.55, facecolor=col, edgecolor=BG, lw=0.5))
            if n > 5000:
                a.text((x + n / 2) / 1024, yy + 0.27, lab.replace('module ', 'mod '), ha='center', va='center',
                       color='black', fontsize=7)
            x += n
        a.text(-2, yy + 0.27, nm, ha='right', va='center', color=FG, fontsize=8.5)
        a.text(min(x / 1024, 112) + 1, yy + 0.27 + (0.35 if i == 2 else 0), f'{x} B, {room - x} left', va='center',
               color=YELLOW, fontsize=8.5)
    for b_ in (32, 64, 96):
        a.axvline(b_, color=DIM, lw=0.6, ls=':')
    a.axvline(room / 1024, color=RED, lw=1.2)
    a.text(room / 1024 + 1, 0.75, 'the end of the room: the loader\nreads and drops any byte past it',
           color=RED, fontsize=8, va='center')
    a.set_xlim(-75, 175)
    a.set_ylim(0.3, 4.1)
    a.set_yticks([])
    a.set_xticks([0, 32, 64, 96, 112, 128])
    a.set_xlabel('KB of sample room in load order (RAMPG = 02 03 04 01, NUMPG 3: 96 KB + 16 KB = 114 688 bytes)')
    a.set_title('GS 128 KB: every load fits; what stage 1 read as an overrun is the half page 1, card RAM \\$00000-\\$03FFF',
                loc='left', fontsize=10.5, color=FG)
    b = axes[1]
    b.set_title('GS 512 KB: #23 answers 15 whole pages (2-16, 480 KB) + the half page 1. Effects only: the driver '
                'patches itself and loads once', loc='left', fontsize=10.5, color=FG)
    x = 0
    for n in range(2, 17):
        b.add_patch(plt.Rectangle((x, 1.6), 32, 0.6, facecolor='#2c3140', edgecolor=FG))
        b.text(x + 16, 1.9, f'page {n}', ha='center', va='center', color=FG, fontsize=7.5)
        x += 32
    b.add_patch(plt.Rectangle((x, 1.6), 16, 0.6, facecolor='#2c3140', edgecolor=FG))
    b.text(x + 8, 1.9, '1/2', ha='center', va='center', color=FG, fontsize=7)
    parts = [('start', fx['fx-start'], ORANGE)] + [(f'FX {n}', fx[f'fx{n:02d}'], VIOLET if n > 10 else BLUE)
                                                  for n in range(1, 22)]
    x = 0
    for lab, n, col in parts:
        b.add_patch(plt.Rectangle((x / 1024, 0.6), n / 1024, 0.6, facecolor=col, edgecolor=BG, lw=0.5))
        x += n
    b.text(x / 1024 + 3, 0.9, f'effects only: handles 1-22, the jingle + 21 FX, {x} bytes, loaded once;\n'
           'the driver then sends handle = FX + 1 (INC L at \\$C23B, \\$C260),\nbut SaturnSound gets + 1 twice: '
           'handle 23, which the card refuses (FX 21 never sounds)', va='center', color=YELLOW, fontsize=8.5)
    b.text(0, 2.35, 'music mode: as on 128 KB, the module + FX 1-10 reloaded at every level change (pages 2-5)',
           color=FG, fontsize=8.5)
    b.set_xlim(-5, 505)
    b.set_ylim(0.3, 2.6)
    b.set_yticks([])
    b.set_xlabel('KB of card RAM in load order')
    fig.suptitle('Where the uploads land on the card: 128 KB vs 512 KB', color=FG, fontsize=13)
    fig.subplots_adjust(left=0.03, right=0.98, top=0.9, bottom=0.08, hspace=0.42)
    save(fig, args.out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('figure', choices=['modules', 'overview', 'effects', 'hooks', 'timeline', 'handshake', 'upload',
                                       'cardmap'])
    ap.add_argument('--out', required=True)
    ap.add_argument('--renders', default=os.path.join(CASE, 'work/audio/fx'))
    ap.add_argument('--ports')
    ap.add_argument('--bot')
    ap.add_argument('--bot-offset', type=int, default=0)
    ap.add_argument('--from', dest='frm', type=int)
    ap.add_argument('--to', type=int)
    ap.add_argument('--fx', type=int)
    ap.add_argument('--shift', type=int, default=0)
    ap.add_argument('--title', default='')
    ap.add_argument('--label', default='')
    ap.add_argument('--json')
    ap.add_argument('--run', dest='runs', nargs=3, action='append', default=[], metavar=('TAG', 'COUNTS', 'MODE'))
    args = ap.parse_args()
    {'modules': fig_modules, 'overview': fig_overview, 'effects': fig_effects, 'hooks': fig_hooks,
     'timeline': fig_timeline, 'handshake': fig_handshake, 'upload': fig_upload, 'cardmap': fig_cardmap}[args.figure](args)


if __name__ == '__main__':
    main()
