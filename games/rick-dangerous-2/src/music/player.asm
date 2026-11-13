; --------------------------------------------------------------------------------------------------------------------
; player.asm: The voices: the period table, the voice records, the envelopes and sweeps, the AY registers
;
; Three voice records (VoiceA-C, 18 bytes) hold what the AY plays: the period, the volume and its envelope phase, the
; sustain count, the pitch sweep. A note of a tune or an effect starts a voice (StartVoice, the original SOUND); every
; frame UpdateVoices runs each voice's envelope and sweep and writes AY registers 0-10. Resource: tables/periods.csv.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C672

; The AY tone periods of 85 semitones: A#0 (3822) up to A7 (32), then 24
;
; The note index is the pattern's note + the transpose + 12 (SequenceChannel
; $CBB6) plus an ornament's step (UpdateOrnament $CC6F); SetPitch $CCB5 reads
; the word. Index i sounds about MIDI note 22 + i with the 128K's AY clock of
; 1.7734 MHz (period 3822 = 29.0 Hz); index 20 (1236) and 24 (988) are about
; half a semitone flat of their neighbours' steps and the last (24, index 84)
; is far above A7.
Periods:
  INCBIN "res/tables/periods.bin",$0000,170

; The AY mixer (register 7) as written: bits 0-2 tone A-C off, bits 3-5 noise
; A-C off
;
; All of a voice's bits set means the voice is free (UpdateVoice $C8D6,
; PickEffectVoice $CD0A); $3F means silence and UpdateVoices does nothing.
; Written by StartVoice (the voice's bits cleared by its flags), SilenceAy (|
; $3F), VoiceOff $C965 (| the voice's bits); written to the AY by UpdateVoices
; and SilenceAy. Initial $3F.
MixerShadow:
  DEFB $3F

; Voice A (AY channel A, 18 bytes; IX in StartVoice, UpdateVoice, SetPitch)
;
; +0 the mixer AND mask that turns the tone on ($FE), +1 the one for the noise
; ($F7), +2 the voice's mixer bits ($09); +3/+4 the tone period; +5 the volume
; (0-127; $FF with the AY envelope); +6 the sustain frames left ($FF never
; ends, 0 releases); +7 the frames before the sweep ($FF none); +8 the sweep
; frames left; +9/+$0A the sweep's period offset; +$0B/+$0C the sweep step;
; +$0D/+$0E the envelope phase routine (EnvelopeAttack, EnvelopeDecay,
; EnvelopeSustain, EnvelopeRelease); +$0F/+$10 the instrument; +$11 the
; instrument's flags.
;
; The initial bytes from +3 are text of the author's source: "et pitch (with "
; (the voice is free at the start, MixerShadow $3F). Read and written by
; StartVoice, UpdateVoice, SweepPitch, the envelope phases, UpdateVoices,
; SetPitch, SilenceAy (+5, +$11).
VoiceA:
  DEFB $FE,$F7,$09
  DEFB $65,$74,$20        ; +3: the tone period (word), +5 the volume, +6 the
  DEFB $70,$69,$74        ; sustain frames, +7 the sweep delay, +8 the sweep
  DEFB $63,$68,$20        ; count, +9/+$0A the sweep offset, +$0B/+$0C the
  DEFB $28,$77,$69        ; sweep step, +$0D/+$0E the phase routine, +$0F/+$10
  DEFB $74,$68,$20        ; the instrument, +$11 the flags

; Voice B (AY channel B), the fields as VoiceA
;
; Masks $FD, $EF, bits $12. Initial bytes from +3: "gle offset)", CR, LF, "SE"
; (text of the source).
VoiceB:
  DEFB $FD,$EF,$12
  DEFB $67,$6C,$65        ; +3 ... +$11 as VoiceA
  DEFB $20,$6F,$66
  DEFB $66,$73,$65
  DEFB $74,$29,$0D
  DEFB $0A,$53,$45

; Voice C (AY channel C), the fields as VoiceA
;
; Masks $FB, $DF, bits $24. Initial bytes from +3: "ITCH: ADD A,A", CR, LF
; (text of the source: the label SETPITCH of SetPitch $CCB5).
VoiceC:
  DEFB $FB,$DF,$24
  DEFB $49,$54,$43        ; +3 ... +$11 as VoiceA
  DEFB $48,$3A,$20
  DEFB $41,$44,$44
  DEFB $20,$41,$2C
  DEFB $41,$0D,$0A

; The noise source: the period low byte (+ sweep) of the last voice with noise
;
; UpdateVoices: written when a voice's flags have bit 1; register 6 gets it
; rotated right three times (the AY keeps bits 0-4: the byte's bits 3-7).
; Initial 0.
NoiseShadow:
  DEFB $00

; Start voice IX with instrument IY, period HL, sustain C (the original SOUND)
;
; Copies the instrument into the voice: +$0F/+$10 = IY, period +3/+4 = HL,
; sustain +6 = C, sweep delay +7 = IY+5, sweep count +8 = (IY+6 AND $7F) / 2
; (at least 1: the first swing is half), step +$0B/+$0C = IY+7/+8, offset
; +9/+$0A = 0, flags +$11 = IY+9. The voice's mixer bits are set, then cleared
; for the tone (flags bit 0) and the noise (bit 1). Without bit 2 the envelope
; starts at EnvelopeAttack from the volume the voice had (a new note does not
; restart from 0); with bit 2 the AY's envelope: register 13 = IY+0 (shape), 11
; = IY+4, 12 = 0, volume $FF (register value 31: the envelope).
;
; Interrupts are disabled (DI) and left so. Called by SequenceChannel $CBEE (a
; note, unless the voice's flags have bit 7) and MusicEffect $CCFE (an effect):
; 2134 runs in the 9 builds, 39 of them effects (from $CCFE). The AY envelope
; branch is not executed in any recording (no instrument, and no effect called,
; has bit 2).
;
; Witness: L1 2331 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
StartVoice:
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
  JR NZ,StartVoiceSweepCount
  LD A,$01
StartVoiceSweepCount:
  LD (IX+$08),A
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
  JR Z,StartVoiceNoise
  AND (IX+$00)
StartVoiceNoise:
  BIT 1,C                 ; bit 1: the noise on
  JR Z,StartVoiceStoreMixer
  AND (IX+$01)
StartVoiceStoreMixer:
  LD (MixerShadow),A
  BIT 2,C
  JR NZ,StartVoiceHardwareEnvelope
  LD HL,EnvelopeAttack
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET
StartVoiceHardwareEnvelope:
  CALL AyAccessBegin      ; bit 2 (not executed in any recording)
  LD A,(IY+$00)
  LD C,$0D
  CALL WriteAyRegister
  LD A,(IY+$04)
  LD C,$0B
  CALL WriteAyRegister
  INC C
  XOR A
  CALL WriteAyRegister
  LD (IX+$05),$FF
  JP AyAccessEnd

; Silence the AY and free all three voices
;
; Mixer register 7 = MixerShadow | $3F (all off), volumes 8-10 = 0, envelope
; period 11 = 1, 12 = 0, shape 13 = 0; the voices' volumes (+5) and flags
; (+$11) = 0. Called by MusicStartTune only: 17 runs in the 9 builds.
;
; Witness: L1 18 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
SilenceAy:
  CALL AyAccessBegin
  LD C,$07
  LD A,(MixerShadow)
  OR $3F
  LD (MixerShadow),A
  CALL WriteAyRegister
  XOR A
  INC C
  CALL WriteAyRegister
  INC C
  CALL WriteAyRegister
  INC C
  CALL WriteAyRegister
  LD A,$01
  INC C
  CALL WriteAyRegister
  INC C
  XOR A
  CALL WriteAyRegister
  INC C
  CALL WriteAyRegister
  LD (VoiceA+$0011),A
  LD (VoiceB+$0011),A
  LD (VoiceC+$0011),A
  LD (VoiceA+$0005),A
  LD (VoiceB+$0005),A
  LD (VoiceC+$0005),A
  JP AyAccessEnd

; Every frame: the three voices' envelopes and sweeps, then AY registers 0-10
;
; Nothing when MixerShadow has all six bits set. Otherwise UpdateVoice for A,
; B, C, then register 7 = MixerShadow, registers 0-5 = each voice's period +
; sweep offset (+3/+4 + +9/+$0A), register 6 = NoiseShadow rotated right 3
; times (set from the low byte of each voice with noise, C winning), registers
; 8-10 = each voice's volume / 8. Called by MusicFrame every frame: 23 034 runs
; in the 9 builds.
;
; Witness: L1 24223 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
UpdateVoices:
  LD A,(MixerShadow)
  AND $3F
  CP $3F
  RET Z
  LD IX,VoiceA
  CALL UpdateVoice
  LD IX,VoiceB
  CALL UpdateVoice
  LD IX,VoiceC
  CALL UpdateVoice
  CALL AyAccessBegin
  LD IX,VoiceA
  LD C,$07
  LD A,(MixerShadow)
  CALL WriteAyRegister
  LD C,$00
  LD A,(VoiceA+$0003)
  ADD A,(IX+$09)
  BIT 1,(IX+$11)
  JP Z,WriteToneAFine
  LD (NoiseShadow),A
WriteToneAFine:
  CALL WriteAyRegister    ; register 0
  INC C
  LD A,(VoiceA+$0004)
  ADC A,(IX+$0A)
  CALL WriteAyRegister
  INC C
  LD A,(VoiceB+$0003)
  ADD A,(IX+$1B)
  BIT 1,(IX+$23)
  JP Z,WriteToneBFine
  LD (NoiseShadow),A
WriteToneBFine:
  CALL WriteAyRegister    ; register 2
  INC C
  LD A,(VoiceB+$0004)
  ADC A,(IX+$1C)
  CALL WriteAyRegister
  INC C
  LD A,(VoiceC+$0003)
  ADD A,(IX+$2D)
  BIT 1,(IX+$35)
  JP Z,WriteToneCFine
  LD (NoiseShadow),A
WriteToneCFine:
  CALL WriteAyRegister    ; register 4
  INC C
  LD A,(VoiceC+$0004)
  ADC A,(IX+$2E)
  CALL WriteAyRegister
  INC C
  LD A,(NoiseShadow)
  RRCA
  RRCA
  RRCA
  CALL WriteAyRegister
  LD C,$08
  LD A,(VoiceA+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAyRegister
  INC C
  LD A,(VoiceB+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAyRegister
  INC C
  LD A,(VoiceC+$0005)
  SRL A
  SRL A
  SRL A
  CALL WriteAyRegister
  JP AyAccessEnd

; One frame of voice IX: the sustain count, the sweep, the envelope phase
;
; Returns at once for a free voice. IY = the instrument (+$0F/+$10). The
; sustain count +6 goes down unless 0 or $FF; SweepPitch; then the phase
; routine at +$0D/+$0E (JP (HL)), or with the AY envelope (flags bit 2)
; HardwareEnvelopeWait. 32 025 runs in the 9 builds.
;
; Witness: L1 34617 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
UpdateVoice:
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
  JR Z,UpdateVoiceSweep
  CP $FF
  JR Z,UpdateVoiceSweep
  DEC (IX+$06)
UpdateVoiceSweep:
  CALL SweepPitch
  BIT 2,(IY+$09)
  JP NZ,HardwareEnvelopeWait
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  JP (HL)

; Volume up by the attack step until the peak, then EnvelopeDecay
;
; IX+5 += IY+0; at IY+4 or above it is set to IY+4 and the phase becomes
; EnvelopeDecay. Reached by JP (HL) from UpdateVoice: 2237 runs in the 9
; builds.
;
; Witness: L1 2442 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
EnvelopeAttack:
  LD A,(IX+$05)
  ADD A,(IY+$00)
  CP (IY+$04)
  JR NC,AttackPeak
  LD (IX+$05),A
  RET
AttackPeak:
  LD A,(IY+$04)
  LD (IX+$05),A
  LD HL,EnvelopeDecay
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Volume by the decay step until the sustain level, then EnvelopeSustain
;
; IX+5 += IY+1 (signed); below IY+2 (or negative) it is set to IY+2 and the
; phase becomes EnvelopeSustain. 15 942 runs in the 9 builds.
;
; Witness: L1 17515 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
EnvelopeDecay:
  LD A,(IX+$05)
  ADD A,(IY+$01)
  JP M,DecayAtSustain
  CP (IY+$02)
  JR C,DecayAtSustain
  LD (IX+$05),A
  RET
DecayAtSustain:
  LD A,(IY+$02)
  LD (IX+$05),A
  LD HL,EnvelopeSustain
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Hold the volume until the sustain count is 0, then EnvelopeRelease
;
; The count IX+6 is the note's duration or the effect's +$0C. 9964 runs in the
; 9 builds.
;
; Witness: L1 10418 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
EnvelopeSustain:
  LD A,(IX+$06)
  AND A
  RET NZ
  LD HL,EnvelopeRelease
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Volume by the release step down to 0, then the voice is off
;
; IX+5 += IY+3 (signed); when it goes negative VoiceOff: volume 0, the voice's
; bits set in MixerShadow (the voice is free), bit 7 of the flags cleared.
; HardwareEnvelopeWait (the AY envelope) waits for the sustain count and goes
; to VoiceOff. 561 runs in the 9 builds; VoiceOff 46 runs (l1q, 10 builds with
; sec-l1-s8); HardwareEnvelopeWait not executed in any recording.
;
; Witness: L1 622 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2, load-l4).
EnvelopeRelease:
  LD A,(IX+$05)
  ADD A,(IY+$03)
  JP M,VoiceOff
  LD (IX+$05),A
  RET
VoiceOff:
  LD (IX+$05),$00
  LD A,(MixerShadow)
  OR (IX+$02)
  LD (MixerShadow),A
  RES 7,(IX+$11)
  RET
; This entry point is used by the routine at UpdateVoice.
HardwareEnvelopeWait:
  LD A,(IX+$06)           ; the AY envelope: off when the sustain count is 0
                          ; (not executed in any recording)
  AND A
  RET NZ
  JR VoiceOff

; One frame of voice IX's pitch sweep
;
; The delay +7 counts down ($FF: no sweep); once at 0 the offset +9/+$0A grows
; by the step +$0B/+$0C each frame. When the count +8 runs out: the
; instrument's +6 = 0 keeps sweeping (the count wraps to 256), bit 7 stops it
; (+7 = $FF), else the count is reloaded with +6 and the step negated (a
; vibrato around the note). 28 704 runs in the 9 builds; the reversal 1535
; (l1q, 10 builds with sec-l1-s8).
;
; Witness: L1 30997 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
SweepPitch:
  LD A,(IX+$07)
  AND A
  JR Z,SweepStep
  CP $FF
  RET Z
  DEC (IX+$07)
  RET NZ
SweepStep:
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
  JP P,SweepReverse
  LD (IX+$07),$FF
  RET
SweepReverse:
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

; RET: a hook before the AY writes
;
; A RET called before every group of AY writes (StartVoice, SilenceAy,
; UpdateVoices); AyAccessEnd ends them. Room for a patch (paging, DI); does
; nothing here. 10 692 runs in the 9 builds.
;
; Witness: L1 11557 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
AyAccessBegin:
  RET

; RET: a hook after the AY writes
;
; Jumped to at the end of StartVoice, SilenceAy and UpdateVoices: their RET. 10
; 692 runs in the 9 builds.
;
; Witness: L1 11557 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
AyAccessEnd:
  RET

; AY register C = A
;
; OUT ($FFFD) the register, OUT ($BFFD) the value. Keeps BC; E changed. 117 544
; runs in the 9 builds.
;
; Witness: L1 127055 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
WriteAyRegister:
  PUSH BC
  LD E,C
  LD BC,$FFFD
  OUT (C),E
  LD B,$BF
  OUT (C),A
  POP BC
  RET

; A tune runs: $FF, 1 while its last notes die away, 0 none
;
; Set to $FF by MusicStartTune. MusicFrame: the OR of the channels' +$0D; when
; all are 0, 1 while a voice still sounds, else 0. MusicEffect plays nothing
; while it is not 0 (341 of the 385 effect calls in the 9 builds were dropped
; so). ReadMusicByte $7ABF in the game reads it (no caller).
MusicPlaying:
  DEFB $00

; Channel A of the tune (21 bytes; IY in SequenceChannel, PatternCommand,
; UpdateOrnament)
;
; +0 the channel's first instrument slot in InstrumentSlots (0, 8, 16:
; constant); +1/+2 the order list pointer; +3/+4 the pattern's start; +5/+6 the
; pattern pointer; +7/+8 the instrument (Instruments + slot value); +9 the
; times the pattern still plays; +$0A the transpose; +$0B $FF when the pattern
; has ended; +$0C the frames the note still lasts; +$0D $FF while the order
; list runs, 0 at its end; +$0E the note's period index; +$0F the ornament
; number; +$10/+$11 the ornament step pointer; +$12 the step's frames left;
; +$13 the steps left; +$14 the ornament state (bit 7 running, bit 6 start at
; the next frame, bits 0-5 the number).
;
; MusicStartTune sets +1/+2, +7-+$0D, +$0F. The initial bytes from +1 are text
; of the author's source: LF, "$3:", TAB, "LD", TAB, "L,(IY+10)", CR, LF, TAB
; (MusicEffect's lines).
ChannelA:
  DEFB $00
  DEFB $0A,$24,$33,$3A,$09,$4C,$44 ; +1 ... +$14 as above
  DEFB $09,$4C,$2C,$28,$49,$59,$2B
  DEFB $31,$30,$29,$0D,$0A,$09

; Channel B of the tune (21 bytes), the fields as ChannelA
;
; +0 = 8. Initial bytes from +1: text of the source ("D", TAB, "H,(IY+11)",
; ...).
ChannelB:
  DEFB $08
  DEFB $44,$09,$48,$2C,$28,$49,$59 ; +1 ... +$14
  DEFB $2B,$31,$31,$29,$0D,$0A,$09
  DEFB $4C,$44,$09,$43,$2C,$28

; Channel C of the tune (21 bytes), the fields as ChannelA
;
; +0 = 16. Initial bytes from +1: text of the source ("Y+12)", CR, LF, CR, LF,
; TAB, "CALL", TAB, "SOUND", ...).
ChannelC:
  DEFB $10
  DEFB $59,$2B,$31,$32,$29,$0D,$0A ; +1 ... +$14
  DEFB $0D,$0A,$09,$43,$41,$4C,$4C
  DEFB $09,$53,$4F,$55,$4E,$44

; Eight instrument offsets per channel: 0, 10, ... 70
;
; MusicStartTune fills each channel's 8 bytes with 0, 10, ... 70 (the
; instruments 0-7, Instruments + offset); an order list byte $C0-$FD could
; change one (none does); PatternCommand reads them for $80-$87. Initial bytes:
; text of the source.
InstrumentSlots:
  DEFB $0D,$0A,$0D,$0A,$24,$32,$3A,$09
  DEFB $50,$4F,$50,$09,$49,$59,$0D,$0A
  DEFB $09,$50,$4F,$50,$09,$49,$58,$0D

; Start tune A: silence, then the three channels from TuneTable
;
; SilenceAy; the order lists from TuneTable + 6 A into the channels' +1/+2; +9
; = 1 (play once), +$0A = 0 (no transpose), +$0B = $FF (read the order list at
; the next frame), +$0C = 1, +$0D = $FF, +$0F = 0 (no ornament), +7/+8 =
; Instruments; InstrumentSlots = 0, 10, ... 70 three times; MusicPlaying = $FF.
;
; Called from StartTune $7AAD through CallRam1 (17 runs in the 9 builds: tunes
; 0, 2 and 4-9).
;
; Witness: L1 18 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
MusicStartTune:
  PUSH AF
  CALL SilenceAy
  POP AF
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A
  LD HL,TuneTable
  ADD A,L
  LD L,A
  JR NC,MusicStartTuneChannels
  INC H
MusicStartTuneChannels:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChannelA+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChannelB+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ChannelC+$0001),DE
  XOR A
  LD (ChannelA+$000A),A
  LD (ChannelB+$000A),A
  LD (ChannelC+$000A),A
  LD (ChannelA+$000F),A
  LD (ChannelB+$000F),A
  LD (ChannelC+$000F),A
  CPL
  LD (ChannelA+$000B),A
  LD (ChannelB+$000B),A
  LD (ChannelC+$000B),A
  LD A,$01
  LD (ChannelA+$0009),A
  LD (ChannelB+$0009),A
  LD (ChannelC+$0009),A
  LD (ChannelA+$000C),A
  LD (ChannelB+$000C),A
  LD (ChannelC+$000C),A
  LD HL,InstrumentSlots
  LD BC,$030A
FillSlotsChannel:
  XOR A
FillSlotsLoop:
  LD (HL),A
  INC HL
  ADD A,C
  LD (HL),A
  INC HL
  ADD A,C
  CP $50
  JR NZ,FillSlotsLoop
  DJNZ FillSlotsChannel
  LD HL,Instruments
  LD (ChannelA+$0007),HL
  LD (ChannelB+$0007),HL
  LD (ChannelC+$0007),HL
  LD A,$FF
  LD (ChannelA+$000D),A
  LD (ChannelB+$000D),A
  LD (ChannelC+$000D),A
  LD (MusicPlaying),A
  RET

; Every frame: UpdateVoices, then one step of the tune on each channel
;
; UpdateVoices; nothing more when MusicPlaying is 0. MusicPlaying = the OR of
; the channels' +$0D; when 0 it is set to 1 while a voice sounds (0 when all
; are free) and nothing more; else SequenceChannel for A, B and C (IY =
; ChannelA-C, IX = VoiceA-C; C falls into SequenceChannel).
;
; Called from MusicFrameCall $7AB6 every interrupt: 23 034 runs in the 9
; builds, the channels 10 060.
;
; Witness: L1 24223 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
MusicFrame:
  CALL UpdateVoices
  LD A,(MusicPlaying)
  AND A
  RET Z
  LD A,(ChannelA+$000D)
  LD HL,ChannelB+$000D
  OR (HL)
  LD HL,ChannelC+$000D
  OR (HL)
  LD (MusicPlaying),A
  JR NZ,MusicFrameChannels
  XOR A
  LD (MusicPlaying),A
  LD A,(MixerShadow)
  AND $3F
  CP $3F
  RET Z
  LD A,$01
  LD (MusicPlaying),A
  RET
MusicFrameChannels:
  LD IY,ChannelA
  LD IX,VoiceA
  CALL SequenceChannel
  LD IY,ChannelB
  LD IX,VoiceB
  CALL SequenceChannel
  LD IY,ChannelC
  LD IX,VoiceC
