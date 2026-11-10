; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The tiles and their attributes
;
; IconTiles, CellTiles and BuildingTiles (8 bytes a tile) and their attribute tables.
; --------------------------------------------------------------------------------------------------------------------

; The 67 icon and frame tiles, 8 bytes each: the tool palette (2 x 2 each), the
; frames $38-$3F, the separators $40-$42
IconTiles:
  INCBIN "res/graphics/IconTiles.bin",$0000,536

; The 94 cell tiles of the map (cells 0-$5D; $5A-$5D the fire and flood frames
; AnimateFire and AnimateFlood copy)
CellTiles:
  INCBIN "res/graphics/CellTiles.bin",$0000,752

; The 244 building tiles (a building row's tile numbers n, n + 1, ...)
BuildingTiles:
  INCBIN "res/graphics/BuildingTiles.bin",$0000,1952

; The attributes of icons 0-55 (DrawIcon reads IconAttrs + A; the frame tiles
; use PrintAttr)
IconAttrs:
  INCBIN "res/graphics/IconAttrs.bin",$0000,56

; The cells' attributes
CellAttrs:
  INCBIN "res/graphics/CellAttrs.bin",$0000,94

; The building tiles' attributes
BuildingAttrs:
  INCBIN "res/graphics/BuildingAttrs.bin",$0000,244
