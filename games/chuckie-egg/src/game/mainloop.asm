; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop and the pickup of eggs and grain
;
; MainLoop is entered by SetupLevel's JP at $B12D and left only by a RET (or by a routine that unwinds the stack to
; it): the RET returns to $A656 in PlayLevel, after CALL SetupLevel. Each pass checks ERR_SP, plays the pickup sound
; and runs the jump; every 130th pass (PassCounter) the slow tick runs everything else.
; --------------------------------------------------------------------------------------------------------------------

; One pass of the game: the jump every pass, the rest every 130th pass
;
; 1. ERR_SP must be 1 (tape block 3): otherwise the game hangs at $985E. 2. The
; pickup sound: every 16 passes, while SoundSweep is not 0, it counts down and
; every fourth count beeps (H = (SoundSweep AND $1F) + 6, two cycles). 3. While
; JumpState is not 0: a click whose pitch follows HarryY on the pass before the
; slow tick, JumpStep $A21C, and after a vertical step the hens are tested
; against Harry (HenTouches $9E66): a touch returns (the life ends).
;
; 4. PassCounter counts 130 passes; then the slow tick: CAPS SHIFT + H holds
; the game until S, CAPS SHIFT + A aborts to Start $A410; the bonus every 50
; ticks (CountDown B = 0), the duck every 12 (MoveDuck $A0C8), the lifts every
; 2 (MoveLifts $A014; Harry on a lift rises one pixel and dies at y $A5), the
; pickup (TakeEggOrGrain $99DF), the time every 10 with a tick (CountDown B =
; 1), one hen every 3 ticks (2 from level 33; MoveHen $911E), PaintCells at
; Harry.
;
; 5. Then Harry: on foot, a jump key starts a jump (JumpState 2, JumpCount $8C,
; JumpDy 1, OnLift 0; the direction from left / right, else straight up);
; otherwise LeaveLadder $9F60, WalkHarry $9D08 unless climbing, FallOffEdge
; $B34C unless on a lift, and ClimbLadder $9E98 (also in the air: a jump
; catches a ladder).
;
; Witness: 14 873 212 passes in the eight builds, 113 934 slow ticks ($99D9);
; 477 jumps started ($9975); 920 lift steps with Harry on board ($991E). Known
; only from the code: the hold and abort keys ($98C8-$98E5) and the faster hens
; ($9944).
MainLoop:
  LD HL,(ERR_SP)
  DEC HL
  LD A,H
  OR L
MainLoopHang:
  JR NZ,MainLoopHang      ; ERR_SP is not 1: hang
  LD HL,SoundSweep
  LD A,(PassCounter)
  AND $0F
  JR NZ,MainLoopJump
  LD A,(HL)
  AND A
  JR Z,MainLoopJump
  DEC (HL)
  AND $03
  JR NZ,MainLoopJump
  LD A,(HL)
  AND $1F
  ADD A,$06
  LD H,A
  LD L,$02
  CALL Beep
MainLoopJump:
  LD A,(JumpState)
  AND A
  JR Z,MainLoopTick
  LD A,(PassCounter)
  DEC A
  JR NZ,MainLoopJumpStep
  LD L,$01
  LD A,(HarryY)
  XOR $FF
  LD H,A
  CALL Beep
MainLoopJumpStep:
  LD A,(JumpDelay)
  PUSH AF
  CALL JumpStep
  POP AF
  DEC A
  JR NZ,MainLoopTick
  LD HL,Hens
  LD B,$05
MainLoopHenTest:
  LD E,(HL)
  LD A,E
  XOR $FF
  JR Z,MainLoopTick
  INC HL
  LD D,(HL)
  INC HL
  INC HL
  INC HL
  CALL HenTouches
  AND A
  RET NZ
  DJNZ MainLoopHenTest
MainLoopTick:
  LD HL,PassCounter             ; the pass counter: the slow tick every 130 passes
  DEC (HL)
  JP NZ,MainLoopNext
  LD (HL),$82
  LD A,$FE
  IN A,($FE)
  BIT 0,A
  JR NZ,MainLoopBonus
  LD A,$BF
  IN A,($FE)
  BIT 4,A
  JR NZ,MainLoopAbort
MainLoopHold:
  LD A,$FD                ; CAPS SHIFT + H: wait for S
  IN A,($FE)
  BIT 1,A
  JR NZ,MainLoopHold
  JR MainLoopBonus
MainLoopAbort:
  LD A,$FD                ; CAPS SHIFT + A: back to the title
  IN A,($FE)
  BIT 0,A
  JR NZ,MainLoopBonus
  POP HL
  JP Start
MainLoopBonus:
  LD A,(BonusRunning)
  AND A
  JR Z,MainLoopDuck
  LD HL,BonusDelay
  DEC (HL)
  JR NZ,MainLoopDuck
  LD (HL),$32
  LD B,$00
  CALL CountDown
MainLoopDuck:
  LD HL,DuckDelay
  DEC (HL)
  JR NZ,MainLoopLifts
  LD (HL),$0C
  CALL MoveDuck
MainLoopLifts:
  LD HL,LiftDelay
  DEC (HL)
  JR NZ,MainLoopPickup
  LD (HL),$02
  CALL MoveLifts
  LD A,(OnLift)
  AND A
  JR Z,MainLoopPickup
  LD A,(HarryY)
  INC A
  LD (HarryY),A
  CP $A5
  RET NC
MainLoopPickup:
  CALL TakeEggOrGrain
  LD HL,TimeDelay
  DEC (HL)
  JR NZ,MainLoopHens
  LD (HL),$0A
  LD B,$01
  CALL CountDown
  LD HL,$0402
  CALL Beep
MainLoopHens:
  LD HL,HenDelay
  DEC (HL)
  JR NZ,MainLoopHarry
  LD C,$03
  LD A,(Level)
  CP $20
  JR C,MainLoopHenDelay
  DEC C
MainLoopHenDelay:
  LD (HL),C
  CALL MoveHen
MainLoopHarry:
  LD HL,(HarryX)
  CALL PaintCells
  LD A,(JumpState)
  AND A
  JR NZ,MainLoopFoot
  LD A,(KeyTable+9)
  IN A,($FE)
  AND $1F
  LD C,A
  LD A,(KeyTable+8)
  OR C
  CP $1F
  JR NZ,MainLoopJumpStart
  LD A,(KeyTable+11)
  IN A,($FE)
  AND $1F
  LD C,A
  LD A,(KeyTable+10)
  OR C
  CP $1F
  JR Z,MainLoopFoot
MainLoopJumpStart:
  LD IX,HarryX
  LD (IX+$4D),$02
  LD (IX+$4F),$8C
  LD (IX+$50),$00
  LD (IX+$52),$01
  LD (IX+$7D),$00
  LD D,$01
  LD E,$00
  LD A,(KeyTable+7)
  IN A,($FE)
  AND $1F
  LD C,A
  LD A,(KeyTable+6)
  OR C
  CP $1F
  JR NZ,MainLoopJumpDir
  LD D,$FF
  LD E,$04
  LD A,(KeyTable+5)
  IN A,($FE)
  AND $1F
  LD C,A
  LD A,(KeyTable+4)
  OR C
  CP $1F
  JR NZ,MainLoopJumpDir
  INC D
  LD E,(IX+$03)
MainLoopJumpDir:
  LD (IX+$4E),D
  LD (IX+$03),E
  JR MainLoopNext
MainLoopFoot:
  LD A,(JumpState)
  AND A
  JR NZ,MainLoopLadder
  CALL LeaveLadder
  LD A,(HarryDir)
  CP $0D
  CALL NZ,WalkHarry
  LD A,(OnLift)
  AND A
  CALL Z,FallOffEdge
MainLoopLadder:
  CALL ClimbLadder
MainLoopNext:
  JP MainLoop

; Take the egg or the grain at Harry's feet
;
; The cell at (HarryX + 8, HarryY - 8): an egg (3) is emptied and scores 100 x
; (1 + min(Level / 4, 9)) (AddScore $A3A7 with B = 10 x that), SoundSweep =
; $FF, EggsLeft - 1; the twelfth egg returns from MainLoop too (two returns:
; the level is complete). Grain (4) is emptied and scores 50, BonusDelay and
; TimeDelay become $FF (the bonus and the time stop for 255 slow ticks),
; SoundSweep = $FF.
;
; Witness: 114 442 calls; 16 levels completed ($9A15), 65 grains ($9A1A). The
; cell is emptied in LiveMap only: the next DrawSprite draws the background
; without it.
TakeEggOrGrain:
  LD HL,(HarryX)
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$08
  LD L,A
  CALL MapCellAt
  CP $03
  JR NZ,TakeGrain
  LD (HL),$00
  LD A,(Level)
  SRL A
  SRL A
  CP $09
  JR C,TakeEggPoints
  LD A,$09
TakeEggPoints:
  LD B,A
  INC B
  XOR A
TakeEggTimesTen:
  ADD A,$0A
  DJNZ TakeEggTimesTen
  LD B,A
  CALL AddScore
  LD A,$FF
  LD (SoundSweep),A
  LD HL,EggsLeft
  DEC (HL)
  RET NZ
  POP HL
  RET
TakeGrain:
  CP $04
  RET NZ
  LD (HL),$00
  LD B,$05
  CALL AddScore
  LD HL,$FFFF
  LD (BonusDelay),HL
  LD A,L
  LD (SoundSweep),A
  RET

; Leftover: two copies of the end of TakeGrain, then zeros
;
; Never read (L1: no access). A3 21 FF FF 22 45 73 7D 32 70 73 C9 is
; TakeGrain's tail ($9A1F-$9A2B), twice.
LeftoverCode9A2C:
  DEFB $A3,$21,$FF,$FF,$22,$45,$73,$7D,$32,$70,$73,$C9,$05,$CD,$A7,$A3
  DEFB $21,$FF,$FF,$22,$45,$73,$7D,$32,$70,$73,$C9,$00,$00,$00,$00,$00
