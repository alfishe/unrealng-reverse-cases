; --------------------------------------------------------------------------------------------------------------------
; fuxoft-module.asm: Fuxoft's player: three entry vectors, the channel streams with calls and loops, instruments, ornaments
;
; Three vectors: MusicStart $EB50 (JP Init) points the three channels at the tune's streams (the words at $F035,
; $F037, $F039), sets their duration counters to 1, mixer bits to tone off, their call stacks and clears the
; instruments and ornaments; MusicInit $EB53 (JP Silence) turns the mixer off and writes the AY; MusicPlay $EB56 (JP
; PlayFrame) plays one frame: ChannelFrame for channels A, B and C, the mixer from their bits, WriteAY.
;
; A channel (ChannelFrame, SP on the channel's own stack): when its note's duration runs out, ReadStream reads the
; stream: a note byte $01-$7F (+ the transposition indexes PeriodTable; 0 is silence) and its duration, or a command
; $80-$8E through CommandTable (goto, call, repeat, next, noise, mixer, ornament, instrument, transposition, return,
; tie on, tie off, machine code, noise +, transposition +). Every frame the instrument's volume stream (a volume and
; its frames, or a short volume for one frame, or $80 goto) and the ornament (a note offset or a period step a frame,
; or $80 goto) shape the sound. The format is in src/res/music/README.md.
; --------------------------------------------------------------------------------------------------------------------

; JP Init: start the tune
MusicStart:
  JP Init

; JP Silence: the mixer off
MusicInit:
  JP Silence

; JP PlayFrame: play one frame
MusicPlay:
  JP PlayFrame

; Point the channels at the tune's three streams, reset their records and
; stacks, the noise to 0
;
; Used by the routine at MusicStart.
Init:
  DI
  LD HL,($F035)
  LD (ChannelRecords),HL
  LD HL,($F037)
  LD (ChannelB),HL
  LD HL,($F039)
  LD (ChannelC),HL
  LD A,$01
  LD (ChannelRecords+$0002),A
  LD (ChannelB+$0002),A
  LD (ChannelC+$0002),A
  LD A,$08
  LD (ChannelRecords+$0003),A
  LD (ChannelB+$0003),A
  LD (ChannelC+$0003),A
  LD HL,Stacks+$0020
  LD DE,$0020
  LD (StackPointers),HL
  ADD HL,DE
  LD (StackPointers+$0002),HL
  ADD HL,DE
  LD (StackPointers+$0004),HL
  LD HL,$0000
  LD (ChannelRecords+$000E),HL
  LD (ChannelB+$000E),HL
  LD (ChannelC+$000E),HL
  LD (ChannelRecords+$0010),HL
  LD (ChannelB+$0010),HL
  LD (ChannelC+$0010),HL
  XOR A
  LD (Noise),A
  RET

; 45 zero bytes (unused)
InitPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00

; The mixer off ($FF into register 7 of AYImage), then WriteAY
;
; Used by the routine at MusicInit.
Silence:
  LD A,$FF
  LD D,$07
  CALL SetAYRegister
  CALL WriteAY
  NOP
  RET

; The image of AY registers 0-13 that WriteAY sends (13 first)
AYImage:
  DEFB $E3,$FF,$F6,$03,$BD,$00,$0D,$FF
  DEFB $0A,$0D,$0A,$00,$00,$00

; The noise period (commands $84 and $8D)
Noise:
  DEFB $0D

; The channel ChannelFrame is working on: 1 A, 2 B, 3 C
Channel:
  DEFB $03

; The caller's stack pointer while ChannelFrame runs on a channel's stack
SavedSP:
  DEFW $694F

; A work word: the stream pointer while a command or a note is read
WorkPointer:
  DEFW $C45C

; Each channel's stack pointer (its calls and repeats): $EC20, $EC40, $EC60 at
; Init
StackPointers:
  DEFW $C416,$C43C,$C45C

; The three channels' stacks (32 bytes each, growing down from $EC20, $EC40,
; $EC60)
Stacks:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $94,$C7,$1C,$D8,$94,$C7,$94,$C7
  DEFB $16,$95,$D7,$C7,$B5,$C6,$68,$AA
  DEFB $5A,$AA,$FE,$07,$58,$AA,$FE,$06
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$94,$C7,$1C,$D8
  DEFB $94,$C7,$B5,$C6,$B5,$C6,$63,$8C
  DEFB $94,$C7,$B5,$C6,$05,$AB,$E6,$02
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$94,$C7,$94,$C7,$00,$94
  DEFB $94,$C7,$94,$C7,$57,$89,$94,$C7
  DEFB $57,$89,$B5,$C6,$C5,$AB,$E6,$02

; The three channels' records (20 bytes each: A $EC60, B $EC74, C $EC88; IX)
;
; +$00 / +$01 the stream pointer; +$02 the note's frames left; +$03 the mixer
; bits; +$04 / +$05 the volume stream pointer; +$06 the volume's frames left;
; +$07 / +$08 the tone period; +$09 the volume; +$0A / +$0B the instrument;
; +$0C / +$0D the ornament pointer; +$0E flags (bit 0 tie, bit 1 tied note
; running, bit 2 the note's first frame, bit 3 the ornament adds notes); +$0F
; the transposition; +$10 / +$11 the ornament; +$12 the note.
ChannelRecords:
  DEFB $FA,$AA,$05,$01,$D4,$AA,$01,$E3
  DEFB $FF,$0A,$CC,$AA,$05,$00,$00,$00
  DEFB $00,$00,$4D,$0F
ChannelB:
  DEFB $09,$AB,$0F,$08,$9D,$AB,$01,$F6
  DEFB $03,$0D,$97,$AB,$A7,$AB,$00,$00
  DEFB $A2,$AB,$19,$08
ChannelC:
  DEFB $CF,$AB,$05,$08,$D0,$AD,$01,$BD
  DEFB $00,$0A,$C4,$AD,$DA,$AD,$00,$00
  DEFB $D5,$AD,$36,$04

; The AY tone period of notes 1-84 (A-0 up)
PeriodTable:
  DEFW $0FBF,$0EDC,$0E07,$0D3D,$0C7F,$0BCC,$0B22,$0A82
  DEFW $09EB,$095D,$08D6,$0857,$07DF,$076E,$0703,$069F
  DEFW $0640,$05E6,$0591,$0541,$04F6,$04AE,$046B,$042C
  DEFW $03F0,$03B7,$0382,$034F,$0320,$02F3,$02C8,$02A1
  DEFW $027B,$0257,$0236,$0216,$01F8,$01DC,$01C1,$01A8
  DEFW $0190,$0179,$0164,$0150,$013D,$012C,$011B,$010B
  DEFW $00FC,$00EE,$00E0,$00D4,$00C8,$00BD,$00B2,$00A8
  DEFW $009F,$0096,$008D,$0085,$007E,$0077,$0070,$006A
  DEFW $0064,$005E,$0059,$0054,$004F,$004B,$0047,$0043
  DEFW $003F,$003B,$0038,$0035,$0032,$002F,$002D,$002A
  DEFW $0028,$0025,$0023,$0021

; Play one frame: ChannelFrame for A, B and C, the mixer from their bits,
; WriteAY
;
; Used by the routine at MusicPlay.
PlayFrame:
  LD IX,ChannelRecords
  LD HL,(StackPointers)
  LD A,$01
  CALL ChannelFrame
  LD (StackPointers),HL
  LD IX,ChannelB
  LD HL,(StackPointers+$0002)
  LD A,$02
  CALL ChannelFrame
  LD (StackPointers+$0002),HL
  LD IX,ChannelC
  LD HL,(StackPointers+$0004)
  LD A,$03
  CALL ChannelFrame
  LD (StackPointers+$0004),HL
  LD A,(ChannelC+$0003)
  RLCA
  LD B,A
  LD A,(ChannelB+$0003)
  OR B
  RLCA
  LD B,A
  LD A,(ChannelRecords+$0003)
  OR B
  LD D,$07
  CALL SetAYRegister

; Write AYImage to AY registers 13 down to 0
;
; Used by the routine at Silence.
WriteAY:
  LD D,$0D
  LD HL,AYImage+$000D
l_ED8A:
  LD A,D
  LD BC,$FFFD
  OUT (C),A
  LD A,(HL)
  LD B,$BF
  OUT (C),A
  DEC HL
  DEC D
  JP P,l_ED8A
  RET

; AYImage[D] = A
;
; Used by the routines at Silence, PlayFrame and ChannelFrame.
SetAYRegister:
  LD BC,AYImage
  LD L,D
  LD H,$00
  ADD HL,BC
  LD (HL),A
  RET

; Back to the caller's stack (SavedSP) with HL = the channel's stack pointer
;
; Used by the routine at ChannelFrame.
ChannelFrameEnd:
  LD (WorkPointer),SP
  LD HL,(WorkPointer)
  LD SP,(SavedSP)
  RET

; One frame of the channel at IX (A its number, HL its stack pointer): the
; stream, the volume, the ornament, the AY registers
;
; Used by the routine at PlayFrame.
ChannelFrame:
  LD (SavedSP),SP
  LD SP,HL
  LD (Channel),A
  DEC (IX+$02)
  JP Z,ReadStream
; This entry point is used by the routine at ReadStream.
l_EDBE:
  DEC (IX+$06)
  JR NZ,l_EDF9
l_EDC3:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD A,(HL)
  CP $80
  JR NZ,l_EDDA
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$04),E
  LD (IX+$05),D
  JR l_EDC3
l_EDDA:
  CP $1E
  JR C,l_EDEA
  SUB $32
  LD (IX+$09),A
  LD (IX+$06),$01
  INC HL
  JR l_EDF3
l_EDEA:
  LD (IX+$09),A
  INC HL
  LD A,(HL)
  LD (IX+$06),A
  INC HL
l_EDF3:
  LD (IX+$04),L
  LD (IX+$05),H
l_EDF9:
  LD A,(IX+$07)
  OR (IX+$08)
  JP Z,l_EE82
  BIT 2,(IX+$0E)
  JP NZ,l_EE82
  LD L,(IX+$0C)
  LD H,(IX+$0D)
l_EE0F:
  LD A,(HL)
  INC HL
  LD (IX+$0C),L
  LD (IX+$0D),H
  CP $80
  JR NZ,l_EE21
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JR l_EE0F
l_EE21:
  CP $82
  JP NZ,l_EE2D
  SET 3,(IX+$0E)
  JP l_EE0F
l_EE2D:
  CP $83
  JP NZ,l_EE39
  RES 3,(IX+$0E)
  JP l_EE0F
l_EE39:
  CP $84
  JP NZ,l_EE49
  LD A,$09
  XOR (IX+$03)
  LD (IX+$03),A
  JP l_EE0F
l_EE49:
  BIT 3,(IX+$0E)
  JP Z,l_EE6B
  ADD A,(IX+$12)
  LD (IX+$12),A
  DEC A
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,PeriodTable
  ADD HL,DE
  LD A,(HL)
  LD (IX+$07),A
  INC HL
  LD A,(HL)
  LD (IX+$08),A
  JP l_EE82
l_EE6B:
  LD E,A
  LD D,$00
  LD L,(IX+$07)
  LD H,(IX+$08)
  AND $80
  JP Z,l_EE7B
  LD D,$FF
l_EE7B:
  ADD HL,DE
  LD (IX+$07),L
  LD (IX+$08),H
; This entry point is used by the routine at ReadStream.
l_EE82:
  LD A,(Noise)
  LD D,$06
  CALL SetAYRegister
  RES 2,(IX+$0E)
  LD A,(Channel)
  ADD A,$07
  LD D,A
  LD A,(IX+$07)
  OR (IX+$08)
  JR Z,l_EE9F
  LD A,(IX+$09)
l_EE9F:
  CALL SetAYRegister
  LD A,(Channel)
  DEC A
  ADD A,A
  LD D,A
  LD A,(IX+$07)
  CALL SetAYRegister
  INC D
  LD A,(IX+$08)
  CALL SetAYRegister
  JP ChannelFrameEnd

; The stream pointer (+$00) = HL
;
; Used by the routines at ReadStream, CommandRepeat, CommandNoise,
; CommandMixer, CommandInstrument, CommandTranspose, CommandReturn,
; CommandOrnament, CommandTie, CommandUntie, CommandCode, CommandNoiseAdd and
; CommandTransposeAdd.
SaveStream:
  LD (IX+$00),L
  LD (IX+$01),H
  RET

; Read the stream: a note and its duration, or a command (CommandTable)
;
; Used by the routines at ChannelFrame, CommandGoto, CommandCall,
; CommandRepeat, CommandNext, CommandNoise, CommandMixer, CommandInstrument,
; CommandTranspose, CommandReturn, CommandOrnament, CommandTie, CommandUntie,
; CommandNoiseAdd and CommandTransposeAdd.
ReadStream:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(HL)
  INC HL
  CALL SaveStream
  BIT 7,A
  JP NZ,StreamCommand
  LD (WorkPointer),HL
  OR A
  JR Z,l_EEF0
  ADD A,(IX+$0F)
  LD (IX+$12),A
  RES 3,(IX+$0E)
  DEC A
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,PeriodTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,(WorkPointer)
  JR l_EEF3
l_EEF0:
  LD DE,$0000
l_EEF3:
  LD A,(HL)
  INC HL
  CALL SaveStream
  LD (IX+$02),A
  LD (IX+$07),E
  LD (IX+$08),D
  LD A,(IX+$10)
  LD (IX+$0C),A
  LD A,(IX+$11)
  LD (IX+$0D),A
  SET 2,(IX+$0E)
  BIT 1,(IX+$0E)
  JP NZ,l_EDBE
  BIT 0,(IX+$0E)
  JP Z,l_EF23
  SET 1,(IX+$0E)
l_EF23:
  LD C,(IX+$0A)
  LD B,(IX+$0B)
  LD A,(BC)
  LD (IX+$09),A
  INC BC
  LD A,(BC)
  INC BC
  LD (IX+$06),A
  LD (IX+$04),C
  LD (IX+$05),B
  JP l_EE82

; A command byte $80-$8E: jump through CommandTable
;
; Used by the routine at ReadStream.
StreamCommand:
  AND $7F
  LD (WorkPointer),HL
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,CommandTable
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  PUSH HL
  LD HL,(WorkPointer)
  RET

; The 15 command routines ($80-$8E)
CommandTable:
  DEFW CommandGoto,CommandCall,CommandRepeat,CommandNext,CommandNoise,CommandMixer,CommandOrnament,CommandInstrument
  DEFW CommandTranspose,CommandReturn,CommandTie,CommandUntie,CommandCode,CommandNoiseAdd,CommandTransposeAdd

; $80 w: goto
CommandGoto:
  LD A,(HL)
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  LD (IX+$01),A
  JP ReadStream

; $81 w: call a sub-stream (the return address on the channel's stack)
CommandCall:
  LD A,(HL)
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  LD (IX+$01),A
  INC HL
  PUSH HL
  JP ReadStream

; $82 n: repeat up to $83 n times
CommandRepeat:
  LD B,(HL)
  PUSH BC
  INC HL
  PUSH HL
  CALL SaveStream
  JP ReadStream

; $83: the end of a repeat
CommandNext:
  POP DE
  POP BC
  DJNZ l_EF9B
  JP ReadStream
l_EF9B:
  PUSH BC
  PUSH DE
  LD (IX+$00),E
  LD (IX+$01),D
  JP ReadStream

; $84 n: the noise period
CommandNoise:
  LD A,(HL)
  INC HL
  LD (Noise),A
  CALL SaveStream
  JP ReadStream

; $85 n: the channel's mixer bits
CommandMixer:
  LD A,(HL)
  INC HL
  CALL SaveStream
  LD (IX+$03),A
  JP ReadStream

; $87 w: the instrument
CommandInstrument:
  LD A,(HL)
  LD (IX+$0A),A
  INC HL
  LD A,(HL)
  LD (IX+$0B),A
  INC HL
  CALL SaveStream
  JP ReadStream

; $88 n: the transposition
CommandTranspose:
  LD A,(HL)
  INC HL
  CALL SaveStream
  LD (IX+$0F),A
  JP ReadStream

; $89: return from a call
CommandReturn:
  POP HL
  CALL SaveStream
  JP ReadStream

; $86 w: the ornament
CommandOrnament:
  LD A,(HL)
  LD (IX+$10),A
  INC HL
  LD A,(HL)
  LD (IX+$11),A
  INC HL
  CALL SaveStream
  JP ReadStream

; $8A: tie on (a note keeps the volume stream running)
CommandTie:
  SET 0,(IX+$0E)
  RES 1,(IX+$0E)
  CALL SaveStream
  JP ReadStream

; $8B: tie off
CommandUntie:
  RES 0,(IX+$0E)
  RES 1,(IX+$0E)
  CALL SaveStream
  JP ReadStream

; $8C w: call machine code
CommandCode:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  CALL SaveStream
  LD BC,ReadStream
  PUSH BC
  PUSH DE
  RET

; $8D n: noise += n (AND the noise mask: the operand at $F01C, $1F or $0F in
; the variants)
CommandNoiseAdd:
  LD A,(Noise)
  ADD A,(HL)
  AND $1F
  LD (Noise),A
  INC HL
  CALL SaveStream
  JP ReadStream

; $8E n: transposition += n
CommandTransposeAdd:
  LD A,(HL)
  ADD A,(IX+$0F)
  LD (IX+$0F),A
  INC HL
  CALL SaveStream
  JP ReadStream
