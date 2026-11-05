; --------------------------------------------------------------------------------------------------------------------
; texts.asm: the scroller's window, text and font
;
; The data the scroller prints: its window, its text (CP866, CR LF lines, src/res/stage2/scroller.txt) and its
; 64-column font (src/res/stage2/font64.png).
; --------------------------------------------------------------------------------------------------------------------

; The scroller's window: column 16, row 17, 16 bytes wide, 6 rows high
;
; Read by ScrollWindowUp through IX (+0 column, +1 row, +2 width in bytes, +3
; height in character rows): the screen's right half, rows 17-22, under the
; logo's box.
ScrollWindow:
  DEFB $10,$11,$10,$06

; A byte no code reads ($00)
ScrollWindowPad:
  DEFB $00

; The scroller's text: AT 32,22, then 157 lines of CP866 text, each ending CR
; LF
;
; 4155 bytes, $654C-$7586. Its first three bytes are AT 32,22 ($16 $20 $16),
; which PrintLine prints before every line; the text itself starts with them
; too. The lines are Russian (CP866) with Latin names and TAB indents: ZS's
; greeting, the story of the Edition, thanks (M.M.A.) and the date 28.01.1999,
; ending "Нажмите пробел..." (press space). The recording (r99) scrolled the
; first 23 lines. The source is src/res/stage2/scroller.txt (UTF-8).
ScrollText:
  INCBIN "res/stage2/scroller.bin",$0000,4155

; The 64-column font: 256 characters x 8 rows, row-major (row r of character c
; at Font64 + 256 x r + c)
;
; CP866 glyphs 4 pixels wide, each drawn in both nibbles of its bytes
; (PrintChar keeps the half for the column). Characters $00-$1F are never
; printed (codes below $20 are control codes), their bytes are there all the
; same. 2048 bytes, $7587-$7D86, the block's last. The source is
; src/res/stage2/font64.png.
Font64:
  INCBIN "res/stage2/font64.bin",$0000,2048
