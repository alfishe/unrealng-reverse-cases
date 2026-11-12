; --------------------------------------------------------------------------------------------------------------------
; daglish-module.asm: Ben Daglish's driver: init, play, sequences and patterns, instruments (ADSR, vibrato), pitch tables
;
; MusicPlay $BFFE (C = the volume limit, then the JP to PlayWrapper) plays one frame, saving every register:
; VoiceFrames (each voice's envelope and vibrato into the AY) and, while the music plays, PlayFrame (each channel's
; sequence and pattern); MusicInit $C003 starts song 0 (LD A,n). Vectors at $C39E (Init), $C3A1 (PlayFrame), $C3A5
; (StartEffect) and StopMusic $C3A8.
;
; A song is three sequences (SongTable). A sequence: a pattern number (PatternLow, PatternHigh), $80+N (the next
; pattern N times), $FE n (the transposition), $C0+K V (the channel's instrument slot K = offset V into Instruments),
; $FF (the channel stops). A pattern: a note and its frames, $7E lo hi d (a raw period), $7F d (a rest), $80+K
; (instrument slot K), $88+N (pitch table N), $C0-$FE (ignored, 1 or 4 bytes), $FF (the end). The format is in
; tools/res_daglish.py.
; --------------------------------------------------------------------------------------------------------------------

; LD C,n: the volume limit, then JP PlayWrapper
MusicPlay:
  LD C,$FE

; JP PlayWrapper
PlayVector:
  JP PlayWrapper

; Start song 0 (LD A,n) through Init
;
; Used by the routine at PlayWrapper.
MusicInit:
  LD A,$00
  LD C,$01
  CALL Init
  RET

; The tail of a game routine: LD I,A, Init with E, restore; no code reaches it
Orphan:
  LD I,A
  LD A,E
  CALL Init
  POP AF
  LD I,A
  POP DE
  RET

; Save the registers, VolumeLimit = C, restart a finished song, PlayFrame,
; restore
;
; Used by the routine at PlayVector.
PlayWrapper:
  EXX
  PUSH BC
  PUSH DE
  PUSH HL
  EXX
  PUSH IX
  PUSH IY
  EX AF,AF'
  PUSH AF
  EX AF,AF'
  PUSH HL
  PUSH DE
  LD E,A
  LD A,C
  LD (VolumeLimit),A
  LD A,(MusicState)
  CP $01
  JR NZ,l_C036
  LD A,E
  CP $01
  CALL NZ,MusicInit
l_C036:
  CALL PlayFrame
  POP DE
  POP HL
  EX AF,AF'
  POP AF
  EX AF,AF'
  POP IY
  POP IX
  EXX
  POP HL
  POP DE
  POP BC
  EXX
  RET

; The byte before PeriodTable
PeriodPad:
  DEFB $00

; The AY tone period of notes 0-84 (a pattern's note + the transposition + 12)
PeriodTable:
  DEFW $0EEE,$0E18,$0D4D,$0C8E,$0BDA,$0B2F,$0A8F,$09F7
  DEFW $0968,$08E1,$0861,$07E9,$0777,$070C,$06A7,$0647
  DEFW $05ED,$0598,$0547,$04FC,$04D4,$0470,$0431,$03F4
  DEFW $03DC,$0386,$0353,$0324,$02F6,$02CC,$02A4,$027E
  DEFW $025A,$0238,$0218,$01FA,$01DE,$01C3,$01AA,$0192
  DEFW $017B,$0166,$0152,$013F,$012D,$011C,$010C,$00FD
  DEFW $00EF,$00E1,$00D5,$00C9,$00BE,$00B3,$00A9,$009F
  DEFW $0096,$008E,$0086,$007F,$0077,$0071,$006A,$0064
  DEFW $005F,$0059,$0054,$0050,$004B,$0047,$0043,$003F
  DEFW $003C,$0038,$0035,$0032,$002F,$002D,$002A,$0028
  DEFW $0026,$0024,$0022,$0020,$0018

; The mixer (AY register 7) as the voices set it
MixerImage:
  DEFB $BF

; The three voices' records (18 bytes each, IX), what the AY plays
;
; +$00 / +$01 / +$02 the voice's tone, noise and both mixer bits; +$03 / +$04
; the period; +$05 the volume; +$06 the frames to hold; +$07 the vibrato delay,
; +$08 its length, +$09 / +$0A its offset, +$0B / +$0C its step; +$0D / +$0E
; the envelope phase's routine; +$0F / +$10 the instrument; +$11 flags (bit 7:
; an effect owns the voice).
Voices:
VoiceA:
  DEFB $FE,$F7,$09,$9F,$00,$32,$01,$00,$F9
  DEFB $E0,$01,$3C,$00,$FE,$C2,$86,$CD,$00
VoiceB:
  DEFB $FD,$EF,$12,$47,$06,$3F,$01,$00,$05
  DEFB $F4,$FF,$04,$00,$FE,$C2,$7C,$CD,$00
VoiceC:
  DEFB $FB,$DF,$24,$38,$02,$5A,$01,$00,$02
  DEFB $00,$00,$FF,$FF,$20,$C3,$9A,$CD,$00

; The voice at IX plays instrument IY with period HL for C frames: envelope,
; vibrato, mixer, noise
;
; Used by the routines at StartEffect and ChannelFrame.
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
  JR NZ,l_C14F
  LD A,$01
l_C14F:
  LD (IX+$08),A
  LD A,(IY+$07)
  LD (IX+$0B),A
  LD A,(IY+$08)
  LD (IX+$0C),A
  XOR A
  LD (IX+$09),A
  LD (IX+$0A),A
  LD A,(MixerImage)
  OR (IX+$02)
  LD C,(IY+$09)
  LD (IX+$11),C
  BIT 0,C
  JR Z,l_C178
  AND (IX+$00)
l_C178:
  BIT 1,C
  JR Z,l_C17F
  AND (IX+$01)
l_C17F:
  LD (MixerImage),A
  BIT 2,C
  JR NZ,l_C191
  LD HL,Attack
  LD (IX+$0D),L
  LD (IX+$0E),H
  DI
  RET
l_C191:
  LD HL,$FFBF
  LD C,$FD
  LD A,(IY+$00)
  LD E,$0D
  CALL SetAYRegister
  LD A,(IY+$04)
  LD E,$0B
  CALL SetAYRegister
  INC E
  XOR A
  CALL SetAYRegister
  LD (IX+$05),$FF
  DI
  RET

; The mixer off, the volumes and envelope period 0, the noise 0
;
; Used by the routines at StopMusic and Init.
Silence:
  LD C,$FD
  LD HL,$FFBF
  LD E,$07
  LD A,(MixerImage)
  OR $3F
  LD (MixerImage),A
  CALL SetAYRegister
  XOR A
  INC E
  CALL SetAYRegister
  INC E
  CALL SetAYRegister
  INC E
  CALL SetAYRegister
  LD A,$01
  INC E
  CALL SetAYRegister
  INC E
  XOR A
  CALL SetAYRegister
  INC E
  CALL SetAYRegister
  LD (Voices+$0011),A
  LD (VoiceB+$0011),A
  LD (VoiceC+$0011),A
  RET

; One frame of the three voices (VoiceFrame), then the mixer, periods (with
; vibrato), noise and volumes into the AY
;
; Used by the routine at PlayFrame.
VoiceFrames:
  LD A,(MixerImage)
  AND $3F
  CP $3F
  RET Z
  LD IX,Voices
  CALL VoiceFrame
  LD IX,VoiceB
  CALL VoiceFrame
  LD IX,VoiceC
  CALL VoiceFrame
  LD IX,Voices
  LD HL,$FFBF
  LD C,$FD
  LD E,$07
  LD A,(MixerImage)
  CALL SetAYRegister
  LD E,$00
  LD A,(Voices+$0003)
  ADD A,(IX+$09)
  BIT 1,(IX+$11)
  JP Z,l_C227
  LD D,A
l_C227:
  CALL SetAYRegister
  INC E
  LD A,(Voices+$0004)
  ADC A,(IX+$0A)
  CALL SetAYRegister
  INC E
  LD A,(VoiceB+$0003)
  ADD A,(IX+$1B)
  BIT 1,(IX+$23)
  JP Z,l_C243
  LD D,A
l_C243:
  CALL SetAYRegister
  INC E
  LD A,(VoiceB+$0004)
  ADC A,(IX+$1C)
  CALL SetAYRegister
  INC E
  LD A,(VoiceC+$0003)
  ADD A,(IX+$2D)
  BIT 1,(IX+$35)
  JP Z,l_C25F
  LD D,A
l_C25F:
  CALL SetAYRegister
  INC E
  LD A,(VoiceC+$0004)
  ADC A,(IX+$2E)
  CALL SetAYRegister
  INC E
  LD A,D
  RRCA
  RRCA
  RRCA
  CALL SetAYRegister
  LD E,$08
  LD A,(VolumeLimit)
  LD D,A
  LD A,(Voices+$0005)
  CP D
  JR C,l_C281
  LD A,D
l_C281:
  SRL A
  SRL A
  SRL A
  CALL SetAYRegister
  INC E
  LD A,(VoiceB+$0005)
  CP D
  JR C,l_C292
  LD A,D
l_C292:
  SRL A
  SRL A
  SRL A
  CALL SetAYRegister
  INC E
  LD A,(VoiceC+$0005)
  CP D
  JR C,l_C2A3
  LD A,D
l_C2A3:
  SRL A
  SRL A
  SRL A
  JP SetAYRegister

; The highest volume (MusicPlay's C); each volume is the lower of the two, / 8
VolumeLimit:
  DEFB $FE

; One frame of the voice at IX: the hold counter, Vibrato, then its envelope
; phase (JP (HL))
;
; Used by the routine at VoiceFrames.
VoiceFrame:
  LD A,(MixerImage)
  AND (IX+$02)
  CP (IX+$02)
  RET Z
  LD A,(IX+$0F)
  LD IYL,A
  LD A,(IX+$10)
  LD IYH,A
  LD A,(IX+$06)
  AND A
  JR Z,l_C2CE
  CP $FF
  JR Z,l_C2CE
  DEC (IX+$06)
l_C2CE:
  CALL Vibrato
  BIT 2,(IY+$09)
  JP NZ,HardwareEnd
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  JP (HL)

; The volume rises by the attack step to the peak, then Decay
Attack:
  LD A,(IX+$05)
  ADD A,(IY+$00)
  CP (IY+$04)
  JR NC,l_C2EE
  LD (IX+$05),A
  RET
l_C2EE:
  LD A,(IY+$04)
  LD (IX+$05),A
  LD HL,Decay
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; The volume falls by the decay step to the sustain level, then Sustain
Decay:
  LD A,(IX+$05)
  ADD A,(IY+$01)
  JP M,l_C310
  CP (IY+$02)
  JR C,l_C310
  LD (IX+$05),A
  RET
l_C310:
  LD A,(IY+$02)
  LD (IX+$05),A
  LD HL,Sustain
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; Hold while the frames last, then Release
Sustain:
  LD A,(IX+$06)
  AND A
  RET NZ
  LD HL,Release
  LD (IX+$0D),L
  LD (IX+$0E),H
  RET

; The volume falls by the release step to 0
Release:
  LD A,(IX+$05)
  ADD A,(IY+$03)
  JP M,VoiceOff
  LD (IX+$05),A
  RET

; Volume 0, the voice's mixer bits off
;
; Used by the routines at Release and HardwareEnd.
VoiceOff:
  LD (IX+$05),$00
  LD A,(MixerImage)
  OR (IX+$02)
  LD (MixerImage),A
  RES 7,(IX+$11)
  RET

; An instrument on the AY envelope: off when its frames run out
;
; Used by the routine at VoiceFrame.
HardwareEnd:
  LD A,(IX+$06)
  AND A
  RET NZ
  JR VoiceOff

; After its delay, the vibrato offset moves by its step; the step turns every
; length frames
;
; Used by the routine at VoiceFrame.
Vibrato:
  LD A,(IX+$07)
  AND A
  JR Z,l_C362
  CP $FF
  RET Z
  DEC (IX+$07)
  RET NZ
l_C362:
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
  JP P,l_C386
  LD (IX+$07),$FF
  RET
l_C386:
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

; AY register E = A (HL = $FFBF, C = $FD)
;
; Used by the routines at StartVoice, Silence and VoiceFrames.
SetAYRegister:
  LD B,H
  OUT (C),E
  LD B,L
  OUT (C),A
  RET

; JP Init
InitVector:
  JP Init

; JP PlayFrame
PlayFrameVector:
  JP PlayFrame

; Not 0 while a channel plays; 1: the song ended and the voices fell silent
MusicState:
  DEFB $FF

; JP StartEffect
EffectVector:
  JP StartEffect

; MusicState 0, Silence
StopMusic:
  XOR A
  LD (MusicState),A
  JP Silence

; Sound effect A: its 13-byte record (EffectRecords) plays on voice A, which
; the music leaves alone
;
; Used by the routine at EffectVector.
StartEffect:
  DI
  LD L,A
  LD E,A
  LD H,$00
  LD D,H
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD IY,EffectRecords
  EX DE,HL
  ADD IY,DE
  LD L,(IY+$0A)
  LD H,(IY+$0B)
  LD C,(IY+$0C)
  LD IX,Voices
  CALL StartVoice
  SET 7,(IX+$11)
  DI
  RET

; The three channels' records (21 bytes each, IY), the sequencer
;
; +$00 the first of its instrument slots (0, 8, 16); +$01 / +$02 the sequence
; pointer; +$03 / +$04 the pattern's start; +$05 / +$06 the pattern pointer;
; +$07 / +$08 the instrument; +$09 the repeats left; +$0A the transposition;
; +$0B the pattern ended; +$0C the frames left; +$0D 0: stopped; +$0E the note;
; +$0F the pitch table; +$10 / +$11 its pointer; +$12 / +$13 its frames and
; steps; +$14 its flags.
Channels:
ChannelA:
  DEFB $00,$03,$CD,$CF,$C6,$FF,$C6,$72,$CD,$01,$00,$FF,$01,$FF,$37,$00,$00,$00,$00,$00,$40
ChannelB:
  DEFB $08,$1D,$CD,$38,$C7,$74,$C7,$72,$CD,$01,$00,$FF,$01,$FF,$0F,$00,$00,$00,$00,$00,$40
ChannelC:
  DEFB $10,$44,$CD,$BA,$C7,$F7,$C7,$72,$CD,$01,$00,$FF,$01,$FF,$21,$00,$00,$00,$00,$00,$40

; 8 slots a channel: offsets into Instruments (Init: 0, 10, ... 70)
InstrumentSlots:
  DEFB $00,$0A,$14,$1E,$28,$32,$3C,$46
  DEFB $00,$0A,$14,$1E,$28,$32,$3C,$46
  DEFB $00,$0A,$14,$1E,$28,$32,$3C,$46

; Start song A: Silence, the three sequences from SongTable, the channels and
; slots reset, MusicState $FF
;
; Used by the routines at MusicInit, Orphan and InitVector.
Init:
  PUSH AF
  CALL Silence
  POP AF
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A
  LD HL,SongTable
  ADD A,L
  LD L,A
  JR NC,l_C43F
  INC H
l_C43F:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (Channels+$0001),DE
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
  LD (Channels+$000A),A
  LD (ChannelB+$000A),A
  LD (ChannelC+$000A),A
  LD (Channels+$000F),A
  LD (ChannelB+$000F),A
  LD (ChannelC+$000F),A
  CPL
  LD (Channels+$000B),A
  LD (ChannelB+$000B),A
  LD (ChannelC+$000B),A
  LD A,$01
  LD (Channels+$0009),A
  LD (ChannelB+$0009),A
  LD (ChannelC+$0009),A
  LD (Channels+$000C),A
  LD (ChannelB+$000C),A
  LD (ChannelC+$000C),A
  LD HL,InstrumentSlots
  LD BC,$030A
l_C48E:
  XOR A
l_C48F:
  LD (HL),A
  INC HL
  ADD A,C
  LD (HL),A
  INC HL
  ADD A,C
  CP $50
  JR NZ,l_C48F
  DJNZ l_C48E
  LD HL,Instruments
  LD (Channels+$0007),HL
  LD (ChannelB+$0007),HL
  LD (ChannelC+$0007),HL
  LD A,$FF
  LD (Channels+$000D),A
  LD (ChannelB+$000D),A
  LD (ChannelC+$000D),A
  LD (MusicState),A
  RET

; One frame of the music: VoiceFrames, then each playing channel
; (ChannelFrame); MusicState 0 when all stopped
;
; Used by the routines at PlayWrapper and PlayFrameVector.
PlayFrame:
  CALL VoiceFrames
  LD A,(MusicState)
  AND A
  RET Z
  LD A,(Channels+$000D)
  LD HL,ChannelB+$000D
  OR (HL)
  LD HL,ChannelC+$000D
  OR (HL)
  LD (MusicState),A
  JR NZ,l_C4E0
  XOR A
  LD (MusicState),A
  LD A,(MixerImage)
  AND $3F
  CP $3F
  RET Z
  LD A,$01
  LD (MusicState),A
  RET
l_C4E0:
  LD IY,Channels
  LD IX,Voices
  CALL ChannelFrame
  LD IY,ChannelB
  LD IX,VoiceB
  CALL ChannelFrame
  LD IY,ChannelC
  LD IX,VoiceC

; The channel at IY (voice IX): the pitch table, then the pattern when the
; frames run out
;
; Used by the routine at PlayFrame.
ChannelFrame:
  CALL PitchFrame
  LD A,(IY+$0B)
  AND A
  JR Z,ReadPattern
l_C507:
  DEC (IY+$09)
  JR Z,ReadSequence
  LD A,(IY+$03)
  LD (IY+$05),A
  LD A,(IY+$04)
  LD (IY+$06),A
  LD (IY+$0B),$00
  JR ReadPattern
ReadSequence:
  LD (IY+$09),$01         ; The pattern ended: repeat it, or read the sequence:
                          ; repeats, transposition, slots, a pattern
  LD L,(IY+$01)
  LD H,(IY+$02)
l_C528:
  LD A,(HL)
  CP $80
  JR C,l_C563
  CP $FE
  JR NZ,l_C53A
  INC HL
  LD A,(HL)
  LD (IY+$0A),A
  INC HL
  JP l_C528
l_C53A:
  CP $FF
  JR NZ,l_C543
  XOR A
  LD (IY+$0D),A
  RET
l_C543:
  CP $C0
  JR NC,l_C550
  AND $1F
  LD (IY+$09),A
  INC HL
  JP l_C528
l_C550:
  AND $07
  ADD A,(IY+$00)
  LD DE,InstrumentSlots
  ADD A,E
  LD E,A
  JR NC,l_C55D
  INC D
l_C55D:
  INC HL
  LDI
  JP l_C528
l_C563:
  LD (IY+$0B),$00
  INC HL
  LD (IY+$01),L
  LD (IY+$02),H
  LD C,A
  LD B,$00
  LD HL,PatternLow
  ADD HL,BC
  LD E,(HL)
  LD HL,PatternHigh
  ADD HL,BC
  LD D,(HL)
  LD (IY+$03),E
  LD (IY+$04),D
  JR l_C589
ReadPattern:
  LD E,(IY+$05)           ; The next pattern items: commands, then a note
                          ; (PeriodTable), a raw period or a rest, and
                          ; StartVoice
  LD D,(IY+$06)
l_C589:
  DEC (IY+$0C)
  JR Z,l_C59B
  LD A,(DE)
  CP $80
  CALL NC,PatternCommand
  LD (IY+$05),E
  LD (IY+$06),D
  RET
l_C59B:
  LD A,(DE)
  CP $80
  JR C,l_C5AC
  CALL PatternCommand
  LD A,(IY+$0B)
  AND A
  JR Z,l_C59B
  JP l_C507
l_C5AC:
  CP $7F
  JR Z,l_C5F8
  CP $7E
  JR NZ,l_C5BD
  INC DE
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  JP l_C5D1
l_C5BD:
  ADD A,(IY+$0A)
  ADD A,$0C
  LD (IY+$0E),A
  LD HL,PeriodTable
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
l_C5D1:
  LD A,(IY+$0F)
  OR $C0
  LD (IY+$14),A
  INC DE
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD C,A
  LD (IY+$05),E
  LD (IY+$06),D
  LD E,(IY+$07)
  LD A,(IY+$08)
  LD IYH,A
  LD IYL,E
  BIT 7,(IX+$11)
  RET NZ
  JP StartVoice
l_C5F8:
  INC DE
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD (IY+$05),E
  LD (IY+$06),D
  RET

; $80-$87 an instrument slot, $88-$BF a pitch table, $FF the end, $C0-$FE
; skipped
;
; Used by the routine at ChannelFrame.
PatternCommand:
  LD A,(DE)
  CP $88
  JR NC,l_C623
  AND $07
  ADD A,(IY+$00)
  LD C,A
  LD B,$00
  LD HL,InstrumentSlots
  ADD HL,BC
  LD C,(HL)
  LD HL,Instruments
  ADD HL,BC
  LD (IY+$07),L
  LD (IY+$08),H
  INC DE
  RET
l_C623:
  CP $FF
  JR NZ,l_C62C
  LD (IY+$0B),$FF
  RET
l_C62C:
  CP $C0
  JR NC,l_C637
  AND $0F
  LD (IY+$0F),A
  INC DE
  RET
l_C637:
  INC DE
  CP $C2
  RET Z
  INC DE
  INC DE
  INC DE
  RET

; One frame of the pitch table: the note offset every few frames into the
; voice's period
;
; Used by the routine at ChannelFrame.
PitchFrame:
  BIT 7,(IX+$11)
  RET NZ
  LD A,(IY+$14)
  BIT 7,A
  RET Z
  AND $3F
  JR NZ,l_C653
  RES 7,(IY+$14)
  RET
l_C653:
  LD D,$07
  BIT 6,(IY+$14)
  JR NZ,l_C687
  DEC (IY+$12)
  RET NZ
  DEC (IY+$13)
  JP Z,l_C687
  LD L,(IY+$10)
  LD H,(IY+$11)
  INC L
  LD (IY+$10),L
  JP NZ,l_C676
  INC H
  LD (IY+$11),H
l_C676:
  LD A,(HL)
  AND D
  LD (IY+$12),A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IY+$0E)
  JP l_C6BC
l_C687:
  LD HL,$C732
  LD A,(IY+$14)
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  ADD HL,DE
  BIT 7,(HL)
  JR NZ,l_C6A1
  BIT 6,(IY+$14)
  JR NZ,l_C6A1
  LD (IY+$13),$01
  RET
l_C6A1:
  RES 6,(IY+$14)
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND D
  LD (IY+$12),A
  LD A,(HL)
  AND D
  INC A
  LD (IY+$13),A
  LD (IY+$10),L
  LD (IY+$11),H
  LD A,(IY+$0E)
l_C6BC:
  ADD A,A
  LD HL,PeriodTable
  ADD A,L
  LD L,A
  JR NC,l_C6C5
  INC H
l_C6C5:
  LD A,(HL)
  LD (IX+$03),A
  INC HL
  LD A,(HL)
  LD (IX+$04),A
  RET
