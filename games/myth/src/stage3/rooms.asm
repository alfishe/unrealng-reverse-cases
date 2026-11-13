; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The rooms: the grids, the room builder, the room changes and the grid passages
; --------------------------------------------------------------------------------------------------------------------

  ORG $829F

; Z when the hero, in grid 1 room 0 and facing left, stands at column 2
;
; NZ (free) in another grid or room, or facing right (ReturnNZ); else the flags
; of the hero's column $74E0 compared with 2. Grid 1 room 0 is the swamp's
; first room: the hero cannot walk back out of its left edge.
;
; Witness: L1 1769 (rzx-r3, s3-right).
CheckSwampLeftEdge:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $00
  RET NZ
  LD A,(HeroFlags)
  BIT 7,A
  JP Z,ReturnNZ
  LD A,(HeroRecord)
  CP $02
  RET

  ORG $95B0

; Clear the taken flags of the stage's three object lists
;
; The lists at $9B62, $9B8F and $9BF8: 3-byte entries up to $FF, bit 7 of the
; first byte cleared (ClearTakenFlags).
;
; Stage 1's ResetObjectLists at $922F is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
ResetObjectLists:
  LD HL,Grid0Placements
  CALL ClearTakenFlags
  LD HL,Grid1Placements
  CALL ClearTakenFlags
  LD HL,Grid2Placements

; Clear bit 7 of each 3-byte entry at HL up to the $FF end
;
; Stage 1's ClearTakenFlags at $923E is the same code.
;
; Witness: L1 102 (rzx-r3, s3-right).
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

  ORG $9853

; Build the room: unpack the stage's graphics, draw the scenery, make the spans
;
; BurstTimer = 100. Unrle $A39A the packed tiles and map $B556 into $5B00 (the
; play buffer), clear the shots, build
;
; the cells (RoomCells, IX = RoomGrid), $9FC7, then patch the tile bitmaps' and
; the attributes' addresses into $98B9
;
; and $989B (from the header words $5B02, $5B04) and draw every cell of the 18
; x 28 play area: its attribute into
;
; the shadow $6DC2 and its 8 bitmap bytes straight onto the screen
; (CopyTileToScreen, from line 48 column 2). Then
;
; BuildSpans, ClearBuffer (the unpacked data is gone) and the actors (JP
; $A6CA).
;
; Stage 1's RoomChange at $988B is the same code.
;
; Witness: L1 39 (rzx-r3, s3-right).
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
; Stage 1's CopyTileToScreen at $991F is the same code.
;
; Witness: L1 19656 (rzx-r3, s3-right).
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
; Stage 1's RoomCells at $9928 is the same code.
;
; Witness: L1 39 (rzx-r3, s3-right).
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
; Stage 1's PutBlock at $9986 is the same code.
;
; Witness: L1 4914 (rzx-r3, s3-right).
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
  LD BC,$FDC0
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  INC HL
  LD A,(IY+$01)
  LD (HL),A
  PUSH HL
  LD BC,$FDC0
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  LD BC,$001F
  ADD HL,BC
  LD A,(IY+$02)
  LD (HL),A
  PUSH HL
  LD BC,$FDC0
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  INC HL
  LD A,(IY+$03)
  LD (HL),A
  PUSH HL
  LD BC,$FDC0
  ADD HL,BC
  LD A,(CellFlag)
  LD (HL),A
  POP HL
  RET

  ORG $9B37

; Grid 0's record (stage 3: the longship): 47 x 9 blocks, the start window at
; block column 11, row 0, the room table Grid0Rooms, map offset 0, +8 = 6
;
; A grid record, 9 bytes, as in stage 1: +0 the width and +1 the height in
; blocks, +2/+3 the start window's block column and row (where StartGrid $A639
; puts the window; the grid passages rewrite them), +4/+5 the room table, +6/+7
; the grid's offset in the map section of the unpacked graphics, +8 the rooms a
; grid row of rooms (only the moves up and down read it; every stage-3 grid is
; one row of rooms, 9 blocks high, so +1 and +8 are read by no recording: grid
; 0's +8 = 6 does not match its 4 rooms and is never used). A room is a window
; of 14 x 9 blocks; the windows step 11 block columns, so neighbouring rooms
; share 3 columns of blocks. RoomGrid ($FE23) points at the record of the
; hero's grid (StageEntry sets $9B37); RoomCells reads +0, +6/+7.
;
; The room table, one byte a room: the exits, bit 0 right, bit 1 left, bit 2
; up, bit 3 down. Grid 0: 4 rooms (1, 3, 3, 2: the deck from the stern to the
; prow); grid 1: 11 rooms (the swamp and the forest, right to the castle); grid
; 2: 1 room with no exit (the castle hall).
;
; Read in rzx-r3 and s3-right (StageEntry, RoomCells, StartGrid, the edge
; checks); grid 1's start column $9B46 is written once in rzx-r3 (the passage
; from grid 0). rooms.txt holds the three records, their room tables and the
; placement lists; tools/fig_rooms.py draws the map and every room from it
; (docs/img/maps/stage3*.png).
;
; LoadRoomActors $A6CA puts each placement not done that lies in the room's
; window into a free actor record, with the kind's row of ActorKinds; bit 7 of
; the kind is set when the actor is beaten or taken, so it does not come back
; (48 placement bytes written in each recording). Grid 0: four of kind $0C (at
; X 16, 56, 96, 144, line 0: the lightning) and ten of kind 4 (the sea at the
; foot of the hull, Y 15). Grid 1: 34 placements: kinds 0-3 (urns and chests,
; 11), kind 4 (the water of the swamp, 15), kind 5 (Y 6), 6 (Y 8), 7 (the
; drawbridge, X 234), 8 and 9 (two each, X 120-131: the dragon's room), $0A and
; $0B (X 124). Grid 2: none. Read in rzx-r3 (140 of the 153 bytes) and s3-right
; (72).
Grid0:
  INCBIN "res/stage3/rooms.bin",$0000,9
Grid0Rooms:
  INCBIN "res/stage3/rooms.bin",$0009,4
Grid1:
  INCBIN "res/stage3/rooms.bin",$000D,9
Grid1Rooms:
  INCBIN "res/stage3/rooms.bin",$0016,11
Grid2:
  INCBIN "res/stage3/rooms.bin",$0021,9
Grid2Rooms:
  INCBIN "res/stage3/rooms.bin",$002A,1
Grid0Placements:
  INCBIN "res/stage3/rooms.bin",$002B,45
Grid1Placements:
  INCBIN "res/stage3/rooms.bin",$0058,105
Grid2Placements:
  INCBIN "res/stage3/rooms.bin",$00C1,3

  ORG $9D70

; Move the room window 11 blocks right when the hero leaves by the right edge
;
; IY = the hero's record. When the hero faces right (+9 bit 7 clear):
; ShiftRoomColumns `$9E6B` with B = 11 blocks and C = 22 cells, StopRoomEffects
; `$9F19` (the rain stops, the old room's colours kept), RoomNumber + 1,
; BurstTimer = `$64` (any burst stopped); PyreState 3 (the body rising) becomes
; 4 (it is gone); then RoomEvents `$9F31`. Facing left: nothing. Preserves IX
; and IY.
;
; Called by CheckRoomExits `$ACE2` when the hero's column is `$19` or more and
; the room's exit bit 0 is set.
;
; Witness: L1 268 (rzx-r3, s3-right).
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
  CALL StopRoomEffects
  LD A,(RoomNumber)
  INC A
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  LD A,(PyreState)
  CP $03
  JP NZ,LeaveRoomRightEvents
  LD A,$04
  LD (PyreState),A
LeaveRoomRightEvents:
  CALL RoomEvents
LeaveRoomRightEnd:
  POP IY
  POP IX
  RET

; Move the room window 11 blocks left when the hero leaves by the left edge
;
; As LeaveRoomRight, mirrored: only when the hero faces left (+9 bit 7 set); B
; = -11 blocks, C = -22 cells, RoomNumber - 1. Called by CheckRoomExits `$ACE2`
; when the hero's column is under 7 and the exit bit 1 is set.
;
; Witness: L1 410 (rzx-r3, s3-right).
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
  CALL StopRoomEffects
  LD A,(RoomNumber)
  DEC A
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  LD A,(PyreState)
  CP $03
  JP NZ,LeaveRoomLeftEvents
  LD A,$04
  LD (PyreState),A
LeaveRoomLeftEvents:
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
; Stage 1's LeaveRoomDown at $9E74 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
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
  CALL StopRoomEffects
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
; Stage 1's LeaveRoomUp at $9EB9 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
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
  CALL StopRoomEffects
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
; when it falls outside columns 0-29; every other record is freed. Then $891C
; and a jump to the room builder $9853.
;
; Stage 1's ShiftRoomColumns at $9EF7 is the same code.
;
; Witness: L1 34 (rzx-r3, s3-right).
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
; by it (freed outside lines 0-143), every other record is freed. Then $891C
; and a jump to the room builder $9853.
;
; The kept actor's new Y is stored at +0 (its X), not at +1 ($9EFE `LD
; (IY+$00),A`): the code moves a kept actor's Y into its X. Ran 6 times in
; s1-right.
;
; Stage 1's ShiftRoomRows at $9F4F is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
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

; Stop the rain and clear `$FE68`, then keep the old room's colours (on into
; SavePlayAttrs)
;
; RainStep `$FE5A` = 0 (UpdateRain `$A41E` stops drawing it) and VikingCount
; `$FE68` = 0, then falls into SavePlayAttrs `$9F20`. Called by the four
; LeaveRoom routines and RebuildRoom `$ADDA` (stage 1's leave routines called
; SavePlayAttrs itself).
;
; Witness: L1 37 (rzx-r3, s3-right).
StopRoomEffects:
  XOR A
  LD (RainStep),A
  LD (VikingCount),A

; Keep the old room's play-area attributes for the fade-in of the next room
;
; Copies the 576 attribute-shadow bytes of screen rows 6-23 ($6DC0, 18 x 32) to
; $7040 and sets RestoreAttributes = 1, so the next attribute pass
; (UpdateAttributes $8B4B) shows the new room over the old one's colours.
;
; Stage 1's SavePlayAttrs at $9FA5 is the same code.
;
; Witness: L1 37 (rzx-r3, s3-right).
SavePlayAttrs:
  LD HL,PlayAttributes
  LD DE,RoomAttributes
  LD BC,$0240
  LDIR
  LD A,$01
  LD (RestoreAttributes),A
  RET

; Spawn the piece or the reward item of a room that has one, after a room
; change
;
; Called by the four LeaveRoom routines and RebuildRoom `$ADDA`. GridNumber 0:
; only room 3, event bit 1 (SpawnBonus `$9F93` at D = 9, E = `$44`). GridNumber
; 1: room 0 bit `$10` (4, `$4C`), room 6 bit 4 (`$13`, `$4C`), room 9 bit 8
; (`$14`, `$2C`), room 8 and every other room SpawnRewardItem `$9F7F`.
; GridNumber 2: nothing (its piece, bit `$40`, comes from ThroneBossBeaten
; `$A02A`). The event's bit goes to SpawnBonus in B.
;
; Witness: L1 37 (rzx-r3, s3-right).
RoomEvents:
  LD A,(GridNumber)
  CP $00
  JR NZ,RoomEventsGrid1
  LD A,(RoomNumber)
  CP $03
  JR NZ,RoomEventsNone
  LD D,$09
  LD E,$44
  LD B,$01
  JP SpawnBonus
RoomEventsNone:
  RET
RoomEventsGrid1:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $08
  JP Z,SpawnRewardItem
  CP $00
  JR NZ,RoomEventsRoom6
  LD D,$04
  LD E,$4C
  LD B,$10
  JP SpawnBonus
RoomEventsRoom6:
  CP $06
  JR NZ,RoomEventsRoom9
  LD D,$13
  LD E,$4C
  LD B,$04
  JP SpawnBonus
RoomEventsRoom9:
  CP $09
  JR NZ,SpawnRewardItem
  LD D,$14
  LD E,$2C
  LD B,$08
  JP SpawnBonus

; A RET no code reaches
;
; Byte `$C9` after RoomEvents' last JP; no jump lands on it and no recording
; read it (rw3.py `$9F7E`: 0 reads).
RoomEventsLeftover:
  DEFB $C9

; Spawn the item of kind 6 at column 9, line `$68` while PiecesComplete is 1
;
; Only when PiecesComplete `$FE57` = 1 (set when the last piece is taken;
; ItemHandler `$A108` adds 1 when a kind-6 item is taken, so it is given once):
; SpawnItem `$A081` with the frame `$EA20`, kind 6, amount 1. Reached from
; RoomEvents for every grid-1 room but 0, 6 and 9 (rzx-r3: 22 calls, 1 spawn).
;
; Witness: L1 22 (rzx-r3).
SpawnRewardItem:
  LD A,(PiecesComplete)
  CP $01
  RET NZ
  LD D,$09
  LD E,$68
  LD BC,ItemIconKind6
  LD L,$06
  LD H,$01
  JP SpawnItem

; Spawn a room's bonus (two records) unless its event bit is set in PiecesMask
;
; Input: B = the event's bit, D, E = X and Y. Returns when PiecesMask has the
; bit. Else, when FindTwoFreeActors $8BF9 finds two free records in a row, both
; get the template $9C94 (the piece's handler UpdatePieceActor $82B9) at D, E:
; the first with +$10 = the bit (BonusHandler sets it in PiecesMask when the
; hero takes it), the second with +$0B = 1 (its sparkle). Preserves IY.
;
; Stage 1's SpawnBonus at $A023 is the same code.
;
; Witness: L1 11 (rzx-r3, s3-right).
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

  ORG $A39A

; Unpack an RLE block: the first byte is the escape, ESC n v is n copies of v,
; ESC ESC ends
;
; Input: HL = the packed block, DE = the output. The block's first byte is its
; escape byte, written into UnrleEscape and UnrleEnd's compares. Then: a byte
; other than the escape is copied; the escape followed by n, v writes n copies
; of v (n = 0 gives 256); the escape twice ends. Output: HL = the second escape
; of the end mark, DE = after the output.
;
; The room builder $9853 unpacks the stage's tiles and map at $B556 with it to
; $5B00 at every room change (26 calls in the stage-1 recordings).
;
; Stage 1's Unrle at $A424 is the same code.
;
; Witness: L1 39 (rzx-r3, s3-right).
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

; Start the rain: 60 drops at random places, RainStep 1
;
; RainPointer `$FE5B` = `$0541` (a ROM address: the rain's random bytes,
; RainRandomByte), BurstTimer `$64` (a burst stopped: the drops use its records
; at `$7040`), RainStep `$FE5A` = 1. Each of the 60 four-byte records from
; `$7040`: +0 the column in pixels (a random byte), +1 the line (a random
; multiple of 4, + `$80`: above the play area), +2 the speed (4 or 8 pixels
; across and lines down a pass), +3 `$FF` (falling; 0-3 the splash).
;
; Reached from RainChance `$A3FD` (grid 0, at random) and UpdateRain `$A507`
; (the kind-9 item used in room 5).
;
; Witness: L1 14 (rzx-r3, s3-right).
StartRain:
  LD HL,$0541
  LD (RainPointer),HL
  LD B,$3C
  LD A,$64
  LD (BurstTimer),A
  LD A,$01
  LD (RainStep),A
  LD IX,RoomAttributes
StartRainDrop:
  PUSH BC
  CALL RainRandomByte
  LD (IX+$00),A
  CALL RainRandomByte
  AND $7C
  ADD A,$80
  LD (IX+$01),A
  CALL RainRandomByte
  AND $02
  ADD A,$02
  SLA A
  LD (IX+$02),A
  LD (IX+$03),$FF
  INC IX
  INC IX
  INC IX
  INC IX
  POP BC
  DJNZ StartRainDrop
  RET

; Grid 0 (the longship): effect 9 now and then, and a new rain at random
;
; Called every main-loop pass (`$7862`). Only with GridNumber 0: one pass in 4
; (Random `$8A26` AND 3 = 0) plays effect 9 (PlaySoundVector `$F9B0`) and, when
; no rain falls (RainStep 0), starts one in a quarter of those (StartRain
; `$A3BA`).
;
; Witness: L1 6278 (rzx-r3, s3-right).
RainChance:
  LD A,(GridNumber)
  CP $00
  RET NZ
  CALL Random
  AND $03
  RET NZ
  LD DE,$0009
  CALL PlaySoundVector
  LD A,(RainStep)
  CP $00
  RET NZ
  CALL Random
  AND $03
  JP Z,StartRain
  RET

; The rain's pass: colour the sky, move and draw the drops, step RainStep; and
; the rain item of room 5
;
; Called every main-loop pass (`$7865`) after RainChance. RainStep `$FE5A` 0:
; UpdateRainIdle. Else: the splash line, `$77`, or `$67` in grid 0's rooms 1
; and 2 (the longship's deck), is written into the CP at `$A4A3`; the shadow
; attributes of the play area's first 15 rows (`$6DC0`, 480 bytes) are set to 5
; (cyan ink on black) so the drops are seen; RainStep + 1 (it runs to `$FF` and
; wraps to 0: the rain ends after 255 passes). In grid 1 or 2, step `$50` sets
; PyreState `$FE5D` = 1 (the pyre's flames start to die, PyreFlameActor
; `$93C8`) and step `$64` PyreState 2 (the body may rise, PyreBodyActor
; `$945E`). The drops drawn: RainStep / 2 + 2 up to step `$7F`, then (`$FF` -
; RainStep) / 2 + 2, at most `$38`: the rain thickens and thins.
;
; Each drop: line + speed under `$80` and under the splash line: it falls (line
; + speed, column - speed: slanting left) and is drawn by DrawRainDrop; at the
; splash line: line = splash line - 3, its splash step +3 + 1 drawn by
; DrawRainSplash; after step 3 it starts again at a random column, line 0. A
; line of `$80` and up (above the play area) moves without being drawn.
;
; Witness: L1 6278 (rzx-r3, s3-right).
;
; GetSelectedItem `$7EEA`: kind 9 selected, RoomNumber 5 and a count left: the
; count - 1 (ShowItemCount `$7D4C`) and StartRain. The fire key is not needed:
; selecting it in room 5 is enough. rzx-r3 used it once (the fall-through to
; `$A501` ran 1 time).
UpdateRain:
  LD A,(RainStep)
  CP $00
  JP Z,UpdateRainIdle
  LD E,$77
  LD A,(GridNumber)
  CP $00
  JR NZ,UpdateRainSky
  LD E,$67
  LD A,(RoomNumber)
  CP $02
  JR Z,UpdateRainSky
  CP $01
  JR Z,UpdateRainSky
  LD E,$77
UpdateRainSky:
  LD A,E
  LD (UpdateRainSplashLine+$0001),A
  LD HL,PlayAttributes
  LD DE,PlayAttributes+$0001
  LD (HL),$05
  LD BC,$01DF
  LDIR
  LD A,(RainStep)
  INC A
  LD (RainStep),A
  CP $50
  JR NZ,UpdateRainStep64
  LD A,(GridNumber)
  CP $00
  JR Z,UpdateRainCount
  LD A,$01
  LD (PyreState),A
  JR UpdateRainCount
UpdateRainStep64:
  CP $64
  JR NZ,UpdateRainCount
  LD A,(GridNumber)
  CP $00
  JR Z,UpdateRainCount
  LD A,$02
  LD (PyreState),A
UpdateRainCount:
  LD A,(RainStep)
  CP $80
  JR NC,UpdateRainThin
  SRL A
  LD B,A
  JR UpdateRainLimit
UpdateRainThin:
  LD E,A
  LD A,$FF
  SUB E
  SRL A
  LD B,A
UpdateRainLimit:
  INC B
  INC B
  LD A,B
  CP $38
  JR C,UpdateRainDrops
  LD B,$38
UpdateRainDrops:
  LD IX,RoomAttributes
UpdateRainLoop:
  PUSH BC
  LD A,(IX+$01)
  ADD A,(IX+$02)
  CP $80
  JR NC,UpdateRainHidden
UpdateRainSplashLine:
  CP $77                  ; CP n: n = the splash line (written above)
  JR C,UpdateRainFall
  LD A,(UpdateRainSplashLine+$0001)
  SUB $03
  LD (IX+$01),A
  INC (IX+$03)
  LD A,(IX+$03)
  CP $04
  JR Z,UpdateRainRestart
  CALL DrawRainSplash
  JR UpdateRainNext
UpdateRainRestart:
  LD (IX+$03),$FF
  CALL RainRandomByte
  LD (IX+$00),A
  XOR A
UpdateRainFall:
  LD (IX+$01),A
  LD A,(IX+$00)
  SUB (IX+$02)
  LD (IX+$00),A
  CALL DrawRainDrop
UpdateRainNext:
  LD BC,$0004
  ADD IX,BC
  POP BC
  DJNZ UpdateRainLoop
  RET
UpdateRainHidden:
  LD (IX+$01),A
  LD A,(IX+$00)
  SUB (IX+$02)
  LD (IX+$00),A
  JR UpdateRainNext
UpdateRainIdle:
  CALL GetSelectedItem    ; no rain: the item of kind 9 used in room 5 starts
                          ; one
  CP $09
  RET NZ
  LD A,(RoomNumber)
  CP $05
  RET NZ
  LD A,(IX+$00)
  CP $00
  RET Z
  DEC (IX+$00)
  CALL ShowItemCount
  JP StartRain

; Draw a falling drop: one of four 4-line slanted streaks by its column's pixel
;
; IX = the drop. The shape is RainDropShapes[(+0 AND 6) / 2], then on into
; DrawRainShape.
;
; Witness: L1 59295 (rzx-r3, s3-right).
DrawRainDrop:
  LD A,(IX+$00)
  AND $06
  SRL A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,RainDropShapes
  ADD HL,BC

; Store the 4 bytes at HL down 4 lines of the play buffer at the drop's place
;
; IX = the drop: buffer `$5B00` + line x 32 + column / 8; each byte replaces
; the buffer's (no OR). Also the end of DrawRainSplash.
;
; Witness: L1 70017 (rzx-r3, s3-right).
DrawRainShape:
  PUSH HL
  LD A,(IX+$01)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,PlayBuffer
  ADD HL,BC
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  LD C,A
  LD B,$00
  ADD HL,BC
  POP DE
  LD BC,$0020
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC DE
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  RET

; A = the next ROM byte of RainPointer (`$0000`-`$3FFF`, wrapping)
;
; RainPointer `$FE5B` + 1, its high byte ANDed with `$3F`; A = the byte there.
; Called by StartRain and UpdateRain.
;
; Witness: L1 5151 (rzx-r3, s3-right).
RainRandomByte:
  LD HL,(RainPointer)
  INC HL
  LD A,H
  AND $3F
  LD H,A
  LD A,(HL)
  LD (RainPointer),HL
  RET

; Draw splash step +3 (0-3) of a drop that reached the splash line
;
; HL = RainSplashShapes + 4 x step, then DrawRainShape (jumped to).
;
; Witness: L1 10722 (rzx-r3, s3-right).
DrawRainSplash:
  LD A,(IX+$03)
  LD L,A
  SLA L
  SLA L
  LD H,$00
  LD BC,RainSplashShapes
  ADD HL,BC
  JP DrawRainShape

; The four slanted drop streaks (4 lines each), by the drop's pixel column
;
; Read by DrawRainDrop `$A50A` through DrawRainShape (all 16 bytes, 59 295
; drops in rzx-r3).
RainDropShapes:
  DEFB $40,$00,$80,$80
  DEFB $10,$00,$20,$20
  DEFB $04,$00,$08,$08
  DEFB $01,$00,$04,$04

; The four splash steps (4 lines each): a drop's bounce spreading out
;
; Read by DrawRainSplash `$A557` through DrawRainShape (all 16 bytes).
RainSplashShapes:
  DEFB $00,$00,$10,$10
  DEFB $00,$28,$28,$00
  DEFB $00,$00,$44,$44
  DEFB $00,$00,$00,$82

; Grid 0: the storm's flash; step LightningState and colour the sky and the
; masts
;
; Called every main-loop pass (`$787D`); only with GridNumber 0. LightningState
; `$FE59` 4 is the calm: each pass one chance in 8 (Random `$8A26` AND 7 = 0)
; starts a flash at state 0; states 0-3 step on one a pass. C =
; LightningColours[state]; a HALT; ColourMasts with C; then every open cell of
; the play area (the cell at `$7282` is 0) gets C in the screen's attributes
; from `$58C2` (18 rows of 28): the sky goes blue, cyan, white, cyan, blue. The
; bolt itself is LightningActor `$94AC`.
;
; Witness: L1 6278 (rzx-r3, s3-right).
LightningStep:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(LightningState)
  CP $04
  JR NZ,LightningStepNext
  CALL Random
  AND $07
  RET NZ
  LD A,$FF
LightningStepNext:
  INC A
  LD (LightningState),A
  LD C,A
  LD B,$00
  LD HL,LightningColours
  ADD HL,BC
  LD C,(HL)
  HALT
  CALL ColourMasts
  LD HL,Attributes+194
  LD DE,CellsPlay
  LD B,$12
LightningStepRow:
  PUSH BC
  LD B,$1C
LightningStepCell:
  LD A,(DE)
  CP $00
  JR NZ,LightningStepSkip
  LD (HL),C
LightningStepSkip:
  INC L
  INC DE
  DJNZ LightningStepCell
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ LightningStepRow
  RET

; The sky's attribute at each LightningState 0-4: paper blue, cyan, white,
; cyan, blue (ink black)
;
; Read by LightningStep `$A588`.
LightningColours:
  DEFB $08,$28,$38,$28,$08

; Paint the longship's red scenery cells (the mast) of grid 0's room with the
; attribute C (screen attributes)
;
; Only with GridNumber 0, by RoomNumber: room 2 nothing; room 1 a column of 8
; cells from `$5962`; room 3 five rows of 3 cells from `$59CD` and 4 single
; cells below; any other room (0) eight rows of 5 cells from `$5974` and 3
; single cells. The cells are scenery (not open), so the flash of LightningStep
; does not reach them otherwise. Called by LightningStep with the flash's
; colour and by RestoreMasts with red.
;
; rzx-r3 never painted room 0's cells (`$A5E6`-`$A605` 0 runs).
;
; Witness: L1 7538 (rzx-r3, s3-right).
ColourMasts:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(RoomNumber)
  CP $02
  RET Z
  CP $01
  JR Z,ColourMastsRoom1
  CP $03
  JR Z,ColourMastsRoom3
  LD HL,Attributes+372
  LD B,$08
ColourMastsRoom0:
  PUSH BC
  LD (HL),C
  INC HL
  LD (HL),C
  INC HL
  LD (HL),C
  INC HL
  LD (HL),C
  INC HL
  LD (HL),C
  LD BC,$001C
  ADD HL,BC
  POP BC
  DJNZ ColourMastsRoom0
  INC HL
  LD (HL),C
  LD DE,$0020
  ADD HL,DE
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  RET
ColourMastsRoom1:
  LD HL,Attributes+354
  LD DE,$0020
  LD B,$08
ColourMastsRoom1Loop:
  PUSH BC
  LD (HL),C
  ADD HL,DE
  POP BC
  DJNZ ColourMastsRoom1Loop
  RET
ColourMastsRoom3:
  LD HL,Attributes+461
  LD B,$05
ColourMastsRoom3Loop:
  PUSH BC
  LD (HL),C
  INC HL
  LD (HL),C
  INC HL
  LD (HL),C
  LD BC,$001E
  ADD HL,BC
  POP BC
  DJNZ ColourMastsRoom3Loop
  LD DE,$0020
  INC HL
  INC HL
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  RET

; ColourMasts with C = 2 (red): the masts' own colour
;
; Called from `$8B7D` and `$8B8B` every pass.
;
; Witness: L1 6278 (rzx-r3, s3-right).
RestoreMasts:
  LD C,$02
  JP ColourMasts

; Clear the room cells and the actors' extra state, enter the current grid at
; its start room, build it
;
; Clears $7280-$74BF (the room's cells), fills $74C0-$74DF with $FF, calls
; $959F, then reads the RoomGrid record: RoomColumn = +2, RoomRow = +3,
; RoomExitsPtr = +4/+5 (the grid's room table), and jumps to the room builder
; $9853. Called by StageEntry ($782A) and RebuildRoom ($ADDA).
;
; Stage 1's StartGrid at $A444 is the same code.
;
; Witness: L1 5 (rzx-r3, s3-right).
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

  ORG $ACE2

; Leave the room when the hero crosses an open edge
;
; IY = the hero, IX = the room's exit flags (RoomExitsPtr $FE2E). Bit 1: column
; under 7 leaves left (LeaveRoomLeft $9DAC); bit 0:
;
; column $19 and up leaves right (LeaveRoomRight $9D70); bit 3: line $70 and
; down leaves down (LeaveRoomDown $9DE8); bit 2: line under $10 leaves
;
; up ($9E2D). Not while the hero is dying (state $0F).
;
; Stage 1's CheckRoomExits at $AADA, the same instructions; the operands that
; differ: the left and right limits (7 at $ACF2 and $19 at $AD01 here) and the
; leave routines' addresses ($ACF4, $AD03, $AD12, $AD20).
;
; Witness: L1 6280 (rzx-r3, s3-right).
CheckRoomExits:
  LD A,(IY+$0A)
  CP $0F
  RET Z
  LD A,(IX+$00)
  AND $02
  JR Z,CheckRoomExitRight
  LD A,(IY+$00)
  CP $07
  CALL C,LeaveRoomLeft
CheckRoomExitRight:
  LD A,(IX+$00)
  AND $01
  JR Z,CheckRoomExitDown
  LD A,(IY+$00)
  CP $19
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
; Called by HeroActor `$AC46` every pass. The stage's three grids (records
; `$9B37` the longship, `$9B44` the land, `$9B58` the castle's hall) are joined
; at three doors: GridNumber 0 room 3 once PiecesTaken `$FE55` is not 0 (the
; longship's piece taken): EnterGrid1; GridNumber 1 room `$0A` with the hero's
; column `$11` or more: EnterGrid2; GridNumber 2 with the hero's column under
; 5, not dying: LeaveGrid2. Each ran once in rzx-r3.
;
; Witness: L1 6280 (rzx-r3, s3-right).
CheckGridPassages:
  LD A,(GridNumber)
  CP $00
  JR NZ,CheckGridPassagesGrid1
  LD A,(RoomNumber)
  CP $03
  RET NZ
  LD A,(PiecesTaken)
  CP $00
  RET Z
  JP EnterGrid1
CheckGridPassagesGrid1:
  LD A,(GridNumber)
  CP $01
  JR NZ,CheckGridPassagesGrid2
  LD A,(RoomNumber)
  CP $0A
  RET NZ
  LD A,(HeroRecord)
  CP $11
  RET C
  JP EnterGrid2
CheckGridPassagesGrid2:
  LD A,(HeroRecord)
  CP $05
  RET NC
  LD A,(HeroState)
  CP $0F
  RET Z
  JP LeaveGrid2

; Go from the longship into grid 1 (`$9B44`), room 2, the hero at column `$0A`,
; line `$39`
;
; RoomGrid `$FE23` = `$9B44`, Placements `$FE25` = `$9B8F`, RoomNumber 2,
; PlaceHero `$A67F` (D = `$0A`, E = `$39`), RebuildRoom `$ADDA`, GridNumber 1.
; IY is kept. Reached from CheckGridPassages (JP).
;
; Witness: L1 1 (rzx-r3).
EnterGrid1:
  LD HL,Grid1
  LD (RoomGrid),HL
  LD HL,Grid1Placements
  LD (Placements),HL
  PUSH IY
  LD A,$02
  LD (RoomNumber),A
  LD DE,$0A39
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD A,$01
  LD (GridNumber),A
  RET

; Go into grid 2 (the castle's hall `$9B58`), room 0, the hero at column 6,
; line `$39`
;
; RoomGrid = Grid2 `$9B58`, Placements = Grid2Placements `$9BF8` (empty),
; RoomNumber 0, PlaceHero (D = 6, E = `$39`), RebuildRoom, GridNumber 2. IY is
; kept.
;
; Witness: L1 1 (rzx-r3).
EnterGrid2:
  LD HL,Grid2
  LD (RoomGrid),HL
  LD HL,Grid2Placements
  LD (Placements),HL
  PUSH IY
  XOR A
  LD (RoomNumber),A
  LD DE,$0639
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD A,$02
  LD (GridNumber),A
  RET

; Back from the hall to grid 1 room `$0A`, the hero at column `$0C`, line `$19`
;
; RoomGrid = Grid1 `$9B44`, Placements = Grid1Placements `$9B8F`, RoomNumber
; `$0A`. The grid record's byte `$9B46` (+2, the start window's column, read by
; StartGrid) is set to `$6E` for the build and put back to `$16` after it.
; PlaceHero (D = `$0C`, E = `$19`), RebuildRoom, GridNumber 1. IY is kept.
;
; Witness: L1 1 (rzx-r3).
LeaveGrid2:
  LD HL,Grid1
  LD (RoomGrid),HL
  LD HL,Grid1Placements
  LD (Placements),HL
  LD IX,Grid1
  LD (IX+$02),$6E
  PUSH IY
  LD A,$0A
  LD (RoomNumber),A
  LD DE,$0C19
  CALL PlaceHero
  CALL RebuildRoom
  POP IY
  LD IX,Grid1
  LD (IX+$02),$16
  LD A,$01
  LD (GridNumber),A
  RET

; Clear the room's cells and build the room again, its events, the rain stopped
;
; StartGrid `$A639`, RoomEvents `$9F31`, then on into StopRoomEffects `$9F19`
; (JP). Called by the three grid doors.
;
; Witness: L1 3 (rzx-r3).
RebuildRoom:
  CALL StartGrid
  CALL RoomEvents
  JP StopRoomEffects

  ORG $B1C8

; HL = the room cell under the actor's feet, E (and D facing left) columns
; back; Z: not solid
;
; IY = the actor. The cell row = (line +1 + height +3 + 3) / 8, the column = +0
; - E (- D more when facing left); HL
;
; = row x 32 + column (an offset into the cells $7282). Z when bit 1 (solid) of
; the cell is clear.
;
; Stage 1's CellUnderFeet at $B134 is the same code.
;
; Witness: L1 2972 (rzx-r3, s3-right).
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
; HL = D / 8 x 32 + E - 4 (an offset into the cells $7282; CellsPlay $7282 is
; screen column 2, so the cell is at screen column E - 2). The
;
; cell's bits: 1 solid, 3 deadly (stage 3's HeroUpdate $ADE3 does not test it).
;
; Stage 1's CellAt at $B162 is the same code.
;
; Witness: L1 1832 (rzx-r3, s3-right).
CellAt:
  SRL D
  SRL D
  SRL D

; CellAt `$B1F6` entered with D = the cell row (0-17) instead of the pixel line
;
; HL = D x 32 + E - 4, A = the cell at `$7282` + HL, Z when it is not solid.
; Called from `$91A2`; CellAt falls into it.
;
; Witness: L1 1847 (rzx-r3, s3-right).
CellAtRow:
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

; Z when one of the three cells at column E, E - 1, E - 2 (pixel line D) is not
; solid
;
; As CellAt: the cell at column E, then the one before, then the one before
; that; returns Z at the first that is not solid (A = that cell), NZ when all
; three are solid. Called from `$926A`.
;
; Witness: L1 18 (rzx-r3).
CellAtSpan3:
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
  ADD HL,BC
  LD A,(HL)
  BIT 1,A
  RET Z
  DEC HL
  LD A,(HL)
  BIT 1,A
  RET Z
  DEC HL
  LD A,(HL)
  BIT 1,A
  RET
