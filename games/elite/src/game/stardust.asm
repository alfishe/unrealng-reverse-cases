; --------------------------------------------------------------------------------------------------------------------
; stardust.asm: The stardust: 16 moving dots in the space views, and the in-system jump
;
; Stardust $7898 runs once a pass in a space view (f1, w1, d1: 1248 runs), after ClearView has emptied the back
; buffer. The 16 dots of StarDots $7E8D (5 bytes each) move by the speed, the roll and the pitch; each dot's back
; buffer address and pixel mask go into the list StarList $7F82 (StarPlot), and when the last dot is done StarPlotAll
; $7C92 XORs every listed pixel into the buffer. Nothing is erased: ClearView has cleared the buffer, and the list is
; started again each pass. The front view moves the dots away from the centre, the rear view towards it, the side
; views sideways (StardustSide $7BFC). A dot off the screen is made again at random (StarRespawn $7D55).
;
; The J key's in-system jump (InSystemJump $7EDE) moves the sun, the planet and the station $2000 closer, and makes
; the next stardust frame draw two passes at speeds $1E and $10 (StarWarp $7EDD).
; --------------------------------------------------------------------------------------------------------------------

; Move and draw the 16 dots for the view; after a J jump, two fast passes first
;
; Used by the routines at FlightLoop and SceneLaunch.
Stardust:
  LD A,(StarWarp)
  DEC A
  JR NZ,StardustPass
  LD (StarWarp),A
  LD A,$1E
  LD (SpeedRate),A
  CALL StardustPass
  LD A,$10
  LD (SpeedRate),A
  CALL StardustPass

; One pass: the rates into StarRoll and StarPitch, the speed halved + 1, then
; every dot
;
; StarCount $7F7C counts the dots (16, or 4 in witch space: WitchSpace); a
; change of view (StarView $7F7B against ViewIndex) reshuffles the table
; (StarShuffle). Each dot's 5 bytes are unpacked into StarX, StarY (sign in bit
; 7, moved to StarSigns bits 7 and 6), StarZ, StarXFrac, StarYFrac; the roll
; and pitch signs go to StarSigns bits 4 and 3.
StardustPass:
  XOR A
  LD (StarListCount),A
  LD (StarFlags),A
  LD A,(SpeedRate)
  SRL A
  INC A
  LD (StarSpeed),A
  LD HL,(RollRate)
  LD (StarRoll),HL
  LD A,$10
  LD (StarCount),A
  LD A,(WitchSpace)
  AND A
  JR Z,StardustPassGetStarView
  LD A,$04
  LD (StarCount),A
StardustPassGetStarView:
  LD A,(StarView)
  LD B,A
  LD A,(ViewIndex)
  CP B
  LD (StarView),A
  CALL NZ,StarShuffle
  LD HL,StarList
  LD (StarListPointer),HL
  LD B,$00
  LD DE,StarDots
  LD (StarPointer),DE
  LD A,(DE)
  CP $80
  JR C,StardustPassSetStarX
  AND $7F
  SET 7,B
StardustPassSetStarX:
  LD (StarX),A
  INC DE
  LD A,(DE)
  CP $80
  JR C,StardustPassSetStarY
  AND $7F
  SET 6,B
StardustPassSetStarY:
  LD (StarY),A
  INC DE
  LD A,(DE)
  LD (StarDepth),A
  INC DE
  LD A,(DE)
  LD (StarXFrac),A
  INC DE
  LD A,(DE)
  LD (StarYFrac),A
  LD A,(StarRoll)
  CP $80
  JR C,StardustPassGetStarPitch
  AND $7F
  SET 4,B
  LD (StarRoll),A
StardustPassGetStarPitch:
  LD A,(StarPitch)
  CP $80
  JR C,StardustPassIfBelow
  AND $7F
  SET 3,B
  LD (StarPitch),A
StardustPassIfBelow:
  LD A,B
  LD (StarSigns),A
  LD A,(ViewIndex)
  AND A
  JP NZ,StardustSide

; The front and rear views: a dot moves out by its depth, then by the roll and
; the pitch
;
; X += X * speed / depth (MulBits, then DivideShifted or DivideFrac8), Y the
; same, the depth decreases by the speed (the rear view: the other way). Then
; the roll turns X into Y and the pitch moves Y (StarRollPitch); the dot's
; address and mask are added to StarList (StarPlot $7B5D).
StardustFront:
  LD A,(StarSpeed)
  LD C,A
  LD A,(StarX)
  LD B,$05
  CALL MulBits
  PUSH HL
  LD A,(StarSpeed)
  LD C,A
  LD A,(StarXFrac)
  LD B,$05
  CALL MulBits
  POP DE
  LD A,(StarXFrac)
  ADD A,L
  LD (StarXFrac),A
  LD A,H
  JR NC,StardustFrontIfNotBelow
  INC A
StardustFrontIfNotBelow:
  ADD A,E
  LD E,A
  JR NC,StardustFrontGetStarDepth
  INC D
StardustFrontGetStarDepth:
  LD A,(StarDepth)
  LD B,A
  LD A,D
  AND A
  JR NZ,StardustFrontJoin
  LD A,E
  CP B
  JR NC,StardustFrontJoin
  CALL DivideFrac8
  LD B,$00
  JR StardustFrontJoin2
StardustFrontJoin:
  LD A,D
  LD L,E
  CALL DivideShifted
  LD B,C
StardustFrontJoin2:
  LD C,D
  LD A,(StarSigns)
  AND $20
  LD HL,(StarXFrac)
  JR NZ,StardustFrontIfNotZero
  ADD HL,BC
  LD A,H
  CP $78
  JR NC,StardustFrontToStarRespawn
  JR StardustFrontSetStarXFrac
StardustFrontIfNotZero:
  AND A
  SBC HL,BC
  JR C,StardustFrontToStarRespawn
  JR Z,StardustFrontToStarRespawn
StardustFrontSetStarXFrac:
  LD (StarXFrac),HL
  LD A,(StarSpeed)
  LD C,A
  LD A,(StarY)
  LD B,$05
  CALL MulBits
  PUSH HL
  LD A,(StarSpeed)
  LD C,A
  LD A,(StarYFrac)
  LD B,$05
  CALL MulBits
  POP DE
  LD A,(StarYFrac)
  ADD A,L
  LD (StarYFrac),A
  LD A,H
  INC A
  ADD A,E
  LD E,A
  JR NC,StardustFrontGetStarDepth2
  INC D
StardustFrontGetStarDepth2:
  LD A,(StarDepth)
  LD B,A
  LD A,D
  AND A
  JR NZ,StardustFrontJoin3
  LD A,E
  CP B
  JR NC,StardustFrontJoin3
  CALL DivideFrac8
  LD B,$00
  JR StardustFrontJoin4
StardustFrontJoin3:
  LD A,D
  LD L,E
  CALL DivideShifted
  LD B,C
StardustFrontJoin4:
  LD C,D
  LD A,(StarSigns)
  AND $20
  LD HL,(StarYFrac)
  JR NZ,StardustFrontIfNotZero2
  ADD HL,BC
  LD A,H
  CP $78
  JR NC,StardustFrontToStarRespawn
  JR StardustFrontSetStarYFrac
StardustFrontToStarRespawn:
  JP StarRespawn
StardustFrontIfNotZero2:
  AND A
  SBC HL,BC
  JR C,StardustFrontToStarRespawn
StardustFrontSetStarYFrac:
  LD (StarYFrac),HL
  LD A,(StarSpeed)
  LD C,A
  LD A,(StarSigns)
  AND $20
  JR NZ,StardustFrontGetStarDepth3
  LD A,(StarDepth)
  SUB C
  JR StardustFrontJoin5
StardustFrontGetStarDepth3:
  LD A,(StarDepth)
  ADD A,C
StardustFrontJoin5:
  JR C,StardustFrontToStarRespawn
  JR Z,StardustFrontToStarRespawn
  LD (StarDepth),A
; This entry point is used by the routine at StardustNext.
StardustFrontGetStarRoll:
  LD A,(StarRoll)
  AND A
  JP Z,StarRollPitch
  LD C,A
  LD A,(StarY)
  CALL StarRollScale
  JR Z,StardustFrontGetStarRoll2
  LD L,A
  LD A,(StarSigns)
  BIT 7,A
  JR NZ,StardustFrontIfNotZero4
  BIT 6,A
  JR NZ,StardustFrontIfNotZero3
  BIT 4,A
  JR NZ,StardustFrontGetStarX
  JR StardustFrontGetStarX2
StardustFrontIfNotZero3:
  BIT 4,A
  JR NZ,StardustFrontGetStarX2
  JR StardustFrontGetStarX
StardustFrontIfNotZero4:
  BIT 6,A
  JR NZ,StardustFrontIfNotZero5
  BIT 4,A
  JR NZ,StardustFrontGetStarX2
  JR StardustFrontGetStarX
StardustFrontIfNotZero5:
  BIT 4,A
  JR NZ,StardustFrontGetStarX
  JR StardustFrontGetStarX2
StardustFrontGetStarX:
  LD A,(StarX)
  ADD A,L
  CP $78
  JR NC,StardustFrontToStarRespawn
  JR StardustFrontSetStarX
StardustFrontGetStarX2:
  LD A,(StarX)
  SUB L
  CALL C,NegateY
StardustFrontSetStarX:
  LD (StarX),A
StardustFrontGetStarRoll2:
  LD A,(StarRoll)
  LD C,A
  LD A,(StarX)
  CALL StarRollScale
  JR Z,StarRollPitch
  LD L,A
  LD A,(StarSigns)
  BIT 7,A
  JR NZ,StardustFrontIfNotZero7
  BIT 6,A
  JR NZ,StardustFrontIfNotZero6
  BIT 4,A
  JR NZ,StardustFrontGetStarY
  JR StarRollScaleGetStarY
StardustFrontIfNotZero6:
  BIT 4,A
  JR NZ,StarRollScaleGetStarY
  JR StardustFrontGetStarY
StardustFrontIfNotZero7:
  BIT 6,A
  JR NZ,StardustFrontIfNotZero8
  BIT 4,A
  JR NZ,StarRollScaleGetStarY
  JR StardustFrontGetStarY
StardustFrontIfNotZero8:
  BIT 4,A
  JR Z,StarRollScaleGetStarY
StardustFrontGetStarY:
  LD A,(StarY)
  SUB L
  CALL C,NegateX
  JR StarRollScaleSetStarY

; HL = the coordinate in A times the rate in C, 4 bits (MulBits), doubled and
; rounded
;
; Used by the routine at StardustFront.
StarRollScale:
  LD B,$04
  CALL MulBits
  LD A,H
  RL L
  RLA
  AND A
  RET
; This entry point is used by the routine at StardustFront.
StarRollScaleGetStarY:
  LD A,(StarY)
  ADD A,L
  CP $78
  JP NC,StarRespawn
; This entry point is used by the routine at StardustFront.
StarRollScaleSetStarY:
  LD (StarY),A

; Apply the roll and the pitch to the dot being moved
;
; Used by the routine at StardustFront.
StarRollPitch:
  LD A,(StarPitch)
  AND A
  JP Z,StarPlot
  LD C,A
  LD A,(StarY)
  LD E,A
  LD B,$04
  CALL MulBits
  EX DE,HL
  LD HL,$4000
  LD A,(StarSigns)
  BIT 6,A
  JR NZ,StarRollPitchIfNotZero
  BIT 3,A
  JR Z,StarRollPitchJoin2
  JR StarRollPitchJoin
StarRollPitchIfNotZero:
  BIT 3,A
  JR NZ,StarRollPitchJoin2
StarRollPitchJoin:
  ADD HL,DE
  JR StarRollPitchJoin3
StarRollPitchJoin2:
  AND A
  SBC HL,DE
StarRollPitchJoin3:
  ADD HL,HL
  LD A,H
  LD (StarRollWork),A
  LD A,(StarDepth)
  LD E,A
  LD B,$08
  LD C,H
  CALL MulBits
  AND A
  ADC HL,HL
  JR C,StarRollPitchToStarRespawn
  JR Z,StarRollPitchToStarRespawn
  LD A,H
  LD (StarDepth),A
  LD A,(StarRollWork)
  LD B,A
  LD A,(StarX)
  SRL A
  CALL DivideFrac8
  LD A,D
  AND A
  JR Z,StarRollPitchToStarRespawn
  BIT 7,A
  JR NZ,StarRollPitchToStarRespawn
  LD (StarX),A
  LD A,(StarPitch)
  LD B,A
  LD A,(StarY)
  LD C,A
  LD A,(StarSigns)
  BIT 6,A
  JR NZ,StarRollPitchIfNotZero2
  BIT 3,A
  JR NZ,StarRollPitchIfNotZero3
  JR StarRollPitchJoin4
StarRollPitchIfNotZero2:
  BIT 3,A
  JR NZ,StarRollPitchJoin4
StarRollPitchIfNotZero3:
  LD A,C
  SUB B
  CALL C,NegateX
  JR StarRollPitchJoin5
; This entry point is used by the routine at StarPlot.
StarRollPitchToStarRespawn:
  JP StarRespawn
StarRollPitchJoin4:
  LD A,C
  ADD A,B
StarRollPitchJoin5:
  SRL A
  LD C,A
  LD A,(StarRollWork)
  LD B,A
  LD A,C
  CALL DivideFrac8
  LD A,D
  AND A
  JR NZ,StarRollPitchIfNotZero4
  LD A,(StarSigns)
  XOR $40
  LD (StarSigns),A
StarRollPitchIfNotZero4:
  LD A,D
  CP $40
  JR NC,StarRollPitchToStarRespawn
  LD (StarY),A

; Add the dot's back buffer address and mask (StarAddress) to StarList, or
; respawn it off the screen
;
; Used by the routine at StarRollPitch.
StarPlot:
  LD A,(StarRoll)
  AND A
  LD A,(StarY)
  JR NZ,StarPlotIfNotZero
  CP $3F
  JR NC,StarRollPitchToStarRespawn
StarPlotIfNotZero:
  CP $3F
  JR NC,StarPlotGetStarPointer
  CALL StarAddress
  LD HL,(StarListPointer)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),C
  INC HL
  LD (StarListPointer),HL
  LD A,(StarListCount)
  INC A
  LD (StarListCount),A
StarPlotGetStarPointer:
  LD HL,(StarPointer)
  LD A,(StarSigns)
  LD B,A
  LD A,(StarX)
  BIT 7,B
  JR Z,StarPlotIfZero
  OR $80
StarPlotIfZero:
  LD (HL),A
  INC HL
  LD A,(StarY)
  BIT 6,B
  JR Z,StarPlotIfZero2
  OR $80
StarPlotIfZero2:
  LD (HL),A
  INC HL
  LD A,(StarDepth)
  LD (HL),A
  INC HL
  LD A,(StarXFrac)
  LD (HL),A
  INC HL
  LD A,(StarYFrac)
  LD (HL),A
  INC HL
  LD (StarPointer),HL

; The next dot: its 5 bytes back into the table, then the next one in
;
; Used by the routine at StarRespawnMake.
StardustNext:
  LD A,(StarCount)
  DEC A
  JP Z,StarPlotAll
  LD (StarCount),A
  LD A,(StarSigns)
  AND $3B
  LD B,A
  LD DE,(StarPointer)
  LD A,(DE)
  CP $80
  JR C,StardustNextSetStarX
  AND $7F
  SET 7,B
StardustNextSetStarX:
  LD (StarX),A
  INC DE
  LD A,(DE)
  CP $80
  JR C,StardustNextSetStarY
  AND $7F
  SET 6,B
StardustNextSetStarY:
  LD (StarY),A
  INC DE
  LD A,(DE)
  LD (StarDepth),A
  INC DE
  LD A,(DE)
  LD (StarXFrac),A
  INC DE
  LD A,(DE)
  LD (StarYFrac),A
  LD A,B
  LD (StarSigns),A
  LD A,(StarFlags)
  DEC A
  JP Z,StardustNextGetStarDepth
  JR StardustNextToStardustFront
; This entry point is used by the routine at StardustPass.
StardustSide:
  DEC A
  JR NZ,StardustNextIfNotZero
  LD A,(StarSigns)
  XOR $38
  LD (StarSigns),A
StardustNextToStardustFront:
  JP StardustFront
StardustNextIfNotZero:
  LD B,A
  LD A,$01
  LD (StarFlags),A
  DEC B
  JR NZ,StardustNextGetStarSigns
  LD A,(StarSigns)
  XOR $10
  LD B,A
  AND $10
  SRL A
  LD C,A
  LD A,B
  AND $08
  ADD A,A
  OR C
  LD C,A
  LD A,B
  AND $E7
  OR C
  LD (StarSigns),A
  JR StardustNextGetStarRoll
StardustNextGetStarSigns:
  LD A,(StarSigns)
  XOR $08
  LD B,A
  AND $10
  SRL A
  LD C,A
  LD A,B
  AND $08
  ADD A,A
  OR C
  LD C,A
  LD A,B
  AND $E7
  OR C
  XOR $20
  LD (StarSigns),A
StardustNextGetStarRoll:
  LD A,(StarRoll)
  LD B,A
  LD A,(StarPitch)
  LD (StarRoll),A
  LD A,B
  LD (StarPitch),A
StardustNextGetStarDepth:
  LD A,(StarDepth)
  LD B,A
  LD A,(StarSpeed)
  CP B
StardustNextLoop:
  JP NC,StarRespawn
  CALL DivideFrac8
  SRL D
  INC D
  LD A,(StarSigns)
  BIT 5,A
  JR NZ,StardustNextIfNotZero3
  BIT 7,A
  JR NZ,StardustNextIfNotZero2
  JR StardustNextGetStarX
StardustNextIfNotZero2:
  JR StardustNextGetStarX2
StardustNextIfNotZero3:
  BIT 7,A
  JR NZ,StardustNextGetStarX
  JR StardustNextGetStarX2
StardustNextGetStarX:
  LD A,(StarX)
  SUB D
  CALL C,NegateY
  JR StardustNextSetStarX2
StardustNextGetStarX2:
  LD A,(StarX)
  ADD A,D
  CP $77
  JR NC,StardustNextLoop
StardustNextSetStarX2:
  LD (StarX),A
  JP StardustFrontGetStarRoll

; Plot the dots of this pass: XOR each listed address with its mask
; (StardustNext jumps here after the last dot)
;
; Used by the routine at StardustNext.
StarPlotAll:
  LD HL,StarList
  LD A,(StarListCount)
  AND A
  RET Z
  LD B,A
StarPlotAllLoop:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  LD A,(DE)
  XOR C
  LD (DE),A
  INC HL
  DJNZ StarPlotAllLoop
  RET

; A = -A and StarSigns bit 6 flipped (the dot crossed the axis)
;
; Used by the routines at StardustFront and StarRollPitch.
NegateX:
  NEG
  LD B,A
  LD A,(StarSigns)
  XOR $40
  LD (StarSigns),A
  LD A,B
  RET

; A = -A and StarSigns bit 7 flipped
;
; Used by the routines at StardustFront and StardustNext.
NegateY:
  NEG
  LD B,A
  LD A,(StarSigns)
  XOR $80
  LD (StarSigns),A
  LD A,B
  RET

; HL = A * C, the low B bits of C (shift and add)
;
; Used by the routines at StardustFront, StarRollScale and StarRollPitch.
MulBits:
  LD D,$00
  LD HL,$0000
  AND A
  JR MulBitsJoin
MulBitsLoop:
  ADD A,A
  RL D
MulBitsJoin:
  RR C
  JR NC,MulBitsIfNotBelow
  LD E,A
  ADD HL,DE
MulBitsIfNotBelow:
  DJNZ MulBitsLoop
  RET

; D = A:L shifted left twice divided by B (StardustFront's depth division)
;
; Used by the routine at StardustFront.
DivideShifted:
  SLA L
  RLA
  SLA L
  RLA
  SLA L
  RLA
  LD C,$F8
  CP B
  JR NC,DivideShiftedJoin
  SLA C
DivideShiftedLoop:
  SLA L
  RLA
  JR C,DivideShiftedJoin
  CP B
  JR NC,DivideShiftedJoin
  SLA C
  JR NC,DivideShiftedIfNotBelow
  JR DivideShiftedLoop
DivideShiftedJoin:
  SUB B
  SCF
  RL C
  JR C,DivideShiftedLoop
DivideShiftedIfNotBelow:
  AND A
  RET Z

; D = A * 256 / B for a small A
;
; Used by the routines at StardustFront, StarRollPitch and StardustNext.
DivideFrac8:
  LD D,$FE
DivideFrac8Loop:
  ADD A,A
  JR C,DivideFrac8Join
  CP B
  JR NC,DivideFrac8Join
  SLA D
  RET NC
  JR DivideFrac8Loop
DivideFrac8Join:
  SUB B
  SCF
  RL D
  RET NC
  JR DivideFrac8Loop

; DE = the back buffer address of the dot, C = its pixel mask
;
; The centre is (128, 63): X added or subtracted by StarSigns bit 7, Y by bit 6
; (bit 6 set: the lower half, D bit 3). D starts at $C0, the back buffer.
StarAddress:
  LD D,$C0
  LD A,(StarSigns)
  LD B,A
  LD A,(StarX)
  LD L,A
  LD A,(StarY)
  LD H,A
  LD A,$80
  BIT 7,B
  JR NZ,StarAddressIfNotZero
  ADD A,L
  JR StarAddressJoin
StarAddressIfNotZero:
  SUB L
StarAddressJoin:
  LD L,A
  LD A,$3F
  BIT 6,B
  JR NZ,StarAddressIfNotZero2
  SUB H
  JP StarAddressJoin2
StarAddressIfNotZero2:
  ADD A,H
  SET 3,D
StarAddressJoin2:
  LD H,A
  AND $07
  OR D
  LD D,A
  LD A,H
  AND $38
  ADD A,A
  ADD A,A
  LD E,A
  LD A,L
  RRA
  RRA
  RRA
  AND $1F
  OR E
  LD E,A
  LD A,L
  AND $07
  LD C,B
  INC A
  LD B,A
  LD A,$01
StarAddressLoop:
  RRCA
  DJNZ StarAddressLoop
  LD C,A
  RET

; A dot left the screen: make it again at random for the view
;
; Used by the routines at StardustFront, StarRollScale, StarRollPitch and
; StardustNext.
StarRespawn:
  LD HL,(StarSeed)
  LD DE,(StarPointer)
  LD A,(ViewIndex)
  AND A
  JR NZ,StarRespawnIfNotZero3
  LD A,(StarPitch)
  AND A
  JR NZ,StarRespawnIfNotZero

; StarRespawnFront
;
; Used by the routine at StarsRenew.
StarRespawnFront:
  LD A,$BF
  LD (StarRespawnMake+$0004),A
  LD A,$9F
  LD (StarRespawnMake+$000B),A
  XOR A
  LD (StarRespawnMake+$000D),A

; StarRespawnMake
StarRespawnMake:
  CALL StarRandom
  AND $BF
  LD (DE),A
  INC DE
  CALL StarRandom
  AND $9F
  OR $80
  LD (DE),A
  INC DE
  CALL StarRandom
  AND $7F
  ADD A,$80
  JR StarRespawnLoop
; This entry point is used by the routine at StarRespawn.
StarRespawnIfNotZero:
  LD A,$3F
  LD (StarRespawnMake+$000B),A
  LD A,$F8
  LD (StarRespawnMake+$0004),A
  LD A,(StarSigns)
  AND $08
  JR NZ,StarRespawnIfNotZero2
  LD A,$80
  LD (StarRespawnMake+$000D),A
  JR StarRespawnToStarRespawnMake
StarRespawnIfNotZero2:
  XOR A
  LD (StarRespawnMake+$000D),A
StarRespawnToStarRespawnMake:
  JP StarRespawnMake
; This entry point is used by the routine at StarRespawn.
StarRespawnIfNotZero3:
  LD C,A
  DEC C
  JP NZ,StarRespawnGetStarPitch
  LD A,(StarPitch)
  AND A
  JR Z,StarRespawnIfZero2
  LD A,$80
  LD (StarRespawnLoopCallStarRandom+$0004),A
  LD A,(StarSigns)
  AND $08
  JR Z,StarRespawnIfZero
  XOR A
  LD (StarRespawnCallStarRandom+$000B),A
  LD A,$3F
  LD (StarRespawnCallStarRandom+$000D),A
  JR StarRespawnGetJumpToggle
StarRespawnIfZero:
  LD A,$BF
  LD (StarRespawnCallStarRandom+$000D),A
  JR StarRespawnGetJumpToggle
StarRespawnIfZero2:
  LD A,$80
  LD (StarRespawnCallStarRandom+$000B),A
  LD A,$3F
  LD (StarRespawnCallStarRandom+$000D),A
  XOR A
  LD (StarRespawnLoopCallStarRandom+$0004),A
StarRespawnGetJumpToggle:
  LD A,(JumpToggle)
  RLCA
  LD (JumpToggle),A
  JR C,StarRespawnCallStarRandom
  CALL StarRandom
  OR $7F
  AND $F7
  LD (DE),A
  INC DE
  CALL StarRandom
  AND $BF
  LD (DE),A
  INC DE
StarRespawnLoopCallStarRandom:
  CALL StarRandom
  OR $80
StarRespawnLoop:
  LD (DE),A
  INC DE
  INC DE
  INC DE
  LD (StarPointer),DE
  LD (StarSeed),HL
  JP StardustNext
StarRespawnCallStarRandom:
  CALL StarRandom
  AND $F7
  LD (DE),A
  INC DE
  CALL StarRandom
  AND $80
  OR $3F
  LD (DE),A
  INC DE
  JR StarRespawnLoopCallStarRandom
StarRespawnGetStarPitch:
  LD A,(StarPitch)
  AND A
  JR NZ,StarRespawnIfNotZero5
  XOR A
  LD (StarRespawnLoop3+$0008),A
StarRespawnLoop2:
  DEC C
  JR NZ,StarRespawnIfNotZero4
  LD A,$78
  LD (DE),A
  JR StarRespawnJoin
StarRespawnIfNotZero4:
  LD A,$F8
  LD (DE),A
StarRespawnJoin:
  INC DE
  CALL StarRandom
  AND $BF
StarRespawnLoop3:
  LD (DE),A
  INC DE
  CALL StarRandom
  AND $7F
  OR $80
  JR StarRespawnLoop
StarRespawnIfNotZero5:
  LD A,$80
  LD (StarRespawnLoop3+$0008),A
  LD A,(JumpToggle)
  RLCA
  LD (JumpToggle),A
  JR NC,StarRespawnLoop2
  CALL StarRandom
  AND $F7
  LD (DE),A
  INC DE
  LD A,(StarSigns)
  AND $08
  JR Z,StarRespawnIfZero3
  LD A,$3F
  JR StarRespawnLoop3
StarRespawnIfZero3:
  LD A,$BF
  JR StarRespawnLoop3

; After a change of view: renumber the dot table (known from the code only)
;
; Used by the routine at StardustPass.
StarShuffle:
  LD A,(StarCount)
  LD B,A
  LD HL,StarDots
StarShuffleLoop:
  LD D,H
  LD E,L
  INC DE
  LD A,(DE)
  LD C,A
  LD A,(HL)
  LD (DE),A
  LD (HL),C
  LD A,L
  ADD A,$05
  JR NC,StarShuffleIfNotBelow
  INC H
StarShuffleIfNotBelow:
  LD L,A
  DJNZ StarShuffleLoop
  RET

; A = the next random byte of the dot generator (HL the seed)
;
; Used by the routine at StarRespawnMake.
StarRandom:
  LD A,H
  ADC A,A
  LD B,A
  ADC A,L
  LD H,A
  LD L,B
  RET

; The 16 dots: X (bit 7 the sign), Y (bit 7 the sign), the depth, the X
; fraction, the Y fraction
StarDots:
  DEFB $00,$10,$FF,$38,$4B
  DEFB $90,$10,$C8,$01,$41
  DEFB $90,$00,$B4,$17,$01
  DEFB $90,$90,$A0,$02,$03
  DEFB $00,$90,$D2,$04,$39
  DEFB $10,$90,$DC,$59,$06
  DEFB $10,$00,$28,$22,$78
  DEFB $10,$10,$32,$64,$15
  DEFB $02,$12,$23,$63,$79
  DEFB $82,$06,$8C,$03,$79
  DEFB $80,$03,$14,$7B,$15
  DEFB $6E,$78,$3C,$02,$22
  DEFB $04,$96,$4C,$64,$0C
  DEFB $05,$20,$EA,$2B,$66
  DEFB $64,$38,$05,$69,$17
  DEFB $04,$43,$38,$F3,$E7

; 1: the next Stardust draws the jump's two fast passes
StarWarp:
  DEFB $00

; The J key: move the sun, the planet and the station $2000 closer when nothing
; is near
;
; KeyViews $FC0A bit 6 (cleared here). Refused while the sun or the planet is
; near (SunClose $81A4, PlanetClose $81A5), while another ship is about
; (ShipsAbout $9C94) or with StationLaunch clear. Then the ships of slots 1-6
; are cleared (ClearShips $9509), every second jump a ship may follow
; (JumpEncounter $9C93), StarWarp is set and JumpCloser moves each of the three
; z coordinates. No recording pressed J.
InSystemJump:
  LD A,(KeyViews)
  BIT 6,A
  PUSH AF
  AND $BF
  LD (KeyViews),A
  POP AF
  RET Z
  LD A,(SunClose)
  DEC A
  RET Z
  LD A,(PlanetClose)
  DEC A
  RET Z
  LD A,(ShipsAbout)
  AND A
  RET NZ
  LD A,(StationLaunch)
  AND A
  RET Z
  XOR A
  LD (MissionShip),A
  LD IX,ShipSlots
  CALL ClearShips
  LD A,(JumpToggle)
  RRCA
  LD (JumpToggle),A
  LD A,$01
  JR C,InSystemJumpSetStarWarp
  LD (JumpEncounter),A
InSystemJumpSetStarWarp:
  LD (StarWarp),A
  LD IX,SunPosition
  CALL JumpCloser
  LD IX,PlanetPosition
  CALL JumpCloser
  LD IX,ShipSlots

; The z coordinate at IX+6..8 moves $2000 towards the ship (a far one by $20
; pages, a near one to $2000 on the other side)
;
; Used by the routine at InSystemJump.
JumpCloser:
  LD BC,$0020
  LD H,(IX+$08)
  LD L,(IX+$07)
  LD D,L
  BIT 7,H
  JR NZ,JumpCloserIfNotZero
  AND A
  SBC HL,BC
  JR C,JumpCloserIfBelow
  JR JumpCloserJoin
JumpCloserIfNotZero:
  ADD HL,BC
  JR C,JumpCloserIfBelow2
JumpCloserJoin:
  LD (IX+$08),H
  LD (IX+$07),L
  RET
JumpCloserIfBelow:
  LD HL,$2000
  LD E,(IX+$06)
  AND A
  SBC HL,DE
  LD A,$80
  LD (IX+$08),A
  LD (IX+$07),H
  LD (IX+$06),L
  RET
JumpCloserIfBelow2:
  LD A,$7F
  LD (IX+$08),A
  LD A,$FF
  LD (IX+$07),A
  LD (IX+$06),A
  RET

; The roll rate for the dots (bit 7 moved to StarSigns)
StarRoll:
  DEFB $00

; The pitch rate for the dots
StarPitch:
  DEFB $00

; StarRollWork
StarRollWork:
  DEFB $00

; StarFlags
StarFlags:
  DEFB $00

; The dot being moved
StarPointer:
  DEFW $0000

; The speed for the dots: SpeedRate / 2 + 1
StarSpeed:
  DEFB $00

; StarXFrac
StarXFrac:
  DEFB $00

; StarX
StarX:
  DEFB $00

; StarYFrac
StarYFrac:
  DEFB $00

; StarY
StarY:
  DEFB $00

; StarDepth
StarDepth:
  DEFB $00

; The view the dots were made for
StarView:
  DEFB $00

; Dots left in this pass
StarCount:
  DEFB $00

; The next free entry of StarList
StarListPointer:
  DEFW $0000

; Bit 7 X negative, bit 6 Y negative, bit 5 the rear view, bits 4 and 3 the
; roll and pitch signs
StarSigns:
  DEFB $00

; The number of dots StarList holds (0 at the start of each pass)
StarListCount:
  DEFB $00

; Rotated by every J jump: every second one may bring a ship
JumpToggle:
  DEFB $55

; The dots of this pass: the back buffer address and the mask of each, 16 of 3
; bytes
StarList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
