; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 set-up and the interrupt handler: the sprites, the controls, the scroller
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 table, the empty sprite list, the scroller reset, the handler
; installed
;
; 257 bytes of $5B at Im2Table ($FE00-$FF00), so the vector is $5B5B whatever
; the bus holds; JP Interrupt at $5B5B; I = $FE; IM 2. L1 1 (c1).
SetupIM2:
  LD HL,Im2Table
  LD BC,$005B
SetupIM2Table:
  LD (HL),C
  INC HL
  DJNZ SetupIM2Table
  LD (HL),C
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD HL,$0000
  LD (ScrollText),HL
  LD (ScrollNext),HL
  XOR A
  LD (ScrollPriority),A
  LD (ScrollLine),A
  LD A,$01
  LD (ScrollDelay),A
  LD HL,Interrupt
  LD A,$C3
  LD (ImJump),A
  LD (ImJump+1),HL
  LD A,$FE
  LD I,A
  IM 2
  RET

; Never run: LD A,$3F; LD I,A; IM 1; EI; CALL $0D6B (CLS); LD A,7; OUT ($FE),A;
; RET
;
; The way back to BASIC that no code reaches (L1: no run, no read): the I
; register and IM 1 restored, the screen cleared, the border white. A leftover
; of development.
ExitToBasic:
  DEFB $3E,$3F,$ED,$47,$ED,$56,$FB,$CD
  DEFB $6B,$0D,$3E,$07,$D3,$FE,$C9

; Every frame: read the controls, XOR the sprite list, scroll the message, the
; timers, the ROM keyboard
;
; Saves the registers; ReadControls; then each sprite list record from
; SpriteListEnd (graphic, flag pointer, width, rows / 8, screen address): its
; rows are XORed onto the screen and, when a byte of the sprite falls on ink
; already there ((screen AND sprite) is not 0), bit 7 of the flag byte is set
; (InterruptCollide: L1 35 639 of 68 835 sprites). Then the scroller, every
; ScrollDelay frames (5; 15 after a whole text row): the 19-byte window at
; $402C (31 pixel lines) moves up one pixel line and the next pixel row of 19
; characters comes in at the bottom (ScrollScreen): row ScrollLine - 1 of each
; glyph, Font - 1 + 8 x code + ScrollLine. After 8 lines the text moves on 19
; characters; at a '.' the queued message (ScrollNext) starts, or none. Then
; WeaponSelect, EnergyTick, DrainTimer, the ROM's KEYBOARD (FRAMES and LAST_K),
; the registers back, EI, RETI.
;
; Witness: L1 54 811 interrupts; 123 658 list reads; the scroller 8 773 steps.
Interrupt:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  EXX
  PUSH BC
  PUSH DE
  PUSH HL
  CALL ReadControls
InterruptSprite:
  LD HL,(SpriteListEnd)
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,D
  OR E
  JR Z,InterruptScroll
  INC HL
  PUSH HL
  EXX
  POP HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  EXX
  INC HL
  INC HL
  LD A,(HL)
  LD (MoverScratch),A
  INC HL
  LD C,(HL)
  INC HL
  PUSH DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (SpriteListEnd),HL
  EX DE,HL
  POP DE
  SLA C
  SLA C
  SLA C
  LD A,C
  LD C,$00
InterruptSpriteRow:
  PUSH AF
  PUSH HL
  LD A,(MoverScratch)
InterruptSpriteByte:
  PUSH AF
  LD A,(DE)
  LD B,(HL)
  XOR B
  LD (HL),A
  AND B
  CP B
  JR Z,InterruptSpriteNext
  LD C,$80
InterruptSpriteNext:
  INC DE
  INC L
  POP AF
  DEC A
  JR NZ,InterruptSpriteByte
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,InterruptSpriteRowNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,InterruptSpriteRowNext
  LD A,H
  SUB $08
  LD H,A
InterruptSpriteRowNext:
  POP AF
  DEC A
  JR NZ,InterruptSpriteRow
InterruptCollide:
  BIT 7,C
  JR Z,InterruptSprite
  EXX
  LD A,(BC)
  SET 7,A
  LD (BC),A
  EXX
  JR InterruptSprite
InterruptScroll:
  LD HL,ScrollDelay
  DEC (HL)
  JP NZ,InterruptTimers
  LD (HL),$05
  LD A,(ScrollLine)
  INC A
  AND $07
  LD (ScrollLine),A
  CP $00
  JR NZ,InterruptScrollStep
  LD (HL),$0F
InterruptScrollStep:
  LD HL,Screen+44
  LD DE,Screen+300
  LD B,$1F
InterruptScrollLine:
  PUSH BC
  PUSH HL
  PUSH DE
  LD B,$13
InterruptScrollByte:
  LD A,(DE)
  LD (HL),A
  INC L
  INC E
  DJNZ InterruptScrollByte
  POP DE
  INC D
  LD A,D
  AND $07
  JR NZ,InterruptScrollLineNext
  LD A,E
  ADD A,$20
  LD E,A
  LD A,D
  SUB $08
  LD D,A
InterruptScrollLineNext:
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,InterruptScrollLineDone
  LD A,L
  ADD A,$20
  LD L,A
  LD A,H
  SUB $08
  LD H,A
InterruptScrollLineDone:
  POP BC
  DJNZ InterruptScrollLine
  LD (ScrollScreen),HL
  LD HL,(ScrollText)
  LD A,H
  OR L
  JR Z,InterruptScrollEnd
  LD A,(ScrollLine)
  LD DE,Font-$0101
  ADD A,E
  LD E,A
  LD B,$13
InterruptScrollChar:
  LD A,(HL)
  INC HL
  PUSH HL
  LD L,A
  LD H,$00
  SLA L
  RL H
  SLA L
  RL H
  SLA L
  RL H
  ADD HL,DE
  LD A,(HL)
  LD HL,(ScrollScreen)
  LD (HL),A
  INC L
  LD (ScrollScreen),HL
  POP HL
  DJNZ InterruptScrollChar
  LD A,(ScrollLine)
  CP $00
  JR NZ,InterruptTimers
  LD A,(HL)
  CP $2E
  JR NZ,InterruptScrollSet
InterruptScrollEnd:
  LD A,(ScrollPriority)
  CP $00
  JR Z,InterruptScrollNone
  LD A,(ScrollLine)
  CP $00
  JR NZ,InterruptTimers
  LD (ScrollPriority),A
  LD HL,(ScrollNext)
  JR InterruptScrollSet
InterruptScrollNone:
  LD HL,$0000
InterruptScrollSet:
  LD (ScrollText),HL
InterruptTimers:
  CALL WeaponSelect
  CALL EnergyTick
  CALL DrainTimer
  CALL KEYBOARD
  POP HL
  POP DE
  POP BC
  EXX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RETI
