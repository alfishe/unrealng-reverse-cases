#!/usr/bin/env python3
"""Run a music piece's own player, frame by frame, and keep what it writes to the AY: the register stream, a WAV.

    python3 tools/ay_render.py variant NAME [--seconds S] [--wav OUT.wav] [--psg OUT.psg]
    python3 tools/ay_render.py original [--seconds S] [--wav OUT.wav]
    python3 tools/ay_render.py piece FILE BASE INIT PLAY [--start ADDR] [...]

The player is never re-implemented: its compiled code runs in SkoolKit's Z80 simulator ($SKOOLKIT_VENV), the way the
menu runs it: one CALL of the init (and of the start entry of layout B), then one CALL of the play entry a frame
(the menu's interrupt). Every OUT to `$FFFD` selects a register and every OUT to `$BFFD` writes it; a frame's
registers are the values after its play call, R13 counts only when it was written in that frame (a write restarts
the envelope).

The WAV is a plain AY model at the 128K's clock (1.7734 MHz, 50 frames a second): three square tones, the 17-bit
noise, the envelope's 16 shapes, the AY's logarithmic volume table, mono, 44.1 kHz. It is a reference to listen to,
not an emulation of the analogue output. The PSG file (the standard frame dump) plays in any AY player.
"""
import argparse
import json
import os
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLOCK = 1773400
FRAME = 50
VOL = [0.0, 0.0106, 0.0150, 0.0222, 0.0320, 0.0466, 0.0665, 0.1039, 0.1237, 0.1986, 0.2803, 0.3548, 0.4702,
       0.6030, 0.7530, 1.0]


def simulator(mem):
    if not mem[0x0052]:
        mem[0x0052] = 0xC9  # the 48K ROM's RET at $0052 (end of MASK_INT): zyxtvmbt's depacker leaves through JP $0052
    try:
        from skoolkit.csimulator import CSimulator as Sim
    except ImportError:  # pragma: no cover - the pure Python one is slower but the same
        from skoolkit.simulator import Simulator as Sim
    return Sim(mem, {'SP': 0xFF00})


class AYPorts:
    def __init__(self):
        self.reg, self.regs, self.r13 = 0, [0] * 16, False
        self.regs[7] = 0xFF

    def read_port(self, registers, port):
        return self.regs[self.reg] if port & 0xC002 == 0xC000 and self.reg < 16 else 0xFF

    def write_port(self, registers, port, value, *rest):
        if port & 0xC002 == 0xC000:
            self.reg = value & 0x0F
        elif port & 0xC002 == 0x8000:
            self.regs[self.reg] = value
            if self.reg == 13:
                self.r13 = True


def call(sim, addr, sentinel=0xFFF0):
    """CALL addr and run until it returns"""
    r = sim.registers
    sp = (r[12] - 2) & 0xFFFF
    sim.memory[sp] = sentinel & 0xFF
    sim.memory[sp + 1] = sentinel >> 8
    r[12] = sp
    sim.run(addr, sentinel)


def frames(mem, init, play, count, start=None):
    """the AY register frames (14 registers and the R13-written flag) of count calls of play after init (and start)"""
    sim = simulator(mem)
    ports = AYPorts()
    sim.set_tracer(ports)
    sim.registers[26] = 0  # DI: the player runs inside the menu's interrupt
    if init:
        call(sim, init)
    if start:
        call(sim, start)
    out = []
    for _ in range(count):
        ports.r13 = False
        call(sim, play)
        out.append(bytes(ports.regs[:14]) + bytes([1 if ports.r13 else 0]))
    return out


def psg(fr, path):
    with open(path, 'wb') as f:
        f.write(b'PSG\x1a' + bytes(12))
        last = [None] * 14
        for r in fr:
            f.write(b'\xff')
            for i in range(14):
                if i == 13 and not r[14]:
                    continue
                if r[i] != last[i] or i == 13:
                    f.write(bytes([i, r[i]]))
                    last[i] = r[i]
        f.write(b'\xfd')


def wav(fr, path, rate=44100):
    import numpy as np
    spf = rate // FRAME
    step = CLOCK / 8 / rate               # AY clock / 8: tone and noise counters tick at clock/16 per half period
    out = np.zeros(len(fr) * spf, dtype=np.float32)
    tone_ph = [0.0, 0.0, 0.0]
    noise_ph, lfsr, noise_bit = 0.0, 1, 1
    env_ph, env_pos, env_shape, env_hold = 0.0, 0, 0, False
    n = np.arange(spf)
    for k, r in enumerate(fr):
        if r[14]:
            env_shape, env_pos, env_ph, env_hold = r[13] & 15, 0, 0.0, False
        mix = r[7]
        # noise: one value per noise period, built as a step sequence for this frame
        nper = max(1, r[6] & 0x1F) * 2
        nvals = np.empty(spf, dtype=np.float32)
        for i in range(spf):
            noise_ph += step
            while noise_ph >= nper:
                noise_ph -= nper
                bit = (lfsr ^ (lfsr >> 3)) & 1
                lfsr = (lfsr >> 1) | (bit << 16)
                noise_bit = lfsr & 1
            nvals[i] = noise_bit
        # envelope: 32 steps a period of 256 x the envelope period / clock x 16 ...
        eper = max(1, r[11] | r[12] << 8) * 2
        evals = np.empty(spf, dtype=np.float32)
        for i in range(spf):
            env_ph += step
            while env_ph >= eper and not env_hold:
                env_ph -= eper
                env_pos += 1
                if env_pos >= 32:
                    if env_shape & 8 and not env_shape & 1:   # continue, no hold: repeat
                        env_pos = 0
                    else:
                        env_pos, env_hold = 31, True
            evals[i] = env_level(env_shape, env_pos, env_hold)
        frame = np.zeros(spf, dtype=np.float32)
        for c in range(3):
            per = max(1, r[2 * c] | (r[2 * c + 1] & 15) << 8)
            ph = tone_ph[c] + step * (n + 1)
            tone = ((ph // per) % 2).astype(np.float32)
            tone_ph[c] = (tone_ph[c] + step * spf) % (2 * per)
            t_on = not mix >> c & 1
            n_on = not mix >> (c + 3) & 1
            gate = (tone if t_on else 1.0) * (nvals if n_on else 1.0)
            v = r[8 + c]
            amp = np.array([VOL[int(e)] for e in evals]) if v & 0x10 else VOL[v & 15]
            frame += gate * amp
        out[k * spf:(k + 1) * spf] = frame / 3.0
    out -= out.mean()
    pcm = np.clip(out * 0.9 * 32767, -32768, 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def env_level(shape, pos, hold):
    """the envelope's volume 0-15 at step pos (0-31) of its first or repeated period"""
    if not shape & 8:                       # shapes 0-7: one ramp (up when bit 2), then 0
        if hold:
            return 0
        return pos // 2 if shape & 4 else 15 - pos // 2
    att, alt, hld = shape & 4, shape & 2, shape & 1
    up = bool(att)
    if hold:
        if hld:
            return (15 if up else 0) ^ (15 if alt else 0)
    level = pos // 2 if up else 15 - pos // 2
    return level


def variant_piece(name):
    """(memory, init, play, start) of a variant's (or the original's) music piece as the menu loads it"""
    mem = bytearray(65536)
    if name == 'original':
        data = open(os.path.join(ROOT, 'build', 'music.bin'), 'rb').read()
        mem[0xC000:0xC000 + len(data)] = data
        return mem, 0xC00B, 0xC00E, None
    vdir = os.path.join(ROOT, 'variants', name)
    cfg = json.load(open(os.path.join(vdir, 'variant.json')))
    e = cfg['equ']
    p = os.path.join(ROOT, 'build', 'variants', name, 'music.bin')
    if not os.path.exists(p):
        p = os.path.join(vdir, 'music', 'piece.bin')
    data = open(p, 'rb').read()
    base = int(e['MusicPiece'][1:], 16)
    mem[base:base + len(data)] = data[:65536 - base]
    for extra in cfg.get('music_extra', []):   # a second music piece some loaders read
        d2 = open(os.path.join(ROOT, 'build', 'variants', name, 'music-%s.bin' % extra['music']) if extra.get('music')
                  else os.path.join(vdir, extra['file']), 'rb').read()
        a = int(extra['at'][1:], 16)
        mem[a:a + len(d2)] = d2
    h = lambda k: int(e[k][1:], 16) if k in e and e[k] != '$0000' else None
    if cfg.get('packed', {}).get('init'):   # the piece is packed (tools/lzpack.py): MusicInit depacks; the player's own init
        return mem, int(cfg['packed']['init'][1:], 16), h('MusicPlay'), h('MusicStart')
    return mem, h('MusicInit'), h('MusicPlay'), h('MusicStart')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('what', choices=['variant', 'original', 'piece'])
    p.add_argument('args', nargs='*')
    p.add_argument('--start', default='')
    p.add_argument('--seconds', type=float, default=60)
    p.add_argument('--wav', default='')
    p.add_argument('--psg', default='')
    p.add_argument('--regs', default='', help='write the frames as JSON (a list of 15-byte hex strings)')
    a = p.parse_args()
    if a.what == 'piece':
        f, base, init, play = a.args
        mem = bytearray(65536)
        data = open(f, 'rb').read()
        b = int(base, 0)
        mem[b:b + len(data)] = data
        init, play, start = int(init, 0), int(play, 0), int(a.start, 0) if a.start else None
    else:
        mem, init, play, start = variant_piece(a.args[0] if a.what == 'variant' else 'original')
    fr = frames(mem, init, play, int(a.seconds * FRAME), start)
    if a.wav:
        os.makedirs(os.path.dirname(os.path.abspath(a.wav)), exist_ok=True)
        wav(fr, a.wav)
    if a.psg:
        psg(fr, a.psg)
    if a.regs:
        json.dump([r.hex() for r in fr], open(a.regs, 'w'))
    print('ay_render: %d frames%s' % (len(fr), (', ' + a.wav) if a.wav else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
