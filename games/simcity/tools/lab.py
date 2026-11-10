"""A live unreal-qt instance of the SimCity case, driven through MCP: a fresh 48K (RAM zeroed, a Kempston card,
muted), the tape loaded as a user does (LOAD "" typed, the tape played at signal speed: the game's own loader
`$FEBD` is no ROM LD-BYTES, so no trap applies) or a snapshot, keys held over emulated frames, memory read, screens
saved, states saved and restored. The base of the case's exploration and of its bot; a recording is started on it
only once no state is restored any more.

    lab = Lab(port_base=37020); lab.load_tape('orig/SimCity.tzx.zip'); lab.keys(['P']); lab.run(20) ... lab.close()
    python3 tools/lab.py serve --port-base 37030      # an instance that outlives the script (pid in work/stage1/lab-PORT.pid)
    lab = Lab(37030, attach=True)                     # drive it from later scripts; close() leaves it running
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


class Lab:
    def __init__(self, port_base=37020, binary=None, model='48K', attach=False):
        self.binary = binary or os.environ.get('BIN') or os.environ['UNREAL_BINARY']
        self.port_base = port_base
        self.model = model
        self.attached = attach
        self.process = None if attach else mcplib.launch(self.binary, port_base)
        self.s = mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', model)
        if attach:
            self.m = corpus.Machine(self.s, port_base)
            self.url = self.m.url
            self.held = []
            self.frame = 0
            self.s.call('control_execution', {'action': 'take_control'}, ok=False)
            return
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

    def load_tape(self, media, load_frames=17000):
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

    def insert_tape(self, path, play=True):
        """Puts a tape file in the running machine (no reset) and starts it, at signal speed: the game enters ROM
        LD-BYTES past its start (`$0562`), where the fast-load trap does not belong"""
        for name in ('fast_tape', 'turbo_tape'):
            self.s.call('invoke_api', {'method': 'PUT', 'path': f'/api/v1/emulator/{{id}}/settings/{name}',
                                       'body': {'value': False}}, ok=False)
        self.post('/tape/load', {'path': os.path.abspath(path)})
        if play:
            self.post('/tape/play', {})

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
            json.dump({'pid': self.process.pid if self.process else self.pid_file_pid(), 'binary': self.binary, 'port_base': self.port_base,
                       'model': self.model, 'ranges': ranges}, f)

    def pid_file_pid(self):
        p = os.path.join(CASE, 'work', 'stage1', f'lab-{self.port_base}.pid')
        return int(open(p).read()) if os.path.exists(p) else None

    def close(self):
        if self.process is None:
            return
        self.process.terminate()
        try:
            self.process.wait(10)
        except subprocess.TimeoutExpired:
            self.process.kill()


if __name__ == '__main__' and len(sys.argv) > 1 and sys.argv[1] == 'serve':
    pb = int(sys.argv[sys.argv.index('--port-base') + 1]) if '--port-base' in sys.argv else 37030
    lab = Lab(pb)
    with open(os.path.join(CASE, 'work', 'stage1', f'lab-{pb}.pid'), 'w') as f:
        f.write(str(lab.process.pid))
    print('serving', pb, 'pid', lab.process.pid)
