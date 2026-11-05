; --------------------------------------------------------------------------------------------------------------------
; leveldata.asm: The level data: enemy paths, waves, kinds, the level table and scripts, the scenery
;
; All the level data is one resource, src/res/levels/levels.lev.txt (tools/res_levels.py, every byte decoded and
; proved both ways; the formats in src/res/levels/README.md). The code reads each table at a fixed address.
;
; A level is an 8-byte record of LevelTable: LevelStart $B062 copies the record of LevelOrder[+6] into the player
; record's +$0D (then into ScriptState $81D7 by $AD56): the level script's start, the play flags, the scroll counter
; and the scenery script number.
;
; The level script (WaveScriptStep $AD66, once a frame while the ship lives) is the level's timeline: a step is a wait
; in frames and a command: a wave launch (LaunchWave $91EC), the scroll on or off, a counter (the only one the scripts
; use is ScriptCounter $81E4), a conditional jump, the save of the state at a checkpoint (op 14, $AED2) and the
; level's end (op 5). The scenery script (ScriptMain $8D72, a coroutine) places object groups of shapes into the map
; ring 16 columns at a time.
;
; A wave definition gives the kind of its enemies (EnemyKinds: speed, accelerations, handler, colour set, hit points),
; their path (the path bytecode run by RunPath $94CB) and their start positions; the script's byte after the wave
; number is the wave's row offset.
; --------------------------------------------------------------------------------------------------------------------

; The start of each of the 28 enemy paths: (address - $681C) / 2
;
; LaunchWave $91EC: E = PathStarts[the path number], the path pointer (record
; +$1D/+$1E) = $681C + 2E ($9324-$9331). A wave's enemies take the path of
; their kind unless the wave names one (bit 7 of its kind byte). 48K c2: the
; bytes of paths 7 and 15 read ($6807, $680F).
PathStarts:
  INCBIN "res/levels/levels.bin",$0000,28

; The path bytecode of the enemies, 28 paths
;
; RunPath $94CB (48K c2: 1405 entries): a byte with bit 7 set is the frame
; count of the command after it (0 = for ever); a command's bits 0-2 pick the
; routine from PathOps $8114, bits 3-6 are its parameter (7 = an extended op
; from PathExtOps $8124; extended op 3 is a loop with a word target). Every
; path starts on an even offset (the table holds offset / 2). 48K c2 reads
; $6864-$6866 and $6888-$688B (paths 7 and 15).
PathCode:
  INCBIN "res/levels/levels.bin",$001C,266

; Wave number -> the offset / 2 of its definition from $6943 (29 waves)
;
; LaunchWave $921A: n = WaveIndex[A], the definition at $6943 + 2n. 48K c2:
; waves 7, 15 ($692D, $6935) launched.
WaveIndex:
  INCBIN "res/levels/levels.bin",$0126,29

; The 29 wave definitions
;
; Each: the bonus byte (wave record +1: bits 6-7 the drop, the rest the bonus
; score), the kind (bit 7: a path number and one more byte follow), the enemy
; count, the gap (frames between the enemies, the delay +$1B grows by it), then
; x, y for each enemy (y $FF = random row 0-127). x is halved and added to $C0,
; y to the script's row byte ($9344-$936D). Every definition has an even
; length. 48K c2: $698B-$6996 and $69D9-$69DE (waves 7 and 15).
WaveDefinitions:
  INCBIN "res/levels/levels.bin",$0143,290

; The 22 enemy kinds, 8 bytes each
;
; Copied by LaunchWave ($9261-$92BB) into the wave template $803E: +0 -> +$18,
; +1 the colour select (with WeaponRatingLevel $80E9: the set of KindColours;
; AND $E3 -> +$21), +2 low nibble -> +$0C (score index), high -> +$17 (speed),
; +3 -> +$10 (X acceleration), +4 -> +$14 (Y acceleration), +5 -> +$07 (the
; handler kind of KindHandlers $80FA), +6 -> +$25 (colour), +7 -> +$0D (hit
; points, $FF invulnerable). Kinds $14 and up use sprite cache record 0. 48K
; c2: kinds 7 and 15.
EnemyKinds:
  INCBIN "res/levels/levels.bin",$0265,176

; 8 colour sets of 3 bytes: +$19, +$20, +$22 of the enemy
;
; Index ((WeaponRatingLevel + the kind's colour select) AND $1C) / 4
; ($9271-$9293): a better armed ship meets the other set. 48K c2: $6B15-$6B1A.
KindColours:
  INCBIN "res/levels/levels.bin",$0315,24

; The 12 levels, 8 bytes each
;
; LevelStart $B062 copies LevelTable[LevelOrder[+6]] (HL = $6B25 + 8 (n + 1))
; to the record's +$0D-+$14: +0 a byte (0 in all twelve, ScriptState $81D7,
; never read), +1/+2 the level script, +3 PlayFlags ($FF), +4/+5 ScrollCount
; (the start: $40, $30, $38 or $10), +6 the scenery script number ($81DD), +7
; ScriptLevelBias ($81DE, added to WeaponRating).
LevelTable:
  INCBIN "res/levels/levels.bin",$032D,96

; The level scripts of the 12 levels (the wave timelines)
;
; Run by WaveScriptStep $AD66 (48K c2: 165 entries, the steps $6B8D-$6BA6 of
; level 1). A step: the wait (ScriptWaitCount $81E1 counts the frames up to
; it), the command: below $40 an op of ScriptCommands $81FF (ops 7-12 take one
; or two words); $40-$7F a jump on the condition (ScriptConditions $8223, on
; the flags ScriptFlags $81E2 of the last counter op) to the word; $80-$BF wave
; A AND $3F with the next byte as its row offset; $C0-$FF a conditional call.
; All twelve end with op 5 (the level's end) and a $FF wait.
LevelScripts:
  INCBIN "res/levels/levels.bin",$038D,1820

; 7 colour patterns of 8 attributes for WorkCell $FFD8
;
; ScriptSetCell $8EC5 copies pattern n (a scenery script byte $C0+n) to
; $FFD8-$FFDF; a shape row's odd attribute byte $B1+2k takes WorkCell byte k
; (the scenery's colour scheme). 48K c2: pattern 2 ($72B9-$72C0).
CellPatterns:
  INCBIN "res/levels/levels.bin",$0AA9,56

; The 39 scenery scripts, indexed by ScriptNumber $81DD
;
; RunScript $8D7A (48K c2: reads $72E3 = script 1, then $7321-$7324 = scripts
; 32 and 33 called by it). Levels use scripts 1-4, 6, 8-12 and 14; 15 is unused
; (it names groups 59 and 60, which point at ShapeTable).
SceneryScriptTable:
  INCBIN "res/levels/levels.bin",$0AE1,78

; The scenery script bodies
;
; A byte below $80 places that object group (DrawGroup $8DCA) and yields until
; 16 more columns have scrolled; $80 n calls script n (the variant mask saved);
; $E0+n sets the variant mask ScriptVariant $8021 = n * 16; $C0+n loads colour
; pattern n; $FF ends (the top script restarts).
SceneryScripts:
  INCBIN "res/levels/levels.bin",$0B2F,363

; The 61 object groups, word pointers
;
; DrawGroup $8DCA ($8DD0). 48K c2 reads entries 30-38 ($74D6-$74E7). Entries 59
; and 60 point at ShapeTable ($7783): only scenery script 15 uses them, and no
; level runs it.
GroupTable:
  INCBIN "res/levels/levels.bin",$0C9A,122

; The group bodies: 3-byte objects, $FF the end
;
; An object: byte 0 bits 0-4 the row, bit 5 drawn bottom up, bit 6 mirrored;
; byte 1 the variant bits (high nibble, AND ScriptVariant: none set, skipped)
; and the column (low nibble); byte 2 the shape. A byte $80-$FE is a sub-group
; (byte 1) taken when its bits 0-6 shifted left meet the variant mask (none in
; the data). 48K c2: groups 30-38, $7615-$76DD.
ObjectGroups:
  INCBIN "res/levels/levels.bin",$0D14,623

; The 79 shapes, word pointers
;
; DrawGroup $8E15 (index * 2 added to $7783). Entries 30 and 31 point at the 2
; bytes before shape 32 (no group uses them).
ShapeTable:
  INCBIN "res/levels/levels.bin",$0F83,158

; The shape bodies: the row count, then per row an attribute, a cell mask and
; the tiles
;
; PlaceColumn $8EA1 (48K c2: 209 entries): the attribute byte (odd: WorkCell
; byte (A - $B1) / 2), then a mask whose set bits, from bit 7, are the columns
; that get a tile; one tile byte per set bit, written to the map ring (the
; attribute to the attribute ring).
Shapes:
  INCBIN "res/levels/levels.bin",$1021,1593
