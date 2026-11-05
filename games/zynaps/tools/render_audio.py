#!/usr/bin/env python3
"""Renders the Zynaps title tune and the six sound effects to files from unreal-ng's own beeper output (docs/09).
Nothing is played: the instance's master is muted and the samples go to WAV files (and MP3 with lame).

    python3 tools/render_audio.py --work work/zyB/rig [--only tune,effects]

The instance is a work folder's (re_session.py capture ... --frames 2 leaves one up: 48K, RAM zero at power-on,
Kempston on the edge connector, muted). The machine runs in emulated frames (`run_frames`) while the audio capture
(`POST /audio/capture`, source `beeper`) takes the samples it computes; a capture holds 30 s, so it is re-armed every
1400 frames between two frames and the pieces are joined (the method of games/nether-earth/tools/render_audio.py).

  tune     work/explore/title.szx (the title pages), left alone for 3000 frames: CreditsPage calls TitleTune $B446,
           which plays the whole tune with the interrupts off. The WAV is cut from the first note to the tune's end
           (45.7 s by tools/fig_tune.py's model).
  effects  for each effect n = 1..6: work/run/play-imm.szx (level 1, the start of play, no input) loaded, 10
           frames run, then the request RequestEffect $B2F0 makes, written by hand (an experiment): CurrentEffect
           $7F97 = n, EffectTick $7F96 = $80, EventRequests $81C5 bit 0. The game's EffectJob and EffectPlay $B30C
           play it; 50 frames captured from the request.

Writes work/zyB/audio/*.wav and docs/audio/*.mp3 (lame, 128 kbit/s mono).
"""
import argparse
import json
import os
import subprocess
import sys
import wave

import zynlib as Z

CHUNK = 1400
OUT = os.path.join(Z.CASE, 'docs', 'audio')
WORK = os.path.join(Z.CASE, 'work', 'zyB', 'audio')
NAMES = {1: 'enemy-shot', 2: 'laser', 3: 'plasma-bounce', 4: 'pod-appears', 5: 'next-weapon', 6: 'weapon-on'}


class Rig:
    def __init__(self, work):
        sys.path.insert(0, os.path.join(Z.K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import corpus  # noqa: E402
        self.s = Z.session(work)
        port = json.load(open(os.path.join(work, 'session.json')))['port_base']
        self.m = corpus.Machine(self.s, port)
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                   'body': {'muted': True}}, ok=False)
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/settings/beeper_punch',
                                   'body': {'value': 'off'}}, ok=False)
        self.wav = None
        self.frame = 0

    def load(self, path):
        self.m.post('/snapshot/load', {'path': os.path.abspath(path)})
        self.frame = 0

    def record(self, path):
        self.path = path
        self.wav = wave.open(path + '.part', 'wb')
        self.wav.setnchannels(2)
        self.wav.setsampwidth(2)
        self.rate = None
        self.arm()

    def arm(self):
        r = self.m.post('/audio/capture', {'action': 'start', 'seconds': 30, 'source': 'beeper'})
        assert r.get('armed'), r
        if self.rate is None:
            self.rate = int(r['sample_rate'])
            self.wav.setframerate(self.rate)
        self.armed = 0

    def flush(self, again=True):
        stopped = self.m.post('/audio/capture', {'action': 'stop'})
        if self.armed:
            captured = int(stopped['captured_samples']) // 2
            path = self.m.get('/audio/capture/result?wav=true')['wav_path']
            with wave.open(path) as w:
                self.wav.writeframes(w.readframes(captured))
            os.remove(path)
        if again:
            self.arm()

    def done(self):
        self.flush(again=False)
        self.wav.close()
        os.replace(self.path + '.part', self.path)
        self.wav = None
        print('wrote', os.path.relpath(self.path, Z.CASE), flush=True)

    def run(self, frames):
        while frames > 0:
            if self.wav and self.armed >= CHUNK:
                self.flush()
            step = min(frames, CHUNK - self.armed) if self.wav else frames
            self.s.call('control_execution', {'action': 'run_frames', 'frames': step})
            self.frame += step
            frames -= step
            if self.wav:
                self.armed += step

    def poke(self, address, data):
        self.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': f'0x{address:04X}',
                                      'hex': bytes(data).hex()})


def read_wav(path):
    import numpy as np
    w = wave.open(path)
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    return x[0::w.getnchannels()].astype(float), w.getframerate()


def write_mono(path, x, rate):
    import numpy as np
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(np.clip(x, -32768, 32767).astype(np.int16).tobytes())


def mp3(wav, name):
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, name + '.mp3')
    subprocess.run(['lame', '--quiet', '-m', 'm', '-b', '128', wav, out], check=True)
    print('wrote', os.path.relpath(out, Z.CASE))


def stage_tune(rig):
    import numpy as np
    rig.load(os.path.join(Z.CASE, 'work', 'explore', 'title.szx'))
    raw = os.path.join(WORK, 'title-raw.wav')
    rig.record(raw)
    rig.run(4600)
    rig.done()
    x, rate = read_wav(raw)
    # sounding: a 50 ms window with speaker flips; the tune is the first sounding stretch after 2 s of silence (the
    # snapshot is in the middle of a tune: the high-score page's 500 silent frames come before the next one)
    s = np.sign(x - (x.max() + x.min()) / 2)
    win = rate // 20
    flips = np.array([np.count_nonzero(np.diff(s[k:k + win])) for k in range(0, len(s) - win, win)])
    on = flips > 0
    k = 0
    while k < len(on) and not (not on[k:k + 40].any() and len(on[k:k + 40]) == 40):
        k += 1
    k += int(np.argmax(on[k:]))
    end = k + int(np.argmax(~on[k:]))
    first, last = k * win, end * win
    cut = os.path.join(WORK, 'title-tune.wav')
    write_mono(cut, x[max(0, first - rate // 10):last + rate // 5], rate)
    mp3(cut, 'title-tune')
    json.dump({'first_s': first / rate, 'last_s': last / rate, 'rate': rate},
              open(os.path.join(WORK, 'title-tune.json'), 'w'))


def stage_effects(rig):
    """each effect from a fresh load of the snapshot (nothing else sounds in its first frames of play): 10 frames run,
    the capture armed, the request written, 50 frames"""
    pieces = []
    for n in range(1, 7):
        rig.load(os.path.join(Z.CASE, 'work', 'run', 'play-imm.szx'))
        rig.run(10)
        path = os.path.join(WORK, f'sfx-{n}-{NAMES[n]}.wav')
        rig.record(path)
        req = rig.m.read(0x81C5, 1)[0] | 1
        rig.poke(0x7F96, [0x80, n])
        rig.poke(0x81C5, [req])
        rig.run(50)
        rig.done()
        x, rate = read_wav(path)
        write_mono(path, x, rate)
        mp3(path, f'sfx-{n}-{NAMES[n]}')
        pieces.append({'effect': n, 'name': NAMES[n], 'request_frame': 10, 'frames': 50,
                       'wav': os.path.relpath(path, Z.CASE)})
    json.dump({'rate': rate, 'pieces': pieces}, open(os.path.join(WORK, 'effects.json'), 'w'), indent=1)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--work', required=True)
    p.add_argument('--only', default='tune,effects')
    args = p.parse_args()
    os.makedirs(WORK, exist_ok=True)
    rig = Rig(args.work)
    if 'tune' in args.only:
        stage_tune(rig)
    if 'effects' in args.only:
        stage_effects(rig)


if __name__ == '__main__':
    main()
