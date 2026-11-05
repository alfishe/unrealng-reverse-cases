; --------------------------------------------------------------------------------------------------------------------
; buffers.asm: The map ring, the start-up copy's source and the glyph cache
;
; $B700-$DFFF is work space in play, but on the tape it carries the 3072 bytes the start-up ($B6FF) copies down to
; $5C00-$67FF before anything else runs: the 256 scenery tiles ($BC00-$C3FF) and the cells of the wave sprites
; ($C400-$C7FF). The rest of the range is zero on the tape.
;
; In play the map ring takes $B700-$BFFF (18 rows of 128 bytes: a tile code and a flag byte a column, cleared by
; LevelSetUp $8C3B, its first 47 bytes the start-up code itself) and the glyph cache $C000-$DFFF (256 glyphs in four
; shifts, pages $C0, $C8, $D8, $D0 for 0, 2, 4, 6 pixels; line k of glyph n at page + k*256 + n; built by BuildGlyph
; $89C9, read by the span handlers $873E, $8797, $87E0, $8819).
; --------------------------------------------------------------------------------------------------------------------

; The map ring from $B72F on (zero on the tape)
;
; In play: the map ring $B700-$BFFF, the playfield's 18 rows of 128 bytes, two
; rows a page; a row's record holds its pointer (+0/+1 = $B71F + $80 * row, set
; by LevelSetUp $8C3B). The scenery scripts write tile codes into it, RowStart
; ($86CE) pushes a row onto the attributes, BuildGlyph ($89C9) and ScrollStep
; ($8AED) read it (c2: $86CE 11862 entries reading $B700-$BFFF).
;
; Its first 47 bytes ($B700-$B72E) are the start-up routine at $B6FF, dead once
; it has run; LevelSetUp clears $B700-$BFFF (LD HL,$B700, BC = $08FF) before
; the first level.
;
; On the tape these 1233 bytes are zero: no leftover.
MapRingSpace:
  DEFS $01
  DEFS $30                ; ScrollColumnB starts here ($8022 = $B730 at level
                          ; start)
  DEFS $04A0              ; ScrollColumn starts here ($801C = $B760 at level
                          ; start)

; The 256 scenery tiles, as the start-up copies them to TileGraphics $5C00
;
; 2048 bytes: 8 line pages of 256 bytes, line y of tile t at $BC00 + y*256 + t.
; The start-up ($B6FF: LD HL,$BC00, DE = $5C00, BC = $0C00, LDIR) copies them
; with the wave cells to $5C00-$67FF, where BuildGlyph ($89C9) reads them
; through TileSet $7F6D (c2: $5C00-$63BA, tile codes up to $BA in level 1); a
; tile drawn mirrored goes through BitReverse $FB00, flipped through the line
; pages +$700 down.
;
; In play $BC00-$BFFF is the map ring's last four rows and $C000-$C3FF the
; glyph cache's first page: the tape copy is dead after the start-up. Editable
; as src/res/gfx/tiles.gfx.png (16 x 16 tiles).
TileSource:
  INCBIN "res/gfx/tiles.bin",$0000,1024
GlyphCache:
  INCBIN "res/gfx/tiles.bin",$0400,1024

; The cells of the wave sprites, copied to $6400
;
; 1024 bytes copied to $6400-$67FF by the start-up: 64 columns of 16 lines (two
; 8-line cells), column-major, a set bit the sprite's pixel. A wave sprite of
; kind A < 16 is two columns at $6400 + A*32; from 16 up three columns at $6620
; + (A-16)*48 (LoadCellSprite $ACD9: HL = $6400 + (A>>3)*256 + (A&7)*32, plus
; (A-16)*16 + $20 from 16 up).
;
; BuildCellSprite ($8EDB) complements them into a sprite cache image
; (SpriteCacheImages $E748) with a blank column after each; c2 reads only
; $64E0-$64FF and $65E0-$65FF (kinds 7 and 15, level 1). $6600-$661F (two
; columns) is no sprite of that addressing. Editable as
; src/res/gfx/wave-cells.gfx.png.
WaveCellSource:
  INCBIN "res/gfx/wave-cells.bin",$0000,1024

; The glyph cache pages $C8-$DF (zero on the tape)
;
; In play: the glyphs shifted by 2, 6 and 4 pixels (pages $C8, $D0, $D8;
; BuildGlyph $89C9 writes them, the span handlers read them). 6144 zero bytes
; on the tape.
GlyphCacheUpper:
  DEFS $1800
