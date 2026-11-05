#!/usr/bin/env python3
"""Difference report figure (work/diff/shell.md): the states around play in both games side by side, one row per
stage, with the interrupt handler each state runs under. The colour says what ANE did to the state.

    python3 tools/fig_diff_shell_states.py --out docs/img/diff/shell-states.png

The states and handlers are the sources':
  Nether Earth: ../nether-earth/src/game/ (Start $A600 with StartInterrupt $D59C, MainMenu $C100 with MenuInterrupt
      $C4FD, PlayLoop $A69A with PlayInterrupt $D566, all through the IM 2 jump at $FDFD; GameStop $AF00 and
      GameOverWait $AEEA; LoadGame and SaveGameBlocks in mainmenu.asm) and its doc 02;
  ANE: src/loader.asm (LoaderMain $6221, LoaderInterrupt $6161), the boot menu $6060 and the help $AAB1 (doc 05
      5.9), src/game/start.asm (GameEntry $A5DA, Restart $A5EF), src/game/im2.asm (ImJump $6969, GameSave $6905),
      src/game/music.asm (MusicInterrupt $6780, PlayMusic $67B1), src/game/endings.asm (CheckGameEnd $AE6B; Dead End
      in bank 3 at $D2EF, Final Cut from bank 6 run at $6060), docs 02, 05 and 10.
"""
import argparse
import sys

import matplotlib

matplotlib.use('Agg')
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyBboxPatch, Patch  # noqa: E402

import fig_diff_shell_common as C  # noqa: E402

# row, NE box (title, handler) or None, ANE box (title, handler) or None, what ANE did
ROWS = [
    (('LOAD "" from tape\nBASIC, loader N1, game block', 'ROM, IM 1'),
     ('RUN "A_NETHER" in TR-DOS\nBASIC, UltraXOR (78 layers)', 'TR-DOS, DI'), 'changed'),
    (None, ('intro: logo, Presents, star,\nscroller (LoaderMain $6221)', 'LoaderInterrupt $6161:\nAY tune; SPACE skips'),
     'added'),
    (None, ('title picture $9C40\nwhile the disk reads the game', 'IM 1'), 'added'),
    (None, ('boot menu $6060\n1 game, 2 help (28 pages), 3 unused', 'IM 1'), 'added'),
    (None, ('GameEntry $A5DA: three title\ncards, 345 frames, silent', 'IM 1'), 'added'),
    (('Start $A600: the IM 2 table\nat $FE00, the random seed', 'StartInterrupt $D59C\n(EI; RET)'),
     ('Restart $A5EF: the tune restarts,\nIM 2 table at $6800, the seed', 'ImJump $6969'), 'changed'),
    (('MainMenu $C100: keys 0-5;\n5: tape load, checksum,\nan error: back to Start',
      'MenuInterrupt $C4FD:\nbeeper tune'),
     ('game menu $C100: keys 0-5,\nRussian, a picture;\n5: disk load, no checksum',
      'MusicInterrupt $6780:\nAY tune TAIGA'), 'changed'),
    (('PlayLoop $A69A\n10-frame turn', 'PlayInterrupt $D566\n(radar, shot sound)'),
     ('PlayLoop $A69A\nthe same turn', 'PlayInterrupt + PlayMusic\n$67B1 (AY music)'), 'changed'),
    (('5 in play: tape save,\ntwo blocks, then play', 'DI (ROM SA-BYTES)'),
     ('5 in play: disk save,\none file, then play', 'GameSave $6905, bank 4'), 'changed'),
    (('I in play: abort to Start', ''), ('I in play: abort to Restart', ''), 'same'),
    (('lost: two lines, a beep,\n100 HALTs, a key: Start', 'GameOverWait $AEEA'),
     ('lost: Dead End (bank 3)\npicture, end tune, GAME OVER', 'own IM 2 $FC00 / $FDFD,\nthen Restart'), 'changed'),
    (('won: two lines, a beep,\n100 HALTs, a key: Start', 'GameOverWait $AEEA'),
     ('won: Final Cut (bank 6, at $6060)\npicture, story, never returns', 'JR $ at $6238:\nreset to leave'),
     'changed'),
]
COLOUR = {'same': C.SAME, 'changed': C.CHANGED, 'added': C.ADDED, 'gone': C.GONE}


def box(ax, x, y, w, h, title, handler, edge):
    ax.add_patch(FancyBboxPatch((x, y - h / 2), w, h, boxstyle='round,pad=0.01,rounding_size=0.06',
                                facecolor='#24262f', edgecolor=edge, lw=1.6))
    ax.text(x + 0.08, y, title, color=C.FG, fontsize=8.6, va='center', ha='left')
    if handler:
        ax.text(x + w - 0.08, y, handler, color=C.DIM, fontsize=7.8, va='center', ha='right', style='italic')


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    p.add_argument('--out', default=C.out_path('shell-states.png'))
    args = p.parse_args()
    fig, ax = plt.subplots(figsize=(14, 12.5), dpi=100)
    C.style(fig, (ax,))
    ax.set_axis_off()
    w, h, dy = 5.3, 0.8, 0.98
    xn, xa = 0.0, 6.4
    ys = [-i * dy for i in range(len(ROWS))]
    for (ne, ane, what), y in zip(ROWS, ys):
        col = COLOUR[what]
        if ne:
            box(ax, xn, y, w, h, ne[0], ne[1], C.NE_COL)
        if ane:
            box(ax, xa, y, w, h, ane[0], ane[1], C.ANE_COL)
        ax.add_patch(plt.Rectangle((xa - 0.32, y - h / 2), 0.14, h, color=col, lw=0))
        if ne and ane:
            ax.plot([xn + w + 0.04, xa - 0.36], [y, y], color=col, lw=1.4, ls='-' if what == 'same' else '--')
    # the main path downwards
    for x, flow, col in ((xn, [0, 5, 6, 7], C.NE_COL), (xa, [0, 1, 2, 3, 4, 5, 6, 7], C.ANE_COL)):
        for a, b in zip(flow, flow[1:]):
            ax.annotate('', xy=(x + 0.5, ys[b] + h / 2), xytext=(x + 0.5, ys[a] - h / 2),
                        arrowprops=dict(arrowstyle='->', color=col, lw=1.1))
    # from play to its exits (inner gutter), and the way back to the menu (outer gutter)
    for gx, sgn, col, back, back_to, label in (
            (xn - 0.2, -1, C.NE_COL, (8, 9, 10, 11), 5, 'abort, a game over:\nback to Start\n(save: back to play)'),
            (xa + w + 0.2, 1, C.ANE_COL, (9, 10), 5, 'abort, Dead End:\nback to Restart, no\ncards, no intro\n'
                                                     '(save: back to play)')):
        edge = xn if sgn < 0 else xa + w
        ax.plot([edge, gx, gx], [ys[7], ys[7], ys[11]], color=col, lw=1.0)
        for r in (8, 9, 10, 11):
            ax.annotate('', xy=(edge, ys[r] + 0.12), xytext=(gx, ys[r] + 0.12),
                        arrowprops=dict(arrowstyle='->', color=col, lw=1.0))
        ox = gx + sgn * 0.35
        rows = [r for r in back if r != 8]
        for r in rows:
            ax.plot([edge, ox], [ys[r] - 0.16, ys[r] - 0.16], color=col, lw=0.9, ls=':')
        ax.plot([ox, ox], [ys[max(rows)] - 0.16, ys[back_to] - 0.12], color=col, lw=0.9, ls=':')
        ax.annotate('', xy=(edge, ys[back_to] - 0.12), xytext=(ox, ys[back_to] - 0.12),
                    arrowprops=dict(arrowstyle='->', color=col, lw=0.9, ls=':'))
        ax.text(ox + sgn * 0.1, (ys[back_to] + ys[max(rows)]) / 2, label, color=col, fontsize=8.2,
                ha='right' if sgn < 0 else 'left', va='center')
    ax.annotate('', xy=(xa + w, ys[3] - 0.15), xytext=(xa + w, ys[3] + 0.15),
                arrowprops=dict(arrowstyle='->', color=C.ANE_COL, lw=1.0, connectionstyle='arc3,rad=-1.4'))
    ax.text(xa + w + 0.35, ys[3], 'help: back to\nthe boot menu', color=C.ANE_COL, fontsize=8.2, ha='left',
            va='center')
    ax.text(xn + w / 2, 0.75, 'Nether Earth (1987, 48K, tape)', color=C.NE_COL, fontsize=12, ha='center')
    ax.text(xa + w / 2, 0.75, 'ANE (1998, Pentagon 128, disk)', color=C.ANE_COL, fontsize=12, ha='center')
    ax.text(xn, 1.35, 'Around play: ANE adds five states before the menu and two endings after play; the menu and '
            'play keep their keys', color=C.FG, fontsize=13.5)
    ax.legend(handles=[Patch(color=COLOUR[k], label=lab) for k, lab in (
        ('same', 'the same'), ('changed', 'changed by ANE'), ('added', 'added by ANE'))], loc='lower center',
        ncol=3, fontsize=9.5, bbox_to_anchor=(0.5, -0.04), frameon=False, labelcolor='#d6d8e0')
    ax.text(xn, ys[-1] - 0.95, 'Each box: the state (left) and the interrupt it runs under (right, italic). '
            'The bar left of an ANE box: what ANE did to the state; an empty NE row: a state NE does not have.',
            color=C.DIM, fontsize=8.6)
    ax.set_xlim(-2.6, xa + w + 2.6)
    ax.set_ylim(ys[-1] - 1.2, 1.6)
    fig.savefig(args.out, facecolor=fig.get_facecolor(), bbox_inches='tight')
    print('wrote', args.out)


if __name__ == '__main__':
    sys.exit(main())
