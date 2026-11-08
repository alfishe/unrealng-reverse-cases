"""j1: the Kempston joystick and the pause menu's options, from the title of c1 (work/snaps/title-A.szx). The
first key (N) on the title and then the joystick pushed left picks the Kempston (ControlMethod 1) and starts a new game, docked at Lave; the
launch (1); the joystick steers (left, right, up, down) and fires; the pause (CAPS SHIFT) and K switch to the
keyboard (N, M, X, S steer), K again back to the joystick; B reverses it (left now rolls the other way), Y reverses
the up and down axis, D (damping), R (recentring), Q and S (the sound off and on) toggle their bits; after each
change a push shows its effect on RollRate / PitchRate. Last the pause and 1: back to the title. Played by
tools/elitebot.py; the keys are in work/j1/inputs.txt."""


def rates(b, what, keys, frames=30):
    """hold keys, then note the roll and pitch rates (sign-magnitude) and the options"""
    b.hold(keys)
    b.run(frames)
    roll, pitch = b.byte(0x70E4), b.byte(0x70E5)
    b.hold('')
    sm = lambda v: -(v & 0x7F) if v & 0x80 else v
    b.note(f"{what} ({keys}): roll {sm(roll)} pitch {sm(pitch)} options ${b.byte(0xFC0E):02X} "
           f"control {b.byte(0x72A2)} steer ${b.byte(0xFC09):02X}")
    b.run(40)


def pause(b, *keys):
    b.tap('CS', 15, 40)
    for k in keys:
        b.tap(k, 6, 40)
        b.note(f"pause {k}: options ${b.byte(0xFC0E):02X}")
    b.tap('SPACE', 6, 60)


def plan(b):
    b.start()
    b.note('N: past the first title loop'); b.tap('N', 30, 400)
    b.note('joystick left on the title'); b.tap('KL', 40, 300)
    b.note(f"control method {b.byte(0x72A2)}, options ${b.byte(0xFC0E):02X}, condition {b.byte(0x7104)}")
    b.note('launch'); b.tap('1', 6, 700)
    for k in ('KL', 'KR', 'KU', 'KD'):
        rates(b, 'joystick', k)
    b.note('fire'); b.tap('KF', 30, 40)
    b.note(f"laser heat {b.byte(0x70F0)}")
    rates(b, 'keyboard ignored', 'N')
    pause(b, 'K')
    for k in ('N', 'M', 'X', 'S'):
        rates(b, 'keyboard', k)
    rates(b, 'joystick ignored', 'KL')
    pause(b, 'K')
    rates(b, 'joystick again', 'KL')
    pause(b, 'B')
    rates(b, 'reversed', 'KL')
    rates(b, 'reversed', 'KU')
    pause(b, 'Y')
    rates(b, 'Y reversed too', 'KU')
    pause(b, 'B', 'Y', 'D', 'R', 'Q', 'S')
    rates(b, 'options', 'KL')
    pause(b, 'D', 'R')
    b.note('back to the title'); b.tap('CS', 15, 40); b.tap('1', 6, 300)
    b.note(f"condition {b.byte(0x7104)}")
