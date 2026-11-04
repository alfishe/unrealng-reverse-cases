; --------------------------------------------------------------------------------------------------------------------
; tables.asm: Lookup tables of the view and the robots: view edges, part sprites, sprite pointers, heights
;
; Small constant tables the view and the movement code index by type. Docs: 06-rendering.md 6.1 (edges), 6.5
; (SpriteTable), 6.6 (PartSpriteTable, PartHeights), 07-objects.md 7.3 / 7.5 (TerrainHeights). Resource: ViewEdgeA /
; ViewEdgeB are src/res/gfx/view-edges.png (see src/res/README.md); the others stay in the source as rows the code
; reads field by field.
;
; Readers: DrawViewBackground / DrawEdgeStrips (the edges), DirectionLoop and ConstructionMenu (PartSpriteTable),
; DrawSprite through TableWord (SpriteTable, index id x 2 + parity), DirectionLoop and SpawnHeightLoop (PartHeights),
; TerrainTop (TerrainHeights). None is written.
; --------------------------------------------------------------------------------------------------------------------

; View edge, black on the left: 8 lines of 2 bytes
;
; $FFFF, $FFFC, $FFF0 ... $C000: a staircase 2 pixels a line.
; DrawViewBackground copies it with DrawEdgeStrips (2 bytes a line, 8 lines,
; then 2 bytes left) 6 times from $5B0A, the lower edge of the black triangle
; above the map, and 3 times from $5FB2. Image: d1-img/D6A8-ViewEdges.png.
ViewEdgeA:
  INCBIN "res/gfx/view-edges.bin",$0000,16

; View edge, black on the right: 8 lines of 2 bytes
;
; $0003, $000F ... $FFFF; DrawViewBackground copies it 4 times from $6512: with
; the 3 copies of ViewEdgeA at $5FB2 it makes the black band along the map's
; front edge, bottom right of the view.
ViewEdgeB:
  INCBIN "res/gfx/view-edges.bin",$0010,16

; Robot part sprites: 8 parts x 4 directions, sprite id - $16
;
; Row = part (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear,
; electronics), column = direction (the number of the lowest set bit of robot
; +$08: 0 X+, 1 X-, 2 Y+, 3 Y-). Read by DirectionLoop ($CF16; sprite id = byte
; + $16, then DrawSprite) for robots in the view and by ConstructionMenu
; ($C87B; column 1, the odd-column sprite via SpriteTable+$58) for the part
; icons. Bipod, tracks and missiles have one picture per axis, anti-grav and
; nuclear one for all four.
;
; The rows, as sprite ids: bipod $18, $18, $19, $19; tracks $16, $16, $17, $17;
; anti-grav $1A x 4; cannon $1B-$1E; missiles $1F, $1F, $20, $20; phasers
; $21-$24; nuclear $25 x 4; electronics $26-$29. Note the part order of the
; rows (bipod first) against the sprite order (tracks first).
PartSpriteTable:
  DEFB $02,$02,$03,$03
  DEFB $00,$00,$01,$01
  DEFB $04,$04,$04,$04
  DEFB $05,$06,$07,$08
  DEFB $09,$09,$0A,$0A
  DEFB $0B,$0C,$0D,$0E
  DEFB $0F,$0F,$0F,$0F
  DEFB $10,$11,$12,$13

; Sprite pointers: 51 sprite ids x (even column, odd column)
;
; Word = the sprite block for index id x 2 + parity (DrawSprite: AND $3F, SRA L
; / ADC A,A, then TableWord). Ids 0 ship, 1 shadow, 2-18 and 21 map types (2-5
; stones, 6-7 boulders, 8-11 rocks, 12-14 trench, 15-18 blocks, 21 post), 19-20
; unused (they point at the ship), 22-41 robot parts (PartSpriteTable), 42 the
; player's flag, 43 the enemy's flag, 44 the warbase sign, 45-50 shots (cannon,
; missile, phaser; X then Y). ConstructionMenu reads from SpriteTable+$58 (id
; 22 on). Read by TableWord ($D34C/$D34E).
SpriteTable:
  DEFW SprShip,SprShipOdd
  DEFW SprShadow,SprShadowOdd
  DEFW SprStonesA,SprStonesA
  DEFW SprStonesB,SprStonesB
  DEFW SprStonesC,SprStonesC
  DEFW SprStonesD,SprStonesD
  DEFW SprBouldersA,SprBouldersAOdd
  DEFW SprBouldersB,SprBouldersBOdd
  DEFW SprRocksA,SprRocksA
  DEFW SprRocksB,SprRocksB
  DEFW SprRocksC,SprRocksC
  DEFW SprRocksD,SprRocksD
  DEFW SprTrenchStartY,SprTrenchStartX
  DEFW SprTrenchMiddleY,SprTrenchMiddleX
  DEFW SprTrenchEndY,SprTrenchEndX
  DEFW SprBlockLow,SprBlockLowOdd
  DEFW SprBlockTall,SprBlockTallOdd
  DEFW SprBlockDoor,SprBlockWindow
  DEFW SprBlockGrid,SprBlockDotted
  DEFW SprShip,SprShip
  DEFW SprShip,SprShip
  DEFW SprPost,SprPost
  DEFW SprTracksX,SprTracksXOdd
  DEFW SprTracksY,SprTracksYOdd
  DEFW SprBipodX,SprBipodXOdd
  DEFW SprBipodY,SprBipodYOdd
  DEFW SprAntiGrav,SprAntiGravOdd
  DEFW SprCannonXp,SprCannonXpOdd
  DEFW SprCannonXm,SprCannonXmOdd
  DEFW SprCannonYp,SprCannonYpOdd
  DEFW SprCannonYm,SprCannonYmOdd
  DEFW SprMissilesX,SprMissilesXOdd
  DEFW SprMissilesY,SprMissilesYOdd
  DEFW SprPhasersXp,SprPhasersXpOdd
  DEFW SprPhasersXm,SprPhasersXmOdd
  DEFW SprPhasersYp,SprPhasersYpOdd
  DEFW SprPhasersYm,SprPhasersYmOdd
  DEFW SprNuclear,SprNuclearOdd
  DEFW SprElectronicsXp,SprElectronicsXpOdd
  DEFW SprElectronicsXm,SprElectronicsXmOdd
  DEFW SprElectronicsYp,SprElectronicsYpOdd
  DEFW SprElectronicsYm,SprElectronicsYmOdd
  DEFW SprFlagPlayer,SprFlagPlayerOdd
  DEFW SprFlagEnemy,SprFlagEnemyOdd
  DEFW SprWarbaseSign,SprWarbaseSignOdd
  DEFW SprShotCannonX,SprShotCannonXOdd
  DEFW SprShotCannonY,SprShotCannonYOdd
  DEFW SprShotMissileX,SprShotMissileXOdd
  DEFW SprShotMissileY,SprShotMissileYOdd
  DEFW SprShotPhaserX,SprShotPhaserXOdd
  DEFW SprShotPhaserY,SprShotPhaserYOdd

; Height of each robot part in units (bipod $0B, tracks 7, anti-grav 8, cannon
; 6, missiles 6, phasers 7, nuclear 7, electronics 7)
;
; Indexed by the part number. DirectionLoop ($CF28) adds it to the draw height
; after each part, so the parts stack; SpawnHeightLoop ($B911) sums it over
; robot +$07 into +$09, the robot's height, when a robot is made.
PartHeights:
  DEFB $0B,$07,$08,$06,$06,$07,$07,$07

; Height of each map cell type (0-22)
;
; Indexed by cell AND $1F: 0-1 0, stones 2-5 2, boulders 6-7 3, rocks 8-11 6,
; trench 12-14 0, blocks 15 7, 16 15, 17 7, 18 15, 19-20 0, the post 21 99 (no
; flight over it), 22 0. Read only by TerrainTop ($B093), the height under a
; cell for CheckShipMove (CellTop) and for shots and robots
; (GroundUnderFootprint).
TerrainHeights:
  DEFB $00,$00,$02,$02,$02,$02,$03,$03
  DEFB $06,$06,$06,$06,$00,$00,$00,$07
  DEFB $0F,$07,$0F,$00,$00,$63,$00
