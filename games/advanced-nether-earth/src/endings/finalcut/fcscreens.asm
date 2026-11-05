; --------------------------------------------------------------------------------------------------------------------
; fcscreens.asm: the screens
;
; Three plain screens (6912 bytes each) FinalCut copies to $4000: the caption shown first, the alien for the scroll
; (the normal screen's half of it) and the Victory screen at the end.
; --------------------------------------------------------------------------------------------------------------------

; the alien in magenta: the normal screen during the scroll
AlienMagentaScreen:
  INCBIN "res/pictures/alien-magenta.scr",$0000,6912

; the caption (Russian): "after long fierce battles the human army has at last
; destroyed the Insignians' base. Now their race is destroyed!", the burning
; base
CaptionScreen:
  INCBIN "res/pictures/caption.scr",$0000,6912

; "Victory is with U!!!": the V-sign
VictoryScreen:
  INCBIN "res/pictures/victory.scr",$0000,6912
