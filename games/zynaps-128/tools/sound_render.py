#!/usr/bin/env python3
"""The music of Zynaps 2 in 1 from the players' loaded images, without the emulator: the AY register stream of a
player run frame by frame in SkoolKit's Z80 simulator, its notes, a WAV (written, not played) and a chart.

    python3 tools/sound_render.py witness intro|game
    python3 tools/sound_render.py wav intro|game|ym:FILE --out OUT.wav [--frames N] [--clock HZ] [--stereo]
    python3 tools/sound_render.py notes intro|game|ym:FILE [--frames N] [--clock HZ]
    python3 tools/sound_render.py chart --out OUT.png [--frames N] SOURCE[@CLOCK] ...
    python3 tools/sound_render.py loop intro|game|ym:FILE [--frames N]

The sources:

    intro   the STarKos player with SK10 (build/sound/starkos-8000.bin at $8000): Init with DE = $8990 (the intro's
            $605E-$6061), then Play ($8003) once a frame, as the intro's IM 2 handler calls it
    game    the page-4 engine (build/sound/engine-c968.bin at $C968, engine-data-de48.bin at $DE48): StartMusic
            ($CA25, as the glue's $5B50 with A not 0), then PlayFrame ($CA60) once a frame, as the glue's interrupt
            handler; no effect is started
    ym:FILE a YM5 / YM6 register dump (uncompressed: the CPC Zynaps of cpc-power, unpacked with lha); its clock is in
            its header

The register writes go through ports $FFFD (the number) and $BFFD (the value), decoded as the 128K decodes them
(A15 = 1, A1 = 0; A14 picks select or write). The state at each frame's end is the frame's sound; R13 written in a
frame restarts the envelope. --clock is the AY clock the periods are played at: 1773400 (the 128K / +2, the default
for intro and game), 1750000 (the Pentagon), 1000000 (the Amstrad CPC). A note's name is the nearest tempered note
at A4 = 440 Hz, with the deviation in cents.

loop prints each channel's repeat: the shortest period after which its tone period, volume and mixer bits repeat
to the end of the run, and the frame it starts at. notes prints the pitch classes, the deviation from the tempered
notes and each channel's first periods as note names. chart draws the sounding notes of each SOURCE[@CLOCK] as dots
(time against pitch, one row a source; tones above 8 kHz are left out).

witness checks the simulation against the recording c1: the STarKos image after Init and 385 Play calls against
work/images/intro-title-bank2.bin ($8000-$90C4), the engine after StartMusic and 118 PlayFrame calls against
work/images/menu-bank4.bin ($C968-$CD22): the players' variables are all inside their images, so equal bytes mean
equal state.

Needs SkoolKit (the venv of unreal-ng's scratch, --venv or $SKOOLKIT_VENV), numpy, and for chart matplotlib.
"""
import argparse
import glob
import math
import os
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_VENV = '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit'
NAMES = ('C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B')
# AY-3-8912 output levels (SkoolKit's table: measured, 0..1)
DAC = (0x0000, 0x0385, 0x053D, 0x0770, 0x0AD7, 0x0FD5, 0x15B0, 0x230C,
       0x2B4C, 0x43C1, 0x5A4B, 0x732F, 0x9204, 0xAFF1, 0xD921, 0xFFFF)
STOP = 0xFF00  # a HALT the simulated calls return to


def skoolkit(venv):
    site = glob.glob(os.path.join(venv, 'lib', 'python3*', 'site-packages'))
    if not site:
        sys.exit(f'no SkoolKit venv at {venv} (--venv)')
    sys.path.insert(0, site[0])
    from skoolkit.simulator import Simulator
    return Simulator


class Ports:
    """The tracer: the AY writes of a frame"""

    def __init__(self):
        self.select, self.frame = 0, []

    def write_port(self, registers, port, value, *rest):
        if port & 0x8002 == 0x8000:
            if port & 0x4000:
                self.select = value & 15
            else:
                self.frame.append((self.select, value))


def part(name):
    for folder in ('build/sound', 'work/parts'):
        path = os.path.join(ROOT, folder, name)
        if os.path.exists(path):
            return open(path, 'rb').read()
    sys.exit(f'{name}: not in build/sound or work/parts (tools/build_sound.sh)')


class Player:
    """A player in the simulator: start() once, frame() once a frame (the AY writes of the frame)"""

    def __init__(self, kind, venv):
        Simulator = skoolkit(venv)
        mem = bytearray(0x10000)
        if kind == 'intro':
            image = part('starkos-8000.bin')
            mem[0x8000:0x8000 + len(image)] = image
            self.start_call, self.frame_call = (0x8000, 0x8990), 0x8003
        else:
            image = part('engine-c968.bin')
            mem[0xC968:0xC968 + len(image)] = image
            data = part('engine-data-de48.bin')
            mem[0xDE48:0xDE48 + len(data)] = data
            self.start_call, self.frame_call = (0xCA25, 0), 0xCA60
        mem[STOP] = 0x76
        self.mem = mem
        self.sim = Simulator(mem, {'SP': 0xFEF0})
        self.ports = Ports()
        self.sim.set_tracer(self.ports)

    def call(self, address, de=0):
        from skoolkit.simutils import D, E, SP
        reg = self.sim.registers
        reg[D], reg[E] = de >> 8, de & 255
        reg[SP] = 0xFEF0 - 2
        self.mem[0xFEEE], self.mem[0xFEEF] = STOP & 255, STOP >> 8
        self.ports.frame = []
        self.sim.run(address, STOP)
        return self.ports.frame

    def start(self):
        return self.call(*self.start_call)

    def frame(self):
        return self.call(self.frame_call)


def player_frames(kind, frames, venv):
    """The register state at the end of each frame and whether R13 was written in it"""
    player = Player(kind, venv)
    regs = [0] * 14
    regs[7] = 0x3F
    for r, v in player.start():
        regs[r] = v
    out = []
    for _ in range(frames):
        writes = player.frame()
        for r, v in writes:
            if r < 14:
                regs[r] = v
        out.append((tuple(regs), any(r == 13 for r, v in writes)))
    return out


def read_ym(path):
    """A YM5 / YM6 file: (the frames, the AY clock, the frame rate, the loop frame)"""
    data = open(path, 'rb').read()
    if data[:4] not in (b'YM5!', b'YM6!') or data[4:12] != b'LeOnArD!':
        sys.exit(f'{path}: not an uncompressed YM5 / YM6 (unpack it with lha first)')
    count, attributes, drums = struct.unpack('>IIH', data[12:22])
    clock, rate, loop, extra = struct.unpack('>IHIH', data[22:34])
    p = 34 + extra
    for _ in range(drums):
        size = struct.unpack('>I', data[p:p + 4])[0]
        p += 4 + size
    for _ in range(3):
        p = data.index(b'\0', p) + 1
    body = data[p:p + 16 * count]
    frames = []
    for f in range(count):
        if attributes & 1:
            r = [body[i * count + f] for i in range(16)]
        else:
            r = list(body[f * 16:f * 16 + 16])
        frames.append((tuple(r[:13]) + (r[13] & 15,), r[13] != 0xFF))
    return frames, clock, rate, loop


def source(name, frames, venv):
    """(the frames, the default clock) of a source"""
    if name.startswith('ym:'):
        ym, clock, rate, loop = read_ym(name[3:])
        return (ym[:frames] if frames else ym), clock
    if name not in ('intro', 'game'):
        sys.exit(f'unknown source {name}: intro, game or ym:FILE')
    return player_frames(name, frames or 3000, venv), 1773400


def note_of(period, clock):
    """(the frequency, the MIDI number as a float) of a tone period"""
    f = clock / (16 * period)
    return f, 69 + 12 * math.log2(f / 440)


def name_of(midi):
    n = int(round(midi))
    return '%s%d' % (NAMES[n % 12], n // 12 - 1)


def channel_notes(frames, clock):
    """Each channel's sounding tone a frame: (frame, channel, period, midi, level) where the tone is on, the channel
    is not silent (level 16: the hardware envelope) and the tone is below 8 kHz"""
    out = []
    for i, (r, _) in enumerate(frames):
        for ch in range(3):
            period = (r[2 * ch] | (r[2 * ch + 1] << 8)) & 0xFFF
            level = 16 if r[8 + ch] & 16 else r[8 + ch] & 15
            if r[7] & (1 << ch) or not period or not level or clock / (16 * period) > 8000:
                continue  # tone off, silent, or above 8 kHz (a drum's noise with the tone left on at a tiny period)
            out.append((i, ch, period, note_of(period, clock)[1], level))
    return out


def envelope_level(shape, steps):
    """The 16-level envelope at step counts (a numpy array from the restart)"""
    import numpy as np
    first = steps < 16
    up = shape & 4
    s = np.minimum(steps, 15)
    rise = s if up else 15 - s
    if shape < 8:
        return np.where(first, rise, 0)
    cont, alt, hold = 1, shape & 2, shape & 1
    cycle = (steps // 16) % 2
    pos = steps % 16
    if hold:
        after = (15 if up else 0) if not alt else (0 if up else 15)
        return np.where(first, rise, after)
    if alt:
        going_up = (cycle == 0) == bool(up)
        return np.where(going_up, pos, 15 - pos)
    return pos if up else 15 - pos


def render(frames, clock, rate=44100, frame_rate=50, stereo=False):
    """The AY's output a sample (numpy float arrays): squares, a 17-bit noise LFSR, the envelope; tone and noise
    off give the volume as a level, as the chip does; a DC-blocking filter at the end"""
    import numpy as np
    from scipy.signal import lfilter
    dac = np.array(DAC) / 0xFFFF
    per_frame = rate / frame_rate
    total = int(len(frames) * per_frame)
    out = np.zeros((3, total))
    lfsr = np.zeros(1 << 17, dtype=np.uint8)
    state = 1
    for i in range(len(lfsr)):
        lfsr[i] = state & 1
        state = (state >> 1) | (((state ^ (state >> 3)) & 1) << 16)
    phase = [0.0, 0.0, 0.0]
    noise_pos = 0.0
    env_steps = 0.0
    for f, (r, retrigger) in enumerate(frames):
        a, b = int(f * per_frame), int((f + 1) * per_frame)
        n = b - a
        if n <= 0:
            continue
        t = np.arange(n)
        noise_period = (r[6] & 31) or 1
        noise_inc = clock / (16 * noise_period) / rate
        noise = lfsr[((noise_pos + t * noise_inc).astype(np.int64)) % len(lfsr)]
        noise_pos = (noise_pos + n * noise_inc) % len(lfsr)
        env_period = (r[11] | (r[12] << 8)) or 1
        if retrigger:
            env_steps = 0.0
        env_inc = clock / (16 * env_period) / rate
        steps = (env_steps + t * env_inc).astype(np.int64)
        env = envelope_level(r[13] & 15, steps)
        env_steps += n * env_inc
        if r[13] & 8 and not (r[13] & 1):
            env_steps %= 32
        for ch in range(3):
            period = ((r[2 * ch] | (r[2 * ch + 1] << 8)) & 0xFFF) or 1
            inc = clock / (16 * period) / rate
            ph = phase[ch] + t * inc
            phase[ch] = (phase[ch] + n * inc) % 1.0
            tone = (ph % 1.0) < 0.5 if inc < 0.5 else np.ones(n, dtype=bool)  # above Nyquist: steady
            tone_on = not (r[7] >> ch) & 1
            noise_on = not (r[7] >> (ch + 3)) & 1
            gate = (tone | (not tone_on)) & ((noise == 1) | (not noise_on))
            level = env if r[8 + ch] & 16 else np.full(n, r[8 + ch] & 15)
            out[ch, a:b] = gate * dac[level]
    out = lfilter([1, -1], [1, -0.995], out, axis=1)
    if stereo:
        left = out[0] + 0.5 * out[1]
        right = out[2] + 0.5 * out[1]
        return np.stack([left, right]) / 1.5
    return out.sum(axis=0) / 3


def write_wav(path, samples, rate=44100):
    import numpy as np
    samples = np.atleast_2d(samples)
    peak = np.abs(samples).max() or 1
    pcm = (samples / peak * 0.9 * 32767).astype('<i2').T.copy()
    with wave.open(path, 'wb') as w:
        w.setnchannels(samples.shape[0])
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def find_loop(states, minimum=200, window=2000):
    """The shortest period P (frames) with states[i] == states[i + P] over the last WINDOW frames, and the first frame
    from which it holds to the end (None, None: no such P within the run)"""
    n = len(states)
    for p in range(minimum, n - window):
        if all(states[i] == states[i + p] for i in range(n - p - window, n - p)):
            start = n - p - window
            while start > 0 and states[start - 1] == states[start - 1 + p]:
                start -= 1
            return p, start
    return None, None


def cmd_witness(args):
    if args.source == 'intro':
        player, calls, image, lo, hi, base = Player('intro', args.venv), 385, 'intro-title-bank2.bin', 0x8000, 0x90C5, 0x8000
    else:
        player, calls, image, lo, hi, base = Player('game', args.venv), 118, 'menu-bank4.bin', 0xC968, 0xCD23, 0xC000
    player.start()
    for _ in range(calls):
        player.frame()
    rec = open(os.path.join(ROOT, 'work', 'images', image), 'rb').read()
    diff = [a for a in range(lo, hi) if player.mem[a] != rec[a - base]]
    print('%s: %d frame calls, $%04X-$%04X against work/images/%s: %s' % (
        args.source, calls, lo, hi - 1, image,
        'identical' if not diff else '%d bytes differ, first $%04X' % (len(diff), diff[0])))
    return 1 if diff else 0


def cmd_wav(args):
    frames, clock = source(args.source, args.frames, args.venv)
    clock = args.clock or clock
    samples = render(frames, clock, stereo=args.stereo)
    write_wav(args.out, samples)
    print('%s: %d frames (%.1f s) at an AY clock of %d Hz' % (args.out, len(frames), len(frames) / 50, clock))


def cmd_notes(args):
    frames, clock = source(args.source, args.frames, args.venv)
    clock = args.clock or clock
    notes = channel_notes(frames, clock)
    hist = [0.0] * 12
    cents = []
    for _, ch, period, midi, level in notes:
        hist[int(round(midi)) % 12] += 1
        cents.append(100 * (midi - round(midi)))
    total = sum(hist) or 1
    print('%s at %d Hz: %d frames, %d sounding channel-frames' % (args.source, clock, len(frames), len(notes)))
    print('pitch classes (share of the sounding channel-frames):')
    for i in sorted(range(12), key=lambda i: -hist[i]):
        if hist[i]:
            print('  %-2s %5.1f %%' % (NAMES[i], 100 * hist[i] / total))
    if cents:
        cents.sort()
        print('deviation from the tempered note: median %+.1f cents, middle half %+.1f to %+.1f' % (
            cents[len(cents) // 2], cents[len(cents) // 4], cents[3 * len(cents) // 4]))
    span = [m for _, _, _, m, _ in notes]
    if span:
        print('range: %s to %s' % (name_of(min(span)), name_of(max(span))))
    for ch in range(3):
        seq, last = [], None
        for f, c, period, midi, level in notes:
            if c == ch and period != last:
                seq.append('%s' % name_of(midi))
                last = period
            if len(seq) >= args.first:
                break
        print('channel %s, the first %d periods: %s' % ('ABC'[ch], len(seq), ' '.join(seq)))


def cmd_loop(args):
    """Each channel's repeat: its period, volume and tone / noise bits a frame"""
    frames, clock = source(args.source, args.frames, args.venv)
    for ch in range(3):
        states = [(r[2 * ch], r[2 * ch + 1] & 15, r[8 + ch], (r[7] >> ch) & 9) for r, _ in frames]
        p, start = find_loop(states)
        if p is None:
            print('%s channel %s: no repeat within %d frames' % (args.source, 'ABC'[ch], len(frames)))
        else:
            print('%s channel %s: repeats every %d frames (%.2f s at 50 Hz) from frame %d on' % (
                args.source, 'ABC'[ch], p, p / 50, start))


def cmd_chart(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    rows = []
    for spec in args.sources:
        name, _, clock = spec.partition('@')
        frames, default = source(name, args.frames, args.venv)
        rows.append((spec, frames, int(clock) if clock else default))
    fig, axes = plt.subplots(len(rows), 1, figsize=(12, 2.6 * len(rows)), squeeze=False)
    colours = ('#c0392b', '#2471a3', '#229954')
    for ax, (spec, frames, clock) in zip(axes[:, 0], rows):
        notes = channel_notes(frames, clock)
        for ch in range(3):
            xs = [f / 50 for f, c, _, _, _ in notes if c == ch]
            ys = [m for _, c, _, m, _ in notes if c == ch]
            ax.scatter(xs, ys, s=1.5, color=colours[ch], label='channel ' + 'ABC'[ch], linewidths=0)
        lo = min((m for *_, m, _ in notes), default=48)
        hi = max((m for *_, m, _ in notes), default=84)
        ticks = [m for m in range(int(lo) - 1, int(hi) + 2) if m % 12 in (0, 4, 7)]
        ax.set_yticks(ticks)
        ax.set_yticklabels([name_of(m) for m in ticks], fontsize=7)
        ax.grid(axis='y', color='#dddddd', linewidth=0.5)
        label = spec.split('@')[0]
        label = os.path.basename(label[3:]) if label.startswith('ym:') else label
        ax.set_title('%s, AY clock %.4g MHz' % (label, clock / 1e6), fontsize=9)
        ax.set_xlim(0, len(frames) / 50)
        ax.legend(loc='upper right', fontsize=7, markerscale=5)
    axes[-1, 0].set_xlabel('seconds')
    fig.tight_layout()
    fig.savefig(args.out, dpi=110)
    print('%s: %d rows' % (args.out, len(rows)))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--venv', default=os.environ.get('SKOOLKIT_VENV', DEFAULT_VENV))
    sub = parser.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('witness')
    p.add_argument('source', choices=('intro', 'game'))
    for name in ('wav', 'notes', 'loop'):
        p = sub.add_parser(name)
        p.add_argument('source')
        p.add_argument('--frames', type=int, default=0, help='frames to run (intro, game: 3000 by default)')
        p.add_argument('--clock', type=int, default=0)
        if name == 'wav':
            p.add_argument('--out', required=True)
            p.add_argument('--stereo', action='store_true', help='ABC stereo (else mono)')
        if name == 'notes':
            p.add_argument('--first', type=int, default=24, help='the first periods a channel to print')
    p = sub.add_parser('chart')
    p.add_argument('--out', required=True)
    p.add_argument('--frames', type=int, default=0)
    p.add_argument('sources', nargs='+')
    args = parser.parse_args()
    return {'witness': cmd_witness, 'wav': cmd_wav, 'notes': cmd_notes, 'loop': cmd_loop,
            'chart': cmd_chart}[args.cmd](args) or 0


if __name__ == '__main__':
    sys.exit(main())
