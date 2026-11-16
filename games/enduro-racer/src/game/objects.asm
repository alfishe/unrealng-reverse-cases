; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The roadside objects, the riders, the splash and the dust
;
; Each pass the track is walked a second time from the bike's place for the drawing (RaceLoop's object walk, $A70F):
; every element ahead within the visible rows is drawn by DrawObject with its type's descriptor list (ObjectTypes),
; the list entry picked by the row (the farther, the smaller sprite). Type 0 is a ramp: its rows go to JumpRows for
; the riders. The near elements are tested against the bike (CollisionSizes).
;
; Six riders (Riders) run their own race: MoveRiders gives each a speed toward its top speed, moves it against the
; bike's ScrollStep, leans its pose in bends and makes it jump at the ramps; DrawRiders draws those on the visible
; rows with RiderSprites, mirrored by the bend's side unless the sprite is symmetric. Riders 4 and 5 are the trucks
; (flags bit 0, pose 4): rider 4 in the race from stage 2, rider 5 from stage 4; both in a demo; flags bit 7 out
; (StartRace).
; --------------------------------------------------------------------------------------------------------------------

  ORG $9111

; The six riders' starts: x, acceleration, top speed, the lowest pose in a bend
; (the sixth's last two bytes are BikePoses' first)
;
; StartRace copies 4 bytes a rider; the sixth reads $9127-$9128 (6, $3A),
; shared with BikePoses' first entry.
RiderStarts:
  INCBIN "res/tables/riderstarts.bin",$0000,22

  ORG $917E

; Seven distance bands: the row threshold, then five poses' descriptors (rows |
; bit 7: never mirrored, width | bit 7 aligned, address)
;
; src/res/tables/riders.csv; the sprites in src/res/sprites/.
RiderSprites:
  INCBIN "res/tables/riders.bin",$0000,147

  ORG $9615

; Draw each rider on a visible row: x from its lateral place, the row's centre
; (the bend) and the row's scale; sprite by distance and pose
;
; RiderSprites' row is the first whose threshold is above the rider's row; the
; pose (4 for the second kind) picks the descriptor (rows, width, address; bit
; 7 of the width: byte-aligned, of the rows: never mirrored; without it the
; sprite is mirrored (DrawMirrored) when BendDir is 1). TopClip is raised to
; the sprite's top. DrawSprite or DrawShifted (DrawMirrored first when needed).
;
; Recorded: c1, stages, twoplayer: riders on screen.
;
; Witness: L1 5195 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawRiders:
  LD IY,Riders
  LD B,$06
l_961B:
  PUSH BC
  BIT 7,(IY+$00)
  JP NZ,l_9701
  LD A,(IY+$04)
  CP $50
  JP NC,l_9701
  LD C,A
  OR $80
  LD L,A
  LD H,$5B
  LD A,(HL)
  LD E,A
  INC A
  JP Z,l_9701
  LD A,(BendDir)
  RRCA
  LD A,(IY+$02)
  JR NC,l_9642
  NEG
l_9642:
  ADD A,$00
  LD C,$82
  BIT 7,A
  JR Z,l_964E
  LD C,$92
  NEG
l_964E:
  LD D,A
  LD A,C
  LD (l_964E+$0008),A
  LD C,$00
  LD A,E
  SUB D
  JR NC,l_9661
  BIT 7,A
  JP Z,l_9701
  NEG
  INC C
l_9661:
  LD H,$7F
  RES 7,L
  LD B,(HL)
  LD L,B
  CALL Multiply
  EX DE,HL
  LD A,H
  AND $E0
  JP NZ,l_9701
  ADD HL,HL
  ADD HL,HL
  LD L,B
  LD B,H
  LD A,(IY+$0C)
  CALL Multiply
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  LD A,B
  DEC C
  JR NZ,l_9684
  NEG
l_9684:
  ADD A,$80
  LD B,A
  LD C,H
  LD H,$5C
  LD A,(IY+$04)
  LD L,A
  LD L,(HL)
  LD H,B
  LD IX,RiderSprites
  LD DE,$0015
l_9697:
  CP (IX+$00)
  JR C,l_96A0
  ADD IX,DE
  JR l_9697
l_96A0:
  LD A,(IY+$09)
  BIT 0,(IY+$00)
  JR Z,l_96AB
  LD A,$04
l_96AB:
  ADD A,A
  ADD A,A
  LD E,A
  ADD IX,DE
  LD B,(IX+$01)
  RES 7,B
  LD A,L
  SUB B
  SUB C
  JR C,l_96BE
  CP $28
  JR NC,l_96C0
l_96BE:
  LD A,$28
l_96C0:
  LD L,A
  LD A,(TopClip)
  CP L
  JR C,l_96CB
  LD A,L
  LD (TopClip),A
l_96CB:
  LD A,(IX+$02)
  ADD A,A
  ADD A,A
  NEG
  ADD A,H
  CCF
  LD H,A
  EX AF,AF'
  LD E,(IX+$03)
  LD D,(IX+$04)
  BIT 7,(IX+$01)
  JR NZ,l_96EF
  LD A,(BendDir)
  RRCA
  JR NC,l_96EF
  PUSH HL
  PUSH BC
  CALL DrawMirrored
  POP BC
  POP HL
l_96EF:
  EX AF,AF'
  LD A,(IX+$02)
  BIT 7,A
  RES 7,A
  JR Z,l_96FE
  CALL DrawSprite
  JR l_9701
l_96FE:
  CALL DrawShifted
l_9701:
  POP BC                  ; next rider
  LD DE,$000F
  ADD IY,DE
  DEC B
  JP NZ,l_961B
  RET

  ORG $975B

; The eight object types' descriptor lists (type * 2 indexes it)
;
; Each list: the farthest row drawn, the row below which the sprite is
; byte-aligned (DrawSprite), then 6-byte entries: the row threshold, the y
; offset, rows, width, the address. src/res/tables/objects.csv;
; src/res/sprites/ draws each.
ObjectTypes:
  DEFW ObjectList0,ObjectList1,ObjectList2,ObjectList3,ObjectList4,ObjectList5,ObjectList6,ObjectList7

; Type 4's list
;
; The lists follow each other ($976B type 4, $9791 type 5, $97C9 type 1, $97F5
; type 6, $9821 type 2, $9859 type 0, $988B type 3, $98BD type 7).
ObjectList4:
  INCBIN "res/tables/objects.bin",$0000,38
ObjectList5:
  INCBIN "res/tables/objects.bin",$0026,56
ObjectList1:
  INCBIN "res/tables/objects.bin",$005E,44
ObjectList6:
  INCBIN "res/tables/objects.bin",$008A,44
ObjectList2:
  INCBIN "res/tables/objects.bin",$00B6,56
ObjectList0:
  INCBIN "res/tables/objects.bin",$00EE,50
ObjectList3:
  INCBIN "res/tables/objects.bin",$0120,50
ObjectList7:
  INCBIN "res/tables/objects.bin",$0152,50

  ORG $9F18

; Draw the object on row A with descriptor list IX at lateral B: the list's
; entry for the row, x from the row's centre (the bend) and the scale
;
; RET when the row is beyond the list's farthest. Entries scanned until the
; row's threshold; the screen line is RoadLines[row] (the LD A at $9F80); x =
; the row's centre (BendRows) +/- B scaled (RowScale); the part above line 40
; is cut off; TopClip raised. JP (IY): DrawSprite (byte-aligned) for rows below
; the list's aligned row, the near ones; DrawShifted beyond.
;
; Recorded: c1: every pass.
;
; Witness: L1 78179 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawObject:
  CP (IX+$00)
  RET NC
  LD IY,DrawShifted
  CP (IX+$01)
  JR NC,l_9F29
  LD IY,DrawSprite
l_9F29:
  INC IX
  INC IX
  LD DE,$0006
l_9F30:
  CP (IX+$00)
  JR C,l_9F39
  ADD IX,DE
  JR l_9F30
l_9F39:
  LD L,A
  LD H,$5C
  LD A,(HL)
  LD (l_9F6B+$0016),A
  SET 7,L
  LD H,$5B
  LD E,(HL)
  LD A,(BendDir)
  RRA
  LD A,B
  JR NC,l_9F4E
  NEG
l_9F4E:
  ADD A,$00
  LD C,$82
  BIT 7,A
  JR Z,l_9F5A
  LD C,$92
  NEG
l_9F5A:
  LD D,A
  LD A,C
  LD (l_9F5A+$0008),A
  LD C,$00
  LD A,E
  SUB D
  JR NC,l_9F6B
  BIT 7,A
  RET Z
  NEG
  INC C
l_9F6B:
  LD H,$7F
  RES 7,L
  LD L,(HL)
  CALL Multiply
  EX DE,HL
  LD A,H
  AND $E0
  RET NZ
  ADD HL,HL
  ADD HL,HL
  LD E,(IX+$04)
  LD D,(IX+$05)
  LD A,$00
  LD B,(IX+$02)
  SUB B
  JP Z,$0000              ; JP Z,$0000: a sprite whose y offset equals its line
                          ; would reset the machine; never taken (lines are $70
                          ; and below the offsets)
  LD L,A
  SUB $28
  JR NC,l_9FA3
  LD L,$28
  PUSH HL
  NEG
  LD H,A
  LD A,B
  SUB H
  LD B,A
  XOR A
  LD L,(IX+$03)
l_9F9B:
  ADD A,L
  DEC H
  JR NZ,l_9F9B
  LD L,A
  ADD HL,DE
  EX DE,HL
  POP HL
l_9FA3:
  LD A,(TopClip)
  CP L
  JR C,l_9FAD
  LD A,L
  LD (TopClip),A
l_9FAD:
  LD A,H
  DEC C
  JR NZ,l_9FB3
  NEG
l_9FB3:
  ADD A,$80
  SUB (IX+$01)
  LD H,A
  LD A,(IX+$03)
  JP (IY)

  ORG $A09A

; Stages 2 and 4 (SplashOn): the splash under the bike, two frames alternating
; ($DED3 20 x 5, $DF37 15 x 3)
;
; Recorded: stages and reset3 (stage 2).
;
; Witness: L1 586 (stages).
DrawSplash:
  LD DE,Sprites+$2BCD
  LD BC,$1405
  LD A,(PassCount)
  RRA
  JR NC,l_A0BF
  LD DE,Sprites+$2C31
  LD BC,$0F03
  JR l_A0BF

; SkidLevel: the dust beside the bike, two frames ($DF64 12 x 4, $DF94 14 x 4)
;
; Witness: L1 448 (stages, truck).
DrawDust:
  LD DE,Sprites+$2C5E
  LD BC,$0C04
  LD A,(PassCount)
  RRA
  JR NC,l_A0BF
  LD DE,Sprites+$2C8E
  LD B,$0E
; This entry point is used by the routine at DrawSplash.
l_A0BF:
  LD A,(JumpHeight+$0001) ; not in the air or stopped; x from the pose's offset
                          ; (DustOffsets)
  AND A
  RET NZ
  LD A,(Speed+$0001)
  AND A
  RET Z
  LD A,(Pose)
  CP $03
  JR C,l_A0D5
  LD A,(Lean)
  ADD A,$06
l_A0D5:
  LD HL,DustOffsets
  ADD A,L
  LD L,A
  JR NC,DustPlace

; INC H: DustOffsets crossing a page (not met: $A0F3 + at most 9 stays in the
; page)
;
; Known only from the code. DrawDust and DrawSplash run on from $A0DD
; (DustPlace).
;
; Known only from the code.
DustCarry:
  INC H
; This entry point is used by the routine at DrawDust.
DustPlace:
  LD H,(HL)               ; the offset
  LD A,C
  ADD A,A
  ADD A,A
  LD L,A
  LD A,(BikeX)
  ADD A,H
  SUB L
  LD H,A
  EX AF,AF'
  LD A,(RoadLines)
  SUB B
  LD L,A
  EX AF,AF'
  LD A,C
  JP DrawShifted

; The splash's and dust's x offset per pose and lean (10 bytes, signed)
DustOffsets:
  INCBIN "res/tables/dust.bin",$0000,10

; Stage 3: the rows between the two gap marks become $FE in RowList (not
; drawn); the bike over them sets InGap
;
; GapMarks are the rows of the track's two $F0 commands seen this pass ($7F
; none). InGap ($7C3A) is read by OffRoadSand: the bike slowed hard and the
; skid noise.
;
; Recorded: stages, reset3: stage 3.
;
; Witness: L1 4740 (c1, crash, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
GapRows:
  LD A,(Stage)
  CP $02
  RET NZ
  LD BC,(GapMarks)
  LD A,C
  RLA
  JR NC,l_A110
  XOR A
  LD (InGap),A
  RET
l_A110:
  LD A,(ScrollStep+$0001)
  INC A
  CP C
  JR C,l_A11A
  LD (InGap),A
l_A11A:
  LD H,$5C
  LD L,B
  LD E,(HL)
  LD L,C
  LD A,(HL)
  SUB E
  RET Z
  LD B,A
  LD L,E
  LD H,$00
  LD DE,$5A90
  LD A,(RoadTopRow)
  NEG
  ADD A,E
  LD E,A
  LD A,$FE
  ADD HL,DE
l_A133:
  LD (HL),A
  INC HL
  DJNZ l_A133
  INC C
  DEC C
  RET NZ
  INC A
l_A13B:
  CP (HL)
  RET Z
  LD (HL),$FE
  INC HL
  JR l_A13B

; A lone RET after GapRows' loop, which no branch reaches
;
; Known only from the code.
GapRowsRet:
  RET

  ORG $A21A

; Each rider in the race: jump (height, speed - $02F0), start a jump at a ramp
; row, speed toward its top, distance - ScrollStep, pose in bends
;
; Recorded: c1: from the countdown's end; stages: jumps at stage 3's ramps.
;
; Witness: L1 5097 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
MoveRiders:
  LD B,$06
  LD DE,$000F

; The $DD prefix of LD IX,$5C80 (run once); the loop re-enters at $A220, where
; the same bytes read LD HL,$5C80
;
; L1 has $A21F executed in every recording; the kit keeps it as a byte because
; two instructions share $A220.
MoveRidersIx:
  DEFB $DD

; One rider (IX; HL's load is harmless in the other register set)
;
; Witness: L1 25485 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
MoveRidersLoop:
  LD HL,Riders
  EXX
  BIT 7,(IX+$00)
  JP NZ,l_A2F9
  LD A,(IX+$0C)
  AND A
  JR Z,l_A259
  LD H,A
  LD L,(IX+$0B)
  LD E,(IX+$0D)
  LD D,(IX+$0E)
  ADD HL,DE
  LD A,H
  CP $F0
  JR C,l_A247
  LD (IX+$09),$03
  LD H,$00
l_A247:
  LD (IX+$0B),L
  LD (IX+$0C),H
  LD HL,-$02F0            ; the gravity, as the bike's
  ADD HL,DE
  LD (IX+$0D),L
  LD (IX+$0E),H
  JR l_A294
l_A259:
  LD A,(IX+$04)
  CP $50
  JR NC,l_A294
  LD D,A
  LD HL,JumpRows
  LD B,$04
l_A266:
  LD A,(HL)
  INC HL
  CP $50
  JR NC,l_A294
  CP D
  JR NC,l_A273
  DJNZ l_A266

; No ramp row ahead of the rider: on to the speed
;
; Known only from the code: JumpRows always held an end mark within four.
RiderNoRamp:
  JR l_A294
; This entry point is used by the routine at MoveRidersLoop.
l_A273:
  LD L,(IX+$05)           ; the ramp's distance
  LD H,(IX+$06)
  LD E,(IX+$03)
  ADD HL,DE
  CP H
  JR NC,l_A294
  LD A,$0C
  BIT 0,(IX+$00)
  JR Z,l_A28A
  LD A,$09
l_A28A:
  LD (IX+$0E),A
  LD (IX+$0C),A
  LD (IX+$09),$00
; This entry point is used by the routine at MoveRidersLoop.
l_A294:
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD C,(IX+$07)
  LD B,$00
  ADD HL,BC
  LD A,H
  CP (IX+$08)
  JR C,l_A2AB
  LD H,(IX+$08)
  LD L,$00
l_A2AB:
  LD (IX+$05),L
  LD (IX+$06),H
  LD E,(IX+$03)
  LD D,(IX+$04)
  ADD HL,DE
  LD DE,(ScrollStep)
  SBC HL,DE
  LD (IX+$03),L
  LD (IX+$04),H
  LD A,(IX+$0C)
  AND A
  JR NZ,l_A2DF
  LD A,(SegmentLeft+$0001)
  LD C,A
  LD A,H
  CP $80
  JR NC,l_A2F9
  CP C
  LD A,(BendPrev)
  JR C,l_A2DC
  LD A,(Bend)
l_A2DC:
  AND A
  JR NZ,l_A2EE
l_A2DF:
  LD A,(IX+$09)
  AND A
  JR Z,l_A2F9
  CP $03
  JR NC,l_A2F9
  INC (IX+$09)
  JR l_A2F9
l_A2EE:
  LD A,(IX+$0A)
  CP (IX+$09)
  JR NC,l_A2F9
  DEC (IX+$09)
; This entry point is used by the routine at MoveRidersLoop.
l_A2F9:
  EXX
  ADD IX,DE
  DEC B
  JP NZ,MoveRidersLoop
  RET
