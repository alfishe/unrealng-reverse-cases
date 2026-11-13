; --------------------------------------------------------------------------------------------------------------------
; reveal.asm: The edge loop's task: the attribute reveal, then the countdown
;
; LoadStream's bit loop calls the routine whose address is the operand of the CALL at $FDCF (BitHook) once a bit,
; between the two edges of the bit. It works in the alternate registers and ends by jumping to EdgeWait, so its time
; is part of the bit's timing window. Three tasks follow each other: AttrRevealStart pads the time while AttrRevealOff
; is 0 (the bitmap loads), then (with the attributes loaded) sets up AttrReveal, which copies 12 attribute bytes a
; call from AttrBuffer to the screen, 64 calls; then CountdownTask draws and counts down the four digits at character
; row 20, columns 13-18.
; --------------------------------------------------------------------------------------------------------------------

  ORG $FC0D

; The first task: wait while AttrRevealOff is 0, then point BitHook at
; AttrReveal
;
; Entered from BitHook (and from the second stage's original end on a failure).
; AttrRevealOff = 0: pad the time (DJNZ of 12) and go to EdgeWait. Else BitHook
; := AttrReveal, HL' = AttrBuffer, DE' = Attributes, A' = $41 (64 calls and the
; switch), and go on through the same delay.
;
; Witness: L1 56665 (c1).
AttrRevealStart:
  EXX
  EX AF,AF'
  LD A,(AttrRevealOff)
  CP $00
  LD B,$0C
  JR Z,AttrRevealPad
  LD HL,AttrReveal
  LD (BitHook+$0001),HL
  LD HL,AttrBuffer
  LD DE,Attributes
  LD A,$41
  LD B,$09
AttrRevealDelay:
  DJNZ AttrRevealDelay    ; DJNZ: the time a call takes
  EX AF,AF'
  EXX
  JP EdgeWait
AttrRevealPad:
  NOP                     ; AttrRevealOff = 0: one NOP more, the same time as
                          ; the set-up
  JR AttrRevealDelay
AttrReveal:
  EXX                     ; The second task: copy 12 attribute bytes from
                          ; AttrBuffer to the screen; after 64 calls,
                          ; CountdownStart
  EX AF,AF'
  DEC A
  JR Z,CountdownStart
  EX AF,AF'
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  NOP
  EXX
  JP EdgeWait
CountdownStart:
  LD A,$01                ; BitHook := CountdownTask; border mask 0 and OR 8 at
                          ; EdgeBorderMask (the border black from now)
  EX AF,AF'
  LD HL,CountdownTask
  LD (BitHook+$0001),HL
  XOR A
  LD (EdgeBorderMask+$0001),A
  LD A,$08
  LD (EdgeBorderMask+$0003),A
  LD B,$08
  LD B,$08
  LD B,$08
CountdownStartDelay:
  DJNZ CountdownStartDelay ; DJNZ: the time
  EXX
  JP EdgeWait

; The third task: draw the four countdown digits, count the time down,
; decrement the counter
;
; A' is the phase. $9C-$98: draw the digits, one glyph's 4 rows a call (C'
; calls a digit), from CountdownDigits (src/loader/sl1.asm, $FF80 + 8 x digit,
; the glyph pointers at CountdownCounter) to the screen: the last digit at
; $5092, the others 2, 3 and 5 columns left of it; below $98 A' counts the
; calls down to 0, each padded to the same time; at 0, A' := $9C and the
; counter goes down by one: the last two digits wrap from 0 to 9, the second
; from 0 to 5 ($FCD9-$FD00). It starts at 0 2 1 1 (pointers $80 $90 $88 $88).
; c1: the counter moved 212 times.
;
; Witness: L1 34614 (c1).
CountdownTask:
  EXX
  EX AF,AF'
  CP $98
  JR C,CountdownPhase
  DEC C
  JR Z,CountdownNextDigit
  EX AF,AF'
  LD B,$04
CountdownRow:
  LD A,(HL)               ; one glyph row to the screen, 4 rows
  LD (DE),A
  INC HL
  INC D
  DJNZ CountdownRow
  NOP
  LD B,$01
  JR CountdownPadDelay
CountdownNextDigit:
  DEC A                   ; the next digit: its pointer and screen cell from A'
  CP $98
  JR C,CountdownPadLong
  LD C,$03
  LD HL,CountdownCounter+$0003
  LD DE,Screen+4242
  LD B,$08
  JR Z,CountdownDigitDelay
  DEC HL
  DEC E
  DEC E
  NOP
  NOP
  LD B,$05
  CP $99
  JR Z,CountdownDigitDelay
  DEC HL
  DEC E
  NOP
  LD B,$03
  CP $9A
  JR Z,CountdownDigitDelay
  DEC HL
  DEC E
  DEC E
  NOP
  NOP
  LD B,$01
CountdownDigitDelay:
  DJNZ CountdownDigitDelay ; DJNZ: the same time for each digit
  LD L,(HL)
  LD H,$FF
  EX AF,AF'
  EXX
  JP EdgeWait
CountdownPad:
  LD B,$0D                ; the calls between two draws: only the time
CountdownPadSwap:
  EX AF,AF'
CountdownPadDelay:
  DJNZ CountdownPadDelay
  EXX
  JP EdgeWait
CountdownPadLong:
  LD B,$0B
  JR CountdownPadSwap
CountdownTick:
  LD (HL),A               ; a digit that did not wrap: store it
CountdownTickDelay:
  DJNZ CountdownTickDelay ; DJNZ: the same time whatever wrapped
  JR CountdownStore
CountdownTickPad:
  NOP
  NOP
  JR CountdownStore
CountdownPhase:
  DEC A                   ; A' below $98: count it down; at 0 the counter ticks
  JR NZ,CountdownPad
  LD A,$9C
  EX AF,AF'
  LD HL,CountdownCounter+$0003
  LD DE,$78F8
  LD A,E
  ADD A,(HL)
  CP D
  LD B,$07
  JR NZ,CountdownTick
  LD (HL),$C8
  DEC HL
  LD A,E
  ADD A,(HL)
  CP D
  LD B,$04
  JR NZ,CountdownTickDelay
  LD (HL),$C8
  DEC HL
  LD A,E
  ADD A,(HL)
  CP D
  JR NZ,CountdownTickPad
  LD (HL),$A8
  DEC HL
  LD A,E
  ADD A,(HL)
CountdownStore:
  LD (HL),A               ; the last digit touched, then C' := 1 and EdgeWait
  LD C,$01
  EXX
  JP EdgeWait

; The four digits as pointers' low bytes into CountdownDigits ($80 = 0, $C8 =
; 9)
;
; Read and written by CountdownTask (c1: 212 decrements). Initially 0 2 1 1.
CountdownCounter:
  DEFB $80,$90,$88,$88
