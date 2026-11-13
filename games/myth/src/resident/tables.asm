; --------------------------------------------------------------------------------------------------------------------
; tables.asm: The tables the stages share: bit reversal, screen lines
; --------------------------------------------------------------------------------------------------------------------

  ORG $FA00

; Byte n is n with its bits in reverse order (the stages' mirrored sprites)
;
; Read in c1 and in the stage recordings (deaths, s1-s3).
BitReverse:
  INCBIN "res/resident/bit-reverse.bin",$0000,256

; The screen address of each of the 192 pixel lines
;
; Read by RevealText, the front and the stages.
ScreenLineTable:
  INCBIN "res/resident/screen-lines.bin",$0000,384

; Zeros no code reads (known only from the code)
ScreenLineTablePad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
