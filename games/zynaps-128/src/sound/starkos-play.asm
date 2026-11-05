; --------------------------------------------------------------------------------------------------------------------
; starkos-play.asm: the entries and the line: speed, patterns, the special track, the three tracks
;
; The intro (block 1, docs/03-build-and-load.md 3.4) calls PlayerEntries with DE = Song ($6061), then PlayerPlay from
; its IM 2 handler once a frame ($60DF), and jumps to PlayerStop when it ends ($60BA). On a 48K ($5D3B = 0) none of
; them runs.
;
; A STarKos song is a list of patterns. Each pattern has a height (lines), three tracks (the linker: one track address
; a channel), a transposition per track and a special track (speed changes and digidrums). The three per-pattern
; values come from run-length streams, each read once a pattern: the transpositions (TranspPointer), the heights
; (HeightPointer) and the special tracks (SpecialListPointer); the linker (LinkerPointer) gives three words a pattern.
; The song's last pattern ends where the special list begins (LinkerEnd); the four streams then restart at the song's
; loop points. The song's bytes and the format: src/res/music/README.md, tools/sk10.py.
;
; Play runs one frame: SpeedCounter counts up to Speed; on the frame it reaches it, a new line: at a pattern's first
; line (NewPatternFlag = SCF) the streams and the linker give the pattern, then the special track and the three tracks
; are read (each track's wait counts down the empty lines), LineCounter counts the pattern's lines. Every frame then
; goes on at PlayInstruments (starkos-frame.asm) for the sound of the three channels.
; --------------------------------------------------------------------------------------------------------------------

; the jump table: Init ($8000), Play ($8003), Stop ($8006)
;
; $8000 JP Init (input DE = the song: $8990); $8003 JP Play; $8006 JP Stop. In
; c1: Init once, at the intro's start; Play 566 times in the intro window (one
; a frame); Stop once, when the intro ends.
PlayerEntries:
  JP Init
PlayerPlay:
  JP Play                 ; JP Play
PlayerStop:
  JP Stop                 ; JP Stop

; $8000: the address the player was built for
;
; No instruction of the player or of the intro reads it.
PlayerOrigin:
  DEFW PlayerEntries

; the digidrum the song asked for this frame (0: none)
;
; Zeroed by Play each frame, set by a special track's drum line or a track's
; drum command; for the host to play a sample. The intro never reads it (no
; reference in block 1's code), and SK10 has no drum (sk10.txt).
DigidrumNumber:
  DEFB $00

; the channel (1-3) of that digidrum
;
; A track's drum command sets its channel number; a special track's drum line
; sets the song's drum channel (header byte 6, copied to SpecialDrum+4 by
; Init).
DigidrumChannel:
  DEFB $00

; one frame of the song: a line when the speed count ends, then the instruments
;
; No input; changes every register (the intro's handler saves them).
; DigidrumNumber = 0, Retrigger = 0 (the R13 retrigger flag); SpeedCounter + 1
; until it equals Speed, else 0 and a new line (NextLine). 566 runs in the
; intro window, 95 of them a new line (Speed 5: six frames a line).
Play:
  XOR A
  LD (DigidrumNumber),A   ; no digidrum this frame
  LD (Retrigger+$0001),A  ; no envelope retrigger yet this frame
SpeedCounter:
  LD A,$00                ; SpeedCounter+1: the frames of this line so far
Speed:
  CP $00                  ; Speed+1: the frames a line - 1 (the song's speed,
                          ; its special track's speed lines)
  JR Z,NextLine
  INC A                   ; not yet: count, and only the instruments this frame
  LD (SpeedCounter+$0001),A
  JP PlayInstruments
NextLine:
  XOR A                   ; a new line
  LD (SpeedCounter+$0001),A
NewPatternFlag:
  OR A                    ; OR A ($B7): the pattern goes on; SCF ($37): a new
                          ; pattern at this line
  JP NC,SpecialWait
  LD (TrackAWait+$0001),A ; a new pattern: the three tracks' waits 0
  LD (TrackBWait+$0001),A
  LD (TrackCWait+$0001),A
  LD A,$B7                ; the next lines are not the pattern's first
  LD (NewPatternFlag),A
TranspWait:
  LD A,$00                ; TranspWait+1: patterns left with the same
                          ; transpositions
  SUB $01
  JR NC,TranspSetWait
TranspPointer:
  LD HL,$0000             ; TranspPointer+1: the transposition stream
  LD A,(HL)
  INC HL
  SRL A                   ; bit 0: a hold (the count in bits 1-7)
  JR C,TranspHold
  LD B,A                  ; bits 1-5: track A's transposition (5 bits signed),
                          ; bit 7: track B's byte follows, bit 6: track C's
  AND $1F
  BIT 4,A
  JR Z,TranspSetA
  OR $E0
TranspSetA:
  LD (TrackAInstrument+$0002),A ; into TrackAInstrument+2 (D, added to each
                                ; note)
  RL B                    ; bit 7 of the byte
  RL B
  JR NC,TranspTestC
  LD A,(HL)               ; track B's transposition byte
  LD (TrackBInstrument+$0002),A
  INC HL
TranspTestC:
  RL B                    ; bit 6
  JR NC,TranspStore
  LD A,(HL)               ; track C's
  LD (TrackCInstrument+$0002),A
  INC HL
TranspStore:
  LD (TranspPointer+$0001),HL
  JR HeightWait
TranspHold:
  LD (TranspPointer+$0001),HL ; a hold: the count
TranspSetWait:
  LD (TranspWait+$0001),A
HeightWait:
  LD A,$00                ; HeightWait+1: patterns left with HeightRepeat's
                          ; height
  SUB $01
  JR C,HeightPointer
  LD (HeightWait+$0001),A
HeightRepeat:
  LD A,$00                ; HeightRepeat+1: the repeated height
  JR SetHeight
HeightPointer:
  LD HL,$0000             ; HeightPointer+1: the height stream
  LD A,(HL)
  INC HL
  SRL A                   ; bit 0 clear: the height for this pattern only
  JR C,HeightRun
  LD (HeightPointer+$0001),HL
  JR SetHeight
HeightRun:
  LD (HeightRepeat+$0001),A ; bit 0 set: the height and a count byte
  LD B,A
  LD A,(HL)
  INC HL
  LD (HeightPointer+$0001),HL
  LD (HeightWait+$0001),A
  LD A,B
SetHeight:
  LD (LineCounter+$0001),A ; LineCounter = the height (the lines - 1)
LinkerPointer:
  LD HL,$0000             ; LinkerPointer+1: the linker, three track addresses
                          ; a pattern
  LD DE,TrackAPointer+$0001 ; track A's address
  LDI
  LDI
  LD DE,TrackBPointer+$0001 ; track B's
  LDI
  LDI
  LD DE,TrackCPointer+$0001 ; track C's
  LDI
  LDI
  LD (LinkerPointer+$0001),HL
SpecialMode:
  LD A,$00                ; SpecialMode+1: 0 one special track for several
                          ; patterns, 1 a list of them
  OR A
  JR NZ,SpecialListWait
SpecialSameWait:
  LD A,$00                ; SpecialSameWait+1: patterns left that restart
                          ; SpecialStart's track
  SUB $01
  JR C,SpecialListPointer
  LD (SpecialSameWait+$0001),A
SpecialStart:
  LD HL,$0000             ; SpecialStart+1: the special track of the current
                          ; run
  JR ReadSpecial
SpecialListWait:
  LD A,$00                ; SpecialListWait+1: patterns left in the list
  SUB $01
  JR C,SpecialListPointer
  LD (SpecialListWait+$0001),A
  LD HL,(SpecialListPointer+$0001)
  JR SpecialNext
SpecialListPointer:
  LD HL,$0000             ; SpecialListPointer+1: the special-track list
  LD A,(HL)
  INC HL
  SRL A                   ; bit 0 clear: one track for count + 1 patterns
  JR C,SpecialListRun
  LD (SpecialSameWait+$0001),A
  XOR A
  LD (SpecialMode+$0001),A
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (SpecialListPointer+$0001),HL
  EX DE,HL
  LD (SpecialStart+$0001),HL
  JR ReadSpecial
SpecialListRun:
  LD (SpecialListWait+$0001),A ; bit 0 set: count + 1 track addresses follow,
                               ; one a pattern
  LD A,$01
  LD (SpecialMode+$0001),A
SpecialNext:
  LD E,(HL)               ; the next track address of the list
  INC HL
  LD D,(HL)
  INC HL
  LD (SpecialListPointer+$0001),HL
  EX DE,HL
  JR ReadSpecial
SpecialWait:
  LD A,$00                ; SpecialWait+1: the special track's empty lines left
  SUB $01
  JR NC,SpecialSetWait
SpecialPointer:
  LD HL,$0000             ; SpecialPointer+1: the special track
ReadSpecial:
  LD A,(HL)               ; a special line: bit 0 a wait, bit 1 a digidrum,
                          ; else a speed
  INC HL
  SRL A
  JR C,SpecialStore
  SRL A                   ; bit 1
  JR C,SpecialDrum
  LD (Speed+$0001),A      ; the speed
  JR SpecialNoWait
SpecialDrum:
  LD (DigidrumNumber),A   ; the digidrum; SpecialDrum+4 the song's drum channel
                          ; (Init)
  LD A,$01
  LD (DigidrumChannel),A
SpecialNoWait:
  XOR A                   ; no wait
SpecialStore:
  LD (SpecialPointer+$0001),HL ; the pointer past the line
SpecialSetWait:
  LD (SpecialWait+$0001),A ; the wait
TrackAWait:
  LD A,$00                ; TrackAWait+1: track A's empty lines left
  SUB $01
  JR NC,TrackASetWait
TrackAPointer:
  LD HL,$0000             ; TrackAPointer+1: track A
TrackAVolume:
  LD BC,$0100             ; TrackAVolume+1: track A's attenuation (0 loud, 15
                          ; silent), +2 its channel number (1)
TrackAInstrument:
  LD DE,$0000             ; TrackAInstrument+1: the instrument, +2 the
                          ; transposition
TrackANote:
  LD IXL,$00              ; TrackANote+2: the note (before the instrument's
                          ; arpeggio)
  CALL ReadTrackLine      ; the line: IYH = 0 a new note, IYL = its wait, HL'
                          ; the pitch slide
  LD A,IXL                ; the note
  LD (TrackANote+$0002),A
  LD (ChanASlide+$0001),HL ; the slide into ChanASlide
  EXX                     ; the main set again: HL = the track
  LD (TrackAPointer+$0001),HL
  LD A,C                  ; the attenuation into ChanAAtten
  LD (TrackAVolume+$0001),A
  LD (ChanAAtten+$0001),A
  XOR A                   ; a new note? (IYH = 0)
  OR IYH
  JR NZ,TrackAWaitFromLine
  LD (ChanAInstrCounter+$0001),A ; yes: the instrument from its first line
  LD D,A
  LD A,E
  LD (TrackAInstrument+$0001),A
  LD L,D                  ; the pitch sum 0
  LD H,L
  LD (ChanAPitch+$0001),HL
TrackAInstrTable:
  LD HL,$0000             ; TrackAInstrTable+1: the song's instrument table
                          ; (Init)
  EX DE,HL                ; table + 2 x the instrument
  ADD HL,HL
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD DE,ChanAInstrLoop+$0001 ; the instrument's loop address
  LDI
  LDI
  LD DE,ChanAInstrEnd+$0001 ; its end
  LDI
  LDI
  LD DE,ChanAInstrSpeed+$0001 ; its speed
  LDI
  LD DE,ChanAInstrLoops   ; OR A / SCF: it loops or not
  LDI
  LD A,(HL)               ; its retrigger byte, ORed into Retrigger
  INC HL
  LD (ChanAInstrPointer+$0001),HL
  LD HL,Retrigger+$0001
  OR (HL)
  LD (HL),A
TrackAWaitFromLine:
  LD A,IYL                ; the wait
TrackASetWait:
  LD (TrackAWait+$0001),A
TrackBWait:
  LD A,$00                ; track B, as track A
  SUB $01
  JR NC,TrackBSetWait
TrackBPointer:
  LD HL,$0000
TrackBVolume:
  LD BC,$0200             ; +2: channel 2
TrackBInstrument:
  LD DE,$0000
TrackBNote:
  LD IXL,$00
  CALL ReadTrackLine
  LD A,IXL
  LD (TrackBNote+$0002),A
  LD (ChanBSlide+$0001),HL
  EXX
  LD (TrackBPointer+$0001),HL
  LD A,C
  LD (TrackBVolume+$0001),A
  LD (ChanBAtten+$0001),A
  XOR A
  OR IYH
  JR NZ,TrackBWaitFromLine
  LD (ChanBInstrCounter+$0001),A
  LD D,A
  LD A,E
  LD (TrackBInstrument+$0001),A
  LD L,D
  LD H,L
  LD (ChanBPitch+$0001),HL
TrackBInstrTable:
  LD HL,$0000
  EX DE,HL
  ADD HL,HL
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD DE,ChanBInstrLoop+$0001
  LDI
  LDI
  LD DE,ChanBInstrEnd+$0001
  LDI
  LDI
  LD DE,ChanBInstrSpeed+$0001
  LDI
  LD DE,ChanBInstrLoops
  LDI
  LD A,(HL)
  INC HL
  LD (ChanBInstrPointer+$0001),HL
  LD HL,Retrigger+$0001
  OR (HL)
  LD (HL),A
TrackBWaitFromLine:
  LD A,IYL
TrackBSetWait:
  LD (TrackBWait+$0001),A
TrackCWait:
  LD A,$00                ; track C, as track A
  SUB $01
  JR NC,TrackCSetWait
TrackCPointer:
  LD HL,$0000
TrackCVolume:
  LD BC,$0300             ; +2: channel 3
TrackCInstrument:
  LD DE,$0000
TrackCNote:
  LD IXL,$00
  CALL ReadTrackLine
  LD A,IXL
  LD (TrackCNote+$0002),A
  LD (ChanCSlide+$0001),HL
  EXX
  LD (TrackCPointer+$0001),HL
  LD A,C
  LD (TrackCVolume+$0001),A
  LD (ChanCAtten+$0001),A
  XOR A
  OR IYH
  JR NZ,TrackCWaitFromLine
  LD (ChanCInstrCounter+$0001),A
  LD D,A
  LD A,E
  LD (TrackCInstrument+$0001),A
  LD L,D
  LD H,L
  LD (ChanCPitch+$0001),HL
TrackCInstrTable:
  LD HL,$0000
  EX DE,HL
  ADD HL,HL
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD DE,ChanCInstrLoop+$0001
  LDI
  LDI
  LD DE,ChanCInstrEnd+$0001
  LDI
  LDI
  LD DE,ChanCInstrSpeed+$0001
  LDI
  LD DE,ChanCInstrLoops
  LDI
  LD A,(HL)
  INC HL
  LD (ChanCInstrPointer+$0001),HL
  LD HL,Retrigger+$0001
  OR (HL)
  LD (HL),A
TrackCWaitFromLine:
  LD A,IYL
TrackCSetWait:
  LD (TrackCWait+$0001),A
LineCounter:
  LD A,$00                ; LineCounter+1: the pattern's lines left - 1
  SUB $01
  JR C,PatternEnd         ; below 0: the pattern ends
  LD (LineCounter+$0001),A
  JR PlayInstruments
PatternEnd:
  LD A,$37                ; the next line starts a pattern; the song's end
                          ; restarts the streams
  LD (NewPatternFlag),A
  LD HL,(LinkerPointer+$0001) ; the linker at the special list (LinkerEnd): the
                              ; song ended
LinkerEnd:
  LD DE,$0000             ; LinkerEnd+1: the end of the linker (Init: the
                          ; special list's address)
  XOR A
  SBC HL,DE
  JR NZ,PlayInstruments   ; not yet
  LD (TranspWait+$0001),A ; the streams' waits 0
  LD (HeightWait+$0001),A
  LD (SpecialWait+$0001),A
TranspLoop:
  LD HL,$0000             ; TranspLoop+1: the transposition stream's loop point
  LD (TranspPointer+$0001),HL
HeightLoop:
  LD HL,$0000             ; HeightLoop+1
  LD (HeightPointer+$0001),HL
LinkerLoop:
  LD HL,$0000             ; LinkerLoop+1
  LD (LinkerPointer+$0001),HL
SpecialListLoop:
  LD HL,$0000             ; SpecialListLoop+1
  LD (SpecialListPointer+$0001),HL
SpecialModeLoop:
  LD A,$00                ; SpecialModeLoop+1: the special list's mode at its
                          ; loop point (Init)
  LD (SpecialMode+$0001),A
