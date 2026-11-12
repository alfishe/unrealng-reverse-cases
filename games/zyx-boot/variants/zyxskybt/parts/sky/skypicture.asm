; --------------------------------------------------------------------------------------------------------------------
; skypicture.asm: The Skynet picture, its attributes, its drawing and the Cyrillic font
;
; Loaded at $6FE0 (the menu's spare bytes and the 9 more sectors the variant's loader reads); SkySetup draws the
; picture at the bottom of the screen, under the catalogue, and SkyScrollSetup copies the font to $9C00 and then
; clears $6FE0-$9BFF.
; --------------------------------------------------------------------------------------------------------------------

; The picture: 40 pixel rows of 20 bytes (160x40), "SKYNET" in Taganrog's
; colours
SkyPicture:
  INCBIN "res/graphics/sky-picture.bin",$0000,800

; Its attributes: 5 rows of 20 cells
SkyPictureAttrs:
  INCBIN "res/tables/sky-picture-attrs.bin",$0000,100

; Copy B rows of C bytes from HL to the screen at DE, one pixel row down after
; each
;
; DE steps through the screen's layout: INC D, and at a cell's end on to the
; next character row (and the next third).
CopyPixelRows:
  PUSH DE
  PUSH BC
  LD B,$00
  LDIR
  POP BC
  POP DE
  INC D
  LD A,D
  AND $07
  JR NZ,l_737C
  LD A,E
  ADD A,$20
  LD E,A
  JR C,l_737C
  LD A,D
  SUB $08
  LD D,A
l_737C:
  DJNZ CopyPixelRows
  RET

; Copy B rows of C bytes from HL to DE, 32 bytes apart (attribute rows)
;
; Used by the routine at DrawSkyPicture.
CopyAttrRows:
  PUSH BC
  PUSH DE
  LD B,$00
  LDIR
  POP DE
  PUSH HL
  LD HL,$0020
  ADD HL,DE
  EX DE,HL
  POP HL
  POP BC
  DJNZ CopyAttrRows
  RET

; Draw SkyPicture at PictureScreen $5066 and its attributes at PictureAttrs
; $5A66
DrawSkyPicture:
  LD HL,SkyPicture
  LD BC,$2814
  LD DE,PictureScreen
  CALL CopyPixelRows
  LD BC,$0514
  LD DE,PictureAttrs
  CALL CopyAttrRows
  RET

; 32 letters for the codes $60-$7F in KOI-7 order (Ю А Б Ц ... Ч, then ©), 8x8
CyrillicFont:
  INCBIN "res/graphics/font-cyrillic.bin",$0000,256
