; --------------------------------------------------------------------------------------------------------------------
; sections.asm: The section table, the exit lists and the map entry lists
; --------------------------------------------------------------------------------------------------------------------

; 14 entries of 8 bytes: 13 sections and 1 filler entries
;
; LevelHeader+2 points here; SetupSection $8A6D reads entry A at SectionTable +
; 8A. +0/+1 the map's offset from Maps (big-endian); +2 0, read by no code; +3
; the scroll limit, the last ViewTop (cells, a multiple of 8) the scroll down
; may reach ($88D2); +4/+5 the exit list's offset from SectionTable
; (big-endian), into CheckSectionExit's LD IX,n; +6/+7 the map entry list's
; offset from SectionTable (big-endian), into SectionEntries $8B3E. The number
; of entries is not stored: SectionCounts $8374 says 13 for this level
; (ResetSectionObjects $8379 walks that many lists).
;
; The filler entries (13) have map offset 0 (section 0's map), limit 0 and
; empty lists (two zero bytes each; the last entry's lists are the 0 word
; KindTable starts with). They lie past SectionCounts: no code reaches them.
SectionTable:
  ; $ED6D section 0: map +$0000, limit 0, exits +$0070, entries +$0075
  ; $ED75 section 1: map +$0040, limit 144, exits +$0092, entries +$009F
  ; $ED7D section 2: map +$0190, limit 16, exits +$01A8, entries +$01B1
  ; $ED85 section 3: map +$01E0, limit 72, exits +$01DA, entries +$01E3
  ; $ED8D section 4: map +$0280, limit 112, exits +$0254, entries +$0261
  ; $ED95 section 5: map +$0370, limit 16, exits +$0316, entries +$0323
  ; $ED9D section 6: map +$03B0, limit 88, exits +$034C, entries +$0359
  ; $EDA5 section 7: map +$0490, limit 8, exits +$0406, entries +$040F
  ; $EDAD section 8: map +$04D0, limit 8, exits +$0434, entries +$0439
  ; $EDB5 section 9: map +$0510, limit 8, exits +$045A, entries +$045F
  ; $EDBD section 10: map +$0600, limit 128, exits +$0480, entries +$0489
  ; $EDC5 section 11: map +$0730, limit 96, exits +$057E, entries +$0587
  ; $EDCD section 12: map +$0830, limit 8, exits +$064C, entries +$0655
  ; $EDD5 filler entries 13-13
  INCBIN "res/level/sections.bin",$0000,112

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
  ; $EDDD flags $02: leaves at the right at row $17 -> section 1, row $A7
  ; $EDE1 the end
  INCBIN "res/level/sections.bin",$0070,5

; Section 0's map entries: 5, then the 0 end
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
  ; $EDE2 kind $14: trap, behaviour $18; row $0C, column 13, y +3 px;
  ;   spawns in view, 1 box
  ; $EDE6 trigger box: x 96, row $10, 4 x 12 cells, set off by Rick
  ; $EDEA kind $76: enemy chases (sprite set 1), patrol 8 px; row $11,
  ;   column 16; spawns in view
  ; $EDEE kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $11, column 4; spawns in view
  ; $EDF2 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 24; spawns in view
  ; $EDF6 kind $14: treasure pickup; row $19, column 17, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EDFA trigger box: x 136, row $19, 3 x 3 cells, set off by Rick
  ; $EDFE the end
  INCBIN "res/level/sections.bin",$0075,29

; Section 1's exits: 3, then the 0 end
Section1Exits:
  ; $EDFF flags $02: leaves at the right at row $1B -> section 2, row $23
  ; $EE03 flags $01: leaves at the left at row $6F -> section 8, row $17
  ; $EE07 flags $01: leaves at the left at row $A7 -> section 0, row $17
  ; $EE0B the end
  INCBIN "res/level/sections.bin",$0092,13

; Section 1's map entries: 36, then the 0 end
Section1Objects:
  ; $EE0C kind $04: trap, behaviour $14; row $0D, column 24; spawns on its
  ;   box, 1 box
  ; $EE10 trigger box: x 80, row $0C, 14 x 4 cells, set off by Rick, every
  ;   pass
  ; $EE14 kind $13: trap, behaviour $24; row $10, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $EE18 trigger box: x 24, row $1A, 1 x 2 cells, set off by punch
  ; $EE1C kind $7D: enemy patrols (sprite set 1), patrol 8 px; row $15,
  ;   column 20; spawns in view
  ; $EE20 kind $0B: trap, behaviour $18; row $18, column 11, y +3 px;
  ;   spawns in view, 1 box
  ; $EE24 trigger box: x 80, row $20, 1 x 4 cells, set off by Rick
  ; $EE28 kind $7C: the countdown bonus stops and pays; row $19, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $EE2C trigger box: x 232, row $18, 3 x 4 cells, set off by Rick
  ; $EE30 kind $02: trap, behaviour $00; row $2D, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE34 trigger box: x 192, row $31, 4 x 3 cells, set off by Rick
  ; $EE38 kind $1A: trap, behaviour $00; row $2D, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE3C trigger box: x 192, row $31, 4 x 3 cells, set off by Rick
  ; $EE40 kind $1B: trap, behaviour $00; row $2D, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE44 trigger box: x 192, row $31, 4 x 3 cells, set off by Rick
  ; $EE48 kind $18: trap, behaviour $10; row $36, column 16; spawns on its
  ;   box, 1 box
  ; $EE4C trigger box: x 160, row $43, 2 x 2 cells, set off by trap
  ; $EE50 kind $18: trap, behaviour $10; row $36, column 16; spawns on its
  ;   box, 3 boxes
  ; $EE54 trigger box: x 160, row $43, 2 x 2 cells, set off by trap
  ; $EE58 trigger box: x 24, row $39, 16 x 15 cells, set off by Rick
  ; $EE5C trigger box: x 152, row $39, 9 x 15 cells, set off by Rick
  ; $EE60 kind $16: detonators pickup; row $39, column 8 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EE64 trigger box: x 64, row $39, 3 x 3 cells, set off by Rick
  ; $EE68 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $45,
  ;   column 4; spawns in view, one-shot
  ; $EE6C kind $1D: trap, behaviour $0C; row $45, column 20 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $EE70 trigger box: x 224, row $46, 1 x 2 cells, set off by punch
  ; $EE74 kind $19: trap, behaviour $24; row $48, column 24 +4 px; spawns
  ;   in view, 1 box
  ; $EE78 trigger box: x 200, row $4E, 3 x 2 cells, set off by Rick
  ; $EE7C kind $01: trap, behaviour $0C; row $4D, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $EE80 trigger box: x 152, row $4E, 7 x 2 cells, set off by blast
  ; $EE84 kind $01: trap, behaviour $0C; row $4D, column 15, y +3 px;
  ;   spawns in view, 1 box
  ; $EE88 trigger box: x 104, row $4E, 7 x 2 cells, set off by blast
  ; $EE8C kind $17: trap, behaviour $10; row $4D, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $EE90 trigger box: x 88, row $4C, 1 x 4 cells, set off by Rick
  ; $EE94 kind $0B: trap, behaviour $18; row $58, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $EE98 trigger box: x 160, row $5E, 1 x 6 cells, set off by Rick
  ; $EE9C kind $0D: trap, behaviour $14; row $58, column 16; spawns in
  ;   view, 1 box
  ; $EEA0 trigger box: x 224, row $5E, 1 x 2 cells, set off by punch
  ; $EEA4 kind $16: trap, behaviour $00; row $58, column 12; spawns in view
  ; $EEA8 kind $78: the countdown bonus starts; row $59, column 8; spawns
  ;   on its box, 1 box
  ; $EEAC trigger box: x 64, row $53, 1 x 9 cells, set off by Rick
  ; $EEB0 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $61,
  ;   column 16; spawns in view
  ; $EEB4 kind $03: trap, behaviour $10; row $6E, column 24; spawns on its
  ;   box, 2 boxes
  ; $EEB8 trigger box: x 160, row $70, 4 x 4 cells, set off by Rick, every
  ;   pass
  ; $EEBC trigger box: x 56, row $70, 3 x 4 cells, set off by Rick, every
  ;   pass
  ; $EEC0 kind $04: trap, behaviour $14; row $79, column 24; spawns on its
  ;   box, 1 box
  ; $EEC4 trigger box: x 112, row $79, 10 x 3 cells, set off by Rick, every
  ;   pass
  ; $EEC8 kind $7C: the countdown bonus stops and pays; row $7D, column 4;
  ;   spawns on its box, one-shot, 1 box
  ; $EECC trigger box: x 32, row $7D, 4 x 3 cells, set off by blast
  ; $EED0 kind $75: enemy patrols (sprite set 1), patrol 40 px; row $81,
  ;   column 8; spawns in view
  ; $EED4 kind $13: trap, behaviour $24; row $84, column 24 +4 px; spawns
  ;   in view, 1 box
  ; $EED8 trigger box: x 224, row $8E, 1 x 2 cells, set off by punch
  ; $EEDC kind $01: trap, behaviour $0C; row $85, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $EEE0 trigger box: x 160, row $86, 4 x 2 cells, set off by blast
  ; $EEE4 kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $8D,
  ;   column 16; spawns in view
  ; $EEE8 kind $12: trap, behaviour $18; row $91, column 4, y +3 px; spawns
  ;   in view, 1 box
  ; $EEEC trigger box: x 64, row $96, 4 x 1 cells, set off by Rick
  ; $EEF0 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $91,
  ;   column 4; spawns on its box, 1 box
  ; $EEF4 trigger box: x 32, row $94, 3 x 1 cells, set off by trap
  ; $EEF8 kind $75: enemy patrols (sprite set 1), patrol 72 px; row $99,
  ;   column 8; spawns in view
  ; $EEFC kind $78: the countdown bonus starts; row $99, column 25; spawns
  ;   on its box, 1 box
  ; $EF00 trigger box: x 200, row $98, 3 x 4 cells, set off by blast
  ; $EF04 kind $15: trap, behaviour $00; row $A6, column 21; spawns in view
  ; $EF08 kind $14: treasure pickup; row $A9, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EF0C trigger box: x 192, row $A9, 3 x 3 cells, set off by Rick
  ; $EF10 kind $15: trap, behaviour $00; row $AA, column 13; spawns in view
  ; $EF14 the end
  INCBIN "res/level/sections.bin",$009F,265

; Section 2's exits: 2, then the 0 end
Section2Exits:
  ; $EF15 flags $01: leaves at the left at row $23 -> section 1, row $1B
  ; $EF19 flags $02: leaves at the right at row $23 -> section 3, row $1B
  ; $EF1D the end
  INCBIN "res/level/sections.bin",$01A8,9

; Section 2's map entries: 4, then the 0 end
Section2Objects:
  ; $EF1E kind $01: treasure pickup; row $15, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EF22 trigger box: x 168, row $15, 3 x 3 cells, set off by Rick
  ; $EF26 kind $06: trap, behaviour $10; row $19, column 29, y +3 px;
  ;   spawns on its box, 3 boxes
  ; $EF2A trigger box: x 24, row $20, 1 x 4 cells, set off by Rick
  ; $EF2E trigger box: x 96, row $20, 1 x 4 cells, set off by trap
  ; $EF32 trigger box: x 224, row $20, 1 x 4 cells, set off by Rick
  ; $EF36 kind $06: trap, behaviour $10; row $19, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF3A trigger box: x 96, row $20, 1 x 4 cells, set off by trap
  ; $EF3E kind $01: trap, behaviour $0C; row $21, column 25, y +3 px;
  ;   spawns in view, 1 box
  ; $EF42 trigger box: x 184, row $22, 7 x 2 cells, set off by blast
  ; $EF46 the end
  INCBIN "res/level/sections.bin",$01B1,41

; Section 3's exits: 2, then the 0 end
Section3Exits:
  ; $EF47 flags $01: leaves at the left at row $1B -> section 2, row $23
  ; $EF4B flags $02: leaves at the right at row $47 -> section 4, row $17
  ; $EF4F the end
  INCBIN "res/level/sections.bin",$01DA,9

; Section 3's map entries: 15, then the 0 end
Section3Objects:
  ; $EF50 kind $78: the countdown bonus starts; row $10, column 4; spawns
  ;   on its box, 1 box
  ; $EF54 trigger box: x 32, row $10, 4 x 4 cells, set off by Rick
  ; $EF58 kind $14: detonators pickup; row $11, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EF5C trigger box: x 192, row $11, 3 x 3 cells, set off by Rick
  ; $EF60 kind $15: trap, behaviour $00; row $12, column 13; spawns in view
  ; $EF64 kind $19: trap, behaviour $24; row $14, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $EF68 trigger box: x 64, row $1A, 1 x 2 cells, set off by punch
  ; $EF6C kind $1C: trap, behaviour $08; row $18, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $EF70 trigger box: x 224, row $12, 1 x 2 cells, set off by punch
  ; $EF74 kind $07: trap, behaviour $14; row $1D, column 15; spawns on its
  ;   box, 1 box
  ; $EF78 trigger box: x 160, row $1C, 3 x 4 cells, set off by Rick, every
  ;   pass
  ; $EF7C kind $08: trap, behaviour $14; row $26, column 7; spawns on its
  ;   box, 1 box
  ; $EF80 trigger box: x 184, row $1C, 5 x 12 cells, set off by Rick, every
  ;   pass
  ; $EF84 kind $01: trap, behaviour $0C; row $29, column 17, y +3 px;
  ;   spawns in view, 1 box
  ; $EF88 trigger box: x 120, row $2A, 6 x 2 cells, set off by blast
  ; $EF8C kind $1F: trap, behaviour $00; row $2C, column 20; spawns on its
  ;   box, 1 box
  ; $EF90 trigger box: x 96, row $32, 12 x 2 cells, set off by Rick
  ; $EF94 kind $12: trap, behaviour $18; row $31, column 12, y +3 px;
  ;   spawns in view, 1 box
  ; $EF98 trigger box: x 96, row $32, 5 x 2 cells, set off by blast
  ; $EF9C kind $7A: enemy chases (sprite set 0), patrol 8 px; row $31,
  ;   column 12; spawns on its box, 1 box
  ; $EFA0 trigger box: x 96, row $34, 3 x 1 cells, set off by trap
  ; $EFA4 kind $01: trap, behaviour $0C; row $31, column 19 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $EFA8 trigger box: x 136, row $32, 7 x 2 cells, set off by blast
  ; $EFAC kind $20: trap, behaviour $00; row $44, column 24; spawns in view
  ; $EFB0 kind $7C: the countdown bonus stops and pays; row $45, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $EFB4 trigger box: x 232, row $44, 3 x 4 cells, set off by Rick
  ; $EFB8 kind $1D: trap, behaviour $0C; row $49, column 14 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $EFBC trigger box: x 24, row $46, 1 x 2 cells, set off by punch
  ; $EFC0 the end
  INCBIN "res/level/sections.bin",$01E3,113

; Section 4's exits: 3, then the 0 end
Section4Exits:
  ; $EFC1 flags $01: leaves at the left at row $17 -> section 3, row $47
  ; $EFC5 flags $02: leaves at the right at row $73 -> section 5, row $23
  ; $EFC9 flags $01: leaves at the left at row $77 -> section 9, row $17
  ; $EFCD the end
  INCBIN "res/level/sections.bin",$0254,13

; Section 4's map entries: 25, then the 0 end
Section4Objects:
  ; $EFCE kind $20: trap, behaviour $00; row $14, column 4; spawns in view
  ; $EFD2 kind $14: treasure pickup; row $19, column 12 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $EFD6 trigger box: x 96, row $19, 3 x 3 cells, set off by Rick
  ; $EFDA kind $1F: trap, behaviour $00; row $21, column 8; spawns on its
  ;   box, 1 box
  ; $EFDE trigger box: x 64, row $21, 2 x 1 cells, set off by Rick
  ; $EFE2 kind $78: the countdown bonus starts; row $28, column 14; spawns
  ;   on its box, 1 box
  ; $EFE6 trigger box: x 104, row $24, 3 x 8 cells, set off by Rick
  ; $EFEA kind $01: trap, behaviour $0C; row $29, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $EFEE trigger box: x 48, row $2A, 7 x 2 cells, set off by blast
  ; $EFF2 kind $21: trap, behaviour $08; row $29, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $EFF6 trigger box: x 152, row $2A, 6 x 2 cells, set off by blast
  ; $EFFA kind $7C: the countdown bonus stops and pays; row $30, column 20;
  ;   spawns on its box, one-shot, 1 box
  ; $EFFE trigger box: x 176, row $30, 1 x 4 cells, set off by Rick
  ; $F002 kind $79: enemy patrols (sprite set 0), patrol 8 px; row $31,
  ;   column 4; spawns in view, one-shot
  ; $F006 kind $14: detonators pickup; row $31, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F00A trigger box: x 192, row $31, 3 x 3 cells, set off by Rick
  ; $F00E kind $1D: trap, behaviour $0C; row $39, column 15, y +3 px;
  ;   spawns in view, 3 boxes
  ; $F012 trigger box: x 184, row $3A, 1 x 2 cells, set off by bullet
  ; $F016 trigger box: x 32, row $32, 1 x 2 cells, set off by bullet
  ; $F01A trigger box: x 64, row $3D, 4 x 1 cells, set off by Rick
  ; $F01E kind $01: treasure pickup; row $39, column 20 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F022 trigger box: x 160, row $39, 3 x 3 cells, set off by Rick
  ; $F026 kind $22: trap, behaviour $00; row $41, column 29, y +3 px;
  ;   spawns in view
  ; $F02A kind $1C: trap, behaviour $08; row $4C, column 24 +4 px; spawns
  ;   in view, 1 box
  ; $F02E trigger box: x 184, row $4A, 5 x 2 cells, set off by blast
  ; $F032 kind $76: enemy chases (sprite set 1), patrol 8 px; row $4D,
  ;   column 0; spawns on its box, 1 box
  ; $F036 trigger box: x 192, row $4F, 4 x 1 cells, set off by Rick
  ; $F03A kind $14: treasure pickup; row $4D, column 0, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F03E trigger box: x 0, row $4D, 3 x 3 cells, set off by Rick
  ; $F042 kind $0A: trap, behaviour $18; row $50, column 17, y +3 px;
  ;   spawns in view, 1 box
  ; $F046 trigger box: x 152, row $53, 1 x 5 cells, set off by Rick
  ; $F04A kind $1E: trap, behaviour $00; row $54, column 25; spawns on its
  ;   box, 1 box
  ; $F04E trigger box: x 208, row $54, 1 x 4 cells, set off by Rick
  ; $F052 kind $20: trap, behaviour $00; row $5C, column 21; spawns in view
  ; $F056 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $61,
  ;   column 12; spawns in view
  ; $F05A kind $1F: trap, behaviour $0C; row $65, column 8; spawns in view,
  ;   1 box
  ; $F05E trigger box: x 224, row $5E, 1 x 2 cells, set off by punch
  ; $F062 kind $23: trap, behaviour $04; row $6D, column 21; spawns in
  ;   view, 1 box
  ; $F066 trigger box: x 128, row $69, 12 x 7 cells, set off by Rick, every
  ;   pass
  ; $F06A kind $79: enemy patrols (sprite set 0), patrol 8 px; row $75,
  ;   column 16; spawns in view
  ; $F06E kind $1C: trap, behaviour $08; row $78, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $F072 trigger box: x 40, row $74, 2 x 4 cells, set off by Rick
  ; $F076 kind $01: trap, behaviour $00; row $79, column 4 +4 px, y +3 px;
  ;   spawns in view
  ; $F07A kind $1D: trap, behaviour $1C; row $79, column 20 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $F07E trigger box: x 144, row $73, 8 x 8 cells, set off by Rick, every
  ;   pass
  ; $F082 the end
  INCBIN "res/level/sections.bin",$0261,181

; Section 5's exits: 3, then the 0 end
Section5Exits:
  ; $F083 flags $22: leaves at the right at row $1B -> section 6, row $63;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $F087 flags $01: leaves at the left at row $23 -> section 4, row $73
  ; $F08B flags $02: leaves at the right at row $23 -> section 6, row $6B
  ; $F08F the end
  INCBIN "res/level/sections.bin",$0316,13

; Section 5's map entries: 7, then the 0 end
Section5Objects:
  ; $F090 kind $24: trap, behaviour $00; row $14, column 8; spawns in view
  ; $F094 kind $24: trap, behaviour $00; row $14, column 16; spawns in view
  ; $F098 kind $76: enemy chases (sprite set 1), patrol 8 px; row $19,
  ;   column 4; spawns in view
  ; $F09C kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $19,
  ;   column 20; spawns in view
  ; $F0A0 kind $78: the countdown bonus starts; row $20, column 6; spawns
  ;   on its box, 1 box
  ; $F0A4 trigger box: x 32, row $20, 4 x 4 cells, set off by Rick
  ; $F0A8 kind $7C: the countdown bonus stops and pays; row $20, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F0AC trigger box: x 232, row $20, 3 x 4 cells, set off by Rick
  ; $F0B0 kind $1D: trap, behaviour $0C; row $21, column 25, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F0B4 trigger box: x 24, row $16, 2 x 2 cells, set off by bullet
  ; $F0B8 the end
  INCBIN "res/level/sections.bin",$0323,41

; Section 6's exits: 3, then the 0 end
Section6Exits:
  ; $F0B9 flags $02: leaves at the right at row $1B -> section 7, row $1B
  ; $F0BD flags $01: leaves at the left at row $63 -> section 5, row $1B
  ; $F0C1 flags $01: leaves at the left at row $6B -> section 5, row $23
  ; $F0C5 the end
  INCBIN "res/level/sections.bin",$034C,13

; Section 6's map entries: 24, then the 0 end
Section6Objects:
  ; $F0C6 kind $0D: trap, behaviour $14; row $18, column 16; spawns in
  ;   view, 1 box
  ; $F0CA trigger box: x 24, row $18, 2 x 4 cells, set off by bullet
  ; $F0CE kind $0D: trap, behaviour $00; row $18, column 8; spawns in view
  ; $F0D2 kind $7C: the countdown bonus stops and pays; row $19, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F0D6 trigger box: x 232, row $18, 3 x 4 cells, set off by Rick
  ; $F0DA kind $17: trap, behaviour $10; row $21, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $F0DE trigger box: x 192, row $24, 4 x 1 cells, set off by Rick
  ; $F0E2 kind $12: trap, behaviour $18; row $2D, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $F0E6 trigger box: x 144, row $28, 1 x 8 cells, set off by Rick
  ; $F0EA kind $12: trap, behaviour $18; row $2D, column 12, y +3 px;
  ;   spawns in view, 1 box
  ; $F0EE trigger box: x 144, row $28, 1 x 8 cells, set off by Rick
  ; $F0F2 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $2D,
  ;   column 8; spawns on its box, 1 box
  ; $F0F6 trigger box: x 64, row $30, 3 x 1 cells, set off by trap
  ; $F0FA kind $7A: enemy chases (sprite set 0), patrol 8 px; row $2D,
  ;   column 12; spawns on its box, 1 box
  ; $F0FE trigger box: x 96, row $30, 3 x 1 cells, set off by trap
  ; $F102 kind $79: enemy patrols (sprite set 0), patrol 40 px; row $35,
  ;   column 4; spawns in view
  ; $F106 kind $27: trap, behaviour $0C; row $3A, column 24; spawns in
  ;   view, 1 box
  ; $F10A trigger box: x 128, row $3A, 8 x 1 cells, set off by Rick
  ; $F10E kind $15: ammunition pickup; row $3D, column 4 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F112 trigger box: x 32, row $3D, 3 x 3 cells, set off by Rick
  ; $F116 kind $26: trap, behaviour $0C; row $42, column 11; spawns in
  ;   view, 1 box
  ; $F11A trigger box: x 56, row $4A, 2 x 2 cells, set off by bullet
  ; $F11E kind $75: enemy patrols (sprite set 1), patrol 24 px; row $49,
  ;   column 8; spawns in view
  ; $F122 kind $75: enemy patrols (sprite set 1), patrol 56 px; row $49,
  ;   column 8; spawns in view
  ; $F126 kind $25: trap, behaviour $00; row $51, column 8, y +3 px; spawns
  ;   on its box, 1 box
  ; $F12A trigger box: x 72, row $50, 1 x 4 cells, set off by Rick
  ; $F12E kind $25: trap, behaviour $00; row $51, column 14, y +3 px;
  ;   spawns on its box, 1 box
  ; $F132 trigger box: x 120, row $50, 1 x 4 cells, set off by Rick
  ; $F136 kind $25: trap, behaviour $00; row $51, column 20, y +3 px;
  ;   spawns on its box, 1 box
  ; $F13A trigger box: x 168, row $50, 1 x 4 cells, set off by Rick
  ; $F13E kind $78: the countdown bonus starts; row $55, column 4; spawns
  ;   on its box, 1 box
  ; $F142 trigger box: x 32, row $55, 4 x 1 cells, set off by Rick
  ; $F146 kind $11: trap, behaviour $14; row $5A, column 20; spawns on its
  ;   box, 1 box
  ; $F14A trigger box: x 32, row $57, 16 x 8 cells, set off by Rick, every
  ;   pass
  ; $F14E kind $12: trap, behaviour $18; row $65, column 22, y +3 px;
  ;   spawns in view, 1 box
  ; $F152 trigger box: x 160, row $66, 3 x 2 cells, set off by blast
  ; $F156 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $65,
  ;   column 22; spawns on its box, 1 box
  ; $F15A trigger box: x 176, row $68, 3 x 1 cells, set off by trap
  ; $F15E kind $16: detonators pickup; row $65, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F162 trigger box: x 200, row $65, 3 x 3 cells, set off by Rick
  ; $F166 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $69,
  ;   column 17; spawns in view
  ; $F16A kind $15: ammunition pickup; row $69, column 6, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F16E trigger box: x 48, row $69, 3 x 3 cells, set off by Rick
  ; $F172 the end
  INCBIN "res/level/sections.bin",$0359,173

; Section 7's exits: 2, then the 0 end
Section7Exits:
  ; $F173 flags $21: leaves at the left at row $1B -> section 6, row $1B;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $F177 flags $82: leaves at the right at row $1B -> section 10, row $1B;
  ;   bit 7: ends the level; with CheatExits ($8067 bit 7) a passage into
  ;   section 10
  ; $F17B the end
  INCBIN "res/level/sections.bin",$0406,9

; Section 7's map entries: 6, then the 0 end
Section7Objects:
  ; $F17C kind $0B: trap, behaviour $18; row $10, column 5, y +3 px; spawns
  ;   in view, 1 box
  ; $F180 trigger box: x 32, row $17, 2 x 5 cells, set off by Rick/enemy
  ; $F184 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $11, column 8; spawns in view
  ; $F188 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $11, column 25; spawns in view
  ; $F18C kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $11, column 20; spawns in view
  ; $F190 kind $21: trap, behaviour $08; row $11, column 16, y +3 px;
  ;   spawns in view, 1 box
  ; $F194 trigger box: x 112, row $12, 3 x 2 cells, set off by blast
  ; $F198 kind $15: ammunition pickup; row $15, column 12 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F19C trigger box: x 96, row $15, 3 x 3 cells, set off by Rick
  ; $F1A0 the end
  INCBIN "res/level/sections.bin",$040F,37

; Section 8's exits: 1, then the 0 end
Section8Exits:
  ; $F1A1 flags $02: leaves at the right at row $17 -> section 1, row $6F
  ; $F1A5 the end
  INCBIN "res/level/sections.bin",$0434,5

; Section 8's map entries: 4, then the 0 end
Section8Objects:
  ; $F1A6 kind $01: treasure pickup; row $0D, column 16 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F1AA trigger box: x 128, row $0D, 3 x 3 cells, set off by Rick
  ; $F1AE kind $01: ammunition pickup; row $11, column 8 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F1B2 trigger box: x 64, row $11, 3 x 3 cells, set off by Rick
  ; $F1B6 kind $01: treasure pickup; row $11, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F1BA trigger box: x 192, row $11, 3 x 3 cells, set off by Rick
  ; $F1BE kind $01: treasure pickup; row $19, column 22, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F1C2 trigger box: x 176, row $19, 3 x 3 cells, set off by Rick
  ; $F1C6 the end
  INCBIN "res/level/sections.bin",$0439,33

; Section 9's exits: 1, then the 0 end
Section9Exits:
  ; $F1C7 flags $02: leaves at the right at row $17 -> section 4, row $77
  ; $F1CB the end
  INCBIN "res/level/sections.bin",$045A,5

; Section 9's map entries: 4, then the 0 end
Section9Objects:
  ; $F1CC kind $01: ammunition pickup; row $0D, column 4 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F1D0 trigger box: x 32, row $0D, 3 x 3 cells, set off by Rick
  ; $F1D4 kind $01: treasure pickup; row $11, column 20 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F1D8 trigger box: x 160, row $11, 3 x 3 cells, set off by Rick
  ; $F1DC kind $01: detonators pickup; row $19, column 10, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F1E0 trigger box: x 80, row $19, 3 x 3 cells, set off by Rick
  ; $F1E4 kind $01: treasure pickup; row $19, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F1E8 trigger box: x 192, row $19, 3 x 3 cells, set off by Rick
  ; $F1EC the end
  INCBIN "res/level/sections.bin",$045F,33

; Section 10's exits: 2, then the 0 end
Section10Exits:
  ; $F1ED flags $01: leaves at the left at row $1B -> section 7, row $1B
  ; $F1F1 flags $01: leaves at the left at row $93 -> section 11, row $1B
  ; $F1F5 the end
  INCBIN "res/level/sections.bin",$0480,9

; Section 10's map entries: 33, then the 0 end
Section10Objects:
  ; $F1F6 kind $29: trap, behaviour $10; row $11, column 0, y +3 px; spawns
  ;   on its box, 2 boxes
  ; $F1FA trigger box: x 24, row $18, 1 x 4 cells, set off by Rick
  ; $F1FE trigger box: x 152, row $17, 1 x 5 cells, set off by trap
  ; $F202 kind $29: trap, behaviour $10; row $11, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $F206 trigger box: x 152, row $16, 1 x 6 cells, set off by trap
  ; $F20A kind $01: treasure pickup; row $11, column 20, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F20E trigger box: x 160, row $11, 3 x 3 cells, set off by Rick
  ; $F212 kind $78: the countdown bonus starts; row $19, column 4; spawns
  ;   on its box, 1 box
  ; $F216 trigger box: x 32, row $18, 1 x 4 cells, set off by Rick
  ; $F21A kind $75: enemy patrols (sprite set 1), patrol 24 px; row $25,
  ;   column 8; spawns in view
  ; $F21E kind $1C: trap, behaviour $08; row $28, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $F222 trigger box: x 32, row $26, 4 x 2 cells, set off by blast
  ; $F226 kind $21: trap, behaviour $08; row $29, column 24 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F22A trigger box: x 192, row $27, 4 x 2 cells, set off by blast
  ; $F22E kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $29, column 16; spawns in view
  ; $F232 kind $1D: trap, behaviour $0C; row $31, column 4 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F236 trigger box: x 24, row $26, 1 x 2 cells, set off by punch
  ; $F23A kind $09: trap, behaviour $14; row $35, column 28; spawns on its
  ;   box, 1 box
  ; $F23E trigger box: x 160, row $34, 5 x 5 cells, set off by Rick, every
  ;   pass
  ; $F242 kind $1F: trap, behaviour $00; row $38, column 4, y +3 px; spawns
  ;   on its box, 1 box
  ; $F246 trigger box: x 48, row $38, 2 x 4 cells, set off by Rick
  ; $F24A kind $01: trap, behaviour $0C; row $3D, column 8 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F24E trigger box: x 64, row $3B, 5 x 5 cells, set off by blast
  ; $F252 kind $7C: the countdown bonus stops and pays; row $45, column 20;
  ;   spawns on its box, one-shot, 1 box
  ; $F256 trigger box: x 160, row $44, 4 x 4 cells, set off by Rick
  ; $F25A kind $1D: trap, behaviour $00; row $4D, column 24 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $F25E trigger box: x 192, row $49, 4 x 5 cells, set off by Rick
  ; $F262 kind $21: trap, behaviour $08; row $51, column 15, y +3 px;
  ;   spawns in view, 1 box
  ; $F266 trigger box: x 104, row $4F, 4 x 5 cells, set off by blast
  ; $F26A kind $1C: trap, behaviour $08; row $51, column 18, y +3 px;
  ;   spawns in view, 1 box
  ; $F26E trigger box: x 128, row $4F, 7 x 5 cells, set off by blast
  ; $F272 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $51,
  ;   column 4; spawns in view
  ; $F276 kind $01: detonators pickup; row $51, column 4 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F27A trigger box: x 32, row $51, 3 x 3 cells, set off by Rick
  ; $F27E kind $7E: enemy chases (sprite set 1), patrol 8 px; row $59,
  ;   column 0; spawns on its box, 1 box
  ; $F282 trigger box: x 128, row $57, 4 x 1 cells, set off by Rick
  ; $F286 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $59, column 0; spawns on its box, 1 box
  ; $F28A trigger box: x 128, row $57, 4 x 1 cells, set off by Rick
  ; $F28E kind $21: trap, behaviour $08; row $5D, column 20, y +3 px;
  ;   spawns in view, 1 box
  ; $F292 trigger box: x 120, row $5E, 6 x 2 cells, set off by blast
  ; $F296 kind $1C: trap, behaviour $08; row $60, column 16 +4 px; spawns
  ;   in view, 1 box
  ; $F29A trigger box: x 120, row $5E, 6 x 2 cells, set off by blast
  ; $F29E kind $01: ammunition pickup; row $69, column 4 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F2A2 trigger box: x 32, row $69, 3 x 3 cells, set off by Rick
  ; $F2A6 kind $79: enemy patrols (sprite set 0), patrol 56 px; row $69,
  ;   column 12; spawns in view
  ; $F2AA kind $28: trap, behaviour $10; row $70, column 0 +4 px; spawns on
  ;   its box, 1 box
  ; $F2AE trigger box: x 224, row $66, 1 x 2 cells, set off by punch
  ; $F2B2 kind $01: treasure pickup; row $71, column 17, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F2B6 trigger box: x 136, row $71, 3 x 3 cells, set off by Rick
  ; $F2BA kind $78: the countdown bonus starts; row $71, column 21; spawns
  ;   on its box, 1 box
  ; $F2BE trigger box: x 168, row $70, 3 x 4 cells, set off by Rick
  ; $F2C2 kind $2A: trap, behaviour $0C; row $72, column 7; spawns in view,
  ;   1 box
  ; $F2C6 trigger box: x 224, row $7A, 1 x 2 cells, set off by punch
  ; $F2CA kind $08: trap, behaviour $14; row $86, column 7; spawns on its
  ;   box, 1 box
  ; $F2CE trigger box: x 128, row $83, 12 x 5 cells, set off by Rick, every
  ;   pass
  ; $F2D2 kind $20: trap, behaviour $00; row $8C, column 8; spawns in view
  ; $F2D6 kind $01: treasure pickup; row $8D, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F2DA trigger box: x 192, row $8D, 3 x 3 cells, set off by Rick
  ; $F2DE kind $7C: the countdown bonus stops and pays; row $91, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $F2E2 trigger box: x 0, row $90, 3 x 4 cells, set off by Rick
  ; $F2E6 kind $15: trap, behaviour $00; row $92, column 21; spawns in view
  ; $F2EA the end
  INCBIN "res/level/sections.bin",$0489,245

; Section 11's exits: 2, then the 0 end
Section11Exits:
  ; $F2EB flags $02: leaves at the right at row $1B -> section 10, row $93
  ; $F2EF flags $01: leaves at the left at row $7B -> section 12, row $1B
  ; $F2F3 the end
  INCBIN "res/level/sections.bin",$057E,9

; Section 11's map entries: 29, then the 0 end
Section11Objects:
  ; $F2F4 kind $21: trap, behaviour $08; row $0D, column 17, y +3 px;
  ;   spawns in view, 1 box
  ; $F2F8 trigger box: x 120, row $0E, 3 x 2 cells, set off by blast
  ; $F2FC kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $0D, column 13; spawns in view, one-shot
  ; $F300 kind $1E: trap, behaviour $0C; row $1C, column 25, y +3 px;
  ;   spawns in view, 1 box
  ; $F304 trigger box: x 184, row $1E, 1 x 2 cells, set off by Rick
  ; $F308 kind $1C: trap, behaviour $08; row $1C, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $F30C trigger box: x 32, row $1A, 4 x 2 cells, set off by blast
  ; $F310 kind $1D: trap, behaviour $0C; row $1D, column 4 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F314 trigger box: x 160, row $0E, 1 x 2 cells, set off by punch
  ; $F318 kind $01: trap, behaviour $0C; row $25, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $F31C trigger box: x 176, row $24, 6 x 4 cells, set off by blast
  ; $F320 kind $20: trap, behaviour $00; row $28, column 12; spawns in view
  ; $F324 kind $01: trap, behaviour $0C; row $2D, column 20 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F328 trigger box: x 160, row $2C, 5 x 4 cells, set off by blast
  ; $F32C kind $01: detonators pickup; row $2D, column 25, y +3 px; spawns
  ;   in view, 1 box
  ; $F330 trigger box: x 200, row $2D, 3 x 3 cells, set off by Rick
  ; $F334 kind $2B: trap, behaviour $18; row $39, column 12, y +3 px;
  ;   spawns in view, 1 box
  ; $F338 trigger box: x 152, row $38, 1 x 4 cells, set off by Rick
  ; $F33C kind $7A: enemy chases (sprite set 0), patrol 8 px; row $39,
  ;   column 12; spawns on its box, 1 box
  ; $F340 trigger box: x 96, row $3C, 3 x 1 cells, set off by trap
  ; $F344 kind $78: the countdown bonus starts; row $41, column 24; spawns
  ;   on its box, 1 box
  ; $F348 trigger box: x 192, row $40, 4 x 1 cells, set off by Rick
  ; $F34C kind $7D: enemy patrols (sprite set 1), patrol 8 px; row $45,
  ;   column 20; spawns in view
  ; $F350 kind $1D: trap, behaviour $0C; row $49, column 16 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F354 trigger box: x 120, row $46, 2 x 2 cells, set off by bullet
  ; $F358 kind $01: trap, behaviour $0C; row $4D, column 12 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F35C trigger box: x 80, row $4D, 6 x 3 cells, set off by blast
  ; $F360 kind $7D: enemy patrols (sprite set 1), patrol 8 px; row $51,
  ;   column 8; spawns in view
  ; $F364 kind $01: ammunition pickup; row $51, column 24 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F368 trigger box: x 192, row $51, 3 x 3 cells, set off by Rick
  ; $F36C kind $1F: trap, behaviour $00; row $57, column 4; spawns on its
  ;   box, 1 box
  ; $F370 trigger box: x 32, row $57, 1 x 5 cells, set off by Rick
  ; $F374 kind $01: detonators pickup; row $59, column 8 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F378 trigger box: x 64, row $59, 3 x 3 cells, set off by Rick
  ; $F37C kind $7C: the countdown bonus stops and pays; row $59, column 20;
  ;   spawns on its box, one-shot, 1 box
  ; $F380 trigger box: x 160, row $58, 4 x 4 cells, set off by Rick
  ; $F384 kind $2C: trap, behaviour $00; row $61, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $F388 trigger box: x 32, row $56, 9 x 6 cells, set off by Rick
  ; $F38C kind $2D: trap, behaviour $00; row $61, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $F390 trigger box: x 32, row $56, 9 x 6 cells, set off by Rick
  ; $F394 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $69,
  ;   column 25; spawns in view
  ; $F398 kind $20: trap, behaviour $00; row $6C, column 8; spawns in view
  ; $F39C kind $75: enemy patrols (sprite set 1), patrol 24 px; row $6D,
  ;   column 16; spawns in view
  ; $F3A0 kind $01: trap, behaviour $0C; row $71, column 17, y +3 px;
  ;   spawns in view, 1 box
  ; $F3A4 trigger box: x 120, row $72, 7 x 2 cells, set off by blast
  ; $F3A8 kind $1D: trap, behaviour $0C; row $71, column 4 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $F3AC trigger box: x 24, row $6E, 2 x 2 cells, set off by bullet
  ; $F3B0 kind $76: enemy chases (sprite set 1), patrol 8 px; row $79,
  ;   column 4; spawns in view
  ; $F3B4 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $79, column 16; spawns in view
  ; $F3B8 the end
  INCBIN "res/level/sections.bin",$0587,197

; Section 12's exits: 2, then the 0 end
Section12Exits:
  ; $F3B9 flags $91: leaves at the left at row $17 -> section 0, row $17;
  ;   bit 7 + bit 4: ends the level (also with CheatExits)
  ; $F3BD flags $02: leaves at the right at row $1B -> section 11, row $7B
  ; $F3C1 the end
  INCBIN "res/level/sections.bin",$064C,9

; Section 12's map entries: 5, then the 0 end
Section12Objects:
  ; $F3C2 kind $0B: trap, behaviour $18; row $0C, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $F3C6 trigger box: x 176, row $13, 1 x 5 cells, set off by Rick
  ; $F3CA kind $20: trap, behaviour $00; row $0C, column 8; spawns in view
  ; $F3CE kind $7E: enemy chases (sprite set 1), patrol 8 px; row $0D,
  ;   column 16; spawns in view
  ; $F3D2 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $15,
  ;   column 20; spawns in view
  ; $F3D6 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 5; spawns in view
  ; $F3DA the end
  INCBIN "res/level/sections.bin",$0655,25
