; --------------------------------------------------------------------------------------------------------------------
; lifts.asm: The two lift platforms
;
; A level with a lift (3-7) has two platforms in one shaft at LiftX; they rise one pixel every two slow ticks and
; start again at the bottom.
; --------------------------------------------------------------------------------------------------------------------

; Move both lift platforms up one pixel
;
; Nothing when LiftX is $FF. For each platform: DrawLift with 0 (erase) at its
; address, its row count + 1; at 166 the platform restarts from LiftTable's
; record (platform 1 takes the address, x and row; platform 2 the address and
; x, row 3); the address one line up (LineUp $A0A9), DrawLift with $FF.
; Witness: 57 158 calls; restarts $A02E 164 and $A05C 167.
MoveLifts:
  LD A,(LiftX)
  XOR $FF
  RET Z
  LD IX,HarryX
  LD HL,(Lift1)
  LD C,$00
  CALL DrawLift
  LD A,(Lift1Row)
  INC A
  CP $A6
  JR C,MoveLifts2
  LD HL,LiftTable
  LD BC,$0004
  LD DE,Lift1
  LDIR
  LD A,$03
MoveLifts2:
  LD (Lift1Row),A
  LD HL,(Lift1)
  CALL LineUp
  LD (Lift1),HL
  LD C,$FF
  CALL DrawLift
  LD HL,(Lift2)
  LD C,$00
  CALL DrawLift
  LD A,(Lift2Row)
  INC A
  CP $A6
  JR C,MoveLifts2Up
  LD HL,LiftTable
  LD BC,$0003
  LD DE,Lift2
  LDIR
  LD A,$03
MoveLifts2Up:
  LD (Lift2Row),A
  LD HL,(Lift2)
  CALL LineUp
  LD (Lift2),HL
  LD C,$FF
  CALL DrawLift
  RET

; Draw (C = $FF) or erase (C = 0) a platform at screen address HL
;
; Clears the byte left of HL and the byte right of the platform (unless that is
; column 0), then four lines of two bytes of C going down the screen
; (LineDown). HL kept. Witness: 109 600 calls (only in the builds with lifts:
; levels-1-3, gameover-name, levels-1-9).
DrawLift:
  PUSH HL
  DEC HL
  LD (HL),$00
  INC HL
  INC HL
  INC HL
  LD A,L
  AND $1F
  JR Z,DrawLiftLines
  LD (HL),$00
DrawLiftLines:
  POP HL
  LD B,$04
DrawLiftLine:
  LD (HL),C
  INC L
  LD (HL),C
  DEC L
  CALL LineDown
  DJNZ DrawLiftLine
  RET

; HL one screen line down
;
; The display file's line order: H + 1, and across a character row or a third.
; Witness: 438 400 calls.
LineDown:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
  RET NC
  LD A,H
  ADD A,$08
  LD H,A
  RET

; HL one screen line up
;
; Witness: 54 800 calls (MoveLifts).
LineUp:
  DEC H
  LD A,H
  AND $07
  CP $07
  JR NZ,LineUpDone
  LD A,H
  ADD A,$08
  LD H,A
  LD A,L
  SUB $20
  LD L,A
  JR NC,LineUpDone
  LD A,H
  SUB $08
  LD H,A
LineUpDone:
  RET

; Leftover: LD A,H, SUB 8, LD H,A, RET and three bytes
;
; Never read (L1: no access).
LeftoverCodeA0C0:
  DEFB $7C,$D6,$08,$67,$C9,$73,$21,$CE
