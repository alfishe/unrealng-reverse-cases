; --------------------------------------------------------------------------------------------------------------------
; effects.asm: The per-frame effects: the gate, the rest, the envelope, the vibrato, the arpeggio and the slide
;
; The envelope (ChannelEffects $C55E) is the C64 ADSR in software: gate on, the volume climbs from 0 by the attack
; step at the attack rate to the instrument's peak, then falls by the decay step at the decay rate to the sustain
; level and holds; gate off (CheckGateOff $C555, when the note timer equals the gate-off time, 2 in every instrument:
; 2 frames before the note's end), it falls by the release step at the release rate to 0. With a release of 1 step
; every 5 frames the release never steps in tune 0 (its code $C5F0 was not executed in any of the 34 recordings).
;
; The vibrato (VibratoEffect $C609): the record (VibratoTable-8 + the instrument's +7) holds a first byte and 7 signed
; period deltas. First byte with bit 7 clear: a delay in frames before the vibrato starts, then it runs to the note's
; end; with bit 7: the number of full cycles (bits 0-6) it runs. Each frame adds the next delta (step 1-7) to the
; period, with its sign turned over on every other pass of 7 (bit 7 of the step), so one cycle is 14 frames. The
; arpeggio (ArpeggioEffect $C694): the record (ArpeggioTable + 8n) is a header (bit 7 loop, bits 3-6 the first hold,
; bits 0-2 the count of steps) and steps (bits 3-7 semitones over the note, bits 0-2 the hold in frames, 0: 256); each
; step sets the period to the note plus its semitones (and the detune); at the end it loops (the base note held
; (header >> 3) & 7 frames first) or returns to the base note. The slide (SlideEffect $C72F): after its delay, the
; period goes up or down by half the step each frame for the count. Each of the three overwrites or moves the period
; the note set; the arpeggio's step overwrites what the vibrato and the slide did.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C555

; Gate off when the note timer reaches the gate-off time; then the effects
;
; A = the note timer (from UpdateChannel $C2E4). A = +$06: the gate bit (+$2A
; bit 0) clear: the release. Falls into ChannelEffects.
;
; Witness: L1 235309 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
CheckGateOff:
  CP (IX+$06)
  JR NZ,ChannelEffects
  RES 0,(IX+$2A)

; The rest timer, the note timer and the envelope, then the vibrato, the
; arpeggio and the slide
;
; A rest (timer +$16 not 0): one less; at 0 the note timer 0 (the next event
; next frame); no effects. Else the note timer one less; NoteEndFlag $C14D up:
; return. Gate on: the attack (every rate frames, the volume + the step, to the
; peak), then the decay (to the sustain level). Gate off: the release (to 0).
; Then VibratoEffect $C609 (fall through).
;
; Witness: L1 235385 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ChannelEffects:
  LD A,(IX+$16)
  OR A
  JR Z,ChannelEffectsNote
  DEC (IX+$16)            ; a rest: count it; at 0 its end
  RET NZ
  LD (IX+$03),$00
  RET
ChannelEffectsNote:
  DEC (IX+$03)            ; the note's timer
  LD A,(NoteEndFlag)      ; a note ended this frame: no effects
  OR A
  RET NZ
  BIT 0,(IX+$2A)          ; the gate: off, the release
  JR Z,EnvelopeRelease
  BIT 7,(IX+$25)          ; the attack done: the decay
  JR NZ,EnvelopeDecay
  INC (IX+$26)
  LD A,(IX+$26)
  CP (IX+$25)
  JR NZ,VibratoEffect
  LD (IX+$26),$00
  LD A,(IX+$24)
  ADD A,(IX+$1F)
  CP (IX+$2B)
  JR C,EnvelopeAttackStore
  LD A,(IX+$2B)
  LD (IX+$1F),A
  SET 7,(IX+$25)
  JR VibratoEffect
EnvelopeAttackStore:
  LD (IX+$1F),A           ; the attack's new volume
  JR VibratoEffect
EnvelopeDecay:
  BIT 7,(IX+$22)          ; the decay done: the sustain holds
  JR NZ,VibratoEffect
  INC (IX+$23)
  LD A,(IX+$23)
  CP (IX+$22)
  JR NZ,VibratoEffect
  LD (IX+$23),$00
  LD A,(IX+$1F)
  SUB (IX+$21)
  JR NC,EnvelopeDecayStore
EnvelopeSustain:
  LD A,(IX+$20)           ; at the sustain level: the decay done
  LD (IX+$1F),A
  SET 7,(IX+$22)
  JR VibratoEffect
EnvelopeDecayStore:
  CP (IX+$20)             ; not below the sustain level yet
  JR C,EnvelopeSustain
  LD (IX+$1F),A
  JR VibratoEffect
EnvelopeRelease:
  BIT 7,(IX+$28)          ; the release done: nothing
  JR NZ,VibratoEffect
  INC (IX+$29)
  LD A,(IX+$29)
  CP (IX+$28)
  JR NZ,VibratoEffect
  LD (IX+$29),$00
  LD A,(IX+$1F)
  SUB (IX+$27)
  JR NC,EnvelopeReleaseStore
  LD (IX+$1F),$00
  SET 7,(IX+$28)
  JR VibratoEffect
EnvelopeReleaseStore:
  LD (IX+$1F),A           ; the release's new volume

; The vibrato: after its delay, the next of 7 period deltas, its sign flipped
; every other pass
;
; A new entry: the end of the envelope, where all its paths join (10 jumps to
; $C609 and the fall from $C606), and the start of the vibrato. No vibrato
; (+$0B = 0): ArpeggioEffect $C694. The delay or cycles byte (+$0A): bit 7
; clear and not 0: one less, no step this frame; 0: step; bit 7 set: step until
; its low 7 bits are 0. A step: delta = (VibratoTable-8)[+$0B + (step & $7F)]
; (CommandParam $C1E0 holds its size): the period + delta while the step's bit
; 7 is clear, the period - delta while it is set. After step 7 the step becomes
; $81 (bit 7 flipped, step 1); after the flipped pass's step 7, 1 again: a
; cycle done, and a cycles count one less.
;
; Records 4, 5 and 7 use it (VibratoTable's only record: delay 40). The cycles
; form ($C61A), and a delta that carries or borrows in the period ($C654,
; $C670) was not executed in any of the 34 recordings.
;
; Witness: L1 208864 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
VibratoEffect:
  LD A,(IX+$0B)
  OR A
  JP Z,ArpeggioEffect
  LD A,(IX+$0A)
  OR A
  JR Z,VibratoStep
  BIT 7,A
  JR Z,VibratoDelay
  AND $7F
  JR Z,ArpeggioEffect
  JR VibratoStep
VibratoDelay:
  DEC (IX+$0A)            ; the delay one less
  JP ArpeggioEffect
VibratoStep:
  LD A,(IX+$0C)           ; the delta of this step
  AND $7F
  ADD A,(IX+$0B)
  LD L,A
  LD H,$00
  LD BC,VibratoTable-8
  ADD HL,BC
  LD A,(HL)
  LD (CommandParam),A
  BIT 7,A
  JR Z,VibratoPositive
  NEG
  LD (CommandParam),A
  BIT 7,(IX+$0C)
  JR NZ,VibratoUp
VibratoDown:
  LD HL,CommandParam      ; the period - the size
  LD A,(IX+$1D)
  SUB (HL)
  LD (IX+$1D),A
  JR NC,VibratoNext
  DEC (IX+$1E)
  JR VibratoNext
VibratoPositive:
  LD A,(CommandParam)     ; a positive delta: up unless the step's bit 7
  LD (CommandParam),A
  BIT 7,(IX+$0C)
  JR NZ,VibratoDown
VibratoUp:
  LD A,(CommandParam)     ; the period + the size
  ADD A,(IX+$1D)
  LD (IX+$1D),A
  JR NC,VibratoNext
  INC (IX+$1E)
VibratoNext:
  INC (IX+$0C)            ; the next step; after 7 the sign flips ($89)
  LD A,(IX+$0C)
  AND $7F
  CP $08
  JR NZ,ArpeggioEffect
  LD A,(IX+$0C)
  XOR $89
  LD (IX+$0C),A
  CP $01
  JR NZ,ArpeggioEffect
  LD A,(IX+$0A)
  OR A
  JR Z,ArpeggioEffect
  DEC (IX+$0A)

; The arpeggio: when the hold ends, the next step's note and hold
;
; No arpeggio (+$10 = 0): SlideEffect $C72F. The hold (+$18) one less; not 0:
; SlideEffect. Step (+$17) 1-7: the byte at ArpeggioTable + 8n + step: the hold
; = its bits 0-2, the period = the note (+$1C) + its bits 3-7 + the detune.
; Step 0 (a looped arpeggio's restart): the header's bits 3-5 as the hold of
; the base note (when not 0). After the last step (the header's bits 0-2): 0
; when the header's bit 7 is set (loop), else $FF; $FF at the hold's end: the
; base note again and $FE, after which nothing.
;
; Arpeggios 1-6 ran (patterns 2, 7-9, 13, 16, 18, 19). The end ($C70E) was not
; executed in any of the 34 recordings: arpeggio 1, the only one with no loop,
; plays on 9-frame notes, which end first.
;
; Witness: L1 208864 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ArpeggioEffect:
  LD A,(IX+$10)
  OR A
  JP Z,SlideEffect
  DEC (IX+$18)
  JP NZ,SlideEffect
  ADD A,(IX+$17)
  LD L,A
  LD H,$00
  LD BC,ArpeggioTable
  ADD HL,BC
  LD A,(IX+$17)
  BIT 7,A
  JR NZ,ArpeggioEnd
  OR A
  JR NZ,ArpeggioByte
  LD A,(HL)
  AND $38
  SRL A
  SRL A
  SRL A
  OR A
  JR NZ,ArpeggioApply
ArpeggioByte:
  LD A,(HL)               ; the step's byte
ArpeggioApply:
  LD C,A                  ; the hold and the semitones over the note
  AND $07
  LD (IX+$18),A
  LD A,C
  AND $F8
  SRL A
  SRL A
  SRL A
  ADD A,(IX+$1C)
  LD C,A
  LD B,$00
  LD HL,PeriodLo
  ADD HL,BC
  LD A,(HL)
  LD HL,PeriodHi
  ADD HL,BC
  LD H,(HL)
  LD L,A
  LD C,(IX+$09)
  ADD HL,BC
  LD (IX+$1D),L
  LD (IX+$1E),H
  INC (IX+$17)            ; the next step; after the last: 0 (loop) or $FF
                          ; (end)
  LD L,(IX+$10)
  LD H,$00
  LD BC,ArpeggioTable
  ADD HL,BC
  LD A,(HL)
  AND $07
  INC A
  CP (IX+$17)
  JR NZ,SlideEffect
  BIT 7,(HL)
  LD A,$FF
  JR Z,ArpeggioSetStep
  XOR A
ArpeggioSetStep:
  LD (IX+$17),A           ; 0 or $FF
  JP SlideEffect
ArpeggioEnd:
  CP $FF                  ; $FF: back to the base note, then $FE
  JR NZ,SlideEffect
  DEC (IX+$17)
  LD C,(IX+$1C)
  LD B,$00
  LD HL,PeriodLo
  ADD HL,BC
  LD A,(HL)
  LD HL,PeriodHi
  ADD HL,BC
  LD H,(HL)
  LD L,A
  LD C,(IX+$09)
  ADD HL,BC
  LD (IX+$1D),L
  LD (IX+$1E),H

; The slide: after its delay, the period up or down by half the step, for the
; count
;
; A new entry: ArpeggioEffect's paths join here (5 jumps to $C72F and the fall
; from $C72C). The delay (+$14) not 0: one less. Else with a count (+$11 not 0;
; $FF endless, else one less): the step (+$12/+$13) halved; the slide command's
; bit 5 (+$15) set: the period + step/2 (the pitch falls); clear: the period -
; step/2 - the step's bit 0 (SBC with the carry RR C left). Returns to
; UpdateTune $C1E4.
;
; Ran in no recording past the delay test: tune 0 has no slide ($C735-$C77C not
; executed in any of the 34 recordings).
;
; Witness: L1 208864 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
SlideEffect:
  LD A,(IX+$14)
  OR A
  JR Z,SlideCount
  DEC (IX+$14)
  JR SlideDone
SlideCount:
  LD A,(IX+$11)           ; the count: 0 none, $FF endless
  OR A
  JR Z,SlideDone
  CP $FF
  JR Z,SlideApply
  DEC (IX+$11)
SlideApply:
  LD A,(IX+$15)           ; the direction: bit 5 of the command
  AND $20
  JR Z,SlideUp
  LD L,(IX+$1D)
  LD H,(IX+$1E)
  LD C,(IX+$12)
  LD B,(IX+$13)
  SRL B
  RR C
  ADD HL,BC
  LD (IX+$1D),L
  LD (IX+$1E),H
  JR SlideDone
SlideUp:
  LD L,(IX+$1D)           ; the period - step/2: the pitch rises
  LD H,(IX+$1E)
  LD C,(IX+$12)
  LD B,(IX+$13)
  SRL B
  RR C
  SBC HL,BC
  LD (IX+$1D),L
  LD (IX+$1E),H
SlideDone:
  RET
