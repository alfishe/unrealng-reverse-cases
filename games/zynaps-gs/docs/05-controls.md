# 5. Controls

What this covers: the options menu (its visible and hidden keys), the title keys, the play controls and the
developer switch. The runs it rests on: the fresh boot `work/stage2/menu/` (`menu-fresh.szx`, keys 0, 8, T, 1, then
2 and fire on the title), stage 1's menu runs (`work/stage1/x1/options-menu.szx`) and the h2 plays (9).

## 5.1 The options menu

The boot shows the loading screen, then the options menu, ZYNAPS OPTIONS (`src/disk/menu/`, run in place at `$6D60`
inside Trush block 4, before the installer). Its key loop (`KeyLoop`) reads row `$F7FE` (keys 1-5) and row `$EFFE`
(0, 8, 7, 6); after an option key it draws the menu again and waits 10 frames. The options are bytes the menu keeps
or bytes in the not yet installed code it toggles directly; key 1 or 2 writes the rest (`Start`) and goes on to the
installer.

| Key | Item | What it changes |
| --- | --- | --- |
| 1 | START MUSIC & EFFECTS | `EffectsOnly` = 0: the level modules and the 10 in-game FX ([9](09-sound.md)) |
| 2 | START ONLY EFFECTS | `EffectsOnly` = 1: no module in play, 21 FX, the 13 effects-only sounds on |
| 3 | INFINITE ROUNDS (YES at the start) | `JR` over the `JR NC` at `$B218` (MainLoopEnd): the game is never over |
| 4 | TURBO LOADER (YES) | the loader's `TurboTest`: its own sector reader on TR-DOS's FDC routines (each sector retried until it reads clean) or TR-DOS's function 5 |
| 5 | SATURNS (YES) | `OptionSaturns`: FX 21 loaded and SaturnSound on (effects only) |
| 6 | SHOOTING (NORMAL / DISABLED / CHANNEL) | `OptionShooting`: the laser's sound through the firmware's own channel choice, none, or channel 1 through the gate |
| 7 | EFFECTS TIMER (0-9, 2 at the start) | the gate's length: a gated sound is dropped while the countdown since the last one runs |
| 0 | not listed | shows the two hidden lines and turns on key 8 and the level keys |
| 8 | INFINITE LIFE (hidden; NOP at the start) | at the start: `RET` over the `RET NZ` at `$9B50`, so the ship is never killed |
| Q W E R T, Y U I O P, A S | SELECT LEVEL!!! (hidden) | levels 1-5, 6-10, 11, 12: `LD B,n` over `LD B,(HL)` / `INC B` at `$B073` |

**Key 0.** `Reveal` writes `$16` (AT) over the zero that ends the menu's text, so `PrintText` goes on into the two
lines after it (row 13, column 4: "8. INFINITE LIFE....." and "Q-P,A-S. SELECT LEVEL!!!"), points key 8's jump at
`InfiniteLifeKey` and the no-key jump at `LevelKeys`. Without key 0, keys 8 and Q-S do nothing: stage 1 pressed them
on their own and saw no change. The figure: [img/compare/menu-hidden.png](img/compare/menu-hidden.png).

**SELECT LEVEL.** The level key writes `LD B,n` into SetLevelStart (`$B073`), where the 48K reads the next level from
the level order. SetLevelStart runs at the game start and after every level done, so the game starts on level n and
every level after it is n again: the conversion's way to practise one level. Proved on a fresh boot with keys 0, T, 1
(`work/stage2/menu/b3-cpu.bin`): `$B073` = `06 05`, the driver's Level = 5 (it loaded level 5's module), and the
player record's level index stayed 0. The play: [img/compare/select-level.png](img/compare/select-level.png).

**What the menu does not show.** The level select has no value on screen, and nothing undoes it but a new boot.

## 5.2 The title and play

The title pages are Zynaps's (the credits page now says "PRESS 1,2,3 & FIRE", [texts/game.md](texts/game.md)):
1 one player, 2 two players, 3 the key definition (`MenuKeys` `$A76F`), then fire starts the game: the Kempston fire
(it then plays with the Kempston) or the defined fire key. In play: the joystick or the defined keys, key 4 pauses
(CheckPauseAndEnd). These are the 48K's controls, unchanged; the 48K case documents the decoding.

## 5.3 The developer switch

Zynaps's switch Invulnerable at `$FFD7` (0 on the tape) still works in the GS: with POKE 65495,1 the ship is never
hit. The GS installer's stubs end at `$FFD1`, below it, and the menu's INFINITE LIFE does not use it. The h2 plays
(9.4) ran with it set: no ShipHitHook in 60000 frames; with it clear, 8 in 4000.
