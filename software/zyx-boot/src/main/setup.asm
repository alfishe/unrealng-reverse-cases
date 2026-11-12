; --------------------------------------------------------------------------------------------------------------------
; setup.asm: The entry: save the caller's state, read the catalogue, IM 2, draw the screen, build the phases, the main loop
;
; Start $61A8 is the menu's only entry, called by the BASIC loader (src/basic, Loader $5D80) once the three pieces are
; in memory. It runs once from the CALL to the first file chosen: the launcher RunLetter $6A51 puts the saved SP back
; and returns to the loader.
;
; MainLoop $627C never waits for the interrupt: it runs as fast as the CPU allows between the interrupts, so the
; rhombi turn and the stars fall at a speed that depends on the machine.
; --------------------------------------------------------------------------------------------------------------------

; Save the caller's registers, read the catalogue, set up IM 2 and the music,
; draw the screen and build the rhombus phases
;
; Saves IY (SavedIY $AFC8), HL' (SavedHLAlt), SP (SavedSP) and I (SavedI).
; Reads 8 sectors from track 0, sector 0 (the catalogue) to Catalogue $9D00
; through TrdosEntry $3D13, still in IM 1. Then SP = MenuStack $FCBC, DI,
; Im2Table $FD00 filled with $FC, JP Interrupt at Im2Jump $FCFC, IM 2 with I =
; $FD. CALL $C00B (the music's init, src/music), DrawScreen $6510 (which also
; lists the catalogue), EI.
;
; The rhombi: copies RombSource $6E98 to RombWork $7700, RombColumnOrder to
; RombColumns $7600 and RombPhaseOffsets to RombOffsets $765C; BuildRombPhases
; $62F1 with threshold $40 writes set A, phases 0-8 at PhasesA $7800-$80FF, and
; MirrorSprite $63D6 the mirror images of phases 0-7 as phases 9-16 at MirrorsA
; $8100-$88FF. RotateSprite $6422 three times turns RombWork by 270 degrees;
; BuildRombPhases (threshold $80) writes set B at PhasesB $8A00, MirrorSprite
; the mirrors at MirrorsB $9300, and RotateSprite turns each of the 17 sprites
; $8A00-$9AFF by 90 degrees: set A turns about the vertical axis, set B about
; the horizontal one.
;
; DrawReflection $6DC6 draws the logo's mirror image at the bottom; the four
; rhombus steps start at 0, 5, 8 and 14 (PhaseTopLeft $B3B1-PhaseBottomRight
; $B3B4), MainTick at $FF; SampleStars $645E reads the 60 stars' pixels; then
; falls into MainLoop.
;
; Witness: L1 4 (c1-c4).
Start:
  LD (SavedIY),IY
  EXX
  LD (SavedHLAlt),HL
  LD (SavedSP),SP
  LD A,I
  LD (SavedI),A
  LD DE,$0000
  LD HL,Catalogue
  LD BC,$0805
  CALL TrdosEntry
  LD SP,MenuStack
  DI
  LD HL,Im2Table
  LD DE,Im2Table+1
  LD BC,$0100
  LD (HL),Im2Jump>>8
  LDIR
  LD HL,Interrupt
  LD (Im2Jump+1),HL
  LD A,$C3
  LD (Im2Jump),A
  IM 2
  LD A,Im2Table>>8
  LD I,A
  IFDEF MusicAfterScreen
  CALL DrawScreen         ; variant: the music starts after DrawScreen
  CALL MusicInit          ; variant: the two calls swapped
  ELSE
  CALL MusicInit
  CALL DrawScreen
  ENDIF
  EI
  LD HL,RombSource
  LD DE,RombWork
  LD BC,$00C8
  LDIR
  LD HL,RombColumnOrder
  LD DE,RombColumns
  LD C,$28
  LDIR
  LD HL,RombPhaseOffsets
  LD DE,RombOffsets
  LD C,$09
  LDIR
  LD DE,PhasesA
  LD A,$40
  LD (RombThreshold),A
  CALL BuildRombPhases
  LD HL,PhasesA
  LD DE,MirrorsA
  LD B,$08
StartMirrorA:
  PUSH BC
  CALL MirrorSprite
  INC H
  INC D
  POP BC
  DJNZ StartMirrorA
  LD HL,RombWork
  CALL RotateSprite
  CALL RotateSprite
  CALL RotateSprite
  LD DE,PhasesB
  LD A,$80
  LD (RombThreshold),A
  CALL BuildRombPhases
  LD HL,PhasesB
  LD DE,MirrorsB
  LD B,$08
StartMirrorB:
  PUSH BC
  CALL MirrorSprite
  INC H
  INC D
  POP BC
  DJNZ StartMirrorB
  LD B,$11
  LD HL,PhasesB
StartTurnB:
  PUSH BC
  CALL RotateSprite
  INC H
  POP BC
  DJNZ StartTurnB
  CALL DrawReflection
  LD A,$FF
  LD (MainTick),A
  INC A
  LD (PhaseTopLeft),A
  LD A,$05
  LD (PhaseTopRight),A
  LD A,$08
  LD (PhaseBottomLeft),A
  LD A,$0E
  LD (PhaseBottomRight),A
  CALL SampleStars

; The main loop: the falling stars and the turning rhombi, as fast as the CPU
; runs
;
; MainTick $B3B0 + 1 each pass. Every 2nd pass: MoveStars $6482 twice on StarsA
; $AC84 and twice on StarsB $ACFC (the operand MoveStars+2 set first). Every
; 4th: the top left rhombus (set A, at $4000, PhaseTopLeft) and the top right
; one (set B, at $401B, PhaseTopRight) one step (PrintRombPhase $64DA), and
; StarsC $AD74 once. Every 8th: the bottom left rhombus (set B, at $5060) and
; the bottom right (set A, at $507B). No HALT: the loop never ends; Interrupt
; $6757 does the rest (keys, music, twinkles, cursor) and the launcher leaves
; through the stack.
;
; Witness: L1 27670 (c1-c4).
MainLoop:
  LD A,(MainTick)
  INC A
  LD (MainTick),A
  LD A,(MainTick)
  AND $01
  CP $01
  JR NZ,MainEvery4
  LD HL,StarsA
  LD (MoveStars+$0002),HL
  CALL MoveStars
  CALL MoveStars
  LD HL,StarsB
  LD (MoveStars+$0002),HL
  CALL MoveStars
  CALL MoveStars
MainEvery4:
  LD A,(MainTick)            ; every 4th pass: the top rhombi, StarsC
  AND $03
  CP $03
  JR NZ,MainEvery8
  LD HL,Screen
  LD DE,PhasesA
  LD BC,PhaseTopLeft
  CALL PrintRombPhase
  LD HL,Screen+27
  LD DE,PhasesB
  LD BC,PhaseTopRight
  CALL PrintRombPhase
  LD HL,StarsC
  LD (MoveStars+$0002),HL
  CALL MoveStars
MainEvery8:
  LD A,(MainTick)            ; every 8th pass: the bottom rhombi
  AND $07
  CP $07
  JR NZ,MainLoop
  LD HL,Screen+4192
  LD DE,PhasesB
  LD BC,PhaseBottomLeft
  CALL PrintRombPhase
  LD HL,Screen+4219
  LD DE,PhasesA
  LD BC,PhaseBottomRight
  CALL PrintRombPhase
  JR MainLoop
