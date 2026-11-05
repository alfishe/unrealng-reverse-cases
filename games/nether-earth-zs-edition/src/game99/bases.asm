; --------------------------------------------------------------------------------------------------------------------
; bases.asm: the bases: counts, owners, buildings, destruction and the new game's map
;
; The 28 capture points (4 warbases, 24 factories) and what stands on them: their 5-byte records in Warbases ($FD70)
; and Factories ($FD84), the 56 building records of Buildings ($FF01: pads, factory roofs, flags) and the map blocks
; they are drawn from.
;
; The counts: CountBases (PlayerBuildings $FD3A / EnemyBuildings $FD42, 7 each: warbases, then the six factory kinds)
; after every change of owner; CountRobots with CountLiveRobots (PlayerRobotCount $FD41 / EnemyRobotCount $FD49) after
; every birth and death.
;
; The owners: GiveFactory and GiveWarbase (from the capture tick and BuildMap) set the owner bits through
; SetBaseOwner, which falls into BaseCell (the door cell), and move the flags and the pad: RemoveBuilding /
; AddBuilding. The destruction: DestroyFactory and DestroyWarbase (from NuclearBlast) mark the record $80
; (MarkBaseDestroyed), remove the buildings and redraw the base's shape in debris (DrawRuins).
;
; The map: BuildMap, once a new game, clears the map and the radar, places the scenery lists (PlaceScenery) and the
; base lists (PlaceBases), gives warbase 0 to the player and 1-3 to the enemy, counts and puts the ship on. The block
; layer under them: DrawShape walks a shape of ShapeTable, StepCell moves by a signed step, PutBlock writes one 2 x 2
; block (its anchor plain, the other three cells with bit 5).
;
; Positions relative to a base's door cell (x, y): a factory's roof row is y-2 (its building at x, our flag at x-2,
; the enemy's at x+2), a warbase's pad row y-4 (the pad at x, our flag at x-4, the enemy's at x+4). A map row is $200
; bytes, so the code moves rows with DEC H / INC H in pairs.
; --------------------------------------------------------------------------------------------------------------------

; Count each side's bases: warbases and the factories of each type
;
; Clears PlayerBuildings ($FD3A, 7 counts) and EnemyBuildings ($FD42, 7) and
; goes through the 28 base records ($FD70, 5 bytes, read at +3): a base whose
; +3 has bit 6 counts for the player, bit 5 for the enemy, at index +3 bits 0-2
; (0 warbases, 1-6 the factories of type 1-6: electronics, nuclear, phasers,
; missiles, cannon, chassis, the resource each makes; neutral and destroyed
; (bit 7) bases do not count. PlayerRobotCount ($FD41) between the two count
; blocks is skipped. The status panel shows these counts ($D2C1; the daily
; production ($AE38) adds 5 general per warbase and 2 per factory to its
; resource; a side with no warbase loses ($AE6B).
;
; Called after every change of owner (the capture tick $AE17), after the blast
; ($BA81), and by the map builder ($BCCA). A, B, DE, HL lost.
CountBases:
  LD HL,PlayerBuildings             ; the player's counts
  LD B,$07                ; 7 counts
ClearPlayerCounts:
  LD (HL),$00             ; count = 0
  INC HL                  ; the next count
  DJNZ ClearPlayerCounts  ; all 7
  INC HL                  ; skip PlayerRobots ($FD41)
  LD B,$07                ; the enemy's 7 counts
ClearEnemyCounts:
  LD (HL),$00             ; count = 0
  INC HL                  ; the next count
  DJNZ ClearEnemyCounts   ; all 7
  LD DE,Warbases+3             ; the +3 byte of base 0, 28 bases
  LD B,$02                ; the capture points: 2 in the image (the built-in
                          ; level), the NELEV byte $1F3 after LOAD MAP
CountBaseLoop:
  LD A,(DE)               ; A = the base's owner and type
  OR A                    ; bit 7?
  JP M,CountNextBase      ; destroyed: not counted
  LD HL,PlayerBuildings             ; the player's counts...
  BIT 6,A                 ; ... if bit 6, ours
  JR NZ,CountBaseType     ; ours: count it
  LD HL,EnemyBuildings             ; not the player's: the enemy's?
  BIT 5,A                 ; bit 5, the enemy's?
  JR Z,CountNextBase      ; neutral: not counted
CountBaseType:
  AND $07                 ; count[type] += 1
  CALL AddAToHL           ; HL = the type's count
  INC (HL)                ; one more
CountNextBase:
  LD A,E                  ; the next record (all inside page $FD)
  ADD A,$05               ; + 5
  LD E,A                  ; DE = the next base's +3
  DJNZ CountBaseLoop      ; all 28 bases
  RET                     ; the counts are new

; PlayerRobots ($FD41) and EnemyRobots ($FD49): the live records of each side
;
; Counts the robot records whose +1 (the map cell's high byte) is not 0: slots
; 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows
; them (the ROBOTS line; the enemy's factory ($B86F) builds better-armed robots
; as its count grows. Called after each birth and death of a robot.
CountRobots:
  LD HL,Robots+1             ; the +1 byte of slot 0
  CALL CountLiveRobots    ; A = our live robots (slots 0-23), HL to slot 24
  LD (PlayerRobotCount),A            ; PlayerRobotCount = A
  CALL CountLiveRobots    ; A = the enemy's (slots 24-47)
  LD (EnemyRobotCount),A            ; EnemyRobotCount = A
  RET                     ; both counted

; A = the live records among 24 robot records from HL (+1 not 0); HL moves past
; them
;
; Used by the routine at CountRobots.
CountLiveRobots:
  LD B,$18                ; 24 records
  LD C,$00                ; C = the live ones
  LD DE,$0010             ; 16 bytes a record
CountLiveLoop:
  LD A,(HL)               ; +$01, the cell's high byte
  OR A                    ; 0?
  JR Z,CountLiveNext      ; a free slot
  INC C                   ; one live robot more
CountLiveNext:
  ADD HL,DE               ; the next record's +$01
  DJNZ CountLiveLoop      ; all 24
  LD A,C                  ; A = the count
  RET                     ; HL past the 24 records

; Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1);
; its flag moves
;
; Sets the factory's owner bits ($BBB9), removes the flag buildings at both
; sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's
; flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The
; factory's own building (type 1-6 at x, y-2) stays.
;
; Called by the capture tick ($AE01) when a robot has stood on the factory's
; door for 144 ticks.
GiveFactory:
  LD HL,Factories+3             ; the factories' +3 bytes
  CALL SetBaseOwner       ; the factory's owner bits; HL = its door cell
  DEC H                   ; HL = the roof row y-2, x+2
  DEC H                   ; ...
  DEC H                   ; ...
  DEC H                   ; ... two rows up (4 pages): the roof row
  INC HL                  ; ...
  INC HL                  ; ... x+2, the enemy's flag place
  CALL RemoveBuilding     ; no flag at x+2
  DEC HL                  ; ...
  DEC HL                  ; ...
  DEC HL                  ; ...
  DEC HL                  ; ... x-2, our flag place
  CALL RemoveBuilding     ; no flag at x-2
  LD A,B                  ; the new owner:
  OR A                    ; 0, the player?
  JR Z,GiveFactoryFlag    ; the player's flag at x-2
  INC HL                  ; the enemy's at x+2
  INC HL                  ; ...
  INC HL                  ; ...
  INC HL                  ; ... x+2
GiveFactoryFlag:
  ADD A,$07               ; type 7 or 8
  LD C,A                  ; C = the flag's type
  CALL AddBuilding        ; add the flag building
  RET                     ; the factory flies its new flag

; Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)
;
; Sets the owner bits ($BBB9) and rebuilds the warbase's buildings on its pad
; row y-4: removes those at x-4, x and x+4, then for the player puts the
; landing pad (type 0, x) and the player's flag (type 7, x-4; for the enemy
; only its flag (type 8, x+4). So a captured warbase gives the player a second
; pad where the construction menu opens.
;
; Called by the map builder ($BCB3-$BCC7: warbase 0 the player's, 1-3 the
; enemy's) and by the capture tick ($ADF9).
GiveWarbase:
  LD HL,Warbases+3             ; the warbases' +3 bytes
  CALL SetBaseOwner       ; the warbase's owner bits; HL = its door cell
  LD A,H                  ; HL = the pad row y-4, column x
  SUB $08                 ; 4 rows up (8 pages)
  LD H,A                  ; H = the pad row's page
  CALL RemoveBuilding     ; the pad
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ... x-4 (only L: no warbase is near a 256-column
                          ; border)
  CALL RemoveBuilding     ; the player's flag place
  LD A,L                  ; the column...
  ADD A,$08               ; ... + 8: x+4
  LD L,A                  ; L = it
  CALL RemoveBuilding     ; the enemy's flag place
  LD C,$08                ; C = 8, the enemy's flag
  LD A,B                  ; the new owner:
  OR A                    ; the enemy?
  JP NZ,AddBuilding       ; the enemy: its flag (type 8) at x+4
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ... back to x
  LD C,A                  ; the player: the pad (type 0) at x
  CALL AddBuilding        ; add the pad
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ... x-4
  LD C,$07                ; and the flag (type 7) at x-4
  JP AddBuilding          ; add the flag, return from there

; Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the
; enemy; HL = its door cell
;
; HL is $FD73 (warbases) or $FD87 (factories). Replaces bits 5-7 of the base's
; +3 with $40 (the player) or $20 (the enemy), which also clears the destroyed
; bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.
SetBaseOwner:
  LD C,A                  ; C = the index
  ADD A,A                 ; * 2
  ADD A,A                 ; * 4
  ADD A,C                 ; * 5, a record's size
  CALL AddAToHL           ; HL = the base's +3
  LD A,B                  ; the side:
  OR A                    ; 0, the player?
  LD A,$40                ; the player's bit 6...
  JR Z,SetBaseOwnerBits   ; yes: $40
  RRCA                    ; ... or the enemy's bit 5
SetBaseOwnerBits:
  LD C,A                  ; keep the type, set the owner
  LD A,(HL)               ; the base's +3
  AND $1F                 ; the type bits 0-4 kept, owner and destroyed bits
                          ; cleared
  OR C                    ; the new owner
  LD (HL),A               ; store it
; This entry point is used by the routine at MarkBaseDestroyed.
BaseCell:
  DEC HL                  ; HL at a base's +3: HL = the map cell of its x
                          ; (+0/+1), y (+2)
  LD C,(HL)               ; C = the door's row (+2)
  DEC HL                  ; the column's high byte (+1)
  LD A,(HL)               ; A = it
  DEC HL                  ; the low byte (+0)
  LD L,(HL)               ; L = it
  LD H,A                  ; HL = the door's column
  LD A,C                  ; A = the row
  JP MapCell              ; HL = the door's map cell, return from there

; Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks
; turned to debris
;
; Marks the factory destroyed ($BC1C), removes its three buildings on the roof
; row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the
; factory's shape (ShapeFactory) again in debris: every block a random tile 6
; or 7.
DestroyFactory:
  LD HL,Factories+3             ; the factories' +3 bytes
  CALL MarkBaseDestroyed  ; +3 = $80; HL = the door cell
  PUSH HL                 ; keep the door cell
  DEC H                   ; the roof row y-2, x+2
  DEC H                   ; ...
  DEC H                   ; ...
  DEC H                   ; ... two rows up: the roof row
  INC HL                  ; ...
  INC HL                  ; ... x+2
  CALL RemoveBuilding     ; the enemy's flag, if any
  DEC HL                  ; ...
  DEC HL                  ; ... x
  CALL RemoveBuilding     ; the factory's roof
  DEC HL                  ; ...
  DEC HL                  ; ... x-2
  CALL RemoveBuilding     ; our flag, if any
  POP HL                  ; the shape from the door
  LD DE,ShapeFactory      ; ShapeFactory
  JP DrawRuins            ; the factory's blocks as debris, return from there

; Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks
; turned to debris
;
; Marks the warbase destroyed ($BC1C), removes the buildings at x-4, x and x+4
; of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7).
DestroyWarbase:
  LD HL,Warbases+3             ; the warbases' +3 bytes
  CALL MarkBaseDestroyed  ; +3 = $80; HL = the door cell
  PUSH HL                 ; keep the door cell
  LD A,H                  ; the pad row y-4, x
  SUB $08                 ; 4 rows up (8 pages)
  LD H,A                  ; H = the pad row's page
  CALL RemoveBuilding     ; the pad, if any
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ...
  DEC L                   ; ... x-4
  CALL RemoveBuilding     ; our flag, if any
  LD A,L                  ; the column...
  ADD A,$08               ; ... + 8: x+4
  LD L,A                  ; L = it
  CALL RemoveBuilding     ; the enemy's flag, if any
  POP HL                  ; HL = the door cell, where the shape starts
  LD DE,ShapeWarbase      ; ShapeWarbase
  JP DrawRuins            ; the warbase's blocks as debris, return from there

; Base A of the table HL (+3 bytes): +3 = $80 (destroyed, no owner); HL = its
; door cell
;
; A = the base's index in its table, HL = the table's +3 bytes (Warbases+3 or
; Factories+3). Writes $80 to the base's +3: destroyed, no owner, type bits 0;
; CountBases does not count it and no order's owner bits match it, so no order
; targets it again. The capture tick (CaptureLoop) does not test bit 7, though:
; from the code, a robot standing 144 turns on the door would give it an owner
; again (SetBaseOwner clears bit 7) with type 0, a warbase; never seen. Goes on
; into BaseCell: HL = the base's door cell, A = its row. Used by DestroyFactory
; and DestroyWarbase.
MarkBaseDestroyed:
  LD C,A                  ; C = the index
  ADD A,A                 ; * 2
  ADD A,A                 ; * 4
  ADD A,C                 ; * 5, a record's size
  CALL AddAToHL           ; HL = the base's +3
  LD (HL),$80             ; destroyed: no owner, no type
  JR BaseCell             ; HL = its door cell, return from there
; This entry point is used by the routines at DestroyFactory and
; DestroyWarbase.
DrawRuins:
  LD A,(DE)               ; draw the shape DE at cell HL with every block a
                          ; random debris tile (6 or 7)
  OR A                    ; the shape's tile: 0 = no block at this step
  JR Z,DrawRuinsStep      ; none: only the move
  CALL Random             ; any tile: debris
  AND $01                 ; 0 or 1
  ADD A,$06               ; tile 6 or 7
  CALL PutBlock           ; the 2 x 2 debris block (HL, DE kept)
DrawRuinsStep:
  INC DE                  ; the shape's next step: columns C, rows B; (0,0)
                          ; ends
  LD A,(DE)               ; the column step...
  LD C,A                  ; ... to C
  INC DE                  ; the row step...
  LD A,(DE)               ; ...
  LD B,A                  ; ... to B
  INC DE                  ; DE = the next step's tile
  OR C                    ; the move (0,0)?
  RET Z                   ; the shape ends
  CALL StepCell           ; HL to the next block
  JR DrawRuins            ; its tile

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
  LD B,$38                ; 56 records
AddBuildingFind:
  LD A,(DE)               ; the record's cell high byte
  OR A                    ; 0: free
  JR Z,AddBuildingStore   ; take it
  INC DE                  ; ...
  INC DE                  ; ...
  INC DE                  ; ... the next 3-byte record
  DJNZ AddBuildingFind    ; all 56
  RET                     ; all taken: no building
AddBuildingStore:
  DEC DE                  ; the cell's bit 6: something to find here
  SET 6,(HL)              ; the map cell's anchor bit
  EX DE,HL                ; HL = the record, DE = the cell
  LD (HL),E               ; +0: the cell's low byte
  INC HL                  ; ...
  LD (HL),D               ; +1: its high byte
  INC HL                  ; ...
  LD (HL),C               ; +2: the type
  EX DE,HL                ; HL = the map cell again
  RET                     ; the building stands

; Remove the building on map cell HL, if any: its record freed, bit 6 of the
; cell cleared
;
; Keeps IY and BC. Uses FindBuilding.
RemoveBuilding:
  PUSH IY                 ; keep the caller's IY...
  PUSH BC                 ; ... and BC
  CALL FindBuilding       ; IY = the building record on cell HL, Z when there
                          ; is one
  JR NZ,RemoveBuildingDone ; none here: nothing to do
  LD (IY+$01),$00         ; the record's high byte 0: free
  RES 6,(HL)              ; the cell's anchor bit off
RemoveBuildingDone:
  POP BC
  POP IY                  ; IY back
  RET                     ; the building is gone

; A new game's map: clear it, place the scenery and the bases of the level,
; give the warbases their owners
;
; Called once by the new game set-up ($A68B). Clears the map $DD00-$FCFF and
; the radar bitmap $D800-$D8FF, places the scenery lists (columns 0-255, then
; 256-511), then the two base lists (their records into $FD70: the warbases
; from $FD70, the factories from the address in IY), gives warbase 0 to the
; player and the next ones to the enemy, counts the bases, marks the radar for
; a rebuild and puts the ship on the map ($B024).
;
; Five operands here are the level's: the four list addresses ($BC8A, $BC92,
; $BCA2, $BCAA) and the first factory record ($BC9B), with the enemy's warbase
; count at $BCB7. The image holds the built-in level's (SceneryWest $BDA9,
; SceneryEast $BE4F, BaseListWest $BE5C, BaseListEast $BE60, the factories from
; $FD7A after 2 warbases, 1 enemy warbase); LOAD MAP writes a NELEV file's tail
; over them (src/res/maps/README.md). The enemy's warbases are given by a DJNZ
; loop, warbase B for B = the count down to 1, where NE gave warbases 1-3 one
; by one; the 8 NOPs after it fill the rest of NE's code.
BuildMap:
  LD HL,Map             ; the map: 16 rows of 512 cells
  LD D,H                  ; DE = HL + 1...
  LD E,L                  ; ...
  INC DE                  ; ...
  LD BC,$1FFF             ; $2000 bytes in all, $DD00-$FCFF
  LD (HL),$00             ; the first 0...
  LDIR                    ; ... copied over the rest: an empty map, terrain
                          ; type 0
  LD HL,RadarOwn             ; the radar bitmap
  LD D,H                  ; DE = HL + 1...
  LD E,L                  ; ...
  INC DE                  ; ...
  LD BC,$00FF             ; 256 bytes, $D800-$D8FF, the player's layer
                          ; (BuildRadar redraws both later)
  LD (HL),$00             ; the first 0...
  LDIR                    ; ... copied over the rest
  LD HL,SceneryWest       ; the scenery of columns 0-255: SceneryWest (NELEV
                          ; $1F4)
  LD D,$00                ; the column's high byte 0
  CALL PlaceScenery       ; place the west scenery
  LD HL,SceneryEast       ; the scenery of columns 256-511: SceneryEast (NELEV
                          ; $1F6)
  LD D,$01                ; the column's high byte 1
  CALL PlaceScenery       ; place the east scenery
  LD IY,Warbases+10             ; the first factory record: $FD70 + 5 x the warbases
                          ; (NELEV $1FC)
  LD IX,Warbases             ; IX = the warbases' records
  LD HL,BaseListWest      ; the bases of columns 0-255: BaseListWest (NELEV
                          ; $1F8)
  LD D,$00                ; the column's high byte 0
  CALL PlaceBases         ; place them
  LD HL,BaseListEast      ; the bases of columns 256-511: BaseListEast (NELEV
                          ; $1FA)
  LD D,$01                ; the column's high byte 1
  CALL PlaceBases         ; place them
  XOR A                   ; warbase 0: the player's
  LD B,A                  ; B = 0: the player
  CALL GiveWarbase        ; warbase 0: its pad and our flag
  LD B,$01                ; B = the enemy's warbases: 1 in the image, NELEV
                          ; $1FE after LOAD MAP
BuildMapEnemyBase:
  PUSH BC                 ; keep the count
  LD A,B                  ; A = the warbase, from the last down to 1
  LD B,$01                ; B = 1: the enemy
  CALL GiveWarbase        ; its flag
  POP BC                  ; the count back
  DJNZ BuildMapEnemyBase  ; every enemy warbase
  NOP                     ; eight NOPs
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL CountBases         ; the first counts of both sides
  LD A,$01                ; rebuild the radar map
  LD (RadarDirty),A            ; RadarDirty = 1
  CALL PutShipOnMap       ; the ship's cell bit 7, the ship's radar dot
  RET                     ; the map is ready

; Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends),
; D = x high byte
;
; A record with bit 7 clear is one 2 x 2 block of that tile ($BD91), with bit 7
; set the shape of that index ($BD61). The cell is $DD00 + $200 * y + D * 256 +
; x.
PlaceScenery:
  LD A,(HL)               ; the record's tile or shape
  OR A                    ; 0?
  RET Z                   ; the end of the list
  LD C,A                  ; C = the tile or shape
  INC HL                  ; ...
  LD E,(HL)               ; E = the column's low byte (D the high byte from the
                          ; caller)
  INC HL                  ; ...
  LD A,(HL)               ; A = the row
  INC HL                  ; HL = the next record
  PUSH HL                 ; keep the list pointer
  PUSH DE                 ; keep D, the column's high byte
  LD HL,Map             ; HL = the cell: $DD00 + 2 * y pages + DE
  ADD A,A                 ; 2 * y: a row is two pages
  ADD A,H                 ; + $DD
  LD H,A                  ; H = the row's page
  ADD HL,DE               ; + the column
  LD A,C                  ; the tile or shape:
  OR A                    ; bit 7?
  JP M,PlaceSceneryShape  ; bit 7: a shape
  CALL PutBlock           ; a single block of tile A
  JR PlaceSceneryNext     ; next record
PlaceSceneryShape:
  CALL DrawShape          ; the shape A AND $7F from this cell
PlaceSceneryNext:
  POP DE                  ; D back
  POP HL                  ; the list pointer back
  JR PlaceScenery         ; the next record

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
  LD A,(HL)               ; the record's type
  OR A                    ; $FF?
  RET M                   ; the end of the list
  LD C,A                  ; C = the type
  INC HL                  ; ...
  LD E,(HL)               ; E = the column's low byte (D the high byte from the
                          ; caller)
  INC HL                  ; ...
  LD A,(HL)               ; the row
  LD B,A                  ; B = it
  INC HL                  ; HL = the next record
  PUSH HL                 ; keep the list pointer
  PUSH DE                 ; keep D, the column's high byte
  LD HL,Map             ; HL = the cell:
  ADD A,A                 ; 2 * y: a row is two pages
  ADD A,H                 ; + $DD
  LD H,A                  ; H = the row's page
  ADD HL,DE               ; + the column
  LD A,C                  ; the type:
  OR A                    ; 0?
  JR Z,PlaceWarbase       ; type 0: a warbase
  LD (IY+$00),E           ; a factory's record
  LD (IY+$01),D           ; +1: the column's high byte
  LD (IY+$02),B           ; +2: the row
  LD (IY+$03),C           ; +3: the type, no owner yet
  LD (IY+$04),$00         ; +4: the capture count 0
  INC IY                  ; ...
  INC IY                  ; ...
  INC IY                  ; ...
  INC IY                  ; ...
  INC IY                  ; ... IY + 5: the next factory record
  PUSH BC                 ; keep the type C
  PUSH HL                 ; keep the door cell
  LD A,$81                ; shape 1, ShapeFactory
  CALL DrawShape          ; the factory's blocks
  POP HL                  ; HL = the door cell
  POP BC                  ; C = the type
  DEC H                   ; the factory's building at (x, y-2), its type
  DEC H                   ; ...
  DEC H                   ; ...
  DEC H                   ; ... two rows up: the roof row
  CALL AddBuilding        ; the roof building of type C, its product
  POP DE                  ; D back
  POP HL                  ; the list pointer back
  JR PlaceBases           ; the next record
PlaceWarbase:
  LD (IX+$00),E           ; a warbase's record
  LD (IX+$01),D           ; +1: the column's high byte
  LD (IX+$02),B           ; +2: the row
  LD (IX+$03),C           ; +3: type 0, no owner yet
  LD (IX+$04),$00         ; +4: the capture count 0
  INC IX                  ; ...
  INC IX                  ; ...
  INC IX                  ; ...
  INC IX                  ; ...
  INC IX                  ; ... IX + 5: the next warbase record
  LD A,$80                ; shape 0, ShapeWarbase
  CALL DrawShape          ; the warbase's blocks (its buildings come with
                          ; GiveWarbase)
  POP DE                  ; D back
  POP HL                  ; the list pointer back
  JR PlaceBases           ; the next record

; Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL
;
; A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block
; at the current cell, then the move to the next cell: columns (signed), rows
; (signed; a move of (0,0) ends after its tile. DrawRuins ($BC27) walks the
; same lists with debris tiles.
DrawShape:
  PUSH HL                 ; keep the cell
  LD HL,ShapeTable        ; the shapes' address table
  AND $7F                 ; the index
  CALL TableWord          ; HL = the shape's address
  EX DE,HL                ; DE = the shape
  POP HL                  ; HL = the cell
DrawShapeStep:
  LD A,(DE)               ; the step's tile
  OR A                    ; 0: no block here
  CALL NZ,PutBlock        ; a 2 x 2 block of the tile
  INC DE                  ; the step's move:
  LD A,(DE)               ; columns...
  LD C,A                  ; ... to C
  INC DE                  ; ...
  LD A,(DE)               ; rows...
  LD B,A                  ; ... to B
  INC DE                  ; DE = the next step
  OR C                    ; both 0?
  RET Z                   ; the move (0,0) ends the shape
  CALL StepCell           ; HL to the next cell
  JR DrawShapeStep        ; its tile

; HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept
;
; HL a map cell, C the columns (signed), B the rows (signed). HL += C
; sign-extended, then H += 2 * B (a map row is $200 bytes). DE kept, A lost.
; The move of one shape step for DrawShape and DrawRuins.
StepCell:
  PUSH DE                 ; keep DE
  LD E,C                  ; DE = C...
  LD D,$00                ; ... as a positive 16-bit number
  LD A,C                  ; C:
  OR A                    ; negative?
  JP P,StepCellAdd        ; no
  LD D,$FF                ; yes: DE = C sign-extended
StepCellAdd:
  ADD HL,DE               ; HL + the columns
  LD A,H                  ; the page...
  ADD A,B                 ; ... + B...
  ADD A,B                 ; ... + B: the rows, 2 pages each
  LD H,A                  ; H = the new row's page
  POP DE                  ; DE back
  RET                     ; HL = the new cell

; A 2 x 2 block of tile A with its bottom left at map cell HL
;
; Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the
; tile as it is, the other three with bit 5 set (the other parts of a block;
; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and
; DE; BC is lost. Used by the map builder, the ruins, the blast and a dead
; robot's wreck ($B133).
PutBlock:
  PUSH DE                 ; keep DE
  LD E,A                  ; E = the tile
  LD BC,$0202             ; 2 rows of 2 cells
  PUSH HL                 ; keep the anchor cell
PutBlockRow:
  PUSH BC                 ; keep the counters
  PUSH HL                 ; keep the row's first cell
PutBlockCell:
  LD (HL),E               ; the first cell plain, the rest with bit 5
  SET 5,E                 ; the following cells are the block's other parts
  INC HL                  ; the next column
  DJNZ PutBlockCell       ; 2 cells
  POP HL                  ; HL = the row's first cell
  POP BC                  ; the counters back
  DEC H                   ; the row above
  DEC H                   ; (a row is 2 pages)
  DEC C                   ; one row less
  JR NZ,PutBlockRow       ; 2 rows
  POP HL                  ; HL = the anchor cell
  POP DE                  ; DE back
  RET                     ; the block is written
