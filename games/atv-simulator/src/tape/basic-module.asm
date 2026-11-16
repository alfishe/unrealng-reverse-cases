; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC loader: CLEAR, LOAD ""CODE, RANDOMIZE USR into the machine-code loader
;
; Three lines, as LIST shows them: 10 CLEAR 25400, 20 LOAD ""CODE, 30 RANDOMIZE USR 65500. CLEAR puts RAMTOP at $6338
; (25400), the first byte of the game; LOAD ""CODE reads tape blocks 2 and 3, the loader, to $FFDC; RANDOMIZE USR
; 65500 enters it. Every number is written as the ROM writes it: its digits, then $0E and the five-byte form (a small
; integer: 0, 0, the value low byte first, 0). No machine code reads these bytes; the ROM's interpreter does.
; --------------------------------------------------------------------------------------------------------------------

; Line 10: CLEAR 25400
;
; The line number high byte first (0, 10), the length low byte first (13), the
; token CLEAR ($FD), the digits "25400", $0E and the number 25400 ($6338) in
; the ROM's small-integer form, $0D. Read by the ROM's interpreter in c1.
BasicLine10:
  DEFB $00,$0A,$0D,$00,$FD,$32,$35,$34
  DEFB $30,$30,$0E,$00,$00,$38,$63,$00
  DEFB $0D

; Line 20: LOAD ""CODE
;
; Line 20 (0, 20), length 5: LOAD ($EF), two quotes (the empty name), CODE
; ($AF), $0D. The ROM loads the next CODE block to the address its header
; gives, $FFDC (tape blocks 2 and 3).
BasicLine20:
  DEFB $00,$14,$05,$00,$EF,$22,$22,$AF
  DEFB $0D

; Line 30: RANDOMIZE USR 65500
;
; Line 30 (0, 30), length 14: RANDOMIZE ($F9), USR ($C0), "65500", $0E and
; 65500 ($FFDC) in the small-integer form, $0D. USR calls the loader at $FFDC
; (c1, frame 1017).
BasicLine30:
  DEFB $00,$1E,$0E,$00,$F9,$C0,$36,$35
  DEFB $35,$30,$30,$0E,$00,$00,$DC,$FF
  DEFB $00,$0D
