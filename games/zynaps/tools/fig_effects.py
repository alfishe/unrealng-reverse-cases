#!/usr/bin/env python3
"""The six sound effects: EffectPlay $B30C run on paper against the beeper capture (docs/09-sound.md 9.4).

    python3 tools/fig_effects.py

The model reads src/res/effects/effects.fx.txt through tools/res_effects.py (the bytes $7E5A-$7E89) and steps
EffectPlay's state the way the code does at each EffectTick: two-tone effects (flag bit 7) step both pitches, one-tone
effects the pitch of the segment (B bit 0); at a segment's end the step change (+4), the shortening of segment A (bit
5), the step reversals (bits 3, 4), the pitch restart (bit 6) and the next segment's pitch from the flags' bit 0, 1
or 2 (even count, odd count, the last). A period is two halves of 25 T a count (the NOP-NOP-NOP-DJNZ round at
$B360) plus about 140 T of loop around them (a count 0 is 256): the tone 3500000 / (25 (hA + hB) + 140) Hz.

The measured side is work/zyB/audio/sfx-N-*.wav (tools/render_audio.py: each effect requested by hand in play, 60
frames from the request). One tick of the model is two TV frames: the effects' lengths in the capture (effect 1: 9
ticks, 18 frames) say so. Writes docs/img/sound/effects.png.
"""
import json
import os

import numpy as np

import zybplot as P
import res_effects

CLOCK = 3500000
FRAME = 69888
TICK = 2           # TV frames an EffectTick (measured, see above)
LOOP_T = 140


def table():
    data = res_effects.from_text(open(os.path.join(P.CASE, 'src', 'res', 'effects', 'effects.fx.txt'), 'rb').read())
    return [list(data[8 * k:8 * k + 8]) for k in range(6)]


def simulate(e):
    """[(tick, high-half count, low-half count)] while the effect sounds"""
    s = list(e[:7])
    lenA, lenB = e[7] & 15, e[7] >> 4
    C = s[6]
    pA, pB = s[0], s[2]
    two = C & 0x80
    b = 1
    sel = 'AB' if two else 'AA'
    frames = lenA
    out, tick = [], 0

    def halves():
        val = {'A': pA, 'B': pB}
        return val[sel[0]], val[sel[1]]

    while tick < 200:
        h = halves()
        out.append((tick, h[0] or 256, h[1] or 256))
        tick += 1
        if two:
            pA = (pA + s[1]) & 255
            pB = (pB + s[3]) & 255
        elif b & 1:
            pA = (pA + s[1]) & 255
        else:
            pB = (pB + s[3]) & 255
        frames -= 1
        if frames:
            continue
        s[5] = (s[5] - 1) & 255
        if s[5] == 0:
            break
        s[1] = (s[1] + s[4]) & 255
        s[3] = (s[3] + s[4]) & 255
        if C & 0x20:
            lenA = max(1, lenA - 1)
        if C & 0x08 and (two or b & 1):
            s[1] = (-s[1]) & 255
        if C & 0x10 and (two or not b & 1):
            s[3] = (-s[3]) & 255
        if C & 0x40:
            pA, pB = s[0], s[2]
        if two:
            sel, frames = 'AB', lenA
        else:
            a = s[5]
            b = C
            carry = a & 1
            a >>= 1
            if carry:
                if a:
                    b >>= 1
                else:
                    b >>= 2
            if b & 1:
                sel, frames = 'AA', lenA
            else:
                sel, frames = 'BB', lenB
    return out


def tone(h, l):
    return CLOCK / (25 * (h + l) + LOOP_T)


NAMES = {1: 'the enemy shot', 2: 'the laser', 3: 'the plasma bounce', 4: 'a pod appears', 5: 'the next weapon',
         6: 'a weapon on'}


def main():
    effects = table()
    meta = json.load(open(os.path.join(P.CASE, 'work', 'zyB', 'audio', 'effects.json')))
    rate = meta['rate']
    per_frame = rate * FRAME / CLOCK
    P.style()
    fig, axes = P.plt.subplots(2, 3, figsize=(14, 7.6))
    for k, piece in enumerate(meta['pieces']):
        n = piece['effect']
        ax = axes[k // 3][k % 3]
        import wave
        w = wave.open(os.path.join(P.CASE, piece['wav']))
        x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(float)
        nfft = 256
        x = x - x.mean()
        spec, freqs, times, _ = ax.specgram(x, NFFT=nfft, Fs=rate, noverlap=nfft - 32, cmap='magma',
                                            xextent=(0, len(x) / per_frame))
        ax.images[0].set_clim(10 * np.log10(spec.max() + 1e-9) - 45, 10 * np.log10(spec.max() + 1e-9))
        model = simulate(effects[n - 1])
        # where the sound starts: the first frame with speaker flips (the request waits for the next dispatch)
        s = np.sign(x)
        flips = [np.count_nonzero(np.diff(s[int(f * per_frame):int((f + 1) * per_frame)])) for f in range(50)]
        start = next(f for f, c in enumerate(flips) if c)
        last = max(f for f, c in enumerate(flips) if c)
        ts = [start + t * TICK for t, _, _ in model]
        fs = [tone(h, l) for _, h, l in model]
        ax.step(ts + [ts[-1] + TICK], fs + [fs[-1]], where='post', color=(0.3, 1, 0.5), lw=1.6)
        print(n, 'sound frames', start, '-', last, 'measured', last - start + 1, 'model', len(model) * TICK)
        e = effects[n - 1]
        ax.set_title(f'{n}: {NAMES[n]}: {len(model)} ticks = {len(model) * TICK} frames (measured {last - start + 1})\n'
                     f'flags %{e[6]:08b}, pitch ${e[0]:02X}/${e[2]:02X}, step {res_effects.signed(e[1]):+d}/'
                     f'{res_effects.signed(e[3]):+d}, {e[5]} segments', fontsize=9.5)
        ax.set_xlim(0, 50)
        ax.set_ylim(0, 4500)
        if k // 3 == 1:
            ax.set_xlabel('TV frames from the request')
        if k % 3 == 0:
            ax.set_ylabel('Hz')
    fig.suptitle('The six effects: the beeper capture (spectrogram) and EffectPlay run on paper from the table '
                 '(green, one tick = 2 frames)', fontsize=12)
    fig.tight_layout()
    P.save(fig, P.out('sound', 'effects.png'))
    for n, e in enumerate(effects, 1):
        m = simulate(e)
        print(n, len(m), 'ticks', f'{min(tone(h, l) for _, h, l in m):.0f}-{max(tone(h, l) for _, h, l in m):.0f} Hz')


if __name__ == '__main__':
    main()
