; Myth: History in the Making, System 3 Software 1989: stage 3 (TZX block 46), 33 792 bytes loaded at $6C3F by the
; resident stage loader over $6C3F-$F03E (tools/image.py).
; Written by kit/mkgame.py from src/stage3/stage3.ann and the recordings; edit stage3.ann, not the .asm.

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
RandomSeed     EQU $FE08  ; NextSeed $8A17: seed = seed x 5 + $15 (a linear congruential step); $07CF at the stage start (InitStageState)
RandomPointer  EQU $FE0A  ; Random $8A26: a pointer into the ROM ($0000-$3FFF), whose bytes are the random numbers; reseeded from R every 64 passes, $07CF at the stage start, $0D7A at each burst
SavedSP        EQU $FE0E  ; ClearBuffer and CopyBuffer keep the caller's SP here while SP walks their buffers
InitOnly10     EQU $FE10  ; set to 2 by InitStageState; no stage-3 code reads it (known only from the code)
InitOnly12     EQU $FE12  ; set to 1 by InitStageState; no stage-3 code reads it (known only from the code)
WorkByte       EQU $FE14  ; scratch: the placement counter of LoadRoomActors, the shape bits of StartBurst
ItemSelected   EQU $FE17  ; the slot of CarriedItems the HUD cursor is on (6 at the start)
ItemLast       EQU $FE18  ; the last used slot of CarriedItems (6 at the start; AddItem raises it)
ItemFirst      EQU $FE19  ; the first slot of CarriedItems (6): the item window does not scroll before it
SpanCount      EQU $FE1C  ; the spans in the span table SpanTable $76E0 that CopyBuffer copies (BuildSpans $99B1)
SpanRow        EQU $FE1E  ; BuildSpans' cell row 0-17
CellColumn     EQU $FE1F  ; the cell column 2-29 of RoomChange's and BuildSpans' loops
RoomColumn     EQU $FE21  ; the room's left edge in the grid, in blocks (2 cells)
RoomRow        EQU $FE22  ; the room's top edge in the grid, in blocks (16 lines)
RoomGrid       EQU $FE23  ; the grid record of the current map grid (Grid0 $9B37, Grid1 $9B44 or Grid2 $9B58)
Placements     EQU $FE25  ; the current grid's placement list (Grid0Placements, Grid1Placements, Grid2Placements): 3 bytes a placement, $FF ends
MissileCursor  EQU $FE27  ; AddMissile's round-robin slot number 0-7
CellFlag       EQU $FE29  ; PutBlock $994E: the byte written to the cell's twin in $7040 (always 0)
RoomExitsPtr   EQU $FE2E  ; the current room's byte in the grid's room table (grid record +4 + RoomNumber)
RoomNumber     EQU $FE30  ; the room in its grid, a grid row of rooms after another: +1 right, -1 left, + grid record +8 down (grid 1: 8 the dragon's room, 10 the drawbridge's)
PassCounter    EQU $FE31  ; +1 every pass (PassTick $9815): the animations' clock
InitOnly3A     EQU $FE3A  ; set to $10 by InitStageState; no stage-1 code reads it (known only from the code)
BurstTimer     EQU $FE3D  ; the burst's step 0..$1B ($0D in the small mode); $64 idle (RoomChange sets it), $FF just started
BurstSmall     EQU $FE3E  ; 0 a big burst (28 steps), 1 a small one (14 steps, doubled direction steps)
Energy         EQU $FE3F  ; the hero's energy, 0 (full) to $2E
InitOnly41     EQU $FE41  ; set to $0D by InitStageState; no stage-3 code reads it (stage 1's InitOnly40; known only from the code)
InitOnly42     EQU $FE42  ; set to 1 by InitStageState; no stage-3 code reads it (stage 1's InitOnly41; known only from the code)
SpanOpen       EQU $FE43  ; (stage 1: $FE42) BuildSpans: 1 while a run of open cells goes on
ItemsChanged   EQU $FE4B  ; (stage 1: $FE4A) 1 after AddItem: the main loop redraws the item strip
GridNumber     EQU $FE4C  ; (stage 1: $FE4B) the grid the hero is in: 0 Grid0 (the longship), 1 Grid1 (the swamp, the forest, the dragon and the castle's drawbridge), 2 Grid2 (the castle's hall)
DragonHits     EQU $FE4D  ; the hits on the dragon (grid 1 room 8): DrawDragon $887A counts them, $0F the last; DragonBeaten $A00F sets $10 (dead); read by UpdateThrownAmmo, DragonFireDamage, DragonHeadActor, DragonFlameActor
DragonHitFlag  EQU $FE4E  ; 1 for one pass after a thrown object reaches the dragon (UpdateThrownAmmo $8058); DrawDragon counts the hit, paints the dragon red and clears it; DragonHeadActor turns red on it
DragonBreath   EQU $FE4F  ; the dragon's breath step, 0 or 1-$12, written by DragonHeadActor ($92FF); DragonFlameActor shows the flame at steps 4-$11, DragonFireDamage ($8819) hurts the hero while it is not 0
EnergyShown    EQU $FE50  ; (stage 1: $FE4D) the energy the HUD bar last drew
EnergyChange   EQU $FE51  ; (stage 1: $FE4E) the pending energy change: $80 and up drains 2 a pass, under $80 refills 2 a pass
SpawnDelay     EQU $FE52  ; (stage 1: $FE4F) passes to the next random spawn (a random 0-15 at the stage start)
FireLatch      EQU $FE53  ; (stage 1: $FE50) 1 while FIRE stays held after a shot or a throw: one a press
PiecesMask     EQU $FE54  ; (stage 1: $FE51) one bit a piece of the artefact (the room event's bit, actor +$10): spawned and taken
PiecesTaken    EQU $FE55  ; (stage 1: $FE52) pieces taken, 0-5
PieceFlash     EQU $FE56  ; (stage 1: $FE53) passes left of the HUD pieces' colour flash
PiecesComplete EQU $FE57  ; (stage 1: $FE54) set to 1 when the fifth piece is taken; +1 for each item of kind 6 taken (SpawnRewardItem gives the kind-6 item while it is 1)
PieceTakenFlag EQU $FE58  ; (stage 1: $FE55) 1 for one pass after a piece is taken
LightningState EQU $FE59  ; the longship's lightning: stepped by LightningStep $A588 (4 the calm), read by LightningActor $94AC for the bolt's shape
RainStep       EQU $FE5A  ; the rain's step: StartRain $A3BA starts it, UpdateRain $A41E counts it (step $50 and $64 move PyreState), StopRoomEffects $9F19 clears it
RainPointer    EQU $FE5B  ; RainRandomByte $A54A's pointer through the ROM for the drops' columns; set by StartRain $A3BA
DrawbridgeDown EQU $FE5C  ; set to 1 by DrawbridgeActor ($93BA) when the drawbridge has come down (frame 7); read by it at $9374
PyreState      EQU $FE5D  ; the funeral pyre: 0 burning, 1 the flames dying (rain step $50), 2 out (step $64), 3 the body rising, 4 gone (PyreBodyActor); also read by PyreFireDamage $87ED and the room changes $9D97, $9DD3
RespawnShiftX  EQU $FE5E  ; (stage 1: $FE56) $FF: no death pending; else the hero's column less the respawn column less 2 (HeroDeath $B2C9); the path flyers move by it (x 2) when their path ends
RespawnShiftY  EQU $FE5F  ; (stage 1: $FE57) the hero's line less the respawn line less $27, set with RespawnShiftX
HeroFreeze     EQU $FE60  ; (stage 1: $FE58) passes the hero's state handler is skipped ($17 after a life lost)
RestoreAttributes EQU $FE61  ; (stage 1: $FE5A) 1: UpdateAttributes takes the solid cells' colours from RoomAttributes once (the new room fades in over the old one)
LivesFlash     EQU $FE62  ; (stage 1: $FE59) the lives boxes' flash step, 0-$10 ($10 idle)
GameOverTimer  EQU $FE63  ; (stage 1: $FE5B) 0 in play; 1 when the last life is lost, counts to $32
InitOnly64     EQU $FE64  ; set to $0A by InitStageState; no stage-3 code reads it (stage 1's BossHits; known only from the code)
ThroneBossHits EQU $FE65  ; the hits on the giant on the throne (grid 2): ThroneBossStep counts them ($9564), $1E the last; ThroneBossBeaten $A02A sets $1F
ThroneHitFlag  EQU $FE66  ; 1 when the hero's bolt reaches the giant (UpdateBolt $8239); ThroneBossStep reads it ($9530) and clears it ($955A)
VikingCount    EQU $FE68  ; the Vikings on the longship, at most 4: SpawnViking +1 ($8C44, $8C59), VikingDie -1 ($8E85), StopRoomEffects $9F1D clears it
Lives          EQU $FE6B  ; (stage 1: $FE61) lives left, from H at StageEntry
  ORG $6C3F
  INCLUDE "variables.asm"  ; The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
  INCLUDE "entry.asm"  ; The stage's entry and set-up
  INCLUDE "mainloop.asm"  ; The main loop and its pass
  INCLUDE "render.asm"  ; The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
  INCLUDE "util.asm"  ; Small helpers: keys, clears, copies, numbers, random numbers, delays
  INCLUDE "hud.asm"  ; The energy, the lives, the score, the HUD, game over and the stage exit
  INCLUDE "hero.asm"  ; The hero: walk, jump, leap, strike with the hammer, throw, the items and the item window
  INCLUDE "missiles.asm"  ; The missiles: shots, thrown objects, the bolt and flyers in 16 six-byte records at $75E0
  INCLUDE "rooms.asm"  ; The rooms: the grids, the room builder, the room changes and the grid passages
  INCLUDE "enemies.asm"  ; The enemies, the hazards and the bosses: the Vikings, the trolls, the bog men, the dragon, the pyre, the lightning, the giant on the throne
  INCLUDE "actors.asm"  ; The actors: the records, their handlers, the spawns, the drawing order
  INCLUDE "graphics.asm"  ; The stage's tiles and map, sprites, pictures and their frame tables

  SAVEBIN "stage3.bin",$6C3F,$8400
