; --------------------------------------------------------------------------------------------------------------------
; screenwork.asm: The end of the cell flags and a graphic slot: work space after the char map
;
; The cell flags are one byte for each char cell of the map window `$6600-$69FF` (32 x 32 cells): `$6C00-$6FFF`, the
; first half in the range before this one. A cell whose char changed is marked 1 (`$AE25`, `$AE4D`, `$AE76`, `$AE9A`,
; the scrolls) and the redraw `$A834` (and `$A25D`) walks the flags from `$6C00` up to the end mark `$FF` it puts at
; `$6F00`, the 24 rows of the screen, redrawing only the marked cells. `$A239` and `$AF18` fill the flags with 1
; (`$0101` pushed from `$6F00` and `$7000` down): redraw everything.
;
; Fragment E ends at the font's last byte, `$9FEC`, before the sound code at `$9FED`.
; --------------------------------------------------------------------------------------------------------------------

; The cell flags of rows 16-23 of the map window (`$6C00` + 32 x row + column),
; 0 as loaded
;
; Written 1 by the scrolls' compares (`$AE25`, `$AE76`, `$AE9A`) and the fills
; `$A239` / `$AF18`, read and cleared by the redraw `$A834` / `$A25D` and
; `$A6D0`. Read and written in every recording.
CellFlagsRow16:
  DEFS $0100

; The cell flags of rows 24-31 (below the screen); `$6F00` is also the redraw's
; end mark
;
; The redraws `$A25D` and `$A834` put `$FF` at `$6F00` (CellFlagsRow24's first
; byte) to stop their scan after row 23; `$A781` saves the byte into its own
; code (`$A80F`) and puts it back after its copy. `$AF18` fills the 256 bytes
; with 1 (SP `$7000`, 8 x 16 PUSH). `$AE76` scans the whole map window up to
; its end mark at CellFlagsEnd.
CellFlagsRow24:
  DEFS $0100

; The end mark of the 32-row scan: `$AE76` writes `$FF` here
CellFlagsEnd:
  DEFB $00

; 127 bytes no routine reads in play (0 as loaded)
;
; Known only from the code: no instruction names an address in it, and the
; recordings read and write it only while the tape loads (`c1`).
Unused7001:
  DEFS $7F

; A 126-byte sprite frame filled at the entry: kind 19's graphic (ObjectKinds
; `$D3B6`)
;
; The entry `$AB4D` copies 126 bytes from `$6C22` here (`$AB62`, after the 126
; from `$6BA4` to `$6A80`, kind 16's graphic): the two graphics kept past the
; music's bytes, which the game reuses as work space. The format is
; SpriteFrames'. No recording drew kind 19.
GraphicSlot19:
  DEFS $7E

; 2 bytes, not read in play
Unused70FE:
  DEFS $02
