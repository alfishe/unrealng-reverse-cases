; --------------------------------------------------------------------------------------------------------------------
; horizon.asm: The horizons: the stage's picture above the road, rotated sideways in the bends
;
; Three pictures, 32 bytes a line: Dunes ($E2C0, 25 lines, stage 3), Mountains ($E5E0, 32 lines, stages 1 and 4),
; Clouds ($E9E0, 9 lines, stages 2 and 5) (StageTable). DrawHorizon copies the stage's picture into the back buffer
; above the road and clears the lines between it and the top of what was drawn (ClearLines pushes zeros with SP as the
; pointer). On a curve the picture itself is rotated: HorizonScrollStep adds the curve's speed to HorizonScroll and
; rotates the picture in place by the whole pixels gained, through RotateTable: by 4 pixels (RRD / RLD) and by 1 (RR /
; RL), right or left; whole bytes (RotateBytesRight / Left) would serve steps of 8 and more, which never come.
; --------------------------------------------------------------------------------------------------------------------

  ORG $9211

; Rotate C lines of the picture at HL right by one pixel (32 bytes a line, the
; last bit wraps to the first)
;
; Recorded: c1, stages: in every bend.
;
; Witness: L1 42826 (c1, crash, m128, stages, tech-brake-bend, tech-cheat,
; tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
RotateRight1:
  AND A
  LD E,L
  LD D,H
  LD B,$04
l_9216:
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC L
  RR (HL)
  INC HL
  DJNZ l_9216
  JR NC,l_9236
  LD A,(DE)
  OR $80
  LD (DE),A
l_9236:
  DEC C
  JP NZ,RotateRight1
  RET

; Rotate C lines left by one pixel (HL at a line's last byte; the next line 64
; bytes on)
;
; Witness: L1 25206 (c1, crash, fall5, stages, truck).
RotateLeft1:
  AND A
  LD E,L
  LD D,H
  LD B,$04
l_9240:
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC HL
  DJNZ l_9240
  JR NC,l_925F
  EX DE,HL
  INC (HL)
  EX DE,HL
l_925F:
  LD DE,$0040
  ADD HL,DE
  DEC C
  JP NZ,RotateLeft1
  RET

; Rotate C lines right by four pixels (RRD along the line, the last nibble
; wraps)
;
; Witness: L1 3033 (stages).
RotateRight4:
  XOR A
  LD E,L
  LD D,H
  LD B,$04
l_926D:
  RRD
  INC L
  RRD
  INC L
  RRD
  INC L
  RRD
  INC L
  RRD
  INC L
  RRD
  INC L
  RRD
  INC L
  RRD
  INC HL
  DJNZ l_926D
  EX DE,HL
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  OR (HL)
  LD (HL),A
  EX DE,HL
  DEC C
  JP NZ,RotateRight4
  RET

; Rotate C lines left by four pixels (RLD)
;
; Witness: L1 2100 (stages).
RotateLeft4:
  XOR A
  LD E,L
  LD D,H
  LD B,$04
l_9299:
  RLD
  DEC L
  RLD
  DEC L
  RLD
  DEC L
  RLD
  DEC L
  RLD
  DEC L
  RLD
  DEC L
  RLD
  DEC L
  RLD
  DEC HL
  DJNZ l_9299
  EX DE,HL
  OR (HL)
  LD (HL),A
  EX DE,HL
  LD DE,$0040
  ADD HL,DE
  DEC C
  JP NZ,RotateLeft4
  RET

; Rotate C lines right by whole bytes
;
; Known only from the code: a step of 8 pixels in one pass never happened (the
; bend's push stays below it).
RotateBytesRight:
  LD E,L
  LD D,H
  DEC L
  LD A,(DE)
  EX AF,AF'
  LD A,$03
l_92C7:
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  DEC A
  JP NZ,l_92C7
  LDD
  EX AF,AF'
  LD (DE),A
  LD DE,$0040
  ADD HL,DE
  LD A,B
  OR C
  JP NZ,RotateBytesRight
  RET

; Rotate C lines left by whole bytes
;
; Known only from the code.
RotateBytesLeft:
  LD E,L
  LD D,H
  INC L
  LD A,(DE)
  EX AF,AF'
  LD A,$03
l_92F4:
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC A
  JP NZ,l_92F4
  LDI
  EX AF,AF'
  LD (DE),A
  LD A,B
  OR C
  JP NZ,RotateBytesLeft
  RET

; Eight left-edge masks ($00, $80, $C0 ... $FE), read by no instruction
;
; Known only from the code: no operand points here and L1 has no read after the
; load; DotMasks ($9CAF) is the table the game uses.
MaskTable:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE

  ORG $99F0

; HorizonScroll += HorizonSpeed / 2; rotate the picture by the whole pixels
; gained, right or left
;
; HorizonSpeed is the LD DE operand ($99F1) BikeLateral writes (the bend and
; the speed). The pixels: 8 at a time (RotateBytes, never), then 4
; (RotateRight4 / RotateLeft4), then 1, through RotateTable's entries (offset,
; routine).
;
; Recorded: c1: each pass in a bend.
;
; Witness: L1 5182 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
HorizonScrollStep:
  LD DE,$0000
  SRA D
  RR E
  LD A,(HorizonRows)
  LD C,A
  LD HL,(HorizonScroll)
  LD A,H
  ADD HL,DE
  LD (HorizonScroll),HL
  SUB H
  LD IY,RotateTable
  BIT 7,A
  JR Z,l_9A12
  NEG
  LD IY,RotateTable+$0009
l_9A12:
  AND A
  RET Z
; This entry point is used by the routine at HorizonBytes.
l_9A14:
  SUB $08
  JR C,l_9A3A

; Steps of 8 pixels: RotateBytes for C lines (C * 31 bytes)
;
; Known only from the code.
HorizonBytes:
  LD HL,(HorizonAddr)
  PUSH BC
  PUSH AF
  LD A,(IY+$00)
  ADD A,L
  LD L,A
  LD A,C
  LD B,$00
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  RL B
  ADD A,A
  RL B
  SUB C
  JR NC,l_9A32
  DEC B
l_9A32:
  LD C,A
  CALL HorizonRotate
  POP AF
  POP BC
  JR l_9A14
; This entry point is used by the routine at HorizonScrollStep.
l_9A3A:
  INC IY                  ; steps of 4
  INC IY
  INC IY
  ADD A,$08
  RET Z
l_9A43:
  SUB $04
  JR C,l_9A58
  PUSH AF
  PUSH BC
  LD HL,(HorizonAddr)
  LD A,(IY+$00)
  ADD A,L
  LD L,A
  CALL HorizonRotate
  POP BC
  POP AF
  JR l_9A43
l_9A58:
  INC IY
  INC IY
  INC IY
  ADD A,$04
  RET Z
l_9A61:
  PUSH AF
  PUSH BC
  LD HL,(HorizonAddr)
  LD A,(IY+$00)
  ADD A,L
  LD L,A
  CALL HorizonRotate
  POP BC
  POP AF
  DEC A
  JR NZ,l_9A61
  RET

; JP to the routine of RotateTable's entry IY (HL = HorizonAddr + the entry's
; offset)
;
; Witness: L1 3230 (c1, crash, fall5, m128, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
HorizonRotate:
  LD E,(IY+$01)
  LD D,(IY+$02)
  PUSH DE
  POP IX
  JP (IX)

; Six entries (offset, routine): right 8, 4, 1 (RotateBytesRight $1F,
; RotateRight4, RotateRight1); left 8, 4, 1
RotateTable:
  DEFB $1F,$C0,$92
  DEFB $00,$68,$92
  DEFB $00,$11,$92
  DEFB $00,$ED,$92
  DEFB $1F,$94,$92
  DEFB $1F,$3B,$92

  ORG $9E3A

; HorizonAddr, HorizonRows, HorizonBottom from StageTable[Stage]; the clear
; count $C0 - rows - top
;
; Witness: L1 54 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).
SetHorizon:
  LD L,$04
  LD A,(Stage)
  CALL Multiply
  LD IX,StageTable
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (HorizonAddr),HL
  LD A,(IX+$02)
  LD (HorizonRows),A
  LD H,A
  LD A,(IX+$03)
  LD (HorizonBottom),A
  LD L,A
  LD A,$C0
  SUB H
  SUB L
  LD (l_9E9F+$0046),A
  RET

; The five stages' horizons: the picture's address (a word), its lines, its top
; line (5 x 4 bytes)
;
; Mountains/32/$50, Clouds/9/$53, Dunes/25/$57, Mountains/32/$50, Clouds/9/$5A.
; src/res/tables/stages.csv.
StageTable:
  INCBIN "res/tables/stages.bin",$0000,20

; From TopClip: draw the horizon's lines into the back buffer and clear the
; lines above it
;
; Witness: L1 5137 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawHorizon:
  LD A,(TopClip)

; from line A (StartRace: 40)
;
; Witness: L1 5162 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
DrawHorizonAt:
  LD L,A
  LD A,(HorizonBottom)
  LD C,A
  SUB L
  JR NC,l_9E88

; The top line below the horizon's bottom: no picture lines (B = 0 path)
;
; Known only from the code: TopClip never went below the horizon.
HorizonHidden:
  LD L,C
  XOR A
; This entry point is used by the routine at DrawHorizonAt.
l_9E88:
  LD B,A                  ; B = the picture's lines to draw
  LD H,$7F
  ADD HL,HL
  LD (SavedSp),SP
  LD SP,HL
  XOR A
  CP B
  LD IY,l_9E88+$0011
  JR NZ,ClearLines
  LD A,(HorizonRows)
  LD HL,(HorizonAddr)
l_9E9F:
  POP DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC A
  JP NZ,l_9E9F
  LD B,$01
  LD IY,l_9E9F+$004D
  JR ClearLines
  LD SP,(SavedSp)
  RET
ClearLines:
  LD C,A                  ; clear B lines: SP = each line's end, 16 PUSH of
                          ; zeros, then JP (IY)
  LD L,C
  LD H,C
  ADD HL,SP
  EX DE,HL
l_9EF6:
  LD A,(DE)
  ADD A,$20
  LD L,A
  INC E
  LD A,(DE)
  INC DE
  ADC A,C
  LD H,A
  LD SP,HL
  LD L,C
  LD H,C
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ l_9EF6
  EX DE,HL
  LD SP,HL
  JP (IY)
