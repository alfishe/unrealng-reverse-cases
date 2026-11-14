#!/usr/bin/env python3
"""Doc 09's measurements, figures and audio: every beeper effect of Bumpy run on SkoolKit's Z80 simulator.

    python3 tools/fig_sound.py table     every effect: primitive, speaker edges, T-states, frames, pitch (printed)
    python3 tools/fig_sound.py wav       docs/img/sound/<effect>.wav: 44 100 Hz mono 16 bit (never played here)
    python3 tools/fig_sound.py waves     docs/img/sound/waves.png: the speaker bit of every effect against time
    python3 tools/fig_sound.py pitch     docs/img/sound/pitch.png: the half-period of each edge against time
    python3 tools/fig_sound.py ay        each effect's 16 parameter bytes read as AY registers 0-13 (printed)
    python3 tools/fig_sound.py all

The memory is the 48K ROM (SkoolKit's resources/48.rom) and the built code block build/game.bin at $61A8 (the
tape's bytes). Each effect is entered at its address with a return address 0 on the stack and runs until PC = 0.
Every OUT to an even port is logged with its T-state; the speaker is bit 4 (EAR) of the byte. The simulator counts
no memory or I/O contention: the code is above $8000 and only the OUT itself may wait for the ULA, a few T at most.
R starts at 0: the noise effects (RandomNoise1 and 2) take their delays from R, so a real run differs from this one
in detail but not in length class; TripleSweep loads R itself and is the same every time.
"""
import os
import struct
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(CASE))
OUT = os.path.join(CASE, 'docs', 'img', 'sound')
sys.path.insert(0, os.path.join(ROOT, 'kit'))
import z80sim  # noqa: E402

BASE = 0x61A8
FT = 69888
CLOCK = 3500000
RATE = 44100

# (address, label, file name, what triggers it, the primitive it calls)
EFFECTS = [
    (0xF3C8, 'SfxLand', 'land', 'a bounce or a take-off from a platform', 'SquareTone'),
    (0xF3DF, 'SfxHit', 'hit', 'a jump up from a platform', 'RomNoise ($04E6)'),
    (0xF3F6, 'SfxPickup', 'pickup', 'a prize, key, drop or hammer; a menu option', 'RandomNoise2'),
    (0xF40D, 'SfxExtraLife', 'extra-life', 'the bottle', 'TripleSweep'),
    (0xF427, 'SfxAnimA', 'water', 'a water drop falls on a fire', 'RumbleHigh'),
    (0xF43E, 'SfxWallBounce', 'wall-bounce', 'a wall turns the ball back; lock 3 opens a stage', 'SweepDown'),
    (0xF455, 'SfxLockA', 'lock-a', 'lock 2 opens a stage', 'RandomNoise1'),
    (0xF46C, 'SfxLockB', 'lock-b', 'lock 1 opens', 'RandomNoise2'),
    (0xF483, 'SfxFireDeath', 'fire-death', 'a landing on fire with no water', 'RumbleLow'),
    (0xF49A, 'SfxLevelEnd', 'level-end', 'the ball sunk into the exit', 'TripleSweep'),
    (0xF4B4, 'SfxSpikeDeath', 'spike-death', 'spikes', 'RumbleLow'),
    (0xF4CB, 'SfxLifeLost', 'life-lost', 'a fall out below, the S key', 'RumbleLow'),
    (0xF4E2, 'SfxAnimB', 'brick', 'a brick layer knocked off', 'RumbleHigh'),
    (0xF4F9, 'SfxTimerTick', 'timer-tick', 'one point of the timer counted in', 'SweepDown'),
    (0xF5BB, 'SfxUnused', 'unused', 'nothing calls it', 'RomRumble ($0BB8)'),
]


def memory():
    mem = bytearray(0x10000)
    venv = z80sim.need_skoolkit() or None  # noqa: F841 (makes skoolkit importable)
    import skoolkit
    rom = open(os.path.join(os.path.dirname(skoolkit.__file__), 'resources', '48.rom'), 'rb').read()
    mem[0:0x4000] = rom
    game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    mem[BASE:BASE + len(game)] = game
    return mem


class Outs:
    def __init__(self):
        self.edges = []

    def write_port(self, registers, port, value, offset=0):
        if port % 2 == 0:
            self.edges.append((registers[25], value))


def run(mem, address):
    """[(T from the call, byte written to $FE)], the T-states of the whole call"""
    from skoolkit.simulator import Simulator
    m = bytearray(mem)
    m[0x5FFE:0x6000] = b'\x00\x00'
    sim = Simulator(m, {'PC': address, 'SP': 0x5FFE, 'R': 0, 'T': 0})
    outs = Outs()
    sim.set_tracer(outs)
    sim.run(address, 0)
    return outs.edges, sim.registers[25]


def measure():
    mem = memory()
    rows = []
    for address, label, name, why, prim in EFFECTS:
        edges, total = run(mem, address)
        level = [(t, (v >> 4) & 1) for t, v in edges]
        flips = [t for i, (t, b) in enumerate(level) if i and b != level[i - 1][1]]
        halves = [b - a for a, b in zip(flips, flips[1:])]
        rows.append({'address': address, 'label': label, 'name': name, 'why': why, 'prim': prim,
                     'edges': level, 'outs': len(edges), 'flips': len(flips), 'T': total, 'halves': halves})
    return rows


def table(rows):
    print('| Effect | Primitive | OUTs | speaker flips | T-states | frames | half-periods (T): min / median / max |')
    print('| --- | --- | ---: | ---: | ---: | ---: | --- |')
    for r in rows:
        h = sorted(r['halves']) or [0]
        print('| %s `$%04X` | %s | %d | %d | %d | %.2f | %d / %d / %d |' % (
            r['label'], r['address'], r['prim'], r['outs'], r['flips'], r['T'], r['T'] / FT, h[0], h[len(h) // 2],
            h[-1]))


def wav(rows):
    os.makedirs(OUT, exist_ok=True)
    for r in rows:
        n = int(r['T'] * RATE / CLOCK) + RATE // 50
        samples = []
        edges = r['edges']
        k, level = 0, 0
        for i in range(n):
            t = i * CLOCK / RATE
            while k < len(edges) and edges[k][0] <= t:
                level = edges[k][1]
                k += 1
            samples.append(9000 if level else -9000)
        path = os.path.join(OUT, r['name'] + '.wav')
        with wave.open(path, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b''.join(struct.pack('<h', s) for s in samples))
        print('wav:', os.path.relpath(path, CASE), '%.3f s' % (n / RATE))


def plt_setup():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    plt.rcParams.update({'font.size': 11, 'figure.facecolor': '#101018', 'axes.facecolor': '#16161f',
                         'axes.edgecolor': '#888', 'axes.labelcolor': '#ddd', 'xtick.color': '#ccc',
                         'ytick.color': '#ccc', 'text.color': '#eee', 'text.parse_math': False})
    return plt


def waves(rows):
    plt = plt_setup()
    n = len(rows)
    cols = 2
    nr = (n + 1) // cols
    fig, axes = plt.subplots(nr, cols, figsize=(10.5, 1.25 * nr + 1.0), dpi=100)
    for ax in axes.flat[n:]:
        ax.axis('off')
    for ax, r in zip(axes.flat, rows):
        xs, ys = [], []
        prev = 0
        for t, b in r['edges']:
            ms = t / CLOCK * 1000
            xs += [ms, ms]
            ys += [prev, b]
            prev = b
        tend = r['T'] / CLOCK * 1000
        xs.append(tend)
        ys.append(prev)
        ax.plot(xs, ys, color='#f0c040', linewidth=0.5)
        ax.set_ylim(-0.25, 1.6)
        ax.set_yticks([])
        ax.set_xlim(0, tend)
        for f in range(1, int(tend / 20) + 1):
            ax.axvline(f * 20, color='#6080ff', linewidth=0.8)
        ax.text(0.01, 0.97, '%s $%04X: %s, %.0f ms = %.1f frames' % (r['label'], r['address'], r['prim'], tend,
                r['T'] / FT), transform=ax.transAxes, va='top', fontsize=10)
        ax.tick_params(labelsize=9)
    fig.suptitle('Every beeper effect: the speaker bit (bit 4 of port $FE) against ms from the call; blue lines '
                 'every 20 ms (one frame)', fontsize=12)
    fig.subplots_adjust(left=0.02, right=0.98, top=0.95, bottom=0.03, hspace=0.45, wspace=0.06)
    path = os.path.join(OUT, 'waves.png')
    fig.savefig(path)
    print('waves:', os.path.relpath(path, CASE))


def pitch(rows):
    plt = plt_setup()
    pick = [r for r in rows if r['label'] in ('SfxLand', 'SfxWallBounce', 'SfxExtraLife', 'SfxPickup', 'SfxHit',
                                              'SfxLifeLost')]
    fig, axes = plt.subplots(2, 3, figsize=(10.5, 6.2), dpi=100)
    for ax, r in zip(axes.flat, pick):
        flips = [t for i, (t, b) in enumerate(r['edges']) if i and b != r['edges'][i - 1][1]]
        xs = [a / CLOCK * 1000 for a in flips[1:]]
        ys = [b - a for a, b in zip(flips, flips[1:])]
        ax.plot(xs, ys, '.', markersize=3, color='#60c0ff')
        ax.set_title('%s $%04X (%s)' % (r['label'], r['address'], r['prim']), fontsize=10)
        ax.set_xlabel('ms from the call')
        ax.set_ylabel('half-period, T')
    fig.suptitle('The half-period of each speaker flip: sweeps fall in a line, noise scatters', fontsize=13)
    fig.tight_layout()
    path = os.path.join(OUT, 'pitch.png')
    fig.savefig(path)
    print('pitch:', os.path.relpath(path, CASE))


def ay():
    """The 16 bytes after each effect's LD HL (SfxLandParams ...) as the 14 AY registers WriteAyRegisters $F190
    would write: tone periods A-C (R0-R5), noise (R6), mixer (R7), volumes (R8-R10, bit 4 = the envelope), the
    envelope period (R11-R12) and shape (R13). Pitches at 1 MHz (the Amstrad CPC's AY clock) and at 1.7734 MHz (the
    Spectrum 128's)"""
    game = open(os.path.join(CASE, 'build', 'game.bin'), 'rb').read()
    print('| Effect | Tone A, B, C (period) | Noise | Mixer | Volumes | Envelope period, shape | Tones at 1 MHz (Hz) '
          '| Envelope cycle at 1 MHz (ms) |')
    print('| --- | --- | ---: | --- | --- | --- | --- | ---: |')
    for address, label, _, _, _ in EFFECTS:
        if label == 'SfxUnused':
            continue
        par = game[address + 1 - BASE] | game[address + 2 - BASE] << 8     # LD HL,params
        b = game[par - BASE:par + 16 - BASE]
        tones = [b[2 * i] | (b[2 * i + 1] & 15) << 8 for i in range(3)]
        env = b[11] | b[12] << 8
        hz = ', '.join('%.0f' % (1e6 / (16 * t)) if t else '-' for t in tones)
        print('| %s `$%04X` | %s | %d | `$%02X` | %s | %d, %d | %s | %.0f |' % (
            label, par, ', '.join(str(t) for t in tones), b[6] & 31, b[7],
            ' '.join('`$%02X`' % v for v in b[8:11]), env, b[13] & 15, hz, 256 * env / 1e6 * 1000))


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if what == 'ay':
        ay()
        return
    rows = measure()
    if what in ('table', 'all'):
        table(rows)
    if what in ('wav', 'all'):
        wav(rows)
    if what in ('waves', 'all'):
        waves(rows)
    if what in ('pitch', 'all'):
        pitch(rows)


if __name__ == '__main__':
    main()
