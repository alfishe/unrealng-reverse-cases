#!/usr/bin/env python3
"""Doc 10's figures: the speed model against c1, the steering model's numbers, the score and the timer over c1, and
the technique runs (tools/play_techniques.py) against their control.

    python3 tools/fig_gameplay.py speed  docs/img/gameplay/speed.png  C1VARS.jsonl
    python3 tools/fig_gameplay.py steer  docs/img/gameplay/steer.png
    python3 tools/fig_gameplay.py score  docs/img/gameplay/score.png  C1VARS.jsonl
    python3 tools/fig_gameplay.py techniques docs/img/gameplay/techniques.png TECHDIR C1VARS.jsonl

C1VARS is a sampling of c1 (the frame and the game's variables at `$5C80-$5E7F`, `$7C2E-$7C53`, `$9136-$9178`,
`$A1C9-$A1CB` every frame or two, from the case's TTD instance). The model's constants are read from the image
(build/game.bin): SteerTable `$8E5D`, LeanTable `$8E56`, the throttle's operands at `$AA0A`-`$AA36`.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
IMAGE = os.path.join(CASE, 'build', 'game.bin')
BASE = 0x5B00


def image():
    return open(IMAGE, 'rb').read()


def byte(a):
    return image()[a - BASE]


def word(a):
    d = image()
    return d[a - BASE] | d[a - BASE + 1] << 8


def throttle(hl):
    """One pass of Throttle with THROTTLE held (`$AA03`)"""
    h = hl >> 8
    if h < 0x14:
        de = (hl + 0x100) >> 2
    elif h < 0xA0:
        de = 0x0220
    else:
        de = (0xC800 - hl) >> 4
    return min(hl + de, 0xFFFF)


def model_speed(passes):
    hl, out = 0, []
    for _ in range(passes):
        out.append(hl >> 8)
        hl = throttle(hl)
    return out


def c1_rows(path):
    rows = []
    for line in open(path):
        r = json.loads(line)
        mem = {}
        for k, v in r.items():
            if k == 'f' or v is None:
                continue
            b = bytes.fromhex(v)
            base = int(k, 16)
            for i, x in enumerate(b):
                mem[base + i] = x
        rows.append((r['f'], mem))
    return rows


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11})
    return plt


def cmd_speed(out, c1_path):
    plt = plt_setup()
    rows = c1_rows(c1_path)
    # c1 from the countdown's 7 (THROTTLE accepted) to the first bounce (15 175): THROTTLE held, a weave of taps
    passes, speeds, last = [], [], None
    for f, m in rows:
        if f < 14105 or f > 15174:
            continue
        pc = m[0x7C2E]
        if pc != last:
            passes.append(len(passes))
            speeds.append(m[0x7C34])
            last = pc
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.6), dpi=100)
    ax = axes[0]
    model = model_speed(len(passes))
    ax.plot(passes, speeds, '.', ms=4, label='c1: SPEED a pass (frames 14 105-15 174)')
    ax.plot(range(len(model)), model, '-', lw=1.2, color='#d62728', label='the model: THROTTLE every pass')
    ax.axhline(0x14, color='#999999', lw=0.7, ls=':')
    ax.axhline(0xA0, color='#999999', lw=0.7, ls=':')
    ax.text(len(model) * 0.02, 0x14 + 3, 'SPEED 20', fontsize=10, color='#555555')
    ax.annotate('BRAKES (14 515), then PAUSE', xy=(52, 62), xytext=(3, 118), fontsize=10,
                arrowprops={'arrowstyle': '->', 'lw': 0.8})
    ax.annotate('full lean: x 255/256 a pass', xy=(100, 155), xytext=(62, 28), fontsize=10,
                arrowprops={'arrowstyle': '->', 'lw': 0.8})
    ax.text(len(model) * 0.02, 0xA0 + 3, 'SPEED 160', fontsize=10, color='#555555')
    ax.set_xlabel('passes from the countdown\'s 7')
    ax.set_ylabel('SPEED (km/h), the high byte of $7C33')
    ax.set_title('Throttle held: the model against c1')
    ax.legend(loc='upper left', fontsize=10, bbox_to_anchor=(0, 0.93))
    ax.set_ylim(0, 215)
    ax = axes[1]
    xs = list(range(0, 200))
    gain = [(throttle(s << 8) - (s << 8)) / 256 for s in xs]
    ax.plot(xs, gain, color='#1f77b4', lw=1.5, label='THROTTLE: SPEED gained a pass')
    ax.plot(xs, [-0x0580 / 256] * len(xs), color='#d62728', lw=1.2, label='BRAKES: -5.5 a pass')
    ax.plot(xs, [-0x0940 / 256] * len(xs), color='#9467bd', lw=1.2, ls='--', label='timer at 0: -9.25 a pass')
    ax.plot(xs, [-(s - (s * 0xD0 >> 8)) for s in xs], color='#8c564b', lw=1.2, ls='-.',
            label='falling: x 208/256 a pass')
    ax.plot(xs, [-(s - (s * 0xFA >> 8)) for s in xs], color='#2ca02c', lw=1.0, ls=':',
            label='bouncing: x 250/256 a pass')
    ax.axhline(0, color='black', lw=0.6)
    ax.set_xlabel('SPEED (km/h)')
    ax.set_ylabel('change a pass (km/h)')
    ax.set_title('The change of SPEED in one pass')
    ax.legend(loc='lower left', fontsize=10)
    ax.set_ylim(-40, 6)
    fig.tight_layout()
    fig.savefig(out)


def cmd_steer(out):
    plt = plt_setup()
    d = image()
    steer = [d[0x8E5D - BASE + 2 * i] for i in range(11)]
    lean = [d[0x8E56 - BASE + i] for i in range(7)]
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.6), dpi=100)
    ax = axes[0]
    speeds = list(range(0, 201))
    for k, col in ((1, '#2ca02c'), (2, '#ff7f0e'), (3, '#d62728')):
        ys = []
        for s in speeds:
            hi = (s * 14) >> 8
            v = steer[hi] * lean[k + 3] >> 3
            if v >> 8 >= 5:
                v = 0x500 | (v & 0xFF)
            ys.append(v / 256)
        ax.plot(speeds, ys, color=col, lw=1.4, label=f'lean {k}: the steering')
    for k, (f, col) in enumerate(((0x52, '#7f7f7f'), (0x8F, '#1f77b4'), (0xA4, '#9467bd')), 1):
        ys = [((s * 14) >> 8) * f / 256 for s in speeds]
        ax.plot(speeds, ys, color=col, lw=1.0, ls='--', label=f'bend {k}: the push')
    ax.set_xlabel('SPEED (km/h)')
    ax.set_ylabel('LateralX units a pass')
    ax.set_title('Steering against a bend\'s push (stages 1, 3, 5)')
    ax.legend(loc='upper center', fontsize=10, ncol=2)
    ax.set_ylim(0, 9.6)
    ax = axes[1]
    s = 199
    hi = (s * 14) >> 8
    labels, vals = [], []
    for k in (1, 2, 3):
        v = steer[hi] * lean[k + 3] >> 3
        labels.append(f'lean {k}')
        vals.append(min(v / 256, 5 + (v & 0xFF) / 256))
    for k, f in enumerate((0x52, 0x8F, 0xA4), 1):
        labels.append(f'bend {k}')
        vals.append(hi * f / 256)
        labels.append(f'bend {k}, x2')
        vals.append(2 * hi * f / 256)
    cols = ['#2ca02c', '#ff7f0e', '#d62728'] + ['#7f7f7f', '#bbbbbb', '#1f77b4', '#9ecae1', '#9467bd', '#c5b0d5']
    ax.barh(range(len(vals)), vals, color=cols)
    ax.set_yticks(range(len(vals)))
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    for i, v in enumerate(vals):
        ax.text(v + 0.1, i, f'{v:.2f}', va='center', fontsize=10)
    ax.set_xlim(0, 15)
    ax.set_xlabel('LateralX units a pass at SPEED 199 (ScrollStep high byte 10)')
    ax.set_title('At full speed (x2: stages 2 and 4)')
    fig.tight_layout()
    fig.savefig(out)


def cmd_score(out, c1_path):
    plt = plt_setup()
    rows = c1_rows(c1_path)
    fs, score, timer, speed, air, fall = [], [], [], [], [], []
    for f, m in rows:
        if f < 14075 or f > 19300:
            continue
        txt = bytes(m[0x5E18 + i] for i in range(7)).decode('latin1').strip()
        if m[0x5E24] == 0x10 or not txt:
            continue  # PlayTurn's swap of the player blocks caught half way (19 069): the other block's zeros
        fs.append(f)
        score.append(int(txt) if txt else 0)
        t = m[0x5E1F]
        timer.append((t >> 4) * 10 + (t & 15) + (m[0x5E20] % 10) / 10)
        speed.append(m[0x7C34])
        air.append(m[0x5CEA] != 0 and m[0x916E] == 0)
        fall.append(m[0x916E] != 0)
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 6.6), dpi=100, sharex=True)
    ax = axes[0]
    ax.plot(fs, [s / 1000 for s in score], color='#1f77b4', lw=1.4, label='SCORE (thousands)')
    for i in range(1, len(fs)):
        if air[i]:
            ax.axvspan(fs[i - 1], fs[i], color='#ffd8a8', lw=0)
        if fall[i]:
            ax.axvspan(fs[i - 1], fs[i], color='#f4b6b6', lw=0)
    ax.set_ylabel('SCORE / 1000')
    ax.set_title('c1, stage 1: the score grows by SPEED a pass, ten times faster in the air (orange); '
                 'a fall (red) adds nothing', fontsize=11)
    ax.legend(loc='upper left', fontsize=10)
    ax = axes[1]
    ax.plot(fs, speed, color='#7f7f7f', lw=1.0, label='SPEED (km/h)')
    ax2 = ax.twinx()
    ax2.plot(fs, timer, color='#d62728', lw=1.4, label='TIME (timer seconds)')
    ax2.set_ylabel('TIME, red')
    ax.set_ylabel('SPEED, grey')
    ax.set_xlabel('TTD frame')
    ax.set_title('The timer: one second for ten passes (about 87 frames, 1.75 s); at 0 the bike rolls to a stop',
                 fontsize=11)
    fig.tight_layout()
    fig.savefig(out)


def cmd_techniques(out, tech_dir, c1_path):
    plt = plt_setup()

    def load(name):
        rows = [json.loads(l) for l in open(os.path.join(tech_dir, name + '.jsonl'))][1:-1]
        return [r['f'] for r in rows], rows

    fig, axes = plt.subplots(2, 2, figsize=(10.5, 7.4), dpi=100)
    f0, r0 = load('ramp-plain')
    f1, r1 = load('ramp-wheelie')
    ax = axes[0][0]
    ax.plot(f0, [r['Speed'] >> 8 for r in r0], color='#7f7f7f', lw=1.4, label='c1 (no wheelie)')
    ax.plot(f1, [r['Speed'] >> 8 for r in r1], color='#d62728', lw=1.4, label='WHEELIE from 15 380')
    ax.axvline(15486, color='black', lw=0.6, ls=':')
    ax.text(15490, 160, 'the ramp (15 486)', fontsize=10)
    ax.set_ylabel('SPEED')
    ax.set_title('A wheelie into a ramp keeps the speed')
    ax.legend(loc='lower left', fontsize=10)
    ax.set_xlim(15380, 15640)
    ax = axes[0][1]
    ax.plot(f0, [r['JumpHeight'] / 256 for r in r0], color='#7f7f7f', lw=1.4, label='c1: pose 2')
    ax.plot(f1, [r['JumpHeight'] / 256 for r in r1], color='#d62728', lw=1.4, label='13 wheelie passes: pose 1')
    ax.set_ylabel('JumpHeight (rows)')
    ax.set_title('and flies higher and further')
    ax.legend(loc='upper right', fontsize=10)
    ax.set_xlim(15460, 15660)
    f2, r2 = load('land-wheelie')
    ax = axes[1][0]
    ax.plot(f0, [r['Speed'] >> 8 for r in r0], color='#7f7f7f', lw=1.4, label='c1: a 6-pass bounce')
    ax.plot(f2, [r['Speed'] >> 8 for r in r2], color='#2ca02c', lw=1.4, label='WHEELIE at the landing')
    ax.set_xlim(15590, 15700)
    ax.set_ylabel('SPEED')
    ax.set_xlabel('frame')
    ax.set_title('A wheelie at the landing: no bounce')
    ax.legend(loc='lower left', fontsize=10)
    f3, r3 = load('brake-bend')
    ax = axes[1][1]
    c1 = [(f, m[0x7C34]) for f, m in c1_rows(c1_path) if 15100 <= f <= 15320]
    ax.plot([f for f, _ in c1], [s for _, s in c1], color='#7f7f7f', lw=1.4, label='c1: rider 1 hit at 15 175')
    ax.plot(f3, [r['Speed'] >> 8 for r in r3], color='#1f77b4', lw=1.4, label='BRAKES 15 130-15 170: no hit')
    ax.axvspan(15130, 15170, color='#e8f0ff', lw=0)
    ax.set_xlabel('frame')
    ax.set_ylabel('SPEED')
    ax.set_title('Braking behind a rider beats the hit')
    ax.legend(loc='lower right', fontsize=10)
    fig.tight_layout()
    fig.savefig(out)


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'speed':
        cmd_speed(sys.argv[2], sys.argv[3])
    elif cmd == 'steer':
        cmd_steer(sys.argv[2])
    elif cmd == 'score':
        cmd_score(sys.argv[2], sys.argv[3])
    elif cmd == 'techniques':
        cmd_techniques(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        sys.exit(__doc__)
