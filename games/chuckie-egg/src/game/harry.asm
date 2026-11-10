; --------------------------------------------------------------------------------------------------------------------
; harry.asm: Harry on foot and on ladders, the map cell reader, the hen touch test
;
; Harry is a 16 x 16 sprite at (HarryX, HarryY). The slow tick calls LeaveLadder, WalkHarry, FallOffEdge and
; ClimbLadder; each tests the map cells around him with the keys of KeyTable.
; --------------------------------------------------------------------------------------------------------------------

; Walk Harry left or right one pixel, or stand
;
; Left key: unless x = 1 or the cells to the left (at his feet and above,
; LiveMap) are bricks: x - 1, HarryDir 4, a step sound ($2805) every 4 pixels.
; Right key: unless x >= $EE or the cells to the right are bricks: x + 1,
; HarryDir 0, a sound ($2806). No key: HarryFrame 3 (the next is 0, standing).
; Then the frame steps (0-3) and DrawSprite draws him. On a lift: when x leaves
; LiftX - 9 .. LiftX + 9 he walks off (JumpState 1, JumpDx his direction,
; JumpCount 4: the drift of FallOffEdge). OnLift stays 1 (only the jump start
; and SetupLevel clear it), so until the next jump the lift steps still raise
; him and the top-row death test still applies.
;
; Witness: 95 138 calls; left steps $9D59 5 749, right $9D95 6 073, standing
; $9DAB 83 316. Known only from the code: walking off a lift ($9DDB never ran).
WalkHarry:
  LD IX,HarryX
  LD HL,(HarryX)
  LD A,(HarryDir)
  AND A
  JR NZ,WalkHarryCell
  DEC L
WalkHarryCell:
  EX DE,HL
  LD HL,LiveMap
  LD A,D
  AND $F8
  LD B,$00
  SLA A
  RL B
  SLA A
  RL B
  LD C,A
  ADD HL,BC
  LD B,$00
  LD C,E
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  LD BC,$0020
  LD A,(KeyTable+5)
  IN A,($FE)
  AND $1F
  LD D,A
  LD A,(KeyTable+4)
  OR D
  CP $1F
  JR Z,WalkHarryRight
  LD A,(HarryX)
  DEC A
  JR Z,WalkHarryStand
  LD A,(HL)
  CP $05
  JR NC,WalkHarryStand
  AND A
  SBC HL,BC
  LD A,(HL)
  CP $05
  JR NC,WalkHarryStand
  DEC (IX+$00)
  LD (IX+$03),$04
  LD A,(HarryX)
  AND $03
  JR NZ,WalkHarryLeftDone
  LD HL,$2805
  CALL Beep
WalkHarryLeftDone:
  JR WalkHarryDraw
WalkHarryRight:
  LD A,(KeyTable+7)
  IN A,($FE)
  AND $1F
  LD D,A
  LD A,(KeyTable+6)
  OR D
  CP $1F
  JR Z,WalkHarryStand
  LD A,(HarryX)
  CP $EE
  JR NC,WalkHarryStand
  INC HL
  INC HL
  LD A,(HL)
  CP $05
  JR NC,WalkHarryStand
  AND A
  SBC HL,BC
  LD A,(HL)
  CP $05
  JR NC,WalkHarryStand
  INC (IX+$00)
  LD (IX+$03),$00
  LD A,(HarryX)
  AND $03
  JR NZ,WalkHarryRightDone
  LD HL,$2806
  CALL Beep
WalkHarryRightDone:
  JR WalkHarryDraw
WalkHarryStand:
  LD (IX+$02),$03
WalkHarryDraw:
  LD HL,(HarryX)
  LD A,(HarryFrame)
  INC A
  AND $03
  LD (HarryFrame),A
  ADD A,(IX+$03)
  CALL DrawSprite
  LD A,(OnLift)
  AND A
  RET Z
  LD A,(LiftX)
  XOR $FF
  RET Z
  XOR $FF
  SUB $09
  LD B,A
  LD A,(HarryX)
  CP B
  JR C,WalkOffLift
  SUB $13
  CP B
  RET C
WalkOffLift:
  LD (IX+$4D),$01
  LD D,$FF
  LD A,(HarryDir)
  AND A
  JR NZ,WalkOffLiftDir
  LD D,$01
WalkOffLiftDir:
  LD (IX+$4E),D
  LD (IX+$4F),$04
  RET

; 67 zeros
;
; Never read (L1: no access).
Zeros9DF1:
  DEFS $43

; A = the map cell at pixel (L, H), HL its address
;
; Output: HL = LiveMap + x / 8 + 4 x (y AND $F8), A = the code there (0 empty,
; 1 and 2 a ladder, 3 an egg, 4 grain, 5 a brick, $A8-$B5 the cage). BC and DE
; kept. Witness: 264 678 calls.
MapCellAt:
  PUSH DE
  PUSH BC
  EX DE,HL
  LD HL,LiveMap
  LD A,D
  AND $F8
  LD B,$00
  SLA A
  RL B
  SLA A
  RL B
  LD C,A
  ADD HL,BC
  LD B,$00
  LD C,E
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  LD A,(HL)
  POP BC
  POP DE
  RET

; Leftover: POP HL, RET, then zeros
;
; Never read (L1: no access).
LeftoverCode9E57:
  DEFB $E1,$C9,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; A = 1 when the hen at (E, D) touches Harry
;
; The box test of DrawHen $929C (Harry's x within x - 7 .. x + 5, y within y +
; 1 .. y + $1C), without the kill: A = 1 touch, 0 none; HL kept. MainLoop calls
; it for the five hens after each vertical jump step. Witness: 29 382 calls
; (none in idle-1p, where Harry never jumps).
HenTouches:
  PUSH HL
  LD HL,HarryX
  LD A,E
  ADD A,$01
  JR C,HenTouchesNo
  ADD A,$04
  CP (HL)
  JR C,HenTouchesNo
  SUB $0D
  JR NC,HenTouchesX
  XOR A
HenTouchesX:
  CP (HL)
  JR NC,HenTouchesNo
  INC HL
  LD A,D
  CP (HL)
  JR NC,HenTouchesNo
  ADD A,$1C
  CP (HL)
  JR C,HenTouchesNo
  LD A,$01
  POP HL
  RET
HenTouchesNo:
  XOR A
  POP HL
  RET

; 11 zeros
;
; Never read (L1: no access).
Zeros9E8D:
  DEFS $0B

; Climb up or down a ladder one pixel
;
; Only at x AND 7 = 0 (Harry over a column). Up key with a ladder's left half
; (1) in the cell above his head (y + 1): HarryDir $0D, y + 1, a sound ($1E14)
; every 4. Else down key with a ladder below his feet (two rows down, three
; when y is on a cell): HarryDir $0D, y - 1, a sound ($1E15). Either way the
; frame steps and JumpState becomes 0: a jump that meets a ladder with up or
; down held is caught. Then DrawSprite. Witness: 113 934 calls; up $9ED7 3 570,
; down $9F11 1 810.
ClimbLadder:
  LD IX,HarryX
  LD A,(IX+$00)
  AND $07
  RET NZ
  LD HL,(HarryX)
  INC H
  EX DE,HL
  LD HL,LiveMap
  LD B,$00
  LD A,D
  AND $F8
  SLA A
  RL B
  SLA A
  RL B
  LD C,A
  ADD HL,BC
  LD B,$00
  LD C,E
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  LD A,(HL)
  DEC A
  JR NZ,ClimbLadderDown
  LD A,(KeyTable+1)
  IN A,($FE)
  AND $1F
  LD C,A
  LD A,(KeyTable)
  OR C
  CP $1F
  JR Z,ClimbLadderDown
  LD (IX+$03),$0D
  INC (IX+$01)
  LD A,(HarryY)
  AND $03
  JR NZ,ClimbLadderUpDone
  LD HL,$1E14
  CALL Beep
ClimbLadderUpDone:
  JR ClimbLadderStep
ClimbLadderDown:
  LD BC,$0040
  AND A
  SBC HL,BC
  LD BC,$0020
  LD A,D
  AND $07
  JR NZ,ClimbLadderDownTest
  SBC HL,BC
ClimbLadderDownTest:
  LD A,(HL)
  DEC A
  JR NZ,ClimbLadderDraw
  LD A,(KeyTable+3)
  IN A,($FE)
  AND $1F
  LD C,A
  LD A,(KeyTable+2)
  OR C
  CP $1F
  JR Z,ClimbLadderDraw
  LD (IX+$03),$0D
  DEC (IX+$01)
  LD A,(HarryY)
  AND $03
  JR NZ,ClimbLadderStep
  LD HL,$1E15
  CALL Beep
ClimbLadderStep:
  LD A,(IX+$02)
  INC A
  AND $03
  LD (IX+$02),A
  LD (IX+$4D),$00
ClimbLadderDraw:
  LD HL,(HarryX)
  LD A,(IX+$02)
  ADD A,(IX+$03)
  CALL DrawSprite
  RET

; 33 zeros
;
; Never read (L1: no access).
Zeros9F3F:
  DEFS $21

; Step off a ladder onto a floor, left or right
;
; Only when y + 1 is on a cell boundary. Left key: the cell to the left and the
; one above it must not be bricks, and the one under them must be a floor
; (1-8): HarryDir 4. Right key: the same to the right: HarryDir 0. The changed
; HarryDir lets WalkHarry run on the same tick. Witness: 100 660 calls; left
; $9FAF 4 663, right $9FDA 5 530.
LeaveLadder:
  LD A,(HarryY)
  INC A
  AND $07
  RET NZ
  LD HL,(HarryX)
  EX DE,HL
  LD HL,LiveMap
  LD A,D
  AND $F8
  LD B,$00
  SLA A
  RL B
  SLA A
  RL B
  LD C,A
  ADD HL,BC
  LD B,$00
  LD C,E
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  LD BC,$0020
  LD A,(KeyTable+5)
  IN A,($FE)
  AND $1F
  LD D,A
  LD A,(KeyTable+4)
  OR D
  CP $1F
  JR Z,LeaveLadderRight
  DEC HL
  LD A,(HL)
  CP $05
  RET NC
  AND A
  SBC HL,BC
  LD A,(HL)
  CP $05
  RET NC
  AND A
  SBC HL,BC
  LD A,(HL)
  AND A
  RET Z
  CP $09
  RET NC
  LD A,$04
  LD (HarryDir),A
  RET
LeaveLadderRight:
  LD A,(KeyTable+7)
  IN A,($FE)
  AND $1F
  LD D,A
  LD A,(KeyTable+6)
  OR D
  CP $1F
  RET Z
  INC HL
  INC HL
  LD A,(HL)
  CP $05
  RET NC
  AND A
  SBC HL,BC
  LD A,(HL)
  CP $05
  RET NC
  AND A
  SBC HL,BC
  LD A,(HL)
  AND A
  RET Z
  CP $09
  RET NC
  XOR A
  LD (HarryDir),A
  RET

; 53 zeros
;
; Never read (L1: no access).
Zeros9FDF:
  DEFS $35
