#!/usr/bin/env python3
"""The General Sound media of Zynaps GS, cut from the disk the way the level loader uploads them.

  gs_media.py BLOB.bin UNPACKED_DIR OUT_DIR [--check STREAMS_DIR]

BLOB.bin      the TRD from track 1 sector 0 (TRD offset $1000): blob sector n = TRD sector n + 16
UNPACKED_DIR  trush.py --scan output (blkNN-sSSSS-ADDR.bin)
OUT_DIR       gets fx/fx-start.raw (the game-start jingle), fx/fx01..fx10.raw (the in-game set, from the boot banks),
              fx/fx11..fx21.raw (the disk set of the effects-only mode), mod/levelNN.mod (13 Protracker modules),
              and media.json (sizes, SHA-1, where each came from)
--check       compare with the streams cut from a live port history (work/tmp/streams.py): FX by bytes, modules
              by bytes

Where it all is (the loader is the bank 1 copy at $C44A, run at $61A8; its tables are read from blk04, which
carries the driver file that lands in bank 1):
  $64F2  FX lengths (negated words, 0 ends a list): the start jingle; $64F6 the in-game set; $650C.. the disk set
  $63B6  6-byte records: sectors, flags (bit1 Trush-packed, bit7 the last record of a set), 2 bytes the game fills
         with the track / sector at start (sequential from blob sector 321), the part length (negated) or a pointer
         to an FX length list
  $64CB  13 words: the first record of each level's module (level 1 .. 13; 13 = the title)
The in-game FX and the jingle come from the boot banks: bank 1 $D3CB (blk01), then $FAA5 on through bank 3
(64 raw sectors from blob 56), bank 4 (blk02) and bank 6 (blk03) in that order, as the loader pages $11 $13 $14 $16
(and 7 bytes of bank 7, zeros, at the end of FX 10).
"""
import argparse
import glob
import hashlib
import json
import os
import struct

LOADER_FILE_OFF = 0x64B3 - 0x61A8 + 0x44A   # the loader inside blk04 (driver file at $64B3, loader at +$44A)
LOADER_LEN = 0x419
FIRST_SECTOR = 321


def word(m, a):
    return m[a] | m[a + 1] << 8


def lengths(m, a):
    out = []
    while word(m, a):
        out.append(0x10000 - word(m, a))
        a += 2
    return out


def blocks(unpacked):
    by_sector = {}
    for f in glob.glob(os.path.join(unpacked, 'blk*.bin')):
        n, s, addr = os.path.basename(f)[:-4].split('-')
        by_sector[int(s[1:])] = (int(addr, 16), open(f, 'rb').read())
    return by_sector


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('blob')
    ap.add_argument('unpacked')
    ap.add_argument('out')
    ap.add_argument('--check')
    a = ap.parse_args()
    blob = open(a.blob, 'rb').read()
    blk = blocks(a.unpacked)
    loader = blk[227][1][LOADER_FILE_OFF:LOADER_FILE_OFF + LOADER_LEN]
    m = bytearray(0x10000)
    m[0x61A8:0x61A8 + LOADER_LEN] = loader
    os.makedirs(os.path.join(a.out, 'fx'), exist_ok=True)
    os.makedirs(os.path.join(a.out, 'mod'), exist_ok=True)
    info = {'fx': [], 'mod': []}

    def save(kind, name, data, source):
        path = os.path.join(a.out, kind, name)
        open(path, 'wb').write(data)
        info[kind].append({'file': f'{kind}/{name}', 'bytes': len(data), 'sha1': hashlib.sha1(data).hexdigest(),
                           'source': source})

    # the boot banks: bank 1 $D3CB.. (blk01), bank 3 (raw), bank 4 (blk02), bank 6 (blk03)
    bank1 = bytearray(0x4000)
    bank1[0xD3CB - 0xC000:] = blk[16][1]
    banks = [bytes(bank1), blob[56 * 256:120 * 256], blk[120][1], blk[178][1]]
    start = lengths(m, 0x64F2)
    pos = 0xD3CB - 0xC000
    save('fx', 'fx-start.raw', banks[0][pos:pos + start[0]], 'bank 1 $D3CB (blk01)')
    # the loader runs on from $FFFF into the next page; FX 10 is 7 bytes longer than what is left of bank 6, so its
    # tail is read from page $17 (bank 7) $C000: zeros there when it runs (the live stream ends in 7 zero bytes)
    flat = banks[0] + banks[1] + banks[2] + banks[3] + bytes(16)
    pos = 0xFAA5 - 0xC000
    names = ['bank 1', 'bank 3', 'bank 4', 'bank 6', 'bank 7']
    for i, n in enumerate(lengths(m, 0x64F6)):
        save('fx', f'fx{i + 1:02d}.raw', flat[pos:pos + n],
             f'{names[pos // 0x4000]} ${0xC000 + pos % 0x4000:04X}')
        pos += n

    # the records, in disk order
    sector = FIRST_SECTOR
    records = []
    for r in range(0x63B6, 0x64CA, 6):
        secs, flags = m[r], m[r + 1]
        raw = blob[sector * 256:(sector + secs) * 256]
        data = blk[sector][1] if flags & 2 else raw
        records.append((r, sector, secs, flags, word(m, r + 4), data))
        sector += secs
    assert sector == 2174, sector
    fxn = 11
    i = 0
    while i < 4:   # the disk FX set: the first four records point at length lists
        r, s, secs, flags, ptr, data = records[i]
        pos = 0
        for n in lengths(m, ptr):
            save('fx', f'fx{fxn:02d}.raw', data[pos:pos + n], f'blob sector {s}' + (' (Trush)' if flags & 2 else ''))
            pos += n
            fxn += 1
        i += 1
    level_of = {word(m, 0x64CB + 2 * k): k + 1 for k in range(13)}
    while i < len(records):
        r = records[i][0]
        level = level_of[r]
        parts, srcs = bytearray(), []
        while True:
            r, s, secs, flags, ln, data = records[i]
            ln = 0x10000 - ln
            parts += data[:ln]
            srcs.append(f'{s}' + ('T' if flags & 2 else ''))
            i += 1
            if flags & 0x80:
                break
        save('mod', f'level{level:02d}.mod', bytes(parts), 'blob sectors ' + ' '.join(srcs))
        info['mod'][-1].update(level=level, title=bytes(parts[:20]).rstrip(b'\0').decode('latin-1'),
                               volume=m[0x64E5 + level - 1])
    json.dump(info, open(os.path.join(a.out, 'media.json'), 'w'), indent=1)
    for k in ('fx', 'mod'):
        for e in info[k]:
            print(f"{e['file']:18s} {e['bytes']:6d} {e['sha1'][:12]} {e.get('title', '')!s:22s} {e['source']}")
    if a.check:
        print('# check against the live streams')
        streams = {open(f, 'rb').read(): os.path.basename(f) for f in glob.glob(os.path.join(a.check, '*.bin'))}
        for k in ('fx', 'mod'):
            for e in info[k]:
                d = open(os.path.join(a.out, e['file']), 'rb').read()
                print(f"{e['file']:18s} {streams.get(d, '-')}")


if __name__ == '__main__':
    main()
