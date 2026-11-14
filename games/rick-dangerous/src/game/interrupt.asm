; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 vector table
;
; SetUpInterrupts $A215 points the IM 2 table at the handler at $FEFE: it saves every register, counts the frame in
; FrameTicks $A237, calls $E49B, runs the slot at $FF11 (SoundTick on a 128K), restores and returns with EI. The frame
; loop ($E40F-$E41C) clears the count and waits in WaitFrames $A22A for one frame; each scroll step waits for four.
;
; I = $83 and the table $8300-$8400 all $FE ($A21B): every interrupt vectors to Im2Handler $FEFE. It counts frames
;
; in $A237 (waited on by $A22A), ticks the counter at $E49B and, once the music is in RAM 1, calls the player:
;
; $A081 writes CALL $A030 over the three NOPs at $FF11.
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 vector table: 257 bytes `$FE` written at the entry (`$A215`, I =
; `$83`), 0 as loaded
;
; `$A215` fills `$8300-$8400` with `$FE` and sets I = `$83`, so any data bus
; value gives the vector `$FEFE`, the handler. With the Spectrum's idle bus
; (`$FF`) every interrupt reads `$83FF` and `$8400` (every routine of the
; recordings shows that read: the interrupt's acceptance booked to the
; interrupted instruction).
Im2Table:
  DEFS $0101

  ORG $A215

; IM 2 with a 257-byte table of $FE: the handler at $FEFE
;
; Fills $8300-$8400 with $FE, I = $83, IM 2, EI. Called once from Start (c1: 1
; run).
;
; Output: A, B, HL changed.
;
; Witness: L1 1 (c1).
SetUpInterrupts:
  DI
  LD HL,Im2Table
  LD B,$00
FillVectorTable:
  LD (HL),$FE
  INC HL
  DJNZ FillVectorTable
  LD (HL),$FE
  LD A,$83
  LD I,A
  IM 2
  EI
  RET

; Wait until C frames have been counted since the last wait, then clear the
; count
;
; Input: C the number of frames. Enables interrupts, loops until FrameTicks >=
; C, then FrameTicks = 0. Output: A, F changed.
;
; The frame loop waits for 1 ($E41C, after clearing FrameTicks at $E411 behind
; a HALT); each scroll step waits for 4 ($ADD5, $AE0C).
;
; Witness: L1 43086 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
WaitFrames:
  EI
WaitFramesLoop:
  LD A,(FrameTicks)
  CP C
  JP C,WaitFramesLoop
  XOR A
  LD (FrameTicks),A
  RET

; The frame count: +1 each interrupt ($FF07-$FF0B), cleared by WaitFrames and
; the frame loop ($E411)
;
; Only the first byte is used.
FrameTicks:
  DEFB $00,$00

  ORG $FEFE

; The frame interrupt: frame counter, timers, music
;
; Saves AF, BC, DE, HL, IX, IY; `$A237` + 1; CALL `$E49B`; at `$FF11` three
; NOPs in the image, CALL `$A030` once
;
; `$A081` has run; restores, EI, RET.
;
; Witness: L1 113425 (beeper48, c1, controls, emptygun, ending, ending2,
; gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44,
; spotL1Z4-47).
Im2Handler:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
Im2CountFrame:
  LD A,(FrameTicks)       ; Frame counter $A237 + 1
Im2CountInc:
  INC A
Im2CountStore:
  LD (FrameTicks),A
  CALL FrameTick
Im2MusicCall:
  NOP                     ; patched to CALL $A030 by $A081
  NOP
  NOP
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RET

; Residue of a 48K BASIC session the tape carries: never read
;
; Bytes the tape's last group holds, read by no code: the leftovers of the
; developers' BASIC memory. The ROM's
;
; machine stack (return addresses such as `$1B76` and `$1303` at `$FF52`) and,
; at `$FF57`, RAMTOP's GO SUB stack
;
; marker `$3E`.
BasicStackResidue:
  DEFB $CE,$0B,$E3,$50,$1E,$17,$DC,$0A
  DEFB $CE,$0B,$E4,$50,$1D,$17,$DC,$0A
  DEFB $D7,$18,$02,$00,$38,$00,$0D,$19
  DEFB $DB,$02,$4D,$00,$DB,$02,$4D,$00
  DEFB $11,$59,$EF,$01,$10,$59,$4C,$38
  DEFB $C0,$57,$71,$0E,$F3,$0D,$21,$17
  DEFB $C6,$1E,$FC,$5D,$76,$1B,$03,$13
  DEFB $00
  DEFB $3E                ; RAMTOP's $3E

; The BASIC UDGs A-U as the ROM sets them up: never read
;
; 21 letters, 8 bytes each, as the ROM copies them to UDG `$FF58`; the game
; stack uses at least the last 28 bytes (`$FFE4` on).
UdgResidue:
  DEFB $00,$3C,$42,$42,$7E,$42,$42,$00
  DEFB $00,$7C,$42,$7C,$42,$42,$7C,$00
  DEFB $00,$3C,$42,$40,$40,$42,$3C,$00
  DEFB $00,$78,$44,$42,$42,$44,$78,$00
  DEFB $00,$7E,$40,$7C,$40,$40,$7E,$00
  DEFB $00,$7E,$40,$7C,$40,$40,$40,$00
  DEFB $00,$3C,$42,$40,$4E,$42,$3C,$00
  DEFB $00,$42,$42,$7E,$42,$42,$42,$00
  DEFB $00,$3E,$08,$08,$08,$08,$3E,$00
  DEFB $00,$02,$02,$02,$42,$42,$3C,$00
  DEFB $00,$44,$48,$70,$48,$44,$42,$00
  DEFB $00,$40,$40,$40,$40,$40,$7E,$00
  DEFB $00,$42,$66,$5A,$42,$42,$42,$00
  DEFB $00,$42,$62,$52,$4A,$46,$42,$00
  DEFB $00,$3C,$42,$42,$42,$42,$3C,$00
  DEFB $00,$7C,$42,$42,$7C,$40,$40,$00
  DEFB $00,$3C,$42,$42,$52,$4A,$3C,$00
  DEFB $00,$7C,$42,$42,$7C,$44,$42,$00
  DEFB $00,$3C,$40,$3C,$02,$42

; The game's stack: SP = 0, set at Start `$AB4E`; it grows down from $FFFF
;
; The image holds the UDG bytes here; at run time the stack's words. This entry
; is the last 18 bytes; the deepest use
;
; seen in the memory images is `$FFE4` (`menu` and `play`), 28 bytes, so the
; stack also reaches into UdgResidue.
GameStack:
  DEFB $3C,$00
  DEFB $00,$FE
  DEFB $10,$10
  DEFB $10,$10
  DEFB $10,$00
  DEFB $00,$42
  DEFB $42,$42
  DEFB $42,$42
  DEFB $3C,$00
