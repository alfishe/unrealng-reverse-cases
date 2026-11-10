#!/usr/bin/env python3
"""The UKNC port's integer AimShot (tools/uknc_aimcheck.py, aim_int; doc 14, 14.6.3) against the game's own AimShot
`$8A02` run on the ROM calculator of a live 48K (doc 14, 14.7, 14.8 risk 1).

    python3 tools/uknc_romcheck.py [--set game|sample] [--port-base 36810] [--out work/review/romcheck]
                                   [--snapshot work/snaps/ready.szx] [--limit N]

A small driver in free RAM (`$C600`, doc 02's map: `$C600-$CFBF` free) runs, with interrupts off, a table of cases
from `$E1A8` (free, `$E1A8-$EFFF`): for each it writes CursorX `$86BA`, CursorY `$86BB`, the cue ball's whole-pixel
x `$8A89` and y `$8A8B` and Power `$86BF`, CALLs AimShot `$8A02` (unchanged: SET-MIN, STACK-A, RST $28, SQR, the
divisions, ScaleByPower `$8A5D`, FP-TO-BC, FrictionSteps, whose RET comes back to the driver) and copies the cue
ball's vy `$8A8E` and vx `$8A8C` into the table. One skip_until runs a whole table (408 cases, about 186 million T).

AimShot reads only CursorX - cue x and CursorY - cue y (STACK-A of whole pixels, exact in the calculator), so a case
is (dx, dy, P); the driver places the cursor and the cue ball to give it (dx = cursor x - cue x, each 0..255).

Sets:
  game    every input the game can give (default): the cursor on the cushion line (x 3..252 on rows 51 and 180, y
          51..180 on columns 3 and 252), the cue ball inside the clamps (x 7..248, y 55..176): |dx| <= 245,
          |dy| <= 125, not both |dx| <= 3 and |dy| <= 3 (123 192 directions), and the 63 even powers 2..126
          (the power only grows by 2; `$80`-`$84` are read as `$7E`): 7 761 096 cases
  sample  a stratified sample: the edges (dx 0, dy 0, |dx| 245, |dy| 125, the shortest distances, the four quadrants,
          P 2, P 126 and the stored `$80`-`$84`) and random directions, about 20 000 cases (seed 1)

Result (2026-11-09): game 7 761 096 inputs, 0 differences from aim_int, 80 from the exact rounding (the near-halves of doc 14,
14.6.3); sample 18 948 inputs, 0 and 0. Four machines in one instance (--workers) run about 1600 cases a second.

Writes OUT/<set>.bin (per case dx, dy, P as int16, int16, uint8, then the ROM's vy, vx), OUT/<set>.txt (the result
line and every difference) and prints the result line. Resumes a set from OUT/<set>.bin. The instance is launched
offscreen on --port-base (six ports: base, +100 .. +500, checked free), muted, and stopped at the end; its
--workers 48K machines each hold the snapshot under a WebAPI control session of this script.
"""
import argparse
import json
import os
import random
import struct
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from uknc_aimcheck import aim_int, aim_model  # noqa: E402

AIMSHOT, CURSORX, CURSORY, POWER, CUEX, CUEY, VX, VY = 0x8A02, 0x86BA, 0x86BB, 0x86BF, 0x8A89, 0x8A8B, 0x8A8C, 0x8A8E
DRIVER, TABLE, TABLE_END = 0xC600, 0xE1A8, 0xF000
REC = 9                       # cursor x, cursor y, cue x, cue y, power; vy (2), vx (2)
BATCH = (TABLE_END - TABLE) // REC
POWERS = list(range(2, 127, 2))


def w(v):
    return [v & 0xFF, v >> 8]


def driver():
    """The driver at DRIVER: DI; SP below the game's stack; for BC cases from TABLE: inputs, CALL AimShot, vy, vx"""
    code = [0xF3, 0x31] + w(0xCFC0)                       # DI; LD SP,$CFC0
    code += [0x21] + w(TABLE)                             # LD HL,TABLE
    code += [0xED, 0x4B] + w(DRIVER + 0xF0)               # LD BC,(count)
    loop = len(code)
    code += [0x78, 0xB1, 0x28, 0x00]                      # LD A,B; OR C; JR Z,done
    jz = len(code) - 1
    code += [0xC5]                                        # PUSH BC
    for addr in (CURSORX, CURSORY, CUEX, CUEY, POWER):
        code += [0x7E, 0x32] + w(addr) + [0x23]           # LD A,(HL); LD (addr),A; INC HL
    code += [0xE5, 0xCD] + w(AIMSHOT) + [0xE1]            # PUSH HL; CALL AimShot; POP HL
    for addr in (VY, VX):
        code += [0xED, 0x5B] + w(addr) + [0x73, 0x23, 0x72, 0x23]   # LD DE,(addr); LD (HL),E; INC HL; LD (HL),D; INC HL
    code += [0xC1, 0x0B, 0x18, 0x00]                      # POP BC; DEC BC; JR loop
    code[-1] = (loop - len(code)) & 0xFF
    done = len(code)
    code[jz] = (done - jz - 1) & 0xFF
    code += [0x18, 0xFE]                                  # done: JR done
    return code, DRIVER + done


def place(dx, dy):
    """cursor and cue bytes giving dx, dy"""
    cx, bx = (dx, 0) if dx >= 0 else (0, -dx)
    cy, by = (dy, 0) if dy >= 0 else (0, -dy)
    return cx, cy, bx, by


def game_set():
    out = []
    for dx in range(-245, 246):
        for dy in range(-125, 126):
            if abs(dx) <= 3 and abs(dy) <= 3:
                continue
            for p in POWERS:
                out.append((dx, dy, p))
    return out


def sample_set():
    rnd = random.Random(1)
    dirs = set()
    for d in range(-245, 246):
        if abs(d) > 3:
            dirs.add((d, 0))                                 # dy = 0: the cursor on the cue ball's row
    for d in range(-125, 126):
        if abs(d) > 3:
            dirs.add((0, d))                                 # dx = 0
    for sx in (1, -1):
        for sy in (1, -1):
            for a in range(0, 246):
                for b in (4, 125):
                    dirs.add((sx * a, sy * b))               # |dy| at its smallest and largest on the rows
            for b in range(0, 126):
                for a in (4, 245):
                    dirs.add((sx * a, sy * b))               # |dx| likewise on the columns
            for a, b in ((4, 0), (4, 1), (4, 4), (3, 4), (5, 5), (245, 125), (245, 124), (244, 125)):
                dirs.add((sx * a, sy * b))                   # the shortest and longest distances
                dirs.add((sx * b, sy * a)) if b <= 125 and a <= 245 else None
    dirs = sorted(dirs)
    cases = []
    for dx, dy in dirs:
        for p in (2, 126, rnd.choice(POWERS)):
            cases.append((dx, dy, p))
    for p in (0x80, 0x82, 0x84):                             # the stored powers above $7E (read as $7E)
        for dx, dy in ((245, 125), (-245, 125), (100, -7), (0, 50), (-60, 0)):
            cases.append((dx, dy, p))
    for _ in range(8000):                                    # random directions inside the game's range, every power
        while True:
            dx, dy = rnd.randint(-245, 245), rnd.randint(-125, 125)
            if not (abs(dx) <= 3 and abs(dy) <= 3):
                break
        cases.append((dx, dy, rnd.choice(POWERS)))
    seen, uniq = set(), []
    for c in cases:
        if c not in seen:
            seen.add(c)
            uniq.append(c)
    return uniq


class Instance:
    """One unreal-qt on its own ports (all six checked free), offscreen; WORKERS 48K machines in it, each muted, with
    the snapshot loaded, paused and under a WebAPI control session of this script"""

    def __init__(self, port_base, snapshot, workers=1):
        import socket
        import lab
        for off in range(0, 600, 100):
            with socket.socket() as s:
                if s.connect_ex(('127.0.0.1', port_base + off)) == 0:
                    raise SystemExit(f'port {port_base + off} is taken')
        binary = os.environ.get('BIN') or os.environ['UNREAL_BINARY']
        self.process = lab.mcplib.launch(binary, port_base)
        self.port_base = port_base
        self.workers = []
        try:
            s = lab.mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', '48K')
            for e in (s.call('emulator_manage', {'action': 'list'}, ok=False).structured or {}).get('emulators', []):
                s.call('emulator_manage', {'action': 'destroy', 'target': e['id']}, ok=False)
            for _ in range(workers):
                s.call('emulator_manage', {'action': 'create', 'model': '48K', 'ram_power_on': 'zero'})
            ids = [e['id'] for e in s.call('emulator_manage', {'action': 'list'}, ok=False).structured['emulators']]
            for eid in ids:
                self.workers.append(Worker(port_base, eid, snapshot))
        except BaseException:
            self.close()
            raise

    def close(self):
        for wk in self.workers:
            wk.release()
        self.process.terminate()
        try:
            self.process.wait(10)
        except Exception:
            self.process.kill()


class Worker:
    def __init__(self, port_base, eid, snapshot):
        self.eid = eid
        self.url = f'http://127.0.0.1:{port_base}/api/v1/emulator/{eid}'
        self.session = None
        self.session = self.http('POST', '/control/session', {'client': 'uknc_romcheck', 'surface': 'webapi',
                                                              'lease_seconds': 600})['session']
        self.mute()
        self.http('POST', '/pause', {})
        r = self.http('POST', '/snapshot/load', {'path': os.path.abspath(snapshot)})
        if r.get('status') == 'error':
            raise SystemExit(f'snapshot load refused: {r}')
        self.mute()
        self.http('POST', '/pause', {})

    def mute(self):
        self.http('PUT', '/audio/mixer/master', {'muted': True})

    def http(self, method, path, body=None, timeout=900, binary=False):
        headers = {'Content-Type': 'application/json'}
        if self.session:
            headers['X-Unreal-Session'] = self.session
        req = urllib.request.Request(self.url + path, data=None if body is None else json.dumps(body).encode(),
                                     method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                raw = r.read()
        except urllib.error.HTTPError as e:
            raise SystemExit(f'{method} {path}: {e.code} {e.read()[:400]!r}')
        return raw if binary else json.loads(raw) if raw else {}

    def write(self, addr, data):
        for i in range(0, len(data), 4096):
            self.http('PUT', f'/memory/{addr + i}', {'data': list(data[i:i + 4096])})

    def read(self, addr, n):
        return self.http('GET', f'/memory/read/{addr}?length={n}&format=binary', timeout=60, binary=True)

    def reg(self, name, value):
        self.http('PUT', f'/registers/{name}', {'value': value})

    def release(self):
        try:
            self.mute()
            self.http('DELETE', '/control/session', timeout=10)
        except (SystemExit, OSError):
            pass


def run_batch(inst, done_pc, cases):
    tbl = []
    for dx, dy, p in cases:
        cx, cy, bx, by = place(dx, dy)
        tbl += [cx, cy, bx, by, p, 0, 0, 0, 0]
    inst.write(TABLE, tbl)
    inst.write(DRIVER + 0xF0, w(len(cases)))
    inst.reg('iff1', 0)
    inst.reg('iff2', 0)
    inst.reg('pc', DRIVER)
    r = inst.http('POST', '/skip_until', {'pc': done_pc, 'max_tstates': 700000000})
    if not (isinstance(r, dict) and r.get('hit')):
        raise SystemExit(f'the driver did not reach its end: {r}')
    m = inst.read(TABLE, len(tbl))
    return [(m[i * REC + 5] | m[i * REC + 6] << 8, m[i * REC + 7] | m[i * REC + 8] << 8) for i in range(len(cases))]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--set', choices=('game', 'sample'), default='game')
    ap.add_argument('--port-base', type=int, default=36810)
    ap.add_argument('--out', default=os.path.join(CASE, 'work', 'review', 'romcheck'))
    ap.add_argument('--snapshot', default=os.path.join(CASE, 'work', 'snaps', 'ready.szx'))
    ap.add_argument('--workers', type=int, default=4, help='machines in the instance run at once (the WebAPI runs '
                    'at most 4 long calls together)')
    ap.add_argument('--limit', type=int, default=0, help='run at most N cases (a timing probe)')
    ap.add_argument('--report-only', action='store_true', help='compare the saved results, no instance')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    cases = game_set() if a.set == 'game' else sample_set()
    if a.limit:
        cases = cases[:a.limit]
    path = os.path.join(a.out, a.set + '.bin')
    rec = struct.Struct('<hhBHH')
    have = os.path.getsize(path) // rec.size if os.path.exists(path) else 0
    if have > len(cases):
        have = len(cases)
    if have < len(cases) and not a.report_only:
        inst = Instance(a.port_base, a.snapshot, a.workers)
        try:
            code, done_pc = driver()
            assert len(code) < 0xF0
            for wk in inst.workers:
                wk.write(DRIVER, code)
                head = wk.read(AIMSHOT, 4)
                if bytes(head) != bytes([0xFD, 0x21, 0x3A, 0x5C]):
                    raise SystemExit(f'AimShot is not at $8A02 in the snapshot: {bytes(head).hex()}')
            t0, nw = time.time(), len(inst.workers)
            step = BATCH * nw
            with open(path, 'r+b' if have else 'wb') as f, ThreadPoolExecutor(nw) as ex:
                f.seek(have * rec.size)
                f.truncate()
                for i in range(have, len(cases), step):     # a round: one table on each machine, its own thread
                    parts = [cases[j:j + BATCH] for j in range(i, min(i + step, len(cases)), BATCH)]
                    res = list(ex.map(lambda k: run_batch(inst.workers[k], done_pc, parts[k]), range(len(parts))))
                    for part, r in zip(parts, res):
                        for (dx, dy, p), (vy, vx) in zip(part, r):
                            f.write(rec.pack(dx, dy, p, vy, vx))
                    f.flush()
                    end = min(i + step, len(cases))
                    el = time.time() - t0
                    if (i // step) % 50 == 0 or end == len(cases):
                        print(f'{end}/{len(cases)} cases, {el:.0f} s, '
                              f'{(len(cases) - end) * el / (end - have) / 60:.1f} min left', flush=True)
        finally:
            inst.close()
    # compare
    data = open(path, 'rb').read()
    n = min(len(data) // rec.size, len(cases))
    bad, model_bad, dirs = [], 0, set()
    for i in range(n):
        dx, dy, p, vy, vx = rec.unpack_from(data, i * rec.size)
        assert (dx, dy, p) == cases[i], (i, (dx, dy, p), cases[i])
        dirs.add((dx, dy))
        pe = 0x7E if p >= 0x80 else p
        if aim_int(dx, dy, pe) != [vy, vx]:
            bad.append((dx, dy, p, vy, vx))
        if aim_model(dx, dy, pe) != [vy, vx]:
            model_bad += 1
    line = (f'{a.set}: {n} inputs ({len(dirs)} directions) through the ROM AimShot, {len(bad)} differences from aim_int, '
            f'{model_bad} from the exact rounding')
    with open(os.path.join(a.out, a.set + '.txt'), 'w') as f:
        f.write(line + '\n')
        for dx, dy, p, vy, vx in bad:
            pe = 0x7E if p >= 0x80 else p
            f.write('dx %d dy %d P %d: ROM vy $%04X vx $%04X, aim_int vy $%04X vx $%04X\n'
                    % (dx, dy, p, vy, vx, *aim_int(dx, dy, pe)))
    print(line)
    for x in bad[:20]:
        print('  dx %d dy %d P %d: ROM $%04X $%04X' % x, ['$%04X' % v for v in aim_int(*x[:2], 0x7E if x[2] >= 0x80 else x[2])])
    if n >= 1:
        for i in range(n):
            dx, dy, p, vy, vx = rec.unpack_from(data, i * rec.size)
            if (dx, dy, p) == (212, 15, 76):
                print('w1 break (212, 15, 76): ROM $%04X $%04X (vy, vx)' % (vy, vx))


if __name__ == '__main__':
    main()
