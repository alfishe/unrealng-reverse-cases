; --------------------------------------------------------------------------------------------------------------------
; tables.asm: Lookup tables of the view and the robots: view edges, part sprites, sprite pointers, heights
;
; Small constant tables the view and the movement code index by type. NE's docs: 06-rendering.md 6.1 (edges), 6.5
; (SpriteTable), 6.6 (PartSpriteTable, PartHeights), 07-objects.md 7.3 / 7.5 (TerrainHeights). Resource: ViewEdgeA /
; ViewEdgeB are src/res/game98/gfx/view-edges.png (see src/res/game98/README.md); the others stay in the source as
; rows the code reads field by field.
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
  INCBIN "res/game98/gfx/view-edges.bin",$0000,16

; View edge, black on the right: 8 lines of 2 bytes
;
; $0003, $000F ... $FFFF; DrawViewBackground copies it 4 times from $6512: with
; the 3 copies of ViewEdgeA at $5FB2 it makes the black band along the map's
; front edge, bottom right of the view.
ViewEdgeB:
  INCBIN "res/game98/gfx/view-edges.bin",$0010,16

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
  DEFB $02,$02,$03,$03    ; part 0 bipod (+$07 bit 0): ids 24 24 25 25 (along
                          ; X, along Y); columns: facing X+, X-, Y+, Y-
  DEFB $00,$00,$01,$01    ; part 1 tracks (+$07 bit 1): ids 22 22 23 23 (along
                          ; X, along Y)
  DEFB $04,$04,$04,$04    ; part 2 anti-grav (+$07 bit 2): id 26 for all four
  DEFB $05,$06,$07,$08    ; part 3 cannon (+$07 bit 3): ids 27-30
  DEFB $09,$09,$0A,$0A    ; part 4 missiles (+$07 bit 4): ids 31 31 32 32 (X,
                          ; Y)
  DEFB $0B,$0C,$0D,$0E    ; part 5 phasers (+$07 bit 5): ids 33-36
  DEFB $0F,$0F,$0F,$0F    ; part 6 nuclear (+$07 bit 6): id 37 for all four
  DEFB $10,$11,$12,$13    ; part 7 electronics (+$07 bit 7): ids 38-41

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
  DEFW SprShip,SprShipOdd ; id 0: the player's ship; each row: the even and the
                          ; odd column's block
  DEFW SprShadow,SprShadowOdd ; id 1: the ship's shadow
  DEFW SprStonesA,SprStonesA ; id 2: map type 2: stones A
  DEFW SprStonesB,SprStonesB ; id 3: map type 3: stones B
  DEFW SprStonesC,SprStonesC ; id 4: map type 4: stones C
  DEFW SprStonesD,SprStonesD ; id 5: map type 5: stones D
  DEFW SprBouldersA,SprBouldersAOdd ; id 6: map type 6: boulders A
  DEFW SprBouldersB,SprBouldersBOdd ; id 7: map type 7: boulders B
  DEFW SprRocksA,SprRocksA ; id 8: map type 8: rocks A
  DEFW SprRocksB,SprRocksB ; id 9: map type 9: rocks B
  DEFW SprRocksC,SprRocksC ; id 10: map type 10: rocks C
  DEFW SprRocksD,SprRocksD ; id 11: map type 11: rocks D
  DEFW SprTrenchStartY,SprTrenchStartX ; id 12: map type 12: trench start
                                       ; (along Y, along X)
  DEFW SprTrenchMiddleY,SprTrenchMiddleX ; id 13: map type 13: trench middle
                                         ; (along Y, along X)
  DEFW SprTrenchEndY,SprTrenchEndX ; id 14: map type 14: trench end (along Y,
                                   ; along X)
  DEFW SprBlockLow,SprBlockLowOdd ; id 15: map type 15: low block
  DEFW SprBlockTall,SprBlockTallOdd ; id 16: map type 16: tall block with an
                                    ; arch
  DEFW SprBlockDoor,SprBlockWindow ; id 17: map type 17: low block (door,
                                   ; window)
  DEFW SprBlockGrid,SprBlockDotted ; id 18: map type 18: tall block (grid,
                                   ; dotted)
  DEFW SprShip,SprShip    ; id 19: unused: points at the ship
  DEFW SprShip,SprShip    ; id 20: unused: points at the ship
  DEFW SprPost,SprPost    ; id 21: map type 21: the border post
  DEFW SprTracksX,SprTracksXOdd ; id 22: tracks along X (part 1, X+ / X-);
                                ; ConstructionMenu reads from here
                                ; (SpriteTable+$58)
  DEFW SprTracksY,SprTracksYOdd ; id 23: tracks along Y (part 1, Y+ / Y-); also
                                ; the chassis factory's sign
  DEFW SprBipodX,SprBipodXOdd ; id 24: bipod along X (part 0)
  DEFW SprBipodY,SprBipodYOdd ; id 25: bipod along Y (part 0)
  DEFW SprAntiGrav,SprAntiGravOdd ; id 26: anti-grav (part 2, every direction)
  DEFW SprCannonXp,SprCannonXpOdd ; id 27: cannon facing X+ (part 3)
  DEFW SprCannonXm,SprCannonXmOdd ; id 28: cannon facing X-
  DEFW SprCannonYp,SprCannonYpOdd ; id 29: cannon facing Y+ (also the cannon
                                  ; factory's sign)
  DEFW SprCannonYm,SprCannonYmOdd ; id 30: cannon facing Y-
  DEFW SprMissilesX,SprMissilesXOdd ; id 31: missiles along X (part 4)
  DEFW SprMissilesY,SprMissilesYOdd ; id 32: missiles along Y (also the
                                    ; missiles factory's sign)
  DEFW SprPhasersXp,SprPhasersXpOdd ; id 33: phasers facing X+ (part 5)
  DEFW SprPhasersXm,SprPhasersXmOdd ; id 34: phasers facing X-
  DEFW SprPhasersYp,SprPhasersYpOdd ; id 35: phasers facing Y+ (also the
                                    ; phasers factory's sign)
  DEFW SprPhasersYm,SprPhasersYmOdd ; id 36: phasers facing Y-
  DEFW SprNuclear,SprNuclearOdd ; id 37: nuclear (part 6, every direction; also
                                ; the nuclear factory's sign)
  DEFW SprElectronicsXp,SprElectronicsXpOdd ; id 38: electronics facing X+
                                            ; (part 7)
  DEFW SprElectronicsXm,SprElectronicsXmOdd ; id 39: electronics facing X-
  DEFW SprElectronicsYp,SprElectronicsYpOdd ; id 40: electronics facing Y+
                                            ; (also the electronics factory's
                                            ; sign)
  DEFW SprElectronicsYm,SprElectronicsYmOdd ; id 41: electronics facing Y-
  DEFW SprFlagPlayer,SprFlagPlayerOdd ; id 42: the player's flag (building type
                                      ; 7)
  DEFW SprFlagEnemy,SprFlagEnemyOdd ; id 43: the enemy's flag (building type 8)
  DEFW SprWarbaseSign,SprWarbaseSignOdd ; id 44: the warbase sign (building
                                        ; type 0, the pad)
  DEFW SprShotCannonX,SprShotCannonXOdd ; id 45: shot: cannon shell along X
                                        ; (weapon 1)
  DEFW SprShotCannonY,SprShotCannonYOdd ; id 46: shot: cannon shell along Y
  DEFW SprShotMissileX,SprShotMissileXOdd ; id 47: shot: missile along X
                                          ; (weapon 2)
  DEFW SprShotMissileY,SprShotMissileYOdd ; id 48: shot: missile along Y
  DEFW SprShotPhaserX,SprShotPhaserXOdd ; id 49: shot: phaser beam along X
                                        ; (weapon 3)
  DEFW SprShotPhaserY,SprShotPhaserYOdd ; id 50: shot: phaser beam along Y

; Height of each robot part in units (bipod $0B, tracks 7, anti-grav 8, cannon
; 6, missiles 6, phasers 7, nuclear 7, electronics 7)
;
; Indexed by the part number. DirectionLoop ($CF28) adds it to the draw height
; after each part, so the parts stack; SpawnHeightLoop ($B911) sums it over
; robot +$07 into +$09, the robot's height, when a robot is made.
PartHeights:
  DEFB $0B,$07,$08,$06,$06,$07,$07,$07 ; by part: bipod 11, tracks 7, anti-grav
                                       ; 8, cannon 6, missiles 6, phasers 7,
                                       ; nuclear 7, electronics 7

; Height of each map cell type (0-22)
;
; Indexed by cell AND $1F: 0-1 0, stones 2-5 2, boulders 6-7 3, rocks 8-11 6,
; trench 12-14 0, blocks 15 7, 16 15, 17 7, 18 15, 19-20 0, the post 21 99 (no
; flight over it), 22 0. Read only by TerrainTop ($B093), the height under a
; cell for CheckShipMove (CellTop) and for shots and robots
; (GroundUnderFootprint).
TerrainHeights:
  DEFB $00,$00,$02,$02,$02,$02,$03,$03 ; types 0-7: 0 empty 0, 1 0, stones 2-5
                                       ; 2, boulders 6-7 3
  DEFB $06,$06,$06,$06,$00,$00,$00,$07 ; types 8-15: rocks 8-11 6, trench 12-14
                                       ; 0, low block 15 7
  DEFB $0F,$07,$0F,$00,$00,$63,$00 ; types 16-22: tall block 16 15, low block
                                   ; 17 7, tall block 18 15, 19-20 0, post 21
                                   ; 99 (no flight), 22 0
