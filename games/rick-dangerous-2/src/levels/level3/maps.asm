; --------------------------------------------------------------------------------------------------------------------
; maps.asm: The sections' maps: rows of 8 block numbers
; --------------------------------------------------------------------------------------------------------------------

; The maps of the 10 sections, one row of 8 block numbers a line
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
  INCBIN "res/level/maps.bin",$0000,160
Section1Map:
  INCBIN "res/level/maps.bin",$00A0,352
Section2Map:
  INCBIN "res/level/maps.bin",$0200,256
Section3Map:
  INCBIN "res/level/maps.bin",$0300,352
Section4Map:
  INCBIN "res/level/maps.bin",$0460,64
Section5Map:
  INCBIN "res/level/maps.bin",$04A0,64
Section6Map:
  INCBIN "res/level/maps.bin",$04E0,288
Section7Map:
  INCBIN "res/level/maps.bin",$0600,72
Section8Map:
  INCBIN "res/level/maps.bin",$0648,296
Section9Map:
  INCBIN "res/level/maps.bin",$0770,176

; 8 bytes after the maps
;
; Bytes no section shows (01 01 01 01 01 01 01 01). BuildView reads the first
; 24 bytes as the 3 rows it builds below the view of the section whose shown
; rows end at $EB0D (scrolled to its limit); no section shows them.
MapsTail1:
  DEFB $01,$01,$01,$01,$01,$01,$01,$01

; 216 zero bytes after the maps
;
; Zero bytes up to the next block.
MapsTail2:
  DEFS $D8
