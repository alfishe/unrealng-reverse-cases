; --------------------------------------------------------------------------------------------------------------------
; effects.asm: The sound effects: the table, the start, the choice of a voice
;
; An effect is a 13-byte record: an instrument (10 bytes, as in Instruments), the AY period (word) and the sustain
; frames. MusicEffect $CCC8 starts effect A on a free voice when no tune plays; with all three voices busy, effects 0
; and 2 are dropped and the others take the voices in turn. Resource: tunes/effects.csv (all 28 records).
; --------------------------------------------------------------------------------------------------------------------

; The 28 sound effects: an instrument, the period, the sustain frames
;
; MusicEffect $CCC8: record A at Effects + 13 A; +0-+9 the instrument,
; +$0A/+$0B the AY tone period, +$0C the frames before the release ($FF never).
; Effect 0's first 10 bytes are also instrument slot 7 (Instruments + 70),
; which no pattern selects.
;
; Read in c1 and the control and load recordings: effects 0, 4, 5 and 10
; ($C510-$C512, $C544-$C546, $C551-$C553, $C592-$C594 in MusicEffect's reads).
; The game names 0, 2, 4, 5, 6, 7, 9 and 10 at its call sites (06-notes.md);
; the beeper on a 48K has 11 effects (0-10), so 11-27 have no counterpart there
; and no call site names them.
Effects:
  INCBIN "res/tunes/effects.bin",$0000,364

  ORG $CCC8

; Start effect A on a voice when no tune plays
;
; Nothing while MusicPlaying is not 0. IY = Effects + 13 A; PickEffectVoice
; gives IX (no carry: none, the effect is dropped); StartVoice with the period
; +$0A/+$0B and the sustain +$0C. Keeps all registers but AF. The lines from
; $CCF6 are in the leftover source text of ChannelA ("LD L,(IY+10) ... CALL
; SOUND ... POP IY / POP IX").
;
; Called from PlayEffect $7A97 through CallRam1: 385 runs in the 9 builds, 44
; past the MusicPlaying test, 39 started.
;
; Witness: L1 429 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
MusicEffect:
  PUSH BC
  LD C,A
  PUSH BC
  LD A,(MusicPlaying)
  AND A
  POP BC
  LD A,C
  POP BC
  RET NZ
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
  LD BC,Effects
  ADD HL,BC
  PUSH HL
  POP IY
  CALL PickEffectVoice
  JP NC,MusicEffectDone
  LD L,(IY+$0A)
  LD H,(IY+$0B)
  LD C,(IY+$0C)
  CALL StartVoice
MusicEffectDone:
  POP IY
  POP IX
  POP BC
  POP DE
  POP HL
  RET

; The voice the next effect takes when none is free: 0-2, A-C in turn
;
; PickEffectVoice: incremented (1, 2, 0, ...) each time an effect other than 0
; or 2 finds all three voices busy (15 times in the 9 builds).
StealTurn:
  DEFB $00

; IX = a voice for effect A: the first free one, else the next in turn; no
; carry: none
;
; A voice is free when all its bits are set in MixerShadow. A, then B, then C;
; with none free, effects 0 (the footstep) and 2 (the fuse) return no carry
; (dropped) and the others take the voice StealTurn names after its increment.
; 44 runs (c1 only): a free voice 24 (A 12, B or C 12), a voice taken 15,
; dropped 5.
;
; Witness: L1 44 (c1).
PickEffectVoice:
  PUSH AF
  LD IX,VoiceA
  LD A,(MixerShadow)
  AND (IX+$02)
  CP (IX+$02)
  JP NZ,PickVoiceTestB
PickVoiceFree:
  POP AF
PickVoiceFound:
  SCF
  RET
PickVoiceTestB:
  LD IX,VoiceB
  LD A,(MixerShadow)
  AND (IX+$02)
  CP (IX+$02)
  JP Z,PickVoiceFree
  LD IX,VoiceC
  LD A,(MixerShadow)
  AND (IX+$02)
  CP (IX+$02)
  JP Z,PickVoiceFree
  POP AF
  CP $00
  RET Z
  CP $02
  RET Z
  LD A,(StealTurn)
  INC A
  CP $03
  JP C,PickVoiceSteal
  XOR A
PickVoiceSteal:
  LD (StealTurn),A
  LD IX,VoiceA
  AND A
  JP Z,PickVoiceFound
  LD IX,VoiceB
  CP $01
  JP Z,PickVoiceFound
  LD IX,VoiceC
  SCF
  RET

; 791 zeros to the end of the block ($D07F)
;
; Nothing reads or writes them in any recording (no reads in the l1q output of
; the part's routines).
TailFill:
  DEFS $0317
