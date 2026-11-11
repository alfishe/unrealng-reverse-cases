; --------------------------------------------------------------------------------------------------------------------
; debris.asm: Eight flying fragments: an exploded object's pieces, moved and drawn every frame
;
; When an object is destroyed, bank 2 $B6D1 (the mission code's ApiVector11, $67DF) fills the eight records at $CFEC
; with random velocities ($B74B, $B75C). Every frame of every view loop, Bank3Step ($72A3, bank 5) calls DrawDebris
; $D08C and MoveAllDebris $D1EC: each live fragment is moved by its velocity, falls (its y speed drops by 5 a frame)
; and dies when it reaches the ground; the ones in front of the tank are drawn through the object renderer $BEDE.
; --------------------------------------------------------------------------------------------------------------------

; The eight fragment records, 20 bytes each (zero at the entry)
;
; +0 flags (bit 7 live, bit 5 drawn this frame; 0 = free), +1 x (fraction, then
; a word), +4 z (fraction, word), +7 y (word), +`$0A` the turn, +`$0B` the
; distance word from `$BBBC`, +`$0D` y relative to the camera, +`$0F` x speed,
; +`$10` z speed, +`$11` y speed, +`$12` and +`$13` the two turn steps. Written
; by `$B74B` / `$B75C` (death, play2), MoveDebris and DrawDebris.
;
; Witness: death, play2 (MoveDebris runs 661 times); the other recordings only
; read the flags.
DebrisRecords:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Draw every live fragment that lies in front of the tank and inside the view
;
; For each of the 8 records (IX from `$CFEC`, the count in the operand
; `$D140`): clear bit 5; a live record's x and z minus the camera's (`$67A7`,
; `$67AA`) into the projection operands `$9A8E` and `$9A6C`; skip it when x is
; outside -`$20`..`$1F` (high byte; the bounds are the operands `$D0C6` /
; `$D0CE`) or z likewise; y minus `$67AD` to +`$0D`; `$BBBC` (bank 2) gives the
; distance (HL, kept in `$66D0`) and HL' to +`$0B`; DebrisInView; if in view,
; bit 5 set and the renderer `$BEDE` draws it.
;
; Witness: L1 3602 (c1, death, m2erbe, missions, play, play2).
DrawDebris:
  LD IX,DebrisRecords
  LD A,$08
  LD (DebrisCountOp+$0001),A

; DrawDebrisNext
;
; Used by the routine at DrawDebrisSkip.
DrawDebrisNext:
  LD A,(IX+$00)
  AND $DF
  LD (IX+$00),A
  JP P,DrawDebrisSkip
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD BC,($67A7)
  AND A
  SBC HL,BC
  LD ($9A8E),HL
  LD A,($67A9)
  LD E,A
  LD A,(IX+$03)
  SBC A,E
  LD D,H
  SLA D
  ADC A,$00
  JP NZ,DrawDebrisSkip
  LD A,H
  AND A
  JP M,XBoundNegOp
XBoundOp:
  LD A,$1F                ; LD A,n: n ($D0C6) the x limit $1F, read again for z
  CP H
  JR NC,l_D0D3
  JP DrawDebrisSkip
XBoundNegOp:
  LD A,$DF                ; LD A,n: n ($D0CE) the lower limit $DF
  CP H
  JP NC,DrawDebrisSkip
l_D0D3:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD BC,($67AA)
  AND A
  SBC HL,BC
  LD ($9A6C),HL
  LD A,($67AC)
  LD E,A
  LD A,(IX+$06)
  SBC A,E
  LD D,H
  SLA D
  ADC A,$00
  JR NZ,DrawDebrisSkip
  LD A,H
  AND A
  JP M,l_D0FF
  LD A,(XBoundOp+$0001)
  CP H
  JR NC,l_D105
  JR DrawDebrisSkip
l_D0FF:
  LD A,(XBoundNegOp+$0001)
  CP H
  JR NC,DrawDebrisSkip
l_D105:
  LD L,(IX+$07)
  LD H,(IX+$08)
  LD BC,($67AD)
  AND A
  SBC HL,BC
  LD (IX+$0D),L
  LD (IX+$0E),H
  CALL $BBBC
  LD ($66D0),HL
  EXX
  LD (IX+$0B),L
  LD (IX+$0C),H
  EXX
  CALL DebrisInView
  JR C,DrawDebrisSkip
  LD HL,($66D0)
  LD A,(IX+$00)
  OR $20
  LD (IX+$00),A
  CALL $BEDE

; DrawDebrisSkip
;
; Used by the routine at DrawDebrisNext.
DrawDebrisSkip:
  LD C,$14
  LD B,$00
  ADD IX,BC
DebrisCountOp:
  LD A,$00                ; LD A,n: n ($D140) the records left
  DEC A
  LD (DebrisCountOp+$0001),A
  JP NZ,DrawDebrisNext

; Carry set when the fragment is outside the view's cone: |x'| > z / 2 + 100
;
; Input: HL = the distance from `$BBBC`, IX the record (+`$0B` the side
; offset). Output: carry = not visible. Witness: L1 4263 (c1, death, m2erbe,
; missions, play, play2).
DebrisInView:
  SRA H
  RR L
  LD BC,$0064
  ADD HL,BC
  LD A,(IX+$0C)
  LD D,A
  LD E,(IX+$0B)
  AND A
  JP P,l_D163
  AND A
  ADC HL,DE
  JP P,l_D169
l_D161:
  SCF
  RET
l_D163:
  AND A
  SBC HL,DE
  JP M,l_D161
l_D169:
  AND A
  RET

; Move one fragment: add the speeds to x, z, y; gravity on the y speed; free
; the record below the ground
;
; x += the signed +`$0F` (with carry into the word), z += +`$10`, y += +`$11`;
; y below 0: the record is freed (+0 = 0). Else the y speed drops by 5 (it
; stays while the subtraction would overflow, `JP PO`) and the turn +`$0A`
; grows by +`$12` and +`$13`.
;
; Witness: L1 661 (death, play2).
MoveDebris:
  LD E,$00
  LD A,(IX+$0F)
  AND A
  JP P,l_D175
  DEC E
l_D175:
  LD D,E
  LD C,(IX+$01)
  ADD A,C
  LD (IX+$01),A
  LD L,(IX+$02)
  LD H,(IX+$03)
  ADC HL,DE
  LD (IX+$02),L
  LD (IX+$03),H
  LD E,$00
  LD A,(IX+$10)
  AND A
  JP P,l_D195
  DEC E
l_D195:
  LD D,E
  LD C,(IX+$04)
  ADD A,C
  LD (IX+$04),A
  LD L,(IX+$05)
  LD H,(IX+$06)
  ADC HL,DE
  LD (IX+$05),L
  LD (IX+$06),H
  LD D,$00
  LD A,(IX+$11)
  AND A
  JP P,l_D1B5
  DEC D
l_D1B5:
  LD E,A
  LD L,(IX+$07)
  LD H,(IX+$08)
  AND A
  ADC HL,DE
  JP M,l_D1CF
  LD (IX+$07),L
  LD (IX+$08),H
  LD E,$05
  AND A
  SBC A,E
  JP PO,l_D1D4
l_D1CF:
  XOR A
  LD (IX+$00),A
  RET
l_D1D4:
  LD (IX+$11),A
  LD A,(IX+$12)
  LD C,(IX+$0A)
  ADD A,C
  LD (IX+$0A),A
  LD A,(IX+$13)
  LD C,(IX+$0A)
  ADD A,C
  LD (IX+$0A),A
  RET

; MoveDebris for each of the 8 records whose flags are non-zero
;
; Witness: L1 3602 (c1, death, m2erbe, missions, play, play2).
MoveAllDebris:
  LD IX,DebrisRecords
  LD B,$08
l_D1F2:
  LD A,(IX+$00)
  AND A
  JR Z,l_D1FB
  CALL MoveDebris
l_D1FB:
  LD DE,$0014
  ADD IX,DE
  DJNZ l_D1F2
  RET

; 509 bytes $E5 (PUSH HL) to the end of the block: never run, never read
;
; No recording reads or runs `$D203-$D3FF`; it looks like the tail of an
; unrolled PUSH clear (as ClearBackBuffer `$96F1`) left from development (known
; only from the code).
PushLeftover:
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
