; --------------------------------------------------------------------------------------------------------------------
; sections.asm: The section table, the exit lists and the map entry lists
; --------------------------------------------------------------------------------------------------------------------

; 14 entries of 8 bytes: 10 sections and 4 filler entries
;
; LevelHeader+2 points here; SetupSection $8A6D reads entry A at SectionTable +
; 8A. +0/+1 the map's offset from Maps (big-endian); +2 0, read by no code; +3
; the scroll limit, the last ViewTop (cells, a multiple of 8) the scroll down
; may reach ($88D2); +4/+5 the exit list's offset from SectionTable
; (big-endian), into CheckSectionExit's LD IX,n; +6/+7 the map entry list's
; offset from SectionTable (big-endian), into SectionEntries $8B3E. The number
; of entries is not stored: SectionCounts $8374 says 10 for this level
; (ResetSectionObjects $8379 walks that many lists).
;
; The filler entries (10, 11, 12, 13) have map offset 0 (section 0's map),
; limit 0 and empty lists (two zero bytes each; the last entry's lists are the
; 0 word KindTable starts with). They lie past SectionCounts: no code reaches
; them.
SectionTable:
  ; $EBED section 0: map +$0000, limit 64, exits +$0070, entries +$0079
  ; $EBF5 section 1: map +$00A0, limit 144, exits +$00BE, entries +$00CF
  ; $EBFD section 2: map +$0200, limit 96, exits +$01AC, entries +$01C5
  ; $EC05 section 3: map +$0300, limit 144, exits +$02A2, entries +$02BB
  ; $EC0D section 4: map +$0460, limit 8, exits +$040C, entries +$0415
  ; $EC15 section 5: map +$04A0, limit 0, exits +$042E, entries +$0437
  ; $EC1D section 6: map +$04E0, limit 112, exits +$0454, entries +$0461
  ; $EC25 section 7: map +$0600, limit 8, exits +$0592, entries +$059B
  ; $EC2D section 8: map +$0648, limit 120, exits +$05BC, entries +$05C5
  ; $EC35 section 9: map +$0770, limit 56, exits +$06A6, entries +$06AB
  ; $EC3D filler entries 10-13
  INCBIN "res/level/sections.bin",$0000,112

; Section 0's exits: 2, then the 0 end
;
; 4 bytes an exit: +0 flags (bits 0-1 the side Rick leaves the view at: 1 left,
; 2 right; bit 4 ends the level even with CheatExits; bit 5 RideMode on the way
; in; bit 6 LevelHookOn = 20; bit 7 the level ends), +1 the section row of
; Rick's feet (ViewTop + (y + 20) / 8) at which it is taken, +2 the section
; entered, +3 the row of that section his feet arrive at (the new ViewTop = +3
; - his feet row in the view). A byte with bits 0, 1, 3 clear ends the list (a
; single 0). CheckSectionExit $8993 reads them.
Section0Exits:
  ; $EC5D flags $02: leaves at the right at row $17 -> section 1, row $47
  ; $EC61 flags $02: leaves at the right at row $47 -> section 1, row $5F
  ; $EC65 the end
  INCBIN "res/level/sections.bin",$0070,9

; Section 0's map entries: 11, then the 0 end
;
; The map entries, sorted by row: 4 bytes each, then +3 bits 0-1 trigger boxes
; of 4 bytes. +0 the kind (bit 7 set while its object lives:
; ResetSectionObjects $8379 and FreeObject $9C57 clear it): below $74 a trap or
; pickup through KindTable, $78 the countdown bonus starts, $7C it stops and
; pays, any other value from $74 an enemy (bits 0-1 its behaviour: 0 and 3
; wander, 1 patrols, 2 chases, 3 also climbs after Rick; bit 2 the second
; sprite set). +1 the cell row in the section. +2 bits 0-4 the column (x =
; column x 8), bit 5 x + 4 pixels, bit 6 y + 3 pixels (traps), bit 7 the spawn
; rule (set: when its row comes into the view; clear: when one of its boxes
; fires). +3 bits 0-1 the boxes, bits 2-5 a trap's behaviour ($20 treasure, $28
; ammunition, $2C detonators: pickups) or an enemy's patrol length ((n + 1) x 8
; pixels), bit 6 one-shot (never re-armed). A kind 0 ends the list.
;
; A trigger box: +0 x in pixels, +1 the cell row, +2 the size (high nibble rows
; - 1, low nibble columns - 1), +3 who sets it off (bit 0 Rick, 1 the bullet, 2
; the blast, 3 the punch, 4 an enemy, 5 another trap; bit 6 fires on every
; pass; bit 7 the latch TestTriggerBoxes $A69F keeps). ScanMapObjects $8B42 and
; SpawnFromMap $9C97 read the entries, TestTriggerBoxes the boxes.
Section0Objects:
  ; $EC66 kind $15: trap, behaviour $08; row $15, column 25, y +3 px;
  ;   spawns in view, 1 box
  ; $EC6A trigger box: x 128, row $1A, 4 x 1 cells, set off by Rick
  ; $EC6E kind $15: ammunition pickup; row $15, column 4, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EC72 trigger box: x 32, row $15, 3 x 3 cells, set off by Rick
  ; $EC76 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $15,
  ;   column 4; spawns in view
  ; $EC7A kind $09: trap, behaviour $18; row $1E, column 25; spawns in
  ;   view, 1 box
  ; $EC7E trigger box: x 200, row $25, 3 x 1 cells, set off by Rick
  ; $EC82 kind $16: trap, behaviour $08; row $1E, column 17; spawns in
  ;   view, 1 box
  ; $EC86 trigger box: x 192, row $28, 4 x 1 cells, set off by Rick
  ; $EC8A kind $06: trap, behaviour $18; row $20, column 12; spawns in
  ;   view, 1 box
  ; $EC8E trigger box: x 88, row $1D, 4 x 3 cells, set off by Rick
  ; $EC92 kind $05: trap, behaviour $0C; row $2D, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $EC96 trigger box: x 24, row $2E, 1 x 2 cells, set off by punch
  ; $EC9A kind $75: enemy patrols (sprite set 1), patrol 24 px; row $2D,
  ;   column 4; spawns in view
  ; $EC9E kind $75: enemy patrols (sprite set 1), patrol 40 px; row $35,
  ;   column 4; spawns in view
  ; $ECA2 kind $75: enemy patrols (sprite set 1), patrol 56 px; row $3D,
  ;   column 4; spawns in view
  ; $ECA6 kind $10: trap, behaviour $00; row $46, column 20 +4 px; spawns
  ;   in view
  ; $ECAA the end
  INCBIN "res/level/sections.bin",$0079,69

; Section 1's exits: 4, then the 0 end
Section1Exits:
  ; $ECAB flags $02: leaves at the right at row $17 -> section 2, row $17
  ; $ECAF flags $01: leaves at the left at row $47 -> section 0, row $17
  ; $ECB3 flags $01: leaves at the left at row $5F -> section 0, row $47
  ; $ECB7 flags $02: leaves at the right at row $9F -> section 2, row $6F
  ; $ECBB the end
  INCBIN "res/level/sections.bin",$00BE,17

; Section 1's map entries: 33, then the 0 end
Section1Objects:
  ; $ECBC kind $16: detonators pickup; row $0D, column 4, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $ECC0 trigger box: x 32, row $0D, 3 x 3 cells, set off by Rick
  ; $ECC4 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $15,
  ;   column 8; spawns in view
  ; $ECC8 kind $7C: the countdown bonus stops and pays; row $15, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $ECCC trigger box: x 232, row $14, 3 x 4 cells, set off by Rick
  ; $ECD0 kind $13: trap, behaviour $24; row $18, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $ECD4 trigger box: x 24, row $1E, 1 x 2 cells, set off by punch
  ; $ECD8 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $21,
  ;   column 20; spawns in view
  ; $ECDC kind $03: trap, behaviour $00; row $21, column 25; spawns on its
  ;   box, 1 box
  ; $ECE0 trigger box: x 24, row $2A, 1 x 2 cells, set off by punch
  ; $ECE4 kind $02: trap, behaviour $10; row $25, column 4; spawns on its
  ;   box, 1 box
  ; $ECE8 trigger box: x 32, row $25, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $ECEC kind $14: treasure pickup; row $29, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $ECF0 trigger box: x 200, row $29, 3 x 3 cells, set off by Rick
  ; $ECF4 kind $79: enemy patrols (sprite set 0), patrol 40 px; row $35,
  ;   column 4; spawns in view
  ; $ECF8 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $35, column 25; spawns in view, one-shot
  ; $ECFC kind $07: trap, behaviour $18; row $38, column 8; spawns in view,
  ;   1 box
  ; $ED00 trigger box: x 72, row $37, 1 x 1 cells, set off by Rick
  ; $ED04 kind $05: trap, behaviour $00; row $45, column 8, y +3 px; spawns
  ;   on its box, 1 box
  ; $ED08 trigger box: x 72, row $47, 1 x 1 cells, set off by Rick
  ; $ED0C kind $05: trap, behaviour $00; row $45, column 16, y +3 px;
  ;   spawns on its box, 1 box
  ; $ED10 trigger box: x 136, row $47, 1 x 1 cells, set off by Rick
  ; $ED14 kind $78: the countdown bonus starts; row $45, column 25; spawns
  ;   on its box, 1 box
  ; $ED18 trigger box: x 184, row $42, 5 x 6 cells, set off by Rick
  ; $ED1C kind $08: trap, behaviour $18; row $58, column 4; spawns in view,
  ;   1 box
  ; $ED20 trigger box: x 32, row $5C, 3 x 4 cells, set off by Rick
  ; $ED24 kind $12: trap, behaviour $24; row $58, column 28 +4 px; spawns
  ;   in view, 1 box
  ; $ED28 trigger box: x 224, row $62, 1 x 2 cells, set off by punch
  ; $ED2C kind $79: enemy patrols (sprite set 0), patrol 32 px; row $59,
  ;   column 12; spawns in view
  ; $ED30 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $59, column 17; spawns in view, one-shot
  ; $ED34 kind $0C: trap, behaviour $24; row $5D, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $ED38 trigger box: x 152, row $5E, 1 x 10 cells, set off by Rick/enemy
  ; $ED3C kind $7C: the countdown bonus stops and pays; row $5D, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $ED40 trigger box: x 0, row $5D, 3 x 3 cells, set off by Rick
  ; $ED44 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $61,
  ;   column 8; spawns in view
  ; $ED48 kind $02: trap, behaviour $10; row $69, column 4; spawns on its
  ;   box, 1 box
  ; $ED4C trigger box: x 96, row $6C, 12 x 4 cells, set off by Rick, every
  ;   pass
  ; $ED50 kind $15: ammunition pickup; row $69, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $ED54 trigger box: x 64, row $69, 3 x 3 cells, set off by Rick
  ; $ED58 kind $04: trap, behaviour $00; row $6D, column 12; spawns on its
  ;   box, 1 box
  ; $ED5C trigger box: x 96, row $6D, 3 x 3 cells, set off by Rick
  ; $ED60 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $79,
  ;   column 20; spawns in view
  ; $ED64 kind $05: trap, behaviour $0C; row $7D, column 9, y +3 px; spawns
  ;   in view, 1 box
  ; $ED68 trigger box: x 24, row $7E, 1 x 2 cells, set off by punch
  ; $ED6C kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $86, column 8; spawns in view
  ; $ED70 kind $01: trap, behaviour $10; row $86, column 25; spawns on its
  ;   box, 1 box
  ; $ED74 trigger box: x 72, row $86, 8 x 3 cells, set off by Rick, every
  ;   pass
  ; $ED78 kind $14: treasure pickup; row $8E, column 17, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $ED7C trigger box: x 136, row $8E, 3 x 3 cells, set off by Rick
  ; $ED80 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $91,
  ;   column 4; spawns in view
  ; $ED84 kind $78: the countdown bonus starts; row $91, column 4; spawns
  ;   on its box, 1 box
  ; $ED88 trigger box: x 32, row $91, 4 x 3 cells, set off by Rick
  ; $ED8C kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $95, column 25; spawns in view, one-shot
  ; $ED90 kind $11: trap, behaviour $18; row $9D, column 25, y +3 px;
  ;   spawns in view, 1 box
  ; $ED94 trigger box: x 160, row $A0, 4 x 4 cells, set off by Rick
  ; $ED98 the end
  INCBIN "res/level/sections.bin",$00CF,221

; Section 2's exits: 6, then the 0 end
Section2Exits:
  ; $ED99 flags $01: leaves at the left at row $17 -> section 1, row $17
  ; $ED9D flags $02: leaves at the right at row $17 -> section 3, row $17
  ; $EDA1 flags $02: leaves at the right at row $2F -> section 3, row $47
  ; $EDA5 flags $02: leaves at the right at row $57 -> section 3, row $5F
  ; $EDA9 flags $01: leaves at the left at row $6F -> section 1, row $9F
  ; $EDAD flags $02: leaves at the right at row $73 -> section 3, row $A3
  ; $EDB1 the end
  INCBIN "res/level/sections.bin",$01AC,25

; Section 2's map entries: 29, then the 0 end
Section2Objects:
  ; $EDB2 kind $14: trap, behaviour $18; row $06, column 16; spawns in
  ;   view, 1 box
  ; $EDB6 trigger box: x 128, row $0E, 1 x 6 cells, set off by Rick
  ; $EDBA kind $14: trap, behaviour $18; row $06, column 22; spawns in
  ;   view, 1 box
  ; $EDBE trigger box: x 176, row $0D, 1 x 7 cells, set off by Rick
  ; $EDC2 kind $15: ammunition pickup; row $11, column 9, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EDC6 trigger box: x 72, row $11, 3 x 3 cells, set off by Rick
  ; $EDCA kind $02: trap, behaviour $10; row $11, column 4; spawns on its
  ;   box, 1 box
  ; $EDCE trigger box: x 32, row $13, 8 x 5 cells, set off by Rick, every
  ;   pass
  ; $EDD2 kind $05: trap, behaviour $00; row $15, column 21, y +3 px;
  ;   spawns on its box, 1 box
  ; $EDD6 trigger box: x 160, row $15, 5 x 3 cells, set off by Rick
  ; $EDDA kind $79: enemy patrols (sprite set 0), patrol 32 px; row $2D,
  ;   column 8; spawns in view
  ; $EDDE kind $79: enemy patrols (sprite set 0), patrol 24 px; row $2D,
  ;   column 16; spawns in view
  ; $EDE2 kind $7C: the countdown bonus stops and pays; row $2D, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $EDE6 trigger box: x 232, row $2C, 3 x 4 cells, set off by Rick
  ; $EDEA kind $26: trap, behaviour $08; row $2E, column 25; spawns in
  ;   view, 1 box
  ; $EDEE trigger box: x 24, row $32, 1 x 2 cells, set off by punch
  ; $EDF2 kind $05: trap, behaviour $00; row $31, column 8, y +3 px; spawns
  ;   on its box, 1 box
  ; $EDF6 trigger box: x 24, row $32, 1 x 2 cells, set off by punch
  ; $EDFA kind $25: trap, behaviour $10; row $39, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $EDFE trigger box: x 80, row $38, 2 x 4 cells, set off by Rick
  ; $EE02 kind $0A: trap, behaviour $10; row $3C, column 10; spawns on its
  ;   box, 1 box
  ; $EE06 trigger box: x 80, row $3B, 1 x 1 cells, set off by Rick/trap
  ; $EE0A kind $0A: trap, behaviour $10; row $3C, column 13; spawns on its
  ;   box, 1 box
  ; $EE0E trigger box: x 104, row $3B, 1 x 1 cells, set off by Rick/trap
  ; $EE12 kind $0A: trap, behaviour $10; row $3C, column 16; spawns on its
  ;   box, 1 box
  ; $EE16 trigger box: x 128, row $3B, 1 x 1 cells, set off by Rick/trap
  ; $EE1A kind $0A: trap, behaviour $10; row $3C, column 19; spawns on its
  ;   box, 1 box
  ; $EE1E trigger box: x 152, row $3B, 1 x 1 cells, set off by Rick/trap
  ; $EE22 kind $0A: trap, behaviour $10; row $3C, column 22; spawns on its
  ;   box, 1 box
  ; $EE26 trigger box: x 176, row $3B, 1 x 1 cells, set off by Rick/trap
  ; $EE2A kind $0A: trap, behaviour $10; row $3C, column 4; spawns on its
  ;   box, 1 box
  ; $EE2E trigger box: x 40, row $39, 2 x 1 cells, set off by Rick/trap
  ; $EE32 kind $0A: trap, behaviour $10; row $3C, column 7; spawns on its
  ;   box, 1 box
  ; $EE36 trigger box: x 64, row $3B, 1 x 1 cells, set off by Rick/trap
  ; $EE3A kind $24: trap, behaviour $10; row $3D, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE3E trigger box: x 80, row $40, 10 x 4 cells, set off by Rick
  ; $EE42 kind $01: trap, behaviour $00; row $4D, column 25; spawns on its
  ;   box, 1 box
  ; $EE46 trigger box: x 96, row $4F, 4 x 1 cells, set off by Rick
  ; $EE4A kind $03: trap, behaviour $00; row $50, column 25; spawns in view
  ; $EE4E kind $22: trap, behaviour $24; row $54, column 4; spawns in view,
  ;   1 box
  ; $EE52 trigger box: x 32, row $51, 2 x 1 cells, set off by Rick
  ; $EE56 kind $15: ammunition pickup; row $55, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EE5A trigger box: x 200, row $55, 3 x 3 cells, set off by Rick
  ; $EE5E kind $78: the countdown bonus starts; row $55, column 4; spawns
  ;   on its box, 1 box
  ; $EE62 trigger box: x 32, row $55, 5 x 3 cells, set off by Rick
  ; $EE66 kind $19: trap, behaviour $24; row $58, column 4; spawns in view,
  ;   1 box
  ; $EE6A trigger box: x 24, row $66, 1 x 2 cells, set off by punch
  ; $EE6E kind $0E: trap, behaviour $08; row $6D, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $EE72 trigger box: x 48, row $6E, 6 x 2 cells, set off by blast
  ; $EE76 kind $05: trap, behaviour $00; row $71, column 23, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $EE7A trigger box: x 184, row $71, 1 x 3 cells, set off by Rick
  ; $EE7E trigger box: x 232, row $71, 1 x 3 cells, set off by Rick
  ; $EE82 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $75, column 16; spawns in view
  ; $EE86 kind $14: treasure pickup; row $75, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EE8A trigger box: x 200, row $75, 3 x 3 cells, set off by Rick
  ; $EE8E the end
  INCBIN "res/level/sections.bin",$01C5,221

; Section 3's exits: 6, then the 0 end
Section3Exits:
  ; $EE8F flags $01: leaves at the left at row $17 -> section 2, row $17
  ; $EE93 flags $02: leaves at the right at row $17 -> section 4, row $17
  ; $EE97 flags $01: leaves at the left at row $47 -> section 2, row $2F
  ; $EE9B flags $01: leaves at the left at row $5F -> section 2, row $57
  ; $EE9F flags $01: leaves at the left at row $A3 -> section 2, row $73
  ; $EEA3 flags $02: leaves at the right at row $A7 -> section 5, row $17
  ; $EEA7 the end
  INCBIN "res/level/sections.bin",$02A2,25

; Section 3's map entries: 42, then the 0 end
Section3Objects:
  ; $EEA8 kind $17: trap, behaviour $10; row $0E, column 29; spawns on its
  ;   box, 3 boxes
  ; $EEAC trigger box: x 24, row $14, 1 x 4 cells, set off by Rick
  ; $EEB0 trigger box: x 112, row $15, 1 x 3 cells, set off by trap
  ; $EEB4 trigger box: x 224, row $14, 1 x 4 cells, set off by Rick
  ; $EEB8 kind $17: trap, behaviour $00; row $0E, column 29; spawns on its
  ;   box, 3 boxes
  ; $EEBC trigger box: x 112, row $14, 1 x 4 cells, set off by trap
  ; $EEC0 trigger box: x 32, row $19, 16 x 1 cells, set off by Rick
  ; $EEC4 trigger box: x 160, row $19, 8 x 1 cells, set off by Rick
  ; $EEC8 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $19, column 25; spawns on its box, 1 box
  ; $EECC trigger box: x 32, row $25, 4 x 1 cells, set off by Rick
  ; $EED0 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $19, column 25; spawns on its box, 1 box
  ; $EED4 trigger box: x 32, row $25, 4 x 1 cells, set off by Rick
  ; $EED8 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $19, column 25; spawns on its box, 1 box
  ; $EEDC trigger box: x 32, row $25, 4 x 1 cells, set off by Rick
  ; $EEE0 kind $78: the countdown bonus starts; row $29, column 25; spawns
  ;   on its box, 1 box
  ; $EEE4 trigger box: x 184, row $28, 5 x 4 cells, set off by Rick
  ; $EEE8 kind $7C: the countdown bonus stops and pays; row $29, column 4;
  ;   spawns on its box, one-shot, 1 box
  ; $EEEC trigger box: x 32, row $28, 4 x 4 cells, set off by Rick
  ; $EEF0 kind $0A: trap, behaviour $10; row $2C, column 9; spawns on its
  ;   box, 1 box
  ; $EEF4 trigger box: x 88, row $2B, 1 x 1 cells, set off by Rick
  ; $EEF8 kind $0A: trap, behaviour $10; row $2C, column 21; spawns on its
  ;   box, 1 box
  ; $EEFC trigger box: x 176, row $2B, 1 x 1 cells, set off by Rick
  ; $EF00 kind $0A: trap, behaviour $10; row $2C, column 6; spawns on its
  ;   box, 1 box
  ; $EF04 trigger box: x 64, row $2B, 1 x 1 cells, set off by Rick
  ; $EF08 kind $0A: trap, behaviour $10; row $2C, column 12; spawns on its
  ;   box, 1 box
  ; $EF0C trigger box: x 112, row $2B, 1 x 1 cells, set off by Rick
  ; $EF10 kind $0A: trap, behaviour $10; row $2C, column 15; spawns on its
  ;   box, 1 box
  ; $EF14 trigger box: x 136, row $2B, 1 x 1 cells, set off by Rick
  ; $EF18 kind $0A: trap, behaviour $10; row $2C, column 18; spawns on its
  ;   box, 1 box
  ; $EF1C trigger box: x 160, row $2B, 1 x 1 cells, set off by Rick
  ; $EF20 kind $02: trap, behaviour $10; row $35, column 4; spawns on its
  ;   box, 1 box
  ; $EF24 trigger box: x 32, row $34, 16 x 4 cells, set off by Rick, every
  ;   pass
  ; $EF28 kind $05: trap, behaviour $0C; row $35, column 16 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $EF2C trigger box: x 120, row $32, 1 x 6 cells, set off by Rick
  ; $EF30 kind $27: trap, behaviour $0C; row $36, column 25; spawns in
  ;   view, 1 box
  ; $EF34 trigger box: x 224, row $3E, 1 x 2 cells, set off by punch
  ; $EF38 kind $0A: trap, behaviour $10; row $40, column 12 +4 px; spawns
  ;   on its box, 1 box
  ; $EF3C trigger box: x 96, row $3F, 2 x 1 cells, set off by Rick
  ; $EF40 kind $15: ammunition pickup; row $41, column 24, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EF44 trigger box: x 192, row $41, 3 x 3 cells, set off by Rick
  ; $EF48 kind $21: trap, behaviour $00; row $45, column 17, y +3 px;
  ;   spawns in view
  ; $EF4C kind $21: trap, behaviour $00; row $59, column 17, y +3 px;
  ;   spawns in view
  ; $EF50 kind $7C: the countdown bonus stops and pays; row $5D, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $EF54 trigger box: x 0, row $5D, 3 x 3 cells, set off by Rick
  ; $EF58 kind $01: trap, behaviour $10; row $5E, column 25; spawns on its
  ;   box, 1 box
  ; $EF5C trigger box: x 32, row $5C, 4 x 8 cells, set off by Rick, every
  ;   pass
  ; $EF60 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $61, column 20; spawns in view
  ; $EF64 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $69, column 4; spawns in view
  ; $EF68 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $69, column 25; spawns in view
  ; $EF6C kind $20: trap, behaviour $08; row $6D, column 20; spawns in
  ;   view, 1 box
  ; $EF70 trigger box: x 144, row $70, 1 x 4 cells, set off by Rick
  ; $EF74 kind $1F: trap, behaviour $10; row $72, column 1; spawns on its
  ;   box, 1 box
  ; $EF78 trigger box: x 136, row $78, 5 x 1 cells, set off by trap
  ; $EF7C kind $1E: trap, behaviour $10; row $72, column 29; spawns on its
  ;   box, 1 box
  ; $EF80 trigger box: x 32, row $86, 4 x 1 cells, set off by trap
  ; $EF84 kind $1F: trap, behaviour $10; row $72, column 1; spawns on its
  ;   box, 1 box
  ; $EF88 trigger box: x 192, row $86, 4 x 1 cells, set off by trap
  ; $EF8C kind $1E: trap, behaviour $10; row $72, column 29; spawns on its
  ;   box, 2 boxes
  ; $EF90 trigger box: x 96, row $81, 8 x 1 cells, set off by Rick
  ; $EF94 trigger box: x 32, row $86, 4 x 1 cells, set off by trap
  ; $EF98 kind $09: trap, behaviour $18; row $82, column 25; spawns in
  ;   view, 2 boxes
  ; $EF9C trigger box: x 200, row $89, 3 x 1 cells, set off by Rick
  ; $EFA0 trigger box: x 112, row $85, 1 x 3 cells, set off by Rick
  ; $EFA4 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $89, column 25; spawns in view
  ; $EFA8 kind $02: trap, behaviour $10; row $89, column 4; spawns on its
  ;   box, 2 boxes
  ; $EFAC trigger box: x 32, row $89, 16 x 3 cells, set off by Rick, every
  ;   pass
  ; $EFB0 trigger box: x 160, row $89, 4 x 3 cells, set off by Rick, every
  ;   pass
  ; $EFB4 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $95,
  ;   column 4; spawns in view
  ; $EFB8 kind $78: the countdown bonus starts; row $95, column 12; spawns
  ;   on its box, 1 box
  ; $EFBC trigger box: x 88, row $95, 6 x 3 cells, set off by Rick
  ; $EFC0 kind $13: trap, behaviour $24; row $98, column 12 +4 px; spawns
  ;   in view, 1 box
  ; $EFC4 trigger box: x 152, row $9C, 1 x 8 cells, set off by Rick
  ; $EFC8 kind $1A: trap, behaviour $18; row $99, column 8 +4 px; spawns in
  ;   view, 1 box
  ; $EFCC trigger box: x 72, row $A2, 1 x 6 cells, set off by Rick
  ; $EFD0 kind $1A: trap, behaviour $18; row $99, column 20 +4 px; spawns
  ;   in view, 1 box
  ; $EFD4 trigger box: x 168, row $9C, 1 x 12 cells, set off by Rick
  ; $EFD8 kind $1A: trap, behaviour $18; row $99, column 24 +4 px; spawns
  ;   in view, 1 box
  ; $EFDC trigger box: x 200, row $9C, 1 x 12 cells, set off by Rick
  ; $EFE0 kind $1B: trap, behaviour $00; row $A5, column 24, y +3 px;
  ;   spawns on its box, 1 box
  ; $EFE4 trigger box: x 192, row $A7, 3 x 1 cells, set off by trap
  ; $EFE8 kind $1B: trap, behaviour $00; row $A5, column 8, y +3 px; spawns
  ;   on its box, 1 box
  ; $EFEC trigger box: x 64, row $A7, 3 x 1 cells, set off by trap
  ; $EFF0 kind $1B: trap, behaviour $00; row $A5, column 20, y +3 px;
  ;   spawns on its box, 1 box
  ; $EFF4 trigger box: x 160, row $A7, 3 x 1 cells, set off by trap
  ; $EFF8 the end
  INCBIN "res/level/sections.bin",$02BB,337

; Section 4's exits: 2, then the 0 end
Section4Exits:
  ; $EFF9 flags $01: leaves at the left at row $17 -> section 3, row $17
  ; $EFFD flags $02: leaves at the right at row $17 -> section 6, row $17
  ; $F001 the end
  INCBIN "res/level/sections.bin",$040C,9

; Section 4's map entries: 2, then the 0 end
Section4Objects:
  ; $F002 kind $18: trap, behaviour $10; row $0E, column 29; spawns on its
  ;   box, 3 boxes
  ; $F006 trigger box: x 24, row $14, 1 x 4 cells, set off by Rick
  ; $F00A trigger box: x 64, row $15, 4 x 3 cells, set off by trap
  ; $F00E trigger box: x 224, row $14, 1 x 4 cells, set off by Rick
  ; $F012 kind $18: trap, behaviour $00; row $0E, column 29; spawns on its
  ;   box, 1 box
  ; $F016 trigger box: x 64, row $15, 4 x 3 cells, set off by trap
  ; $F01A the end
  INCBIN "res/level/sections.bin",$0415,25

; Section 5's exits: 2, then the 0 end
Section5Exits:
  ; $F01B flags $01: leaves at the left at row $17 -> section 3, row $A7
  ; $F01F flags $02: leaves at the right at row $17 -> section 6, row $87
  ; $F023 the end
  INCBIN "res/level/sections.bin",$042E,9

; Section 5's map entries: 5, then the 0 end
Section5Objects:
  ; $F024 kind $15: ammunition pickup; row $0D, column 12 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F028 trigger box: x 96, row $0D, 3 x 3 cells, set off by Rick
  ; $F02C kind $1C: trap, behaviour $18; row $11, column 13, y +3 px;
  ;   spawns in view, 1 box
  ; $F030 trigger box: x 88, row $12, 2 x 2 cells, set off by blast
  ; $F034 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 16; spawns in view
  ; $F038 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 19; spawns in view
  ; $F03C kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 22; spawns in view
  ; $F040 the end
  INCBIN "res/level/sections.bin",$0437,29

; Section 6's exits: 3, then the 0 end
Section6Exits:
  ; $F041 flags $01: leaves at the left at row $17 -> section 4, row $17
  ; $F045 flags $82: leaves at the right at row $17 -> section 7, row $17;
  ;   bit 7: ends the level; with CheatExits ($8067 bit 7) a passage into
  ;   section 7
  ; $F049 flags $01: leaves at the left at row $87 -> section 5, row $17
  ; $F04D the end
  INCBIN "res/level/sections.bin",$0454,13

; Section 6's map entries: 39, then the 0 end
Section6Objects:
  ; $F04E kind $14: trap, behaviour $18; row $05, column 16; spawns in
  ;   view, 1 box
  ; $F052 trigger box: x 128, row $0C, 1 x 4 cells, set off by Rick
  ; $F056 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $09,
  ;   column 20; spawns in view
  ; $F05A kind $75: enemy patrols (sprite set 1), patrol 24 px; row $0D,
  ;   column 8; spawns in view
  ; $F05E kind $14: treasure pickup; row $0D, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F062 trigger box: x 200, row $0D, 3 x 3 cells, set off by Rick
  ; $F066 kind $04: trap, behaviour $00; row $11, column 4; spawns on its
  ;   box, 1 box
  ; $F06A trigger box: x 32, row $11, 1 x 3 cells, set off by Rick
  ; $F06E kind $09: trap, behaviour $18; row $12, column 25; spawns in
  ;   view, 2 boxes
  ; $F072 trigger box: x 208, row $15, 2 x 3 cells, set off by Rick
  ; $F076 trigger box: x 224, row $0A, 1 x 2 cells, set off by punch
  ; $F07A kind $75: enemy patrols (sprite set 1), patrol 24 px; row $15,
  ;   column 16; spawns in view
  ; $F07E kind $7C: the countdown bonus stops and pays; row $15, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F082 trigger box: x 232, row $14, 3 x 4 cells, set off by Rick
  ; $F086 kind $09: trap, behaviour $18; row $1F, column 25; spawns in
  ;   view, 1 box
  ; $F08A trigger box: x 200, row $25, 3 x 2 cells, set off by Rick
  ; $F08E kind $04: trap, behaviour $0C; row $21, column 4; spawns in view,
  ;   1 box
  ; $F092 trigger box: x 224, row $26, 1 x 2 cells, set off by punch
  ; $F096 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $21,
  ;   column 16; spawns in view
  ; $F09A kind $05: trap, behaviour $00; row $25, column 14, y +3 px;
  ;   spawns on its box, 1 box
  ; $F09E trigger box: x 152, row $26, 1 x 2 cells, set off by Rick
  ; $F0A2 kind $0C: trap, behaviour $24; row $29, column 8 +4 px; spawns in
  ;   view, 1 box
  ; $F0A6 trigger box: x 64, row $33, 4 x 1 cells, set off by Rick
  ; $F0AA kind $0B: trap, behaviour $24; row $29, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $F0AE trigger box: x 128, row $33, 4 x 1 cells, set off by Rick
  ; $F0B2 kind $15: ammunition pickup; row $2D, column 21, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F0B6 trigger box: x 168, row $2D, 3 x 3 cells, set off by Rick
  ; $F0BA kind $02: trap, behaviour $10; row $3A, column 4; spawns on its
  ;   box, 1 box
  ; $F0BE trigger box: x 112, row $39, 14 x 3 cells, set off by Rick, every
  ;   pass
  ; $F0C2 kind $0A: trap, behaviour $1C; row $3C, column 6; spawns on its
  ;   box, 1 box
  ; $F0C6 trigger box: x 48, row $3B, 3 x 1 cells, set off by Rick, every
  ;   pass
  ; $F0CA kind $0A: trap, behaviour $1C; row $40, column 4; spawns on its
  ;   box, 1 box
  ; $F0CE trigger box: x 32, row $3F, 2 x 1 cells, set off by Rick, every
  ;   pass
  ; $F0D2 kind $78: the countdown bonus starts; row $41, column 13; spawns
  ;   on its box, 1 box
  ; $F0D6 trigger box: x 104, row $3E, 3 x 6 cells, set off by Rick
  ; $F0DA kind $0A: trap, behaviour $1C; row $44, column 9; spawns on its
  ;   box, 1 box
  ; $F0DE trigger box: x 80, row $43, 1 x 1 cells, set off by Rick, every
  ;   pass
  ; $F0E2 kind $2D: trap, behaviour $10; row $46, column 29; spawns on its
  ;   box, 2 boxes
  ; $F0E6 trigger box: x 32, row $50, 8 x 1 cells, set off by Rick
  ; $F0EA trigger box: x 104, row $4B, 1 x 5 cells, set off by trap
  ; $F0EE kind $2D: trap, behaviour $10; row $46, column 29; spawns on its
  ;   box, 1 box
  ; $F0F2 trigger box: x 104, row $4B, 1 x 5 cells, set off by trap
  ; $F0F6 kind $09: trap, behaviour $18; row $53, column 25; spawns in
  ;   view, 1 box
  ; $F0FA trigger box: x 200, row $5A, 3 x 1 cells, set off by Rick
  ; $F0FE kind $76: enemy chases (sprite set 1), patrol 8 px; row $55,
  ;   column 4; spawns in view
  ; $F102 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $55,
  ;   column 17; spawns in view
  ; $F106 kind $0A: trap, behaviour $10; row $59, column 24 +4 px; spawns
  ;   on its box, 1 box
  ; $F10A trigger box: x 192, row $59, 4 x 1 cells, set off by Rick
  ; $F10E kind $75: enemy patrols (sprite set 1), patrol 32 px; row $5A,
  ;   column 17; spawns in view
  ; $F112 kind $2B: trap, behaviour $10; row $61, column 29, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $F116 trigger box: x 32, row $61, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $F11A trigger box: x 152, row $61, 9 x 3 cells, set off by Rick, every
  ;   pass
  ; $F11E kind $2A: trap, behaviour $10; row $61, column 0, y +3 px; spawns
  ;   on its box, 2 boxes
  ; $F122 trigger box: x 32, row $61, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $F126 trigger box: x 152, row $61, 9 x 3 cells, set off by Rick, every
  ;   pass
  ; $F12A kind $02: trap, behaviour $10; row $69, column 4; spawns on its
  ;   box, 2 boxes
  ; $F12E trigger box: x 32, row $69, 16 x 5 cells, set off by Rick, every
  ;   pass
  ; $F132 trigger box: x 152, row $69, 9 x 5 cells, set off by Rick, every
  ;   pass
  ; $F136 kind $01: trap, behaviour $10; row $69, column 25; spawns on its
  ;   box, 2 boxes
  ; $F13A trigger box: x 96, row $69, 16 x 5 cells, set off by Rick, every
  ;   pass
  ; $F13E trigger box: x 32, row $69, 9 x 5 cells, set off by Rick, every
  ;   pass
  ; $F142 kind $2C: trap, behaviour $10; row $6C, column 24 +4 px; spawns
  ;   on its box, 1 box
  ; $F146 trigger box: x 224, row $72, 1 x 2 cells, set off by punch
  ; $F14A kind $28: trap, behaviour $10; row $6C, column 4 +4 px; spawns on
  ;   its box, 1 box
  ; $F14E trigger box: x 24, row $72, 1 x 2 cells, set off by punch
  ; $F152 kind $21: trap, behaviour $00; row $71, column 9 +4 px, y +3 px;
  ;   spawns in view
  ; $F156 kind $29: trap, behaviour $00; row $71, column 25; spawns on its
  ;   box, 1 box
  ; $F15A trigger box: x 160, row $70, 8 x 3 cells, set off by Rick, every
  ;   pass
  ; $F15E kind $1D: trap, behaviour $18; row $79, column 24, y +3 px;
  ;   spawns in view, 1 box
  ; $F162 trigger box: x 48, row $84, 1 x 4 cells, set off by Rick
  ; $F166 kind $05: trap, behaviour $00; row $85, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $F16A trigger box: x 48, row $84, 1 x 4 cells, set off by Rick
  ; $F16E kind $06: trap, behaviour $18; row $88, column 8; spawns in view,
  ;   1 box
  ; $F172 trigger box: x 64, row $84, 1 x 4 cells, set off by trap
  ; $F176 kind $05: trap, behaviour $00; row $89, column 4, y +3 px; spawns
  ;   on its box, 1 box
  ; $F17A trigger box: x 0, row $89, 2 x 3 cells, set off by trap
  ; $F17E the end
  INCBIN "res/level/sections.bin",$0461,305

; Section 7's exits: 2, then the 0 end
Section7Exits:
  ; $F17F flags $01: leaves at the left at row $17 -> section 6, row $17
  ; $F183 flags $02: leaves at the right at row $17 -> section 8, row $17
  ; $F187 the end
  INCBIN "res/level/sections.bin",$0592,9

; Section 7's map entries: 5, then the 0 end
Section7Objects:
  ; $F188 kind $14: trap, behaviour $18; row $09, column 4; spawns in view,
  ;   1 box
  ; $F18C trigger box: x 40, row $14, 1 x 4 cells, set off by Rick
  ; $F190 kind $21: trap, behaviour $00; row $11, column 17 +4 px, y +3 px;
  ;   spawns in view
  ; $F194 kind $21: trap, behaviour $00; row $15, column 25 +4 px, y +3 px;
  ;   spawns in view
  ; $F198 kind $07: trap, behaviour $18; row $18, column 8; spawns in view,
  ;   1 box
  ; $F19C trigger box: x 72, row $17, 3 x 1 cells, set off by Rick
  ; $F1A0 kind $33: trap, behaviour $1C; row $18, column 4 +4 px; spawns on
  ;   its box, 1 box
  ; $F1A4 trigger box: x 40, row $17, 2 x 1 cells, set off by Rick, every
  ;   pass
  ; $F1A8 the end
  INCBIN "res/level/sections.bin",$059B,33

; Section 8's exits: 2, then the 0 end
Section8Exits:
  ; $F1A9 flags $01: leaves at the left at row $17 -> section 7, row $17
  ; $F1AD flags $02: leaves at the right at row $8F -> section 9, row $17
  ; $F1B1 the end
  INCBIN "res/level/sections.bin",$05BC,9

; Section 8's map entries: 31, then the 0 end
Section8Objects:
  ; $F1B2 kind $14: trap, behaviour $18; row $09, column 21; spawns in
  ;   view, 1 box
  ; $F1B6 trigger box: x 168, row $13, 1 x 6 cells, set off by Rick
  ; $F1BA kind $75: enemy patrols (sprite set 1), patrol 40 px; row $16,
  ;   column 15; spawns in view
  ; $F1BE kind $78: the countdown bonus starts; row $16, column 16; spawns
  ;   on its box, 1 box
  ; $F1C2 trigger box: x 120, row $13, 5 x 6 cells, set off by Rick
  ; $F1C6 kind $0A: trap, behaviour $10; row $17, column 11; spawns on its
  ;   box, 1 box
  ; $F1CA trigger box: x 88, row $16, 2 x 1 cells, set off by Rick
  ; $F1CE kind $0A: trap, behaviour $10; row $19, column 4; spawns on its
  ;   box, 1 box
  ; $F1D2 trigger box: x 40, row $18, 1 x 1 cells, set off by Rick
  ; $F1D6 kind $79: enemy patrols (sprite set 0), patrol 40 px; row $25,
  ;   column 12; spawns in view
  ; $F1DA kind $03: trap, behaviour $00; row $25, column 25; spawns on its
  ;   box, 1 box
  ; $F1DE trigger box: x 200, row $26, 3 x 2 cells, set off by Rick
  ; $F1E2 kind $03: trap, behaviour $00; row $29, column 9; spawns on its
  ;   box, 1 box
  ; $F1E6 trigger box: x 88, row $29, 1 x 4 cells, set off by Rick
  ; $F1EA kind $04: trap, behaviour $00; row $2E, column 4; spawns on its
  ;   box, 1 box
  ; $F1EE trigger box: x 32, row $2E, 1 x 3 cells, set off by Rick
  ; $F1F2 kind $05: trap, behaviour $0C; row $35, column 15, y +3 px;
  ;   spawns in view, 1 box
  ; $F1F6 trigger box: x 104, row $36, 2 x 2 cells, set off by blast
  ; $F1FA kind $05: trap, behaviour $0C; row $35, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $F1FE trigger box: x 48, row $36, 2 x 2 cells, set off by blast
  ; $F202 kind $07: trap, behaviour $18; row $44, column 12; spawns in
  ;   view, 1 box
  ; $F206 trigger box: x 96, row $42, 3 x 1 cells, set off by Rick
  ; $F20A kind $07: trap, behaviour $18; row $44, column 4; spawns in view,
  ;   1 box
  ; $F20E trigger box: x 24, row $3E, 1 x 2 cells, set off by punch
  ; $F212 kind $05: trap, behaviour $0C; row $49, column 4 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F216 trigger box: x 32, row $48, 4 x 1 cells, set off by Rick
  ; $F21A kind $14: treasure pickup; row $49, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F21E trigger box: x 200, row $49, 3 x 3 cells, set off by Rick
  ; $F222 kind $75: enemy patrols (sprite set 1), patrol 40 px; row $4D,
  ;   column 16; spawns in view
  ; $F226 kind $21: trap, behaviour $00; row $55, column 9 +4 px, y +3 px;
  ;   spawns in view
  ; $F22A kind $07: trap, behaviour $18; row $58, column 24; spawns in
  ;   view, 1 box
  ; $F22E trigger box: x 184, row $56, 5 x 2 cells, set off by blast
  ; $F232 kind $2E: trap, behaviour $08; row $5E, column 24; spawns in
  ;   view, 1 box
  ; $F236 trigger box: x 192, row $5D, 3 x 1 cells, set off by Rick
  ; $F23A kind $05: trap, behaviour $0C; row $61, column 9, y +3 px; spawns
  ;   in view, 1 box
  ; $F23E trigger box: x 64, row $60, 4 x 1 cells, set off by Rick
  ; $F242 kind $7C: the countdown bonus stops and pays; row $61, column 8;
  ;   spawns on its box, one-shot, 1 box
  ; $F246 trigger box: x 64, row $61, 4 x 3 cells, set off by Rick
  ; $F24A kind $79: enemy patrols (sprite set 0), patrol 40 px; row $69,
  ;   column 4; spawns in view
  ; $F24E kind $06: trap, behaviour $18; row $6C, column 24; spawns in
  ;   view, 1 box
  ; $F252 trigger box: x 224, row $6A, 1 x 2 cells, set off by punch
  ; $F256 kind $14: treasure pickup; row $71, column 8, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F25A trigger box: x 64, row $71, 3 x 3 cells, set off by Rick
  ; $F25E kind $0A: trap, behaviour $1C; row $79, column 13; spawns on its
  ;   box, 1 box
  ; $F262 trigger box: x 104, row $78, 3 x 1 cells, set off by Rick, every
  ;   pass
  ; $F266 kind $0A: trap, behaviour $1C; row $7C, column 17; spawns on its
  ;   box, 1 box
  ; $F26A trigger box: x 136, row $7B, 3 x 1 cells, set off by Rick, every
  ;   pass
  ; $F26E kind $7D: enemy patrols (sprite set 1), patrol 8 px; row $81,
  ;   column 20; spawns in view
  ; $F272 kind $30: trap, behaviour $18; row $81, column 5; spawns in view,
  ;   2 boxes
  ; $F276 trigger box: x 32, row $8B, 4 x 9 cells, set off by Rick
  ; $F27A trigger box: x 96, row $8F, 4 x 5 cells, set off by Rick
  ; $F27E kind $2F: trap, behaviour $08; row $8D, column 29, y +3 px;
  ;   spawns in view, 1 box
  ; $F282 trigger box: x 208, row $8C, 2 x 8 cells, set off by Rick
  ; $F286 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $91, column 13; spawns in view
  ; $F28A kind $1B: trap, behaviour $00; row $91, column 5, y +3 px; spawns
  ;   on its box, 1 box
  ; $F28E trigger box: x 40, row $93, 3 x 1 cells, set off by trap
  ; $F292 the end
  INCBIN "res/level/sections.bin",$05C5,225

; Section 9's exits: 1, then the 0 end
Section9Exits:
  ; $F293 flags $92: leaves at the right at row $4B -> section 0, row $4B;
  ;   bit 7 + bit 4: ends the level (also with CheatExits)
  ; $F297 the end
  INCBIN "res/level/sections.bin",$06A6,5

; Section 9's map entries: 19, then the 0 end
Section9Objects:
  ; $F298 kind $31: trap, behaviour $18; row $11, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $F29C trigger box: x 64, row $14, 1 x 4 cells, set off by Rick
  ; $F2A0 kind $78: the countdown bonus starts; row $15, column 20; spawns
  ;   on its box, 1 box
  ; $F2A4 trigger box: x 160, row $15, 4 x 3 cells, set off by Rick
  ; $F2A8 kind $15: ammunition pickup; row $19, column 5, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F2AC trigger box: x 40, row $19, 3 x 3 cells, set off by Rick
  ; $F2B0 kind $04: trap, behaviour $0C; row $20, column 20; spawns in
  ;   view, 1 box
  ; $F2B4 trigger box: x 64, row $27, 8 x 1 cells, set off by Rick
  ; $F2B8 kind $03: trap, behaviour $0C; row $20, column 25; spawns in
  ;   view, 1 box
  ; $F2BC trigger box: x 64, row $27, 8 x 1 cells, set off by Rick
  ; $F2C0 kind $16: detonators pickup; row $29, column 4, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F2C4 trigger box: x 32, row $29, 3 x 3 cells, set off by Rick
  ; $F2C8 kind $05: trap, behaviour $0C; row $31, column 24, y +3 px;
  ;   spawns in view, 1 box
  ; $F2CC trigger box: x 192, row $30, 4 x 1 cells, set off by Rick
  ; $F2D0 kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $35,
  ;   column 16; spawns in view
  ; $F2D4 kind $03: trap, behaviour $00; row $3D, column 13; spawns on its
  ;   box, 1 box
  ; $F2D8 trigger box: x 120, row $3C, 1 x 4 cells, set off by Rick
  ; $F2DC kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $3D,
  ;   column 4; spawns in view
  ; $F2E0 kind $15: trap, behaviour $08; row $41, column 25, y +3 px;
  ;   spawns in view, 1 box
  ; $F2E4 trigger box: x 88, row $39, 5 x 1 cells, set off by Rick
  ; $F2E8 kind $16: ammunition pickup; row $45, column 20 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F2EC trigger box: x 160, row $45, 3 x 3 cells, set off by Rick
  ; $F2F0 kind $32: trap, behaviour $18; row $45, column 25; spawns in
  ;   view, 1 box
  ; $F2F4 trigger box: x 200, row $4B, 1 x 5 cells, set off by Rick
  ; $F2F8 kind $04: trap, behaviour $00; row $49, column 4; spawns on its
  ;   box, 1 box
  ; $F2FC trigger box: x 32, row $49, 2 x 3 cells, set off by Rick
  ; $F300 kind $7C: the countdown bonus stops and pays; row $49, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F304 trigger box: x 232, row $48, 3 x 4 cells, set off by Rick
  ; $F308 kind $1B: trap, behaviour $00; row $4D, column 25, y +3 px;
  ;   spawns on its box, 1 box
  ; $F30C trigger box: x 200, row $4F, 3 x 1 cells, set off by trap
  ; $F310 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $4D, column 8; spawns in view
  ; $F314 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $4D, column 15; spawns in view
  ; $F318 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $4D, column 22; spawns in view
  ; $F31C the end
  INCBIN "res/level/sections.bin",$06AB,133

; The filler entries' lists: a 0 exit list and a 0 entry list each
;
; 6 bytes, two for each filler entry from 10 (the last one's two bytes are the
; first word of KindTable).
FillerSectionLists:
  INCBIN "res/level/sections.bin",$0730,6
