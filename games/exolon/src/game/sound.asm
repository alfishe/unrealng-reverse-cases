; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The AY sound effects (silent on a 48K)
; --------------------------------------------------------------------------------------------------------------------

; Write C to AY register A
;
; OUT ($FFFD),A selects the register, OUT ($BFFD),C writes it; AF, BC, HL kept.
; Runs on every machine: on a 48K the ports go nowhere (c1: 17 of 17 bytes
; executed). Callers: the tune (AySilence, TuneChannelStep, TuneNextEvent) and
; the effects (SoundEffectsTick, SfxWriteChannelA-C).
AyWrite:
  PUSH AF
  PUSH BC
  PUSH HL
  LD H,C
  LD BC,$FFFD
  OUT (C),A
  LD B,$BF
  OUT (C),H
  POP HL
  POP BC
  POP AF
  RET

; One tick of the 16 sound effect slots: up to three of them to the AY channels
;
; SfxChannelIndex $C5EA = 0, SfxMixer $C5E9 = $BF (all tones and noises off),
; SfxChannelBits $C5E7 = $F6 (tone A and noise A on). Each slot of SfxSlots
; $C5EB (16 bytes, 16 slots) that is active (+0 not $FF) steps (SfxSlotStep),
; and the channel bits rotate one place (RLC: B's, then C's). At the end
; register 6 = SfxNoise $C5E8 and register 7 = SfxMixer.
;
; The first three active slots in slot order get AY channels A, B and C
; (SfxToAyChannel); a fourth and later run on unheard. A slot that ends in this
; tick rotates the bits but takes no channel: the next slot's channel bits are
; then one place ahead of its channel (an engine quirk).
;
; Called three times a main loop pass ($75C5, $7601, $766B; 237 645 times each
; in the runs), on the 48K too: the 48K hears the beeper routines $7C26 / $7C40
; instead.
SoundEffectsTick:
  XOR A
  LD (SfxChannelIndex),A
  LD A,$BF
  LD (SfxMixer),A
  LD A,$F6
  LD (SfxChannelBits),A
  LD IX,SfxSlots
  LD B,$10
SoundEffectsSlot:
  PUSH IX
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,SoundEffectsNext
  CALL SfxSlotStep
  LD HL,SfxChannelBits
  RLC (HL)
SoundEffectsNext:
  POP BC
  POP IX
  LD DE,$0010
  ADD IX,DE
  DJNZ SoundEffectsSlot
  LD A,$06                ; register 6 = the noise period, register 7 = the
                          ; mixer
  LD BC,(SfxNoise)
  CALL AyWrite
  LD BC,(SfxMixer)
  INC A
  JP AyWrite

; One effect slot's tick: the next note when the note ends, the volume decay
;
; IX the slot. +3 (the note's ticks) - 1, at 0 SfxReadStream. +6 (the decay
; counter) - 1, at 0 reloaded from +7 and the volume +4 (when not 0) - the step
; +8 (no floor: a step that does not divide the volume wraps it). Then
; SfxToAyChannel.
SfxSlotStep:
  DEC (IX+$03)
  CALL Z,SfxReadStream
  DEC (IX+$06)
  JP NZ,SfxSlotStepOut
  LD A,(IX+$07)
  LD (IX+$06),A
  LD A,(IX+$04)
  OR A
  JP Z,SfxSlotStepOut
  SUB (IX+$08)
  LD (IX+$04),A
SfxSlotStepOut:
  JP SfxToAyChannel

; Read an effect slot's stream up to its next note
;
; The codes at +1/+2: $FF the effect's end (+0 = $FF, the slot free; the return
; to SfxSlotStep dropped, so no channel this tick). $FE n: the start volume +5
; = n. $FD p s: the decay (+7 = p, +6 = p / 2 + 1, +8 = s; SfxSetDecay, never
; ran). $FC m: the mixer mask +$0B (0 tone and noise, 7 noise only, $38 tone
; only). $FB n: SfxNoise = n, and n is also the note that follows (the code
; falls into the note test with A = n). A note: below $60 the note with the
; slot's length +$0C, $60-$FA the note code - $60 and then a length byte
; (+$0C). The period +9/+$0A = NotePeriods[note], the note's ticks +3 = +$0C,
; the volume +4 = +5.
;
; 23 streams in SoundEffects $C218 (sfx.py over every start the triggers name).
SfxReadStream:
  LD L,(IX+$01)
  LD H,(IX+$02)
; This entry point is used by the routines at SfxSetDecay and SfxCheckMixer.
SfxReadCode:
  LD A,(HL)
  CP $FF
  JR NZ,SfxCheckVolume
  LD (IX+$00),$FF
  POP AF
  RET
SfxCheckVolume:
  CP $FE                  ; $FE n
  JR NZ,SfxCheckDecay
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  INC HL
  JR SfxReadCode
SfxCheckDecay:
  CP $FD                  ; $FD falls into SfxSetDecay
  JR NZ,SfxCheckMixer

; Effect code $FD p s: the volume decay (never ran)
;
; +7 = p, +6 = p / 2 + 1, +8 = s. The streams with $FD ($C53F, $C54D, $C55D,
; $C56D, $C577, $C585, $C593, $C5BA, $C5C8) are those of the triggers that
; never ran (the ones at $C10E, $C116, $C126, $C16F, $C17F, $C195): no
; recording read them. The other effects decay with the slot's +6/+7/+8 as
; StartSoundEffect left them (+8 = 1) and the counters a previous effect left
; in the slot.
SfxSetDecay:
  INC HL
  LD A,(HL)
  LD (IX+$07),A
  SRL A
  INC A
  LD (IX+$06),A
  INC HL
  LD A,(HL)
  LD (IX+$08),A
  INC HL
  JR SfxReadCode

; Effect codes $FC (the mixer mask) and $FB (the noise period), then the note
;
; Used by the routine at SfxReadStream.
SfxCheckMixer:
  CP $FC
  JR NZ,SfxCheckNoise
  INC HL
  LD A,(HL)
  LD (IX+$0B),A
  INC HL
  JR SfxReadCode
SfxCheckNoise:
  CP $FB                  ; $FB n: the noise period, n kept in A as the note
  JR NZ,SfxNote
  INC HL
  LD A,(HL)
  LD (SfxNoise),A
SfxNote:
  CP $60                  ; a note: from $60 a length byte follows
  JR C,SfxNotePeriod
  SUB $60
  INC HL
  LD C,(HL)
  LD (IX+$0C),C
SfxNotePeriod:
  INC HL                  ; the note's period from NotePeriods
  LD (IX+$01),L
  LD (IX+$02),H
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,NotePeriods
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$09),E
  LD (IX+$0A),D
  LD A,(IX+$0C)           ; the note's ticks and the start volume
  LD (IX+$03),A
  LD A,(IX+$05)
  LD (IX+$04),A
  RET

; Hand an effect slot's period and volume to the next free AY channel
;
; SfxChannelIndex + 1; its old value picks SfxChannelWriters $C077 (0 A, 1 B, 2
; C, 3-15 SfxNoChannel), entered with DE = the period (+9/+$0A), C = the volume
; (+4).
SfxToAyChannel:
  LD A,(SfxChannelIndex)
  LD L,A
  INC A
  LD (SfxChannelIndex),A
  LD H,$00
  ADD HL,HL
  LD DE,SfxChannelWriters
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD E,(IX+$09)
  LD D,(IX+$0A)
  LD C,(IX+$04)
  JP (HL)

; The writers of AY channels A, B, C, then 13 times SfxNoChannel
;
; SfxToAyChannel's JP (HL): SfxWriteChannelA $C097, SfxWriteChannelB $C0B1,
; SfxWriteChannelC $C0CC, then $C7F3 (a RET).
SfxChannelWriters:
  DEFW SfxWriteChannelA,SfxWriteChannelB,SfxWriteChannelC,SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel
  DEFW SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel,SfxNoChannel

; AY channel A from an effect: the mixer bits, the volume and the period
;
; SfxMixer AND= (SfxChannelBits OR the slot's mask +$0B); register 8 = C,
; registers 0/1 = DE.
SfxWriteChannelA:
  LD HL,SfxMixer
  LD A,(SfxChannelBits)
  OR (IX+$0B)
  AND (HL)
  LD (HL),A
  LD A,$08
  CALL AyWrite
  XOR A
  LD C,E
  CALL AyWrite
  INC A
  LD C,D
  JP AyWrite

; AY channel B: the mixer bits, register 9 = C, registers 2/3 = DE
SfxWriteChannelB:
  LD HL,SfxMixer
  LD A,(SfxChannelBits)
  OR (IX+$0B)
  AND (HL)
  LD (HL),A
  LD A,$09
  CALL AyWrite
  LD A,$02
  LD C,E
  CALL AyWrite
  INC A
  LD C,D
  JP AyWrite

; AY channel C: the mixer bits, register 10 = C, registers 4/5 = DE
SfxWriteChannelC:
  LD HL,SfxMixer
  LD A,(SfxChannelBits)
  OR (IX+$0B)
  AND (HL)
  LD (HL),A
  LD A,$0A
  CALL AyWrite
  LD A,$04
  LD C,E
  CALL AyWrite
  INC A
  LD C,D
  JP AyWrite

; Start effect NoiseBurstSound in slot 13
;
; A noise burst falling from volume 13 to 3. Called by MoveShots at $8417 (419
; calls in the runs), after $9362 found a thing at the place of an entry of the
; table at $845F.
PlaySfxNoiseBurst:
  PUSH AF
  PUSH BC
  LD A,$0D
  LD BC,NoiseBurstSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect AmmoRefillSound in slot 2
;
; Called at $9980 right after the ammunition $8E5A is set to 99 (a refill), and
; at $9F65.
PlaySfxAmmoRefill:
  PUSH AF
  PUSH BC
  LD A,$02
  LD BC,SoundEffects
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect GrenadeRefillSound in slot 2
;
; Called at $99D6 right after the grenades $8E66 are set to 10.
PlaySfxGrenadeRefill:
  PUSH AF
  PUSH BC
  LD A,$02
  LD BC,GrenadeRefillSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect JingleASound in slot 4 (never ran)
;
; No caller in the image and no recording ran it; with the next two, a trigger
; whose sound is a tune-like phrase of decaying notes (code $FD): left from the
; version this engine came from.
PlaySfxJingleA:
  LD A,$04
  LD BC,JingleASound
  JP StartSoundEffect

; Start effects JingleBSound (slot 14) and JingleBBassSound (slot 5) (never
; ran)
;
; No caller, never ran.
PlaySfxJingleB:
  LD A,$0E
  LD BC,JingleBSound
  CALL StartSoundEffect
  LD A,$05
  LD BC,JingleBBassSound
  JP StartSoundEffect

; Start effect WobbleSound in slot 13 (never ran)
;
; No caller, never ran.
PlaySfxWobble:
  LD A,$0D
  LD BC,WobbleSound
  JP StartSoundEffect

; Start effect TrillSound in slot 5
;
; Called by $9EAF (which adds A to the counter $9ED6 the round end turns into a
; bonus) and by $A32B (PickupsVsPlayer). 156 calls in the runs.
PlaySfxTrill:
  PUSH AF
  PUSH BC
  LD A,$05
  LD BC,TrillSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect NoiseSweepSound in slot 7
;
; Called at $9DBB right after small sprite 8 (the round shot of SmallSprites)
; is drawn at $9DB8: a shot fired by the scenery's guns.
PlaySfxNoiseSweep:
  PUSH AF
  PUSH BC
  LD A,$07
  LD BC,NoiseSweepSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect BlastSound in slot 6
;
; Noise with a falling tone, volume 15 down to 1. Callers: $909F (after ten
; beeper delays of FireShell), $91A9, $9427.
PlaySfxBlast:
  PUSH AF
  PUSH BC
  LD A,$06
  LD BC,BlastSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect ExplosionSound in slot 8
;
; Called right after $981D and before a score is added ($9B79, $9BD0, $9E5B,
; $9E7F, $A63C): something shot and destroyed.
PlaySfxExplosion:
  PUSH AF
  PUSH BC
  LD A,$08
  LD BC,ExplosionSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect PulseSound in slot 13
;
; Called by Teleports ($98F3, $9928; 38 and 8 calls).
PlaySfxPulse:
  PUSH AF
  PUSH BC
  LD A,$0D
  LD BC,PulseSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effect RiseSound in slot 12 (never ran)
;
; No caller, never ran.
PlaySfxRise:
  LD A,$0C
  LD BC,RiseSound
  JP StartSoundEffect

; Start effect ShotSound in slot 15
;
; Called by the fire routine FireControl at $8372, right after the ammunition
; $8E5A is decremented (2625 calls in the runs): the player's laser shot.
PlaySfxShot:
  LD A,$0F
  LD BC,ShotSound
  JP StartSoundEffect

; Start effects ChordSound1-3 in slots 8, 9, 10 (never ran)
;
; A three-voice arpeggio. No caller, never ran.
PlaySfxChord:
  LD A,$08
  LD BC,ChordSound1
  CALL StartSoundEffect
  INC A
  LD BC,ChordSound2
  CALL StartSoundEffect
  INC A
  LD BC,ChordSound3
  JP StartSoundEffect

; Start effects FanfareSound (slot 0) and FanfareBassSound (slot 15) (never
; ran)
;
; No caller, never ran.
PlaySfxFanfare:
  PUSH AF
  PUSH BC
  XOR A
  LD BC,FanfareSound
  CALL StartSoundEffect
  LD A,$0F
  LD BC,FanfareBassSound
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effects HumSoundA (slot 1) and HumSoundB (slot 11)
;
; Two low notes (periods $0384 and $0392, 10 ticks, volume 12) beating against
; each other. Called by ForceFieldStep ($ABD6) on each of its passes while its
; object is on (9349 calls in the runs).
PlaySfxHum:
  PUSH AF
  PUSH BC
  LD A,$01
  LD BC,HumSoundA
  CALL StartSoundEffect
  LD A,$0B
  LD BC,HumSoundB
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start effects GrenadeSoundA (slot 9) and GrenadeSoundB (slot 15)
;
; Called when a grenade is thrown ($9254, after the grenades $8E66 are
; decremented): two sweeps a fifth apart rising in volume then falling.
PlaySfxGrenade:
  PUSH AF
  PUSH BC
  LD A,$09
  LD BC,GrenadeSoundA
  CALL StartSoundEffect
  LD A,$0F
  LD BC,GrenadeSoundB
  CALL StartSoundEffect
  POP BC
  POP AF
  RET

; Start the effect stream BC in slot A
;
; IX = SfxSlots + 16A; +0 = $FF while it is set up, +1/+2 = BC, +3 = 1 (read at
; the next tick), +4 = +5 = 15, +8 = 1, +9/+$0A = 0, +$0B = $38 (tone only),
; +$0C = 1, then +0 = 0 (active). A slot already playing is restarted. +6/+7
; are not set.
StartSoundEffect:
  PUSH IX
  PUSH HL
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,SfxSlots
  ADD HL,DE
  PUSH HL
  POP IX
  LD (IX+$00),$FF
  LD (IX+$01),C
  LD (IX+$02),B
  LD (IX+$03),$01
  LD (IX+$04),$0F
  LD (IX+$05),$0F
  LD (IX+$08),$01
  LD (IX+$09),$00
  LD (IX+$0A),$00
  LD (IX+$0B),$38
  LD (IX+$0C),$01
  LD (IX+$00),$00
  POP DE
  POP HL
  POP IX
  RET

; The 23 sound effect streams (codes of SfxReadStream)
;
; Each starts at the address its trigger passes and ends with $FF; sfx.py
; decodes them.
SoundEffects:
  DEFB $FE,$0D,$AF,$03,$47,$3F,$37,$FE,$0B,$4F,$47,$3F,$37,$FE,$09,$4F ; AmmoRefillSound,
  DEFB $47,$3F,$37,$FE,$07,$4F,$47,$3F,$37,$FE,$05,$4F,$47,$3F,$37,$FE ; slot 2:
  DEFB $03,$4F,$47,$3F,$37,$FF                                         ; arpeggios
                                                                       ; 79-71-63-55
                                                                       ; at volume
                                                                       ; 13, 11 ...
                                                                       ; 3
GrenadeRefillSound:
  DEFB $FE,$0D,$B4,$03,$4C,$44,$3C,$FE,$0B,$54,$4C,$44,$3C,$FE,$09,$54 ; slot 2:
  DEFB $4C,$44,$3C,$FE,$07,$54,$4C,$44,$3C,$FE,$05,$54,$4C,$44,$3C,$FE ; arpeggios
  DEFB $03,$54,$4C,$44,$3C,$FF                                         ; 84-76-68-60
                                                                       ; at volume
                                                                       ; 13 ... 3
NoiseBurstSound:
  DEFB $FC,$00,$FE,$0D,$FB,$00,$AB,$01,$FE,$0C,$4B,$FE,$0B,$4B,$FE,$0A ; slot 13:
  DEFB $4B,$FE,$05,$AB,$03,$FE,$04,$4B,$FE,$03,$4B,$FF                 ; tone and
                                                                       ; noise,
                                                                       ; note 75,
                                                                       ; volume 13
                                                                       ; down to 3
TrillSound:
  DEFB $FE,$0C,$9C,$03,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C ; slot 5:
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C ; note 60
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C ; and
  DEFB $00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C,$00,$3C ; silence
  DEFB $00,$3C,$00,$3C,$00,$3C,$FF                                     ; alternating,
                                                                       ; 3 ticks
                                                                       ; each, 34
                                                                       ; times
NoiseSweepSound:
  DEFB $FC,$07,$FE,$0E,$FB,$00,$63,$01,$FB,$02,$01,$FB,$04,$01,$FB,$06 ; slot 7:
  DEFB $01,$FB,$08,$01,$FB,$0A,$01,$FB,$0C,$01,$FB,$0E,$01,$FB,$10,$01 ; noise
  DEFB $FB,$12,$01,$FB,$14,$01,$FB,$16,$01,$FE,$08,$FB,$18,$01,$FE,$06 ; only, the
  DEFB $FB,$1A,$01,$FE,$04,$FB,$1C,$01,$FE,$02,$FB,$1E,$01,$FF         ; noise
                                                                       ; period
                                                                       ; stepping
                                                                       ; 0, 2, ...
                                                                       ; 30
BlastSound:
  DEFB $FC,$00,$FB,$1F,$FE,$0F,$88,$02,$27,$26,$25,$24,$FE,$0E,$23,$22 ; slot 6:
  DEFB $FE,$0D,$21,$20,$FE,$0C,$1F,$FE,$0B,$1E,$FE,$0A,$1D,$FE,$09,$1C ; noise 31
  DEFB $FE,$08,$1A,$FE,$07,$18,$FE,$06,$16,$FE,$05,$14,$FE,$04,$12,$FE ; and notes
  DEFB $03,$10,$FE,$02,$0E,$FE,$01,$0C,$FF                             ; 40 down to
                                                                       ; 12, volume
                                                                       ; 15 down to
                                                                       ; 1
ExplosionSound:
  DEFB $FC,$00,$FB,$00,$FE,$0E,$92,$01,$FE,$0D,$30,$FE,$0C,$2E,$FE,$0B ; slot 8:
  DEFB $2C,$FE,$09,$2A,$FE,$07,$28,$FE,$05,$26,$FE,$03,$24,$FF         ; noise and
                                                                       ; notes 50
                                                                       ; down to
                                                                       ; 36, volume
                                                                       ; 14 down to
                                                                       ; 3
HumSoundA:
  DEFB $FE,$0C,$61,$0A,$FF ; slot 1: note 1 (period $0384) for 10 ticks
HumSoundB:
  DEFB $FE,$0C,$62,$0A,$FF ; slot 11: note 2 (period $0392) for 10 ticks
GrenadeSoundA:
  DEFB $FE,$01,$AF,$01,$FE,$03,$4E,$FE,$05,$4D,$FE,$07,$4C,$FE,$09,$4B ; slot 9:
  DEFB $FE,$0B,$4A,$FE,$0D,$49,$FE,$0F,$48,$47,$46,$45,$FE,$0E,$44,$43 ; notes 79
  DEFB $42,$41,$FE,$0D,$40,$3F,$3E,$3D,$FE,$0C,$3C,$3B,$3A,$39,$FE,$0B ; down to
  DEFB $38,$37,$36,$35,$FE,$0A,$34,$33,$32,$31,$FE,$09,$30,$2F,$2E,$2D ; 24, the
  DEFB $FE,$08,$2C,$2B,$2A,$29,$FE,$07,$28,$27,$26,$25,$FE,$06,$24,$23 ; volume up
  DEFB $22,$21,$FE,$05,$20,$1F,$1E,$1D,$FE,$04,$1C,$1B,$1A,$19,$FE,$03 ; 1 to 15
  DEFB $18,$17,$16,$15,$FE,$02,$14,$14,$13,$12,$FE,$01,$11,$10,$0F,$0E ; then down
  DEFB $0D,$FF
GrenadeSoundB:
  DEFB $FE,$01,$9B,$01,$FE,$03,$3A,$FE,$05,$39,$FE,$07,$38,$FE,$09,$37 ; slot 15:
  DEFB $FE,$0B,$36,$FE,$0D,$35,$FE,$0F,$34,$33,$32,$31,$FE,$0E,$30,$2F ; the same
  DEFB $2E,$2D,$FE,$0D,$2C,$2B,$2A,$29,$FE,$0C,$28,$27,$26,$25,$FE,$0B ; from note
  DEFB $24,$23,$22,$21,$FE,$0A,$20,$1F,$1E,$1D,$FE,$09,$1C,$1B,$1A,$19 ; 59
  DEFB $FE,$08,$18,$17,$16,$15,$FE,$07,$14,$13,$12,$11,$FE,$06,$10,$0F
  DEFB $0E,$0D,$FE,$05,$0C,$0B,$0A,$13,$FE,$04,$12,$11,$10,$0F,$FE,$03
  DEFB $0E,$0D,$0C,$0B,$FE,$02,$0A,$0A,$09,$08,$FE,$01,$07,$06,$05,$04
  DEFB $03,$FF
FanfareSound:
  DEFB $FE,$0F,$9C,$02,$40,$43,$3B,$3F,$42,$3A,$3E,$41,$39,$3D,$40,$38 ; slot 0
  DEFB $3C,$3F,$37,$3B,$3E,$9C,$06,$FF                                 ; (never
                                                                       ; read): an
                                                                       ; arpeggio
                                                                       ; of 18
                                                                       ; notes,
                                                                       ; then 60
                                                                       ; held
PulseSound:
  DEFB $FC,$00,$FE,$0F,$9C,$01,$FE,$0E,$3C,$FE,$0D,$3C,$FE,$0C,$3C,$FE ; slot 13:
  DEFB $0F,$3C,$01,$FE,$0E,$3C,$FE,$0D,$3C,$FE,$0C,$3C,$FE,$0E,$3C,$FE ; note 60
  DEFB $0D,$3C,$FE,$0C,$3C,$FE,$0B,$3C,$FE,$0E,$3C,$FE,$0D,$3C,$FE,$0C ; with
  DEFB $3C,$FE,$0B,$3C,$FE,$0D,$3C,$FE,$0C,$3C,$FE,$0B,$3C,$FE,$0A,$3C ; tremolo
  DEFB $FE,$0D,$3C,$FE,$0C,$3C,$FE,$0B,$3C,$FE,$0A,$3C,$FE,$0C,$3C,$FE ; volumes 15
  DEFB $0B,$3C,$FE,$0A,$3C,$FE,$09,$3C,$FE,$0C,$3C,$FE,$0B,$3C,$FE,$0A ; ... 1
  DEFB $3C,$FE,$09,$3C,$FE,$0B,$3C,$FE,$0A,$3C,$FE,$09,$3C,$FE,$08,$3C
  DEFB $FE,$0B,$3C,$FE,$0A,$3C,$FE,$09,$3C,$FE,$08,$3C,$FE,$0A,$3C,$FE
  DEFB $09,$3C,$FE,$08,$3C,$FE,$07,$3C,$FE,$0A,$3C,$FE,$09,$3C,$FE,$08
  DEFB $3C,$FE,$07,$3C,$FE,$09,$3C,$FE,$08,$3C,$FE,$07,$3C,$FE,$06,$3C
  DEFB $FE,$09,$3C,$FE,$08,$3C,$FE,$07,$3C,$FE,$06,$3C,$FE,$08,$3C,$FE
  DEFB $07,$3C,$FE,$06,$3C,$FE,$05,$3C,$FE,$08,$3C,$FE,$07,$3C,$FE,$06
  DEFB $3C,$FE,$05,$3C,$FE,$07,$3C,$FE,$06,$3C,$FE,$05,$3C,$FE,$04,$3C
  DEFB $FE,$07,$3C,$FE,$06,$3C,$FE,$05,$3C,$FE,$04,$3C,$FF
FanfareBassSound:
  DEFB $FE,$0F,$FD,$01,$01,$90,$06,$2F,$2E,$2D,$2C,$2B,$30,$FF ; slot 15 (never
                                                               ; read): decay
                                                               ; 1,1, notes 48
                                                               ; down to 43
JingleBSound:
  DEFB $FE,$0F,$FD,$02,$01,$A3,$09,$A0,$03,$3E,$40,$A1,$06,$40,$3C,$FF ; slot 14
                                                                       ; (never
                                                                       ; read):
                                                                       ; decay 2,1,
                                                                       ; a phrase
                                                                       ; from note
                                                                       ; 67
JingleASound:
  DEFB $FE,$0F,$FD,$01,$01,$A3,$01,$41,$46,$45,$43,$41,$46,$A5,$02,$FF ; slot 4
                                                                       ; (never
                                                                       ; read):
                                                                       ; decay 1,1,
                                                                       ; a phrase
                                                                       ; from note
                                                                       ; 67
JingleBBassSound:
  DEFB $FE,$0C,$FD,$04,$01,$9C,$0C,$37,$3C,$FF ; slot 5 (never read): decay
                                               ; 4,1, notes 60 55 60
ChordSound1:
  DEFB $FE,$0F,$FD,$01,$01,$A8,$04,$43,$40,$3C,$40,$43,$48,$FF ; slot 8 (never
                                                               ; read): decay
                                                               ; 1,1, 72 67 64
                                                               ; 60 64 67 72
ChordSound2:
  DEFB $FE,$0A,$FD,$01,$01,$A3,$04,$40,$3C,$37,$3C,$40,$43,$FF ; slot 9 (never
                                                               ; read): 67 64
                                                               ; 60 55 60 64 67
ChordSound3:
  DEFB $FE,$0A,$FD,$01,$01,$A0,$04,$3C,$37,$34,$37,$3C,$40,$FF ; slot 10 (never
                                                               ; read): 64 60
                                                               ; 55 52 55 60 64
ShotSound:
  DEFB $FC,$00,$FE,$0D,$FB,$0F,$74,$01,$FE,$0B,$14,$FE,$09,$14,$FE,$07 ; slot 15:
  DEFB $14,$FE,$03,$74,$03,$FE,$02,$14,$FF                             ; noise 15
                                                                       ; and note
                                                                       ; 20 at
                                                                       ; volume 13
                                                                       ; down to 2
WobbleSound:
  DEFB $FE,$0F,$FD,$02,$01,$A5,$02,$46,$47,$48,$47,$46,$45,$FF ; slot 13 (never
                                                               ; read): decay
                                                               ; 2,1, notes
                                                               ; 69-72-69
RiseSound:
  DEFB $FE,$0D,$FD,$03,$01,$FC,$00,$FB,$00,$88,$03,$89,$01,$2A,$2B,$2C ; slot 12
  DEFB $2D,$2E,$2F,$30,$31,$32,$33,$34,$35,$36,$37,$98,$04,$FF         ; (never
                                                                       ; read):
                                                                       ; decay 3,1,
                                                                       ; noise and
                                                                       ; notes 40
                                                                       ; up to 56
  DEFB $00                ; one spare byte (0)
SfxChannelBits:
  DEFB $00                ; the mixer bits of the channel being handed out ($F6
                          ; rotated)
SfxNoise:
  DEFB $00                ; the noise period to register 6
SfxMixer:
  DEFB $00                ; the mixer value to register 7
SfxChannelIndex:
  DEFB $00                ; the AY channels handed out in this tick
SfxSlots:
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 16 slots
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; of 16
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; bytes: +0
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $FF free /
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 0 active,
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +1/+2 the
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; stream, +3
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the note's
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ticks, +4
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; volume, +5
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the start
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; volume,
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; +6/+7 the
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; decay
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; counter
                                                                       ; and its
                                                                       ; reload, +8
                                                                       ; the decay
                                                                       ; step,
                                                                       ; +9/+$0A
                                                                       ; the
                                                                       ; period,
                                                                       ; +$0B the
                                                                       ; mixer
                                                                       ; mask, +$0C
                                                                       ; the note
                                                                       ; length
NotePeriods:
  DEFB $00,$00,$84,$03,$92,$03,$8E,$0C,$DA,$0B,$2F,$0B,$8F,$0A,$F7,$09 ; 96 AY tone
  DEFB $68,$09,$E1,$08,$61,$08,$E9,$07,$77,$07,$0C,$07,$A7,$06,$47,$06 ; periods: 0
  DEFB $ED,$05,$98,$05,$47,$05,$FC,$04,$B4,$04,$70,$04,$31,$04,$F4,$03 ; (silence),
                                                                       ; $0384,
                                                                       ; $0392,
                                                                       ; then from
                                                                       ; 3 the
                                                                       ; semitones
                                                                       ; $0C8E down
                                                                       ; to $0010;
                                                                       ; the tune
                                                                       ; reads from
                                                                       ; entry 24
                                                                       ; ($C71B)
NotePeriodsTune:
  DEFB $BC,$03,$86,$03,$53,$03,$24,$03,$F6,$02,$CC,$02,$A4,$02,$7E,$02 ; entry 24:
  DEFB $5A,$02,$38,$02,$18,$02,$FA,$01,$DE,$01,$C3,$01,$AA,$01,$92,$01 ; the tune's
  DEFB $7B,$01,$66,$01,$52,$01,$3F,$01,$2D,$01,$1C,$01,$0C,$01,$FD,$00 ; note 0
  DEFB $EF,$00,$E1,$00,$D5,$00,$C9,$00,$BE,$00,$B3,$00,$A9,$00,$9F,$00
  DEFB $96,$00,$8E,$00,$86,$00,$7F,$00,$77,$00,$71,$00,$6A,$00,$64,$00
  DEFB $5F,$00,$59,$00,$54,$00,$50,$00,$4B,$00,$47,$00,$43,$00,$3F,$00
  DEFB $3C,$00,$38,$00,$35,$00,$32,$00,$2F,$00,$2D,$00,$2A,$00,$28,$00
  DEFB $26,$00,$24,$00,$22,$00,$20,$00,$1E,$00,$1C,$00,$1B,$00,$19,$00
  DEFB $18,$00,$16,$00,$15,$00,$14,$00,$13,$00,$12,$00,$11,$00,$10,$00
CpcKeyMatrix:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; 10 bytes ($FF): the Amstrad
                                               ; CPC keyboard rows
                                               ; CpcReadKeyboard writes (never
                                               ; written in any recording)
