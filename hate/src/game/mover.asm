; Objects: move, steer, height, walls and hits, once a pass
;
; Step 5 of the pass (docs/04-game-loop.md 4.3, docs/07-objects.md 7.4). Counts
; the passes in $C271, then moves every live record of $C000 with MoveRecord.
; The new position along goes to $C2EA, across to $C2F2, the height to $C2F6
; (for the player, $C2F6 already holds the height $E7E9 or AUTO chose);
; StoreMove writes them back unless the record stopped.
MoveObjects:
  LD A,(PassCounter)      ; the pass counter: steering every 4 passes, height
                          ; every 2
  INC A
  LD (PassCounter),A
  LD IX,PlayerRecord
  BIT 7,(IX+$00)          ; the player gone: start with the next record
  JP NZ,NextMover

; Move one record
;
; IX = the record. In order: the distance ahead of the scroll ($D14D): below 0
; the record is gone, 352 or more it waits. A dying record (bit 5) counts its
; explosion. With behaviour bit 3, at 190 or more ahead, every 8th pass (+F)
; and on a random bit, it fires: pads and dishes (types 14-15) launch the
; template $C2B4 + 9k (k from the highest of behaviour bits 7-4) into a free
; slot of $C1B0-$C200; the others fire the template $C2E1 into the first free
; of the 6 slots from $C210 (which takes in $C260). A record with no speed and
; no height behaviour stops here, except the player.
;
; Then the step (direction table $C340 times the speed +6), steering by
; behaviour bits 4-7, the height by bits 0-2, the terrain (TerrainHeight),
; walls and the barrier from the profile, and the hit boxes for PairScan
; (docs/07-objects.md 7.4, docs/10-gameplay-logic.md 10.3, 10.4).
MoveRecord:
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD BC,(ScrollDistance)  ; minus the distance scrolled
  AND A
  SBC HL,BC
  LD A,H
  BIT 7,A                 ; behind the scroll: gone
  JR Z,AheadOfScroll
  SET 7,(IX+$00)
  JP NextMover
AheadOfScroll:
  CP $01                  ; $160 (352) or more ahead: not yet
  JR C,WithinRange
  JP NZ,NextMover
  LD A,L
  CP $60
  JP NC,NextMover
WithinRange:
  BIT 5,(IX+$00)          ; dying?
  JP NZ,RecordDying
  BIT 3,(IX+$07)          ; behaviour bit 3: fires
  JR Z,CheckSpeed
  LD BC,$00BE             ; less than 190 ahead: no
  AND A
  SBC HL,BC
  BIT 7,H
  JR NZ,CheckSpeed
  LD A,(IX+$0F)           ; the fire timer: every 8th pass
  INC A
  AND $07
  LD (IX+$0F),A
  JR NZ,CheckSpeed
  CALL Random             ; and on a random bit
  BIT 0,L
  JR NZ,CheckSpeed
  LD DE,EnemyShotTemplate ; an enemy shot: template $C2E1, slots from $C210
  LD HL,EnemyShotRecords
  LD A,(IX+$00)
  AND $0F
  CP $0E                  ; pads and dishes launch instead
  JR C,LaunchObject
  LD A,(IX+$07)           ; the highest of behaviour bits 7-4 picks the
                          ; template
  LD HL,LaunchTemplates
  LD DE,$0009
  LD B,$04
HighestBitLoop:
  RLA
  JR C,TemplateChosen
  ADD HL,DE
  DJNZ HighestBitLoop
TemplateChosen:
  EX DE,HL
  LD HL,LaunchedRecords   ; launched objects: $C1B0-$C200
LaunchObject:
  LD A,$06                ; DE = template, HL = the first slot: 6 slots
  LD BC,$0010
FreeSlotLoop:
  BIT 7,(HL)              ; bit 7: a free slot
  JR NZ,FillSlot
  ADD HL,BC
  DEC A
  JR NZ,FreeSlotLoop
  JR CheckSpeed           ; all taken: no launch
FillSlot:
  LD BC,$0009             ; 9 bytes of template, 7 zero
  EX DE,HL
  PUSH DE
  LDIR
  LD B,$07
  XOR A
ZeroRecordTail:
  LD (DE),A
  INC E
  DJNZ ZeroRecordTail
  LD E,(IX+$01)           ; the position of the firer
  LD D,(IX+$02)
  POP HL
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  LD A,(IX+$03)
  INC L
  LD (HL),A
  LD A,(IX+$04)
  INC L
  LD (HL),A
CheckSpeed:
  LD A,(IX+$06)           ; the speed
  AND A
  JP NZ,RecordStep
  LD A,(IX+$07)           ; no speed, no height behaviour ...
  AND $07
  JR NZ,StandStill
  LD A,IXL                ; ... and not the player: nothing more
  AND A
  JP NZ,NextMover
  LD A,IXH
  CP $C0
  JP NZ,NextMover
StandStill:
  LD HL,$0000             ; no step along or across
  XOR A
  JP NewPosition
RecordDying:
  LD A,(IX+$08)           ; the explosion counter + 2
  ADD A,$02
  CP $2D                  ; 45: gone
  JR C,StoreExplosion
  SET 7,(IX+$00)
  JP NextMover
StoreExplosion:
  LD (IX+$08),A
  CP $22                  ; at 34 and 40 a dome of type 2 throws out a jet
  JR Z,DomeJet
  CP $28
  JR NZ,FollowerShield
DomeJet:
  LD A,(IX+$00)
  AND $0F
  CP $02
  JR NZ,FollowerShield
  LD DE,LaunchTemplates+$0012 ; template $C2C6
  LD HL,LaunchedRecords
  JP LaunchObject
FollowerShield:
  LD A,(IX+$00)           ; the player hit with followers: the last one lost
                          ; instead
  AND $0F
  CP $02
  JR NC,DyingSpeed
  LD A,(Followers)        ; the followers
  AND A
  JR Z,DyingSpeed
  DEC A
  LD (Followers),A
  LD HL,(ConvoyLinkEnd)   ; the end of the follower list
  DEC HL
  LD D,(HL)
  LD (HL),$FF
  DEC HL
  LD E,(HL)
  LD (HL),$FF
  LD (ConvoyLinkEnd),HL
  EX DE,HL
  DEC L
  DEC L
  DEC L
  SET 5,(HL)              ; that follower is hit ...
  LD A,$08
  ADD A,L
  LD L,A
  LD (HL),$20             ; ... its explosion starts at 32
  LD HL,(FollowerOffset)
  LD BC,$0006
  ADD HL,BC
  LD (FollowerOffset),HL
  LD A,(IX+$00)           ; the player is not hit after all
  RES 5,A
  LD (IX+$00),A
  AND $0F                 ; +8 = 2 x type again: its own sprite
  ADD A,A
  LD (IX+$08),A
DyingSpeed:
  LD A,(IX+$06)           ; dying records go on moving at their speed
  AND A
  JR NZ,RecordStep
  LD HL,$0000
  XOR A
  JR NewPosition
RecordStep:
  LD HL,Directions        ; the direction table $C340, 4 bytes a direction
  LD A,(IX+$05)
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  LD E,(HL)               ; DE = the step along
  INC L
  LD D,(HL)
  INC L
  LD A,(HL)               ; A = the step across
  EX DE,HL
  LD B,(IX+$06)           ; times the speed
  DEC B
  JR Z,NewPosition
  LD E,L
  LD D,H
  LD C,A
SpeedLoop:
  ADD HL,DE
  ADD A,C
  DJNZ SpeedLoop
NewPosition:
  LD C,(IX+$01)
  LD B,(IX+$02)
  ADD HL,BC
  LD (MoverAlong),HL      ; the new position along
  ADD A,(IX+$03)
  LD (MoverAcross),A      ; the new position across
  LD A,(IX+$07)           ; behaviour bits 4-7: steering
  AND $F0
  JP Z,HeightBehaviour
  BIT 5,A                 ; bit 5: turn round at the edge
  JR Z,NotTurnAtEdge
  LD A,(MoverAcross)
  DEC A
  CP $46                  ; across 0 or $47 and up
  JR C,HeightBehaviour
  LD A,(IX+$05)
  ADD A,$04
  AND $07
  LD (IX+$05),A
  JR HeightBehaviour
NotTurnAtEdge:
  BIT 4,A                 ; bit 4: toward the player across, every 4 passes
  JR Z,NotChase
  LD A,(PassCounter)
  AND $03
  JR NZ,HeightBehaviour
  LD A,($C003)            ; the player's position across
  LD B,A
  LD A,(MoverAcross)
  SUB B
  ADD A,$03
  LD C,$04                ; from 3 below to 2 above the player: direction 4,
                          ; straight
  CP $06
  JR C,SetChaseDirection
  INC C                   ; direction 5, across + 1
  BIT 7,A
  JR NZ,SetChaseDirection
  LD C,$03                ; direction 3, across - 1
SetChaseDirection:
  LD (IX+$05),C
  JR HeightBehaviour
NotChase:
  BIT 6,A                 ; bit 6: the weave $C3F0, every 4 passes
  JR Z,NotWeave
  LD A,(PassCounter)
  AND $03
  JR NZ,HeightBehaviour
  LD A,(IX+$0C)
  INC A
  AND $07
  LD (IX+$0C),A
  LD C,A
  LD B,$00
  LD HL,WeavePattern
  ADD HL,BC
  LD A,(HL)
  LD (IX+$05),A
  JR HeightBehaviour
NotWeave:
  BIT 7,A                 ; bit 7: a random turn, every 4 passes
  JR Z,HeightBehaviour
  LD A,(PassCounter)
  AND $03
  JR NZ,HeightBehaviour
  CALL Random
  LD A,(IX+$05)
  INC A
  BIT 0,L
  JR Z,StoreRandomTurn
  DEC A
  DEC A
StoreRandomTurn:
  AND $07
  LD (IX+$05),A
HeightBehaviour:
  LD A,(IX+$07)           ; behaviour bits 0-2: the height
  AND $07
  JR Z,NoHeightBehaviour
  BIT 0,A                 ; bit 0: follow the player's height, a step every
                          ; other pass
  JR Z,NotFollowHeight
  LD A,(PassCounter)
  BIT 0,A
  JR NZ,NoHeightBehaviour
  LD A,($C004)
  LD B,A
  LD A,(IX+$04)
  CP B
  JR Z,ClampHeight
  JR C,RiseOne
  DEC A
  JR ClampHeight
RiseOne:
  INC A
ClampHeight:
  CP $19                  ; at most 24
  JR C,StoreHeight
  LD A,$18
  JR StoreHeight
NotFollowHeight:
  BIT 2,A                 ; bit 2: the arc $C282
  JR Z,NotArc
  LD A,(IX+$0E)
  INC A
  LD (IX+$0E),A
  LD C,A
  LD B,$00
  LD HL,MissileArc
  ADD HL,BC
  LD A,(HL)
  CP $19                  ; the arc's end (25 or more) ...
  JP C,StoreHeight
  BIT 5,(IX+$00)          ; ... a dying record stays at 2
  JR Z,ArcEndGone
  LD A,(IX+$0E)
  DEC A
  LD (IX+$0E),A
  LD A,$02
  JR StoreHeight
ArcEndGone:
  SET 7,(IX+$00)          ; ... otherwise it is gone
  JP NextMover
NotArc:
  BIT 1,A                 ; bit 1: the wave $C272, 16 steps
  JR Z,KeepHeight
  LD A,(IX+$0E)
  INC A
  AND $0F
  LD (IX+$0E),A
  LD C,A
  LD B,$00
  LD HL,HeightWave
  ADD HL,BC
  LD A,(HL)
  JR StoreHeight
NoHeightBehaviour:
  LD A,(IX+$00)           ; no height behaviour: the player keeps $C2F6, the
                          ; others their height
  AND $0F
  CP $02
  JR C,TerrainHeight
KeepHeight:
  LD A,(IX+$04)
StoreHeight:
  LD (MoverHeight),A      ; the new height
TerrainHeight:
  LD DE,ProfileMargin+$0042 ; the profile under the record
  LD B,$05                ; types 0-3: 6 profile bytes
  LD A,(IX+$00)
  AND $0F
  CP $04
  JR C,ProfileUnder
  LD B,$03                ; types 4-10: 4
  CP $0B
  JR C,ProfileUnder
  INC DE                  ; types 11-15: 2, one further on
  LD B,$01
ProfileUnder:
  LD L,(IX+$01)
  LD H,(IX+$02)
  SRL H
  RR L
  ADD HL,DE
  LD C,$1F                ; ground bits 0-4
  LD A,(HL)
  AND C
  LD D,A
  LD A,(HL)
  EX AF,AF'               ; A' = the profile bytes ORed: the walls
HighestGroundLoop:
  EX AF,AF'               ; D = the highest ground
  INC HL
  OR (HL)
  EX AF,AF'
  LD A,(HL)
  AND C
  CP D
  JR C,NotHigher
  LD D,A
NotHigher:
  DJNZ HighestGroundLoop
  INC D                   ; + 2: the floor
  INC D
  LD A,(IX+$00)
  BIT 5,A                 ; not dying, a type below 10 ...
  JR NZ,FlyingFloor
  AND $0F
  CP $0A
  JR NC,FlyingFloor
  BIT 0,A                 ; ... and odd: on the ground
  JR Z,FlyingFloor
  LD (IX+$04),D
  JR SetFloorHeight
FlyingFloor:
  LD A,(MoverHeight)      ; flying: raised to the floor, never lowered
  CP D
  JR NC,HeightBox
SetFloorHeight:
  LD A,D
  LD (MoverHeight),A
HeightBox:
  SUB $07                 ; IYL = height - 7: the low edge of the height box
  LD IYL,A
  LD E,$47                ; across limit $47 with no wall
  LD A,(IX+$00)
  AND $0F
  CP $0B                  ; pods and dying records: no walls
  JP Z,AcrossClamp
  BIT 5,(IX+$00)
  JP NZ,AcrossClamp
  EX AF,AF'               ; profile bit 7: a wall, limit $17
  RLA
  JR NC,CheckWallBit6
  LD E,$17
WallLimit:
  LD A,(IX+$00)
  AND $0F
  CP $0C                  ; shots
  JR Z,ShotOnWall
  LD A,(MoverAcross)
  LD C,A
  CP E                    ; inside the limit
  JP C,CheckLowEdge
  BIT 7,A
  JP NZ,ClampAcrossLow
  BIT 5,(IX+$07)          ; behaviour bit 5: turn to direction 2
  JR Z,WallOvershoot
  LD (IX+$05),$02
WallOvershoot:
  SUB $06                 ; within 6 of the wall: put just inside
  CP E
  JP C,JustInsideLimit
  LD L,(IX+$01)           ; further: no step along, 6 back across
  LD H,(IX+$02)
  LD (MoverAlong),HL
  BIT 0,L
  JR Z,ClearAcrossBit0
  SET 0,A
  JR StoreAcross
ClearAcrossBit0:
  RES 0,A
  JR StoreAcross
ShotOnWall:
  LD A,(MoverAcross)
  LD C,A
  CP E
  JR C,CheckLowEdge
  LD A,(IX+$05)           ; direction 0: a shot of the player
  AND A
  JR NZ,ShotVanishes
ShotStopped:
  SET 5,(IX+$00)          ; hit, stopped, explosion at 32
  LD (IX+$06),$00
  LD (IX+$08),$20
  LD HL,SoundRequests     ; sound request bit 2 (docs/09-sound.md 9.6)
  SET 2,(HL)
  JP NextMover
ShotVanishes:
  SET 7,(IX+$00)          ; other shots just vanish
  JP NextMover
CheckWallBit6:
  RLA                     ; profile bit 6: a wall, limit $27
  JR NC,Barrier
  LD E,$27
  JR WallLimit
Barrier:
  RLA                     ; profile bit 5 alone: the barrier
                          ; (docs/10-gameplay-logic.md 10.4)
  JR NC,AcrossClamp
  LD A,(IX+$00)
  AND $0F
  CP $02
  JR C,BarrierPlayer
  CP $0B                  ; types 2-10: not moved this pass, no hit test
  JP C,NextMover
  LD A,(IX+$05)           ; types 12-15: direction 0 (the player's shots) stops
                          ; on it; others pass
  AND A
  JR Z,ShotStopped
  JR AcrossClamp
BarrierPlayer:
  LD A,$FF                ; the player: the AUTO countdown starts, with or
                          ; without followers
  LD (AutoCountdown),A
  LD A,(Followers)        ; followers: it passes
  AND A
  JR NZ,AcrossClamp
  SET 5,(IX+$00)          ; none: the player is hit
  LD (IX+$08),$20
  LD HL,SoundRequests     ; sound request bit 1
  SET 1,(HL)
AcrossClamp:
  LD A,(MoverAcross)      ; across within 2 .. limit - 1
  LD C,A
  CP E
  JR C,CheckLowEdge
  BIT 7,A
  JR NZ,ClampAcrossLow
JustInsideLimit:
  LD A,E
  DEC A
  JR KeepStepBit0
CheckLowEdge:
  CP $02
  JR NC,KeepStepBit0
ClampAcrossLow:
  LD A,$02
KeepStepBit0:
  BIT 0,C                 ; keep bit 0 of the step's across
  JR Z,StoreAcross
  SET 0,A
StoreAcross:
  LD (MoverAcross),A      ; the new position across
  LD A,(IX+$00)
  BIT 5,A
  JP NZ,StoreMove         ; dying: no hit test
  LD BC,$0007             ; half the box: 7 for types 0-3
  LD E,$0F
  AND $0F
  CP $04
  JR C,HitBoxes
  LD C,$05                ; 5 for types 4-10
  LD E,$0B
  CP $0B
  JR C,HitBoxes
  LD C,$03                ; 3 for types 11 and up
  LD E,$07
HitBoxes:
  LD HL,(MoverAlong)      ; the box starts, one for each class of the other
                          ; record
  AND A
  SBC HL,BC
  LD (HitWindowAlong),HL  ; along: position - half (others 11-13)
  DEC HL
  DEC HL
  LD (HitWindowAlong+$0002),HL ; - 2 more (others 4-10)
  DEC HL
  DEC HL
  LD (HitWindowAlong+$0004),HL ; - 2 more, 4 in all (others 0-3)
  LD A,(MoverAcross)
  SUB C
  LD (HitWindowAcross),A  ; across - half: written, not read by the scan
  SUB $02
  LD (HitWindowAcross+$0001),A ; across - half - 2 (others 4-13)
  SUB $02
  LD (HitWindowAcross+$0002),A ; across - half - 4 (others 0-3)
  LD A,E                  ; the box widths into the CP operands below
  LD (PairWithSmall+$0014),A ; others 11-13: 2 x half + 1
  LD (PairWithSmall+$0020),A
  ADD A,$04
  LD (PairWithMid+$0014),A ; others 4-10: + 4
  LD (PairWithMid+$0020),A
  ADD A,$04
  LD (PairWithBig+$0014),A ; others 0-3: + 8
  LD (PairWithBig+$0020),A
  LD HL,PlayerRecord      ; every record, from $C000

; Hit test: the moving record against every record
;
; IX = the moving record, HL = the other. Records that are gone or dying are
; passed over. The other's class picks the box: its position along less the box
; start (BC) must be below the width, as must its position across less the
; start, and its height less IYL below 15. The width operands are self-modified
; by MoveRecord ($E555): the box is centred along for every class, and across
; for others of types 0-10; against types 11-13 the across box starts at $C2F4
; and runs 2 lower than centred ($C2F3, the centred start, is written and not
; read). Pads (14) are never hit; dishes (15) only by the player, without a
; height test. A pair goes to the handler table at $EBAA, which skips the
; record itself (docs/07-objects.md 7.4, 7.6). The list's end goes to
; StoreMove.
PairScan:
  LD A,(HL)
  BIT 6,A                 ; the end of the list: done
  JP NZ,StoreMove
  PUSH HL
  BIT 7,A                 ; gone
  JR NZ,PairScanNext
  BIT 5,A                 ; dying
  JR Z,PairByClass

; Drop the other record's address and go on
;
; Also the "nothing" handler of the hit table (docs/07-objects.md 7.6).
PairScanNext:
  POP HL

; The next record of the scan
;
; The pair scan moves on to the next record (HL + 16) and tests it against the
; moving record IX again (PairScan). Most pairs come by falling through
; PairScanNext (the other record gone or dying, or the "nothing" handler of the
; table); it is jumped to directly when the other record is the moving one
; itself and from HitShotOnTarget when an enemy shot passes a moving target;
; entered 640 205 times in the bot game (PairScan 656 852)
; (docs/04-game-loop.md 4.5, docs/07-objects.md 7.6).
PairScanStep:
  LD DE,$0010
  ADD HL,DE
  JP PairScan
; This entry point is used by the routine at PairScan.
PairByClass:
  AND $0F
  CP $04
  JP C,PairWithBig
  CP $0B
  JP C,PairWithMid
  CP $0E
  JP C,PairWithSmall      ; 11-13
  JR Z,PairScanNext       ; 14: pads are never hit
  LD A,(IX+$00)           ; 15: dishes, only the player
  AND $0F
  CP $02
  JR NC,PairScanNext
  LD BC,($C2F0)           ; along, a box 23 wide
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  LD A,D
  AND A
  JP NZ,PairScanNext
  LD A,E
  CP $17
  JP NC,PairScanNext
  LD A,($C2F5)            ; across, 23 wide; no height test
  LD B,A
  INC L
  LD A,(HL)
  SUB B
  CP $17
  JP NC,PairScanNext
  JP HitDispatch          ; a hit: the handler table
PairWithBig:
  LD BC,($C2F0)           ; the other is of types 0-3
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  LD A,D
  AND A
  JP NZ,PairScanNext
  LD A,E
  CP $17                  ; the width: self-modified, 2 x half + 9
  JP NC,PairScanNext
  LD A,($C2F5)            ; across
  LD B,A
  INC L
  LD A,(HL)
  SUB B
  CP $17                  ; self-modified like $E5DC
  JP NC,PairScanNext
  INC L
  LD A,(HL)               ; the other's height
  LD IYH,A
  SUB IYL                 ; within 7 either way
  CP $0F
  JP NC,PairScanNext
  JP HitDispatch
PairWithMid:
  LD BC,($C2EE)           ; the other is of types 4-10
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  LD A,D
  AND A
  JP NZ,PairScanNext
  LD A,E
  CP $13                  ; the width: self-modified, 2 x half + 5
  JP NC,PairScanNext
  LD A,($C2F4)
  LD B,A
  INC L
  LD A,(HL)
  SUB B
  CP $13                  ; self-modified like $E60E
  JP NC,PairScanNext
  INC L
  LD A,(HL)
  LD IYH,A
  SUB IYL
  CP $0F
  JP NC,PairScanNext
  JP HitDispatch
PairWithSmall:
  LD BC,(HitWindowAlong)  ; the other is of types 11-13
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  LD A,D
  AND A
  JP NZ,PairScanNext
  LD A,E
  CP $0F                  ; the width: self-modified, 2 x half + 1
  JP NC,PairScanNext
  LD A,($C2F4)            ; across from $C2F4, not $C2F3
  LD B,A
  INC L
  LD A,(HL)
  SUB B
  CP $0F                  ; self-modified like $E640
  JP NC,PairScanNext
  INC L
  LD A,(HL)
  LD IYH,A
  SUB IYL
  CP $0F
  JP NC,PairScanNext
  JP HitDispatch

; Write the new position and height into the record
;
; From $C2F6 (height), $C2EA (along) and $C2F2 (across), into +4, +1/+2 and +3.
StoreMove:
  LD A,(MoverHeight)
  LD (IX+$04),A
  LD HL,(MoverAlong)
  LD (IX+$01),L
  LD (IX+$02),H
  LD A,(MoverAcross)
  LD (IX+$03),A

; The next live record to move
;
; Gone records (bit 7) are passed over; bit 6 ends the list.
NextMover:
  LD DE,$0010
  ADD IX,DE
  LD A,(IX+$00)
  BIT 7,A
  JP Z,MoveRecord
  BIT 6,A
  JP Z,NextMover
  RET

; Passes down has been held, up to 6: the aircraft's climb step
;
; $E687-$E68A: one counter for each stick direction, read by the player routine
; $E7E9; the step is (count + 1) / 2 (docs/10-gameplay-logic.md 10.3).
DownHeldCount:
  DEFB $00

; Passes up has been held, up to 6
UpHeldCount:
  DEFB $00

; Passes left has been held, up to 6
LeftHeldCount:
  DEFB $00

; Passes right has been held, up to 6
RightHeldCount:
  DEFB $00

; The AUTO countdown: passes left, 0 when off
;
; Set at the round start ($D251) and to $FF when the player reaches the barrier
; ($E4DE); counted down by $E68C (docs/05-controls.md 5.4).
AutoCountdown:
  DEFB $00
