# 8. HUD and text

What this covers: the panel, the fonts, the printers and every string of the GS conversion. The recordings it rests
on: work/stage1/screens (the title pages, the menu, level 1), work/stage2/menu (the menu with key 0, `m2-key8.png`).

## 8.1 What is the 48K's

The panel (the score, the lives, the weapon icons), the game's font ([`src/res/fonts`](../src/res/fonts/README.md),
`glyphs`) and its printer are Zynaps's, unchanged: PrintChar `$A321` with the print codes 0-6 (the attribute, ink,
paper, column, row, column and row moves), PrintString `$A401`, PrintMessage `$A423`, PrintBcd `$A43E`,
PrintPlayerScore `$A4AE`, DrawLives `$A4EF`, PrintKeyName `$A623`. Their description: the 48K case's chapter 8 and
[12](12-routine-reference.md).

## 8.2 The game's strings

The messages (`$82EE-$8515`, [`src/res/text/messages.msg.txt`](../src/res/text/messages.msg.txt)) and the
high-score table (`$8261`, [`hiscores.hsc.txt`](../src/res/text/hiscores.hsc.txt)) are the 48K's except message 21,
the credits page: "MUSIC / STEVE TURNER" became "PRESS / 1,2,3 & FIRE", at the same places and lengths. Every text:
[`texts/game.md`](texts/game.md); the figure: [`img/compare/credits.png`](img/compare/credits.png).

## 8.3 The options menu's printer

The menu (src/disk/menu.asm, [5](05-controls.md)) has a printer of its own. MakeFont `$6FA2` copies the 48 ROM's
character set into bank 7 (`$FD00`) with every row ORed with itself shifted right: a bold font. PrintText `$6EE9`
reads codes 32 and up as characters, `$10 a` as the attribute (the letters A, B, C, E, F, G: bright blue, red,
magenta, cyan, yellow, white), `$0D` as a new line, `$16 r c` as a position and 0 as the end. ShowValues `$6FB7`
writes the options' values (YES / NOP, the SHOOTING word, the timer digit) into Text before each print. Key 0
writes `$16` over the zero at TextEnd `$7164`, so the two hidden lines print. Every text: [`texts/menu.md`](texts/menu.md);
the figure: [`img/compare/menu-hidden.png`](img/compare/menu-hidden.png).

## 8.4 The other texts

The disk's catalogue names and the BASIC: [`texts/disk.md`](texts/disk.md). The 13 modules' names and sample texts
(the credits inside them): [`texts/modules.md`](texts/modules.md).
