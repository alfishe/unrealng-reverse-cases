; --------------------------------------------------------------------------------------------------------------------
; playfield.asm: The playfield renderer: attributes, glyph spans, sprite strips and stars, row by row
;
; The playfield is 18 character rows of 32 columns. Nothing is drawn pixel by pixel: every row is a chain of span
; nodes, each naming a run of 0-4 glyphs out of the glyph cache ($C000-$DFFF) and the gap of empty columns before it.
;
; The glyph cache holds 256 glyphs in four copies, shifted by 0, 2, 4 and 6 pixels (pages $C0, $C8, $D8, $D0). A glyph
; is line-interleaved: line k of glyph n is at page + k*256 + n. ShiftPage ($7F6A) picks the copy for the current
; scroll phase, so a span handler only copies bytes: LDI and LDD alternate (zigzag) across the run, one pixel line
; after another.
;
; Each row has a 32-byte record at $F12C + 32*row (RowRecords): the map ring pointer, the attribute and screen
; addresses, the head node, counters for the scroll step and the column builder, the sprite-strip list and the row's
; star. The renderer runs with SP pointing at the record and POPs its fields.
;
; Per row: one beeper toggle (the in-game engine hum: RowBeep $7F7E XOR $18, AND the mask $7F7F, OUT $FE), the 32
; attributes pushed from the map ring onto the attribute row, the span nodes, the sprite strips, the star, then a
; delay that pads every row to the cost of at least four glyphs, so the 18 toggles are evenly spaced.
; --------------------------------------------------------------------------------------------------------------------

; Draw the 18 rows of the playfield
;
; Saves SP into the operand of RenderDone, clears the padding balance (the
; operand of RowEnd), sets RowsLeft ($7F6F) = 18 and IX = SP = $F12C (the first
; row record), then enters RowStart.
;
; The rows run as a chain of RETs: RowStart pushes the attributes and returns
; into the row's head span node; each span handler returns into the next node;
; the sentinel node ($85E4) returns into RowEnd; RowEnd moves to the next
; record and jumps to RowStart or, after 18 rows, to RenderDone.
;
; Called from the frame handler $A9ED once a frame while playing (c2: 659
; entries in 1500 frames, all from $A9ED).
DrawPlayfield:
  LD (RenderDone+$0001),SP
  XOR A
  LD (RowEnd+$0001),A
  LD A,$12
  LD (RowsLeft),A
  LD IX,RowRecords
  LD SP,IX
  JP RowStart

; Restore the stack pointer and return to the frame handler
;
; The operand of LD SP is the SP that DrawPlayfield saved.
RenderDone:
  LD SP,$0000
  RET

; The span node that ends every row: handler RowEnd, then a 0 byte
;
; A three-byte node: the word $85E7 (RowEnd) and a 0. An empty row's head field
; (+6/+7 of its record) points here; the last node of every row links here.
; LevelSetUp writes it into all 18 records.
SentinelNode:
  DEFB $E7,$85,$00

; End of a row: sprite strips, the star, padding, next row
;
; Reached by RET from the last span node. A = the padding balance (the operand,
; written at $86BD) + the row's glyph count (+8); kept in A'.
;
; When the row has sprite strips (+$15 the count, +$16/+$17 the list) SP moves
; to the strip list and every strip entry is drawn by StripDraw; then RowStar
; draws the row's star.
;
; Input: IX = the row record, B = the screen pixel high byte of the row.
; Output: falls through to the next row.
;
; c2: 11592 entries (= 659 frames * 18 rows minus the frames cut short).
RowEnd:
  LD A,$00
  ADD A,(IX+$08)
  EX AF,AF'
  LD A,(IX+$15)
  AND A
  JP Z,RowStar
  LD C,B
  LD B,A
  LD L,(IX+$16)
  LD H,(IX+$17)
  LD SP,HL
  EXX
  LD H,(IX+$03)
  EXX

; Return into the next strip entry
;
; SP points at a strip entry whose first word is StripDraw: the RET starts it.
; The DJNZ at $8679 loops here once per strip.
StripNext:
  RET

; Draw one sprite strip into a character row
;
; A strip entry (built by BuildObjectStrips) holds: the link to the next entry,
; a word B'/C' (C' = the sprite's colour), the start position (H = the column
; count, saved in the operand of StripCellsDone; L = the first attribute cell),
; then the cell bytes.
;
; Per cell: an attribute whose low six bits are 0 (an empty cell) gets the
; sprite colour and the eight lines are written plainly (StripCellPlain); an
; attribute below 8 (black ink on black paper) is skipped (StripCellSkip);
; otherwise the lines are ANDed into the scenery (StripCellMask) and the cell
; keeps the scenery colour.
;
; A' (the row's glyph count) is incremented for every drawn cell, so the
; padding counts strips as glyphs.
;
; c2: 7168 entries.
StripDraw:
  POP IY
  EXX
  POP BC
  EXX
  POP HL
  LD A,H
  LD (StripCellsDone+$0001),A
  LD A,L
  EXX
  LD L,A
  POP DE
StripCell:
  LD SP,IY                ; the next cell: test its attribute
  LD A,(HL)
  AND $3F
  JP Z,StripCellPlain
  CP $08
  JP NC,StripCellMask
  JP StripCellSkip
StripCellPlain:
  EX AF,AF'               ; empty cell: colour it, write 8 lines
  INC A
  EX AF,AF'
  LD (HL),C
  INC L
  EXX
  LD H,C
  POP DE
  LD (HL),E
  INC H
  LD (HL),D
  INC H
  POP DE
  LD (HL),E
  INC H
  LD (HL),D
  INC H
  POP DE
  LD (HL),E
  INC H
  LD (HL),D
  INC H
  POP DE
  LD (HL),E
  INC H
  LD (HL),D
  JP StripCellsDone
StripCellSkip:
  INC L                   ; dark cell: skip it
  EXX
  JP StripCellsDone
StripCellMask:
  EX AF,AF'               ; scenery cell: AND the 8 lines in
  INC A
  EX AF,AF'
  INC L
  EXX
  LD H,C
  POP DE
  LD A,(HL)
  AND E
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  LD (HL),A
  INC H
  POP DE
  LD A,(HL)
  AND E
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  LD (HL),A
  INC H
  POP DE
  LD A,(HL)
  AND E
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  LD (HL),A
  INC H
  POP DE
  LD A,(HL)
  AND E
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  LD (HL),A
StripCellsDone:
  LD SP,$0000             ; LD SP,n: n's low byte = the strip's H (written at
                          ; $860A)
  ADD IY,SP
  INC L
  EXX
  DJNZ StripCell
  EX DE,HL
  LD SP,HL
  EX DE,HL
  EXX
  DJNZ StripNext

; Draw the row's star, pad the row's time, step to the next row
;
; SP = the operand (saved at $86E2: the record + 8); SP + $14 = the record +
; $1C: POP HL = the star's position (L) and screen high byte, POP AF = its
; flags (carry: visible) and colour.
;
; A visible star on an empty attribute cell sets the attribute and writes a
; single dot on pixel line 3 (one byte B, the other lines cleared); on a used
; cell it XORs the dot into line 3 of the scenery.
;
; Then the padding: A' - 4 left over is the new balance; a row cheaper than
; four glyphs waits 10 DJNZ loops per missing glyph. IX += 32, SP = IX;
; RowsLeft - 1; RowStart or RenderDone.
;
; c2: 11592 entries (as RowEnd).
RowStar:
  LD SP,$0000
  LD HL,$0014
  ADD HL,SP
  LD SP,HL
  POP HL
  POP AF
  JR NC,RowPad
  LD C,A
  LD B,H
  LD H,(IX+$03)
  LD A,(HL)
  AND A
  JR NZ,StarOnScenery
  LD (HL),C
  LD H,(IX+$05)
  XOR A
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),B
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  JP RowPad
StarOnScenery:
  LD H,(IX+$05)           ; XOR the dot into pixel line 3
  INC H
  INC H
  INC H
  LD A,(HL)
  XOR B
  LD (HL),A
RowPad:
  EX AF,AF'               ; the row's cost against four glyphs
  SUB $04
  JP NC,NextRow
RowPadGlyph:
  LD B,$0A                ; wait one glyph's time
RowPadWait:
  DJNZ RowPadWait
  INC A
  JR NZ,RowPadGlyph
NextRow:
  LD (RowEnd+$0001),A     ; store the balance, IX += 32
  LD SP,$0020
  ADD IX,SP
  LD SP,IX
  LD HL,RowsLeft
  DEC (HL)
  JP Z,RenderDone

; Start a row: beeper toggle, attributes, then the row's span nodes
;
; Toggles the beeper (RowBeep $7F7E XOR $18, AND the mask $7F7F, OUT $FE): the
; in-game engine sound is this click, 18 times a frame.
;
; A' = ShiftPage ($7F6A). POP DE = the map ring pointer (+0), HL = the
; attribute address of column 31 (+2), BC = the screen address of the row (+4),
; IY = the head node (+6); saves SP (the record + 8) in RowStar's operand.
;
; SP = the attribute address + 1, then 16 PUSH DE of map bytes read downwards
; (DEC L wraps in the ring page): the 32 attributes of the row land in one go.
; A = C = the screen low byte (column 0), C = $FF. SP = IY: RET into the head
; node.
;
; c2: 11862 entries.
RowStart:
  LD HL,RowBeep
  LD A,(HL)
  XOR $18
  LD (HL),A
  INC HL
  AND (HL)
  OUT ($FE),A
  LD A,(ShiftPage)
  EX AF,AF'
  POP DE
  POP HL
  POP BC
  POP IY
  LD (RowStar+$0001),SP
  LD SP,HL
  INC SP
  EX DE,HL
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  DEC L
  PUSH DE
  LD D,(HL)
  DEC L
  LD E,(HL)
  PUSH DE
  LD A,C
  LD C,$FF
  LD SP,IY
  RET

; Span node handler: a run of four glyphs
;
; Entered by RET with SP = node + 2. POP HL: L = the first glyph, H = the gap.
; A (the column) += gap, DE = the screen address, H = ShiftPage (A'): HL = the
; glyph's line 0.
;
; Eight lines, the four bytes copied LDI, LDI, LDI, LD/INC on even lines and
; LDD back on odd lines (zigzag), INC H / INC D a line. Leaves A = the column
; after the run; POP HL = the next node, SP = it, RET.
;
; The top cost of the game: c2 18726 entries, 123 per mille of all
; instructions.
SpanDraw4:
  POP HL
  ADD A,H
  LD E,A
  LD D,B
  EX AF,AF'
  LD H,A
  EX AF,AF'
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,E
  LDD
  LDD
  LDD
  LDD
  POP HL
  LD SP,HL
  RET

; Span node handler: a run of three glyphs
;
; As SpanDraw4 with three bytes a line. c2: 5790 entries.
SpanDraw3:
  POP HL
  ADD A,H
  LD E,A
  LD D,B
  EX AF,AF'
  LD H,A
  EX AF,AF'
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,E
  LDD
  LDD
  LDD
  POP HL
  LD SP,HL
  RET

; Span node handler: a run of two glyphs
;
; As SpanDraw4 with two bytes a line. c2: 2306 entries.
SpanDraw2:
  POP HL
  ADD A,H
  LD E,A
  LD D,B
  EX AF,AF'
  LD H,A
  EX AF,AF'
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDD
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LDI
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,E
  LDD
  LDD
  POP HL
  LD SP,HL
  RET

; Span node handler: one glyph
;
; As SpanDraw4 with one byte a line (LD A,(HL); LD (DE),A). c2: 5328 entries.
SpanDraw1:
  POP HL
  ADD A,H
  LD E,A
  LD D,B
  EX AF,AF'
  LD H,A
  EX AF,AF'
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  LD A,E
  LDD
  POP HL
  LD SP,HL
  RET

; Span node handler: an empty node
;
; A node whose last glyph has scrolled out but which still links the row: skips
; the glyph/gap word and returns into the next node. c2: 522 entries.
SpanDraw0:
  POP HL
  POP HL
  LD SP,HL
  RET
