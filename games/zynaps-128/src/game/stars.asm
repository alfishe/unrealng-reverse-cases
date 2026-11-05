; --------------------------------------------------------------------------------------------------------------------
; stars.asm: The star field: one star per playfield row
;
; Each playfield row carries one star in its record (+$18-+$1F): a random speed and position, a colour of $44-$47
; (bright green paper bits XOR random), drawn by RowStar. The stars move only while the playfield scrolls (PlayFlags
; $81DA bit 5) and are shown only when PlayFlags bit 7 is set.
; --------------------------------------------------------------------------------------------------------------------

; Give each of the 18 rows a random star
;
; Walks the records from the top with SP at record + $20 and pushes, per row:
; +$1E/+$1F = F and the colour ($47 XOR Random AND 3), +$1C/+$1D = L the row's
; screen low byte ($20, $40, ...) and H = $20, +$1A/+$1B = the speed (B = 16-47
; from Random, C = $E0), +$18/+$19 = E (Random bits 3-6 moved to 4-7, OR $80)
; and D = $FF.
;
; MoveStars rewrites the fields every frame: +$1C = the cell's low byte and
; +$1D = the dot byte that RowStar draws, +$1E carry = visible.
;
; Saves and restores SP through the operand of InitStarsDone. Output: all
; registers changed.
;
; Called by LevelSetUp ($8D30) and StarsSwitch.
InitStars:
  LD (InitStarsDone+$0001),SP
  LD C,$E0
  LD D,$FF
  LD HL,$2020
  EXX
  LD B,$12
  LD HL,RowRecords+$0020
  LD DE,$0020
InitStarLoop:
  LD SP,HL
  ADD HL,DE
  EXX
  CALL Random
  LD E,A
  AND $03
  XOR $47
  PUSH AF
  PUSH HL
  LD A,L
  ADD A,H
  LD L,A
  CALL Random
  AND $1F
  ADD A,$10
  LD B,A
  PUSH BC
  LD A,E
  RRCA
  RRCA
  RRCA
  AND $F0
  OR $80
  LD E,A
  PUSH DE
  EXX
  DJNZ InitStarLoop
InitStarsDone:
  LD SP,$0000             ; LD SP,n: n = the caller's SP
  RET

; Turn the stars on (A = 1) or off (A = other) and restart them
;
; LD HL,$81DA; DEC A; set (A = 1) or reset PlayFlags bit 7; CALL InitStars. Not
; entered in 48K c1 or 48K c2: no caller found in the image (a leftover or a
; cheat entry).
StarsSwitch:
  LD HL,PlayFlags
  DEC A
  JR Z,StarsOn
  RES 7,(HL)
  JR StarsRestart
StarsOn:
  SET 7,(HL)              ; SET 7: the stars shown
StarsRestart:
  CALL InitStars
  RET

; Move every star and respawn the ones that left the screen
;
; Writes the opcode of the dot-making instruction: XOR $F8 gives SET n,B
; (PlayFlags bit 7 set: stars shown), XOR $B8 gives RES n,B (no dot: the stars
; stay invisible). Saves SP into MoveStarsDone.
;
; Per row (SP = the star fields): while scrolling (PlayFlags bit 5) the 16-bit
; position += speed (wrapping); a position below $1000 respawns the star (new
; random colour and speed). The pixel bit within the byte comes from the
; position's low bits (written into StarDot's opcode), the screen byte from its
; high bits.
;
; Called by the frame handler (48K c2: 659 entries, 37 per mille).
MoveStars:
  LD HL,PlayFlags
  BIT 7,(HL)
  LD A,$F8
  JR NZ,StarsShownMode
  LD A,$B8
StarsShownMode:
  LD (StarDotOpcode+$0001),A ; store the XOR value into StarDotOpcode's operand
  LD (MoveStarsDone+$0001),SP
  LD HL,PlayFlags
  LD C,(HL)
  LD B,$12
  LD HL,RowRecords+$0018
  LD DE,$0020
  LD SP,RowRecords
MoveStarLoop:
  EXX
  POP DE
  EXX
  LD SP,HL
  ADD HL,DE
  BIT 5,C
  EXX
  POP BC
  POP HL
  JR Z,StarCheckEdge
  ADD HL,BC
StarCheckEdge:
  LD A,H                  ; off the left edge?
  SUB $10
  JR NC,StarPlace
  CALL Random
  LD C,A
  LD HL,$2FE0
  PUSH HL
  RRCA
  RRCA
  RRCA
  AND $F0
  OR $80
  LD L,A
  LD H,B
  PUSH HL
  LD A,C
  AND $03
  XOR $47
  POP HL
  POP HL
  POP BC
  INC SP
  INC SP
  PUSH AF
  PUSH BC
  LD A,$1F
StarPlace:
  POP BC
  XOR C
  AND $1F
  XOR C
  LD C,A
  LD A,L
  LD B,$00
  AND $E0
  RRCA
  RRCA
StarDotOpcode:
  XOR $F8                 ; XOR n: n = $F8 (SET) or $B8 (RES), written at $889F
  LD (StarDot+$0001),A
StarDot:
  SET 0,B                 ; SET n,B: the bit number written at $88F6
  LD A,E
  SUB $2F
  ADD A,H
  LD E,A
  LD A,(DE)
  CP $01
  POP DE
  LD A,D
  PUSH AF
  PUSH BC
  PUSH HL
  POP AF
  POP AF
  POP AF
  EXX
  DJNZ MoveStarLoop
MoveStarsDone:
  LD SP,$0000             ; LD SP,n: n = the caller's SP
  RET
