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
  LD HL,MenuInterrupt
  LD (Handler),HL
  LD HL,BassTrack         ; HL' = the bass track
  LD DE,LeadTrack         ; DE' = the lead track
  LD BC,$0101             ; B' = C' = 1: read both voices at the first
                          ; interrupt
  EXX
  LD HL,DrumTrackSteady   ; HL = the drum track, C = 1: read it at the first
                          ; interrupt
  EI
  LD C,$01
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
  LD A,(Input)
  LD (Input),A
  POP AF

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
  JP NZ,LeadIdlePad
  LD D,$00                ; reload: the note's period, written by LeadNextEvent
                          ; ($C540)
  LD A,$18                ; $18 voice on, 0 off: written by LeadOn / LeadOff
  OUT ($FE),A             ; the pulse's leading edge
  LD A,$00                ; the pulse width: period / 4, written by $C547
LeadPulse:
  DEC A                   ; hold the pulse
  JP NZ,LeadPulse
  OUT ($FE),A             ; A = 0: the trailing edge
  JP BassStep
LeadIdlePad:
  PUSH AF                 ; no edge: the same pad as BassIdlePad
  LD A,(Input)

; the rest of the lead pad (an entry only because work/deep starts its
; recording here)
;
; Write Input back and POP AF, then fall into BassStep. The recording of
; work/deep began inside the tone loop at this instruction, so its L1 lists the
; address as a root.
LeadIdlePadTail:
  LD (Input),A
  POP AF

; tone loop: count the bass period down, at 0 a pulse
;
; The bass voice's twin of LeadStep: E is its counter, the operands $C4ED
; (period), $C4EF (on / off) and $C4F3 (pulse width) are written by
; BassNextEvent, BassOn and BassOff.
BassStep:
  DEC E                   ; the bass counter
  JP NZ,BassIdlePad
  LD E,$00                ; reload: the note's period, written by BassNextEvent
                          ; ($C52D)
  LD A,$18                ; $18 voice on, 0 off: written by BassOn / BassOff
  OUT ($FE),A
  LD A,$00                ; the pulse width: period / 4, written by $C534
BassPulse:
  DEC A                   ; hold the pulse
  JP NZ,BassPulse
  OUT ($FE),A
  JP LeadStep             ; next turn: the lead voice

; the interrupt handler of the menu
;
; The drum, the bass and lead note readers, the title colours; a number key
; ends MenuMusic. It returns to the tone loop of MenuMusic, or, with SP from
; SavedSP, to the menu.
MenuInterrupt:
  PUSH AF
  DEC C                   ; the drum's frames run out: play the next drum
                          ; record (inside the interrupt, the tone loop waits)
  CALL Z,DrumStep
  EXX                     ; the voices' registers
  DEC C                   ; the bass note's frames run out: the next bass event
  CALL Z,BassNextEvent
  DEC B                   ; the lead note's frames run out: the next lead event
  CALL Z,LeadNextEvent
  CALL TitleColourCycle   ; the title's colours
  LD A,$E7                ; half-rows 1-5 and 6-0: a number key, any menu
                          ; choice
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,MenuMusicExit
  EXX                     ; none: back to the tone loop
  POP AF
  EI
  RET
MenuMusicExit:
  DI                      ; a number key: drop the tone loop, return from
                          ; MenuMusic to the menu
  LD SP,(SavedSP)           ; SP as MenuMusic left it: the next RET returns to
                          ; $C1A1
  LD HL,StartInterrupt
  LD (Handler),HL
  EI
  RET

; read the bass voice's next event: a note, or a command
;
; HL' = the bass track position. A byte of 9 or more is a note: the byte is the
; period (written into $C4ED, and period / 4 into the pulse width $C4F3) and
; the next byte its length in frames (C'). A byte below 9 is a command
; (BassCommand). Called by MenuInterrupt when C' runs out, and jumped to again
; by every command handler, so commands take no time.
BassNextEvent:
  LD A,(HL)               ; the event byte
  CP $09
  JR C,BassCommand        ; below 9: a command
  LD (BassStep+$0005),A   ; the period into LD E,n
  RRCA                    ; the pulse width: period / 4
  RRCA
  AND $3F
  LD (BassStep+$000B),A
  INC HL                  ; C' = the note's frames
  LD C,(HL)
  INC HL
  RET

; read the lead voice's next event: a note, or a command
;
; The lead twin of BassNextEvent: DE' = the position, the note goes into $C4D0
; / $C4D6 and its frames into B'.
LeadNextEvent:
  LD A,(DE)               ; the event byte
  CP $09
  JR C,LeadCommand        ; below 9: a command
  LD (LeadStep+$0005),A   ; the period into LD D,n
  RRCA                    ; the pulse width: period / 4
  RRCA
  AND $3F
  LD (LeadStep+$000B),A
  INC DE
  LD A,(DE)               ; B' = the note's frames
  LD B,A
  INC DE
  RET
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
  DEFB $C3,$A7,$C5

; bass command 2 (entry): JP BassCall
;
; A table entry of BassCommandTable: command 2 calls a pattern.
BassCmd2:
  JP BassCall

; bass command 3 (entry): JP SetDrumTrack
;
; A table entry: command 3 starts another drum track.
BassCmd3:
  JP SetDrumTrack

; bass command 4 (entry): JP BassOn
;
; A table entry: command 4 turns the bass voice on.
BassCmd4:
  JP BassOn

; bass command 5 (entry): JP BassOff
;
; A table entry: command 5 turns the bass voice off (its notes keep their time,
; silent).
BassCmd5:
  JP BassOff

; bass command 6 (entry): JP BassReturn
;
; A table entry: command 6 ends a pattern.
BassCmd6:
  JP BassReturn

; bass commands 7 and 8: JP SetDrumTrack twice (unused, the same as command 3)
BassCmd7:
  DEFB $C3,$CC,$C5
  DEFB $C3,$CC,$C5

; command A of the lead track: jump to entry A of the table after the CALL
;
; The lead twin of BassCommand. HL' (the bass position) is pushed so the
; handlers can pop it back.
LeadCommand:
  PUSH HL
  CALL MusicDispatch      ; MusicDispatch pops the table address
LeadCommandTable:
  JP DefineKeyDone        ; entry 0: JP $C4A6 (never used)

; lead command 1: JP LeadGoto ($C5B0)
LeadCmd1:
  DEFB $C3,$B0,$C5

; lead command 2 (entry): JP LeadCall
;
; A table entry of LeadCommandTable: command 2 calls a pattern.
LeadCmd2:
  JP LeadCall

; lead command 3: JP SetDrumTrack, a bass-only handler (it reads HL', the bass
; track): unusable from the lead track and unused
LeadCmd3:
  DEFB $C3,$CC,$C5

; lead command 4 (entry): JP LeadOn
;
; A table entry: command 4 turns the lead voice on.
LeadCmd4:
  JP LeadOn

; lead command 5 (entry): JP LeadOff
;
; A table entry: command 5 turns the lead voice off.
LeadCmd5:
  JP LeadOff

; lead command 6 (entry): JP LeadReturn
;
; A table entry: command 6 ends a pattern.
LeadCmd6:
  JP LeadReturn

; lead commands 7 and 8: JP SetDrumTrack twice (unused)
LeadCmd7:
  DEFB $C3,$CC,$C5
  DEFB $C3,$CC,$C5

; bass command 2 aa: play the pattern at aa, then go on after the command
;
; One level only: the return position (the address operand's high byte) is kept
; in $FD54; BassReturn resumes one byte past it.
BassCall:
  POP HL                  ; HL' = the bass position again
  INC HL
  LD A,(HL)
  INC HL
  LD (BassReturnPos),HL           ; the return point
  LD H,(HL)               ; HL' = the pattern
  LD L,A
  JP BassNextEvent

; lead command 2 aa: play the pattern at aa, then go on after the command
;
; The return position is kept in $FD56.
LeadCall:
  POP HL                  ; HL' back (the bass position); DE' is the lead
                          ; position
  EX DE,HL
  INC HL
  LD A,(HL)
  INC HL
  LD (LeadReturnPos),HL           ; the return point
  LD H,(HL)
  LD L,A
  EX DE,HL                ; DE' = the pattern
  JP LeadNextEvent

; bass command 1 aa: continue the track at aa (code: POP HL, read the word, JP
; BassNextEvent)
;
; Code that runs when the tune loops (frame 5099 of a menu left alone): the
; recordings never stayed in the menu that long, so the cut keeps it as data.
; POP HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; JP $C528. The bass
; track ends with 1 $C678.
BassGoto:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP BassNextEvent

; lead command 1 aa: continue the track at aa (code, run only when the tune
; loops)
;
; POP HL; EX DE,HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; EX DE,HL; JP
; $C53B. The lead track ends with 1 $C702.
LeadGoto:
  POP HL
  EX DE,HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  EX DE,HL
  JP LeadNextEvent

; bass command 6: back from the pattern to the bass track
;
; Used by the routine at BassCmd6.
BassReturn:
  POP HL
  LD HL,(BassReturnPos)           ; one past the call's address operand
  INC HL
  JP BassNextEvent

; lead command 6: back from the pattern to the lead track
;
; Used by the routine at LeadCmd6.
LeadReturn:
  POP HL
  LD DE,(LeadReturnPos)           ; one past the call's address operand
  INC DE
  JP LeadNextEvent

; bass command 3 aa: the drum plays the track at aa from its next record
;
; Writes aa into the main set's HL, the drum position (the frames left of the
; current drum record are kept). Read through the bass voice's HL', so only the
; bass track may use it.
SetDrumTrack:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  EXX                     ; low byte into the drum's HL
  LD L,A
  EXX
  LD A,(HL)
  INC HL
  EXX                     ; high byte into the drum's HL
  LD H,A
  EXX
  JP BassNextEvent

; play the next drum record (a short noise or sweep inside the interrupt)
;
; HL = the drum position, called by MenuInterrupt when the drum's frames (C)
; run out. A record is the frames until the next one and a kind: 0 a hiss (96
; bytes of ROM from $08xx sent to the beeper, about 1 ms), 2 p a falling tone
; (48 cycles: the low half starts at p - 1 and shortens by 1, the high half
; starts at p / 2 and lengthens by 4), any other kind a rasp (80 ROM bytes from
; $00xx with a gap that mostly grows). The byte 1 in place of the frames is a
; goto: 1 aa. The tone loop stands still while a drum plays. In the 5300-frame
; experiment kinds 1 and 2 ran 72 times each.
DrumStep:
  LD A,(HL)               ; the frames, or 1
  INC HL
  CP $01                  ; 1 aa: goto
  JR Z,DrumGoto
  LD C,A                  ; C = the frames to the next record
  LD A,(HL)               ; the kind
  INC HL
  CP $02
  JR Z,DrumSweep
  AND A
  JR Z,DrumHiss
DrumRasp:
  PUSH HL                 ; any other kind: 80 ROM bytes $00xx; the gap (~B &
                          ; $3F) grows $2F-$3F, once 256, then 1-$3E
  LD H,$00
  LD B,$50
DrumRaspLoop:
  LD A,(HL)               ; a ROM byte's EAR / MIC bits to the beeper
  AND $18
  OUT ($FE),A
  LD A,B
  CPL
  AND $3F
DrumRaspGap:
  DEC A
  JR NZ,DrumRaspGap
  INC HL
  DJNZ DrumRaspLoop
  POP HL
  RET
DrumGoto:
  LD A,(HL)               ; the record 1 aa: continue at aa
  INC HL
  LD H,(HL)
  LD L,A
  JP DrumStep
DrumHiss:
  PUSH HL                 ; kind 0: 96 ROM bytes $08xx straight to the beeper
  LD H,$08
  LD B,$60
DrumHissLoop:
  LD A,(HL)
  AND $18
  OUT ($FE),A
  DJNZ DrumHissLoop
  POP HL
  RET
DrumSweep:
  LD A,(HL)               ; kind 2 p: the falling tone
  INC HL
  PUSH HL
  LD B,$30
  LD L,A                  ; the low half
  RRCA                    ; the high half: p / 2
  LD H,A
DrumSweepLoop:
  XOR A                   ; the low half, one shorter each cycle
  OUT ($FE),A
  DEC L
  LD A,L
DrumSweepLow:
  DEC A
  JR NZ,DrumSweepLow
  LD A,$18                ; the high half, 4 longer each cycle
  OUT ($FE),A
  LD A,$04
  ADD A,H
  LD H,A
DrumSweepHigh:
  DEC A
  JR NZ,DrumSweepHigh
  DJNZ DrumSweepLoop
  POP HL
  RET

; bass command 4: the bass pulses sound again
;
; Used by the routine at BassCmd4.
BassOn:
  POP HL
  LD A,$18                ; EAR and MIC into the bass pulse ($C4EF)
  LD (BassStep+$0007),A
  INC HL
  JP BassNextEvent

; bass command 5: the bass pulses go silent (the notes still take their time)
;
; Used by the routine at BassCmd5.
BassOff:
  POP HL
  XOR A
  LD (BassStep+$0007),A
  INC HL
  JP BassNextEvent

; lead command 4: the lead pulses sound again
;
; Used by the routine at LeadCmd4.
LeadOn:
  POP HL
  LD A,$18                ; EAR and MIC into the lead pulse ($C4D2)
  LD (LeadStep+$0007),A
  INC DE
  JP LeadNextEvent

; lead command 5: the lead pulses go silent
;
; Used by the routine at LeadCmd5.
LeadOff:
  POP HL
  XOR A
  LD (LeadStep+$0007),A
  INC DE
  JP LeadNextEvent

; jump to entry A of the 3-byte JP table that follows the caller's CALL
;
; Called with A = the command (below 9) from BassCommand / LeadCommand; it pops
; its own return address (the table) and jumps to table + 3 * A, so the handler
; returns to nobody: each jumps back to the voice's reader.
MusicDispatch:
  LD L,A
  ADD A,A
  ADD A,L
  POP HL                  ; the table, after the CALL
  ADD A,L
  LD L,A
  JR NC,MusicDispatchJump
  INC H
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
  PUSH BC
  PUSH HL
  LD HL,$582A             ; row 1, column 10
  LD A,(TitleColourPhase)            ; the phase, 0-15
  INC A
  AND $0F
  LD (TitleColourPhase),A
  RRCA                    ; odd: nothing this frame
  JR C,TitleColourDone
  OR $40                  ; BRIGHT, ink = phase / 2
  LD BC,$0C07             ; 12 columns, 7 rows
TitleColourRow:
  PUSH BC
TitleColourCell:
  LD (HL),A
  INC HL
  DJNZ TitleColourCell
  LD B,A                  ; to the next row: 12 + 20
  LD A,$14
  CALL AddAToHL
  LD A,B
  POP BC
  DEC C
  JR NZ,TitleColourRow
TitleColourDone:
  POP HL
  POP BC
  RET
