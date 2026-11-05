#!/usr/bin/env python3
"""Zynaps 2 in 1 on every 128K-or-larger TR-DOS model of unreal-ng: one fresh machine per model, the TRD autostarted,
the same keys as recording c1 (the boot list ENTER, the title, options 0, the Hewson screen, space held into play),
a screenshot at each step and the facts that show whether the 128K path ran.

    python3 tools/model_run.py --out work/stage1/models --port-base 14900 [--binary B] [--keep] [--boot-wait N] \
        [--hold N] [--suffix S] [--route matrix] [--pre enter] [--options 1,2] [--start mouse] [--results F] \
        PENTAGON:128 SCORPION:256 PENTAGON:512 PENTAGON:1024 ...

Each MODEL:RAM gives OUT/MODEL-RAM/*.png and a line of OUT/models.json:
  flag5D3B   the loader's 128K flag (1 = the paging test passed, the AY path is taken)
  page4      whether the 128K glue copied the page-4 sound engine (`$C968`, 955 bytes, equal to block 1's `$632D`)
  glue5B00   whether the 128K glue sits at `$5B00` (equal to block 2's `$61B6`, `$E3` bytes)
  pc / port7FFD at the end, the mouse device the machine reports, and the screen digest of each step
The machine is muted; the instance is stopped at the end unless --keep.
"""
import argparse
import hashlib
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
UNREAL = os.environ.get('UNREAL_NG', os.path.join(HERE, '..', '..', '..', 'unreal-ng'))
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'mcp'))
import mcplib  # noqa: E402
sys.path.insert(0, os.path.join(UNREAL, 'tools', 'verification', 'analysis'))
import corpus  # noqa: E402

TRD = os.path.join(CASE, 'work', 'media', 'trd', 'Zynaps(2In1)(km).trd')
BLK1 = os.path.join(CASE, 'work', 'media', 'blk1-unpacked.bin')   # block 1 at $6000
BLK2 = os.path.join(CASE, 'work', 'media', 'blk2-unpacked.bin')   # block 2 at $6000
MOUSE = os.path.join(CASE, 'work', 'media', 'mouse-fe00.bin')      # the mouse driver as copied to $FE00


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--out', required=True)
    p.add_argument('--port-base', type=int, default=14900)
    p.add_argument('--binary', default=os.path.join(UNREAL, 'scratch', 'bin', 'unreal-qt.app', 'Contents', 'MacOS',
                                                    'unreal-qt'))
    p.add_argument('--keep', action='store_true')
    p.add_argument('--boot-wait', type=int, default=300, help='frames from the autostart to the boot list')
    p.add_argument('--hold', type=int, default=3, help='frames each key is held')
    p.add_argument('--suffix', default='', help='appended to each model folder (a rerun)')
    p.add_argument('--results', default='models.json')
    p.add_argument('--options', default='', help='option keys tapped on the options screen before 0 (1: INF.LIVES, 2: K-MOUSE), e.g. 1,2')
    p.add_argument('--start', default='space', choices=['space', 'mouse'],
                   help='what starts play on the menu: space (keyboard control) or the left mouse button (mouse control)')
    p.add_argument('--pre', help='a key tapped once before the boot list (GMX: its black start screen takes one)')
    p.add_argument('--route', help='type_input route for the keys (matrix: the Profi, whose PS/2 route loses them)')
    p.add_argument('models', nargs='+')
    a = p.parse_args()
    os.makedirs(a.out, exist_ok=True)
    blk1, blk2 = open(BLK1, 'rb').read(), open(BLK2, 'rb').read()
    engine = blk1[0x632D - 0x6000: 0x632D - 0x6000 + 0x3BB]
    glue = blk2[0x61B6 - 0x6000: 0x61B6 - 0x6000 + 0xE3]
    proc = mcplib.launch(a.binary, a.port_base)
    s = mcplib.Session(f'http://127.0.0.1:{a.port_base + 200}/mcp', 'PENTAGON')
    results = []
    try:
        for spec in a.models:
            model, _, ram = spec.partition(':')
            r = run_model(s, a, model, int(ram) if ram else 0, engine, glue)
            print(json.dumps(r))
            results.append(r)
            with open(os.path.join(a.out, a.results), 'w') as f:
                json.dump(results, f, indent=1)
    finally:
        if not a.keep:
            s.destroy_all()
            proc.terminate()
            proc.wait(timeout=20)


def run_model(s, a, model, ram, engine, glue):
    tag = (f'{model}-{ram}' if ram else model) + a.suffix
    out = os.path.join(a.out, tag)
    os.makedirs(out, exist_ok=True)
    rep = {'model': model, 'ram': ram, 'steps': {}}
    s.destroy_all()
    create = {'action': 'create', 'model': model, 'ram_power_on': 'zero'}
    if ram:
        create['ram_size'] = ram
    c = s.call('emulator_manage', create, ok=False)
    rep['create'] = (c.text or '').splitlines()[:1]
    s.call('emulator_manage', {'action': 'start'}, ok=False)
    s.call('invoke_api', {'method': 'PUT', 'path': '/api/v1/emulator/{id}/audio/mixer/master',
                          'body': {'muted': True}}, ok=False)
    s.call('control_execution', {'action': 'take_control'}, ok=False)
    s.call('control_execution', {'action': 'run_frames', 'frames': 100}, ok=False)
    s.call('control_execution', {'action': 'pause'}, ok=False)
    rep['mouse'] = (s.call('mouse_input', {'action': 'status'}, ok=False).text or '').splitlines()[:2]
    ld = s.call('load_software', {'path': TRD, 'autostart': True}, ok=False)
    rep['load'] = (ld.text or '').splitlines()[:2]
    m = corpus.Machine(s, a.port_base)
    if a.route:
        s.call('type_input', {'action': 'route', 'route': a.route}, ok=False)
        rep['route'] = a.route

    def run(n):
        s.call('control_execution', {'action': 'run_frames', 'frames': n}, ok=False)

    def key(k, n=None):
        n = n or a.hold
        s.call('type_input', {'action': 'press', 'key': k}, ok=False)
        run(n)
        s.call('type_input', {'action': 'release', 'key': k}, ok=False)

    def shot(name):
        path = os.path.abspath(os.path.join(out, name + '.png'))
        s.call('capture_media', {'action': 'screenshot', 'path': path}, ok=False)
        rep['steps'][name] = hashlib.md5(m.read(0x4000, 6912)).hexdigest()[:12]

    if a.pre:
        run(a.boot_wait)
        shot('0-before-pre-key')
        key(a.pre)
        rep['pre'] = a.pre
    run(a.boot_wait)
    shot('1-boot-list')
    key('enter')
    run(600)
    shot('2-title')
    rep['flag5D3B'] = m.read(0x5D3B, 1)[0]
    key('space')
    run(150)
    shot('3-options')
    for k in filter(None, a.options.split(',')):
        key(k)
        run(20)
    if a.options:
        shot('3b-options-set')
        rep['options'] = a.options
        rep['5D40'] = m.read(0x5D40, 2).hex()
    key('0')
    run(550)
    shot('4-hewson')
    key('space')
    run(150)
    shot('5-menu')
    if a.start == 'mouse':
        # The game's start test (`$A748`, patched: IN `$FADF`, AND 2) keeps its stick flag when bit 1 of the buttons is
        # low: mouse control. unreal-ng's Kempston mouse gives the left button on bit 0, the right on bit 1
        s.call('mouse_input', {'action': 'press', 'button': 'right'}, ok=False)
        run(35)
        s.call('mouse_input', {'action': 'release', 'button': 'right'}, ok=False)
        rep['start'] = 'mouse'
    else:
        key('space', 35)
    run(300)
    shot('6-play')
    if '1' in a.options.split(','):
        rep['B171'] = m.read(0xB171, 1).hex()            # $B6: OR (IX+4), lives never drop
    if '2' in a.options.split(','):
        drv = open(MOUSE, 'rb').read()
        rep['mouse_driver'] = sum(x == y for x, y in zip(m.read(0xFE00, 0xD7), drv)) / 0xD7   # code, not its variables
        rep['mouse_patches'] = {'A6D4': m.read(0xA6D3, 3).hex(), 'A74E': m.read(0xA74E, 6).hex(),
                                'B212': m.read(0xB211, 3).hex()}
        pos = []
        for dx, dy in ((0, 0), (24, 0), (0, 12), (-24, -12)):
            if dx or dy:
                s.call('mouse_input', {'action': 'glide', 'dx': dx, 'dy': dy}, ok=False)
            run(40)
            pos.append(m.read(0xF36F, 4).hex() + '/' + m.read(0xFED9, 2).hex())
        rep['ship_F36F'] = pos      # the ship's X lo/hi, Y lo/hi / the driver's X, Y ($FED9, $FEDA) after each glide
        shot('6b-play-mouse')
        s.call('mouse_input', {'action': 'press', 'button': 'left'}, ok=False)
        run(6)
        shot('6c-play-mouse-fire')
        s.call('mouse_input', {'action': 'release', 'button': 'left'}, ok=False)
    run(600)
    shot('7-play-later')
    page4 = m.read_page('ram', 4)
    # Bytes equal to the copied originals (the engine's channel records and the glue's variables change as it runs)
    rep['page4'] = sum(x == y for x, y in zip(page4[0x968:0x968 + len(engine)], engine)) / len(engine)
    rep['glue5B00'] = sum(x == y for x, y in zip(m.read(0x5B00, len(glue)), glue)) / len(glue)
    st = s.call('inspect_state', {'aspects': ['registers', 'paging']}, ok=False)
    rep['state'] = ' '.join((st.text or '').split())[:600]
    return rep


if __name__ == '__main__':
    main()
