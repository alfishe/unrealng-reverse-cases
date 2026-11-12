; --------------------------------------------------------------------------------------------------------------------
; render.asm: Screen drawing: the clears, the cell composer, sprites, the reveal of blocks
; --------------------------------------------------------------------------------------------------------------------

  ORG $8339

; Clear the screen: attributes to 0, pixels to 0, then the attributes to A
;
; Callers: $5C68, $5D4F, the title $6A7B, $A6FD, $A73E, $A806.
;
; Witness: L1 140 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2,
; opt x3, rzx x7, rzxroom x2).
ClearScreen:
  PUSH AF
  CALL BlackAttributes
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1800
  LD (HL),L
  LDIR
  POP AF

; Fill all 768 attributes with A
;
; Witness: L1 280 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2,
; opt x3, rzx x7, rzxroom x2).
FillAttributes:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF

; (HL) = A, then LDIR BC more bytes
;
; Witness: L1 294 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2,
; opt x3, rzx x7, rzxroom x2).
FillAttrRun:
  LD (HL),A
  LDIR
  RET

; All attributes to 0
;
; Witness: L1 140 (deaths, gameover, havok, hiscore, menu, play48, throw, c x2,
; opt x3, rzx x7, rzxroom x2).
BlackAttributes:
  XOR A
  JR FillAttributes

; Fill the attributes of character rows 1-22 ($5820, 704 bytes) with A
;
; Caller: $5C68 (the start of a life).
;
; Witness: L1 14 (deaths, gameover, havok, hiscore, menu, play48, throw, c x1,
; opt x3, rzx x1, rzxroom x1).
FillPlayAttributes:
  LD HL,Attributes+32
  LD DE,Attributes+33
  LD BC,$02BF
  JR FillAttrRun

  ORG $8803

; DE = the screen address of tile-map cell A (20 a row, 12 x 16 pixels each), +
; 1
;
; E = A / 20 (the row), A = A mod 20 (the column); DrawColumnPos = column x 4;
; B = 2 x row, C = column x 1.5 (character columns), the half-character flag
; (column AND 1) into the operand at $8879; CharCellAddress (one character row
; down). Callers: RedrawCellMask $8873, ComposeCell.
;
; Witness: L1 65975 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x61, rzxroom x18).
CellScreenAddress:
  LD A,E
  LD DE,$1400
  JR CellRowDivide
CellRowCount:
  INC E
CellRowDivide:
  SUB D
  JR NC,CellRowCount
  ADD A,D
  SLA E
  PUSH AF
  ADD A,A
  ADD A,A
  LD (DrawColumnPos),A
  POP AF
  LD B,E
  LD E,A
  SRL A
  ADD A,E
  LD C,A
  LD A,$01
  AND E
  LD (EraseCell+$0006),A
  CALL CharCellAddress
  INC E
  RET

; DE = the screen address for X A (in 4-pixel units x 4), row E, with the phase
; table at $FDF5
;
; C = A / 4 x 1.5, CharCellAddress; E = (E AND $E0) + the column from
; DrawColumnPos and the byte $FDF5 + (DrawColumnPos AND 7). Callers: DrawHavok,
; $8C68.
;
; Witness: L1 113205 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
SpriteScreenAddress:
  SRL A
  SRL A
  LD B,E
  LD E,A
  SRL A
  ADD A,E
  LD C,A
  CALL CharCellAddress
  LD A,E
  AND $E0
  LD B,A
  LD A,(DrawColumnPos)
  AND $07
  ADD A,$F5
  LD L,A
  LD H,$FD
  LD A,(DrawColumnPos)
  AND $F8
  RRCA
  RRCA
  LD C,A
  RRCA
  ADD A,C
  ADD A,(HL)
  OR B
  LD E,A
  INC E
  RET

; Redraw every cell with the reveal mask $6DFF
;
; Caller: the room lookup $95C3.
;
; Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
RedrawRoomMasked:
  LD A,(RevealedZones)

; For the 220 cells (20 x 11): RedrawCellMask with C = A AND $FC
;
; Caller: $955A.
;
; Witness: L1 313 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x59, rzxroom x18).
RedrawCellsMasked:
  AND $FC
  LD C,A
  LD B,$DC
  LD L,$00
RedrawCellsLoop:
  PUSH HL
  PUSH BC
  CALL RedrawCell
  POP BC
  POP HL
  INC L
  DJNZ RedrawCellsLoop
  RET

; A = C, then RedrawCellMask
;
; Witness: L1 68685 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x59, rzxroom x18).
RedrawCell:
  LD A,C

; Cell L: when its flags ($6700 + L) AND A are set draw it (layers), else erase
; it unless the reveal mask $6DFF covers it
;
; Caller: RedrawCell, $9E61.
;
; Witness: L1 68736 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x61, rzxroom x18).
RedrawCellMask:
  LD H,$67
  LD E,L
  AND (HL)
  JR NZ,DrawCellLayers
  LD A,(RevealedZones)
  AND (HL)
  RET NZ
; This entry point is used by the routine at MaskCellRows.
EraseCell:
  LD E,L                  ; LD A,n at $8878: the half-character flag; the masks
                          ; $F000 or $000F
  CALL CellScreenAddress
  EX DE,HL
  LD A,$00
  LD DE,$F000
  OR A
  JR NZ,EraseCellLower
  LD DE,$000F
EraseCellLower:
  CALL MaskCellRows
  LD A,$20
  ADD A,L
  LD L,A
  JR C,MaskCellRows
  LD H,C

; AND 8 pixel lines of two bytes at HL with D and E
;
; Witness: L1 78654 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x59, rzxroom x18).
MaskCellRows:
  LD C,H
  LD B,$08
MaskCellRowsLoop:
  LD A,D
  AND (HL)
  LD (HL),A
  INC L
  LD A,E
  AND (HL)
  LD (HL),A
  DEC L
  INC H
  DJNZ MaskCellRowsLoop
  RET
; This entry point is used by the routine at RedrawCellMask.
DrawCellLayers:
  LD H,$68                ; the cell's four layers ($6800-$6B00) empty: erase;
                          ; else ComposeCell and, when the flag at $88AE is
                          ; set, colour its 2 x 2 attributes from $66F7 + the
                          ; high nibble of $6C00 + L
  XOR A
  OR (HL)
  INC H
  OR (HL)
  INC H
  OR (HL)
  INC H
  OR (HL)
  JR Z,EraseCell
  PUSH HL
  CALL ComposeCell
  POP HL
  LD A,$00
  OR A
  JR Z,DrawCellDone
  INC H
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD HL,CellColours
  ADD A,L
  LD L,A
  LD C,(HL)
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD (HL),C
  INC L
  LD (HL),C
  LD A,$1F
  ADD A,L
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LD (HL),C
  INC L
  LD (HL),C
DrawCellDone:
  JP BlitWindowAt         ; JP $8C72: the composed cell to the screen

; Compose cell L into the buffer $5D4A: the back layers, then the front layers,
; 4 rows of $10 pixel lines, DE = its screen address
;
; ComposeCellColumn with ComposeBackCell $898C, then with ComposeFrontCell
; $8943; $8C76 = 4, $8D27 = $10 (the blitter's rows and lines);
; CellScreenAddress.
;
; Witness: L1 26646 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x14, rzx x61, rzxroom x18).
ComposeCell:
  PUSH HL
  LD BC,ComposeBackCell
  CALL ComposeCellColumn
  POP HL
  PUSH HL
  LD BC,ComposeFrontCell
  CALL ComposeCellColumn
  POP DE
  LD A,$04
  LD (BlitWindowWidth+$0002),A
  LD A,$10
  LD (PackRowLines+$0001),A
  CALL CellScreenAddress
  RET

; One cell through the routine BC (stored as the CALL at $8932), 4 rows, buffer
; $5D4A
;
; Witness: L1 53293 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x14, rzx x61, rzxroom x18).
ComposeCellColumn:
  LD (ComposeRowLoop+$0009),BC
  LD A,$04
  LD BC,$0100
  LD DE,$5D4A
  JR ComposeRows

; Compose the cells under an actor into its buffer (ComposeDest): rows ($69DE),
; cell ($A56E), phase (DrawColumnPos)
;
; BC = the routine (ComposeBackCell / ComposeFrontCell); L = the cell ($A56E
; operand), B = the rows ($69DE), C = (DrawColumnPos AND 3) x 6, A = the line
; count ($8C76), DE = ComposeDest. Caller: the actor update $8E2B.
;
; Witness: L1 203037 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeActorCells:
  LD (ComposeRowLoop+$0009),BC
  LD A,(RevealZone+$0005)
  LD L,A
  LD A,(BoxClip+$0001)
  LD B,A
  LD A,(DrawColumnPos)
  AND $03
  ADD A,A
  ADD A,A
  LD C,A
  SRL A
  ADD A,C
  LD C,A
  LD A,(BlitWindowWidth+$0002)
  LD DE,(ComposeDest)

; B rows: the count A into $892E, then per row the routine, DE + 16, L + 20
;
; Witness: L1 256331 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeRows:
  LD (ComposeRowLoop+$0004),A
  LD A,L
ComposeRowLoop:
  PUSH HL                 ; LD A,n at $892D: the cells a row (into $89F6); CALL
                          ; at $8932: the routine
  PUSH DE
  PUSH BC
  LD A,$00
  LD (ComposeTileLoop+$000A),A
  CALL ComposeBackCell
  POP BC
  POP DE
  POP HL
  LD A,$10
  ADD A,E
  LD E,A
  LD A,$14
  ADD A,L
  LD L,A
  DJNZ ComposeRowLoop
  RET

; The front layers ($6A00 / $6B00) of cell L, or the blank tile $43 when the
; cell's flags AND $6DFF are clear
;
; Witness: L1 349517 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeFrontCell:
  PUSH HL
  LD H,$67
  LD A,(HL)
  AND $FC
  LD H,A
  LD A,(RevealedZones)
  AND H
  JR NZ,ComposeFrontTiles
  LD A,$43
  JR ComposeFrontTile
ComposeFrontTiles:
  LD H,$6B
  LD A,(HL)
  DEC H
  OR A
  JR Z,ComposeFrontEmpty
  LD B,A
  LD A,(HL)
  OR A
  LD A,B
  JR Z,ComposeFrontTile
  CALL ComposeTwoTiles
  JR ComposeFrontNext
ComposeFrontEmpty:
  OR (HL)
  JR NZ,ComposeFrontTile
  LD A,(ComposeTileLoop+$000A)
  LD L,A
  LD A,C
ComposeFrontSkip:
  INC D
  DEC L
  JR Z,ComposeFrontSkipDone
  ADD A,$06
  CP $18
  JR NZ,ComposeFrontSkip
ComposeFrontSkipDone:
  LD A,L
  LD (ComposeTileLoop+$000A),A
  JR ComposeFrontNext
ComposeFrontTile:
  CALL ComposeTile
ComposeFrontNext:
  POP HL
  INC L
  LD C,$00
  LD A,(ComposeTileLoop+$000A)
  OR A
  RET Z
  JR ComposeFrontCell

; The back layers ($6800 / $6900) of cell L: one tile, both (ComposeTwoTiles)
; or the blank tile $43
;
; Witness: L1 349509 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeBackCell:
  PUSH HL
  LD H,$69
  LD A,(HL)
  DEC H
  OR A
  JR Z,ComposeBackOne
  LD B,A
  LD A,(HL)
  OR A
  LD A,B
  JR Z,ComposeBackTile
  CALL ComposeTwoTiles
  JR ComposeBackNext
ComposeBackOne:
  OR (HL)
  JR NZ,ComposeBackTile
  LD A,$43
ComposeBackTile:
  CALL ComposeTileOverlay
ComposeBackNext:
  POP HL
  INC L
  LD C,$00
  LD A,(ComposeTileLoop+$000A)
  OR A
  RET Z
  JR ComposeBackCell

; Compose the tile (HL), then the tile B over it, keeping the column count at
; $89F6
;
; Witness: L1 21094 (bossgate, deaths, play48, rooms, poke-room x14, rzx x67,
; rzxroom x15).
ComposeTwoTiles:
  LD A,(ComposeTileLoop+$000A)
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD A,(HL)
  CALL ComposeTile
  POP AF
  POP BC
  POP DE
  POP HL
  LD (ComposeTileLoop+$000A),A
  LD A,B
  CALL ComposeTile
  RET
; This entry point is used by the routine at ComposeTile.
ComposeHighTile:
  LD HL,MaskedColumns     ; tiles $4B and up: the unpacker entry $8C0A
  JR ComposeTileWith

; Compose tile A: codes $4B and up through $8C0A, else ComposeTileOverlay
;
; Witness: L1 123014 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
ComposeTile:
  CP $4B
  JR NC,ComposeHighTile

; ComposeOverlay first (tiles $1B and up with an overlay nibble in $6C00), then
; the tile
;
; Witness: L1 365175 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeTileOverlay:
  CALL ComposeOverlay

; Compose tile B with the 3-bit unpacker $8BC8
;
; Witness: L1 365175 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeTilePlain:
  LD A,B
  LD HL,UnpackGroups

; Compose a tile with the unpacker HL (stored as the CALL at $89F0): its packed
; data from $8EA3
;
; Witness: L1 452405 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeTileWith:
  LD (ComposeTileLoop+$0005),HL
  CALL FrameRecord

; The unpacker's operands ($8C1E = $50, $8C13 = $0E), then 2-byte rows into DE,
; C + 6 a column up to $12
;
; Witness: L1 549398 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeTileRows:
  LD B,$00
  ADD HL,BC
  LD A,$50
  LD (MaskedColumnStart+$0001),A
  LD A,$0E
  LD (MaskedColumnRows+$0001),A
ComposeTileLoop:
  LD B,$02                ; LD A,n at $89F5: the columns left (shared with
                          ; ComposeRows)
  PUSH DE
  PUSH BC
  CALL UnpackGroups
  POP BC
  POP DE
  LD A,$00
  DEC A
  LD (ComposeTileLoop+$000A),A
  RET Z
  INC D
  LD A,C
  CP $12
  RET Z
  ADD A,$06
  LD C,A
  JR ComposeTileLoop

; Tiles $1B and up: when ($6C00 + L) AND $0F is n, compose the tile, then tile
; $43 + n ANDed in by AndTileColumns
;
; Witness: L1 365175 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ComposeOverlay:
  LD B,A
  CP $1B
  RET C
  LD H,$6C
  LD A,(HL)
  AND $0F
  RET Z
  PUSH AF
  LD A,(ComposeTileLoop+$000A)
  PUSH DE
  PUSH BC
  PUSH AF
  CALL ComposeTilePlain
  POP AF
  POP BC
  POP DE
  LD (ComposeTileLoop+$000A),A
  POP AF
  ADD A,$43
  POP HL
  LD HL,AndTileColumns
  LD (ComposeTileLoop+$0005),HL
  CALL FrameRecord
  JR ComposeTileRows

; AND a tile's columns into the chunk buffer (the shade of a cell)
;
; The AND variant of the column writer of DrawTileColumns `$89D9`: ShadeTile
; `$8A06` puts `$8A2F` in the call operand `$89F1`, finds the shade tile `$43`
; + n with TileAddress `$8EA3` and runs DrawTileColumns, which calls here once
; a 3-pixel column with HL = the chunk byte of its top line and DE = the
; column's packed bytes, B = the groups of 8 values (2 for a 16-line tile).
;
; Each group of three bytes gives eight 3-bit values, most significant first
; (the same unpacking as UnpackGroups `$8BC8`); each value is ANDed into the
; buffer byte of its line (L + 1 a line). The shade tiles `$44-$4A` are dot
; patterns, so a shaded wall shows its texture through a grid of holes
; (ROOM-tmp/swroom.py draws them so; the c1 end screen agrees in every cell but
; the sprites').
;
; Out: DE = the byte after the column, HL = the next buffer line.
;
; The entry is one byte below the region `$8A30`: the loop is `$8A30`, the `EX
; DE,HL` before it swaps the pointers DrawTileColumns hands over.
;
; Witness: L1 264980 (bossgate, deaths, play48, rooms, poke-room x14, rzx x67,
; rzxroom x13).
AndTileColumns:
  EX DE,HL
AndTileLoop:
  LD A,(DE)               ; value 0: bits 7-5 of byte 0
  RLCA
  RLCA
  RLCA
  AND (HL)
  LD (HL),A
  INC L
  LD A,(DE)               ; value 1: bits 4-2
  RRCA
  RRCA
  AND (HL)
  LD (HL),A
  INC L
  LD A,(DE)               ; value 2: bits 1-0 of byte 0 and bit 7 of byte 1
  INC DE
  EX DE,HL
  LD C,(HL)
  EX DE,HL
  RL C
  RLA
  AND (HL)
  LD (HL),A
  INC L
  LD A,C                  ; value 3: bits 6-4 of byte 1
  RLCA
  RLCA
  RLCA
  AND (HL)
  LD (HL),A
  INC L
  LD A,C                  ; value 4: bits 3-1
  RRCA
  RRCA
  AND (HL)
  LD (HL),A
  INC L
  LD A,(DE)               ; value 5: bit 0 of byte 1 and bits 7-6 of byte 2
  INC DE
  EX DE,HL
  LD C,(HL)
  EX DE,HL
  RL C
  RLA
  RL C
  RLA
  AND (HL)
  LD (HL),A
  INC L
  LD A,C                  ; value 6: bits 5-3 of byte 2
  RLCA
  RLCA
  RLCA
  AND (HL)
  LD (HL),A
  INC L
  LD A,(DE)               ; value 7: bits 2-0
  AND (HL)
  LD (HL),A
  INC L
  INC DE                  ; the next group
  DJNZ AndTileLoop
  EX DE,HL
  RET

; Draw the actors that stand in front of the cells' front layer
;
; E = `$80` (actor flag +2 bit 7: drawn in front), D = `$20` (bit 5 set: not
; drawn), then DrawActorsAll `$8A76`. Called by ActorUpdate `$8E2B` (`CALL
; C,$8A73`) after the front pass of the cells, only when an actor of the window
; holds bit 7.
;
; Witness: L1 11205 (bossgate, deaths, gameover, hiscore, menu, play48, opt x3,
; rzx x26).
DrawFrontActors:
  LD DE,$2080

; Draw the actors of all ten pages that overlap the window
;
; B = 10 pages from `$5D00` (`$5D-$66`), C = 0. Called by ActorUpdate `$8E2B`
; with DE = `$A001` (draw the active ones, flag +2 bit 0, unless bit 7 or 5 is
; set) between the back pass (DrawWindowCells `$8907` with DrawCellBack
; `$898C`) and the front pass (with DrawCellFront `$8943`), and by
; DrawFrontActors with DE = `$2080`.
;
; Witness: L1 112726 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
DrawActorsAll:
  LD BC,$0A00

; Draw the actors whose flags match E and not D into the window
;
; In: B = the number of actor pages from `$5D00`, D = the flags that skip an
; actor, E = the flags that select it, C = 0. For each page: C |= flag byte +2;
; when +2 AND E is not 0, DrawActor `$8A90`. Out: C = the OR of all the flag
; bytes (the caller tests bit 7 to know whether a front pass is needed).
;
; Called directly by `$A73E` (`$A7B9`: the redraw of one actor's box after it
; moved, then BlitWindow `$8C68`).
;
; Witness: L1 123592 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
DrawActors:
  LD HL,Hiro+$0002
DrawActorsLoop:
  LD A,(HL)               ; C |= the flags
  OR C
  LD C,A
  LD A,(HL)
  AND E
  JR Z,DrawActorsNext
  PUSH HL
  PUSH DE
  PUSH BC
  CALL DrawActor
  POP BC
  POP DE
  POP HL
DrawActorsNext:
  INC H                   ; the next page
  DJNZ DrawActorsLoop
  RET

; Draw one actor, clipped to the window, into the chunk buffer
;
; In: HL = the actor's flag byte (+2), D = the flags that skip it. Out:
; nothing; IX, the patched operands of the column drawers changed.
;
; **Skips.** A flag of D set; `$9A27` (no carry: the actor's box +`$2A-$2D`
; (left, right, top, bottom) does not meet the window's `$732A-$732D`); kind
; +`$1C` = `$25` (a giant: drawn by its own code).
;
; **Removal.** State +`$20` bit 1 asks for removal: the bit is cleared, `$8E95`
; tests the state; when the actor is gone its flags +2 are cleared and, when
; +`$29` holds a cell number, that cell of layer `$68` (`$68DB` + n) is emptied
; and the reveal spawner `$A59B` runs.
;
; **Vertical cull.** `$8E95`, then a Y (+0) in `$A0-$C7` (below the room) is
; not drawn.
;
; **Clip.** BC = the window's left and right (`$732A`, `$732B`). E = the units
; cut off on the left (window left - X +`$2A`, 0 when the actor starts inside);
; the first chunk page = `$5D` + E. C = the first column of the frame drawn;
; mirrored actors (+`$20` bit 7) count the columns from their right edge. The
; number of columns = the window width (`$8C76`) - E - the units the actor's
; right edge (+`$2B`) lies left of the window's right edge. The first line =
; `$4A` + Y - the window top (the operand `$8B15`, written by `$8F75`).
;
; **The frame.** IX = the set's address (+`$18`/`$19`) + frame (+`$23`) x bytes
; a frame (+`$17`) (Multiply `$8EDD`). Plain: ClipColumns `$8B6A`, then
; MaskedColumns `$8C0A` once a column. Mirrored (+`$1B` bit 7): the columns are
; walked from the right (DE = -bytes a column) through MirroredColumn `$8C51`.
;
; Run 1440 times in c1 and 132818 times in the stage 1 recordings: every
; visible actor, every frame it moves.
;
; Witness: L1 610301 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
DrawActor:
  LD A,(HL)
  AND D
  RET NZ
  LD D,$73                ; DE = $73xx: the window box $732A-$732D against the
                          ; actor's box +$2A-$2D
  CALL BoxesOverlap
  RET NC
  LD L,$1C                ; kind $25 (a giant): not here
  LD A,(HL)
  CP $25
  RET Z
  LD L,$20                ; +$20 bit 1: removal asked
  BIT 1,(HL)
  JR Z,DrawActorCull
  RES 1,(HL)
  CALL ActorOffWindow
  JR NZ,DrawActorClip
  LD L,$02                ; gone: flags 0
  XOR A
  LD (HL),A
  LD L,$29                ; +$29: the cell it occupied
  OR (HL)
  RET Z
  LD HL,TitleColours+$01E1
  ADD A,L
  LD L,A
  LD (HL),$00
  JP SpawnRoomEnemies     ; spawn what the reveal holds
DrawActorCull:
  CALL ActorOffWindow
  RET Z
  LD L,$00                ; Y $A0-$C7: below the room
  LD A,(HL)
  CP $A0
  JR C,DrawActorClip
  CP $C8
  RET C
DrawActorClip:
  LD BC,(DrawColumnPos)   ; C = the window's left, B = its right
  LD L,$2A                ; E = the units cut on the left
  LD A,C
  SUB (HL)
  NEG
  JP P,DrawActorPage
  XOR A
DrawActorPage:
  LD E,A                  ; the first chunk page
  ADD A,$5D
  LD (ClipColumnsStart+$0002),A
  LD L,$20                ; mirrored?
  LD A,(HL)
  RLA
  JR NC,DrawActorLeft
  LD L,$01                ; mirrored: count from the right edge
  LD A,(HL)
  NEG
  SRL A
  LD L,A
  LD A,C
  OR A
  JR Z,DrawActorMirrorEdge
  ADD A,L
  JR DrawActorColumns
DrawActorMirrorEdge:
  LD A,L
  JR DrawActorColumns
DrawActorLeft:
  LD L,$2A                ; plain: C = the first column drawn
  LD A,C
  SUB (HL)
  JP P,DrawActorColumns
  XOR A
DrawActorColumns:
  LD C,A                  ; the right edge: cut when the actor ends inside the
                          ; window
  LD L,$2B
  LD A,B
  SUB (HL)
  NEG
  JP M,DrawActorWidth
  XOR A
DrawActorWidth:
  LD L,A
  LD A,(BlitWindowWidth+$0002)
  ADD A,L
  SUB E
  LD (ClipColumnsCount+$0001),A
DrawActorTop:
  LD A,$00                ; LD A,n: n = the window top (written by $8F75)
  LD L,$00
  SUB (HL)
  NEG
  ADD A,$4A
  LD (ClipColumnsStart+$0001),A
  PUSH HL                 ; IX = the frame's address
  LD L,$18
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  POP IX
  LD L,$23
  LD E,(HL)
  LD L,$17
  LD H,(HL)
  CALL Multiply8
  EX DE,HL
  ADD IX,DE
  POP HL
  LD L,$1B                ; +$1B bit 7: the frame is mirrored
  BIT 7,(HL)
  JR NZ,DrawActorMirrored
  LD A,C
  OR A
  CALL ClipColumns
DrawActorColumnLoop:
  PUSH DE                 ; plain: one column a pass
  PUSH BC
  CALL MaskedColumns
  POP BC
  POP DE
  INC D
  DEC C
  JR NZ,DrawActorColumnLoop
  RET
DrawActorMirrored:
  INC C                   ; mirrored: from the right column
  LD E,C
  LD L,$15
  LD A,(HL)
  SRL A
  SUB E
  CALL ClipColumns
DrawActorMirrorLoop:
  PUSH DE
  PUSH HL
  PUSH BC
  CALL MirroredColumn
  POP BC
  POP HL
DrawActorMirrorStep:
  LD DE,$FFFF             ; LD DE,n: n = -bytes a column (written by
                          ; ClipColumns)
  ADD HL,DE
  POP DE
  INC D
  DEC C
  JR NZ,DrawActorMirrorLoop
  RET

; Set up the column drawers for an actor's frame and its vertical clip
;
; In: H = the actor page, A = the first frame column drawn (Z when 0), IX = the
; frame's address. Rows +`$16`: B = rows / 4, E = rows x 3 / 8, the bytes a
; column; -E goes to DrawActorMirrorStep `$8B60`. IX += A x E skips the columns
; cut on the left.
;
; ClipColumnsStart `$8B84` (the operands written by DrawActor): D = the first
; chunk page, E = the first buffer line, C = the columns to draw. A sprite
; whose top is above the window goes to ClipTop `$8BB7`; else SetColumnClip
; `$8B94` with A = `$50` (the first value of ColumnValues) and L = 0 (no line
; cut).
;
; Witness: L1 157851 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ClipColumns:
  EX AF,AF'
  LD L,$16
  LD A,(HL)
  RRCA
  RRCA
  LD B,A
  LD E,A
  RRCA
  ADD A,E
  LD E,A
  NEG
  LD (DrawActorMirrorStep+$0001),A
  EX AF,AF'               ; columns cut on the left: skip their bytes
  JR Z,ClipColumnsStart
  LD H,A
  CALL Multiply8
  EX DE,HL
  ADD IX,DE
ClipColumnsStart:
  LD DE,$0000             ; LD DE,n: D = the first chunk page, E = the first
                          ; buffer line
ClipColumnsCount:
  LD C,$00                ; LD C,n: n = the columns to draw
  LD A,$4A                ; top above the window?
  SUB E
  DEC A
  JP P,ClipTop
  LD A,$50
  LD L,$00

; Set the first value and the line count of MaskedColumn
;
; In: A = the low byte of the first value drawn (`$50` + the lines cut at the
; top), B = rows / 4, L = the lines cut at the top, E = the first buffer line.
; Writes A into MaskedColumnStart `$8C1D` (`LD SP,ColumnValues+n`), B = rows /
; 8 (the groups UnpackColumn reads), and the loop count `$8C13` = rows - 2 - L,
; cut further when the sprite reaches below the window (`$8D27` + `$4A`).
;
; Out: A = rows - 2 - L with its flags, HL = IX (the frame's columns).
;
; Witness: L1 157851 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
SetColumnClip:
  LD (MaskedColumnStart+$0001),A
  LD A,B
  ADD A,A
  ADD A,A
  RR B
  SUB $02
  SUB L
  PUSH AF
  LD L,A
  ADD A,E
  LD H,A
  LD A,(PackRowLines+$0001)
  ADD A,$4A
  SUB H
  JP P,SetColumnClipRows
  ADD A,L
  LD L,A
SetColumnClipRows:
  LD A,L
  LD (MaskedColumnRows+$0001),A
  POP AF
  PUSH IX
  POP HL
  RET

; A sprite that starts above the window: cut its top lines
;
; In: A = the lines above the window - 1 (negative). E = `$4A` (draw from the
; window's first line), L = the lines cut, A = `$50` + L, then SetColumnClip
; `$8B94`. When no line is left (`DEC A`, not positive) `POP IY` drops
; DrawActor's return: the actor is not drawn.
;
; Witness: L1 12268 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, rzx x70, rzxroom x18).
ClipTop:
  INC A
  LD E,$4A
  LD L,A
  ADD A,$50
  CALL SetColumnClip
  DEC A
  RET P
  POP IY
  RET

; Unpack one picture column into ColumnValues ($5B50)
;
; DE = `$5B50`, then UnpackGroups `$8BC8`.
;
; Witness: L1 819989 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
UnpackColumn:
  LD DE,ColumnValues

; Unpack B groups of three bytes into eight 3-bit values each
;
; In: HL = the packed bytes, DE = the output, B = the groups. Eight values a
; group, most significant bits first: byte 0 bits 7-5, 4-2, bits 1-0 with byte
; 1 bit 7, byte 1 bits 6-4, 3-1, bit 0 with byte 2 bits 7-6, byte 2 bits 5-3,
; 2-0. One output byte a value, E increments (no page crossing).
;
; The format of every picture in the game: the tiles (DrawTileColumns `$89D9`
; calls here with DE = the chunk buffer line, so a tile overwrites the buffer),
; the sprites (UnpackColumn) and the title letters (the c48 recording reads
; `$F954-$FD97` through here at the title).
;
; Out: HL = the byte after the groups, DE = the byte after the values.
;
; Witness: L1 4265375 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
UnpackGroups:
  PUSH BC
  LD B,$07
UnpackGroupsLoop:
  LD A,(HL)               ; value 0
  RLCA
  RLCA
  RLCA
  AND B
  LD (DE),A
  INC E
  LD A,(HL)
  RRCA
  RRCA
  AND B
  LD (DE),A
  INC E
  LD A,(HL)               ; value 2: across bytes 0 and 1
  INC HL
  LD C,(HL)
  RL C
  RLA
  AND B
  LD (DE),A
  INC E
  LD A,C
  RLCA
  RLCA
  RLCA
  AND B
  LD (DE),A
  INC E
  LD A,C
  RRCA
  RRCA
  AND B
  LD (DE),A
  INC E
  LD A,(HL)               ; value 5: across bytes 1 and 2
  INC HL
  LD C,(HL)
  RL C
  RLA
  RL C
  RLA
  AND B
  LD (DE),A
  INC E
  LD A,C
  RLCA
  RLCA
  RLCA
  AND B
  LD (DE),A
  INC E
  LD A,(HL)
  AND B
  LD (DE),A
  INC E
  INC HL
  POP BC                  ; the next group
  DJNZ UnpackGroups
  RET

; Draw one sprite column with its outline into the chunk buffer
;
; In: HL = the column's packed bytes, B = rows / 8, D = the chunk page, E = the
; first buffer line. UnpackColumn, then MaskedColumn `$8C0F`.
;
; Witness: L1 597066 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x70, rzxroom x19).
MaskedColumns:
  PUSH DE
  PUSH BC
  CALL UnpackColumn

; OR the unpacked column into the buffer with a one-pixel black outline
;
; Reads the values back from ColumnValues with the stack: `LD SP,$5B50+n`, `POP
; BC` (C = value k, B = value k + 1), `DEC SP`, so each pop slides one value.
; The interrupts are off for each `POP` only (DI / EI around it): an interrupt
; would push onto the values. The caller's SP is kept in the operand `$8C4D`.
;
; Line k of the buffer: buffer AND M[v(k - 1)] AND M[v(k)] AND M[v(k + 1)] OR
; v(k), with M the table at `$6F00` (FF FC F8 F8 F1 F0 F0 F0: the pixels of the
; value and those beside them in the unit cleared). The first line leaves
; M[v(0)] out (A starts at `$FF`), the last has no v(k + 1). So a sprite or a
; tile from `$4B` gets a black edge above, below and between its pixels, never
; past its unit's sides.
;
; Entered from MaskedColumns and from MirroredColumn `$8C51` (`JR $8C0F`), both
; with the column's B and DE pushed. The tiles from `$4B` are drawn here too
; (`$89C9` -> MaskedColumns).
;
; Out: HL = the next column's packed bytes.
;
; Witness: L1 819986 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
MaskedColumn:
  POP AF
  POP DE
  PUSH HL
MaskedColumnRows:
  LD A,$08                ; LD A,n: n = the lines between the first and the
                          ; last (SetColumnClip)
  EX AF,AF'
  LD A,$FF
  LD H,$6F                ; H = $6F: the outline masks
  LD (MaskedColumnSP+$0001),SP ; keep SP
MaskedColumnStart:
  LD SP,ColumnValues             ; LD SP,n: n = the first value (SetColumnClip)
  DI
  POP BC                  ; C = v(0), B = v(1)
  DEC SP
  EI
  LD L,B
  AND (HL)
  EX DE,HL
  AND (HL)
  OR C
  LD (HL),A
  INC L
  EX DE,HL
  EX AF,AF'
MaskedColumnLoop:
  EX AF,AF'               ; line k: M[v(k-1)] AND M[v(k)] AND M[v(k+1)]
  LD L,B
  LD A,(HL)
  LD L,C
  AND (HL)
  DI
MaskedColumnPop:
  POP BC                  ; the next two values from the stream
  DEC SP
  EI
  LD L,B
  AND (HL)
  EX DE,HL
  AND (HL)
  OR C
  LD (HL),A
  INC L
  EX DE,HL
  EX AF,AF'
  DEC A
  JR NZ,MaskedColumnLoop
  LD L,B                  ; the last line
  LD A,(HL)
  LD L,C
  AND (HL)
  EX DE,HL
  AND (HL)
  OR B
  LD (HL),A
  INC L
  EX DE,HL
MaskedColumnSP:
  LD SP,$0000             ; LD SP,n: n = the caller's SP
  POP HL
  RET

; Draw one sprite column mirrored left to right
;
; UnpackColumn, then each value through the table at `$7A00` (0 4 2 6 1 5 3 7:
; the 3 pixels reversed), in place from the last value down, then MaskedColumn
; `$8C0F`. DrawActor walks the columns from the right, so the frame is mirrored
; as a whole.
;
; Witness: L1 222923 (bossgate, deaths, gameover, havok, hiscore, play48,
; rooms, throw, c x1, opt x3, poke-room x8, rzx x71, rzxroom x17).
MirroredColumn:
  PUSH DE
  PUSH BC
  CALL UnpackColumn
  DEC E
  EX DE,HL
  POP AF
  PUSH AF
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,A
  LD D,$7A
MirroredColumnLoop:
  LD E,(HL)
  LD A,(DE)
  LD (HL),A
  DEC L
  DJNZ MirroredColumnLoop
  JR MaskedColumn

; Copy the composed window from the chunk buffer to the screen
;
; E = the window top (`$732C`), A = its left (`$732A`), ScreenAddress `$8828`
; (DE = the screen byte), then BlitWindowAt `$8C72`.
;
; Called by ActorUpdate `$8E2B` after each actor is redrawn and by `$A7B9`.
;
; Witness: L1 112380 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BlitWindow:
  LD A,(DrawRowPos)
  LD E,A
  LD A,(DrawColumnPos)
  CALL SpriteScreenAddress

; Pack the window's lines and copy them to the screen at DE
;
; In: DE = the screen address of the window's top-left byte. Entered by `JP
; $8C72` from `$88D8` (a cell drawn alone).
;
; PackRow `$8CE5` packs every line of the window into the bytes at `$6F08` and
; returns A = the bytes a line. One byte: the blitter is BlitColumn `$8CD9`.
; More: BlitRows `$8CAD`, its `JR` into the LDI chain set to copy the bytes - 2
; middle bytes. Then for each character row of the window (`$8D27` / 8) the
; blitter draws 8 lines; DE steps to the next character row (E + `$20`, D back
; unless the third changed).
;
; Witness: L1 139027 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BlitWindowAt:
  LD H,$5D
BlitWindowWidth:
  LD BC,$004A             ; LD BC,n: B = the window width in units (written by
                          ; $8F75 / $88DB), C = $4A the first line
  CALL PackRow
  LD HL,BlitColumn        ; one byte a line: BlitColumn
  DEC A
  JR Z,BlitWindowRows
  LD L,$16                ; L = $16 - 2 (bytes - 1): the JR offset into the LDI
                          ; chain
BlitWindowOffset:
  DEC L
  DEC L
  DEC A
  JR NZ,BlitWindowOffset
  LD A,L
  LD (BlitRowsJump+$0001),A
  LD HL,BlitRows          ; BlitRows
BlitWindowRows:
  LD (BlitWindowCall+$0001),HL ; the blitter into the CALL
  LD A,(PackRowLines+$0001) ; B = the character rows
  RRA
  RRA
  RRA
  AND $1F
  LD B,A
  LD HL,OutlineMask+$0008
BlitWindowLoop:
  LD C,D
  PUSH BC
BlitWindowCall:
  CALL $0000              ; CALL n: n = BlitRows or BlitColumn
  LD A,E
  ADD A,$20
  LD E,A
  POP BC
  JR C,BlitWindowNext
  LD D,C
BlitWindowNext:
  DJNZ BlitWindowLoop
  RET

; Copy 8 packed lines of two or more bytes to the screen under the edge masks
;
; HL = the packed lines (`$6F08` on), DE = the screen. For each of 8 lines: the
; first byte = screen AND the left mask (operand `$8CB3`) OR the packed byte,
; the middle bytes by LDI (C = `$FF` keeps B clear of the LDI count), the last
; byte = screen AND the right mask (operand `$8CD0`) OR the packed byte; D + 1
; to the next line. The masks keep the screen pixels outside the window.
;
; Witness: L1 418215 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BlitRows:
  LD BC,$08FF
; This entry point is used by the routine at BlitRowsLdiTail.
BlitRowsLoop:
  PUSH DE
  LD A,(DE)
BlitRowsLeftMask:
  AND $00                 ; AND n: n = the left edge mask (PackRow)
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
BlitRowsJump:
  JR BlitRowsRight        ; JR into the LDI chain: the offset set by
                          ; BlitWindowAt

; LDI chain: copied as bytes (entered only through the patched JR)
;
; Five LDI (`ED A0`) of the LDI chain; BlitRowsJump `$8CB8` jumps to the one
; that leaves the bytes - 2 copies. It goes on into BlitRowsLdiTail `$8CC4`.
; Kept as bytes: the static walk does not follow the patched jump. Witness: L1
; 0 (c1).
BlitRowsLdi:
  DEFB $ED,$A0
  DEFB $ED,$A0
  DEFB $ED,$A0
  DEFB $ED,$A0
  DEFB $ED,$A0

; The last five LDI of the chain and the right edge
;
; The second half of the LDI chain of BlitRows (ten LDI in all, so up to 12
; bytes a line), then the last byte under the right mask.
;
; Witness: L1 6720 (gameover, havok, hiscore, menu, c x1, rzx x2, rzxroom x1).
BlitRowsLdiTail:
  LDI
  LDI
  LDI
  LDI
  LDI
; This entry point is used by the routine at BlitRows.
BlitRowsRight:
  LD A,(DE)               ; the last byte
BlitRowsRightMask:
  AND $00                 ; AND n: n = the right edge mask (PackRow)
  OR (HL)
  LD (DE),A
  INC HL
  POP DE
  INC D
  DJNZ BlitRowsLoop
  RET

; Copy 8 packed lines of one byte to the screen under both edge masks
;
; B = 8; for each line: screen AND the mask (operand `$8CDD`: the left mask OR
; the right mask) OR the packed byte, D + 1.
;
; Witness: L1 8899 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x64, rzxroom x10).
BlitColumn:
  LD B,$08
BlitColumnLoop:
  LD A,(DE)
BlitColumnMask:
  AND $00                 ; AND n: n = the left mask OR the right mask
                          ; (PackRow)
  OR (HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ BlitColumnLoop
  RET

; Pack every line of the window from the chunk buffer into screen bytes at
; $6F08
;
; In: H = `$5D` (the first chunk page), C = `$4A` (the first line), B = the
; window width in units, the window's left (`$732A`), the lines (`$8D27`). p =
; left AND 7 (the unit's place in a 3-byte group of 8 units).
;
; The table PackerPhases `$FD98` gives for p the packer entry (into the CALL at
; `$8D2C`) and the left mask (into BlitRows `$8CB3`); its record p + B + 7 the
; address where the packing must stop and the right mask (into `$8CD0`; both
; masks OR-ed into BlitColumn `$8CDD`). PackRow plants a `RET` (`$C9`) at that
; stop address, keeps the byte it covered in the operand `$8D42` and its
; address in `$8D3F`, and puts it back at the end.
;
; For each line: A = 0, CALL the packer (it reads the units across the pages,
; INC H, and writes whole bytes to BC), the partial last byte to (BC), the next
; line (L + 1).
;
; Out: A = the bytes a line (BC - the start of the last line); DE as on entry
; (the screen).
;
; Witness: L1 139027 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
PackRow:
  PUSH DE
  LD L,C
  PUSH HL
  LD A,(DrawColumnPos)
  AND $07
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,$98
  LD L,A
  LD H,$FD                ; the record of phase p
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD A,(HL)
  LD (PackRowCall+$0001),DE
  LD (BlitRowsLeftMask+$0001),A
  PUSH AF
  LD DE,$0013             ; HL = the record p + B + 7: the stop
  ADD HL,DE
  LD A,B
  ADD A,A
  ADD A,B
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  LD A,(HL)
  EX DE,HL
  LD (PackRowRestore+$0001),HL
  LD (BlitRowsRightMask+$0001),A
  POP BC
  OR B
  LD (BlitColumnMask+$0001),A
  LD A,(HL)               ; plant the RET, keep the byte
  LD (HL),$C9
  LD (PackRowByte+$0001),A
  LD BC,OutlineMask+8             ; BC = the packed lines
  POP HL
PackRowLines:
  LD A,$00                ; LD A,n: n = the window lines (written by $8F75 /
                          ; $88DB)
PackRowLoop:
  PUSH AF
  PUSH HL
  XOR A
  PUSH BC
PackRowCall:
  CALL $0000              ; CALL n: n = the packer entry of phase p
  LD (BC),A
  INC BC
  POP DE
  POP HL
  POP AF
  INC L
  DEC A
  JR NZ,PackRowLoop
  LD L,C
  LD H,B
  OR A
  SBC HL,DE
  LD A,L
PackRowRestore:
  LD HL,$0000             ; LD HL,n: n = the stop address
PackRowByte:
  LD (HL),$00             ; LD (HL),n: n = the byte the RET covered
  POP DE
  RET

; The unrolled packer: 24 units of 3 pixels into 9 bytes; entry for a window
; starting at unit 0 of a group
;
; Each `PackUnitsN` entry starts a line at unit N of a 3-byte group (N = the
; window's left AND 7): unit 0 bits 7-5 of byte 0, 1 bits 4-2, 2 bits 1-0 and
; bit 7 of byte 1, 3 bits 6-4, 4 bits 3-1, 5 bit 0 and bits 7-6 of byte 2, 6
; bits 5-3, 7 bits 2-0. In: HL = the chunk byte of the line in the first unit's
; page, BC = the output, A = 0 (the bits before the window). Each unit `INC H`
; to the next page; a full byte goes to (BC). The code runs on for three groups
; (`$8D45-$8DFD`) until the `RET` PackRow planted after the window's last unit.
;
; The bytes `$8DE6` and `$8DFD` are `INC H` instructions that only a planted
; `RET` follows.
;
; Witness: L1 753555 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
PackUnits0:
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  INC H

; Packer entry: the window starts at unit 1 of a group
;
; See PackUnits0 `$8D45`. Witness: L1 1158720 (bossgate, deaths, gameover,
; havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx
; x72, rzxroom x19).
PackUnits1:
  LD E,A
  LD A,(HL)
  RLCA
  RLCA
  OR E
  INC H

; Packer entry: the window starts at unit 2 of a group
;
; See PackUnits0 `$8D45`. Witness: L1 1363472 (bossgate, deaths, gameover,
; havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx
; x72, rzxroom x19).
PackUnits2:
  LD D,$00
  LD E,(HL)
  SRL E
  RR D
  OR E
  LD (BC),A
  INC BC
  LD A,D
  INC H

; Packer entry: the window starts at unit 3 of a group
;
; See PackUnits0 `$8D45`. Witness: L1 1690190 (bossgate, deaths, gameover,
; havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx
; x72, rzxroom x19).
PackUnits3:
  LD E,A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  RRCA
  OR E
  INC H

; Packer entry: the window starts at unit 4 of a group
;
; See PackUnits0 `$8D45`. Witness: L1 1838814 (bossgate, deaths, gameover,
; havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx
; x72, rzxroom x19).
PackUnits4:
  LD E,A
  LD A,(HL)
  RLCA
  OR E
  INC H

; Packer entry: the window starts at unit 5 of a group
;
; See PackUnits0 `$8D45`. Witness: L1 1847488 (bossgate, deaths, gameover,
; havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx
; x72, rzxroom x19).
PackUnits5:
  LD D,$00
  LD E,(HL)
  SRL E
  RR D
  SRL E
  RR D
  OR E
  LD (BC),A
  INC BC
  LD A,D
  INC H

; Packer entry: the window starts at unit 6 of a group
;
; See PackUnits0 `$8D45`. Witness: L1 1883375 (bossgate, deaths, gameover,
; havok, hiscore, menu, play48, rooms, throw, c x2, opt x3, poke-room x15, rzx
; x71, rzxroom x19).
PackUnits6:
  LD E,A
  LD A,(HL)
  RLCA
  RLCA
  RLCA
  OR E
  INC H

; Packer entry: the window starts at unit 7 of a group; then the second and
; third groups
;
; See PackUnits0 `$8D45`. Unit 7 completes byte 2 of the group (`OR (HL)`); the
; code goes on with the next two groups (`$8D84`, `$8DC3`), the same pattern.
;
; Witness: L1 1900321 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
PackUnits7:
  OR (HL)
  LD (BC),A
  INC BC
  INC H
PackUnitsGroup2:
  LD A,(HL)               ; the second group: unit 0
  RRCA
  RRCA
  RRCA
  INC H
  LD E,A
  LD A,(HL)
  RLCA
  RLCA
  OR E
  INC H
  LD D,$00
  LD E,(HL)
  SRL E
  RR D
  OR E
  LD (BC),A
  INC BC
  LD A,D
  INC H
  LD E,A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  RRCA
  OR E
  INC H
  LD E,A
  LD A,(HL)
  RLCA
  OR E
  INC H
  LD D,$00
  LD E,(HL)
  SRL E
  RR D
  SRL E
  RR D
  OR E
  LD (BC),A
  INC BC
  LD A,D
  INC H
  LD E,A
  LD A,(HL)
  RLCA
  RLCA
  RLCA
  OR E
  INC H
  OR (HL)
  LD (BC),A
  INC BC
  INC H
PackUnitsGroup3:
  LD A,(HL)               ; the third group: unit 0
  RRCA
  RRCA
  RRCA
  INC H
  LD E,A
  LD A,(HL)
  RLCA
  RLCA
  OR E
  INC H
  LD D,$00
  LD E,(HL)
  SRL E
  RR D
  OR E
  LD (BC),A
  INC BC
  LD A,D
  INC H
  LD E,A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  RRCA
  OR E
  INC H
  LD E,A
  LD A,(HL)
  RLCA
  OR E

; INC H: only ever replaced by the planted RET
;
; An `INC H` of the packer (`$24`) that never runs as such: the record of
; PackerPhases that stops here plants a `RET` over it; kept as a byte. Witness:
; L1 0 (c1).
PackUnitsStop1:
  DEFB $24

; The third group, units 5-7
;
; The end of the unrolled packer, reached by falling through when the stop lies
; further on (`$8DFD`): the widest windows, only at the menu and the game over
; in the stage 1 recordings. See PackUnits0 `$8D45`.
;
; Witness: L1 2240 (gameover, havok, hiscore, menu, c x1, rzx x2, rzxroom x1).
PackUnitsTail:
  LD D,$00
  LD E,(HL)
  SRL E
  RR D
  SRL E
  RR D
  OR E
  LD (BC),A
  INC BC
  LD A,D
  INC H
  LD E,A
  LD A,(HL)
  RLCA
  RLCA
  RLCA
  OR E

; INC H: the last stop, always a planted RET
;
; The packer's last `INC H` (`$24`): PackerPhases record 30 plants the `RET`
; here. Witness: L1 0 (c1).
PackUnitsStop2:
  DEFB $24

  ORG $8F3B

; The actor's screen box at rest: +$2A-$2F and the clip bits in +$20
;
; IY = the actor. ActorScreenBox `$8F75` (the box with the last move, into the
; render's variables), then the box of the actor where it stands now (DE = 0):
; BoxColumns `$8FDD` on X gives +`$2E` (columns), +`$2A` (first) and +`$2B`
; (last column, 3-pixel units 0-79); BoxRows `$9000` on Y gives +`$2F` (rows),
; +`$2C` (first) and +`$2D` (last row, 8-pixel rows 0-21); the clip bits go to
; +`$20` bits 4-7 (bits 0-3 kept). Then `$74BA` (the row-pattern pointer the
; render reads at `$8922`) = `$5D4A`, or `$5D42` when the first row `$732C` is
; odd.
;
; Callers: ActorUpdate `$8E3A` (after every move that needs a redraw), `$A73E`.
;
; Witness: L1 114102 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ActorBoxStore:
  CALL ActorScreenBox
  LD L,$01
  LD A,(HL)
  LD DE,$0000
  CALL BoxColumns
  LD L,$2E                ; +$2E = the column count
  LD (HL),A
  LD L,$2A                ; +$2A, +$2B = the first and last column
  LD (HL),C
  INC L
  LD (HL),B
  LD L,$00
  LD A,(HL)
  LD L,A
  CALL BoxRows
  LD L,$2F                ; +$2F = the row count
  LD (HL),A
  LD L,$2C                ; +$2C, +$2D = the first and last row
  LD (HL),C
  INC L
  LD (HL),B
  LD L,$20                ; the clip bits into +$20's high nibble
  LD A,(HL)
  AND $0F
  OR E
  LD (HL),A
  LD DE,$5D4A             ; Hiro's page +$4A, +$42 on an odd first row
  LD A,(DrawRowPos)
  RRA
  JR NC,ActorBoxPattern
  LD E,$42
ActorBoxPattern:
  LD (ComposeDest),DE
  RET

; The box the actor's redraw covers, the old place included: the render's
; variables
;
; IY = the actor; HL = IY on return. The box spans the last step: the X start
; is X less the X step +`$22` when that was to the right, the width grows by
; its size, and the Y start is Y less +`$21` (a quarter of the last Y step).
; BoxColumns `$8FDD` gives the columns: count to `$8C76`, first and last to
; `$732A`/`$732B`; the first row line (Y AND `$F8`, 0 when `$C8` or more) to
; the operand `$8B15`; BoxRows `$9000` gives the rows: count x 8 (pixel lines)
; to `$8D27`, first and last to `$732C`/`$732D`; the clip bits to `$69DD`; the
; first and last cell (RowBase `$7000`[first row / 2] + column / 4) to
; `$A56E`/`$A56F`; the number of 16-pixel rows to `$69DE`.
;
; Callers: ActorBoxStore `$8F3B`, `$955A` (the room change), `$A41E`.
;
; Witness: L1 156241 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ActorScreenBox:
  PUSH IY
  POP HL
  LD E,$00
  LD L,$22                ; D = +$22, the last X step
  LD D,(HL)
  LD A,D
  LD L,E
  OR A                    ; a step to the right: start that far back
  JP M,ActorScreenBoxX
  NEG
  LD L,A
ActorScreenBoxX:
  LD A,L
  LD L,$01
  ADD A,(HL)
  CALL BoxColumns
  LD (BlitWindowWidth+$0002),A ; the column count, the first and last column
  LD (DrawColumnPos),BC
  PUSH BC
  LD L,$21                ; Y less +$21
  LD A,(HL)
  NEG
  LD L,$00
  ADD A,(HL)
  LD L,A
  AND $F8
  CP $C8
  JR C,ActorScreenBoxY
  XOR A
ActorScreenBoxY:
  LD (DrawActorTop+$0001),A ; the first pixel line of the box, for the render
  LD A,L
  CALL BoxRows
  ADD A,A
  ADD A,A
  ADD A,A
  LD (PackRowLines+$0001),A ; the box's height in pixel lines
  LD (DrawRowPos),BC
  LD A,E
  LD (BoxClip),A          ; the clip bits
  POP DE
  PUSH HL
  LD H,$70                ; the first and last cell of the box (RowBase)
  LD L,C
  SRL L
  LD A,E
  SRL A
  SRL A
  ADD A,(HL)
  LD E,A
  LD A,D
  SRL A
  SRL A
  ADD A,(HL)
  LD D,A
  LD (RevealZone+$0005),DE
  LD A,B
  SRL A
  INC A
  SUB L
  LD (BoxClip+$0001),A    ; the number of 16-pixel rows
  POP HL
  RET

; The box's columns from X = A, step D: C = first, B = last (3-pixel units), A
; = count
;
; L = X, (IY... HL) the actor page for +`$15` (width in pixels). C = X / 2, or
; 0 with clip bit 7 when that is `$4F` or more (past the right edge); B = (X +
; |D| + width) / 2 - 1, or `$4F` with clip bit 6 when `$50` or more. Falls into
; BoxSpan `$901F` (A = B + 1 - C).
;
; Callers: ActorBoxStore `$8F3B`, ActorScreenBox `$8F75`.
;
; Witness: L1 270343 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BoxColumns:
  LD L,A
  SRL A
  CP $4F
  JR C,BoxColumnsEnd
  SET 7,E                 ; starts past the right edge
  XOR A
BoxColumnsEnd:
  LD C,A
  LD A,D
  OR A
  JP P,BoxColumnsWidth
  NEG
BoxColumnsWidth:
  ADD A,L
  LD L,$15
  ADD A,(HL)
  SRL A
  DEC A
  CP $50
  JR C,BoxSpan
  SET 6,E                 ; ends past the right edge
  LD A,$4F
  JR BoxSpan

; The box's rows from Y = A (8-pixel rows): C = first, B = last, A = count
;
; C = Y / 8, or 0 with clip bit 5 when that is `$15` or more (Y wrapped above
; the window); B = (Y + height +`$16` - 1) / 8, or `$15` with clip bit 4 when
; `$16` or more. Falls into BoxSpan `$901F`. Callers: ActorBoxStore `$8F3B`,
; ActorScreenBox `$8F75`.
;
; Witness: L1 270343 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BoxRows:
  RRA
  RRA
  RRA
  AND $1F
  CP $15
  JR C,BoxRowsEnd
  SET 5,E                 ; starts above the window
  XOR A
BoxRowsEnd:
  LD C,A
  LD A,L
  LD L,$16
  ADD A,(HL)
  DEC A
  RRA
  RRA
  RRA
  AND $1F
  CP $16
  JR C,BoxSpan
  SET 4,E                 ; ends below the window
  LD A,$15

; B = A (the last), A = B + 1 - C (the count)
;
; The common tail of BoxColumns `$8FDD` and BoxRows `$9000`.
;
; Witness: L1 540685 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BoxSpan:
  LD B,A
  INC A
  SUB C
  RET
