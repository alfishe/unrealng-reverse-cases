; --------------------------------------------------------------------------------------------------------------------
; shotsetup.asm: The shot: direction and speed through the ROM calculator
;
; AimShot $8A02 turns the aim cursor and the power into the cue ball's velocity with the ROM's floating-point
; calculator (RST $28): dx = cursor x - cue x, dy = cursor y - cue y, r = SQR (dx*dx + dy*dy), then vy = 16 P dy / r
; and vx = 16 P dx / r with P the power (at most 126), so the speed is P / 16 pixels a tick (at most 7.9) towards the
; cursor. The ROM needs IY = ERR_NR and the I register's ROM value $3F while it runs; the routine puts I = $FE back.
; --------------------------------------------------------------------------------------------------------------------

; The shot: the cue ball's velocity from the cursor, the cue ball and the power
;
; Called by the power task $8506 when the shot is played: game 4, w1 21, f1 9,
; p2 6, v1 4, m1 1 times (one a shot; frames game 6441-8491, w1 1079-11557). IY
; = $5C3A, I = $3F, SET-MIN clears the calculator stack. Stacks the cursor x
; CursorX $86BA and the cue ball's pixel x $8A89 (STACK-A, whole pixels: the
; fractions are not used) and runs AimCalcDx $8A1A.
AimShot:
  LD IY,ERR_NR
  LD A,$3F
  LD I,A
  CALL SET_MIN
  LD A,(CursorX)
  CALL STACK_A
  LD A,(BallRecords+$0001)
  CALL STACK_A
  RST $28

; RST $28 literals: dx and dx*dx
;
; Read by the ROM's calculator after the RST $28 at $8A19 (5 bytes, game 20
; reads = 4 shots). Stack in: cursor x, cue x. Out: dx, dx*dx.
AimCalcDx:
  DEFB $03                ; $03 subtract: dx = cursor x - cue x
  DEFB $31,$31            ; $31 duplicate, $31 duplicate
  DEFB $04                ; $04 multiply: dx, dx*dx
  DEFB $38                ; $38 end-calc

; Stack the cursor y and the cue ball's y, then r and dy / r
;
; The calculator returns here. Stacks CursorY $86BB and the cue ball's pixel y
; $8A8B, runs AimCalcDyOverR $8A2D.
AimStackDy:
  LD HL,(CursorX)
  LD A,H
  CALL STACK_A
  LD A,(BallRecords+$0003)
  CALL STACK_A
  RST $28

; RST $28 literals: dy, r = SQR (dx*dx + dy*dy), dy / r
;
; 16 bytes read once a shot (game 64 reads). Stack in: dx, dx*dx, cursor y, cue
; y. Out: dx, r, dy / r. Memory 0 of the calculator holds dy.
AimCalcDyOverR:
  DEFB $03,$C0,$01        ; $03 subtract: dy; $C0 st-mem-0 (dy); $01 exchange:
                          ; dx, dy, dx*dx
  DEFB $E0,$31,$04,$0F    ; $E0 get-mem-0, $31 duplicate, $04 multiply, $0F
                          ; addition: dx, dy, dx*dx + dy*dy
  DEFB $28                ; $28 sqr: dx, dy, r
  DEFB $01,$C0,$02        ; $01 exchange, $C0 st-mem-0 (dy), $02 delete: dx, r
  DEFB $31,$E0,$01        ; $31 duplicate, $E0 get-mem-0, $01 exchange: dx, r,
                          ; dy, r
  DEFB $05,$38            ; $05 division: dx, r, dy / r; $38 end-calc

; vy = ScaleByPower (dy / r), then dx / r
;
; Stores BC from ScaleByPower $8A5D in the cue ball's vy $8A8E, then runs
; AimCalcDxOverR $8A45.
AimStoreVy:
  CALL ScaleByPower
  LD (BallRecords+$0006),BC
  RST $28

; RST $28 literals: $05 division (dx / r), $38 end-calc
AimCalcDxOverR:
  DEFB $05,$38

; vx = ScaleByPower (dx / r); the cue ball moves
;
; Stores BC in the cue ball's vx $8A8C, sets its +13 bit 6 (moving), I = $FE
; (the game's IM 2 table again), and jumps to FrictionSteps $90F5 with IX = the
; cue ball.
AimStoreVx:
  CALL ScaleByPower
  LD (BallRecords+$0004),BC
  LD IX,BallRecords
  SET 6,(IX+$0D)
  LD A,$FE
  LD I,A
  JP FrictionSteps

; BC = 16 P x the top of the calculator stack, as a 16-bit two's complement 8.8
;
; P = Power $86BF, values of $80 and more taken as $7E (the power only grows in
; steps of 2, so at most 126); BC = 16 P (2 P shifted 3 times) stacked by
; STACK-BC, then ScaleByPowerCalc $8A7A, then FP-TO-BC through ScaleToBC $8A85.
; Runs twice a shot (game 8, w1 42).
ScaleByPower:
  LD A,(Power)
  CP $80
  JR C,ScalePowerOk
  LD A,$7E
ScalePowerOk:
  ADD A,A
  LD B,$00
  LD C,A
  SLA C
  RL B
  SLA C
  RL B
  SLA C
  RL B
  CALL STACK_BC
  RST $28

; RST $28 literals: multiply, and add 65536 to a value that is not positive
;
; 11 bytes; the jump-true skips the stk-data and the addition for a positive
; product. A negative x + 65536 is its 16-bit two's complement, which FP-TO-BC
; returns in BC. A product of exactly 0 (the cursor on the cue ball's row or
; column) also gets 65536 added; FP-TO-BC then reads the float's bytes as an
; integer, BC = 0 with the carry set, so the component is 0 after all (known
; only from the ROM's code, see the notes).
ScaleByPowerCalc:
  DEFB $04,$31,$37        ; $04 multiply: 16 P x (d / r); $31 duplicate; $37
                          ; greater-0
  DEFB $00,$06            ; $00 jump-true, offset 6: to the end-calc at $8A84
                          ; when positive
  DEFB $34,$00,$41,$00    ; $34 stk-data: $00 (one mantissa byte, exponent
                          ; next), $41 (+$50 = $91), $00: 65536
  DEFB $0F,$38            ; $0F addition; $38 end-calc

; JP FP-TO-BC: the value off the calculator stack into BC
;
; Jumps to the ROM's FP-TO-BC $2DA2, which returns to AimStoreVy $8A3D or
; AimStoreVx $8A47.
ScaleToBC:
  JP FP_TO_BC
