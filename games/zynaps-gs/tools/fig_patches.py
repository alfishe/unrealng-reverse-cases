#!/usr/bin/env python3
"""Docs 03 and 09: the installer's patch places, code against screen: for each of the 31 places in Zynaps that
src/disk/install.asm rewrites (28 CALL/JP operands, 3 runs of NOPs), the original instruction, what it calls now,
and the screen at the first time a recording ran it, or "not reached".

    python3 tools/fig_patches.py --out docs/img/load/patch-sites.png

The first runs come from work/zgsA/r1-sites.json (r1, music mode, level 1, 4724 frames) and work/zgsA/fx2-sites.json
(fx2, effects only, level 1, 62931 frames); both were found with time_travel find_event (find exec, first hit). A hit
at tinframe 0 without a code page is a frame-boundary artefact of find_event and is not counted. The screens are
time_travel memory_at at that frame:tinframe on the instance holding the recording (work/zgsA/r1, work/zgsA/fx2).
"""
import argparse
import json
import os

from PIL import Image, ImageDraw

import zgslib as Z

K = Z.K
WORK = os.path.join(Z.CASE, 'work', 'zgsA')

# site, the original instruction (install.asm's EQU comment), what the installer makes of it, the group
SITES = [
    ('SiteTitle', '$B203', 'CALL CreditsPage', 'CALL TitleEntry: title module', 'title'),
    ('SiteTitleTune', '$B0BF', 'CALL $B446 (title tune)', 'CALL KeyWait', 'title'),
    ('SiteTitleLoop', '$B209', 'JP NC,MainLoopTitle', 'JP NC,TitleStub ($5B00)', 'title'),
    ('SiteGameStart', '$AF51', 'LD ($80B0),A', 'CALL GameStartHook: jingle', 'level'),
    ('SiteNextLevel', '$B075', 'LD DE,8', 'CALL NextLevelHook', 'level'),
    ('SiteRoundStart', '$B03E', 'CALL ClearHitGrid', 'CALL RoundStartHook: load', 'level'),
    ('SiteShipHit', '$9B51', 'JP KillPlayer', 'JP ShipHitHook: FX 8', 'ship'),
    ('SiteShipHitExplode', '$9BE6', 'CALL $A293', 'CALL StartExplosionQuiet', 'ship'),
    ('SiteSound2', '$9C77', 'CALL $B2F0, A=2', 'CALL ShotHook', 'ship'),
    ('SiteSound4', '$A31D', 'CALL $B2F0, A=4', 'CALL PodAppearsHook', 'ship'),
    ('SiteSound5', '$A226', 'CALL $B2F0, A=5', 'CALL NextWeaponHook', 'ship'),
    ('SiteSound6', '$A21F', 'CALL $B2F0, A=6', 'CALL WeaponOnHook', 'ship'),
    ('SiteObject12', '$9CA6', 'LD (IX+$12),A', 'CALL PlasmaLaunchHook', 'weapons'),
    ('SiteObjectA', '$9CFA', 'CALL PlaceAtPlayer', 'CALL MissileLaunchHook', 'weapons'),
    ('SiteObjectB', '$9D1F', 'CALL PlaceAtPlayer', 'CALL MissileLaunchHook', 'weapons'),
    ('SiteSound3', '$9EA5', 'CALL $B2F0, A=3', 'CALL PlasmaBounceHook', 'weapons'),
    ('Site95E7', '$95E7', 'LD HL,0', 'CALL SceneryBounceHook', 'weapons'),
    ('Site9823', '$9823', 'LD HL,0', 'CALL ArenaBounceHook', 'weapons'),
    ('SiteSound1', '$A1C4', 'CALL $B2F0, A=1', 'CALL EnemyFireHook', 'enemies'),
    ('SiteExplodeA', '$9FBE', 'CALL $A293', 'CALL ExplodeHook', 'enemies'),
    ('SiteExplodeB', '$A034', 'CALL $A293', 'CALL ExplodeHook', 'enemies'),
    ('SiteA0BA', '$A0BA', 'DEC (IY+$0D)', 'CALL BigEnemyHitHook', 'enemies'),
    ('SiteA0D5', '$A0D5', 'LD ($80E2),A', 'CALL BigEnemyDestroyedHook', 'enemies'),
    ('SiteSpriteA', '$9694', 'CALL PathOpAccelerate', 'CALL ObjectSoundStub', 'enemies'),
    ('SiteSpriteB', '$9747', 'CALL PathOpAccelerate', 'CALL ObjectSoundStub', 'enemies'),
    ('Site969D', '$969D', 'CALL DirectionTo', 'CALL AimPlayerHook', 'enemies'),
    ('Site9856', '$9856', 'LD (IY+$1B),1', 'CALL DiveHook', 'enemies'),
    ('Site9954', '$9954', 'LD L,(IY+0)', 'CALL SlotGoneHook', 'enemies'),
    ('Site9859', '$9859', "LD (IY+$1B),1's last byte", 'NOP', 'nop'),
    ('SiteA0BD', '$A0BD', 'CALL NZ,0', 'NOP NOP NOP', 'nop'),
    ('SiteSound0', '$ABF1', 'CALL $B2F0, A=0', 'NOP NOP NOP', 'nop'),
]
GROUPS = {'title': ((120, 170, 255), 'the title'), 'level': ((255, 200, 90), 'game and level start'),
          'ship': ((120, 220, 120), 'the ship'), 'weapons': ((90, 210, 220), 'weapons and bounces'),
          'enemies': ((255, 120, 120), 'enemies'), 'nop': ((170, 170, 170), 'beeper calls removed')}


def first_runs():
    out = {}
    for run in ('r1', 'fx2'):
        for name, (_addr, frame, tin) in json.load(open(os.path.join(WORK, f'{run}-sites.json'))).items():
            if frame is None or tin == 0:
                continue  # tinframe 0: find_event's frame-boundary artefact (no code page), not a run
            if name not in out or (run == 'r1' and out[name][0] != 'r1'):
                out[name] = (run, frame, tin)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--out', default=Z.out('load', 'patch-sites.png'))
    args = ap.parse_args()
    runs = first_runs()
    f, fs, fb = K.font(12), K.font(11), K.font(15)
    cols, cw, ch = 4, 222, 168
    rows = (len(SITES) + cols - 1) // cols
    top = 74
    W = cols * cw + 12
    im = Image.new('RGB', (W, top + rows * ch + 10), K.BACKGROUND)
    d = ImageDraw.Draw(im)
    reached = sum(1 for s in SITES if s[0] in runs)
    d.text((8, 6), f'The installer rewrites 31 places in Zynaps; {reached} ran in the recordings, '
                   f'{len(SITES) - reached} were not reached', fill=K.TEXT, font=fb)
    d.text((8, 28), 'cell: address, site; the original -> what it is now; the screen at the first run '
                    '(recording, frame, T-state)', fill=K.DIM, font=f)
    x = 8
    for g, (colour, label) in GROUPS.items():
        d.rectangle([x, 50, x + 10, 60], fill=colour)
        d.text((x + 14, 48), label, fill=K.TEXT, font=f)
        x += 22 + int(d.textlength(label, font=f))
    for i, (name, addr, was, now, group) in enumerate(SITES):
        cx, cy = 6 + (i % cols) * cw, top + (i // cols) * ch
        colour = GROUPS[group][0]
        d.rectangle([cx, cy, cx + cw - 8, cy + ch - 8], outline=colour)
        d.text((cx + 5, cy + 3), f'{addr} {name[4:] if name.startswith("Site") else name}', fill=colour, font=f)
        d.text((cx + 5, cy + 19), was, fill=K.DIM, font=fs)
        d.text((cx + 5, cy + 33), '-> ' + now, fill=K.TEXT, font=fs)
        if name in runs:
            run, frame, tin = runs[name]
            scr = Z.cached(os.path.join(WORK, run), frame, tinframe=tin)
            thumb = Z.render(scr, 1).resize((128, 96), Image.LANCZOS)
            im.paste(thumb, (cx + 5, cy + 50))
            d.text((cx + 138, cy + 54), run, fill=K.TEXT, font=f)
            d.text((cx + 138, cy + 70), f'f{frame}', fill=K.DIM, font=f)
            d.text((cx + 138, cy + 86), f'T{tin}', fill=K.DIM, font=f)
        else:
            d.rectangle([cx + 5, cy + 50, cx + 133, cy + 146], outline=(70, 70, 80))
            d.text((cx + 22, cy + 90), 'not reached', fill=(150, 150, 150), font=f)
    im.save(args.out)
    print(args.out, im.size, reached, 'reached')


if __name__ == '__main__':
    main()
