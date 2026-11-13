; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The energy, the lives, the score, the HUD, game over and the stage exit
; --------------------------------------------------------------------------------------------------------------------

  ORG $79EA

; Grid 1 room 2 with item 6 selected, the hero standing at columns 10-13: the
; stage's exit
;
; Returns unless GridNumber is 1, RoomNumber 2, the selected item
; (GetSelectedItem) of kind 6, the hero's column $74E0 10-13 and his state
; $74EA 0; then it runs on into StageExit (E = 2 at the end). Stage 1's
; CheckStageExit ($79FC) asks for grid 0 room 2 and BossPhase; stage 3 tests
; the grid. rzx-r3 ends the stage so (StageExit ran once; its screen 17128
; shows the stars).
;
; Witness: L1 6279 (rzx-r3, s3-right).
CheckStageExit:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $02
  RET NZ
  CALL GetSelectedItem
  CP $06
  RET NZ
  LD A,(HeroRecord)
  CP $0A
  RET C
  CP $0E
  RET NC
  LD A,(HeroState)
  CP $00
  RET NZ

; The stage's exit effect: falling stars over a coloured field until FIRE or
; SPACE, then EndStage with E = 2
;
; StartStageExit draws the field and seeds 80 stars at $5B00 (4 bytes each);
; then each frame (HALT) moves the stars of speed 1-3 (MoveStar), until KeyFire
; or SPACE ($88F5); then E = 2 and EndStage.
;
; Stage 1's StageExit at $7A1D is the same code.
;
; Witness: L1 1 (rzx-r3).
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
; screen: y = (y + speed) mod 128, clears the bytes above it (speed lines, from
; ScreenLineTable+96, line 48 down), and plots two lines from StarPixels (speed
; and pixel).
;
; Stage 1's MoveStar at $7A4A is the same code.
;
; Witness: L1 8004 (rzx-r3).
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
  XOR A
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
; Stage 1's StarPixels at $7ABA (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
StarPixels:
  DEFB $40,$00,$10,$00,$04,$00,$01,$00
  DEFB $C0,$00,$30,$00,$0C,$00,$03,$00
  DEFB $C0,$C0,$30,$30,$0C,$0C,$03,$03
  DEFB $C0,$C0,$30,$30,$0C,$0C,$03,$03

; Clear the play area, colour it at random and seed 80 stars
;
; $9FC7, then clears the play area (column 0, lines $30-$BF, 32 bytes wide,
; from the blank $8A44 with stride 0), RandomPlayAttrs, and 80 star records at
; $5B00: speed 1-4, pixel 0-3, column 2-29, y $80-$FF (random bytes from
; $8A26).
;
; Stage 1's StartStageExit at $7ADA is the same code.
;
; Witness: L1 1 (rzx-r3).
StartStageExit:
  CALL BlackOutPlayArea
  LD HL,BlankIcon
  LD BC,$0030
  LD DE,$2090
  LD A,$00
  CALL CopyToScreen
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
; $8A26, paper 0. Sets RandomPointer to $091D first, so the colours are the
; same each time.
;
; Stage 1's RandomPlayAttrs at $7B27 is the same code.
;
; Witness: L1 1 (rzx-r3).
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
; from 99 to 0). Outputs none; A, BC, HL destroyed. Called with 1200 for a
; piece (PieceWaitsPickup $8367) and by ScoreBurst200 ($9FDA), DragonBeaten
; ($A017, 2500), ThroneBossBeaten ($A032, 2000), ScoreBurst20 ($A051),
; ItemHandler ($A120) and FragmentActor ($AB66).
;
; Stage 1's AddScore at $7B53 is the same code.
;
; Witness: L1 41 (rzx-r3).
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
  XOR A
  LD (ScoreHigh),A
  RET

; Write the six score digits into ScoreDigits and draw them into the text
; buffer $7640
;
; $8A84 writes Score as four digits at ScoreDigitsLow, $8AB6 writes ScoreHigh
; as two at ScoreDigitsHigh, then RenderDigits draws the six characters into
; $7640 with a stride of 6.
;
; Stage 1's RenderScore at $7B73 is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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
  JP RenderDigits

; Colour the score's leading zeros blue on black (unseen) and the rest yellow
;
; Builds six attributes at $6D00 ($06, yellow on black), sets $01 for each
; leading '0' of ScoreDigitsHigh on, and copies them to the HUD at $5826 (row
; 1, columns 6-11).
;
; Stage 1's HideLeadingZeros at $7B95 is the same code.
;
; Witness: L1 6278 (rzx-r3, s3-right).
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
; 8, then HideLeadingZeros. Every pass.
;
; Stage 1's ShowScore at $7BC3 is the same code.
;
; Witness: L1 6278 (rzx-r3, s3-right).
ShowScore:
  CALL RenderScore
  LD HL,DigitBuffer
  LD BC,$0608
  LD DE,$0608
  LD A,$06
  CALL CopyToScreen
  JP HideLeadingZeros

; Draw a string of digits into a byte buffer, 8 lines a character
;
; IX = a text record (two bytes skipped, then characters from '0' up, 0 ends),
; HL = the buffer, A = the buffer's stride (patched into $7BE8). Each
; character: 7 lines from DigitGlyphs + (char - '0') x 8 and an eighth line of
; 0, one byte column; HL moves one byte right per character.
;
; Stage 1's RenderDigits at $7BD7 is the same code.
;
; Witness: L1 6990 (rzx-r3, s3-right).
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
; Stage 1's ScoreDigits at $7C1E (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
ScoreDigits:
  DEFB $00,$00
ScoreDigitsHigh:
  DEFB $30,$30            ; as in stage 1 at $7C20 (an operand of a matched
                          ; routine)
ScoreDigitsLow:
  DEFB $30,$30,$30,$30,$00 ; as in stage 1 at $7C22 (an operand of a matched
                           ; routine)

  ORG $7DBB

; Start the lives boxes' flash
;
; LivesFlash = 0. Called by LoseLife and at the stage's start (StageSetUp's
; last JP, $9782).
;
; Stage 1's StartLivesFlash at $7DCD is the same code.
;
; Witness: L1 6 (rzx-r3, s3-right).
StartLivesFlash:
  XOR A
  LD (LivesFlash),A
  RET

; One step of the lives boxes' flash: up to white, then back to magenta (a
; life) or blue (lost)
;
; Idle when LivesFlash is $10. Steps 1-7: the six boxes' attributes at $5861
; and $5881 (rows 3-4, columns 1-6) get ink + 1 up to 7. Steps 8-15: ink - 1
; down to 3 (magenta) for box n while Lives >= n, else 1 (blue). Called every
; pass by $9815.
;
; Stage 1's LivesFlashStep at $7DD2 is the same code.
;
; Witness: L1 6338 (rzx-r3, s3-right).
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

  ORG $7E84

; Move the energy 2 a pass towards EnergyChange; at 0 lose a life
;
; EnergyChange 0: nothing. $80 and up (a drain): EnergyChange + 2 and Energy -
; 2; Energy at 0 calls LoseLife. Under $80 (a refill): EnergyChange - 2 and
; Energy + 2 up to $2E. Called every pass by $9815. Deaths recording: Energy 46
; down to 2, then the life lost at frame 2775 and the refill.
;
; Stage 1's ApplyEnergyChange at $7E9F is the same code.
;
; Witness: L1 6338 (rzx-r3, s3-right).
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
  JP Z,LoseLife
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
; Returns if Lives is 0. Lives - 1, PlaySoundVector 7, StartLivesFlash,
; HeroFreeze = $17. Lives left: Energy 0, EnergyChange $2E (the refill), E =
; $33 and $B2C9 (the hero's death). None left: E = $6C, GameOverTimer = 1 and
; $B2C9. Called by HeroUpdate ($AE01, the hero's death) and jumped to from
; ApplyEnergyChange ($7E9B) and CheckWaterDeath ($8837, $885D). Deaths
; recording: Lives 5 to 4 at frame 2775.
;
; Stage 1's LoseLife at $7ECE is the same code.
;
; Witness: L1 4 (s3-right).
LoseLife:
  LD A,(Lives)
  CP $00
  RET Z
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

  ORG $837F

; After a piece is taken: count it, draw its box on the HUD, start the flash,
; effect 12
;
; Only when PieceTakenFlag is 1 (cleared here). PiecesTaken + 1 (5:
; PiecesComplete = 1), PieceFlash = $2D, then CopyToScreen of a 2 x 14-byte
; picture ($DECB for the first piece, $DEE7 for the others) to column 24 +
; PiecesTaken, line $19; PlaySoundVector 12.
;
; Stage 1's ShowPieceTaken at $82FA is the same code.
;
; Witness: L1 6279 (rzx-r3, s3-right).
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

; Cycle the colours of the pieces' boxes while PieceFlash runs (always once all
; five are taken)
;
; PieceFlash - 1 a pass; the colour is the cycle at $B4B1[(PieceFlash + 2) & 7]
; for PiecesTaken + 1 cells at $5879 and $5899 (rows 3-4 from column 25).
;
; Stage 1's FlashPieces at $833B is the same code.
;
; Witness: L1 6279 (rzx-r3, s3-right).
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

; After the last life: count GameOverTimer to $31, draw GAME OVER in the item
; strip, then cycle its colour
;
; GameOverTimer 0: nothing. 1-$30: + 1 a pass. At $31: clears the strip (column
; 10, line $18, 12 x 16 from the blank $8A44) and draws the 8 x 8-byte GAME
; OVER picture at $D328 at column 12, line $1C. $32 and on: the colour from the
; cycle ($B4A3) patched into the inline record GameOverBox and filled.
; s1-right: the HUD's GAME OVER (WALKTHROUGH 6.1, frame 4000).
;
; Stage 1's GameOverStep at $836D is the same code.
;
; Witness: L1 6338 (rzx-r3, s3-right).
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
  LD (GameOverColour+$000D),A
  CALL FillAttributes
  DEFB $0C,$18,$08,$02,$00

; GameOverStep, continued: return
;
; Stage 1's GameOverStepDone at $83A8 is the same code (a RET).
;
; Witness: L1 167 (s3-right).
GameOverStepDone:
  RET

  ORG $85C9

; EnergyChange - C (a drain), unless the hero is dying (state $0F)
;
; C = the damage. Called by UpdateThroneShot ($8100), VikingStand ($8D9C),
; TrollSwingCheck ($915A) and BogManActor ($91D0); jumped to from
; PyreFireDamage ($8804), DragonFireDamage ($8821) and CheckWaterDeath ($8845);
; TouchHero ($85AF) runs on into it.
;
; Stage 1's DamageHero at $870C is the same code.
;
; Witness: L1 26 (rzx-r3, s3-right).
DamageHero:
  LD A,(HeroState)
  CP $0F
  RET Z
  LD A,(EnergyChange)
  SUB C
  LD (EnergyChange),A
  RET

  ORG $8952

; Dissolve the HUD's 48 pixel lines onto the screen in 8 steps
;
; DE = the source picture (48 lines of 32 bytes; $7000 from StageSetUp $970D:
; the HUD as loaded). Eight steps, each
;
; after a HALT: every byte of screen lines 0-47 = source AND a mask; the mask
; is DissolveMasks $F9CB + set + step
;
; (set = bits 3-4 of a ROM byte read through RandomPointer, 0, 8, 16 or 24; the
; step 0-7, the ADD at DissolveStepOperand set to 0 first) and gains bits each
; step until $FF; only RandomPointer's low byte is cleared each step, so each
; step reads the next 6 pages of the ROM and the pattern changes (rzx-r1: the
; first reads of the 8 steps at $0701, $0D01, $1301 ... $3101). Patches the
;
; LD DE at $8966 (the source) and the ADD A at $898A (the step).
;
; Stage 1's DissolveHud at $8AB1 is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
DissolveHud:
  LD (DissolveStep+$000B),DE
  LD B,$08
  XOR A
  LD (DissolveStepOperand+$0001),A
DissolveStep:
  PUSH BC
  HALT
  XOR A
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

  ORG $8A84

; Write HL as B decimal digits (ASCII) at IX
;
; B = 1-5 digits (the last B of 10000, 1000, 100, 10, 1 from DecimalTable);
; each digit by repeated subtraction.
;
; IX ends past the digits. PrintScore $7B61 writes the score $F9FB with 4
; digits into $7C10.
;
; Stage 1's NumberToDigits at $8BE3 is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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
; A = 0 writes "00". PrintScore writes the amount $F9FD so; only the 0 branch
; ran.
;
; Stage 1's ByteToDigits at $8C15 is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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

  ORG $A33B

; Redraw the HUD's energy bar when the energy changed
;
; When Energy differs from EnergyShown: EnergyShown = Energy; the bar is Energy
; / 8 bytes of the pattern at $E21E, a last byte masked by BarMasks[Energy & 7]
; (written into BarEdgeMask), then zeros to 6 bytes; drawn on 6 screen lines
; from EnergyBarScreen ($4134). Called every pass from $9815.
;
; Stage 1's DrawEnergyBar at $A3C5 is the same code.
;
; Witness: L1 6338 (rzx-r3, s3-right).
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
; Stage 1's BarMasks at $A41C (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
BarMasks:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
