; --------------------------------------------------------------------------------------------------------------------
; player.asm: The AY player's entries, the tune start, the frame update and the sequencer
;
; Ben Daglish's AY player, a later relative of the one in Terramex (1987): three sequencer records (SeqChannelA-C, one
; per AY channel) read order lists and patterns; three AY channel records (AyChannelA-C) run the volume envelope
; (attack, decay, sustain, release), the vibrato and the pitch slide and are written to the AY every frame by AyUpdate
; $D1C3. Channel A doubles its tone period, so it sounds an octave below B and C (the bass).
;
; The glue at $853F (main memory) drives it at every interrupt, with bank 4 paged in: a tune request in $8452 ($FF
; stop, $FE none, else the tune number, bit 7 = loop) starts StartTune $C0D7 with A AND 15 and is kept in $8453; while
; MusicState $C006 is not 0 the glue tail-jumps to PlayFrame $C17D. When a tune has ended (MusicState 0) the glue
; restarts it if $8453 bit 7 is set, follows tune 2 (the start jingle) with $81 (tune 1 looped, the in-game music)
; when the title page's sound toggle $8455 is 0 (music), and otherwise plays the effect request $8454 through
; PlayEffect $C011 (JP, A = the effect) or, with no effect, runs PlayFrame for the envelopes. $8452 = $FF silences
; through Silence $D182. The requests: $80 title ($5FC0 from $5C4D), 2 at the start of play ($5CDA), $FF at the end
; ($5C45). After the call the glue copies AyChannelA's volume ($D0A2) to $9BA3, the operand that keeps the footstep
; effect 7 from being requested while channel A sounds.
;
; c1: StartTune runs 3 times (title $80, start 2, in-game $81), PlayFrame at every interrupt from the title on (2614
; times in c1, 18045 in menu). Only the menu recording sets the toggle to effects and plays effects (PlayEffect 10
; times).
; --------------------------------------------------------------------------------------------------------------------

; JP StartTune: the player's entry table, slot 0
;
; The entry table of the player as Daglish built it: $C000 start a tune (A =
; the tune), $C003 play one frame, $C006 the state byte, $C007 start an effect,
; $C00A stop. The AY rips use $C000 and $C003 (init and interrupt).
; Switchblade's glue jumps to the routines themselves, so no recording runs the
; table.
;
; Not run in the keyed recordings. Witness: L1 0 ().
StartTuneVector:
  JP StartTune

; JP PlayFrame: the entry table, slot 1
;
; Not run in the keyed recordings. Witness: L1 0 ().
PlayFrameVector:
  JP PlayFrame

; $FF a tune is playing, 1 the last notes are dying away, 0 stopped
;
; Set to $FF by StartTune $C0D7; PlayFrame $C17D sets it to 0 when the three
; order lists have ended and to 1 for as long as a channel still sounds.
; Cleared by StopMusic $C00A. Read by the glue at $856D and $8589: 0 lets it
; restart a looped tune or play effects.
MusicState:
  DEFB $00

; JP PlayEffect: the entry table, slot 2
;
; Not run in the keyed recordings. Witness: L1 0 ().
PlayEffectVector:
  JP PlayEffect

; Stop the tune: MusicState 0, then Silence
;
; The entry table's slot 3. No code in the game calls it (the glue silences
; with Silence $D182 directly and leaves MusicState alone).
;
; Not run in the keyed recordings. Witness: L1 0 ().
StopMusic:
  XOR A
  LD (MusicState),A
  JP Silence

; Start sound effect A on channel A
;
; A = the effect number (0-13). IY = Effects $CF60 + 13 x A, the record: its
; first ten bytes are an instrument, +$0A/+$0B the tone period, +$0C the gate
; time. StartNote $D0DA starts it on AyChannelA (IX = $D09D) with HL = the
; period and C = the gate time, then bit 7 of the channel's flags (+$11) locks
; the channel against the tune until the release ends (EnvRelease $D358 clears
; it).
;
; Called only by the glue's JP at $859B, with no tune playing (MusicState 0)
; and the request $8454 not $FF. menu runs it 10 times (the records of effects
; 7, 10 and 11 are read), after its title page set the toggle $8455 to effects.
;
; Witness: L1 10 (menu).
PlayEffect:
  PUSH IX
  PUSH IY
  LD IX,AyChannelA        ; IX = the AY record of channel A: effects play on
                          ; channel A only
  LD L,A                  ; HL = 13 x A
  LD E,A
  LD H,$00
  LD D,H
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD IY,Effects           ; IY = the effect's record
  EX DE,HL
  ADD IY,DE
  LD L,(IY+$0A)           ; HL = the period, C = the gate time
  LD H,(IY+$0B)
  LD C,(IY+$0C)
  CALL StartNote
  SET 7,(IX+$11)          ; lock channel A: the sequencer leaves it alone, the
                          ; arpeggio does not touch it
  POP IY
  POP IX
  RET

  ORG $C0D7

; Start tune A: silence the AY, point the three channels at the tune's order
; lists, reset the state
;
; A = the tune (0 title, 1 in-game, 2 start; the glue passes the request AND
; 15). Silence $D182 first. The three order-list pointers of TuneTable $CCF1 +
; 6 x A go to the records' +$01/+$02. Per channel: the transpose, the arpeggio,
; the slide switch and state and the drum switch cleared; the pattern-end flag
; $FF, the repeat count 1 and the event timer 1, so the first PlayFrame reads
; the order list at once; every slot of SlotTables set to instrument n; the
; instrument pointer at Instruments $CED4 (record 0); the order list running
; ($FF); MusicState $FF and DrumTimer $FF.
;
; Called by the glue at $856A (c1: 3 times, the title, the start jingle and the
; in-game tune).
;
; Witness: L1 27 (c1, deaths, gameover, menu, opt x3).
StartTune:
  PUSH AF
  CALL Silence
  POP AF
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,A
  LD HL,TuneTable         ; HL = TuneTable + 6 x A
  ADD A,L
  LD L,A
  JR NC,SetOrderPointers
  INC H
SetOrderPointers:
  LD E,(HL)               ; the three order-list pointers to +$01/+$02 of each
                          ; record
  INC HL
  LD D,(HL)
  INC HL
  LD (SeqChannelA+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (SeqChannelB+$0001),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (SeqChannelC+$0001),DE
  XOR A                   ; transpose, arpeggio, slide switch, slide state and
                          ; drum switch = 0 on the three channels
  LD (SeqChannelA+$000A),A
  LD (SeqChannelB+$000A),A
  LD (SeqChannelC+$000A),A
  LD (SeqChannelA+$000F),A
  LD (SeqChannelB+$000F),A
  LD (SeqChannelC+$000F),A
  LD (SeqChannelA+$0015),A
  LD (SeqChannelB+$0015),A
  LD (SeqChannelC+$0015),A
  LD (SeqChannelA+$0019),A
  LD (SeqChannelB+$0019),A
  LD (SeqChannelC+$0019),A
  LD (SeqChannelA+$0020),A
  LD (SeqChannelB+$0020),A
  LD (SeqChannelC+$0020),A
  CPL                     ; pattern-end flags = $FF
  LD (SeqChannelA+$000B),A
  LD (SeqChannelB+$000B),A
  LD (SeqChannelC+$000B),A
  LD A,$01                ; repeat counts and event timers = 1
  LD (SeqChannelA+$0009),A
  LD (SeqChannelB+$0009),A
  LD (SeqChannelC+$0009),A
  LD (SeqChannelA+$000C),A
  LD (SeqChannelB+$000C),A
  LD (SeqChannelC+$000C),A
  LD HL,SlotTables        ; three channels: slot n = 10 x n
  LD BC,$030A
ResetSlotsChannel:
  XOR A
ResetSlotsLoop:
  LD (HL),A
  INC HL
  ADD A,C
  LD (HL),A
  INC HL
  ADD A,C
  CP $A0
  JR NZ,ResetSlotsLoop
  DJNZ ResetSlotsChannel
  LD HL,Instruments       ; instrument 0 on every channel
  LD (SeqChannelA+$0007),HL
  LD (SeqChannelB+$0007),HL
  LD (SeqChannelC+$0007),HL
  LD A,$FF                ; order lists running, MusicState $FF, no noise burst
  LD (SeqChannelA+$000D),A
  LD (SeqChannelB+$000D),A
  LD (SeqChannelC+$000D),A
  LD (MusicState),A
  LD (DrumTimer),A
  RET

; Play one frame: update and write the AY, then step the three sequencers
;
; The glue's every-frame call (JP at $8571 or $8597; its RET returns to the
; glue at $8549). AyUpdate $D1C3 first (envelopes, vibrato, the registers).
; Then, if MusicState $C006 is not 0: MusicState = the three records' +$0D ORed
; (0 when every order list has ended); while some list runs, SequenceChannel
; $C1C5 for A, B and C; when all have ended, MusicState stays 1 as long as a
; channel still sounds (AyMixer has a channel on) and becomes 0 when all are
; off.
;
; Witness: L1 49267 (c1, deaths, gameover, menu, rooms, opt x3).
PlayFrame:
  CALL AyUpdate
  LD A,(MusicState)
  AND A
  RET Z
  LD A,(SeqChannelA+$000D) ; all three order lists ended?
  LD HL,SeqChannelB+$000D
  OR (HL)
  LD HL,SeqChannelC+$000D
  OR (HL)
  LD (MusicState),A
  JR NZ,SequenceChannels
  XOR A                   ; yes: MusicState 0, or 1 while a channel still
                          ; sounds
  LD (MusicState),A
  LD A,(AyMixer)
  AND $3F
  CP $3F
  RET Z
  LD A,$01
  LD (MusicState),A
  RET
SequenceChannels:
  LD IY,SeqChannelA       ; IY = the sequencer record, IX = the AY record, for
                          ; A, B, C
  LD IX,AyChannelA
  CALL SequenceChannel
  LD IY,SeqChannelB
  LD IX,AyChannelB
  CALL SequenceChannel
  LD IY,SeqChannelC       ; channel C falls into SequenceChannel
  LD IX,AyChannelC

; Step one channel's sequencer by a frame: the arpeggio, the slide, the
; patterns
;
; IY = the sequencer record, IX = the AY record. UpdateArpeggio $C390 and
; UpdatePortamento $C420 first. When the pattern has ended (+$0B not 0): one
; repeat less; while repeats remain the pattern starts again, else
; ReadOrderList reads the order list. Then the event timer +$0C counts down;
; while it runs, one pending command byte is taken ahead (so a pattern's end
; mark $FF is seen on the frame before the last note ends); at 0 the commands
; are read up to the next event: a note (0-$7D, then its length), $7E (a raw
; period word, then the length) or $7F (a rest: the length only; the playing
; note runs on to its release).
;
; A note: the index + the transpose (+$0A), stored as the note playing (+$0E),
; picks the period from NoteTable $D016; with the slide on, the slide's target
; is the note + interval (+$18) and its whole change goes to +$1E/+$1F. The
; arpeggio state becomes $C0 + the arpeggio, the length goes to +$0C, IY
; becomes the instrument and, unless an effect holds the channel, StartNote
; $D0DA starts it (DrumPending = the drum switch).
;
; The order list (ReadOrderList): $00-$7F play pattern n (PatternAddrLo/Hi
; $CC97/$CCC4), $80-$BF the next pattern n times (low five bits), $C0-$FB n, m
; slot n (low four bits) = instrument m, $FC one byte skipped, $FD a, b three
; bytes skipped, $FE t the transpose t, $FF the end (+$0D = 0, the channel
; stops reading). As order-list codes $FC and $FD are in no tune (the code at
; $C1FC and $C206 ran in no recording); as pattern commands they are the drums
; (ReadPatternCommand).
;
; Witness: L1 137559 (c1, deaths, gameover, menu, rooms, opt x3).
SequenceChannel:
  CALL UpdateArpeggio
  CALL UpdatePortamento
  LD A,(IY+$0B)
  AND A
  JP Z,ContinuePattern
PatternEnded:
  DEC (IY+$09)            ; the pattern's end: repeat it or read the order list
  JR Z,ReadOrderList
  LD A,(IY+$03)
  LD (IY+$05),A
  LD A,(IY+$04)
  LD (IY+$06),A
  LD (IY+$0B),$00
  JR ContinuePattern
ReadOrderList:
  LD (IY+$09),$01         ; the repeat count 1 unless the list says otherwise
  LD L,(IY+$01)
  LD H,(IY+$02)
OrderListLoop:
  LD A,(HL)
  CP $80
  JR C,OrderPattern
  CP $FD                  ; $FD a b: skipped
  JR NZ,OrderNotFD
  INC HL
  INC HL
  INC HL
  JP OrderListLoop
OrderNotFD:
  CP $FC
  JR NZ,OrderNotFC
  INC HL
  JP OrderListLoop
OrderNotFC:
  CP $FE                  ; $FE t: the transpose
  JR NZ,OrderNotFE
  INC HL
  LD A,(HL)
  LD (IY+$0A),A
  INC HL
  JP OrderListLoop
OrderNotFE:
  CP $FF                  ; $FF: the channel's order list ends
  JR NZ,OrderNotEnd
  XOR A
  LD (IY+$0D),A
  RET
OrderNotEnd:
  CP $C0                  ; $80-$BF: the repeat count
  JR NC,OrderSetSlot
  AND $1F
  LD (IY+$09),A
  INC HL
  JP OrderListLoop
OrderSetSlot:
  AND $0F                 ; $C0-$FB n, m: slot n of this channel = 10 x m
  ADD A,(IY+$00)
  LD DE,SlotTables
  ADD A,E
  LD E,A
  JR NC,OrderSlotAddressed
  INC D
OrderSlotAddressed:
  INC HL
  LD A,(HL)
  INC HL
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD (DE),A
  JP OrderListLoop
OrderPattern:
  LD (IY+$0B),$00         ; $00-$7F: the pattern's address from PatternAddrLo /
                          ; PatternAddrHi
  INC HL
  LD (IY+$01),L
  LD (IY+$02),H
  LD C,A
  LD B,$00
  LD HL,PatternAddrLo
  ADD HL,BC
  LD E,(HL)
  LD HL,PatternAddrHi
  ADD HL,BC
  LD D,(HL)
  LD (IY+$03),E
  LD (IY+$04),D
  JR CountEvent
ContinuePattern:
  LD E,(IY+$05)           ; DE = the pattern pointer
  LD D,(IY+$06)
CountEvent:
  DEC (IY+$0C)            ; the event timer: still running?
  JR Z,ReadEvent
  LD A,(DE)               ; yes: take one command byte ahead
  CP $80
  CALL NC,ReadPatternCommand
  LD (IY+$05),E
  LD (IY+$06),D
  RET
ReadEvent:
  LD A,(DE)               ; read commands up to the next event
  CP $80
  JR C,ReadEventKind
  CALL ReadPatternCommand
  LD A,(IY+$0B)
  AND A
  JR Z,ReadEvent
  JP PatternEnded         ; a $FF read here (not ahead): the end at once. Ran
                          ; in no recording: the look-ahead always finds it
ReadEventKind:
  CP $7F                  ; $7F: a rest
  JP Z,EventRest
  CP $7E                  ; $7E lo hi: a raw tone period
  JR NZ,EventNoteIndex
  INC DE
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  JP EventStart
EventNoteIndex:
  ADD A,(IY+$0A)          ; a note: +$0E = index + transpose, HL = its period
  LD (IY+$0E),A
  LD HL,NoteTable
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(IY+$15)           ; the slide on: set it up for this note
  LD (IY+$19),A
  AND A
  JR Z,EventStart
  LD A,(IY+$16)
  LD (IY+$1A),A
  LD A,(IY+$17)
  LD (IY+$1B),A
  LD A,(IY+$18)
  ADD A,(IY+$0E)          ; the target: the note + the slide interval
  PUSH HL
  LD HL,NoteTable
  ADD A,A
  LD C,A
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  POP BC
  AND A
  SBC HL,BC               ; +$1E/+$1F = target period - the note's period
  LD (IY+$1E),L
  LD (IY+$1F),H
  LD H,B
  LD L,C
EventStart:
  LD A,(IY+$0F)           ; the arpeggio state, the length, the pattern
                          ; pointer, IY = the instrument
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
  BIT 7,(IX+$11)          ; an effect holds the channel: no note
  RET NZ
  LD A,(IY+$20)           ; DrumPending = the drum switch
  LD (DrumPending),A
  JP StartNote            ; start the note
EventRest:
  INC DE                  ; a rest: the length only
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD (IY+$05),E
  LD (IY+$06),D
  RET

; Take one pattern command byte at DE
;
; DE = the pattern pointer, A = (DE) >= $80. $80-$8B: instrument slot n (low
; four bits): +$07/+$08 = Instruments $CED4 + the slot's offset (SlotTables).
; $FF: the pattern's end (+$0B = $FF, DE stays on it). $8C-$BF: the arpeggio,
; low four bits (the tunes use $90 + n). $C0 a b c: the slide on, delay a,
; steps b, interval c semitones; $C1: the slide off. $FC: the drum off; $FD a
; b: the drum on, a burst of a frames at noise period b (DrumLength, DrumNoise;
; every note of the channel from now on). Others ($C2-$FB, $FE): skipped (the
; RET at $C38F ran in no recording).
;
; Called by SequenceChannel $C1C5 at $C274 (ahead) and $C283.
;
; Witness: L1 11309 (c1, deaths, gameover, menu, rooms, opt x3).
ReadPatternCommand:
  LD A,(DE)
  CP $8C
  JR NC,CommandNotInstrument
  AND $0F                 ; $80-$8B: the instrument in slot n
  ADD A,(IY+$00)
  LD C,A
  LD B,$00
  LD HL,SlotTables
  ADD HL,BC
  LD C,(HL)
  LD HL,Instruments
  ADD HL,BC
  LD (IY+$07),L
  LD (IY+$08),H
  INC DE
  RET
CommandNotInstrument:
  CP $FF                  ; $FF: the pattern's end
  JR NZ,CommandNotEnd
  LD (IY+$0B),$FF
  RET
CommandNotEnd:
  CP $C0                  ; $8C-$BF: the arpeggio number
  JR NC,CommandC0Up
  AND $0F
  LD (IY+$0F),A
  INC DE
  RET
CommandC0Up:
  INC DE                  ; $C0 and up: past the command byte; $C1 the slide
                          ; off
  CP $C1
  JR NZ,CommandNotC1
  LD (IY+$15),$00
  RET
CommandNotC1:
  CP $C0                  ; $C0 a b c: the slide on
  JR NZ,CommandNotC0
  LD (IY+$15),$FF
  LD A,(DE)
  INC DE
  LD (IY+$16),A
  LD A,(DE)
  INC DE
  LD (IY+$17),A
  LD A,(DE)
  INC DE
  LD (IY+$18),A
  RET
CommandNotC0:
  CP $FC                  ; $FC: the drum off
  JR NZ,CommandNotFC
  LD (IY+$20),$00
  RET
CommandNotFC:
  CP $FD                  ; $FD a b: the drum on
  JR NZ,CommandUnknown
  LD (IY+$20),$FF
  LD A,(DE)
  INC DE
  LD (DrumLength),A
  LD A,(DE)
  INC DE
  LD (DrumNoise),A
  RET
CommandUnknown:
  RET                     ; any other byte: skipped

; Step the channel's arpeggio: a list of semitone offsets played over the note
;
; IY = the sequencer record, IX = the AY record. Nothing while an effect holds
; the channel or the state +$14 has bit 7 clear. Arpeggio 0: none (bit 7
; cleared). The first frame of a note (bit 6) and the end of a looping list
; start the list at Arpeggios-8 + 8 x n: its header byte gives the first step's
; frames (bits 3-5), the steps (bits 0-2, + 1) and the loop (bit 7); the first
; step plays the note itself. Each later step is one byte: bits 3-7 the offset
; in semitones, bits 0-2 the frames. A step writes the tone period of note +
; offset (NoteTable) to the AY record's +$03/+$04.
;
; Every arpeggio of the tunes is a three-note chord stepped one frame a note
; (header $8A: the note, then two offsets).
;
; Witness: L1 137559 (c1, deaths, gameover, menu, rooms, opt x3).
UpdateArpeggio:
  BIT 7,(IX+$11)
  RET NZ
  LD A,(IY+$14)
  BIT 7,A
  RET Z
  AND $3F                 ; arpeggio 0: off
  JR NZ,ArpeggioRunning
  RES 7,(IY+$14)
  RET
ArpeggioRunning:
  LD D,$07                ; D = 7: the frame mask, and the high byte of $700
                          ; below
  BIT 6,(IY+$14)
  JR NZ,ArpeggioStart
  DEC (IY+$12)            ; the step's frames
  RET NZ
  DEC (IY+$13)            ; the steps left: at 0 start the list again
  JP Z,ArpeggioStart
  LD L,(IY+$10)           ; the next step
  LD H,(IY+$11)
  INC L
  LD (IY+$10),L
  JP NZ,ArpeggioStep
  INC H
  LD (IY+$11),H
ArpeggioStep:
  LD A,(HL)               ; frames = bits 0-2, note offset = bits 3-7
  AND D
  LD (IY+$12),A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IY+$0E)
  JP SetNotePeriod
ArpeggioStart:
  LD HL,Arpeggios-$708    ; HL = Arpeggios-8 + 8n: A = (n + $80 or $C0) x 8
                          ; drops the $80 / $C0, D = 7 adds $700
  LD A,(IY+$14)
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  ADD HL,DE
  BIT 7,(HL)
  JR NZ,ArpeggioHeader
  BIT 6,(IY+$14)          ; no loop: start only on the note's first frame. Ran
                          ; in no recording (every list loops)
  JR NZ,ArpeggioHeader
  LD (IY+$13),$01         ; else hold the last step
  RET
ArpeggioHeader:
  RES 6,(IY+$14)          ; the first step's frames and the step count from the
                          ; header
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
  LD A,(IY+$0E)           ; the first step: the note itself
SetNotePeriod:
  ADD A,A                 ; A = the note: the period from NoteTable to the AY
                          ; record's +$03/+$04
  LD HL,NoteTable
  ADD A,L
  LD L,A
  JR NC,SetNotePeriodHigh
  INC H
SetNotePeriodHigh:
  LD A,(HL)
  INC HL
  LD (IX+$03),A
  LD A,(HL)
  LD (IX+$04),A
  RET

; Step the channel's pitch slide
;
; IY = the sequencer record, IX = the AY record. State +$19: 0 off. $FF (set at
; the note): the step = the whole change +$1E/+$1F divided by the steps +$1B (a
; signed 16 by 8 bit division, done on the magnitude), state 1. Then the delay
; +$1A counts down; after it, each frame adds the step to the AY record's slide
; offset +$12/+$13 until the steps run out; then the offset is the whole change
; exactly and the state 0. StartNote $D0DA clears the offset at every note.
;
; Witness: L1 137559 (c1, deaths, gameover, menu, rooms, opt x3).
UpdatePortamento:
  LD A,(IY+$19)
  AND A
  RET Z
  JP P,PortamentoDelay
  LD D,$00                ; set up: DE = the steps, CA = the change
  LD E,(IY+$1B)
  LD HL,$0000
  LD C,(IY+$1E)
  LD A,(IY+$1F)
  AND A
  JP M,DivideNegative
  LD B,$10                ; a positive change: CA / E
DivideLoop:
  RL C
  RLA
  ADC HL,HL
  SBC HL,DE
  JR NC,DivideNoAdd
  ADD HL,DE
DivideNoAdd:
  CCF
  DJNZ DivideLoop
  RL C                    ; the quotient's last bit; the step to +$1C/+$1D
  RLA
  LD (IY+$1C),C
  LD (IY+$1D),A
  LD (IY+$19),$01
  JR PortamentoDelay
DivideNegative:
  CPL                     ; a negative change: divide the magnitude, negate the
                          ; quotient
  LD B,A
  LD A,C
  CPL
  LD C,A
  INC BC
  LD A,B
  LD B,$10
DivideNegativeLoop:
  RL C
  RLA
  ADC HL,HL
  SBC HL,DE
  JR NC,DivideNegativeNoAdd
  ADD HL,DE
DivideNegativeNoAdd:
  CCF
  DJNZ DivideNegativeLoop
  RL C
  RLA
  CPL
  LD B,A
  LD A,C
  CPL
  LD C,A
  INC BC
  LD (IY+$1C),C
  LD (IY+$1D),B
  LD (IY+$19),$01
PortamentoDelay:
  LD A,(IY+$1A)           ; the delay first
  AND A
  JR Z,PortamentoStep
  DEC (IY+$1A)
  RET
PortamentoStep:
  LD A,(IY+$1B)           ; a step: the offset += the step
  AND A
  JR Z,PortamentoDone
  DEC (IY+$1B)
  LD A,(IY+$1C)
  ADD A,(IX+$12)
  LD (IX+$12),A
  LD A,(IY+$1D)
  ADC A,(IX+$13)
  LD (IX+$13),A
  RET
PortamentoDone:
  LD A,(IY+$1E)           ; the end: the offset = the whole change, the slide
                          ; off
  LD (IX+$12),A
  LD A,(IY+$1F)
  LD (IX+$13),A
  LD (IY+$19),$00
  RET
