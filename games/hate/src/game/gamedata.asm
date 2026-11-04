; Object record: the player
;
; Every moving or hittable thing is a 16-byte record in the list $C000-$C26F,
; ended by $FF at $C270; docs/07-objects.md 7.1-7.2. +0 flags and type (bit 7
; gone, 6 end, 5 hit, 0-3 type), +1/+2 position along, +3 across, +4 height, +5
; direction, +6 speed, +7 behaviour, +8 the sprite slot in $C300 (also the
; explosion frame), +9-+B screen place, +C/+E motion steps, +F fire timer. Zero
; in the image: the round start fills the list. Bit 7 of $C000 set is a lost
; life ($CFEF).
PlayerRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object records: the player's shots (5)
;
; $E82F fires into a free one; $CFD6 counts the free ones for the gauge.
PlayerShotRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object records: pods (4)
;
; Released by shot domes ($EDFE); docs/07-objects.md 7.5.
PodRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object record: the vehicle of the other kind
;
; Parked at position $600, from VehicleTemplate ($D1FB); the vehicle of the
; next round.
ParkedVehicleRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object records: the course's objects (16)
;
; The round's block of the course data, 8 bytes each, the rest zeroed ($D250).
CourseObjectRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object records: launched missiles and jets (6)
;
; Filled from the templates $C2B4 by a firing object ($E1DD).
LaunchedRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object records: the enemy's shots (5)
;
; Filled from EnemyShotTemplate ($E1E1).
EnemyShotRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Object record: the vehicle of the round before
;
; At position $6C ($D27A).
PreviousVehicleRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; End of the object list ($FF)
ObjectListEnd:
  DEFB $FF

; Pass counter of the mover
;
; Incremented once a pass by $E15C; steering acts when its low 2 bits are 0
; (every 4 passes).
PassCounter:
  DEFB $00

; Height wave: 16 steps
;
; Followed by records with behaviour bit 1 ($E3BF), index +E mod 16.
HeightWave:
  DEFB $00,$08,$0D,$11,$14,$16,$17,$18,$18,$18,$17,$16,$14,$11,$0D,$08

; Height arc of a missile or shell
;
; 9 up to 24 and down to 2, then $FF: a height of 25 or more ends the flight
; ($E38F). The shell's start is found in it from the player's height ($E878).
MissileArc:
  DEFB $09,$0E,$12,$15,$17,$18,$17,$15,$12,$0E,$09,$02,$FF

; Input device: 0 keyboard, 1 Sinclair, 2 Kempston, 3 Protek-AGF
;
; Set by the menu ($F26D), read by the device reader ($E6FF);
; docs/05-controls.md 5.1.
InputDevice:
  DEFB $01

; Control byte: bit 0 left, 1 right, 2 down, 3 up, 4 fire
;
; Written once a pass by the device reader $E68C; docs/05-controls.md 5.2. The
; byte after it ($C291) is not referenced by address.
ControlByte:
  DEFB $00,$00

; Player start: +1 to +7 of $C000
;
; Position along $0080, across $2C, height 2, direction 0, speed 1, behaviour
; 0; copied by $D1FB at each round start.
PlayerTemplate:
  DEFB $80,$00,$2C,$02,$00,$01,$00

; Not referenced by address
UnusedC299:
  DEFS $08

; The parked and the previous vehicle records
;
; $C2A1 is set to the type of the round's vehicle ($D1FB) and becomes +0 of
; $C260 in the next round ($D27A). $C2A2-$C2B0 are copied to $C0A1 (position
; along $0600, across $2C, height 2); $C2A4-$C2B0 to $C263.
VehicleTemplate:
  DEFB $00,$00,$06,$2C,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Game start: JP to the main loop
;
; Entered once from the start-up $9F2C.
GameStart:
  JP GameEntry

; Templates of launched objects (5 x 9 bytes)
;
; +0 to +8 of a record (the position is then copied from the firer, the rest
; cleared): type 8 jet, type 7 missile (written at $D1FB: course vehicle type +
; 6), type 8 jet, type 4 missile, type 6 missile. A pad picks one by the
; highest set bit of its behaviour bits 7-4 ($E1D7); the dome of type 2 throws
; out the third ($E259); docs/07-objects.md 7.4.
LaunchTemplates:
  DEFB $08,$00,$00,$00,$00,$04,$02,$89,$10
  DEFB $07,$00,$00,$00,$00,$04,$03,$41,$0E
  DEFB $08,$00,$00,$00,$00,$04,$03,$11,$10
  DEFB $04,$00,$00,$00,$00,$02,$03,$22,$08
  DEFB $06,$00,$00,$00,$00,$04,$03,$81,$0C

; Template of an enemy shot
;
; Bytes `1C 00 00 00 00 04 04 00 18`: type 12 (the low nibble; bit 4 set),
; direction 4, speed 4, sprite slot $18; used by firing objects below type 14:
; $E1BD points DE at it and the same `LDIR` at $E1F5 that copies
; `LaunchTemplates` copies it.
EnemyShotTemplate:
  DEFB $1C,$00,$00,$00,$00,$04,$04,$00,$18

; New position along of the record being moved
;
; Written by $E2D7 (position + direction step x speed), read by the hit window
; set-up $E531.
MoverAlong:
  DEFW $0000

; Hit test window starts, along (3 words)
;
; The moving record's new position along less half the box, for the three size
; classes of the other record; set at $E531, compared in $E586-$E62D;
; docs/07-objects.md 7.4.
HitWindowAlong:
  DEFW $0000
  DEFW $0000
  DEFW $0000

; New position across of the record being moved
MoverAcross:
  DEFB $00

; Hit test window starts, across (3 bytes)
HitWindowAcross:
  DEFB $00,$00,$00

; New height of the record being moved
;
; docs/10-gameplay-logic.md; the terrain check $E400-$E43B corrects it.
MoverHeight:
  DEFB $00

; Round number, 1-10
;
; docs/04-game-loop.md 4.2.
RoundNumber:
  DEFB $00

; Lap: passes through the 10 rounds
;
; 0 at the start ($9F29); from 1 on the course is armed harder ($D296,
; docs/07-objects.md 7.8).
LapNumber:
  DEFB $00

; Lives of the round
Lives:
  DEFB $00

; Round number string: two digits at (21,18)
;
; Printed by $D1BF; the digits are written into $C2FD-$C2FE (the record: $87,
; $15, $12, digit, digit, $FF).
RoundText:
  DEFM $87,$15,$12,"  ",$FF

; Sprite graphics pointers
;
; 23 addresses into $6580-$7FFF, read as $C300 + record byte +8 ($DBEC, $DC67,
; $DCD6, $EA8F). Slots $20-$2C are the explosion frames.
SpriteTable:
  DEFW SpriteGfx00,SpriteGfx02,SpriteGfx04,SpriteGfx06
  DEFW SpriteGfx08,SpriteGfx0A,SpriteGfx0A,SpriteGfx0E
  DEFW SpriteGfx10,SpriteGfx10,SpriteGfx14,SpriteGfx16
  DEFW SpriteGfx18,SpriteGfx1A,SpriteGfx1C,SpriteGfx1E
  DEFW ExplosionGfx20,ExplosionGfx22,ExplosionGfx20,ExplosionGfx26
  DEFW ExplosionGfx28,ExplosionGfx2A,ExplosionGfx2C

; Scroll state: page step 0-63
;
; docs/06-rendering.md 6.2-6.4.
ScrollPage:
  DEFB $00

; Scroll state: strip half, 0 or $80
ScrollHalf:
  DEFB $00

; Not referenced by address
UnusedC330:
  DEFB $00

; SP saved by the blit and the strip builder
;
; $D35E and $D536 use SP to walk address lists.
SavedStack:
  DEFW $0000

; Shot gauge string
;
; Five cells at (3,6), filled with "/" for each free shot slot by $CFD6, then a
; "/" at (2,6); printed at $CFE9; docs/08-hud-and-text.md 8.3.
ShotGaugeText:
  DEFM $84,$03,$06,"     ",$87,$02,$06,"/",$FF

; Direction steps: along, across (8 x 4 bytes)
;
; Read by $E2B3: the word +0 is the step along, the byte +2 the step across;
; docs/07-objects.md 7.1.
Directions:
  DEFW $0002,$0000
  DEFW $0001,$FFFF
  DEFW $0000,$FFFE
  DEFW $FFFF,$FFFF
  DEFW $FFFE,$0000
  DEFW $FFFF,$0001
  DEFW $0000,$0002
  DEFW $0001,$0001

; Template of the player's shot
;
; Type 12, direction 0, speed 6, sprite slot $18; copied by $E889.
ShotTemplate:
  DEFB $1C,$00,$00,$00,$00,$00,$06,$00,$18,$00,$00,$00,$00,$00,$00,$00

; Template of the ground vehicle's shell
;
; Type 12, speed 6, behaviour bit 2 (the arc $C282), sprite slot $1A; copied by
; $E841.
ShellTemplate:
  DEFB $0C,$00,$00,$00,$00,$00,$06,$04,$1A,$00,$00,$00,$00,$00,$00,$00

; Hit handlers: 7 rows of 8
;
; $EBAA jumps to the word at $C380 + 16 x (moving type / 2) + 2 x (other type /
; 2). Rows for the moving types 0-1 to 12-13; types 14-15 never move first.
; $EBD1 both hit, $EC0B nothing, $EC0F both turn, $EC27 player meets a shot,
; $E57E nothing (next pair), the rest score or collect; docs/07-objects.md 7.6.
HitHandlers:
  DEFW HitBoth,HitBoth,HitBoth,HitBoth,HitBoth,HitPlayerOnPod,HitPlayerOnShot,HitPlayerOnStatic
  DEFW HitBoth,HitNone,HitNone,HitNone,HitNone,HitNone,HitDomeOnShot,PairScanNext
  DEFW HitBoth,HitNone,HitTurnRound,HitNone,HitNone,HitNone,HitTargetOnShot,PairScanNext
  DEFW HitBoth,HitNone,HitNone,HitNone,HitNone,HitNone,HitTargetOnShot,PairScanNext
  DEFW HitBoth,HitNone,HitNone,HitNone,HitNone,HitNone,HitTargetOnShot,PairScanNext
  DEFW HitBlockOnPlayer,HitBlockOnOther,HitBlockOnOther,HitBlockOnOther,HitBlockOnOther,HitBlockOnOther,HitBlockOnShot,PairScanNext
  DEFW HitShotOnPlayer,HitShotOnDome,HitShotOnTarget,HitShotOnTarget,HitShotOnTarget,HitShotOnBlock,HitShotOnShot,PairScanNext

; Weave: direction sequence 4 5 6 5 4 3 2 3
;
; Behaviour bit 6 ($E327), index +C mod 8.
WeavePattern:
  DEFB $04,$05,$06,$05,$04,$03,$02,$03

; Next row of the expanded course
;
; docs/06-rendering.md 6.5; $D49C, $D536.
CourseRowPtr:
  DEFW RowList

; Strips drawn in the round
;
; At 32 the round starts ($D4BF).
StripCount:
  DEFW $0000

; Page of the last fresh strip
;
; Written by $D57F; docs/06-rendering.md 6.4.
FreshStripPage:
  DEFW $0000

; Not referenced by address
UnusedC3FE:
  DEFS $02
