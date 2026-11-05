#!/usr/bin/env python3
"""Renders Nether Earth's menu tune and sound effects to docs/audio/*.mp3 from unreal-ng's own audio output.

    python3 tools/render_audio.py [--binary UNREAL_QT] [--port-base 19310] [--only menu,play,pokes] [--encode-only]

How: an own unreal-qt instance (offscreen, master muted: nothing reaches the speakers), a ZX Spectrum 48K (RAM
powered on as zeros, a Kempston card on the edge connector: the machine of the case's recordings), the beeper with
no punch. The machine runs in emulated frames (`run_frames`) while unreal-ng's audio capture
(`POST /audio/capture` with `source: beeper`, the beeper's own buffer) takes the samples it computes; the capture
holds at most 30 s, so it is re-armed every 1400 frames between two frames (no sample lost or doubled) and the
pieces (`/audio/capture/result?wav=true`) are joined into one WAV per stage in work/audio/.

The stages:
  menu   work/play/start.szx, the main menu 93 frames into its tune (docs/09-sound.md 9.4), left alone for two
         passes; each pass start is the frame whose interrupt sends the bass track back to its start (BassReturnPos
         $FD54 falls back): frames 5099 and 10291, a pass of 5192 frames (tune_roll.py's model: 5120 interrupts).
  play   tools/bot.py's game from the same snapshot (Kempston, start, robots built and ordered: the run that
         work/docC/fight recorded), to frame 19400: every menu Beep of the construction and robot menus, and the
         first shots in play (the fire sweep of frame 18680 cut by a hit, a kill). SoundFx ($FD53) read at every frame end
         from 18600 on, so each play effect is cut at the frame the game set it.
  pokes  work/ill1/snaps/deep-3000.szx (in play, no shot yet) with SoundFx set to each effect's start value (an
         experiment: the game's PlayInterrupt and SoundEffect make the sound): the whole fire sweep, the miss, the
         hit, the kill.

Then each piece is cut by its frame window (the tune with a fade) and encoded with lame (192 kbit/s, mono).
"""
import argparse
import json
import os
import subprocess
import sys
import time
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
R = os.path.abspath(os.path.join(CASE, '..', '..'))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(R, 'unreal-ng'))
sys.path.insert(0, HERE)
import bot  # noqa: E402

BINARY = ('/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/wt-ane-stage1/cmake-build-agent-release/bin/'
          'unreal-qt.app/Contents/MacOS/unreal-qt')
START = os.path.join(CASE, 'work', 'play', 'start.szx')
PLAY = os.path.join(CASE, 'work', 'ill1', 'snaps', 'deep-3000.szx')
WORK = os.path.join(CASE, 'work', 'audio')
OUT = os.path.join(CASE, 'docs', 'audio')

FRAME_T = 69888                 # 48K: T-states a frame
CPU_HZ = 3500000
FRAME_S = FRAME_T / CPU_HZ      # 19.97 ms
CHUNK = 1400                    # frames a capture (28 s; the capture holds 30 s)
SOUND = {'beeper_punch': 'off'}
SOUNDFX = 0xFD53
TUNE_OFFSET, TUNE_PERIOD = 93, 5120   # start.szx is 93 frames into the tune; one pass in interrupts (tune_roll.py)
BASS_RETURN = 0xFD54
FADE = 250                      # frames of the next pass faded out
WATCH_FROM, PLAY_FRAMES = 18600, 19400


class Rig(bot.Game):
    """tools/bot.py's game on an own instance, with the beeper captured and SoundFx watched"""

    def __init__(self, args):
        super().__init__(UNREAL, WORK)
        self.args = args
        self.process = None
        self.wav = None
        self.events = []
        self.watch_from = None
        self.fx = 0

    def boot(self, snapshot):
        """bot.Game.launch (48K, ram zero, Kempston on edge.1, master muted, the snapshot loaded) on a new instance"""
        self.stop()
        self.process = self.launch(self.args.binary, snapshot, self.args.port_base)
        self.s.call('control_execution', {'action': 'take_control'}, ok=False)
        for name, value in SOUND.items():
            r = self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/settings/' + name,
                                           'body': {'value': value}}, ok=False)
            assert not r.is_error, (name, r.text)
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                   'body': {'muted': True}}, ok=False)
        rows = [d['source'] for d in self.m.get('/audio/mixer').get('devices', [])]
        assert 'beeper' in rows, rows
        self.frame, self.events, self.held, self.log, self.fx = 0, [], set(), [], 0
        print('mixer sources', rows, flush=True)

    def stop(self):
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(10)
            except Exception:
                self.process.kill()
            self.process = None

    # the capture: one WAV a stage, pieces of CHUNK frames

    def record(self, path):
        self.wav_path = path
        self.wav = wave.open(path + '.part', 'wb')
        self.wav.setnchannels(2)
        self.wav.setsampwidth(2)
        self.rate = None
        self.armed_frames = 0
        self.start_frame = self.frame
        self.arm()

    def arm(self):
        r = self.m.post('/audio/capture', {'action': 'start', 'seconds': 30, 'source': 'beeper'})
        assert r.get('armed'), r
        if self.rate is None:
            self.rate = int(r['sample_rate'])
            self.wav.setframerate(self.rate)
        self.armed_frames = 0

    def flush(self, again=True):
        stopped = self.m.post('/audio/capture', {'action': 'stop'})
        if self.armed_frames:
            # After a stop the result (and its WAV) is the whole armed buffer, zeros past the captured part: keep
            # only the captured_samples the stop reports (interleaved, 2 a stereo frame)
            captured = int(stopped['captured_samples']) // 2
            assert 0 < captured < int(stopped['target_samples']) // 2, stopped
            path = self.m.get('/audio/capture/result?wav=true')['wav_path']
            with wave.open(path) as w:
                assert w.getnchannels() == 2 and w.getsampwidth() == 2 and w.getframerate() == self.rate
                assert w.getnframes() >= captured
                self.wav.writeframes(w.readframes(captured))
            os.remove(path)
        if again:
            self.arm()

    def done(self, stage, source):
        self.flush(again=False)
        self.wav.close()
        os.replace(self.wav_path + '.part', self.wav_path)
        self.wav = None
        with open(os.path.join(WORK, stage + '.json'), 'w') as f:
            json.dump({'stage': stage, 'frames': self.frame - self.start_frame, 'source': source,
                       'events': self.events}, f, indent=0)

    def word(self, address):
        v = self.m.read(address, 2)
        return v[0] | v[1] << 8

    def event(self, name):
        self.events.append([self.frame - self.start_frame, name])
        print(f'{self.frame - self.start_frame:7d} {name}', flush=True)

    # the clock: bot.Game.run, chunked for the capture; from watch_from on one frame a step with SoundFx read

    def run(self, frames):
        while frames > 0:
            step = frames
            if self.wav:
                if self.armed_frames >= CHUNK:
                    self.flush()
                step = min(frames, CHUNK - self.armed_frames)
            if self.watch_from is not None and self.frame + step > self.watch_from:
                step = max(1, min(step, self.watch_from - self.frame)) if self.frame < self.watch_from else 1
            self.s.call('control_execution', {'action': 'run_frames', 'frames': step})
            self.frame += step
            frames -= step
            if self.wav:
                self.armed_frames += step
            if self.watch_from is not None and self.frame >= self.watch_from:
                fx = self.m.read(SOUNDFX, 1)[0]
                if fx and (not self.fx or fx != (self.fx + 1) & 0xFF):  # set by the game, not the interrupt count
                    self.event(f'SoundFx = ${fx:02X}')
                self.fx = fx

    # the menus' Beeps: each stick move or fire of bot.py logged with its context

    def hold_until(self, buttons, probe, limit=60, step=1):
        where = 'construction' if self.m.read(bot.HANDLER, 2) == bytes([bot.START_INTERRUPT & 0xFF,
                                                                         bot.START_INTERRUPT >> 8]) else 'robot'
        self.event(f'{where} {"+".join(sorted(buttons))}')
        return super().hold_until(buttons, probe, limit, step)

    def choose(self, menu, item, then=()):
        names = {bot.MAIN_MENU: 'main', bot.ORDERS_MENU: 'orders', bot.TARGET_MENU: 'target'}
        self.event(f'choose {names.get(menu, menu)} {item}')
        ok = super().choose(menu, item, then)
        self.event(f'chosen {names.get(menu, menu)} {item}')
        return ok


def stage_menu(rig):
    """The menu left alone for two passes of the tune; each pass start found in the machine: the frame whose
    interrupt sends the bass track back to its start (BassReturnPos $FD54, the bass track's return point after a
    pattern call, drops back to the track's first call)"""
    def until_loop(limit):
        before = rig.word(BASS_RETURN)
        for _ in range(limit):
            rig.run(1)
            now = rig.word(BASS_RETURN)
            if now < before:
                return
            before = now
        raise RuntimeError('the tune did not loop')
    rig.boot(START)
    rig.record(os.path.join(WORK, 'menu.wav'))
    rig.event('the menu, tune frame 93')
    rig.run(TUNE_PERIOD - TUNE_OFFSET - 200)
    until_loop(600)
    rig.frame -= 1
    rig.event('the tune starts again')  # the frame its interrupt read the bass goto in
    rig.frame += 1
    rig.run(TUNE_PERIOD - 200)
    until_loop(600)
    rig.frame -= 1
    rig.event('the tune loops')
    rig.frame += 1
    rig.run(600)
    rig.done('menu', 'beeper')


def stage_play(rig):
    rig.boot(START)
    rig.record(os.path.join(WORK, 'play.wav'))
    rig.watch_from = WATCH_FROM
    shots = os.path.join(WORK, 'screens')
    os.makedirs(shots, exist_ok=True)
    rig.event('the menu')
    bot.play(rig, PLAY_FRAMES, shots)
    rig.watch_from = None
    rig.run(60)
    rig.done('play', 'beeper')
    with open(os.path.join(WORK, 'play.log'), 'w') as f:
        f.write('\n'.join(rig.log) + '\n')


def stage_pokes(rig):
    rig.boot(PLAY)
    assert rig.m.read(bot.HANDLER, 2) == bytes([bot.PLAY_INTERRUPT & 0xFF, bot.PLAY_INTERRUPT >> 8])
    rig.record(os.path.join(WORK, 'pokes.wav'))
    rig.run(10)
    for value, frames in ((0x01, 140), (0xFC, 20), (0xFA, 20), (0xC8, 70)):
        assert rig.m.read(SOUNDFX, 1)[0] == 0
        rig.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': hex(SOUNDFX),
                                     'hex': f'{value:02X}'}, ok=False)
        rig.event(f'SoundFx = ${value:02X}')
        rig.run(frames)
    rig.done('pokes', 'beeper')


# ---------------------------------------------------------------------------------------------------------------
# cutting and encoding

class Take:
    """One stage's WAV (the left channel: the beeper is mono) and its events"""

    def __init__(self, stage):
        import numpy as np
        self.np = np
        with open(os.path.join(WORK, stage + '.json')) as f:
            self.meta = json.load(f)
        with wave.open(os.path.join(WORK, stage + '.wav')) as w:
            self.rate = w.getframerate()
            d = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').reshape(-1, 2).astype(np.float64)
        self.data = d[:, 0]
        self.per = len(self.data) / self.meta['frames']

    def at(self, frame):
        return int(round(frame * self.per))

    def event(self, text, nth=0):
        hits = [e for e in self.meta['events'] if e[1].startswith(text)]
        return hits[nth]

    def bursts(self, frame, limit_frames, threshold=30):
        """[(first, end)] frames of the sounding stretches from `frame` (RMS above threshold, one-frame gaps
        bridged)"""
        np = self.np
        last = min(frame + limit_frames, self.meta['frames'] - 1)
        rms = []
        for k in range(frame, last):
            x = self.data[self.at(k):self.at(k + 1)]
            rms.append(float(np.sqrt(((x - x.mean()) ** 2).mean())) if len(x) else 0.0)
        out, k = [], 0
        while k < len(rms):
            if rms[k] > threshold:
                j = k
                while j < len(rms) and (rms[j] > threshold or (j + 1 < len(rms) and rms[j + 1] > threshold)):
                    j += 1
                out.append((frame + k, frame + j))
                k = j
            else:
                k += 1
        return out

    def tone(self, a, b):
        """The strongest frequency above 300 Hz of frames [a, b)"""
        np = self.np
        x = self.data[self.at(a):self.at(b)]
        x = x - x.mean()
        spec = np.abs(np.fft.rfft(x * np.hanning(len(x))))
        hz = np.fft.rfftfreq(len(x), 1 / self.rate)
        audible = hz > 300  # above the silence around a short burst
        return float(hz[audible][int(spec[audible].argmax())])

    def similarity(self, a, b, seconds=6.0):
        """Correlation of the RMS envelopes (20 ms) of two windows: 1.0 when b repeats a"""
        np = self.np
        hop = 882
        n = int(seconds * self.rate) // hop * hop
        ex = np.sqrt((self.data[a:a + n].reshape(-1, hop) ** 2).mean(axis=1))
        ey = np.sqrt((self.data[b:b + n].reshape(-1, hop) ** 2).mean(axis=1))
        return float(np.corrcoef(ex, ey)[0, 1])


def write_mp3(take, start, end, fade, path, title):
    """Samples [start, end) of the take, the DC blocked (a one-pole high-pass at 3.5 Hz, the output capacitor a
    machine has), `fade` samples faded out at the end and 2 ms at both ends; lame CBR 192 kbit/s mono"""
    np = take.np
    from math import pi
    pre = int(0.5 * take.rate)  # the blocker settles on half a second before the cut
    seg = take.data[max(0, start - pre):end]
    lead = start - max(0, start - pre)
    a = 1 - 2 * pi * 3.5 / take.rate
    y = np.zeros_like(seg)
    px, py = seg[0], 0.0
    for i in range(len(seg)):  # plain loop: lfilter is not in numpy
        py = seg[i] - px + a * py
        px = seg[i]
        y[i] = py
    y = y[lead:]
    n = len(y)
    edge = int(0.002 * take.rate)
    ramp = np.ones(n)
    ramp[:edge] = np.linspace(0, 1, edge)
    if fade:
        ramp[n - fade:] = np.linspace(1, 0, fade)
    ramp[n - edge:] = np.minimum(ramp[n - edge:], np.linspace(1, 0, edge))
    y = y * ramp
    pcm = np.clip(np.round(y), -32768, 32767).astype('<i2')
    tmp = path[:-4] + '.wav'
    with wave.open(tmp, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(take.rate)
        w.writeframes(pcm.tobytes())
    subprocess.run(['lame', '--quiet', '-b', '192', '--cbr', '-m', 'm', '--tt', title,
                    '--ta', 'Nether Earth (Argus Press Software, 1987)', tmp, path], check=True)
    os.remove(tmp)
    return n / take.rate, float(np.abs(y).max())


# The effects: (file, stage, the event the sound follows, which burst of at least min_frames after it (of those
# whose strongest frequency is within 8 % of hz, when hz is given), the README's words). Beep's tone is
# 3.5 MHz / (2 (13 A + 50)): A = $14 5645 Hz, $64 1296 Hz, $78 1087 Hz. The play stage's events are bot.py's stick moves ("construction up", "robot fire") and
# SoundFx changes; the bursts are the frames the beeper sounds in.
SFX = [
    ('sfx-cursor-click', 'play', 'construction up', 0, 1, 5645, 'a click: a cursor or a list menu highlight moved',
     '`CursorMoved` `$CB47` (also `ListMenuKey` `$AD17`, `DistanceShow` `$AAB3`): `Beep` `$CCAC`, A = `$14`',
     'bot.py: the first part chosen in the construction menu (the cursor moved up)'),
    ('sfx-part-paid', 'play', 'construction fire', 0, 3, 1296, 'a part paid for (a list menu item chosen sounds '
     'the same)',
     '`PartPaid` `$CA91` (also `ListMenuChosen` `$AD37`): `Beep`, A = `$64`',
     'bot.py: the first part put on in the construction menu'),
    ('sfx-target-chosen', 'play', 'choose target', 0, 3, 1087, 'a target chosen: the choice beep and the order '
     'beep back to back (LEAVE ROBOT sounds the same)',
     '`ListMenuChosen` `$AD37` (`Beep` A = `$64`), then `OrderSet` `$ABF7` (`Beep` A = `$78`; `LeaveRobot` `$A803` '
     'after LEAVE ROBOT)', 'bot.py: the first robot\'s order, its target chosen'),
    ('sfx-robot-start', 'play', 'construction fire', 0, 20, None, 'START ROBOT: the rising chirp and the long low beep',
     '`BuildChirp` `$CB83`: `Beep` A = `$50` down to `$14` by 5, then `LeaveConstructionMenu` `$CB90` A = `$C8`',
     'bot.py: START ROBOT of the first robot'),
    ('sfx-shot-hit', 'play', 'SoundFx = $02', 0, 5, None, 'a shot fired, then the hit that cuts it off',
     '`SoundEffect` `$D5C4` from `PlayInterrupt` `$D566`: `SoundFx` `$FD53` 1 counting up (`FireShot` `$B6D6`), '
     'then `$FA` (`MoveShot` `$B724`)', 'bot.py\'s game: the first shot in play'),
    ('sfx-kill-in-play', 'play', 'SoundFx = $C9', 0, 20, None, 'a robot destroyed in play',
     '`SoundEffect`, `SoundFx` `$C8` (`MoveShotKill` `$B7D7`)', 'bot.py\'s game: the first kill'),
    ('sfx-fire-sweep', 'pokes', 'SoundFx = $01', 0, 20, None, 'a shot fired: the falling sweep, its full 126 frames',
     '`SoundEffect`, `SoundFx` 1 to `$7F`', '`work/ill1/snaps/deep-3000.szx`, `SoundFx` set to 1'),
    ('sfx-miss', 'pokes', 'SoundFx = $FC', 0, 1, None, 'a shot ends on a wall, a building or nothing',
     '`SoundEffect`, `SoundFx` `$FC` (noise, 3 frames; `ShotGone` `$B7EA`)', 'the same, `SoundFx` = `$FC`'),
    ('sfx-hit', 'pokes', 'SoundFx = $FA', 0, 1, None, 'a robot hit, still alive',
     '`SoundEffect`, `SoundFx` `$FA` (noise, 5 frames)', 'the same, `SoundFx` = `$FA`'),
    ('sfx-kill', 'pokes', 'SoundFx = $C8', 0, 20, None, 'a robot destroyed (the explosion)',
     '`SoundEffect`, `SoundFx` `$C8` (noise, 55 frames)', 'the same, `SoundFx` = `$C8`'),
]


def encode():
    os.makedirs(OUT, exist_ok=True)
    rows, report, takes = [], {}, {}

    def take(stage):
        if stage not in takes:
            takes[stage] = Take(stage)
        return takes[stage]

    t = take('menu')
    f0, f1 = t.event('the tune starts again')[0], t.event('the tune loops')[0]
    period = f1 - f0
    start, end = t.at(f0), t.at(f1 + FADE)
    sim = t.similarity(t.at(f0 + 200), t.at(f1 + 200))
    secs, peak = write_mp3(t, start, end, t.at(FADE), os.path.join(OUT, 'menu-tune.mp3'), 'the menu tune')
    print(f'{"menu-tune":20s} frames {f0}..{f1} + {FADE}  pass {period} frames ({period - TUNE_PERIOD} interrupts '
          f'missed)  {secs:6.1f} s  peak {peak:6.0f}  loop check {sim:.4f}', flush=True)
    report['menu-tune'] = {'frames': [f0, f1], 'pass_frames': period, 'seconds': round(secs, 2),
                           'loop_check': round(sim, 4)}
    rows.append(('menu-tune', 'the main menu tune: two pulse voices and the drums, one pass from its start',
                 '`MenuMusic` `$C4A7` (the tone loop `$C4C3`) and `MenuInterrupt` `$C4FD`; tracks: bass `$C678`, '
                 'lead `$C702`, drums `$C665` / `$C66C`',
                 f'{secs:.1f} s (one pass {period * FRAME_S:.1f} s + fade {FADE * FRAME_S:.1f} s)',
                 f'`work/play/start.szx` (tune frame {TUNE_OFFSET}) left alone; cut from frame {f0}, where the '
                 f'bass track goes back to its start, to frame {f1}, where it does again, plus the fade; loop check '
                 f'{sim:.3f}'))
    for name, stage, after, nth, min_frames, hz, what, source, how in SFX:
        t = take(stage)
        f0 = t.event(after)[0]
        found = [b for b in t.bursts(f0, 300) if b[1] - b[0] >= min_frames
                 and (not hz or abs(t.tone(b[0], b[1] + 1) / hz - 1) < 0.08)]
        a, b = found[nth]
        hz = t.tone(a, b + 1)
        start, end = t.at(a - 1), t.at(b + 2)
        secs, peak = write_mp3(t, start, end, 0, os.path.join(OUT, name + '.mp3'), what)
        print(f'{name:20s} frames {a}..{b}  {secs:6.2f} s  peak {peak:6.0f}  strongest {hz:7.0f} Hz', flush=True)
        report[name] = {'frames': [a, b], 'seconds': round(secs, 3), 'strongest_hz': round(hz)}
        rows.append((name, what, source, f'{secs:.2f} s', f'{how}; frames {a}-{b} of the stage'))
    with open(os.path.join(WORK, 'report.json'), 'w') as f:
        json.dump(report, f, indent=1)
    write_readme(rows)


def write_readme(rows):
    lines = [
        '# Nether Earth: the sound, rendered',
        '',
        'The menu tune and the sound effects as unreal-ng plays them: rendered from the machine state by the',
        'emulator\'s own audio output. `python3 tools/render_audio.py` makes all of them (an own unreal-qt instance',
        'on port base 19310, muted: nothing reaches the speakers). How the sounds work: [09-sound.md](../09-sound.md).',
        '',
        '**The machine:** ZX Spectrum 48K (3.5 MHz, 69888 T a frame: 19.97 ms, 50.08 a second), RAM powered on as',
        'zeros, a Kempston card. The game sounds only the beeper (port `$FE` bits 4 and 3); the capture takes the',
        'beeper\'s own buffer, so nothing else in the mix can reach the files. unreal-ng\'s beeper with no punch.',
        '',
        '**How:** the emulator runs in emulated frames (`run_frames`) while its audio capture',
        '(`POST /api/v1/emulator/{id}/audio/capture` with `source: beeper`, then `/audio/capture/result?wav=true`)',
        'takes the beeper\'s own buffer at 44.1 kHz. The capture holds at most 30 s, so it is re-armed every 1400',
        'frames between two frames: the pieces join without a lost or doubled sample. The WAVs (`work/audio/`) are',
        'cut, the DC blocked (a 3.5 Hz high-pass, the output capacitor of the machine), and encoded with lame: CBR',
        '192 kbit/s, mono. No level change.',
        '',
        '**The tune** is one pass from the frame its interrupt sends the bass track back to its start to the frame',
        'it does so again, found in the machine (`BassReturnPos` `$FD54` falls back), then 5 s of the next pass',
        'faded out. A pass takes 5192 frames (103.7 s), not the 5120 of `tools/tune_roll.py`, which counts one',
        'interrupt a frame: 72 frames a pass have no `MenuInterrupt` step (likely interrupts missed while a drum',
        'plays inside the handler; not traced). The "loop check" is the correlation of the loudness (20 ms RMS) of',
        '6 s of the pass with the same 6 s one pass later: near 1 means the capture really repeats there.',
        '',
        '**The effects** come from `tools/bot.py`\'s game (the run of `work/docC/fight`: the menus\' Beeps as the',
        'bot builds and orders its first robot, the first shot and the first kill in play), and from `SoundFx`',
        'set in a play snapshot for the whole sweep and the noises alone. Beeps of the same A sound the same',
        'wherever they are called (09-sound.md 9.6): one file each, the other sites in the table. The `$FA` beep',
        '(`CombatRefused`, `GameOverWait`, `LoadError`, 530 Hz) happens in no run here.',
        '',
        '| File | What | Source routine | Length | How rendered |',
        '| --- | --- | --- | --- | --- |',
    ]
    for name, what, source, length, how in rows:
        lines.append(f'| [{name}.mp3]({name}.mp3) | {what} | {source} | {length} | {how} |')
    lines += [
        '',
        'Stages (`tools/render_audio.py --only STAGE`): `menu`, `play` (bot.py\'s game to frame 19400, under a',
        'minute), `pokes`. `--encode-only` redoes the cuts from `work/audio/`.',
        '',
    ]
    with open(os.path.join(OUT, 'README.md'), 'w') as f:
        f.write('\n'.join(lines))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--binary', default=BINARY)
    p.add_argument('--port-base', type=int, default=19310)
    p.add_argument('--only', default='menu,play,pokes')
    p.add_argument('--encode-only', action='store_true', help='cut and encode the WAVs work/audio already holds')
    args = p.parse_args()
    os.makedirs(WORK, exist_ok=True)
    if not args.encode_only:
        rig = Rig(args)
        try:
            for stage in args.only.split(','):
                began = time.time()
                {'menu': stage_menu, 'play': stage_play, 'pokes': stage_pokes}[stage](rig)
                print(f'{stage}: {time.time() - began:.0f} s', flush=True)
        finally:
            rig.stop()
    encode()


if __name__ == '__main__':
    sys.exit(main())
