; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The sprite graphics: the droid, the enemies, the weapon-3 probe, the objects, the patrollers, the menu frame
;
; The graphics of every moving thing. The droid's frames are rows of 2 or 3 bytes, 40 rows; the enemy, materialise and
; probe frames 16 rows of 3 bytes after a shift byte; the object frames 24 rows of 4 bytes after a shift byte; the
; patroller frames 24 rows of 4 bytes. ShiftGraphic3 / ShiftGraphic4 shift the enemy and object frames in place by the
; shift byte, so the bytes of $A74E-$AEC4, $B049-$B2EF, $B413-$B6B9 and $B71B-$B83D change in play (L1 writes); every
; shift byte in the image is 0 (the frames as drawn).
; --------------------------------------------------------------------------------------------------------------------

; The droid's 14 frames, 40 rows each: frames 0-7 and 11-13 3 bytes wide,
; frames 8-10 (the turn and the front) 2 bytes
;
; DroidFrames $6888 points at each frame, DroidWidths $68A4 gives its width:
; 0-7 the walk (3 bytes, 120 each), 8 and 9 the turn-round (2 bytes), 10 the
; front, also the teleport beam (2 bytes, DroidFront), 11-13 the droid in the
; air (3 bytes; 13 never stays on screen). TurnRound $7866 mirrors $9C40-$A4AF
; in place (480 + 480 + 160 + 480 + 480 = 2 080 bytes), all but DroidFront, so
; the image holds the right-facing set and play turns it; PlaceDroid $7A6D
; reads DroidGraphics + 4 ($70 in the right-facing set) to know which way the
; frames face. L1: all 1 560 bytes read (3 586 417 reads), 1 480 written (127
; 784 writes: the mirroring; DroidFront's 80 bytes never).
DroidGraphics:
  INCBIN "res/sprites/Droid.bin",$0000,120
DroidWalk1:
  INCBIN "res/sprites/Droid.bin",$0078,120
DroidWalk2:
  INCBIN "res/sprites/Droid.bin",$00F0,120
DroidWalk3:
  INCBIN "res/sprites/Droid.bin",$0168,120
DroidWalk4:
  INCBIN "res/sprites/Droid.bin",$01E0,120
DroidWalk5:
  INCBIN "res/sprites/Droid.bin",$0258,120
DroidWalk6:
  INCBIN "res/sprites/Droid.bin",$02D0,120
DroidWalk7:
  INCBIN "res/sprites/Droid.bin",$0348,120
DroidTurn1:
  INCBIN "res/sprites/Droid.bin",$03C0,80
DroidTurn2:
  INCBIN "res/sprites/Droid.bin",$0410,80
DroidFront:
  INCBIN "res/sprites/Droid.bin",$0460,80
DroidFly1:
  INCBIN "res/sprites/Droid.bin",$04B0,120
DroidFly2:
  INCBIN "res/sprites/Droid.bin",$0528,120
DroidFly3:
  INCBIN "res/sprites/Droid.bin",$05A0,120

; 600 zero bytes inside the mirrored range
;
; TurnRound's last 3-byte pass runs to $A4AF (from $A2D0, 160 rows of 3 bytes),
; so it mirrors these zeros too (L1: 600 bytes, 52 680 reads and as many
; writes, all zeros); no frame points here.
DroidMirrorSpare:
  DEFS $0258

; 670 zero bytes no code reads or writes
;
; L1: no access in $A4B0-$A74D.
ZeroFill3:
  DEFS $029E

; The nine enemy kinds: 35 frames of 49 bytes (shift byte, 16 rows of 3 bytes)
;
; EnemyGraphics $68C1 points at each kind's first frame, EnemyFrameCounts $68B8
; gives its frames (4, 3, then 4). ShiftGraphic3 shifts a frame in place to the
; enemy's x. L1: every byte of $A74E-$AEC4 read (1 244 984 reads) and written
; (375 902 writes).
EnemyGraphicsData:
  INCBIN "res/sprites/Enemies.bin",$0000,196
EnemyKind2:
  INCBIN "res/sprites/Enemies.bin",$00C4,147
EnemyKind3:
  INCBIN "res/sprites/Enemies.bin",$0157,196
EnemyKind4:
  INCBIN "res/sprites/Enemies.bin",$021B,196
EnemyKind5:
  INCBIN "res/sprites/Enemies.bin",$02DF,196
EnemyKind6:
  INCBIN "res/sprites/Enemies.bin",$03A3,196
EnemyKind7:
  INCBIN "res/sprites/Enemies.bin",$0467,196
EnemyKind8:
  INCBIN "res/sprites/Enemies.bin",$052B,196
EnemyKind9:
  INCBIN "res/sprites/Enemies.bin",$05EF,196
EnemyExplosion:
  INCBIN "res/sprites/Enemies.bin",$06B3,49
EnemyExplosion2:
  INCBIN "res/sprites/Enemies.bin",$06E4,49
EnemyExplosion3:
  INCBIN "res/sprites/Enemies.bin",$0715,49
EnemyExplosion4:
  INCBIN "res/sprites/Enemies.bin",$0746,49

; An enemy materialising: 4 frames of 48 bytes (16 rows of 3, no shift byte)
;
; MaterialiseFrames $68DB. The frames are drawn at a byte column, so they are
; not shifted. L1: 192 bytes, 178 998 reads, no write.
MaterialiseGraphics:
  INCBIN "res/sprites/Materialise.bin",$0000,48
Materialise2:
  INCBIN "res/sprites/Materialise.bin",$0030,48
Materialise3:
  INCBIN "res/sprites/Materialise.bin",$0060,48
Materialise4:
  INCBIN "res/sprites/Materialise.bin",$0090,48

; Weapon 3's probe: 4 frames of 49 bytes (shift byte, 16 rows of 3)
;
; FireWeapon3 ($861C) and MoveShot3Frame ($8298 on) point the shot at frame
; (ShotFrame AND 3): 0, 1, 2, 3, then back down. L1: only the recordings
; rzx-040000, rzx-052000 and rzx-070000 fire weapon 3; they read frames 2 and 3
; ($AFB6-$B017, 291 reads), so frames 1 and 4 are known only from the code
; there. The recording probe-shield (tjB, doc 05 5.8) shows frames 2 and 4 too
; (rows at $AFB7 and $B019, counting from 1 as above), so only frame 1 is known
; only from the code. No write: the shift was 0 each time.
ProbeGraphics:
  INCBIN "res/sprites/Probe.bin",$0000,49
Probe2:
  INCBIN "res/sprites/Probe.bin",$0031,49
Probe3:
  INCBIN "res/sprites/Probe.bin",$0062,49
Probe4:
  INCBIN "res/sprites/Probe.bin",$0093,49

; The five object kinds: 17 frames of 97 bytes (shift byte, 24 rows of 4 bytes)
;
; ObjectKind $7C28 by the kind bits: bit 4 $B049 (3 frames), bit 5 $B16C (4),
; bit 6 $B2F0 (3), bit 7 $B413 (4), none $B597 (3). ShiftGraphic4 shifts a
; frame in place to the object's x. L1: all 1 649 bytes read (355 694 reads), 1
; 358 written (69 341 writes: $B049-$B2EF and $B413-$B6B9; kind 6 at $B2F0
; never shifted).
ObjectGraphics:
  INCBIN "res/sprites/Objects.bin",$0000,291
ObjectKind5:
  INCBIN "res/sprites/Objects.bin",$0123,388
ObjectKind6:
  INCBIN "res/sprites/Objects.bin",$02A7,291
ObjectKind7:
  INCBIN "res/sprites/Objects.bin",$03CA,388
ObjectKindNone:
  INCBIN "res/sprites/Objects.bin",$054E,291
ObjectDeath:
  INCBIN "res/sprites/Objects.bin",$0671,97
ObjectDeath2:
  INCBIN "res/sprites/Objects.bin",$06D2,97
ObjectDeath3:
  INCBIN "res/sprites/Objects.bin",$0733,97
ObjectDeath4:
  INCBIN "res/sprites/Objects.bin",$0794,97
ProbeExplosion:
  INCBIN "res/sprites/Objects.bin",$07F5,49
ProbeExplosion2:
  INCBIN "res/sprites/Objects.bin",$0826,49
ProbeExplosion3:
  INCBIN "res/sprites/Objects.bin",$0857,49
ProbeExplosion4:
  INCBIN "res/sprites/Objects.bin",$0888,49

; A patroller going right: 4 frames of 96 bytes (24 rows of 4)
;
; DrawPatroller $942D (at $9430) takes this set for a patroller moving right
; (direction bit 0 of +1 clear) and PatrolLeft for one moving left. Not
; shifted: a patroller moves a byte column at a time. L1: 768 bytes, 96 192
; reads, no write.
PatrolRight:
  INCBIN "res/sprites/Patrollers.bin",$0000,96
PatrolRight2:
  INCBIN "res/sprites/Patrollers.bin",$0060,96
PatrolRight3:
  INCBIN "res/sprites/Patrollers.bin",$00C0,96
PatrolRight4:
  INCBIN "res/sprites/Patrollers.bin",$0120,96
PatrolLeft:
  INCBIN "res/sprites/Patrollers.bin",$0180,96
PatrolLeft2:
  INCBIN "res/sprites/Patrollers.bin",$01E0,96
PatrolLeft3:
  INCBIN "res/sprites/Patrollers.bin",$0240,96
PatrolLeft4:
  INCBIN "res/sprites/Patrollers.bin",$02A0,96

; The menu screen's frame: 8 blocks of 16 x 16 pixels (16 rows of 2 bytes)
;
; Menu $8854 draws the frame with Blit16: the top edge 14 times along row 0,
; the bottom edge along row 22, the left and right edges 10 times down columns
; 0 and 30, and the four corners. L1 reads 4 992 (4 menus x 1 248).
MenuFrameTopEdge:
  INCBIN "res/graphics/MenuFrame.bin",$0000,32
MenuFrameBottomEdge:
  INCBIN "res/graphics/MenuFrame.bin",$0020,32
MenuFrameLeftEdge:
  INCBIN "res/graphics/MenuFrame.bin",$0040,32
MenuFrameRightEdge:
  INCBIN "res/graphics/MenuFrame.bin",$0060,32
MenuFrameTopLeft:
  INCBIN "res/graphics/MenuFrame.bin",$0080,32
MenuFrameTopRight:
  INCBIN "res/graphics/MenuFrame.bin",$00A0,32
MenuFrameBottomLeft:
  INCBIN "res/graphics/MenuFrame.bin",$00C0,32
MenuFrameBottomRight:
  INCBIN "res/graphics/MenuFrame.bin",$00E0,32

; 4 zero bytes no code reads
ZeroFill4:
  DEFS $04
