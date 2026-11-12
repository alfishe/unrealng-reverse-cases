#!/usr/bin/env python3
"""Switchblade's rooms as the game builds and draws them, for tools/fig_rooms.py: the 3-bit column pictures, the room
builder (BuildRoomPlanes $9F34 / DecodeRoom $9F63, the map commands $A016-$A3C6, SetupRoomObjects $A41E, BuildZones $A4D1) and the
cell drawing (RedrawCell $8867, ComposeBackCell $898C, ComposeFrontCell $8943, ComposeTileWith $89D9).

Ported from the game in stage 2 (work/stage2/ann/ROOM.md); the built planes were checked byte for byte against about
70 snapshots. The builder works on a 64K memory: tools/fig_rooms.py fills it from src/res alone (the tables of page
$73, $7292, $7400-$75FF, $7BD8, the map, the rooms, the tiles, the cell colours) and the 48K ROM, which the open-air
rooms' noise reads (BuildSurface $A039).
"""

# ---- pictures (swgfx) ----

TILES = 0xD104
SPRITE_SETS = 0x6CD6
OUTLINE_MASKS = [0xFF, 0xFC, 0xF8, 0xF8, 0xF1, 0xF0, 0xF0, 0xF0]    # the table at $6F00 (set by the game)
MIRROR3 = [0, 4, 2, 6, 1, 5, 3, 7]                                   # the table at $7A00: a 3-bit value mirrored


def unpack(data, count):
    """count 3-bit values from data, eight values in three bytes, MSB first (UnpackGroups $8BC8)."""
    out = []
    bits = 0
    nbits = 0
    i = 0
    while len(out) < count:
        if nbits < 3:
            bits = (bits << 8) | data[i]
            i += 1
            nbits += 8
        nbits -= 3
        out.append((bits >> nbits) & 7)
    return out


def sprite_sets(mem):
    """The 24 records of PageTail60 $6CD6: (address, columns, rows, bytes a frame, frames)."""
    recs = []
    for i in range(24):
        a = SPRITE_SETS + 5 * i
        w, h, size, lo, hi = mem[a:a + 5]
        recs.append([lo | hi << 8, w // 2, h, size])
    for k, r in enumerate(recs):
        end = recs[k + 1][0] if k + 1 < len(recs) else 0xFD98
        r.append((end - r[0]) // r[3])
    return [tuple(r) for r in recs]


def frame_columns(mem, addr, cols, rows):
    """A picture at addr as a list of columns of 3-bit values."""
    per = rows * 3 // 8
    return [unpack(mem[addr + c * per:addr + (c + 1) * per], rows) for c in range(cols)]


def tile_columns(mem, n):
    """Tile n (1-based) of set 0: 4 columns of 16 values (FrameRecord $8EA3)."""
    return frame_columns(mem, TILES + 24 * ((n - 1) & 0xFFFF) % 0x10000, 4, 16)


class Chunky:
    """A picture of 3-bit column values, the game's chunk buffer: one byte per 3-pixel unit and pixel line."""

    def __init__(self, cols, rows):
        self.cols = cols
        self.rows = rows
        self.v = [[0] * rows for _ in range(cols)]

    def put(self, x, y, columns):
        """Overwrite: the plain tile draw (UnpackGroups $8BC8 into the buffer)."""
        for i, col in enumerate(columns):
            for j, val in enumerate(col):
                self.v[x + i][y + j] = val

    def put_and(self, x, y, columns):
        """AND the values in: the shade overlay (AndTileLoop $8A30)."""
        for i, col in enumerate(columns):
            for j, val in enumerate(col):
                self.v[x + i][y + j] &= val

    def put_masked(self, x, y, columns):
        """Draw with a one-pixel black outline above, below and inside the 3-pixel unit (MaskedColumn $8C0F).

        Row k: buffer = buffer AND mask[v(k-1)] AND mask[v(k)] AND mask[v(k+1)] OR v(k). The first row leaves
        mask[v(0)] out (the game's quirk); the last row has no v(k+1)."""
        for i, col in enumerate(columns):
            n = len(col)
            for k in range(n):
                m = OUTLINE_MASKS[col[1]] if k == 0 else OUTLINE_MASKS[col[k - 1]] & OUTLINE_MASKS[col[k]]
                if 0 < k < n - 1:
                    m &= OUTLINE_MASKS[col[k + 1]]
                cur = self.v[x + i][y + k]
                self.v[x + i][y + k] = (cur & m | col[k]) & 0xFF

    def pixels(self):
        """Rows of 0/1 pixels, 3 per unit, bit 2 left."""
        out = []
        for y in range(self.rows):
            line = []
            for x in range(self.cols):
                val = self.v[x][y] & 7
                line += [(val >> 2) & 1, (val >> 1) & 1, val & 1]
            out.append(line)
        return out


def mirror(columns):
    """A picture mirrored left to right (MirroredColumn $8C51 mirrors each value; the caller walks the columns back)."""
    return [[MIRROR3[v] for v in col] for col in reversed(columns)]


# ---- the room builder ----

ROOM_TABLE = 0x7100
SHAPE_BASES = 0x7300        # 16 bytes: the first shape of a placement's style (low nibble of its first byte)
SHAPES = 0x7300             # page $73: shapes, tile strings ($A02E), the bar styles
HORIZON = 0x74F5            # 20 bytes from $74F5 + room: the horizon row of a surface room
SOLID_LIST = 0x7292         # (page, tile) pairs that count as solid for the shading ($A300, 33 pairs)
SOLID_LIST2 = 0x7294        # the same list from its second pair, 34 pairs ($A32F)
ITEM_TILES = 0x7BD8         # (tile, page) per pickup type ($A4B8)


def room_address(mem, room):
    """RoomDataAddress $A3C9: the room's data."""
    return mem[ROOM_TABLE + 2 * room] | mem[ROOM_TABLE + 2 * room + 1] << 8


class Builder:
    def __init__(self, mem, rom=None):
        """mem: a 64K memory with the room tables, the rooms and the tiles at their addresses; rom: the 48K ROM, read
        by Surface's noise (put at $0000)."""
        self.m = bytearray(mem)
        if rom:
            self.m[0:0x4000] = rom[:0x4000]
        self.m[0x6BE3] = 0                                  # CellColour: 0 after the first surface room
        self.trace = []

    # --- memory helpers -------------------------------------------------------------------------------------------
    def rd(self, a):
        return self.m[a & 0xFFFF]

    def cell(self, page, l):
        return self.m[page << 8 | (l & 0xFF)]

    def setc(self, page, l, v):
        self.m[page << 8 | (l & 0xFF)] = v & 0xFF

    def clear(self, count, start):
        """ClearRoomCells $70EF: count cells from start in the six pages."""
        for i in range(count or 256):
            for p in range(0x67, 0x6D):
                self.setc(p, start + i, 0)

    def place(self, page, l, v):
        """PutTileMarkA $A408: the tile, and bit 0 of the zone byte (a tile is here)."""
        self.setc(page, l, v)
        self.setc(0x67, l, 1)

    def place_coloured(self, page, l, v):
        """PutTileMarkPropA $A3F4: the tile, the zone byte 1, the colour byte = CellProperty $6BE3."""
        self.setc(page, l, v)
        self.setc(0x67, l, 1)
        self.setc(0x6C, l, self.m[0x6BE3])

    # --- BuildRoomPlanes $9F34 ------------------------------------------------------------------------------------------
    def build(self, room, above):
        """BuildRoomPlanes $9F34: the room above's bottom row into cells $EC-$FF, then the room. Returns the address after
        the map commands (the zones and objects, read by SetupRoomObjects $A41E)."""
        self.m[0x6BDC] = above
        self.m[0x6BDD] = room
        if above == 0:
            self.clear(0x14, 0xEC)
        else:
            self.build_map(room_address(self.m, above), 0xFF)
            for p in range(0x68, 0x6C):
                for i in range(20):
                    self.setc(p, 0xEC + i, self.cell(p, 0xC8 + i))
        end = self.build_map(room_address(self.m, room), 0)
        self.objects(end)
        return end

    def build_map(self, bc, above_flag):
        """DecodeRoom $9F63: clear the map, the three placement groups, the commands."""
        self.m[0x6AEB] = above_flag
        self.clear(0xDC, 0)
        hdr = self.rd(bc)
        bc += 1
        counts = [hdr & 7, (hdr >> 3) & 7, hdr >> 6]
        # Group g (0, 1, 2) starts its shapes one further: s = base + g ($9F86: 3 - E + base, E = 3, 2, 1)
        for g, n in enumerate(counts):
            for _ in range(n):
                bc = self.placement(bc, g)
        return self.commands(bc)

    def placement(self, bc, g):
        """$9F78: one placement: byte 1 = count << 4 | style, byte 2 = the first cell. Each step puts the shape's
        tile(s) on the back layer $68: 1, or 2 and 3 side by side (shape bit 7); bits 5-0 the step to the next
        cell; bit 6 restarts the style's shape list."""
        b1 = self.rd(bc)
        base = self.m[SHAPE_BASES + (b1 & 0x0F)]
        self.m[0x6BDE] = (base - 1) & 0xFF
        s = (base + g) & 0xFF
        count = b1 >> 4
        bc += 1
        l = self.rd(bc)
        for _ in range(count or 256):
            sh = self.m[SHAPES + s]
            if sh & 0x80:
                self.place(0x68, l, 2)
                l = (l + 1) & 0xFF
                self.place(0x68, l, 3)
            else:
                self.place(0x68, l, 1)
            l = (l + (sh & 0x3F)) & 0xFF
            if sh & 0x40:
                s = self.m[0x6BDE]
            s = (s + 1) & 0xFF
        return bc + 1

    def commands(self, bc):
        """$9FD6: the command list. Byte: low nibble the code, high nibble the repeat (code $0D: bit 4 + 1 and the
        style in bits 7-5). Codes: 0-3 tile strings on layer $68+code, 4 the surface, 5/6/9/$A bars from four style
        tables, 7/8/$C bars on a fixed layer, $B small pieces, $D wall fill and shading, $E decorations, $F the end."""
        while True:
            b = self.rd(bc)
            code = b & 0x0F
            hi = b >> 4
            reps = (hi & 1) + 2 if code == 0x0D else hi + 1
            bc += 1
            reps -= 1
            if reps == 0:
                continue
            if code >= 0x0D and self.m[0x6AEB] & 0x80:
                return bc                  # the room above: only its map up to the first code >= $0D
            self.trace.append((bc - 1, code, hi))
            if code <= 3:
                bc = self.strings(bc, code, hi)
                continue
            if code == 0x0F:
                self.fixups()
                return bc
            if code == 0x0D:
                bc = self.wall_fill(bc, b, reps)
                continue
            while reps:
                if code == 4:
                    self.surface(bc, code)
                elif code in (5, 6, 7, 8, 9, 0x0A, 0x0C):
                    bc = self.bar(bc, code)
                elif code == 0x0B:
                    bc = self.piece(bc)
                elif code == 0x0E:
                    bc = self.decor(bc)
                if code != 4:                              # Surface returns to $9FEF: no operand
                    bc += 1
                reps -= 1

    def strings(self, bc, code, n):
        """ObjectPattern $A016: n pairs (cell, string index); PlotPattern $A02E writes tile, step, tile, ... from
        page $73 until a step with bit 7 set, on layer $68 + code. Not marked in the zone page."""
        page = 0x68 + code
        for _ in range(n or 256):
            l = self.rd(bc)
            bc += 1
            e = self.rd(bc)
            while True:
                self.setc(page, l, self.m[SHAPES + e])
                e = (e + 1) & 0xFF
                step = self.m[SHAPES + e]
                if step & 0x80:
                    break
                l = (l + step) & 0xFF
                e = (e + 1) & 0xFF
            bc += 1
        return bc

    def next2(self, state):
        """$A0AD: the next noise value 1-3 from the stream bytes after the command (low 2 bits, 0 read as 1), never
        twice in a row."""
        while True:
            state[0] += 1
            a = self.rd(state[0]) & 3 or 1
            if a != state[1]:
                state[1] = a
                return a

    def surface(self, bc, code):
        """BuildSurface $A039 (code 4): the open-air rows; the stream pointer is restored after (the noise only reads)."""
        room = self.m[0x6BDD]
        self.m[0x6BE3] = 0x20
        state = [bc, code]                                  # room 123: the noise reads the room's own bytes
        if room == 0x7B:
            l = 0xC8
            n = 0x0E
        else:
            for i in range(0x78):
                self.setc(0x6C, i, 0x20)
            for row in range(4):
                for i in range(20):
                    self.setc(0x68, 20 * row + i, 0x33 + row)
            for i in range(20):
                self.setc(0x68, 0x50 + i, self.m[HORIZON + room + i])
            neg = (-room) & 0xFF
            state[0] = neg                                  # LDIR left BC = 0, then C = -room: the noise reads
                                                            # the ROM from $0000 + 256 - room + 1
            self.setc(0x68, 9 + neg, 0x37)                 # the sun (cell 9 - room: rooms 1-9)
            if neg < 0xFC:
                self.setc(0x68, neg + 0x54, 0x43)
            for i in range(20):
                self.setc(0x68, 0x64 + i, self.next2(state) + 0x3B)
            l = 0x78
            n = 0x14
        for _ in range(n):
            self.place_coloured(0x6B, l, self.next2(state) + 0x80)
            l = (l + 1) & 0xFF
        self.m[0x6BE3] = 0

    BAR_TABLES = {5: (0x75AD, True, None), 0x0A: (0x7511, True, None), 6: (0x7400, False, None),
                  9: (0x7436, False, None), 7: (0x7571, None, 0x69), 8: (0x7571, None, 0x6A), 0x0C: (0x7496, None, 0x68)}

    def bar(self, bc, code):
        """StripRecordAddress $A0EE / $A101 / $A109: a run of tiles from a 6-byte style record (page | mark flag, after-a-wall
        piece, first piece, two alternating middle pieces, last piece). Operand 1: style << 4 | length (0 = 16),
        operand 2: the first cell. Codes 5 / $A run right, 6 / 9 down; 7, 8, $C right below a table split
        (IX low byte < $A7 / $DE) and down from there, on a fixed layer."""
        table, horizontal, page = self.BAR_TABLES[code]
        ix = table + 6 * (self.rd(bc) >> 4)
        if page is None:
            page = self.m[ix] & 0x7F
        else:
            horizontal = (ix & 0xFF) < (0xA7 if code in (7, 8) else 0xDE)
        step = 1 if horizontal else 0x14
        self.m[0x6BDF] = step
        n = self.rd(bc) & 0x0F or 0x10
        bc += 1
        l = self.rd(bc)
        rec = self.m[ix:ix + 6]
        mark = rec[0] & 0x80

        def put(v, both):
            self.setc(page, l, v)                          # $A410 / $A416
            if both and mark:
                self.setc(0x67, l, 1)
                self.setc(0x6C, l, self.m[0x6BE3])

        n -= 1
        if n == 0:
            put(rec[1], True)
            return bc
        put(rec[2], True)
        k = 3
        d = None
        while True:
            d = rec[k]
            l = (l + step) & 0xFF
            n -= 1
            if n == 0:
                put(rec[5], step & 1)
                return bc
            while True:
                if (self.cell(0x68, l) - 1) & 0xFF >= 0x1A:
                    put(d, step & 1)
                    k ^= 7
                    break
                d = rec[1]
                l = (l + step) & 0xFF
                n -= 1
                if n == 0:
                    put(d, step & 1)
                    return bc

    def piece(self, bc):
        """ObjectTypeB $A006 (code $B): operand 1 high nibble selects the routine of RoomCodeHandlersB $75EF."""
        sub = self.rd(bc) >> 4
        if sub in (1, 5):                                  # $A1E2 / $A1E6: set / clear a cell's zone byte
            bc += 1
            self.setc(0x67, self.rd(bc), 1 if sub == 1 else 0)
            return bc
        n = self.rd(bc) & 0x0F
        if sub == 0:                                       # $A164: a row on layer $6B: $76 over $75, else $77
            n = n or 0x10
        bc += 1
        l = self.rd(bc)
        if sub == 0:
            while True:
                self.setc(0x6B, l, 0x76 if self.cell(0x6B, l) == 0x75 else 0x77)
                n -= 1
                if n == 0:
                    return bc
                l = (l + 1) & 0xFF
        if sub == 2:                                       # $A179: a two-wide column $2D $2E on layer $68
            self.place(0x68, l, 0x2D)
            self.place(0x68, l + 1, 0x2E)
            while True:
                l = (l + 0x14) & 0xFF
                n = (n - 1) & 0xFF
                if n == 0:
                    return bc
                self.setc(0x68, l, 0x2D)
                self.setc(0x68, l + 1, 0x2E)
        if sub in (3, 4):                                  # $A197 / $A1C5: a column $31 $32 (sub 4: a $30 cap)
            self.m[0x6BE3] = 0x10
            if sub == 3:
                self.place_coloured(0x6B, l, 0x31)
                self.place_coloured(0x6B, l + 1, 0x32)
            else:
                n = (n + 2) & 0xFF
                self.place_coloured(0x6B, l, 0x30)
                l = (l + 0x15) & 0xFF
                self.place_coloured(0x6B, l, 0x31)
                l = (l - 1) & 0xFF
                n = (n - 1) & 0xFF
                if n:
                    self.setc(0x6B, l, 0x31)
                    self.setc(0x6C, l, 0x10)
                    self.setc(0x6B, l + 1, 0x32)
                    self.setc(0x6C, l + 1, 0x10)
                else:
                    self.m[0x6BE3] = 0
                    return bc
            while True:
                l = (l + 0x14) & 0xFF
                n = (n - 1) & 0xFF
                if n == 0:
                    break
                self.setc(0x6B, l, 0x31)
                self.setc(0x6C, l, 0x10)
                self.setc(0x6B, l + 1, 0x32)
                self.setc(0x6C, l + 1, 0x10)
            self.m[0x6BE3] = 0
        return bc

    # --- RoomOpFillBack $A1F1: the back wall and its shading -----------------------------------------------------------
    def solid(self, l, lst, count):
        """TestCellSolid $A334: the back tile at l is a wall (1-$19), or empty / >= $1A and one of the (page, tile)
        pairs matches."""
        a = self.cell(0x68, l)
        if a and a < 0x1A:
            return True
        for i in range(count):
            if self.cell(self.m[lst + 2 * i], l) == self.m[lst + 2 * i + 1]:
                return True
        return False

    @staticmethod
    def row_start(l):
        """$A3EA: Z when l is 20, 40, ... 240."""
        return any(l == 20 * k for k in range(1, 13))

    def wall_fill(self, bc, cmd, reps):
        self.m[0x6BE0] = cmd >> 5
        for _ in range(reps):
            self.fill_from(self.rd(bc))
            bc += 1
        return bc

    def shade_bits(self, l):
        """$A300: bit 2 the cell on the left is solid, bit 1 the one above, bit 0 above-left; 7 counts as 6."""
        c = 0
        for nl in ((l - 1) & 0xFF, (l - 0x14) & 0xFF, (l - 0x15) & 0xFF):
            c = (c << 1) | self.solid(nl, SOLID_LIST, 0x21)
        return 6 if c == 7 else c

    def set_shade(self, l, c):
        """$A2CD: the shade nibble from the neighbour bits; 4 and 2 add a corner tile on layer $69 when empty."""
        if c == 4 and not self.cell(0x69, l):
            self.setc(0x69, l, 0x65)
        if c == 2 and not self.cell(0x69, l):
            self.setc(0x69, l, 0x66)
        b = c - 1 if c >= 5 else c
        self.setc(0x6C, l, self.cell(0x6C, l) & 0xF0 | b)

    def fill_cell(self, l, c):
        """$A2B8: an empty cell gets the wall tile $1A + style and its shade; tile $2E with shade 4-5 becomes $2F."""
        a = self.cell(0x68, l)
        if a == 0:
            self.set_shade(l, c)
            self.setc(0x68, l, self.m[0x6BE0] + 0x1A)
            return
        if c == 0:
            return
        if a != 0x2E:
            self.set_shade(l, c)
            return
        if 4 <= c < 6:
            self.setc(0x68, l, 0x2F)

    def scan_right(self, l):
        """$A265: fill cells to the right until a wall or the row's end. Returns the last l."""
        while True:
            a = self.cell(0x68, l)
            if a == 0xFF:
                self.setc(0x68, l, 0)
                self.m[0x6BE2] = (l + 0x14) & 0xFF
                return l
            if a == 0 or a + 1 >= 0x1A:
                if self.solid(l, SOLID_LIST2, 0x22):
                    if self.solid((l - 0x14) & 0xFF, 0x72B4, 3):
                        for i in range(3):
                            p, v = self.m[0x72D8 + 2 * i], self.m[0x72D9 + 2 * i]
                            if self.cell(p, l) == v:
                                self.setc(p, l, v - 1)
                else:
                    self.fill_cell(l, self.shade_bits(l))
            else:
                return l
            l = (l + 1) & 0xFF
            if self.row_start(l):
                return (l - 1) & 0xFF

    def fill_from(self, start):
        """FillBackFrom $A20D: from a cell, find the wall on the left, fill to the right; then the row below while
        it is open."""
        self.m[0x6BE1] = start
        l = start
        mode = 'left'
        while True:
            if mode == 'left':                              # $A23F
                l = (l - 1) & 0xFF
                a = self.cell(0x68, l)
                if a == 0xFF:
                    self.setc(0x68, l, 0)
                    mode = 'right'
                    continue
                if self.row_start(l):
                    if a == 0 and not self.solid(l, SOLID_LIST2, 0x22):
                        c = 3 if self.solid((l - 0x14) & 0xFF, SOLID_LIST, 0x21) else 0
                        self.fill_cell(l, c)
                    mode = 'right'
                    continue
                if a == 0 or a >= 0x1F:
                    continue
                mode = 'right'
                continue
            # $A218
            l = (l + 1) & 0xFF
            self.scan_right(l)
            nxt = (self.m[0x6BE1] + 0x14) & 0xFF
            self.m[0x6BE1] = nxt
            if nxt >= 0xDC:
                return
            l = nxt
            a = self.cell(0x68, l)
            if a == 0xFF:
                while True:                                 # $A22C
                    self.setc(0x68, l, 0)
                    l = (l + 1) & 0xFF
                    if l == self.m[0x6BE2] or self.cell(0x68, l) != 0xFF:
                        return
            if a != 0 and a < 0x1F:
                return
            mode = 'left'

    def decor(self, bc):
        """RoomOpLedge $A357 (code $E): a row of front tiles on layer $6B from the pair table $73BD (operand high nibble
        2) or $73C1: the second tile over the record's tiles 3 / 4, else the first; shade 6 on the first cell
        unless the shade is 2 or ..., 7 after; the cell after the row gets shade 8 / 5 and the corner $65."""
        n = self.rd(bc) & 0x0F or 0x10
        ix = 0x73BD if self.rd(bc) & 0xF0 == 0x20 else 0x73C1
        bc += 1
        l = self.rd(bc)
        sh = self.cell(0x6C, l) & 0x0F
        c = 6 if sh == 2 or (sh == 0 and not self.row_start(l)) else 7
        while True:
            a = self.cell(0x6B, l)
            d = self.m[ix + 1] if a in (self.m[ix + 2], self.m[ix + 3]) else self.m[ix]
            self.place(0x6B, l, d)
            self.setc(0x6C, l, self.cell(0x6C, l) & 0xF0 | c)
            c = 7
            l = (l + 1) & 0xFF
            n -= 1
            if n == 0:
                break
        if not self.row_start(l) and not self.solid(l, SOLID_LIST2, 0x22):
            sh = self.cell(0x6C, l) & 0x0F
            c = 8 if sh in (0, 1) else 5
            self.setc(0x6C, l, sh | c)
            self.setc(0x69, l, 0x65)
        return bc

    def fixups(self):
        """RoomPatch $72DE (code $F, the end): room 1 colours row 6 columns 0-9; room 8 clears four colours."""
        room = self.m[0x6BDD]
        if room == 1:
            for i in range(10):
                self.setc(0x6C, 0x78 + i, 0x20)
        elif room == 8:
            for a in (0x6C5A, 0x6C5B, 0x6C6E, 0x6C6F):
                self.m[a] = 0

    # --- SetupRoomObjects $A41E, BuildZones $A4D1 -----------------------------------------------------------------------
    def objects(self, bc):
        """SetupRoomObjects $A41E: the zone records (each: byte n << 4 | last << 3 | e, n rectangles (first, last cell),
        e single cells; bit 3 set on the last record; a 0 byte: no zones), then a byte counts << 4 | items, then
        2 x items bytes (pickups) and 2 x counts bytes (the enemy starts) copied to $5B01."""
        zones = []
        if self.rd(bc) == 0:
            zones.append(0x75FB)                           # no zones of its own: the one record at $75FB
            bc += 1
        else:
            while True:
                zones.append(bc)
                b = self.rd(bc)
                bc += 1 + 2 * ((b >> 4) & 7) + (b & 7)
                if b & 8:
                    break
        self.zone_records = zones
        b = self.rd(bc)
        enemies = b >> 4
        items = b & 0x0F
        bc += 1
        self.items = [(self.rd(bc + 2 * i), self.rd(bc + 2 * i + 1)) for i in range(items)]
        bc += 2 * items
        self.enemies = [(self.rd(bc + 2 * i), self.rd(bc + 2 * i + 1)) for i in range(enemies)]
        self.objects_end = bc + 2 * enemies
        self.zones(zones)
        for b0, cell in self.items:                       # $A49E: the pickups not yet taken (all, here)
            t = b0 >> 5
            tile, page = self.m[ITEM_TILES + 2 * t], self.m[ITEM_TILES + 2 * t + 1]
            self.setc(page, cell, tile)
            if tile != 0x8C:
                self.setc(0x67, cell, self.cell(0x67, cell) | 2)

    def zones(self, recs):
        """BuildZones $A4D1: zone k (bit 7 - k of the zone byte) covers its rectangles (cells holding 0 or 1 only)
        and its single cells (forced)."""
        bit = 0x80
        for rec in recs:
            b = self.rd(rec)
            p = rec + 1
            for _ in range((b >> 4) & 7):
                first, last = self.rd(p), self.rd(p + 1)
                q, r = divmod((last - first) & 0xFF, 20)
                for row in range(q + 1):
                    for col in range(r + 1):
                        l = (first + 20 * row + col) & 0xFF
                        if self.cell(0x67, l) < 2:
                            self.setc(0x67, l, self.cell(0x67, l) | bit)
                p += 2
            for _ in range(b & 7):
                l = self.rd(p)
                self.setc(0x67, l, self.cell(0x67, l) & 3 | bit)
                p += 1
            bit >>= 1


# ---- drawing ----

ROWS, COLS = 11, 20
BLANK = 0x43
COLOURS = 0x66F7


def draw_overlay(pic, mem, x, y, tile, shade):
    """ComposeTileOverlay $89D2: the tile plain (UnpackGroups), then from $1B on the shade tile $43 + n ANDed over it
    (ComposeOverlay $8A06), whatever the tile's code."""
    pic.put(x, y, tile_columns(mem, tile))
    if tile >= 0x1B and shade:
        pic.put_and(x, y, tile_columns(mem, BLANK + shade))


def draw_tile(pic, mem, x, y, tile, shade):
    """ComposeTile $89CE: $4B and up outlined (MaskedColumns $8C0A), never shaded; below, ComposeTileOverlay."""
    if tile >= 0x4B:
        pic.put_masked(x, y, tile_columns(mem, tile))
        return
    draw_overlay(pic, mem, x, y, tile, shade)


def draw_pair(pic, mem, x, y, t1, t2, shade):
    if t1:
        draw_tile(pic, mem, x, y, t1, shade)
    if t2:
        draw_tile(pic, mem, x, y, t2, shade)


def render(mem, revealed=0xFC, rows=ROWS):
    """The room map in mem's pages $67-$6C as a chunk picture (80 units x 16 rows) and a 30 x 2 rows attribute grid.

    revealed: the zone bits shown ($6DFF in the game); 0xFC shows every zone."""
    pic = Chunky(COLS * 4, rows * 16)
    attrs = {}
    for cell in range(rows * COLS):
        r, c = divmod(cell, COLS)
        x, y = 4 * c, 16 * r
        zone = mem[0x6700 + cell]
        t = [mem[0x6800 + cell], mem[0x6900 + cell], mem[0x6A00 + cell], mem[0x6B00 + cell]]
        shade = mem[0x6C00 + cell] & 0x0F
        if not zone & revealed & 0xFC:
            continue                               # RedrawCell $8867 leaves (or blanks) an unrevealed cell
        if not any(t):
            draw_tile(pic, mem, x, y, BLANK, 0)    # $8873: cleared, the attributes left as they are
            continue
        if t[0] and t[1]:                          # ComposeBackCell $898C: a pair through ComposeTile
            draw_pair(pic, mem, x, y, t[0], t[1], shade)
        else:                                      # one tile (any code) or $43: ComposeTileOverlay, plain
            draw_overlay(pic, mem, x, y, t[0] or t[1] or BLANK, shade)
        draw_pair(pic, mem, x, y, t[2], t[3], shade)
        attr = mem[COLOURS + (mem[0x6C00 + cell] >> 4)]
        col = 1 + (12 * c) // 8
        for dy in (0, 1):
            for dx in (0, 1):
                attrs[(1 + 2 * r + dy, col + dx)] = attr
    return pic, attrs


SPECTRUM = [(0, 0, 0), (0, 0, 0xCD), (0xCD, 0, 0), (0xCD, 0, 0xCD), (0, 0xCD, 0), (0, 0xCD, 0xCD), (0xCD, 0xCD, 0),
            (0xCD, 0xCD, 0xCD), (0, 0, 0), (0, 0, 0xFF), (0xFF, 0, 0), (0xFF, 0, 0xFF), (0, 0xFF, 0), (0, 0xFF, 0xFF),
            (0xFF, 0xFF, 0), (0xFF, 0xFF, 0xFF)]


def to_screen(pic, attrs):
    """A 256 x 192 bitmap (rows of 0/1) and a 24 x 32 attribute grid, the room at (8, 8)."""
    bm = [[0] * 256 for _ in range(192)]
    for y, line in enumerate(pic.pixels()):
        if 8 + y >= 192:
            break
        for x, p in enumerate(line):
            bm[8 + y][8 + x] = p
    at = [[0] * 32 for _ in range(24)]
    for (r, c), a in attrs.items():
        if r < 24:
            at[r][c] = a
    return bm, at


def png(path, bm, at, scale=2):
    from PIL import Image
    img = Image.new('RGB', (256 * scale, 192 * scale))
    px = img.load()
    for y in range(192):
        for x in range(256):
            a = at[y // 8][x // 8]
            bright = 8 if a & 0x40 else 0
            col = SPECTRUM[(a & 7) + bright] if bm[y][x] else SPECTRUM[((a >> 3) & 7) + bright]
            for dy in range(scale):
                for dx in range(scale):
                    px[x * scale + dx, y * scale + dy] = col
    img.save(path)


def screen_of(mem):
    """The bitmap and attributes of a 64K memory image's screen."""
    bm = [[0] * 256 for _ in range(192)]
    for y in range(192):
        base = 0x4000 | ((y & 0xC0) << 5) | ((y & 7) << 8) | ((y & 0x38) << 2)
        for xb in range(32):
            b = mem[base + xb]
            for k in range(8):
                bm[y][xb * 8 + k] = (b >> (7 - k)) & 1
    at = [[mem[0x5800 + 32 * r + c] for c in range(32)] for r in range(24)]
    return bm, at
