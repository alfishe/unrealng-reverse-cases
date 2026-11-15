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
  ; $E2ED section 0: scroll limit 64, 20 rows to the next map, rows 2-23
  ;   shown: rows 20-23 are section 1's rows 0-3; also the map of the
  ;   filler entries 10, 11, 12, 13
  INCBIN "res/level/maps.bin",$0000,160
Section1Map:
  ; $E38D section 1: scroll limit 144, 44 rows to the next map, rows 2-43
  ;   shown
  INCBIN "res/level/maps.bin",$00A0,352
Section2Map:
  ; $E4ED section 2: scroll limit 96, 32 rows to the next map, rows 2-31
  ;   shown
  INCBIN "res/level/maps.bin",$0200,256
Section3Map:
  ; $E5ED section 3: scroll limit 144, 44 rows to the next map, rows 2-43
  ;   shown
  INCBIN "res/level/maps.bin",$0300,352
Section4Map:
  ; $E74D section 4: scroll limit 8, 8 rows to the next map, rows 2-9
  ;   shown: rows 8-9 are section 5's rows 0-1
  INCBIN "res/level/maps.bin",$0460,64
Section5Map:
  ; $E78D section 5: scroll limit 0, 8 rows to the next map, rows 2-7 shown
  INCBIN "res/level/maps.bin",$04A0,64
Section6Map:
  ; $E7CD section 6: scroll limit 112, 36 rows to the next map, rows 2-35
  ;   shown
  INCBIN "res/level/maps.bin",$04E0,288
Section7Map:
  ; $E8ED section 7: scroll limit 8, 9 rows to the next map, rows 2-9
  ;   shown: row 9 is section 8's row 0
  INCBIN "res/level/maps.bin",$0600,72
Section8Map:
  ; $E935 section 8: scroll limit 120, 37 rows to the next map, rows 2-37
  ;   shown: row 37 is section 9's row 0
  INCBIN "res/level/maps.bin",$0648,296
Section9Map:
  ; $EA5D section 9: scroll limit 56, 20 rows shown up to its row 21
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
