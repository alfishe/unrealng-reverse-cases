#!/usr/bin/env python3
"""Carry stage 1's names over to another stage: find the routines and data of stage 1 that recur in a stage image
and print the .ann lines for them.

    python3 tools/stage_names.py work/mkgame/stage2.bin                 # .ann lines on stdout, the report on stderr
    python3 tools/stage_names.py work/mkgame/stage2.bin --out work/stage2/stage2/names.ann

Each stage block holds the same engine assembled at other addresses (docs/02-architecture.md 2.1). A routine of
stage 1 (a `c` entry of src/stage1/stage1.ann, up to the next entry) is matched by its normalized instruction
sequence: the same instructions, opcodes and lengths, every 8-bit operand and relative jump equal, and every 16-bit
operand either

- equal (a resident routine, a constant, a stage variable at the same address),
- shifted by the routine's own shift (an address inside the routine: a self-modified operand, a jump to itself), or
- the address of something stage 1 names (an entry, an inner label or an @equ), mapped to the target's operand: the
  pairs are collected over all matches and must agree (one stage-1 label, one target address).

The search runs over the target's stage range $6C3F-$F03E with the 16-bit operands as wildcards; a routine found in
several places is placed by the mapping (a call from a matched routine says where it is) or by the order of its
matched neighbours, else it is left out as ambiguous. Then every operand pair that points at a stage-1 data entry or
inner label gives that entry's address in the target (data entries are not compared byte for byte: their shape and
size are to be checked).

Output: for each matched routine its entry line (`$XXXX c Name ; title`), the description "As in stage 1 at $YYYY,
the same code." and its inner labels at the same offsets; the data entries found through the operands; the @equ
lines of stage 1 with the target's address where it differs; and on stderr the count and the list of stage-1
routines that did not match (with the longest matching prefix where a call says where the routine should be).
"""
import argparse
import os
import re
import sys

from z80dis import z80

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import mkgame  # noqa: E402  (the reference .ann parser, kit/mkgame.py)

LO, HI = 0x6C3F, 0xF03F
WORD_TYPES = {'IMM', 'ADDR', 'ADDR_DEREF'}


def decode(mem, pc):
    """(length, positions of the 16-bit operand's two bytes or None) of the instruction at pc"""
    d = z80.decode(bytes(mem[pc:pc + 4]) + bytes(4), pc)
    n = max(1, d.len)
    word = None
    for typ, val in d.operands:
        t = typ.name if hasattr(typ, 'name') else str(typ)
        if t in WORD_TYPES and isinstance(val, int):
            if d.op.name in ('JR', 'DJNZ'):
                continue
            if t == 'IMM' and n < 3:
                continue
            if n >= 3 and (mem[pc + n - 2] | mem[pc + n - 1] << 8) == val & 0xFFFF:
                word = n - 2
    return n, word


def instructions(mem, lo, hi):
    out, pc = [], lo
    while pc < hi:
        n, w = decode(mem, pc)
        out.append((pc, n, w))
        pc += n
    return out


def load_image(path):
    """a 64 K view: tools/image.py's (64 K) as it is, a bare block (mkgame's assembled stageN.bin) put at LO"""
    d = open(path, 'rb').read()
    if len(d) == 0x10000:
        return d
    if len(d) != HI - LO:
        raise SystemExit('%s: %d bytes, neither a 64 K image nor a block of %d' % (path, len(d), HI - LO))
    return bytes(LO) + d + bytes(0x10000 - HI)


class Stage1:
    def __init__(self, ann_path, image_path):
        mkgame.LO, mkgame.HI = LO, HI  # the stage-1 block: its @equ lie outside it
        self.ann = mkgame.Annotations(ann_path)
        self.mem = load_image(image_path)
        self.entries = sorted(a for a in self.ann.entries if LO <= a < HI)
        self.names = {}
        for a, (kind, name, _, _) in self.ann.entries.items():
            if name:
                self.names[a] = name
        for a, (name, _) in self.ann.inline.items():
            if name:
                self.names.setdefault(a, name)
        self.equ = {a: v for a, v in self.ann.equ.items()}

    def end_of(self, a):
        i = self.entries.index(a)
        return self.entries[i + 1] if i + 1 < len(self.entries) else HI

    def is_named(self, v):
        if v in self.names:
            return True
        for a, (name, size, _) in self.equ.items():
            if a <= v < a + (size or 1):
                return True
        return LO <= v < HI


def pattern(mem, ins, inline_after):
    """the regex of a routine's bytes with the 16-bit operands as wildcards, and the operand positions"""
    parts, words = [], []
    base = ins[0][0]
    for pc, n, w in ins:
        for k in range(n):
            if w is not None and k in (w, w + 1):
                if k == w:
                    v = mem[pc + w] | mem[pc + w + 1] << 8
                    words.append((pc - base + w, v, pc))
                    parts.append(b'(?s:..)')
            else:
                parts.append(re.escape(bytes([mem[pc + k]])))
    return re.compile(b''.join(parts), re.S), words


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('image', help='the target stage image (64 K, work/mkgame/stageN.bin)')
    ap.add_argument('--ann', default=os.path.join(CASE, 'src', 'stage1', 'stage1.ann'))
    ap.add_argument('--stage1', default=os.path.join(CASE, 'work', 'mkgame', 'stage1.bin'))
    ap.add_argument('--out', help='write the .ann lines here instead of stdout')
    ap.add_argument('--min', type=int, default=4, help='the fewest bytes a routine needs to be searched (4)')
    a = ap.parse_args()
    s1 = Stage1(a.ann, a.stage1)
    tgt = load_image(a.image)
    region = tgt[LO:HI]

    code = [e for e in s1.entries if s1.ann.entries[e][0] == 'c' and s1.ann.entries[e][1]]
    cand, info = {}, {}
    for e in code:
        end = s1.end_of(e)
        ins = instructions(s1.mem, e, end)
        if sum(n for _, n, _ in ins) != end - e:
            ins = ins[:-1]
        size = sum(n for _, n, _ in ins)
        rx, words = pattern(s1.mem, ins, None)
        info[e] = (size, ins, words, rx)
        found = []
        if size < a.min:
            cand[e] = None
            continue
        for m in rx.finditer(region):
            t = LO + m.start()
            shift = t - e
            ok, pairs = True, []
            for off, v, _ in words:
                tv = tgt[t + off] | tgt[t + off + 1] << 8
                if tv == v or (e <= v < end and tv == v + shift):
                    if tv != v:
                        pairs.append((v, tv))
                    continue
                if s1.is_named(v) or LO <= v < HI or 0xFE01 <= v <= 0xFEFD:
                    pairs.append((v, tv))
                    continue
                ok = False
                break
            if ok:
                found.append((t, pairs))
        cand[e] = found

    def check_at(e, t):
        size, ins, words, rx = info[e]
        if not (LO <= t and t + size <= HI) or not rx.fullmatch(tgt[t:t + size]):
            return None
        pairs = []
        for off, v, _ in words:
            tv = tgt[t + off] | tgt[t + off + 1] << 8
            if tv == v or (e <= v < e + size and tv == v + t - e):
                if tv != v:
                    pairs.append((v, tv))
            elif s1.is_named(v) or 0xFE01 <= v <= 0xFEFD:
                pairs.append((v, tv))
            else:
                return None
        return (t, pairs)

    # place: unique matches first, then the ambiguous ones by the mapping and the order of their neighbours
    placed, mapping = {}, {}

    def add_pairs(pairs):
        for v, tv in pairs:
            mapping.setdefault(v, {}).setdefault(tv, 0)
            mapping[v][tv] += 1

    for e, f in cand.items():
        if f and len(f) == 1:
            placed[e] = f[0][0]
            add_pairs(f[0][1])
    changed = True
    while changed:
        changed = False
        for e, f in cand.items():
            if e in placed:
                continue
            want = mapping.get(e)
            if f is None or not f:
                if want:
                    pick = check_at(e, max(want, key=want.get))
                    if pick:
                        placed[e] = pick[0]
                        add_pairs(pick[1])
                        changed = True
                continue
            if len(f) < 2:
                continue
            pick = None
            if want:
                best = max(want, key=want.get)
                pick = next((x for x in f if x[0] == best), None)
            if pick is None:
                lo_n = max((placed[x] for x in placed if x < e), default=LO)
                hi_n = min((placed[x] for x in placed if x > e), default=HI)
                inside = [x for x in f if lo_n < x[0] < hi_n]
                if len(inside) == 1:
                    pick = inside[0]
            if pick:
                placed[e] = pick[0]
                add_pairs(pick[1])
                changed = True
    # the routine entries themselves are mapped too
    for e, t in placed.items():
        mapping.setdefault(e, {}).setdefault(t, 0)
        mapping[e][t] += 1

    def target_of(v):
        m = mapping.get(v)
        if not m:
            return None
        best = max(m, key=m.get)
        return best

    # similar: a routine a matched call points at whose instructions are the same but for some operands
    def shape(mem, pc):
        d = z80.decode(bytes(mem[pc:pc + 4]) + bytes(4), pc)
        return d.op.name, tuple(t.name if t.name in ('IMM', 'ADDR', 'ADDR_DEREF', 'MEM_DISPL_IX', 'MEM_DISPL_IY')
                                else (t.name, str(v)) for t, v in d.operands), max(1, d.len)

    similar = {}
    taken = set(placed.values())
    def compare(e, t):
        ins = info[e][1]
        diff = []
        for pc, n, w in ins:
            tp = t + pc - e
            if not LO <= tp < HI or shape(s1.mem, pc) != shape(tgt, tp):
                return None
            if bytes(s1.mem[pc:pc + n]) != bytes(tgt[tp:tp + n]):
                diff.append(tp)
        return diff if len(diff) <= max(2, len(ins) // 4) else None

    for _ in range(3):
        for e in code:
            if e in placed or e in similar:
                continue
            tries = []
            if target_of(e) is not None:
                tries.append(target_of(e))
            known = {**placed, **{x: y[0] for x, y in similar.items()}}
            before = [x for x in known if x < e]
            after = [x for x in known if x > e]
            if before:
                b = max(before)
                tries.append(known[b] + s1.end_of(b) - b + (e - s1.end_of(b)))
            if after:
                c = min(after)
                tries.append(known[c] - (c - e))
            for t in tries:
                if t in taken:
                    continue
                diff = compare(e, t)
                if diff is not None:
                    similar[e] = (t, diff)
                    taken.add(t)
                    break

    conflicts = {v: m for v, m in mapping.items() if len(m) > 1 and v in s1.names}
    lines = [f'# Carried over from stage 1 by tools/stage_names.py ({os.path.relpath(a.ann, CASE)}): '
             f'{len(placed)} of {len(code)} named routines, the same code.']
    # @equ lines of stage 1, at the target's address where the operands say so
    for v, (name, size, comment) in sorted(s1.equ.items()):
        t = target_of(v)
        if t is not None and t != v:
            lines.append(f'@equ ${t:04X} {name}{" " + str(size) if size and size > 1 else ""} ; '
                         f'stage 1 has it at ${v:04X}{"; " + comment if comment else ""}')
        else:
            lines.append(f'@equ ${v:04X} {name}{" " + str(size) if size and size > 1 else ""}'
                         f'{" ; " + comment if comment else ""}')
    # entries: routines and data, in the target's address order
    out = []
    for e, t in placed.items():
        kind, name, width, title = s1.ann.entries[e]
        block = [f'${t:04X} c {name}' + (f' ; {title}' if title else '')]
        block.append(f'> As in stage 1 at ${e:04X}, the same code.')
        end = s1.end_of(e)
        for ia in sorted(x for x in s1.ann.inline if e < x < end):
            iname, icom = s1.ann.inline[ia]
            if iname or icom:
                block.append(f'${t + ia - e:04X}' + (f' {iname}' if iname else '') + (f' ; {icom}' if icom else ''))
        out.append((t, block))
    for e, (t, diff) in similar.items():
        kind, name, width, title = s1.ann.entries[e]
        block = [f'${t:04X} c {name}' + (f' ; {title}' if title else '')]
        block.append(f'> As in stage 1 at ${e:04X}, the same instructions; other operands at '
                     + ', '.join(f'${x:04X}' for x in diff) + ' (to be checked: an address, or a constant of '
                     'the stage).')
        end = s1.end_of(e)
        for ia in sorted(x for x in s1.ann.inline if e < x < end):
            iname, icom = s1.ann.inline[ia]
            if iname or icom:
                block.append(f'${t + ia - e:04X}' + (f' {iname}' if iname else '') + (f' ; {icom}' if icom else ''))
        out.append((t, block))
    data_found = []
    for e in s1.entries:
        kind, name, width, title = s1.ann.entries[e]
        if kind == 'c' or not name:
            continue
        t = target_of(e)
        if t is None:
            continue
        data_found.append(e)
        block = [f'${t:04X} {kind} {name}' + (f' {width}' if width else '') + (f' ; {title}' if title else '')]
        block.append(f'> As in stage 1 at ${e:04X} (found through the operands of the matched routines); '
                     f'its size and shape are to be checked.')
        out.append((t, block))
    placed_t = {t for t, _ in out}
    for v in sorted(mapping):
        if v in s1.ann.inline and s1.ann.inline[v][0] and not any(lo <= v < s1.end_of(lo) for lo in
                                                                     list(placed) + list(similar)):
            t = target_of(v)
            if t is not None and t not in placed_t and LO <= t < HI:
                out.append((t, [f'${t:04X} {s1.ann.inline[v][0]} ; as in stage 1 at ${v:04X} (an operand of a '
                                f'matched routine)']))
    for t, block in sorted(out):
        lines += block
    text = '\n'.join(lines) + '\n'
    if a.out:
        open(a.out, 'w').write(text)
    else:
        sys.stdout.write(text)

    # report
    rep = sys.stderr
    print(f'stage_names: {len(placed)} of {len(code)} named stage-1 routines matched '
          f'({sum(info[e][0] for e in placed)} of {sum(info[e][0] for e in info)} code bytes), '
          f'{len(data_found)} data entries located through operands; {len(similar)} more routines with the same '
          f'instructions but other operands (marked "to be checked")', file=rep)
    if conflicts:
        print('conflicting operand pairs (one stage-1 label, several target addresses):', file=rep)
        for v, m in sorted(conflicts.items()):
            print(f'  {s1.names[v]} ${v:04X} -> ' + ', '.join(f'${x:04X} x{n}' for x, n in sorted(m.items())),
                  file=rep)
    miss = [e for e in code if e not in placed and e not in similar]
    print(f'not matched ({len(miss)}):', file=rep)
    for e in miss:
        name = s1.ann.entries[e][1]
        size = info[e][0]
        why = 'too short to search, no call says where' if cand[e] is None else (
            f'{len(cand[e])} places, none placed' if cand[e] else 'no place')
        t = target_of(e)
        hint = ''
        if t is not None:
            ins = info[e][1]
            k = 0
            for pc, n, w in ins:
                tp = t + pc - e
                if bytes(s1.mem[pc:pc + (w if w is not None else n)]) != bytes(tgt[tp:tp + (w if w is not None else n)]):
                    break
                k += 1
            hint = f'; called at ${t:04X} there: the first {k} of {len(ins)} instructions match'
        print(f'  ${e:04X} {name} ({size} bytes): {why}{hint}', file=rep)
    return 0


if __name__ == '__main__':
    sys.exit(main())
