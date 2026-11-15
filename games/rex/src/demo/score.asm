; --------------------------------------------------------------------------------------------------------------------
; score.asm: The score, the lives, the shield figure, the HUD heat cell
; --------------------------------------------------------------------------------------------------------------------

; Fade the HUD's kill flash one step (attribute row $5840, 30 cells), then mark
; the latest kill's two cells white
;
; As REX 1's KillFlashFade $9992 (src/game/score.asm).
;
; Witness: L1 6752 (d1, demo-cycle).
KillFlashFade:
  LD HL,$5840
  LD B,$1E
FadeHudLoop:
  LD A,(HL)               ; each HUD attribute one step darker
  DEC A
  CP $FF
  JP Z,FadeHudNext
  LD (HL),A
FadeHudNext:
  INC HL                  ; the next cell
  DJNZ FadeHudLoop
  LD HL,(KillFlashPtr)
  LD (HL),$07
  INC HL
  LD (HL),$07
  RET

; Print Score $5EC7 in the HUD
;
; As REX 1's ShowScore $99AB (src/game/score.asm).
;
; Witness: L1 69 (d1, demo-cycle).
ShowScore:
  LD HL,(Score)
  CALL ToDigits
  LD E,$10
  LD L,$00
  LD B,$05
  CALL PrintDigits
  RET

; Print Lives $5EEC in the HUD
;
; As REX 1's ShowLives $99BB (src/game/score.asm).
;
; Witness: L1 8 (d1, demo-cycle).
ShowLives:
  LD A,(Lives)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD E,$17
  LD L,$00
  LD B,$01
  CALL PrintDigits
  RET

; ShieldDrainRate $5ED7 - 1: a hit on the shield drains it faster
; (EnemyBulletsHitRex, ObjectHitsRex)
;
; As REX 1's ShieldDrainFast $99CE (src/game/score.asm).
;
; Witness: L1 51 (d1, demo-cycle).
ShieldDrainFast:
  LD A,$01
  LD (ShieldDrainRate),A

; With the shield on, count ShieldDrainRate down; at 0 one unit of ShieldEnergy
; $5ED6 goes; none left switches the shield off
;
; As REX 1's ShieldDrain $99D3 (src/game/score.asm).
;
; Witness: L1 531 (d1, demo-cycle).
ShieldDrain:
  LD A,(ShieldDrainRate)
  DEC A
  LD (ShieldDrainRate),A
  OR A
  RET NZ
  LD A,$05
  LD (ShieldDrainRate),A
  LD A,(ShieldEnergy)
  SUB L
  JP C,ShieldOff
  LD (ShieldEnergy),A
  CALL ShowShield
  RET
ShieldOff:
  XOR A                   ; no energy: the shield off
  LD (ShieldEnergy),A
  LD (ShieldOn),A
  CALL ShowShield
  RET

; Print ShieldEnergy $5ED6 in the HUD and colour it: red when low, green
; otherwise ($E513, $E514 in the attribute shadow)
;
; As REX 1's ShowShield $99FA (src/game/score.asm).
;
; Witness: L1 475 (d1, demo-cycle).
ShowShield:
  LD A,(ShieldEnergy)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD E,$15
  LD L,$00
  LD B,$02
  CALL PrintDigits
  LD A,(ShieldEnergy)
  SRL A
  SRL A
  SRL A
  SRL A
  AND $07
  INC A
  LD ($5815),A
  LD ($5814),A
  LD (ShieldAttrs+$0001),A
  LD (ShieldAttrs),A
  RET

; The HUD cell $5817 (and its shadow $E516) in the colour HeatColour $6071
;
; Witness: L1 12 (d1, demo-cycle).
ShowHeat:
  LD A,(HeatColour)
  LD ($5817),A
  LD (HeatAttr),A
  RET

; The sound of an enemy bullet on the shield ($D9A9)
;
; Witness: L1 3 (d1, demo-cycle).
ShieldHitSound:
  LD DE,SfxShieldHit
  CALL StartSfx
  RET

; Leftover: HeatColour - 1, the count 100, ShowHeat, and at colour 2 RexDies;
; nothing calls it
;
; Witness: L1 0 ().
HeatLeftover:
  LD A,(HeatColour)
  DEC A
  LD (HeatColour),A
  LD HL,$0064
  LD (HeatCount),HL
  CALL ShowHeat
  CP $02
  RET NZ
  CALL RexDies
  RET

; Every 100 passes HeatColour + 1 up to 7, ShowHeat (RexDies sets it back to 7,
; NewGame to 7)
;
; Witness: L1 6752 (d1, demo-cycle).
HeatStep:
  LD HL,(HeatCount)
  DEC HL
  LD (HeatCount),HL
  LD A,L
  OR H
  RET NZ
  LD HL,$0064
  LD (HeatCount),HL
  LD A,(HeatColour)
  INC A
  CP $08
  RET Z
  LD (HeatColour),A
  CALL ShowHeat
  RET

; Score + DE (none while dying); ExtraLifeCount + DE, taken back by 200 when it
; reaches 200 (no extra life in the demo); ShowScore
;
; Changed from REX 1's AddScore $9A27 (src/game/score.asm).
;
; Witness: L1 69 (d1, demo-cycle).
AddScore:
  LD A,(Dying)
  OR A
  RET NZ
  LD HL,(Score)
  ADD HL,DE
  LD (Score),HL
  LD HL,(ExtraLifeCount)
  ADD HL,DE
  LD (ExtraLifeCount),HL
  LD DE,$00C8
  AND A
  SBC HL,DE
  JP C,AddScoreShow
  LD (ExtraLifeCount),HL
AddScoreShow:
  JP ShowScore            ; print it

; The screen flash of a smart bomb or a bonus: the attribute shadow faded
; through FadeSteps $90DD by FadeStepIndex $5ECB
;
; As REX 1's FadeStep $9A4C (src/game/score.asm).
;
; Witness: L1 6752 (d1, demo-cycle).
FadeStep:
  LD A,(FadeStepIndex)
  CP $FF
  RET Z
  LD E,A
  LD D,$00
  LD HL,FadeSteps
  ADD HL,DE
  LD A,(HL)
  CP $FF
  JP NZ,FadeStepAttr
  LD A,$FF
  LD (FadeStepIndex),A
  RET
FadeStepAttr:
  LD (Temp1),A            ; the step's attribute change
  LD HL,$5800
  LD DE,AttrShadow
  LD B,$40
FadeCells:
  LD A,(Temp1)            ; each cell of the shadow
  CP $01
  JP Z,FadeIncrease
  OR A
  JP Z,FadeDecrease
  CP $02
  JP Z,FadeCopy
FadeNextCell:
  INC HL                  ; the next cell
  INC DE
  DJNZ FadeCells
  LD A,(FadeStepIndex)
  INC A
  LD (FadeStepIndex),A
  RET
FadeCopy:
  LD A,(DE)               ; the shadow to the screen
  CP (HL)
  JP Z,FadeNextCell
  LD A,(HL)
  INC A
  AND $07
  LD (HL),A
  JP FadeNextCell
FadeIncrease:
  LD A,(HL)               ; a brighter step
  INC A
  CP $07
  JP Z,FadeNextCell
  AND $07
  LD (HL),A
  JP FadeNextCell
FadeDecrease:
  LD A,(HL)               ; a darker step
  DEC A
  OR A
  JP Z,FadeNextCell
  AND $07
  LD (HL),A
  JP FadeNextCell

; The fade's 17 steps: 1 six times, 0 five times, 2 six times, then $FF (the
; end)
;
; As REX 1's FadeSteps $9AB3 (src/game/score.asm).
FadeSteps:
  DEFB $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$FF
