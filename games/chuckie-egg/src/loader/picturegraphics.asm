; --------------------------------------------------------------------------------------------------------------------
; picturegraphics.asm: The loading picture's character graphics
;
; 66 graphics of 8 x 8, codes $60-$A1 of PictureText; the editable sheet is src/res/loader/PictureGraphics.png.
; --------------------------------------------------------------------------------------------------------------------

; The loading picture's 66 character graphics, codes $60-$A1, 8 bytes each, top
; row first
;
; Read by PrintPictureChar $5FC9 for the picture codes $60 and up (glyph =
; PictureGraphics + 8 x (code - $60)); c1: 200 of the 768 characters of
; PictureText, drawn between frames 246 and 361. The ROM's calculator stack
; later starts inside it ($5DC0, set by Loader), when the picture is no longer
; needed.
PictureGraphics:
  INCBIN "res/loader/PictureGraphics.bin",$0000,528
