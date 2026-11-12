; --------------------------------------------------------------------------------------------------------------------
; sheridan-module.asm: Ian Sheridan's driver: init, play, the sequences and patterns, the ADSR envelope, arpeggio, vibrato, fades
;
; Two vectors: MusicPlay $C000 (JP Play) plays one frame; MusicInit $C003 (JP Init) starts song Tune. Play first takes
; a request from Command (a song number + 1, $FE fade out and stop, $FF stop), runs the fade (FadeFrame), then for
; each running channel ChannelFrame: the next pattern item when the note's frames run out, the volume envelope
; (attack, decay, sustain, release), the arpeggio, the vibrato into AYRegisters; the master volume lowers the three
; volumes and WriteAY sends registers 0-10.
;
; A song is three sequences (SongTable, 6 bytes a song). A sequence: a pattern number and its repeat count
; (PatternTable), $FA n / $FB n (the note offset: + n / = n), $FC n (the duration table), $FD (the song again), $FE
; (the sequence again), $FF (stop). A pattern: a note byte (the note = the byte - the note offset) and a duration
; index (DurationTable), $60 d (a tie), $61 i (the instrument), $64 n (the noise period), $65 s (the envelope shape),
; $FC n / $FD n (fade in / out), $FF (silence), $FE (the end). The format is in tools/res_sheridan.py.
; --------------------------------------------------------------------------------------------------------------------

; JP Play: play one frame
MusicPlay:
  JP Play

; JP Init: start song Tune
MusicInit:
  JP Init

; A request for the next Play: a song number + 1, $FE fade out and stop, $FF
; stop (0: none)
Command:
  DEFB $00

; 1 while the music plays
Playing:
  DEFB $01

; Not 0: channel C's instrument uses the AY envelope (its period follows the
; note)
HardwareEnvelope:
  DEFB $00

; The song Init starts ($FF: 0)
Tune:
  DEFB $00

; The duration table: 8 frame counts, picked by the sequence command $FC
DurationTable:
  DEFW $C808

; Bytes no code reads
Spare:
  DEFB $00,$00,$00,$00,$30,$30,$30,$30,$00

; 15 full; the fades move it, Play lowers the volumes by 15 - it
MasterVolume:
  DEFB $0F

; 1: stop the music when the fade ends
StopAfterFade:
  DEFB $00

; +1 fade in, $FF fade out, 0 no fade
FadeStep:
  DEFB $00

; The frames left until the next fade step
FadeCounter:
  DEFB $00

; Frames a fade step ($80: at once)
FadeSpeed:
  DEFB $00

; A byte no code reads
Spare2:
  DEFB $00

; One frame of the fade: MasterVolume one step every FadeSpeed frames, stop at
; 0 or 15
;
; Used by the routine at Play.
FadeFrame:
  LD A,(FadeStep)
  AND A
  LD B,A
  RET Z
  LD A,(FadeSpeed)
  CP $80
  JP Z,l_C044
  LD A,(FadeCounter)
  DEC A
  LD (FadeCounter),A
  RET NZ
  LD A,(FadeSpeed)
  LD (FadeCounter),A
  LD A,(MasterVolume)
  ADD A,B
  BIT 4,A
  JP NZ,l_C053
  LD (MasterVolume),A
  RET
l_C044:
  LD A,B
  CP $01
  LD A,$0F
  JP Z,l_C04D
  XOR A
l_C04D:
  LD (MasterVolume),A
  JP l_C053
l_C053:
  XOR A
  LD (FadeStep),A
  LD A,(StopAfterFade)
  AND A
  JP NZ,StopMusic
  RET

; Pattern command $FC n: fade in, n frames a step
;
; Used by the routine at ReadPattern.
FadeIn:
  LD A,$00
  LD (MasterVolume),A
  LD A,$01
; This entry point is used by the routine at FadeOut.
l_C066:
  LD (FadeStep),A
  INC HL
  LD A,(HL)
  LD (FadeSpeed),A
  LD (FadeCounter),A
  INC HL
  JP l_C51C

; Pattern command $FD n: fade out, n frames a step
;
; Used by the routine at ReadPattern.
FadeOut:
  LD A,$0F
  LD (MasterVolume),A
  LD A,$FF
  JP l_C066

; AY register H = L
;
; Used by the routines at Init, Silence, WriteAY, SetPeriod, PatternShape and
; PatternInstrument.
SetAYRegister:
  LD BC,$FFFD
  OUT (C),H
  LD B,$BF
  OUT (C),L
  RET

; The image of AY registers 0-10 (the periods, the noise, the mixer, the
; volumes)
AYRegisters:
  DEFB $9D,$06,$6A,$00,$9F,$06,$02,$EA,$0F,$09,$0F

; The three channels' records (43 bytes each, IX)
;
; +$00 / +$01 the pattern pointer; +$02 the frames left; +$03 the note; +$04
; the volume; +$05 the peak; +$06 the sustain time; +$07 / +$08 the attack
; delay and step; +$09 / +$0A the decay delay and step; +$0B the attack
; counter; +$0C the phase (bits 0-1: 1 attack, 2 decay, 3 sustain, 0 release;
; bit 7 stopped); +$0D the offset of its period in AYRegisters, +$0F of its
; volume; +$10-+$14 the arpeggio (index, loop, end, table); +$15 / +$16 the
; pattern's start; +$17 the noise mask; +$19-+$1F the vibrato (delay, depth,
; period, direction, offset); +$20 / +$21 the sequence pointer; +$22 the
; repeats left; +$23 / +$24 the sequence's start; +$25-+$2A the decay, sustain
; and release counters.
ChannelRecords:
ChannelA:
  DEFB $7E,$CA,$06,$0E,$0F,$0F,$00,$00,$0F,$01,$FF
  DEFB $00,$02,$00,$01,$08,$00,$00,$01,$BB,$C8,$78
  DEFB $CA,$00,$F7,$00,$00,$02,$00,$FE,$03,$03,$B9
  DEFB $C9,$01,$B3,$C9,$01,$00,$00,$FF,$00,$03
ChannelB:
  DEFB $2A,$CA,$06,$3E,$09,$09,$00,$00,$09,$01,$F7
  DEFB $00,$02,$02,$03,$09,$00,$00,$01,$98,$C8,$22
  DEFB $CA,$10,$EF,$FF,$FF,$00,$01,$00,$00,$00,$C8
  DEFB $C9,$04,$C6,$C9,$01,$00,$00,$FF,$00,$00
ChannelC:
  DEFB $45,$CA,$06,$0E,$0F,$0F,$00,$00,$0F,$01,$FF
  DEFB $00,$02,$04,$05,$0A,$00,$00,$01,$75,$C8,$3D
  DEFB $CA,$00,$00,$FF,$FF,$00,$01,$00,$00,$00,$D1
  DEFB $C9,$01,$CF,$C9,$01,$00,$00,$FF,$00,$03

; Bytes no code reads
Spare3:
  DEFB $00,$00,$00,$00,$00

; Command n: MasterVolume 15, no fade, then Init
;
; Used by the routine at Play.
Restart:
  LD A,$0F
  LD (MasterVolume),A
  XOR A
  LD (FadeStep),A
  LD (StopAfterFade),A

; Start song Tune: silence, the three sequences from SongTable, their first
; patterns
;
; Tune $FF is taken as 0. Every channel's frame counter 1, the note offset 0;
; the three words of SongTable + 6 * Tune go into the operands of the LD
; HL,(nn) below (the sequences' addresses), ChannelStart for A, B and C (IX =
; ChannelA, ChannelB, ChannelC), Playing = 1, the mixer $F8.
Init:
  CALL Silence
  LD A,(Tune)
  CP $FF
  JP NZ,l_C135
  INC A
  LD (Tune),A
l_C135:
  LD A,$01
  LD (ChannelRecords+$0002),A
  LD (ChannelB+$0002),A
  LD (ChannelC+$0002),A
  XOR A
  LD (HardwareEnvelope),A
  PUSH IX
  LD IX,ChannelRecords
  LD A,(Tune)
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  LD L,A
  LD H,$00
  LD DE,SongTable
  ADD HL,DE
  LD (l_C135+$0031),HL
  INC HL
  INC HL
  LD (l_C135+$003B),HL
  INC HL
  INC HL
  LD (l_C135+$0045),HL
  LD HL,(SongTable)
  CALL ChannelStart
  LD IX,ChannelB
  LD HL,(SongTable+2)
  CALL ChannelStart
  LD IX,ChannelC
  LD HL,(SongTable+4)
  CALL ChannelStart
  LD A,$01
  LD (Playing),A
  LD H,$07
  LD L,$F8
  CALL SetAYRegister
  LD A,(Tune)
  CP $01
  POP IX
  RET

; HALT and Play until the music stops (no code calls it)
PlayToEnd:
  HALT
  CALL Play
  LD A,(Playing)
  AND A
  JP NZ,PlayToEnd
  RET

; The channel at IX starts its sequence at HL: the first pattern
; (NextSequenceItem), counters cleared
;
; Used by the routine at Init.
ChannelStart:
  LD (IX+$20),L
  LD (IX+$23),L
  LD (IX+$00),L
  LD (IX+$21),H
  LD (IX+$24),H
  LD (IX+$01),H
  CALL NextSequenceItem
  LD (IX+$02),$01
  LD (IX+$0C),$00
  LD (IX+$05),$00
  LD (IX+$04),$00
  LD (IX+$17),$00
  RET

; Silence, Playing = 0
;
; Used by the routines at FadeFrame, Play, ChannelStop and SequenceStop.
StopMusic:
  CALL Silence
  XOR A
  LD (Playing),A
  RET

; AYRegisters cleared, the mixer $F8, then WriteAY
;
; Used by the routines at Init and StopMusic.
Silence:
  LD H,$07
  LD L,$FF
  CALL SetAYRegister
  LD HL,AYRegisters
  LD DE,AYRegisters+$0001
  LD BC,$000A
  LD (HL),$00
  LDIR
  LD A,$F8
  LD (AYRegisters+$0007),A

; WriteAY
;
; Used by the routine at Play.
WriteAY:
  LD B,$0B                ; Write AYRegisters to AY registers 0-10
  LD H,$00
  LD DE,AYRegisters
l_C1F1:
  LD A,(DE)
  LD L,A
  PUSH BC
  CALL SetAYRegister
  POP BC
  INC H
  INC DE
  DJNZ l_C1F1
  RET

; Play one frame: Command, the fade, the three channels, the master volume,
; WriteAY
;
; Used by the routines at MusicPlay and PlayToEnd.
Play:
  LD A,(Command)
  AND A
  JP Z,l_C22D
  LD B,A
  XOR A
  LD (Command),A
  LD A,B
  CP $FF
  JP Z,StopMusic
  CP $FE
  JP NZ,l_C226
  LD A,$01
  LD (StopAfterFade),A
  LD A,$FF
  LD (FadeStep),A
  LD A,$0A
  LD (FadeSpeed),A
  JP l_C22D
l_C226:
  DEC A
  LD (Tune),A
  JP Restart
l_C22D:
  CALL FadeFrame
  LD A,(Playing)
  AND A
  JR Z,l_C28F
  PUSH IX
  LD IX,ChannelRecords
  BIT 7,(IX+$0C)
  CALL Z,ChannelFrame
  LD IX,ChannelB
  BIT 7,(IX+$0C)
  CALL Z,ChannelFrame
  LD IX,ChannelC
  BIT 7,(IX+$0C)
  CALL Z,ChannelFrame
  LD A,(MasterVolume)
  CPL
  AND $0F
  LD B,A
  LD A,(HardwareEnvelope)
  AND A
  LD A,$10
  JP NZ,l_C271
  LD A,(AYRegisters+$0008)
  SUB B
  JP NC,l_C271
  XOR A
l_C271:
  LD (AYRegisters+$0008),A
  LD A,(AYRegisters+$0009)
  SUB B
  JP NC,l_C27C
  XOR A
l_C27C:
  LD (AYRegisters+$0009),A
  LD A,(AYRegisters+$000A)
  SUB B
  JP NC,l_C287
  XOR A
l_C287:
  LD (AYRegisters+$000A),A
  CALL WriteAY
  POP IX
l_C28F:
  RET

; One frame of the channel at IX: the next pattern item, the envelope, the
; arpeggio, the vibrato
;
; Used by the routine at Play.
ChannelFrame:
  LD A,(IX+$02)
  DEC (IX+$02)
  JP Z,ReadPattern
; This entry point is used by the routines at ReadPattern and ChannelStop.
l_C299:
  LD A,(IX+$0C)
  AND $03
  JP Z,Release
  CP $01
  JP Z,Attack
  CP $02
  JP Z,Decay
  CP $03
  JP Z,Sustain
  JP ChannelOutput
Attack:
  LD A,(IX+$0B)           ; Phase 1: the volume rises by the attack step every
                          ; attack delay frames up to the peak
  AND A
  JR Z,l_C2BF
  DEC (IX+$0B)
  JP ChannelOutput
l_C2BF:
  LD A,(IX+$04)
  LD B,(IX+$08)
  ADD A,B
  LD (IX+$04),A
  LD B,(IX+$05)
  CP B
  JR Z,l_C2E0
  JR NC,l_C2DA
  LD A,(IX+$07)
  LD (IX+$0B),A
  JP ChannelOutput
l_C2DA:
  LD A,(IX+$05)
  LD (IX+$04),A
l_C2E0:
  LD A,(IX+$0C)
  AND $FC
  OR $02
  LD (IX+$0C),A
  LD A,(IX+$09)
  LD (IX+$25),A
  JP ChannelOutput
Decay:
  LD A,(IX+$25)           ; Phase 2: the volume falls by the decay step down to
                          ; the sustain level
  AND A
  JR Z,l_C2FF
  DEC (IX+$25)
  JP ChannelOutput
l_C2FF:
  LD A,(IX+$04)
  LD B,(IX+$0A)
  ADD A,B
  LD (IX+$04),A
  BIT 7,A
  JP NZ,l_C31E
  LD B,(IX+$26)
  CP B
  JR Z,l_C32B
  JR C,l_C325
  LD A,(IX+$09)
  LD (IX+$25),A
  JR ChannelOutput
l_C31E:
  LD (IX+$04),$00
  JP l_C32B
l_C325:
  LD A,(IX+$26)
  LD (IX+$04),A
l_C32B:
  LD A,(IX+$0C)
  AND $FC
  OR $03
  LD (IX+$0C),A
  LD A,(IX+$06)
  LD (IX+$27),A
  JR ChannelOutput
Sustain:
  LD A,(IX+$27)           ; Phase 3: the volume holds for the sustain time
  AND A
  JR Z,l_C348
  DEC (IX+$27)
  JR ChannelOutput
l_C348:
  LD A,(IX+$0C)
  AND $FC
  LD (IX+$0C),A
  LD A,(IX+$2A)
  LD (IX+$29),A
  JP ChannelOutput
Release:
  LD A,(IX+$29)           ; Phase 0: the volume falls to 0
  AND A
  JR Z,l_C364
  DEC (IX+$29)
  JR ChannelOutput
l_C364:
  LD A,(IX+$04)
  LD B,(IX+$28)
  ADD A,B
  LD (IX+$04),A
  BIT 7,A
  JR NZ,l_C37A
  LD A,(IX+$2A)
  LD (IX+$29),A
  JR ChannelOutput
l_C37A:
  LD (IX+$04),$00
  LD A,(IX+$0C)
  AND $FC
  OR $03
  LD (IX+$0C),A
  JR ChannelOutput
ChannelOutput:
  LD A,(IX+$04)           ; The volume, the arpeggio's note offset (SetPeriod),
                          ; the vibrato on the period
  LD HL,AYRegisters
  LD D,$00
  LD E,(IX+$0F)
  ADD HL,DE
  LD (HL),A
  LD H,(IX+$14)
  LD L,(IX+$13)
  LD D,$00
  LD E,(IX+$10)
  ADD HL,DE
  LD A,(IX+$03)
  PUSH AF
  LD A,(HL)
  ADD A,(IX+$03)
  LD (IX+$03),A
  CALL SetPeriod
  POP AF
  LD (IX+$03),A
  INC (IX+$10)
  LD A,(IX+$12)
  XOR (IX+$10)
  JR NZ,l_C3C6
  LD A,(IX+$11)
  LD (IX+$10),A
l_C3C6:
  LD A,(IX+$1A)
  CP $FF
  JR Z,l_C416
  AND A
  JR Z,l_C3D5
  DEC (IX+$1A)
  JR NZ,l_C416
l_C3D5:
  DEC (IX+$1F)
  JR NZ,l_C3E8
  LD A,(IX+$1E)
  LD (IX+$1F),A
  LD A,(IX+$1C)
  XOR $01
  LD (IX+$1C),A
l_C3E8:
  BIT 0,(IX+$1C)
  LD B,(IX+$1B)
  LD A,(IX+$1D)
  JR Z,l_C3F7
  ADD A,B
  JR l_C3F8
l_C3F7:
  SUB B
l_C3F8:
  LD (IX+$1D),A
  LD C,A
  LD B,$FF
  BIT 7,A
  JR NZ,l_C404
  LD B,$00
l_C404:
  LD HL,AYRegisters
  LD D,$00
  LD E,(IX+$0D)
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD (HL),D
  DEC HL
  LD (HL),E
l_C416:
  LD A,(IX+$02)
  RET

; The channel's next pattern item: a note and its duration, or a command
;
; Used by the routines at ChannelFrame and NextPattern.
ReadPattern:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (IX+$10),$00
; This entry point is used by the routines at PatternEndUnused, PatternRepeat
; and PatternInstrument.
l_C424:
  LD A,(HL)
  CP $60
  JR Z,l_C497
  CP $61
  JP Z,PatternInstrument
  CP $64
  JP Z,PatternNoise
  CP $65
  JP Z,PatternShape
  CP $FC
  JP Z,FadeIn
  CP $FD
  JP Z,FadeOut
  CP $FE
  JP Z,PatternEnd
  CP $FF
  JP Z,PatternSilence
  LD B,A
  LD A,(IX+$0C)
  AND $FC
  OR $01
  LD (IX+$0C),A
  LD A,B
NoteOffset:
  SUB $0B                 ; SUB n: the note = the byte - n (sequence commands
                          ; $FA, $FB)
  LD (IX+$03),A
l_C45D:
  INC HL
  LD A,(HL)
  DEC A
  PUSH HL
  LD H,$00
  LD L,A
  LD DE,(DurationTable)
  ADD HL,DE
  LD A,(HL)
  POP HL
  INC HL
  LD (IX+$02),A
  LD A,(IX+$07)
  LD (IX+$0B),A
  LD (IX+$00),L
  LD (IX+$01),H
  CALL SetPeriod
  LD A,(IX+$19)
  LD (IX+$1A),A
  LD A,(IX+$1E)
  SRL A
  LD (IX+$1F),A
  LD (IX+$1C),$01
  LD (IX+$1D),$00
  JP l_C299
l_C497:
  JR l_C45D

; The period of the note (PeriodTable) into AYRegisters; channel C with the AY
; envelope: its period too
;
; Used by the routines at ChannelFrame and ReadPattern.
SetPeriod:
  LD A,(IX+$17)
  AND A
  CALL NZ,NoisePeriod
  LD A,(IX+$03)
  INC A
  INC A
  ADD A,A
  LD D,$00
  LD E,A
  LD HL,PeriodTable
  ADD HL,DE
  PUSH HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD HL,AYRegisters
  LD D,$00
  LD E,(IX+$0D)
  ADD HL,DE
  LD (HL),C
  INC HL
  LD (HL),B
  POP HL
  LD A,(HardwareEnvelope)
  AND A
  RET Z
  LD A,(IX+$0F)
  CP $08
  RET NZ
  LD DE,$00DA
  ADD HL,DE
  EX DE,HL
  LD H,$0B
  LD A,(DE)
  LD L,A
  CALL SetAYRegister
  INC DE
  INC H
  LD A,(DE)
  LD L,A
  CALL SetAYRegister
  RET

; The noise period from the note
;
; Used by the routine at SetPeriod.
NoisePeriod:
  LD A,(IX+$03)
  NEG
  AND $1F
  LD (AYRegisters+$0006),A
  RET

; $64 n: the noise period
;
; Used by the routine at ReadPattern.
PatternNoise:
  INC HL
  LD A,(HL)
  INC HL
  LD (AYRegisters+$0006),A
  JP l_C51C

; $FF: the volume 0
;
; Used by the routine at ReadPattern.
PatternSilence:
  INC HL
  LD (IX+$04),$00
  JP l_C51C

; $65 s: the AY envelope shape (register 13)
;
; Used by the routine at ReadPattern.
PatternShape:
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  LD H,$0D
  LD L,A
  CALL SetAYRegister
  POP HL
  JP l_C51C

; $FE: the pattern again until its repeats run out, then the next sequence item
;
; Used by the routine at ReadPattern.
PatternEnd:
  LD A,(IX+$22)
  DEC A
  LD (IX+$22),A
  JR NZ,PatternRepeat
  JP NextPattern

; JP to ReadPattern's loop; no code reaches it
PatternEndUnused:
  JP l_C424

; The pattern again from its start (+$15 / +$16)
;
; Used by the routine at PatternEnd.
PatternRepeat:
  LD L,(IX+$15)
  LD H,(IX+$16)
; This entry point is used by the routines at FadeIn, PatternNoise,
; PatternSilence and PatternShape.
l_C51C:
  LD (IX+$01),H
  LD (IX+$00),L
  JP l_C424

; $61 i: copy instrument i (35-byte records at Instruments) into the channel
;
; Used by the routine at ReadPattern.
PatternInstrument:
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  LD (IX+$00),L
  LD (IX+$01),H
  LD B,A
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Instruments
  ADD HL,DE
  LD D,$00
  ADD A,B
  LD E,A
  ADD HL,DE
  LD A,(HL)
  LD (IX+$07),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  INC HL
  LD A,(HL)
  LD (IX+$08),A
  INC HL
  LD A,(HL)
  LD (IX+$09),A
  INC HL
  LD A,(HL)
  LD (IX+$0A),A
  INC HL
  LD A,(HL)
  LD (IX+$26),A
  INC HL
  LD A,(HL)
  LD (IX+$06),A
  INC HL
  LD A,(HL)
  LD (IX+$2A),A
  INC HL
  LD A,(HL)
  LD (IX+$28),A
  INC HL
  LD A,(HL)
  LD (IX+$19),A
  INC HL
  LD A,(HL)
  LD (IX+$1B),A
  INC HL
  LD A,(HL)
  LD (IX+$1E),A
  INC HL
  LD A,(HL)
  LD (IX+$11),A
  INC HL
  LD A,(HL)
  LD (IX+$12),A
  INC HL
  LD (IX+$14),H
  LD (IX+$13),L
  LD (IX+$10),$00
  LD DE,$0010
  ADD HL,DE
  LD A,(HL)
  LD (IX+$17),$00
  AND A
  JP Z,l_C5B0
  LD B,A
  OR $C0
  LD (AYRegisters+$0007),A
  LD A,B
  BIT 7,A
  JP Z,l_C5B0
  CPL
  AND $38
  LD (IX+$17),A
l_C5B0:
  INC HL
  LD A,(IX+$0F)
  CP $08
  JP NZ,l_C5CC
  LD A,(HL)
  LD (HardwareEnvelope),A
  AND A
  JP Z,l_C5CC
  INC HL
  INC HL
  LD A,(HL)
  PUSH HL
  LD H,$0D
  LD L,A
  CALL SetAYRegister
  POP HL
l_C5CC:
  POP HL
  JP l_C424

; $FC n: DurationTable = the n-th 8-byte table
;
; Used by the routine at NextSequenceItem.
SequenceDurations:
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  ADD A,A
  ADD A,A
  ADD A,A
  LD H,$00
  LD L,A
  LD DE,DurationTables
  ADD HL,DE
  LD (DurationTable),HL
  POP HL
  JP l_C627

; $FB n: the note offset = n
;
; Used by the routine at NextSequenceItem.
SequenceOffset:
  INC HL
  LD A,(HL)
  INC HL
  LD (NoteOffset+$0001),A
  JP l_C627

; $FA n: the note offset += n
;
; Used by the routine at NextSequenceItem.
SequenceOffsetAdd:
  INC HL
  LD B,(HL)
  INC HL
  LD A,(NoteOffset+$0001)
  ADD A,B
  LD (NoteOffset+$0001),A
  JP l_C627

; Stop the channel (and the music when the next byte is not 0); no code reaches
; it
ChannelStop:
  LD (IX+$0C),$FF
  LD (IX+$03),$00
  LD (IX+$04),$00
  INC HL
  LD A,(HL)
  AND A
  JP Z,l_C299
  CALL StopMusic
  JP l_C299

; The repeats ran out: the next sequence item, then ReadPattern
;
; Used by the routine at PatternEnd.
NextPattern:
  CALL NextSequenceItem
  JP ReadPattern

; $FF: stop the music
;
; Used by the routine at NextSequenceItem.
SequenceStop:
  POP BC
  JP StopMusic

; $FD: the song again (Init)
;
; Used by the routine at NextSequenceItem.
SequenceRestart:
  POP BC
  JP Init

; Read the sequence: commands, then a pattern number (PatternTable) and its
; repeat count
;
; Used by the routines at ChannelStart and NextPattern.
NextSequenceItem:
  LD L,(IX+$20)
  LD H,(IX+$21)
; This entry point is used by the routines at SequenceDurations, SequenceOffset
; and SequenceOffsetAdd.
l_C627:
  LD A,(HL)
  CP $FA
  JP Z,SequenceOffsetAdd
  CP $FB
  JP Z,SequenceOffset
  CP $FC
  JP Z,SequenceDurations
  CP $FD
  JP Z,SequenceRestart
  CP $FE
  JR Z,SequenceLoop
  CP $FF
  JR Z,SequenceStop
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,PatternTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$00),E
  LD (IX+$01),D
  LD (IX+$15),E
  LD (IX+$16),D
  POP HL
  INC HL
  LD A,(HL)
  LD (IX+$22),A
  INC HL
  LD (IX+$20),L
  LD (IX+$21),H
  RET
SequenceLoop:
  LD L,(IX+$23)           ; $FE: the sequence again from its start
  LD H,(IX+$24)
  JR l_C627

; Bytes no code reads
Spare4:
  DEFB $00,$00,$00,$00

; The AY tone period of notes -2 up (SetPeriod indexes it by the note + 2)
PeriodTable:
  DEFW $0000,$0FBF,$0EDC,$0E07,$0D3D,$0C7F,$0BCC,$0B22
  DEFW $0A82,$09EB,$095D,$08D6,$0857,$07DF,$076E,$0703
  DEFW $069F,$0640,$05E6,$0591,$0541,$04F6,$04AE,$046B
  DEFW $042C,$03F0,$03B7,$0382,$034F,$0320,$02F3,$02C8
  DEFW $02A1,$027B,$0257,$0236,$0216,$01F8,$01DC,$01C1
  DEFW $01A8,$0190,$0179,$0164,$0150,$013D,$012C,$011B
  DEFW $010B,$00FC,$00EE,$00E0,$00D4,$00C8,$00BD,$00B2
  DEFW $00A8,$009F,$0096,$008D,$0085,$007E,$0077,$0070
  DEFW $006A,$0064,$005E,$0059,$0054,$004F,$004B,$0047
  DEFW $0043,$003F,$003B,$0038,$0035,$0032,$002F,$002D
  DEFW $002A,$0028,$0025,$0023,$0021,$001F,$001E,$001C
  DEFW $001A,$0019,$0018,$0016,$0015,$0014,$0013,$0012
  DEFW $0011,$0010,$000F,$000E,$000D,$000C,$000C,$000B
  DEFW $000B,$000A,$0009,$0009,$0008

; The AY envelope period of each note (PeriodTable + $DA), for channel C's
; hardware envelope
EnvelopePeriods:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $006A,$0064,$005E,$005A,$0054,$004F,$004A,$0047
  DEFW $0043,$003F,$003B,$0038,$0035,$0032,$002F,$002D
  DEFW $002A,$0028,$0025,$0023,$0021,$0020,$001E,$001C
  DEFW $001B,$0019,$0018,$0016,$0015,$0014,$0013,$0012
  DEFW $0011,$0010,$000F,$000E,$000D,$000C,$000B,$000A
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
