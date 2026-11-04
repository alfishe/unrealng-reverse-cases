; Count each side's bases: warbases and the factories of each type
;
; Clears PlayerBases ($FD3A, 7) and EnemyBases ($FD42, 7) and goes through the
; 28 base records ($FD70, 5 bytes): a base whose +3 has bit 6 counts for the
; player, bit 5 for the enemy, at index +3 bits 0-2 (0 warbases, 1-6 the
; factories of type 1-6: electronics, nuclear, phasers, missiles, cannon,
; chassis, the resource each makes); neutral and destroyed (bit 7) bases do not
; count. The status panel shows these counts ($D2C1); the daily production
; ($AE38) adds 5 general per warbase and 2 per factory to its resource; a side
; with no warbase loses ($AE6B).
;
; Called after every change of owner (the capture tick $AE17), after the blast
; ($BA81), and by the map builder ($BCCA). Ran 18 times in the deep recording.
CountBases:
  LD HL,PlayerBuildings             ; the player's counts
  LD B,$07
ClearPlayerCounts:
  LD (HL),$00
  INC HL
  DJNZ ClearPlayerCounts
  INC HL                  ; skip PlayerRobots ($FD41)
  LD B,$07
ClearEnemyCounts:
  LD (HL),$00
  INC HL
  DJNZ ClearEnemyCounts
  LD DE,Warbases+3             ; the +3 byte of base 0, 28 bases
  LD B,$1C
CountBaseLoop:
  LD A,(DE)
  OR A
  JP M,CountNextBase      ; destroyed: not counted
  LD HL,PlayerBuildings
  BIT 6,A
  JR NZ,CountBaseType
  LD HL,EnemyBuildings             ; not the player's: the enemy's?
  BIT 5,A
  JR Z,CountNextBase      ; neutral: not counted
CountBaseType:
  AND $07                 ; count[type] += 1
  CALL AddAToHL
  INC (HL)
CountNextBase:
  LD A,E                  ; the next record (all inside page $FD)
  ADD A,$05
  LD E,A
  DJNZ CountBaseLoop
  RET

; PlayerRobots ($FD41) and EnemyRobots ($FD49): the live records of each side
;
; Counts the robot records whose +1 (the map cell's high byte) is not 0: slots
; 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows
; them (the ROBOTS line); the enemy's factory ($B86F) builds better-armed
; robots as its count grows. Called after each birth and death of a robot.
CountRobots:
  LD HL,Robots+$0001      ; the +1 byte of slot 0
  CALL CountLiveRobots
  LD (PlayerRobotCount),A
  CALL CountLiveRobots
  LD (EnemyRobotCount),A
  RET

; A = the live records among 24 robot records from HL (+1 not 0); HL moves past
; them
;
; Used by the routine at CountRobots.
CountLiveRobots:
  LD B,$18
  LD C,$00
  LD DE,$0010
CountLiveLoop:
  LD A,(HL)
  OR A
  JR Z,CountLiveNext
  INC C
CountLiveNext:
  ADD HL,DE
  DJNZ CountLiveLoop
  LD A,C
  RET

; Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1);
; its flag moves
;
; Sets the factory's owner bits ($BBB9), removes the flag buildings at both
; sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's
; flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The
; factory's own building (type 1-6 at x, y-2) stays.
;
; Called by the capture tick ($AE01) when a robot has stood on the factory's
; door for 144 ticks. Ran 17 times in the deep recording (captures by both
; sides).
GiveFactory:
  LD HL,Factories+3             ; the factories' +3 bytes
  CALL SetBaseOwner
  DEC H                   ; HL = the roof row y-2, x+2
  DEC H
  DEC H
  DEC H
  INC HL
  INC HL
  CALL RemoveBuilding     ; no flag at x+2
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  CALL RemoveBuilding     ; no flag at x-2
  LD A,B
  OR A
  JR Z,GiveFactoryFlag    ; the player's flag at x-2
  INC HL                  ; the enemy's at x+2
  INC HL
  INC HL
  INC HL
GiveFactoryFlag:
  ADD A,$07               ; type 7 or 8
  LD C,A
  CALL AddBuilding        ; add the flag building
  RET

; Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)
;
; Sets the owner bits ($BBB9) and rebuilds the warbase's buildings on its pad
; row y-4: removes those at x-4, x and x+4, then for the player puts the
; landing pad (type 0, x) and the player's flag (type 7, x-4); for the enemy
; only its flag (type 8, x+4). So a captured warbase gives the player a second
; pad where the construction menu opens.
;
; Called by the map builder ($BCB3-$BCC7: warbase 0 the player's, 1-3 the
; enemy's) and by the capture tick ($ADF9). In the deep recording only the four
; set-up calls ran.
GiveWarbase:
  LD HL,Warbases+3             ; the warbases' +3 bytes
  CALL SetBaseOwner
  LD A,H                  ; HL = the pad row y-4, column x
  SUB $08
  LD H,A
  CALL RemoveBuilding     ; the pad
  DEC L
  DEC L
  DEC L
  DEC L
  CALL RemoveBuilding     ; the player's flag place
  LD A,L
  ADD A,$08
  LD L,A
  CALL RemoveBuilding     ; the enemy's flag place
  LD C,$08
  LD A,B
  OR A
  JP NZ,AddBuilding       ; the enemy: its flag (type 8) at x+4
  DEC L
  DEC L
  DEC L
  DEC L
  LD C,A                  ; the player: the pad (type 0) at x
  CALL AddBuilding
  DEC L
  DEC L
  DEC L
  DEC L
  LD C,$07                ; and the flag (type 7) at x-4
  JP AddBuilding

; Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the
; enemy; HL = its door cell
;
; HL is $FD73 (warbases) or $FD87 (factories). Replaces bits 5-7 of the base's
; +3 with $40 (the player) or $20 (the enemy), which also clears the destroyed
; bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.
SetBaseOwner:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL AddAToHL
  LD A,B
  OR A
  LD A,$40                ; the player's bit 6 ...
  JR Z,SetBaseOwnerBits
  RRCA                    ; ... or the enemy's bit 5
SetBaseOwnerBits:
  LD C,A                  ; the owner bit into the base's type byte
  LD A,(HL)
  AND $1F
  OR C
  LD (HL),A
; This entry point is used by the routine at MarkBaseDestroyed.
BaseCell:
  DEC HL                  ; HL at a base's +3: HL = the map cell of its x
                          ; (+0/+1), y (+2)
  LD C,(HL)
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  LD A,C
  JP MapCell

; Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks
; turned to debris
;
; Marks the factory destroyed ($BC1C), removes its three buildings on the roof
; row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the
; factory's shape (ShapeFactory) again in debris: every block a random tile 6
; or 7. Verified by an experiment: factory 0 at (39,6) became $80, its building
; at (39,4) went and its blocks became tiles 6 / 7.
DestroyFactory:
  LD HL,Factories+3
  CALL MarkBaseDestroyed
  PUSH HL                 ; keep the door cell
  DEC H                   ; the roof row y-2, x+2
  DEC H
  DEC H
  DEC H
  INC HL
  INC HL
  CALL RemoveBuilding
  DEC HL
  DEC HL
  CALL RemoveBuilding
  DEC HL
  DEC HL
  CALL RemoveBuilding
  POP HL                  ; the shape from the door
  LD DE,ShapeFactory      ; ShapeFactory
  JP DrawRuins

; Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks
; turned to debris
;
; Marks the warbase destroyed ($BC1C), removes the buildings at x-4, x and x+4
; of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7). Verified
; by an experiment: warbase 1 at (261,8) became $80, its flag building at
; (265,4) went, the enemy's warbase count fell from 3 to 2 and its walls became
; debris.
DestroyWarbase:
  LD HL,Warbases+3
  CALL MarkBaseDestroyed
  PUSH HL                 ; keep the door cell
  LD A,H                  ; the pad row y-4, x
  SUB $08
  LD H,A
  CALL RemoveBuilding
  DEC L
  DEC L
  DEC L
  DEC L
  CALL RemoveBuilding
  LD A,L
  ADD A,$08
  LD L,A
  CALL RemoveBuilding
  POP HL
  LD DE,ShapeWarbase      ; ShapeWarbase
  JP DrawRuins

; Base A of the table HL (+3 bytes): +3 = $80 (destroyed, no owner); HL = its
; door cell
;
; Used by the routines at DestroyFactory and DestroyWarbase.
MarkBaseDestroyed:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL AddAToHL
  LD (HL),$80             ; destroyed: no owner, no type
  JR BaseCell
; This entry point is used by the routines at DestroyFactory and
; DestroyWarbase.
DrawRuins:
  LD A,(DE)               ; draw the shape DE at cell HL with every block a
                          ; random debris tile (6 or 7)
  OR A
  JR Z,DrawRuinsStep
  CALL Random             ; any tile: debris
  AND $01
  ADD A,$06
  CALL PutBlock
DrawRuinsStep:
  INC DE                  ; the shape's next step: columns C, rows B; (0,0)
                          ; ends
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  OR C
  RET Z
  CALL StepCell           ; HL to the next block
  JR DrawRuins

; Add a building: map cell HL, type C (0 pad, 1-6 factory, 7 the player's flag,
; 8 the enemy's flag)
;
; Takes the first free record of Buildings (56 x 3 bytes: the cell, the type; a
; high byte 0 = free), writes the cell and the type, and sets bit 6 of the map
; cell. With all 56 records taken it does nothing. The buildings are what the
; ship stands on (their heights by type at $B0C1: pad 15, factories 21-22,
; flags 25) and where landing opens the construction menu (type 0).
AddBuilding:
  LD DE,Buildings+1             ; the high bytes of the cells
  LD B,$38
AddBuildingFind:
  LD A,(DE)
  OR A
  JR Z,AddBuildingStore
  INC DE
  INC DE
  INC DE
  DJNZ AddBuildingFind
  RET
AddBuildingStore:
  DEC DE                  ; the cell's bit 6: something to find here
  SET 6,(HL)
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),C
  EX DE,HL
  RET

; Remove the building on map cell HL, if any: its record freed, bit 6 of the
; cell cleared
;
; Keeps IY and BC. Uses FindBuilding.
RemoveBuilding:
  PUSH IY
  PUSH BC
  CALL FindBuilding
  JR NZ,RemoveBuildingDone
  LD (IY+$01),$00
  RES 6,(HL)
RemoveBuildingDone:
  POP BC                  ; restore BC, IY
  POP IY
  RET

; A new game's map: clear it, place the scenery and the 28 bases, give the
; warbases their owners
;
; Called once by the new game set-up ($A68B). Clears the map $DD00-$FCFF and
; the radar bitmap $D800-$D8FF, places the scenery lists SceneryWest (columns
; 0-255) and SceneryEast (256-511), then the bases BaseListWest and
; BaseListEast (records into $FD70: 4 warbases, 24 factories, all neutral),
; gives warbase 0 to the player and warbases 1-3 to the enemy, counts the
; bases, marks the radar for a rebuild and puts the ship on the map ($B024).
;
; The resulting map: the player's warbase at (22,9), the enemy's at (261,8),
; (369,8), (494,8); 24 factories, four of each type; read back from the live
; instance after a new game.
BuildMap:
  LD HL,Map               ; the map: 16 rows of 512 cells
  LD D,H
  LD E,L
  INC DE
  LD BC,$1FFF
  LD (HL),$00
  LDIR
  LD HL,RadarOwn          ; the radar bitmap
  LD D,H
  LD E,L
  INC DE
  LD BC,$00FF
  LD (HL),$00
  LDIR
  LD HL,SceneryWest       ; the scenery, columns 0-255
  LD D,$00
  CALL PlaceScenery
  LD HL,SceneryEast       ; the scenery, columns 256-511
  LD D,$01
  CALL PlaceScenery
  LD IY,Factories             ; the factories' records from $FD84, the warbases'
                          ; from $FD70
  LD IX,Warbases
  LD HL,BaseListWest
  LD D,$00
  CALL PlaceBases
  LD HL,BaseListEast
  LD D,$01
  CALL PlaceBases
  XOR A                   ; warbase 0: the player's
  LD B,A
  CALL GiveWarbase
  LD A,$01                ; warbases 1-3: the enemy's
  LD B,A
  CALL GiveWarbase
  LD A,$02
  LD B,$01
  CALL GiveWarbase
  LD A,$03
  LD B,$01
  CALL GiveWarbase
  CALL CountBases
  LD A,$01                ; rebuild the radar map
  LD (RadarDirty),A
  CALL PutShipOnMap       ; the ship's cell bit 7, the ship's radar dot
  RET

; Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends),
; D = x high byte
;
; A record with bit 7 clear is one 2 x 2 block of that tile ($BD91), with bit 7
; set the shape of that index ($BD61). The cell is $DD00 + $200 * y + D * 256 +
; x.
PlaceScenery:
  LD A,(HL)
  OR A
  RET Z
  LD C,A
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD HL,Map               ; HL = the cell: $DD00 + 2 * y pages + DE
  ADD A,A
  ADD A,H
  LD H,A
  ADD HL,DE
  LD A,C
  OR A
  JP M,PlaceSceneryShape  ; bit 7: a shape
  CALL PutBlock
  JR PlaceSceneryNext
PlaceSceneryShape:
  CALL DrawShape
PlaceSceneryNext:
  POP DE
  POP HL
  JR PlaceScenery

; Place a bases list at HL (3-byte records: type, x low, y; $FF ends), D = x
; high byte
;
; Type 0: a warbase. Its record goes to IX (the warbases' table) and
; ShapeWarbase is drawn from the cell. Type 1-6: a factory of that type. Its
; record goes to IY (the factories' table), ShapeFactory is drawn and the
; factory's building (that type) is added two rows up, at (x, y-2). A record:
; +0/+1 x, +2 y, +3 the type (the owner bits come later), +4 0 (the capture
; counter).
PlaceBases:
  LD A,(HL)
  OR A
  RET M
  LD C,A
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  LD B,A
  INC HL
  PUSH HL
  PUSH DE
  LD HL,Map
  ADD A,A
  ADD A,H
  LD H,A
  ADD HL,DE
  LD A,C
  OR A
  JR Z,PlaceWarbase       ; type 0: a warbase
  LD (IY+$00),E           ; a factory's record
  LD (IY+$01),D
  LD (IY+$02),B
  LD (IY+$03),C
  LD (IY+$04),$00
  INC IY
  INC IY
  INC IY
  INC IY
  INC IY
  PUSH BC
  PUSH HL
  LD A,$81                ; shape 1, ShapeFactory
  CALL DrawShape
  POP HL
  POP BC
  DEC H                   ; the factory's building at (x, y-2), its type
  DEC H
  DEC H
  DEC H
  CALL AddBuilding
  POP DE
  POP HL
  JR PlaceBases
PlaceWarbase:
  LD (IX+$00),E           ; a warbase's record
  LD (IX+$01),D
  LD (IX+$02),B
  LD (IX+$03),C
  LD (IX+$04),$00
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
  LD A,$80                ; shape 0, ShapeWarbase
  CALL DrawShape
  POP DE
  POP HL
  JR PlaceBases

; Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL
;
; A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block
; at the current cell, then the move to the next cell: columns (signed), rows
; (signed); a move of (0,0) ends after its tile. DrawRuins ($BC27) walks the
; same lists with debris tiles.
DrawShape:
  PUSH HL
  LD HL,ShapeTable
  AND $7F
  CALL TableWord
  EX DE,HL
  POP HL
DrawShapeStep:
  LD A,(DE)
  OR A
  CALL NZ,PutBlock        ; a 2 x 2 block of the tile
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  OR C
  RET Z                   ; the move (0,0) ends the shape
  CALL StepCell
  JR DrawShapeStep

; HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept
;
; Used by the routines at MarkBaseDestroyed and DrawShape.
StepCell:
  PUSH DE
  LD E,C
  LD D,$00
  LD A,C
  OR A
  JP P,StepCellAdd
  LD D,$FF
StepCellAdd:
  ADD HL,DE
  LD A,H
  ADD A,B
  ADD A,B
  LD H,A
  POP DE
  RET

; A 2 x 2 block of tile A with its bottom left at map cell HL
;
; Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the
; tile as it is, the other three with bit 5 set (the other parts of a block;
; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and
; DE; BC is lost. Used by the map builder, the ruins, the blast and a dead
; robot's wreck ($B133).
PutBlock:
  PUSH DE
  LD E,A
  LD BC,$0202             ; 2 rows of 2 cells
  PUSH HL
PutBlockRow:
  PUSH BC
  PUSH HL
PutBlockCell:
  LD (HL),E               ; the first cell plain, the rest with bit 5
  SET 5,E
  INC HL
  DJNZ PutBlockCell
  POP HL
  POP BC
  DEC H                   ; the row above
  DEC H
  DEC C
  JR NZ,PutBlockRow
  POP HL
  POP DE
  RET
