; Bytes below the ground profile
;
; 76 bytes just below the ground profile $6000. In the image they hold
; mask/pixel byte pairs left from the build; the screen copy at $9F1C
; overwrites them from $BFB4-$BFFF (the image of $5B00-$5FFF) before play. The
; profile readers index from $5FF6-$5FF8 ($DA1E, $DAA1, $DB1B, $E3E5, $E94F),
; so the top of this block is the profile's left margin.
ProfileMargin:
  INCBIN "res/leftovers/profile-margin.bin",$0000,76

; Ground profile buffer (768 bytes)
;
; The course's profile under the scroll, one byte for every 2 units along the
; course: the ground height (bits 0-4) and the walls (bits 5-7);
; docs/07-objects.md 7.4. Cleared at every round start ($CF68, $D0EF). In the
; image it holds leftovers of the build, and the entry $61A8 sits inside it:
; code that runs once and then becomes buffer space (docs/02-architecture.md
; 2.2).
ProfileBuffer:
  INCBIN "res/leftovers/profile-buffer.bin",$0000,424

; Game entry (RANDOMIZE USR 25000)
;
; The address BASIC line 30 calls. It sets the stack to the top of memory,
; disables interrupts and jumps to the start-up $9F12. Overwritten when the
; first round clears the profile buffer.
Entry:
  LD SP,$FFFF             ; the stack grows down from the top of RAM
  DI                      ; the game proper runs with interrupts off
  JP Startup              ; the start-up

; Ground profile buffer, after the entry
;
; The rest of the profile buffer, to $62FF. The first 42 bytes are leftover
; loader code that never runs, the rest is zero.
GroundProfileTail:
  INCBIN "res/leftovers/profile-buffer-tail.bin",$0000,337

; Font, codes $20-$3A
;
; 64 glyphs of 8 bytes for codes $20-$5F at $6300-$64FF, glyph = $6300 + (code
; - $20) * 8; printed by $EE17 and, lines 2-6 only, by $EEA4
; (docs/08-hud-and-text.md 8.2). Codes $22-$2C are the big GAME OVER, $2E a red
; block, $2F a gauge segment. The glyph slots of ";" to "?" and "[" to "_" hold
; strings instead (next entries).
Font:
  INCBIN "res/gfx/font.bin",$0000,216

; Credits, first part (in the font's ";" to "?" slots)
;
; A print string for $EE17 (records: attribute + $80, column, row, characters;
; $FF ends): "WRITTEN BY", "COSTA PANAYI", "MUSIC BY" at column 1, rows 17-19,
; attribute $30. Printed by the menu $F1AA; docs/08-hud-and-text.md 8.3.
CreditsText1:
  DEFM $B0,$01,$11,"WRITTEN BY",$B0,$01,$12,"COSTA PANAYI",$B0,$01,$13,"MUSIC BY",$FF

; Font, codes $40-$5A
;
; The second half of the font: the (c) sign at code $40 ("@" in the strings)
; and the capitals.
FontHigh:
  INCBIN "res/gfx/font.bin",$0100,216

; Credits, second part (in the font's "[" to "_" slots)
;
; "BEN DAGLISH", "(c)1989 VORTEX" at column 1, rows 20-21. Printed by the menu
; $F1AA.
CreditsText2:
  DEFM $B0,$01,$14,"BEN DAGLISH",$B0,$01,$15,"@1989 VORTEX",$FF

; " AUTO " in the top window
;
; Printed at (2,6) by the AUTO start in $E68C (docs/05-controls.md 5.4).
AutoText:
  DEFM $87,$02,$06," AUTO ",$FF

; Visible-record list and sprite scratch page
;
; Work space of the sprite code. $EFA5 builds the list of visible records here
; each pass (pointer kept at $EF9F, $40 ends the list) and $F089 scans it;
; $DE08 fills $6500-$6543 with $FF as scratch. Zero in the image.
SpriteScratch:
  DEFS $80

; Sprite graphics, table slot $00
;
; The sprite graphics run from here to $7FFF. Each block is reached through the
; pointer table $C300 by a record's byte +8 (the low byte of the address into
; $C300): 2 x type, for the player at $D246 ($C008) and for every record from
; $C060 at each round setup ($D2E3); the templates $C2B4-$C2E1 and $C360/$C370
; carry their own. The block boundaries below are the table's pointers.
SpriteGfx00:
  INCBIN "res/gfx/sprites/slot-00.bin",$0000,630

; Sprite graphics, table slot $02
SpriteGfx02:
  INCBIN "res/gfx/sprites/slot-02.bin",$0000,630

; Sprite graphics, table slot $04
SpriteGfx04:
  INCBIN "res/gfx/sprites/slot-04.bin",$0000,630

; Sprite graphics, table slot $06
SpriteGfx06:
  INCBIN "res/gfx/sprites/slot-06.bin",$0000,630

; Sprite graphics, table slot $1C
SpriteGfx1C:
  INCBIN "res/gfx/sprites/slot-1c.bin",$0000,420

; Sprite graphics, table slot $1E
SpriteGfx1E:
  INCBIN "res/gfx/sprites/slot-1e.bin",$0000,420

; Sprite graphics, table slot $14
SpriteGfx14:
  INCBIN "res/gfx/sprites/slot-14.bin",$0000,374

; Sprite graphics, table slot $08 (the type 4 missile template)
SpriteGfx08:
  INCBIN "res/gfx/sprites/slot-08.bin",$0000,374

; Sprite graphics, table slots $0A and $0C (the type 6 missile template)
SpriteGfx0A:
  INCBIN "res/gfx/sprites/slot-0a.bin",$0000,374

; Sprite graphics, table slot $0E (the type 7 missile template)
SpriteGfx0E:
  INCBIN "res/gfx/sprites/slot-0e.bin",$0000,374

; Sprite graphics, table slots $10 and $12 (the jet templates)
SpriteGfx10:
  INCBIN "res/gfx/sprites/slot-10.bin",$0000,374

; Sprite graphics, table slot $16
SpriteGfx16:
  INCBIN "res/gfx/sprites/slot-16.bin",$0000,182

; Sprite graphics, table slot $18 (shots: templates $C360, $C2E1)
SpriteGfx18:
  INCBIN "res/gfx/sprites/slot-18.bin",$0000,182

; Sprite graphics, table slot $1A (the shell: template $C370)
SpriteGfx1A:
  INCBIN "res/gfx/sprites/slot-1a.bin",$0000,182

; Explosion frame, table slot $22
;
; The explosion: a hit record's byte +8 is set to $20 ($EBD1, $E262) and counts
; up by 2 a pass to $2C ($E235), so the frames are the slots $20-$2C; slot $20
; and $24 share one picture.
ExplosionGfx22:
  INCBIN "res/gfx/explosions/slot-22.bin",$0000,168

; Explosion frame, table slots $20 and $24
ExplosionGfx20:
  INCBIN "res/gfx/explosions/slot-20.bin",$0000,168

; Explosion frame, table slot $26
ExplosionGfx26:
  INCBIN "res/gfx/explosions/slot-26.bin",$0000,168

; Explosion frame, table slot $28
ExplosionGfx28:
  INCBIN "res/gfx/explosions/slot-28.bin",$0000,168

; Explosion frame, table slot $2A
ExplosionGfx2A:
  INCBIN "res/gfx/explosions/slot-2a.bin",$0000,168

; Explosion frame, table slot $2C (the last before the record is gone)
;
; Its first and last strips ($7F58-$7F81, $7FD6-$7FFF) are blank (`FF 00`: mask
; $FF, no ink), the only blank strips of the explosion frames: the burst has
; thinned to its middle
ExplosionGfx2C:
  INCBIN "res/gfx/explosions/slot-2c.bin",$0000,168
