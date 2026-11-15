; --------------------------------------------------------------------------------------------------------------------
; sections.asm: The section table, the exit lists and the map entry lists
; --------------------------------------------------------------------------------------------------------------------

; 8 entries of 8 bytes: 8 sections
;
; LevelHeader+2 points here; SetupSection $8A6D reads entry A at SectionTable +
; 8A. +0/+1 the map's offset from Maps (big-endian); +2 0, read by no code; +3
; the scroll limit, the last ViewTop (cells, a multiple of 8) the scroll down
; may reach ($88D2); +4/+5 the exit list's offset from SectionTable
; (big-endian), into CheckSectionExit's LD IX,n; +6/+7 the map entry list's
; offset from SectionTable (big-endian), into SectionEntries $8B3E. The number
; of entries is not stored: SectionCounts $8374 says 8 for this level
; (ResetSectionObjects $8379 walks that many lists).
SectionTable:
  ; $ECED section 0: map +$0000, limit 104, exits +$0040, entries +$0045
  ; $ECF5 section 1: map +$0110, limit 8, exits +$0116, entries +$011B
  ; $ECFD section 2: map +$0160, limit 80, exits +$0170, entries +$0179
  ; $ED05 section 3: map +$0240, limit 32, exits +$0246, entries +$024B
  ; $ED0D section 4: map +$02B0, limit 8, exits +$02DC, entries +$02E1
  ; $ED15 section 5: map +$02E8, limit 16, exits +$0332, entries +$0337
  ; $ED1D section 6: map +$0340, limit 104, exits +$0398, entries +$03A1
  ; $ED25 section 7: map +$0440, limit 16, exits +$04CE, entries +$04D3
  INCBIN "res/level/sections.bin",$0000,64

; Section 0's exits: 1, then the 0 end
;
; 4 bytes an exit: +0 flags (bits 0-1 the side Rick leaves the view at: 1 left,
; 2 right; bit 4 ends the level even with CheatExits; bit 5 RideMode on the way
; in; bit 6 LevelHookOn = 20; bit 7 the level ends), +1 the section row of
; Rick's feet (ViewTop + (y + 20) / 8) at which it is taken, +2 the section
; entered, +3 the row of that section his feet arrive at (the new ViewTop = +3
; - his feet row in the view). A byte with bits 0, 1, 3 clear ends the list (a
; single 0). CheckSectionExit $8993 reads them.
Section0Exits:
  ; $ED2D flags $02: leaves at the right at row $2B -> section 1, row $1B
  ; $ED31 the end
  INCBIN "res/level/sections.bin",$0040,5

; Section 0's map entries: 31, then the 0 end
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
  ; $ED32 kind $06: trap, behaviour $10; row $0A, column 10; spawns on its
  ;   box, 1 box
  ; $ED36 trigger box: x 40, row $10, 16 x 4 cells, set off by Rick, every
  ;   pass
  ; $ED3A kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $11, column 16; spawns in view
  ; $ED3E kind $0F: trap, behaviour $08; row $12, column 20 +4 px; spawns
  ;   in view, 1 box
  ; $ED42 trigger box: x 144, row $10, 6 x 4 cells, set off by blast
  ; $ED46 kind $01: detonators pickup; row $15, column 25, y +3 px; spawns
  ;   in view, 1 box
  ; $ED4A trigger box: x 200, row $15, 3 x 3 cells, set off by Rick
  ; $ED4E kind $10: trap, behaviour $00; row $19, column 20; spawns on its
  ;   box, 1 box
  ; $ED52 trigger box: x 160, row $1A, 2 x 2 cells, set off by Rick
  ; $ED56 kind $03: trap, behaviour $10; row $1A, column 12 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $ED5A trigger box: x 40, row $1C, 10 x 8 cells, set off by Rick, every
  ;   pass
  ; $ED5E kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $21, column 4; spawns in view, one-shot
  ; $ED62 kind $11: trap, behaviour $00; row $21, column 20; spawns in view
  ; $ED66 kind $0C: trap, behaviour $00; row $26, column 18; spawns on its
  ;   box, 1 box
  ; $ED6A trigger box: x 128, row $35, 4 x 3 cells, set off by Rick
  ; $ED6E kind $7C: the countdown bonus stops and pays; row $29, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $ED72 trigger box: x 232, row $28, 3 x 4 cells, set off by Rick
  ; $ED76 kind $0C: trap, behaviour $00; row $2A, column 14; spawns on its
  ;   box, 1 box
  ; $ED7A trigger box: x 128, row $35, 4 x 3 cells, set off by Rick
  ; $ED7E kind $01: ammunition pickup; row $31, column 15, y +3 px; spawns
  ;   in view, 1 box
  ; $ED82 trigger box: x 120, row $31, 3 x 3 cells, set off by Rick
  ; $ED86 kind $7D: enemy patrols (sprite set 1), patrol 48 px; row $39,
  ;   column 8; spawns in view
  ; $ED8A kind $24: trap, behaviour $18; row $3C, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $ED8E trigger box: x 128, row $42, 1 x 2 cells, set off by punch
  ; $ED92 kind $76: enemy chases (sprite set 1), patrol 8 px; row $41,
  ;   column 13; spawns in view
  ; $ED96 kind $76: enemy chases (sprite set 1), patrol 8 px; row $41,
  ;   column 9; spawns in view
  ; $ED9A kind $0A: trap, behaviour $08; row $44, column 4; spawns in view,
  ;   1 box
  ; $ED9E trigger box: x 88, row $38, 1 x 4 cells, set off by Rick
  ; $EDA2 kind $09: trap, behaviour $08; row $48, column 24; spawns in
  ;   view, 1 box
  ; $EDA6 trigger box: x 208, row $47, 1 x 1 cells, set off by Rick
  ; $EDAA kind $7E: enemy chases (sprite set 1), patrol 8 px; row $49,
  ;   column 21; spawns in view
  ; $EDAE kind $01: treasure pickup; row $49, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EDB2 trigger box: x 168, row $49, 3 x 3 cells, set off by Rick
  ; $EDB6 kind $08: trap, behaviour $08; row $4A, column 9 +4 px; spawns in
  ;   view, 1 box
  ; $EDBA trigger box: x 72, row $50, 1 x 4 cells, set off by Rick
  ; $EDBE kind $06: trap, behaviour $10; row $56, column 14; spawns on its
  ;   box, 1 box
  ; $EDC2 trigger box: x 96, row $5C, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $EDC6 kind $07: trap, behaviour $10; row $56, column 20; spawns on its
  ;   box, 1 box
  ; $EDCA trigger box: x 96, row $5C, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $EDCE kind $78: the countdown bonus starts; row $5D, column 4; spawns
  ;   on its box, 1 box
  ; $EDD2 trigger box: x 32, row $5A, 5 x 6 cells, set off by Rick
  ; $EDD6 kind $0B: trap, behaviour $0C; row $65, column 18, y +3 px;
  ;   spawns in view, 1 box
  ; $EDDA trigger box: x 24, row $6A, 1 x 2 cells, set off by punch
  ; $EDDE kind $01: treasure pickup; row $69, column 4, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EDE2 trigger box: x 32, row $69, 3 x 3 cells, set off by Rick
  ; $EDE6 kind $05: trap, behaviour $00; row $6A, column 4, y +3 px; spawns
  ;   in view
  ; $EDEA kind $03: trap, behaviour $10; row $6A, column 24 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $EDEE trigger box: x 160, row $6C, 8 x 6 cells, set off by Rick, every
  ;   pass
  ; $EDF2 kind $76: enemy chases (sprite set 1), patrol 8 px; row $75,
  ;   column 12; spawns in view
  ; $EDF6 kind $76: enemy chases (sprite set 1), patrol 8 px; row $75,
  ;   column 14; spawns in view
  ; $EDFA kind $02: trap, behaviour $24; row $78, column 17; spawns in
  ;   view, 1 box
  ; $EDFE trigger box: x 128, row $76, 5 x 2 cells, set off by blast
  ; $EE02 the end
  INCBIN "res/level/sections.bin",$0045,209

; Section 1's exits: 1, then the 0 end
Section1Exits:
  ; $EE03 flags $22: leaves at the right at row $1B -> section 2, row $1B;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EE07 the end
  INCBIN "res/level/sections.bin",$0116,5

; Section 1's map entries: 12, then the 0 end
Section1Objects:
  ; $EE08 kind $13: trap, behaviour $18; row $0D, column 23; spawns in
  ;   view, one-shot, 1 box
  ; $EE0C trigger box: x 168, row $12, 5 x 2 cells, set off by blast
  ; $EE10 kind $12: trap, behaviour $0C; row $10, column 17; spawns in
  ;   view, one-shot, 1 box
  ; $EE14 trigger box: x 168, row $12, 5 x 2 cells, set off by blast
  ; $EE18 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $11, column 12; spawns in view
  ; $EE1C kind $2C: trap, behaviour $0C; row $11, column 22 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EE20 trigger box: x 168, row $12, 5 x 2 cells, set off by blast
  ; $EE24 kind $27: trap, behaviour $10; row $11, column 22; spawns on its
  ;   box, one-shot, 1 box
  ; $EE28 trigger box: x 168, row $12, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EE2C kind $28: trap, behaviour $10; row $11, column 22; spawns on its
  ;   box, one-shot, 1 box
  ; $EE30 trigger box: x 168, row $12, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EE34 kind $29: trap, behaviour $10; row $11, column 22; spawns on its
  ;   box, one-shot, 1 box
  ; $EE38 trigger box: x 168, row $12, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EE3C kind $2A: trap, behaviour $10; row $11, column 22; spawns on its
  ;   box, one-shot, 1 box
  ; $EE40 trigger box: x 168, row $12, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EE44 kind $2B: trap, behaviour $10; row $11, column 22; spawns on its
  ;   box, one-shot, 1 box
  ; $EE48 trigger box: x 168, row $12, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EE4C kind $12: trap, behaviour $0C; row $18, column 29; spawns in
  ;   view, one-shot, 1 box
  ; $EE50 trigger box: x 168, row $12, 5 x 2 cells, set off by blast
  ; $EE54 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $19,
  ;   column 6; spawns in view
  ; $EE58 kind $76: enemy chases (sprite set 1), patrol 8 px; row $19,
  ;   column 22; spawns in view
  ; $EE5C the end
  INCBIN "res/level/sections.bin",$011B,85

; Section 2's exits: 2, then the 0 end
Section2Exits:
  ; $EE5D flags $01: leaves at the left at row $47 -> section 3, row $17
  ; $EE61 flags $02: leaves at the right at row $63 -> section 4, row $1B
  ; $EE65 the end
  INCBIN "res/level/sections.bin",$0170,9

; Section 2's map entries: 26, then the 0 end
Section2Objects:
  ; $EE66 kind $01: treasure pickup; row $0D, column 4 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EE6A trigger box: x 32, row $0D, 3 x 3 cells, set off by Rick
  ; $EE6E kind $16: trap, behaviour $10; row $0E, column 17 +4 px; spawns
  ;   on its box, 1 box
  ; $EE72 trigger box: x 96, row $10, 10 x 4 cells, set off by Rick, every
  ;   pass
  ; $EE76 kind $06: trap, behaviour $10; row $0E, column 18; spawns on its
  ;   box, 1 box
  ; $EE7A trigger box: x 136, row $0D, 11 x 15 cells, set off by Rick,
  ;   every pass
  ; $EE7E kind $78: the countdown bonus starts; row $10, column 13; spawns
  ;   on its box, 1 box
  ; $EE82 trigger box: x 104, row $10, 1 x 4 cells, set off by Rick
  ; $EE86 kind $14: trap, behaviour $10; row $12, column 6; spawns on its
  ;   box, 1 box
  ; $EE8A trigger box: x 16, row $10, 12 x 12 cells, set off by Rick, every
  ;   pass
  ; $EE8E kind $17: trap, behaviour $10; row $16, column 28; spawns on its
  ;   box, 1 box
  ; $EE92 trigger box: x 160, row $0D, 8 x 16 cells, set off by Rick, every
  ;   pass
  ; $EE96 kind $15: trap, behaviour $10; row $1C, column 8; spawns on its
  ;   box, 1 box
  ; $EE9A trigger box: x 16, row $14, 10 x 8 cells, set off by Rick, every
  ;   pass
  ; $EE9E kind $14: trap, behaviour $10; row $1E, column 18; spawns on its
  ;   box, 2 boxes
  ; $EEA2 trigger box: x 192, row $1F, 4 x 1 cells, set off by Rick
  ; $EEA6 trigger box: x 56, row $24, 4 x 1 cells, set off by trap
  ; $EEAA kind $17: trap, behaviour $10; row $1E, column 20; spawns on its
  ;   box, 1 box
  ; $EEAE trigger box: x 168, row $24, 4 x 1 cells, set off by trap
  ; $EEB2 kind $14: trap, behaviour $10; row $1E, column 10; spawns on its
  ;   box, 2 boxes
  ; $EEB6 trigger box: x 112, row $24, 3 x 1 cells, set off by trap
  ; $EEBA trigger box: x 192, row $1F, 4 x 1 cells, set off by Rick
  ; $EEBE kind $17: trap, behaviour $10; row $1E, column 12; spawns on its
  ;   box, 1 box
  ; $EEC2 trigger box: x 104, row $24, 2 x 1 cells, set off by trap
  ; $EEC6 kind $18: trap, behaviour $08; row $28, column 10; spawns in
  ;   view, 1 box
  ; $EECA trigger box: x 32, row $28, 4 x 1 cells, set off by Rick
  ; $EECE kind $18: trap, behaviour $08; row $28, column 16; spawns in
  ;   view, 1 box
  ; $EED2 trigger box: x 80, row $30, 4 x 1 cells, set off by trap
  ; $EED6 kind $0D: trap, behaviour $00; row $28, column 10; spawns on its
  ;   box, 1 box
  ; $EEDA trigger box: x 80, row $28, 3 x 3 cells, set off by Rick
  ; $EEDE kind $19: trap, behaviour $10; row $39, column 2, y +3 px; spawns
  ;   on its box, 2 boxes
  ; $EEE2 trigger box: x 88, row $36, 16 x 9 cells, set off by Rick, every
  ;   pass
  ; $EEE6 trigger box: x 32, row $38, 9 x 8 cells, set off by Rick, every
  ;   pass
  ; $EEEA kind $2D: trap, behaviour $00; row $3E, column 16 +4 px; spawns
  ;   on its box, 1 box
  ; $EEEE trigger box: x 128, row $3D, 4 x 2 cells, set off by Rick
  ; $EEF2 kind $1C: trap, behaviour $08; row $44, column 2, y +3 px; spawns
  ;   in view, 1 box
  ; $EEF6 trigger box: x 40, row $44, 1 x 4 cells, set off by bullet
  ; $EEFA kind $7C: the countdown bonus stops and pays; row $45, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $EEFE trigger box: x 0, row $44, 3 x 4 cells, set off by Rick
  ; $EF02 kind $1A: trap, behaviour $10; row $49, column 6, y +3 px; spawns
  ;   on its box, 1 box
  ; $EF06 trigger box: x 56, row $44, 16 x 8 cells, set off by Rick, every
  ;   pass
  ; $EF0A kind $1B: trap, behaviour $10; row $49, column 23, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF0E trigger box: x 56, row $44, 16 x 8 cells, set off by Rick, every
  ;   pass
  ; $EF12 kind $01: ammunition pickup; row $49, column 15, y +3 px; spawns
  ;   in view, 1 box
  ; $EF16 trigger box: x 120, row $49, 3 x 3 cells, set off by Rick
  ; $EF1A kind $05: trap, behaviour $00; row $56, column 4, y +3 px; spawns
  ;   in view
  ; $EF1E kind $1F: trap, behaviour $00; row $56, column 26, y +3 px;
  ;   spawns in view
  ; $EF22 kind $20: trap, behaviour $10; row $5D, column 1; spawns on its
  ;   box, 1 box
  ; $EF26 trigger box: x 128, row $5E, 1 x 2 cells, set off by punch
  ; $EF2A kind $1E: trap, behaviour $00; row $62, column 10, y +3 px;
  ;   spawns in view
  ; $EF2E kind $1F: trap, behaviour $00; row $62, column 27, y +3 px;
  ;   spawns in view
  ; $EF32 the end
  INCBIN "res/level/sections.bin",$0179,205

; Section 3's exits: 1, then the 0 end
Section3Exits:
  ; $EF33 flags $02: leaves at the right at row $33 -> section 2, row $63
  ; $EF37 the end
  INCBIN "res/level/sections.bin",$0246,5

; Section 3's map entries: 21, then the 0 end
Section3Objects:
  ; $EF38 kind $13: trap, behaviour $18; row $0D, column 15; spawns in
  ;   view, one-shot, 1 box
  ; $EF3C trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $EF40 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $15,
  ;   column 20; spawns in view
  ; $EF44 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $15,
  ;   column 8; spawns in view
  ; $EF48 kind $2C: trap, behaviour $0C; row $15, column 14 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EF4C trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $EF50 kind $10: trap, behaviour $0C; row $15, column 4; spawns in view,
  ;   one-shot, 1 box
  ; $EF54 trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $EF58 kind $27: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EF5C trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EF60 kind $28: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EF64 trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EF68 kind $29: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EF6C trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EF70 kind $2A: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EF74 trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EF78 kind $2B: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EF7C trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EF80 kind $1D: trap, behaviour $00; row $26, column 4, y +3 px; spawns
  ;   in view
  ; $EF84 kind $13: trap, behaviour $18; row $2D, column 7; spawns in view,
  ;   one-shot, 1 box
  ; $EF88 trigger box: x 40, row $32, 5 x 2 cells, set off by blast
  ; $EF8C kind $12: trap, behaviour $0C; row $30, column 13; spawns in
  ;   view, one-shot, 1 box
  ; $EF90 trigger box: x 40, row $32, 5 x 2 cells, set off by blast
  ; $EF94 kind $12: trap, behaviour $0C; row $30, column 29; spawns in
  ;   view, one-shot, 1 box
  ; $EF98 trigger box: x 40, row $32, 5 x 2 cells, set off by blast
  ; $EF9C kind $2C: trap, behaviour $0C; row $31, column 6 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EFA0 trigger box: x 40, row $32, 5 x 2 cells, set off by blast
  ; $EFA4 kind $27: trap, behaviour $10; row $31, column 6; spawns on its
  ;   box, one-shot, 1 box
  ; $EFA8 trigger box: x 40, row $32, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EFAC kind $28: trap, behaviour $10; row $31, column 6; spawns on its
  ;   box, one-shot, 1 box
  ; $EFB0 trigger box: x 40, row $32, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EFB4 kind $2B: trap, behaviour $10; row $31, column 6; spawns on its
  ;   box, one-shot, 1 box
  ; $EFB8 trigger box: x 40, row $32, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EFBC kind $75: enemy patrols (sprite set 1), patrol 24 px; row $31,
  ;   column 4; spawns in view
  ; $EFC0 kind $76: enemy chases (sprite set 1), patrol 8 px; row $31,
  ;   column 20; spawns in view
  ; $EFC4 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $31, column 16; spawns in view
  ; $EFC8 the end
  INCBIN "res/level/sections.bin",$024B,145

; Section 4's exits: 1, then the 0 end
Section4Exits:
  ; $EFC9 flags $02: leaves at the right at row $1B -> section 6, row $73
  ; $EFCD the end
  INCBIN "res/level/sections.bin",$02DC,5

; Section 4's map entries: 12, then the 0 end
Section4Objects:
  ; $EFCE kind $2E: trap, behaviour $18; row $0C, column 17; spawns in
  ;   view, one-shot, 1 box
  ; $EFD2 trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $EFD6 kind $13: trap, behaviour $18; row $0D, column 10; spawns in
  ;   view, one-shot, 1 box
  ; $EFDA trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $EFDE kind $2C: trap, behaviour $0C; row $15, column 14 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EFE2 trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $EFE6 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $15,
  ;   column 12; spawns in view
  ; $EFEA kind $7E: enemy chases (sprite set 1), patrol 8 px; row $15,
  ;   column 25; spawns in view
  ; $EFEE kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 4; spawns in view
  ; $EFF2 kind $27: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EFF6 trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $EFFA kind $28: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $EFFE trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F002 kind $29: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F006 trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F00A kind $2B: trap, behaviour $10; row $15, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F00E trigger box: x 104, row $16, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F012 kind $12: trap, behaviour $0C; row $18, column 29; spawns in
  ;   view, one-shot, 1 box
  ; $F016 trigger box: x 104, row $16, 5 x 2 cells, set off by blast
  ; $F01A kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $19, column 23; spawns in view
  ; $F01E the end
  INCBIN "res/level/sections.bin",$02E1,81

; Section 5's exits: 1, then the 0 end
Section5Exits:
  ; $F01F flags $02: leaves at the right at row $17 -> section 6, row $37
  ; $F023 the end
  INCBIN "res/level/sections.bin",$0332,5

; Section 5's map entries: 14, then the 0 end
Section5Objects:
  ; $F024 kind $2E: trap, behaviour $18; row $11, column 14; spawns in
  ;   view, one-shot, 1 box
  ; $F028 trigger box: x 104, row $1A, 5 x 2 cells, set off by blast
  ; $F02C kind $12: trap, behaviour $0C; row $14, column 29; spawns in
  ;   view, one-shot, 1 box
  ; $F030 trigger box: x 104, row $1A, 5 x 2 cells, set off by blast
  ; $F034 kind $78: the countdown bonus starts; row $14, column 4; spawns
  ;   on its box, 1 box
  ; $F038 trigger box: x 32, row $16, 4 x 2 cells, set off by Rick
  ; $F03C kind $7C: the countdown bonus stops and pays; row $14, column 24;
  ;   spawns on its box, one-shot, 1 box
  ; $F040 trigger box: x 192, row $16, 4 x 2 cells, set off by Rick
  ; $F044 kind $2C: trap, behaviour $0C; row $19, column 14 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F048 trigger box: x 104, row $1A, 5 x 2 cells, set off by blast
  ; $F04C kind $75: enemy patrols (sprite set 1), patrol 24 px; row $19,
  ;   column 12; spawns in view
  ; $F050 kind $27: trap, behaviour $10; row $19, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F054 trigger box: x 104, row $1A, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F058 kind $28: trap, behaviour $10; row $19, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F05C trigger box: x 104, row $1A, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F060 kind $29: trap, behaviour $10; row $19, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F064 trigger box: x 104, row $1A, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F068 kind $2A: trap, behaviour $10; row $19, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F06C trigger box: x 104, row $1A, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F070 kind $2B: trap, behaviour $10; row $19, column 14; spawns on its
  ;   box, one-shot, 1 box
  ; $F074 trigger box: x 104, row $1A, 5 x 2 cells, set off by blast, every
  ;   pass
  ; $F078 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $19, column 4; spawns in view
  ; $F07C kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $19, column 25; spawns in view
  ; $F080 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $1D,
  ;   column 19; spawns in view
  ; $F084 the end
  INCBIN "res/level/sections.bin",$0337,97

; Section 6's exits: 2, then the 0 end
Section6Exits:
  ; $F085 flags $42: leaves at the right at row $17 -> section 7, row $1F;
  ;   bit 6: LevelHookOn = 20 (the Fat Guy)
  ; $F089 flags $01: leaves at the left at row $3F -> section 5, row $1F
  ; $F08D the end
  INCBIN "res/level/sections.bin",$0398,9

; Section 6's map entries: 41, then the 0 end
Section6Objects:
  ; $F08E kind $7D: enemy patrols (sprite set 1), patrol 56 px; row $0D,
  ;   column 4; spawns in view
  ; $F092 kind $01: ammunition pickup; row $0D, column 16, y +3 px; spawns
  ;   in view, 1 box
  ; $F096 trigger box: x 128, row $0D, 3 x 3 cells, set off by Rick
  ; $F09A kind $01: detonators pickup; row $0D, column 17, y +3 px; spawns
  ;   in view, 1 box
  ; $F09E trigger box: x 136, row $0D, 3 x 3 cells, set off by Rick
  ; $F0A2 kind $33: trap, behaviour $10; row $10, column 18; spawns on its
  ;   box, 1 box
  ; $F0A6 trigger box: x 80, row $0C, 11 x 4 cells, set off by Rick, every
  ;   pass
  ; $F0AA kind $32: trap, behaviour $10; row $15, column 15, y +3 px;
  ;   spawns on its box, 1 box
  ; $F0AE trigger box: x 24, row $14, 6 x 6 cells, set off by Rick, every
  ;   pass
  ; $F0B2 kind $34: trap, behaviour $18; row $15, column 24 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F0B6 trigger box: x 120, row $0C, 1 x 4 cells, set off by Rick
  ; $F0BA kind $7C: the countdown bonus stops and pays; row $15, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F0BE trigger box: x 232, row $14, 3 x 4 cells, set off by Rick
  ; $F0C2 kind $31: trap, behaviour $10; row $16, column 16; spawns on its
  ;   box, 2 boxes
  ; $F0C6 trigger box: x 32, row $22, 8 x 2 cells, set off by Rick, every
  ;   pass
  ; $F0CA trigger box: x 32, row $1D, 4 x 7 cells, set off by Rick, every
  ;   pass
  ; $F0CE kind $17: trap, behaviour $10; row $1A, column 16; spawns on its
  ;   box, 1 box
  ; $F0D2 trigger box: x 96, row $1C, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $F0D6 kind $0B: trap, behaviour $0C; row $25, column 14, y +3 px;
  ;   spawns in view, 1 box
  ; $F0DA trigger box: x 224, row $31, 1 x 2 cells, set off by punch
  ; $F0DE kind $26: trap, behaviour $24; row $29, column 2; spawns in view,
  ;   1 box
  ; $F0E2 trigger box: x 32, row $2A, 3 x 2 cells, set off by blast
  ; $F0E6 kind $35: trap, behaviour $1C; row $30, column 20 +4 px; spawns
  ;   on its box, 2 boxes
  ; $F0EA trigger box: x 128, row $28, 4 x 12 cells, set off by Rick, every
  ;   pass
  ; $F0EE trigger box: x 160, row $28, 8 x 7 cells, set off by Rick, every
  ;   pass
  ; $F0F2 kind $30: trap, behaviour $10; row $32, column 3, y +3 px; spawns
  ;   on its box, 1 box
  ; $F0F6 trigger box: x 16, row $34, 6 x 4 cells, set off by Rick, every
  ;   pass
  ; $F0FA kind $78: the countdown bonus starts; row $34, column 6; spawns
  ;   on its box, 1 box
  ; $F0FE trigger box: x 48, row $34, 2 x 4 cells, set off by Rick
  ; $F102 kind $1F: trap, behaviour $00; row $36, column 22, y +3 px;
  ;   spawns in view
  ; $F106 kind $2F: trap, behaviour $10; row $37, column 3, y +3 px; spawns
  ;   on its box, 1 box
  ; $F10A trigger box: x 16, row $34, 6 x 4 cells, set off by Rick, every
  ;   pass
  ; $F10E kind $2F: trap, behaviour $10; row $37, column 9, y +3 px; spawns
  ;   on its box, 1 box
  ; $F112 trigger box: x 48, row $31, 8 x 7 cells, set off by Rick, every
  ;   pass
  ; $F116 kind $30: trap, behaviour $10; row $3A, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $F11A trigger box: x 0, row $3C, 4 x 4 cells, set off by Rick, every
  ;   pass
  ; $F11E kind $75: enemy patrols (sprite set 1), patrol 16 px; row $3D,
  ;   column 14; spawns in view
  ; $F122 kind $01: detonators pickup; row $3D, column 6, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F126 trigger box: x 48, row $3D, 3 x 3 cells, set off by Rick
  ; $F12A kind $2F: trap, behaviour $10; row $3F, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $F12E trigger box: x 0, row $3C, 4 x 4 cells, set off by Rick, every
  ;   pass
  ; $F132 kind $75: enemy patrols (sprite set 1), patrol 8 px; row $45,
  ;   column 20; spawns in view
  ; $F136 kind $22: trap, behaviour $1C; row $48, column 12; spawns on its
  ;   box, 1 box
  ; $F13A trigger box: x 96, row $47, 3 x 1 cells, set off by Rick, every
  ;   pass
  ; $F13E kind $22: trap, behaviour $1C; row $48, column 16; spawns on its
  ;   box, 1 box
  ; $F142 trigger box: x 128, row $47, 3 x 1 cells, set off by Rick, every
  ;   pass
  ; $F146 kind $01: ammunition pickup; row $4D, column 20, y +3 px; spawns
  ;   in view, 1 box
  ; $F14A trigger box: x 160, row $4D, 3 x 3 cells, set off by Rick
  ; $F14E kind $36: trap, behaviour $04; row $50, column 8; spawns on its
  ;   box, 1 box
  ; $F152 trigger box: x 64, row $4F, 1 x 1 cells, set off by Rick
  ; $F156 kind $30: trap, behaviour $10; row $52, column 10, y +3 px;
  ;   spawns on its box, 1 box
  ; $F15A trigger box: x 64, row $54, 8 x 4 cells, set off by Rick, every
  ;   pass
  ; $F15E kind $30: trap, behaviour $10; row $52, column 18, y +3 px;
  ;   spawns on its box, 1 box
  ; $F162 trigger box: x 120, row $54, 8 x 4 cells, set off by Rick, every
  ;   pass
  ; $F166 kind $2F: trap, behaviour $10; row $57, column 10, y +3 px;
  ;   spawns on its box, 1 box
  ; $F16A trigger box: x 64, row $54, 8 x 4 cells, set off by Rick, every
  ;   pass
  ; $F16E kind $2F: trap, behaviour $10; row $57, column 18, y +3 px;
  ;   spawns on its box, 1 box
  ; $F172 trigger box: x 120, row $54, 8 x 4 cells, set off by Rick, every
  ;   pass
  ; $F176 kind $30: trap, behaviour $10; row $5A, column 14, y +3 px;
  ;   spawns on its box, 1 box
  ; $F17A trigger box: x 64, row $5C, 15 x 4 cells, set off by Rick, every
  ;   pass
  ; $F17E kind $09: trap, behaviour $08; row $5D, column 24; spawns in
  ;   view, 1 box
  ; $F182 trigger box: x 208, row $5C, 1 x 1 cells, set off by Rick
  ; $F186 kind $2F: trap, behaviour $10; row $5F, column 18, y +3 px;
  ;   spawns on its box, 1 box
  ; $F18A trigger box: x 64, row $5C, 15 x 4 cells, set off by Rick, every
  ;   pass
  ; $F18E kind $2F: trap, behaviour $10; row $5F, column 10, y +3 px;
  ;   spawns on its box, 1 box
  ; $F192 trigger box: x 64, row $5C, 15 x 4 cells, set off by Rick, every
  ;   pass
  ; $F196 kind $1F: trap, behaviour $00; row $6A, column 17, y +3 px;
  ;   spawns in view
  ; $F19A kind $09: trap, behaviour $08; row $6D, column 4; spawns in view,
  ;   1 box
  ; $F19E trigger box: x 32, row $6B, 1 x 1 cells, set off by Rick
  ; $F1A2 kind $22: trap, behaviour $00; row $6F, column 24; spawns in view
  ; $F1A6 kind $76: enemy chases (sprite set 1), patrol 8 px; row $77,
  ;   column 12; spawns in view
  ; $F1AA kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $79,
  ;   column 16; spawns in view
  ; $F1AE kind $21: trap, behaviour $00; row $7A, column 13; spawns in view
  ; $F1B2 kind $0A: trap, behaviour $08; row $7C, column 24; spawns in
  ;   view, 1 box
  ; $F1B6 trigger box: x 208, row $7B, 1 x 1 cells, set off by Rick
  ; $F1BA the end
  INCBIN "res/level/sections.bin",$03A1,301

; Section 7's exits: 1, then the 0 end
Section7Exits:
  ; $F1BB flags $92: leaves at the right at row $1B -> section 0, row $1B;
  ;   bit 7 + bit 4: ends the level (also with CheatExits)
  ; $F1BF the end
  INCBIN "res/level/sections.bin",$04CE,5

; Section 7's map entries: 1, then the 0 end
Section7Objects:
  ; $F1C0 kind $01: trap, behaviour $1C; row $24, column 25; spawns on its
  ;   box, 2 boxes
  ; $F1C4 trigger box: x 0, row $19, 16 x 11 cells, set off by Rick, every
  ;   pass
  ; $F1C8 trigger box: x 128, row $16, 16 x 14 cells, set off by Rick,
  ;   every pass
  INCBIN "res/level/sections.bin",$04D3,11
