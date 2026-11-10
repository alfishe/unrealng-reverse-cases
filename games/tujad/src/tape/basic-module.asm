; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: line 10, which clears the screen black, loads the CODE block and calls its stub
;
; Tape block 2 holds the program "TUJAD" (header: LINE 10, program length 88, no variables). The one line is CLEAR
; 24767: PAPER 0: INK 0: POKE 23624,0: CLS : LOAD "" CODE 16384: RANDOMIZE USR 23296. Every number is its digits, then
; the number marker $0E and the five-byte small-integer form the ROM reads.
;
; c1: the ROM loads the block at signal speed and runs the line at once (LINE 10); the stub at $5B00 is entered at
; frame 2908, T 8352 (WALKTHROUGH 1).
; --------------------------------------------------------------------------------------------------------------------

; BASIC line 10: CLEAR 24767: PAPER 0: INK 0: POKE 23624,0: CLS : LOAD "" CODE
; 16384: RANDOMIZE USR 23296
;
; The whole program (the header's program length 88 covers it all): the line
; number 10 (two bytes, high byte first), the line's length (84, low byte
; first), then seven statements split by ":" ($3A) and closed by ENTER ($0D).
;
; CLEAR 24767 puts RAMTOP at $60BF, one byte below the game block (GameStart
; $60C0, src/game). PAPER 0 and INK 0 make the next CLS black on black, POKE
; 23624,0 sets BORDCR (a black border and a black lower screen), so the picture
; loads into a black screen. LOAD "" CODE 16384 loads the next file, tape
; blocks 3 and 4, at $4000 (the header's own start, 32768, is overridden): the
; loading screen and the 32-byte stub at $5B00. RANDOMIZE USR 23296 calls the
; stub (StubLoad $5B00 in src/screen), which never returns.
BasicLine10:
  DEFB $00,$0A
  DEFB $54,$00            ; the line's length, 84
  DEFB $FD,$32,$34,$37,$36,$37 ; CLEAR ($FD) "24767"
  DEFB $0E,$00,$00,$BF,$60,$00 ; $0E and 24767 = $60BF as a small integer (0,
                               ; 0, low, high, 0)
  DEFB $3A,$DA,$30        ; ":" PAPER ($DA) "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$D9,$30        ; ":" INK ($D9) "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$F4,$32,$33,$36,$32,$34 ; ":" POKE ($F4) "23624"
  DEFB $0E,$00,$00,$48,$5C,$00,$2C,$30 ; $0E and 23624 = $5C48 (BORDCR), then
                                       ; "," and "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$FB            ; ":" CLS ($FB)
  DEFB $3A,$EF,$22,$22,$AF,$31,$36,$33 ; ":" LOAD ($EF) "" CODE ($AF) "16384"
  DEFB $38,$34
  DEFB $0E,$00,$00,$00,$40,$00 ; $0E and 16384 = $4000
  DEFB $3A,$F9,$C0,$32,$33,$32,$39,$36 ; ":" RANDOMIZE ($F9) USR ($C0) "23296"
  DEFB $0E,$00,$00,$00,$5B,$00 ; $0E and 23296 = $5B00
  DEFB $0D                ; ENTER
