#!/usr/bin/env python3
"""The controls as pictures (docs/05-controls.md): the keyboard map and the steering accumulators.

    python3 tools/fig_keys.py

- docs/img/controls/keymap.png: the 40 keys of the 48K keyboard, each with what Elite does with it, coloured by the
  key byte the interrupt's ScanKeyboard sets for it (KeyTable `$FF58`: KeyScreens `$FC08`, KeySteer `$FC09`,
  KeyViews `$FC0A`, KeyCombat `$FC0B`, KeyChart `$FC0C`, KeyDigits `$FC0F`); grey keys set no bit (Z, V) or only
  the character in KeyCode (the letters typed on the charts and in the name).
- docs/img/controls/steering.png: ReadControls `$FE01` run as the code says, frame by frame: the roll accumulator
  while N is held for 40 frames and then released, with damping (option D, bit 3), with recentring (option R,
  bit 2) and with neither; the pitch the same with X; the speed with SPACE then SYMBOL SHIFT. The rate the flight
  loop takes (CopyRates) is the accumulator's high byte.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtplot as P  # noqa: E402

ROWS = [['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
        ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
        ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'ENTER'],
        ['CAPS', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'SYM', 'SPACE']]
# key: (key byte, what it does) from KeyTable and the key bytes' annotations (src/game/keyboard.asm)
KEYS = {
    'ENTER': ('KeyScreens', 'inventory'), 'L': ('KeyScreens', 'status'), 'K': ('KeyScreens', 'market\nprices'),
    'P': ('KeyScreens', 'data on\nsystem'), 'O': ('KeyScreens', 'short\nrange chart'),
    'I': ('KeyScreens', 'galactic\nchart'), '0': ('KeyScreens', 'joystick\nfire'), 'Y': ('KeyScreens', 'cloak'),
    'N': ('KeySteer', 'roll\nleft'), 'M': ('KeySteer', 'roll\nright'), 'X': ('KeySteer', 'climb'),
    'S': ('KeySteer', 'dive'), 'SPACE': ('KeySteer', 'faster'), 'SYM': ('KeySteer', 'slower'),
    '1': ('KeyViews', 'front view\n(docked:\nlaunch)'), '2': ('KeyViews', 'rear view\n(docked:\nbuy)'),
    '3': ('KeyViews', 'left view\n(docked:\nsell)'), '4': ('KeyViews', 'right view\n(docked:\nequip)'),
    'H': ('KeyViews', 'hyper-\nspace'), 'G': ('KeyViews', 'galactic\n(with H)'), 'J': ('KeyViews', 'jump\ndrive'),
    'CAPS': ('KeyViews', 'pause'),
    'A': ('KeyCombat', 'fire'), 'T': ('KeyCombat', 'target\nmissile'), 'F': ('KeyCombat', 'fire\nmissile'),
    'U': ('KeyCombat', 'unarm\nmissile'), 'E': ('KeyCombat', 'E.C.M.'), 'W': ('KeyCombat', 'energy\nbomb'),
    'Q': ('KeyCombat', 'escape\npod'), 'C': ('KeyCombat', 'docking\ncomputer'),
    'B': ('KeyChart', 'cursor\nhome'), 'D': ('KeyChart', 'distance'), 'R': ('KeyChart', 'find\nplanet'),
    '9': ('KeyDigits', 'Sinclair\nup'), '5': ('KeyDigits', 'Cursor\nleft'), '8': ('KeyDigits', 'Cursor right\nSinclair\ndown'),
    '6': ('KeyDigits', 'Cursor down\nSinclair\nleft'), '7': ('KeyDigits', 'Cursor up\nSinclair\nright'),
}
BYTE_COLOUR = {'KeyScreens': P.READ, 'KeySteer': P.EXEC, 'KeyViews': (0.95, 0.75, 0.25), 'KeyCombat': P.HOT,
               'KeyChart': (0.75, 0.55, 0.95), 'KeyDigits': (0.45, 0.85, 0.85)}
BYTE_ADDR = {'KeyScreens': '$FC08', 'KeySteer': '$FC09', 'KeyViews': '$FC0A', 'KeyCombat': '$FC0B',
             'KeyChart': '$FC0C', 'KeyDigits': '$FC0F'}


def keymap():
    fig, ax = P.figure(15, 6.2)
    for r, row in enumerate(ROWS):
        for c, k in enumerate(row):
            x, y = c + 0.25 * r, -r
            byte, what = KEYS.get(k, (None, ''))
            colour = BYTE_COLOUR.get(byte, (0.3, 0.3, 0.35))
            ax.add_patch(P.plt.Rectangle((x, y), 0.92, 0.88, facecolor=colour, edgecolor=P.DIM, alpha=0.85))
            ax.text(x + 0.06, y + 0.8, k, fontsize=9, fontweight='bold', va='top', color='black')
            ax.text(x + 0.46, y + 0.34, what, fontsize=7, ha='center', va='center', color='black')
    ax.set_xlim(-0.1, 11.0)
    ax.set_ylim(-3.2, 1.0)
    ax.set_aspect('equal')
    ax.axis('off')
    handles = [P.plt.matplotlib.patches.Patch(color=BYTE_COLOUR[b], label='%s %s' % (b, BYTE_ADDR[b]))
               for b in BYTE_COLOUR]
    handles.append(P.plt.matplotlib.patches.Patch(color=(0.3, 0.3, 0.35), label='no bit (Z, V; the letters only '
                                                                                  'type on the charts)'))
    ax.legend(handles=handles, ncol=4, fontsize=8, loc='upper center', bbox_to_anchor=(0.5, -0.02))
    ax.set_title('The keys and the key byte the interrupt sets for each: 1-4 and six letters pick the view or the '
                 'screen, N M X S steer,\nSPACE and SYMBOL SHIFT set the speed, the top row\'s letters fight', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/controls/keymap.png')


def step(word, plus, minus, add, fall, limit, recentre, damping):
    """one frame of ReadControls on a sign and magnitude word (bit 15 the sign)"""
    sign, mag = word >> 15, word & 0x7FFF
    if plus or minus:
        want = 0 if plus else 1
        if mag == 0 or sign == want:
            sign, mag = want, min(mag + add, limit - 1)
        elif recentre:
            mag = 0
        else:
            mag = max(mag - add, 0)
    elif damping:
        mag = max(mag - fall, 0)
    return (sign << 15) | mag if mag else 0


def signed(w):
    return -(w & 0x7FFF) if w >> 15 else w


def steering():
    fig, axes = P.figure(15, 4.6, nrows=1, ncols=3)
    frames = range(90)
    for ax, (name, add, fall, limit) in zip(axes[:2], (('roll (N held)', 0xFF, 0x3C, 0x1000),
                                                         ('pitch (X held)', 0x66, 0x24, 0x1000))):
        for label, rec, damp, colour in (('damping (D)', False, True, P.EXEC), ('neither', False, False, P.READ)):
            w, ys = 0, []
            for f in frames:
                held = f < 40
                w = step(w, held, False, add, fall, limit, rec, damp)
                ys.append(signed(w) >> 8)
            ax.plot(list(frames), ys, label=label, color=colour, lw=2)
        w, ys = 0, []
        for f in frames:
            w = step(w, f < 40, 40 <= f < 44, add, fall, limit, True, False)
            ys.append(signed(w) >> 8)
        ax.plot(list(frames), ys, label='recentring (R), the other key tapped', color=P.HOT, lw=1.5, ls='--')
        ax.axvline(40, color=P.DIM, lw=0.8)
        ax.set_title('%s: +$%02X a frame up to $%04X;\nreleased, -$%02X a frame with damping' % (name, add, limit,
                                                                                               fall), fontsize=10)
        ax.set_xlabel('frame (the key released at 40)')
        ax.set_ylabel('the rate: the high byte')
        ax.legend(fontsize=7.5)
    ax = axes[2]
    s, ys = 0, []
    for f in frames:
        if f < 50:
            s = min(s + 0xA0, 0x1FFF)
        elif f < 70:
            s = max(s - 0xA0, 0)
        ys.append(s >> 8)
    ax.plot(list(frames), ys, color=P.EXEC, lw=2)
    ax.axvline(50, color=P.DIM, lw=0.8)
    ax.axvline(70, color=P.DIM, lw=0.8)
    ax.set_title('speed: SPACE +$A0 a frame (below $2000),\nSYMBOL SHIFT -$A0, kept when released', fontsize=10)
    ax.set_xlabel('frame (SPACE to 50, SYMBOL SHIFT 50-70)')
    ax.set_ylabel('SpeedRate')
    fig.suptitle('ReadControls run as the code says, once a frame in the interrupt: the flight loop takes the high '
                 'bytes at the start of each pass', fontsize=11)
    fig.tight_layout()
    P.save(fig, 'docs/img/controls/steering.png')


def main():
    keymap()
    steering()


if __name__ == '__main__':
    main()
