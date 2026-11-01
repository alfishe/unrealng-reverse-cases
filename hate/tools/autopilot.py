#!/usr/bin/env python3
"""A player for H.A.T.E. that reads the game's own records (docs/07-objects.md) and steers the Kempston stick, so a
second recording reaches what the demo and random play never do: pods picked up, a round's end, the next round
(docs/10-gameplay-logic.md).

It plays from the loaded game (work/c2/start.szx: the menu), picks the Kempston reader (key 3) and starts (key 6).
Every pass it reads the object list at $C000 and the scroll distance $D14D through the WebAPI and decides the stick
for the next pass. The emulator is exact and the decisions depend only on memory, so a run with --record replays the
same game as the run without it.

    python3 autopilot.py --unreal <unreal-ng checkout> --binary <unreal-qt> --start work/c2/start.szx
                         --work work/p1 [--frames 20000] [--record] [--port-base 9780]
"""
import argparse
import json
import os
import sys
import time

TYPES = {0: 'player', 1: 'player', 2: 'dome', 3: 'dome', 4: 'missile', 5: 'missile', 6: 'missile', 7: 'missile',
         8: 'jet', 9: 'jet', 10: 'cube', 11: 'pod', 12: 'shot', 14: 'pad', 15: 'dish'}


THREATS = {4, 5, 6, 7, 8, 9, 10, 15}


def limit_of(profile_byte):
    """The highest position across the walls of one profile byte allow ($E94F: bit 7 $17, bit 6 $27, else $47)"""
    return 0x17 if profile_byte & 0x80 else 0x27 if profile_byte & 0x40 else 0x47


args_margin = 8
ALONG = [2, 1, 0, -1, -2, -1, 0, 1]  # $C340: the steps of the eight directions
ACROSS = [0, -1, -2, -1, 0, 1, 2, 1]


def size_of(kind):
    """A record's half of the hit box ($E555): 8 for types 0-3, 4 for 4-10, 0 for 11-13; 14-15 taken as 8"""
    return 8 if kind < 4 or kind > 13 else 4 if kind <= 10 else 0


def danger(me, a, h, threats, passes=14):
    """The smallest clearance over the next passes to any threat, the player steering toward across @p a and
    height @p h; below 0 means a hit is predicted"""
    worst = 99
    for r in threats:
        box = 7 + 8 + size_of(r['type']) + 3
        for k in range(1, passes + 1):
            d = r['dist'] + k * (ALONG[r['dir']] * r['speed'] - 2) + 2 * k - me['dist']
            x = r['across'] + k * ACROSS[r['dir']] * r['speed']
            step = min(4 * k, abs(a - me['across']))
            mx = me['across'] + (step if a > me['across'] else -step)
            hstep = min(3 * k, abs(h - me['height']))
            mh = me['height'] + (hstep if h > me['height'] else -hstep)
            clear = max(abs(d) - box, abs(x - mx) - box, abs(r['height'] - mh) - box)
            worst = min(worst, clear)
    return worst


def decide(st, profile, give_up=False):
    """The stick for the next pass from the records (docs/07-objects.md 7.1) and the profile ahead of the player;
    @p give_up steers into the nearest threat instead (to spend the lives: the fall back of docs/04 4.4)"""
    me = next((r for r in st['records'] if r['slot'] == 0xC000), None)
    if me is None or me['hit']:
        return [], 'down'
    if give_up:
        near = [r for r in st['records'] if r['type'] in THREATS and not r['hit'] and r['dist'] > me['dist']]
        if not near:
            return [], 'give up'
        r = min(near, key=lambda r: r['dist'])
        stick = ['left'] if me['across'] < r['across'] - 1 else ['right'] if me['across'] > r['across'] + 1 else []
        if me['type'] == 0:
            stick += ['down'] if me['height'] < r['height'] - 1 else ['up'] if me['height'] > r['height'] + 1 else []
        return stick, 'give up'
    room = min(limit_of(b) for b in profile) - 4
    goal, goal_h, why = min(0x2C, room - 6), 2, 'cruise'
    others = sorted((r for r in st['records'] if r['slot'] != 0xC000 and not r['hit']), key=lambda r: r['dist'])
    pods = [r for r in others if r['type'] == 11 and me['dist'] - 4 < r['dist'] < me['dist'] + 160]
    domes = [r for r in others if r['type'] == 3 and me['dist'] + 16 < r['dist'] < me['dist'] + 220]
    if pods:
        goal, goal_h, why = pods[0]['across'], pods[0]['height'], 'pod'
    elif domes:
        goal, goal_h, why = domes[0]['across'], 2, 'dome'
    threats = [r for r in others if (r['type'] in THREATS or (r['type'] == 12 and r['dir'] != 0))
               and -40 < r['dist'] - me['dist'] < 140]
    heights = [goal_h] + ([2, 8, 14, 20, 26] if me['type'] == 0 else [])
    best = None
    for a in range(3, max(4, room), 2):
        for h in heights:
            clear = danger(me, a, h, threats)
            score = (min(clear, args_margin), -abs(a - goal) - abs(h - goal_h))
            if best is None or score > best[0]:
                best = (score, a, h)
    _, target, height = best
    if best[0][0] < 0 or target != goal:
        why += ' dodge'
    stick = ['fire']
    if me['across'] < target - 1:
        stick.append('left')
    elif me['across'] > target + 1:
        stick.append('right')
    if me['type'] == 0:
        if me['height'] < height - 1:
            stick.append('down')
        elif me['height'] > height + 1:
            stick.append('up')
    return stick, why


class Game:
    def __init__(self, args):
        sys.path.insert(0, os.path.join(args.unreal, 'tools', 'verification', 'analysis'))
        import corpus  # noqa: E402
        from corpus import mcplib  # noqa: E402
        self.corpus = corpus
        self.process = mcplib.launch(args.binary, args.port_base)
        s = mcplib.Session(f'http://127.0.0.1:{args.port_base + 200}/mcp', '48K')
        s.fresh_machine('48K', ram_power_on='zero')
        s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
        for _ in range(100):  # the plug restarts the machine: wait for the wired stick
            if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
                break
            time.sleep(0.1)
        s.call('control_execution', {'action': 'pause'}, ok=False)
        s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                              'body': {'muted': True}}, ok=False)
        self.s = s
        self.m = corpus.Machine(s, args.port_base)
        self.m.post('/snapshot/load', {'path': os.path.abspath(args.start)})
        self.held = set()
        self.frame = 0

    def stick(self, buttons):
        """Holds exactly @p buttons (fire, left, right, up, down)"""
        buttons = set(buttons)
        for b in self.held - buttons:
            self.s.call('joystick_input', {'action': 'release', 'buttons': b}, ok=False)
        for b in buttons - self.held:
            self.s.call('joystick_input', {'action': 'press', 'buttons': b}, ok=False)
        self.held = buttons

    def key(self, key, hold=5, gap=20):
        self.s.call('type_input', {'action': 'press', 'key': key}, ok=False)
        self.run(hold)
        self.s.call('type_input', {'action': 'release', 'key': key}, ok=False)
        self.run(gap)

    def run(self, frames):
        self.s.call('control_execution', {'action': 'run_frames', 'frames': frames})
        self.frame += frames

    def state(self):
        mem = self.m.read(0xC000, 0x300)
        scrolled = int.from_bytes(self.m.read(0xD14D, 2), 'little')
        records = []
        for a in range(0, 0x280, 16):
            r = mem[a:a + 16]
            if r[0] & 0x40:
                break
            if not r[0] & 0x80:
                records.append({'slot': 0xC000 + a, 'type': r[0] & 15, 'hit': bool(r[0] & 0x20),
                                'dist': (r[1] | r[2] << 8) - scrolled, 'across': r[3], 'height': r[4],
                                'dir': r[5], 'speed': r[6]})
        return {'scrolled': scrolled, 'records': records, 'control': mem[0x290], 'lives': mem[0x2F9],
                'round': mem[0x2F7], 'lap': mem[0x2F8], 'device': mem[0x28F], 'followers': self.m.read(0xECE4, 1)[0],
                'demo': self.m.read(0xF0DB, 1)[0], 'auto': self.m.read(0xE68B, 1)[0]}

    def close(self):
        self.process.terminate()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--unreal', required=True)
    p.add_argument('--binary', required=True)
    p.add_argument('--start', required=True)
    p.add_argument('--work', required=True)
    p.add_argument('--frames', type=int, default=20000)
    p.add_argument('--give-up', type=int, default=0, help='from this round on, spend the lives (0: never)')
    p.add_argument('--port-base', type=int, default=9780)
    p.add_argument("--wait", type=int, default=200)
    p.add_argument('--probe', action='store_true', help='which stick direction moves the player which way')
    args = p.parse_args()
    os.makedirs(args.work, exist_ok=True)
    g = Game(args)
    try:
        g.key('space', hold=10, gap=100)  # the title before the menu ($8000-$83FF) leaves on any key
        g.key('3', hold=10, gap=50)  # the Kempston reader
        g.key('6')  # start
        g.run(args.wait)
        if not args.probe:
            seen = {}
            while g.frame < args.frames:
                st = g.state()
                me = next((r for r in st['records'] if r['slot'] == 0xC000), None)
                pos = int.from_bytes(g.m.read(0xC001, 2), 'little')
                profile = g.m.read(0x5FF7 + pos // 2, 48)
                if st['round'] > seen.get('top', 0):
                    seen['top'] = st['round']
                stick, why = decide(st, profile, args.give_up and seen.get('top', 0) >= args.give_up)
                if seen.get('top', 0) > 0 and st['round'] == 0 and g.frame > seen.get('game_over', 1 << 30):
                    print(g.frame, 'back in the menu: done')
                    break
                if seen.get('top', 0) > 0 and st['round'] == 0 and 'game_over' not in seen:
                    seen['game_over'] = g.frame + 50
                if me and me['hit'] and seen.get('alive'):
                    last = seen['alive']
                    lm = next(r for r in last['records'] if r['slot'] == 0xC000)
                    print('HIT at', g.frame, 'me', lm, 'profile', profile[:24].hex())
                    for r in last['records']:
                        if r['slot'] != 0xC000 and abs(r['dist'] - lm['dist']) < 40:
                            print('   near', TYPES.get(r['type']), r)
                seen['alive'] = st if me and not me['hit'] else None
                g.stick(stick)
                g.run(3)
                key = (st['round'], st['lives'], st['followers'], st['lap'])
                if key != seen.get('key') or g.frame % 300 < 3:
                    seen['key'] = key
                    print(g.frame, 'round', st['round'], 'lap', st['lap'], 'lives', st['lives'], 'followers',
                          st['followers'], 'scrolled', st['scrolled'], 'me', me and (me['across'], me['height']),
                          why, flush=True)
        if args.probe:
            for buttons in ([], ['left'], ['right'], ['up'], ['down'], ['fire']):
                g.stick(buttons)
                before = g.state()
                g.run(30)
                after = g.state()
                pl0 = next((r for r in before['records'] if r['slot'] == 0xC000), None)
                pl1 = next((r for r in after['records'] if r['slot'] == 0xC000), None)
                print(buttons, 'control', hex(after['control']), pl0, '->', pl1, 'scrolled', before['scrolled'],
                      after['scrolled'])
            g.stick([])
            print(json.dumps(g.state(), indent=None)[:3000])
    finally:
        g.close()


if __name__ == '__main__':
    main()
