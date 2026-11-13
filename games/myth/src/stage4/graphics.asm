; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The stage's sprites, pictures and their frame tables
;
; The stage's graphics $C4A5-$F03E: the sprite sets that SetActorFrame $ABBD reads (two words after its CALL: the
; frame table, the set's base; the frame records 6 bytes: dx, dy, width in bytes, height in lines, the bitmap's offset
; from the base; 1 bit a pixel, rows top first, no mask), the plain bitmaps the code addresses itself, the boss's row-
; packed picture and colours, the burst's tables. Each set's bitmaps are exactly the bytes its frames cover, the table
; right after them. Each entry is a resource in src/res/stage4/ (README.md there).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C4A5

; The boss's face: a row-packed picture of 104 lines (each line a byte LEN x 16
; + SKIP, then LEN bytes)
;
; DrawBossPicture $8F2B draws it with DrawRowPicture $902A into the play buffer
; at $5F17 every pass in grid 8 room 2 while BossPhase is not 2. Read in rzx-r4
; (458 passes); not in s4-right.
BossPicture:
  INCBIN "res/stage4/rowpicture-boss.bin",$0000,494

; The boss picture's 8 x 13 attributes, normal
;
; DrawBossPicture copies them into the shadow at $6E58 (columns $18-$1F, rows
; 10-22). Read in rzx-r4.
BossColours:
  INCBIN "res/stage4/table-boss-colours.bin",$0000,104

; The boss picture's 8 x 13 attributes while BossFlash runs (a hit)
;
; DrawBossPicture, instead of BossColours, while BossFlash is set. Read in
; rzx-r4 (20 hits).
BossHitColours:
  INCBIN "res/stage4/table-boss-hit-colours.bin",$0000,104

; A brazier's flame: 4 frames (BrazierFrames $892D, Brazier $8917)
;
; Read in s4-right and rzx-r4.
BrazierSprites:
  INCBIN "res/stage4/sprites-brazier.bin",$0000,194

; The traps' set: 27 frames: the crumbling slab 0-8, the spikes 9-16, the
; falling column 17-18, the dust 19-24 and two more
;
; The frame table $CB0B with the base $C825 is named by five readers:
; CrumblingSlabFrames $86FB, SwitchedSpikesFrames $873E, FloorSwitchFrames
; $87A8, FallingColumnFrames $888B, ColumnDustFrames $890C. Read in rzx-r4 (and
; the switches' frame in s4-right).
TrapSprites:
  INCBIN "res/stage4/sprites-traps.bin",$0000,904

; The pendulum: 15 frames (PendulumFrames $88C0, Pendulum $888F)
;
; Read in rzx-r4.
PendulumSprites:
  INCBIN "res/stage4/sprites-pendulum.bin",$0000,892

; A shot, 2 bytes x 5 lines (ShotFrames $8098's first record)
;
; ShotFrames' record 0. Read by DrawShotRecord $807C for UpdateHeroShot $80CC
; (C = 0) in rzx-r4 (264 passes); not in s4-right. The other four records
; ($CF33, $CF42, $CF51, $CF6B) serve UpdateAimedShot $803A only.
ShotSmallBitmap:
  INCBIN "res/stage4/bitmaps-shot-small-2x5.bin",$0000,10

; Two shots, 1 byte x 15 lines (ShotFrames)
;
; ShotFrames' records 1 and 2; read by DrawShotRecord $807C only for
; UpdateAimedShot $803A, which no recording ran (the recordings checked:
; s4-right, rzx-r4); known only from the code.
ShotUprightBitmaps:
  INCBIN "res/stage4/bitmaps-shot-upright-1x15.bin",$0000,30

; Two shots, 2 bytes x 13 lines (ShotFrames)
;
; ShotFrames' records 3 and 4; read by DrawShotRecord $807C only for
; UpdateAimedShot $803A, which no recording ran (the recordings checked:
; s4-right, rzx-r4); known only from the code.
ShotSlantedBitmaps:
  INCBIN "res/stage4/bitmaps-shot-slanted-2x13.bin",$0000,52

; The hero's bolt: 3 frames of 2 bytes x 8 lines (HeroBoltFrames $8169)
;
; Read by UpdateHeroBolt in rzx-r4 (the bolts that hurt the boss).
BoltBitmaps:
  INCBIN "res/stage4/bitmaps-bolt-2x8.bin",$0000,48

; The boss's shots: 5 frames of 2 bytes x 8 lines, one a direction
; (HeadShotImages $B604)
;
; Read in rzx-r4.
HeadShotBitmaps:
  INCBIN "res/stage4/bitmaps-head-shots-2x8.bin",$0000,80

; The water's surface: 3 frames of 4 bytes x 2 lines (WaterRipple $8629 at
; $8649: $D005 + 8 x the frame)
;
; Read in s4-right and rzx-r4.
WaterBitmaps:
  INCBIN "res/stage4/bitmaps-water-4x2.bin",$0000,24

; GAME OVER: 8 bytes x 8 lines, drawn in the HUD's item strip (GameOverStep
; $8414 at $8433)
;
; Read in s4-right (the game over).
GameOverPicture:
  INCBIN "res/stage4/bitmaps-game-over-8x8.bin",$0000,64

; The barrier: 5 frames, the block and the pillar at four heights (BarrierSet
; $9711)
;
; Read in s4-right and rzx-r4.
BarrierSprites:
  INCBIN "res/stage4/sprites-barrier.bin",$0000,184

; The mummy: 8 frames of 30 lines (MummySet $93AE, MummyActor $9351)
;
; Read in rzx-r4.
MummySprites:
  INCBIN "res/stage4/sprites-mummy.bin",$0000,828

; The scorpion: 10 frames (ScorpionSet $934D, ScorpionActor $9319)
;
; Read in rzx-r4.
ScorpionSprites:
  INCBIN "res/stage4/sprites-scorpion.bin",$0000,183

; The boss's mouth: 4 frames (BossMouthFrames $8B0E, BossMouth $8AD4)
;
; Read in rzx-r4.
BossMouthSprites:
  INCBIN "res/stage4/sprites-boss-mouth.bin",$0000,152

; The ledges: 5 frames (LedgeFrames $8A1E, BridgeLedgeFormingFrames $8A55,
; BridgeLedgeFrames $8A84)
;
; Read in rzx-r4.
LedgeSprites:
  INCBIN "res/stage4/sprites-ledge.bin",$0000,207

; The altar's disc: 2 bytes x 16 lines (AltarDisc $8931 at $8963)
;
; Read in rzx-r4.
DiscBitmap:
  INCBIN "res/stage4/bitmaps-disc-2x16.bin",$0000,32

; The objects: 9 frames, urns and chests (StrikeableActorSet $A993), frame 7
; the urn and frame 8 the cross of the urn markers (UrnMarkerFrames $8B35)
;
; Read in s4-right and rzx-r4.
ObjectSprites:
  INCBIN "res/stage4/sprites-objects.bin",$0000,246

; The hero's strikes and throw: 16 frames (HeroStrikeLowSet $AFB5,
; HeroStrikeMidSet $AFFC, HeroStrikeHighSet $B046, HeroThrowSet $B092)
;
; Read in s4-right and rzx-r4.
HeroStrikeSprites:
  INCBIN "res/stage4/sprites-hero-strike.bin",$0000,854

; The energy bar's pattern: 6 bytes, one pixel line (DrawEnergyBar $A54D at
; $A57B)
;
; Read in s4-right and rzx-r4.
EnergyBarPattern:
  INCBIN "res/stage4/bitmaps-energy-bar-6x1.bin",$0000,6

; The hero's jump: 19 frames (HeroJumpSet $B25D)
;
; Read in s4-right and rzx-r4.
HeroJumpSprites:
  INCBIN "res/stage4/sprites-hero-jump.bin",$0000,963

; The hero's walk and stand: 13 frames (HeroStandSet $AF11, HeroWalkSet $B17E)
;
; Read in s4-right and rzx-r4.
HeroWalkSprites:
  INCBIN "res/stage4/sprites-hero-walk.bin",$0000,693

; 30 bytes no code reads: a picture of 2 bytes x 15 lines
;
; No instruction or word of the block points into $E159-$E176, and neither
; recording read it (s4-right, rzx-r4); kept as a leftover.
UnreadBitmap:
  INCBIN "res/stage4/bitmaps-unread-2x15.bin",$0000,30

; A fragment: 8 copies of 3 bytes x 11 lines, shifted 0-7 pixels (MoveFragment
; $AB35 at $AB6D: $E177 + 33 x the shift)
;
; Read in s4-right and rzx-r4.
FragmentSprites:
  INCBIN "res/stage4/bitmaps-fragment-3x11.bin",$0000,264

; A piece of the stage's artefact: 10 frames (PieceFrames $82A0); the first two
; also the HUD's piece pictures
;
; Read in rzx-r4 (the pieces) and s4-right (the HUD).
PieceSprites:
  INCBIN "res/stage4/sprites-piece.bin",$0000,28
PieceSprite1:
  INCBIN "res/stage4/sprites-piece.bin",$001C,264

; The item icons: 9 of 2 bytes x 16 lines (ItemIcons $7F75: kinds 9, 8, 3, 2,
; 6, 0, 1, 5, 7 in memory order; kind 4 is BlankIcon)
;
; DrawItemIcon draws them in the HUD's strip and the item window; SpawnItem's
; callers give an item actor its icon (StrikeableKind9 $A997, DropItemKind1
; $A2D0 and the others). Read in s4-right and rzx-r4.
ItemIconBitmaps:
  INCBIN "res/stage4/bitmaps-item-icons-2x16.bin",$0000,288

; Thrown items: 4 frames of 3 bytes x 13 lines (ImageDescriptors $B62D)
;
; Only the first two are read (ImageDescriptors' first two records, the thrown
; item, missile kinds 5 and 6); the other two frames have no reader (known only
; from the code).
ThrownBitmaps:
  INCBIN "res/stage4/bitmaps-thrown-3x13.bin",$0000,156

; 5 frames of 3 bytes x 8 lines (ImageDescriptors' last five records, which no
; code reads)
;
; No reader (known only from the code): ImageDescriptors names them but only
; its first two records are read.
ThrownSmallBitmaps:
  INCBIN "res/stage4/bitmaps-thrown-small-3x8.bin",$0000,120

; The hero's leap: 14 frames (HeroLeapSet $B29A)
;
; Read in s4-right and rzx-r4.
HeroLeapSprites:
  INCBIN "res/stage4/sprites-hero-leap.bin",$0000,601

; 10 bytes no code reads ($00 $00 $00 $00 $05 $02 $00 $00 $00 $00)
;
; No instruction or word of the block points into $E830-$E839; neither
; recording read it.
UnreadE830:
  DEFB $00,$00,$00,$00,$05,$02,$00,$00,$00,$00

; The burst's 4 particle glyphs, 1 byte x 8 lines each (UpdateBurst $A41D:
; BurstGlyphs[...] x 8 + $E83A)
;
; Read in s4-right and rzx-r4.
ParticleGlyphs:
  INCBIN "res/stage4/bitmaps-particles-1x8.bin",$0000,32

; The glyph (0-3) of each burst step, indexed by the step + a random 0-3 (35
; bytes)
;
; Read by UpdateBurst in s4-right and rzx-r4.
BurstGlyphs:
  INCBIN "res/stage4/table-burst-glyphs.bin",$0000,35

; The step lists of the 6 burst directions, 32 bytes each (UpdateBurst: $E87D +
; direction x 32, indexed by the step)
;
; Read by UpdateBurst in s4-right and rzx-r4.
BurstDirections:
  INCBIN "res/stage4/table-burst-directions.bin",$0000,192

; The shape the beaten boss bursts into: 2 bytes x 12 lines (BossBeaten $A24C
; at $A295)
;
; Read in rzx-r4.
BossBurstShape:
  INCBIN "res/stage4/bitmaps-burst-boss-2x12.bin",$0000,24

; 6 bytes after the boss's burst shape that StartBurst never reads (it reads
; 24)
;
; StartBurst reads 24 bytes of BurstBossShapes and stops before these. Not read
; in any recording (the recordings checked: s4-right, rzx-r4); known only from
; the code.
UnreadE955:
  DEFB $06,$00,$04,$00,$00,$00

; Two burst shapes of 2 bytes x 12 lines: $E95B (ScoreBurst20 $A1C8,
; ScoreBurst200 $A221) and $E973 (ScoreBurst80 $A1FB, the mummy)
;
; StartBurst $A385 reads 24 bytes from the shape's address. Read in s4-right
; and rzx-r4.
BurstShapes:
  INCBIN "res/stage4/bitmaps-burst-shapes-2x12.bin",$0000,48

; 1716 zero bytes to the block's end, which no code reads (s4-right, rzx-r4);
; zero as loaded
UnusedE98B:
  DEFS $06B4
