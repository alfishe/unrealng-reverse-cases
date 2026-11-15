; --------------------------------------------------------------------------------------------------------------------
; maps.asm: The sections' maps: rows of 8 block numbers
; --------------------------------------------------------------------------------------------------------------------

; The maps of the 8 sections, one row of 8 block numbers a line
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
  ;   shown; also the map of the filler entries 8, 9, 10, 11, 12, 13, 14,
  ;   15, 16
  INCBIN "res/level/maps.bin",$0000,64
Section1Map:
  ; $E4AD section 1: scroll limit 112, 30 rows to the next map, rows 2-35
  ;   shown: rows 30-35 are section 2's rows 0-5
  INCBIN "res/level/maps.bin",$0040,240
Section2Map:
  ; $E59D section 2: scroll limit 112, 40 rows to the next map, rows 2-35
  ;   shown; rows 36-38 only built below the view; row 39 read by nothing
  ;   (filler)
  INCBIN "res/level/maps.bin",$0130,320
Section3Map:
  ; $E6DD section 3: scroll limit 0, 8 rows to the next map, rows 2-7 shown
  INCBIN "res/level/maps.bin",$0270,64
Section4Map:
  ; $E71D section 4: scroll limit 104, 32 rows to the next map, rows 2-33
  ;   shown: rows 32-33 are section 5's rows 0-1
  INCBIN "res/level/maps.bin",$02B0,256
Section5Map:
  ; $E81D section 5: scroll limit 104, 32 rows to the next map, rows 2-33
  ;   shown: rows 32-33 are section 6's rows 0-1
  INCBIN "res/level/maps.bin",$03B0,256
Section6Map:
  ; $E91D section 6: scroll limit 8, 8 rows to the next map, rows 2-9
  ;   shown: rows 8-9 are section 7's rows 0-1
  INCBIN "res/level/maps.bin",$04B0,64
Section7Map:
  ; $E95D section 7: scroll limit 8, 8 rows shown up to its row 9
  INCBIN "res/level/maps.bin",$04F0,80

; 185 zero bytes after the maps
;
; Zero bytes up to the next block. BuildView reads the first 24 bytes as the 3
; rows it builds below the view of the section whose shown rows end at $E9AD
; (scrolled to its limit); no section shows them.
MapsTail1:
  DEFS $B9

; 6 bytes after the maps
;
; Bytes no section shows (01 01 01 01 01 01).
MapsTail2:
  DEFB $01,$01,$01,$01,$01,$01

; 769 zero bytes after the maps
;
; Zero bytes up to the next block.
MapsTail3:
  DEFS $0301
