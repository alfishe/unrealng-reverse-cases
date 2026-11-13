; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The sprite blitters: CPC mode-1 graphics drawn on the Spectrum screen, and their colour cells
;
; The game keeps the Amstrad CPC's graphics and screen addresses. A sprite is CPC mode-1 bytes, ($A9FE) bytes a line
; (4 pixels each, two bit planes) and B lines; its place is a CPC screen address ($C000 + line%8 x $800 + row x 80 +
; byte). The blitters turn the address into a pixel line and a CPC byte column ($C71F), take the Spectrum line address
; from the line table ($B515: IX = $B52D + 2 x line, $B52C = column / 2) and pack two CPC bytes into one Spectrum
; byte: the low nibbles (one bit plane, pens 2 and 3 show as ink) for the sprites, the high nibbles for the bricks. An
; odd CPC column starts with a half byte.
;
; Store (DrawSprite), XOR (XorSprite) and XOR of the high nibbles (XorBricks), each with a variant that then colours
; the cells the sprite covers (PaintAttrs). Interrupts are off while a sprite is drawn.
; --------------------------------------------------------------------------------------------------------------------

  ORG $E2A0

; Draw a sprite (store) and colour the cells it covers
;
; DrawSprite $E318 (DE the CPC screen address, HL the graphics, B the lines,
; ($A9FE) the width in CPC bytes), then PaintAttrs $E2A3 with the attribute in
; C.
;
; Witness: L1 89434 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx34,
; rzx36-rzx44, rzx46-rzx99).
DrawSpriteColoured:
  CALL DrawSprite

; Colour the cells under the sprite just drawn with the attribute C
;
; Input: C the attribute (bit 7 set: the area is 8 lines taller), the place
; left by $C71F ($C74F the CPC character row, $C750 the CPC byte column), the
; height in lines at SpriteHeight $E3E4 and the width at $A9FE. Nothing is done
; when C's ink (bits 0-2) is 0.
;
; The cells are rows ($C74F - 1) onwards (a sprite starting in CPC row 0, above
; the Spectrum screen, loses its first 8 lines), columns $C750 / 2 onwards,
; ((width + column bit 0 + 1) / 2) cells wide and (height + 7) / 8 rows high;
; each gets C (bit 7 cleared), written into the operand of the LD (HL),n at
; $E30E before the loop. Output: the attributes; $E3E4 and $C74F changed.
;
; Witness: L1 275682 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PaintAttrs:
  LD A,C
  AND $07
  RET Z
  BIT 7,C
  JR Z,PaintAttrsSkip
  RES 7,C
  LD A,(SpriteHeight)
  ADD A,$08
  LD (SpriteHeight),A
PaintAttrsSkip:
  LD A,(CharRow)
  AND A
  JR NZ,PaintAttrsSkip2
  INC A
  LD (CharRow),A
  LD A,(SpriteHeight)
  SUB $08
  RET C
  LD (SpriteHeight),A
  LD A,(CharRow)
  INC A
  LD (CharRow),A
PaintAttrsSkip2:
  DEC A
  SLA A
  SLA A
  SLA A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD A,(ByteColumn)
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,$5800
  ADD HL,DE
  LD A,C
  LD (PaintAttrsLoop2+$0001),A
  LD A,(ByteColumn)
  AND $01
  LD C,A
  LD A,(SpriteWidth)
  ADD A,C
  INC A
  SRL A
  LD C,A
  LD A,$20
  SUB C
  LD E,A
  LD D,$00
  LD A,(SpriteHeight)
  ADD A,$07
  SRL A
  SRL A
  SRL A
  LD B,A
PaintAttrsLoop:
  LD A,B
  LD B,C
PaintAttrsLoop2:
  LD (HL),$06
  INC HL
  DJNZ PaintAttrsLoop2
  ADD HL,DE
  LD B,A
  DJNZ PaintAttrsLoop
  RET

; Draw a CPC sprite on the screen, storing its bytes
;
; Input: DE the CPC screen address, HL the graphics, B the lines, ($A9FE) the
; width in CPC bytes. B goes to SpriteHeight $E3E4. Each line: the Spectrum
; address from the line table, then width / 2 bytes, each (first byte << 4) |
; (second byte & $0F), and for an odd width a last half byte (first byte << 4).
; An odd CPC column ($C750 bit 0) starts with the low nibble of one byte alone
; and ends with a high-nibble byte when the width is even. Output: carry clear,
; BC kept; IY kept; the screen bytes stored. Interrupts are off from $E32A and
; on again at the end.
;
; Witness: L1 91481 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
DrawSprite:
  PUSH BC
  PUSH IX
  PUSH HL
  PUSH BC
  LD A,B
  LD (SpriteHeight),A
  EX DE,HL
  CALL ScreenAddrToLine
  CALL LineAddress
  POP BC
  POP HL
  DI
  PUSH IY
  PUSH HL
  POP IY
  LD A,(SpriteWidth)
  LD H,A
  LD A,(SpectrumColumn)
  LD L,A
  LD A,(ByteColumn)
  BIT 0,A
  JR NZ,DrawSpriteLoop3
DrawSpriteLoop:
  PUSH BC
  LD A,(IX+$00)
  LD D,(IX+$01)
  OR L
  LD E,A
  LD B,H
  SRL B
  LD A,B
  AND A
  JR Z,DrawSpriteSkip
DrawSpriteLoop2:
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  LD C,A
  INC IY
  LD A,(IY+$00)
  AND $0F
  OR C
  INC IY
  LD (DE),A
  INC DE
  DJNZ DrawSpriteLoop2
DrawSpriteSkip:
  BIT 0,H
  JR Z,DrawSpriteSkip2
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  INC IY
  LD (DE),A
  INC DE
DrawSpriteSkip2:
  INC IX
  INC IX
  POP BC
  DJNZ DrawSpriteLoop
  AND A
  POP IY
  EI
  POP IX
  POP BC
  RET
DrawSpriteLoop3:
  PUSH BC
  LD A,(IX+$00)
  LD D,(IX+$01)
  OR L
  LD E,A
  LD A,(IY+$00)
  AND $0F
  INC IY
  LD (DE),A
  INC DE
  LD B,H
  SRL B
  DEC B
  LD A,B
  AND A
  JR Z,DrawSpriteSkip3
  JP M,DrawSpriteSkip3
DrawSpriteLoop4:
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  LD C,A
  INC IY
  LD A,(IY+$00)
  AND $0F
  OR C
  INC IY
  LD (DE),A
  INC DE
  DJNZ DrawSpriteLoop4
DrawSpriteSkip3:
  BIT 0,H
  JR NZ,DrawSpriteSkip4
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  INC IY
  LD (DE),A
  INC DE
DrawSpriteSkip4:
  INC IX
  INC IX
  POP BC
  DJNZ DrawSpriteLoop3
  AND A
  POP IY
  EI
  POP IX
  POP BC
  RET

; The height in lines of the last sprite drawn (PaintAttrs takes it)
SpriteHeight:
  DEFB $01

; XOR a sprite onto the screen and colour its cells
;
; XorSprite $E3EE (HL the CPC screen address, DE the graphics, B the lines),
; then PaintAttrs $E2A3 with C.
;
; Witness: L1 186047 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
XorSpriteColoured:
  PUSH BC
  CALL XorSprite
  POP BC
  CALL PaintAttrs
  RET

; XOR a CPC sprite onto the screen
;
; As DrawSprite $E318, but the screen address is in HL and the graphics in DE,
; and each byte is XORed into the screen: drawing twice removes the sprite. The
; last half byte of an odd width at an even column ($E442) never ran: no sprite
; of odd width is XORed there.
;
; Witness: L1 228035 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
XorSprite:
  PUSH IX
  PUSH DE
  PUSH BC
  LD A,B
  LD (SpriteHeight),A
  CALL ScreenAddrToLine
  CALL LineAddress
  POP BC
  POP DE
  DI
  PUSH IY
  PUSH DE
  POP IY
  LD A,(SpriteWidth)
  LD D,A
  LD A,(SpectrumColumn)
  LD E,A
  LD A,(ByteColumn)
  BIT 0,A
  JR NZ,XorSpriteLoop3
XorSpriteLoop:
  PUSH BC
  LD A,(IX+$00)
  LD H,(IX+$01)
  OR E
  LD L,A
  LD B,D
  SRL B
  LD A,B
  AND A
  JR Z,XorSpriteSkip
XorSpriteLoop2:
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  LD C,A
  INC IY
  LD A,(IY+$00)
  AND $0F
  OR C
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
  DJNZ XorSpriteLoop2
XorSpriteSkip:
  BIT 0,D
  JR Z,XorSpriteSkip2
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
XorSpriteSkip2:
  INC IX
  INC IX
  POP BC
  DJNZ XorSpriteLoop
  AND A
  POP IY
  EI
  POP IX
  RET
XorSpriteLoop3:
  PUSH BC
  LD A,(IX+$00)
  LD H,(IX+$01)
  OR E
  LD L,A
  LD A,(IY+$00)
  AND $0F
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
  LD B,D
  SRL B
  DEC B
  LD A,B
  AND A
  JR Z,XorSpriteSkip3
  JP M,XorSpriteSkip3
XorSpriteLoop4:
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  LD C,A
  INC IY
  LD A,(IY+$00)
  AND $0F
  OR C
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
  DJNZ XorSpriteLoop4
XorSpriteSkip3:
  BIT 0,D
  JR NZ,XorSpriteSkip4
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  SLA A
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
XorSpriteSkip4:
  INC IX
  INC IX
  POP BC
  DJNZ XorSpriteLoop3
  AND A
  POP IY
  EI
  POP IX
  RET

; XOR a brick graphic and colour its cells
;
; XorBricks $E4C4, then PaintAttrs $E2A3 with C. The only caller is the brick
; drawing at $D1A6.
;
; Witness: L1 204 (fire, l98, rzx x6).
XorBricksColoured:
  PUSH BC
  CALL XorBricks
  POP BC
  CALL PaintAttrs
  RET

; XOR a CPC graphic onto the screen from its high nibbles
;
; As XorSprite $E3EE, but each Spectrum byte is (first byte & $F0) | (second
; byte >> 4): the other bit plane of the CPC graphic. The odd-column path
; $E530-$E58A never ran (the bricks lie at even columns).
;
; Witness: L1 204 (fire, l98, rzx x6).
XorBricks:
  PUSH IX
  PUSH DE
  PUSH BC
  LD A,B
  LD (SpriteHeight),A
  CALL ScreenAddrToLine
  CALL LineAddress
  POP BC
  POP DE
  DI
  PUSH IY
  PUSH DE
  POP IY
  LD A,(SpriteWidth)
  LD D,A
  LD A,(SpectrumColumn)
  LD E,A
  LD A,(ByteColumn)
  BIT 0,A
  JR NZ,XorBricksLoop3
XorBricksLoop:
  PUSH BC
  LD A,(IX+$00)
  LD H,(IX+$01)
  OR E
  LD L,A
  LD B,D
  SRL B
  LD A,B
  AND A
  JR Z,XorBricksSkip
XorBricksLoop2:
  LD A,(IY+$00)
  AND $F0
  INC IY
  LD C,A
  LD A,(IY+$00)
  SRL A
  SRL A
  SRL A
  SRL A
  OR C
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
  DJNZ XorBricksLoop2
XorBricksSkip:
  BIT 0,D
  JR Z,XorBricksSkip2
  LD A,(IY+$00)
  AND $F0
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
XorBricksSkip2:
  INC IX
  INC IX
  POP BC
  DJNZ XorBricksLoop
  AND A
  POP IY
  EI
  POP IX
  RET
XorBricksLoop3:
  PUSH BC
  LD A,(IX+$00)
  LD H,(IX+$01)
  OR E
  LD L,A
  LD A,(IY+$00)
  SRL A
  SRL A
  SRL A
  SRL A
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
  LD B,D
  SRL B
  DEC B
  LD A,B
  AND A
  JR Z,XorBricksSkip3
  JP M,XorBricksSkip3
XorBricksLoop4:
  LD A,(IY+$00)
  AND $F0
  INC IY
  LD C,A
  LD A,(IY+$00)
  SRL A
  SRL A
  SRL A
  SRL A
  OR C
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
  DJNZ XorBricksLoop4
XorBricksSkip3:
  BIT 0,D
  JR NZ,XorBricksSkip4
  LD A,(IY+$00)
  AND $F0
  INC IY
  XOR (HL)
  LD (HL),A
  INC HL
XorBricksSkip4:
  INC IX
  INC IX
  POP BC
  DJNZ XorBricksLoop3
  AND A
  POP IY
  EI
  POP IX
  RET
