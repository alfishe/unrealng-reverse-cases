; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The sound: the tune player (two beeper channels and drums on its own interrupt), the tunes, the effects
;
; TunePlay ($F852) plays a tune with A its number: 0 the title tune, 1 the finish tune (TuneTable, 6 bytes a tune: the
; sequence lists of channel A, channel B and the drums). It owns the machine while it plays: its own IM 2 table (every
; byte $FD, the vector $FDFD = JP TuneInterrupt), a loop that toggles the speaker for two square-wave channels from
; the alternate registers, and the drums from the interrupt every 12 frames. TuneInterrupt calls the hook at TuneHook:
; MenuTick on the title (the menu runs inside the tune), TuneKeyCheck (a key stops the tune) otherwise; TrailEnd
; blanks the hook so the finish tune always ends by itself. A channel's stream is notes (a byte under $80: NoteTable's
; period) and commands ($80 + n: 0 next sequence, 1 the note's attack off, 2 the decay, 3 the length, 4 the
; transposition). The effects are the game's own: Tone and Click (the engine from the interrupt, Landing's thump, the
; bonus count), Noise (random from the ROM).
; --------------------------------------------------------------------------------------------------------------------

  ORG $F850

; LD A,0: the start of an entry point for tune 0 that no one calls (Title and
; TrailEnd call TunePlay)
;
; Known only from the code.
TunePlay0:
  LD A,$00

; Play tune A: the channels' sequences, the own IM 2 table and vector, the loop
; until the tune or a key ends it
;
; TuneNumber ($FB57) = A; DI; the three sequence pointers from TuneTable; the
; attack/decay bytes reset; $FE00-$FF00 = $FD, I = $FE, IM 2, $FDFD = JP
; TuneInterrupt; the first sequence of each channel; then TuneLoop. Title (c1:
; 4) and TrailEnd (trail1, trails: 9) call it.
;
; Witness: L1 17 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
TunePlay:
  LD (TuneEntry+$0001),A
  XOR A
  LD (TransposeB+$0001),A
  DI
  EXX
  LD (TuneStop+$000B),HL
  EXX
  LD (TuneStop+$0008),SP
  CALL TuneEntry
  LD SP,HL
  POP HL
  LD (NextSequenceA+$0001),HL
  POP HL
  LD (NextSequenceB+$0001),HL
  POP HL
  LD (NextSequenceD+$0001),HL
  LD SP,$0000
DrumBorder:
  LD A,$00                ; LD A,0: the border bits the drums send (the operand
                          ; read by DrumNoise and DrumHit)
  LD (ChannelAOff+$0001),A
  LD (ChannelBOff+$0001),A
  LD (l_FA52+$0004),A
  LD (l_FA6E+$0004),A
  LD (ChannelAOn+$0001),A
  LD (ChannelBOn+$0001),A
  LD HL,Im2Table
  LD BC,$00FD
l_F890:
  LD (HL),C
  INC HL
  DJNZ l_F890
  LD (HL),C
  LD A,$FE
  LD I,A
  IM 2
  LD A,$C3
  LD (TuneVector),A
  LD HL,TuneInterrupt
  LD (TuneVector+$0001),HL
  CALL NextSequenceA
  CALL NextSequenceB
  CALL NextSequenceD
  CALL TuneLoop
  JP TuneStop

; The two channels: count down each channel's period, toggle the speaker, read
; the next note or command at the end of its length
;
; Witness: L1 17 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
TuneLoop:
  LD C,$01
  EXX
  EI
  LD BC,$0101
  HALT
l_F8BD:
  CALL C,Envelope
  LD A,B
  AND A
  JR NZ,l_F8F3
; This entry point is used by the routine at CommandsB.
ChannelAPtr:
  LD HL,SequencesA0+$0059 ; LD HL,stream: channel A's stream pointer (the
                          ; operand patched)
; This entry point is used by the routines at CommandsB and SetTransposeA.
l_F8C7:
  LD A,(HL)
  OR A
  JP M,ChannelACommand
  CALL NoteLookup
  LD (l_F8F8+$0004),A
  LD D,A
  RRCA
  RRCA
  RRCA
  AND $1F
  LD (ChannelAOn+$0005),A
  XOR A
  LD (Envelope+$0001),A
  INC A
  LD (l_F8F8+$0006),A
  LD A,(ChannelAOn+$0001)
  OR $18
  LD (ChannelAOn+$0001),A
  INC HL
; This entry point is used by the routine at CommandsB.
l_F8EC:
  LD (ChannelAPtr+$0001),HL
  LD B,$0C
  JR l_F8F8
l_F8F3:
  LD A,$03
l_F8F5:
  DEC A
  JR NZ,l_F8F5
l_F8F8:
  DEC D
  JR NZ,l_F90F
  LD D,$A8
  LD A,$02
l_F8FF:
  DEC A
  JR NZ,l_F8FF
ChannelAOn:
  LD A,$18                ; LD A,$18: the speaker byte that starts channel A's
                          ; half-wave (its operand the attack's OR, patched by
                          ; Envelope)
  OUT ($FE),A
  LD A,$14
l_F908:
  DEC A
  JR NZ,l_F908
ChannelAOff:
  LD A,$00                ; LD A,0: the byte that ends it (the decay's)
  OUT ($FE),A
l_F90F:
  LD A,C
  AND A
  JR NZ,l_F941
; This entry point is used by the routine at CommandsB.
ChannelBPtr:
  LD HL,SequencesA0+$0198 ; LD HL,stream: channel B's stream pointer
; This entry point is used by the routines at CommandsB and SetTransposeB.
l_F916:
  LD A,(HL)
  OR A
  JP M,ChannelBCommand
  CALL NoteLookup
  LD (l_F946+$0005),A
  LD E,A
  RRCA
  RRCA
  AND $3F
  LD (ChannelBOn+$0005),A
  XOR A
  LD (EnvelopeStep+$0001),A
  INC A
  LD (l_F946+$0007),A
  LD A,(ChannelBOn+$0001)
  OR $18
  LD (ChannelBOn+$0001),A
  INC HL
; This entry point is used by the routine at CommandsB.
l_F93A:
  LD (ChannelBPtr+$0001),HL
  LD C,$54
  JR l_F946
l_F941:
  LD A,$03
l_F943:
  DEC A
  JR NZ,l_F943
l_F946:
  DEC E
  JP NZ,l_F8BD
  LD E,$2A
  LD A,$02
l_F94E:
  DEC A
  JR NZ,l_F94E
ChannelBOn:
  LD A,$18                ; LD A,$18: channel B's start byte
  OUT ($FE),A
  LD A,$09
l_F957:
  DEC A
  JR NZ,l_F957
ChannelBOff:
  LD A,$00                ; LD A,0: channel B's end byte
  OUT ($FE),A
  JP l_F8BD

; The tune's IM 2 handler: count the channels' note timers, the drums every 12
; frames, the hook
;
; Witness: L1 7111 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1,
; trails, turn, wallcrash, warp).
TuneInterrupt:
  PUSH AF
  PUSH HL
  PUSH DE
  DEC C
  DEC B
  EXX
  DEC C
  CALL Z,Drums
  PUSH BC
TuneHook:
  CALL TuneKeyCheck       ; CALL MenuTick or TuneKeyCheck (patched by MenuLoop
                          ; and TrailEnd; three zeros for none)
  POP BC
  EXX
  POP DE
  POP HL
  POP AF
  SCF
  EI
  RET

; Any key: stop the tune
;
; Witness: L1 5420 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1,
; trails, turn, wallcrash, warp).
TuneKeyCheck:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  RET Z
; This entry point is used by the routines at MenuTick and TunePlay.
TuneStop:
  DI                      ; DI, the ROM's vector (JP $0038) in TuneVector, SP
                          ; and HL' as TunePlay saved them (the operands at
                          ; $F986 and $F989), HL' = $2758, return to the caller
  LD HL,$0038
  LD (TuneVector+$0001),HL
  LD SP,$F838             ; TunePlay's saved SP: patched, not BufferP2+$011C
  LD HL,$2758
  EXX
  NOP
  RET

; Channel B's command byte: dispatch by CommandJump
;
; Witness: L1 846 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
ChannelBCommand:
  INC HL
  PUSH HL
  AND $7F
  CALL CommandJump
  JP l_FA09
  JP l_F9D1
  JP CommandsB
  JP l_F9F9
  JP SetTransposeB
  POP HL
  RET

; one byte between the tables
CommandPad:
  DEFB $00

; Channel A's command byte
;
; Witness: L1 730 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
ChannelACommand:
  INC HL
  PUSH HL
  AND $7F
  CALL CommandJump
  JP l_FA10
  JP l_F9DD
  JP l_F9C8
  JP l_F9E9

; Channel A's command 4: JP SetTransposeA, the shared transposition (no tune
; uses it)
;
; Known only from the code.
UnusedCommandA4:
  JP SetTransposeA

; POP HL; RET: channel A's end of the tune ($85); no recording reaches it:
; channel B's twin at $F9A4 ends the tunes in them (trails 1, warp 7, kb 1)
;
; Known only from the code.
CommandEnd:
  POP HL
  RET

; Channel B's commands: decay, attack, length, next
;
; Witness: L1 37 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
CommandsB:
  POP HL
  LD A,(HL)
  LD (EnvelopeStep+$0007),A
  INC HL
  JP l_F916
; This entry point is used by the routine at ChannelACommand.
l_F9C8:
  POP HL
  LD A,(HL)
  LD (Envelope+$0008),A
  INC HL
  JP l_F8C7
; This entry point is used by the routine at ChannelBCommand.
l_F9D1:
  POP HL
  LD A,(ChannelBOn+$0001)
  AND $07
  LD (ChannelBOn+$0001),A
  JP l_F93A
; This entry point is used by the routine at ChannelACommand.
l_F9DD:
  POP HL
  LD A,(ChannelAOn+$0001)
  AND $07
  LD (ChannelAOn+$0001),A
  JP l_F8EC
; This entry point is used by the routine at ChannelACommand.
l_F9E9:
  POP HL
  PUSH BC
  LD B,$03
  XOR A
l_F9EE:
  ADD A,(HL)
  DJNZ l_F9EE
  LD (l_F8EC+$0004),A
  INC HL
  POP BC
  JP l_F8C7
; This entry point is used by the routine at ChannelBCommand.
l_F9F9:
  POP HL
  PUSH BC
  LD B,$03
  XOR A
l_F9FE:
  ADD A,(HL)
  DJNZ l_F9FE
  LD (l_F93A+$0004),A
  INC HL
  POP BC
  JP l_F916
; This entry point is used by the routine at ChannelBCommand.
l_FA09:
  POP HL
  CALL NextSequenceB
  JP ChannelBPtr
; This entry point is used by the routine at ChannelACommand.
l_FA10:
  POP HL
  CALL NextSequenceA
  JP ChannelAPtr

; The shared transposition (the one byte both channels add) from channel A's
; stream (no tune uses it)
;
; Known only from the code.
SetTransposeA:
  POP HL
  LD A,(HL)
  INC HL
  LD (TransposeB+$0001),A
  JP l_F8C7

; Channel B's transposition (TransposeB at $FB69)
;
; Witness: L1 2 (menu).
SetTransposeB:
  POP HL
  LD A,(HL)
  INC HL
  LD (TransposeB+$0001),A
  JP l_F916

; The drums' stream, a byte every 12 interrupts or as DrumSpeed sets (from
; TuneInterrupt): the byte AND $7F picks 0 next sequence, 1 rest, 2
; DrumUnused2, 3 DrumSpeed, 4 DrumUnused, 5 nothing, 6 DrumNoise, 7 DrumHit
;
; Witness: L1 1157 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
Drums:
  LD C,$0C
; This entry point is used by the routine at DrumNext.
DrumPtr:
  LD HL,SequencesA0+$01AB ; LD HL,stream: the drums' stream pointer (the
                          ; operand patched)
  LD A,(HL)
  INC HL
  LD (DrumPtr+$0001),HL
  AND $7F
  CALL CommandJump
  JP DrumNext
  RET

; two zero bytes after command 1's RET
DrumPad:
  DEFB $00,$00

; Drum command 2: JP DrumUnused2 (no tune uses it)
;
; Known only from the code.
DrumJump2:
  JP DrumUnused2

; Drum command 3: JP DrumSpeed
;
; Witness: L1 480 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
DrumJump3:
  JP DrumSpeed

; Drum command 4: JP DrumUnused (no tune uses it)
;
; Known only from the code.
DrumJump4:
  JP DrumUnused

; Drum command 5: RET (no tune uses it)
;
; Known only from the code.
DrumJump5:
  RET

; two zero bytes after command 5's RET
DrumPad2:
  DEFB $00,$00

; Drum commands 6 and 7: JP DrumNoise, JP DrumHit
;
; Witness: L1 470 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
DrumJump6:
  JP DrumNoise
  JP DrumHit

; A drum sound no tune uses: 128 bytes of the ROM sent to the speaker
;
; Known only from the code.
DrumUnused:
  LD B,$80
l_FA52:
  LD A,(HL)
  AND $18
  OR $00
  OUT ($FE),A
  DEC L
  DJNZ l_FA52
  RET

; A noise: the ROM's bytes from $005C sent to the speaker until a zero
;
; Witness: L1 470 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
DrumNoise:
  LD HL,$005C
l_FA60:
  LD A,(HL)
  OR A
  RET Z
  AND $18
  OR $00
  OUT ($FE),A
  INC HL
  JR l_FA60

; A second unused drum sound
;
; Known only from the code.
DrumUnused2:
  LD B,$20
l_FA6E:
  LD A,(HL)
  AND $18
  OR $00
  OUT ($FE),A
l_FA75:
  DEC A
  JR NZ,l_FA75
  DEC L
  DJNZ l_FA6E
  RET

; The drums' next sequence
;
; Witness: L1 64 (c1, kb, menu, trail1, trails, wallcrash, warp).
DrumNext:
  CALL NextSequenceD
  JR DrumPtr

; A drum: 30 clicks of a falling pitch
;
; Witness: L1 197 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
DrumHit:
  LD HL,(DrumPtr+$0001)
  LD A,(HL)
  INC HL
  LD (DrumPtr+$0001),HL
  LD B,$1E
  LD L,A
  RRCA
  LD H,A
l_FA8E:
  LD A,(DrumBorder+$0001)
  OUT ($FE),A
  DEC L
  LD A,L
l_FA95:
  DEC A
  JR NZ,l_FA95
  LD A,(DrumBorder+$0001)
  OR $18
  OUT ($FE),A
  LD A,$04
  ADD A,H
  LD H,A
l_FAA3:
  DEC A
  JR NZ,l_FAA3
  DJNZ l_FA8E
  RET

; The drums' speed (3 x the byte)
;
; Witness: L1 480 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
DrumSpeed:
  LD HL,(DrumPtr+$0001)
  LD B,$03
  XOR A
l_FAAF:
  ADD A,(HL)
  DJNZ l_FAAF
  LD (Drums+$0001),A
  INC HL
  LD (DrumPtr+$0001),HL
  JP Drums

; Jump to the (A AND $7F)th JP after the caller
;
; Witness: L1 2797 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
CommandJump:
  LD L,A
  ADD A,A
  ADD A,L
  POP HL
  ADD A,L
  LD L,A
  JR NC,l_FAC5
  INC H
l_FAC5:
  JP (HL)

; The channels' note shapes: the attack and decay counters
;
; Witness: L1 3257 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
Envelope:
  LD A,$02
  INC A
  LD (Envelope+$0001),A
  PUSH HL
  CP $03
  JR C,EnvelopeStep
  XOR A
  LD (Envelope+$0001),A
  LD HL,ChannelAOn+$0005
  DEC (HL)
  JR Z,l_FADE
  LD HL,l_F8F8+$0006
l_FADE:
  INC (HL)
EnvelopeStep:
  LD A,$01                ; LD A,n: the envelope's step counter, 1 to 3 (the
                          ; operand patched)
  INC A
  LD (EnvelopeStep+$0001),A
  CP $04
  JR C,l_FAF7
  XOR A
  LD (EnvelopeStep+$0001),A
  LD HL,ChannelBOn+$0005
  DEC (HL)
  JR Z,l_FAF6
  LD HL,l_F946+$0007
l_FAF6:
  INC (HL)
l_FAF7:
  POP HL
  RET

; Channel A's next sequence (the list's end: the first again)
;
; Witness: L1 72 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
NextSequenceA:
  LD HL,SequencesA0+$0022
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (NextSequenceA+$0001),HL
  LD (ChannelAPtr+$0001),DE
  LD A,D
  OR E
  RET NZ
  CALL TuneEntry
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (NextSequenceA+$0001),DE
  JR NextSequenceA

; Channel B's next sequence
;
; Witness: L1 56 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
NextSequenceB:
  LD HL,SequencesA0+$004A
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (NextSequenceB+$0001),HL
  LD (ChannelBPtr+$0001),DE
  LD A,D
  OR E
  RET NZ
  CALL TuneEntry
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (NextSequenceB+$0001),DE
  JR NextSequenceB

; The drums' next sequence
;
; Witness: L1 135 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
NextSequenceD:
  LD HL,SequencesA0+$0052
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (NextSequenceD+$0001),HL
  LD (DrumPtr+$0001),DE
  LD A,D
  OR E
  RET NZ
  CALL TuneEntry
  INC HL
  INC HL
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (NextSequenceD+$0001),DE
  JR NextSequenceD

; HL = TuneTable + 6 x TuneNumber
;
; Witness: L1 73 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
TuneEntry:
  LD A,$00                ; LD A,n: the tune (the operand patched by TunePlay)
  ADD A,A
  LD L,A
  ADD A,L
  ADD A,L
  LD HL,TuneTable
  ADD A,L
  LD L,A
  RET NC
  INC H
  RET

; A = NoteTable's period for the note A + TransposeB
;
; Witness: L1 2000 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).
NoteLookup:
  PUSH HL
  LD HL,NoteTable
TransposeB:
  ADD A,$02               ; ADD A,n: channel B's transposition (the operand
                          ; patched)
  ADD A,L
  LD L,A
  JR NC,l_FB6F
  INC H
l_FB6F:
  LD A,(HL)
  POP HL
  RET

; The 60 notes' half-periods, highest first
NoteTable:
  INCBIN "res/sound/tunes.bin",$0000,60

; Tune 0 (the title) and tune 1 (the finish): channel A's, channel B's and the
; drums' sequence lists
TuneTable:
  INCBIN "res/sound/tunes.bin",$003C,12
  ASSERT {TuneTable} == SequencesA0

; The tunes' sequence lists (pattern addresses, 0 then the restart) and the
; patterns
SequencesA0:
  INCBIN "res/sound/tunes.bin",$0048,579
  ASSERT {SequencesA0+148} == ShiftCount
  ASSERT {SequencesA0+150} == ShiftCount
  ASSERT {SequencesA0+204} == Controls2
  ASSERT {SequencesA0+206} == Controls2
  ASSERT {SequencesA0+208} == Controls2
  ASSERT {SequencesA0+210} == Controls2
  ASSERT {SequencesA0+216} == Controls2
  ASSERT {SequencesA0+218} == Controls2
  ASSERT {SequencesA0+220} == Controls2
  ASSERT {SequencesA0+222} == Controls2
  ASSERT {SequencesA0+224} == Controls2
  ASSERT {SequencesA0+226} == Controls2
  ASSERT {SequencesA0+232} == Controls2
  ASSERT {SequencesA0+234} == Controls2
  ASSERT {SequencesA0+480} == KeyIndexes2
  ASSERT {SequencesA0+516} == ClipWidth
  ASSERT {SequencesA0+518} == ClipWidth
  ASSERT {SequencesA0+520} == ClipWidth
  ASSERT {SequencesA0+522} == ClipWidth
  ASSERT {SequencesA0+528} == ClipWidth
  ASSERT {SequencesA0+530} == ClipWidth
  ASSERT {SequencesA0+532} == ClipWidth
  ASSERT {SequencesA0+534} == ClipWidth
  ASSERT {SequencesA0+536} == ClipWidth
  ASSERT {SequencesA0+538} == ClipWidth
  ASSERT {SequencesA0+544} == ClipWidth
  ASSERT {SequencesA0+546} == ClipWidth

; JP TuneInterrupt, written by TunePlay (zeros in the image)
TuneVector:
  DEFB $00,$00,$00

; The IM 2 table: $80 each (SetupIm2) or $FD (TunePlay), 257 bytes; zeros in
; the image
Im2Table:
  DEFS $0118

; 96 bytes no code reads: system variables and stack bytes, and four glyphs of
; the ROM's font (A, B, C, D), from the developer's memory
TopLeftover:
  DEFB $F3,$0D,$CE,$0B,$E2,$50,$CE,$0B,$E3,$50,$1E,$17,$DC,$0A,$CE,$0B
  DEFB $E4,$50,$1D,$17,$03,$1A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$DB,$02
  DEFB $DB,$02,$4D,$00,$E4,$53,$1C,$00,$E3,$53,$0C,$02,$5C,$0E,$C0,$57
  DEFB $71,$0E,$F3,$0D,$21,$17,$C6,$1E,$70,$62,$76,$1B,$03,$13,$00,$3E
  DEFB $00,$3C,$42,$42,$7E,$42,$42,$00,$00,$7C,$42,$7C,$42,$42,$7C,$00
  DEFB $00,$3C,$42,$40,$40,$42,$3C,$00,$00,$78,$44,$42,$42,$44,$78,$00
