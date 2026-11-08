#!/usr/bin/env python3
"""The 8 title ships in the emulator against tools/shipsim.py (docs/3d-engine.md 3): from work/snaps/title-A.szx,
N pressed between the ships; for each, the 64 KB at TitleLoop $73C3 and the back buffer at the next TitleLoop, then
shipsim's title pass from that memory. Writes work/titleproof/<n>-mem.bin, <n>-real.bin. Needs the instance in
work/view (re_session open; muted here).

    python3 tools/title_proof.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.path.join(HERE, '..', 'work')
sys.path.insert(0, HERE)
import elitebot as EB  # noqa: E402
import lenslok_live as LL  # noqa: E402

OUT = os.path.join(WORK, 'titleproof')
TITLE_LOOP = 0x73C3
TITLE_LOAD = 0x7378   # the first title ("Load New Commander"), before any key


def main():
    b = EB.Bot(os.path.join(WORK, 'view'))
    b.load_snapshot(os.path.join(WORK, 'snaps', 'title-A.szx'))
    lv = LL.Live(b.s)
    b.run(60)
    for i in range(8):
        if i == 1:
            b.tap('N', 24, 120)
        elif i > 1:
            b.tap('SPACE', 24, 200)          # a new game, docked
            b.tap('CS', 15, 40)              # the pause
            b.tap('1', 6, 200)               # back to the title: TitleNext, the next ship
            b.tap('N', 24, 120)
        pc = TITLE_LOAD if i == 0 else TITLE_LOOP
        for k in range(3):               # a few passes in, then two in a row
            lv.until(pc, 50)
            lv.frames(1)
        lv.until(pc, 50)
        mem = lv.read(0, 0x10000)
        lv.call('control_execution', {'action': 'step', 'count': 1})
        lv.until(pc, 50)
        real = lv.read(0xC000, 0x1000)
        open(os.path.join(OUT, '%d-mem.bin' % i), 'wb').write(mem)
        open(os.path.join(OUT, '%d-real.bin' % i), 'wb').write(real)
        print(i, 'title ship header $%04X' % (mem[0x6048 + 7 * 39 + 0x23] | mem[0x6048 + 7 * 39 + 0x24] << 8))


if __name__ == '__main__':
    main()
