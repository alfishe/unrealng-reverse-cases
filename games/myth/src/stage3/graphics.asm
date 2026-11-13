; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The stage's tiles and map, sprites, pictures and their frame tables
;
; Every animated actor shows frames of a sprite set: the bitmaps, then a frame table of 6-byte records (dx, dy, the
; width in bytes, the height in lines, the bitmap's offset from the set's start). SetActorFrame $AC0A takes the frame
; number in A and the table and the set's start from the two words after its CALL. The frames are 1 bit a pixel, rows
; top first, no mask, ORed into the play buffer (mirrored through BitReverse for an actor facing left). Each set's
; bitmaps are exactly the bytes its frames cover, the table right after them (one exception: DragonHeadSprites, one
; stray byte before its table).
;
; Stage 3's sets: the hero's walk, jump, leap and strikes (a hammer); the urns and chests; the pieces of the artefact;
; the Viking warrior; the troll; the bog man; the dragon's head and its breath; the drawbridge; the pyre's flames,
; bier and body; and the pictures drawn without a table: the lightning bolts, the dragon (a row-packed picture with
; its colours), the seated figure of the castle hall (the same), the water's ripple, the shots, the fireballs, the
; thrown objects, the item icons, GAME OVER, the burst's glyphs and shapes.
; --------------------------------------------------------------------------------------------------------------------

  ORG $B556

; The stage's tiles, blocks and map, RLE-packed (3231 bytes; 4437 unpacked: 229
; tiles, 118 blocks, the three grids' map)
;
; RoomChange unpacks it with Unrle $A39A into the play buffer at $5B00 at every
; room change (the buffer is cleared again before the actors are drawn). Unrle:
; the first byte is the escape ($F9 here); a byte other than the escape is
; itself, ESC n v is n copies of v, ESC ESC ends. Unpacked: five words, the
; offsets from $5B0A of the tile kinds (0), the tiles' pixels ($E5: 229 x 8
; bytes), their attributes ($080D), the blocks ($08F2: 118 x 4 tile numbers)
; and the map ($0ACA: grid 0 47 x 9, grid 1 124 x 9, grid 2 14 x 9 block
; numbers, at the grid records' map offsets 0, $01A7, $0603).
;
; The packer that made it is greedy: every run of 4 to 255 equal bytes is ESC n
; v, except one stretch of 8 zero bytes left as they are (unpacked offset 1663:
; a blank tile's pixels). With that one exception tools/res_stage.py packs the
; block again bit for bit (graphics.txt, tiles.png). All 3231 bytes read in
; rzx-r3 and s3-right (each room change).
StageGraphics:
  INCBIN "res/stage3/graphics.bin",$0000,3231

; The shortest lightning bolt: 2 bytes x 24 lines
;
; The four bolts are drawn by the lightning (kind $0C) through LightningShapes
; $9500 (the bitmap, the width, the height of each, and a blank 1 x 1 for no
; bolt). All four read in rzx-r3 and s3-right (the deck of the longship).
LightningBolt1:
  INCBIN "res/stage3/bitmaps-lightning-1-2x24.bin",$0000,48

; A lightning bolt: 2 bytes x 48 lines
LightningBolt2:
  INCBIN "res/stage3/bitmaps-lightning-2-2x48.bin",$0000,96

; A lightning bolt: 2 bytes x 72 lines
LightningBolt3:
  INCBIN "res/stage3/bitmaps-lightning-3-2x72.bin",$0000,144

; The longest lightning bolt: 3 bytes x 104 lines
LightningBolt4:
  INCBIN "res/stage3/bitmaps-lightning-4-3x104.bin",$0000,312

; The seated figure of the castle hall (grid 2): a row-packed picture of 79
; lines (each a byte LEN x 16 + SKIP, then LEN bytes), drawn at buffer line $F8
; of character row 3 ($5F18)
;
; The grid-2 picture code ($9514, called every pass from MainLoop) draws it
; with DrawRowPicture $89A4 while the figure stands (the hits counter $FE65
; under $1E), then paints its colours ThroneAttributes. Read in rzx-r3 (all 335
; bytes; s3-right never reaches the castle).
ThronePicture:
  INCBIN "res/stage3/rowpicture-throne.bin",$0000,335

; 2 bytes past the picture's 79th line that no code reads (DrawRowPicture draws
; 79 lines; read in neither recording)
ThronePictureEnd:
  DEFB $16,$04

; The seated figure's colours: 10 rows of 5 attributes ($FF: leave the cell),
; copied into the shadow at $6E59
;
; The grid-2 picture code ($9537) copies them, or paints $42 (bright red) where
; not $FF for one pass after a hit ($9567, $FE66). Read in rzx-r3 (all 50
; bytes).
ThroneAttributes:
  INCBIN "res/stage3/table-throne-attributes.bin",$0000,50

; The castle's drawbridge: 4 frames, from raised (1 x 31) to lowered (4 x 30)
;
; The drawbridge (kind 7, $9369) shows the frames as it falls. Read in rzx-r3
; (all 388 bytes).
DrawbridgeSprites:
  INCBIN "res/stage3/sprites-drawbridge.bin",$0000,364
DrawbridgeFrameTable:
  INCBIN "res/stage3/sprites-drawbridge.bin",$016C,24

; The funeral pyre's flames: 6 frames of 2 bytes x 12-14 lines
;
; Read in rzx-r3 (all 192 bytes) through the SetActorFrame call at $9419 (kinds
; 8 and 9, PyreFlameActor $93C8; PyreFlameSet $941C).
PyreFlameSprites:
  INCBIN "res/stage3/sprites-pyre-flame.bin",$0000,156
PyreFlameFrameTable:
  INCBIN "res/stage3/sprites-pyre-flame.bin",$009C,36

; 4 frames of 5 bytes x 11-15 lines: the pyre's bier (frame 0) and the body on
; it (frames 1-3)
;
; SetActorFrame calls at $9449 (PyreBierActor $9420) and $94A5 (PyreBodyActor
; $945E). Read in rzx-r3 (all 269 bytes).
BierSprites:
  INCBIN "res/stage3/sprites-bier.bin",$0000,245
BierFrameTable:
  INCBIN "res/stage3/sprites-bier.bin",$00F5,24

; The dragon (grid 1, room 8): a row-packed picture of 69 lines, drawn at
; buffer address $6192 (character row 6, line 4, column 18)
;
; The dragon's picture code ($8880, every pass in room 8) draws it with
; DrawRowPicture $89A4 while the dragon lives (the hits counter $FE4D under
; $0F), then paints its colours DragonAttributes. Read in rzx-r3 (all 408
; bytes).
DragonPicture:
  INCBIN "res/stage3/rowpicture-dragon.bin",$0000,408

; 6 bytes past the picture's 69th line that no code reads (read in neither
; recording)
DragonPictureEnd:
  DEFB $11,$80,$11,$80,$11,$80

; The dragon's colours: 9 rows of 9 attributes ($FF: leave the cell), copied
; into the shadow at $6E92
;
; The dragon's picture code ($88A3) copies them, or ($88D2) paints them red for
; one pass after a hit ($FE4E). Read in rzx-r3 (all 81 bytes).
DragonAttributes:
  INCBIN "res/stage3/table-dragon-attributes.bin",$0000,81

; The dragon's head: 4 frames of 4 bytes x 27 lines, the jaws from shut to wide
; open
;
; SetActorFrame call at $930F (kind 5, DragonHeadActor $92BF; DragonHeadSet
; $9312) with the frame table DragonHeadFrameTable. The frames are one after
; another; the byte after them ($CCC0) is a stray, so the table is not right
; after them and the set is kept as bitmaps and a table. Read in rzx-r3 (all
; 432 bytes).
DragonHeadSprites:
  INCBIN "res/stage3/bitmaps-dragon-head-4x27.bin",$0000,432

; One zero byte between the head's frames and its table that no frame covers
; and no code reads (read in neither recording)
DragonHeadStray:
  DEFB $00

; The dragon head's 4 frame records (dx, dy, width, height, offset from
; DragonHeadSprites)
;
; Read in rzx-r3 (all 24 bytes).
DragonHeadFrameTable:
  INCBIN "res/stage3/table-dragon-head-frames.bin",$0000,24

; The dragon's breath: 7 frames of a cloud of fire, from a puff (3 x 16) to the
; full cloud (6 x 44) and its last sparks
;
; SetActorFrame call at $9362 (kind 6, DragonFlameActor $9329; DragonFlameSet
; $9365). Read in rzx-r3 (all 989 bytes).
BreathSprites:
  INCBIN "res/stage3/sprites-breath.bin",$0000,947
BreathFrameTable:
  INCBIN "res/stage3/sprites-breath.bin",$03B3,42

; The troll: 7 frames, its legs walking (frames 0-3, 2 x 10-11) and its body
; with the club (4 club down, 5 and 6 the swing)
;
; SetActorFrame call at $90B2 (TrollFrame $90AF, for TrollLegsActor $9003 and
; TrollBodyActor $90C6; TrollFrameSet $90B5). Read in rzx-r3 (198 of 430 bytes:
; the small frames).
TrollSprites:
  INCBIN "res/stage3/sprites-troll.bin",$0000,388
TrollFrameTable:
  INCBIN "res/stage3/sprites-troll.bin",$0184,42

; The throne giant's fireball: four frames of 2 bytes x 8 lines
; (ThroneShotFrames $8170)
;
; Read by UpdateThroneShot ($8160) in rzx-r3 (all 64 bytes).
FireballSprites:
  INCBIN "res/stage3/bitmaps-fireball-2x8.bin",$0000,64

; A shot: 2 bytes x 5 lines (the shot frames table $80A4's first record)
;
; The shots' pictures, table $80A4: this one, two of 1 x 15 and two of 2 x 13,
; by direction. rzx-r3 reads only this one (10 bytes); the other four are known
; only from the code ($80A4).
ShotSmall:
  INCBIN "res/stage3/bitmaps-shot-small-2x5.bin",$0000,10

; Two shots of 1 byte x 15 lines (the ones flying up and down)
ShotUpright:
  INCBIN "res/stage3/bitmaps-shot-upright-1x15.bin",$0000,30

; Two shots of 2 bytes x 13 lines (the slanted ones)
ShotSlanted:
  INCBIN "res/stage3/bitmaps-shot-slanted-2x13.bin",$0000,52

; The thrown object: four frames of 1 byte x 4 lines, smallest last
; (ThrownAmmoFrames $805E: 9 records, frames 3, 2, 1, 0, then 0)
;
; Read by UpdateThrownAmmo ($8025) in rzx-r3 (all 16 bytes).
ThrownAmmoSprites:
  INCBIN "res/stage3/bitmaps-thrown-ammo-1x4.bin",$0000,16

; The water's surface (kind 4): 16 bytes, 4 bytes a line; a frame is 4 x 2
; lines from $D310, $D314 or $D318 (3 frames 4 bytes apart, overlapping)
;
; $928E steps the frame 0-2 every second pass and points +4/+5 at $D310 + 4 x
; the frame. Read in rzx-r3 and s3-right (all 16 bytes).
WaterRipple:
  INCBIN "res/stage3/bitmaps-water-4x4.bin",$0000,16

; 8 bytes past the ripple's frames that no code reads (the last frame ends at
; $D31F; read in neither recording)
WaterRippleEnd:
  DEFB $11,$11,$11,$11,$40,$40,$40,$40

; GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep
; $83F2)
;
; Read in s3-right (all 64 bytes: its game over); rzx-r3 has none.
GameOverPicture:
  INCBIN "res/stage3/bitmaps-game-over-8x8.bin",$0000,64

; The Viking warrior (a horned helmet, a round shield and an axe): 18 frames
; (stand, walk, block, strike, hit, death)
;
; SetActorFrame call at $8E9D (VikingFrame $8E9A, VikingFrameSet $8EA0) for
; VikingActor $8C64.
;
; Read in rzx-r3 (1129 of 1273 bytes) and s3-right (992).
VikingSprites:
  INCBIN "res/stage3/sprites-viking.bin",$0000,1165
VikingFrameTable:
  INCBIN "res/stage3/sprites-viking.bin",$048D,108

; The bog man: 20 frames, rising out of the swamp, wading and sinking flat
;
; SetActorFrame call at $9208 (BogManFrame $9203, BogManFrameSet $920B) for
; BogManActor $91AD.
;
; Read in rzx-r3 (all 1642 bytes).
BogManSprites:
  INCBIN "res/stage3/sprites-bog-man.bin",$0000,1522
BogManFrameTable:
  INCBIN "res/stage3/sprites-bog-man.bin",$05F2,120

; A piece of the stage's artefact: 10 frames; the first two (2 x 14) are also
; the HUD's piece pictures
;
; ShowPieceTaken copies $DECB (the first piece) or $DEE7 (the others) to the
; HUD. Read in rzx-r3 (286 of 292 bytes) and s3-right (258).
PieceSprites:
  INCBIN "res/stage3/sprites-piece.bin",$0000,28
PieceSprite1:
  INCBIN "res/stage3/sprites-piece.bin",$001C,204
PieceFrameTable:
  INCBIN "res/stage3/sprites-piece.bin",$00E8,60

; The urns and chests: 8 frames, two of each (whole, cracked) for the kinds 0-3
; (StrikeableActor $A9C2)
;
; Read in rzx-r3 (all 250 bytes).
StrikeableSprites:
  INCBIN "res/stage3/sprites-strikeable.bin",$0000,202
StrikeableFrameTable:
  INCBIN "res/stage3/sprites-strikeable.bin",$00CA,48

; The hero's strikes with a hammer: 4 frames
;
; Read in rzx-r3 and s3-right (all 309 bytes).
HeroStrikeSprites:
  INCBIN "res/stage3/sprites-hero-strike.bin",$0000,285
HeroStrikeFrameTable:
  INCBIN "res/stage3/sprites-hero-strike.bin",$011D,24

; The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar draws Energy
; / 8 of them on 6 lines)
;
; Read in rzx-r3 and s3-right.
EnergyBarPattern:
  INCBIN "res/stage3/bitmaps-energy-bar-6x1.bin",$0000,6

; The hero's jump: 19 frames
;
; Read in rzx-r3 and s3-right (all 1020 bytes).
HeroJumpSprites:
  INCBIN "res/stage3/sprites-hero-jump.bin",$0000,906
HeroJumpFrameTable:
  INCBIN "res/stage3/sprites-hero-jump.bin",$038A,114

; The hero walking and standing: 13 frames
;
; Read in rzx-r3 and s3-right (all 728 bytes).
HeroWalkSprites:
  INCBIN "res/stage3/sprites-hero-walk.bin",$0000,650
HeroWalkFrameTable:
  INCBIN "res/stage3/sprites-hero-walk.bin",$028A,78

; A fragment of a broken urn: 8 copies of 3 bytes x 11 lines, shifted 0-7
; pixels ($E8F8 + 33 x shift)
;
; Read in rzx-r3 (all 264 bytes).
FragmentSprites:
  INCBIN "res/stage3/bitmaps-fragment-3x11.bin",$0000,264

; The item icons: 9 of 2 bytes x 16 lines (the first item kind 2's), for the
; HUD's strip and the items on the floor (ItemIcons $7F2F; kind 4 is BlankIcon
; $8A44)
;
; DrawItemIcon and the item actors. Read in rzx-r3 (all 288 bytes) and s3-right
; (64).
ItemIconSprites:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$0000,32
ItemIconKind6:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$0020,32
ItemIconKind9:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$0040,32
ItemIconKind3:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$0060,32
ItemIconKind7:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$0080,32
ItemIconKind5:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$00A0,32
ItemIconKind0:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$00C0,32
ItemIconKind8:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$00E0,32
ItemIconKind1:
  INCBIN "res/stage3/bitmaps-item-icons-2x16.bin",$0100,32

; The drifting shots: 4 frames of 3 bytes x 13 lines (the frame words at $B4B9)
;
; Read in s3-right (78 of 156 bytes); not in rzx-r3.
DriftShotSprites:
  INCBIN "res/stage3/bitmaps-drift-shots-3x13.bin",$0000,39
DriftShot1:
  INCBIN "res/stage3/bitmaps-drift-shots-3x13.bin",$0027,39
DriftShot2:
  INCBIN "res/stage3/bitmaps-drift-shots-3x13.bin",$004E,39
DriftShot3:
  INCBIN "res/stage3/bitmaps-drift-shots-3x13.bin",$0075,39

; The hero's leaps (back and up): 14 frames
;
; Read in rzx-r3 (434 of 765 bytes); not in s3-right.
HeroLeapSprites:
  INCBIN "res/stage3/sprites-hero-leap.bin",$0000,681
HeroLeapFrameTable:
  INCBIN "res/stage3/sprites-hero-leap.bin",$02A9,84

; The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst:
; BurstGlyphs[...] x 8 + $EEB9)
;
; Read in rzx-r3 (all 32 bytes).
ParticleGlyphs:
  INCBIN "res/stage3/bitmaps-particles-1x8.bin",$0000,32

; The glyph (0-3) of each burst step, indexed by the step + a random 0-3 (35
; bytes)
;
; Read in rzx-r3 (31 of 35 bytes).
BurstGlyphs:
  INCBIN "res/stage3/table-burst-glyphs.bin",$0000,35

; 6 rows of 32 indices into the burst's step table: each particle direction's
; step at each burst step
;
; Read in rzx-r3 (177 of 192 bytes).
BurstDirections:
  INCBIN "res/stage3/table-burst-directions.bin",$0000,192

; The shapes a burst breaks up: 62 bytes, 2 bytes a line; each start reads 2 x
; 12 lines from its address
;
; The shapes are read from $EFBC ($A064), $EFCA ($9FEF: 14 bytes on,
; overlapping the first's zero tail) and $EFE2 (the dragon's and the figure's
; last hits, $A01E, $A039). Read in rzx-r3 (all 62 bytes).
BurstShapes:
  INCBIN "res/stage3/bitmaps-burst-shapes-2x31.bin",$0000,14
BurstShape2:
  INCBIN "res/stage3/bitmaps-burst-shapes-2x31.bin",$000E,24
BurstShapeBoss:
  INCBIN "res/stage3/bitmaps-burst-shapes-2x31.bin",$0026,24

; 69 zero bytes to the block's end ($F03E) that no code reads (rzx-r3,
; s3-right; known only from the code)
BlockEnd:
  DEFS $45
