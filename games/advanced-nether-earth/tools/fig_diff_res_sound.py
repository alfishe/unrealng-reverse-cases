#!/usr/bin/env python3
"""The sound of the two games compared, for the resources part of docs/13 (work/diff/resources.md).

    python3 tools/fig_diff_res_sound.py where     docs/img/diff/res-sound-where.png: what sounds in each state
    python3 tools/fig_diff_res_sound.py spectra   docs/img/diff/res-sound-spectra.png: the menu music of both, and
                                                  two effects both games make with the same code, as spectrograms
    python3 tools/fig_diff_res_sound.py all

`where` is drawn from the states tables of both cases' docs/04 (the interrupt handler of each state and what it
plays) and docs/09; `spectra` decodes the mp3s of both cases' docs/audio (rendered by unreal-ng from the machine
state: games/nether-earth/docs/audio/README.md, docs/audio/README.md) with ffmpeg and draws them with scipy.
"""
import argparse
import os
import subprocess
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
R = os.path.abspath(os.path.join(CASE, '..', '..'))
sys.path.insert(0, os.path.join(R, 'kit'))
import kitlib as K  # noqa: E402

OUT = os.path.join(CASE, 'docs', 'img', 'diff')
NE_AUDIO = os.path.join(R, 'games', 'nether-earth', 'docs', 'audio')
ANE_AUDIO = os.path.join(CASE, 'docs', 'audio')
RATE = 44100


def rgb(c):
    return tuple(v / 255 for v in c)


BG, FG, DIM, PANEL = rgb(K.BACKGROUND), rgb(K.TEXT), rgb(K.DIM), rgb(K.PANEL)
BEEPER, AY, SILENT = rgb(K.WRITE_FADE[1]), rgb(K.READ), rgb((70, 70, 85))

# (state, NE: (kind, text), ANE: (kind, text)); kind: beeper / ay / silent / both (AY music + beeper effects)
STATES = [
    ('intro, title', ('silent', 'no intro: the tape loader, then the menu'),
     ('ay', 'MAD NIGHT (Syrus) under the intro, Presents and the scroller;\nthe title picture and the title cards '
      'silent')),
    ('boot menu, help', ('silent', 'not in the game'), ('ay', 'TOMY (X-Man), PT3, the boot menu and the help pages')),
    ('main menu', ('beeper', 'the menu tune (MenuMusic $C4A7): two pulse voices and drums in\n'
                   'a busy loop until a number key; a loop of 5120 frames (102 s)'),
     ('ay', 'TAIGA (X-Man), New SoundTrack Player, bank 1, by MusicInterrupt\n'
      '$6780 (IM 2); a loop of 5120 frames (105 s)')),
    ('redefine keys', ('silent', 'silent (StartInterrupt)'), ('ay', 'TAIGA goes on (MusicInterrupt stays)')),
    ('construction menu', ('beeper', 'the menu Beeps only, the game waits (StartInterrupt)'),
     ('both', 'TAIGA (MusicInterrupt) + the same Beeps')),
    ('play, robot menus,\ndirect control, pause', ('beeper', 'SoundEffect each frame: shot sweep, hit, miss, '
                                                   'explosion;\nthe menu Beeps; no music'),
     ('both', 'TAIGA every frame (PlayMusic $67B1, chained into\nPlayInterrupt) + the same SoundEffect and Beeps')),
    ('game end', ('beeper', 'a text on the panel and the $FA Beep (530 Hz)'),
     ('ay', 'lost: Dead End, NETHER EARTH (END) (Syrus);\nwon: Final Cut, REM (X-Man)')),
    ('save, load', ('silent', 'tape: silent'), ('silent', 'disk module, IM 1: silent')),
]


def cmd_where(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import FancyBboxPatch
    rows = len(STATES)
    fig, ax = plt.subplots(figsize=(12.5, 0.78 * rows + 1.7), dpi=100)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(BG)
    ax.set_xlim(0, 12.5)
    ax.set_ylim(rows + 0.2, -1.1)
    ax.axis('off')
    x_state, x_ne, x_ane, w = 0.1, 2.0, 7.3, 5.1
    ax.text(x_ne, -0.55, 'Nether Earth (48K, beeper only)', color=FG, fontsize=12, weight='bold')
    ax.text(x_ane, -0.55, 'Advanced Nether Earth (Pentagon 128, one AY + the beeper)', color=FG, fontsize=12,
            weight='bold')
    colour = {'beeper': BEEPER, 'ay': AY, 'silent': SILENT, 'both': AY}
    for i, (state, ne, ane) in enumerate(STATES):
        ax.text(x_state, i + 0.42, state, color=FG, fontsize=10, va='center')
        for x, (kind, text) in ((x_ne, ne), (x_ane, ane)):
            ax.add_patch(FancyBboxPatch((x, i + 0.06), w, 0.74, boxstyle='round,pad=0.0,rounding_size=0.08',
                                        facecolor=colour[kind], alpha=0.28, edgecolor=colour[kind], lw=1.2))
            if kind == 'both':
                ax.add_patch(FancyBboxPatch((x + w - 0.18, i + 0.06), 0.18, 0.74,
                                            boxstyle='round,pad=0.0,rounding_size=0.05', facecolor=BEEPER,
                                            edgecolor='none', alpha=0.9))
            ax.text(x + 0.1, i + 0.43, text.replace('$', r'\$'), color=FG, fontsize=8.8, va='center')
    y = rows + 0.05
    items = [(BEEPER, 'beeper: the menu tune, SoundEffect and Beep (one code in both games)'),
             (AY, 'AY music (a yellow strip: the beeper effects over it)'), (SILENT, 'silent')]
    x = 0.1
    for c, t in items:
        ax.add_patch(FancyBboxPatch((x, y), 0.3, 0.3, boxstyle='square,pad=0', facecolor=c, alpha=0.8,
                                    edgecolor='none'))
        ax.text(x + 0.4, y + 0.16, t, color=DIM, fontsize=9, va='center')
        x += 0.9 + len(t) * 0.085
    ax.set_title('Where the sound is: NE plays music only in its menu; ANE has AY music almost everywhere and keeps '
                 'NE\'s beeper effects', color=FG, fontsize=12.5, loc='left')
    fig.text(0.01, 0.01, 'handlers from both docs/04 (4.2 / the states table) and docs/09; '
             'python3 tools/fig_diff_res_sound.py where', color=DIM, fontsize=8)
    fig.tight_layout(rect=(0, 0.03, 1, 1))
    path = args.out or os.path.join(OUT, 'res-sound-where.png')
    fig.savefig(path, facecolor=BG)
    print(path)


def decode(path, start=0.0, length=None):
    cmd = ['ffmpeg', '-v', 'error', '-ss', str(start), '-i', path]
    if length:
        cmd += ['-t', str(length)]
    cmd += ['-ac', '1', '-ar', str(RATE), '-f', 's16le', '-']
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype='<i2').astype(np.float32) / 32768.0


def cmd_spectra(args):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from scipy import signal
    panels = [
        ('NE: the menu tune (beeper), first 20 s', os.path.join(NE_AUDIO, 'menu-tune.mp3'), 0, 20),
        ('ANE: TAIGA (AY, ABC mixed to mono), first 20 s',
         os.path.join(ANE_AUDIO, 'taiga.mp3'), 0, 20),
        ('NE: START ROBOT, the chirp + the $C8 beep', os.path.join(NE_AUDIO, 'sfx-robot-start.mp3'), 0, None),
        ('ANE: the same, same code and values', os.path.join(ANE_AUDIO, 'sfx-robot-start.mp3'), 0, None),
        ('NE: a shot fired, the 126-frame sweep', os.path.join(NE_AUDIO, 'sfx-fire-sweep.mp3'), 0, None),
        ('ANE: the same sweep, 2.6 % longer frames', os.path.join(ANE_AUDIO, 'sfx-fire-sweep.mp3'), 0, None),
    ]
    fig, axes = plt.subplots(3, 2, figsize=(12.5, 9.4), dpi=100)
    fig.patch.set_facecolor(BG)
    for ax, (title, path, start, length) in zip(axes.flat, panels):
        x = decode(path, start, length)
        f, t, s = signal.spectrogram(x, RATE, nperseg=1024, noverlap=768)
        db = 10 * np.log10(s + 1e-12)
        ax.pcolormesh(t, f / 1000, db, shading='auto', cmap='magma', vmin=db.max() - 70, vmax=db.max())
        ax.set_ylim(0, 8)
        ax.set_facecolor(BG)
        ax.set_title('%s  (%.2f s)' % (title.replace('$', r'\$'), len(x) / RATE), color=FG, fontsize=9.5,
                     loc='left')
        ax.tick_params(colors=DIM, labelsize=8)
        for sp in ax.spines.values():
            sp.set_color(DIM)
        ax.set_ylabel('kHz', color=DIM, fontsize=8)
        ax.set_xlabel('s', color=DIM, fontsize=8)
    fig.suptitle('The menu music changes from a two-voice beeper tune to a three-channel AY tune; the effects are '
                 'the same code and sound alike', color=FG, fontsize=12, x=0.01, ha='left')
    fig.text(0.01, 0.005, 'spectrograms (1024-point windows, 70 dB range) of the mp3s in nether-earth/docs/audio '
             'and docs/audio; python3 tools/fig_diff_res_sound.py spectra', color=DIM, fontsize=8)
    fig.tight_layout(rect=(0, 0.02, 1, 0.97))
    path = args.out or os.path.join(OUT, 'res-sound-spectra.png')
    fig.savefig(path, facecolor=BG)
    print(path)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('what', choices=['where', 'spectra', 'all'])
    p.add_argument('--out')
    args = p.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for w in (['where', 'spectra'] if args.what == 'all' else [args.what]):
        globals()['cmd_' + w](args if args.what != 'all' else argparse.Namespace(out=None))


if __name__ == '__main__':
    main()
