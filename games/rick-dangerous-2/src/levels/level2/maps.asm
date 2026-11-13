; --------------------------------------------------------------------------------------------------------------------
; maps.asm: The sections' maps: rows of 8 block numbers
; --------------------------------------------------------------------------------------------------------------------

; The maps of the 13 sections, one row of 8 block numbers a line
;
; LevelHeader+4 points here. A section's map is a column of rows, 8 block
; numbers a row (8 x 4 cells = 256 pixels: one screen wide), the top row first;
; the section table's +0/+1 (big-endian) is the offset of its first row from
; here. No height is stored: BuildView $88D4 reads 11 rows from row ViewTop / 4
; into ViewCells (44 cell rows), the screen shows view rows 9-31 under the HUD,
; and the scroll limit (section table +3) is the last ViewTop. So a section
; shows block rows 2 to limit / 4 + 7 (rows 0-1 lie above the screen, rows
; limit / 4 + 8 to + 10 are built below it for the objects there).
;
; The maps follow each other in memory (in section order but for the
; section-table filler entries). A map often starts 2 rows before the end of
; the previous one's shown rows: those 2 rows are the next section's hidden
; rows 0-1 (a packing that costs nothing). The comment on each section gives
; its rows to the next map and what the limit asks for.
Maps:
  INCBIN "res/level/maps.bin",$0000,64
Section1Map:
  INCBIN "res/level/maps.bin",$0040,336
Section2Map:
  INCBIN "res/level/maps.bin",$0190,80
Section3Map:
  INCBIN "res/level/maps.bin",$01E0,160
Section4Map:
  INCBIN "res/level/maps.bin",$0280,240
Section5Map:
  INCBIN "res/level/maps.bin",$0370,64
Section6Map:
  INCBIN "res/level/maps.bin",$03B0,224
Section7Map:
  INCBIN "res/level/maps.bin",$0490,64
Section8Map:
  INCBIN "res/level/maps.bin",$04D0,64
Section9Map:
  INCBIN "res/level/maps.bin",$0510,240
Section10Map:
  INCBIN "res/level/maps.bin",$0600,304
Section11Map:
  INCBIN "res/level/maps.bin",$0730,256
Section12Map:
  INCBIN "res/level/maps.bin",$0830,80

; 128 zero bytes after the maps
;
; Zero bytes up to the next block. BuildView reads the first 24 bytes as the 3
; rows it builds below the view of the section whose shown rows end at $ECED
; (scrolled to its limit); no section shows them.
MapsTail:
  DEFS $80
