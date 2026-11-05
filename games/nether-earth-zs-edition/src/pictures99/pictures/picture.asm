; --------------------------------------------------------------------------------------------------------------------
; picture.asm: the packed intro screen
; --------------------------------------------------------------------------------------------------------------------

; The intro's screen, RLE-packed (3132 bytes): the author's photo, the logo,
; the bottom line
;
; 6912 bytes once decoded: on the left the photo of Sergey Zotov (ZS) in black
; on white; on the right in a red frame the logo "NETHER EARTH / ZS / EDITION /
; 1999" (green, magenta, cyan), "ZS" under it; on the bottom row "You wanted
; new levels? Take its!" in yellow. 429 runs ($9A V N), one of them a $9A
; literal; the stream ends at $8A35, the decoder's run counter back at 0. The
; source is src/res/pictures99/intro-screen.png; the build packs it
; (tools/front99_res.py) into these bytes.
PackedScreen:
  INCBIN "res/pictures99/intro-screen.rle",$0000,3132

; The 81 bytes after the packed screen to the end of the 13th sector: no code
; reads them
;
; RLE bytes of another picture (runs of $00 and of $3F / $F0, not this screen's
; tail), left in the memory the block was saved from. Kept as a leftover
; (src/res/pictures99/leftover-8a36.bin).
SectorSlack:
  INCBIN "res/pictures99/leftover-8a36.bin",$0000,81
