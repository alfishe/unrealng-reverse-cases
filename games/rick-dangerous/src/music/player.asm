; --------------------------------------------------------------------------------------------------------------------
; player.asm: The AY player: periods, the three channels' state, note start, volume envelopes, the AY output
;
; The player under the tunes and the effects. Three channel records (ChannelA, ChannelB, ChannelC, 18 bytes each) hold
; what each AY channel sounds now: tone period, volume, a software volume envelope (attack, decay, sustain, release,
; run by a routine pointer per channel), a duration count and a vibrato or slide added to the period. StartNote $C0E2
; loads a channel from a 10-byte instrument (or the first 10 bytes of an effect); UpdateAy $C19F, once a frame from
; AyTick $C46C, steps the three channels and writes AY registers 0-10.
;
; The period table is the one of an Atari ST player (YM2149 at 2 MHz), index 0 = C-1: on the Spectrum's 1.7734 MHz AY
; every note sounds about two semitones lower. The player uses no hardware envelope: the hooks SoundHookStart $C345
; and SoundHookEnd $C346 are bare RETs, and the envelope stub at StartNoteFixed $C148 loads registers and writes
; nothing.
; --------------------------------------------------------------------------------------------------------------------

; AY tone periods, 85 notes from C-1 (3822) by semitones; index = note +
; transpose + 12
;
; TrackStep $C4B4 (at $C573) and OrnamentStep $C5F5 (at $C672) read the word at
; PeriodTable + 2 * index; the index is the pattern's note plus the track's
; transpose plus 12. The values are 2 000 000 / 16 / f of the equal-tempered
; scale (3822: 32.7 Hz, C-1, at 2 MHz).
;
; Two entries carry a typo in bit 5 of the low byte: index 20 (G#2) is 1236
; (`$04D4`), not 1204 (`$04B4`), and index 24 (C-3) is 988 (`$03DC`), not 956
; (`$03BC`); those two notes sound about half a semitone flat. The last entry,
; index 84, is 24, not 30.
PeriodTable:
  INCBIN "res/music/periods.bin",$0000,170

; AY register 7 as last written: bits 0-2 tone off, bits 3-5 noise off (all
; set: silent)
;
; StartNote clears the channel's tone and/or noise bits (its instrument's flags
; bits 0 and 1), ReleaseStep $C2DD sets them again when the volume reaches 0.
; UpdateAy returns at once while bits 0-5 are all set (nothing sounding): that
; is the cost of a silent frame. As loaded: `$3F`.
MixerShadow:
  DEFB $3F

; Channel A: +0 tone-on AND mask, +1 noise-on AND mask, +2 its mixer bits,
; +3/+4 period, +5 volume (0-255)
;
; The channel record (IX), 18 bytes: +0 the AND mask that turns its tone on in
; register 7, +1 the mask that turns its noise on, +2 both its bits (tone and
; noise off), +3/+4 the note's period, +5 the volume (0-255; AY volume = it /
; 8), +6 the duration left (frames; 0: released; `$FF`: held), +7 the vibrato
; delay left (`$FF`: none), +8 the vibrato steps left, +9/+10 the offset added
; to the period, +11/+12 the offset's step per frame, +13/+14 the envelope
; phase routine (AttackStep $C28D, DecayStep $C2AC, SustainStep $C2CE,
; ReleaseStep $C2DD), +15/+16 the instrument, +17 the instrument's flags (bit 7
; set while an effect owns the channel, so tunes leave it alone).
;
; Masks of channel A as loaded: `$FE`, `$F7`, `$09`.
ChannelA:
  DEFB $FE,$F7,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Channel B (masks `$FD`, `$EF`, `$12`); effect 4 always plays here
ChannelB:
  DEFB $FD,$EF,$12,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Channel C (masks `$FB`, `$DF`, `$24`)
ChannelC:
  DEFB $FB,$DF,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The noise period: the low period byte of the last channel with noise
; (instrument flags bit 1)
;
; UpdateAy stores the low byte of a noise channel's period (+ offset) here and
; writes it rotated right three times to AY register 6.
NoisePeriod:
  DEFB $00

; Start a note on channel IX: instrument IY, period HL, duration C
;
; Copies the instrument (IY: +0 attack step, +1 decay step, +2 sustain level,
; +3 release step, +4 peak volume, +5 vibrato delay, +6 vibrato length, +7/+8
; vibrato step, +9 flags) into the channel record: period, duration, delay,
; half the vibrato length (at least 1), the step; the period offset is cleared.
; The flags go to +17: bit 0 turns the channel's tone on, bit 1 its noise, bit
; 2 a fixed volume (`$FF`, held for the duration) instead of the envelope (no
; instrument or effect sets it). Otherwise the envelope starts at AttackStep.
; Called by TrackStep for a tune's note and by AyPlayEffect $C685 with an
; effect.
;
; Starts with DI and has no EI: the callers run with interrupts off (the game's
; `$9FED`) or inside the IM 2 handler.
;
; Witness: L1 5524 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
StartNote:
  DI
  LD A,IYL
  LD (IX+$0F),A
  LD A,IYH
  LD (IX+$10),A
  LD (IX+$03),L
  LD (IX+$04),H
  LD (IX+$06),C
  LD A,(IY+$05)
  LD (IX+$07),A
  LD A,(IY+$06)
  AND $7F
  SRL A
  JR NZ,StartNoteSteps
  LD A,$01
StartNoteSteps:
  LD (IX+$08),A           ; at least one vibrato step
  LD A,(IY+$07)
  LD (IX+$0B),A
  LD A,(IY+$08)
  LD (IX+$0C),A
  XOR A
  LD (IX+$09),A
  LD (IX+$0A),A
  LD A,(MixerShadow)
  OR (IX+$02)
  LD C,(IY+$09)
  LD (IX+$11),C
  BIT 0,C
  JR Z,StartNoteNoise
  AND (IX+$00)
StartNoteNoise:
  BIT 1,C                 ; flags bit 1: the channel's noise on
  JR Z,StartNoteEnvelope
  AND (IX+$01)
StartNoteEnvelope:
  LD (MixerShadow),A
  BIT 2,C
  JR NZ,StartNoteFixed
  LD HL,AttackStep
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET
StartNoteFixed:
  CALL SoundHookStart     ; the fixed-volume start: a stub of a
                          ; hardware-envelope start (loads A and C, writes
                          ; nothing)
  LD A,(IY+$00)
  LD C,$0D
  LD A,(IY+$04)
  LD C,$0B
  INC C
  XOR A
  LD (IX+$05),$FF
  JP SoundHookEnd

; Silence the AY: all tone and noise off, volumes 0, the channels' volumes
; cleared
;
; Sets bits 0-5 of MixerShadow, writes register 7, zeroes registers 8-10,
; register 11 = 1 and 12-13 = 0 (the envelope), and the three channels'
; volumes. AyPlayTune $C3E4 calls it before a tune starts.
;
; Witness: L1 30 (c1, controls, ending, ending2, gameover, level1).
SilenceAll:
  CALL SoundHookStart
  LD C,$07
  LD A,(MixerShadow)
  OR $3F
  LD (MixerShadow),A
  CALL WriteAy
  XOR A
  INC C
  CALL WriteAy
  INC C
  CALL WriteAy
  INC C
  CALL WriteAy
  LD A,$01
  INC C
  CALL WriteAy
  INC C
  XOR A
  CALL WriteAy
  INC C
  CALL WriteAy
  LD (ChannelA+$0011),A
  LD (ChannelB+$0011),A
  LD (ChannelC+$0011),A
  LD (ChannelA+$0005),A
  LD (ChannelB+$0005),A
  LD (ChannelC+$0005),A
  JP SoundHookEnd

; Once a frame: step the three channels and write AY registers 7, 0-6 and 8-10
;
; Returns at once while MixerShadow has every channel off. Otherwise runs
; ChannelStep $C25B for channels A, B and C, then writes the mixer, each
; channel's period plus its vibrato offset, the noise period (NoisePeriod, from
; a channel with noise) and the volumes (+5 / 8).
;
; Witness: L1 47434 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
UpdateAy:
  LD A,(MixerShadow)
  AND $3F
  CP $3F
  RET Z
  LD IX,ChannelA
  CALL ChannelStep
  LD IX,ChannelB
  CALL ChannelStep
  LD IX,ChannelC
  CALL ChannelStep
  CALL SoundHookStart
  LD IX,ChannelA
  LD C,$07
  LD A,(MixerShadow)
  CALL WriteAy
  LD C,$00
  LD A,(ChannelA+$0003)
  ADD A,(IX+$09)
  BIT 1,(IX+$11)
  JP Z,UpdateAyToneA
  LD (NoisePeriod),A
UpdateAyToneA:
  CALL WriteAy
  INC C
  LD A,(ChannelA+$0004)
  ADC A,(IX+$0A)
  CALL WriteAy
  INC C
  LD A,(ChannelB+$0003)
  ADD A,(IX+$1B)
  BIT 1,(IX+$23)
  JP Z,UpdateAyToneB
  LD (NoisePeriod),A
UpdateAyToneB:
  CALL WriteAy
  INC C
  LD A,(ChannelB+$0004)
  ADC A,(IX+$1C)
  CALL WriteAy
  INC C
  LD A,(ChannelC+$0003)
  ADD A,(IX+$2D)
  BIT 1,(IX+$35)
  JP Z,UpdateAyToneC
  LD (NoisePeriod),A
UpdateAyToneC:
  CALL WriteAy
  INC C
  LD A,(ChannelC+$0004)
  ADC A,(IX+$2E)
  CALL WriteAy
  INC C
  LD A,(NoisePeriod)
  RRCA
  RRCA
  RRCA
  CALL WriteAy
  LD C,$08
  LD A,(ChannelA+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAy
  INC C
  LD A,(ChannelB+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAy
  INC C
  LD A,(ChannelC+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAy
  JP SoundHookEnd

; One channel's frame: count the duration down, step the vibrato, run the
; envelope phase
;
; Nothing while the channel is off in MixerShadow. The duration (+6) counts
; down unless 0 or `$FF`; VibratoStep $C303 moves the period offset; then a
; fixed-volume instrument (flags bit 2) waits for the duration to end and goes
; to ReleaseOff, the others jump to the phase routine at +13/+14.
;
; Witness: L1 99282 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
ChannelStep:
  LD A,(MixerShadow)
  AND (IX+$02)
  CP (IX+$02)
  RET Z
  LD A,(IX+$0F)
  LD IYL,A
  LD A,(IX+$10)
  LD IYH,A
  LD A,(IX+$06)
  AND A
  JR Z,ChannelStepPhase
  CP $FF
  JR Z,ChannelStepPhase
  DEC (IX+$06)
ChannelStepPhase:
  CALL VibratoStep
  BIT 2,(IY+$09)
  JP NZ,FixedVolumeEnd
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  JP (HL)

; Envelope phase 1: volume + attack step until the peak, then DecayStep
;
; Witness: L1 6357 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
AttackStep:
  LD A,(IX+$05)
  ADD A,(IY+$00)
  CP (IY+$04)
  JR NC,AttackPeak
  LD (IX+$05),A
  RET
AttackPeak:
  LD A,(IY+$04)
  LD (IX+$05),A
  LD HL,DecayStep
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Envelope phase 2: volume + decay step (negative) down to the sustain level,
; then SustainStep
;
; Witness: L1 37089 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
DecayStep:
  LD A,(IX+$05)
  ADD A,(IY+$01)
  JP M,DecaySustain
  CP (IY+$02)
  JR C,DecaySustain
  LD (IX+$05),A
  RET
DecaySustain:
  LD A,(IY+$02)
  LD (IX+$05),A
  LD HL,SustainStep
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Envelope phase 3: hold the volume until the duration (+6) is 0, then
; ReleaseStep
;
; Witness: L1 15122 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
SustainStep:
  LD A,(IX+$06)
  AND A
  RET NZ
  LD HL,ReleaseStep
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Envelope phase 4: volume + release step (negative) down to 0, then the
; channel off and free
;
; At 0 the channel's tone and noise bits are set again in MixerShadow and +17
; bit 7 is cleared, so a tune may use the channel again after an effect.
;
; Witness: L1 7788 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
ReleaseStep:
  LD A,(IX+$05)
  ADD A,(IY+$03)
  JP M,ReleaseOff
  LD (IX+$05),A
  RET
ReleaseOff:
  LD (IX+$05),$00
  LD A,(MixerShadow)
  OR (IX+$02)
  LD (MixerShadow),A
  RES 7,(IX+$11)
  RET
; This entry point is used by the routine at ChannelStep.
FixedVolumeEnd:
  LD A,(IX+$06)           ; a fixed-volume note: off when its duration ends
  AND A
  RET NZ
  JR ReleaseOff

; Add the step to the period offset after the delay; at the end of the length
; reverse the step
;
; +7 delays the start (`$FF`: never). Each frame the step (+11/+12) is added to
; the offset (+9/+10); when +8 counts to 0 the instrument's length +6 decides:
; 0 keeps the step going (a slide), bit 7 set stops it (+7 = `$FF`), else +8 =
; the length and the step is negated (a vibrato).
;
; Witness: L1 66356 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
VibratoStep:
  LD A,(IX+$07)
  AND A
  JR Z,VibratoAdd
  CP $FF
  RET Z
  DEC (IX+$07)
  RET NZ
VibratoAdd:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD C,(IX+$0B)
  LD B,(IX+$0C)
  ADD HL,BC
  LD (IX+$09),L
  LD (IX+$0A),H
  DEC (IX+$08)
  RET NZ
  LD A,(IY+$06)
  AND A
  RET Z
  JP P,VibratoReverse
  LD (IX+$07),$FF
  RET
VibratoReverse:
  LD (IX+$08),A
  LD A,C
  CPL
  LD C,A
  LD A,B
  CPL
  LD B,A
  INC BC
  LD (IX+$0B),C
  LD (IX+$0C),B
  RET

; A bare RET called before the AY writes: a hook left from another machine's
; player
;
; Witness: L1 33124 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
SoundHookStart:
  RET

; A bare RET jumped to after the AY writes
;
; Witness: L1 33124 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
SoundHookEnd:
  RET

; Write A to AY register C (OUT `$FFFD` the register, OUT `$BFFD` the value)
;
; Witness: L1 364244 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
WriteAy:
  PUSH BC
  LD E,C
  LD BC,$FFFD
  OUT (C),E
  LD B,$BF
  OUT (C),A
  POP BC
  RET
