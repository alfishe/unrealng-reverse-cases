; --------------------------------------------------------------------------------------------------------------------
; mix.asm: nee.mix: tape I/O for the saved game, its checksum, the map drawer, the tiles and the font
;
; The saved game is Nether Earth's own (NE SaveGame $C28D / LoadGameBlocks $C21E): a 2-byte block holding the 16-bit
; sum of the game block, then the game block, 9425 ($24D1) bytes, both headerless with flag $00. The game keeps the
; block at $D92B-$FDFB; the editor at $9C40-$C110, so every game address is the editor's + $3CEB (15595), and the
; checksum word sits at $9858 (the game's: $5B00).
;
; The four tape entries are the ROM's own LD-BYTES / SA-BYTES entered with the registers set: LD-BLOCK $0802 (it
; reports "R Tape loading error" on a failure, which nee.bas's error trap turns into its ERROR screen) and SA-BYTES
; $04C2 (the standard pilot: the save is a normal ROM-speed block).
;
; DrawMap prints the map page through the ROM's PRINT: each 2x2-character tile is the four characters $20-$23 printed
; with CHARS pointing 256 bytes below the tile's 32 bytes, so it needs no screen addressing of its own. nee.bas does
; the same with the UDG pointer for the selected block.
; --------------------------------------------------------------------------------------------------------------------

; USR 50000: load the checksum block, 2 bytes to $9858 (flag $00)
;
; nee.bas line 8 ("Searching..."). IX = $9858, DE = 2, A = flag $00, carry set
; (load), then the ROM's LD-BLOCK ($0802): back to BASIC on success, "R Tape
; loading error" (or BREAK) otherwise.
;
; Ran at frame 260 of edB/tour (the editor tape's saved game) and at 17817
; (LOAD FILE with the tape ended: BREAK, the error trap, line 146).
LoadChecksum:
  LD IX,Checksum
  LD DE,$0002
  LD A,$00
  SCF
  JP LD_BLOCK                ; ROM LD-BLOCK: LD-BYTES, an error report on failure

; USR 50013: load the game block, 9425 bytes to $9C40-$C110 (flag $00)
;
; nee.bas line 8 ("Loading file..."). LoadChecksum with IX = $9C40, DE = $24D1.
; Ran at frame 512 of edB/tour.
LoadGameBlock:
  LD IX,GameBlock
  LD DE,$24D1
  LD A,$00
  SCF
  JP LD_BLOCK                ; ROM LD-BLOCK

; USR 50026: save the checksum block, 2 bytes from $9858 (flag $00)
;
; nee.bas line 15, after SumGameBlock. ROM SA-BYTES ($04C2) with IX = $9858, DE
; = 2, A = $00. Ran at frame 14013 of edB/tour.
SaveChecksum:
  LD IX,Checksum
  LD DE,$0002
  LD A,$00
  SCF
  JP SA_BYTES                ; ROM SA-BYTES

; USR 50039: save the game block, 9425 bytes from $9C40 (flag $00)
;
; nee.bas line 15, right after SaveChecksum. Ran at frame 14264 of edB/tour.
SaveGameBlock:
  LD IX,GameBlock
  LD DE,$24D1
  LD A,$00
  SCF
  JP SA_BYTES                ; ROM SA-BYTES

; USR 50052: the checksum: the 16-bit sum of the 9425 bytes at $9C40, into
; $9858
;
; Each byte added to a 16-bit total, the carry out of bit 15 dropped: the sum
; the game's LoadGameBlocks ($C21E) compares with the checksum block. nee.bas
; line 15 calls it after its sort and the clock reset, before the save. Ran at
; frame 13866 of edB/tour.
SumGameBlock:
  LD HL,GameBlock
  LD BC,$24D1
  LD DE,$0000             ; DE: the sum
SumLoop:
  PUSH HL                 ; add the next byte
  LD L,(HL)
  LD H,$00
  ADD HL,DE
  EX DE,HL
  POP HL
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,SumLoop
  LD (Checksum),DE           ; the checksum block's word
  RET

; One zero byte: DrawMap starts at 50080
;
; No recording reads it.
Unused:
  DEFB $00

; USR 50080: draw the map page from MapPtr into rows 0-15 of the screen
;
; nee.bas line 33 sets MapPtr (POKE 50403/50404 from RANDOMIZE's SEED), then
; calls it; lines 71, 109, 132 call it again after a deletion or a new
; building. Keeps CHARS; clears rows 0-15 to black on white in columns 1-30 and
; to black in columns 0 and 31 (ClearBox with ATTR_P $38, then $00); makes INK
; 8 PAPER 8 permanent (the tiles keep the cells' attributes); then for the 15
; map rows MapPtr + $200 (map row 1) to row 15, 31 cells each, prints each
; block piece (cells 2-18: DrawPiece) and each building door (cell $50:
; DrawDoor) as a 2x2-character tile whose bottom left is the cell. Ends with
; INK 0 PAPER 7 made permanent, ATTR_P $07 (BASIC's white on black), CHARS
; back, interrupts on.
;
; Cells 0-1, $13-$4F and above $50 draw nothing: a block's other three cells
; (its number + 32) and a door's neighbours are covered by the tile drawn from
; the bottom-left cell.
;
; Ran 7 times in edB/tour (frames 4565 to 12903). Page 1 took 18 frames
; (4565+24846 to the RET at 4583+35142), 13 of them ClearBox's spaces (the
; tiles from 4578+18862).
DrawMap:
  DI                      ; no interrupts: CHARS is not the ROM's while it runs
  LD HL,(CHARS)           ; keep CHARS
  LD (SavedChars),HL
  LD A,$01                ; ClearBox: columns 1-30, rows 0-15, black on white
  LD (BoxColumn),A
  XOR A
  LD (BoxRow),A
  LD A,$1E
  LD (BoxWidth),A
  LD A,$10
  LD (BoxHeight),A
  LD A,$38                ; ATTR_P: paper 7, ink 0
  LD (ATTR_P),A
  CALL ClearBox
  XOR A                   ; then the edge columns 0 and 31 black on black
  LD (BoxColumn),A
  LD (ATTR_P),A
  LD A,$01
  LD (BoxWidth),A
  CALL ClearBox
  LD A,$1F
  LD (BoxColumn),A
  CALL ClearBox
  CALL TEMPS              ; TEMPS: the permanent colours to the temporary ones
  LD DE,ColoursClear      ; INK 8, PAPER 8 ...
  LD BC,$0004
  CALL PR_STRING
  CALL COLOUR_PERM              ; ... made permanent (ROM $1CAD: ATTR_T / MASK_T and
                          ; P_FLAG's temporary bits to the permanent ones)
  LD HL,(MapPtr)          ; the map row under screen row 1: MapPtr + 512
  INC H
  INC H
  LD B,$0F                ; 15 rows
DrawRow:
  PUSH BC
  LD B,$1F                ; 31 cells
DrawCell:
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH BC
  CP $02                  ; 0-1: nothing
  JR C,NextCell
  CP $13                  ; 2-18: a block piece
  JR C,DrawPiece
  CP $50                  ; $13-$4F: nothing
  JR C,NextCell
  CP $51                  ; $50: a building's door
  JR C,DrawDoor
; This entry point is used by the routines at DoorUnknown and PrintTile.
NextCell:
  POP BC
  POP HL
  DJNZ DrawCell
  LD DE,$01E1             ; on to the next row: 31 + 481 = 512
  ADD HL,DE
  POP BC
  DJNZ DrawRow
  CALL TEMPS              ; INK 0 PAPER 7 made permanent
  LD DE,ColoursMap
  LD BC,$0004
  CALL PR_STRING
  CALL COLOUR_PERM
  LD A,$07                ; ATTR_P $07: white ink, black paper, as BASIC had it
  LD (ATTR_P),A
  LD HL,(SavedChars)      ; CHARS back
  LD (CHARS),HL
  EI
  RET
DrawPiece:
  DEC A                   ; a block piece: the tile of block A, its odd-row
                          ; variant for blocks 12-18
  DEC A
  LD L,A                  ; HL = (A - 2) x 32: the block's tile
  LD H,$00
  LD DE,$0020
  PUSH AF
  CALL HL_MULT              ; ROM $30A9: HL = HL x DE
  POP AF
  LD DE,Tiles             ; + Tiles - 256: CHARS for characters $20-$23 = the
                          ; tile's four characters
  ADD HL,DE
  DEC H
  CP $0A                  ; blocks 2-11: one tile
  JR C,PrintTile
  POP BC                  ; blocks 12-18: the row counter (the outer B) from
                          ; the stack ...
  POP DE
  POP AF
  PUSH AF
  PUSH DE
  PUSH BC
  BIT 0,A                 ; ... odd: the variant tile, 224 bytes on
  JR Z,PrintTile
  LD DE,$00E0
  ADD HL,DE
  JR PrintTile
DrawDoor:
  POP BC                  ; a door: the building's type from SaveBuildings, its
                          ; tile from BuildingTiles
  POP HL
  PUSH HL
  PUSH BC
  LD DE,$3CEA             ; HL was past the cell: + $3CEA = the cell's game
                          ; address
  ADD HL,DE
  EX DE,HL
  LD HL,EdSaveBuildings             ; the first SaveBuildings record (game $D958)
FindBuilding:
  LD A,(HL)               ; the record's address word against the cell's
  XOR E
  JR NZ,NextBuildingHi
  INC HL
  LD A,(HL)
  XOR D
  JR NZ,NextBuildingLo
  INC HL                  ; found: its type (0 pad, 1-6 factory, 7 / 8 flag)
                          ; ...
  LD A,(HL)
  LD L,A
  LD H,$00
  LD DE,$0020
  CALL HL_MULT
  LD DE,$0300             ; ... picks BuildingTiles + type x 32
  ADD HL,DE
  LD DE,Tiles
  ADD HL,DE
  DEC H
  JR PrintTile
NextBuildingHi:
  INC HL                  ; the low byte differed: skip 3
NextBuildingLo:
  INC HL                  ; the high byte differed: skip 2
  INC HL
  AND A
  PUSH DE
  LD DE,EdSaveBuildings+164             ; past the 56th record: none
  PUSH HL
  SBC HL,DE
  POP HL
  POP DE
  JR C,FindBuilding

; No SaveBuildings record names this door: nothing drawn
;
; The fall-through of FindBuilding's loop; not run in edB/tour (every door
; there had its record).
DoorUnknown:
  JP NextCell

; Set CHARS to HL, then print the tile at the cell's screen position
;
; Entered by a jump from DrawPiece and DrawDoor with the row and cell counters
; and the map pointer stacked; goes back to NextCell.
PrintTile:
  LD (CHARS),HL
  POP HL                  ; the stacked counters: H = cells left in the row, D
                          ; = rows left
  POP BC
  POP DE
  PUSH DE
  PUSH BC
  PUSH HL
  LD A,$16                ; AT 16 - D, 31 - H: the cell's own character square
                          ; ...
  RST $10
  LD A,$10
  SUB D
  RST $10
  LD A,$1F
  SUB H
  RST $10
  LD A,$22                ; ... characters $22 $23 (the tile's lower half)
  RST $10
  LD A,$23
  RST $10
  LD A,$16                ; AT the row above: characters $20 $21 (the upper
                          ; half)
  RST $10
  LD A,$0F
  SUB D
  RST $10
  LD A,$1F
  SUB H
  RST $10
  LD A,$20
  RST $10
  LD A,$21
  RST $10
  JP NextCell

; Print spaces over BoxHeight rows of BoxWidth from (BoxRow, BoxColumn) on the
; upper screen
;
; Opens stream 2 (the upper screen; CHAN-OPEN also copies the permanent colours
; to the temporary ones) and prints AT row, column, then BoxWidth spaces, row
; by row: the area takes ATTR_P's colours. Called by DrawMap only.
ClearBox:
  LD A,$02                ; stream 2: the upper screen
  CALL CHAN_OPEN
  LD A,(BoxHeight)
  LD B,A
  LD A,(BoxRow)
  LD C,A
ClearRow:
  LD D,B
  LD A,$16
  RST $10
  LD A,C
  RST $10
  LD A,(BoxColumn)
  RST $10
  LD A,(BoxWidth)
  LD B,A
ClearSpace:
  LD A,$20
  RST $10
  DJNZ ClearSpace
  LD B,D
  INC C
  DJNZ ClearRow
  RET

; The map address at the page's left column (nee.bas's DA, 40996-41453), POKEd
; by nee.bas line 33
;
; The tape's $A024 (40996) is page 1: the map's column 15 ($A024 - $A015, Map
; at $A015 = game $DD00).
MapPtr:
  DEFW $A024

; ClearBox's column
BoxColumn:
  DEFB $1F

; ClearBox's first row
BoxRow:
  DEFB $00

; ClearBox's width
BoxWidth:
  DEFB $01

; ClearBox's rows
BoxHeight:
  DEFB $10

; CHARS while DrawMap runs
SavedChars:
  DEFW $3C00

; INK 8, PAPER 8: printed as control codes, then made permanent
ColoursClear:
  DEFB $10,$08,$11,$08

; INK 0, PAPER 7: the same at the end
ColoursMap:
  DEFB $10,$00,$11,$07

; The map blocks' tiles: 32 bytes a block (characters $20-$23), blocks 2-18,
; then the odd-row variants of 12-18
;
; 24 tiles of 2x2 characters: blocks 2-18 at Tiles + 32 x (block - 2), the
; variants at + 224 (blocks 12-18 in odd map rows: nee.bas line 88 picks them
; when putting, DrawPiece when drawing). nee.bas's UDG pointer at 50419 + 32 x
; (CB - 2) shows the selected one.
Tiles:
  INCBIN "res/mix/tiles.bin",$0000,768

; The doors' tiles by SaveBuildings type: 0 the warbase pad, 1-6 the factories
; (electronics ... chassis), 7 the human flag, 8 the insignian flag
BuildingTiles:
  INCBIN "res/mix/building-tiles.bin",$0000,288

; One zero byte before the font
Unused2:
  DEFB $51

; The editor's font: 96 characters from $20, 8 bytes each; nee.bas line 1 sets
; CHARS = 51220 (Font - 256)
Font:
  INCBIN "res/mix/font.bin",$0000,768
