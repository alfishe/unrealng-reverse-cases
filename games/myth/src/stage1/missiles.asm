; --------------------------------------------------------------------------------------------------------------------
; missiles.asm: The missiles: shots, thrown objects and flyers in 16 six-byte records at $75E0
;
; $B2E6 calls, for each of the 16 records at $75E0 not free (+0 = $FF), the handler of its kind (+2) from the table at
; $B31A. The record: +0 the column (path flyers: +5 / 2), +1 y, +2 the kind, +3/+4/+5 the kind's own (a step, a
; direction). A handler frees its record with $B35E. Most of them draw with $B42B / $B446 (normal / mirrored) and
; colour with $B382, $B3A3 or $B40A / $B46F.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8006

; Kinds 2 and 3: an object thrown in an arc, left (2) or right (3); counts the
; drops into room 12's pit
;
; IY = the record: +3 the arc step, +4 the frame counter. CheckPitDrop first;
; below y $82 it is freed. +3 and +4 step; CheckArcLanding at steps 12 and 21;
; step 22 frees it. Every fourth tick x moves 1 (kind 2 left, 3 right); y +=
; ArcSteps[+3]. Draws frame +4 & 7 from $D926 (12 bytes a frame) with the
; record ArcFrame, mirrored for kind 3.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
UpdateThrownArc:
  CALL CheckPitDrop
  LD A,(IY+$01)
  CP $82
  JR C,ThrownArcMove
  JP RemoveActor
ThrownArcMove:
  INC (IY+$03)
  INC (IY+$04)
  CALL CheckArcLanding
  LD A,(IY+$03)
  CP $16
  JP Z,RemoveActor
  LD A,(IY+$04)
  AND $03
  JR NZ,ThrownArcDraw
  LD A,(IY+$02)
  CP $02
  JR Z,ThrownArcLeft
  INC (IY+$00)
  JR ThrownArcDraw
ThrownArcLeft:
  DEC (IY+$00)
ThrownArcDraw:
  LD C,(IY+$03)
  LD B,$00
  LD HL,ArcSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$01)
  LD (IY+$01),A
  LD A,(IY+$04)
  AND $07
  SLA A
  SLA A
  LD C,A
  SLA A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,ThrownSprites
  ADD HL,BC
  LD IX,ArcFrame
  LD A,(IY+$02)
  CP $02
  JR Z,ThrownArcMirror
  CALL DrawSpriteMirrored
  LD C,$07
  JP ColourSpriteMirrored
ThrownArcMirror:
  CALL DrawSprite
  LD C,$07
  JP ColourSprite

; The arc's y change at each step 0-22
ArcSteps:
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$05,$06,$07,$FC,$FD,$FE,$FF
  DEFB $00,$01,$02,$03,$04,$04,$00

; The thrown object's frame record: a word (0, the graphics come in HL), 2
; bytes wide, 6 lines
ArcFrame:
  DEFB $00,$00,$02,$06

; At arc steps 12 and 21: if the cell under the object is not free, hold the
; step
;
; Tests the cell at (x + 3, y + 8) with $B162; not free (Z) decrements +3 so
; the object rests.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
CheckArcLanding:
  LD A,(IY+$03)
  CP $0C
  JR Z,CheckArcLandingCell
  CP $15
  RET NZ
CheckArcLandingCell:
  LD A,(IY+$00)
  ADD A,$03
  LD E,A
  LD A,(IY+$01)
  ADD A,$08
  LD D,A
  CALL CellAt
  RET NZ
  DEC (IY+$03)
  RET

; An object below y $82: outside room 12 freed; in room 12 counted
; (EyeFlashRepeats, PitDrops up to 9; the ninth sets BossPhase 2)
;
; Only while BossPhase is 1. Above y $82: returns at once.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
CheckPitDrop:
  LD A,(IY+$01)
  CP $82
  RET C
  LD A,(RoomNumber)
  CP $0C
  JP NZ,RemoveActor
  LD A,(BossPhase)
  CP $01
  RET NZ
  LD A,(EyeFlashRepeats)
  INC A
  LD (EyeFlashRepeats),A
  LD A,(PitDrops)
  CP $09
  JR Z,CheckPitDropDone
  INC A
  LD (PitDrops),A
  RET
CheckPitDropDone:
  LD A,$02
  LD (BossPhase),A
  RET

; Kind 1: a shot flying in one of 8 directions; hurts the hero by 6
;
; +4 = the direction 0-7 (ShotDirections: dx, dy, the frame's offset in
; ShotFrames, mirrored). ShotHitsHero with C = 6; moves; freed at column 0 or
; $1F, y under 8 or $80 and up; draws the direction's frame.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
UpdateAimedShot:
  LD C,$06
  CALL ShotHitsHero
  LD A,(IY+$04)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,ShotDirections
  ADD HL,BC
  LD A,(IY+$00)
  ADD A,(HL)
  LD (IY+$00),A
  CP $00
  JP Z,RemoveActor
  CP $1F
  JP Z,RemoveActor
  INC HL
  LD A,(IY+$01)
  ADD A,(HL)
  LD (IY+$01),A
  CP $08
  JP C,RemoveActor
  CP $80
  JP NC,RemoveActor
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD B,$00
; This entry point is used by the routine at UpdateHeroShot.
DrawShotFrame:
  LD IX,ShotFrames        ; A = mirrored, C = the frame's offset in ShotFrames
  ADD IX,BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  CP $00
  JR NZ,DrawShotMirrored
  CALL DrawSprite
  CALL ColourRedYellow
  JP ColourSprite
DrawShotMirrored:
  CALL DrawSpriteMirrored
  CALL ColourRedYellow
  JP ColourSpriteMirrored

; Frame records: graphics address, width, lines ($C783 2x5, $C78D 1x15, $C79C
; 1x15, $C7AB 2x13, $C7C5 2x13)
ShotFrames:
  DEFB $83,$C7,$02,$05
  DEFB $8D,$C7,$01,$0F
  DEFB $9C,$C7,$01,$0F
  DEFB $AB,$C7,$02,$0D
  DEFB $C5,$C7,$02,$0D

; The 8 directions: dx, dy, the frame's offset in ShotFrames, 1 mirrored
ShotDirections:
  DEFB $00,$F8,$04,$00
  DEFB $01,$F8,$0C,$01
  DEFB $01,$00,$00,$01
  DEFB $01,$08,$10,$01
  DEFB $00,$08,$08,$00
  DEFB $FF,$08,$10,$00
  DEFB $FF,$00,$00,$00
  DEFB $FF,$F8,$0C,$00

; Kind 9: a shot flying left or right; stops at the room's edge or on an actor
; it hits
;
; +4 = 0 left, else right. Freed at column 0 or $1F, or when ShotHitsActor
; finds an actor (it sets the actor's hit flag). Draws ShotFrames' first frame
; ($C783), mirrored by the direction.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
UpdateHeroShot:
  LD A,(IY+$04)
  CP $00
  JR Z,HeroShotLeft
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  JR HeroShotHit
HeroShotLeft:
  DEC (IY+$00)
  JP Z,RemoveActor
HeroShotHit:
  CALL ShotHitsActor
  JP NZ,RemoveActor
  LD A,(IY+$04)
  LD BC,$0000
  JP DrawShotFrame

  ORG $83A9

; Kind 4: a falling (or rising) shot drifting right one column every other
; tick; hurts the hero by 10
;
; +3 = the tick 0-3 (the frame), +4 = dy a tick. Freed at y $88 and over or
; column $1E. ShotHitsHero with C = 10, then DrawDriftShot.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
UpdateDriftRight:
  LD A,(IY+$01)
  ADD A,(IY+$04)
  CP $88
  JP NC,RemoveActor
  LD (IY+$01),A
  LD A,(IY+$03)
  INC A
  AND $03
  LD (IY+$03),A
  AND $01
  JR Z,DriftRightHurt
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1E
  JP Z,RemoveActor
DriftRightHurt:
  LD C,$0A
  CALL ShotHitsHero

; Draw a drifting shot: frame +3 from the records at $B3EA, ink green (red in
; room 0), flickering bright
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
DrawDriftShot:
  LD A,(IY+$03)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,ImageDescriptors
  ADD IX,BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL DrawSprite
  LD E,$44
  LD A,(RoomNumber)
  CP $00
  JR NZ,DrawDriftShotColour
  LD E,$42
DrawDriftShotColour:
  LD A,(PassCounter)
  AND $01
  ADD A,E
  LD C,A
  CALL ColourSpriteMirrored
  RET

; Kind 5: as UpdateDriftRight, drifting left
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
UpdateDriftLeft:
  LD A,(IY+$01)
  ADD A,(IY+$04)
  CP $88
  JP NC,RemoveActor
  LD (IY+$01),A
  LD A,(IY+$03)
  DEC A
  AND $03
  LD (IY+$03),A
  AND $01
  JR NZ,DriftLeftHurt
  DEC (IY+$00)
  JP Z,RemoveActor
DriftLeftHurt:
  LD C,$0A
  CALL ShotHitsHero
  JP DrawDriftShot

; Kinds 7 and 8: a flyer along PathSteps, forwards (7) then back (8); OR-drawn
; 3 x 13 bytes
;
; +4 = the step into PathSteps (pairs: dx in half columns, dy), +5 = x in half
; columns, +3 a step counter. Kind 7 steps forwards; at the end mark ($64) it
; becomes kind 8 and is moved by RespawnShiftX (x 2) and RespawnShiftY, unless
; no lives are left (freed). Kind 8 steps back and is freed at step $FF. +0 =
; +5 / 2; the pre-shifted half ($B3EA or $B3EE by +5's parity) is ORed into the
; buffer (3 bytes x 13 lines) when on screen (column under $1E, y under $78),
; then coloured ($B38D, $B40A).
;
; Witness: L1 5080 (c1o, deaths, s1-right).
UpdatePathFlyer:
  LD A,(IY+$02)
  CP $08
  JR NZ,PathFlyerForward
  DEC (IY+$03)
  LD A,(IY+$03)
  CP $FF
  JP Z,RemoveActor
  DEC (IY+$04)
  JR PathFlyerStep
PathFlyerForward:
  INC (IY+$03)
  INC (IY+$04)
PathFlyerStep:
  LD A,(IY+$04)
  CP $80
  JR NC,PathFlyerPlace
  LD C,A
  SLA C
  LD B,$00
  LD HL,PathSteps
  ADD HL,BC
  LD A,(HL)
  CP $64
  JR NZ,PathFlyerMove
  LD (IY+$02),$08
  LD A,(RespawnShiftX)
  LD E,A
  LD A,(Lives)
  CP $00
  JP Z,RemoveActor
  LD A,(IY+$05)
  SUB E
  SUB E
  LD (IY+$05),A
  LD A,(RespawnShiftY)
  LD E,A
  LD A,(IY+$01)
  SUB E
  LD (IY+$01),A
  RET
PathFlyerMove:
  LD A,(IY+$02)
  CP $08
  JR Z,PathFlyerBack
  LD A,(IY+$05)
  ADD A,(HL)
  LD (IY+$05),A
  INC HL
  LD A,(IY+$01)
  ADD A,(HL)
  LD (IY+$01),A
  JR PathFlyerPlace
PathFlyerBack:
  LD A,(IY+$05)
  SUB (HL)
  LD (IY+$05),A
  INC HL
  LD A,(IY+$01)
  SUB (HL)
  LD (IY+$01),A
PathFlyerPlace:
  LD A,(IY+$05)
  SRL A
  LD (IY+$00),A
  LD IX,ImageDescriptors
  LD A,(IY+$05)
  AND $01
  JR NZ,PathFlyerDraw
  LD IX,ImageDescriptors+$0004
PathFlyerDraw:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IY+$00)
  CP $1E
  RET NC
  LD A,(IY+$01)
  CP $78
  RET NC
  CALL BufferAddressHL
  LD B,$0D
PathFlyerLine:
  PUSH BC
  LD B,$03
PathFlyerByte:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  INC HL
  DJNZ PathFlyerByte
  LD BC,$001D
  ADD HL,BC
  POP BC
  DJNZ PathFlyerLine
  CALL ColourYellowMagenta
  JP ColourSprite

; The flyer's path: dx (half columns), dy a step; $64 $64 ends
PathSteps:
  DEFB $01,$FE,$01,$FD,$01,$FB,$FF,$FB
  DEFB $FF,$FD,$FF,$FE,$FF,$01,$FF,$02
  DEFB $FF,$03,$01,$03,$01,$02,$01,$01
  DEFB $01,$FF,$01,$FE,$01,$FD,$01,$FD
  DEFB $FF,$FD,$FF,$FD,$FF,$FE,$FF,$FE
  DEFB $FF,$FF,$FF,$FF,$FF,$01,$FF,$01
  DEFB $FF,$02,$FF,$02,$FF,$03,$FF,$03
  DEFB $FF,$01,$FF,$FE,$FF,$FC,$FF,$FA
  DEFB $01,$FA,$01,$FC,$01,$FE,$01,$FF
  DEFB $01,$01,$01,$02,$01,$03,$01,$02
  DEFB $01,$01,$01,$00,$01,$00,$02,$00
  DEFB $02,$00,$02,$00,$02,$00,$03,$00
  DEFB $03,$00,$03,$00,$03,$00,$03,$00
  DEFB $03,$00,$03,$00,$03,$00,$04,$00
  DEFB $04,$00,$04,$00,$64,$64

; Kind 6: a shot flying flat left or right; in grid 2 at column 15 it triggers
; $A14A
;
; +5 = 0 right, 1 left. Freed at column 0 or $1E. In grid 2 (the single room)
; at column 15 with $FE5D 0: $A14A. Draws FlatShotFrame ($D986, 2 x 8),
; mirrored for +5 = 1, coloured by $B3A3.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
UpdateFlatShot:
  LD A,(IY+$05)
  CP $00
  JR Z,FlatShotRight
  DEC (IY+$00)
  JP Z,RemoveActor
  JR FlatShotCheck
FlatShotRight:
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1E
  JP Z,RemoveActor
FlatShotCheck:
  LD A,(GridNumber)
  CP $02
  JP NZ,FlatShotDraw
  LD A,(IY+$00)
  CP $0F
  JP NZ,FlatShotDraw
  LD A,(ArenaBossBeaten)
  CP $00
  JP NZ,FlatShotDraw
  LD A,(GridNumber)
  CP $02
  JP NZ,FlatShotDraw
  JP ArenaBossHit
FlatShotDraw:
  LD IX,FlatShotFrame
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IY+$05)
  CP $01
  JR Z,FlatShotMirrored
  CALL DrawSprite
  CALL MissileColour
  JP ColourSprite
FlatShotMirrored:
  CALL DrawSpriteMirrored
  CALL MissileColour
  JP ColourSpriteMirrored

; Frame record: graphics $D986, 2 bytes wide, 8 lines
FlatShotFrame:
  DEFB $86,$D9,$02,$08

; Kinds 10 and 11: a missile bouncing along the floor, left (10) or right (11);
; hurts the hero by 6
;
; +5 counts ticks: x moves 1 every other tick. +3 = the bounce step 1-44
; (BounceSteps), freed at 45 or at the room's edge; CheckBounceFloor at the
; bounce bottoms. ShotHitsHero with C = 6. Frames BounceFrames by +5's parity.
;
; Witness: L1 1092 (s1-right).
UpdateBouncer:
  LD A,(IY+$02)
  CP $0A
  JR Z,BouncerLeft
  INC (IY+$05)
  LD A,(IY+$05)
  AND $01
  JP NZ,BouncerStep
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  JP BouncerStep
BouncerLeft:
  INC (IY+$05)
  LD A,(IY+$05)
  AND $01
  CP $01
  JP NZ,BouncerStep
  DEC (IY+$00)
  JP Z,RemoveActor
BouncerStep:
  INC (IY+$03)
  CALL CheckBounceFloor
  LD C,$06
  CALL ShotHitsHero
  LD A,(IY+$03)
  CP $2D
  JP Z,RemoveActor
  LD C,A
  LD B,$00
  LD HL,BounceSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$01)
  LD (IY+$01),A
  LD A,(IY+$05)
  AND $01
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,BounceFrames
  ADD IX,BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL DrawSprite
  CALL ColourRedYellow
  JP ColourSprite

; Two frame records: $D996 and $D9B0, 2 bytes x 13 lines
BounceFrames:
  DEFB $96,$D9,$02,$0D
  DEFB $B0,$D9,$02,$0D

; The bouncer's y change at steps 1-44; the last 6 bytes ($8672-$8677) are
; never read (the step stops at 45)
BounceSteps:
  DEFB $01,$02,$03,$04,$05,$06,$FA,$FB
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$05,$06,$FB,$FC,$FD,$FE,$FF
  DEFB $00,$01,$02,$03,$04,$05,$FC,$FD
  DEFB $FE,$FF,$00,$01,$02,$03,$04,$FD
  DEFB $FE,$FF,$00,$01,$02,$03,$FE,$FF
  DEFB $00,$01,$02

; At steps 6, 19, 30, 39 and 46: if the cell under it is not free, hold the
; step (it rolls on the floor)
;
; Tests (x + 3, y + 16) with $B162.
;
; Witness: L1 1064 (s1-right).
CheckBounceFloor:
  LD A,(IY+$03)
  CP $06
  JR Z,CheckBounceFloorCell
  CP $13
  JR Z,CheckBounceFloorCell
  CP $1E
  JR Z,CheckBounceFloorCell
  CP $27
  JR Z,CheckBounceFloorCell
  CP $2E
  RET NZ
CheckBounceFloorCell:
  LD A,(IY+$00)
  ADD A,$03
  LD E,A
  LD A,(IY+$01)
  ADD A,$10
  LD D,A
  CALL CellAt
  RET NZ
  DEC (IY+$03)
  RET

; NZ (and the actor's hit flag, +$09 bit 4) when the shot IY is over a
; shootable actor
;
; For the 13 actors at $74F2: not free, shootable (+$0F bit 0), same column,
; and the shot's y - the actor's y under its height (+3). Returns via $B2E1
; (NZ, hit) or $B2DC (Z, none).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
ShotHitsActor:
  LD IX,Actors
  LD B,$0D
ShotHitsActorNext:
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,ShotHitsActorSkip
  BIT 0,(IX+$0F)
  JR Z,ShotHitsActorSkip
  LD A,(IX+$00)
  CP (IY+$00)
  JR NZ,ShotHitsActorSkip
  LD E,(IX+$03)
  LD A,(IY+$01)
  SUB (IX+$01)
  CP E
  JR NC,ShotHitsActorSkip
  SET 4,(IX+$09)
  POP BC
  JP ReturnNZ
ShotHitsActorSkip:
  LD BC,$0012
  ADD IX,BC
  POP BC
  DJNZ ShotHitsActorNext
  JP ReturnZ

  ORG $86EB

; Hurt the hero by C when the missile IY is in its column and within 14 lines;
; not through the shield
;
; Item 1 selected with a count: no harm. Else when the hero's x ($74E0) is +0
; and $A7B8 (A = $0E, E = the hero's y, D = +1) finds them overlapping,
; DamageHero.
;
; Witness: L1 1064 (s1-right).
ShotHitsHero:
  CALL GetSelectedItem
  CP $01
  JR NZ,ShotHitsHeroTest
  LD A,(IX+$00)
  CP $00
  RET NZ
ShotHitsHeroTest:
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$0E
  CALL AbsDiffBelow
  RET NC

  ORG $876C

; Missile kind 0 (no missile): flash the border from R for ever
;
; The entry 0 of the handler table at $B31A, and the jumps at $890F, $8911,
; $892D. A trap: never returns.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
HangFlashBorder:
  LD A,R
  OUT ($FE),A
  CALL KeyHook
  JP HangFlashBorder
