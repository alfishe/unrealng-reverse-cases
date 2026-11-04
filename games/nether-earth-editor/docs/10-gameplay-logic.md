# 10. Gameplay logic

The edition's game is Nether Earth unchanged ([3.5](03-build-and-load.md#35-the-image-against-nether-earths)), so its
rules are those of [NE 10](../../nether-earth/docs/10-gameplay-logic.md). What is new on this tape is what the rules
start from: a saved game that a person, through the editor, wrote instead of `NewGameSetup`. This document covers
what the save format means for the rules: what a level can and cannot set, what the game checks when it loads one
(almost nothing), and what the eight saved games on the tape do with that freedom.

The evidence: the 9 425-byte blocks themselves (`work/edA/blocks/b7.bin` ... `b27.bin`, as text in
`src/res/levels/*.txt`), the `load` recording (one level loaded through `LoadGameBlocks`, played, saved), and the
`levels` run (all eight loaded and played 400 frames), all in [03](03-build-and-load.md).

## 10.1 What the format carries, and what not

The block is the memory `$D92B-$FDFB` ([3.6](03-build-and-load.md#36-the-saved-game)). It carries every byte the
rules read in play:

| Rules state | Where | Read by (NE) |
| --- | --- | --- |
| terrain, heights, object and ship marks | `Map` `$DD00` | robot moves, shots, capture (bit 6 on a door) |
| 48 robots: cell, position, parts, order, strength, timers | `Robots` `$DA00` | `WorldTurn`, the AI |
| 5 shots in flight | `Shots`, staged | `UpdateShot` |
| buildings: pads, factories, flags | `Buildings`, staged | drawing, construction |
| 28 capture points: door, owner and type, count | `Warbases` `$FD70`, `Factories` `$FD84` | `GameTurnEnd`'s capture loop |
| both sides' resources and building counts | `Resources` `$FD22`, `PlayerBuildings` `$FD3A`, `EnemyBuildings` `$FD42`, `EnemyResources` `$FD4A` | production, construction, `CheckGameEnd` |
| robot counts | `PlayerRobotCount` `$FD41`, `EnemyRobotCount` `$FD49` | the panel, the AI |
| the clock | `Clock` `$FD35` (minutes, hours, days) | `GameTurn`, `DailyProduction` |
| the ship | `ShipX` `$FD0E`, `ShipY` `$FD0D`, `Altitude` `$FD10` | the ship, landing, radar |
| the random seed | `RandomSeed` `$FD00` | everything random |

It does not carry the code, the tables of costs, heights and damage, the key table or the device choice (NE 3.6).
**So a level cannot change a rule**, only the position the rules start from. The levels confirm it: the edition's
code is NE's byte for byte, and `LoadGameBlocks` writes only the sum at `$5B00`, the block at `$D92B-$FDFB` and the
two copies back to `Shots` and `Buildings` (03, the `load` recording, frames 677-3026).

## 10.2 What the game checks: the sum, nothing else

`LoadGameBlocks` compares the 16-bit byte sum and goes to play (NE 3.6). It does not recount, validate or rebuild
anything but the radar (`RadarDirty` = 1, which `SaveGame` sets and all eight levels have). So every invariant that
`NewGameSetup` and play keep is the level author's job:

- **The counts.** `PlayerBuildings` / `EnemyBuildings` (warbases, then the six factory kinds) are recounted only by
  `CountBases` (`$BB09`) after a capture (NE 10.7). Until the first capture, production (NE 10.2) and the end test
  (NE 10.10) use the counts as loaded. In all eight saved games the counts agree with the capture points' owners,
  and the robot counts with the live robot slots (`python3 work/edA/counts.py`: "agree" for all eight; the numbers
  in [01 1.3](01-game-design.md#13-the-levels)). A level with `EnemyBuildings` warbases = 0 would be won at the first
  turn, whatever stands on the map; one with ours at 0, lost.
- **Map bit 6.** The anchor mark of a robot, a building or a shot. `levels.py` derives it from the objects, and
  every cell where the block disagrees is kept as a `cell` line. Two levels have bit 6 on cells no object occupies:
  Enemy At The Gates at (287,5), (420,12), (202,13), (263,15), and The Chase at (35,10), (35,13), next to its
  enemy robots. All six are block cells (types 2-10), so the ground is blocked there anyway. A robot's move probes
  anchors one cell around (NE 7, "the probes that test a move"), so these marks also stop moves into the cells next
  to them, and a shot landing next to one hits an anchor with no object (code reading, not recorded). They look like
  leftovers of objects the editor moved or removed.
- **Free robot slots.** A slot is free when `+$01` = 0 (NE 7). The game ignores the rest of a free record, and the
  levels keep leftovers there (`robot K raw` lines): a parts byte (`+$07`) in free enemy slots of seven levels (24
  in Double Frontline), and whole old records in our free slot 0 of Enemy At The Gates and slots 1-3 of The Chase.
  They do nothing until the slot is reused, which writes a new record over them (NE 10.8).
- **Orders.** A loaded robot keeps the order it was saved with; `SetOrder`'s check (an order 4 or 5 without the
  nuclear part becomes 0, NE 10.5) runs only when an order is given. The three enemy robots of Enemy At The Gates
  with orders 4 and 5 (slots 27, 39, 42) do have the nuclear part, so the levels stay within what play could reach.

## 10.3 Out-of-play capture points

A level has 28 capture points like the original, but most levels need fewer. The editor parks an unused point as
owner and type `$80`: bit 7 "destroyed", owner 0, type 0. It keeps the point's old door; in Jungle Of Stone and the
editor's save these are the original battle's doors, (97,3) for point 8 among them (NE 10.9). On the map such a
point has no building: the maps show it as a grey "x".

| Level | Points at `$80` | Their doors on open ground |
| --- | ---: | ---: |
| Enemy At The Gates | 6 | 6 |
| Break Through | 0 | 0 |
| Fortifications | 6 | 5 |
| The Chase | 25 | 20 |
| Jungle Of Stone | 26 | 21 |
| Double Frontline | 1 | 1 |
| The Slogan | 24 | 14 |
| the editor's save | 26 | 26 |

(the door cell's terrain type 0 in the block's map; the rest lie under blocks.)

**The rule this meets.** NE's capture loop does not test bit 7 (NE 10.12): a robot that stands 144 turns on the door
of a destroyed point captures it, and `SetBaseOwner` turns it into a live **warbase** of the capturing side, counted
and paying 5 general a day. NE witnessed it on its own instance (point 8 `$80` → `$40`, NE 10.9 and 10.12). On these
levels it means:

- every `$80` door on open ground is an invisible warbase site. Any robot that stops there for 144 turns, ours or the
  enemy's, by order or by chance (an ADVANCE that ends there, a robot stopped by a fight), gives its side a warbase;
- in **The Chase**, point 2 (`$80`) has the same door as the enemy's warbase point 1, (487,8). A robot capturing that
  warbase stands on both doors, so both counts climb and both points change hands in the same turn: the capturing
  side gets two warbases, one of them invisible (from the capture loop, NE 10.7; not recorded);
- the enemy can win a base back the same way, so a level without factories is not as closed as its map looks.

This is the strongest rule effect of the format, and none of the levels seem to intend it.

## 10.4 The clock and the first day

All eight saved games have `Clock` = 0 0 0 (00:00, day 0) and `TurnFrames` = 0, and every level starts as a fresh
day: the first `DailyProduction` comes after 288 turns (about a minute, NE 10.1). In the `levels` run the clock read
02.15 to 03.20 after 400 frames (03.20 is 40 turns × 5 minutes; turns that take more than 10 frames give less), as on
a new game. So the starting resources of a level are what
the player has for the whole first minute. That is what sets the levels' pace:

- Jungle Of Stone (30 general against 99 of everything) and Enemy At The Gates (99 general only, 24 enemy robots on
  the way) are poor starts;
- Fortifications and The Slogan give us 99 of everything at once;
- the levels without factories (The Chase, Jungle Of Stone, The Slogan, the editor's save) pay only 5 general a
  warbase a day after that, so the starting stock is most of what either side will ever have, apart from captured
  `$80` warbases (10.3).

## 10.5 The variables that are only state

The rest of `$FD00-$FD6F` is display and sound state that the save carries because it lies in the range:
`PrintAddr`, `PrintAttr`, `MenuCursor`, `MenuParts`, `MenuResources`, `RadarPhase`, `RadarBlink`, `BassReturnPos`
and so on. Play redraws from the rules state (the `EnterPlay` path, NE 2.3), so these do not matter; `levels.py`
keeps them byte for byte only so the block rebuilds exactly. `Side` (`$FD51`) is 1 in all eight: a value
`WorldTurn` rewrites for each robot (NE 7). `RandomSeed` differs per level, so a level replays the same way from its
load only if the player's inputs are the same.

## 10.6 What the save showed in play

The `load` recording saved Enemy At The Gates again after 300 frames of play
([3.6](03-build-and-load.md#36-the-saved-game)). Against the level, 200 bytes differ: 146 in robot records, 46 map
cells (robots and shots moved, their bit 6 marks with them), `RandomSeed`, `Altitude`, `RadarBlink` and `Clock`. No
count changed and no capture point did: in 300 frames (30 turns) no capture can complete (144 turns).

## 10.7 Notes

- The editor (02, 05) is what writes these blocks; its own checks, if any, are the only guard the invariants of 10.2
  have.
- An editor wanting points out of play without the 10.3 effect would have to put their doors under blocks, as some
  of The Slogan's and Fortifications' are, or off the map.
