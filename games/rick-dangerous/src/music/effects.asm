; --------------------------------------------------------------------------------------------------------------------
; effects.asm: The sound effects: AyPlayEffect and the table of the 12 effects
;
; An effect is one note started straight on a channel: a 13-byte record, the 10 bytes of an instrument then its period
; and its duration. AyPlayEffect $C685 takes channels A, B, C in turn (effect 4 always B) and marks the channel busy,
; so the tune's notes skip it until the effect's volume reaches 0.
;
; The game calls it through its own AyPlayEffect `$9FED` (A = the effect, RAM 1 paged in, interrupts off). On a 48K
; `$9FED` plays the beeper routine `$A08E` instead, from its own data: these records are the 128K's only.
; --------------------------------------------------------------------------------------------------------------------

; Play effect A (0-11): its record from EffectTable on the next channel, as a
; note
;
; IY = EffectTable + 13A. Effect 4 goes to ChannelB; the others to the channel
; after the last one used (EffectChannel 0, 1, 2: A, B, C). StartNote with the
; record's period (+10/+11) and duration (+12). Keeps every register but A and
; F.
;
; Witness: L1 2042 (L1Z4, c1, controls, ending2, gameover, level1-level4).
AyPlayEffect:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH IX
  PUSH IY
  LD E,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD C,L
  LD B,H
  ADD HL,HL
  ADD HL,BC
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,EffectTable
  ADD HL,BC
  PUSH HL
  POP IY
  LD A,E
  CP $04
  JP NZ,PlayEffectNextChannel
  LD IX,ChannelB
  JP PlayEffectStart
PlayEffectNextChannel:
  LD A,(EffectChannel)
  INC A
  CP $03
  JP C,PlayEffectChannel
  XOR A
PlayEffectChannel:
  LD (EffectChannel),A
  LD IX,ChannelA
  AND A
  JP Z,PlayEffectStart
  LD IX,ChannelB
  CP $01
  JP Z,PlayEffectStart
  LD IX,ChannelC
PlayEffectStart:
  LD L,(IY+$0A)
  LD H,(IY+$0B)
  LD C,(IY+$0C)
  CALL StartNote
  POP IY
  POP IX
  POP BC
  POP DE
  POP HL
  RET

; The channel of the last effect: 0, 1, 2 = A, B, C (as loaded 0)
EffectChannel:
  DEFB $00

  ORG $CD08

; The 12 effects, 13 bytes each: an instrument's 10 bytes, the period, the
; duration
;
; +0-+9 as Instruments, +10/+11 the period, +12 the duration in frames. The
; comments give the call sites of the game's AyPlayEffect `$9FED` with A = the
; effect and the most runs of a call site in one recording.
EffectTable:
Effect0:
  INCBIN "res/music/effects.bin",$0000,13
Effect1:
  INCBIN "res/music/effects.bin",$000D,13
Effect2:
  INCBIN "res/music/effects.bin",$001A,13
Effect3:
  INCBIN "res/music/effects.bin",$0027,13
Effect4:
  INCBIN "res/music/effects.bin",$0034,13
Effect5:
  INCBIN "res/music/effects.bin",$0041,13
Effect6:
  INCBIN "res/music/effects.bin",$004E,13
Effect7:
  INCBIN "res/music/effects.bin",$005B,13
Effect8:
  INCBIN "res/music/effects.bin",$0068,13
Effect9:
  INCBIN "res/music/effects.bin",$0075,13
Effect10:
  INCBIN "res/music/effects.bin",$0082,13
Effect11:
  INCBIN "res/music/effects.bin",$008F,13
