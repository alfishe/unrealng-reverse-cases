; --------------------------------------------------------------------------------------------------------------------
; sections.asm: The section table, the exit lists and the map entry lists
; --------------------------------------------------------------------------------------------------------------------

; 13 entries of 8 bytes: 13 sections
;
; LevelHeader+2 points here; SetupSection $8A6D reads entry A at SectionTable +
; 8A. +0/+1 the map's offset from Maps (big-endian); +2 0, read by no code; +3
; the scroll limit, the last ViewTop (cells, a multiple of 8) the scroll down
; may reach ($88D2); +4/+5 the exit list's offset from SectionTable
; (big-endian), into CheckSectionExit's LD IX,n; +6/+7 the map entry list's
; offset from SectionTable (big-endian), into SectionEntries $8B3E. The number
; of entries is not stored: SectionCounts $8374 says 13 for this level
; (ResetSectionObjects $8379 walks that many lists).
SectionTable:
  ; $EAED section 0: map +$0000, limit 120, exits +$0068, entries +$0075
  ; $EAF5 section 1: map +$0130, limit 8, exits +$017A, entries +$0183
  ; $EAFD section 2: map +$0170, limit 72, exits +$01A8, entries +$01B1
  ; $EB05 section 3: map +$0240, limit 96, exits +$024A, entries +$025B
  ; $EB0D section 4: map +$0340, limit 24, exits +$02FC, entries +$030D
  ; $EB15 section 5: map +$03B0, limit 48, exits +$0366, entries +$0377
  ; $EB1D section 6: map +$0450, limit 48, exits +$03E0, entries +$03E5
  ; $EB25 section 7: map +$04F0, limit 32, exits +$0476, entries +$047B
  ; $EB2D section 8: map +$0560, limit 8, exits +$04B8, entries +$04BD
  ; $EB35 section 9: map +$05A0, limit 8, exits +$04E6, entries +$04EB
  ; $EB3D section 10: map +$0600, limit 200, exits +$0514, entries +$0525
  ; $EB45 section 11: map +$07C0, limit 32, exits +$0676, entries +$067F
  ; $EB4D section 12: map +$0830, limit 48, exits +$06D0, entries +$06D9
  INCBIN "res/level/sections.bin",$0000,104

; Section 0's exits: 3, then the 0 end
;
; 4 bytes an exit: +0 flags (bits 0-1 the side Rick leaves the view at: 1 left,
; 2 right; bit 4 ends the level even with CheatExits; bit 5 RideMode on the way
; in; bit 6 LevelHookOn = 20; bit 7 the level ends), +1 the section row of
; Rick's feet (ViewTop + (y + 20) / 8) at which it is taken, +2 the section
; entered, +3 the row of that section his feet arrive at (the new ViewTop = +3
; - his feet row in the view). A byte with bits 0, 1, 3 clear ends the list (a
; single 0). CheckSectionExit $8993 reads them.
Section0Exits:
  ; $EB55 flags $01: leaves at the left at row $47 -> section 8, row $17
  ; $EB59 flags $02: leaves at the right at row $4F -> section 1, row $17
  ; $EB5D flags $02: leaves at the right at row $8F -> section 3, row $1F
  ; $EB61 the end
  INCBIN "res/level/sections.bin",$0068,13

; Section 0's map entries: 35, then the 0 end
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
  ; $EB62 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $0D,
  ;   column 12; spawns in view
  ; $EB66 kind $75: enemy patrols (sprite set 1), patrol 8 px; row $11,
  ;   column 20; spawns in view
  ; $EB6A kind $1A: trap, behaviour $10; row $16, column 24; spawns on its
  ;   box, 1 box
  ; $EB6E trigger box: x 160, row $11, 8 x 9 cells, set off by Rick, every
  ;   pass
  ; $EB72 kind $13: trap, behaviour $08; row $18, column 16; spawns in
  ;   view, 1 box
  ; $EB76 trigger box: x 24, row $18, 1 x 4 cells, set off by Rick
  ; $EB7A kind $14: trap, behaviour $08; row $18, column 18; spawns in
  ;   view, 1 box
  ; $EB7E trigger box: x 96, row $18, 1 x 4 cells, set off by trap
  ; $EB82 kind $78: the countdown bonus starts; row $18, column 24; spawns
  ;   on its box, 1 box
  ; $EB86 trigger box: x 192, row $18, 4 x 1 cells, set off by Rick
  ; $EB8A kind $03: trap, behaviour $10; row $24, column 29, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $EB8E trigger box: x 224, row $1A, 1 x 2 cells, set off by punch
  ; $EB92 trigger box: x 88, row $24, 1 x 4 cells, set off by trap
  ; $EB96 kind $03: trap, behaviour $10; row $24, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EB9A trigger box: x 88, row $24, 1 x 4 cells, set off by trap
  ; $EB9E kind $01: trap, behaviour $18; row $31, column 14, y +3 px;
  ;   spawns in view, 1 box
  ; $EBA2 trigger box: x 96, row $32, 3 x 2 cells, set off by blast
  ; $EBA6 kind $11: trap, behaviour $10; row $36, column 9; spawns on its
  ;   box, 1 box
  ; $EBAA trigger box: x 32, row $2F, 10 x 12 cells, set off by Rick, every
  ;   pass
  ; $EBAE kind $17: trap, behaviour $10; row $36, column 20; spawns on its
  ;   box, 1 box
  ; $EBB2 trigger box: x 128, row $30, 12 x 11 cells, set off by Rick,
  ;   every pass
  ; $EBB6 kind $75: enemy patrols (sprite set 1), patrol 56 px; row $3D,
  ;   column 8; spawns in view
  ; $EBBA kind $0F: trap, behaviour $08; row $40, column 12 +4 px; spawns
  ;   in view, 1 box
  ; $EBBE trigger box: x 56, row $3E, 1 x 2 cells, set off by punch
  ; $EBC2 kind $79: enemy patrols (sprite set 0), patrol 32 px; row $45,
  ;   column 8; spawns in view
  ; $EBC6 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $45,
  ;   column 19; spawns in view
  ; $EBCA kind $7C: the countdown bonus stops and pays; row $45, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $EBCE trigger box: x 0, row $44, 3 x 4 cells, set off by Rick
  ; $EBD2 kind $04: trap, behaviour $18; row $50, column 12 +4 px; spawns
  ;   in view, 1 box
  ; $EBD6 trigger box: x 128, row $4E, 1 x 2 cells, set off by punch
  ; $EBDA kind $05: trap, behaviour $08; row $52, column 20; spawns in
  ;   view, 1 box
  ; $EBDE trigger box: x 104, row $50, 1 x 4 cells, set off by Rick
  ; $EBE2 kind $06: trap, behaviour $08; row $5A, column 21; spawns in
  ;   view, 2 boxes
  ; $EBE6 trigger box: x 112, row $58, 1 x 4 cells, set off by Rick
  ; $EBEA trigger box: x 160, row $58, 4 x 1 cells, set off by Rick
  ; $EBEE kind $44: trap, behaviour $24; row $64, column 18, y +3 px;
  ;   spawns in view, 1 box
  ; $EBF2 trigger box: x 128, row $66, 7 x 2 cells, set off by blast
  ; $EBF6 kind $7A: enemy chases (sprite set 0), patrol 8 px; row $65,
  ;   column 4; spawns in view
  ; $EBFA kind $7A: enemy chases (sprite set 0), patrol 8 px; row $65,
  ;   column 11; spawns in view
  ; $EBFE kind $01: detonators pickup; row $65, column 25, y +3 px; spawns
  ;   in view, 1 box
  ; $EC02 trigger box: x 200, row $65, 3 x 3 cells, set off by Rick
  ; $EC06 kind $78: the countdown bonus starts; row $6A, column 4; spawns
  ;   on its box, 1 box
  ; $EC0A trigger box: x 32, row $6B, 4 x 1 cells, set off by Rick
  ; $EC0E kind $09: trap, behaviour $10; row $74, column 0, y +3 px; spawns
  ;   on its box, 1 box
  ; $EC12 trigger box: x 24, row $6E, 1 x 2 cells, set off by punch
  ; $EC16 kind $0A: trap, behaviour $10; row $76, column 6; spawns on its
  ;   box, 1 box
  ; $EC1A trigger box: x 32, row $6E, 16 x 10 cells, set off by Rick, every
  ;   pass
  ; $EC1E kind $0A: trap, behaviour $10; row $76, column 18; spawns on its
  ;   box, 1 box
  ; $EC22 trigger box: x 80, row $72, 16 x 6 cells, set off by Rick, every
  ;   pass
  ; $EC26 kind $0B: trap, behaviour $08; row $80, column 28; spawns in
  ;   view, 1 box
  ; $EC2A trigger box: x 208, row $81, 3 x 3 cells, set off by blast
  ; $EC2E kind $75: enemy patrols (sprite set 1), patrol 8 px; row $81,
  ;   column 12; spawns in view
  ; $EC32 kind $0C: trap, behaviour $18; row $84, column 0; spawns in view,
  ;   1 box
  ; $EC36 trigger box: x 16, row $84, 1 x 4 cells, set off by trap
  ; $EC3A kind $04: trap, behaviour $08; row $88, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $EC3E trigger box: x 128, row $82, 1 x 2 cells, set off by punch
  ; $EC42 kind $7C: the countdown bonus stops and pays; row $8D, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $EC46 trigger box: x 232, row $8C, 3 x 4 cells, set off by Rick
  ; $EC4A kind $16: trap, behaviour $00; row $91, column 24 +4 px, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $EC4E trigger box: x 32, row $8C, 5 x 1 cells, set off by Rick
  ; $EC52 trigger box: x 248, row $8C, 1 x 4 cells, set off by Rick
  ; $EC56 kind $0E: trap, behaviour $08; row $91, column 9, y +3 px; spawns
  ;   in view, 1 box
  ; $EC5A trigger box: x 32, row $8C, 4 x 1 cells, set off by Rick
  ; $EC5E kind $15: trap, behaviour $08; row $91, column 9, y +3 px; spawns
  ;   in view, 1 box
  ; $EC62 trigger box: x 32, row $8C, 4 x 1 cells, set off by Rick
  ; $EC66 the end
  INCBIN "res/level/sections.bin",$0075,261

; Section 1's exits: 2, then the 0 end
Section1Exits:
  ; $EC67 flags $02: leaves at the right at row $17 -> section 2, row $27
  ; $EC6B flags $01: leaves at the left at row $17 -> section 0, row $4F
  ; $EC6F the end
  INCBIN "res/level/sections.bin",$017A,9

; Section 1's map entries: 5, then the 0 end
Section1Objects:
  ; $EC70 kind $02: trap, behaviour $00; row $0C, column 14 +4 px; spawns
  ;   in view
  ; $EC74 kind $17: trap, behaviour $10; row $12, column 20; spawns on its
  ;   box, 1 box
  ; $EC78 trigger box: x 144, row $0C, 11 x 9 cells, set off by Rick, every
  ;   pass
  ; $EC7C kind $0E: trap, behaviour $08; row $19, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $EC80 trigger box: x 16, row $14, 1 x 4 cells, set off by Rick
  ; $EC84 kind $01: trap, behaviour $18; row $19, column 20 +4 px, y +3 px;
  ;   spawns in view, 1 box
  ; $EC88 trigger box: x 144, row $1A, 7 x 2 cells, set off by blast
  ; $EC8C kind $15: trap, behaviour $08; row $19, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $EC90 trigger box: x 16, row $14, 1 x 4 cells, set off by Rick
  ; $EC94 the end
  INCBIN "res/level/sections.bin",$0183,37

; Section 2's exits: 2, then the 0 end
Section2Exits:
  ; $EC95 flags $01: leaves at the left at row $27 -> section 1, row $17
  ; $EC99 flags $01: leaves at the left at row $5F -> section 3, row $17
  ; $EC9D the end
  INCBIN "res/level/sections.bin",$01A8,9

; Section 2's map entries: 23, then the 0 end
Section2Objects:
  ; $EC9E kind $01: ammunition pickup; row $0D, column 8, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $ECA2 trigger box: x 64, row $0D, 3 x 3 cells, set off by Rick
  ; $ECA6 kind $02: trap, behaviour $00; row $14, column 14 +4 px; spawns
  ;   in view, 1 box
  ; $ECAA trigger box: x 56, row $0E, 1 x 2 cells, set off by punch
  ; $ECAE kind $78: the countdown bonus starts; row $15, column 18; spawns
  ;   on its box, 1 box
  ; $ECB2 trigger box: x 152, row $14, 1 x 4 cells, set off by Rick
  ; $ECB6 kind $17: trap, behaviour $00; row $19, column 4; spawns in view
  ; $ECBA kind $17: trap, behaviour $10; row $1D, column 20; spawns on its
  ;   box, 1 box
  ; $ECBE trigger box: x 144, row $14, 10 x 13 cells, set off by Rick,
  ;   every pass
  ; $ECC2 kind $76: enemy chases (sprite set 1), patrol 8 px; row $21,
  ;   column 9; spawns in view
  ; $ECC6 kind $75: enemy patrols (sprite set 1), patrol 40 px; row $21,
  ;   column 16; spawns in view
  ; $ECCA kind $01: detonators pickup; row $29, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $ECCE trigger box: x 200, row $29, 3 x 3 cells, set off by Rick
  ; $ECD2 kind $1E: trap, behaviour $10; row $31, column 28, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $ECD6 trigger box: x 96, row $30, 1 x 4 cells, set off by trap
  ; $ECDA trigger box: x 160, row $2D, 4 x 1 cells, set off by Rick
  ; $ECDE kind $1E: trap, behaviour $10; row $31, column 28, y +3 px;
  ;   spawns on its box, 1 box
  ; $ECE2 trigger box: x 96, row $30, 1 x 4 cells, set off by trap
  ; $ECE6 kind $01: treasure pickup; row $39, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $ECEA trigger box: x 192, row $39, 3 x 3 cells, set off by Rick
  ; $ECEE kind $79: enemy patrols (sprite set 0), patrol 40 px; row $41,
  ;   column 8; spawns in view
  ; $ECF2 kind $75: enemy patrols (sprite set 1), patrol 24 px; row $49,
  ;   column 8; spawns in view
  ; $ECF6 kind $01: treasure pickup; row $49, column 24 +4 px, y +3 px;
  ;   spawns in view, one-shot, 1 box
  ; $ECFA trigger box: x 192, row $49, 3 x 3 cells, set off by Rick
  ; $ECFE kind $17: trap, behaviour $00; row $4E, column 16; spawns in view
  ; $ED02 kind $04: trap, behaviour $18; row $50, column 4 +4 px; spawns in
  ;   view, 1 box
  ; $ED06 trigger box: x 224, row $52, 1 x 2 cells, set off by punch
  ; $ED0A kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $51, column 25; spawns in view
  ; $ED0E kind $1B: trap, behaviour $08; row $52, column 12; spawns in
  ;   view, 2 boxes
  ; $ED12 trigger box: x 120, row $50, 1 x 4 cells, set off by bullet
  ; $ED16 trigger box: x 112, row $51, 3 x 3 cells, set off by blast
  ; $ED1A kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $59, column 20; spawns in view
  ; $ED1E kind $43: trap, behaviour $08; row $5C, column 4; spawns in view,
  ;   1 box
  ; $ED22 trigger box: x 152, row $5A, 1 x 2 cells, set off by punch
  ; $ED26 kind $7C: the countdown bonus stops and pays; row $5D, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $ED2A trigger box: x 0, row $5C, 3 x 4 cells, set off by Rick
  ; $ED2E kind $75: enemy patrols (sprite set 1), patrol 32 px; row $61,
  ;   column 8; spawns in view
  ; $ED32 kind $76: enemy chases (sprite set 1), patrol 8 px; row $61,
  ;   column 21; spawns in view
  ; $ED36 the end
  INCBIN "res/level/sections.bin",$01B1,153

; Section 3's exits: 4, then the 0 end
Section3Exits:
  ; $ED37 flags $02: leaves at the right at row $17 -> section 2, row $5F
  ; $ED3B flags $01: leaves at the left at row $1F -> section 0, row $8F
  ; $ED3F flags $01: leaves at the left at row $67 -> section 9, row $17
  ; $ED43 flags $22: leaves at the right at row $77 -> section 4, row $17;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $ED47 the end
  INCBIN "res/level/sections.bin",$024A,17

; Section 3's map entries: 22, then the 0 end
Section3Objects:
  ; $ED48 kind $11: trap, behaviour $10; row $0E, column 9; spawns on its
  ;   box, 1 box
  ; $ED4C trigger box: x 64, row $0C, 10 x 4 cells, set off by Rick, every
  ;   pass
  ; $ED50 kind $1F: trap, behaviour $00; row $11, column 16; spawns in view
  ; $ED54 kind $04: trap, behaviour $08; row $18, column 24 +4 px; spawns
  ;   in view, 1 box
  ; $ED58 trigger box: x 56, row $0E, 1 x 2 cells, set off by punch
  ; $ED5C kind $20: trap, behaviour $08; row $18, column 10; spawns in
  ;   view, 1 box
  ; $ED60 trigger box: x 24, row $1C, 1 x 4 cells, set off by Rick
  ; $ED64 kind $01: ammunition pickup; row $1D, column 5, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $ED68 trigger box: x 40, row $1D, 3 x 3 cells, set off by Rick
  ; $ED6C kind $16: trap, behaviour $10; row $25, column 18 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $ED70 trigger box: x 128, row $20, 12 x 8 cells, set off by Rick, every
  ;   pass
  ; $ED74 kind $17: trap, behaviour $10; row $31, column 4; spawns on its
  ;   box, 1 box
  ; $ED78 trigger box: x 32, row $2C, 11 x 11 cells, set off by Rick, every
  ;   pass
  ; $ED7C kind $76: enemy chases (sprite set 1), patrol 8 px; row $31,
  ;   column 16; spawns in view
  ; $ED80 kind $01: detonators pickup; row $31, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $ED84 trigger box: x 200, row $31, 3 x 3 cells, set off by Rick
  ; $ED88 kind $78: the countdown bonus starts; row $37, column 8; spawns
  ;   on its box, 1 box
  ; $ED8C trigger box: x 64, row $37, 4 x 1 cells, set off by Rick
  ; $ED90 kind $11: trap, behaviour $10; row $3E, column 9; spawns on its
  ;   box, 1 box
  ; $ED94 trigger box: x 32, row $3A, 10 x 10 cells, set off by Rick, every
  ;   pass
  ; $ED98 kind $11: trap, behaviour $10; row $3E, column 21; spawns on its
  ;   box, 1 box
  ; $ED9C trigger box: x 144, row $3C, 6 x 8 cells, set off by Rick, every
  ;   pass
  ; $EDA0 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $41,
  ;   column 12; spawns in view
  ; $EDA4 kind $2B: trap, behaviour $10; row $4C, column 29, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $EDA8 trigger box: x 168, row $4C, 1 x 4 cells, set off by Rick
  ; $EDAC trigger box: x 104, row $4C, 1 x 4 cells, set off by trap
  ; $EDB0 kind $2B: trap, behaviour $10; row $4C, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EDB4 trigger box: x 104, row $4C, 1 x 4 cells, set off by trap
  ; $EDB8 kind $21: trap, behaviour $10; row $54, column 2; spawns on its
  ;   box, 1 box
  ; $EDBC trigger box: x 120, row $54, 1 x 4 cells, set off by Rick
  ; $EDC0 kind $75: enemy patrols (sprite set 1), patrol 40 px; row $55,
  ;   column 4; spawns in view
  ; $EDC4 kind $22: trap, behaviour $10; row $58, column 28; spawns on its
  ;   box, 1 box
  ; $EDC8 trigger box: x 136, row $5E, 3 x 2 cells, set off by trap
  ; $EDCC kind $7C: the countdown bonus stops and pays; row $65, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $EDD0 trigger box: x 0, row $64, 3 x 4 cells, set off by Rick
  ; $EDD4 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $6D,
  ;   column 4; spawns in view
  ; $EDD8 kind $01: trap, behaviour $18; row $79, column 22, y +3 px;
  ;   spawns in view, 1 box
  ; $EDDC trigger box: x 160, row $7A, 7 x 2 cells, set off by blast
  ; $EDE0 kind $16: trap, behaviour $10; row $79, column 18, y +3 px;
  ;   spawns on its box, 1 box
  ; $EDE4 trigger box: x 128, row $78, 7 x 4 cells, set off by Rick, every
  ;   pass
  ; $EDE8 the end
  INCBIN "res/level/sections.bin",$025B,161

; Section 4's exits: 4, then the 0 end
Section4Exits:
  ; $EDE9 flags $01: leaves at the left at row $17 -> section 3, row $77
  ; $EDED flags $22: leaves at the right at row $17 -> section 5, row $2F;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EDF1 flags $22: leaves at the right at row $23 -> section 5, row $3B;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EDF5 flags $22: leaves at the right at row $33 -> section 5, row $4B;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EDF9 the end
  INCBIN "res/level/sections.bin",$02FC,17

; Section 4's map entries: 10, then the 0 end
Section4Objects:
  ; $EDFA kind $33: trap, behaviour $00; row $0C, column 21; spawns on its
  ;   box, 1 box
  ; $EDFE trigger box: x 168, row $12, 9 x 16 cells, set off by Rick
  ; $EE02 kind $33: trap, behaviour $00; row $11, column 25; spawns in view
  ; $EE06 kind $2D: trap, behaviour $10; row $1D, column 5; spawns on its
  ;   box, 2 boxes
  ; $EE0A trigger box: x 0, row $16, 12 x 16 cells, set off by Rick, every
  ;   pass
  ; $EE0E trigger box: x 0, row $10, 12 x 6 cells, set off by Rick, every
  ;   pass
  ; $EE12 kind $78: the countdown bonus starts; row $23, column 12; spawns
  ;   on its box, 1 box
  ; $EE16 trigger box: x 96, row $22, 1 x 3 cells, set off by bullet
  ; $EE1A kind $2D: trap, behaviour $10; row $25, column 5; spawns on its
  ;   box, 2 boxes
  ; $EE1E trigger box: x 40, row $20, 7 x 14 cells, set off by Rick, every
  ;   pass
  ; $EE22 trigger box: x 40, row $1C, 7 x 4 cells, set off by Rick, every
  ;   pass
  ; $EE26 kind $2D: trap, behaviour $10; row $2D, column 5; spawns on its
  ;   box, 2 boxes
  ; $EE2A trigger box: x 40, row $28, 7 x 12 cells, set off by Rick, every
  ;   pass
  ; $EE2E trigger box: x 40, row $24, 7 x 4 cells, set off by Rick, every
  ;   pass
  ; $EE32 kind $16: trap, behaviour $10; row $31, column 12, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE36 trigger box: x 40, row $2D, 14 x 7 cells, set off by Rick, every
  ;   pass
  ; $EE3A kind $16: trap, behaviour $10; row $31, column 19, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE3E trigger box: x 136, row $30, 9 x 4 cells, set off by Rick, every
  ;   pass
  ; $EE42 kind $16: trap, behaviour $10; row $31, column 26, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE46 trigger box: x 192, row $30, 8 x 4 cells, set off by Rick, every
  ;   pass
  ; $EE4A kind $7C: the countdown bonus stops and pays; row $31, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $EE4E trigger box: x 232, row $30, 3 x 4 cells, set off by Rick
  ; $EE52 the end
  INCBIN "res/level/sections.bin",$030D,89

; Section 5's exits: 4, then the 0 end
Section5Exits:
  ; $EE53 flags $02: leaves at the right at row $17 -> section 6, row $3F
  ; $EE57 flags $21: leaves at the left at row $2F -> section 4, row $17;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EE5B flags $21: leaves at the left at row $3B -> section 4, row $23;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EE5F flags $21: leaves at the left at row $4B -> section 4, row $33;
  ;   bit 5: RideMode $945D = $FF (Rick rides)
  ; $EE63 the end
  INCBIN "res/level/sections.bin",$0366,17

; Section 5's map entries: 15, then the 0 end
Section5Objects:
  ; $EE64 kind $33: trap, behaviour $00; row $0F, column 21; spawns in view
  ; $EE68 kind $79: enemy patrols (sprite set 0), patrol 56 px; row $15,
  ;   column 5; spawns in view
  ; $EE6C kind $01: detonators pickup; row $15, column 8, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EE70 trigger box: x 64, row $15, 3 x 3 cells, set off by Rick
  ; $EE74 kind $37: trap, behaviour $18; row $16, column 28; spawns in
  ;   view, 1 box
  ; $EE78 trigger box: x 32, row $0D, 1 x 2 cells, set off by bullet
  ; $EE7C kind $35: trap, behaviour $00; row $21, column 5; spawns in view
  ; $EE80 kind $26: trap, behaviour $10; row $21, column 19, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE84 trigger box: x 160, row $21, 1 x 1 cells, set off by trap
  ; $EE88 kind $26: trap, behaviour $10; row $21, column 24, y +3 px;
  ;   spawns on its box, 1 box
  ; $EE8C trigger box: x 200, row $21, 1 x 1 cells, set off by trap
  ; $EE90 kind $36: trap, behaviour $10; row $22, column 7, y +3 px; spawns
  ;   on its box, 1 box
  ; $EE94 trigger box: x 64, row $21, 1 x 1 cells, set off by trap
  ; $EE98 kind $2E: trap, behaviour $08; row $35, column 18; spawns in
  ;   view, 1 box
  ; $EE9C trigger box: x 168, row $45, 7 x 1 cells, set off by Rick
  ; $EEA0 kind $2F: trap, behaviour $10; row $36, column 21, y +3 px;
  ;   spawns on its box, 1 box
  ; $EEA4 trigger box: x 176, row $35, 1 x 1 cells, set off by trap
  ; $EEA8 kind $30: trap, behaviour $10; row $36, column 25, y +3 px;
  ;   spawns on its box, 1 box
  ; $EEAC trigger box: x 208, row $35, 1 x 1 cells, set off by trap
  ; $EEB0 kind $79: enemy patrols (sprite set 0), patrol 32 px; row $39,
  ;   column 4; spawns in view
  ; $EEB4 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $39,
  ;   column 13; spawns in view
  ; $EEB8 kind $12: trap, behaviour $10; row $4A, column 24; spawns on its
  ;   box, 2 boxes
  ; $EEBC trigger box: x 32, row $48, 1 x 4 cells, set off by trap
  ; $EEC0 trigger box: x 24, row $48, 1 x 4 cells, set off by Rick
  ; $EEC4 kind $12: trap, behaviour $10; row $4A, column 24; spawns on its
  ;   box, 1 box
  ; $EEC8 trigger box: x 32, row $48, 1 x 4 cells, set off by trap
  ; $EECC the end
  INCBIN "res/level/sections.bin",$0377,105

; Section 6's exits: 1, then the 0 end
Section6Exits:
  ; $EECD flags $02: leaves at the right at row $17 -> section 7, row $2F
  ; $EED1 the end
  INCBIN "res/level/sections.bin",$03E0,5

; Section 6's map entries: 20, then the 0 end
Section6Objects:
  ; $EED2 kind $02: trap, behaviour $00; row $0C, column 14 +4 px; spawns
  ;   in view, 1 box
  ; $EED6 trigger box: x 24, row $0E, 1 x 2 cells, set off by punch
  ; $EEDA kind $7A: enemy chases (sprite set 0), patrol 8 px; row $11,
  ;   column 20; spawns in view
  ; $EEDE kind $79: enemy patrols (sprite set 0), patrol 8 px; row $15,
  ;   column 4; spawns in view
  ; $EEE2 kind $01: trap, behaviour $18; row $15, column 29, y +3 px;
  ;   spawns in view, 1 box
  ; $EEE6 trigger box: x 216, row $16, 3 x 2 cells, set off by blast
  ; $EEEA kind $24: trap, behaviour $08; row $19, column 12; spawns in
  ;   view, 1 box
  ; $EEEE trigger box: x 24, row $22, 1 x 2 cells, set off by punch
  ; $EEF2 kind $26: trap, behaviour $10; row $1D, column 14, y +3 px;
  ;   spawns on its box, 1 box
  ; $EEF6 trigger box: x 120, row $1D, 1 x 1 cells, set off by trap
  ; $EEFA kind $28: trap, behaviour $10; row $1E, column 5, y +3 px; spawns
  ;   on its box, 1 box
  ; $EEFE trigger box: x 48, row $1D, 1 x 1 cells, set off by trap
  ; $EF02 kind $29: trap, behaviour $00; row $21, column 29; spawns in view
  ; $EF06 kind $28: trap, behaviour $10; row $22, column 20, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF0A trigger box: x 168, row $21, 1 x 1 cells, set off by trap
  ; $EF0E kind $7C: the countdown bonus stops and pays; row $29, column 4;
  ;   spawns on its box, one-shot, 1 box
  ; $EF12 trigger box: x 32, row $28, 4 x 3 cells, set off by Rick
  ; $EF16 kind $2A: trap, behaviour $10; row $30, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF1A trigger box: x 88, row $30, 1 x 4 cells, set off by trap
  ; $EF1E kind $2A: trap, behaviour $10; row $30, column 29, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $EF22 trigger box: x 96, row $35, 16 x 3 cells, set off by Rick
  ; $EF26 trigger box: x 88, row $30, 1 x 4 cells, set off by trap
  ; $EF2A kind $78: the countdown bonus starts; row $30, column 4; spawns
  ;   on its box, 1 box
  ; $EF2E trigger box: x 32, row $30, 4 x 4 cells, set off by Rick
  ; $EF32 kind $27: trap, behaviour $10; row $3C, column 24, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF36 trigger box: x 184, row $3D, 1 x 1 cells, set off by trap
  ; $EF3A kind $25: trap, behaviour $00; row $41, column 29; spawns on its
  ;   box, 1 box
  ; $EF3E trigger box: x 40, row $42, 3 x 1 cells, set off by Rick
  ; $EF42 kind $26: trap, behaviour $10; row $41, column 19, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF46 trigger box: x 160, row $41, 1 x 1 cells, set off by trap
  ; $EF4A kind $11: trap, behaviour $10; row $46, column 13; spawns on its
  ;   box, 1 box
  ; $EF4E trigger box: x 40, row $44, 13 x 8 cells, set off by Rick, every
  ;   pass
  ; $EF52 kind $76: enemy chases (sprite set 1), patrol 8 px; row $49,
  ;   column 16; spawns in view
  ; $EF56 kind $23: trap, behaviour $00; row $49, column 20; spawns in view
  ; $EF5A kind $01: ammunition pickup; row $49, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EF5E trigger box: x 200, row $49, 3 x 3 cells, set off by Rick
  ; $EF62 the end
  INCBIN "res/level/sections.bin",$03E5,145

; Section 7's exits: 1, then the 0 end
Section7Exits:
  ; $EF63 flags $82: leaves at the right at row $17 -> section 10, row $D7;
  ;   bit 7: ends the level; with CheatExits ($8067 bit 7) a passage into
  ;   section 10
  ; $EF67 the end
  INCBIN "res/level/sections.bin",$0476,5

; Section 7's map entries: 10, then the 0 end
Section7Objects:
  ; $EF68 kind $16: trap, behaviour $10; row $0D, column 16 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $EF6C trigger box: x 104, row $0C, 9 x 8 cells, set off by Rick, every
  ;   pass
  ; $EF70 kind $79: enemy patrols (sprite set 0), patrol 24 px; row $11,
  ;   column 8; spawns in view
  ; $EF74 kind $77: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 24; spawns in view
  ; $EF78 kind $01: treasure pickup; row $19, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EF7C trigger box: x 168, row $19, 3 x 3 cells, set off by Rick
  ; $EF80 kind $1A: trap, behaviour $10; row $1E, column 4; spawns on its
  ;   box, 1 box
  ; $EF84 trigger box: x 32, row $1A, 4 x 14 cells, set off by Rick, every
  ;   pass
  ; $EF88 kind $02: trap, behaviour $00; row $24, column 18 +4 px; spawns
  ;   in view
  ; $EF8C kind $02: trap, behaviour $00; row $24, column 10 +4 px; spawns
  ;   in view
  ; $EF90 kind $0A: trap, behaviour $10; row $2E, column 8; spawns on its
  ;   box, 1 box
  ; $EF94 trigger box: x 48, row $2C, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $EF98 kind $0A: trap, behaviour $10; row $2E, column 14; spawns on its
  ;   box, 1 box
  ; $EF9C trigger box: x 48, row $2C, 16 x 7 cells, set off by Rick, every
  ;   pass
  ; $EFA0 kind $7B: enemy wanders and climbs after Rick (sprite set 0),
  ;   patrol 8 px; row $31, column 20; spawns in view
  ; $EFA4 the end
  INCBIN "res/level/sections.bin",$047B,61

; Section 8's exits: 1, then the 0 end
Section8Exits:
  ; $EFA5 flags $02: leaves at the right at row $17 -> section 0, row $47
  ; $EFA9 the end
  INCBIN "res/level/sections.bin",$04B8,5

; Section 8's map entries: 5, then the 0 end
Section8Objects:
  ; $EFAA kind $01: treasure pickup; row $15, column 22, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFAE trigger box: x 176, row $15, 3 x 3 cells, set off by Rick
  ; $EFB2 kind $01: treasure pickup; row $15, column 8, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFB6 trigger box: x 64, row $15, 3 x 3 cells, set off by Rick
  ; $EFBA kind $01: ammunition pickup; row $19, column 17, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EFBE trigger box: x 136, row $19, 3 x 3 cells, set off by Rick
  ; $EFC2 kind $01: detonators pickup; row $19, column 4, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EFC6 trigger box: x 32, row $19, 3 x 3 cells, set off by Rick
  ; $EFCA kind $01: treasure pickup; row $19, column 13, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFCE trigger box: x 104, row $19, 3 x 3 cells, set off by Rick
  ; $EFD2 the end
  INCBIN "res/level/sections.bin",$04BD,41

; Section 9's exits: 1, then the 0 end
Section9Exits:
  ; $EFD3 flags $02: leaves at the right at row $17 -> section 3, row $67
  ; $EFD7 the end
  INCBIN "res/level/sections.bin",$04E6,5

; Section 9's map entries: 5, then the 0 end
Section9Objects:
  ; $EFD8 kind $01: treasure pickup; row $0D, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFDC trigger box: x 200, row $0D, 3 x 3 cells, set off by Rick
  ; $EFE0 kind $01: treasure pickup; row $11, column 12, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFE4 trigger box: x 96, row $11, 3 x 3 cells, set off by Rick
  ; $EFE8 kind $01: treasure pickup; row $11, column 17, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $EFEC trigger box: x 136, row $11, 3 x 3 cells, set off by Rick
  ; $EFF0 kind $01: ammunition pickup; row $15, column 4, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EFF4 trigger box: x 32, row $15, 3 x 3 cells, set off by Rick
  ; $EFF8 kind $01: detonators pickup; row $19, column 20, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $EFFC trigger box: x 160, row $19, 3 x 3 cells, set off by Rick
  ; $F000 the end
  INCBIN "res/level/sections.bin",$04EB,41

; Section 10's exits: 4, then the 0 end
Section10Exits:
  ; $F001 flags $92: leaves at the right at row $1B -> section 0, row $1B;
  ;   bit 7 + bit 4: ends the level (also with CheatExits)
  ; $F005 flags $01: leaves at the left at row $6F -> section 11, row $17
  ; $F009 flags $02: leaves at the right at row $6F -> section 12, row $3F
  ; $F00D flags $01: leaves at the left at row $8F -> section 11, row $2F
  ; $F011 the end
  INCBIN "res/level/sections.bin",$0514,17

; Section 10's map entries: 47, then the 0 end
Section10Objects:
  ; $F012 kind $01: detonators pickup; row $0D, column 25, y +3 px; spawns
  ;   in view, 1 box
  ; $F016 trigger box: x 200, row $0D, 3 x 3 cells, set off by Rick
  ; $F01A kind $01: treasure pickup; row $11, column 18, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F01E trigger box: x 144, row $11, 3 x 3 cells, set off by Rick
  ; $F022 kind $3B: trap, behaviour $24; row $18, column 8 +4 px; spawns in
  ;   view, 2 boxes
  ; $F026 trigger box: x 224, row $22, 1 x 2 cells, set off by punch
  ; $F02A trigger box: x 24, row $12, 1 x 2 cells, set off by punch
  ; $F02E kind $01: trap, behaviour $18; row $19, column 12, y +3 px;
  ;   spawns in view, 1 box
  ; $F032 trigger box: x 80, row $1A, 7 x 2 cells, set off by blast
  ; $F036 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $19, column 24; spawns in view
  ; $F03A kind $7C: the countdown bonus stops and pays; row $19, column 29;
  ;   spawns on its box, one-shot, 1 box
  ; $F03E trigger box: x 232, row $18, 3 x 4 cells, set off by Rick
  ; $F042 kind $3C: trap, behaviour $18; row $1A, column 20; spawns in
  ;   view, 1 box
  ; $F046 trigger box: x 144, row $1A, 3 x 2 cells, set off by blast
  ; $F04A kind $7D: enemy patrols (sprite set 1), patrol 56 px; row $21,
  ;   column 12; spawns in view
  ; $F04E kind $01: ammunition pickup; row $29, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $F052 trigger box: x 64, row $29, 3 x 3 cells, set off by Rick
  ; $F056 kind $3E: trap, behaviour $24; row $32, column 15; spawns in
  ;   view, 2 boxes
  ; $F05A trigger box: x 32, row $3A, 1 x 2 cells, set off by punch
  ; $F05E trigger box: x 224, row $3A, 1 x 2 cells, set off by punch
  ; $F062 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $39,
  ;   column 20; spawns in view
  ; $F066 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $39,
  ;   column 5; spawns in view
  ; $F06A kind $78: the countdown bonus starts; row $3D, column 16; spawns
  ;   on its box, 1 box
  ; $F06E trigger box: x 104, row $3C, 7 x 2 cells, set off by Rick
  ; $F072 kind $3D: trap, behaviour $00; row $42, column 16; spawns in view
  ; $F076 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $4D,
  ;   column 12; spawns in view
  ; $F07A kind $17: trap, behaviour $10; row $52, column 4; spawns on its
  ;   box, 1 box
  ; $F07E trigger box: x 32, row $4E, 12 x 10 cells, set off by Rick, every
  ;   pass
  ; $F082 kind $17: trap, behaviour $10; row $52, column 20; spawns on its
  ;   box, 1 box
  ; $F086 trigger box: x 128, row $4E, 12 x 10 cells, set off by Rick,
  ;   every pass
  ; $F08A kind $7D: enemy patrols (sprite set 1), patrol 56 px; row $55,
  ;   column 8; spawns in view
  ; $F08E kind $7D: enemy patrols (sprite set 1), patrol 32 px; row $5D,
  ;   column 8; spawns in view
  ; $F092 kind $40: trap, behaviour $00; row $64, column 25; spawns in view
  ; $F096 kind $16: trap, behaviour $10; row $69, column 10, y +3 px;
  ;   spawns on its box, 1 box
  ; $F09A trigger box: x 64, row $68, 7 x 4 cells, set off by Rick, every
  ;   pass
  ; $F09E kind $16: trap, behaviour $10; row $69, column 19, y +3 px;
  ;   spawns on its box, 1 box
  ; $F0A2 trigger box: x 136, row $68, 7 x 4 cells, set off by Rick, every
  ;   pass
  ; $F0A6 kind $01: ammunition pickup; row $69, column 15, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F0AA trigger box: x 120, row $69, 3 x 3 cells, set off by Rick
  ; $F0AE kind $04: trap, behaviour $18; row $70, column 25; spawns in
  ;   view, 1 box
  ; $F0B2 trigger box: x 200, row $6E, 4 x 2 cells, set off by blast
  ; $F0B6 kind $01: treasure pickup; row $7D, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F0BA trigger box: x 168, row $7D, 3 x 3 cells, set off by Rick
  ; $F0BE kind $01: treasure pickup; row $7D, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F0C2 trigger box: x 200, row $7D, 3 x 3 cells, set off by Rick
  ; $F0C6 kind $3F: trap, behaviour $10; row $86, column 2; spawns on its
  ;   box, 2 boxes
  ; $F0CA trigger box: x 184, row $90, 5 x 9 cells, set off by Rick
  ; $F0CE trigger box: x 160, row $98, 2 x 1 cells, set off by trap
  ; $F0D2 kind $3F: trap, behaviour $10; row $86, column 2; spawns on its
  ;   box, 1 box
  ; $F0D6 trigger box: x 160, row $98, 2 x 1 cells, set off by trap
  ; $F0DA kind $01: treasure pickup; row $89, column 21, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F0DE trigger box: x 168, row $89, 3 x 3 cells, set off by Rick
  ; $F0E2 kind $01: treasure pickup; row $89, column 25, y +3 px; spawns in
  ;   view, one-shot, 1 box
  ; $F0E6 trigger box: x 200, row $89, 3 x 3 cells, set off by Rick
  ; $F0EA kind $08: trap, behaviour $10; row $8C, column 17; spawns on its
  ;   box, 1 box
  ; $F0EE trigger box: x 224, row $8A, 1 x 2 cells, set off by punch
  ; $F0F2 kind $7C: the countdown bonus stops and pays; row $8C, column 0;
  ;   spawns on its box, one-shot, 1 box
  ; $F0F6 trigger box: x 0, row $8C, 3 x 4 cells, set off by Rick
  ; $F0FA kind $3A: trap, behaviour $00; row $A5, column 29; spawns in view
  ; $F0FE kind $30: trap, behaviour $10; row $A6, column 14, y +3 px;
  ;   spawns on its box, 1 box
  ; $F102 trigger box: x 120, row $A5, 1 x 1 cells, set off by trap
  ; $F106 kind $30: trap, behaviour $10; row $A6, column 5, y +3 px; spawns
  ;   on its box, 1 box
  ; $F10A trigger box: x 48, row $A5, 1 x 1 cells, set off by trap
  ; $F10E kind $39: trap, behaviour $00; row $B1, column 29; spawns in view
  ; $F112 kind $38: trap, behaviour $00; row $B1, column 0; spawns on its
  ;   box, 1 box
  ; $F116 trigger box: x 24, row $B6, 1 x 2 cells, set off by punch
  ; $F11A kind $28: trap, behaviour $10; row $B2, column 20, y +3 px;
  ;   spawns on its box, 1 box
  ; $F11E trigger box: x 168, row $B1, 1 x 1 cells, set off by trap
  ; $F122 kind $28: trap, behaviour $10; row $B2, column 10, y +3 px;
  ;   spawns on its box, 1 box
  ; $F126 trigger box: x 88, row $B1, 1 x 1 cells, set off by trap
  ; $F12A kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $BE, column 25; spawns in view
  ; $F12E kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $BE,
  ;   column 7; spawns in view
  ; $F132 kind $01: detonators pickup; row $BE, column 25, y +3 px; spawns
  ;   in view, one-shot, 1 box
  ; $F136 trigger box: x 200, row $BE, 3 x 3 cells, set off by Rick
  ; $F13A kind $2C: trap, behaviour $24; row $C8, column 21, y +3 px;
  ;   spawns in view, 1 box
  ; $F13E trigger box: x 224, row $C7, 1 x 2 cells, set off by punch
  ; $F142 kind $78: the countdown bonus starts; row $D5, column 25; spawns
  ;   on its box, 1 box
  ; $F146 trigger box: x 192, row $D4, 4 x 4 cells, set off by Rick
  ; $F14A kind $11: trap, behaviour $10; row $DA, column 5; spawns on its
  ;   box, 1 box
  ; $F14E trigger box: x 16, row $D2, 8 x 9 cells, set off by Rick, every
  ;   pass
  ; $F152 kind $11: trap, behaviour $10; row $DA, column 13; spawns on its
  ;   box, 1 box
  ; $F156 trigger box: x 80, row $D2, 8 x 9 cells, set off by Rick, every
  ;   pass
  ; $F15A kind $11: trap, behaviour $10; row $DA, column 21; spawns on its
  ;   box, 1 box
  ; $F15E trigger box: x 144, row $D2, 8 x 9 cells, set off by Rick, every
  ;   pass
  ; $F162 the end
  INCBIN "res/level/sections.bin",$0525,337

; Section 11's exits: 2, then the 0 end
Section11Exits:
  ; $F163 flags $02: leaves at the right at row $17 -> section 10, row $6F
  ; $F167 flags $02: leaves at the right at row $2F -> section 10, row $8F
  ; $F16B the end
  INCBIN "res/level/sections.bin",$0676,9

; Section 11's map entries: 12, then the 0 end
Section11Objects:
  ; $F16C kind $01: trap, behaviour $18; row $0D, column 8, y +3 px; spawns
  ;   in view, 1 box
  ; $F170 trigger box: x 40, row $0E, 8 x 3 cells, set off by blast
  ; $F174 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $0D,
  ;   column 14; spawns in view
  ; $F178 kind $40: trap, behaviour $00; row $10, column 5; spawns in view
  ; $F17C kind $16: trap, behaviour $10; row $11, column 21 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $F180 trigger box: x 144, row $0C, 10 x 8 cells, set off by Rick, every
  ;   pass
  ; $F184 kind $04: trap, behaviour $18; row $14, column 25; spawns in
  ;   view, 1 box
  ; $F188 trigger box: x 192, row $12, 4 x 2 cells, set off by blast
  ; $F18C kind $40: trap, behaviour $00; row $18, column 17; spawns in view
  ; $F190 kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $21,
  ;   column 8; spawns in view
  ; $F194 kind $2D: trap, behaviour $10; row $2A, column 5; spawns on its
  ;   box, 1 box
  ; $F198 trigger box: x 40, row $26, 7 x 10 cells, set off by Rick, every
  ;   pass
  ; $F19C kind $0A: trap, behaviour $10; row $2E, column 16; spawns on its
  ;   box, 1 box
  ; $F1A0 trigger box: x 64, row $2C, 16 x 4 cells, set off by Rick, every
  ;   pass
  ; $F1A4 kind $0A: trap, behaviour $10; row $2E, column 10; spawns on its
  ;   box, 1 box
  ; $F1A8 trigger box: x 64, row $2C, 16 x 4 cells, set off by Rick, every
  ;   pass
  ; $F1AC kind $41: trap, behaviour $24; row $30, column 5; spawns in view,
  ;   1 box
  ; $F1B0 trigger box: x 32, row $2E, 1 x 2 cells, set off by punch
  ; $F1B4 kind $16: trap, behaviour $10; row $31, column 24 +4 px, y +3 px;
  ;   spawns on its box, 1 box
  ; $F1B8 trigger box: x 160, row $2C, 12 x 8 cells, set off by Rick, every
  ;   pass
  ; $F1BC the end
  INCBIN "res/level/sections.bin",$067F,81

; Section 12's exits: 2, then the 0 end
Section12Exits:
  ; $F1BD flags $01: leaves at the left at row $17 -> section 10, row $47
  ; $F1C1 flags $01: leaves at the left at row $3F -> section 10, row $6F
  ; $F1C5 the end
  INCBIN "res/level/sections.bin",$06D0,9

; Section 12's map entries: 16, then the 0 end
Section12Objects:
  ; $F1C6 kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $11,
  ;   column 16; spawns in view, one-shot
  ; $F1CA kind $07: trap, behaviour $08; row $12, column 9; spawns in view,
  ;   1 box
  ; $F1CE trigger box: x 56, row $10, 7 x 3 cells, set off by blast
  ; $F1D2 kind $7E: enemy chases (sprite set 1), patrol 8 px; row $15,
  ;   column 0; spawns in view
  ; $F1D6 kind $7F: enemy wanders and climbs after Rick (sprite set 1),
  ;   patrol 8 px; row $15, column 5; spawns in view
  ; $F1DA kind $1A: trap, behaviour $0C; row $1A, column 24; spawns in
  ;   view, 1 box
  ; $F1DE trigger box: x 160, row $19, 1 x 3 cells, set off by bullet
  ; $F1E2 kind $2A: trap, behaviour $10; row $20, column 29, y +3 px;
  ;   spawns on its box, 2 boxes
  ; $F1E6 trigger box: x 96, row $20, 1 x 4 cells, set off by trap
  ; $F1EA trigger box: x 88, row $25, 10 x 3 cells, set off by Rick
  ; $F1EE kind $2A: trap, behaviour $10; row $20, column 29, y +3 px;
  ;   spawns on its box, 1 box
  ; $F1F2 trigger box: x 96, row $20, 1 x 4 cells, set off by trap
  ; $F1F6 kind $17: trap, behaviour $10; row $2A, column 20; spawns on its
  ;   box, 1 box
  ; $F1FA trigger box: x 160, row $28, 8 x 8 cells, set off by Rick, every
  ;   pass
  ; $F1FE kind $17: trap, behaviour $10; row $2A, column 4; spawns on its
  ;   box, 1 box
  ; $F202 trigger box: x 32, row $28, 8 x 8 cells, set off by Rick, every
  ;   pass
  ; $F206 kind $7D: enemy patrols (sprite set 1), patrol 40 px; row $31,
  ;   column 4; spawns in view
  ; $F20A kind $7D: enemy patrols (sprite set 1), patrol 24 px; row $31,
  ;   column 20; spawns in view
  ; $F20E kind $40: trap, behaviour $00; row $3E, column 25; spawns in view
  ; $F212 kind $41: trap, behaviour $24; row $40, column 17; spawns in
  ;   view, 1 box
  ; $F216 trigger box: x 128, row $3E, 1 x 2 cells, set off by punch
  ; $F21A kind $2D: trap, behaviour $10; row $44, column 5; spawns on its
  ;   box, 1 box
  ; $F21E trigger box: x 24, row $3C, 9 x 13 cells, set off by Rick, every
  ;   pass
  ; $F222 kind $16: trap, behaviour $00; row $49, column 7, y +3 px; spawns
  ;   in view
  ; $F226 kind $42: trap, behaviour $08; row $4A, column 26; spawns in
  ;   view, 1 box
  ; $F22A trigger box: x 176, row $48, 1 x 4 cells, set off by Rick
  INCBIN "res/level/sections.bin",$06D9,103
