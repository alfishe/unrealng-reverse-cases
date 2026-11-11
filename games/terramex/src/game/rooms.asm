; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The room set-up, the tile sets, the tile map and the room effects
; --------------------------------------------------------------------------------------------------------------------

  ORG $917C

; Party slots 1-4: frame $7F, flags 0
;
; Writes `$007F` to the words `$5B0A`, `$5B0E`, `$5B12`, `$5B16`: bytes +2 (the
; sprite frame) and +3 of the four 4-byte records after the hero's (`$5B04`).
; Frame `$7F` is the blank sprite: `$6000 + $7F * 72` = `$83B8`, 72 zero bytes
; in the image. Called by the room set-up at `$990B` on every room entry (106
; runs over all builds).
;
; Witness: L1 106 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
ClearPartySlots:
  LD HL,$007F
  LD (ObjectSlot1+2),HL
  LD (ObjectSlot2+2),HL
  LD (ObjectSlot3+2),HL
  LD (ObjectSlot4+2),HL
  RET

; The tile set in place: 0 the base set, $FF the alternate set
;
; Toggled only by SwapTileset `$918D`; read by the room set-up `$9880` (which
; swaps the set for the 15 rooms of the list at `$9AC6`), RoomEffects `$91C0`,
; ShowCapsules `$92BD`, EndGame `$906D`, `$A102`, `$A193` and others. Written
; in rzx18000, rzx20000, rzx26000 (twice), rzx34000, rzx50000.
AltTileset:
  DEFB $00

; Exchange the base and the alternate tile set
;
; Swaps the 1024 bytes of `$F400-$F7FF` (the bitmaps of tiles `$80-$FF`) with
; `$FA00-$FDFF`, and the 128 attributes of those tiles `$DF80-$DFFF` with
; `$C580-$C5FF`; then AltTileset `$918C` = NOT its old value. A swap, not a
; copy: the set that goes out is kept for the way back.
;
; Callers: the room set-up at `$9890`/`$9899` (6 runs: rzx18000 frame 1417,
; rzx20000 858, rzx26000 463 and 1075, rzx34000 1481, rzx50000 183), EndGame at
; `$908A`.
;
; Witness: L1 6 (rzx, rzx, rzx, rzx, rzx).
SwapTileset:
  LD A,(AltTileset)
  PUSH AF
  LD HL,AltTilePixels
  LD DE,TilePixels+$0400
  LD BC,$0400
SwapTileBitmaps:
  PUSH BC
  LD C,(HL)
  LD A,(DE)
  LD (HL),A
  LD A,C
  LD (DE),A
  POP BC
  DEC BC
  INC HL
  INC DE
  LD A,C
  OR B
  JR NZ,SwapTileBitmaps
  LD HL,AltTileAttrs      ; the attributes of tiles $80-$FF: $C580 <-> $DF80
  LD B,$80
  LD DE,TileAttrs+$0080
SwapTileAttrs:
  LD C,(HL)
  LD A,(DE)
  LD (HL),A
  LD A,C
  LD (DE),A
  INC DE
  INC HL
  DJNZ SwapTileAttrs
  POP AF
  XOR $FF
  LD (AltTileset),A
  RET

; Animate the flames (base set), the beams and the capsules (alternate set)
;
; Called once a pass by MainLoop `$9018`. The lists are built by the room
; set-up `$9880` with `$9A8C` (a CPIR over the tile map `$F800`): `$9AD5` holds
; the map addresses of tile `$B5` in a base-set room, of tile `$DD` in an
; alternate-set room; `$9AE5` those of tile `$8C` (alternate set only); a 0
; word ends a list.
;
; Base set (AltTileset `$918C` = 0): for the first two entries of `$9AD5` (B =
; 2) the 8-byte frame PassCount AND 3 of FlameFrames `$933D` is copied into
; tile `$B5`'s bitmap (`$F5A8`), the cell is drawn again on the screen and in
; the background copy (`$9A52`), and its attribute (map address + `$6000` =
; `$5800 + offset`) gets BRIGHT flipped at random (bit 0 of R). The rooms with
; tile `$B5` (from the room data): `$1C`, `$21`, `$29`, `$2D`, `$2E`, `$2F`,
; `$33`, `$35`, `$36`, `$3F`, `$40`, `$41`, `$42`. gameover (room `$1C`) and 11
; rzx segments run it (5256 runs of `$91D6`).
;
; Alternate set (Beams `$9208`): `$9AD5` is read as pairs of tile `$DD` cells
; on one row: the two ends of an electric beam. Pixel rows 6 and 7 of each cell
; between them get random bytes (R rotated, XOR PassCount); the beam is redrawn
; every pass (rzx26000-rzx42000, 9538 runs of `$9266`). The hero is hit when
; his X is from the left end's X to below the right end's X minus 12 and |Y + 6
; - the row's Y| < 12, while Status `$5C06` is below 4: Status = `$18` through
; `$AE85` (CreatureDeath `$A89E` in the table at `$A72E`). The hit (`$9260`) is
; not executed in any recording. A list that ends after an odd entry returns
; without the capsules. Rooms with tile `$DD`: `$20`, `$38` (two beams), `$39`,
; `$3A`, `$3C`, `$43`. rzx42000 frame 500 shows the beam of room `$3A` across
; row 13.
;
; Then the capsules (Capsules `$9282`): the 16-byte frame of CapsuleFrames
; `$92FD` (PassCount AND 3, run backwards when bit 2 of PassCount is clear: 3 2
; 1 0 0 1 2 3) is copied into tiles `$8C`-`$8D` (`$F460`), and each cell of
; `$9AE5` gets tile `$8C` and the next cell `$8D` again in the map and the
; background copy (`$9A4D`); ShowCapsules `$92BD` copies them to the screen
; later in the pass. Rooms with tile `$8C`: `$12`, `$20`, `$2B`, `$2C`, `$38`,
; `$3A`, `$3B` (six: the lab, rzx46000 frame 500), `$3C`, `$44`.
;
; Witness: L1 26513 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
RoomEffects:
  LD B,$02
  LD HL,EffectCellsA
  LD A,(AltTileset)
  OR A
  JP NZ,Beams             ; the alternate set: beams and capsules
FlamesLoop:
  PUSH BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  LD A,E
  OR D
  JR Z,FlamesNext
  EXX
  LD A,(PassCount)            ; the frame: PassCount AND 3
  AND $03
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,FlameFrames
  ADD HL,DE
  LD DE,TilePixels+$B5*8     ; into tile $B5's bitmap
  LD BC,$0008
  LDIR
  EXX
  EX DE,HL
  PUSH HL
  LD A,$B5                ; draw tile $B5 there: the screen and the background
                          ; copy
  CALL SetTile
  POP HL
  LD DE,$6000             ; the map address + $6000: the cell's attribute
  ADD HL,DE
  LD A,R                  ; flip BRIGHT at random
  AND $01
  RRCA
  RRCA
  XOR (HL)
  LD (HL),A
FlamesNext:
  POP HL
  POP BC
  DJNZ FlamesLoop
  RET
Beams:
  LD IY,PassCount             ; a beam: the left and the right end cells
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,E
  OR D
  JP Z,Capsules
  LD C,(HL)               ; the right end; 0: the list ended inside a pair
  INC HL
  LD B,(HL)
  INC HL
  LD A,C
  OR B
  RET Z
  PUSH DE
  INC DE
  PUSH BC
  LD A,D                  ; the screen addresses of pixel row 6 of the cells
  AND $03
  RLCA
  RLCA
  RLCA
  OR $06
  OR $40
  LD D,A
  LD A,B
  AND $03
  RLCA
  RLCA
  RLCA
  OR $06
  OR $40
  LD B,A
  EXX
  POP HL
  CALL MapToPixels        ; the ends as pixel coordinates: H = Y, L = X
  LD C,L
  LD B,H
  POP HL
  CALL MapToPixels
  LD A,(Hero)            ; the hero inside the beam's X span?
  CP L
  JR C,BeamDraw
  ADD A,$0C
  CP C
  JR NC,BeamDraw
  LD A,(Hero+1)            ; and within 12 rows of it?
  ADD A,$06
  SUB B
  JR NC,BeamCheckY
  NEG
BeamCheckY:
  CP $0C
  JR NC,BeamDraw
  LD A,(Status)            ; and Status below 4?
  CP $04
  JR NC,BeamDraw
  LD A,$18                ; the hero is hit: Status $18
  CALL SetStatus
BeamDraw:
  EXX
BeamLoop:
  LD A,R                  ; random bytes on pixel rows 6 and 7 of each cell
  RLCA
  XOR (IY+$00)
  LD (DE),A
  INC D
  LD A,R
  RLCA
  XOR (IY+$00)
  LD (DE),A
  DEC D
  INC DE
  PUSH DE
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  POP DE
  JR NZ,BeamLoop
  JR Beams

; Animate the capsules, tiles $8C-$8D (RoomEffects continued)
;
; Reached only by `JP Z,$9282` at `$9212` when Beams `$9208` meets the 0 word
; that ends the list `$9AD5` (an entry of the cut because it is a jump target
; from another routine's L1 block). Described under RoomEffects `$91C0`: the
; frame of CapsuleFrames `$92FD` (3 2 1 0 0 1 2 3 over PassCount) into the
; bitmaps of tiles `$8C`-`$8D` (`$F460`), then tile `$8C` and `$8D` at each map
; address of `$9AE5` and the next, in the map and the background copy
; (`$9A4D`).
;
; Witness: L1 5581 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx).
Capsules:
  LD A,(PassCount)            ; the frame for the capsules: 3 2 1 0 0 1 2 3
  LD C,A
  AND $03
  BIT 2,C
  JR NZ,CapsulesFrame
  XOR $03
CapsulesFrame:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,CapsuleFrames
  ADD HL,DE
  LD DE,TilePixels+$8C*8     ; into tiles $8C-$8D's bitmaps
  LD BC,$0010
  LDIR
  LD DE,EffectCellsB
CapsulesLoop:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  OR L
  RET Z
  PUSH DE
  PUSH HL
  LD A,$8C                ; tile $8C at the cell, $8D at the next: the map and
                          ; the background copy
  CALL SetTileBuffer
  POP HL
  INC HL
  LD A,$8D
  CALL SetTileBuffer
  POP DE
  JR CapsulesLoop

; Copy the capsule cells from the background copy to the screen
;
; Called by `$9B22` at `$9BE4` every pass. Returns at once in a base-set room
; (AltTileset `$918C` = 0). Else, for each map address in the list `$9AE5`,
; copies the cell and the one to its right from the background copy (`$E000`)
; to the screen through CopyBackCell `$92D6` (33546 calls, rzx18000-rzx50000).
;
; Witness: L1 26510 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ShowCapsules:
  LD A,(AltTileset)
  OR A
  RET Z
  LD DE,EffectCellsB
ShowCapsulesLoop:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  OR L
  RET Z
  CALL CopyBackCell
  INC HL
  CALL CopyBackCell
  JR ShowCapsulesLoop

; Copy one cell of the play window from the background copy to the screen
;
; HL = a tile map address (`$F800-$F9FF`). The cell's screen address is (H AND
; 3) * 8 + `$40` : L, its background copy the same OR `$E0`; 8 bytes down the
; cell. HL and DE kept. The SkoolKit note ("menu border strip") does not fit:
; the only caller is ShowCapsules `$92BD`.
;
; Witness: L1 33546 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx).
CopyBackCell:
  PUSH DE
  PUSH HL
  LD A,H
  AND $03
  RLCA
  RLCA
  RLCA
  OR $40
  LD D,A
  OR $E0
  LD H,A
  LD E,L
  LD B,$08
CopyBackCellLoop:
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  DJNZ CopyBackCellLoop
  POP HL
  POP DE
  RET

; A tile map address as pixel coordinates
;
; HL = a tile map address (`$F800` + row * 32 + column). Out: H = row * 8 (the
; Y), L = column * 8 (the X), the units of the hero's X and Y at
; `$5B04`/`$5B05`. Called twice by Beams `$9208` (3646 calls). The SkoolKit
; title ("attribute address") does not fit what it returns.
;
; Witness: L1 3646 (rzx, rzx, rzx, rzx, rzx, rzx).
MapToPixels:
  LD A,H
  AND $03
  LD H,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,H
  ADD A,A
  ADD A,A
  ADD A,A
  LD H,A
  RET

; Four frames of the capsule, tiles $8C-$8D: 16 bytes each, the left tile then
; the right
;
; Copied to `$F460` by Capsules `$9282`. The frames differ only in rows 3-6 of
; the right tile. Read in rzx18000-rzx50000.
CapsuleFrames:
  INCBIN "res/graphics/capsules.bin",$0000,64

; Four 8-byte frames of tile $B5, a flame, PassCount AND 3 picks one
;
; Copied into tile $B5's bitmap ($F5A8) by RoomEffects $91E2 for the first two
; flames of a base-set room (13 rooms hold tile $B5), then the cell is drawn
; again. Read in gameover (room $1C) and 11 rzx segments.
FlameFrames:
  INCBIN "res/graphics/flames.bin",$0000,32

  ORG $9855

; Set up room A: the room-entry specials, the respawn point, then the room
; proper (SK)
;
; A = the new room (level * 12 + column). Called right after every change of
; Room $5C01: InitGame at $8FE5, the respawn $9090 at $90BB, the game-over path
; $9372 at $937C, the room exits $A640/$A671/$A69B/$A6AE (tail jumps at $A669,
; $A691, $A6AB, $A6BF), $A8EA at $A94E and $B5DD at $B6F3.
;
; First CALL $BE42 (the room's creature decode, A kept). Room $2C sets the word
; $5C34 to $FF02: $5C34 is the pair C = dx, B = dy that $A34B moves the hero by
; (each kept in -3..3 there), so the room starts the hero with dx = +2, dy =
; -1; r18000 is the only build that entered room $2C. Then the room is looked
; up in CheckpointRooms $9AF5: when it is listed and FallPasses $5C05 is 0 (the
; hero is not falling), SaveRespawnPoint $9AA1 records this room as the place a
; lost life restarts. Last the per-room set-up SetUpRoomTiles $9880, with IX
; preserved around it.
;
; Evidence: 105 entries over all 31 play builds, SaveRespawnPoint called from
; $9874 71 times (27 builds), so 34 room entries were in rooms not listed or
; while falling.
;
; Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
SetUpRoom:
  PUSH AF
  CALL DecodeRoomCreatures
  CP $2C                  ; room $2C?
  JR NZ,SetUpRoomCheckpoint
  LD HL,$FF02             ; dx = +2 (C), dy = -1 (B): a number pair, not an
                          ; address
  LD (FloatVelocity),HL
SetUpRoomCheckpoint:
  LD HL,CheckpointRooms   ; HL = CheckpointRooms
SetUpRoomScan:
  BIT 7,(HL)              ; the $FF end mark: not a checkpoint room
  JR NZ,SetUpRoomTail
  CP (HL)
  JR Z,SetUpRoomSave
  INC HL
  JR SetUpRoomScan
SetUpRoomSave:
  LD A,(FallPasses)            ; listed: save the respawn point unless the hero is
                          ; falling
  OR A
  CALL Z,SaveRespawnPoint
SetUpRoomTail:
  POP AF                  ; A = the room again
  PUSH IX
  CALL SetUpRoomTiles
  POP IX
  RET

; Per-room set-up: the tile set, the tile map, the effect cells, the room's
; counters, the screen
;
; A = the room. The tile set: when the room is in AltTilesetRooms $9AC6 and the
; alternate set is not loaded (flag $918C = 0), or not in it and the set is
; loaded, $918D swaps the tiles $80-$FF ($F400 with $FA00, their attributes
; $DF80 with $C580). Witness: $918D called 6 times in 5 builds over 105
; set-ups.
;
; Then WellHole $5BA2 = 0, BuildTileMap $9914 expands the room into the tile
; map $F800, the two effect lists $9AD5-$9AF4 are cleared (32 bytes) and filled
; by FindTileCells $9A8C: EffectCellsA $9AD5 with every cell of tile $B5 (the
; base set) or $DD (the alternate set), and with the alternate set EffectCellsB
; $9AE5 with every cell of tile $8C. $91C0 and $9282/$92BD animate those cells
; each pass.
;
; Then BridgeState $5C0C, RoomStage $5C41 and ProfessorState $5BA1 are cleared
; and PadLatch $B072 set to 1; room $10 sets ThinkHints $A6E6[$0F] (the byte
; $A6F5) to 6 (InitGame puts 7 there at $8FB7); room $1C with RopeCount $5C24
; not 0 (the notes RopeTrick $BC73 counted while the Flute, item $0C, was
; played in room $10) writes the tile pair $98, $99 into columns 8-9 of rows
; 0-11 of the tile map. RopeCount is cleared in every room. Last $917C parks
; actor slots 1-4 (frame $7F, the blank sprite), DrawRoom $99A4 draws the whole
; play window and $B93F (tail jump) places the room's floor items.
;
; Evidence: 105-106 runs in 31 builds; the room-$10 branch ran in gameover,
; r10000 and r14500; the room-$1C column ($98F7-$9906) did not run in any of
; the 34 builds (no build entered room $1C with $5C24 set).
;
; Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
SetUpRoomTiles:
  PUSH AF
  LD HL,AltTilesetRooms
  LD B,$0F                ; 15 rooms in the list
SetUpRoomTilesFind:
  CP (HL)
  JR Z,SetUpRoomTilesAlt
  INC HL
  DJNZ SetUpRoomTilesFind
  LD A,(AltTileset)       ; not listed: back to the base set if the alternate
                          ; one is loaded
  OR A
  CALL NZ,SwapTileset
  JR SetUpRoomTilesBuild
SetUpRoomTilesAlt:
  LD A,(AltTileset)       ; listed: load the alternate set if it is not
  OR A
  CALL Z,SwapTileset
SetUpRoomTilesBuild:
  POP AF
  PUSH AF
  LD HL,$0000
  LD (WellHole),HL           ; no well in the room until BuildTileMap finds
                          ; back-tile $10
  CALL BuildTileMap
  LD HL,EffectCellsA
  LD DE,EffectCellsA+$0001
  LD BC,$001F
  LD (HL),$00             ; clear both effect lists, $9AD5-$9AF4
  LDIR
  LD C,$B5                ; the base set animates tile $B5
  LD A,(AltTileset)
  OR A
  JR Z,SetUpRoomTilesCellsA
  LD C,$DD                ; the alternate set: tile $DD
SetUpRoomTilesCellsA:
  LD A,C
  LD DE,EffectCellsA
  CALL FindTileCells
  LD A,(AltTileset)
  OR A
  JR Z,SetUpRoomTilesCounters
  LD DE,EffectCellsB
  LD A,$8C                ; the alternate set's second list: tile $8C
  CALL FindTileCells
SetUpRoomTilesCounters:
  XOR A
  LD (BridgeState),A
  LD (RoomStage),A
  LD (ProfessorState),A
  INC A
  LD (PadLatch),A         ; PadLatch = 1
  POP AF
  CP $10
  JR NZ,SetUpRoomTilesRoom1C
  PUSH AF
  LD A,$06                ; room $10: ThinkHints[$0F] becomes 6, the Bellows
  LD (ThinkHints+$000F),A
  POP AF
SetUpRoomTilesRoom1C:
  CP $1C
  JR NZ,SetUpRoomTilesDone
  LD A,(RopeCount)
  OR A
  JR Z,SetUpRoomTilesDone
  LD B,$0C                ; 12 rows, from row 0, column 8 of the tile map
  LD HL,TileMap+$0008
SetUpRoomTilesColumn:
  LD (HL),$98             ; tile $98 left, $99 right
  INC HL
  LD (HL),$99
  LD DE,$001F             ; next row: 31 + the INC HL = 32
  ADD HL,DE
  DJNZ SetUpRoomTilesColumn
SetUpRoomTilesDone:
  XOR A
  LD (RopeCount),A
  CALL ClearPartySlots    ; actor slots 1-4 parked on the blank frame $7F
  CALL DrawRoom           ; draw the whole play window
  JP SpawnRoomItems       ; the room's floor items

; Expand room A's 8 x 4 back-tiles into the 32 x 16 tile map $F800 (SK)
;
; A = the room. The room's 32 back-tile indices sit at $D600 + 32 * room, 4
; rows of 8; each back-tile is 16 tile indices at $C600 + 16 * index, 4 rows of
; 4, written to the tile map at $F800 + 128 * row + 4 * column (IX), the 16
; stores unrolled. Back-tile $10 (the well) is also recorded by WellRecord
; $99F0 before it is copied. Out: the tile map; IX, HL, DE, BC changed.
;
; Called only by SetUpRoomTiles at $98A4. Room $0C is the only room using
; back-tile $10 (index 26: row 3, column 2), drawn in docs/img/maps/rooms.png
; as the well; WellRecord ran 3 times, in r06000 and r12000.
;
; Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
BuildTileMap:
  LD L,A
  LD H,$00
  ADD HL,HL               ; room * 32
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,RoomGrids
  ADD HL,DE
  LD B,$04
  LD IX,TileMap           ; IX = the tile map, row 0
BuildTileMapRow:
  PUSH BC                 ; 4 back-tile rows
  PUSH IX
  LD B,$08
BuildTileMapCell:
  PUSH BC                 ; 8 back-tiles a row
  LD A,(HL)
  LD C,A
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL               ; back-tile * 16
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,BackTiles
  ADD HL,DE
  LD A,C
  CP $10
  CALL Z,WellRecord       ; back-tile $10: note the well
  LD A,(HL)
  LD (IX+$00),A           ; cell row 0 of the back-tile; +$20, +$40, +$60 below
                          ; are rows 1-3
  INC HL
  LD A,(HL)
  LD (IX+$01),A
  INC HL
  LD A,(HL)
  LD (IX+$02),A
  INC HL
  LD A,(HL)
  LD (IX+$03),A
  INC HL
  LD A,(HL)
  LD (IX+$20),A
  INC HL
  LD A,(HL)
  LD (IX+$21),A
  INC HL
  LD A,(HL)
  LD (IX+$22),A
  INC HL
  LD A,(HL)
  LD (IX+$23),A
  INC HL
  LD A,(HL)
  LD (IX+$40),A
  INC HL
  LD A,(HL)
  LD (IX+$41),A
  INC HL
  LD A,(HL)
  LD (IX+$42),A
  INC HL
  LD A,(HL)
  LD (IX+$43),A
  INC HL
  LD A,(HL)
  LD (IX+$60),A
  INC HL
  LD A,(HL)
  LD (IX+$61),A
  INC HL
  LD A,(HL)
  LD (IX+$62),A
  INC HL
  LD A,(HL)
  LD (IX+$63),A
  POP HL
  INC HL
  LD BC,$0004             ; IX: the next back-tile, 4 cells right
  ADD IX,BC
  POP BC
  DJNZ BuildTileMapCell
  POP IX
  LD BC,$0080             ; IX: the next back-tile row, 4 cell rows down
  ADD IX,BC
  POP BC
  DJNZ BuildTileMapRow
  RET

; Draw the whole play window from the tile map: attributes, screen and back
; buffer (SK)
;
; For each of the 512 cells n of the tile map $F800 (32 x 16): the attribute
; $5800 + n = $DF00[tile], and the tile's 8 bytes at (TilePixelsPtr $5B72,
; $F000) + 8 * tile go to the screen cell (the top two thirds, $4000-$4FFF) and
; to the same cell of the back buffer ($E000-$EFFF, the screen address OR
; $A000), so the buffer starts each room as a clean copy of the background.
;
; Called only by SetUpRoomTiles at $990E (106 runs, 31 builds). Stops when n
; reaches 512 (BIT 1,H).
;
; Witness: L1 106 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
DrawRoom:
  LD HL,$0000
  LD DE,TileMap
DrawRoomCell:
  PUSH HL
  PUSH DE
  LD A,H
  OR $58                  ; HL = $5800 + n, the cell's attribute
  LD H,A
  LD A,(DE)
  PUSH AF
  PUSH HL
  LD L,A
  LD H,$00
  LD BC,TileAttrs         ; the tile attributes $DF00
  ADD HL,BC
  LD A,(HL)
  POP HL
  LD (HL),A
  LD A,H                  ; H = $40 or $48: the cell's screen third
  AND $03
  RLCA
  RLCA
  RLCA
  OR $40
  LD H,A
  POP AF
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,(TilePixelsPtr)           ; the tile's bitmap
  ADD HL,DE
  POP DE
  LD C,E
  LD A,D
  OR $E0                  ; BC = the same cell in the back buffer
  LD B,A
  EX AF,AF'
  LD A,$08
DrawRoomRow:
  EX AF,AF'               ; 8 pixel rows to the screen and the buffer
  LD A,(HL)
  LD (DE),A
  LD (BC),A
  INC D
  INC B
  INC HL
  EX AF,AF'
  DEC A
  JR NZ,DrawRoomRow
  POP DE
  INC DE
  POP HL
  INC HL
  BIT 1,H                 ; 512 cells done?
  JR Z,DrawRoomCell
  RET

; Note the well (back-tile $10): the cell under its top row and its middle tile
; rows
;
; Called by BuildTileMap at $993D when the back-tile is $10. IX = the
; back-tile's first cell in the tile map, HL = its 16 tile indices. WellHole
; $5BA2 = IX + $6020: the same cell one row down, written in the attribute-file
; form ($5800 + offset: only bits 0-1 of the high byte and the low byte are
; used by DrawTileAt $9A64); WellTiles $5BA4 = HL + 4: the back-tile's rows 1
; and 2 (tiles $34-$37 and $3F-$42, the well's front wall). DrawWellFront $9A2F
; redraws exactly those 2 x 4 cells. All registers kept.
;
; Witness: 3 runs (r06000, r12000), the room-$0C set-ups.
;
; Witness: L1 3 (rzx, rzx).
WellRecord:
  PUSH HL
  PUSH IX
  PUSH DE
  LD DE,$6020
  ADD IX,DE
  LD (WellHole),IX
  LD DE,$0004
  ADD HL,DE
  LD (WellTiles),HL
  POP DE
  POP IX
  POP HL
  RET

; Draw the well's front wall over the hero while he climbs into or out of the
; well
;
; Called by RenderPass $9B22 at $9BB7 right after the hero (actor slot 0) is
; drawn into the back buffer, once a pass (26 517 calls over the 34 builds).
; $AF22 returns carry when the room has no well (WellHole $5BA2 = 0) or the
; hero's X ($5B04) is not within the 8 pixels of the well's column; otherwise,
; when Status $5C06 is 2 with StatusTimer $5C07 >= 8, or Status is 3 with
; StatusTimer < 8, DrawWellFront $9A2F paints the wall's 2 x 4 cells over the
; hero in the buffer, so the hero is hidden behind the well's rim. Status 3 is
; set at $A508 when the hero climbs up out of room $18 into room $0C (the room
; above it, Y = $60); Status 2 at $AD2D ($AD17, the climb). BC, HL, DE kept.
;
; Evidence: the wall was drawn 11 times (r06500, r12000); Status 2 reached
; $9A1F in r06500, Status 3 in r12000. What the screen shows is not yet checked
; (run request R1).
;
; Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
WellFront:
  CALL OverHole
  RET C
  LD A,(Status)
  CP $02
  JR Z,WellFrontEvent2
  CP $03
  RET NZ
  LD A,(StatusTimer)            ; Status 3: only for the first 8 counts
  CP $08
  RET NC
  JR WellFrontDraw
WellFrontEvent2:
  LD A,(StatusTimer)            ; Status 2: from the 8th count on
  CP $08
  RET C
WellFrontDraw:
  PUSH BC
  PUSH HL
  PUSH DE
  CALL DrawWellFront
  POP DE
  POP HL
  POP BC
  RET

; Redraw the well's front wall: 2 rows of 4 cells into the back buffer
;
; HL = WellHole $5BA2 (returns at once when 0), DE = WellTiles $5BA4. Two rows
; of four cells through DrawTileBuffer $9A62, the second row 32 cells on.
; Called only by WellFront at $9A28 (11 runs, r06500 and r12000).
;
; Witness: L1 11 (rzx, rzx).
DrawWellFront:
  LD HL,(WellHole)
  LD A,H
  OR L
  RET Z
  LD DE,(WellTiles)
  LD B,$02
DrawWellFrontRow:
  PUSH BC
  PUSH HL
  LD B,$04
DrawWellFrontCell:
  CALL DrawTileBuffer
  DJNZ DrawWellFrontCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ DrawWellFrontRow
  RET

; Write tile A into tile-map cell HL and draw it into the back buffer only
;
; HL = a cell of the tile map ($F800-$F9FF), A = the tile. (HL) = A, DE = HL,
; then DrawTileBuffer $9A62 (a tail jump at $9A50). Out: L + 1, DE + 1.
; Callers: the alternate set's effect $9282 at $92B0 and $92B7, and $B7A8 at
; $B7D4 (25 904 and 5312 calls).
;
; Witness: L1 38860 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx).
SetTileBuffer:
  PUSH HL
  POP DE
  LD (HL),A
  JR DrawTileBuffer

; Write tile A into tile-map cell HL and draw it on the screen and in the back
; buffer
;
; HL = a cell of the tile map, A = the tile. (HL) = A; DrawTileAt $9A64 with C
; = $40 draws the cell on the screen, the cell is stepped back and the routine
; runs on into DrawTileBuffer $9A62 for the buffer. Out: HL = the cell + 1 in
; the attribute-file form ($58xx), DE = HL; callers push what they keep.
; Callers: the base set's effect $91C0 at $91F3 (5256 calls, tile $B5), $BA97
; at $BB19, and the room-$1C column $BC73 (tiles $98, $99; not reached in any
; build).
;
; Witness: L1 5349 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
SetTile:
  PUSH HL
  POP DE
  LD (HL),A
  PUSH BC
  LD BC,$6000             ; $F8xx + $6000 = $58xx: bits 0-1 of the high byte
                          ; (the third) are what counts
  ADD HL,BC
  POP BC
  LD C,$40                ; the screen page
  CALL DrawTileAt
  DEC L                   ; back to the same cell for the buffer
  DEC DE

; Draw the tile of cell (DE) at cell HL of the back buffer
;
; C = $E0 (the back buffer's page), then DrawTileAt $9A64. Entered by
; SetTileBuffer, by SetTile (running on) and called by DrawWellFront at $9A3F.
;
; Witness: L1 44297 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawTileBuffer:
  LD C,$E0

; Draw tile (DE) into the cell HL of the screen page C ($40) or the back buffer
; ($E0)
;
; HL = a cell address of which only L (the cell in the third) and bits 0-1 of H
; (the third) are used, so tile-map ($F8xx) and attribute ($58xx) forms both
; work; DE points to the tile index; C = the page. The tile's 8 bytes at
; (TilePixelsPtr $5B72) + 8 * tile go to the 8 pixel rows of the cell. Out: L +
; 1 (the next cell), DE + 1; BC kept.
;
; Witness: L1 49646 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DrawTileAt:
  PUSH HL
  PUSH BC
  PUSH DE
  LD A,H
  AND $03
  RLCA
  RLCA
  RLCA
  OR C                    ; H = page + third * 8
  LD H,A
  PUSH HL
  LD A,(DE)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,(TilePixelsPtr)
  ADD HL,DE
  EX DE,HL
  POP HL
  LD B,$08
DrawTileAtRow:
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  DJNZ DrawTileAtRow
  POP DE
  INC DE
  POP BC
  POP HL
  INC L
  RET

; List the tile-map cells holding tile A, as words from DE on
;
; A = the tile, DE = the list. CPIR over $F800-$F9FE (BC = $1FF: the last cell,
; $F9FF, is never searched); each match is stored as its tile-map address (low
; byte first). The list's end is the zero word left by the clearing in
; SetUpRoomTiles. Out: DE past the last word.
;
; Called by SetUpRoomTiles at $98C2 (tile $B5 or $DD into EffectCellsA $9AD5)
; and $98D0 (tile $8C into EffectCellsB $9AE5): 124 calls, a match in 17 builds
; (70 words stored). Each list has room for 8 words; the most any room holds is
; 4 tiles $DD (room $38) and 6 tiles $8C (room $3B), counted from the room
; data, so neither list overflows.
;
; Witness: L1 124 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
FindTileCells:
  LD BC,$01FF
  LD HL,TileMap
FindTileCellsNext:
  CPIR                    ; RET PO: the whole map searched
  RET PO
  PUSH AF
  DEC HL
  LD A,L
  LD (DE),A
  INC DE
  LD A,H
  LD (DE),A
  INC DE
  INC HL
  POP AF
  JR FindTileCellsNext

; Record the room, the event state and the hero as the place a lost life
; restarts (SK)
;
; Copies Room $5C01 to $5C2D, Status $5C06 to $5C2B, StatusTimer $5C07 to
; $5C2C, the hero's X and Y ($5B04) to $5C2E, his frame and flags ($5B06) to
; $5C30 and the word $5B9E to $5C32. The respawn $9090 copies them all back and
; calls SetUpRoom.
;
; Callers: InitGame at $9012 (the start room) and SetUpRoom at $9874 (a room
; listed in CheckpointRooms entered while FallPasses $5C05 = 0). 78 runs in 27
; builds. A life lost in an unlisted room restarts in the last listed room
; entered.
;
; Witness: L1 78 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx).
SaveRespawnPoint:
  LD A,(Room)
  LD (RespawnRoom),A
  LD A,(Status)
  LD (RespawnStatus),A
  LD A,(StatusTimer)
  LD (RespawnTimer),A
  LD HL,(Hero)
  LD (RespawnXY),HL
  LD HL,(Hero+2)
  LD (RespawnFrame),HL
  LD HL,(LiftRoom)
  LD (RespawnLift),HL
  RET

; The 15 rooms drawn with the alternate tiles $80-$FF (SK)
;
; SetUpRoomTiles $9880 scans all 15 (B = 15) on every room set-up; a listed
; room has the tiles from $FA00 (attributes $C580) in place of $F400 ($DF80).
; Read in every play build (1495 reads). doc 06, 6.3 draws room $14 (a base-set
; room) from the data and it equals the screen.
AltTilesetRooms:
  INCBIN "res/rooms/alt-rooms.bin",$0000,15

; The tile-map addresses of the room's tiles $B5 (base set) or $DD (alternate
; set), zero-ended
;
; Built on every room set-up by FindTileCells $9A8C (from $98C2) after
; SetUpRoomTiles clears $9AD5-$9AF4. Read each pass by the effect routine
; $91C0: with the base set the first two cells show a tile $B5 animated in 4
; frames by PassCount $5C02 with random pixel noise; with the alternate set the
; words go in pairs, two $DD cells on one row that $91C0 joins with a noise
; beam, and the hero inside it gets event $18 ($9255). 103 894 reads over the
; play builds; zeros in the image.
EffectCellsA:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

; The tile-map addresses of the room's tiles $8C (alternate set only),
; zero-ended
;
; Built by FindTileCells from $98D0 when the alternate set is in; read each
; pass by $9282 through $92BD (91 023 reads). Room $3B has the most, 6.
EffectCellsB:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

; The 44 rooms where SaveRespawnPoint records the restart point, then $FF
;
; SetUpRoom $9855 scans from $9AF5 to the first byte with bit 7 set. Listed:
; $00 $01 $04 $07-$09 $0C-$0E $12-$15 $17-$1B $1F $21-$23 $26-$2A $2C $30-$36
; $38-$3B $3D $3E $40 $44 $45. Not listed: $02 $03 $05 $06 $0A $0B $0F-$11 $16
; $1C-$1E $20 $24 $25 $2B $2D-$2F $37 $3C $3F $41-$43. Read in every play build
; (6179 reads).
CheckpointRooms:
  INCBIN "res/tables/checkpoint-rooms.bin",$0000,45

  ORG $C600

; The 256 back-tiles: 4 x 4 tile indices each
;
; A room is 8 x 4 back-tiles (RoomGrids $D600), each 4 x 4 tiles of 8 x 8
; pixels: the 32 x 16 tile map TileMap $F800. 242 of the 256 back-tiles appear
; in the 72 grids; the highest index used is $F4.
;
; Witness: the play builds read the back-tiles of the rooms they enter
; (bytemap.py).
BackTiles:
  INCBIN "res/rooms/backtiles.bin",$0000,4096

; The back-tile grids of the 72 rooms: 32 bytes a room, 4 rows of 8
;
; Room R (level x 12 + column) at $D600 + 32 x R. Rooms $46 and $47, past the
; 70 of the map, exist in both tables and are portal targets; their records in
; RoomCreatures $C152 are zeros.
;
; Witness: each room the recordings enter has its 32 bytes read (bytemap.py; 57
; rooms in the RZX run).
RoomGrids:
  INCBIN "res/rooms/grids.bin",$0000,2304

  ORG $F800

; The room's tile map, 32 x 16 tile indices, rebuilt on each room entry; on the
; tape a leftover
;
; The builder ($9914) writes it from the room's grid and the back-tiles before
; anything reads it. The 512 bytes on the tape are the map of a room as it was
; when the tape was saved.
TileMap:
  INCBIN "res/leftovers/tile-map-tape.bin",$0000,512
