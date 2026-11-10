; --------------------------------------------------------------------------------------------------------------------
; sprite.asm: The sprite renderer and the duck's kill test
;
; DrawSprite draws Harry and the duck: the frame shifted to the pixel, ORed over the background of the map cells under
; it, written to the screen; then the attributes, then the duck test.
; --------------------------------------------------------------------------------------------------------------------

; Draw sprite frame A at (L, H) over the map's background
;
; Inputs: A the frame (Sprites), L = x, H = y. The frame's 16 rows of 2 bytes
; go to SpriteBuffer as rows of 3, shifted right by x AND 7. CellBuffer gets
; the glyphs of the 3 x 3 map cells under (x, y) (LiveMap, CharacterSet), 24
; lines of 3 bytes; the buffer is ORed with the 16 background lines that match
; y AND 7, and the 16 rows of 3 bytes are written from (x, y) down the screen.
; So a sprite erases its old self with the background as it moves one pixel.
; Then the attribute 6 (yellow) on 3 x 3 cells (2 columns at x >= $F1, 2 rows
; when y is on a cell or below $11).
;
; Then the duck test: DuckX within HarryX - 7 .. HarryX + 8 and DuckY within
; HarryY - 8 .. HarryY + 9 kills: it drops the five saved words and every word
; on the stack until one is $A410 or more (the return into PlayLevel, $A656)
; and returns there. Known only from the code: no build was killed by the duck
; ($9BC6 never ran). The test runs for every draw, also while the duck is caged
; on levels 1-8: a Harry at x 0-15 and y 143-160 would touch the caged duck at
; (8, 152).
;
; Witness: 134 270 calls (WalkHarry, ClimbLadder, JumpStep, MoveDuck,
; CatchLift); 18 652-18 859 T unshifted, + about 1244 T a pixel of shift
; (levels-1-3 frames 600-612). Measured in levels-1-3 frames 600-900: Harry
; never read blank by the beam.
DrawSprite:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH IX
  PUSH HL
  LD C,L
  LD HL,Sprites
  LD E,A
  XOR A
  RL E
  RLA
  RL E
  RLA
  RL E
  RLA
  RL E
  RLA
  RL E
  RLA
  LD D,A
  ADD HL,DE
  LD DE,SpriteBuffer
  LD B,$10
  XOR A
DrawSpriteCopy:
  LDI
  LDI
  INC BC
  INC BC
  LD (DE),A
  INC DE
  DJNZ DrawSpriteCopy
  LD A,$07
  AND C
  CP $00
  JR Z,DrawSpriteBack
DrawSpriteShift:
  LD B,$10
  LD HL,SpriteBuffer
DrawSpriteShiftRow:
  SRL (HL)
  INC HL
  RR (HL)
  INC HL
  RR (HL)
  INC HL
  DJNZ DrawSpriteShiftRow
  DEC A
  JR NZ,DrawSpriteShift
DrawSpriteBack:
  POP HL
  PUSH HL
  LD IX,CellBuffer
  EX DE,HL
  LD HL,LiveMap
  LD A,D
  AND $F8
  LD B,$00
  SLA A
  RL B
  SLA A
  RL B
  LD C,A
  ADD HL,BC
  LD B,$00
  LD C,E
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  EX DE,HL
  LD BC,$0303
DrawSpriteCell:
  PUSH BC
  LD HL,CharacterSet
  LD A,(DE)
  LD B,$00
  SLA A
  RL B
  SLA A
  RL B
  SLA A
  RL B
  LD C,A
  ADD HL,BC
  LD B,$08
DrawSpriteGlyph:
  LD A,(HL)
  LD (IX+$00),A
  INC IX
  INC IX
  INC IX
  INC HL
  DJNZ DrawSpriteGlyph
  LD B,$17
DrawSpriteGlyphBack:
  DEC IX
  DJNZ DrawSpriteGlyphBack
  POP BC
  INC DE
  DJNZ DrawSpriteCell
  EX DE,HL
  LD DE,$0023
  AND A
  SBC HL,DE
  LD DE,$0015
  ADD IX,DE
  EX DE,HL
  LD B,$03
  DEC C
  JR NZ,DrawSpriteCell
  POP HL
  PUSH HL
  LD A,H
  AND $07
  XOR $07
  LD H,A
  SLA A
  ADD A,H
  LD C,A
  LD B,$00
  LD HL,CellBuffer
  LD DE,SpriteBuffer
  ADD HL,BC
  LD B,$30
DrawSpriteOr:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC DE
  INC HL
  DJNZ DrawSpriteOr
  POP DE
  PUSH DE
  LD HL,Screen
  LD BC,$0800
  LD A,D
  CP $80
  JR NC,DrawSpriteScreen
  CP $40
  JR NC,DrawSpriteMiddle
  ADD HL,BC
DrawSpriteMiddle:
  ADD HL,BC
DrawSpriteScreen:
  AND $38
  LD C,A
  LD A,$38
  SUB C
  SLA A
  SLA A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,D
  AND $07
  LD C,A
  LD A,$07
  SUB C
  LD D,A
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  EX DE,HL
  LD B,$10
  LD HL,SpriteBuffer
DrawSpriteRow:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(HL)
  LD (DE),A
  INC HL
  DEC E
  DEC E
  INC D
  LD A,D
  AND $07
  JR NZ,DrawSpriteNextRow
  LD A,D
  SUB $08
  LD D,A
  LD A,E
  ADD A,$20
  LD E,A
  JR NC,DrawSpriteNextRow
  LD A,D
  ADD A,$08
  LD D,A
DrawSpriteNextRow:
  DJNZ DrawSpriteRow
  POP HL
  PUSH HL
  LD C,$03
  LD A,L
  CP $F1
  JR C,DrawSpriteAttrs
  DEC C
DrawSpriteAttrs:
  LD B,$03
  LD A,H
  AND $07
  XOR $07
  JR Z,DrawSpriteAttrsTwo
  LD A,H
  CP $11
  JR NC,DrawSpriteAttrAt
DrawSpriteAttrsTwo:
  DEC B
DrawSpriteAttrAt:
  CALL SpriteAttrAddr
  LD DE,$0020
DrawSpriteAttrRow:
  LD IXL,C
  PUSH HL
DrawSpriteAttrCell:
  LD (HL),$06
  INC HL
  DEC IXL
  JR NZ,DrawSpriteAttrCell
  POP HL
  ADD HL,DE
  DJNZ DrawSpriteAttrRow
  LD HL,DuckX
  LD A,(HarryX)
  ADD A,$08
  JR NC,DrawSpriteDuckTest
  LD A,$FF
DrawSpriteDuckTest:
  CP (HL)
  JR C,DrawSpriteDone
  SUB $10
  JR NC,DrawSpriteDuckX
  XOR A
DrawSpriteDuckX:
  CP (HL)
  JR NC,DrawSpriteDone
  INC HL
  LD A,(HarryY)
  ADD A,$09
  CP (HL)
  JR C,DrawSpriteDone
  SUB $12
  JR NC,DrawSpriteDuckY
  XOR A
DrawSpriteDuckY:
  CP (HL)
  JR NC,DrawSpriteDone
  LD B,$05
DuckKill:
  POP HL                  ; drop five words, then unwind to the game flow
  DJNZ DuckKill
  LD BC,Start
DuckKillUnwind:
  POP HL
  PUSH HL
  AND A
  SBC HL,BC
  RET NC
  POP HL
  JR DuckKillUnwind
DrawSpriteDone:
  POP HL
  POP IX
  POP DE
  POP BC
  POP AF
  RET

; HL = the attribute address of pixel (L, H)
;
; As AttrAddrHen $93DD. Witness: 134 267 calls (DrawSprite).
SpriteAttrAddr:
  PUSH AF
  PUSH DE
  LD A,$BF
  SUB H
  LD H,$00
  EX DE,HL
  LD HL,Attributes
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  AND $F8
  SLA A
  RL D
  SLA A
  RL D
  LD E,A
  ADD HL,DE
  POP DE
  POP AF
  RET

; 65 zeros
;
; Never read (L1: no access).
Zeros9BFF:
  DEFS $41
