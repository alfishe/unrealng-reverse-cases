# 7. Objects

What this covers:

- the game variables `$7A80-$7AEF`, where the rules keep their state;
- the level block that LoadLevel `$FE03` reads to `$C4AE`: its parts, and its header byte by byte;
- the wave script: the 5-byte entry, the six commands, RunWaves and StartWave;
- each level's waves on its map, and all 8 scripts on one axis;
- the kind record, the scripts and the paths they draw;
- the 28 enemy slots, MoveEnemies and the two movers each kind names;
- the level's own mover code at the end of each block, with two kinds at work;
- collision: SolidMap and its tags, the hit gathering, HitEnemy, the enemy shots;
- the random numbers;
- level 1 decoded byte by byte, against its recording;
- what differs between the 8 levels.

The rules these objects serve are in [doc 10](10-gameplay-logic.md): the ship, the Force, the weapons, the score,
death and the level's end. The drawing (DrawSprite, the metatiles, the scroll) is in [doc 6](06-rendering.md).

The recordings it rests on ([WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)):

- `l1`: level 1 from `c1/play.szx` to the level 2 search, 15 260 frames. It carries the RAM-only POKE `$91F2` = `$C9`,
  so the ship cannot die;
- `l2`-`l8`: the other levels, each with its load, with the same POKE.

`l1` was opened on an own muted instance, after `. work/env.sh` (BIN is the unreal-qt binary it names):

```text
python3 ../../kit/rs.py open --work work/docs/rtC/l1 --ttd work/stage1/rec/l1/session.ttd --model 48K --port-base 37790 --binary $BIN
```

`work/docs/rtC/sample.py` sampled
the variables `$7A80-$7AEF` and the slots `$8501-$85FC` every 10 frames into `work/docs/rtC/l1-vars.jsonl`. A sample
of frame N is the memory at the start of frame N.

Coordinates:

- the play field is 32 cell columns by 20 cell rows, and a cell is 8 x 8 pixels;
- a position is (column C, row B), as the code keeps it in BC;
- the map is cut into block columns of 4 cells, 32 pixels each ([doc 6](06-rendering.md)).

## 7.1 The game variables

The rules keep their state in one block, GameVars `$7A80-$7AEF`, just below the font at `$7AF0`. Doc 11 lists each
entry. This table groups them by owner.

| Address | Name | Size | What it holds | Who writes it | Doc |
| --- | --- | ---: | --- | --- | --- |
| `$7A80` | ColumnPtr | 2 | the next byte of the column buffer to feed | Scroll | 6 |
| `$7A82` | ScrollStep | 1 | the step 0-7 inside a cell column | Scroll | 6, 7.3 |
| `$7A83` | MetaColumn | 1 | the cell column 0-3 inside the block column | Scroll | 6, 7.3 |
| `$7A84` | MapColumn | 1 | the next block column the scroll feeds; the screen's left edge is 8 behind | Scroll, RestartPoint | 7.3 |
| `$7A85` | MapReadPtr, MapBlockPtr | 4 | the map bytes being read | Scroll | 6 |
| `$7A89` | FrameCounter | 1 | counts passes; movers use its low bits as a clock | Scroll | 7.8 |
| `$7A8A` | IntTicks | 1 | counts interrupts; the main loop waits for 3 | Interrupt | 4 |
| `$7A8B` | KempstonAbsent | 1 | the Kempston probe's result | ProbeKempston | 5 |
| `$7A8C` | ExtraLives | 1 | the extra lives given | CheckExtraLife | 10 |
| `$7A8D` | DeathTimer | 1 | 32 at a death, then counts down | ShipDies, LoseLife | 10 |
| `$7A8E` | ScrollHalted | 1 | the scroll stands (a boss) | wave command 1 | 7.3 |
| `$7A8F` | WavesHalted | 1 | no waves start and no enemy moves (the level's end) | wave command 5 | 7.3 |
| `$7A90` | WavePtr | 2 | the next wave entry | RunWaves, RestartPoint | 7.3 |
| `$7A95` | HitCount, HitResult | 2 | the tags the last draw gathered; ProcessHits' result | CollectHit, ProcessHits | 7.9 |
| `$7A97` | BeamMeter | 1 | the BEAM meter's column | FireBeam | 10 |
| `$7A98` | ShieldTimer | 1 | the shield's frames left | TakePickup, ShipShield | 10 |
| `$7A99` | ScoreChanged | 1 | the score needs reprinting | AddScore | 8 |
| `$7A9A` | WaveOverride | 1 | wave command 3: the slot of the next wave | CommandWave | 7.3 |
| `$7A9B` | LevelEndTimer | 1 | counts down after the level's end | command 5, BossBlast | 10 |
| `$7A9C` | DrawTag | 1 | the tag the next draw writes into SolidMap | every drawer | 7.9 |
| `$7A9D` | StarFrame | 1 | the star task's counter | interrupt task 5 | 4 |
| `$7A9E` | ShooterLimit, Shooters | 2 | how many enemies may have a shot out; how many have | command 4, EnemyFire | 7.9 |
| `$7AA0` | Lives | 1 | the lives | ShipDies | 10 |
| `$7AA1` | ShipColumn, ShipRow | 2 | the ship's cell | MoveShip | 10 |
| `$7AA3` | ForceAttached | 1 | 0 free, 1 at the nose, 2 at the tail | ForceDraw, the detach | 10 |
| `$7AA4` | ShipFrame | 1 | the ship's sprite: 3 level, 2 and 4 tilted | MoveShip | 10 |
| `$7AA5` | BitUpperOn, BitLowerOn, MissilesOn | 3 | the add-ons fitted | TakePickup | 10 |
| `$7AA8` | ForceRecord | 9 | three records of 3 bytes (state, column, row) | MoveForce | 10 |
| `$7AB1` | BitPositions | 12 | the bits' positions and the beam's sprite phase | MoveBitDevices, FireBeam | 10 |
| `$7ABD` | WeaponKind, ForceLevel | 2 | the Force's laser; its level 0-3 | TakePickup | 10 |
| `$7ABF` | BeamCharge, BeamPower | 2 | the charge while fire is held; the released beam's strength | FireBeam, HitEnemy | 10 |
| `$7AC1` | Carriers | 8 | the two pick-up carriers | level movers B7-B15 | 10 |
| `$7AC9` | BossBlast, BossBlastCount, BossBlastPos | 4 | the boss explosion | BossDestroyed | 7.10 |
| `$7ACD` | RandomPtr | 2 | NextRandom's pointer into the ROM | NextRandom | 7.10 |
| `$7ACF` | Scratch | 8 | scratch words of the shot and award code | many | |
| `$7AD7` | HitList | 16 | the tags gathered by the last draw | CollectHit | 7.9 |
| `$7AE7` | MissileLaunch | 9 | the missiles' launch records | MoveMissileSet | 10 |

Three tables beside the block belong to the objects:

| Address | Name | Size | What it holds |
| --- | --- | ---: | --- |
| `$7E00` | SolidMap | 640 | a tag per play-field cell (32 x 20): who drew it last ([7.9](#79-collision-solidmap-tags-and-the-hit-gathering)) |
| `$8386` | EnemyShots | 84 | 28 records of 3 bytes, one per slot: object and direction, column, row |
| `$8501` | EnemySlots | 252 | 28 slots of 9 bytes ([7.7](#77-the-slots-and-moveenemies)) |

The level adds its own: LevelVars `$C4C4-$C4DF`, 28 bytes inside the level block, which only the level's movers use.

![The game variables over l1: a lane per variable, sampled every 10 frames](img/objects/l1-vars.png)

How to read it:

- a lane per variable, x is the frame of `l1`, the lane runs from 0 to the value at its right;
- red and blue bands are flags (on or off);
- "enemy slots in use" counts the slots whose hits are not zero.

Drawn by `python3 tools/fig_objects.py vars work/docs/rtC/l1-vars.jsonl docs/img/objects/l1-vars.png`, from 1526
samples of `l1` (frames 0-15 250).

```text
the rules' state:
    the scroll's place          ScrollStep, MetaColumn, MapColumn     -> the waves (7.3)
    the waves                   WavePtr, WaveOverride, ShooterLimit   -> the slots (7.7)
    the ship and its arms       ShipColumn .. BeamPower               -> doc 10
    the level's end             WavesHalted, LevelEndTimer            -> doc 10
```

```mermaid
flowchart LR
    S["Scroll: ScrollStep, MetaColumn, MapColumn"] --> W["RunWaves: WavePtr"]
    W --> L["EnemySlots $8501"]
    L --> M["MoveEnemies: DrawTag, SolidMap"]
    M --> H["ProcessHits: HitList, BeamPower"]
    W --> C["commands: ScrollHalted, WaveOverride, ShooterLimit, LevelEndTimer"]
    P["TakePickup: ForceLevel, WeaponKind, add-ons"] --> F["MoveForce: ForceRecord, ForceAttached"]
```

Worked example, the `l1` samples:

- frame 2050 reads ForceLevel 0 and WeaponKind 0;
- frame 2060, after the crystal of [doc 10](10-gameplay-logic.md#106-the-pick-ups), reads WeaponKind 2 and ForceLevel 1;
- frame 2090 reads ForceAttached 2: the Force docked at the ship's tail;
- ScrollHalted is set from frame 12 050 (the boss), and WavesHalted reads `$41` at 14 580 (the level's end);
- both are clear again at 14 840, after level 2's load.

Witness: the 1526 samples behind the figure.

**The point**: the rules have one small state block, and a level adds only its 28 LevelVars. Saving `$7A80-$7AEF`,
the slots and the level space is saving the game.

## 7.2 The level block: what lies where

Each level is one tape block that LoadLevel `$FE03` reads to `$C4AE` ([doc 3, 3.9](03-build-and-load.md#39-the-games-level-loader)).
It brings everything the level needs:

- the sprites and the object table;
- the metatiles and the map;
- the wave script;
- the enemy kinds and their scripts;
- the code that moves them.

The game's code reaches into the level only through the header's pointers.

![The 8 level bodies: each loads at C4AE and brings its own sprites, map, wave script, kinds and mover code](img/levels/blocks.png)

How to read it:

- a row is a level, x is the address from `$C4AE` to `$FA00`;
- a box is a part, its colour in the key, its start address under it;
- "records" are the kind records, "kinds" the kind table of words;
- "movers" are the two tables of 16 words, "code" the level's own movers and helpers.

Drawn by `python3 tools/fig_level.py blocks docs/img/levels/blocks.png` from `build/levelN.bin` and the labels of
`build/levelN.lst`. It needs no recording.

The order is the same in every level. Level 1's parts:

| Part | Level 1 | What it is | Read by |
| --- | --- | --- | --- |
| header | `$C4AE-$C4C3` | 22 bytes ([7.2.1](#721-the-header-byte-by-byte)) | RestartPoint, CheckRestart, the pointers |
| LevelVars | `$C4C4-$C4DF` | 28 spare bytes, zero on tape: the level code's own variables | the level's movers |
| sprites | `$C4E0-$D7F8` | the cells (9 bytes each) of the level's objects | DrawSprite |
| objects | `$D7F9-$D910` | the object table: size and cell pointer per object | LevelObject `$8E5F` |
| metatiles | `$D911-$E570` | 144 bytes each, numbered down from the map | MetatileAddress |
| map | `$E571-$E787` | 5 bytes per block column | Scroll |
| waves | `$E788-$ECA0` | the wave script, 5 bytes an entry | RunWaves |
| records | `$ECA1-$EFFA` | the kind records | StartWave, MoveEnemies |
| kinds | `$EFFB-$F056` | the kind table: a word per kind | StartWave |
| scripts | `$F057-$F364` | the movement scripts | MoveEnemies |
| movers | `$F365-$F3A4` | two tables of 16 code addresses | MoveEnemies |
| code | `$F3A5-$F859` | the movers and their helpers | MoveEnemies' `JP (HL)` |

```text
level block at $C4AE:
    header -> LevelVars -> sprites -> objects -> metatiles -> map -> waves
           -> kind records -> kind table -> scripts -> movers A, movers B -> mover code
```

```mermaid
flowchart LR
    H["header $C4AE"] --> O["objects (+12)"]
    H --> M["map (+14); metatiles below it"]
    H --> W["waves (+6)"]
    H --> K["kind table (+16)"]
    K --> R["kind records"]
    R --> S["scripts"]
    H --> A["movers A (+18)"]
    H --> B["movers B (+20)"]
    A --> C["mover code"]
    B --> C
```

Worked example: level 1 is 13 228 bytes, `$C4AE-$F859`. Level 6 is the smallest, 8849 bytes ending at `$E73E`. The
space up to `$FA00` is free in every level.

Witness: `build/level1.bin` to `build/level8.bin` rebuild the TZX identically ([doc 3](03-build-and-load.md#313-the-build)).

The parts are resources the build reads (`src/res/levels/levelN/`): the sprites, the object table (`objects.csv`),
the metatiles, the map (`map.txt`) and the wave script with the kind records after it (`waves.txt`, one wave a line,
[7.3](#73-the-wave-script-runwaves-and-the-commands)); the kind table, the scripts, the movers and their code stay in `src/levelN/`.

**The point**: a level is data and code in one block, tied to the game only by the header's fixed offsets. A new level
needs no change in the game's code.

### 7.2.1 The header, byte by byte

![Level 1's records byte by byte: the header, a wave entry, a command entry, a kind record, a script step](img/levels/formats.png)

How to read it:

- each box is one byte, with its value from `build/level1.bin`;
- the label under the box names the field;
- the lines under each row explain the fields.

Drawn by `python3 tools/fig_level.py formats docs/img/levels/formats.png`.

| Offset | Address | Game name | Size | Meaning |
| ---: | --- | --- | ---: | --- |
| +0 | `$C4AE` | LevelRestartColumn | 1 | the block column a life restarts at (zero on tape) |
| +1 | `$C4AF` | LevelRestartWave | 2 | the wave entry a life restarts at (zero on tape) |
| +3 | `$C4B1` | LevelChecks | 3 | three checkpoint columns; the first is the start column; `$FF` none |
| +6 | `$C4B4` | LevelWaves | 6 | the wave entries that go with them; the first is the script's start |
| +12 | `$C4BA` | LevelObjects | 2 | the object table |
| +14 | `$C4BC` | LevelMetatiles | 2 | the map; metatile n lies at map - (n + 1) x 144 |
| +16 | `$C4BE` | LevelKinds | 2 | the kind table |
| +18 | `$C4C0` | LevelMoves | 2 | movers A |
| +20 | `$C4C2` | LevelMoves2 | 2 | movers B |

Two routines use the first part:

- RestartPoint `$8696`, at a level's start, sets the restart wave and WavePtr to LevelWaves (the script's start). It
  sets the restart column and MapColumn to LevelChecks (the start column).
- CheckRestart `$C2D6` runs every pass. When MapColumn equals a checkpoint column, the restart column becomes that
  column less 8, and the restart wave becomes its entry. A life lost later restarts there
  ([doc 10](10-gameplay-logic.md#1012-death-lives-and-continues)).

```text
RestartPoint:
    RestartWave = WavePtr = LevelWaves[0]
    RestartColumn = MapColumn = LevelChecks[0]
CheckRestart:                        # every pass
    for k in 2, 1, 0:
        if MapColumn == LevelChecks[k]:
            RestartColumn = MapColumn - 8      # the screen whose right edge is the checkpoint
            RestartWave = LevelWaves[k]
            return
```

```asm
RestartPoint:
8696  LD HL,(LevelWaves)
8699  LD (LevelRestartWave),HL
869C  LD (WavePtr),HL
869F  LD A,(LevelChecks)
86A2  LD (LevelRestartColumn),A
86A5  LD (MapColumn),A
86A8  RET
CheckRestart:
C2D6  LD HL,LevelChecks+$0002
C2D9  LD DE,LevelWaves+$0004
C2DC  LD A,(MapColumn)
C2DF  CP (HL)
C2E0  JR Z,l_C2ED               ; the third checkpoint
C2E2  DEC L
C2E3  DEC E
C2E4  DEC E
C2E5  CP (HL)
C2E6  JR Z,l_C2ED               ; the second
C2E8  DEC L
C2E9  DEC E
C2EA  DEC E
C2EB  CP (HL)
C2EC  RET NZ                    ; the first, or none
l_C2ED:
C2ED  SUB $08
C2EF  LD (LevelRestartColumn),A
C2F2  LD HL,LevelRestartWave
C2F5  EX DE,HL
C2F6  LDI                       ; the checkpoint's wave entry
C2F8  LDI
C2FA  RET
```

```mermaid
flowchart TD
    L["LoadLevel: the block at $C4AE"] --> R["RestartPoint: WavePtr = start wave, MapColumn = start column"]
    R --> P["each pass: CheckRestart"]
    P --> Q{"MapColumn = a checkpoint column?"}
    Q -- "no" --> P
    Q -- "yes" --> S["RestartColumn = column - 8, RestartWave = its entry"]
    S --> P
    P --> D{"a life lost?"}
    D -- "yes" --> B["the level restarts at RestartColumn, RestartWave"]
```

Worked example, level 1's header: `00 00 00 06 25 4B 88 E7 AF E8 44 EA F9 D7 71 E5 FB EF 65 F3 85 F3`.

- The start column is 6 and the checkpoints are `$25` = 37 and `$4B` = 75.
- The script starts at `$E788`; the checkpoints' entries are `$E8AF` and `$EA44`.
- The objects lie at `$D7F9`, the map at `$E571`, the kinds at `$EFFB`, the movers at `$F365` and `$F385`.
- At MapColumn 37 the restart column becomes 29 with the wave `$E8AF`; at 75 it becomes 67 with `$EA44`.

Witness: the `l1` samples of MapColumn ([7.1](#71-the-game-variables)): it passes 37 and 75 on its way to 123. A
restart: `restart` (the integration's recording: c1's play start, POKE `$91F2` = `$C9` until frame 2640). At 2640
MapColumn is 39, past the checkpoint 37, and LevelRestartColumn `$C4AE` is 29; the POKE undone, a life is lost at
2667 to an enemy shot (`$C3CE`); the next life (StartPlay `$8BD3` at 2858) begins with MapColumn 37: the first screen
covers the 8 block columns from 29, its right edge at the checkpoint.

**The point**: a checkpoint is a map column, not a time. A life lost restarts one screen before the last checkpoint
passed, with the waves from there.

## 7.3 The wave script: RunWaves and the commands

The wave script says what appears when. It is a list of 5-byte entries, sorted by map position. RunWaves `$8FDD` runs
once a pass, after the scroll. It starts every entry whose position has come.

A position is three numbers:

- the block column (MapColumn);
- the cell column in the block (MetaColumn, 0-3);
- the step (ScrollStep, 0-7).

The scroll moves one step a pass, so the test can be "equal" and no entry is missed.

A wave entry:

| Byte | Field | Meaning |
| ---: | --- | --- |
| 0 | column | the block column; `$FF` ends the script |
| 1 | sub | bits 3-4 the cell column in the block, bits 0-2 the step |
| 2 | kind | 1-62: a kind; `$63`: a command |
| 3 | x | the enemy's screen column (31 is the right edge); for a command, its number |
| 4 | y | the enemy's screen row; for a command, its argument |

The commands (CommandWave `$9093`):

| Command | Does | Used |
| ---: | --- | --- |
| 1 | the scroll halts: ScrollHalted = 1, CellFreeEmpty patched to `SCF : RET`, the play attributes copied to the screen, the sides cleared | once a level (twice in level 1): the boss |
| 2 | ResumeWaves: ScrollHalted and WavesHalted 0, CellFreeEmpty restored | in no script |
| 3 | WaveOverride = the argument: the next wave goes into that slot | bosses and fixed formations |
| 4 | ShooterLimit = the argument | each level's start, sometimes later |
| 5 | LevelEndTimer = WavesHalted = `$41`: the level's end | once (level 8: three times) |
| 6 | PlaySound, H = the argument, L = `$83` | levels 2, 7 and 8 |
| other | nothing | level 7's entry `$EC16` has command `$5D` |

```text
RunWaves:                               # once a pass
    if WavesHalted: return
    loop:
        e = WavePtr
        if e.column == $FF: return                           # the script's end
        if (e.column, e.sub >> 3 & 3, e.sub & 7) != (MapColumn, MetaColumn, ScrollStep): return
        WavePtr += 5
        if e.kind == $63: CommandWave(e.x, e.y)
        else: StartWave(e.kind, column e.x, row e.y)
```

```asm
RunWaves:
8FDD  LD A,(WavesHalted)
8FE0  AND A
8FE1  RET NZ
RunWavesNext:
8FE2  LD HL,(WavePtr)           ; the next entry
8FE5  LD A,$FF
8FE7  CP (HL)
8FE8  RET Z                     ; the script's end
8FE9  LD A,(MapColumn)
8FEC  CP (HL)
8FED  RET NZ                    ; not yet
8FEE  INC HL
8FEF  LD A,(HL)
8FF0  RRCA
8FF1  RRCA
8FF2  RRCA
8FF3  AND $03                   ; bits 3-4: the cell column
8FF5  LD B,A
8FF6  LD A,(MetaColumn)
8FF9  CP B
8FFA  RET NZ
8FFB  LD A,(HL)
8FFC  AND $07                   ; bits 0-2: the step
8FFE  LD B,A
8FFF  LD A,(ScrollStep)
9002  CP B
9003  RET NZ
9004  INC HL
9005  LD A,(HL)
9006  CP $63
9008  JP Z,CommandWave
900B  INC HL
900C  LD E,(HL)                 ; E = column x
900D  INC HL
900E  LD D,(HL)                 ; D = row y
900F  INC HL
9010  LD (WavePtr),HL
StartWave:                      ; A = the kind (7.5)
...
StartWaveDone:
908F  NOP                       ; StartWaveAt makes it a RET
9090  JP RunWavesNext           ; the next entry may be due too
CommandWave:
9093  INC HL
9094  LD A,(HL)                 ; the command number
9095  INC HL
9096  INC HL
9097  LD (WavePtr),HL
909A  DEC HL                    ; HL at the argument
909B  CP $01
909D  JR Z,l_90B5               ; then 2, 3, 4, 5, 6 in turn
...
90B3  JR StartWaveDone          ; any other number: nothing
l_90B5:
90B5  LD A,$01
90B7  LD (ScrollHalted),A
90BA  LD A,$37                  ; SCF
90BC  LD (CellFreeEmpty),A
90BF  LD A,$C9                  ; RET
90C1  LD (CellFreeEmpty+$0001),A
90C4  LD HL,PlayAttrs
90C7  LD DE,$5800
90CA  LD BC,$0280
90CD  LDIR
90CF  CALL ClearSides
90D2  JR StartWaveDone
...
l_90E5:
90E5  LD A,$41
90E7  LD (LevelEndTimer),A
90EA  LD (WavesHalted),A
90ED  JR StartWaveDone
l_90EF:
90EF  LD H,(HL)
90F0  LD L,$83
90F2  CALL PlaySound
90F5  JR StartWaveDone
```

```mermaid
flowchart TD
    A["RunWaves, once a pass"] --> H{"WavesHalted?"}
    H -- "yes" --> X["return"]
    H -- "no" --> E{"entry column = $FF?"}
    E -- "yes" --> X
    E -- "no" --> M{"column, cell, step = MapColumn, MetaColumn, ScrollStep?"}
    M -- "no" --> X
    M -- "yes" --> K{"kind = $63?"}
    K -- "no" --> S["StartWave: a slot for the kind"]
    K -- "yes" --> C{"command"}
    C -- "1" --> C1["halt the scroll"]
    C -- "2" --> C2["resume"]
    C -- "3" --> C3["WaveOverride = argument"]
    C -- "4" --> C4["ShooterLimit = argument"]
    C -- "5" --> C5["LevelEndTimer = WavesHalted = $41"]
    C -- "6" --> C6["PlaySound argument"]
    S --> E
    C1 --> E
    C2 --> E
    C3 --> E
    C4 --> E
    C5 --> E
    C6 --> E
```

The halt has a quirk that shapes every boss. Scroll still counts ScrollStep, MetaColumn and MapColumn while
ScrollHalted is set; only the screen stops. So the wave script goes on while the boss is on screen. Its later entries
(more boss parts, the second halt, the level's end) come by time. In `l1` the halt came at MapColumn 107 (frame
12 050), and MapColumn went on to 123 (frame 14 580), where command 5 ended the level.

Worked example, `l1` frame 202: the scroll reached block column 16, cell 0, step 0.

- Entry 0 (`$E788`, `10 00 63 04 00`) is command 4: ShooterLimit 0.
- Entry 1 (`$E78D`, `10 00 01 1F 04`) starts kind 1 at column 31, row 4, in slot 1.
- Entry 2 is due at step 5, five passes later.

![RunWaves and StartWave at l1 frame 202: entry 0 (command 4) and entry 1 (kind 1 into slot 1)](img/routines/StartWave.gif)

How to read it:

- left, the memory `$7A80-$85FF` (the variables and the slots), and the slots from `$8501` as 28 rows of 9 bytes;
- right, the code, with the instructions run in the slice marked;
- slot 1 fills with `41 57 F0 1F 04 00 A1 EC 01`.

Recording `l1`, frame 202, T 14 100 to 15 460 (164 instructions), 40 pictures: `python3 ../../kit/routine_anim.py
--work work/docs/rtC/l1 --listing build/game.lst --listing build/level1.lst --window 202:14100-202:15460 --out
docs/img/routines/StartWave.gif --view buffer:8501:9x28:hex --range 7A80-85FF --pc 8FDD-90F6 --pictures 40`.

Witness:

- `l1` frame 202 (the animation);
- the `l1` samples show WavesHalted `$41` at frame 14 580 (MapColumn 123) and level 2's load by 14 840;
- command 2 is in no script, so it is known only from the code;
- level 7's command `$5D` (entry `$EC16`) falls through CommandWave and does nothing.

**The point**: the waves are tied to the map, not to time. Once the scroll halts, the map position becomes a clock: a
boss is a set of waves that run while the screen stands still.

## 7.4 The waves of each level

Each level's script can be drawn on its own map, with a mark per enemy wave where its enemy appears.

![Level 1 as its wave script places it: each enemy where it appears on the map](img/levels/strip-1.png)

How to read it:

- the map from `src/res/levels/level1`, drawn by `tools/levelmap.py`, cut into rows of 32 block columns;
- a circle per wave entry, its number the kind, at map cell ((column - 8) x 4 + cell + x, y): where the enemy starts;
- a square is an entry that runs while the scroll halts, drawn on the halted screen;
- the red line marks the halt (the boss); blue triangles mark the checkpoints.

Drawn by `python3 tools/fig_level.py strip 1 docs/img/levels/strip-1.png`. It needs no recording.

Level 1 reads like the arcade's first stage:

- lines of kind 1 (the small fliers) from the right edge, from block column 16 to 82;
- kind 14 walkers on the floor at block columns 42-48;
- kind 19 and 22 pods on the ceiling from 50 to 95;
- the big ship at 60-63: command 3 puts kinds 10, 11 and 44 into fixed slots 8-25;
- the boss from 100: kinds 6 and 46 (32 hits each), 23 (the tail), 42 (the core) and 43, then kinds 9 and 21 on the
  halted screen.

The other levels are drawn the same way, by `python3 tools/fig_level.py strip N docs/img/levels/strip-N.png`:

![Level 2 as its wave script places it](img/levels/strip-2.png)

![Level 3 as its wave script places it](img/levels/strip-3.png)

![Level 4 as its wave script places it](img/levels/strip-4.png)

![Level 5 as its wave script places it](img/levels/strip-5.png)

![Level 6 as its wave script places it](img/levels/strip-6.png)

![Level 7 as its wave script places it](img/levels/strip-7.png)

![Level 8 as its wave script places it](img/levels/strip-8.png)

All 8 scripts on one axis show the rhythm of each level:

![The 8 wave scripts on one axis: what starts at which map column, and where the scroll halts and the level ends](img/levels/waves.png)

How to read it:

- x is the block column; a tick per enemy wave, its height the enemy's screen row;
- red marks "halt", black "end";
- short green lines would be command 2 (none), short violet lines are command 6 (a sound); blue triangles are
  checkpoints;
- wide orange blocks are many entries at one column (a formation).

Drawn by `python3 tools/fig_level.py waves docs/img/levels/waves.png`.

```text
for each entry of level N's script:
    if a command: mark it on the axis at its column
    else: tick at its column, height = its screen row
```

```mermaid
flowchart LR
    A["block column 8-17: the first waves"] --> B["the level's body"]
    B --> C["command 1: the halt"]
    C --> D["boss waves by time"]
    D --> E["command 5: the end"]
```

What the axis shows:

- the waves start at block column 8-17, so the first screen is empty;
- level 7 plays sound `$0A` four times just after its halt at 72;
- level 2's boss part (64-98) is a stream of sound commands (sounds `$10`-`$13`, its heartbeat) and waves on the
  halted screen;
- level 3 has few waves (50) and many commands (45): its big ship is placed by 42 commands 3, into fixed slots;
- level 8 has three "end" commands; the first turns the level digit from 8 to 9 and play goes on, the second wraps
  to level 1, the third is never reached ([doc 10](10-gameplay-logic.md#1014-the-level-end-and-the-wrap)).

Worked example: level 2's halt at block column 64 plays sound `$12` in the same entry group. From 66 to 96 a sound
command comes every one to three block columns: `$13`, `$11`, `$13`, `$12`.

Witness: each level's script as text: `python3 tools/wavescript.py N --part waves`. The halts at `l1` 12 050 and the
level ends of `l2`-`l8` are in [WALKTHROUGH 6.1](../WALKTHROUGH.md#61-the-screens).

**The point**: R-Type's levels are scripts on a strip. Each enemy has a place on the map, and the boss is the part of
the script past the halt.

## 7.5 The kind record

A wave names a kind. The kind table (LevelKinds, header +16) holds a word per kind: the address of its record. The
record says how the enemy moves, how hard it is, what it scores and which scripts it runs.

| Byte | Field | Meaning |
| ---: | --- | --- |
| 0 | movers | low nibble: mover A (before the draw); high nibble: mover B (after it) |
| 1 | flags | bits 0-5 the hits it takes (`$3F` indestructible), bit 6 it fires, bit 7 a shot out (used in the slot) |
| 2 | score | high nibble the explosion size (0 none), low nibble the award |
| 3.. | scripts | script addresses, a word each; a word `$00xx` frees the slot, `$FFxx` starts the list again |

The award n picks the pair (place, digit) number n - 1 of ScoreAwards `$70DC` (`src/res/tables/score-awards.csv`).
Awards 1-9 give 100-900 points and award 10 gives 1000. The table has 10 pairs. Award 12, which every indestructible
kind carries, reads the zeros after it, and AddScore returns at once on place 0: no points.

The alias: when bytes 3 and 4 are equal and below `$80`, they are a kind number. The slot then takes that kind's
record (its scripts and its score), but keeps its own movers and flags. Level 1's kinds 11 and 44 borrow kind 10's
scripts: the same path, with a different mover and other hits.

```text
StartWave(kind, x, y):
    record = LevelKinds[kind - 1]
    if WaveOverride: slot = WaveOverride; WaveOverride = 0           # command 3: overwrites the slot
    else: slot = the first of slots 1-24 whose flags are 0
          if none: return                                            # the wave is dropped
    slot.record = record; slot.column = x; slot.row = y
    slot.movers = record[0]; slot.flags = record[1]
    if record[3] == record[4] and record[3] < $80:                   # the alias
        record = LevelKinds[record[3] - 1]; slot.record = record
    slot.script = the word at record + 3; slot.index = 1
```

```asm
StartWave:
9013  LD H,$00
9015  LD L,A
9016  DEC L
9017  ADD HL,HL
9018  LD BC,(LevelKinds)
901C  ADD HL,BC
901D  LD A,(HL)
901E  INC HL
901F  LD H,(HL)
9020  LD L,A                    ; HL = the kind's record
9021  PUSH HL
9022  LD HL,EnemySlots
9025  LD B,$18                  ; 24 slots searched
9027  LD A,(WaveOverride)
902A  AND A
902B  JR Z,l_9037
902D  CALL SlotFlags            ; command 3: that slot
9030  XOR A
9031  LD (WaveOverride),A
9034  JP l_9044
l_9037:
9037  LD A,(HL)
9038  AND A
9039  JR Z,l_9044               ; a free slot
903B  LD A,L
903C  ADD A,$09
903E  LD L,A
903F  DJNZ l_9037
9041  POP HL
9042  JR StartWaveDone          ; none free: dropped
l_9044:
9044  PUSH HL
9045  POP IX
9047  POP HL
9048  LD (IX+$06),L             ; the record
904B  LD (IX+$07),H
904E  LD (IX+$03),E             ; column
9051  LD (IX+$04),D             ; row
9054  EX DE,HL
9055  LD A,(DE)
9056  LD (IX+$05),A             ; movers
9059  INC DE
905A  LD A,(DE)
905B  LD (IX+$00),A             ; flags
905E  INC DE
905F  INC DE
9060  EX DE,HL
9061  LD A,(HL)
9062  INC HL
9063  CP (HL)
9064  JR NZ,l_9083              ; two different bytes: a script address
9066  CP $80
9068  JR NC,l_9083
906A  LD H,$00                  ; the alias: that kind's record
...
9078  LD (IX+$06),L
907B  LD (IX+$07),H
907E  INC HL
907F  INC HL
9080  INC HL
9081  LD A,(HL)
9082  INC HL
l_9083:
9083  LD (IX+$01),A             ; the first script
9086  LD A,(HL)
9087  LD (IX+$02),A
908A  LD A,$01
908C  LD (IX+$08),A             ; the next script is number 1
```

```mermaid
flowchart TD
    W["a wave: kind, x, y"] --> T["record = LevelKinds[kind - 1]"]
    T --> O{"WaveOverride set?"}
    O -- "yes" --> F["that slot (command 3), WaveOverride = 0"]
    O -- "no" --> S{"a free slot among 1-24?"}
    S -- "no" --> D["the wave is dropped"]
    S -- "yes" --> F
    F --> C["slot: record, x, y, movers, flags"]
    C --> A{"script bytes equal and below $80?"}
    A -- "yes" --> B["take that kind's record and scripts"]
    A -- "no" --> N["the first script"]
    B --> N
    N --> I["script index 1"]
```

Worked example: level 1's kind 1, record `$ECA1`: `00 41 12 57 F0 57 F0 57 F0 57 F0 00 00`.

- Movers A0 and B0.
- Flags `$41`: 1 hit, and it fires.
- Score `$12`: explosion size 1, award 2 (200 points).
- Scripts: `$F057` four times, then a zero word, which frees the slot.

The [data sheet](#721-the-header-byte-by-byte) draws these bytes.

Witness: the slot written at `l1` frame 202 ([7.3](#73-the-wave-script-runwaves-and-the-commands)).

**The point**: a kind is 3 bytes of rules plus a playlist of scripts. The playlist's end decides whether the enemy
leaves (free) or stays (again) until killed.

## 7.6 The scripts and the paths they draw

A script is a list of 2-byte steps: the object to draw, then a move byte. One step runs a pass (or every other pass,
with the half-speed movers).

| Move bit | Meaning |
| --- | --- |
| 0-1 | the drawer: 0 as stored, 1 mirrored, 2 upside down, 3 both ([doc 6](06-rendering.md)) |
| 2 | up (row - 1) |
| 3 | down (row + 1) |
| 4 | left (column - 1) |
| 5 | right (column + 1) |
| 6 | spare |
| 7 | the script's last step |

MoveEnemies turns the move byte by two `RRCA` and calls MoveByBits `$C3D1`, which the enemy shots share:

```text
MoveByBits(bits, B row, C column):
    if bits & 1: B -= 1
    if bits & 2: B += 1
    if bits & 4: C -= 1
    if bits & 8: C += 1
```

```asm
MoveByBits:                     ; A bit 0 up, 1 down, 2 left, 3 right
C3D1  BIT 0,A
C3D3  JR Z,l_C3D6
C3D5  DEC B
l_C3D6:
C3D6  BIT 1,A
C3D8  JR Z,l_C3DB
C3DA  INC B
l_C3DB:
C3DB  BIT 2,A
C3DD  JR Z,l_C3E0
C3DF  DEC C
l_C3E0:
C3E0  BIT 3,A
C3E2  RET Z
C3E3  INC C
C3E4  RET
```

```mermaid
flowchart LR
    S["step: object, move"] --> D["drawer = move & 3"]
    S --> M["MoveByBits(move >> 2)"]
    M --> P["new B, C"]
    S --> L{"move bit 7?"}
    L -- "yes" --> N["next script from the record"]
    L -- "no" --> T["next step"]
```

The paths of all 46 kinds of level 1, each kind's script list walked once from the same start:

![Level 1's 46 enemy kinds: the path each kind's script list draws, one cell a step](img/levels/paths-1.png)

How to read it:

- a panel per kind: the screen at 4 pixels a cell, the path from the green dot to the red one;
- the title gives the movers (A and B) and the hits; the line under it gives the steps and whether the list frees or
  loops;
- every kind starts at cell (26, 8) here, while the wave gives the real start;
- a mover can skip steps or steer ([7.8](#78-the-movers-the-levels-own-code)), so the path on screen can differ.

Drawn by `python3 tools/fig_level.py paths 1 docs/img/levels/paths-1.png` from `build/level1.bin`. The other levels
are `img/levels/paths-2.png` to `paths-8.png`, by the same command with N. Level 2's:

![Level 2's kinds and their paths](img/levels/paths-2.png)

The other six, by the same command:

![Level 3's kinds and their paths](img/levels/paths-3.png)

![Level 4's kinds and their paths](img/levels/paths-4.png)

![Level 5's kinds and their paths](img/levels/paths-5.png)

![Level 6's kinds and their paths](img/levels/paths-6.png)

![Level 7's kinds and their paths](img/levels/paths-7.png)

![Level 8's kinds and their paths](img/levels/paths-8.png)

The kinds' pictures, each level's sprite sheet from `python3 tools/fig_render.py objects` ([doc 6](06-rendering.md)),
put a face to these numbers:

![Level 1's objects](img/sprites/objects-level-1.png)

![Level 2's objects](img/sprites/objects-level-2.png)

![Level 3's objects](img/sprites/objects-level-3.png)

![Level 4's objects](img/sprites/objects-level-4.png)

![Level 5's objects](img/sprites/objects-level-5.png)

![Level 6's objects](img/sprites/objects-level-6.png)

![Level 7's objects](img/sprites/objects-level-7.png)

![Level 8's objects](img/sprites/objects-level-8.png)

What the panels of level 1 show:

- kind 1, the small fliers: 32 steps left with a wave up and down, then free;
- kinds 24-30, the snakes of pick-up carriers: long winding lists, then free;
- kinds 38-41: the four quarters of one circle, each starting at a different quarter (the big gun's ring);
- kinds 4, 6, 23, 42 and 46: one step that loops, so they stand still and their movers do the moving.

Worked example: script `$F057` (kind 1) is `31 10 32 18 33 10 32 14 31 14 32 10 33 18 32 90`.

| Step | Object | Move | Means |
| ---: | ---: | --- | --- |
| 1 | 49 | `$10` | left |
| 2 | 50 | `$18` | down and left |
| 3 | 51 | `$10` | left |
| 4 | 50 | `$14` | up and left |
| 5 | 49 | `$14` | up and left |
| 6 | 50 | `$10` | left |
| 7 | 51 | `$18` | down and left |
| 8 | 50 | `$90` | left, the last step |

Eight steps move eight cells left in a small wave. The object cycles 49-50-51-50: the flier's animation.

Witness: kind 1's slot at `l1` frame 202 holds script `$F057`. Kind 1 is the first enemy of `l1`.

**The point**: the script carries both the animation (the object per step) and the path (the move bits). A new enemy
is a new script, with no code.

## 7.7 The slots and MoveEnemies

EnemySlots `$8501` holds 28 slots of 9 bytes:

| Byte | Field | Meaning |
| ---: | --- | --- |
| +0 | flags | bits 0-5 hits left; bit 6 fires; bit 7 a shot out; 0 = free |
| +1 | script | the current step (a pointer into the script) |
| +3 | column | C |
| +4 | row | B |
| +5 | movers | low nibble mover A, high nibble mover B |
| +6 | record | the kind record |
| +8 | index | the next script's number in the record; bit 7: hit since the last move |

StartWave searches only slots 1-24 for a free one. Slots 25-28 are reached only through command 3. MoveEnemies `$9109`
runs every pass, before RunWaves, and walks all 28.

```text
MoveEnemies:                                   # every pass
    if WavesHalted: return
    for slot in 1..28:
        if not (slot.index & $80) and slot.flags & $3F == 0: continue  # free (a slot just killed still runs once)
        DrawTag = $80 + slot
        object, move = the step at slot.script
        (B, C) = MoveByBits(move >> 2, slot.row, slot.column)
        if slot.flags bit 6 and not bit 7: EnemyFire()
        killed = EnemyHit()                    # carry when its hits ran out
        jump MoversA[slot.movers & 15]         # carry, the new BC, the object in A'
    # a mover A ends at one of:
    #   MoveStore: keep the new BC, then draw;  MoveDraw: draw at the old place;  MoveDrawA: draw object A
    #   MoveNext: no draw
    # all of them then jump MoversB[slot.movers >> 4], which ends at:
    #   MoveScript: the next step (or the next script, or free);  MoveDone: stay on this step
```

```asm
MoveEnemies:
9109  LD A,(WavesHalted)
910C  AND A
910D  RET NZ
910E  LD IY,EnemySlots
9112  LD B,$01
MoveEnemiesSlot:
9114  BIT 7,(IY+$08)            ; hit since the last move: run it
9118  JR NZ,l_912D
911A  LD A,(IY+$00)
911D  AND $3F
911F  JR NZ,l_912D              ; alive
MoveEnemiesNext:
9121  LD DE,$0009
9124  ADD IY,DE
9126  INC B
9127  LD A,B
9128  CP $1D                    ; 28 slots
912A  JR NZ,MoveEnemiesSlot
912C  RET
l_912D:
912D  LD A,B
912E  OR $80
9130  LD (DrawTag),A            ; the slot's tag: $80 + slot
9133  PUSH BC
9134  LD E,(IY+$01)
9137  LD D,(IY+$02)             ; DE = the step
913A  LD C,(IY+$03)
913D  LD B,(IY+$04)
9140  LD A,(DE)                 ; the object
9141  EX AF,AF'
9142  INC DE
9143  LD A,(DE)                 ; the move
9144  RRCA
9145  RRCA
9146  CALL MoveByBits
9149  BIT 7,(IY+$00)
914D  JR NZ,l_9159              ; a shot is out
914F  LD A,(DrawTag)
9152  BIT 6,(IY+$00)
9156  CALL NZ,EnemyFire
l_9159:
9159  LD A,(IY+$05)
915C  AND $0F
915E  LD HL,(LevelMoves)
9161  CALL TableEntry
9164  CALL EnemyHit             ; carry: killed
9167  JP (HL)                   ; mover A
MoveStore:
9168  LD (IY+$03),C
916B  LD (IY+$04),B
MoveDraw:
916E  LD A,(DE)                 ; the move byte: its bits 0-1 pick the drawer
MoveDrawA:
916F  PUSH DE
...                             ; DrawSprite, Mirrored, Flipped or Both
MoveNext:
9195  LD A,(IY+$05)             ; mover B
9198  RRCA
9199  RRCA
919A  RRCA
919B  RRCA
919C  AND $0F
919E  LD HL,(LevelMoves2)
91A1  CALL TableEntry
91A4  JP (HL)
MoveScript:
91A5  LD A,(DE)
91A6  CP $80
91A8  JR NC,l_91B3              ; the last step
91AA  INC DE
91AB  LD (IY+$01),E             ; the next step
91AE  LD (IY+$02),D
MoveDone:
91B1  JR MoveSlotEnd
l_91B3:
91B3  LD E,(IY+$06)
91B6  LD D,(IY+$07)
91B9  LD A,(IY+$08)
91BC  ADD A,A
91BD  ADD A,$03
91BF  LD H,$00
91C1  LD L,A
91C2  ADD HL,DE                 ; record + 3 + 2 x index
91C3  LD B,(HL)
91C4  INC HL
91C5  LD A,(HL)
91C6  AND A
91C7  JR Z,MoveFree             ; $00xx: free
91C9  CP $FF
91CB  JR NZ,l_91D3
91CD  LD (IY+$08),$00           ; $FFxx: from the first script again
91D1  JR l_91B3
l_91D3:
91D3  LD (IY+$01),B
91D6  LD (IY+$02),A
91D9  INC (IY+$08)
MoveSlotEnd:
91DC  POP BC
91DD  JP MoveEnemiesNext
MoveFree:
91E0  LD (IY+$00),$00
91E4  JR MoveSlotEnd
```

```mermaid
flowchart TD
    S["slot n of 28"] --> L{"alive or just hit?"}
    L -- "no" --> N["next slot"]
    L -- "yes" --> T["DrawTag = $80 + n; read object and move; MoveByBits"]
    T --> F{"fires and no shot out?"}
    F -- "yes" --> EF["EnemyFire"]
    F -- "no" --> H
    EF --> H["EnemyHit: carry when killed"]
    H --> A["mover A (level code)"]
    A --> X{"exit"}
    X -- "MoveStore" --> ST["keep the new position"] --> DR["draw the object"]
    X -- "MoveDraw" --> DR
    X -- "MoveNext" --> B
    DR --> B["mover B (level code)"]
    B --> Y{"exit"}
    Y -- "MoveDone" --> N
    Y -- "MoveScript" --> SC{"last step?"}
    SC -- "no" --> NS["next step"] --> N
    SC -- "yes" --> NX{"next word of the record"}
    NX -- "an address" --> NS2["next script"] --> N
    NX -- "$FFxx" --> R["index 0, the first script"] --> N
    NX -- "$00xx" --> FR["free the slot"] --> N
```

![MoveEnemies at l1 frame 202: one pass over the 28 slots](img/routines/MoveEnemies.gif)

How to read it:

- left, the memory and the 28 slots; right, the code;
- slot 1 (kind 1, the slot of [7.3](#73-the-wave-script-runwaves-and-the-commands)) runs mover A0, the draw and
  mover B0;
- the other 27 slots are skipped in a few instructions each.

Recording `l1`, frame 202, T 11 000 to 14 210 (316 instructions), 40 pictures: `python3 ../../kit/routine_anim.py
--work work/docs/rtC/l1 --listing build/game.lst --listing build/level1.lst --window 202:11000-202:14210 --out
docs/img/routines/MoveEnemies.gif --view buffer:8501:9x28:hex --range 7A80-85FF --pc 9109-91F1,C3D1-C3E4,C1E0-C20A
--pictures 40`.

Worked example: slot 1 at frame 202 holds `41 57 F0 1F 04 00 A1 EC 01`.

- Flags `$41`: 1 hit, fires.
- Step `$F057`, column 31, row 4.
- Movers 0 and 0; record `$ECA1`; next script number 1.
- The step `31 10` says object 49, left: the new column is 30.
- Mover A0 (`JP C,MoveNext : JP MoveStore`) stores it and draws; mover B0 (`JP MoveScript`) steps to `$F059`.

Witness: `l1` frame 202 (the animation). The "enemy slots in use" lane of [7.1](#71-the-game-variables) shows up to
22 slots alive at once in level 1.

**The point**: one loop runs every enemy of every level, and the level supplies only the two jumps per kind. The
order is the same for all: move, fire, hit test, mover A, draw, mover B, script.

## 7.8 The movers: the level's own code

Each level ends with two tables of 16 code addresses (header +18 and +20) and the code they point at. MoveEnemies
enters mover A with:

- carry set when EnemyHit found the enemy killed;
- BC = the new position from the move bits (the slot keeps the old one in IY+3 and IY+4);
- DE at the step's move byte, and the object in A'.

A mover A exits at MoveStore `$9168`, MoveDraw `$916E`, MoveDrawA `$916F` (draw object A) or MoveNext `$9195` (no
draw). A mover B exits at MoveScript `$91A5` (the next step) or MoveDone `$91B1` (stay on this step).

Level 1's movers:

| Mover | Code | What it does | Kinds |
| --- | --- | --- | --- |
| A0 | `$F3A5` | killed: no draw; else store and draw | 1-5, 34-37, 43 |
| A1 | `$F3AB` | killed: no draw; else store on odd passes and draw at the old place on even ones: half speed | 7, 8, 15-18, 20, 31, 45 |
| A2 | `$F3B9` | the same as A1, written with the other jump | 24-30 |
| A3 | `$F3BE` | drifts left (L1DriftLeft); killed: LevelVars+1 counts it; at 4, MapColumn = 115 and WavePtr = `$EC97` | 6, 46 |
| A4 | `$F3E3` | when the slot 10 part is left of it: L1BossHit (1500 points, LevelVars = 26) | 11 |
| A5 | `$F408` | the big ship's explosions, counted by LevelVars | 10, 44 |
| A6 | `$F468` | a ceiling pod: moves every 8th pass, draws with tag `$DC` + slot and soft cells, faces the ship | 19, 22 |
| A7 | `$F4D8` | plays sound `$09` once, at script 1 | 9, 21 |
| A8 | `$F4EC` | the boss core: at MapColumn 115 frees slots 20-23 with explosions and points | 42 |
| A9 | `$F559` | the boss tail: 14 segments of object `$39` from L1ShapeFrames; when slot 2 is free, BossDestroyed and 3000 points | 23 |
| A10 | `$F5AD` | follows the ship's row on odd scripts; at script 6 starts kind 13 and plays sound `$09` | 12 |
| A11 | `$F5E8` | one column left a pass | 13 |
| A12 | `$F5EC` | the walker: faces the ship, steps toward it unless scenery is in the way | 14 |
| A13 | `$F63D` | the big gun: follows the ship's row, fires a `$B4` shot, every 32nd pass starts kinds 38-41 | 32 |
| A14 | `$F6EA` | at object `$19`, every 4th pass starts kind 34 or 35 (or 36 or 37, by its facing), chosen by `LD A,R` | 33 |
| A15 | `$F728` | killed by scenery (GetCell no carry) or by the core's tag `$9C` | 38-41 |
| B0 | `$F742` | MoveScript: a step a pass | most |
| B1 | `$F745` | MoveScript on odd passes, MoveDone on even ones: half speed | many |
| B2-B5 | `$F750` | soft cells off, then B1 | none in level 1 |
| B6 | `$F755` | soft cells off, draw limit 31, then B0 | 19, 22 |
| B7-B15 | `$F75F-$F777` | a pick-up carrier: the slot's place into Carriers with a pick-up kind (3-9) | 24-30 |

The two kinds at work:

**Kind 14, the walker (mover A12).**

- Each pass it turns to face the ship: bit 0 of its move byte (the mirror) becomes 1 when the ship is to its right.
- On even script numbers it moves at half speed, as A1.
- On odd ones it takes one row and one column toward the ship, but only if GetCell finds the cell there empty.
  Otherwise it stays.

```text
L1MoverA12:
    if killed: goto MoveNext
    move.mirror = 1 if ShipColumn >= column else 0         # face the ship (the script byte is rewritten)
    if slot.index is even: goto the half-speed store (A1)
    row' = row + 1 if ShipRow >= row + 1 else row - 1
    col' = column + 1 if ShipColumn >= column + 1 else column - 1
    if GetCell(the cell beyond, toward the ship) != 0: (row', col') = (row, column)
    goto MoveStore
```

```asm
L1MoverA12:
F5EC  JP C,MoveNext             ; killed
F5EF  LD A,(ShipColumn)
F5F2  CP C
F5F3  LD L,$01
F5F5  JR NC,l_F5F9
F5F7  LD L,$00
l_F5F9:
F5F9  LD A,(DE)
F5FA  AND $FE
F5FC  OR L
F5FD  LD (DE),A                 ; the mirror bit into the script
F5FE  LD A,(IY+$08)
F601  AND $01
F603  JP Z,l_F3AE               ; even script: half speed
F606  PUSH BC
...                             ; one row and one column toward the ship, H and L the cell beyond
F62B  CALL GetCell
F62E  AND A
F62F  JR Z,l_F637               ; empty: the new place
F631  POP HL
F632  POP DE
F633  POP BC                    ; the old place
F634  JP MoveStore
l_F637:
F637  POP BC
F638  POP DE
F639  POP HL
F63A  JP MoveStore
```

```mermaid
flowchart TD
    A["L1MoverA12"] --> K{"killed?"}
    K -- "yes" --> N["MoveNext"]
    K -- "no" --> M["mirror bit = ship to the right"]
    M --> I{"script number odd?"}
    I -- "no" --> H["half speed: store on odd passes"]
    I -- "yes" --> S["one row and one column toward the ship"]
    S --> G{"the cell beyond empty?"}
    G -- "yes" --> ST["MoveStore: the new place"]
    G -- "no" --> OL["MoveStore: the old place"]
```

![L1MoverA12: kind 14 steers toward the ship unless scenery is there](img/routines/L1MoverA12.gif)

How to read it: left, the slots; right, the level code. The walker's slot changes its column and row bytes, and the
mirror bit of its step. Recording `l1`, frame 3270, T 21 800 to 23 600 (253 instructions), 40 pictures:
`python3 ../../kit/routine_anim.py --work work/docs/rtC/l1 --listing build/game.lst --listing build/level1.lst
--window 3270:21800-3270:23600 --out docs/img/routines/L1MoverA12.gif --view buffer:8501:9x28:hex --range 7A80-85FF
--pc F5EC-F63C,C0E4-C0F8 --pictures 40`.

**Kind 42, the boss core (mover A8).**

- It draws with DrawTag `$9C`, so a ring part (mover A15) that touches it dies.
- It drifts left with L1DriftLeft.
- At MapColumn 115, once every 32 passes, it frees the four slots 20-23 with L1BlastRecord. Command 3 put boss parts
  there at block column 100. Each is zeroed, an explosion starts at its place, and its award is added.
- Above 115 it moves slot 2's part one column left every 8th pass.

Mover A3 sets MapColumn to 115 when four kind 6 or 46 parts are killed, so both ways lead to the same blast. In `l1`
the parts were not killed: MapColumn reached 115 by the clock of the halt.

```text
L1MoverA8:
    DrawTag = $9C; L1DriftLeft()
    if MapColumn == 115:
        if FrameCounter & $1F == $10:
            for slot in 20, 21, 22, 23: L1BlastRecord(slot)   # free, explode, award
    elif MapColumn > 115 and FrameCounter & 7 == 0:
        slot 2's column -= 1
    if FrameCounter & 7: MoveDone else MoveStore
```

```asm
L1MoverA8:
F4EC  LD A,$9C
F4EE  LD (DrawTag),A
F4F1  CALL L1DriftLeft
F4F4  LD A,(MapColumn)
F4F7  CP $73
F4F9  JR C,l_F530               ; below 115: nothing
F4FB  JR NZ,l_F51B              ; above 115
F4FD  LD A,(FrameCounter)
F500  AND $1F
F502  CP $10
F504  JR NZ,l_F51B
F506  LD HL,EnemySlots+171      ; slot 20
F509  PUSH DE
F50A  PUSH BC
F50B  CALL L1BlastRecord
F50E  CALL L1BlastRecord
F511  CALL L1BlastRecord
F514  CALL L1BlastRecord
F517  POP BC
F518  POP DE
F519  JR l_F530
...
L1BlastRecord:
F53B  PUSH HL
F53C  LD A,(HL)
F53D  AND A
F53E  JR Z,l_F553               ; already free
F540  LD (HL),$00
...
F54D  CALL FreeExplosion
F550  CALL AwardScore
```

```mermaid
flowchart TD
    A["L1MoverA8"] --> T["DrawTag $9C, drift left"]
    T --> M{"MapColumn"}
    M -- "below 115" --> E["MoveDone or MoveStore"]
    M -- "115" --> F{"FrameCounter & $1F = $10?"}
    F -- "yes" --> B["L1BlastRecord x 4: slots 20-23 freed, exploded, scored"]
    F -- "no" --> E
    M -- "above 115" --> S["every 8th pass slot 2 one column left"]
    B --> E
    S --> E
```

![L1MoverA8 at l1 frame 13518: MapColumn 115, the boss parts in slots 20-23 freed, exploded and scored](img/routines/L1MoverA8.gif)

How to read it: the slot rows 20-23 (`$85AC`-`$85D3`) go to zero one after the other as L1BlastRecord, FreeExplosion
and AwardScore run. Recording `l1`, frame 13 518, T 19 900 to 24 600 (576 instructions), 50 pictures:
`python3 ../../kit/routine_anim.py --work work/docs/rtC/l1 --listing build/game.lst --listing build/level1.lst
--window 13518:19900-13518:24600 --out docs/img/routines/L1MoverA8.gif --view buffer:8501:9x28:hex --range 7A80-85FF
--pc F4EC-F558,A5A5-A5FF,A5B4-A5D0 --pictures 50`.

Worked example, `l1`: a trace of frames 13 440-13 615 runs `$F506` once, at frame 13 518, T 20 033. The four slots
20-23 then read `00` in their flags (the last picture of the animation).

Witness:

- L1MoverA12 at `l1` frame 3270, its steering branch `$F606` at T 21 922;
- L1MoverA8 at `l1` frame 13 518 (above);
- never run in `l1` (the stage 2 coverage, `python3 work/docs/rtC/tools/ran.py l1 ADDR`): L1BossHit `$F42D`, the A3
  kill count `$F3C6` and the BossDestroyed call `$F5A1`.

**The point**: the game's loop is generic. Each level's character (the walkers, the boss's tail, the snake carriers)
is a few hundred bytes of level code behind two jump tables.

## 7.9 Collision: SolidMap, tags and the hit gathering

R-Type has no box test. Every drawer writes a tag into SolidMap `$7E00`, one byte per play-field cell, and reads what
was there first. The tag is DrawTag:

| Tag | Who | Set by |
| --- | --- | --- |
| 0 | empty | the clear routines |
| 1-5 | the ship's cells | GameObject (DrawTag = the object, below 6) |
| 6-`$25` | the ship's shots, the Force, the bits, the beam | GameObject |
| `$80` | an enemy shot, or an object drawn without a slot | MoveEnemyShots, level code |
| `$80` + n | enemy slot n | MoveEnemies |
| `$DC` + n | an enemy slot drawn over soft cells (mover A6) | level code |
| `$FA` | a soft cell, scenery a shot can blow up | SoftCellsOn |
| `$FB-$FF` | scenery | the scroll feed, BossDestroyed |

CellFree `$8EC2` decides, cell by cell, whether a sprite may be drawn there:

- An empty cell may be drawn on, unless CellFreeEmpty `$8F0B` finds scenery (`$DC` or above) in the next cell to the
  right. On the scroll's step 7 it also looks two cells to the right, because the scroll is about to move it in.
- While the scroll halts, command 1 patches CellFreeEmpty to `SCF : RET`, so every empty cell is free.
- A taken cell is not drawn on. While DrawPrepare `$9A1E` has the hit gathering on (a `RET` made a `NOP`), CollectHit
  `$8EDB` puts the cell's tag into HitList (14 at most) and a soft cell's place into HitCells.

The ship's shots, the beam and the Force draw with the gathering on, then call ProcessHits `$A495`:

```text
ProcessHits:
    HitResult = 1                                # 1: nothing counted
    for tag in HitList:
        if tag < $80: continue                   # the ship's own objects
        if tag == $FA: ExplodeSoftCell(); PlaySound($0F); HitResult = 0
        elif tag > $FA: continue                 # hard scenery
        else: HitEnemy(the slot of tag)          # $80 + n, or $DC + n
    return HitResult
HitEnemy(slot):
    hits = slot.flags & $3F
    if hits == $3F:                              # indestructible
        if BeamPower: BeamPower = 0; return      # the beam ends on it
    elif hits:
        slot.flags -= 1; if hits == 1: slot.flags = 0
        slot.index |= $80                        # EnemyHit sees it next pass
    if BeamPower: BeamPower -= 1                 # the beam weakens a hit
    HitResult = 0
```

On its next pass MoveEnemies runs EnemyHit `$C1E0` for the slot. It clears bit 7 of +8. With hits left it plays sound
`$04` (an enemy hit) and returns no carry. With none left it calls EnemyDies and returns carry, which the mover sees
as "killed". EnemyDies `$A599` takes a free explosion record (FreeExplosion, 20 records of 3 bytes). AwardScore picks
the explosion's sound by the size nibble (`$10`: sound `$08`, `$40`: `$0A`, else `$09`) and the points. AddScore adds
them.

```asm
HitEnemy:
A551  CP $FA
A553  JP NC,ProcessHitsNext     ; scenery
A556  CP $DC
A558  JR C,l_A55C
A55A  SUB $DC                   ; a $DC tag: the slot number again
l_A55C:
A55C  EX DE,HL
A55D  CALL SlotFlags            ; HL = the slot's flags
A560  EX DE,HL
A561  AND $3F
A563  JR Z,l_A588               ; already dead
A565  CP $3F
A567  JR NZ,l_A57B
A569  LD (Scratch+$0006),A      ; indestructible:
A56C  LD A,(BeamPower)
A56F  AND A
A570  JR Z,l_A588
A572  XOR A
A573  LD (BeamPower),A          ; the beam ends on it
A576  CALL ClearHits
A579  INC A
A57A  RET
l_A57B:
A57B  EX DE,HL
A57C  DEC (HL)                  ; one hit
A57D  DEC A
A57E  JR NZ,l_A581
A580  LD (HL),A                 ; the last: flags 0
l_A581:
A581  LD A,L
A582  ADD A,$08
A584  LD L,A
A585  SET 7,(HL)                ; +8 bit 7: hit
A587  EX DE,HL
l_A588:
A588  LD A,(BeamPower)
A58B  AND A
A58C  JR Z,HitCounted
A58E  DEC A
A58F  LD (BeamPower),A          ; the beam loses one a hit
HitCounted:
A592  XOR A
A593  LD (HitResult),A
A596  JP ProcessHitsNext
EnemyHit:
C1E0  BIT 7,(IY+$08)
C1E4  RET Z                     ; not hit
C1E5  RES 7,(IY+$08)
C1E9  LD A,(IY+$00)
C1EC  AND $3F
C1EE  JR Z,l_C1FC               ; no hits left: dies
C1F0  PUSH HL
C1F1  LD HL,$0481
C1F4  CALL PlaySound            ; sound $04
C1F7  POP HL
C1F8  LD A,$01
C1FA  AND A                     ; no carry
C1FB  RET
l_C1FC:
...
C203  CALL EnemyDies
...
C209  SCF                       ; carry: killed
C20A  RET
```

The enemy shots (MoveEnemyShots `$C348`, the 28 records of 3 bytes at `$8386`, one per slot) test the cell they move
into with GetCell `$C0E4`:

| Cell | The shot |
| --- | --- |
| 0 | moves on and is drawn |
| 1-5, the ship | `JP ShipDies` at `$C3CE` |
| 6-`$25`, the ship's shots, the Force, the bits | ends: the Force and the bits are shields |
| an enemy | moves on over it, unless the enemy is indestructible: then it ends |
| `$FA` and above, scenery | ends |
| off the field (row 20 or more, column 31 or more) | ends |

A shot fired by EnemyFire (object 1) that ends clears its slot's "shot out" bit, and Shooters drops by one. EnemyFire
`$C2FB` fires only while Shooters is below ShooterLimit (wave command 4). Its shot aims once, at the start, in one of
8 directions (the row toward the ship's row, the column toward its column), and keeps that direction.

```mermaid
flowchart TD
    D["a shot, the beam or the Force is drawn (gathering on)"] --> L["HitList: the tags under it"]
    L --> P["ProcessHits"]
    P --> T{"tag"}
    T -- "below $80" --> P
    T -- "$FA soft cell" --> SC["blow the cell up, sound $0F"]
    T -- "$FB-$FF" --> P
    T -- "an enemy" --> HE{"hits"}
    HE -- "0" --> P
    HE -- "$3F" --> IB["the beam stops"]
    HE -- "other" --> MH["hits - 1, mark +8 bit 7"]
    MH --> NX["next pass: EnemyHit"]
    NX --> Q{"hits left?"}
    Q -- "yes" --> S4["sound $04"]
    Q -- "no" --> ED["EnemyDies: explosion, score; carry to the mover"]
    ES["an enemy shot moves"] --> G{"GetCell"}
    G -- "1-5" --> SD["ShipDies"]
    G -- "6-$25, scenery, an indestructible enemy" --> E2["the shot ends"]
    G -- "empty or an enemy" --> DR["drawn"]
```

The level 1 boss blast shows the end of this chain on the screen: explosions where the parts were, and their points.

![l1 frames 13500-13600: the boss parts of slots 20-23 explode at MapColumn 115](img/play/l1-boss-blast.gif)

How to read it: the play screen every 4 frames; the explosions at frame 13 518 stand where the four parts were.
Recording `l1`, frames 13 500-13 600, 26 pictures: `python3 ../../kit/screen_anim.py --work work/docs/rtC/l1 --from
13500 --to 13600 --step 4 --width 1050 docs/img/play/l1-boss-blast.gif`.

Worked example, `l1` frame 5452 ([doc 10, 10.4](10-gameplay-logic.md#104-the-shot-and-the-charged-beam)): the weakest
beam (power 10) leaves the ship. Each enemy cell it crosses takes one hit and costs the beam one point of power. So a
beam of 10 kills at most 10 one-hit enemies, and it dies at the first indestructible one.

Witness: ProcessHits, HitEnemy and EnemyHit run in all the level recordings. The ship-hit branch `$C3CE` is taken in
`deaths-l7` ([doc 10, 10.12](10-gameplay-logic.md#1012-death-lives-and-continues)).

**The point**: collision is a side effect of drawing. The tag map that keeps sprites off the scenery is the same map
that tells a shot what it hit.

## 7.10 The random numbers

The game has one pseudo-random routine, NextRandom `$C05D`. It steps RandomPtr through memory and returns the next
byte AND `$1F` that is not zero (1-31).

```text
NextRandom:
    repeat: RandomPtr += 1; a = memory[RandomPtr] & $1F
    until a != 0
    return a
```

```asm
NextRandom:
C05D  LD HL,(RandomPtr)
C060  INC HL
C061  LD (RandomPtr),HL
C064  LD A,(HL)
C065  AND $1F
C067  JR Z,NextRandom
C069  RET
```

Its only user is the boss explosion. BossDestroyed `$C19C` sets RandomPtr to 0 and every nonzero SolidMap cell to
`$FF`. BossBlastOnce `$C0FC` then draws a column below `$1E` and a row below `$12`, again and again (up to 128 tries)
until it finds a cell of `$80` or more, and explodes there. So every boss explodes at the same sequence of places,
taken from the ROM's first bytes.

```asm
BossBlastOnce:
...
C115  LD A,$80                  ; 128 tries
l_C117:
C117  EX AF,AF'
l_C118:
C118  CALL NextRandom
C11B  CP $1E
C11D  JR NC,l_C118              ; a column below 30
C11F  LD C,A
l_C120:
C120  CALL NextRandom
C123  CP $12
C125  JR NC,l_C120              ; a row below 18
C127  LD B,A
C128  CALL GetCell
C12B  CP $80
C12D  JR NC,l_C134              ; the boss or scenery: explode here
C12F  EX AF,AF'
C130  DEC A
C131  JR NZ,l_C117
C133  RET
```

```mermaid
flowchart TD
    A["RandomPtr + 1"] --> B["byte AND $1F"]
    B --> C{"0?"}
    C -- "yes" --> A
    C -- "no" --> D["1-31"]
    D --> E["BossBlastOnce: column below 30, row below 18"]
    E --> F{"SolidMap cell $80 or more?"}
    F -- "yes" --> X["explosion, sound $09 or $0A"]
    F -- "no" --> G{"128 tries used?"}
    G -- "no" --> A
    G -- "yes" --> R["no blast this time"]
```

![The boss blast's first 128 places: NextRandom over the 48K ROM from address 1](img/objects/boss-random.png)

How to read it:

- the 32 x 20 play field, a cell per square;
- a coloured square is a place NextRandom gives; its number is the first draw that lands there, and a darker square
  is drawn more than once;
- the pink border (columns 0, 30 and 31, rows 0, 18 and 19) is never drawn: NextRandom never returns 0, and the
  limits stop the rest.

Drawn by `python3 tools/fig_objects.py random ROM docs/img/objects/boss-random.png`, with the 48K ROM. It needs no
recording.

Worked example: the ROM begins `F3 AF 11 FF FF C3 CB 11`. From address 1 the bytes AND `$1F` give `$0F`, `$11`,
`$1F`, `$1F`, `$03`, `$0B`, `$11`. The first column is `$0F` = 15 (below 30). The row needs a byte below 18: `$11` =
17. So the first blast is tried at column 15, row 17, square 0 of the figure.

The other randomness is `LD A,R`: the interrupt's star field, level 1's mover A14 (kind 34 or 35), and movers of
levels 3 and 4.

Witness: `boss` (the integration's recording, [doc 10, 10.10](10-gameplay-logic.md#1010-the-enemies-the-waves-and-the-bosses-of-each-level)):
slot 2 POKEd free at 12 374, BossDestroyed at 12 375, BossBlastOnce's explosions (`$C134` 156 times) and sweep
(`$C164` 586 times) to 12 995. No recording killed a boss by hits. The stars run in
every recording.

**The point**: the same ROM gives the same explosion. R-Type's random numbers are a replay of the ROM's bytes, and
every boss dies the same way.

## 7.11 Level 1 decoded, against its recording

The whole chain for level 1's first enemy, from the bytes on tape to the slot in play:

1. The header at `$C4AE` gives start column 6, checkpoints 37 and 75, the script at `$E788`, the kinds at `$EFFB` and
   the movers at `$F365` and `$F385` ([7.2.1](#721-the-header-byte-by-byte)).
2. RestartPoint sets WavePtr = `$E788` and MapColumn = 6. The first screen shows block columns 6-13. At `l1` frame 0
   MapColumn reads 14 (`$7A84` = `$0E`).
3. The scroll steps once a pass: 8 steps a cell, 4 cells a block column. At block column 16 (frame 202) the first two
   entries are due. `10 00 63 04 00` is command 4 (ShooterLimit 0: nobody fires yet). `10 00 01 1F 04` is kind 1 at
   column 31, row 4.
4. The kind table's word 0 is `$ECA1`, the record `00 41 12 57 F0 ...`. Slot 1 becomes `41 57 F0 1F 04 00 A1 EC 01`.
5. MoveEnemies runs before RunWaves, so slot 1 moves on the next pass: step `$F057`, `31 10`, object 49 one column
   left.
6. Kind 1 flies 32 steps (its four scripts) and is freed at the left. Or the ship shoots it: it has 1 hit, so
   EnemyDies explodes it (size 1, sound `$08`) and awards 200.
7. At block column 32 command 4 raises ShooterLimit to 4 (`l1` frame 1910), and the fliers start to fire.

The animation shows the slots fill as the script runs, beside the screen:

![l1 frames 190-1400: the enemy slots fill as level 1's wave script runs](img/play/l1-waves-slots.gif)

How to read it:

- the grid is `$8500-$85FF` at a byte a cell: the slots, 9 bytes each, 28 of them from `$8501`;
- the screen is beside it;
- bytes appear when a wave starts a slot and vanish when a kind's list frees it.

Recording `l1`, frames 190-1400, every 20 frames (1 397 760 T), 62 pictures: `python3 ../../kit/memanim.py --work
work/docs/rtC/l1 --from 190 --to 1400 --step 1397760 --from-address 8500 --to-address 85FF --screen
docs/img/play/l1-waves-slots.gif`.

```text
header $C4AE -> LevelWaves $E788 -> entry 1: column 16, kind 1, x 31, y 4
             -> LevelKinds $EFFB, word 0 -> record $ECA1
             -> slot 1 $8501 -> script $F057 -> movers A0 $F3A5, B0 $F742 -> DrawSprite
```

```mermaid
flowchart LR
    H["header $C4AE"] --> W["wave script $E788"]
    W --> E["entry: column 16, kind 1, x 31, y 4"]
    E --> K["kind table $EFFB, word 0"]
    K --> R["record $ECA1: movers, flags, score, scripts"]
    R --> S["slot 1 $8501"]
    S --> P["script $F057: 8 steps x 4"]
    P --> M["movers A0, B0 at $F3A5, $F742"]
    M --> D["DrawSprite: objects 49-51 on the screen"]
```

Witness: `l1` frames 0-1400 (the samples and the animation), and frame 202 (the trace of
[7.3](#73-the-wave-script-runwaves-and-the-commands)).

**The point**: from a header to a sprite takes five lookups (header, script, kind table, record, script), all inside
the level block. The game code adds only the loop and the draw.

## 7.12 What differs between the 8 levels

| Level | Bytes | End | Start column | Checkpoints | Waves | Commands | Kinds | Scripts | Halt at | End at |
| ---: | ---: | --- | ---: | --- | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 13228 | `$F859` | 6 | 37, 75 | 227 | 34 | 46 | 79 | 107, 116 | 123 |
| 2 | 12856 | `$F6E5` | 6 | 43 | 248 | 43 | 46 | 67 | 64 | 98 |
| 3 | 13074 | `$F7BF` | 0 | none | 50 | 45 | 42 | 43 | 64 | 101 |
| 4 | 12998 | `$F773` | 0 | 41 | 203 | 10 | 54 | 117 | 74 | 103 |
| 5 | 8904 | `$E775` | 0 | 35 | 207 | 7 | 60 | 74 | 73 | 95 |
| 6 | 8849 | `$E73E` | 0 | 39 | 112 | 5 | 57 | 69 | 61 | 76 |
| 7 | 12997 | `$F772` | 0 | 45 | 213 | 22 | 53 | 88 | 72 | 96 |
| 8 | 11980 | `$F379` | 0 | none | 70 | 33 | 48 | 43 | 32 | 56, 66, 82 |

The table is `python3 tools/wavescript.py summary`. More differences, from the kind records
(`python3 tools/wavescript.py N --part kinds`):

| Level | Indestructible kinds | Kinds that fire | Alias kinds | Kinds no wave starts | Shooter limits | The boss in the level code |
| ---: | ---: | ---: | ---: | --- | --- | --- |
| 1 | 9 | 15 | 2 | 13, 34-41 (started by movers A10, A13, A14) | 0, 4 | parts blown at MapColumn 115; a tail of 14 segments |
| 2 | 24 | 1 | 15 | none | 0 | 16 hits (LevelVars to 16), then BossDestroyed; heartbeat sounds `$10`-`$13` |
| 3 | 7 | 9 | 23 | 34-42 | 28 | a big ship placed by 42 commands 3; BossDestroyed |
| 4 | 7 | 10 | 10 | 3, 6-9, 11, 20, 30, 46, 47, 54 | 2, 4 | movers set MapColumn |
| 5 | 1 | 9 | 11 | 21 kinds | 4 | movers set MapColumn |
| 6 | 1 | 24 | 0 | 24, 46 | 8 | 27 kinds of 12 hits |
| 7 | 3 | 25 | 0 | 13, 16-19, 36, 45 | 8, 4 | BossDestroyed; command `$5D` |
| 8 | 21 | 0 | 10 | 7-18, 27 | 0 | BossDestroyed, then MapColumn; three level ends |

What stays the same: the header layout, the 5-byte waves, the record format, the 16 + 16 movers with the same exits,
and MoveEnemies. What changes: the data, the counts, and the movers' code. Movers A0-A2 and B0-B1 do the same work in
every level; A3 and up differ per level.

```text
for N in 1..8:
    d = wavescript.decode(N)
    count the waves, commands, kinds, scripts; find halts and ends
    per kind: hits == $3F, fires, alias, started by some wave
```

```mermaid
flowchart LR
    S["same in all 8"] --> H["header layout"]
    S --> W["5-byte waves"]
    S --> R["record format"]
    S --> M["MoveEnemies and the mover exits"]
    D["differs per level"] --> DA["data and counts"]
    D --> DM["movers A3-A15, B2-B15"]
    D --> DL["ShooterLimit"]
```

Worked example: level 6 has 27 kinds of 12 hits and 24 kinds that fire, with ShooterLimit 8. Level 2 has 24
indestructible kinds and only 1 that fires, with ShooterLimit 0. The level 2 walls hold the player back, and the level
6 crowd shoots back.

Witness: the paths figures `img/levels/paths-N.png` ([7.6](#76-the-scripts-and-the-paths-they-draw)) show every kind of
each level. The `l2`-`l8` recordings play each level to its end.

**The point**: difficulty in R-Type is data. The shooter limit (0 to 28) is the one global knob, and the rest is which
kinds a level brings.

## 7.13 Notes, quirks and what is known only from the code

- **The script is tested for equality.** RunWaves needs the exact column, cell and step. It can, because the scroll
  moves one step a pass; a pass that moved two steps would skip a wave for good.
- **The halt is a clock.** MapColumn counts on while the screen stands. Level 1's boss lasts from column 107 to 115
  (frames 12 050-13 518 of `l1`, 1468 frames) whatever the player does, and then its parts blow up.
- **Slots 25-28** are never searched by StartWave; only command 3 reaches them.
- **A wave with no free slot is lost**: StartWave pops and returns, and WavePtr has already moved on.
- **Level 7's command `$5D`** at `$EC16` is a no-op: a data slip, or a command dropped in development.
- **Indestructible kinds score nothing**: their award 12 reads past the 10 pairs of ScoreAwards into zeros.
- **EnemyDies with no free explosion** (all 20 busy) skips AwardScore, and AddScore then runs with the caller's DE.
  No recording was checked for it.
- **Known only from the code**: command 2 (in no script); a boss killed by hits (BossDestroyed `$C19C`,
  BossBlastOnce and NextRandom ran only in `boss`, after a POKE freed the slot); L1BossHit `$F42D`; mover A3's kill count; the level movers listed under "Known
  only from the code" in `work/stage2/NOTES.md`.
