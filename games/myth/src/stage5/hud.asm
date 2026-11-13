; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The energy, the lives, the score, the HUD and game over
;
; The routines stage 5 keeps from stage 1's HUD. The score is six decimal digits in the resident Score and ScoreHigh;
; stage 5 never adds to it (AddScore has no caller) and never shows it after the start (ShowScore has no caller;
; RevealScore $967E reveals it once). The energy (Energy $FE4F, $2E full) moves 2 a pass towards the pending
; EnergyChange $FE53; when it would reach 0 a life is lost and the hero explodes (state 1 of the hero record
; HeroRecord $BA7E). The six lives boxes flash after each life lost (LivesFlashStep).
;
; The HUD (screen lines 0-47) is stage 1's: the picture $7000 dissolved in, the boxes coloured by
; FillShadowAttributes, the score written by NumberToDigits and ByteToDigits, the energy bar drawn by DrawEnergyBar
; from Energy $FE4F.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7AF3

; Add BC points to the score
;
; As in stage 1 at $7B53, the same instructions. Score += BC; at 10000 or more,
; Score -= 10000 and ScoreHigh + 1 (wrapping from 99 to 0). Outputs none; A,
; BC, HL destroyed.
;
; No caller in stage 5's code: no CALL, JP or pointer to $7AF3 in the linear
; listing list-all.txt.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
; As in stage 1 at $7B73, the same code. $94F0 writes Score as four digits at
; ScoreDigitsLow, ByteToDigits $9524 writes ScoreHigh as two at
; ScoreDigitsHigh, then RenderDigits draws the six characters into DigitBuffer
; $7640 with a stride of 6. Called once by StageSetUp $95E4 (the stage's
; set-up).
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
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
; As in stage 1 at $7B95, the same code. Builds six attributes at $6D00 ($06,
; yellow on black), sets $01 for each leading '0' of ScoreDigitsHigh on, and
; copies them to the HUD at $5826 (row 1, columns 6-11). Reached only from
; ShowScore.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
  JP NZ,HideLeadingZerosCopy
  INC IX
  LD (HL),$01
  INC HL
  JP HideLeadingZerosNext
HideLeadingZerosCopy:
  LD HL,ShadowAttributes
  LD DE,Attributes+38
  LD BC,$0006
  LDIR
  RET

; Draw the score on the HUD
;
; As in stage 1 at $7BC3, the same code. RenderScore, then CopyToScreen of the
; 6 x 8 bytes at DigitBuffer $7640 to column 6, line 8, then HideLeadingZeros.
;
; No caller in stage 5's code: no CALL, JP or pointer to $7B66 in list-all.txt
; (stage 1 calls it every pass; stage 5's main loop does not).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
; As in stage 1 at $7BD7, the same code. IX = a text record (two bytes skipped,
; then characters from '0' up, 0 ends), HL = the buffer, A = the buffer's
; stride (patched into $7B9D). Each character: 7 lines from DigitGlyphs + (char
; - '0') x 8 and an eighth line of 0, one byte column; HL moves one byte right
; per character. Reached by JP from RenderScore and FormatItemCount.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
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
  JP RenderDigitsChar

; The score as text: two unused bytes, ScoreHigh's two digits, Score's four
; digits, 0
;
; Written by RenderScore (NumberToDigits $94F0 at ScoreDigitsLow, ByteToDigits
; $9524 at ScoreDigitsHigh), read by RenderDigits and HideLeadingZeros;
; EndStage returns ScoreDigitsHigh in BC. Loaded as 0, 0, '000000', 0.
ScoreDigits:
  DEFB $00,$00
ScoreDigitsHigh:
  DEFB $30,$30            ; ScoreHigh's two digits ($9524); EndStage returns
                          ; this address in BC
ScoreDigitsLow:
  DEFB $30,$30,$30,$30    ; Score's four digits ($94F0)
ScoreDigitsEnd:
  DEFB $00                ; 0: the end mark

  ORG $7D7F

; Start the lives boxes' flash
;
; As in stage 1 at $7DCD, the same instructions with LivesFlash at $FE55.
; LivesFlash = 0. Called by LoseLife and at the stage's start (the JP at
; $965A).
;
; Witness: L1 8 (ending, rzx-r5, s5-right).
StartLivesFlash:
  LD A,$00
  LD (LivesFlash),A
  RET

; One step of the lives boxes' flash: up to white, then back to magenta (a
; life) or blue (lost)
;
; As in stage 1 at $7DD2, the same instructions with Lives at $FE58 and
; LivesFlash at LivesFlash $FE55. Idle when LivesFlash is $10. Steps 1-7: the
; six boxes' attributes at $5861 and $5881 (rows 3-4, columns 1-6) get ink + 1
; up to 7. Steps 8-16: ink - 1 down to 3 (magenta) for box n while Lives >= n,
; else 1 (blue). Called every pass by MainLoop and by PassTick $966E (the idle
; passes at the start).
;
; Witness: L1 11786 (ending, rzx-r5, s5-right).
LivesFlashStep:
  LD A,(LivesFlash)
  CP $10
  RET Z
  LD IX,Attributes+97
  INC A
  LD (LivesFlash),A
  CP $08
  JP NC,LivesFlashDown
  LD B,$06
LivesFlashUp:
  LD A,(IX+$00)
  CP $07
  JP Z,LivesFlashUpNext
  INC (IX+$00)
  INC (IX+$20)
LivesFlashUpNext:
  INC IX
  DJNZ LivesFlashUp
  RET
LivesFlashDown:
  LD B,$06
LivesFlashBox:
  LD E,$03
  LD A,$07
  SUB B
  LD C,A
  LD A,(Lives)
  CP C
  JP NC,LivesFlashBoxInk
  LD E,$01
LivesFlashBoxInk:
  LD A,(IX+$00)
  CP E
  JP Z,LivesFlashDownNext
  DEC (IX+$00)
  DEC (IX+$20)
LivesFlashDownNext:
  INC IX
  DJNZ LivesFlashBox
  RET

  ORG $7E17

; Move the energy 2 a pass towards EnergyChange; at 0 lose a life
;
; As in stage 1 at $7E9F, with Energy at $FE4F and EnergyChange at $FE53.
; EnergyChange 0: nothing. $80 and up (a drain): EnergyChange + 2 and Energy -
; 2 (none at Energy 0); when Energy would reach 0 it is not stored and LoseLife
; runs. Under $80 (a refill): EnergyChange - 2 and Energy + 2 up to $2E. Called
; every pass by MainLoop and by PassTick $966E.
;
; The damage in stage 5 is odd (C = 9 at CheckShotHitsDamage $A361): from $F7
; the drain steps $F9, $FB, $FD, $FF, $01, and from then on EnergyChange swaps
; between $01 (a refill step to $FF, Energy + 2 below $2E) and $FF (a drain
; step to $01, Energy - 2) every pass until the next change; the bar flickers
; by 2. s5-right ran only the refill at the start (23 passes, Energy 0 to $2E);
; ending ran the damage 32 times (CheckShotHitsDamage) and lost 5 lives. The
; swap itself is known only from the code.
;
; Witness: L1 11786 (ending, rzx-r5, s5-right).
ApplyEnergyChange:
  LD A,(EnergyChange)
  CP $00
  RET Z
  CP $80
  JP C,ApplyEnergyRefill
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

; A life lost: the hero explodes, Lives - 1, effect 7, flash the lives, refill
; the energy
;
; Reached from ApplyEnergyChange when the drain would take Energy to 0. Returns
; if the hero's state HeroState $BA82 is not 0 (already exploding). Else the
; state = 1 (HeroControl runs the explosion, then state 2 or 3), EnergyChange =
; $30 (the refill), StartLivesFlash, Lives $FE58 - 1, and PlaySoundVector with
; E = 7. Unlike stage 1 it does not test Lives first: HeroControl ends the
; stage when the explosion ends with Lives at 0.
;
; Witness: L1 5 (ending).
LoseLife:
  LD A,(HeroState)
  CP $00
  RET NZ
  LD A,$01
  LD (HeroState),A
  LD A,$30
  LD (EnergyChange),A
  CALL StartLivesFlash
  LD A,(Lives)
  DEC A
  LD (Lives),A
  LD DE,$0007
  JP PlaySoundVector

  ORG $7E9D

; Count GameOverTimer to $31, draw GAME OVER in the item strip, then cycle its
; colour
;
; As in stage 1 at $836D, with GameOverTimer at $FE56. GameOverTimer 0:
; nothing. 1-$30: + 1 a pass. At $31: clears the strip (column 10, line $18, 12
; x 16 from the blank BlankIcon $94B0, stride 0) and draws the 8 x 8-byte GAME
; OVER picture at GameOverPicture $A367 at column 12, line $1C. $32 and on
; (GameOverColour): the colour from CycleColour $A021 patched into the inline
; record GameOverBox and filled. Called every pass by PassTick $966E, which
; runs only in the idle passes at the start ($9678).
;
; Nothing in stage 5 sets GameOverTimer: InitStageState $96DD clears it and no
; other code writes GameOverTimer $FE56 but this routine, so only the first
; test runs; stage 5's game over is the hero's count HeroGameOverCount $BA84
; (HeroControl).
;
; Witness: L1 90 (ending, rzx-r5, s5-right).
GameOverStep:
  LD A,(GameOverTimer)
  CP $00
  RET Z
  CP $32
  JP Z,GameOverColour
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

; $954E's inline record: column 12, line 24, 8 x 2 cells, the colour (patched)
;
; Read by FillAttributes $954E after the CALL at $7ED1; GameOverStep writes the
; colour (the last byte, $7ED8).
GameOverBox:
  DEFB $0C,$18,$08,$02,$00

; GameOverStep, continued: return
;
; Part of GameOverStep, after its inline record.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
GameOverStepDone:
  RET

; EnergyChange - C (a drain)
;
; C = the damage. Called by $A363 (a missile on the hero, C = 9). Unlike stage
; 1's DamageHero it does not test the hero's state.
;
; Witness: L1 32 (ending).
DamageHero:
  LD A,(EnergyChange)
  SUB C
  LD (EnergyChange),A
  RET

  ORG $941B

; Dissolve the HUD's 48 pixel lines onto the screen in 8 steps
;
; DE = the source picture (48 lines of 32 bytes; HudPicture $7000 from
; StageSetUp). Eight steps, each after a HALT: the low byte of RandomPointer
; $FE0A = 0 (the same pattern every step), then every byte of screen lines 0-47
; (ScreenLineTable $FB00) = source AND a mask; the mask is read at $F9CB + (a
; byte read through RandomPointer AND $18) + the step + 1 (the resident's
; DissolveMasks $F9CC: 4 rows of 8) and gains bits each step. Patches the LD DE
; at DissolveSource and the ADD A at DissolveStepOperand. As stage 1's
; DissolveHud $8AB1.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
DissolveHud:
  LD (DissolveSource+$0001),DE
  LD B,$08
  LD A,$00
  LD (DissolveStepOperand+$0001),A
DissolveStep:
  PUSH BC
  HALT
  LD A,$00
  LD (RandomPointer),A
  LD IY,ScreenLineTable
DissolveSource:
  LD DE,$0000             ; LD DE,n: n = the picture, written at $941B
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

  ORG $94B0

; 32 zero bytes: a blank source for clears done by copying
;
; Read by $7EAF (LD HL,$94B0, then BC = $0A18, DE = $0C10: a copy to the
; screen); s5-right read each of its bytes 9 times. Stage 1's BlankIcon $8BA3
; (the blank item icon and the source of the clears done by copying with stride
; 0).
BlankIcon:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

  ORG $94F0

; Write HL as B decimal digits (ASCII) at IX
;
; B = 1-5 digits (the last B of 10000, 1000, 100, 10, 1 from DecimalTable
; $F9BF); each digit by repeated subtraction. IX ends past the digits. Called
; from $7B1D (the score). As stage 1's NumberToDigits $8BE3.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
NumberToDigits:
  LD IY,DecimalTable
  LD A,$05
  SUB B
  JP Z,DigitLoop
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
  JP NC,DigitSubtract
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
; A = 0 writes "00"; else the tens by repeated subtraction of 10, then the
; units. Called from $7B27. In s5-right A was not 0 (the "00" branch never
; ran). As stage 1's ByteToDigits $8C15.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
ByteToDigits:
  CP $00
  JP NZ,ByteToDigitsTens
  LD A,$30
  LD (IX+$00),A
  LD (IX+$01),A
  RET
ByteToDigitsTens:
  LD E,$FF
ByteToDigitsLoop:
  INC E
  SUB $0A
  JP NC,ByteToDigitsLoop
  ADD A,$3A
  LD (IX+$01),A
  LD A,E
  ADD A,$30
  LD (IX+$00),A
  RET

  ORG $9744

; Redraw the HUD's energy bar when the energy changed
;
; When Energy $FE4F differs from EnergyShown $FE52: EnergyShown = Energy; the
; bar is Energy / 8 bytes of the pattern at EnergyBarPattern $BA78, a last byte
; masked by BarMasks[Energy AND 7] (written into BarEdgeMask's operand), then
; zeros up to 6 bytes; drawn on 6 screen lines from EnergyBarScreen $4134 (row
; 1, line 1, column 20; INC D a line). Called by the main loop ($785D) and
; PassTick. As stage 1's DrawEnergyBar $A3C5.
;
; Witness: L1 11786 (ending, rzx-r5, s5-right).
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
  JP Z,DrawEnergyBarEdge
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
  AND $00                 ; AND n: n = BarMasks[Energy AND 7], written at $9760
  LD (DE),A
  INC DE
  LD A,$05
  SUB C
  JP Z,DrawEnergyBarNext
  LD B,A
  XOR A
DrawEnergyBarZeros:
  LD (DE),A
  INC DE
  DJNZ DrawEnergyBarZeros
DrawEnergyBarNext:
  POP DE
  POP HL
  INC D
  POP BC
  DJNZ DrawEnergyBarLine
  RET

; The bar's last byte: 0 to 7 pixels from the left ($00, $80, $C0 ... $FE)
;
; Read by DrawEnergyBar ($975B) with Energy AND 7.
BarMasks:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE
