; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The graphics piece: 8 sectors at $A600
;
; Loaded by the BASIC loader to $A600-$ADFF: the font, the logo, its attributes, the star tables, the random bytes and
; the corner colours. These are the bytes the variants change most (work/stage1/variants.md).
; --------------------------------------------------------------------------------------------------------------------

; The font: 96 characters of 8 bytes, space to the copyright sign
;
; Chars $5C36 = $A500 while the menu prints (DrawScreen).
Font:
  INCBIN "res/graphics/font.bin",$0000,768

; The ZYX logo: four 40x40 sprites (the Z takes two)
;
; Printed by DrawScreen at $4006, $400B, $4010, $4015; flipped by
; DrawReflection.
Logo:
  INCBIN "res/graphics/logo.bin",$0000,200
LogoPart2:
  INCBIN "res/graphics/logo.bin",$00C8,200
LogoPart3:
  INCBIN "res/graphics/logo.bin",$0190,200
LogoPart4:
  INCBIN "res/graphics/logo.bin",$0258,200

; The logo's attributes: 5 rows of 20 cells
;
; Copied to $5806 by DrawScreen.
LogoAttributes:
  INCBIN "res/tables/logo-attrs.bin",$0000,100

; The falling stars: three tables of 20 records of 6 bytes
;
; Read by SampleStars and MoveStars.
StarsA:
  INCBIN "res/tables/stars.bin",$0000,120
StarsB:
  INCBIN "res/tables/stars.bin",$0078,120
StarsC:
  INCBIN "res/tables/stars.bin",$00F0,120

; 8 random bytes: the twinkles' places (NewRandoms refills them)
Randoms:
  INCBIN "res/tables/randoms.bin",$0000,8

; The corner gradients' five attributes
;
; Read by ColourCornerRows and ColourCornerColumns.
CornerColours:
  INCBIN "res/tables/corner-colours.bin",$0000,5

; Zeros to the 8th sector's end: loaded, not read
GraphicsSpare:
  INCBIN "res/spare/graphics-tail.bin",$0000,7
