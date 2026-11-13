; --------------------------------------------------------------------------------------------------------------------
; basic.asm: The BASIC: line 0, whose USR enters the code after the program
;
; The program is one line, numbered 0 and auto-run: RANDOMIZE USR (PEEK 23641+256*PEEK 23642+4) as LIST shows it,
; whose hidden five-byte numbers are 23635 (PROG), 23636 and 58: USR (PROG + 58) = $5D05. The digits are a decoy:
; 23641/23642 is E_LINE, so a reader of the listing would look for the code at E_LINE + 4.
;
; The line has no ENTER ($00 instead) and a length field of 923: USR is evaluated before the ROM looks for the
; statement's end, and the code never returns, so neither is ever read. The header says 384 bytes with a program of
; 52: the other 332 bytes are the program's "variables" (VARS = $5CFF), six unused bytes, the code at $5D05 and the
; first stage.
; --------------------------------------------------------------------------------------------------------------------

; Line 0: RANDOMIZE USR (PEEK 23641+256*PEEK 23642+4), the hidden numbers
; 23635, 256, 23636, 58
;
; PEEK PROG + 256 x PEEK (PROG + 1) = `$5CCB`, the line's own address; + 58 =
; `$5D05`, the code after the program. Each number's digits are followed by
; `$0E` and the five-byte form the ROM uses; three of the four differ from the
; digits.
;
; c1: the ROM runs the line after the load and USR enters `$5D05` with BC =
; `$5D05`.
BasicLine0:
  DEFB $00,$00            ; the line number, 0 (high byte first)
  DEFB $9B,$03            ; the line's length, 923: wrong, never read (the line
                          ; never ends)
  DEFB $F9,$C0,$28,$BE    ; RANDOMIZE ($F9) USR ($C0) "(" PEEK ($BE)
  DEFB $32,$33,$36,$34,$31,$0E,$00,$00 ; "23641", $0E and 23635 = $5C53 (PROG)
  DEFB $53,$5C,$00
  DEFB $2B,$32,$35,$36,$0E,$00,$00,$00 ; "+" "256", $0E and 256
  DEFB $01,$00
  DEFB $2A,$BE,$32,$33,$36,$34,$32,$0E ; "*" PEEK "23642", $0E and 23636 =
  DEFB $00,$00,$54,$5C,$00             ; $5C54
  DEFB $2B,$34,$0E,$00,$00,$3A,$00,$00 ; "+" "4", $0E and 58
  DEFB $29,$00            ; ")", then $00 where ENTER would be

; Six bytes between the program and the code: VARS points here, nothing reads
; them
;
; The first bytes of the program's "variables" area. No code of the load reads
; them (c1).
BasicGap:
  DEFB $00,$12,$00,$00,$00,$00

; USR's code: copy the loader's first stage ($134 bytes from $5D17) to $B626
; and run it
;
; Entered by USR with BC = `$5D05`, the routine's own address: HL = BC + `$12`
; = `$5D17`, wherever the program was loaded. SP = `$5C00`, the stack below the
; main block's load address (the stack stays there to the end of the load).
; LDIR `$134` bytes to `$B626-$B759` and `JP $B65B` (Loader1Start). Interrupts
; are still on: Loader1Start turns them off after clearing the screen.
;
; Witness: L1 1 (c1).
BasicCode:
  LD HL,$0012
  ADD HL,BC               ; HL = USR's address + $12: the first stage's bytes
  LD DE,HookCount
  LD BC,$0134
  LD SP,$5C00
  LDIR
  JP Loader1Start
