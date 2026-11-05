#!/usr/bin/env python3
"""Write the TRD from a layout (src/media/trd.txt): tools/mkscl.py's file lines, plus the disk's own parts.

    python3 tools/mktrd.py LAYOUT OUT.trd

On top of mkscl.py's lines (file / at / zero):

    label PATH                       the disk label: a one-line text file, 8 ASCII characters (sector 9 $F5)
    sector9 PATH                     the bytes of sector 9 before the disk fields ($00-$E0)
    free SECTOR PATH [FROM [COUNT]]  bytes in the free area, at logical sector SECTOR (track x 16 + sector)
    entry INDEX NAME TYPE START LENGTH SECTORS FIRST
                                     a leftover catalogue entry at or past the end mark (no file of the layout; at the
                                     mark its name must start with $00, the mark itself); NAME may hold {XX} bytes, FIRST is its logical first sector

A TRD here: 160 tracks of 16 sectors (80 cylinders, two sides). Track 0: the catalogue (sectors 1-8, 16 bytes a
file: name, type, start, length, sectors, first sector, first track), sector 9: the disk's fields at $E1-$FF (the
first free sector and track, type $16 = 80 tracks two sides, the file count, the free sector count, $10 = TR-DOS,
10 spaces ($EA-$F3; this disk's formatter wrote 10), the deleted count, the label), sectors 10-16 empty. The files lie one after the other from track 1
sector 0 (logical sector 16); every byte past them is zero unless a free line fills it.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mkscl  # noqa: E402

TRACKS = 160


def main():
    layout, out = sys.argv[1], sys.argv[2]
    disk = {'label': None, 'sector9': b'', 'free': [], 'entries': []}

    def extra(w, where):
        if w[0] == 'label':
            disk['label'] = open(mkscl.path(w[1]), encoding='utf-8').read().rstrip('\n')
            if len(disk['label']) != 8:
                sys.exit('%s: the label is not 8 characters' % where)
        elif w[0] == 'sector9':
            disk['sector9'] = open(mkscl.path(w[1]), 'rb').read()
        elif w[0] == 'free':
            data = open(mkscl.path(w[2]), 'rb').read()
            if len(w) > 3:
                frm = mkscl.number(w[3])
                data = data[frm:frm + mkscl.number(w[4])] if len(w) > 4 else data[frm:]
            disk['free'].append((mkscl.number(w[1]), data, where))
        elif w[0] == 'entry':
            name = re.sub(r'\{([0-9A-F]{2})\}', lambda m: chr(int(m.group(1), 16)), w[2])
            e = (name.encode('latin-1').ljust(8) + w[3].encode('ascii') + mkscl.number(w[4]).to_bytes(2, 'little') +
                 mkscl.number(w[5]).to_bytes(2, 'little') + bytes([mkscl.number(w[6])]))
            first = mkscl.number(w[7])
            disk['entries'].append((mkscl.number(w[1]), e + bytes([first % 16, first // 16]), where))
        else:
            return False
        return True

    files = mkscl.read_layout(layout, extra)
    trd = bytearray(TRACKS * 16 * 256)
    at = 16
    for k, (name, typ, start, length, sectors, data) in enumerate(files):
        e = mkscl.entry(name, typ, start, length, sectors) + bytes([at % 16, at // 16])
        trd[k * 16:k * 16 + 16] = e
        trd[at * 256:at * 256 + len(data)] = data
        at += sectors
    first_free = at
    for index, e, where in disk['entries']:
        if index < len(files) or (index == len(files) and e[0] != 0):
            sys.exit('%s: entry %d is a file\'s, or would hide the end mark' % (where, index))
        trd[index * 16:index * 16 + 16] = e
    for sector, data, where in disk['free']:
        if sector < first_free:
            sys.exit('%s: sector %d is a file\'s' % (where, sector))
        trd[sector * 256:sector * 256 + len(data)] = data
    s9 = bytearray(256)
    s9[:len(disk['sector9'])] = disk['sector9']
    s9[0xE1] = first_free % 16
    s9[0xE2] = first_free // 16
    s9[0xE3] = 0x16
    s9[0xE4] = len(files)
    s9[0xE5:0xE7] = (TRACKS * 16 - first_free).to_bytes(2, 'little')
    s9[0xE7] = 0x10
    s9[0xEA:0xF4] = b' ' * 10
    s9[0xF5:0xFD] = disk['label'].encode('ascii')
    trd[0x800:0x900] = s9
    open(out, 'wb').write(trd)


if __name__ == '__main__':
    main()
