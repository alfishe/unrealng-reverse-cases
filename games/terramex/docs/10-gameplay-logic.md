# 10. Gameplay logic

What this covers: the rules of Terramex as the code runs them.

- the world and its exits;
- the hero's 34 statuses;
- walking, climbing, the jump, the fall, the refusal and the umbrella;
- the rides: the bounce, the hover, the lift, the balloon, the barrels, the basket, the float and the teleport;
- every death, the lives and the restart;
- every creature and hazard;
- every item and puzzle, the explorer rooms and the professor's six wishes;
- the telescope, the countdown, the ending and the score;
- the notable features and what no recording reached.

The records these rules work on (slots, creature records, item records, bearers) are in doc 07.

The recordings it rests on (WALKTHROUGH 6.0) are the ones doc 07 uses:

- `gameover`, sampled into `work/docs/tmC/go/vars.jsonl`:
  - the Spring jump and bounce into room `$10`;
  - the two pickups;
  - the RZX player's fatal fall into room `$1C`, replayed as the last life (Lives POKEd to 1, said so);
  - the space scene without the deflector.
- `rzx24750` (`work/docs/tmC/r247`): room `$31`, the crystal and the teleport.
- `rzx06000` (`work/docs/tmC/r06`): a creature's touch, in a drifted part of that segment.
- `rzx44000` (`work/docs/tmC/r44`): the first two gifts.
- `rzx50000`: the sixth gift and the ending, as recorded at stage 1.
- The RZX run as a whole: `work/stage1/rzx/vars.bin`, one sample every 250 RZX frames.
- The L1 counts of the 34 builds, quoted from the witness lines of `src/game/game.ann`.
- The clone probes of stage 2 (`work/stage2/probe_points.py`). These changed one variable on a copy of an RZX state, to
  reach what the run never did. Each is said so where it is used.

As in doc 07:

- A sample of frame N is the memory at the start of frame N; a trace shows an instruction in the frame it ran in.
- Every speed is per main-loop pass. A pass is 2.4 to 3.3 frames, 2.8 on average in the RZX run.
- "SK" marks a reading taken from the SkoolKit disassembly of nzeemin.

## 10.1 The world and its exits

The world is 6 levels of 12 rooms. Room R = 12 x level + column; level 0 is the surface and level 5 the deepest lab
level (doc 07.2). The play window is 256 x 128 pixels. The hero is a 24 x 24 sprite whose X and Y are its top left
corner.

The hero leaves a room by one of four routines:

| Exit | When | New room | New position | Called from |
| --- | --- | --- | --- | --- |
| ExitLeft `$A640` | X below 4 (walking), X 1 or 2 (jumping) | column - 1, column 0 wraps to 11; from room `$29`, the explorer's own room | X `$E6` | HeroUpdate, JumpArc, FloatInRoom2C |
| ExitRight `$A671` | X `$E8` or more (walking), `$E7` (jumping) | column + 1, 11 wraps to 0; from an explorer room, room `$29` | X 2 | HeroUpdate, JumpArc, BarrelRideLong |
| ExitUp `$A69B` | Y above 0 | level - 1; on level 0 the hero is put back | Y `$66` | HeroUpdate, BounceUp, Hover, JumpStepY, BalloonRide, LiftUp |
| ExitDown `$A6AE` | Y `$67` or more (`$68` when falling or jumping) | level + 1; from level 5 the hero is put back | Y 2 | HeroUpdate, HeroFall, Hover, LiftDown, BalloonRide, JumpHoleCheck |

```text
ExitLeft:
    level, column = Room / 12, Room mod 12
    if Room == $29: Room = ExplorerRooms[Explorer]      ; $2D, $2E, $2F, $46, $47
    else: Room = 12 * level + (column - 1) mod 12
    Hero.X = $E6
    SetUpRoom(Room)

ExitRight:
    if Room in ExplorerRooms: Room = $29
    else: Room = 12 * level + (column + 1) mod 12
    Hero.X = 2
    SetUpRoom(Room)
```

```mermaid
flowchart LR
    R29["room $29"] -- "left, explorer 0" --> R2D["$2D"]
    R29 -- "left, explorer 1" --> R2E["$2E"]
    R29 -- "left, explorer 2" --> R2F["$2F"]
    R29 -- "left, explorer 3" --> R46["$46"]
    R29 -- "left, explorer 4" --> R47["$47"]
    R2D -- right --> R29
    R2E -- right --> R29
    R2F -- right --> R29
    R46 -- right --> R29
    R47 -- right --> R29
    C0["column 0"] -- left --> C11["column 11, the same level"]
    C11 -- right --> C0
```

The horizontal wrap makes every level a ring of 12 rooms. The explorer rooms replace the usual left neighbour of room
`$29` (room `$28`, the space scene), so each explorer sees only his own room there. Room `$28` is never entered by an
exit: only LoseGame and ProfessorEnding set it.

![The 72 rooms](img/maps/rooms.png)

The map: every room drawn from `src/res/rooms/rooms.txt` by `tools/fig_rooms.py` (doc 06).

How to read the map:

- 12 rooms to a row, one row a level, the surface at the top.
- The last row ends with rooms `$46` and `$47`.

**The point**: the map is a 12 x 6 grid that wraps sideways. The only special link is room `$29`'s left exit, which
leads to the chosen explorer's room.

Worked example: the RZX run's first exits. The run starts in room `$14` (level 1, column 8). By RZX 750 it is in room
`$07` (level 0, column 7), one level up and one column left. The samples of `work/stage1/rzx/vars.bin` show it there
with the first pickup made (score 50).

Witness:

- ExitLeft: 30 exits in 17 rzx segments, 3 of them wrapping. The room `$29` path ran once, with explorer 0.
- ExitRight: 38 exits in gameover and 18 rzx segments; the explorer room path once.
- ExitUp: 13 calls, 5 of them blocked (`.ann`).

## 10.2 The statuses

The hero's state is Status `$5C06`, 0-33, with StatusTimer `$5C07` counting the passes inside it. Status 0 is the
normal update (walk, climb, fall, jump start). Every other status is a handler that replaces the rest of the update:
StatusDispatch `$A6CC` jumps to word N - 1 of StatusHandlers `$A72E`, and each handler starts with a POP that drops
the return into HeroUpdate.

```asm
StatusDispatch:
  LD A,(Status)
  OR A
  RET Z                   ; status 0: the normal update goes on
  LD C,$FF                ; no sound, for the death lists
  DEC A
  ADD A,A
  LD L,A
  LD H,$00
  PUSH DE
  LD DE,StatusHandlers    ; word N - 1 for status N
  ADD HL,DE
                          ; falls into JumpThroughWord: pop DE, JP (word)
```

| Status | Handler | What | Set by |
| ---: | --- | --- | --- |
| 0 | none | the normal update | ClearStatus `$AE84` |
| 1, 2, 3 | JumpArc `$ADAC` | the jump: 1 off an edge after three refusals, 2 the fire key, 3 the hop out of room `$18`'s ladder top | RefuseDrop, StartJump `$A465`, ClimbOutTop |
| 4 | Hover `$AD32` | hover with the Vacuum Cleaner in rooms `$14` and `$08` | StartHover `$A42B` |
| 5 | BounceUp `$AD17` | rise 4 pixels a pass, then the jump arc | PickUpItem (the Spring, the Trampoline) |
| 6 | Status6Entry `$A5F0` | stand and animate: the Flute played | RopeTrick `$BC73` |
| 7, 8 | BalloonRide `$AC35` | in the balloon | StatusZeroTriggers `$AF3B` |
| 9 | BalloonCrash `$AC1A` | the balloon falls | BalloonRide, in room 3 with the Party Manifesto |
| 10 | Think `$AB6E` | the T key: think | ThinkKey `$B02E` |
| 11 | BrightIdea `$ABC7` | the idea: an item | Think |
| 12 | NoIdea `$ABD9` | no idea: head shaking | Think |
| 13 | BarrelSpot `$AA3C` | at room `$1D`'s barrel spot | StatusZeroTriggers |
| 14 | BarrelRide `$AA6F` | the ride in the Barrel Medium | BarrelSpot |
| 15 | BarrelRideShort `$AAA7` | the Barrel Small: fatal | BarrelSpot |
| 16 | BarrelRideLong `$AABA` | the Barrel Big: on to the next room, fatal | BarrelSpot |
| 17 | SinkInMud `$AA04` | sink one row into the mud | HeroTileChecks, after 50 passes on mud |
| 18 | LoseLifeWait `$A9EE` | 50 passes, then a life lost | StartDying `$AAF0` |
| 19 | LiftUp `$A96B` | the lift up | LiftPlatform `$AF81` |
| 20 | LiftDown `$A9C4` | the lift down | LiftPlatform |
| 21 | RideObject4 `$A95F` | carried by the basket | BasketScript `$B409` |
| 22 | Teleport `$A8EA` | the teleport pads | TeleportPadCheck `$B03B` |
| 23 | SilentDeath `$A8A8` | room `$20`'s pad, the radiation, room `$39`'s creature | Teleport, RadiationScript, SilverCrossScript |
| 24 | CreatureDeath `$A89E` | a creature's touch, the beam | HitExplorer `$C0DA`, RoomEffects `$9262` |
| 25 | Room1ADeath `$A88F` | a snake's bite | RunSnakes `$B57C` |
| 26 | FallDeath `$A888` | the fall, tile `$A5`, the balloon crash, room `$2E` | HeroLand, HeroTileChecks, BalloonCrash, ExplorerRoom2E, HitExplorer |
| 27 | Room43Anim `$A851` | the Silver Lining becomes the Silver Cross | SilverLiningScript `$B704` |
| 28 | Room2DAnim `$A828` | the Cricket Ball throw | CricketBallScript `$B370` |
| 29 | Frozen `$A90E` | nothing: a script moves the hero | LoseGame, ProfessorEnding, Room2DAnim, ExplorerRoom46 |
| 30 | LookIntoTelescope `$A822` | bend to the telescope | TelescopeRoom `$B16A` |
| 31 | TelescopeView `$A7B9` | the asteroid and the time left | LookIntoTelescope |
| 32 | DrinkPose `$A783` | room `$2E`, the Beer Barrel | ExplorerRoom2E `$B263` |
| 33 | FlashPose `$A770` | room `$47`, the Flashgun | ExplorerRoom47 `$B18A` |

Several `.ann` comments name the handler of status N + 1 for status N (the snakes "`$19` (`$A888`)", the basket "`$15`
(`$A8EA`)", and others). The table holds word N - 1 for status N, so those names are one status off. The list is in
`work/docs/tmC-src-changes.md` for the lead.

```mermaid
stateDiagram-v2
    [*] --> Normal: status 0
    Normal --> Jump: fire, 3 refusals, room $18 ladder top (1-3)
    Jump --> Normal: step 17 or a floor
    Normal --> Bounce: on the Spring or Trampoline from a jump (5)
    Bounce --> Jump: a floor under the feet
    Normal --> Rides: hover 4, balloon 7-9, barrels 13-16, lift 19-20, basket 21, teleport 22
    Rides --> Normal: the ride ends
    Normal --> Scripted: think 10-12, Flute 6, scenes 27-33
    Scripted --> Normal: the frames end
    Normal --> Dying: deaths 23-26, mud 17
    Jump --> Dying: a creature (24)
    Rides --> Dying: barrels 15-16, balloon crash 9, the pad of room $20
    Dying --> Lose: status 18, 50 passes
    Lose --> Normal: Lives - 1, the respawn
    Lose --> SpaceScene: Lives = 0 (29)
```

![StatusDispatch at work](img/routines/StatusDispatch.gif)

The animation of StatusDispatch, made by another writer, shows the dispatch through the table.

**The point**: one byte selects the hero's whole behaviour. The deaths, the rides and the scripted scenes are all
statuses, so a creature can only kill a hero whose status is below 15 (doc 07.6).

Witness: StatusDispatch makes 9 430 dispatches in c1, explorers, gameover and 26 rzx segments (`.ann`). Each status's
witness is given in its section.

## 10.3 Walking and climbing

In status 0, HeroUpdate `$A3E1` reads the controls into E (bit 0 right, 1 left, 2 down, 3 up, 4 fire). Left with right
or up with down reads as nothing (ReadControls). The steps:

```text
HeroUpdate, status 0, not falling:
    if fire and standing and not on the lift and not on the unicycle and (Room != $1A or Y >= $3A):
        StartJump: Status = 2, JumpDirection = E, sound 6
    if right: X += 2, facing right; X >= $E8: ExitRight
    if left:  X -= 2, facing left;  X < 4: ExitLeft
    if down and OnLadder: Y += 2, ClimbFrame; Y >= $67: ExitDown
    if up and OnLadder:   Y -= 2, ClimbFrame; above 0: ExitUp (room $18: hop out, status 3)
    HeroTileChecks
    if a wall at the leading edge: X back
    if OnLadder: nothing more
    elif floor distance 0: HeroLand
    elif floor distance 1-4: HeroFall
    else: RefuseDrop (unless the umbrella is held)
    the walk frame: 0-3 every other pass, 2 at rest
```

The climb frame is `$20 + (Y AND 6) / 2`, so the four climb frames change every 2 pixels. A ladder is a tile `$98` or
`$99` in every room, also `$92` and `$95` on level 0, or `$C6`, `$C7`, `$CE`, `$CF` with the alternate tile set
(OnLadder `$A193`). The test reads the tile under the middle of the feet (X + 12, Y + 23).

```asm
  CP $67                  ; down a ladder: Y >= $67 leaves by the bottom
  JP NC,ExitDown
  JR ClimbFrame
  ...
ClimbFrame:               ; A = Y
  AND $06                 ; frame $20 + (Y AND 6) / 2: the four climb frames
  RRCA
  ADD A,$20
  LD (IX+$02),A
  RET
```

```mermaid
flowchart TD
    E["E = the controls"] --> J{"fire, standing, not on the lift or unicycle?"}
    J -- yes --> SJ["StartJump: status 2"]
    J -- no --> H["left / right: X +- 2, exits"]
    H --> V{"up / down on a ladder tile?"}
    V -- yes --> CL["Y +- 2, frames $20-$23, exits"]
    V -- no --> P
    CL --> P["HeroTileChecks: walls, floor distance, deadly tile, mud"]
    P --> W{"a wall ahead?"}
    W -- yes --> XB["X back"]
    W -- no --> G
    XB --> G{"floor distance"}
    G -- "ladder" --> F0["nothing more"]
    G -- 0 --> LAND["HeroLand"]
    G -- "1-4" --> FALL["HeroFall"]
    G -- "5 or more" --> REF["RefuseDrop, or fall with the umbrella"]
```

![The hero climbing, driven with the Kempston joystick](img/play/climb-kempston.gif)

The animation was made by another writer. It shows the climb frames changing as the hero moves up a ladder.

**The point**: the walk and the climb are 2 pixels a pass, the same step as every creature. The ladder is a property
of a tile under the hero's middle, not of the room.

Worked example: `rzx24750` frames 612-614. The hero walks left in room `$30`: X `$4C` in the samples of 612 and 613,
`$4A` in 614, frame 3. The walk frame steps only on every other pass (PassCount bit 0), and the X changes once a pass
because the pass is about 2.8 frames long.

Witness: HeroUpdate's climb runs 439 passes in 8 rzx segments (`.ann`, OnLadder). HeroWalkFrames runs 15 541 times in
the 34 builds.

## 10.4 The jump

A jump lasts 17 passes. Each pass sets the frame from JumpFrames `$AE8D`, moves Y by JumpRise `$AE9E` and moves X by 2
in the jump's direction. A floor under the feet ends the jump early, and step 17 puts the hero on the row.

| Step | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| frame | `$0C` | `$0C` | `$0D` | `$0D` | `$0E` | `$0E` | `$0E` | `$0E` | `$0E` | `$0F` | `$0F` | `$0F` | `$0F` | `$0F` | `$0F` | 2 | 2 |
| rise | 4 | 3 | 3 | 3 | 2 | 2 | 1 | 0 | 0 | 0 | -1 | -2 | -2 | -3 | -3 | -3 | -4 |

The rise sums to 18 pixels up and 18 down. A sideways jump covers 17 x 2 = 34 pixels. The hero is 24 pixels tall, so a
jump clears less than his own height.

```text
JumpArc (statuses 1, 2, 3):
    Hero.frame = JumpFrames[StatusTimer]
    step = StatusTimer; StatusTimer += 1
    if step == $11: Y = Y AND $F8; Status = 0; return
    JumpStepY(step):
        if step == $10 and over the hole of $5BA2: fall to the room below
        Y -= JumpRise[step]
        if Y < 0: ExitUp; if Y >= $68: ExitDown
        if a floor under the feet: frame 2, Status = 0
    if JumpDirection has left or right:
        X += 2 or X -= 2 (exits at $E7 and at 1-2)
        if a wall at the leading edge: X and Y back
```

```asm
JumpArc:
  POP HL
  LD DE,JumpFrames
  CALL FrameFromTable
  LD HL,StatusTimer
  LD A,(HL)
  INC (HL)
  CP $11                  ; step 17: onto the row, status 0
  JR NZ,JumpMove
  LD A,(IX+$01)
  AND $F8
  LD (IX+$01),A
  JP ClearStatus
JumpMove:
  CALL JumpStepY
  LD A,(JumpDirection)
  LD E,A
  AND $03                 ; straight up: no X move
  RET Z
  ...
```

```mermaid
stateDiagram-v2
    [*] --> Rising: StartJump, status 2, sound 6
    Rising --> Rising: steps 0-6, Y - 4 to - 1
    Rising --> Top: steps 7-9, Y kept
    Top --> Falling: steps 10-16, Y + 1 to + 4
    Falling --> Landed: a floor under the feet, frame 2
    Falling --> Landed: step 17, Y onto the row
    Rising --> Bounce: on a Spring, status 5
    Falling --> Bounce: on a Spring, status 5
    Landed --> [*]: status 0
```

![The hero's Y in two gameover passages: the jump and the bounce, and the fatal fall](img/gameplay/jump-fall.png)

The figure: `gameover` frames 405-530 (left) and 1278-1376 (right), from the samples (`work/docs/tmC/go/vars.jsonl`),
drawn by `tools/fig_gameplay.py`.

```bash
python3 tools/fig_gameplay.py docs/img/gameplay
```

How to read the figure:

- Left: the hero's Y, one dot a frame, coloured by the status: white 0, yellow 2 (JumpArc), pink 5 (BounceUp). In room
  `$1C` the Y is drawn `$68` lower, so the climb into room `$10` reads as one curve. The dashed line is JumpRise, one
  step a pass.
- Right: the fall; the dots are the Y, the blue steps are FallPasses `$5C05`. The dotted line is the limit of 20.

**The point** (left): a jump is one curve of 17 passes. The Spring turns its fall into a climb of 4 pixels a pass, high
enough to pass through the ceiling into the room above.

![JumpArc at work: the jump onto the Spring and the bounce](img/routines/JumpArc.gif)

The animation shows `gameover` frames 413-462, in 80 pictures, with the screen as the view. The code panel follows
JumpArc `$ADAC-$AE8C`, BounceUp `$AD17` and PickUpItem `$BB6C`.

```bash
python3 ../../kit/routine_anim.py --work work/docs/tmC/go --window 413:0-462:0 --listing build/game.lst \
  --pc ADAC-AE8C,AD17-AD31,BB6C-BC06 --view screen --range 5B00-5CFF --pictures 80 --delay 120 \
  --title "A jump (status 2, JumpArc) onto the Spring in room \$1C: at step 12 PickUpItem sets the hero on it, status 5 (BounceUp) lifts him 4 pixels a pass (gameover, frames 413-462)" \
  --out docs/img/routines/JumpArc.gif
```

Worked example: `gameover`, room `$1C`. The hero stands on the floor next to the Spring at X `$50`, Y `$48`.

1. Frame 414: fire, straight up. The sample of 415 shows status 2.
2. The Y samples go `$48`, `$44`, `$41`, `$3E`, `$3B`, `$39`, `$37`, `$36`, `$36`, `$36`, then `$37` at step `$0B`.
   These are the JumpRise steps 4, 3, 3, 3, 2, 2, 1, 0, 0, 0, -1.
3. In frame 447, at StatusTimer `$0B`, PickUpItem finds him near the Spring (item slot 1: X `$50`, Y `$48`), in status
   2 with the timer 10 or more and |dX| = 0. It sets Y = `$48` - `$17` = `$31`, frame `$0F` and status 5.
4. BounceUp lifts him 4 pixels a pass. In frame 485 he leaves the top of the room (Y 1), and in frame 486 he is in room
   `$10` at Y `$66`.
5. In frame 523 a floor is under his feet: status 2, the jump arc to its end. Status 0 at 526.

Witness: JumpArc runs 2 391 passes in gameover and 23 rzx segments; BounceUp 67 passes in gameover, rzx10000 and
rzx22000 (`.ann`).

## 10.5 The fall, the refusal and the umbrella

HeroTileChecks puts the number of tile rows below the feet in HeroProbes+3 (FloorDistance `$A1F4`). HeroUpdate then
chooses:

| Rows | What happens |
| --- | --- |
| 0 | land (HeroLand `$A5B9`) |
| 1-4 | fall (HeroFall `$A570`) |
| 5 or more | refuse (RefuseDrop `$A545`): the hero is put back and shakes his head; the third refusal in a row jumps off the edge (status 1). With the Umbrella in hand he falls instead |

A falling hero moves 2 pixels, probes again, and moves 2 more while still above the floor: 4 pixels a pass. The input
is ignored. Each pass counts FallPasses `$5C05`, except with the Umbrella in hand. A landing after 20 fall passes or more
kills: status 26.

The Umbrella exception has its own exceptions, decided by the room and X:

- in rooms `$35` and above, the passes count even with the Umbrella;
- in rooms `$10` and `$1C`, left of X `$80`, they count even with the Umbrella;
- everywhere else, the Umbrella stops the count.

```asm
HeroFall:
  INC (IX+$01)            ; 2 pixels, probe, 2 more while still above the floor
  INC (IX+$01)
  CALL HeroTileChecks
  LD A,(IY+$03)
  OR A
  JR Z,HeroFalling
  INC (IX+$01)
  INC (IX+$01)
  LD A,(Room)             ; count the fall passes unless the umbrella is in use ...
  CP $35
  JR NC,HeroFallCount
  BIT 7,(IX+$00)
  JR NZ,HeroFallUmbrella
  CP $10
  JR Z,HeroFallCount
  CP $1C
  JR Z,HeroFallCount
HeroFallUmbrella:
  LD A,(HeldItem)         ; ... rooms $35 and up, and rooms $10 and $1C left of X $80
  CP $05
  JR Z,HeroFalling
HeroFallCount:
  LD HL,FallPasses        ; + 1, kept at 255
  INC (HL)
  JR NZ,HeroFalling
  DEC (HL)
HeroFalling:
  LD E,$00                ; no input while falling
  LD A,$01
  LD (Falling),A
  LD A,(IX+$01)
  CP $68
  JP NC,ExitDown
  JR HeroWalkAnim
HeroLand:
  LD HL,FallPasses        ; 20 fall passes or more kill
  LD A,(HL)
  LD (HL),$00
  CP $14
  LD A,$1A
  CALL NC,SetStatus
  LD A,(IX+$01)           ; Y onto the row
  AND $F8
  LD (IX+$01),A
```

```mermaid
flowchart TD
    P["HeroTileChecks: rows to a floor"] --> Z{"rows"}
    Z -- 0 --> L["HeroLand"]
    Z -- "1-4" --> F["HeroFall: 2 px, probe, 2 px"]
    Z -- "5+" --> U{"Umbrella held?"}
    U -- yes --> F
    U -- no --> R["RefuseDrop: back, head shake; the third time status 1"]
    F --> C{"room >= $35, or room $10/$1C with X below $80?"}
    C -- yes --> CNT["FallPasses + 1"]
    C -- no --> UM{"Umbrella held?"}
    UM -- yes --> NC["not counted; frame $0B high up"]
    UM -- no --> CNT
    CNT --> D{"Y >= $68?"}
    NC --> D
    D -- yes --> X["ExitDown: the room below, the count goes on"]
    L --> K{"FallPasses >= 20?"}
    K -- yes --> S26["status 26: FallDeath"]
    K -- no --> OK["Y AND $F8, mud sinks 2 or 4 px"]
```

A room entry saves the respawn point only while FallPasses is 0, so a falling hero never saves a checkpoint mid-fall
(doc 07.2).

**The point** (right panel of the figure in 10.4): the umbrella is a parachute everywhere except in the deep levels and
in the shaft of rooms `$10` and `$1C`. That shaft is exactly where the RZX player lost his only life.

![FallDeath at work: the last passes of the fatal fall](img/routines/FallDeath.gif)

The animation shows `gameover` frames 1335-1373, in 76 pictures, with the screen as the view. The code panel follows
HeroUpdate `$A3E1-$A63F`, FallDeath `$A888-$A8E9` and StartDying `$AAF0`.

```bash
python3 ../../kit/routine_anim.py --work work/docs/tmC/go --window 1335:0-1373:0 --listing build/game.lst \
  --pc A3E1-A63F,A888-A8E9,AAF0-AAF9 --view screen --range 5B00-5CFF --pictures 76 --delay 120 \
  --title "The last passes of a 21-pass fall in room \$1C, the landing (FallPasses 21 >= 20: status 26) and FallDeath's frame \$1C (gameover, frames 1335-1373)" \
  --out docs/img/routines/FallDeath.gif
```

Worked example: `gameover`, the RZX player's fall, from the samples.

| Frame | Room | Hero | HeldItem | FallPasses | Status |
| ---: | --- | --- | --- | ---: | --- |
| 1283 | `$10` | `72 40 03 00` | `05` (Umbrella) | 0 | 0 |
| 1284 | `$10` | `72 44 0B 00` | `05` | 1 | 0 |
| 1310 | `$10` | `72 64 0B 00` | `05` | 9 | 0 |
| 1311 | `$1C` | `72 02 0B 00` | `05` | `$0A` | 0 |
| 1360 | `$1C` | `72 30 02 00` | `05` | `$15` (21) | 0 |
| 1361 | `$1C` | `72 30 02 00` | `05` | 0 | `$1A` |
| 1364 | `$1C` | `72 30 1C 00` | `05` | 0 | `$1A` |
| 1372 | `$1C` | `72 30 1C 00` | `05` | 0 | `$12` |

Step by step:

1. The hero walks left off a ledge in room `$10` at X `$72`, below `$80`, with the Umbrella in hand. Frame `$0B` is the
   umbrella pose.
2. Room `$10` and X below `$80`: the passes count despite the Umbrella.
3. He falls through the floor into room `$1C`. The count goes on: `$0A` at the entry, 21 at the landing.
4. FallPasses 21 is 20 or more: status 26 in frame 1360. FallDeath shows frame `$1C` (the flattened hero) and moves to
   status 18 at 1372.

Witness: HeroLand's kill ran in gameover (frame 1360), rzx10000 (the same fall) and rzx24000 (`.ann`, FallDeath). The
refusal frames play 7 times in 3 rzx segments (RefuseFrames).

## 10.6 The rides

Each ride is a status that moves the hero by its own rules until it ends.

| Ride | Status | Start | Motion | End | Witness |
| --- | --- | --- | --- | --- | --- |
| Bounce | 5 | landing on the Spring (14) or the Trampoline (20) in a jump (doc 07.9) | Y - 4 a pass, through the ceiling into the room above | a floor: status 2 | gameover, rzx10000, rzx22000: 67 passes |
| Hover | 4 | the Vacuum Cleaner (10) in hand in room `$14` or `$08` | frame `$1D`; 2 pixels in four directions | another item in hand | 4 908 passes in c1, explorers, rzx00000 |
| Lift down / up | 20 / 19 | down or up on the lift platform (LiftPlatform `$AF81`, X `$1A-$2F`) in the lift's room | Y + 2 or - 2 a pass along column 7 | the stop of rooms `$1F`, `$2B`, `$37`, `$43` | down: 220 passes in rzx20000, rzx36000; up: none |
| Balloon | 7, 8 | standing at the balloon (StatusZeroTriggers) | the Bellows (6): rise 1 a pass; the Party Manifesto (7): rise; any other item: sink 2 a pass | on the ground, step out left or right | rzx14000 frames 696-1104, 452 passes, the Bellows |
| Balloon crash | 9 | rising with the Party Manifesto to the top of room 3 | sink | the ground: status 26 | none |
| Barrel spot | 13 | left held at Y `$48`, X `$1C-$1F` in room `$1D` | frame `$17`, wait 5 passes | the barrel in hand chooses 14, 15 or 16 | rzx16000 frames 479-491 |
| Barrel Medium | 14 | item 9 in hand | 84 passes, X + 2, Y along BarrelArc `$AAFA` | status 0 | rzx16000 frames 508-745 |
| Barrel Small | 15 | item 28 in hand | BarrelShortArc, 32 passes | frame `$1C`, status 18: death | none |
| Barrel Big | 16 | item 27 in hand | X + 2, 100 passes, on to the next room | status 18: death | none |
| Basket | 21 | near the basket at its end in room `$3F` | the hero takes the basket's place, frame `$2D` | the other end: Y - 8, status 0 | 418 passes in rzx28000, rzx32750, rzx34000 |
| Float | none: FloatInRoom2C replaces the update | entering room `$2C` | velocity -3..3 on each axis, +1 a pass towards the held direction, bounce off walls | the left exit | rzx18000, rzx20000: 149 passes |
| Teleport | 22 | standing on a pad (TeleportPads `$B073`) with CrystalPlaced set | TeleportFrames, then the other pad | room `$30` to `$3D`, `$3D` to `$20`; the pad of room `$20` kills (status 23) | rzx24750 frames 731-780, rzx34000 frames 1461-1512 |

```text
TeleportPadCheck (every pass in status 0):
    for (room, Y, X) in TeleportPads:            ; ($20,$58,$80) ($3D,$38,$60) ($30,$58,$60)
        if Room == room and Hero.Y == Y and X <= Hero.X < X + 8:
            if not PadLatch: Status = 22
            return
    PadLatch = 0                                 ; off every pad

Teleport (status 22):
    first pass: LiftRoom = $1F, LiftY = $50
    Room $30: destination $3D, only while CrystalPlaced
    Room $3D: destination $20, only while CrystalPlaced
    Room $20: Status = 23 (the silent death)
    play TeleportFrames; at the room byte: SetUpRoom(destination), PadLatch = pad X
```

```mermaid
stateDiagram-v2
    [*] --> OnPad: Y and X on a pad, PadLatch 0
    OnPad --> Waiting: CrystalPlaced 0
    Waiting --> Waiting: nothing happens
    OnPad --> Frames: CrystalPlaced set, room $30 or $3D
    Frames --> Arrived: the room byte, SetUpRoom, PadLatch = X
    Arrived --> [*]: frames end, status 0
    OnPad --> Death: room $20, status 23
```

![The teleport between two rooms](img/play/teleport-r24750.gif)

The animation shows `rzx24750` frames 716-786, every second frame, at twice the size. The hero jumps onto the pad of
room `$30`, dissolves, and appears in room `$3D`.

```bash
python3 ../../kit/screen_anim.py --work work/docs/tmC/r247 --from 716 --to 786 --step 2 --scale 2 --delay 100 \
  --hold 2000 docs/img/play/teleport-r24750.gif
```

Worked example: `rzx24750`. The crystal was placed at frame 613 (doc 07.10). The hero jumps in frame 721 (status 2 in
the sample of 722) and lands on the pad at Y `$58`, X `$62`: the pad of room `$30` is (`$58`, `$60`), and `$62` is
within `$60-$67`. Status 22 shows in the sample of 731. The frames run to 780, and the hero arrives in room `$3D`.

The float of room `$2C` starts with the velocity `$FF02` (SetUpRoom): dx = +2, dy = -1.

**The point**: each puzzle item is a vehicle. The game's movement is mostly in these rides, and three of them kill on
purpose: the Barrel Small, the Barrel Big and the pad of room `$20`.

Witness: in the table. Teleport's two runs are the only ones in the builds (`.ann`).

## 10.7 Deaths, lives and the restart

Every death goes the same way: a death status plays a frame list, then status 18 waits 50 passes and takes a life.

| Status | Handler | Causes | Frames (FallDeathFrames `$A8BF`) | Sound |
| ---: | --- | --- | --- | --- |
| 26 | FallDeath `$A888` | a landing after 20 fall passes; tile `$A5` under the feet; the balloon crash; room `$2E`'s creature; a creature's touch while standing | `$1C` | 0 at the end |
| 23 | SilentDeath `$A8A8` | room `$20`'s pad; room `$3C` without the Pills; room `$39`'s creature without the Silver Cross | 30 frames: `$04 $05 $04 $02 $06 ...`, then `$29 $2A $2B $2C` | none |
| 24 | CreatureDeath `$A89E` | a creature's touch; the electric beam | `$25 $26 $27 $28 $7F` | 3 every pass |
| 25 | Room1ADeath `$A88F` | a snake's bite | `$14 $15 $16` | 4 at the end |
| 18 (direct) | | the Barrel Small, the Barrel Big, room `$2F` without the Unicycle, room `$46` without the Spurs, room `$47`'s creature | | |

```text
DeathFrames(DE = the list, C = the sound):     ; statuses 23-26
    Hero.frame = DE[StatusTimer / 2]; StatusTimer += 1
    at $FF: PlaySound(C) unless $FF; StartDying: Status = 18

LoseLifeWait (status 18):
    StatusTimer += 1
    if StatusTimer != 50: return
    LifeLost = 50                        ; the main loop sees it and runs Respawn
    Lives -= 1                           ; LifeLossOp $A9FD
    if Lives == 0: LoseGame
    else: DrawSpareLives

Respawn ($9090), from the main loop:
    Status, StatusTimer, Room, Hero X Y frame flags, the lift = the respawn state $5C2B-$5C33
    SetUpRoom(Room)
```

```asm
LoseLifeWait:
  POP HL
  LD HL,StatusTimer
  INC (HL)
  LD A,(HL)
  CP $32                  ; 50 passes
  RET NZ
  LD (LifeLost),A
  LD HL,Lives
LifeLossOp:
  DEC (HL)                ; GameEntry makes it OR A when InfiniteLives is 1
  JP Z,LoseGame
  JP DrawSpareLives
```

The respawn state is written by SaveRespawnPoint `$9AA1` on every entry into one of the 44 CheckpointRooms while the
hero is not falling, and by InitGame. A life lost in an unlisted room restarts in the last listed room entered, at the
place and status of that entry.

The 44 checkpoint rooms are:

- `$00 $01 $04 $07 $08 $09 $0C $0D $0E $12 $13 $14 $15 $17 $18 $19 $1A $1B $1F $21 $22 $23`;
- `$26 $27 $28 $29 $2A $2C $30 $31 $32 $33 $34 $35 $36 $38 $39 $3A $3B $3D $3E $40 $44 $45`.

The infinite lives: the loader sets InfiniteLives `$5B03` to 1 when `$8000` held `$C9` before the load, and GameEntry
then makes LifeLossOp an `OR A` (doc 03). SK's POKE 43517,182 does the same.

```mermaid
stateDiagram-v2
    [*] --> DeathStatus: 23, 24, 25 or 26
    DeathStatus --> Waiting: the frame list ends, sound, status 18
    Waiting --> Waiting: StatusTimer + 1
    Waiting --> Respawn: 50 passes, Lives - 1 > 0
    Waiting --> LoseGame: Lives - 1 = 0
    Respawn --> [*]: the last checkpoint, status from the respawn state
    LoseGame --> SpaceScene: room $28, status 29
```

![The four death frame lists](img/gameplay/death-frames.png)

The figure: the four lists of FallDeathFrames `$A8BF` from the built image, drawn with explorer 0's sprites by
`tools/fig_gameplay.py`.

```bash
python3 tools/fig_gameplay.py docs/img/gameplay
```

How to read the figure:

- One block a death status: its handler, its causes, the number of frames and the sound.
- Each sprite is one frame of the list, 2 passes each; "x n" merges n repeats of one frame.
- Status 26 is one frame: the flattened hero. Status 23 is the long one: the hero swaying, then collapsing.

**The point**: four lists, four ways to die on screen, then one common wait. The sound tells the deaths apart as much as
the picture.

Worked example 1: the creature death of `rzx06000` (doc 07.6) and its restart.

| Frame | Status | Room | Hero | Lives |
| ---: | ---: | --- | --- | ---: |
| 536 | `$18` | `$0C` | `A2 56 0F 80` | 4 |
| 564 | `$12` | `$0C` | `A2 56 7F 80` | 4 |
| 688 | `$12` (timer `$31`) | `$0C` | `A2 56 7F 80` | 4 |
| 689 | 0 | `$0C` | `02 60 13 80` | 3 |

Status 18 starts at 564 and runs 50 passes to 688. In frame 688 the life is lost and the respawn puts the hero back at
the entry point of room `$0C`: X 2, Y `$60`, the place where he walked in from the left.

![The touch of a riser and the restart](img/play/creature-death-r06000.gif)

The animation shows `rzx06000` frames 520-700, every third frame, at twice the size.

```bash
python3 ../../kit/screen_anim.py --work work/docs/tmC/r06 --from 520 --to 700 --step 3 --scale 2 --delay 100 \
  --hold 2000 docs/img/play/creature-death-r06000.gif
```

Worked example 2: the last life in `gameover`. Status 18 runs from 1372 to 1502. In frame 1502 Lives goes from 1 to 0,
and LifeLossOp jumps to LoseGame: Room `$28`, the respawn state set to room `$28` with status `$1D`. The respawn of
frame 1509 restores exactly that, and status 29 shows in the sample of 1510 (10.10).

Witness: LoseLifeWait runs in gameover (frames 1374-1502) and five rzx segments: rzx06000, rzx10000, rzx22000,
rzx24000 and rzx32000. SaveRespawnPoint runs 78 times in 27 builds (`.ann`).

## 10.8 Creatures and hazards

The creature types are in doc 07.5. Here is what each means for the hero.

| Hazard | Where | Kills when | Death | Defence |
| --- | --- | --- | --- | --- |
| Drop | 18 rooms | it touches him (8-pixel box) on any pass | 24, or 26 if standing | timing: it waits a random time |
| Riser | 16 rooms | it stands fully up (index 3) and touches him | 24 or 26 | pass while it rises or rests |
| Walker, climber, flier, still creature | 19 rooms | a frame with the hit flag touches him | 24 or 26 | jump over, or wait |
| Snakes | rooms `$17`, `$1A` | the snake's X equals the hero's X rounded down to 4 pixels | 25 | the Flute in hand (in room `$1A` only above Y `$3A`) |
| Radiation | room `$3C` | 20 passes in the room without having picked up the Pills | 23 | the Anti Radiation Pills (22), picked up once |
| Room `$39`'s creature | room `$39` | the hero below Y `$48`, X `$62` or more, status below 4 | 23 | the Silver Cross (29): it flees |
| Electric beams | rooms `$20`, `$38`, `$39`, `$3A`, `$3C`, `$43` | the hero inside a beam's span and within 12 rows, status below 4 | 24 | timing |
| Mud | tiles `$BC`, `$BD` (rooms `$35`, `$36` flicker them) | 50 passes standing on them | 17: sink one row | keep moving |
| Tile `$A5` | the normal tile set | standing on it in status 0 | 26 | do not step on it |
| Long falls | anywhere | 20 fall passes | 26 | the Umbrella, outside the exceptions |

```text
RunSnakes (rooms $17, $1A), for each snake slot:
    if frame == $7F: skip
    if frame == $55: frame = $7F; Status = 25            ; struck last pass: the bite
    else:
        frame = $51 + (step through $51-$54 by PassCount bit 0)
        if Hero.X AND $FC == snake X and not charmed: frame = $55   ; the strike
charmed = HeldItem == $0C and (Room == $17 or Hero.Y < $3A)
```

```mermaid
flowchart TD
    S["a snake, each pass"] --> G{"frame $7F?"}
    G -- yes --> N["skip"]
    G -- no --> B{"frame $55?"}
    B -- yes --> BITE["frame $7F, status 25: the bite"]
    B -- no --> A["frame steps $51-$54"]
    A --> X{"its X = hero X AND $FC?"}
    X -- no --> N
    X -- yes --> F{"Flute held, and room $17 or Y below $3A?"}
    F -- yes --> N
    F -- no --> ST["frame $55: the strike"]
```

The strike and the bite take two passes: the strike frame `$55` shows for one pass before the bite. That pass is the
hero's only warning.

**The point**: most hazards have an item that defuses them, and the item must be in the hand, not on a bearer. The
creatures and the beams are pure timing.

Worked example: the snakes of room `$1A` in the RZX run. At RZX 11 750 the hero has just restarted in room `$1A` with
the Umbrella in hand (`work/stage1/rzx/vars.bin`). At RZX 12 000 he holds the Flute (`$0C`), and at 12 250 he is in room
`$19`, past the snakes, with 3 lives. The replay of `rzx10000` drifts at its end: there the hero is bitten in frame
1943 (Room1ADeath, frames 1943-1958), which the RZX's own state at 12 000 does not show.

Witness:

- The snake strike and bite ran once each, in rzx10000's drifted end (`$B5C2`, `$B5C8`).
- The radiation death branch (`$B796`) never ran. A clone probe (`work/stage2/probe_points.py` C: the RZX state at
  44 000 with PillsTaken = 0, room `$3C` entered from `$3D`) shows status 23 at frame 70, status 18 at 225, and the
  restart in room `$3B` at 355 with Lives 3 to 2.
- The beam's hit (`$9262`), the mud sink (`$A15A`) and tile `$A5` (11 772 tests, no match) never ran.

## 10.9 Items and puzzles

Every puzzle test reads HeldItem. The table gives every item, where it lies (doc 07.8), and what holding it does.

| Item | Name | Lies in | Use |
| ---: | --- | --- | --- |
| 0 | Unicycle | `$0B` | room `$2F` (explorer 2): ride across; unicycle frames, no jump |
| 1 | Flashgun | `$22` | room `$47` (explorer 4): flash the creature (status 33) |
| 2 | Cricket Ball | `$0C` | room `$2D` (explorer 0): throw it at X `$DC`, a Formula falls |
| 3 | Spurs | `$10` | room `$46` (explorer 3): ride the creature |
| 4 | Beer Barrel | `$2A` | room `$2E` (explorer 1): the creature drinks (status 32) |
| 5 | Umbrella | `$00` | slows falls: no fall count, except rooms `$35`+ and `$10`/`$1C` left of `$80` |
| 6 | Bellows | `$10` | the balloon rises |
| 7 | Party Manifesto | `$09` | the balloon rises, and crashes at the top of room 3 |
| 8 | Cannon | `$1D` | cannot be picked up |
| 9 | Barrel Medium | `$07` | the barrel ride of room `$1D` |
| 10 | Vacuum Cleaner | `$14` | hover in rooms `$14` and `$08` |
| 11 | ACME Bridge | `$08` | the bridge of room `$19` |
| 12 | Flute | `$16` | charms the snakes; in room `$10` grows the rope into room `$1C` |
| 13 | Silver Lining | `$0A` | room `$43` at Y `$20`, X `$76-$83`: becomes the Silver Cross (status 27, +75) |
| 14 | Spring | `$1C` | bounce, where it lies |
| 15 | Formula | `$2E $2F $46 $47`, `$2D` by the throw | gift 1 |
| 16 | Switch | `$27` | fits the lever of rooms `$3E` and `$40` |
| 17 | Button | `$42` | gift 5 |
| 18 | Battery | `$34` | gift 3 |
| 19 | Coat Hanger | `$31` | gift 2 |
| 20 | Trampoline | `$33` | bounce, where it lies |
| 21 | Atomic Pile | `$3C` | gift 4 |
| 22 | Anti Radiation Pills | `$04` | room `$3C`: no radiation (set on pickup) |
| 23 | Cup of tea | `$45` | gift 6 |
| 24 | Energy Crystal | `$2C`; record 20 is its place in `$30` | room `$30`'s machine: the teleports (+75) |
| 27, 28 | Barrel Big, Barrel Small | `$1D`, `$21` | the fatal barrel rides |
| 29 | Silver Cross | from the Silver Lining | room `$39`'s creature flees (+150) |

The "Lies in" column is ItemPlaces (doc 07.8). Items 25, 26, 30 and 31 are not items to carry: their sprites draw the
balloon's basket (`$99`) and envelope (`$9A`), room `$3F`'s basket (`$9E`) and the lift (`$9F`).

The puzzles depend on each other:

```mermaid
flowchart TD
    VC["Vacuum Cleaner: hover in $14/$08"] --> R08["reach room $08: the ACME Bridge"]
    R08 --> BR["bridge in room $19"]
    FL["Flute"] --> SN["pass the snakes of $17 and $1A"]
    FL --> ROPE["room $10: the rope into $1C"]
    B9["Barrel Medium"] --> BAR["room $1D: the barrel ride"]
    BEL["Bellows"] --> BAL["the balloon of $0F/$03"]
    CB["Cricket Ball"] --> F1["room $2D: the Formula"]
    SL["Silver Lining"] --> SC["room $43: the Silver Cross"]
    SC --> R39["room $39: the creature flees"]
    SW["Switch"] --> LEV["the lever of $3E/$40"]
    LEV --> BAS["the basket of $3F"]
    EC["Energy Crystal"] --> TP["room $30: the teleports $30 to $3D to $20"]
    PILL["Anti Radiation Pills"] --> R3C["room $3C: the Atomic Pile"]
    F1 --> G1["gift 1"]
    R3C --> G4["gift 4"]
    G1 --> PROF["the professor: six gifts"]
    G4 --> PROF
    PROF --> END["the ending: the deflector"]
```

![The items the RZX run needs: where each lies and where it is used](img/gameplay/item-uses.png)

The figure: the arrows of the USES list in `tools/fig_gameplay.py`, made from the HeldItem tests of the room scripts
and statuses, drawn on the room map.

```bash
python3 tools/fig_gameplay.py docs/img/gameplay
```

How to read the figure:

- The 72 rooms, darkened, 12 to a row.
- Each item is drawn in its colour in the room where it lies; its line ends in a dot in the room where it is used.
- The labels mark the professor (`$3B`), the crystal pad (`$30`), the barrels (`$1D`) and the balloon (`$0F`).
- The text below lists what is not drawn: the Umbrella, the key items of the explorer rooms, the Spring and Trampoline.

**The point**: the items are spread over the map, and most are used far from where they lie. The professor's room is
the hub: six lines end there.

The explorer rooms each test one key item, the explorer's own from the instructions:

| Explorer | Room | Item | With it | Without it |
| ---: | --- | --- | --- | --- |
| 0 | `$2D` | Cricket Ball (2) at X `$DC`, Y `$48` | the throw (status 28), the Formula falls into the hands | nothing happens |
| 1 | `$2E` | Beer Barrel (4) at X `$B2`, Y `$48` | the creature drinks (status 32) | touching it: status 26 |
| 2 | `$2F` | Unicycle (0) at Y `$48`, X `$54-$B3` | ride across | status 18 left of X `$96` |
| 3 | `$46` | Spurs (3) | ride the creature to the left (status 29, then 1) | status 18 left of X `$DC` |
| 4 | `$47` | Flashgun (1) at Y `$60` | the flash (status 33), two screen flashes | eaten: status 18 |

Each explorer room except `$2D` holds a Formula (ItemPlaces records 27-30). Room `$2D` gives its Formula by the throw.
So every explorer can get exactly one Formula.

Worked example: room `$2D` in the RZX run (explorer 0), in rzx16000 and rzx18000 (`.ann`, CricketBallScript):

1. Stage 0 puts the target in slot 3 at X `$64`, Y `$48`, frame `$4F`.
2. The hero stands at X `$DC`, Y `$48` with the Cricket Ball (2): stage 1, status 28.
3. At the throw frame `$3E` the ball appears in slot 4 at X `$C8`, Y `$39` and flies 4 pixels left and 1 down a pass to
   Y `$52`.
4. The target's frame goes to `$50`, and the Formula drops from Y 8 to Y `$48`, 1 pixel a pass.
5. BallThrown is set, HeldItem = `$0F`, the status is cleared. The RZX run gets its Formula here (rzx18000, stage 3).

Witness:

- The bridge (BridgeEffect) ran in rzx08000 and rzx12000 (room `$19`) and rzx42000 (room `$3A`).
- The lever was fitted and pulled in rzx28000 and rzx32750; the basket arrived in rzx28000 and rzx34000.
- The Silver Cross made the creature flee 33 passes, with the score once (`$B538`); status 27 shows in rzx38000 frames
  2-135. The trigger instruction of room `$43` (`$B71E`) is in no build: the segment starts with status 27 already
  set.
- The rope (`$BC91` on), Think (status 10) and every explorer room but `$2D` never ran.

## 10.10 The professor, the telescope and the ending

Professor Eyestrain stands in room `$3B` (ProfessorScript `$B5DD`). He walks to and fro. On his way left he stops,
plays his frames (ProfFrames `$B6C1`), and his last frame `$4D` is the asking pose: WantedItem = WantedItems[GiftCount],
and the speech bubble in slot 3 shows that item's sprite (`$80` + item).

The six wishes, in order (WantedItems `$B6BB`): the Formula (15), the Coat Hanger (19), the Battery (18), the Atomic Pile
(21), the Button (17) and the Cup of tea (23).

```text
ProfessorScript, every pass:
    if Near(Hero, professor) and HeldItem == WantedItem:
        HeldItem = $FF; LastGift = item
        SpawnRoomItems; DrawPortrait; AddScore(150)
        GiftCount += 1
        if GiftCount == 6: ProfessorEnding
    the professor: place, walk, stop, frames; at frame $4D on the way left:
        WantedItem = WantedItems[GiftCount]; the bubble = $80 + WantedItem

ProfessorEnding:
    Room = $28; SetUpRoom; GameWon = $1D; Status = 29; Hero.frame = $7F
```

```asm
ProfessorScript:
  LD IY,ObjectSlot4
  CALL Near
  JR NC,ProfState
  LD HL,HeldItem          ; the wanted item in hand?
  LD A,(WantedItem)
  CP (HL)
  JR NZ,ProfState
  PUSH IY
  PUSH IX
  LD (HL),$FF             ; given: HeldItem = $FF, LastGift = the item
  LD (LastGift),A
  CALL SpawnRoomItems
  CALL DrawPortrait
  LD DE,$0096             ; +150
  CALL AddScore
  POP IX
  POP IY
  LD HL,GiftCount         ; the sixth gift ends the game
  INC (HL)
  LD A,(HL)
  CP $06
  JP Z,ProfessorEnding
```

```mermaid
stateDiagram-v2
    [*] --> Place: ProfessorState 0, X $1A, Y $48
    Place --> Walk: state 1
    Walk --> Stop: turns on his way left
    Stop --> Ask: frames end at $4D
    Ask --> Walk: WantedItem = WantedItems[GiftCount], bubble shown
    Walk --> Gift: Near and HeldItem = WantedItem
    Ask --> Gift: Near and HeldItem = WantedItem
    Gift --> Walk: GiftCount 1-5, +150
    Gift --> Ending: GiftCount 6, room $28, GameWon
```

![ProfessorScript at work: the first gift](img/routines/ProfessorScript.gif)

The animation shows `rzx44000` frames 408-466, in 80 pictures, with the screen as the view. The code panel follows
ProfessorScript `$B5DD-$B703`, DrawPortrait and AddScore.

```bash
python3 ../../kit/routine_anim.py --work work/docs/tmC/r44 --window 408:0-466:0 --listing build/game.lst \
  --pc B5DD-B703,9E5D-9EBC,BCF2-BD10 --view screen --range 5B00-5CFF --pictures 80 --delay 120 \
  --title "The first gift: Professor Eyestrain asks for the Formula (bubble = item sprite \$8F), the explorer brings it: +150, GiftCount 1 (rzx44000, frames 408-466)" \
  --out docs/img/routines/ProfessorScript.gif
```

Worked example: `rzx44000`, from the samples (doc 07.11 has the table).

1. The hero holds the Formula from frame 0; WantedItem is 0 (doc 07.13).
2. In frame 415 the professor asks: the sample of 416 shows WantedItem `$0F`.
3. In frame 459 the hero is near him with the Formula: HeldItem `$FF`, score 1400 to 1550, GiftCount 1.
4. The professor asks for the Coat Hanger (`$13`) in frame 723. The hero swaps it from a bearer into his hand (the
   sample of 1067) and gives it in frame 1203: GiftCount 2, score 1700.

The telescope of room `$12`: standing at X `$C0`, Y `$40` with right held starts status 30. The hero bends to the
eyepiece, and status 31 shows space: room `$28` set up, the asteroid in slot 4 at X `$75`, Y = 2 x (40 - days), and the
text "TIME REMAINING TO COLLISION" with the days, hours and minutes. The fewer the days, the lower the asteroid stands.
After `$80` passes the hero is back in room `$12`. Room `$12` was never reached, so this is known only from the code.

The ending is the script of room `$28`, SpaceScene `$B0B6`. LoseGame and ProfessorEnding both lead there; GameWon
decides the outcome.

```text
SpaceScene (RoomStage steps):
    0: the asteroid in slot 1 at X $A2, Y 4, frame $75
       the Earth in slots 2, 3 at X $89, $71, Y $68, frames $72, $71
       if GameWon: the deflector in slot 4 at X $89, Y $5C, frame $6F
    1: the asteroid X - 1, Y + 4 a pass, down to Y $54
    won:  the deflector frame + 1, sound 2; the asteroid X - 4, Y - 1 a pass; gone at X 4
    lost: the asteroid hidden; the Earth frames $76, then $77; sound 1
    then count to $80 passes; GameOver = 1
```

```mermaid
flowchart TD
    A["LoseGame: lives out or time out"] --> S["room $28, status 29"]
    B["ProfessorEnding: the sixth gift, GameWon = $1D"] --> S
    S --> P["SpaceScene $B0B6: the asteroid falls"]
    P --> W{"GameWon?"}
    W -- yes --> D["the deflector fires; the asteroid turns away"]
    W -- no --> X["the strike: frames $76, $77"]
    D --> E["count $80 passes, GameOver = 1"]
    X --> E
    E --> H["EndGame $906D: the high score, the menu"]
```

![The space scene after the last life: the strike](img/play/space-scene-strike.gif)

The animation shows `gameover` frames 1504-1964, every sixth frame, at twice the size: the asteroid falls on the Earth
with no deflector.

```bash
python3 ../../kit/screen_anim.py --work work/docs/tmC/go --from 1504 --to 1964 --step 6 --scale 2 --delay 100 \
  docs/img/play/space-scene-strike.gif
```

![The space scene after the sixth gift: the deflection](img/play/space-scene-won.gif)

The won ending (`rzx50000` frames 194-729), from another writer's animation: the deflector fires and the
asteroid turns away. GameOver is set at frame 729 and the menu follows at 732.

**The point**: one scene serves both endings. The only difference is GameWon, which places the deflector; without it the
same script plays the strike.

Witness: the gifts ran 6 times (rzx44000 2, rzx46000 2, rzx48000 1, rzx50000 1) and the ending once (rzx50000).
SpaceScene ran 327 times in gameover and rzx (`.ann`).

## 10.11 The countdown

CountDown `$935D` takes one minute off the clock every pass. The clock is three plain binary bytes: days `$5BFB`, hours
`$5BFC`, minutes `$5BFD`. It starts at 30 days, 23 hours and 59 minutes.

```asm
CountDown:
  LD HL,CountdownMinutes
  DEC (HL)
  BIT 7,(HL)
  RET Z
  LD (HL),$3B             ; minutes back to 59
  DEC HL
  DEC (HL)
  BIT 7,(HL)
  RET Z
  LD (HL),$17             ; hours back to 23
  DEC HL
  DEC (HL)
  BIT 7,(HL)
  RET Z                   ; days below 0: falls into LoseGame
```

```mermaid
flowchart LR
    M["minutes - 1"] --> MN{"below 0?"}
    MN -- no --> R["return"]
    MN -- yes --> H["minutes = 59, hours - 1"]
    H --> HN{"below 0?"}
    HN -- no --> R
    HN -- yes --> D["hours = 23, days - 1"]
    D --> DN{"below 0?"}
    DN -- no --> R
    DN -- yes --> L["LoseGame $9372"]
```

The whole clock is 31 x 24 x 60 = 44 640 passes. At 2.8 frames a pass that is about 125 000 frames, 42 minutes of play.
Because there is no frame sync, the clock runs faster in quiet rooms and slower in busy ones.

**The point**: the countdown counts work, not time. A player who stands in an empty room spends days faster than one in
a crowded room.

Worked example: the RZX run. At RZX 250 the clock reads 30 days 23:41; at 25 000, 24 days 20:40 (`$18 $14 $28`); at the
end, 18 days 15:32. The run used 12 days 8 hours 27 minutes: 17 787 passes in about 50 700 frames, 2.85 frames a pass.

Witness: the hours roll over 440 times and the days 13 times in the builds (`$9364`, `$936B`). The time running out was
reached only on a clone (`work/stage2/probe_points.py` A: the RZX state at 44 000 with the clock set to 0 days 0 hours
2 minutes). The pass after 0:00:00 falls into LoseGame; room `$28` follows 10 frames after the change, and GameOver at
frame 430. The days wrap to 255, and the clock goes on counting.

## 10.12 The score

The score `$5C18` is 32 bits, signed, low byte first. AddScore `$BCF2` adds DE (signed) and prints it.

| Event | Points | Where |
| --- | ---: | --- |
| a pickup | 50 | PickUpItem `$BB6C` |
| the crystal set in place | 75 | ItemsPass `$B9FA` |
| the Silver Lining made into the Silver Cross | 75 | Room43Anim `$A851` |
| a gift to the professor | 150 | ProfessorScript `$B5DD` |
| room `$39`'s creature fleeing from the Silver Cross | 150 | SilverCrossScript `$B4E2` |

```asm
AddScore:                 ; DE = the points, signed; every register kept
  PUSH IX
  PUSH IY
  PUSH HL
  PUSH BC
  PUSH AF
  EXX
  PUSH HL
  PUSH BC
  PUSH DE
  EXX
  CALL AddToScore         ; the 32-bit add
  CALL PrintScore         ; the panel digits (doc 08)
  EXX
  POP HL
  POP BC
  POP DE
  EXX
  POP AF
  POP BC
  POP HL
  POP IY
  POP IX
  RET
```

```mermaid
flowchart LR
    P["pickup +50"] --> A["AddScore $BCF2"]
    C["crystal +75"] --> A
    L["Silver Lining +75"] --> A
    G["gift +150"] --> A
    X["Silver Cross +150"] --> A
    A --> S["Score $5C18, 32 bits"]
    S --> E["EndGame: HiScore $5B78 if higher"]
```

The RZX run ends at 2 300. The fixed events give 6 x 150 + 150 + 75 + 75 = 1 200, which leaves 1 100 = 22 pickups at
50 (an inference from the sums; the run's samples show the score rising in steps of 50 through RZX 39 500).

**The point**: points come only from progress. There is nothing to shoot and no bonus for time left, so the score is a
measure of how far the player got.

Witness: AddScore's callers are the five in the table (`.ann`); the score samples of the RZX run are drawn in doc 07.12.

## 10.13 Notable features

- **No frame sync.** The main loop has no HALT; a pass takes 2.4 to 3.3 frames. All speeds, the countdown and the
  random waits are per pass (doc 04).
- **The countdown counts passes** (10.11), so it runs at the speed of the room.
- **R-based random numbers.** Random mixes a 16-bit state with the R register (doc 07.7). Only the creatures' waits use
  it; everything else is fixed.
- **`$C000` is two routines.** In RAM 0 it is the drop's fall (DropFall); with RAM 6 paged in, the IM 2 handler calls
  the music player there (doc 07.5, doc 09).
- **The umbrella's exceptions.** The Umbrella stops the fall count except in rooms `$35` and up and in rooms `$10` and
  `$1C` left of X `$80` (10.5). The RZX player died there with the Umbrella in hand.
- **A creature touch while standing kills as a fall.** HitExplorer gives status 26 to a standing hero and 24 to a hero
  in the air (doc 07.6).
- **Hit 0 never hits, except for the drop** (doc 07.6), against the resource notes.
- **WantedItem starts at 0**, the Unicycle, because InitGame's clear runs after its `$FF` (doc 07.13).
- **Three deliberate death rides**: the Barrel Small, the Barrel Big and the pad of room `$20` (10.6).
- **A Cursor joystick reader that no menu choice reaches** (ReadCursorKeys `$B8D4`), with a bug: a released 6 returns
  the port byte instead of the input bits (doc 05).
- **The room `$10` entry rewrites ThinkHints**: the idea of room `$0F` becomes 6, the Bellows (SetUpRoomTiles).
- **Off-by-one handler names** in the `.ann` comments: several name the handler of status N + 1 (10.2, sent to the
  lead).

## 10.14 What no recording reached

Known only from the code, or from a clone probe where said:

- the beam's hit; the mud sink (status 17); tile `$A5`;
- the telescope (room `$12` never visited; statuses 30, 31);
- Think and its ideas (statuses 10-12);
- the lift up (status 19); the balloon crash (status 9); the Barrel Small and the Barrel Big (statuses 15, 16);
- the rope of room `$10`; the Silver Lining's trigger (status 27 is seen, its start is not);
- the explorer rooms `$2E`, `$2F`, `$46` and `$47` (statuses 32, 33), and every explorer but 0;
- status 23 in play (only the radiation probe), room `$39`'s attack, the pad of room `$20`;
- the countdown running out (only the clock probe);
- the flier's change of type, a third item in a room, the full bearers (doc 07.13);
- the WantedItem = 0 gift of the Unicycle;
- the 13 rooms the RZX run does not visit: `$01 $02 $05 $06 $11 $12 $15 $1E $21 $24 $25 $2E $2F` (WALKTHROUGH 6.0).
