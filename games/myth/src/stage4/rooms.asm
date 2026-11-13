; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The room data, Unrle, the room builder and the room changes
; --------------------------------------------------------------------------------------------------------------------

  ORG $81A8

; Spawn the bonus (a piece) or the exit item of a room that has one
;
; By GridNumber and RoomNumber: grid 2 room 1 event bit $10 (the piece at D =
; $13, E = $44); grid 3 room 2 bit 8 ($07, $44); grid 4 room 1 bit 4 ($0D,
; $34); grid 5 room 2 bit 2 ($0F, $44); grid 8 room 2 bit 1 ($18, $44) once
; BossPhase is 2; grid 9 (any room), with PiecesTaken 5 and PiecesComplete 1:
; the exit item (SpawnItem $A2A5: D = 7, E = $50, the frame $E483 = item 5's
; icon, kind 5, amount 1). The event's bit goes to SpawnBonus. Callers:
; StageEntry, EnterGrid9 $8BEB, the room changes $A025, $A055, $A0A7, $A0E5 and
; $A2A2.
;
; Witness: L1 46 (rzx-r4, s4-right).
;
; In s4-right both calls were in grid 0. In rzx-r4 (44 calls) every grid's
; branch ran: the five pieces' rooms and grid 9's exit item.
RoomEvents:
  LD A,(GridNumber)
  CP $02
  JR NZ,RoomEventGrid3
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD D,$13
  LD E,$44
  LD B,$10
  JR SpawnBonus
RoomEventGrid3:
  CP $03
  JP NZ,RoomEventGrid4
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD D,$07
  LD E,$44
  LD B,$08
  JR SpawnBonus
RoomEventGrid4:
  CP $04
  JP NZ,RoomEventGrid5
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD D,$0D
  LD E,$34
  LD B,$04
  JR SpawnBonus
RoomEventGrid5:
  CP $05
  JP NZ,RoomEventGrid8
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD D,$0F
  LD E,$44
  LD B,$02
  JR SpawnBonus
RoomEventGrid8:
  CP $08
  JP NZ,RoomEventGrid9
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(BossPhase)
  CP $02
  RET NZ
  LD D,$18
  LD E,$44
  LD B,$01
  JR SpawnBonus
RoomEventGrid9:
  CP $09
  RET NZ
  LD A,(PiecesTaken)
  CP $05
  RET NZ
  LD A,(PiecesComplete)
  CP $01
  RET NZ
  LD D,$07
  LD E,$50
  LD BC,$E483
  LD L,$05
  LD H,$01
  JP SpawnItem

; Spawn a room's bonus (two records) unless its event bit is set in PiecesMask
;
; Input: B = the event's bit, D, E = X and Y. Returns when PiecesMask has the
; bit. Else, when FindFreeActorPair $93FF finds two free records in a row, both
; get the template $9F05 (the piece, handler UpdatePieceActor) at D, E with
; SpawnActor $A639: the first with +$10 = the bit (PieceTaken sets it in
; PiecesMask), the second with +$0B = 1 (its sparkle). Preserves IY. As in
; stage 1 at `$A023`.
;
; Witness: L1 9 (rzx-r4).
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

  ORG $8B8C

; Go into grid 1 ($9AFD), room 0, the hero at column 8, line $11
;
; Reached from CheckGridPassages $ACF9: grid 0 room 1, the hero at column $0C
; or more with BarrierState 2. RoomGrid = $9AFD, Placements = $9BDA, RoomNumber
; 0, the hero respawned from the template $9EE1 (SpawnActor $A639, D = 8, E =
; $11), HeroStandFrame $AF09, RebuildRoom $ADFE, GridNumber 1. IY is kept.
;
; Witness: L1 1 (rzx-r4).
EnterGrid1:
  LD IX,Grid1
  LD (RoomGrid),IX
  LD HL,Grid1Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$08
  LD E,$11
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  POP IY
  LD A,$01
  LD (GridNumber),A
  RET

; Go into grid 9 ($9AEB), room 0, the hero at column $0E, line $21; spawn the
; room's event
;
; Reached from $ADD1: grid 8 room 2 at column $1C or more. RoomGrid $9AEB,
; Placements $9B62, room 0, the hero at D = $0E, E = $21, GridNumber 9, then
; RoomEvents (the exit item once all five pieces are taken).
;
; Witness: L1 1 (rzx-r4).
EnterGrid9:
  LD IX,Grid9
  LD (RoomGrid),IX
  LD HL,Grid9Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$0E
  LD E,$21
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$09
  LD (GridNumber),A
  CALL RoomEvents
  POP IY
  RET

; Go into grid 2 ($9AF4), room 0, the hero at column 2, line $21
;
; Reached from $AD2E: grid 1 room 1, the hero at column 8 in state 5 at frame
; 5. RoomGrid $9AF4, Placements $9B6B, GridNumber 2.
;
; Witness: L1 1 (rzx-r4).
EnterGrid2:
  LD HL,Grid2
  LD (RoomGrid),HL
  LD HL,Grid2Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$02
  LD E,$21
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$02
  LD (GridNumber),A
  POP IY
  RET

; Go into grid 3 ($9B06), room 3, the hero at column $1E, line $31, facing left
;
; Reached from $AD33: grid 1 room 1, column $0A, state 5 at frame 5. RoomGrid
; $9B06, Placements $9BE6, room 3, the hero's +9 bit 7 set (facing left),
; GridNumber 3.
;
; Witness: L1 1 (rzx-r4).
EnterGrid3:
  LD HL,Grid3
  LD (RoomGrid),HL
  LD HL,Grid3Placements
  LD (Placements),HL
  PUSH IY
  LD A,$03
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$1E
  LD E,$31
  CALL SpawnActor
  SET 7,(IY+$09)
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$03
  LD (GridNumber),A
  POP IY
  RET

; Go into grid 4 ($9B0F), room 2, the hero at column $0E, line $21
;
; Reached from $AD38: grid 1 room 1, column $0C, state 5 at frame 5. RoomGrid
; $9B0F, Placements $9C5B, room 2, GridNumber 4.
;
; Witness: L1 1 (rzx-r4).
EnterGrid4:
  LD HL,Grid4
  LD (RoomGrid),HL
  LD HL,Grid4Placements
  LD (Placements),HL
  PUSH IY
  LD A,$02
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$0E
  LD E,$21
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$04
  LD (GridNumber),A
  POP IY
  RET

; Go into grid 5 ($9B18), room 0, the hero at column 2, line $31
;
; Reached from $AD3D: grid 1 room 1, column $0E, state 5 at frame 5. RoomGrid
; $9B18, Placements $9CD0, room 0, GridNumber 5.
;
; Witness: L1 1 (rzx-r4).
EnterGrid5:
  LD HL,Grid5
  LD (RoomGrid),HL
  LD HL,Grid5Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$02
  LD E,$31
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$05
  LD (GridNumber),A
  POP IY
  RET

; Go into grid 8 ($9B21), room 0, the hero at column 2, line $31
;
; Reached from $ADFB: GridNumber other than 0-5, 8 and 9 (grid 10, set by
; $96C5), room 2, column $1C or more. RoomGrid $9B21, Placements $9D66, room 0,
; GridNumber 8.
;
; Witness: L1 1 (rzx-r4).
EnterGrid8:
  LD HL,Grid8
  LD (RoomGrid),HL
  LD HL,Grid8Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$02
  LD E,$31
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$08
  LD (GridNumber),A
  POP IY
  RET

; Back from grid 9 to grid 8 room 2, the hero at column $1C, line $31, facing
; left
;
; Reached from $ADEB: grid 9, column $10, state 5 at frame 5. RoomGrid $9B21,
; Placements $9D66, room 2; the grid record's +2 (the start window's block
; column, $9B23) is $16 for the build and 0 again after it. The hero faces
; left. GridNumber 8.
;
; Witness: L1 1 (rzx-r4).
ReturnToGrid8:
  LD HL,Grid8
  LD (RoomGrid),HL
  LD HL,Grid8Placements
  LD (Placements),HL
  LD IX,Grid8
  LD (IX+$02),$16
  PUSH IY
  LD A,$02
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$1C
  LD E,$31
  CALL SpawnActor
  SET 7,(IY+$09)
  CALL HeroStandFrame
  CALL RebuildRoom
  LD IX,Grid8
  LD (IX+$02),$00
  LD A,$08
  LD (GridNumber),A
  POP IY
  RET

; Back to grid 1 room 1, the hero at column GridNumber x 2 + 2, line $31
;
; Reached from grids 2, 3, 4 and 5 ($AD5D, $AD7D, $AD9D, $ADBD: the hero in
; state 5 at frame 5 at the way out). RoomGrid $9AFD, Placements $9BDA, room 1;
; the grid record's +3 (the start window's block row, $9B00) is 6 for the build
; and 0 again after it. GridNumber 1.
;
; Witness: L1 4 (rzx-r4).
ReturnToGrid1:
  LD HL,Grid1
  LD (RoomGrid),HL
  LD HL,Grid1Placements
  LD (Placements),HL
  LD IX,Grid1
  LD (IX+$03),$06
  PUSH IY
  LD A,(GridNumber)
  SLA A
  ADD A,$02
  LD D,A
  LD A,$01
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD E,$31
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD IX,Grid1
  LD (IX+$03),$00
  LD A,$01
  LD (GridNumber),A
  POP IY
  RET

  ORG $942B

; Clear the taken flags of three placement lists
;
; The lists at $9B50, $9B62 and $9B6B (ClearTakenFlags). As in stage 1 at
; `$922F`; stage 4 has more grids, and only these three lists are reset here.
;
; Witness: L1 2 (rzx-r4, s4-right).
ResetObjectLists:
  LD HL,Grid0Placements
  CALL ClearTakenFlags
  LD HL,Grid9Placements
  CALL ClearTakenFlags
  LD HL,Grid2Placements

; Clear bit 7 of each 3-byte entry at HL up to the $FF end
;
; Witness: L1 92 (rzx-r4, s4-right).
ClearTakenFlags:
  LD A,(HL)
  CP $FF
  RET Z
  AND $7F
  LD (HL),A
  INC HL
  INC HL
  INC HL
  JR ClearTakenFlags

  ORG $969C

; Into the mummy's room: grid 10 at its room 0, the hero at column 2, line $31
;
; Jumped to from CheckGridPassages `$AD19`. RoomGrid = $9B2A, Placements =
; $9DA8, RoomNumber 0, the hero's template $9EE1 into $74E0 at 2, $31
; (SpawnActor $A639), the standing frame (HeroStandFrame $AF09), the room built
; (RebuildRoom $ADFE), then GridNumber = $0A. Preserves IY.
;
; Witness: L1 1 (rzx-r4).
EnterGrid10:
  LD HL,Grid10
  LD (RoomGrid),HL
  LD HL,Grid10Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$02
  LD E,$31
  CALL SpawnActor
  CALL HeroStandFrame
  CALL RebuildRoom
  LD A,$0A
  LD (GridNumber),A
  POP IY
  RET

  ORG $97FB

; Build the room: unpack the stage's graphics, draw the scenery, make the spans
;
; BurstTimer = 100. Unrle $A5AC the packed tiles and map $B77F into $5B00 (the
; play buffer), ClearShots, the cells (RoomCells, IX = RoomGrid),
; BlackOutPlayArea, then the tile bitmaps' and the attributes' addresses ($5B0A
; + the header words $5B02, $5B04) patched into RoomChangeBitmaps and
; RoomChangeAttrs, and every cell of the 18 x 28 play area drawn: its attribute
; into the shadow $6DC2 and its 8 bitmap bytes onto the screen
; (CopyTileToScreen, from line 48 column 2). Then BuildSpans, ClearBuffer (the
; unpacked data is gone) and the actors (JP LoadRoomActors $A654). As in stage
; 1 at `$988B`.
;
; Witness: L1 57 (rzx-r4, s4-right).
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
; Witness: L1 28728 (rzx-r4, s4-right).
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
; map). The window starts at RoomRow x width + RoomColumn of the map ($5B0A +
; the header word $5B08 + the offset); each block becomes 2 x 2 tiles
; (PutBlock), the cells 64 bytes a block row (32 a cell row, columns 2-29). As
; in stage 1 at `$9928`.
;
; Witness: L1 57 (rzx-r4, s4-right).
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
; left, top right, bottom left, bottom right). Also writes CellFlag (0: both
; branches load 0) into each cell's twin 576 bytes lower (the $7040 grid).
; Returns HL + 1 + 32. As in stage 1 at `$9986`.
;
; Witness: L1 7182 (rzx-r4, s4-right).
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

  ORG $9AE2

; Grid 0's record (GridNumber 0: the palm beach, the pyramid's steps and the
; barrier): 25 x 9 blocks, start window 0, 0, the room table Grid0Rooms, map
; offset 0
;
; A grid record, 9 bytes, as in stage 1: +0 the width and +1 the height in
; blocks, +2/+3 the start window's block column and row (StartGrid $A5CC copies
; them to RoomColumn and RoomRow; the grid passages rewrite them, Grid1 +2 at
; ReturnToGrid1 $8D23 and Grid8 +2 at ReturnToGrid8 $8CE0), +4/+5 the room
; table, +6/+7 the grid's offset in the map section of the unpacked graphics,
; +8 the rooms a grid row of rooms (meaningful only in a grid of more than one
; row of rooms: Grid1). A room is a window of 14 x 9 blocks; the windows step
; 11 block columns and 6 block rows. RoomGrid points at the record of the
; hero's grid.
;
; Stage 4 has nine grids, where stage 1 has three. They are named by the
; GridNumber ($FE47) the grid passages give them (EnterGrid1 $8B8C to
; EnterGrid10 $969C), not by their order: the records lie in the order 0, 9, 2,
; 1, 3, 4, 5, 8, 10 (GridNumber 6 and 7 do not exist); tools/fig_rooms.py names
; them by GridNumber, the record in brackets. Stage 4 keeps their nine records
; together, then the nine room tables (Grid0Rooms $9B33), then the nine
; placement lists (Grid0Placements $9B50): stage 1 puts each room table after
; its record. The resource is rooms-split.txt (tools/res_stage4.py), in
; rooms.txt's language; tools/fig_rooms.py draws the map and every room from it
; (docs/img/maps/stage4.png, stage4-rooms.png).
;
; Read in s4-right (RoomCells $9898, StartGrid $A5CC, LeaveRoomDown $A06A, the
; hero's room checks); the start columns written only by the grid passages,
; which s4-right did not run.
;
; Read by the hero's room checks (CheckRoomExits $AC9E) in s4-right.
;
; As in stage 1: LoadRoomActors $A654 puts each placement not done that lies in
; the room's window into a free actor record, with its kind's row of
; ActorKinds; MarkPlacementDone $A616 sets bit 7 when the actor is beaten or
; taken; ResetObjectLists $942B clears the bits at the stage's start. 62
; placements are kind 4 at X 250, Y 0, each right after a trap's or a switch's:
; X 250 lies outside every window, so LoadRoomActors never builds them; they
; keep the next placement's index even, so each trap's slot (+$10 / 2 in
; TrapSlots, TrapSlotAddress) is its own (known from the code: no reader of the
; X 250 records).
;
; Read and written in s4-right (LoadRoomActors, MarkPlacementDone,
; ReviveAllPlacements $A629, ResetObjectLists).
Grid0:
  INCBIN "res/stage4/rooms-split.bin",$0000,9
Grid9:
  INCBIN "res/stage4/rooms-split.bin",$0009,9
Grid2:
  INCBIN "res/stage4/rooms-split.bin",$0012,9
Grid1:
  INCBIN "res/stage4/rooms-split.bin",$001B,9
Grid3:
  INCBIN "res/stage4/rooms-split.bin",$0024,9
Grid4:
  INCBIN "res/stage4/rooms-split.bin",$002D,9
Grid5:
  INCBIN "res/stage4/rooms-split.bin",$0036,9
Grid8:
  INCBIN "res/stage4/rooms-split.bin",$003F,9
Grid10:
  INCBIN "res/stage4/rooms-split.bin",$0048,9
Grid0Rooms:
  INCBIN "res/stage4/rooms-split.bin",$0051,2
Grid9Rooms:
  INCBIN "res/stage4/rooms-split.bin",$0053,1
Grid2Rooms:
  INCBIN "res/stage4/rooms-split.bin",$0054,4
Grid1Rooms:
  INCBIN "res/stage4/rooms-split.bin",$0058,2
Grid3Rooms:
  INCBIN "res/stage4/rooms-split.bin",$005A,4
Grid4Rooms:
  INCBIN "res/stage4/rooms-split.bin",$005E,5
Grid5Rooms:
  INCBIN "res/stage4/rooms-split.bin",$0063,5
Grid8Rooms:
  INCBIN "res/stage4/rooms-split.bin",$0068,3
Grid10Rooms:
  INCBIN "res/stage4/rooms-split.bin",$006B,3
Grid0Placements:
  INCBIN "res/stage4/rooms-split.bin",$006E,18
Grid9Placements:
  INCBIN "res/stage4/rooms-split.bin",$0080,9
Grid2Placements:
  INCBIN "res/stage4/rooms-split.bin",$0089,111
Grid1Placements:
  INCBIN "res/stage4/rooms-split.bin",$00F8,12
Grid3Placements:
  INCBIN "res/stage4/rooms-split.bin",$0104,117
Grid4Placements:
  INCBIN "res/stage4/rooms-split.bin",$0179,117
Grid5Placements:
  INCBIN "res/stage4/rooms-split.bin",$01EE,150
Grid8Placements:
  INCBIN "res/stage4/rooms-split.bin",$0284,66
Grid10Placements:
  INCBIN "res/stage4/rooms-split.bin",$02C6,3

; The trap slots: 16 a grid (GridNumber 0-6), one byte an actor: 0 idle, 1
; triggered, 2 done; zero as loaded
;
; TrapSlotAddress $8786 gives $9DAB + GridNumber x 16 + the actor's +$10 / 2
; (the placement's index / 2). The switches set them (FloorSwitch $865C,
; CrumblingSlab $869B), the traps read them (SwitchedSpikes $86FF,
; FallingColumn $87AC, Pendulum $888F). StartTrapChain / TrapChainStep ($82FA,
; $830C) set grid 3's slots 6 down to 0 ($9DDB on), LinkTrapSlots ($8324) joins
; grid 3's slots 12-15 ($9DE7), grid 4's 5-10 ($9DF0) and grid 5's 4-6 ($9DFF).
; InitStageState $9F71 clears the 112 bytes at the stage's start.
;
; Read and written in rzx-r4 (the switches and traps); in s4-right only
; InitStageState's clear ran over them.
TrapSlots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
TrapSlotsGrid2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; grid 2's
                                                                       ; 16 slots
TrapSlotsGrid3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; grid 3's 16 slots: 0-6
                                                       ; the trap chain, 12-15
                                                       ; linked at $9DE7
TrapSlotsGrid3Linked:
  DEFB $00,$00,$00,$00    ; grid 3's slots 12-15
TrapSlotsGrid4:
  DEFB $00,$00,$00,$00,$00 ; grid 4's 16 slots: 5-10 linked at $9DF0
TrapSlotsGrid4Linked:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; grid 4's slots 5-10
TrapSlotsGrid5:
  DEFB $00,$00,$00,$00    ; grid 5's 16 slots: 4-6 linked at $9DFF
TrapSlotsGrid5Linked:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; grid 5's
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                 ; slots 4-6

  ORG $9FFD

; Move the room window 11 blocks right when the hero leaves by the right edge
;
; IY = the hero (called from CheckRoomExits `$ACBF`). When he faces right (+9
; bit 7 clear): ShiftRoomColumns with B = 11 blocks and C = 22 cells,
; SavePlayAttrsGrid10, RoomNumber + 1, BurstTimer = $64 (any burst stopped),
; RoomEvents $81A8. Facing left: nothing. Preserves IX and IY. As in stage 1 at
; `$9E16`.
;
; Witness: L1 235 (rzx-r4, s4-right).
LeaveRoomRight:
  PUSH IX
  PUSH IY
  LD E,$00
  LD IX,(RoomGrid)
  BIT 7,(IY+$09)
  JR NZ,LeaveRoomRightEnd
  LD B,$0B
  LD C,$16
  LD A,$00
  CALL ShiftRoomColumns
  CALL SavePlayAttrsGrid10
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
; As LeaveRoomRight, mirrored (called from CheckRoomExits `$ACB0`): only when
; the hero faces left; B = -11 blocks, C = -22 cells, RoomNumber - 1. New in
; stage 4: it also clears the six bytes $9DF0-$9DF5 of the room-state area.
;
; Witness: L1 439 (rzx-r4, s4-right).
LeaveRoomLeft:
  PUSH IX
  PUSH IY
  LD E,$00
  LD IX,(RoomGrid)
  BIT 7,(IY+$09)
  JR Z,LeaveRoomLeftEnd
  LD B,$F5
  LD C,$EA
  LD A,$00
  CALL ShiftRoomColumns
  CALL SavePlayAttrsGrid10
  LD A,(RoomNumber)
  DEC A
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  CALL RoomEvents
  LD HL,TrapSlotsGrid4Linked
  LD DE,TrapSlotsGrid4Linked+$0001
  LD BC,$0005
  LD (HL),$00
  LDIR
LeaveRoomLeftEnd:
  POP IY
  POP IX
  RET

; Move the room window 6 blocks down when the hero leaves by the bottom
;
; IY = the hero (called from CheckRoomExits `$ACCE`). Only in state 3, a fall
; (state 2 with +8 under 8 goes nowhere): ShiftRoomRows with B = 6 blocks and C
; = 96 lines, SavePlayAttrsGrid10, RoomNumber + the grid's rooms per row (the
; grid record's +8), BurstTimer = $64, RoomEvents $81A8. Preserves IX and IY.
; As in stage 1 at `$9E74`.
;
; Witness: L1 1 (rzx-r4).
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
  CALL SavePlayAttrsGrid10
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
; IY = the hero (called from CheckRoomExits `$ACDC`). Only in state 2 with +8
; under 8: ShiftRoomRows with B = -6 blocks and C = -96 lines,
; SavePlayAttrsGrid10, RoomNumber - the grid's rooms per row, BurstTimer = $64,
; RoomEvents $81A8. Preserves IX and IY. As in stage 1 at `$9EB9`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
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
  CALL SavePlayAttrsGrid10
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
; Input: B = the blocks (signed), C = the cells (2B), IY = the hero. RoomColumn
; + B; the hero's column and base column - C. 2B is written into the SUB
; operands at ShiftKeptX and ShiftKeptEntryX; every used record of the 13 from
; $74F2 with +$0F bit 1 (kept over a room change) moves by it and is freed at
; column $1E and up (a negative column wraps there too); every other record is
; freed. Then ClearPlayBuffer $8FA0 and a jump to RoomChange $97FB. As in stage
; 1 at `$9EF7`.
;
; Witness: L1 41 (rzx-r4, s4-right).
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
  LD A,$00
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
; Input: B = the blocks (signed), C = the lines (16B), IY = the hero. RoomRow +
; B; the hero's line and base line - C. C is written into ShiftKeptY and
; ShiftKeptEntryY; every used record with +$0F bit 1 is moved by it (freed
; outside lines 0-143), every other record is freed. Then ClearPlayBuffer $8FA0
; and RoomChange $97FB.
;
; As in stage 1 at `$9F4F`, with its slip: the kept actor's new line is stored
; at +0 (its column), not at +1 (`$A181` `LD (IY+$00),A`).
;
; Witness: L1 1 (rzx-r4).
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

; In grid 10, SpawnDelay = 1 (the mummy comes at once); then SavePlayAttrs
;
; New in stage 4: the room changes (`$A016`, `$A046`, `$A092`, `$A0D0`) and
; RebuildRoom `$AE01` call it in place of SavePlayAttrs. GridNumber $0A sets
; SpawnDelay to 1, so SpawnTimer $9245 brings the next mummy on the next pass;
; it goes on into SavePlayAttrs.
;
; Witness: L1 55 (rzx-r4, s4-right).
SavePlayAttrsGrid10:
  LD A,(GridNumber)
  CP $0A
  JP NZ,SavePlayAttrs
  LD A,$01
  LD (SpawnDelay),A

; Keep the old room's play-area attributes for the fade-in of the next room
;
; Copies the 576 attribute-shadow bytes of screen rows 6-23 ($6DC0, 18 x 32) to
; $7040 and sets RestoreAttributes = 1, so the next attribute pass shows the
; new room over the old one's colours. As in stage 1 at `$9FA5`.
;
; Witness: L1 55 (rzx-r4, s4-right).
SavePlayAttrs:
  LD HL,PlayAttributes
  LD DE,RoomAttributes
  LD BC,$0240
  LDIR
  LD A,$01
  LD (RestoreAttributes),A
  RET

  ORG $A5AC

; Unpack an RLE block: the first byte is the escape, ESC n v is n copies of v,
; ESC ESC ends
;
; Input: HL = the packed block, DE = the output. The block's first byte is its
; escape byte, written into UnrleEscape and UnrleEnd's compares. A byte other
; than the escape is copied; the escape followed by n, v writes n copies of v
; (n = 0 gives 256); the escape twice ends. RoomChange `$9806` unpacks the
; stage's tiles and map at $B77F to $5B00 with it at every room change. As in
; stage 1 at `$A424`.
;
; Witness: L1 57 (rzx-r4, s4-right).
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
; Clears $7280-$74BF (the room's cells), fills $74C0-$74DF with $FF,
; ClearActors $941C, then reads the RoomGrid record: RoomColumn = +2, RoomRow =
; +3, RoomExitsPtr = +4/+5 (the grid's room table), and jumps to RoomChange
; $97FB. Called at the stage start (`$7822`) and by RebuildRoom `$ADFE`. As in
; stage 1 at `$A444`.
;
; Witness: L1 15 (rzx-r4, s4-right).
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

  ORG $AC9E

; Leave the room when the hero crosses an open edge
;
; IY = the hero, IX = the room's exit flags (RoomExitsPtr). Bit 1: column under
; 6 leaves left (LeaveRoomLeft); bit 0: column $1A and up leaves right
; (LeaveRoomRight); bit 3: line $70 and down leaves down (LeaveRoomDown); bit
; 2: line under $10 leaves up (LeaveRoomUp). Not while the hero is dying (state
; $0F). As in stage 1 at `$AADA`.
;
; Witness: L1 8621 (rzx-r4, s4-right).
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

; Pass between the map grids at their fixed places
;
; IY = the hero; GridNumber, RoomNumber, the hero's column ($74E0), state
; ($74EA) and frame ($74E8). "Crouched" below is state 5 at frame 5 (the middle
; strike's pass held by LEFT). Grid 0 room 1, column $0C and up, BarrierState
; 2: `$8B8C`. Grid 1 room 1: column $15 and up with item kind 6 selected and
; UrnsComplete: EnterGrid10; under $15, crouched at column 8, $0A, $0C or $0E:
; `$8BF1`, `$8C20`, `$8C53`, `$8C82`. Crouched at grid 4 room 2 column $10,
; grid 2 room 0 column 4, grid 3 room 3 column $1C, grid 5 room 0 column 4:
; `$8D23`. Grid 8 room 2, column $1C and up: `$8BBD`. Grid 9, column $10,
; crouched: `$8CE0`. Any other grid, room 2, column $1C and up: `$8CB1`. Called
; from HeroActor `$AC11`. The targets (hA's range) move the hero between grids.
; Stage 1's routine (`$AB1C`) has four doors.
;
; Witness: L1 8621 (rzx-r4, s4-right).
CheckGridPassages:
  LD A,(GridNumber)
  CP $00
  JR NZ,CheckGridPassagesGrid1
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD A,(HeroRecord)
  CP $0C
  RET C
  LD A,(BarrierState)
  CP $02
  RET NZ
  JP EnterGrid1
CheckGridPassagesGrid1:
  CP $01
  JR NZ,CheckGridPassagesGrid4
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD A,(HeroRecord)
  CP $15
  JP C,CheckGridPassagesCrouch1
  CALL GetSelectedItem
  CP $06
  RET NZ
  LD A,(UrnsComplete)
  CP $01
  JP Z,EnterGrid10
  RET
CheckGridPassagesCrouch1:
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $05
  RET NZ
  LD A,(HeroRecord)
  CP $08
  JP Z,EnterGrid2
  CP $0A
  JP Z,EnterGrid3
  CP $0C
  JP Z,EnterGrid4
  CP $0E
  JP Z,EnterGrid5
  RET
CheckGridPassagesGrid4:
  CP $04
  JP NZ,CheckGridPassagesGrid2
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $05
  RET NZ
  LD A,(HeroRecord)
  CP $10
  JP Z,ReturnToGrid1
  RET
CheckGridPassagesGrid2:
  CP $02
  JP NZ,CheckGridPassagesGrid3
  LD A,(RoomNumber)
  CP $00
  RET NZ
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $05
  RET NZ
  LD A,(HeroRecord)
  CP $04
  JP Z,ReturnToGrid1
  RET
CheckGridPassagesGrid3:
  CP $03
  JP NZ,CheckGridPassagesGrid5
  LD A,(RoomNumber)
  CP $03
  RET NZ
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $05
  RET NZ
  LD A,(HeroRecord)
  CP $1C
  JP Z,ReturnToGrid1
  RET
CheckGridPassagesGrid5:
  CP $05
  JP NZ,CheckGridPassagesGrid8
  LD A,(RoomNumber)
  CP $00
  RET NZ
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $05
  RET NZ
  LD A,(HeroRecord)
  CP $04
  JP Z,ReturnToGrid1
  RET
CheckGridPassagesGrid8:
  CP $08
  JP NZ,CheckGridPassagesGrid9
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(HeroRecord)
  CP $1C
  JP NC,EnterGrid9
  RET
CheckGridPassagesGrid9:
  CP $09
  JP NZ,CheckGridPassagesOther
  LD A,(HeroRecord)
  CP $10
  RET NZ
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $05
  JP Z,ReturnToGrid8
  RET
CheckGridPassagesOther:
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(HeroRecord)
  CP $1C
  RET C
  JP EnterGrid8

; Clear the room's cells and build the room again
;
; StartGrid $A5CC, then on into SavePlayAttrsGrid10 (JP $A19C). Called after
; every grid change (`$8BB2` .. `$8D55`, EnterGrid10 `$96C0`). As in stage 1 at
; `$AC37`.
;
; Witness: L1 13 (rzx-r4).
RebuildRoom:
  CALL StartGrid
  JP SavePlayAttrsGrid10

  ORG $B2EC

; HL = the room cell under the actor's feet, E (and D facing left) columns
; back; Z: not solid
;
; IY = the actor. The cell row = (line + height + 3) / 8, the column = +0 - E
; (- D more facing left); HL = row x 32 + column (an offset into the cells
; $7282). Z when bit 1 (solid) of the cell is clear. As in stage 1 at `$B134`.
;
; Witness: L1 4069 (rzx-r4, s4-right).
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

; A = the room cell one row below the actor's feet, 4 columns back facing left;
; NZ: solid (not referenced)
;
; The cell row (line + height) / 8 + 1, the column +0 (- 4 facing left), HL
; into $7282. No instruction or word of the image refers to `$B31A`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
CellBelowFeet:
  LD A,(IY+$01)
  ADD A,(IY+$03)
  SRL A
  SRL A
  SRL A
  INC A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IY+$00)
  BIT 7,(IY+$09)
  JR Z,CellBelowFeetColumn
  SUB $04
CellBelowFeetColumn:
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,CellsPlay
  ADD HL,BC
  LD A,(HL)
  BIT 1,(HL)
  RET

; A = the room cell at column E, pixel line D; Z: not solid
;
; HL = D / 8 x 32 + E - 4 (an offset into the cells $7282; CellsPlay $7282 is
; screen column 2, so the cell is at screen column E - 2). The cell's bits: 1
; solid, 3 deadly (CheckDeadlyFloor). As in stage 1 at `$B162`.
;
; Witness: L1 529 (rzx-r4, s4-right).
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

; Flash the attribute $58C2 + HL red and yellow until N is pressed (not
; referenced)
;
; Saves AF; the attribute at $58C2 + HL alternates $50 and $70 a frame each
; (HALTs); reads the keyboard half-row $7FFE: N (bit 3) ends it, else the
; resident's $FCDB is called; the DJNZ's counter is B, which LD BC,$7FFE has
; just set to $7F. No instruction or word of the image refers to `$B363`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
FlashCellWait:
  PUSH AF
  LD BC,Attributes+194
  ADD HL,BC
  LD B,$64
FlashCellLoop:
  LD (HL),$50
  HALT
  LD (HL),$70
  HALT
  LD BC,$7FFE
  IN A,(C)
  BIT 3,A
  JR Z,FlashCellEnd
  CALL KeyHook
  DJNZ FlashCellLoop
FlashCellEnd:
  POP AF
  RET

  ORG $B77F

; The stage's tiles, blocks and map, RLE-packed (3366 bytes; 5331 unpacked: 179
; tiles, 108 blocks, the nine grids' map)
;
; RoomChange $97FB unpacks it with Unrle $A5AC to $5B00 at every room change
; (escape byte $C1). Unpacked: five offset words from $5B0A (the tile kinds 179
; bytes, the tile pixels 1432, the tile colours 179, the blocks 108 x 4, the
; map 3099 bytes: the nine grids in the order of their records, Grid0 25 x 9
; first). The unpacked block reaches $6FD2, over the shadow attributes;
; RoomCells $9898 takes the room's blocks into Cells before RoomChange writes
; the room's colours. The packer left one stretch of 9 equal bytes unpacked at
; offset 285 (graphics.txt's `literal`).
;
; Read in s4-right and rzx-r4 (Unrle: all 3366 bytes, at every room change).
StageGraphics:
  INCBIN "res/stage4/graphics.bin",$0000,3366
