; --------------------------------------------------------------------------------------------------------------------
; stc-module.asm: The Sound Tracker player: init, play, the pattern reader, the samples and ornaments, the AY write
;
; Two entry points: MusicInit (the first byte, LD HL,Module and JP Init) reads the STC module's header into the
; player's variables, clears the channel records and silences the AY; MusicPlay (the JP at +6) plays one frame: on a
; row frame (Delay frames a row) each channel whose row counter ran out reads its pattern stream (ReadPattern), then
; for each channel one sample row (SampleRow) and one ornament step, the tone period from PeriodTable, the volume, the
; noise and the mixer into AYRegisters, last WriteAY.
;
; The module (STC): the delay, three offsets (positions, ornaments, patterns), the 18-byte identifier "SONG BY ST
; COMPILE", the size, then the samples (99 bytes each: 32 rows of 3 bytes and a loop pair), the positions (pattern and
; transposition pairs), the ornaments (33 bytes each), the pattern table (7 bytes each: number, three stream offsets)
; and the streams; the format is in src/res/music/README.md.
; --------------------------------------------------------------------------------------------------------------------

; Set the player up for the module at Module: LD HL,Module, then JP Init
MusicInit:
  LD HL,Module

; JP Init
InitJump:
  JP Init

; Play one frame (JP Play)
MusicPlay:
  JP Play

; Read the module's header, clear the channels, silence the AY
;
; Delay = byte 0; ModuleBase = HL (the self-modified operand of AddModuleBase);
; the three table pointers from the header's offsets plus the module's address;
; the positions' count + 1; clears the 45 bytes of the channel records; finds
; sample 0 (99-byte records) for the three channels; then WriteAY.
Init:
  DI
  LD A,(HL)
  LD (Delay),A
  LD (AddModuleBase+$0001),HL
  INC HL
  CALL ReadOffset
  LD A,(DE)
  INC DE
  INC A
  LD (PositionCount),A
  LD (PlayerVariables),DE
  CALL ReadOffset
  LD (PlayerVariables+$0002),DE
  PUSH DE
  CALL ReadOffset
  LD (PlayerVariables+$0004),DE
  LD HL,$001B
  CALL AddModuleBase
  EX DE,HL
  LD (PlayerVariables+$0006),HL
  LD HL,StreamC+$0002
  LD (StreamA),HL
  LD HL,ChannelRecords
  LD DE,ChannelRecords+$0001
  LD BC,$002C
  LD (HL),B
  LDIR
  POP HL
  LD BC,$0021
  XOR A
  CALL FindRecord
  DEC A
  LD (ChannelA+$0007),A
  LD (ChannelB+$0007),A
  LD (ChannelC+$0007),A
  LD A,$01
  LD (DelayCounter),A
  INC HL
  LD (ChannelA+$0005),HL
  LD (ChannelB+$0005),HL
  LD (ChannelC+$0005),HL
  CALL WriteAY
  DI
  RET

; The player's variables: the module's tables, the delay and its counter, the
; stream pointers
;
; +0 the positions' address, +2 the ornaments', +4 the patterns', +6 the
; samples', +8 Delay, +9 DelayCounter, +10 the positions' count + 1, +11, +13,
; +15 the three stream pointers, +17 $FF. Written by Init and Play: the bytes
; on a disk are what they held when it was saved.
PlayerVariables:
  DEFB $77,$F1,$8F,$F1,$13,$F2,$5E,$EE
Delay:
  DEFB $06
DelayCounter:
  DEFB $01
PositionCount:
  DEFB $0C
StreamA:
  DEFB $88,$F4
StreamB:
  DEFB $5C,$F5
StreamC:
  DEFB $A2,$F5,$FF

; The three channels' records (10 bytes each, IX = +2), then AYRegisters
;
; IX+$00 the sample row, +$01 the note, +$02 the row counter, +$03 / +$04 the
; sample's address, +$05 / +$06 the ornament's, +$07 the rows left of the
; sample, IX-$01 the row length, IX-$02 the envelope state.
ChannelRecords:
  DEFB $00,$00
ChannelA:
  DEFB $01,$00,$00,$C2,$EE,$90,$F1,$1F
  DEFB $02,$01
ChannelB:
  DEFB $07,$1D,$00,$4E,$F0,$90,$F1,$19
  DEFB $00,$00
ChannelC:
  DEFB $01,$2E,$00,$B1,$F0,$D2,$F1,$1F
PositionIndex:
  DEFB $06

; The image of AY registers 0-13 that WriteAY sends
AYRegisters:
  DEFB $F8,$0E,$CA,$02,$0B,$01
AYNoise:
  DEFB $07
AYMixer:
  DEFB $31,$0F,$19,$09
AYEnvelopePeriod:
  DEFB $B3,$00
AYEnvelopeShape:
  DEFB $00

; HL = the first record from HL whose first byte is A (records of BC bytes)
;
; Used by the routines at Init, NextPosition and ReadPattern.
FindRecord:
  CP (HL)
  RET Z
  ADD HL,BC
  JP FindRecord

; DE = the word at (HL) plus ModuleBase, HL + 2
;
; Used by the routines at Init and NextPosition.
ReadOffset:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL

; HL += ModuleBase (the operand of LD BC,nn: written by Init), result in DE
;
; Used by the routine at Init.
AddModuleBase:
  LD BC,$EE43
  ADD HL,BC
  EX DE,HL
  RET

; One row of a sample: A = the row; out B, C the mixer bits, D the noise and
; volume, E, HL the tone delta
;
; Used by the routine at ChannelSounds.
SampleRow:
  LD D,$00
  LD E,A
  ADD A,A
  ADD A,E
  LD E,A
  ADD IX,DE
  LD A,(IX+$01)
  BIT 7,A
  LD C,$10
  JP NZ,l_C14B
  LD C,D
l_C14B:
  BIT 6,A
  LD B,$02
  JP NZ,l_C153
  LD B,D
l_C153:
  AND $1F
  LD H,A
  LD E,(IX+$02)
  LD A,(IX+$00)
  PUSH AF
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  LD D,A
  POP AF
  AND $0F
  LD L,A
  BIT 5,(IX+$01)
  RET Z
  SET 4,D
  RET

; Start the next position: its transposition and the three streams of its
; pattern
;
; Used by the routine at Play.
NextPosition:
  LD A,(PositionIndex)
  LD C,A
  LD HL,PositionCount
  CP (HL)
  JP C,l_C17D
  XOR A
  LD C,A
l_C17D:
  INC A
  LD (PositionIndex),A
  LD L,C
  LD H,$00
  ADD HL,HL
  LD DE,(PlayerVariables)
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD (TonePeriod+$0012),A
  LD A,C
  LD HL,(PlayerVariables+$0004)
  LD BC,$0007
  CALL FindRecord
  INC HL
  CALL ReadOffset
  LD (StreamA),DE
  CALL ReadOffset
  LD (StreamB),DE
  CALL ReadOffset
  LD (StreamC),DE
  RET

; Count down a channel's row counter; on 0 reload it from the row length
;
; Used by the routine at Play.
CountRow:
  DEC (IX+$02)
  RET P
  LD A,(IX-$01)
  LD (IX+$02),A
  RET

; Play one frame: on a row frame the three streams, then the sound of each
; channel and WriteAY
;
; Used by the routine at MusicPlay.
Play:
  LD A,(DelayCounter)
  DEC A
  LD (DelayCounter),A
  JP NZ,ChannelSounds
  LD A,(Delay)
  LD (DelayCounter),A
  LD IX,ChannelA
  CALL CountRow
  JP P,l_C1E7
  LD HL,(StreamA)
  LD A,(HL)
  INC A
  CALL Z,NextPosition
  LD HL,(StreamA)
  CALL ReadPattern
  LD (StreamA),HL
l_C1E7:
  LD IX,ChannelB
  CALL CountRow
  JP P,l_C1FA
  LD HL,(StreamB)
  CALL ReadPattern
  LD (StreamB),HL
l_C1FA:
  LD IX,ChannelC
  CALL CountRow
  JP P,ChannelSounds
  LD HL,(StreamC)
  CALL ReadPattern
  LD (StreamC),HL
  JP ChannelSounds

; Read a channel's stream to its next note, rest or release: note, sample,
; ornament, envelope, row length
;
; Used by the routine at Play.
ReadPattern:
  LD A,(HL)
  CP $60
  JP C,l_C23E
  CP $70
  JP C,l_C24B
  CP $80
  JP C,l_C26C
  JP Z,l_C263
  CP $81
  JP Z,l_C249
  CP $82
  JP Z,l_C269
  CP $8F
  JP C,l_C288
  SUB $A1
  LD (IX+$02),A
  LD (IX-$01),A
  INC HL
  JP ReadPattern
l_C23E:
  LD (IX+$01),A
  LD (IX+$00),$00
  LD (IX+$07),$20
l_C249:
  INC HL
  RET
l_C24B:
  SUB $60
  PUSH HL
  LD BC,$0063
  LD HL,(PlayerVariables+$0006)
  CALL FindRecord
  INC HL
  LD (IX+$03),L
  LD (IX+$04),H
  POP HL
  INC HL
  JP ReadPattern
l_C263:
  INC HL
; This entry point is used by the routine at SampleStep.
l_C264:
  LD (IX+$07),$FF
  RET
l_C269:
  XOR A
  JR l_C26E
l_C26C:
  SUB $70
l_C26E:
  PUSH HL
  LD BC,$0021
  LD HL,(PlayerVariables+$0002)
  CALL FindRecord
  INC HL
  LD (IX+$05),L
  LD (IX+$06),H
  LD (IX-$02),$00
  POP HL
  INC HL
  JP ReadPattern
l_C288:
  SUB $80
  LD (AYEnvelopeShape),A
  INC HL
  LD A,(HL)
  INC HL
  LD (AYEnvelopePeriod),A
  LD (IX-$02),$01
  PUSH HL
  XOR A
  LD BC,$0021
  LD HL,(PlayerVariables+$0002)
  CALL FindRecord
  INC HL
  LD (IX+$05),L
  LD (IX+$06),H
  POP HL
  JP ReadPattern

; Step a channel's sample: the next row, its loop
;
; Used by the routine at ChannelSounds.
SampleStep:
  LD A,(IX+$07)
  INC A
  RET Z
  DEC A
  DEC A
  LD (IX+$07),A
  PUSH AF
  LD A,(IX+$00)
  LD C,A
  INC A
  AND $1F
  LD (IX+$00),A
  POP AF
  RET NZ
  LD E,(IX+$03)
  LD D,(IX+$04)
  LD HL,$0060
  ADD HL,DE
  LD A,(HL)
  DEC A
  JP M,l_C264
  LD C,A
  INC A
  AND $1F
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  INC A
  LD (IX+$07),A
  RET

; The channel's noise period into AYNoise when its sample row has noise
;
; Used by the routine at ChannelSounds.
NoiseFromSample:
  LD A,C
  OR A
  RET NZ
  LD A,H
  LD (AYNoise),A
  RET

; The envelope bit of a channel's volume
;
; Used by the routine at ChannelSounds.
EnvelopeStep:
  LD A,(IX+$07)
  INC A
  RET Z
  LD A,(IX-$02)
  OR A
  RET Z
  CP $02
  JP Z,l_C2FF
  LD (IX-$02),$02
  JP l_C303
l_C2FF:
  XOR A
  LD (AYEnvelopeShape),A
l_C303:
  SET 4,(HL)
  RET

; The three channels' sound: sample rows, ornament notes, periods, volumes,
; mixer
;
; Used by the routine at Play.
ChannelSounds:
  LD IX,ChannelA
  CALL SampleStep
  LD A,C
  LD (TonePeriod+$000A),A
  LD IX,(ChannelA+$0003)
  CALL SampleRow
  LD A,C
  OR B
  RRCA
  LD (AYMixer),A
  LD IX,ChannelA
  LD A,(IX+$07)
  INC A
  JP Z,l_C332
  CALL NoiseFromSample
  CALL TonePeriod
  LD (AYRegisters),HL
l_C332:
  LD HL,AYMixer+$0001
  LD (HL),A
  CALL EnvelopeStep
  LD IX,ChannelB
  CALL SampleStep
  LD A,(IX+$07)
  INC A
  JP Z,l_C367
  LD A,C
  LD (TonePeriod+$000A),A
  LD IX,(ChannelB+$0003)
  CALL SampleRow
  LD A,(AYMixer)
  OR C
  OR B
  LD (AYMixer),A
  CALL NoiseFromSample
  LD IX,ChannelB
  CALL TonePeriod
  LD (AYRegisters+$0002),HL
l_C367:
  LD HL,AYMixer+$0002
  LD (HL),A
  CALL EnvelopeStep
  LD IX,ChannelC
  CALL SampleStep
  LD A,(IX+$07)
  INC A
  JP Z,l_C3A0
  LD A,C
  LD (TonePeriod+$000A),A
  LD IX,(ChannelC+$0003)
  CALL SampleRow
  LD A,(AYMixer)
  RLC C
  RLC B
  OR B
  OR C
  LD (AYMixer),A
  CALL NoiseFromSample
  LD IX,ChannelC
  CALL TonePeriod
  LD (AYRegisters+$0004),HL
l_C3A0:
  LD HL,AYMixer+$0003
  LD (HL),A
  CALL EnvelopeStep
  JP WriteAY

; HL = PeriodTable[note + the ornament's offset + the transposition] -/+ the
; sample's tone delta
;
; Used by the routine at ChannelSounds.
TonePeriod:
  LD A,L
  PUSH AF
  PUSH DE
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD DE,$0000
  ADD HL,DE
  LD A,(IX+$01)
  ADD A,(HL)
  ADD A,$00
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,PeriodTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  POP DE
  POP AF
  BIT 4,D
  JR Z,l_C3D3
  RES 4,D
  ADD HL,DE
  RET
l_C3D3:
  AND A
  SBC HL,DE
  RET

; The AY tone period of each of the 96 notes
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

; Write AYRegisters to the AY: registers 13 (when a shape is set) or 12 down to
; 0
;
; Used by the routines at Init and ChannelSounds.
WriteAY:
  LD HL,AYEnvelopeShape
  XOR A
  OR (HL)
  LD A,$0D
  JR NZ,l_C4A5
  SUB $03
  DEC HL
  DEC HL
  DEC HL
l_C4A5:
  LD C,$FD
l_C4A7:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,l_C4A7
  RET
