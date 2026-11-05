; --------------------------------------------------------------------------------------------------------------------
; starkos-frame.asm: every frame: the three instruments, the track and instrument line formats
;
; PlayInstruments runs every frame after Play's line work. For each channel (A, B, C: three copies of the same code)
; it adds the track's pitch slide to the pitch sum, sets LinePitch, IXL = the note and IY = the channel's tone
; register in SendRegisters' cache, and calls InstrumentLine with HL = the instrument's line and A = the instrument's
; frame counter. InstrumentLine writes the channel's period, volume (and noise, envelope) into the cache and returns
; IXH = the channel's mixer bits (bit 0 tone off, bit 3 noise off). The counter then runs up to the instrument's
; speed; at it the next line, and at the instrument's end its loop address (a looping instrument) or instrument 0's
; silent line with speed 255 (a one-shot). The three mixer pairs make R7 and SendRegisters (starkos-output.asm) sends
; what changed.
;
; ReadTrackLine is the track format (a note, a note with volume / instrument / slide, a wait, a rest to the pattern's
; end, volume, slide, off, a digidrum) and InstrumentLine the instrument line format (the volume, arpeggio, pitch,
; noise, a fixed period, the hardware envelope with its period from the tone's or the tone's from the envelope's).
; Both are in tools/sk10.py's docstring with the byte layout; the text src/res/music/sk10.txt writes each line in
; those terms.
; --------------------------------------------------------------------------------------------------------------------

; every frame: the instruments of channels A, B, C, the mixer, then
; SendRegisters
;
; HL' = Retrigger (the instruments' hardware lines OR their retrigger bit into
; it), D' = the channel's attenuation. Per channel: PitchSum += Slide;
; LinePitch = PitchSum; InstrumentLine(HL = the instrument line, A = the
; counter, IXL = the note, IY = the channel's period cache); then the counter:
; below Speed + 1, the same line next frame; at it, the next line (InstrPointer
; = the line's end), or at InstrEnd the loop. Ends in JP SendRegisters with A =
; R7 (IXH of C, B, A: A's bits 0 and 3, B's 1 and 4, C's 2 and 5). 566 runs.
PlayInstruments:
  LD HL,Retrigger+$0001
ChanAAtten:
  LD D,$00                ; ChanAAtten+1: track A's attenuation, subtracted
                          ; from every instrument volume
  EXX
ChanAPitch:
  LD HL,$0000             ; ChanAPitch+1: the pitch sum (the slides of the
                          ; frames so far)
ChanASlide:
  LD DE,$0000             ; ChanASlide+1: the track's slide a frame
  ADD HL,DE
  LD (ChanAPitch+$0001),HL
  LD (LinePitch+$0001),HL ; LinePitch: half of it is added to the period
  LD A,(TrackANote+2)
  LD IXL,A
ChanAInstrPointer:
  LD HL,$0000             ; ChanAInstrPointer+1: the instrument's line
  LD IY,AYReg0+$0001      ; IY = AYReg0+1: channel A's period low byte (+$1B
                          ; the high byte, +$36 the volume)
  LD A,(ChanAInstrCounter+1); A = the counter: InstrumentLine retriggers
                                 ; the envelope at 0 only
  CALL InstrumentLine
  EX DE,HL                ; DE = the line's end
ChanAInstrCounter:
  LD A,$00                ; ChanAInstrCounter+1: frames of this line so far
ChanAInstrSpeed:
  CP $00                  ; ChanAInstrSpeed+1: the instrument's speed (frames a
                          ; line - 1; 255 holds)
  JR Z,ChanAInstrEnd
  INC A                   ; not yet
  JR ChanASetCounter
ChanAInstrEnd:
  LD HL,$0000             ; ChanAInstrEnd+1: the instrument's end
  XOR A
  SBC HL,DE
  JR NZ,ChanANextLine
ChanAInstrLoop:
  LD DE,$0000             ; ChanAInstrLoop+1: its loop address
ChanAInstrLoops:
  OR A                    ; OR A: a one-shot, SCF: it loops
  JR C,ChanANextLine
ChanAZeroEnd:
  LD HL,$0000             ; ChanAZeroEnd+1: instrument 0's end (Init): a
                          ; one-shot ends in instrument 0's line
  LD (ChanAInstrEnd+$0001),HL
  DEC A                   ; the speed 255: that line holds
  LD (ChanAInstrSpeed+$0001),A
  INC A
ChanANextLine:
  LD (ChanAInstrPointer+$0001),DE ; the next line
ChanASetCounter:
  LD (ChanAInstrCounter+$0001),A ; the counter
  LD A,IXH                ; channel A's mixer bits into MixerA
  LD (MixerA+$0001),A
  EXX                     ; channel B, as channel A
ChanBAtten:
  LD D,$00
  EXX
ChanBPitch:
  LD HL,$0000
ChanBSlide:
  LD DE,$0000
  ADD HL,DE
  LD (ChanBPitch+$0001),HL
  LD (LinePitch+$0001),HL
  LD A,(TrackBNote+2)
  LD IXL,A
ChanBInstrPointer:
  LD HL,$0000
  LD IY,AYReg2+$0001      ; IY = AYReg2+1: channel B's period
  LD A,(ChanBInstrCounter+1)
  CALL InstrumentLine
  EX DE,HL
ChanBInstrCounter:
  LD A,$00
ChanBInstrSpeed:
  CP $00
  JR Z,ChanBInstrEnd
  INC A
  JR ChanBSetCounter
ChanBInstrEnd:
  LD HL,$0000
  XOR A
  SBC HL,DE
  JR NZ,ChanBNextLine
ChanBInstrLoop:
  LD DE,$0000
ChanBInstrLoops:
  OR A
  JR C,ChanBNextLine
ChanBZeroEnd:
  LD HL,$0000
  LD (ChanBInstrEnd+$0001),HL
  DEC A
  LD (ChanBInstrSpeed+$0001),A
  INC A
ChanBNextLine:
  LD (ChanBInstrPointer+$0001),DE
ChanBSetCounter:
  LD (ChanBInstrCounter+$0001),A
  LD A,IXH                ; channel B's mixer bits into MixerB
  LD (MixerB+$0001),A
  EXX                     ; channel C, as channel A
ChanCAtten:
  LD D,$00
  EXX
ChanCPitch:
  LD HL,$0000
ChanCSlide:
  LD DE,$0000
  ADD HL,DE
  LD (ChanCPitch+$0001),HL
  LD (LinePitch+$0001),HL
  LD A,(TrackCNote+2)
  LD IXL,A
ChanCInstrPointer:
  LD HL,$0000
  LD IY,AYReg4+$0001      ; IY = AYReg4+1: channel C's period
  LD A,(ChanCInstrCounter+1)
  CALL InstrumentLine
  EX DE,HL
ChanCInstrCounter:
  LD A,$00
ChanCInstrSpeed:
  CP $00
  JR Z,ChanCInstrEnd
  INC A
  JR ChanCSetCounter
ChanCInstrEnd:
  LD HL,$0000
  XOR A
  SBC HL,DE
  JR NZ,ChanCNextLine
ChanCInstrLoop:
  LD DE,$0000
ChanCInstrLoops:
  OR A
  JR C,ChanCNextLine
ChanCZeroEnd:
  LD HL,$0000
  LD (ChanCInstrEnd+$0001),HL
  DEC A
  LD (ChanCInstrSpeed+$0001),A
  INC A
ChanCNextLine:
  LD (ChanCInstrPointer+$0001),DE
ChanCSetCounter:
  LD (ChanCInstrCounter+$0001),A
  LD A,IXH                ; channel C's bits
  SLA A
MixerB:
  OR $00                  ; MixerB+1: channel B's mixer bits
  RLA                     ; one more place
MixerA:
  OR $00                  ; MixerA+1: channel A's mixer bits
  JP SendRegisters        ; R7 in A

; read one line of a track
;
; Input: HL = the track, B = the channel (1-3), C = the attenuation, D = the
; transposition, E = the instrument, IXL = the note. Byte bit 0 set: a note
; (bits 1-7), nothing else. Bit 0 clear, bits 1-7 below $60: a note with a
; second byte: bit 0 the attenuation follows in bits 1-4, bit 7 an instrument
; byte follows, bit 6 a slide byte. $60 + k: a command: 0 a wait byte, 1 a rest
; to the pattern's end (wait 255), 2 the attenuation byte, 3 the slide byte, 4
; both, 5 off (instrument 0), 6 a digidrum byte (then off), 7-31 a wait of k -
; 7 lines. Output: HL past the line, IXL = the note + the transposition, C, E,
; IYH = 0 a new note (the instrument restarts) or 1, IYL = the empty lines
; after this one, HL' = the slide; returns with the alternate set in use. 142
; runs in the intro window (35 + 12 + 95 for tracks A, B, C).
ReadTrackLine:
  LD A,(HL)
  INC HL
  SRL A
  JR C,TrackNoteOnly      ; bit 0 set: a note alone
  CP $60                  ; $60 and above: a command
  JR NC,TrackCommand
  LD IYH,$00              ; a new note
  ADD A,D
  LD IXL,A                ; the second byte
  LD B,(HL)
  INC HL
  LD A,B
  RRA
  JR NC,TrackTestInstr
  AND $0F
  LD C,A
TrackTestInstr:
  RL B                    ; bit 7: an instrument byte
  JR NC,TrackTestSlide
  LD E,(HL)
  INC HL
TrackTestSlide:
  RL B                    ; bit 6: a slide byte
  JR NC,NoSlide
TrackSlide:
  LD A,(HL)               ; the slide byte, sign-extended into HL'
  INC HL
  EXX
  LD L,A
  LD H,$00
  RLA
  JR NC,SlideDone
  DEC H
SlideDone:
  LD IYL,$00
  RET
NoSlide:
  EXX                     ; HL' = 0, no wait
  LD HL,$0000
  LD IYL,$00
  RET
TrackNoteOnly:
  LD IYH,$00              ; a one-byte note
  ADD A,D
  LD IXL,A
  JR NoSlide
TrackCommand:
  LD IYH,$01              ; IYH = 1: no new note
  SUB $60
  JR Z,CmdWaitByte
  DEC A
  JR Z,CmdRest
  DEC A
  JR Z,CmdVolume
  DEC A
  JR Z,TrackSlide
  DEC A
  JR Z,CmdVolumeSlide
  DEC A
  JR Z,CmdOff
  DEC A
  JR Z,CmdDrum
  DEC A
  EXX
  LD IYL,A
  LD HL,$0000
  RET
CmdWaitByte:
  LD A,(HL)               ; $C0 n: n empty lines
  INC HL
  EXX
  LD IYL,A
  LD HL,$0000
  RET
CmdVolume:
  LD C,(HL)               ; $C4 n: the attenuation
  INC HL
  EXX
  LD IYL,$00
  LD HL,$0000
  RET
CmdVolumeSlide:
  LD C,(HL)               ; $C8 n s: the attenuation and the slide
  INC HL
  JR TrackSlide
CmdRest:
  LD IYL,$FF              ; $C2: no change to the pattern's end
  EXX
  LD HL,$0000
  RET
CmdDrum:
  LD A,(HL)               ; $CC n: a digidrum on this channel, then off
  INC HL
  LD (DigidrumNumber),A
  LD A,B
  LD (DigidrumChannel),A
CmdOff:
  LD IY,$0000             ; $CA: instrument 0 from this line (IYH = 0, E = 0)
  LD E,$00
  EXX
  LD HL,$0000
  RET

; one line of an instrument: the channel's period, volume, noise and mixer bits
;
; Input: HL = the line, A = the instrument's frame counter, IXL = the note, IY
; = the channel's period low byte in the cache (IY+$1B the high byte, IY+$36
; the volume), D' = the attenuation, HL' = Retrigger, LinePitch = the pitch
; sum. The line's first byte E: bit 7 clear: a soft line. Bits 0-3 the volume
; (minus the attenuation, not below 0); volume 0 with bit 4 clear: silent (R8
; 0, tone and noise off), no more bytes. Bit 4: a noise byte N follows: N bit 6
; a fixed period (the word after; N bits 0-4 the noise if not 0), else N bits
; 0-4 the noise and N bit 5 the tone too. With the tone: bit 5 an arpeggio byte
; (semitones added to the note), bit 6 a pitch word (added to the period); the
; period = PeriodTable[note + arpeggio, at most 95] + LinePitch / 2 + the
; pitch. Bit 7 set: a hardware line (HardLine). Output: HL past the line, IXH =
; the mixer bits (bit 0 tone off, bit 3 noise off). 1698 runs in the intro
; window (all soft lines: no hardware line played in its three patterns).
;
; E (the first byte): bit 6 retrigger R13 (only at counter 0), bit 0 tone off,
; bit 3 a noise byte follows, bit 4 a fixed tone word follows (and with bit 5
; an envelope word), else bit 1 an arpeggio byte, bit 2 a pitch word, bit 5
; (without sync) an envelope word. The second byte B: bits 0-1 the shape (8,
; 10, 12, 14), bits 2-4 the ratio R (the envelope period = the tone period >>
; (7 - R), rounded; R = 3 puts the envelope at the note's own pitch), bit 7
; sync (the tone period set back from the envelope period << (7 - R), + the
; offset byte when bit 6). Not run in c1's intro window (SK10's instrument 4 is
; the only hardware one: tools/sk10.py).
InstrumentLine:
  LD E,(HL)
  INC HL
  BIT 7,E
  JP NZ,HardLine          ; bit 7: the hardware envelope
  BIT 4,E                 ; bit 4: a noise byte
  JR Z,SoftLine
  LD A,(HL)               ; N bit 6: a fixed period
  BIT 6,A
  JR Z,NoiseLine
  LD D,$08                ; noise off unless N's bits 0-4
  INC HL
  AND $1F
  JR Z,FixedVolume
  LD (AYReg6+$0001),A     ; R6
  RES 3,D
FixedVolume:
  LD A,E                  ; the volume - the attenuation
  AND $0F
  EXX
  SUB D
  EXX
  JR NC,FixedStore
  XOR A
FixedStore:
  LD (IY+$36),A
  LD IXH,D
  LD A,(HL)               ; the fixed period into the cache
  LD (IY+$00),A
  INC HL
  LD A,(HL)
  LD (IY+$1B),A
  INC HL
  RET
NoiseLine:
  LD (AYReg6+$0001),A     ; noise N; bit 5 of N: the tone too
  INC HL
  LD D,$01                ; tone off, noise on
  BIT 5,A
  JR Z,NoiseOnly
  RES 0,D                 ; tone on as well
  LD A,E
  AND $0F
  EXX
  SUB D
  EXX
  JR NC,NoiseToneStore
  XOR A
NoiseToneStore:
  LD (IY+$36),A
  LD IXH,D
  JR ArpAndPitch
NoiseOnly:
  LD A,E                  ; the noise alone
  AND $0F
  EXX
  SUB D
  EXX
  JR NC,NoiseOnlyStore
  XOR A
NoiseOnlyStore:
  LD (IY+$36),A
SetMixer:
  LD IXH,D                ; IXH = the mixer bits
  RET
SilentLine:
  LD (IY+$36),$00         ; volume 0: tone and noise off
  LD D,$09
  JR SetMixer
SoftLine:
  LD D,$08                ; the tone, noise off
  LD A,E
  AND $0F
  JR Z,SilentLine
  EXX
  SUB D
  EXX
  JR NC,SoftStore
  XOR A
SoftStore:
  LD (IY+$36),A
  LD IXH,$08
ArpAndPitch:
  BIT 5,E                 ; bit 5: the arpeggio byte
  JR Z,NoArpeggio
  LD A,(HL)
  INC HL
  JR TestPitch
NoArpeggio:
  XOR A
TestPitch:
  BIT 6,E                 ; bit 6: the pitch word
  JR Z,NoPitch
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  JR AddArpeggio
NoPitch:
  LD DE,$0000
AddArpeggio:
  ADD A,IXL               ; the note + the arpeggio, at most 95
  CP $60
  JR C,PeriodOfNote
  LD A,$5F
PeriodOfNote:
  PUSH HL                 ; PeriodTable + 2 x the note
  ADD A,A
  LD L,A
  LD H,$00
  LD BC,PeriodTable
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
LinePitch:
  LD HL,$0000             ; LinePitch+1: the pitch sum (PlayInstruments),
                          ; halved and added
  SRA H
  RR L
  ADD HL,BC
  ADD HL,DE
  LD (IY+$00),L           ; into the cache
  LD (IY+$1B),H
  POP HL
  RET
HardLine:
  OR A                    ; the hardware envelope: R8 = 16, the shape, the
                          ; ratio
  JR NZ,HardMixer
  LD A,E                  ; the first frame of the line: the retrigger bit
  EXX
  AND $40
  OR (HL)
  LD (HL),A
  EXX
HardMixer:
  LD A,E                  ; D = tone off (bit 0) and noise off (bit 3)
  OR $08
  AND $09
  LD D,A
  LD (IY+$36),$10         ; volume 16: the envelope
  LD B,(HL)               ; the shape: R13 = 8 + 2 x (B & 3)
  INC HL
  LD A,B
  AND $03
  ADD A,A
  ADD A,$08
  LD (AYReg13+$0001),A
  BIT 3,E                 ; bit 3: the noise byte
  JR Z,HardSetMixer
  LD A,(HL)
  INC HL
  LD (AYReg6+$0001),A
  RES 3,D
  JR HardSetMixer
HardSetMixer:
  LD IXH,D
  XOR A
  BIT 7,B                 ; B bit 7: sync; bit 6 its offset byte
  JR Z,SetSyncFlag
  BIT 6,B
  JR Z,SetSyncOffset
  LD A,(HL)
  INC HL
SetSyncOffset:
  LD (SyncOffset+$0001),A
  LD A,$01
SetSyncFlag:
  LD (HardSync+$0001),A   ; HardSync+1 = 1 with sync
  LD A,B                  ; the ratio x 2 into HardRatio+1
  RRA
  AND $0E
  LD (HardRatio+$0001),A
  BIT 4,E                 ; bit 4: a fixed tone period
  JP NZ,HardFixed
  BIT 1,E                 ; bit 1: the arpeggio
  JR Z,HardNoArp
  LD A,(HL)
  INC HL
  JR HardKeepFlags
HardNoArp:
  XOR A
HardKeepFlags:
  EX AF,AF'               ; E kept in A'
  LD A,E
  EX AF,AF'
  BIT 2,E                 ; bit 2: the pitch word
  JR Z,HardNoPitch
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  JR HardAddArp
HardNoPitch:
  LD DE,$0000
HardAddArp:
  ADD A,IXL               ; the note + the arpeggio, at most 95
  CP $60
  JR C,HardPeriod
  LD A,$5F
HardPeriod:
  PUSH HL                 ; the period: PeriodTable[note] + LinePitch / 2 + the
                          ; pitch
  ADD A,A
  LD L,A
  LD H,$00
  LD BC,PeriodTable
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD HL,(LinePitch+$0001)
  SRA H
  RR L
  ADD HL,BC
  ADD HL,DE
  LD C,L
  LD B,H
HardSync:
  LD A,$00                ; HardSync+1: 1 the tone follows the envelope
  OR A
  JR NZ,HardRatio
  EX AF,AF'               ; bit 5: the envelope period given
  BIT 5,A
  JR NZ,HardEnvGiven
HardTone:
  LD A,C                  ; the tone period into the cache
  LD (IY+$00),C
  LD (IY+$1B),B
HardRatio:
  LD E,$00                ; HardRatio+1: the ratio x 2
  LD A,E
  SRL A
  ADD A,E
  LD (HardShiftDown+$0001),A ; skip 3 x ratio bytes of the shifts: >> (7 -
                             ; ratio)
  LD A,C
HardShiftDown:
  JR ShiftsDown           ; JR into the seven shifts
ShiftsDown:
  SRL B
  RRA
  SRL B
  RRA
  SRL B
  RRA
  SRL B
  RRA
  SRL B
  RRA
  SRL B
  RRA
  SRL B
  RRA
  LD C,A
  JR NC,SetEnvPeriod      ; rounded
  INC BC
SetEnvPeriod:
  LD A,C                  ; R11, R12
  LD (AYReg11+$0001),A
  LD A,B
  LD (AYReg12+$0001),A
  LD A,(HardSync+1)       ; sync: the tone from the envelope period
  OR A
  JR Z,HardDone
  LD A,(HardRatio+1)
  LD E,A
  SRL A
  ADD A,E
  LD (HardShiftUp+$0001),A ; skip 3 x ratio bytes: << (7 - ratio)
  LD A,B
HardShiftUp:
  JR ShiftsUp             ; JR into the seven shifts
ShiftsUp:
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  LD B,A
SyncOffset:
  LD HL,$0000             ; SyncOffset+1: the offset added (B bit 6)
  ADD HL,BC
  LD (IY+$00),L
  LD (IY+$1B),H
HardDone:
  POP HL
  RET
HardFixed:
  LD C,(HL)               ; bit 4: the fixed tone word
  INC HL
  LD B,(HL)
  INC HL
  PUSH HL
  BIT 5,E
  JR Z,HardTone
HardEnvGiven:
  POP HL                  ; the tone, and the envelope period from the next
                          ; word
  LD (IY+$00),C
  LD (IY+$1B),B
  LD A,(HL)
  LD (AYReg11+$0001),A
  INC HL
  LD A,(HL)
  LD (AYReg12+$0001),A
  INC HL
  RET
