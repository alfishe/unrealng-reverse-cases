; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The game's graphics: sprites and the object table
; --------------------------------------------------------------------------------------------------------------------

; bytes before the first sprite (no recording reads them; known only from the
; heatmap)
GraphicsHead:
  INCBIN "res/leftovers/graphics-head.bin",$0000,13

; The game's sprites: cells of 9 bytes (attribute, 8 pixel bytes) drawn through
; GameObjects
;
; The ship, its shield, the Force in its levels, the bits, the shots, the beam,
; the missiles, the explosions, the carriers, the logo letters. Read in every
; play recording.
Sprites:
  INCBIN "res/graphics/sprites.bin",$0000,5731

; 111 objects of 4 bytes: width, height, the cells' address (GameObject)
GameObjects:
  INCBIN "res/tables/game-objects.bin",$0000,444
