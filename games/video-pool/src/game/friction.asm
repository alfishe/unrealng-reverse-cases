; --------------------------------------------------------------------------------------------------------------------
; friction.asm: The rolling friction: the steps from the direction of motion
;
; FrictionSteps $90F5 turns a ball's velocity direction into two friction steps from FrictionTable $DD3A: a
; deceleration of about 5/256 pixel a tick per tick against the motion, split between x and y by the direction,
; rounded to whole steps.
; --------------------------------------------------------------------------------------------------------------------

; The friction steps +8 / +9 of the ball IX from the direction of its velocity
;
; |vx| and |vy| (AbsHL $914A) are shifted left together, at most 8 times, until
; bit 3 of either high byte is set: two 4-bit numbers in the ratio of the
; components (high nibbles of the 8.8 values after normalising; small speeds
; use the shifted-up low bytes). FrictionTable $DD3A[16 ny + nx]: the low
; nibble is the x step, the high nibble the y step, each negated when its
; velocity component is positive, so the step opposes the motion (0 for a zero
; component). Speeds over 15 pixels a tick would lose their top bits; the shot
; gives at most 7.9.
;
; Called by MoveBall $8701 (one ball a tick in turn), BallContacts $87EF (both
; balls after a contact) and AimStoreVx $8A47 (the shot): game 42, w1 960, f1
; 284, p2 655, v1 392, m1 174 calls, frames game 6447-8651.
FrictionSteps:
  LD L,(IX+$04)
  LD H,(IX+$05)
  CALL AbsHL
  EX DE,HL
  LD L,(IX+$06)
  LD H,(IX+$07)
  CALL AbsHL
  LD B,$08
FrictionNormalise:
  BIT 3,H
  JR NZ,FrictionLookup
  BIT 3,D
  JR NZ,FrictionLookup
  SLA L
  RL H
  SLA E
  RL D
  DJNZ FrictionNormalise
FrictionLookup:
  LD A,H                  ; A = 16 ny + nx
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,D
  LD H,$00
  LD L,A
  LD DE,FrictionTable
  ADD HL,DE
  LD A,(HL)
  AND $0F
  BIT 7,(IX+$05)
  JR NZ,FrictionStoreX
  NEG
FrictionStoreX:
  LD (IX+$08),A           ; +8
  LD A,(HL)
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  BIT 7,(IX+$07)
  JR NZ,FrictionStoreY
  NEG
FrictionStoreY:
  LD (IX+$09),A           ; +9
  RET

; HL = |HL|
;
; Two's complement negate when bit 7 of H is set. Called twice by FrictionSteps
; $90F5 (game 84, w1 1920).
AbsHL:
  BIT 7,H
  RET Z
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  INC HL
  RET
