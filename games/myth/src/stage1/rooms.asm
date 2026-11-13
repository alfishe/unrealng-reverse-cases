; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The room data, Unrle, the room builder and the room changes
;
; A stage's map is up to three grids of blocks of 2 x 2 tiles (Grid0, Grid1, Grid2 at $9B6F: the size, the start
; window, the room table of exits); a room is a window of 14 x 9 blocks stepping 11 columns and 6 rows. At each room
; change RoomChange $988B unpacks StageGraphics (Unrle $A424) into the play buffer, RoomCells $9928 writes the
; window's 28 x 18 tile numbers into Cells, the tiles are drawn once onto the screen with their colours into
; ShadowAttributes, BuildSpans $99E9 lists the open runs, and LoadRoomActors $A4CC puts the room's placements into
; actor records. The room exits ($AADA) and the grid passages ($AB1C) move the window.
; --------------------------------------------------------------------------------------------------------------------

  ORG $922F

; Clear the taken flags of the stage's three object lists
;
; The lists at $9BA0, $9C69 and $9C78: 3-byte entries up to $FF, bit 7 of the
; first byte cleared (ClearTakenFlags).
;
; Witness: L1 2 (s1-idle, s1-right).
ResetObjectLists:
  LD HL,Grid0Placements
  CALL ClearTakenFlags
  LD HL,Grid1Placements
  CALL ClearTakenFlags
  LD HL,Grid2Placements

; Clear bit 7 of each 3-byte entry at HL up to the $FF end
;
; Witness: L1 156 (s1-idle, s1-right).
ClearTakenFlags:
  LD A,(HL)
  CP $FF
  RET Z
  AND $7F
  LD (HL),A
  INC HL
  INC HL
  INC HL
  JP ClearTakenFlags

  ORG $988B

; Build the room: unpack the stage's graphics, draw the scenery, make the spans
;
; BurstTimer = 100. Unrle $A424 the packed tiles and map $B4B2 into $5B00 (the
; play buffer), clear the shots, build
;
; the cells (RoomCells, IX = RoomGrid), $A057, then patch the tile bitmaps' and
; the attributes' addresses into $98F1
;
; and $98D3 (from the header words $5B02, $5B04) and draw every cell of the 18
; x 28 play area: its attribute into
;
; the shadow $6DC2 and its 8 bitmap bytes straight onto the screen
; (CopyTileToScreen, from line 48 column 2). Then
;
; BuildSpans, ClearBuffer (the unpacked data is gone) and the actors (JP
; $A4CC).
;
; Witness: L1 26 (c1o, deaths, s1-idle, s1-right).
RoomChange:
  LD A,$64
  LD (BurstTimer),A
  LD HL,StageGraphics
  LD DE,PlayBuffer
  CALL Unrle
  CALL ClearShots
  LD IX,(RoomGrid)
  CALL RoomCells
  CALL BlackOutPlayArea
  LD HL,(PlayBuffer+2)
  LD BC,PlayBuffer+10
  ADD HL,BC
  LD (RoomChangeBitmaps+$0001),HL
  LD HL,(PlayBuffer+4)
  ADD HL,BC
  LD (RoomChangeAttrs+$0001),HL
  LD DE,CellsPlay
  LD IY,PlayAttributesCell
  LD HL,ScreenLineTable+96
  LD B,$12
RoomChangeRow:
  PUSH BC
  PUSH HL
  LD B,$1C
  LD A,$02
  LD (CellColumn),A
RoomChangeCell:
  PUSH BC
  PUSH HL
  LD A,(DE)
  LD C,A
  LD B,$00
RoomChangeAttrs:
  LD HL,$0000             ; LD HL,n: n = the tile attributes' address
  ADD HL,BC
  LD A,(HL)
  LD (IY+$00),A
  INC IY
  POP HL
  PUSH DE
  PUSH HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD A,(CellColumn)
  ADD A,C
  LD L,A
  LD H,B
  EX DE,HL
  LD A,(HL)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
RoomChangeBitmaps:
  LD BC,$0000             ; LD BC,n: n = the tile bitmaps' address
  ADD HL,BC
  CALL CopyTileToScreen
  POP HL
  POP DE
  LD A,(CellColumn)
  INC A
  LD (CellColumn),A
  INC DE
  POP BC
  DJNZ RoomChangeCell
  LD BC,$0004
  ADD IY,BC
  POP HL
  LD BC,$0010
  ADD HL,BC
  POP BC
  INC DE
  INC DE
  INC DE
  INC DE
  DEC B
  JR NZ,RoomChangeRow
  CALL BuildSpans
  CALL ClearBuffer
  JP LoadRoomActors

; Copy 8 bytes from HL to the screen cell DE (INC D a line)
;
; Witness: L1 13104 (c1o, deaths, s1-idle, s1-right).
CopyTileToScreen:
  LD B,$08
CopyTileLine:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ CopyTileLine
  RET

; Write the room's 14 x 9 blocks as 28 x 18 tile numbers into the cells $7282
;
; IX = the grid record (+0 the width in blocks, +6 the grid's offset in the
; map). The window starts at
;
; RoomRow x width + RoomColumn of the map ($5B0A + the header word $5B08 + the
; offset); each block becomes 2 x 2 tiles
;
; (PutBlock), the cells 64 bytes a block row (32 a cell row, columns 2-29).
;
; Witness: L1 26 (c1o, deaths, s1-idle, s1-right).
RoomCells:
  LD HL,$0000
  LD A,(RoomRow)
  CP $00
  JR Z,RoomCellsColumn
  LD B,A
  LD E,(IX+$00)
  LD D,$00
RoomCellsRowOffset:
  ADD HL,DE
  DJNZ RoomCellsRowOffset
RoomCellsColumn:
  LD A,(RoomColumn)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,(PlayBuffer+8)
  ADD HL,BC
  LD BC,PlayBuffer+10
  ADD HL,BC
  LD C,(IX+$06)
  LD B,(IX+$07)
  ADD HL,BC
  PUSH HL
  POP IY
  LD HL,CellsPlay
  LD B,$09
RoomCellsRow:
  PUSH IY
  PUSH BC
  PUSH HL
  LD B,$0E
RoomCellsBlock:
  PUSH BC
  PUSH HL
  PUSH IY
  LD A,(IY+$00)
  CALL PutBlock
  POP IY
  POP HL
  POP BC
  INC HL
  INC HL
  INC IY
  DJNZ RoomCellsBlock
  POP HL
  POP BC
  POP IY
  LD DE,$0040
  ADD HL,DE
  LD E,(IX+$00)
  LD D,$00
  ADD IY,DE
  DJNZ RoomCellsRow
  RET

; Write block A's 4 tile numbers at HL, HL + 1, HL + 32, HL + 33
;
; The blocks are 4 tile numbers each at $5B0A + the header word $5B06 (top
; left, top right, bottom left, bottom
;
; right). Also writes CellFlag (0) into each cell's twin 576 bytes lower ($7040
; grid). Returns HL + 1 + 32.
;
; Witness: L1 3276 (c1o, deaths, s1-idle, s1-right).
PutBlock:
  PUSH AF
  LD C,$00
  LD A,(IY+$00)
  CP $59
  JR NC,PutBlockFlag
  LD C,$00
PutBlockFlag:
  LD A,C
  LD (CellFlag),A
  POP AF
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,(PlayBuffer+6)
  ADD HL,BC
  LD BC,PlayBuffer+10
  ADD HL,BC
  PUSH HL
  POP IY
  EX DE,HL
  LD A,(IY+$00)
  LD (HL),A
  PUSH HL
  LD BC,-576
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  INC HL
  LD A,(IY+$01)
  LD (HL),A
  PUSH HL
  LD BC,-576
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  LD BC,$001F
  ADD HL,BC
  LD A,(IY+$02)
  LD (HL),A
  PUSH HL
  LD BC,-576
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  INC HL
  LD A,(IY+$03)
  LD (HL),A
  PUSH HL
  LD BC,-576
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  RET

  ORG $9B6F

; Grid 0's record (stage 1: the surface and the caves): 69 x 21 blocks, the
; start window at block column 22, row 0, the room table Grid0Rooms, map offset
; 0, 6 rooms a grid row
;
; A grid record, 9 bytes: +0 the width and +1 the height in blocks, +2/+3 the
; start window's block column and row (where StartGrid $A444 puts the window;
; the grid passages rewrite them, $ABBA-$AC30), +4/+5 the room table, +6/+7 the
; grid's offset in the map section of the unpacked graphics, +8 the rooms a
; grid row of rooms. A room is a window of 14 x 9 blocks; the windows step 11
; block columns and 6 block rows, so neighbouring rooms share 3 columns or 3
; rows of blocks. RoomGrid ($FE23) points at the record of the hero's grid;
; RoomCells $9928 reads +0, +6/+7; RoomNumber counts the windows a grid row
; after another.
;
; The room table, one byte a room: the exits, bit 0 right, bit 1 left, bit 2
; up, bit 3 down (read by the edge checks $AADA). Item kind 7 writes 5 into
; room 12's byte $9B84 (right and up: the gate to the right opens).
;
; Read in all four stage-1 builds (RoomCells, StartGrid, the edge checks). The
; file rooms.txt holds the three records, their room tables and the placement
; lists; tools/fig_rooms.py draws the map and every room from it
; (docs/img/maps/).
;
; LoadRoomActors $A4CC puts each placement not done that lies in the room's
; window (X in 2 x RoomColumn to + 29, Y in 2 x RoomRow to + 17) into a free
; actor record, with the kind's row of ActorKinds; MarkPlacementDone sets bit 7
; when the actor is beaten or taken, so it does not come back; ResetObjectLists
; $922F clears the bits at the stage's start. Grid 0: kinds 0 and 1 (hanging
; bodies) 7 each, 2 (flame jets) 15, 3-6 (urns and chests) 16, 7 (fire pits)
; 13, 8-11 (the winged demon's parts) 1 each, 12 and 14 (statue heads) 1 each,
; 13 (the gate) 1, 16 (the bridge slab) 1.
Grid0:
  INCBIN "res/stage1/rooms.bin",$0000,9
Grid0Rooms:
  INCBIN "res/stage1/rooms.bin",$0009,18
Grid1:
  INCBIN "res/stage1/rooms.bin",$001B,9
Grid1Rooms:
  INCBIN "res/stage1/rooms.bin",$0024,3
Grid2:
  INCBIN "res/stage1/rooms.bin",$0027,9
Grid2Rooms:
  INCBIN "res/stage1/rooms.bin",$0030,1
Grid0Placements:
  INCBIN "res/stage1/rooms.bin",$0031,201
Grid1Placements:
  INCBIN "res/stage1/rooms.bin",$00FA,15
Grid2Placements:
  INCBIN "res/stage1/rooms.bin",$0109,18

  ORG $9E16

; Move the room window 11 blocks right when the hero leaves by the right edge
;
; IY = the hero's record. When the hero faces right (+9 bit 7 clear):
; ShiftRoomColumns with B = 11 blocks and C = 22 cells, SavePlayAttrs,
; RoomNumber + 1, BurstTimer = $64 (any burst stopped), RoomEvents. Facing
; left: nothing. Preserves IX and IY.
;
; Witness: L1 67 (c1o, deaths, s1-right).
LeaveRoomRight:
  PUSH IX
  PUSH IY
  LD E,$00
  LD IX,(RoomGrid)
  BIT 7,(IY+$09)
  JR NZ,LeaveRoomRightEnd
  LD B,$0B
  LD C,$16
  XOR A
  CALL ShiftRoomColumns
  CALL SavePlayAttrs
  LD A,(RoomNumber)
  INC A
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  CALL RoomEvents
LeaveRoomRightEnd:
  POP IY
  POP IX
  RET

; Move the room window 11 blocks left when the hero leaves by the left edge
;
; As LeaveRoomRight, mirrored: only when the hero faces left (+9 bit 7 set); B
; = -11 blocks, C = -22 cells, RoomNumber - 1.
;
; Witness: L1 369 (c1o, deaths, s1-right).
LeaveRoomLeft:
  PUSH IX
  PUSH IY
  LD E,$00
  LD IX,(RoomGrid)
  BIT 7,(IY+$09)
  JR Z,LeaveRoomLeftEnd
  LD B,$F5
  LD C,$EA
  XOR A
  CALL ShiftRoomColumns
  CALL SavePlayAttrs
  LD A,(RoomNumber)
  DEC A
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  CALL RoomEvents
LeaveRoomLeftEnd:
  POP IY
  POP IX
  RET

; Move the room window 6 blocks down when the hero leaves by the bottom
;
; IY = the hero. Only in the hero's state 3 (+$0A; state 2 with +8 under 8 goes
; nowhere): ShiftRoomRows with B = 6 blocks and C = 96 lines, SavePlayAttrs,
; RoomNumber + the grid's rooms-per-row (record +8), BurstTimer = $64,
; RoomEvents. Preserves IX and IY.
;
; Witness: L1 153 (c1o, deaths, s1-right).
LeaveRoomDown:
  PUSH IX
  PUSH IY
  LD E,$00
  LD A,(IY+$0A)
  CP $02
  JR NZ,LeaveRoomDownState3
  LD A,(IY+$08)
  CP $08
  JR C,LeaveRoomDownEnd
LeaveRoomDownState3:
  LD A,(IY+$0A)
  CP $03
  JR NZ,LeaveRoomDownEnd
  LD IX,(RoomGrid)
  LD B,$06
  LD C,$60
  LD A,$01
  CALL ShiftRoomRows
  CALL SavePlayAttrs
  LD IX,(RoomGrid)
  LD A,(RoomNumber)
  ADD A,(IX+$08)
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  CALL RoomEvents
LeaveRoomDownEnd:
  POP IY
  POP IX
  RET

; Move the room window 6 blocks up when the hero leaves by the top
;
; IY = the hero. Only in state 2 (+$0A) with +8 under 8: ShiftRoomRows with B =
; -6 blocks and C = -96 lines, SavePlayAttrs, RoomNumber - the grid's
; rooms-per-row, BurstTimer = $64, RoomEvents. Preserves IX and IY.
;
; Witness: L1 1 (s1-right).
LeaveRoomUp:
  PUSH IX
  PUSH IY
  LD E,$00
  LD A,(IY+$0A)
  CP $02
  JR NZ,LeaveRoomUpEnd
  LD A,(IY+$08)
  CP $08
  JR NC,LeaveRoomUpEnd
  LD IX,(RoomGrid)
  LD B,$FA
  LD C,$A0
  LD A,$01
  CALL ShiftRoomRows
  CALL SavePlayAttrs
  LD IX,(RoomGrid)
  LD A,(RoomNumber)
  SUB (IX+$08)
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  CALL RoomEvents
LeaveRoomUpEnd:
  POP IY
  POP IX
  RET

; Move the room window by B blocks across, move the hero and the kept actors by
; C cells, build the room
;
; Input: B = the blocks to move (signed), C = the cells (2B), IY = the hero.
; RoomColumn + B; the hero's X and entry X - C. The amount 2B is written into
; the two SUB operands at ShiftKeptX and ShiftKeptEntryX; then every used actor
; record with +$0F bit 1 (kept over a room change) is moved by it and freed
; when it falls outside columns 0-29; every other record is freed. Then $8A7B
; and a jump to the room builder $988B.
;
; Witness: L1 20 (c1o, deaths, s1-right).
ShiftRoomColumns:
  LD A,(RoomColumn)
  ADD A,B
  LD (RoomColumn),A
  LD A,(IY+$0D)
  SUB C
  LD (IY+$0D),A
  LD A,(IY+$00)
  SUB C
  LD (IY+$00),A
  XOR A
  ADD A,B
  ADD A,B
  LD (ShiftKeptEntryX+$0001),A
  LD (ShiftKeptX+$0001),A
  LD IY,Actors
  LD B,$0D
  LD DE,$0012
ShiftColumnsLoop:
  LD A,(IY+$00)
  CP $FF
  JR Z,ShiftColumnsNext
  BIT 1,(IY+$0F)
  JR Z,ShiftColumnsFree
  LD A,(IY+$00)
ShiftKeptX:
  SUB $00                 ; SUB n: n written above (2 x blocks)
  CP $1E
  JR NC,ShiftColumnsFree
  LD (IY+$00),A
  LD A,(IY+$0D)
ShiftKeptEntryX:
  SUB $00                 ; SUB n: n written above
  LD (IY+$0D),A
  JR ShiftColumnsNext
ShiftColumnsFree:
  LD (IY+$00),$FF
ShiftColumnsNext:
  ADD IY,DE
  DJNZ ShiftColumnsLoop
  CALL ClearPlayBuffer
  JP RoomChange

; Move the room window by B blocks up or down, move the hero and the kept
; actors by C lines, build the room
;
; Input: B = the blocks to move (signed), C = the lines (16B), IY = the hero.
; RoomRow + B; the hero's Y and entry Y - C. C is written into the SUB operands
; at ShiftKeptY and ShiftKeptEntryY; every used record with +$0F bit 1 is moved
; by it (freed outside lines 0-143), every other record is freed. Then $8A7B
; and a jump to the room builder $988B.
;
; The kept actor's new Y is stored at +0 (its X), not at +1 ($9F8A `LD
; (IY+$00),A`): the code moves a kept actor's Y into its X. Ran 6 times in
; s1-right.
;
; Witness: L1 4 (c1o, deaths, s1-right).
ShiftRoomRows:
  LD A,(RoomRow)
  ADD A,B
  LD (RoomRow),A
  LD A,(IY+$0E)
  SUB C
  LD (IY+$0E),A
  LD A,(IY+$01)
  SUB C
  LD (IY+$01),A
  LD A,C
  LD (ShiftKeptEntryY+$0001),A
  LD (ShiftKeptY+$0001),A
  LD IY,Actors
  LD B,$0D
  LD DE,$0012
ShiftRowsLoop:
  LD A,(IY+$00)
  CP $FF
  JR Z,ShiftRowsNext
  BIT 1,(IY+$0F)
  JR Z,ShiftRowsFree
  LD A,(IY+$01)
ShiftKeptY:
  SUB $00                 ; SUB n: n written above (16 x blocks)
  CP $90
  JR NC,ShiftRowsFree
  LD (IY+$00),A
  LD A,(IY+$0E)
ShiftKeptEntryY:
  SUB $00                 ; SUB n: n written above
  LD (IY+$0E),A
  JR ShiftRowsNext
ShiftRowsFree:
  LD (IY+$00),$FF
ShiftRowsNext:
  ADD IY,DE
  DJNZ ShiftRowsLoop
  CALL ClearPlayBuffer
  JP RoomChange

; Keep the old room's play-area attributes for the fade-in of the next room
;
; Copies the 576 attribute-shadow bytes of screen rows 6-23 ($6DC0, 18 x 32) to
; $7040 and sets RestoreAttributes = 1, so the next attribute pass ($8CAA)
; shows the new room over the old one's colours.
;
; Witness: L1 24 (c1o, deaths, s1-right).
SavePlayAttrs:
  LD HL,PlayAttributes
  LD DE,RoomAttributes
  LD BC,$0240
  LDIR
  LD A,$01
  LD (RestoreAttributes),A
  RET

; Spawn the bonus or item of a room that has one, after a room change
;
; Called by the four LeaveRoom routines. By RoomNumber: room 0 event bit 0 (the
; bonus at D = $12, E = $54), room 5 bit 1 ($0A, $54), room 11 bit 2 ($09,
; $44), room 12 bit 3 ($09, $44); room 15 the reward item (SpawnRewardItem);
; with GridNumber = 1 only room 2, bit 4 ($07, $54). The event's bit goes to
; SpawnBonus.
;
; Witness: L1 24 (c1o, deaths, s1-right).
RoomEvents:
  LD A,(GridNumber)
  CP $01
  JR Z,RoomEventStageVar4B
  LD A,(RoomNumber)
  CP $0F
  JP Z,SpawnRewardItem
  CP $00
  JR NZ,RoomEventRoom5
  LD D,$12
  LD E,$54
  LD B,$01
  JP SpawnBonus
RoomEventRoom5:
  CP $05
  JR NZ,RoomEventRoom11
  LD D,$0A
  LD E,$54
  LD B,$02
  JP SpawnBonus
RoomEventRoom11:
  CP $0B
  JR NZ,RoomEventRoom12
  LD D,$09
  LD E,$44
  LD B,$04
  JP SpawnBonus
RoomEventRoom12:
  CP $0C
  JR NZ,RoomEventNone
  LD D,$09
  LD E,$44
  LD B,$08
  JP SpawnBonus
RoomEventNone:
  RET
RoomEventStageVar4B:
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD D,$07
  LD E,$54
  LD B,$10
  JP SpawnBonus

; Spawn item kind 6 in room 15 when PiecesTaken is 5 and one kind-6 item was
; taken
;
; Only when PiecesTaken = 5 and PiecesComplete = 1: SpawnItem at X 9, Y $30
; with the frame $EB0C, kind 6, amount 1.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
SpawnRewardItem:
  LD A,(PiecesTaken)
  CP $05
  RET NZ
  LD A,(PiecesComplete)
  CP $01
  RET NZ
  LD D,$09
  LD E,$30
  LD BC,ItemIconKind6
  LD L,$06
  LD H,$01
  JP SpawnItem

; Spawn a room's bonus (two records) unless its event bit is set in PiecesMask
;
; Input: B = the event's bit, D, E = X and Y. Returns when PiecesMask has the
; bit. Else, when FindTwoFreeActors $8D50 finds two free records in a row, both
; get the template $9D59 (the bonus handler $8233) at D, E: the first with +$10
; = the bit (BonusHandler sets it in PiecesMask when the hero takes it), the
; second with +$0B = 1 (its sparkle). Preserves IY.
;
; Witness: L1 1 (s1-right).
SpawnBonus:
  LD A,(PiecesMask)
  AND B
  RET NZ
  PUSH IY
  PUSH BC
  PUSH DE
  CALL FindFreeActorPair
  JR NZ,SpawnBonusFull
  LD HL,PieceTemplate
  POP DE
  POP BC
  PUSH BC
  PUSH DE
  CALL SpawnActor
  POP DE
  POP BC
  LD (IY+$10),B
  LD BC,$0012
  ADD IY,BC
  LD HL,PieceTemplate
  CALL SpawnActor
  LD (IY+$0B),$01
  POP IY
  RET
SpawnBonusFull:
  POP DE
  POP BC
  POP IY
  RET

  ORG $A424

; Unpack an RLE block: the first byte is the escape, ESC n v is n copies of v,
; ESC ESC ends
;
; Input: HL = the packed block, DE = the output. The block's first byte is its
; escape byte, written into UnrleEscape and UnrleEnd's compares. Then: a byte
; other than the escape is copied; the escape followed by n, v writes n copies
; of v (n = 0 gives 256); the escape twice ends. Output: HL = the second escape
; of the end mark, DE = after the output.
;
; The room builder $988B unpacks the stage's tiles and map at $B4B2 with it to
; $5B00 at every room change (26 calls in the stage-1 recordings).
;
; Witness: L1 26 (c1o, deaths, s1-idle, s1-right).
Unrle:
  LD A,(HL)
  INC HL
  LD (UnrleEscape+$0001),A
  LD (UnrleEnd+$0001),A
UnrleNext:
  LD A,(HL)
  INC HL
UnrleEscape:
  CP $00                  ; CP n: n = the block's escape byte (written above)
  JR Z,UnrleRun
  LD (DE),A
  INC DE
  JR UnrleNext
UnrleRun:
  LD A,(HL)
UnrleEnd:
  CP $00                  ; CP n: n = the escape byte (written above)
  RET Z
  LD B,A
  INC HL
  LD A,(HL)
  INC HL
UnrleRunLoop:
  LD (DE),A
  INC DE
  DJNZ UnrleRunLoop
  JR UnrleNext

; Clear the room cells and the actors' extra state, enter the current grid at
; its start room, build it
;
; Clears $7280-$74BF (the room's cells), fills $74C0-$74DF with $FF, calls
; $921E, then reads the RoomGrid record: RoomColumn = +2, RoomRow = +3,
; RoomExitsPtr = +4/+5 (the grid's room table), and jumps to the room builder
; $988B. Called at the stage start and from $AC37 (a grid change).
;
; Witness: L1 2 (s1-idle, s1-right).
StartGrid:
  LD HL,Cells
  LD DE,Cells+$0001
  LD BC,$023F
  LD (HL),$00
  LDIR
  LD HL,CellsFloor
  LD DE,CellsFloor+$0001
  LD BC,$001F
  LD (HL),$FF
  LDIR
  CALL ClearActors
  LD IX,(RoomGrid)
  LD A,(IX+$02)
  LD (RoomColumn),A
  LD A,(IX+$03)
  LD (RoomRow),A
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD (RoomExitsPtr),HL
  JP RoomChange

  ORG $AADA

; Leave the room when the hero crosses an open edge
;
; IY = the hero, IX = the room's exit flags (RoomExitsPtr $FE2E). Bit 1: column
; under 6 leaves left ($9E45); bit 0:
;
; column $1A and up leaves right ($9E16); bit 3: line $70 and down leaves down
; ($9E74); bit 2: line under $10 leaves
;
; up ($9EB9). Not while the hero is dying (state $0F).
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
CheckRoomExits:
  LD A,(IY+$0A)
  CP $0F
  RET Z
  LD A,(IX+$00)
  AND $02
  JR Z,CheckRoomExitRight
  LD A,(IY+$00)
  CP $06
  CALL C,LeaveRoomLeft
CheckRoomExitRight:
  LD A,(IX+$00)
  AND $01
  JR Z,CheckRoomExitDown
  LD A,(IY+$00)
  CP $1A
  CALL NC,LeaveRoomRight
CheckRoomExitDown:
  LD A,(IX+$00)
  AND $08
  JR Z,CheckRoomExitUp
  LD A,(IY+$01)
  CP $70
  CALL NC,LeaveRoomDown
CheckRoomExitUp:
  LD A,(IX+$00)
  AND $04
  RET Z
  LD A,(IY+$01)
  CP $10
  CALL C,LeaveRoomUp
  RET

; Pass between the map grids at their fixed doors
;
; The stage's three grids are joined at four doors, each a room, a column and a
; facing (GridNumber $FE4B, RoomNumber
;
; $FE30, the hero's column $74E0 and facing $74E9):
;
; grid 0 room 7, column 4, facing left, walking: into the shaft (EnterGrid1
; $AB83);
;
; grid 0 room $11, column $1D and up, facing right: into the single room
; (EnterGrid2 $ABDD);
;
; grid 1 room 2, column $1D and up, facing right: back to the surface
; (LeaveGrid1 $ABA7);
;
; grid 2, column 1, facing left: back to the surface (LeaveGrid2 $AC01).
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
CheckGridPassages:
  LD A,(GridNumber)
  CP $00
  JR NZ,CheckGridPassageGrid1
  LD A,(RoomNumber)
  CP $07
  JR NZ,CheckGridPassageRoom11
  LD A,(HeroRecord)
  CP $04
  RET NZ
  LD A,(HeroFlags)
  BIT 7,A
  RET Z
  LD A,(IY+$0A)
  CP $01
  RET NZ
  JP EnterGrid1
CheckGridPassageRoom11:
  CP $11
  RET NZ
  LD A,(HeroRecord)
  CP $1D
  RET C
  LD A,(HeroFlags)
  BIT 7,A
  RET NZ
  JP EnterGrid2
CheckGridPassageGrid1:
  LD A,(GridNumber)
  CP $01
  JR NZ,CheckGridPassageGrid2
  LD A,(RoomNumber)
  CP $02
  JR NZ,CheckGridPassageGrid2
  LD A,(HeroRecord)
  CP $1D
  RET C
  LD A,(HeroFlags)
  BIT 7,A
  RET NZ
  JP LeaveGrid1
CheckGridPassageGrid2:
  LD A,(GridNumber)
  CP $02
  RET NZ
  LD A,(HeroRecord)
  CP $01
  RET NZ
  LD A,(HeroFlags)
  BIT 7,A
  RET Z
  JP LeaveGrid2

; Go into grid 1 (the shaft $9B8A), room 0, the hero at column 2, line $F1
;
; RoomGrid $FE23 = $9B8A, Placements $FE25 = $9C69, RoomNumber 0, PlaceHero
; $A481 (D = 2, E = $F1), the room built
;
; again (RebuildRoom $AC37), GridNumber 1. IY is kept.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
EnterGrid1:
  LD HL,Grid1
  LD (RoomGrid),HL
  LD HL,Grid1Placements
  LD (Placements),HL
  PUSH IY
  XOR A
  LD (RoomNumber),A
  LD D,$02
  LD E,$F1
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD A,$01
  LD (GridNumber),A
  RET

; Back from the shaft to grid 0 room 7, the hero at column 2, line $21
;
; RoomGrid $9B6F, Placements $9BA0, room 7. The grid record's bytes $9B72 and
; $9B71 are set to 6 and $0B for the
;
; build and put back to 0 and $16 after it (the record's +2 and +3, read by the
; room build). GridNumber 0.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
LeaveGrid1:
  LD HL,Grid0
  LD (RoomGrid),HL
  LD HL,Grid0Placements
  LD (Placements),HL
  LD A,$06
  LD (Grid0+$0003),A
  LD A,$0B
  LD (Grid0+$0002),A
  PUSH IY
  LD A,$07
  LD (RoomNumber),A
  LD D,$02
  LD E,$21
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD A,$16
  LD (Grid0+$0002),A
  XOR A
  LD (Grid0+$0003),A
  LD (GridNumber),A
  RET

; Go into grid 2 (the single room $9B96), the hero at column 2, line $31
;
; RoomGrid $9B96, Placements $9C78, room 0, GridNumber 2.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
EnterGrid2:
  LD HL,Grid2
  LD (RoomGrid),HL
  LD HL,Grid2Placements
  LD (Placements),HL
  PUSH IY
  XOR A
  LD (RoomNumber),A
  LD D,$02
  LD E,$31
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD A,$02
  LD (GridNumber),A
  RET

; Back from the single room to grid 0 room $11, the hero at column $1A, line
; $29
;
; As LeaveGrid1 $ABA7 with $9B72 = $0C and $9B71 = $37 for the build, room $11.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
LeaveGrid2:
  LD HL,Grid0
  LD (RoomGrid),HL
  LD HL,Grid0Placements
  LD (Placements),HL
  LD A,$0C
  LD (Grid0+$0003),A
  LD A,$37
  LD (Grid0+$0002),A
  PUSH IY
  LD A,$11
  LD (RoomNumber),A
  LD D,$1A
  LD E,$29
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD A,$16
  LD (Grid0+$0002),A
  XOR A
  LD (Grid0+$0003),A
  LD (GridNumber),A
  RET

; Clear the room's cells and build the room again
;
; ClearRoom $A444, then on into BuildRoom $9FA5.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
RebuildRoom:
  CALL StartGrid
  JP SavePlayAttrs

  ORG $B134

; HL = the room cell under the actor's feet, E (and D facing left) columns
; back; Z: not solid
;
; IY = the actor. The cell row = (line +1 + height +3 + 3) / 8, the column = +0
; - E (- D more when facing left); HL
;
; = row x 32 + column (an offset into the cells $7282). Z when bit 1 (solid) of
; the cell is clear.
;
; Witness: L1 8531 (c1o, deaths, s1-idle, s1-right).
CellUnderFeet:
  LD A,(IY+$01)
  ADD A,(IY+$03)
  ADD A,$03
  SRL A
  SRL A
  SRL A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IY+$00)
  SUB E
  BIT 7,(IY+$09)
  JR Z,CellUnderFeetColumn
  SUB D
CellUnderFeetColumn:
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,CellsPlay
  PUSH HL
  ADD HL,BC
  BIT 1,(HL)
  POP HL
  RET

; A = the room cell at column E, pixel line D; Z: not solid
;
; HL = D / 8 x 32 + E - 4 (an offset into the cells $7282; the play area's cell
; column 0 is screen column 4). The
;
; cell's bits: 1 solid, 3 deadly (HeroUpdate $AC3D).
;
; Witness: L1 9915 (c1o, deaths, s1-idle, s1-right).
CellAt:
  SRL D
  SRL D
  SRL D
  LD L,D
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  SUB $04
  ADD A,E
  LD L,A
  LD BC,CellsPlay
  PUSH HL
  ADD HL,BC
  LD A,(HL)
  BIT 1,A
  POP HL
  RET

  ORG $B4B2

; The stage's tiles, blocks and map, RLE-packed (3583 bytes; 4295 unpacked: 196
; tiles, 114 blocks, the three grids' map)
;
; RoomChange $988B unpacks it with Unrle $A424 into the play buffer at $5B00 at
; every room change (the buffer is cleared again before the actors are drawn).
; Unrle: the first byte is the escape ($C7 here); a byte other than the escape
; is itself, ESC n v is n copies of v (n = 0: 256), ESC ESC ends. Unpacked:
; five words, the offsets from $5B0A of the tile kinds (1 byte a tile: 0 open,
; else solid; bit 1 solid, bit 3 deadly), the tile pixels (8 bytes a tile), the
; tile attributes (1 a tile), the blocks (4 tile numbers a block: top left, top
; right, bottom left, bottom right) and the map (a block number a byte, the
; grids one after another, each its width x height; Grid0 +6 gives its offset).
; RoomCells $9928 turns the room's 14 x 9 blocks into 28 x 18 tile numbers in
; Cells.
;
; The packer that made it is greedy: every run of 4 to 255 equal bytes is ESC n
; v, except one stretch of 8 zero bytes left as they are (unpacked offset 1366:
; a blank tile's pixels). With that one exception tools/res_stage.py packs the
; block again bit for bit, so the resource is editable: graphics.txt (the
; blocks and the map grids as text) and tiles.png (the tiles' pixels and
; colours). The same holds for the stages 2-4 (docs/img/maps/ has every grid
; and room). Read in all four stage-1 builds, every byte (Unrle).
StageGraphics:
  INCBIN "res/stage1/graphics.bin",$0000,3583
