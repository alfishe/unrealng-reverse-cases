; --------------------------------------------------------------------------------------------------------------------
; tune.asm: the title tune: two detuned square waves, the interrupts off
;
; TitleTune plays the tune of the credits page with the interrupts off: TuneOrder ($FF1C) lists 7 patterns (A A B A C
; C D), a pattern is note bytes and duration commands up to $FF. A command $C0+n sets the note length to n x 16 x 256
; loop passes (TuneDuration $B4AE, the low byte $B4AD stays 0); a note n takes the period p = TunePeriods[n] ($FF01)
; and runs two counters, p and p + 1 passes: each wrap toggles the speaker (both at once toggle it once), so one note
; sounds as two tones a pass apart, a slow beat. A pass is 81 T (uncontended code at $B486-$B49B), so the speaker, the
; XOR of the two counters, gives a pulse train at 3500000 / (81 p) Hz on a 48K (two pulses per counter period; the
; capture of docs 9.3 confirms it): from 179 Hz (p = 242, note 1) to 800 Hz (p = 54, note 26). The periods fall by
; about a semitone a step (notes 24 to 25 a whole tone); the patterns use notes 1, 2, 4, 6, 7, 9-14, 16-21, 23 and 25,
; never 3, 5, 8, 15, 22, 24 and 26 (src/res/music/titletune.tune.txt).
;
; Between notes it checks fire (TitleFireCheck $A748) and the keys 1-5 (half row $F7FE): either ends the tune and the
; credits page goes on to the menu. c1: 2 entries, 230 permille of the attract recording (269491882 T in the tune's
; own code). The text form: src/res/music/titletune.tune.txt (tools/res_tune.py).
; --------------------------------------------------------------------------------------------------------------------

; play the title tune until fire or a key 1-5
;
; DI; for each of the 7 patterns of TuneOrder: the notes until $FF, the length
; commands, the keys checked before each byte. EI and return. Called by
; CreditsPage ($B0BF). Reads $FF1C-$FFD3, TunePeriods, TuneDuration; ports: IN
; $F7FE, OUT $FE (bit 4 only: $00, $10).
TitleTune:
  DI
  LD HL,TuneOrder         ; TuneOrder: 7 pattern pointers
  LD B,$07
TunePattern:
  LD E,(HL)               ; DE = the pattern
  INC HL
  LD D,(HL)
  INC HL
TuneByte:
  EXX                     ; fire ends the tune
  CALL TitleFireCheck
  EXX
  JR C,TuneEnd
  LD A,$F7                ; the keys 1-5 end it too
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,TuneEnd
TuneRead:
  LD A,(DE)
  CP $FF
  JR Z,TuneNextPattern    ; $FF: the pattern's end
  INC DE
  CP $C0                  ; $C0+: a length
  JR C,TuneNote
  ADD A,A                 ; (cmd & 15) * 16: the passes' high byte
  ADD A,A
  ADD A,A
  ADD A,A
  LD (TuneDuration+$0001),A
  JR TuneRead
TuneNote:
  PUSH HL                 ; the note's period
  PUSH DE
  PUSH BC
  LD HL,TunePeriods
  LD E,A
  LD D,$00
  ADD HL,DE
  LD B,(HL)
  LD C,B                  ; the second counter one pass longer
  INC C
  LD DE,(TuneDuration)    ; DE = the length in passes
  LD H,B                  ; H, L: the two counters
  XOR A
TunePass:
  DEC H                   ; counter H: at 0 it reloads and toggles
  JR NZ,TuneCounterL
  OR $10
  LD H,B
TuneCounterL:
  DEC L                   ; counter L likewise
  JR NZ,TuneMix
  OR $10
  LD L,C
TuneMix:
  ADD A,$08               ; + 8 and AND $10: a wrap flips the speaker bit, A >>
                          ; 1 keeps it for the next pass
  AND $10
  OUT ($FE),A
  SRL A
  DEC E                   ; the length
  JR NZ,TunePass
  DEC D
  JR NZ,TunePass
  POP BC
  POP DE
  POP HL
  JR TuneByte
TuneNextPattern:
  DJNZ TunePattern
TuneEnd:
  EI
  RET

; AND A; RET and two zeros no code reaches
TuneSpare:
  DEFB $A7,$C9,$00,$00

; the note length in loop passes: the high byte set by the $C0+ commands, the
; low byte 0
TuneDuration:
  DEFW $0000
