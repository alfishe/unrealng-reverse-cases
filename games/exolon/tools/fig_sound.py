"""Figures of docs/09-sound.md (docs agent B).

  python3 tools/fig_sound.py aytune     docs/img/sound/ay-tune.png       the 128K title tune, model of the streams
  python3 tools/fig_sound.py beeptunes  docs/img/sound/beeper-tunes.png  the 48K tunes, model of PlayTwoTones
  python3 tools/fig_sound.py renders    docs/img/sound/renders.png       spectrograms of the rendered sounds
  python3 tools/fig_sound.py render --work W   the 48K sounds to work/docs/docB/audio/*.wav (never played)

render: an experiment on a live 48K instance (re_session.py open/capture leaves one; muted here first). Each sound
starts from a fresh load of work/snaps/entry.z80 (the game's entry $6D60): Start runs, MainMenu prints the menu and
reaches $6DCB, where a 48K plays the title tune (LD HL,TitleTune / CALL PlayTune). The six bytes there are patched
per sound: the jingle by the operand ($6DCC = JingleTune $7D68), an effect by CALL $7DA3 to a stub written over the
title tune's data (unused then): R times BeeperNoise $7C26 with B, or BeeperSweep $7C3C once. The menu goes on
after it, silent. unreal-ng's own beeper output is captured (POST /audio/capture, source beeper, re-armed every
1400 frames) to WAV files.
"""
import json
import math
import os
import sys
import wave

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fig_docb as B  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

AY_CLOCK = 1773400          # the 128K's AY clock, Hz
NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
STREAMS = [('A', 0xBA01, 0xBE7D), ('B', 0xBB7E, 0xBECD), ('C', 0xBD06, 0xBF1D)]
NOTE_PERIODS = 0xC6EB
NOTE_PERIODS_TUNE = 0xC71B


def note_name(freq):
    n = 12 * math.log2(freq / 440) + 57      # 57 = A4 counted from C0
    k = int(round(n))
    return f'{NAMES[k % 12]}{k // 12}', k


AFTER = {}             # each note's stream address after it (TuneTick leaves the pointer there)


def ay_streams():
    """each channel's events in ticks as TuneChannelStep reads them: (start tick, ticks, period or 0, noise on)"""
    M = B.image()
    out = {}
    for name, start, rec in STREAMS:
        length = M[rec + 0x0A]
        p, stack, t, ev = start, [], 0, []
        mixer, noise = False, 0
        after = []
        while True:
            a = M[p]
            if a < 0x64:
                if a >= 0x32:
                    length = M[p + 1]
                    a -= 0x32
                    p += 1
                period = B.word(M, NOTE_PERIODS_TUNE + 2 * a)
                ev.append((t, length, period, noise if mixer else 0))
                after.append(p + 1)
                t += length
                p += 1
            elif a == 0x64:
                mixer = not mixer
                p += 1
            elif a == 0x79:
                noise = M[p + 1]
                p += 2
            elif a == 0x75:
                stack.append(p + 3)
                p = B.word(M, p + 1)
            elif a == 0x76:
                p = stack.pop()
            elif a == 0x8A:
                p += 2 + M[p + 1]
            elif a == 0xFF:
                break
            else:
                raise ValueError(f'{name} ${p:04X}: code {a:02X}')
        out[name] = (ev, t)
        AFTER[name] = after
    return out


def aytune():
    ch = ay_streams()
    end = min(t for _, t in ch.values())
    B.style()
    fig, axs = plt.subplots(3, 1, figsize=(B.WIDTH, 11), sharex=True)
    for ax, (name, (ev, total)) in zip(axs, ch.items()):
        notes = ev
        ks = [note_name(AY_CLOCK / 16 / p)[1] for t, d, p, nz in notes if not nz]
        lo, hi = min(ks), max(ks)
        for t, d, p, nz in notes:
            if nz:
                y = lo - 3 if nz == 31 else lo - 6
                ax.broken_barh([(t, d * 0.92)], (y - 0.8, 1.6), color=(0.95, 0.6, 0.2))
            else:
                k = note_name(AY_CLOCK / 16 / p)[1]
                ax.broken_barh([(t, d * 0.92)], (k - 0.4, 0.8), color=B.COLOURS[0])
        ticks = list(range((lo // 12) * 12, hi + 2, 12))
        ylab = [f'C{k // 12}' for k in ticks]
        if any(e[3] for e in notes):
            ticks = [lo - 6, lo - 3] + ticks
            ylab = ['noise 15', 'noise 31'] + ylab
        ax.set_yticks(ticks)
        ax.set_yticklabels(ylab)
        ax.set_ylim(lo - 8, hi + 2)
        ax.grid(True, axis='y', alpha=0.3)
        nz = sum(1 for e in notes if e[3])
        ax.set_ylabel(f'channel {name}')
        ax.set_title(B.wrap(f'channel {name}: stream ${STREAMS["ABC".index(name)][1]:04X}, {len(notes)} notes '
                            f'({nz} on noise, orange, at their noise period), {total} ticks to its $FF', 112),
                     fontsize=11)
        ax.axvline(end, color=B.TEXT, lw=1, ls='--')
    axs[-1].set_xlabel(B.wrap(f'tick (TuneTick $B767 = every 4th menu star draw); the tune stops at tick {end} '
                              '(dashed), when the first channel reaches its $FF', 110))
    B.suptitle(fig, 'The 128K title tune: three channels of notes two octaves above the effects\' table, '
               f'{sum(len(v[0]) for v in ch.values())} notes, no loop (model of the streams)')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'ay-tune.png'))
    return ch, end


# --- the 48K renders ------------------------------------------------------------------------------------------------

AUDIO = os.path.join(B.DOCB, 'audio')
CHUNK = 1400
TUNE_SITE = 0x6DCB                       # LD HL,TitleTune ; CALL PlayTune in MainMenu
STUB = 0x7DA3                            # TitleTune's data, free while a stub runs
BEEPER_NOISE, BEEPER_SWEEP = 0x7C26, 0x7C3C
# name: (what calls it, the patch at $6DCB, the stub or None, frames to capture)
SOUNDS = {
    'title-tune': ('MainMenu $6DCB (48K, once per load)', None, None, 2400),
    'jingle': ('ZorbaCheat $7055, GAME OVER $A030', bytes([0x21, 0x68, 0x7D, 0xCD, 0x17, 0x7D]), None, 300),
    'noise-c8-key-click': ('DefineKeys $7029 (B $C8)', None, (1, 0xC8), 120),
    'noise-3c-fire': ('FirePress $8368 (B $3C)', None, (1, 0x3C), 120),
    'noise-14x20-shot-hit': ('ShotHitNoise $844E (20 x B $14)', None, (20, 0x14), 120),
    'noise-1ex10-shell': ('FireShellNoise $9096 (10 x B $1E)', None, (10, 0x1E), 120),
    'noise-28-bonus-tick': ('PayBonusTick $9EC1 (B $28)', None, (1, 0x28), 120),
    'noise-3cx80-bravery': ('ZoneEndBravery $A855 (80 x B $3C, without AddScore between)', None, (80, 0x3C), 200),
    'sweep-pod': ('Pods $9996 (BeeperSweep)', None, 'sweep', 120),
}


class Rig:
    def __init__(self, work):
        sys.path.insert(0, os.path.join(B.K.unreal_root(None), 'tools', 'verification', 'analysis'))
        import corpus  # noqa: E402
        self.s = B.session(work)
        port = json.load(open(os.path.join(work, 'session.json')))['port_base']
        self.m = corpus.Machine(self.s, port)
        self.api('PUT', '/audio/mixer/master', {'muted': True})
        self.api('PUT', '/settings/beeper_punch', {'value': 'off'})
        self.wav = None
        self.source = 'beeper'

    def api(self, method, path, body):
        self.s.call('invoke_api', {'method': method, 'path': '/api/v1/emulator/{id}' + path, 'body': body}, ok=False)

    def load(self, path):
        self.m.post('/snapshot/load', {'path': os.path.abspath(path)})
        self.api('PUT', '/audio/mixer/master', {'muted': True})

    def poke(self, address, data):
        self.s.call('memory_access', {'action': 'write', 'space': 'cpu', 'offset': f'0x{address:04X}',
                                      'hex': bytes(data).hex()})

    def record(self, path):
        self.path = path
        self.wav = wave.open(path + '.part', 'wb')
        self.wav.setnchannels(2)
        self.wav.setsampwidth(2)
        self.rate = None
        self.arm()

    def arm(self):
        r = self.m.post('/audio/capture', {'action': 'start', 'seconds': 30, 'source': self.source})
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

    def run(self, frames):
        while frames > 0:
            if self.armed >= CHUNK:
                self.flush()
            step = min(frames, CHUNK - self.armed)
            self.s.call('control_execution', {'action': 'run_frames', 'frames': step})
            frames -= step
            self.armed += step


def read_wav(path):
    w = wave.open(path)
    x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    return x[0::w.getnchannels()].astype(float), w.getframerate()


def sounding(x, rate):
    """(first, last) sample with the speaker moving (a 2 ms window with a level change)"""
    d = np.abs(np.diff(x)) > 1000
    idx = np.flatnonzero(d)
    return (int(idx[0]), int(idx[-1])) if len(idx) else (0, 0)


def render(work):
    os.makedirs(AUDIO, exist_ok=True)
    rig = Rig(work)
    meta = {}
    for name, (caller, patch, stub, frames) in SOUNDS.items():
        rig.load(os.path.join(B.WORK, 'snaps', 'entry.z80'))
        if stub == 'sweep':
            rig.poke(STUB, [0xCD, BEEPER_SWEEP & 0xFF, BEEPER_SWEEP >> 8, 0xC9])
        elif stub:
            r, b = stub
            rig.poke(STUB, [0x06, r, 0xC5, 0x06, b, 0xCD, BEEPER_NOISE & 0xFF, BEEPER_NOISE >> 8, 0xC1, 0x10, 0xF7,
                            0xC9])
        if stub:
            patch = bytes([0xCD, STUB & 0xFF, STUB >> 8, 0, 0, 0])
        if patch:
            rig.poke(TUNE_SITE, patch)
        path = os.path.join(AUDIO, name + '.wav')
        rig.record(path)
        rig.run(frames)
        rig.done()
        x, rate = read_wav(path)
        a, b = sounding(x, rate)
        meta[name] = {'caller': caller, 'patch': patch.hex() if patch else None, 'stub': stub, 'frames': frames,
                      'rate': rate, 'first_s': a / rate, 'last_s': b / rate, 'sounding_s': (b - a) / rate}
        print(f'{name}: {caller}: sounds {a / rate:.3f}-{b / rate:.3f} s ({(b - a) / rate * 1000:.1f} ms)', flush=True)
    json.dump(meta, open(os.path.join(AUDIO, 'renders.json'), 'w'), indent=1)


TUNE_STOPPED, TUNE_POINTER_A = 0xB6E4, 0xB6E6


def render_ay(work, frames=7000):
    """the 128K title tune: work/docs/docB/audio/play128.szx (the menu of a 128K tape load, saved from the rig
    re_session.py capture --media build/Exolon.tzx --model 128K --load-frames 12200 leaves) left alone; AY 1 captured;
    TuneStopped $B6E4 and the stream pointers $B6E6-$B6EB read every frame"""
    rig = Rig(work)
    rig.source = 'ay1'
    rig.load(os.path.join(AUDIO, 'play128.szx'))
    path = os.path.join(AUDIO, 'ay-title-tune.wav')
    rig.record(path)
    log = []
    for f in range(frames):
        m = rig.m.read(TUNE_STOPPED, 8)
        log.append((f, m[0], B.word(m, 2), B.word(m, 4), B.word(m, 6)))
        rig.run(1)
    rig.done()
    json.dump({'rate': rig.rate, 'every': 1, 'log': log}, open(os.path.join(AUDIO, 'ay-title-tune.json'), 'w'))
    print('wrote', path)


# the AY effects: (file name, starter, what calls it in the game)
SFX = [
    ('shot', 0xC177, 'FireControl $8372, the laser shot'),
    ('noise-burst', 0xC0E7, 'MoveShots $8417, a shot meets a thing'),
    ('blast', 0xC148, 'FireShell $909F, $91A9, GrenadeBlast $9427'),
    ('explosion', 0xC155, 'a thing shot ($9B79 and four more)'),
    ('grenade', 0xC1BE, 'ThrowGrenade $9254'),
    ('noise-sweep', 0xC13B, 'Guns $9DBB, a gun\'s shot'),
    ('trill', 0xC12E, 'bonus count $9EAF, PickupsVsPlayer $A32B'),
    ('ammo-refill', 0xC0F4, 'ammunition set to 99 ($9980, $9F65)'),
    ('grenade-refill', 0xC101, 'grenades set to 10 ($99D6)'),
    ('pulse', 0xC162, 'Teleports $98F3, $9928'),
    ('hum', 0xC1A9, 'ForceFieldStep $ABD6, every pass while on'),
    ('jingle-a', 0xC10E, 'no caller'),
    ('jingle-b', 0xC116, 'no caller'),
    ('wobble', 0xC126, 'no caller'),
    ('rise', 0xC16F, 'no caller'),
    ('chord', 0xC17F, 'no caller'),
    ('fanfare', 0xC195, 'no caller'),
]
SFX_STUB = 0x803D            # PlayTwoTones, beeper only: unused on a 128K, uncontended
SFX_SITE = 0x6DC9            # MainMenu's JR NZ,MenuReady on a 128K, after TuneStart
SFX_DELAY = 1680             # 26 T a loop: about 46 000 T a tick, a third of a 138 347 T pass (doc 04's median)


def menu_snapshot(rig):
    """play128.szx (the rig's machine after its capture: in play, GAME OVER and its beeper jingle at about frame 1790,
    MainMenu at about 2510) run with MainMenu's $6DC9 made JR $ until the CPU waits there; saved as menu128.szx"""
    rig.load(os.path.join(AUDIO, 'play128.szx'))
    rig.poke(SFX_SITE, [0x18, 0xFE])
    f = 0
    while rig.m.get('/registers')['special']['pc'] != SFX_SITE:
        rig.s.call('control_execution', {'action': 'run_frames', 'frames': 10})
        f += 10
        assert f < 4000
    path = os.path.join(AUDIO, 'menu128.szx')
    rig.m.post('/snapshot/save', {'path': path})
    print('menu reached at frame', f)
    return path


def render_sfx(work, frames=150):
    """each AY effect alone: menu128.szx (menu_snapshot) loaded, a stub at $803D (DI, AySilence $B753, the starter,
    then SoundEffectsTick $BF7E and a delay loop forever), $6DC9 made JP $803D, 150 frames captured from AY 1"""
    rig = Rig(work)
    rig.source = 'ay1'
    menu = menu_snapshot(rig)
    meta = {}
    for name, starter, caller in SFX:
        rig.load(menu)
        loop = 7
        stub = [0xF3, 0xCD, 0x53, 0xB7, 0xCD, starter & 0xFF, starter >> 8,
                0xCD, 0x7E, 0xBF, 0x01, SFX_DELAY & 0xFF, SFX_DELAY >> 8, 0x0B, 0x78, 0xB1, 0x20, 0xFB,
                0x18, (loop - 20) & 0xFF]
        rig.poke(SFX_STUB, stub)
        rig.poke(SFX_SITE, [0xC3, SFX_STUB & 0xFF, SFX_STUB >> 8])
        path = os.path.join(AUDIO, f'sfx-{name}.wav')
        rig.record(path)
        rig.run(frames)
        rig.done()
        x, rate = read_wav(path)
        env = np.array([np.abs(x[k:k + rate // 100]).max() for k in range(0, len(x), rate // 100)])
        on = np.flatnonzero(env > 100)
        meta[name] = {'starter': f'${starter:04X}', 'caller': caller,
                      'first_s': float(on[0] / 100) if len(on) else None,
                      'last_s': float(on[-1] / 100) if len(on) else None}
        print(name, meta[name], flush=True)
    json.dump({'rate': rate, 'delay': SFX_DELAY, 'sfx': meta}, open(os.path.join(AUDIO, 'sfx.json'), 'w'), indent=1)


# --- the figures of the renders --------------------------------------------------------------------------------------

STEP_T = 96                  # PlayTwoTones: T-states a loop step, every path (the pads)
CPU = 3500000


def beeper_notes(start):
    """a PlayTune tune as (start s, length s, f1, f2): a voice toggles at each wrap, a full wave is 2 (256 - reload)
    steps"""
    M = B.image()
    out, t, p = [], 0.0, start
    while M[p]:
        L, n1, n2 = M[p], M[p + 1], M[p + 2]
        d = L * 256 * STEP_T / CPU
        f = [CPU / (2 * (256 - M[0x8062 + n]) * STEP_T) for n in (n1, n2)]
        out.append((t, d, f[0], f[1]))
        t += d
        p += 3
    return out


def spectrogram(ax, x, rate, t0=0.0, fmax=4000, nfft=4096, hop=1024):
    from matplotlib import mlab
    sp, fr, tt = mlab.specgram(x - x.mean(), NFFT=nfft, Fs=rate, noverlap=nfft - hop)
    keep = (fr > 40) & (fr < fmax)
    db = 10 * np.log10(sp[keep] + 1e-9)
    ax.pcolormesh(tt + t0, fr[keep], db, shading='auto', cmap='magma', vmin=db.max() - 60, vmax=db.max())
    ax.set_yscale('log')
    ax.set_ylim(60, fmax)
    ticks = [t for t in (100, 200, 400, 800, 1600, 3200, 6400) if t < fmax]
    ax.set_yticks(ticks)
    ax.set_yticklabels([str(t) for t in ticks])
    ax.minorticks_off()
    ax.set_ylabel('Hz')


def beeptunes():
    meta = json.load(open(os.path.join(AUDIO, 'renders.json')))
    B.style()
    fig, axs = plt.subplots(2, 1, figsize=(B.WIDTH, 10.5), gridspec_kw={'height_ratios': [3, 2]})
    for ax, name, start, title in ((axs[0], 'title-tune', 0x7DA3, 'TitleTune $7DA3'),
                                   (axs[1], 'jingle', 0x7D68, 'JingleTune $7D68')):
        x, rate = read_wav(os.path.join(AUDIO, name + '.wav'))
        a = meta[name]['first_s']
        x = x[int(a * rate):]
        notes = beeper_notes(start)
        total = notes[-1][0] + notes[-1][1]
        spectrogram(ax, x[:int((total + 0.3) * rate)], rate, nfft=4096 if name == 'title-tune' else 2048,
                    hop=1024 if name == 'title-tune' else 256)
        for t, d, f1, f2 in notes:
            ax.plot([t, t + d], [f1, f1], color=(0.3, 0.9, 1.0), lw=2)
            ax.plot([t, t + d], [f2, f2], color=(0.5, 1.0, 0.4), lw=2)
        ax.set_xlim(0, total + 0.3)
        ax.set_title(B.wrap(f'{title}: {len(notes)} notes, model {total:.2f} s, rendered '
                            f'{meta[name]["sounding_s"]:.2f} s (the speaker moving); lines: the model\'s voice 1 '
                            '(cyan) and voice 2 (green) on the render\'s spectrum', 100), fontsize=11)
        ax.set_xlabel('seconds from the first note')
    B.suptitle(fig, 'The 48K tunes are two square waves at once: every model note lies on the rendered spectrum, '
               'and the length fits 96 T a loop step')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'beeper-tunes.png'))


BEEPER_SHOWN = ['noise-28-bonus-tick', 'noise-3c-fire', 'noise-c8-key-click', 'noise-14x20-shot-hit',
                'noise-1ex10-shell', 'sweep-pod', 'noise-3cx80-bravery']


def beepfx():
    meta = json.load(open(os.path.join(AUDIO, 'renders.json')))
    B.style()
    fig, axs = plt.subplots(len(BEEPER_SHOWN), 1, figsize=(B.WIDTH, 13))
    for ax, name in zip(axs, BEEPER_SHOWN):
        x, rate = read_wav(os.path.join(AUDIO, name + '.wav'))
        m = meta[name]
        a = int(m['first_s'] * rate)
        span = max(m['sounding_s'] * 1.15, 0.006)
        seg = x[a - rate // 2000: a + int(span * rate)]
        lvl = (seg > (x.max() + x.min()) / 2).astype(float)
        tt = (np.arange(len(seg)) - rate // 2000) / rate * 1000
        ax.fill_between(tt, 0, lvl, step='post', color=B.COLOURS[0], lw=0)
        ax.set_yticks([])
        ax.set_xlim(tt[0], tt[-1])
        ax.set_ylabel('speaker', fontsize=10.5)
        ax.set_title(f'{m["caller"]}: {m["sounding_s"] * 1000:.1f} ms of speaker movement', fontsize=11, loc='left')
    axs[-1].set_xlabel('ms from the first speaker change (each panel its own scale)')
    B.suptitle(fig, 'The 48K effects: BeeperNoise $7C26 is B pulses of random level, each one loop shorter (the '
               'pulses shrink to the end); BeeperSweep $7C3C is 16 steps of 10 half-waves, each step a longer wave '
               '(falling pitch)')
    fig.tight_layout(rect=(0, 0, 1, 0.92), h_pad=0.8)
    B.save(fig, B.out('sound', 'beeper-effects.png'))


def ay_measured():
    """each note's read frame (the first frame whose stream pointer has passed it) against its model tick"""
    ch = ay_streams()
    d = json.load(open(os.path.join(AUDIO, 'ay-title-tune.json')))
    log = d['log']
    pts = {}
    for k, name in enumerate('ABC'):
        aft, j, fr = AFTER[name], 0, []
        for f, *r in log:
            if j < len(aft) and r[1 + k] == aft[j]:
                fr.append(f)
                j += 1
        pts[name] = (np.array([e[0] for e in ch[name][0]][:len(fr)]), np.array(fr))
    t = np.concatenate([v[0] for v in pts.values()])
    f = np.concatenate([v[1] for v in pts.values()])
    a, b = np.polyfit(t, f, 1)
    stop = next(r[0] for r in log if r[1] == 0xFF)
    return ch, pts, a, b, stop, d['rate']


def aymeasured():
    ch, pts, a, b, stop, rate = ay_measured()
    x, rate = read_wav(os.path.join(AUDIO, 'ay-title-tune.wav'))
    fps = rate / (len(x) / len(json.load(open(os.path.join(AUDIO, 'ay-title-tune.json')))['log']))
    B.style()
    fig, axs = plt.subplots(3, 1, figsize=(B.WIDTH, 12.5), gridspec_kw={'height_ratios': [3, 2, 1.3]})
    ax = axs[0]
    lo, hi = 70.0, 15.0
    t0, t1 = 60, 75                 # seconds of the capture shown
    seg = x[int(t0 * rate):int(t1 * rate)]
    spectrogram(ax, seg, rate, t0=t0, fmax=3000)
    for k, name in enumerate('ABC'):
        ev = ch[name][0]
        for (tk, dur, per, nz), fr in zip(ev, pts[name][1]):
            s0 = fr / fps
            s1 = (a * (tk + dur) + b) / fps
            if s1 < t0 or s0 > t1 or nz:
                continue
            fq = AY_CLOCK / 16 / per
            ax.plot([s0, s1], [fq, fq], color=B.COLOURS[k + 1], lw=1.6)
    ax.set_xlim(t0, t1)
    ax.set_title(B.wrap(f'seconds {t0}-{t1} of the capture: the model\'s tone notes (A, B, C in three colours, '
                        'placed at their measured read frames) on the rendered spectrum', 100), fontsize=11)
    ax.set_xlabel('seconds of the capture')
    ax = axs[1]
    for k, name in enumerate('ABC'):
        tk, fr = pts[name]
        ax.plot(tk, fr, '.', ms=3, color=B.COLOURS[k + 1], label=f'channel {name}: {len(fr)} notes')
    tt = np.array([0, 6480])
    ax.plot(tt, a * tt + b, color=B.TEXT, lw=0.8, ls='--', label=f'{1 / a:.3f} ticks a frame')
    ax.axhline(stop, color=B.DIM, lw=1)
    ax.text(100, stop - 350, f'TuneStopped $B6E4 = $FF at frame {stop}', fontsize=10.5, va='top')
    ax.set_xlabel('model tick of the note')
    ax.set_ylabel('capture frame')
    ax.legend(loc='lower right')
    ax.set_title('every note\'s read frame against its model tick: one straight line', fontsize=11)
    ax = axs[2]
    for k, name in enumerate('ABC'):
        tk, fr = pts[name]
        ax.plot(tk, fr - (a * tk + b), '.', ms=3, color=B.COLOURS[k + 1])
    t = np.concatenate([v[0] for v in pts.values()])
    f = np.concatenate([v[1] for v in pts.values()])
    res = f - (a * t + b)
    ax.set_ylabel('frames off')
    ax.set_xlabel('model tick of the note')
    ax.set_title(B.wrap(f'off the line: at most {np.abs(res).max():.1f} frames (a tick is {a:.2f} frames; the '
                        'ticks follow the star draws)', 100), fontsize=11)
    n = sum(len(v[0]) for v in pts.values())
    B.suptitle(fig, f'The 128K title tune as rendered: all {n} model notes found in order, {1 / a:.2f} ticks a '
               f'frame, 6480 ticks = {6480 * a:.0f} frames ({6480 * a / 50.0:.1f} s)')
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    B.save(fig, B.out('sound', 'ay-tune-measured.png'))


def ayfx_part(names, out, title):
    meta = json.load(open(os.path.join(AUDIO, 'sfx.json')))['sfx']
    B.style()
    cols = 2
    rows = (len(names) + cols - 1) // cols
    fig, axs = plt.subplots(rows, cols, figsize=(B.WIDTH, 2.75 * rows + 1.3), squeeze=False)
    for ax, name in zip(axs.flat, names):
        x, rate = read_wav(os.path.join(AUDIO, f'sfx-{name}.wav'))
        m = meta[name]
        end = min(len(x) / rate, max(0.3, m['last_s'] + 0.1))
        spectrogram(ax, x[:int(end * rate)], rate, fmax=8000, nfft=1024, hop=128)
        ax.set_xlim(0, end)
        ax.set_title(f'{name} {m["starter"]}: {m["last_s"]:.2f} s\n{m["caller"][:60]}', fontsize=11)
        ax.set_xlabel('s')
    for ax in list(axs.flat)[len(names):]:
        ax.axis('off')
    B.suptitle(fig, title)
    fig.tight_layout(rect=(0, 0, 1, 1 - 0.75 / (2.75 * rows + 1.3)))
    B.save(fig, B.out('sound', out))


def ayfx():
    """the 17 AY effects in two figures: the 11 with a caller, then the 6 starters no code calls"""
    names = [n for n, _, _ in SFX]
    ayfx_part(names[:11], 'ay-effects.png', 'The 11 AY effects the game starts, rendered one by one (stub at $803D: '
              'the starter, then SoundEffectsTick about 46 000 T apart); a spectrogram each, its caller below the '
              'name')
    ayfx_part(names[11:], 'ay-effects-orphans.png', 'The 6 AY effect starters no code calls, rendered the same way: '
              'they work, the game never asks for them')


if __name__ == '__main__':
    if sys.argv[1] == 'render-sfx':
        render_sfx(sys.argv[sys.argv.index('--work') + 1])
    elif sys.argv[1] == 'render-ay':
        render_ay(sys.argv[sys.argv.index('--work') + 1])
    elif sys.argv[1] == 'render':
        render(sys.argv[sys.argv.index('--work') + 1])
    else:
        {'aytune': aytune, 'beeptunes': beeptunes, 'beepfx': beepfx, 'aymeasured': aymeasured,
         'ayfx': ayfx}[sys.argv[1]]()
