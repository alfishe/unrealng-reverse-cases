#!/usr/bin/env python3
"""DrawView ($CCBD) in Python, instruction for instruction in effect: the background, the diagonal walk, DrawCell with
the deferral of robots (bit 6) and the ship (bit 7), DrawSprite with its clipping. It works on a copy of the 64 K
memory (the map and the records are changed by a deferral and put back, as the game does) and gives the 3200 bytes
of the view buffer `$5B00` and the list of what it drew.

    import ill_view
    buf, events = ill_view.draw_view(memory)        # memory: 65536 bytes (bytearray or bytes)

`python3 tools/ill_view.py --trace W/traces/F_T-F_T.uatr` checks it: the buffer it draws from the trace's start
memory against the buffer the game left in the same trace when CopyViewToScreen began (they must be equal).

Used by tools/ill_render.py for the figures of docs 06 and 07 that show views the camera never saw (a fight, the
whole map), and by nothing else.
"""
import argparse
import os
import sys

VIEW, FONT = 0x5B00, 0x6780
MAP_VIEW, SHIP_Y, SHIP_X, ALTITUDE, SHIP_DRAW = 0xFD06, 0xFD0D, 0xFD0E, 0xFD10, 0xFD11
SPRITE_TABLE, PART_SPRITES, PART_HEIGHTS = 0xD6E8, 0xD6C8, 0xD7B4
EDGE_A, EDGE_B = 0xD6A8, 0xD6B8
ROBOTS, SHOTS, BUILDINGS = 0xDA00, 0xD7D3, 0xFF01
BUILDING_SPRITES = [0x2C, 0x28, 0x25, 0x23, 0x20, 0x1D, 0x17, 0x2A, 0x2B]
BUILDING_HEIGHTS = [0x13, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x1A, 0x1A]


def s8(v):
    v &= 0xFF
    return v - 256 if v & 0x80 else v


def word(m, a):
    return m[a] | m[a + 1] << 8


class View:
    """one DrawView over `m` (a bytearray of 65536, changed in place like the game changes memory)"""

    def __init__(self, m, record=None, defer=True):
        self.m = m
        self.defer = defer        # False: draw every object at its own cell (what the deferral avoids)
        self.events = []          # (kind, details...) in drawing order
        self.record = record      # called after each sprite: record(event, m)

    # ------------------------------------------------------------------------------------------- DrawSprite $CF2D
    def sprite(self, sid, e, d, h, why):
        m = self.m
        e2 = (e << 1 | e >> 7) & 0xFF          # RLC E
        l = (e2 + d - 0x18) & 0xFF
        e4 = (e2 << 1 | e2 >> 7) & 0xFF
        hh = (8 * d + 0x64 - e4 - h) & 0xFF
        odd = l & 1
        l = s8(l) >> 1                         # SRA L
        index = (sid & 0x3F) * 2 + odd
        at = word(m, SPRITE_TABLE + 2 * index)
        rows, width = m[at], m[at + 1]
        src = at + 2
        skip = 0
        event = {'kind': why, 'sprite': sid & 0x3F, 'odd': odd, 'e': e, 'd': d, 'h': h, 'col': l, 'line': hh,
                 'rows': rows, 'width': width, 'block': at, 'drawn': False}
        self.events.append(event)
        if not ((l - 0x14) & 0x80):            # CP $14 / RET P
            return
        c = rows
        if hh >= 0xA0:
            if hh >= 0xE2:
                return
            a = (hh - 0x9F - c) & 0xFF
            if not (a & 0x80):
                return
            c = (-a) & 0xFF
            while True:                        # ClipBottomLoop: skip a row of the sprite
                src += 2 * width
                hh = (hh - 1) & 0xFF
                if hh == 0x9F:
                    break
        if l < 0:                              # ClipLeft
            skip = -l
            l = 0
            if skip >= width:
                return
        if l + width >= 0x15:                  # ClipRight
            skip = l + width - 0x14
            src -= 2 * skip
        dst = VIEW + 20 * hh + l
        event['drawn'] = True
        for _ in range(c):                     # SpriteRowLoop
            s, b = src + 2 * skip, width - skip
            p = dst
            for _ in range(b):
                m[p] = (m[p] & m[s]) | m[s + 1]
                s += 2
                p += 1
            src = s
            borrow = (dst & 0xFF) < 20
            dst -= 20
            if borrow and dst >> 8 == 0x5A:
                break
        if self.record:
            self.record(event, m)

    # ----------------------------------------------------------------------------------- DrawViewBackground $CFD7
    def background(self):
        m = self.m
        for a in range(VIEW, FONT):
            m[a] = 0
        if self.record:
            self.record({'kind': 'clear'}, m)
        p, fill = VIEW, 10
        for _ in range(5):
            for _ in range(8):
                for _ in range(fill):
                    m[p] = 0xFF
                    p += 1
                p += 20 - fill
            fill -= 2
        if self.record:
            self.record({'kind': 'corner'}, m)
        for edge, count, dst in ((EDGE_A, 6, VIEW + 0x0A), (EDGE_A, 3, VIEW + 0x0AB2), (EDGE_B, 4, VIEW + 0x0A12)):
            for _ in range(count):
                s = edge
                for _ in range(8):
                    m[dst], m[dst + 1] = m[s], m[s + 1]
                    s += 2
                    dst += 20
                dst -= 2
        if self.record:
            self.record({'kind': 'edges'}, m)

    # ---------------------------------------------------------------------------------------- the neighbour tests
    @staticmethod
    def later(de, hl):
        """KeepLaterCell: is HL drawn after DE? (both map addresses)"""
        c = ((de & 0xFF) - (hl & 0xFF)) & 0xFF
        b = ((de >> 8) - 0xDD) >> 1 & 0x7F
        a = (((((hl >> 8) - 0xDD) & 0xFF) >> 1) - b + c) & 0xFF
        if a & 0x80:
            return de
        if a == 0 and not (c & 0x80):
            return de
        return hl

    def check_block(self, de, hl):
        v = self.m[hl]
        if v & 0x20 or not v & 0x1F:
            return de
        return self.later(de, hl)

    def latest_block(self, de, hl):
        """FindLatestBlock: DE = the latest of DE and the blocks next to HL"""
        p = (hl - 1 + 0x200) & 0xFFFF            # (x-1, y+1)
        if p >> 8 < 0xFD:
            de = self.check_block(de, p)
            p += 1                               # (x, y+1)
            de = self.check_block(de, p)
            p -= 1
        p = (p - 0x200) & 0xFFFF                 # (x-1, y)
        de = self.check_block(de, p)
        p = (p + 2 + 0x200) & 0xFFFF             # (x+1, y+1)
        if p >> 8 < 0xFD:
            de = self.check_block(de, p)
        return de

    def check_object(self, de, hl):
        if not self.m[hl] & 0x40:
            return de
        de = self.later(de, hl)                  # KeepLaterCell, then falls into FindLatestBlock
        return self.latest_block(de, hl)

    # ---------------------------------------------------------------------------------------- DrawMapObjects $CCC6
    def walk(self):
        m = self.m
        m[SHIP_DRAW] = m[SHIP_DRAW + 1] = 0
        ship_x, mv = word(m, SHIP_X), word(m, MAP_VIEW)
        de = ((mv >> 8) & 1) << 8 | (mv & 0xFF)
        e = (ship_x - de) & 0xFF
        self.sprite(1, e, m[SHIP_Y], 0, 'shadow')
        hl = (mv + 0x20) & 0xFFFF
        d, e = 0, 0x20
        while True:
            hl = (hl - 1) & 0xFFFF
            e = (e - 1) & 0xFF
            start_hl, start_de = hl, (d, e)
            self.events.append({'kind': 'diagonal', 'x_minus_y': s8(e)})
            while True:
                if not s8(e) < 0:
                    v = m[hl]
                    if v:
                        self.cell(hl, d, e, v)
                hl = (hl + 0x201) & 0xFFFF
                d += 1
                e = (e + 1) & 0xFF
                if d >= 0x10 or e == 0x20:
                    break
            last_e = e
            hl, (d, e) = start_hl, start_de
            if last_e == 1:
                return

    # ---------------------------------------------------------------------------------------------- DrawCell $CD18
    def cell(self, hl, d, e, v):
        m = self.m
        self.events.append({'kind': 'cell', 'hl': hl, 'd': d, 'e': e, 'v': v})
        if not v & 0x20 and v & 0x1F:
            self.sprite(v & 0x1F, e, d, 0, 'block')
        if v & 0x40:
            self.cell_object(hl, d, e)
        v = m[hl]
        if not v & 0x80:
            return
        bc = word(m, SHIP_DRAW)
        if bc:
            m[hl] &= 0x7F
            self.events.append({'kind': 'ship_undefer', 'hl': hl})
            self.sprite(0, bc & 0xFF, bc >> 8, m[ALTITUDE], 'ship')
            return
        latest = self.latest_block(hl, hl)
        p = (hl - 1 - 0x200) & 0xFFFF            # (x-1, y-1)
        latest = self.check_object(latest, p)
        p = (p + 0x200) & 0xFFFF                 # (x-1, y)
        latest = self.check_object(latest, p)
        p = (p + 0x200) & 0xFFFF                 # (x-1, y+1)
        if p >> 8 < 0xFD:
            latest = self.check_object(latest, p)
            p += 1
            latest = self.check_object(latest, p)
            p += 1
            latest = self.check_object(latest, p)
        if latest != hl and self.defer:
            m[latest] |= 0x80
            m[SHIP_DRAW], m[SHIP_DRAW + 1] = e, d
            self.events.append({'kind': 'ship_defer', 'hl': hl, 'to': latest})
            return
        self.sprite(0, e, d, m[ALTITUDE], 'ship')

    # ------------------------------------------------------------------------------------- DrawCellObject $CE12
    def cell_object(self, hl, d, e):
        m = self.m
        for i in range(48):
            r = ROBOTS + 16 * i
            if word(m, r) == hl:
                return self.mover(hl, d, e, r, 'robot', i)
        for i in range(56):
            b = BUILDINGS + 3 * i
            if word(m, b) == hl:
                t = m[b + 2]
                return self.sprite(BUILDING_SPRITES[t], e, d, BUILDING_HEIGHTS[t], 'building')
        for i in range(5):
            s = SHOTS + 9 * i
            if word(m, s) == hl:
                return self.mover(hl, d, e, s, 'shot', i)

    def mover(self, hl, d, e, r, kind, slot):
        """DrawMover $CE68"""
        m = self.m
        latest = self.latest_block(hl, hl)
        if latest != hl and self.defer:
            m[latest] |= 0x40
            m[r], m[r + 1] = latest & 0xFF, latest >> 8
            self.events.append({'kind': 'defer', 'what': kind, 'slot': slot, 'hl': hl, 'to': latest})
            return
        real = ((word(m, r + 2) + ((2 * m[r + 4] + 0xDD) << 8)) & 0xFFFF)   # MapCell
        if real != hl:
            m[r], m[r + 1] = real & 0xFF, real >> 8
            m[hl] &= 0xBF
            self.events.append({'kind': 'undefer', 'what': kind, 'slot': slot, 'hl': hl, 'real': real})
            p, e = (hl - 1) & 0xFFFF, (e - 1) & 0xFF
            while (real & 0xFF) != (p & 0xFF):
                p, e = p + 1, (e + 1) & 0xFF
            while (real >> 8) != (p >> 8):
                p, d = p - 0x200, d - 1
        self.mover_sprite(r, kind, slot, d, e)

    def mover_sprite(self, r, kind, slot, d, e):
        """DrawMoverSprite $CEC3 / DrawRobot $CEE8"""
        m = self.m
        if kind == 'shot':
            axis = 1 if m[r + 5] >= 3 else 0
            self.sprite(0x2B + 2 * m[r + 7] + axis, e, d, m[r + 8], 'shot')
            return
        parts, h = m[r + 7], m[r + 0x0D]
        facing = m[r + 8]
        direction = 0
        while not facing >> direction & 1 and direction < 8:
            direction += 1
        for part in range(8):
            if parts >> part & 1:
                sid = 0x16 + m[PART_SPRITES + 4 * part + direction]
                self.sprite(sid, e, d, h, f'robot {slot} part {part}')
                h = (h + m[PART_HEIGHTS + part]) & 0xFF


def draw_view(memory, record=None, defer=True):
    m = bytearray(memory)
    v = View(m, record, defer)
    v.background()
    v.walk()
    return bytes(m[VIEW:FONT]), v.events, m


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('--trace', required=True)
    p.add_argument('--unreal')
    a = p.parse_args()
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'kit'))
    import kitlib as K
    at = K.access_trace(a.unreal)
    t = at.load(a.trace)
    copy = next(i for i, x in enumerate(t.instructions) if x.pc == 0xD071)
    start = bytes(t.memory_at(0))
    game = bytes(t.memory_at(copy))[VIEW:FONT]
    mine, events, _ = draw_view(start)
    diff = [i for i in range(3200) if mine[i] != game[i]]
    sprites = [e for e in events if 'sprite' in e]
    print(f'{a.trace}: {len(sprites)} sprites ({sum(e["drawn"] for e in sprites)} drawn), '
          f'{sum(e["kind"] == "cell" for e in events)} cells, '
          f'{len(diff)} bytes differ from the game\'s buffer at CopyViewToScreen')
    for i in diff[:10]:
        print(f'  ${VIEW + i:04X} line {i // 20} byte {i % 20}: mine {mine[i]:02X} game {game[i]:02X}')
    sys.exit(1 if diff else 0)


if __name__ == '__main__':
    main()
