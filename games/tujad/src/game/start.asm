; --------------------------------------------------------------------------------------------------------------------
; start.asm: The entry point and the work space
;
; The game block is entered at $6300 (the stub's JP $6300). The work space that follows holds the movers' records, the
; droid, the shot, the room and the scroller, then the scroller's messages and the buffers. Many of its bytes in the
; image are the authors' assembler source (Leftover text, src/res/leftover): the game writes those variables before it
; reads them.
; --------------------------------------------------------------------------------------------------------------------

; The game's entry: JP Setup
;
; The stub at $5B00 jumps here after the load (c1: L1 1).
Start:
  JP Setup

; The four enemy records of 9 bytes
;
; Record k (k = 0-3) at $6303 + 9k: +0 the timer (passes to the next step), +1
; the state (bits 0-1 the direction 0 right, 1 down, 2 left, 3 up; bit 6
; materialising; bit 7 hit, the explosion; $40 with +0 = 1 or 2 a spawn
; waiting), +2 x in pixels (up to $F0; a spawn writes Random OR $20 AND $F8,
; $20-$D0), +3 y in pixels (up to $B0), +4/+5 the graphic pointer, +6 the
; frame, +7 the frames, +8 the attribute. DrawRoom $6B40 zeroes byte 0 of each
; and, by the bits of the room's enemy mask, sets +0 to 1 or 2, +1 to $40 and
; the graphic to BlankGraphic $6609. MainLoop calls MoveEnemy $90E7 with each
; record (L1 18 579 passes).
Enemies:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
Enemy2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
Enemy3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
Enemy4:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; The room's two object records of 10 bytes
;
; Object 1 at $6327, object 2 at $6331: +0 the kind (bits 4-7, ObjectKind) and
; a 2-pass move timer (bits 0-1; 0: no object), +1 the state (bits 0-1 the
; direction, bit 4 dead (MoveObject returns at once), bit 5 stopped by another
; weapon (cleared again when its own weapon kills it: MoveObjectDying RES 5),
; bit 6 just entered, bit 7 dying), +2 x (pixels), +3 y, +4/+5 the graphic, +6
; the frame, +7 the frames, +8 the weapon mark it dies to, +9 the attribute.
; DrawRoom copies the room's records from the alien map into these (LDIR at
; $6C2B), SaveRoomObjects $6ADC writes them back when the droid leaves the
; room, so an object keeps its place and its life. MainLoop calls MoveObject
; $809D for each (L1 18 579).
Objects:
  DEFB $00
Object1Flags:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
Object2:
  DEFB $00
Object2Flags:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; The three patroller records of 8 bytes, and their pointers
;
; A patroller moves along a fixed row through several rooms: +0 bit 7 not drawn
; (DrawRoom sets it on every room change), the frame; +1 y and the direction;
; +2 the column; +3 the room it is in; +4/+5 the room and column where it turns
; right; +6/+7 where it turns left. MovePatrollers $6AAD takes one a pass
; through PatrollerPtrs. The bytes in the image are the start state (no NewGame
; resets them).
Patrollers:
  DEFB $00,$98,$13,$78,$7B,$10,$78,$13
Patroller2:
  DEFB $00,$90,$1B,$00,$05,$07,$00,$1B
Patroller3:
  DEFB $00,$98,$16,$6B,$6D,$19,$6B,$16
PatrollerPtrs:
  DEFB $3B,$63,$43,$63,$4B,$63 ; the addresses of the three records, read by
                               ; MovePatrollers

; The droid, the shot, the room and the energy counters
;
; x (column 0-$1D), y (pixel row $30-$98 in steps of 2), the flags (bit 0
; facing left, bit 1 turning, bit 2 in the air (no wall under the feet), bit 3
; moving, bit 4 the shield (down held alone: FlagPointer $0000, EnergyReload
; 10, HazardFlash), bit 6 the step frame, bit 7 the sprite list's collision
; bit), the frame 0-13, the width in bytes. The image's bytes from $6359 are
; Leftover text (the authors' source): PlaceDroid $7A6D and NewGame $7A2F write
; every byte before play.
DroidVars:
  INCBIN "res/leftover/Source1.bin",$0000,1
DroidY:
  INCBIN "res/leftover/Source1.bin",$0001,1
DroidFlags:
  INCBIN "res/leftover/Source1.bin",$0002,1
DroidFrame:
  INCBIN "res/leftover/Source1.bin",$0003,1
DroidWidth:
  INCBIN "res/leftover/Source1.bin",$0004,1
Shot:
  INCBIN "res/leftover/Source1.bin",$0005,1
ShotPos:
  INCBIN "res/leftover/Source1.bin",$0006,2
ShotGraphic:
  INCBIN "res/leftover/Source1.bin",$0008,2
Room:
  INCBIN "res/leftover/Source1.bin",$000A,1
ControlsLatch:
  INCBIN "res/leftover/Source1.bin",$000B,2
EnergyTimer:
  INCBIN "res/leftover/Source1.bin",$000D,1
EnemyKindTurn:
  INCBIN "res/leftover/Source1.bin",$000E,1
Weapons:
  INCBIN "res/leftover/Source1.bin",$000F,1
KeyLatches:
  INCBIN "res/leftover/Source1.bin",$0010,1
Ammo:
  INCBIN "res/leftover/Source1.bin",$0011,3
Lives:
  INCBIN "res/leftover/Source1.bin",$0014,1
Energy:
  INCBIN "res/leftover/Source1.bin",$0015,1
MoveDelay:
  INCBIN "res/leftover/Source1.bin",$0016,1
DeathColour:
  INCBIN "res/leftover/Source1.bin",$0017,3
PatrollerTurn:
  INCBIN "res/leftover/Source1.bin",$001A,1
EnergyReload:
  INCBIN "res/leftover/Source1.bin",$001B,1
BorderSound:
  INCBIN "res/leftover/Source1.bin",$001C,1
TeleportLatch:
  INCBIN "res/leftover/Source1.bin",$001D,1
TouchTimer:
  INCBIN "res/leftover/Source1.bin",$001E,1
DroidGraphic:
  INCBIN "res/leftover/Source1.bin",$001F,2
TurnGraphic:
  INCBIN "res/leftover/Source1.bin",$0021,2
TurnStep:
  INCBIN "res/leftover/Source1.bin",$0023,2
FlagPointer:
  INCBIN "res/leftover/Source1.bin",$0025,2

; The start values of $6364-$637F, copied by NewGame
;
; NewGame $7A59 copies these 28 bytes to ControlsLatch (L1 4 new games, LDIR
; 112 runs). Energy timer $FA, weapon 0, ammunition 3 3 3, lives 3, energy 99,
; move delay 1, the drain reload $FA, DroidGraphic BlankGraphic, TurnGraphic
; DroidFrames' first ($9C40), TurnStep TurnSequence, FlagPointer DroidFlags.
InitialVars:
  DEFB $00,$01,$FA,$00,$80,$00,$03,$03
  DEFB $03,$03,$99,$01,$00,$00,$00,$00
  DEFB $FA,$00,$00,$00,$09,$66,$40,$9C
  DEFB $B2,$68,$5B,$63

; The room's items, teleporter and the scratch words
;
; From the room's alien record (DrawRoom $6B6C): the two items' positions and
; kinds, the teleporter's position and target room; then the random number, the
; patroller pointer, the item cell found and scratch words of the movers and
; the shots. The image's bytes are Leftover text (the authors' source).
RoomVars:
  INCBIN "res/leftover/Source2.bin",$0000,1
Item2Pos:
  INCBIN "res/leftover/Source2.bin",$0001,1
Item1Kind:
  INCBIN "res/leftover/Source2.bin",$0002,1
Item2Kind:
  INCBIN "res/leftover/Source2.bin",$0003,1
TeleportPos:
  INCBIN "res/leftover/Source2.bin",$0004,1
TeleportRoom:
  INCBIN "res/leftover/Source2.bin",$0005,1
TeleportColumn:
  INCBIN "res/leftover/Source2.bin",$0006,1
TeleportRow:
  INCBIN "res/leftover/Source2.bin",$0007,1
RandomSeed:
  INCBIN "res/leftover/Source2.bin",$0008,4
PatrollerPtr:
  INCBIN "res/leftover/Source2.bin",$000C,2
FoundItem:
  INCBIN "res/leftover/Source2.bin",$000E,4
MoverScratch:
  INCBIN "res/leftover/Source2.bin",$0012,3
DrawMode:
  INCBIN "res/leftover/Source2.bin",$0015,1
RoomRecordPtr:
  INCBIN "res/leftover/Source2.bin",$0016,2
RoomEnemyPtr:
  INCBIN "res/leftover/Source2.bin",$0018,2
TileAttrPtr:
  INCBIN "res/leftover/Source2.bin",$001A,2
ObjectScratch:
  INCBIN "res/leftover/Source2.bin",$001C,4
StepX:
  INCBIN "res/leftover/Source2.bin",$0020,1
StepY:
  INCBIN "res/leftover/Source2.bin",$0021,1
StepWidth:
  INCBIN "res/leftover/Source2.bin",$0022,1
StepHeight:
  INCBIN "res/leftover/Source2.bin",$0023,1
ShotScratch:
  INCBIN "res/leftover/Source2.bin",$0024,1
ShotMark:
  INCBIN "res/leftover/Source2.bin",$0025,1
Controls:
  INCBIN "res/leftover/Source2.bin",$0026,1
TouchBits:
  INCBIN "res/leftover/Source2.bin",$0027,1
ObjectBits:
  INCBIN "res/leftover/Source2.bin",$0028,1
BeamScreen:
  INCBIN "res/leftover/Source2.bin",$0029,2
ScrollText:
  INCBIN "res/leftover/Source2.bin",$002B,2
ScrollNext:
  INCBIN "res/leftover/Source2.bin",$002D,2
ScrollPriority:
  INCBIN "res/leftover/Source2.bin",$002F,1
ScrollLine:
  INCBIN "res/leftover/Source2.bin",$0030,1
ScrollDelay:
  INCBIN "res/leftover/Source2.bin",$0031,1
ScrollScreen:
  INCBIN "res/leftover/Source2.bin",$0032,2
SpriteListEnd:
  INCBIN "res/leftover/Source2.bin",$0034,2
