; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The room data, Unrle, the room builder and the room changes
; --------------------------------------------------------------------------------------------------------------------

  ORG $8329

; While walking: thrown back from a closed way (the temple's left edge,
; Medusa's room)
;
; IY = the hero. CheckFirstRoomLeft and CheckMedusaBarrier each return Z for a
; closed way; on Z the hero goes to state $0B (HeroRecoil, +$0B = $FF) and Z is
; returned (ReturnZ; the walk handler $B052 stops). NZ: free. Called by the
; walk handler: 1183 times in rzx-r2, 270 in s2-right; neither recording walked
; into a barrier (the hit at $8334 never ran).
;
; As in stage 1 at $819A with stage 2's two checks.
;
; Witness: L1 1541 (rzx-r2, s2-right, stageload).
CheckWalkBarriers:
  CALL CheckFirstRoomLeft
  JR Z,WalkBarrierHit
  CALL CheckMedusaBarrier
  JR Z,WalkBarrierHit
  RET
WalkBarrierHit:
  LD (IY+$0B),$FF
  LD (IY+$0A),$0B
  CALL HeroRecoil
  JP ReturnZ

; Z when the hero walks left at x 2 in grid 0's room 0 (the stage's first room)
;
; Grid 0, room 0, the hero facing left (+9 bit 7): Z when +0 (x) is 2. Any
; other grid or room, or facing right: NZ (ReturnNZ for the facing).
;
; Witness: L1 1541 (rzx-r2, s2-right, stageload).
CheckFirstRoomLeft:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(RoomNumber)
  CP $00
  JR NZ,CheckFirstRoomLeftNo
  BIT 7,(IY+$09)
  JP Z,ReturnNZ
  LD A,(IY+$00)
  CP $02
  RET
CheckFirstRoomLeftNo:
  RET                     ; NZ: another room

; Z when the hero walks right into Medusa's statue: x $18 while she stands, $1C
; after
;
; Grid 2, room 0, the hero facing right: with MedusaState 0 Z when x is $18
; (the statue blocks the way), else Z when x is $1C (the room's right wall).
; Other rooms, or facing left: NZ. rzx-r2 tested it 12 times, all after the
; statue was struck.
;
; Witness: L1 1541 (rzx-r2, s2-right, stageload).
CheckMedusaBarrier:
  LD A,(GridNumber)
  CP $02
  RET NZ
  LD A,(RoomNumber)
  CP $00
  RET NZ
  BIT 7,(IY+$09)
  RET NZ
  LD A,(MedusaState)
  CP $00
  JR NZ,CheckMedusaBarrierAfter
  LD A,(IY+$00)
  CP $18
  RET
CheckMedusaBarrierAfter:
  LD A,(IY+$00)           ; the statue gone: x $1C
  CP $1C
  RET

; Spawn the bonus or item of a room that has one, after a room change
;
; Called by StageEntry and the LeaveRoom routines ($984B and others). Grid 0:
; room 0 event bit 4 (the bonus at D = 7, E = $54), room 4 bit 2 ($08, $54),
; room 5 bit 1 ($18, $44). Grid 1: room 7 bit $20 ($12, $3C), only once the
; hydra is beaten (HydraHeads = $64). Grid 2: bit 8 ($0A, $34), then, with
; PiecesComplete = 1, SpawnItem kind 5 (the artefact, icon $DF05) at $11, $50.
; The event's bit goes to SpawnBonus. rzx-r2 runs it 30 times (frames
; 260-18424); the artefact appears once (grid 2).
;
; As in stage 1 at $9FB6 with stage 2's rooms.
;
; Witness: L1 39 (rzx-r2, s2-right, stageload).
RoomEvents:
  LD A,(GridNumber)
  CP $00
  JR NZ,RoomEventGrid1
  LD A,(RoomNumber)
  CP $00
  JR NZ,RoomEventRoom4
  LD D,$07
  LD E,$54
  LD B,$04
  JR SpawnBonus
RoomEventRoom4:
  CP $04
  JR NZ,RoomEventRoom5
  LD D,$08
  LD E,$54
  LD B,$02
  JR SpawnBonus
RoomEventRoom5:
  CP $05
  JR NZ,RoomEventNone
  LD D,$18
  LD E,$44
  LD B,$01
  JR SpawnBonus
RoomEventNone:
  RET
RoomEventGrid1:
  LD A,(GridNumber)
  CP $01
  JR NZ,RoomEventGrid2
  LD A,(RoomNumber)
  CP $07
  RET NZ
  LD A,(HydraHeads)
  CP $64
  RET NZ
  LD D,$12
  LD E,$3C
  LD B,$20
  JP SpawnBonus
RoomEventGrid2:
  LD D,$0A
  LD E,$34
  LD B,$08
  CALL SpawnBonus
  LD A,(PiecesComplete)
  CP $01
  RET NZ
  LD D,$11
  LD E,$50
  LD BC,ItemIconKind5
  LD L,$05
  LD H,$01
  JP SpawnItem

; Spawn a room's bonus (two records) unless its event bit is set in PiecesMask
;
; Input: B = the event's bit, D, E = X and Y. Returns when PiecesMask has the
; bit. Else, when FindTwoFreeActors $8D87 finds two free records in a row, both
; get the template $9742 (the bonus handler $842E) at D, E: the first with +$10
; = the bit (BonusHandler sets it in PiecesMask when the hero takes it), the
; second with +$0B = 1 (its sparkle). Preserves IY.
;
; As in stage 1 at $A023, the same code.
;
; Witness: L1 12 (rzx-r2, s2-right, stageload).
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

; Put a sparkle at the extra life: base X + 2, the Sparkle template
;
; IY = the extra-life actor. MoveBaseX with E = 2, then SpawnActor of the
; Sparkle template ($9730) at its base +$0D, +$0E (JP). Called by
; ExtraLifeActor ($9B3A) when the life is taken: rzx-r2 frame 2961.
;
; Witness: L1 1 (rzx-r2).
ExtraLifeSparkle:
  LD E,$02
  CALL MoveBaseX
  LD D,(IY+$0D)
  LD E,(IY+$0E)
  LD HL,SparkleTemplate
  JP SpawnActor

  ORG $8814

; Go into grid 1 (the hydra's caves, the record $9547), room 0
;
; RoomGrid = $9547, Placements = Grid1Placements, RoomNumber 0, $A3A7 (places
; the hero for the way in), $ADBA (the room built again), GridNumber 1. IY is
; kept. Reached from the grid passages ($AD7F). s2-right frame 4322, rzx-r2
; frame 7179.
;
; As in stage 1 at $AB83 with stage 2's grid record.
;
; Witness: L1 2 (rzx-r2, s2-right).
EnterGrid1:
  LD HL,Grid1
  LD (RoomGrid),HL
  LD HL,Grid1Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  CALL PlaceHeroGrid1
  CALL EnterGridBuild
  POP IY
  LD A,$01
  LD (GridNumber),A
  RET

; Go into grid 2 (Medusa's room, the record $9550), room 0, then its room
; events
;
; RoomGrid = $9550, Placements = Grid2Placements, RoomNumber 0, $A3B8 (the
; hero's place), $ADBA, GridNumber 2, RoomEvents (the bonus and the artefact).
; IY is kept. rzx-r2: frames 7450 and 16453.
;
; As in stage 1 at $ABDD with stage 2's grid record and RoomEvents.
;
; Witness: L1 2 (rzx-r2).
EnterGrid2:
  LD HL,Grid2
  LD (RoomGrid),HL
  LD HL,Grid2Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  CALL PlaceHeroGrid2
  CALL EnterGridBuild
  LD A,$02
  LD (GridNumber),A
  CALL RoomEvents
  POP IY
  RET

; Back from Medusa's room to grid 1, room 0
;
; RoomGrid = $9547, Placements = Grid1Placements, RoomNumber 0, $A3C9 (the
; hero's place), $ADBA, GridNumber 1; IX = $9547 before and after. rzx-r2:
; frames 9262 and 16975.
;
; As in stage 1 at $AC01 with stage 2's grids.
;
; Witness: L1 2 (rzx-r2).
LeaveGrid2:
  LD IX,Grid1
  LD HL,Grid1
  LD (RoomGrid),HL
  LD HL,Grid1Placements
  LD (Placements),HL
  PUSH IY
  LD A,$00
  LD (RoomNumber),A
  CALL PlaceHeroBackGrid1
  CALL EnterGridBuild
  POP IY
  LD IX,Grid1
  LD A,$01
  LD (GridNumber),A
  RET

; Back from grid 1 to grid 0 room 5
;
; RoomGrid = $953E, Placements = Grid0Placements, RoomNumber 5, $A3DE (the
; hero's place), $ADBA, RoomEvents, GridNumber 0. The grid record's byte $9540
; is set to $37 for the build and put back to 0 after it. rzx-r2: frame 17558.
;
; As in stage 1 at $ABA7 with stage 2's grid record.
;
; Witness: L1 1 (rzx-r2).
LeaveGrid1:
  LD IX,Grid0
  LD A,$37
  LD (Grid0+$0002),A
  LD (RoomGrid),IX
  LD HL,Grid0Placements
  LD (Placements),HL
  PUSH IY
  LD A,$05
  LD (RoomNumber),A
  CALL PlaceHeroBackGrid0
  CALL EnterGridBuild
  CALL RoomEvents
  POP IY
  LD IX,Grid0
  LD A,$00
  LD (GridNumber),A
  LD A,$00
  LD (Grid0+$0002),A
  RET

  ORG $8EF9

; Clear the taken flags of the stage's three object lists
;
; The lists at $9568, $95A1 and $95FE: 3-byte entries up to $FF, bit 7 of the
; first byte cleared (ClearTakenFlags).
;
; As in stage 1 at $922F, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
ResetObjectLists:
  LD HL,Grid0Placements
  CALL ClearTakenFlags
  LD HL,Grid1Placements
  CALL ClearTakenFlags
  LD HL,Grid2Placements

; Clear bit 7 of each 3-byte entry at HL up to the $FF end
;
; HL = a placement list. Called by ResetObjectLists for Grid0Placements,
; Grid1Placements and (falling in) Grid2Placements: 50 entries at the stage's
; start (frame 248).
;
; As in stage 1 at $923E.
;
; Witness: L1 159 (rzx-r2, s2-right, stageload).
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

  ORG $9257

; Build the room: unpack the stage's graphics, draw the scenery, make the spans
;
; BurstTimer = 100. Unrle $A33D the packed tiles and map $B7D5 into $5B00 (the
; play buffer), clear the shots, build
;
; the cells (RoomCells, IX = RoomGrid), $99D3, then patch the tile bitmaps' and
; the attributes' addresses into $92BD
;
; and $929F (from the header words $5B02, $5B04) and draw every cell of the 18
; x 28 play area: its attribute into
;
; the shadow $6DC2 and its 8 bitmap bytes straight onto the screen
; (CopyTileToScreen, from line 48 column 2). Then
;
; BuildSpans, ClearBuffer (the unpacked data is gone) and the actors (JP
; LoadRoomActors $A431).
;
; As in stage 1 at $988B, the same code.
;
; Witness: L1 43 (rzx-r2, s2-right, stageload).
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
; Called by RoomChange ($92C0).
;
; As in stage 1 at $991F, the same code.
;
; Witness: L1 21672 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $9928, the same code.
;
; Witness: L1 43 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $9986, the same code.
;
; Witness: L1 5418 (rzx-r2, s2-right, stageload).
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

  ORG $953E

; Grid 0's record (the temple): 69 x 9 blocks, the start window at 0, 0, the
; room table Grid0Rooms, map offset 0, 6 rooms a grid row
;
; A grid record, 9 bytes, as stage 1's: +0 the width and +1 the height in
; blocks, +2/+3 the start window's block column and row (StartGrid; StageEntry
; sets +2 = $37 for the first build and puts 0 back), +4/+5 the room table,
; +6/+7 the grid's offset in the map section of StageGraphics, +8 the rooms a
; grid row. Unlike stage 1's block the three records come first, then the three
; room tables, then the placement lists.
;
; The room table, one byte a room: the exits, bit 0 right, bit 1 left, bit 2
; up, bit 3 down (the edge checks).
;
; Read and partly written (the start window) in s2-right and rzx-r2: 146 and
; 189 of the map's 201 bytes read. The file map.txt holds the records, their
; room tables and the placement lists (tools/res_stage2.py); tools/fig_rooms.py
; draws the map and every room from it (docs/img/maps/stage2.png,
; stage2-rooms.png).
;
; LoadRoomActors puts each placement not done that lies in the room's window
; into a free actor record with its kind's row of ActorKinds. Grid 0: the urns
; (kinds 16-19), the pools' ripples (20), the statues (0, 1, 14, 15), the
; harpy's lamp, flame and rise (2, 13, 3).
Grid0:
  INCBIN "res/stage2/map.bin",$0000,9
Grid1:
  INCBIN "res/stage2/map.bin",$0009,9
Grid2:
  INCBIN "res/stage2/map.bin",$0012,9
Grid0Rooms:
  INCBIN "res/stage2/map.bin",$001B,6
Grid1Rooms:
  INCBIN "res/stage2/map.bin",$0021,8
Grid2Rooms:
  INCBIN "res/stage2/map.bin",$0029,1
Grid0Placements:
  INCBIN "res/stage2/map.bin",$002A,57
Grid1Placements:
  INCBIN "res/stage2/map.bin",$0063,93
Grid2Placements:
  INCBIN "res/stage2/map.bin",$00C0,9

  ORG $9810

; Move the room window 11 blocks right when the hero leaves by the right edge
;
; IY = the hero's record. When the hero faces right (+9 bit 7 clear):
; ShiftRoomColumns with B = 11 blocks and C = 22 cells, $9E21 and $9E4F (the
; hydra's body for the new room), SavePlayAttrs; a harpy still out (HarpyPhase
; 3) goes back to 1 (it comes again); RoomNumber + 1, BurstTimer = $64 (any
; burst stopped), RoomEvents. Facing left: nothing. Preserves IX and IY. Called
; by the room-edge check $AD4B: 110 calls, 12 room changes in rzx-r2.
;
; As in stage 1 at $9E16 with the hydra and harpy steps.
;
; Witness: L1 117 (rzx-r2, s2-right, stageload).
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
  CALL DrawHydraBody
  CALL ColourHydra
  CALL SavePlayAttrs
  LD A,(HarpyPhase)
  CP $03
  JP NZ,LeaveRoomRightNext
  LD A,$01
  LD (HarpyPhase),A
LeaveRoomRightNext:
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
; As LeaveRoomRight, mirrored and without $9E21 / $9E4F: only when the hero
; faces left (+9 bit 7 set); B = -11 blocks, C = -22 cells, SavePlayAttrs,
; RoomNumber - 1, BurstTimer $64, HarpyPhase 3 back to 1, RoomEvents. Called by
; $AD3C: 281 calls, 12 room changes in rzx-r2.
;
; As in stage 1 at $9E45 with the harpy step.
;
; Witness: L1 379 (rzx-r2, s2-right, stageload).
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
  CALL SavePlayAttrs
  LD A,(RoomNumber)
  DEC A
  LD (RoomNumber),A
  LD A,$64
  LD (BurstTimer),A
  LD A,(HarpyPhase)
  CP $03
  JP NZ,LeaveRoomLeftEvents
  LD A,$01
  LD (HarpyPhase),A
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
; As in stage 1 at $9E74, the same code.
;
; Witness: L1 1 (rzx-r2).
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
; As in stage 1 at $9EB9, the same code.
;
; Witness: L1 1 (rzx-r2).
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
; when it falls outside columns 0-29; every other record is freed. Then
; ClearPlayBuffer and a jump to RoomChange. 24 times in rzx-r2.
;
; As in stage 1 at $9EF7.
;
; Witness: L1 31 (rzx-r2, s2-right, stageload).
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
; Input: B = the blocks to move (signed), C = the lines (16B), IY = the hero.
; RoomRow + B; the hero's Y and entry Y - C. C is written into the SUB operands
; at ShiftKeptY and ShiftKeptEntryY; every used record with +$0F bit 1 is moved
; by it (freed outside lines 0-143), every other record is freed. Then $8AA0
; and a jump to the room builder $9257.
;
; The kept actor's new Y is stored at +0 (its X), not at +1 ($99A7 `LD
; (IY+$00),A`): the code moves a kept actor's Y into its X. Ran 6 times in
; s1-right.
;
; As in stage 1 at $9F4F, the same code.
;
; Witness: L1 2 (rzx-r2).
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
; $7040 and sets RestoreAttributes = 1, so the next attribute pass ($8CD0)
; shows the new room over the old one's colours.
;
; As in stage 1 at $9FA5, the same code.
;
; Witness: L1 40 (rzx-r2, s2-right, stageload).
SavePlayAttrs:
  LD HL,PlayAttributes
  LD DE,RoomAttributes
  LD BC,$0240
  LDIR
  LD A,$01
  LD (RestoreAttributes),A
  RET

  ORG $A33D

; Unpack an RLE block: the first byte is the escape, ESC n v is n copies of v,
; ESC ESC ends
;
; Input: HL = the packed block, DE = the output. The block's first byte is its
; escape byte, written into UnrleEscape and UnrleEnd's compares. Then: a byte
; other than the escape is copied; the escape followed by n, v writes n copies
; of v (n = 0 gives 256); the escape twice ends. Output: HL = the second escape
; of the end mark, DE = after the output.
;
; RoomChange $9257 ($9262) unpacks the stage's tiles and map StageGraphics
; $B7D5 to $5B00 with it at every room change (7 calls in s2-right, 33 in
; rzx-r2).
;
; As in stage 1 at $A424, the same code.
;
; Witness: L1 43 (rzx-r2, s2-right, stageload).
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
; RoomExitsPtr = +4/+5 (the grid's room table), and jumps to RoomChange $9257.
; Called at the stage start (StageEntry $7822) and by EnterGridBuild $ADBA at
; each grid change (1 in s2-right, 6 in rzx-r2).
;
; As in stage 1 at $A444, the same code.
;
; Witness: L1 10 (rzx-r2, s2-right, stageload).
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

  ORG $AD2A

; Leave the room when the hero crosses an open edge
;
; IY = the hero, IX = the room's exit flags (RoomExitsPtr $FE2E). Bit 1: column
; under 6 leaves left ($9853); bit 0: column $1A and up leaves right ($9810);
; bit 3: line $70 and down leaves down (LeaveRoomDown $9890); bit 2: line under
; $10 leaves up (LeaveRoomUp $98D5). Not while the hero is dying (state $0F).
;
; As in stage 1 at $AADA, the same code.
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
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
; By GridNumber $FE54 (stage 1 had it at $FE4B), RoomNumber $FE30 and the
; hero's column $74E0:
;
; grid 0 room 5, column $1D and up: into grid 1 (EnterGrid1 $8814);
;
; grid 1 room 0, column 2: back to grid 0 room 5 ($8882);
;
; grid 1 room 0, columns $15-$17, the hero in the middle strike (state 5) held
; at frame 3: into grid 2 ($8835);
;
; grid 2, column 2: back to grid 1 ($8859).
;
; The facing is not tested (stage 1's doors had one). In s2-right the first
; door is taken once (the walk to the right falls into grid 1); in rzx-r2 all
; four (1, 1, 2, 2).
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
CheckGridPassages:
  LD A,(GridNumber)
  CP $00
  JR NZ,CheckGridPassageGrid1
  LD A,(RoomNumber)
  CP $05
  RET NZ
  LD A,(HeroRecord)
  CP $1D
  RET C
  JP EnterGrid1
CheckGridPassageGrid1:
  CP $01
  JR NZ,CheckGridPassageGrid2
  LD A,(RoomNumber)
  CP $00
  RET NZ
  LD A,(HeroRecord)
  CP $02
  JP Z,LeaveGrid1
CheckGridPassageShrine:
  LD A,(HeroRecord)       ; columns $15-$17 of grid 1's room 0: the door into
                          ; grid 2
  CP $15
  RET C
  CP $18
  RET NC
  LD A,(HeroState)
  CP $05
  RET NZ
  LD A,(HeroFrame)
  CP $03
  RET NZ
  JP EnterGrid2
CheckGridPassageGrid2:
  CP $02
  JR NZ,CheckGridPassagesDone
  LD A,(HeroRecord)
  CP $02
  RET NZ
  JP LeaveGrid2
CheckGridPassagesDone:
  RET

; Build the grid just entered (StartGrid) and keep its attributes for the
; fade-in (SavePlayAttrs)
;
; CALL StartGrid $A35D, then JP SavePlayAttrs $99C2. Called by the four grid
; changes ($882A, $884B, $8873, $889F):
;
; once in s2-right, 6 times in rzx-r2. Stage 1 had RebuildRoom $AC37 in its
; place.
;
; Witness: L1 7 (rzx-r2, s2-right).
EnterGridBuild:
  CALL StartGrid
  JP SavePlayAttrs

  ORG $B282

; HL = the room cell under the actor's feet, E (and D facing left) columns
; back; Z: not solid
;
; IY = the actor. The cell row = (line +1 + height +3 + 3) / 8, the column = +0
; - E (- D more when facing left); HL = row x 32 + column (an offset into the
; cells $7282). Z when bit 1 (solid) of the cell is clear.
;
; As in stage 1 at $B134, the same code.
;
; Witness: L1 3828 (rzx-r2, s2-right, stageload).
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

; A copy of a feet-cell test: the row (line + height) / 8 + 1, the column (- 4
; facing left); NZ when solid (no caller)
;
; 44 bytes of code no CALL, JP or word reaches (stage 1 has no such copy). It
; ends LD A,(HL) / BIT 1,(HL) / RET.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code.
CellUnderFeetUnused:
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
  JR Z,CellUnderFeetUnusedColumn
  SUB $04
CellUnderFeetUnusedColumn:
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
; D = D / 8, on into CellAtRow $B2E2. HL = D x 32 + E - 4 (an offset into the
; cells $7282; CellsPlay $7282 is screen column 2, so the cell is at screen
; column E - 2). The cell's bits: 1 solid, 3 deadly.
;
; As in stage 1 at $B162, the same code; stage 2 enters its second part from
; outside too.
;
; Witness: L1 1762 (rzx-r2, s2-right, stageload).
CellAt:
  SRL D
  SRL D
  SRL D

; A = the room cell at column E, cell row D; Z: not solid
;
; CellAt's second part, called directly by UpdateDriftLeft $B6C3 with the row
; already divided.
;
; Witness: L1 3847 (rzx-r2, s2-right, stageload).
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

  ORG $B7D5

; The stage's tiles, blocks and map, RLE-packed (3072 bytes; 3852 unpacked: 195
; tiles, 110 blocks, the three grids' map of 1452 bytes)
;
; RoomChange $9257 unpacks it with Unrle $A33D into the play buffer at $5B00 at
; every room change. Unrle as in stage 1: the first byte is the escape ($C9
; here); a byte other than the escape is itself, ESC n v is n copies of v, ESC
; ESC ends. The unpacked block: five words (the offsets of the tile kinds,
; pixels, attributes, blocks and map from $5B0A), then the five sections.
;
; The packer that made it is greedy (every run of 4 to 255 equal bytes is ESC n
; v) except one stretch of 8 zero bytes left as they are (unpacked offset 1397,
; a blank tile's pixels); with that one exception tools/res_stage.py packs the
; block again bit for bit. graphics.txt holds the escape, the stretch, the tile
; kinds, the blocks and the map (GRIDS['stage2'] in tools/res_stage.py: 69 x 9,
; 47 x 15, 14 x 9), tiles.png the tiles' pixels and colours. Read whole in
; s2-right and rzx-r2.
StageGraphics:
  INCBIN "res/stage2/graphics.bin",$0000,3072
