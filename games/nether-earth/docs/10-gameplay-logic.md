# 10. Gameplay logic

Nether Earth is a war of production. Each side starts with warbases and 20 general resource. A day of game time
pays out per building owned, and robots built from parts capture more buildings. The player never fights directly:
the robots walk, look, shoot and capture on their own, steered by orders. The enemy (the "Insignians") uses the
same robots, the same costs and the same capture rule. Its commander is a few lines of random choices
(`EnemyCommander` `$B7F4`). A side with no warbase left has lost.

Evidence:

- the code of `src/game/main.asm` (the routines named below);
- `work/deep`: the bot's 36046-frame game from the menu snapshot `work/play/start.szx`, 11.8 game days. The bot
  is `tools/bot.py play --record`.
  - L1 counts.
  - TTD `memory_at` samples of `$FD00`-`$FDFF` and the robot records every 120 frames, taken by
    `tools/course_chart.py sample`. The instance was only read: no seek, no resume.
- `work/docC/fight`: the same bot on an own instance for 19829 frames. It replays `work/deep` frame for frame:
  `FireShot` and `SoundEffect` first run at frames 18679 and 18680, `GameTurn` at frame 61, in both.
  - Its access trace of frames 18679-18712 shows a shot and its hit.
  - Its `memory_at` reads show the robot strengths.
- the region agents' notes and experiments on own instances (`work/ann/r1.md`-`r5.md`): the game ends, the full
  slots, the nuclear blast, the construction menu with poked resources, the target bug.

## 10.1 The game turn and the clock

The play loop (`PlayLoop` `$A69A`, [4.3](04-game-loop.md)) runs one game turn a pass:

1. read the controls;
2. move the ship;
3. `WorldTurn` (`$B0CA`);
4. draw the view;
5. `GameTurn` (`$AD62`).

The menus call `WorldTurn` and `GameTurn` between key presses too, so the war goes on while the player chooses
([5.5](05-controls.md)). Only the construction menu stops the world: it installs `StartInterrupt` and runs no
turns.

`GameTurn`, step by step:

1. `Random` (`$D358`): one step of the random generator a turn, whatever else draws numbers.
2. The clock (`$FD35` minutes, `$FD36` hours, `$FD37` days): +5 minutes. 60 minutes make an hour, 24 hours a day;
   a new day calls `DailyProduction` (`$AE38`, 10.2).
3. The clock print ([8.5](08-hud-and-text.md)).
4. `CheckGameEnd` (`$AE6B`, 10.10).
5. The capture loop over the 28 capture points (10.7).
6. The pacing (`TurnPace` `$AE1D`): wait until `PlayInterrupt` has counted 10 frames in `TurnFrames` (`$FD34`)
   since the last turn, then clear it.

A turn is at least 10 frames (0.2 s), an hour 12 turns, and a day 288 turns: at least 2880 frames, 57.6 s. In
`work/deep` 3414 turns took 36046 frames, 10.56 frames a turn: some turns'
work takes more than 10 frames.

## 10.2 Production and resources

`DailyProduction` runs `ProduceSide` (`$AE4E`) for both sides, then reprints the panel:

- general += 5 × warbases;
- each part resource += 2 × the factories of its kind;
- every resource stops at 99 (`AddCapped` `$AE62`).

Each side has 7 resources: general, electronics, nuclear, phasers, missiles, cannon, chassis. Ours are at
`Resources` (`$FD22`) and the enemy's at `$FD4A`; the building counts are at `$FD3A` and `$FD42`, in the same order
(warbases, then the six factory kinds). It ran 11 times in `work/deep`, once a game day.

At the start our side has 1 warbase and the enemy 3, and both have 20 general and nothing else (`work/deep` frame
120). So the enemy earns 15 general a day to our 5 until factories change hands.

## 10.3 Construction: costs and limits

The construction menu opens when the ship sinks onto the pad of our warbase. This takes three things:

- altitude 15;
- the door cell 4 rows below the pad free of map bit 6;
- the three cells of the row under the door free of bit 6.

The menu itself is in [5.4](05-controls.md). Its rules, from `ConstructionMenuLoop` (`$CA0F`), `RefundPart`
(`$CAC1`) and `StartRobot` (`$CB52`):

| Part | Bit | Cost (`PartCosts` `$CAF0`) | Paid from (`$CAF8`) | Height (`PartHeights` `$D7B4`) |
| --- | --- | --- | --- | --- |
| bipod | 0 | 3 | chassis | 11 |
| tracks | 1 | 5 | chassis | 7 |
| anti-grav | 2 | 10 | chassis | 8 |
| cannon | 3 | 2 | cannon | 6 |
| missiles | 4 | 4 | missiles | 6 |
| phasers | 5 | 4 | phasers | 7 |
| nuclear | 6 | 20 | nuclear | 7 |
| electronics | 7 | 3 | electronics | 7 |

- A part pays from its own resource. The rest comes out of general; if general cannot cover it, the part is
  refused.
- The menu works on a copy of the resources (`MenuResources`). The copy goes back into `Resources` only on START.
- Exactly one chassis: choosing one refunds the chosen one first.
- At most three of the four weapon bits 3-6 (`MenuParts & $78` is never `$78`).
- START ROBOT needs a chassis and a weapon; electronics count as neither.
- A side has 24 robot slots: ours are `$DA00` + 16 × n for n = 0-23, the enemy's `$DB80` + 16 × n.

Our new robot stands on the warbase's door, facing down: `+$05` 4, `+$06` 5, order 0, strength 100, `+$0F` 1, so it
moves at the next turn. Its height `+$09` is the sum of its parts' heights. `work/deep` frame 360, the first robot:
`16 EF 16 00 09 00 00 09 04 11` (cell `$EF16`, column 22, row 9, bipod + cannon, height 17).

## 10.4 A robot's turn

```mermaid
flowchart TD
    U["UpdateRobot $B0FA"] -->|"+$0C = 0"| D["RobotDestroyed $B116<br/>wreck laid, dot erased, slot freed, recount"]
    U -->|"+$0C < 0: dying"| Y["+$0C + 1, bit 6 toggled<br/>4 turns"]
    U -->|"+$0C > 0"| S["RobotStep $B154"]
    S -->|"+$0A = 1: player on it"| Z["nothing"]
    S --> W["Side = +$0A bit 7; DEC +$0F<br/>not 0: wait"]
    W --> F["off the map; FreeDirections $B513 → C"]
    F -->|"+$0A = 2"| DC["RobotDirectControl $B450"]
    F --> V["SpotEnemies $B626 → E"]
    V -->|"opponent ahead"| A["move on if free;<br/>FindFreeShot + weapon pick → FireShot, stand"]
    V -->|"opponent to a side"| T["turn to it, +$06 = 2"]
    V -->|"none"| N["keep +$05 for +$06 steps while free,<br/>else SteerByOrder $B222, +$06 = 3-6"]
    A --> M["RobotMove $B20D: TurnOrStep $B471,<br/>SetStepDelay $B5F3, PlaceRobot"]
    T --> M
    N --> M
    DC --> M
```

`WorldTurn` first calls `EnemyCommander` (10.8). It then calls `UpdateRobot` for each of the 48 records whose
`+$01` is not 0 (ours first), then `UpdateShot` for each of the 5 shot records ([7.1](07-objects.md)). In
`work/deep` `UpdateRobot` ran 49165 times and took 9652 steps.

![WorldTurn in the frame of the first shot: work/docC/fight frame 18679:13500-18679:57000](img/routines/RobotStep.gif)

`python3 ../../kit/routine_anim.py --work work/docC/fight --window 18679:13500-18679:57000 --listing build/game.lst
--view buffer:D7D3:9x5 --pc B0CA-B7F3 --range D700-FFFF --pictures 80 --out docs/img/routines/RobotStep.gif`.

- The memory panel shows the robots' records at `$DA00`-`$DCFF` read one by one, and the map reads of
  `FreeDirections` and `SpotEnemies`.
- The view is the five shot records. At T 24670 an enemy robot's step fires: `FireShot` fills record 3 at `$D7EE`.
- `UpdateShot` moves the shots at the end of the turn.

**Step delays.** `SetStepDelay` reloads `+$0F` from `StepDelays` (`$B61D`), in turns per step. The column is the
locomotion: the lowest set bit of the parts `+$07`, so exactly one in every built robot. The row is the ground
height under the robot (`+$0D`):

| Ground | bipod | tracks | anti-grav |
| --- | --- | --- | --- |
| flat (0) | 6 | 4 | 3 |
| low (1-3) | 8 | 6 | 3 |
| high (4 and up) | 9 | 7 | 4 |

A turn of 90 degrees costs a step (`TurnOrStep`). A turn from right to left goes through down or up, so it costs
two steps.

**Movement thresholds.** `FreeDirections` tests the 2 × 2 footprint's next cells against the terrain type. It also
tests for object anchors (bit 6), and for the ship's cell (bit 7) when the ship is lower than the robot's top.

| Locomotion | Blocks from type | Ground heights it climbs |
| --- | --- | --- |
| bipod | `$08` | 0, 2, 3 |
| tracks | `$0C` | also 6 |
| anti-grav | `$0F` | also the types `$0C`-`$0E` |

Types `$0F` and above (tall blocks, buildings) stop every robot ([7.3](07-objects.md)).

**Vision.** `SpotEnemies` scans 8 cells in each direction, and in the facing direction 10 cells (12 with
electronics) on three parallel lanes. The first object on a lane ends it. Only an opponent (`+$0A` bit 7 differs)
with strength above 0 counts, so buildings, shots and friends hide what is behind them. The result E has the
direction bits in the `Input` order: 0 right, 1 left, 2 down, 3 up.

**An opponent ahead.** The robot moves on if it can. It fires if a shot record of its side is free
(`FindFreeShot` `$B6B8`: records 1-2 ours, 3-4 the enemy's) and it has a weapon:

1. `Random AND $38 AND` the parts chooses each of cannon, missiles and phasers with a coin flip.
2. The highest chosen fires: phasers 3, missiles 2, cannon 1 (`RobotWeaponPick` `$B1B7`).
3. Firing makes the robot stand this step: `+$05` = 0, `+$06` = 1.

So a robot fires its best weapon on half its chances, and a lone cannon fires only on half the turns that see an
opponent. With two shot records a side, at most two of its shots fly at once (plus the player's COMBAT MODE
shot).

## 10.5 Orders

`SteerByOrder` (`$B222`) picks a direction among the free ones C by the order `+$0B`. It runs only when the robot
has no opponent in sight and its course `+$06` is used up or blocked. The new course lasts 3-6 steps.

| Order | Name ([8.3](08-hud-and-text.md)) | Steering |
| --- | --- | --- |
| 0 | STOP AND DEFEND | stand; it still turns and fires at what it sees |
| 1 | ADVANCE n MILES | lean right: the order's direction with chance 3/4 when free, else a random free one other than the opposite (`RobotLeanTo` `$B326`). `+$0E` = miles × 2 counts the columns down (`StepPosition` `$B4B9`: -1 a column in the order's direction, +1 against, at most 99); at 0 the order becomes 0 |
| 2 | RETREAT n MILES | the same to the left |
| 3 | SEARCH & DESTROY ENEMY ROBOTS | the opponent at slot `+$0E`, kept while it lives and is under 50 columns away; else the nearest live opponent by column (`FindNearestOpponent` `$B41D`); none: a random free direction |
| 4 | ... ENEMY FACTORYS | a building target (below); needs the nuclear part |
| 5 | ... ENEMY WARBASES | the same; needs the nuclear part |
| 6 | SEARCH & CAPTURE NEUTRAL FACTORYS | a building target |
| 7 | ... ENEMY FACTORYS | a building target |
| 8 | ... ENEMY WARBASES | a building target |

`SetOrder` (`$ABC8`) turns an order 4 or 5 for a robot without the nuclear part into 0. Any order whose search
finds no target becomes 0 too.

**Building targets.** `TargetBuildingTable` (`$B3D5`) gives the table (warbases `$FD70` for 5 and 8, factories
`$FD84` for the others) and the owner bits wanted:

- `$20` (the enemy's) for our robots;
- `$40` (ours) for the enemy's;
- 0 (neutral) for order 6.

The target is record `+$0E`, kept while it still has those owner bits. Else `FindTargetBuilding` (`$B34D`) takes
the nearest by column that no robot of the side with the same order is already after (`ConsiderBuilding`
`$B36C`). With none, our robot stands and an enemy robot switches to order 3.

**The aim** (`RobotAim` `$B2D5`):

- D = the directions toward the target. While the columns differ, the row aimed at is 3 below the building's row:
  its door.
- 8 or more columns away: lean horizontally, as an advance does.
- Closer: a random free direction among the wanted ones. A horizontal one is kept for |dx| - 1 steps.
- Arrived (D = 0): orders 4 and 5 detonate (`NuclearBlast`, 10.9); the others face down and stand. A robot that
  stands on a door captures it (10.7).

## 10.6 Shooting and damage

`FireShot` (`$B6D6`) launches the shot from the robot's anchor in its facing direction:

- 5 steps of range, 7 for missiles, one more with electronics;
- each step moves 2 cells;
- the first step is taken at once (`MoveShot` `$B724`); when the shot survives it, `SoundFx` = 1
  ([9.5](09-sound.md)).

Every turn `UpdateShot` (`$B70D`) moves each shot one step. The shot is gone off rows 0-15, when its steps run out,
or over ground of height 10 or more (types `$10` and `$12`). Then the 3 × 3 cells around its new cell are tested
for an object (bit 6):

- **Nothing:** the shot marks its cell and flies on.
- **A live robot of either side** takes the damage below; there is friendly fire.
- **Anything else** ends the shot: a building, another shot, a dying robot (`ShotGone` `$B7EA`, `SoundFx` `$FC`).

    damage = ((60 - (+`$09` + +`$0D`)) / 4) × (weapon + 1)        integer division, weapon 1 cannon, 2 missiles, 3 phasers

A tall robot on high ground takes less. For a robot of height 19 on flat ground: 10 per point, so a cannon does
20, missiles 30 and phasers 40.

- Strength 0 or below: `+$0C` = `$FC`, dying, `SoundFx` `$C8`.
- Otherwise `SoundFx` `$FA`.

The recordings agree:

| Moment | Shot | Victim | Strength |
| --- | --- | --- | --- |
| `work/deep` from frame 18680 | an enemy missile, record `$D7EE`: `7B F3 7B 00 0B 08 06 02 0A` (column `$7B`, row 11, up, 6 steps left, missiles) | our robot 2, height 19 | 100 → 70 → 40 |
| `work/deep`, later | our cannon | enemy robot 25, height 19 | 100 → 80 → 60 → 40 |
| `work/docC/fight` frame 18702 | the same missile | robot 2 (`$DA2C`: `$64` at frame 18701, `$46` at 18703) | 100 → 70 |

A dying robot counts `+$0C` up from `$FC` and toggles its cell's bit 6 for four turns, so shots and eyes see it
only every other turn. At 0 `RobotDestroyed` frees the slot, erases the dot and recounts. On bare ground it lays a
2 × 2 wreck of terrain types 6 / 7 (height 3), which every locomotion can climb.

COMBAT MODE in the robot menu fires shot record 0 (`$D7D3`) from the player's robot, or detonates its bomb
(`CombatMenuCode` `$AC7C`). Without the weapon chosen it buzzes (`CombatRefused` `$ACCE`). No recording entered it;
a region agent fired a cannon from it on an own instance (the comment at `$AC7C`).

## 10.7 Capture

In each turn, `GameTurnEnd` (`$AD90`) looks at the 28 capture points at `$FD70` (5 bytes each: column, row, owner
and type, a count). Points 0-3 are the warbases, 4-27 the factories. The test cell is each point's door.

1. Map bit 6 on the door (a robot anchored there): the count `+4` goes up by 1.
2. At 144 (`$90`) turns, about 30 s of play, the count is reset and the robot there (`FindRobot` `$CDD8`) takes the
   point for its side (`+$0A` bit 7):
   - a warbase: `GiveWarbase` (`$BB86`);
   - a factory: `GiveFactory` (`$BB61`), point - 4.
3. An empty door resets the count to 0.
4. After any capture `CountBases` (`$BB09`) recounts both sides and the panel is reprinted.

Any robot captures, whatever its order: an ADVANCE that stops on a door takes the building. A warbase the player
captures gets a pad, a second construction site. The robot has to stay on the door for 144 turns. An opponent
ahead makes it step on if it can (10.4), which takes it off the door and resets the count; this follows from the
code and was not seen in a recording. In `work/deep` every capture followed a count of 121-143
in the 250-frame samples (r1).

## 10.8 The enemy commander

`EnemyCommander` (`$B7F4`) runs first in every `WorldTurn`; there were 3415 calls in `work/deep`. `Random AND $1F`
picks one of the enemy's slots 24-47; the values 24-31 do nothing, so it acts in 3 turns of 4.

**A free slot: maybe a new robot.**

1. Each of the 4 warbases in turn is taken with chance 1/2, but only if its owner byte is exactly `$20` (the
   enemy's, intact).
2. The door and the three cells of the row under it must be free of bit 6.
3. Parts: one random byte (the second of two `Random` calls, `$B84D`). There is no second try: the slot stays
   free this turn unless the byte has
   - exactly one chassis (bit 0, 1 or 2);
   - weapons (bits 3-6) neither none nor all four;
   - at least EnemyRobots / 8 + 1 weapons: 1 below 8 robots, 2 from 8, 3 from 16.

   Electronics (bit 7) come with chance 1/2.
4. Payment on a copy in `MenuResources`, with `PartCosts` like the player's. The shortfall of the own resources
   must be at most max(general / 2, 11), and at most general. Otherwise nothing is spent and nothing built.
5. The new robot: `+$0A` `$80`, `+$05` 4 and `+$08` 4 (down), `+$06` 3, order 0, strength 100, `+$0E` `$FF`,
   `+$0F` 1, height the sum of `PartHeights`. Then the counts and the panel.

The enemy pays the same prices but can borrow up to half its general resource. Its robots grow better armed as
its army grows.

**A live robot: maybe a new order** (`EnemyReplan` `$B920`).

- Order 0 is replaced at once; any other order only with chance 1/32 a turn.
- Orders 1-3 are always chosen anew.
- For orders 4-8 the order is kept only if the target has changed owner *and* the robot stands on its door: the
  capture is under way. Otherwise the order is chosen anew, which usually gives the nearest target again.

`EnemyChooseOrder` (`$B95D`):

| Parts | Order | Chance |
| --- | --- | --- |
| with nuclear | 5 destroy warbases | 3/4 |
| | 4 destroy factories | 1/4 |
| without | 6 capture neutral factories | 1/2 |
| | 7 capture the player's factories | 1/4 |
| | 8 capture the player's warbases | 1/4 |

The target is the nearest by column (`FindTargetBuilding`). If there is none, the order is 3: hunt robots. The
commander never gives ADVANCE or RETREAT.

## 10.9 The nuclear blast

`NuclearBlast` (`$B99F`) runs when a robot with order 4 or 5 reaches its target, or from COMBAT MODE's NUCLEAR
BOMB.

1. The first intact base in reach is destroyed: its owner byte gets bit 7 (`$80`) and its blocks become debris.
   - Warbases: |dy| < 7, |dx| < 7 and dx + dy < 10, with dy measured from the robot's row + 5.
   - Factories: 5, 5 and 7, from the row + 1.
2. A round area of 9 × 9 cells around the robot (rows of 5, 7, 9, 9, 9, 9, 9, 7, 5 cells; map rows 1-15 only):
   - every robot there dies, of both sides;
   - blocks of the types `$11`-`$14` become debris (types 6 / 7).
3. The robot itself dies.
4. `NuclearFlash` (`$BA87`): 61 random paper colours on the view, with a fading rumble of ROM bytes
   (`NuclearRumble` `$BAEE`). It lasts about 3.3 s, and the game stands still meanwhile.
5. The radar is rebuilt, the bases and robots are recounted, and the panel is reprinted.

A destroyed base is gone for both sides: no one can capture it again, since `CountBases` and the searches skip
bit 7. r3 verified it twice on its instance with a poked nuclear robot (a warbase and a factory). No recording
built a nuclear robot.

## 10.10 Winning and losing

`CheckGameEnd` (`$AE6B`) runs every turn:

- **The enemy has no warbase** (`$FD42` = 0): `GameWon` (`$AEB1`) prints " INSIGNIANS DESTROYED / YOU HAVE WON !"
  over the radar.
- **Ours are 0** (`$FD3A` = 0): "YOU HAVE NO BASES LEFT / BETTER LUCK NEXT TIME!".

Factories and robots do not count. Both ends then run the same code:

1. `GameStop` (`$AF00`).
2. `GameOverWait` (`$AEEA`): a low beep (`$FA`), 100 HALTs (2 s), `WaitRelease`, then the first control pressed.
3. `JP Start`: the title menu.

There is no score. r1 verified both ends by poking the counts on its instance (`work/ann/r1.md`). The enemy's
warbases can only be taken by capture (order 8 for us) or destroyed by a nuclear robot (order 5).

## 10.11 What the deep recording showed

![The course of the bot's game: robots, factories and resources per side over 11.8 game days, work/deep](img/game-deep-course.png)

`python3 tools/course_chart.py sample --work work/deep --out work/docC/course.json` (memory_at at every 120th frame,
0-36000), then `python3 tools/course_chart.py chart work/docC/course.json docs/img/game-deep-course.png`. The panels:

- top: the robots per side (`$FD41`, `$FD49`), with our robots built and lost;
- middle: the factories per side and the neutral ones;
- bottom: the general resource and the sum of the part resources per side.

Only samples taken while `PlayInterrupt` was the handler count.

![The bot's game: screens from frame 130 to 34796](img/bot-game.png)

The bot ([5.6](05-controls.md)) builds a robot whenever it can afford its plan, and orders it to capture neutral
or enemy factories or to destroy robots (`PLAN` in `tools/bot.py`).

| Day | Frame | Robots ours / enemy | Warbases | Factories | Neutral | General | Parts (sum) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.02 | 120 | 0 / 0 | 1 / 3 | 0 / 0 | 24 | 20 / 20 | 0 / 0 |
| 1.00 | 3360 | 2 / 3 | 1 / 3 | 0 / 0 | 24 | 15 / 15 | 0 / 0 |
| 2.00 | 6480 | 3 / 4 | 1 / 3 | 1 / 1 | 22 | 9 / 19 | 2 / 2 |
| 4.03 | 12840 | 5 / 8 | 1 / 3 | 2 / 2 | 20 | 6 / 17 | 4 / 4 |
| 6.01 | 18840 | 6 / 11 | 1 / 3 | 3 / 5 | 16 | 7 / 14 | 7 / 4 |
| 8.01 | 24600 | 5 / 12 | 1 / 3 | 3 / 8 | 13 | 17 / 21 | 19 / 18 |
| 10.02 | 30720 | 4 / 16 | 1 / 3 | 4 / 10 | 10 | 13 / 22 | 26 / 31 |
| 11.84 | 36000 | 3 / 15 | 1 / 3 | 4 / 13 | 7 | 18 / 10 | 34 / 20 |

What the game did:

- **17 captures, all of neutral factories.** Ours were 4: points 4, 6, 7 and 8, on days 1.80, 3.45, 5.47 and 8.05.
  The enemy took 13: points 21, 22, 15, 23, 27, 13, 26, 14, 25, 24, 20, 16 and 19. No warbase and no owned
  factory changed hands.
- **The enemy outbuilt us** from its 3 warbases' 15 general a day. It built 22 robots in the samples and lost 7,
  ending with 15. Our side built 7 (the bot's whole plan), peaked at 6 and ended with 3.
- **Production shows in steps.** Our general rose by 5 a day with one warbase; each new factory added 2 a day to
  its resource.
- **The end state, frame 36000.**
  - Our buildings `1 1 0 1 1 1 0` (warbases, electronics .. chassis) and resources `18 10 0 6 8 10 0`.
  - The enemy's buildings `3 1 1 2 3 3 3` and resources `10 4 4 0 0 12 0`.
- **The fighting began late.** The first shot was fired near the end of day 5 (frame 18679). `FireShot` ran 51 times, and
  `SoundEffect` 1356 times from frame 18680 to 35333.
- **No nuclear robot, no game end.** The enemy commander builds nuclear robots only by chance and pays 20 for the
  part; none appeared in 11.8 days. The bot's own nuclear robot is the 8th entry of its plan, and it built only 7.
  Neither side lost a warbase.

## 10.12 Bugs

| Where | What | Witness |
| --- | --- | --- |
| `ConstructionMenu`, the play loop at `$A6F3` | With all 24 of our slots taken, the menu returns at once with IY = `$DB80`, the enemy's slot 24. The play loop then writes the new-robot values there: that enemy robot gets strength 100 and order 0 back, every turn the ship sits on the pad | r1, on its instance: a poked strength `$20` was `$64` again after landing |
| `SteerByOrder` `$B2B8` | After `FindTargetBuilding` finds a new target, HL is past the table (`$FDFF` for factories, `$FD87` for warbases). The aim reads `$FDFE` / `$FDFD` (the `JP` and `Handler`) as row `$66`, column `$C300`: one step of a wrong course, corrected at the next decision | r2, a breakpoint at `$B2BB`: HL = `$FDFF`, DE = `$C300` |
| `PrintTensUnits` `$D407` | A value above 99 prints a wrong tens digit (200 is "D0"); only poked resources get there | r4 ([8.6](08-hud-and-text.md)) |
| `ConstructionMenuLoop` `$CA0F` | A refused chassis swap leaves the old chassis refunded: the robot has no chassis until another is chosen | r4, experiment 3 |
| `MenuMusic` `$C4A7` | A restarted tune keeps a voice's on/off state from where it was cut | `work/docC/rec` frames 406-427 ([9.4](09-sound.md)) |
| `PrintDigitColumn` `$D2E3` | A count of 10 or more would print `:` onwards; no count gets there | code reading |

Never-run code: `UnusedTapeCode` (`$AE29`). Keys 6 and 7 held together jump into the ROM's SAVE code at `$04B0`
with `Start` as the return address. It looks like a debugging leftover; nothing calls it.

## 10.13 Design notes

- **One rule set for both sides.** The enemy builds from the same parts at the same prices, steps with the same
  delays, captures by the same count and is hit by the same formula. Its edges are the start (3 warbases to 1) and
  the credit of half its general resource.
- **Orders, not control.** A robot's orders only matter when it sees no opponent. Seeing one always wins: turn,
  fire, stand. A capture order is fragile, since a single opponent in view stops the walk.
- **Time is the currency.** Production is daily and capture takes 144 turns. Step delays make a bipod on rough
  ground three times slower than an anti-grav: the long game rewards factories over robots, as `work/deep` shows.
- **Cheap randomness.** One `Random` per turn plus the draws of the commander and the robots decide all choices;
  the deep recording and `work/docC/fight` show that the whole game is deterministic from the snapshot and the
  inputs.
