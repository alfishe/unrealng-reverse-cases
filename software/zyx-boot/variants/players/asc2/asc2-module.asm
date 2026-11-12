; --------------------------------------------------------------------------------------------------------------------
; asc2-module.asm: The ASC Sound Master player (later command set): init, frame, pattern reader, samples, ornaments, AY
;
; Three entry points, as the menu's own ASC player: MusicInit $C00B (JP InitPlayer) clears the channels and reads the
; module's header at Module into the player's self-modified operands; MusicPlay $C00E (JP PlayFrame) plays one frame;
; MusicStop $C011 (JP Silence) silences the AY. A frame: DelayCounter counts the module's delay; on a row frame a new
; position starts when every channel's stream has ended (NextPosition), then ChannelRow reads each channel's stream;
; every frame ChannelSound turns each channel's sample and ornament rows into its period, volume and noise, then the
; mixer and WriteAY.
;
; The pattern stream (ChannelRow): $00-$55 a note (in envelope mode the envelope period byte follows), $56-$5D a hold,
; $5E release, $5F off; commands before it: $60-$9F the row length, $A0-$BF the sample, $C0-$DF the ornament, $E0
; envelope mode, $E1-$EF the volume, $F0 n the noise base, $F1-$FF the envelope shape. Sample rows: bit 1 of the third
; byte alone is the envelope, bits 1-2 = 2 the volume +1 a row, = 4 the volume -1 a row (SampleRow).
; --------------------------------------------------------------------------------------------------------------------

; The compiled player's header: the init, play, AY-write and AY-register
; addresses
PlayerVectors:
  DEFW MusicInit,MusicPlay,WriteAY,AYRegisters

; Three more bytes of the compilation's header
PlayerHeaderBytes:
  DEFB $00,$80,$4C

; Set the player up for the tune (JP InitPlayer)
MusicInit:
  JP InitPlayer

; Play one frame of the tune (JP PlayFrame)
MusicPlay:
  JP PlayFrame

; Silence the AY (JP Silence)
MusicStop:
  JP Silence

; The compiler's "ASM COMPILATION OF " + the tune's title + " BY " + its author
; (each variant its own)
PlayerText:
  DEFM "ASM COMPILATION OF AXEL-FORCE           BY OLEG KRASNOBAEV OKO "

; Clear the channels, read the module's header into the player's operands,
; silence the AY
;
; Clears ChannelA to the end of ChannelC (78 bytes), the position
; (PositionOp+1) to 0, the three row counters (+$0B) and DelayCounter to 1;
; then the delay into DelayOp+1, the three offsets plus Module into
; PatternTableOp+1, CommandSample+1 and CommandOrnament+1, the number of
; positions into PositionCountOp+1 and the positions' address into
; NextPosition+1.
InitPlayer:
  XOR A
  LD HL,ChannelA
  LD DE,ChannelA+$0001
  LD BC,$004D
  LD (HL),A
  LDIR
  LD (PositionOp+$0001),A
  LD (ChannelA+$000B),A
  LD (ChannelB+$000B),A
  LD (ChannelC+$000B),A
  INC A
  LD (DelayCounter),A
  LD DE,Module
  LD B,D
  LD C,E
  LD A,(DE)
  INC DE
  LD (DelayOp+$0001),A
  CALL ReadOffsetDE
  LD (PatternTableOp+$0001),HL
  CALL ReadOffsetDE
  LD (CommandSample+$0001),HL
  CALL ReadOffsetDE
  LD (CommandOrnament+$0001),HL
  LD A,(DE)
  INC DE
  LD (PositionCountOp+$0001),A
  LD (NextPosition+$0001),DE

; Clear the AY register image, mixer $FF, write all 14 registers
;
; Used by the routine at MusicStop.
Silence:
  XOR A
  LD HL,AYRegisters
  LD DE,AYRegisters+$0001
  LD BC,$000D
  LD (HL),A
  LDIR
  DEC A
  LD (AYMixer),A
  JP WriteAY

; Channel A's record (26 bytes)
;
; +$00 flags (bit 0 the stream goes on, bit 1 the sample ended, bit 2 sound on,
; bit 3 released, bit 4 envelope mode, bit 5 envelope this frame); +$01 the
; mixer bits; +$02 the note; +$03 / +$04 the tone offset; +$05 the noise base;
; +$06 the noise; +$07 the volume; +$08 the volume slide; +$09 the channel
; volume; +$0A the row length; +$0B the row counter; +$0C / +$0D the stream
; pointer; +$0E / +$0F the sample; +$10 / +$11 the sample row; +$12 / +$13 the
; sample's loop row; +$14 / +$15 the ornament; +$16 / +$17 the ornament row;
; +$18 / +$19 the ornament's loop row.
ChannelA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Channel B's record (26 bytes, as ChannelA)
ChannelB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Channel C's record (26 bytes, as ChannelA)
ChannelC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; The image of AY registers 0-13 that WriteAY sends
AYRegisters:
  DEFB $00,$00,$00,$00,$00,$00
AYNoise:
  DEFB $00                ; register 6: the noise period
AYMixer:
  DEFB $00,$00,$00,$00    ; register 7: the mixer
AYEnvelopePeriod:
  DEFB $00,$00            ; register 11: the envelope period's low byte
AYEnvelopeShape:
  DEFB $00                ; register 13: the envelope shape; $FF: no new shape,
                          ; not written

; The channel ChannelSound is working on: 0 A, 1 B, 2 C
CurrentChannel:
  DEFB $00

; Frames left to the next row
DelayCounter:
  DEFB $01

; Play one frame: on a row frame the next position and the channels' rows, then
; each channel's sound, the mixer, the AY
;
; Used by the routine at MusicPlay.
PlayFrame:
  LD HL,DelayCounter
  DEC (HL)
  JR NZ,PlayFrameSound
DelayOp:
  LD (HL),$06             ; LD (HL),n: n = the module's delay (InitPlayer
                          ; writes it)
  LD A,(ChannelA)
  LD HL,ChannelB
  OR (HL)
  LD HL,ChannelC
  OR (HL)
  BIT 0,A
  CALL Z,NextPosition
  LD IX,ChannelA
  CALL ChannelRow
  LD IX,ChannelB
  CALL ChannelRow
  LD IX,ChannelC
  CALL ChannelRow
PlayFrameSound:
  XOR A                   ; every frame: the three channels' sound and the
                          ; mixer
  LD IX,ChannelA
  CALL ChannelSound
  LD A,$01
  LD IX,ChannelB
  CALL ChannelSound
  LD A,$02
  LD IX,ChannelC
  CALL ChannelSound
  LD A,(ChannelC+$0001)
  RLCA
  LD B,A
  LD A,(ChannelB+$0001)
  OR B
  RLCA
  LD B,A
  LD A,(ChannelA+$0001)
  OR B
  LD E,$07
  CALL SetAYRegister

; Write AYRegisters to the AY: registers 13 (when set) or 12 down to 0
;
; Used by the routine at Silence.
WriteAY:
  LD HL,AYEnvelopeShape
  LD DE,$FFBF
  LD C,$FD
  LD A,(HL)
  INC A
  LD A,$0D
  JR NZ,l_C172
  DEC A
  DEC HL
l_C172:
  LD B,D
  OUT (C),A
  LD B,E
  OUTD
  DEC A
  JP P,l_C172
  LD (AYEnvelopeShape),A
  RET

; AYRegisters[E] = A
;
; Used by the routines at PlayFrame and ChannelSound.
SetAYRegister:
  PUSH HL
  PUSH DE
  LD HL,AYRegisters
  LD D,$00
  ADD HL,DE
  LD (HL),A
  POP DE
  POP HL
  RET

; HL = BC + the word at (DE), DE + 2
;
; Used by the routines at InitPlayer and NextPosition.
ReadOffsetDE:
  EX DE,HL

; HL = BC + the word at (HL); DE = HL + 2
;
; Used by the routine at NextPosition.
ReadOffset:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  RET

; Start the next position: the three channels' streams of its pattern (LD HL,n:
; n = the positions)
;
; Used by the routine at PlayFrame.
NextPosition:
  LD HL,$0000
PositionOp:
  LD DE,$0000             ; LD DE,n: n = the position to start (written here; 0
                          ; by InitPlayer)
  ADD HL,DE
  INC E
  LD A,E
PositionCountOp:
  CP $01                  ; CP n: n = the number of positions (InitPlayer
                          ; writes it)
  SBC A,A
  AND E
  LD (PositionOp+$0001),A
  LD A,(HL)
  ADD A,A
  LD E,A
  ADD A,A
  ADD A,E
  LD H,D
  LD L,A
PatternTableOp:
  LD BC,$0000             ; LD BC,n: n = the pattern table (InitPlayer writes
                          ; it)
  ADD HL,BC
  CALL ReadOffset
  LD (ChannelA+$000C),HL
  CALL ReadOffsetDE
  LD (ChannelB+$000C),HL
  CALL ReadOffsetDE
  LD (ChannelC+$000C),HL
  LD HL,ChannelA
  SET 0,(HL)
  LD HL,ChannelB
  SET 0,(HL)
  LD HL,ChannelC
  SET 0,(HL)
  RET

; One row of a channel: when its row counter runs out, read the commands and
; the next event of its stream
;
; Used by the routine at PlayFrame.
ChannelRow:
  DEC (IX+$0B)
  RET P
  LD E,(IX+$0C)
  LD D,(IX+$0D)
ChannelRowLoop:
  LD A,(DE)               ; the next byte: an event ($00-$5F) or a command
                          ; ($60-$FF; each returns here)
  INC DE
  CP $60
  JR C,RowEvent
  LD HL,ChannelRowLoop
  PUSH HL
  SUB $F0
  JR NC,CommandShape
  ADD A,$10
  JR C,CommandVolume
  ADD A,$20
  JR C,CommandOrnament
  ADD A,$20
  JR C,CommandSample
  ADD A,$40
  LD (IX+$0A),A
  RET
CommandSample:
  LD BC,$0000             ; $A0-$BF: the sample (LD BC,n: n = the sample table,
                          ; InitPlayer writes it)
  CALL TableEntry
  LD (IX+$0E),L
  LD (IX+$0F),H
  RET
CommandOrnament:
  LD BC,$0000             ; $C0-$DF: the ornament (LD BC,n: n = the ornament
                          ; table, InitPlayer writes it)
  CALL TableEntry
  LD (IX+$14),L
  LD (IX+$15),H
  RET

; TableEntry
;
; Used by the routine at ChannelRow.
TableEntry:
  ADD A,A                 ; HL = BC + the word at BC + 2A (a sample or ornament
                          ; address from its table)
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
  RES 4,(IX+$00)          ; $E0: envelope mode; $E1-$EF: the channel volume
                          ; 1-15
  LD (IX+$09),A
  RET NZ
  SET 4,(IX+$00)
  LD (IX+$09),$0F
  RET
; This entry point is used by the routine at ChannelRow.
CommandShape:
  JR Z,l_C237             ; $F1-$FF: the envelope shape; $F0 n: the noise base
                          ; n
  LD (AYEnvelopeShape),A
  RET
l_C237:
  LD A,(DE)
  INC DE
  LD (IX+$05),A
  RET
; This entry point is used by the routine at ChannelRow.
RowEvent:
  CP $56                  ; $56-$5D hold, $5E release, $5F off, else a note
  JR C,RowNote
  CP $5E
  JR C,RowDone
  JR Z,RowRelease
  RES 2,(IX+$00)
  JR RowDone
RowRelease:
  SET 3,(IX+$00)          ; $5E: released (bit 3)
  JR RowDone
RowNote:
  SET 2,(IX+$00)          ; a note: sound on, the note, the noise base, tone
                          ; offset 0, the sample and the ornament from their
                          ; start
  RES 3,(IX+$00)
  LD (IX+$02),A
  LD A,(IX+$05)
  LD (IX+$06),A
  XOR A
  LD (IX+$08),A
  LD (IX+$03),A
  LD (IX+$04),A
  LD L,(IX+$0E)
  LD H,(IX+$0F)
  LD (IX+$10),L
  LD (IX+$11),H
  RES 1,(IX+$00)
  LD L,(IX+$14)
  LD H,(IX+$15)
  LD (IX+$16),L
  LD (IX+$17),H
  BIT 4,(IX+$00)
  JR Z,RowDone
  LD A,(DE)
  INC DE
  LD (AYEnvelopePeriod),A
RowDone:
  LD A,(IX+$0A)           ; the row counter from the row length; bit 0 cleared
                          ; when the next byte is the $FF that ends the stream
  LD (IX+$0B),A
  LD (IX+$0C),E
  LD (IX+$0D),D
  LD A,(DE)
  INC A
  RET NZ
  RES 0,(IX+$00)
  RET

; One frame of a channel's sound: its sample and ornament rows, the period, the
; volume, the noise
;
; Used by the routine at PlayFrame.
ChannelSound:
  LD (CurrentChannel),A
  XOR A
  BIT 1,(IX+$00)
  JR NZ,l_C306
  BIT 2,(IX+$00)
  JR Z,l_C306
  CALL SampleStep
  CALL OrnamentStep
  BIT 3,(IX+$01)
  JR NZ,l_C2CB
  LD A,(IX+$06)
  LD (AYNoise),A
l_C2CB:
  LD A,(IX+$02)
  CP $56
  JR C,l_C2D7
  RLA
  SBC A,A
  CPL
  AND $55
l_C2D7:
  ADD A,A
  LD B,$00
  LD C,A
  LD HL,PeriodTable
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD L,(IX+$03)
  LD H,(IX+$04)
  ADD HL,DE
  LD A,(CurrentChannel)
  ADD A,A
  LD E,A
  LD A,L
  CALL SetAYRegister
  INC E
  LD A,H
  AND $0F
  CALL SetAYRegister
  LD A,(IX+$00)
  CPL
  AND $30
  LD A,(IX+$07)
  JR NZ,l_C306
  OR $10
l_C306:
  LD D,A
  LD A,(CurrentChannel)
  ADD A,$08
  LD E,A
  LD A,D
  JP SetAYRegister

; One row of the channel's sample: loop marks, tone offset, mixer, envelope or
; volume slide, volume
;
; Used by the routine at ChannelSound.
SampleStep:
  LD L,(IX+$10)
  LD H,(IX+$11)
  LD D,H
  LD E,L
  LD A,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CP $20
  JR C,SampleRow
  BIT 7,A
  JR NZ,l_C335
l_C327:
  BIT 6,A
  JR NZ,l_C33D
l_C32B:
  BIT 5,A
  JR Z,SampleRow
  SET 1,(IX+$00)
  JR SampleRow
l_C335:
  LD (IX+$12),E
  LD (IX+$13),D
  JR l_C327
l_C33D:
  BIT 3,(IX+$00)
  JR NZ,l_C32B
  LD L,(IX+$12)
  LD H,(IX+$13)
SampleRow:
  LD (IX+$10),L           ; the next row kept; the tone delta, the mixer, the
                          ; envelope or the volume slide
  LD (IX+$11),H
  LD E,C
  LD C,A
  LD A,E
  RLA
  SBC A,A
  LD D,A
  LD L,(IX+$03)
  LD H,(IX+$04)
  ADD HL,DE
  LD (IX+$03),L
  LD (IX+$04),H
  LD A,B
  AND $09
  LD (IX+$01),A
  LD A,B
  AND $06
  CP $02
  SET 5,(IX+$00)
  JR Z,SampleVolume
  RES 5,(IX+$00)
  JR C,SampleVolume
  SUB $05
  ADD A,(IX+$08)
  JP P,l_C387
  CP $F1
  ADC A,$00
  JR l_C38B
l_C387:
  CP $10
  ADC A,$FF
l_C38B:
  LD (IX+$08),A
SampleVolume:
  LD A,B                  ; the row's volume plus the slide, scaled by the
                          ; channel volume
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,(IX+$08)
  JP P,l_C39C
  XOR A
l_C39C:
  CP $10
  JR C,l_C3A2
  LD A,$0F
l_C3A2:
  LD D,A
  LD B,(IX+$09)
l_C3A6:
  ADD A,D
  DJNZ l_C3A6
  AND $F0
  RRCA
  RRCA
  RRCA
  RRCA
  LD (IX+$07),A
  JR AddNoise

; One row of the channel's ornament: loop marks, note offset, noise offset
;
; Used by the routine at ChannelSound.
OrnamentStep:
  LD L,(IX+$16)
  LD H,(IX+$17)
  LD D,H
  LD E,L
  LD A,(HL)
  INC HL
  LD B,(HL)
  INC HL
  CP $20
  JR C,l_C3DC
  BIT 7,A
  JR NZ,l_C3D4
l_C3C8:
  BIT 6,A
  JR Z,l_C3DC
  LD L,(IX+$18)
  LD H,(IX+$19)
  JR l_C3DC
l_C3D4:
  LD (IX+$18),E
  LD (IX+$19),D
  JR l_C3C8
l_C3DC:
  LD (IX+$16),L
  LD (IX+$17),H
  LD C,A
  LD A,B
  ADD A,(IX+$02)
  LD (IX+$02),A

; The noise period += the row's signed 5-bit noise delta
;
; Used by the routine at SampleStep.
AddNoise:
  LD A,C
  AND $10
  NEG
  OR C
  ADD A,(IX+$06)
  AND $1F
  LD (IX+$06),A
  RET

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

; Two bytes after the table
PeriodPad:
  DEFB $00,$00
