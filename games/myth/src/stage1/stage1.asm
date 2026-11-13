; Myth: History in the Making, System 3 Software 1989: stage 1 (TZX block 40), 33 792 bytes loaded at $6C3F by the
; resident stage loader over $6C3F-$F03E (tools/image.py).
; Written by kit/mkgame.py from src/stage1/stage1.ann and the recordings; edit stage1.ann, not the .asm.

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
InitOnly10     EQU $FE10  ; set to 2 by InitStageState; no stage-1 code reads it (known only from the code)
InitOnly12     EQU $FE12  ; set to 1 by InitStageState; no stage-1 code reads it (known only from the code)
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
EyeFlashRepeats EQU $FE36  ; DrawRoomPicture's eye flashes still to come; +1 for each object thrown into room 12's pit (CheckPitDrop $80B2)
EyeFlashStep   EQU $FE37  ; DrawRoomPicture: the step 10-1 of the current flash
PitDrops       EQU $FE38  ; objects thrown into room 12's pit while the demon sleeps, up to 9: the ninth wakes it (BossPhase 2)
GateOpen       EQU $FE39  ; GateActor $9065: 1 while the gate stands raised (Y under $38): the left exit of its room is open
InitOnly3A     EQU $FE3A  ; set to $10 by InitStageState; no stage-1 code reads it (known only from the code)
BurstTimer     EQU $FE3D  ; the burst's step 0..$1B ($0D in the small mode); $64 idle (RoomChange sets it), $FF just started
BurstSmall     EQU $FE3E  ; 0 a big burst (28 steps), 1 a small one (14 steps, doubled direction steps)
Energy         EQU $FE3F  ; the hero's energy, 0 (full) to $2E
InitOnly40     EQU $FE40  ; set to $0D by InitStageState; no stage-1 code reads it (known only from the code)
InitOnly41     EQU $FE41  ; set to 1 by InitStageState; no stage-1 code reads it (known only from the code)
SpanOpen       EQU $FE42  ; BuildSpans: 1 while a run of open cells goes on
BossFlash      EQU $FE43  ; the boss's hit flash: passes left in white-on-red ($41)
ItemsChanged   EQU $FE4A  ; 1 after AddItem: the main loop redraws the item strip
GridNumber     EQU $FE4B  ; the grid the hero is in: 0 Grid0 (stage 1: the surface and the caves), 1 Grid1 (the shaft), 2 Grid2 (the arena)
BossPhase      EQU $FE4C  ; the winged boss's phase: 1 asleep (the start), 2 the flight, 3 the fall (BossFlees), 4 beaten; room 12's right exit is open from 4 on
EnergyShown    EQU $FE4D  ; the energy the HUD bar last drew
EnergyChange   EQU $FE4E  ; the pending energy change: $80 and up drains 2 a pass, under $80 refills 2 a pass
SpawnDelay     EQU $FE4F  ; SpawnTimer $8D1D: passes to the next random spawn (a random 0-15 at the stage start)
FireLatch      EQU $FE50  ; 1 while FIRE stays held after a shot or a throw: one a press
PiecesMask     EQU $FE51  ; one bit a piece of the artefact (the room event's bit, actor +$10): spawned and taken
PiecesTaken    EQU $FE52  ; pieces taken, 0-5
PieceFlash     EQU $FE53  ; passes left of the HUD pieces' colour flash
PiecesComplete EQU $FE54  ; set to 1 when the fifth piece is taken; +1 for each item of kind 6 taken (SpawnRewardItem gives the kind-6 item while it is 1)
PieceTakenFlag EQU $FE55  ; 1 for one pass after a piece is taken
RespawnShiftX  EQU $FE56  ; $FF: no death pending; else the hero's column less the respawn column less 2 (HeroDeath $B22B); the path flyers move by it (x 2) when their path ends
RespawnShiftY  EQU $FE57  ; the hero's line less the respawn line less $27, set with RespawnShiftX
HeroFreeze     EQU $FE58  ; passes the hero's state handler is skipped ($17 after a life lost)
LivesFlash     EQU $FE59  ; the lives boxes' flash step, 0-$10 ($10 idle)
RestoreAttributes EQU $FE5A  ; 1: UpdateAttributes takes the solid cells' colours from RoomAttributes once (the new room fades in over the old one)
GameOverTimer  EQU $FE5B  ; 0 in play; 1 when the last life is lost, counts to $32
BossHits       EQU $FE5C  ; the hits the winged boss's head still takes ($0A at the stage start)
ArenaBossBeaten EQU $FE5D  ; 1 once the arena's boss took 20 hits (ArenaBossHit): its picture and damage stop
ArenaBossHits  EQU $FE5E  ; the hits the arena's boss took, up to 20
ArenaFlash     EQU $FE5F  ; 1 after a hit on the arena's boss: its picture's colours flash red once
Lives          EQU $FE61  ; lives left, from H at StageEntry
  ORG $6C3F
  INCLUDE "variables.asm"  ; The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
  INCLUDE "entry.asm"  ; The stage's entry and set-up
  INCLUDE "mainloop.asm"  ; The main loop and its pass
  INCLUDE "render.asm"  ; The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
  INCLUDE "util.asm"  ; Small helpers: keys, clears, copies, numbers, random numbers, delays
  INCLUDE "hud.asm"  ; The energy, the lives, the score, the HUD, game over and the stage exit
  INCLUDE "hero.asm"  ; The hero: walk, jump, crouch, strike, fire, the items and the item window
  INCLUDE "missiles.asm"  ; The missiles: shots, thrown objects and flyers in 16 six-byte records at $75E0
  INCLUDE "enemies.asm"  ; The enemies, the hazards and the bosses
  INCLUDE "actors.asm"  ; The actor records: placement, the per-pass update, the frames, the bursts
  INCLUDE "rooms.asm"  ; The room data, Unrle, the room builder and the room changes
  INCLUDE "graphics.asm"  ; The stage's sprites, pictures and their frame tables

  SAVEBIN "stage1.bin",$6C3F,$8400
