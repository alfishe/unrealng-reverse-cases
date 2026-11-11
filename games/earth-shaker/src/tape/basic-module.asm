; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: line 10, which sets the colours, clears RAMTOP below the game, prints the title, loads the CODE block and enters the menu
;
; TZX block 11 holds the program "EARTH" (header, TZX block 10: LINE 1, program length 107, no variables). The one
; line is 10 INK 7: PAPER 0: BORDER 0: CLEAR 27000: PRINT AT 0,0;"EARTH SHAKER by M.BATTY": LOAD "" CODE : RANDOMIZE
; USR 35616. Every number is its digits, then the number marker $0E and the five-byte small-integer form the ROM
; reads. LINE 1 starts the program at the first line at or after 1, line 10.
;
; c1: the ROM loads the block at signal speed and runs the line at once; the game's code runs first at frame 11 225,
; the menu (WALKTHROUGH 1).
; --------------------------------------------------------------------------------------------------------------------

; BASIC line 10: INK 7: PAPER 0: BORDER 0: CLEAR 27000: PRINT AT 0,0;"EARTH
; SHAKER by M.BATTY": LOAD "" CODE : RANDOMIZE USR 35616
;
; The whole program (the header's program length 107 covers it all): the line
; number 10 (two bytes, high byte first), the line's length (103, low byte
; first), then eight statements split by ":" ($3A) and closed by ENTER ($0D).
;
; CLEAR 27000 puts RAMTOP at $6978, below the game block (ScrollerText $6D42,
; src/game), so the machine stack sits under the game. LOAD "" CODE loads the
; next file, TZX blocks 12 and 13, at the address its header names, $6D42.
; RANDOMIZE USR 35616 calls $8B20 (GameEntry in src/game), which never returns.
BasicLine10:
  DEFB $00,$0A
  DEFB $67,$00            ; the line's length, 103
  DEFB $D9,$37            ; INK ($D9) "7"
  DEFB $0E,$00,$00,$07,$00,$00 ; $0E and 7
  DEFB $3A,$DA,$30        ; ":" PAPER ($DA) "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$E7,$30        ; ":" BORDER ($E7) "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$FD,$32,$37,$30,$30,$30 ; ":" CLEAR ($FD) "27000"
  DEFB $0E,$00,$00,$78,$69,$00 ; $0E and 27000 = $6978 as a small integer (0,
                               ; 0, low, high, 0)
  DEFB $3A,$F5,$AC,$30    ; ":" PRINT ($F5) AT ($AC) "0"
  DEFB $0E,$00,$00,$00,$00,$00,$2C,$30 ; $0E and 0, then "," and "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3B,$22,$45,$41,$52,$54,$48,$20 ; ";" and the string "EARTH SHAKER by
  DEFB $53,$48,$41,$4B,$45,$52,$20,$62 ; M.BATTY"
  DEFB $79,$20,$4D,$2E,$42,$41,$54,$54
  DEFB $59,$22
  DEFB $3A,$EF,$22,$22,$AF ; ":" LOAD ($EF) "" CODE ($AF)
  DEFB $3A,$F9,$C0,$33,$35,$36,$31,$36 ; ":" RANDOMIZE ($F9) USR ($C0) "35616"
  DEFB $0E,$00,$00,$20,$8B,$00 ; $0E and 35616 = $8B20
  DEFB $0D                ; ENTER
