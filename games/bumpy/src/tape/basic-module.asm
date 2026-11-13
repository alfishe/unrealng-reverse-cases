; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: line 10, which hides the tape messages, loads the screen and the code and calls the game
;
; Tape block 2 holds the program "BUMPY" (header: LINE 10, program length 191, no variables). The one line is POKE
; 23624,0: POKE 23693,0: POKE 23607,128: CLEAR 24999: LOAD "" SCREEN$: PRINT: BRIGHT 1: OVER 1: PAPER 5: {INK 0} LOAD
; "" CODE 25000: POKE 23607,60: POKE 23685,0: RANDOMIZE USR 43900. Every number is its digits, then the number marker
; $0E and the five-byte small-integer form the ROM reads.
;
; c1: the ROM loads the block and runs the line at once (LINE 10); the screen and the code follow, and USR 43900
; enters GameStart $AB7C (src/game).
; --------------------------------------------------------------------------------------------------------------------

; BASIC line 10: POKE 23624,0: POKE 23693,0: POKE 23607,128: CLEAR 24999: LOAD
; "" SCREEN$: PRINT: BRIGHT 1: OVER 1: PAPER 5: {INK 0} LOAD "" CODE 25000:
; POKE 23607,60: POKE 23685,0: RANDOMIZE USR 43900
;
; The whole program (the header's program length 191 covers it all): the line
; number 10 (two bytes, high byte first), the line's length (187, low byte
; first), then thirteen statements split by ":" ($3A) and closed by ENTER
; ($0D).
;
; POKE 23624,0 sets BORDCR (a black border and lower screen) and POKE 23693,0
; ATTR_P (black on black). POKE 23607,128 moves the high byte of CHARS from $3C
; to $80: the ROM's messages ("Bytes: BUMPY.SCR", "Bytes: BUMPY.CDE") then
; print with the font read from RAM at $8100-$83FF, which holds zeros before
; the code block loads, so they print blank. CLEAR 24999 puts RAMTOP at $61A7,
; one byte below the code block (GameBlock $61A8). LOAD "" SCREEN$ loads the
; loading screen (tape blocks 3 and 4) at $4000; PRINT, BRIGHT 1, OVER 1 and
; PAPER 5 make the next message (OVER 1, a blank font) leave the picture alone
; (known only from the code: the message is not seen in c1's shots).
;
; The two bytes $10 $00 before LOAD are an embedded INK 0 control, which the
; interpreter skips (the ROM's character fetch passes over colour controls and
; their parameter); in a LIST it inks the rest of the line black. LOAD "" CODE
; 25000 loads tape blocks 5 and 6 at $61A8. POKE 23607,60 puts CHARS back at
; $3C00, POKE 23685,0 clears the high byte of DF_CC (known only from the code:
; nothing prints after it), and RANDOMIZE USR 43900 calls GameStart $AB7C,
; which never returns.
BasicLine10:
  DEFB $00,$0A
  DEFB $BB,$00            ; the line's length, 187
  DEFB $F4,$32,$33,$36,$32,$34 ; POKE ($F4) "23624"
  DEFB $0E,$00,$00,$48,$5C,$00,$2C,$30 ; $0E and 23624 = $5C48 (BORDCR), then
                                       ; "," and "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$F4,$32,$33,$36,$39,$33 ; ":" POKE ($F4) "23693"
  DEFB $0E,$00,$00,$8D,$5C,$00,$2C,$30 ; $0E and 23693 = $5C8D (ATTR_P), then
                                       ; "," and "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$F4,$32,$33,$36,$30,$37 ; ":" POKE ($F4) "23607"
  DEFB $0E,$00,$00,$37,$5C,$00,$2C,$31 ; $0E and 23607 = $5C37 (CHARS high
  DEFB $32,$38                         ; byte), then "," and "128"
  DEFB $0E,$00,$00,$80,$00,$00 ; $0E and 128
  DEFB $3A,$FD,$32,$34,$39,$39,$39 ; ":" CLEAR ($FD) "24999"
  DEFB $0E,$00,$00,$A7,$61,$00 ; $0E and 24999 = $61A7
  DEFB $3A,$EF,$22,$22,$AA ; ":" LOAD ($EF) "" SCREEN$ ($AA)
  DEFB $3A,$F5            ; ":" PRINT ($F5)
  DEFB $3A,$DC,$31        ; ":" BRIGHT ($DC) "1"
  DEFB $0E,$00,$00,$01,$00,$00 ; $0E and 1
  DEFB $3A,$DE,$31        ; ":" OVER ($DE) "1"
  DEFB $0E,$00,$00,$01,$00,$00 ; $0E and 1
  DEFB $3A,$DA,$35        ; ":" PAPER ($DA) "5"
  DEFB $0E,$00,$00,$05,$00,$00 ; $0E and 5
  DEFB $3A,$10,$00        ; ":" then the embedded INK 0 control ($10 $00)
  DEFB $EF,$22,$22,$AF,$32,$35,$30,$30 ; LOAD ($EF) "" CODE ($AF) "25000"
  DEFB $30
  DEFB $0E,$00,$00,$A8,$61,$00 ; $0E and 25000 = $61A8
  DEFB $3A,$F4,$32,$33,$36,$30,$37 ; ":" POKE ($F4) "23607"
  DEFB $0E,$00,$00,$37,$5C,$00,$2C,$36 ; $0E and 23607, then "," and "60"
  DEFB $30
  DEFB $0E,$00,$00,$3C,$00,$00 ; $0E and 60 = $3C
  DEFB $3A,$F4,$32,$33,$36,$38,$35 ; ":" POKE ($F4) "23685"
  DEFB $0E,$00,$00,$85,$5C,$00,$2C,$30 ; $0E and 23685 = $5C85 (DF_CC high
                                       ; byte), then "," and "0"
  DEFB $0E,$00,$00,$00,$00,$00 ; $0E and 0
  DEFB $3A,$F9,$C0,$34,$33,$39,$30,$30 ; ":" RANDOMIZE ($F9) USR ($C0) "43900"
  DEFB $0E,$00,$00,$7C,$AB,$00 ; $0E and 43900 = $AB7C
  DEFB $0D                ; ENTER
