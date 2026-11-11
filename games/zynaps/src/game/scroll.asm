; --------------------------------------------------------------------------------------------------------------------
; scroll.asm: Scrolling: glyph allocation, the column builder and the scroll step
;
; The playfield scrolls left two pixels a step. The map ring at $B700-$BFFF (9 pages, two character rows a page, row
; pointers $80 apart) holds the scenery tile codes and attributes; ScrollColumn ($801C) is the leading column.
;
; When a new column enters on the right, the column builder turns each map cell into a glyph: it reads the tile's 8
; lines from the tile set ($5C00, line k of tile n at $5C00 + k*256 + n; +$700 for the upside-down copy), mirrors it
; through BitReverse ($FB00) when asked, and writes the four shifted copies into the glyph cache, each combined with
; the glyph on its left (ADD HL,HL twice per two pixels).
;
; Glyph slots are tracked by the 256-bit map GlyphBitmap ($FFE0-$FFFF); span nodes come from the pool at $F800 (95
; nodes of 8 bytes, free list NodeFreeList $7F68). The scroll step retires the leftmost glyph of every row, frees its
; slot and node, and links the new ones.
; --------------------------------------------------------------------------------------------------------------------

; Find C free glyph slots in a row of the glyph bitmap
;
; Starting from the last position (GlyphAllocMask $8015 = the slot index,
; $8016/$8017 = the bitmap byte and the bit mask), scans GlyphBitmap
; $FFE0-$FFFF for a clear bit, wrapping to $FFE0 and rotating the mask. When
; the run of C slots would pass slot 255 it restarts at slot 0.
;
; Output: E = the first slot (the glyph index), H/L = its bit mask and bitmap
; address, D = $C0; the allocator state advanced by C.
;
; Called by NewSpanNode (c2: 307 entries).
AllocGlyphs:
  LD HL,(GlyphAllocByte)
  LD B,H
  LD A,(GlyphAlloc)
  LD E,A
  LD H,$FF
AllocScan:
  LD A,(HL)
  AND B
  JR Z,AllocFound
  INC E
  INC L
  JP NZ,AllocScan
  LD L,$E0
  RLC B
  JP AllocScan
AllocFound:
  LD A,E
  ADD A,C
  JR C,AllocWrap
  LD H,B
  PUSH HL
  LD (GlyphAlloc),A
  LD A,L
  ADD A,C
  JR NC,AllocStore
  ADD A,$E0
  RLC H
AllocStore:
  LD L,A
  LD (GlyphAllocByte),HL
  POP HL
  LD D,$C0
  RET
AllocWrap:
  LD E,$00                ; restart at slot 0
  LD L,$E0
  RLC B
  JR AllocScan

; Set up the column builder for a new column
;
; Returns at once unless PlayFlags bit 5 (scrolling) is set. Writes the
; builder's operands: IX = $F34C (the record of row 17), HL = ScrollColumn +
; $880 (row 17's cell 8 pages on, + $80), 18 rows to go.
;
; Called from the frame handler cycle (c2: 229 entries, one per scroll step).
StartColumn:
  LD HL,PlayFlags
  BIT 5,(HL)
  RET Z
  LD HL,RowRecords+$0220
  LD (BuildColumn+$0002),HL
  LD HL,(ScrollColumn)
  LD A,H
  ADD A,$08
  LD H,A
  LD A,L
  ADD A,$80
  LD L,A
  LD (BuildColumnCell+$0001),HL
  LD A,$12
  LD (BuildColumnLeft+$0001),A
  RET

; Build up to six cells of the new column, bottom row first
;
; Spreads the 18 rows of a column over three frames: B = 6 rows a call. Per row
; calls BuildCell, then IX -= 32 (the record above), L += $80 and H - 1 every
; second row (two rows a ring page).
;
; The operands keep the state between calls: the record (IX), the map pointer
; (HL) and the rows left (C). Returns at once with C = 0.
;
; c2: 688 entries.
BuildColumn:
  LD IX,$0000
BuildColumnCell:
  LD HL,$0000             ; LD HL,n: the map cell of the next row
BuildColumnLeft:
  LD BC,$0600             ; LD BC,$0600+n: n = the rows left
  LD A,C
  AND A
  RET Z

; BuildColumnLoop
;
; Used by the routine at BuildColumnStep.
BuildColumnLoop:
  PUSH BC
  CALL BuildCell

; BuildColumnBack
BuildColumnBack:
  POP BC                  ; back from BuildCell: the cell above
  LD DE,-32
  ADD IX,DE
  LD A,$80
  ADD A,L

; BuildColumnStep
BuildColumnStep:
  LD L,A                  ; L = the next cell row
  DEC C
  JR Z,BuildColumnSave
  BIT 0,C
  JR NZ,BuildColumnNext
  DEC H
BuildColumnNext:
  DJNZ BuildColumnLoop
  LD (BuildColumn+$0002),IX
  LD (BuildColumnCell+$0001),HL
BuildColumnSave:
  LD A,C
  LD (BuildColumnLeft+$0001),A
  RET

; Turn one map cell of the new column into a glyph
;
; A = the cell's tile code. 0 (empty): when the row's previous column had a
; tile (+$14 bit 7) the gap starts and the following cell's flag byte is set to
; "no attribute" (bit 7 set, bit 2 clear) when it is empty too; otherwise the
; empty-column count +$13 grows (up to 32).
;
; A tile: BuildGlyph. Input: IX = the row record, HL = the map cell. c2: 3948
; entries.
BuildCell:
  LD A,(HL)
  AND A
  JR NZ,BuildGlyph
  BIT 7,(IX+$14)
  JR NZ,CellGapStart
  BIT 5,(IX+$13)
  RET NZ
  INC (IX+$13)
  RET
CellGapStart:
  LD E,L
  INC L
  LD A,(HL)
  AND A
  JR NZ,CellGapDone
  LD L,(IX+$00)
  INC L
  INC L
  RES 2,(HL)
  SET 7,(HL)
CellGapDone:
  LD L,E
  CALL BuildGlyph

; BuildCellDone
BuildCellDone:
  RES 7,(IX+$14)          ; the cell built: clear its pending bit
  RET

; Build one glyph of the new column in all four shifts
;
; The left neighbour is the row's last glyph (+$0F) when the previous column
; had a tile (+$14 bit 7), else a blank line of the tile set. Takes a new span
; node and glyph run when the current run is used up (+$12, NewSpanNode).
;
; The cell's flag byte (the map byte at the row pointer + 1): bit 0 = upside
; down (source + $700 and DEC D instead of INC D at GlyphLineStep), bit 1 =
; mirrored (each line through BitReverse $FB00: the LD A,(HL) at GlyphMirror,
; else NOP).
;
; Writes the 8 lines at shift 0 (page $C0 + line), shift 2 (SET 3,D), shift 4
; (SET 4,D) and shift 6 (RES 3,D), each the 16-bit pair left:new shifted left
; 2, 4, 6 pixels. Sets the slot's bit in GlyphBitmap and +$14 bit 6 (glyph
; added: the scroll step widens the tail node).
;
; c2: 1025 entries.
BuildGlyph:
  EXX
  LD C,(IX+$0F)
  LD B,$C0
  LD E,C
  LD D,B
  INC E
  BIT 7,(IX+$14)
  JR NZ,GlyphHaveLeft
  LD BC,(TileSet)
GlyphHaveLeft:
  EXX
  SET 7,(IX+$14)
  DEC (IX+$12)
  CALL Z,NewSpanNode
  PUSH HL
  LD A,(HL)
  LD L,(IX+$00)
  INC L
  LD C,(HL)
  LD HL,(TileSet)
  LD L,A
  LD A,$14
  LD (GlyphLineStep),A
  XOR A
  LD (GlyphMirror),A
  BIT 0,C
  JR Z,GlyphNoFlip
  LD DE,$0700
  ADD HL,DE
  LD A,$15
  LD (GlyphLineStep),A
GlyphNoFlip:
  EX DE,HL
  BIT 1,C
  JR Z,GlyphNoMirror
  LD A,$7E
  LD (GlyphMirror),A
  LD HL,BitReverse
GlyphNoMirror:
  EXX
  LD (IX+$0F),E
  EXX
  LD B,$08

; GlyphLine
;
; Used by the routine at GlyphShift4.
GlyphLine:
  LD A,(DE)
GlyphLineStep:
  INC D                   ; INC D or DEC D (written at $89F4, $8A05): down or
                          ; up the source tile
  LD L,A
GlyphMirror:
  LD A,(HL)               ; LD A,(HL) (mirror through $FB00) or NOP, written at
                          ; $89F8, $8A0F
  EXX
  LD (DE),A
  LD L,A
  LD A,(BC)
  LD H,A

; GlyphShift2
GlyphShift2:
  SET 3,D                 ; the copy shifted 2 pixels
  ADD HL,HL
  ADD HL,HL
  LD A,H
  LD (DE),A
  SET 4,D
  ADD HL,HL
  ADD HL,HL
  LD A,H
  LD (DE),A
  RES 3,D
  ADD HL,HL

; GlyphShift4
GlyphShift4:
  ADD HL,HL               ; the copy shifted 4 pixels
  LD A,H
  LD (DE),A
  RES 4,D
  INC B
  INC D
  EXX
  DJNZ GlyphLine
  LD A,(IX+$10)
  LD L,(IX+$11)
  LD H,$FF

; GlyphMarkBits
GlyphMarkBits:
  OR (HL)                 ; set the slot bits in the bitmap $FFE0
  LD (HL),A
  INC L
  JR NZ,GlyphMarkSlot
  LD L,$E0
  RLC (IX+$10)
GlyphMarkSlot:
  LD (IX+$11),L
  SET 6,(IX+$14)
  POP HL

; GlyphBuilt
GlyphBuilt:
  RET

; Link a new span node at the row's tail and reserve its glyph run
;
; Takes a node from the pool (PopNode), links it after the tail (+$0D/+$0E),
; sets its gap = the empty-column count (+$13), width 0, handler SpanDraw0,
; counts it (+$0A), resets +$13 to 1. The link store in the previous node is
; done with interrupts off (DI unless the frame phase $7F65 is 4).
;
; Measures the run of tiles that follows in the map (up to 4) into +$12 and
; reserves as many glyph slots (AllocGlyphs); the first glyph index goes to the
; node (+2), the slot mask and address to +$10/+$11.
;
; c2: 307 entries.
NewSpanNode:
  PUSH HL
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  LD DE,$0004
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  CALL PopNode
  PUSH DE
  POP IY
  PUSH HL
  LD (IX+$0D),E
  LD (IX+$0E),D
  LD HL,$0004
  ADD HL,DE
  LD (HL),C
  INC HL
  LD (HL),B
  LD A,(IX+$13)
  LD (IY+$03),A
  XOR A
  LD (IY+$06),A
  INC A
  LD (IX+$13),A
  LD HL,SpanDraw0
  LD (IY+$00),L
  LD (IY+$01),H
  INC (IX+$0A)
  POP HL
  DI
  LD (HL),D
  DEC HL
  LD (HL),E
  LD A,(PassPhase)
  CP $04
  JR Z,RunMeasure
  EI
RunMeasure:
  POP HL
  PUSH HL
  LD B,$04
RunMeasureLoop:
  LD A,(HL)
  AND A
  JR Z,RunMeasureGap
  INC L
RunMeasureNext:
  DJNZ RunMeasureLoop
  LD A,$04
  JR RunStore
RunMeasureGap:
  INC L
  LD A,(HL)
  AND A
  JR NZ,RunMeasureNext
  LD A,$05
  SUB B
RunStore:
  LD (IX+$12),A
  EXX
  PUSH BC
  LD C,A
  CALL AllocGlyphs
  POP BC
  LD (IX+$10),H
  LD (IX+$11),L
  LD (IY+$02),E
  EXX
  POP HL
  RET

; Take a span node from the free list
;
; Output: DE = the node, NodeFreeList ($7F68) = the node's link. HL preserved.
; c2: 307 entries.
PopNode:
  PUSH HL
  LD HL,(NodeFreeList)
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (NodeFreeList),DE
  DEC HL
  EX DE,HL
  POP HL
  RET

; Return the span node HL to the free list
;
; The node's first word = the old NodeFreeList, NodeFreeList = HL. DE
; preserved. c2: 230 entries.
PushNode:
  PUSH DE
  LD DE,(NodeFreeList)
  LD (NodeFreeList),HL
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  POP DE
  RET

; Scroll the playfield model one step (two pixels) left
;
; Returns unless PlayFlags bit 5. ScrollCount ($81DB) + 1, ScriptRoom ($801F) +
; 1, EmptyRows ($7F70) = 0.
;
; Per row record (IX from $F12C, C = 18): an empty row counts in EmptyRows.
; Else the head node's gap - 1; when it goes negative the leftmost glyph
; leaves: its bitmap bit is freed (+$0B/+$0C), the glyph count +8 - 1 and the
; node width - 1; a node of width 0 is unlinked and returned to the pool
; (PushNode), and when the row loses its last node the tail is reset to the
; record (+$0D = IX + 2). The handler follows the width (SetSpanHandler).
;
; When the column builder added a glyph (+$14 bit 6) the tail node grows by
; one.
;
; The new leading attribute: the map byte at the row pointer + 1 is a flag
; byte; bit 2 set: bit 7 set = paper and bright from it, ink from the previous
; cell; bit 7 clear = ink from bits 3-5 and bright from bit 6, paper from the
; previous cell; bit 2 clear: bit 7 set = 0 (black), bit 7 clear = the previous
; cell's attribute. The pointer + 1.
;
; Then ScrollColumn + 1, $8022 + 1, the column 31 places ahead (the cell
; (ScrollColumn + $1F) AND $3F in all four quarters of the 9 ring pages)
; cleared, and a delay of EmptyRows - 9 units that pads the step's time.
;
; Called from the frame handler cycle (c2: 228 entries).
ScrollStep:
  LD HL,PlayFlags
  BIT 5,(HL)
  RET Z
  LD HL,(ScrollCount)
  INC HL
  LD (ScrollCount),HL
  LD HL,ScriptRoom
  INC (HL)
  XOR A
  LD (EmptyRows),A
  LD IX,RowRecords
  LD C,$12
ScrollRow:
  LD A,(IX+$0A)
  AND A
  JP Z,ScrollRowEmpty
ScrollRowHead:
  LD L,(IX+$06)
  LD H,(IX+$07)
  PUSH HL
  POP IY
  DEC (IY+$03)
  JP M,GlyphLeaves
  JR NZ,TailGrow
  LD A,(IY+$02)
  LD B,A
  AND $1F
  ADD A,$E0
  LD (IX+$0C),A
  LD A,B
  AND $E0
  RLCA
  RLCA
  RLCA
  LD B,A
  INC B
  LD A,$80
FreeMaskShift:
  RLCA
  DJNZ FreeMaskShift
  LD (IX+$0B),A
  JR TailGrow
GlyphLeaves:
  LD (IY+$03),$00
  LD A,(IX+$0B)
  LD L,(IX+$0C)
  LD H,$FF
  CPL
  AND (HL)
  LD (HL),A
  INC L
  JR NZ,GlyphLeftFreed
  LD L,$E0
  RLC (IX+$0B)
GlyphLeftFreed:
  LD (IX+$0C),L
  DEC (IX+$08)
  DEC (IY+$06)
  JR NZ,NodeNarrowed
  LD L,(IY+$04)
  LD H,(IY+$05)
  LD (IX+$06),L
  LD (IX+$07),H
  PUSH IY
  POP HL
  CALL PushNode
  DEC (IX+$0A)
  JR NZ,ScrollRowHead
  PUSH IX
  POP DE
  INC DE
  INC DE
  LD (IX+$0D),E
  LD (IX+$0E),D
  JR LeadAttribute
NodeNarrowed:
  CALL SetSpanHandler
  INC (IY+$02)
TailGrow:
  BIT 6,(IX+$14)
  JR Z,LeadAttribute
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  PUSH HL
  POP IY
  INC (IX+$08)
  INC (IY+$06)
  CALL SetSpanHandler
  RES 6,(IX+$14)
  JR LeadAttribute
ScrollRowEmpty:
  LD HL,EmptyRows
  INC (HL)
LeadAttribute:
  LD L,(IX+$00)           ; the new leading attribute from the flag byte
  LD H,(IX+$01)
  LD E,(HL)
  INC L
  LD A,(HL)
  BIT 2,A
  JR Z,LeadNoAttribute
  BIT 7,A
  JR NZ,LeadPaper
  RES 6,E
  BIT 6,A
  JR Z,LeadInk
  SET 6,E
LeadInk:
  RRCA
  RRCA
  RRCA
  XOR E
  AND $07
  XOR E
  JR LeadStore
LeadPaper:
  XOR E
  AND $78
  XOR E
  JR LeadStore
LeadNoAttribute:
  BIT 7,A
  LD A,$00
  JR NZ,LeadKeep
  CPL
LeadKeep:
  AND E
LeadStore:
  LD (HL),A
  INC (IX+$00)
  LD DE,$0020
  ADD IX,DE
  DEC C
  JP NZ,ScrollRow
  LD HL,ScrollColumn
  INC (HL)
  LD HL,ScrollMap
  INC (HL)
  LD HL,(ScrollColumn)
  LD A,L
  ADD A,$1F
  AND $3F
  LD L,A
  LD C,$00
  LD B,$09
ClearAheadPage:
  LD (HL),C
  SET 6,L
  LD (HL),C
  SET 7,L
  LD (HL),C
  RES 6,L
  LD (HL),C
  RES 7,L
  INC H
  DJNZ ClearAheadPage
  LD A,(EmptyRows)
  SUB $09
  RET M
  RET Z
ScrollPad:
  LD B,$13
ScrollPadWait:
  DJNZ ScrollPadWait
  DEC A
  JR NZ,ScrollPad
  RET

; Point the node IY at the handler for its width
;
; Handler = SpanHandlers[(IY+6)] into the node's first word. c2: 1559 entries.
SetSpanHandler:
  LD E,(IY+$06)
  SLA E
  LD D,$00
  LD HL,SpanHandlers
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IY+$00),E
  LD (IY+$01),D
  RET

; The span handler of each run width 0-4
;
; SpanDraw0, SpanDraw1, SpanDraw2, SpanDraw3, SpanDraw4.
SpanHandlers:
  DEFW SpanDraw0
  DEFW SpanDraw1
  DEFW SpanDraw2
  DEFW SpanDraw3
  DEFW SpanDraw4
