; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The character set, the HUD characters and the sprites
;
; Every graphic is stored top row first. PrintChar $9C40 draws codes 0-$CB from CharacterSet (HudCharacters is its
; tail from code $9E), DrawSprite $9A4C the 17 frames of Sprites, DrawHen $929C the eight of HenSprites. The editable
; sheets are src/res/graphics/*.png and src/res/sprites/*.png.
; --------------------------------------------------------------------------------------------------------------------

; The character set, codes 0-$9D: the map cells, the font, the title logo
;
; Glyph = CharacterSet + 8 x code, top row first. Codes 0-5 are the map cells
; (empty, the ladder's two halves, the egg, the grain, the brick), $20-$5F the
; font, $80-$8A the big CHUCKIE EGG of the title, $8F-$96 the A+F logo, $97-$9A
; the key names SPACE, CAPS SHIFT, SYMBOL SHIFT and ENTER. Readers: PrintChar
; $9C40 (33 112 calls), DrawSprite $9A4C (the background cells), DrawHen $929C
; (the cells it erases, from $84F7, the last row), AddScore $A3A7 (the digits
; $30-$39 at $8670).
CharacterSet:
  INCBIN "res/graphics/CharacterSet.bin",$0000,1264

; Codes $9E-$CB: the HUD digits, the cage, the life icon, the cursor
;
; The tail of the character set: $9E-$A7 the digits 0-9 of the HUD (CountDown
; $A1B8 reads them as HudCharacters + 8 x digit), $A8-$B5 the duck's cage, $B6
; the life icon, $B7 the name entry's cursor.
HudCharacters:
  INCBIN "res/graphics/HudCharacters.bin",$0000,368

; 672 bytes of $FF
;
; Never read (L1: no access): the size of one level map, filled with $FF.
FillFF:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The 17 sprite frames of 16 x 16: Harry right 0-3, left 4-7, the duck 8-11,
; blank 12, climbing 13-16
;
; DrawSprite $9A4C copies frame A (Sprites + 32 x A, two bytes a row, top row
; first). Harry's frame is HarryFrame + HarryDir (0 right, 4 left, $0D
; climbing), the duck's 8 or 10 + DuckFrame (10-11 when Harry is left of it);
; frame 12 (blank) erases Harry when he lands on a lift and the duck before it
; moves. Witness: DrawSprite runs 134 270 times in the eight builds.
Sprites:
  INCBIN "res/sprites/Sprites.bin",$0000,544

; The hens' eight frames of 16 x 16: walking 0, 1, 4, 5, climbing 2-3, pecking
; 6-7
;
; DrawHen $929C reads frame A - 1 from its last row up (HL = HenSprites - 2 +
; 32 x A). For a walk A is the state (1 left, 2 right) plus 4 when x AND 4 is
; set; for a climb 3, or 4 when y AND 4 is set; the pecks 7 and 8 are frames 6
; (left) and 7 (right).
HenSprites:
  INCBIN "res/sprites/HenSprites.bin",$0000,256

; Leftover: the first rows of a sprite frame
;
; Never read (L1: no access).
LeftoverSprite:
  DEFB $00,$00,$00,$00,$00,$00,$0C,$00,$0F,$00,$0F,$80,$1F,$C0
