; --------------------------------------------------------------------------------------------------------------------
; charsets.asm: The two char sets: 256 chars of 8 x 8 and their attributes each
;
; A zone draws with char set 0 (levels 1 and 2) or 1 (levels 3 and 4): EnterZone `$AC83` reads the zone's byte +0 and
; patches the attribute page (`$79` or `$82`) into `$A853` and `$AA80`, and passes the bitmaps (`$7100` or `$7A00`) to
; the char properties' builder `$F6A9`. Char C's 8 lines lie at the set + 8C, top line first; its attribute at the
; attribute page + C. The map (`$6500` on) holds the char codes; the redraw `$A834` copies a char's 8 lines and its
; attribute to the screen.
;
; The editable form is src/res/graphics/charset0.png and charset1.png (tools/res_gfx.py; src/res/graphics/README.md):
; a sheet of 16 x 16 cells in their colours, the attributes in the PNG's text chunk.
; --------------------------------------------------------------------------------------------------------------------

; Char set 0 (levels 1-2): 256 chars of 8 lines
;
; Read by the redraws `$A834`, `$A25D` and `$A6D0` (the char cells under the
; sprites).
CharSet0:
  INCBIN "res/graphics/charset0.bin",$0000,2048

; The attributes of char set 0; char 0's (`$7900`) is the screen's empty
; colour, set by the level
;
; `$E320` (LevelIntro) and `$AC14` write `$7900`: the colour of char 0 (empty
; space) follows the level record's attribute; `$ABD8` and `$E267` write it
; too. Read by `$AA0E` (the HUD) and the redraw through the page patched into
; `$A853`.
CharAttr0:
  INCBIN "res/graphics/charattr0.bin",$0000,256

; Char set 1 (levels 3-4): 256 chars of 8 lines
CharSet1:
  INCBIN "res/graphics/charset1.bin",$0000,2048

; The attributes of char set 1
CharAttr1:
  INCBIN "res/graphics/charattr1.bin",$0000,256
