#!/usr/bin/env python3
"""Renders Advanced Nether Earth's tunes and sound effects to docs/audio/*.mp3 from unreal-ng's own audio output.

    python3 tools/render_audio.py [--binary UNREAL_QT] [--port-base 19310] [--only flow,deadend,finalcut,sfx,pokes]
                                  [--encode-only]

How: an own unreal-qt instance (offscreen, master muted: nothing reaches the speakers), a Pentagon 128 with TR-DOS
and one plain AY in the AY socket (no TurboSound FM, no General Sound, no MoonSound: the machine the game was made
for), AY-3-8910 DAC curve, ABC stereo, 1.75 MHz AY clock, the AY tone voicing `flat` and no enhancement (no punch,
no room), the beeper with no punch. The machine runs in emulated frames (`run_frames`) while unreal-ng's audio
capture (`POST /audio/capture`, the post-mix master or one device's own buffer) takes the samples it computes; the
capture holds at most 30 s, so it is re-armed every 1400 frames between two frames (no sample lost or doubled) and
the pieces (`/audio/capture/result?wav=true`) are joined into one WAV per stage in work/audio/.

The stages (each from the case's own snapshots and input scripts):
  flow      power-on, the SCL in drive A, work/stage3/inputs/r1-help.txt's RUN "A_NETHER" typed, then the intro
            left alone for one loop of MAD NIGHT; SPACE: the boot menu with TOMY, left alone for its loop; key 3:
            the boot menu's sample; key 1: the game starter, the title cards and the game menu with TAIGA, left
            alone for its loop. Master mix.
  deadend   work/stage3/x0/deadend-start.szx (the r3 recording's start, PlayerBuildings poked to 0): Dead End and
            its tune NETHER EARTH (END), no key. Master mix.
  finalcut  work/stage3/r4/finalcut-start.szx (the r4 recording's start, EnemyBuildings poked to 0): Final Cut and
            REM. Master mix.
  sfx       tools/fig_tour.py's tour (the game menu snapshot, the construction menu, orders, combat, the distance
            menu), the beeper's own buffer: the menus' beeps and the cannon shot as the game makes them.
  pokes     work/stage3/x0/play.szx with SoundFx ($FD53) set to each effect's start value (an experiment: the
            game's PlayInterrupt and SoundEffect make the sound): the fire sweep, the miss, the hit, the kill.
            Beeper buffer.

Then each piece is cut by its frame window, given a fade where it is a loop, and encoded with lame (192 kbit/s,
stereo for the AY, mono for the beeper). The windows and the loop lengths (from the players run on SkoolKit's
simulator, work/docR/ay/*.json: the first frame the AY writes repeat) are the TUNES / EFFECTS tables below.
"""
import argparse
import array
import json
import os
import subprocess
import sys
import time
import urllib.request
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.abspath(os.path.join(HERE, '..'))
R = os.path.abspath(os.path.join(CASE, '..', '..'))
UNREAL = os.environ.get('UNREAL_NG', os.path.join(R, 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import mcplib  # noqa: E402
import corpus  # noqa: E402
import mm_session  # noqa: E402
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
import toolpaths  # noqa: E402

BINARY = toolpaths.unreal_binary(required=False) or 'unreal-qt'
SCL = os.path.join(CASE, 'orig', 'Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl')
S3 = os.path.join(CASE, 'work', 'stage3')
WORK = os.path.join(CASE, 'work', 'audio')
OUT = os.path.join(CASE, 'docs', 'audio')

FRAME_T = 71680                 # Pentagon: T-states a frame
CPU_HZ = 3500000
FRAME_S = FRAME_T / CPU_HZ      # 20.48 ms
CHUNK = 1400                    # frames a capture (28.7 s; the capture holds 30 s)
SOUND = {'ay_voicing': 'flat', 'ay_punch': 'off', 'ay_room': 'off', 'beeper_punch': 'off', 'ay_stereo': 'abc',
         'ay_chip': 'ay8910'}

SOUNDFX = 0xFD53
PLAY_INTERRUPT, MUSIC_INTERRUPT, HANDLER = 0xD566, 0x6780, 0x696A


# ---------------------------------------------------------------------------------------------------------------
# the instance and the capture


class Rig:
    """One own instance: the machine, the capture, the frame clock, the inputs"""

    def __init__(self, args):
        self.args = args
        self.process = mcplib.launch(args.binary, args.port_base)
        self.s = mcplib.Session(f'http://127.0.0.1:{args.port_base + 200}/mcp', 'PENTAGON')
        self.s.call('control_execution', {'action': 'take_control'}, ok=False)
        self.frame = 0
        self.wav = None

    def machine(self):
        """A Pentagon 128 with one plain AY, nothing else making sound, a Kempston card (as the recordings had)"""
        s = self.s
        s.destroy_all()
        s.call('emulator_manage', {'action': 'create', 'model': 'PENTAGON', 'ram_power_on': 'zero'})
        s.call('emulator_manage', {'action': 'start'}, ok=False)
        self.mute()
        s.call('control_execution', {'action': 'pause'}, ok=False)
        self.m = corpus.Machine(s, self.args.port_base)
        for slot, card in (('ay-socket', 'ay'), ('edge.1', 'kempston')):
            s.call('emulator_manage', {'action': 'slots_plug', 'slot': slot, 'card': card,
                                       'replace_if_incompatible': True}, ok=False)
            self.settle()
        for slot in ('zxbus.1', 'zxbus.2', 'zxbus.3', 'zxbus.4'):
            s.call('emulator_manage', {'action': 'slots_remove', 'slot': slot}, ok=False)
            self.settle()
        s.call('control_execution', {'action': 'pause'}, ok=False)
        self.m = corpus.Machine(s, self.args.port_base)
        self.mute()
        for name, value in SOUND.items():
            r = s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/settings/' + name,
                                      'body': {'value': value}}, ok=False)
            assert not r.is_error, (name, r.text)
        mixer = self.m.get('/audio/mixer')
        rows = [d['source'] for d in mixer.get('devices', [])]
        assert 'ay1' in rows and 'beeper' in rows and not any(k in rows for k in ('ay2', 'fm1', 'gs', 'moonsound_fm')), rows
        self.sources = rows
        return rows

    def settle(self):
        """A slot change restarts the machine: wait until the instance answers again"""
        for _ in range(100):
            r = self.s.call('emulator_manage', {'action': 'list'}, ok=False)
            if (r.structured or {}).get('emulators'):
                break
            time.sleep(0.1)
        time.sleep(0.3)

    def mute(self):
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                   'body': {'muted': True}}, ok=False)

    def load(self, snapshot):
        r = self.m.post('/snapshot/load', {'path': os.path.abspath(snapshot)})
        assert r.get('status') == 'success', r
        self.mute()

    def stop(self):
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(10)
            except Exception:
                self.process.kill()
            self.process = None

    # the capture: one WAV a stage, pieces of CHUNK frames

    def record(self, path, source='master'):
        self.wav_path, self.source = path, source
        self.wav = wave.open(path + '.part', 'wb')
        self.wav.setnchannels(2)
        self.wav.setsampwidth(2)
        self.rate = None
        self.samples = 0
        self.armed_frames = 0
        self.start_frame = self.frame
        self.arm()

    def arm(self):
        body = {'action': 'start', 'seconds': 30}
        if self.source != 'master':
            body['source'] = self.source
        r = self.m.post('/audio/capture', body)
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
            res = self.m.get('/audio/capture/result?wav=true')
            path = res['wav_path']
            with wave.open(path) as w:
                assert w.getnchannels() == 2 and w.getsampwidth() == 2 and w.getframerate() == self.rate
                assert w.getnframes() >= captured
                self.wav.writeframes(w.readframes(captured))
            os.remove(path)
            self.samples += captured
        if again:
            self.arm()

    def done(self):
        self.flush(again=False)
        self.wav.close()
        os.replace(self.wav_path + '.part', self.wav_path)
        frames = self.frame - self.start_frame
        self.wav = None
        return frames

    # the clock and the inputs

    def run(self, frames):
        while frames > 0:
            step = frames
            if self.wav:
                if self.armed_frames >= CHUNK:
                    self.flush()
                step = min(frames, CHUNK - self.armed_frames)
            self.s.call('control_execution', {'action': 'run_frames', 'frames': step})
            self.frame += step
            frames -= step
            if self.wav:
                self.armed_frames += step

    def key(self, name, down):
        self.s.call('type_input', {'action': 'press' if down else 'release', 'key': name})

    def tap(self, name, hold=6, gap=20):
        self.key(name, True)
        self.run(hold)
        self.key(name, False)
        self.run(gap)

    def script(self, path, stop_after=None):
        """A zx-reaper input script (re_session's format) from now; stop_after: the last frame to play"""
        held, last = [], 0
        for frame, keys in mm_session.parse_script(path):
            if stop_after is not None and frame > stop_after:
                break
            if frame > last:
                self.run(frame - last)
                last = frame
            if keys is None:
                break
            for k in held:
                self.key(mm_session.KEY_NAMES.get(k, k.lower()), False)
            for k in keys:
                self.key(mm_session.KEY_NAMES.get(k, k.lower()), True)
            held = keys
        for k in held:
            self.key(mm_session.KEY_NAMES.get(k, k.lower()), False)
        return last

    def word(self, address):
        v = self.m.read(address, 2)
        return v[0] | v[1] << 8

    def latch(self):
        for latch in self.m.get('/state/paging').get('latches', []):
            if str(latch.get('port')).upper() in ('0X7FFD', '7FFD'):
                v = latch.get('value')
                return int(v, 0) if isinstance(v, str) else v
        return 0x10


def ay_drain(rig):
    entries = [e for e in rig.m.get('/ay/log?limit=65536').get('entries', []) if e['type'] == 'write']
    rig.m.post('/ay/log', {'action': 'clear'})
    return entries


def log_event(events, rig, name):
    events.append([rig.frame - rig.start_frame, name])
    print(f'{rig.frame - rig.start_frame:7d} {name}', flush=True)


def save_events(stage, events, frames, source):
    with open(os.path.join(WORK, stage + '.json'), 'w') as f:
        json.dump({'frames': frames, 'source': source, 'events': events}, f, indent=1)


# ---------------------------------------------------------------------------------------------------------------
# the stages

# Each module's first pass in frames: (where the loop goes back to, the loop's length). From the players run on
# SkoolKit's simulator (work/docR/ay/*.json): the AY writes repeat with this period. TAIGA loops to its position 13
# (3331 frames in); the others to position 0 (their first pass is the period; a PT3 player's first frames differ
# from a later pass's in a few registers only)
LOOP = {'mad-night': (0, 11388), 'tomy': (0, 8960), 'taiga': (3331, 5120), 'nether-earth-end': (0, 768),
        'rem': (0, 12800)}
FADE = 250  # frames of the next pass faded out after a loop (5.1 s)


def stage_flow(rig):
    rig.machine()
    # The disk inserted, not booted: the r1 script types RUN "A_NETHER" itself, as in the recording
    r = rig.s.call('load_software', {'path': SCL, 'autostart': False, 'play': False}, ok=False)
    assert not r.is_error, r.text
    print(r.text.splitlines()[0], flush=True)
    rig.run(1500)  # the 128 menu, as re_session's --record-load (load_frames)
    events = []
    rig.record(os.path.join(WORK, 'flow.wav'))
    log_event(events, rig, 'typing RUN "A_NETHER" (r1-help.txt)')
    rig.script(os.path.join(S3, 'inputs', 'r1-help.txt'), stop_after=348)
    log_event(events, rig, 'ENTER held 6 frames and released: TR-DOS runs the boot')
    rig.run(1500 + sum(LOOP['mad-night']) + FADE)
    log_event(events, rig, 'SPACE: the boot menu')
    rig.tap('space', hold=4, gap=0)
    rig.run(1000 + sum(LOOP['tomy']) + FADE)
    # The AY log over the sample: PlaySample writes the three volume registers 12790 times (DI, the tune stopped);
    # the frames that hold those writes are the sample's window. The log's ring holds 32K writes: drained every
    # 20 frames. Its frame numbers are the machine's counter: one frame of the tune before the key maps them
    rig.m.post('/ay/log', {'action': 'start', 'capacity': 65536})
    rig.m.post('/ay/log', {'action': 'clear'})
    stage_at = rig.frame - rig.start_frame
    rig.run(1)
    entries = ay_drain(rig)
    offset = entries[0]['frame'] - stage_at
    log_event(events, rig, 'key 3: the sample')
    rig.key('3', True)
    rig.run(4)
    rig.key('3', False)
    for _ in range(20):
        rig.run(20)
        entries += ay_drain(rig)
    rig.m.post('/ay/log', {'action': 'stop'})
    per = {}
    for e in entries:
        per[e['frame'] - offset] = per.get(e['frame'] - offset, 0) + 1
    busy = sorted(f for f, n in per.items() if n > 100)
    first = min((e for e in entries if e['frame'] - offset == busy[0]), key=lambda e: e['index'])
    last = max((e for e in entries if e['frame'] - offset == busy[-1]), key=lambda e: e['index'])
    sample = {'first_frame': busy[0], 'first_t': first['tacts'], 'last_frame': busy[-1], 'last_t': last['tacts'],
              'writes': sum(per[f] for f in busy)}
    print('the sample:', sample, flush=True)
    events.append([busy[0], 'the sample: first volume write', sample])
    events.append([busy[-1] + 1, 'the sample: after its last write', sample])
    log_event(events, rig, 'key 1: the game')
    rig.tap('1', hold=4, gap=0)
    rig.run(1000 + sum(LOOP['taiga']) + FADE)
    log_event(events, rig, 'end')
    frames = rig.done()
    save_events('flow', events, frames, 'master')


def stage_snapshot(rig, stage, snapshot, frames):
    rig.machine()
    rig.load(snapshot)
    events = []
    rig.record(os.path.join(WORK, stage + '.wav'))
    log_event(events, rig, 'snapshot ' + os.path.relpath(snapshot, CASE))
    rig.run(frames)
    log_event(events, rig, 'end')
    save_events(stage, events, rig.done(), 'master')


def stage_pokes(rig):
    rig.machine()
    events = []
    rig.load(os.path.join(S3, 'x0', 'play.szx'))
    rig.record(os.path.join(WORK, 'pokes.wav'), source='beeper')
    log_event(events, rig, 'play.szx')
    for value, name, frames in ((0x01, 'fire', 140), (0xFC, 'miss', 20), (0xFA, 'hit', 20), (0xC8, 'kill', 70)):
        rig.run(10)
        # SoundFx ($FD53) is in the game's bank 0 at $C000: written while bank 0 is paged (the music handler pages
        # bank 1 only inside the interrupt)
        for _ in range(50):
            if rig.latch() & 7 == 0:
                break
            rig.run(1)
        assert rig.latch() & 7 == 0
        rig.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': hex(SOUNDFX),
                                     'hex': f'{value:02X}'}, ok=False)
        log_event(events, rig, f'SoundFx = ${value:02X} ({name})')
        rig.run(frames)
    log_event(events, rig, 'end')
    save_events('pokes', events, rig.done(), 'beeper')


def stage_sfx(rig, stage='sfx', source='beeper'):
    """fig_tour.py's tour (the game menu snapshot, a game to the hover before its lost end) with one buffer captured:
    the beeper's (sfx) or the master mix (sfxmix); no TTD recording, no screens"""
    sys.path.insert(0, HERE)
    import fig_tour

    class TourGame(fig_tour.Game):
        def launch(self, snapshot):
            self.s, self.m = rig.s, rig.m
            rig.load(snapshot)
            raw = self.m.read
            self.m.read = lambda a, n: (self.m.read_page('ram', 0)[a - 0xC000:a - 0xC000 + n] if a >= 0xC000
                                        else raw(a, n))

        def run(self, frames):
            rig.run(frames)
            self.frame = rig.frame - rig.start_frame

        def grab(self):
            pass

        def shot(self, name):
            pass

    class A:
        unreal = UNREAL
        binary = rig.args.binary
        port_base = rig.args.port_base

    rig.machine()
    os.makedirs(os.path.join(WORK, 'tour'), exist_ok=True)  # the tour saves play.szx there
    g = TourGame(A, os.path.join(WORK, 'tour'))
    rig.record(os.path.join(WORK, stage + '.wav'), source=source)
    g.launch(fig_tour.MENU_SNAPSHOT)
    orig_ev = g.ev
    stop = 'PlayerBuildings'  # the tour's lost game is the deadend stage

    class Stop(Exception):
        pass

    def ev(name):
        orig_ev(name)
        if name.startswith(stop):
            raise Stop
    g.ev = ev
    try:
        fig_tour.tour(g)
    except Stop:
        pass
    g.stick(set())
    save_events(stage, [list(e) for e in g.events], rig.done(), source)


# ---------------------------------------------------------------------------------------------------------------
# cutting and encoding

class Take:
    """One stage's WAV and its events; positions in samples (the capture's own count: samples / frames)"""

    def __init__(self, stage):
        import numpy as np
        self.np = np
        with open(os.path.join(WORK, stage + '.json')) as f:
            self.meta = json.load(f)
        with wave.open(os.path.join(WORK, stage + '.wav')) as w:
            self.rate = w.getframerate()
            self.data = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2').reshape(-1, 2).astype(np.float64)
        self.per = len(self.data) / self.meta['frames']

    def at(self, frame, t=0):
        return int(round((frame + t / FRAME_T) * self.per))

    def event(self, text, nth=0):
        hits = [e for e in self.meta['events'] if e[0] is not None and e[1].startswith(text)]
        return hits[nth]

    def onset(self, frame, limit_frames=3000, gap_frames=3):
        """The first sample from `frame` on where the sound starts after gap_frames of digital silence"""
        np = self.np
        lo, hi = self.at(frame), self.at(frame + limit_frames)
        level = np.abs(self.data[lo:hi]).max(axis=1)
        need = int(gap_frames * self.per)
        quiet = level < 2
        run = 0
        for i in range(len(level)):
            if quiet[i]:
                run += 1
            else:
                if run >= need:
                    return lo + i
                run = 0
        raise RuntimeError(f'no onset after frame {frame}')

    def bursts(self, frame, limit_frames, threshold=30):
        """[(first, end)] sample ranges of the sounding stretches from `frame` (frames of RMS above threshold, gaps
        of one frame bridged)"""
        np = self.np
        out, f, last = [], frame, min(frame + limit_frames, self.meta['frames'] - 1)
        rms = [float(np.sqrt(((self.data[self.at(k):self.at(k + 1)] - self.data[self.at(k):self.at(k + 1)].mean(0))
                                ** 2).mean())) for k in range(frame, last)]
        k = 0
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

    def similarity(self, a, b, seconds=8.0):
        """Correlation of the RMS envelopes (20 ms) of two windows: 1.0 when b repeats a"""
        np = self.np
        n, hop = int(seconds * self.rate) // 882 * 882, 882
        x = self.data[a:a + n].reshape(-1, hop, 2)
        y = self.data[b:b + n].reshape(-1, hop, 2)
        ex, ey = np.sqrt((x ** 2).mean(axis=(1, 2))), np.sqrt((y ** 2).mean(axis=(1, 2)))
        return float(np.corrcoef(ex, ey)[0, 1])


def write_mp3(take, start, end, fade, path, mono, title):
    """Samples [start, end) of the take, the DC blocked (a one-pole high-pass at 3.5 Hz, the output capacitor a
    machine has), `fade` samples faded out at the end and 2 ms at both ends; lame CBR 192 kbit/s"""
    np = take.np
    pre = int(0.5 * take.rate)  # the blocker settles on half a second before the cut
    seg = take.data[max(0, start - pre):end].copy()
    lead = start - max(0, start - pre)
    from math import pi
    a = 1 - 2 * pi * 3.5 / take.rate
    y = np.zeros_like(seg)
    prev_x = seg[0].copy()
    prev_y = np.zeros(2)
    for i in range(len(seg)):  # plain loop: lfilter is not in numpy
        prev_y = seg[i] - prev_x + a * prev_y
        prev_x = seg[i]
        y[i] = prev_y
    y = y[lead:]
    n = len(y)
    edge = int(0.002 * take.rate)
    ramp = np.ones(n)
    ramp[:edge] = np.linspace(0, 1, edge)
    if fade:
        ramp[n - fade:] = np.linspace(1, 0, fade)
    ramp[n - edge:] = np.minimum(ramp[n - edge:], np.linspace(1, 0, edge))
    y *= ramp[:, None]
    if mono:
        y = y[:, :1]
    pcm = np.clip(np.round(y), -32768, 32767).astype('<i2')
    tmp = path[:-4] + '.wav'
    with wave.open(tmp, 'wb') as w:
        w.setnchannels(1 if mono else 2)
        w.setsampwidth(2)
        w.setframerate(take.rate)
        w.writeframes(pcm.tobytes())
    subprocess.run(['lame', '--quiet', '-b', '192', '--cbr', '-m', 'm' if mono else 's', '--tt', title,
                    '--ta', 'Advanced Nether Earth (Eternity Industry, 1998)', tmp, path], check=True)
    os.remove(tmp)
    return n / take.rate, float(np.abs(y).max())


# The tunes: stage, where the tune starts (the first sound after the event, after at least 3 frames of digital
# silence: each player's init silences the AY), the loop length (LOOP), the README's words
TUNES = [
    ('mad-night', 'flow', 'ENTER held', 'MAD NIGHT (Syrus/EI, 15.02.98), the intro',
     'New SoundTrack Player (PT2 compile player, Phantom Family) in bank 6, `src/music/intro-music.asm`, '
     '`src/res/music/mad-night.pt2`; played from IM 2 by `LoaderMain` `$6221` while the intro and the scroller run',
     'power-on, the SCL, `RUN "A_NETHER"` typed (`r1-help.txt`), the intro left alone'),
    ('tomy', 'flow', 'SPACE', 'TOMY (X-Man, 08.12.96), the boot music: the boot menu and the help',
     'PT3 player (Nick of GDC) in bank 1 (`d04`), module at `$CE21`, `src/music/boot-music.asm`, '
     '`src/res/music/tomy.pt3`; the boot program plays it each frame',
     'the same run: SPACE at the scroller, the boot menu left alone'),
    ('taiga', 'flow', 'key 1', 'TAIGA (X-Man, 05.03.97), the game music: the game menu, the menus and play',
     'New SoundTrack Player in bank 1 `$C000`, module `$CA45`, `src/music/music-bank1.asm`, '
     '`src/res/music/taiga.pt2`; `MusicInterrupt` `$6780` (menus) and `PlayMusic` `$67B1` (play)',
     'the same run: boot menu key 1, the game starter, the title cards, the game menu left alone'),
    ('nether-earth-end', 'deadend', 'snapshot', 'NETHER EARTH (END) (Syrus/EI), Dead End: the lost game',
     'New SoundTrack Player in bank 3 `$C000`, `src/music/dead-end-music.asm`, `src/res/music/nether-earth-end.pt2`; '
     'Dead End `$D2EF`',
     '`work/stage3/x0/deadend-start.szx` (the r3 recording\'s start: `PlayerBuildings` `$FD3A` poked to 0), no key'),
    ('rem', 'finalcut', 'snapshot', 'REM (X-Man, 17.10.96), Final Cut: the won game',
     'PT3 player at `$DB00` in the Final Cut image, module `$E921`, `src/music/final-cut-music.asm`, '
     '`src/res/music/rem.pt3`',
     '`work/stage3/r4/finalcut-start.szx` (the r4 recording\'s start: `EnemyBuildings` `$FD42` poked to 0)'),
]

# The effects: stage, the event, which burst after it (the n-th, or the first at least `min_frames` long), the words
SFX = [
    ('sfx-part-accepted', 'sfx', 'fire on BIPOD', 0, 4, 'construction menu: a part put on (paid)',
     '`PartPaid` (`src/game/construction.asm`): `Beep`, A = `$64`', 'the tour (`tools/fig_tour.py`): fire on BIPOD'),
    ('sfx-part-refused', 'sfx', 'fire on NUCLEAR', 0, 4, 'construction menu: a part refused or taken off',
     '`PartRefused`: `Beep`, A = `$78`', 'the tour: fire on NUCLEAR (20 > 13 left)'),
    ('sfx-cursor-click', 'sfx', 'up: 5 MILES', 0, 1, 'a click: a menu cursor, a menu item or the miles moved',
     '`DistanceShow` (also `CursorMoved`, `ListMenuKey`): `Beep`, A = `$14`', 'the tour: the distance menu, up'),
    ('sfx-item-chosen', 'sfx', 'SEARCH & CAPTURE', 0, 4, 'a list menu item chosen',
     '`ListMenuChosen` (`src/game/robotmenu.asm`): `Beep`, A = `$64`', 'the tour: SEARCH & CAPTURE in the orders'),
    ('sfx-order-given', 'sfx', 'fire: ADVANCE 20 MILES', 0, 4, 'an order given, LEAVE ROBOT, direct control ended',
     '`DistanceDone` (also `OrderSet`, `LeaveRobot`): `Beep`, A = `$78`', 'the tour: fire on 20 MILES'),
    ('sfx-robot-start', 'sfx', 'START ROBOT', 0, 20, 'START ROBOT: the rising chirp and the long low beep',
     '`BuildChirp`: `Beep` A = `$50` down to `$14` by 5, then `LeaveConstructionMenu` A = `$C8`',
     'the tour: START in the construction menu'),
    ('sfx-cannon-shot', 'sfx', 'FIRE CANNON', 0, 20, 'a cannon shot fired by our robot, to its end on nothing',
     '`SoundEffect` (`src/game/interrupts.asm`) from `PlayInterrupt` `$D566`: `SoundFx` `$FD53` 1 counting up (the '
     'falling sweep), then `$FC` (the miss)', 'the tour: COMBAT MODE, FIRE CANNON'),
    ('sfx-fire-sweep', 'pokes', 'SoundFx = $01', 0, 20, 'a shot fired: the falling sweep, its full 126 frames',
     '`SoundEffect`, `SoundFx` 1 to `$7F`', '`x0/play.szx`, `SoundFx` `$FD53` set to 1'),
    ('sfx-miss', 'pokes', 'SoundFx = $FC', 0, 1, 'a shot ends on a wall, a building or nothing',
     '`SoundEffect`, `SoundFx` `$FC` (noise, 3 frames)', '`x0/play.szx`, `SoundFx` = `$FC`'),
    ('sfx-hit', 'pokes', 'SoundFx = $FA', 0, 1, 'a robot hit, still alive',
     '`SoundEffect`, `SoundFx` `$FA` (noise, 5 frames)', '`x0/play.szx`, `SoundFx` = `$FA`'),
    ('sfx-kill', 'pokes', 'SoundFx = $C8', 0, 20, 'a robot destroyed (the explosion)',
     '`SoundEffect`, `SoundFx` `$C8` (noise, 55 frames)', '`x0/play.szx`, `SoundFx` = `$C8`'),
]

# In the mix: the beeper over the music, the master as the speaker gets it
MIX = [
    ('construction-menu-in-play', 'sfxmix', 'the construction menu opens', 'START ROBOT', 120,
     'the construction menu as heard: TAIGA with the beeps of five parts and START',
     '`ConstructionMenu` `$C849` (`MusicInterrupt` plays TAIGA), `Beep`', 'the tour, master mix'),
]


def encode():
    os.makedirs(OUT, exist_ok=True)
    rows, takes = [], {}

    def take(stage):
        if stage not in takes:
            takes[stage] = Take(stage)
        return takes[stage]

    report = {}
    for name, stage, after, what, source, how in TUNES:
        t = take(stage)
        start = t.onset(t.event(after)[0])
        back, period = LOOP[name]
        loop = t.at(back + period) - t.at(0)
        fade = t.at(FADE) - t.at(0)
        end = start + loop + fade
        assert end <= len(t.data), (name, end, len(t.data))
        # the check: 6 s from the loop's start (plus 200 frames) against the same 6 s one period later (both
        # inside the stage's undisturbed run: the next key comes after the fade)
        probe = start + t.at(back + min(200, period // 4)) - t.at(0)
        sim = t.similarity(probe, probe + t.at(period) - t.at(0), seconds=6.0)
        secs, peak = write_mp3(t, start, end, fade, os.path.join(OUT, name + '.mp3'), False, what.split(',')[0])
        frame = start / t.per
        print(f'{name:28s} start frame {frame:8.1f}  loop {back}+{period} frames  {secs:6.1f} s  peak {peak:6.0f}  '
              f'loop check {sim:.3f}', flush=True)
        report[name] = {'start_frame': round(frame, 1), 'seconds': round(secs, 2), 'loop_check': round(sim, 4)}
        rows.append((name, what, source, f'{secs:.1f} s (one pass {(back + period) * FRAME_S:.1f} s + fade '
                     f'{FADE * FRAME_S:.1f} s)', f'{how}; stereo ABC; master mix from frame {frame:.0f} '
                     f'of the stage; loop check {sim:.3f}'))
    t = take('flow')
    first, after = t.event('the sample: first'), t.event('the sample: after')
    info = first[2]
    start = t.at(info['first_frame'], info['first_t'])
    end = t.at(info['last_frame'], info['last_t'] + 307)
    secs, peak = write_mp3(t, start, end, 0, os.path.join(OUT, 'sample.mp3'), False, 'the boot menu sample')
    print(f'{"sample":28s} frames {info["first_frame"]}..{info["last_frame"]}  {secs:6.2f} s  writes {info["writes"]}')
    report['sample'] = {'seconds': round(secs, 3), 'writes': info['writes']}
    rows.append(('sample', 'the boot menu\'s key 3 ("NOT used"): a digitized sample, 4-bit, 11401 Hz',
                 '`PlaySample` in the boot program (`src/bootmenu/boot.asm`), 12790 bytes of bank 7 `$CE09` through '
                 'AY registers 8-10, 307 T a sample, interrupts off (the tune stops)', f'{secs:.2f} s',
                 'the flow run: boot menu key 3; cut from the first to the last volume write of the AY log '
                 f'({info["writes"]} writes); stereo ABC, master mix'))
    for name, stage, after, nth, min_frames, what, source, how in SFX:
        t = take(stage)
        f0 = t.event(after)[0]
        found = [b for b in t.bursts(f0, 300) if b[1] - b[0] >= min_frames]
        a, b = found[nth]
        start, end = t.at(a - 1), t.at(b + 2)
        secs, peak = write_mp3(t, start, end, 0, os.path.join(OUT, name + '.mp3'), True, what)
        print(f'{name:28s} frames {a}..{b}  {secs:6.2f} s  peak {peak:6.0f}', flush=True)
        report[name] = {'frames': [a, b], 'seconds': round(secs, 3)}
        rows.append((name, what, source, f'{secs:.2f} s', f'{how}; the beeper\'s own buffer (mono), frames '
                     f'{a}-{b} of the stage'))
    for name, stage, first, last, tail, what, source, how in MIX:
        t = take(stage)
        a, b = t.event(first)[0], t.event(last)[0] + tail
        start, end = t.at(a), t.at(b)
        fade = t.at(25) - t.at(0)
        secs, peak = write_mp3(t, start, end, fade, os.path.join(OUT, name + '.mp3'), False, what)
        print(f'{name:28s} frames {a}..{b}  {secs:6.2f} s  peak {peak:6.0f}', flush=True)
        report[name] = {'frames': [a, b], 'seconds': round(secs, 2)}
        rows.append((name, what, source, f'{secs:.1f} s', f'{how}, frames {a}-{b}; stereo ABC'))
    with open(os.path.join(WORK, 'report.json'), 'w') as f:
        json.dump(report, f, indent=1)
    write_readme(rows)


def write_readme(rows):
    lines = [
        '# Advanced Nether Earth: the sound, rendered',
        '',
        'Every tune and sound effect of the game as unreal-ng plays it: rendered from the machine state by the',
        'emulator\'s own audio output, not from the module files. `python3 tools/render_audio.py` makes all of them',
        '(about two minutes; an own unreal-qt instance on port base 19310, muted: nothing reaches the speakers).',
        '',
        '**The machine:** Pentagon 128 with TR-DOS 5.04T, one AY-3-8910 (the AY DAC curve, not the YM2149\'s) at',
        '1.75 MHz (the Pentagon\'s 3.5 MHz / 2), **ABC stereo** (A left, B centre, C right: the levels A 100/10,',
        'B 66/66, C 10/100 percent left/right, unreal-ng\'s `STEREO.ABC`). No TurboSound, General Sound or MoonSound',
        'in the slots. unreal-ng\'s AY tone voicing `flat` (no tone shaping), no punch, no room, no beeper punch;',
        'the AY synthesized at its native rate (218.75 kHz) and decimated to 44.1 kHz.',
        '',
        '**How:** the emulator runs in emulated frames (`run_frames`) while its audio capture',
        '(`POST /api/v1/emulator/{id}/audio/capture`, then `/audio/capture/result?wav=true`) takes what it computes:',
        'the post-mix master (AY + beeper) for the tunes, the beeper\'s own buffer for the effects. The capture holds',
        'at most 30 s, so it is re-armed every 1400 frames between two frames: the pieces join without a lost or',
        'doubled sample. The WAVs (`work/audio/`) are cut, the DC blocked (a 3.5 Hz high-pass, the output',
        'capacitor of the machine), and encoded with lame: CBR 192 kbit/s, stereo for the AY, mono for the beeper.',
        'No level change: the files keep the emulator\'s levels.',
        '',
        '**A tune** starts at its first sound (the player\'s init silences the AY first) and runs the module\'s',
        'first pass (its length from the players run on SkoolKit\'s simulator, `work/docR/ay/*.json`: the frame the',
        'AY writes start to repeat; TAIGA loops back to its position 13, the others to the start), then 5.1 s of',
        'the next pass faded out. The "loop check" is the correlation of the loudness (20 ms RMS) of 6 s at the',
        'loop\'s start with the 6 s one period later: near 1 means the capture really repeats there. A frame is',
        '71680 T = 20.48 ms (48.8 a second).',
        '',
        '| File | What | Source routine / module | Length | How rendered |',
        '| --- | --- | --- | --- | --- |',
    ]
    for name, what, source, length, how in rows:
        lines.append(f'| [{name}.mp3]({name}.mp3) | {what} | {source} | {length} | {how} |')
    lines += [
        '',
        'Stages (`tools/render_audio.py --only STAGE`): `flow` (power-on to the game menu: MAD NIGHT, TOMY, the',
        'sample, TAIGA), `deadend`, `finalcut`, `sfx` and `sfxmix` (`tools/fig_tour.py`\'s tour, beeper / master),',
        '`pokes` (`SoundFx` set in `x0/play.szx`: an experiment that runs the game\'s own effect code; the hit and',
        'the kill happen in no recording). `--encode-only` redoes the cuts from `work/audio/`.',
        '',
    ]
    with open(os.path.join(OUT, 'README.md'), 'w') as f:
        f.write('\n'.join(lines))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--binary', default=BINARY)
    p.add_argument('--port-base', type=int, default=19310)
    p.add_argument('--only', default='flow,deadend,finalcut,sfx,sfxmix,pokes')
    p.add_argument('--encode-only', action='store_true', help='cut and encode the WAVs work/audio already holds')
    args = p.parse_args()
    os.makedirs(WORK, exist_ok=True)
    if not args.encode_only:
        rig = Rig(args)
        try:
            for stage in args.only.split(','):
                began = time.time()
                if stage == 'flow':
                    stage_flow(rig)
                elif stage == 'deadend':
                    stage_snapshot(rig, 'deadend', os.path.join(S3, 'x0', 'deadend-start.szx'), 1300)
                elif stage == 'finalcut':
                    stage_snapshot(rig, 'finalcut', os.path.join(S3, 'r4', 'finalcut-start.szx'), 15000)
                elif stage == 'sfx':
                    stage_sfx(rig)
                elif stage == 'sfxmix':
                    stage_sfx(rig, 'sfxmix', 'master')
                elif stage == 'pokes':
                    stage_pokes(rig)
                else:
                    raise SystemExit('unknown stage ' + stage)
                print(f'{stage}: {time.time() - began:.0f} s', flush=True)
        finally:
            rig.stop()
    encode()


if __name__ == '__main__':
    main()
