; --------------------------------------------------------------------------------------------------------------------
; sections.asm: The section table, the exit lists and the map entry lists
; --------------------------------------------------------------------------------------------------------------------

; 17 entries of 8 bytes: 8 sections and 9 filler entries
;
; LevelHeader+2 points here; SetupSection $8A6D reads entry A at SectionTable +
; 8A. +0/+1 the map's offset from Maps (big-endian); +2 0, read by no code; +3
; the scroll limit, the last ViewTop (cells, a multiple of 8) the scroll down
; may reach ($88D2); +4/+5 the exit list's offset from SectionTable
; (big-endian), into CheckSectionExit's LD IX,n; +6/+7 the map entry list's
; offset from SectionTable (big-endian), into SectionEntries $8B3E. The number
; of entries is not stored: SectionCounts $8374 says 9 for this level
; (ResetSectionObjects $8379 walks that many lists).
;
; The filler entries (8, 9, 10, 11, 12, 13, 14, 15, 16) have map offset 0
; (section 0's map), limit 0 and empty lists (two zero bytes each; the last
; entry's lists are the 0 word KindTable starts with). Only the first of them
; is inside SectionCounts (section 8); the lead's recording sec-l1-s8 set it
; up: an empty screen of section 0's map.
SectionTable:
  ; $ED6D section 0: map +$0000, limit 0, exits +$0088, entries +$008D
  ; $ED75 section 1: map +$0040, limit 112, exits +$00C2, entries +$00CB
  ; $ED7D section 2: map +$0130, limit 112, exits +$0198, entries +$01B1
  ; $ED85 section 3: map +$0270, limit 0, exits +$026E, entries +$0273
  ; $ED8D section 4: map +$02B0, limit 104, exits +$028C, entries +$0299
  ; $ED95 section 5: map +$03B0, limit 104, exits +$036A, entries +$0377
  ; $ED9D section 6: map +$04B0, limit 8, exits +$043C, entries +$0441
  ; $EDA5 section 7: map +$04F0, limit 8, exits +$0462, entries +$0467
  ; $EDAD filler entries 8-16
  INCBIN "res/level/sections.bin",$0000,136

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
  ; $EDF5 flags $02: leaves at the right at row $1E -> section 2, row $8E
  ; $EDF9 the end
  INCBIN "res/level/sections.bin",$0088,5

; Section 0's map entries: 6, then the 0 end
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
  ; $EDFA kind $0D: trap, behaviour $10; row $0F, column 17; spawns on its
  ;   box, 1 box
  ; $EDFE trigger box: x 96, row $1E, 3 x 1 cells, set off by trap
  ; $EE02 kind $0D: trap, behaviour $10; row $0F, column 21; spawns on its
  ;   box, 1 box
  ; $EE06 trigger box: x 128, row $1E, 3 x 1 cells, set off by trap
  ; $EE0A kind $0D: trap, behaviour $10; row $0F, column 25; spawns on its
  ;   box, 1 box
  ; $EE0E trigger box: x 160, row $1E, 3 x 1 cells, set off by trap
  ; $EE12 kind $0E: trap, behaviour $10; row $0F, column 5; spawns on its
  ;   box, 1 box
  ; $EE16 trigger box: x 168, row $19, 8 x 6 cells, set off by Rick
  ; $EE1A kind $0D: trap, behaviour $10; row $0F, column 13; spawns on its
  ;   box, 1 box
  ; $EE1E trigger box: x 64, row $1E, 3 x 1 cells, set off by trap
  ; $EE22 kind $0D: trap, behaviour $10; row $0F, column 9; spawns on its
  ;   box, 2 boxes
  ; $EE26 trigger box: x 96, row $18, 1 x 7 cells, set off by Rick
  ; $EE2A trigger box: x 192, row $1E, 3 x 1 cells, set off by trap
  ; $EE2E the end
  INCBIN "res/level/sections.bin",$008D,53

; Section 1's exits: 2, then the 0 end
Section1Exits:
  ; $EE2F flags $92: leaves at the right at row $17 -> section 0, row $17;
  ;   bit 7 + bit 4: ends the level (also with CheatExits)
  ; $EE33 flags $01: leaves at the left at row $83 -> section 4, row $1B
  ; $EE37 the end
  INCBIN "res/level/sections.bin",$00C2,9

; Section 1's map entries: 30, then the 0 end
Section1Objects:
  ; $EE38 kind $30: trap, behaviour $00; row $11, column 21 +4 px; spawns
  ;   on its box, 1 box
  ; $EE3C trigger box: x 32, row $18, 8 x 1 cells, set off by Rick
  ; $EE40 kind $7C: the countdown bonus stops and pays; row $15, column 28;
  ;   spawns on its box, one-shot, 1 box
  ; $EE44 trigger box: x 224, row $14, 4 x 4 cells, set off by Rick
  ; $EE48 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $1D, column 4; spawns in view
  ; $EE4C kind $2D: trap, behaviour $10; row $1D, column 3; spawns on its
  ;   box, 2 boxes
  ; $EE50 trigger box: x 64, row $1C, 4 x 1 cells, set off by Rick/enemy
  ; $EE54 trigger box: x 224, row $1E, 1 x 2 cells, set off by punch
  ; $EE58 kind $2C: trap, behaviour $14; row $21, column 26; spawns in
  ;   view, 1 box
  ; $EE5C trigger box: x 24, row $26, 1 x 2 cells, set off by punch
  ; $EE60 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $25,
  ;   column 16; spawns in view
  ; $EE64 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $29, column 25; spawns in view
  ; $EE68 kind $2B: trap, behaviour $24; row $2C, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $EE6C trigger box: x 24, row $2A, 1 x 2 cells, set off by punch
  ; $EE70 kind $0B: trap, behaviour $24; row $34, column 8 +4 px; spawns in
  ;   view, 1 box
  ; $EE74 trigger box: x 224, row $32, 1 x 2 cells, set off by punch
  ; $EE78 kind $1E: trap, behaviour $10; row $39, column 26; spawns on its
  ;   box, 1 box
  ; $EE7C trigger box: x 112, row $39, 3 x 3 cells, set off by Rick, every
  ;   pass
  ; $EE80 kind $15: ammunition pickup; row $3D, column 21, y +3 px; spawns
  ;   in view, 1 box
  ; $EE84 trigger box: x 168, row $3D, 3 x 3 cells, set off by Rick
  ; $EE88 kind $78: the countdown bonus starts; row $45, column 4; spawns
  ;   on its box, 1 box
  ; $EE8C trigger box: x 32, row $42, 4 x 6 cells, set off by Rick
  ; $EE90 kind $2A: trap, behaviour $00; row $46, column 9; spawns in view
  ; $EE94 kind $2A: trap, behaviour $00; row $46, column 12; spawns in view
  ; $EE98 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $4D,
  ;   column 8; spawns in view
  ; $EE9C kind $1E: trap, behaviour $10; row $51, column 26; spawns on its
  ;   box, 2 boxes
  ; $EEA0 trigger box: x 32, row $4F, 12 x 5 cells, set off by Rick, every
  ;   pass
  ; $EEA4 trigger box: x 160, row $54, 4 x 4 cells, set off by Rick, every
  ;   pass
  ; $EEA8 kind $16: detonators pickup; row $55, column 21, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EEAC trigger box: x 168, row $55, 3 x 3 cells, set off by Rick
  ; $EEB0 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $59,
  ;   column 17; spawns in view, one-shot
  ; $EEB4 kind $0C: trap, behaviour $04; row $5C, column 4; spawns in view,
  ;   1 box
  ; $EEB8 trigger box: x 24, row $5A, 1 x 2 cells, set off by punch
  ; $EEBC kind $17: trap, behaviour $14; row $62, column 16; spawns in
  ;   view, one-shot, 1 box
  ; $EEC0 trigger box: x 112, row $62, 2 x 2 cells, set off by blast
  ; $EEC4 kind $15: ammunition pickup; row $69, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EEC8 trigger box: x 200, row $69, 3 x 3 cells, set off by Rick
  ; $EECC kind $76: enemy chases (sprite set 1), patrol 8 px; row $6D,
  ;   column 16; spawns in view
  ; $EED0 kind $22: trap, behaviour $10; row $71, column 26; spawns on its
  ;   box, 1 box
  ; $EED4 trigger box: x 224, row $7A, 1 x 2 cells, set off by punch
  ; $EED8 kind $22: trap, behaviour $10; row $75, column 10; spawns on its
  ;   box, 1 box
  ; $EEDC trigger box: x 32, row $74, 2 x 4 cells, set off by Rick, every
  ;   pass
  ; $EEE0 kind $14: treasure pickup; row $75, column 4, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EEE4 trigger box: x 32, row $75, 3 x 3 cells, set off by Rick
  ; $EEE8 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $79, column 25; spawns in view
  ; $EEEC kind $2F: trap, behaviour $10; row $79, column 25, y +3 px;
  ;   spawns on its box, one-shot, 1 box
  ; $EEF0 trigger box: x 160, row $7E, 4 x 2 cells, set off by Rick
  ; $EEF4 kind $0A: trap, behaviour $24; row $80, column 8; spawns in view,
  ;   1 box
  ; $EEF8 trigger box: x 80, row $7C, 1 x 1 cells, set off by Rick
  ; $EEFC kind $7E: enemy chases (sprite set 1), patrol 8 px; row $81,
  ;   column 12; spawns in view
  ; $EF00 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $81,
  ;   column 25; spawns in view
  ; $EF04 the end
  INCBIN "res/level/sections.bin",$00CB,205

; Section 2's exits: 6, then the 0 end
Section2Exits:
  ; $EF05 flags $02: leaves at the right at row $17 -> section 5, row $17
  ; $EF09 flags $31: leaves at the left at row $4A -> section 0, row $4A;
  ;   bit 4 without bit 7: no effect; bit 5: RideMode $945D = $FF (Rick
  ;   rides)
  ; $EF0D flags $01: leaves at the left at row $67 -> section 4, row $77
  ; $EF11 flags $02: leaves at the right at row $73 -> section 5, row $7B
  ; $EF15 flags $01: leaves at the left at row $8E -> section 0, row $1E
  ; $EF19 flags $02: leaves at the right at row $8E -> section 3, row $1E
  ; $EF1D the end
  INCBIN "res/level/sections.bin",$0198,25

; Section 2's map entries: 28, then the 0 end
Section2Objects:
  ; $EF1E kind $1B: trap, behaviour $00; row $16, column 9; spawns in view
  ; $EF22 kind $1D: trap, behaviour $0C; row $1D, column 6; spawns in view,
  ;   one-shot, 1 box
  ; $EF26 trigger box: x 120, row $26, 1 x 2 cells, set off by punch
  ; $EF2A kind $7D: enemy patrols (sprite set 1), patrol 16 px; row $25,
  ;   column 16; spawns in view, one-shot
  ; $EF2E kind $04: trap, behaviour $24; row $28, column 24; spawns in
  ;   view, 1 box
  ; $EF32 trigger box: x 224, row $26, 1 x 2 cells, set off by punch
  ; $EF36 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $34,
  ;   column 14; spawns in view
  ; $EF3A kind $1A: trap, behaviour $10; row $3D, column 26; spawns on its
  ;   box, 1 box
  ; $EF3E trigger box: x 160, row $3C, 8 x 4 cells, set off by Rick, every
  ;   pass
  ; $EF42 kind $1C: trap, behaviour $0C; row $3D, column 3; spawns in view,
  ;   1 box
  ; $EF46 trigger box: x 24, row $3A, 1 x 2 cells, set off by punch
  ; $EF4A kind $15: ammunition pickup; row $3D, column 22, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EF4E trigger box: x 176, row $3D, 3 x 3 cells, set off by Rick
  ; $EF52 kind $78: the countdown bonus starts; row $3D, column 25; spawns
  ;   on its box, 1 box
  ; $EF56 trigger box: x 200, row $3C, 3 x 4 cells, set off by Rick
  ; $EF5A kind $29: trap, behaviour $08; row $48, column 4; spawns in view
  ; $EF5E kind $18: trap, behaviour $10; row $49, column 26; spawns on its
  ;   box, 1 box
  ; $EF62 trigger box: x 64, row $48, 16 x 4 cells, set off by Rick, every
  ;   pass
  ; $EF66 kind $1F: trap, behaviour $00; row $50, column 10; spawns on its
  ;   box, 1 box
  ; $EF6A trigger box: x 32, row $50, 4 x 4 cells, set off by Rick
  ; $EF6E kind $16: detonators pickup; row $51, column 4, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EF72 trigger box: x 32, row $51, 3 x 3 cells, set off by Rick
  ; $EF76 kind $76: enemy chases (sprite set 1), patrol 8 px; row $51,
  ;   column 10; spawns in view, one-shot
  ; $EF7A kind $1F: trap, behaviour $00; row $58, column 19; spawns in view
  ; $EF7E kind $26: trap, behaviour $08; row $5D, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $EF82 trigger box: x 152, row $56, 6 x 3 cells, set off by Rick
  ; $EF86 kind $7C: the countdown bonus stops and pays; row $64, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $EF8A trigger box: x 0, row $64, 3 x 4 cells, set off by Rick
  ; $EF8E kind $79: enemy patrols (sprite set 0), patrol 56 px; row $65,
  ;   column 4; spawns in view
  ; $EF92 kind $0F: trap, behaviour $14; row $65, column 0, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EF96 trigger box: x 24, row $66, 2 x 2 cells, set off by blast
  ; $EF9A kind $12: trap, behaviour $0C; row $6F, column 29; spawns in
  ;   view, one-shot, 1 box
  ; $EF9E trigger box: x 24, row $72, 1 x 2 cells, set off by punch
  ; $EFA2 kind $13: trap, behaviour $00; row $70, column 10; spawns in view
  ; $EFA6 kind $2E: trap, behaviour $10; row $71, column 4, y +3 px; spawns
  ;   on its box, one-shot, 1 box
  ; $EFAA trigger box: x 104, row $74, 2 x 2 cells, set off by Rick
  ; $EFAE kind $7C: the countdown bonus stops and pays; row $71, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $EFB2 trigger box: x 232, row $71, 3 x 3 cells, set off by Rick
  ; $EFB6 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $79, column 15; spawns in view, one-shot
  ; $EFBA kind $10: trap, behaviour $10; row $7F, column 5; spawns on its
  ;   box, 1 box
  ; $EFBE trigger box: x 136, row $88, 2 x 1 cells, set off by Rick
  ; $EFC2 kind $11: trap, behaviour $10; row $7F, column 24; spawns on its
  ;   box, 1 box
  ; $EFC6 trigger box: x 136, row $82, 2 x 1 cells, set off by Rick
  ; $EFCA kind $78: the countdown bonus starts; row $8C, column 4; spawns
  ;   on its box, 1 box
  ; $EFCE trigger box: x 32, row $8C, 3 x 3 cells, set off by Rick
  ; $EFD2 kind $0F: trap, behaviour $14; row $8C, column 28, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EFD6 trigger box: x 208, row $8D, 2 x 2 cells, set off by blast
  ; $EFDA the end
  INCBIN "res/level/sections.bin",$01B1,189

; Section 3's exits: 1, then the 0 end
Section3Exits:
  ; $EFDB flags $01: leaves at the left at row $1E -> section 2, row $8E
  ; $EFDF the end
  INCBIN "res/level/sections.bin",$026E,5

; Section 3's map entries: 3, then the 0 end
Section3Objects:
  ; $EFE0 kind $14: treasure pickup; row $1C, column 8, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFE4 trigger box: x 64, row $1C, 3 x 3 cells, set off by Rick
  ; $EFE8 kind $15: ammunition pickup; row $1C, column 15, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EFEC trigger box: x 120, row $1C, 3 x 3 cells, set off by Rick
  ; $EFF0 kind $16: detonators pickup; row $1C, column 22, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EFF4 trigger box: x 176, row $1C, 3 x 3 cells, set off by Rick
  ; $EFF8 the end
  INCBIN "res/level/sections.bin",$0273,25

; Section 4's exits: 3, then the 0 end
Section4Exits:
  ; $EFF9 flags $02: leaves at the right at row $1B -> section 1, row $83
  ; $EFFD flags $01: leaves at the left at row $73 -> section 7, row $1B
  ; $F001 flags $02: leaves at the right at row $77 -> section 2, row $67
  ; $F005 the end
  INCBIN "res/level/sections.bin",$028C,13

; Section 4's map entries: 28, then the 0 end
Section4Objects:
  ; $F006 kind $21: trap, behaviour $04; row $0D, column 22, y +3 px;
  ;   spawns in view, 1 box
  ; $F00A trigger box: x 96, row $08, 5 x 3 cells, set off by Rick
  ; $F00E kind $09: trap, behaviour $08; row $10, column 12; spawns in
  ;   view, 1 box
  ; $F012 trigger box: x 112, row $0F, 1 x 1 cells, set off by Rick
  ; $F016 kind $25: trap, behaviour $24; row $15, column 10; spawns in
  ;   view, 1 box
  ; $F01A trigger box: x 32, row $14, 12 x 4 cells, set off by Rick, every
  ;   pass
  ; $F01E kind $02: trap, behaviour $04; row $18, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $F022 trigger box: x 24, row $26, 1 x 2 cells, set off by punch
  ; $F026 kind $7C: the countdown bonus stops and pays; row $18, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F02A trigger box: x 232, row $18, 3 x 4 cells, set off by Rick
  ; $F02E kind $27: trap, behaviour $08; row $2D, column 22, y +3 px;
  ;   spawns in view, 1 box
  ; $F032 trigger box: x 112, row $2C, 1 x 4 cells, set off by Rick
  ; $F036 kind $7D: enemy patrols (sprite set 1), patrol 48 px; row $2D,
  ;   column 4; spawns in view, one-shot
  ; $F03A kind $23: trap, behaviour $10; row $37, column 17; spawns on its
  ;   box, 1 box
  ; $F03E trigger box: x 96, row $3B, 3 x 1 cells, set off by trap
  ; $F042 kind $23: trap, behaviour $10; row $37, column 21; spawns on its
  ;   box, 1 box
  ; $F046 trigger box: x 128, row $3B, 3 x 1 cells, set off by trap
  ; $F04A kind $23: trap, behaviour $10; row $37, column 25; spawns on its
  ;   box, 1 box
  ; $F04E trigger box: x 160, row $3B, 3 x 1 cells, set off by trap
  ; $F052 kind $23: trap, behaviour $10; row $37, column 29; spawns on its
  ;   box, 1 box
  ; $F056 trigger box: x 192, row $3B, 3 x 1 cells, set off by trap
  ; $F05A kind $23: trap, behaviour $10; row $37, column 13; spawns on its
  ;   box, 2 boxes
  ; $F05E trigger box: x 224, row $3D, 3 x 1 cells, set off by Rick
  ; $F062 trigger box: x 224, row $3B, 3 x 1 cells, set off by trap
  ; $F066 kind $78: the countdown bonus starts; row $40, column 16; spawns
  ;   on its box, 1 box
  ; $F06A trigger box: x 128, row $40, 4 x 4 cells, set off by Rick
  ; $F06E kind $08: trap, behaviour $08; row $44, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $F072 trigger box: x 160, row $42, 1 x 2 cells, set off by punch
  ; $F076 kind $31: trap, behaviour $18; row $46, column 20; spawns in
  ;   view, one-shot, 1 box
  ; $F07A trigger box: x 144, row $46, 2 x 2 cells, set off by blast
  ; $F07E kind $17: trap, behaviour $14; row $46, column 8; spawns in view,
  ;   one-shot, 1 box
  ; $F082 trigger box: x 48, row $46, 2 x 2 cells, set off by blast
  ; $F086 kind $07: trap, behaviour $00; row $48, column 28; spawns on its
  ;   box, 1 box
  ; $F08A trigger box: x 240, row $45, 1 x 1 cells, set off by Rick
  ; $F08E kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $4D, column 7; spawns in view
  ; $F092 kind $16: detonators pickup; row $4D, column 9, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F096 trigger box: x 72, row $4D, 3 x 3 cells, set off by Rick
  ; $F09A kind $25: trap, behaviour $24; row $55, column 18; spawns in
  ;   view, 1 box
  ; $F09E trigger box: x 112, row $54, 9 x 4 cells, set off by Rick, every
  ;   pass
  ; $F0A2 kind $01: trap, behaviour $08; row $5A, column 24 +4 px; spawns
  ;   in view, 1 box
  ; $F0A6 trigger box: x 24, row $62, 1 x 2 cells, set off by punch
  ; $F0AA kind $12: trap, behaviour $10; row $5F, column 13; spawns on its
  ;   box, 1 box
  ; $F0AE trigger box: x 128, row $60, 1 x 4 cells, set off by Rick
  ; $F0B2 kind $1E: trap, behaviour $10; row $61, column 26; spawns on its
  ;   box, 1 box
  ; $F0B6 trigger box: x 128, row $60, 5 x 4 cells, set off by Rick, every
  ;   pass
  ; $F0BA kind $01: trap, behaviour $08; row $64, column 4; spawns in view,
  ;   1 box
  ; $F0BE trigger box: x 96, row $6C, 4 x 1 cells, set off by Rick
  ; $F0C2 kind $75: enemy patrols (sprite set 1), patrol 56 px; row $69,
  ;   column 8; spawns in view
  ; $F0C6 kind $0F: trap, behaviour $14; row $71, column 0, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F0CA trigger box: x 24, row $72, 2 x 2 cells, set off by blast
  ; $F0CE kind $06: trap, behaviour $00; row $75, column 8; spawns in view
  ; $F0D2 kind $05: trap, behaviour $00; row $75, column 24; spawns in view
  ; $F0D6 the end
  INCBIN "res/level/sections.bin",$0299,209

; Section 5's exits: 3, then the 0 end
Section5Exits:
  ; $F0D7 flags $01: leaves at the left at row $17 -> section 2, row $17
  ; $F0DB flags $02: leaves at the right at row $47 -> section 6, row $17
  ; $F0DF flags $01: leaves at the left at row $7B -> section 2, row $73
  ; $F0E3 the end
  INCBIN "res/level/sections.bin",$036A,13

; Section 5's map entries: 28, then the 0 end
Section5Objects:
  ; $F0E4 kind $03: trap, behaviour $24; row $11, column 25; spawns in
  ;   view, 1 box
  ; $F0E8 trigger box: x 224, row $0E, 1 x 3 cells, set off by punch
  ; $F0EC kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 0; spawns in view, one-shot
  ; $F0F0 kind $28: trap, behaviour $14; row $15, column 26; spawns in
  ;   view, 1 box
  ; $F0F4 trigger box: x 224, row $1E, 1 x 2 cells, set off by punch
  ; $F0F8 kind $7C: the countdown bonus stops and pays; row $15, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $F0FC trigger box: x 0, row $14, 3 x 4 cells, set off by Rick
  ; $F100 kind $19: trap, behaviour $10; row $19, column 15; spawns on its
  ;   box, 1 box
  ; $F104 trigger box: x 128, row $19, 1 x 2 cells, set off by trap
  ; $F108 kind $1A: trap, behaviour $10; row $19, column 26; spawns on its
  ;   box, 2 boxes
  ; $F10C trigger box: x 224, row $19, 1 x 3 cells, set off by trap
  ; $F110 trigger box: x 120, row $20, 1 x 4 cells, set off by Rick
  ; $F114 kind $2F: trap, behaviour $10; row $1D, column 25, y +3 px;
  ;   spawns on its box, one-shot, 1 box
  ; $F118 trigger box: x 120, row $20, 1 x 4 cells, set off by Rick
  ; $F11C kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $21,
  ;   column 13; spawns in view
  ; $F120 kind $75: enemy patrols (sprite set 1), patrol 16 px; row $2D,
  ;   column 4; spawns in view
  ; $F124 kind $1E: trap, behaviour $10; row $2D, column 26; spawns on its
  ;   box, 1 box
  ; $F128 trigger box: x 144, row $2C, 10 x 2 cells, set off by Rick, every
  ;   pass
  ; $F12C kind $01: trap, behaviour $24; row $30, column 12 +4 px; spawns
  ;   in view, 1 box
  ; $F130 trigger box: x 24, row $36, 1 x 2 cells, set off by punch
  ; $F134 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $35, column 4; spawns in view, one-shot
  ; $F138 kind $2E: trap, behaviour $10; row $35, column 4, y +3 px; spawns
  ;   on its box, one-shot, 1 box
  ; $F13C trigger box: x 32, row $3D, 12 x 1 cells, set off by Rick
  ; $F140 kind $75: enemy patrols (sprite set 1), patrol 32 px; row $39,
  ;   column 12; spawns in view
  ; $F144 kind $14: treasure pickup; row $39, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F148 trigger box: x 200, row $39, 3 x 3 cells, set off by Rick
  ; $F14C kind $17: trap, behaviour $14; row $46, column 22; spawns in
  ;   view, one-shot, 1 box
  ; $F150 trigger box: x 160, row $46, 2 x 2 cells, set off by blast
  ; $F154 kind $17: trap, behaviour $14; row $46, column 16; spawns in
  ;   view, one-shot, 1 box
  ; $F158 trigger box: x 112, row $46, 2 x 2 cells, set off by blast
  ; $F15C kind $15: trap, behaviour $10; row $4F, column 21; spawns on its
  ;   box, 1 box
  ; $F160 trigger box: x 224, row $56, 1 x 2 cells, set off by punch
  ; $F164 kind $2F: trap, behaviour $10; row $55, column 25, y +3 px;
  ;   spawns on its box, one-shot, 1 box
  ; $F168 trigger box: x 200, row $5E, 2 x 2 cells, set off by Rick
  ; $F16C kind $78: the countdown bonus starts; row $55, column 8; spawns
  ;   on its box, 1 box
  ; $F170 trigger box: x 64, row $55, 4 x 3 cells, set off by Rick
  ; $F174 kind $16: trap, behaviour $14; row $59, column 3; spawns in view,
  ;   1 box
  ; $F178 trigger box: x 152, row $56, 1 x 2 cells, set off by punch
  ; $F17C kind $7D: enemy patrols (sprite set 1), patrol 32 px; row $5D,
  ;   column 4; spawns in view
  ; $F180 kind $15: ammunition pickup; row $61, column 22, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F184 trigger box: x 176, row $61, 3 x 3 cells, set off by Rick
  ; $F188 kind $14: trap, behaviour $10; row $65, column 3; spawns on its
  ;   box, 1 box
  ; $F18C trigger box: x 64, row $64, 9 x 4 cells, set off by Rick, every
  ;   pass
  ; $F190 kind $01: trap, behaviour $08; row $68, column 4; spawns in view,
  ;   1 box
  ; $F194 trigger box: x 224, row $6E, 1 x 2 cells, set off by punch
  ; $F198 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $6D, column 18, y +3 px; spawns in view
  ; $F19C kind $2F: trap, behaviour $10; row $6D, column 25, y +3 px;
  ;   spawns on its box, one-shot, 1 box
  ; $F1A0 trigger box: x 200, row $75, 2 x 3 cells, set off by Rick
  ; $F1A4 kind $76: enemy chases (sprite set 1), patrol 8 px; row $79,
  ;   column 16, y +3 px; spawns in view
  ; $F1A8 the end
  INCBIN "res/level/sections.bin",$0377,197

; Section 6's exits: 1, then the 0 end
Section6Exits:
  ; $F1A9 flags $01: leaves at the left at row $17 -> section 5, row $47
  ; $F1AD the end
  INCBIN "res/level/sections.bin",$043C,5

; Section 6's map entries: 4, then the 0 end
Section6Objects:
  ; $F1AE kind $14: treasure pickup; row $0D, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1B2 trigger box: x 200, row $0D, 3 x 3 cells, set off by Rick
  ; $F1B6 kind $16: detonators pickup; row $0D, column 5, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F1BA trigger box: x 40, row $0D, 3 x 3 cells, set off by Rick
  ; $F1BE kind $14: treasure pickup; row $15, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1C2 trigger box: x 168, row $15, 3 x 3 cells, set off by Rick
  ; $F1C6 kind $14: treasure pickup; row $19, column 13, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1CA trigger box: x 104, row $19, 3 x 3 cells, set off by Rick
  ; $F1CE the end
  INCBIN "res/level/sections.bin",$0441,33

; Section 7's exits: 1, then the 0 end
Section7Exits:
  ; $F1CF flags $02: leaves at the right at row $1B -> section 4, row $73
  ; $F1D3 the end
  INCBIN "res/level/sections.bin",$0462,5

; Section 7's map entries: 4, then the 0 end
Section7Objects:
  ; $F1D4 kind $15: ammunition pickup; row $0C, column 12, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F1D8 trigger box: x 96, row $0C, 3 x 3 cells, set off by Rick
  ; $F1DC kind $14: treasure pickup; row $10, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1E0 trigger box: x 200, row $10, 3 x 3 cells, set off by Rick
  ; $F1E4 kind $14: treasure pickup; row $15, column 4, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1E8 trigger box: x 32, row $15, 3 x 3 cells, set off by Rick
  ; $F1EC kind $14: treasure pickup; row $19, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1F0 trigger box: x 168, row $19, 3 x 3 cells, set off by Rick
  ; $F1F4 the end
  INCBIN "res/level/sections.bin",$0467,33

; The filler entries' lists: a 0 exit list and a 0 entry list each
;
; 16 bytes, two for each filler entry from 8 (the last one's two bytes are the
; first word of KindTable).
FillerSectionLists:
  INCBIN "res/level/sections.bin",$0488,16
