; --------------------------------------------------------------------------------------------------------------------
; topcells.asm: the developer switch and the work cells over the ROM font's leftover
;
; The last 43 bytes of the image are what the loader left of a copy of the ROM's character set (from 'P' to the cut
; 'U'): the tune data ends at $FFD3, and the bytes up to $FFFE are the font's 'P' tail ($FFD4-$FFD7) and 'Q'-'U'
; ($FFD8-$FFFE). The game uses three parts of them as variables: Invulnerable ($FFD7, the last line of 'P', 0),
; WorkGlyph ($FFD8, 8 bytes) and ColumnFlags ($FFE0, 32 bytes to $FFFF, one past the image).
; --------------------------------------------------------------------------------------------------------------------

; the lines 4-6 of the ROM's 'P' ($7C, $40, $40), no code reads them
FontLeftover:
  DEFB $7C,$40,$40

; the developer switch: not 0 = the ship cannot be killed
;
; Read only at $9B4C, the collision's death path: when the ship is hit and
; Invulnerable is not 0, the death count-down ($9B5F, DeathTimer = $16) is
; skipped and the ship flies on. Never written by the game: 0 on the tape (the
; 'P' glyph's empty last line), so a POKE 65495,1 makes the ship immortal.
; Measured (work/f4/invuln.py from work/explore/play-start.szx, no input): with
; 0 the idle ship died at frames 300-400, 900-1000 and 1400-1500 (deaths 3);
; with 1 no death in 30000 frames, through levels 0-3 into level 4.
Invulnerable:
  DEFB $00

; an 8-byte work cell: $8EC5 copies a glyph of $72A9 + 8 n here, $8EA1 draws it
; (on the tape: the ROM's 'Q')
WorkGlyph:
  INCBIN "res/fonts/romleftover.bin",$0000,8

; 32 flags a screen column (to $FFFF, past the image): cleared by $8C3B at each
; level start ($8CD9, LDIR of 32 bytes $FFE0-$FFFF), $89C9 sets bits in (H =
; $FF, L = the object's +$11); on the tape the ROM's 'R'-'U'
ColumnFlags:
  INCBIN "res/fonts/romleftover.bin",$0008,31
