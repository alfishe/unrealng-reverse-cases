#!/usr/bin/env python3
"""Doc 03: the table of every packed block of the SCL and the figure of the disk's 512 sectors with each block's
packed and unpacked size (docs/img/load/blocks.png).

    python3 tools/fig_blocks.py [--png docs/img/load/blocks.png] [--md]

Run after tools/build.sh (it reads build/pk/*.hrm and build/blk/*.bin). The numbers come from:

- src/sfx/blocks.asm: each HRUM_SFX block (its label, the ORG it runs at, the depacker's place, the output, the
  entry and exit flags) and the comment above it;
- build/pk/NAME.hrm: the packed stream (tools/hrum.py pack), build/blk/NAME.bin: the whole block (31 bytes of set-up,
  119 of depacker, the stream);
- src/disk.txt: where each build/blk file lies (file sector + byte, counted from A_NETHER.B's first sector); the
  intro's block lies inside build/loader.bin at $6600, the two inner blocks inside other blocks' images
  (src/images.asm).

--md prints the Markdown table of doc 03 (one row a block, then the totals).
"""
import argparse
import os
import re

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
BG, PANEL, FG, DIM = '#15161b', '#1c1d24', '#e6e6e6', '#b8bcc8'

# What each block holds and the doc that describes it (the label of src/sfx/blocks.asm -> name, what, doc)
WHAT = {
    'Intro': ('intro', 'the intro program: the Eternity picture, the tune MAD NIGHT', '[3.4](#34-the-boot-chain)'),
    'IntroScreen': ('introscreen', 'the Eternity Industry picture', '[3.4](#34-the-boot-chain)'),
    'Block02': ('d02', '"Presents"', '[3.4](#34-the-boot-chain)'),
    'Block03': ('d03', 'the credits scroller', '[3.4](#34-the-boot-chain)'),
    'Block05': ('d05', 'the boot program: boot menu, help', '[3.4](#34-the-boot-chain)'),
    'Block04': ('d04', 'the boot music: PT3 player, X-Man tune', '[9](09-sound.md)'),
    'BootBank7': ('d06', "bank 7's image (holds the game starter)", '[3.4](#34-the-boot-chain)'),
    'Part9C40': ('d07', 'the game starter', '[3.4](#34-the-boot-chain)'),
    'Game': ('game', 'the game', '[2](02-architecture.md)'),
    'Music': ('music', 'the game music: SoundTrack player, "TAIGA"', '[9](09-sound.md)'),
    'DeadEnd': ('deadend', 'Dead End (a lost game), the menu picture', '[10](10-gameplay-logic.md)'),
    'FinalCut': ('finalcut', 'Final Cut (a won game)', '[10](10-gameplay-logic.md)'),
    'DiskIo': ('diskio', 'the disk module: save, load', '[3.7](#37-the-saved-game-nethern)'),
}
SHORT = {'intro': 'intro', 'introscreen': 'intro picture', 'd02': 'Presents', 'd03': 'scroller',
         'd05': 'boot program', 'd04': 'boot music', 'd06': 'bank 7 image', 'd07': 'game starter', 'game': 'game',
         'music': 'game music', 'deadend': 'Dead End', 'finalcut': 'Final Cut', 'diskio': 'disk module'}
# Where the boot reads each disk range (tools/ane_sim.py --log, work/stage2/tmp/log3.txt; tools/sim_reads.py)
READ_TO = {'intro': '`$6161` (the loader)', 'd02': 'bank 7 `$DB00`', 'd03': 'bank 4 `$C000`',
           'd05': '`$6060`', 'deadend': 'bank 3 `$C000`', 'music': 'bank 3 `$C000`', 'd04': 'bank 1 `$C000`',
           'game': 'bank 4 `$C000` + bank 3', 'finalcut': 'bank 6 `$C000`', 'diskio': 'bank 6 `$C000`',
           'd06': 'bank 7 `$C000`', 'introscreen': 'in the intro', 'd07': "in bank 7's image"}
BANK_AT = {'IntroScreen': 'bank 7 ', 'Block04': 'bank 1 ', 'BootBank7': 'bank 7 ', 'Music': 'bank 1 ',
           'DeadEnd': 'bank 3 ', 'DiskIo': 'bank 4 '}
COLOURS = {'intro': '#5c8fd6', 'introscreen': '#7fa8e0', 'd02': '#4fb3bf', 'd03': '#3f8f99', 'd05': '#4caf50',
           'd04': '#c77ddb', 'd06': '#8e7cc3', 'd07': '#b39ddb', 'game': '#d9a441', 'music': '#e07ad0',
           'deadend': '#d9534f', 'finalcut': '#f0c05a', 'diskio': '#e8833a'}


def sizes():
    """PK_NAME / UN_NAME from build/pk/sizes.inc (tools/packall.py)"""
    out = {}
    for line in open(os.path.join(CASE, 'build/pk/sizes.inc')):
        m = re.match(r'\s*(\w+)\s+(?:EQU|=)\s+(\$?\w+)', line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


SIZES = None


def num(s):
    global SIZES
    s = s.strip()
    if re.match(r'(PK|UN)_', s):
        SIZES = SIZES or sizes()
        if s not in SIZES:  # the file holds only the last packall pass: the lengths are the files' sizes
            kind, name = s.split('_', 1)
            return os.path.getsize(os.path.join(CASE, 'build/pk/%s.%s' % (name, 'hrm' if kind == 'PK' else 'img')))
        s = SIZES[s]
    return int(s[1:], 16) if s.startswith('$') else int(s)


def parse_blocks():
    """[(label, args, comment)] from src/sfx/blocks.asm"""
    out, comment = [], []
    for line in open(os.path.join(CASE, 'src/sfx/blocks.asm')):
        if line.startswith(';'):
            comment.append(line[1:].strip())
            continue
        m = re.match(r'(\w+):\s*$', line)
        if m:
            label = m.group(1)
            continue
        m = re.match(r'\s+HRUM_SFX (.*)', line)
        if m:
            args = [a.strip() for a in re.findall(r'"[^"]*"|[^,]+', m.group(1))]
            out.append((label, args, ' '.join(comment)))
            comment = []
        elif not line.strip().startswith('ORG') and line.strip():
            comment = [] if not line.strip().startswith('SAVEBIN') else comment
    return out


def parse_disk():
    """{build/blk file: [(sector, byte, from, count)]}"""
    places = {}
    for line in open(os.path.join(CASE, 'src/disk.txt')):
        p = line.split()
        if not p or p[0] != 'at':
            continue
        sec, off = p[1].split('+')
        frm = num(p[3]) if len(p) > 3 else 0
        cnt = num(p[4]) if len(p) > 4 else None
        places.setdefault(p[2], []).append((int(sec), int(off), frm, cnt))
    return places


def blocks():
    disk = parse_disk()
    rows = []
    for label, a, comment in parse_blocks():
        name, what, doc = WHAT[label]
        entry_ei, sp_save, dep, out, outlen = num(a[0]), num(a[1]), num(a[2]), num(a[3]), num(a[4])
        exit_sp, exit_ei, exit_jp = num(a[8]), num(a[9]), num(a[10])
        stream = os.path.getsize(os.path.join(CASE, 'build/pk/%s.hrm' % name))
        size = os.path.getsize(os.path.join(CASE, 'build/blk/%s.bin' % name))
        assert size == stream + 150, name
        pl = disk.get('build/blk/%s.bin' % name, [])
        parts = []
        for sec, off, frm, cnt in pl:
            n = cnt if cnt is not None else size - frm
            last = sec + (off + n - 1) // 256
            parts.append((sec, off, last, n))
        if name == 'intro':  # inside the loader at $6600: loader byte $6600 - $6161
            o = 0x6600 - 0x6161
            parts = [(11 + o // 256, o % 256, 11 + (o + size - 1) // 256, size)]
        rows.append(dict(label=label, name=name, what=what, doc=doc, ei=entry_ei, spsave=sp_save, dep=dep,
                         out=out, outlen=outlen, exit_sp=exit_sp, exit_ei=exit_ei, exit_jp=exit_jp, stream=stream,
                         size=size, parts=sorted(parts), org=None))
    order = ['intro', 'introscreen', 'd02', 'd03', 'd05', 'd04', 'd06', 'd07', 'music', 'deadend', 'diskio',
             'game', 'finalcut']
    return sorted(rows, key=lambda r: order.index(r['name']))


def sectors_text(r):
    if not r['parts']:
        return 'inside ' + ('the intro (`$7537`)' if r['name'] == 'introscreen' else "bank 7's image (`$C000`)")
    return ' + '.join('%d-%d' % (s, l) if s != l else '%d' % s for s, _o, l, _n in r['parts'])


def start_text(r):
    s = 'EI' if r['ei'] else 'DI'
    s += ', returns' if r['spsave'] else ', no return'
    return s


def end_text(r):
    e = 'EI' if r['exit_ei'] else 'DI'
    if r['exit_sp']:
        e = 'SP `$%04X`, ' % r['exit_sp'] + e
    return e + (', `JP $%04X`' % r['exit_jp'] if r['exit_jp'] else ', `RET`')


def table(rows):
    lines = ['| # | Block | Sectors | Read to | Stream | Block | Unpacked | Stream / unpacked | Unpacks to | '
             'Depacker | Set-up | End | What | Doc |',
             '| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- | --- | --- |']
    for i, r in enumerate(rows, 1):
        bank = BANK_AT.get(r['label'], '')
        lines.append('| %d | `%s` | %s | %s | %d | %d | %d | %d %% | %s`$%04X-$%04X` | `$%04X` | %s | %s | %s | %s |' % (
            i, r['label'], sectors_text(r), READ_TO[r['name']], r['stream'], r['size'], r['outlen'],
            round(100 * r['stream'] / r['outlen']), bank, r['out'], r['out'] + r['outlen'] - 1, r['dep'],
            start_text(r), end_text(r), r['what'], r['doc']))
    ts, tb, tu = (sum(r[k] for r in rows) for k in ('stream', 'size', 'outlen'))
    lines.append('| | **total**, %d blocks | | | **%d** | **%d** | **%d** | **%d %%** | | | | | | |' % (
        len(rows), ts, tb, tu, round(100 * ts / tu)))
    return '\n'.join(lines)


def plain_row():
    """The one unpacked block: src/disk.txt's line for plain-9c40.bin, its size from the file"""
    disk = parse_disk()
    path = 'src/res/img/plain-9c40.bin'
    sec, off, _f, _c = disk[path][0]
    n = os.path.getsize(os.path.join(CASE, path))
    return ('| %d | `Title9C40` (not packed) | %d-%d | `$9C40` | | %d | %d | 100 %% | `$9C40-$%04X`, then its own '
            'screen depacker draws `$4000-$5AFF` | none | UltraXOR\'s reader: `CALL $9C40` | `RET` to the reader | '
            'the title picture, its own LZ (`CALL $0052` finds where it runs) | [3.4](#34-the-boot-chain) |' % (
                14, sec, sec + (off + n - 1) // 256, n, n, 0x9C40 + n - 1))


def hrust_row(trd=os.path.join(CASE, 'orig/ANE_FC.TRD')):
    """The Final Cut disk's Hrust 1 block: the catalogue entry of ane_fc and the "HR" header in its sectors"""
    d = open(trd, 'rb').read()
    e = d[0:16]
    assert e[:8] == b'ane_fc  ', e
    nsec, sec0, trk0 = e[13], e[14], e[15]
    at = (trk0 * 16 + sec0) * 256
    h = d.find(b'HR', at, at + nsec * 256)
    un, pk = int.from_bytes(d[h + 2:h + 4], 'little'), int.from_bytes(d[h + 4:h + 6], 'little')
    rel = h - at
    return ('| 1 | `ane_fc` Hrust 1 block | `ane_fc.B` file sectors %d-%d (track %d sector %d on) | `$61A8` '
            '(TR-DOS `$3D13`, `C` = 5, 55 sectors) | %d | %d (55 sectors read) | %d | %d %% | `$6060-$%04X` | '
            '`$FE4C` (`$DE` bytes, its 6 last bytes to `$FF2C`) | `$61A8`: DI, copies the depacker, LDDR | SP '
            '`$6060`, DI, `JP $61A8` (the image) | Final Cut alone | [3.8](#38-the-final-cut-disk-2017) |' % (
                rel // 256, nsec - 1, trk0, sec0, pk, 55 * 256, un, round(100 * pk / un), 0x6060 + un - 1))


def figure(rows, png):
    fig = plt.figure(figsize=(12, 8.6), facecolor=BG)
    fig.text(0.015, 0.975, 'The SCL is 512 sectors: 13 HRUM 3.5 blocks pack 253 503 bytes of programs into 107 326',
             color=FG, fontsize=14, family='monospace', va='top')
    fig.text(0.015, 0.94, 'Top: the disk sector by sector, each block in its colour; bottom: each block\'s stream '
             'against what it unpacks to', color=DIM, fontsize=10, family='monospace', va='top')
    ax = fig.add_axes([0.04, 0.70, 0.94, 0.17], facecolor=PANEL)
    files = [(0, 255, 'A_NETHER.B'), (255, 437, 'a_nether.E'), (437, 476, 'nether.N'), (476, 512, 'NETHER+.W')]
    for lo, hi, name in files:
        ax.add_patch(Rectangle((lo, 2.2), hi - lo, 0.6, facecolor='#2b2d38', edgecolor=DIM, lw=0.8))
        ax.text((lo + hi) / 2, 2.5, name, color=FG, ha='center', va='center', fontsize=9, family='monospace')
    other = [(0, 11, 'UltraXOR BASIC 0-10', '#7a7d8c', 0.55), (11, 15, 'loader code 11-15', '#9aa0b0', 0.2),
             (87, 100, '$9C40 plain 87-99', '#b0b0b0', 0.55), (437, 476, 'a saved game', '#6d8a6d', 0.55),
             (476, 512, 'text', '#555a66', 0.55)]
    for lo, hi, name, col, y in other:
        ax.add_patch(Rectangle((lo, 0.9), hi - lo, 1.0, facecolor=col, edgecolor=BG, lw=0.5))
        ax.text(lo + 1, y, name, color=DIM, ha='left', va='center', fontsize=7.5, family='monospace')
    ax.annotate('game tail 251-255', xy=(253, 0.9), xytext=(232, 0.2), color=DIM, fontsize=7.5,
                family='monospace', arrowprops=dict(arrowstyle='-', color=DIM, lw=0.6))
    for r in rows:
        for s, o, l, n in r['parts']:
            x0 = s + o / 256
            x1 = x0 + n / 256
            ax.add_patch(Rectangle((x0, 0.9), x1 - x0, 1.0, facecolor=COLOURS[r['name']], edgecolor=BG, lw=0.5))
            if n > 1500:
                lab = {'d02': 'Pres-\nents', 'd03': 'scrol-\nler', 'diskio': 'disk\nmod.'}.get(
                    r['name'], SHORT[r['name']].replace(' ', '\n'))
                ax.text((x0 + x1) / 2, 1.4, lab, color='#101010', ha='center', va='center', fontsize=7,
                        family='monospace')
    ax.set_xlim(0, 512)
    ax.set_ylim(0, 3)
    ax.set_yticks([])
    ax.set_xticks(range(0, 513, 32))
    ax.tick_params(colors=DIM, labelsize=8)
    ax.set_xlabel('sector (counted from A_NETHER.B\'s first; 256 bytes each)', color=DIM, fontsize=9)
    for s in ax.spines.values():
        s.set_color('#444')
    bx = fig.add_axes([0.17, 0.06, 0.80, 0.55], facecolor=PANEL)
    order = list(reversed(rows))
    for i, r in enumerate(order):
        c = COLOURS[r['name']]
        bx.barh(i, r['outlen'], color=c, alpha=0.35, height=0.75)
        bx.barh(i, r['stream'], color=c, height=0.75)
        bx.text(r['outlen'] + 300, i, '%d -> %d  (%d %%)' % (r['stream'], r['outlen'],
                round(100 * r['stream'] / r['outlen'])), color=FG, va='center', fontsize=8.5, family='monospace')
    bx.set_yticks(range(len(order)))
    bx.set_yticklabels(['%s\n%s' % (SHORT[r['name']], ('bank %s ' % BANK_AT[r['label']].split()[1]
                        if r['label'] in BANK_AT else '') + '$%04X' % r['out']) for r in order],
                       color=FG, fontsize=8.5, family='monospace')
    bx.set_xlim(0, 52000)
    bx.tick_params(colors=DIM, labelsize=8)
    bx.set_xlabel('bytes: solid = the packed stream on the disk, pale = the bytes it unpacks to', color=DIM,
                  fontsize=9)
    for s in bx.spines.values():
        s.set_color('#444')
    os.makedirs(os.path.dirname(png), exist_ok=True)
    fig.savefig(png, dpi=100, facecolor=BG)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--png', default=os.path.join(CASE, 'docs/img/load/blocks.png'))
    p.add_argument('--md', action='store_true')
    args = p.parse_args()
    rows = blocks()
    if args.md:
        print(table(rows))
        print(plain_row())
        print('\nThe Final Cut disk (`orig/ANE_FC.TRD`):\n')
        print('| # | Block | Sectors | Read to | Stream | Read | Unpacked | Stream / unpacked | Unpacks to | Depacker | '
              'Set-up | End | What | Doc |')
        print('| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- | --- | --- |')
        print(hrust_row())
    figure(rows, args.png)


if __name__ == '__main__':
    main()
