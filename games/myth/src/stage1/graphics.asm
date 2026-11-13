; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The stage's sprites, pictures and their frame tables
;
; Every animated actor shows frames of a sprite set: the bitmaps, then a frame table of 6-byte records (dx, dy, the
; width in bytes, the height in lines, the bitmap's offset from the set's start). SetActorFrame $AA02 takes the frame
; number in A and the table's and the set's addresses from the four bytes after its CALL, and fills the actor's +0/+1
; (+$0D + dx, negated when the actor faces left, and +$0E + dy), +2/+3 and +4/+5. A bitmap is 1 bit a pixel, the rows
; top first, no mask; DrawActorSprite $A6AA ORs it into the play buffer through the row plotters (RowPlotters $8910),
; mirrored through the resident bit-reversal table $FA00 when the actor faces left; DrawSprite $B42B copies a picture
; with LDIR. Each set's bitmaps are exactly the bytes its frames cover, and its table follows them: so each set is one
; resource (sprites-NAME.png with the table in its text chunk). The plain pictures (shots, icons, the boss's parts)
; are bitmaps-NAME-WxH.png, frames of one size one after another.
;
; The sets: the hero's walk, jump, leap and strikes; the urns and chests; the pieces of the artefact; the warriors
; (stage 1: skeletons) and their collapse; the statue heads; the hanging bodies; the flame jets and fire pits; the
; gate and the bridge slab; the dragon's head with its body picture and the winged demon's wings, body and head with
; the face over its lair. What no stage-1 recording reads (the demon, the dragon, the shots, the bridge, the fire pit)
; is named from the code that reads it.
; --------------------------------------------------------------------------------------------------------------------

; The bridge slab: 4 bytes x 8 lines (BridgeSlabTemplate's frame; the demon's
; beaten wing lays it, BridgeSlabActor $90A3)
;
; Not read in the stage-1 recordings (none reaches the demon); known only from
; the code ($9D27, the template's +4).
BridgeSlabSprite:
  INCBIN "res/stage1/bitmaps-bridge-slab-4x8.bin",$0000,32

; The fire pit's flames: 6 frames of 2 bytes x 12-14 lines (FirePitActor $8D6D
; shows 0-3)
;
; Not read in the stage-1 recordings; known only from the code (FirePitFrames
; $8DC6).
FirePitSprites:
  INCBIN "res/stage1/sprites-fire-pit.bin",$0000,156
FirePitFrameTable:
  INCBIN "res/stage1/sprites-fire-pit.bin",$009C,36

; The flame jet: 13 frames of 2 bytes x 3-22 lines, from a flicker to a column
; of flame and back (FlameJetActor $8DCC)
;
; Read in all four stage-1 builds (FlameJetFrames $8E3D).
FlameJetSprites:
  INCBIN "res/stage1/sprites-flame-jet.bin",$0000,340
FlameJetFrameTable:
  INCBIN "res/stage1/sprites-flame-jet.bin",$0154,78

; The hanging body: 8 frames of 2 bytes x 37 lines, the rope above
; (HangingActor $9186 points +4/+5 into it itself, $91CB and $91E4)
;
; Read in all four stage-1 builds.
HangingSprites:
  INCBIN "res/stage1/bitmaps-hanging-2x37.bin",$0000,592

; A shot: 2 bytes x 5 lines (ShotFrames $813D's first record)
;
; The shots' pictures, ShotFrames $813D: this one, two of 1 x 15 and two of 2 x
; 13, by direction (ShotDirections $8151). Not read in the stage-1 recordings;
; known only from the code.
ShotSmall:
  INCBIN "res/stage1/bitmaps-shot-small-2x5.bin",$0000,10

; Two shots of 1 byte x 15 lines (the ones flying up and down)
ShotUpright:
  INCBIN "res/stage1/bitmaps-shot-upright-1x15.bin",$0000,30

; Two shots of 2 bytes x 13 lines (the slanted ones)
ShotSlanted:
  INCBIN "res/stage1/bitmaps-shot-slanted-2x13.bin",$0000,52

; The warrior (stage 1: a skeleton with a sword and a shield): 21 frames (rise,
; stand, walk, block, strike)
;
; WarriorSetFrame $9766 (WarriorFrames $9769). Read in all four stage-1 builds
; (1628 of its bytes; the frames not shown are the rising ones' tops).
WarriorSprites:
  INCBIN "res/stage1/sprites-warrior.bin",$0000,1589
WarriorFrameTable:
  INCBIN "res/stage1/sprites-warrior.bin",$0635,126

; GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep
; $836D)
;
; Read in the stage-1 builds (all 64 bytes: the game over of the deaths
; recording).
GameOverPicture:
  INCBIN "res/stage1/bitmaps-game-over-8x8.bin",$0000,64

; The dragon's head: 2 frames, the mouth closed (6 bytes x 40 lines) and open
; (7 x 38) (ArenaHeadActor $90E7)
;
; Not read in the stage-1 recordings (none reaches the arena); known only from
; the code (ArenaHeadFrames $911F).
ArenaHeadSprites:
  INCBIN "res/stage1/sprites-arena-head.bin",$0000,506
ArenaHeadFrameTable:
  INCBIN "res/stage1/sprites-arena-head.bin",$01FA,12

; The dragon's body: a row-packed picture of 92 lines (each a byte LEN x 16 +
; SKIP, then LEN bytes), drawn from buffer row 4, column 14
;
; DrawArenaPicture $89BB draws it into the play buffer every pass with
; DrawRowPicture $8B03 while the dragon lives (ArenaBossBeaten), then its
; colours ArenaAttributes. Not read in the stage-1 recordings; known only from
; the code.
ArenaPicture:
  INCBIN "res/stage1/rowpicture-arena.bin",$0000,1078

; 7 bytes past the picture's 92nd line that no code reads (known only from the
; code: DrawArenaPicture draws 92 lines)
ArenaPictureEnd:
  DEFB $80,$11,$80,$11,$80,$11,$80

; The dragon's colours: 12 rows of 16 attributes (0: leave the cell), copied
; into the shadow at $6E4E
;
; DrawArenaPicture $89BB, or painted red where non-zero while ArenaFlash. Known
; only from the code.
ArenaAttributes:
  INCBIN "res/stage1/table-arena-attributes.bin",$0000,192

; The demon's face over its lair (room 12): a row-packed picture of 53 lines,
; drawn from buffer column 9
;
; DrawRoomPicture $8930 draws it every pass in room 12, its two eyes flashing
; (EyeFlashColours). Not read in the stage-1 recordings; known only from the
; code.
RoomPicture:
  INCBIN "res/stage1/rowpicture-room.bin",$0000,843

; 6 bytes past the picture's 53rd line that no code reads (known only from the
; code)
RoomPictureEnd:
  DEFB $1E,$01,$1E,$01,$1E,$01

; A thrown object: 8 frames of 2 bytes x 6 lines (stage 1: a turning skull),
; drawn by the missile kinds 2 and 3 (ArcFrame $8090: frame x 12)
;
; Not read in the stage-1 recordings; known only from the code.
ThrownSprites:
  INCBIN "res/stage1/bitmaps-thrown-2x6.bin",$0000,96

; A flat shot: 2 bytes x 8 lines (FlatShotFrame $85C4)
;
; Not read in the stage-1 recordings; known only from the code.
FlatShotSprite:
  INCBIN "res/stage1/bitmaps-flat-shot-2x8.bin",$0000,16

; The bouncing shot: 2 frames of 2 bytes x 13 lines (BounceFrames $863D)
;
; Read in all four stage-1 builds (DrawSprite $B42B).
BounceSprites:
  INCBIN "res/stage1/bitmaps-bounce-2x13.bin",$0000,52

; The gate: 1 frame of 2 bytes x 24 lines (GateActor $9065)
;
; Read in all four stage-1 builds (GateFrames $909F).
GateSprites:
  INCBIN "res/stage1/sprites-gate.bin",$0000,48
GateFrameTable:
  INCBIN "res/stage1/sprites-gate.bin",$0030,6

; The statue head: 3 frames of 3 bytes x 31-32 lines (StatueActor $912B)
;
; Read in all four stage-1 builds (StatueFrames $917C).
StatueSprites:
  INCBIN "res/stage1/sprites-statue.bin",$0000,282
StatueFrameTable:
  INCBIN "res/stage1/sprites-statue.bin",$011A,18

; The warrior falling apart: 14 frames, from the body to a few sparks
; (WarriorCollapse $9705)
;
; Not read in the stage-1 recordings (WarriorCollapseFrames $9719); known only
; from the code.
WarriorCollapseSprites:
  INCBIN "res/stage1/sprites-warrior-collapse.bin",$0000,617
WarriorCollapseFrameTable:
  INCBIN "res/stage1/sprites-warrior-collapse.bin",$0269,84

; The winged demon's wing: 3 bytes x 33 lines (BossWingLeft $8E60, mirrored for
; the right)
;
; Not read in the stage-1 recordings (none reaches room 12); known only from
; the code.
BossWingSprite:
  INCBIN "res/stage1/bitmaps-boss-wing-3x33.bin",$0000,99

; The demon's body: 2 frames of 6 bytes x 32 lines (BossBodySprite $8FF3: $DE4C
; from the attack's step 10)
;
; Known only from the code.
BossBodySprites:
  INCBIN "res/stage1/bitmaps-boss-body-6x32.bin",$0000,192
BossBodyStill:
  INCBIN "res/stage1/bitmaps-boss-body-6x32.bin",$00C0,192

; The demon's head: 4 frames of 2 bytes x 20 lines, the mouth closed to open
; (BossHeadFrames $8F6D)
;
; Known only from the code.
BossHeadSprites:
  INCBIN "res/stage1/bitmaps-boss-head-2x20.bin",$0000,40
BossHead1:
  INCBIN "res/stage1/bitmaps-boss-head-2x20.bin",$0028,40
BossHead2:
  INCBIN "res/stage1/bitmaps-boss-head-2x20.bin",$0050,40
BossHead3:
  INCBIN "res/stage1/bitmaps-boss-head-2x20.bin",$0078,40

; A piece of the stage's artefact: 10 frames (UpdatePieceActor $8233); the
; first two (2 x 14) are also the HUD's piece pictures
;
; ShowPieceTaken copies $E06C (the first piece) or $E088 (the others) to the
; HUD. Read in all four stage-1 builds (PieceFrames $8275).
PieceSprites:
  INCBIN "res/stage1/sprites-piece.bin",$0000,28
PieceSprite1:
  INCBIN "res/stage1/sprites-piece.bin",$001C,204
PieceFrameTable:
  INCBIN "res/stage1/sprites-piece.bin",$00E8,60

; The urns and chests: 8 frames, two of each (whole, cracked) for the kinds 3-6
; (StrikeableActor $A7C4)
;
; Read in all four stage-1 builds (StrikeableActorSet $A7FF).
StrikeableSprites:
  INCBIN "res/stage1/sprites-strikeable.bin",$0000,202
StrikeableFrameTable:
  INCBIN "res/stage1/sprites-strikeable.bin",$00CA,48

; The hero's strikes: 9 frames (low, middle, high)
;
; HeroStrikeLowSet $AE82, HeroStrikeMidSet $AEC6, HeroStrikeHighSet $AF0C. Read
; in all four stage-1 builds.
HeroStrikeSprites:
  INCBIN "res/stage1/sprites-hero-strike.bin",$0000,381
HeroStrikeFrameTable:
  INCBIN "res/stage1/sprites-hero-strike.bin",$017D,54

; The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar $A3C5 draws
; Energy / 8 of them on 6 lines)
;
; Read in all four stage-1 builds.
EnergyBarPattern:
  INCBIN "res/stage1/bitmaps-energy-bar-6x1.bin",$0000,6

; The hero's jump: 19 frames (HeroJumpSet $B0AF)
;
; Read in all four stage-1 builds.
HeroJumpSprites:
  INCBIN "res/stage1/sprites-hero-jump.bin",$0000,685
HeroJumpFrameTable:
  INCBIN "res/stage1/sprites-hero-jump.bin",$02AD,114

; The hero walking and standing: 13 frames (HeroWalkSet $AFD7, HeroStandSet
; $ADE5; frame 12 stands)
;
; Read in all four stage-1 builds.
HeroWalkSprites:
  INCBIN "res/stage1/sprites-hero-walk.bin",$0000,564
HeroWalkFrameTable:
  INCBIN "res/stage1/sprites-hero-walk.bin",$0234,78

; A fragment of a broken urn: 8 copies of 3 bytes x 11 lines, shifted 0-7
; pixels (FragmentActor $A891: $E9E4 + 33 x shift)
;
; Not read in the stage-1 recordings (no urn breaks in them); known only from
; the code.
FragmentSprites:
  INCBIN "res/stage1/bitmaps-fragment-3x11.bin",$0000,264

; The item icons: 8 of 2 bytes x 16 lines (the first item kind 2's), for the
; HUD's strip and the items on the floor (ItemIcons $7F3B)
;
; DrawItemIcon $7E19 and the item actors (SpawnItem $A098 sets the icon as the
; frame). The stage-1 recordings read two (the kinds 3 and 0 the strip shows).
ItemIconSprites:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$0000,32
ItemIconKind6:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$0020,32
ItemIconKind5:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$0040,32
ItemIconKind3:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$0060,32
ItemIconKind8:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$0080,32
ItemIconKind1:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$00A0,32
ItemIconKind7:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$00C0,32
ItemIconKind0:
  INCBIN "res/stage1/bitmaps-item-icons-2x16.bin",$00E0,32

; The drifting shots: 4 frames of 3 bytes x 13 lines (ImageDescriptors $B3EA,
; DrawDriftShot $83D4)
;
; Read in all four stage-1 builds.
DriftShotSprites:
  INCBIN "res/stage1/bitmaps-drift-shots-3x13.bin",$0000,39
DriftShot1:
  INCBIN "res/stage1/bitmaps-drift-shots-3x13.bin",$0027,39
DriftShot2:
  INCBIN "res/stage1/bitmaps-drift-shots-3x13.bin",$004E,39
DriftShot3:
  INCBIN "res/stage1/bitmaps-drift-shots-3x13.bin",$0075,39

; The hero's leaps (back and up): 14 frames (HeroLeapSet $B0EC)
;
; Read in all four stage-1 builds.
HeroLeapSprites:
  INCBIN "res/stage1/sprites-hero-leap.bin",$0000,394
HeroLeapFrameTable:
  INCBIN "res/stage1/sprites-hero-leap.bin",$018A,84

; The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst:
; BurstGlyphs[...] x 8 + $EE66)
;
; Not read in the stage-1 recordings (no burst in them); known only from the
; code.
ParticleGlyphs:
  INCBIN "res/stage1/bitmaps-particles-1x8.bin",$0000,32

; The glyph (0-3) of each burst step, indexed by the step + a random 0-3
;
; Known only from the code (UpdateBurst $A2B1).
BurstGlyphs:
  INCBIN "res/stage1/table-burst-glyphs.bin",$0000,35

; 6 rows of 32 indices into BurstSteps $A39D: each particle direction's step at
; each burst step
;
; Known only from the code.
BurstDirections:
  INCBIN "res/stage1/table-burst-directions.bin",$0000,192

; The shapes a burst breaks up: 5 frames of 2 bytes x 12 lines (StartBurst
; $A1F3 reads 24 bytes from the shape's address)
;
; The shapes are read from $EF69 (ScoreBurst20 $A065, BurstAtActor $A129),
; $EF85 (ScoreBurst160 $A1CF: 4 bytes into the second frame, so its last 4
; bytes are the third frame's first), $EF99 (BossFlees $A182), $EFB1
; (ScoreBurst64 $A19B) and $EFC9 (ArenaBossHit $A14A). Known only from the
; code.
BurstShapes:
  INCBIN "res/stage1/bitmaps-burst-shapes-2x12.bin",$0000,28
BurstShapeHanging:
  INCBIN "res/stage1/bitmaps-burst-shapes-2x12.bin",$001C,20
BurstShapeBoss:
  INCBIN "res/stage1/bitmaps-burst-shapes-2x12.bin",$0030,24
BurstShapeStatue:
  INCBIN "res/stage1/bitmaps-burst-shapes-2x12.bin",$0048,24
BurstShapeBossHit:
  INCBIN "res/stage1/bitmaps-burst-shapes-2x12.bin",$0060,24

; 94 zero bytes to the block's end ($F03E) that no code reads (the four stage-1
; builds; known only from the code)
BlockEnd:
  DEFS $5E
