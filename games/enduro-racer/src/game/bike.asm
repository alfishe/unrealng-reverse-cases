; --------------------------------------------------------------------------------------------------------------------
; bike.asm: The bike: the controls, the lean and the steering, wheelies, jumps, falls and getting up, the collisions, off the road
;
; SPEED ($7C33-$7C34, 8.8 km/h) rises with THROTTLE (fast at low speed, then by a fixed $220, slower from 160 toward
; 200: $C800, never reached, 199 the top) and falls with BRAKES ($580 a pass); RaceLoop applies them. ScrollStep =
; SPEED * 14 moves the track. The lean (-3 to 3) follows LEFT and RIGHT one step a pass and returns toward 0 every
; second pass without them; the sideways speed is SteerTable[speed] * LeanTable[lean] / 8 (its high byte capped at 5,
; the low byte kept), added to the lateral position LateralX with the bend's push (BikeLateral). WHEELIE held lifts
; the front (pose 0) and counts passes (Wheelies); at a ramp the speed is kept in proportion to the wheelie (8 passes:
; all of it; none: 3/4) and the jump's height comes from the ramp's place and the speed. Hitting an object or a truck
; at 35 km/h or more is a fall (Crash): the bike flies (JumpSpeed from the speed), lies for FallTime, the turn ends
; (the turn loop: the other player's turn, or a restart of this one at the fall's x); slower, and side-on hits, are a
; bounce (BounceTime: 3 passes of random steering). Off the road the speed is capped by the distance (OffRoad); stage
; 3's sand also makes the skid noise and dust, and its gap (the water) slows hard.
;
; Poses (Pose, $9175): 0 wheelie, 1 and 2 in the air, 3 riding (the lean picks the sprite), 7 thrown, 8 and 9 down;
; BikePoses has the sprite of each (entries 3-6 the leans, mirrored for the other side).
; --------------------------------------------------------------------------------------------------------------------

  ORG $9127

; The bike's sprites: rows, width (bit 7 aligned), address, then the wheel
; animation (count, width, offset, source; count bit 7: none)
;
; DrawBike reads BikePoses + 9 * n + 1 ... + 9 (the code's base $9127). Entries
; with no animation leave their last four bytes free, and the game keeps
; variables in them: ScrollStep, $9138, LateralX, TopClip, DrawnTop, FallTime,
; Wheelies, Pose, Lean, RoadTopRow, BikeX.
BikePoses:
  DEFB $06,$3A,$03,$ED,$DB,$0A,$01,$88,$C9
  DEFB $DE,$3C,$03,$9B,$DC,$80
ScrollStep:
  DEFB $00,$00            ; SPEED * 14: the track's distance a pass (8.8)
BendPtr:
  DEFB $00,$00,$53,$83,$F4,$DA,$80 ; ScrollBends' profile pointer
LateralX:
  DEFB $00,$00,$00,$00,$2C,$86,$EC,$D9,$0A ; the bike's sideways place, 8.8
  DEFB $02,$BB,$B5,$DE,$2E,$85,$DE,$D6,$0D ; ($9140 the whole part, $5C-$A4 on
  DEFB $02,$96,$9B,$DE,$2F,$04,$9A,$D4,$0C ; the road's scale)
  DEFB $02,$80,$82,$DE,$30,$03,$8B,$D2,$0D
  DEFB $01,$61,$75,$DE,$37,$87,$CC,$DF,$80
TopClip:
  DEFB $00                ; the highest line drawn this pass (CopyBuffer starts
                          ; there)
DrawnTop:
  DEFB $00                ; last pass's TopClip
FallTime:
  DEFB $00                ; a fall's count (bit 7: the side), 0 riding
Wheelies:
  DEFB $00,$29,$86,$4D,$E1,$80 ; passes with WHEELIE held
Pose:
  DEFB $00                ; the bike's pose
Lean:
  DEFB $00                ; the lean, -3 to 3
RoadTopRow:
  DEFB $00                ; RoadLines[127] - $71 (RowTable's first road line -
                          ; $70); $FF breaks DrawRoad (the stage 3 reset)
BikeX:
  DEFB $00,$19,$05,$43,$E2,$80 ; the bike's screen x ($80 the centre)

  ORG $9FBE

; Draw the bike: its pose's sprite (mirrored when leaning the other way), the
; wheels' animation, at BikeX, on the road or in the air
;
; Not during the countdown's first part or while getting up. Pose 3: entry Lean
; + 6 (3-6, mirrored for 7-9); others: entry Pose. The wheel patch is XORed in
; every pass above 64 km/h, every second above 32, every fourth below, never
; stopped. y: RoadLines[0] or $C0 in the air, minus JumpHeight; TopClip raised.
;
; Witness: L1 5151 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawBike:
  LD A,(Countdown)
  CP $04
  JR C,l_9FC7
  RRA
  RET NC
l_9FC7:
  LD A,(GetUp)
  AND A
  RET NZ
  LD H,A
  LD A,(Pose)
  CP $03
  JR NZ,l_9FE1
  LD A,(Lean)
  ADD A,$06
  CP $07
  JR C,l_9FE1
  CPL
  ADD A,$0D
  DEC H
l_9FE1:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD IX,BikePoses
  ADD IX,BC
  INC H
  EX AF,AF'
  BIT 7,(IX+$05)
  JR NZ,l_A048
  LD A,(Speed+$0001)
  AND A
  JR Z,l_A048
  CP $40
  JR NC,l_A00F
  LD C,$01
  CP $20
  JR NC,l_A009
  LD C,$03
l_A009:
  LD A,(PassCount)
  AND C
  JR NZ,l_A048
l_A00F:
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD E,(IX+$07)
  LD D,$00
  ADD HL,DE
  LD E,(IX+$08)
  LD D,(IX+$09)
  EXX
  LD A,(IX+$02)
  AND $7F
  LD C,(IX+$06)
  SUB C
  LD (l_A035+$000E),A
  LD D,(IX+$05)
  RES 7,D
  LD B,C
l_A034:
  EXX
l_A035:
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC HL
  INC DE
  EXX
  DJNZ l_A034
  DEC D
  JR Z,l_A048
  LD B,C
  EXX
  LD BC,$0000
  ADD HL,BC
  JR l_A035
l_A048:
  EX AF,AF'               ; mirror, then place
  LD E,(IX+$03)
  LD D,(IX+$04)
  CALL Z,DrawMirrored
  LD A,(SkidLevel)
  LD C,A
  LD A,(JumpHeight+$0001)
  LD B,A
  AND A
  LD A,$C0
  JR NZ,l_A062
  LD A,(RoadLines)
l_A062:
  SUB B
  LD B,(IX+$01)
  SUB B
  JR NC,l_A06A
  XOR A
l_A06A:
  ADD A,C
  CP $28
  JR NC,l_A071
  LD A,$28
l_A071:
  LD L,A
  LD A,B
  SUB C
  RET Z
  RET C
  LD B,A
  LD A,(TopClip)
  CP L
  JR C,l_A081
  LD A,L
  LD (TopClip),A
l_A081:
  LD C,$00
  LD A,(IX+$02)
  LD C,A
  ADD A,A
  ADD A,A
  LD H,A
  LD A,(BikeX)
  SUB H
  LD H,A
  LD A,C
  BIT 7,A
  RES 7,A
  JP NZ,DrawSprite
  JP DrawShifted

  ORG $A1C9

; A bounce's passes left (3, or 6 after a landing)
BounceTime:
  DEFB $00
BounceDir:
  DEFB $00                ; the bounce's push: 8 right, 4 left, 0 random
BikeHitX:
  DEFB $00                ; the bike's x for the collisions ($82 + LateralX *
                          ; $C0 / 256)

  ORG $A1D9

; Stages 1, 2 and 4: beyond $24 off the road's middle, SPEED capped at SPEED *
; (256 - ((d - $24) / 2 + 1)) / 256 + 1
;
; POKE: the Keep Speed Off Road POKE turns its LD ($7C34),A at $A1F1 into LD
; A,(nn) (WALKTHROUGH 6.0).
;
; Witness: L1 3917 (c1, crash, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).
OffRoad:
  JR NC,l_A1DD
  NEG
l_A1DD:
  SUB $24
  RET C
; This entry point is used by the routine at OffRoadStage5.
l_A1E0:
  SRL A
  INC A
  NEG
  LD L,A
  LD A,(Speed+$0001)
  LD B,A
  CALL Multiply
  LD A,D
  INC A
  CP B
  RET NC
  LD (Speed+$0001),A
  RET

; Stage 5: no test on one side (RET NC), else OffRoadSand
;
; Witness: L1 376 (fall5, stages).
OffRoadStage5:
  RET NC
OffRoadSand:
  JR NC,l_A1FA            ; Stage 3: the sand: SkidLevel = (d - $24) / 4 and
                          ; the cap; on the road InGap gives SkidLevel 3 and a
                          ; cap of $0C
  NEG
l_A1FA:
  SUB $24
  LD C,A
  JR C,l_A209
  SRL A
  SRL A
  LD (SkidLevel),A
  LD A,C
  JR l_A1E0
l_A209:
  LD A,(InGap)
  LD (SkidLevel),A
  AND A
  RET Z
  LD A,$03
  LD (SkidLevel),A
  LD A,$0C
  JR l_A1E0

  ORG $ACDF

; The bike each pass: a fall's count (and its end: the turn ends), getting up,
; the demo's steering, the controls, bounce, wheelie, lean, sideways speed
;
; Falling: SPEED * $D0 / 256 a pass; pose 8 or 9; on stages 3 and 5 the sand
; adds skid noise (FallSand). The fall's end: FallX = LateralX, Countdown = $80
; (resume), the race ends (RaceEndFall, back to PlayTurn: the next turn).
; Getting up: GetUp ($7C31) slides LateralX toward 0 by 3 a pass. In the air:
; only BikeLateral. The demo steers back to the middle. Then HeldKeys (the OR
; operand at $AD8A, ReadControls' D of RaceLoop) gives the controls.
;
; Recorded: crash (the falls, frames 3320-4580), twoplayer (the turn handed
; over at a fall).
;
; Witness: L1 5163 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
BikeControl:
  LD A,(FallTime)
  AND A
  JR Z,GetUpSlide
  DEC A
  LD B,A
  AND $7F
  JR NZ,l_ACFA
  LD A,(LateralX+$0001)
  LD (FallX),A
  LD A,$80
  LD (Countdown),A
  POP HL
RaceEndFall:
  JP RaceOver             ; JP RaceOver: the fall ends this turn
l_ACFA:
  LD A,(Speed+$0001)
  LD L,$D0
  CALL Multiply
  LD (Speed),DE
  LD HL,Pose
  LD A,(JumpHeight+$0001)
  LD C,A
  AND A
  JR Z,l_AD23
  LD A,(JumpSpeed+$0001)
  RLA
  JP NC,BikeLateral
  LD (HL),$08
  LD A,(RoadLines+$000C)
  CPL
  ADD A,$C0
  CP C
  JP C,BikeLateral
l_AD23:
  LD (HL),$09
  LD A,B
  LD (FallTime),A
FallSand:
  LD HL,LateralX+$0001    ; stages 3 and 5: the skid noise while sliding on the
                          ; sand
  LD A,(Stage)
  CP $02
  JR Z,l_AD39
  CP $04
  RET C

; Stage 5's fall on the sand: skid noise only off the right side
;
; The recording fall5 (from the stages state of stage 5, the obstacle and truck
; bytes put back) falls at frames 235-280.
;
; Witness: L1 8 (fall5).
FallStage5:
  BIT 7,(HL)
  RET NZ
; This entry point is used by the routine at BikeControl.
l_AD39:
  LD A,(HL)
  CP $C8
  RET NC
  CP $38
  RET C
  LD A,(SkidLevel)
  ADD A,$03
  LD (SkidLevel),A
  RET

; GetUp: LateralX toward 0 by 3 a pass
;
; Witness: L1 4863 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
GetUpSlide:
  LD A,(GetUp)
  AND A
  JR Z,l_AD63
  BIT 7,A
  JR NZ,l_AD57
  SUB $03
  JR l_AD59
l_AD57:
  ADD A,$03
l_AD59:
  JR NC,l_AD5C
  XOR A
l_AD5C:
  LD (GetUp),A
  LD (LateralX+$0001),A
  RET
l_AD63:
  LD A,(JumpHeight+$0001) ; riding
  AND A
  JP NZ,BikeLateral
  LD A,(DemoMode)
  AND A
  JR Z,l_AD86
  LD D,$00
  LD A,(LateralX+$0001)
  LD E,$08
  BIT 7,A
  JR Z,l_AD7F
  LD E,$04
  NEG
l_AD7F:
  CP $08
  JR C,l_AD89
  LD D,E
  JR l_AD89
l_AD86:
  CALL ReadControls
l_AD89:
  LD A,D
HeldKeys:
  OR $00                  ; OR n: n = RaceLoop's ReadControls (the reset bit
                          ; too)
  LD D,A
  LD A,(BounceTime)       ; BounceTime: random steering for its passes
  AND A
  JR Z,l_ADB2
  LD C,A
  DEC A
  LD (BounceTime),A
  LD B,$03
  LD A,(BounceDir)
  AND A
  JR NZ,l_ADAA
  LD A,C
  CP $04
  JR C,l_ADA6
  DEC B
l_ADA6:
  LD A,R
  AND $0C
l_ADAA:
  OR D
  LD D,A
  LD A,B
  LD (Pose),A
  JR l_ADF7
l_ADB2:
  BIT 1,D                 ; WHEELIE: Wheelies + 1, pose 0
  JR Z,l_ADC4
  LD A,(Wheelies)
  INC A
  LD (Wheelies),A
  XOR A
  LD (Pose),A
  JP BikeLateral
l_ADC4:
  XOR A                   ; riding: the lean from LEFT and RIGHT, or back
                          ; toward 0
  LD (Wheelies),A
  LD A,$03
  LD (Pose),A
  LD A,(Countdown)
  CP $04
  JP NC,BikeLateral
  LD A,D
  AND $0C
  JR NZ,l_ADF7
  LD A,(PassCount)
  AND $01
  JR Z,l_AE15
  LD A,(Lean)
  AND A
  JR Z,l_AE15
  BIT 7,A
  JR NZ,l_ADF1
  DEC A
  LD (Lean),A
  JR l_AE15
l_ADF1:
  INC A
  LD (Lean),A
  JR l_AE15
l_ADF7:
  LD A,(Lean)
  BIT 3,D
  JR NZ,l_ADFF
  INC A
l_ADFF:
  BIT 2,D
  JR NZ,l_AE04
  DEC A
l_AE04:
  BIT 7,A
  JR Z,l_AE0E
  CP $FD
  JR C,l_AE15
  JR l_AE12
l_AE0E:
  CP $04
  JR NC,l_AE15
l_AE12:
  LD (Lean),A
l_AE15:
  LD A,(ScrollStep+$0001) ; the sideways speed: SteerTable * LeanTable / 8, at
                          ; most 5
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,SteerTable
  ADD HL,DE
  LD E,(HL)
  LD A,(Lean)
  AND A
  JR NZ,l_AE2F
  LD HL,$0000
  LD (BounceSpeed+$0001),HL
  JR BikeLateral
l_AE2F:
  ADD A,$03
  LD C,A
  LD B,$00
  LD HL,LeanTable
  ADD HL,BC
  LD A,(HL)
  LD L,E
  CALL Multiply
  SRL D
  RR E
  SRL D
  RR E
  SRL D
  RR E
  LD A,D
  CP $05
  JR C,l_AE50
  LD D,$05
l_AE50:
  LD A,(Lean)
  RLA
  JR NC,l_AE5C
  LD HL,$0000
  SBC HL,DE
  EX DE,HL
l_AE5C:
  LD (BounceSpeed+$0001),DE
; This entry point is used by the routine at BikeControl.
BikeLateral:
  LD A,(ScrollStep+$0001) ; the bend's push (factor by the bend, bits 0-1) and
                          ; the sideways speed into LateralX, kept within the
                          ; road's scale; the jump's height

; ADD A,A on stages 2 and 4, NOP elsewhere (StartRace writes it): the bend's
; push doubled there
;
; L1 has the byte executed in every recording; the kit keeps it as a byte
; because StartRace changes the instruction.
BendOp:
  DEFB $87

; The push: (ScrollStep's high byte, doubled on stages 2 and 4) * the bend's
; factor ($52, $8F, $A4; BendPrev holds the bend), signed by BendDir;
; HorizonSpeed too
;
; Then LateralX += the sideways speed (BounceSpeed added during a bounce) + the
; push, clamped to $A4-$5C. In the air: JumpHeight += JumpSpeed, JumpSpeed -=
; $02F0; the landing (below the road's line) ends the jump: pose 3, lean 0,
; Wheelies 0, and with WHEELIE not held a 6-pass bounce.
;
; Witness: L1 4934 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
BikeLateralPush:
  LD L,A
  LD A,(BendPrev)
  AND A
  JR NZ,l_AE70
  LD DE,$0000
  JR l_AE8B
l_AE70:
  CP $02
  LD A,$52
  JR C,l_AE7C
  LD A,$8F
  JR Z,l_AE7C
  LD A,$A4
l_AE7C:
  CALL Multiply
  LD A,(BendDir)
  DEC A
  JR NZ,l_AE8B
  LD HL,$0000
  SBC HL,DE
  EX DE,HL
l_AE8B:
  LD HL,(LateralX)
  LD (HorizonScrollStep+$0001),DE
BounceSpeed:
  LD BC,$0000             ; LD BC,nn: the bounce's sideways push (BikeControl)
  LD A,(BounceTime)
  AND A
  JR Z,l_AE9C
  ADD HL,BC
l_AE9C:
  ADD HL,BC
  ADD HL,DE
  LD DE,$A55C
  LD A,H
  BIT 7,A
  JR Z,l_AEAC
  CP D
  JR NC,l_AEB0
  LD H,D
  JR l_AEB0
l_AEAC:
  CP E
  JR C,l_AEB0
  LD H,E
l_AEB0:
  LD (LateralX),HL
  LD HL,(JumpHeight)
  LD A,H
  AND A
  RET Z
  LD DE,(JumpSpeed)
  ADD HL,DE
  LD A,(RoadLines)
  CPL
  ADD A,$C1
  CP H
  JR NC,l_AECC
  LD A,H
  CP $C4
  JR C,l_AEEA
l_AECC:
  LD A,(FallTime)
  AND A
  JR NZ,l_AEE2
  LD (Lean),A
  LD (Wheelies),A
  LD A,$03
  LD (Pose),A
  CALL ReadControls
  BIT 1,D
l_AEE2:
  LD HL,$0006
  JR NZ,l_AEEA
  LD (BounceTime),HL
l_AEEA:
  LD (JumpHeight),HL
  LD HL,-$02F0            ; the gravity: JumpSpeed - $02F0 a pass
  ADD HL,DE
  LD (JumpSpeed),HL
  BIT 7,D
  RET Z
  LD A,(Pose)
  CP $02
  RET NZ
  DEC A
  LD (Pose),A
  RET

; A fall: the bike thrown (JumpHeight from RoadLines[0], JumpSpeed = SPEED / 32
; + $12), pose 7, FallTime 9 (bit 7 the side), the crash sound
;
; Recorded: crash, c1, m128, twoplayer (no fall in stages and reset3: their
; POKEs make the bike immune).
;
; Witness: L1 13 (c1, crash, fall5, m128, truck, twoplayer).
Crash:
  LD A,(RoadLines)
  CPL
  ADD A,$C2
  LD (JumpHeight+$0001),A
  LD A,(Speed+$0001)
  RLCA
  RLCA
  RLCA
  AND $07
  ADD A,$12
  LD (JumpSpeed+$0001),A
  LD A,$07
  LD (Pose),A
  LD A,(LateralX+$0001)
  AND $80
  ADD A,$09
  LD (FallTime),A
  XOR A
  LD (SkidLevel),A
  JP CrashSound

; Each pass: BikeRoadPlace, then TrackDistance += ScrollStep; the elements
; passed (TrackStep); the segment's progress, and the next segment when it ends
;
; SegmentLeft counts down by ScrollStep; its high byte's change is RowsScrolled
; (ScrollBends). At the segment's end: SegmentLeft = the segment's length
; ($AF81: the segment byte's bits 6-7 + $80, in 256 units), and in a demo
; DemoMode - 1 (at 0 the demo ends: DemoEnd).
;
; Witness: L1 5203 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
AdvanceTrack:
  CALL BikeRoadPlace
  LD DE,(ScrollStep)
  LD HL,(TrackDistance)
  ADD HL,DE
  LD (TrackDistance),HL
  LD B,H
  LD HL,(TrackPtr)
  LD A,(HL)
  AND $0F
  ADD A,A
  CP B
  JR NC,l_AF6B
  PUSH DE
  LD IY,(GapMarks)
l_AF4C:
  LD C,A
  PUSH BC
  LD IX,TrackStack
  CALL TrackStep
  POP BC
  LD A,(HL)
  AND $0F
  ADD A,A
  ADD A,C
  CP B
  JR C,l_AF4C
  LD (TrackPtr),HL
  LD A,B
  SUB C
  LD (TrackDistance+$0001),A
  LD (GapMarks),IY
  POP DE
l_AF6B:
  LD HL,(SegmentLeft)
  LD B,H
  SBC HL,DE
  LD (SegmentLeft),HL
  LD A,H
  EX AF,AF'
  LD A,B
  SUB H
  LD (RowsScrolled),A
  EX AF,AF'
  JR C,l_AF80
  AND A
  RET NZ
l_AF80:
  ADD A,$80
  LD (SegmentLeft+$0001),A
  LD A,(DemoMode)
  AND A
  JR Z,NextSegment
  DEC A
  LD (DemoMode),A
  JR NZ,NextSegment

; The demo's segments used up: drop three returns and end the race (RaceEnd),
; back to the attract loop
;
; Known only from the code: every recorded demo was ended by a key first.
DemoEnd:
  POP HL
  POP HL
  POP HL
  JP RaceEnd

; Segments + 1, StageListPtr to the next segment; bit 5 of the one passed: the
; stage's end (StageEnd)
;
; Witness: L1 257 (c1, crash, fall5, m128, stages, tech-brake-bend, tech-cheat,
; tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
NextSegment:
  LD HL,Segments
  INC (HL)
  LD HL,(StageListPtr)
  BIT 5,(HL)
  INC HL
  LD (StageListPtr),HL
  JP NZ,StageEnd

; The segment byte: Bend (bits 0-1, the bend), Crest (bits 2-3, the crest),
; BendDir (bit 4, the bend's side), length (bits 6-7); RoadRowsFlat when the
; crest was 0, ClearBendRows when the bend was 0
;
; Witness: L1 270 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
SegmentDecode:
  LD A,(Crest)
  LD (CrestPrev),A
  AND A
  CALL Z,RoadRowsFlat
  LD HL,(StageListPtr)
  LD A,(HL)
  PUSH AF
  RRA
  RRA
  AND $03
  LD (Crest),A
  LD A,(Bend)
  LD (BendPrev),A
  AND A
  CALL Z,ClearBendRows
  POP AF
  LD B,A
  AND $03
  LD (Bend),A
  LD A,B
  AND $C0
  LD (l_AF80+$0001),A
  LD HL,BendDir
  XOR A
  BIT 4,B
  JR Z,l_AFDD
  INC A
l_AFDD:
  CP (HL)
  RET Z
  LD (HL),A

; The bend's side into eight branch opcodes: JR NZ ($20) or JR Z ($28) at
; $9FAF, $93B7, $9680, $94A1, $94F5, $9AF5, $9B73, $9BB5
;
; Witness: L1 62 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
SetBendDir:
  LD A,B
  RRCA
  AND $08
  OR $20
  LD (l_9FAD+$0002),A
  LD (DrawRoadRow+$0006),A
  LD (l_9661+$001F),A
  LD (l_9495+$000C),A
  LD (l_94E8+$000D),A
  LD (l_9AE8+$000D),A
  LD (l_9B67+$000C),A
  LD (l_9BAB+$000A),A

; From LateralX and the bend: patch the road's and the objects' centre into
; twelve operands, BikeX; OffRoad by stage
;
; The offset is clamped to +/-$21 (the rest goes to BikeX's offset); the
; operands at $93A0/$93A1, $9487/$9488, $94DA/$94DB, $9ADA/$9ADB, $9B59/$9B5A,
; $9B9D/$9B9E get ADD A,n or SUB n and the offset; $9F4F and $9643 the signed
; offset. In the air or falling no off-road test.
;
; Witness: L1 5265 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
BikeRoadPlace:
  LD A,(BendDir)
  LD C,A
  LD A,(LateralX+$0001)
  LD B,$00
  BIT 7,A
  JR NZ,l_B016
  CP $22
  JR C,l_B01F
  SUB $22
  LD B,A
  LD A,$21
  JR l_B01F
l_B016:
  CP $DF
  JR NC,l_B01F
  ADD A,$21
  LD B,A
  LD A,$DF
l_B01F:
  DEC C
  JR NZ,l_B024
  NEG
l_B024:
  LD (l_9F4E+$0001),A
  LD (l_9642+$0001),A
  BIT 7,A
  LD C,$C6
  JR Z,l_B034
  LD C,$D6
  NEG
l_B034:
  LD (l_937C+$0025),A
  LD (l_9448+$0040),A
  LD (l_94C7+$0014),A
  LD (l_9AB2+$0029),A
  LD (l_9B37+$0023),A
  LD (l_9B89+$0015),A
  LD A,C
  LD (l_937C+$0024),A
  LD (l_9448+$003F),A
  LD (l_94C7+$0013),A
  LD (l_9AB2+$0028),A
  LD (l_9B37+$0022),A
  LD (l_9B89+$0014),A
  LD A,B
  NEG
  ADD A,A
  JR NC,l_B061
  SET 7,A
l_B061:
  ADD A,$80
  LD (BikeX),A
  SUB $80
  EX AF,AF'
  LD A,(FallTime)
  AND A
  RET NZ
  LD A,(JumpHeight+$0001)
  AND A
  JR Z,l_B079
  XOR A
  LD (SkidLevel),A
  RET
l_B079:
  EX AF,AF'
OffRoadJump:
  JP OffRoad              ; JP nn: nn = StageParams' off-road routine
                          ; (StartRace)
