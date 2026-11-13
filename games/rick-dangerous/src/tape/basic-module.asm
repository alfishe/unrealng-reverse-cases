; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC "Rick": the title, then LOAD "Rick1" CODE 52480 and RANDOMIZE USR 52480
;
; Six lines: 10 REM RICK DANGEROUS  v.2/89; 20 CLEAR 50000; 30 BORDER 0: PAPER 0: INK 0: CLS; 40 PRINT AT 1,8; PAPER
; 1; INK 7;" RICK DANGEROUS "; 50 LOAD "Rick1" CODE 52480; 60 RANDOMIZE USR 52480. Rick1 (src/loader/rick1.asm) then
; loads the rest without the ROM's loader.
;
; Each line: its number (two bytes, high byte first), its length (two bytes, low byte first), the tokens, ENTER ($0D).
; --------------------------------------------------------------------------------------------------------------------

; 10 REM RICK DANGEROUS  v.2/89
;
; A version mark ("v.2/89"); nothing reads it.
BasicLine10:
  DEFB $00,$0A
  DEFB $19,$00            ; the line's length, 25
  DEFB $EA,$20,$52,$49,$43,$4B,$20,$44 ; REM ($EA) and the text
  DEFB $41,$4E,$47,$45,$52,$4F,$55,$53
  DEFB $20,$20,$76,$2E,$32,$2F,$38,$39
  DEFB $0D

; 20 CLEAR 50000
;
; RAMTOP at 50000 = `$C350`, below the key page `$C900` and Rick1 `$CD00`.
BasicLine20:
  DEFB $00,$14,$0D,$00
  DEFB $FD,$35,$30,$30,$30,$30 ; CLEAR ($FD) "50000"
  DEFB $0E,$00,$00,$50,$C3,$00,$0D ; $0E and 50000 = $C350

; 30 BORDER 0: PAPER 0: INK 0: CLS
;
; A black screen and border: the title of line 40 is the only thing shown while
; Rick1 loads.
BasicLine30:
  DEFB $00,$1E,$1D,$00
  DEFB $E7,$30,$0E,$00,$00,$00,$00,$00 ; BORDER ($E7) "0", $0E and 0
  DEFB $3A
  DEFB $DA,$30,$0E,$00,$00,$00,$00,$00 ; ":" PAPER ($DA) "0", $0E and 0
  DEFB $3A
  DEFB $D9,$30,$0E,$00,$00,$00,$00,$00 ; ":" INK ($D9) "0", $0E and 0
  DEFB $3A
  DEFB $FB,$0D            ; ":" CLS ($FB), ENTER

; 40 PRINT AT 1,8; PAPER 1; INK 7;" RICK DANGEROUS "
;
; The title in white on blue at row 1, column 8. Rick1 then prints its own
; messages at rows 7 and 10.
BasicLine40:
  DEFB $00,$28,$37,$00
  DEFB $F5,$AC,$31,$0E,$00,$00,$01,$00 ; PRINT ($F5) AT ($AC) "1", $0E and 1
  DEFB $00
  DEFB $2C,$38,$0E,$00,$00,$08,$00,$00 ; "," "8", $0E and 8
  DEFB $3B,$DA,$31,$0E,$00,$00,$01,$00 ; ";" PAPER ($DA) "1", $0E and 1
  DEFB $00
  DEFB $3B,$D9,$37,$0E,$00,$00,$07,$00 ; ";" INK ($D9) "7", $0E and 7
  DEFB $00
  DEFB $3B,$22,$20,$52,$49,$43,$4B,$20 ; ";" and the string " RICK DANGEROUS "
  DEFB $44,$41,$4E,$47,$45,$52,$4F,$55
  DEFB $53,$20,$22,$0D

; 50 LOAD "Rick1" CODE 52480
;
; Loads TZX blocks 3 and 4 (the header "Rick1", CODE, 512 bytes) at 52480 =
; `$CD00`, Rick1Start.
BasicLine50:
  DEFB $00,$32,$15,$00
  DEFB $EF,$22,$52,$69,$63,$6B,$31,$22 ; LOAD ($EF) "Rick1" CODE ($AF) "52480"
  DEFB $AF,$35,$32,$34,$38,$30,$0E
  DEFB $00,$00,$00,$CD,$00,$0D ; $0E and 52480 = $CD00

; 60 RANDOMIZE USR 52480
;
; Calls Rick1Start `$CD00` (src/loader/rick1.asm), which never returns.
BasicLine60:
  DEFB $00,$3C,$0E,$00
  DEFB $F9,$C0,$35,$32,$34,$38,$30 ; RANDOMIZE ($F9) USR ($C0) "52480"
  DEFB $0E,$00,$00,$00,$CD,$00 ; $0E and 52480 = $CD00
  DEFB $0D                ; ENTER
