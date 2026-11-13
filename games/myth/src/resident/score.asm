; --------------------------------------------------------------------------------------------------------------------
; score.asm: The score: the decimal table and the score variables (the stages print it)
; --------------------------------------------------------------------------------------------------------------------

  ORG $F9BD

; POP HL / RET: return to the caller's caller
;
; Not executed in any recording (all checked); stage 4 refers to it twice
; (xref.txt). Known only from the code.
DropReturn:
  POP HL
  RET

; 10000, 1000, 100, 10, 1: the stages' decimal print
;
; Read by the stages' score print (every stage recording).
DecimalTable:
  DEFW $2710
  DEFW $03E8
  DEFW $0064
  DEFW $000A
  DEFW $0001

  ORG $F9FB

; The score, a word (0 at NewGame; the stages add to it)
Score:
  DEFW $0000

; The score's high two digits (ten thousands, 0-99), above Score: 0 at NewGame;
; the stages' AddScore carries into it (src/stage1 AddScore)
ScoreHigh:
  DEFB $00
