; --------------------------------------------------------------------------------------------------------------------
; interrupts.asm: The interrupts: the title, the play passes and their scheduler
;
; In play the interrupt handler pointer $FDFE holds PlayInterrupt. One play interrupt is one pass of the game, and a
; pass takes two frames (the next frame's interrupt is lost under DI). The phase $7F65 cycles 1-4: phase 1 scrolls a
; column (ScrollStep $8AED) and starts the next one ($894D), phases 2-4 test and clear the hit grid ($9150, $91C6);
; each then runs the stars, the panel, the playfield, the play logic (PlayPass) and the next step of the drawing
; chain.
;
; The chain is three CALL BuildColumn ($896D) each followed by DI; RET (ChainBuildColumn1-3), then ChainEnd.
; BuildColumn enables the interrupts while it builds glyphs (EI at $8AA2, not in phase 4), so the next interrupt
; arrives inside a chain step: at depth 1 ($7F64) a pass runs its chain step itself; a nested pass (depth 2) instead
; overwrites the DI; RET of the step before its own with NOPs and leaves at once, so the interrupted step, when it
; returns from BuildColumn, falls into the next one. A slow frame thus draws the strips back to back; ChainEnd sets
; the phase to 0 and phase 1 restores the three DI; RET ($C9F3).
;
; The timing waits (DJNZ loops) put the border changes and the column building behind the beam. Evidence: TTD 48K c2
; frames 300-316: $7F62 +1 every 2 frames, $7F65 1, 2, 3, 4, 0, $7F66 $AAE5, $AAEA, $AAEF, $AAF4, $AAF9; L1:
; PlayInterrupt 659 entries in 48K c2, BuildColumn 688 (165/165/166 from the chain steps + 192 from $AFA3).
; --------------------------------------------------------------------------------------------------------------------

; Start, stop and step the fine scroll
;
; At phase 4 when the restart flag $81E3 is $FF: it becomes 0 and the scroll
; starts ($81DA bit 5). When $7F7B is not $FF the scroll stops (bit 5 cleared).
; Otherwise with the scroll on, or still between two cells ($7F6A not $C0), the
; fine scroll counter steps: $7F6B toggles $08/$10 and $7F6A takes it by XOR, a
; 2-bit Gray code $C0, $C8, $D8, $D0; $7F6C = $FF says the pass scrolls (0: it
; does not).
;
; Called by PlayPass. Evidence: TTD 48K c2 frames 300-316: $7F6A C8, D8, D0,
; C0, $7F6B 08/10, $7F6C FF.
ScrollControl:
  LD A,(PassPhase)
  CP $04
  JR NZ,ScrollControlRunning
  LD HL,ScrollRestart     ; the restart flag
  LD A,(HL)
  INC A
  JR NZ,ScrollControlRunning
  LD (HL),A
  LD HL,PlayFlags         ; the scroll on
  SET 5,(HL)
ScrollControlRunning:
  LD A,(DeathTimer)
  INC A
  JR Z,ScrollControlStep
  LD HL,PlayFlags         ; the scroll off
  RES 5,(HL)
  RET
ScrollControlStep:
  XOR A
  LD (ScrollThisPass),A
  LD HL,PlayFlags
  BIT 5,(HL)
  JR NZ,ScrollControlGray
  LD A,(ShiftPage)        ; stopped: only up to the cell boundary
  CP $C0
  RET Z
ScrollControlGray:
  LD HL,FineScrollToggle  ; the next fine position
  LD A,(HL)
  XOR $18
  LD (HL),A
  LD HL,ShiftPage
  XOR (HL)
  LD (HL),A
  LD A,$FF
  LD (ScrollThisPass),A
  RET

; Interrupt handler of the title and between screens
;
; Only sets the interrupt flag $7F96 = $80. Installed by WaitMenuRasterEnd and
; the game's screens ($852D, $ABE6, $ABF8, $B18B, $B1F2).
;
; On a 128K: the glue makes the LD HL,$7F96 at $A9E5 CALL PlayAtA9E5 ($5B21): a
; frame of the engine, then the load (src/game/setup.asm, glue.asm;
; docs/09-sound.md 9.2).
TitleInterrupt:
  PUSH HL
  LD HL,EffectTick
  LD (HL),$80
  POP HL
  EI
  RET

; Interrupt handler in play: one phase of a game pass
;
; Saves all registers. Phase 4 (a pass whose chain has not ended): nothing
; more. Otherwise $7F62 +1 (PassCount), $7F63 rotated (PassBit, the object bit
; of this pass), $7F64 +1 (depth), the phase $7F65 +1; $7F96 = $FF; the colour
; cycle $80BC 8, $10, $18; the three sound bit patterns $7F80, $7F84, $7F88
; shift one bit, the bit out into $7F7F, $7F83, $7F87.
;
; Phase 1: $8AED, the chain from its start ($7F66 = $AAE5), the three DI; RET
; restored, $894D, a wait of $0B (scroll on) or $2F x 16 DJNZ. Phases 2-3:
; $9150, $91C6, a wait of $10. Then the wait before the border black is $77
; DJNZ. (The 48K: 2, $26, 5 and $10; the Pentagon's counts are larger, its
; interrupt comes earlier in the frame and nothing is contended.) Then $8894,
; the panel update $AB13, a wait, the border black, $85CA, and PlayPass.
;
; Installed at $B1DF. Evidence: 48K c2 L1 659 entries, 12 permille own time.
;
; On a 128K: the glue makes the PUSH IX: PUSH IY at $A9F7 JP PlayAtA9F7 ($5B31)
; and a NOP: one engine step; with PlayAtAB03 the engine steps twice a pass in
; play (c1: 3220 times each), and a pass takes two TV frames, so one step a TV
; frame on average (src/game/setup.asm, glue.asm; docs/09-sound.md 9.8).
PlayInterrupt:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  EX AF,AF'
  EXX
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH IX
  PUSH IY

; l_A9FB
l_A9FB:
  LD A,(PassPhase)        ; a pass still in its chain: skip
  CP $04
  JP Z,PlayInterruptRestore
  LD HL,PassCount         ; PassCount
  INC (HL)
  LD HL,PassBit           ; PassBit
  RLC (HL)
  LD HL,PassDepth         ; depth
  INC (HL)
  LD HL,PassPhase         ; the phase
  LD A,(HL)
  INC A
  LD (HL),A
  LD A,$FF                ; the interrupt flag
  LD (EffectTick),A
  LD HL,ColourCycle       ; the colour cycle: 8, $10, $18
  LD A,(HL)
  ADD A,$08
  CP $20
  JR NZ,PlayInterruptColour
  LD A,$08
PlayInterruptColour:
  LD (HL),A
  LD HL,(SoundPattern1)   ; the sound bit patterns, one bit a pass
  ADD HL,HL
  LD (SoundPattern1),HL
  SBC A,A
  LD (RowBeepMask),A
  LD HL,(SoundPattern2)
  ADD HL,HL
  LD (SoundPattern2),HL
  SBC A,A
  LD (ObjectBeepMask),A
  LD HL,(SoundPattern3)
  ADD HL,HL
  LD (SoundPattern3),HL
  SBC A,A
  LD (SlotBeepMask),A
  LD A,(PassPhase)        ; phase 1: a new pass
  DEC A
  JR NZ,PlayInterruptPhase
  CALL ScrollStep
  LD HL,RunChainStep      ; the chain from its start
  LD (ChainStep),HL
  LD HL,$C9F3             ; F3 C9: DI; RET after each chain step again
  LD (ChainStep1End),HL
  LD (ChainStep2End),HL
  LD (ChainStep3End),HL
  CALL StartColumn
  LD A,$0B                ; the wait with the scroll on: $0B ($02 in the 48K)
  LD HL,PlayFlags
  BIT 5,(HL)
  JR NZ,PlayInterruptWait
  ADD A,$24               ; and without
  JR PlayInterruptWait
PlayInterruptPhase:
  CALL TestHitGrid        ; phases 2-4
  CALL ClearHitGrid
  LD A,$10                ; phases 2-3: $10 ($05 in the 48K)
PlayInterruptWait:
  LD B,$10
PlayInterruptDelay:
  DJNZ PlayInterruptDelay
  DEC A
  JP NZ,PlayInterruptWait
  CALL MoveStars
  CALL PanelFrame         ; the panel spinners, power and weapon marks
  LD A,$04
  LD B,$77                ; $77 ($10 in the 48K)
PlayInterruptDelay2:
  DJNZ PlayInterruptDelay2
  XOR A                   ; border black
  OUT ($FE),A
  CALL DrawPlayfield

; The play logic of a phase
;
; $ABD5, ScrollControl, $9463, $8F9B; in odd phases $90CB, in phase 2 $AD66; at
; depth 1 in phases 2-3 $8D45. Falls into PlayChain.
PlayPass:
  CALL CheckPauseAndEnd
  CALL ScrollControl
  CALL RunObjects
  CALL ObjectStrips
  LD A,(PassPhase)
  BIT 0,A
  CALL NZ,MarkEnemyGrid
  LD A,(PassPhase)
  CP $02
  CALL Z,WaveScriptStep
  LD A,(PassDepth)
  CP $01
  JR NZ,PlayChain
  LD A,(PassPhase)
  SUB $02
  CP $02
  CALL C,ResumeScript

; Advance the drawing chain
;
; A wait, the border black, the chain step $7F66 + 5. At depth 1 the step runs
; (RunChainStep) and returns to PlayInterruptExit; nested, the DI; RET before
; the step are replaced by two NOPs so the interrupted step continues into it.
PlayChain:
  LD A,$06
  LD B,$10
PlayChainDelay:
  DJNZ PlayChainDelay
  XOR A
  OUT ($FE),A
  LD HL,(ChainStep)       ; the next chain step
  LD DE,$0005
  ADD HL,DE
  LD (ChainStep),HL
  LD A,(PassDepth)        ; nested?
  CP $01
  JR Z,RunChainStep
  DEC HL                  ; NOP the DI; RET of the step before
  LD (HL),$00
  DEC HL
  LD (HL),$00
  JR PlayInterruptExit
RunChainStep:
  LD DE,PlayInterruptExit ; run it, returning to PlayInterruptExit
  PUSH DE
  JP (HL)

; Chain step 1: build cells of the new column
;
; CALL BuildColumn $896D then DI; RET (two NOPs when a nested pass chained step
; 2 on).
ChainBuildColumn1:
  CALL BuildColumn

; ChainStep1End
ChainStep1End:
  DI                      ; DI; RET or NOP; NOP
  RET

; Chain step 2: build cells of the new column
ChainBuildColumn2:
  CALL BuildColumn
ChainStep2End:
  DI                      ; DI; RET or NOP; NOP
  RET

; Chain step 3: build cells of the new column
ChainBuildColumn3:
  CALL BuildColumn
ChainStep3End:
  DI                      ; DI; RET or NOP; NOP
  RET

; The end of the chain: phase 0
;
; DI, $7F65 = 0, so the next interrupt starts a new pass.
ChainEnd:
  DI
  XOR A
  LD (PassPhase),A
  RET

; Leave the play interrupt
;
; Depth $7F64 down by one, all registers back, EI.
;
; On a 128K: the glue makes the POP IY: POP IX at $AB03 JP PlayAtAB03 ($5B3C)
; and a NOP: a frame of the engine (src/game/setup.asm, glue.asm;
; docs/09-sound.md 9.2).
PlayInterruptExit:
  LD HL,PassDepth
  DEC (HL)
; This entry point is used by the routine at l_A9FB.
PlayInterruptRestore:
  POP IY
  POP IX

; l_AB07
l_AB07:
  POP BC
  POP DE
  POP HL
  POP AF
  EXX
  EX AF,AF'
  POP BC
  POP DE
  POP HL
  POP AF
  EI
  RET
