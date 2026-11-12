; --------------------------------------------------------------------------------------------------------------------
; whittaker-platoon-module.asm: David Whittaker's driver (Platoon): init, play, the pattern reader, envelopes, ornaments, effects
;
; Two entries: MusicInit $C000 starts the tune whose number is the operand of its first LD A,n ($C001): the tempo and
; the three order lists from its 7-byte record in the song table (SongTable, $C8ED), every channel's record reset;
; MusicPlay $C0C1 plays one frame: EffectFrame (a sound effect, if one runs), then while the music is on, on a tempo
; frame each channel whose duration ran out reads its pattern (ChannelTick, ReadPattern), and for each channel
; ChannelFrame gives the tone period and the volume into AYRegisters; a running effect overrides channels A and C;
; WriteAY sends registers 11 down to 0.
;
; A pattern: a note $00-$7F (PeriodTable index plus the transposition), a command $80-$91 through CommandOffsets
; (rest, sweep off / up / down, slide, bend up / down, end of the pattern, sweep, transposition, tone, noise, tone and
; noise, flag, stop, hold, lock, unlock), $B8-$BF the tempo, $C0-$CF an ornament (OrnamentOffsets), $D0-$DF a volume
; envelope (EnvelopeTable), $E0-$FF the duration of the notes after it. The format is in tools/res_whittaker.py.
; --------------------------------------------------------------------------------------------------------------------

; Start the tune (LD A,n: 3 in both variants): its tempo and the three
; channels' order lists
;
; HL = SongTable + 7 * the tune: the tempo into TempoReload, then for each
; channel (IX = ChannelA, ChannelB, ChannelC, 33 bytes apart) the order list's
; address (+$03 / +$04), its first pattern (+$01 / +$02), the order offset 2
; (+$05 / +$06), the duration count 1, the flags, sweep and lock cleared. Last
; the transposition 0, the tempo counter 1 and MusicOn = 1.
MusicInit:
  LD A,$03
  LD HL,MusicOn
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD C,A
  ADD A,A
  ADD A,C
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,SongTable
  ADD HL,BC
  LD A,(HL)
  LD (TempoReload+$0001),A
  INC HL
  LD IX,ChannelRecords
  LD C,$21
  LD A,$03
l_C023:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  LD (IX+$10),$01
  LD (IX+$00),B
  LD (IX+$1D),B
  LD (IX+$1F),B
  LD (IX+$03),E
  LD (IX+$04),D
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$05),$02
  LD (IX+$06),B
  POP HL
  LD (IX+$01),E
  LD (IX+$02),D
  ADD IX,BC
  DEC A
  JR NZ,l_C023
  LD (Transposition+$0001),A
  INC A
  LD (TempoCounter),A
  LD (MusicOn),A
  RET

; The three channels' records (33 bytes each, IX)
;
; +$00 flags (bit 0 a frame toggle, 1 command $8D, 2 slide on, 3 bend on, 5 the
; envelope runs, 7 bend down); +$01 / +$02 the pattern pointer; +$03 / +$04 the
; order list; +$05 / +$06 the offset of the next order entry; +$07 / +$08 the
; slide's sum; +$09 / +$0A the ornament, +$0B / +$0C its pointer; +$0D the
; slide step, +$0E its delay; +$0F the envelope's speed; +$10 the frames left
; of the note, +$11 the duration; +$12 the note; +$13 the volume; +$14 / +$15
; the envelope, +$16 / +$17 its pointer, +$18 its volume, +$19 the speed
; counter; +$1A the sweep width, +$1B its step, +$1C its position, +$1D the
; sweep mode; +$1E 1: the notes set the noise period; +$1F lock; +$20 the
; channel's mixer bits ($09, $12, $24).
ChannelRecords:
ChannelA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09
ChannelB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12
ChannelC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$24

; The frames left until the next tempo frame
TempoCounter:
  DEFB $00

; Play one frame: the effect, the channels on a tempo frame, the periods and
; volumes, the AY
MusicPlay:
  CALL EffectFrame
  LD A,(MusicOn)
  AND A
  JP Z,EffectOverride
NoiseNote:
  LD A,$00                ; LD A,n: the note of a noise channel (written by
                          ; ReadPattern), the noise period of this frame
  LD (NoisePeriod+$0001),A
  LD HL,TempoCounter
  DEC (HL)
  JR NZ,l_C0F1
  LD B,(HL)
  LD IX,ChannelRecords
  CALL ChannelTick
  LD IX,ChannelB
  CALL ChannelTick
  LD IX,ChannelC
  CALL ChannelTick
TempoReload:
  LD A,$01                ; LD A,n: the tempo (frames a row; SongTable,
                          ; commands $B8-$BF)
  LD (TempoCounter),A
l_C0F1:
  LD IX,ChannelRecords
  CALL ChannelFrame
  LD (AYRegisters),HL
  LD (AYRegisters+$0008),A
  LD IX,ChannelB
  CALL ChannelFrame
  LD (AYRegisters+$0002),HL
  LD (AYRegisters+$0009),A
  LD IX,ChannelC
  CALL ChannelFrame
  LD (AYRegisters+$0004),HL
  LD (AYRegisters+$000A),A
NoisePeriod:
  LD A,$00                ; LD A,n: the noise period for AYRegisters
                          ; (ChannelFrame and the lock write it)
  LD (AYRegisters+$0006),A
EffectOverride:
  LD A,(EffectOn)         ; While an effect runs: its tone periods, noise,
                          ; mixer bits and volumes over channels A and C
  AND A
  JR Z,l_C14D
  LD HL,(EffectRegisters+$0001)
  LD (AYRegisters),HL
  LD HL,(EffectRegisters+$0005)
  LD (AYRegisters+$0004),HL
  LD A,(EffectRegisters+$0007)
  LD (AYRegisters+$0006),A
  LD A,(AYRegisters+$0007)
  OR $2D
  LD HL,EffectRegisters+$0008
  AND (HL)
  LD (AYRegisters+$0007),A
  LD A,(EffectRegisters+$0009)
  LD (AYRegisters+$0008),A
  LD A,(EffectRegisters+$000B)
  LD (AYRegisters+$000A),A
l_C14D:
  LD A,(MusicOn)
  LD HL,EffectOn
  OR (HL)
  RET Z
WriteAY:
  LD HL,AYRegisters+$000B ; Write AYRegisters to AY registers 11 down to 0
                          ; (when the music or an effect is on)
  LD A,$0B
  LD C,$FD
l_C15C:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,l_C15C
  RET

; AY register D = E
;
; Used by the routine at StartEffect.
SetAYRegister:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Every AY register 13 down to 0 = 0, then the mixer (7) = $3F
;
; Used by the routines at StopMusic and EffectFrame.
SilenceAY:
  LD C,$FD
  LD DE,$0D00
  SUB A
l_C179:
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),A
  DEC D
  JP P,l_C179
  LD DE,$073F
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Music and effect off, the AY silent, the three volumes 0
;
; Used by the routine at CommandStop.
StopMusic:
  XOR A
  LD (MusicOn),A
  LD (EffectOn),A
  CALL SilenceAY
  XOR A
  LD (AYRegisters+$0008),A
  LD (AYRegisters+$0009),A
  LD (AYRegisters+$000A),A
  RET

; Commands $80-$91: each byte the offset of its routine from its own address
CommandOffsets:
  DEFB $C9,$B1,$B5,$BA,$78,$A7,$A2,$0F,$91,$89,$4E,$38,$60,$B6,$04,$C3,$C8,$CD

; $8E: stop the music (StopMusic)
CommandStop:
  POP HL
  JP StopMusic

; $87: the end of the pattern: the next order entry (a word 0: the order list
; again)
CommandEnd:
  LD C,(IX+$05)
  LD B,(IX+$06)
  LD L,(IX+$03)
  LD H,(IX+$04)
  ADD HL,BC
  INC BC
  INC BC
  LD A,(HL)
  INC HL
  LD D,(HL)
  LD E,A
  OR D
  JR NZ,l_C1DE
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD BC,$0002
  LD E,(HL)
  INC HL
  LD D,(HL)
l_C1DE:
  LD (IX+$05),C
  LD (IX+$06),B
  LD B,$00
  JP l_C297

; $8B: the channel plays noise (its mixer bits), its notes set the noise period
CommandNoise:
  LD A,(IX+$20)
  LD C,A
  AND $07
  LD HL,MixerBits+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  LD A,$01
  LD (IX+$1E),A
  JP l_C297

; $8A: the channel plays tone
CommandTone:
  LD A,(IX+$20)
  LD C,A
  AND $38
  LD HL,MixerBits+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  XOR A
  LD (IX+$1E),A
  JP l_C297

; $8C: tone and noise
CommandBoth:
  LD HL,MixerBits+$0001
  LD A,(IX+$20)
  CPL
  AND (HL)
  LD (HL),A
  LD A,$01
  LD (IX+$1E),A
  JR l_C297

; $84 s d: a slide: step s every d frames
CommandSlide:
  LD A,(DE)
  INC DE
  LD (IX+$07),B
  LD (IX+$08),B
  LD (IX+$0D),A
  SET 2,(IX+$00)
  LD A,(DE)
  LD (IX+$0E),A
  INC DE
  JR l_C297

; $89 n: the transposition (the operand at $C37C) = n
CommandTranspose:
  LD A,(DE)
  INC DE
  LD (Transposition+$0001),A
  JR l_C297

; $88 s w: a sweep: step s, width w
CommandSweep:
  LD A,(DE)
  LD (IX+$1B),A
  INC DE
  LD A,(DE)
  LD (IX+$1A),A
  INC DE
  LD (IX+$1C),A
  JR l_C297

; $86: the note bends down a step a frame
CommandBendDown:
  SET 7,(IX+$00)

; $85: the note bends up
CommandBendUp:
  SET 3,(IX+$00)
  JR l_C297

; $81: no sweep
CommandSweepOff:
  LD (IX+$1D),B
  JR l_C297

; $82: the sweep goes up
CommandSweepUp:
  LD (IX+$1D),$40
  JR l_C297

; $83: the sweep goes down
CommandSweepDown:
  LD (IX+$1D),$C0
  JR l_C297

; $8D: sets flag bit 1
CommandFlag:
  SET 1,(IX+$00)
  JR l_C297

; $80: a rest: volume 0, the envelope stopped, for the duration
CommandRest:
  LD (IX+$13),B
  RES 5,(IX+$00)
  JR l_C2C6

; $8F: the note goes on for the duration (no new envelope)
CommandHold:
  RES 5,(IX+$00)
  JR l_C2C6

; $90: lock the channel ($FF)
CommandLock:
  LD (IX+$1F),$FF
  JR l_C297

; $91: unlock it
CommandUnlock:
  LD (IX+$1F),B
  JR l_C297

; A tempo frame of the channel at IX: when its duration runs out, ReadPattern;
; else the bend
;
; A note (bit 7 clear): +$12 = the note (and NoiseNote when the channel sets
; the noise), the envelope from its start, the envelope running, the duration
; count reloaded, the pointer saved. Bit 7 set: PatternCommand.
ChannelTick:
  DEC (IX+$10)
  JR NZ,Bend
  LD (IX+$00),B
ReadPattern:
  LD E,(IX+$01)           ; Read the pattern from the pointer: commands and
                          ; settings until a note, rest or hold
  LD D,(IX+$02)
; This entry point is used by the routines at CommandEnd, CommandNoise,
; CommandTone, CommandBoth, CommandSlide, CommandTranspose, CommandSweep,
; CommandBendUp, CommandSweepOff, CommandSweepUp, CommandSweepDown,
; CommandFlag, CommandLock, CommandUnlock and PatternCommand.
l_C297:
  LD A,(DE)
  INC DE
  AND A
  JP M,PatternCommand
  LD (IX+$12),A
  BIT 0,(IX+$1E)
  JR Z,l_C2A9
  LD (NoiseNote+$0001),A
l_C2A9:
  LD L,(IX+$14)
  LD (IX+$16),L
  LD H,(IX+$15)
  LD (IX+$17),H
  LD A,(HL)
  LD (IX+$18),A
  LD (IX+$13),A
  LD A,(IX+$0F)
  LD (IX+$19),A
  SET 5,(IX+$00)
; This entry point is used by the routines at CommandRest and CommandHold.
l_C2C6:
  LD A,(IX+$11)
  LD (IX+$10),A
  LD (IX+$02),D
  LD (IX+$01),E
  LD A,(IX+$1F)
  AND A
  JR Z,l_C2E2
  LD A,(EffectOn)
  AND A
  JR NZ,l_C2E2
  LD (IX+$1F),$FF
l_C2E2:
  RET

; Bend on (flag bit 3): the note one up (bit 7 clear) or down (bit 7 set) a
; tempo frame
;
; Used by the routine at ChannelTick.
Bend:
  LD A,(IX+$00)
  BIT 3,A
  RET Z
  RLA
  JR NC,l_C2F0
  INC (IX+$12)
  RET
l_C2F0:
  DEC (IX+$12)
  RET

; A byte $80-$FF: a command below $B8 (CommandOffsets), else the tempo, an
; ornament, an envelope or a duration
;
; Used by the routine at ChannelTick.
PatternCommand:
  CP $B8
  JR C,Dispatch
  ADD A,$20
  JR C,SetDuration
  ADD A,$10
  JR C,SetEnvelope
  ADD A,$10
  JR NC,SetTempo
SetOrnament:
  LD C,A                  ; $C0-$CF: the ornament OrnamentOffsets[n]
  LD HL,OrnamentOffsets
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  LD (IX+$0B),L
  LD (IX+$09),L
  LD (IX+$0C),H
  LD (IX+$0A),H
  JP l_C297
SetTempo:
  ADD A,$09               ; $B8-$BF: TempoReload = n + 1
  LD (TempoReload+$0001),A
  JP l_C297
SetDuration:
  INC A                   ; $E0-$FF: the duration = n + 1
  LD (IX+$11),A
  JP l_C297
SetEnvelope:
  LD HL,EnvelopeTable     ; $D0-$DF: the envelope EnvelopeTable[n] (and the
                          ; speed byte before it)
  ADD A,A
  LD C,A
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (IX+$14),L
  LD (IX+$15),H
  DEC HL
  LD A,(HL)
  LD (IX+$0F),A
  JP l_C297
Dispatch:
  LD HL,EffectOverride+$0009 ; JP to the command's routine: CommandOffsets[A -
                             ; $80] + its address
  LD C,A
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  JP (HL)

; One frame of the channel at IX: HL = its tone period, A = its volume
;
; The envelope's next volume every +$0F frames (a byte with bit 7 set ends it),
; the ornament's next note offset (bit 7 set: the ornament again), the note +
; the transposition (the operand at $C37C) into PeriodTable, the sweep (a
; triangle of width +$1A, step +$1B, the period shifted by the note's octave),
; the slide (+$0D every +$0E frames), the mixer bits into AYRegisters, the
; lock.
ChannelFrame:
  LD C,(IX+$00)
  BIT 5,C
  JR Z,Transposition
  LD A,(IX+$19)
  SUB $01
  LD (IX+$19),A
  JR NC,l_C375
  LD A,(IX+$0F)
  LD (IX+$19),A
  LD L,(IX+$16)
  LD H,(IX+$17)
  INC HL
  LD A,(HL)
  AND A
  JP M,l_C375
  LD (IX+$16),L
  LD (IX+$17),H
  LD (IX+$18),A
l_C375:
  LD A,(IX+$18)
  LD (IX+$13),A
Transposition:
  LD A,$00                ; LD A,n: the transposition (command $89)
  ADD A,(IX+$12)
  LD B,A
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  LD A,(HL)
  INC HL
  AND A
  JP P,l_C395
  LD L,(IX+$09)
  LD H,(IX+$0A)
  AND $7F
l_C395:
  LD (IX+$0B),L
  LD (IX+$0C),H
  ADD A,B
  LD HL,PeriodTable
  LD D,$00
  ADD A,A
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD L,(IX+$1D)
  BIT 6,L
  JR Z,l_C3F6
  LD H,A
  LD B,(IX+$1A)
  SLA B
  BIT 7,L
  LD A,(IX+$1C)
  JR Z,l_C3BF
  BIT 0,C
  JR NZ,l_C3DD
l_C3BF:
  BIT 5,L
  JR NZ,l_C3CF
  SUB (IX+$1B)
  JR NC,l_C3DA
  SET 5,(IX+$1D)
  SUB A
  JR l_C3DA
l_C3CF:
  ADD A,(IX+$1B)
  CP B
  JR C,l_C3DA
  RES 5,(IX+$1D)
  LD A,B
l_C3DA:
  LD (IX+$1C),A
l_C3DD:
  EX DE,HL
  SRL B
  SUB B
  LD E,A
  LD A,D
  LD D,$00
  JR NC,l_C3E8
  DEC D
l_C3E8:
  ADD A,$A0
  JR C,l_C3F4
l_C3EC:
  SLA E
  RL D
  ADD A,$18
  JR NC,l_C3EC
l_C3F4:
  ADD HL,DE
  EX DE,HL
l_C3F6:
  LD A,C
  XOR $01
  LD (IX+$00),A
  BIT 2,C
  JR Z,l_C421
  LD B,(IX+$0E)
  DJNZ l_C41E
  LD C,(IX+$0D)
  BIT 7,C
  JR Z,l_C40D
  DEC B
l_C40D:
  LD L,(IX+$07)
  LD H,(IX+$08)
  ADD HL,BC
  LD (IX+$07),L
  LD (IX+$08),H
  ADD HL,DE
  EX DE,HL
  JR l_C421
l_C41E:
  LD (IX+$0E),B
l_C421:
  CPL
  AND $03
MixerBits:
  LD A,$38                ; LD A,n: the mixer bits of the tone and noise
                          ; commands
  JR NZ,l_C432
  LD A,(NoiseNote+$0001)
  XOR $08
  LD (NoisePeriod+$0001),A
  LD A,$07
l_C432:
  LD HL,AYRegisters+$0007
  XOR (HL)
  AND (IX+$20)
  XOR (HL)
  LD (HL),A
  LD A,(IX+$1F)
  AND A
  JP P,l_C455
  AND $7F
  LD (IX+$1F),A
  LD A,(IX+$20)
  AND $38
  XOR $FF
  AND (HL)
  LD (HL),A
  LD A,$41
  LD (NoisePeriod+$0001),A
l_C455:
  EX DE,HL
  LD A,(IX+$13)
  RET

; The image of AY registers 0-11 that WriteAY sends: the periods, the noise,
; the mixer, the volumes
AYRegisters:
  DEFB $00,$00,$00,$00,$00,$00,$00,$3F,$0F,$0F,$0F,$00

; The effect's own image: tone periods A ($C467) and C ($C46B), the noise
; ($C46D), the mixer mask, the volumes
EffectRegisters:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$3F,$10,$00,$10,$00

; The AY tone period of notes 0-95
PeriodTable:
  DEFW $0EF8,$0E10,$0D60,$0C80,$0BD8,$0B28,$0A88,$09F0
  DEFW $0960,$08E0,$0858,$07E0,$077C,$0708,$06B0,$0640
  DEFW $05EC,$0594,$0544,$04F8,$04B0,$0470,$042C,$03F0
  DEFW $03BE,$0384,$0358,$0320,$02F6,$02CA,$02A2,$027C
  DEFW $0258,$0238,$0216,$01F8,$01DF,$01C2,$01AC,$0190
  DEFW $017B,$0165,$0151,$013E,$012C,$011C,$010B,$00FC
  DEFW $00EF,$00E1,$00D6,$00C8,$00BD,$00B2,$00A8,$009F
  DEFW $0096,$008E,$0085,$007E,$0077,$0070,$006B,$0064
  DEFW $005E,$0059,$0054,$004F,$004B,$0047,$0042,$003F
  DEFW $003B,$0038,$0035,$0032,$002F,$002C,$002A,$0027
  DEFW $0025,$0023,$0021,$001F,$001D,$001C,$001A,$0019
  DEFW $0017,$0016,$0015,$0013,$0012,$0011,$0010,$000F

; Ornaments $C0-$CD: each byte the offset of its data from its own address
OrnamentOffsets:
  DEFB $0E,$0E,$10,$12,$14,$16,$17,$1E,$24,$29,$2A,$2B,$2C,$32

; The ornaments: note offsets a frame, a byte with bit 7 set: the ornament
; again
Ornaments:
  DEFB $80,$07,$0C,$8F,$03,$07,$8C,$00,$03,$87,$00,$04,$87,$00,$8C,$0C
  DEFB $00,$00,$00,$00,$00,$00,$80,$0C,$00,$00,$00,$00,$00,$80,$0C,$00
  DEFB $00,$00,$00,$80,$00,$83,$00,$84,$00,$85,$18,$00,$00,$00,$00,$00
  DEFB $80,$04,$07,$8C

; Envelopes $D0-$DA: each the address of its volumes (the byte before it is the
; speed)
EnvelopeTable:
  DEFW $C58C,$C58F,$C597,$C5A9,$C5D3,$C5D7,$C601,$C607,$C62B,$C637,$C643

; The envelopes: a speed byte, then volumes a step, a byte with bit 7 set ends
Envelopes:
  DEFB $00,$09,$87,$03,$0F,$0E,$0D,$0C,$0B,$0A,$87,$01,$0F,$0E,$0C,$0B
  DEFB $0D,$0C,$0A,$09,$0B,$0A,$08,$07,$09,$08,$06,$05,$87,$01,$0F,$0E
  DEFB $0D,$0C,$0B,$0D,$0C,$0B,$0A,$09,$0B,$0A,$09,$08,$07,$09,$08,$07
  DEFB $06,$05,$07,$06,$05,$04,$03,$05,$04,$03,$02,$01,$04,$03,$02,$01
  DEFB $03,$02,$01,$02,$01,$00,$87,$0A,$0F,$0E,$87,$02,$0F,$0E,$0D,$0C
  DEFB $0B,$0D,$0C,$0B,$0A,$09,$0B,$0A,$09,$08,$07,$09,$08,$07,$06,$05
  DEFB $07,$06,$05,$04,$03,$05,$04,$03,$02,$01,$04,$03,$02,$01,$03,$02
  DEFB $01,$02,$01,$00,$87,$01,$0B,$0F,$0B,$08,$87,$02,$0A,$0B,$0C,$0D
  DEFB $0E,$0F,$0F,$0E,$0E,$0E,$0E,$0D,$0D,$0C,$0C,$0C,$0C,$0B,$0B,$0B
  DEFB $0B,$0A,$0A,$0A,$0A,$09,$09,$09,$09,$08,$08,$08,$07,$06,$87,$01
  DEFB $0C,$0B,$0A,$09,$08,$07,$09,$08,$07,$06,$87,$01,$0D,$0C,$0B,$0A
  DEFB $09,$08,$0A,$09,$08,$07,$87,$01,$0E,$0D,$0C,$0B,$0A,$09,$0B,$0A
  DEFB $09,$08,$87

; 1 while the music plays
MusicOn:
  DEFB $00

; 1 while a sound effect plays
EffectOn:
  DEFB $00

; Start sound effect A: its 17-byte record (EffectTable) into EffectState, its
; envelope into AY 12 and 13
StartEffect:
  LD HL,EffectOn
  LD (HL),$00
  LD HL,EffectTable
  ADD A,A
  ADD A,L
  LD L,A
  JR NC,l_C65E
  INC H
l_C65E:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD B,$11
  LD HL,EffectState
l_C666:
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  DJNZ l_C666
  LD A,(EffectState+$0001)
  LD (EffectDelay),A
  LD HL,(EffectState+$0002)
  LD (EffectRegisters+$0001),HL
  LD DE,(EffectState+$0004)
  LD (EffectRegisters+$0005),DE
  LD A,L
  LD (EffectRegisters+$0007),A
  LD A,(EffectState+$0007)
  LD (EffectRegisters+$0008),A
  LD A,(EffectState+$0006)
  LD E,A
  LD D,$0C
  CALL SetAYRegister
  LD A,(EffectState+$0010)
  LD E,A
  LD D,$0D
  CALL SetAYRegister
  LD HL,EffectOn
  INC (HL)
  RET

; One frame of the running effect: the random number, the time left, the
; repeats, the period sweeps of A and C
;
; Used by the routine at MusicPlay.
EffectFrame:
  CALL Random
  LD A,(EffectOn)
  AND A
  RET Z
  LD A,(EffectState)
  AND A
  JR NZ,l_C6B5
  LD (EffectOn),A
  JP SilenceAY
l_C6B5:
  DEC A
  LD (EffectState),A
  LD A,(EffectDelay)
  AND A
  JR NZ,l_C6EE
  LD A,(EffectState+$000E)
  AND A
  RET Z
  DEC A
  LD (EffectState+$000E),A
  LD A,(EffectState+$0001)
  LD (EffectDelay),A
  LD A,(EffectState+$000F)
  AND A
  JR Z,l_C6D7
  LD A,(RandomSeed)
l_C6D7:
  LD B,A
  LD A,(EffectState+$0002)
  ADD A,B
  LD (EffectRegisters+$0001),A
  LD A,(EffectState+$0003)
  ADD A,B
  AND $0F
  LD (EffectRegisters+$0002),A
  LD HL,(EffectState+$0004)
  LD (EffectRegisters+$0005),HL
l_C6EE:
  LD HL,EffectDelay
  DEC (HL)
  LD A,(EffectState+$000C)
  AND A
  JR Z,l_C715
  JP P,l_C708
  LD HL,(EffectRegisters+$0001)
  LD DE,(EffectState+$0008)
  ADD HL,DE
  LD (EffectRegisters+$0001),HL
  JR l_C715
l_C708:
  LD HL,(EffectRegisters+$0001)
  LD DE,(EffectState+$0008)
  AND A
  SBC HL,DE
  LD (EffectRegisters+$0001),HL
l_C715:
  LD A,(EffectState+$000D)
  AND A
  JR Z,l_C738
  JP P,l_C72B
  LD HL,(EffectRegisters+$0005)
  LD DE,(EffectState+$000A)
  ADD HL,DE
  LD (EffectRegisters+$0005),HL
  JR l_C738
l_C72B:
  LD HL,(EffectRegisters+$0005)
  LD DE,(EffectState+$000A)
  AND A
  SBC HL,DE
  LD (EffectRegisters+$0005),HL
l_C738:
  LD A,(EffectRegisters+$0001)
  LD (EffectRegisters+$0007),A
  RET

; The 20 sound effects' records (17 bytes each)
EffectTable:
  DEFW Effects,$C778,$C789,$C79A,$C7AB,$C7BC,$C7CD,$C7DE
  DEFW $C7EF,$C800,$C811,$C822,$C833,$C844,$C855,$C866
  DEFW $C877,$C888,$C899,$C8AA

; The effects: time, repeat delay, tone A, noise, tone C, sweep directions and
; steps, repeats, envelope
Effects:
  DEFB $14,$14,$80,$00,$41,$00,$28,$F2,$02,$00,$02,$00,$FF,$FF,$0A,$00,$00
  DEFB $0A,$14,$A0,$00,$11,$00,$50,$F2,$12,$00,$12,$00,$FF,$FF,$0A,$00,$00
  DEFB $19,$07,$00,$08,$20,$08,$1E,$FA,$30,$01,$30,$01,$FF,$FF,$05,$00,$00
  DEFB $19,$07,$00,$09,$20,$09,$1E,$FA,$30,$01,$30,$01,$FF,$FF,$05,$00,$00
  DEFB $64,$06,$84,$00,$70,$00,$14,$FA,$08,$00,$08,$00,$01,$01,$FF,$00,$0D
  DEFB $14,$06,$14,$03,$00,$02,$0C,$FA,$40,$00,$50,$00,$01,$01,$0F,$01,$0E
  DEFB $14,$07,$40,$03,$00,$06,$1E,$FA,$40,$00,$30,$00,$01,$01,$3C,$00,$00
  DEFB $1E,$07,$08,$00,$17,$00,$19,$FA,$10,$00,$10,$00,$FF,$FF,$0A,$00,$00
  DEFB $19,$FF,$35,$00,$80,$00,$3C,$FA,$03,$08,$02,$08,$01,$01,$FF,$00,$00
  DEFB $28,$1F,$1F,$04,$1F,$04,$06,$D7,$01,$00,$01,$00,$01,$01,$00,$00,$0D
  DEFB $23,$0A,$14,$00,$1F,$00,$32,$D2,$07,$00,$08,$00,$FF,$01,$0A,$01,$00
  DEFB $5A,$0A,$14,$00,$1F,$00,$5A,$D2,$07,$00,$08,$00,$FF,$01,$0A,$01,$00
  DEFB $14,$06,$02,$04,$22,$04,$28,$F2,$91,$01,$99,$01,$FF,$FF,$FF,$00,$00
  DEFB $3C,$0D,$00,$01,$20,$04,$3C,$FA,$0C,$00,$28,$00,$01,$01,$FF,$00,$00
  DEFB $0A,$05,$14,$02,$2E,$02,$12,$FA,$3F,$00,$38,$00,$FF,$FF,$05,$00,$00
  DEFB $23,$FF,$2F,$D0,$F2,$0B,$0A,$FA,$07,$08,$03,$08,$01,$01,$FF,$00,$0D
  DEFB $03,$63,$43,$00,$21,$04,$02,$D7,$01,$00,$01,$00,$01,$01,$00,$00,$0E
  DEFB $14,$07,$55,$01,$5C,$01,$23,$FA,$41,$00,$41,$00,$FF,$FF,$06,$00,$00
  DEFB $5A,$FF,$02,$0F,$F2,$0E,$0A,$FA,$04,$08,$05,$08,$01,$01,$FF,$00,$0D
  DEFB $14,$06,$02,$01,$0C,$01,$50,$D2,$49,$00,$53,$00,$FF,$FF,$15,$00,$00

; The running effect: a copy of its record, then the delay counter
EffectState:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The frames left until the effect's next repeat
EffectDelay:
  DEFB $00
  DEFB $00

; A = the next pseudo-random number (a 32-bit shift register at RandomSeed)
;
; Used by the routine at EffectFrame.
Random:
  LD A,(RandomSeed)
  AND $48
  ADC A,$38
  SLA A
  SLA A
  LD HL,RandomSeed+$0003
  RL (HL)
  DEC HL
  RL (HL)
  DEC HL
  RL (HL)
  DEC HL
  RL (HL)
  LD A,(HL)
  RET

; The shift register
RandomSeed:
  DEFB $FF,$80,$1B,$34
