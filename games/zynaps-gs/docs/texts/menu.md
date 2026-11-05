# menu

**What it is.** The texts of the options menu, ZYNAPS OPTIONS: the title, the items 1-7, the credits of the
conversion and the two hidden lines, with the value words the menu writes into them. All English.

**The file.** The driver file in bank 1 at `$CC00`, run at `$7007` (`Text` in `src/disk/menu.ann`; the source is
the `DEFM` lines of [`src/disk/menu/menu.asm`](../../src/disk/menu/menu.asm)). `PrintText` prints them: `$16 r c`
a position, `$10 a` an attribute letter (`A` bright blue, `B` bright red, `C` bright magenta, `E` bright cyan, `F`
bright yellow, `G` bright white), 0 the end. The zero at `$7164` ends the text as shown; key 0 writes `$16` there,
and the two hidden lines after it print too ([5](../05-controls.md)).

## The original

As printed (row, column; the colour letter dropped):

| Row | Column | Text | Colour |
| ---: | ---: | --- | --- |
| 0 | 9 | `ZYNAPS OPTIONS` | red |
| 3 | 4 | `1. START MUSIC & EFFECTS` | cyan |
| 4 | 4 | `2. START ONLY EFFECTS` | cyan |
| 6 | 4 | `3. INFINITE ROUNDS...` + `YES` / `NOP` | white, value yellow |
| 7 | 4 | `4. TURBO LOADER......` + `YES` / `NOP` | white, value yellow |
| 9 | 4 | `5. SATURNS...........` + `YES` / `NOP` | white, value yellow |
| 10 | 4 | `6. SHOOTING.....` + `..NORMAL` / `DISABLED` / `.CHANNEL` | white |
| 11 | 4 | `7. EFFECTS TIMER.......` + a digit 0-9 (`2` at the start) | white, value yellow |
| 17 | 8 | `GAME ADAPTED BY:` | magenta |
| 18 | 11 | `MIKE BLUM` | cyan |
| 20 | 6 | `MUSIC & FX MIXED BY:` | magenta |
| 21 | 3 | `JOHN UNDERWOOD & DANGEROUS` | cyan |
| 23 | 2 | `COPYRIGHT (C)1997 ZX-MASTERS` | white |
| 13 | 4 | `8. INFINITE LIFE.....` + `YES` / `NOP` (hidden) | blue, value yellow |
| 14 | 4 | `Q-P,A-S. SELECT LEVEL!!!` (hidden) | blue |

"NOP" is the menu's word for "no" (three letters, like "YES"). The screen as shown and with the hidden lines:
[`img/compare/menu-hidden.png`](../img/compare/menu-hidden.png).
