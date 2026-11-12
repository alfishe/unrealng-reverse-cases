; --------------------------------------------------------------------------------------------------------------------
; megaapoc-module.asm: The Mega Apocalypse game player: three channels of order lists and patterns, plus one sound effect on channel C
;
; Entry: MusicPlay $E505 (once a frame). Init $E5EA starts the song at $EB38 (the tempo, then three words: the order
; lists of channels A, B and C); Effect $E635 starts sound effect A (18 bytes at $EE94 + 18 * A).
;
; An order list: pattern addresses, a word 0 starts it again. A pattern: $00-$7F a note (ends the row), $80-$8C
; commands through CommandOffsets ($80 rest, $85 the next pattern, $88 stop, $82 and $86 two argument bytes, $89 and
; $8B one), $B0-$BF the arpeggio, $C0-$DF the volume envelope, $E0-$FF the note length.
; --------------------------------------------------------------------------------------------------------------------

; One frame: when the music is on, each channel's row on a row frame and each
; channel's sound; the sound effect on channel C; the mixer; then the AY
; registers
MusicPlay:
  SUB A
  CP $01
  PUSH IX
  JR Z,EffectFrame
  LD B,A
  LD IX,Channels
  LD HL,TempoCounter
  DEC (HL)
  JR NZ,l_E525
  LD (HL),$06
  CALL ChannelRow
  CALL ChannelRowNext
  CALL ChannelRowNext
  LD IXL,$64
l_E525:
  LD A,$0F
  LD (AYRegs+$0006),A
  LD BC,$E8B2
  CALL ChannelSound
  LD (AYRegs),HL
  LD BC,$E8B3
  CALL ChannelSoundNext
  LD (AYRegs+$0002),HL
  LD BC,$E8B4
  CALL ChannelSoundNext
  LD (AYRegs+$0004),HL
  SUB A
EffectFrame:
  CP $00                  ; The sound effect's frame (the CP operand at $E547:
                          ; 1 while one plays): its period sweep, noise and
                          ; volume over channel C
  JR Z,Mixer
  LD HL,EffectParams+$000E
  DEC (HL)
  JR NZ,l_E558
  LD (AYRegs+$000A),A
  LD (EffectFrame+$0001),A
  JR Mixer
l_E558:
  LD DE,(EffectParams+$000C)
  LD A,(EffectParams+$0005)
  OR A
  JR Z,l_E578
  LD HL,EffectCounters+$0001
  DEC (HL)
  JR NZ,l_E578
  LD (HL),A
  LD HL,EffectParams+$0006
  RRC (HL)
  LD HL,(EffectParams+$0007)
  JR C,l_E576
  LD HL,(EffectParams+$0009)
l_E576:
  ADD HL,DE
  EX DE,HL
l_E578:
  LD HL,(EffectParams)
  ADD HL,DE
  LD A,(EffectParams+$0004)
  OR A
  JR Z,l_E58F
  EX DE,HL
  LD HL,EffectCounters
  DEC (HL)
  JR NZ,l_E58E
  LD (HL),A
  LD DE,(EffectParams+$0002)
l_E58E:
  EX DE,HL
l_E58F:
  LD (EffectParams+$000C),HL
  LD A,$10
  LD (AYRegs+$000A),A
  LD (AYRegs+$0004),HL
  LD A,L
  LD HL,EffectParams+$000B
  RRC (HL)
  LD HL,Channels+$0002
  RES 0,(HL)
  JR NC,Mixer
  INC (HL)
  LD (AYRegs+$0006),A
Mixer:
  LD HL,Channels+$0002    ; The mixer from the channels' tone and noise bits
  LD A,$CE
  OR (HL)
  DEC L
  LD C,(HL)
  DEC L
  RR C
  RLA
  LD C,(HL)
  RR C
  RLA
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,A
  XOR C
  LD (AYRegs+$0007),A
WriteAY:
  SUB A                   ; AY registers 12 (13 when the envelope shape
                          ; changed) down to 0 from AYRegs
  CP $00
  LD HL,AYRegs+$000C
  LD D,$0C
  JR Z,l_E5D2
  INC D
  INC L
  LD (WriteAY+$0002),A
l_E5D2:
  LD BC,$FF3F
  OUT (C),D
  LD C,$FD
  OUT (C),D
  LD B,$BF
  LD A,(HL)
  DEC HL
  OUT ($5F),A
  OUT (C),A
  DEC D
  JP P,l_E5D2
  POP IX
  RET

; Start the song at $EB38: clear the channel records, the tempo, each channel's
; order list and its first pattern
Init:
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,Channels
  PUSH HL
  LD BC,$0044
  LD DE,Channels+$0001
  LD (HL),B
  LDIR
  LD HL,$EB38
  LD A,(HL)
  INC HL
  LD (MusicPlay+$0013),A
  EX (SP),IX
  SUB A
  LD (MusicPlay+$0002),A
  INC A
  LD (DE),A
  LD BC,$0301
l_E60D:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (IX+$24),C
  LD (IX+$09),E
  LD (IX+$0C),D
  LD (IX+$0F),$02
  LD A,(DE)
  LD (IX+$03),A
  INC E
  LD A,(DE)
  LD (IX+$06),A
  INC IXL
  DJNZ l_E60D
  LD A,C
  LD (MusicPlay+$0002),A
  POP IX
  POP HL
  POP DE
  POP BC
  RET

; Start sound effect A: its 15 parameter bytes to EffectParams, 3 to the AY
; image
Effect:
  PUSH BC
  PUSH DE
  PUSH HL
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,A
  LD B,$00
  LD HL,$EE94
  ADD HL,BC
  LD C,A
  ADD HL,BC
  ADD HL,BC
  LD DE,EffectParams
  LD C,$0F
  SUB A
  LD (EffectFrame+$0001),A
  LDIR
  LD C,$03
  LD DE,AYRegs+$000B
  LDIR
  LD HL,(EffectParams+$0004)
  LD (EffectCounters),HL
  LD A,$01
  LD (EffectFrame+$0001),A
  LD (WriteAY+$0002),A
  POP HL
  POP DE
  POP BC
  RET

; Jump offsets of commands $80-$8C (target = the entry's address + its byte)
CommandOffsets:
  DEFB $DA,$74,$45,$68,$6B,$1A,$51,$7C,$05,$37,$75,$6F,$2F

; $88: the music off, the volumes 0
CommandStop:
  LD HL,l_E525+$0020
  EX (SP),HL
  SUB A
  LD (MusicPlay+$0002),A
  LD (AYRegs+$0008),A
  LD (AYRegs+$0009),A
  LD (AYRegs+$000A),A
  RET

; CommandEnd
CommandEnd:
  DEFB $DD,$4E,$0F,$DD,$6E,$09,$DD,$66 ; $85: the next pattern of the order
  DEFB $0C,$09,$7E,$2C,$B6,$20,$03,$ED ; list (a word 0: the list from its
  DEFB $42,$48,$56,$2D,$5E,$0C,$0C,$DD ; start)
  DEFB $71,$0F,$18,$63
CommandTie:
  DEFB $DD,$77,$2A,$18,$5E ; $8C: the note byte to $8C (the next note ties)
CommandTranspose:
  DEFB $1A,$13,$DD,$77,$3F,$18,$57 ; $89 n: the channel's transposition
CommandSweep:
  DEFB $1A,$13,$DD,$77,$1E,$DD,$CB,$42 ; $82 step count: the period sweep
  DEFB $DE,$1A,$13,$DD,$77,$21,$18,$47
CommandVibrato:
  DEFB $1A,$13,$DD,$77,$39,$1A,$13,$DD ; $86 depth speed: the vibrato
  DEFB $77,$3C,$87,$DD,$77,$36,$DD,$CB
  DEFB $42,$E6,$18,$33
CommandDrumOn:
  DEFB $DD,$CB,$42,$FE    ; $83: flags 7 and 6
CommandHold:
  DEFB $DD,$CB,$42,$F6,$18,$29 ; $84: flag 6
CommandPlain:
  DEFB $DD,$70,$42,$18,$24 ; $81: every flag off
CommandNoise:
  DEFB $1A,$13,$32,$3E,$E8 ; $8B n: the noise period, flags 2 and 1
CommandMixOn:
  DEFB $DD,$CB,$42,$D6    ; $8A: flags 2 and 1
CommandNoiseOn:
  DEFB $DD,$CB,$42,$CE,$18,$15 ; $87: flag 1

; The next channel's row (IX + 1)
;
; Used by the routine at MusicPlay.
ChannelRowNext:
  INC IXL

; ChannelRow
;
; Used by the routine at MusicPlay.
ChannelRow:
  DEC (IX+$24)            ; A channel's row: count its row counter down, at 0
                          ; read the pattern's items up to a note or a rest
  LD A,(IX+$42)
  JR NZ,BendStep
  AND $30
  LD (IX+$42),A
  LD E,(IX+$03)
  LD D,(IX+$06)
ReadItem:
  LD A,(DE)               ; The next item of the stream: $E0-$FF length,
                          ; $C0-$DF envelope, $B0-$BF arpeggio, $80-$AF
                          ; commands, else a note
  INC DE
  CP $B0
  JR C,l_E72B
  ADD A,$20
  JR C,l_E720
  ADD A,$20
  JR C,l_E726
  LD C,A
  LD HL,$E986
  ADD HL,BC
  LD C,(HL)
  LD (IX+$18),C
  JR ReadItem
l_E720:
  INC A
  LD (IX+$27),A
  JR ReadItem
l_E726:
  LD (IX+$33),A
  JR ReadItem
l_E72B:
  OR A
  JP P,ItemNote
  LD C,A
  LD HL,l_E5D2+$0017
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  JP (HL)
BendStep:
  ADD A,A                 ; The note's bend by one a row
  RET P
  SBC A,A
  OR $01
  ADD A,(IX+$2A)
  LD (IX+$2A),A
  RET

; CommandRest
CommandRest:
  DEFB $DD,$36,$30,$F0,$18,$28 ; $80: the envelope silent

; ItemNote
;
; Used by the routine at ChannelRow.
ItemNote:
  LD (IX+$12),B           ; A note: restart the envelope and the arpeggio
                          ; (unless tied), noise notes from $54
  LD (IX+$15),B
  BIT 7,(IX+$2A)
  LD (IX+$2A),A
  JR NZ,l_E75E
  LD (IX+$30),B
  LD (IX+$2D),B
l_E75E:
  LD C,(IX+$18)
  LD (IX+$1B),C
  LD C,B
  SUB $54
  JR C,l_E76E
  LD C,$02
  LD (l_E525+$0001),A
l_E76E:
  LD (IX+$00),C
  LD A,(IX+$27)
  LD (IX+$24),A
  LD (IX+$06),D
  LD (IX+$03),E
  RET

; The next channel's sound (IX + 1)
;
; Used by the routine at MusicPlay.
ChannelSoundNext:
  INC IXL

; ChannelSound
;
; Used by the routine at MusicPlay.
ChannelSound:
  LD D,$00                ; A channel's frame: the volume envelope row, the
                          ; arpeggio row, the period with vibrato and sweep;
                          ; the volume to (BC)
  LD A,(IX+$30)
  CP $F0
  JR NC,l_E7A4
  SUB $10
  LD (IX+$30),A
  JR NC,l_E7A4
  LD HL,$EA8F
  LD E,(IX+$33)
  ADD HL,DE
  LD A,(HL)
  ADD A,(IX+$2D)
  LD E,A
  ADD HL,DE
  LD A,(HL)
  INC (IX+$2D)
  LD (IX+$30),A
l_E7A4:
  OR $F0
  INC A
  ADD A,$0F
  JR C,l_E7AC
  SUB A
l_E7AC:
  LD (BC),A
  LD HL,$EA7C
  LD E,(IX+$1B)
  INC E
  ADD HL,DE
  LD A,(HL)
  OR A
  JP P,l_E7BF
  LD E,(IX+$18)
  AND $7F
l_E7BF:
  LD (IX+$1B),E
  ADD A,(IX+$2A)
  ADD A,(IX+$3F)
  ADD A,A
  LD HL,PeriodTable
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC L
  LD D,(HL)
  LD C,(IX+$42)
  BIT 4,C
  JR Z,l_E803
  SUB A
  OR (IX+$39)
  JR NZ,l_E7E0
  INC A
  AND C
l_E7E0:
  LD B,(IX+$36)
  LD L,A
  LD A,(IX+$3C)
  BIT 5,C
  JR NZ,l_E7F2
  SUB L
  JR NZ,l_E7F8
  SET 5,C
  JR l_E7F8
l_E7F2:
  ADD A,L
  CP B
  JR NZ,l_E7F8
  RES 5,C
l_E7F8:
  LD (IX+$3C),A
  SRL B
  SUB B
  LD L,A
  SBC A,A
  LD H,A
  ADD HL,DE
  EX DE,HL
l_E803:
  LD A,C
  XOR $01
  LD (IX+$42),A
  BIT 3,C
  JR Z,l_E82E
  LD B,(IX+$21)
  DJNZ l_E82B
  LD C,(IX+$1E)
  BIT 7,C
  JR Z,l_E81A
  DEC B
l_E81A:
  LD L,(IX+$12)
  LD H,(IX+$15)
  ADD HL,BC
  LD (IX+$12),L
  LD (IX+$15),H
  ADD HL,DE
  EX DE,HL
  JR l_E82E
l_E82B:
  LD (IX+$21),B
l_E82E:
  CPL
  AND $03
  LD A,(IX+$00)
  LD C,A
  RES 0,C
  RRA
  JR NZ,l_E841
  LD HL,AYRegs+$0006
  LD (HL),$07
  OR $01
l_E841:
  OR C
  BIT 2,(IX+$42)
  JR Z,l_E84C
  RES 1,(IX+$42)
l_E84C:
  LD (IX+$00),A
  EX DE,HL
  RET

; The sound effect: period, sweep steps and their counters, the noise pattern
EffectParams:
  DEFB $03,$00,$03,$00,$08,$01,$AA,$01,$00,$FF,$FF,$FF,$07,$00,$00

; The sweep counters
EffectCounters:
  DEFB $07,$01,$00,$00

; The channel records, interleaved: field k of channel c at $E864 + k + c
; (fields every 3 bytes)
Channels:
  DEFB $00,$00,$03,$4C,$4C,$62,$EB,$EB,$EB,$60,$BA,$0E,$E9,$E9,$EA,$02,$02,$02,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$C0,$C0,$78,$01,$01,$01,$01,$01,$01,$01,$01,$01,$0C,$0C,$63,$03
  DEFB $03,$03,$0C,$0C,$06,$01,$01,$0D,$10,$10,$00,$04,$04,$00,$04,$04,$00,$00,$0C,$00,$31,$31,$01

; Frames left to the next row
TempoCounter:
  DEFB $04

; The AY register image: three tone periods, the noise, the mixer, three
; volumes, the envelope
AYRegs:
  DEFB $A3,$06,$4F,$03,$ED,$EC,$0F,$DC,$0C,$0C,$06,$40,$1F,$09

; The AY tone period of each note 0-$53 (84 notes)
PeriodTable:
  DEFW $0D4D,$0C8E,$0BDA,$0B2F,$0A8F,$09F7,$0968,$08E1,$0861,$07E9,$0777,$070C
  DEFW $06A7,$0647,$05ED,$0598,$0547,$04FC,$04B4,$0470,$0431,$03F4,$03BC,$0386
  DEFW $0353,$0324,$02F6,$02CC,$02A4,$027E,$025A,$0238,$0218,$01FA,$01DE,$01C3
  DEFW $01AA,$0192,$017B,$0166,$0152,$013F,$012D,$011C,$010C,$00FD,$00EF,$00E1
  DEFW $00D5,$00C9,$00BE,$00B3,$00A9,$009F,$0096,$008E,$0086,$007F,$0077,$0071
  DEFW $006A,$0064,$005F,$0059,$0054,$0050,$004B,$0047,$0043,$003F,$003C,$0038
  DEFW $0035,$0032,$002F,$002D,$002A,$0028,$0026,$0024,$0022,$0020,$001E,$001C
