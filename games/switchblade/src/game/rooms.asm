; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The map lookup, the room decoder and builder, the room objects and zones
; --------------------------------------------------------------------------------------------------------------------

; The map's columns: 127 column numbers, read through MapRowCounts /
; MapRowStarts
;
; Read by the map lookup `$95F9` with MapRowCounts `$70C7` and MapRowStarts
; `$70DB`: row r's rooms are MapColumns[start r .. start r + count r - 1]; the
; room number is the place in the list + 1.
MapColumns:
  INCBIN "res/rooms/map.bin",$0000,127

; The rooms in each of the map's 20 rows
MapRowCounts:
  INCBIN "res/rooms/map.bin",$007F,20

; Each map row's first index in MapColumns
MapRowStarts:
  INCBIN "res/rooms/map.bin",$0093,20

; Clear B cells from C in the six room planes $6700-$6C00
;
; A = 0, L = C; for each cell the six planes `$67`-`$6C`. From BuildPageTails
; (`$DC`, `$24` cells: the spare cells and the row above), and the room build
; `$9F3D` (C = `$EC`, B = `$14`: the row above) and `$9F6A` (C = 0, B = `$DC`:
; the whole room).
;
; Witness: L1 424 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x56, rzxroom x19).
ClearRoomCells:
  XOR A
  LD L,C
ClearRoomCellsLoop:
  LD H,$67
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC L
  DJNZ ClearRoomCellsLoop
  RET

; The room data's address for each room 1-127 ($A928-$D0A5)
;
; Read by `$A3C9` (H = `$71`, L = room x 2: room 1 is `$7102`). MENU names the
; table's base `$7100` RoomDataTable; its first word `$7100` (room 0) lies in
; ClearRoomCells.
RoomDataPointers:
  DEFW Room1,Room2,Room3,Room4,Room5,Room6,Room7,Room8
  DEFW Room9,Room10,Room11,Room12,Room13,Room14,Room15,Room16
  DEFW Room17,Room18,Room19,Room20,Room21,Room22,Room23,Room24
  DEFW Room25,Room26,Room27,Room28,Room29,Room30,Room31,Room32
  DEFW Room33,Room34,Room35,Room36,Room37,Room38,Room39,Room40
  DEFW Room41,Room42,Room43,Room44,Room45,Room46,Room47,Room48
  DEFW Room49,Room50,Room51,Room52,Room53,Room54,Room55,Room56
  DEFW Room57,Room58,Room59,Room60,Room61,Room62,Room63,Room64
  DEFW Room65,Room66,Room67,Room68,Room69,Room70,Room71,Room72
  DEFW Room73,Room74,Room75,Room76,Room77,Room78,Room79,Room80
  DEFW Room81,Room82,Room83,Room84,Room85,Room86,Room87,Room88
  DEFW Room89,Room90,Room91,Room92,Room93,Room94,Room95,Room96
  DEFW Room97,Room98,Room99,Room100,Room101,Room102,Room103,Room104
  DEFW Room105,Room106,Room107,Room108,Room109,Room110,Room111,Room112
  DEFW Room113,Room114,Room115,Room116,Room117,Room118,Room119,Room120
  DEFW Room121,Room122And123,Room122And123,Room124,Room125,Room126,Room127

; The actor kinds' templates: 73 words, kind -> template (0 for no kind)
;
; Read by TemplateForKind `$A652` (kind AND `$7F`, DE = the word). The
; templates lie in the page tails (`$5D82` ... `$66FF`, from PageTailTemplate).
; Bytes, not words: the words point at run-time addresses whose image bytes are
; other things.
KindTemplates:
  INCBIN "res/tables/kind-templates.bin",$0000,146

; Room tile tables: pairs (plane page, tile) read by $A334
;
; Read by `$A334` (B pairs from HL): entry points SolidTiles `$7292`, `$7294`
; and LedgeTiles `$72B4`.
SolidTiles:
  INCBIN "res/rooms/solid-tiles.bin",$0000,34
LedgeTiles:
  INCBIN "res/rooms/solid-tiles.bin",$0022,36

; Three pairs (plane page, tile) read by $A298
TopTiles:
  INCBIN "res/rooms/solid-tiles.bin",$0046,6

; Room opcode handler: fix-ups for rooms 1 and 8 in the cell property plane
; $6C00
;
; Reached through the room opcode table (`$73C7`, `JP (HL)` at `$A015`). Room
; 1: the ten cells `$78-$81` of `$6C00` get the property `$20`; room 8: the
; cells `$5A`, `$5B`, `$6E`, `$6F` get 0. Other rooms: nothing.
;
; Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
RoomPatch:
  LD A,(Room)
  CP $01
  JR NZ,RoomPatch8
  LD HL,PageTail5F+$0020
  LD E,$0A
RoomPatchLoop:
  LD (HL),$20
  INC HL
  DEC E
  JR NZ,RoomPatchLoop
  RET
RoomPatch8:
  CP $08
  RET NZ
  LD HL,$0000
  LD (PageTail5F+$0002),HL
  LD (PageTail5F+$0016),HL
  RET

  ORG $955A

; After a move of Hiro: cross into the next room when he reaches an edge
;
; Reached by `JP $955A` from AnimateAfterMove `$9B97` after every move of Hiro
; (kind `$24`), H = `$5D`: 2348 runs in the play recordings.
;
; C = -(Hiro +$3D), the X offset an animation in progress has added, so the X
; test sees the true position.
;
; **The rows.** Tested when Hiro is on a ladder (`$5D02` bit 3), or when his
; top is inside the room (`$5D20` bit 5 clear, set by `$9000` when the Y is
; past the top): so he leaves a room upwards only by a ladder or a jump that
; stays inside. Y = `$A0` steps the row down (`$69DF` + 1) and puts him at Y
; `$F0` (-16); Y = `$EC` (-20) steps it up and puts him at `$9C`.
;
; **The columns.** X + C = `$9E` steps the column right (`$69E0` + 1) and puts
; him at X `$FC`; `$FA` steps it left and puts him at `$9C`. The Y goes back to
; its value before this move (the operand at `$95B4`, written by ApplyMove
; `$9B59`): the step's vertical part is undone.
;
; **No edge.** `$8F75` (his box and clip bits again) and `$A569` (is the reveal
; block under or ahead of him new?): a new block is added to `$6DFF`, drawn
; (`$8855`) and its objects spawned (`JP $A59E`): the rooms are revealed block
; by block as Hiro walks.
;
; **A crossing.** In Havok's room (123, `$7B`) `CALL $5FCB` first (code in
; actor page `$5F`); `$A58A` keeps the old room's reveal and taken bytes
; `$6DFE-$6DFF` and loads the next room's; then falls into EnterRoom `$95C3`.
; The c1 walk: 13 column crossings (c1, deaths, gameover, rooms), 2 row
; crossings (deaths, rooms).
;
; Witness: L1 42125 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
CheckRoomExit:
  LD L,$3D                ; C = -(+$3D): the animation's X offset
  LD A,(HL)
  NEG
  LD C,A
  LD HL,MapRow            ; HL = the map row
  LD A,(Hiro+$0002)       ; on a ladder: always test the rows
  AND $08
  JR NZ,RoomExitTestY
  LD A,(Hiro+$0020)       ; top above the room (bit 5): skip the rows
  BIT 5,A
  JR NZ,RoomExitTestX
RoomExitTestY:
  LD A,(Hiro)
  LD E,$F0
  CP $A0                  ; Y = $A0: the bottom edge
  JR Z,RoomExitDown
  LD E,$9C
  CP $EC                  ; Y = $EC (-20): the top edge
  JR Z,RoomExitUp
RoomExitTestX:
  INC L                   ; HL = the map column
  LD A,(Hiro+$0001)
  ADD A,C
  LD E,$FC
  CP $9E                  ; X = $9E: the right edge
  JR Z,RoomExitRight
  LD E,$9C
  CP $FA                  ; X = $FA (-6): the left edge
  JR Z,RoomExitLeft
  CALL ActorScreenBox     ; no edge: the box and clip bits again
  CALL RevealZone         ; a reveal block not yet seen? D = its bit
  LD A,D
  RET NZ
  PUSH AF                 ; draw the new block's cells and spawn its objects
  CALL RedrawCellsMasked
  POP AF
  JP SpawnZoneEnemies
RoomExitDown:
  INC (HL)                ; row + 1, Y = $F0
  JR RoomExitSetY
RoomExitUp:
  DEC (HL)                ; row - 1, Y = $9C
RoomExitSetY:
  LD A,E
  LD (Hiro),A
  JR RoomExitEnter
RoomExitRight:
  INC (HL)                ; column + 1, X = $FC
  JR RoomExitSetX
RoomExitLeft:
  DEC (HL)                ; column - 1, X = $9C
RoomExitSetX:
  LD A,E
  LD (Hiro+$0001),A
  LD A,$04                ; LD A,n: n = Hiro's Y before this move (ApplyMove
                          ; writes it)
  LD (Hiro),A
RoomExitEnter:
  LD A,(Room)             ; leaving room 123 (Havok's)?
  CP $7B
  CALL Z,HavokRoomLeave
  CALL SaveRoomState      ; save this room's reveal bytes, load the next room's

; Find the room at the map row and column and build it
;
; Falls in from CheckRoomExit `$955A` and is called by `$5C68` (the start of a
; game and of a life): 23 runs.
;
; `$6BDC` = the room above (FindRoom `$95F9` of row - 1, 0 on row 0); `$6BDD` =
; the room (FindRoom of the row). Room 123 (`$7B`, Havok's) calls `$5FD4`
; first. Then BuildRoomPlanes `$9F34` (the cell planes), `$A41E`, `$8852`
; (draws the revealed cells), `$A59B` (spawns the objects of the revealed
; blocks), and when the energy ball or the death wait is on (`$6651` not 0)
; RestoreShield `$995C` puts it back around Hiro.
;
; Out: A = the value BuildRoomPlanes returned (kept over the calls).
;
; Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
EnterRoom:
  LD B,$00                ; B = 0 for the CPIR count
  LD A,(MapRow)
  OR A
  JR Z,EnterRoomAbove
  DEC A                   ; the row above
  CALL FindRoom
EnterRoomAbove:
  LD (RoomAbove),A        ; $6BDC: the room above, 0 none
  LD A,(MapRow)
  CALL FindRoom
  LD (Room),A             ; $6BDD: the room
  LD A,(Room)
  CP $7B                  ; room 123: Havok's room hook in page $5F
  CALL Z,HavokRoomEnter
  CALL BuildRoomPlanes    ; decode the room (and the bottom row of the room
                          ; above)
  PUSH AF
  CALL SetupRoomObjects
  CALL RedrawRoomMasked
  CALL SpawnRoomEnemies
  LD A,(Invulnerable)     ; the energy ball or the death wait on? put it back
  OR A
  CALL NZ,RestoreShield
  POP AF
  RET

; The room number at map row A and column $69E0
;
; A = the map row (0-19). `$70C7`+row is the number of rooms in the row,
; `$70DB`+row the offset of its first column in the column list `$7048`; CPIR
; searches that stretch for the column `$69E0`. Out: A = the position found + 1
; - (`$7048` - 1): the room number 1-127, or 0 when the column has no room
; (`$9613`, the rooms recording's 4 failed lookups when it wrote the map
; variables by hand). B must be 0 (EnterRoom `$95C3`).
;
; Witness: L1 375 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
FindRoom:
  LD H,$70
  ADD A,$C7
  LD L,A
  LD C,(HL)               ; C = the number of rooms in the row
  ADD A,$14
  LD L,A
  LD A,(HL)               ; L = the row's first entry in the column list
  ADD A,$48
  LD L,A
  LD H,$70
  LD A,(MapColumn)        ; the column
  CPIR
  JR NZ,FindRoomNone
  LD A,L                  ; the room = its place in the list
  SUB $48
  RET
FindRoomNone:
  XOR A                   ; no room there: 0
  RET

  ORG $9F34

; Decode the room (and the bottom row of the room above) into the cell planes
;
; From EnterRoom `$95E3`: 23 runs. With no room above (`$6BDC` = 0) the spare
; row `$EC-$FF` of the six planes is cleared (`$70EF`). Else the room above is
; decoded first (`$A3C9` gives its data, DecodeRoom with A = `$FF`: walls and
; object types below `$0D` only) and its bottom row (cells `$C8-$DB`) is copied
; to `$EC-$FF` in the planes `$68-$6B` (deaths, rooms: 2). Then the room
; `$6BDD` (DecodeRoom with A = 0). Out: A = 0.
;
; Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
BuildRoomPlanes:
  LD A,(RoomAbove)
  OR A
  JR NZ,BuildRoomAbove
  LD BC,$14EC             ; no room above: clear the spare row
  CALL ClearRoomCells
  JR BuildRoomCurrent
BuildRoomAbove:
  CALL RoomDataAddress    ; the room above's data
  LD A,$FF
  CALL DecodeRoom
  LD H,$68                ; its bottom row to the spare row, four planes
  LD A,$04
CopyAboveRowLoop:
  LD L,$C8
  LD E,$EC
  LD D,H
  LD BC,$0014
  LDIR
  INC H
  DEC A
  JR NZ,CopyAboveRowLoop
BuildRoomCurrent:
  LD A,(Room)
  CALL RoomDataAddress
  XOR A

; Decode a packed room at BC into the cell planes
;
; BC = the room's data (the table `$7100`, a word a room, `$A3C9`), A = `$FF`
; for the room above (`$6AEB`). All 220 cells of the six planes cleared
; (`$70EF`).
;
; **The walls.** A header byte: bits 0-2, 3-5 and 6-7 count the runs of three
; groups (E = 3, 2, 1: the pattern starts 0, 1 or 2 entries later). A run: a
; byte (low nibble: a pattern in the table `$7300`; high nibble: the steps),
; the start cell. Each step reads a pattern byte: bit 7 set puts the tile pair
; 2, 3 in two cells, else tile 1, in plane `$68` with plane `$67` = 1
; (`$A408`); bits 0-5 the step to the next cell; bit 6 goes back to the
; pattern's start.
;
; **The objects** (NextObjectGroup `$9FD6`): groups of a type byte (low nibble
; the type, high nibble the count - 1) and their bytes, dispatched through the
; table `$73C7` (DispatchObject). The room above stops at type `$0D`.
;
; Witness: L1 279 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
DecodeRoom:
  LD (ZoneRecords+$000A),A
  PUSH BC                 ; clear all six planes
  LD BC,$DC00
  CALL ClearRoomCells
  POP BC
  LD E,$02                ; the header: three groups of wall runs
  LD A,(BC)
  PUSH AF
  INC BC
  AND $07
  JR Z,WallGroup2
  INC E                   ; group 1: E = 3
WallRunLoop:
  PUSH AF
  PUSH DE
  LD A,(BC)               ; the pattern from the table $7300
  AND $0F
  LD H,$73
  LD L,A
  LD L,(HL)
  LD A,L
  DEC A
  LD (Room+$0001),A       ; its first entry - 1: the restart point
  LD A,$03                ; the start entry for this group
  SUB E
  ADD A,L
  LD L,A
  CALL OpHighNibble       ; the steps: the high nibble
  INC BC
  LD A,(BC)               ; the start cell
  PUSH BC
  LD B,E
  LD E,A
  EX DE,HL
  LD H,$68                ; plane $68
WallStepLoop:
  LD A,(DE)               ; bit 7: a pair 2, 3
  RLA
  LD A,$01
  JR NC,WallTile
  INC A
  CALL PutTileMarkA
  INC L
  INC A
WallTile:
  CALL PutTileMarkA
  LD A,(DE)               ; bits 0-5: the step
  AND $3F
  ADD A,L
  LD L,A
  LD A,(DE)               ; bit 6: back to the pattern's start
  AND $40
  JR Z,WallNextStep
  LD A,(Room+$0001)
  LD E,A
WallNextStep:
  INC E
  DJNZ WallStepLoop
  POP BC
  INC BC
  POP DE
  POP AF
  DEC A
  JR NZ,WallRunLoop
  DEC E                   ; the next group
  JR Z,NextObjectGroup
  INC A
  CP E
  JR Z,WallGroup3
WallGroup2:
  POP AF                  ; bits 3-5: group 2
  PUSH AF
  RRA
  RRA
  RRA
  AND $07
  JR NZ,WallRunLoop
  LD E,$01
WallGroup3:
  POP AF                  ; bits 6-7: group 3
  RLCA
  RLCA
  AND $03
  JR NZ,WallRunLoop

; An object group: the type and the count
;
; Also reached from `$A016`, `$A1F1` (the last of a group). Type `$0D`: the
; count is (high nibble & 1) + 2.
;
; Witness: L1 1770 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
NextObjectGroup:
  LD A,(BC)
  AND $0F
  LD (ZoneRecords+$0009),A
  CP $0D
  LD HL,$010F
  JR NZ,ObjectGroupCount
  LD HL,$0201
ObjectGroupCount:
  CALL OpHighNibble
  AND L
  ADD A,H
  LD (ZoneRecords+$0008),A

; The next object of the group
;
; Witness: L1 5695 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
NextObject:
  INC BC

; Count the group; dispatch the type
;
; Witness: L1 5736 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
ObjectLoop:
  LD HL,ZoneRecords+$0008
  DEC (HL)
  JR Z,NextObjectGroup
  INC L                   ; types from $0D: not for the room above
  LD A,(HL)
  CP $0D
  JR C,DispatchObject
  INC L
  BIT 7,(HL)
  RET NZ
DispatchObject:
  LD HL,RoomCodeHandlers  ; the table $73C7, a word a type
  LD D,A
  RLCA
  JR JumpViaTable

; Type $0B: a second table $75EF, by bits 4-7 of the next byte
;
; Witness: L1 183 (bossgate, deaths, play48, rooms, poke-room x8, rzx x19,
; rzxroom x7).
ObjectTypeB:
  LD HL,RoomCodeHandlersB
  LD A,(BC)
  RRA
  RRA
  RRA
  AND $1E

; JP (the word at HL + A)
;
; Witness: L1 4889 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
JumpViaTable:
  ADD A,L
  LD L,A
  LD A,(HL)
  INC L
  LD H,(HL)
  LD L,A
  JP (HL)

; Types 0-3: tile patterns in plane $68 + type
;
; For each of the group's objects (the count in E): a start cell, a pattern
; offset in page `$73` (PlotPattern), one byte skipped. Then the next group. 25
; runs.
;
; Witness: L1 208 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x13, rzx x39, rzxroom x13).
ObjectPattern:
  LD A,$68
  ADD A,D
  LD H,A
  LD A,E
ObjectPatternLoop:
  PUSH AF
  LD A,(BC)
  LD L,A
  INC BC
  LD D,$73
  LD A,(BC)
  LD E,A
  CALL PlotPattern
  INC BC
  LD A,(BC)
  POP AF
  DEC A
  JR NZ,ObjectPatternLoop
  JR NextObjectGroup

; Put the tiles of the pattern DE from cell L on
;
; The pattern: a tile, then pairs of a step (a byte below `$80`) and a tile; a
; byte from `$80` ends it.
;
; Witness: L1 1316 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x13, rzx x39, rzxroom x13).
PlotPattern:
  LD A,(DE)
  LD (HL),A
  INC E
  LD A,(DE)
  OR A
  RET M
  ADD A,L
  LD L,A
  INC E
  JR PlotPattern

; Type 4: the surface rooms' sky, horizon and ground
;
; Plane `$6C` cells 0-`$77` = `$20`; plane `$68` rows 0-3 = tiles `$33`, `$34`,
; `$35`, `$36`; row 4 = 20 bytes from `$74F5` + room (the horizon moves with
; the room); tile `$37` at cell 9 - room (rooms below 10), tile `$43` at `$54`
; - room (rooms from 5); a row of tiles `$3C-$3E` and a row of `$81-$83` in
; plane `$6B` (solid, attribute `$20`), each tile differing from the one
; before, the choice taken from the bytes of the ROM from `$0000` + 257 - room,
; the 48K keyword table (NextGroundVariant). Room 123 (Havok's) gets only the
; second row, 14 cells from `$C8`. 19 runs (c1 and the play recordings: rooms
; 1-7).
;
; Witness: L1 41 (deaths, gameover, havok, hiscore, menu, play48, rooms, throw,
; c x1, opt x3, rzx x2, rzxroom x6).
BuildSurface:
  PUSH BC
  LD A,$20
  LD (CellProperty),A
  LD E,$0E
  LD L,$C8
  LD A,(Room)
  CP $7B
  JR Z,FloorRow           ; Havok's room: the floor row only
  LD HL,CellProperty+$001D
  LD B,$78
FillAttrLoop:
  LD (HL),$20
  INC L
  DJNZ FillAttrLoop
  LD C,$04
  LD DE,TitleColours+$0106
  LD A,$33
SkyRowLoop:
  LD B,$14
SkyCellLoop:
  LD (DE),A
  INC E
  DJNZ SkyCellLoop
  INC A
  DEC C
  JR NZ,SkyRowLoop
  LD HL,ComposeDest+$003B ; the horizon strip, moved by the room number
  LD A,(Room)
  PUSH AF
  ADD A,L
  LD L,A
  LD C,$14
  LDIR
  POP AF
  NEG
  LD C,A
  LD H,D
  LD A,$09
  ADD A,C
  LD L,A
  LD (HL),$37             ; tile $37 at cell 9 - room
  LD A,C
  CP $FC
  JR NC,GroundRow
  ADD A,$54               ; tile $43 at cell $54 - room
  LD L,A
  LD (HL),$43
GroundRow:
  EX DE,HL
  LD E,$14
GroundRowLoop:
  CALL NextGroundVariant
  ADD A,$3B
  LD (HL),A
  INC HL
  DEC E
  JR NZ,GroundRowLoop
  LD E,$14
FloorRow:
  LD H,$6B                ; plane $6B: solid tiles $81-$83
FloorRowLoop:
  CALL NextGroundVariant
  ADD A,$80
  CALL PutTileMarkPropA
  INC HL
  DEC E
  JR NZ,FloorRowLoop
  LD A,$00                ; the attribute back to 0
  LD (CellProperty),A
  POP BC
  JP ObjectLoop

; A = 1-3 from the next data byte, not equal to D
;
; Reads bytes of the ROM from `$0000` + 257 - room as a source of variation (BC
; was reused: the `LDIR` at `$A070` leaves B = 0, `LD C,A` at `$A075` puts 256
; - room in C): the 48K keyword table, the same on the 128K's ROM 1. Bits 0-1
; (0 counts as 1), until it differs from the last (D). Out: D = A.
;
; Witness: L1 2432 (deaths, gameover, havok, hiscore, menu, play48, rooms,
; throw, c x1, opt x3, rzx x2, rzxroom x6).
NextGroundVariant:
  INC BC
  LD A,(BC)
  AND $03
  JR NZ,NextGroundVariantCmp
  INC A
NextGroundVariantCmp:
  CP D
  JR Z,NextGroundVariant
  LD D,A
  RET

; Type 5: a horizontal run from the records at $75AD
;
; Witness: L1 68 (rooms, poke-room x1, rzx x11, rzxroom x4).
ObjectRunH75AD:
  LD HL,StructureSetF
  JR ObjectRunH

; Type $0A: a horizontal run from the records at $7511
;
; Witness: L1 1633 (bossgate, deaths, play48, rooms, poke-room x13, rzx x53,
; rzxroom x14).
ObjectRunH7511:
  LD HL,StructureSetD

; Carry set: a horizontal run (step 1); `$A0EE`, `$A101`
;
; The run's record (6 bytes: plane, end tiles, the middle tiles) is chosen by
; the high nibble (`$A0EE`); `$A109` lays it, step 1 with carry, `$14` (a
; column) without.
;
; Witness: L1 1701 (bossgate, deaths, play48, rooms, poke-room x13, rzx x53,
; rzxroom x14).
ObjectRunH:
  SCF
  JR StripFromRecord

; Type 6: a vertical run from the records at $7400
;
; `LD HL,$7400` / `JR $A0CC` (OR A: carry clear, step `$14`) into `$A0C9`'s
; tail. Reached only through the table `$73C7` (type 6); not run in the keyed
; recordings.
;
; Witness: L1 298 (poke-room x3, rzx x26, rzxroom x7). Not run in the keyed
; recordings.
ObjectRunV7400:
  LD HL,StructureRecords
  JR StripRecordGo

; Room opcode 9: a vertical strip from the strip records at $7436
;
; Opcode 9 of the room data (dispatch table `$73C7` entry 9). HL = the strip
; records `$7436` (16 records of 6 bytes), carry clear: the strip runs down
; (step 20). Falls into StripFromRecord `$A0CD`, which picks the record by the
; high nibble of the opcode byte, takes the layer page from the record and
; draws the run (DrawStrip `$A109`).
;
; The neighbours `$A0B9` (opcode 5, `$75AD`, across), `$A0BE` (opcode 10,
; `$7511`, across) and `$A0C4` (opcode 6, `$7400`, down; not run in the keyed
; recordings) lie before this range and join here.
;
; Witness: L1 1100 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14). Runs in deaths and rooms (45 in all).
RoomOpStripDown:
  LD HL,StructureSetB
; This entry point is used by the routine at ObjectRunV7400.
StripRecordGo:
  OR A                    ; the strip records in HL (entry from ObjectRunV7400)

; Draw a strip whose layer page is in its record
;
; In: HL = a strip table, carry = across (set) or down (clear), BC at the
; opcode byte. StripRecordAddress `$A0EE` points IX at record (high nibble of
; (BC)); StripPageFromRecord `$A101` takes the page from the record's byte 0
; (bit 7 off) and DrawStrip `$A109` draws.
;
; Callers: opcodes 5, 6, 9 and 10 (`$A0B9`, `$A0BE`, `$A0C4`, RoomOpStripDown
; `$A0C9`). 109 runs (deaths, rooms).
;
; Witness: L1 3099 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
StripFromRecord:
  CALL StripRecordAddress
  JR StripPageFromRecord

; Room opcode 7: a strip on layer $6900 from the records at $7571
;
; A = `$69`, the layer page; joins StripOnLayer `$A0D8`. 9 runs (rooms).
;
; Witness: L1 148 (rooms, poke-room x6, rzx x17, rzxroom x7).
RoomOpStrip69:
  LD A,$69
  JR StripOnLayer

; Room opcode 8: a strip on layer $6A00 from the records at $7571
;
; A = `$6A`; falls into StripOnLayer `$A0D8`. 3 runs (deaths, rooms).
;
; Witness: L1 133 (deaths, play48, rooms, poke-room x6, rzx x14, rzxroom x5).
RoomOpStrip6A:
  LD A,$6A

; StripOnLayer
;
; Used by the routine at RoomOpStrip69.
StripOnLayer:
  LD HL,StructureSetE     ; HL = the records $7571 (10 records): opcodes 7 and
                          ; 8 share them
  CALL StripRecordAddress
  CP $A7                  ; records below $75A7 (the first 6) run across
                          ; (carry), the rest down
  JR DrawStrip

; Room opcode 12: a strip on the wall layer $6800 from the records at $7496
;
; A = `$68`, HL = `$7496` (20 records). StripRecordAddress `$A0EE` returns A =
; the low byte of the record address: records below `$74DE` (the first 12) run
; across, the others down; then DrawStrip `$A109` with the page `$68`. 2 runs
; (rooms).
;
; Witness: L1 106 (rooms, poke-room x1, rzx x14, rzxroom x4).
RoomOpStrip68:
  LD A,$68
  LD HL,StructureSetC
  CALL StripRecordAddress
  CP $DE                  ; the first 12 records run across
  JR DrawStrip

; IX = a strip table + 6 x (the opcode byte's high nibble)
;
; In: HL = the table, A = the layer page (opcodes 7, 8, 12), BC = the opcode
; byte, F = the direction (kept). `OpHighNibble` `$A3E1` gives E = (BC) >> 4;
; `$8EDD` multiplies 6 x E; IX = HL + 6E. Out: IX = the record, H = the A
; given, A = the low byte of IX, the flags as given.
;
; A strip record (6 bytes): +0 the layer page, bit 7 set to mark the cells
; (flags `$6700` bit 0, property `$6C00`); +1 the tile alone or after a wall;
; +2 the first tile; +3 and +4 the middle tiles, alternated; +5 the last tile.
;
; Callers: StripFromRecord `$A0CD`, StripOnLayer `$A0D8`, RoomOpStrip68
; `$A0E2`. 123 runs.
;
; Witness: L1 3486 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
StripRecordAddress:
  PUSH AF
  PUSH HL
  CALL OpHighNibble
  LD H,$06
  CALL Multiply8          ; HL = 6 x E
  POP DE
  ADD HL,DE
  PUSH HL
  POP IX
  POP AF
  LD H,A
  LD A,L
  RET
; This entry point is used by the routine at StripFromRecord.
StripPageFromRecord:
  PUSH AF                 ; H = the record's page (byte 0, bit 7 cleared)
  LD A,(IX+$00)
  AND $7F
  LD H,A
  POP AF

; Draw a run of tiles: first, alternating middles, last; skip the cells where a
; wall stands
;
; In: IX = the strip record, H = the layer page, carry = across, BC at the
; opcode byte. StripStep `$6BDF` = 1 (across) or 20 (down). ReadRunLen16
; `$A3D1`: E = the low nibble of (BC) (16 when 0), L = the next byte, the first
; cell.
;
; One cell: the record's +1 tile (`$A15B`). Else +2 at the first cell, then for
; every next cell the middle tile, +3 and +4 by turns (the `LD D,(IX+n)`
; displacement at `$A125`, flipped by XOR 7); a cell whose wall layer `$6800`
; holds 1-$1A is left alone and the cell after it gets +1; the last cell gets
; +5. Across, every tile is written by PutStripTileMark `$A416` (marked when
; the record's bit 7 is set); down, only the first.
;
; Ends at RoomOpNext `$A1EE`. 123 runs (deaths, rooms); the alternation `$A138`
; 179.
;
; Witness: L1 3486 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
DrawStrip:
  LD A,$01
  JR C,DrawStripSetStep
  LD A,$14
DrawStripSetStep:
  LD (StripStep),A        ; StripStep $6BDF: 1 across, 20 down
  CALL ReadRunLen16
  DEC E
  JR Z,DrawStripSingle
  LD D,(IX+$02)           ; the first tile, record +2
  CALL PutStripTileMark
  LD A,$03                ; the middle tiles start at record +3
  LD (DrawStripMiddle+$0002),A
DrawStripMiddle:
  LD D,(IX+$03)           ; D = record +3 or +4: the displacement byte $A125 is
                          ; flipped below
  LD A,(StripStep)
  ADD A,L
  LD L,A
  DEC E
  JR Z,DrawStripEnd
DrawStripLoop:
  PUSH HL                 ; a wall (1-$1A) on the $6800 layer under this cell?
  LD H,$68
  LD A,(HL)
  DEC A
  POP HL
  CP $1A
  JR C,DrawStripOverWall
  CALL PutStripTile       ; no: write the middle tile, flip +3 / +4
  LD A,(DrawStripMiddle+$0002)
  XOR $07
  LD (DrawStripMiddle+$0002),A
  JR DrawStripMiddle
DrawStripOverWall:
  LD D,(IX+$01)           ; a wall: leave it, the next cell gets record +1
  LD A,(StripStep)
  ADD A,L
  LD L,A
  DEC E
  JR NZ,DrawStripLoop
  JR DrawStripLast
DrawStripEnd:
  LD D,(IX+$05)           ; the last cell: record +5
DrawStripLast:
  CALL PutStripTile
  JP RoomOpNext
DrawStripSingle:
  LD D,(IX+$01)           ; a run of one cell: record +1
  CALL PutStripTileMark
  JP RoomOpNext

; Room sub-opcode 0: a run of $77 across the $6B00 layer ($76 over a $75)
;
; Sub-opcode 0 of opcode 11 (table `$75EF` entry 0). ReadRunLen16 `$A3D1`: E
; cells from cell L; each cell of `$6B00` gets `$77`, or `$76` where it holds
; `$75`. Unmarked. Then RoomOpNext `$A1EE`.
;
; The mechanical cut took these bytes for data: no keyed recording ran them,
; the table `$75EF` points here. Not run in the keyed recordings; known only
; from the code.
;
; Witness: L1 21 (bossgate, poke-room x1, rzx x8).
SubOpRun77:
  CALL ReadRunLen16
  LD H,$6B
SubOpRun77Loop:
  LD D,$76                ; D = $76, $77 unless the cell holds $75
  LD A,(HL)
  CP $75
  JR Z,SubOpRun77Put
  INC D
SubOpRun77Put:
  LD (HL),D
  DEC E
  JP Z,RoomOpNext
  INC L
  JR SubOpRun77Loop

; Room sub-opcode 2: a pillar two cells wide, $2D / $2E on the $6800 layer
;
; ReadRun `$A3D5` (E rows, L the top-left cell). The top row is written and
; marked (PutTileMark `$A407`), each row below written plain: `$2D` left, `$2E`
; right. The background fill (`$A2BF`) turns a shaded `$2E` into `$2F`. 3 runs
; (deaths, rooms).
;
; Witness: L1 65 (deaths, play48, rooms, poke-room x5, rzx x9, rzxroom x4).
SubOpPillar:
  LD D,$2D
  LD H,$68
  CALL ReadRun
  CALL PutTileMark
  INC L
  INC D
  CALL PutTileMark
SubOpPillarLoop:
  LD A,$13                ; next row: +19 cells, back to the left column
  ADD A,L
  LD L,A
  DEC D
  DEC E
  JP Z,RoomOpNext
  LD (HL),D
  INC L
  INC D
  LD (HL),D
  JR SubOpPillarLoop

; Room sub-opcode 3: a column two cells wide, $31 / $32 on the $6B00 layer,
; property $10
;
; CellProperty `$6BE3` = `$10` for the run; ReadRun `$A3D5`; the top row marked
; and given the property (PutTileMarkProp `$A3F3`), the rows below the property
; only (PutTileProp `$A402`); then `$6BE3` = 0 and RoomOpNext `$A1EE`. 3 runs
; (rooms).
;
; Witness: L1 50 (rooms, poke-room x6, rzx x8, rzxroom x2).
SubOpColumn31:
  LD A,$10
  LD (CellProperty),A
  LD D,$31
  LD H,$6B
  CALL ReadRun
  CALL PutTileMarkProp
  INC L
  INC D
  CALL PutTileMarkProp
SubOpColumnRow:
  LD A,$13                ; next row
  ADD A,L
  LD L,A
  DEC D
; This entry point is used by the routine at SubOpColumnTop30.
SubOpColumnLoop:
  DEC E
  JR Z,SubOpColumnDone
  CALL PutTileProp
  INC L
  INC D
  CALL PutTileProp
  JR SubOpColumnRow
SubOpColumnDone:
  LD A,$00                ; the property back to 0
  LD (CellProperty),A
  JP RoomOpNext

; Room sub-opcode 4: the same column topped by $30, set one cell to the left
;
; CellProperty `$6BE3` = `$10`; `$30` at the first cell, `$31` one row down and
; one cell right, then SubOpColumnLoop `$A1B0` writes `$31` / `$32` pairs from
; the cell below the `$30` (the `$31` is overwritten by the `$32`, its mark
; stays). The deaths room shows `$30` at cell 26 and `$31` `$32` at 46, 47 with
; property `$10`. 1 run (deaths).
;
; Witness: L1 11 (deaths, play48, rzx x4, rzxroom x1).
SubOpColumnTop30:
  LD A,$10
  LD (CellProperty),A
  LD H,$6B
  CALL ReadRun
  INC E
  INC E
  LD D,$30
  CALL PutTileMarkProp
  LD A,L
  ADD A,$15
  LD L,A
  LD D,$31
  CALL PutTileMarkProp
  DEC L
  JR SubOpColumnLoop

; Room sub-opcode 1: set the cell flag $6700 to 1
;
; D = 1, joins SubOpClearMark at `$A1E8`: the next byte is a cell, its flag
; byte in `$6700` is set to D. Not run in the keyed recordings (the mechanical
; cut took the bytes for data; table `$75EF` entry 1 points here).
;
; Witness: L1 7 (rzx x2, rzxroom x2).
SubOpMarkCell:
  LD D,$01
  JR SubOpPutCellFlag

; Room sub-opcode 5: clear a cell's flag byte $6700
;
; D = 0; the cell is the next byte; `$6700` + cell = D. Falls into RoomOpNext.
; 8 runs (deaths, rooms).
;
; Witness: L1 29 (deaths, play48, rooms, rzx x2, rzxroom x2).
SubOpClearMark:
  LD D,$00
; This entry point is used by the routine at SubOpMarkCell.
SubOpPutCellFlag:
  LD H,$67                ; the cell's flag byte = D
  INC BC
  LD A,(BC)
  LD L,A
  LD (HL),D

; Back to the room opcode loop ($9FEE: the next byte, the opcode's count)
;
; `JP $9FEE`. The common exit of the strip and sub-opcode handlers. 138 runs.
;
; Witness: L1 3669 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
RoomOpNext:
  JP NextObject

; Room opcode 13: fill the back wall from one or two start cells
;
; The opcode byte: bits 0-3 = 13, bit 4 one more start cell, bits 5-7 the
; back-wall set. `$6BE0` = the set (0-7); `$6AE9` (the opcode count less the
; one the loop took) start cells follow, each handed to FillBackFrom `$A20D`;
; then `JP $9FD6`, the next opcode.
;
; 9 runs (deaths, rooms).
;
; Witness: L1 326 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
RoomOpFillBack:
  DEC BC
  LD A,(BC)
  AND $E0
  RLCA
  RLCA
  RLCA
  LD (BackWallSet),A      ; the back-wall set, bits 5-7 of the opcode byte
  LD A,(ZoneRecords+$0008)
RoomOpFillBackLoop:
  INC BC
  PUSH AF
  PUSH BC
  CALL FillBackFrom
  POP BC
  POP AF
  DEC A
  JR NZ,RoomOpFillBackLoop
  INC BC
  JP NextObjectGroup

; Fill the back wall down and right of a start cell
;
; In: BC at the start cell. `$6BE1` = the row's start cell. From the cell left
; of it the routine walks left to the wall that bounds the area (a wall tile
; 1-$1E on `$6800`, the first column, or a `$FF` stop mark, which it clears),
; then fills that row rightwards with FillBackRow `$A265` and goes one row down
; (`$6BE1` + 20) while the start cell of the row is not a wall, up to cell 219.
;
; A `$FF` met at the start of a row ends the fill: `$A22C` clears the `$FF`
; marks of that row up to `$6BE2` (set by FillBackRow when it met one).
;
; Callers: RoomOpFillBack `$A1F1`. 12 runs.
;
; Witness: L1 446 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
FillBackFrom:
  LD A,(BC)
  LD L,A
  LD (FillRowStart),A
  LD H,$68
  JR FillBackSeekLeft
FillBackClearStop:
  LD (HL),$00             ; a $FF stop mark: clear it
FillBackRowStart:
  INC L                   ; fill this row, then the next row down
  CALL FillBackRow
  LD A,(FillRowStart)
  ADD A,$14
  LD (FillRowStart),A
  CP $DC
  RET NC
  LD L,A
  LD A,(HL)
  INC A
  JR NZ,FillBackTestStart
FillBackClearMarks:
  LD A,(FillStopCell)     ; clear the $FF marks of the row up to $6BE2
  LD (HL),$00
  INC L
  CP L
  RET Z
  LD A,(HL)
  INC A
  RET NZ
  JR FillBackClearMarks
FillBackTestStart:
  DEC A                   ; empty or a non-wall cell: go on; a wall: stop
  JR Z,FillBackSeekLeft
  CP $1F
  RET C
FillBackSeekLeft:
  DEC L                   ; walk left to the bounding wall
  LD A,(HL)
  INC A
  JR Z,FillBackClearStop
  CALL IsRowStart
  LD A,(HL)
  JR Z,FillBackColumn0
  OR A
  JR Z,FillBackSeekLeft
  CP $1F
  JR NC,FillBackSeekLeft
  JR FillBackRowStart
FillBackColumn0:
  OR A                    ; the first column: an empty cell starts the row only
                          ; when the cell above is not solid
  JR NZ,FillBackRowStart
  DEC A
  CP $1F
  JR C,FillBackRowStart
  CALL IsSolid
  JR C,FillBackRowStart
  CALL ShadeFirstColumn
  JR FillBackRowStart

; Fill one row of the back wall rightwards from cell L
;
; Per cell of `$6800`: a wall (1-$18) ends the row; `$FF` is cleared and ends
; it (`$6BE2` = the cell below + 20, for FillBackFrom); an empty cell or a back
; tile ($19 and up) is tested with IsSolid `$A32F` against the front layers:
;
; - not solid (`$A27D`): ShadeCell `$A2B5`: the shading of the left, upper and
; upper-left neighbours; an empty cell gets the set's back tile `$1A` + `$6BE0`
; and the shading property;
;
; - solid (a ladder, column or ledge stands here, `$A28D`): when the cell above
; holds a ledge (`$50-$52` on `$6B00`), the ladder or column tile here (`$57`
; on `$6B00`, `$80` on `$6900`, `$55` on `$6A00`, the pairs at `$72D8`) is
; turned into its top tile (one less).
;
; The row ends at the last column (IsRowStart `$A3EA` on the next cell). 579
; runs.
;
; Witness: L1 18464 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
FillBackRow:
  LD A,(HL)
  OR A
  JR Z,FillBackRowCell
  INC A
  JR NZ,FillBackRowWall
  LD (HL),A
  LD A,L
  ADD A,$14
  LD (FillStopCell),A
  RET
FillBackRowWall:
  CP $1A                  ; 1-$18: a wall ends the row
  JR C,FillBackRowEnd
FillBackRowCell:
  CALL IsSolid            ; a solid front tile in this cell?
  JR C,FillBackUnderLedge
  CALL ShadeCell
  JR FillBackRowNext
FillBackRowEnd:
  CP $1C
  RET C
FillBackRowNext:
  INC L                   ; next cell; the first column of the next row ends
                          ; the row
  CALL IsRowStart
  JR NZ,FillBackRow
  DEC L
  RET
FillBackUnderLedge:
  LD B,$03                ; solid: a ledge above? (3 pairs at $72B4: $50-$52 on
                          ; $6B00)
  LD DE,LedgeTiles
  CALL IsAboveInList
  JR NC,FillBackRowNext
  PUSH HL
  LD DE,TopTiles
  LD B,$03
FillBackTopTile:
  LD A,(DE)               ; the tile here becomes its top variant (pairs at
                          ; $72D8)
  INC DE
  LD H,A
  LD A,(DE)
  INC DE
  CP (HL)
  JR NZ,FillBackTopNext
  DEC (HL)
FillBackTopNext:
  DJNZ FillBackTopTile
  POP HL
  JR FillBackRowNext

; Shading of a cell in the first column: only the cell above counts
;
; B = 33, DE = `$7292` (the solid list with `$2E` on `$6800`); C = 3 when the
; cell above is solid (IsAboveInList `$A320`), else 0; joins ShadeCellApply
; `$A2B8`. 4 runs (rooms).
;
; Witness: L1 468 (rooms, poke-room x7, rzx x47, rzxroom x6).
ShadeFirstColumn:
  LD B,$21
  LD DE,SolidTiles
  CALL IsAboveInList
  JR ShadeCellApply

; Shade a back cell from its neighbours, give an empty cell the back tile
;
; NeighbourShade `$A300` sets C (bit 2 left, bit 1 above, bit 0 above-left
; solid). Falls into ShadeCellApply `$A2B8`: an empty cell gets
; SetShadeProperty `$A2CD` and the back tile `$1A` + set (`$A2F6`); a back tile
; already there is shaded only when C is not 0, and a pillar's right half `$2E`
; with C 4 or 5 becomes `$2F`. 369 runs.
;
; Witness: L1 14525 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
ShadeCell:
  CALL NeighbourShade

; ShadeCellApply
;
; Used by the routine at ShadeFirstColumn.
ShadeCellApply:
  LD A,(HL)
  OR A
  JR Z,ShadeEmptyCell
  LD A,C
  OR A
  RET Z
  LD A,(HL)
  CP $2E
  JR NZ,SetShadeProperty
  LD A,C
  CP $04
  RET C
  CP $06
  RET NC
  INC (HL)
  RET

; Write the shading shape C into the cell property, the corner overlay into
; $6900
;
; C = 4 (left only): `$65` into `$6900` when the cell is empty there; C = 2
; (above only): `$66`; C 5-7 become 4-6; the low nibble of `$6C00` + L = the
; result (high nibble kept). Out: H = `$68`. 360 runs.
;
; Witness: L1 14016 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
SetShadeProperty:
  LD A,C
  CP $04
  LD B,$65
  CALL Z,PutOverlayIfEmpty
  LD B,$66
  CP $02
  CALL Z,PutOverlayIfEmpty
  CP $05
  JR C,SetShadeNibble
  DEC A
SetShadeNibble:
  LD B,A
  LD H,$6C
  LD A,(HL)
  AND $F0
  OR B
  LD (HL),A
  LD H,$68
  RET

; Write B into layer H+1 at cell L when that cell is empty
;
; Callers: SetShadeProperty `$A2CD`. 25 runs, 22 writes.
;
; Witness: L1 603 (bossgate, deaths, play48, rooms, poke-room x13, rzx x54,
; rzxroom x11).
PutOverlayIfEmpty:
  PUSH AF
  INC H
  LD A,(HL)
  OR A
  JR NZ,PutOverlayDone
  LD (HL),B
PutOverlayDone:
  POP AF
  DEC H
  RET
; This entry point is used by the routine at ShadeCellApply.
ShadeEmptyCell:
  CALL SetShadeProperty   ; the shading, then the back tile $1A + set
  LD A,(BackWallSet)
  ADD A,$1A
  LD (HL),A
  RET

; C = the solid bits of the left, upper and upper-left neighbours
;
; B = 33, DE = `$7292`, C = 0; TestCellSolid `$A334` on L-1, L-20, L-21, each
; shifting its result into C. C = 7 becomes 6. Out: C, H = `$68`. 369 runs.
;
; Witness: L1 14525 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
NeighbourShade:
  LD B,$21
  LD DE,SolidTiles
  LD C,$00
  PUSH HL
  DEC L
  CALL TestCellSolid
  LD A,$ED
  ADD A,L
  LD L,A
  CALL TestCellSolid
  DEC L
  CALL TestCellSolid
  POP HL
  LD H,$68
  LD A,$07
  CP C
  RET NZ
  DEC C
  RET

; Is the cell above L in the B-entry tile list at DE?
;
; Carry and C = 3 when it is, else C = 0. Callers: FillBackRow `$A28D` (3 ledge
; pairs at `$72B4`), ShadeFirstColumn `$A2AB`. 153 runs.
;
; Witness: L1 3158 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
IsAboveInList:
  PUSH HL
  LD A,L
  SUB $14
  LD L,A
  CALL TestCellSolid
  POP HL
  LD C,$00
  RET NC
  LD C,$03
  RET

; Is cell L solid: a wall, or a front tile from the list at $7294?
;
; B = 34, DE = `$7294` (the list less its first pair, `$2E` on `$6800`). Falls
; into TestCellSolid. 530 runs.
;
; Witness: L1 17949 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
IsSolid:
  LD B,$22
  LD DE,SolidTiles+$0002

; Carry when cell L is a wall (1-$19 on $6800) or holds a (page, tile) pair of
; the list at DE
;
; In: L = the cell, DE = the list of (page, tile) pairs, B = its length. A wall
; code 1-$19 on `$6800` is solid at once; otherwise each pair is tried. Out:
; carry = solid, and the result shifted into C (`RL C`); HL, DE, B kept.
;
; The list `$7292` (38 pairs): `$2E` on `$6800`; `$7F` `$80` `$40` `$42` `$3F`
; `$41` `$4C` `$4F` on `$6900`; `$54` `$55` `$40` `$42` `$3F` `$41` `$4C` `$4F`
; on `$6A00`; `$50-$52` `$32` `$30` `$27-$2C` `$57` `$56` `$81-$83` `$31` on
; `$6B00`; then `$2D` on `$6800` and the three top-tile pairs at `$72D8`. 1790
; runs; the pair loop 39917.
;
; Witness: L1 64682 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
TestCellSolid:
  PUSH HL
  PUSH DE
  PUSH BC
  LD H,$68
  LD A,(HL)
  OR A
  JR Z,TestCellSolidLoop
  CP $1A
  JR C,TestCellSolidDone
TestCellSolidLoop:
  LD A,(DE)
  LD H,A
  INC E
  LD A,(DE)
  CP (HL)
  JR Z,TestCellSolidYes
  INC E
  DJNZ TestCellSolidLoop
  XOR A
  JR TestCellSolidDone
TestCellSolidYes:
  SCF
TestCellSolidDone:
  POP BC                  ; C = C x 2 + carry
  POP DE
  POP HL
  PUSH AF
  RL C
  POP AF
  RET

; Room opcode 14: a ledge across the $6B00 layer and its shadow
;
; ReadRunLen16 `$A3D1` (E cells, L the first). The previous byte's high nibble
; picks the tiles: `$20` gives IX = `$73BD` (`$70`, `$71` at a crossing of
; `$57` / `$56`), else `$73C1` (`$72`, `$73` at a crossing of `$75` / `$74`).
; Every cell gets its tile and the mark (PutTileMark `$A407`); the shading
; nibble of `$6C00` becomes 6 (7 after the first cell, 7 also at a first cell
; in the first column when its nibble was 0, kept 6 when it was 2).
;
; The cell after the ledge, when it is in the same row and not solid, gets the
; shading 8 or 5 ORed in and the corner `$65` on `$6900`: the ledge's shadow.
; Then RoomOpNext. 7 runs (rooms).
;
; Witness: L1 256 (bossgate, rooms, poke-room x11, rzx x38, rzxroom x10).
RoomOpLedge:
  CALL ReadRunLen16
  PUSH BC
  DEC BC
  LD A,(BC)
  AND $F0
  CP $20
  LD IX,ShapeTilesA
  JR Z,RoomOpLedgeFirstShade
  LD IX,ShapeTilesB
RoomOpLedgeFirstShade:
  LD C,$06
  LD H,$6C
  LD A,(HL)
  AND $0F
  CP $02
  JR Z,RoomOpLedgeLoop
  OR A
  JR NZ,RoomOpLedgeShade7
  CALL IsRowStart
  JR NZ,RoomOpLedgeLoop
RoomOpLedgeShade7:
  LD C,$07
RoomOpLedgeLoop:
  LD H,$6B                ; a crossing tile where a ladder or column already
                          ; stands
  LD A,(HL)
  LD D,(IX+$01)
  CP (IX+$02)
  JR Z,RoomOpLedgePut
  CP (IX+$03)
  JR Z,RoomOpLedgePut
  LD D,(IX+$00)
RoomOpLedgePut:
  CALL PutTileMark
  LD H,$6C
  LD A,(HL)
  AND $F0
  OR C
  LD (HL),A
  LD C,$07
  INC L
  DEC E
  JR NZ,RoomOpLedgeLoop
  CALL IsRowStart         ; the cell after the ledge: same row, not solid?
  JR Z,RoomOpLedgeDone
  CALL IsSolid
  JR C,RoomOpLedgeDone
  LD H,$6C
  LD A,(HL)
  AND $0F
  LD C,$08
  JR Z,RoomOpLedgeShadow
  CP $01
  JR Z,RoomOpLedgeShadow
  LD C,$05
RoomOpLedgeShadow:
  LD A,(HL)
  AND $0F
  OR C
  LD (HL),A
  LD H,$69
  LD (HL),$65
RoomOpLedgeDone:
  POP BC
  JP NextObject

; BC = the address of room A's data (the word table at $7100)
;
; BC = the word at `$7100` + 2A. Callers: `$9F34` (the room and the room
; above). 25 runs.
;
; Witness: L1 279 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
RoomDataAddress:
  LD H,$71
  RLCA
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  RET

; E = the run length (low nibble of (BC), 16 when 0), L = the next byte (the
; first cell)
;
; Callers: DrawStrip `$A109`, RoomOpLedge `$A357`, SubOpRun77 `$A164`. Falls
; into ReadRunCommon. Out: BC at the cell byte.
;
; Witness: L1 3763 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
ReadRunLen16:
  LD E,$10
  JR ReadRunCommon

; E = the low nibble of (BC) (0 kept when 0), L = the next byte
;
; Callers: SubOpPillar, SubOpColumn31, SubOpColumnTop30, SetupRoomObjects. 30
; runs.
;
; Witness: L1 332 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
ReadRun:
  LD E,$00

; The shared body of ReadRun and ReadRunLen16
;
; Witness: L1 4095 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
ReadRunCommon:
  LD A,(BC)
  AND $0F
  JR Z,ReadRunCell
  LD E,A
ReadRunCell:
  INC BC
  LD A,(BC)
  LD L,A
  RET

; E = A = the high nibble of (BC)
;
; Callers: `$9F63`, `$9FD6`, StripRecordAddress `$A0EE`, SetupRoomObjects
; `$A41E`. 333 runs.
;
; Witness: L1 7132 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
OpHighNibble:
  LD A,(BC)
  RRA
  RRA
  RRA
  RRA
  AND $0F
  LD E,A
  RET

; Z when cell L starts a row (20, 40, ... 240)
;
; Subtracts 20 up to 12 times. Cell 0 is not found (NZ). B is lost. 656 runs.
;
; Witness: L1 23797 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x14).
IsRowStart:
  LD A,L
  LD B,$0C
IsRowStartLoop:
  SUB $14
  RET Z
  DJNZ IsRowStartLoop
  RET

; Write D at (HL), set the cell's flag $6700 to 1 and its property to
; CellProperty
;
; Witness: L1 122 (deaths, play48, rooms, poke-room x6, rzx x10, rzxroom x3).
PutTileMarkProp:
  LD A,D

; The same with the tile in A
;
; Caller: `$A039` (opcode 4, the outdoor rows). 388 runs.
;
; Witness: L1 942 (deaths, gameover, havok, hiscore, menu, play48, rooms,
; throw, c x1, opt x3, poke-room x6, rzx x11, rzxroom x8).
PutTileMarkPropA:
  LD (HL),A

; $6700 + L = 1, $6C00 + L = CellProperty $6BE3
;
; Witness: L1 7172 (deaths, gameover, havok, hiscore, menu, play48, rooms,
; throw, c x1, opt x3, poke-room x11, rzx x47, rzxroom x17).
MarkCellProp:
  PUSH HL
  LD H,$67
  LD (HL),$01

; $6C00 + L = CellProperty $6BE3 (HL on the stack)
;
; Witness: L1 7210 (deaths, gameover, havok, hiscore, menu, play48, rooms,
; throw, c x1, opt x3, poke-room x11, rzx x47, rzxroom x17).
SetCellProp:
  LD A,(CellProperty)
  LD H,$6C
  LD (HL),A
  POP HL
  RET

; Write D at (HL) and the cell property, no mark
;
; Witness: L1 38 (deaths, play48, rzx x5, rzxroom x2).
PutTileProp:
  LD A,D
  LD (HL),A
  PUSH HL
  JR SetCellProp

; Write D at (HL) and set the cell flag $6700 to 1
;
; Witness: L1 1283 (bossgate, deaths, play48, rooms, poke-room x11, rzx x41,
; rzxroom x12).
PutTileMark:
  LD A,D

; The same with the tile in A
;
; Caller: `$9F63` (the room data's tile blocks). 847 runs.
;
; Witness: L1 11476 (bossgate, deaths, play48, rooms, poke-room x15, rzx x54,
; rzxroom x14).
PutTileMarkA:
  LD (HL),A
  PUSH HL
  LD H,$67
  LD (HL),$01
  POP HL
  RET

; A middle or last strip tile: plain down, marked across
;
; Writes D; when StripStep `$6BDF` is even (down) that is all; across it goes
; on as PutStripTileMark.
;
; Witness: L1 9126 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
PutStripTile:
  LD (HL),D
  LD A,(StripStep)
  RRA
  RET NC

; Write D, and mark the cell when the strip record's +0 has bit 7
;
; Witness: L1 8757 (bossgate, deaths, play48, rooms, poke-room x15, rzx x55,
; rzxroom x16).
PutStripTileMark:
  LD (HL),D
  BIT 7,(IX+$00)
  RET Z
  JR MarkCellProp

; Read the room's zones, items and enemies; draw the items; restore the room's
; state
;
; Called from `$95C3` (the room lookup) with BC after the room's build data. BC
; is pushed and popped round the surface (BuildSurface); the variants do not
; read it. 23 runs (c1, deaths, gameover, menu, opt2-4, rooms).
;
; 1. The zones: up to 6 records, their addresses in `$6AE1` (count `$6AE0`). A
; record: a header (bits 4-6 n rectangles, bit 3 the last record, bits 0-2 m
; single cells), n pairs (first cell, last cell), m cells. A room without zones
; (first byte 0) gets the one record `$75FB`.
;
; 2. A count byte: low nibble the items, high nibble the enemies (`$6ADC`,
; `$6ADD`); the 2-byte records of both are copied to RoomObjectList `$5B01`,
; `$6ADE` = the start of the enemies.
;
; 3. Clears `$9A59`, byte +2 (active) of the actor pages `$5E00-$6600` (all but
; Hiro) and the enemy slots `$68DC-$68EB`; `$8F75`; BuildZones `$A4D1` (which
; also restores the room's state and reveals Hiro's zone).
;
; 4. The items: item i is skipped when bit i (from bit 7) of `$6DFE` (the
; room's taken items) is set; else its kind (bits 5-7 of the first byte) picks
; a (tile, page) pair at `$7BD8` (`$19`/`$1A`/`$8C` on `$6900`,
; `$8C`/`$8D`/`$19` on `$6A00`) and the tile goes into its cell (second byte);
; the cell flag gets bit 1 unless the tile is `$8C`.
;
; Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
SetupRoomObjects:
  LD D,$01
  LD HL,ZoneRecords
  LD A,(BC)
  OR A
  JR NZ,SetupZonesLoop
  LD (HL),$FB             ; no zones: the default zone record $75FB
  INC L
  LD (HL),$75
  INC BC
  JR SetupRoomCounts
SetupZonesNext:
  INC D
SetupZonesLoop:
  LD (HL),C               ; record size: 1 + 2n + m
  INC L
  LD (HL),B
  INC L
  LD A,(BC)
  AND $08
  PUSH AF
  LD A,(BC)
  AND $07
  LD E,A
  LD A,(BC)
  AND $70
  RRCA
  RRCA
  RRCA
  INC A
  ADD A,E
  ADD A,C
  LD C,A
  LD A,$00
  ADC A,B
  LD B,A
  POP AF
  JR Z,SetupZonesNext
SetupRoomCounts:
  LD A,D                  ; low nibble items, high nibble enemies
  LD (ZoneCount),A
  CALL OpHighNibble
  LD D,A
  CALL ReadRun
  LD A,E
  LD (ItemCount),DE
  LD L,C
  LD H,B
  LD B,$00
  LD DE,RoomObjectList             ; copy the item records to RoomObjectList
  OR A
  JR Z,SetupRoomEnemies
  RLCA
  LD C,A
  LDIR
SetupRoomEnemies:
  LD (EnemyListPtr),DE    ; $6ADE: where the enemy records start
  LD A,(EnemyCount)
  OR A
  JR Z,SetupRoomClear
  RLCA
  LD C,A
  LDIR
SetupRoomClear:
  XOR A                   ; clear $9A59, the actors' active bytes, the enemy
                          ; slots
  LD (RunActorSteps+$000E),A
  LD B,$09
  LD HL,IntroBox+$0007
SetupRoomClearActors:
  LD (HL),A
  INC H
  DJNZ SetupRoomClearActors
  LD B,$10
  LD HL,EnemySlots
SetupRoomClearSlots:
  LD (HL),A
  INC HL
  DJNZ SetupRoomClearSlots
  CALL ActorScreenBox
  CALL BuildZones
  LD A,(ItemCount)
  OR A
  RET Z
  LD B,A
  LD HL,RoomObjectList
SetupRoomItemLoop:
  LD A,(TakenItems)       ; the item's bit of $6DFE: taken?
  LD C,A
  LD A,(ItemCount)
  SUB B
  INC A
SetupRoomItemBit:
  RL C
  DEC A
  JR NZ,SetupRoomItemBit
  LD A,(HL)
  INC HL
  LD C,(HL)
  JR C,SetupRoomItemNext
  PUSH HL
  AND $E0
  RLCA
  RLCA
  RLCA
  RLCA
  LD HL,ObjectTilePlaces  ; the kind's (tile, page) pair at $7BD8
  ADD A,L
  LD L,A
  LD A,(HL)
  INC L
  LD D,(HL)
  LD E,C
  LD (DE),A
  CP $8C
  JR Z,SetupRoomItemSkip
  LD D,$67                ; not $8C: cell flag bit 1
  LD A,(DE)
  OR $02
  LD (DE),A
SetupRoomItemSkip:
  POP HL
SetupRoomItemNext:
  INC HL
  DJNZ SetupRoomItemLoop
  RET

; Write the zone bits into the cell flags; restore the room's state; reveal
; Hiro's zone
;
; Zone k (k = 0-5) gets the bit `$80` >> k. For each rectangle (first, last
; cell) the width and height are found by dividing (last - first) by 20
; (`$A502`), and each cell whose flag is below 2 gets the bit; then each single
; cell of the record gets it over its zone bits (`AND 3` / `OR C`).
;
; Then the room's two saved state bytes: `$6D00` + 2 (room - 1) to `$6DFE`
; (taken items) and `$6DFF` (revealed zones), `$6E00` + 2 (room - 1) to `$6EFE`
; / `$6EFF` (enemies gone); `JP RevealZone` `$A569`. 23 runs.
;
; Witness: L1 206 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
BuildZones:
  LD A,(ZoneCount)
  LD B,A
  LD C,$01
  LD IX,ZoneRecords
BuildZonesLoop:
  LD L,(IX+$00)
  INC IX
  LD H,(IX+$00)
  INC IX
  LD A,(HL)
  RRC C
  LD E,C
  LD A,(HL)
  PUSH AF
  AND $70
  JR Z,BuildZonesCells
  RRCA
  RRCA
  RRCA
  RRCA
  PUSH BC
  LD D,A
  INC HL
BuildZonesRect:
  PUSH HL                 ; the rectangle: (last - first) / 20 gives rows and
                          ; columns
  INC HL
  LD A,(HL)
  DEC HL
  SUB (HL)
  PUSH DE
  LD E,A
  LD C,$14
  XOR A
  LD B,$08
BuildZonesDivide:
  RL E
  RLA
  SUB C
  JR NC,BuildZonesDivNext
  ADD A,C
BuildZonesDivNext:
  DJNZ BuildZonesDivide
  LD C,A
  LD A,E
  RLA
  CPL
  INC C
  INC A
  LD B,A
  POP DE
  LD L,(HL)
  LD H,$67
BuildZonesRow:
  PUSH HL
  PUSH BC
BuildZonesCell:
  LD A,(HL)               ; flag below 2: no zone yet, take this one
  CP $02
  JR NC,BuildZonesCellNext
  OR E
  LD (HL),A
BuildZonesCellNext:
  INC L
  DEC C
  JR NZ,BuildZonesCell
  POP BC
  POP HL
  LD A,L
  ADD A,$14
  LD L,A
  DJNZ BuildZonesRow
  POP HL
  INC HL
  INC HL
  DEC D
  JR NZ,BuildZonesRect
  DEC HL
  POP BC
BuildZonesCells:
  POP AF                  ; the single cells of the record
  AND $07
  JR Z,BuildZonesNext
  PUSH BC
  LD B,A
BuildZonesCellLoop:
  INC HL
  LD D,$67
  LD E,(HL)
  LD A,(DE)
  AND $03
  OR C
  LD (DE),A
  DJNZ BuildZonesCellLoop
  POP BC
BuildZonesNext:
  DJNZ BuildZonesLoop
  CALL RoomItemState      ; the room's state bytes from $6D00 / $6E00
  LDI
  LDI
  CALL RoomEnemyState
  LDI
  LDI
  JP RevealZone

; HL = $6E00 + 2 (room - 1), DE = $6EFE: the room's enemy bits
;
; Witness: L1 398 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
RoomEnemyState:
  LD H,$6E
  JR RoomStateAddress

; HL = $6D00 + 2 (room - 1), DE = $6DFE: the room's item and zone bits
;
; Witness: L1 398 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
RoomItemState:
  LD H,$6D

; L = 2 (room - 1), DE = H:$FE
;
; Witness: L1 796 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x56, rzxroom x18).
RoomStateAddress:
  LD E,$FE
  LD D,H
  LD A,(Room)
  DEC A
  RLCA
  LD L,A
  RET

; Add the zone under the actor's feet to the revealed zones; Z when it is new
;
; The operand of `LD HL,n` at `$A56D` holds two cells, written by `$8FCF` for
; the actor just placed: L when bit 7 of `$5D1B` is set, else H. The zone bits
; (`AND $FC`) of the flag byte one row below (`$6700` + cell + 20) are tested
; against RevealedZones `$6DFF`: already there gives NZ; a new zone is added
; and A = 0, Z.
;
; Callers: `$955A` (every pass of play), BuildZones `$A4D1`. 2356 runs.
;
; Witness: L1 42139 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
RevealZone:
  LD A,(RevealedZones)
  LD C,A
  LD HL,$0000
  LD A,(Hiro+$001B)
  RLA
  JR C,RevealZoneTest
  LD L,H
RevealZoneTest:
  LD A,L
  ADD A,$14
  LD L,A
  LD H,$67
  LD A,(HL)
  AND $FC
  LD D,A
  AND C
  RET NZ
  LD A,D
  OR C
  LD (RevealedZones),A
  XOR A
  RET

; Copy $6DFE-$6DFF and $6EFE-$6EFF back to the room's entries in $6D00 / $6E00
;
; Called from `$955A` when Hiro leaves a room. 15 runs (c1, deaths, gameover,
; rooms).
;
; Witness: L1 192 (bossgate, deaths, gameover, hiscore, play48, rooms, c x1,
; poke-room x15, rzx x55, rzxroom x17).
SaveRoomState:
  CALL RoomItemState
  EX DE,HL
  LDI
  LDI
  CALL RoomEnemyState
  EX DE,HL
  LDI
  LDI
  RET
