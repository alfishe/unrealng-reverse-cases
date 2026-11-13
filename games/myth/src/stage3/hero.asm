; --------------------------------------------------------------------------------------------------------------------
; hero.asm: The hero: walk, jump, leap, strike with the hammer, throw, the items and the item window
; --------------------------------------------------------------------------------------------------------------------

  ORG $7C15

; SPACE: stop the game, flash the strip's frame, choose an item with LEFT and
; RIGHT, SPACE again to go on
;
; Clears PassCounter, waits (cycling the frame colours, CycleWindowFrame) for
; SPACE's release, then every 6 frames: DrawItemStrip and ShowItemCount; RIGHT
; scrolls to the previous slot (ScrollItemsRight), LEFT to the next
; (ScrollItemsLeft); SPACE again: waits for its release, cycles the frame back
; to its first colour and flashes the selected box (FlashSelectedBox).
;
; The HUD's strip itself is drawn in every recording (c1 frame 15982).
;
; Stage 1's ItemWindow at $7C27 is the same code.
;
; Witness: L1 172 (rzx-r3).
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
; (column 15, line 24, 2 x 2 cells) and fills it with $8ADE. Called by
; ItemWindow and at the stage's start (StageSetUp at $977C).
;
; Stage 1's FlashSelectedBox at $7C6E is the same code.
;
; Witness: L1 18 (rzx-r3, s3-right).
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
; Stage 1's FlashSelectedBoxNext at $7C80 is the same code.
;
; Witness: L1 90 (rzx-r3, s3-right).
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
; (ShowItemStrip). Also run three times at the stage's start (StageSetUp at
; $9763, $9769 and $976F, with the frame cycle patched off) to roll the strip
; in.
;
; Stage 1's ScrollItemsLeft at $7C85 is the same code.
;
; Witness: L1 32 (rzx-r3, s3-right).
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
; Stage 1's ScrollItemsRight at $7CB9 is the same code.
;
; Witness: L1 17 (rzx-r3).
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
; stage's start (StageSetUp at $975D, back at $9773) patches to RET while it
; rolls the strip in, and back.
;
; In the stage-1 recordings only the patched RET ran (the item window was never
; opened).
;
; Stage 1's CycleWindowFrame at $7CED is the same code.
;
; Witness: L1 1967 (rzx-r3, s3-right).
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
; Stage 1's WindowFrameColours at $7D16 (found through the operands of the
; matched routines); the size and shape given here are stage 3's, from its
; bytes and readers.
WindowFrameColours:
  DEFB $01,$02,$03,$04,$05,$06,$07,$07
  DEFB $07,$07,$06,$05,$04,$03,$02,$01

; When ItemsChanged is set: clear it and redraw the strip and the count
;
; Every pass. ItemsChanged is set by AddItem.
;
; Stage 1's RedrawItemsIfChanged at $7D26 is the same code.
;
; Witness: L1 6279 (rzx-r3, s3-right).
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
; Stage 1's DrawItemStrip at $7D36 is the same code.
;
; Witness: L1 637 (rzx-r3, s3-right).
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
; Stage 1's ShowItemCount at $7D5E is the same code.
;
; Witness: L1 710 (rzx-r3).
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
; Stage 1's FormatItemCount at $7DA0 is the same code.
;
; Witness: L1 710 (rzx-r3).
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
; Stage 1's ItemCountText at $7DC8 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
ItemCountText:
  DEFB $00,$00,$30,$30,$00

  ORG $7E07

; Draw item icon A (16 lines of 2 bytes, a blank third byte) into the buffer at
; HL
;
; HL = the buffer address (stride 32), A = the item kind; the icon's address is
; ItemIcons[A]. Destroys BC, DE.
;
; Stage 1's DrawItemIcon at $7E19 is the same code.
;
; Witness: L1 5096 (rzx-r3, s3-right).
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
; Stage 1's ShowItemStrip at $7E3D is the same code.
;
; Witness: L1 1717 (rzx-r3, s3-right).
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
; Stage 1's CopyStripRows at $7E4C is the same code.
;
; Witness: L1 3434 (rzx-r3, s3-right).
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

; Add D of item kind A to the carried items: to its slot if carried, else to a
; new slot after ItemLast
;
; Searches the 17 slots of CarriedItems for kind A: found, CarriedCounts of
; that slot + D, at most 99 ($63). Not found: ItemLast + 1, the kind into that
; slot and D into its count. Both ways ItemsChanged = 1 (the main loop redraws
; the strip). Called by ItemHandler $A131 when the hero takes an item (13 times
; in the recordings). Stage 1's AddItem ($7E5F) searches 12 slots; here B = $11
; and the count lies 17 bytes on.
;
; Witness: L1 13 (rzx-r3).
AddItem:
  PUSH AF
  LD HL,CarriedItems
  LD B,$11
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
  POP AF                  ; the kind is carried: its count + D, at most 99
  LD BC,$0011
  ADD HL,BC
  LD A,(HL)
  ADD A,D
  CP $64
  JR C,AddItemStore
  LD A,$63
AddItemStore:
  LD (HL),A
  JR AddItemDone

  ORG $7EEA

; A = the selected item's kind, IX = the address of its count
;
; A = CarriedItems[ItemSelected], IX = CarriedCounts + ItemSelected. BC
; destroyed.
;
; Stage 1's GetSelectedItem at $7F05 is the same code.
;
; Witness: L1 22067 (rzx-r3, s3-right).
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

; The item kind of each of the 17 slots (slots 0-3 hold 4, the blank icon; the
; first item at slot 6)
;
; Filled from StartItems by InitStageState; AddItem `$7E4D` searches and
; extends it; DrawItemStrip and GetSelectedItem read it.
;
; Stage 1's CarriedItems at $7F17 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
CarriedItems:
  DEFB $04,$04,$04,$04,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The amount of each slot's item (shown by ShowItemCount; AddItem adds)
;
; Stage 1's CarriedCounts at $7F23 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
CarriedCounts:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The kinds InitStageState copies into CarriedItems at the stage start
;
; 4 4 4 4 0 0 3 0 ... 0: slots 0-3 the blank kind 4, slot 6 kind 3 (the first
; item, where ItemSelected starts). Read by InitStageState $9D00 (LD HL,$7F1E:
; 17 bytes to CarriedItems). Stage 1's StartItems at $7F2F has 12 bytes.
StartItems:
  INCBIN "res/stage3/table-startitems.bin",$0000,17

; The 2 x 16 icon of each item kind 0-9 (10 words into ItemIconSprites `$EA00`;
; kind 4 points to BlankIcon `$8A44`)
;
; $EAC0, $EB00, $EA00, $EA60, $8A44, $EAA0, $EA20, $EA80, $EAE0, $EA40. Read by
; DrawItemIcon `$7E07` (the HUD strip). Stage 1's ItemIcons at $7F3B has 9
; words.
ItemIcons:
  INCBIN "res/stage3/table-itemicons.bin",$0000,20
  ASSERT {ItemIcons} == ItemIconKind0
  ASSERT {ItemIcons+2} == ItemIconKind1
  ASSERT {ItemIcons+4} == ItemIconSprites
  ASSERT {ItemIcons+6} == ItemIconKind3
  ASSERT {ItemIcons+8} == BlankIcon
  ASSERT {ItemIcons+10} == ItemIconKind5
  ASSERT {ItemIcons+12} == ItemIconKind6
  ASSERT {ItemIcons+14} == ItemIconKind7
  ASSERT {ItemIcons+16} == ItemIconKind8
  ASSERT {ItemIcons+18} == ItemIconKind9

  ORG $7FE9

; Z when the hero is in state 6 at frame 4
;
; As IsHeroHitFrame7 for state 6. Called by VikingStand ($8D24, $8D4F) and
; StrikeableActor ($A9C2).
;
; Stage 1's IsHeroHitFrame6 at $7FFA is the same code.
;
; Witness: L1 2673 (rzx-r3, s3-right).
IsHeroHitFrame6:
  LD A,(HeroState)
  CP $06
  RET NZ
  LD A,(HeroFrame)
  CP $04
  RET

  ORG $828B

; While walking: thrown back at grid 1's left edge (room 0, column 2, facing
; left)
;
; IY = the hero. CheckSwampLeftEdge returns Z for the barrier; then the hero
; goes to state $0B (+$0B = $FF), HeroRecoil runs at once and Z is returned
; (ReturnZ: the walk handler stops). NZ: free. Called by the walk handler at
; $AFED. Stage 1's CheckWalkBarriers ($819A) tests three gates; stage 3 has
; this one barrier.
;
; Witness: L1 1769 (rzx-r3, s3-right).
CheckWalkBarriers:
  CALL CheckSwampLeftEdge
  JR Z,WalkBarrierRecoil
  RET
WalkBarrierRecoil:
  LD (IY+$0B),$FF         ; not executed in any recording (known only from the
                          ; code)
  LD (IY+$0A),$0B
  CALL HeroRecoil
  JP ReturnZ

  ORG $85A1

; NZ when item 1 is selected and its count is not 0 (the shield); Z otherwise
;
; GetSelectedItem; not item 1: Z via $B37A. Called by BogManActor ($91C8) and
; TouchHero ($85B0); neither call ran in the recordings.
;
; Stage 1's IsShieldUp at $86DD is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
IsShieldUp:
  CALL GetSelectedItem
  CP $01
  JP NZ,ReturnZ
  LD A,(IX+$00)
  CP $00
  RET

; Hurt the hero by C when the actor IY is in his column within 6 lines, unless
; the shield is up
;
; IY = the actor, C = the damage. IsShieldUp `$85A1`: NZ (the shield) returns.
; The hero's column `$74E0` must equal the actor's +0 (else NZ return), and the
; hero's line `$74E1` lie within 6 lines of the actor's +1 (AbsDiffBelow
; `$A9B6`; else return); then it runs on into DamageHero `$85C9`.
;
; No CALL, JP or word in the image reaches `$85AF` (callers.py); stage 3's
; enemies call DamageHero themselves.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
TouchHero:
  PUSH BC
  CALL IsShieldUp
  POP BC
  RET NZ
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$06
  CALL AbsDiffBelow
  RET NC

  ORG $85D7

; State $0B: the hero thrown back from a closed exit, a 6-step hop, then
; standing
;
; +$0B counts 0-6: y += RecoilSteps[+$0B], x back one pixel step ($89EF with 3:
; +$11 down, the column on wrap) and the walk frame drawn ($B065). At 7: state
; 0, x - 1 column ($B1A6 E = $FF), +$11 = 0, standing ($AF17).
;
; Stage 1's HeroRecoil at $871A is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
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
; Stage 1's RecoilSteps at $874C (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
RecoilSteps:
  DEFB $FB,$FF,$00,$00,$01,$02,$03

; A leftover no code calls: Z unless bit 1 of the room cell at (column E, line
; D) is set
;
; HL = $7282 + (D / 8) x 32 + E, then BIT 1,(HL). No caller in the image.
;
; Stage 1's CellFlagUnused at $8753 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
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

  ORG $8824

; The sea and the swamp: grid 0 below line $32 and grid 1 room 10 from column
; 18 kill; grid 1 below line $3A drains 2
;
; Called every pass by the hero's pass at $ADE9 (IY = the hero). Grid 1: in
; room 10 the hero's column $12 or more calls LoseLife; then a base line $74EE
; of $3A-$C7 calls DamageHero with C = 2. Grid 0 (the longship): a base line of
; $32-$C7 (the hero fallen into the sea) calls LoseLife unless he is already
; dying (state $0F). Grid 2: nothing. The grid-0 death ran 4 times (rzx-r3),
; the grid-1 drain never.
;
; Witness: L1 6280 (rzx-r3, s3-right).
CheckWaterDeath:
  LD A,(GridNumber)
  CP $01
  JR NZ,CheckWaterDeathSea
  LD A,(RoomNumber)
  CP $0A
  JR NZ,CheckWaterDeathSwamp
  LD A,(IY+$00)
  CP $12
  JP NC,LoseLife
CheckWaterDeathSwamp:
  LD A,(HeroBaseY)        ; grid 1: the base line $3A-$C7 drains 2
  CP $C8
  RET NC
  CP $3A
  RET C
  LD C,$02
  JP DamageHero
CheckWaterDeathSea:
  LD A,(GridNumber)            ; grid 0: the base line $32-$C7 is the sea
  CP $02
  RET Z
  LD A,(HeroBaseY)
  CP $C8
  RET NC
  CP $32
  RET C
  LD A,(HeroState)
  CP $0F
  RET Z
  JP LoseLife

; Use up the protective item's charge while it is selected
;
; Called by HeroUpdate ($ADE3) at its start. When the selected item
; (GetSelectedItem $7EEA) is of kind 1 (the kind
;
; DamageHero's guard $85A1 lets protect the hero) and its count IX is non-zero,
; takes one away every 8th pass
;
; (PassCounter) and redraws the HUD's item (JP $7D4C). The kind-1 branch ($8866
; on) is not executed in any recording (the recordings checked: rzx-r3,
; s3-right): the shield was never selected.
;
; Stage 1's DrainItemCharge at $89A1 is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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

  ORG $95DA

; The hero's wait after a death; then he comes back at the room's respawn point
;
; IY = the hero. Every 2nd pass +$10 - 1; at 0: state 0, position (+$0D, +$0E)
; = RespawnPoint, flags 0,
;
; RespawnShiftX = $FF, the standing frame (JP $AF17). Reached from HeroUpdate
; (a JP at $AE1B).
;
; Stage 1's RespawnCountdown at $9259 is the same code.
;
; Witness: L1 518 (s3-right).
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
; Stage 1's RespawnPoint at $927C is the same code.
;
; Witness: L1 8 (s3-right).
RespawnPoint:
  LD HL,RespawnPoints
  LD A,(GridNumber)
  CP $00
  JR Z,RespawnPointRead
  LD HL,RespawnPointsGrid1
  CP $01
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

; Column, line of each room: grid 0 (18 rooms), grid 1 (3) at $92C1, grid 2 (1)
; at $92C7
;
; Stage 1's RespawnPoints at $929D (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
RespawnPoints:
  DEFB $18,$31,$14,$31,$14,$31,$08,$31
RespawnPointsGrid1:
  DEFB $10,$39,$10,$39,$10,$39,$10,$39 ; as in stage 1 at $92C1 (an operand of
  DEFB $10,$39,$06,$39,$10,$39,$10,$39 ; a matched routine)
  DEFB $06,$39,$14,$19,$08,$19
RespawnPointsGrid2:
  DEFB $0C,$39            ; as in stage 1 at $92C7 (an operand of a matched
                          ; routine)

  ORG $9646

; Throw the selected item when the fire key is pressed (one throw a press)
;
; Called by HeroUpdate ($AE0E). FireLatch makes it one throw a press. Unless
; the hero's state is $0F: takes one of the selected
;
; item's count (none left: nothing), redraws it ($7D4C), plays effect 8 and
; launches a shot from the hero's hands
;
; ($B334: D = the column (one less facing left), E = the line + 8 rounded to a
; cell, B = the direction, C = 9).
;
; Stage 1's ThrowItem at $92D1 is the same code.
;
; Witness: L1 1802 (rzx-r3).
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

; Item kind 7: throw one for each press of FIRE (no count), a missile of kind 5
;
; FIRE edge-triggered through FireLatch `$FE53`. Not while dying (state `$0F`).
; PlaySoundVector effect 8, then AddMissileHigh `$B334` at the hero's column
; (one less facing left), his line + 8 rounded down to a cell, B = 1 (right) or
; 0 (left), C = 5: the kind-5 missile (handler `$821F`) is the weapon that hits
; the throne giant (ThroneBossStep `$9514`). Called by HeroUpdate `$ADE3` when
; the selected item's kind is 7.
;
; Stage 1's FireBolt (kind 7 too) added a kind-6 missile with AddMissile and
; effect `$0B`. rzx-r3 threw 33, all facing right.
;
; Witness: L1 245 (rzx-r3).
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
  LD A,(IY+$0A)
  CP $0F
  RET Z
  LD DE,$0008
  CALL PlaySoundVector
  LD D,(IY+$00)
  LD A,(IY+$01)
  ADD A,$08
  AND $F8
  LD E,A
  BIT 7,(IY+$09)
  JR NZ,FireBoltLeft
  LD B,$01
  LD C,$05
  JP AddMissileHigh
FireBoltLeft:
  LD B,$00
  LD C,$05
  DEC D
  JP AddMissileHigh

  ORG $AC46

; Per-pass handler of the hero's record ($74E0): move, fall, leave the room,
; change grid
;
; The handler word of the hero's template ($9C76), called first in each pass of
; UpdateActors $A7BB with IY =
;
; $74E0. HeroUpdate $ADE3 (controls and states), CheckHeroFooting $AC6F (ledges
; and falls), CheckRoomExits $ACE2
;
; with IX = RoomExitsPtr $FE2E, CheckGridPassages $AD24, then RoomExitsPtr =
; the grid record's word +4 +
;
; RoomNumber $FE30 (the room may have changed).
;
; Stage 1's HeroActor at $AA3E is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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
; IY = the hero. In a jump (state 2) at frame `$0C`: solid ground under the
; feet one column ahead (CellUnderFeet `$B1C8`, E = 1, D = 2) lands him on the
; ledge: frame `$0F`, the base column 2 back (MoveBaseX `$B1A6`), the base line
; 16 up (MoveActorY `$963E`), on into JumpFrame `$B13D`; at frame `$0F` with no
; ground there he drops (StartDrop `$AFB6`). Standing (state 0) or walking
; (state 1) at frame 5 or `$0B` with no ground under him (E = 1, D = 2, C = 7)
; starts a fall (StartFall `$AFA4`).
;
; Stage 1's CheckHeroFooting tested the ground of the stand and the walk with E
; = 2, D = 0. Called by HeroActor `$AC46` every pass.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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
  LD E,$01
  LD D,$02
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

  ORG $ADE3

; The hero's pass: items, hazards, weapons, colour, then his state's handler
;
; IY = the hero. DrainItemCharge `$8860` and the three checks DragonFireDamage
; `$8807`, CheckWaterDeath `$8824` and PyreFireDamage `$87ED`. A column of 0 or
; `$20` and up costs a life (LoseLife `$7EB3`) unless he is dying (state
; `$0F`); stage 3 has no deadly-cell test here (stage 1's tested bit 3 of the
; cell under him). Then the selected item's kind (GetSelectedItem `$7EEA`)
; fires its weapon: 5 ThrowAmmo `$AE94`, 8 ThrowItem `$9646`, 7 FireBolt
; `$969A` (A is not kept between the tests). Dying: the death pause
; (RespawnCountdown `$95DA`). Then the colour (HeroColour `$AE59`), and while
; HeroFreeze `$FE60` counts down the controls are ignored. Else by the state
; +$0A: 0 HeroStand `$AEDA`, 1 HeroWalk `$AFED`, 2 HeroJump `$B11B`, 3 HeroFall
; `$B0B3`, 4 HeroLeapBack `$B0FF`, 6 HeroStrike `$AF61`, 9 HeroLeap `$B147`,
; `$0B` HeroRecoil `$85D7`; stage 3 has no states 5 and 7 (stage 1's middle and
; low strikes).
;
; Called by HeroActor `$AC46`. rzx-r3 lost no life here (`$AE01` 0 runs).
;
; Witness: L1 6280 (rzx-r3, s3-right).
HeroUpdate:
  CALL DrainItemCharge
  CALL DragonFireDamage
  CALL CheckWaterDeath
  CALL PyreFireDamage
  LD A,(HeroRecord)
  CP $00
  JR Z,HeroUpdateDeath
  CP $20
  JR C,HeroUpdateWeapons
HeroUpdateDeath:
  LD A,(IY+$0A)
  CP $0F
  JR Z,HeroUpdateWeapons
  CALL LoseLife
HeroUpdateWeapons:
  CALL GetSelectedItem
  CP $05
  CALL Z,ThrowAmmo
  CP $08
  CALL Z,ThrowItem
  CP $07
  CALL Z,FireBolt
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
  CP $06
  JP Z,HeroStrike
  CP $09
  JP Z,HeroLeap
  CP $0B
  JP Z,HeroRecoil
  RET

; Set the hero's colour: flashing when weak or shielded
;
; IY = the hero, +$0C his colour. Energy $FE3F under $0E: the colour cycle of
; CycleColour $B4A3. Else item kind 1
;
; selected with a count: white and blue on alternate passes. Else +$0C rises
; one a pass up to 7 (white).
;
; Stage 1's HeroColour at $ACD9 is the same code.
;
; Witness: L1 5762 (rzx-r3, s3-right).
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

; Item kind 5: throw one of the counted items (a missile of kind 2 or 3)
;
; FIRE edge-triggered (FireLatch `$FE53`). With a count left (GetSelectedItem
; `$7EEA`'s IX), the count goes down and the HUD's count is printed again
; (ShowItemCount `$7D4C`); AddMissile `$B32B` at the hero's column and line +
; 8, B = `$0A`, C = 3 (facing right) or 2 (left): the thrown item (handler
; `$7FF5`); PlaySoundVector effect `$0B`. Any state but none is tested (stage 1
; threw only standing).
;
; rzx-r3 threw 22, all facing right (`$AECF` 0 runs).
;
; Witness: L1 562 (rzx-r3).
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
  ADD A,$08
  LD E,A
  LD B,$0A
  LD D,(IY+$00)
  LD C,$03
  BIT 7,(IY+$09)
  JR Z,ThrowAmmoAdd
  LD C,$02
ThrowAmmoAdd:
  CALL AddMissile
  LD DE,$000B
  JP PlaySoundVector

; State 0: read the controls
;
; IY = the hero. FIRE: HeroFireHeld `$AF23`. DOWN: the leap (StartLeap
; `$AF51`). UP: the jump (StartJump `$AF41`). RIGHT: walk right (WalkRight
; `$AFC3`) when facing right; facing left he only turns (base column + 4,
; facing right) and shows the standing frame. LEFT the same mirrored (WalkLeft
; `$AFD8`). No key: nothing (the frame stays). The key readers are the
; resident's KeyUp `$FC90` to KeyFire `$FCCC` (Z = held).
;
; Witness: L1 2474 (rzx-r3, s3-right).
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
  JR HeroStandFrame
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
; by $85EE, $95FA (the end of the death
;
; pause) and $A689.
;
; Stage 1's HeroStandFrame at $ADDD is the same code.
;
; Witness: L1 201 (rzx-r3, s3-right).
HeroStandFrame:
  LD A,$0C
  LD (IY+$08),A
  CALL SetActorFrame

; SetActorFrame's words after HeroStandFrame's CALL: the walk frame table
; `$E8AA`, its graphics `$E620`
;
; Read by SetActorFrame `$AC0A`. Frame `$0C` of the set is the standing hero.
HeroStandSet:
  DEFW HeroWalkFrameTable,HeroWalkSprites

; FIRE held while standing: the strike, with item kind 3 and UP
;
; Only with the selected item's kind 3 (GetSelectedItem `$7EEA`) and UP held:
; frame `$FF`, state 6, the base column + 1, then HeroStrike. Else nothing.
; Stage 1's HeroFireHeld took kinds 6, 5 and 3 and three strikes (DOWN, UP,
; LEFT).
;
; Witness: L1 374 (rzx-r3, s3-right).
HeroFireHeld:
  CALL GetSelectedItem
  CP $03
  JR NZ,HeroFireHeldNoWeapon
  CALL KeyUp
  JR NZ,HeroFireHeldNoKey
  LD (IY+$08),$FF
  LD (IY+$0A),$06
  LD E,$01
  CALL MoveBaseX
  JP HeroStrike
HeroFireHeldNoKey:
  RET
HeroFireHeldNoWeapon:
  RET

; Start the jump: state 2, base column + 2
;
; Also entered from the walk (WalkJumpCheck $B06F).
;
; Stage 1's StartJump at $AE3D is the same code.
;
; Witness: L1 34 (rzx-r3, s3-right).
StartJump:
  LD E,$02
  CALL MoveBaseX
  LD (IY+$0A),$02
  LD (IY+$08),$FF
  JP HeroJump

; Start the leap (DOWN): state 9, base column + 1
;
; Stage 1's StartLeap at $AE4D is the same code.
;
; Witness: L1 21 (rzx-r3).
StartLeap:
  LD E,$01
  CALL MoveBaseX
  LD (IY+$0A),$09
  LD (IY+$08),$FF
  JP HeroLeap

; State 6: the strike, 14 passes; held while FIRE and UP are held
;
; +8 counts the passes from 0; at 9 with FIRE and UP still held it goes back to
; 0 (the swing goes on). At `$0E`: state 0, the base column - 1, the standing
; frame. Else the frame is HeroStrikeFrames[+8 / 2] of HeroStrikeSet. The
; strike's hit is tested by the struck actors (IsHeroHitFrame6 `$7FE9`).
;
; Witness: L1 567 (rzx-r3, s3-right).
HeroStrike:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $09
  JR NZ,HeroStrikeEnd
  CALL KeyFire
  JR NZ,HeroStrikeEnd
  CALL KeyUp
  JR NZ,HeroStrikeEnd
  LD (IY+$08),$00
HeroStrikeEnd:
  LD A,(IY+$08)
  CP $0E
  JR NZ,HeroStrikeShow
  LD (IY+$0A),$00
  LD E,$FF
  CALL MoveBaseX
  JP HeroStandFrame
HeroStrikeShow:
  SRL A
  LD C,A
  LD B,$00
  LD HL,HeroStrikeFrames
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetActorFrame's words: the strike frame table `$E206`, its graphics `$E0E9`
;
; Read by SetActorFrame `$AC0A` after the CALL at `$AF96`.
HeroStrikeSet:
  DEFW HeroStrikeFrameTable,HeroStrikeSprites

; the strike set's frame for each pair of passes: 0, 1, 2, 3, 2, 1, 0
;
; Read by HeroStrike `$AF61` (all 7 bytes in rzx-r3).
HeroStrikeFrames:
  DEFB $00,$01,$02,$03,$02,$01,$00

; Start a fall: state 3, speed 2, frame $10, base column - 5
;
; Stage 1's StartFall at $AF1B is the same code.
;
; Witness: L1 5 (rzx-r3, s3-right).
StartFall:
  LD (IY+$0A),$03
  LD (IY+$0B),$02
  LD (IY+$08),$10
  LD E,$FB
  CALL MoveBaseX
  RET

; Drop off a ledge missed in a jump: state 3, speed 4, frame $10
;
; Stage 1's StartDrop at $AF2D is the same code.
;
; Witness: L1 8 (rzx-r3, s3-right).
StartDrop:
  LD (IY+$0A),$03
  LD (IY+$0B),$04
  LD (IY+$08),$10
  RET

; RIGHT while standing: start walking unless a wall is ahead
;
; FrontCellAhead $B09A: a solid cell keeps him standing. Else state 1, frame 0,
; base column + 2.
;
; Stage 1's WalkRight at $AF3A is the same code.
;
; Witness: L1 197 (rzx-r3, s3-right).
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
; Stage 1's WalkLeft at $AF4F is the same code.
;
; Witness: L1 32 (rzx-r3).
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
; A barrier ahead (CheckWalkBarriers `$828B`: Z) ends the pass. UP at frame 5
; or `$0A` jumps (WalkJumpCheck `$B06F`). At frames 5 and `$0B` (the feet
; together) a wall ahead (FrontCell `$B081`) stops him: the base column becomes
; his column - 1 (+ 1 facing left), state 0, the standing frame. RIGHT while
; facing left, or LEFT while facing right, turns him (HeroTurn `$B184`). No
; direction key at frame 5 or `$0B`: state 0, the standing frame. The frame
; goes 0 to `$0B`; at 0 and 6 the base column moves 2 (MoveBaseX `$B1A6`); then
; the frame of HeroWalkSet.
;
; Witness: L1 1769 (rzx-r3, s3-right).
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
  XOR A
HeroWalkFrame:
  LD (IY+$08),A
  CP $06
  JP NZ,HeroWalkShow
  LD E,$02
  CALL MoveBaseX
; This entry point is used by the routine at HeroRecoil.
HeroWalkShow:
  LD A,(IY+$08)           ; as in stage 1 at $AFD1
  CALL SetActorFrame

; SetActorFrame's words: the walk frame table `$E8AA` (`$0D` frames; `$0C`
; stands), its graphics `$E620`
;
; Read by SetActorFrame `$AC0A` after the CALL at `$B068`.
HeroWalkSet:
  DEFW HeroWalkFrameTable,HeroWalkSprites

; UP during the walk at frame 5 or $0A: drop the walk and jump
;
; Pops the return address and jumps to StartJump $AF41.
;
; Stage 1's WalkJumpCheck at $AFDB is the same code.
;
; Witness: L1 1769 (rzx-r3, s3-right).
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
; Column + 4 facing right, + 0 facing left (CellAt `$B1F6`, jumped to). Called
; by HeroWalk.
;
; Witness: L1 284 (rzx-r3, s3-right).
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

; The cell where a walk would start: column + 3 (facing right) or + 1 (left),
; line + 16; NZ when solid
;
; CellAt `$B1F6` (jumped to). Called by WalkRight `$AFC3` and WalkLeft `$AFD8`.
; Stage 1's FrontCellAhead was a copy of FrontCell (+ 4 / + 0).
;
; Witness: L1 229 (rzx-r3, s3-right).
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
; Frames `$10` to `$12` of the jump set. At frame `$10`: solid ground under the
; feet (CellUnderFeet `$B1C8`, E = 1, D = 2, C = 4) starts the landing (frames
; `$11`, `$12`, then standing at frame 6, base column + 5); else the speed +$0B
; goes up by 2 to 4 and is added to the base line. Stage 1 tested the ground
; with E = 2, D = 0.
;
; Witness: L1 77 (rzx-r3, s3-right).
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
; Stage 1's HeroLeapBack at $B06B is the same code.
;
; Witness: L1 189 (rzx-r3).
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
; CheckHeroFooting $AC6F catches a ledge on
;
; the way down.
;
; Stage 1's HeroJump at $B087 is the same code.
;
; Witness: L1 604 (rzx-r3, s3-right).
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
; Stage 1's JumpFrame at $B0A9 is the same code.
;
; Witness: L1 662 (rzx-r3, s3-right).
JumpFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's words: the jump frame table `$E5AE` (19 frames; `$10`-`$12`
; also the fall), its graphics `$E224`
;
; Read by SetActorFrame `$AC0A` after JumpFrame's CALL at `$B140`.
HeroJumpSet:
  DEFW HeroJumpFrameTable,HeroJumpSprites

; State 9: the leap up (DOWN), frames 0 to $0D of the leap set
;
; The frames crouch and spring up (their line offsets fall from 46 to 25). At
; frame 8 a ledge under the raised feet
;
; (CellUnderFeet $B1C8, E = 1, D = 2) lets him climb: at $0E the base line goes
; 16 up and he stands; no ledge sinks
;
; him back (state 4, HeroLeapBack $B0FF).
;
; Stage 1's HeroLeap at $B0B3 is the same code.
;
; Witness: L1 189 (rzx-r3).
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
; Stage 1's LeapFrame at $B0E9 is the same code.
;
; Witness: L1 336 (rzx-r3).
LeapFrame:
  CALL SetActorFrame

; SetActorFrame's words: the leap frame table `$EE65` (14 frames), its graphics
; `$EBBC`
;
; Read by SetActorFrame `$AC0A` after LeapFrame's CALL at `$B17D`.
HeroLeapSet:
  DEFW HeroLeapFrameTable,HeroLeapSprites

; Turn the hero round in the walk: base column by TurnSteps[frame], facing
; flipped
;
; Stage 1's HeroTurn at $B0F0 is the same code.
;
; Witness: L1 8 (rzx-r3).
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
; Stage 1's TurnSteps at $B106 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
TurnSteps:
  DEFB $02,$02,$02,$04,$04,$04,$02,$02,$02,$02,$04,$04

  ORG $B2C9

; Start the hero's death: a burst of eight fragments, the hero hidden, the
; pause
;
; Only when no death is in progress (RespawnShiftX $FE5E = $FF). E = the pause
; in pairs of passes ($33 after a life, $6C
;
; after the last; from LoseLife $7EB3), stored in the hero's +$10 ($74F0).
; Clears the effects 8-15 ($7610-$763F),
;
; adds eight effects of type 7 at the hero (column, line + 4) with +4 = 0, 2,
; .. 14 (the directions) and +5 = the
;
; column x 2 (AddMissileHigh $B334), sets state $0F ($74EA), takes the respawn
; point ($95FD: D column, E line),
;
; RespawnShiftX and RespawnShiftY $FE5F from it, and hides the hero (column 0,
; line $8C, colour 0).
;
; Stage 1's HeroDeath at $B22B is the same code.
;
; Witness: L1 4 (s3-right).
HeroDeath:
  LD A,(RespawnShiftX)
  CP $FF
  RET NZ
  PUSH DE
  LD HL,MissilesHigh
  LD DE,MissilesHighY
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
