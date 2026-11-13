; --------------------------------------------------------------------------------------------------------------------
; kinds.asm: The trap kinds: the kind table, the animation scripts, the paths and the kind records
; --------------------------------------------------------------------------------------------------------------------

; A word a kind (0-54): the address of its record
;
; LevelHeader+0 points here. SpawnMapObject $9D6C takes the word at KindTable +
; 2 x the map entry's kind (below $74) for a trap or pickup. Kind 0 is never
; used (its word is $0041); kinds 4, 14, 35, 37 have records but no map entry
; uses them.
KindTable:
  INCBIN "res/level/kinds.bin",$0000,110

; The animation scripts of the trap kinds
;
; Read by AnimateTrap $A608 from a record's +$0A/+$0B: a byte below $80 is a
; frame (SpriteFrameMap: the sprite, bit 7 mirrored; frame $7F hides the
; object) shown one pass; $80 + n then a frame: that frame for n more passes;
; $FD n plays effect n; $FF and a word jumps there (every script ends in one).
; A kind record gives the first script (+5/+6) and the one after the switch
; (+9/+10).
TrapAnims:
  INCBIN "res/level/anims.bin",$0000,362

; The paths of the trap kinds
;
; Read by UpdateTrap $A2F7 from a record's +$0F/+$10: pairs of a count and a
; step (the high nibble the x step, the low nibble the y step, each signed, 7
; meaning 8 pixels) applied once a pass count times; $FF n plays effect n; 0
; and a word jumps there (the loop point: a one-shot trap ends there, a waiting
; trap switches to its second path). A kind record gives the first path (+3/+4)
; and the second (+7/+8).
TrapPaths:
  INCBIN "res/level/paths.bin",$0000,653

; The kind records: 11 bytes, or 7 for a kind that never switches
;
; KindTable points to each. +0 the width, +1 the height (record +7, +8); +2
; bits 6-7 into the record's +0 (bit 6 deadly to Rick and the enemies, bit 7
; the detonator test), bits 0-5 x 4 the behaviour after the switch (record
; +$15); +3/+4 the path, +5/+6 the animation; +7/+8 the second path, +9/+10 the
; second animation (SwitchTrapPath $A4D5 swaps them in). A record followed 7
; bytes later by the next one has no second half of its own: its +7..+10 are
; the next record's first bytes, which no switch reads for such a kind (or the
; switch would take them).
KindRecords:
Kind1:
  INCBIN "res/level/kinds-2.bin",$0000,7
Kind2:
  INCBIN "res/level/kinds-2.bin",$0007,11
Kind3:
  INCBIN "res/level/kinds-2.bin",$0012,7
Kind4:
  INCBIN "res/level/kinds-2.bin",$0019,11
Kind5:
  INCBIN "res/level/kinds-2.bin",$0024,7
Kind6:
  INCBIN "res/level/kinds-2.bin",$002B,7
Kind7:
  INCBIN "res/level/kinds-2.bin",$0032,7
Kind8:
  INCBIN "res/level/kinds-2.bin",$0039,11
Kind9:
  INCBIN "res/level/kinds-2.bin",$0044,11
Kind10:
  INCBIN "res/level/kinds-2.bin",$004F,11
Kind11:
  INCBIN "res/level/kinds-2.bin",$005A,7
Kind12:
  INCBIN "res/level/kinds-2.bin",$0061,7
Kind13:
  INCBIN "res/level/kinds-2.bin",$0068,7
Kind14:
  INCBIN "res/level/kinds-2.bin",$006F,7
Kind15:
  INCBIN "res/level/kinds-2.bin",$0076,11
Kind16:
  INCBIN "res/level/kinds-2.bin",$0081,7
Kind17:
  INCBIN "res/level/kinds-2.bin",$0088,7
Kind18:
  INCBIN "res/level/kinds-2.bin",$008F,7
Kind19:
  INCBIN "res/level/kinds-2.bin",$0096,11
Kind20:
  INCBIN "res/level/kinds-2.bin",$00A1,7
Kind21:
  INCBIN "res/level/kinds-2.bin",$00A8,7
Kind22:
  INCBIN "res/level/kinds-2.bin",$00AF,7
Kind23:
  INCBIN "res/level/kinds-2.bin",$00B6,7
Kind24:
  INCBIN "res/level/kinds-2.bin",$00BD,11
Kind25:
  INCBIN "res/level/kinds-2.bin",$00C8,7
Kind26:
  INCBIN "res/level/kinds-2.bin",$00CF,7
Kind27:
  INCBIN "res/level/kinds-2.bin",$00D6,7
Kind28:
  INCBIN "res/level/kinds-2.bin",$00DD,11
Kind29:
  INCBIN "res/level/kinds-2.bin",$00E8,7
Kind30:
  INCBIN "res/level/kinds-2.bin",$00EF,7
Kind31:
  INCBIN "res/level/kinds-2.bin",$00F6,7
Kind32:
  INCBIN "res/level/kinds-2.bin",$00FD,7
Kind33:
  INCBIN "res/level/kinds-2.bin",$0104,7
Kind34:
  INCBIN "res/level/kinds-2.bin",$010B,7
Kind35:
  INCBIN "res/level/kinds-2.bin",$0112,11
Kind36:
  INCBIN "res/level/kinds-2.bin",$011D,11
Kind37:
  INCBIN "res/level/kinds-2.bin",$0128,7
Kind38:
  INCBIN "res/level/kinds-2.bin",$012F,11
Kind39:
  INCBIN "res/level/kinds-2.bin",$013A,7
Kind40:
  INCBIN "res/level/kinds-2.bin",$0141,7
Kind41:
  INCBIN "res/level/kinds-2.bin",$0148,7
Kind42:
  INCBIN "res/level/kinds-2.bin",$014F,7
Kind43:
  INCBIN "res/level/kinds-2.bin",$0156,7
Kind44:
  INCBIN "res/level/kinds-2.bin",$015D,7
Kind45:
  INCBIN "res/level/kinds-2.bin",$0164,7
Kind46:
  INCBIN "res/level/kinds-2.bin",$016B,11
Kind47:
  INCBIN "res/level/kinds-2.bin",$0176,7
Kind48:
  INCBIN "res/level/kinds-2.bin",$017D,7
Kind49:
  INCBIN "res/level/kinds-2.bin",$0184,7
Kind50:
  INCBIN "res/level/kinds-2.bin",$018B,7
Kind51:
  INCBIN "res/level/kinds-2.bin",$0192,7
Kind52:
  INCBIN "res/level/kinds-2.bin",$0199,11
Kind53:
  INCBIN "res/level/kinds-2.bin",$01A4,7
Kind54:
  INCBIN "res/level/kinds-2.bin",$01AB,11
