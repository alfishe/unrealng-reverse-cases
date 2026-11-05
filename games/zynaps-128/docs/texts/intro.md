# Zynaps 2 in 1: the texts of the intro

The intro is block 1 (`$6000`, Hrust 1, unpacked in place; [03](../03-build-and-load.md) 3.4). It shows three
pictures with an attribute-row reveal; every text in it is part of a picture (bitmap and attributes), not a string:
a scan of the unpacked block, the STarKos player and the page-4 engine for runs of printable ASCII finds no text
(only graphics bytes and the player's `SK10` song tag). All of it is English; no translation is needed.

Positions are character rows (0-23) and columns (0-31), measured on the screen dumps. The pictures alone, as
taken from memory in stage 1: `work/media/scr-title.scr`, `scr-options.scr`, `scr-hewson.scr`.

## 1. The title picture

Recording `work/stage1/c1/session.ttd` frame 2290 ([03-title](../img/compare/03-title.png), right;
`work/stage1/screens/05-title.png`). New in the 128K version.

| Where | Text |
| --- | --- |
| top left, the logo (drawn) | `ZYNAPS` |
| bottom left, under the frame | `RVS.M.STAWICKI©` (the artist's signature) |

## 2. The options screen

Frame 2740 ([04-options](../img/compare/04-options.png), the middle panel; `work/stage1/screens/06-options.png`).
New in the 128K version. The line in row 23 is the menu: `0` starts, `1` and `2` toggle their option, shown by
inverting the option's attributes (`work/stage1/screens/06b-options-both-on.png`).

| Row | Text |
| --- | --- |
| 0-10 | the `ZYNAPS` logo (drawn) |
| 11 | `WITH AY` |
| 12 | `48/128K  MUSIC & SFX` |
| 14 | `1987 (C) HEWSON` |
| 15 | `2018 (R) GOODBOY&TIBOH` |
| 17 | `CONTROL IN THE GAME MENU` |
| 18 | `1&2 SELECT 1 OR 2 PLAYER` |
| 19 | `3 REDEFINE KEYS` |
| 20 | `4 HIGH SCORE` |
| 21 | `FIRE START GAME` |
| 23 | `0.START  1.INF.LIVES  2.K-MOUSE` |

As one block, the layout kept:

```
      WITH AY
48/128K  MUSIC & SFX

1987 (C) HEWSON
2018 (R) GOODBOY&TIBOH

     CONTROL IN THE GAME MENU
 1&2 SELECT 1 OR 2 PLAYER
   3 REDEFINE KEYS
   4 HIGH SCORE
FIRE START GAME

0.START  1.INF.LIVES  2.K-MOUSE
```

Meaning of the abbreviations (English): `INF.LIVES` infinite lives (the lives never drop), `K-MOUSE` a Kempston
mouse moves the ship (a button fires). `(R)` is written as on the screen; it marks the 2018 rework by goodboy and
tiboh.

## 3. The Hewson picture

Frame 3290 ([05-hewson-picture](../img/compare/05-hewson-picture.png), right; `work/stage1/screens/07-hewson.png`).
The same picture as the 48K original's loading screen (the figure measures the differences: the top pixel line, the
tape's four-arrow mark, six stars' colours; no text differs).

| Where | Text |
| --- | --- |
| top left, the logo (drawn) | `ZYNAPS` |
| under the logo, handwriting | `By Dominic Robinson` |
| top right corner, small | `Jmp` (also in the 48K picture) |
| bottom right plate | `HEWSON` |

Then the loader loads block 2 and starts the game: its texts are in [game.md](game.md).
