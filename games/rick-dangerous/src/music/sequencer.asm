; --------------------------------------------------------------------------------------------------------------------
; sequencer.asm: The tune sequencer: three tracks of order lists and patterns, started by AyPlayTune, stepped by AyTick
;
; A tune is three order lists, one a channel (TuneTable $CA8F, 6 bytes a tune). An order list names patterns, with
; repeat counts and transposes; a pattern is a list of notes, each with its duration in frames, and instrument
; changes. The three track records (Track0-Track2, 21 bytes each) follow the lists; AyTick $C46C steps them once a
; frame from the IM 2 handler. The format and the editable text are in src/res/music/README.md.
;
; A note never takes a channel that an effect holds (channel +17 bit 7): the effect plays to its end over the tune,
; which goes on silently on that channel until its next note there.
; --------------------------------------------------------------------------------------------------------------------

; Not run: a jump table of an earlier build (JP `$A016`, JP AyTick, the flag,
; JP OldPlayEffect)
;
; Known only from the code. Nothing jumps here: the game calls AyPlayTune
; $C3E4, AyTick $C46C and AyPlayEffect $C685 directly. The first jump goes to
; `$A016`, the game's own AyPlayTune in RAM 2, so the table was made for a
; build where this code sat elsewhere.
OldEntries:
  JP $A016

; Not run: JP AyTick
;
; Known only from the code.
OldTick:
  JP AyTick

; The music flag: `$FF` after AyPlayTune, 1 while the last notes die away, 0
; when the tune is over
;
; AyPlayTune sets `$FF`; AyTick ORs the three tracks' active bytes (+13) into
; it, and when all three order lists have ended it is 1 until every channel is
; silent, then 0. AyTick steps the tracks only while it is not 0.
MusicOn:
  DEFB $00

; Not run: JP OldPlayEffect
;
; Known only from the code.
OldJumps:
  JP OldPlayEffect

; Not run: MusicOn = 0, then SilenceAll
;
; Known only from the code.
OldStopMusic:
  XOR A
  LD (MusicOn),A
  JP SilenceAll

; Not run: an older AyPlayEffect, always on channel A
;
; Known only from the code. The same record address as AyPlayEffect
; (EffectTable + 13A), always channel A, and the channel marked busy (+17 bit
; 7) after StartNote; DI / EI round it.
OldPlayEffect:
  DI
  LD L,A
  LD E,A
  LD H,$00
  LD D,H
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD IY,EffectTable
  EX DE,HL
  ADD IY,DE
  LD L,(IY+$0A)
  LD H,(IY+$0B)
  LD C,(IY+$0C)
  LD IX,ChannelA
  CALL StartNote
  SET 7,(IX+$11)
  EI
  RET

; Track 0 (channel A): +0 instrument map offset, +1/+2 order list pointer,
; +3/+4 pattern start, +5/+6 pattern pointer
;
; The track record (IY), 21 bytes: +0 its 8 slots' offset in InstrumentMap (0,
; 8, 16 as loaded; never written), +1/+2 the next order list byte, +3/+4 the
; pattern's start (for a repeat), +5/+6 the next pattern byte, +7/+8 the
; instrument, +9 the repeats left, +10 the transpose (semitones), +11 `$FF`
; when the pattern has ended, +12 the frames left of the note, +13 active (0
; when its order list has ended), +14 the note's period index, +15 the ornament
; number, +16/+17 the ornament pointer, +18 the ornament step's frames, +19 the
; steps left, +20 the ornament state (bit 7 on, bit 6 restart, bits 0-5 the
; number).
Track0:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Track 1 (channel B), map offset 8
Track1:
  DEFB $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Track 2 (channel C), map offset 16
Track2:
  DEFB $10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Each track's 8 instrument slots: an offset into Instruments, 0-70 step 10,
; set by AyPlayTune
;
; A pattern's `$80`-`$87` takes slot 0-7 here; an order list's `$C0`-`$FD` byte
; puts the next byte into a slot (no tune does). AyPlayTune fills all three
; with 0, 10, ... 70, so slot N is instrument N.
InstrumentMap:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Start tune A (0-7): silence, point the three tracks at the tune's order
; lists, MusicOn = `$FF`
;
; Called from the game's AyPlayTune `$A016` (128K only) with A = the tune.
; Calls SilenceAll, reads the tune's three order list pointers from TuneTable +
; 6A, then for each track: repeats 1, transpose 0, pattern ended, the note's
; frames 1, active, ornament 0, instrument Instruments (0); InstrumentMap to 0,
; 10, ... 70. The tunes and their call sites: 0 `$E324` (a level's intro), 1-4
; `$AC20` (a level's end, the number from `$E4AD`), 5 `$E220`, 6 `$E386`, 7
; `$F531` (the bonus end marker).
;
; Witness: L1 30 (c1, controls, ending, ending2, gameover, level1).
AyPlayTune:
  PUSH AF
  CALL SilenceAll
  POP AF
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A
  LD HL,TuneTable
  ADD A,L
  LD L,A
  JR NC,PlayTuneLists
  INC H
PlayTuneLists:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (Track0+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (Track1+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (Track2+$0001),DE
  XOR A
  LD (Track0+$000A),A
  LD (Track1+$000A),A
  LD (Track2+$000A),A
  LD (Track0+$000F),A
  LD (Track1+$000F),A
  LD (Track2+$000F),A
  CPL
  LD (Track0+$000B),A
  LD (Track1+$000B),A
  LD (Track2+$000B),A
  LD A,$01
  LD (Track0+$0009),A
  LD (Track1+$0009),A
  LD (Track2+$0009),A
  LD (Track0+$000C),A
  LD (Track1+$000C),A
  LD (Track2+$000C),A
  LD HL,InstrumentMap
  LD BC,$030A
PlayTuneMapRow:
  XOR A
PlayTuneMapLoop:
  LD (HL),A
  INC HL
  ADD A,C
  LD (HL),A
  INC HL
  ADD A,C
  CP $50
  JR NZ,PlayTuneMapLoop
  DJNZ PlayTuneMapRow
  LD HL,Instruments
  LD (Track0+$0007),HL
  LD (Track1+$0007),HL
  LD (Track2+$0007),HL
  LD A,$FF
  LD (Track0+$000D),A
  LD (Track1+$000D),A
  LD (Track2+$000D),A
  LD (MusicOn),A
  RET

; Once a frame (the IM 2 handler, through `$A030`): UpdateAy, then step the
; three tracks while a tune plays
;
; UpdateAy runs every frame, for the effects too. While MusicOn is not 0 the
; three tracks' active bytes are ORed: all ended, MusicOn = 1 while a channel
; still sounds, then 0; else TrackStep for tracks 0, 1, 2 on channels A, B, C
; (the last falls into TrackStep).
;
; Witness: L1 47434 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
AyTick:
  CALL UpdateAy
  LD A,(MusicOn)
  AND A
  RET Z
  LD A,(Track0+$000D)
  LD HL,Track1+$000D
  OR (HL)
  LD HL,Track2+$000D
  OR (HL)
  LD (MusicOn),A
  JR NZ,MusicTickTracks
  XOR A
  LD (MusicOn),A
  LD A,(MixerShadow)
  AND $3F
  CP $3F
  RET Z
  LD A,$01
  LD (MusicOn),A
  RET
MusicTickTracks:
  LD IY,Track0
  LD IX,ChannelA
  CALL TrackStep
  LD IY,Track1
  LD IX,ChannelB
  CALL TrackStep
  LD IY,Track2
  LD IX,ChannelC

; One track's frame: count the note down; at its end read the next pattern
; bytes (and order list bytes)
;
; OrnamentStep first. While the note's frames last (+12), the pattern pointer
; is only moved past command bytes. At 0 the next pattern byte: `$80`-`$FF`
; commands (PatternCommand $C5BB), `$7F` a rest (the next byte: frames), `$7E`
; a period word then frames, else a note: PeriodTable[note + transpose + 12],
; the next byte its frames, and StartNote with the track's instrument unless an
; effect holds the channel.
;
; At a pattern's `$FF` the repeat count runs down (the same pattern again),
; then the order list is read: under `$80` a pattern number (PatternLo /
; PatternHi), `$80`-`$BF` the repeats (bits 0-4) of the next pattern,
; `$C0`-`$FD` an InstrumentMap slot (bits 0-2) and its value, `$FE` a
; transpose, `$FF` the end (active = 0).
;
; Witness: L1 43833 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
TrackStep:
  CALL OrnamentStep
  LD A,(IY+$0B)
  AND A
  JR Z,TrackPatternBytes
TrackNextPattern:
  DEC (IY+$09)
  JR Z,TrackOrderList
  LD A,(IY+$03)
  LD (IY+$05),A
  LD A,(IY+$04)
  LD (IY+$06),A
  LD (IY+$0B),$00
  JR TrackPatternBytes
TrackOrderList:
  LD (IY+$09),$01
  LD L,(IY+$01)
  LD H,(IY+$02)
TrackOrderByte:
  LD A,(HL)
  CP $80
  JR C,TrackOrderPattern
  CP $FE
  JR NZ,TrackOrderEnd
  INC HL
  LD A,(HL)
  LD (IY+$0A),A
  INC HL
  JP TrackOrderByte
TrackOrderEnd:
  CP $FF
  JR NZ,TrackOrderRepeat
  XOR A
  LD (IY+$0D),A
  RET
TrackOrderRepeat:
  CP $C0
  JR NC,TrackOrderMap
  AND $1F
  LD (IY+$09),A
  INC HL
  JP TrackOrderByte
TrackOrderMap:
  AND $07
  ADD A,(IY+$00)
  LD DE,InstrumentMap
  ADD A,E
  LD E,A
  JR NC,TrackOrderMapStore
  INC D
TrackOrderMapStore:
  INC HL
  LDI
  JP TrackOrderByte
TrackOrderPattern:
  LD (IY+$0B),$00
  INC HL
  LD (IY+$01),L
  LD (IY+$02),H
  LD C,A
  LD B,$00
  LD HL,PatternLo
  ADD HL,BC
  LD E,(HL)
  LD HL,PatternHi
  ADD HL,BC
  LD D,(HL)
  LD (IY+$03),E
  LD (IY+$04),D
  JR TrackCountDown
TrackPatternBytes:
  LD E,(IY+$05)
  LD D,(IY+$06)
TrackCountDown:
  DEC (IY+$0C)
  JR Z,TrackNextByte
  LD A,(DE)
  CP $80
  CALL NC,PatternCommand
  LD (IY+$05),E
  LD (IY+$06),D
  RET
TrackNextByte:
  LD A,(DE)
  CP $80
  JR C,TrackNote
  CALL PatternCommand
  LD A,(IY+$0B)
  AND A
  JR Z,TrackNextByte
  JP TrackNextPattern
TrackNote:
  CP $7F
  JR Z,TrackRest
  CP $7E
  JR NZ,TrackNoteIndex
  INC DE
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  JP TrackNoteStart
TrackNoteIndex:
  ADD A,(IY+$0A)
  ADD A,$0C
  LD (IY+$0E),A
  LD HL,PeriodTable
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
TrackNoteStart:
  LD A,(IY+$0F)
  OR $C0
  LD (IY+$14),A
  INC DE
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD C,A
  LD (IY+$05),E
  LD (IY+$06),D
  LD E,(IY+$07)
  LD A,(IY+$08)
  LD IYH,A
  LD IYL,E
  BIT 7,(IX+$11)
  RET NZ
  JP StartNote
TrackRest:
  INC DE
  LD A,(DE)
OrnamentBase:
  INC DE                  ; OrnamentStep's table base: ornament N at
                          ; OrnamentBase + 8N lies in this code (no tune has
                          ; one)
  LD (IY+$0C),A
  LD (IY+$05),E
  LD (IY+$06),D
  RET

; A pattern command byte at DE: `$80`-`$87` instrument slot, `$88`-`$BF`
; ornament, `$FF` pattern end, `$C0`-`$FE` skipped
;
; `$80`-`$87`: the instrument = Instruments + InstrumentMap[track +0 + bits
; 0-2]. `$88`-`$BF`: the ornament number (bits 0-3) for the next notes. `$FF`:
; the track's pattern ended (+11 = `$FF`). `$C2` is skipped alone, the other
; `$C0`-`$FE` with three more bytes. The tunes use only `$80`-`$85` and `$FF`.
;
; Witness: L1 1892 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
PatternCommand:
  LD A,(DE)
  CP $88
  JR NC,PatternCommandEnd
  AND $07
  ADD A,(IY+$00)
  LD C,A
  LD B,$00
  LD HL,InstrumentMap
  ADD HL,BC
  LD C,(HL)
  LD HL,Instruments
  ADD HL,BC
  LD (IY+$07),L
  LD (IY+$08),H
  INC DE
  RET
PatternCommandEnd:
  CP $FF
  JR NZ,PatternCommandOrnament
  LD (IY+$0B),$FF
  RET
PatternCommandOrnament:
  CP $C0
  JR NC,PatternCommandSkip
  AND $0F
  LD (IY+$0F),A
  INC DE
  RET
PatternCommandSkip:
  INC DE
  CP $C2
  RET Z
  INC DE
  INC DE
  INC DE
  RET

; Step the track's ornament (a per-note arpeggio): the period moves through
; table offsets
;
; Every note sets +20 = ornament | `$C0`, and with ornament 0 (every tune)
; OrnamentStep clears bit 7 and returns. Beyond that it is known only from the
; code: with a number N it would read bytes at OrnamentBase + 8N (bits 0-2
; frames, bits 3-7 semitones over the note), which lie inside TrackStep's code:
; the ornament table of the original player was not kept.
;
; Witness: L1 43833 (L1Z4, c1, controls, ending, ending2, gameover,
; level1-level4).
OrnamentStep:
  BIT 7,(IX+$11)
  RET NZ
  LD A,(IY+$14)
  BIT 7,A
  RET Z
  AND $3F
  JR NZ,OrnamentRun
  RES 7,(IY+$14)
  RET
OrnamentRun:
  LD D,$07
  BIT 6,(IY+$14)
  JR NZ,OrnamentStart
  DEC (IY+$12)
  RET NZ
  DEC (IY+$13)
  JP Z,OrnamentStart
  LD L,(IY+$10)
  LD H,(IY+$11)
  INC L
  LD (IY+$10),L
  JP NZ,OrnamentNext
  INC H
  LD (IY+$11),H
OrnamentNext:
  LD A,(HL)
  AND D
  LD (IY+$12),A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IY+$0E)
  JP OrnamentPeriod
OrnamentStart:
  LD HL,OrnamentBase
  LD A,(IY+$14)
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  ADD HL,DE
  BIT 7,(HL)
  JR NZ,OrnamentLoad
  BIT 6,(IY+$14)
  JR NZ,OrnamentLoad
  LD (IY+$13),$01
  RET
OrnamentLoad:
  RES 6,(IY+$14)
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND D
  LD (IY+$12),A
  LD A,(HL)
  AND D
  INC A
  LD (IY+$13),A
  LD (IY+$10),L
  LD (IY+$11),H
  LD A,(IY+$0E)
OrnamentPeriod:
  ADD A,A
  LD HL,PeriodTable
  ADD A,L
  LD L,A
  JR NC,OrnamentSetPeriod
  INC H
OrnamentSetPeriod:
  LD A,(HL)
  LD (IX+$03),A
  INC HL
  LD A,(HL)
  LD (IX+$04),A
  RET
