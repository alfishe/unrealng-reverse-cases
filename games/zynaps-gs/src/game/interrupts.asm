; --------------------------------------------------------------------------------------------------------------------
; interrupts.asm: The interrupts: the title, the play passes and their scheduler
;
; In play the interrupt handler pointer $FDFE holds PlayInterrupt. One pass of the game is spread over the frames by
; the phase $7F65: the interrupt of phase 1 starts a pass (moves the objects $8AED, prepares the strips $894D), the
; next ones (phases 2-3) run the sprites and collisions ($9150, $91C6); each runs the scroll and the play logic
; (PlayPass), then the next step of the drawing chain.
;
; The chain is three CALL DrawStrips ($896D) each followed by DI; RET (ChainDrawStrips1-3), then ChainEnd. DrawStrips
; enables the interrupts while it draws, so the next interrupt arrives inside a chain step: at depth 1 ($7F64) a pass
; runs its chain step itself; a nested pass (depth 2) instead overwrites the DI; RET of the step before its own with
; NOPs and leaves at once, so the interrupted step, when it returns from DrawStrips, falls into the next one. A slow
; frame thus draws the strips back to back; ChainEnd sets the phase to 0 and phase 1 restores the three DI; RET
; ($C9F3).
;
; The timing waits (DJNZ loops) put the border changes and the strip drawing behind the beam. Evidence: TTD c2 frames
; 300-316: $7F62 +1 every 2 frames, $7F65 1, 2, 3, 4, 0, $7F66 $AAE5, $AAEA, $AAEF, $AAF4, $AAF9; L1: PlayInterrupt
; 659 entries in c2, DrawStrips 688 (165/165/166 from the chain steps + 192 from $AFA3).
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
; Called by PlayPass. Evidence: TTD c2 frames 300-316: $7F6A C8, D8, D0, C0,
; $7F6B 08/10, $7F6C FF.
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
; restored, $894D, a wait of 2 (scroll on) or $26 x 16 DJNZ. Phases 2-3: $9150,
; $91C6, a wait of 5. Then $8894, the panel update $AB13, a wait, the border
; black, $85CA, and PlayPass.
;
; Installed at $B1DF. Evidence: c2 L1 659 entries, 12 permille own time.
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
  LD HL,(SoundPattern1)   ; the sound bit patterns, one bit a pass (GS: the
                          ; installer writes GateStub and TitleEntry over these
                          ; 33 bytes: the effects gate's countdown and the
                          ; title module's load)
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
PlayInterruptPass:
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
  LD A,$02                ; the wait with the scroll on
  LD HL,PlayFlags
  BIT 5,(HL)
  JR NZ,PlayInterruptWait
  ADD A,$24               ; and without
  JR PlayInterruptWait
PlayInterruptPhase:
  CALL TestHitGrid        ; phases 2-3
  CALL ClearHitGrid
  LD A,$05
PlayInterruptWait:
  LD B,$10
PlayInterruptDelay:
  DJNZ PlayInterruptDelay
  DEC A
  JP NZ,PlayInterruptWait
  CALL MoveStars
  CALL PanelFrame         ; the panel spinners, power and weapon marks
  LD A,$04
  LD B,$10
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

; Chain step 1: draw the strips
;
; CALL DrawStrips $896D then DI; RET (two NOPs when a nested pass chained step
; 2 on).
ChainDrawStrips1:
  CALL BuildColumn

; ChainStep1End
ChainStep1End:
  DI                      ; DI; RET or NOP; NOP
  RET

; Chain step 2: draw the strips
ChainDrawStrips2:
  CALL BuildColumn
ChainStep2End:
  DI                      ; DI; RET or NOP; NOP
  RET

; Chain step 3: draw the strips
ChainDrawStrips3:
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
PlayInterruptExit:
  LD HL,PassDepth
  DEC (HL)
; This entry point is used by the routine at PlayInterrupt.
PlayInterruptRestore:
  POP IY
  POP IX
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
