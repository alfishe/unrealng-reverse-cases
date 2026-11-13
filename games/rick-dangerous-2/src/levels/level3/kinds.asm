; --------------------------------------------------------------------------------------------------------------------
; kinds.asm: The trap kinds: the kind table, the animation scripts, the paths and the kind records
; --------------------------------------------------------------------------------------------------------------------

; A word a kind (0-51): the address of its record
;
; LevelHeader+0 points here. SpawnMapObject $9D6C takes the word at KindTable +
; 2 x the map entry's kind (below $74) for a trap or pickup. Kind 0 is never
; used (its word is $0000); kinds 13, 15, 35 have records but no map entry uses
; them.
KindTable:
  INCBIN "res/level/kinds.bin",$0000,104
  ASSERT {KindTable+2} == KindRecords && {KindTable+4} == Kind2 && {KindTable+6} == Kind3 && {KindTable+8} == Kind4
  ASSERT {KindTable+10} == Kind5 && {KindTable+12} == Kind6 && {KindTable+14} == Kind7
  ASSERT {KindTable+16} == Kind8 && {KindTable+18} == Kind9 && {KindTable+20} == Kind10 && {KindTable+22} == Kind11
  ASSERT {KindTable+24} == Kind12 && {KindTable+26} == Kind13 && {KindTable+28} == Kind14
  ASSERT {KindTable+30} == Kind15
  ASSERT {KindTable+32} == Kind16 && {KindTable+34} == Kind17 && {KindTable+36} == Kind18
  ASSERT {KindTable+38} == Kind19 && {KindTable+40} == Kind20 && {KindTable+42} == Kind21
  ASSERT {KindTable+44} == Kind22 && {KindTable+46} == Kind23
  ASSERT {KindTable+48} == Kind24 && {KindTable+50} == Kind25 && {KindTable+52} == Kind26
  ASSERT {KindTable+54} == Kind27 && {KindTable+56} == Kind28 && {KindTable+58} == Kind29
  ASSERT {KindTable+60} == Kind30 && {KindTable+62} == Kind31
  ASSERT {KindTable+64} == Kind32 && {KindTable+66} == Kind33 && {KindTable+68} == Kind34
  ASSERT {KindTable+70} == Kind35 && {KindTable+72} == Kind36 && {KindTable+74} == Kind37
  ASSERT {KindTable+76} == Kind38 && {KindTable+78} == Kind39
  ASSERT {KindTable+80} == Kind40 && {KindTable+82} == Kind41 && {KindTable+84} == Kind42
  ASSERT {KindTable+86} == Kind43 && {KindTable+88} == Kind44 && {KindTable+90} == Kind45
  ASSERT {KindTable+92} == Kind46 && {KindTable+94} == Kind47
  ASSERT {KindTable+96} == Kind48 && {KindTable+98} == Kind49 && {KindTable+100} == Kind50
  ASSERT {KindTable+102} == Kind51

; The animation scripts of the trap kinds
;
; Read by AnimateTrap $A608 from a record's +$0A/+$0B: a byte below $80 is a
; frame (SpriteFrameMap: the sprite, bit 7 mirrored; frame $7F hides the
; object) shown one pass; $80 + n then a frame: that frame for n more passes;
; $FD n plays effect n; $FF and a word jumps there (every script ends in one).
; A kind record gives the first script (+5/+6) and the one after the switch
; (+9/+10).
TrapAnims:
  INCBIN "res/level/anims.bin",$0000,351

; The paths of the trap kinds
;
; Read by UpdateTrap $A2F7 from a record's +$0F/+$10: pairs of a count and a
; step (the high nibble the x step, the low nibble the y step, each signed, 7
; meaning 8 pixels) applied once a pass count times; $FF n plays effect n; 0
; and a word jumps there (the loop point: a one-shot trap ends there, a waiting
; trap switches to its second path). A kind record gives the first path (+3/+4)
; and the second (+7/+8).
TrapPaths:
  INCBIN "res/level/paths.bin",$0000,778

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
  INCBIN "res/level/kinds-2.bin",$0007,7
Kind3:
  INCBIN "res/level/kinds-2.bin",$000E,7
Kind4:
  INCBIN "res/level/kinds-2.bin",$0015,7
Kind5:
  INCBIN "res/level/kinds-2.bin",$001C,7
Kind6:
  INCBIN "res/level/kinds-2.bin",$0023,11
Kind7:
  INCBIN "res/level/kinds-2.bin",$002E,11
Kind8:
  INCBIN "res/level/kinds-2.bin",$0039,11
Kind9:
  INCBIN "res/level/kinds-2.bin",$0044,11
Kind10:
  INCBIN "res/level/kinds-2.bin",$004F,7
Kind11:
  INCBIN "res/level/kinds-2.bin",$0056,11
Kind12:
  INCBIN "res/level/kinds-2.bin",$0061,11
Kind13:
  INCBIN "res/level/kinds-2.bin",$006C,7
Kind14:
  INCBIN "res/level/kinds-2.bin",$0073,11
Kind15:
  INCBIN "res/level/kinds-2.bin",$007E,7
Kind16:
  INCBIN "res/level/kinds-2.bin",$0085,7
Kind17:
  INCBIN "res/level/kinds-2.bin",$008C,11
Kind18:
  INCBIN "res/level/kinds-2.bin",$0097,11
Kind19:
  INCBIN "res/level/kinds-2.bin",$00A2,11
Kind20:
  INCBIN "res/level/kinds-2.bin",$00AD,11
Kind21:
  INCBIN "res/level/kinds-2.bin",$00B8,11
Kind22:
  INCBIN "res/level/kinds-2.bin",$00C3,11
Kind23:
  INCBIN "res/level/kinds-2.bin",$00CE,7
Kind24:
  INCBIN "res/level/kinds-2.bin",$00D5,7
Kind25:
  INCBIN "res/level/kinds-2.bin",$00DC,11
Kind26:
  INCBIN "res/level/kinds-2.bin",$00E7,11
Kind27:
  INCBIN "res/level/kinds-2.bin",$00F2,7
Kind28:
  INCBIN "res/level/kinds-2.bin",$00F9,11
Kind29:
  INCBIN "res/level/kinds-2.bin",$0104,11
Kind30:
  INCBIN "res/level/kinds-2.bin",$010F,7
Kind31:
  INCBIN "res/level/kinds-2.bin",$0116,7
Kind32:
  INCBIN "res/level/kinds-2.bin",$011D,11
Kind33:
  INCBIN "res/level/kinds-2.bin",$0128,7
Kind34:
  INCBIN "res/level/kinds-2.bin",$012F,11
Kind35:
  INCBIN "res/level/kinds-2.bin",$013A,7
Kind36:
  INCBIN "res/level/kinds-2.bin",$0141,7
Kind37:
  INCBIN "res/level/kinds-2.bin",$0148,7
Kind38:
  INCBIN "res/level/kinds-2.bin",$014F,11
Kind39:
  INCBIN "res/level/kinds-2.bin",$015A,7
Kind40:
  INCBIN "res/level/kinds-2.bin",$0161,7
Kind41:
  INCBIN "res/level/kinds-2.bin",$0168,7
Kind42:
  INCBIN "res/level/kinds-2.bin",$016F,7
Kind43:
  INCBIN "res/level/kinds-2.bin",$0176,7
Kind44:
  INCBIN "res/level/kinds-2.bin",$017D,7
Kind45:
  INCBIN "res/level/kinds-2.bin",$0184,7
Kind46:
  INCBIN "res/level/kinds-2.bin",$018B,11
Kind47:
  INCBIN "res/level/kinds-2.bin",$0196,11
Kind48:
  INCBIN "res/level/kinds-2.bin",$01A1,11
Kind49:
  INCBIN "res/level/kinds-2.bin",$01AC,11
Kind50:
  INCBIN "res/level/kinds-2.bin",$01B7,11
Kind51:
  INCBIN "res/level/kinds-2.bin",$01C2,11

; 831 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $033F
