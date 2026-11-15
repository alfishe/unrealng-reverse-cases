; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: line 10, CLEAR 24570, load the loader, run it
;
; Tape block 2 holds the program "MASK3" (header block 1: LINE 0, program length 36, no variables). Its one line is 10
; CLEAR 24570: LOAD "" CODE : RANDOMIZE USR 65280. Every number is its digits, then the number marker $0E and the
; five-byte small-integer form the ROM reads. The header's LINE 0 is below the first line, so the program runs from
; line 10 at once.
;
; c1: the ROM loads the block and runs the line; LOAD "" CODE takes the header "loader" (block 3) and its 256 bytes at
; $FF00 (block 4, src/loader), and USR 65280 calls LoaderStart $FF00.
; --------------------------------------------------------------------------------------------------------------------

; BASIC line 10: CLEAR 24570: LOAD "" CODE : RANDOMIZE USR 65280
;
; The whole program (the header's program length 36 covers it all): the line
; number 10 (two bytes, high byte first), the line's length (32, low byte
; first), then three statements split by ":" ($3A) and closed by ENTER ($0D).
;
; CLEAR 24570 puts RAMTOP at $5FFA, just under the game's block at $6000 (TZX
; block 6), so the ROM's stack and the GO SUB stack stay out of the way of the
; load. LOAD "" CODE loads the next CODE file at the address its header gives,
; $FF00 (the loader). RANDOMIZE USR 65280 calls it; it never returns.
BasicLine10:
  DEFB $00,$0A
  DEFB $20,$00            ; the line's length, 32
  DEFB $FD,$32,$34,$35,$37,$30 ; CLEAR ($FD) "24570"
  DEFB $0E,$00,$00,$FA,$5F,$00 ; $0E and 24570 = $5FFA
  DEFB $3A,$EF,$22,$22,$AF ; ":" LOAD ($EF) "" CODE ($AF)
  DEFB $3A,$F9,$C0,$36,$35,$32,$38,$30 ; ":" RANDOMIZE ($F9) USR ($C0) "65280"
  DEFB $0E,$00,$00,$00,$FF,$00 ; $0E and 65280 = $FF00
  DEFB $0D                ; ENTER
