#!/usr/bin/env python3
"""Battle Command's pointer driven from the game's own record: the cursor X at `$7C51` (word) and Y at `$7C53`
(screen pixels), moved with the keys O / P / Q / A held a few frames at a time until it is on the target, then
SPACE (select) tapped. Every move is logged as keys over frames, so the same run can be replayed as an input
script (mm_session format) from the same start.

    from bcbot import Bot; b = Bot(lab); b.click(40, 182); b.script('tests/inputs/x.txt')
"""
CUR_X, CUR_Y = 0x7C51, 0x7C53
# The game's five control systems (OPTIONS 1-5): keys for right, left, down, up, fire; 'mouse' moves the Kempston mouse
CONTROLS = {'keyboard': ('P', 'O', 'A', 'Q', 'SPACE'), 'sinclair': ('7', '6', '8', '9', '0'),
            'cursor': ('8', '5', '6', '7', '0'), 'kempston': ('KR', 'KL', 'KD', 'KU', 'KF'), 'mouse': None}


class Bot:
    def __init__(self, lab, log=None):
        self.lab = lab
        self.log = log if log is not None else []   # [(frame, keys)] from the lab's frame counter
        self.t0 = lab.frame
        self.control = 'keyboard'
        self.mouse_log = []   # [(frame, action, args)]: mouse moves and clicks are not in the input script

    def mouse(self, action, **kw):
        self.mouse_log.append((self.lab.frame, action, kw))
        self.lab.s.call('mouse_input', {'action': action, **kw}, ok=False)

    def hold(self, keys, frames):
        self.log.append((self.lab.frame, list(keys)))
        self.lab.keys(list(keys))
        self.lab.run(frames)
        self.log.append((self.lab.frame, []))
        self.lab.keys([])

    def wait(self, frames):
        self.lab.run(frames)

    def cursor(self):
        b = self.lab.read(CUR_X, 3)
        return b[0] | b[1] << 8, b[2]

    def goto(self, x, y, tol=2, tries=80):
        for _ in range(tries):
            cx, cy = self.cursor()
            dx, dy = x - cx, y - cy
            if abs(dx) <= tol and abs(dy) <= tol:
                return cx, cy
            if self.control == 'mouse':
                self.mouse('move', dx=max(-32, min(32, dx)), dy=-max(-32, min(32, dy)))
                self.wait(2)
                continue
            right, left, down, up, _ = CONTROLS[self.control]
            keys = []
            if dx > tol:
                keys.append(right)
            elif dx < -tol:
                keys.append(left)
            if dy > tol:
                keys.append(down)
            elif dy < -tol:
                keys.append(up)
            step = max(1, min(8, max(abs(dx), abs(dy)) // 3))
            self.hold(keys, step)
            self.wait(1)
        return self.cursor()

    def click(self, x, y, after=25):
        self.goto(x, y)
        if self.control == 'mouse':
            self.mouse('press', button='left')
            self.wait(3)
            self.mouse('release', button='left')
        else:
            self.hold([CONTROLS[self.control][4]], 3)
        self.wait(after)

    def key(self, k, hold=3, after=20):
        self.hold([k] if isinstance(k, str) else k, hold)
        self.wait(after)

    def script(self, path, start=None):
        """The keys so far as an mm_session input script, frames counted from @p start (the bot's first frame)"""
        t0 = self.t0 if start is None else start
        with open(path, 'w') as f:
            for frame, keys in self.log:
                f.write(f"{frame - t0} {' '.join(keys) if keys else '-'}\n")
            f.write(f"{self.lab.frame - t0} END\n")
