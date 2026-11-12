; --------------------------------------------------------------------------------------------------------------------
; ziutek-module.asm: The Part V player: positions of patterns, three pattern streams, samples of 32 rows and ornaments of 32 notes
;
; Entry: MusicPlay $C780 (once a frame; there is no init). Every 5th frame a row: each channel's next items; every
; frame each channel's sample and ornament row, then the AY registers. On the other frames delay loops keep the
; frame's length even.
;
; The positions ($CCFF): 28 pairs (pattern number from 1, transposition); a pattern ($CD37 + 6 * (number - 1)): the
; streams of channels A, B and C. A stream: $00-$0D the next position, $0E-$1D the envelope shape with its period
; byte, $1E-$34 off, $35-$44 the ornament, $45-$84 the row length, $85-$8E the row without a new note, $8F-$EE a note,
; $EF-$FE the sample (ranges from ItemRanges).
; --------------------------------------------------------------------------------------------------------------------

; One frame: count the frame counter down (the LD operand at $C781; 5 frames a
; row), on a row frame each channel's row, then the sound
MusicPlay:
  LD A,$01
  DEC A
  JR NZ,l_C787
  LD A,$05
l_C787:
  LD (MusicPlay+$0001),A
  JR NZ,IdleFrame
  LD IX,ChannelA
  CALL ChannelRow
  LD IX,ChannelB
  CALL ChannelRow
  LD IX,ChannelC
  CALL ChannelRow
SoundFrame:
  LD IX,ChannelA          ; Each channel's sound into AYRegs, the mixer from
                          ; their tone and noise bits
  CALL ChannelSound
  LD (AYRegs),HL
  LD (AYRegs+$0008),A
  PUSH BC
  LD IX,ChannelB
  CALL ChannelSound
  LD (AYRegs+$0002),HL
  LD (AYRegs+$0009),A
  PUSH BC
  LD IX,ChannelC
  CALL ChannelSound
  LD (AYRegs+$0004),HL
  LD (AYRegs+$000A),A
  LD A,B
  POP BC
  RLCA
  OR B
  POP BC
  RLCA
  OR B
  LD (AYRegs+$0007),A
WriteAY:
  LD HL,AYRegs+$000D      ; AY registers 12 down to 0 from AYRegs (13 only when
                          ; the shape changed)
  LD A,$0D
  LD BC,$FFFD
  OUT (C),A
  IN A,(C)
  CP (HL)
  LD A,(HL)
  DEC HL
  JR Z,l_C7E9
  LD B,$BF
  OUT (C),A
l_C7E9:
  LD A,$0C
l_C7EB:
  LD B,$FF
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  RET M
  JR l_C7EB
IdleFrame:
  CALL Delay              ; Not a row frame: three delay loops in place of the
                          ; rows
  CALL Delay
  CALL Delay
  JR SoundFrame

; NextPosition
NextPosition:
  DEFB $3E,$01,$FE,$1C,$20,$07,$3E,$00 ; The next position (the LD operand at
  DEFB $B7,$28,$02,$F1,$C9,$3C,$32,$03 ; $C803; after $1C, position 1): its
  DEFB $C8,$3D,$87,$06,$00,$4F,$21,$FF ; pattern's three streams and the
  DEFB $CC,$09,$4E,$23,$7E,$32,$6A,$C9 ; transposition
  DEFB $0D,$C5,$E1,$29,$09,$29,$01,$37
  DEFB $CD,$09,$5E,$23,$56,$23,$ED,$53
  DEFB $9A,$C9,$4E,$23,$46,$23,$ED,$43
  DEFB $A6,$C9,$4E,$23,$46,$ED,$43,$B2
  DEFB $C9,$18,$1C

; The stream item ranges: pairs (first byte above the range, the handler's JR
; offset at $C878)
ItemRanges:
  DEFB $0E,$89,$1E,$2C,$35,$40,$45,$14,$85,$3B,$8F,$51,$EF,$46,$FF,$00

; A channel's row: count its row counter down, at 0 read items up to a note,
; off or a hold
;
; Used by the routine at MusicPlay.
ChannelRow:
  DEC (IX+$03)
  JP P,Delay
  LD E,(IX+$09)
  LD D,(IX+$0A)
ReadItem:
  LD A,(DE)               ; The next item: find its range in ItemRanges, A =
                          ; the byte less the range's first, jump through the
                          ; JR at $C877
  INC DE
  LD HL,ItemRanges
l_C866:
  CP (HL)
  INC HL
  JR C,l_C86D
  INC HL
  JR l_C866
l_C86D:
  LD C,A
  LD A,(HL)
  LD (l_C86D+$000B),A
  LD A,C
  DEC HL
  DEC HL
  DEC HL
  SUB (HL)
  JR ItemNote

; ItemSample
ItemSample:
  DEFB $21,$61,$CD,$28,$07,$01,$62,$00 ; $EF-$FE: the sample (98 bytes from
  DEFB $09,$3D,$20,$FC,$DD,$75,$05,$DD ; $CD61)
  DEFB $74,$06,$18,$D4
ItemOrnament:
  DEFB $DD,$36,$0B,$00,$21,$D3,$D0,$28 ; $35-$44: the ornament (32 bytes from
  DEFB $07,$01,$20,$00,$09,$3D,$20,$FC ; $D0D3)
  DEFB $DD,$75,$07,$DD,$74,$08,$18,$BC
ItemEnvelope:
  DEFB $32,$C2,$C9,$1A,$13,$32,$C0,$C9 ; $0E-$1D: the envelope shape and the
  DEFB $DD,$36,$0B,$01,$AF,$18,$DD     ; period byte that follows, ornament 0
ItemLength:
  DEFB $DD,$77,$04,$18,$A8 ; $45-$84: the row length
ItemOff:
  DEFB $DD,$36,$02,$00,$18,$0B ; $1E-$34: the channel off

; ItemNote
;
; Used by the routine at ChannelRow.
ItemNote:
  LD (IX+$00),A           ; $8F-$EE: a note: the sample from its first row
  LD (IX+$01),$00
  LD (IX+$02),$21
ItemHold:
  LD A,(IX+$04)           ; $85-$8E: the row length again, no new note
  LD (IX+$03),A
  LD (IX+$09),E
  LD (IX+$0A),D
  RET

; data_C8D7
data_C8D7:
  DEFB $CD,$DA,$C8

; A delay loop of 30 steps
;
; Used by the routines at MusicPlay and ChannelRow.
Delay:
  LD HL,$001E
l_C8DD:
  DEC HL
  LD A,H
  OR L
  JP NZ,l_C8DD
  RET
; This entry point is used by the routine at ChannelSound.
DelayLong:
  LD HL,$0021             ; A delay loop of 33 steps (a channel that is off)
  JR l_C8DD

; A channel's frame: its sample row (period offset, mixer bits, volume, noise),
; its ornament's note, the period; HL = the period, A = the volume, B = the
; mixer bits
;
; Used by the routine at MusicPlay.
ChannelSound:
  LD A,(IX+$02)
  LD B,$09
  OR A
  JR Z,DelayLong
  DEC A
  LD (IX+$02),A
  PUSH AF
  LD A,(IX+$01)
  LD E,A
  INC A
  AND $1F
  LD (IX+$01),A
  POP AF
  DEC A
  LD C,(IX+$05)
  LD B,(IX+$06)
  JR NZ,l_C91E
  LD HL,$0060
  ADD HL,BC
  LD A,(HL)
  OR A
  JR Z,l_C91B
  LD (IX+$01),A
  DEC A
  LD E,A
  INC HL
  LD A,(HL)
  INC A
  INC A
l_C91B:
  LD (IX+$02),A
l_C91E:
  LD A,E
  ADD A,A
  ADD A,E
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD C,(HL)
  BIT 7,C
  LD A,$08
  JR NZ,l_C930
  XOR A
l_C930:
  BIT 6,C
  JR Z,l_C936
  OR $01
l_C936:
  LD (l_C98D+$0002),A
  INC HL
  LD A,E
  LD E,(HL)
  LD HL,$0000
  PUSH AF
  RRA
  RRA
  RRA
  RRA
  AND $0F
  LD D,A
  BIT 5,C
  JR Z,l_C94E
  ADD HL,DE
  JR l_C950
l_C94E:
  SBC HL,DE
l_C950:
  BIT 7,C
  JR NZ,l_C95A
  LD A,C
  AND $1F
  LD (AYRegs+$0006),A
l_C95A:
  POP AF
  AND $0F
  POP DE
  LD D,$00
  EX DE,HL
  LD C,(IX+$07)
  LD B,(IX+$08)
  ADD HL,BC
  PUSH AF
  LD A,$00
  ADD A,(HL)
  ADD A,(IX+$00)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,PeriodTable
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  ADD HL,DE
  POP BC
  LD A,(IX+$02)
  LD C,A
  OR A
  JR Z,l_C98D
  LD C,B
  LD A,(IX+$0B)
  OR A
  JR Z,l_C98D
  LD C,$10
l_C98D:
  LD A,C
  LD B,$08
  RET

; Channel A's record: +0 the note, +1 the sample row, +2 rows left, +3 the row
; counter, +4 the length, +5 the sample, +7 the ornament, +9 the stream, +$0B
; envelope on
ChannelA:
  DEFB $00,$00,$00,$01,$00,$00,$00,$D3,$D0,$83,$CA,$00

; Channel B's record
ChannelB:
  DEFB $00,$00,$00,$01,$00,$00,$00,$D3,$D0,$E5,$CA,$00

; Channel C's record
ChannelC:
  DEFB $00,$00,$00,$01,$00,$00,$00,$D3,$D0,$E8,$CA,$00

; The AY register image: three tone periods, the noise, the mixer, three
; volumes, the envelope
AYRegs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00

; The AY tone period of each note 0-$5F (96 notes)
PeriodTable:
  DEFW $0EF8,$0E10,$0D60,$0C80,$0BD8,$0B28,$0A88,$09F0,$0960,$08E0,$0858,$07E0
  DEFW $077C,$0708,$06B0,$0640,$05EC,$0594,$0544,$04F8,$04B0,$0470,$042C,$03F0
  DEFW $03BE,$0384,$0358,$0320,$02F6,$02CA,$02A2,$027C,$0258,$0238,$0216,$01F8
  DEFW $01DF,$01C2,$01AC,$0190,$017B,$0165,$0151,$013E,$012C,$011C,$010B,$00FC
  DEFW $00EF,$00E1,$00D6,$00C8,$00BD,$00B2,$00A8,$009F,$0096,$008E,$0085,$007E
  DEFW $0077,$0070,$006B,$0064,$005E,$0059,$0054,$004F,$004B,$0047,$0042,$003F
  DEFW $003B,$0038,$0035,$0032,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F
  DEFW $001D,$001C,$001A,$0019,$0017,$0016,$0015,$0013,$0012,$0011,$0010,$000F
