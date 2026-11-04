"""List the blocks of a TZX and write its data blocks as TAP (blocks 0x10 and 0x11)."""
import sys
d = open(sys.argv[1], 'rb').read()
assert d[:8] == b'ZXTape!\x1a', 'not a TZX'
i, n, tap = 10, 0, bytearray()
K = {0: 'Program', 1: 'Num array', 2: 'Char array', 3: 'Bytes'}
while i < len(d):
    t = d[i]; i += 1
    if t in (0x10, 0x11):
        if t == 0x10:
            pause = d[i] | d[i+1] << 8; ln = d[i+2] | d[i+3] << 8; data = d[i+4:i+4+ln]; i += 4 + ln; info = f'std pause {pause}'
        else:
            h = d[i:i+18]; ln = h[15] | h[16] << 8 | h[17] << 16; data = d[i+18:i+18+ln]; i += 18 + ln
            info = 'turbo pilot %d sync %d/%d zero %d one %d pilots %d' % (h[0]|h[1]<<8, h[2]|h[3]<<8, h[4]|h[5]<<8, h[6]|h[7]<<8, h[8]|h[9]<<8, h[10]|h[11]<<8)
        x = 0
        for b in data: x ^= b
        desc = ''
        if data[0] == 0 and len(data) == 19:
            nm = data[2:12].decode('latin1'); l = data[12] | data[13] << 8; p1 = data[14] | data[15] << 8; p2 = data[16] | data[17] << 8
            desc = f'header {K.get(data[1])} "{nm}" len {l} p1 {p1} p2 {p2}'
        else:
            desc = f'data flag {data[0]:02X} {len(data)-2} bytes'
        print(f'{n:2} {t:02X} {info}: {desc} xor {"ok" if x == 0 else "BAD"}')
        tap += bytes([len(data) & 255, len(data) >> 8]) + data
    elif t == 0x30:
        ln = d[i]; print(f'{n:2} 30 text: {d[i+1:i+1+ln].decode("latin1")}'); i += 1 + ln
    elif t == 0x32:
        ln = d[i] | d[i+1] << 8; body = d[i+2:i+2+ln]; i += 2 + ln
        k, j, out = body[0], 1, []
        for _ in range(k):
            tid, l = body[j], body[j+1]; out.append(f'{tid:02X}={body[j+2:j+2+l].decode("latin1")}'); j += 2 + l
        print(f'{n:2} 32 archive info: ' + '; '.join(out))
    elif t == 0x20:
        print(f'{n:2} 20 pause {d[i] | d[i+1] << 8}'); i += 2
    elif t == 0x21:
        ln = d[i]; print(f'{n:2} 21 group start {d[i+1:i+1+ln].decode("latin1")}'); i += 1 + ln
    elif t == 0x22:
        print(f'{n:2} 22 group end')
    else:
        raise SystemExit(f'block type {t:02X} at {i-1}: not handled')
    n += 1
if len(sys.argv) > 2:
    open(sys.argv[2], 'wb').write(tap)
