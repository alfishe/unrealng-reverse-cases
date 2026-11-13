; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The energy, the lives, the score, the HUD, game over and the stage exit
; --------------------------------------------------------------------------------------------------------------------

  ORG $7A2D

; With item 5 selected, in grid 8 room 1 at columns $10-$13: leave the stage
;
; Every pass. Only with item 5 selected (GetSelectedItem), in grid 8
; (GridNumber) room 1 and with the hero's x ($74E0) from $10 to $13: drops its
; own return address and runs StageExit (falls into it). Stage 1 tested item 6
; at the stage's first room and the hero's y too. Item 5 is the item RoomEvents
; $8212 gives in grid 9 once the five pieces are taken (SpawnItem with kind 5).
; In rzx-r4 the whole test passed once, at the end of the run (pass 7675), and
; the stage was left through StageExit; s4-right never had item 5 selected.
;
; Witness: L1 8620 (rzx-r4, s4-right).
CheckStageExit:
  CALL GetSelectedItem
  CP $05
  RET NZ
  LD A,(GridNumber)
  CP $08
  RET NZ
  LD A,(RoomNumber)
  CP $01
  RET NZ
  LD A,(HeroRecord)
  CP $10
  RET C
  CP $14
  RET NC

; The stage's exit effect: falling stars over a coloured field until FIRE or
; SPACE, then EndStage with E = 2
;
; StartStageExit draws the field and seeds 80 stars at $5B00 (4 bytes each);
; then each frame (HALT) moves the stars of speed 1-3 (MoveStar; a speed-4 star
; stays), until KeyFire or TestSpaceKey reports a key; then E = 2 and EndStage.
; As in stage 1 at `$7A1D`, with stage 4's addresses.
;
; Witness: L1 1 (rzx-r4).
StageExit:
  POP HL
  CALL StartStageExit
StageExitFrame:
  HALT
  LD IX,PlayBuffer
  LD B,$50
StageExitStar:
  PUSH BC
  LD A,(IX+$00)
  CP $04
  CALL C,MoveStar
  LD BC,$0004
  ADD IX,BC
  POP BC
  DJNZ StageExitStar
  CALL KeyFire
  JR Z,StageExitDone
  CALL TestSpaceKey
  JR Z,StageExitDone
  JR StageExitFrame
StageExitDone:
  LD E,$02
  JP EndStage

; Move one star down by its speed and plot it as two pixel lines
;
; IX = the star: +0 speed 1-4, +1 the pixel within the byte 0-3, +2 the column
; 2-29, +3 y ($80 and up: not yet on screen). Off screen: y += speed only. On
; screen: y = (y + speed) mod 128; IY = ScreenLineTable + 96 + 2y (line 48 +
; y); clears the star's column on speed lines from there down, then plots the
; two lines StarPixels[(speed - 1) x 8 + pixel x 2] under them. As stage 1's
; MoveStar `$7A4A`.
;
; Witness: L1 5974 (rzx-r4).
MoveStar:
  LD A,(IX+$03)
  CP $80
  JR C,MoveStarOnScreen
  ADD A,(IX+$00)
  LD (IX+$03),A
  RET
MoveStarOnScreen:
  ADD A,(IX+$00)
  CP $80
  JR C,MoveStarPlot
  SUB $80
MoveStarPlot:
  LD (IX+$03),A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,ScreenLineTable+96
  ADD HL,BC
  PUSH HL
  POP IY
  LD A,(IX+$00)
  DEC A
  SLA A
  SLA A
  SLA A
  LD C,A
  LD A,(IX+$01)
  SLA A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,StarPixels
  ADD HL,BC
  LD B,(IX+$00)
MoveStarClear:
  LD A,(IY+$00)
  ADD A,(IX+$02)
  LD E,A
  LD D,(IY+$01)
  LD A,$00
  LD (DE),A
  INC IY
  INC IY
  DJNZ MoveStarClear
  LD A,(IY+$00)
  ADD A,(IX+$02)
  LD E,A
  LD D,(IY+$01)
  INC IY
  INC IY
  LD A,(HL)
  LD (DE),A
  INC HL
  LD A,(IY+$00)
  ADD A,(IX+$02)
  LD E,A
  LD D,(IY+$01)
  LD A,(HL)
  LD (DE),A
  RET

; The two pixel lines of a star, by speed (rows 1-4) and pixel (pairs 0-3)
;
; Read by MoveStar $7AAE (LD HL,StarPixels; + (speed - 1) x 8 + pixel x 2):
; speed 1 a single pixel, speed 2 two pixels on one line, speeds 3-4 two pixels
; on two lines. Read in rzx-r4 (the stage exit).
StarPixels:
  DEFB $40,$00,$10,$00,$04,$00,$01,$00
  DEFB $C0,$00,$30,$00,$0C,$00,$03,$00
  DEFB $C0,$C0,$30,$30,$0C,$0C,$03,$03
  DEFB $C0,$C0,$30,$30,$0C,$0C,$03,$03

; Clear the play area, colour it at random and seed 80 stars
;
; ClearPlayBuffer, then clears 144 screen lines from line 48 (ScreenLineTable +
; 96), 30 bytes each from column 0; FillAttributes with the inline StageExitBox
; (columns 2-29, rows 6-23, attribute 0).
;
; Witness: L1 1 (rzx-r4).
StartStageExit:
  CALL ClearPlayBuffer
  LD IX,ScreenLineTable+96
  LD B,$90
StartStageExitLine:
  PUSH BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  INC IX
  INC IX
  LD B,$1E
StartStageExitByte:
  LD (HL),$00
  INC HL
  DJNZ StartStageExitByte
  POP BC
  DJNZ StartStageExitLine
  CALL FillAttributes

; FillAttributes' inline record: column 2, line $30, 28 x 18 cells, attribute 0
;
; The inline record after the CALL at $7B24, read by FillAttributes (it returns
; past it). Read in rzx-r4 (1 call).
StageExitBox:
  DEFB $02,$30,$1C,$12,$00

; StartStageExit, continued: random colours and 80 star records
;
; RandomPlayAttrs, then 80 records at $5B00: speed 1-4, pixel 0-3, column 2-29
; (Random & $1F, retried from $1C up), y $80-$FF (random bytes from Random
; $90AC).
;
; Witness: L1 1 (rzx-r4).
StartStageExitStars:
  CALL RandomPlayAttrs
  LD B,$50
  LD IX,PlayBuffer
SeedStar:
  PUSH BC
  CALL Random
  AND $03
  INC A
  LD (IX+$00),A
  CALL Random
  AND $03
  LD (IX+$01),A
SeedStarColumn:
  CALL Random
  AND $1F
  CP $1C
  JR NC,SeedStarColumn
  ADD A,$02
  LD (IX+$02),A
  CALL Random
  AND $7F
  ADD A,$80
  LD (IX+$03),A
  LD BC,$0004
  ADD IX,BC
  POP BC
  DJNZ SeedStar
  RET

; Fill the play area's attributes (28 x 16 cells) with bright inks 2-7 on black
;
; From $58C2 (row 6, column 2), 16 rows of 28 cells: bright, ink 2-7 from
; Random $90AC (0 and 1 retried), paper 0. Sets RandomPointer to $091D first,
; so the colours are the same each time. Called by StartStageExitStars $7B2C.
; As in stage 1 at `$7B27`.
;
; Witness: L1 1 (rzx-r4).
RandomPlayAttrs:
  LD IX,Attributes+194
  LD HL,$091D
  LD (RandomPointer),HL
  LD B,$10
RandomPlayAttrsRow:
  PUSH BC
  LD B,$1C
RandomPlayAttrsCell:
  PUSH BC
RandomPlayAttrsPick:
  CALL Random
  AND $07
  CP $02
  JR C,RandomPlayAttrsPick
  ADD A,$40
  LD (IX+$00),A
  INC IX
  POP BC
  DJNZ RandomPlayAttrsCell
  LD BC,$0004
  ADD IX,BC
  POP BC
  DJNZ RandomPlayAttrsRow
  RET

; Add BC points to the score
;
; Score += BC; at 10000 or more, Score -= 10000 and ScoreHigh += 1 (wrapping
; from 99 to 0). Outputs none; A, BC, HL destroyed. Callers: PieceTaken $8389
; (1200), $A1CB, $A1FE, $A224, the boss beaten $A28E (1400), $A347, $AB19.
;
; Witness: L1 45 (rzx-r4).
AddScore:
  LD HL,(Score)
  ADD HL,BC
  LD (Score),HL
  LD BC,$2710
  AND A
  SBC HL,BC
  RET C
  LD (Score),HL
  LD A,(ScoreHigh)
  INC A
  LD (ScoreHigh),A
  CP $64
  RET NZ
  LD A,$00
  LD (ScoreHigh),A
  RET

; Write the six score digits into ScoreDigits and draw them into the text
; buffer $7640
;
; NumberToDigits writes Score as four digits at ScoreDigitsLow, ByteToDigits
; writes ScoreHigh as two at ScoreDigitsHigh, then RenderDigits (JR) draws the
; six characters of ScoreDigits into $7640 with a stride of 6. Called by
; ShowScore and StageSetUp $977F.
;
; Witness: L1 8621 (rzx-r4, s4-right).
RenderScore:
  LD IX,ScoreDigitsLow
  LD HL,(Score)
  LD B,$04
  CALL NumberToDigits
  LD IX,ScoreDigitsHigh
  LD A,(ScoreHigh)
  CALL ByteToDigits
  LD HL,DigitBuffer
  LD A,$06
  LD IX,ScoreDigits
  JR RenderDigits

; Colour the score's leading zeros blue on black (unseen) and the rest yellow
;
; Builds six attributes at $6D00 ($06, yellow on black), sets $01 for each
; leading '0' of ScoreDigitsHigh on, and copies them to the HUD at $5826 (row
; 1, columns 6-11). Reached by ShowScore's JR. As in stage 1 at `$7B95`. The
; scan does not stop at the sixth digit: a score of 0 would run on into the end
; mark (0, not '0'), so it stops there.
;
; Witness: L1 8619 (rzx-r4, s4-right).
HideLeadingZeros:
  LD IX,ScoreDigitsHigh
  LD HL,ShadowAttributes
  LD DE,ShadowAttributes+$0001
  LD BC,$0005
  LD (HL),$06
  LDIR
  LD HL,ShadowAttributes
HideLeadingZerosNext:
  LD A,(IX+$00)
  CP $30
  JR NZ,HideLeadingZerosCopy
  INC IX
  LD (HL),$01
  INC HL
  JR HideLeadingZerosNext
HideLeadingZerosCopy:
  LD HL,ShadowAttributes
  LD DE,Attributes+38
  LD BC,$0006
  LDIR
  RET

; Draw the score on the HUD
;
; RenderScore, then CopyToScreen of the 6 x 8 bytes at $7640 to column 6, line
; 8 (stride 6), then HideLeadingZeros (JR). Every pass (MainLoop $7870).
;
; Witness: L1 8619 (rzx-r4, s4-right).
ShowScore:
  CALL RenderScore
  LD HL,DigitBuffer
  LD BC,$0608
  LD DE,$0608
  LD A,$06
  CALL CopyToScreen
  JR HideLeadingZeros

; Draw a string of digits into a byte buffer, 8 lines a character
;
; IX = a text record (two bytes skipped, then characters from '0' up, 0 ends),
; HL = the buffer, A = the buffer's stride (patched into the LD C,n at $7C39).
; Each character: 7 lines from DigitGlyphs + (char - '0') x 8 and an eighth
; line of 0, one byte column; HL moves one byte right per character. Callers:
; RenderScore (JR) and FormatItemCount (JP). As in stage 1 at `$7BD7`.
;
; Witness: L1 9379 (rzx-r4, s4-right).
RenderDigits:
  LD (RenderDigitsChar+$001C),A
  INC IX
  INC IX
RenderDigitsChar:
  LD A,(IX+$00)
  CP $00
  RET Z
  INC IX
  PUSH HL
  SUB $30
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,DigitGlyphs
  ADD HL,BC
  EX DE,HL
  POP HL
  PUSH HL
  LD C,$00
  LD B,$00
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  LD (HL),$00
  POP HL
  INC HL
  JR RenderDigitsChar

; The score as text: two unused bytes, ScoreHigh's two digits, Score's four
; digits, 0
;
; RenderScore's record for RenderDigits (IX = ScoreDigits, the first two bytes
; skipped). EndStageSave returns ScoreDigitsHigh in BC. Read every pass in both
; recordings.
ScoreDigits:
  DEFB $00,$00
ScoreDigitsHigh:
  DEFB $30,$30            ; ScoreHigh's two digits (ByteToDigits)
ScoreDigitsLow:
  DEFB $30,$30,$30,$30    ; Score's four digits (NumberToDigits)
ScoreDigitsEnd:
  DEFB $00                ; 0: the end mark

  ORG $7E0D

; Start the lives boxes' flash
;
; LivesFlash = 0. Callers: LoseLife $7F18, AnkhShrine $8ABC (a life gained) and
; StageSetUp $978B.
;
; Witness: L1 8 (rzx-r4, s4-right).
StartLivesFlash:
  LD A,$00
  LD (LivesFlash),A
  RET

; One step of the lives boxes' flash: up to white, then back to magenta (a
; life) or blue (lost)
;
; Idle when LivesFlash is $10. Steps 1-7: the six boxes' attributes at $5861
; and $5881 (rows 3-4, columns 1-6) get ink + 1 up to 7. Steps 8-15: ink - 1
; down to 3 (magenta) for box n while Lives >= n, else 1 (blue). Called every
; pass by PassTick $97CA. As in stage 1 at `$7DD2`.
;
; Witness: L1 8679 (rzx-r4, s4-right).
LivesFlashStep:
  LD A,(LivesFlash)
  CP $10
  RET Z
  LD IX,Attributes+97
  INC A
  LD (LivesFlash),A
  CP $08
  JR NC,LivesFlashDown
  LD B,$06
LivesFlashUp:
  LD A,(IX+$00)
  CP $07
  JR Z,LivesFlashUpNext
  INC (IX+$00)
  INC (IX+$20)
LivesFlashUpNext:
  INC IX
  DJNZ LivesFlashUp
  RET
LivesFlashDown:
  LD B,$06
LivesFlashDownBox:
  LD E,$03
  LD A,$07
  SUB B
  LD C,A
  LD A,(Lives)
  CP C
  JR NC,LivesFlashDownStep
  LD E,$01
LivesFlashDownStep:
  LD A,(IX+$00)
  CP E
  JR Z,LivesFlashDownNext
  DEC (IX+$00)
  DEC (IX+$20)
LivesFlashDownNext:
  INC IX
  DJNZ LivesFlashDownBox
  RET

  ORG $7ED7

; Move the energy 2 a pass towards EnergyChange; at 0 lose a life
;
; EnergyChange 0: nothing. $80 and up (a drain): EnergyChange + 2 and Energy -
; 2; Energy reaching 0 goes to LoseLife (JR). Under $80 (a refill):
; EnergyChange - 2 and Energy + 2 up to $2E. Called every pass by PassTick
; $97C1. In s4-right only refills ran (92 passes: the start's $2E and three
; after lost lives); the drain branch ($7EE1) ran in rzx-r4 (18 passes, no life
; lost).
;
; Witness: L1 8679 (rzx-r4, s4-right).
ApplyEnergyChange:
  LD A,(EnergyChange)
  CP $00
  RET Z
  CP $80
  JR C,ApplyEnergyRefill
  ADD A,$02
  LD (EnergyChange),A
  LD A,(Energy)
  CP $00
  RET Z
  SUB $02
  JR Z,LoseLife
  LD (Energy),A
  RET
ApplyEnergyRefill:
  SUB $02
  LD (EnergyChange),A
  LD A,(Energy)
  CP $2E
  RET NC
  ADD A,$02
  LD (Energy),A
  RET

; A life lost: Lives - 1, effect 7, flash the lives, freeze the hero; refill or
; game over
;
; Returns while the hero is dying (state $0F at $74EA; stage 1 tested Lives 0
; instead). Else Lives - 1, PlaySoundVector 7, StartLivesFlash, HeroFreeze =
; $17. Lives left: Energy 0, EnergyChange $2E (the refill), E = $33 and
; HeroDeath $B3AE (JP). None left: E = $6C, GameOverTimer = 1 and $B3AE.
; Callers: ApplyEnergyChange, $9380, SwitchedSpikes' test $9694 (grid 3 room
; 2), the hero at the room's edge $AE11 (column 0 or $1F and up), $B730 and
; $B739. s4-right: 526 calls, 522 of them from $AE11 while the hero was already
; dying, 4 lives lost (the last at the game over). rzx-r4 lost no life.
;
; Witness: L1 526 (s4-right).
LoseLife:
  LD A,(HeroState)
  CP $0F
  RET Z
  LD A,(Lives)
  DEC A
  LD (Lives),A
  LD DE,$0007
  CALL PlaySoundVector
  CALL StartLivesFlash
  LD A,$17
  LD (HeroFreeze),A
  LD A,(Lives)
  CP $00
  JR Z,LoseLastLife
  XOR A
  LD (Energy),A
  LD A,$2E
  LD (EnergyChange),A
  LD E,$33
  JP HeroDeath
LoseLastLife:
  LD E,$6C
  LD A,$01
  LD (GameOverTimer),A
  JP HeroDeath

  ORG $83A1

; Cycle the colours of the pieces' boxes while PieceFlash runs (always once all
; five are taken)
;
; PieceFlash - 1 a pass; the colour is CycleColours $B5BD[(PieceFlash + 2) & 7]
; for PiecesTaken + 1 cells at $5879 and $5899 (rows 3-4 from column 25).
; Called by MainLoop $783D. As in stage 1 at `$833B`.
;
; Witness: L1 8620 (rzx-r4, s4-right).
;
; In s4-right PieceFlash stayed 0; in rzx-r4 the boxes flashed after each piece
; (540 passes).
FlashPieces:
  LD A,(PieceFlash)
  LD E,A
  LD A,(PiecesTaken)
  CP $05
  JR Z,FlashPiecesStep
  LD A,E
  CP $00
  RET Z
FlashPiecesStep:
  LD A,E
  DEC A
  LD (PieceFlash),A
  ADD A,$02
  AND $07
  LD C,A
  LD B,$00
  LD HL,CycleColours
  ADD HL,BC
  LD A,(PiecesTaken)
  INC A
  LD B,A
  LD A,(HL)
  LD HL,Attributes+121
  LD DE,Attributes+153
FlashPiecesCell:
  LD (HL),A
  INC HL
  LD (DE),A
  INC DE
  DJNZ FlashPiecesCell
  RET

; After a piece is taken: count it, draw its box on the HUD, start the flash,
; effect 12
;
; Only when PieceTakenFlag is 1 (cleared here). PiecesTaken + 1 (5:
; PiecesComplete = 1), PieceFlash = $2D, then CopyToScreen of a 2 x 14-byte
; picture ($E27F for the first piece, $E29B for the others) to column $18 +
; PiecesTaken, line $19; PlaySoundVector 12 (JP). Called by MainLoop $783A. As
; in stage 1 at `$82FA`.
;
; Witness: L1 8620 (rzx-r4, s4-right).
;
; In s4-right no piece was taken; in rzx-r4 all five were (the first with the
; picture $E27F, the others with $E29B).
ShowPieceTaken:
  LD A,(PieceTakenFlag)
  DEC A
  RET NZ
  LD (PieceTakenFlag),A
  LD A,(PiecesTaken)
  INC A
  LD (PiecesTaken),A
  CP $05
  JR NZ,ShowPieceBox
  LD A,$01
  LD (PiecesComplete),A
ShowPieceBox:
  LD A,$2D
  LD (PieceFlash),A
  LD HL,PieceSprites
  LD A,(PiecesTaken)
  CP $01
  JR Z,ShowPieceBoxDraw
  LD HL,PieceSprite1
ShowPieceBoxDraw:
  LD A,(PiecesTaken)
  ADD A,$18
  LD B,A
  LD C,$19
  LD D,$02
  LD E,$0E
  LD A,$02
  CALL CopyToScreen
  LD DE,$000C
  JP PlaySoundVector

; After the last life: count GameOverTimer to $31, draw GAME OVER in the item
; strip, then cycle its colour
;
; GameOverTimer 0: nothing. 1-$30: + 1 a pass. At $31: clears the strip (column
; $0A, line $18, 12 x 16 from BlankIcon) and draws the 8 x 8-byte GAME OVER
; picture at $D01D at column $0C, line $1C. At $32: the colour from CycleColour
; $B5AF patched into the inline record GameOverBox and filled. Called by
; PassTick $97C7. As in stage 1 at `$836D`.
;
; Witness: L1 8679 (rzx-r4, s4-right).
;
; s4-right: the game over at the end (169 passes with GAME OVER shown). rzx-r4
; had no game over.
GameOverStep:
  LD A,(GameOverTimer)
  CP $00
  RET Z
  CP $32
  JR Z,GameOverColour
  INC A
  LD (GameOverTimer),A
  CP $31
  RET NZ
  LD HL,BlankIcon
  LD BC,$0A18
  LD DE,$0C10
  LD A,$00
  CALL CopyToScreen
  LD HL,GameOverPicture
  LD BC,$0C1C
  LD DE,$0808
  LD A,$08
  CALL CopyToScreen
GameOverColour:
  CALL CycleColour
  LD (GameOverBox+$0004),A
  CALL FillAttributes

; FillAttributes' inline record: column 12, line 24, 8 x 2 cells, the colour
; (patched)
;
; The inline record after the CALL at $8447, read by FillAttributes (it returns
; past it). Read in s4-right (169 calls).
GameOverBox:
  DEFB $0C,$18,$08,$02,$00

; GameOverStep, continued: return
;
; Part of GameOverStep, after its inline record.
;
; Witness: L1 169 (s4-right).
GameOverStepDone:
  RET

  ORG $861B

; EnergyChange - C (a drain), unless the hero is dying (state $0F)
;
; C = the damage. Callers: ShotHitsHero (falls in), ColumnHurts $8857,
; PendulumHurts $88FA, $9666, $9699 and $B77C. As in stage 1 at `$870C`.
;
; Witness: L1 16 (rzx-r4).
DamageHero:
  LD A,(HeroState)
  CP $0F
  RET Z
  LD A,(EnergyChange)
  SUB C
  LD (EnergyChange),A
  RET

  ORG $8FD6

; Dissolve the HUD's 48 pixel lines onto the screen in 8 steps
;
; DE = the source picture (48 lines of 32 bytes; $7000 from StageSetUp $9732:
; the HUD as loaded). Eight steps, each after a HALT: every byte of screen
; lines 0-47 = source AND a mask; the mask is DissolveMasks $F9CB + set + step
; (set = bits 3-4 of a ROM byte read through RandomPointer, 0, 8, 16 or 24; the
; step 0-7, the ADD at DissolveStepOperand set to 0 first) and gains bits each
; step until $FF; only RandomPointer's low byte is cleared each step, so each
; step reads the next 6 pages of the ROM and the pattern changes (rzx-r1: the
; first reads of the 8 steps at $0701, $0D01, $1301 ... $3101). Patches the LD
; DE at $8FEC (the source) and the ADD A at DissolveStepOperand (the step). As
; stage 1's DissolveHud `$8AB1`.
;
; Witness: L1 2 (rzx-r4, s4-right).
DissolveHud:
  LD (DissolveStep+$000C),DE
  LD B,$08
  LD A,$00
  LD (DissolveStepOperand+$0001),A
DissolveStep:
  PUSH BC
  HALT
  LD A,$00
  LD (RandomPointer),A
  LD IY,ScreenLineTable
  LD DE,$0000
  LD B,$30
DissolveLine:
  PUSH BC
  LD A,(IY+$00)
  ADD A,$00
  LD L,A
  LD H,(IY+$01)
  INC IY
  INC IY
  LD B,$20
DissolveByte:
  PUSH BC
  LD BC,(RandomPointer)
  INC BC
  LD (RandomPointer),BC
  LD A,(BC)
  AND $18
  ADD A,$CB
DissolveStepOperand:
  ADD A,$01               ; ADD A,n: n = the step 0-7
  LD C,A
  LD B,$F9
  LD A,(BC)
  LD C,A
  LD A,(DE)
  AND C
  LD (HL),A
  INC DE
  INC HL
  POP BC
  DJNZ DissolveByte
  POP BC
  DJNZ DissolveLine
  LD HL,DissolveStepOperand+$0001
  INC (HL)
  POP BC
  DJNZ DissolveStep
  RET

  ORG $910A

; Write HL as B decimal digits (ASCII) at IX
;
; B = 1-5 digits (the last B of 10000, 1000, 100, 10, 1 from DecimalTable);
; each digit by repeated subtraction. IX ends past the digits. RenderScore
; writes Score with 4 digits into ScoreDigitsLow.
;
; Witness: L1 8621 (rzx-r4, s4-right).
NumberToDigits:
  LD IY,DecimalTable
  LD A,$05
  SUB B
  JR Z,DigitLoop
  LD E,A
  SLA E
  LD D,$00
  ADD IY,DE
DigitLoop:
  PUSH BC
  LD A,$FF
  LD C,(IY+$00)
  LD B,(IY+$01)
DigitSubtract:
  SCF
  CCF
  INC A
  PUSH HL
  POP DE
  SBC HL,BC
  JR NC,DigitSubtract
  EX DE,HL
  ADD A,$30
  LD (IX+$00),A
  INC IX
  INC IY
  INC IY
  POP BC
  DJNZ DigitLoop
  RET

; Write A (0-99) as two ASCII digits at IX
;
; A = 0 writes "00"; else tens and units. RenderScore writes ScoreHigh so. The
; "00" branch $9140 ran in neither recording (ScoreHigh was not 0 in either).
;
; Witness: L1 8621 (rzx-r4, s4-right).
ByteToDigits:
  CP $00
  JR NZ,ByteToDigitsTens
  LD A,$30
  LD (IX+$00),A
  LD (IX+$01),A
  RET
ByteToDigitsTens:
  LD E,$FF
ByteToDigitsLoop:
  INC E
  SUB $0A
  JR NC,ByteToDigitsLoop
  ADD A,$3A
  LD (IX+$01),A
  LD A,E
  ADD A,$30
  LD (IX+$00),A
  RET

  ORG $A54D

; Redraw the HUD's energy bar when the energy changed
;
; When Energy differs from EnergyShown: EnergyShown = Energy; the bar is Energy
; / 8 bytes of a full pattern, a last byte masked by BarMasks[Energy & 7]
; (written into BarEdgeMask), then zeros to 6 bytes; drawn on 6 screen lines.
; Called every pass by PassTick `$97C4`. As in stage 1 at `$A3C5`.
;
; Witness: L1 8679 (rzx-r4, s4-right).
DrawEnergyBar:
  LD A,(EnergyShown)
  LD B,A
  LD A,(Energy)
  CP B
  RET Z
  LD A,(Energy)
  LD (EnergyShown),A
  LD A,(Energy)
  AND $07
  LD C,A
  LD B,$00
  LD HL,BarMasks
  ADD HL,BC
  LD A,(HL)
  LD (BarEdgeMask+$0001),A
  LD A,(Energy)
  SRL A
  SRL A
  SRL A
  LD C,A
  LD B,$06
  LD DE,EnergyBarScreen
  LD HL,EnergyBarPattern
DrawEnergyBarLine:
  PUSH BC
  PUSH HL
  PUSH DE
  LD A,C
  CP $00
  JR Z,DrawEnergyBarEdge
  LD B,A
DrawEnergyBarFull:
  LD A,(HL)
  LD (DE),A
  INC L
  INC DE
  DJNZ DrawEnergyBarFull
DrawEnergyBarEdge:
  LD A,(HL)
BarEdgeMask:
  AND $00                 ; AND n: n = BarMasks[Energy & 7] (written above)
  LD (DE),A
  INC DE
  LD A,$05
  SUB C
  JR Z,DrawEnergyBarNext
  LD B,A
  XOR A
DrawEnergyBarClear:
  LD (DE),A
  INC DE
  DJNZ DrawEnergyBarClear
DrawEnergyBarNext:
  POP DE
  POP HL
  INC D
  POP BC
  DJNZ DrawEnergyBarLine
  RET

; The left-aligned masks of 0-7 pixels for the bar's last byte
;
; 0, $80, $C0, $E0, $F0, $F8, $FC, $FE; read by DrawEnergyBar.
BarMasks:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
