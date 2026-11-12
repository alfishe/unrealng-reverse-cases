; --------------------------------------------------------------------------------------------------------------------
; player.asm: The hero: tile probes, walking, climbing, falling, the room exits, the controls
; --------------------------------------------------------------------------------------------------------------------

; The hero's four contact flags, cleared and set by $A102 each time it runs
;
; $A102 (IY = $A0FE) zeroes them and its tile tests set them. Of their uses: +0
; and +1 are tested by $A34B before it turns the velocity $5C34 round (+0 when
; moving left, +1 when moving right), +3 is tested by $AD17 after a climb step
; and in $A34B for downward moves (known only from the code). 83 554 reads and
; 150 559 writes over the builds.
HeroProbes:
  DEFB $00,$00,$00,$00

; Probe the tiles around the hero: deadly tile, floor distance, mud, walls (SK,
; renamed)
;
; IX = the hero ($5B04). Clears the probe record $A0FE (IY) and fills it: +3
; the rows down to a floor (FloorDistance $A1F4), +0 / +1 a wall at the left /
; right edge (LeftWallCheck $A2AC, RightWallCheck $A2FA). While the status
; $5C06 is 0 and the normal tile set is in ($918C = 0) it first reads the two
; tiles under the feet (DeadlyTileProbe $A176): tile $A5 under either sets
; status $1A (the fall death, FallDeath $A888). Standing (+3 = 0) on tile $BC
; or $BD with the normal set stores the tile in $5C28 and counts passes in
; $5C29; at 50 passes status $11 (SinkInMud $AA04). Off it, $5C29 = 0. When
; $5BA0 is 0 (the hero stands on the lift, LiftPlatform $AF81) +3 is forced to
; 0.
;
; Out: $A0FE filled, IY = $A0FE; DE kept. Called from HeroUpdate $A3E1 ($A50E,
; $A576), FloatInRoom2C $A34B, BalloonRide $AC35, BalloonCrash $AC1A, BounceUp
; $AD17, JumpArc $ADAC and JumpStepY $AE37.
;
; Evidence: the $A5 test never matched in any recording ($A126 / $A12B: 11772
; tests, no match); $BC / $BD matched 26 passes in one rzx segment, the 50-pass
; sink never came ($A15A not executed).
;
; Witness: L1 21714 (c1, explorers, gameover, rzx x31).
HeroTileChecks:
  LD IY,HeroProbes
  PUSH DE
  XOR A
  LD (IY+$00),A
  LD (IY+$01),A
  LD (IY+$02),A
  LD (IY+$03),A
  LD A,(Status)            ; the probes for deadly tiles only when the status is
                          ; 0 ...
  OR A
  JR NZ,ProbeFloor
  LD A,(AltTileset)       ; ... and the normal tile set is in
  OR A
  JR NZ,ProbeFloor
  CALL DeadlyTileProbe
  LD A,B
  CP $A5
  JR Z,DeadlyTileHit
  LD A,C
  CP $A5
  JR NZ,ProbeFloor
DeadlyTileHit:
  LD A,$1A                ; tile $A5 under the feet: status $1A, the fall death
  CALL SetStatus
ProbeFloor:
  CALL FloorDistance      ; +3 = rows down to a floor tile
  XOR A
  LD (MudTile),A
  LD A,(IY+$03)
  OR A
  JR NZ,OffMudTile
  LD A,(AltTileset)
  OR A
  JR NZ,OffMudTile
  LD A,(HL)               ; HL points at the matched entry of the floor list:
                          ; the floor tile itself
  CP $BC
  JR Z,OnMudTile
  CP $BD
  JR NZ,OffMudTile
OnMudTile:
  LD (MudTile),A            ; $5C28 = the tile ($BC or $BD), $5C29 counts the
                          ; passes on it
  LD HL,MudPasses
  INC (HL)
  LD A,(HL)
  CP $32                  ; 50 passes on mud: status $11 (sink)
  JR C,ProbeWalls
  LD A,$11
  LD (Status),A
  JR ProbeWalls
OffMudTile:
  XOR A                   ; not on mud: the count restarts
  LD (MudPasses),A
ProbeWalls:
  CALL LeftWallCheck      ; +0 left edge, +1 right edge
  CALL RightWallCheck
  LD A,(NotOnLift)            ; on the lift ($5BA0 = 0) the hero always stands
  OR A
  JR NZ,HeroTileChecksEnd
  LD (IY+$03),A
HeroTileChecksEnd:
  POP DE
  RET

; Read the two tiles under the hero's feet
;
; IX = the hero. C = the tile at (X + 8, Y + 23), B = the tile at (X + 16, Y +
; 23), both read from the tile map $F800 through PixelToTileMap $A293. Called
; only from HeroTileChecks $A102, which compares both with $A5.
;
; Witness: L1 11772 (c1, explorers, gameover, rzx x23).
DeadlyTileProbe:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,H
  ADD A,$17
  LD H,A
  PUSH HL
  LD A,L
  ADD A,$08
  LD L,A
  CALL PixelToTileMap
  LD C,(HL)
  POP HL
  LD A,L
  ADD A,$10
  LD L,A
  CALL PixelToTileMap
  LD B,(HL)
  RET

; Is the tile under the middle of the hero's feet a ladder tile? (SK, renamed)
;
; IX = the hero. Reads the tile at (X + 12, Y + 23). Out: Z set when it is a
; climbing tile: $98 or $99 in every room, also $92 and $95 in rooms below $0C;
; with the other tile set ($918C not 0) $C6, $C7, $CE or $CF instead. X + 12
; past $FF returns NZ (A = 1).
;
; Called from HeroUpdate $A3E1 for down ($A4BA), up ($A4D5) and every pass
; ($A52E: on a ladder the hero neither falls nor lands). Witness of the names:
; down and up move the hero 2 pixels a pass only while it is Z, with the frames
; $20-$23 (ClimbFrame $A4E8): 439 climbing passes in 8 rzx segments.
;
; Witness: L1 16548 (c1, explorers, gameover, rzx x31).
OnLadder:
  LD A,(IX+$00)
  ADD A,$0C
  JR C,LadderOffRight
  LD L,A
  LD A,(IX+$01)
  ADD A,$17
  LD H,A
  LD A,(AltTileset)
  OR A
  JR NZ,LadderAltSet
  LD A,(Room)            ; rooms below $0C (CP leaves carry) also take $92 and
                          ; $95
  CP $0C
  PUSH AF
  CALL PixelToTileMap
  POP AF
  LD A,(HL)
  JR NC,LadderTileBoth
  CP $92
  RET Z
  CP $95
  RET Z
LadderTileBoth:
  CP $98                  ; $98 and $99: ladders in every room
  RET Z
  CP $99
  RET
LadderOffRight:
  XOR A                   ; X + 12 past the right edge: NZ
  INC A
  RET
LadderAltSet:
  CALL PixelToTileMap     ; the other tile set's climbing tiles
  LD A,(HL)
  CP $C6
  RET Z
  CP $C7
  RET Z
  CP $CE
  RET Z
  CP $CF
  RET

; Rows from the hero's head down to a floor tile, the probe record kept (SK,
; renamed)
;
; IX = the hero, IY = $A0FE. Runs the floor scan FloorScanFrom $A208 from (X +
; 12, Y - 1) instead of under the feet and returns the row count in A (0 = a
; floor or ceiling tile at the head), Z set when 0. (IY+3) is saved and put
; back. Called only from FloatInRoom2C $A34B ($A3B4): a rising hero bounces off
; a tile at its head.
;
; Witness: L1 69 (rzx x2).
HeadroomRows:
  PUSH BC
  LD A,(IY+$03)
  PUSH AF
  LD (IY+$03),$00
  LD A,(IX+$00)
  ADD A,$0C
  LD L,A
  LD A,(IX+$01)
  DEC A
  CALL FloorScanFrom
  LD C,(IY+$03)
  POP AF
  LD (IY+$03),A
  LD A,C
  POP BC
  OR A
  RET

; Count the tile rows from under the hero's feet down to a floor tile (SK,
; renamed)
;
; IX = the hero, IY = $A0FE. From the row under the feet (X + 12, Y + 24) each
; row's tile at that column is looked up in FloorTiles $A234 (AltFloorTiles
; $A264 with the other set); the list runs on into the solid tiles to its $00
; end. (IY+3) = the rows passed before a match: 0 = standing on a floor. When
; the scan or the start reaches Y $80 (the bottom of the play window) (IY+3) =
; 5. Out: HL points at the matched list entry, Z set on a match.
;
; HeroUpdate $A3E1 reads (IY+3): 0 stand or land, 1-4 fall, 5 or more refuse
; the drop (RefuseDrop $A545) unless the umbrella is in use.
;
; Witness: L1 21714 (c1, explorers, gameover, rzx x31).
FloorDistance:
  LD A,(IX+$00)
  ADD A,$0C
  LD L,A
  LD A,(IX+$01)
  ADD A,$18
  CP $7F
  JR C,FloorScanFrom
; This entry point is used by the routine at FloorScanFrom.
FloorNone:
  LD (IY+$03),$05         ; past the bottom of the play window: 5 rows
  RET

; The floor scan from a given point
;
; A = the start Y, L = the X; IY+3 counts the rows. Entered from FloorDistance
; $A1F4 and HeadroomRows $A1D3. BC keeps the current point.
;
; Witness: L1 21782 (c1, explorers, gameover, rzx x31).
FloorScanFrom:
  LD H,A
  PUSH HL
  POP BC
FloorScanRow:
  CALL PixelToTileMap     ; one row: the tile against the list
  EX DE,HL
  LD HL,FloorTiles
  LD A,(AltTileset)
  OR A
  JR Z,FloorScanMatch
  LD HL,AltFloorTiles
FloorScanMatch:
  LD A,(DE)               ; Z: a floor tile
  CP (HL)
  RET Z
  LD A,(HL)
  OR A
  JR Z,FloorScanNext
  INC HL
  JR FloorScanMatch
FloorScanNext:
  LD A,B                  ; next row down; at Y $80 the scan gives up with 5
  LD L,C
  ADD A,$08
  LD H,A
  LD B,A
  CP $80
  JR NC,FloorNone
  INC (IY+$03)
  JR FloorScanRow

; The floor tiles: stand on, walk through (23 bytes), then the solid tiles to
; their $00 end
;
; FloorDistance $A1F4 scans this list from its start through ExtraSolidTiles
; $A242 and SolidTiles $A24B to the $00 at $A263, so every listed tile is a
; floor; the first 14 ($95, $AC-$B0, $CF, $BC, $BD, $C0, $C1, $C8-$CA) are
; floors only: no wall test reads them. $BC and $BD are the mud tiles of
; HeroTileChecks $A102. Read on every pass in every play recording (58740 reads
; of $A234).
FloorTiles:
  INCBIN "res/tables/floor-tiles.bin",$0000,14
ExtraSolidTiles:
  INCBIN "res/tables/floor-tiles.bin",$000E,9

; The solid tiles of the normal tile set: walls and floors, $00 end
;
; WallColumnCheck $A2B2 compares the tiles of a column with this list (from
; ExtraSolidTiles $A242 in rooms $18 and up); a match stops a walk (HeroUpdate
; $A51A) or turns a creature.
SolidTiles:
  INCBIN "res/tables/solid-tiles.bin",$0000,25

; The floor tiles of the other tile set (4 bytes), then the solid ones to their
; $00 end
;
; The other tile set is in when $918C is not 0 (the 15 rooms of AltTilesetRooms
; $9AC6). FloorDistance $A1F4 scans from here instead of FloorTiles $A234.
AltFloorTiles:
  INCBIN "res/tables/alt-floor-tiles.bin",$0000,4
AltExtraSolidTiles:
  INCBIN "res/tables/alt-floor-tiles.bin",$0004,9

; The solid tiles of the other tile set, $00 end
;
; The first 15 are those of SolidTiles $A24B, then 18 of the other set.
AltSolidTiles:
  INCBIN "res/tables/alt-solid-tiles.bin",$0000,34

; Turn a pixel point into its tile map address (SK)
;
; L = X, H = Y (pixels). Out: HL = $F800 + (Y / 8) * 32 + X / 8, the room's
; tile map (32 x 16). DE kept. The one lookup of every probe here and of the
; creatures' probes. 241661 calls in all recordings.
;
; Witness: L1 241661 (c1, explorers, gameover, rzx x31).
PixelToTileMap:
  PUSH DE
  SRL L
  SRL L
  SRL L
  LD A,H
  RLCA
  RLCA
  LD H,A
  AND $E0
  OR L
  LD L,A
  LD A,H
  AND $01
  LD H,A
  LD DE,TileMap
  ADD HL,DE
  POP DE
  RET

; Is there a solid tile in the column of the object's left edge? (SK, renamed)
;
; IX = the object (the hero or a creature), IY = its probe record. Takes (X, Y)
; and runs WallColumnCheck $A2B2: (IY+0) = 1 when a solid tile is there. Called
; from HeroTileChecks $A102 and the creature code $C0FD.
;
; Witness: L1 26266 (c1, explorers, gameover, rzx x31).
LeftWallCheck:
  LD L,(IX+$00)
  LD H,(IX+$01)

; Look for a solid tile in a column 3 or 4 rows high
;
; HL = the top point (L = X, H = Y). (IY+0) = 0, then each of 3 tile rows from
; H down (4 when H is not on a row boundary) is compared with SolidTiles $A24B
; (AltSolidTiles $A271 with the other set); from room $18 on the list starts at
; ExtraSolidTiles $A242 (AltExtraSolidTiles $A268). Any match sets (IY+0) = 1.
;
; Witness: L1 49704 (c1, explorers, gameover, rzx x31).
WallColumnCheck:
  LD (IY+$00),$00
  LD B,$03
  LD A,H
  AND $07
  JR Z,WallColumnRow
  INC B
WallColumnRow:
  PUSH BC                 ; one row of the column
  PUSH HL
  CALL PixelToTileMap
  LD DE,SolidTiles
  LD A,(AltTileset)
  OR A
  JR Z,WallSetChosen
  LD DE,AltSolidTiles
WallSetChosen:
  LD A,(Room)            ; rooms $18 and up: the nine extra solid tiles count
                          ; as walls
  CP $18
  JR C,WallColumnLoop
  LD DE,ExtraSolidTiles
  LD A,(AltTileset)
  OR A
  JR Z,WallColumnLoop
  LD DE,AltExtraSolidTiles
WallColumnLoop:
  LD A,(DE)
WallColumnCompare:
  CP (HL)
  JR Z,WallColumnHit
  INC DE
  LD A,(DE)
  OR A
  JR NZ,WallColumnCompare
  JR WallColumnNext
WallColumnHit:
  LD (IY+$00),$01         ; a solid tile: (IY+0) = 1
WallColumnNext:
  POP HL                  ; next row down
  LD A,H
  ADD A,$08
  LD H,A
  POP BC
  DJNZ WallColumnRow
  RET

; Is there a solid tile in the column of the object's right edge? (SK, renamed)
;
; IX = the object, IY = its probe record. WallColumnCheck $A2B2 at (X + 23, Y)
; with IY moved up one: the result goes to (IY+1). Called from HeroTileChecks
; $A102 and the creature code $C109.
;
; Witness: L1 23438 (c1, explorers, gameover, rzx x31).
RightWallCheck:
  LD A,(IX+$00)
  ADD A,$17
  LD L,A
  LD H,(IX+$01)
  INC IY
  CALL WallColumnCheck
  DEC IY
  RET

; Is the tile under the middle of the object's feet solid? Result in (IY+1)
;
; IX = the object, IY = its record. SolidTileAt $A328 at (X + 12, Y + 24) with
; IY moved up one. Called only from the creature code $C121 (3402 calls, 21 rzx
; segments).
;
; Witness: L1 3402 (rzx x21).
CreatureFloorBelow:
  LD A,(IX+$00)
  ADD A,$0C
  LD L,A
  LD A,(IX+$01)
  ADD A,$18
  LD H,A
  INC IY
  CALL SolidTileAt
  DEC IY
  RET

; Is the tile at the middle of the object's top row solid? Result in (IY+0)
;
; IX = the object, IY = its record. SolidTileAt $A328 at (X + 12, Y). Called
; only from the creature code $C115.
;
; Witness: L1 138 (rzx x3).
CreatureSolidAt:
  LD A,(IX+$00)
  ADD A,$0C
  LD L,A
  LD H,(IX+$01)

; Compare one tile with the solid list from ExtraSolidTiles
;
; HL = the pixel point. (IY+0) = 1 when the tile is in ExtraSolidTiles $A242
; (AltExtraSolidTiles $A268 with the other set) or the solid list after it,
; else 0.
;
; Witness: L1 3540 (rzx x21).
SolidTileAt:
  LD (IY+$00),$00
  CALL PixelToTileMap
  LD DE,ExtraSolidTiles
  LD A,(AltTileset)
  OR A
  JR Z,SolidTileLoop
  LD DE,AltExtraSolidTiles
SolidTileLoop:
  LD A,(DE)
SolidTileCompare:
  CP (HL)
  JR Z,SolidTileHit
  INC DE
  LD A,(DE)
  OR A
  JR NZ,SolidTileCompare
  JR SolidTileDone
SolidTileHit:
  LD (IY+$00),$01
SolidTileDone:
  RET

; The hero's update in room $2C: floating with momentum, bouncing off walls
; (SK, renamed)
;
; The room handler of room $2C (RoomScripts $B7EC, reached through $B7DD and
; JumpThroughWord $A6DD from HeroUpdate $A3E1). POP AF drops the return into
; HeroUpdate, so this replaces the whole update in that room. Status 0
; (ClearStatus $AE84), frame $1A, the probes (HeroTileChecks $A102).
;
; The input ($B87D) steps the velocity $5C34 (C = X, B = Y) by 1 a pass towards
; the held direction, each kept within -3..3. A wall at the leading edge
; ((IY+1) going right, (IY+0) going left), a floor under the feet going down,
; or a tile at the head going up (HeadroomRows $A1D3) negates that component:
; the hero bounces. The facing follows the sign of C; X and Y move by the
; velocity. X below 4 leaves by the left exit (ExitLeft $A640); this routine
; has no right or vertical exit.
;
; Evidence: rzx18000 frames 1769-1997 and rzx20000 frames 0-312 (149 passes);
; the screen there shows the hero floating in a lab of floating objects.
; Reached only through the room handler table.
;
; Witness: L1 149 (rzx x2).
FloatInRoom2C:
  POP AF
  CALL ClearStatus
  LD (IX+$02),$1A
  CALL HeroTileChecks
  CALL ReadControls
  LD E,A
  LD BC,(FloatVelocity)
  BIT 0,E                 ; right: X velocity up to 3
  JR Z,FloatLeft
  INC C
  LD A,C
  CP $04
  JR NZ,FloatLeft
  DEC C
FloatLeft:
  BIT 1,E                 ; left: X velocity down to -3
  JR Z,FloatDown
  DEC C
  LD A,C
  CP $FC
  JR NZ,FloatDown
  INC C
FloatDown:
  BIT 2,E                 ; down: Y velocity up to 3
  JR Z,FloatUp
  INC B
  LD A,B
  CP $04
  JR NZ,FloatUp
  DEC B
FloatUp:
  BIT 3,E                 ; up: Y velocity down to -3
  JR Z,FloatBounceX
  DEC B
  LD A,B
  CP $FC
  JR NZ,FloatBounceX
  INC B
FloatBounceX:
  BIT 7,C                 ; moving right: a wall at the right edge reverses it
  JR NZ,FloatBounceLeft
  BIT 0,(IY+$01)
  JR Z,FloatBounceY
  LD A,C
  NEG
  LD C,A
  JR FloatBounceY
FloatBounceLeft:
  BIT 0,(IY+$00)          ; moving left: a wall at the left edge reverses it
  JR Z,FloatBounceY
  LD A,C
  NEG
  LD C,A
FloatBounceY:
  BIT 7,B                 ; moving down: a floor under the feet reverses it
  JR NZ,FloatBounceUp
  LD A,(IY+$03)
  OR A
  JR NZ,FloatApply
  LD A,B
  NEG
  LD B,A
  JR FloatApply
FloatBounceUp:
  CALL HeadroomRows       ; moving up: a tile at the head reverses it
  JR NZ,FloatApply
  LD A,B
  NEG
  LD B,A
FloatApply:
  LD (FloatVelocity),BC           ; store the velocity, set the facing, move
  RES 7,(IX+$03)
  BIT 7,C
  JR NZ,FloatMove
  SET 7,(IX+$03)
FloatMove:
  LD A,B
  ADD A,(IX+$01)
  LD (IX+$01),A
  LD A,C
  ADD A,(IX+$00)
  LD (IX+$00),A
  CP $04                  ; X below 4: the room to the left
  RET NC
  JP ExitLeft

; The hero's update, once a main-loop pass: room handler, status, walk, jump,
; climb, fall, exits (SK)
;
; Called from the main loop $9018 ($902B) every pass, IX = the hero. In order:
;
; 1. The room handler of the current room ($B7DD: RoomScripts $B7EC through
; JumpThroughWord $A6DD). A handler that starts with POP (FloatInRoom2C $A34B)
; replaces the rest.
;
; 2. IY = $A0FE, SP saved in SavedSP $AF39 (JumpHoleCheck $AF09 unwinds to it).
; A frame list in progress (FrameListPtr $AEED not 0) plays one frame
; (FrameListPlay $AEB9) and nothing else happens.
;
; 3. E = the input ($B87D: bit 0 right, 1 left, 2 down, 3 up, 4 fire). Status
; 0: StatusZeroTriggers $AF3B (enter the balloon, the barrel spot of room $1D).
; The position is saved in $5C09 / $5C0A.
;
; 4. StatusDispatch $A6CC: a status other than 0 runs its handler, which drops
; the return and ends the update.
;
; 5. TeleportPadCheck $B03B; standing (probe +3 = 0 from the last pass):
; ThinkKey $B02E (T). With item $0A in use ($5B98) in room $14 or $08: status 4
; (Hover $AD32), frame $1D, Y - 8.
;
; 6. While falling ($5C04 not 0) the input is ignored. Fire starts a jump
; (StartJump $A465) when the hero stands, is not on the lift ($5BA0), not on
; the unicycle ($5BFA = 0) and, in room $1A, Y >= $3A: status 2, $5C03 = $82,
; $5C08 = the input, sound 6 ($C4B2).
;
; 7. Right / left: X +- 2 and the facing; X >= $E8 leaves right (ExitRight
; $A671), X < 4 left (ExitLeft $A640). Down / up on a ladder tile (OnLadder
; $A193): Y +- 2, the climb frames $20-$23; Y >= $67 leaves down (ExitDown
; $A6AE), above 0 up (ExitUp $A69B; in room $18 the hero hops out of the ladder
; top with status 3).
;
; 8. The probes (HeroTileChecks $A102). A wall at the leading edge puts X back.
; Then: on a ladder nothing more (HeroWalkFrames $A5E3); standing: land
; ($A5B9); a drop of 1-4 rows: fall 4 pixels a pass ($A570); 5 or more: refuse
; (RefuseDrop $A545).
;
; Witness: L1 26517 (c1, explorers, gameover, rzx x31).
HeroUpdate:
  CALL RunRoomScript
  LD IY,HeroProbes        ; IY = the probe record $A0FE for the whole update
  LD (SavedSP),SP         ; JumpHoleCheck $AF09 restores SP from here to leave
                          ; from deep inside the update
  LD HL,(FrameListPtr)    ; a frame list in progress replaces the update
  LD A,H
  OR L
  JP NZ,FrameListPlay
  CALL ReadControls
  LD E,A
  LD A,(Status)
  OR A
  CALL Z,StatusZeroTriggers ; status 0: the balloon and barrel triggers
  LD IX,Hero
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (HeroSavedXY),HL           ; the position before this pass: walls and refusals
                          ; put it back
  CALL StatusDispatch     ; a status handler drops the return and ends the
                          ; update here
  CALL TeleportPadCheck
  LD A,(IY+$03)
  OR A
  CALL Z,ThinkKey         ; standing: the T key thinks
  LD A,(HeldItem)            ; item $0A in use in room $14 or $08: hover
  CP $0A
  JR NZ,HeroInput
  LD A,(Room)
  CP $14
  JR Z,StartHover
  CP $08
  JR NZ,HeroInput
StartHover:
  LD A,$04                ; status 4, frame $1D, lift the hero 8 pixels
  LD (Status),A
  LD A,$1D
  LD (IX+$02),A
  LD A,(IX+$01)
  SUB $08
  RET C
  LD (IX+$01),A
  RET
HeroInput:
  LD A,(Falling)            ; falling: no input
  OR A
  JR Z,HeroFire
  LD E,$00
HeroFire:
  BIT 4,E                 ; fire: a jump if allowed
  JR Z,HeroRight
  LD A,(NotOnLift)
  OR A
  JR Z,HeroRight
  LD A,(UnicycleFrames)
  OR A
  JR NZ,HeroRight
  LD A,(Room)
  CP $1A
  JR NZ,StartJump
  LD A,(IX+$01)
  CP $3A
  JR C,HeroRight
StartJump:
  LD L,(IX+$00)           ; status 2 with the input as the direction, sound 6
  LD H,(IX+$01)
  LD (HeroSavedXY),HL
  LD A,(IY+$03)
  OR A
  JR NZ,HeroRight
  LD A,$02
  LD (Status),A
  LD A,$82
  LD (RefuseCount),A
  LD A,E
  LD (JumpDirection),A
  LD A,$06
  JP PlaySound
HeroRight:
  BIT 0,E                 ; right: 2 pixels, face right, X >= $E8 the next room
  JR Z,HeroLeft
  SET 7,(IX+$03)
  INC (IX+$00)
  INC (IX+$00)
  LD A,(IX+$00)
  CP $E8
  JP NC,ExitRight
HeroLeft:
  BIT 1,E                 ; left: 2 pixels, face left, X < 4 the room to the
                          ; left
  JR Z,HeroDown
  RES 7,(IX+$03)
  DEC (IX+$00)
  DEC (IX+$00)
  LD A,(IX+$00)
  CP $04
  JP C,ExitLeft
HeroDown:
  BIT 2,E                 ; down: only on a ladder tile, 2 pixels
  JR Z,HeroUp
  INC (IX+$01)
  CALL OnLadder
  JR Z,ClimbDown
  DEC (IX+$01)
  JR HeroUp
ClimbDown:
  INC (IX+$01)            ; on a ladder: the second pixel, Y >= $67 the room
                          ; below
  LD A,(IX+$01)
  CP $67
  JP NC,ExitDown
  JR ClimbFrame
HeroUp:
  BIT 3,E                 ; up: only on a ladder tile, 2 pixels
  JR Z,HeroProbe
  CALL OnLadder
  JR NZ,HeroProbe
  LD A,(IX+$01)
  DEC A
  JP M,ClimbOutTop
  DEC A
  JP M,ClimbOutTop
  LD (IX+$01),A
ClimbFrame:
  AND $06                 ; frame $20 + (Y AND 6) / 2: the four climb frames
  RRCA
  ADD A,$20
  LD (IX+$02),A
  RET
ClimbOutTop:
  LD A,(Room)            ; above the top: the room above; room $18 hops out
                          ; with status 3
  CP $18
  JP NZ,ExitUp
  PUSH IX
  CALL ExitUp
  POP IX
  LD (IX+$01),$60
  XOR A
  LD (JumpDirection),A
  LD A,$03
  JP SetStatus
HeroProbe:
  PUSH DE                 ; the probes, then the walls
  CALL HeroTileChecks
  POP DE
  XOR A
  BIT 0,E
  JR Z,HeroWallLeft
  LD A,(IY+$01)
HeroWallLeft:
  BIT 1,E
  JR Z,HeroWallTest
  LD A,(IY+$00)
HeroWallTest:
  OR A                    ; a wall ahead: X back, no left or right this pass
  JR Z,HeroGround
  LD HL,(HeroSavedXY)
  LD (IX+$00),L
  LD A,E
  AND $0C
  LD E,A
HeroGround:
  CALL OnLadder           ; ladder, stand, fall or refuse
  JP Z,HeroWalkFrames
  LD A,(IY+$03)
  OR A
  JR Z,HeroLand
  CP $05                  ; a drop of 5 rows or more ...
  JR C,HeroFallTest
  LD A,(HeldItem)            ; ... is taken with the umbrella (item 5) in use
  CP $05
  JR Z,HeroFallTest
RefuseDrop:
  LD HL,(HeroSavedXY)           ; refuse: the position back; the third refusal in a
                          ; row jumps (status 1)
  LD (IX+$00),L
  LD (IX+$01),H
  LD HL,RefuseCount
  LD A,(HL)
  AND $7F
  CP $03
  JR Z,HeroFall
  INC (HL)
  LD A,(HL)
  CP $03
  JR NZ,RefuseShake
  LD A,E                  ; the third refusal: status 1, the jump off the edge
                          ; in the held direction
  LD (JumpDirection),A
  LD A,$01
  LD (Status),A
RefuseShake:
  LD HL,RefuseFrames      ; play RefuseFrames: the hero shakes his head
  JP StartFrameList
HeroFallTest:
  OR A
  JR Z,HeroLand
HeroFall:
  INC (IX+$01)            ; fall: 2 pixels, probe, 2 more while still above the
                          ; floor
  INC (IX+$01)
  CALL HeroTileChecks
  LD A,(IY+$03)
  OR A
  JR Z,HeroFalling
  INC (IX+$01)
  INC (IX+$01)
  LD A,(Room)            ; count the fall passes ($5C05) unless the umbrella
                          ; is in use ...
  CP $35
  JR NC,HeroFallCount
  BIT 7,(IX+$00)
  JR NZ,HeroFallUmbrella
  CP $10
  JR Z,HeroFallCount
  CP $1C
  JR Z,HeroFallCount
HeroFallUmbrella:
  LD A,(HeldItem)            ; ... rooms $35 and up, and rooms $10 and $1C left of
                          ; X $80, count even with it
  CP $05
  JR Z,HeroFalling
HeroFallCount:
  LD HL,FallPasses             ; $5C05 + 1, kept at 255
  INC (HL)
  JR NZ,HeroFalling
  DEC (HL)
HeroFalling:
  LD E,$00                ; $5C04 = 1, no input; Y >= $68 the room below
  LD A,$01
  LD (Falling),A
  LD A,(IX+$01)
  CP $68
  JP NC,ExitDown
  JR HeroWalkAnim
HeroLand:
  LD HL,FallPasses             ; land: 20 fall passes or more kill (status $1A); Y
                          ; onto the row
  LD A,(HL)
  LD (HL),$00
  CP $14
  LD A,$1A
  CALL NC,SetStatus
  LD A,(IX+$01)
  AND $F8
  LD (IX+$01),A
  LD A,(MudTile)            ; on a mud tile the feet sink 2 ($BC) or 4 ($BD)
                          ; pixels into it
  OR A
  JR Z,HeroWalkFrames
  LD C,$02
  CP $BC
  JR Z,HeroSinkIn
  LD C,$04
HeroSinkIn:
  LD A,(IX+$01)
  OR C
  LD (IX+$01),A

; End of the hero update: the walk cycle and the item frames
;
; Clears the refusal count $5C03 and the falling flag $5C04, then (from
; HeroWalkAnim $A5EA, where a fall also comes) sets the frame: a held direction
; steps the walk cycle 0-3 on every other pass (PassCount $5C02 bit 0), no
; direction gives frame 2. On the unicycle ($5BFA not 0) the frames are
; $3C-$3F; with item $0C in use ($5B98) frames 0-3 become $10-$13; falling with
; the umbrella (item 5) 4 rows or more above the floor gives frame $0B.
;
; Status 6 enters at Status6Entry $A5F0 (StatusHandlers $A72E): the hero stays
; in place and only animates; it is set by RopeTrick $BC73 ($BCB4, a note of
; the Flute in room $10).
;
; Witness: L1 15541 (c1, explorers, gameover, rzx x31).
HeroWalkFrames:
  XOR A
  LD (RefuseCount),A
  LD (Falling),A
; This entry point is used by the routine at HeroUpdate.
HeroWalkAnim:
  LD A,E
  AND $0F
  JR Z,HeroStandFrame
  PUSH AF
Status6Entry:
  POP AF                  ; status 6 enters here: POP AF drops the return into
                          ; HeroUpdate
  LD A,(PassCount)
  AND $01
  JR Z,HeroUnicycleFrames
  LD A,(IX+$02)
  INC A
  AND $03
  LD (IX+$02),A
HeroUnicycleFrames:
  LD A,(UnicycleFrames)
  OR A
  JR Z,HeroItem0CFrames
  LD A,(IX+$02)
  AND $03
  ADD A,$3C
  LD (IX+$02),A
HeroItem0CFrames:
  LD A,(HeldItem)
  CP $0C
  JR NZ,HeroUmbrellaFrame
  LD A,(IX+$02)
  CP $04
  JR NC,HeroUmbrellaFrame
  SET 4,(IX+$02)
HeroUmbrellaFrame:
  LD A,(Falling)            ; falling with the umbrella high above the floor:
                          ; frame $0B
  OR A
  RET Z
  LD A,(HeldItem)
  CP $05
  RET NZ
  LD A,(IY+$03)
  CP $04
  RET C
  LD (IX+$02),$0B
  RET
HeroStandFrame:
  LD A,$02
  LD (IX+$02),A
  JR HeroUnicycleFrames

; Leave the room by the left edge (SK, renamed)
;
; The room to the left: same level, column - 1, column 0 wrapping to 11
; (RoomToLevelColumn $AEEF, LevelColumnToRoom $AEFD). From room $29 the room is
; ExplorerRooms $A66C[Explorer $5B70] instead. X = $E6, then the room is set up
; ($9855). Called from HeroUpdate $A3E1, FloatInRoom2C $A34B and JumpArc $ADAC.
; Evidence: 30 exits in 17 rzx segments, 3 of them wrapping; the room $29 path
; once (rzx, explorer 0).
;
; Witness: L1 30 (rzx x17).
ExitLeft:
  LD A,(Room)
  CP $29
  JR NZ,ExitLeftGrid
  LD A,(Explorer)
  LD L,A
  LD H,$00
  LD DE,ExplorerRooms
  ADD HL,DE
  LD A,(HL)
  LD (Room),A
  JR ExitLeftEnter
ExitLeftGrid:
  CALL RoomToLevelColumn
  LD A,C
  SUB $01
  JR NC,ExitLeftWrap
  LD A,$0B
ExitLeftWrap:
  LD C,A
  CALL LevelColumnToRoom
ExitLeftEnter:
  LD (IX+$00),$E6         ; the hero at the right edge
  JP SetUpRoom

; Each explorer's own room: entered from room $29 to the left, left back to
; room $29 to the right (SK, renamed)
;
; Rooms $2D, $2E, $2F, $46 and $47 for explorers 0-4. ExitLeft $A640 reads the
; explorer's byte; ExitRight $A671 sends the hero from any of these rooms to
; room $29. Each has its room handler (RoomScripts $B7EC: $B370, ExplorerRoom2E
; $B263, ExplorerRoom2F $B22D, ExplorerRoom46 $B2EB, ExplorerRoom47 $B18A), and
; each handler tests one item: the explorer's key item of the instructions.
; Evidence: the RZX run plays explorer 0 (one extra read of $A66C at the room
; $29 exit).
ExplorerRooms:
  INCBIN "res/tables/explorer-rooms.bin",$0000,5

; Leave the room by the right edge (SK, renamed)
;
; From a room of ExplorerRooms $A66C the hero goes to room $29; else same
; level, column + 1, 11 wrapping to 0. X = 2, then the room is set up ($9855).
; Called from HeroUpdate $A3E1, JumpArc $ADAC and BarrelRideLong $AABA.
; Evidence: 38 exits in gameover and 18 rzx segments; the explorer room path
; once.
;
; Witness: L1 38 (gameover, rzx x18).
ExitRight:
  LD HL,ExplorerRooms
  LD B,$05
  LD A,(Room)
ExitRightPortal:
  CP (HL)
  JR Z,ExitRightToRoom29
  INC HL
  DJNZ ExitRightPortal
  CALL RoomToLevelColumn
  LD A,C
  INC A
  CP $0C
  JR NZ,ExitRightGrid
  XOR A
ExitRightGrid:
  LD C,A
  CALL LevelColumnToRoom
ExitRightEnter:
  LD (IX+$00),$02         ; the hero at the left edge
  JP SetUpRoom
ExitRightToRoom29:
  LD A,$29
  LD (Room),A
  JR ExitRightEnter

; Leave the room by the top: the room one level up (SK, renamed)
;
; Level - 1; on level 0 the hero is put back to $5C09 / $5C0A (ExitBlocked
; $A6C2). Y = $66, then the room is set up ($9855). Called from HeroUpdate
; $A3E1, BalloonRide $AC35, BounceUp $AD17, Hover $AD32, JumpStepY $AE37 and
; LiftUp $A96B. Evidence: 13 calls, 5 of them blocked.
;
; Witness: L1 13 (gameover, rzx x8).
ExitUp:
  CALL RoomToLevelColumn
  LD A,B
  SUB $01
  JR C,ExitBlocked
  LD B,A
  CALL LevelColumnToRoom
  LD (IX+$01),$66
  JP SetUpRoom

; Leave the room by the bottom: the room one level down (SK, renamed)
;
; Level + 1; level 6 does not exist, so from level 5 the hero is put back
; (ExitBlocked $A6C2). Y = 2, then the room is set up ($9855). Called from
; HeroUpdate $A3E1, BalloonRide $AC35, Hover $AD32, LiftDown $A9C4,
; JumpHoleCheck $AF09 and ExitDownSaved $AE6A.
;
; Witness: L1 13 (gameover, rzx x9).
ExitDown:
  CALL RoomToLevelColumn
  LD A,B
  INC A
  CP $06
  JR Z,ExitBlocked
  LD B,A
  CALL LevelColumnToRoom
  LD (IX+$01),$02
  JP SetUpRoom
; This entry point is used by the routine at ExitUp.
ExitBlocked:
  LD HL,(HeroSavedXY)           ; no room there: the position before this pass
  LD (IX+$00),L
  LD (IX+$01),H
  RET

  ORG $AF09

; On the jump's last step over the hole of $5BA2: fall to the room below
;
; A = the step; only step $10. OverHole $AF22 with status 2: SP back to SavedSP
; $AF39 and ExitDown $A6AE. Evidence: once in an rzx segment.
;
; Witness: L1 2366 (gameover, rzx x23).
JumpHoleCheck:
  CP $10
  RET NZ
  EX AF,AF'
  CALL OverHole
  JR C,JumpHoleDone
  LD A,(Status)
  CP $02
  JR NZ,JumpHoleDone
  LD SP,(SavedSP)
  JP ExitDown
JumpHoleDone:
  EX AF,AF'
  RET

; Is the hero over the hole whose tile map address is $5BA2?
;
; $5BA2 = 0: carry. Else its column x 8 against the hero's X: no carry when X
; is within 8 pixels right of it. Also called by WellFront $9A09.
;
; Witness: L1 26583 (c1, explorers, gameover, rzx x31).
OverHole:
  LD HL,(WellHole)
  LD A,H
  OR L
  SCF
  RET Z
  LD A,L
  AND $1F
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD A,(Hero)
  SUB L
  RET C
  CP $08
  CCF
  RET

; The SP at HeroUpdate's start (JumpHoleCheck returns from here)
SavedSP:
  DEFW $0000

  ORG $B87C

; The controls read this pass: bit 0 right, 1 left, 2 down, 3 up, 4 fire
;
; Written by ReadDevice $B894 every call (cleared, then the bits of the pressed
; controls) and read back at its end ($B930). Witness: written in all 34 builds
; (52351 writes).
InputBits:
  DEFB $00

; Read the controls; both left and right, or both up and down, read as nothing
;
; Out: A = the InputBits of ReadDevice $B894, or 0 when bits 0 and 1 or bits 2
; and 3 are both set; E = the raw InputBits on every path. Called by $A3E1
; every pass ($A3F4), by $A34B ($A356), by $AF81 ($AFBA, which tests E: up +
; down there gives down, status 20) and by TelescopeRoom $B16A ($B17F).
;
; Witness: L1 26612 (c1, explorers, gameover, rzx x31). The cancel branches
; ($B887, $B890) are not executed in any recording (c1, explorers, gameover,
; the 31 rzx builds).
ReadControls:
  CALL ReadDevice
  LD E,A
  AND $03
  CP $03
  JR NZ,ReadControlsUpDown
  XOR A
  RET
ReadControlsUpDown:
  LD A,E                  ; up and down both?
  AND $0C
  CP $0C
  JR NZ,ReadControlsDone
  XOR A
  RET
ReadControlsDone:
  LD A,E
  RET

; Read the chosen device into InputBits: keyboard, Kempston or Sinclair
;
; Device $94AF (the device menu: 0 keyboard, 1 Kempston, 2 Sinclair). Keyboard
; (ReadKeyboard $B8FE): SPACE fire, Z left, X right, O up, K down (the Help
; page of the selector: "Z=Left X=Right O=Up K=Down <SPACE> -Jump"). Kempston:
; IN ($1F) AND $1F, already in the InputBits order. Sinclair (port $EFFE, keys
; 6-0): 0 fire, 6 left, 7 right, 9 up, 8 down. Out: A = InputBits $B87C.
;
; Witness: explorers reads all three (keyboard 849 and Sinclair 853 passes,
; Kempston in every build).
;
; Witness: L1 26612 (c1, explorers, gameover, rzx x31).
ReadDevice:
  LD HL,InputBits
  LD (HL),$00
  LD A,(InputDevice)
  OR A
  JP Z,ReadKeyboard
  DEC A
  JR Z,ReadKempston
  LD BC,$EFFE             ; device 2: Sinclair, keys 6 7 8 9 0
  IN A,(C)
  AND $1F
  BIT 0,A
  JR NZ,SinclairLeft
  SET 4,(HL)
SinclairLeft:
  BIT 4,A                 ; 6: left
  JR NZ,SinclairRight
  SET 1,(HL)
SinclairRight:
  BIT 3,A                 ; 7: right
  JR NZ,SinclairUp
  SET 0,(HL)
SinclairUp:
  BIT 1,A                 ; 9: up
  JR NZ,SinclairDown
  SET 3,(HL)
SinclairDown:
  BIT 2,A                 ; 8: down
  JP NZ,InputBitsOut
  SET 2,(HL)
  JP InputBitsOut
ReadKempston:
  IN A,($1F)              ; device 1: Kempston port $1F
  AND $1F
  LD (HL),A
  JP InputBitsOut

; A Cursor joystick reader no device reaches: 5 left, 8 right, 7 up, 6 down, 0
; fire
;
; The same form as the other readers (HL = InputBits): port $F7FE bit 4 (5)
; left; port $EFFE bit 0 (0) fire, bit 2 (8) right, bit 3 (7) up, bit 4 (6)
; down; then JP $B930, but a released 6 returns at once (RET NZ at $B8F8) with
; A = the port byte instead of InputBits. ReadDevice $B894 sends every device
; but 0 and 1 to the Sinclair reader, and no instruction of the image refers to
; $B8D4: a fourth device left out of the menu. Not executed in any recording
; (c1, explorers, gameover, the 31 rzx builds); known only from the code.
;
; Witness: L1 0 ().
ReadCursorKeys:
  LD BC,$F7FE
  IN A,(C)
  BIT 4,A                 ; 5 (port $F7FE bit 4): left
  JR NZ,CursorRow2
  SET 1,(HL)
CursorRow2:
  LD BC,$EFFE             ; port $EFFE: 0 fire
  IN A,(C)
  BIT 0,A
  JR NZ,CursorRight
  SET 4,(HL)
CursorRight:
  BIT 2,A                 ; 8: right
  JR NZ,CursorUp
  SET 0,(HL)
CursorUp:
  BIT 3,A                 ; 7: up
  JR NZ,CursorDown
  SET 3,(HL)
CursorDown:
  BIT 4,A                 ; 6: down; RET NZ when released (A = the port byte)
  RET NZ
  SET 2,(HL)
  JP InputBitsOut

; The keyboard: SPACE fire, Z left, X right, O up, K down
;
; Reached from ReadDevice $B894 when Device $94AF is 0. Witness: explorers, 849
; passes.
;
; Witness: L1 849 (explorers).
ReadKeyboard:
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  JR NZ,KeyZ
  SET 4,(HL)
KeyZ:
  LD BC,$FEFE             ; Z (port $FEFE bit 1): left
  IN A,(C)
  BIT 1,A
  JR NZ,KeyX
  SET 1,(HL)
KeyX:
  BIT 2,A                 ; X (bit 2): right
  JR NZ,KeyO
  SET 0,(HL)
KeyO:
  LD BC,$DFFE             ; O (port $DFFE bit 1): up
  IN A,(C)
  BIT 1,A
  JR NZ,KeyK
  SET 3,(HL)
KeyK:
  LD BC,$BFFE             ; K (port $BFFE bit 2): down
  IN A,(C)
  BIT 2,A
  JR NZ,InputBitsOut
  SET 2,(HL)

; A = InputBits: the end of every reader
;
; Witness: L1 26612 (c1, explorers, gameover, rzx x31).
InputBitsOut:
  LD A,(HL)
  RET
