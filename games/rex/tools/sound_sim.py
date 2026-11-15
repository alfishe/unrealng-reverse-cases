#!/usr/bin/env python3
"""Rex's AY effects, run in SkoolKit's Z80 simulator from the case's build: SoundReset, StartSfx with a descriptor,
then SoundStep call after call, as the main loop calls it (twice a pass). The tables, the figures and the audio
renders of doc 9 (written, never played).

    python3 tools/sound_sim.py table [--part rex1|rex2|demo]   each effect: channel, noise, steps, its length in
                                                               SoundStep calls and in passes, the T-states a call
    python3 tools/sound_sim.py cost                            SoundStep's T-states with 0, 1, 2 and 3 channels busy
    python3 tools/sound_sim.py fig-effects OUT.png [--part P]  the 14 effects: volume and period, step by step
    python3 tools/sound_sim.py beeper OUT.png --trace T.uatr   the OUT ($FE) speaker and MIC bits of a trace
    python3 tools/sound_sim.py fig-trace OUT.png --trace T.uatr --listing build/game.lst [--title ..]
                                                               a recording's AY writes (an access trace) as a chart:
                                                               each channel's volume and period, the effects started
    python3 tools/sound_sim.py gaps --trace T.uatr             the T-states between SoundStep calls in a trace
    python3 tools/sound_sim.py wavs DIR [--part P]             each effect as a WAV (the step spacing measured, below)

The images: build/game.bin at $6018 (REX 1), build/rex2.bin and build/demo.bin at $61A8. The AY writes go through
SoundWrite: OUT ($FFFD) selects the register, OUT ($BFFD) writes it. AY clock 1 773 400 Hz (the 128K).

The spacing of the steps: the main loop has no interrupt and calls SoundStep twice a pass, once after UpdateObjects
and once after BufferToScreen and ClearBuffer. The two gaps (STEP_GAPS, T-states: the first call to the second, which
spans BufferToScreen, then the second to the next pass's first) were measured by `gaps` on the `c1` trace of TTD
frames 16976-16990 (8 calls, the means 214 143 and 57 181 T); the renders alternate them. Needs SkoolKit ($SKOOLKIT_VENV), numpy, matplotlib.
"""
import argparse
import glob
import os
import re
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AY_CLOCK = 1773400
CPU = 3546900
FRAME = 70908
STOP = 0x5BF0
LEVELS = (0.0, 0.0137, 0.0205, 0.0291, 0.0423, 0.0618, 0.0847, 0.1369, 0.1691, 0.2647, 0.3527, 0.4499,
          0.5704, 0.6873, 0.8482, 1.0)
PARTS = {'rex1': ('game', 0x6018), 'rex2': ('rex2', 0x61A8), 'demo': ('demo', 0x61A8)}
EFFECTS = ['SfxGun', 'SfxEnemyShot', 'SfxLaser', 'SfxSpray', 'SfxHitWall', 'SfxExplosion', 'SfxShield',
           'SfxMaterialise', 'SfxDematerialise', 'SfxBigPod', 'SfxPowerPod', 'SfxBombPod', 'SfxRestart',
           'SfxRecharge']
WHAT = {'SfxGun': 'the gun, double fire, multiple', 'SfxEnemyShot': 'an enemy shot', 'SfxLaser': 'the laser',
        'SfxSpray': 'the spray', 'SfxHitWall': 'a bullet stops', 'SfxExplosion': 'a kill, a death',
        'SfxShield': 'the shield hum', 'SfxMaterialise': 'Rex appears', 'SfxDematerialise': 'Rex vanishes',
        'SfxBigPod': 'a big power pod', 'SfxPowerPod': 'a power pod', 'SfxBombPod': 'a bomb pod',
        'SfxRestart': 'a restart marker', 'SfxRecharge': 'the recharger', 'SfxShieldHit': 'a shot on the shield'}
# measured on c1 TTD frames 16976-16990 (gaps): SoundStep 1 -> SoundStep 2, SoundStep 2 -> next pass's SoundStep 1
STEP_GAPS = (214143, 57181)
LINE = re.compile(r'^\s*\d+\+*\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):')


def labels(name):
    out = {}
    for line in open(os.path.join(ROOT, 'build', name + '.lst'), encoding='latin-1'):
        m = LINE.match(line)
        if m:
            out.setdefault(m.group(2), int(m.group(1), 16))
    return out


def skoolkit():
    venv = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    site = glob.glob(os.path.join(venv, 'lib', 'python3*', 'site-packages'))
    if not site:
        sys.exit(f'no SkoolKit at {venv} ($SKOOLKIT_VENV)')
    sys.path.insert(0, site[0])
    from skoolkit.simulator import Simulator
    from skoolkit import simutils
    return Simulator, simutils


class Ports:
    def __init__(self):
        self.select = 0
        self.regs = [0] * 16
        self.writes = []

    def write_port(self, registers, port, value, *rest):
        if port & 0xC002 == 0xC000:
            self.select = value & 15
        elif port & 0xC002 == 0x8000:
            self.regs[self.select] = value
            self.writes.append((self.select, value))


class Machine:
    """one part's image in the simulator; call(label) runs a routine to its RET"""

    def __init__(self, part='rex1'):
        Simulator, self.su = skoolkit()
        name, base = PARTS[part]
        self.L = labels(name)
        mem = bytearray(0x10000)
        image = open(os.path.join(ROOT, 'build', name + '.bin'), 'rb').read()
        mem[base:base + len(image)] = image
        mem[STOP] = 0x76
        self.mem = mem
        self.sim = Simulator(mem, {'SP': 0x5BE0})
        self.ports = Ports()
        self.sim.set_tracer(self.ports)

    def call(self, address, **regs):
        su = self.su
        reg = self.sim.registers
        for k, v in regs.items():
            if len(k) == 2:
                reg[getattr(su, k[0].upper())], reg[getattr(su, k[1].upper())] = v >> 8, v & 255
            else:
                reg[getattr(su, k.upper())] = v
        reg[su.SP] = 0x5BDE
        self.mem[0x5BDE], self.mem[0x5BDF] = STOP & 255, STOP >> 8
        self.ports.writes = []
        t0 = reg[su.T]
        self.sim.run(address, STOP)
        return reg[su.T] - t0

    def channel_busy(self, ch):
        return self.mem[self.L['Channels'] + 8 * ch] != 0xFF


def effect_names(m):
    names = [e for e in EFFECTS if e in m.L]
    if 'SfxShieldHit' in m.L:
        names.append('SfxShieldHit')
    return names


def run_effect(m, name, limit=400):
    """[(registers after the step, T-states of the call)] for each SoundStep until the channel is free again"""
    m.call(m.L['SoundReset'])
    addr = m.L[name]
    ch = m.mem[addr] - 1
    m.call(m.L['StartSfx'], de=addr)
    out = [(list(m.ports.regs), 0)]
    for _ in range(limit):
        t = m.call(m.L['SoundStep'])
        out.append((list(m.ports.regs), t))
        if not m.channel_busy(ch):
            break
    return ch, out


def descriptor(m, name):
    a = m.L[name]
    b = m.mem
    return b[a], b[a + 1], b[a + 2], b[a + 3], b[a + 4] | b[a + 5] << 8


def cmd_table(args):
    m = Machine(args.part)
    print('| Effect | Address | For | Channel | Tone or noise | Steps | Start volume | Start period | '
          'SoundStep calls | Passes | T a call (busy) |')
    print('| --- | --- | --- | --- | --- | ---: | ---: | --- | ---: | ---: | ---: |')
    for name in effect_names(m):
        c, noise, steps, vol, per = descriptor(m, name)
        ch, run = run_effect(m, name)
        n = len(run) - 1
        tbusy = max(t for _, t in run[1:])
        print(f'| {name} | `${m.L[name]:04X}` | {WHAT[name]} | {"ABC"[c - 1]} | {"noise" if noise else "tone"} | '
              f'{steps} | {vol >> 4} | `${per:04X}` | {n} | {n / 2:.1f} | {tbusy} |')


def cmd_cost(args):
    m = Machine(args.part)
    m.call(m.L['SoundReset'])
    print('idle', m.call(m.L['SoundStep']))
    names = ['SfxRestart', 'SfxEnemyShot', 'SfxGun']   # channels B, C, A: long ones
    for k, n in enumerate(names):
        m.call(m.L['StartSfx'], de=m.L[n])
        print(f'{k + 1} busy ({", ".join(names[:k + 1])})', m.call(m.L['SoundStep']), 'writes', len(m.ports.writes))


def timeline(run):
    """the registers of each step with the time it holds (seconds), the steps spaced by STEP_GAPS"""
    out = []
    for k, (regs, _) in enumerate(run):
        out.append((regs, STEP_GAPS[k % 2] / CPU))
    return out


def render(segs, rate=44100, tail=0.05):
    """[(14 registers, seconds)] -> mono float samples: tone squares, the 17-bit noise, fixed volumes"""
    import numpy as np
    total = int(sum(d for _, d in segs) * rate + tail * rate)
    out = np.zeros(total)
    lfsr = np.zeros(1 << 17, dtype=np.uint8)
    st = 1
    for i in range(len(lfsr)):
        lfsr[i] = st & 1
        st = (st >> 1) | (((st ^ (st >> 3)) & 1) << 16)
    phase = [0.0] * 3
    npos = 0.0
    lv = np.array(LEVELS)
    pos = 0
    for r, d in segs:
        n = int(round(d * rate))
        if pos + n > total:
            n = total - pos
        t = np.arange(n)
        ninc = AY_CLOCK / (16 * ((r[6] & 31) or 1)) / rate
        noise = lfsr[((npos + t * ninc).astype(np.int64)) % len(lfsr)]
        npos = (npos + n * ninc) % len(lfsr)
        for ch in range(3):
            p = ((r[2 * ch] | (r[2 * ch + 1] << 8)) & 0xFFF) or 1
            inc = AY_CLOCK / (16 * p) / rate
            ph = phase[ch] + t * inc
            phase[ch] = (phase[ch] + n * inc) % 1.0
            tone = (ph % 1.0) < 0.5 if inc < 0.5 else np.ones(n, dtype=bool)
            ton = not (r[7] >> ch) & 1
            non = not (r[7] >> (ch + 3)) & 1
            gate = (tone | (not ton)) & ((noise == 1) | (not non))
            out[pos:pos + n] += gate * lv[r[8 + ch] & 15]
        pos += n
    out -= np.convolve(out, np.ones(2205) / 2205, mode='same')
    return out / 3


def write_wav(path, samples, rate=44100):
    import numpy as np
    peak = np.abs(samples).max() or 1
    pcm = (samples / peak * 0.9 * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def cmd_wavs(args):
    m = Machine(args.part)
    os.makedirs(args.dir, exist_ok=True)
    for name in effect_names(m):
        ch, run = run_effect(m, name)
        segs = timeline(run)
        path = os.path.join(args.dir, f'{args.part}-{name}.wav')
        write_wav(path, render(segs))
        print(path, f'{sum(d for _, d in segs):.2f} s')


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 10, 'axes.titlesize': 10, 'figure.dpi': 100})
    return plt


def cmd_fig_effects(args):
    plt = plt_setup()
    m = Machine(args.part)
    names = effect_names(m)
    cols = 3
    rows = (len(names) + cols - 1) // cols
    fig, axes = plt.subplots(rows, cols, figsize=(10.5, 2.3 * rows + 0.8), squeeze=False)
    for k, name in enumerate(names):
        ax = axes[k // cols][k % cols]
        ch, run = run_effect(m, name)
        c, noise, steps, vol, per = descriptor(m, name)
        xs = list(range(len(run)))
        vols = [r[8 + ch] & 15 for r, _ in run]
        if noise:
            pers = [r[6] & 31 for r, _ in run]
        else:
            pers = [r[2 * ch] | (r[2 * ch + 1] & 15) << 8 for r, _ in run]
        ax.step(xs, vols, where='post', color='#d04040', lw=1.6)
        ax.set_ylim(-0.5, 15.5)
        ax.set_yticks([0, 5, 10, 15])
        ax.set_ylabel('volume', color='#d04040')
        ax2 = ax.twinx()
        ax2.step(xs, pers, where='post', color='#3060c0', lw=1.2)
        ax2.set_ylabel('noise period' if noise else 'tone period', color='#3060c0')
        ax.set_title(f'{name} ${m.L[name]:04X}, channel {"ABC"[ch]}\n{WHAT[name]}, {len(run) - 1} calls')
        ax.set_xlabel('SoundStep call (2 a pass)')
    for k in range(len(names), rows * cols):
        axes[k // cols][k % cols].axis('off')
    fig.suptitle(f'{args.part.upper()}: every AY effect run in the simulator from its descriptor: volume (red, left) '
                 'and period (blue, right) after each SoundStep call', fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    fig.savefig(args.out, dpi=100)
    print(args.out)


def load_trace(path):
    sys.path.insert(0, os.path.join(os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng'),
                                    'tools', 'verification', 'analysis'))
    import access_trace
    return access_trace.load(path)


def trace_events(tr, L):
    """(the AY writes [(T from the trace's start, register, value)], the StartSfx calls [(T, effect)],
    the SoundStep calls [T])"""
    units = max(1, tr.units_per_t)
    base = tr.from_frame * tr.frame_t + tr.from_t // units
    names = {L[e]: e for e in EFFECTS + ['SfxShieldHit'] if e in L}
    sel, writes, starts, steps = 0, [], [], []
    for x in tr.instructions:
        t = x.frame * tr.frame_t + x.t // units - base
        if x.pc == L['StartSfx']:
            starts.append((t, names.get(x.de, f'${x.de:04X}')))
        if x.pc == L['SoundStep']:
            steps.append(t)
        for c in x.cycles:
            if c.tag == 'O':
                if c.address & 0xC002 == 0xC000:
                    sel = c.value & 15
                elif c.address & 0xC002 == 0x8000:
                    writes.append((t, sel, c.value))
    return writes, starts, steps


def cmd_gaps(args):
    tr = load_trace(args.trace)
    L = labels(args.listing)
    _, _, steps = trace_events(tr, L)
    gaps = [b - a for a, b in zip(steps, steps[1:])]
    print('SoundStep calls', len(steps))
    print('gaps (T)', gaps)
    if len(gaps) >= 2:
        odd, even = gaps[0::2], gaps[1::2]
        print('mean of alternate gaps', sum(odd) // len(odd), sum(even) // len(even))


def cmd_fig_trace(args):
    """the AY registers over a traced window: each channel's volume (line) and tone period (dots, in AY units),
    the noise period and which channels the mixer gives noise, the StartSfx calls and the SoundStep calls"""
    plt = plt_setup()
    tr = load_trace(args.trace)
    L = labels(args.listing)
    writes, starts, steps = trace_events(tr, L)
    units = max(1, tr.units_per_t)
    f0 = tr.from_frame + tr.from_t / units / tr.frame_t
    end = tr.to_frame + tr.to_t / units / tr.frame_t
    regs = [0] * 16
    vol = {c: [] for c in range(3)}
    tone = {c: [] for c in range(3)}
    noise, mixer = [], []
    for t, r, v in writes:
        x = f0 + t / tr.frame_t
        regs[r] = v
        if 8 <= r <= 10:
            vol[r - 8].append((x, v & 15))
        elif r < 6:
            c = r // 2
            tone[c].append((x, regs[2 * c] | (regs[2 * c + 1] & 15) << 8))
        elif r == 6:
            noise.append((x, v & 31))
        elif r == 7:
            mixer.append((x, v))
    fig, axes = plt.subplots(5, 1, figsize=(10.5, 8.6), sharex=True,
                             gridspec_kw={'height_ratios': [1, 1, 1, 0.8, 0.8]})
    colours = ['#d04040', '#30a030', '#3060c0']
    for c in range(3):
        ax = axes[c]
        if vol[c]:
            ax.step([p[0] for p in vol[c]] + [end], [p[1] for p in vol[c]] + [vol[c][-1][1]], where='post',
                    color=colours[c], lw=1.4)
        ax.set_ylim(-0.5, 15.5)
        ax.set_ylabel(f'{"ABC"[c]} volume')
        ax2 = ax.twinx()
        if tone[c]:
            ax2.plot([p[0] for p in tone[c]], [p[1] for p in tone[c]], '.', ms=3, color='#606060')
        ax2.set_ylabel('tone period', color='#606060')
    ax = axes[3]
    if noise:
        ax.plot([p[0] for p in noise], [p[1] for p in noise], 'x', ms=4, color='#b07000')
    ax.set_ylim(-1, 32)
    ax.set_ylabel('noise period')
    ax2 = ax.twinx()
    for k, (x, v) in enumerate(mixer):
        x2 = mixer[k + 1][0] if k + 1 < len(mixer) else end
        for c in range(3):
            if not v & (8 << c):
                ax2.plot([x, x2], [c, c], color=colours[c], lw=3)
    ax2.set_ylim(-0.7, 2.7)
    ax2.set_yticks([0, 1, 2])
    ax2.set_yticklabels(['noise on A', 'noise on B', 'noise on C'])
    ax = axes[4]
    ys = {}
    for t, name in starts:
        y = ys.setdefault(name, len(ys))
        ax.plot([f0 + t / tr.frame_t], [y], 'v', color='#202020')
    ax.set_yticks(range(len(ys)))
    ax.set_yticklabels(list(ys))
    ax.set_ylim(-0.7, max(1, len(ys)) - 0.3)
    for t in steps:
        for a in axes:
            a.axvline(f0 + t / tr.frame_t, color='#d8d8d8', lw=0.5, zorder=0)
    ax.set_xlim(f0, end)
    ax.set_xlabel('TTD frame of the recording (grey lines: the SoundStep calls; triangles: StartSfx)')
    fig.suptitle(args.title, fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    fig.savefig(args.out, dpi=100)
    print(args.out, len(writes), 'writes', len(starts), 'starts', len(steps), 'SoundStep calls')


def cmd_beeper(args):
    """the beeper crackle: every OUT ($FE) of the traced window, its speaker (bit 4) and MIC (bit 3) bits, the whole
    window above, the first burst at T scale below"""
    plt = plt_setup()
    tr = load_trace(args.trace)
    units = max(1, tr.units_per_t)
    base = tr.from_frame * tr.frame_t + tr.from_t // units
    outs = []
    for x in tr.instructions:
        for c in x.cycles:
            if c.tag == 'O' and not c.address & 1:
                outs.append((x.frame * tr.frame_t + x.t // units - base, x.frame, x.pc, c.value))
    if not outs:
        raise SystemExit('no OUT ($FE) in the window')
    fig, axes = plt.subplots(2, 1, figsize=(10.5, 5.6))
    f0 = tr.from_frame + tr.from_t / units / tr.frame_t
    for ax, sel, scale, label in ((axes[0], outs, tr.frame_t, 'TTD frame'),
                                  (axes[1], [o for o in outs if o[1] == outs[0][1]], 1, 'T-states in the frame')):
        xs = [(o[0] / scale + f0) if scale != 1 else (o[0] - (o[1] - tr.from_frame) * tr.frame_t) for o in sel]
        spk = [(o[3] >> 4) & 1 for o in sel]
        mic = [(o[3] >> 3) & 1 for o in sel]
        ax.step(xs, [v + 2.2 for v in spk], where='post', color='#d04040', lw=1.4)
        ax.step(xs, mic, where='post', color='#3060c0', lw=1.4)
        ax.plot(xs, [v + 2.2 for v in spk], 'o', ms=3, color='#d04040')
        ax.plot(xs, mic, 'o', ms=3, color='#3060c0')
        ax.set_yticks([0, 1, 2.2, 3.2])
        ax.set_yticklabels(['MIC 0', 'MIC 1', 'speaker 0', 'speaker 1'])
        ax.set_xlabel(label)
        ax.grid(axis='x', color='#e0e0e0')
    axes[0].set_title(f'{len(outs)} OUT (FE hex) writes by DrawShard over the window; each a random value: (R x 2) AND F8 hex, border bits 0')
    axes[1].set_title(f'the first burst, frame {outs[0][1]}: one write a shard, six shards')
    fig.suptitle(args.title, fontsize=11)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    fig.savefig(args.out, dpi=100)
    print(args.out, len(outs), 'writes in frames', sorted(set(o[1] for o in outs)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('table', 'cost'):
        p = sub.add_parser(name)
        p.add_argument('--part', default='rex1', choices=PARTS)
    p = sub.add_parser('wavs')
    p.add_argument('dir')
    p.add_argument('--part', default='rex1', choices=PARTS)
    p = sub.add_parser('fig-effects')
    p.add_argument('out')
    p.add_argument('--part', default='rex1', choices=PARTS)
    p = sub.add_parser('gaps')
    p.add_argument('--trace', required=True)
    p.add_argument('--listing', default='game')
    p = sub.add_parser('fig-trace')
    p.add_argument('out')
    p.add_argument('--trace', required=True)
    p.add_argument('--listing', default='game')
    p.add_argument('--title', default='AY writes of a trace')
    p = sub.add_parser('beeper')
    p.add_argument('out')
    p.add_argument('--trace', required=True)
    p.add_argument('--title', default='The beeper crackle of an explosion')
    a = ap.parse_args()
    {'table': cmd_table, 'cost': cmd_cost, 'wavs': cmd_wavs, 'fig-effects': cmd_fig_effects, 'gaps': cmd_gaps,
     'beeper': cmd_beeper, 'fig-trace': cmd_fig_trace}[a.cmd](a)


if __name__ == '__main__':
    main()
