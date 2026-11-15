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
  ; $E46D section 0: scroll limit 0, 8 rows to the next map, rows 2-7
  ;   shown; also the map of the filler entries 13
  INCBIN "res/level/maps.bin",$0000,64
Section1Map:
  ; $E4AD section 1: scroll limit 144, 42 rows to the next map, rows 2-43
  ;   shown: rows 42-43 are section 2's rows 0-1
  INCBIN "res/level/maps.bin",$0040,336
Section2Map:
  ; $E5FD section 2: scroll limit 16, 10 rows to the next map, rows 2-11
  ;   shown: rows 10-11 are section 3's rows 0-1
  INCBIN "res/level/maps.bin",$0190,80
Section3Map:
  ; $E64D section 3: scroll limit 72, 20 rows to the next map, rows 2-25
  ;   shown: rows 20-25 are section 4's rows 0-5
  INCBIN "res/level/maps.bin",$01E0,160
Section4Map:
  ; $E6ED section 4: scroll limit 112, 30 rows to the next map, rows 2-35
  ;   shown: rows 30-35 are section 5's rows 0-5
  INCBIN "res/level/maps.bin",$0280,240
Section5Map:
  ; $E7DD section 5: scroll limit 16, 8 rows to the next map, rows 2-11
  ;   shown: rows 8-11 are section 6's rows 0-3
  INCBIN "res/level/maps.bin",$0370,64
Section6Map:
  ; $E81D section 6: scroll limit 88, 28 rows to the next map, rows 2-29
  ;   shown: rows 28-29 are section 7's rows 0-1
  INCBIN "res/level/maps.bin",$03B0,224
Section7Map:
  ; $E8FD section 7: scroll limit 8, 8 rows to the next map, rows 2-9
  ;   shown: rows 8-9 are section 8's rows 0-1
  INCBIN "res/level/maps.bin",$0490,64
Section8Map:
  ; $E93D section 8: scroll limit 8, 8 rows to the next map, rows 2-9
  ;   shown: rows 8-9 are section 9's rows 0-1
  INCBIN "res/level/maps.bin",$04D0,64
Section9Map:
  ; $E97D section 9: scroll limit 8, 30 rows to the next map, rows 2-9
  ;   shown; rows 10-12 only built below the view; rows 13-29 read by
  ;   nothing (filler)
  INCBIN "res/level/maps.bin",$0510,240
Section10Map:
  ; $EA6D section 10: scroll limit 128, 38 rows to the next map, rows 2-39
  ;   shown: rows 38-39 are section 11's rows 0-1
  INCBIN "res/level/maps.bin",$0600,304
Section11Map:
  ; $EB9D section 11: scroll limit 96, 32 rows to the next map, rows 2-31
  ;   shown
  INCBIN "res/level/maps.bin",$0730,256
Section12Map:
  ; $EC9D section 12: scroll limit 8, 8 rows shown up to its row 9
  INCBIN "res/level/maps.bin",$0830,80

; 128 zero bytes after the maps
;
; Zero bytes up to the next block. BuildView reads the first 24 bytes as the 3
; rows it builds below the view of the section whose shown rows end at $ECED
; (scrolled to its limit); no section shows them.
MapsTail:
  DEFS $80
