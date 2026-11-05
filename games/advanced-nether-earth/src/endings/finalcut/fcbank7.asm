; --------------------------------------------------------------------------------------------------------------------
; fcbank7.asm: the shadow screen (bank 7)
;
; Bank7Block is copied by FinalCut to bank 7 at $C000 ($3578 bytes: this screen, the PT3 player at $DB00 and the tune
; REM after it). The screen is the shadow screen's picture: the alien in green, the scroll's other half (the normal
; screen holds it in magenta, AlienMagentaScreen). After the copy the 768 bytes of Bank7Block here hold FinalCut's
; line table.
; --------------------------------------------------------------------------------------------------------------------

; the alien in green: the shadow screen (6912 bytes, plain)
AlienGreenScreen:
  INCBIN "res/pictures/alien-green.scr",$0000,6912
