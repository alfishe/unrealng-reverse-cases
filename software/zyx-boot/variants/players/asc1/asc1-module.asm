; --------------------------------------------------------------------------------------------------------------------
; asc1-module.asm: The relocatable ASC Sound Master 1.x player: relocation, init, frame, rows with the 1.x commands, samples, ornaments
;
; Entries: MusicInit $C00B (the first time JR Relocate, after that JR InitPlayer), MusicPlay $C00E (JP PlayFrame),
; MusicStop $C011 (JP Silence). Every absolute operand is an offset from $C000 until Relocate has run.
;
; The module (ASC Sound Master 1.x): +0 delay, +1 the loop position, +2/+4/+6 the pattern, sample and ornament tables
; (offsets from the module), +8 the number of positions, +9 the positions. The pattern stream: $00-$55 a note, $56-$5D
; hold, $5E release, $5F off; $60-$9F the row length, $A0-$BF the sample, $C0-$DF the ornament, $E0 envelope mode,
; $E1-$EF the volume; $F0-$FF sixteen commands through CommandOffsets, some with an operand byte (noise, delay,
; glissando, slides, volume slide, envelope shapes 8, 10, 12, 14).
; --------------------------------------------------------------------------------------------------------------------

; The compiled player's header: MusicInit, MusicPlay, WriteAY and AYRegisters
; (absolute: the compiler wrote them for $C000)
PlayerVectors:
  DEFW MusicInit,MusicPlay,WriteAY,$C59B

; Three more bytes of the compilation's header
PlayerHeaderBytes:
  DEFB $80,$80,$37

; JR Relocate; Relocate rewrites the offset so that later calls go to
; InitPlayer
MusicInit:
  JR Relocate

; One zero byte
InitPad:
  DEFB $00

; JP PlayFrame (an offset until relocated)
MusicPlay:
  JP $00B9

; JP Silence (an offset until relocated)
MusicStop:
  JP $00A5

; "ASM COMPILATION OF " + the tune's title + " BY " + its author
PlayerText:
  DEFM "ASM COMPILATION OF TECHNO PROJECT II    BY HEATHER '94         "

; Find the player's own address (CALL $0052, the ROM's RET, leaves it on the
; stack) and jump to Relocator
;
; Used by the routine at MusicInit.
Relocate:
  CALL $0052
  DEC SP
  DEC SP
  POP DE
  LD HL,$04DF
  ADD HL,DE
  JP (HL)

; Clear the channels and the counters, read the module's header into the
; player's operands, then Silence
InitPlayer:
  XOR A
  LD HL,$0535
  LD DE,$0536
  LD BC,$0065
  LD (HL),A
  LDIR
  LD ($0167),A
  LD ($0548),A
  LD ($056A),A
  LD ($058C),A
  INC A
  LD ($05A9),A
  LD DE,$0671
  LD B,D
  LD C,E
  LD A,(DE)
  INC DE
  LD ($00C0),A
  LD A,(DE)
  INC DE
  LD ($0171),A
  CALL $015B
  LD ($017C),HL
  CALL $015B
  LD ($01E6),HL
  CALL $015B
  LD ($01F3),HL
  LD A,(DE)
  INC DE
  LD ($016D),A
  LD ($0164),DE

; Clear the AY register image, the mixer to $FF, then WriteAY
Silence:
  XOR A
  LD HL,$059B
  LD DE,$059C
  LD BC,$000D
  LD (HL),A
  LDIR
  DEC A
  LD ($05A2),A
  JP $012C

; Play one frame: on a row frame the next position and each channel's row,
; every frame each channel's sound and the mixer
PlayFrame:
  LD HL,$05A9
  DEC (HL)
  JR NZ,l_C0E6
  LD (HL),$06
  LD A,($0535)
  LD HL,$0557
  OR (HL)
  LD HL,$0579
  OR (HL)
  BIT 0,A
  CALL Z,$0163
  LD IX,$0535
  CALL $01AB
  LD IX,$0557
  CALL $01AB
  LD IX,$0579
  CALL $01AB
l_C0E6:
  LD IX,$0535
  LD BC,($059B)
  CALL $0394
  LD ($059B),BC
  LD ($05A3),A
  LD IX,$0557
  LD BC,($059D)
  CALL $0394
  LD ($059D),BC
  LD ($05A4),A
  LD IX,$0579
  LD BC,($059F)
  CALL $0394
  LD ($059F),BC
  LD ($05A5),A
  LD A,($057A)
  RLCA
  LD HL,$0558
  OR (HL)
  RLCA
  LD HL,$0536
  OR (HL)
  LD ($05A2),A

; Write the AY register image to the AY: register 13 only when set, then 12
; down to 0
WriteAY:
  LD HL,$05A8
  LD DE,$FFBF
  LD C,$FD
  LD A,(HL)
  INC A
  LD A,$0D
  JR NZ,l_C13C
  DEC A
  DEC HL
l_C13C:
  LD B,A
  INC A
  AND $09
  OR (HL)
  LD A,B
  JR NZ,l_C14D
  DEC A
  DEC HL
  LD B,D
  OUT (C),A
  LD B,E
  OUTI
  INC A
l_C14D:
  LD B,D
  OUT (C),A
  LD B,E
  OUTD
  DEC A
  JP P,$013C
  LD ($05A8),A
  RET

; HL = BC + the word at (DE), DE + 2
ReadOffsetDE:
  EX DE,HL
ReadOffset:
  LD E,(HL)               ; HL = BC + the word at (HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  RET

; Start the next position (after the last, the loop position): the pattern's
; three streams into the channels
NextPosition:
  LD HL,$0000
  LD DE,$0000
  ADD HL,DE
  LD A,E
  INC A
  CP $01
  JR C,l_C172
  LD A,$00
l_C172:
  LD ($0167),A
  LD A,(HL)
  ADD A,A
  ADD A,(HL)
  ADD A,A
  LD H,D
  LD L,A
  LD BC,$0000
  ADD HL,BC
  CALL $015C
  LD ($0549),HL
  CALL $015B
  LD ($056B),HL
  CALL $015B
  LD ($058D),HL
  LD HL,$0535
  SET 0,(HL)
  LD HL,$0557
  SET 0,(HL)
  LD HL,$0579
  SET 0,(HL)
  XOR A
  LD ($0540),A
  LD ($0562),A
  LD ($0584),A
  RET

; One row of a channel: when its row counter runs out, the commands and the
; next event of its stream
ChannelRow:
  DEC (IX+$13)
  RET P
  RES 6,(IX+$00)
  RES 7,(IX+$00)
  XOR A
  LD (IX+$0A),A
  LD (IX+$10),A
  LD E,(IX+$14)
  LD D,(IX+$15)
  LD A,(DE)
  INC DE
  CP $60
  JP C,$030A
  LD HL,$01C4
  PUSH HL
  SUB $F0
  JR NC,CommandF
  ADD A,$10
  JR C,CommandVolume
  ADD A,$20
  JR C,CommandOrnament
  ADD A,$20
  JR C,CommandSample
  ADD A,$40
  LD (IX+$12),A
  RET
CommandSample:
  LD BC,$0000             ; $A0-$BF: the sample from the sample table
  CALL $020E
  LD (IX+$16),L
  LD (IX+$17),H
  RET
CommandOrnament:
  LD BC,$0000             ; $C0-$DF: the ornament from the ornament table
  CALL $020E
  LD (IX+$1C),L
  LD (IX+$1D),H
  RET

; BC = BC / 16 (signed)
ShiftRight4:
  LD A,C
  SRA B
  RRA
  SRA B
  RRA
  SRA B
  RRA
  SRA B
  RRA
  LD C,A
  RET

; HL = BC + the word at BC + 2A
TableEntry:
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  ADD HL,BC
  RET
; This entry point is used by the routine at ChannelRow.
CommandVolume:
  RES 4,(IX+$00)          ; $E0: envelope mode (volume 15); $E1-$EF: the volume
  LD (IX+$0F),A
  RET NZ
  SET 4,(IX+$00)
  LD (IX+$0F),$0F
  RET
; This entry point is used by the routine at ChannelRow.
CommandF:
  LD HL,$0235             ; $F0-$FF: jump through CommandOffsets
  LD B,$00
  LD C,A
  ADD HL,BC
  LD C,(HL)
  ADD HL,BC
  LD C,B
  JP (HL)

; Sixteen jump offsets (target = the entry's address + its byte); the last one
; is the first byte of CommandNoise
CommandOffsets:
  DEFB $0F,$17,$1B,$12,$1E,$26,$39,$3B
  DEFB $C9,$43,$C7,$B4,$C5,$07,$C3

; $F0 n: the noise base
CommandNoise:
  LD A,(DE)
  INC DE
  LD (IX+$0B),A
  RET

; CommandContinue
CommandContinue:
  DEFB $CD,$52,$02        ; $F3: continue the sample and the ornament
CommandContSample:
  DEFB $DD,$CB,$00,$F6,$C9 ; $F1: continue the sample (the next note does not
                           ; restart it)
CommandContOrnament:
  DEFB $DD,$CB,$00,$FE,$C9 ; $F2: continue the ornament
CommandDelay:
  DEFB $1A,$13,$32,$A9,$05,$32,$C0,$00 ; $F4 n: the delay (frames a row)
  DEFB $C9
CommandGlissDown:
  DEFB $1A,$ED,$44,$13,$D5,$32,$AA,$05 ; $F5 n: glissando down by n a frame
  DEFB $87,$6F,$9F,$67,$29,$29,$29,$EB
  DEFB $3E,$FF,$18,$75
CommandGlissUp:
  DEFB $1A,$18,$EC        ; $F6 n: glissando up
CommandSlide:
  DEFB $DD,$CB,$00,$F6,$DD,$4E,$06,$DD ; $F7 n: slide to the next note in n
  DEFB $46,$07                         ; frames, the sample continues
CommandSlideNote:
  DEFB $1A,$13,$32,$AA,$05,$D5,$1A,$FE ; $F9 n: slide to the next note in n
  DEFB $56,$38,$09,$DD,$4E,$06,$DD,$46 ; frames
  DEFB $07,$DD,$7E,$02,$CD,$29,$05,$D5
  DEFB $DD,$7E,$02,$CD,$29,$05,$EB,$CD
  DEFB $FF,$01,$09,$D1,$B7,$ED,$52,$29
  DEFB $29,$29,$29,$F5,$E5,$30,$06,$EB
  DEFB $AF,$67,$6F,$ED,$52,$3A,$AA,$05
  DEFB $ED,$44,$4F,$06,$11,$AF,$8F,$81
  DEFB $38,$02,$91,$B7,$ED,$6A,$10,$F6
  DEFB $EB,$06,$00,$4F,$E1,$F1,$38,$0E
  DEFB $7A,$2F,$57,$7B,$2F,$5F,$13,$78
  DEFB $2F,$47,$79,$2F,$4F,$03,$09,$DD
  DEFB $75,$06,$DD,$74,$07,$3A,$AA,$05
  DEFB $DD,$73,$08,$DD,$72,$09,$DD,$77
  DEFB $0A,$D1,$C9
CommandVolumeSlide:
  DEFB $1A,$13,$87,$87,$07,$30,$04,$EE ; $FB n: the volume slide
  DEFB $F8,$C6,$08,$DD,$77,$11,$DD,$77
  DEFB $10,$C9
CommandShape:
  DEFB $32,$A8,$05,$C9    ; $F8, $FA, $FC, $FE: the envelope shape
RowEvent:
  DEFB $FE,$56,$38,$12,$FE,$5E,$38,$6E ; $56-$5D hold, $5E release, $5F off,
  DEFB $28,$06,$DD,$CB,$00,$96,$18,$66 ; else a note
  DEFB $DD,$CB,$00,$DE,$18,$60
RowNote:
  DEFB $DD,$77,$02,$DD,$7E,$0B,$DD,$77 ; a note: the sample and the ornament
  DEFB $0C,$DD,$7E,$0A,$3D,$F2,$37,$03 ; from their start unless continued, the
  DEFB $AF,$DD,$77,$06,$DD,$77,$07,$DD ; envelope period byte in envelope mode
  DEFB $CB,$00,$76,$20,$22,$AF,$DD,$77
  DEFB $0E,$DD,$77,$04,$DD,$77,$05,$DD
  DEFB $6E,$16,$DD,$66,$17,$DD,$75,$18
  DEFB $DD,$74,$19,$DD,$CB,$00,$D6,$DD
  DEFB $CB,$00,$9E,$DD,$CB,$00,$8E,$DD
  DEFB $CB,$00,$7E,$20,$10,$DD,$6E,$1C
  DEFB $DD,$66,$1D,$DD,$75,$1E,$DD,$74
  DEFB $1F,$DD,$36,$03,$00,$DD,$CB,$00
  DEFB $66,$28,$05,$1A,$13,$32,$A6,$05
RowDone:
  DEFB $DD,$7E,$12,$DD,$77,$13,$DD,$73 ; the row counter from the row length;
  DEFB $14,$DD,$72,$15,$1A,$3C,$C0,$DD ; bit 0 cleared when the next byte is
  DEFB $CB,$00,$86,$C9                 ; the $FF that ends the stream

; One frame of a channel's sound: its sample and ornament rows, the period with
; its slide, the volume
ChannelSound:
  XOR A
  BIT 1,(IX+$00)
  JR NZ,l_C407
  BIT 2,(IX+$00)
  JR Z,l_C407
  CALL $0408
  CALL $04E6
  BIT 3,(IX+$01)
  JR NZ,l_C3B6
  LD A,(IX+$07)
  ADD A,(IX+$0C)
  LD ($05A1),A
l_C3B6:
  LD A,(IX+$02)
  ADD A,(IX+$03)
  CP $56
  JR C,l_C3C5
  RLA
  SBC A,A
  CPL
  AND $55
l_C3C5:
  CALL $0529
  LD L,(IX+$04)
  LD H,(IX+$05)
  ADD HL,DE
  LD C,(IX+$06)
  LD B,(IX+$07)
  CALL $01FF
  ADD HL,BC
  LD B,H
  LD C,L
  LD A,(IX+$0A)
  OR A
  JR Z,l_C3FA
  JP M,$03E7
  DEC (IX+$0A)
  LD L,(IX+$06)
  LD H,(IX+$07)
  LD E,(IX+$08)
  LD D,(IX+$09)
  ADD HL,DE
  LD (IX+$06),L
  LD (IX+$07),H
l_C3FA:
  LD A,(IX+$00)
  CPL
  AND $30
  LD A,(IX+$0D)
  JR NZ,l_C407
  OR $10
l_C407:
  RET

; One row of the channel's sample: loop marks, tone offset, mixer, envelope or
; volume slide, volume
SampleStep:
  LD A,(IX+$10)
  LD C,$00
  OR A
  JR Z,l_C425
  SUB $08
  CP $08
  JR NC,l_C41E
  RRA
  SBC A,A
  SCF
  RLA
  LD C,A
  LD A,(IX+$11)
l_C41E:
  LD (IX+$10),A
  LD A,C
  CALL $04D2
l_C425:
  LD L,(IX+$18)
  LD H,(IX+$19)
  LD D,H
  LD E,L
  LD A,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CP $20
  JR C,l_C45D
  BIT 7,A
  JR NZ,l_C449
l_C43B:
  BIT 6,A
  JR NZ,l_C451
l_C43F:
  BIT 5,A
  JR Z,l_C45D
  SET 1,(IX+$00)
  JR l_C45D
l_C449:
  LD (IX+$1A),E
  LD (IX+$1B),D
  JR l_C43B
l_C451:
  BIT 3,(IX+$00)
  JR NZ,l_C43F
  LD L,(IX+$1A)
  LD H,(IX+$1B)
l_C45D:
  LD (IX+$18),L
  LD (IX+$19),H
  LD E,C
  LD C,A
  LD A,E
  RLA
  SBC A,A
  LD D,A
  LD L,(IX+$04)
  LD H,(IX+$05)
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,B
  AND $09
  LD (IX+$01),A
  LD A,B
  AND $06
  CP $02
  SET 5,(IX+$00)
  JR Z,l_C492
  RES 5,(IX+$00)
  JR C,l_C492
  SUB $05
  CALL $04D2
l_C492:
  LD A,B
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,(IX+$0E)
  JP P,$04A0
  XOR A
  CP $10
  JR C,l_C4A6
  LD A,$0F
l_C4A6:
  LD D,A
  LD B,(IX+$0F)
l_C4AA:
  ADD A,D
  DJNZ l_C4AA
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  LD (IX+$0D),A
  BIT 5,(IX+$00)
  JR Z,l_C51C
  BIT 3,(IX+$01)
  JR Z,l_C51C
  LD A,C
  ADD A,A
  ADD A,A
  ADD A,A
  SRA A
  SRA A
  SRA A
  LD HL,$05A6
  ADD A,(HL)
  LD (HL),A
  RET

; The volume slide += A, kept within -15..15
AdjustVolume:
  ADD A,(IX+$0E)
  JP P,$04DE
  CP $F1
  ADC A,$00
  JR l_C4E2

; data_C4DE
data_C4DE:
  DEFB $FE,$10,$CE,$FF

; l_C4E2
;
; Used by the routine at AdjustVolume.
l_C4E2:
  LD (IX+$0E),A
  RET

; One row of the channel's ornament: loop marks, note offset, noise offset
OrnamentStep:
  LD L,(IX+$1E)
  LD H,(IX+$1F)
  LD D,H
  LD E,L
  LD A,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CP $20
  JR C,l_C50E
  BIT 7,A
  JR NZ,l_C506
l_C4FA:
  BIT 6,A
  JR Z,l_C50E
  LD L,(IX+$20)
  LD H,(IX+$21)
  JR l_C50E
l_C506:
  LD (IX+$20),E
  LD (IX+$21),D
  JR l_C4FA
l_C50E:
  LD (IX+$1E),L
  LD (IX+$1F),H
  LD C,A
  LD A,B
  ADD A,(IX+$03)
  LD (IX+$03),A
; This entry point is used by the routine at SampleStep.
l_C51C:
  LD A,C
  AND $10
  NEG
  OR C
  ADD A,(IX+$0C)
  LD (IX+$0C),A
  RET

; DE = the AY tone period of note A
NotePeriod:
  ADD A,A
  LD D,$00
  LD E,A
  LD HL,$05C5
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  RET

; Add the player's address to the 101 words RelocTable lists, point MusicInit
; at InitPlayer and run it (the channel records and the AY image are cleared
; over this code afterwards)
Relocator:
  LD HL,$FFAA
  ADD HL,DE
  LD B,H
  LD C,L
  LD HL,$0509
  ADD HL,DE
  LD D,B
  LD E,C
l_C541:
  LD A,(HL)
  OR A
  JR Z,l_C558
  INC HL
  PUSH HL
  LD H,$00
  LD L,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  LD A,H
  LD (DE),A
  DEC DE
  LD A,L
  LD (DE),A
  POP HL
  JR l_C541
l_C558:
  LD HL,$000C
  LD (HL),$51
  DEC HL
  JP (HL)

; The relocation list: each byte the distance from the last patched word to the
; next, 0 ends it
RelocTable:
  DEFB $0F,$03,$4E,$03,$09,$03,$03,$03,$04,$03,$07,$05,$03,$03,$03,$03
  DEFB $03,$03,$05,$04,$04,$03,$0A,$03,$03,$08,$03,$04,$06,$04,$03,$04
  DEFB $03,$04,$03,$04,$04,$03,$04,$03,$04,$04,$03,$04,$03,$04,$04,$03
  DEFB $04,$03,$03,$04,$05,$04,$03,$28,$03,$1B,$0D,$03,$03,$03,$03,$03
  DEFB $03,$05,$05,$06,$03,$03,$21,$03,$1D,$0D,$35,$20,$0F,$03,$09,$1E
  DEFB $12,$07,$04,$16,$30,$20,$27,$50,$24,$03,$0F,$12,$10,$0C,$41,$6D
  DEFB $0D,$30,$09,$58,$2B,$00

; The AY tone period of each note 0-$55 (86 notes)
PeriodTable:
  DEFW $0EDC,$0E07,$0D3E,$0C80,$0BCC,$0B22,$0A82,$09EC
  DEFW $095C,$08D6,$0858,$07E0,$076E,$0704,$069F,$0640
  DEFW $05E6,$0591,$0541,$04F6,$04AE,$046B,$042C,$03F0
  DEFW $03B7,$0382,$034F,$0320,$02F3,$02C8,$02A1,$027B
  DEFW $0257,$0236,$0216,$01F8,$01DC,$01C1,$01A8,$0190
  DEFW $0179,$0164,$0150,$013D,$012C,$011B,$010B,$00FC
  DEFW $00EE,$00E0,$00D4,$00C8,$00BD,$00B2,$00A8,$009F
  DEFW $0096,$008D,$0085,$007E,$0077,$0070,$006A,$0064
  DEFW $005E,$0059,$0054,$0050,$004B,$0047,$0043,$003F
  DEFW $003C,$0038,$0035,$0032,$002F,$002D,$002A,$0028
  DEFW $0026,$0024,$0022,$0020,$001E,$001C
