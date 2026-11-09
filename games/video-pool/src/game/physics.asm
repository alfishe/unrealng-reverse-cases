; --------------------------------------------------------------------------------------------------------------------
; physics.asm: The physics task: the motion step, rolling friction, ball against ball
;
; The task PhysicsTask $86C1 (list $84BA, period 0: once an interrupt while the balls move) walks the seven ball
; records BallRecords $8A88 and calls MoveBall $8701 for every ball that is on the table, moving and not potted (+13
; bits 7 and 6 set, bit 5 clear).
;
; Numbers: a position is 8.8 fixed point in screen pixels (+0 the fraction, +1 the pixel), a velocity 8.8 two's
; complement in pixels a tick (+4/+5 vx, +6/+7 vy), a friction step a signed byte in 1/256 pixel a tick, added to the
; velocity every tick (+8 x, +9 y). One tick = one run of the task = one interrupt.
;
; MoveBall adds the velocity to the position, clamps it to x 7..248, y 55..176, runs the ball-ball test BallContacts
; $87EF and the cushion and pocket test PocketOrCushion $8B4E, then applies the friction steps; a component whose sign
; the step would flip becomes 0, and a ball with both components 0 stops (bit 6 cleared).
;
; Ball against ball uses no trigonometry: the whole-pixel |dx|, |dy| of two balls index ContactTable $DBFA (inside /
; contact ring / apart), the ball is stepped back along its velocity until it lies on the ring, and the ring cell
; picks one of 31 CollisionRecords $DE3A: three coefficients nx^2, ny^2, |nx ny| (0.8 fixed point, 1.0 = $0100) by
; which ScaleVelocity $89C4 projects the relative velocity onto the line of centres. The projection is added to one
; ball and taken from the other: an equal-mass elastic collision.
; --------------------------------------------------------------------------------------------------------------------

; The physics task: move every rolling ball one tick
;
; A task of the list $84BA (the balls moving, period 0) and of the editor's
; list $C518, reached through the scheduler's JP (HL), so no CALL counts it:
; the first instruction ran game 290, w1 2860, f1 742, p2 1180, v1 822, m1 313
; times (frames game 6447-8658, w1 1085-11615).
;
; Clears EventCount $8B4D, then for each of the seven records (IX from
; BallRecords $8A88, 14 bytes a step, B = 7..1) calls MoveBall $8701 when +13
; has bit 7 (on the table) and bit 6 (moving) set and bit 5 (potted) clear:
; 2030 records looked at and 286 moves in game, 20020 / 5644 in w1.
;
; Then advances FrictionTurn $8B4C (0..6, wrapping: $86F2 ran 41 of 290 times
; in game, 398 of 2860 in w1), so each ball gets its friction steps recomputed
; once in seven ticks. If EventCount reached 7 the whole pass runs again
; ($86FB); no recording took that jump (the counts of $86C1 and $86FD are equal
; in every build). Ends with CALL $8304.
;
; In w1 the break (frames 1085-1254) has 159 ticks for 168 interrupts: no tick
; in every second frame 1156-1172, after the contacts of frames 1150-1153
; (tools/physics_model.py, docs 10.1).
PhysicsTask:
  XOR A
  LD (EventCount),A
  LD IX,BallRecords
  LD B,$07
PhysicsBallLoop:
  LD A,(IX+$0D)           ; IX = the record, B = 7 - the ball number
  BIT 7,A
  JR Z,PhysicsNextBall
  BIT 6,A
  JR Z,PhysicsNextBall
  BIT 5,A
  JR NZ,PhysicsNextBall
  PUSH BC
  PUSH IX
  CALL MoveBall
  POP IX
  POP BC
PhysicsNextBall:
  LD DE,$000E
  ADD IX,DE
  DJNZ PhysicsBallLoop
  LD A,(FrictionTurn)
  INC A
  CP $07
  JR NZ,PhysicsTurnStore
  XOR A
PhysicsTurnStore:
  LD (FrictionTurn),A     ; FrictionTurn = (FrictionTurn + 1) mod 7
  LD A,(EventCount)
  CP $07
  JR NC,PhysicsTask       ; EventCount >= 7: one more pass (never taken in any
                          ; recording)
  CALL BuildDrawList
  RET

; One tick of one ball: move, collide, pocket or bounce, friction, redraw flag
;
; Input IX = the ball's record, B = 7 - the ball number (0 cue, 1-6); called by
; PhysicsTask $86C1 (and from the editor $C20B, a path m1 never took). Runs
; game 286, w1 5644, f1 1574, p2 3850, v1 2299, m1 970 times.
;
; 1. When FrictionTurn $8B4C = B - 1 the friction steps are recomputed first
; (FrictionSteps $90F5): one ball a tick in turn.
;
; 2. x += vx, y += vy (16-bit 8.8 adds). x is clamped to $0700..$F800
; (7.0..248.0) with the carry of the add caught (a wrap past 0 or $FFFF goes to
; the limit); y to $3700..$B000 (55.0..176.0), the low side without the carry
; test. The clamps fired w1 7 / 9, f1 1 / 2, p2 2 / 0, v1 2 / 2 times ($8738 /
; $8768); the limits lie past the pocket line, so a clamped ball is potted in
; the same move.
;
; 3. Clears +13 bit 4, then BallContacts $87EF (ball against ball) and
; PocketOrCushion $8B4E (A = the ball number).
;
; 4. Friction: vx += the sign-extended +8, vy += +9; if the sum crosses zero
; the component becomes 0 ($8795: w1 61, $87B9: w1 58 times). Both components
; 0: +13 bit 6 cleared, the ball stops ($87D2: game 4, w1 53).
;
; 5. Redraw flag: +13 bit 4 is set unless the pixel x, y equal +10, +11. Those
; hold the sprite's corner (x - 7, y - 7), so the test can only match after a
; 7-pixel jump; in every build $87EA (set) ran exactly as often as $87DB (the
; test reached), so every moving ball is redrawn every tick.
MoveBall:
  LD A,$07
  SUB B
  PUSH AF
  LD A,(FrictionTurn)
  DEC B
  CP B
  CALL Z,FrictionSteps
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD E,(IX+$04)
  LD D,(IX+$05)
  ADD HL,DE
  BIT 7,D
  JR NZ,MoveXLeft
  LD DE,$F800
  JR C,MoveXClamp
  XOR A
  SBC HL,DE
  JR NC,MoveXClamp
  ADD HL,DE
  JR MoveXStore
MoveXLeft:
  LD DE,$0700             ; vx negative: low clamp $0700
  JR NC,MoveXClamp
  XOR A
  SBC HL,DE
  JR C,MoveXClamp
  ADD HL,DE
  JR MoveXStore
MoveXClamp:
  EX DE,HL                ; x = the limit in DE
MoveXStore:
  LD (IX+$00),L
  LD (IX+$01),H
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD E,(IX+$06)
  LD D,(IX+$07)
  ADD HL,DE
  BIT 7,D
  JR NZ,MoveYUp
  LD DE,$B000
  JR C,MoveYClamp
  XOR A
  SBC HL,DE
  JR NC,MoveYClamp
  ADD HL,DE
  JR MoveYStore
MoveYUp:
  LD DE,$3700             ; vy negative: low clamp $3700, no carry test
  XOR A
  SBC HL,DE
  JR C,MoveYClamp
  ADD HL,DE
  JR MoveYStore
MoveYClamp:
  EX DE,HL
MoveYStore:
  LD (IX+$02),L
  LD (IX+$03),H
  RES 4,(IX+$0D)
  CALL BallContacts
  POP AF
  CALL PocketOrCushion
  LD A,(IX+$08)
  OR A
  JR Z,FrictionVy
  LD E,A
  LD D,$00
  JP P,FrictionVx
  DEC D
FrictionVx:
  LD L,(IX+$04)           ; DE = the step, sign-extended
  LD H,(IX+$05)
  BIT 7,H
  ADD HL,DE
  JR NZ,FrictionVxCheck
  CCF
FrictionVxCheck:
  JR NC,FrictionVxStore   ; carry here = vx crossed zero
  LD HL,$0000
FrictionVxStore:
  LD (IX+$04),L
  LD (IX+$05),H
FrictionVy:
  LD A,(IX+$09)
  OR A
  JR Z,StopTest
  LD E,A
  LD D,$00
  JP P,FrictionVyAdd
  DEC D
FrictionVyAdd:
  LD L,(IX+$06)
  LD H,(IX+$07)
  BIT 7,H
  ADD HL,DE
  JR NZ,FrictionVyCheck
  CCF
FrictionVyCheck:
  JR NC,FrictionVyStore
  LD HL,$0000
FrictionVyStore:
  LD (IX+$06),L
  LD (IX+$07),H
StopTest:
  LD A,(IX+$04)           ; vx = vy = 0: RES 6, the ball stops
  OR (IX+$05)
  JR NZ,RedrawTest
  LD A,(IX+$06)
  OR (IX+$07)
  JR NZ,RedrawTest
  RES 6,(IX+$0D)
RedrawTest:
  BIT 4,(IX+$0D)          ; compares +1 with +10 and +3 with +11 (the sprite
                          ; corner, x - 7): never equal in practice
  RET NZ
  LD A,(IX+$01)
  CP (IX+$0A)
  JR NZ,RedrawSet
  LD A,(IX+$03)
  CP (IX+$0B)
  RET Z
RedrawSet:
  SET 4,(IX+$0D)
  RET

; Ball against ball: find a touching ball, step back onto the contact ring,
; exchange velocities
;
; Input IX = the moving ball. Runs as often as MoveBall (game 286, w1 5644).
; For every record IY on the table (7 looked at, the ball itself included; it
; and any ball on the same pixel are skipped by dx = dy = 0): whole-pixel |dx|,
; |dy| (the +1, +3 bytes) both below 16, then ContactTable $DBFA[16 |dy| +
; |dx|]. A negative entry ($80) means overlap (w1 201, f1 55, p2 124, v1 80, m1
; 47 times, $8833); 0 (apart) and a ring entry without overlap are no contact
; (RET P).
;
; On overlap: StepBack $8E33 moves IX back along its own velocity by less than
; a pixel and the table is read again until the entry is no longer negative;
; ContactSigns $89B5 = 2 (dx < 0) + (dy < 0) with dx = IX - IY. The entry n
; (1..31) selects CollisionRecords $DE3A + 6 (n - 1), kept in ContactRecordPtr
; $89B7 with IY in ContactOther $89B9; the loop goes on, so the last touching
; ball wins. The ring entry was found w1 71, f1 28, p2 49, v1 32, m1 17 times;
; game (c1, a game of fouls) never had a ball hit.
;
; The exchange ($889C) runs if the ball moves towards the other in x or y (sign
; of dx against the sign of vx, the same for y); it always did when a contact
; was found (the JP P to $89AA never taken). With dv = v(IY) - v(IX) and the
; record's w0 = nx^2, w1 = ny^2, w2 = |nx ny|: A = w0 dvx, B = w2 dvy, C = w2
; dvx, D = w1 dvy (ScaleVelocity $89C4, 4 calls a contact). The sign s of nx ny
; is + when dx and dy have the same sign (ContactSigns 0 or 3), - otherwise.
; IX.v += (A + sB, D + sC); IY.v -= the same. The other ball is set moving (+13
; bit 6), BallHitFlag $89BB = 1, the sound request $827D = 1, EventCount += 2,
; and both balls get new friction steps (FrictionSteps $90F5 twice).
;
; Finally the moving ball's fractions are set to $80 (the centre of its pixel),
; also when it was moving away.
BallContacts:
  PUSH IY
  XOR A
  LD (ContactFound),A
  LD IY,BallRecords
  LD B,$07
ContactLoop:
  PUSH BC                 ; PUSH ContactNext as the return address of every
                          ; test below
  LD HL,ContactNext
  PUSH HL
  BIT 7,(IY+$0D)
  RET Z
  LD A,(IX+$01)
  SUB (IY+$01)
  JR NC,ContactDy
  NEG
ContactDy:
  CP $10
  RET NC
  LD C,A
  LD A,(IX+$03)
  SUB (IY+$03)
  JR NC,ContactLookup
  NEG
ContactLookup:
  CP $10                  ; A = 16 |dy| + |dx|
  RET NC
  LD B,A
  OR C
  RET Z
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD HL,ContactTable
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  OR A
  RET P
ContactBackOff:
  CALL StepBack           ; step back, recompute signed dx, dy and the signs
  LD A,(IX+$01)
  SUB (IY+$01)
  PUSH AF
  LD A,$00
  RLA
  RLA
  LD (ContactVars),A
  POP AF
  JR NC,ContactBackDy
  NEG
ContactBackDy:
  LD C,A
  LD A,(IX+$03)
  SUB (IY+$03)
  PUSH AF
  LD A,(ContactVars)
  ADC A,$00
  LD (ContactVars),A
  POP AF
  JR NC,ContactBackLookup
  NEG
ContactBackLookup:
  ADD A,A                 ; still negative: step back again
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD HL,ContactTable
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  OR A
  JP M,ContactBackOff
  LD HL,CollisionRecords  ; the ring entry n: record = CollisionRecords + 6 (n
                          ; - 1)
  DEC A
  ADD A,A
  LD E,A
  ADD A,A
  ADD A,E
  LD E,A
  ADD HL,DE
  LD (ContactRecordPtr),HL
  LD (ContactOther),IY
  LD A,(ContactVars)
  LD (ContactSignsFound),A
  RET
ContactNext:
  LD DE,$000E             ; the next IY (reached by RET from the tests)
  ADD IY,DE
  POP BC
  DEC B
  JP NZ,ContactLoop
  LD IY,(ContactOther)    ; all seen: ContactFound zero = no contact
  LD A,(ContactFound)
  OR A
  JP Z,ContactDone
  LD A,(ContactSignsFound) ; moving towards the other ball in x or in y:
                           ; exchange
  RRCA
  RRCA
  XOR (IX+$05)
  LD L,A
  LD A,(ContactSignsFound)
  RRCA
  XOR (IX+$07)
  OR L
  JP P,ContactCentre
  LD L,(IY+$04)
  LD H,(IY+$05)
  LD E,(IX+$04)
  LD D,(IX+$05)
  XOR A
  SBC HL,DE
  EX DE,HL
  PUSH DE
  LD HL,(ContactRecordPtr)
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  CALL ScaleVelocity
  LD (ExchangeA),HL
  POP DE
  LD HL,(ContactRecordPtr)
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  PUSH HL
  CALL ScaleVelocity
  LD (ExchangeC),HL
  LD L,(IY+$06)
  LD H,(IY+$07)
  LD E,(IX+$06)
  LD D,(IX+$07)
  XOR A
  SBC HL,DE
  EX DE,HL
  POP HL
  PUSH DE
  CALL ScaleVelocity
  LD (ExchangeB),HL
  POP DE
  LD HL,(ContactRecordPtr)
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  CALL ScaleVelocity
  LD (ExchangeD),HL
  LD A,(ContactSignsFound)
  OR A
  JR Z,ExchangeVx
  INC A
  AND $03
ExchangeVx:
  LD L,(IX+$04)           ; A = 0: same-sign quadrant (add the cross terms),
                          ; else subtract
  LD H,(IX+$05)
  LD DE,(ExchangeA)
  ADD HL,DE
  LD DE,(ExchangeB)
  OR A
  JR Z,ExchangeVxAdd
  SBC HL,DE
  JR ExchangeVxStore
ExchangeVxAdd:
  ADD HL,DE
ExchangeVxStore:
  LD (IX+$04),L
  LD (IX+$05),H
  LD L,(IX+$06)
  LD H,(IX+$07)
  LD DE,(ExchangeD)
  ADD HL,DE
  LD DE,(ExchangeC)
  OR A
  JR Z,ExchangeVyAdd
  SBC HL,DE
  JR ExchangeVyStore
ExchangeVyAdd:
  ADD HL,DE
ExchangeVyStore:
  LD (IX+$06),L
  LD (IX+$07),H
  LD L,(IY+$04)
  LD H,(IY+$05)
  LD DE,(ExchangeA)
  OR A
  SBC HL,DE
  LD DE,(ExchangeB)
  OR A
  JR NZ,ExchangeOtherVxAdd
  SBC HL,DE
  JR ExchangeOtherVxStore
ExchangeOtherVxAdd:
  ADD HL,DE
ExchangeOtherVxStore:
  LD (IY+$04),L
  LD (IY+$05),H
  LD L,(IY+$06)
  LD H,(IY+$07)
  LD DE,(ExchangeD)
  OR A
  SBC HL,DE
  LD DE,(ExchangeC)
  OR A
  JR NZ,ExchangeOtherVyAdd
  SBC HL,DE
  JR ExchangeOtherVyStore
ExchangeOtherVyAdd:
  ADD HL,DE
ExchangeOtherVyStore:
  LD (IY+$06),L
  LD (IY+$07),H
  SET 6,(IY+$0D)
  LD A,$01
  LD (BallHitFlag),A
  LD (SoundRequest),A
  LD A,(EventCount)
  ADD A,$02
  LD (EventCount),A
  CALL FrictionSteps
  PUSH IY
  EX (SP),IX
  CALL FrictionSteps
  POP IX
ContactCentre:
  LD A,$80                ; fractions of x and y = $80
  LD (IX+$00),A
  LD (IX+$02),A
ContactDone:
  POP IY
  RET

; The ball-contact work variables
;
; Written and read by BallContacts $87EF (w1 18 997 reads over the block).
; BallHitFlag $89BB is cleared at the shot's start ($84C8) and read by the
; end-of-shot task ($83CD) to tell whether any ball was hit.
ContactVars:
  DEFB $00                ; 2 (dx < 0) + (dy < 0), dx = mover - other,
                          ; recomputed on each back-off step
ContactSignsFound:
  DEFB $00                ; the signs at the contact found
ContactRecordPtr:
  DEFB $00                ; the low byte of the CollisionRecords pointer
ContactFound:
  DEFB $00                ; the pointer's high byte ($DE), cleared before the
                          ; scan: non-zero = a contact found
ContactOther:
  DEFB $00,$00            ; the other ball's record (IY), a word
BallHitFlag:
  DEFB $00                ; 1 = a ball was hit during this shot
ExchangeA:
  DEFB $00,$00            ; w0 dvx, 8.8 signed
ExchangeB:
  DEFB $00,$00            ; w2 dvy
ExchangeC:
  DEFB $00,$00            ; w2 dvx
ExchangeD:
  DEFB $00,$00            ; w1 dvy

; HL = DE x the coefficient HL (0.8 fixed point, $0100 = 1.0), signed
;
; Input HL = a coefficient of a collision record (H = 1: exactly 1.0, else 0
; and L the fraction), DE = a signed 8.8 velocity; output HL = the product, 8.8
; signed; uses A, BC, DE. Coefficient 1.0 returns DE at once ($89C7: 24 of 284
; calls in w1). Otherwise |DE| is formed, the fraction times the low byte
; (MulByte $89F5) rounded to its high byte, plus the fraction times the high
; byte, and the sign put back. Runs only on contacts: w1 284, f1 112, p2 196,
; v1 124, m1 68 calls (4 a contact), never in game.
ScaleVelocity:
  BIT 0,H
  EX DE,HL
  RET NZ
  EX DE,HL
  LD A,D
  OR A
  PUSH AF
  JP P,ScaleFrac
  CPL
  LD D,A
  LD A,E
  CPL
  LD E,A
  INC DE
ScaleFrac:
  LD A,L                  ; fraction x the low byte, rounded
  PUSH AF
  LD C,D
  LD L,H
  LD D,H
  CALL MulByte
  BIT 7,L
  JR Z,ScaleInt
  INC H
ScaleInt:
  LD L,H                  ; + fraction x the integer byte
  LD H,$00
  POP AF
  LD D,H
  LD E,C
  CALL MulByte
  POP AF
  RET P
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  INC HL
  RET

; HL += A x DE, 8 bits of A from bit 0
;
; Shift-and-add: eight steps, A rotated right, DE added when the bit is set, DE
; doubled each step. Called twice by ScaleVelocity $89C4 (w1 520 calls).
MulByte:
  LD B,$08
MulByteLoop:
  RRCA
  JR NC,MulByteShift
  ADD HL,DE
MulByteShift:
  SLA E
  RL D
  DJNZ MulByteLoop
  RET
