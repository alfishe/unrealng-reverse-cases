; --------------------------------------------------------------------------------------------------------------------
; helppic.asm: the picture of help item 1
;
; The first of the fifteen Hrust 1 streams: the picture of "Описание игры" (help item 1), held before the depacker.
; The others are in pictures.asm. Each is a whole screen packed by Hrust 1 (tools/bootmenu_hrust.py has the format;
; the PNG in src/res/bootmenu/pictures). After every stream one byte nothing reads.
; --------------------------------------------------------------------------------------------------------------------

; help item 1 "Описание игры": a planet over a figure by a craft (Hrust 1)
;
; Drawn by HelpDescription for each of its 5 pages.
DescriptionPicture:
  INCBIN "res/pictures/description.hrust",$0000,1510

; a byte after the stream: never read
DescriptionPictureSpare:
  DEFB $00
