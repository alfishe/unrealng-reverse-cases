; --------------------------------------------------------------------------------------------------------------------
; whittaker-storm-module.asm: David Whittaker's driver (Stormbringer): init, play, the pattern reader, envelopes, ornaments
;
; Two entries: MusicInit $C000 starts the tune whose number is its LD A,n operand: the tempo and the three order lists
; from its 7-byte record in SongTable ($C4EE); MusicPlay $C0B9 plays one frame while the music is on: on a tempo frame
; (TempoCounter) each channel whose duration ran out reads its pattern (ChannelTick, ReadPattern), then for each
; channel ChannelFrame gives the tone period and volume into AYRegisters, and WriteAY sends registers 13 down to 0.
;
; A pattern: a note $00-$7F (PeriodTable index plus the transposition, from note 12 up), a command $80-$8F through
; CommandOffsets (rest, sweep off / up / down, slide, bend up / down, the end of the pattern, sweep, transposition,
; tone, noise, tone and noise, flag, stop, hold), $C0-$CF an ornament (OrnamentOffsets), $D0-$DF a start volume and
; three bytes of envelope (attack, decay, sustain), $E0-$FF the duration of the notes after it. The format is in
; tools/res_whittaker.py.
; --------------------------------------------------------------------------------------------------------------------

; Start the tune (LD A,n: 0 here): the tempo and the three channels' order
; lists
;
; MusicOn = 0; HL = SongTable + 7 * the tune: the tempo into TempoReload, then
; for each channel (IX = ChannelA, ChannelB, ChannelC, 32 bytes apart) the
; order list (+$03 / +$04), its first pattern (+$01 / +$02), the order offset
; 2, the duration count 1, the flags and sweep cleared. Last the transposition
; 0, TempoCounter 1, MusicOn 1.
MusicInit:
  LD A,$00
  EX AF,AF'
  XOR A
  LD (MusicOn),A
  EX AF,AF'
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
  LD C,$20
  LD A,$03
l_C021:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  LD (IX+$10),$01
  LD (IX+$00),B
  LD (IX+$1D),B
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
  JR NZ,l_C021
  LD (Transposition+$0001),A
  INC A
  LD (TempoCounter),A
  LD (MusicOn),A
  RET

; The three channels' records (32 bytes each, IX)
;
; As Platoon's driver's (variants/players/whittaker-platoon) but the envelope:
; +$00 flags (bit 6 the attack), +$01 / +$02 the pattern pointer, +$03 / +$04
; the order list, +$05 / +$06 the order offset, +$07 / +$08 the slide's sum,
; +$09-+$0C the ornament, +$0D / +$0E the slide, +$10 / +$11 the frames left
; and the duration, +$12 the note, +$13 the volume, +$14 the attack rate, +$15
; the decay rate, +$16 the current rate, +$17 the sustain length, +$18 its
; counter, +$19 the start volume, +$1A-+$1D the sweep, +$1E the notes set the
; noise, +$1F the channel's mixer bits.
ChannelRecords:
ChannelA:
  DEFB $01,$09,$C7,$F5,$C4,$48,$00,$00
  DEFB $FA,$B2,$C4,$B3,$C4,$F4,$01,$00
  DEFB $05,$20,$41,$08,$51,$71,$01,$34
  DEFB $00,$08,$02,$01,$02,$00,$00,$09
ChannelB:
  DEFB $21,$BF,$C7,$75,$C5,$4A,$00,$41
  DEFB $00,$B2,$C4,$B3,$C4,$01,$01,$00
  DEFB $01,$02,$2D,$08,$00,$11,$01,$05
  DEFB $02,$0B,$02,$01,$01,$40,$00,$12
ChannelC:
  DEFB $01,$B5,$C9,$F1,$C5,$3C,$00,$11
  DEFB $00,$B2,$C4,$B3,$C4,$01,$01,$00
  DEFB $07,$20,$41,$08,$51,$71,$01,$34
  DEFB $00,$08,$04,$02,$04,$60,$00,$24

; The frames left until the next tempo frame
TempoCounter:
  DEFB $04

; Play one frame: the channels on a tempo frame, the periods and volumes, the
; AY
MusicPlay:
  LD A,(MusicOn)
  AND A
  JP Z,l_C112
NoiseNote:
  LD A,$4C                ; LD A,n: the noise channel's note (ReadPattern
                          ; writes it), the noise period of this frame
  LD (NoisePeriod+$0001),A
  LD HL,TempoCounter
  DEC (HL)
  JR NZ,l_C0E6
  LD B,(HL)
  LD IX,ChannelRecords
  CALL ChannelTick
  LD IX,ChannelB
  CALL ChannelTick
  LD IX,ChannelC
  CALL ChannelTick
  LD HL,TempoCounter
TempoReload:
  LD (HL),$04             ; LD (HL),n: the tempo (frames a row, from SongTable)
l_C0E6:
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
  LD A,$4C                ; LD A,n: the noise period for AYRegisters
  LD (AYRegisters+$0006),A
l_C112:
  LD A,(MusicOn)
  AND A
  JR NZ,WriteAY
  RET

; Music off, the AY silent, the three volumes 0
StopMusic:
  XOR A
  LD (MusicOn),A
  CALL SilenceAY
  XOR A
  LD (AYRegisters+$0008),A
  LD (AYRegisters+$0009),A
  LD (AYRegisters+$000A),A
  RET

; Write AYRegisters to AY registers 13 down to 0
;
; Used by the routine at MusicPlay.
WriteAY:
  LD HL,PeriodTable
  LD A,$0D
  LD C,$FD
l_C132:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,l_C132
  RET

; AY register D = E
SetAYRegister:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Every AY register 13 down to 0 = 0, then the mixer (7) = $3F
;
; Used by the routines at StopMusic and CommandStop.
SilenceAY:
  LD C,$FD
  LD DE,$0D00
  SUB A
l_C14F:
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),A
  DEC D
  JP P,l_C14F
  LD DE,$073F
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Commands $80-$8F: each byte the offset of its routine from its own address
CommandOffsets:
  DEFB $CB,$B3,$B7,$BC,$7A,$A9,$A4,$11,$93,$8B,$50,$3A,$62,$B8,$02,$C5

; $8E: music off, the AY silent
CommandStop:
  XOR A
  LD (MusicOn),A
  POP HL
  JP SilenceAY

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
  JR NZ,l_C1A1
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD BC,$0002
  LD E,(HL)
  INC HL
  LD D,(HL)
l_C1A1:
  LD (IX+$05),C
  LD (IX+$06),B
  LD B,$00
  JP l_C24F

; $8B: the channel plays noise, its notes set the noise period
CommandNoise:
  LD A,(IX+$1F)
  LD C,A
  AND $07
  LD HL,MixerBits+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  LD A,$01
  LD (IX+$1E),A
  JP l_C24F

; $8A: the channel plays tone
CommandTone:
  LD A,(IX+$1F)
  LD C,A
  AND $38
  LD HL,MixerBits+$0001
  XOR (HL)
  AND C
  XOR (HL)
  LD (HL),A
  XOR A
  LD (IX+$1E),A
  JP l_C24F

; $8C: tone and noise
CommandBoth:
  LD HL,MixerBits+$0001
  LD A,(IX+$1F)
  CPL
  AND (HL)
  LD (HL),A
  LD A,$01
  LD (IX+$1E),A
  JR l_C24F

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
  JR l_C24F

; $89 n: the transposition (the operand at $C32B) = n
CommandTranspose:
  LD A,(DE)
  INC DE
  LD (Transposition+$0001),A
  JR l_C24F

; $88 s w: a sweep: step s, width w
CommandSweep:
  LD A,(DE)
  LD (IX+$1B),A
  INC DE
  LD A,(DE)
  LD (IX+$1A),A
  INC DE
  LD (IX+$1C),A
  JR l_C24F

; $86: the note bends down a step a tempo frame
CommandBendDown:
  SET 7,(IX+$00)

; $85: the note bends up
CommandBendUp:
  SET 3,(IX+$00)
  JR l_C24F

; $81: no sweep
CommandSweepOff:
  LD (IX+$1D),B
  JR l_C24F

; $82: the sweep goes up
CommandSweepUp:
  LD (IX+$1D),$40
  JR l_C24F

; $83: the sweep goes down
CommandSweepDown:
  LD (IX+$1D),$C0
  JR l_C24F

; $8D: sets flag bit 1
CommandFlag:
  SET 1,(IX+$00)
  JR l_C24F

; $80: a rest: volume 0 for the duration
CommandRest:
  LD (IX+$13),B
  RES 5,(IX+$00)
  JR l_C27B

; $8F: the note goes on for the duration
CommandHold:
  RES 5,(IX+$00)
  JR l_C27B

; A tempo frame of the channel at IX: when its duration runs out, ReadPattern;
; else the bend
;
; Used by the routine at MusicPlay.
ChannelTick:
  DEC (IX+$10)
  JR NZ,Bend
  LD (IX+$00),B
ReadPattern:
  LD E,(IX+$01)           ; Read the pattern: commands and settings until a
                          ; note, rest or hold
  LD D,(IX+$02)
; This entry point is used by the routines at CommandEnd, CommandNoise,
; CommandTone, CommandBoth, CommandSlide, CommandTranspose, CommandSweep,
; CommandBendUp, CommandSweepOff, CommandSweepUp, CommandSweepDown and
; CommandFlag.
l_C24F:
  LD A,(DE)
  INC DE
  AND A
  JP M,PatternCommand
  LD (IX+$12),A
  BIT 0,(IX+$1E)
  JR Z,l_C261
  LD (NoiseNote+$0001),A
l_C261:
  LD A,(IX+$19)
  LD (IX+$13),A
  SET 5,(IX+$00)
  SET 6,(IX+$00)
  LD A,(IX+$14)
  LD (IX+$16),A
  LD A,(IX+$17)
  LD (IX+$18),A
; This entry point is used by the routines at CommandRest and CommandHold.
l_C27B:
  LD A,(IX+$11)
  LD (IX+$10),A
  LD (IX+$02),D
  LD (IX+$01),E
  RET
Bend:
  LD A,(IX+$00)           ; Bend on (flag bit 3): the note one up or down
  BIT 3,A
  RET Z
  RLA
  JR NC,l_C295
  INC (IX+$12)
  RET
l_C295:
  DEC (IX+$12)
  RET
PatternCommand:
  CP $C0                  ; A byte $80-$FF: a command below $C0
                          ; (CommandOffsets), else an ornament, an envelope or
                          ; a duration
  JR C,Dispatch
  ADD A,$20
  JR C,SetDuration
  ADD A,$10
  JR C,SetEnvelope
SetOrnament:
  ADD A,$10               ; $C0-$CF: the ornament OrnamentOffsets[n]
  LD C,A
  LD HL,OrnamentOffsets
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  LD (IX+$0B),L
  LD (IX+$09),L
  LD (IX+$0C),H
  LD (IX+$0A),H
  JR l_C24F
SetDuration:
  INC A                   ; $E0-$FF: the duration = n + 1
  LD (IX+$11),A
  JR l_C24F
SetEnvelope:
  LD (IX+$19),A           ; $D0-$DF v a d s: the start volume v, the attack and
                          ; decay rates, the sustain length
  LD A,(DE)
  INC DE
  LD (IX+$14),A
  LD A,(DE)
  INC DE
  LD (IX+$15),A
  LD A,(DE)
  INC DE
  LD (IX+$17),A
  JP l_C24F
Dispatch:
  LD HL,l_C0E6+$0001      ; JP to the command's routine: CommandOffsets[A -
                          ; $80] + its address
  LD C,A
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  JP (HL)

; One frame of the channel at IX: HL = its tone period, A = its volume
;
; The envelope (the volume rises by the attack rate to 15, falls by the decay
; rate, holds for the sustain length, then falls), the ornament's next note
; offset ($87 or more: the ornament again), the note + the transposition into
; PeriodTable, the sweep, the slide, the mixer bits into AYRegisters.
ChannelFrame:
  LD C,(IX+$00)
  BIT 5,C
  JR Z,Transposition
  LD A,(IX+$16)
  SUB $10
  JR NC,l_C312
  BIT 6,C
  JR Z,l_C317
  ADD A,(IX+$13)
  JR NC,l_C2F7
  SBC A,A
l_C2F7:
  ADD A,$10
  LD (IX+$13),A
  LD A,(IX+$18)
  SUB $10
  JR NC,l_C30D
  RES 6,C
  LD A,(IX+$15)
  LD (IX+$16),A
  JR Transposition
l_C30D:
  LD (IX+$18),A
  JR Transposition
l_C312:
  LD (IX+$16),A
  JR Transposition
l_C317:
  CPL
  SUB $0F
  ADD A,(IX+$13)
  JR C,l_C320
  SUB A
l_C320:
  LD (IX+$13),A
  DEC (IX+$18)
  JR NZ,Transposition
  RES 5,C
Transposition:
  LD A,$00                ; LD A,n: the transposition (command $89)
  ADD A,(IX+$12)
  LD B,A
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  LD A,(HL)
  CP $87
  JR C,l_C342
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD A,(HL)
l_C342:
  INC HL
  LD (IX+$0B),L
  LD (IX+$0C),H
  ADD A,B
  LD HL,PeriodTable-24
  LD D,$00
  ADD A,A
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD L,(IX+$1D)
  BIT 6,L
  JR Z,l_C3A4
  LD H,A
  LD B,(IX+$1A)
  SLA B
  BIT 7,L
  LD A,(IX+$1C)
  JR Z,l_C36D
  BIT 0,C
  JR NZ,l_C38B
l_C36D:
  BIT 5,L
  JR NZ,l_C37D
  SUB (IX+$1B)
  JR NC,l_C388
  SET 5,(IX+$1D)
  SUB A
  JR l_C388
l_C37D:
  ADD A,(IX+$1B)
  CP B
  JR C,l_C388
  RES 5,(IX+$1D)
  LD A,B
l_C388:
  LD (IX+$1C),A
l_C38B:
  EX DE,HL
  SRL B
  SUB B
  LD E,A
  LD A,D
  LD D,$00
  JR NC,l_C396
  DEC D
l_C396:
  ADD A,$A0
  JR C,l_C3A2
l_C39A:
  SLA E
  RL D
  ADD A,$18
  JR NC,l_C39A
l_C3A2:
  ADD HL,DE
  EX DE,HL
l_C3A4:
  LD A,C
  XOR $01
  LD (IX+$00),A
  BIT 2,C
  JR Z,l_C3CF
  LD B,(IX+$0E)
  DJNZ l_C3CC
  LD C,(IX+$0D)
  BIT 7,C
  JR Z,l_C3BB
  DEC B
l_C3BB:
  LD L,(IX+$07)
  LD H,(IX+$08)
  ADD HL,BC
  LD (IX+$07),L
  LD (IX+$08),H
  ADD HL,DE
  EX DE,HL
  JR l_C3CF
l_C3CC:
  LD (IX+$0E),B
l_C3CF:
  CPL
  AND $03
MixerBits:
  LD A,$38                ; LD A,n: the mixer bits of the tone and noise
                          ; commands
  JR NZ,l_C3E0
  LD A,(NoiseNote+$0001)
  XOR $08
  LD (NoisePeriod+$0001),A
  LD A,$07
l_C3E0:
  LD HL,AYRegisters+$0007
  XOR (HL)
  AND (IX+$1F)
  XOR (HL)
  LD (HL),A
  EX DE,HL
  LD A,(IX+$13)
  RET

; The image of AY registers 0-12 that WriteAY sends (register 13 is
; PeriodTable's first byte)
AYRegisters:
  DEFB $B2,$00,$36,$02,$B2,$00,$4C,$38,$08,$08,$08,$00,$00

; The AY tone period of notes 12-95 (ChannelFrame indexes it from 24 bytes
; before)
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
  DEFW $0025,$0023,$0021,$001F

; Ornaments $C0-$CF: each byte the offset of its data from its own address
OrnamentOffsets:
  DEFB $0F,$10,$13,$16,$19,$1D,$20,$23,$26,$29,$2B,$2D,$2F,$34,$36,$00

; The ornaments: note offsets a frame, $87 or more: the ornament again
Ornaments:
  DEFB $87,$00,$03,$07,$87,$00,$04,$07,$87,$00,$02,$07,$87,$00,$04,$07
  DEFB $0C,$87,$07,$0C,$0F,$87,$07,$0C,$10,$87,$03,$07,$0C,$87,$04,$07
  DEFB $0C,$87,$00,$0C,$87,$00,$03,$87,$00,$04,$87,$0C,$0C,$0C,$0C,$00
  DEFB $87,$00,$07,$87,$00,$00,$00,$00,$0C,$87

; 1 while the music plays
MusicOn:
  DEFB $01
