#!/usr/bin/env python3
"""ATV Simulator: the controls recording `turn` (doc 05), made with tools/record.py's machinery.

    python3 tools/rec_controls.py turn --work work/stage1/rec/turn --start work/stage1/rec/c1/menu.szx \
        --port-base 37782 [--keep]

Plan `turn`, from c1's menu.szx (one player, KEMPSTON detected at power-on):

1. CHOOSE CONTROL, then the third line of the one-player method window, SINCLAIR (its action ChooseKeys1 `$75AD`
   sets Keyboard1Alt `$8087`), back in the main menu;
2. START; after the trail intro (FrameCount `$D6BC` no longer `$FF`) the rider walks right until he is 24 pixels
   short of the ATV, then jumps with right held until MountCheck puts him on (the Kempston, as before: SINCLAIR
   changed nothing);
3. right held 252 frames (the throttle), wheel up 21 frames, a jump with wheel down held in the air, right again;
4. left held 315 frames: the brake down to speed 0, the turn round (AtvFrame `$5C`, three passes), then the throttle
   to the left (the distance and the score go down);
5. right held 245 frames: the brake, the turn back, the throttle to the right.

Each pass-sized step (7 frames) logs the player's record and the controls in `W/log.json`: the samples are read
between run calls, so each is the memory at the end of a 7-frame step, at no fixed point of the game's pass.
The input script goes to tests/inputs/<W's name>.txt (record.py), the recording to W.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import record as R  # noqa: E402

RECORD_P1 = 0xD70E     # player 1's record (50 bytes); +9 Speed, +4 Facing, +3 AtvFrame, +2 Mounted
FIELDS = {'jump': 0, 'vspeed': 1, 'mounted': 2, 'frame': 3, 'facing': 4, 'x': 5, 'height': 6, 'speed': 9,
          'fuel': 11, 'turnl': 15, 'turnr': 16, 'rframe': 17, 'rfacing': 18, 'rx': 19, 'rheight': 20,
          'track': 24, 'wheelie': 35}


def sample(r, log, note=''):
    rec = r.rd(RECORD_P1, 50)
    v = {k: rec[o] for k, o in FIELDS.items()}
    v['track'] = rec[24] | rec[25] << 8
    v['fuel'] = rec[10] | rec[11] << 8
    v['controls1'] = r.rd(0x8113)[0]
    v['score'] = r.rd(0x6948, 5).decode('latin1')
    v['clock'] = r.rd(0xD6C9, 3).decode('latin1')
    v['kempston'] = r.rd(0x8086)[0]
    v['alt'] = r.rd(0x8087)[0]
    v['frame_no'] = r.lab.frame
    v['held'] = '+'.join(r.held)
    if note:
        v['note'] = note
    log.append(v)


def hold_log(r, log, spec, frames, note=''):
    """Holds @p spec for @p frames in steps of 7, a sample after each step"""
    left = frames
    while left > 0:
        n = min(7, left)
        r.hold(spec, n)
        left -= n
        sample(r, log, note)


def plan_turn(r):
    """turn: from c1's menu.szx (one player, KEMPSTON detected): CHOOSE CONTROL, SINCLAIR (the one-player window's
    third line, ChooseKeys1); START; the rider walks right and jumps (KR, KF) onto the ATV; right 252
    frames, wheel up 21, a jump with wheel down in the air; left 315 frames (brake, turn round, throttle to the
    left); right 245 frames (brake, turn back, throttle right). Samples of the record every 7 frames in log.json"""
    log = []
    R.to_menu(r)
    r.shot('menu')
    R.menu_goto(r, 'control')
    r.tap('SPACE', 4, 30)
    r.shot('methods')
    r.tap('ENTER', 4, 25)
    r.tap('ENTER', 4, 25)
    r.shot('sinclair')
    r.tap('SPACE', 4, 30)
    r.shot('menu-after')
    sample(r, log, 'after SINCLAIR')
    R.start_game(r)
    r.wait(150)
    r.shot('start-line')
    sample(r, log, 'start line')
    for _ in range(100):                      # the trail intro: FrameCount `$D6BC` is $FF until the first pass
        if r.rd(0xD6BC)[0] != 0xFF:
            break
        r.wait(7)
    sample(r, log, 'first pass')
    for _ in range(60):                       # walk right until the rider is 24 pixels short of the ATV
        if log[-1]['rx'] >= log[-1]['x'] - 24:
            break
        hold_log(r, log, 'KR', 7, 'walk to the ATV')
    for _ in range(6):                        # jump (right held): MountCheck takes him on while he falls
        hold_log(r, log, 'KR+KF', 7, 'jump on')
        hold_log(r, log, 'KR', 21, 'jump on')
        if log[-1]['mounted']:
            break
    r.shot('mounted')
    hold_log(r, log, 'KR', 252, 'throttle')
    r.shot('full-speed')
    hold_log(r, log, 'KR+KU', 21, 'wheel up')
    hold_log(r, log, 'KR', 14, 'throttle')
    hold_log(r, log, 'KR+KF', 7, 'jump')
    hold_log(r, log, 'KR+KD', 21, 'wheel down in the air')
    hold_log(r, log, 'KR', 70, 'throttle')
    r.shot('before-left')
    hold_log(r, log, 'KL', 105, 'brake, turn round')
    r.shot('turned')
    hold_log(r, log, 'KL', 210, 'throttle left')
    r.shot('left')
    hold_log(r, log, 'KR', 245, 'brake, turn back, throttle right')
    r.shot('right-again')
    json.dump(log, open(os.path.join(r.work, 'log.json'), 'w'), indent=0)


R.PLANS['turn'] = plan_turn

if __name__ == '__main__':
    R.main()
