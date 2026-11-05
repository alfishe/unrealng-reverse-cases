#!/usr/bin/env python3
"""A long recorded game of the '99 (docs 07, 09, 10): the disk booted on a Pentagon 128, the start-up menu driven by
its pointer to a LEVEL and KEMPSTON, START, then Nether Earth's bot (R/games/nether-earth/tools/bot.py, used as a
library, not changed) builds robots, orders them and waits, while the analysis records.

    python3 tools/zsB_play99.py menu --work work/zsB/menu --level 3 [--port-base 15400]
        boots the disk, picks the level (1 EASY .. 4 CRITICAL) and KEMPSTON, START, saves W/play.szx at the
        first frame PlayInterrupt is the handler (and W/menu.szx at the start-up menu); stops the instance
    python3 tools/zsB_play99.py menu --work work/zsB/menu-map0 --level 3 --map 0
        the same after LOAD MAP (row 17, columns 8-17): the catalogue's NELEV file of that index (Q / A move,
        SPACE loads; 0 = NELEV_00), then the menu again (MenuEntry resets level and pointer) and the same choices
    python3 tools/zsB_play99.py deep --start work/zsB/menu/play.szx --work work/zsB/deep [--frames 30000]
        the bot from that snapshot with the recording on: W/l1.json, W/session.ttd, W/play.log, W/screens/;
        the instance is stopped at the end (--keep keeps it for re_session.py)

The '99 keeps the robot records, the variables, the menus and the interrupt handlers at the addresses the bot reads
(src/game99/game.ann: StartInterrupt $D59C, PlayInterrupt $D566, RobotMenu $A720, ConstructionMenu $C849,
Robots $DA00, Buildings $FF01, Resources $FD22). The bot's own play() presses 2 and 0 in Nether Earth's menu; the
'99 has none (START plays), so this script runs the same loop without those keys.
"""
import argparse
import json
import os
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NE_TOOLS = os.path.join(ROOT, '..', 'nether-earth', 'tools')
UNREAL = os.environ.get('UNREAL_NG', '/Volumes/TB4-4Tb/Projects/Test/unreal-ng/scratch/wt-nezs-stage1')
BIN = os.path.join(UNREAL, 'cmake-build-agent-release', 'bin', 'unreal-qt.app', 'Contents', 'MacOS', 'unreal-qt')
SCL = os.path.join(ROOT, 'work', 'scl', 'z99', 'NEZSED.SCL')
sys.path.insert(0, NE_TOOLS)
import bot  # noqa: E402

POINTER = 0xDD74        # DrawPointer's LD BC operand: x, then y (src/menu99/menu.ann)
LEVEL_ROW = {1: 10, 2: 11, 3: 12, 4: 13}


def launch(g, port_base, work, binary=BIN):
    here = os.getcwd()
    os.makedirs(work, exist_ok=True)
    os.chdir(work)  # the emulator writes its features.ini where it starts
    try:
        process = g.mcplib.launch(binary, port_base)
    finally:
        os.chdir(here)
    s = g.mcplib.Session(f'http://127.0.0.1:{port_base + 200}/mcp', 'PENTAGON')
    s.fresh_machine('PENTAGON', ram_power_on='zero')
    s.call('emulator_manage', {'action': 'slots_plug', 'slot': 'edge.1', 'card': 'kempston'}, ok=False)
    for _ in range(100):  # the plug restarts the machine: wait for the wired stick
        if 'slots_plug slot=edge.1' not in s.call('joystick_input', {'action': 'status'}, ok=False).text:
            break
        time.sleep(0.1)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    g.s = s
    g.m = g.corpus.Machine(s, port_base)
    with open(os.path.join(work, 'session.json'), 'w') as f:
        json.dump({'pid': process.pid, 'binary': binary, 'port_base': port_base, 'model': 'PENTAGON',
                   'ranges': '4000-FFFF'}, f)
    return process


def stop(process):
    process.terminate()
    try:
        process.wait(10)
    except Exception:  # noqa: BLE001
        process.kill()


def pointer(g):
    x, y = g.m.read(POINTER, 2)
    return x, y


def point_at(g, row, col):
    """Move the menu pointer with Q A O P until its corner is in cell (row, col)"""
    tx, ty = col * 8 + 4, row * 8 + 4
    for _ in range(600):
        x, y = pointer(g)
        if abs(x - tx) <= 1 and abs(y - ty) <= 1:
            break
        keys = []
        if y < ty - 1:
            keys.append('a')
        elif y > ty + 1:
            keys.append('q')
        if x < tx - 1:
            keys.append('p')
        elif x > tx + 1:
            keys.append('o')
        for k in keys:
            g.s.call('type_input', {'action': 'press', 'key': k}, ok=False)
        g.run(1)
        for k in keys:
            g.s.call('type_input', {'action': 'release', 'key': k}, ok=False)
    g.run(2)
    g.key('space', hold=3, gap=15)
    g.note(f'pointer at {pointer(g)} for cell ({row},{col})')


def menu(a):
    g = bot.Game(UNREAL, a.work)
    process = launch(g, a.port_base, g.work)
    try:
        r = g.s.call('load_software', {'path': SCL, 'autostart': True, 'play': False}, ok=False)
        g.note((r.text or '').splitlines()[0] if r.text else 'loaded')
        g.run(1310)
        g.key('space', hold=5, gap=10)
        for _ in range(400):  # the start-up menu: MenuEntry has run once the pointer sits at (8, 8)
            g.run(10)
            if g.m.read(0xD800, 1)[0] and pointer(g) == (8, 8) and g.m.read(0xDD73, 1)[0] == 0x01:
                break
        g.run(20)
        g.note(f'start-up menu, pointer {pointer(g)}')
        g.m.post('/snapshot/save', {'path': os.path.join(g.work, 'menu.szx'), 'force': True})
        if a.map is not None:
            point_at(g, 17, 10)          # LOAD MAP: the catalogue
            g.run(400)
            for _ in range(a.map):
                g.key('a', hold=6, gap=10)
            g.note(f'LOAD MAP: index {a.map}, $ADB4 = {g.m.read(0xADB4, 1)[0]}')
            g.key('space', hold=6, gap=10)
            g.run(60)
            for _ in range(600):  # the map loads, JP Start: the start-up menu again
                g.run(10)
                if pointer(g) == (8, 8) and g.m.read(0xDD73, 1)[0] == 0x01:
                    break
            g.run(20)
            g.note(f'menu again, pointer {pointer(g)}; capture points $ADB4 = {g.m.read(0xADB4, 1)[0]}, '
                   f'$BB1F = {g.m.read(0xBB1F, 1)[0]}')
            g.m.post('/snapshot/save', {'path': os.path.join(g.work, 'menu-map.szx'), 'force': True})
        point_at(g, LEVEL_ROW[a.level], 2)
        point_at(g, 11, 25)          # CONTROL: KEMPSTON
        point_at(g, 17, 2)           # START
        for _ in range(500):
            g.run(1)
            if g.state()['handler'] == bot.PLAY_INTERRUPT:
                break
        g.note(f"handler ${g.state()['handler']:04X}, level patches $B87E {g.m.read(0xB87E, 3).hex()} "
               f"$AE41 {g.m.read(0xAE41, 9).hex()} $A5E5 {g.m.read(0xA5E5, 3).hex()} Controls {g.m.read(0xD3E4, 1)[0]}")
        g.m.post('/snapshot/save', {'path': os.path.join(g.work, 'play.szx'), 'force': True})
    finally:
        with open(os.path.join(g.work, 'menu.log'), 'w') as f:
            f.write('\n'.join(g.log) + '\n')
        stop(process)


def play(g, frames, shots):
    """bot.play without Nether Earth's menu keys (the '99 is already in play)"""
    home = next(b for b in g.buildings() if b['type'] == 0)
    g.note(f"game on, warbase at ({home['x']},{home['y']})")
    step, next_shot = 0, 0
    while g.frame < frames:
        st = g.state()
        if g.frame >= next_shot:
            g.screen(os.path.join(shots, f'f{g.frame:06d}.png'))
            mine = sum(r['mine'] for r in g.robots())
            g.note(f"day {st['clock'][2]} {st['clock'][1]:02d}:{st['clock'][0]:02d} resources {st['resources']} "
                   f"robots {mine} vs {len(g.robots()) - mine}")
            next_shot = g.frame + 1500
        if st['handler'] not in (bot.PLAY_INTERRUPT, bot.START_INTERRUPT):
            g.note(f"handler ${st['handler']:04X}: the game ended")
            break
        parts, kind, target = bot.PLAN[step % len(bot.PLAN)]
        if sum(r['mine'] for r in g.robots()) < 24 and bot.affordable(parts, st['resources']):
            if not g.land_on_warbase(home['x'], home['y']):
                g.note('the pad is blocked')
                g.climb()
                g.fly_to(home['x'] + 3, home['y'])
                g.run(100)
                continue
            robot = g.build(parts)
            if robot is None:
                g.note(f'refused {parts}')
                step += 1
                continue
            g.note(f"robot {robot['slot']} parts ${robot['parts']:02X} at ({robot['x']},{robot['y']})")
            try:
                order = g.order(robot['slot'], kind, target)
            except TypeError as e:      # bot.py lost the menu (no highlighted item): leave it, go on
                g.note(f'order menu lost ({e}); leaving it')
                g.stick({'fire'})
                g.run(30)
                g.stick(set())
                order = False
            g.note(f"robot {robot['slot']} order {bot.ORDER_NAMES[order] if order is not False else 'not given'}")
            step += 1
            continue
        g.fly_to(home['x'] + 2, home['y'] + 2, cruise=30, limit=200)
        g.stick({'fire'} if g.state()['altitude'] < 30 else set())
        g.run(50)
    g.stick(set())


def deep(a):
    g = bot.Game(UNREAL, a.work)
    process = launch(g, a.port_base, g.work)
    try:
        g.m.post('/snapshot/load', {'path': os.path.abspath(a.start)})
        g.m.post('/snapshot/save', {'path': os.path.join(g.work, 'start.szx'), 'force': True})
        with open(os.path.join(g.work, 'start.bin'), 'wb') as f:
            f.write(g.m.read(0, 0x10000))
        g.s.call('analysis', {'action': 'start', 'record': True})
        shots = os.path.join(g.work, 'screens')
        os.makedirs(shots, exist_ok=True)
        try:
            play(g, a.frames, shots)
        finally:
            with open(os.path.join(g.work, 'play.log'), 'w') as f:
                f.write('\n'.join(g.log) + '\n')
            g.finish()          # the L1 and session.ttd are written even when the bot fails
            with open(os.path.join(g.work, 'end-cpu.bin'), 'wb') as f:
                f.write(g.m.read(0, 0x10000))
    finally:
        if not a.keep:
            stop(process)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('command', choices=['menu', 'deep'])
    p.add_argument('--work', required=True)
    p.add_argument('--start')
    p.add_argument('--level', type=int, default=3)
    p.add_argument('--map', type=int, help='LOAD MAP first: the catalogue index of the NELEV file')
    p.add_argument('--frames', type=int, default=30000)
    p.add_argument('--port-base', type=int, default=15400)
    p.add_argument('--keep', action='store_true')
    a = p.parse_args()
    if a.command == 'menu':
        menu(a)
    else:
        deep(a)
    return 0


if __name__ == '__main__':
    sys.exit(main())
