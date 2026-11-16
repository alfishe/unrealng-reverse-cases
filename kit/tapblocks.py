#!/usr/bin/env python3
"""The blocks of a TAP or TZX file: list them, or write the data of one.

    python3 tapblocks.py list FILE.tap                # index, length, ROM-speed time, header fields, checksum
    python3 tapblocks.py FILE.tap INDEX OUT.bin       # INDEX counts every block, headers included (0-based)
    python3 tapblocks.py list FILE.tzx                # every TZX block: id, kind, timings, length, flag, checksum,
                                                      # header fields, play time; the total with the pauses
    python3 tapblocks.py FILE.tzx INDEX OUT.bin       # INDEX counts every TZX block (texts, pauses, loops too)

A TAP block is written without its flag byte and checksum, after the checksum is checked. A TZX block's data is
written as the block holds it, flag and checksum included: a turbo or pure-data block need have neither (SpeedLock).
The file's kind comes from its first bytes ("ZXTape!" is a TZX), not its name.

The TZX walk knows every block of the TZX 1.20 format: the data blocks (10 standard, 11 turbo, 14 pure data), the
signal blocks (12 tone, 13 pulses, 15 direct recording, 18 CSW, 19 generalized data), the flow blocks (20 pause,
21/22 group, 23 jump, 24/25 loop start / end of MakeTZX dumps, 26/27 call / return, 28 select, 2A stop on a 48K,
2B signal level), the info blocks (30 text, 31 message, 32 archive info, 33 hardware, 35 custom, 5A glue) and the
old 16/17/34/40. A byte that is no block id stops the walk: `list` prints the blocks before it and says where
(TOSEC's Enduro Racer `[a]`: id $2F at offset 31 702, the length of the pure-data block before it is wrong), and
exits with status 1.

    import tapblocks
    for b in tapblocks.parse_tzx(open('game.tzx', 'rb').read()):   # {index, id, offset, kind, size, [data, pause,
        ...                                                        #  timing, text, items]}
    tapblocks.tzx_seconds(b), tapblocks.tzx_describe(b['data'])
"""
import sys

KINDS = {0: 'Program', 1: 'Number array', 2: 'Character array', 3: 'Bytes'}
TZX_MAGIC = b'ZXTape!\x1a'
# the ROM's timings (T-states of a pulse, pulses of the pilot), the default of a standard block
STD = dict(pilot=2168, sync1=667, sync2=735, zero=855, one=1710, last=8)


def raw_blocks(tap):
    """(offset, flag, data without flag and checksum, checksum ok)"""
    i = 0
    while i + 2 <= len(tap):
        length = tap[i] | tap[i + 1] << 8
        body = tap[i + 2:i + 2 + length]
        checksum = 0
        for b in body:
            checksum ^= b
        yield i, body[0] if body else None, body[1:-1], checksum == 0 and len(body) == length
        i += 2 + length


def blocks(tap):
    for offset, _flag, data, ok in raw_blocks(tap):
        if not ok:
            raise SystemExit(f'block at {offset}: bad checksum')
        yield data


def rom_seconds(flag, data, checksum_byte=0):
    """The block's play time at ROM speed (pilot, sync, the bits of flag, data and checksum; no pause)"""
    pilot = (8063 if (flag or 0) < 128 else 3223) * 2168 + 667 + 735
    ones = sum(bin(b).count('1') for b in [flag or 0, *data, checksum_byte])
    bits = 8 * (len(data) + 2)
    return (pilot + ones * 2 * 1710 + (bits - ones) * 2 * 855) / 3500000


def describe(flag, data):
    if flag == 0 and len(data) == 17:
        kind = KINDS.get(data[0], f'type {data[0]}')
        name = data[1:11].decode('latin-1').rstrip()
        length, p1, p2 = (int.from_bytes(data[k:k + 2], 'little') for k in (11, 13, 15))
        if data[0] == 0:
            return f'header {kind} "{name}" length {length}' + (f' LINE {p1}' if p1 < 32768 else '') + f' vars {p2}'
        return f'header {kind} "{name}" length {length} start {p1} (${p1:04X})' + (f' param2 {p2}' if data[0] == 3 else '')
    return f'data, flag ${flag:02X}' if flag is not None else 'empty'


# ---------------------------------------------------------------------------------------------------------------
# TZX


class TzxError(ValueError):
    """a byte that is no block id, or a block cut short by the file's end; .offset, .blocks (the ones before)"""

    def __init__(self, text, offset, before):
        super().__init__(text)
        self.offset, self.blocks = offset, before


def is_tzx(data):
    return data[:8] == TZX_MAGIC


def _u16(b, i):
    return b[i] | b[i + 1] << 8


def _u24(b, i):
    return b[i] | b[i + 1] << 8 | b[i + 2] << 16


def _u32(b, i):
    return int.from_bytes(b[i:i + 4], 'little')


def _tzx_block(t, i, bid, blk):
    """the block of id bid whose body starts at i: fills blk, returns the offset after it (None: no block id)"""
    if bid == 0x10:
        pause, ln = _u16(t, i), _u16(t, i + 2)
        data = t[i + 4:i + 4 + ln]
        pilot_pulses = 8063 if data and data[0] < 128 else 3223
        blk.update(kind='standard', pause=pause, data=data, timing=dict(STD, pilot_pulses=pilot_pulses))
        return i + 4 + ln
    if bid == 0x11:
        p = [_u16(t, i + k) for k in range(0, 12, 2)]
        last, pause, ln = t[i + 12], _u16(t, i + 13), _u24(t, i + 15)
        blk.update(kind='turbo', pause=pause, data=t[i + 18:i + 18 + ln],
                   timing=dict(pilot=p[0], sync1=p[1], sync2=p[2], zero=p[3], one=p[4], pilot_pulses=p[5], last=last))
        return i + 18 + ln
    if bid == 0x12:
        blk.update(kind='pure tone', timing=dict(pulse=_u16(t, i), count=_u16(t, i + 2)))
        return i + 4
    if bid == 0x13:
        cnt = t[i]
        blk.update(kind='pulses', timing=dict(pulses=[_u16(t, i + 1 + 2 * k) for k in range(cnt)]))
        return i + 1 + 2 * cnt
    if bid == 0x14:
        zero, one, last, pause, ln = _u16(t, i), _u16(t, i + 2), t[i + 4], _u16(t, i + 5), _u24(t, i + 7)
        blk.update(kind='pure data', pause=pause, data=t[i + 10:i + 10 + ln], timing=dict(zero=zero, one=one, last=last))
        return i + 10 + ln
    if bid == 0x15:
        per, pause, last, ln = _u16(t, i), _u16(t, i + 2), t[i + 4], _u24(t, i + 5)
        blk.update(kind='direct recording', pause=pause, samples=t[i + 8:i + 8 + ln],
                   timing=dict(sample=per, last=last))
        return i + 8 + ln
    if bid in (0x16, 0x17, 0x18, 0x19):  # C64 ROM / turbo (old), CSW recording, generalized data: a 4-byte length
        kinds = {0x16: 'C64 ROM', 0x17: 'C64 turbo', 0x18: 'CSW recording', 0x19: 'generalized data'}
        ln = _u32(t, i)
        blk.update(kind=kinds[bid], length=ln)
        if bid in (0x18, 0x19) and ln >= 2:
            blk['pause'] = _u16(t, i + 4)
        return i + 4 + ln
    if bid == 0x20:
        blk.update(kind='pause', pause=_u16(t, i))
        return i + 2
    if bid == 0x21:
        ln = t[i]
        blk.update(kind='group start', text=t[i + 1:i + 1 + ln].decode('latin-1'))
        return i + 1 + ln
    if bid == 0x22:
        blk.update(kind='group end')
        return i
    if bid == 0x23:
        rel = _u16(t, i)
        blk.update(kind='jump', text=f'by {rel - 0x10000 if rel & 0x8000 else rel}')
        return i + 2
    if bid == 0x24:
        blk.update(kind='loop start', text=f'repeat {_u16(t, i)}')
        return i + 2
    if bid == 0x25:
        blk.update(kind='loop end')
        return i
    if bid == 0x26:
        cnt = _u16(t, i)
        blk.update(kind='call sequence', text=f'{cnt} calls')
        return i + 2 + 2 * cnt
    if bid == 0x27:
        blk.update(kind='return')
        return i
    if bid == 0x28:
        ln = _u16(t, i)
        blk.update(kind='select', text=f'{t[i + 2] if ln else 0} choices')
        return i + 2 + ln
    if bid == 0x2A:
        blk.update(kind='stop if 48K')
        return i + 4
    if bid == 0x2B:
        blk.update(kind='signal level', text=f'level {t[i + 4]}')
        return i + 4 + _u32(t, i)
    if bid == 0x30:
        ln = t[i]
        blk.update(kind='text', text=t[i + 1:i + 1 + ln].decode('latin-1'))
        return i + 1 + ln
    if bid == 0x31:
        ln = t[i + 1]
        blk.update(kind='message', text=t[i + 2:i + 2 + ln].decode('latin-1'))
        return i + 2 + ln
    if bid == 0x32:
        ln = _u16(t, i)
        body = t[i + 2:i + 2 + ln]
        cnt, j, items = body[0], 1, []
        for _ in range(cnt):
            tid, tl = body[j], body[j + 1]
            items.append((tid, body[j + 2:j + 2 + tl].decode('latin-1')))
            j += 2 + tl
        blk.update(kind='archive info', items=items)
        return i + 2 + ln
    if bid == 0x33:
        cnt = t[i]
        hw = [tuple(t[i + 1 + 3 * k:i + 4 + 3 * k]) for k in range(cnt)]
        blk.update(kind='hardware', text=' '.join(f'type {a} id {b} info {c}' for a, b, c in hw))
        return i + 1 + 3 * cnt
    if bid == 0x34:
        blk.update(kind='emulation info')
        return i + 8
    if bid == 0x35:
        ln = _u32(t, i + 16)
        blk.update(kind='custom info', text=t[i:i + 16].decode('latin-1').strip())
        return i + 20 + ln
    if bid == 0x40:
        blk.update(kind='snapshot', text=f'type {t[i]}')
        return i + 4 + _u24(t, i + 1)
    if bid == 0x5A:
        blk.update(kind='glue')
        return i + 9
    return None


def parse_tzx(t):
    """the blocks of a TZX, one dict each: index, id, offset, kind, size, and as the block has them data (a data
    block's bytes, flag and checksum included), pause (ms), timing (T-states), text, items (archive info). Raises
    TzxError at a byte that is no block id or a block past the file's end"""
    if not is_tzx(t):
        raise TzxError('not a TZX (no "ZXTape!" signature)', 0, [])
    i, n, before = 10, 0, []
    while i < len(t):
        bid, start = t[i], i
        blk = dict(index=n, id=bid, offset=start)
        try:
            end = _tzx_block(t, i + 1, bid, blk)
        except IndexError:
            end = len(t) + 1
        if end is None:
            raise TzxError(f'block id ${bid:02X} at offset {start} is no TZX block (a damaged file, or the length of '
                           f'the block before is wrong)', start, before)
        if end > len(t):
            raise TzxError(f'block {n} (id ${bid:02X}) at offset {start} runs past the file\'s end', start, before)
        blk['size'] = end - start
        i = end
        before.append(blk)
        yield blk
        n += 1


def tzx_seconds(blk):
    """a TZX block's signal time in seconds at 3.5 MHz (no pause)"""
    tm, data = blk.get('timing'), blk.get('data')
    if tm is None:
        return 0
    if blk['kind'] == 'pure tone':
        return tm['pulse'] * tm['count'] / 3.5e6
    if blk['kind'] == 'pulses':
        return sum(tm['pulses']) / 3.5e6
    if blk['kind'] == 'direct recording':
        return tm['sample'] * (8 * max(0, len(blk['samples']) - 1) + tm['last']) / 3.5e6
    tot = 0
    if 'pilot' in tm:
        tot += tm['pilot'] * tm['pilot_pulses'] + tm['sync1'] + tm['sync2']
    bits = []
    for k, b in enumerate(data):
        nb = tm['last'] if k == len(data) - 1 else 8
        bits += [(b >> (7 - q)) & 1 for q in range(nb)]
    ones = sum(bits)
    tot += ones * 2 * tm['one'] + (len(bits) - ones) * 2 * tm['zero']
    return tot / 3.5e6


def tzx_describe(data):
    """a data block's flag, checksum and, for a ROM header, its fields"""
    if not data:
        return ''
    x = 0
    for b in data:
        x ^= b
    ck = 'ok' if x == 0 else f'xor {x:02X}'
    flag = data[0]
    if flag == 0 and len(data) == 19:
        h = data[1:-1]
        name = h[1:11].decode('latin-1').rstrip()
        ln, p1, p2 = _u16(h, 11), _u16(h, 13), _u16(h, 15)
        kind = KINDS.get(h[0], f'type {h[0]}')
        extra = f' LINE {p1}' if h[0] == 0 and p1 < 32768 else (f' start {p1} (${p1:04X})' if h[0] == 3 else '')
        return f'flag 00, header {kind} "{name}" length {ln}{extra} p2 {p2}, checksum {ck}'
    return f'flag {flag:02X}, {len(data) - 2} data bytes, checksum {ck}'


def tzx_line(b):
    """one block's line of `list`"""
    s = tzx_seconds(b)
    line = f"{b['index']:2d} @{b['offset']:6d} id {b['id']:02X} {b['kind']:<12}"
    if 'timing' in b:
        line += ' ' + ' '.join(f'{k}={v}' for k, v in b['timing'].items() if k != 'pulses')
        if 'pulses' in b['timing']:
            line += ' pulses=' + ','.join(map(str, b['timing']['pulses']))
    if 'data' in b:
        line += f" len {len(b['data'])} | {tzx_describe(b['data'])}"
    if 'pause' in b:
        line += f" pause {b['pause']} ms"
    if s:
        line += f' | {s:.2f} s'
    if 'text' in b:
        line += f" '{b['text']}'"
    if 'items' in b:
        line += ' ' + '; '.join(f'{k}:{v}' for k, v in b['items'])
    return line


def tzx_list(t, out=print):
    """`list` of a TZX: a line a block, then the total with the pauses. Returns 0, or 1 when the walk stopped early
    (TzxError, said in the last line)"""
    total = 0
    try:
        for b in parse_tzx(t):
            total += tzx_seconds(b) + b.get('pause', 0) / 1000
            out(tzx_line(b))
    except TzxError as e:
        out(f'total {total:.1f} s with pauses ({total * 50:.0f} frames at 50 Hz) up to here')
        out(f'stopped: {e}')
        return 1
    out(f'total {total:.1f} s with pauses ({total * 50:.0f} frames at 50 Hz)')
    return 0


def tzx_block_data(t, index):
    """the data of TZX block index (flag and checksum included)"""
    for b in parse_tzx(t):
        if b['index'] == index:
            if 'data' not in b:
                raise SystemExit(f'block {index} is a {b["kind"]} block: no data')
            return b['data']
    raise SystemExit(f'no block {index}')


def main():
    if len(sys.argv) == 3 and sys.argv[1] == 'list':
        tap = open(sys.argv[2], 'rb').read()
        if is_tzx(tap):
            return tzx_list(tap)
        total = 0.0
        for index, (offset, flag, data, ok) in enumerate(raw_blocks(tap)):
            seconds = rom_seconds(flag, data, tap[offset + 2 + len(data) + 1] if ok else 0)
            total += seconds
            print(f'{index:3}  offset {offset:6}  {len(data):6} bytes  {seconds:6.1f} s  {describe(flag, data)}'
                  f'{"" if ok else "  BAD CHECKSUM"}')
        print(f'total {total:.1f} s at ROM speed ({round(total * 3500000 / 69888)} 48K frames), pauses not included')
        return 0
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    tap = open(sys.argv[1], 'rb').read()
    if is_tzx(tap):
        try:
            data = tzx_block_data(tap, int(sys.argv[2]))
        except TzxError as e:
            raise SystemExit(f'{sys.argv[1]}: {e}')
    else:
        data = list(blocks(tap))[int(sys.argv[2])]
    open(sys.argv[3], 'wb').write(data)
    return 0


if __name__ == '__main__':
    sys.exit(main())
