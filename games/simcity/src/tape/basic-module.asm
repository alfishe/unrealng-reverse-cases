; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: a black screen, CLEAR 32767, load the loader at $FE00 and call it; three mastering lines
;
; Tape block 2 holds the program "Simcity" (header: LINE 0, program length 144, no variables). The ROM runs line 10 at
; once (LINE 0 starts at the first line), line 20 loads blocks 3 and 4, line 30 enters the loader (src/loader) and
; never returns, so lines 40-60 never run: they are the authors' mastering lines, the program saved itself with line
; 50 and went on to the next file of the master tape.
;
; c1: the ROM loads the block at signal speed; the loader $FE00 is entered at frame 1258, T 65 246 (docs/03 3.5).
; --------------------------------------------------------------------------------------------------------------------

; Line 10: PAPER 0: INK 0: BORDER 0: CLEAR 32767
;
; Black on black and a black border, so the loading screen shows only as
; LoadBlock stores its attributes; CLEAR 32767 puts RAMTOP at $7FFF, below the
; loader's $FE00.
BasicLine10:
  DEFB $00,$0A
  DEFB $28,$00            ; the line's length, 40
  DEFB $DA,$30,$0E,$00,$00,$00,$00,$00 ; PAPER ($DA) "0" and its number
  DEFB $3A,$D9,$30,$0E,$00,$00,$00,$00 ; ":" INK ($D9) "0" and its number
  DEFB $00
  DEFB $3A,$E7,$30,$0E,$00,$00,$00,$00 ; ":" BORDER ($E7) "0" and its number
  DEFB $00
  DEFB $3A,$FD,$33,$32,$37,$36,$37,$0E ; ":" CLEAR ($FD) "32767" and $0E, 32767
  DEFB $00,$00,$FF,$7F,$00             ; = $7FFF
  DEFB $0D                ; ENTER

; Line 20: LOAD "" CODE 65024
;
; Loads the next file, blocks 3 and 4: the 512-byte "loader" at $FE00 (its
; header's own start is 65024 as well).
BasicLine20:
  DEFB $00,$14
  DEFB $10,$00            ; the line's length, 16
  DEFB $EF,$22,$22,$AF,$36,$35,$30,$32 ; LOAD ($EF) "" CODE ($AF) "65024" and
  DEFB $34,$0E,$00,$00,$00,$FE,$00     ; $0E, 65024 = $FE00
  DEFB $0D                ; ENTER

; Line 30: RANDOMIZE USR 65024
;
; Calls LoaderStart $FE00 (src/loader), which never returns.
BasicLine30:
  DEFB $00,$1E
  DEFB $0E,$00            ; the line's length, 14
  DEFB $F9,$C0,$36,$35,$30,$32,$34,$0E ; RANDOMIZE ($F9) USR ($C0) "65024" and
  DEFB $00,$00,$00,$FE,$00             ; $0E, 65024 = $FE00
  DEFB $0D                ; ENTER

; Line 40, never reached: POKE 23418,84
;
; 23418 = $5B7A, in the printer buffer, where code2 later lands: the game's
; image holds $7A there (LD A,D in the tone ToneBeep at $5B66), and 84 ($54)
; would be LD D,H. A leftover of the mastering, known only from the code: no
; recording runs it (c1 leaves BASIC at line 30).
BasicLine40:
  DEFB $00,$28
  DEFB $16,$00            ; the line's length, 22
  DEFB $F4,$32,$33,$34,$31,$38,$0E,$00 ; POKE ($F4) "23418" and $0E, 23418 =
  DEFB $00,$7A,$5B,$00,$2C,$38,$34,$0E ; $5B7A, "," "84" and $0E, 84
  DEFB $00,$00,$54,$00,$00
  DEFB $0D                ; ENTER

; Line 50, never reached: SAVE "Simcity" LINE 0
;
; The line that wrote blocks 1 and 2 of the master tape: a program saved with
; LINE 0 autostarts at its first line.
BasicLine50:
  DEFB $00,$32
  DEFB $13,$00            ; the line's length, 19
  DEFB $F8,$22,$53,$69,$6D,$63,$69,$74 ; SAVE ($F8) "Simcity" LINE ($CA) "0"
  DEFB $79,$22,$CA,$30,$0E,$00,$00,$00 ; and $0E, 0
  DEFB $00,$00
  DEFB $0D                ; ENTER

; Line 60, never reached: LOAD "mast0"
;
; The next file of the authors' mastering tape.
BasicLine60:
  DEFB $00,$3C
  DEFB $09,$00            ; the line's length, 9
  DEFB $EF,$22,$6D,$61,$73,$74,$30,$22 ; LOAD ($EF) "mast0"
  DEFB $0D                ; ENTER
