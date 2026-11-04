; --------------------------------------------------------------------------------------------------------------------
; music.asm: The menu tune: a two-voice beeper loop, the drum and the note readers in the interrupt, the title colours
;
; The tune that plays while the main menu waits for a key, and the colour cycle of the NETHER EARTH title. Docs:
; 09-sound.md 9.1-9.4 (the loop, the interrupt, the track formats, the tune); the track format is also in
; src/res/README.md (Menu tune text) and the tune data is src/res/music/menu.txt.
;
; Calling order: MainMenuKeys ($C19E) calls MenuMusic, which saves SP in SavedSP, makes MenuInterrupt the Handler,
; sets the track positions and never returns by itself: it runs the tone loop (LeadStep / BassStep, each voice a
; square-ish pulse train counted in loop turns by D and E). Every frame MenuInterrupt plays the next drum record
; (DrumStep, which stops the tone loop for its length), reads the next bass and lead events when their frames run out
; (BassNextEvent, LeadNextEvent, commands through MusicDispatch and the two JP tables), recolours the title
; (TitleColourCycle) and, when a number key is down, loads SP from SavedSP and returns from MenuMusic itself
; (MenuMusicExit).
;
; Registers own the state: the main set's D / E are the lead / bass period counters, HL the drum position, C the
; drum's frames left; the alternate set's HL' the bass position, DE' the lead position, C' / B' the bass / lead frames
; left. The interrupt saves only AF. The periods, the pulse widths and the on / off values are operands of the tone
; loop's own instructions, written by the readers (self-modifying code: $C4D0, $C4D2, $C4D6, $C4ED, $C4EF, $C4F3).
;
; Tracks: a note is (period >= 9, frames); a byte below 9 is a command: 1 aa goto, 2 aa call a pattern (one level, the
; return in BassReturnPos / LeadReturnPos), 3 aa start a drum track (bass only), 4 on, 5 off, 6 return; 0, 7, 8
; unused. Drum records are (frames, kind[, p]): 0 a hiss, 2 p a falling sweep, others a rasp; 1 aa goto. The tune is
; 5120 frames (102.4 s) and loops.
;
; Quirks: MenuMusic does not reset the on / off operands, so a tune restarted (after keys 1-3) while a voice was off
; stays silent until that voice's next command 4 (docs 9.4). Command 3 in the lead table would use the bass position.
; The exit leaves the alternate set swapped in; the menu keeps nothing in registers.
; --------------------------------------------------------------------------------------------------------------------

; play the menu tune until a number key is pressed
;
; Called once by the main menu ($C19E) after all keys are up. Saves SP in
; $FD08, installs MenuInterrupt as Handler and sets the music state: the bass
; voice reads the track $C678 through HL' (frames left C'), the lead voice the
; track $C702 through DE' (frames left B'), the drum the track $C665 through HL
; (frames left C); C' = B' = C = 1, so the first interrupt reads the first
; event of each. Then it runs the tone loop for ever: the main set's D and E
; count each voice's period down.
;
; The tone loop never returns: MenuInterrupt ends it by loading SP from $FD08
; when a number key is down, so the RET of the interrupt returns from MenuMusic
; to the menu ($C1A1), which then reads the key. Ran 144 frames in work/play
; (12666-12814). The tune is 5120 frames (102.4 s) long in each voice and loops
; (experiment: both voices jumped back at frame 5099 of a menu left alone);
; docs: r4.md.
MenuMusic:
  DI                      ; no interrupt while the state is set
  LD (SavedSP),SP           ; the stack for the exit from MenuInterrupt
  LD HL,MenuInterrupt     ; Handler: the IM 2 vector at $FDFD jumps to
                          ; MenuInterrupt now
  LD (Handler),HL           ; Handler = MenuInterrupt
  LD HL,BassTrack         ; HL' = the bass track
  LD DE,LeadTrack         ; DE' = the lead track
  LD BC,$0101             ; B' = C' = 1: read both voices at the first
                          ; interrupt
  EXX                     ; HL, DE, BC become HL', DE', BC'
  LD HL,DrumTrackSteady   ; HL = the drum track, C = 1: read it at the first
                          ; interrupt
  EI                      ; the interrupt may run (the HALT below waits for it)
  LD C,$01                ; C = 1: the drum's first record at the first
                          ; interrupt
  HALT                    ; start on an interrupt

; tone loop: the time of a bass step without an edge
;
; The tone loop runs LeadStep and BassStep in turn, about 122 T a turn. A step
; whose counter has not run out takes this pad (PUSH AF, read Input and write
; it back unchanged, POP AF: 61 T with the DEC / JP) so both paths take about
; the same time, the pitch stays steady whatever the other voice does.
BassIdlePad:
  PUSH AF                 ; a pad: Input is written back unchanged, only the
                          ; time counts
  LD A,(Input)            ; 13 T: a read of Input ...
  LD (Input),A            ; ... and the same value back, 13 T
  POP AF                  ; A and the flags back: the pad leaves no trace

; tone loop: count the lead period down, at 0 a pulse
;
; D counts the lead voice's period in loop turns. At 0 it reloads D with the
; note's period (the operand $C4D0), sets the beeper (EAR and MIC, $18, or 0
; when the voice is off: the operand $C4D2) for a pulse of 14 * width T (the
; operand $C4D6 = period / 4, at most 63), then clears it. The voice's pitch is
; about 3.5 MHz / (122 + 3.5) / period: period $7C about 225 Hz, $29 about 680
; Hz.
LeadStep:
  DEC D                   ; the lead counter
  JP NZ,LeadIdlePad       ; not run out: the pad, then the bass
  LD D,$00                ; reload: the note's period, written by LeadNextEvent
                          ; ($C540)
  LD A,$18                ; $18 voice on, 0 off: written by LeadOn / LeadOff
  OUT ($FE),A             ; the pulse's leading edge
  LD A,$00                ; the pulse width: period / 4, written by $C547
LeadPulse:
  DEC A                   ; hold the pulse
  JP NZ,LeadPulse         ; until the width is used up
  OUT ($FE),A             ; A = 0: the trailing edge
  JP BassStep             ; on to the bass voice
LeadIdlePad:
  PUSH AF                 ; no edge: the same pad as BassIdlePad
  LD A,(Input)            ; 13 T: Input read ...

; the rest of the lead pad (an entry only because work/deep starts its
; recording here)
;
; Write Input back and POP AF, then fall into BassStep. The recording of
; work/deep began inside the tone loop at this instruction, so its L1 lists the
; address as a root.
LeadIdlePadTail:
  LD (Input),A            ; ... and written back unchanged
  POP AF                  ; A and the flags back

; tone loop: count the bass period down, at 0 a pulse
;
; The bass voice's twin of LeadStep: E is its counter, the operands $C4ED
; (period), $C4EF (on / off) and $C4F3 (pulse width) are written by
; BassNextEvent, BassOn and BassOff.
BassStep:
  DEC E                   ; the bass counter
  JP NZ,BassIdlePad       ; not run out: the pad, then the lead
  LD E,$00                ; reload: the note's period, written by BassNextEvent
                          ; ($C52D)
  LD A,$18                ; $18 voice on, 0 off: written by BassOn / BassOff
  OUT ($FE),A             ; the pulse's leading edge
  LD A,$00                ; the pulse width: period / 4, written by $C534
BassPulse:
  DEC A                   ; hold the pulse
  JP NZ,BassPulse         ; until the width is used up
  OUT ($FE),A             ; A = 0: the trailing edge
  JP LeadStep             ; next turn: the lead voice

; the interrupt handler of the menu
;
; The drum, the bass and lead note readers, the title colours; a number key
; ends MenuMusic. It returns to the tone loop of MenuMusic, or, with SP from
; SavedSP, to the menu.
MenuInterrupt:
  PUSH AF                 ; the tone loop's A and flags
  DEC C                   ; the drum's frames run out: play the next drum
                          ; record (inside the interrupt, the tone loop waits)
  CALL Z,DrumStep         ; DrumStep: one drum record, with the tone loop
                          ; stopped
  EXX                     ; the voices' registers
  DEC C                   ; the bass note's frames run out: the next bass event
  CALL Z,BassNextEvent    ; BassNextEvent: the next note or commands of the
                          ; bass
  DEC B                   ; the lead note's frames run out: the next lead event
  CALL Z,LeadNextEvent    ; LeadNextEvent: the next note or commands of the
                          ; lead
  CALL TitleColourCycle   ; the title's colours
  LD A,$E7                ; half-rows 1-5 and 6-0: a number key, any menu
                          ; choice
  IN A,($FE)              ; IN from $E7FE: the half rows 1-5 and 6-0
  CPL                     ; a pressed key reads 0: invert
  AND $1F                 ; the five key bits
  JR NZ,MenuMusicExit     ; a number key is down
  EXX                     ; none: back to the tone loop
  POP AF                  ; the tone loop's A and flags back
  EI                      ; interrupts on for the next frame
  RET                     ; into the tone loop where it was
MenuMusicExit:
  DI                      ; a number key: drop the tone loop, return from
                          ; MenuMusic to the menu
  LD SP,(SavedSP)           ; SP as MenuMusic left it: the next RET returns to
                          ; $C1A1
  LD HL,StartInterrupt    ; Handler back to StartInterrupt (EI; RET)
  LD (Handler),HL           ; nothing runs in the menu's HALTs now
  EI                      ; interrupts on
  RET                     ; returns from MenuMusic to the menu ($C1A1)

; read the bass voice's next event: a note, or a command
;
; HL' = the bass track position. A byte of 9 or more is a note: the byte is the
; period (written into $C4ED, and period / 4 into the pulse width $C4F3) and
; the next byte its length in frames (C'). A byte below 9 is a command
; (BassCommand). Called by MenuInterrupt when C' runs out, and jumped to again
; by every command handler, so commands take no time.
BassNextEvent:
  LD A,(HL)               ; the event byte
  CP $09                  ; a period is 9 or more
  JR C,BassCommand        ; below 9: a command
  LD (BassStep+$0005),A   ; the period into LD E,n
  RRCA                    ; the pulse width: period / 4
  RRCA                    ; A = period / 4 ...
  AND $3F                 ; 0-63
  LD (BassStep+$000B),A   ; into LD A,n of the bass pulse ($C4F3)
  INC HL                  ; C' = the note's frames
  LD C,(HL)               ; C' = the note's frames
  INC HL                  ; HL' = the next event
  RET                     ; back into MenuInterrupt

; read the lead voice's next event: a note, or a command
;
; The lead twin of BassNextEvent: DE' = the position, the note goes into $C4D0
; / $C4D6 and its frames into B'.
LeadNextEvent:
  LD A,(DE)               ; the event byte
  CP $09                  ; a period is 9 or more
  JR C,LeadCommand        ; below 9: a command
  LD (LeadStep+$0005),A   ; the period into LD D,n
  RRCA                    ; the pulse width: period / 4
  RRCA                    ; A = period / 4 ...
  AND $3F                 ; 0-63
  LD (LeadStep+$000B),A   ; into LD A,n of the lead pulse ($C4D6)
  INC DE                  ; the frames byte
  LD A,(DE)               ; B' = the note's frames
  LD B,A                  ; B' = the frames
  INC DE                  ; DE' = the next event
  RET                     ; back into MenuInterrupt
; This entry point is used by the routine at BassNextEvent.
BassCommand:
  PUSH HL                 ; command A of the bass track: jump to entry A of the
                          ; table after the CALL
  CALL MusicDispatch      ; MusicDispatch pops the table address
BassCommandTable:
  JP DefineKeyDone        ; entry 0: JP $C4A6 (never used, it would RET into
                          ; the pushed HL)

; bass command 1: JP BassGoto ($C5A7), the 3-byte entry 1
BassCmd1:
  DEFB $C3,$A7,$C5        ; entry 1: JP $C5A7 (BassGoto), the bass track's goto

; bass command 2 (entry): JP BassCall
;
; A table entry of BassCommandTable: command 2 calls a pattern.
BassCmd2:
  JP BassCall             ; entry 2: call a pattern

; bass command 3 (entry): JP SetDrumTrack
;
; A table entry: command 3 starts another drum track.
BassCmd3:
  JP SetDrumTrack         ; entry 3: start a drum track

; bass command 4 (entry): JP BassOn
;
; A table entry: command 4 turns the bass voice on.
BassCmd4:
  JP BassOn               ; entry 4: bass on

; bass command 5 (entry): JP BassOff
;
; A table entry: command 5 turns the bass voice off (its notes keep their time,
; silent).
BassCmd5:
  JP BassOff              ; entry 5: bass off

; bass command 6 (entry): JP BassReturn
;
; A table entry: command 6 ends a pattern.
BassCmd6:
  JP BassReturn           ; entry 6: back from a pattern

; bass commands 7 and 8: JP SetDrumTrack twice (unused, the same as command 3)
BassCmd7:
  DEFB $C3,$CC,$C5        ; entry 7: JP $C5CC (SetDrumTrack), unused
  DEFB $C3,$CC,$C5        ; entry 8: JP $C5CC (SetDrumTrack), unused

; command A of the lead track: jump to entry A of the table after the CALL
;
; The lead twin of BassCommand. HL' (the bass position) is pushed so the
; handlers can pop it back.
LeadCommand:
  PUSH HL                 ; HL' (the bass position) kept for the handler to pop
  CALL MusicDispatch      ; MusicDispatch pops the table address
LeadCommandTable:
  JP DefineKeyDone        ; entry 0: JP $C4A6 (never used)

; lead command 1: JP LeadGoto ($C5B0)
LeadCmd1:
  DEFB $C3,$B0,$C5        ; entry 1: JP $C5B0 (LeadGoto), the lead track's goto

; lead command 2 (entry): JP LeadCall
;
; A table entry of LeadCommandTable: command 2 calls a pattern.
LeadCmd2:
  JP LeadCall             ; entry 2: call a pattern

; lead command 3: JP SetDrumTrack, a bass-only handler (it reads HL', the bass
; track): unusable from the lead track and unused
LeadCmd3:
  DEFB $C3,$CC,$C5        ; entry 3: JP $C5CC (SetDrumTrack), bass only, unused
                          ; by the lead track

; lead command 4 (entry): JP LeadOn
;
; A table entry: command 4 turns the lead voice on.
LeadCmd4:
  JP LeadOn               ; entry 4: lead on

; lead command 5 (entry): JP LeadOff
;
; A table entry: command 5 turns the lead voice off.
LeadCmd5:
  JP LeadOff              ; entry 5: lead off

; lead command 6 (entry): JP LeadReturn
;
; A table entry: command 6 ends a pattern.
LeadCmd6:
  JP LeadReturn           ; entry 6: back from a pattern

; lead commands 7 and 8: JP SetDrumTrack twice (unused)
LeadCmd7:
  DEFB $C3,$CC,$C5        ; entry 7: JP $C5CC (SetDrumTrack), unused
  DEFB $C3,$CC,$C5        ; entry 8: JP $C5CC (SetDrumTrack), unused

; bass command 2 aa: play the pattern at aa, then go on after the command
;
; One level only: the return position (the address operand's high byte) is kept
; in $FD54; BassReturn resumes one byte past it.
BassCall:
  POP HL                  ; HL' = the bass position again
  INC HL                  ; on to the address operand's low byte
  LD A,(HL)               ; A = the pattern's low byte
  INC HL                  ; HL' at the high byte
  LD (BassReturnPos),HL           ; the return point
  LD H,(HL)               ; HL' = the pattern
  LD L,A                  ; HL' = the pattern
  JP BassNextEvent        ; the pattern's first event, at once

; lead command 2 aa: play the pattern at aa, then go on after the command
;
; The return position is kept in $FD56.
LeadCall:
  POP HL                  ; HL' back (the bass position); DE' is the lead
                          ; position
  EX DE,HL                ; HL = the lead position (at the command byte)
  INC HL                  ; the address operand's low byte
  LD A,(HL)               ; A = the pattern's low byte
  INC HL                  ; at the high byte
  LD (LeadReturnPos),HL           ; the return point
  LD H,(HL)               ; H = the pattern's high byte
  LD L,A                  ; L = the low byte: HL = the pattern
  EX DE,HL                ; DE' = the pattern
  JP LeadNextEvent        ; the pattern's first event, at once

; bass command 1 aa: continue the track at aa (code: POP HL, read the word, JP
; BassNextEvent)
;
; Code that runs when the tune loops (frame 5099 of a menu left alone): the
; recordings never stayed in the menu that long, so the cut keeps it as data.
; POP HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; JP $C528. The bass
; track ends with 1 $C678.
BassGoto:
  POP HL                  ; HL' = the bass position (at the command byte)
  INC HL                  ; the address operand
  LD A,(HL)               ; A = the target's low byte
  INC HL                  ; at the high byte
  LD H,(HL)               ; HL' = the target
  LD L,A                  ; L = the low byte
  JP BassNextEvent        ; its first event, at once

; lead command 1 aa: continue the track at aa (code, run only when the tune
; loops)
;
; POP HL; EX DE,HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; EX DE,HL; JP
; $C53B. The lead track ends with 1 $C702.
LeadGoto:
  POP HL                  ; HL' back (the bass position)
  EX DE,HL                ; HL = the lead position
  INC HL                  ; the address operand
  LD A,(HL)               ; A = the target's low byte
  INC HL                  ; at the high byte
  LD H,(HL)               ; HL = the target
  LD L,A                  ; L = the low byte
  EX DE,HL                ; DE' = the target, HL' the bass position again
  JP LeadNextEvent        ; its first event, at once

; bass command 6: back from the pattern to the bass track
;
; Used by the routine at BassCmd6.
BassReturn:
  POP HL                  ; drop the pushed position
  LD HL,(BassReturnPos)           ; one past the call's address operand
  INC HL                  ; one past the address operand: the event after the
                          ; call
  JP BassNextEvent        ; the next event of the track, at once

; lead command 6: back from the pattern to the lead track
;
; Used by the routine at LeadCmd6.
LeadReturn:
  POP HL                  ; HL' back (the bass position)
  LD DE,(LeadReturnPos)           ; one past the call's address operand
  INC DE                  ; one past the address operand: the event after the
                          ; call
  JP LeadNextEvent        ; the next event of the track, at once

; bass command 3 aa: the drum plays the track at aa from its next record
;
; Writes aa into the main set's HL, the drum position (the frames left of the
; current drum record are kept). Read through the bass voice's HL', so only the
; bass track may use it.
SetDrumTrack:
  POP HL                  ; HL' = the bass position (at the command byte)
  INC HL                  ; the address operand's low byte
  LD A,(HL)               ; A = the drum track's low byte
  INC HL                  ; at the high byte
  EXX                     ; low byte into the drum's HL
  LD L,A                  ; the drum's L = the low byte
  EXX                     ; back to the voice set (HL' the bass position)
  LD A,(HL)               ; the high byte
  INC HL                  ; HL' past the command
  EXX                     ; high byte into the drum's HL
  LD H,A                  ; the drum's H = the high byte: HL = the new drum
                          ; track
  EXX                     ; back to the voice registers
  JP BassNextEvent        ; the next bass event, at once

; play the next drum record (a short noise or sweep inside the interrupt)
;
; HL = the drum position, called by MenuInterrupt when the drum's frames (C)
; run out. A record is the frames until the next one and a kind: 0 a hiss meant
; as 96 bytes of ROM from $08xx sent to the beeper, about 1 ms (but
; DrumHissLoop never steps HL: one ROM byte, $08 L, 96 times; in the recordings
; it is $23, EAR / MIC 0, so the hiss is silent: docs/09-sound.md), 2 p a
; falling tone (48 cycles: the low half starts at p - 1 and shortens by 1, the
; high half starts at p / 2 and lengthens by 4), any other kind a rasp (80 ROM
; bytes from $00xx with a gap that mostly grows). The byte 1 in place of the
; frames is a goto: 1 aa. The tone loop stands still while a drum plays. In the
; 5300-frame experiment kinds 1 and 2 ran 72 times each.
DrumStep:
  LD A,(HL)               ; the frames, or 1
  INC HL                  ; HL past the frames byte
  CP $01                  ; 1 aa: goto
  JR Z,DrumGoto           ; 1: the goto record
  LD C,A                  ; C = the frames to the next record
  LD A,(HL)               ; the kind
  INC HL                  ; HL past the kind: the next record (or p of a sweep)
  CP $02                  ; 2: the sweep
  JR Z,DrumSweep          ; kind 2
  AND A                   ; 0: the hiss
  JR Z,DrumHiss           ; kind 0
DrumRasp:
  PUSH HL                 ; any other kind: 80 ROM bytes $00xx; the gap (~B &
                          ; $3F) grows $2F-$3F, once 256, then 1-$3E
  LD H,$00                ; HL = $00xx: the ROM's first page, L = the
                          ; position's low byte
  LD B,$50                ; 80 beeper writes
DrumRaspLoop:
  LD A,(HL)               ; a ROM byte's EAR / MIC bits to the beeper
  AND $18                 ; only bits 3-4, MIC and EAR
  OUT ($FE),A             ; to the beeper (border black)
  LD A,B                  ; the gap from the count: ~B AND $3F
  CPL                     ; ~B: grows as B counts down
  AND $3F                 ; the gap, 0-63 turns (0 waits 256)
DrumRaspGap:
  DEC A                   ; wait (A = 0 waits 256 turns)
  JR NZ,DrumRaspGap       ; the gap
  INC HL                  ; the next ROM byte
  DJNZ DrumRaspLoop       ; 80 writes
  POP HL                  ; HL = the drum position
  RET                     ; back into MenuInterrupt
DrumGoto:
  LD A,(HL)               ; the record 1 aa: continue at aa
  INC HL                  ; at the high byte
  LD H,(HL)               ; H = the high byte
  LD L,A                  ; HL = the target
  JP DrumStep             ; its record at once
DrumHiss:
  PUSH HL                 ; kind 0: meant as 96 ROM bytes $08xx to the beeper;
                          ; one byte 96 times, in practice silence
  LD H,$08                ; HL = $08xx: ROM bytes as noise
  LD B,$60                ; 96 beeper writes
DrumHissLoop:
  LD A,(HL)               ; the ROM byte at HL ($08 L: HL never moves, the bug
                          ; that silences the hiss) ...
  AND $18                 ; bits 3-4 only
  OUT ($FE),A             ; ... to the beeper
  DJNZ DrumHissLoop       ; 96 writes of the same byte, as fast as DJNZ runs:
                          ; no edge when its bits are 0
  POP HL                  ; HL = the drum position
  RET                     ; back into MenuInterrupt
DrumSweep:
  LD A,(HL)               ; kind 2 p: the falling tone
  INC HL                  ; past p: the next record
  PUSH HL                 ; the drum position kept
  LD B,$30                ; 48 cycles
  LD L,A                  ; the low half
  RRCA                    ; the high half: p / 2
  LD H,A                  ; H = p / 2 (RRCA of p)
DrumSweepLoop:
  XOR A                   ; the low half, one shorter each cycle
  OUT ($FE),A             ; beeper low
  DEC L                   ; the low half one turn shorter each cycle
  LD A,L                  ; A = the low half's length
DrumSweepLow:
  DEC A                   ; hold the low half
  JR NZ,DrumSweepLow      ; the low half
  LD A,$18                ; the high half, 4 longer each cycle
  OUT ($FE),A             ; beeper high
  LD A,$04                ; the high half 4 turns longer each cycle
  ADD A,H                 ; + the last length
  LD H,A                  ; H = the new length
DrumSweepHigh:
  DEC A                   ; hold the high half
  JR NZ,DrumSweepHigh     ; the high half
  DJNZ DrumSweepLoop      ; the next cycle
  POP HL                  ; HL = the drum position
  RET                     ; back into MenuInterrupt

; bass command 4: the bass pulses sound again
;
; Used by the routine at BassCmd4.
BassOn:
  POP HL                  ; HL' = the bass position (at the command)
  LD A,$18                ; EAR and MIC into the bass pulse ($C4EF)
  LD (BassStep+$0007),A   ; into LD A,n of BassStep: the bass sounds
  INC HL                  ; past the 1-byte command
  JP BassNextEvent        ; the next bass event, at once

; bass command 5: the bass pulses go silent (the notes still take their time)
;
; Used by the routine at BassCmd5.
BassOff:
  POP HL                  ; HL' = the bass position
  XOR A                   ; 0: no edge, the bass rests
  LD (BassStep+$0007),A   ; into the bass pulse ($C4EF)
  INC HL                  ; past the command
  JP BassNextEvent        ; the next bass event, at once

; lead command 4: the lead pulses sound again
;
; Used by the routine at LeadCmd4.
LeadOn:
  POP HL                  ; HL' back (the bass position)
  LD A,$18                ; EAR and MIC into the lead pulse ($C4D2)
  LD (LeadStep+$0007),A   ; into LD A,n of LeadStep: the lead sounds
  INC DE                  ; DE' past the 1-byte command
  JP LeadNextEvent        ; the next lead event, at once

; lead command 5: the lead pulses go silent
;
; Used by the routine at LeadCmd5.
LeadOff:
  POP HL                  ; HL' back
  XOR A                   ; 0: no edge, the lead rests
  LD (LeadStep+$0007),A   ; into the lead pulse ($C4D2)
  INC DE                  ; past the command
  JP LeadNextEvent        ; the next lead event, at once

; jump to entry A of the 3-byte JP table that follows the caller's CALL
;
; Called with A = the command (below 9) from BassCommand / LeadCommand; it pops
; its own return address (the table) and jumps to table + 3 * A, so the handler
; returns to nobody: each jumps back to the voice's reader.
MusicDispatch:
  LD L,A                  ; L = the command
  ADD A,A                 ; A = 2 x command
  ADD A,L                 ; A = 3 x command: the entry's offset
  POP HL                  ; the table, after the CALL
  ADD A,L                 ; + the table's low byte
  LD L,A                  ; L = the entry's low byte
  JR NC,MusicDispatchJump ; no carry into H
  INC H                   ; carry into H
MusicDispatchJump:
  JP (HL)                 ; to the command's JP

; drum track: a hiss every 32 frames (32 0, then 1 $C665)
;
; The drum tracks: records of (frames, kind[, p]) and gotos 1 aa; DrumStep.
; This one plays at the start and at the end of each pass of the tune; docs
; r4.md.
DrumTrackSteady:
  INCBIN "res/music/menu/drum-steady.bin",$0000,5

; a hiss record (32 0) that no goto reaches
DrumTrackUnused:
  INCBIN "res/music/menu/drum-unused.bin",$0000,2

; drum track: rasp 16, hiss 8, hiss 8, sweep $30 for 32 frames (64 frames),
; loops
;
; Started by the bass track's command 3 $C66C after the four intro riffs.
DrumTrackBeat:
  INCBIN "res/music/menu/drum-beat.bin",$0000,12

; the bass track: commands of 3 bytes (drums, pattern calls, the goto back)
;
; 3 $C665, 4 x 2 $C6BD (the riff), 3 $C66C, 2 x 2 $C6CC, 8 x 2 $C6DD, 5 x 2
; $C6CC, 3 $C665, 1 $C678: 5120 frames.
BassTrack:
  INCBIN "res/music/menu/bass-track.bin",$0000,69

; bass pattern: the 128-frame intro riff on $7C with rests, then $52
;
; Notes are (period, frames), commands 4 / 5 one byte: $7C 16, off, $7C 8, on,
; $7C 16, off, $7C 64, $52 24, on, return.
BassRiff:
  INCBIN "res/music/menu/bass-riff.bin",$0000,15

; bass pattern: $7C $6E $68 $5D twice, 64 frames each (512 frames)
BassWalk:
  INCBIN "res/music/menu/bass-walk.bin",$0000,17

; bass pattern: $7C in eighths with rests, then the run $8B $93 $A5 $BA $A5 $93
; $8B $7C $8B $93 $A5 (128 frames)
BassRun:
  INCBIN "res/music/menu/bass-run.bin",$0000,37

; the lead track: pattern calls, two long notes, the goto back
;
; 4 x riff $C789, 4 x phrase $C7AA, off, $C7AA, on, 5 x $C7C5, then $C7D2 /
; $C7C5 three times in turns, $3E 32, $37 32, 2 x $C7AA, 4 x the scale $C7DF, 4
; x $C789, 8 x $C7C5, 4 x $C789, 1 $C702: 5120 frames.
LeadTrack:
  INCBIN "res/music/menu/lead-track.bin",$0000,135

; lead pattern: $37 with rests, then trills $29 / $2E, $37, $3E (128 frames)
LeadRiff:
  INCBIN "res/music/menu/lead-riff.bin",$0000,33

; lead pattern: the tune's phrase $29 $2E $31 $37 $3E $49 $3E $45 $2E $29 $2E
; $34 $2E (256 frames)
LeadPhrase:
  INCBIN "res/music/menu/lead-phrase.bin",$0000,27

; lead pattern: $3E $52 $7C twice (64 frames)
LeadArpeggioA:
  INCBIN "res/music/menu/lead-arpeggio-a.bin",$0000,13

; lead pattern: $45 $5D $8B twice (64 frames)
LeadArpeggioB:
  INCBIN "res/music/menu/lead-arpeggio-b.bin",$0000,13

; lead pattern: the 16-note scale $29 up to $BA (high to low) twice, 4 frames a
; note (128 frames)
LeadScale:
  INCBIN "res/music/menu/lead-scale.bin",$0000,65

; cycle the ink of the NETHER EARTH title, one colour every 2 frames
;
; Counts $FD33 0-15 each call; on even counts it paints the attributes of rows
; 1-7, columns 10-21 (the big title printed by $C1E3) with BRIGHT, black paper
; and ink count / 2, so the ink runs through all 8 colours every 16 frames.
; Called every frame by the main menu's HALT loops ($C193, $C1A2) and by
; MenuInterrupt while the tune plays (26 calls over frames 0-26 of work/deep;
; it writes $582A-$58F5).
TitleColourCycle:
  PUSH BC                 ; kept: from MenuInterrupt BC is the voices' frame
                          ; counts (B' lead, C' bass)
  PUSH HL                 ; kept: from MenuInterrupt HL is the bass position
  LD HL,$582A             ; row 1, column 10
  LD A,(TitleColourPhase)            ; the phase, 0-15
  INC A                   ; the next phase
  AND $0F                 ; 0-15
  LD (TitleColourPhase),A            ; TitleColourPhase = the new phase
  RRCA                    ; odd: nothing this frame
  JR C,TitleColourDone    ; odd phase: no paint this frame
  OR $40                  ; BRIGHT, ink = phase / 2
  LD BC,$0C07             ; 12 columns, 7 rows
TitleColourRow:
  PUSH BC                 ; the counts kept
TitleColourCell:
  LD (HL),A               ; one attribute
  INC HL                  ; the next cell
  DJNZ TitleColourCell    ; 12 cells across
  LD B,A                  ; to the next row: 12 + 20
  LD A,$14                ; 20: from column 22 to column 10 of the next row
  CALL AddAToHL           ; HL += 20
  LD A,B                  ; A = the attribute again
  POP BC                  ; B = 12 columns again, C the rows left
  DEC C                   ; seven rows
  JR NZ,TitleColourRow    ; the next row
TitleColourDone:
  POP HL                  ; the caller's HL
  POP BC                  ; the caller's BC
  RET                     ; back to the menu loop or MenuInterrupt
