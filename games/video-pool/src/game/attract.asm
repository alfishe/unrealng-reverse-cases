; --------------------------------------------------------------------------------------------------------------------
; attract.asm: The attract sequence's letters: OCP turning into POOL, "video" sliding in
;
; LogoFlip $BB13 turns the banner's letters about their vertical axes: in 20 steps the O, C and P (gaps in the magenta
; stripes) narrow to nothing, then in 20 steps P, O, O, L widen in their place. Each letter is a list of edges per
; stripe row (FlipLetterO $BB98 and the next three); FlipEdge $BC11 XORs only the strip between an edge's width at
; this step and at the next one, taken from the cosine tables FlipWidths16 $BC74 / FlipWidths24 $BC89.
;
; VideoSlideIn $BC9E prints "video" above the banner with the font $DEF4 doubled in width (16 pixels a letter), each
; letter scrolling into its cell 2 pixels a step.
; --------------------------------------------------------------------------------------------------------------------

; Turn the banner's OCP into POOL: 20 steps narrowing O, C, P, then 20 steps
; widening P, O, O, L
;
; Step C 0-19 with B = 0: FlipLetter $BB74 for O at x 63, C at x 127, P at x
; 191 (line 47, DE = $2F3F / $2F7F / $2FBF), one frame each (PresentsFrame
; $B91B). Then C 20 down to 1 with B = 1 (widening): P at x 41, O at 101, O at
; 161, L at 221.
;
; Witness (l1sum.py BB13 BB17 BB42): once per presents page; game 6051-6059 (7
; narrowing steps, then the key), w1 2 runs (494- and 16 323), m1 3 runs of 20
; + 20 steps (494-4055). WALKTHROUGH 6.1: m1 frame 300 shows OCP, frame 900
; POOL.
LogoFlip:
  LD B,$00
  LD C,$00
FlipNarrowLoop:
  CALL PresentsFrame      ; O C P narrowing, C = 0..19
  LD DE,$2F3F
  LD IX,FlipLetterO
  CALL FlipLetter
  LD DE,$2F7F
  LD IX,FlipLetterC
  CALL FlipLetter
  LD DE,$2FBF
  LD IX,FlipLetterP
  CALL FlipLetter
  INC C
  LD A,C
  CP $14
  JR NZ,FlipNarrowLoop
  LD B,$01
  LD C,$14
FlipWidenLoop:
  CALL PresentsFrame      ; P O O L widening, C = 20..1
  LD DE,$2F29
  LD IX,FlipLetterP
  CALL FlipLetter
  LD DE,$2F65
  LD IX,FlipLetterO
  CALL FlipLetter
  LD DE,$2FA1
  LD IX,FlipLetterO
  CALL FlipLetter
  LD DE,$2FDD
  LD IX,FlipLetterL
  CALL FlipLetter
  DEC C
  LD A,C
  CP $00
  JR NZ,FlipWidenLoop
  RET

; One step of one letter: FlipEdge for each edge record of the list at IX,
; relative to D (line), E (x centre)
;
; IX = a letter's list of 3-byte records (dx, dy, kind) ending $FF; B = the
; phase (0 narrowing, 1 widening), C = the step. For each record: E + dx, D +
; dy and kind + phase go to FlipEdge $BC11. Registers kept but IX. game 210
; records, m1 4800.
FlipLetter:
  LD A,(IX+$00)
  CP $FF
  RET Z
  PUSH BC
  PUSH DE
  LD A,E
  ADD A,(IX+$00)
  LD E,A
  LD A,D
  ADD A,(IX+$01)
  LD D,A
  LD A,(IX+$02)
  ADD A,B
  LD B,A
  CALL FlipEdge
  INC IX
  INC IX
  INC IX
  POP DE
  POP BC
  JR FlipLetter

; The letter O: 12 edge records (dx, dy, kind), $FF
;
; Each letter: per stripe row (dy 0, 8, ... 40, the six stripe pairs) a record
; for the left edge (dx 0) and one for the right edge (dx 1, kind bit 1 set).
; Kind: bit 1 = the right edge, bit 2 = the 24-pixel width table, bit 3 = both
; tables (two edges drawn, 16 and 24); bit 0 is the phase LogoFlip adds. Read
; by FlipLetter $BB74: all 121 bytes in w1 and m1 (game, f1, p2, v1 stop at the
; key during the narrowing, so the L is never read there).
FlipLetterO:
  INCBIN "res/graphics/FlipLetters.bin",$0000,37
FlipLetterC:
  INCBIN "res/graphics/FlipLetters.bin",$0025,31
FlipLetterP:
  INCBIN "res/graphics/FlipLetters.bin",$0044,31
FlipLetterL:
  INCBIN "res/graphics/FlipLetters.bin",$0063,22

; XOR the strip an edge moves by between step C and the next on four lines
; (D-2, D-1, D+2, D+3)
;
; E = the letter's centre x, D = the stripe line, B = kind + phase, C = the
; step. Bit 3 of B: both widths (FlipEdge again with bit 2 set, then clear).
; Otherwise the width w = FlipWidths16 $BC74 [C] (or FlipWidths24 $BC89 with
; bit 2), compared with the entry after it (phase 0) or before it (phase 1); no
; change, nothing drawn. The strip of |difference| pixels is placed left (bit 1
; clear) or right of the centre at the edge's position and XORed by the span
; routine $93B3 (B = length) on the lines D-2, D-1, D+2 and D+3: the two
; two-line stripes of one letter row.
;
; Witness: game 432 calls, w1 3628, m1 10 020 (6052-4055).
FlipEdge:
  BIT 3,B
  JR NZ,FlipEdgeBoth
  BIT 2,B
  JR NZ,FlipEdgeWide
  LD HL,FlipWidths16
  JR FlipEdgeStep
FlipEdgeWide:
  LD HL,FlipWidths24      ; bit 2: the 24-pixel table
FlipEdgeStep:
  LD A,B
  LD B,$00
  ADD HL,BC
  LD B,A
  LD A,(HL)
  BIT 0,B
  JR NZ,FlipEdgeWiden
  INC HL
  JR FlipEdgeCompare
FlipEdgeWiden:
  DEC HL                  ; phase 1: compare with the entry before
FlipEdgeCompare:
  CP (HL)
  RET Z
  PUSH AF
  SUB (HL)
  JR NC,FlipEdgeWidth
  NEG
FlipEdgeWidth:
  LD C,A
  POP AF
  BIT 1,B
  JR NZ,FlipEdgeRight
  DEC A
  BIT 0,B
  JR Z,FlipEdgeLeft
  ADD A,C
FlipEdgeLeft:
  NEG
  JR FlipEdgeXor
FlipEdgeRight:
  BIT 0,B
  JR NZ,FlipEdgeXor
  SUB C
FlipEdgeXor:
  ADD A,E
  LD E,A
  LD B,C
  DEC D
  DEC D
  CALL XorLine
  INC D
  CALL XorLine
  INC D
  INC D
  INC D
  CALL XorLine
  INC D
  CALL XorLine
  RET
FlipEdgeBoth:
  RES 3,B                 ; bit 3: both tables
  SET 2,B
  PUSH BC
  PUSH DE
  CALL FlipEdge
  POP DE
  POP BC
  RES 2,B
  CALL FlipEdge
  RET

; Half-widths of a turning letter: 16 cos(4.5 k) for k = 0..20 (16 ... 1, 0)
;
; 21 bytes 16, 16, 16, 16, 15, 15, 14, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3,
; 1, 0: the projected half-width of a 16-pixel half letter turned by 4.5
; degrees a step (16 cos 45 = 11.3, entry 10 = 11). Read by FlipEdge $BC11; all
; in w1 and m1.
FlipWidths16:
  INCBIN "res/tables/FlipWidths.bin",$0000,21
FlipWidths24:
  INCBIN "res/tables/FlipWidths.bin",$0015,21

; Print "video" above the banner, letters 16 pixels wide sliding into their
; cells 2 pixels a step
;
; Eight steps C = 7..0, three frames each (PresentsFrame $B91B). Each step
; prints the five letters of VideoText $BD04 at line 24 ($18), x 8 + 24 i: each
; font row (Font $DEF4, letter - 'a') doubled to 16 bits, shifted left by 2 C
; bits, written as two screen bytes over the old ones (no XOR), so each letter
; enters its cell from the right.
;
; Witness (l1sum.py BC9E BCA0): w1 once (16 323-16 347), m1 three times
; (581-4079); in game, f1, p2, v1 a key came first.
VideoSlideIn:
  LD C,$07
VideoStepLoop:
  LD B,$03                ; C = 7..0
VideoStepWait:
  CALL PresentsFrame      ; three frames
  DJNZ VideoStepWait
  LD H,$18
  LD L,$08
  CALL PresentsPixelAddress
  LD DE,VideoText
  LD B,$05
VideoCharLoop:
  PUSH BC                 ; five letters
  PUSH DE
  LD A,(DE)
  SUB $61
  PUSH HL
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Font
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH HL
  LD B,$08
VideoLineLoop:
  PUSH BC                 ; eight lines
  LD A,(DE)
  PUSH DE
  LD DE,$0000
  LD B,$08
VideoDoubleLoop:
  RLCA                    ; each bit twice
  PUSH AF
  RL E
  RL D
  POP AF
  RL E
  RL D
  DJNZ VideoDoubleLoop
  LD B,C
  LD A,B
  OR A
  JR Z,VideoStore
VideoShiftLoop:
  SLA E                   ; shift left 2 C bits
  RL D
  SLA E
  RL D
  DJNZ VideoShiftLoop
VideoStore:
  LD (HL),D
  INC HL
  LD (HL),E
  DEC HL
  INC H
  POP DE
  INC DE
  POP BC
  DJNZ VideoLineLoop
  POP HL
  INC HL
  INC HL
  INC HL
  POP DE
  INC DE
  POP BC
  DJNZ VideoCharLoop
  DEC C
  JP P,VideoStepLoop
  RET

; "video", the five letters of VideoSlideIn
;
; Read by VideoSlideIn $BC9E (w1, m1).
VideoText:
  INCBIN "res/text/VideoText.bin",$0000,5

; SP at PresentsPage's entry: PresentsAbort $B931 reloads it (written and read
; once in every build)
PresentsSP:
  DEFB $00,$00
PresentsDone:
  DEFB $00                ; 0 while GameStart $8000's first presents page runs
                          ; ($8006), $FF after it ($800E): PresentsPage then
                          ; also calls $A8FD (read twice in m1, both 0)
