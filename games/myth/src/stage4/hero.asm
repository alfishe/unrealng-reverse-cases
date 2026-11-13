; --------------------------------------------------------------------------------------------------------------------
; hero.asm: The hero: walk, jump, crouch, strike, fire, the items and the item window
; --------------------------------------------------------------------------------------------------------------------

  ORG $7C67

; SPACE: stop the game, flash the strip's frame, choose an item with LEFT and
; RIGHT, SPACE again to go on
;
; Clears PassCounter and waits (HALT, CycleWindowFrame) for SPACE's release;
; then every 6 frames: DrawItemStrip and ShowItemCount; RIGHT selects the
; previous slot (ScrollItemsRight), LEFT the next (ScrollItemsLeft); SPACE
; again: waits for its release, cycles the frame until its first cell $586A is
; back to colour 1, and falls into FlashSelectedBox. Called by MainLoop $7881.
; As in stage 1 at `$7C27`.
;
; Witness: L1 170 (rzx-r4).
ItemWindow:
  LD A,$00
  LD (PassCounter),A
  HALT
  CALL CycleWindowFrame
  CALL TestSpaceKey
  JR Z,ItemWindow
ItemWindowStep:
  LD B,$06
ItemWindowFrame:
  PUSH BC
  HALT
  CALL CycleWindowFrame
  CALL DrawItemStrip
  CALL ShowItemCount
  POP BC
  DJNZ ItemWindowFrame
  CALL KeyRight
  JR NZ,ItemWindowLeft
  CALL ScrollItemsRight
  JR ItemWindowStep
ItemWindowLeft:
  CALL KeyLeft
  JR NZ,ItemWindowSpace
  CALL ScrollItemsLeft
  JR ItemWindowStep
ItemWindowSpace:
  CALL TestSpaceKey
  JR NZ,ItemWindowStep
ItemWindowRelease:
  CALL TestSpaceKey
  JR Z,ItemWindowRelease
ItemWindowSettle:
  HALT
  CALL CycleWindowFrame
  LD A,(Attributes+106)
  CP $01
  JR NZ,ItemWindowSettle

; Colour the selected item's box with inks 2 to 6, one a frame
;
; Five frames: patches the colour into the inline record SelectedBoxRecord
; (column 15, line 24, 2 x 2 cells) and fills it with FillAttributes. Called at
; the stage's start (StageSetUp $9785) and reached from ItemWindow.
;
; Witness: L1 22 (rzx-r4, s4-right).
FlashSelectedBox:
  LD B,$05
  LD C,$02

; FlashSelectedBoxFrame
;
; Used by the routine at FlashSelectedBoxNext.
FlashSelectedBoxFrame:
  PUSH BC
  HALT
  LD A,C
  LD (SelectedBoxRecord+$0004),A
  CALL FillAttributes

; FillAttributes' inline record: column 15, line 24, 2 x 2 cells, the colour
; (patched)
;
; The inline record after the CALL at $7CB8, read by FillAttributes (it returns
; past it). Read in rzx-r4 and s4-right (110 calls).
SelectedBoxRecord:
  DEFB $0F,$18,$02,$02,$00

; FlashSelectedBox, continued
;
; Part of FlashSelectedBox, after its inline record: the next colour, five
; frames in all.
;
; Witness: L1 110 (rzx-r4, s4-right).
FlashSelectedBoxNext:
  POP BC
  INC C
  DJNZ FlashSelectedBoxFrame
  RET

; Select the next slot: scroll the strip 24 pixels left, one pixel a frame
;
; Returns if ItemSelected is ItemLast. Else ItemSelected + 1, and 24 times:
; shifts the strip's 18 lines in the play buffer ($5B67-$5B77, 17 bytes a line)
; one pixel left, HALT, CycleWindowFrame and ShowItemStrip. Also run three
; times at the stage's start (StageSetUp $976B-$9777, with CycleWindowFrame
; patched to RET) to roll the strip in. As in stage 1 at `$7C85`.
;
; Witness: L1 36 (rzx-r4, s4-right).
ScrollItemsLeft:
  LD A,(ItemLast)
  LD B,A
  LD A,(ItemSelected)
  CP B
  RET Z
  INC A
  LD (ItemSelected),A
  LD B,$18
ScrollItemsLeftStep:
  PUSH BC
  LD HL,PlayBuffer+119
  LD B,$12
ScrollItemsLeftLine:
  PUSH BC
  PUSH HL
  SLA (HL)
  DEC HL
  LD B,$10
ScrollItemsLeftByte:
  RL (HL)
  DEC HL
  DJNZ ScrollItemsLeftByte
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ ScrollItemsLeftLine
  HALT
  CALL CycleWindowFrame
  CALL ShowItemStrip
  POP BC
  DJNZ ScrollItemsLeftStep
  RET

; Select the previous slot: scroll the strip 24 pixels right
;
; Returns if ItemSelected is ItemFirst. Else ItemSelected - 1 and the mirror of
; ScrollItemsLeft (16 lines from $5B64). Called by ItemWindow $7C8A only.
;
; Witness: L1 23 (rzx-r4).
ScrollItemsRight:
  LD A,(ItemFirst)
  LD B,A
  LD A,(ItemSelected)
  CP B
  RET Z
  DEC A
  LD (ItemSelected),A
  LD B,$18
ScrollItemsRightStep:
  PUSH BC
  LD HL,PlayBuffer+100
  LD B,$10
ScrollItemsRightLine:
  PUSH BC
  PUSH HL
  SRL (HL)
  INC HL
  LD B,$10
ScrollItemsRightByte:
  RR (HL)
  INC HL
  DJNZ ScrollItemsRightByte
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ ScrollItemsRightLine
  HALT
  CALL CycleWindowFrame
  CALL ShowItemStrip
  POP BC
  DJNZ ScrollItemsRightStep
  RET

; Next colour of the strip's frame (the 12 cells over and under it)
;
; PassCounter + 1; the colour WindowFrameColours[PassCounter & 15] fills the
; attributes $586A-$5875 and $588A-$5895. Its first byte is a NOP that
; StageSetUp ($9763) patches to RET while it rolls the strip in, and back
; ($977A).
;
; Witness: L1 2419 (rzx-r4, s4-right).
;
; In s4-right only the patched RET ran (72 times, the roll-in); the colour code
; from $7D2E on ran in rzx-r4 (2275 times, the item window).
CycleWindowFrame:
  NOP
  LD HL,PassCounter
  INC (HL)
  LD A,(HL)
  AND $0F
  LD C,A
  LD B,$00
  LD HL,WindowFrameColours
  ADD HL,BC
  LD A,(HL)
  LD HL,Attributes+106
  LD DE,Attributes+107
  LD BC,$000B
  LD (HL),A
  LDIR
  LD HL,Attributes+138
  LD DE,Attributes+139
  LD BC,$000B
  LD (HL),A
  LDIR
  RET

; The frame's 16 inks: 1 to 7 and back
;
; Read by CycleWindowFrame $7D38 (+ PassCounter & 15). Read in rzx-r4 (the item
; window).
WindowFrameColours:
  DEFB $01,$02,$03,$04,$05,$06,$07,$07
  DEFB $07,$07,$06,$05,$04,$03,$02,$01

; When ItemsChanged is set: clear it and redraw the strip and the count
;
; Every pass (MainLoop $7846). ItemsChanged is set by AddItem. DrawItemStrip,
; then ShowItemCount (JR). In s4-right ItemsChanged stayed 0; in rzx-r4 it was
; set 13 times.
;
; Witness: L1 8620 (rzx-r4, s4-right).
RedrawItemsIfChanged:
  LD A,(ItemsChanged)
  CP $01
  RET NZ
  LD A,$00
  LD (ItemsChanged),A
  CALL DrawItemStrip
  JR ShowItemCount

; Draw the icons of slots ItemSelected-3 to +4 into the buffer and show them
;
; For 8 slots from CarriedItems + ItemSelected - 3: DrawItemIcon at $5B64 + 3 x
; n, then ShowItemStrip (JP). Callers: ItemWindow, RedrawItemsIfChanged and
; StageSetUp ($9768-$9774).
;
; Witness: L1 685 (rzx-r4, s4-right).
DrawItemStrip:
  LD A,(ItemSelected)
  SUB $03
  LD C,A
  LD B,$00
  LD HL,PlayBuffer+100
  LD IX,CarriedItems
  ADD IX,BC
  LD B,$08
DrawItemStripNext:
  PUSH BC
  LD A,(IX+$00)
  PUSH HL
  CALL DrawItemIcon
  POP HL
  LD BC,$0003
  ADD HL,BC
  INC IX
  POP BC
  DJNZ DrawItemStripNext
  JP ShowItemStrip

; Draw the selected item's count (two digits) and hide it when 0
;
; FormatItemCount, CopyToScreen of the 2 x 8 bytes at $7640 to column 15, line
; 8; then the attributes $582F and $5830: $41 (blue on black, unseen) for a
; zero digit pair, else $06. Callers: ItemWindow, RedrawItemsIfChanged, $953D,
; $9576, $95CA and $AEA3 (after an item's count changes).
;
; Witness: L1 758 (rzx-r4).
ShowItemCount:
  CALL FormatItemCount
  LD HL,DigitBuffer
  LD BC,$0F08
  LD DE,$0208
  LD A,$02
  CALL CopyToScreen
  LD IX,ItemCountText
  LD E,$41
  LD A,(IX+$02)
  CP $30
  JR Z,ShowItemCountTens
  LD E,$06
ShowItemCountTens:
  LD A,E
  LD (Attributes+47),A
  LD A,(IX+$03)
  CP $30
  JR Z,ShowItemCountUnits
  LD A,$06
  LD (Attributes+48),A
  RET
ShowItemCountUnits:
  LD A,E
  CP $41
  JR Z,ShowItemCountHide
  LD A,$06
  LD (Attributes+48),A
  RET
ShowItemCountHide:
  LD A,$41
  LD (Attributes+48),A
  RET

; Write CarriedCounts[ItemSelected] as two digits into ItemCountText and draw
; them at $7640
;
; Tens and units into ItemCountText+2 and +3, then RenderDigits (JP) with HL =
; $7640 and a stride of 2.
;
; Witness: L1 758 (rzx-r4).
FormatItemCount:
  LD A,(ItemSelected)
  LD C,A
  LD B,$00
  LD HL,CarriedCounts
  ADD HL,BC
  LD IX,ItemCountText
  LD C,$30
  LD A,(HL)
FormatItemCountTens:
  SUB $0A
  JR C,FormatItemCountUnits
  INC C
  JR FormatItemCountTens
FormatItemCountUnits:
  ADD A,$3A
  LD (IX+$03),A
  LD (IX+$02),C
  LD A,$02
  LD HL,DigitBuffer
  JP RenderDigits

; The count as text for RenderDigits: two unused bytes, two digits, 0
;
; Written by FormatItemCount ($7DFA, $7DFD) and read by RenderDigits and
; ShowItemCount ($7DB5, $7DC2). Read in rzx-r4 (758 times).
ItemCountText:
  DEFB $00,$00,$30,$30,$00

  ORG $7E5A

; Draw item icon A (16 lines of 2 bytes, a blank third byte) into the buffer at
; HL
;
; HL = the buffer address (stride 32), A = the item kind; the icon's address is
; ItemIcons[A]. Destroys BC, DE, A. Called by DrawItemStrip $7D8E.
;
; Witness: L1 5480 (rzx-r4, s4-right).
DrawItemIcon:
  PUSH HL
  LD C,A
  SLA A
  LD C,A
  LD B,$00
  LD HL,ItemIcons
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  LD B,$10
DrawItemIconLine:
  PUSH BC
  LD A,(DE)
  LD (HL),A
  INC DE
  INC HL
  LD A,(DE)
  LD (HL),A
  INC DE
  INC HL
  LD A,$00
  LD (HL),A
  LD BC,$001E
  ADD HL,BC
  POP BC
  DJNZ DrawItemIconLine
  RET

; Copy the strip's 12 x 16 window from the buffer ($5B68) to the screen ($406A)
;
; Two calls of CopyStripRows: the first 8 lines to $406A (row 3, column 10),
; the next 8 to $408A (the second by JR). Callers: ScrollItemsLeft,
; ScrollItemsRight and DrawItemStrip.
;
; Witness: L1 2101 (rzx-r4, s4-right).
ShowItemStrip:
  LD HL,PlayBuffer+104
  LD DE,Screen+106
  CALL CopyStripRows
  LD DE,Screen+138
  JR CopyStripRows

; Copy 8 lines of 12 bytes from the buffer (stride 32) to one character row of
; the screen at DE
;
; HL = the buffer (left after the call at the next 8 lines), DE = the screen
; address (D + 1 a line). Called by ShowItemStrip.
;
; Witness: L1 4202 (rzx-r4, s4-right).
CopyStripRows:
  LD B,$08
CopyStripRow:
  PUSH BC
  LD BC,$000C
  PUSH DE
  LDIR
  LD BC,$0014
  ADD HL,BC
  POP DE
  INC D
  POP BC
  DJNZ CopyStripRow
  RET

; Add D of item A to the carried items: a new slot after ItemLast, or the
; amount added (up to 99)
;
; A = the item kind, D = the amount. If A is already in CarriedItems (any of
; the 12 slots, the padding too), its count goes up by D, at most 99; else
; ItemLast + 1 and the new slot gets A and D. Sets ItemsChanged. Stage 1's
; AddItem also wrote 5 into a room-table byte for item 7; stage 4's has no such
; case. Called by $A358 (the item pick-up).
;
; Witness: L1 17 (rzx-r4).
AddItem:
  PUSH AF
  LD HL,CarriedItems
  LD B,$0C
AddItemFind:
  CP (HL)
  JR Z,AddItemMore
  INC HL
  DJNZ AddItemFind
  LD A,(ItemLast)
  INC A
  LD (ItemLast),A
  LD C,A
  LD B,$00
  LD HL,CarriedItems
  ADD HL,BC
  POP AF
  LD (HL),A
  LD HL,CarriedCounts
  ADD HL,BC
  LD (HL),D
AddItemDone:
  LD A,$01
  LD (ItemsChanged),A
  RET
AddItemMore:
  POP AF
  LD BC,$000C
  ADD HL,BC
  LD A,(HL)
  ADD A,D
  CP $64
  JR C,AddItemStore
  LD A,$63
AddItemStore:
  LD (HL),A
  JR AddItemDone

  ORG $7F3F

; A = the selected item's kind, IX = the address of its count
;
; A = CarriedItems[ItemSelected], IX = CarriedCounts + ItemSelected. BC, HL
; destroyed. Callers: CheckStageExit, AnkhShrine, the hero's item use
; ($AE14-$AE24, $AE97, $AF15), $952F, $956A, $95BE and the grid passage $AD0E.
; As in stage 1 at `$7F05`.
;
; Witness: L1 35065 (rzx-r4, s4-right).
GetSelectedItem:
  LD HL,CarriedItems
  LD A,(ItemSelected)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  LD IX,CarriedCounts
  ADD IX,BC
  RET

; The item kind of each of the 12 slots (slots 0-3 hold 4, the blank icon; the
; first item at slot 6)
;
; Copied from StartItems by InitStageState $9F81; read by GetSelectedItem,
; DrawItemStrip, AddItem and FindUrnCount. As loaded: the same as StartItems.
; Read in both recordings.
CarriedItems:
  DEFB $04,$04,$04,$04,$00,$00,$07,$02,$00,$00,$00,$00

; The amount of each slot's item (shown by ShowItemCount; AddItem adds)
;
; InitStageState sets slot 7 (item 2) to 6 ($9FD0); every other count is 0 at
; the start. Read in both recordings (GetSelectedItem's IX).
CarriedCounts:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The carried items at the stage's start, copied to CarriedItems by
; InitStageState: slot 6 item 7, slot 7 item 2
;
; Read by InitStageState $9F7E (LDIR of 12 bytes). Slots 0-3 hold 4 (the blank
; icon), 4-5 and 8-11 hold 0. ItemLast starts at 7 ($9FCB).
StartItems:
  INCBIN "res/stage4/table-startitems.bin",$0000,12

; The 16 x 16 icon of each item kind 0-9 (32 bytes each; kind 4 points to
; BlankIcon)
;
; Read by DrawItemIcon $7E61. Ten words: kinds 0-3 $E443, $E463, $E403, $E3E3;
; kind 4 BlankIcon; kinds 5-9 $E483, $E423, $E4A3, $E3C3, $E3A3 (in the stage's
; graphics). Kind 5 is the exit item (CheckStageExit), 6 the disc (AltarDisc's
; picture), 8 an ankh-like cross (AnkhShrine), 9 the urn (FindUrnCount). Read
; in both recordings (the strip).
ItemIcons:
  INCBIN "res/stage4/table-itemicons.bin",$0000,20
  ASSERT {ItemIcons+8} == BlankIcon
  ASSERT {ItemIcons+18} == ItemIconBitmaps

  ORG $802E

; Z (and C clear) when the hero is in state 7 at frame 3, the frame its attack
; hits
;
; Reads the hero's state $74EA and frame $74E8. Stage 1 tested frame 4 (the
; same instructions with CP 4). Called by the strikeable actors $A938 and
; $A997.
;
; Witness: L1 4073 (rzx-r4).
IsHeroHitFrame7:
  LD A,(HeroState)
  CP $07
  RET NZ
  LD A,(HeroFrame)
  CP $03
  RET

  ORG $8175

; While walking: thrown back from the closed barrier of grid 0 room 1
;
; IY = the hero. CheckBarrier returns Z for a closed barrier; on Z the hero
; goes to state $0B (HeroRecoil, +$0B = $FF, the first step run at once) and Z
; is returned (ReturnZ $B4A2: the walk handler stops). NZ: free. Called by the
; walk $B0F5. In s4-right the hero ran into the barrier 6 times; in rzx-r4
; never (the hero was not at x $0A facing right while the barrier was closed).
;
; Witness: L1 2174 (rzx-r4, s4-right).
CheckWalkBarriers:
  CALL CheckBarrier
  JR Z,WalkBarrierHit
  RET
WalkBarrierHit:
  LD (IY+$0B),$FF
  LD (IY+$0A),$0B
  CALL HeroRecoil
  JP ReturnZ

; Grid 0 room 1, facing right at x $0A: closed until BarrierState is 2
;
; Returns NZ (open) outside grid 0 room 1, with BarrierState 2 (ReturnNZ
; $B4A7), facing left (+9 bit 7) or at another x; Z (closed) at x $0A facing
; right. Stage 1 had three such gates (CheckRightGate, CheckLeftGate,
; CheckItemGate); stage 4 has this one.
;
; Witness: L1 2174 (rzx-r4, s4-right).
CheckBarrier:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD A,(BarrierState)
  CP $02
  JP Z,ReturnNZ
  BIT 7,(IY+$09)
  RET NZ
  LD A,(IY+$00)
  CP $0A
  RET

  ORG $8B3A

; State $0B: the hero thrown back from the closed barrier, a 6-step hop, then
; standing
;
; +$0B counts 0-6: x back by StepFineBack (A = 3: +$11 down, the column on a
; borrow), y +$0E += RecoilSteps[+$0B], the walk frame drawn (HeroWalkShow
; $B178). At 7: state 0, x - 1 column (MoveBaseX E = $FF), +$11 = 0, standing
; (HeroStandFrame $AF09). Callers: CheckWalkBarriers $8183 and the hero's state
; dispatch $AE93. As in stage 1 at `$871A`.
;
; Witness: L1 48 (s4-right).
;
; s4-right: 6 hops at the barrier of grid 0 room 1; none in rzx-r4.
HeroRecoil:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $07
  JR NZ,HeroRecoilStep
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  LD (IY+$11),$00
  JP HeroStandFrame
HeroRecoilStep:
  LD A,$03
  CALL StepFineBack
  LD C,(IY+$0B)
  LD B,$00
  LD HL,RecoilSteps
  ADD HL,BC
  LD A,(IY+$0E)
  ADD A,(HL)
  LD (IY+$0E),A
  JP HeroWalkShow

; The hop's y change at steps 0-6
;
; Read by HeroRecoil $8B5E: -5, -1, 0, 0, 1, 2, 3. Read in s4-right.
RecoilSteps:
  DEFB $FB,$FF,$00,$00,$01,$02,$03

; A leftover no code calls: Z unless bit 1 of the room cell at (column E, line
; D) is set
;
; HL = $7282 + (D / 8) x 32 + E, then BIT 1,(HL). No CALL, JP or table word
; names $8B73.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code.
CellFlagUnused:
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
  LD C,E
  LD B,$00
  ADD HL,BC
  LD BC,CellsPlay
  ADD HL,BC
  BIT 1,(HL)
  RET

  ORG $9454

; The hero's wait after a death; then he comes back at the room's respawn point
;
; IY = the hero. Every 2nd pass (PassCounter bit 0) +$10 - 1; at 0: state 0,
; the base position (+$0D, +$0E) = RespawnPoint, flags +9 = 0, RespawnShiftX =
; $FF, the standing frame (JP HeroStandFrame $AF09). Jumped to from HeroUpdate
; `$AE31` (state $0F). As in stage 1 at `$9259`.
;
; Witness: L1 522 (s4-right).
RespawnCountdown:
  LD A,(PassCounter)
  AND $01
  RET Z
  DEC (IY+$10)
  RET NZ
  LD (IY+$0A),$00
  CALL RespawnPoint
  LD A,$FF
  LD (RespawnShiftX),A
  LD (IY+$09),$00
  LD (IY+$0D),D
  LD (IY+$0E),E
  JP HeroStandFrame

; D, E = the respawn column and line of the current grid and room
;
; RespawnPoints[GridNumber x 6 + RoomNumber]. Called by RespawnCountdown and
; HeroDeath `$B3E7`.
;
; Witness: L1 8 (s4-right).
RespawnPoint:
  LD HL,RespawnPoints
  LD A,(GridNumber)
  SLA A
  LD C,A
  SLA A
  ADD A,C
  LD C,A
  LD A,(RoomNumber)
  ADD A,C
  LD C,A
  LD B,$00
  ADD HL,BC
  ADD HL,BC
  LD D,(HL)
  INC HL
  LD E,(HL)
  RET

; The respawn point of each grid's six rooms, 11 grids: the base column, the
; base line
;
; 66 pairs (column, line), read by RespawnPoint $9477 with the index GridNumber
; x 6 + RoomNumber; (0, 0) for the rooms a grid lacks. Column $14 with line
; $19, $21, $31 or $41 are the common points.
RespawnPoints:
  DEFB $14,$41,$04,$41,$14,$19,$14,$19,$14,$19,$14,$19
  DEFB $14,$19,$14,$19,$14,$19,$14,$19,$14,$19,$14,$19
  DEFB $14,$21,$12,$31,$14,$21,$12,$11,$14,$21,$14,$21
  DEFB $14,$31,$14,$31,$16,$31,$14,$31,$14,$31,$14,$31
  DEFB $16,$21,$14,$21,$14,$21,$0A,$21,$14,$21,$00,$00
  DEFB $10,$31,$10,$31,$0E,$31,$04,$31,$14,$31,$00,$00
  DEFB $14,$19,$14,$19,$14,$19,$14,$19,$14,$19,$14,$19
  DEFB $14,$19,$14,$19,$14,$19,$14,$19,$14,$19,$14,$19
  DEFB $10,$11,$14,$21,$06,$21,$14,$19,$14,$19,$14,$19
  DEFB $14,$19,$14,$19,$14,$19,$14,$19,$14,$19,$14,$19
  DEFB $02,$31,$02,$31,$02,$31,$00,$00,$00,$00,$00,$00

  ORG $951D

; Item kind 9 selected in grid 8 room 1: its count runs down; empty, it wakes
; the boss
;
; Called from HeroUpdate `$AE29` when the selected item's kind is 9. Only in
; grid 8 (GridNumber) room 1 and every 16th pass: with a count left
; (GetSelectedItem $7F3F, IX) the count - 1 and ShowItemCount $7D9E; at 0
; BossPhase is set to 1 (when it was 0), which arms HeadShots $B412 in room 2.
;
; Witness: L1 81 (rzx-r4).
DrainKind9:
  LD A,(GridNumber)
  CP $08
  RET NZ
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD A,(PassCounter)
  AND $0F
  RET NZ
  CALL GetSelectedItem
  LD A,(IX+$00)
  CP $00
  JP Z,DrainKind9Empty
  DEC (IX+$00)
  JP ShowItemCount
DrainKind9Empty:
  LD A,(BossPhase)
  CP $00
  RET NZ
  INC A
  LD (BossPhase),A
  RET

; Item kind 1: a missile of kind 9 for each press of FIRE (a count used)
;
; Called from HeroUpdate `$AE19`. FIRE edge-triggered through FireLatch. Not
; while dying (state $0F). With a count left: count - 1, ShowItemCount $7D9E,
; PlaySoundVector 8, then AddMissileHigh $B45C with C = 9 (the handler $80CC)
; at the hero's column (one less facing left) and line + 9 rounded down to 8
; (also its +5), B = 1 facing right, 0 facing left.
;
; Witness: L1 1198 (rzx-r4).
FireKind1:
  LD A,(FireLatch)
  CP $00
  JR Z,FireKind1Press
  CALL KeyFire
  RET Z
  XOR A
  LD (FireLatch),A
  RET
FireKind1Press:
  CALL KeyFire
  RET NZ
  LD A,$01
  LD (FireLatch),A
  LD A,(IY+$0A)
  CP $0F
  RET Z
  CALL GetSelectedItem
  LD A,(IX+$00)
  CP $00
  RET Z
  DEC (IX+$00)
  CALL ShowItemCount
  LD DE,$0008
  CALL PlaySoundVector
  LD D,(IY+$00)
  LD A,(IY+$01)
  ADD A,$09
  AND $F8
  LD E,A
  BIT 7,(IY+$09)
  JR NZ,FireKind1Left
  LD B,$01
  LD C,$09
  JP AddMissileHigh
FireKind1Left:
  LD B,$00
  LD C,$09
  DEC D
  JP AddMissileHigh

; Item kind 3: a missile of kind 2 for each press of FIRE, one at a time (a
; count used)
;
; Called from HeroUpdate `$AE21`. As FireKind1, but the earlier kind-2 missiles
; of the slots 8-15 are removed first (ClearKind2Missiles $95F8),
; PlaySoundVector 6, and the missile is kind 2 (the handler $80F4) at column -
; 2 with B = 1 facing left, or column + 1 with B = 0 facing right.
;
; Witness: L1 1185 (rzx-r4).
FireKind3:
  LD A,(FireLatch)
  CP $00
  JR Z,FireKind3Press
  CALL KeyFire
  RET Z
  XOR A
  LD (FireLatch),A
  RET
FireKind3Press:
  CALL KeyFire
  RET NZ
  LD A,$01
  LD (FireLatch),A
  LD A,(IY+$0A)
  CP $0F
  RET Z
  CALL GetSelectedItem
  LD A,(IX+$00)
  CP $00
  RET Z
  DEC (IX+$00)
  CALL ShowItemCount
  CALL ClearKind2Missiles
  LD DE,$0006
  CALL PlaySoundVector
  LD D,(IY+$00)
  LD A,(IY+$01)
  ADD A,$09
  AND $F8
  LD E,A
  BIT 7,(IY+$09)
  JR Z,FireKind3Right
  LD B,$01
  LD C,$02
  DEC D
  DEC D
  JP AddMissileHigh
FireKind3Right:
  LD B,$00
  LD C,$02
  INC D
  JP AddMissileHigh

  ORG $ABF9

; Per-pass handler of the hero's record ($74E0): move, fall, leave the room,
; change grid
;
; The handler word of the hero's template $9EE1, called first by
; RunActorHandlers with IY = $74E0. HeroUpdate $AE04 (controls and states),
; CheckFellOut, CheckDeadlyFloor, then (HeroActorRoom) CheckDeathZone,
; CheckHeroFooting (ledges and falls), CheckRoomExits with IX = RoomExitsPtr,
; CheckGridPassages, and RoomExitsPtr = the grid record's word +4 + RoomNumber
; (the room may have changed). Stage 1's HeroActor (`$AA3E`) has no
; CheckFellOut, CheckDeadlyFloor or CheckDeathZone.
;
; Witness: L1 8621 (rzx-r4, s4-right).
HeroActor:
  CALL HeroUpdate
  CALL CheckFellOut
  CALL CheckDeadlyFloor
HeroActorRoom:
  CALL CheckDeathZone     ; the room part (stage 1's HeroActor from its
                          ; CheckHeroFooting on)
  CALL CheckHeroFooting
  PUSH IY
  LD IX,(RoomExitsPtr)
  CALL CheckRoomExits
  CALL CheckGridPassages
  LD IX,(RoomGrid)
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD A,(RoomNumber)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD (RoomExitsPtr),HL
  POP IY
  RET

; Catch a ledge in a jump, or start a fall where the ground ends
;
; IY = the hero. In a jump (state 2) at frame $0C: solid ground one column
; ahead (CellUnderFeet $B2EC, E = 1, D = 2) lands him on the ledge: frame $0F,
; base column 2 back, base line 16 up (MoveActorY $9515), on into JumpFrame; at
; frame $0F with no ground there he drops (StartDrop). Standing (state 0, E =
; 2, D = 0) or walking (state 1, E = 1, D = 2) at frame 5 or $0B with no ground
; under him starts a fall (StartFall). As in stage 1 at `$AA67`, with other
; column offsets for the walk.
;
; Witness: L1 8621 (rzx-r4, s4-right).
CheckHeroFooting:
  LD A,(IY+$0A)
  CP $02
  JR NZ,CheckHeroFootingState
  LD A,(IY+$08)
  CP $0C
  JR NZ,CheckHeroFootingState
  LD E,$01
  LD D,$02
  CALL CellUnderFeet
  RET Z
  LD (IY+$08),$0F
  LD E,$FE
  CALL MoveBaseX
  LD C,$F0
  CALL MoveActorY
  JP JumpFrame
CheckHeroFootingState:
  LD A,(IY+$0A)
  CP $00
  JR Z,CheckHeroFootingGround
  CP $02
  JR NZ,CheckHeroFootingWalk
  LD A,(IY+$08)
  CP $0F
  RET NZ
  LD E,$01
  LD D,$02
  LD C,$02
  CALL CellUnderFeet
  JP Z,StartDrop
  RET
CheckHeroFootingWalk:
  CP $01
  RET NZ
  LD A,(IY+$08)
  CP $05
  JR Z,CheckHeroFootingGround
  CP $0B
  RET NZ
CheckHeroFootingGround:
  LD A,(IY+$0A)
  CP $00
  JR NZ,CheckHeroFootingGround2
  LD E,$02
  LD D,$00
  LD C,$07
  CALL CellUnderFeet
  JP Z,StartFall
  RET
CheckHeroFootingGround2:
  LD E,$01
  LD D,$02
  LD C,$07
  CALL CellUnderFeet
  JP Z,StartFall
  RET

  ORG $AE04

; The hero's pass: the screen edge, the items, the colour, then his state's
; handler
;
; IY = the hero. Column $1F and up, or 0: LoseLife $7F05. The selected item's
; kind (GetSelectedItem $7F3F): 1 FireKind1, 3 FireKind3, 9 DrainKind9. Dying
; (state $0F): RespawnCountdown. Colour +$0C: Energy under $0E: CycleColour AND
; 7 (flashing); else + 1 a pass up to 7 (white). While HeroFreeze counts down
; the state handler is skipped. Else by the state +$0A: 0 HeroStand, 1
; HeroWalk, 2 HeroJump, 3 HeroFall, 4 HeroLeapBack, 5 HeroStrikeMid, 6
; HeroStrikeHigh, 7 HeroStrikeLow, 9 HeroLeap, $0A HeroThrow, $0B HeroRecoil
; $8B3A. Called from HeroActor `$ABF9`. Stage 1's routine (`$AC3D`) differs in
; the hazards and weapons.
;
; Witness: L1 8621 (rzx-r4, s4-right).
HeroUpdate:
  LD A,(HeroRecord)
  CP $1F
  JP NC,HeroUpdateEdge
  CP $00
  JP NZ,HeroUpdateItems
HeroUpdateEdge:
  CALL LoseLife
HeroUpdateItems:
  CALL GetSelectedItem
  CP $01
  CALL Z,FireKind1
  CALL GetSelectedItem
  CP $03
  CALL Z,FireKind3
  CALL GetSelectedItem
  CP $09
  CALL Z,DrainKind9
  LD A,(IY+$0A)
  CP $0F
  JP Z,RespawnCountdown
  LD A,(Energy)
  CP $0E
  JR NC,HeroColourNormal
  CALL CycleColour
  AND $07
  LD (IY+$0C),A
  JR HeroUpdateFreeze
HeroColourNormal:
  LD A,(IY+$0C)
  CP $07
  JR Z,HeroUpdateFreeze
  INC A
  LD (IY+$0C),A
HeroUpdateFreeze:
  LD A,(HeroFreeze)
  CP $00
  JR Z,HeroUpdateDispatch
  DEC A
  LD (HeroFreeze),A
  RET
HeroUpdateDispatch:
  LD A,(IY+$0A)
  CP $00
  JP Z,HeroStand
  CP $01
  JP Z,HeroWalk
  CP $02
  JP Z,HeroJump
  CP $03
  JP Z,HeroFall
  CP $04
  JP Z,HeroLeapBack
  CP $05
  JP Z,HeroStrikeMid
  CP $06
  JP Z,HeroStrikeHigh
  CP $07
  JP Z,HeroStrikeLow
  CP $09
  JP Z,HeroLeap
  CP $0A
  JP Z,HeroThrow
  CP $0B
  JP Z,HeroRecoil
  RET

; Throw one of item kind 2: a missile of kind 5 (left) or 6 (right), effect $0B
;
; Called from HeroThrow `$B080` at its frame 8. GetSelectedItem $7F3F; a count
; of 0 does nothing, else count - 1, ShowItemCount $7D9E, AddMissile with D =
; the column (+ 1 facing right), E = the line + 8, C = 5 facing left, 6 facing
; right (both handled by $8450), B = 1, A = 1, then PlaySoundVector $0B.
;
; Witness: L1 10 (rzx-r4).
HeroThrowMissile:
  CALL GetSelectedItem
  LD A,(IX+$00)
  CP $00
  RET Z
  DEC (IX+$00)
  CALL ShowItemCount
  LD A,(IY+$01)
  ADD A,$08
  LD E,A
  LD A,(IY+$00)
  LD D,A
  LD C,$05
  LD B,$FF
  BIT 7,(IY+$09)
  JR NZ,HeroThrowMissileAdd
  INC C
  LD B,$01
  LD A,(IY+$00)
  ADD A,B
  LD D,A
HeroThrowMissileAdd:
  LD A,$01
  LD B,$01
  CALL AddMissile
  LD DE,$000B
  JP PlaySoundVector

; State 0: read the controls
;
; IY = the hero. FIRE: HeroFireHeld. DOWN: StartLeap. UP: StartJump. RIGHT:
; walk right (WalkRight), first turning (base column + 4, facing right) when
; facing left; LEFT the same to the left (WalkLeft). No key: HeroStandFrame.
; The keys through the resident's readers $FC90 (UP), $FC9F (DOWN), $FCAE
; (LEFT), $FCBD (RIGHT), $FCCC (FIRE). As in stage 1 at `$ADA2`.
;
; Witness: L1 3421 (rzx-r4, s4-right).
HeroStand:
  CALL KeyFire
  JR Z,HeroFireHeld
  CALL KeyDown
  JP Z,StartLeap
  CALL KeyUp
  JP Z,StartJump
  CALL KeyRight
  JR NZ,HeroStandLeft
  BIT 7,(IY+$09)
  JP Z,WalkRight
  LD E,$04
  CALL MoveBaseX
  RES 7,(IY+$09)
HeroStandLeft:
  CALL KeyLeft
  RET NZ
  BIT 7,(IY+$09)
  JP NZ,WalkLeft
  LD E,$04
  CALL MoveBaseX
  SET 7,(IY+$09)

; Show the standing frame (frame $0C of the walk set) and end the pass
;
; Frame $0C of HeroStandSet. Also jumped to by the states when they end, by
; RespawnCountdown `$9474`, EnterGrid10 `$96BD`, PlaceHeroAtStart `$A613` and
; the grid moves `$8BAF` .. `$8D52`. As in stage 1 at `$ADDD`.
;
; Witness: L1 311 (rzx-r4, s4-right).
HeroStandFrame:
  LD A,$0C
  LD (IY+$08),A
  CALL SetActorFrame

; SetActorFrame's parameters: the walk frame table $E10B, its graphics $DEA4
; (13 frames; $0C stands)
;
; Inline after HeroStandFrame's CALL SetActorFrame $ABBD. Read in s4-right (17
; passes) and rzx-r4 (294).
HeroStandSet:
  DEFW $E10B,HeroWalkSprites

; FIRE held while standing: a throw (item kind 2) or a strike (item kind 7)
;
; GetSelectedItem $7F3F: kind 2 StartThrow. Kind 7: DOWN the low strike (state
; 7, HeroStrikeLow), UP the high strike (state 6, HeroStrikeHigh), LEFT the
; middle strike (state 5, HeroStrikeMid), each from frame $FF with the base
; column + 1. Other kinds: nothing. Stage 1's (`$ADE9`) strikes with kinds 6, 5
; and 3.
;
; Witness: L1 285 (rzx-r4, s4-right).
HeroFireHeld:
  CALL GetSelectedItem
  CP $02
  JP Z,StartThrow
  CP $07
  RET NZ
  CALL KeyDown
  JR NZ,HeroFireHeldUp
  LD (IY+$08),$FF
  LD (IY+$0A),$07
  LD E,$01
  CALL MoveBaseX
  JR HeroStrikeLow
HeroFireHeldUp:
  CALL KeyUp
  JR NZ,HeroFireHeldLeft
  LD (IY+$08),$FF
  LD (IY+$0A),$06
  LD E,$01
  CALL MoveBaseX
  JP HeroStrikeHigh
HeroFireHeldLeft:
  CALL KeyLeft
  JR NZ,HeroFireHeldNone
  LD (IY+$08),$FF
  LD (IY+$0A),$05
  LD E,$01
  CALL MoveBaseX
  JR HeroStrikeMid
HeroFireHeldNone:
  RET

; An unreached RET byte after HeroFireHeld
;
; HeroFireHeld leaves by its own jumps; nothing jumps to this byte. Not
; executed in any recording (the recordings checked: s4-right, rzx-r4); known
; only from the code.
StrikeLeftover:
  DEFB $C9

; Start the throw: state $0A, frame $FF, base column + 1
;
; Jumped to from HeroFireHeld `$AF1A`; on into HeroThrow.
;
; Witness: L1 10 (rzx-r4).
StartThrow:
  LD (IY+$08),$FF
  LD (IY+$0A),$0A
  LD E,$01
  CALL MoveBaseX
  JP HeroThrow

; Start the jump: state 2, base column + 2
;
; From HeroStand `$AEDD` and WalkJumpCheck `$B191`. As in stage 1 at `$AE3D`.
;
; Witness: L1 62 (rzx-r4, s4-right).
StartJump:
  LD E,$02
  CALL MoveBaseX
  LD (IY+$0A),$02
  LD (IY+$08),$FF
  JP HeroJump

; Start the leap (DOWN): state 9, base column + 1
;
; From HeroStand `$AED7`. As in stage 1 at `$AE4D`.
;
; Witness: L1 50 (rzx-r4).
StartLeap:
  LD E,$01
  CALL MoveBaseX
  LD (IY+$0A),$09
  LD (IY+$08),$FF
  JP HeroLeap

; State 7: the low strike, 8 passes
;
; +8 counts 0-7; frame 4 + HeroStrikeLowFrames[+8] (4, 4, 5, 5, 5, 5, 4, 4) of
; the strike set; at 8 back to standing (base column - 1). The hit is tested by
; the strikeable objects (IsHeroHitFrame7 $802E). As in stage 1 at `$AE5D`.
;
; Witness: L1 234 (rzx-r4).
HeroStrikeLow:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $08
  JP NZ,HeroStrikeLowShow
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroStrikeLowShow:
  LD C,(IY+$08)
  LD B,$00
  LD HL,HeroStrikeLowFrames
  ADD HL,BC
  LD A,(HL)
  ADD A,$04
  CALL SetActorFrame

; SetActorFrame's parameters: the strike frame table $DA7B, its graphics $D785
; (16 frames)
;
; Inline after HeroStrikeLow's CALL SetActorFrame $ABBD. Read in rzx-r4 (208
; passes); not in s4-right.
HeroStrikeLowSet:
  DEFW $DA7B,HeroStrikeSprites

; the strike set's frame (less 4) for each pass of the low strike
;
; Read by HeroStrikeLow (LD HL,HeroStrikeLowFrames + the pass). Read in rzx-r4
; (208 passes); not in s4-right.
HeroStrikeLowFrames:
  DEFB $00,$00,$01,$01,$01,$01,$00,$00

; State 5: the middle strike, 10 passes; held at pass 6 while LEFT is held
;
; +8 counts 0-9 (+$10 counts the passes too); at 6 with LEFT held it stays at 5
; (the crouch CheckGridPassages looks for); at $0A back to standing (base
; column - 1). Frame 6 + HeroStrikeMidFrames[+8]. As in stage 1 at `$AE8E`.
;
; Witness: L1 54 (rzx-r4).
HeroStrikeMid:
  INC (IY+$08)
  INC (IY+$10)
  LD A,(IY+$08)
  CP $06
  JP NZ,HeroStrikeMidEnd
  CALL KeyLeft
  JP NZ,HeroStrikeMidEnd
  LD (IY+$08),$05
HeroStrikeMidEnd:
  LD A,(IY+$08)
  CP $0A
  JP NZ,HeroStrikeMidShow
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroStrikeMidShow:
  LD C,(IY+$08)
  LD B,$00
  LD HL,HeroStrikeMidFrames
  ADD HL,BC
  LD A,(HL)
  ADD A,$06
  CALL SetActorFrame

; the strike frame table $DA7B, its graphics $D785
;
; Inline after HeroStrikeMid's CALL SetActorFrame $ABBD. Read in rzx-r4 (54
; passes); not in s4-right.
HeroStrikeMidSet:
  DEFW $DA7B,HeroStrikeSprites

; the strike set's frame (less 6) for each pass of the middle strike
;
; Read by HeroStrikeMid (LD HL,HeroStrikeMidFrames + the pass). Read in rzx-r4
; (54 passes); not in s4-right.
HeroStrikeMidFrames:
  DEFB $00,$00,$01,$01,$02,$02,$01,$01,$00,$00

; State 6: the high strike; held while FIRE and UP are held
;
; +8 counts 1-9; at $0A with FIRE and UP held it restarts at 1, else back to
; standing (base column - 1). Frame HeroStrikeHighFrames[+8 / 2] (0, 1, 2, 2,
; 2: the table's later bytes are never reached). As in stage 1 at `$AED4`.
;
; Witness: L1 11 (s4-right).
HeroStrikeHigh:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $0A
  JP NZ,HeroStrikeHighEnd
  CALL KeyFire
  JP NZ,HeroStrikeHighEnd
  CALL KeyUp
  JP NZ,HeroStrikeHighEnd
  LD (IY+$08),$01
HeroStrikeHighEnd:
  LD A,(IY+$08)
  CP $0A
  JP NZ,HeroStrikeHighShow
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroStrikeHighShow:
  SRL A
  LD C,A
  LD B,$00
  LD HL,HeroStrikeHighFrames
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; the strike frame table $DA7B, its graphics $D785
;
; Inline after HeroStrikeHigh's CALL SetActorFrame $ABBD. Read in s4-right (10
; passes); not in rzx-r4.
HeroStrikeHighSet:
  DEFW $DA7B,HeroStrikeSprites

; the strike set's frame for each pair of passes of the high strike
;
; Read by HeroStrikeHigh (LD HL,HeroStrikeHighFrames + half the pass count).
; Read in s4-right (10 passes); not in rzx-r4.
HeroStrikeHighFrames:
  DEFB $00,$01,$02,$02,$02,$02,$02,$02,$02,$01,$00

; State $0A: the throw; FIRE held keeps the arm swinging, the missile leaves at
; step 8
;
; +8 counts up from 0. At $10 it goes back to 6 (the swing loops while FIRE
; stays held); at $0E with FIRE released it jumps to $12; at $18 the throw ends
; (HeroThrowEnd). At 8: HeroThrowMissile. Frame HeroThrowFrames[+8 / 2] of the
; strike set (frames 9-$0F).
;
; Witness: L1 210 (rzx-r4).
HeroThrow:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $18
  JP Z,HeroThrowEnd
  CP $10
  JP NZ,HeroThrowRelease
  LD (IY+$08),$06
  JP HeroThrowShow
HeroThrowRelease:
  CP $0E
  JP NZ,HeroThrowShow
  CALL KeyFire
  JP Z,HeroThrowShow
  LD (IY+$08),$12
HeroThrowShow:
  LD A,(IY+$08)
  CP $08
  CALL Z,HeroThrowMissile
  LD C,(IY+$08)
  SRL C
  LD B,$00
  LD HL,HeroThrowFrames
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; the strike frame table $DA7B, its graphics $D785
;
; Inline after HeroThrow's CALL SetActorFrame $ABBD. Read in rzx-r4 (200
; passes); not in s4-right.
HeroThrowSet:
  DEFW $DA7B,HeroStrikeSprites

; The throw over: base column - 1, state 0, standing frame
;
; Witness: L1 10 (rzx-r4).
HeroThrowEnd:
  LD E,$FF
  CALL MoveBaseX
  LD (IY+$0A),$00
  JP HeroStandFrame

; the strike set's frame for each pair of passes of the throw: 9, $0A, $0B,
; $0C, $0D, $0E, $0C, $0F, $0C, $0B, $0A, 9
;
; Read by HeroThrow (LD HL,HeroThrowFrames + half the pass count). Read in
; rzx-r4 (200 passes); not in s4-right.
HeroThrowFrames:
  DEFB $09,$0A,$0B,$0C,$0D,$0E,$0C,$0F,$0C,$0B,$0A,$09

; Start a fall: state 3, speed 2, frame $10, base column - 5
;
; From CheckHeroFooting `$AC8D` and `$AC9A`. As in stage 1 at `$AF1B`.
;
; Witness: L1 8 (rzx-r4).
StartFall:
  LD (IY+$0A),$03
  LD (IY+$0B),$02
  LD (IY+$08),$10
  LD E,$FB
  CALL MoveBaseX
  RET

; Drop off a ledge missed in a jump: state 3, speed 4, frame $10
;
; From CheckHeroFooting `$AC6C`. As in stage 1 at `$AF2D`.
;
; Witness: L1 2 (rzx-r4).
StartDrop:
  LD (IY+$0A),$03
  LD (IY+$0B),$04
  LD (IY+$08),$10
  RET

; RIGHT while standing: start walking unless a wall is ahead
;
; FrontCellAhead: a solid cell keeps him standing. Else state 1, frame 0, base
; column + 2, on into HeroWalk. From HeroStand `$AEE9`. As in stage 1 at
; `$AF3A`.
;
; Witness: L1 106 (rzx-r4, s4-right).
WalkRight:
  CALL FrontCellAhead
  RET NZ
  LD (IY+$08),$00
  LD (IY+$0A),$01
  INC (IY+$0D)
  INC (IY+$0D)
  JR HeroWalk

; LEFT while standing: start walking unless a wall is ahead (base column - 2)
;
; From HeroStand `$AEFD`. As in stage 1 at `$AF4F`.
;
; Witness: L1 77 (rzx-r4).
WalkLeft:
  CALL FrontCellAhead
  RET NZ
  LD (IY+$08),$00
  LD (IY+$0A),$01
  DEC (IY+$0D)
  DEC (IY+$0D)
  JR HeroWalk

; State 1: walk, 12 frames a cycle, 2 columns each half
;
; CheckWalkBarriers $8175 (Z ends the pass: a barrier throws him back). UP at
; frame 5 or $0A jumps (WalkJumpCheck). At frames 5 and $0B a wall ahead
; (FrontCell) stops him (state 0, base column = his column - 1, + 1 facing
; left); at those frames no direction key stops him too. RIGHT while facing
; left, or LEFT while facing right, turns him (HeroTurn). The frame goes 0 to
; $0B; at 0 and 6 the base column moves 2 (MoveBaseX); then HeroWalkShow. As in
; stage 1 at `$AF64`.
;
; Witness: L1 2174 (rzx-r4, s4-right).
HeroWalk:
  CALL CheckWalkBarriers
  RET Z
  CALL WalkJumpCheck
  LD A,(IY+$08)
  CP $02
  JR Z,HeroWalkFeet
  CP $08
  JR NZ,HeroWalkFeet
HeroWalkFeet:
  LD A,(IY+$08)
  CP $05
  JR Z,HeroWalkWall
  CP $0B
  JR NZ,HeroWalkRight
  LD A,$FF
HeroWalkWall:
  CALL FrontCell
  JR Z,HeroWalkRight
  LD A,$FF
  CALL NegateIfFacingLeft
  ADD A,(IY+$00)
  LD (IY+$0D),A
  LD (IY+$0A),$00
  JP HeroStandFrame
HeroWalkRight:
  CALL KeyRight
  JR NZ,HeroWalkLeft
  BIT 7,(IY+$09)
  JR Z,HeroWalkStep
  CALL HeroTurn
  JR HeroWalkStep
HeroWalkLeft:
  CALL KeyLeft
  JR NZ,HeroWalkNoKey
  BIT 7,(IY+$09)
  JR NZ,HeroWalkStep
  CALL HeroTurn
  JR HeroWalkStep
HeroWalkNoKey:
  LD A,(IY+$08)
  CP $05
  JR Z,HeroWalkStop
  CP $0B
  JR NZ,HeroWalkStep
HeroWalkStop:
  LD (IY+$0A),$00
  JP HeroStandFrame
HeroWalkStep:
  LD A,(IY+$08)
  INC A
  CP $0C
  JR NZ,HeroWalkFrame
  LD E,$02
  CALL MoveBaseX
  LD A,$00
HeroWalkFrame:
  LD (IY+$08),A
  CP $06
  JR NZ,HeroWalkShow
  LD E,$02
  CALL MoveBaseX

; Show walk frame +8
;
; Also jumped to from `$8B69`. As in stage 1's HeroWalk (`$AFD1`).
;
; Witness: L1 2090 (rzx-r4, s4-right).
HeroWalkShow:
  LD A,(IY+$08)
  CALL SetActorFrame

; the walk frame table $E10B, its graphics $DEA4
;
; Inline after HeroWalkShow's CALL SetActorFrame $ABBD. Read in s4-right (117
; passes) and rzx-r4 (1973).
HeroWalkSet:
  DEFW $E10B,HeroWalkSprites

; UP during the walk at frame 5 or $0A: drop the walk and jump
;
; Pops the return address and jumps to StartJump. From HeroWalk `$B0F9`. As in
; stage 1 at `$AFDB`.
;
; Witness: L1 2168 (rzx-r4, s4-right).
WalkJumpCheck:
  CALL KeyUp
  RET NZ
  LD A,(IY+$08)
  CP $05
  JR Z,WalkJumpCheckJump
  CP $0A
  RET NZ
WalkJumpCheckJump:
  POP HL
  JP StartJump

; A = the cell ahead of the hero at his line + 16; NZ when it is solid
;
; Column + 4 facing right, + 0 facing left (CellAt $B346). From HeroWalk
; `$B114`. As in stage 1 at `$AFED`.
;
; Witness: L1 346 (rzx-r4, s4-right).
FrontCell:
  LD A,(IY+$00)
  ADD A,$04
  LD E,A
  BIT 7,(IY+$09)
  JR Z,FrontCellLine
  LD A,E
  SUB $04
  LD E,A
FrontCellLine:
  LD A,(IY+$01)
  ADD A,$10
  LD D,A
  JP CellAt

; A = the cell 3 columns ahead (1 facing left) at the hero's line + 16; NZ when
; it is solid
;
; CellAt $B346. From WalkRight and WalkLeft. Stage 1's copy (`$B007`) is the
; same test as FrontCell; stage 4's looks one column nearer.
;
; Witness: L1 183 (rzx-r4, s4-right).
FrontCellAhead:
  LD A,(IY+$00)
  ADD A,$03
  LD E,A
  BIT 7,(IY+$09)
  JR Z,FrontCellAheadLine
  LD A,E
  SUB $02
  LD E,A
FrontCellAheadLine:
  LD A,(IY+$01)
  ADD A,$10
  LD D,A
  JP CellAt

; State 3: fall, speeding up to 4 lines a pass, land on solid ground
;
; Frames $10 to $12 of the jump set. At frame $10: solid ground under the feet
; (CellUnderFeet, E = 1, D = 2) starts the landing (frames $11, $12, then
; standing at frame 6, base column + 5); else the speed +$0B goes up by 2 to 4
; and is added to the base line. As in stage 1 at `$B021`.
;
; Witness: L1 86 (rzx-r4).
HeroFall:
  LD A,(IY+$08)
  CP $10
  JR Z,HeroFallFalling
  INC A
  CP $13
  JR NZ,HeroFallLanding
  LD (IY+$0A),$00
  LD (IY+$08),$06
  LD E,$05
  CALL MoveBaseX
  JP HeroStandFrame
HeroFallLanding:
  LD (IY+$08),A
  JR HeroFallShow
HeroFallFalling:
  LD E,$01
  LD D,$02
  LD C,$04
  CALL CellUnderFeet
  JR Z,HeroFallSpeed
  INC (IY+$08)
  JR HeroFallShow
HeroFallSpeed:
  LD A,(IY+$0B)
  CP $04
  JR Z,HeroFallMove
  ADD A,$02
  LD (IY+$0B),A
HeroFallMove:
  LD A,(IY+$0B)
  ADD A,(IY+$0E)
  LD (IY+$0E),A
HeroFallShow:
  LD A,(IY+$08)
  JP JumpFrame

; State 4: a leap that found no ledge sinks back (the leap frames backwards)
;
; At frame $FF: standing (base column - 1). As in stage 1 at `$B06B`.
;
; Witness: L1 450 (rzx-r4).
HeroLeapBack:
  DEC (IY+$08)
  LD A,(IY+$08)
  CP $FF
  JR NZ,HeroLeapBackShow
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroLeapBackShow:
  LD A,(IY+$08)
  JP LeapFrame

; State 2: the forward jump, frames 0 to $12 of the jump set
;
; At frame 9 the base column moves 1; at $13 he stands (base column + 5).
; CheckHeroFooting catches a ledge on the way down. As in stage 1 at `$B087`.
;
; Witness: L1 1191 (rzx-r4, s4-right).
HeroJump:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $09
  JR NZ,HeroJumpLedge
  LD E,$01
  CALL MoveBaseX
HeroJumpLedge:
  LD A,(IY+$08)
  CP $0C
  JR NZ,HeroJumpEnd
HeroJumpEnd:
  LD A,(IY+$08)
  CP $13
  JR NZ,JumpFrame
  LD (IY+$0A),$00
  LD E,$05
  CALL MoveBaseX
  JP HeroStandFrame

; Show frame A of the jump set
;
; As in stage 1 at `$B0A9`.
;
; Witness: L1 1216 (rzx-r4, s4-right).
JumpFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; the jump frame table $DE32, its graphics $DAE1 (19 frames)
;
; Inline after JumpFrame's CALL SetActorFrame $ABBD. Read in s4-right (56
; passes) and rzx-r4 (1160).
HeroJumpSet:
  DEFW $DE32,HeroJumpSprites

; State 9: the leap up (DOWN), frames 0 to $0D of the leap set
;
; At frame 8 a ledge under the raised feet (CellUnderFeet, E = 1, D = 2) lets
; him go on: at $0E the base line goes 16 up and he stands; no ledge sinks him
; back (state 4, HeroLeapBack). As in stage 1 at `$B0B3`.
;
; Witness: L1 450 (rzx-r4).
HeroLeap:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $0E
  JR NZ,HeroLeapLedge
  LD (IY+$0A),$00
  LD C,$F0
  CALL MoveActorY
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroLeapLedge:
  CP $08
  JR NZ,HeroLeapFrame
  LD E,$01
  LD D,$02
  LD C,$05
  CALL CellUnderFeet
  JR NZ,HeroLeapFrame
  LD (IY+$0A),$04
  LD (IY+$0B),$02
  RET
HeroLeapFrame:
  LD A,(IY+$08)

; Show frame A of the leap set
;
; As in stage 1 at `$B0E9`.
;
; Witness: L1 800 (rzx-r4).
LeapFrame:
  CALL SetActorFrame

; the leap frame table $E7DC, its graphics $E5D7 (14 frames)
;
; Inline after LeapFrame's CALL SetActorFrame $ABBD. Read in rzx-r4 (800
; passes); not in s4-right.
HeroLeapSet:
  DEFW $E7DC,HeroLeapSprites

; Turn the hero round in the walk: base column by TurnSteps[frame], facing
; flipped
;
; From HeroWalk `$B136` and `$B146`. As in stage 1 at `$B0F0`.
;
; Witness: L1 4 (rzx-r4).
HeroTurn:
  LD E,(IY+$08)
  LD D,$00
  LD HL,TurnSteps
  ADD HL,DE
  LD E,(HL)
  CALL MoveBaseX
  LD A,(IY+$09)
  XOR $80
  LD (IY+$09),A
  RET

; the base-column move of a turn at each walk frame
;
; Read by HeroTurn (LD HL,TurnSteps + the walk frame). Read in rzx-r4 (4
; turns); not in s4-right.
TurnSteps:
  DEFB $02,$02,$02,$04,$04,$04,$02,$02,$02,$02,$04,$04

  ORG $B3AE

; Start the hero's death: a burst of eight fragments, the hero hidden, the
; pause
;
; Called from `$7F32` and `$7F3C` (LoseLife). Only when no death is in progress
; (RespawnShiftX = $FF). E = the pause in pairs of passes, stored in the hero's
; +$10 ($74F0). Clears the missile slots 8-15 ($7610-$763F), adds eight
; missiles of kind 7 at the hero (column, line + 4) with +4 = 0, 2, .. 14 (the
; directions) and +5 = the column x 2 (AddMissileHigh), sets state $0F ($74EA),
; takes the respawn point (RespawnPoint $9477: D column, E line), RespawnShiftX
; and RespawnShiftY from it, and hides the hero (column 0, line $8C, colour 0).
; As in stage 1 at `$B22B`.
;
; Witness: L1 4 (s4-right).
HeroDeath:
  LD A,(RespawnShiftX)
  CP $FF
  RET NZ
  PUSH DE
  LD HL,MissilesHigh
  LD DE,MissilesHigh+$0001
  LD BC,$002F
  LD (HL),$FF
  LDIR
  POP DE
  LD A,E
  LD (HeroCounter),A
  LD B,$08
HeroDeathBurst:
  PUSH BC
  LD A,(HeroRecord)
  LD D,A
  LD A,(HeroY)
  ADD A,$04
  LD E,A
  LD C,$07
  DEC B
  SLA B
  LD A,D
  SLA A
  CALL AddMissileHigh
  POP BC
  DJNZ HeroDeathBurst
  LD A,$0F
  LD (HeroState),A
  CALL RespawnPoint
  LD A,(HeroRecord)
  SUB D
  SUB $02
  LD (RespawnShiftX),A
  LD A,(HeroY)
  SUB E
  SUB $27
  LD (RespawnShiftY),A
  LD A,$00
  LD (HeroRecord),A
  LD (HeroBaseX),A
  LD A,$8C
  LD (HeroY),A
  LD (HeroBaseY),A
  LD A,$00
  LD (HeroAttribute),A
  RET

  ORG $B71E

; Grid 0 room 1, column $0E and up: the hero loses a life
;
; Called by HeroActor `$AC02`. GridNumber 0, RoomNumber 1, the hero's column
; $0E or more: LoseLife (JP $7F05). The barrier stands at column 10 of that
; room (CheckWalkBarriers $8175 throws him back there until BarrierState is 2).
;
; Witness: L1 8621 (rzx-r4, s4-right).
CheckDeathZone:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD A,(HeroRecord)
  CP $0E
  RET C
  JP LoseLife

; The hero's base line at $51: he loses a life
;
; IY = the hero (from HeroActor `$ABFC`). +$0E = $51: LoseLife (JP $7F05).
;
; Witness: L1 8621 (rzx-r4, s4-right).
CheckFellOut:
  LD A,(IY+$0E)
  CP $51
  RET NZ
  JP LoseLife

; Standing or walking on a deadly cell: drain 4 energy
;
; IY = the hero (from HeroActor `$ABFF`). States 0 and 1 only: the cell under
; his feet (as CellUnderFeet with E = 2, D = 0); bit 3 set (the spikes):
; DamageHero $861B with C = 4.
;
; Witness: L1 8621 (rzx-r4, s4-right).
CheckDeadlyFloor:
  LD A,(IY+$0A)
  CP $01
  JP Z,CheckDeadlyFloorCell
  CP $00
  RET NZ
CheckDeadlyFloorCell:
  LD D,$00
  LD E,$02
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
  JR Z,CheckDeadlyFloorColumn
  SUB D
CheckDeadlyFloorColumn:
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,CellsPlay
  PUSH HL
  ADD HL,BC
  LD A,(HL)
  POP HL
  BIT 3,A
  RET Z
  LD C,$04
  JP DamageHero
