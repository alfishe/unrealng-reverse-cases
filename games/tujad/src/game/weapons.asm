; --------------------------------------------------------------------------------------------------------------------
; weapons.asm: The shot of each weapon, and firing
;
; One shot is in flight at a time (Shot: 0 none; bit 0 going left, bit 4 exploding, bit 5 the first pass, bit 6 a shot
; in flight, bit 7 hit). Weapon 0 is a dash that kills by collision only (the interrupt's XOR sets bit 7 of Shot, its
; flag byte); weapons 1-3 mark the cells they cross (ShotMark $40, $20, $10 with bit 0) and an object whose kill mark
; is that weapon's dies (MoveObject $809D). Weapons 1-3 cost one unit of ammunition a shot.
; --------------------------------------------------------------------------------------------------------------------

; Move the shot of the weapon in use
;
; By Weapons: bit 7 MoveShot0 $877E; bits 6 and 5 MoveShotStraight $84CC; bit 4
; (weapon 3) the probe here. MainLoop calls it twice a pass (L1 37 157). Weapon
; 3's shot (graphic Weapon3Graphics $AF85, 3 bytes x 2 rows, attribute $46,
; mark $10): erased and its mark XORed out, then while fire is held it is
; steered by the directions (MoveShot3Steer, CellSolidColumn / CellSolidRow: no
; RZX build steered one; the probe-shield recording steered it 71 times, doc
; 5.8), else it explodes over four passes (Weapon3Frames) and marks the cells
; of an object under it with $11.
MoveShot:
  LD HL,Weapons
  BIT 7,(HL)
  JP NZ,MoveShot0
  BIT 6,(HL)
  JP NZ,MoveShotStraight
  BIT 5,(HL)
  JP NZ,MoveShotStraight
MoveShot3:
  LD HL,Shot
  XOR A
  CP (HL)
  RET Z
  BIT 5,(HL)
  JP NZ,MoveShot3Draw
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$03
  INC HL
  LD (HL),$02
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $60
  LD H,A
  LD L,E
  LD A,B
  AND $07
  LD B,$02
  JR Z,MoveShot3Cols
  INC B
MoveShot3Cols:
  LD A,C
  AND $07
  LD C,$02
  JR Z,MoveShot3Erase
  INC C
MoveShot3Erase:
  LD A,$10
  CALL XorCells
  POP HL
  BIT 4,(HL)
  JP NZ,MoveShot3Exploding
  BIT 7,(HL)
  JP NZ,MoveShot3Hit
MoveShot3Steer:
  LD A,(Controls)
  AND $1F
  BIT 4,A
  JP Z,MoveShot3Explode
  INC HL
  BIT 0,A
  JR Z,MoveShot3SteerLeft
  PUSH AF
  LD A,(HL)
  AND $07
  JR NZ,MoveShot3SteerRight
  LD A,$F0
  CP (HL)
  JR Z,MoveShot3SteerRightDone
  PUSH HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  INC L
  INC L
  LD A,$02
  CALL CellSolidColumn
  CP $01
  POP HL
  JR Z,MoveShot3SteerRightDone
MoveShot3SteerRight:
  INC (HL)
  INC (HL)
MoveShot3SteerRightDone:
  POP AF
MoveShot3SteerLeft:
  BIT 1,A
  JR Z,MoveShot3SteerDown
  PUSH AF
  LD A,(HL)
  AND $07
  JR NZ,MoveShot3SteerLeftStep
  XOR A
  CP (HL)
  JR Z,MoveShot3SteerLeftDone
  PUSH HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  DEC L
  LD A,$02
  CALL CellSolidColumn
  CP $01
  POP HL
  JR Z,MoveShot3SteerLeftDone
MoveShot3SteerLeftStep:
  DEC (HL)
  DEC (HL)
MoveShot3SteerLeftDone:
  POP AF
MoveShot3SteerDown:
  BIT 2,A
  INC HL
  JR Z,MoveShot3SteerUp
  PUSH AF
  LD A,(HL)
  AND $07
  JR NZ,MoveShot3SteerDownStep
  LD A,$B0
  CP (HL)
  JR Z,MoveShot3SteerDownDone
  PUSH HL
  LD B,(HL)
  DEC HL
  LD C,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  LD BC,$0040
  ADD HL,BC
  LD A,$02
  CALL CellSolidRow
  CP $01
  POP HL
  JR Z,MoveShot3SteerDownDone
MoveShot3SteerDownStep:
  INC (HL)
  INC (HL)
MoveShot3SteerDownDone:
  POP AF
MoveShot3SteerUp:
  BIT 3,A
  JR Z,MoveShot3SteerDone
  PUSH AF
  LD A,(HL)
  AND $07
  JR NZ,MoveShot3SteerUpStep
  LD A,$30
  CP (HL)
  JR Z,MoveShot3SteerUpDone
  PUSH HL
  LD B,(HL)
  DEC HL
  LD C,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  LD BC,$0020
  SCF
  CCF
  SBC HL,BC
  LD A,$02
  CALL CellSolidRow
  CP $01
  POP HL
  JR Z,MoveShot3SteerUpDone
MoveShot3SteerUpStep:
  DEC (HL)
  DEC (HL)
MoveShot3SteerUpDone:
  POP AF
MoveShot3SteerDone:
  DEC HL
  DEC HL
MoveShot3Draw:
  RES 5,(HL)
  PUSH HL
  PUSH HL
  BIT 3,(HL)
  JR NZ,MoveShot3FrameDown
  INC (HL)
  LD A,(HL)
  AND $03
  CP $03
  JR NZ,MoveShot3Frame
  SET 3,(HL)
  JR MoveShot3Frame
MoveShot3FrameDown:
  DEC (HL)
  LD A,(HL)
  AND $03
  CP $00
  JR NZ,MoveShot3Frame
  RES 3,(HL)
MoveShot3Frame:
  LD HL,ProbeGraphics
  OR A
  JR Z,MoveShot3Shift
  LD DE,$0031
MoveShot3FrameLoop:
  ADD HL,DE
  DEC A
  JR NZ,MoveShot3FrameLoop
MoveShot3Shift:
  POP DE
  PUSH DE
  INC DE
  LD A,(DE)
  AND $07
  CALL ShiftGraphic3
  INC HL
  EX DE,HL
  POP HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$03
  INC HL
  LD (HL),$02
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD A,B
  AND $07
  LD B,$02
  JR Z,MoveShot3AttrCols
  INC B
MoveShot3AttrCols:
  LD A,C
  AND $07
  LD C,$02
  JR Z,MoveShot3Attr
  INC C
MoveShot3Attr:
  LD A,$46
  PUSH BC
  PUSH HL
  CALL FillAttr
  POP HL
  POP BC
  LD A,H
  AND $03
  OR $60
  LD H,A
  LD A,$10
  CALL XorCells
  RET
MoveShot3Hit:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  CALL CellAddrXY
  LD A,B
  AND $07
  LD B,$02
  JR Z,MoveShot3HitCols
  INC B
MoveShot3HitCols:
  LD A,C
  AND $07
  LD C,$02
  JR Z,MoveShot3HitRows
  INC C
MoveShot3HitRows:
  LD DE,$0020
MoveShot3HitRow:
  PUSH BC
  PUSH HL
  LD B,C
MoveShot3HitCell:
  LD A,(HL)
  BIT 2,A
  JR Z,MoveShot3HitNext
  OR $11
  LD (HL),A
  POP HL
  POP HL
  POP HL
  JR MoveShot3Explode
MoveShot3HitNext:
  INC L
  DJNZ MoveShot3HitCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ MoveShot3HitRow
  POP HL
MoveShot3Explode:
  LD A,$50
  JR MoveShot3ExplodeStep
MoveShot3Exploding:
  LD A,(HL)
  INC A
MoveShot3ExplodeStep:
  LD (HL),A
  AND $07
  CP $04
  JR NZ,MoveShot3ExplodeFrame
  LD (HL),$00
  LD DE,BlankGraphic
  LD A,(KeyLatches)
  RES 7,A
  SET 6,A
  LD (KeyLatches),A
  JR MoveShot3ExplodeDraw
MoveShot3ExplodeFrame:
  SLA A
  PUSH HL
  LD HL,Weapon3Frames
  LD D,$00
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  INC HL
  LD A,(HL)
  AND $07
  EX DE,HL
  CALL ShiftGraphic3
  INC HL
  EX DE,HL
  DEC HL
MoveShot3ExplodeDraw:
  INC HL
  INC HL
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  LD BC,$0007
  SCF
  CCF
  SBC HL,BC
  LD DE,(SpriteListEnd)
  INC DE
  INC DE
  LD BC,$0006
  LDIR
  LD (SpriteListEnd),DE
  RET

; Weapons 1 and 2: a 2 x 1 bolt 4 pixels a call (8 a pass: MoveShot runs twice)
; to a wall or the edge
;
; The old image erased and its ShotMark XORed out; x - 4 or + 4 (to 0 or $F8);
; a wall or item cell under the new place ends it (KeyLatches bit 6 set: fire
; must be released); an object under it (cell bit 2) gets the mark ORed in with
; bit 0 and the shot ends; else the next frame (graphic +/- 16) is drawn with
; ShotScratch's attribute and the mark XORed in. L1 4 647 calls, 55 with a
; shot.
MoveShotStraight:
  LD HL,Shot
  XOR A
  CP (HL)
  RET Z
  BIT 5,(HL)
  JP NZ,MoveShotStraightDraw
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$02
  INC HL
  LD (HL),$01
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $60
  LD H,A
  LD L,E
  LD A,B
  AND $07
  LD B,$01
  JR Z,MoveShotStraightCols
  INC B
MoveShotStraightCols:
  LD A,C
  AND $07
  LD C,$01
  JR Z,MoveShotStraightErase
  INC C
MoveShotStraightErase:
  LD A,(ShotMark)
  CALL XorCells
  POP HL
  LD A,(HL)
  BIT 7,A
  JR NZ,MoveShotStraightHit
  PUSH HL
  INC HL
  BIT 0,A
  JR Z,MoveShotStraightRight
  DEC (HL)
  DEC (HL)
  DEC (HL)
  DEC (HL)
  XOR A
  JR MoveShotStraightEdge
MoveShotStraightRight:
  INC (HL)
  INC (HL)
  INC (HL)
  INC (HL)
  LD A,$F8
MoveShotStraightEdge:
  CP (HL)
  JR Z,MoveShotStraightEnd1
  LD C,(HL)
  INC HL
  LD B,(HL)
  CALL CellAddrXY
  LD A,B
  AND $07
  LD B,$01
  JR Z,MoveShotStraightTestCols
  INC B
MoveShotStraightTestCols:
  LD A,C
  AND $07
  LD C,$01
  JR Z,MoveShotStraightTestRow
  INC C
MoveShotStraightTestRow:
  LD DE,$0020
  PUSH BC
  PUSH HL
  LD B,C
MoveShotStraightTestCell:
  LD A,(HL)
  CP $01
  JR Z,MoveShotStraightWall
  BIT 7,A
  JR NZ,MoveShotStraightWall
  INC L
  DJNZ MoveShotStraightTestCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ MoveShotStraightTestRow
  JR MoveShotStraightOn
MoveShotStraightWall:
  POP BC
MoveShotStraightEnd2:
  POP BC
MoveShotStraightEnd1:
  POP BC
MoveShotStraightEnd:
  XOR A
  LD (Shot),A
  LD HL,KeyLatches
  SET 6,(HL)
  RET
MoveShotStraightHit:
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  CALL CellAddrXY
  LD A,B
  AND $07
  LD B,$01
  JR Z,MoveShotStraightHitCols
  INC B
MoveShotStraightHitCols:
  LD A,C
  AND $07
  LD C,$01
  JR Z,MoveShotStraightHitRows
  INC C
MoveShotStraightHitRows:
  LD DE,$0020
MoveShotStraightHitRow:
  PUSH BC
  PUSH HL
  LD B,C
MoveShotStraightHitCell:
  LD A,(HL)
  BIT 2,A
  JR Z,MoveShotStraightHitNext
  OR $01
  LD (HL),A
  LD A,(ShotMark)
  OR (HL)
  LD (HL),A
  JR MoveShotStraightEnd2
MoveShotStraightHitNext:
  INC L
  DJNZ MoveShotStraightHitCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ MoveShotStraightHitRow
  JR MoveShotStraightEnd
MoveShotStraightOn:
  POP HL
MoveShotStraightDraw:
  PUSH HL
  RES 5,(HL)
  INC HL
  PUSH HL
  LD A,(HL)
  BIT 2,A
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD DE,$0010
  JR NZ,MoveShotStraightFrameUp
  SCF
  CCF
  SBC HL,DE
  JR MoveShotStraightFrame
MoveShotStraightFrameUp:
  ADD HL,DE
MoveShotStraightFrame:
  EX DE,HL
  POP HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$02
  INC HL
  LD (HL),$01
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD A,B
  AND $07
  LD B,$01
  JR Z,MoveShotStraightAttrCols
  INC B
MoveShotStraightAttrCols:
  LD A,C
  AND $07
  LD C,$01
  JR Z,MoveShotStraightAttr
  INC C
MoveShotStraightAttr:
  LD A,(ShotScratch)
  PUSH HL
  PUSH BC
  CALL FillAttr
  POP BC
  POP HL
  LD A,H
  AND $03
  OR $60
  LD H,A
  LD A,(ShotMark)
  CALL XorCells
  RET

; Fire the weapon in use: a new shot beside the droid
;
; Not while a shot is new (Shot bit 6) or fire has not been released
; (KeyLatches bit 6). Shot = $60; x = the droid's column + 3 (right) or - 2
; (left, bit 0), not past column $1B / 2; y = the droid's y + 16. Weapon 0: the
; dash at ShotGraphic0 (FireBasic); weapon 1: $8824, attribute $43, mark $40;
; weapon 2: $8844, $44, $20; weapon 3: $AF85 on 2 x 2 cells, $46... each
; refused on a wall cell and when its Ammo is 0, which then goes down one (BCD)
; and is printed. L1 1 844 calls, 779 shots fired.
Fire:
  LD HL,Shot
  BIT 6,(HL)
  RET NZ
  LD HL,KeyLatches
  BIT 6,(HL)
  RET NZ
  LD HL,Shot
  LD (HL),$60
  LD BC,(DroidVars)
  LD A,(DroidFlags)
  BIT 0,A
  JR NZ,FireLeft
  LD A,C
  CP $1B
  JP NC,FireRefused
  ADD A,$03
  LD C,A
  JR FireWeapon
FireLeft:
  LD A,C
  CP $02
  JP C,FireRefused
  SET 0,(HL)
FireWeapon:
  LD A,B
  ADD A,$10
  LD B,A
  LD A,(Shot)
  LD HL,Weapons
  BIT 7,(HL)
  JP NZ,FireBasic
  BIT 6,(HL)
  JR NZ,FireWeapon1
  BIT 5,(HL)
  JP NZ,FireWeapon2
  BIT 0,A
  JR Z,FireWeapon3
  DEC C
  DEC C
FireWeapon3:
  SLA C
  SLA C
  SLA C
  LD (ShotPos),BC
  LD DE,ProbeGraphics
  LD (ShotGraphic),DE
  CALL CellAddrXY
  LD A,B
  AND $07
  LD B,$02
  JR Z,FireWeapon3Cols
  INC B
FireWeapon3Cols:
  LD A,C
  AND $07
  LD C,$02
  JR Z,FireWeapon3Rows
  INC C
FireWeapon3Rows:
  LD DE,$0020
FireWeapon3Row:
  PUSH BC
  PUSH HL
  LD B,C
FireWeapon3Cell:
  LD A,(HL)
  CP $01
  JP Z,FireRefusedPop
  INC L
  DJNZ FireWeapon3Cell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ FireWeapon3Row
  LD A,(Ammo+$0002)
  CP $00
  JP Z,FireRefused
  SUB $01
  DAA
  LD (Ammo+$0002),A
  LD HL,Screen+130
  CALL PrintBcd
  LD HL,KeyLatches
  SET 7,(HL)
  RET
FireWeapon1:
  BIT 0,A
  JR Z,FireWeapon1Pos
  DEC C
FireWeapon1Pos:
  SLA C
  SLA C
  SLA C
  LD (ShotPos),BC
  LD DE,Weapon1Bolt
  LD (ShotGraphic),DE
  CALL CellAddrXY
  LD A,(HL)
  CP $01
  JP Z,FireRefused
  LD A,B
  AND $07
  JR Z,FireWeapon1Ammo
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,FireWeapon1Below
  INC H
FireWeapon1Below:
  LD A,(HL)
  CP $01
  JP Z,FireRefused
FireWeapon1Ammo:
  LD A,(Ammo)
  CP $00
  JP Z,FireRefused
  SUB $01
  DAA
  LD (Ammo),A
  LD HL,Screen+130
  CALL PrintBcd
  LD A,$43
  LD (ShotScratch),A
  LD A,$40
  LD (ShotMark),A
  RET
FireWeapon2:
  BIT 0,A
  JR Z,FireWeapon2Pos
  DEC C
FireWeapon2Pos:
  SLA C
  SLA C
  SLA C
  LD (ShotPos),BC
  LD DE,Weapon2Bolt
  LD (ShotGraphic),DE
  CALL CellAddrXY
  LD A,(HL)
  CP $01
  JR Z,FireRefused
  LD A,B
  AND $07
  JR Z,FireWeapon2Ammo
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,FireWeapon2Below
  INC H
FireWeapon2Below:
  LD A,(HL)
  CP $01
  JR Z,FireRefused
FireWeapon2Ammo:
  LD A,(Ammo+$0001)
  CP $00
  JR Z,FireRefused
  SUB $01
  DAA
  LD (Ammo+$0001),A
  LD HL,Screen+130
  CALL PrintBcd
  LD A,$44
  LD (ShotScratch),A
  LD A,$20
  LD (ShotMark),A
  RET
FireBasic:
  BIT 0,A
  JR Z,FireBasicPos
  DEC C
FireBasicPos:
  SLA C
  SLA C
  SLA C
  LD (ShotPos),BC
  LD DE,ShotGraphic0
  LD (ShotGraphic),DE
  CALL CellAddrXY
  LD A,(HL)
  CP $01
  RET NZ
FireRefused:
  XOR A
  LD (Shot),A
  RET
FireRefusedPop:
  POP BC
  POP BC
  JR FireRefused

; Weapon 0: the dash 8 pixels a call (16 a pass) until it hits ink, a wall or
; the edge
;
; The old image erased; when the interrupt found ink under it (Shot bit 7) it
; ends; else x - 8 or + 8 (to 0 or $F8), and a wall or item cell ends it. A new
; dash (bit 5) is only drawn. Attribute $47. L1 32 027 calls, 5 855 moves.
MoveShot0:
  LD HL,Shot
  XOR A
  CP (HL)
  RET Z
  BIT 5,(HL)
  JR NZ,MoveShot0Draw
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$01
  INC HL
  LD (HL),$01
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  POP HL
  LD A,(HL)
  BIT 7,A
  JR NZ,MoveShot0End
  PUSH HL
  INC HL
  BIT 0,A
  JR Z,MoveShot0Right
  LD A,(HL)
  SUB $08
  LD (HL),A
  LD A,$F8
  JR MoveShot0Edge
MoveShot0Right:
  LD A,(HL)
  ADD A,$08
  LD (HL),A
  XOR A
MoveShot0Edge:
  CP (HL)
  JR Z,MoveShot0EndPop
  LD C,(HL)
  INC HL
  LD B,(HL)
  CALL CellAddrXY
  LD A,(HL)
  CP $01
  JR Z,MoveShot0EndPop
  BIT 7,A
  JR Z,MoveShot0On
MoveShot0EndPop:
  POP BC
MoveShot0End:
  XOR A
  LD (Shot),A
  RET
MoveShot0On:
  POP HL
MoveShot0Draw:
  PUSH HL
  RES 5,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$01
  INC HL
  LD (HL),$01
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD D,A
  LD A,$47
  LD (DE),A
  RET

; The bolt graphics of weapons 1 and 2: 2 x 8, two frames each
;
; Fire $86CA / $870B start the shot at $8824 (weapon 1) or $8844 (weapon 2);
; MoveShotStraight steps the graphic 16 bytes up or down a pass by its
; direction, so $8814 and $8834 are the frames the shot alternates with.
ShotGraphics:
  INCBIN "res/sprites/ShotGraphics.bin",$0000,16
Weapon1Bolt:
  INCBIN "res/sprites/ShotGraphics.bin",$0010,16
Weapon2BoltAlt:
  INCBIN "res/sprites/ShotGraphics.bin",$0020,16
Weapon2Bolt:
  INCBIN "res/sprites/ShotGraphics.bin",$0030,16
