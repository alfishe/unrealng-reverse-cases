#!/usr/bin/env python3
"""The font as a sheet (docs/08-hud-and-text.md): the 91 glyphs of the codes $20-$7A at $5D70, from
src/res/fonts/font.png, each with its code and what it stands for. The dashboard's frame pieces (codes that are
punctuation in ASCII but drawn as slants, corners and bars, printed by the same PlotChar) are marked in orange.

    python3 tools/fig_font.py [OUT.png]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402
import res_formats as R  # noqa: E402

FONT = os.path.join(P.CASE, 'src', 'res', 'fonts', 'font.png')
FRAME = set(range(0x21, 0x27)) | {0x2B} | set(range(0x3B, 0x3F)) | {0x40} | set(range(0x5B, 0x60))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else 'docs/img/hud/font.png'
    data = R.font_build(open(FONT, 'rb').read())
    fig, ax = P.figure(12, 6.6)
    for g in range(91):
        code = 0x20 + g
        col, row = g % 16, g // 16
        x0, y0 = col * 11, row * 13
        frame = code in FRAME
        ink = P.HOT if frame else P.TEXT
        for y in range(8):
            for b in range(8):
                if data[8 * g + y] >> (7 - b) & 1:
                    ax.add_patch(P.plt.Rectangle((x0 + b, y0 + y), 1, 1, color=ink, lw=0))
        ax.add_patch(P.plt.Rectangle((x0 - 0.2, y0 - 0.2), 8.4, 8.4, fill=False, color=P.DIM, lw=0.4))
        shown = '!' if code == 0x2A else chr(code)  # the texts' "*" is drawn as "!"
        label = '$%02X' % code if frame or code == 0x20 else '$%02X %s' % (code, shown)
        ax.text(x0 + 4, y0 + 9.6, label, ha='center', va='center', fontsize=7, color=P.DIM if not frame else P.HOT,
                family='monospace')
    ax.set_xlim(-2, 16 * 11)
    ax.set_ylim(6 * 13 + 1, -2)
    ax.set_aspect('equal')
    ax.axis('off')
    fig.suptitle('The font at $5D70, codes $20-$7A: letters, digits and signs (white),\n'
                 'and in orange the dashboard\'s pieces (frame slants and corners, bar ends, the missile, the indicators)',
                 fontsize=11)
    fig.tight_layout()
    P.save(fig, out)


if __name__ == '__main__':
    main()
