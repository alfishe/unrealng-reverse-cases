; --------------------------------------------------------------------------------------------------------------------
; jump.asm: The jump, the fall, catching a lift
;
; JumpState 2: in the air, one vertical pixel every JumpDelay passes (MainLoop calls JumpStep every pass); the x step
; and the lift test run once a slow tick. JumpState 1: drifting off an edge for JumpCount slow ticks, then falling
; straight.
; --------------------------------------------------------------------------------------------------------------------

; One step of the jump or the fall
;
; On the pass before the slow tick (PassCounter 1): PaintCells, x + JumpDx
; (bouncing at 0 and $EE), CatchLift for both platforms, then JumpDrift. On the
; other passes: in the air, the vertical step (JumpFall). Witness: 1 760 022
; calls (0 in idle-1p).
JumpStep:
  LD A,(PassCounter)
  DEC A
  JR Z,JumpStepX
  LD A,(JumpState)
  DEC A
  JP NZ,JumpFall
  RET
JumpStepX:
  LD HL,(HarryX)
  CALL PaintCells
  LD A,L
  ADD A,(IX+$4E)
  LD (HarryX),A
  AND A
  JR NZ,JumpStepRightWall
  LD (IX+$4E),$01
  JR JumpStepLifts
JumpStepRightWall:
  CP $EE
  JR C,JumpStepLifts
  LD (IX+$4E),$FF
JumpStepLifts:
  LD HL,Lift1Row
  CALL CatchLift
  LD HL,Lift2Row
  CALL CatchLift
  JR JumpDrift

; Land Harry on the lift platform whose row count is at HL
;
; Nothing without a lift. When HarryX is within LiftX - 9 .. LiftX + 9 and
; HarryY is within six pixels under the row + 16: OnLift 1, JumpState 0, Harry
; erased (frame 12), HarryY = row + $11, and the rest of JumpStep is dropped
; (POP); LiftPhrase speaks. Witness: 26 662 calls, 50 landings ($A278).
CatchLift:
  LD A,(LiftX)
  XOR $FF
  RET Z
  XOR $FF
  SUB $09
  LD B,A
  LD A,(HarryX)
  CP B
  RET C
  SUB $13
  CP B
  RET NC
  LD B,$06
  LD A,(HL)
  ADD A,$10
CatchLiftRow:
  DEC A
  CP (IX+$01)
  JR Z,CatchLiftLand
  DJNZ CatchLiftRow
  RET
CatchLiftLand:
  LD (IX+$7D),$01
  LD (IX+$4D),$00
  EX DE,HL
  LD HL,(HarryX)
  LD A,$0C
  CALL DrawSprite
  LD A,(DE)
  ADD A,$11
  LD (HarryY),A
  POP HL
  CALL LiftPhrase
  RET

; JumpState 1: count the drift; at its end the fall starts
;
; JumpCount - 1; not 0: JumpLand. At 0: JumpState 2, JumpDx 0, JumpCount $FA,
; JumpDy $FF, and Harry is drawn. JumpState 2 goes on to JumpFall. Witness: the
; fall starts $A2A2 63 times.
JumpDrift:
  LD A,(JumpState)
  DEC A
  JR NZ,JumpFall
  DEC (IX+$4F)
  JR NZ,JumpLand
  LD HL,JumpState
  LD (HL),$02
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$FA
  LD (IX+$52),$FF
  LD A,(HarryFrame)
  CALL DrawHarryFrame
  RET

; The vertical step of a jump or a fall
;
; JumpDelay counts passes. Rising (JumpDy 1): JumpCount + 10 each step, from
; $8C; after 12 steps (it wraps to 4) the top: JumpDy 0; at y $A7 and over the
; jump turns down. At the top the next step starts the fall: JumpDy $FF, delay
; 250, then 10 less a step, down to 40 (the fall speeds up). y + JumpDy; under
; y $10 the life ends (two POPs: back from MainLoop; fall-death, $A309 1). Then
; JumpLand.
;
; Witness: the top $A2F6 243, the fall starts $A2CC 279.
JumpFall:
  LD HL,JumpDelay
  DEC (HL)
  RET NZ
  PUSH HL
  LD HL,(HarryX)
  CALL PaintCells
  POP HL
  LD A,(JumpDy)
  DEC A
  JR Z,JumpRise
  INC A
  AND A
  JR NZ,JumpFallFaster
JumpFallStart:
  LD (IX+$52),$FF
  LD A,$FA
  JR JumpSetDelay
JumpFallFaster:
  LD A,(JumpCount)
  SUB $0A
  CP $28
  JR NC,JumpFallSet
  LD A,$28
JumpFallSet:
  JR JumpSetDelay
JumpRise:
  LD A,(HarryY)
  CP $A7
  JR C,JumpRiseStep
  INC (IX+$01)
  JR JumpFallStart
JumpRiseStep:
  LD A,(JumpCount)
  ADD A,$0A
  CP $04
  JR NZ,JumpSetDelay
  LD (IX+$52),$00
  XOR A
JumpSetDelay:
  LD (JumpCount),A
  LD (HL),A
  LD A,(HarryY)
  ADD A,(IX+$52)
  CP $10
  JR NC,JumpSetY
  POP HL
  POP HL
  RET
JumpSetY:
  LD (HarryY),A

; Draw Harry in the air; bounce off walls; land on a floor
;
; Draws frame 1 of his direction (DrawHarryFrame). The cell under his feet
; (MapCellAt - $3F): not rising and moving sideways, a brick beside him
; reverses JumpDx (101 bounces, $A34E). A brick, or a ladder with a brick
; beside it, under his feet, with y + 1 on a cell boundary: JumpState 0
; (landed; a climbing frame becomes 0). Witness: 813 landings ($A36A).
JumpLand:
  LD A,$01
  CALL DrawHarryFrame
  CALL MapCellAt
  LD BC,$003F
  AND A
  SBC HL,BC
  LD A,(JumpDy)
  DEC A
  JR Z,JumpLandTest
  LD A,(JumpDx)
  AND A
  JR Z,JumpLandTest
  DEC A
  JR Z,JumpLandRight
  LD A,(HarryX)
  AND $07
  CP $04
  JR NC,JumpLandTest
  DEC HL
  LD A,(HL)
  INC HL
  CP $05
  JR NZ,JumpLandTest
  JR JumpBounce
JumpLandRight:
  LD A,(HarryX)
  AND $07
  CP $03
  JR C,JumpLandTest
  INC HL
  LD A,(HL)
  DEC HL
  CP $05
  JR NZ,JumpLandTest
JumpBounce:
  LD A,(JumpDx)
  XOR $FE
  LD (JumpDx),A
JumpLandTest:
  LD A,(HL)
  AND A
  RET Z
  CP $05
  JR Z,JumpLanded
  CP $03
  RET NC
  DEC HL
  DEC A
  JR Z,JumpLandLadder
  INC HL
  INC HL
JumpLandLadder:
  LD A,(HL)
  CP $05
  RET NZ
JumpLanded:
  LD A,(HarryY)
  INC A
  AND $07
  RET NZ
  LD (IX+$4D),$00
  LD HL,HarryDir
  LD A,(HL)
  CP $0D
  RET NZ
  LD (HL),$00
  RET

; DrawSprite frame A + HarryDir at Harry
;
; Witness: 10 532 calls.
DrawHarryFrame:
  LD HL,(HarryX)
  ADD A,(IX+$03)
  CALL DrawSprite
  RET

; Speak one of the eight LiftPhrases (R AND 7)
;
; Witness: 50 calls (the lift landings).
LiftPhrase:
  LD A,R
  AND $07
  INC A
  LD B,A
  LD HL,LiftPhrases-$0001
LiftPhraseFind:
  INC HL
  DJNZ LiftPhraseFind
  LD A,(HL)
  JP StartPhrase

; The phrases LiftPhrase picks from
;
; Read at LiftPhrases + (R AND 7) (LiftPhrase steps (R AND 7) + 1 bytes from
; LiftPhrases - 1). The editable form is src/res/tables/LiftPhrases.csv.
LiftPhrases:
  INCBIN "res/tables/LiftPhrases.bin",$0000,8

; Leftover: RET, LD C,A, INC B, RET, 0, 0
;
; Never read (L1: no access).
LeftoverA3A1:
  DEFB $C9,$4F,$04,$C9,$00,$00
