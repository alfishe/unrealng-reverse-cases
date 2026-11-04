#!/usr/bin/env python3
"""Finds Nether Earth's routines and data in the memory images of Advanced Nether Earth.

  ne_match.py --image work/images/fc-bank5.bin@4000:5 --image ...  [--out work/stage1/match.tsv] [--summary]

NE's side: its game image (games/nether-earth/work/mkgame/original.bin, 64 K, the loader's image), the entries of
its src/game/game.ann (each entry runs to the next one, the last to the image's end $FCE9) and its listing
build/game.lst (the instruction boundaries of the code). In a code entry every 16-bit operand that points into the
image ($4000-$FFFF: JP, CALL, LD rr,nn, LD (nn),A ...) is masked, so a routine moved to another address still
matches; in a word table (kind w) every word in that range is masked.

ANE's side: one or more images, each FILE@BASE[:LABEL] (a 16 K bank at its CPU base, or a 64 K view at 0000).

Per NE entry, in this order:
  same      the entry's bytes at the same address (unmasked, all of them)
  moved     all its bytes, unchanged, at another address (data, or code with no absolute operand)
  relocated all its bytes outside the masked operands at another address; the operands' shift is reported
  changed   the best placement found by 8-byte seeds, with the similarity (matching bytes / entry bytes, masked
            positions count as matching when both are address-like); below 50 % the entry is called absent
  absent    no placement
Short entries (under 6 bytes) match in many places: the hit nearest to the neighbouring entries' shift is taken.

The TSV has one row per entry: address, kind, name, size, status, ANE label:address, shift, similarity, hits.
"""

import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
NE = os.path.join(os.path.dirname(CASE), 'nether-earth')
ANNOTATION = re.compile(r'\$([0-9A-Fa-f]{4})\s+([cbwts])\b(?:\s+([A-Za-z_]\w*))?')
LISTING = re.compile(r'^\s*\d+\+?\s+([0-9A-F]{4}) ((?:[0-9A-F]{2} )+)\s*(\S.*)$')
LO, HI = 0x5B00, 0xFCE9
SEED = 8

# Opcodes whose last two bytes are a 16-bit operand (nn): unprefixed, ED-prefixed, DD/FD-prefixed
NN_PLAIN = {0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD} | {0xC2 + 8 * k for k in range(8)} | \
    {0xC4 + 8 * k for k in range(8)}
NN_ED = {0x43, 0x4B, 0x53, 0x5B, 0x63, 0x6B, 0x73, 0x7B}
NN_INDEX = {0x21, 0x22, 0x2A}


def address_like(value):
    return 0x4000 <= value <= 0xFFFF


def operand_offset(code):
    """The offset of the nn operand inside an instruction's bytes, or None"""
    if not code:
        return None
    op = code[0]
    if op in NN_PLAIN and len(code) == 3:
        return 1
    if op == 0xED and len(code) == 4 and code[1] in NN_ED:
        return 2
    if op in (0xDD, 0xFD) and len(code) == 4 and code[1] in NN_INDEX:
        return 2
    return None


def read_entries(ann):
    entries = []
    for line in open(ann):
        text = line.strip()
        m = ANNOTATION.match(text)
        if m:
            entries.append((int(m.group(1), 16), m.group(2), m.group(3) or f'L{m.group(1).upper()}'))
    entries.sort()
    out = []
    for i, (a, kind, name) in enumerate(entries):
        end = entries[i + 1][0] if i + 1 < len(entries) else HI
        out.append((a, end, kind, name))
    return out


def read_instructions(lst):
    """{address: bytes} of every instruction in the listing (data directives left out)"""
    out = {}
    for line in open(lst, errors='replace'):
        m = LISTING.match(line)
        if not m:
            continue
        text = m.group(3)
        if text.startswith(('DEF', 'INCBIN', 'DB ', 'DW ', 'DS ', 'BLOCK', 'INCLUDE', ';')):
            continue
        out[int(m.group(1), 16)] = bytes.fromhex(m.group(2).replace(' ', ''))
    return out


def entry_mask(image, start, end, kind, instructions):
    """The entry's bytes and a mask: True where the byte is an absolute operand (not compared exactly)"""
    data = image[start:end]
    mask = [False] * len(data)
    if kind == 'c':
        for a in range(start, end):
            code = instructions.get(a)
            off = operand_offset(code) if code else None
            if off is not None and a + off + 1 < end:
                value = code[off] | code[off + 1] << 8
                if address_like(value):
                    mask[a - start + off] = mask[a - start + off + 1] = True
    elif kind == 'w':
        for i in range(0, len(data) - 1, 2):
            if address_like(data[i] | data[i + 1] << 8):
                mask[i] = mask[i + 1] = True
    return data, mask


class Space:
    """The ANE images as one searchable byte string, each byte with its label and CPU address"""

    def __init__(self, specs):
        self.parts = []  # (offset in blob, base, label, length)
        blob = bytearray()
        for spec in specs:
            path, _, rest = spec.partition('@')
            base, _, label = rest.partition(':')
            data = open(path, 'rb').read()
            self.parts.append((len(blob), int(base, 16), label or os.path.basename(path), len(data)))
            blob += data
            blob += bytes(16)  # no match runs across two images
        self.blob = bytes(blob)
        self.seeds = collections.defaultdict(list)
        for i in range(len(self.blob) - SEED):
            chunk = self.blob[i:i + SEED]
            if len(set(chunk)) > 1:  # runs of one byte seed everything: left out
                self.seeds[chunk].append(i)

    def where(self, offset):
        for start, base, label, length in self.parts:
            if start <= offset < start + length:
                return label, base + offset - start
        return None, None

    def offset_of(self, label, address):
        for start, base, lab, length in self.parts:
            if lab == label and base <= address < base + length:
                return start + address - base
        return None

    def at_address(self, data, address):
        """The offsets of the images that hold data at the same CPU address"""
        out = []
        for start, base, label, length in self.parts:
            if base <= address and address + len(data) <= base + length:
                o = start + address - base
                if self.blob[o:o + len(data)] == data:
                    out.append(o)
        return out

    def find_exact(self, data, limit=64):
        hits, i = [], self.blob.find(data)
        while i >= 0 and len(hits) < limit:
            hits.append(i)
            i = self.blob.find(data, i + 1)
        return hits

    def find_masked(self, data, mask):
        """Offsets where every unmasked byte agrees (seeded by the longest unmasked run)"""
        best, run, start = (0, 0), 0, 0
        for i, m in enumerate(mask + [True]):
            if m:
                if run > best[1]:
                    best = (start, run)
                run = 0
            else:
                if run == 0:
                    start = i
                run += 1
        s, n = best
        if n < 3:
            return []
        out = []
        for i in self.find_exact(data[s:s + n], limit=4096):
            o = i - s
            if o < 0 or o + len(data) > len(self.blob):
                continue
            if all(m or self.blob[o + k] == b for k, (b, m) in enumerate(zip(data, mask))):
                out.append(o)
        return out

    def best_placement(self, data, mask):
        """(offset, similarity) of the placement most 8-byte seeds vote for"""
        votes = collections.Counter()
        for k in range(0, len(data) - SEED + 1):
            if any(mask[k:k + SEED]):
                continue
            for i in self.seeds.get(data[k:k + SEED], ())[:64]:
                votes[i - k] += 1
        best = (None, 0.0)
        for o, _ in votes.most_common(8):
            sim = self.similarity(data, mask, o)
            if sim > best[1]:
                best = (o, sim)
        return best

    def similarity(self, data, mask, o):
        """Matching bytes / entry bytes at offset o; a masked operand pair matches when ANE's word there is
        address-like too"""
        same, k = 0, 0
        while k < len(data):
            j = o + k
            if not 0 <= j < len(self.blob) - 1:
                k += 1
                continue
            if mask[k] and k + 1 < len(data) and mask[k + 1]:
                if address_like(self.blob[j] | self.blob[j + 1] << 8):
                    same += 2
                k += 2
                continue
            if self.blob[j] == data[k]:
                same += 1
            k += 1
        return same / max(1, len(data))


def operand_shift(space, image, start, data, mask, o, instructions, kind):
    """The shifts (ANE operand - NE operand) of the masked operands at a placement: {shift: count}"""
    shifts = collections.Counter()
    k = 0
    while k < len(data) - 1:
        if mask[k] and mask[k + 1]:
            ne = data[k] | data[k + 1] << 8
            ane = space.blob[o + k] | space.blob[o + k + 1] << 8
            shifts[(ane - ne) & 0xFFFF] += 1
            k += 2
        else:
            k += 1
    return shifts


def fmt_shift(shift):
    return '' if shift is None else ('+' if shift < 0x8000 else '-') + '%04X' % (shift if shift < 0x8000 else 0x10000 - shift)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--image', action='append', required=True, help='ANE image FILE@BASE[:LABEL] (hex base)')
    p.add_argument('--ne-image', default=os.path.join(NE, 'work', 'mkgame', 'original.bin'))
    p.add_argument('--ann', default=os.path.join(NE, 'src', 'game', 'game.ann'))
    p.add_argument('--lst', default=os.path.join(NE, 'build', 'game.lst'))
    p.add_argument('--out', help='the TSV')
    p.add_argument('--summary', action='store_true', help='counts per status and per NE module')
    args = p.parse_args()
    image = open(args.ne_image, 'rb').read()
    entries = read_entries(args.ann)
    instructions = read_instructions(args.lst)
    modules = module_of(args.ann)
    space = Space(args.image)
    rows, last_shift = [], {}
    for start, end, kind, name in entries:
        data, mask = entry_mask(image, start, end, kind, instructions)
        status, place, shift, sim, hits = 'absent', None, None, 0.0, 0
        exact = space.find_exact(data) if data else []
        same = space.at_address(data, start)
        if len(set(data)) <= 1 and len(data) > 4:
            # a run of one byte (a buffer, zeroes): a place says nothing
            status, sim = 'fill', 1.0
            hits = len(exact)
            place = same[0] if same else (exact[0] if exact else None)
        elif same:
            status, place, sim, hits = 'same', same[0], 1.0, len(exact)
        elif exact:
            place = nearest(space, exact, start, last_shift.get('shift'))
            status, sim, hits = 'moved', 1.0, len(exact)
        else:
            masked = space.find_masked(data, mask) if any(mask) else []
            if masked:
                place = nearest(space, masked, start, last_shift.get('shift'))
                status, sim, hits = 'relocated', 1.0, len(masked)
            elif len(data) >= SEED:
                o, sim = space.best_placement(data, mask)
                if o is not None and sim >= 0.5:
                    status, place = 'changed', o
        label, addr = space.where(place) if place is not None else (None, None)
        if place is not None:
            shifts = operand_shift(space, image, start, data, mask, place, instructions, kind)
            if shifts:
                shift = shifts.most_common(1)[0][0]
            if status in ('same', 'moved', 'relocated', 'changed') and len(data) >= 6:
                last_shift['shift'] = (addr - start) & 0xFFFF
        rows.append((start, kind, name, end - start, status, f'{label}:{addr:04X}' if label else '',
                     fmt_shift(shift), f'{sim:.2f}', hits, modules.get(start, '')))
    if args.out:
        with open(args.out, 'w') as f:
            f.write('ne_addr\tkind\tname\tsize\tstatus\tane\toperand_shift\tsimilarity\thits\tmodule\n')
            for r in rows:
                f.write('$%04X\t%s\t%s\t%d\t%s\t%s\t%s\t%s\t%d\t%s\n' % r)
    if args.summary or not args.out:
        summary(rows)


def nearest(space, offsets, start, shift):
    """Of several hits, the one whose shift from NE's address is closest to the neighbours' shift"""
    if len(offsets) == 1 or shift is None:
        same = [o for o in offsets if space.where(o)[1] == start]
        return same[0] if same else offsets[0]
    want = (start + shift) & 0xFFFF
    return min(offsets, key=lambda o: abs(space.where(o)[1] - want))


def module_of(ann):
    out, module = {}, ''
    for line in open(ann):
        text = line.strip()
        if text.startswith('@module'):
            module = text.split()[1]
        m = ANNOTATION.match(text)
        if m:
            out[int(m.group(1), 16)] = module
    return out


def summary(rows):
    by = collections.Counter(r[4] for r in rows)
    size = collections.Counter()
    for r in rows:
        size[r[4]] += r[3]
    print('status     entries  bytes')
    for k in ('same', 'moved', 'relocated', 'changed', 'fill', 'absent'):
        print(f'{k:10} {by[k]:7}  {size[k]:5}')
    print(f'{"total":10} {len(rows):7}  {sum(size.values()):5}')
    mods = collections.defaultdict(collections.Counter)
    for r in rows:
        mods[r[9]][r[4]] += 1
    print('\nmodule        same moved reloc chang  fill absent')
    for m, c in mods.items():
        print(f'{m:12} {c["same"]:5} {c["moved"]:5} {c["relocated"]:5} {c["changed"]:5} {c["fill"]:5} {c["absent"]:6}')


if __name__ == '__main__':
    sys.exit(main())
