#!/usr/bin/env python3
"""The two tape ciphers byte by byte (doc 03): the loader's R layer on $FE80-$FE8F, LoadBlock's store on the first
sixteen bytes of block 6, and block 5's first 512 bytes as on tape and as stored (the screen's top is zeros, so the
tape shows the key stream itself).

    python3 tools/fig_cipher.py "work/media/zxdb-SimCity.tzx/Sim City.tzx" docs/img/load/cipher.png

Every byte comes from the TZX (tools/tzxblocks.py) and tools/decrypt_tape.py.
"""
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Rectangle  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tzxblocks  # noqa: E402
import decrypt_tape  # noqa: E402

BG, FG, DIM = '#0e0e14', '#e6e6ee', '#9a9aa8'
ROWC = {'tape': '#5aa0ff', 'key': '#f0c846', 'E': '#f08c46', 'out': '#5ad278'}


def row(ax, y, label, values, colour, x0=2.2):
    ax.text(x0 - 0.15, y + 0.4, label, ha='right', va='center', color=colour, fontsize=10)
    for i, v in enumerate(values):
        g = v / 255
        ax.add_patch(Rectangle((x0 + i, y), 0.92, 0.8, facecolor=(g * 0.55 + 0.12,) * 3, edgecolor=colour, lw=1))
        ax.text(x0 + i + 0.46, y + 0.4, f'{v:02X}', ha='center', va='center', color='white', fontsize=10)


def tex(s):
    return s.replace('$', r'\$')


def main():
    src, out = sys.argv[1], sys.argv[2]
    bl = [b['data'] for b in tzxblocks.parse(open(src, 'rb').read()) if 'data' in b]
    loader = bl[3][1:-1]
    plain = decrypt_tape.loader_r(loader)
    plt.rcParams.update({'font.family': 'monospace'})
    fig = plt.figure(figsize=(10.5, 9.4), dpi=100, facecolor=BG)
    fig.suptitle('The two ciphers, byte by byte: the R layer of the loader, then LoadBlock on every data byte',
                 color='white', fontsize=13, y=0.985)
    # panel A: the R layer
    a = fig.add_axes([0.0, 0.73, 1.0, 0.21], facecolor=BG)
    a.set_xlim(0, 19)
    a.set_ylim(-0.6, 4.4)
    a.axis('off')
    a.text(0.2, 4.05, tex('A. LoaderStart: the byte at $FE80 + k XOR (2 + 8 k) AND $7F (the R register read by '
                          'LD A,R)'), color=FG, fontsize=11)
    ks = list(range(16))
    row(a, 2.6, 'on tape', loader[0x80:0x90], ROWC['tape'])
    row(a, 1.6, 'R key', [(2 + 8 * k) & 0x7F for k in ks], ROWC['key'])
    row(a, 0.6, 'in clear', plain[0x80:0x90], ROWC['out'])
    for i in ks:
        a.text(2.2 + i + 0.46, 3.55, f'{i}', ha='center', va='center', color=DIM, fontsize=10)
    a.text(2.05, 3.55, 'k', ha='right', va='center', color=DIM, fontsize=10)
    a.text(2.2, -0.25, tex('DI; LD SP,$61A7; LD HL,$4000; LD DE,$4001; LD BC,$1AFF; LD (HL),L; LDIR (the key repeats '
                           'every 16 bytes)'), color=DIM, fontsize=10)
    # panel B: LoadBlock on block 6
    b = fig.add_axes([0.0, 0.42, 1.0, 0.28], facecolor=BG)
    b.set_xlim(0, 19)
    b.set_ylim(-0.7, 5.4)
    b.axis('off')
    raw = bl[5]
    n = len(raw) - 2
    b.text(0.2, 5.05, tex(f'B. LoadBlock: block 6 ({n} bytes to $6B00): stored = received XOR key XOR E'),
           color=FG, fontsize=11)
    idx = list(range(16))
    tape = [raw[1 + i] for i in idx]
    key = [(3 * (i + 1)) & 0xFF for i in idx]
    e = [(n - i) & 0xFF for i in idx]
    stored = [tape[i] ^ key[i] ^ e[i] for i in idx]
    for i in idx:
        b.text(2.2 + i + 0.46, 4.55, f'{i}', ha='center', va='center', color=DIM, fontsize=10)
    b.text(2.05, 4.55, 'i', ha='right', va='center', color=DIM, fontsize=10)
    row(b, 3.6, 'on tape', tape, ROWC['tape'])
    row(b, 2.6, 'key 3(i+1)', key, ROWC['key'])
    row(b, 1.6, 'E (n-i)', e, ROWC['E'])
    row(b, 0.6, 'stored', stored, ROWC['out'])
    b.text(2.2, -0.3, tex('$6B00: the first bytes of code1 as LoadBlock stores them; key and E both wrap at 256'), color=DIM, fontsize=10)
    # panel C: the key stream of block 6, 1024 bytes, 256 a line
    import numpy as np
    c = fig.add_axes([0.13, 0.05, 0.84, 0.30], facecolor=BG)
    ks = np.array([[((3 * (i + 1)) & 0xFF) ^ ((n - i) & 0xFF) for i in range(r * 256, r * 256 + 256)]
                   for r in range(4)])
    c.imshow(ks, cmap='viridis', interpolation='nearest', aspect='auto', vmin=0, vmax=255)
    c.set_yticks(range(4))
    c.set_yticklabels([f'bytes {r * 256}-{r * 256 + 255}' for r in range(4)], color=FG, fontsize=10)
    c.set_xticks([0, 64, 128, 192, 255])
    c.set_xticklabels(['+0', '+64', '+128', '+192', '+255'], color=DIM, fontsize=10)
    for sp in c.spines.values():
        sp.set_color('#3c3c50')
    c.set_title(tex("C. Block 6's key stream (key XOR E), a cell a byte: the four lines are equal, a period of 256"), color=FG, fontsize=10.5, loc='left',
                x=-0.13)
    fig.savefig(out, facecolor=BG)
    print(out)


if __name__ == '__main__':
    main()
