; --------------------------------------------------------------------------------------------------------------------
; tail.asm: The block's tail: zeros, then what the stack held when the block was saved
;
; The copy at $5E00 ends at $5E78 (block offset $87). The rest of the block is no code the loader runs: zeros up to
; $FFB5, then 74 bytes that read like the top of a stack, a leftover of the machine the block was saved from: words
; that fall in the game's code ($929E, $9244 and $9247 inside its interrupt handler, $AF33, $87D0), two copies of the
; ROM-like run $3A $5C $06 $13 $21 $11, and at $FFF4 the JP $9226 and at $FFFF the $18 that the game's entry writes
; itself (GameEntry $9100: the IM 2 jump), and at $FFFE the 0 of a 128K. The game's entry writes $FFF4-$FFF6 and $FFFF
; again and the loader writes MachineFlag, so none of these bytes is read as it came off the tape (known from the
; code: LoaderMain writes $FFFE before any read).
; --------------------------------------------------------------------------------------------------------------------

; Zeros after the copied code
LoaderPad:
  DEFS $2E

; The stack as it was when the block was saved: 74 bytes, read by nothing
StackLeftover:
  DEFB $54,$00,$9E,$92,$2F,$AF,$33,$AF
  DEFB $F0,$84,$00,$F3,$D0,$87,$02,$02
  DEFB $54,$00,$44,$92,$3A,$5C,$06,$13
  DEFB $21,$11,$3B,$F3,$01,$9F,$59,$9F
  DEFB $47,$92,$3A,$5C,$06,$13,$21,$11
  DEFB $9B,$36,$58,$FF,$0A,$00,$38,$40
  DEFB $00,$00,$8A,$A1,$0A,$00,$0B,$98
  DEFB $00,$CC,$4D,$00,$38,$80
JumpToHandlerLeftover:
  DEFB $C3,$26,$92,$5A,$A5,$80,$E2,$88 ; JP $9226, as the game's entry writes
  DEFB $E2,$3C                         ; it
MachineFlag:
  DEFB $00                ; the 128K flag: 0 on a 128K, $FF on a 48K (written
                          ; by LoaderMain, read by the game's interrupt)
JrLeftover:
  DEFB $18                ; $18 (JR), as the game's entry writes it
