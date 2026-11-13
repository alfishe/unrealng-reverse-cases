; --------------------------------------------------------------------------------------------------------------------
; hero.asm: The hero: walk, jump, crouch, strike, fire, the items and the item window
;
; The carried items are two 12-byte lists, CarriedItems $7F17 (the item kind of each slot) and CarriedCounts $7F23
; (its amount), filled from StartItems at the stage's start. Slots 0-5 are padding (slots 0-3 hold the blank icon 4)
; and slot 6 is the first item; ItemFirst..ItemLast are the slots in use and ItemSelected the selected one. The HUD's
; item strip shows the selected slot in the middle and its neighbours (DrawItemStrip, 8 icons drawn, 3 and two halves
; seen through the 12-byte window at $406A); the SPACE item window (ItemWindow) scrolls it.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7C27

; SPACE: stop the game, flash the strip's frame, choose an item with LEFT and
; RIGHT, SPACE again to go on
;
; Clears PassCounter, waits (cycling the frame colours, CycleWindowFrame) for
; SPACE's release, then every 6 frames: DrawItemStrip and ShowItemCount; RIGHT
; scrolls to the previous slot (ScrollItemsRight), LEFT to the next
; (ScrollItemsLeft); SPACE again: waits for its release, cycles the frame back
; to its first colour and flashes the selected box (FlashSelectedBox).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code. The HUD's strip itself is drawn in every
; recording (c1 frame 15982).
ItemWindow:
  XOR A
  LD (PassCounter),A
  HALT
  CALL CycleWindowFrame
  CALL TestSpaceKey
  JP Z,ItemWindow
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
; (column 15, line 24, 2 x 2 cells) and fills it with $8C3D. Called by
; ItemWindow and at the stage's start ($981B).
;
; Witness: L1 2 (s1-idle, s1-right).
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

; $8C3D's inline record: column 15, line 24, 2 x 2 cells, the colour (patched)
SelectedBoxRecord:
  DEFB $0F,$18,$02,$02,$00

; FlashSelectedBox, continued
;
; Part of FlashSelectedBox, after its inline record.
;
; Witness: L1 10 (s1-idle, s1-right).
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
; (ShowItemStrip). Also run three times at the stage's start ($97FF, with the
; frame cycle patched off) to roll the strip in.
;
; Witness: L1 6 (s1-idle, s1-right).
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
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; stage's start ($97FA) patches to RET while it rolls the strip in, and back.
;
; Witness: L1 144 (s1-idle, s1-right). In the stage-1 recordings only the
; patched RET ran (the item window was never opened).
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
WindowFrameColours:
  DEFB $01,$02,$03,$04,$05,$06,$07,$07
  DEFB $07,$07,$06,$05,$04,$03,$02,$01

; When ItemsChanged is set: clear it and redraw the strip and the count
;
; Every pass. ItemsChanged is set by AddItem.
;
; Witness: L1 10189 (c1o, deaths, s1-idle, s1-right).
RedrawItemsIfChanged:
  LD A,(ItemsChanged)
  CP $01
  RET NZ
  XOR A
  LD (ItemsChanged),A
  CALL DrawItemStrip
  JP ShowItemCount

; Draw the icons of slots ItemSelected-3 to +4 into the buffer and show them
;
; For 8 slots from CarriedItems + ItemSelected - 3: DrawItemIcon at $5B64 + 3 x
; n, then ShowItemStrip.
;
; Witness: L1 6 (s1-idle, s1-right).
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
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
ItemCountText:
  DEFB $00,$00,$30,$30,$00

  ORG $7E19

; Draw item icon A (16 lines of 2 bytes, a blank third byte) into the buffer at
; HL
;
; HL = the buffer address (stride 32), A = the item kind; the icon's address is
; ItemIcons[A]. Destroys BC, DE.
;
; Witness: L1 48 (s1-idle, s1-right).
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
  XOR A
  LD (HL),A
  LD BC,$001E
  ADD HL,BC
  POP BC
  DJNZ DrawItemIconLine
  RET

; Copy the strip's 12 x 16 window from the buffer ($5B68) to the screen ($406A)
;
; Two calls of CopyStripRows: the first 8 lines to $406A (row 3, column 10),
; the next 8 to $408A.
;
; Witness: L1 150 (s1-idle, s1-right).
ShowItemStrip:
  LD HL,PlayBuffer+104
  LD DE,Screen+106
  CALL CopyStripRows
  LD DE,Screen+138
  JP CopyStripRows

; Copy 8 lines of 12 bytes from the buffer (stride 32) to one character row of
; the screen at DE
;
; HL = the buffer (left after the call at the next 8 lines), DE = the screen
; address.
;
; Witness: L1 300 (s1-idle, s1-right).
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
; A = the item kind, D = the amount. Item 7 also writes 5 into $9B84 (a byte of
; the room data). If A is already in CarriedItems (any of the 12 slots, the
; padding too), its count goes up by D, at most 99; else ItemLast + 1 and the
; new slot gets A and D. Sets ItemsChanged. Called by $8B03 and $A10E (the
; pick-ups).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
AddItem:
  PUSH AF
  CP $07
  JR NZ,AddItemFind
  LD HL,Grid0Rooms+$000C
  LD (HL),$05
AddItemFind:
  LD HL,CarriedItems
  LD B,$0C
AddItemFindNext:
  CP (HL)
  JR Z,AddItemMore
  INC HL
  DJNZ AddItemFindNext
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

  ORG $7F05

; A = the selected item's kind, IX = the address of its count
;
; A = CarriedItems[ItemSelected], IX = CarriedCounts + ItemSelected. BC
; destroyed.
;
; Witness: L1 37505 (c1o, deaths, s1-idle, s1-right).
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
CarriedItems:
  DEFB $04,$04,$04,$04,$00,$00,$03,$00,$00,$00,$00,$00

; The amount of each slot's item (shown by ShowItemCount; AddItem adds)
CarriedCounts:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The carried items at the stage's start, copied to CarriedItems by $9DA1: slot
; 6 holds item 3
StartItems:
  INCBIN "res/stage1/table-startitems.bin",$0000,12

; The 16 x 16 icon of each item kind 0-8 (32 bytes each; kind 4 points to the
; blank $8BA3)
ItemIcons:
  INCBIN "res/stage1/table-itemicons.bin",$0000,18
  ASSERT {ItemIcons} == ItemIconKind0
  ASSERT {ItemIcons+2} == ItemIconKind1
  ASSERT {ItemIcons+4} == ItemIconSprites
  ASSERT {ItemIcons+6} == ItemIconKind3
  ASSERT {ItemIcons+8} == BlankIcon
  ASSERT {ItemIcons+10} == ItemIconKind5
  ASSERT {ItemIcons+12} == ItemIconKind6
  ASSERT {ItemIcons+14} == ItemIconKind7
  ASSERT {ItemIcons+16} == ItemIconKind8

  ORG $7FEE

; Z (and C clear) when the hero is in state 7 at frame 4, the frame its attack
; hits
;
; Reads the hero's state $74EA and frame $74E8. Called by $A7C4 for each enemy.
;
; Witness: L1 20131 (c1o, deaths, s1-idle, s1-right).
IsHeroHitFrame7:
  LD A,(HeroState)
  CP $07
  RET NZ
  LD A,(HeroFrame)
  CP $04
  RET

; Z when the hero is in state 6 at frame 4
;
; As IsHeroHitFrame7 for state 6. Called by $9676.
;
; Witness: L1 26 (c1o, s1-right).
IsHeroHitFrame6:
  LD A,(HeroState)
  CP $06
  RET NZ
  LD A,(HeroFrame)
  CP $04
  RET

  ORG $819A

; While walking: thrown back from a closed exit (rooms 12 and 7 of grid 0, the
; room of grid 2)
;
; IY = the hero. CheckRightGate, CheckLeftGate and CheckItemGate each return Z
; for a closed exit; on Z the hero goes to state $0B (HeroRecoil, +$0B = $FF)
; and Z is returned (the walk handler $AF64 stops). NZ: free.
;
; Witness: L1 875 (c1o, deaths, s1-right).
CheckWalkBarriers:
  CALL CheckRightGate
  JR Z,WalkBarrierHit
  CALL CheckLeftGate
  JR Z,WalkBarrierHit
  CALL CheckItemGate
  JP Z,WalkBarrierHit
  RET
WalkBarrierHit:
  LD (IY+$0B),$FF
  LD (IY+$0A),$0B
  CALL HeroRecoil
  JP ReturnZ

; Grid 0 room 12, facing right at x $1C: open while BossPhase is 1, or 4 with
; item 7 carried
;
; Returns NZ (open) outside that room, facing left, at another x; Z (closed)
; for other states.
;
; Witness: L1 875 (c1o, deaths, s1-right).
CheckRightGate:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(RoomNumber)
  CP $0C
  RET NZ
  BIT 7,(IY+$09)
  RET NZ
  LD A,(IY+$0D)
  CP $1C
  RET NZ
  LD A,(BossPhase)
  CP $01
  JP Z,ReturnNZ
  CP $04
  JP NZ,ReturnZ
  LD HL,CarriedItems
  LD B,$0C
CheckRightGateItem:
  LD A,(HL)
  CP $07
  JP Z,ReturnNZ
  INC HL
  DJNZ CheckRightGateItem
  JP ReturnZ

; Grid 0 room 7, facing left at x 5: closed while GateOpen is 0
;
; Witness: L1 875 (c1o, deaths, s1-right).
CheckLeftGate:
  LD A,(GridNumber)
  CP $00
  RET NZ
  LD A,(RoomNumber)
  CP $07
  RET NZ
  LD A,(GateOpen)
  CP $00
  RET NZ
  LD A,(HeroFlags)
  BIT 7,A
  JP Z,ReturnNZ
  LD A,(HeroRecord)
  CP $05
  RET

; Grid 2, facing left at x 2: closed unless item 2 is carried
;
; Witness: L1 875 (c1o, deaths, s1-right).
CheckItemGate:
  LD A,(GridNumber)
  CP $02
  RET NZ
  LD A,(HeroFlags)
  BIT 7,A
  JP Z,ReturnNZ
  LD A,(HeroRecord)
  CP $02
  RET NZ
  LD HL,CarriedItems
  LD B,$0C
CheckItemGateNext:
  LD A,(HL)
  CP $02
  JP Z,ReturnNZ
  INC HL
  DJNZ CheckItemGateNext
  JP ReturnZ

  ORG $86DD

; NZ when item 1 is selected and its count is not 0 (the shield); Z otherwise
;
; GetSelectedItem; not item 1: Z via $B2DC. Callers: $8DE7, $96A4.
;
; Witness: L1 9 (c1o, deaths, s1-right).
IsShieldUp:
  CALL GetSelectedItem
  CP $01
  JP NZ,ReturnZ
  LD A,(IX+$00)
  CP $00
  RET

  ORG $871A

; State $0B: the hero thrown back from a closed exit, a 6-step hop, then
; standing
;
; +$0B counts 0-6: y += RecoilSteps[+$0B], x back one pixel step ($8B4E with 3:
; +$11 down, the column on wrap) and the walk frame drawn ($AFD1). At 7: state
; 0, x - 1 column ($B112 E = $FF), +$11 = 0, standing ($ADDD).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
RecoilSteps:
  DEFB $FB,$FF,$00,$00,$01,$02,$03

; A leftover no code calls: Z unless bit 1 of the room cell at (column E, line
; D) is set
;
; HL = $7282 + (D / 8) x 32 + E, then BIT 1,(HL). No caller in the image.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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

  ORG $89A1

; Use up the protective item's charge while it is selected
;
; Called by the hero's pass at $AC3D. When the selected item (GetSelectedItem
; $7F05) is of kind 1 (the kind
;
; DamageHero's guard $86DD lets protect the hero) and its count IX is non-zero,
; takes one away every 8th pass
;
; (PassCounter) and redraws the HUD's item (JP $7D5E). The kind-1 branch never
; ran in the stage-1 recordings.
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
DrainItemCharge:
  CALL GetSelectedItem
  CP $01
  RET NZ
  LD A,(IX+$00)
  CP $00
  RET Z
  LD A,(PassCounter)
  AND $07
  JR NZ,DrainItemDone
  DEC (IX+$00)
  JP ShowItemCount
DrainItemDone:
  RET

  ORG $9259

; The hero's wait after a death; then he comes back at the room's respawn point
;
; IY = the hero. Every 2nd pass +$10 - 1; at 0: state 0, position (+$0D, +$0E)
; = RespawnPoint, flags 0,
;
; RespawnShiftX = $FF, the standing frame (JP $ADDD). Reached from $AC91.
;
; Witness: L1 797 (c1o, deaths, s1-right).
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
; Witness: L1 13 (c1o, deaths, s1-right).
RespawnPoint:
  LD HL,RespawnPoints
  LD A,(GridNumber)
  CP $00
  JR Z,RespawnPointRead
  LD HL,RespawnPointsShaft
  CP $01
  JR Z,RespawnPointRead
  LD HL,RespawnPointsArena
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

; Column, line of each room: grid 0 (18 rooms), grid 1 (3) at $92C1, grid 2 (1)
; at $92C7
RespawnPoints:
  DEFB $12,$41,$14,$41,$14,$31,$14,$31
  DEFB $0A,$41,$0A,$41,$0E,$31,$0E,$21
  DEFB $0E,$31,$0E,$21,$0E,$31,$08,$31
  DEFB $16,$31,$0E,$31,$0E,$31,$0E,$31
  DEFB $0E,$31,$08,$31
RespawnPointsShaft:
  DEFB $0E,$31,$0E,$31,$0E,$41 ; grid 1
RespawnPointsArena:
  DEFB $04,$31            ; grid 2

  ORG $92D1

; Throw the selected item when the fire key is pressed (one throw a press)
;
; Reached from $AC89. FireLatch makes it one throw a press. Unless the hero's
; state is $0F: takes one of the selected
;
; item's count (none left: nothing), redraws it ($7D5E), plays effect 8 and
; launches a shot from the hero's hands
;
; ($B296: D = the column (one less facing left), E = the line + 8 rounded to a
; cell, B = the direction, C = 9).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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

  ORG $AA3E

; Per-pass handler of the hero's record ($74E0): move, fall, leave the room,
; change grid
;
; The handler word of the hero's template ($9D3B), called first in each pass of
; UpdateActors $A5BD with IY =
;
; $74E0. HeroUpdate $AC3D (controls and states), CheckHeroFooting $AA67 (ledges
; and falls), CheckRoomExits $AADA
;
; with IX = RoomExitsPtr $FE2E, CheckGridPassages $AB1C, then RoomExitsPtr =
; the grid record's word +4 +
;
; RoomNumber $FE30 (the room may have changed).
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
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
; one column ahead (CellUnderFeet
;
; $B134, E = 1, D = 2) lands him on the ledge: frame $0F, the base column 2
; back, the base line 16 up ($92C9), on
;
; into the jump's frame (JumpFrame $B0A9); at frame $0F with no ground there he
; drops (StartDrop $AF2D). Standing
;
; (state 0) or walking (state 1) at frame 5 or $0B with no ground under him (E
; = 2, D = 0) starts a fall (StartFall
;
; $AF1B).
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
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
  LD E,$02
  LD D,$00
  LD C,$07
  CALL CellUnderFeet
  JP Z,StartFall
  RET

  ORG $AC3D

; The hero's pass: items, hazards, weapons, colour, then his state's handler
;
; IY = the hero. Item 1 drains ($89A1). A deadly cell (bit 3) under him at his
; column + 4 (facing right) or his
;
; column (left) and his line, or his column 0 or 32 and up, costs a life
; (LoseLife $7ECE) unless he is dying (state
;
; $0F). Then, not dying: the selected item's kind ($7F05) fires its weapon: 7
; FireBolt $AD14, 5 ThrowAmmo $AD4B, 8
;
; $92D1. Dying: the death pause ($9259). Then the colour (HeroColour $ACD9),
; and while HeroFreeze $FE58 counts down
;
; the controls are ignored. Else by the state +$0A: 0 HeroStand $ADA2, 1
; HeroWalk $AF64, 2 HeroJump $B087, 3
;
; HeroFall $B021, 4 HeroLeapBack $B06B, 5 HeroStrikeMid $AE8E, 6 HeroStrikeHigh
; $AED4, 7 HeroStrikeLow $AE5D, 9
;
; HeroLeap $B0B3, $0B the scripted move $871A.
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
HeroUpdate:
  CALL DrainItemCharge
  LD A,(HeroRecord)
  CP $00
  JR Z,HeroUpdateDeath
  CP $20
  JR NC,HeroUpdateDeath
  LD A,(IY+$00)
  ADD A,$04
  BIT 7,(IY+$09)
  JP Z,HeroUpdateHazard
  SUB $04
HeroUpdateHazard:
  LD E,A
  LD D,(IY+$01)
  CALL CellAt
  BIT 3,A
  JP Z,HeroUpdateWeapons
HeroUpdateDeath:
  LD A,(IY+$0A)
  CP $0F
  JR Z,HeroUpdateWeapons
  CALL LoseLife
HeroUpdateWeapons:
  LD A,(IY+$0A)
  CP $0F
  JR Z,HeroUpdateState
  CALL GetSelectedItem
  PUSH AF
  CP $07
  CALL Z,FireBolt
  POP AF
  PUSH AF
  CP $05
  CALL Z,ThrowAmmo
  POP AF
  CP $08
  CALL Z,ThrowItem
HeroUpdateState:
  LD A,(IY+$0A)
  CP $0F
  JP Z,RespawnCountdown
  CALL HeroColour
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

; Set the hero's colour: flashing when weak or shielded
;
; IY = the hero, +$0C his colour. Energy $FE3F under $0E: the colour cycle of
; CycleColour $B3C4. Else item kind 1
;
; selected with a count: white and blue on alternate passes. Else +$0C rises
; one a pass up to 7 (white).
;
; Witness: L1 9393 (c1o, deaths, s1-idle, s1-right).
HeroColour:
  LD A,(Energy)
  CP $0E
  JR NC,HeroColourShield
  CALL CycleColour
  AND $07
  LD (IY+$0C),A
  RET
HeroColourShield:
  CALL GetSelectedItem
  CP $01
  JR NZ,HeroColourNormal
  LD A,(IX+$00)
  CP $00
  JP Z,HeroColourNormal
  LD (IY+$0C),$07
  LD A,(PassCounter)
  AND $01
  RET Z
  LD (IY+$0C),$01
  RET
HeroColourNormal:
  LD A,(IY+$0C)
  CP $07
  JR Z,HeroColourDone
  INC A
  LD (IY+$0C),A
  RET
HeroColourDone:
  RET

; Item kind 7: a bolt for each press of FIRE (no count)
;
; FIRE edge-triggered through FireLatch $FE50. Adds a missile of kind 6 at the
; hero's column (one left when facing
;
; left) and line + 4, its +5 = 0 (right) or 1 (left) (AddMissile $B28D), and
; plays effect $0B. Runs in every state
;
; but the death.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
FireBolt:
  LD A,(FireLatch)
  CP $00
  JR Z,FireBoltPress
  CALL KeyFire
  RET Z
  XOR A
  LD (FireLatch),A
  RET
FireBoltPress:
  CALL KeyFire
  RET NZ
  LD A,$01
  LD (FireLatch),A
  LD D,(IY+$00)
  LD A,(IY+$01)
  ADD A,$04
  LD E,A
  LD C,$06
  XOR A
  BIT 7,(IY+$09)
  JR Z,FireBoltAdd
  LD A,$01
  DEC D
FireBoltAdd:
  CALL AddMissile
  LD DE,$000B
  JP PlaySoundVector

; Item kind 5: throw one of the counted items, standing only
;
; FIRE edge-triggered (FireLatch $FE50). With a count left ($7F05's IX), the
; count goes down and the HUD's count is
;
; printed again ($7D5E); standing (state 0) it adds a missile of kind 2 (facing
; left) or 3 (right) at line - 2,
;
; +4 = $FF, +5 = 1, and plays effect $0B.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
ThrowAmmo:
  LD A,(FireLatch)
  CP $00
  JR Z,ThrowAmmoPress
  CALL KeyFire
  RET Z
  XOR A
  LD (FireLatch),A
  RET
ThrowAmmoPress:
  CALL KeyFire
  RET NZ
  LD A,$01
  LD (FireLatch),A
  CALL GetSelectedItem
  LD A,(IX+$00)
  CP $00
  RET Z
  DEC (IX+$00)
  CALL ShowItemCount
  LD A,(IY+$01)
  SUB $02
  LD E,A
  LD B,$00
  LD A,(IY+$0A)
  CP $00
  RET NZ
  LD A,(IY+$00)
  SUB B
  LD D,A
  LD C,$02
  BIT 7,(IY+$09)
  JR NZ,ThrowAmmoAdd
  INC C
  LD A,(IY+$00)
  ADD A,B
  DEC A
  LD D,A
ThrowAmmoAdd:
  LD A,$01
  LD B,$FF
  CALL AddMissile
  LD DE,$000B
  JP PlaySoundVector

; State 0: read the controls
;
; IY = the hero. FIRE: HeroFireHeld $ADE9. DOWN: the leap (StartLeap $AE4D).
; UP: the jump (StartJump $AE3D). RIGHT:
;
; walk right (WalkRight $AF3A), first turning (base column + 4, facing right)
; when facing left; LEFT the same to the
;
; left (WalkLeft $AF4F). No key: the standing frame (HeroStandFrame $ADDD). The
; key readers are the resident's
;
; KeyUp $FC90 to KeyFire $FCCC (Z = held): the order UP, DOWN, LEFT, RIGHT,
; FIRE is that of the front part's
;
; joystick set-up ($9834 Kempston bits 3, 2, 1, 0, 4; $986A Sinclair keys 9, 8,
; 6, 7, 0).
;
; Witness: L1 8194 (c1o, deaths, s1-idle, s1-right).
HeroStand:
  CALL KeyFire
  JP Z,HeroFireHeld
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
; Frame $0C of HeroWalkSet. Also jumped to by the other states when they end,
; by $8731, $9279 (the end of the death
;
; pause) and $A48B.
;
; Witness: L1 71 (c1o, deaths, s1-idle, s1-right).
HeroStandFrame:
  LD A,$0C
  LD (IY+$08),A
  CALL SetActorFrame

; SetActorFrame's parameters: the walk frame table, its graphics
HeroStandSet:
  DEFW HeroWalkFrameTable,HeroWalkSprites

; FIRE held while standing: a strike with a hand weapon
;
; Only with the selected item's kind 6, 5 or 3 ($7F05): DOWN the low strike
; (state 7, HeroStrikeLow $AE5D), UP the
;
; high strike (state 6, HeroStrikeHigh $AED4), LEFT the middle strike (state 5,
; HeroStrikeMid $AE8E); each starts at
;
; frame $FF with the base column + 1.
;
; Witness: L1 115 (c1o, s1-right).
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
  JP HeroStrikeLow
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
  LD (IY+$10),$00
  LD E,$01
  CALL MoveBaseX
  JP HeroStrikeMid
HeroFireHeldNone:
  RET
HeroFireHeldNoWeapon:
  RET

; Start the jump: state 2, base column + 2
;
; Also entered from the walk (WalkJumpCheck $AFDB).
;
; Witness: L1 8 (s1-right).
StartJump:
  LD E,$02
  CALL MoveBaseX
  LD (IY+$0A),$02
  LD (IY+$08),$FF
  JP HeroJump

; Start the leap (DOWN): state 9, base column + 1
;
; Witness: L1 1 (c1o).
StartLeap:
  LD E,$01
  CALL MoveBaseX
  LD (IY+$0A),$09
  LD (IY+$08),$FF
  JP HeroLeap

; State 7: the low strike, 8 passes
;
; Frames 4, 4, 5, 5, 5, 5, 4, 4 of the strike set (HeroStrikeLowFrames); at the
; end back to standing (base column -
;
; 1). Frame 4 of the state is the hit ($7FEE, StrikeableActor $A7C4).
;
; Witness: L1 9 (c1o).
HeroStrikeLow:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $08
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
  ADD A,$04
  CALL SetActorFrame

; the strike frame table, its graphics
HeroStrikeLowSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; the strike set's frame for each pass of the low strike
HeroStrikeLowFrames:
  DEFB $00,$00,$01,$01,$01,$01,$00,$00

; State 5: the middle strike, 10 passes; held at pass 6 while LEFT is held
;
; Frames 6, 6, 7, 7, 8, 8, 7, 7, 6, 6 of the strike set (HeroStrikeMidFrames);
; +$10 counts its passes.
;
; Witness: L1 11 (c1o).
HeroStrikeMid:
  INC (IY+$08)
  INC (IY+$10)
  LD A,(IY+$08)
  CP $06
  JR NZ,HeroStrikeMidEnd
  CALL KeyLeft
  JR NZ,HeroStrikeMidEnd
  LD (IY+$08),$05
HeroStrikeMidEnd:
  LD A,(IY+$08)
  CP $0A
  JR NZ,HeroStrikeMidShow
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

; the strike frame table, its graphics
HeroStrikeMidSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; the strike set's frame (less 6) for each pass of the middle strike
HeroStrikeMidFrames:
  DEFB $00,$00,$01,$01,$02,$02,$01,$01,$00,$00

; State 6: the high strike, 9 passes; held while FIRE and UP are held
;
; Frames 0, 1, 2, ..., 2, 1, 0 of the strike set (HeroStrikeHighFrames, by the
; pass / 2). Frame 4 of the state is
;
; the high hit ($7FFA).
;
; Witness: L1 47 (c1o, s1-right).
HeroStrikeHigh:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $0A
  JR NZ,HeroStrikeHighEnd
  CALL KeyFire
  JR NZ,HeroStrikeHighEnd
  CALL KeyUp
  JR NZ,HeroStrikeHighEnd
  LD (IY+$08),$01
HeroStrikeHighEnd:
  LD A,(IY+$08)
  CP $0A
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

; the strike frame table, its graphics
HeroStrikeHighSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; the strike set's frame for each pair of passes of the high strike
HeroStrikeHighFrames:
  DEFB $00,$01,$02,$02,$02,$02,$02,$02,$02,$01,$00

; Start a fall: state 3, speed 2, frame $10, base column - 5
;
; Witness: L1 8 (c1o, deaths, s1-right).
StartFall:
  LD (IY+$0A),$03
  LD (IY+$0B),$02
  LD (IY+$08),$10
  LD E,$FB
  CALL MoveBaseX
  RET

; Drop off a ledge missed in a jump: state 3, speed 4, frame $10
;
; Witness: L1 1 (s1-right).
StartDrop:
  LD (IY+$0A),$03
  LD (IY+$0B),$04
  LD (IY+$08),$10
  RET

; RIGHT while standing: start walking unless a wall is ahead
;
; FrontCellAhead $B007: a solid cell keeps him standing. Else state 1, frame 0,
; base column + 2.
;
; Witness: L1 126 (c1o, deaths, s1-right).
WalkRight:
  CALL FrontCellAhead
  RET NZ
  LD (IY+$08),$00
  LD (IY+$0A),$01
  INC (IY+$0D)
  INC (IY+$0D)
  JP HeroWalk

; LEFT while standing: start walking unless a wall is ahead (base column - 2)
;
; Witness: L1 18 (c1o, deaths).
WalkLeft:
  CALL FrontCellAhead
  RET NZ
  LD (IY+$08),$00
  LD (IY+$0A),$01
  DEC (IY+$0D)
  DEC (IY+$0D)
  JP HeroWalk

; State 1: walk, 12 frames a cycle, 2 columns each half
;
; A puzzle block ahead ($819A) ends the pass. UP at frame 5 or $0A jumps
; (WalkJumpCheck $AFDB). At frames 5 and $0B
;
; (the feet together) a wall ahead (FrontCell $AFED) or no direction key stops
; him (state 0, standing frame). RIGHT
;
; while facing left, or LEFT while facing right, turns him (HeroTurn $B0F0).
; The frame goes 0 to $0B; at 0 and 6 the
;
; base column moves 2 (B = MoveBaseX $B112); then the frame of HeroWalkSet.
;
; Witness: L1 875 (c1o, deaths, s1-right).
HeroWalk:
  CALL CheckWalkBarriers
  RET Z
  CALL WalkJumpCheck
  LD A,(IY+$08)
  CP $05
  JR Z,HeroWalkWall
  CP $0B
  JR NZ,HeroWalkRight
  LD A,$FF
HeroWalkWall:
  CALL FrontCell
  JR Z,HeroWalkRight
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
  XOR A
HeroWalkFrame:
  LD (IY+$08),A
  CP $06
  JP NZ,HeroWalkShow
  LD E,$02
  CALL MoveBaseX
; This entry point is used by the routine at HeroRecoil.
HeroWalkShow:
  LD A,(IY+$08)
  CALL SetActorFrame

; the walk frame table ($0D frames; $0C stands), its graphics
HeroWalkSet:
  DEFW HeroWalkFrameTable,HeroWalkSprites

; UP during the walk at frame 5 or $0A: drop the walk and jump
;
; Pops the return address and jumps to StartJump $AE3D.
;
; Witness: L1 875 (c1o, deaths, s1-right).
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
; Column + 4 facing right, + 0 facing left (CellAt $B162).
;
; Witness: L1 139 (c1o, deaths, s1-right).
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
  CALL CellAt
  RET

; The same test as FrontCell $AFED (a second copy of the code)
;
; Witness: L1 144 (c1o, deaths, s1-right).
FrontCellAhead:
  LD A,(IY+$00)
  ADD A,$04
  LD E,A
  BIT 7,(IY+$09)
  JR Z,FrontCellAheadLine
  LD A,E
  SUB $04
  LD E,A
FrontCellAheadLine:
  LD A,(IY+$01)
  ADD A,$10
  LD D,A
  CALL CellAt
  RET

; State 3: fall, speeding up to 4 lines a pass, land on solid ground
;
; Frames $10 to $12 of the jump set. At frame $10: solid ground under the feet
; (CellUnderFeet $B134, E = 2, D = 0)
;
; starts the landing (frames $11, $12, then standing at frame 6, base column +
; 5); else the speed +$0B goes up by 2
;
; to 4 and is added to the base line.
;
; Witness: L1 83 (c1o, deaths, s1-right).
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
  LD E,$02
  LD D,$00
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
; Witness: L1 9 (c1o).
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
; CheckHeroFooting $AA67 catches a ledge on
;
; the way down.
;
; Witness: L1 105 (s1-right).
HeroJump:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $09
  JR NZ,HeroJumpEnd
  LD E,$01
  CALL MoveBaseX
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
; Witness: L1 179 (c1o, deaths, s1-right).
JumpFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; the jump frame table ($13 frames), its graphics
HeroJumpSet:
  DEFW HeroJumpFrameTable,HeroJumpSprites

; State 9: the leap up (DOWN), frames 0 to $0D of the leap set
;
; The frames crouch and spring up (their line offsets fall from 46 to 25). At
; frame 8 a ledge under the raised feet
;
; (CellUnderFeet $B134, E = 1, D = 2) lets him climb: at $0E the base line goes
; 16 up and he stands; no ledge sinks
;
; him back (state 4, HeroLeapBack $B06B).
;
; Witness: L1 9 (c1o).
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
; Witness: L1 16 (c1o).
LeapFrame:
  CALL SetActorFrame

; the leap frame table ($0E frames), its graphics
HeroLeapSet:
  DEFW HeroLeapFrameTable,HeroLeapSprites

; Turn the hero round in the walk: base column by TurnSteps[frame], facing
; flipped
;
; Witness: L1 2 (c1o).
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
TurnSteps:
  DEFB $02,$02,$02,$04,$04,$04,$02,$02,$02,$02,$04,$04

  ORG $B22B

; Start the hero's death: a burst of eight fragments, the hero hidden, the
; pause
;
; Only when no death is in progress (RespawnShiftX $FE56 = $FF). E = the pause
; in pairs of passes ($33 after a life, $6C
;
; after the last; from LoseLife $7ECE), stored in the hero's +$10 ($74F0).
; Clears the effects 8-15 ($7610-$763F),
;
; adds eight effects of type 7 at the hero (column, line + 4) with +4 = 0, 2,
; .. 14 (the directions) and +5 = the
;
; column x 2 (AddMissileHigh $B296), sets state $0F ($74EA), takes the respawn
; point ($927C: D column, E line),
;
; RespawnShiftX and RespawnShiftY $FE57 from it, and hides the hero (column 0,
; line $8C, colour 0).
;
; Witness: L1 7 (c1o, deaths, s1-right).
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
  XOR A
  LD (HeroRecord),A
  LD (HeroBaseX),A
  LD A,$8C
  LD (HeroY),A
  LD (HeroBaseY),A
  XOR A
  LD (HeroAttribute),A
  RET
