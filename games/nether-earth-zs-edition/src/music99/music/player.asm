; --------------------------------------------------------------------------------------------------------------------
; player.asm: the Sound Tracker 1.x compiled player
;
; The player the Sound Tracker 1.x editor's compile function puts in front of a module: three entry jumps (init, play,
; mute), the compile text, the set-up, the variables, the per-frame play routine, the note table and the AY register
; writer. It plays STC modules: a tempo (frames a row), a position list (pattern, transposition), 16 samples of 32
; lines (volume, noise, tone shift, masks; a loop), ornaments of 32 note offsets, patterns of three channel streams
; (notes, sample / ornament / envelope / length commands).
;
; Its variables live inside the block ($C0C9-$C107) and some operands are patched as it runs (the module address in
; ModuleOffset, the transposition in NoteTransposition, the sample line in OrnamentLine): the block is not re-entrant
; and is only correct once Init has run.
; --------------------------------------------------------------------------------------------------------------------

; Eleven bytes the compiler leaves in front of the jumps
;
; $0B $00 $0E $00: the offsets of the init and play entries ($C00B, $C00E) as
; words; $7E $80 $81 $80 $80 $10 $1F: bytes no code of the block reads (the
; compiler's own; their meaning is not known from this block). Nothing in the
; recording reads any of them.
CompileHeader:
  DEFB $0B,$00,$0E,$00,$7E,$80,$81,$80
  DEFB $80,$10,$1F

; Entry: set the module at Module up for playing from its first position
;
; JR to InitEntry (HL = Module). Called once by stage 2 at $61E3 (r99 frame
; 261) with A = $80, which the player ignores. Interrupts are disabled while it
; runs and enabled again on return.
Init:
  JR InitEntry

; A padding byte after the JR (NOP)
InitPad:
  DEFB $00

; Entry: one frame of the tune (called once an interrupt)
;
; JR to PlayEntry. Called by stage 2's interrupt handler ($6525) every frame
; from r99 frame 262 to 2114.
Play:
  JR PlayEntry

; A padding byte after the JR (NOP)
PlayPad:
  DEFB $00

; Entry: silence the AY
;
; JR to MuteAY. Called once by stage 2 ($6278) after SPACE (r99 frame 2114).
Mute:
  JR MuteAY

; A padding byte after the JR (NOP)
MutePad:
  DEFB $00

; "SOUND TRACKER COMPILATION OF NE___MUS   BY KSA SOFTWARE" and the byte $7F
;
; The compiler's signature with the module name ("NE___MUS") and the author
; field ("KSA SOFTWARE") filled in when compiling: other compiled blocks carry
; their own (the reference copy "SLIDE" with an empty author, "BURO NAHOD BY
; WILLIS SOFT"). Whether KSA Software is the musician or the author field of
; the copy of Sound Tracker used is not known from this block. $7F at $C04B
; ends it.
CompileText:
  DEFM "SOUND TRACKER COMPILATION OF NE___MUS   BY KSA SOFTWARE",$7F

; Silence the AY: register 12 stepped through 0-255, the mixer (register 7) set
; to $FF
;
; Selects AY register 12 and writes A = 0, 1, ... 255 to it (MuteLoop, ending
; when A wraps to 0), then register 7 = $FF: every tone and noise channel off.
; A, BC changed. Ports $FFFD / $BFFD.
MuteAY:
  LD BC,$FFFD
  LD A,$0C                ; register 12, the envelope period's high byte, is
                          ; selected
  OUT (C),A
  XOR A                   ; A = 0 to the data port first, then 1, 2 ... in
                          ; MuteLoop
  LD B,$BF
  JP MuteLoop

; Init's jump: HL = the module
;
; HL = Module, on to InitModule.
InitEntry:
  LD HL,Module
  JP InitModule

; Play's jump: on to PlayFrame
;
; Used by the routine at Play.
PlayEntry:
  JP PlayFrame

; Set the player's variables up for the STC module at HL
;
; Input: HL = the module. Reads the tempo, patches ModuleOffset with the module
; address (the module's offsets become addresses), takes the positions list
; (its first byte + 1 = the count), the ornaments, the patterns and the samples
; (module + 27) addresses; points channel A's pattern stream at PatternEnd
; ($FF, so that the first Play fetches position 0), zeroes
; ChannelState..AYEnvShape, sets every channel's ornament to ornament 0 and its
; sample counter to $FF (silent), the delay counter to 1, and writes the AY
; registers once (WriteAY). DI on entry, EI on return. Outputs: every variable
; of the player; A, BC, DE, HL changed.
InitModule:
  DI                      ; interrupts off while the variables are half set
  LD A,(HL)               ; the module's first byte: frames a row
  LD (Tempo),A
  LD (ModuleOffset+$0001),HL ; the module address into ModuleOffset's operand
  INC HL
  CALL ReadOffset         ; DE = the positions list ...
  LD A,(DE)               ; ... its first byte: the last position's index
  INC DE
  INC A                   ; + 1: the count of positions
  LD (PositionCount),A
  LD (PositionsAddr),DE
  CALL ReadOffset         ; DE = the ornaments
  LD (OrnamentsAddr),DE
  PUSH DE
  CALL ReadOffset         ; DE = the patterns
  LD (PatternsAddr),DE
  LD HL,$001B             ; DE = the samples (module + 27)
  CALL ModuleOffset
  EX DE,HL
  LD (SamplesAddr),HL
  LD HL,PatternEnd        ; channel A's stream at the $FF of PatternEnd
  LD (PatternPtrA),HL
  LD HL,ChannelState      ; ChannelState..AYEnvShape cleared (45 bytes)
  LD DE,ChannelState+$0001
  LD BC,$002C
  LD (HL),B
  LDIR
  POP HL                  ; ornament 0: found in the ornament list
  LD BC,$0021
  XOR A
  CALL FindNumbered
  DEC A                   ; A = $FF: every channel's sample counter ...
  LD (ChannelA+$0007),A
  LD (ChannelB+$0007),A
  LD (ChannelC+$0007),A
  LD A,$01                ; ... and the delay counter at 1: the next Play reads
                          ; a row
  LD (DelayCounter),A
  INC HL                  ; every channel plays ornament 0 (its offsets, past
                          ; the number byte)
  LD (ChannelA+$0005),HL
  LD (ChannelB+$0005),HL
  LD (ChannelC+$0005),HL
  CALL WriteAY            ; the registers once
  EI
  RET

; The module's position list (past its count byte)
;
; The player's variables, $C0C9-$C107. Before Init they hold the compiler's
; leftovers (as on the disk); InitModule sets them.
PositionsAddr:
  DEFW $F177
OrnamentsAddr:
  DEFW $F18F              ; the module's ornaments
PatternsAddr:
  DEFW $F213              ; the module's pattern table
SamplesAddr:
  DEFW $EE5E              ; the module's samples (module + 27)

; Frames a row (the module's first byte)
Tempo:
  DEFB $06
DelayCounter:
  DEFB $03                ; frames left until the next row
PositionCount:
  DEFB $0C                ; the number of positions (list byte + 1)

; Channel A's pattern stream: the next row's byte
PatternPtrA:
  DEFW $F4B1
PatternPtrB:
  DEFW $F4F3              ; channel B's pattern stream
PatternPtrC:
  DEFW $F535              ; channel C's pattern stream

; $FF: channel A's stream points here after Init (an end of pattern: the first
; Play fetches a position)
PatternEnd:
  DEFB $FF

; Channel A's 10 bytes; IX points at +2 (ChannelA)
;
; Per channel (A $C0DB, B $C0E5, C $C0EF), IX = the channel + 2: IX-2 the
; envelope state (0 none, 1 set by the row, 2 written once), IX-1 the row
; length reload, IX+0 the sample line (0-31), IX+1 the note, IX+2 the rows left
; until the next note, IX+3/4 the sample's address, IX+5/6 the ornament's
; address, IX+7 the sample lines left ($FF: silent).
ChannelState:
  DEFB $00,$00
ChannelA:
  DEFB $04,$24,$00,$88,$EF,$90,$F1,$1C ; channel A: IX here
ChannelStateB:
  DEFB $02,$01            ; channel B's 10 bytes
ChannelB:
  DEFB $04,$1A,$01,$4E,$F0,$90,$F1,$1C ; channel B: IX here
ChannelStateC:
  DEFB $00,$01            ; channel C's 10 bytes
ChannelC:
  DEFB $0A,$35,$00,$B1,$F0,$D2,$F1,$16 ; channel C: IX here

; The next position to play
PositionIndex:
  DEFB $05

; The AY registers 0-13 as WriteAY writes them (down from 13 or 10): tone A, B,
; C periods
AYTone:
  DEFW $09DF,$0358
  DEFW $0168

; Register 6: the noise period
AYNoise:
  DEFB $00
AYMixer:
  DEFB $38                ; register 7: the mixer
AYVolume:
  DEFB $0B,$1A,$07        ; registers 8-10: the volumes A, B, C (bit 4: the
                          ; envelope)
AYEnvPeriod:
  DEFB $D9,$00            ; registers 11-12: the envelope period
AYEnvShape:
  DEFB $00                ; register 13: the envelope shape (0: not written
                          ; this frame)

; Find the record whose first byte is A
;
; Inputs: A = the number, HL = the first record, BC = the record size. Steps HL
; by BC until (HL) = A. Output: HL = the record (no end check: the number must
; be there).
FindNumbered:
  CP (HL)
  RET Z
  ADD HL,BC
  JP FindNumbered

; Read a module offset at HL and make it an address
;
; Input: HL = a word in the module. Output: DE = the word + the module address
; (through ModuleOffset), HL past the word. BC changed.
ReadOffset:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL

; DE = HL + the module address (the operand patched by InitModule)
;
; ModuleOffset+1 holds the module address once Init has run (on the disk the
; compiler's $EE43). Input HL, output DE = HL + module; BC changed. InitModule
; calls it directly for the samples (HL = 27).
ModuleOffset:
  LD BC,$EE43
  ADD HL,BC
  EX DE,HL
  RET

; Decode one line of a sample
;
; Inputs: IX = the sample's address (IX+3/4 of a channel), A = the line (0-31).
; Outputs: L = the volume (0-15), H = the noise period, DE = the tone shift (12
; bits, bit 4 of D set when it is added), C = $10 when the tone is masked off,
; B = $02 when the noise is masked off; IX moved to the line. Called three
; times a frame from PlayFrameOut.
SampleLine:
  LD D,$00
  LD E,A
  ADD A,A
  ADD A,E
  LD E,A
  ADD IX,DE
  LD A,(IX+$01)
  BIT 7,A
  LD C,$10
  JP NZ,SampleNoiseMask
  LD C,D
SampleNoiseMask:
  BIT 6,A                 ; bit 6: the noise mask
  LD B,$02
  JP NZ,SampleNoise
  LD B,D
SampleNoise:
  AND $1F                 ; the noise period
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
  BIT 5,(IX+$01)          ; bit 5: the shift is added
  RET Z
  SET 4,D
  RET

; Move to the next position: the three pattern streams and the transposition
;
; Takes PositionIndex (back to 0 after the last), reads the position's pattern
; number and transposition (the transposition patched into NoteTransposition),
; finds the pattern in the pattern table and points PatternPtrA/B/C at its
; three streams. Called from PlayFrame when channel A's stream reaches $FF (5
; times in the window, frames 262-1806). A, BC, DE, HL changed.
NextPosition:
  LD A,(PositionIndex)
  LD C,A
  LD HL,PositionCount
  CP (HL)
  JP C,NextPositionSet
  XOR A
  LD C,A
NextPositionSet:
  INC A                   ; the index after this one
  LD (PositionIndex),A
  LD L,C
  LD H,$00
  ADD HL,HL
  LD DE,(PositionsAddr)
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD (NoteTransposition+$0001),A
  LD A,C
  LD HL,(PatternsAddr)
  LD BC,$0007
  CALL FindNumbered
  INC HL
  CALL ReadOffset
  LD (PatternPtrA),DE
  CALL ReadOffset
  LD (PatternPtrB),DE
  CALL ReadOffset
  LD (PatternPtrC),DE
  RET

; Count a channel's rows down
;
; IX = the channel. DEC (IX+2); when it goes below zero the reload (IX-1) is
; put back and the sign flag is set (M): the caller reads the channel's next
; row.
RowCountdown:
  DEC (IX+$02)
  RET P
  LD A,(IX-$01)
  LD (IX+$02),A
  RET

; One frame of the tune: every Tempo frames a row of each channel, then the
; sound
;
; DelayCounter counted down; at zero it is reloaded from Tempo and each channel
; whose row counter ran out reads its stream (ReadRow; channel A first fetches
; the next position when its stream is at $FF). Then PlayFrameOut works out and
; writes the registers. Called through Play from the interrupt handler.
PlayFrame:
  LD A,(DelayCounter)
  DEC A
  LD (DelayCounter),A
  JP NZ,PlayFrameOut
  LD A,(Tempo)
  LD (DelayCounter),A
  LD IX,ChannelA
  CALL RowCountdown
  JP P,PlayChannelB
  LD HL,(PatternPtrA)
  LD A,(HL)
  INC A
  CALL Z,NextPosition
  LD HL,(PatternPtrA)
  CALL ReadRow
  LD (PatternPtrA),HL
PlayChannelB:
  LD IX,ChannelB          ; channel B
  CALL RowCountdown
  JP P,PlayChannelC
  LD HL,(PatternPtrB)
  CALL ReadRow
  LD (PatternPtrB),HL
PlayChannelC:
  LD IX,ChannelC          ; channel C
  CALL RowCountdown
  JP P,PlayFrameOut
  LD HL,(PatternPtrC)
  CALL ReadRow
  LD (PatternPtrC),HL
  JP PlayFrameOut

; Read a channel's pattern stream up to its next note or rest
;
; Inputs: HL = the stream, IX = the channel. Bytes: $00-$5F a note (IX+1; the
; sample restarts: line 0, 32 lines); $60-$6F the sample (number - $60);
; $70-$7F the ornament (number - $70, the envelope off); $80 a rest (the
; channel silent); $81 an empty row; $82 ornament 0, the envelope off; $83-$8E
; the envelope shape (- $80) with the next byte its period (low), ornament 0;
; $A1 and above the row length (- $A1). Commands loop until a note, a rest or
; an empty row. Output: HL past the row.
ReadRow:
  LD A,(HL)
  CP $60
  JP C,RowNote
  CP $70
  JP C,RowSample
  CP $80
  JP C,SetOrnament
  JP Z,RowRest
  CP $81
  JP Z,RowEmpty
  CP $82
  JP Z,OrnamentZero
  CP $8F
  JP C,SetEnvelope
  SUB $A1
  LD (IX+$02),A
  LD (IX-$01),A
  INC HL
  JP ReadRow
RowNote:
  LD (IX+$01),A           ; a note
  LD (IX+$00),$00
  LD (IX+$07),$20
RowEmpty:
  INC HL                  ; an empty row
  RET
RowSample:
  SUB $60                 ; a sample
  PUSH HL
  LD BC,$0063
  LD HL,(SamplesAddr)
  CALL FindNumbered
  INC HL
  LD (IX+$03),L
  LD (IX+$04),H
  POP HL
  INC HL
  JP ReadRow
RowRest:
  INC HL                  ; a rest

; The channel's sample counter to $FF: the channel is silent
;
; Used by the routine at SampleStep.
ChannelOff:
  LD (IX+$07),$FF
  RET

; Row byte $82: ornament 0, the envelope off
;
; Used by the routine at ReadRow.
OrnamentZero:
  XOR A
  JR SetOrnamentA

; Row byte $70-$7F: point the channel at ornament A - $70, the envelope off
;
; Inputs: A = the row byte, HL = the stream, IX = the channel. Back into
; ReadRow with HL past the byte.
SetOrnament:
  SUB $70
; This entry point is used by the routine at OrnamentZero.
SetOrnamentA:
  PUSH HL
  LD BC,$0021
  LD HL,(OrnamentsAddr)
  CALL FindNumbered
  INC HL
  LD (IX+$05),L
  LD (IX+$06),H
  LD (IX-$02),$00
  POP HL
  INC HL
  JP ReadRow

; Row bytes $83-$8E, period: the envelope shape and period, ornament 0
;
; AYEnvShape = A - $80, AYEnvPeriod = the next byte, the channel's envelope
; state 1, ornament 0; back into ReadRow.
SetEnvelope:
  SUB $80
  LD (AYEnvShape),A
  INC HL
  LD A,(HL)
  INC HL
  LD (AYEnvPeriod),A
  LD (IX-$02),$01
  PUSH HL
  XOR A
  LD BC,$0021
  LD HL,(OrnamentsAddr)
  CALL FindNumbered
  INC HL
  LD (IX+$05),L
  LD (IX+$06),H
  POP HL
  JP ReadRow

; Advance a channel's sample by one line
;
; IX = the channel. When the channel is silent ($FF) returns at once (Z). Else
; the line counter IX+7 is decreased and the line IX+0 advanced (mod 32); C =
; the line to play. When the counter runs out the sample's loop (its byte $60:
; start + 1, $61: length) restarts it, or (no loop) the channel goes silent.
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
  JP M,ChannelOff
  LD C,A
  INC A
  AND $1F
  LD (IX+$00),A
  INC HL
  LD A,(HL)
  INC A
  LD (IX+$07),A
  RET

; Register 6 = H when the noise is on (C = 0)
;
; Used by the routine at PlayFrameOut.
NoiseFromSample:
  LD A,C
  OR A
  RET NZ
  LD A,H
  LD (AYNoise),A
  RET

; Set bit 4 of the volume at HL while the channel uses the envelope
;
; IX = the channel, HL = its volume register in AYVolume. On the first frame
; after an envelope command (IX-2 = 1) the state becomes 2; on the next ones
; (2) AYEnvShape is cleared, so the shape register is written once. The
; volume's bit 4 (the envelope) is set while the state is non-zero.
EnvelopeFlag:
  LD A,(IX+$07)
  INC A
  RET Z
  LD A,(IX-$02)
  OR A
  RET Z
  CP $02
  JP Z,EnvelopeOnce
  LD (IX-$02),$02
  JP EnvelopeOn
EnvelopeOnce:
  XOR A                   ; the shape is written only on the first frame
  LD (AYEnvShape),A
EnvelopeOn:
  SET 4,(HL)              ; the envelope on
  RET

; The frame's sound of the three channels into AYTone..AYVolume, then WriteAY
;
; For each channel: SampleStep; SampleLine of the line; the mixer bits; the
; tone period (TonePeriod); the volume; the envelope state. AYMixer is built
; from the three channels' tone and noise masks. Ends in WriteAY.
PlayFrameOut:
  LD IX,ChannelA
  CALL SampleStep
  LD A,C
  LD (OrnamentLine+$0001),A
  LD IX,(ChannelA+$0003)
  CALL SampleLine
  LD A,C
  OR B
  RRCA
  LD (AYMixer),A
  LD IX,ChannelA
  LD A,(IX+$07)
  INC A
  JP Z,VolumeA
  CALL NoiseFromSample
  CALL TonePeriod
  LD (AYTone),HL
VolumeA:
  LD HL,AYVolume          ; channel A's volume
  LD (HL),A
  CALL EnvelopeFlag
OutChannelB:
  LD IX,ChannelB          ; channel B
  CALL SampleStep
  LD A,(IX+$07)
  INC A
  JP Z,VolumeB
  LD A,C
  LD (OrnamentLine+$0001),A
  LD IX,(ChannelB+$0003)
  CALL SampleLine
  LD A,(AYMixer)
  OR C
  OR B
  LD (AYMixer),A
  CALL NoiseFromSample
  LD IX,ChannelB
  CALL TonePeriod
  LD (AYTone+$0002),HL
VolumeB:
  LD HL,AYVolume+$0001    ; channel B's volume
  LD (HL),A
  CALL EnvelopeFlag
OutChannelC:
  LD IX,ChannelC          ; channel C
  CALL SampleStep
  LD A,(IX+$07)
  INC A
  JP Z,VolumeC
  LD A,C
  LD (OrnamentLine+$0001),A
  LD IX,(ChannelC+$0003)
  CALL SampleLine
  LD A,(AYMixer)
  RLC C
  RLC B
  OR B
  OR C
  LD (AYMixer),A
  CALL NoiseFromSample
  LD IX,ChannelC
  CALL TonePeriod
  LD (AYTone+$0004),HL
VolumeC:
  LD HL,AYVolume+$0002    ; channel C's volume
  LD (HL),A
  CALL EnvelopeFlag
  JP WriteAY

; The tone period of a channel's note, ornament and sample shift
;
; Inputs: IX = the channel, DE = the sample's shift (bit 4 of D: add), L = the
; volume (kept). The note (IX+1) + the ornament's offset at the line
; (OrnamentLine's operand, patched with the line) + the position's
; transposition (NoteTransposition's operand) indexes NoteTable; the shift is
; added or subtracted. Output: HL = the period, A = the volume.
TonePeriod:
  LD A,L
  PUSH AF
  PUSH DE
  LD L,(IX+$05)
  LD H,(IX+$06)
OrnamentLine:
  LD DE,$000A             ; OrnamentLine+1: the sample line, patched by
                          ; PlayFrameOut
  ADD HL,DE
  LD A,(IX+$01)
  ADD A,(HL)
NoteTransposition:
  ADD A,$00               ; NoteTransposition+1: the position's transposition,
                          ; patched by NextPosition
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,NoteTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  POP DE
  POP AF
  BIT 4,D
  JR Z,ShiftDown
  RES 4,D
  ADD HL,DE
  RET
ShiftDown:
  AND A                   ; bit 4 clear: the shift is subtracted
  SBC HL,DE
  RET

; The 96 tone periods of the notes (8 octaves of 12, $0EF8 down to $000F)
;
; The AY tone period of each note (the Sound Tracker table, for the AY's 1.77
; MHz clock).
NoteTable:
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

; Write the AY registers from AYTone..AYEnvShape
;
; When AYEnvShape is non-zero registers 13 down to 0 are written, else 10 down
; to 0 (the envelope shape is written only when a row set it: writing register
; 13 restarts the envelope). OUTD from the top register's byte downwards. A,
; BC, HL changed. Ports $FFFD / $BFFD.
WriteAY:
  LD HL,AYEnvShape
  XOR A
  OR (HL)
  LD A,$0D
  JR NZ,WriteAYFrom
  SUB $03
  DEC HL
  DEC HL
  DEC HL
WriteAYFrom:
  LD C,$FD                ; C = $FD: port $FFFD selects, $BFFD (B after OUTD's
                          ; decrement: $BEFD, decoded the same) writes
WriteAYLoop:
  LD B,$FF                ; one register: select A, write (HL), down
  OUT (C),A
  LD B,$BF
  OUTD
  DEC A
  JP P,WriteAYLoop
  RET

; MuteAY's loop: register 12 = A, A + 1, ... until A wraps to 0; then register
; 7 = $FF
;
; Used by the routine at MuteAY.
MuteLoop:
  OUT (C),A
  INC A
  JR NZ,MuteLoop
  LD B,$FF                ; every tone and noise off
  LD A,$07
  OUT (C),A
  LD BC,$BFFD
  LD A,$FF
  OUT (C),A
  RET

; The tune: an STC module (Sound Tracker compiled, 2023 bytes)
;
; Its 27-byte header: tempo 6, positions at +$026D, ornaments at +$0292,
; patterns at +$0358, the identifier "SONG BY ST COMPILE", the size $07E7; then
; 16 samples of 99 bytes, the 18 positions, the ornaments, the pattern table
; and the patterns. The source is the .stc file (src/res/music99/ne_mus.stc,
; readable by zxtune and other STC players).
Module:
  INCBIN "res/music99/ne_mus.stc",$0000,2023

; The 113 bytes after the module to the end of the 13th sector: no code reads
; them
;
; They look like the end of another tune's patterns (the same kind of bytes as
; the module's pattern data) left in the memory the block was saved from. Kept
; as a leftover (src/res/music99/leftover-cc8f.bin).
SectorSlack:
  INCBIN "res/music99/leftover-cc8f.bin",$0000,113
