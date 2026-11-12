; --------------------------------------------------------------------------------------------------------------------
; hydrofool-module.asm: The Hydrofool game player: three channels, each an order list of patterns; per frame the volume envelope, the arpeggio, vibrato and slides
;
; Entries: MusicInit $F424 (JP Init: the song in A), MusicPlay $F427 (JP Play, once a frame), MusicStop $F42A (JP
; Stop), MusicStart $F42D (song 0).
;
; A song: three words at $F93A + 6 * song, the order lists of channels A, B and C. An order list: pattern addresses, a
; word 0 starts it again. A pattern: $00-$7F a note (ends the row), $80-$91 commands through CommandOffsets ($80 rest,
; $87 the next pattern, $8E stop, $84 and $88 two argument bytes, $89 one), $B8-$BF the tempo, $C0-$CF the arpeggio
; (from the table at $F8F1), $D0-$DF the volume envelope with three argument bytes, $E0-$FF the note length.
; --------------------------------------------------------------------------------------------------------------------

; JP Init
MusicInit:
  JP Init

; JP Play
MusicPlay:
  JP Play

; JP Stop
MusicStop:
  JP Stop

; Song 0: LD A,0, then Init
MusicStart:
  LD A,$00
  JP Init

; Clear Playing and silence the AY
;
; Used by the routine at MusicStop.
Stop:
  XOR A
  LD ($F939),A
  JP Silence

; Start song A: each channel's order list from the song table, its first
; pattern, the counters; then set Playing
;
; Used by the routines at MusicInit and MusicStart.
Init:
  PUSH AF
  XOR A
  LD ($F939),A
  POP AF
  LD C,A
  ADD A,A
  ADD A,C
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,$F93A
  ADD HL,BC
  LD IX,ChannelA
  LD C,$21
  XOR A
  LD (l_F764+$0001),A
  LD A,$03
l_F456:
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
  JR NZ,l_F456
  INC A
  LD (TempoCounter),A
  LD ($F939),A
  RET

; Channel A's record, 33 bytes: +0 flags, +1 the stream, +3 the order list, +5
; its index, +7 the slide, +9 the arpeggio, +$0B its row, +$0D the slide step,
; +$10 the row counter, +$11 the length, +$12 the note, +$13 the volume, +$14
; the envelope, +$19 the envelope's volume, +$1A the vibrato, +$1D its mode,
; +$1F the noise flag, +$20 the mixer mask
ChannelA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $09

; Channel B's record
ChannelB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $12

; Channel C's record
ChannelC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $24

; Frames left to the next row
TempoCounter:
  DEFB $00

; One frame: on a row frame (the tempo counter runs out) each channel's row;
; every frame each channel's sound into AYRegs; then write AYRegs to the AY
;
; Used by the routine at MusicPlay.
Play:
  LD A,($F939)
  AND A
  RET Z
  LD A,$00
  LD (FrameSound+$0028),A
  LD HL,TempoCounter
  DEC (HL)
  JR NZ,FrameSound
  LD B,(HL)
  LD IX,ChannelA
  CALL ChannelRow
  LD IX,ChannelB
  CALL ChannelRow
  LD IX,ChannelC
  CALL ChannelRow
  LD HL,TempoCounter
  LD (HL),$01
FrameSound:
  LD IX,ChannelA          ; Each channel's sound: the period into AYRegs, the
                          ; volume
  CALL ChannelSound
  LD (AYRegs),HL
  LD (AYRegs+$0008),A
  LD IX,ChannelB
  CALL ChannelSound
  LD (AYRegs+$0002),HL
  LD (AYRegs+$0009),A
  LD IX,ChannelC
  CALL ChannelSound
  LD (AYRegs+$0004),HL
  LD (AYRegs+$000A),A
  LD A,$00
  LD (AYRegs+$0006),A
WriteAY:
  LD HL,AYRegs+$000D      ; AY registers 13 down to 0 from AYRegs
  LD A,$0D
  LD C,$FD
l_F54C:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,l_F54C
  RET

; AY register D = E
WriteRegister:
  LD BC,$FFFD
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; All AY registers 0, the mixer to $3F
;
; Used by the routines at Stop and CommandStop.
Silence:
  LD C,$FD
  LD DE,$0D00
  SUB A
l_F569:
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),A
  DEC D
  JP P,l_F569
  LD DE,$073F
  LD B,$FF
  OUT (C),D
  LD B,$BF
  OUT (C),E
  RET

; Jump offsets of commands $80-$91 (target = the entry's address + its byte)
CommandOffsets:
  DEFB $CD,$B5,$B9,$BE,$7C,$AB,$A6,$13,$95,$8D,$52,$3C,$64,$BA,$04,$C1,$C6,$CB

; $8E: clear Playing, leave the frame and silence
CommandStop:
  XOR A
  LD ($F939),A
  POP HL
  JP Silence

; $87: the next pattern of the order list (a word 0: the list from its start)
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
  JR NZ,l_F5BD
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD BC,$0002
  LD E,(HL)
  INC HL
  LD D,(HL)
l_F5BD:
  LD (IX+$05),C
  LD (IX+$06),B
  LD B,$00
  JP ReadItem

; CommandNoise
CommandNoise:
  DEFB $DD,$7E,$20,$4F,$E6,$07,$21,$20 ; $8B: the channel's noise on (its tone
  DEFB $F8,$AE,$A1,$AE,$77,$3E,$01,$DD ; mask from the mixer)
  DEFB $77,$1E,$C3,$75,$F6
CommandTone:
  DEFB $DD,$7E,$20,$4F,$E6,$38,$21,$20 ; $8A: the channel's tone on
  DEFB $F8,$AE,$A1,$AE,$77,$AF,$DD,$77
  DEFB $1E,$C3,$75,$F6
CommandBoth:
  DEFB $21,$20,$F8,$DD,$7E,$20,$2F,$A6 ; $8C: tone and noise on
  DEFB $77,$3E,$01,$DD,$77,$1E,$18,$74
CommandSlide:
  DEFB $1A,$13,$DD,$70,$07,$DD,$70,$08 ; $84 step count: a slide of the period
  DEFB $DD,$77,$0D,$DD,$CB,$00,$D6,$1A
  DEFB $DD,$77,$0E,$13,$18,$5E
CommandTranspose:
  DEFB $1A,$13,$32,$65,$F7,$18,$57 ; $89 n: the transposition of every channel
CommandSweep:
  DEFB $1A,$DD,$77,$1B,$13,$1A,$DD,$77 ; $88 step size: the vibrato
  DEFB $1A,$13,$DD,$77,$1C,$18,$48
CommandBendDown:
  DEFB $DD,$CB,$00,$FE    ; $86: bend down
CommandBendUp:
  DEFB $DD,$CB,$00,$DE,$18,$3E ; $85: bend up
CommandSweepOff:
  DEFB $DD,$70,$1D,$18,$39 ; $81: the vibrato off
CommandSweepUp:
  DEFB $DD,$36,$1D,$40,$18,$33 ; $82: vibrato mode $40
CommandSweepDown:
  DEFB $DD,$36,$1D,$C0,$18,$2D ; $83: vibrato mode $C0
CommandFlag:
  DEFB $DD,$CB,$00,$CE,$18,$27 ; $8D: flag bit 1
CommandRest:
  DEFB $DD,$70,$13        ; $80: volume 0 for the row
CommandHold:
  DEFB $DD,$CB,$00,$AE,$18,$54 ; $8F: the row without a new note
CommandLock:
  DEFB $DD,$CB,$00,$E6,$18,$18 ; $90: the next notes keep the envelope
CommandUnlock:
  DEFB $DD,$CB,$1F,$C6,$18,$12 ; $91: the noise flag

; A channel's row: count its row counter down, at 0 read the pattern's items up
; to a note, a rest or a hold
;
; Used by the routine at Play.
ChannelRow:
  DEC (IX+$10)
  JR NZ,l_F6B8
  LD (IX+$00),B
  RES 0,(IX+$1F)
  LD E,(IX+$01)
  LD D,(IX+$02)
; This entry point is used by the routine at CommandEnd.
ReadItem:
  LD A,(DE)               ; The next item of the stream
  INC DE
  AND A
  JP M,ItemRange
  LD (IX+$12),A
  BIT 0,(IX+$1E)
  JR Z,l_F687
  LD (Play+$0006),A
l_F687:
  BIT 4,(IX+$00)
  JR NZ,l_F6AB
  LD A,(IX+$19)
  LD (IX+$13),A
  SET 5,(IX+$00)
  SET 6,(IX+$00)
  RES 4,(IX+$00)
  LD A,(IX+$14)
  LD (IX+$16),A
  LD A,(IX+$17)
  LD (IX+$18),A
l_F6AB:
  LD A,(IX+$11)
  LD (IX+$10),A
  LD (IX+$02),D
  LD (IX+$01),E
  RET
l_F6B8:
  LD A,(IX+$00)
  BIT 3,A
  RET Z
  RLA
  JR NC,l_F6C5
  INC (IX+$12)
  RET
l_F6C5:
  DEC (IX+$12)
  RET
ItemRange:
  CP $B8                  ; $80-$B7 through CommandOffsets; $B8-$BF tempo,
                          ; $C0-$CF arpeggio, $D0-$DF envelope, $E0-$FF length
  JR C,l_F711
  ADD A,$20
  JR C,l_F6F5
  ADD A,$10
  JR C,l_F6FC
  ADD A,$10
  JR NC,l_F6EE
  LD C,A
  LD HL,$F8F1
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  LD (IX+$0B),L
  LD (IX+$09),L
  LD (IX+$0C),H
  LD (IX+$0A),H
  JR ReadItem
l_F6EE:
  ADD A,$09
  LD (Play+$002A),A
  JR ReadItem
l_F6F5:
  INC A
  LD (IX+$11),A
  JP ReadItem
l_F6FC:
  LD (IX+$19),A
  LD A,(DE)
  INC DE
  LD (IX+$14),A
  LD A,(DE)
  INC DE
  LD (IX+$15),A
  LD A,(DE)
  INC DE
  LD (IX+$17),A
  JP ReadItem
l_F711:
  LD HL,Play+$0013
  LD C,A
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  JP (HL)

; A channel's frame: the volume envelope, the arpeggio row, the note's period
; with vibrato and slide, the mixer bits; HL = the period, A = the volume
;
; Used by the routine at Play.
ChannelSound:
  LD C,(IX+$00)
  BIT 5,C
  JR Z,l_F764
  LD A,(IX+$16)
  SUB $10
  JR NC,l_F74C
  BIT 6,C
  JR Z,l_F751
  ADD A,(IX+$13)
  JR NC,l_F731
  SBC A,A
l_F731:
  ADD A,$10
  LD (IX+$13),A
  LD A,(IX+$18)
  SUB $10
  JR NC,l_F747
  RES 6,C
  LD A,(IX+$15)
  LD (IX+$16),A
  JR l_F764
l_F747:
  LD (IX+$18),A
  JR l_F764
l_F74C:
  LD (IX+$16),A
  JR l_F764
l_F751:
  CPL
  SUB $0F
  ADD A,(IX+$13)
  JR C,l_F75A
  SUB A
l_F75A:
  LD (IX+$13),A
  DEC (IX+$18)
  JR NZ,l_F764
  RES 5,C
l_F764:
  LD A,$00
  ADD A,(IX+$12)
  LD B,A
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  LD A,(HL)
  CP $87
  JR C,l_F77C
  LD L,(IX+$09)
  LD H,(IX+$0A)
  LD A,(HL)
l_F77C:
  INC HL
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
  JR Z,l_F7DE
  LD H,A
  LD B,(IX+$1A)
  SLA B
  BIT 7,L
  LD A,(IX+$1C)
  JR Z,l_F7A7
  BIT 0,C
  JR NZ,l_F7C5
l_F7A7:
  BIT 5,L
  JR NZ,l_F7B7
  SUB (IX+$1B)
  JR NC,l_F7C2
  SET 5,(IX+$1D)
  SUB A
  JR l_F7C2
l_F7B7:
  ADD A,(IX+$1B)
  CP B
  JR C,l_F7C2
  RES 5,(IX+$1D)
  LD A,B
l_F7C2:
  LD (IX+$1C),A
l_F7C5:
  EX DE,HL
  SRL B
  SUB B
  LD E,A
  LD A,D
  LD D,$00
  JR NC,l_F7D0
  DEC D
l_F7D0:
  ADD A,$A0
  JR C,l_F7DC
l_F7D4:
  SLA E
  RL D
  ADD A,$18
  JR NC,l_F7D4
l_F7DC:
  ADD HL,DE
  EX DE,HL
l_F7DE:
  LD A,C
  XOR $01
  LD (IX+$00),A
  BIT 2,C
  JR Z,l_F809
  LD B,(IX+$0E)
  DJNZ l_F806
  LD C,(IX+$0D)
  BIT 7,C
  JR Z,l_F7F5
  DEC B
l_F7F5:
  LD L,(IX+$07)
  LD H,(IX+$08)
  ADD HL,BC
  LD (IX+$07),L
  LD (IX+$08),H
  ADD HL,DE
  EX DE,HL
  JR l_F809
l_F806:
  LD (IX+$0E),B
l_F809:
  BIT 0,(IX+$1F)
  JR Z,l_F81C
  RES 0,(IX+$1F)
  LD A,$00
  LD (FrameSound+$0028),A
  LD A,$07
  JR l_F82D
l_F81C:
  CPL
  AND $03
  LD A,$38
  JR NZ,l_F82D
  LD A,(Play+$0006)
  XOR $08
  LD (FrameSound+$0028),A
  LD A,$07
l_F82D:
  LD HL,AYRegs+$0007
  XOR (HL)
  AND (IX+$20)
  XOR (HL)
  LD (HL),A
  EX DE,HL
  LD A,(IX+$13)
  RET

; The AY register image: three tone periods, the noise, the mixer, three
; volumes, the envelope
AYRegs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$3F,$0F,$0F,$0F,$00,$00,$00

; The AY tone period of each note 0-$53 (84 notes)
PeriodTable:
  DEFW $0EF8,$0E10,$0D60,$0C80,$0BD8,$0B28,$0A88,$09F0,$0960,$08E0,$0858,$07E0
  DEFW $077C,$0708,$06B0,$0640,$05EC,$0594,$0544,$04F8,$04B0,$0470,$042C,$03F0
  DEFW $03BE,$0384,$0358,$0320,$02F6,$02CA,$02A2,$027C,$0258,$0238,$0216,$01F8
  DEFW $01DF,$01C2,$01AC,$0190,$017B,$0165,$0151,$013E,$012C,$011C,$010B,$00FC
  DEFW $00EF,$00E1,$00D6,$00C8,$00BD,$00B2,$00A8,$009F,$0096,$008E,$0085,$007E
  DEFW $0077,$0070,$006B,$0064,$005E,$0059,$0054,$004F,$004B,$0047,$0042,$003F
  DEFW $003B,$0038,$0035,$0032,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F
