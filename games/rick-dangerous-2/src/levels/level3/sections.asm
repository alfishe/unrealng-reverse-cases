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
  INCBIN "res/level/sections.bin",$0079,69

; Section 1's exits: 4, then the 0 end
Section1Exits:
  INCBIN "res/level/sections.bin",$00BE,17

; Section 1's map entries: 33, then the 0 end
Section1Objects:
  INCBIN "res/level/sections.bin",$00CF,221

; Section 2's exits: 6, then the 0 end
Section2Exits:
  INCBIN "res/level/sections.bin",$01AC,25

; Section 2's map entries: 29, then the 0 end
Section2Objects:
  INCBIN "res/level/sections.bin",$01C5,221

; Section 3's exits: 6, then the 0 end
Section3Exits:
  INCBIN "res/level/sections.bin",$02A2,25

; Section 3's map entries: 42, then the 0 end
Section3Objects:
  INCBIN "res/level/sections.bin",$02BB,337

; Section 4's exits: 2, then the 0 end
Section4Exits:
  INCBIN "res/level/sections.bin",$040C,9

; Section 4's map entries: 2, then the 0 end
Section4Objects:
  INCBIN "res/level/sections.bin",$0415,25

; Section 5's exits: 2, then the 0 end
Section5Exits:
  INCBIN "res/level/sections.bin",$042E,9

; Section 5's map entries: 5, then the 0 end
Section5Objects:
  INCBIN "res/level/sections.bin",$0437,29

; Section 6's exits: 3, then the 0 end
Section6Exits:
  INCBIN "res/level/sections.bin",$0454,13

; Section 6's map entries: 39, then the 0 end
Section6Objects:
  INCBIN "res/level/sections.bin",$0461,305

; Section 7's exits: 2, then the 0 end
Section7Exits:
  INCBIN "res/level/sections.bin",$0592,9

; Section 7's map entries: 5, then the 0 end
Section7Objects:
  INCBIN "res/level/sections.bin",$059B,33

; Section 8's exits: 2, then the 0 end
Section8Exits:
  INCBIN "res/level/sections.bin",$05BC,9

; Section 8's map entries: 31, then the 0 end
Section8Objects:
  INCBIN "res/level/sections.bin",$05C5,225

; Section 9's exits: 1, then the 0 end
Section9Exits:
  INCBIN "res/level/sections.bin",$06A6,5

; Section 9's map entries: 19, then the 0 end
Section9Objects:
  INCBIN "res/level/sections.bin",$06AB,133

; The filler entries' lists: a 0 exit list and a 0 entry list each
;
; 6 bytes, two for each filler entry from 10 (the last one's two bytes are the
; first word of KindTable).
FillerSectionLists:
  INCBIN "res/level/sections.bin",$0730,6
