; --------------------------------------------------------------------------------------------------------------------
; tables.asm: Tables: room build, title scene, gates, actor scripts
; --------------------------------------------------------------------------------------------------------------------

  ORG $7300

; The low bytes in page $73 of the 16 room patterns, indexed by a room record's
; low nibble
;
; The room builder at $9F63 takes the low nibble of a room-stream byte, reads H
; = $73, L = RoomPatternStarts[n] ($9F7D-$9F80) and walks the pattern from
; $73xx (RoomPatterns). Values $10-$41: the patterns lie at $7310-$7344.
;
; Witness: $7300-$7306 read by $9F63 in deaths and rooms (L1 byte profiles).
RoomPatternStarts:
  INCBIN "res/rooms/outline-starts.bin",$0000,16

; Room patterns read by $9F63: a byte a cell step, bit 7 two tiles, bit 6 back
; to the row start, bits 0-5 the step
;
; Read through DE = $73xx by the loop $9F96: bit 7 set puts two tiles ($A408
; twice), bits 0-5 are added to the tile-map offset, bit 6 restarts the column
; from $6BDE. Patterns 0-8 here ($7310-$7329); the rest go on at
; RoomPatternsMore past the two variables.
;
; Witness: $7300-$731D, $7322-$7329 read by $9F63 (deaths, rooms).
RoomPatterns:
  INCBIN "res/rooms/outlines-1.bin",$0000,26

; Two words of drawing state: the column position (a word) and the row position
; (a word)
;
; $8F75 writes BC from $8FDD (the actor's X, +$22 applied) to $732A and BC from
; $9000 (Y - +$21) to $732C; the cell writer CellScreenAddress $8803 writes the
; cell column x 4 to $732A. Readers: SpriteScreenAddress $8828,
; ComposeActorCells $8907, $8A90, $8C68, $8CE5, $9A27, $8F3B (bit 0 of $732C
; picks the composer buffer $5D4A / $5D42).
;
; Witness: read and written in every recording (c1, deaths, menu ...).
DrawColumnPos:
  DEFB $00
  DEFB $00
DrawRowPos:
  DEFB $00                ; the row position (a word), from $9000
  DEFB $00

; Room patterns 9-15 read by $9F63 (continued from RoomPatterns)
;
; Witness: $732E, $7333-$7344 read by $9F63 (rooms).
RoomPatternsMore:
  INCBIN "res/rooms/outlines-2.bin",$0000,23

; Tile shapes for $A02E: (tile, step) pairs, a step with bit 7 set ends the
; shape
;
; PlotPattern $A02E: DE = $73xx (E from the room stream, $A01F), (DE) is a tile
; code stored at (HL), the next byte is added to L; a step of $80 or more ends.
; The room code handlers 0-3 ($A016) place them.
;
; Witness: $7345-$7394 read by $A02E in c1, menu, gameover, deaths, rooms.
RoomShapes:
  INCBIN "res/rooms/strings.bin",$0000,120

; Four tile codes read through IX by $A357 when the room byte's high nibble is
; 2
;
; $A357: IX = $73BD when (BC-1) AND $F0 = $20, else ShapeTilesB $73C1. Witness:
; $73BD-$73C0 read by $A357 (rooms).
ShapeTilesA:
  INCBIN "res/rooms/decor-tiles.bin",$0000,4
ShapeTilesB:
  INCBIN "res/rooms/decor-tiles.bin",$0004,4

; Two tile codes ($55, $54) searched with CPIR by $9CB1
;
; $9CB1: the tile under the actor at $6A00 + B is looked up in these two bytes.
; Witness: read by $9CA1 / $9CA7 / $9CB1 in c1, menu, opt2-4, rooms.
SpecialTiles:
  INCBIN "res/rooms/ladder-tiles.bin",$0000,2

; The room-stream code handlers, 15 addresses ($9FFF: index = the code x 2)
;
; $9FEF / $9FFF: HL = $73C7, A = the code ($0D or less), RLCA, $A00F adds and
; jumps (JP (HL)). Codes 0-3 $A016 (shapes), 4 $A039 (the room's strip), 5
; $A0B9, 6 $A0C4, 7 $A0D2, 8 $A0D6, 9 $A0C9, 10 $A0BE, 11 $A006, 12 $A0E2, 13
; $A1F1, 14 $A357.
;
; Witness: $73CD-$73E6 read by $9FEF / $A00F (c1, gameover, menu, opt2-4,
; deaths, rooms).
RoomCodeHandlers:
  DEFW ObjectPattern
  DEFW ObjectPattern
  DEFW ObjectPattern
  DEFW ObjectPattern
  DEFW BuildSurface
  DEFW ObjectRunH75AD
  DEFW ObjectRunV7400
  DEFW RoomOpStrip69
  DEFW RoomOpStrip6A
  DEFW RoomOpStripDown
  DEFW ObjectRunH7511
  DEFW ObjectTypeB
  DEFW RoomOpStrip68
  DEFW RoomOpFillBack
  DEFW RoomOpLedge

; Ten handler addresses read from DE = $73E5 by $9A99
;
; $72DE, $921C, $9238, $91EE, $91E1, $91F4, $920A, $9215, $91A9, $91D4.
; Witness: $73E7-$73F8 read by $9A99 (every play recording).
ActorKindHandlers:
  DEFW RoomPatch
  DEFW JumpStep
  DEFW FallScriptStep
  DEFW PoseStep
  DEFW TurnStep
  DEFW ActionStep
  DEFW FallDamageStep
  DEFW HangStep
  DEFW DeathStep
  DEFW RiseStep

; Seven zero bytes, read by no recording
Spare73F9:
  INCBIN "res/leftovers/spare-73f9.bin",$0000,7

; Six-byte structure records: +0 the first tile (bit 7 a flag), +1-+5 the next
; tiles
;
; $A0EE: IX = base + 6 x (the high nibble of the room byte) ($8EDD multiplies),
; the bases $7400 ($A0C4), $7436 ($A0C9), $7496 ($A0E2), StructureSetD $7511
; ($A0BE), $7571 ($A0D8), $75AD ($A0B9). $A101 / $A109 / $A416 put (IX+0) AND
; $7F, (IX+2), (IX+3) ... into the tile map.
;
; The record at $74BA (set C, record 6) is two variables: ComposeDest.
;
; Witness: $7436-$74AC read by $A0CD / $A109 / $A416 (deaths, rooms);
; $7400-$7435 read by no recording (handler 6 $A0C4 did not run).
StructureRecords:
  INCBIN "res/rooms/bars-1.bin",$0000,54
StructureSetB:
  INCBIN "res/rooms/bars-1.bin",$0036,96
StructureSetC:
  INCBIN "res/rooms/bars-1.bin",$0096,36
ComposeDest:
  INCBIN "res/rooms/bars-1.bin",$00BA,60

; A strip of tiles: room code 4 ($A039) copies 20 bytes from $74F5 + the room
; number into the map row
;
; $A065: HL = $74F5 + ($6BDD), LDIR 20 bytes into the tile map (DE from $6800 +
; 80), the strip of tiles $36-$43 under the room; the window overlaps the next
; table for rooms above 7. Witness: $74F6-$7511 read by $A039 (c1, gameover,
; menu, opt2-4, deaths, rooms).
RoomStrip:
  INCBIN "res/rooms/horizon.bin",$0000,27

; Six-byte structure records, sets D, E and F (see StructureRecords)
;
; Witness: $7511-$7558, $7577-$75C4 read by $A0CD / $A109 / $A416 (deaths,
; rooms).
StructureSetD:
  INCBIN "res/rooms/bars-2.bin",$0000,96
StructureSetE:
  INCBIN "res/rooms/bars-2.bin",$0060,60
StructureSetF:
  INCBIN "res/rooms/bars-2.bin",$009C,66

; Six handler addresses picked by $A006 (room code 11): (byte >> 3) AND $1E
;
; $A164, $A1E2, $A179, $A197, $A1C5, $A1E6. Witness: $75F3-$75FA read by $A00F
; (deaths, rooms).
RoomCodeHandlersB:
  DEFW SubOpRun77
  DEFW SubOpMarkCell
  DEFW SubOpPillar
  DEFW SubOpColumn31
  DEFW SubOpColumnTop30
  DEFW SubOpClearMark

; Five bytes: an empty list $A41E points $6AE1 at ($10, 0, $DB, 0, 0)
;
; $A427-$A42A store $75FB into $6AE1 when the room stream byte is 0. Witness:
; $75FB-$75FD read by $A4D1 (every play recording).
EmptyObjectList:
  INCBIN "res/rooms/default-zone.bin",$0000,5

; The title's attract scene: 26 actor records of 7 bytes (X, Y, kind, three
; bytes to +$3F, one to +$0A)
;
; $A73E reads 15 records from $7600 and later 11 from $7669 ($A7D3) through
; $A7DD: C, B and A ($65ED) for $A65D, then 3 bytes to the actor's +$3F-+$41
; and one to +$0A. Witness: $7600-$76D1 read by $A73E (c48, gameover, menu).
TitleActors:
  INCBIN "res/tables/title-actors.bin",$0000,182

; 26 actor pages ($5D-$6B): the order the title scene steps its actors in
;
; $A775: H = (TitleSceneIndex), the page of the next actor. Witness: read by
; $A73E.
TitleActorOrder:
  INCBIN "res/tables/title-order.bin",$0000,26

; The title scene's index into TitleActorOrder ($B6 at the start) and its step
; count
;
; $A73E sets $B6, 0; $A788 increments both when an actor's counter ends (effect
; 11). $A7C3: step $1A, $1B and $0F end or switch the scene.
TitleSceneIndex:
  DEFB $B6
TitleSceneStep:
  DEFB $00                ; steps done

; Six rooms that hold a gate (the room numbers searched with CPIR by $8F28)
;
; BarrierFind $8F28: CPIR over these six for the room $6BDD, HL = the match + 6
; (GateClosed). $8F01 then compares Hiro's X $5D01 with GateX and the side bit
; with $5D1B: D = 0 (no move) at the gate. $8F22 clears GateClosed: called at
; $97E5 when the guardian (an actor of kind $2A) is killed, effect 3.
;
; Rooms $7B (Havok's room), $5D, $3A, $08, $27, $88. Witness: $76D2-$76D7 read
; by $8F28 in every play recording; $76DB, $76E1, $76E7 read by $8F01 (deaths).
GateRooms:
  INCBIN "res/tables/gates.bin",$0000,6
GateClosed:
  INCBIN "res/tables/gates.bin",$0006,6
GateX:
  INCBIN "res/tables/gates.bin",$000C,6
GateSide:
  INCBIN "res/tables/gates.bin",$0012,6

; Actor scripts (animation and moves), read through the actor's script pointer
; (+$3A/+$3B)
;
; Read by $917E, $919C, $919F, $9191, $A6B1 (the frame, the next pointer),
; $9253 and $93FB (move steps), $9BB6. The scripts' format is the enemies /
; player regions' (their readers). Starts named here are the ones a LD BC,nn
; loads.
;
; Witness: $76F3-$79CA read by $917E / $9191 / $919F / $A6B1 / $9BB6 / $93FB
; (c1, deaths, gameover, rooms).
ActorScripts:
  INCBIN "res/tables/scripts-76.bin",$0000,789

; A message to show: 1 or 2 from the bonus code $99B4 / $99D2, the main loop
; calls $66B6 while set
;
; $66B6 (code in the globals page) shows message ($79FF) through $66C8 and
; clears it. Witness: read by $8DFE / $8E06 in every play recording.
MessageRequest:
  DEFB $00

; The eight 3-bit codes bit-reversed: 0 4 2 6 1 5 3 7 (a mirrored room)
;
; $8C51: D = $7A, E = a code from the unpacked room, (DE) replaces it
; ($8C60-$8C62). Witness: $7A00-$7A07 read by $8C51 (c1, deaths, gameover,
; opt2-4, rooms).
ReverseCodes:
  INCBIN "res/tables/reverse-codes.bin",$0000,8

; Actor scripts (continued), Hiro's among them
;
; Witness: $7A08-$7B7F read by $917E / $919C / $919F / $9191 / $9253 / $93FB /
; $9BB6 / $A6B1.
ActorScriptsMore:
  INCBIN "res/tables/scripts-7a.bin",$0000,62
StrikeScript1:
  INCBIN "res/tables/scripts-7a.bin",$003E,11
WalkScript:
  INCBIN "res/tables/scripts-7a.bin",$0049,41
RunScript:
  INCBIN "res/tables/scripts-7a.bin",$0072,53
LadderGrabScript:
  INCBIN "res/tables/scripts-7a.bin",$00A7,7
LandScript:
  INCBIN "res/tables/scripts-7a.bin",$00AE,6
HardLandScript:
  INCBIN "res/tables/scripts-7a.bin",$00B4,18
StrikeScript2:
  INCBIN "res/tables/scripts-7a.bin",$00C6,13
StrikeScript3:
  INCBIN "res/tables/scripts-7a.bin",$00D3,13
LadderLeaveScript:
  INCBIN "res/tables/scripts-7a.bin",$00E0,7
Script92F5:
  INCBIN "res/tables/scripts-7a.bin",$00E7,12
Script9C0E:
  INCBIN "res/tables/scripts-7a.bin",$00F3,5
StandScript:
  INCBIN "res/tables/scripts-7a.bin",$00F8,93
Script911A:
  INCBIN "res/tables/scripts-7a.bin",$0155,6
MessageNumber:
  INCBIN "res/tables/scripts-7a.bin",$015B,29

; Three (script word, value) triples read downward with LDDR by $965F from
; $7B88
;
; $9669: HL = $7B88, three LDDR of 3 bytes into $6584-$6586: script $7B89 and
; the values $8E, $9B, $A8 (three actors spawned by $965F). Witness: not read
; in the keyed recordings.
SpawnTriples:
  INCBIN "res/tables/scripts-7a.bin",$0178,9

; The script the three spawned actors run (from $7B89), and the scripts that
; follow
SpawnedScript:
  INCBIN "res/tables/scripts-7a.bin",$0181,44
Script9115:
  INCBIN "res/tables/scripts-7a.bin",$01AD,35

; Six (tile code, map page) pairs: $A4B8 writes the tile into page $69 / $6A at
; the object's cell
;
; $A4B8: HL = $7BD8 + ((A AND $E0) >> 4), A = the tile, D = the page, (DE) = A.
; Witness: $7BD8-$7BE1 read by $A41E (c1, deaths, gameover, menu, opt2-4,
; rooms).
ObjectTilePlaces:
  INCBIN "res/rooms/pickup-tiles.bin",$0000,13

  ORG $FD98

; The packer's entries and stops with the screen edge masks: 31 records of 3
; bytes
;
; Read by PackRow `$8CE5`. Record p (0-7, p = the window's left unit AND 7):
; the entry PackUnitsN (word) where a line starts at unit p of a 3-byte group,
; and the left mask (the screen bits left of the window kept). Record p + w + 7
; (w = the window width in units): the address of the `INC H` after the
; window's last unit, where PackRow plants a `RET`, and the right mask. The
; words are code addresses: `$8D45`, `$8D4A`, `$8D50`, `$8D5C`, `$8D64`,
; `$8D69`, `$8D79`, `$8D80`, then the stops `$8D49` ... `$8DFD`.
PackerPhases:
  INCBIN "res/tables/packer-phases.bin",$0000,93

; The byte of a 3-byte group that holds unit n (0-7): 0 0 0 1 1 1 2 2
;
; Read by SpriteScreenAddress `$8828` (`$FDF5` + (X AND 7)): the screen column
; of a window's left unit = 3 x (X / 8) + this.
UnitByteOffsets:
  INCBIN "res/tables/unit-offsets.bin",$0000,8

; Zeros in the image: the bootstrap's SetVectors $401F writes JP $8456 at $FDFD
; and the IM 2 table $FE00-$FF00 (all $FD)
;
; Read by no code as loaded: the 260 bytes `$FDFD-$FF00` are written before the
; first interrupt (boot.ann: Im2Jump, Im2Table).
Im2Space:
  DEFS $0104
