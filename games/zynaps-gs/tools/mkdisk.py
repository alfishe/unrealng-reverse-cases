#!/usr/bin/env python3
"""Write the TRD from its layout (src/media/trd.txt) and the built parts: the one run of sectors the boot and the
loader read, from track 1 sector 0, and the catalogue that cuts it into 9 files.

    python3 tools/mkdisk.py LAYOUT OUT.trd [--sjasmplus BIN] [--work DIR]

Layout lines (# starts a comment; numbers decimal, $hex or 0xhex):

    label TEXT                        the disk label (8 characters, sector 9 $F5)
    entry NAME TYPE START LENGTH SECTORS
                                      a catalogue entry; the entries take the run's sectors one after the other
    join NAME PATH ...                a named byte run: the files one after the other
    raw SRC [FROM [COUNT]]            bytes of SRC (a file or a join) as they are, zeros to the sector's end
    trush SRC FROM COUNT DEST         bytes of SRC packed into a Trush block (src/disk/trush.asm) that unpacks them
                                      to DEST: the block loads at DEST - $12C; COUNT - means to the end
    records LOADER                    the level data: the loader's record table (src/disk/loader.ann FxRecords,
                                      ModuleRecords), each record's bytes packed or raw as the disk's rule says

The disk's packing rule, checked against every record's flags and sector count: a record is a Trush block when
its in-place depack is safe (tools/trush.py margin above 0) and the block takes fewer sectors than the raw bytes.
A module is cut into 16384-byte parts after zeros to a whole sector (only level 9 needs them); a set of FX is its
FX one after the other. The sets were made in one buffer, each over the one before: a raw set's last sector ends
with what the sets before it left there (set 1: zeros; set 3: the bytes of set 2, FX 16, past set 3's length).
"""
import argparse
import os
import shutil
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import trush  # noqa: E402

TRACKS = 160
LOADER_ORG = 0x61A8
FX_RECORDS, MODULE_RECORDS, LEVEL_RECORDS = 0x63B6, 0x63CE, 0x64CB
IN_GAME_FX = 0x64F6
PACKED_AT, BANK = 0xBED4, 0xC000


def number(s):
    s = s.strip()
    if s[0] == '$':
        return int(s[1:], 16)
    return int(s, 0)


def sectors(n):
    return (n + 255) // 256


class Disk:
    def __init__(self, sjasmplus, work):
        self.run = bytearray()
        self.joins = {}
        self.sjasmplus, self.work = sjasmplus, work
        self.blocks = 0
        self.fxbuffer = bytearray()

    def source(self, name):
        if name in self.joins:
            return self.joins[name]
        return open(os.path.join(CASE, name), 'rb').read()

    def add(self, data):
        self.run += data + bytes(-len(data) % 256)

    def trush(self, data, dest):
        """data packed into a Trush block that unpacks it to dest: assembled by sjasmplus from src/disk/trush.asm
        and unpacked again by tools/trush.py to prove it"""
        base = dest - 0x12C
        stream = trush.pack(data)
        folder = os.path.join(self.work, 'blk%02d' % self.blocks)
        self.blocks += 1
        os.makedirs(folder, exist_ok=True)
        open(os.path.join(folder, 'stream.bin'), 'wb').write(stream)
        subprocess.run([self.sjasmplus, '--nologo', '--msg=war', '-DTRUSH_BASE=%d' % base,
                        '-DTRUSH_DEST_END=%d' % (dest + len(data) - 1), '-DTRUSH_LEN=%d' % len(data),
                        os.path.join(CASE, 'src', 'disk', 'trush.asm')], cwd=folder, check=True)
        block = open(os.path.join(folder, 'block.bin'), 'rb').read()
        h, back = trush.unpack(block, base)
        assert back == data and h['dest_start'] == dest, 'the Trush block does not unpack to its data'
        return block

    def records(self, loader):
        """the level data in the order of the loader's records"""
        L = self.source(loader)

        def byte(a):
            return L[a - LOADER_ORG]

        def word(a):
            return struct.unpack('<H', L[a - LOADER_ORG:a - LOADER_ORG + 2])[0]

        def lengths(a):
            out = []
            while word(a):
                out.append(0x10000 - word(a))
                a += 2
            return out

        fx = len(lengths(IN_GAME_FX))  # FX 1-10 are in the banks: the disk sets go on from FX 11
        first = {word(LEVEL_RECORDS + 2 * i): i + 1 for i in range(13)}
        a, kind, fxset, level, part = FX_RECORDS, 'fx', 0, None, 0
        while byte(a):
            count, flags, lw = byte(a), byte(a + 1), word(a + 4)
            if a == MODULE_RECORDS:
                kind = 'module'
            if kind == 'fx':
                fxset += 1
                names = []
                for n in lengths(lw):
                    fx += 1
                    names.append('build/res/sfx/fx%02d.bin' % fx)
                data = b''.join(self.source(n) for n in names)
                assert [len(self.source(n)) for n in names] == lengths(lw), 'FX set %d: lengths' % fxset
                what = 'FX set %d (FX %d-%d)' % (fxset, fx - len(names) + 1, fx)
                end = len(data) + -len(data) % 256
                tail = bytes(self.fxbuffer[len(data):end]).ljust(end - len(data), b'\0')
                self.fxbuffer[:len(data)] = data
            else:
                if a in first:
                    level, part = first[a], 0
                module = self.source('build/res/music/level%02d.bin' % level)
                padded = module + bytes(-len(module) % 256)
                data = padded[part * 16384:(part + 1) * 16384]
                assert 0x10000 - lw == min(16384, len(module) - part * 16384), 'level %d part %d: length' % (
                    level, part + 1)
                what = 'level %d part %d' % (level, part + 1)
                part += 1
                tail = bytes(-len(data) % 256)
            stream = trush.pack(data)
            low, _ = trush.margin(data, BANK + len(data) - 1, stream)
            packed = low > 0 and sectors(0x119 + len(stream)) < sectors(len(data))
            assert packed == bool(flags & 2), '%s: the rule says %s, the loader %s' % (
                what, 'packed' if packed else 'raw', 'packed' if flags & 2 else 'raw')
            data = self.trush(data, BANK) if packed else data + tail
            assert sectors(len(data)) == count, '%s: %d sectors, the loader reads %d' % (what, sectors(len(data)),
                                                                                          count)
            self.add(data)
            a += 6


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('layout')
    ap.add_argument('out')
    ap.add_argument('--sjasmplus', default=os.environ.get(
        'SJASMPLUS', '/Volumes/TB4-4Tb/Projects/emulators/github/sjasmplus/build/release/sjasmplus'))
    ap.add_argument('--work', default=os.path.join(CASE, 'build', 'trush'))
    a = ap.parse_args()
    shutil.rmtree(a.work, ignore_errors=True)
    disk = Disk(a.sjasmplus, a.work)
    label, entries = None, []
    for n, line in enumerate(open(a.layout, encoding='utf-8'), 1):
        w = line.split('#', 1)[0].split()
        if not w:
            continue
        where = '%s:%d' % (a.layout, n)
        if w[0] == 'label':
            label = w[1]
            assert len(label) == 8, where + ': the label is not 8 characters'
        elif w[0] == 'entry':
            entries.append((w[1], w[2], number(w[3]), number(w[4]), number(w[5])))
        elif w[0] == 'join':
            disk.joins[w[1]] = b''.join(disk.source(p) for p in w[2:])
        elif w[0] == 'raw':
            data = disk.source(w[1])
            frm = number(w[2]) if len(w) > 2 else 0
            data = data[frm:frm + number(w[3])] if len(w) > 3 else data[frm:]
            disk.add(data)
        elif w[0] == 'trush':
            data = disk.source(w[1])[number(w[2]):]
            if w[3] != '-':
                data = data[:number(w[3])]
            disk.add(disk.trush(data, number(w[4])))
        elif w[0] == 'records':
            disk.records(w[1])
        else:
            sys.exit(where + ': unknown line ' + w[0])
    run = disk.run
    total = sum(e[4] for e in entries)
    assert total * 256 == len(run), 'the entries hold %d sectors, the run is %d' % (total, len(run) // 256)
    trd = bytearray(TRACKS * 16 * 256)
    at = 16
    for i, (name, typ, start, length, count) in enumerate(entries):
        trd[i * 16:i * 16 + 16] = (name.encode('latin-1').ljust(8) + typ.encode('ascii') +
                                   struct.pack('<HHB', start, length, count) + bytes([at % 16, at // 16]))
        at += count
    trd[16 * 256:16 * 256 + len(run)] = run
    free = TRACKS * 16 - at
    trd[0x8E1:0x8E8] = bytes([at % 16, at // 16, 0x16, len(entries), free & 255, free >> 8, 0x10])
    trd[0x8F5:0x8FD] = label.encode('ascii')
    open(a.out, 'wb').write(trd)
    print('mkdisk: %s, %d files, %d sectors, %d Trush blocks, %d free' % (
        os.path.relpath(a.out, CASE), len(entries), len(run) // 256, disk.blocks, free))


if __name__ == '__main__':
    sys.exit(main())
