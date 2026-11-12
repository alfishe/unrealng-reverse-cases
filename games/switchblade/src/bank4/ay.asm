; --------------------------------------------------------------------------------------------------------------------
; ay.asm: Starting a note on a channel, the envelope phases, the vibrato, the AY writes
;
; The AY side of the player. StartNote $D0DA sets a channel up from an instrument; at every frame AyUpdate $D1C3 runs
; UpdateChannel $D2D6 for A, B and C (the gate timer, UpdateVibrato $D37E, the envelope phase through the record's
; +$0D/+$0E) and writes the registers 0-10: tone periods (A doubled; base + vibrato offset + slide offset), the noise
; period, the mixer, the volumes (volume / 8). WriteAyRegister $D3C6 is the one routine with ports $FFFD / $BFFD.
; --------------------------------------------------------------------------------------------------------------------

; Start a note or an effect on an AY channel
;
; IX = the AY record, IY = the instrument (Instruments or Effects), HL = the
; tone period, C = the gate time. Sets the instrument, the period, the gate
; timer, the vibrato (delay +5, the first sweep half of +6, at least 1, step
; +7/+8, the offset 0) and clears the slide offset; the AY record's volume +$05
; is kept, so a note or effect attacks from the volume the channel had (doc 09,
; 9.11). The mixer: the channel off, then tone on if flags bit 0, noise on if
; bit 1, or noise on for a burst when DrumPending $C0D2 is set (DrumChannel,
; DrumTimer = DrumLength). Flags bit 2 (hardware envelope, no instrument) sets
; the AY envelope: shape = +0, period high = +4, low 0, volume $FF (31: bit 4 =
; envelope mode) and leaves the phase alone; otherwise the phase is EnvAttack
; $D308.
;
; Called by SequenceChannel $C1C5 (JP at $C30F) and PlayEffect $C011.
;
; Witness: L1 13915 (c1, deaths, gameover, menu, rooms, opt x3).
StartNote:
  LD A,IYL
  LD (IX+$0F),A
  LD A,IYH
  LD (IX+$10),A
  LD (IX+$03),L
  LD (IX+$04),H
  LD (IX+$06),C
  LD A,(IY+$05)           ; the vibrato: delay, half the width (at least 1),
                          ; the step
  LD (IX+$07),A
  LD A,(IY+$06)
  AND $7F
  SRL A
  JR NZ,SetSweepFrames
  LD A,$01
SetSweepFrames:
  LD (IX+$08),A
  LD A,(IY+$07)
  LD (IX+$0B),A
  LD A,(IY+$08)
  LD (IX+$0C),A
  XOR A                   ; the vibrato offset (+$09/+$0A) and the slide offset
                          ; (+$12/+$13) from 0; the volume (+$05) is kept
  LD (IX+$09),A
  LD (IX+$0A),A
  LD (IX+$12),A
  LD (IX+$13),A
  LD A,(AyMixer)          ; the mixer: this channel off, then on as the flags
                          ; say
  OR (IX+$02)
  LD C,(IY+$09)
  LD (IX+$11),C
  BIT 0,C
  JR Z,MixerDrum
  AND (IX+$00)
MixerDrum:
  PUSH AF                 ; a drum burst pending?
  LD A,(DrumPending)
  AND A
  JR NZ,MixerDrumStart
  POP AF
  BIT 1,C                 ; no: noise as the flags say
  JR Z,MixerSet
  AND (IX+$01)
  JR MixerSet
MixerDrumStart:
  XOR A                   ; the burst: DrumChannel, DrumTimer = DrumLength,
                          ; noise on
  LD (DrumPending),A
  LD A,(IX+$01)
  LD (DrumChannel),A
  LD A,(DrumLength)
  LD (DrumTimer),A
  POP AF
  AND (IX+$01)
MixerSet:
  LD (AyMixer),A
  BIT 2,C                 ; flags bit 2: the hardware envelope
  JR NZ,HardEnvelope
  LD HL,EnvAttack         ; the envelope phase starts at EnvAttack
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET
HardEnvelope:
  CALL AyPrepare          ; registers 13 (shape), 11 and 12 (period), the
                          ; volume $FF. Ran in no recording
  LD A,(IY+$00)
  LD E,$0D
  CALL WriteAyRegister
  LD A,(IY+$04)
  LD E,$0B
  CALL WriteAyRegister
  INC E
  XOR A
  CALL WriteAyRegister
  LD (IX+$05),$FF
  JP AyDone

; Silence the AY: every channel off, the volumes 0, the effect locks off
;
; Mixer (register 7) all off ($3F set in AyMixer), registers 8-10 (volumes) 0,
; 11 = 1, 12 and 13 = 0; the AY records' flags (+$11) and volumes (+$05) to 0.
; Called by StartTune $C0D7, StopMusic $C00A and the glue at $858D (a request
; $FF while a tune plays; ran in no recording).
;
; Witness: L1 27 (c1, deaths, gameover, menu, opt x3).
Silence:
  CALL AyPrepare
  LD E,$07
  LD A,(AyMixer)
  OR $3F
  LD (AyMixer),A
  CALL WriteAyRegister
  XOR A
  INC E
  CALL WriteAyRegister
  INC E
  CALL WriteAyRegister
  INC E
  CALL WriteAyRegister
  LD A,$01
  INC E
  CALL WriteAyRegister
  INC E
  XOR A
  CALL WriteAyRegister
  INC E
  CALL WriteAyRegister
  LD (AyChannelA+$0011),A
  LD (AyChannelB+$0011),A
  LD (AyChannelC+$0011),A
  LD (AyChannelA+$0005),A
  LD (AyChannelB+$0005),A
  LD (AyChannelC+$0005),A
  JP AyDone

; Update the three AY channels by a frame and write registers 0-10
;
; Nothing when AyMixer has all six channel bits set (silent). UpdateChannel
; $D2D6 for A, B, C; DrumTimer counts down and at its end turns the burst's
; noise off in AyMixer. Then the registers: 7 = AyMixer bits 0-5; 0/1 = 2 x
; (A's period + vibrato offset + slide offset); 2/3 and 4/5 the same for B and
; C without the doubling; for a channel with noise (flags bit 1) its period's
; low byte becomes NoisePeriod; 6 = DrumNoise while a burst runs, else
; NoisePeriod, rotated right three times; 8-10 = the volumes / 8. The LD
; HL,$FFBF lines are leftovers: HL is loaded again before it is read.
;
; Called by PlayFrame $C17D at every frame of the glue.
;
; Witness: L1 49267 (c1, deaths, gameover, menu, rooms, opt x3).
AyUpdate:
  LD A,(AyMixer)
  AND $3F
  CP $3F
  RET Z
  LD IX,AyChannelA
  CALL UpdateChannel
  LD IX,AyChannelB
  CALL UpdateChannel
  LD IX,AyChannelC
  CALL UpdateChannel
  LD HL,DrumTimer         ; the drum burst's timer
  LD A,(HL)
  CP $FF
  JR Z,WriteAy
  DEC (HL)
  JP P,WriteAy
  LD A,(DrumChannel)
  CPL
  LD HL,AyMixer
  OR (HL)
  LD (HL),A
WriteAy:
  CALL AyPrepare          ; register 7: the mixer
  LD E,$07
  LD A,(AyMixer)
  AND $3F
  CALL WriteAyRegister
  LD IX,AyChannelA        ; channel A: (period + vibrato + slide) x 2
  LD E,$00
  LD HL,(AyChannelA+$0003)
  LD A,(IX+$09)
  ADD A,L
  LD L,A
  LD A,(IX+$0A)
  ADC A,H
  LD H,A
  LD A,(IX+$12)
  ADD A,L
  LD L,A
  LD A,(IX+$13)
  ADC A,H
  LD H,A
  ADD HL,HL
  LD A,H
  PUSH AF
  LD A,L
  LD HL,$FFBF
  BIT 1,(IX+$11)          ; noise on A: its period's low byte is the noise
                          ; period
  JP Z,WriteAyToneA
  LD (NoisePeriod),A
WriteAyToneA:
  CALL WriteAyRegister
  INC E
  POP AF
  CALL WriteAyRegister
  INC E
  LD HL,(AyChannelB+$0003) ; channel B: period + vibrato + slide
  LD A,(IX+$1D)
  ADD A,L
  LD L,A
  LD A,(IX+$1E)
  ADC A,H
  LD H,A
  LD A,(IX+$26)
  ADD A,L
  LD L,A
  LD A,(IX+$27)
  ADC A,H
  PUSH AF
  LD A,L
  LD HL,$FFBF
  BIT 1,(IX+$25)
  JP Z,WriteAyToneB
  LD (NoisePeriod),A
WriteAyToneB:
  CALL WriteAyRegister
  INC E
  POP AF
  CALL WriteAyRegister
  INC E
  LD HL,(AyChannelC+$0003) ; channel C
  LD A,(IX+$31)
  ADD A,L
  LD L,A
  LD A,(IX+$32)
  ADC A,H
  LD H,A
  LD A,(IX+$3A)
  ADD A,L
  LD L,A
  LD A,(IX+$3B)
  ADC A,H
  PUSH AF
  LD A,L
  LD HL,$FFBF
  BIT 1,(IX+$39)
  JP Z,WriteAyToneC
  LD (NoisePeriod),A
WriteAyToneC:
  CALL WriteAyRegister
  INC E
  POP AF
  CALL WriteAyRegister
  INC E
  LD A,(DrumTimer)        ; register 6: the drum's or the channel's noise
                          ; period
  CP $FF
  JR Z,NoiseFromChannel
  LD A,(DrumNoise)
  JP WriteAyNoise
NoiseFromChannel:
  LD A,(NoisePeriod)
WriteAyNoise:
  RRCA
  RRCA
  RRCA
  CALL WriteAyRegister
  LD E,$08                ; registers 8-10: the volumes / 8
  LD A,(AyChannelA+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAyRegister
  INC E
  LD A,(AyChannelB+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAyRegister
  INC E
  LD A,(AyChannelC+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAyRegister
  JP AyDone

; One AY channel's frame: the gate timer, the vibrato, the envelope phase
;
; IX = the AY record. Nothing when the channel is off in AyMixer. IY = its
; instrument. The gate timer +$06 counts down (0 and $FF stay); UpdateVibrato
; $D37E; then the phase routine at +$0D/+$0E (JP (HL)), or for a
; hardware-envelope instrument the wait at $D377.
;
; Witness: L1 138756 (c1, deaths, gameover, menu, rooms, opt x3).
UpdateChannel:
  LD A,(AyMixer)
  AND (IX+$02)
  CP (IX+$02)
  RET Z
  LD A,(IX+$0F)
  LD IYL,A
  LD A,(IX+$10)
  LD IYH,A
  LD A,(IX+$06)
  AND A
  JR Z,UpdateChannelPhase
  CP $FF
  JR Z,UpdateChannelPhase
  DEC (IX+$06)
UpdateChannelPhase:
  CALL UpdateVibrato
  BIT 2,(IY+$09)
  JP NZ,HardEnvelopeWait
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  JP (HL)                 ; the envelope phase: EnvAttack, EnvDecay, EnvSustain
                          ; or EnvRelease

; The attack: volume + instrument +0 up to the peak (+4), then the decay
;
; Reached through the AY record's +$0D/+$0E (JP (HL) at $D307).
;
; Witness: L1 14765 (c1, deaths, gameover, menu, rooms, opt x3).
EnvAttack:
  LD A,(IX+$05)
  ADD A,(IY+$00)
  CP (IY+$04)
  JR NC,EnvAttackPeak
  LD (IX+$05),A
  RET
EnvAttackPeak:
  LD A,(IY+$04)
  LD (IX+$05),A
  LD HL,EnvDecay
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; The decay: volume + instrument +1 down to the sustain level (+2), then the
; sustain
;
; Witness: L1 111733 (c1, deaths, gameover, menu, rooms, opt x3).
EnvDecay:
  LD A,(IX+$05)
  ADD A,(IY+$01)
  JP M,EnvDecayDone
  CP (IY+$02)
  JR C,EnvDecayDone
  LD (IX+$05),A
  RET
EnvDecayDone:
  LD A,(IY+$02)
  LD (IX+$05),A
  LD HL,EnvSustain
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; The sustain: hold until the gate timer is 0, then the release
;
; Witness: L1 7336 (c1, deaths, gameover, menu, rooms, opt x3).
EnvSustain:
  LD A,(IX+$06)
  AND A
  RET NZ
  LD HL,EnvRelease
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; The release: volume + instrument +3 down to 0, then the channel off
;
; At 0: the channel's off bits into AyMixer and the effect lock (flags bit 7)
; cleared: the tune may use channel A again.
;
; Witness: L1 199 (c1, deaths, gameover, menu, rooms, opt x3).
EnvRelease:
  LD A,(IX+$05)
  ADD A,(IY+$03)
  JP M,ChannelOff
  LD (IX+$05),A
  RET
ChannelOff:
  LD (IX+$05),$00
  LD A,(AyMixer)
  OR (IX+$02)
  LD (AyMixer),A
  RES 7,(IX+$11)
  RET
; This entry point is used by the routine at UpdateChannel.
HardEnvelopeWait:
  LD A,(IX+$06)           ; a hardware-envelope note: off when the gate timer
                          ; ends. Ran in no recording
  AND A
  RET NZ
  JR ChannelOff

; Step the channel's vibrato: the offset + the step, the step reversed at each
; sweep's end
;
; IX = the AY record, IY = the instrument. The delay +$07 first ($FF: stopped).
; Each frame: offset +$09/+$0A += step +$0B/+$0C; at the end of a sweep (+$08 =
; 0): instrument +6 = 0 goes on (an endless slide), +6 negative stops ($FF),
; else +$08 = +6 and the step is negated.
;
; Witness: L1 134033 (c1, deaths, gameover, menu, rooms, opt x3).
UpdateVibrato:
  LD A,(IX+$07)
  AND A
  JR Z,VibratoStep
  CP $FF
  RET Z
  DEC (IX+$07)
  RET NZ
VibratoStep:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD C,(IX+$0B)
  LD B,(IX+$0C)
  ADD HL,BC
  LD (IX+$09),L
  LD (IX+$0A),H
  DEC (IX+$08)
  RET NZ
  LD A,(IY+$06)           ; the sweep's end
  AND A
  RET Z
  JP P,VibratoReverse
  LD (IX+$07),$FF         ; width negative: stop. Ran in no recording
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

; Leftover set-up before AY writes: C = $FD, HL = $FFBF; falls into AyDone
;
; Neither value is read: WriteAyRegister loads BC itself. Called by StartNote,
; Silence and AyUpdate.
;
; Witness: L1 46279 (c1, deaths, gameover, menu, rooms, opt x3).
AyPrepare:
  LD C,$FD
  LD HL,$FFBF

; RET: the end of a batch of AY writes
;
; The tail of StartNote, Silence and AyUpdate jumps here; AyPrepare falls into
; it.
;
; Witness: L1 92558 (c1, deaths, gameover, menu, rooms, opt x3).
AyDone:
  RET

; Write A to AY register E
;
; OUT ($FFFD),E then OUT ($BFFD),A. BC is lost, E and A kept.
;
; Witness: L1 508961 (c1, deaths, gameover, menu, rooms, opt x3).
WriteAyRegister:
  LD BC,$FFFD
  OUT (C),E
  LD B,$BF
  OUT (C),A
  RET
