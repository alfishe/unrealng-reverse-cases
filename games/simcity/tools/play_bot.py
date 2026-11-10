#!/usr/bin/env python3
"""SimCity recordings made by the bot: a fresh muted 48K (Kempston plugged), a start state loaded (the difficulty
menu right after the tape load, work/stage1/lab/loaded.szx, made by `tools/play_bot.py loaded`), the TTD recording
started, a plan played with the bot's moves (tools/simbot.py: the cursor steered from `$5CFC/$5CFD`), screens and the
game's state logged at named moments, then end.szx, l1.json, session.ttd and the input script of what was pressed.

    python3 tools/play_bot.py loaded --port-base 37020                    # the start state (load at signal speed)
    python3 tools/play_bot.py record PLAN --work work/stage1/rec/PLAN [--start S] [--port-base 37020]
    python3 tools/play_bot.py list

The state logged: funds (24 bits at `$8F97`), month `$8F9B` (0 = JAN), year `$8F9C` (word), the cursor `$5CFC/$5CFD`,
the view origin `$6507/$6508` (map cells), the pass counter `$8F9F`, the PC. A POKE, where a plan uses one, is
written in the plan's note and in record.json; tools/image.py builds the image from the tape alone.
"""
import argparse
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lab import Lab, CASE  # noqa: E402
from simbot import Bot, menu, open_menu, down, tool, place  # noqa: E402

LOADED = os.path.join(CASE, 'work', 'stage1', 'lab', 'loaded.szx')
ICONS = ['bulldozer', 'road', 'power-line', 'rail', 'park', 'residential', 'commercial', 'industrial', 'police',
         'fire', 'stadium', 'power-station', 'seaport', 'airport']


class Run:
    def __init__(self, bot, work):
        self.b, self.lab, self.work = bot, bot.lab, work
        self.moments, self.log = [], []
        os.makedirs(os.path.join(work, 'screens'), exist_ok=True)

    def state(self):
        v = self.lab.read(0x8F97, 9)
        c = self.lab.read(0x5CFC, 2)
        o = self.lab.read(0x6507, 2)
        p = self.lab.read(0x8443, 9)
        e = self.lab.read(0x8E90, 3)
        r = self.lab.regs() or {}
        return dict(frame=self.b.frame, funds=v[0] | v[1] << 8 | v[2] << 16, month=v[4], year=v[5] | v[6] << 8,
                    cursor=list(c), view=list(o), passes=v[8], pc=(r.get('special') or {}).get('pc'),
                    pop=p[0] | p[1] << 8 | p[2] << 16, rci=[p[3] | p[4] << 8, p[5] | p[6] << 8, p[7] | p[8] << 8],
                    year_end_pop=e[0] | e[1] << 8 | e[2] << 16, category=self.lab.read(0x975F, 1)[0])

    def shot(self, name):
        p = os.path.join(self.work, 'screens', f'{self.b.frame:06d}-{name}.png')
        self.lab.shot(p, 2)
        s = self.state()
        s['name'] = name
        self.moments.append(s)
        print('  ', name, {k: s[k] for k in ('frame', 'funds', 'month', 'year')}, flush=True)

    def wait(self, frames, every=0, name='wait'):
        """Lets time pass; a state every `every` frames"""
        step = every or frames
        done = 0
        while done < frames:
            n = min(step, frames - done)
            self.b.wait(n)
            done += n
            if every:
                self.log.append(self.state())
        return self


def new_city(r, level=0):
    """From the difficulty menu: level 0-2 (down, fire), then the landscape is made (about 600 frames)"""
    b = r.b
    b.wait(20)
    down(b, level)
    r.shot(f'level-{level}')
    b.tap('SPACE', 8, 60)
    r.shot('creating-landscape')
    b.wait(700)
    r.shot('new-city')


def coal_station(r, col, row):
    tool(r.b, 11)
    place(r.b, col, row)
    r.b.wait(20)
    r.shot('select-power-type')
    down(r.b, 1)
    r.b.tap('SPACE', 8, 30)


def road_line(b, row, c0, c1):
    tool(b, 1)
    for c in range(c0, c1 + 1):
        place(b, c, row)


def build_town(r):
    """A town in the start view: R zones above a road, C and I below, a coal station, power lines over the roads"""
    b = r.b
    coal_station(r, 24, 8)
    tool(b, 5)
    for c in (6, 9, 12, 15, 18, 21):
        place(b, c, 9)
    r.shot('residential-row')
    road_line(b, 12, 5, 26)
    tool(b, 6)
    for c in (6, 9, 12):
        place(b, c, 13)
    tool(b, 7)
    for c in (15, 18, 21):
        place(b, c, 13)
    road_line(b, 16, 5, 26)
    tool(b, 2)
    place(b, 7, 12)
    place(b, 7, 16)
    tool(b, 5)
    for c in (6, 9, 12, 15, 18, 21):
        place(b, c, 17)
    tool(b, 8)
    place(b, 24, 13)
    tool(b, 9)
    place(b, 24, 17)
    r.shot('town-built')


def until_map(r, limit=4000):
    """Waits until the map view is back (the attribute of screen cell (16, 12) has PAPER 6): after a tape save or
    load, the game redraws the view; returns the frames waited"""
    for i in range(0, limit, 10):
        if r.lab.read(0x5800 + 32 * 12 + 16, 1)[0] & 0x38 == 0x30:
            return i
        r.b.wait(10)
    return None


def set_tax(r, steps):
    """In the open BUDGET window (TAX RATE lit): fire edits the rate, Q raises and A lowers it by 1 %, fire ends"""
    b = r.b
    b.tap('SPACE', 8, 30)
    for _ in range(abs(steps)):
        b.tap('Q' if steps > 0 else 'A', 8, 24)
    b.tap('SPACE', 8, 30)


def close_budget(r):
    down(r.b, 4)
    r.b.tap('SPACE', 8, 30)
    r.b.wait(60)    # the view is redrawn: a fire pressed sooner is lost


# ---------------------------------------------------------------------------------------------------- the plans
def plan_tools(r):
    """Every tool once on the easy level ($20000, no POKE), AUTO-BUDGET on so the year-end window stays away:
    bulldozer on trees, road, power line, rail, park, R, C, I, police, fire, airport ($10000), stadium, the power
    station dialog and a nuclear station; then the coal station and the seaport refused for lack of funds; a road on
    an occupied cell; the cursor-key scroll (CS+5..8); the icon shortcuts (SS+1..0)"""
    b = r.b
    new_city(r, 0)
    menu(b, 'OPTIONS', 1); r.shot('auto-budget-on')
    tool(b, 0); place(b, 15, 12); place(b, 16, 12); r.shot('bulldozer')
    tool(b, 1); place(b, 5, 10); place(b, 6, 10); place(b, 7, 10); r.shot('road')
    tool(b, 2); place(b, 8, 10); place(b, 9, 10); r.shot('power-line')
    tool(b, 3); place(b, 10, 10); place(b, 11, 10); r.shot('rail')
    tool(b, 4); place(b, 12, 10); r.shot('park')
    tool(b, 5); place(b, 5, 18); r.shot('residential')
    tool(b, 6); place(b, 9, 18); r.shot('commercial')
    tool(b, 7); place(b, 13, 18); r.shot('industrial')
    tool(b, 8); place(b, 17, 18); r.shot('police')
    tool(b, 9); place(b, 21, 18); r.shot('fire')
    tool(b, 13); place(b, 24, 13); b.wait(20); r.shot('airport')
    tool(b, 10); place(b, 25, 18); r.shot('stadium')
    tool(b, 11); place(b, 24, 8); b.wait(20); r.shot('select-power-type'); b.tap('SPACE', 8, 30); r.shot('nuclear')
    tool(b, 11); place(b, 19, 8); b.wait(20); down(b, 1); b.tap('SPACE', 8, 30); b.wait(10); r.shot('coal-no-funds')
    tool(b, 12); place(b, 5, 13); b.wait(10); r.shot('seaport-no-funds')
    tool(b, 1); place(b, 25, 18); r.shot('occupied-beep')
    for k in ('8', '6', '5', '7'):
        b.tap(['CS', k], 30, 10)
        r.shot(f'scroll-cs{k}')
    for k in '1234567890':
        b.tap(['SS', k], 8, 16)
        r.shot(f'shortcut-ss{k}')
    r.wait(6000, 400)
    r.shot('after-6000')


def plan_ports(r):
    """The easy level again ($20000, no POKE): the Kempston joystick steers the cursor and fires (the second control
    method), then the seaport on the lake shore, the coal station, a stadium, the power lines"""
    b = r.b
    new_city(r, 0)
    menu(b, 'OPTIONS', 1)
    x0 = b.cursor()
    b.keys(['KR', 'KD']); b.run(40); b.keys([]); b.run(4)
    r.shot('kempston-moved')
    x1 = b.cursor()
    b.keys(['KU']); b.run(200); b.keys([]); b.run(4)
    b.goto(4 * 12 + 5, 12)
    b.keys(['KF']); b.run(6); b.keys([]); b.run(20)
    r.shot('kempston-fire-seaport-icon')
    r.moments[-1]['cursor_before_after'] = [list(x0), list(x1)]
    place(b, 5, 13); b.wait(20); r.shot('seaport')
    coal_station(r, 24, 8); r.shot('coal')
    tool(b, 10); place(b, 18, 18); r.shot('stadium')
    tool(b, 2)
    for c in range(9, 24):
        place(b, c, 12)
    r.shot('power-lines')
    r.wait(4000, 400)
    r.shot('after-4000')


def plan_menus(r):
    """Every menu and option on the town: SYSTEM (about, save to tape, load from tape, use old landscape, start new
    city, exit), OPTIONS (each toggle seen in the open menu, the four speeds), DISASTERS (DISABLE ALL), WINDOWS (maps
    with every sub-map and the CS+1..9 regions, ENTER for the maps, budget with the tax rate edited, evaluation).
    USE OLD LANDSCAPE with the gene 12345 and back to 00003. The saved city is rebuilt as a TAP from memory (tools/savetap.py: the emulator has no tape recorder), the map
    and funds are spoiled by a tool write and loaded back from that tape"""
    b = r.b
    new_city(r, 0)
    build_town(r)
    menu(b, 'SYSTEM', 0); r.shot('about'); b.tap('SPACE', 8, 30)
    for i, name in enumerate(['auto-bulldoze', 'auto-budget', 'sound', 'zone-demolish-wait']):
        menu(b, 'OPTIONS', i)
        open_menu(b, 'OPTIONS'); r.shot(f'option-{name}-toggled'); down(b, 5); b.tap('SPACE', 8, 30)
        menu(b, 'OPTIONS', i)
    menu(b, 'OPTIONS', 4); r.shot('speed-menu')
    for i, name in enumerate(['fast', 'normal', 'slow', 'paused']):
        down(b, i)
        b.tap('SPACE', 8, 30); r.shot(f'speed-{name}')
        r.wait(400, 400)
        r.shot(f'speed-{name}-400')
        menu(b, 'OPTIONS', 4)
    down(b, 1); b.tap('SPACE', 8, 30)    # back to NORMAL
    open_menu(b, 'DISASTERS'); r.shot('disasters-menu'); down(b, 6); b.tap('SPACE', 8, 30); r.shot('disable-all')
    open_menu(b, 'DISASTERS'); r.shot('disasters-disabled'); down(b, 6); b.tap('SPACE', 8, 30)
    open_menu(b, 'WINDOWS'); r.shot('windows-menu'); b.tap('SPACE', 8, 30); r.shot('maps')
    for i in range(1, 8):
        down(b, 1); b.wait(20); r.shot(f'maps-sub{i}')
    for k in '123456789':
        b.tap(['CS', k], 8, 30); r.shot(f'maps-region{k}')
    b.tap('SPACE', 8, 30); r.shot('maps-exit')
    b.tap('ENTER', 8, 30); r.shot('enter-maps'); b.tap('SPACE', 8, 30)
    menu(b, 'WINDOWS', 1); r.shot('budget')
    set_tax(r, 2); r.shot('budget-tax')
    close_budget(r); r.shot('budget-exit')
    menu(b, 'WINDOWS', 2); r.shot('evaluation'); b.tap('SPACE', 8, 30)
    open_menu(b, 'SYSTEM'); r.shot('system-menu'); down(b, 4); b.tap('SPACE', 8, 30); r.shot('saving-menu')
    b.tap('SPACE', 8, 40); r.shot('save-name')
    for k in 'TOWN':
        b.tap(k, 6, 16)
    b.tap('ENTER', 8, 60); r.shot('save-start-tape')
    b.tap('SPACE', 10, 20); r.shot('saving')
    r.moments[-1]['save_frames'] = until_map(r)
    b.wait(150); r.shot('saved')
    from savetap import tap_from
    tap = os.path.join(r.work, 'town.tap')
    open(tap, 'wb').write(tap_from(r.lab.read))
    r.lab.write(0x8F97, b'\0\0\0')
    r.lab.write(0xC450, bytes(0x400))
    b.wait(60); r.shot('spoiled')
    menu(b, 'SYSTEM', 3); r.shot('loading-menu'); b.tap('SPACE', 8, 40); r.shot('load-name')
    for k in 'TOWN':
        b.tap(k, 6, 16)
    b.tap('ENTER', 8, 60); r.shot('load-searching')
    r.lab.insert_tape(tap)
    b.wait(1500); r.shot('loading')
    r.moments[-1]['load_frames'] = until_map(r)
    b.wait(150); r.shot('loaded')
    menu(b, 'SYSTEM', 2); r.shot('old-landscape')
    b.tap('SPACE', 8, 30); r.shot('gene-input')
    for k in '12345':
        b.tap(k, 6, 16)
    b.tap('ENTER', 8, 30); r.shot('gene-12345')
    b.tap('SPACE', 8, 30); b.wait(30); r.shot('gene-12345-level')       # the gene's city starts at the level menu
    b.tap('SPACE', 8, 30); b.wait(700); r.shot('gene-12345-city')
    menu(b, 'SYSTEM', 2); b.tap('SPACE', 8, 30)
    for k in '00003':
        b.tap(k, 6, 16)
    b.tap('ENTER', 8, 30); b.tap('SPACE', 8, 30); b.wait(30); b.tap('SPACE', 8, 30); b.wait(700)
    r.shot('gene-00003-city')
    menu(b, 'SYSTEM', 1); r.shot('start-new-city'); down(b, 1); r.shot('start-new-city-yes')
    b.tap('SPACE', 8, 60); r.shot('start-new-city-level')
    b.tap('SPACE', 8, 30); b.wait(800); r.shot('start-new-city-easy')
    menu(b, 'SYSTEM', 5); r.shot('exit-simcity'); b.tap('SPACE', 8, 60); r.shot('exit-simcity-no')
    menu(b, 'SYSTEM', 5); down(b, 1); r.shot('exit-simcity-yes')
    b.tap('SPACE', 8, 60); r.shot('exit-simcity-1')
    b.wait(300); r.shot('exit-simcity-2')


def plan_growth(r, frames=40000):
    """The town on the easy level with AUTO-BUDGET on and the speed FAST, then time: growth, traffic, pollution,
    crime, the messages and the population milestones; the evaluation and every map at the end"""
    b = r.b
    new_city(r, 0)
    menu(b, 'OPTIONS', 1); r.shot('auto-budget-on')
    build_town(r)
    menu(b, 'OPTIONS', 4); b.tap('SPACE', 8, 30); r.shot('speed-fast')
    for k in range(frames // 2000):
        r.wait(2000, 250)
        r.shot(f'growth-{k + 1:02d}')
        if k % 5 == 4:
            menu(b, 'WINDOWS', 2); r.shot(f'evaluation-{k + 1:02d}'); b.tap('SPACE', 8, 30)
    menu(b, 'WINDOWS', 0)
    for i in range(8):
        b.wait(20); r.shot(f'maps-sub{i}')
        down(b, 1)
    b.tap('SPACE', 8, 30)


def plan_city(r, frames=60000):
    """A city on money written into the funds (`$8F97-$8F99` = 999 999 after the new city and again once the city is
    built; a tool write, the image never holds it). Not the POKE file's 26241,0 / 26242,0: those NOP the SBC of the
    shared 24-bit subtraction `$6680`, which the city category also uses (`$9760` compares the population with the
    thresholds at `$9750` through it), so they would corrupt the milestones. The whole start view filled with zones on three
    roads, a nuclear station, police, fire, a stadium, a power line down column 0; AUTO-BUDGET on, the tax at 7 %,
    the speed FAST, then 60 000 frames of time for growth, traffic, pollution, crime and the population milestones;
    the evaluation every 20 000 frames; city2 goes on from its end"""
    b = r.b
    new_city(r, 0)
    r.lab.write(0x8F97, (999999).to_bytes(3, 'little'))
    r.moments.append(dict(frame=b.frame, name='money', poke='$8F97-$8F99 = 999999'))
    menu(b, 'OPTIONS', 1)
    menu(b, 'WINDOWS', 1); set_tax(r, -25); set_tax(r, 7); r.shot('tax-7'); close_budget(r)
    tool(b, 11); place(b, 28, 8); b.wait(20); b.tap('SPACE', 8, 30)
    road_line(b, 11, 0, 27)
    road_line(b, 18, 0, 31)
    road_line(b, 22, 0, 31)
    tool(b, 5)
    for c in range(1, 26, 3):
        place(b, c, 8)
        place(b, c, 15)
    tool(b, 6)
    for c in (1, 4, 7, 10):
        place(b, c, 12)
    for c in (16, 19, 22, 25):
        place(b, c, 19)
    tool(b, 7)
    for c in (16, 19, 22, 25):
        place(b, c, 12)
    for c in (1, 4, 7, 10):
        place(b, c, 19)
    tool(b, 8); place(b, 13, 12)
    tool(b, 9); place(b, 13, 19)
    tool(b, 10); place(b, 28, 12)
    tool(b, 2)
    for row in range(8, 22):
        place(b, 0, row)
    r.lab.write(0x8F97, (999999).to_bytes(3, 'little'))
    r.moments.append(dict(frame=b.frame, name='money', poke='$8F97-$8F99 = 999999'))
    r.shot('city-built')
    menu(b, 'OPTIONS', 4); b.tap('SPACE', 8, 30); r.shot('speed-fast')
    grow(r, frames, 0)


def grow(r, frames, first):
    """FAST time in steps of 4000 frames, a shot each step and the evaluation every fifth"""
    b = r.b
    for k in range(first, first + frames // 4000):
        r.wait(4000, 500)
        r.shot(f'year-{k + 1:02d}')
        if k % 5 == 4:
            menu(b, 'WINDOWS', 2); b.wait(20); r.shot(f'evaluation-{k + 1:02d}'); b.tap('SPACE', 8, 30); b.wait(30)


def plan_city2(r, frames=80000):
    """The city's second half (start: city's end.szx, still at FAST; one TTD capture holds about 100 000 frames, so
    the city is two recordings): 80 000 more frames of FAST time, then every map at NORMAL speed and the evaluation"""
    b = r.b
    grow(r, frames, 15)
    menu(b, 'OPTIONS', 4); down(b, 1); b.tap('SPACE', 8, 30)
    menu(b, 'WINDOWS', 0); b.wait(30)
    for i in range(8):
        r.shot(f'maps-sub{i}')
        down(b, 1); b.wait(30)
    b.tap('SPACE', 8, 30)
    menu(b, 'WINDOWS', 2); b.wait(20); r.shot('evaluation-end'); b.tap('SPACE', 8, 30)


def plan_metro(r, frames=80000):
    """A second block for the population milestones the one-view city cannot reach (it levels off at about 6000):
    from city's end.szx (FAST, AUTO-BUDGET on), the funds written to 999 999 again, the view scrolled with CS+6 / CS+8
    to (47, 53), the land south-east of the city (the lake west of it, the coast in the corner at columns 29-31), and
    the city's layout built there with its own nuclear station at (28, 19) (roads 18 and 22 stop at column 27); then
    80 000 frames of FAST time with the evaluation every 20 000 frames, every map and a last evaluation"""
    b = r.b
    r.lab.write(0x8F97, (999999).to_bytes(3, 'little'))
    r.moments.append(dict(frame=b.frame, name='money', poke='$8F97-$8F99 = 999999'))
    for _ in range(80):
        vx, vy = r.lab.read(0x6507, 2)
        if (vx, vy) == (47, 53):
            break
        b.tap(['CS', '6' if vy < 53 else '7'] if vy != 53 else ['CS', '8' if vx < 47 else '5'], 8, 30)
    r.shot('view-47-53')
    road_line(b, 11, 0, 27)
    road_line(b, 18, 0, 27)
    road_line(b, 22, 0, 27)
    tool(b, 11); place(b, 28, 19); b.wait(20); b.tap('SPACE', 8, 30)
    tool(b, 5)
    for c in range(1, 26, 3):
        place(b, c, 8)
        place(b, c, 15)
    tool(b, 6)
    for c in (1, 4, 7, 10):
        place(b, c, 12)
    for c in (16, 19, 22, 25):
        place(b, c, 19)
    tool(b, 7)
    for c in (16, 19, 22, 25):
        place(b, c, 12)
    for c in (1, 4, 7, 10):
        place(b, c, 19)
    tool(b, 8); place(b, 13, 12)
    tool(b, 9); place(b, 13, 19)
    tool(b, 2)
    for row in range(8, 22):
        place(b, 0, row)
    r.lab.write(0x8F97, (999999).to_bytes(3, 'little'))
    r.moments.append(dict(frame=b.frame, name='money', poke='$8F97-$8F99 = 999999'))
    r.shot('block-built')
    grow(r, frames, 15)
    menu(b, 'OPTIONS', 4); down(b, 1); b.tap('SPACE', 8, 30)
    menu(b, 'WINDOWS', 0); b.wait(30)
    for i in range(8):
        r.shot(f'maps-sub{i}')
        down(b, 1); b.wait(30)
    b.tap('SPACE', 8, 30)
    menu(b, 'WINDOWS', 2); b.wait(20); r.shot('evaluation-end'); b.tap('SPACE', 8, 30)


def plan_disasters(r):
    """Each disaster from the DISASTERS menu on the grown city (start: city2's end.szx), 2000 frames each at NORMAL speed"""
    b = r.b
    for i, name in enumerate(['fire', 'flood', 'earthquake', 'air-crash', 'tornado', 'meltdown']):
        menu(b, 'DISASTERS', i)
        b.wait(30)
        r.shot(f'{name}-0')
        for k in range(4):
            r.wait(500, 100)
            r.shot(f'{name}-{k + 1}')


def plan_levels(r):
    """Medium and difficult new cities (their funds), each looked at; the level menu's INPUT NEW CITY NAME (METRO)"""
    b = r.b
    new_city(r, 1)
    menu(b, 'SYSTEM', 1); b.wait(30); r.shot('new-city-menu'); down(b, 1)
    r.shot('new-city-yes'); b.tap('SPACE', 8, 60); r.shot('level-menu')
    down(b, 3); r.shot('city-name-item'); b.tap('SPACE', 8, 30); r.shot('city-name-input')
    for k in 'METRO':
        b.tap(k, 6, 16)
    b.tap('ENTER', 8, 30); r.shot('city-name-metro')
    for _ in range(4):
        b.tap('Q', 8, 16)
    down(b, 2); r.shot('level-2'); b.tap('SPACE', 8, 60); b.wait(700); r.shot('difficult-city')


def plan_bankrupt(r):
    """The difficult level ($5000): the money spent on zones, the tax rate set to 0 %, then years with no income to
    see what the game does at the funds' floor"""
    b = r.b
    new_city(r, 2)
    tool(b, 5)
    for row in (9, 13, 17):
        for c in (3, 6, 9, 12, 15, 18, 21, 24):
            place(b, c, row)
    r.shot('spent')
    menu(b, 'WINDOWS', 1); set_tax(r, -20); r.shot('tax-0'); close_budget(r)
    menu(b, 'OPTIONS', 4); b.tap('SPACE', 8, 30)
    for k in range(10):
        r.wait(2000, 500)
        r.shot(f'years-{k + 1:02d}')
        if b.frame and r.lab.read(0x5800 + 32 * 12 + 16, 1)[0] & 0x38 == 0:    # a window open: the budget
            r.shot(f'window-{k + 1:02d}')
            close_budget(r)


PLANS = {'city': plan_city, 'city2': plan_city2, 'metro': plan_metro, 'tools': plan_tools, 'ports': plan_ports, 'menus': plan_menus, 'growth': plan_growth,
         'disasters': plan_disasters, 'levels': plan_levels, 'bankrupt': plan_bankrupt}


def record(args):
    work = os.path.abspath(args.work)
    lab = Lab(args.port_base)
    try:
        lab.load(os.path.abspath(args.start))
        lab.session_json(work)
        lab.start_recording()
        b = Bot(lab)
        r = Run(b, work)
        began = time.time()
        PLANS[args.plan](r)
        b.wait(10)
        r.shot('end')
        lab.save(os.path.join(work, 'end.szx'))
        b.write_script(os.path.join(work, 'inputs.txt'),
                       f'{args.plan}: the bot\'s keys from {os.path.relpath(args.start, CASE)} (tools/play_bot.py)')
        json.dump(dict(moments=r.moments, log=r.log), open(os.path.join(work, 'states.json'), 'w'), indent=0)
        lab.s.call('analysis', {'action': 'build', 'path': os.path.join(work, 'l1.json'), 'wait': 30000})
        st = lab.s.call('analysis', {'action': 'status'}).text
        while ': running' in st:
            time.sleep(5)
            st = lab.s.call('analysis', {'action': 'status'}).text
        rr = lab.s.call('time_travel', {'action': 'dump', 'path': os.path.join(work, 'session.ttd')}, ok=False)
        json.dump(dict(plan=args.plan, doc=PLANS[args.plan].__doc__, start=os.path.relpath(args.start, CASE),
                       frames=b.frame, seconds=round(time.time() - began), status=st.splitlines(),
                       ttd=(rr.text or '').splitlines()[:2]), open(os.path.join(work, 'record.json'), 'w'), indent=1)
        print('recorded', args.plan, b.frame, 'frames', flush=True)
    finally:
        lab.close()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd')
    ap.add_argument('plan', nargs='?')
    ap.add_argument('--work')
    ap.add_argument('--start', default=LOADED)
    ap.add_argument('--port-base', type=int, default=37020)
    args = ap.parse_args()
    if args.cmd == 'list':
        for k, f in PLANS.items():
            print(k, ':', ' '.join(f.__doc__.split()))
    elif args.cmd == 'loaded':
        lab = Lab(args.port_base)
        try:
            print('load frames', lab.load_tape(os.path.join(CASE, 'orig', 'SimCity.tzx.zip')))
            os.makedirs(os.path.dirname(LOADED), exist_ok=True)
            lab.save(LOADED)
        finally:
            lab.close()
    elif args.cmd == 'record':
        record(args)


if __name__ == '__main__':
    main()
