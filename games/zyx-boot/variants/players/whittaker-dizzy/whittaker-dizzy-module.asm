; --------------------------------------------------------------------------------------------------------------------
; whittaker-dizzy-module.asm: David Whittaker's driver (Fantasy World Dizzy): init, play, the pattern reader, envelopes, effects
;
; Entries: MusicInit $BFFE (LD A,n, the tune, then the vectors' first JP) starts that tune; MusicPlay $C003 plays one
; frame; $C006 stops the music and the effect; $C009 starts sound effect A. A frame: EffectFrame, then while the music
; is on the tempo (a fraction: TempoStep added to TempoSum, a row on the carry) lets each channel whose duration ran
; out read its pattern (ChannelTick, ReadPattern); ChannelFrame gives each channel's tone period and volume into
; AYRegisters, the master volume (a fade) lowers them, a running effect takes channel A, and WriteAY sends registers
; 10 down to 0.
;
; A pattern: a note $00-$7F (PeriodTable index plus the transposition and the channel's own transposition), a command
; $80-$93 through CommandOffsets (rest, sweep off, sweep up, the end of the pattern, sweep, transposition, tone, stop,
; hold, the channel's transposition, a new order list), $C0-$CF a long duration (241-256 frames), $D0-$DF a volume
; envelope (EnvelopeTable), $E0-$FF a duration of 1-32 frames. The format is in tools/res_whittaker.py.
; --------------------------------------------------------------------------------------------------------------------

; LD A,n: the tune (0 in zyxboot-10, 1 in zyxsiriu), then JP Init
MusicInit:
  LD A,$00

; JP Init
InitVector:
  JP Init

; JP Play: play one frame
MusicPlay:
  JP Play

; JP StopMusic
;
; Used by the routines at Init and CommandStop.
StopVector:
  JP StopMusic

; JP StartEffect: start sound effect A
EffectVector:
  JP StartEffect

; Start tune A: StopMusic, the tempo and the three channels' order lists from
; its 7-byte record
;
; HL = SongTable + 7 * the tune: the tempo into TempoStep and Tempo, then for
; each channel (IX = ChannelA, ChannelB, ChannelC, 34 bytes apart) the order
; list (+$03 / +$04), its first pattern (+$01 / +$02), the order offset 2, the
; duration count 1, the flags, sweep and channel transposition cleared. Last
; the transposition 0, TempoSum $FF and MusicOn $FF.
Init:
  PUSH AF
  CALL StopVector
  POP AF
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
  LD (TempoStep+$0001),A
  LD (Tempo),A
  INC HL
  LD IX,ChannelRecords
  LD C,$22
  LD A,$03
l_C02D:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  LD (IX+$10),$01
  LD (IX+$00),B
  LD (IX+$1D),B
  LD (IX+$20),B
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
  JR NZ,l_C02D
  LD (Transposition+$0001),A
  DEC A
  LD (TempoSum),A
  LD (MusicOn),A
  RET

; The three channels' records (34 bytes each, IX)
;
; As Platoon's driver's (variants/players/whittaker-platoon) with one more
; byte: +$00 flags, +$01 / +$02 the pattern pointer, +$03 / +$04 the order
; list, +$05 / +$06 the order offset, +$0F the envelope's speed, +$10 / +$11
; the frames left and the duration, +$12 the note, +$13 the volume, +$14-+$19
; the envelope, +$1A-+$1D the sweep, +$1E the notes set the noise, +$20 the
; channel's transposition (command $92), +$21 the channel's mixer bits.
ChannelRecords:
ChannelA:
  DEFB $21,$A4,$C9,$3D,$C9,$08,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$01,$04,$08,$0C,$06,$DF,$C4
  DEFB $ED,$C4,$06,$00,$01,$01,$02,$00,$00,$00,$00
  DEFB $09
ChannelB:
  DEFB $21,$8A,$C9,$0B,$C9,$08,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$01,$04,$08,$18,$06,$DF,$C4
  DEFB $ED,$C4,$06,$00,$02,$01,$03,$60,$00,$00,$00
  DEFB $12
ChannelC:
  DEFB $01,$C0,$C9,$6F,$C9,$02,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$03,$04,$20,$1D,$00,$30,$C5
  DEFB $3F,$C5,$0A,$01,$01,$01,$01,$40,$00,$00,$F4
  DEFB $24

; Play one frame: the effect, the tempo, the channels, the master volume, the
; effect over channel A, the AY
;
; Used by the routine at MusicPlay.
Play:
  LD A,(MusicOn)
  LD HL,EffectOn
  OR (HL)
  RET Z
  CALL EffectFrame
  LD A,(MusicOn)
  AND A
  JR Z,l_C12F
NoiseNote:
  LD A,$00                ; LD A,n: the noise channel's note (ReadPattern
                          ; writes it)
  LD (NoisePeriod+$0001),A
TempoStep:
  LD A,$2A                ; LD A,n: the tempo, added to TempoSum every frame; a
                          ; carry is a row
  LD HL,TempoSum
  ADD A,(HL)
  LD (HL),A
  JR NC,l_C103
  LD B,$00
  LD IX,ChannelRecords
  CALL ChannelTick
  LD IX,ChannelB
  CALL ChannelTick
  LD IX,ChannelC
  CALL ChannelTick
l_C103:
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
  LD (AYRegisters+$0006),A
l_C12F:
  LD A,(MusicOn)
  AND A
  JR NZ,MasterFade
  LD (AYRegisters+$0008),A
  LD (AYRegisters+$0009),A
  LD (AYRegisters+$000A),A
  LD A,$3F
  LD (AYRegisters+$0007),A
  JR EffectOverride
MasterFade:
  LD A,(MasterVolume)     ; Each volume less 15 - MasterVolume
  AND $0F
  XOR $0F
  JR Z,EffectOverride
  LD B,A
  LD A,(AYRegisters+$0008)
  SUB B
  JR NC,l_C156
  XOR A
l_C156:
  LD (AYRegisters+$0008),A
  LD A,(AYRegisters+$0009)
  SUB B
  JR NC,l_C160
  XOR A
l_C160:
  LD (AYRegisters+$0009),A
  LD A,(AYRegisters+$000A)
  SUB B
  JR NC,l_C16A
  XOR A
l_C16A:
  LD (AYRegisters+$000A),A
EffectOverride:
  LD A,(EffectOn)         ; While an effect runs: its period, noise and volume
                          ; on channel A
  AND A
  JR Z,WriteAY
  LD HL,(EffectRegisters+$0002)
  LD (AYRegisters),HL
  LD A,(EffectState+$0006)
  LD B,A
  BIT 3,A
  JR NZ,l_C187
  LD A,(EffectRegisters+$0008)
  LD (AYRegisters+$0006),A
l_C187:
  LD HL,AYRegisters+$0007
  LD A,(HL)
  OR $09
  AND B
  LD (HL),A
  LD A,(EffectRegisters+$000A)
  LD (AYRegisters+$0008),A
WriteAY:
  LD HL,AYRegisters+$000A ; Write AYRegisters to AY registers 10 down to 0
  LD A,$0A
  LD C,$FD
l_C19C:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,l_C19C
  RET

; AY register D = E
SetAYRegister:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; AY registers 10 down to 0 = 0, then the mixer (7) = $3F
;
; Used by the routine at StopEffect.
SilenceAY:
  LD C,$FD
  LD DE,$0A00
  SUB A
l_C1B9:
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),A
  DEC D
  JP P,l_C1B9
  LD DE,$073F
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Music off, the effect off, the volumes 0, MasterVolume 15
;
; Used by the routine at StopVector.
StopMusic:
  XOR A
  LD (MusicOn),A
  CALL StopEffect
  XOR A
  LD (AYRegisters+$0008),A
  LD (AYRegisters+$0009),A
  LD (AYRegisters+$000A),A
  LD A,$0F
  LD (MasterVolume),A
  RET

; The effect off, the AY silent
;
; Used by the routine at StopMusic.
StopEffect:
  XOR A
  LD (EffectOn),A
  JP SilenceAY

; Commands $80-$93: each byte the offset of its routine from its own address
; (0: none)
CommandOffsets:
  DEFB $9D,$91,$8A,$00,$00,$00,$00,$29,$77,$68,$53,$00,$00,$00,$1E,$97,$00,$00,$66,$01

; $93 w: the channel goes on with the order list at w
CommandOrders:
  LD A,(DE)
  LD (IX+$03),A
  LD L,A
  INC DE
  LD A,(DE)
  LD (IX+$04),A
  LD H,A
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$05),$02
  LD (IX+$06),B
  JP l_C2A4

; $8E: stop the music (StopMusic)
CommandStop:
  POP HL
  JP StopVector

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
  JR NZ,l_C241
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD BC,$0002
  LD E,(HL)
  INC HL
  LD D,(HL)
l_C241:
  LD (IX+$05),C
  LD (IX+$06),B
  LD B,$00
  JP l_C2A4

; $8A: the channel plays tone
CommandTone:
  LD A,(IX+$21)
  LD C,A
  AND $38
  LD HL,MixerBits+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  XOR A
  LD (IX+$1E),A
  JP l_C2A4

; $89 n: the transposition (the operand at $C346) = n
CommandTranspose:
  LD A,(DE)
  INC DE
  LD (Transposition+$0001),A
  JR l_C2A4

; $92 n: the channel's own transposition (+$20) = n
CommandChannelTranspose:
  LD A,(DE)
  INC DE
  LD (IX+$20),A
  JR l_C2A4

; $88 s w: a sweep: step s, width w, going up
CommandSweep:
  LD A,(DE)
  LD (IX+$1B),A
  INC DE
  LD A,(DE)
  LD (IX+$1A),A
  LD (IX+$1C),A
  INC DE
CommandSweepUp:
  LD (IX+$1D),$40         ; $82: the sweep goes up
  JR l_C2A4

; $81: no sweep
CommandSweepOff:
  LD (IX+$1D),B
  JR l_C2A4

; Sets flag bit 1; no command leads here (Platoon's $8D)
UnusedFlag:
  SET 1,(IX+$00)
  JR l_C2A4

; $80: a rest: volume 0, the envelope stopped, for the duration
CommandRest:
  LD (IX+$13),B
  RES 5,(IX+$00)
  JR l_C2D3

; $8F: the note goes on for the duration
CommandHold:
  JR l_C2CF

; A row of the channel at IX: when its duration runs out, ReadPattern
;
; Used by the routine at Play.
ChannelTick:
  DEC (IX+$10)
  RET NZ
  LD (IX+$00),B
ReadPattern:
  LD E,(IX+$01)           ; Read the pattern: commands and settings until a
                          ; note, rest or hold
  LD D,(IX+$02)
; This entry point is used by the routines at CommandOrders, CommandEnd,
; CommandTone, CommandTranspose, CommandChannelTranspose, CommandSweep,
; CommandSweepOff, UnusedFlag and PatternCommand.
l_C2A4:
  LD A,(DE)
  INC DE
  AND A
  JP M,PatternCommand
  LD (IX+$12),A
  BIT 0,(IX+$1E)
  JR Z,l_C2B6
  LD (NoiseNote+$0001),A
l_C2B6:
  LD L,(IX+$14)
  LD (IX+$16),L
  LD H,(IX+$15)
  LD (IX+$17),H
  LD A,(HL)
  LD (IX+$18),A
  LD (IX+$13),A
  LD A,(IX+$0F)
  LD (IX+$19),A
; This entry point is used by the routine at CommandHold.
l_C2CF:
  SET 5,(IX+$00)
; This entry point is used by the routine at CommandRest.
l_C2D3:
  LD A,(IX+$11)
  LD (IX+$10),A
  LD (IX+$02),D
  LD (IX+$01),E
  RET

; A byte $80-$FF: a command below $C0 (CommandOffsets), else a duration or an
; envelope
;
; Used by the routine at ChannelTick.
PatternCommand:
  CP $C0
  JR C,Dispatch
  ADD A,$20
  JR C,SetDuration
  ADD A,$10
  JR C,SetEnvelope
SetDuration:
  INC A                   ; $E0-$FF (and $C0-$CF): the duration
  LD (IX+$11),A
  JP l_C2A4
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
  JP l_C2A4
Dispatch:
  LD HL,EffectOverride+$0002 ; JP to the command's routine: CommandOffsets[A -
                             ; $80] + its address
  LD C,A
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  JP (HL)

; One frame of the channel at IX: HL = its tone period, A = its volume
;
; The envelope's next volume every +$0F frames (bit 7 set ends it), the note +
; the transposition (the operand at $C346) + the channel's transposition into
; PeriodTable, the sweep, the mixer bits into AYRegisters.
ChannelFrame:
  LD C,(IX+$00)
  BIT 5,C
  JR Z,Transposition
  LD A,(IX+$19)
  SUB $01
  LD (IX+$19),A
  JR NC,l_C33F
  LD A,(IX+$0F)
  LD (IX+$19),A
  LD L,(IX+$16)
  LD H,(IX+$17)
  INC HL
  LD A,(HL)
  AND A
  JP M,l_C33F
  LD (IX+$16),L
  LD (IX+$17),H
  LD (IX+$18),A
l_C33F:
  LD A,(IX+$18)
  LD (IX+$13),A
Transposition:
  LD A,$00                ; LD A,n: the transposition (command $89)
  ADD A,(IX+$12)
  ADD A,(IX+$20)
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
  JR Z,l_C3A7
  LD H,A
  LD B,(IX+$1A)
  SLA B
  BIT 7,L
  LD A,(IX+$1C)
  JR Z,l_C370
  BIT 0,C
  JR NZ,l_C38E
l_C370:
  BIT 5,L
  JR NZ,l_C380
  SUB (IX+$1B)
  JR NC,l_C38B
  SET 5,(IX+$1D)
  SUB A
  JR l_C38B
l_C380:
  ADD A,(IX+$1B)
  CP B
  JR C,l_C38B
  RES 5,(IX+$1D)
  LD A,B
l_C38B:
  LD (IX+$1C),A
l_C38E:
  EX DE,HL
  SRL B
  SUB B
  LD E,A
  LD A,D
  LD D,$00
  JR NC,l_C399
  DEC D
l_C399:
  ADD A,$A0
  JR C,l_C3A5
l_C39D:
  SLA E
  RL D
  ADD A,$18
  JR NC,l_C39D
l_C3A5:
  ADD HL,DE
  EX DE,HL
l_C3A7:
  LD A,C
  XOR $01
  LD (IX+$00),A
  CPL
  AND $03
MixerBits:
  LD A,$38                ; LD A,n: the mixer bits of the tone command
  JR NZ,l_C3BE
  LD A,(NoiseNote+$0001)
  XOR $08
  LD (NoisePeriod+$0001),A
  LD A,$07
l_C3BE:
  LD HL,AYRegisters+$0007
  XOR (HL)
  AND (IX+$21)
  XOR (HL)
  LD (HL),A
  EX DE,HL
  LD A,(IX+$13)
  RET

; $FF while the music plays
MusicOn:
  DEFB $FF

; Not 0 while a sound effect plays
EffectOn:
  DEFB $00

; 15: full; less fades the music
MasterVolume:
  DEFB $0F

; The tune's tempo (Init)
Tempo:
  DEFB $2A

; TempoStep is added here every frame
TempoSum:
  DEFB $B5

; The image of AY registers 0-10 that WriteAY sends
AYRegisters:
  DEFB $7C,$07,$C2,$03,$94,$05,$00,$38,$06,$06,$00

; The effect's period ($C3DE), noise ($C3E4) and volume ($C3E6)
EffectRegisters:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$3F,$00,$00,$00,$00

; The AY tone period of notes 0-85
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
  DEFW $0025,$0023,$0021,$001F,$001D,$001C

; Envelopes $D0-$DF: each the address of its volumes (the byte before it is the
; speed)
EnvelopeTable:
  DEFW $C4B7,$C4C6,$C4CD,$C4DF,$C4F1,$C4F6,$C4FB,$C502
  DEFW $C50B,$C51C,$C526,$C530,$C53A,$C54B,$C55B,$C55E

; The envelopes: a speed byte, then volumes a step, $87 ends
Envelopes:
  DEFB $01,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03,$02,$01,$87,$01
  DEFB $0D,$0E,$0F,$0E,$0D,$87,$01,$0F,$0E,$0D,$0B,$0D,$0C,$0A,$09,$0B
  DEFB $0A,$08,$07,$09,$08,$06,$05,$87,$01,$0F,$0F,$0D,$0B,$0D,$0C,$0A
  DEFB $09,$0B,$0A,$08,$07,$09,$08,$06,$05,$87,$01,$0F,$0E,$0D,$87,$01
  DEFB $0F,$0E,$0C,$87,$01,$0F,$0E,$0D,$0C,$0B,$87,$02,$0E,$0D,$0C,$0B
  DEFB $0A,$09,$08,$87,$08,$0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05
  DEFB $04,$03,$02,$01,$87,$02,$0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$87,$04
  DEFB $0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$87,$03,$0F,$0E,$0D,$0C,$0B,$0A
  DEFB $09,$08,$87,$01,$0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04
  DEFB $03,$02,$01,$87,$01,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04
  DEFB $03,$02,$01,$87,$01,$0F,$87,$01,$0C,$87

; Start sound effect A: its 14-byte record into EffectState, its period, noise
; and volume table
;
; Used by the routine at EffectVector.
StartEffect:
  LD HL,EffectOn
  LD (HL),$00
  LD HL,EffectTable
  ADD A,A
  ADD A,L
  LD L,A
  JR NC,l_C56E
  INC H
l_C56E:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD B,$0E
  LD HL,EffectState
l_C576:
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  DJNZ l_C576
  LD A,(EffectState+$0001)
  LD (EffectCounters),A
  LD HL,(EffectState+$0002)
  LD (EffectRegisters+$0002),HL
  LD A,(EffectState+$0006)
  BIT 3,A
  JR NZ,l_C593
  LD A,L
  LD (EffectRegisters+$0008),A
l_C593:
  LD A,(EffectState+$000B)
  LD (EffectCounters+$0001),A
  LD A,(EffectState+$000D)
  LD (EffectCounters+$0006),A
  LD A,(EffectState+$000A)
  LD HL,EffectVolumeTable
  ADD A,A
  LD C,A
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (EffectCounters+$0002),HL
  LD (EffectCounters+$0004),HL
  LD A,(HL)
  LD (EffectRegisters+$000A),A
  LD HL,EffectOn
  INC (HL)
  RET

; One frame of the running effect: the random number, the time, the repeats,
; the period sweep, the volume table
;
; Used by the routine at Play.
EffectFrame:
  CALL Random
  LD A,(EffectOn)
  AND A
  RET Z
  LD A,(EffectState)
  AND A
  JR NZ,l_C5D3
  LD A,(EffectState+$000C)
  AND A
  JR NZ,l_C5D3
  LD (EffectOn),A
  RET
l_C5D3:
  DEC A
  LD (EffectState),A
  LD A,(EffectCounters)
  AND A
  JR NZ,l_C60B
  LD A,(EffectState+$000C)
  AND A
  JR NZ,l_C5E9
  LD A,(EffectState+$0009)
  AND A
  JR Z,l_C64D
l_C5E9:
  DEC A
  LD (EffectState+$0009),A
  LD A,(EffectState+$0001)
  LD (EffectCounters),A
  LD A,(EffectState+$0007)
  AND A
  JR Z,l_C5FC
  LD A,(RandomSeed)
l_C5FC:
  LD B,A
  LD A,(EffectState+$0002)
  ADD A,B
  LD (EffectRegisters+$0002),A
  LD A,(EffectState+$0003)
  ADD A,B
  LD (EffectRegisters+$0003),A
l_C60B:
  LD HL,EffectCounters
  DEC (HL)
  LD HL,EffectState+$000D
  LD A,(HL)
  AND A
  JR Z,l_C61D
  LD HL,EffectCounters+$0006
  DEC (HL)
  JR NZ,l_C640
  LD (HL),A
l_C61D:
  LD A,(EffectState+$0008)
  AND A
  JR Z,l_C640
  JP P,l_C633
  LD HL,(EffectRegisters+$0002)
  LD DE,(EffectState+$0004)
  ADD HL,DE
  LD (EffectRegisters+$0002),HL
  JR l_C640
l_C633:
  LD HL,(EffectRegisters+$0002)
  LD DE,(EffectState+$0004)
  AND A
  SBC HL,DE
  LD (EffectRegisters+$0002),HL
l_C640:
  LD A,(EffectState+$0006)
  BIT 3,A
  JR NZ,l_C64D
  LD A,(EffectRegisters+$0002)
  LD (EffectRegisters+$0008),A
l_C64D:
  LD A,(EffectCounters+$0001)
  DEC A
  LD (EffectCounters+$0001),A
  JR NZ,l_C674
  LD A,(EffectState+$000B)
  LD (EffectCounters+$0001),A
  LD HL,(EffectCounters+$0004)
  LD A,(HL)
  INC HL
  AND A
  JP P,l_C66E
  CP $80
  JR NZ,l_C674
  LD HL,(EffectCounters+$0002)
  LD A,(HL)
  INC HL
l_C66E:
  LD (EffectCounters+$0004),HL
  LD (EffectRegisters+$000A),A
l_C674:
  RET

; The 26 sound effects' records (14 bytes each)
EffectTable:
  DEFW Effects,$C6B7,$C6C5,$C6D3,$C6E1,$C6EF,$C6FD,$C70B
  DEFW $C719,$C727,$C735,$C743,$C751,$C75F,$C76D,$C77B
  DEFW $C789,$C799,$C7A7,$C7B5,$C7C3,$C7D1,$C7DF,$C7ED
  DEFW $C7FB,$C809

; The effects: time, repeat delay, period, sweep step and direction, repeats,
; the volume table, its speed
Effects:
  DEFB $02,$04,$04,$08,$00,$00,$F6,$01,$00,$63,$03,$01,$00,$00
  DEFB $02,$04,$10,$03,$00,$00,$F6,$01,$00,$63,$03,$01,$00,$00
  DEFB $02,$04,$18,$03,$00,$00,$F7,$01,$00,$63,$04,$01,$00,$00
  DEFB $02,$04,$08,$03,$00,$00,$F7,$01,$00,$63,$04,$01,$00,$00
  DEFB $05,$01,$5E,$01,$01,$00,$FE,$00,$FF,$63,$09,$01,$00,$00
  DEFB $05,$01,$5E,$02,$01,$00,$FE,$00,$FF,$63,$09,$01,$00,$00
  DEFB $09,$0E,$02,$02,$28,$00,$FE,$00,$01,$00,$00,$01,$00,$00
  DEFB $0F,$03,$1E,$0A,$60,$00,$F6,$00,$FF,$FF,$00,$01,$00,$00
  DEFB $0C,$02,$3C,$00,$02,$00,$FE,$00,$01,$63,$08,$02,$00,$00
  DEFB $0C,$63,$4C,$00,$00,$00,$FE,$00,$01,$63,$05,$02,$00,$00
  DEFB $32,$63,$1F,$00,$11,$00,$F7,$00,$01,$63,$01,$02,$00,$02
  DEFB $0C,$63,$02,$01,$18,$00,$FE,$00,$FF,$63,$08,$02,$00,$03
  DEFB $C8,$FF,$20,$00,$02,$08,$FE,$00,$FF,$63,$01,$08,$00,$00
  DEFB $0C,$05,$90,$01,$41,$00,$F6,$00,$FF,$63,$00,$01,$00,$00
  DEFB $0C,$02,$0F,$00,$11,$00,$F7,$FF,$01,$FF,$00,$01,$00,$00
  DEFB $32,$0A,$A0,$00,$18,$00,$FE,$00,$FF,$63,$08,$05,$00,$02
  DEFB $0B,$05,$1F,$00,$08,$00,$F6,$00,$01,$0A,$08,$01,$00,$00
  DEFB $FF,$00,$19,$28,$1F,$00,$01,$00,$F6,$00,$01,$00,$06,$02
  DEFB $00,$03,$50,$03,$F0,$07,$88,$00,$FE,$00,$FF,$63,$07,$02
  DEFB $00,$00,$46,$03,$10,$0A,$60,$00,$F6,$00,$FF,$FF,$04,$02
  DEFB $00,$00,$50,$04,$00,$08,$16,$00,$F6,$01,$FF,$63,$00,$04
  DEFB $00,$00,$14,$63,$20,$01,$10,$00,$FE,$00,$01,$63,$00,$05
  DEFB $00,$02,$0F,$63,$E0,$01,$42,$00,$FE,$00,$FF,$63,$04,$01
  DEFB $00,$00,$0F,$63,$90,$01,$20,$00,$F6,$00,$FF,$63,$05,$01
  DEFB $00,$00,$32,$0A,$14,$00,$07,$00,$F6,$01,$FF,$0A,$00,$04
  DEFB $00,$00,$3C,$06,$03,$01,$48,$00,$F6,$00,$FF,$63,$00,$04
  DEFB $00,$00

; The effects' volume tables
EffectVolumeTable:
  DEFW EffectVolumes,$C83B,$C854,$C86C,$C873,$C878,$C881,$C88E,$C890,$C89F

; Volumes a step: $FF ends, $80 starts the table again
EffectVolumes:
  DEFB $0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03,$02,$01,$FF
  DEFB $06,$08,$0A,$0B,$0C,$0D,$0E,$0E,$0E,$0D,$0D,$0C,$0C,$0B,$0B,$09
  DEFB $08,$07,$06,$05,$04,$03,$02,$01,$FF,$06,$08,$0A,$0C,$0E,$0F,$0E
  DEFB $0E,$0D,$0D,$0C,$0C,$0B,$0B,$09,$08,$07,$06,$05,$04,$03,$02,$01
  DEFB $FF,$0A,$00,$00,$00,$0A,$00,$FF,$06,$08,$0A,$0C,$FF,$0F,$00,$00
  DEFB $0E,$00,$00,$0D,$00,$FF,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03
  DEFB $02,$01,$FF,$0C,$80,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04
  DEFB $03,$02,$01,$FF,$0D,$00,$00,$00,$0B,$00,$FF

; The running effect: a copy of its record
EffectState:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Its delay counter, volume speed counter, volume table start and pointer,
; sweep counter
EffectCounters:
  DEFB $00,$00,$00,$00,$00,$00,$00

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
  DEFB $5B,$7F,$F6,$FF
