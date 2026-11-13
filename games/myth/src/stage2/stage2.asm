; Myth: History in the Making, System 3 Software 1989: stage 2 (TZX block 43), 33 792 bytes loaded at $6C3F by the
; resident stage loader over $6C3F-$F03E (tools/image.py).
; Written by kit/mkgame.py from src/stage2/stage2.ann and the recordings; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
Screen         EQU $4000  ; the screen's pixels
EnergyBarScreen EQU $4134  ; the HUD's energy bar: screen row 1, pixel line 1, column 20
Attributes     EQU $5800  ; the screen's attributes
PlayBuffer     EQU $5B00  ; the play buffer $5B00-$6CFF (its tail $6C3F-$6CFF is PlayBufferTail in the block): 18 character rows of 8 lines of 32 bytes, linear; also the unpack area of StageGraphics
DigitGlyphs    EQU $F959  ; resident font from '0': 8 bytes a character, 7 rows drawn (RenderDigits)
PlaySoundVector EQU $F9B0  ; resident: JP to the AY effect starter (E = the effect number)
DecimalTable   EQU $F9BF  ; resident: the words 10000, 1000, 100, 10, 1
DissolveMasks  EQU $F9CC  ; resident: DissolveHud's eight masks
Score          EQU $F9FB  ; resident: the score's low four decimal digits, 0-9999 (AddScore)
ScoreHigh      EQU $F9FD  ; resident: the score's high two digits (ten thousands), 0-99 (AddScore)
BitReverse     EQU $FA00  ; resident: each byte with its bits reversed (the sprites drawn facing left)
ScreenLineTable EQU $FB00  ; resident: the screen address of each of the 192 pixel lines (words)
KeyUp          EQU $FC90  ; resident key reader: Z when UP is held (DEFINE KEYS / joystick patch its port and bit)
KeyDown        EQU $FC9F  ; resident key reader: Z when DOWN is held
KeyLeft        EQU $FCAE  ; resident key reader: Z when LEFT is held
KeyRight       EQU $FCBD  ; resident key reader: Z when RIGHT is held
KeyFire        EQU $FCCC  ; resident key reader: Z when FIRE is held
KeyHook        EQU $FCDB  ; resident: called before every key read (a RET, or the joystick / pause check DEFINE KEYS installs)
RandomSeed     EQU $FE08  ; NextSeed $8B76: seed = seed x 5 + $15 (a linear congruential step); $07CF at the stage start (InitStageState)
RandomPointer  EQU $FE0A  ; Random $8B85: a pointer into the ROM ($0000-$3FFF), whose bytes are the random numbers; reseeded from R every 64 passes, $07CF at the stage start, $0D7A at each burst
SavedSP        EQU $FE0E  ; ClearBuffer and CopyBuffer keep the caller's SP here while SP walks their buffers
InitOnly10     EQU $FE10  ; set to 2 by InitStageState $9766; SpawnHarpy $8DA4 keeps IY here (a word) between its two SpawnActor calls
InitOnly12     EQU $FE12  ; set to 1 by InitStageState; no stage-2 code reads it (known only from the code)
WorkByte       EQU $FE14  ; scratch: the placement counter of LoadRoomActors, the shape bits of StartBurst
ItemSelected   EQU $FE17  ; the slot of CarriedItems the HUD cursor is on (6 at the start)
ItemLast       EQU $FE18  ; the last used slot of CarriedItems (6 at the start; AddItem raises it)
ItemFirst      EQU $FE19  ; the first slot of CarriedItems (6): the item window does not scroll before it
SpanCount      EQU $FE1C  ; the spans in the span table $76A0 that CopyBuffer copies (BuildSpans $99E9)
SpanRow        EQU $FE1E  ; BuildSpans' cell row 0-17
CellColumn     EQU $FE1F  ; the cell column 2-29 of RoomChange's and BuildSpans' loops
RoomColumn     EQU $FE21  ; the room's left edge in the grid, in blocks (2 cells)
RoomRow        EQU $FE22  ; the room's top edge in the grid, in blocks (16 lines)
RoomGrid       EQU $FE23  ; the grid record of the current map grid ($9B6F, $9B8A or $9B96)
Placements     EQU $FE25  ; the current grid's placement list (Grid0Placements, Grid1Placements, Grid2Placements): 3 bytes a placement, $FF ends
MissileCursor  EQU $FE27  ; AddMissile's round-robin slot number 0-7
CellFlag       EQU $FE29  ; PutBlock $9986: the byte written to the cell's twin in $7040 (always 0)
RoomExitsPtr   EQU $FE2E  ; the current room's byte in the grid's room table (grid record +4 + RoomNumber)
RoomNumber     EQU $FE30  ; the room in its grid, a grid row of rooms after another: +1 right, -1 left, + grid record +8 down (stage 1, grid 0: 12 the demon's lair)
PassCounter    EQU $FE31  ; +1 every pass (PassTick $984D): the animations' clock
InitOnly3A     EQU $FE37  ; stage 1 has it at $FE3A; set to $10 by InitStageState $9766; no stage-2 code reads it (known only from the code)
BurstTimer     EQU $FE3A  ; stage 1 has it at $FE3D; the burst's step 0..$1B ($0D in the small mode); $64 idle (RoomChange sets it), $FF just started
BurstSmall     EQU $FE3B  ; stage 1 has it at $FE3E; 0 a big burst (28 steps), 1 a small one (14 steps, doubled direction steps)
Energy         EQU $FE3C  ; stage 1 has it at $FE3F; the hero's energy, 0 (full) to $2E
InitOnly40     EQU $FE3E  ; stage 1 has it at $FE40; set to $0D by InitStageState $9766; no stage-2 code reads it (known only from the code)
InitOnly41     EQU $FE3F  ; stage 1 has it at $FE41; set to 1 by InitStageState $9766; no stage-2 code reads it (known only from the code)
SpanOpen       EQU $FE40  ; stage 1 has it at $FE42; BuildSpans $93B5: 1 while a run of open cells goes on
Hydra3Step     EQU $FE41  ; the third head's step (written by $9F75), as Hydra1Step
Hydra3Pose     EQU $FE42  ; the third head's pose (written by $9F75), as Hydra1Pose
Hydra1Step     EQU $FE43  ; the hydra's first head: its step 0-$14 (HydraNeck1Step $9EEC); HydraHead1Actor $7FB5 fires at steps 4, 8 and 12 ($B31C)
Hydra1Pose     EQU $FE44  ; the first head's pose from $A113 (written by $9EEC): PlaceHydraHead $8100 picks its frame by it (under 5, 5-6, 7 and up)
Hydra2Step     EQU $FE45  ; the second head's step (written by $9F31), as Hydra1Step
Hydra2Pose     EQU $FE46  ; the second head's pose (written by $9F31), as Hydra1Pose
Hydra1X        EQU $FE4D  ; the first head's x in pixels less $18 ($28 at the start; written by $9EAE): PlaceHydraHead's column and shift
Hydra1Y        EQU $FE4E  ; the first head's line ($15 at the start; written by $9EAE)
Hydra2X        EQU $FE4F  ; the second head's x, as Hydra1X ($6D at the start)
Hydra2Y        EQU $FE50  ; the second head's line ($11 at the start)
Hydra3X        EQU $FE51  ; the third head's x, as Hydra1X ($34 at the start)
Hydra3Y        EQU $FE52  ; the third head's line ($0E at the start)
ItemsChanged   EQU $FE53  ; stage 1 has it at $FE4A; 1 after AddItem $7E2B: the main loop redraws the item strip (RedrawItemsIfChanged $7CF1)
GridNumber     EQU $FE54  ; stage 1 has it at $FE4B; the grid the hero is in: 0 Grid0 (the temple and the hydra's rooms), 1 Grid1, 2 Grid2 (Medusa's room); set by EnterGrid1 $8814, EnterGrid2 $8835, LeaveGrid2 $8859, LeaveGrid1 $8882
Statue0Broken  EQU $FE55  ; 1 once the statue of kind 0 ($A6EC) is struck: BreakStatue0 $9A41; the statue is not placed again
Statue1State   EQU $FE56  ; the statue of kind 1 ($A718): 0 standing, 1-3 the flash after a blow, $C8 broken (BreakStatue1 $9A14)
MedusaState    EQU $FE57  ; 0 Medusa stands, 1 struck (MedusaStruck $8138: her head falls), 2 the head lies, 4 the head taken (an item); CheckMedusaBarrier $835D closes the way at column $18 while 0
EnergyShown    EQU $FE58  ; stage 1 has it at $FE4D; the energy the HUD bar last drew
EnergyChange   EQU $FE59  ; stage 1 has it at $FE4E; the pending energy change: $80 and up drains 2 a pass, under $80 refills 2 a pass
HarpyPhase     EQU $FE5A  ; the harpy's statue (kind 3, $A7F6): 3 once the harpy is out (SpawnHarpy $8DA4), $FA when it flies off ($8EA9), back to 1 from 3 when the hero leaves the room (LeaveRoomRight / Left)
SpawnDelay     EQU $FE5B  ; stage 1 has it at $FE4F; SpawnTimer $8D45: passes to the next random spawn (5-20; a random byte at the stage start)
Hydra1Neck     EQU $FE5C  ; the first head's neck ($0E at the start; written by $9EEC); bit 7 set: the head cut off (CutHydraHead1 $80C1), $80 the head gone (its actors removed)
Hydra2Neck     EQU $FE5D  ; the second head's neck ($16 at the start; written by $9F31); bit 7 as Hydra1Neck
Hydra3Neck     EQU $FE5E  ; the third head's neck ($0E at the start; written by $9F75); bit 7 as Hydra1Neck
HydraHeads     EQU $FE5F  ; the hydra's heads left: 3 at the start, - 1 for each head cut off ($80C1, $80D6, $80EB); $64 once HydraDefeated $9BB4 has burst the body
FireLatch      EQU $FE60  ; stage 1 has it at $FE50; 1 while FIRE stays held after a shot or a throw: one a press
PieceFlash     EQU $FE62  ; stage 1 has it at $FE53; passes left of the HUD pieces' colour flash
PieceTakenFlag EQU $FE63  ; stage 1 has it at $FE55; 1 for one pass after a piece is taken
RespawnShiftX  EQU $FE64  ; stage 1 has it at $FE56; $FF: no death pending; else the hero's column less the respawn column less 2 (HeroDeath $B22B); the path flyers move by it (x 2) when their path ends
RespawnShiftY  EQU $FE65  ; stage 1 has it at $FE57; the hero's line less the respawn line less $27, set with RespawnShiftX
HeroFreeze     EQU $FE66  ; stage 1 has it at $FE58; passes the hero's state handler is skipped ($17 after a life lost, LoseLife $7EA8)
SpiritCount    EQU $FE67  ; the spirits (SpawnRandomEnemy $8F8C, SpiritActor $9028) on screen, at most 2
RestoreAttributes EQU $FE68  ; stage 1 has it at $FE5A; 1: UpdateAttributes takes the solid cells' colours from RoomAttributes once (the new room fades in over the old one)
PiecesComplete EQU $FE69  ; stage 1 has it at $FE54; set to 1 when the fifth piece is taken; +1 for each item of kind 6 taken (SpawnRewardItem gives the kind-6 item while it is 1)
PiecesTaken    EQU $FE6A  ; stage 1 has it at $FE52; pieces taken, 0-5
PiecesMask     EQU $FE6B  ; stage 1 has it at $FE51; one bit a piece of the artefact (the room event's bit, actor +$10): spawned and taken
LivesFlash     EQU $FE6C  ; stage 1 has it at $FE59; the lives boxes' flash step, 0-$10 ($10 idle)
GameOverTimer  EQU $FE6D  ; stage 1 has it at $FE5B; 0 in play; 1 when the last life is lost, counts to $32
Lives          EQU $FE6F  ; stage 1 has it at $FE61; lives left, from H at StageEntry
  ORG $6C3F
  INCLUDE "variables.asm"  ; The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
  INCLUDE "entry.asm"  ; The stage's entry and set-up
  INCLUDE "mainloop.asm"  ; The main loop and its pass
  INCLUDE "render.asm"  ; The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
  INCLUDE "hud.asm"  ; The energy, the lives, the score, the HUD, game over and the stage exit
  INCLUDE "hero.asm"  ; The hero: walk, jump, crouch, strike, fire, the items and the item window
  INCLUDE "enemies.asm"  ; The enemies, the hazards and the bosses
  INCLUDE "missiles.asm"  ; The missiles: shots, thrown objects and flyers in 16 six-byte records at $75E0
  INCLUDE "rooms.asm"  ; The room data, Unrle, the room builder and the room changes
  INCLUDE "util.asm"  ; Small helpers: keys, clears, copies, numbers, random numbers, delays
  INCLUDE "actors.asm"  ; The actor records: placement, the per-pass update, the frames, the bursts
  INCLUDE "graphics.asm"  ; The stage's sprites, pictures and their frame tables

  SAVEBIN "stage2.bin",$6C3F,$8400
