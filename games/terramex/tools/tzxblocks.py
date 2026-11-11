#!/usr/bin/env python3
"""The blocks of a TZX file: list them with their timings, or write the data of one.

    python3 tzxblocks.py list FILE.tzx            # every block: id, timings, length, flag, checksum, header fields
    python3 tzxblocks.py FILE.tzx INDEX OUT.bin   # the data of block INDEX (flag and checksum included)
"""
import sys

KINDS = {0: 'Program', 1: 'Number array', 2: 'Character array', 3: 'Bytes'}
STD = dict(pilot=2168, sync1=667, sync2=735, zero=855, one=1710, last=8)


def u16(b, i):
    return b[i] | b[i + 1] << 8


def u24(b, i):
    return b[i] | b[i + 1] << 8 | b[i + 2] << 16


def parse(t):
    assert t[:8] == b'ZXTape!\x1a', 'not a TZX'
    i, n = 10, 0
    while i < len(t):
        bid = t[i]
        start = i
        i += 1
        blk = dict(index=n, id=bid, offset=start)
        if bid == 0x10:
            pause, ln = u16(t, i), u16(t, i + 2)
            data = t[i + 4:i + 4 + ln]
            pilot_pulses = 8063 if data and data[0] < 128 else 3223
            blk.update(kind='standard', pause=pause, data=data, timing=dict(STD, pilot_pulses=pilot_pulses))
            i += 4 + ln
        elif bid == 0x11:
            p = [u16(t, i + k) for k in range(0, 12, 2)]
            last, pause, ln = t[i + 12], u16(t, i + 13), u24(t, i + 15)
            data = t[i + 18:i + 18 + ln]
            blk.update(kind='turbo', pause=pause, data=data,
                       timing=dict(pilot=p[0], sync1=p[1], sync2=p[2], zero=p[3], one=p[4], pilot_pulses=p[5], last=last))
            i += 18 + ln
        elif bid == 0x12:
            blk.update(kind='pure tone', timing=dict(pulse=u16(t, i), count=u16(t, i + 2)))
            i += 4
        elif bid == 0x13:
            cnt = t[i]
            blk.update(kind='pulses', timing=dict(pulses=[u16(t, i + 1 + 2 * k) for k in range(cnt)]))
            i += 1 + 2 * cnt
        elif bid == 0x14:
            zero, one, last, pause, ln = u16(t, i), u16(t, i + 2), t[i + 4], u16(t, i + 5), u24(t, i + 7)
            data = t[i + 10:i + 10 + ln]
            blk.update(kind='pure data', pause=pause, data=data, timing=dict(zero=zero, one=one, last=last))
            i += 10 + ln
        elif bid == 0x20:
            blk.update(kind='pause', pause=u16(t, i))
            i += 2
        elif bid == 0x21:
            ln = t[i]
            blk.update(kind='group start', text=t[i + 1:i + 1 + ln].decode('latin-1'))
            i += 1 + ln
        elif bid == 0x22:
            blk.update(kind='group end')
        elif bid == 0x30:
            ln = t[i]
            blk.update(kind='text', text=t[i + 1:i + 1 + ln].decode('latin-1'))
            i += 1 + ln
        elif bid == 0x32:
            ln = u16(t, i)
            body = t[i + 2:i + 2 + ln]
            cnt, j, items = body[0], 1, []
            for _ in range(cnt):
                tid, tl = body[j], body[j + 1]
                items.append((tid, body[j + 2:j + 2 + tl].decode('latin-1')))
                j += 2 + tl
            blk.update(kind='archive info', items=items)
            i += 2 + ln
        elif bid == 0x2A:
            blk.update(kind='stop if 48K')
            i += 4
        elif bid == 0x33:
            cnt = t[i]
            hw = [tuple(t[i + 1 + 3 * k:i + 4 + 3 * k]) for k in range(cnt)]
            blk.update(kind='hardware', text=' '.join(f'type {a} id {b} info {c}' for a, b, c in hw))
            i += 1 + 3 * cnt
        elif bid == 0x35:
            ln = int.from_bytes(t[i + 16:i + 20], 'little')
            blk.update(kind='custom info', text=t[i:i + 16].decode('latin-1').strip())
            i += 20 + ln
        else:
            raise SystemExit(f'block id {bid:#x} at {start} not handled')
        blk['size'] = i - start
        yield blk
        n += 1


def seconds(blk):
    tm, data = blk.get('timing'), blk.get('data')
    if tm is None:
        return 0
    if blk['kind'] == 'pure tone':
        return tm['pulse'] * tm['count'] / 3.5e6
    if blk['kind'] == 'pulses':
        return sum(tm['pulses']) / 3.5e6
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


def describe(data):
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
        ln, p1, p2 = u16(h, 11), u16(h, 13), u16(h, 15)
        kind = KINDS.get(h[0], f'type {h[0]}')
        extra = f' LINE {p1}' if h[0] == 0 and p1 < 32768 else (f' start {p1} (${p1:04X})' if h[0] == 3 else '')
        return f'flag 00, header {kind} "{name}" length {ln}{extra} p2 {p2}, checksum {ck}'
    return f'flag {flag:02X}, {len(data) - 2} data bytes, checksum {ck}'


def main():
    if sys.argv[1] == 'list':
        t = open(sys.argv[2], 'rb').read()
        total = 0
        for b in parse(t):
            s = seconds(b)
            total += s + b.get('pause', 0) / 1000
            line = f"{b['index']:2d} @{b['offset']:6d} id {b['id']:02X} {b['kind']:<12}"
            if 'timing' in b:
                line += ' ' + ' '.join(f'{k}={v}' for k, v in b['timing'].items() if k != 'pulses')
                if 'pulses' in b['timing']:
                    line += ' pulses=' + ','.join(map(str, b['timing']['pulses']))
            if 'data' in b:
                line += f" len {len(b['data'])} | {describe(b['data'])}"
            if 'pause' in b:
                line += f" pause {b['pause']} ms"
            if s:
                line += f' | {s:.2f} s'
            if 'text' in b:
                line += f" '{b['text']}'"
            if 'items' in b:
                line += ' ' + '; '.join(f'{k}:{v}' for k, v in b['items'])
            print(line)
        print(f'total {total:.1f} s with pauses ({total * 50:.0f} frames at 50 Hz)')
    else:
        t = open(sys.argv[1], 'rb').read()
        idx = int(sys.argv[2])
        for b in parse(t):
            if b['index'] == idx:
                open(sys.argv[3], 'wb').write(b['data'])
                return
        raise SystemExit('no such block')


if __name__ == '__main__':
    main()
