; --------------------------------------------------------------------------------------------------------------------
; tiles.asm: The tiles: pixels, attributes, the alternate upper set
; --------------------------------------------------------------------------------------------------------------------

; The attributes of the alternate upper tiles $80-$FF
;
; In a room of RoomsOnAltTiles $9AC6 the room builder swaps these 128 bytes
; with TileAttrs+$80 ($DF80) and AltTilePixels $FA00 with TilePixels+$400
; ($F400); the next room on the base set swaps them back. Witness: written and
; read in the rzx builds 18000, 20000, 26000 (the swap $918D).
AltTileAttrs:
  INCBIN "res/tiles/alt-attrs.bin",$0000,128

  ORG $DF00

; The attribute of each of the 256 tiles
;
; Looked up by tile index (A + $DF00) when the tile map is drawn ($99A4).
; $DF80-$DFFF are swapped with AltTileAttrs $C580 in the rooms on the alternate
; set.
TileAttrs:
  INCBIN "res/tiles/base-attrs.bin",$0000,256

  ORG $F000

; The 256 tiles' pixels: 8 bytes each
;
; Tile T at $F000 + 8 x T (the word $5B72 = $F000). $F400-$F7FF (tiles $80-$FF)
; are swapped with AltTilePixels $FA00 in the rooms on the alternate set.
TilePixels:
  INCBIN "res/tiles/base-pixels.bin",$0000,2048

  ORG $FA00

; The alternate upper tiles $80-$FF: 128 tiles of 8 bytes
AltTilePixels:
  INCBIN "res/tiles/alt-pixels.bin",$0000,1024
