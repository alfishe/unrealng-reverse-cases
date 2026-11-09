#!/usr/bin/env python3
"""Doc 01's figures: sheets of the screenshots in docs/img/play (kit/screen_shot.py at scale 2, 512 x 384), each
labelled with its recording and frame, and the play screen with every part numbered.

    python3 tools/fig_design.py screens|playscreen|moments|variations|editor|halloffame|all

Every sheet is 1050 pixels wide: four screens a row at the Spectrum's own size (256 x 192, the PNG halved), the
caption under each. The play screen is one screenshot at scale 2 with numbered marks and a legend. Writes
docs/img/design/<name>.png.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CASE = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(CASE, '..', '..', 'kit'))
import kitlib as K  # noqa: E402

PLAY = os.path.join(CASE, 'docs', 'img', 'play')
OUT = os.path.join(CASE, 'docs', 'img', 'design')
WIDTH = 1050
GAP = 5

SHEETS = {
    'screens': ('Every screen of Video Pool, from the attract sequence to the hall of fame', [
        ('m1-0300-attract-logo', '1. attract: the OCP banner rolls in', 'm1 300'),
        ('m1-0900-attract-signature', '2. attract: the pen writes the signature', 'm1 900'),
        ('m1-1500-attract-press-key', '3. attract: "press any key"', 'm1 1500'),
        ('m1-4620-menu', '4. the main menu', 'm1 4620'),
        ('m1-5190-variations', '5. the variations page', 'm1 5190'),
        ('m1-5550-redefine-left', '6. redefine keys', 'm1 5550'),
        ('m1-6420-editor', '7. the table editor', 'm1 6420'),
        ('w1-0660-frame1', '8. "FRAME 1" before the rack', 'w1 660'),
        ('w1-1060-aim-power', '9. play: the aim, the power bar', 'w1 1060'),
        ('p2-1800-player2-frame1', '10. two players: "PLAYER 2"', 'p2 1800'),
        ('w1-11800-game-over', '11. GAME OVER', 'w1 11800'),
        ('w1-12500-name-entry', '12. the name entry', 'w1 12500'),
        ('w1-14000-hall-of-fame', '13. the hall of fame', 'w1 14000'),
        ('m1-7998-small-pockets', '14. play on the small pockets', 'm1 7998'),
        ('j1-2245-menu-interface2', '15. the menu, Interface 2 ticked', 'j1 2245'),
        ('m1-5860-redefined-qwp', '16. keys redefined to Q W P', 'm1 5860'),
    ]),
    'moments': ('The key moments of a game, in the order a player meets them', [
        ('w1-0660-frame1', '1. the start: FRAME 1', 'w1 660'),
        ('p2-1950-racking', '2. the balls roll into the rack', 'p2 1950'),
        ('w1-1060-aim-power', '3. the first aim', 'w1 1060'),
        ('w1-1122-break-contact', '4. the break: the cue ball hits', 'w1 1122'),
        ('w1-1140-break-spread', '5. the pack spreads', 'w1 1140'),
        ('w1-3990-pot-score', '6. a pot is scored', 'w1 3990'),
        ('w1-4050-frame2', '7. frame cleared: FRAME 2', 'w1 4050'),
        ('f1-1000-cue-to-pocket', '8. the cue ball runs to a pocket', 'f1 1000'),
        ('f1-1200-cue-respotted', '9. a life lost, the cue respotted', 'f1 1200'),
        ('f1-2940-last-shot', '10. the last shot: "last shot"', 'f1 2940'),
        ('f1-3050-shots-out', '11. no pot in time: FOUL SHOT!', 'f1 3050'),
        ('w1-11800-game-over', '12. the third life gone: GAME OVER', 'w1 11800'),
    ]),
    'variations': ('The three rule variations: what each one punishes', [
        ('v1-0700-variations', '1. the variations page', 'v1 700'),
        ('w1-3990-pot-score', '2. standard: any ball, any pocket', 'w1 3990'),
        ('v1-1250-wrong-order', '3. variation 1: WRONG ORDER!', 'v1 1250'),
        ('v1-1350-pot-score', '4. ball 4 potted, a life to go', 'v1 1350'),
        ('v1-2550-variation2', '5. variation 2 chosen', 'v1 2550'),
        ('v1-3100-wrong-pocket', '6. variation 2: WRONG POCKET!', 'v1 3100'),
        ('v1-3250-score-150', '7. the wrong ball still scores', 'v1 3250'),
        ('v1-2443-menu-after-break', '8. the menu names the variation', 'v1 2443'),
    ]),
    'editor': ('The table editor: pick a ball, move it, drop it, play', [
        ('e1-0650-editor', '1. the editor, cursor at (128, 115)', 'e1 650'),
        ('e1-0700-cursor-on-ball1', '2. the cursor on ball 1', 'e1 700'),
        ('e1-0720-ball1-picked', '3. fire: ball 1 picked', 'e1 720'),
        ('e1-0760-ball1-moved', '4. ball 1 moved left to x 170', 'e1 760'),
        ('e1-0840-cursor-on-play', '5. dropped; the cursor on "play"', 'e1 840'),
        ('e1-0878-play', '6. "play": the aim on the edit', 'e1 878'),
        ('e1-1318-shot-done', '7. after the shot', 'e1 1318'),
        ('m1-6420-editor', '8. the editor in m1 (no pick)', 'm1 6420'),
    ]),
    'halloffame': ('GAME OVER to the hall of fame: a score of 2700 enters as "vp"', [
        ('w1-11800-game-over', '1. GAME OVER, score 002700', 'w1 11800'),
        ('w1-12500-name-entry', '2. "congratulations!": the grid', 'w1 12500'),
        ('w1-13300-name-vp', '3. "vp" typed, the cursor on "end"', 'w1 13300'),
        ('w1-14000-hall-of-fame', '4. the flags: vp second, bill out', 'w1 14000'),
        ('f1-4700-game-over', '5. f1: GAME OVER below the table', 'f1 4700'),
        ('f1-5500-menu', '6. f1: the menu after 250 + 500 frames', 'f1 5500'),
        ('w1-15000-menu', '7. w1: the menu again', 'w1 15000'),
        ('w1-16300-attract', '8. 30 s idle: the attract sequence', 'w1 16300'),
    ]),
}

# The play screen: the target (x, y) in Spectrum pixels of w1 frame 1060, where the numbered mark sits, the label
PLAYSCREEN = [
    ((20, 3), (20, -8), 'player 1 score x 10 (1up blinks for the player at the table), ScorePlayer1 $9F45'),
    ((112, 3), (112, -8), 'the hi score: the best of the hall of fame, x 10'),
    ((212, 3), (212, -8), 'player 2 score, ScorePlayer2 $9F47'),
    ((60, 12), (60, -8), 'the power bar in its box: grows while fire is held, Power $86BF'),
    ((162, 12), (162, -8), 'the frame number, FrameNumber $9F4B'),
    ((248, 12), (248, -8), 'shots left for this ball, ShotsLeft $9F4D ("last shot" blinks at 1)'),
    ((60, 28), (60, 28), 'the potted row: balls 1-6 parked or potted here (empty at a frame start)'),
    ((162, 28), (144, 28), 'the lives: one cue ball each, LivesLeft $9F4E (3 at the start)'),
    ((8, 44), (28, 44), 'pocket mark "x1": the pocket multiplier; the six marks turn one place a frame'),
    ((40, 108), (40, 92), 'the cue ball, placed at (40, 115)'),
    ((200, 104), (176, 88), 'the rack: balls 1-6 in a triangle, its point ball 1 at (190, 115)'),
    ((252, 130), (226, 156), 'the aiming cursor on the cushion line: the cue ball runs towards it'),
    ((128, 52), (100, 70), 'a middle pocket: a gap in the long cushion (large pockets here)'),
    ((12, 176), (40, 166), 'a corner pocket: a 45-degree channel between two cushions'),
]


def caption_font():
    return K.font(13)


def wrap(draw, text, font, width):
    lines, line = [], ''
    for w in text.split():
        if line and draw.textlength(line + ' ' + w, font=font) > width:
            lines.append(line)
            line = w
        else:
            line = (line + ' ' + w).strip()
    return lines + [line]


def sheet(name):
    title, shots = SHEETS[name]
    cols = 4
    cell_w = (WIDTH - GAP * (cols + 1)) // cols
    small, big = caption_font(), K.font(16)
    rows = (len(shots) + cols - 1) // cols
    cap_h = 52
    top = 34
    height = top + rows * (192 + cap_h + GAP) + 30
    image = Image.new('RGB', (WIDTH, height), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((GAP, 8), title, fill=K.TEXT, font=big)
    for i, (stem, text, where) in enumerate(shots):
        path = os.path.join(PLAY, stem + '.png')
        shot = Image.open(path).convert('RGB').resize((256, 192), Image.NEAREST)
        x = GAP + (i % cols) * (cell_w + GAP) + (cell_w - 256) // 2
        y = top + (i // cols) * (192 + cap_h + GAP)
        image.paste(shot, (x, y))
        lines = wrap(draw, text, small, 256)
        draw.text((x, y + 194), '\n'.join(lines[:2]), fill=K.TEXT, font=small, spacing=2)
        rec, frame = where.split()
        draw.text((x, y + 194 + 16 * min(2, len(lines))), f'{rec} frame {frame}', fill=K.DIM, font=small)
    draw.text((GAP, height - 22), 'Each screen at the start of the named frame of the recording (kit/screen_shot.py); '
              'recordings: WALKTHROUGH 6.0', fill=K.DIM, font=small)
    return image


def playscreen():
    shot = Image.open(os.path.join(PLAY, 'w1-1060-aim-power.png')).convert('RGB')  # 512 x 384
    small, big = K.font(13), K.font(16)
    top = 34 + 26
    legend_x = 512 + 26
    step = 33
    height = max(top + 384, 34 + len(PLAYSCREEN) * step) + 40
    image = Image.new('RGB', (WIDTH, height), K.BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((GAP, 8), 'The play screen: the HUD on rows 0-4, the table on rows 6-22, the pocket marks on rows 5 '
              'and 23', fill=K.TEXT, font=big)
    image.paste(shot, (10, top))
    for n, ((x, y), (mx, my), text) in enumerate(PLAYSCREEN, 1):
        tx, ty = 10 + 2 * x, top + 2 * y
        cx, cy = 10 + 2 * mx, top + 2 * my
        r = 9
        if (tx, ty) != (cx, cy):
            draw.line([cx, cy, tx, ty], fill=(250, 210, 40), width=2)
            draw.ellipse([tx - 3, ty - 3, tx + 3, ty + 3], fill=(250, 210, 40))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(250, 210, 40), outline=(0, 0, 0), width=2)
        label = str(n)
        tw = draw.textlength(label, font=small)
        draw.text((cx - tw / 2, cy - 8), label, fill=(0, 0, 0), font=small)
        ly = 34 + (n - 1) * step
        draw.ellipse([legend_x, ly, legend_x + 18, ly + 18], fill=(250, 210, 40))
        draw.text((legend_x + 9 - tw / 2, ly + 1), label, fill=(0, 0, 0), font=small)
        words, line, lines = text.split(), '', []
        for w in words:
            if draw.textlength(line + ' ' + w, font=small) > WIDTH - legend_x - 34:
                lines.append(line)
                line = w
            else:
                line = (line + ' ' + w).strip()
        lines.append(line)
        draw.text((legend_x + 26, ly + 1), '\n'.join(lines[:2]), fill=K.TEXT, font=small, spacing=1)
    draw.text((10, height - 24), 'w1 frame 1060 (the first aim of frame 1, power growing), kit/screen_shot.py at scale 2; '
              'positions from the code (docs 06, 08)', fill=K.DIM, font=small)
    return image


def main():
    which = sys.argv[1:] or ['all']
    if which == ['all']:
        which = list(SHEETS) + ['playscreen']
    os.makedirs(OUT, exist_ok=True)
    for name in which:
        image = playscreen() if name == 'playscreen' else sheet(name)
        path = os.path.join(OUT, name + '.png')
        image.save(path)
        print(f'{path}: {image.width} x {image.height}')


if __name__ == '__main__':
    main()
