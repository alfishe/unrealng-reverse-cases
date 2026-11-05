; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The 89 sprite blocks: the ship, the map objects, the robot parts, the buildings' signs, the shots
;
; All pictures of the view, $6980-$A569, 15338 bytes, then 150 spare bytes up to Start. Docs: nether-
; earth/docs/06-rendering.md 6.5 (sprites), 6.6 (robots stacked from parts). Resources: src/res/gfx/sprites/*.png, one
; per block, built into .bin files; the table of files, ids and sizes is in src/res/README.md (The sprites).
;
; Format of a block: byte 0 the height in pixel lines, byte 1 the width in bytes, then the rows from the BOTTOM line
; up, each row width x (mask, graphic) pairs: screen = (screen AND mask) OR graphic. Each block is two entries here:
; SprX (the 2-byte header) and SprXRows (the rows), sharing one resource file.
;
; Readers: DrawSprite ($CF2D, into ViewBuffer) through SpriteTable (module tables), index = sprite id x 2 + the half-
; byte column parity (the odd entry is usually the same picture 4 pixels right); robot parts through PartSpriteTable
; and PartHeights; the construction menu's part icons straight to the screen by DrawMaskedUp ($D315). Never written.
; --------------------------------------------------------------------------------------------------------------------

; Sprite 22 (even column; SpriteTable 44): tracks, moving along X (directions
; 0-1), 27 rows x 3 bytes
;
; The sprites run from here to $A569, 88 blocks, each reached through
; SpriteTable (sprite id x 2 + the column parity). A block: the height in pixel
; lines, the width in bytes, then the rows from the BOTTOM line up, each row
; width x (mask, graphic) byte pairs: screen = (screen AND mask) OR graphic
; (SpriteByteLoop into ViewBuffer, DrawMaskedUp straight to the screen). The
; parity is bit 0 of the half-byte column DrawSprite computes (2 x X + Y - 24):
; the odd entry is the same picture shifted right by 4 pixels (one byte wider
; where it needs to), except where noted: for map objects the column parity is
; the row parity, and map types 12, 13, 14, 17, 18 use the two entries for two
; different pictures.
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprTracksX:
  INCBIN "res/gfx/sprites/tracks-x.bin",$0000,2

; SprTracksX: 27 rows of 3 (mask, graphic) pairs, bottom line first
SprTracksXRows:
  INCBIN "res/gfx/sprites/tracks-x.bin",$0002,162

; Sprite 22 (odd column; SpriteTable 45): tracks, moving along X (directions
; 0-1), 27 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprTracksXOdd:
  INCBIN "res/gfx/sprites/tracks-x-odd.bin",$0000,2

; SprTracksXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first
SprTracksXOddRows:
  INCBIN "res/gfx/sprites/tracks-x-odd.bin",$0002,216

; Sprite 23 (even column; SpriteTable 46): tracks, moving along Y (directions
; 2-3), 28 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprTracksY:
  INCBIN "res/gfx/sprites/tracks-y.bin",$0000,2

; SprTracksY: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprTracksYRows:
  INCBIN "res/gfx/sprites/tracks-y.bin",$0002,168

; Sprite 23 (odd column; SpriteTable 47): tracks, moving along Y (directions
; 2-3), 28 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprTracksYOdd:
  INCBIN "res/gfx/sprites/tracks-y-odd.bin",$0000,2

; SprTracksYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprTracksYOddRows:
  INCBIN "res/gfx/sprites/tracks-y-odd.bin",$0002,224

; Sprite 24 (even column; SpriteTable 48): bipod legs, along X, 30 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprBipodX:
  INCBIN "res/gfx/sprites/bipod-x.bin",$0000,2

; SprBipodX: 30 rows of 3 (mask, graphic) pairs, bottom line first
SprBipodXRows:
  INCBIN "res/gfx/sprites/bipod-x.bin",$0002,180

; Sprite 24 (odd column; SpriteTable 49): bipod legs, along X, 30 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprBipodXOdd:
  INCBIN "res/gfx/sprites/bipod-x-odd.bin",$0000,2

; SprBipodXOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprBipodXOddRows:
  INCBIN "res/gfx/sprites/bipod-x-odd.bin",$0002,240

; Sprite 25 (even column; SpriteTable 50): bipod legs, along Y, 29 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprBipodY:
  INCBIN "res/gfx/sprites/bipod-y.bin",$0000,2

; SprBipodY: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprBipodYRows:
  INCBIN "res/gfx/sprites/bipod-y.bin",$0002,174

; Sprite 25 (odd column; SpriteTable 51): bipod legs, along Y, 29 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprBipodYOdd:
  INCBIN "res/gfx/sprites/bipod-y-odd.bin",$0000,2

; SprBipodYOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprBipodYOddRows:
  INCBIN "res/gfx/sprites/bipod-y-odd.bin",$0002,232

; Sprite 26 (even column; SpriteTable 52): anti-grav unit, every direction, 23
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprAntiGrav:
  INCBIN "res/gfx/sprites/anti-grav.bin",$0000,2

; SprAntiGrav: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprAntiGravRows:
  INCBIN "res/gfx/sprites/anti-grav.bin",$0002,138

; Sprite 26 (odd column; SpriteTable 53): anti-grav unit, every direction, 23
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprAntiGravOdd:
  INCBIN "res/gfx/sprites/anti-grav-odd.bin",$0000,2

; SprAntiGravOdd: 23 rows of 4 (mask, graphic) pairs, bottom line first
SprAntiGravOddRows:
  INCBIN "res/gfx/sprites/anti-grav-odd.bin",$0002,184

; Sprite 27 (even column; SpriteTable 54): cannon facing X+ (direction 0), 28
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonXp:
  INCBIN "res/gfx/sprites/cannon-xp.bin",$0000,2

; SprCannonXp: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonXpRows:
  INCBIN "res/gfx/sprites/cannon-xp.bin",$0002,168

; Sprite 27 (odd column; SpriteTable 55): cannon facing X+ (direction 0), 28
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonXpOdd:
  INCBIN "res/gfx/sprites/cannon-xp-odd.bin",$0000,2

; SprCannonXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonXpOddRows:
  INCBIN "res/gfx/sprites/cannon-xp-odd.bin",$0002,224

; Sprite 28 (even column; SpriteTable 56): cannon facing X- (direction 1), 30
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonXm:
  INCBIN "res/gfx/sprites/cannon-xm.bin",$0000,2

; SprCannonXm: 30 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonXmRows:
  INCBIN "res/gfx/sprites/cannon-xm.bin",$0002,180

; Sprite 28 (odd column; SpriteTable 57): cannon facing X- (direction 1), 30
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprCannonXmOdd:
  INCBIN "res/gfx/sprites/cannon-xm-odd.bin",$0000,2

; SprCannonXmOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonXmOddRows:
  INCBIN "res/gfx/sprites/cannon-xm-odd.bin",$0002,240

; Sprite 29 (even column; SpriteTable 58): cannon facing Y+ (direction 2), 30
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYp:
  INCBIN "res/gfx/sprites/cannon-yp.bin",$0000,2

; SprCannonYp: 30 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonYpRows:
  INCBIN "res/gfx/sprites/cannon-yp.bin",$0002,180

; Sprite 29 (odd column; SpriteTable 59): cannon facing Y+ (direction 2), 30
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYpOdd:
  INCBIN "res/gfx/sprites/cannon-yp-odd.bin",$0000,2

; SprCannonYpOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonYpOddRows:
  INCBIN "res/gfx/sprites/cannon-yp-odd.bin",$0002,240

; Sprite 30 (even column; SpriteTable 60): cannon facing Y- (direction 3), 25
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYm:
  INCBIN "res/gfx/sprites/cannon-ym.bin",$0000,2

; SprCannonYm: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonYmRows:
  INCBIN "res/gfx/sprites/cannon-ym.bin",$0002,150

; Sprite 30 (odd column; SpriteTable 61): cannon facing Y- (direction 3), 25
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYmOdd:
  INCBIN "res/gfx/sprites/cannon-ym-odd.bin",$0000,2

; SprCannonYmOdd: 25 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonYmOddRows:
  INCBIN "res/gfx/sprites/cannon-ym-odd.bin",$0002,200

; Sprite 31 (even column; SpriteTable 62): missile pod along X, 27 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprMissilesX:
  INCBIN "res/gfx/sprites/missiles-x.bin",$0000,2

; SprMissilesX: 27 rows of 3 (mask, graphic) pairs, bottom line first
SprMissilesXRows:
  INCBIN "res/gfx/sprites/missiles-x.bin",$0002,162

; Sprite 31 (odd column; SpriteTable 63): missile pod along X, 27 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprMissilesXOdd:
  INCBIN "res/gfx/sprites/missiles-x-odd.bin",$0000,2

; SprMissilesXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first
SprMissilesXOddRows:
  INCBIN "res/gfx/sprites/missiles-x-odd.bin",$0002,216

; Sprite 32 (even column; SpriteTable 64): missile pod along Y, 28 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprMissilesY:
  INCBIN "res/gfx/sprites/missiles-y.bin",$0000,2

; SprMissilesY: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprMissilesYRows:
  INCBIN "res/gfx/sprites/missiles-y.bin",$0002,168

; Sprite 32 (odd column; SpriteTable 65): missile pod along Y, 28 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprMissilesYOdd:
  INCBIN "res/gfx/sprites/missiles-y-odd.bin",$0000,2

; SprMissilesYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprMissilesYOddRows:
  INCBIN "res/gfx/sprites/missiles-y-odd.bin",$0002,224

; Sprite 33 (even column; SpriteTable 66): phasers facing X+, 28 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersXp:
  INCBIN "res/gfx/sprites/phasers-xp.bin",$0000,2

; SprPhasersXp: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersXpRows:
  INCBIN "res/gfx/sprites/phasers-xp.bin",$0002,168

; Sprite 33 (odd column; SpriteTable 67): phasers facing X+, 28 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersXpOdd:
  INCBIN "res/gfx/sprites/phasers-xp-odd.bin",$0000,2

; SprPhasersXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersXpOddRows:
  INCBIN "res/gfx/sprites/phasers-xp-odd.bin",$0002,224

; Sprite 34 (even column; SpriteTable 68): phasers facing X-, 29 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersXm:
  INCBIN "res/gfx/sprites/phasers-xm.bin",$0000,2

; SprPhasersXm: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersXmRows:
  INCBIN "res/gfx/sprites/phasers-xm.bin",$0002,174

; Sprite 34 (odd column; SpriteTable 69): phasers facing X-, 29 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprPhasersXmOdd:
  INCBIN "res/gfx/sprites/phasers-xm-odd.bin",$0000,2

; SprPhasersXmOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersXmOddRows:
  INCBIN "res/gfx/sprites/phasers-xm-odd.bin",$0002,232

; Sprite 35 (even column; SpriteTable 70): phasers facing Y+, 29 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYp:
  INCBIN "res/gfx/sprites/phasers-yp.bin",$0000,2

; SprPhasersYp: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersYpRows:
  INCBIN "res/gfx/sprites/phasers-yp.bin",$0002,174

; Sprite 35 (odd column; SpriteTable 71): phasers facing Y+, 29 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYpOdd:
  INCBIN "res/gfx/sprites/phasers-yp-odd.bin",$0000,2

; SprPhasersYpOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersYpOddRows:
  INCBIN "res/gfx/sprites/phasers-yp-odd.bin",$0002,232

; Sprite 36 (even column; SpriteTable 72): phasers facing Y-, 26 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYm:
  INCBIN "res/gfx/sprites/phasers-ym.bin",$0000,2

; SprPhasersYm: 26 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersYmRows:
  INCBIN "res/gfx/sprites/phasers-ym.bin",$0002,156

; Sprite 36 (odd column; SpriteTable 73): phasers facing Y-, 26 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYmOdd:
  INCBIN "res/gfx/sprites/phasers-ym-odd.bin",$0000,2

; SprPhasersYmOdd: 26 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersYmOddRows:
  INCBIN "res/gfx/sprites/phasers-ym-odd.bin",$0002,208

; Sprite 37 (even column; SpriteTable 74): nuclear bomb (the ball with the
; trefoil), every direction, 29 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. No recording of the Nether Earth case drew it.
SprNuclear:
  INCBIN "res/gfx/sprites/nuclear.bin",$0000,2

; SprNuclear: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprNuclearRows:
  INCBIN "res/gfx/sprites/nuclear.bin",$0002,174

; Sprite 37 (odd column; SpriteTable 75): nuclear bomb (the ball with the
; trefoil), every direction, 29 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprNuclearOdd:
  INCBIN "res/gfx/sprites/nuclear-odd.bin",$0000,2

; SprNuclearOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprNuclearOddRows:
  INCBIN "res/gfx/sprites/nuclear-odd.bin",$0002,232

; Sprite 38 (even column; SpriteTable 76): electronics dome facing X+, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsXp:
  INCBIN "res/gfx/sprites/electronics-xp.bin",$0000,2

; SprElectronicsXp: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXpRows:
  INCBIN "res/gfx/sprites/electronics-xp.bin",$0002,144

; Sprite 38 (odd column; SpriteTable 77): electronics dome facing X+, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsXpOdd:
  INCBIN "res/gfx/sprites/electronics-xp-odd.bin",$0000,2

; SprElectronicsXpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXpOddRows:
  INCBIN "res/gfx/sprites/electronics-xp-odd.bin",$0002,144

; Sprite 39 (even column; SpriteTable 78): electronics dome facing X-, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsXm:
  INCBIN "res/gfx/sprites/electronics-xm.bin",$0000,2

; SprElectronicsXm: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXmRows:
  INCBIN "res/gfx/sprites/electronics-xm.bin",$0002,144

; Sprite 39 (odd column; SpriteTable 79): electronics dome facing X-, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprElectronicsXmOdd:
  INCBIN "res/gfx/sprites/electronics-xm-odd.bin",$0000,2

; SprElectronicsXmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXmOddRows:
  INCBIN "res/gfx/sprites/electronics-xm-odd.bin",$0002,144

; Sprite 40 (even column; SpriteTable 80): electronics dome facing Y+, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYp:
  INCBIN "res/gfx/sprites/electronics-yp.bin",$0000,2

; SprElectronicsYp: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYpRows:
  INCBIN "res/gfx/sprites/electronics-yp.bin",$0002,144

; Sprite 40 (odd column; SpriteTable 81): electronics dome facing Y+, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYpOdd:
  INCBIN "res/gfx/sprites/electronics-yp-odd.bin",$0000,2

; SprElectronicsYpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYpOddRows:
  INCBIN "res/gfx/sprites/electronics-yp-odd.bin",$0002,144

; Sprite 41 (even column; SpriteTable 82): electronics dome facing Y-, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYm:
  INCBIN "res/gfx/sprites/electronics-ym.bin",$0000,2

; SprElectronicsYm: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYmRows:
  INCBIN "res/gfx/sprites/electronics-ym.bin",$0002,144

; Sprite 41 (odd column; SpriteTable 83): electronics dome facing Y-, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYmOdd:
  INCBIN "res/gfx/sprites/electronics-ym-odd.bin",$0000,2

; SprElectronicsYmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYmOddRows:
  INCBIN "res/gfx/sprites/electronics-ym-odd.bin",$0002,144

; Sprite 42 (even column; SpriteTable 84): the player's flag, building type 7,
; 11 rows x 3 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of the
; Nether Earth case drew it.
SprFlagPlayer:
  INCBIN "res/gfx/sprites/flag-player.bin",$0000,2

; SprFlagPlayer: 11 rows of 3 (mask, graphic) pairs, bottom line first
SprFlagPlayerRows:
  INCBIN "res/gfx/sprites/flag-player.bin",$0002,66

; Sprite 42 (odd column; SpriteTable 85): the player's flag, building type 7,
; 11 rows x 4 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height).
SprFlagPlayerOdd:
  INCBIN "res/gfx/sprites/flag-player-odd.bin",$0000,2

; SprFlagPlayerOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first
SprFlagPlayerOddRows:
  INCBIN "res/gfx/sprites/flag-player-odd.bin",$0002,88

; Sprite 43 (even column; SpriteTable 86): the enemy's flag, building type 8,
; 11 rows x 3 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of the
; Nether Earth case drew it.
SprFlagEnemy:
  INCBIN "res/gfx/sprites/flag-enemy.bin",$0000,2

; SprFlagEnemy: 11 rows of 3 (mask, graphic) pairs, bottom line first
SprFlagEnemyRows:
  INCBIN "res/gfx/sprites/flag-enemy.bin",$0002,66

; Sprite 43 (odd column; SpriteTable 87): the enemy's flag, building type 8, 11
; rows x 4 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of the
; Nether Earth case drew it.
SprFlagEnemyOdd:
  INCBIN "res/gfx/sprites/flag-enemy-odd.bin",$0000,2

; SprFlagEnemyOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first
SprFlagEnemyOddRows:
  INCBIN "res/gfx/sprites/flag-enemy-odd.bin",$0002,88

; Sprite 44 (even column; SpriteTable 88): the warbase sign, building type 0,
; 17 rows x 3 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of the
; Nether Earth case drew it.
SprWarbaseSign:
  INCBIN "res/gfx/sprites/warbase-sign.bin",$0000,2

; SprWarbaseSign: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprWarbaseSignRows:
  INCBIN "res/gfx/sprites/warbase-sign.bin",$0002,102

; Sprite 44 (odd column; SpriteTable 89): the warbase sign, building type 0, 17
; rows x 4 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height).
SprWarbaseSignOdd:
  INCBIN "res/gfx/sprites/warbase-sign-odd.bin",$0000,2

; SprWarbaseSignOdd: 17 rows of 4 (mask, graphic) pairs, bottom line first
SprWarbaseSignOddRows:
  INCBIN "res/gfx/sprites/warbase-sign-odd.bin",$0002,136

; Sprite 45 (even column; SpriteTable 90): cannon shell, flying along X, 16
; rows x 2 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotCannonX:
  INCBIN "res/gfx/sprites/shot-cannon-x.bin",$0000,2

; SprShotCannonX: 16 rows of 2 (mask, graphic) pairs, bottom line first
SprShotCannonXRows:
  INCBIN "res/gfx/sprites/shot-cannon-x.bin",$0002,64

; Sprite 45 (odd column; SpriteTable 91): cannon shell, flying along X, 16 rows
; x 2 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotCannonXOdd:
  INCBIN "res/gfx/sprites/shot-cannon-x-odd.bin",$0000,2

; SprShotCannonXOdd: 16 rows of 2 (mask, graphic) pairs, bottom line first
SprShotCannonXOddRows:
  INCBIN "res/gfx/sprites/shot-cannon-x-odd.bin",$0002,64

; Sprite 46 (even column; SpriteTable 92): cannon shell, flying along Y, 13
; rows x 3 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotCannonY:
  INCBIN "res/gfx/sprites/shot-cannon-y.bin",$0000,2

; SprShotCannonY: 13 rows of 3 (mask, graphic) pairs, bottom line first
SprShotCannonYRows:
  INCBIN "res/gfx/sprites/shot-cannon-y.bin",$0002,78

; Sprite 46 (odd column; SpriteTable 93): cannon shell, flying along Y, 13 rows
; x 3 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotCannonYOdd:
  INCBIN "res/gfx/sprites/shot-cannon-y-odd.bin",$0000,2

; SprShotCannonYOdd: 13 rows of 3 (mask, graphic) pairs, bottom line first
SprShotCannonYOddRows:
  INCBIN "res/gfx/sprites/shot-cannon-y-odd.bin",$0002,78

; Sprite 47 (even column; SpriteTable 94): missile, flying along X, 22 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotMissileX:
  INCBIN "res/gfx/sprites/shot-missile-x.bin",$0000,2

; SprShotMissileX: 22 rows of 3 (mask, graphic) pairs, bottom line first
SprShotMissileXRows:
  INCBIN "res/gfx/sprites/shot-missile-x.bin",$0002,132

; Sprite 47 (odd column; SpriteTable 95): missile, flying along X, 22 rows x 4
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotMissileXOdd:
  INCBIN "res/gfx/sprites/shot-missile-x-odd.bin",$0000,2

; SprShotMissileXOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first
SprShotMissileXOddRows:
  INCBIN "res/gfx/sprites/shot-missile-x-odd.bin",$0002,176

; Sprite 48 (even column; SpriteTable 96): missile, flying along Y, 22 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotMissileY:
  INCBIN "res/gfx/sprites/shot-missile-y.bin",$0000,2

; SprShotMissileY: 22 rows of 3 (mask, graphic) pairs, bottom line first
SprShotMissileYRows:
  INCBIN "res/gfx/sprites/shot-missile-y.bin",$0002,132

; Sprite 48 (odd column; SpriteTable 97): missile, flying along Y, 22 rows x 4
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotMissileYOdd:
  INCBIN "res/gfx/sprites/shot-missile-y-odd.bin",$0000,2

; SprShotMissileYOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first
SprShotMissileYOddRows:
  INCBIN "res/gfx/sprites/shot-missile-y-odd.bin",$0002,176

; Sprite 49 (even column; SpriteTable 98): phaser beam, along X, 17 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotPhaserX:
  INCBIN "res/gfx/sprites/shot-phaser-x.bin",$0000,2

; SprShotPhaserX: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserXRows:
  INCBIN "res/gfx/sprites/shot-phaser-x.bin",$0002,102

; Sprite 49 (odd column; SpriteTable 99): phaser beam, along X, 17 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotPhaserXOdd:
  INCBIN "res/gfx/sprites/shot-phaser-x-odd.bin",$0000,2

; SprShotPhaserXOdd: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserXOddRows:
  INCBIN "res/gfx/sprites/shot-phaser-x-odd.bin",$0002,102

; Sprite 50 (even column; SpriteTable 100): phaser beam, along Y, 20 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotPhaserY:
  INCBIN "res/gfx/sprites/shot-phaser-y.bin",$0000,2

; SprShotPhaserY: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserYRows:
  INCBIN "res/gfx/sprites/shot-phaser-y.bin",$0002,120

; Sprite 50 (odd column; SpriteTable 101): phaser beam, along Y, 20 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording of the Nether Earth case drew
; it.
SprShotPhaserYOdd:
  INCBIN "res/gfx/sprites/shot-phaser-y-odd.bin",$0000,2

; SprShotPhaserYOdd: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserYOddRows:
  INCBIN "res/gfx/sprites/shot-phaser-y-odd.bin",$0002,120

; Sprite 0 (even column; SpriteTable 0, 38, 39, 40, 41): the player's ship, 30
; rows x 4 bytes
;
; Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the
; ship's cell.
SprShip:
  INCBIN "res/gfx/sprites/ship.bin",$0000,2

; SprShip: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprShipRows:
  INCBIN "res/gfx/sprites/ship.bin",$0002,240

; Sprite 0 (odd column; SpriteTable 1): the player's ship, 30 rows x 4 bytes
;
; Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the
; ship's cell.
SprShipOdd:
  INCBIN "res/gfx/sprites/ship-odd.bin",$0000,2

; SprShipOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprShipOddRows:
  INCBIN "res/gfx/sprites/ship-odd.bin",$0002,240

; Sprite 1 (even column; SpriteTable 2): the ship's shadow on the ground, 24
; rows x 3 bytes
;
; Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the
; map.
SprShadow:
  INCBIN "res/gfx/sprites/shadow.bin",$0000,2

; SprShadow: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprShadowRows:
  INCBIN "res/gfx/sprites/shadow.bin",$0002,144

; Sprite 1 (odd column; SpriteTable 3): the ship's shadow on the ground, 24
; rows x 4 bytes
;
; Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the
; map.
SprShadowOdd:
  INCBIN "res/gfx/sprites/shadow-odd.bin",$0000,2

; SprShadowOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first
SprShadowOddRows:
  INCBIN "res/gfx/sprites/shadow-odd.bin",$0002,192

; Sprite 2 (both columns; SpriteTable 4, 5): stones, map type 2, 21 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprStonesA:
  INCBIN "res/gfx/sprites/stones-a.bin",$0000,2

; SprStonesA: 21 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesARows:
  INCBIN "res/gfx/sprites/stones-a.bin",$0002,126

; Sprite 3 (both columns; SpriteTable 6, 7): stones, map type 3, 22 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprStonesB:
  INCBIN "res/gfx/sprites/stones-b.bin",$0000,2

; SprStonesB: 22 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesBRows:
  INCBIN "res/gfx/sprites/stones-b.bin",$0002,132

; Sprite 4 (both columns; SpriteTable 8, 9): stones, map type 4, 21 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprStonesC:
  INCBIN "res/gfx/sprites/stones-c.bin",$0000,2

; SprStonesC: 21 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesCRows:
  INCBIN "res/gfx/sprites/stones-c.bin",$0002,126

; Sprite 5 (both columns; SpriteTable 10, 11): stones, map type 5, 20 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprStonesD:
  INCBIN "res/gfx/sprites/stones-d.bin",$0000,2

; SprStonesD: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesDRows:
  INCBIN "res/gfx/sprites/stones-d.bin",$0002,120

; Sprite 8 (both columns; SpriteTable 16, 17): rocks, map type 8, 25 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprRocksA:
  INCBIN "res/gfx/sprites/rocks-a.bin",$0000,2

; SprRocksA: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksARows:
  INCBIN "res/gfx/sprites/rocks-a.bin",$0002,150

; Sprite 9 (both columns; SpriteTable 18, 19): rocks, map type 9, 26 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprRocksB:
  INCBIN "res/gfx/sprites/rocks-b.bin",$0000,2

; SprRocksB: 26 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksBRows:
  INCBIN "res/gfx/sprites/rocks-b.bin",$0002,156

; Sprite 10 (both columns; SpriteTable 20, 21): rocks, map type 10, 23 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprRocksC:
  INCBIN "res/gfx/sprites/rocks-c.bin",$0000,2

; SprRocksC: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksCRows:
  INCBIN "res/gfx/sprites/rocks-c.bin",$0002,138

; Sprite 11 (both columns; SpriteTable 22, 23): rocks, map type 11, 24 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprRocksD:
  INCBIN "res/gfx/sprites/rocks-d.bin",$0000,2

; SprRocksD: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksDRows:
  INCBIN "res/gfx/sprites/rocks-d.bin",$0002,144

; Sprite 12 (even column; SpriteTable 24): trench start along Y (map type 12 on
; even rows), 20 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprTrenchStartY:
  INCBIN "res/gfx/sprites/trench-start-y.bin",$0000,2

; SprTrenchStartY: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchStartYRows:
  INCBIN "res/gfx/sprites/trench-start-y.bin",$0002,120

; Sprite 12 (odd column; SpriteTable 25): trench start along X (map type 12 on
; odd rows), 21 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprTrenchStartX:
  INCBIN "res/gfx/sprites/trench-start-x.bin",$0000,2

; SprTrenchStartX: 21 rows of 4 (mask, graphic) pairs, bottom line first
SprTrenchStartXRows:
  INCBIN "res/gfx/sprites/trench-start-x.bin",$0002,168

; Sprite 13 (even column; SpriteTable 26): trench middle along Y (map type 13
; on even rows), 23 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprTrenchMiddleY:
  INCBIN "res/gfx/sprites/trench-middle-y.bin",$0000,2

; SprTrenchMiddleY: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchMiddleYRows:
  INCBIN "res/gfx/sprites/trench-middle-y.bin",$0002,138

; Sprite 13 (odd column; SpriteTable 27): trench middle along X (map type 13 on
; odd rows), 21 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprTrenchMiddleX:
  INCBIN "res/gfx/sprites/trench-middle-x.bin",$0000,2

; SprTrenchMiddleX: 21 rows of 4 (mask, graphic) pairs, bottom line first
SprTrenchMiddleXRows:
  INCBIN "res/gfx/sprites/trench-middle-x.bin",$0002,168

; Sprite 14 (even column; SpriteTable 28): trench end along Y (map type 14 on
; even rows), 23 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprTrenchEndY:
  INCBIN "res/gfx/sprites/trench-end-y.bin",$0000,2

; SprTrenchEndY: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchEndYRows:
  INCBIN "res/gfx/sprites/trench-end-y.bin",$0002,138

; Sprite 14 (odd column; SpriteTable 29): trench end along X (map type 14 on
; odd rows), 17 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprTrenchEndX:
  INCBIN "res/gfx/sprites/trench-end-x.bin",$0000,2

; SprTrenchEndX: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchEndXRows:
  INCBIN "res/gfx/sprites/trench-end-x.bin",$0002,102

; Sprite 15 (even column; SpriteTable 30): low block, map type 15, 32 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockLow:
  INCBIN "res/gfx/sprites/block-low.bin",$0000,2

; SprBlockLow: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockLowRows:
  INCBIN "res/gfx/sprites/block-low.bin",$0002,256

; Sprite 15 (odd column; SpriteTable 31): low block, map type 15, 32 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockLowOdd:
  INCBIN "res/gfx/sprites/block-low-odd.bin",$0000,2

; SprBlockLowOdd: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockLowOddRows:
  INCBIN "res/gfx/sprites/block-low-odd.bin",$0002,256

; Sprite 16 (even column; SpriteTable 32): tall block with an arch, map type
; 16, 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockTall:
  INCBIN "res/gfx/sprites/block-tall.bin",$0000,2

; SprBlockTall: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockTallRows:
  INCBIN "res/gfx/sprites/block-tall.bin",$0002,320

; Sprite 16 (odd column; SpriteTable 33): tall block with an arch, map type 16,
; 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockTallOdd:
  INCBIN "res/gfx/sprites/block-tall-odd.bin",$0000,2

; SprBlockTallOdd: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockTallOddRows:
  INCBIN "res/gfx/sprites/block-tall-odd.bin",$0002,320

; Sprite 6 (even column; SpriteTable 12): boulders, map type 6, 25 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprBouldersA:
  INCBIN "res/gfx/sprites/boulders-a.bin",$0000,2

; SprBouldersA: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprBouldersARows:
  INCBIN "res/gfx/sprites/boulders-a.bin",$0002,150

; Sprite 6 (odd column; SpriteTable 13): boulders, map type 6, 24 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprBouldersAOdd:
  INCBIN "res/gfx/sprites/boulders-a-odd.bin",$0000,2

; SprBouldersAOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first
SprBouldersAOddRows:
  INCBIN "res/gfx/sprites/boulders-a-odd.bin",$0002,192

; Sprite 7 (even column; SpriteTable 14): boulders, map type 7, 25 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprBouldersB:
  INCBIN "res/gfx/sprites/boulders-b.bin",$0000,2

; SprBouldersB: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprBouldersBRows:
  INCBIN "res/gfx/sprites/boulders-b.bin",$0002,150

; Sprite 7 (odd column; SpriteTable 15): boulders, map type 7, 24 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprBouldersBOdd:
  INCBIN "res/gfx/sprites/boulders-b-odd.bin",$0000,2

; SprBouldersBOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first
SprBouldersBOddRows:
  INCBIN "res/gfx/sprites/boulders-b-odd.bin",$0002,192

; Sprite 21 (both columns; SpriteTable 42, 43): border post, map type 21, 36
; rows x 2 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprPost:
  INCBIN "res/gfx/sprites/post.bin",$0000,2

; SprPost: 36 rows of 2 (mask, graphic) pairs, bottom line first
SprPostRows:
  INCBIN "res/gfx/sprites/post.bin",$0002,144

; Sprite 17 (even column; SpriteTable 34): low block with a door, map type 17
; on even rows, 32 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockDoor:
  INCBIN "res/gfx/sprites/block-door.bin",$0000,2

; SprBlockDoor: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockDoorRows:
  INCBIN "res/gfx/sprites/block-door.bin",$0002,256

; Sprite 17 (odd column; SpriteTable 35): low block with a window, map type 17
; on odd rows, 32 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockWindow:
  INCBIN "res/gfx/sprites/block-window.bin",$0000,2

; SprBlockWindow: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockWindowRows:
  INCBIN "res/gfx/sprites/block-window.bin",$0002,256

; Sprite 18 (even column; SpriteTable 36): tall block with a grid face and a
; door, map type 18 on even rows, 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprBlockGrid:
  INCBIN "res/gfx/sprites/block-grid.bin",$0000,2

; SprBlockGrid: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockGridRows:
  INCBIN "res/gfx/sprites/block-grid.bin",$0002,320

; Sprite 18 (odd column; SpriteTable 37): tall block with a dotted face, map
; type 18 on odd rows, 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording of the Nether Earth case
; drew it.
SprBlockDotted:
  INCBIN "res/gfx/sprites/block-dotted.bin",$0000,2

; SprBlockDotted: 40 rows of 4 (mask, graphic) pairs, bottom line first
;
; The last byte, $A569, is also the DI that starts GsMenuSound: the
; conversion's code begins one byte inside the sprite. Nether Earth has 0
; there; here $F3 is the graphic byte of the top line's rightmost pair (mask
; $FF), so every dotted block gets six ink pixels (11110011) over the
; background at its top right. The resource gfx/sprites/block-dotted.bin stops
; one byte short (src/res/game/README.md, The overlap); the label GsMenuSound
; gives the byte.
SprBlockDottedRows:
  INCBIN "res/gfx/sprites/block-dotted.bin",$0002,319
