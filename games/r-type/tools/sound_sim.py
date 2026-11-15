#!/usr/bin/env python3
"""R-Type's beeper sound, run in SkoolKit's Z80 simulator from the case's build: PlaySound `$F87C` with the sound and
the channel bits the game passes, then the IM 2 handler Interrupt `$BE23` once a frame, as the machine calls it (its
task table `$BE60` runs SoundTask1-3 in turn, one channel an interrupt). The OUT ($FE) writes and their T-states give
the speaker bit (bit 4). The tables, the figures and the audio renders of doc 9 (written, never played).

    python3 tools/sound_sim.py decode [N ...]          each sound's script decoded step by step (the default: all 35)
    python3 tools/sound_sim.py table                   each sound: channel, timbre, ticks, frames, the speaker's
                                                       toggles, the T-states inside the interrupt, the longest tick
    python3 tools/sound_sim.py silence                 the Silence routine's effect on three busy channels
    python3 tools/sound_sim.py fig-pitch OUT.png       the 35 sounds: the speaker's half-period over time
    python3 tools/sound_sim.py fig-schedule OUT.png    one sound ($0D) frame by frame: the interrupt's tasks, the
                                                       T-states each spends playing
    python3 tools/sound_sim.py fig-script OUT.png      a script decoded byte by byte (sound $0D) as a data sheet
    python3 tools/sound_sim.py wavs DIR                every sound as a WAV (MP3 by `lame -V 4` when over 2 s)

The image: build/game.bin at `$7000`; EntryCopySource `$7EE2` (414 bytes) copied to `$5B64` as the entry does (the
scripts of sounds `$15`-`$1E` live there); the 48K ROM at `$0000` (NoiseBurst reads its bytes); level 1's body
(build/level1.bin) at `$C4AE` (sounds `$1F`-`$21` point into the level space, `--level N` takes another level).
The channel bits are the game's own (`CHANNEL`, from the LD HL / LD L before each CALL PlaySound); a sound no code
starts gets `$81`.

The model: a 48K frame of 69 888 T; the handler is entered at a frame's start when the previous call has returned,
else at the next frame boundary (the interrupt is missed while the handler runs with interrupts off, as on the
machine). SkoolKit has no contention: the T-states are the uncontended ones (the code runs at `$F87C`-`$FB66`, above
the contended `$4000`-`$7FFF`, so the tone loops are exact; NoiseBurst reads the ROM, also uncontended).
Needs SkoolKit ($SKOOLKIT_VENV), Pillow; numpy for the renders.
"""
import argparse
import glob
import os
import subprocess
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRAME = 69888
CPU = 3500000
STOP = 0x5AF0          # a HALT in the attribute file's unused end, the return address of every call
PLAYSOUND, INTERRUPT = 0xF87C, 0xBE23
SOUNDDATA = 0xFB66
SLOTS = SOUNDDATA + 0x67   # the three channels' script pointers
CMDS = SOUNDDATA + 0x85    # the command table $FBEB
SCRIPTS = SOUNDDATA + 0xA5 # the script table $FC0B
CMD_NAMES = ['End', 'Rest', 'Mark', 'Back', 'Repeat', 'Loop', 'spare6', 'Noise', 'Chord1', 'Chord2', 'Chord3',
             'Chord4', 'Chord5', 'Chord6', 'spareE', 'spareF']
CHORDS = {8: 'voices 1-2 steady, 3-4 falling', 9: 'voices 1-2 steady, 3-4 rising', 10: 'voices 1-2 rising, 3-4 steady',
          11: 'voices 1-2 falling, 3-4 steady', 12: 'all four falling', 13: 'all four rising'}
# the channel bits each sound is started with (the LD HL / LD L before CALL PlaySound); $81 for the unstarted ones
CHANNEL = {0x00: 0x83, 0x01: 0x21, 0x02: 0x83, 0x03: 0x83, 0x04: 0x81, 0x05: 0x43, 0x06: 0x81, 0x07: 0x81,
           0x08: 0x82, 0x09: 0x83, 0x0A: 0x83, 0x0B: 0x41, 0x0C: 0x81, 0x0D: 0x83, 0x0E: 0x83, 0x0F: 0x21,
           0x10: 0x83, 0x11: 0x83, 0x12: 0x83, 0x13: 0x83, 0x14: 0x81, 0x15: 0x83, 0x16: 0x41, 0x17: 0x81,
           0x18: 0x41, 0x19: 0x83, 0x1A: 0x81, 0x1B: 0x81, 0x1C: 0x41, 0x1D: 0x82, 0x1E: 0x81, 0x1F: 0x81,
           0x20: 0x81, 0x21: 0x81, 0x22: 0x81}
WHAT = {0x00: 'silence (Silence, wave command 6)', 0x01: 'the ship\'s shot', 0x02: 'the beam charging',
        0x03: 'level 8 wave sound', 0x04: 'an enemy hit', 0x05: 'the beam released', 0x06: 'the missiles',
        0x07: 'unstarted', 0x08: 'small explosion', 0x09: 'big explosion, the ship hit',
        0x0A: 'middle explosion, a life lost', 0x0B: 'key defined (never ran)', 0x0C: 'best pilots table entered',
        0x0D: 'pick-up', 0x0E: 'extra life', 0x0F: 'a soft cell hit', 0x10: 'level 2 beat 1',
        0x11: 'level 2 beat 2', 0x12: 'level 2 beat 3', 0x13: 'level 2 beat 4', 0x14: 'the Force docks',
        0x15: 'level end tune', 0x16: 'anti-air shot, name entered', 0x17: 'unstarted (= $18)',
        0x18: 'a bounced shot', 0x19: 'control chosen 1', 0x1A: 'mission over 1', 0x1B: 'mission over 2',
        0x1C: 'ground laser', 0x1D: 'control chosen 2', 0x1E: 'control chosen 3', 0x1F: 'unstarted (level space)',
        0x20: 'unstarted (level space)', 0x21: 'unstarted (level space)', 0x22: 'CONTINUE count'}


def skoolkit():
    venv = os.environ.get('SKOOLKIT_VENV', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/venv-skoolkit')
    site = glob.glob(os.path.join(venv, 'lib', 'python3*', 'site-packages'))
    if not site:
        sys.exit(f'no SkoolKit at {venv} ($SKOOLKIT_VENV)')
    sys.path.insert(0, site[0])
    from skoolkit.simulator import Simulator
    from skoolkit import simutils
    return Simulator, simutils


def image(level=1):
    mem = bytearray(0x10000)
    unreal = os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng')
    mem[0:0x4000] = open(os.path.join(unreal, 'data', 'rom', '48.rom'), 'rb').read()[:0x4000]
    game = open(os.path.join(ROOT, 'build', 'game.bin'), 'rb').read()
    mem[0x7000:0x7000 + len(game)] = game
    mem[0x5B64:0x5B64 + 414] = mem[0x7EE2:0x7EE2 + 414]
    body = open(os.path.join(ROOT, 'build', f'level{level}.bin'), 'rb').read()
    mem[0xC4AE:0xC4AE + len(body)] = body
    mem[STOP] = 0x76
    return mem


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


class Ports:
    def __init__(self):
        self.fe = []

    def write_port(self, registers, port, value, *rest):
        if not port & 1:
            self.fe.append((registers[25], value))


class Machine:
    def __init__(self, level=1):
        Simulator, self.su = skoolkit()
        self.mem = image(level)
        self.sim = Simulator(self.mem, {'SP': 0x5AE0})
        self.ports = Ports()
        self.sim.set_tracer(self.ports)

    def call(self, address, hl=0):
        su, reg = self.su, self.sim.registers
        reg[su.SP] = 0x5ADE
        reg[su.H], reg[su.L] = hl >> 8, hl & 255
        self.mem[0x5ADE], self.mem[0x5ADF] = STOP & 255, STOP >> 8
        t0 = reg[su.T]
        self.sim.run(address, STOP)
        return t0, reg[su.T]

    def busy(self):
        return [word(self.mem, SLOTS + 2 * k) for k in range(3)]


def play(n, level=1, frames_max=1500, tail=6):
    """frames: list of (frame, task channel, T in the handler, [(t from the frame start, speaker bit)])"""
    m = Machine(level)
    m.call(PLAYSOUND, n << 8 | CHANNEL.get(n, 0x81))
    channel = next((k + 1 for k, p in enumerate(m.busy()) if p), 0)
    out, frame, quiet, edges = [], 0, 0, []
    t_next = 0
    while frame < frames_max:
        table = [m.mem[0xBE60 + 5 * k + 3] for k in range(1, 4)]   # the counters before the call
        due = [k + 1 for k in range(3) if table[k] == 1]
        m.ports.fe = []
        t0, t1 = m.call(INTERRUPT)
        base = frame * FRAME
        for t, v in m.ports.fe:
            edges.append((base + (t - t0), (v >> 4) & 1))
        out.append((frame, due[0] if due else 0, t1 - t0, len(m.ports.fe)))
        length = t1 - t0
        frame += 1 + length // FRAME      # the interrupts missed while the handler ran
        if not any(m.busy()):
            quiet += 1
            if quiet > tail:
                break
        else:
            quiet = 0
    return channel, out, edges


VOICES = {8: (0, 0, -1, -2), 9: (0, 0, 1, 2), 10: (0, 1, 1, 1), 11: (0, -1, -1, -1), 12: (0, -1, -2, -3),
          13: (0, 1, 2, 3)}   # each voice's entry: the step's entry + k x the parameter (voices 1-4)
LENGTH = {0x80: (2, 3, 1), 0x40: (3, 7, 2), 0x20: (4, 15, 4)}   # the timbre bits: (shift, mask, voice factor)


def timbre_of(bits):
    t = bits & 0xE0
    return 0x80 if t == 0x80 else 0x40 if t == 0x40 else 0x20


def voice(mem, entry, v, bits):
    """(delay E, half-periods) of voice v (1-4) on period entry `entry`, as NotePeriod computes it"""
    shift, mask, k = LENGTH[timbre_of(bits)]
    lo, hi = mem[SOUNDDATA + 2 * entry], mem[SOUNDDATA + 2 * entry + 1]
    d = (hi >> shift) + 1 + (1 if (hi & mask) >= v * k else 0)
    return lo, (d - 1) & 255


def hz(delay):
    return CPU / (2 * (115 + 26 * delay))


def describe(mem, b0, b1, bits):
    cmd, par = b0 >> 4, b0 & 15
    if cmd in VOICES:
        parts = []
        for v in (4, 3, 2, 1):
            e = b1 + VOICES[cmd][v - 1] * par
            lo, n = voice(mem, e, v, bits)
            parts.append(f'v{v} entry {e} ({hz(lo):.0f} Hz x {n})')
        return f'chord, entry {b1}, step {par}: ' + ', '.join(parts) + ' (played v4 first)'
    if cmd == 7:
        shift = LENGTH[timbre_of(bits)][0]
        lo, hi = mem[SOUNDDATA + 2 * b1], mem[SOUNDDATA + 2 * b1 + 1]
        start = 0xFF + 2 * par * 256
        return (f'noise: {hi >> shift} bursts of {lo} ROM bytes from ${start:04X} down, each followed by a gap of '
                f'{lo} x 13 T' + ('' if par else ' (the same bytes each burst)'))
    if cmd == 0:
        return 'end: the channel is freed'
    if cmd == 2:
        return f'mark: keep the next step in place {par} (no time)'
    if cmd == 3:
        return f'back: go to the step kept in place {par} (no time; a loop with no end)'
    if cmd == 4:
        return f'repeat: counter {par} = {b1}, keep the next step in place {par} (no time)'
    if cmd == 5:
        return f'loop: counter {par} - 1; not 0: back to place {par} (no time)'
    if cmd == 1:
        return 'rest: nothing this tick'
    return 'spare command'


def decode(mem, n, bits=None):
    bits = CHANNEL[n] if bits is None else bits
    start = word(mem, SCRIPTS + 2 * n)
    lines = [f'sound ${n:02X} ({WHAT[n]}): script ${start:04X}, channel bits ${bits:02X}']
    if not start:
        lines.append('  (no script: the channel is freed)')
        return lines, []
    steps, seen, todo = [], set(), [start]
    while todo:
        a = todo.pop(0)
        while a not in seen and len(steps) < 200:
            seen.add(a)
            b0, b1 = mem[a], mem[a + 1]
            cmd, par = b0 >> 4, b0 & 15
            steps.append((a, b0, b1, cmd, par))
            lines.append(f'  ${a:04X}: {b0:02X} {b1:02X}  {CMD_NAMES[cmd]:7} {describe(mem, b0, b1, bits)}')
            if cmd in (0, 3):
                break
            a += 2
    return lines, steps


def cmd_decode(args):
    mem = image(args.level)
    for n in (args.sounds or range(35)):
        lines, _ = decode(mem, n)
        print('\n'.join(lines))


def summary(n, level=1):
    channel, frames, edges = play(n, level)
    busy = [f for f in frames if f[3]]
    if not edges:
        return dict(n=n, channel=channel, frames=0, ticks=0, toggles=0, t_total=0, t_max=0, seconds=0)
    last = edges[-1][0]
    first = edges[0][0]
    t_play = sum(f[2] for f in busy)
    return dict(n=n, channel=channel, frames=last // FRAME - first // FRAME + 1, ticks=len(busy),
                toggles=len(edges), t_total=t_play, t_max=max(f[2] for f in busy), seconds=(last - first) / CPU)


def cmd_table(args):
    print('| Sound | What | Bits | Channel | Ticks | Frames | Seconds | OUTs | T in the handler | Longest tick (T, frames) |')
    print('| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |')
    for n in range(35):
        s = summary(n, args.level)
        print(f"| `${n:02X}` | {WHAT[n]} | `${CHANNEL[n]:02X}` | {s['channel']} | {s['ticks']} | {s['frames']} | "
              f"{s['seconds']:.2f} | {s['toggles']} | {s['t_total']} | {s['t_max']} ({s['t_max'] / FRAME:.2f}) |")


def cmd_silence(args):
    m = Machine(args.level)
    for n in (0x15, 0x0D, 0x09):
        m.call(PLAYSOUND, n << 8 | 0x81)
    print('three sounds started ($15, $0D, $09 with bits $81): channels', [f'${p:04X}' for p in m.busy()])
    for hl in (0x0083, 0x0082, 0x0081):
        m.call(PLAYSOUND, hl)
        print(f'PlaySound HL=${hl:04X}: channels', [f'${p:04X}' for p in m.busy()])


def font(size):
    from PIL import ImageFont
    for path in ('/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf',
                 '/System/Library/Fonts/Helvetica.ttc'):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def cmd_fig_pitch(args):
    from PIL import Image, ImageDraw
    import math
    cols, pw, ph = 5, 210, 150
    rows = 7
    head = 70
    im = Image.new('RGB', (cols * pw, head + rows * ph + 40), 'white')
    d = ImageDraw.Draw(im)
    f13, f11, f10 = font(17), font(14), font(13)
    d.text((10, 8), 'The 35 sounds as the beeper plays them: each dot is one half-period of the speaker '
                    '(time on x, pitch on y, log scale)', fill='black', font=f13)
    d.text((10, 30), 'Rendered by tools/sound_sim.py fig-pitch from build/game.bin; x: seconds from the first OUT, '
                     'the panel\'s own scale (its length under the title); y: 100 Hz to 20 kHz', fill=(60, 60, 60), font=f11)
    d.text((10, 46), 'A clean line is a tone; a cloud is noise (ROM bytes); gaps are the frames between the channel\'s '
                     'ticks (every third interrupt)', fill=(60, 60, 60), font=f11)
    for n in range(35):
        x0, y0 = (n % cols) * pw, head + (n // cols) * ph
        d.rectangle([x0 + 4, y0 + 4, x0 + pw - 4, y0 + ph - 4], outline=(180, 180, 180))
        _, _, edges = play(n, args.level)
        dur = (edges[-1][0] - edges[0][0]) / CPU if len(edges) > 1 else 0
        name = f'${n:02X} {WHAT[n]}'
        cut = name.rfind(' ', 0, 25) if len(name) > 25 else len(name)
        d.text((x0 + 8, y0 + 6), name[:cut], fill='black', font=f11)
        d.text((x0 + 8, y0 + 22), (name[cut:].strip() + ': ' if cut < len(name) else '') +
               f'{dur:.2f} s, {len(edges)} OUTs', fill=(90, 90, 90), font=f10)
        px0, px1, py0, py1 = x0 + 10, x0 + pw - 10, y0 + 42, y0 + ph - 10
        d.line([px0, py1, px1, py1], fill=(200, 200, 200))
        if len(edges) < 2:
            d.text((px0 + 30, py0 + 30), 'no output', fill=(160, 0, 0), font=f11)
            continue
        t0 = edges[0][0]
        span = max(edges[-1][0] - t0, 1)
        lo, hi = math.log(100), math.log(20000)
        for (ta, va), (tb, vb) in zip(edges, edges[1:]):
            if va == vb or tb == ta:
                continue
            hz = CPU / (2 * (tb - ta))
            if hz < 100 or hz > 20000:
                continue
            x = px0 + (ta - t0) * (px1 - px0) / span
            y = py1 - (math.log(hz) - lo) * (py1 - py0) / (hi - lo)
            d.point((x, y), fill=(20, 60, 170))
    d.text((10, head + rows * ph + 12), 'Sounds $1F-$21 read level 1\'s bytes at $F168-$F35C (the level space): '
                                        'they play whatever the loaded level holds there.', fill=(60, 60, 60), font=f11)
    im.save(args.out)
    print(args.out, im.size)


def cmd_fig_schedule(args):
    from PIL import Image, ImageDraw
    n = args.sound
    channel, frames, edges = play(n, args.level)
    frames = [f for f in frames][:24]
    W, H = 1050, 470
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    f15, f12, f11 = font(17), font(14), font(13)
    d.text((10, 8), f'Sound ${n:02X} ({WHAT[n]}) frame by frame: the channel plays only in its own interrupt, '
                    f'one in three', fill='black', font=f15)
    d.text((10, 30), f'tools/sound_sim.py fig-schedule: PlaySound HL=${n:02X}{CHANNEL[n]:02X} (channel {channel}), then '
                     f'Interrupt $BE23 once a frame; bar = T-states in the handler (of 69 888)', fill=(60, 60, 60),
           font=f12)
    x0, y0, bw, gh = 60, 100, 38, 250
    colours = {1: (200, 80, 60), 2: (60, 140, 60), 3: (40, 90, 190), 0: (150, 150, 150)}
    tmax = max(f[2] for f in frames)
    scale = gh / max(tmax, 20000)
    for i, (fr, ch, t, outs) in enumerate(frames):
        x = x0 + i * (bw + 2)
        h = t * scale
        d.rectangle([x, y0 + gh - h, x + bw, y0 + gh], fill=colours[ch])
        d.text((x + 4, y0 + gh + 6), str(fr), fill='black', font=f11)
        d.text((x + 2, y0 + gh - h - 30), f'{t // 1000}k', fill='black', font=f11)
        d.text((x + 2, y0 + gh - h - 16), f'{outs}', fill=(120, 0, 0), font=f11)
    d.line([x0 - 5, y0 + gh, x0 + 24 * (bw + 2), y0 + gh], fill='black')
    d.text((x0, y0 + gh + 22), 'frame after PlaySound', fill='black', font=f12)
    ly = y0 + gh + 46
    for k, name in ((1, 'task 1 (SoundTask1 $F8E8) ran'), (2, 'task 2 (SoundTask2 $F8F8)'),
                    (3, 'task 3 (SoundTask3 $F908)'), (0, 'no sound task due')):
        lx = 60 + [0, 0, 240, 450, 660][k] if k else 870
        d.rectangle([lx, ly, lx + 14, ly + 14], fill=colours[k])
        d.text((lx + 20, ly), name, fill='black', font=f11)
    d.text((10, ly + 26), 'Numbers over a bar: thousands of T-states in the handler (black), OUT ($FE) writes (red).',
           fill=(60, 60, 60), font=f11)
    d.text((10, ly + 44), f'Channel {channel} carries the sound; the other two tasks find no script and return in a few '
                          'dozen T.', fill=(60, 60, 60), font=f11)
    im.save(args.out)
    print(args.out, im.size)


def cmd_fig_script(args):
    from PIL import Image, ImageDraw
    mem = image(args.level)
    n = args.sound
    lines, steps = decode(mem, n)
    W = 1050
    H = 150 + 46 * len(steps) + 80
    im = Image.new('RGB', (W, H), 'white')
    d = ImageDraw.Draw(im)
    f15, f12, f11 = font(17), font(14), font(13)
    d.text((10, 8), f'Sound ${n:02X} ({WHAT[n]}): its script decoded, two bytes a step', fill='black', font=f15)
    d.text((10, 30), f'tools/sound_sim.py fig-script --sound 0x{n:02X}: the script table $FC0B entry {n} points at '
                     f'${word(mem, SCRIPTS + 2 * n):04X}.', fill=(60, 60, 60), font=f11)
    d.text((10, 47), 'Byte 0: the high nibble is the command (table $FBEB), the low nibble its parameter. Byte 1: '
                     'its argument. e = a period entry.', fill=(60, 60, 60), font=f11)
    hdr = ['address', 'byte 0', 'command', 'param', 'byte 1', 'meaning']
    xs = [10, 85, 150, 255, 305, 365]
    y = 76
    for x, h in zip(xs, hdr):
        d.text((x, y), h, fill='black', font=f12)
    y += 24
    colours = {0: (220, 220, 220), 2: (255, 230, 170), 3: (255, 230, 170), 4: (200, 230, 255), 5: (200, 230, 255),
               7: (240, 200, 200)}
    for a, b0, b1, cmd, par in steps:
        d.rectangle([5, y - 3, W - 5, y + 39], fill=colours.get(cmd, (210, 240, 210)))
        d.text((xs[0], y + 4), f'${a:04X}', fill='black', font=f12)
        d.text((xs[1], y + 4), f'${b0:02X}', fill='black', font=f12)
        d.text((xs[2], y + 4), f'{cmd:X} {CMD_NAMES[cmd]}', fill='black', font=f12)
        d.text((xs[3], y + 4), f'{par}', fill='black', font=f12)
        d.text((xs[4], y + 4), f'${b1:02X}', fill='black', font=f12)
        mean = describe(mem, b0, b1, CHANNEL[n]).replace(' Hz x ', ' Hz x').replace('entry ', 'e')
        if len(mean) > 70:
            cut = mean.rfind(' ', 0, 70)
            d.text((xs[5], y - 1), mean[:cut], fill='black', font=f11)
            d.text((xs[5], y + 18), mean[cut + 1:], fill='black', font=f11)
        else:
            d.text((xs[5], y + 4), mean, fill='black', font=f11)
        y += 46
    d.text((10, y + 10), 'Each step is one tick of the channel: one interrupt in three. A chord step plays its four '
                         'voices inside that interrupt (TonePlayer $FB2F).', fill=(60, 60, 60), font=f11)
    im = im.crop((0, 0, W, y + 40))
    im.save(args.out)
    print(args.out, im.size)


def render(edges, rate=44100):
    import numpy as np
    if not edges:
        return np.zeros(rate // 10, dtype=np.int16)
    t0 = edges[0][0]
    total = int((edges[-1][0] - t0) / CPU * rate) + rate // 10
    out = np.zeros(total, dtype=np.float32)
    level = 0
    pos = 0
    for t, v in edges:
        p = int((t - t0) / CPU * rate)
        out[pos:p] = level
        pos, level = p, v
    out[pos:] = 0
    out = out - out.mean() if len(out) else out
    # a gentle low-pass (a speaker is no ideal square)
    k = np.ones(3) / 3
    out = np.convolve(out, k, mode='same')
    return (out * 12000).astype(np.int16)


def cmd_wavs(args):
    os.makedirs(args.dir, exist_ok=True)
    for n in range(1, 35):
        _, _, edges = play(n, args.level)
        if not edges:
            continue
        data = render(edges)
        base = os.path.join(args.dir, f'sound-{n:02x}')
        with wave.open(base + '.wav', 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(44100)
            w.writeframes(data.tobytes())
        seconds = len(data) / 44100
        if seconds > 2:
            subprocess.run(['lame', '--quiet', '-V', '4', base + '.wav', base + '.mp3'], check=True)
            os.remove(base + '.wav')
            print(f'{base}.mp3 {seconds:.2f} s')
        else:
            print(f'{base}.wav {seconds:.2f} s')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--level', type=int, default=1)
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('decode')
    s.add_argument('sounds', nargs='*', type=lambda x: int(x, 0))
    sub.add_parser('table')
    sub.add_parser('silence')
    s = sub.add_parser('fig-pitch')
    s.add_argument('out')
    s = sub.add_parser('fig-schedule')
    s.add_argument('out')
    s.add_argument('--sound', type=lambda x: int(x, 0), default=0x0D)
    s = sub.add_parser('fig-script')
    s.add_argument('out')
    s.add_argument('--sound', type=lambda x: int(x, 0), default=0x0D)
    s = sub.add_parser('wavs')
    s.add_argument('dir')
    args = p.parse_args()
    {'decode': cmd_decode, 'table': cmd_table, 'silence': cmd_silence, 'fig-pitch': cmd_fig_pitch,
     'fig-schedule': cmd_fig_schedule, 'fig-script': cmd_fig_script, 'wavs': cmd_wavs}[args.cmd](args)


if __name__ == '__main__':
    main()
