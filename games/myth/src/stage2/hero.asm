; --------------------------------------------------------------------------------------------------------------------
; hero.asm: The hero: walk, jump, crouch, strike, fire, the items and the item window
; --------------------------------------------------------------------------------------------------------------------

  ORG $7BF2

; SPACE: stop the game, flash the strip's frame, choose an item with LEFT and
; RIGHT, SPACE again to go on
;
; Clears PassCounter, waits (cycling the frame colours, CycleWindowFrame) for
; SPACE's release, then every 6 frames: DrawItemStrip and ShowItemCount; RIGHT
; scrolls to the previous slot (ScrollItemsRight), LEFT to the next
; (ScrollItemsLeft); SPACE again: waits for its release, cycles the frame back
; to its first colour (until the attribute at $586A is 1) and runs on into
; FlashSelectedBox. Called by MainLoop ($7886) when SPACE is pressed and the
; hero is not dying.
;
; As in stage 1 at $7C27. In rzx-r2 the window opens 18 times (frames
; 520-18716): 14 scrolls right, 19 left; the last choice selects item 5 (the
; artefact) before the stage's exit.
;
; Witness: L1 161 (rzx-r2).
ItemWindow:
  LD A,$00
  LD (PassCounter),A
  HALT
  CALL CycleWindowFrame
  CALL TestSpaceKey
  JR Z,ItemWindow
ItemWindowStep:
  LD B,$06                ; 6 frames of the strip and the count
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
  CALL KeyLeft              ; not RIGHT: LEFT selects the next slot
  JR NZ,ItemWindowSpace
  CALL ScrollItemsLeft
  JR ItemWindowStep
ItemWindowSpace:
  CALL TestSpaceKey       ; neither: SPACE again closes the window
  JR NZ,ItemWindowStep
ItemWindowRelease:
  CALL TestSpaceKey       ; wait for SPACE's release
  JR Z,ItemWindowRelease
ItemWindowSettle:
  HALT                    ; cycle the frame back to its first colour
  CALL CycleWindowFrame
  LD A,(Attributes+106)
  CP $01
  JR NZ,ItemWindowSettle

; Colour the selected item's box with inks 2 to 6, one a frame
;
; Five frames: patches the colour into the inline record SelectedBoxRecord
; (column 15, line 24, 2 x 2 cells) and fills it with $8C63. Called by
; ItemWindow and at the stage's start (StageSetUp $91E7).
;
; As in stage 1 at $7C6E, the same code.
;
; Witness: L1 21 (rzx-r2, s2-right, stageload).
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
  LD (FlashSelectedBoxFrame+$000D),A
  CALL FillAttributes
  DEFB $0F,$18,$02,$02,$00

; FlashSelectedBox, continued
;
; Part of FlashSelectedBox, after its inline record.
;
; As in stage 1 at $7C80, the same code.
;
; Witness: L1 105 (rzx-r2, s2-right, stageload).
FlashSelectedBoxNext:
  POP BC
  INC C
  DJNZ FlashSelectedBoxFrame
  RET

; Select the next slot: scroll the strip 24 pixels left, one pixel a frame
;
; Returns if ItemSelected is ItemLast. Else ItemSelected + 1, and 24 times:
; shifts the strip's 18 lines in the play buffer ($5B66-$5B77, 17 bytes a line)
; one pixel left, cycles the frame (CycleWindowFrame) and shows the strip
; (ShowItemStrip). Also run three times at the stage's start (StageSetUp $91CD,
; $91D3, $91D9, with the frame cycle patched off) to roll the strip in.
;
; As in stage 1 at $7C85, the same code.
;
; Witness: L1 28 (rzx-r2, s2-right, stageload).
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
; ScrollItemsLeft.
;
; As in stage 1 at $7CB9, the same code.
;
; Witness: L1 14 (rzx-r2).
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
; attributes $586A-$5875 and $588A-$5895. Its first byte is a NOP that the
; stage's start (StageSetUp $91C7, $91DE) patches to RET while it rolls the
; strip in, and back.
;
; As in stage 1 at $7CED, the same code.
;
; Witness: L1 1719 (rzx-r2, s2-right, stageload).
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
; 1-7, 7, 7, 6-1: CycleWindowFrame ($7CC3) takes entry PassCounter & 15 for the
; 12 cells over and under the item strip.
WindowFrameColours:
  DEFB $01,$02,$03,$04,$05,$06,$07,$07
  DEFB $07,$07,$06,$05,$04,$03,$02,$01

; When ItemsChanged is set: clear it and redraw the strip and the count
;
; Every pass (MainLoop $7846). ItemsChanged is set by AddItem; DrawItemStrip,
; then ShowItemCount (JR). Redrew 7 times in rzx-r2 (the 7 pick-ups).
;
; As in stage 1 at $7D26.
;
; Witness: L1 8032 (rzx-r2, s2-right, stageload).
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
; n, then ShowItemStrip.
;
; As in stage 1 at $7D36, the same code.
;
; Witness: L1 556 (rzx-r2, s2-right, stageload).
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
; zero digit pair, else $06.
;
; As in stage 1 at $7D5E, the same code.
;
; Witness: L1 606 (rzx-r2).
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
; Tens and units into ItemCountText+2 and +3, then RenderDigits with a stride
; of 2.
;
; As in stage 1 at $7DA0, the same code.
;
; Witness: L1 606 (rzx-r2).
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
; Written by FormatItemCount ($7D75, the two digits) and read by RenderDigits
; through ShowItemCount ($7D3A).
ItemCountText:
  DEFB $00,$00,$30,$30,$00

  ORG $7DE5

; Draw item icon A (16 lines of 2 bytes, a blank third byte) into the buffer at
; HL
;
; HL = the buffer address (stride 32), A = the item kind; the icon's address is
; ItemIcons[A] ($7F00). Destroys BC, DE. Called by DrawItemStrip ($7D19) for
; each of the 8 slots shown.
;
; As in stage 1 at $7E19.
;
; Witness: L1 4448 (rzx-r2, s2-right, stageload).
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
; the next 8 to $408A. Called by DrawItemStrip and ScrollItemsLeft /
; ScrollItemsRight.
;
; As in stage 1 at $7E3D.
;
; Witness: L1 1444 (rzx-r2, s2-right, stageload).
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
; address.
;
; As in stage 1 at $7E4C, the same code.
;
; Witness: L1 2888 (rzx-r2, s2-right, stageload).
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
; write of 5 into the room data for item 7 is gone. Called only by ItemHandler
; ($9AE2): 7 pick-ups in rzx-r2 (frames 1660-16687), 3 of them new slots.
;
; As in stage 1 at $7E5F, without the item-7 poke.
;
; Witness: L1 7 (rzx-r2).
AddItem:
  PUSH AF
  LD HL,CarriedItems
  LD B,$0C
AddItemFind:
  CP (HL)                 ; is A in the 12 slots?
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
  LD A,$01                ; ItemsChanged = 1
  LD (ItemsChanged),A
  RET
AddItemMore:
  POP AF                  ; found: the count + D
  LD BC,$000C
  ADD HL,BC
  LD A,(HL)
  ADD A,D
  CP $64
  JR C,AddItemStore
  LD A,$63
AddItemStore:
  LD (HL),A               ; at most 99
  JR AddItemDone

  ORG $7ECA

; A = the selected item's kind, IX = the address of its count
;
; A = CarriedItems[ItemSelected], IX = CarriedCounts + ItemSelected. BC
; destroyed.
;
; As in stage 1 at $7F05, the same code.
;
; Witness: L1 9245 (rzx-r2, s2-right, stageload).
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
; Filled from StartItems by InitStageState ($9776); read by DrawItemStrip
; ($7D0C), AddItem ($7E2C, $7E41) and GetSelectedItem ($7ECA).
CarriedItems:
  DEFB $04,$04,$04,$04,$00,$00,$03,$01,$00,$00,$00,$00

; The amount of each slot's item (shown by ShowItemCount; AddItem adds)
;
; Read by FormatItemCount ($7D71) and GetSelectedItem ($7ED5, IX = the count's
; address), written by AddItem ($7E47) and InitStageState ($97B8: slot 7's
; count). All 0 as loaded.
CarriedCounts:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The carried items at the stage's start, copied to CarriedItems by
; InitStageState: slot 6 item 3, slot 7 item 1
;
; 4 4 4 4 (the blank icon) 0 0, then item 3 at slot 6 and item 1 at slot 7,
; then 0. Read by InitStageState ($9773, an LDIR of 12 bytes to CarriedItems).
; CarriedItems at $7EDC holds the same bytes as loaded.
StartItems:
  INCBIN "res/stage2/table-startitems.bin",$0000,12

; The 16 x 16 icon of each item kind 0-7 (32 bytes each; kind 4 points to the
; blank BlankIcon $8BCA)
;
; Read by DrawItemIcon ($7DEC). Kinds 0-7: $DE65, $DE85, $DEE5, $DEA5, $8BCA
; (blank), $DF05, $DEC5, $DF25. Kind 5 is the artefact the stage's exit needs
; (CheckStageExit).
ItemIcons:
  INCBIN "res/stage2/table-itemicons.bin",$0000,16
  ASSERT {ItemIcons} == ItemIconSprites
  ASSERT {ItemIcons+2} == ItemIconKind1
  ASSERT {ItemIcons+4} == ItemIconKind2
  ASSERT {ItemIcons+6} == ItemIconKind3
  ASSERT {ItemIcons+8} == BlankIcon
  ASSERT {ItemIcons+10} == ItemIconKind5
  ASSERT {ItemIcons+12} == ItemIconKind6
  ASSERT {ItemIcons+14} == ItemIconKind7

  ORG $87C2

; State $0B: the hero thrown back from a closed exit, a 6-step hop, then
; standing
;
; +$0B counts 0-6: y += RecoilSteps[+$0B], x back one pixel step ($8B75 with 3:
; +$11 down, the column on wrap) and the walk frame drawn ($B0D8). At 7: state
; 0, x - 1 column ($B256 E = $FF), +$11 = 0, standing ($AED5).
;
; As in stage 1 at $871A, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code.
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
; -5, -1, 0, 0, 1, 2, 3. Read by HeroRecoil ($87E6) with the step.
RecoilSteps:
  DEFB $FB,$FF,$00,$00,$01,$02,$03

; A leftover no code calls: Z unless bit 1 of the room cell at (column E, line
; D) is set
;
; HL = $7282 + (D / 8) x 32 + E, then BIT 1,(HL). No caller in the image.
;
; As in stage 1 at $8753, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
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

  ORG $8F22

; The hero's wait after a death; then he comes back at the room's respawn point
;
; IY = the hero. Every 2nd pass +$10 - 1; at 0: state 0, position (+$0D, +$0E)
; = RespawnPoint, flags 0,
;
; RespawnShiftX = $FF, the standing frame (JP $AED5). Reached from HeroUpdate
; ($ADE2 JP Z).
;
; As in stage 1 at $9259, the same code.
;
; Witness: L1 723 (rzx-r2, s2-right).
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

; D, E = the respawn column and line of the room RoomNumber in grid GridNumber
;
; HL = RespawnPoints' grid 1 part, grid 0 part ($8F76) or grid 2 part ($8F82)
; by GridNumber; D, E = the pair at RoomNumber x 2. Called by RespawnCountdown
; ($8F30) and $B379 (the hero's death): 10 times in s2-right, 2 in rzx-r2
; (frame 12755).
;
; As in stage 1 at $927C with stage 2's tables (grid 1's first).
;
; Witness: L1 12 (rzx-r2, s2-right).
RespawnPoint:
  LD HL,RespawnPoints
  LD A,(GridNumber)
  CP $01
  JR Z,RespawnPointRead
  LD HL,RespawnPointsGrid0
  CP $00
  JR Z,RespawnPointRead
  LD HL,RespawnPointsGrid2
RespawnPointRead:
  LD A,(RoomNumber)
  SLA A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD D,(HL)
  INC HL
  LD E,(HL)
  RET

; Column, line of each room: grid 1 (8 rooms), grid 0 (6) at $8F76, grid 2 (1)
; at $8F82
;
; 15 pairs, read by RespawnPoint ($8F45-$8F64).
RespawnPoints:
  DEFB $06,$19
  DEFB $0C,$39
  DEFB $0A,$19
  DEFB $04,$19
  DEFB $00,$00
  DEFB $16,$E9
  DEFB $08,$F9
  DEFB $04,$19
RespawnPointsGrid0:
  DEFB $0E,$41            ; grid 0, rooms 0-5
  DEFB $0E,$41
  DEFB $08,$41
  DEFB $0A,$41
  DEFB $0A,$41
  DEFB $14,$31
RespawnPointsGrid2:
  DEFB $08,$21            ; grid 2, room 0

  ORG $90F5

; Throw the selected item when the fire key is pressed (one throw a press)
;
; Called from HeroUpdate ($ADDA CALL Z). FireLatch makes it one throw a press.
; Unless the hero's state is $0F: takes one of the selected
;
; item's count (none left: nothing), redraws it ($7D29), plays effect 8 and
; launches a shot from the hero's hands
;
; ($B3C5: D = the column (one less facing left), E = the line + 8 rounded to a
; cell, B = the direction, C = 9).
;
; As in stage 1 at $92D1, the same code.
;
; Witness: L1 1411 (rzx-r2).
ThrowItem:
  LD A,(FireLatch)
  CP $00
  JR Z,ThrowItemPress
  CALL KeyFire
  RET Z
  XOR A
  LD (FireLatch),A
  RET
ThrowItemPress:
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
  ADD A,$08
  AND $F8
  LD E,A
  BIT 7,(IY+$09)
  JR NZ,ThrowItemLeft
  LD B,$01
  LD C,$09
  JP AddMissileHigh
ThrowItemLeft:
  LD B,$00
  LD C,$09
  DEC D
  JP AddMissileHigh

  ORG $AC8E

; Per-pass handler of the hero's record ($74E0): move, fall, leave the room,
; change grid
;
; The handler word of the hero's template ($96CA), called first in each pass of
; RunActorHandlers $A523 with IY = $74E0. HeroUpdate $ADC0 (controls and
; states), CheckHeroFooting $ACB7 (ledges and falls), CheckRoomExits $AD2A with
; IX = RoomExitsPtr $FE2E, CheckGridPassages $AD6C, then RoomExitsPtr = the
; grid record's word +4 + RoomNumber $FE30 (the room may have changed).
;
; As in stage 1 at $AA3E, the same code.
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
HeroActor:
  CALL HeroUpdate
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
; IY = the hero. In a jump (state 2) at frame $0C: solid ground under the feet
; one column ahead (CellUnderFeet $B282, E = 1, D = 2) lands him on the ledge:
; frame $0F, the base column 2 back, the base line 16 up ($8F84), on into the
; jump's frame (JumpFrame $B1ED); at frame $0F with no ground there he drops
; (StartDrop $B01D). Standing (state 0) or walking (state 1) at frame 5 or $0B
; with no ground under him (E = 2, D = 0) starts a fall (StartFall $B00B).
;
; As in stage 1 at $AA67, the same instructions; the operands the draft marked
; are the same numbers (the frames, the offsets) and the routines' new
; addresses: nothing of the stage.
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
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

  ORG $ADC0

; The hero's pass: the edges, the weapons, the colour, the freeze, then his
; state's handler
;
; IY = the hero. At column 1, or 32 and up, a life is lost ($7E90; never
; executed in the two recordings). The selected item's kind (GetSelectedItem
; $7ECA): 6 fires the hero's missile (FireHeroMissile $AE43), 1 throws it
; (ThrowItem $90F5). Dying (state $0F): the death pause (RespawnCountdown
; $8F22). The colour (stage 1's HeroColour $ACD9, here in line): Energy $FE3C
; under $0E, the colour cycle (CycleColour $B4FB AND 7); else +$0C rises one a
; pass up to 7 (white). While HeroFreeze $FE66 counts down (LoseLife sets $17:
; $7EA8) the controls are ignored. Else by the state +$0A: 0 HeroStand $AE9B, 1
; HeroWalk $B052, 2 HeroJump $B1C4, 3 HeroFall $B126, 4 HeroLeapBack $B1A8, 5
; HeroStrikeMid $AF8C, 6 HeroStrikeHigh $AFC8, 7 HeroStrikeLow $AF4F, 9
; HeroLeap $B1F7, $0B HeroRecoil $87C2 (8 and $0A: nothing).
;
; Stage 1's deadly-cell test and item 1's drain are not here. In s2-right 1952
; passes, rzx-r2 5806.
;
; As in stage 1's HeroUpdate $AC3D in its job; the code is its own.
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
HeroUpdate:
  LD A,(HeroRecord)
  CP $01
  JP Z,HeroUpdateEdge
  CP $20
  JP C,HeroUpdateWeapons
HeroUpdateEdge:
  CALL LoseLife
HeroUpdateWeapons:
  CALL GetSelectedItem
  CP $06
  CALL Z,FireHeroMissile
  CP $01
  CALL Z,ThrowItem
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
  CP $0B
  JP Z,HeroRecoil
  RET

; Item kind 6: a missile for each press of FIRE (no count)
;
; FIRE edge-triggered through FireLatch $FE60 (KeyFire $FCCC). E = the hero's
; line - 2; in the states 0, 3, 4 and 9 the column one off (B = 1), in state 5
; two off (B = 2), in the others nothing; facing left: kind 5 at the column -
; B, facing right: kind 6 at the column + B; +4 = 1, +5 = 1 (AddMissile $B3BD);
; effect $0B. The missile is UpdateHeroMissile $B56D's.
;
; In rzx-r2 1136 passes with item 6, 66 missiles; s2-right never selects it.
;
; Witness: L1 1136 (rzx-r2).
FireHeroMissile:
  LD A,(FireLatch)
  CP $00
  JR Z,FireHeroMissilePress
  CALL KeyFire
  RET Z
  XOR A
  LD (FireLatch),A
  RET
FireHeroMissilePress:
  CALL KeyFire
  RET NZ
  LD A,$01
  LD (FireLatch),A
  LD A,(IY+$01)
  SUB $02
  LD E,A
  LD B,$01
  LD A,(IY+$0A)
  CP $00
  JR Z,FireHeroMissileLeft
  CP $09
  JR Z,FireHeroMissileLeft
  CP $03
  JR Z,FireHeroMissileLeft
  CP $04
  JR Z,FireHeroMissileLeft
  CP $05
  RET NZ
  INC B
FireHeroMissileLeft:
  LD A,(IY+$00)
  SUB B
  LD D,A
  LD C,$05
  BIT 7,(IY+$09)
  JR NZ,FireHeroMissileAdd
  INC C
  LD A,(IY+$00)
  ADD A,B
  LD D,A
FireHeroMissileAdd:
  LD A,$01
  LD B,$01
  CALL AddMissile
  LD DE,$000B
  JP PlaySoundVector

; State 0: read the controls
;
; IY = the hero. FIRE: HeroFireHeld $AEE1. DOWN: the leap (StartLeap $AF3F).
; UP: the jump (StartJump $AF2F). RIGHT: walk right (WalkRight $B02A), first
; turning (base column + 4, facing right) when facing left; LEFT the same to
; the left (WalkLeft $B03E). No key: the standing frame (HeroStandFrame $AED5).
; The key readers are the resident's KeyUp $FC90 to KeyFire $FCCC (Z = held).
;
; As in stage 1 at $ADA2, the same instructions.
;
; Witness: L1 3192 (rzx-r2, s2-right, stageload).
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
; Frame $0C of HeroStandSet. Also jumped to by the states when they end, by the
; hero's placings (PlaceHeroAtStart $A396 ...) and by RespawnCountdown $8F42
; (the end of the death pause).
;
; As in stage 1 at $ADDD, the same code.
;
; Witness: L1 274 (rzx-r2, s2-right, stageload).
HeroStandFrame:
  LD A,$0C
  LD (IY+$08),A
  CALL SetActorFrame

; SetActorFrame's parameters: the walk frame table $D1F8, its graphics $CF2E
HeroStandSet:
  DEFW HeroWalkFrameTable,HeroWalkSprites

; FIRE held while standing: a strike with a hand weapon
;
; Only with the selected item's kind 6, 5 or 3 (GetSelectedItem $7ECA): DOWN
; the low strike (state 7, HeroStrikeLow $AF4F), UP the high strike (state 6,
; HeroStrikeHigh $AFC8), LEFT the middle strike (state 5, HeroStrikeMid $AF8C);
; each starts at frame $FF with the base column + 1. Stage 1 also cleared +$10
; for the middle strike; stage 2 does not.
;
; In s2-right 204 passes (4 high strikes), rzx-r2 184 (13 high, 5 low, 2
; middle).
;
; Witness: L1 398 (rzx-r2, s2-right, stageload).
HeroFireHeld:
  CALL GetSelectedItem
  CP $06
  JR Z,HeroFireHeldKeys
  CP $05
  JR Z,HeroFireHeldKeys
  CP $03
  JR NZ,HeroFireHeldNoWeapon
HeroFireHeldKeys:
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
HeroFireHeldNoWeapon:
  RET

; Start the jump: state 2, base column + 2
;
; Also entered from the walk (WalkJumpCheck $B0E2).
;
; As in stage 1 at $AE3D, the same code.
;
; Witness: L1 58 (rzx-r2, s2-right, stageload).
StartJump:
  LD E,$02
  CALL MoveBaseX
  LD (IY+$0A),$02
  LD (IY+$08),$FF
  JP HeroJump

; Start the leap (DOWN): state 9, base column + 1
;
; Jumped to from HeroStand ($AEA3).
;
; As in stage 1 at $AE4D, the same code.
;
; Witness: L1 50 (rzx-r2).
StartLeap:
  LD E,$01
  CALL MoveBaseX
  LD (IY+$0A),$09
  LD (IY+$08),$FF
  JP HeroLeap

; State 7: the low strike, 6 passes; held at pass 3 while DOWN is held
;
; Frames 0, 0, 1, 1, 0, 0 of the strike set (HeroStrikeLowFrames,
; HeroStrikeLowSet); at pass 6 back to standing (base column - 1). Stage 1's
; low strike had 8 passes and frames 4-5; stage 2's low strike is the one
; UpdateFloorShot $B52B lets deflect a floor shot (frame 2 of the state... see
; there).
;
; In rzx-r2 154 passes; none in s2-right.
;
; Witness: L1 154 (rzx-r2).
HeroStrikeLow:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $03
  JR NZ,HeroStrikeLowEnd
  CALL KeyDown
  JR NZ,HeroStrikeLowEnd
  LD (IY+$08),$02
HeroStrikeLowEnd:
  LD A,(IY+$08)
  CP $06
  JR NZ,HeroStrikeLowShow
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
  CALL SetActorFrame

; SetActorFrame's parameters: the strike frame table $CABB, its graphics $C7FE
HeroStrikeLowSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; the strike set's frame for each pass of the low strike (+9 for the middle
; strike)
HeroStrikeLowFrames:
  DEFB $00,$00,$01,$01,$00,$00

; State 5: the middle strike, 6 passes; held at pass 3 while LEFT is held
;
; Frames 9, 9, $0A, $0A, 9, 9 of the strike set (HeroStrikeLowFrames + 9); +$10
; counts its passes (the harpy's phase 2, HarpyRiseAsleep $A87D, and the door
; into grid 2, CheckGridPassages $AD9D, look at it and at the frame 3).
;
; In rzx-r2 16 passes; none in s2-right.
;
; As in stage 1 at $AE8E in its job (stage 1: 10 passes, held at pass 6).
;
; Witness: L1 16 (rzx-r2).
HeroStrikeMid:
  INC (IY+$08)
  INC (IY+$10)
  LD A,(IY+$08)
  CP $03
  JR NZ,HeroStrikeMidEnd
  CALL KeyLeft
  JR NZ,HeroStrikeMidEnd
  LD (IY+$08),$02
HeroStrikeMidEnd:
  LD A,(IY+$08)
  CP $06
  JR NZ,HeroStrikeMidShow
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroStrikeMidShow:
  LD C,(IY+$08)
  LD B,$00
  LD HL,HeroStrikeLowFrames
  ADD HL,BC
  LD A,(HL)
  ADD A,$09
  CALL SetActorFrame

; the strike frame table $CABB, its graphics $C7FE
HeroStrikeMidSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; State 6: the high strike, $0E passes; held at pass $0A (back to 0) while FIRE
; and UP are held
;
; Frames 2, 3, 4, 5, 6, 7, 8 of the strike set (HeroStrikeHighFrames, by the
; pass / 2). Its pass 7 (frame 7 of the record, $816D) is the hit of the
; statues and the urns (KneelingStatueActor, WarriorStatueActor,
; StrikeableActor).
;
; In s2-right 60 passes, rzx-r2 385.
;
; Witness: L1 445 (rzx-r2, s2-right).
HeroStrikeHigh:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $0A
  JR NZ,HeroStrikeHighEnd
  CALL KeyFire
  JR NZ,HeroStrikeHighEnd
  CALL KeyUp
  JR NZ,HeroStrikeHighEnd
  LD (IY+$08),$00
HeroStrikeHighEnd:
  LD A,(IY+$08)
  CP $0E
  JR NZ,HeroStrikeHighShow
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

; the strike frame table $CABB, its graphics $C7FE
HeroStrikeHighSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; the strike set's frame for each pair of passes of the high strike
HeroStrikeHighFrames:
  DEFB $02,$03,$04,$05,$06,$07,$08

; Start a fall: state 3, speed 2, frame $10, base column - 5
;
; Jumped to from CheckHeroFooting ($AD19), CheckHeroFooting ($AD26).
;
; As in stage 1 at $AF1B, the same code.
;
; Witness: L1 10 (rzx-r2, s2-right, stageload).
StartFall:
  LD (IY+$0A),$03
  LD (IY+$0B),$02
  LD (IY+$08),$10
  LD E,$FB
  CALL MoveBaseX
  RET

; Drop off a ledge missed in a jump: state 3, speed 4, frame $10
;
; Jumped to from CheckHeroFooting ($ACF8).
;
; As in stage 1 at $AF2D, the same code.
;
; Witness: L1 10 (rzx-r2, s2-right).
StartDrop:
  LD (IY+$0A),$03
  LD (IY+$0B),$04
  LD (IY+$08),$10
  RET

; RIGHT while standing: start walking unless a wall is ahead
;
; FrontCellAhead $B10D: a solid cell keeps him standing. Else state 1, frame 0,
; base column + 2, on into HeroWalk $B052.
;
; As in stage 1 at $AF3A, the same instructions.
;
; Witness: L1 231 (rzx-r2, s2-right, stageload).
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
; Jumped to from HeroStand ($AEC9).
;
; As in stage 1 at $AF4F, the same instructions.
;
; Witness: L1 48 (rzx-r2).
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
; A puzzle block ahead ($8329) ends the pass. UP at frame 5 or $0A jumps
; (WalkJumpCheck $B0E2). At frames 2 and 8 GridNumber $FE54 is read and not
; used ($B064, a leftover). At frames 5 and $0B (the feet together) a wall
; ahead (FrontCell $B0F4) stops him with the base column = his column - 1 (+ 1
; facing left; NegateIfFacingLeft $B266), standing; no direction key stops him
; too. RIGHT while facing left, or LEFT while facing right, turns him (HeroTurn
; $B234). The frame goes 0 to $0B; at 0 and 6 the base column moves 2
; (MoveBaseX $B256); then the frame of HeroWalkSet.
;
; As in stage 1 at $AF64 in its job; the wall stop sets the base column (stage
; 1 did not) and the dead read is new.
;
; Witness: L1 1541 (rzx-r2, s2-right, stageload).
HeroWalk:
  CALL CheckWalkBarriers
  RET Z
  CALL WalkJumpCheck
  LD A,(IY+$08)
  CP $02
  JR Z,HeroWalkGridRead
  CP $08
  JR NZ,HeroWalkFeet
HeroWalkGridRead:
  LD A,(GridNumber)            ; LD A,(GridNumber): A is overwritten at once
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
; This entry point is used by the routine at HeroRecoil.
HeroWalkShow:
  LD A,(IY+$08)
  CALL SetActorFrame

; the walk frame table $D1F8 ($0D frames; $0C stands), its graphics $CF2E
HeroWalkSet:
  DEFW HeroWalkFrameTable,HeroWalkSprites

; UP during the walk at frame 5 or $0A: drop the walk and jump
;
; Pops the return address and jumps to StartJump $AF2F.
;
; As in stage 1 at $AFDB, the same code.
;
; Witness: L1 1541 (rzx-r2, s2-right, stageload).
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
; Column + 4 facing right, + 0 facing left (CellAt $B2DC, jumped to). Called by
; HeroWalk $B074.
;
; As in stage 1 at $AFED (the CALL and RET there are a JP here).
;
; Witness: L1 238 (rzx-r2, s2-right, stageload).
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

; A = the cell ahead at his line + 16, column + 3 (+ 1 facing left); NZ when it
; is solid
;
; The test of WalkRight and WalkLeft ($B02A, $B03E). Stage 1's copy ($B007) was
; FrontCell's twin; stage 2's looks one
;
; column nearer (+3, or +1 facing left).
;
; Witness: L1 279 (rzx-r2, s2-right, stageload).
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

; State 3: fall, speeding up to 4 lines a pass, land on solid ground; a fall
; into the pit kills
;
; In grids 1 and 2 (GridNumber $FE54 not 0) a fall below a room's line limit
; (room 0 $69, 1 $79, 5 $32, the others $6C) is fatal: EnergyChange $FE59 =
; $32, a life lost ($7E90) and HeroDeath $B340 with E = $33. Else frames $10 to
; $12 of the jump set: at $10 solid ground under the feet (CellUnderFeet $B282,
; E = 1, D = 2, C = 4) starts the landing (frames $11, $12, then standing at
; frame 6, base column + 5); else the speed +$0B goes up by 2 to 4 and is added
; to the base line.
;
; In s2-right the fall is fatal 3 times (grid 1); none in rzx-r2.
;
; As in stage 1 at $B021 in its job, with the fatal fall added.
;
; Witness: L1 165 (rzx-r2, s2-right, stageload).
HeroFall:
  LD A,(GridNumber)
  CP $00
  JP Z,HeroFallFrame
  LD E,$6C
  LD A,(RoomNumber)
  CP $01
  JP NZ,HeroFallRoom5
  LD E,$79
HeroFallRoom5:
  CP $05
  JP NZ,HeroFallRoom0
  LD E,$32
HeroFallRoom0:
  CP $00
  JP NZ,HeroFallDepth
  LD E,$69
HeroFallDepth:
  LD A,(IY+$01)
  CP E
  JP C,HeroFallFrame
  LD A,$32
  LD (EnergyChange),A
  CALL LoseLife
  LD E,$33
  JP HeroDeath
HeroFallFrame:
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
; Jumped to from HeroUpdate ($AE26).
;
; As in stage 1 at $B06B, the same code.
;
; Witness: L1 441 (rzx-r2).
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
; CheckHeroFooting $ACB7 catches a ledge on the way down. A test of frame $0C
; at $B1D6 leads nowhere (its JR NZ goes to the next instruction).
;
; As in stage 1 at $B087 apart from that test.
;
; Witness: L1 1045 (rzx-r2, s2-right, stageload).
HeroJump:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $09
  JR NZ,HeroJumpFrameC
  LD E,$01
  CALL MoveBaseX
HeroJumpFrameC:
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
; Jumped to from CheckHeroFooting ($ACDB), HeroFall ($B1A5), HeroJump ($B1DF).
;
; As in stage 1 at $B0A9, the same instructions.
;
; Witness: L1 1165 (rzx-r2, s2-right, stageload).
JumpFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; the jump frame table $CEBC ($13 frames), its graphics $CB03
HeroJumpSet:
  DEFW HeroJumpFrameTable,HeroJumpSprites

; State 9: the leap up (DOWN), frames 0 to $0D of the leap set
;
; At frame 8 a ledge under the raised feet (CellUnderFeet $B282, E = 1, D = 2)
; lets him climb: at $0E the base line goes 16 up and he stands; no ledge sinks
; him back (state 4, HeroLeapBack $B1A8).
;
; As in stage 1 at $B0B3, the same code.
;
; Witness: L1 446 (rzx-r2).
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
; Jumped to from HeroLeapBack ($B1C1).
;
; As in stage 1 at $B0E9, the same code.
;
; Witness: L1 789 (rzx-r2).
LeapFrame:
  CALL SetActorFrame

; the leap frame table $EC92, its graphics $E9AC
HeroLeapSet:
  DEFW HeroLeapFrameTable,HeroLeapSprites

; Turn the hero round in the walk: base column by TurnSteps[frame], facing
; flipped
;
; Called by HeroWalk ($B096, $B0A6): 5 turns in rzx-r2.
;
; As in stage 1 at $B0F0, the same code.
;
; Witness: L1 5 (rzx-r2).
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
; Read by HeroTurn: only $B24C, $B24E, $B253, $B255 in the recordings. As in
; stage 1 at $B106.
TurnSteps:
  DEFB $02,$02,$02,$04,$04,$04,$02,$02,$02,$02,$04,$04

  ORG $B340

; Start the hero's death: a burst of eight fragments, the hero hidden, the
; pause
;
; Only when no death is in progress (RespawnShiftX $FE64 = $FF). E = the pause
; in pairs of passes ($33 from HeroFall $B159; LoseLife's $7EBD, $7EC7), stored
; in the hero's +$10 ($74F0). Clears the missile slots 8-15 ($7610-$763F), adds
; eight missiles of type 7 at the hero (column, line + 4) with +4 = 0, 2, .. 14
; (the directions) and +5 = the column x 2 (AddMissileHigh $B3C5), sets state
; $0F ($74EA), takes the respawn point ($8F45: D column, E line), RespawnShiftX
; and RespawnShiftY $FE65 from it, and hides the hero (column 0, line $8C,
; colour 0).
;
; In s2-right 5 deaths, rzx-r2 1.
;
; As in stage 1 at $B22B, the same instructions.
;
; Witness: L1 9 (rzx-r2, s2-right).
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
