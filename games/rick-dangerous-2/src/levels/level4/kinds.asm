; --------------------------------------------------------------------------------------------------------------------
; kinds.asm: The trap kinds: the kind table, the animation scripts, the paths and the kind records
; --------------------------------------------------------------------------------------------------------------------

; A word a kind (0-68): the address of its record
;
; LevelHeader+0 points here. SpawnMapObject $9D6C takes the word at KindTable +
; 2 x the map entry's kind (below $74) for a trap or pickup. Kind 0 is never
; used (its word is $0001); kinds 13, 16, 24, 25, 28, 29, 49, 50, 52 have
; records but no map entry uses them.
KindTable:
  INCBIN "res/level/kinds.bin",$0000,138

; The animation scripts of the trap kinds
;
; Read by AnimateTrap $A608 from a record's +$0A/+$0B: a byte below $80 is a
; frame (SpriteFrameMap: the sprite, bit 7 mirrored; frame $7F hides the
; object) shown one pass; $80 + n then a frame: that frame for n more passes;
; $FD n plays effect n; $FF and a word jumps there (every script ends in one).
; A kind record gives the first script (+5/+6) and the one after the switch
; (+9/+10).
TrapAnims:
  INCBIN "res/level/anims.bin",$0000,918

; The paths of the trap kinds
;
; Read by UpdateTrap $A2F7 from a record's +$0F/+$10: pairs of a count and a
; step (the high nibble the x step, the low nibble the y step, each signed, 7
; meaning 8 pixels) applied once a pass count times; $FF n plays effect n; 0
; and a word jumps there (the loop point: a one-shot trap ends there, a waiting
; trap switches to its second path). A kind record gives the first path (+3/+4)
; and the second (+7/+8).
TrapPaths:
  INCBIN "res/level/paths.bin",$0000,1151

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
  INCBIN "res/level/kinds-2.bin",$0000,11
Kind2:
  INCBIN "res/level/kinds-2.bin",$000B,7
Kind3:
  INCBIN "res/level/kinds-2.bin",$0012,7
Kind4:
  INCBIN "res/level/kinds-2.bin",$0019,11
Kind5:
  INCBIN "res/level/kinds-2.bin",$0024,11
Kind6:
  INCBIN "res/level/kinds-2.bin",$002F,11
Kind7:
  INCBIN "res/level/kinds-2.bin",$003A,11
Kind8:
  INCBIN "res/level/kinds-2.bin",$0045,7
Kind9:
  INCBIN "res/level/kinds-2.bin",$004C,7
Kind10:
  INCBIN "res/level/kinds-2.bin",$0053,7
Kind11:
  INCBIN "res/level/kinds-2.bin",$005A,11
Kind12:
  INCBIN "res/level/kinds-2.bin",$0065,11
Kind13:
  INCBIN "res/level/kinds-2.bin",$0070,11
Kind14:
  INCBIN "res/level/kinds-2.bin",$007B,11
Kind15:
  INCBIN "res/level/kinds-2.bin",$0086,11
Kind16:
  INCBIN "res/level/kinds-2.bin",$0091,7
Kind17:
  INCBIN "res/level/kinds-2.bin",$0098,7
Kind18:
  INCBIN "res/level/kinds-2.bin",$009F,7
Kind19:
  INCBIN "res/level/kinds-2.bin",$00A6,11
Kind20:
  INCBIN "res/level/kinds-2.bin",$00B1,11
Kind21:
  INCBIN "res/level/kinds-2.bin",$00BC,11
Kind22:
  INCBIN "res/level/kinds-2.bin",$00C7,7
Kind23:
  INCBIN "res/level/kinds-2.bin",$00CE,7
Kind24:
  INCBIN "res/level/kinds-2.bin",$00D5,11
Kind25:
  INCBIN "res/level/kinds-2.bin",$00E0,7
Kind26:
  INCBIN "res/level/kinds-2.bin",$00E7,7
Kind27:
  INCBIN "res/level/kinds-2.bin",$00EE,11
Kind28:
  INCBIN "res/level/kinds-2.bin",$00F9,7
Kind29:
  INCBIN "res/level/kinds-2.bin",$0100,11
Kind30:
  INCBIN "res/level/kinds-2.bin",$010B,7
Kind31:
  INCBIN "res/level/kinds-2.bin",$0112,7
Kind32:
  INCBIN "res/level/kinds-2.bin",$0119,11
Kind33:
  INCBIN "res/level/kinds-2.bin",$0124,7
Kind34:
  INCBIN "res/level/kinds-2.bin",$012B,7
Kind35:
  INCBIN "res/level/kinds-2.bin",$0132,7
Kind36:
  INCBIN "res/level/kinds-2.bin",$0139,7
Kind37:
  INCBIN "res/level/kinds-2.bin",$0140,7
Kind38:
  INCBIN "res/level/kinds-2.bin",$0147,7
Kind39:
  INCBIN "res/level/kinds-2.bin",$014E,7
Kind40:
  INCBIN "res/level/kinds-2.bin",$0155,7
Kind41:
  INCBIN "res/level/kinds-2.bin",$015C,7
Kind42:
  INCBIN "res/level/kinds-2.bin",$0163,7
Kind43:
  INCBIN "res/level/kinds-2.bin",$016A,7
Kind44:
  INCBIN "res/level/kinds-2.bin",$0171,11
Kind45:
  INCBIN "res/level/kinds-2.bin",$017C,7
Kind46:
  INCBIN "res/level/kinds-2.bin",$0183,11
Kind47:
  INCBIN "res/level/kinds-2.bin",$018E,7
Kind48:
  INCBIN "res/level/kinds-2.bin",$0195,7
Kind49:
  INCBIN "res/level/kinds-2.bin",$019C,7
Kind52:
  INCBIN "res/level/kinds-2.bin",$01A3,7
Kind54:
  INCBIN "res/level/kinds-2.bin",$01AA,7
Kind55:
  INCBIN "res/level/kinds-2.bin",$01B1,11
Kind56:
  INCBIN "res/level/kinds-2.bin",$01BC,7
Kind57:
  INCBIN "res/level/kinds-2.bin",$01C3,7
Kind58:
  INCBIN "res/level/kinds-2.bin",$01CA,7
Kind59:
  INCBIN "res/level/kinds-2.bin",$01D1,11
Kind60:
  INCBIN "res/level/kinds-2.bin",$01DC,11
Kind61:
  INCBIN "res/level/kinds-2.bin",$01E7,7
Kind62:
  INCBIN "res/level/kinds-2.bin",$01EE,11
Kind63:
  INCBIN "res/level/kinds-2.bin",$01F9,7
Kind64:
  INCBIN "res/level/kinds-2.bin",$0200,7
Kind65:
  INCBIN "res/level/kinds-2.bin",$0207,11
Kind66:
  INCBIN "res/level/kinds-2.bin",$0212,11
Kind67:
  INCBIN "res/level/kinds-2.bin",$021D,11
Kind68:
  INCBIN "res/level/kinds-2.bin",$0228,11

; 1 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $01
