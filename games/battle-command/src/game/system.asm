; --------------------------------------------------------------------------------------------------------------------
; system.asm: The 128K system area and the loader's leftovers at $5B00
;
; The game image starts at $5B00. $5B00-$5BFF holds what the SpeedLock loader left there (the 128K ROM's own routines
; at $5B00 were overwritten by the bank 5 block, tape block 23); the game never reads or runs it. After a reset the
; ROM writes its SWAP routines here again, which is why the controls recording runs $5B00 (frames 330-405, after the
; reset).
; --------------------------------------------------------------------------------------------------------------------

; Leftover bytes of the load in the 128K ROM's system area
;
; No routine of the game reads or runs `$5B00-$5BFF` in any recording after the
; entry (the L1 of every play and menu build; controls runs the ROM's own SWAP
; here only after the reset at frame 331, `case.json` "overwritten"). Kept as a
; documented leftover.
LoadLeftover5B00:
  DEFB $00,$00,$00,$00,$00,$00,$52,$08,$01,$FF,$04,$00,$80,$03,$3A,$5C
  DEFB $00,$C0,$21,$14,$9B,$36,$58,$27,$FD,$00,$20,$48,$9A,$00,$00,$00
  DEFB $F8,$81,$40,$00,$CD,$F1,$8A,$C3,$00,$08,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
