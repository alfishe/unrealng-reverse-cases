#!/usr/bin/env python3
"""Carry REX 1's names to another build of the engine (REX 2, the DEMO): a seeding aid for writing its .ann, not a
generator of the case's sources (kit/mkgame.py writes those from the .ann).

The code of each build is read from its mkgame skool (the instructions mkgame found, with their addresses) and its
64 K image. Every named address of src/game/game.ann that is an instruction start (an entry or an inner label) gets a
signature: the bytes of up to 8 instructions from it, the 16-bit operands masked (they are addresses, different in
each build). A signature found at exactly one instruction start of the other build carries the name there. Then the
operands of the matched instructions pair REX 1's addresses with the other build's: a data label or variable of
REX 1 named in an operand carries its name to the address the other build names at the same place (the most frequent
pairing wins).

    python3 tools/name_transfer.py OTHER.skool OTHER.img [--out MAP.txt]

prints (or writes) one line a carried name: OTHER_ADDR REX1_ADDR KIND NAME HOW, then the entries of the other skool
no name reached.
"""
import argparse
import collections
import re

GAME_ANN = 'src/game/game.ann'
GAME_SKOOL = 'work/mkgame/game.skool'
GAME_IMG = 'work/mkgame/original.bin'


def skool_code(path):
    """[(address, instruction text, is entry start)] of the code lines of a skool, and the entries' kinds"""
    code, kinds = [], {}
    for line in open(path):
        m = re.match(r'([cbwts* ])\$([0-9A-F]{4}) (.*?)\s*(?:;.*)?$', line.rstrip('\n'))
        if not m:
            continue
        a = int(m.group(2), 16)
        if m.group(1) in 'cbwts':
            kinds[a] = m.group(1)
            kind = m.group(1)
        if kind == 'c':
            code.append((a, m.group(3).strip()))
    return code, kinds


def lengths(code, hi=0x10000):
    out = {}
    for (a, text), nxt in zip(code, code[1:] + [(hi, '')]):
        n = nxt[0] - a
        out[a] = (n if 0 < n <= 4 else None, text)
    return out


def masked(mem, a, n, text):
    raw = list(mem[a:a + n])
    # a 16-bit operand: an address or a number written $XXXX or as a label; the last two bytes of the instruction
    if re.search(r'(?<![+-])\$[0-9A-F]{4}\b|[,( ][A-Za-z_]\w*\)?$', text) and not re.match(r'(JR|DJNZ)\b', text) \
            and n >= 3 and not re.search(r'\(I[XY][+-]', text):
        raw[-2:] = [None, None]
    return tuple(raw)


def operand(mem, a, n, text):
    if n >= 3 and re.search(r'\$[0-9A-F]{4}\b', text) and not re.match(r'(JR|DJNZ)\b', text) \
            and not re.search(r'\(I[XY][+-]', text):
        return mem[a + n - 2] | mem[a + n - 1] << 8
    return None


def ann_names(path):
    names = {}
    for line in open(path):
        line = line.strip()
        m = re.match(r'(?:@var )?\$([0-9A-F]{4})(?: ([cbwts]))? ([A-Za-z]\w*)', line)
        if m:
            names.setdefault(int(m.group(1), 16), (m.group(2) or ('v' if line.startswith('@var') else 'i'),
                                                   m.group(3)))
    return names


def main():
    p = argparse.ArgumentParser()
    p.add_argument('skool')
    p.add_argument('image')
    p.add_argument('--out')
    args = p.parse_args()
    mem1 = open(GAME_IMG, 'rb').read()
    mem2 = open(args.image, 'rb').read()
    code1, _ = skool_code(GAME_SKOOL)
    code2, kinds2 = skool_code(args.skool)
    len1, len2 = lengths(code1), lengths(code2)
    order1, order2 = [a for a, _ in code1], [a for a, _ in code2]
    idx1 = {a: i for i, a in enumerate(order1)}
    names = ann_names(GAME_ANN)

    def sig(order, lens, mem, i, k):
        out = []
        for a in order[i:i + k]:
            n, text = lens[a]
            if n is None:
                break
            out.append(masked(mem, a, n, text))
        return tuple(out)

    found = {}  # other address -> (rex1 address, how)
    for k in (8, 5, 3):
        index = collections.defaultdict(list)
        for i, a in enumerate(order2):
            s = sig(order2, len2, mem2, i, k)
            if len(s) == k:
                index[s].append(a)
        for a1, (kind, name) in sorted(names.items()):
            if a1 not in idx1 or a1 in {v[0] for v in found.values()}:
                continue
            s = sig(order1, len1, mem1, idx1[a1], k)
            if len(s) < k:
                continue
            hits = [h for h in index.get(s, []) if h not in found]
            if len(hits) == 1:
                found[hits[0]] = (a1, 'sig%d' % k)
    # the entries left between two matched ones: REX 1's and the other's in the same gap, paired in order when their
    # opcode sequences are alike (difflib ratio >= 0.7): a routine changed a little between the builds
    import difflib
    _, kinds1 = skool_code(GAME_SKOOL)
    ent1 = [a for a in sorted(kinds1) if kinds1[a] == 'c' and a in names]
    ent2 = [a for a in sorted(kinds2) if kinds2[a] == 'c']
    back = {v[0]: k for k, v in found.items()}

    def ops(order, lens, mem, a, idx):
        out = []
        for x in order[idx[a]:idx[a] + 40]:
            n, text = lens[x]
            if n is None or (x != a and x in starts_of):
                break
            out.append(mem[x])
        return out
    idx2 = {a: i for i, a in enumerate(order2)}
    starts_of = set(ent1) | set(ent2)
    anchors = sorted((a1, a2) for a2, (a1, _) in found.items() if a1 in kinds1 and a2 in kinds2)
    for (p1, p2), (q1, q2) in zip([(0, 0)] + anchors, anchors + [(0x10000, 0x10000)]):
        g1 = [a for a in ent1 if p1 < a < q1 and a not in back]
        g2 = [a for a in ent2 if p2 < a < q2 and a not in found]
        for a1, a2 in zip(g1, g2):
            r = difflib.SequenceMatcher(None, ops(order1, len1, mem1, a1, idx1),
                                        ops(order2, len2, mem2, a2, idx2)).ratio()
            if r >= 0.7:
                found[a2] = (a1, 'gap %.2f' % r)
    # pair the operands of the matched stretches
    pairs = collections.defaultdict(collections.Counter)
    for a2, (a1, _) in found.items():
        i1, i2 = idx1[a1], order2.index(a2)
        for x1, x2 in zip(order1[i1:i1 + 8], order2[i2:i2 + 8]):
            n1, t1 = len1[x1]
            n2, t2 = len2[x2]
            if n1 is None or n2 is None or n1 != n2 or mem1[x1] != mem2[x2]:
                break
            o1, o2 = operand(mem1, x1, n1, t1), operand(mem2, x2, n2, t2)
            if o1 is not None and o2 is not None:
                pairs[o1][o2] += 1
    carried = {a2: (a1, names[a1][0], names[a1][1], how) for a2, (a1, how) in found.items()}
    taken = set(carried)
    for o1, counts in sorted(pairs.items()):
        if o1 in names and names[o1][0] not in 'c':
            o2, n = counts.most_common(1)[0]
            if o2 not in taken:
                carried[o2] = (o1, names[o1][0], names[o1][1], 'operand x%d' % n)
                taken.add(o2)
    lines = ['%04X %04X %s %s %s' % (a2, a1, kind, name, how) for a2, (a1, kind, name, how) in sorted(carried.items())]
    missing = [a for a, k in sorted(kinds2.items()) if a not in carried]
    lines.append('# entries of %s no name reached: %s' % (args.skool, ' '.join('%s%04X' % (kinds2[a], a)
                                                                                for a in missing)))
    text = '\n'.join(lines) + '\n'
    if args.out:
        open(args.out, 'w').write(text)
    else:
        print(text, end='')


if __name__ == '__main__':
    main()
