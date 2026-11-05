; --------------------------------------------------------------------------------------------------------------------
; tilecopy.asm: The tile set and the sprite glyphs at $5C00-$67FF, where the 48K start-up copies them
;
; GS: the image starts at $5C00 with the 3072 bytes the 48K's Start ($B6FF) copies from $BC00-$C7FF down here: the
; dump was taken after the start-up, so the tiles and glyphs are already in place (and their tape copy is still at
; $BC00, see the buffers module). The installer's Mover moves them here from the block's $C800.
;
; $5C00-$63FF: the scenery tiles, line-interleaved (line k of tile t at $5C00 + 256 k + t), read by BuildGlyph $89C9
; through TileSet $7F6D (c2: 1025 entries reading tiles $00-$BA of all 8 lines). $6400-$67FF: 8-byte linear glyphs for
; the sprite builders: BuildCellSprite $8EDB reads $64E0-$64FF and $65E0-$65FF (c2: 5 entries), BuildBigSprite $8F0C
; reads 8 bytes a cell from $66E0.
; --------------------------------------------------------------------------------------------------------------------

; The 256 scenery tiles, 8 line pages of 256 bytes: line y of tile t at $5C00 +
; 256 y + t
;
; The bytes of TileSource ($BC00), which the 48K's Start copies here; read in
; play by BuildGlyph $89C9 through TileSet $7F6D (c2: $5C00-$63BA, tile codes
; up to $BA in level 1). A tile drawn mirrored goes through BitReverse $FB00.
TileGraphics:
  INCBIN "res/gfx/tiles.bin",$0000,2048

; The cells of the wave sprites: 8-byte linear glyphs for the sprite builders
;
; The bytes of WaveCellSource ($C400). BuildCellSprite $8EDB reads $64E0-$64FF
; and $65E0-$65FF (c2: 5 entries), BuildBigSprite $8F0C 8 bytes a cell from
; $66E0.
WaveCellGraphics:
  INCBIN "res/gfx/wave-cells.bin",$0000,736
BigSpriteGlyphs:
  INCBIN "res/gfx/wave-cells.bin",$02E0,288
