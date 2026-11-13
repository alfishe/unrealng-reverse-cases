; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The stage's sprites, pictures and their frame tables
;
; Every animated actor shows frames of a sprite set: the bitmaps, then a frame table of 6-byte records (dx, dy, the
; width in bytes, the height in lines, the bitmap's offset from the set's start). SetActorFrame $AC52 takes the frame
; number in A and the table and the set from the four bytes after its CALL (or from a word pair such as StatueSet
; $A714). The other pictures are plain 1-bit frames read through their addresses: the shots, the hydra's heads, necks
; and body, the harpy's body, the item icons, the drifting shots, the burst's glyphs and shapes.
;
; The layout follows stage 1's (shots, game over, the urns, the hero's strikes, the energy bar, the hero's jump and
; walk, the fragments, the pieces, the item icons, the drifting shots, the hero's leap, the burst tables), with stage
; 2's own sets between: the spirit, the pool's ripple, the hydra's necks, heads and body, Medusa, the harpy and its
; wings, lamp and rise, the statues, the sparkle, the pool and the drops. The block ends with 301 zero bytes. Every
; file is under src/res/stage2/ (README.md there).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C3D5

; The spirit: 8 frames, growing out of the floor (0-5) and flapping (6, 7)
; (SpiritActor $9028)
;
; SpiritFrameSet $9050 (SetActorFrame's inline words). All 507 bytes read in
; s2-right and rzx-r2.
SpiritSprites:
  INCBIN "res/stage2/sprites-spirit.bin",$0000,459
SpiritFrameTable:
  INCBIN "res/stage2/sprites-spirit.bin",$01CB,48

; A shot: 2 bytes x 5 lines (ShotFrames $82CD's first record)
;
; The spirits' shots (UpdateAimedShot), ShotFrames $82CD: this one, two of 1 x
; 15 and two of 2 x 13, by direction. Read in s2-right and rzx-r2.
ShotSmall:
  INCBIN "res/stage2/bitmaps-shot-small-2x5.bin",$0000,10

; Two shots of 1 byte x 15 lines (the ones flying up and down)
;
; Not read in the recordings checked (s2-right, rzx-r2): SpiritShotDirections
; $90EF has no straight up or down; known only from the code (ShotFrames).
ShotUpright:
  INCBIN "res/stage2/bitmaps-shot-upright-1x15.bin",$0000,30

; Two shots of 2 bytes x 13 lines (the slanted ones)
;
; Read in s2-right and rzx-r2.
ShotSlanted:
  INCBIN "res/stage2/bitmaps-shot-slanted-2x13.bin",$0000,52

; The pool's ripple: 3 frames of 4 bytes x 2 lines (WaterActor $8782: $C62C +
; frame x 8)
;
; Read whole in s2-right and rzx-r2.
RippleSprites:
  INCBIN "res/stage2/bitmaps-ripple-4x2.bin",$0000,24

; GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep
; $8585)
;
; Read whole in s2-right (its game over); not in rzx-r2.
GameOverPicture:
  INCBIN "res/stage2/bitmaps-game-over-8x8.bin",$0000,64

; A segment of a hydra's neck: 8 copies of 2 bytes x 8 lines, shifted 0-7
; pixels (OrNeckSegment $A066)
;
; DrawNeckHighLoop ($9FEC) and DrawNeckLow ($A0DB) point BC at $C684 + 16 x the
; shift. 124 of the 128 bytes read in rzx-r2; not in s2-right (no hydra).
NeckSegments:
  INCBIN "res/stage2/bitmaps-hydra-neck-2x8.bin",$0000,128

; The urns: 8 frames, two of each (whole, cracked) for the kinds 16-19
; (StrikeableActor $A9B8)
;
; StrikeableSet $A9F1. Read whole in rzx-r2 (152 of 250 bytes in s2-right).
StrikeableSprites:
  INCBIN "res/stage2/sprites-strikeable.bin",$0000,202
StrikeableFrameTable:
  INCBIN "res/stage2/sprites-strikeable.bin",$00CA,48

; The hero's strikes: 11 frames (low, middle, high)
;
; HeroStrikeLowSet $AF82, HeroStrikeMidSet $AFC4, HeroStrikeHighSet $B000. Read
; whole in rzx-r2 (583 of 767 bytes in s2-right).
HeroStrikeSprites:
  INCBIN "res/stage2/sprites-hero-strike.bin",$0000,701
HeroStrikeFrameTable:
  INCBIN "res/stage2/sprites-hero-strike.bin",$02BD,66

; The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar $9DC2 draws
; Energy / 8 of them on 6 lines)
;
; Read in s2-right and rzx-r2 (three of the six bytes: the bar never runs out
; in them).
EnergyBarPattern:
  INCBIN "res/stage2/bitmaps-energy-bar-6x1.bin",$0000,6

; The hero's jump: 19 frames (HeroJumpSet $B1F3)
;
; Read whole in s2-right and rzx-r2.
HeroJumpSprites:
  INCBIN "res/stage2/sprites-hero-jump.bin",$0000,953
HeroJumpFrameTable:
  INCBIN "res/stage2/sprites-hero-jump.bin",$03B9,114

; The hero walking and standing: 13 frames (HeroWalkSet $B0DE, HeroStandSet
; $AEDD; frame 12 stands)
;
; Read whole in s2-right and rzx-r2.
HeroWalkSprites:
  INCBIN "res/stage2/sprites-hero-walk.bin",$0000,714
HeroWalkFrameTable:
  INCBIN "res/stage2/sprites-hero-walk.bin",$02CA,78

; 30 bytes between the walk set's frame table and FragmentSprites that no code
; reads
;
; No instruction or table points into them and the recordings checked
; (s2-right, rzx-r2) read none; known only from the code. A leftover of the
; graphics block (stage 1 has no such gap here).
GraphicsLeftover:
  DEFB $00,$00,$07,$A0,$1F,$50,$22,$88,$41,$04,$01,$00,$42,$8C,$3C,$58
  DEFB $0D,$20,$07,$40,$0C,$A0,$0D,$A0,$00,$40,$00,$00,$00,$20

; A fragment of a broken statue: 8 copies of 3 bytes x 11 lines, shifted 0-7
; pixels (MoveFragment $ABA2: $D264 + 33 x shift)
;
; Read whole in rzx-r2 (the statues broken); not in s2-right.
FragmentSprites:
  INCBIN "res/stage2/bitmaps-fragment-3x11.bin",$0000,264

; Medusa: 7 frames, the statue, her head looking about and lying
; (MedusaSetFrame $81C8)
;
; MedusaFrameSet $81CB (SetActorFrame's inline words). Read whole in rzx-r2;
; not in s2-right (it never reaches grid 2).
MedusaSprites:
  INCBIN "res/stage2/sprites-medusa.bin",$0000,359
MedusaFrameTable:
  INCBIN "res/stage2/sprites-medusa.bin",$0167,42

; A spinning shot: 11 frames of 1 byte x 12 lines, spinning up (0-4), flying
; (5), breaking up (5-10)
;
; DrawFloorShot $B5C6 (Medusa's head's shot) and DrawHeroMissile $B5E3 (item
; 6's missile): $D4FD + 12 x frame. 108 of 132 bytes read in rzx-r2; not in
; s2-right.
SpinShotSprites:
  INCBIN "res/stage2/bitmaps-spin-shot-1x12.bin",$0000,132

; A hydra head: 3 frames of 3 bytes x 22 lines, by its pose (PlaceHydraHead
; $8100: from $D605, the last frame, back 66 bytes a frame)
;
; Read whole in rzx-r2; not in s2-right.
HydraHeadSprites:
  INCBIN "res/stage2/bitmaps-hydra-head-3x22.bin",$0000,198

; The harpy's body: 3 frames of 4 bytes x 28 lines (HarpyAttackFrames $8EBF;
; HarpyTemplate's frame)
;
; Read whole in s2-right and rzx-r2.
HarpySprites:
  INCBIN "res/stage2/bitmaps-harpy-4x28.bin",$0000,112
HarpySprite1:
  INCBIN "res/stage2/bitmaps-harpy-4x28.bin",$0070,112
HarpySprite2:
  INCBIN "res/stage2/bitmaps-harpy-4x28.bin",$00E0,112

; The harpy's wings: 5 frames (HarpyWingsActor $8DD2)
;
; HarpyWingsFrameSet $8DE4. Read whole in s2-right and rzx-r2.
HarpyWingsSprites:
  INCBIN "res/stage2/sprites-harpy-wings.bin",$0000,434
HarpyWingsFrameTable:
  INCBIN "res/stage2/sprites-harpy-wings.bin",$01B2,30

; The hydra's body: a row-packed picture of 112 lines (each a byte LEN x 16 +
; SKIP, then LEN bytes), drawn in rooms 7 and 3
;
; DrawHydraBody $9E21 draws it with DrawRowPicture $8B2A while the hydra lives:
; all 112 lines in room 7 from the buffer address $5C12, its top 48 lines at
; the bottom of room 3 from $6712. All 986 bytes read in rzx-r2; not in
; s2-right.
HydraBodyPicture:
  INCBIN "res/stage2/rowpicture-hydra.bin",$0000,986

; A piece of the stage's artefact: 10 frames (UpdatePieceActor $842E); the
; first two (2 x 14) are also the HUD's piece pictures
;
; ShowPieceTaken copies $DD41 (the first piece) or $DD5D (the others) to the
; HUD. PieceFrames $846E. 286 of 292 bytes read in rzx-r2, 258 in s2-right.
PieceSprites:
  INCBIN "res/stage2/sprites-piece.bin",$0000,28
PieceSprite1:
  INCBIN "res/stage2/sprites-piece.bin",$001C,204
PieceFrameTable:
  INCBIN "res/stage2/sprites-piece.bin",$00E8,60

; The item icons: 7 of 2 bytes x 16 lines (the first item kind 0's), for the
; HUD's strip and the items on the floor (ItemIcons $7F00)
;
; DrawItemIcon and the item actors (SpawnItem sets the icon as the frame). Kind
; 4's icon is BlankIcon $8BCA outside the block. 192 of 224 bytes read in
; rzx-r2, 96 in s2-right.
ItemIconSprites:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$0000,32
ItemIconKind1:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$0020,32
ItemIconKind3:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$0040,32
ItemIconKind6:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$0060,32
ItemIconKind2:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$0080,32
ItemIconKind5:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$00A0,32
ItemIconKind7:
  INCBIN "res/stage2/bitmaps-item-icons-2x16.bin",$00C0,32

; The statues: 4 frames (KneelingStatueActor $A6EC, WarriorStatueActor $A718)
;
; StatueSet $A714. Read whole in s2-right and rzx-r2.
StatueSprites:
  INCBIN "res/stage2/sprites-statue.bin",$0000,351
StatueFrameTable:
  INCBIN "res/stage2/sprites-statue.bin",$015F,24

; The harpy rising out of its statue: 4 frames (HarpyRiseActor $A7F6)
;
; HarpyRiseSet $A879. Read whole in s2-right and rzx-r2.
HarpyRiseSprites:
  INCBIN "res/stage2/sprites-harpy-rise.bin",$0000,341
HarpyRiseFrameTable:
  INCBIN "res/stage2/sprites-harpy-rise.bin",$0155,24

; The lamp, its flame and the extra life: 22 frames (HarpyLampActor $A7E2,
; HarpyFlameActor $A760, ExtraLifeActor $9AFA frames 18-21)
;
; HarpyLampSet $A7F2. 271 of 938 bytes read in rzx-r2, 183 in s2-right: most
; frames are never shown in them.
HarpyLampSprites:
  INCBIN "res/stage2/sprites-harpy-lamp.bin",$0000,806
HarpyLampFrameTable:
  INCBIN "res/stage2/sprites-harpy-lamp.bin",$0326,132

; The sparkle of a life taken: 6 frames (SparkleActor $9B4F)
;
; SparkleSet $9B5D. Read whole in rzx-r2; not in s2-right.
SparkleSprites:
  INCBIN "res/stage2/sprites-sparkle.bin",$0000,37
SparkleFrameTable:
  INCBIN "res/stage2/sprites-sparkle.bin",$0025,36

; The bubbling pool's surface: 18 frames (PoolActor $ABF2)
;
; PoolSet $AC34. 576 of 636 bytes read in rzx-r2; not in s2-right (no pool in
; grid 0's first rooms).
PoolSprites:
  INCBIN "res/stage2/sprites-pool.bin",$0000,528
PoolFrameTable:
  INCBIN "res/stage2/sprites-pool.bin",$0210,108

; The drifting shots: 4 frames of 3 bytes x 13 lines (ImageDescriptors $B6DD
; 0-3, UpdateDriftLeft $B639)
;
; Read whole in s2-right and rzx-r2.
DriftShotSprites:
  INCBIN "res/stage2/bitmaps-drift-shots-3x13.bin",$0000,39
DriftShot1:
  INCBIN "res/stage2/bitmaps-drift-shots-3x13.bin",$0027,39
DriftShot2:
  INCBIN "res/stage2/bitmaps-drift-shots-3x13.bin",$004E,39
DriftShot3:
  INCBIN "res/stage2/bitmaps-drift-shots-3x13.bin",$0075,39

; A drifting shot fading on the ground: 5 frames of 3 bytes x 8 lines
; (ImageDescriptors 4-8)
;
; Read whole in s2-right and rzx-r2.
DriftFadeSprites:
  INCBIN "res/stage2/bitmaps-drift-fade-3x8.bin",$0000,24
DriftFade1:
  INCBIN "res/stage2/bitmaps-drift-fade-3x8.bin",$0018,24
DriftFade2:
  INCBIN "res/stage2/bitmaps-drift-fade-3x8.bin",$0030,24
DriftFade3:
  INCBIN "res/stage2/bitmaps-drift-fade-3x8.bin",$0048,24
DriftFade4:
  INCBIN "res/stage2/bitmaps-drift-fade-3x8.bin",$0060,24

; The hero's leaps (back and up): 14 frames (HeroLeapSet $B230)
;
; 476 of 826 bytes read in rzx-r2; not in s2-right.
HeroLeapSprites:
  INCBIN "res/stage2/sprites-hero-leap.bin",$0000,742
HeroLeapFrameTable:
  INCBIN "res/stage2/sprites-hero-leap.bin",$02E6,84

; The drop: 13 frames, falling and splashing (DropActor $A929)
;
; DropSet $A990. 186 of 193 bytes read in s2-right and rzx-r2.
DropSprites:
  INCBIN "res/stage2/sprites-drop.bin",$0000,115
DropFrameTable:
  INCBIN "res/stage2/sprites-drop.bin",$0073,78

; The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst $9C92:
; BurstGlyphs[...] x 8 + $EDA7)
;
; Read whole in rzx-r2; not in s2-right (no burst in it).
ParticleGlyphs:
  INCBIN "res/stage2/bitmaps-particles-1x8.bin",$0000,32

; The glyph (0-3) of each burst step, indexed by the step + a random 0-3 (35
; bytes)
;
; Read by UpdateBurst ($9CAE): 31 of 35 in rzx-r2.
BurstGlyphs:
  INCBIN "res/stage2/table-burst-glyphs.bin",$0000,35

; 6 rows of 32 indices into BurstSteps $9D9A: each particle direction's step at
; each burst step
;
; Read by UpdateBurst ($9CE6): 179 of 192 in rzx-r2.
BurstDirections:
  INCBIN "res/stage2/table-burst-directions.bin",$0000,192

; The shapes a burst breaks up: 2 bytes x 12 lines read from six overlapping
; addresses (StartBurst $9BFA reads 24 bytes from the shape's address)
;
; $EEAA (CutHydraHead1-3), $EEB8 (MedusaStruck $8138, UnusedBurst $9B82), $EECA
; (BreakStatue0 / 1), $EEE2 (ScoreBurst20 $99E1, BurstSpirit $9B92), $EEEE
; (HydraDefeated, room 3), $EEFA (HydraDefeated, room 7): 104 bytes in all,
; which the file shows as 4 frames of 24 bytes and 8 bytes left over. Read
; whole in rzx-r2; not in s2-right.
BurstShapes:
  INCBIN "res/stage2/bitmaps-burst-shapes-2x12.bin",$0000,14
BurstShapeMedusa:
  INCBIN "res/stage2/bitmaps-burst-shapes-2x12.bin",$000E,18
BurstShapeStatue:
  INCBIN "res/stage2/bitmaps-burst-shapes-2x12.bin",$0020,24
BurstShape20:
  INCBIN "res/stage2/bitmaps-burst-shapes-2x12.bin",$0038,12
BurstShapeHydraTop:
  INCBIN "res/stage2/bitmaps-burst-shapes-2x12.bin",$0044,12
BurstShapeHydraBody:
  INCBIN "res/stage2/bitmaps-burst-shapes-2x12.bin",$0050,24

; 301 zero bytes to the block's end ($F03E) that no code reads (s2-right,
; rzx-r2; known only from the code)
BlockEnd:
  DEFS $012D
