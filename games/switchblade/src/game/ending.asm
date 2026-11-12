; --------------------------------------------------------------------------------------------------------------------
; ending.asm: Havok and the end
; --------------------------------------------------------------------------------------------------------------------

; The end picture's actor: draw it, and once its timer has run out fade it,
; then the end text
;
; IY = the actor. While +$10 bit 5 (its 16-bit timer, GameTick) is clear:
; DrawHavok. Then each pass the mask (the AND n operand at $878F, $FF at the
; start) - 1, effect 4 every 16 steps, DrawHavok with the mask; at 0: the actor
; off (+2 = 0), DelayBC 65 536, CALL $9962, $6652 bit 6 set (fire now ends the
; game, GameTick), EndText printed. Returns with POP BC / POP HL / RET (out of
; the actor dispatch $8E2B).
;
; Witness: L1 825 (havok, rzx x2): havok kills Havok with his hit points POKEd
; to 1 at frame 20.
HavokFade:
  LD A,(IY+$10)
  BIT 5,A
  JR NZ,HavokFadeStep
  CALL DrawHavok
HavokFadeReturn:
  POP BC
  POP HL
  RET
HavokFadeStep:
  LD A,(DrawHavokByte+$0002)
  DEC A
  LD (DrawHavokByte+$0002),A
  PUSH AF
  AND $0F
  JR NZ,HavokFadeDraw
  LD A,$04
  LD (EffectRequest),A
HavokFadeDraw:
  CALL DrawHavok
  POP AF
  JR NZ,HavokFadeReturn
  LD (IY+$02),$00
  LD BC,$0000
  CALL DelayBC
  CALL SpawnShield
  LD HL,EndFlags
  SET 6,(HL)
  LD HL,EndText
  CALL PrintString
  JR HavokFadeReturn

; Draw the 48 x 80 picture from $7F23 (or $7F3B when Y AND 7 = 0) at the
; actor's place, ANDed with the fade mask
;
; E = +$2C, A = +$2A: SpriteScreenAddress; ShiftHavokGraphic; 10 character rows
; of 8 lines of 6 bytes, each byte AND the mask at $878F.
;
; Witness: L1 825 (havok, rzx x2).
DrawHavok:
  LD E,(IY+$2C)
  LD A,(IY+$2A)
  CALL SpriteScreenAddress
  CALL ShiftHavokGraphic
  LD HL,FirebladeIcons+$0006
  LD A,(IY+$00)
  AND $07
  JR NZ,DrawHavokRows
  LD BC,$0018
  ADD HL,BC
DrawHavokRows:
  LD B,$0A
DrawHavokRow:
  PUSH BC
  LD C,D
  LD A,$08
DrawHavokLine:
  PUSH AF
  PUSH DE
  LD B,$06
DrawHavokByte:
  LD A,(HL)               ; AND n: n ($878F) the fade mask
  AND $FF
  LD (DE),A
  INC HL
  INC E
  DJNZ DrawHavokByte
  POP DE
  INC D
  POP AF
  DEC A
  JR NZ,DrawHavokLine
  LD A,$20
  ADD A,E
  LD E,A
  JR C,DrawHavokNextRow
  LD D,C
DrawHavokNextRow:
  POP BC
  DJNZ DrawHavokRow
  RET

; Rotate HavokPicture's 384 bytes left or right by the change of the actor's
; pixel phase
;
; The phase (3 x +$2A) AND 7 against the last one (the operand at $87AC): left
; by RL from $80FC down, right by RR from $7F7D up, one pass a pixel; DE back
; to the column (L / 8 added).
;
; Witness: L1 825 (havok, rzx x2).
ShiftHavokGraphic:
  LD A,E
  AND $E0
  LD E,A
  PUSH DE
  LD A,$00
  LD B,A
  LD A,(IY+$2A)
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  AND $07
  LD (ShiftHavokGraphic+$0006),A
  SUB B
  PUSH BC
  JR Z,ShiftHavokDone
  JP P,ShiftHavokRight
  NEG
  LD C,A
  EX AF,AF'
  LD A,C
  OR A
ShiftHavokLeft:
  EX AF,AF'
  LD HL,HavokPicture+383
  LD BC,$0180
ShiftHavokLeftByte:
  EX AF,AF'
  RL (HL)
  EX AF,AF'
  DEC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,ShiftHavokLeftByte
  EX AF,AF'
  DEC A
  JR NZ,ShiftHavokLeft
  JR ShiftHavokDone
ShiftHavokRight:
  LD C,A
  EX AF,AF'
  LD A,C
  OR A
ShiftHavokRightPass:
  EX AF,AF'
  LD HL,HavokPicture
  LD BC,$0180
ShiftHavokRightByte:
  EX AF,AF'
  RR (HL)
  EX AF,AF'
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,ShiftHavokRightByte
  EX AF,AF'
  DEC A
  JR NZ,ShiftHavokRightPass
ShiftHavokDone:
  POP HL
  POP DE
  SRL L
  SRL L
  SRL L
  LD H,A
  ADD HL,DE
  EX DE,HL
  RET
