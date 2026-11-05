# 10. Gameplay logic

What this covers: what the GS conversion changes in the rules, the level order, the menu's options as code and what
the recordings showed. The recordings it rests on: work/stage2/h2 (play from a fresh boot with POKE 65495,1 through
ten levels, hooks counted, `summary.txt`), h2 mortal (the same, mortal), work/stage2/menu (SELECT LEVEL key T).

## 10.1 The rules

The rules are Zynaps's ([12](12-routine-reference.md), the 48K case's chapter 10): the conversion adds sound calls
([7.1](07-objects.md#71-where-the-sounds-sit)) and changes nothing the player can do, except through the menu's
options (10.3).

## 10.2 The levels

LevelOrder `$8003` holds the order of the 12 levels: 0, 1, 2, then 3-8 shuffled, then 9, 10, 11 (level = value + 1).
The play run had `[0, 1, 2, 6, 7, 5, 3, 8, 4, 9, 10, 11]`: levels 1, 2, 3, 7, 8, 6, 4, 9, 5, 10 were played. At
every level start NextLevelHook (`$B075`) keeps the level for the driver, and RoundStartHook (`$B03E`) loads its
module and FX from the disk when the level changed ([3](03-build-and-load.md), [9](09-sound.md)). LevelDone
`$B174` goes on to the next index; after 12 it wraps to 0.

## 10.3 The menu's options as code

| Option | Default | What it writes | Effect in play |
| --- | --- | --- | --- |
| INFINITE ROUNDS (key 3) | YES | JR (`$18`) over the JR NC at `$B218` (MainLoopEnd) | after every life lost or level, the next round: the game is never over |
| INFINITE LIFE (hidden key 8) | NOP | RET (`$C9`) over the RET NZ at `$9B50` (PlayerHit) | the ship is never killed |
| SELECT LEVEL (hidden keys Q-P, A, S) | - | LD B,n (`$06 n`) over LD B,(HL) / INC B at `$B073` | every level start, the first and each after a level done, is level n |
| TURBO LOADER (key 4) | YES | the loader's TurboTest operand | the level loads |
| SATURNS (key 5) | YES | SaturnsOption | FX 21 on path 1 ([7.2](07-objects.md#72-path-sounds)) |
| SHOOTING (key 6) | NORMAL | ShootingOption | the laser's sound: normal, none, or on its own channel |
| EFFECTS TIMER (key 7) | 2 | the gate's two operands | the time between effects |

The end codes ([4](04-game-loop.md)): 1 a life lost (PlayerDied, carry when no lives are left), 2 a level done
(LevelDone), 3 and 4 an abort (AbortGame). Only the first two return to MainLoopEnd: AbortGame (key Q in the pause)
resets the stack and jumps to MainLoopTitle, so INFINITE ROUNDS does not stop an abort.

With SELECT LEVEL, Player1LevelIndex (`$7FA2`) still counts 0, 1, 2 ... but the level is n each time: the driver
loads level n's module (`img/compare/select-level.png`, key T, level 5: `$B073` = `06 05`).

## 10.4 What the recordings showed

- Immortal (POKE 65495,1, the 48K's test switch at `$FFD7`) the ship is never hit: ShipHitHook 0 times. Mortal: 8.
- The side weapons: plasma launched 3 times and bounced 3 times, the seeker 9 launches; the homing missile was not seen
  launching (why is open).
- The big enemy: hit 58 times on levels 7, 8, 9 and 5, destroyed once (level 5).
- Every count, hook by hook and level by level: [9.4](09-sound.md#94-where-the-game-makes-a-sound).
