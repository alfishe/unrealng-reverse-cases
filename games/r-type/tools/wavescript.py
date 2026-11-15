#!/usr/bin/env python3
"""R-Type's level blocks decoded: the header, the wave script, the enemy kinds, their movement scripts and the two
mover tables, from build/levelN.bin (the body LoadLevel `$FE03` reads to `$C4AE`) and build/levelN.lst (the labels).

    python3 tools/wavescript.py N [--part header|waves|kinds|scripts|movers|all]   one level as text
    python3 tools/wavescript.py summary                                           a line a level (doc 7, 7.12)
    python3 tools/wavescript.py json N                                            the decode as JSON (the figures)

The formats (doc 7):

- the header, `$C4AE`: restart column, restart wave (the live copies, zeros on tape), three checkpoint columns (the
  first is the start column, `$FF` none), their three wave entries, then the words objects, map, kinds, movers A,
  movers B;
- a wave entry, 5 bytes: map block column, (metatile column << 3) | scroll step, kind, then a word: the enemy's
  column (low byte) and row (high byte); kind `$63` is a command: its low word byte the command (1 halt the scroll,
  2 resume, 3 the next wave's slot = high byte, 4 the shooter limit = high byte, 5 the level's end, 6 sound = high
  byte); `$FF` in the column byte ends the script;
- a kind record: movers (low nibble mover A, high nibble mover B), flags (bits 0-5 hits, bit 6 fires, bit 7 a shot
  out), score byte (high nibble explosion size, low nibble award), then the scripts as words, `$0000` frees the slot,
  `$FFFF` starts the list again; a record whose first word's two bytes are equal and below `$80` borrows that kind's
  scripts;
- a script step, 2 bytes: the level object, then the move byte (bits 0-1 the drawer: stored, mirrored, flipped, both;
  bit 2 up, 3 down, 4 left, 5 right; bit 7 the script's last step).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORG = 0xC4AE
COMMANDS = {1: 'halt the scroll', 2: 'resume the scroll', 3: 'next wave in slot', 4: 'shooter limit',
            5: 'level end', 6: 'sound'}
DRAWERS = ['stored', 'mirrored', 'flipped', 'both']
LINE = re.compile(r'^\s*\d+\+*\s+([0-9A-F]{4})\s+([A-Za-z_]\w*):')


def load(n):
    data = open(os.path.join(ROOT, 'build', f'level{n}.bin'), 'rb').read()
    mem = bytearray(0x10000)
    mem[ORG:ORG + len(data)] = data
    labels = {}
    for line in open(os.path.join(ROOT, 'build', f'level{n}.lst'), encoding='latin-1'):
        m = LINE.match(line)
        if m:
            labels.setdefault(int(m.group(1), 16), m.group(2))
    return mem, len(data), labels


def word(mem, a):
    return mem[a] | mem[a + 1] << 8


def header(mem):
    h = dict(restart_column=mem[ORG], restart_wave=word(mem, ORG + 1),
             checks=[mem[ORG + 3 + k] for k in range(3)], waves=[word(mem, ORG + 6 + 2 * k) for k in range(3)],
             objects=word(mem, ORG + 12), map=word(mem, ORG + 14), kinds=word(mem, ORG + 16),
             movers_a=word(mem, ORG + 18), movers_b=word(mem, ORG + 20))
    return h


def waves(mem, start, stop=0x10000):
    """the entries from start up to a $FF column byte or the first kind record (stop): level 1 has no $FF"""
    out, a = [], start
    while a < stop and mem[a] != 0xFF and len(out) < 1000:
        col, sub, kind, lo, hi = mem[a:a + 5]
        e = dict(address=a, column=col, meta=(sub >> 3) & 3, step=sub & 7, kind=kind, lo=lo, hi=hi,
                 position=col * 4 + ((sub >> 3) & 3) + (sub & 7) / 8)
        if kind == 0x63:
            e['command'] = lo
            e['arg'] = hi
        out.append(e)
        a += 5
    return out, a


def kinds(mem, table, lo):
    """the records lie between the wave script's end (lo) and the table; the table runs while its words do"""
    count = 0
    while lo < word(mem, table + 2 * count) < table:
        count += 1
    out = []
    for k in range(count):
        r = word(mem, table + 2 * k)
        movers, flags, score = mem[r], mem[r + 1], mem[r + 2]
        b3, b4 = mem[r + 3], mem[r + 4]
        alias = b3 if (b3 == b4 and b3 < 0x80) else None
        scripts = []
        if alias is None:
            a = r + 3
            while len(scripts) < 40:
                w = word(mem, a)
                if w >> 8 == 0:
                    scripts.append('free')
                    break
                if w >> 8 == 0xFF:
                    scripts.append('again')
                    break
                scripts.append(w)
                a += 2
        out.append(dict(kind=k + 1, record=r, mover_a=movers & 15, mover_b=movers >> 4, hits=flags & 0x3F,
                        fires=bool(flags & 0x40), flags=flags, size=score >> 4, award=score & 15, alias=alias,
                        scripts=scripts))
    return out


def script(mem, a):
    steps = []
    while len(steps) < 128:
        obj, mv = mem[a], mem[a + 1]
        d = []
        if mv & 4:
            d.append('up')
        if mv & 8:
            d.append('down')
        if mv & 16:
            d.append('left')
        if mv & 32:
            d.append('right')
        steps.append(dict(address=a, object=obj, move=mv, dirs=d, drawer=DRAWERS[mv & 3], last=bool(mv & 0x80),
                          bit6=bool(mv & 0x40)))
        if mv & 0x80:
            break
        a += 2
    return steps


def decode(n):
    mem, size, labels = load(n)
    h = header(mem)
    k = kinds(mem, h['kinds'], h['waves'][0])
    w, end = waves(mem, h['waves'][0], min(kk['record'] for kk in k))
    scripts = {}
    for kk in k:
        for s in kk['scripts']:
            if isinstance(s, int) and s not in scripts:
                scripts[s] = script(mem, s)
    for e in w:
        pass
    ma = [word(mem, h['movers_a'] + 2 * i) for i in range(16)]
    mb = [word(mem, h['movers_b'] + 2 * i) for i in range(16)]
    return dict(level=n, size=size, end=ORG + size, header=h, waves=w, waves_end=end, kinds=k, scripts=scripts,
                movers_a=ma, movers_b=mb, labels=labels)


def name(labels, a):
    return labels.get(a, f'${a:04X}')


def text(d, part='all'):
    n, h, labels = d['level'], d['header'], d['labels']
    out = []
    if part in ('all', 'header'):
        out.append(f'Level {n}: {d["size"]} bytes at $C4AE-${d["end"] - 1:04X}')
        out.append(f'  header: restart column {h["restart_column"]}, restart wave ${h["restart_wave"]:04X}; '
                   f'checkpoint columns {", ".join(str(c) if c != 255 else "-" for c in h["checks"])}; '
                   f'their wave entries {", ".join(f"${x:04X}" for x in h["waves"])}')
        out.append(f'  objects ${h["objects"]:04X}, map ${h["map"]:04X}, kinds ${h["kinds"]:04X}, movers A '
                   f'${h["movers_a"]:04X}, movers B ${h["movers_b"]:04X}')
    if part in ('all', 'waves'):
        out.append(f'  wave script: {len(d["waves"])} entries ${h["waves"][0]:04X}-${d["waves_end"]:04X} ($FF)')
        for i, e in enumerate(d['waves']):
            where = f'col {e["column"]:3}.{e["meta"]}.{e["step"]}'
            if 'command' in e:
                c = e['command']
                arg = f' {e["arg"]}' if c in (3, 4, 6) else ''
                out.append(f'    {i:3} ${e["address"]:04X} {where}  command {c} ({COMMANDS.get(c, "?")}){arg}')
            else:
                out.append(f'    {i:3} ${e["address"]:04X} {where}  kind {e["kind"]:2} at column {e["lo"]}, '
                           f'row {e["hi"]}')
    if part in ('all', 'kinds'):
        out.append(f'  kinds: {len(d["kinds"])}')
        for k in d['kinds']:
            s = (f'borrows kind {k["alias"]}\'s scripts' if k['alias'] else
                 ' '.join(f'${x:04X}' if isinstance(x, int) else x for x in k['scripts']))
            out.append(f'    kind {k["kind"]:2} ${k["record"]:04X}: movers A{k["mover_a"]} B{k["mover_b"]}, hits '
                       f'{k["hits"]}{" (indestructible)" if k["hits"] == 63 else ""}, '
                       f'{"fires" if k["fires"] else "no fire"}, size {k["size"]}, award {k["award"]}; {s}')
    if part in ('all', 'scripts'):
        out.append(f'  scripts: {len(d["scripts"])}')
        for a, steps in sorted(d['scripts'].items()):
            out.append(f'    ${a:04X}: ' + ', '.join(
                f'{s["object"]}{"/" + s["drawer"][0] if s["drawer"] != "stored" else ""}'
                f'{"+" + "".join(x[0] for x in s["dirs"]) if s["dirs"] else ""}' for s in steps))
    if part in ('all', 'movers'):
        out.append('  movers A: ' + ', '.join(name(labels, a) for a in d['movers_a']))
        out.append('  movers B: ' + ', '.join(name(labels, a) for a in d['movers_b']))
    return '\n'.join(out)


def summary():
    print('| Level | Bytes | End | Start column | Checkpoints | Waves | Commands | Kinds | Scripts | Halt at | End at |')
    print('| ---: | ---: | --- | ---: | --- | ---: | ---: | ---: | ---: | --- | --- |')
    for n in range(1, 9):
        d = decode(n)
        h = d['header']
        cmds = [e for e in d['waves'] if 'command' in e]
        halts = [e['column'] for e in cmds if e['command'] == 1]
        ends = [e['column'] for e in cmds if e['command'] == 5]
        print(f'| {n} | {d["size"]} | `${d["end"] - 1:04X}` | {h["checks"][0]} | '
              f'{", ".join(str(c) for c in h["checks"][1:] if c != 255) or "none"} | {len(d["waves"]) - len(cmds)} | '
              f'{len(cmds)} | {len(d["kinds"])} | {len(d["scripts"])} | {", ".join(map(str, halts)) or "-"} | '
              f'{", ".join(map(str, ends))} |')


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    if args[0] == 'summary':
        summary()
        return
    if args[0] == 'json':
        d = decode(int(args[1]))
        d['scripts'] = {f'{a:04X}': s for a, s in d['scripts'].items()}
        d.pop('labels')
        print(json.dumps(d, indent=1))
        return
    part = 'all'
    if '--part' in args:
        part = args[args.index('--part') + 1]
    print(text(decode(int(args[0])), part))


if __name__ == '__main__':
    main()
