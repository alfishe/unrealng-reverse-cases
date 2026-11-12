"""A live unreal-qt instance of the Rick Dangerous case, driven through MCP: a fresh 48K or 128K (RAM zeroed, a Kempston
card, muted), the original tape loaded as a user does (`load_original`: LOAD "" typed on a 48K, the 128 menu's Tape
Loader on a 128K, the tape played at ROM speed or with the LD-BYTES trap) or a snapshot, keys held over emulated
frames, memory read, screens saved, states saved and restored. The base of the case's probes; a recording is started
on it only once no state is restored any more. `Lab(port_base, attach=True)` drives an instance already running on
that base (started by an earlier Lab with `keep=True`), so one instance serves many short scripts.

    lab = Lab(port_base=37495, model='128K'); lab.load_original(); lab.keys(['1']); lab.run(20) ... lab.close()
"""
import json
import os
import subprocess
import sys
import time
import types
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402
import zxscreen  # noqa: E402

UNREAL = K.unreal_root(None)
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import mcplib  # noqa: E402
import mm_session  # noqa: E402
import corpus  # noqa: E402


def tape_file():
    """The original TZX, unpacked unchanged from orig/RickDangerous.tzx.zip into work/media/orig/RickDangerous.tzx"""
    import zipfile
    out = os.path.join(CASE, 'work', 'media', 'orig', 'RickDangerous.tzx')
    if not os.path.exists(out):
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with zipfile.ZipFile(os.path.join(CASE, 'orig', 'RickDangerous.tzx.zip')) as z:
            open(out, 'wb').write(z.read('Rick Dangerous.tzx'))
    return out


class Lab:
    def __init__(self, port_base=37495, binary=None, model='48K', attach=False):
        self.binary = binary or os.environ.get('BIN') or os.environ['UNREAL_BINARY']
        self.port_base = port_base
        self.model = model
        self.held = []
        self.frame = 0
        if attach:
            self.process = None
            self.s = mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', model)
            self.s.call('control_execution', {'action': 'take_control'}, ok=False)
            self.m = corpus.Machine(self.s, port_base)
            self.url = self.m.url
            return
        self.process = mcplib.launch(self.binary, port_base)
        open(os.path.join(CASE, 'work', 'stage1', f'lab-{port_base}.pid'), 'w').write(str(self.process.pid))
        self.s = mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', model)
        self.s.fresh_machine(model, ram_power_on='zero')
        self.s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
        for _ in range(100):  # the plug restarts the machine: wait for the wired stick
            if 'slots_plug slot=edge.1' not in self.s.call('joystick_input', {'action': 'status'}, ok=False).text:
                break
            time.sleep(0.1)
        self.s.call('control_execution', {'action': 'pause'}, ok=False)
        self.mute()
        self.s.call('control_execution', {'action': 'take_control'}, ok=False)
        self.m = corpus.Machine(self.s, port_base)
        self.url = self.m.url
        self.held = []
        self.frame = 0

    def mute(self):
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                   'body': {'muted': True}}, ok=False)

    def post(self, path, body):
        r = self.s.call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}' + path, 'body': body})
        return (r.structured or {}).get('body') or {}

    def load_tape(self, media, load_frames=12000):
        """The tape as re_session.py capture loads it; returns the frames the load took"""
        media = os.path.abspath(media)
        if media.endswith('.zip'):
            media = corpus.unpack(media, os.path.join(CASE, 'work', 'media', 'lab'), corpus.MEDIA_SUFFIXES['tape'])
        report = {}
        args = types.SimpleNamespace(load_frames=load_frames, disk_boot_frames=0)
        frames = corpus.load(self.m, {'kind': 'tape', 'model': self.model}, media, report, args)
        self.mute()
        self.frame = frames
        return frames

    def tape(self):
        r = self.s.call('invoke_api', {'method': 'GET', 'path': '/api/v1/emulator/{id}/tape'}, ok=False)
        return (r.structured or {}).get('body') or {}

    def load_original(self, rom_speed=True, boot=None, path=None):
        """The original tape (unpacked from orig/ into work/media/orig/), the fast LD-BYTES trap and turbo off when
        @p rom_speed, LOAD "" typed (48K) or the 128 menu's Tape Loader taken with ENTER (128K), the tape played.
        The tape is left playing; returns the frames run so far"""
        self.s.call('load_software', {'path': os.path.abspath(path) if path else tape_file(), 'autostart': False,
                                      'play': False}, ok=False)
        if rom_speed:
            for name in ('fast_tape', 'turbo_tape'):
                self.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                           'body': {'value': False}}, ok=False)
        frames = corpus.run_frames(self.m, boot or corpus.TAPE_BOOT_FRAMES, None, 0)
        if self.model == '48K':
            for keys in (['j'], ['symbol', 'p'], ['symbol', 'p'], ['enter']):
                corpus.key_tap(self.m, keys)
            frames += 4 * 15
        else:
            corpus.key_tap(self.m, ['enter'])
            frames += 15
        self.m.post('/tape/play', None)
        self.mute()
        self.frame = frames
        return frames

    def load(self, path):
        self.post('/snapshot/load', {'path': os.path.abspath(path)})
        self.mute()
        self.frame = 0

    def save(self, path):
        self.post('/snapshot/save', {'path': os.path.abspath(path), 'force': True})

    def read(self, address, length):
        with urllib.request.urlopen(f'{self.url}/memory/read/{address}?length={length}&format=binary',
                                    timeout=30) as r:
            return r.read()

    def write(self, address, data):
        """Pokes @p data (bytes) at @p address: an experiment on a clone, never on a recording"""
        self.post('/memory/write', {'address': str(address), 'data': list(data)})

    def regs(self):
        return self.m.get('/registers')

    def run(self, frames):
        if frames > 0:
            self.s.call('control_execution', {'action': 'run_frames', 'frames': frames})
            self.frame += frames

    def shot(self, path, scale=2):
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
        zxscreen.render(self.read(0x4000, 6912), scale).save(path)

    def _key(self, key, down):
        action = 'press' if down else 'release'
        if key in mm_session.KEMPSTON:
            self.s.call('joystick_input', {'action': action, 'buttons': mm_session.KEMPSTON[key]}, ok=False)
        else:
            self.s.call('type_input', {'action': action, 'key': mm_session.KEY_NAMES.get(key, key.lower())})

    def keys(self, keys):
        """Holds exactly @p keys from now on (releases the others)"""
        for k in self.held:
            if k not in keys:
                self._key(k, False)
        for k in keys:
            if k not in self.held:
                self._key(k, True)
        self.held = list(keys)

    def tap(self, keys, hold=3, gap=5):
        self.keys(keys)
        self.run(hold)
        self.keys([])
        self.run(gap)

    def start_recording(self):
        self.s.call('analysis', {'action': 'start', 'record': True})

    def session_json(self, work, ranges='4000-FFFF'):
        """A re_session.py session.json in @p work, so `re_session.py build / stages / stop` work on this instance"""
        os.makedirs(work, exist_ok=True)
        with open(os.path.join(work, 'session.json'), 'w') as f:
            json.dump({'pid': self.process.pid, 'binary': self.binary, 'port_base': self.port_base,
                       'model': self.model, 'ranges': ranges}, f)

    def close(self):
        if self.process is None:
            return
        self.process.terminate()
        try:
            self.process.wait(10)
        except subprocess.TimeoutExpired:
            self.process.kill()
