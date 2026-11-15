; --------------------------------------------------------------------------------------------------------------------
; basic-demo-module.asm: The BASIC "DEMO": clears the screen, sets RAMTOP, loads the screen and the code and calls the game
;
; Tape block 2 of side 2 holds the program "DEMO" (header: LINE 1, program length 150, no variables). Line 1 does not
; exist, so the ROM runs from line 10: PAPER 0: INK 0: BORDER 0: CLS, CLEAR 24999, `LOAD "" SCREEN$`, PRINT AT 0,0;,
; LOAD "" CODE, RANDOMIZE USR 35460. Every number is its digits, then the number marker $0E and the five-byte small-
; integer form the ROM reads.
;
; Witness: d1 (work/stage1/d1: power-on, side 2 at ROM speed on the 128K), whose ROM loads this block and runs it,
; frame 13 224 enters $8A84.
; --------------------------------------------------------------------------------------------------------------------

; Line 10: PAPER 0: INK 0: BORDER 0: CLS
;
; Black paper, ink and border, then CLS: the ROM's tape messages that follow
; print black on black, and the loading screen comes onto a black frame.
BasicLine10:
  DEFB $00,$0A
  DEFB $1D,$00            ; the line's length, 29
  DEFB $DA,$30,$0E,$00,$00,$00,$00,$00 ; PAPER ($DA) "0", $0E and 0
  DEFB $3A,$D9,$30,$0E,$00,$00,$00,$00 ; ":" INK ($D9) "0", $0E and 0
  DEFB $00
  DEFB $3A,$E7,$30,$0E,$00,$00,$00,$00 ; ":" BORDER ($E7) "0", $0E and 0
  DEFB $00
  DEFB $3A,$FB,$0D        ; ":" CLS ($FB), ENTER

; Line 20: CLEAR 24999
;
; RAMTOP to $61A7, one byte under the code block ($61A8): the machine stack
; moves under the code, where the game keeps it (its own SP is set by the
; entry).
BasicLine20:
  DEFB $00,$14,$0D,$00
  DEFB $FD,$32,$34,$39,$39,$39,$0E,$00 ; CLEAR ($FD) "24999", $0E and 24999 =
  DEFB $00,$A7,$61,$00,$0D             ; $61A7, ENTER

; Line 30: `LOAD "" SCREEN$`
;
; Loads the next Bytes file to the screen at $4000 whatever its header's start
; says (the header gives 40000).
BasicLine30:
  DEFB $00,$1E,$05,$00,$EF,$22,$22,$AA
  DEFB $0D

; Line 40: PRINT AT 0,0;
;
; Puts the print position back at the top left, so the ROM's "Bytes: ds"
; message of the next LOAD prints in the black top line (INK 0 on PAPER 0) and
; not over the picture (known only from the BASIC: the message is not visible
; in the recording's screens).
BasicLine40:
  DEFB $00,$28,$13,$00
  DEFB $F5,$AC,$30,$0E,$00,$00,$00,$00 ; PRINT ($F5) AT ($AC) "0", $0E and 0,
  DEFB $00,$2C,$30,$0E,$00,$00,$00,$00 ; "," "0", $0E and 0, ";", ENTER
  DEFB $00,$3B,$0D

; Line 50: LOAD "" CODE
;
; Loads the code block at the start its header gives ($61A8).
BasicLine50:
  DEFB $00,$32,$05,$00,$EF,$22,$22,$AF
  DEFB $0D

; Line 60: RANDOMIZE USR 35460
;
; Calls DEMO's entry $8A84 (src/demo), which never returns.
BasicLine60:
  DEFB $00,$3C,$0E,$00
  DEFB $F9,$C0,$33,$35,$34,$36,$30,$0E ; RANDOMIZE ($F9) USR ($C0) "35460", $0E
  DEFB $00,$00,$84,$8A,$00,$0D         ; and 35460 = $8A84, ENTER

; Line 999: SAVE "t:": SAVE "DEMO" LINE 1: LOAD "a:": LOAD "maked"
;
; The authors' mastering line, never run (the program starts at line 1, and
; line 60 does not return). SAVE "t:" sends the next SAVE to the tape and LOAD
; "a:" makes a disk drive the default, the syntax of a disk interface's BASIC:
; so the program saves itself to tape with LINE 1 and then loads the next step,
; "maked", from the disk (known only from the BASIC's text).
BasicLine999:
  DEFB $03,$E7,$25,$00
  DEFB $F8,$22,$74,$3A,$22,$3A,$F8,$22 ; SAVE ($F8) "t:" ":"
  DEFB $44,$45,$4D,$4F,$22,$CA,$31,$0E
  DEFB $00,$00,$01,$00,$00,$3A,$EF,$22
  DEFB $61,$3A,$22,$3A,$EF,$22,$6D,$61
  DEFB $6B,$65,$64,$22,$0D
