"""A live unreal-qt instance of the Video Pool case, driven through MCP: a fresh 48K (RAM zeroed, a Kempston card,
muted), a snapshot loaded, keys held over emulated frames, memory read, states saved and restored. The base of the
case's bots (tools/shot_bot.py); a recording is started on it only once no state is restored any more.

    lab = Lab(port_base=34200); lab.load('work/snaps/entry.z80'); lab.keys(['B']); lab.run(20) ... lab.close()

The game's records read here (WALKTHROUGH 6.0, found in c1):
  - the balls $8A88, 7 records of 14 bytes: +0/+1 x (8.8), +2/+3 y (8.8), +13 flags (bit 7 on the table, bit 6
    moving), the cue ball first;
  - the cursor $86BA (x) / $86BB (y), on the cushion line.
"""
import json
import os
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

UNREAL = K.unreal_root(None)
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import mcplib  # noqa: E402
import mm_session  # noqa: E402

BALLS, BALL_SIZE, NBALLS = 0x8A88, 14, 7
CURSOR = 0x86BA


class Lab:
    def __init__(self, port_base=34200, binary=None, model='48K'):
        self.binary = binary or os.environ.get('BIN') or os.environ['UNREAL_BINARY']
        self.port_base = port_base
        self.process = mcplib.launch(self.binary, port_base)
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
        listing = self.s.call('emulator_manage', {'action': 'list'}, ok=False)
        self.url = f"http://127.0.0.1:{port_base}/api/v1/emulator/{listing.structured['emulators'][0]['id']}"
        self.held = []
        self.frame = 0

    def mute(self):
        self.s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                                   'body': {'muted': True}}, ok=False)

    def post(self, path, body):
        r = self.s.call('invoke_api', {'method': 'POST', 'path': '/api/v1/emulator/{id}' + path, 'body': body})
        return (r.structured or {}).get('body') or {}

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

    def run(self, frames):
        if frames > 0:
            self.s.call('control_execution', {'action': 'run_frames', 'frames': frames})
            self.frame += frames

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

    def balls(self):
        m = self.read(BALLS, BALL_SIZE * NBALLS)
        out = []
        for i in range(NBALLS):
            r = m[i * BALL_SIZE:(i + 1) * BALL_SIZE]
            out.append(dict(x=r[1] + r[0] / 256, y=r[3] + r[2] / 256, flags=r[13], raw=r.hex()))
        return out

    def cursor(self):
        m = self.read(CURSOR, 2)
        return m[0], m[1]

    def start_recording(self):
        self.s.call('analysis', {'action': 'start', 'record': True})

    def session_json(self, work, ranges='4000-FFFF'):
        """A re_session.py session.json in @p work, so `re_session.py build / stages / stop` work on this instance"""
        os.makedirs(work, exist_ok=True)
        with open(os.path.join(work, 'session.json'), 'w') as f:
            json.dump({'pid': self.process.pid, 'binary': self.binary, 'port_base': self.port_base, 'model': '48K',
                       'ranges': ranges}, f)

    def close(self):
        self.process.terminate()
        try:
            self.process.wait(10)
        except subprocess.TimeoutExpired:
            self.process.kill()
