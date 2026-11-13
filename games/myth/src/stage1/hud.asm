; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The energy, the lives, the score, the HUD, game over and the stage exit
;
; The score is six decimal digits in two resident variables, ScoreHigh (two digits) and Score (four digits, 0-9999),
; so it carries from stage to stage. The energy (Energy, 0-$2E) changes by 2 a pass towards a pending EnergyChange;
; the HUD's six boxes at the top left show the lives, and the five boxes at the top right the pieces taken.
; --------------------------------------------------------------------------------------------------------------------

  ORG $79FC

; With item 6 selected, standing at the start place of room 2: leave the stage
;
; Every pass. Only in grid 0 (GridNumber 0), room 2 (the stage's first room)
; and with item 6 selected (GetSelectedItem): when the hero's x ($74E0) is
; 18-21 and its y ($74E1) is $5A, drops its own return address and runs
; StageExit. In stage 1 the selected item 6 at that place is the way out of the
; stage.
;
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
CheckStageExit:
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(GridNumber)
  CP $00
  RET NZ
  CALL GetSelectedItem
  CP $06
  RET NZ
  LD A,(HeroRecord)
  CP $12
  RET C
  CP $16
  RET NC
  LD A,(HeroY)
  CP $5A
  RET NZ

; The stage's exit effect: falling stars over a coloured field until FIRE or
; SPACE, then EndStage with E = 2
;
; StartStageExit draws the field and seeds 80 stars at $5B00 (4 bytes each);
; then each frame (HALT) moves the stars of speed 1-3 (MoveStar), until KeyFire
; or SPACE ($8A54); then E = 2 and EndStage.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
StarPixels:
  DEFB $40,$00,$10,$00,$04,$00,$01,$00
  DEFB $C0,$00,$30,$00,$0C,$00,$03,$00
  DEFB $C0,$C0,$30,$30,$0C,$0C,$03,$03
  DEFB $C0,$C0,$30,$30,$0C,$0C,$03,$03

; Clear the play area, colour it at random and seed 80 stars
;
; $A057, then clears the play area (column 0, lines $30-$BF, 32 bytes wide,
; from the blank $8BA3 with stride 0), RandomPlayAttrs, and 80 star records at
; $5B00: speed 1-4, pixel 0-3, column 2-29, y $80-$FF (random bytes from
; $8B85).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; $8B85, paper 0. Sets RandomPointer to $091D first, so the colours are the
; same each time.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; piece (PieceWaitsPickup) and by the enemies' deaths ($A065, $A19B, $A1CF,
; $A87B).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; $8BE3 writes Score as four digits at ScoreDigitsLow, $8C15 writes ScoreHigh
; as two at ScoreDigitsHigh, then RenderDigits draws the six characters into
; $7640 with a stride of 6.
;
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
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
; Witness: L1 10186 (c1o, deaths, s1-idle, s1-right).
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
; Witness: L1 10186 (c1o, deaths, s1-idle, s1-right).
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
; HL = the buffer, A = the buffer's stride (patched into $7BFA). Each
; character: 7 lines from DigitGlyphs + (char - '0') x 8 and an eighth line of
; 0, one byte column; HL moves one byte right per character.
;
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
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
ScoreDigits:
  DEFB $00,$00
ScoreDigitsHigh:
  DEFB $30,$30            ; ScoreHigh's two digits ($8C15); EndStage returns
                          ; this address in BC
ScoreDigitsLow:
  DEFB $30,$30,$30,$30    ; Score's four digits ($8BE3)
ScoreDigitsEnd:
  DEFB $00                ; 0: the end mark

  ORG $7DCD

; Start the lives boxes' flash
;
; LivesFlash = 0. Called by LoseLife and at the stage's start ($9821).
;
; Witness: L1 9 (c1o, deaths, s1-idle, s1-right).
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
; pass by $984D.
;
; Witness: L1 10246 (c1o, deaths, s1-idle, s1-right).
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

  ORG $7E9F

; Move the energy 2 a pass towards EnergyChange; at 0 lose a life
;
; EnergyChange 0: nothing. $80 and up (a drain): EnergyChange + 2 and Energy -
; 2; Energy at 0 calls LoseLife. Under $80 (a refill): EnergyChange - 2 and
; Energy + 2 up to $2E. Called every pass by $984D. Deaths recording: Energy 46
; down to 2, then the life lost at frame 2775 and the refill.
;
; Witness: L1 10246 (c1o, deaths, s1-idle, s1-right).
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
; $33 and $B22B (the hero's death). None left: E = $6C, GameOverTimer = 1 and
; $B22B. Called by ApplyEnergyChange and by $AC6C (the hero at column 0 or $20
; and up, or in a cell with bit 3 set). Deaths recording: Lives 5 to 4 at frame
; 2775.
;
; Witness: L1 7 (c1o, deaths, s1-right).
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

  ORG $82FA

; After a piece is taken: count it, draw its box on the HUD, start the flash,
; effect 12
;
; Only when PieceTakenFlag is 1 (cleared here). PiecesTaken + 1 (5:
; PiecesComplete = 1), PieceFlash = $2D, then CopyToScreen of a 2 x 14-byte
; picture ($E06C for the first piece, $E088 for the others) to column 24 +
; PiecesTaken, line $19; PlaySoundVector 12.
;
; Witness: L1 10189 (c1o, deaths, s1-idle, s1-right).
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
; PieceFlash - 1 a pass; the colour is the cycle at $B3D2[(PieceFlash + 2) & 7]
; for PiecesTaken + 1 cells at $5879 and $5899 (rows 3-4 from column 25).
;
; Witness: L1 10189 (c1o, deaths, s1-idle, s1-right).
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
; 10, line $18, 12 x 16 from the blank $8BA3) and draws the 8 x 8-byte GAME
; OVER picture at $CE92 at column 12, line $1C. $32 and on: the colour from the
; cycle ($B3C4) patched into the inline record GameOverBox and filled.
; s1-right: the HUD's GAME OVER (WALKTHROUGH 6.1, frame 4000).
;
; Witness: L1 10246 (c1o, deaths, s1-idle, s1-right).
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

; $8C3D's inline record: column 12, line 24, 8 x 2 cells, the colour (patched)
GameOverBox:
  DEFB $0C,$18,$08,$02,$00

; GameOverStep, continued: return
;
; Witness: L1 168 (s1-right).
GameOverStepDone:
  RET

  ORG $870C

; EnergyChange - C (a drain), unless the hero is dying (state $0F)
;
; C = the damage. Called by ShotHitsHero and the enemies ($8A43, $8A51, $8DEE,
; $921B, $96AB).
;
; Witness: L1 822 (c1o, deaths, s1-right).
DamageHero:
  LD A,(HeroState)
  CP $0F
  RET Z
  LD A,(EnergyChange)
  SUB C
  LD (EnergyChange),A
  RET

  ORG $8AB1

; Dissolve the HUD's 48 pixel lines onto the screen in 8 steps
;
; DE = the source picture (48 lines of 32 bytes; $7000 from StageSetUp $97AC:
; the HUD as loaded). Eight steps, each
;
; after a HALT: every byte of screen lines 0-47 = source AND a mask; the mask
; is one of 4 rows of 8 at $F9CC
;
; (resident; B = $F9, C = $CB + 1 + the step, the row picked by bits 3-4 of a
; ROM byte read through RandomPointer,
;
; reset to 0 each step so the pattern is the same every step) and gains bits
; each step until $FF. Patches the
;
; LD DE at $8AC5 (the source) and the ADD A at $8AE9 (the step).
;
; Witness: L1 2 (s1-idle, s1-right).
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

  ORG $8BE3

; Write HL as B decimal digits (ASCII) at IX
;
; B = 1-5 digits (the last B of 10000, 1000, 100, 10, 1 from DecimalTable);
; each digit by repeated subtraction.
;
; IX ends past the digits. PrintScore $7B73 writes the score $F9FB with 4
; digits into $7C22.
;
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
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
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
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

  ORG $A3C5

; Redraw the HUD's energy bar when the energy changed
;
; When Energy differs from EnergyShown: EnergyShown = Energy; the bar is Energy
; / 8 bytes of the pattern at $E43D, a last byte masked by BarMasks[Energy & 7]
; (written into BarEdgeMask), then zeros to 6 bytes; drawn on 6 screen lines
; from EnergyBarScreen ($4134). Called every pass from $984D.
;
; Witness: L1 10246 (c1o, deaths, s1-idle, s1-right).
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
BarMasks:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
