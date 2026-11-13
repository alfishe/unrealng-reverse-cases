; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The 48K beeper effects
;
; On a 48K (Machine48K $7A76 set) PlayEffect $7A97 points PlayBeeperStep's note pointer at one of eleven effects, and
; the main loop calls PlayBeeperStep $7B66 once a pass: one note a pass, a square wave on port $FE bit 3 for $600 loop
; turns whatever the pitch. No recording runs a 48K, so this module is known only from the code; the static walk takes
; it for data, and it is written as DEFB, one instruction a line.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7ABF

; Read the RAM 1 music's byte $C9CF (A, flags of AND A); nothing on a 48K
;
; Not executed in any recording and called from nowhere in the image
; ($6000-$FEFD holds no CALL or JP to $7ABF). Pages RAM 1 in like CallRam1 and
; returns the byte $C9CF of the music (perhaps "a tune is playing"), interrupts
; left off.
;
; Witness: L1 0 ().
ReadMusicByte:
  LD A,(Machine48K)       ; LD A,($7A76): Machine48K
  AND A
  RET NZ                  ; RET NZ: a 48K
  DI
  LD A,$11
  LD BC,$7FFD
  OUT (C),A               ; OUT (C),A: RAM 1 at $C000
  LD A,(MusicPlaying)
  LD E,A
  LD A,$10
  LD BC,$7FFD
  OUT (C),A               ; OUT (C),A: RAM 0 back
  LD A,E
  AND A
  RET

; 48K: PlayEffect's other half, the note pointer at $7B67 =
; BeeperEffectTable[A] for A < 11
;
; Reached from PlayEffect $7AA0 when Machine48K is set; ends with PlayEffect's
; POP BC, POP HL, POP AF, RET.
;
; Evidence: c48 (the 48K load and play, stage 2) 157 runs: every effect the
; play started.
;
; Witness: L1 157 (c48).
SelectBeeperEffect:
  CP $0B                  ; CP $0B
  JP NC,SelectBeeperEffectDone ; JP NC,$7AEE: no such effect
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,BeeperEffectTable ; LD BC,$7AF2: BeeperEffectTable
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PlayBeeperStep+$0001),DE ; LD ($7B67),DE: PlayBeeperStep's note pointer
SelectBeeperEffectDone:
  POP BC
  POP HL
  POP AF
  RET

; The eleven beeper effects' addresses, by effect number (SelectBeeperEffect)
BeeperEffectTable:
  DEFW BeeperEffects
  DEFW BeeperEffect1
  DEFW BeeperEffect2
  DEFW BeeperEffect3
  DEFW BeeperEffect4
  DEFW BeeperEffect5
  DEFW BeeperEffect6
  DEFW BeeperEffect7
  DEFW BeeperEffect8
  DEFW BeeperEffect9
  DEFW BeeperEffect10

; The beeper effects: one note a pass, each byte the half period in loop turns,
; $FF ends
;
; Played by PlayBeeperStep $7B66 on a 48K. A lower byte is a higher note; every
; note lasts $600 loop turns (about 0.7 frame).
BeeperEffects:
BeeperEffect0:
  INCBIN "res/tables/beeper-effects.bin",$0000,2
BeeperEffect1:
  INCBIN "res/tables/beeper-effects.bin",$0002,3
BeeperEffect2:
  INCBIN "res/tables/beeper-effects.bin",$0005,2
BeeperEffect3:
  INCBIN "res/tables/beeper-effects.bin",$0007,6
BeeperEffect4:
  INCBIN "res/tables/beeper-effects.bin",$000D,7
BeeperEffect5:
  INCBIN "res/tables/beeper-effects.bin",$0014,13
BeeperEffect6:
  INCBIN "res/tables/beeper-effects.bin",$0021,17
BeeperEffect7:
  INCBIN "res/tables/beeper-effects.bin",$0032,6
BeeperEffect8:
  INCBIN "res/tables/beeper-effects.bin",$0038,6
BeeperEffect9:
  INCBIN "res/tables/beeper-effects.bin",$003E,13
BeeperEffect10:
  INCBIN "res/tables/beeper-effects.bin",$004B,19

; 48K: play the next note of the current beeper effect, if any
;
; Called by the main loop $7D86 each pass when Machine48K is set. The note
; pointer (the LD HL operand at $7B67, set by SelectBeeperEffect) is 0 at the
; start: the first passes on a 48K would play the ROM's bytes at $0000 ($F3,
; $AF, $11) until its $FF at $0003. The note: C = the byte, then port $FE = $08
; / $00 (MIC bit, black border) toggled every C turns of a DE = $600 countdown,
; about 49 000 T: most of a frame per pass. Not executed in any recording.
;
; Evidence: c48 1206 runs, one a main loop pass after the game started (no
; other recording is a 48K).
;
; Witness: L1 1206 (c48).
PlayBeeperStep:
  LD HL,$0000             ; LD HL,nn: nn = the next note
  LD A,(HL)
  CP $FF
  RET Z                   ; RET Z: the effect is over
  INC HL
  LD (PlayBeeperStep+$0001),HL
  LD C,A                  ; LD C,A: the half period
  LD DE,$0600             ; LD DE,$0600: the note's length
BeeperHigh:
  LD A,$08
  OUT ($FE),A
  LD B,C
BeeperHighWait:
  DEC DE
  LD A,D
  OR E
  RET Z
  DJNZ BeeperHighWait     ; DJNZ BeeperHighWait
BeeperLow:
  LD A,$00
  OUT ($FE),A
  LD B,C
BeeperLowWait:
  DEC DE
  LD A,D
  OR E
  RET Z
  DJNZ BeeperLowWait      ; DJNZ BeeperLowWait
  JP BeeperHigh           ; JP BeeperHigh

; A RET after PlayBeeperStep's loop, which ends only by its RET Z: never
; reached
;
; One byte $C9 between PlayBeeperStep's JP BeeperHigh and the entry code at
; $7B8F: no instruction jumps to it, no recording reads or runs it (an older
; routine's end).
BeeperStepRet:
  DEFB $C9
