# game

**What it is.** The texts of the game: Zynaps's messages (title pages, the selections, the key definition, the
banner, the high-score entry) and its high-score table. They are the 48K's except one.

**The files.** [`src/res/text/messages.msg.txt`](../../src/res/text/messages.msg.txt) (`$82EE-$8515`, one message a
line with its print codes) and [`src/res/text/hiscores.hsc.txt`](../../src/res/text/hiscores.hsc.txt) (`$8261`);
the format: [`src/res/text/README.md`](../../src/res/text/README.md). All English.

## What the GS changed

Message 21, the credits page: the 48K's

```text
MUSIC
STEVE TURNER
```

is now

```text
PRESS
1,2,3 & FIRE
```

at the same places and lengths (rows 16 and 17, columns 13 and 10: "PRESS" and "MUSIC" are both 5 characters,
"1,2,3 & FIRE" and "STEVE TURNER" both 12). The rest of the file is byte for byte the 48K's. The keys are the title's: 1 one player, 2 two players, 3 the key definition, then fire to start
(`MenuKeys`, [5](../05-controls.md)). The figure: [`img/compare/credits.png`](../img/compare/credits.png).

## The texts as shown

| Message | Text |
| ---: | --- |
| 13 | `KEYBOARD  DEFINITION`, then `FIRE`, `UP`, `DOWN`, `LEFT`, `RIGHT` (14-18) and the key names `CS`, `SS`, `SP`, `EN` (9-12) |
| 19 | `SELECTIONS`, `1 PLAYER`, `2  PLAYERS` |
| 20, 21 | `BY` `DOMINIC ROBINSON`, the Hewson logo, `GRAPHICS` `STEVE CROW` `DOMINIC ROBINSON`, `PRESS` `1,2,3 & FIRE`, `COPYRIGHT` `HEWSON 1987` |
| 24 | `PREPARE FOR COMBAT`, `PLAYER n` |
| 25-27 | `ROLE OF HONOUR`, `PLAYER n`, `UNRANKED`, `ENTER YOUR INITIALS` |
| table | `EGO 68000`, `DFR 25000`, `BAV 10000`, `HNR 5000`, `BMR 1000` |

The keyboard reader's key order at `$8199`, `ZXCVASDFGQWERT1234509876POIUY`, is a table, not shown.
