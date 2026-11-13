; Myth: History in the Making, System 3 Software 1989: stage 4 (TZX block 49), 33 792 bytes loaded at $6C3F by the
; resident stage loader over $6C3F-$F03E (tools/image.py).
; Written by kit/mkgame.py from src/stage4/stage4.ann and the recordings; edit stage4.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
Screen         EQU $4000  ; the screen's pixels
EnergyBarScreen EQU $4134  ; the HUD's energy bar: screen row 1, pixel line 1, column 20
Attributes     EQU $5800  ; the screen's attributes
PlayBuffer     EQU $5B00  ; the play buffer $5B00-$6CFF (its tail $6C3F-$6CFF is PlayBufferTail in the block): 18 character rows of 8 lines of 32 bytes, linear; also the unpack area of StageGraphics
DigitGlyphs    EQU $F959  ; resident font from '0': 8 bytes a character, 7 rows drawn (RenderDigits)
PlaySoundVector EQU $F9B0  ; resident: JP to the AY effect starter (E = the effect number)
DecimalTable   EQU $F9BF  ; resident: the words 10000, 1000, 100, 10, 1
DissolveMasks  EQU $F9CB  ; resident: the dissolve masks; DissolveHud reads sets 0-3 (32 bytes)
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
RandomSeed     EQU $FE08  ; NextSeed $909D: seed = seed x 5 + $15 (a linear congruential step); $07CF at the stage start (InitStageState)
RandomPointer  EQU $FE0A  ; Random $90AC: a pointer into the ROM ($0000-$3FFF), whose bytes are the random numbers; reseeded from R every 64 passes, $07CF at the stage start, $0D7A at each burst
SavedSP        EQU $FE0E  ; ClearBuffer and CopyBuffer keep the caller's SP here while SP walks their buffers
InitOnly10     EQU $FE10  ; set to 2 by InitStageState; no stage-1 code reads it (known only from the code)
InitOnly12     EQU $FE12  ; set to 1 by InitStageState; no stage-1 code reads it (known only from the code)
WorkByte       EQU $FE14  ; scratch: the placement counter of LoadRoomActors, the shape bits of StartBurst
ItemSelected   EQU $FE17  ; the slot of CarriedItems the HUD cursor is on (6 at the start)
ItemLast       EQU $FE18  ; the last used slot of CarriedItems (6 at the start; AddItem raises it)
ItemFirst      EQU $FE19  ; the first slot of CarriedItems (6): the item window does not scroll before it
RestoreAttributes EQU $FE1C  ; 1: the next attribute pass ($91D0) takes the solid cells' colours from RoomAttributes once (set by SavePlayAttrs $A1A9; stage 1's $FE5A)
SpanCount      EQU $FE1D  ; the spans in the span table $76A0 that CopyBuffer copies (BuildSpans $9959; stage 1's $FE1C)
SpanRow        EQU $FE1F  ; BuildSpans' cell row 0-17
CellColumn     EQU $FE20  ; the cell column 2-29 of RoomChange's and BuildSpans' loops
RoomColumn     EQU $FE22  ; the room's left edge in the grid, in blocks (2 cells)
RoomRow        EQU $FE23  ; the room's top edge in the grid, in blocks (16 lines)
RoomGrid       EQU $FE24  ; the grid record of the current map grid ($9B6F, $9B8A or $9B96)
Placements     EQU $FE26  ; the current grid's placement list (Grid0Placements, Grid1Placements, Grid2Placements): 3 bytes a placement, $FF ends
MissileCursor  EQU $FE28  ; AddMissile's round-robin slot number 0-7
CellFlag       EQU $FE2A  ; PutBlock $98F6: the byte written to the cell's twin in $7040 (always 0)
RoomExitsPtr   EQU $FE2F  ; the current room's byte in the grid's room table (grid record +4 + RoomNumber)
RoomNumber     EQU $FE31  ; the room in its grid, a grid row of rooms after another: +1 right, -1 left, + grid record +8 down (stage 1, grid 0: 12 the demon's lair)
PassCounter    EQU $FE32  ; +1 every pass (PassTick $97BD): the animations' clock
InitOnly36     EQU $FE36  ; set to $10 by InitStageState; no stage-4 code reads it (known only from the code)
BurstTimer     EQU $FE39  ; the burst's step 0..$1B ($0D in the small mode); $64 idle (RoomChange sets it), $FF just started
BurstSmall     EQU $FE3A  ; 0 a big burst (28 steps), 1 a small one (14 steps, doubled direction steps)
Energy         EQU $FE3B  ; the hero's energy, 0 (empty: a life lost) to $2E (full)
InitOnly3D     EQU $FE3D  ; set to $0D by InitStageState; no stage-4 code reads it (known only from the code)
InitOnly3E     EQU $FE3E  ; set to 1 by InitStageState; no stage-4 code reads it (known only from the code)
SpanOpen       EQU $FE3F  ; BuildSpans: 1 while a run of open cells goes on (stage 1's $FE42)
ItemsChanged   EQU $FE46  ; 1 after AddItem $7EA0: RedrawItemsIfChanged $7D66 clears it and redraws the item strip and the count
GridNumber     EQU $FE47  ; the map grid the hero is in, 0-10 (EnterGrid10 $969C sets 10, the mummy's room); with RoomNumber it indexes RespawnPoints (x 6) and picks the passages (CheckGridPassages $ACE0)
EnergyShown    EQU $FE48  ; the energy the HUD bar last drew
EnergyChange   EQU $FE49  ; the pending energy change: $80 and up drains 2 a pass, under $80 refills 2 a pass
SpawnDelay     EQU $FE4A  ; SpawnTimer $9245: passes to the next random spawn (Random at the stage start; 1 after a room change in grid 10, SavePlayAttrsGrid10 $A19C)
FireLatch      EQU $FE4B  ; 1 while FIRE stays held after a shot of item kind 1 or 3 (FireKind1 $954B, FireKind3 $959F): one shot a press
PiecesTaken    EQU $FE4C  ; pieces taken, 0-5
PieceFlash     EQU $FE4D  ; passes left of the HUD pieces' colour flash
PieceTakenFlag EQU $FE4E  ; 1 for one pass after a piece is taken
RespawnShiftX  EQU $FE4F  ; $FF: no death pending; else the hero's column less the respawn column less 2 (RespawnCountdown $9454); the path flyers move by it (x 2) when their path ends
RespawnShiftY  EQU $FE50  ; the hero's line less the respawn line less $27, set with RespawnShiftX
HeroFreeze     EQU $FE51  ; passes the hero's state handler is skipped ($17 after a life lost, $7F1D; counted down by HeroUpdate $AE04)
TrapChainTimer EQU $FE52  ; StartTrapChain $82FA sets $1C (grid 3, a rising piece at step $0A); TrapChainStep $830C counts it down and sets grid 3's trap slots 6 to 0 to 1, one every 4 passes
PiecesComplete EQU $FE53  ; set to 1 when the fifth piece is taken; +1 for each item of kind 6 taken (SpawnRewardItem gives the kind-6 item while it is 1)
PiecesMask     EQU $FE54  ; one bit a piece of the artefact (the room event's bit, actor +$10): spawned and taken
LivesFlash     EQU $FE55  ; the lives boxes' flash step, 0-$10 ($10 idle)
GameOverTimer  EQU $FE56  ; 0 in play; 1 when the last life is lost, counts to $32
UrnsComplete   EQU $FE57  ; 1 once AltarDisc $8931 finds four of item kind 9 (the urns) carried; then the disc flashes, and item kind 6 selected in grid 1 room 1 at column $15 and up leads into grid 10 (CheckGridPassages $ACE0)
BossPhase      EQU $FE58  ; the boss of grid 8 room 2 (a face on the wall that spits shots): 0 asleep, 1 awake and spitting (DrainKind9 $951D sets it when item kind 9 runs out in room 1; HeadShots $B412), 2 beaten (BossBeaten $A24C)
BossFlash      EQU $FE59  ; passes left of the boss's hit colours: 2 when a bolt reaches it (UpdateHeroBolt $8148); BossMouth $8AD8 and DrawBossPicture $8F4B count it down
BarrierState   EQU $FE5A  ; the barrier of grid 0 room 1: 0 closed, 1 its block shot away (BarrierBlockActor $96CB), 2 its pillar sunk: open (BarrierPillarActor $96DD; CheckGridPassages $ACE0 then lets the hero through)
BossHits       EQU $FE5B  ; the hits the boss still takes: $14 at the stage start (InitStageState $9FE3); -1 for each pass DrawBossPicture $8F57 finds BossFlash set; the last calls BossBeaten $A24C
Lives          EQU $FE5D  ; lives left, from H at StageEntry
  ORG $6C3F
  INCLUDE "variables.asm"  ; The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
  INCLUDE "entry.asm"  ; The stage's entry and set-up
  INCLUDE "mainloop.asm"  ; The main loop and its pass
  INCLUDE "render.asm"  ; The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
  INCLUDE "hud.asm"  ; The energy, the lives, the score, the HUD, game over and the stage exit
  INCLUDE "hero.asm"  ; The hero: walk, jump, crouch, strike, fire, the items and the item window
  INCLUDE "missiles.asm"  ; The missiles: shots, thrown objects and flyers in 16 six-byte records at $75E0
  INCLUDE "rooms.asm"  ; The room data, Unrle, the room builder and the room changes
  INCLUDE "enemies.asm"  ; The enemies, the hazards and the bosses
  INCLUDE "util.asm"  ; Small helpers: keys, clears, copies, numbers, random numbers, delays
  INCLUDE "actors.asm"  ; The actor records: placement, the per-pass update, the frames, the bursts
  INCLUDE "graphics.asm"  ; The stage's sprites, pictures and their frame tables

  SAVEBIN "stage4.bin",$6C3F,$8400
