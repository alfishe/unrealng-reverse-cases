; --------------------------------------------------------------------------------------------------------------------
; sequencer.asm: The tune sequencer: order lists, patterns, ornaments
;
; One call of SequenceChannel a frame and channel: the note's frames count down; at 0 the pattern's next bytes are
; read (commands, then a note or a rest) and the note starts the voice. A pattern's $FF is met while the last note
; still sounds; the next frame takes the next order list entry, so patterns follow each other without a gap.
; --------------------------------------------------------------------------------------------------------------------

; One frame of channel IY driving voice IX
;
; UpdateOrnament first. When the pattern has ended (+$0B): once more from its
; start while +9 counts down, else the next order list entry (ReadOrderLoop:
; $FE transpose, $FF the channel's end with +$0D = 0, $80-$BF the repeat,
; $C0-$FD an instrument slot, below $80 the pattern via PatternAddrLow /
; PatternAddrHigh). Then the note's frames +$0C go down; while the note lasts,
; a command byte at the pointer is done at once (PatternCommand); at 0,
; PatternCommand for each command, then the note: $7F a rest (only the frames),
; $7E a period word, else index + $0A + 12 into Periods (+$0E keeps it). The
; frames go to +$0C, the ornament state +$14 = ornament | $C0, and StartVoice
; runs with the instrument +7/+8, the period, the frames as sustain; not when
; the voice's flags have bit 7.
;
; 30 180 runs in the 9 builds; the order list 499, a new pattern 99, a note
; 2292, a rest 41 (l1q, 10 builds with sec-l1-s8). The slot command and the $7E
; period are not executed in any recording.
;
; Witness: L1 32775 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
SequenceChannel:
  CALL UpdateOrnament
  LD A,(IY+$0B)
  AND A
  JR Z,ContinuePattern
PatternEnded:
  DEC (IY+$09)            ; once more, or the order list
  JR Z,ReadOrderList
  LD A,(IY+$03)
  LD (IY+$05),A
  LD A,(IY+$04)
  LD (IY+$06),A
  LD (IY+$0B),$00
  JR ContinuePattern
ReadOrderList:
  LD (IY+$09),$01         ; +9 = 1
  LD L,(IY+$01)
  LD H,(IY+$02)
ReadOrderLoop:
  LD A,(HL)
  CP $80
  JR C,OrderPattern
  CP $FE
  JR NZ,OrderNotTranspose
  INC HL
  LD A,(HL)
  LD (IY+$0A),A
  INC HL
  JP ReadOrderLoop
OrderNotTranspose:
  CP $FF
  JR NZ,OrderNotEnd
  XOR A
  LD (IY+$0D),A
  RET
OrderNotEnd:
  CP $C0
  JR NC,OrderSetSlot
  AND $1F
  LD (IY+$09),A
  INC HL
  JP ReadOrderLoop
OrderSetSlot:
  AND $07                 ; $C0-$FD v: slot (bits 0-2) = v (not executed in any
                          ; recording)
  ADD A,(IY+$00)
  LD DE,InstrumentSlots
  ADD A,E
  LD E,A
  JR NC,OrderSlotStore
  INC D
OrderSlotStore:
  INC HL
  LDI
  JP ReadOrderLoop
OrderPattern:
  LD (IY+$0B),$00         ; a pattern number
  INC HL
  LD (IY+$01),L
  LD (IY+$02),H
  LD C,A
  LD B,$00
  LD HL,PatternAddrLow
  ADD HL,BC
  LD E,(HL)
  LD HL,PatternAddrHigh
  ADD HL,BC
  LD D,(HL)
  LD (IY+$03),E
  LD (IY+$04),D
  JR CountNote
ContinuePattern:
  LD E,(IY+$05)
  LD D,(IY+$06)
CountNote:
  DEC (IY+$0C)
  JR Z,ReadPatternLoop
  LD A,(DE)
  CP $80
  CALL NC,PatternCommand
  LD (IY+$05),E
  LD (IY+$06),D
  RET
ReadPatternLoop:
  LD A,(DE)               ; the note has ended: commands, then a note or a rest
  CP $80
  JR C,PatternNote
  CALL PatternCommand
  LD A,(IY+$0B)
  AND A
  JR Z,ReadPatternLoop
  JP PatternEnded
PatternNote:
  CP $7F
  JR Z,PatternRest
  CP $7E
  JR NZ,PatternPitchedNote
  INC DE
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  JP PatternNoteStart
PatternPitchedNote:
  ADD A,(IY+$0A)          ; index = note + transpose + 12
  ADD A,$0C
  LD (IY+$0E),A
  LD HL,Periods
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
PatternNoteStart:
  LD A,(IY+$0F)           ; HL = the period
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
  JP StartVoice
PatternRest:
  INC DE                  ; $7F: only the frames
  LD A,(DE)
  INC DE
  LD (IY+$0C),A
  LD (IY+$05),E
  LD (IY+$06),D
  RET

; Do the pattern command at DE: instrument, ornament, end, or a skipped command
;
; $80-$87: the instrument +7/+8 = Instruments + InstrumentSlots[+0 + bits 0-2];
; $88-$BF: the ornament +$0F = bits 0-3; $FF: +$0B = $FF (the pattern has
; ended; DE stays); $C0-$FE: skipped, $C2 one byte, the others four. DE moves
; past the command. 336 runs in the 9 builds; $88 and up 208, the ornaments 7
; (l1q, 10 builds with sec-l1-s8); the skip is not executed in any recording.
;
; Witness: L1 360 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
PatternCommand:
  LD A,(DE)
  CP $88
  JR NC,PatternCommandHigh
  AND $07
  ADD A,(IY+$00)
  LD C,A
  LD B,$00
  LD HL,InstrumentSlots
  ADD HL,BC
  LD C,(HL)
  LD HL,Instruments
  ADD HL,BC
  LD (IY+$07),L
  LD (IY+$08),H
  INC DE
  RET
PatternCommandHigh:
  CP $FF
  JR NZ,PatternCommandNotEnd
  LD (IY+$0B),$FF
  RET
PatternCommandNotEnd:
  CP $C0
  JR NC,PatternCommandSkip
  AND $0F
  LD (IY+$0F),A
  INC DE
  RET
PatternCommandSkip:
  INC DE                  ; not executed in any recording
  CP $C2
  RET Z
  INC DE
  INC DE
  INC DE
  RET

; One frame of channel IY's ornament: the next semitone step into voice IX's
; period
;
; Nothing when the voice's flags have bit 7 or the state +$14 has bit 7 clear;
; number 0 clears bit 7. At the start (bit 6) and whenever the steps +$13 run
; out, OrnamentStart: the record at $C4A8 + 8 n (Ornaments), +$12 = its bits
; 3-5, +$13 = bits 0-2 + 1, the pointer at it, the period of the note itself;
; an ornament without bit 7 holds its last step instead of starting again. Each
; time the step's frames +$12 run out: the next step, +$12 = its bits 0-2, the
; period of +$0E + its bits 3-7 (SetPitch). 30 180 runs in the 9 builds; a step
; 2531, a start 1312 (l1q, 10 builds with sec-l1-s8).
;
; Witness: L1 32775 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, sec-l1-s8, c1, load-l2-load-l5).
UpdateOrnament:
  BIT 7,(IX+$11)
  RET NZ
  LD A,(IY+$14)
  BIT 7,A
  RET Z
  AND $3F
  JR NZ,OrnamentRunning
  RES 7,(IY+$14)
  RET
OrnamentRunning:
  LD D,$07                ; D = 7: the mask, and the high byte added at
                          ; OrnamentStart
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
  JP NZ,OrnamentStep
  INC H
  LD (IY+$11),H
OrnamentStep:
  LD A,(HL)
  AND D
  LD (IY+$12),A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,(IY+$0E)
  JP SetPitch
OrnamentStart:
  LD HL,Ornaments-8-7*256           ; HL = $BDA8 + $0700 (D) + 8 n = $C4A8 + 8
                                    ; n
  LD A,(IY+$14)
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  ADD HL,DE
  BIT 7,(HL)
  JR NZ,OrnamentRestart
  BIT 6,(IY+$14)
  JR NZ,OrnamentRestart
  LD (IY+$13),$01
  RET
OrnamentRestart:
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
SetPitch:
  ADD A,A                 ; voice IX's period = Periods[A] (the source's
                          ; SETPITCH)
  LD HL,Periods
  ADD A,L
  LD L,A
  JR NC,SetPitchStore
  INC H
SetPitchStore:
  LD A,(HL)
  LD (IX+$03),A
  INC HL
  LD A,(HL)
  LD (IX+$04),A
  RET
