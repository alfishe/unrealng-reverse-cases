# 10. Gameplay logic

What this covers: the rules as the code applies them:

- TraceBeam, the beam's path through the grid, and what each element does to it;
- the cells burnt, the overload and the energy, the mines and the gremlins;
- every way to lose a life, a level completed and the ending;
- the solver as a reading of TraceBeam, and the game's notable features.

The recordings it rests on:

- `L01` (`work/docs/dfA/L01`, port base 37480): level 1 played from the menu to CONTACT! and the bonus, frames
  0-1645. Its memory at frames 256, 377 and 1514 was dumped with `tools/ttd_dump.py` into `work/docs/dfA/dump/`.
- `L03` (`work/docs/dfA/L03`, port base 37485): level 3 with its two gremlins, frames 1150-1330.

The single traces are replayed from those dumps by SkoolKit's simulator: `tools/fig_trace.py` runs TraceBeam
`$8ED6` on a copy of the dumped memory, from the start MainLoop gives it.

## 10.1 One pass, as rules

The game is a loop of passes ([doc 4, 4.2](04-game-loop.md#42-the-pass)). Each pass:

1. reads the controls;
2. traces the beam from the laser;
3. moves the gremlins and draws the screen;
4. settles the pass's outcome in PassEnd.

The trace does not act on what it finds. It sets four flags, and PassEnd and UpdateOverload turn them into the
rules:

```mermaid
flowchart TD
    T[TraceBeam 8ED6] --> F{what the beam met}
    F -->|a cell 40| B[BeamBurn: an explosion slot, 120 or 30 points]
    F -->|a mine 41| M[BeamOnMine 8ED4]
    F -->|back into the laser, or 40 steps long| L[BeamInLaser 8ED5]
    F -->|the receiver, from its front| D[LevelDone 8ED2]
    F -->|a wall, an absorbing polariser, the edge| E[the beam simply ends]
    M --> O[UpdateOverload A683: 4 steps a pass, MINE ALERT]
    L --> O2[UpdateOverload: 1 step a pass, OVERLOAD]
    E --> C[CoolOverload: 1 step back a pass]
    O --> X{overload bar full?}
    O2 --> X
    X -->|yes| LL[LifeLost 8ED3]
    G[DrainEnergy A613: 1 step every rate frames] -->|empty| LL
    LL --> LO[LoseLife 866A: BOOM, the level again, or GAME OVER]
    D --> LC[LevelComplete 87D4: CONTACT!, the bonus, the next level]
    B --> PE[PassEnd: explosion steps; the last cell opens the receiver]
```

*The rules of a pass. Witness: the flags' writers and readers in the listing (`$8ED2-$8ED5`, [doc 7,
7.7](07-objects.md#77-the-state-variables)), and the `L01` course in 10.9. The point: the beam decides everything.
The only other clock is the energy, which drains whatever the beam does.*

## 10.2 TraceBeam: the path

The beam moves on a lattice of half-cells:

- x runs 0-32 and y runs 0-20;
- a cell (row r, column c) has its centre at x = 2c + 2, y = 2r + 2;
- between centres are the vertices where four characters meet.

There are 16 directions, clockwise from east (4 south, 8 west, 12 north). One step moves the beam by BeamDeltas
`$8170`:

| Directions | Step (dx, dy) | Kind |
| --- | --- | --- |
| 0, 4, 8, 12 | (2, 0), (0, 2), (-2, 0), (0, -2) | axis: one cell a step |
| 2, 6, 10, 14 | (1, 1), (-1, 1), (-1, -1), (1, -1) | diagonal: one character a step |
| 1, 3, 5, 7, 9, 11, 13, 15 | (2, 1), (1, 2), ... | slope: two by one |

So the 16 directions are only roughly 22.5 degrees apart: the slopes are at 26.6 and 63.4 degrees.

```asm
BeamStep:                   ; $8EDD, once a vertex
  XOR A
  LD (BeamAtCentre),A
  LD (BeamReflected),A
  LD (BeamY+$0003),A
  LD A,(BeamDirection)
  CP $FF                    ; ended
  RET Z
  LD (BeamNextDirection),A  ; by default the beam goes straight on
  LD A,(BeamX)              ; x or y odd: between cells, nothing to read
  SRL A
  LD C,A
  JP C,BeamVertex
  LD A,(BeamY)
  SRL A
  LD B,A
  JP C,BeamVertex
  ...                       ; HL = $FD12 + 17 (y/2) + x/2: the cell
  LD A,(HL)
  RES 7,A                   ; a turning element acts as its current angle
  AND A
  JP Z,BeamVertex           ; empty
  CP $11
  JP C,BeamMirror           ; $01-$10
  CP $21
  JR C,BeamBlock            ; $11-$20 polarisers: decided by their characters
  CP $58
  RET NC                    ; an explosion: the beam ends
  CP $4F
  JP NC,FibreEntry          ; $4F-$57
  CP $4B
  JR NC,BeamReceiver        ; $4B-$4E
  CP $43
  JP NC,BeamAtLaser         ; $43-$4A
  CP $42
  JP Z,PrismTurn            ; $42
  CP $3F
  JP C,BeamVertex           ; $21-$3E walls: decided by their characters
  CP $41
  JR Z,BeamMine             ; $41
BeamBurn:                   ; $3F, $40: a cell
  ...
```

```text
TraceBeam():                                  # from the half-cell in front of the laser
    steps = 0
    loop:
        next = direction
        if x and y are even:                  # a cell's centre
            act on the cell (10.3): may set next, end the beam, or set a flag
        BeamVertex: draw the four characters round (x, y) in three passes;
            a wall or polariser character met may end the beam or bounce it
            if next == direction + 8: BeamBackToLaser (OVERLOAD), end
        if next == FF: end
        direction = next; (x, y) += BeamDeltas[direction]
        if off the field: end
        steps += 1 (diagonals only at even x)
        if steps == 40: BeamBackToLaser (OVERLOAD)  # the beam goes on
        if steps == 150: end
```

The trace reads two maps. The grid (`$FD23`) decides at a cell's centre. The character map (`$E000`) decides at the
vertices between: the walls and polarisers are characters, so a beam can graze a wall's edge or be stopped by one
quarter of it. That is the work of the three drawing passes of BeamVertex `$906E` ([doc 6, 6.6](06-rendering.md)).

![The pass that reaches the receiver](img/logic/trace-contact.gif)

*`L01` frame 1514, one TraceBeam replayed from the dump (`python3 tools/ttd_dump.py --work work/docs/dfA/L01 --frame`
`1514 --out work/docs/dfA/dump/l01-1514 --no-ram`, then `python3 tools/fig_trace.py`
`work/docs/dfA/dump/l01-1514.cpu.bin docs/img/logic/trace-contact.gif --title "..."`): 18 steps, 125 371 T. How to read
it: the level as BuildLevel draws the dumped grid (dimmed); the magenta line is the path so far; circles are the
vertices (large at a cell's centre). The panel on the right gives each step's x, y, direction and length, and the
handler the cell sent it to. The point: from the laser's front, three mirrors turn the beam (west to north-east, to
east-south-east, to west). It enters the receiver from its open side: BeamReceiver sets LevelDone.*

**Worked example: the winning pass of level 1** (`python3 tools/fig_trace.py work/docs/dfA/dump/l01-1514.cpu.bin`
`--list`).

1. The beam starts at x 6, y 16 going west (direction 8): the half-cell in front of the laser `$49` at row 7,
   column 3. The laser's centre is x 8, y 16.
2. At x 2, y 16 (row 7, column 0) the cell holds `$0F`. BeamMirror gives (16 - 8 + 14 + 8) AND 15 = 14:
   north-east.
3. Four diagonal steps reach x 6, y 12 (row 5, column 2), which holds `$08`: (16 - 14 + 7 + 8) AND 15 = 1, east by
   south-east.
4. Six slope steps reach x 18, y 18 (row 8, column 8), which holds `$02`. The player turned this mirror at frame
   1513. It gives (16 - 1 + 1 + 8) AND 15 = 8: west.
5. Five steps west reach x 8, y 18 (row 8, column 3), the receiver `$4B`. The beam is on an axis, and ((8 + 8) AND
   12) / 4 = 0 = (`$4B` - `$4B`) AND 3, so it entered from the front. LevelDone = `$FF`.

The trace's length counter stands at 15 at the end, well under the 40 of 10.4.

## 10.3 What each element does

| Code | Element | At the centre | Witness |
| --- | --- | --- | --- |
| `$00` | empty | on | every trace |
| `$01-$10` | mirror (16 angles) | BeamMirror `$8FFB`: out = (16 - in + code - 1 + 8) AND 15 | 212 472 runs |
| `$11-$18` | cyan polariser | by its characters: along its axis it passes, else it absorbs | `elements.py` experiment |
| `$19-$20` | yellow polariser | by its characters: along its axis it passes, else it reflects | `elements.py` experiment |
| `$21-$2F` | absorbing wall | by its characters (`$71`): the beam ends | every level |
| `$30-$3E` | reflecting wall | by its characters (`$72`): the beam bounces | 21 949 bounces |
| `$40` | cell | BeamBurn: an explosion slot, the points, the beam ends | 10.5 |
| `$41` | mine | BeamMine: BeamOnMine, SoundFlags bit 1, the beam ends | `mine`, 46 RZX segments |
| `$42` | prism | PrismTurn `$9014`: a random new direction 4-12 sixteenths off the reverse | 16 015 runs |
| `$47-$4A` | laser | BeamAtLaser: from its front on an axis, BeamBackToLaser (OVERLOAD); else the beam ends | 1094 runs |
| `$4B-$4E` | receiver | BeamReceiver: from its front on an axis, LevelDone; else the beam ends | 18 completions |
| `$50-$57` | fibre-optic end | FibreEntry `$903E`: the beam jumps to the partner (code XOR 1) and leaves it in the same direction | 4105 runs |
| `$58-$5C` | an explosion | the beam ends | 10.5 |
| bit 7 | turning | acts as its current angle; ChargeLaser and the gremlins turn it | |

![The mirror table](img/logic/mirror-table.png)

*BeamMirror's answer for all 16 codes and 16 incoming directions, drawn by `python3 tools/fig_logic.py mirror`
`docs/img/logic/mirror-table.png` from the formula of `$8FFB` (each code drawn by the game's CellTable). How to read
it: a column per mirror code, a row per incoming direction, the outgoing direction in the cell. Red marks the out =
in + 8 case: the beam goes back along itself. The point: only the eight odd codes can send a beam back.*

*An even code lies half-way between two square-on angles, so no axis, diagonal or slope beam meets it square. A
mirror one click off square is always safe from OVERLOAD, but the next click may not be.*

**Worked example: a mirror one click off square.** A beam going north (12) meets `$09`, the horizontal mirror: (16 -
12 + 8 + 8) AND 15 = 4. That is south, the reverse, so OVERLOAD. One click to `$0A` gives 5 (south by south-west),
and the beam is away. One click the other way to `$08` gives 3. This is how the `L01` overload at frame 256 below
comes and goes as the player turns the mirror at row 0, column 0.

Three elements are random or remote:

- **The prism** takes a number from Random `$8E15` on every pass. The beam leaves (in + 4 - (H AND 7)) or (in - 4 +
  (H AND 7)), so it flickers from pass to pass. It never goes straight back, so a prism never overloads.
- **A fibre end** finds its partner by scanning the grid backwards for the code XOR 1. The beam is drawn into the
  first end, jumps to the partner's centre, and leaves in its arrival direction. Every level that holds an end holds
  its partner, so the "no partner" branch (FibreNoPartner `$9059`) is dead.
- **The laser and the receiver** both demand an axis beam on their open side. A beam on their back or flank, or a
  slanted one, just ends.

## 10.4 The overlong beam

```asm
BeamCountStep:              ; in BeamMove $9235
  LD A,(BeamSteps)          ; length + 1 (a diagonal step only at even x)
  INC A
  LD (BeamSteps),A
BeamLengthCheck:
  LD A,(BeamSteps)
  CP $28                    ; under 40: the next vertex
  JP C,BeamStep
  LD D,A
  CALL Z,BeamBackToLaser    ; exactly 40: OVERLOAD
  LD A,D
  CP $96                    ; under 150: on
  JP C,BeamStep
  RET
```

A beam that runs 40 steps sets BeamInLaser as if it had come back into the laser, but the trace goes on, up to 150
steps. So a long path costs a step of the overload bar every pass, even when it reaches the cells. Lighting a far
cell by a long detour is not free: the player has to burn it before the bar fills (64 passes, 10.6). The RZX run hit
the 40 in 14 of the 59 level segments (`$926D`, 2010 runs).

## 10.5 Burning a cell

```asm
BeamBurn:                   ; $8F40
  EX DE,HL                  ; DE = the cell's grid address
  LD B,$06
  LD HL,ExplosionSlots      ; $81B8: seven slots of 4 bytes
BeamBurnSlot:
  LD A,(HL)                 ; a free slot has high byte 0
  AND A
  JR Z,BeamBurnStore
  INC L
  INC L
  INC L
  INC L
  DJNZ BeamBurnSlot         ; six looked at; the seventh if all are taken
BeamBurnStore:
  LD (HL),D                 ; grid address, y, x
  INC L
  LD (HL),E
  INC L
  LD A,(BeamY)
  LD (HL),A
  INC L
  LD A,(BeamX)
  LD (HL),A
  LD A,$FF                  ; the beam ends at the cell
  LD (BeamNextDirection),A
CellPoints:
  LD B,$18                  ; patched: 12 or 3
  CALL AddScore
  JP BeamVertex
```

The beam stops at the cell and scores at once. The cell is not removed by the trace: PassEnd steps its slot each pass
through the codes `$57`, `$58-$5C` and empties it ([doc 7, 7.5](07-objects.md#75-the-explosion-slots)). While the
cell explodes its code is `$58` or more, which ends the beam (10.3). So the beam stays blocked for the whole
explosion, about 30 frames, and only then runs on to the next element.

![A cell burnt, as the trace sees it](img/logic/trace-burn.gif)

*`L01` frame 377 replayed (`python3 tools/fig_trace.py work/docs/dfA/dump/l01-377.cpu.bin`
`docs/img/logic/trace-burn.gif --title "..."`): 25 steps, 188 552 T. How to read it: as the trace above. The point:
the beam crosses most of the play area and ends at x 22, y 16 (row 7, column 10), a cell: BeamBurn.*

![The cell exploding](img/logic/PassEnd-burn.gif)

*`L01` frames 377-411, 70 pictures of 33 946 T (`python3 ../../kit/routine_anim.py --work work/docs/dfA/L01 --window`
`377:0-411:0 --listing build/game.lst --view screen --range FD00-FDFF --pc 85AE-865F --pictures 70 --title "..." --out`
`docs/img/logic/PassEnd-burn.gif`). How to read it: top left, LevelGrid `$FD00-$FDFF`, where the cell's byte `$FDA4`
changes; bottom left, the screen; right, PassEnd `$85AE-$865F` with the instruction under way. The point: the cell's
code climbs one step a pass and then goes to 0, and the beam behind it is blocked until it does.*

**Worked example: the cell at row 7, column 10.** The watch over ExplosionSlots `$81B8` and the cell `$FDA4` = `$FD23`
+ 17 x 7 + 10 shows:

| Frame | `$FDA4` | What |
| ---: | --- | --- |
| 378 | `$40` -> slot | the trace hits it: slot 0 = `$FD $A4`, y 16, x 22; 120 points |
| 379 | `$58` | PassEnd: `$57` and then the first frame code; BurnSoundFlag `$57`, BurnSound played |
| 386 | `$59` | SoundFlags bit 3 still on: the hiss |
| 391 | `$5A` | the hiss stops |
| 397 | `$5B` | |
| 403 | `$5C` | |
| 409 | `$00` | emptied; CellsLeft `$13` to `$12`; the slot freed |
| 413 | | the beam, now free, reaches and hits the next cell |

So a cell takes 31 frames (six passes) from the hit to the next hit.

**The last cell.** When CellsLeft reaches 0, PassEnd calls OpenReceiver `$8B3F`. This finds the receiver, puts the
element in front of it into explosion slot 0, sets CellsLeft to `$FF`, plays ReceiverOpenSound and adds 250 points.
The element in front of the receiver is a mine in 23 levels, a wall in 32, a polariser in 4 and a fibre end in 1. It
blows up like a cell, and when its slot empties, CellsLeft is decremented once more, to `$FE`. The receiver's mouth is
now open.

## 10.6 Overload and energy

```asm
UpdateOverload:             ; $A683, once a pass
  LD A,(BeamOnMine)
  AND A
  JR Z,OverloadLaser
  ...                       ; MINE ALERT ($13), then OverloadStep and three OverloadAddStep: 4 steps
OverloadLaser:
  LD A,(BeamInLaser)
  AND A
  JP Z,CoolOverload         ; neither: one step back
  LD A,(SoundFlags)
  SET 2,A                   ; the overload tone on, the mine's off
  RES 1,A
  LD (SoundFlags),A
  ...                       ; OVERLOAD ($12), OverloadStep: 1 step
OverloadAddStep:            ; $A6CD
  ...                       ; the bar full ($54B9): return
  ...                       ; one bit into the byte, SCF; RRA, three lines
  ...                       ; at $54B9: LifeLost = $FF, unless practice
```

The OVERLOAD bar is 8 bytes of 8 pixels: 64 steps. The beam fills it at two speeds:

- **back in the laser** (a mirror square on, or the 40-step beam): 1 step a pass, so 64 passes (about 300 frames)
  before a life is lost;
- **on a mine**: 4 steps a pass, so 16 passes (about 80 frames).

Any pass with neither takes one step back (CoolOverload `$A6F4`). So a brief overload is harmless, and the bar
measures how long the player has left the beam wrong.

![The overload trace](img/logic/trace-overload.gif)

*`L01` frame 256 replayed (`python3 tools/fig_trace.py work/docs/dfA/dump/l01-256.cpu.bin`
`docs/img/logic/trace-overload.gif --title "..."`): 10 steps, 72 309 T. How to read it: as the traces above. The
point: the mirror at row 0, column 0 meets the north-going beam square on. Its answer is the reverse, so BeamVertex
calls BeamBackToLaser, and BeamInLaser is `$FF` at the trace's end.*

![The overload bar against UpdateOverload](img/logic/UpdateOverload.gif)

*`L01` frames 1325-1352, 70 pictures of 26 957 T (`python3 ../../kit/routine_anim.py --work work/docs/dfA/L01 --window`
`1325:0-1352:0 --listing build/game.lst --view screen --range 5400-56FF --pc A683-A728 --pictures 70 --title "..."`
`--out docs/img/logic/UpdateOverload.gif`). How to read it: top left, the screen's bytes `$5400-$56FF` (lines 4-6 of
the panel's third, where the bars are); bottom left, the screen; right, UpdateOverload to CoolOverloadStep. The
point: OVERLOAD (frame 1330), then MINE ALERT (1336) add bits to the bar's left byte. When the player turns the beam
off the mine (1345), CoolOverloadStep takes them back one a pass.*

The energy is the level's clock ([doc 8, 8.1](08-hud-and-text.md#81-the-panel)). DrainEnergy `$A613` takes a step off
the ENERGY bar every `rate` frames, the level's first settings byte. The bar is 8 bytes, 64 steps.

| Bar left | What happens |
| --- | --- |
| 2 bytes (`$54F2`) | ENERGY LOW (`$0A`), once |
| 1 byte (`$54F1`) | ENERGY LEVEL CRITICAL (`$0C`), repeated; EnergyCritical `$837E`: the beam flashes (glyph set `$8040`) |
| empty (`$54F0`) | ENERGY DRAINED (`$17`), LifeLost |

**Worked example: level 1's clock.** The rate is `$5A` = 90 frames, so the level lasts 64 x 90 = 5760 frames: 115
seconds after the charge. The `energy` recording charged at about frame 690 and drained at 6450, which is 5760
frames later. The charge itself takes 32 passes (8 bytes of 4 steps), and it scrambles the mirrors on every pass
(ChargeLaser, [doc 9, 9.6](09-sound.md#96-soundflags-and-the-interrupt) for its sound).

## 10.7 The gremlins

A gremlin ([doc 7, 7.6](07-objects.md#76-the-gremlins-records-and-mover)) appears on a free cell after its delay and
walks a character a pass. On a mirror it may stop and turn the mirror, one step a pass, at random (GremlinTurnMirror
`$AC2D`, 11 188 runs). Each appearance posts BEWARE OF THE GREMLINS (priority 4) unless a more urgent message is shown. The
trace never reads the gremlin records, so a gremlin does not stop the beam. The danger is the mirror it turns,
which can send the beam back into the laser, onto a mine, or off the cells.

The player's weapon is the cursor. CursorFire `$9A57` runs every pass. With fire held, it looks for any gremlin whose
cell (+4, +5) is the cursor's cell. Each one found is killed:

- its delay becomes `$C8` (200 counts, so it comes back much later);
- its turns and its cell are cleared;
- GremlinSoundFlag is set (PassEnd plays GremlinSound);
- the score gets 160 points.

![The gremlins of level 3](img/logic/gremlins.gif)

*`L03` frames 1150-1330, every third frame (`python3 ../../kit/screen_anim.py --work work/docs/dfA/L03 --from 1150`
`--to 1330 --step 3 --scale 2 --delay 100 --hold 1500 docs/img/logic/gremlins.gif`). How to read it: the screen as
the player sees it. The gremlins are the dithered magenta blobs. The point: the first gremlin appears at frame 1167
and the second at 1251, and both wander over the cells. The beam meanwhile alternates between the receiver's area
and OVERLOAD as the player turns mirrors: the gremlins and the beam do not interact.*

**Worked example: a gremlin kill.** Fire with the cursor on the gremlin's cell: the record's +4/+5 must equal the
cursor cell's grid address. In `L03` at frame 1176, record 0 stands on `$FD7B` = `$FD23` + 17 x 5 + 3 (row 5,
column 3) with +4/+5 = `$7B $FD`. A fire then would give +0 = `$C8`, +5 = 0 and 160 points. A gremlin between
cells (+5 = 0, X or Y odd) cannot be hit, so the player must catch it standing on a cell, every other pass at most.

## 10.8 Losing a life

```mermaid
flowchart TD
    A[the beam in the laser: a mirror square on, or 40 steps] -->|1 step a pass| O[OVERLOAD bar]
    B[the beam on a mine] -->|4 steps a pass| O
    O -->|64 steps, not practice| L[LifeLost 8ED3]
    E[DrainEnergy: a step every rate frames] -->|bar empty| D[EnergyDrained A66F: ENERGY DRAINED]
    D --> L
    L --> P[PassEnd: LoseLife 866A]
    P -->|message below 16| R[BOOM BOOM BOOM, the play area red, LifeLostSound]
    P -->|ENERGY DRAINED shown| S[EnergyDrainedSound]
    R --> C[LoseLifeCount: a life bar hollowed]
    S --> C
    C -->|lives left| N[the same level again, from its start score]
    C -->|none| G[GAME OVER banner, then the hall of fame]
```

*Every way to lose a life. Witness: LoseLife ran 45 times: `mine`, `overload` and `gameover` (the red screen,
`$8675` 41 times), `energy` (ENERGY DRAINED, `$869A` 4 times), and 36 lives over 26 RZX segments. The point: there
are only two causes, the overload bar and the energy. A mine is not instant death: it only fills the overload bar
four times faster.*

A life lost restarts the level from SetUpLevel: the score goes back to SavedScore (the score at the level's start),
the mirrors are scrambled again by the charge, and the energy is full again. In practice (PracticeFlag `$8407`) the
overload never takes a life.

## 10.9 Level complete, the bonus and the ending

```mermaid
sequenceDiagram
    participant PE as PassEnd
    participant LC as LevelComplete 87D4
    participant LP as LevelCompletePause 87F3
    participant N as the next level
    PE->>LC: LevelDone set
    LC->>LC: SoundFlags 0, CONTACT! (18), ContactSound 43 frames, Level + 1
    LC->>LP: a Delay
    LP->>LP: the play area magenta
    loop each energy pixel left
        LP->>LP: 10 points, TwoTone 0A3C, a pixel off
    end
    loop each life left
        LP->>LP: a bar hollowed, 500 points, GremlinSound, TwoTone 0204
    end
    LP->>N: score saved, Lives = 3
    N->>N: after level 60 TheEnd, after P3 the title, else LevelPanel
```

*LevelComplete and its bonus. Witness: `L01` frames 1515-1645 (doc 8's bonus watch) and the 18 completions of the RZX
run. The point: a quick finish is paid twice, by the energy left (10 points a pixel, up to 640) and by the lives
left (500 each). Every level then starts with three lives again, so a life lost costs only its 500-point bonus and
the level's progress.*

![Level 1 completed](img/logic/level-complete.gif)

*`L01` frames 1508-1645, every third frame (`python3 ../../kit/screen_anim.py --work work/docs/dfA/L01 --from 1508`
`--to 1645 --step 3 --scale 2 --delay 120 --hold 2000 docs/img/logic/level-complete.gif`). How to read it: the screen
as the player sees it. The point: the last turn (frame 1513), the beam into the receiver, CONTACT! on the line, the
play area turning magenta, and the energy bar counted into the score.*

![The course of level 1](img/logic/course-l01.png)

*`L01` frames 0-1645, drawn by `python3 tools/fig_course.py work/docs/dfA/l01-course.txt docs/img/logic/course-l01.png`
`--title "..."` from `python3 tools/ttd_watch.py --work work/docs/dfA/L01 --addr`
`8380,9B3F,9B40,9B41,9B42,A507,A50A,A104,A8A6 --from 0 --to 1645 --step 1`. How to read it: one row a variable, frame
across. The point: the whole level in one picture.*

- *The charge fills the energy byte by byte up to frame 225, with SoundFlags bit 4 on.*
- *The cells go one by one, each a step of the score and of CellsLeft, with a burst of bit 3 (the hiss).*
- *OVERLOAD comes in short spells (red), and the bar never leaves its first byte (`$B1`).*
- *MINE ALERT comes once (1336).*
- *CellsLeft reaches 0, the door opens (`$FE`), and CONTACT! (green) is followed by the bonus, where the score
  climbs in small steps and the energy byte falls.*
- *The energy lost only one byte in 1300 frames of play (rate 90, so 8 steps a byte = 720 frames).*

**Worked example: level 1's score.** Level 1 has 19 cells and fewer than 30, so a cell is worth 120 points.

- 19 x 120 = 2280, and the receiver opening adds 250: 2530 at CONTACT! (frame 1518, doc 8).
- The energy left was 7 bytes and some pixels (the pointer at `$F7`). Each pixel is 10 points, counted from frame
  1599.
- Then the three lives: 3 x 500 = 1500.

**The ending.** After level 60, LevelCompletePause jumps to TheEnd `$8885`:

- it clears the full-screen buffer and draws the ending (EndingScreen `$A8CE`);
- it plays ChargedSound twice, waits until no key is held, and plays the title tune;
- it returns to the title, where the hall of fame takes the score.

The ending was seen only in `rzx-344752` and the stage-2 `ending` recording.

## 10.10 The solver as a reading of TraceBeam

`tools/solver.py` (the case's level player, [doc 1, 1.7](01-game-design.md#17-how-a-level-is-solved)) needs no model
of the rules. It copies the running game's 64 K and sets one mirror to a trial angle in LevelGrid. It renders the
character map, because the walls and polarisers are decided by characters, and then runs TraceBeam `$8ED6` in
SkoolKit's simulator from the start MainLoop gives it. The copy's memory is the answer:

- the cells hit are the explosion slots `$81B8` filled;
- LevelDone `$8ED2` means the receiver was reached;
- BeamOnMine `$8ED4` means a mine;
- BeamInLaser `$8ED5` means the laser, or a 40-step beam.

It tries the mirrors the beam met, keeps a turn that burns a cell (or, with none left, reaches the receiver) without a
mine or the laser, and walks the cursor there. `tools/fig_trace.py` is the same idea drawn: the figures of this
document are TraceBeam's own answers, not a re-implementation.

## 10.11 Notable features

- **The beam is the whole game state.** The trace is re-run from the laser on every pass. Nothing remembers where
  the beam went: turning a mirror changes the next pass's path at once.
- **The cells are both targets and walls.** A burning cell blocks the beam for six passes, so a line of cells is
  burnt one at a time, front to back.
- **The 40-step limit makes long paths costly.** A detour through many mirrors overloads the laser on every pass.
- **Odd and even mirrors.** Only odd codes can reflect a beam square back (10.3).
- **Two drawing models.** The grid decides at a cell's centre, the characters between. So the walls have quarter
  shapes that the beam can graze or clip.
- **The randomness** is in only three places: the prism, the charge's mirror scramble and the gremlins. All of them
  use the one Random `$8E15`, whose seed the options panel advances while it waits for a key.
- **Lives reset at every level** (Lives = 3 in LevelCompletePause). A game over needs all three lost in one level.

## 10.12 What is known only from the code

- The 150-step stop of BeamLengthCheck: the recordings reach 40 steps; how often a trace ran on to 150 was not
  counted.
- FibreNoPartner `$9059`: no level lacks a partner.
- InCornerTable `$8100` (a diagonal beam bouncing in the incoming pass, ReflectInCorner `$93F2`): no play reads it.
  The outgoing pass of each vertex already tests the character the next vertex's incoming pass meets, so only the
  trace's first vertex can reach `$93F2`, and that vertex is the laser's front, on an axis. A search in SkoolKit's
  simulator over level 1 (`work/docs/integrate/corner_search.py`, `corner_level1.py`: mirrors turning the beam onto
  a diagonal with a reflecting wall in its way, and every start vertex) found hits only at the first vertex. The clone
  `corner` (`work/docs/integrate/rec/corner`: `game0.szx` with the beam's start `$8376-$8378` POKEd to x 10, y 16,
  direction 10) shows it: 342 passes run `$93F2`, the wall beside the laser is the one wall found, and the beam is
  turned a quarter, to direction 14.

![A diagonal beam turned in the incoming pass](img/logic/reflect-in-corner.png)

*`corner` at frame 750 (`python3 tools/scr_png.py work/docs/integrate/rec/corner/screens/000750.scr
docs/img/logic/reflect-in-corner.png`). How to read it: level 1 on the clone; the beam starts at the reflecting wall
right of the laser. The point: the beam set off north-west leaves north-east: InCornerTable's "one wall" answer, a
quarter turn.*
- The codes `$3F` and `$43-$46` (a cell and lasers no level holds): the trace treats them as a cell and as lasers.
- A gremlin killed while standing on a mirror it is turning: the kill clears +1, so the turn stops (no recording
  shows it).
