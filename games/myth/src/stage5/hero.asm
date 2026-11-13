; --------------------------------------------------------------------------------------------------------------------
; hero.asm: The hero: its movement, its shots, its explosion, and the item strip kept from stage 1
;
; The hero is a 3-byte, 24-line sprite (HeroFrames: 4 animation frames x 4 two-pixel shifts) copied to the screen from
; the record HeroRecord $BA7E: +0 X in pixels ($12-$66), +1 the screen line ($40-$96), +4 the state (0 flying, 1
; exploding, 2 re-forming, 3 game over), +5 the explosion frame, +6 the game-over count ($5A). The keys move it 2
; pixels a pass in state 0 (HeroControl). FIRE shoots on its release (HeroFire): the shot records at HeroShots $75E0
; (16 x 8 bytes: +0 the column, $FF free, $FE ending; +1 the line; +2/+3 the screen address) fly one column a pass to
; column 29 (MoveShots, DrawShots).
;
; The item strip, the item window and the item counts are stage 1's code left in the block: StageSetUp $95E4 rolls the
; strip in at the start (ScrollItemsLeft three times, FlashSelectedBox); nothing else of it runs.
;
; The hero's record is at HeroRecord $BA7E (+0 X in pixels, +1 the screen line, +4 a flag, +5 a frame).
; --------------------------------------------------------------------------------------------------------------------

  ORG $7BCB

; SPACE: stop the game, flash the strip's frame, choose an item with LEFT and
; RIGHT, SPACE again to go on
;
; As in stage 1 at $7C27, the same code. Clears PassCounter, waits (cycling the
; frame colours, CycleWindowFrame) for SPACE's release (TestSpaceKey $93BE),
; then every 6 frames: DrawItemStrip and ShowItemCount; RIGHT (KeyRight $FCBD)
; scrolls to the previous slot (ScrollItemsRight), LEFT (KeyLeft $FCAE) to the
; next (ScrollItemsLeft); SPACE again: waits for its release, cycles the frame
; back to its first colour (the attribute $586A at 1) and falls into
; FlashSelectedBox.
;
; No caller in stage 5's code: no CALL, JP or pointer to $7BCB in list-all.txt
; other than its own loop ($7BD7); stage 5's main loop does not test SPACE
; alone.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ItemWindow:
  LD A,$00
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
  JP NZ,ItemWindowLeft
  CALL ScrollItemsRight
  JP ItemWindowStep
ItemWindowLeft:
  CALL KeyLeft
  JP NZ,ItemWindowSpace
  CALL ScrollItemsLeft
  JP ItemWindowStep
ItemWindowSpace:
  CALL TestSpaceKey
  JP NZ,ItemWindowStep
ItemWindowRelease:
  CALL TestSpaceKey
  JP Z,ItemWindowRelease
ItemWindowSettle:
  HALT
  CALL CycleWindowFrame
  LD A,(Attributes+106)
  CP $01
  JP NZ,ItemWindowSettle

; Colour the selected item's box with inks 2 to 6, one a frame
;
; As in stage 1 at $7C6E, the same code. Five frames: patches the colour into
; the inline record SelectedBoxRecord (column 15, line 24, 2 x 2 cells) and
; fills it with FillAttributes $954E. Called by StageSetUp $95E4 (the stage's
; set-up) and reached from ItemWindow.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
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

; $954E's inline record: column 15, line 24, 2 x 2 cells, the colour (patched)
;
; Read by FillAttributes $954E after the CALL at $7C24; FlashSelectedBox writes
; its last byte (the colour, 2 to 6).
SelectedBoxRecord:
  DEFB $0F,$18,$02,$02,$00

; FlashSelectedBox, continued
;
; Part of FlashSelectedBox, after its inline record.
;
; Witness: L1 15 (ending, rzx-r5, s5-right).
FlashSelectedBoxNext:
  POP BC
  INC C
  DJNZ FlashSelectedBoxFrame
  RET

; Select the next slot: scroll the strip 24 pixels left, one pixel a frame
;
; As in stage 1 at $7C85, the same code. Returns if ItemSelected $FE35 is
; ItemLast $FE36. Else ItemSelected + 1, and 24 times: shifts the strip's 18
; lines in the play buffer ($5B66-$5B77, 17 bytes a line) one pixel left,
; cycles the frame (CycleWindowFrame) and shows the strip (ShowItemStrip). Run
; three times at the stage's start ($963A, with the frame cycle patched off) to
; roll the strip in.
;
; Witness: L1 9 (ending, rzx-r5, s5-right).
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
; As in stage 1 at $7CB9, the same code. Returns if ItemSelected $FE35 is
; ItemFirst $FE37. Else ItemSelected - 1 and the mirror of ScrollItemsLeft.
; Reached only from ItemWindow.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
; As in stage 1 at $7CED, the same code. PassCounter $FE4D + 1; the colour
; WindowFrameColours[PassCounter AND 15] fills the attributes $586A-$5875 and
; $588A-$5895. Its first byte is a NOP that the stage's start ($9632) patches
; to RET while it rolls the strip in, and back ($964B).
;
; Witness: L1 216 (ending, rzx-r5, s5-right). In s5-right only the patched RET
; ran (the item window was never opened).
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
; 16 bytes, read by CycleWindowFrame at PassCounter AND 15: 1-7, 7, 7, 6-1.
; Read in no recording (s5-right, rzx-r5, ending).
WindowFrameColours:
  DEFB $01,$02,$03,$04,$05,$06,$07,$07
  DEFB $07,$07,$06,$05,$04,$03,$02,$01

; When ItemsChanged is set: clear it and redraw the strip and the count
;
; As in stage 1 at $7D26, the same instructions with ItemsChanged at
; ItemsChanged $FE2F (stage 1's $FE4A). When $FE2F is 1: clears it,
; DrawItemStrip, then ShowItemCount.
;
; No caller in stage 5's code: no CALL, JP or pointer to $7CD2 in list-all.txt;
; nothing in stage 5 writes ItemsChanged $FE2F but this routine (and
; InitStageState $96DD's clear).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
RedrawItemsIfChanged:
  LD A,(ItemsChanged)
  CP $01
  RET NZ
  LD A,$00
  LD (ItemsChanged),A
  CALL DrawItemStrip
  JP ShowItemCount

; Draw the icons of slots ItemSelected-3 to +4 into the buffer and show them
;
; As in stage 1 at $7D36, the same code. For 8 slots from CarriedItems +
; ItemSelected - 3: DrawItemIcon at $5B64 + 3 x n, then ShowItemStrip. Called
; by StageSetUp $95E4 at the start (three times), ItemWindow and
; RedrawItemsIfChanged.
;
; Witness: L1 9 (ending, rzx-r5, s5-right).
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
; As in stage 1 at $7D5E, the same code. FormatItemCount, CopyToScreen of the 2
; x 8 bytes at DigitBuffer $7640 to column 15, line 8 (stride 2); then the
; attributes $582F (tens) and $5830 (units): $41 (blue on black, unseen) for a
; zero digit pair, else $06 (yellow). Reached from ItemWindow and
; RedrawItemsIfChanged.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
  JP Z,ShowItemCountTens
  LD E,$06
ShowItemCountTens:
  LD A,E
  LD (Attributes+47),A
  LD A,(IX+$03)
  CP $30
  JP Z,ShowItemCountZero
  LD A,$06
  LD (Attributes+48),A
  RET
ShowItemCountZero:
  LD A,E                  ; units digit '0': hidden only when the tens are
                          ; hidden too
  CP $41
  JP Z,ShowItemCountHide
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
; As in stage 1 at $7DA0, the same code. Tens (by repeated subtraction of 10)
; and units into ItemCountText+2 and +3, then RenderDigits with a stride of 2
; into DigitBuffer $7640. Called by ShowItemCount.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
  JP C,FormatItemCountDone
  INC C
  JP FormatItemCountTens
FormatItemCountDone:
  ADD A,$3A
  LD (IX+$03),A
  LD (IX+$02),C
  LD A,$02
  LD HL,DigitBuffer
  JP RenderDigits

; The count as text for RenderDigits: two unused bytes, two digits, 0
;
; Written by FormatItemCount (+2 the tens, +3 the units), read by RenderDigits
; and ShowItemCount. Loaded as 0, 0, '00', 0.
ItemCountText:
  DEFB $00,$00,$30,$30,$00

  ORG $7DD0

; Draw item icon A (16 lines of 2 bytes, a blank third byte) into the buffer at
; HL
;
; As in stage 1 at $7E19, the same code. HL = the buffer address (stride 32), A
; = the item kind; the icon's address is ItemIcons[A]. Destroys BC, DE. Called
; by DrawItemStrip.
;
; Witness: L1 72 (ending, rzx-r5, s5-right).
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
; As in stage 1 at $7E3D, the same code. Two calls of CopyStripRows: the first
; 8 lines to $406A (row 3, column 10), the next 8 to $408A.
;
; Witness: L1 225 (ending, rzx-r5, s5-right).
ShowItemStrip:
  LD HL,PlayBuffer+104
  LD DE,Screen+106
  CALL CopyStripRows
  LD DE,Screen+138
  JP CopyStripRows

; Copy 8 lines of 12 bytes from the buffer (stride 32) to one character row of
; the screen at DE
;
; As in stage 1 at $7E4C, the same code. HL = the buffer (left after the call
; at the next 8 lines), DE = the screen address.
;
; Witness: L1 450 (ending, rzx-r5, s5-right).
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

  ORG $7E67

; The item kind of each of the 12 slots (slots 0-3 hold 4, the blank icon; slot
; 6 holds 8)
;
; Copied from StartItems by InitStageState $96DD at the start; read by
; DrawItemStrip (CarriedItems + ItemSelected - 3, 8 slots). Loaded as a copy of
; StartItems.
CarriedItems:
  DEFB $04,$04,$04,$04,$00,$00,$08,$00,$00,$00,$00,$00

; The amount of each slot's item (read by FormatItemCount)
;
; Read by FormatItemCount at CarriedCounts + ItemSelected. All 0; no stage-5
; code writes them.
CarriedCounts:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The carried items at the stage's start, copied to CarriedItems by $96DD:
; slots 0-3 kind 4 (blank), slot 6 kind 8
;
; The 12 bytes $04, $04, $04, $04, 0, 0, $08, 0, 0, 0, 0, 0. InitStageState
; $96DD copies them with LDIR to CarriedItems.
StartItems:
  INCBIN "res/stage5/table-startitems.bin",$0000,12

; The 16 x 16 icon of each item kind 0-8 (32 bytes each; kind 4 points to the
; blank $94B0)
;
; Read by DrawItemIcon at ItemIcons + 2 x kind: ItemIcon0 $BA38, ItemIcon1
; $B9F8, ItemIcons16 $B958, ItemIcon3 $B9B8, BlankIcon $94B0, ItemIcon5 $B998,
; ItemIcon6 $B978, ItemIcons16 $B958, ItemIcon8 $B9D8.
ItemIcons:
  INCBIN "res/stage5/table-itemicons.bin",$0000,18
  ASSERT {ItemIcons} == ItemIcon0 && {ItemIcons+2} == ItemIcon1 && {ItemIcons+4} == ItemIcons16
  ASSERT {ItemIcons+6} == ItemIcon3 && {ItemIcons+8} == BlankIcon && {ItemIcons+10} == ItemIcon5
  ASSERT {ItemIcons+12} == ItemIcon6 && {ItemIcons+14} == ItemIcons16 && {ItemIcons+16} == ItemIcon8

  ORG $7EE9

; Put the hero at X $40, line $68, flying (state 0, frame 0), the game-over
; count $5A
;
; Writes the hero record HeroRecord $BA7E: +0 X = $40, +1 line = $68, +4 state
; = 0, +5 frame = 0, +6 the game-over count = $5A (90 even passes). Called once
; by StageEntry.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
InitHero:
  LD IX,HeroRecord
  LD (IX+$00),$40
  LD (IX+$01),$68
  LD (IX+$04),$00
  LD (IX+$05),$00
  LD (IX+$06),$5A
  RET

; Free the 16 hero shot records: fill $75E0-$765F with $FF
;
; 128 bytes of $FF (LDIR): the 16 records of 8 bytes MoveShots and DrawShots
; walk. Called once by StageEntry.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
ClearHeroShots:
  LD HL,HeroShots
  LD DE,HeroShots+$0001
  LD BC,$007F
  LD (HL),$FF
  LDIR
  RET

  ORG $7F1E

; Move the hero with the keys (state 0); on even passes run its explosion,
; re-forming and game-over count
;
; IX = the hero record HeroRecord $BA7E. State +4 = 0: RIGHT (HeroRight), LEFT
; (HeroLeft), UP (HeroUp), DOWN (HeroDown), each tested with the resident
; readers (KeyRight $FCBD, KeyLeft $FCAE, KeyUp $FC90, KeyDown $FC9F; Z =
; held), 2 pixels a pass. Then on odd passes (PassCounter $FE4D bit 0) return.
;
; On even passes by state: 0 nothing; 1 (exploding, set by LoseLife) the frame
; +5 + 1 up to 6, then state 3 when Lives $FE58 is 0, else state 2; 2
; (re-forming) the frame - 1 down to $FF, then state 0 and frame 0; 3 and on
; (game over) the count +6 - 1 and the frame = 5 each even pass; MainLoop ends
; the stage when the count HeroGameOverCount $BA84 reaches 0 (90 even passes).
;
; A quirk from the code: on the pass the explosion ends with lives left, the
; state-2 test sees A = Lives: with 2 lives it runs one re-forming step at once
; (frame 5), with others the state-3 tail once (HeroGameOverTick: the count -
; 1, frame 5).
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
HeroControl:
  LD IX,HeroRecord
  LD A,(IX+$04)
  CP $00
  JP NZ,HeroControlState
  CALL KeyRight
  CALL Z,HeroRight
  CALL KeyLeft
  CALL Z,HeroLeft
  CALL KeyUp
  CALL Z,HeroUp
  CALL KeyDown
  CALL Z,HeroDown
HeroControlState:
  LD A,(PassCounter)            ; even passes only: the state machine
  AND $01
  RET NZ
  LD A,(IX+$04)
  CP $00
  RET Z
  CP $01
  JP NZ,HeroReforming
  INC (IX+$05)
  LD A,(IX+$05)
  CP $06
  RET NZ
  LD A,(Lives)
  CP $00
  JP NZ,HeroToReform
  LD (IX+$04),$03
  JP HeroGameOverTick
HeroToReform:
  LD (IX+$04),$02         ; lives left: state 2
HeroReforming:
  CP $02
  JP NZ,HeroGameOverTick
  DEC (IX+$05)
  LD A,(IX+$05)
  CP $FF
  RET NZ
  LD (IX+$04),$00
  LD (IX+$05),$00
  RET
HeroGameOverTick:
  DEC (IX+$06)            ; the game-over count - 1, frame 5
  LD (IX+$05),$05
  RET

; LEFT: X - 2 unless it becomes $10 (X stops at $12)
;
; IX = the hero record. Called by HeroControl when LEFT is held.
;
; Witness: L1 126 (rzx-r5).
HeroLeft:
  LD A,(IX+$00)
  SUB $02
  CP $10
  RET Z
  LD (IX+$00),A
  RET

; RIGHT: X + 2 while under $68 (X stops at $66)
;
; IX = the hero record. Called by HeroControl when RIGHT is held.
;
; Witness: L1 2147 (rzx-r5, s5-right).
HeroRight:
  LD A,(IX+$00)
  ADD A,$02
  CP $68
  RET NC
  LD (IX+$00),A
  RET

; UP: the line - 2 unless it falls under $40
;
; IX = the hero record. Called by HeroControl when UP is held.
;
; Witness: L1 869 (rzx-r5, s5-right).
HeroUp:
  LD A,(IX+$01)
  SUB $02
  CP $40
  RET C
  LD (IX+$01),A
  RET

; DOWN: the line + 2 while under $98 (the line stops at $96)
;
; IX = the hero record. Called by HeroControl when DOWN is held.
;
; Witness: L1 703 (rzx-r5).
HeroDown:
  LD A,(IX+$01)
  ADD A,$02
  CP $98
  RET NC
  LD (IX+$01),A
  RET

  ORG $7FD3

; FIRE: a shot from the hero on each release of FIRE, with effect 8
;
; Nothing while the hero's state HeroState $BA82 is not 0. FireLatch $FE3A = 1
; (armed): FIRE held (KeyFire $FCCC, Z) clears it. FireLatch 0: while FIRE is
; held nothing; when it is up FireLatch = 1 and a shot: FindShotSlot (none
; free: return), PlaySoundVector E = 8, the record: +0 the column X / 8, +1 the
; line (Y + 12) AND $F8, +2/+3 the screen address of that line and column
; (ScreenLineTable). FireLatch is 0 at the start, so the first pass with FIRE
; up fires once.
;
; s5-right: 30 presses, 31 shots.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
HeroFire:
  LD A,(HeroState)
  CP $00
  RET NZ
  LD A,(FireLatch)
  CP $01
  JP NZ,HeroFireArmed
  CALL KeyFire
  RET NZ
  LD A,$00
  LD (FireLatch),A
HeroFireArmed:
  CALL KeyFire              ; FireLatch 0: shoot when FIRE is up
  RET Z
  LD A,$01
  LD (FireLatch),A
  CALL FindShotSlot
  RET NZ
  LD DE,$0008
  CALL PlaySoundVector
  LD IY,HeroRecord
  LD A,(IY+$00)
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(IY+$01)
  ADD A,$0C
  AND $F8
  LD (IX+$01),A
  LD C,A
  LD B,$00
  LD HL,ScreenLineTable
  ADD HL,BC
  ADD HL,BC
  LD A,(HL)
  ADD A,(IX+$00)
  LD (IX+$02),A
  INC HL
  LD A,(HL)
  LD (IX+$03),A
  RET

; IX = the next shot record (round robin over 16); Z when it is free
;
; ShotCursor $FE2D + 1 AND 15; IX = HeroShots $75E0 + 8 x it; Z when +0 is $FF.
; Called by HeroFire.
;
; Witness: L1 278 (ending, rzx-r5, s5-right).
FindShotSlot:
  LD A,(ShotCursor)
  INC A
  AND $0F
  LD (ShotCursor),A
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,HeroShots
  ADD IX,BC
  LD A,(IX+$00)
  CP $FF
  RET

  ORG $8464

; Move the hero's shots one column right; a shot on Dameron's hit line scores
; two pending hits
;
; For the 16 shot records at HeroShots $75E0 (8 bytes): free ($FF) skip; $FE
; becomes $FF (freed after DrawShots erased it); else the column + 1 and the
; screen address +2 + 1; at column $1D the shot ends ($FE). Then Dameron's
; column: (X + C) / 8 with C = $88 (forms 0-2), $B0 (form 3), $E8 (won). In
; that column and with the line +1 within Y + $2B to Y + $A2 the shot ends; it
; scores (the pending hits PendingHits $FE41 = 2) only on the line (Y AND $F8)
; + $88 (form 0), + $68 (form 1), + $60 (forms 2-3), the mouth; won (phase 4
; and on): any line in the band.
;
; With X at 0 the won column is 29 ($1D), where the shots end before the test,
; so no hit after the duel. s5-right: 25 shots met the head, none on the hit
; line; rzx-r5: 40 shots on the hit line ($84DE), all before the win.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
MoveShots:
  LD IX,HeroShots
  LD B,$10
  LD DE,$0008
MoveShotsNext:
  LD A,(IX+$00)
  INC A
  JP Z,MoveShotsSkip
  LD (IX+$00),A
  CP $FF
  JP Z,MoveShotsSkip
  INC (IX+$02)
  CP $1D
  JP Z,ShotEnds
  LD C,$E8
  LD A,(DuelPhase)
  CP $04
  JP NC,MoveShotsColumn
  LD C,$B0
  CP $03
  JP Z,MoveShotsColumn
  LD C,$88
MoveShotsColumn:
  LD A,(DameronX)
  ADD A,C
  SRL A
  SRL A
  SRL A
  CP (IX+$00)
  JP NZ,MoveShotsSkip
  LD A,(DameronY)
  ADD A,$2A
  CP (IX+$01)
  JP NC,MoveShotsSkip
  ADD A,$78
  CP (IX+$01)
  JP C,MoveShotsSkip
  LD A,(DuelPhase)
  CP $04
  JP NC,ShotHitsDameron
  LD C,$88
  CP $00
  JP Z,MoveShotsLine
  LD C,$60
  CP $02
  JP NC,MoveShotsLine
  LD C,$68
MoveShotsLine:
  LD A,(DameronY)
  AND $F8
  ADD A,C
  CP (IX+$01)
  JP NZ,ShotEnds
ShotHitsDameron:
  LD A,$02                ; two pending hits
  LD (PendingHits),A
  JP ShotEnds
MoveShotsSkip:
  ADD IX,DE
  DJNZ MoveShotsNext
  RET
ShotEnds:
  LD (IX+$00),$FE         ; +0 = $FE: erased and freed on the next passes
  JP MoveShotsSkip

; Draw the hero's shots (5 lines of 2 blank and 2 picture bytes); erase the
; ending ones
;
; For the 16 shot records: free skip; ending ($FE): EraseShot clears 3 lines of
; one byte at the screen address +2/+3; else 5 lines at the screen address: 2
; bytes of 0 (the trail) then 2 bytes of ShotGraphic. Then clears the screen
; byte $4BFD (line 123, column 29) every pass. Every pass from MainLoop.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
DrawShots:
  LD IX,HeroShots
  LD B,$10
DrawShotsNext:
  PUSH BC
  LD A,(IX+$00)
  INC A
  JP Z,DrawShotsSkip
  CP $FF
  JP Z,EraseShot
  LD HL,ShotGraphic
  LD E,(IX+$02)
  LD D,(IX+$03)
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LDI
  LDI
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LDI
  LDI
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LDI
  LDI
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LDI
  LDI
  INC D
  DEC E
  DEC E
  DEC E
  DEC E
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LDI
  LDI
DrawShotsSkip:
  LD BC,$0008
  ADD IX,BC
  POP BC
  DJNZ DrawShotsNext
  LD A,$00
  LD (Screen+3069),A
  RET
EraseShot:
  LD E,(IX+$02)
  LD D,(IX+$03)
  XOR A
  LD (DE),A
  INC D
  LD (DE),A
  INC D
  LD (DE),A
  JP DrawShotsSkip

; The hero's shot: 5 lines of 2 bytes
;
; Read by DrawShots (LDI, 2 bytes a line).
ShotGraphic:
  INCBIN "res/stage5/bitmaps-shot-2x5.bin",$0000,10

; Draw the hero (3 bytes x 24 lines) straight to the screen; while exploding
; $9D85 draws the explosion
;
; IX = the hero record HeroRecord $BA7E. State +4 not 0: JP DrawHeroFrame $9D85
; (the explosion frame +5 + 12, same layout). Else the frame:
; HeroFrames[((PassCounter AND 7) / 2) x 4 + (X AND 6) / 2], 4 animation frames
; and 4 two-pixel shifts; the column X / 8 is patched into $85C8; SP walks
; ScreenLineTable from the line +1 (DI), 3 LDIs a line for 24 lines.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
DrawHero:
  LD IX,HeroRecord
  LD A,(IX+$04)
  CP $00
  JP NZ,DrawHeroFrame
  DI
  LD IX,HeroRecord
  LD A,(IX+$00)
  AND $06
  LD C,A
  LD A,(PassCounter)
  AND $07
  SRL A
  SLA A
  SLA A
  SLA A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,HeroFrames
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  LD (DrawHeroLine+$0003),A
  LD A,(IX+$01)
  LD C,A
  LD B,$00
  LD HL,ScreenLineTable
  ADD HL,BC
  ADD HL,BC
  LD (SavedSP),SP
  LD SP,HL
  EX DE,HL
  LD BC,$0048
DrawHeroLine:
  POP DE
  LD A,E
  ADD A,$00
  LD E,A
  LDI
  LDI
  LDI
  JP PE,DrawHeroLine
  LD SP,(SavedSP)
  EI
  RET

; The hero's 16 frames: 4 animation steps x 4 shifts (0, 2, 4, 6 pixels), 72
; bytes each
;
; Read by DrawHero at HeroFrames + ((PassCounter AND 7) / 2) x 8 + (X AND 6).
; Steps 0-2 at $BB1C-$BE34; step 3 repeats step 1 ($BC3C-$BD14).
HeroFrames:
  DEFW HeroSprites,$BB64,$BBAC,$BBF4
  DEFW $BC3C,$BC84,$BCCC,$BD14
  DEFW $BD5C,$BDA4,$BDEC,$BE34
  DEFW $BC3C,$BC84,$BCCC,$BD14

  ORG $9D85

; Draw the hero ($BA7E) as frame +5 + 12 (3 bytes x 24 lines) straight onto the
; screen
;
; Jumped to from $857F when the record's +4 (HeroState $BA82) is not 0. DI; DE
; = SpriteFrameAddress(+5 + 12); the column +0 / 8 is written into the ADD A,n
; at DrawHeroFrameColumn; SP walks ScreenLineTable $FB00 from the line +1
; (SavedSP $FE0E keeps the real SP); 24 lines of 3 bytes (LDI x 3 until BC = 72
; is spent); EI. No mask: the bytes replace the screen's.
;
; Witness: L1 119 (ending).
DrawHeroFrame:
  DI
  LD IX,HeroRecord
  LD A,(IX+$05)
  ADD A,$0C
  CALL SpriteFrameAddress
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  LD (DrawHeroFrameColumn+$0001),A
  LD A,(IX+$01)
  LD C,A
  LD B,$00
  LD HL,ScreenLineTable
  ADD HL,BC
  ADD HL,BC
  LD (SavedSP),SP
  LD SP,HL
  EX DE,HL
  LD BC,$0048
DrawHeroFrameLine:
  POP DE
  LD A,E
DrawHeroFrameColumn:
  ADD A,$00               ; ADD A,n: n = the column, written at $9D9B
  LD E,A
  LDI
  LDI
  LDI
  JP PE,DrawHeroFrameLine
  LD SP,(SavedSP)
  EI
  RET
