; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC "RICK-II": black screen, CLEAR 65279, LOAD the loader, call it
;
; Four lines, auto-run from the first (the header's LINE 0, below line 10, starts at the program's start). PAPER 0,
; INK 0 and BORDER 0 make the screen black so the loading screen appears only when its attributes arrive; CLEAR 65279
; puts RAMTOP under $FF00, where LOAD ""CODE then reads the 256-byte "loader" block (header block 3: start 65280);
; RANDOMIZE USR 65280 enters it. The numbers carry their five-byte forms ($0E, then the small-integer form 0, sign,
; value, 0) as the ROM's editor writes them.
; --------------------------------------------------------------------------------------------------------------------

; Line 10: PAPER 0: INK 0: BORDER 0
;
; The line number 10 (high byte first), the length 27, then PAPER ($DA) "0" and
; its number 0, ":", INK ($D9) "0", ":", BORDER ($E7) "0", ENTER ($0D).
BasicLine10:
  DEFB $00,$0A,$1B,$00    ; the line number, 10, and the length, 27
  DEFB $DA,$30,$0E,$00,$00,$00,$00,$00 ; PAPER "0" and its hidden 0
  DEFB $3A,$D9,$30,$0E,$00,$00,$00,$00 ; ": INK 0"
  DEFB $00
  DEFB $3A,$E7,$30,$0E,$00,$00,$00,$00 ; ": BORDER 0" and ENTER
  DEFB $00,$0D

; Line 20: CLEAR 65279
;
; CLEAR ($FD) "65279" and its hidden number $FEFF: RAMTOP = $FEFF, under the
; loader.
BasicLine20:
  DEFB $00,$14,$0D,$00    ; the line number, 20, and the length, 13
  DEFB $FD,$36,$35,$32,$37,$39,$0E,$00 ; CLEAR "65279", hidden $FEFF, ENTER
  DEFB $00,$FF,$FE,$00,$0D

; Line 30: LOAD "" CODE
;
; LOAD ($EF) "" CODE ($AF): the next Bytes block at the address of its header,
; the "loader" block at 65280.
BasicLine30:
  DEFB $00,$1E,$05,$00    ; the line number, 30, and the length, 5
  DEFB $EF,$22,$22,$AF,$0D ; LOAD "" CODE ENTER

; Line 40: RANDOMIZE USR 65280
;
; RANDOMIZE ($F9) USR ($C0) "65280", hidden $FF00: calls the loader
; (src/loader). It never returns: the loader resets the machine on a tape error
; and jumps into the game otherwise.
BasicLine40:
  DEFB $00,$28,$0E,$00    ; the line number, 40, and the length, 14
  DEFB $F9,$C0,$36,$35,$32,$38,$30,$0E ; RANDOMIZE USR "65280", hidden $FF00,
  DEFB $00,$00,$00,$FF,$00,$0D         ; ENTER
