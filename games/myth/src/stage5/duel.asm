; --------------------------------------------------------------------------------------------------------------------
; duel.asm: The duel with Dameron: the texts' timer, his four forms, his path, his missiles, the hits
;
; Dameron is a 15-column head on the right, drawn in three parts every pass: the face (7 bytes wide at column (X +
; $78) / 8), the dome (4 wide at (X + $B0) / 8) and the back (4 wide at (X + $D0) / 8), 128 lines from line 48 + Y
; (the line table ScreenLinePlay $9805). X (DameronX $FE3E) stays 0 (DameronPath moves only Y), so the columns are 15,
; 22 and 26. Y (DameronY $FE3F) starts at $8E, climbs one line a pass to $14 (DameronApproachStep), then follows
; DameronPath (one line up or down a pass, 128 steps).
;
; The phase DuelPhase $FE43: $FF the intro text (TextPassDelay, the timer DuelTimer $FE45 from $044C down by 2 a pass
; to $00A0: 470 passes), 0-3 Dameron's four forms, 4 won (the ending text). A hero shot on the hit line sets the
; pending hits PendingHits $FE41 = 2; DuelHit takes one a pass into the hit counter HitCounter $FE44; at 20 (10 shots)
; the phase steps, FormChanged $FE42 = 1 and NextDameronForm $A0C4 bursts the old form. Form 0 face DameronFace0
; $A43A, form 1 face DameronFace1 $ABBA, form 2 a 5-byte face DameronFace2 $AF3A, form 3 no face (the dome from
; DameronDome3 $B1BA); won: the dome and the back cleared and the final burst (FinalBurstShape).
;
; When the hits on Dameron complete a phase, DuelHit $79A9 calls NextDameronForm: phases 1-3 throw seven staggered
; explosions (shot records of kind 4 at HudPicture $7000) round his head; phase 4 bursts the head's 16 x 12 shape at
; FinalBurstShape $7AD7 into particles (StartBurst), which fly apart for 14 steps of two passes (UpdateBurst from the
; main loop), each an 8 x 8 glyph drawn and erased directly on the screen. The particle list is at Particles $7100 (4
; bytes a particle).
; --------------------------------------------------------------------------------------------------------------------

  ORG $79A9

; Take one pending hit a pass: count it, step the form every 20, flash
; Dameron's cells blue; while a text is up flash it instead
;
; Reached by a JP from ColourPlayArea every pass. TextShown $FE47 = 1 (a text
; page on screen, set by ShowTexts $8C87): FlashTextRows and return. Else when
; the pending hits PendingHits $FE41 are 0: return. Else PendingHits $FE41 - 1
; and the hit counter HitCounter $FE44 + 1; at $14 (20): HitCounter $FE44 = 0,
; the phase DuelPhase $FE43 + 1, FormChanged $FE42 = 1 and NextDameronForm
; $A0C4 (effect 0 and the bursts of the beaten form; the final burst at phase
; 4).
;
; Then (DuelHitFlash) the 15 x 16 cells from $58C0 + (Y AND $F8) x 4 + (X +
; $78) / 8 (Dameron's face and dome) get attribute 1 (blue on black) for this
; pass; ColourPlayArea recolours them on the next.
;
; A shot gives two hits (MoveShots sets PendingHits $FE41 to 2), so a form
; takes 10 shots and the duel 40. s5-right never hit Dameron ($79B7 never ran);
; rzx-r5 counted all 80 hits ($79B7 80 runs, 40 shots on the hit line) and won
; the duel.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
DuelHit:
  LD A,(TextShown)
  CP $01
  JP Z,FlashTextRows
  LD A,(PendingHits)
  CP $00
  RET Z
  DEC A
  LD (PendingHits),A
  LD A,(HitCounter)
  INC A
  LD (HitCounter),A
  CP $14
  JP NZ,DuelHitFlash
  LD A,$00
  LD (HitCounter),A
  LD A,(DuelPhase)
  INC A
  LD (DuelPhase),A
  LD A,$01
  LD (FormChanged),A
  CALL NextDameronForm
DuelHitFlash:
  LD A,(DameronY)            ; Dameron's cells blue for one pass
  AND $F8
  SLA A
  SLA A
  LD L,A
  LD H,$00
  LD BC,Attributes+192
  ADD HL,BC
  LD A,(DameronX)
  ADD A,$78
  SRL A
  SRL A
  SRL A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD C,$01
  LD B,$10
DuelHitFlashRow:
  LD (HL),C               ; 15 cells, then + $12 to the next row
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  INC L
  LD (HL),C
  LD DE,$0012
  ADD HL,DE
  DJNZ DuelHitFlashRow
  RET

; Flash the seven text rows' attributes red and magenta
;
; While a text page is shown (TextShown $FE47 = 1): FlashTextRow on the rows 8,
; 10, ..., 20 at column 16 ($5910, $5950, $5990, $59D0, $5A10, $5A50, $5A90),
; the rows CopyTextLine $8D89 copies the text lines to.
;
; Witness: L1 4440 (ending, rzx-r5, s5-right).
FlashTextRows:
  LD HL,Attributes+272
  CALL FlashTextRow
  LD HL,Attributes+336
  CALL FlashTextRow
  LD HL,Attributes+400
  CALL FlashTextRow
  LD HL,Attributes+464
  CALL FlashTextRow
  LD HL,Attributes+528
  CALL FlashTextRow
  LD HL,Attributes+592
  CALL FlashTextRow
  LD HL,Attributes+656
  CALL FlashTextRow
  RET

; Fill 12 attributes at HL with bright red ($42) on even passes, bright magenta
; ($43) on odd ones
;
; HL = the first attribute; the colour from PassCounter $FE4D bit 0. HL is left
; past the 12 cells.
;
; Witness: L1 31075 (ending, rzx-r5, s5-right).
FlashTextRow:
  LD E,$42
  LD A,(PassCounter)
  AND $01
  JP Z,FlashTextRowFill
  LD E,$43
FlashTextRowFill:
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  LD (HL),E
  INC L
  RET

  ORG $7AD7

; The final burst's shape: 12 rows of 16 bits, bits 7-14 set (a block 8
; fragments wide, 12 high)
;
; Read by StartBurst $91B9 (IX = $7AD7, D = 12, E = 9, A = 1) from $A0E2, at
; phase 4 (Dameron beaten): each set bit (bit 7 of the first byte first) puts a
; burst fragment at column D + bit, row E + row. Every row is $01, $FE.
FinalBurstShape:
  INCBIN "res/stage5/bitmaps-final-burst-2x12.bin",$0000,24

; Two more rows of FinalBurstShape's pattern that no code reads
;
; StartBurst $91B9 reads 24 bytes (12 rows of 2); these 4 bytes ($01, $FE, $01,
; $FE) continue the pattern up to AddScore. No code reads them: no operand
; points into them, and StartBurst $91B9 stops after 24 bytes.
FinalBurstShapeTail:
  DEFB $01,$FE,$01,$FE

  ORG $87C2

; The texts' timer, or Dameron: his approach and path, his three parts, the
; late forms' pacing
;
; Phase $FF (the intro), or 4 (won) with FormChanged $FE42 at 0: the text timer
; (DuelTextTimer): the timer DuelTimer $FE45 - 2 a pass and JP ShowTexts $8C87
; (the text pages), until it is $00A0. Then won stays on the ending (ShowTexts
; $8C87 every pass, the timer no longer counts); the intro starts the duel: the
; phase = 0, the timer = $FFC3 (so after the duel the ending waits while the
; timer's high byte is $FF or $FE before ShowTexts $8C87 shows it).
;
; Else (DuelMove): until the arrival flag DameronArrived $FE3D is set, Y - 1 a
; pass (DameronApproachStep) to $14, where DameronArrived $FE3D = 1; then the
; path index DameronPathIndex $FE40 + 1 and X, Y +=
; DameronPath[DameronPathIndex $FE40]. HL = ScreenLinePlay $9805 + 2 x Y
; (Dameron's top line, from line 48), DrawDameronFace, DrawDameronBack,
; DrawDameronDome; in form 3 and on PaceLateForms.
;
; s5-right: 470 intro passes, the approach from $8E to $14 in 122 passes, then
; the path.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
DuelStep:
  LD A,(DuelPhase)
  CP $FF
  JP Z,DuelTextTimer
  CP $04
  JP NZ,DuelMove
  LD A,(FormChanged)
  CP $01
  JP Z,DuelMove
DuelTextTimer:
  LD HL,(DuelTimer)
  LD A,H
  CP $00
  JP NZ,DuelTextCount
  LD A,L
  CP $A0
  JP Z,DuelTextDone
DuelTextCount:
  DEC HL
  DEC HL
  LD (DuelTimer),HL
  JP ShowTexts
DuelTextDone:
  LD A,(DuelPhase)
  CP $04
  JP Z,ShowTexts
  LD A,$00
  LD (DuelPhase),A
  LD HL,$FFC3
  LD (DuelTimer),HL
DuelMove:
  LD HL,DameronApproachStep
  LD A,(DameronArrived)
  CP $00
  JP NZ,DuelPathStep
  LD A,(DameronY)
  CP $14
  JP NZ,DuelApplyStep
  LD A,$01
  LD (DameronArrived),A
DuelPathStep:
  LD A,(DameronPathIndex)
  INC A
  LD (DameronPathIndex),A
  SLA A
  LD C,A
  LD B,$00
  LD HL,DameronPath
  ADD HL,BC
DuelApplyStep:
  LD A,(DameronX)
  ADD A,(HL)
  LD (DameronX),A
  INC HL
  LD A,(DameronY)
  ADD A,(HL)
  LD (DameronY),A
  LD HL,ScreenLinePlay
  LD A,(DameronY)
  LD C,A
  LD B,$00
  ADD HL,BC
  ADD HL,BC
  PUSH HL
  CALL DrawDameronFace
  POP HL
  PUSH HL
  CALL DrawDameronBack
  POP HL
  CALL DrawDameronDome
  LD A,(DuelPhase)
  CP $03
  JP NC,PaceLateForms
  RET

; Draw Dameron's face (form 0: $A43A, 1: $ABBA, 7 bytes; 2: $AF3A, 5 bytes; 3:
; none); clear the old one on a form change
;
; Phase 4 and on: return. HL = the line table from Dameron's Y (ScreenLinePlay
; $9805 + 2 x Y), patched into the three LD SP; the column (X + $78) / 8
; patched into the 7-byte draw, - 2 into the clear, + 2 into the 5-byte draw.
; 128 lines ($80), or $36 when Y is $5A or more. DI; SP walks the line table;
; each line LDIs the picture's bytes to the screen.
;
; Form 2 draws 5 bytes at column + 2, then (DrawFaceChange) on the pass
; FormChanged $FE42 is 1 clears 5 bytes of 128 lines at column - 2 and clears
; FormChanged $FE42; form 3 draws nothing and on that pass clears the 5 bytes
; at column + 2. Returns with EI.
;
; Witness: L1 6161 (ending, rzx-r5, s5-right).
DrawDameronFace:
  LD A,(DuelPhase)
  CP $04
  RET NC
  LD (DrawFaceWide+$0005),HL
  LD (DrawFaceNarrow+$0005),HL
  LD (DrawFaceClear+$000B),HL
  LD A,(DameronX)
  ADD A,$78
  SRL A
  SRL A
  SRL A
  LD (DrawFaceWideLine+$0003),A
  SUB $02
  LD (DrawFaceClearLine+$0003),A
  ADD A,$04
  LD (DrawFaceNarrowLine+$0003),A
  LD C,$80
  LD A,(DameronY)
  CP $5A
  JP C,DrawFaceSelect
  LD C,$36
DrawFaceSelect:
  DI
  LD HL,DameronFace0
  LD A,(DuelPhase)
  CP $00
  JP Z,DrawFaceWide
  LD HL,DameronFace1
  CP $01
  JP Z,DrawFaceWide
  LD HL,DameronFace2
  CP $03
  JP Z,DrawFaceChange
  JP DrawFaceNarrow
DrawFaceWide:
  LD (DrawSavedSP),SP
  LD SP,$0000
  LD A,C
  LD (LineCount),A
DrawFaceWideLine:
  POP DE
  LD A,E
  ADD A,$0E
  LD E,A
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,DrawFaceWideLine
  LD SP,(DrawSavedSP)
  EI
  RET
DrawFaceNarrow:
  LD (DrawSavedSP),SP
  LD SP,$0000
  LD A,C
  LD (LineCount),A
DrawFaceNarrowLine:
  POP DE
  LD A,E
  ADD A,$0E
  LD E,A
  LDI
  LDI
  LDI
  LDI
  LDI
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,DrawFaceNarrowLine
  LD SP,(DrawSavedSP)
  EI
DrawFaceChange:
  LD A,(FormChanged)
  CP $01
  RET NZ
  LD A,(DuelPhase)
  CP $02
  JP Z,DrawFaceClear
  CP $03
  RET NZ
  LD A,(DrawFaceClearLine+$0003)
  ADD A,$04
  LD (DrawFaceClearLine+$0003),A
DrawFaceClear:
  LD C,$80
  XOR A
  LD (FormChanged),A
  LD (DrawSavedSP),SP
  LD SP,$0000
  LD A,C
  LD (LineCount),A
  LD C,$00
DrawFaceClearLine:
  POP DE
  LD A,E
  ADD A,$0E
  LD E,A
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,DrawFaceClearLine
  LD SP,(DrawSavedSP)
  EI
  RET

; Draw the middle of Dameron's head (4 bytes x 128 lines at (X + $B0) / 8):
; $A7BA, $B1BA in form 3
;
; Phase 4 and on: return. HL = the line table, patched into the LD SP; the
; column patched into the ADD; DI, 128 lines of 4 LDIs, EI.
;
; Witness: L1 6161 (ending, rzx-r5, s5-right).
DrawDameronDome:
  LD A,(DuelPhase)
  CP $04
  RET NC
  LD (DrawDomeStart+$0005),HL
  LD A,(DameronX)
  ADD A,$B0
  SRL A
  SRL A
  SRL A
  LD (DrawDomeLine+$0003),A
  DI
  LD HL,DameronDome
  LD A,(DuelPhase)
  CP $03
  JP NZ,DrawDomeStart
  LD HL,DameronDome3
DrawDomeStart:
  LD (DrawSavedSP),SP
  LD SP,$0000
  LD A,$80
  LD (LineCount),A
DrawDomeLine:
  POP DE
  LD A,E
  ADD A,$0E
  LD E,A
  LDI
  LDI
  LDI
  LDI
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,DrawDomeLine
  LD SP,(DrawSavedSP)
  EI
  RET

; Draw the back of Dameron's head (4 bytes x 128 lines at (X + $D0) / 8,
; $A9BA); won: clear the head once
;
; HL = the line table, patched into two LD SP; the column into the draw, - 4
; into the clear. Phase under 4: DI, 128 lines of 4 LDIs (two NOPs after them),
; EI. Phase 4 (DrawBackGone): when FormChanged $FE42 is 1, clears it and clears
; 8 bytes of 128 lines from column (X + $D0) / 8 - 4 (the dome and the back).
;
; Witness: L1 6161 (ending, rzx-r5, s5-right).
DrawDameronBack:
  LD (DrawDameronBack+$002A),HL
  LD (DrawBackGone+$000F),HL
  LD A,(DameronX)
  ADD A,$D0
  SRL A
  SRL A
  SRL A
  LD (DrawBackLine+$0003),A
  SUB $04
  LD (DrawBackClearLine+$0003),A
  LD A,(DuelPhase)
  CP $04
  JP Z,DrawBackGone
  DI
  LD HL,DameronBack
  LD (DrawSavedSP),SP
  LD SP,$0000
  LD A,$80
  LD (LineCount),A
DrawBackLine:
  POP DE
  LD A,E
  ADD A,$0E
  LD E,A
  LDI
  LDI
  LDI
  LDI
  NOP
  NOP
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,DrawBackLine
  LD SP,(DrawSavedSP)
  EI
  RET
DrawBackGone:
  LD A,(FormChanged)
  CP $01
  RET NZ
  XOR A
  LD (FormChanged),A
  LD (DrawSavedSP),SP
  LD SP,$0000
  LD A,$80
  LD (LineCount),A
DrawBackClearLine:
  POP DE
  LD A,E
  ADD A,$0E
  LD E,A
  LD A,$00
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD (DE),A
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,DrawBackClearLine
  LD SP,(DrawSavedSP)
  EI
  RET

; Dameron's path after the approach: 128 steps of (dX, dY), dX always 0, dY +1
; or -1
;
; Read by DuelStep at DameronPath + 2 x the path index DameronPathIndex $FE40
; (a byte, so 128 steps that repeat): X += dX, Y += dY each pass. Twice: up 20,
; down 6, up 6, down 20, up 6, down 6 (no net move).
DameronPath:
  INCBIN "res/stage5/table-dameron-path.bin",$0000,256

; The approach's step (dX 0, dY -1): Dameron climbs from Y $8E to $14
;
; Read by DuelStep until the arrival flag DameronArrived $FE3D is set.
DameronApproachStep:
  DEFB $00,$FF

; Dameron's missiles, by form, on set passes; effect 2 each
;
; Nothing until the arrival flag DameronArrived $FE3D is set, or while the
; hero's state HeroState $BA82 is not 0. By the phase: 0, at PassCounter AND
; $1F = 0 or 7: a fireball (kind 1) at column (X + $80) / 8, line (Y + $50) AND
; $F8; 1, at 0 or 8: a bolt (kind 3) at (X + $78) / 8, line (Y AND $F8) + $30;
; 2, at 0: two bolts at (X + $88) / 8, lines (Y AND $F8) + $18 and (Y + $30)
; AND $F8, at 5: one at (Y AND $F8) + $20; 3, every 8 passes: an arcing shot
; (kind 2) at (X + $B0) / 8, line (Y AND $F8) + $20, path (PassCounter / 16)
; AND 3, step $FF. Each through FindFreeMissile and PlaySoundVector E = 2.
;
; s5-right: 196 fireballs in form 0.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
DameronFire:
  LD A,(DameronArrived)
  CP $00
  RET Z
  LD A,(HeroState)
  CP $00
  RET NZ
  LD A,(DuelPhase)
  CP $00
  JP Z,DameronFire0
  CP $01
  JP Z,DameronFire1
  CP $02
  JP Z,DameronFire2
  CP $03
  JP Z,DameronFire3
  RET
DameronFire0:
  LD A,(PassCounter)
  AND $1F
  JP Z,DameronFire0Shot
  CP $07
  RET NZ
DameronFire0Shot:
  CALL FindFreeMissile
  RET Z
  LD A,(DameronX)
  ADD A,$80
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(DameronY)
  ADD A,$50
  AND $F8
  LD (IX+$01),A
  LD (IX+$02),$01
  LD DE,$0002
  JP PlaySoundVector
DameronFire1:
  LD A,(PassCounter)
  AND $1F
  JP Z,DameronFire1Shot
  CP $08
  JP Z,DameronFire1Shot
  RET
DameronFire1Shot:
  CALL FindFreeMissile
  RET Z
  LD A,(DameronX)
  ADD A,$78
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(DameronY)
  AND $F8
  ADD A,$30
  LD (IX+$01),A
  LD (IX+$02),$03
  LD DE,$0002
  JP PlaySoundVector
DameronFire2:
  LD A,(PassCounter)
  AND $1F
  CP $05
  JP Z,DameronFire2Single
  CP $00
  RET NZ
  CALL FindFreeMissile
  RET Z
  LD A,(DameronX)
  ADD A,$88
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(DameronY)
  AND $F8
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$03
  CALL FindFreeMissile
  RET Z
  LD A,(DameronX)
  ADD A,$88
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(DameronY)
  ADD A,$30
  AND $F8
  LD (IX+$01),A
  LD (IX+$02),$03
  LD DE,$0002
  JP PlaySoundVector
DameronFire2Single:
  CALL FindFreeMissile
  RET Z
  LD A,(DameronX)
  ADD A,$88
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(DameronY)
  AND $F8
  ADD A,$20
  LD (IX+$01),A
  LD (IX+$02),$03
  LD DE,$0002
  JP PlaySoundVector
DameronFire3:
  LD A,(PassCounter)
  AND $07
  RET NZ
  CALL FindFreeMissile
  RET Z
  LD A,(DameronX)
  ADD A,$B0
  SRL A
  SRL A
  SRL A
  LD (IX+$00),A
  LD A,(DameronY)
  AND $F8
  ADD A,$20
  LD (IX+$01),A
  LD (IX+$02),$02
  LD A,(PassCounter)
  SRL A
  SRL A
  SRL A
  SRL A
  AND $03
  LD (IX+$03),A
  LD (IX+$04),$FF
  LD DE,$0002
  JP PlaySoundVector

  ORG $9076

; Move and draw the burst's particles one step (on the even passes)
;
; Called every pass by the main loop ($7869); acts only when PassCounter $FE4D
; is even. Nothing while BurstTimer $FE49 = $65 (set at $782E: no burst). Else
; BurstTimer + 1; at $1C ($0E when BurstSmall $FE48 is not 0) the burst ends
; (StopBurst). The step's glyph: BurstGlyphSteps[step + Random AND 3] x 8 +
; BurstGlyphs, written into ParticleGlyph's operand $915C.
;
; Each particle (4 bytes from Particles $7100, $FF ends the list, $80 a dead
; one): +2 the direction; 13-18 (the shape's right byte) become 0-5 and take
; the first set of steps, BurstSteps; 0-5 (the left byte) take the second,
; BurstStepsLeft. The step's index = BurstDirections[direction x 32 + step +
; (+3 AND 3)] (that sum doubled in the small mode); dx, dy = the pair at that
; index. The old cell is erased (EraseParticle, through TextPenShift $FE4A,
; TextScratch $FE4B); X + dx is kept when the sum is 1-30; Y - dy: a result of
; 0 leaves Y as it was, 26 and up kills the particle (+0 = $80, not drawn),
; else stored. Then the glyph's 8 bytes go to the screen cell (PlayLineTable[Y
; x 8] + X, INC H a line): a particle in rows 0-5 gets the address 0 + X
; (PlayLineTable's zero words) and writes into the ROM, i.e. is not shown.
;
; The even pass after StopBurst (BurstTimer $64) runs once more: $64 + 1 = $65
; is not the end value, so the step $65 is drawn (the glyph and step indexes
; read past BurstGlyphSteps and BurstDirections), then the next even pass sees
; $65 and stops.
;
; In s5-right no burst ran: only the tests of PassCounter $FE4D and BurstTimer
; $FE49 ran. rzx-r5 and ending ran the body from $908D 16 times each, at the
; win.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
UpdateBurst:
  LD A,(PassCounter)
  AND $01
  RET NZ
  LD E,$1C
  LD A,(BurstSmall)
  CP $00
  JR Z,UpdateBurstStep
  LD E,$0E
UpdateBurstStep:
  LD A,(BurstTimer)            ; BurstTimer = $65: idle
  CP $65
  RET Z
  INC A
  CP E
  JP Z,StopBurst
  LD (BurstTimer),A
  CALL Random
  AND $03
  LD C,A
  LD A,(BurstTimer)
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,BurstGlyphSteps
  ADD HL,BC
  LD C,(HL)
  SLA C
  SLA C
  SLA C
  LD B,$00
  LD HL,BurstGlyphs
  ADD HL,BC
  LD (ParticleGlyph+$0001),HL
  LD IY,Particles
UpdateBurstLoop:
  LD A,(IY+$00)           ; the next particle: $FF ends, $80 skipped
  CP $FF
  RET Z
  CP $80
  JP Z,UpdateBurstNext
  LD E,$01
  LD A,(IY+$02)
  CP $0A
  JR C,UpdateBurstDirection
  SUB $0D
  LD E,$00
UpdateBurstDirection:
  LD L,A                  ; HL = BurstDirections + direction x 32
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,BurstDirections
  ADD HL,BC
  LD A,(BurstTimer)
  LD C,A
  LD A,(IY+$03)
  AND $03
  ADD A,C
  LD C,A
  LD A,(BurstSmall)
  CP $00
  JR Z,UpdateBurstIndex
  SLA C
UpdateBurstIndex:
  LD B,$00
  ADD HL,BC
  LD C,(HL)
  SLA C
  LD B,$00
  LD HL,BurstSteps
  ADD HL,BC
  LD A,E
  CP $00
  JR Z,UpdateBurstMove
  LD BC,$0014
  ADD HL,BC
UpdateBurstMove:
  LD E,(HL)               ; E, D = dx, dy; erase the old cell
  INC HL
  LD D,(HL)
  LD A,(IY+$00)
  LD (TextPenShift),A
  LD A,(IY+$01)
  LD (TextScratch),A
  PUSH HL
  PUSH BC
  PUSH DE
  CALL EraseParticle
  POP DE
  POP BC
  POP HL
  LD A,(IY+$00)
  ADD A,E
  JR Z,UpdateBurstY
  CP $1F
  JR NC,UpdateBurstY
  LD (IY+$00),A
UpdateBurstY:
  LD A,(IY+$01)
  SUB D
  JR Z,UpdateBurstDraw
  CP $1A
  JR C,UpdateBurstStoreY
  LD (IY+$00),$80
  JP UpdateBurstNext
UpdateBurstStoreY:
  LD (IY+$01),A
UpdateBurstDraw:
  LD C,(IY+$01)           ; the cell's screen address from PlayLineTable
  SLA C
  SLA C
  SLA C
  LD B,$00
  LD HL,PlayLineTable
  ADD HL,BC
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  PUSH BC
  POP HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
ParticleGlyph:
  LD DE,$0000             ; LD DE,n: n = the step's glyph, written at $90B3
  LD BC,$0020
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  LD A,(DE)
  LD (HL),A
UpdateBurstNext:
  INC IY
  INC IY
  INC IY
  INC IY
  JP UpdateBurstLoop

; A RET no code reaches
;
; After UpdateBurst's JP UpdateBurstLoop; no CALL, JP or word in stage 5's
; block names $918A (work/stage2/stage5/B-raw.py).
UnusedRet:
  DEFB $C9

; BurstTimer = $64: the burst ends
;
; Reached by JP Z from $908F at the last step. As in stage 1 at $A393, the same
; code (stage 1's idle value; stage 5's idle value is $65, see UpdateBurst).
;
; Witness: L1 2 (ending, rzx-r5).
StopBurst:
  LD A,$64
  LD (BurstTimer),A
  RET

; 20 (dx, dy) steps: 10 for the right-byte particles, 10 for the left-byte ones
;
; Signed bytes (-1, 0, 1): dx added to the column, dy taken from the character
; row. UpdateBurst reads the pair BurstSteps + 2 x the index ($90FA; + $14 for
; the directions 0-5). The same use as stage 1's BurstSteps $A39D.
BurstSteps:
  INCBIN "res/stage5/table-burst-steps.bin",$0000,20
BurstStepsLeft:
  INCBIN "res/stage5/table-burst-steps.bin",$0014,20

; Turn a 16 x 12 shape into particles at $7100 that fly apart (UpdateBurst)
;
; Input: A = BurstSmall $FE48 (1 small: 14 steps of doubled moves; 0 big: 28),
; D, E = the shape's left column and top character row, IX = the shape (12 rows
; of 2 bytes, bit 7 the left). RandomPointer $FE0A = $0D7A (every burst flies
; the same way), BurstTimer $FE49 = $FF. Each set bit gives a particle of 4
; bytes at Particles $7100: X, Y, the direction (a Random 0-5, + 13 for the
; row's right byte), +3 a Random 0-3; X + 1 a bit, the next row at Y + 1, X -
; 16; $FF ends the list. Preserves IY. Unlike stage 1's StartBurst $A1F3 it
; plays no sound and sets no colours.
;
; Its only use: NextDameronForm $A0E6 (JP) at phase 4, D = 12, E = 9, A = 1, IX
; = FinalBurstShape $7AD7 (Dameron's head).
;
; Witness: L1 2 (ending, rzx-r5).
StartBurst:
  LD (BurstSmall),A
  LD HL,$0D7A
  LD (RandomPointer),HL
  PUSH IY
  LD A,$FF
  LD (BurstTimer),A
  LD IY,Particles
  LD B,$0C
StartBurstRow:
  PUSH BC
  LD B,$02
  LD L,$00
StartBurstByte:
  PUSH BC
  LD A,(IX+$00)
  LD (WorkByte),A
  LD B,$08
StartBurstBit:
  PUSH BC
  LD A,(WorkByte)
  BIT 7,A
  JR Z,StartBurstNextBit
  LD (IY+$00),D
  LD (IY+$01),E
StartBurstDirection:
  PUSH HL                 ; a Random 0-7 until under 6
  CALL Random
  POP HL
  AND $07
  CP $06
  JR NC,StartBurstDirection
  ADD A,L
  LD (IY+$02),A
  PUSH HL
  CALL Random
  POP HL
  AND $03
  LD (IY+$03),A
  INC IY
  INC IY
  INC IY
  INC IY
StartBurstNextBit:
  LD A,(WorkByte)
  SLA A
  LD (WorkByte),A
  INC D
  POP BC
  DJNZ StartBurstBit
  INC IX
  POP BC
  LD A,L
  ADD A,$0D
  LD L,A
  DJNZ StartBurstByte
  INC E
  LD A,D
  SUB $10
  LD D,A
  POP BC
  DJNZ StartBurstRow
  LD (IY+$00),$FF
  POP IY
  RET

; The burst's 8 x 8 particle glyphs: 0-3 from dense to sparse, 4-6 blank
;
; UpdateBurst writes BurstGlyphs + 8 x BurstGlyphSteps[...] into ParticleGlyph
; ($90AF); the indexes 0-3 are the four patterns, 4-6 (read only on the extra
; step $65, see UpdateBurst) are blank.
BurstGlyphs:
  INCBIN "res/stage5/bitmaps-particles-1x8.bin",$0000,32
BurstGlyphBlank:
  INCBIN "res/stage5/bitmaps-particles-1x8.bin",$0020,24

; Four zero bytes between the glyphs and BurstGlyphSteps
;
; No code reads them (UpdateBurst's glyph indexes stop at 6).
BurstUnused:
  DEFB $00,$00,$00,$00

; The glyph (0-3) at each burst step: index = step + a Random 0-3
;
; 35 bytes: 1, 0 at the first steps, then 1, 2 and 3, 2: the particles grow
; sparser as they fly. Read by UpdateBurst ($90A2: step 0-$1B + 0-3, the first
; 31 bytes; the extra step $65 reads past the table).
BurstGlyphSteps:
  INCBIN "res/stage5/table-burst-glyphs.bin",$0000,35

; Six direction tables of 32 step indexes (0-6 into BurstSteps); the first five
; here
;
; UpdateBurst reads BurstDirections + direction x 32 + (step + 0-3) ($90DA; the
; sum doubled in the small mode). The sixth table (direction 5,
; BurstDirectionsCut $932F) has only 26 bytes before EraseParticle's code at
; EraseParticle $9349: its indexes 26-31 read code bytes, and the small mode's
; doubled indexes up to 32 reach $934F.
BurstDirections:
  INCBIN "res/stage5/table-burst-directions.bin",$0000,160

; The sixth direction table (direction 5), cut to 26 bytes by EraseParticle's
; code
;
; Its indexes 26-31 (and the small mode's doubled ones up to 32) would read the
; code bytes of EraseParticle $9349 on: UpdateBurst does not check the table's
; end. rzx-r5 and ending read 13 of its bytes and 4 bytes of EraseParticle
; $9349 on: the overrun happens.
BurstDirectionsCut:
  INCBIN "res/stage5/table-burst-directions-cut.bin",$0000,26

; Clear the 8 x 8 screen cell of the particle at column $FE4A, row $FE4B
;
; HL = PlayLineTable[TextScratch $FE4B x 8] + TextPenShift $FE4A; 8 zero bytes,
; INC H a line. Called by UpdateBurst ($9119) before each particle moves.
; Corrupts A, BC, HL.
;
; Witness: L1 2754 (ending, rzx-r5).
EraseParticle:
  LD A,(TextScratch)
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,PlayLineTable
  ADD HL,BC
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  PUSH BC
  POP HL
  LD A,(TextPenShift)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,$00
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  RET

  ORG $A0C4

; Dameron's next form: seven explosions round his head, or at phase 4 the burst
;
; Called by DuelHit ($79D8) after the 20th hit of a phase has stepped the phase
; DuelPhase $FE43. PlaySoundVector $F9B0 with E = 0. Phase 1:
; SpawnFormExplosions1, 2: SpawnFormExplosions2, 3: SpawnFormExplosions3; any
; other (4): StartBurst (JP) with D = 12, E = 9 (column 12, row 9), A = 1
; (small: 14 steps), IX = FinalBurstShape $7AD7 (the head's 16 x 12 shape).
;
; Witness: L1 8 (ending, rzx-r5).
NextDameronForm:
  LD DE,$0000
  CALL PlaySoundVector
  LD A,(DuelPhase)
  CP $01
  JP Z,SpawnFormExplosions1
  CP $02
  JP Z,SpawnFormExplosions2
  CP $03
  JP Z,SpawnFormExplosions3
  LD D,$0C
  LD E,$09
  LD A,$01
  LD IX,FinalBurstShape
  JP StartBurst

; A RET no code reaches
;
; After NextDameronForm's JP StartBurst; no CALL, JP or word in stage 5's block
; names $A0E9 (work/stage2/stage5/B-raw.py).
UnusedRet2:
  DEFB $C9

; Seven explosions round Dameron's head for his second form (phase 1)
;
; The base: E = DameronX $FE3E / 8 + 14 (column), D = (DameronY $FE3F AND $F8)
; + $48 (line). Each explosion: FindFreeMissile $8C6C finds a free shot record
; (IX), then +0 = E + dx, +1 = D + dy, +2 = 4 (the kind: the explosion handler
; BurstMissile $819D), +4 = its start count (negative: the handler counts it up
; every second pass and shows nothing until it reaches 0, so the seven go off
; one after the other). (dx, dy, +4): (0, $10, $FF), (2, $18, $FC), (4, $20,
; $FA), (4, 8, $FE), (1, $18, $F6), (3, 8, $F9), (-1, $10, $F2).
;
; Each FindFreeMissile $8C6C is followed by RET Z, but FindFreeMissile $8C6C
; returns NZ both when it finds a record and when the eight are busy (then IX =
; MissilesEnd $7030, past the records): the RET Z is never taken.
;
; Witness: L1 2 (ending, rzx-r5).
SpawnFormExplosions1:
  LD A,(DameronX)
  SRL A
  SRL A
  SRL A
  ADD A,$0E
  LD E,A
  LD A,(DameronY)
  AND $F8
  ADD A,$48
  LD D,A
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD (IX+$00),E
  LD A,D
  ADD A,$10
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FF
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$02
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FC
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$04
  LD (IX+$00),A
  LD A,D
  ADD A,$20
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FA
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$04
  LD (IX+$00),A
  LD A,D
  ADD A,$08
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FE
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$01
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F6
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$03
  LD (IX+$00),A
  LD A,D
  ADD A,$08
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F9
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$FF
  LD (IX+$00),A
  LD A,D
  ADD A,$10
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F2
  RET

; Seven explosions round Dameron's head for his third form (phase 2)
;
; As SpawnFormExplosions1 with the base E = DameronX / 8 + 12, D = (DameronY
; AND $F8) + 8 and (dx, dy, +4): (0, $10, $FF), (2, $18, $FC), (4, $20, $FA),
; (3, 8, $FE), (1, $18, $F6), (1, $28, $F9), (-1, $20, $F2).
;
; Witness: L1 2 (ending, rzx-r5).
SpawnFormExplosions2:
  LD A,(DameronX)
  SRL A
  SRL A
  SRL A
  ADD A,$0C
  LD E,A
  LD A,(DameronY)
  AND $F8
  ADD A,$08
  LD D,A
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD (IX+$00),E
  LD A,D
  ADD A,$10
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FF
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$02
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FC
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$04
  LD (IX+$00),A
  LD A,D
  ADD A,$20
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FA
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$03
  LD (IX+$00),A
  LD A,D
  ADD A,$08
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FE
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$01
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F6
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$01
  LD (IX+$00),A
  LD A,D
  ADD A,$28
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F9
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$FF
  LD (IX+$00),A
  LD A,D
  ADD A,$20
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F2
  RET

; Seven explosions round Dameron's head for his fourth form (phase 3)
;
; As SpawnFormExplosions1 with the base E = DameronX / 8 + $13, D = DameronY
; AND $F8 and (dx, dy, +4): (0, 0, $FF), (2, $18, $FC), (1, 8, $FA), (-1, $28,
; $FE), (1, $18, $F6), (3, $18, $F9), (2, $10, $F2).
;
; Witness: L1 2 (ending, rzx-r5).
SpawnFormExplosions3:
  LD A,(DameronX)
  SRL A
  SRL A
  SRL A
  ADD A,$13
  LD E,A
  LD A,(DameronY)
  AND $F8
  LD D,A
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD (IX+$00),E
  LD A,D
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FF
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$02
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FC
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$01
  LD (IX+$00),A
  LD A,D
  ADD A,$08
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FA
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$FF
  LD (IX+$00),A
  LD A,D
  ADD A,$28
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$FE
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$01
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F6
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$03
  LD (IX+$00),A
  LD A,D
  ADD A,$18
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F9
  PUSH DE
  CALL FindFreeMissile
  POP DE
  RET Z
  LD A,E
  ADD A,$02
  LD (IX+$00),A
  LD A,D
  ADD A,$10
  LD (IX+$01),A
  LD (IX+$02),$04
  LD (IX+$04),$F2
  RET
