; --------------------------------------------------------------------------------------------------------------------
; topcells.asm: the developer switch and the work cells at the top of memory
;
; The tune data ends at $FFD3. $FFD4-$FFD8 are the 48K tape's bytes (what its loader left of the ROM font's 'P' and
; the first line of 'Q'); from $FFD9 to $FFFF the 2 in 1 holds zeros, where the 48K tape had the rest of the font's
; 'Q'-'U'. The game uses three parts as variables: Invulnerable ($FFD7, 0), WorkGlyph ($FFD8, 8 bytes) and ColumnFlags
; ($FFE0, 32 bytes to $FFFF).
; --------------------------------------------------------------------------------------------------------------------

; the lines 4-6 of the ROM's 'P' ($7C, $40, $40), no code reads them
FontLeftover:
  DEFB $7C,$40,$40

; the developer switch: not 0 = the ship cannot be killed
;
; Read only at $9B4C, the collision's death path: when the ship is hit and
; Invulnerable is not 0, the death count-down ($9B5F, DeathTimer = $16) is
; skipped and the ship flies on. Never written by the game: 0 in block 2 (the
; 'P' glyph's empty last line), so a POKE 65495,1 makes the ship immortal; on a
; 128K into RAM page 0 (a write while the engine's page 4 is in at $C000 misses
; it). Witnessed here in r1 and r2: no ship lost (docs/09-sound.md 9.2).
; Measured (../zynaps/work/f4/invuln.py from
; ../zynaps/work/explore/play-start.szx, no input): with 0 the idle ship died
; at frames 300-400, 900-1000 and 1400-1500 (deaths 3); with 1 no death in
; 30000 frames, through levels 0-3 into level 4.
Invulnerable:
  DEFB $00

; an 8-byte work cell: $8EC5 copies a glyph of $72A9 + 8 n here, $8EA1 draws it
; (zero in block 2)
WorkGlyph:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; 32 flags a screen column (to $FFFF, the image's last byte): cleared by $8C3B
; at each level start ($8CD9, LDIR of 32 bytes $FFE0-$FFFF), $89C9 sets bits in
; (H = $FF, L = the object's +$11); zero in block 2
ColumnFlags:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$73
