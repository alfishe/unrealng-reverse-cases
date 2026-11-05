; --------------------------------------------------------------------------------------------------------------------
; tilecopy.asm: The top of the start-up copy at $5C00-$67FF: zeros on the tape, the tiles and glyphs in play
;
; The image starts at $61A8 inside the block Start ($B6FF) fills: it copies the 3072 bytes the tape put at $BC00-$C7FF
; down to $5C00-$67FF. The tape's own bytes here are zeros; from the copy on the area holds the game's tile set and
; sprite glyphs.
;
; $5C00-$63FF: the scenery tiles, line-interleaved (line k of tile t at $5C00 + 256 k + t), read by BuildGlyph $89C9
; through TileSet $7F6D (c2: 1025 entries reading tiles $00-$BA of all 8 lines). $6400-$67FF: 8-byte linear glyphs for
; the sprite builders: BuildCellSprite $8EDB reads $64E0-$64FF and $65E0-$65FF (c2: 5 entries), BuildBigSprite $8F0C
; reads 8 bytes a cell from $66E0.
; --------------------------------------------------------------------------------------------------------------------

; The tile set and sprite glyphs from $61A8 on (zeros on the tape, copied from
; $C1A8 by Start)
;
; The image's part of the 3072-byte block that Start copies from $BC00 to $5C00
; (DI, LDIR at $B70C): tile lines 5-7 from $61A8 (tiles $A8-$FF of line 5, then
; lines 6 and 7: $6200-$63FF), then the linear glyphs $6400-$67FF. On the tape
; every byte is 0 (c1: $5B00, the loader's relocation, writes $61A8-$7FFF with
; them), so the source keeps them as space.
;
; In play the tile lines are read by BuildGlyph $89C9 (c2: $6100-$61BA,
; $6300-$63BA, 1025 entries), the glyphs by BuildCellSprite $8EDB ($64E0-$64FF,
; $65E0-$65FF) and BuildBigSprite $8F0C.
TileCopyTail:
  DEFS $0538
BigSpriteGlyphs:
  DEFS $0120              ; 8-byte linear glyphs read by BuildBigSprite $8F0C
                          ; when A = 1 (the operand at $8F15)
