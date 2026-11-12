; --------------------------------------------------------------------------------------------------------------------
; fp3bt-module.asm: A game's stream player: numbered streams of two-byte items, called like subroutines, on three channels; volume, pitch and global shapes
;
; Entries: MusicPlay $C000 (JP Play, once a frame), MusicStop $C003 (JP Silence), $C006 (JP $C3FE: a stub, no code
; there), MusicInit $C00A (stream $40 on channel 1).
;
; A stream (number E: $C450 + the word at $C590 + 2E): two bytes an item, the second the duration or argument: $00
; rest, $01-$08 start stream E on channel n, $09-$64 a note, $65-$E3 a note with the last duration (one byte), $E6
; noise, $E8 hold, $E9 volume shape E, $EA pitch shape E, $EB the global shape E, $EC detune, $ED transposition, $EE
; call stream E, $FF return (or loop), the rest stop the channel. A shape (number E: $C450 + the word at $C518 + 2E):
; (count, step) pairs, ended by $FF.
; --------------------------------------------------------------------------------------------------------------------

; JP Play
MusicPlay:
  JP Play

; JP Silence
MusicStop:
  JP Silence

; JP $C3FE
Stub:
  JP Free

; Not 0: Play does not write the AY
Mute:
  DEFB $00

; Stream $40 on channel 1
MusicInit:
  LD E,$40
  LD A,$01

; Stream E on channel C (1-3; a stream starting with a byte below 9 names its
; channel): when its priority is not lower, the channel restarts there
;
; Used by the routine at ChannelStep.
StartStream:
  LD C,A
  CALL StreamAddress
  LD A,(HL)
  CP $09
  JR NC,l_C01A
  LD C,A
  INC HL
  LD A,(HL)
l_C01A:
  CP $F4
  LD B,$0A
  JR NZ,l_C023
  INC HL
  LD B,(HL)
  INC HL
l_C023:
  DEC C
  JR Z,l_C075
  DEC C
  JR Z,l_C055
  DEC C
  JR Z,l_C035
  LD A,(ChannelB+$0010)
  OR A
  JR Z,l_C055
  JP l_C075
l_C035:
  LD DE,ChannelC+$0010
  LD A,(DE)
  LD C,A
  LD A,B
  SUB C
  RET C
  XOR A
  LD (DE),A
  LD (ChannelC+$001B),A
  LD (ChannelC+$0018),A
  INC A
  LD (ChannelC+$0011),A
  LD (ChannelC+$0012),HL
  LD (ChannelC+$0014),HL
  LD (ChannelC+$0016),HL
  LD A,B
  LD (DE),A
  RET
l_C055:
  LD DE,ChannelB+$0010
  LD A,(DE)
  LD C,A
  LD A,B
  SUB C
  RET C
  XOR A
  LD (DE),A
  LD (ChannelB+$001B),A
  LD (ChannelB+$0018),A
  INC A
  LD (ChannelB+$0011),A
  LD (ChannelB+$0012),HL
  LD (ChannelB+$0014),HL
  LD (ChannelB+$0016),HL
  LD A,B
  LD (DE),A
  RET
l_C075:
  LD DE,ChannelA+$0010
  LD A,(DE)
  LD C,A
  LD A,B
  SUB C
  RET C
  XOR A
  LD (DE),A
  LD (ChannelA+$001B),A
  LD (ChannelA+$0018),A
  INC A
  LD (ChannelA+$0011),A
  LD (ChannelA+$0012),HL
  LD (ChannelA+$0014),HL
  LD (ChannelA+$0016),HL
  LD A,B
  LD (DE),A
  RET

; Every channel off, the mixer to $3F, the volumes 0, then the AY registers
;
; Used by the routine at MusicStop.
Silence:
  LD A,$3F
  LD (AYRegs+$0007),A
  XOR A
  LD (ChannelA+$0010),A
  LD (ChannelB+$0010),A
  LD (ChannelC+$0010),A
  LD (ChannelA+$001B),A
  LD (ChannelB+$001B),A
  LD (ChannelC+$001B),A
  LD (ChannelA+$0018),A
  LD (ChannelB+$0018),A
  LD (ChannelC+$0018),A
  LD (AYRegs+$0008),A
  LD (AYRegs+$0009),A
  LD (AYRegs+$000A),A
  LD HL,AYRegs+$000D
  LD E,$0D
  JP l_C16B

; HL = $C450 + the word at $C590 + 2E (stream E)
;
; Used by the routines at StartStream and ChannelStep.
StreamAddress:
  LD A,E
  ADD A,A
  ADD A,$90
  LD L,A
  ADC A,$C5
  SUB L
  LD H,A
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,PeriodTable
  ADD HL,DE
  RET

; BC = $C450 + the word at $C518 + 2E (shape E)
;
; Used by the routine at ChannelStep.
ShapeAddress:
  LD A,E
  ADD A,A
  ADD A,$18
  LD E,A
  ADC A,$C5
  SUB E
  LD D,A
  LD A,(DE)
  ADD A,$50
  LD C,A
  INC DE
  LD A,(DE)
  ADC A,$C4
  LD B,A
  RET

; One frame: each playing channel's stream step and sound, the global shape,
; then the AY registers 10 down to 0 (unless Mute)
;
; Used by the routine at MusicPlay.
Play:
  LD A,$14
  LD (PlayVars+$0003),A
  LD A,(ChannelA+$0010)
  OR A
  JR Z,l_C10D
  LD IX,ChannelA
  LD IY,AYRegs+$0008
  LD HL,(AYRegs)
  LD (PlayVars),HL
  LD HL,(ChannelA+$0012)
  CALL ChannelStep
  LD (AYRegs),HL
l_C10D:
  LD A,(ChannelB+$0010)
  OR A
  JR Z,l_C12A
  LD IX,ChannelB
  LD IY,AYRegs+$0009
  LD HL,(AYRegs+$0002)
  LD (PlayVars),HL
  LD HL,(ChannelB+$0012)
  CALL ChannelStep
  LD (AYRegs+$0002),HL
l_C12A:
  LD A,(ChannelC+$0010)
  OR A
  JR Z,l_C147
  LD IX,ChannelC
  LD IY,AYRegs+$000A
  LD HL,(AYRegs+$0004)
  LD (PlayVars),HL
  LD HL,(ChannelC+$0012)
  CALL ChannelStep
  JP l_C15B
l_C147:
  OR H
  OR L
  JR Z,l_C15B
  DEC L
  DEC L
  LD A,(AYRegs+$0009)
  LD (AYRegs+$000A),A
  LD A,(AYRegs+$0007)
  OR $20
  LD (AYRegs+$0007),A
l_C15B:
  LD (AYRegs+$0004),HL
  CALL GlobalShape
  LD A,(Mute)
  OR A
  RET NZ
  LD HL,AYRegs+$000A
  LD E,$0A
; This entry point is used by the routine at Silence.
l_C16B:
  LD BC,$FFFD
  OUT (C),E
  LD BC,$BFFD
  LD A,(HL)
  DEC HL
  OUT (C),A
  DEC E
  JP P,l_C16B
  RET

; A channel's frame: at the end of its duration the next items, else its shapes
;
; Used by the routine at Play.
ChannelStep:
  DEC (IX+$11)
  JP NZ,ChannelShapes
ReadItem:
  LD A,(HL)               ; The next item (two bytes, A and E)
  INC HL
  LD E,(HL)
  INC HL
  OR A
  JP Z,l_C24E
  CP $09
  JP C,ItemStart
  CP $65
  JP C,ItemNote
  CP $E4
  JP C,ItemTie
  CP $FF
  JP Z,ItemReturn
  SUB $E6
  JR Z,ItemNoise
  DEC A
  DEC A
  JR Z,ItemHold
  DEC A
  JR Z,ItemVolumeShape
  DEC A
  JR Z,ItemPitchShape
  DEC A
  JR Z,ItemGlobalShape
  DEC A
  JP Z,ItemDetune
  DEC A
  JR Z,ItemTranspose
  DEC A
  JR Z,ItemCall
ItemStop:
  LD (IX+$10),$00         ; Stop the channel
  LD (IY+$00),$00
  LD HL,$0000
  RET
ItemHold:
  LD (IX+$11),$01         ; $E8: hold
  DEC HL
  LD (IX+$12),L
  LD (IX+$13),H
  LD HL,$0000
  RET
ItemStart:
  PUSH IX                 ; $01-$08: start stream E on channel A
  PUSH HL
  CALL StartStream
  POP HL
  POP IX
  LD A,(PlayVars+$0003)
  DEC A
  RET Z
  LD (PlayVars+$0003),A
  JP ReadItem
ItemNoise:
  LD A,E                  ; $E6: the noise period
  LD (AYRegs+$0006),A
  LD A,$01
  LD (PlayVars+$0002),A
  JP ReadItem
ItemTranspose:
  LD (IX+$18),E           ; $ED: the transposition
  JP ReadItem
ItemPitchShape:
  CALL ShapeAddress       ; $EA: the pitch shape
  LD (IX+$0E),C
  LD (IX+$0F),B
  JP ReadItem
ItemVolumeShape:
  CALL ShapeAddress       ; $E9: the volume shape
  LD (IX+$0C),C
  LD (IX+$0D),B
  JP ReadItem
ItemGlobalShape:
  CALL ShapeAddress       ; $EB: the global shape
  LD (PlayVars+$0010),BC
  JP ReadItem
ItemCall:
  LD (IX+$15),H           ; $EE: call stream E (the return position kept)
  LD (IX+$14),L
  CALL StreamAddress
  JP ReadItem
ItemReturn:
  LD H,(IX+$15)           ; $FF: back to the caller, or the stream's loop
  LD L,(IX+$14)
  LD A,(HL)
  CP $FF
  JP NZ,ReadItem
  LD H,(IX+$17)
  LD L,(IX+$16)
  JP ReadItem
ItemDetune:
  LD (IX+$1B),E           ; $EC: the detune
  JP ReadItem
ItemTie:
  AND $7F                 ; $65-$E3: a note with the last duration
  DEC HL
  LD E,(IX+$1E)
ItemNote:
  ADD A,(IX+$18)          ; $09-$64: a note, its period, the shapes from their
                          ; start
  SUB $0C
l_C24E:
  LD (IX+$11),E
  LD (IX+$1E),E
  LD (IX+$1C),A
  LD (IX+$13),H
  LD (IX+$12),L
  ADD A,A
  ADD A,$50
  LD L,A
  ADC A,$C4
  SUB L
  LD H,A
  LD DE,PlayVars
  LDI
  LDI
  LD (IY+$00),$00
  PUSH IX
  POP DE
  LD HL,$0008
  ADD HL,DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  XOR A
  LD HL,PlayVars+$0002
  OR (HL)
  LD (HL),$00
  LD L,(IX+$19)
  JR Z,l_C29F
  LD HL,(PlayVars+$0010)
  LD (PlayVars+$0008),HL
  LD HL,$0000
  LD (PlayVars+$0004),HL
l_C29F:
  LD A,(AYRegs+$0007)
  AND (IX+$1A)
  OR L
  AND $3F
  LD (AYRegs+$0007),A
ChannelShapes:
  PUSH IX                 ; The volume shape's step, then the pitch shape's:
                          ; the period
  POP HL
  LD D,(IX+$05)
  LD E,(IX+$04)
  INC (HL)
  LD A,(DE)
  SUB (HL)
  JP NZ,l_C2E0
  LD (HL),A
  INC DE
  LD A,(DE)
  ADD A,(IY+$00)
  SUB $80
  LD (IY+$00),A
  INC DE
  INC HL
  INC (HL)
  LD A,(DE)
  SUB (HL)
  JP NZ,l_C2E0
  LD (HL),A
  INC DE
  LD A,(DE)
  INC A
  JP NZ,l_C2DA
  LD D,(IX+$0D)
  LD E,(IX+$0C)
l_C2DA:
  LD (IX+$05),D
  LD (IX+$04),E
l_C2E0:
  LD HL,(PlayVars)
  LD A,H
  OR L
  RET Z
  LD A,(IX+$1B)
  OR A
  JR NZ,l_C32E
  PUSH IX
  POP HL
  INC HL
  INC HL
  LD D,(IX+$07)
  LD E,(IX+$06)
  INC (HL)
  LD A,(DE)
  SUB (HL)
  JP NZ,l_C32A
  LD (HL),A
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  INC HL
  INC (HL)
  LD A,(DE)
  SUB (HL)
  JP NZ,l_C31C
  LD (HL),A
  INC DE
  LD A,(DE)
  INC A
  JP NZ,l_C316
  LD D,(IX+$0F)
  LD E,(IX+$0E)
l_C316:
  LD (IX+$07),D
  LD (IX+$06),E
l_C31C:
  LD HL,(PlayVars)
  LD B,$00
  ADD HL,BC
  ADD HL,BC
  LD C,$80
  SBC HL,BC
  SBC HL,BC
  RET
l_C32A:
  LD HL,(PlayVars)
  RET
l_C32E:
  DEC (IX+$1D)
  LD A,(IX+$1C)
  JR Z,l_C33D
  ADD A,(IX+$1B)
  LD (IX+$1D),$01
l_C33D:
  ADD A,A
  ADD A,$50
  LD L,A
  ADC A,$C4
  SUB L
  LD H,A
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  RET

; The global shape's step: the noise period, envelope mode above 16
;
; Used by the routine at Play.
GlobalShape:
  LD DE,(PlayVars+$0008)
  LD HL,PlayVars+$0004
  INC (HL)
  LD A,(DE)
  SUB (HL)
  RET NZ
  LD (HL),A
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  INC HL
  INC (HL)
  LD A,(DE)
  SUB (HL)
  JP NZ,l_C370
  LD (HL),A
  INC DE
  LD A,(DE)
  INC A
  JP NZ,l_C36C
  LD DE,(PlayVars+$0010)
l_C36C:
  LD (PlayVars+$0008),DE
l_C370:
  LD HL,AYRegs+$0006
  LD A,(HL)
  ADD A,C
  SUB $80
  LD (HL),A
  CP $11
  RET C
  INC HL
  LD A,(HL)
  OR $38
  LD (HL),A
  RET

; The AY register image: three tone periods, the noise, the mixer, three
; volumes, the envelope
AYRegs:
  DEFB $AC,$03,$87,$02,$85,$02,$A2,$38,$0E,$08,$08,$21,$01,$0C

; The note's period, the noise flag, the item budget, the global shape's
; counters and pointers
PlayVars:
  DEFB $7D,$02,$00,$14,$00,$00,$0A,$00,$26,$C8,$04,$00,$00,$00,$12,$00,$26,$C8

; Channel A's record, 31 bytes: the shapes' counters and pointers, +$10
; playing, +$11 the duration, +$12 the stream, +$14 the return, +$16 the loop,
; +$18 transposition, +$19 noise, +$1A mixer mask, +$1B detune, +$1C the note
ChannelA:
  DEFB $01,$01,$00,$00,$30,$C8,$B7,$C7,$00,$00,$00,$00,$2D,$C8,$B7,$C7
  DEFB $0A,$0D,$87,$CD,$93,$CC,$7B,$CC,$0C,$08,$32,$0C,$0C,$01,$20

; Channel B's record
ChannelB:
  DEFB $07,$01,$00,$00,$61,$C7,$F5,$C7,$00,$00,$00,$00,$5B,$C7,$C8,$C7
  DEFB $0A,$0D,$0E,$CD,$0C,$CD,$F8,$CC,$0C,$10,$29,$00,$1F,$01,$28

; Channel C's record
ChannelC:
  DEFB $04,$01,$00,$00,$A2,$C7,$58,$C6,$00,$00,$00,$00,$9C,$C7,$58,$C6
  DEFB $00,$00,$5E,$D0,$5E,$D0,$5E,$D0,$00,$20,$1B,$00,$23,$01,$30

; Bytes the stub at $C006 jumps to: LD HL,($0000) and zeros
;
; Used by the routine at Stub.
Free:
  DEFB $2A,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; The AY tone period of each note (the streams' and shapes' offsets count from
; here)
PeriodTable:
  DEFW $0000,$0DDB,$0D14,$0C58,$0BA7,$0AFF,$0A61,$09CC,$093F,$08BB,$083D,$07C7
  DEFW $0757,$06EE,$068A,$062C,$05D3,$0580,$0531,$04E6,$04A0,$045D,$041F,$03E3
  DEFW $03AC,$0377,$0345,$0316,$02EA,$02C0,$0298,$0273,$0250,$022F,$020F,$01F2
  DEFW $01D6,$01BB,$01A2,$018B,$0175,$0160,$014C,$013A,$0128,$0117,$0108,$00F9
  DEFW $00EB,$00DE,$00D1,$00C6,$00BA,$00B0,$00A6,$009D,$0094,$008C,$0084,$007C
  DEFW $0075,$006F,$0069,$0063,$005D,$0058,$0053,$004E,$004A,$0046,$0042,$003E
  DEFW $003B,$0037,$0034,$0031,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F
  DEFW $001D,$001C,$001A,$0019,$0017,$0016,$0015,$0014,$0012,$0011,$0010,$0010
  DEFW $000F,$000E,$000D,$8301
