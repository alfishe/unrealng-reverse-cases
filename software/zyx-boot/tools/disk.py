#!/usr/bin/env python3
"""TR-DOS disk images (SCL, TRD, Hobeta) for the ZYX boot case: list, extract, list BASIC, build an SCL.

    disk.py list IMAGE                     the catalogue: name, type, start, length, sectors
    disk.py extract IMAGE OUTDIR           each file's sector-padded body as NN_NAME.T (+ .json with its header)
    disk.py basic FILE [LENGTH]            a BASIC program as text (numbers shown as typed; the hidden 5-byte
                                           forms that differ from the text are marked)
    disk.py scl OUT.scl NAME:T:START:LEN:FILE ...   an SCL of these files (bodies padded to whole sectors)
"""
import json
import os
import struct
import sys

TOKENS = dict(zip(range(0xA5, 0x100), (
    'RND|INKEY$|PI|FN|POINT|SCREEN$|ATTR|AT|TAB|VAL$|CODE|VAL|LEN|SIN|COS|TAN|ASN|ACS|ATN|LN|EXP|INT|SQR|'
    'SGN|ABS|PEEK|IN|USR|STR$|CHR$|NOT|BIN|OR|AND|<=|>=|<>|LINE|THEN|TO|STEP|DEF FN|CAT|FORMAT|MOVE|ERASE|OPEN #|CL'
    'OSE #|MERGE|VERIFY|BEEP|CIRCLE|INK|PAPER|FLASH|BRIGHT|INVERSE|OVER|OUT|LPRINT|LLIST|STOP|READ|DATA|RESTORE|NEW|BORDER|CONTINUE|DIM|REM|FOR|GO TO|GO SUB|INPUT|LOAD|LIST|LET|PAUSE|NEXT|POKE|PRINT|PLOT|RUN|SAVE|RANDOMIZE|IF|CLS|DRAW|CLEAR|RETURN|COPY').split('|')))


def read(path):
    d = open(path, 'rb').read()
    if d[:8] == b'SINCLAIR':
        n = d[8]
        files, off = [], 9 + 14 * n
        for i in range(n):
            h = d[9 + 14 * i: 23 + 14 * i]
            secs = h[13]
            files.append(entry(i, h, d[off: off + 256 * secs]))
            off += 256 * secs
        return files, d[off:]
    if path.lower().endswith('.trd') or len(d) in (655360, 640 * 1024):
        files = []
        for i in range(128):
            h = d[16 * i: 16 * i + 16]
            if h[0] == 0:
                break
            secs, sec, trk = h[13], h[14], h[15]
            off = (trk * 16 + sec) * 256
            files.append(entry(i, h, d[off: off + 256 * secs], dict(track=trk, sector=sec, deleted=h[0] == 1)))
        return files, b''
    # Hobeta: a 17-byte header (13 bytes of the catalogue entry, sectors as a word), the checksum word
    h = d[:17]
    f = entry(0, h[:13] + bytes([h[14]]), d[17:])
    f['hobeta_checksum'] = struct.unpack('<H', h[15:17])[0]
    f['hobeta_checksum_ok'] = f['hobeta_checksum'] == (sum(h[:15]) * 257 + sum(range(15))) & 0xFFFF
    return [f], b''


def entry(i, h, body, extra=None):
    start, length = struct.unpack('<HH', h[9:13])
    e = dict(index=i, name=h[:8].decode('latin-1'), type=chr(h[8]), start=start, length=length, sectors=h[13],
             body=body)
    e.update(extra or {})
    return e


def basic(data, length=None):
    data = data[:length] if length else data
    out, i = [], 0
    while i + 4 <= len(data):
        num = data[i] * 256 + data[i + 1]
        ln = data[i + 2] | data[i + 3] << 8
        if num >= 16384:
            break
        body = data[i + 4: i + 4 + ln]
        text, j = [], 0
        while j < len(body):
            c = body[j]
            if c == 0x0E:
                v = body[j + 1: j + 6]
                if v[0] == 0 and v[1] in (0, 0xFF):
                    val = (v[2] | v[3] << 8) - (65536 if v[1] else 0)
                else:
                    m = (v[1] | 0x80) << 24 | v[2] << 16 | v[3] << 8 | v[4]
                    val = m / (1 << 32) * 2 ** (v[0] - 128) * (-1 if v[1] & 0x80 else 1)
                    val = int(val) if val == int(val) else val
                shown = ''.join(text).rsplit(' ', 1)[-1]
                text.append(f'{{{val}}}' if str(val) not in ''.join(text)[-12:] else '')
                j += 6
                continue
            if c == 0x0D:
                break
            if c >= 0xA5:
                text.append(' ' + TOKENS[c] + ' ')
            elif 32 <= c < 127:
                text.append(chr(c))
            else:
                text.append(f'\\x{c:02X}')
            j += 1
        out.append(f'{num:5} ' + ''.join(text).replace('  ', ' ').strip())
        i += 4 + ln
    return out, i


def main():
    cmd = sys.argv[1]
    if cmd == 'list':
        files, tail = read(sys.argv[2])
        print(f'{len(files)} files')
        for f in files:
            x = f" T{f['track']}:S{f['sector']}" if 'track' in f else ''
            print(f"{f['index']:3} {f['name']!r:12} {f['type']} start {f['start']:5} (${f['start']:04X}) "
                  f"len {f['length']:5} (${f['length']:04X}) sectors {f['sectors']:3}{x}")
        if tail:
            print('tail', tail.hex())
    elif cmd == 'extract':
        files, _ = read(sys.argv[2])
        out = sys.argv[3]
        os.makedirs(out, exist_ok=True)
        for f in files:
            base = f"{f['index']:02}_{f['name'].rstrip().replace('/', '_')}.{f['type']}"
            open(os.path.join(out, base), 'wb').write(f['body'])
            json.dump({k: v for k, v in f.items() if k != 'body'}, open(os.path.join(out, base + '.json'), 'w'))
    elif cmd == 'basic':
        data = open(sys.argv[2], 'rb').read()
        lines, end = basic(data, int(sys.argv[3], 0) if len(sys.argv) > 3 else None)
        print('\n'.join(lines))
        print(f'; program ends at +{end}')
    elif cmd == 'scl':
        out, specs = sys.argv[2], sys.argv[3:]
        head, bodies = [], []
        for s in specs:
            name, typ, start, length, path = s.split(':', 4)
            body = open(path, 'rb').read()
            body += bytes(-len(body) % 256)
            head.append(name.ljust(8)[:8].encode('latin-1') + typ.encode() +
                        struct.pack('<HHB', int(start, 0), int(length, 0), len(body) // 256))
            bodies.append(body)
        d = b'SINCLAIR' + bytes([len(specs)]) + b''.join(head) + b''.join(bodies)
        d += struct.pack('<I', sum(d) & 0xFFFFFFFF)
        open(out, 'wb').write(d)


if __name__ == '__main__':
    main()
