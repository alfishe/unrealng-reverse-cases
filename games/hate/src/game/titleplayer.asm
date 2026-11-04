; Title music player: relocating entry
;
; Entry of the title music player (Ben Daglish's beeper engine);
; docs/02-architecture.md 2.3, docs/09-sound.md. C = the tune number (the
; operand $8002, set to 0 by the start-up). It reads its own call address from
; the CALL operand below the return address, swaps $58C bytes from that address
; + $3A with $803A, calls the set-up $803A and swaps them back, so the player
; can be linked anywhere. Called as CALL $8000 the swap changes nothing. The
; same 64 pages are the playfield buffer $8000-$BFFF in play
; (docs/06-rendering.md 6.2).
TitlePlayer:
  DI
  LD C,$00                ; the tune number: an operand written by the start-up
                          ; ($9F16)
  EXX
  POP HL                  ; the return address: points after our CALL
  PUSH HL
  DEC HL                  ; DE = the CALL's operand, the address this copy was
                          ; called at
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD HL,$003A             ; the player's body follows $3A bytes after the entry
  ADD HL,DE
  PUSH HL
  LD BC,$058C             ; length of the body
  LD DE,TitleSetup
SwapInLoop:
  LD A,(DE)               ; exchange (DE) and (HL), byte by byte
  EX AF,AF'
  LD A,(HL)
  LD (DE),A
  EX AF,AF'
  LD (HL),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,SwapInLoop
  CALL TitleSetup         ; play; returns here on the tune's end or a key

; Title music player: swap the body back
;
; Undoes the swap of $8000 and returns to the start-up.
TitlePlayerSwapBack:
  POP HL
  LD DE,TitleSetup
  LD BC,$058C
SwapBackLoop:
  LD A,(DE)               ; exchange the bytes again
  EX AF,AF'
  LD A,(HL)
  LD (DE),A
  EX AF,AF'
  LD (HL),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,SwapBackLoop
  RET

; Title player set-up: hook IM 2, reset the voices, start the tune
;
; Saves SP into the operand at $8364 (for the exits at $8356), points SP at its
; own small stack below $83F7, reads the IM 2 vector address from I (the vector
; table byte at I*256, doubled: $FDFD) and saves the 3 bytes there to $83F9,
; then writes JP $8340 in their place. Applies the 9 (address, byte) patches of
; $8422 to reset its own operands, enables interrupts, and starts tune C from
; the table $843D; docs/02-architecture.md 2.3.
TitleSetup:
  LD (TitleExit+$000E),SP ; saved for the exits: the operand of LD SP,nn at
                          ; $8363
  LD SP,TitleVectorAddr   ; the player's own stack, $83E2-$83F6
  LD A,I                  ; I = the high byte of the vector table
  LD H,A
  LD L,$00
  LD D,(HL)               ; D = E = the table byte: the vector address is $FDFD
  LD E,D
  EX DE,HL
  LD (TitleVectorAddr),HL ; the vector address, used again by the exit $8356
  LD DE,TitleVectorSave
  LD BC,$0003
  LDIR                    ; keep the 3 bytes found at the vector
  LD DE,TitleInterrupt    ; JP $8340, written backwards over the vector
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  DEC HL
  LD (HL),$C3
  LD B,$09                ; nine patches
  LD HL,TitlePatches
PatchLoop:
  LD E,(HL)               ; (DE) = the patch byte
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  LD (DE),A
  DJNZ PatchLoop
  EI
  HALT                    ; wait for the first interrupt: start on a frame
  EXX
  LD HL,TuneTable         ; HL = the song of tune C
  LD B,$00
  SLA C
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD C,B
  JP SongStep             ; C = 0: no note sounding yet

; Title player: is the current note over?
;
; Entered from the voice loop after each period of voice B. C counts the note's
; frames down (the IM 2 handler decrements it); while it is not 0 the voices go
; on, at 0 the next pattern command is read.
NoteTimeCheck:
  LD A,C                  ; C: frames left of the note
  AND A
  JP NZ,DrumTick

; Title player: next note, reload the note length
;
; Reloads C with the note length (the operand $8085, set by command 17), then
; reads the next command of the pattern.
PatternStep:
  LD C,$05                ; the note length, an operand written by command 17
                          ; ($80F8)
  EXX
  EX DE,HL                ; HL = the pattern position, kept in DE' between
                          ; notes

; Title player: dispatch one pattern command
;
; Reads the command byte at HL and jumps through the handler table $83FC (2
; bytes a command) with the position after the byte on the stack;
; docs/09-sound.md 9.3.
PatternCommand:
  LD E,(HL)
  SLA E
  LD D,$00
  INC HL
  PUSH HL                 ; the handler pops the position
  LD HL,TitleCommands     ; the command table
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP (HL)                 ; to the command's handler

; Title command 1: voice A's starting pulse width
;
; Writes the argument byte into the operands at $81DE and $8205, the LD B,n of
; voice A's note set-up in commands 10 and 11: the pulse width a note starts
; with, its loudness.
CmdWidthA:
  POP HL
  LD A,(HL)
  INC HL
  LD (NoteABPeriods+$0037),A ; voice A, command 10's set-up
  LD (CmdNoteAPeriod+$0011),A ; voice A, command 11's set-up
  JP PatternCommand

; Title command 2: voice B's starting pulse width
;
; Writes the argument byte into the operands at $81BB and $8231, the LD B,n of
; voice B's note set-up in commands 10 and 12.
CmdWidthB:
  POP HL
  LD A,(HL)
  INC HL
  LD (NoteABPeriods+$0014),A ; voice B, command 10's set-up
  LD (NoteBPeriod+$0011),A ; voice B, command 12's set-up
  JP PatternCommand

; Title command 3: envelope step time of voice A
;
; Writes the argument into the operand at $827E, the reload of H (voice A's
; envelope frame counter) when a note starts.
CmdEnvelopeA:
  POP HL
  LD A,(HL)
  INC HL
  LD (VoiceAEnvelope+$0005),A ; read by $81E7 and $8213 into H
  JP PatternCommand

; Title command 4: envelope step time of voice B
;
; Writes the argument into the operand at $82E0, the reload of L (voice B's
; envelope frame counter) when a note starts.
CmdEnvelopeB:
  POP HL
  LD A,(HL)
  INC HL
  LD (VoiceBEnvelope+$0005),A ; read by $81CC and $823F into L
  JP PatternCommand

; Title commands 5 and 6: envelope mode of voice A (not run)
;
; Two handlers that did not run in the recording: POP HL; LD B,1; JP $8088
; (command 5, mode 1: hold) and POP HL; LD B,0; JP $8088 (command 6, mode 0:
; decay). B of the pattern's register set is voice A's envelope mode;
; docs/09-sound.md 9.4.
CmdModeA:
  DEFB $E1,$06,$01,$C3,$88,$80,$E1,$06
  DEFB $00,$C3,$88,$80

; Title command 7: voice B envelope mode 1 (hold)
;
; C of the pattern's register set is voice B's envelope mode.
CmdModeBHold:
  POP HL
  LD C,$01
  JP PatternCommand

; Title command 8: voice B envelope mode 0 (decay)
;
; Sets voice B's envelope mode C = 0 and goes back to the pattern reader
; (PatternCommand); docs/09-sound.md 9.3.
CmdModeBDecay:
  POP HL
  LD C,$00
  JP PatternCommand

; Title commands 13-15: silence the voices (not run)
;
; Three handlers that did not run in the recording. Each zeroes an OUT value
; operand: command 13 at $80DA both ($82D0 and $8332), command 14 at $80E5
; voice A ($82D0), command 15 at $80ED voice B ($8332); then JP $8088.
CmdSilence:
  DEFB $E1,$AF,$32,$D0,$82,$32,$32,$83
  DEFB $C3,$88,$80,$E1,$AF,$32,$D0,$82
  DEFB $C3,$88,$80,$E1,$AF,$32,$32,$83
  DEFB $C3,$88,$80

; Title command 17: set the note length
;
; The argument goes into the operand of LD C,n at $8085 and into C' at once.
CmdNoteLength:
  POP HL
  LD A,(HL)
  INC HL
  LD (PatternStep+$0001),A ; the reload at $8084
  EXX
  LD C,A
  EXX
  JP PatternCommand

; Title command 16: change the drum pattern from a pattern
;
; Starts the drum pattern whose address follows the command byte ($815E), then
; reads the next command.
CmdDrums:
  POP HL
  DEC HL
  CALL DrumStart
  JP PatternCommand

; Title command 9: end of pattern
;
; Counts the repeats down (the operand $810E). While some remain, it restarts
; the pattern from its start (the operand $810B); otherwise it goes back to the
; song at the position saved in $8116; docs/09-sound.md 9.3.
CmdPatternEnd:
  POP HL
  LD DE,PatternA          ; the pattern's start, an operand written by $8152
  LD A,$05                ; repeats left, an operand written by $8110 and $8146
  DEC A
  LD (CmdPatternEnd+$0005),A
  JR NZ,PatternEnter      ; again: restart the pattern
  LD HL,TuneSong+$0009    ; the song position, an operand written by $814E

; Title player: interpret the song
;
; Reads one song byte at HL: $FF return from a sub-song, $FE call a sub-song,
; $FD jump, $FC end of the tune, $FB start a drum pattern, n < $FB play the
; pattern at the following address n times; docs/09-sound.md 9.2.
SongStep:
  LD A,(HL)
  INC A
  JR NZ,SongCallCheck     ; not $FF

; Title song byte $FF: return (not run)
;
; LD HL,nn; JP $8118: back to the position saved by $FE (the operand $811D).
; The tune of this game uses no sub-song.
SongReturn:
  DEFB $21,$00,$00,$C3,$18,$81

; Title player: song byte $FE?
;
; Song bytes from $FE down: $FE calls a sub-song (SongCall, not run), anything
; else is a jump in the song (SongJump).
SongCallCheck:
  INC A
  JR NZ,SongJump          ; not $FE

; Title song byte $FE: call a sub-song (not run)
;
; INC HL; LD E,(HL); INC HL; LD D,(HL); INC HL; LD ($811D),HL; EX DE,HL; JP
; $8118: saves the position after the address into SongReturn's operand and
; continues at the address.
SongCall:
  DEFB $23,$5E,$23,$56,$23,$22,$1D,$81
  DEFB $EB,$C3,$18,$81

; Title player: song bytes $FD, $FC, $FB and patterns
;
; $FD jumps to the address that follows (tune 0 loops this way); $FC leaves
; through $8356, the same exit as a key; $FB starts a drum pattern; any other
; byte n plays the pattern at the following address n times: n goes into $810E,
; the pattern's start into $810B and the song position after it into $8116.
SongJump:
  INC A
  JR NZ,SongEndOrDrums
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP SongStep
SongEndOrDrums:
  INC A                   ; $FC, $FB or a pattern
  JP Z,TitleExit          ; $FC: the end of the tune
  INC A
  JP Z,SongDrums          ; $FB: drums
  SUB $05                 ; n - 1 more repeats after this one
  LD (CmdPatternEnd+$0005),A ; repeats, the operand of LD A,n at $810D
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (CmdPatternEnd+$000D),HL ; the song position, the operand at $8115
  EX DE,HL
  LD (CmdPatternEnd+$0002),HL ; the pattern's start, the operand at $810A
  EX DE,HL

; Title player: enter a pattern
;
; Back to the pattern register set, where DE holds the pattern position, then
; $8084.
PatternEnter:
  EXX
  JP PatternStep

; Title song byte $FB: start a drum pattern
;
; Calls DrumStart with the return set to $8118, the next song byte.
SongDrums:
  LD DE,SongStep
  PUSH DE

; Title player: start the drum pattern at the address after HL
;
; Clears the drum timer (operand $8244), stores the pattern's first byte, its
; speed in frames, into the operand $824B, and its step address into $8250 (the
; position) and $8258 (the loop point); docs/09-sound.md 9.5.
DrumStart:
  XOR A
  LD (DrumTick+$0001),A   ; drum timer = 0: the first step at once
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(DE)
  LD (DrumTick+$0008),A   ; the speed: frames a step
  INC DE
  LD (DrumByte+$0006),DE  ; the loop point, used by drum byte 1
  LD (DrumTick+$000D),DE  ; the position
  RET

; Title command 0: hold the notes one more note length
;
; Command 0: nothing changes this note length; the player goes on to the drum
; tick (DrumTick) with the notes as they are.
CmdHold:
  POP DE
  EXX
  JP DrumTick

; Title command 18: hold the notes n note lengths
;
; The counter is its own operand at $817B: 0 means the command starts, it loads
; n from the argument; otherwise it counts down, staying on this command until
; 0, then steps over the argument.
CmdLongNote:
  LD A,$00                ; the counter, an operand: 0 = not counting
  AND A
  JP Z,LongNoteStart
  LD HL,CmdLongNote+$0001
  DEC (HL)                ; one note length done
  POP DE
  DEC DE
  EXX
  JP NZ,DrumTick          ; more to go: keep the notes
  EXX
  INC DE
  INC DE
  EX DE,HL
  JP PatternCommand
LongNoteStart:
  POP DE                  ; the argument n: the counter
  LD A,(DE)
  LD (CmdLongNote+$0001),A ; start counting
  DEC DE
  EXX
  JP DrumTick

; Title command 10: a note on both voices
;
; Two period bytes: voice A's goes into D of the voice loop and the reload
; operand $82CA, voice B's into E and $832C. Each voice's pulse width ($82D4,
; $8336) starts at the width of command 1 or 2, its pre-delay ($82CC, $832E) is
; period / 8 + $18 less that width, and its OUT value ($82D0, $8332) is $18
; (beeper on); H and L get the envelope times of commands 3 and 4. When an
; envelope mode is not 0, the note starts mode 3; docs/09-sound.md 9.3-9.4.
CmdNoteAB:
  LD A,B
  AND A
  JR Z,CmdNoteABVoiceB    ; voice A in mode 0: leave it

; Title command 10: voice A mode 3 (not run)
;
; LD B,3: voice A starts in mode 3 when its mode is not 0. Voice A was in mode
; 0 through the recording.
NoteABModeA:
  DEFB $06,$03

; Title command 10: voice B mode and the periods
;
; Command 10: voice B starts in envelope mode 3 when C is not 0; then both
; periods from the pattern (NoteABPeriods), voice B's written into its period
; reload VoiceBStep+$0005.
CmdNoteABVoiceB:
  LD A,C
  AND A
  JR Z,NoteABPeriods
  LD C,$03                ; voice B starts in mode 3
NoteABPeriods:
  POP DE                  ; the two periods
  LD A,(DE)
  INC DE
  EX AF,AF'
  LD A,(DE)
  INC DE
  EXX
  LD E,A
  LD (VoiceBStep+$0005),A ; voice B's period reload
  SRL A
  SRL A
  SRL A
  ADD A,$18
  LD B,$17                ; voice B's starting width, an operand written by
                          ; command 2
  SUB B
  LD (VoiceBStep+$0007),A ; voice B's pre-delay: period / 8 + $18 - width
  LD A,B
  LD (VoiceBPreDelay+$0007),A ; voice B's pulse width
  LD A,$18
  LD (VoiceBPreDelay+$0003),A ; voice B on
  LD (VoiceAPreDelay+$0003),A ; voice A on
  LD A,($82E0)            ; L = voice B's envelope time
  LD L,A
  EX AF,AF'
  LD D,A
  LD (VoiceAStep+$0005),A ; voice A's period reload
  SRL A
  SRL A
  SRL A
  ADD A,$18
  LD B,$17                ; voice A's starting width, an operand written by
                          ; command 1
  SUB B
  LD (VoiceAStep+$0007),A ; voice A's pre-delay
  LD A,B
  LD (VoiceAPreDelay+$0007),A ; voice A's pulse width
  LD A,($827E)            ; H = voice A's envelope time
  LD H,A
  JP DrumTick

; Title command 11: a note on voice A only
;
; One period byte for voice A, set up as in command 10.
CmdNoteA:
  LD A,B
  AND A
  JR Z,CmdNoteAPeriod     ; mode 0: leave it

; Title command 11: voice A mode 3 (not run)
;
; LD B,3, as in command 10.
NoteAModeA:
  DEFB $06,$03

; Title command 11: voice A's period
;
; Command 11: voice A's period from the pattern into its reload
; VoiceAStep+$0005, and its pre-delay VoiceAStep+$0007 = period / 8 + $18 - the
; starting width (an operand command 1 writes); docs/09-sound.md 9.3.
CmdNoteAPeriod:
  POP DE
  LD A,(DE)
  INC DE
  EXX
  LD D,A
  LD (VoiceAStep+$0005),A ; voice A's period reload
  SRL A
  SRL A
  SRL A
  ADD A,$18
  LD B,$17                ; voice A's starting width, an operand written by
                          ; command 1
  SUB B
  LD (VoiceAStep+$0007),A ; voice A's pre-delay
  LD A,B
  LD (VoiceAPreDelay+$0007),A ; voice A's pulse width
  LD A,$18
  LD (VoiceAPreDelay+$0003),A ; voice A on
  LD A,($827E)
  LD H,A
  JP DrumTick

; Title command 12: a note on voice B only
;
; One period byte for voice B, set up as in command 10.
CmdNoteB:
  LD A,C
  AND A
  JR Z,NoteBPeriod
  LD C,$03                ; voice B starts in mode 3
NoteBPeriod:
  POP DE                  ; the period
  LD A,(DE)
  INC DE
  EXX
  LD E,A
  LD (VoiceBStep+$0005),A ; voice B's period reload
  SRL A
  SRL A
  SRL A
  ADD A,$18
  LD B,$17                ; voice B's starting width, an operand written by
                          ; command 2
  SUB B
  LD (VoiceBStep+$0007),A ; voice B's pre-delay
  LD A,B
  LD (VoiceBPreDelay+$0007),A ; voice B's pulse width
  LD A,$18
  LD (VoiceBPreDelay+$0003),A ; voice B on
  LD A,($82E0)
  LD L,A

; Title player: drum timer, then the voices
;
; The operand $8244 is the drum timer, decremented once a frame by the IM 2
; handler. At 0 it is reloaded from the speed (operand $824B) and the next drum
; byte is played: 0 rest, 1 loop to the pattern's start, 2-6 the sounds $8367,
; $837F, $839A, $83C6, $83B0; docs/09-sound.md 9.5.
DrumTick:
  LD A,$05                ; the drum timer, an operand the IM 2 handler
                          ; decrements
  AND A
  JP NZ,VoiceAEnvelope
  EXX
  LD A,$05                ; the speed, an operand written by $8168
  LD (DrumTick+$0001),A
  LD HL,DrumPatternA+$0002 ; the drum position, an operand written by $8170 and
                           ; $8261
DrumByte:
  LD A,(HL)               ; the next drum byte
  DEC A
  JP NZ,DrumSound         ; not 1: a sound or a rest
  LD HL,DrumPatternA+$0001 ; the loop point, an operand written by $816C
  LD (DrumTick+$000D),HL
  JP DrumByte
DrumSound:
  INC HL                  ; play byte 2-6; 0 falls through to the voices
  LD (DrumTick+$000D),HL
  EXX
  DEC A
  JP Z,DrumClick
  DEC A
  JP Z,DrumNoise
  DEC A
  JP Z,DrumRise
  DEC A
  JP Z,DrumSweep
  DEC A
  JP Z,DrumFall

; Title player: voice A's envelope tick
;
; H counts voice A's envelope frames (the IM 2 handler decrements it). At 0 it
; is reloaded with 3 and voice A's envelope mode B' is applied: 0 decays the
; note ($82A3), 1-3 are handled by the bytes $8284 (not run in the recording).
VoiceAEnvelope:
  LD A,H
  AND A
  JR NZ,VoicesPlay        ; not yet: play the voices
  LD H,$03                ; an operand written by command 3
  EXX
  LD A,B
  AND A
  JR Z,VoiceADecay        ; mode 0: decay

; Title player: voice A envelope modes 1-3 (not run)
;
; DEC A; JR Z,$82BD (mode 1: hold); DEC A; JR Z,$8296 (mode 2: B = 3, voice on,
; the period reloaded, then a decay step); mode 3: B = 2, voice off ($82D0 =
; 0), H = 1, JP $82C1. Modes 2 and 3 alternate: a stutter. Voice B's copy of
; this code ran ($82E2).
VoiceAModes:
  DEFB $3D,$28,$36,$3D,$28,$0C,$06,$02
  DEFB $AF,$32,$D0,$82,$D9,$26,$01,$C3
  DEFB $C1,$82,$06,$03,$3E,$18,$32,$D0
  DEFB $82,$3A,$CA,$82,$D9,$57,$D9

; Title player: voice A's decay step
;
; Narrows voice A's pulse ($82D4) and lengthens its pre-delay ($82CC) by one:
; the same pitch, quieter. When the width runs out the bytes at $82B1 silence
; the voice.
VoiceADecay:
  LD HL,VoiceAPreDelay+$0007 ; voice A's pulse width
  DEC (HL)
  JR Z,VoiceAOff
  LD HL,VoiceAStep+$0007  ; voice A's pre-delay
  INC (HL)
  EXX
  JP VoiceAStep

; Title player: voice A's pulse width ran out (not run)
;
; INC (HL) (the width back to 1); XOR A; LD ($82D0),A (voice A off); LD A,B;
; AND A; JP Z,$82BD; LD B,1 (a mode other than 0 becomes hold); $82BD: EXX; JP
; $82C5.
VoiceAOff:
  DEFB $34,$AF,$32,$D0,$82,$78,$A7,$CA
  DEFB $BD,$82,$06,$01,$D9,$C3,$C5,$82

; Title player: the two voices
;
; One period step of each voice. D counts voice A's period down; at 0 it is
; reloaded (the operand $82CA) and one pulse is sent: pre-delay ($82CC), beeper
; on ($82D0, $18), pulse width ($82D4), beeper off. Then voice B's envelope
; tick (L, mode C') and the same for voice B with E at $8327; docs/09-sound.md
; 9.4.
VoicesPlay:
  LD B,$04                ; balance the time of the envelope branch
BalanceDelayLoop:
  DJNZ BalanceDelayLoop
; This entry point is used by the routine at VoiceADecay.
VoiceAStep:
  DEC D                   ; voice A's period counter
  JP NZ,VoiceBEnvelope
  LD D,$A6                ; voice A's period, an operand written by the note
                          ; commands
  LD B,$15                ; voice A's pre-delay, an operand
VoiceAPreDelay:
  DJNZ VoiceAPreDelay
  LD A,$18                ; voice A's OUT value: $18 on, 0 silenced
  OUT ($FE),A             ; beeper on, border black
  LD B,$17                ; voice A's pulse width, an operand
VoiceAPulse:
  DJNZ VoiceAPulse
  LD A,$00
  OUT ($FE),A             ; beeper off
VoiceBEnvelope:
  LD A,L                  ; L: voice B's envelope frames
  AND A
  JR NZ,VoiceBDelay
  LD L,$03                ; an operand written by command 4
  EXX
  LD A,C                  ; C: voice B's envelope mode
  AND A
  JR Z,VoiceBDecay        ; mode 0: decay
  DEC A
  JR Z,$831F              ; mode 1: hold
  DEC A
  JR Z,VoiceBModeOn       ; mode 2
  LD C,$02                ; mode 3: the voice off for one tick, then mode 2
  XOR A
  LD (VoiceBPreDelay+$0003),A
  EXX
  LD L,$01
  JP VoiceBDelay
VoiceBModeOn:
  LD C,$03                ; mode 2: the voice on, the period restarted, then
                          ; mode 3
  LD A,$18
  LD (VoiceBPreDelay+$0003),A
  LD A,($832C)
  EXX
  LD E,A
  EXX
VoiceBDecay:
  LD HL,VoiceBPreDelay+$0007 ; voice B's pulse width
  DEC (HL)
  JR Z,VoiceBOff
  LD HL,VoiceBStep+$0007  ; voice B's pre-delay
  INC (HL)
  EXX
  JP VoiceBStep

; Title player: voice B's pulse width ran out (not run)
;
; INC (HL); XOR A; LD ($8332),A (voice B off); LD A,C; AND A; JP Z,$831F; LD
; C,1; $831F: EXX; JP $8327. The JR Z,$831F at $82E7 (mode 1) enters at its
; tail.
VoiceBOff:
  DEFB $34,$AF,$32,$32,$83,$79,$A7,$CA
  DEFB $1F,$83,$0E,$01,$D9,$C3,$27,$83

; Title player: balance the envelope branch
;
; A 4-step delay loop that makes the envelope branch take as long as the other
; one, so voice B's period step comes at the same time either way.
VoiceBDelay:
  LD B,$04

; Title player: delay loop
;
; The delay loop of VoiceBDelay (B = 4), then voice B's period step.
VoiceBDelayLoop:
  DJNZ VoiceBDelayLoop

; Title player: voice B's period step
;
; E counts voice B's period down; at 0 one pulse is sent like voice A's. Then
; back to $807F.
VoiceBStep:
  DEC E
  JP NZ,NoteTimeCheck
  LD E,$A4                ; voice B's period, an operand written by the note
                          ; commands
  LD B,$15                ; voice B's pre-delay, an operand
VoiceBPreDelay:
  DJNZ VoiceBPreDelay
  LD A,$18                ; voice B's OUT value: $18 on, 0 silenced
  OUT ($FE),A             ; beeper on
  LD B,$17                ; voice B's pulse width, an operand
VoiceBPulse:
  DJNZ VoiceBPulse
  LD A,$00
  OUT ($FE),A             ; beeper off
  JP NoteTimeCheck

; Title player: the IM 2 handler, once a frame
;
; Reached through JP $8340 at $FDFD. A key on any row ends the music ($8356).
; Otherwise it ticks the engine's clocks: the drum timer ($8244) and the
; registers of the interrupted voice loop, C (the note length), H and L (the
; envelopes); 123 T an entry. docs/02-architecture.md 2.3.
TitleInterrupt:
  DI
  EX AF,AF'
  XOR A
  IN A,($FE)              ; A = 0: all keyboard rows
  CPL
  AND $1F
  JR NZ,TitleExit         ; a key: leave the music
  PUSH HL
  LD HL,DrumTick+$0001    ; the drum timer
  DEC (HL)
  POP HL
  DEC C                   ; the note length
  DEC H                   ; voice A's envelope
  DEC L                   ; voice B's envelope
  EX AF,AF'
  EI
  RET
; This entry point is used by the routine at SongJump.
TitleExit:
  DI                      ; the tune ends ($FC) or a key: unhook and unwind
  LD DE,(TitleVectorAddr) ; the vector address saved at $8049
  LD HL,TitleVectorSave   ; put back the 3 bytes the set-up replaced
  LD BC,$0003
  LDIR
  LD SP,$FFF9             ; SP as $803A saved it: the operand $8364
  RET                     ; back into $8025, at any depth of the player

; Title drum 2: a click
;
; The beeper held on for 300 loop steps, then a pause; docs/09-sound.md 9.5.
DrumClick:
  PUSH DE
  LD A,$18
  OUT ($FE),A             ; beeper on
  LD DE,$012C
ClickHoldLoop:
  DEC DE
  LD A,D
  OR E
  JP NZ,ClickHoldLoop
  OUT ($FE),A             ; A = 0 here: beeper off
  LD B,$64
ClickPauseLoop:
  DJNZ ClickPauseLoop
  POP DE
  JP VoiceAEnvelope

; Title drum 3: noise from the ROM
;
; 150 pulses whose levels and lengths are the bytes of the ROM from $0064: code
; read as random numbers.
DrumNoise:
  PUSH DE
  LD B,$96
  LD DE,$0064             ; the ROM as a noise table
NoisePulseLoop:
  LD A,(DE)
  INC DE
  AND $18
  OUT ($FE),A             ; a level from one byte
  LD A,(DE)               ; a length from the next
  AND $18
  INC A
  INC DE
NoiseLengthLoop:
  DEC A
  JP NZ,NoiseLengthLoop
  DJNZ NoisePulseLoop
  POP DE
  JP VoiceAEnvelope

; Title drum 4: a rising tone, half-period 50 down to 1
;
; The beeper toggled 50 times with two waits of D each, D from 50 down to 1: a
; tone rising in pitch. Then back to voice A's envelope.
DrumRise:
  PUSH DE
  XOR A
  LD D,$32
RiseStepLoop:
  LD B,D
RiseFirstWait:
  DJNZ RiseFirstWait
  LD B,D
RiseSecondWait:
  DJNZ RiseSecondWait
  XOR $18
  OUT ($FE),A             ; toggle the beeper
  DEC D
  JP NZ,RiseStepLoop
  POP DE
  JP VoiceAEnvelope

; Title drum 6: a falling tone, period 180 up in steps of 4
;
; The beeper toggled with one wait of D, D from 180 up in steps of 4 until it
; wraps past 255 (19 steps): a tone falling in pitch.
DrumFall:
  PUSH DE
  XOR A
  LD D,$B4
FallStepLoop:
  LD B,D
FallWait:
  DJNZ FallWait
  XOR $18
  OUT ($FE),A             ; toggle the beeper
  INC D
  INC D
  INC D
  INC D
  JP NZ,FallStepLoop
  POP DE
  JP VoiceAEnvelope

; Title drum 5: a rising tone, period 200 down to 124
;
; The beeper toggled with one wait of D, D from 200 down in steps of 4 while it
; is at least 124 (20 steps): a short rising tone, then back to voice A's
; envelope.
DrumSweep:
  PUSH DE
  LD E,$00
  LD D,$C8
SweepStepLoop:
  LD A,E
  LD B,D
SweepWait:
  DJNZ SweepWait
  XOR $18
  OUT ($FE),A             ; toggle the beeper
  DEC D
  DEC D
  DEC D
  DEC D
  LD E,A
  LD A,D
  CP $7C
  JP NC,SweepStepLoop
  POP DE
  JP VoiceAEnvelope

; Title player's stack
;
; SP points at $83F7 from $803E on: the interrupts and the command dispatch
; push here. Stale bytes in the image.
TitleStack:
  DEFB $08,$00,$00,$00,$00,$1A,$03,$DB
  DEFB $02,$4D,$00,$39,$32,$05,$00,$03
  DEFB $03,$7B,$00,$93,$0C

; The IM 2 vector address
;
; Written at $8049 ($FDFD when I = $FE), read by the exit $8357. The image
; holds a stale value.
TitleVectorAddr:
  DEFW $0058

; The 3 bytes the title replaced at the vector
;
; Saved at $8052, put back at $8361.
TitleVectorSave:
  DEFB $F3,$AF,$11

; Pattern command handlers 0-18
;
; Read by $8088, 2 bytes a command: 0 $8175 hold, 1-4 $8098-$80B9 voice
; parameters, 5-8 $80C2-$80D4 envelope modes, 9 $8109 end of pattern, 10-12
; $819B, $81EE, $821A notes, 13-15 $80DA-$80ED silence, 16 $8101 drums, 17
; $80F5 note length, 18 $817A long note; docs/09-sound.md 9.3.
TitleCommands:
  DEFW CmdHold,CmdWidthA,CmdWidthB,CmdEnvelopeA
  DEFW CmdEnvelopeB,CmdModeA,$80C8,CmdModeBHold
  DEFW CmdModeBDecay,CmdPatternEnd,CmdNoteAB,CmdNoteA
  DEFW CmdNoteB,CmdSilence,$80E5,$80ED
  DEFW CmdDrums,CmdNoteLength,CmdLongNote

; Patch list: 9 x (address, byte)
;
; Applied by $803A at every start: periods $64 ($82CA, $832C), both voices
; silenced ($82D0, $8332), pulse widths $17 ($82D4, $8336), pre-delays 1
; ($82CC, $832E), the long-note counter 0 ($817B).
TitlePatches:
  DEFB $CA,$82,$64
  DEFB $2C,$83,$64
  DEFB $D0,$82,$00
  DEFB $32,$83,$00
  DEFB $D4,$82,$17
  DEFB $36,$83,$17
  DEFB $CC,$82,$01
  DEFB $2E,$83,$01
  DEFB $7B,$81,$00

; Tune table
;
; One song address a tune, picked by C at $806F. Tune 0 is $843F.
TuneTable:
  DEFW TuneSong

; Tune 0: the song
;
; Song entries ($8118): n and a pattern address, $FB and a drum pattern
; address, $FD and an address (jump). It plays $8467 once, then $8473 x5,
; $84A8, $84C6 x2, $853B, $84C6 x2, $853B with drums $85A2 and $85B4, and jumps
; back to the start at $8460: the tune loops until a key. The last 4 bytes
; (pattern $83E8, $FC) are never reached.
TuneSong:
  INCBIN "res/music/title/song.bin",$0000,40

; Tune 0: set-up pattern
;
; Command 8 (voice B mode 0), 17 (note length 5), 1-4 (the voices' parameters),
; 9 (end). Pattern commands are listed at $83FC.
PatternInit:
  INCBIN "res/music/title/pattern-init.bin",$0000,12

; Tune 0: pattern A
;
; Notes: command 10 with two periods, 11 or 12 with one; 0 holds, 18 n holds n
; note lengths, 9 ends the pattern.
PatternA:
  INCBIN "res/music/title/pattern-a.bin",$0000,53

; Tune 0: pattern B
PatternB:
  INCBIN "res/music/title/pattern-b.bin",$0000,30

; Tune 0: pattern C
PatternC:
  INCBIN "res/music/title/pattern-c.bin",$0000,117

; Tune 0: pattern D
;
; Uses command 16 at $8583 to switch to the drums $85B4.
PatternD:
  INCBIN "res/music/title/pattern-d.bin",$0000,103

; Drum pattern: clicks and noise
;
; The speed (5 frames a step), then the steps: 2 click, 3 noise, 0 rest, 1
; loop; docs/09-sound.md 9.5.
DrumPatternA:
  INCBIN "res/music/title/drums-a.bin",$0000,18

; Drum pattern: the three tones
;
; Speed 5, then the drums 4 (rising), 5 (sweep) and 6 (falling) and 1 loop.
DrumPatternB:
  INCBIN "res/music/title/drums-b.bin",$0000,18

; Unused, zero
TitleTail:
  DEFS $3A
