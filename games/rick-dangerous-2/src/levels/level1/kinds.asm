; --------------------------------------------------------------------------------------------------------------------
; kinds.asm: The trap kinds: the kind table, the animation scripts, the paths and the kind records
; --------------------------------------------------------------------------------------------------------------------

; A word a kind (0-49): the address of its record
;
; LevelHeader+0 points here. SpawnMapObject $9D6C takes the word at KindTable +
; 2 x the map entry's kind (below $74) for a trap or pickup. Kind 0 is never
; used (its word is $0000); kinds 32, 36 have records but no map entry uses
; them.
KindTable:
  INCBIN "res/level/kinds.bin",$0000,100
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
  ASSERT {KindTable+96} == Kind48 && {KindTable+98} == Kind49

; The animation scripts of the trap kinds
;
; Read by AnimateTrap $A608 from a record's +$0A/+$0B: a byte below $80 is a
; frame (SpriteFrameMap: the sprite, bit 7 mirrored; frame $7F hides the
; object) shown one pass; $80 + n then a frame: that frame for n more passes;
; $FD n plays effect n; $FF and a word jumps there (every script ends in one).
; A kind record gives the first script (+5/+6) and the one after the switch
; (+9/+10).
TrapAnims:
  ; $F269 kinds 1, 1 (second), 2, 2 (second), 3, 3 (second), 4, 4 (second),
  ;   5, 6, 7, 8, 8 (second), 9, 9 (second), 10, 10 (second), 11, 11
  ;   (second), 12, 12 (second), 41, 43, 43 (second)
  ; $F26E kind 13
  ; $F273 kinds 15 (second), 23 (second)
  ; $F282 kind 14
  ; $F289 kind 15
  ; $F28E kind 16
  ; $F295 kind 17
  ; $F29C kind 18
  ; $F2B2 kind 19
  ; $F2C1 kind 24
  ; $F2C8 kind 21
  ; $F2CF kinds 22, 34
  ; $F2E5 kinds 23, 49, 49 (second)
  ; $F2E9 kinds 25, 26
  ; $F2F2 kind 27
  ; $F304 kinds 28, 29
  ; $F31A kinds 30, 45
  ; $F321 kind 31
  ; $F32C kind 32
  ; $F333 kinds 33, 33 (second)
  ; $F339 kinds 38, 39
  ; $F33D kinds 22 (second), 40 (second), 44 (second)
  ; $F341 kind 36 (second)
  ; $F34E kind 37 (second)
  ; $F35B kind 38 (second)
  ; $F3AA kind 39 (second)
  ; $F3B0 kind 40
  ; $F3C6 kind 20
  ; $F3CD kind 35
  ; $F3E4 kind 36
  ; $F3F5 kind 37
  ; $F406 kind 44
  ; $F41C kind 42
  ; $F42F kind 46
  ; $F448 kind 47
  ; $F461 kind 48
  INCBIN "res/level/anims.bin",$0000,593

; The paths of the trap kinds
;
; Read by UpdateTrap $A2F7 from a record's +$0F/+$10: pairs of a count and a
; step (the high nibble the x step, the low nibble the y step, each signed, 7
; meaning 8 pixels) applied once a pass count times; $FF n plays effect n; 0
; and a word jumps there (the loop point: a one-shot trap ends there, a waiting
; trap switches to its second path). A kind record gives the first path (+3/+4)
; and the second (+7/+8).
TrapPaths:
  ; $F4BA kinds 1, 2, 3, 4, 8, 9, 10, 11, 15, 22 (second), 23, 36, 37, 38,
  ;   39, 40 (second), 42, 43, 44 (second), 48, 49
  ; $F4BF kinds 1 (second), 12
  ; $F4CA kind 2 (second)
  ; $F4D5 kind 3 (second)
  ; $F4DC kind 4 (second)
  ; $F4E3 kind 5
  ; $F4EA kind 6
  ; $F4F1 kind 7
  ; $F4FC kind 8 (second)
  ; $F501 kind 9 (second)
  ; $F506 kind 10 (second)
  ; $F50F kind 11 (second)
  ; $F518 kind 12 (second)
  ; $F523 kind 13
  ; $F52C kind 14
  ; $F535 kind 16
  ; $F53E kind 17
  ; $F547 kind 18
  ; $F556 kind 19
  ; $F561 kind 20
  ; $F56A kind 21
  ; $F571 kind 22
  ; $F57E kind 24
  ; $F587 kind 25
  ; $F592 kind 26
  ; $F59D kind 27
  ; $F5A8 kind 28
  ; $F5B5 kind 29
  ; $F5C2 kind 30
  ; $F5CB kind 31
  ; $F5D6 kind 32
  ; $F5DB kind 33
  ; $F5E2 kind 33 (second)
  ; $F5E9 kind 34
  ; $F5F2 kind 38 (second)
  ; $F601 kind 39 (second)
  ; $F60C kind 40
  ; $F619 kind 41
  ; $F624 kind 35
  ; $F635 kind 43 (second)
  ; $F63E kind 44
  ; $F64B kind 45
  ; $F654 kinds 15 (second), 23 (second)
  ; $F659 kinds 46, 47
  ; $F65E kind 49 (second)
  ; $F663 kinds 36 (second), 37 (second)
  INCBIN "res/level/paths.bin",$0000,430

; The kind records: 11 bytes, or 7 for a kind that never switches
;
; KindTable points to each. +0 the width, +1 the height (record +7, +8); +2
; bits 6-7 into the record's +0 (bit 6 deadly to Rick and the enemies, bit 7 a
; platform, with bit 6 a solid block that also sets off a lit detonator), bits
; 0-5 x 4 OR-ed into the +0 the trap takes after the switch (record +$15; $20
; gives bit 7); +3/+4 the path, +5/+6 the animation; +7/+8 the second path,
; +9/+10 the second animation (SwitchTrapPath $A4D5 swaps them in). A record
; followed 7 bytes later by the next one has no second half of its own: its
; +7..+10 are the next record's first bytes, which no switch reads for such a
; kind (or the switch would take them).
KindRecords:
Kind1:
  ; $F668 kind 1: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F4BF, anim $F269
  INCBIN "res/level/kinds-2.bin",$0000,11
Kind2:
  ; $F673 kind 2: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F4CA, anim $F269
  INCBIN "res/level/kinds-2.bin",$000B,11
Kind3:
  ; $F67E kind 3: 24 x 16, flags $A0, path $F4BA, anim $F269, second path
  ;   $F4D5, anim $F269
  INCBIN "res/level/kinds-2.bin",$0016,11
Kind4:
  ; $F689 kind 4: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F4DC, anim $F269
  INCBIN "res/level/kinds-2.bin",$0021,11
Kind5:
  ; $F694 kind 5: 24 x 8, flags $A0, path $F4E3, anim $F269 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$002C,7
Kind6:
  ; $F69B kind 6: 24 x 8, flags $A0, path $F4EA, anim $F269 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0033,7
Kind7:
  ; $F6A2 kind 7: 24 x 8, flags $A0, path $F4F1, anim $F269 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$003A,7
Kind8:
  ; $F6A9 kind 8: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F4FC, anim $F269
  INCBIN "res/level/kinds-2.bin",$0041,11
Kind9:
  ; $F6B4 kind 9: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F501, anim $F269
  INCBIN "res/level/kinds-2.bin",$004C,11
Kind10:
  ; $F6BF kind 10: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F506, anim $F269
  INCBIN "res/level/kinds-2.bin",$0057,11
Kind11:
  ; $F6CA kind 11: 24 x 8, flags $A0, path $F4BA, anim $F269, second path
  ;   $F50F, anim $F269
  INCBIN "res/level/kinds-2.bin",$0062,11
Kind12:
  ; $F6D5 kind 12: 24 x 8, flags $A0, path $F4BF, anim $F269, second path
  ;   $F518, anim $F269
  INCBIN "res/level/kinds-2.bin",$006D,11
Kind13:
  ; $F6E0 kind 13: 6 x 21, flags $50, path $F523, anim $F26E (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0078,7
Kind14:
  ; $F6E7 kind 14: 16 x 16, flags $50, path $F52C, anim $F282 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$007F,7
Kind15:
  ; $F6EE kind 15: 24 x 16, flags $F0, path $F4BA, anim $F289, second path
  ;   $F654, anim $F273
  INCBIN "res/level/kinds-2.bin",$0086,11
Kind16:
  ; $F6F9 kind 16: 16 x 16, flags $50, path $F535, anim $F28E (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0091,7
Kind17:
  ; $F700 kind 17: 16 x 16, flags $50, path $F53E, anim $F295 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0098,7
Kind18:
  ; $F707 kind 18: 8 x 21, flags $50, path $F547, anim $F29C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$009F,7
Kind19:
  ; $F70E kind 19: 24 x 14, flags $50, path $F556, anim $F2B2 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00A6,7
Kind20:
  ; $F715 kind 20: 24 x 4, flags $50, path $F561, anim $F3C6 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00AD,7
Kind21:
  ; $F71C kind 21: 16 x 16, flags $50, path $F56A, anim $F2C8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00B4,7
Kind22:
  ; $F723 kind 22: 24 x 4, flags $50, path $F571, anim $F2CF, second path
  ;   $F4BA, anim $F33D
  INCBIN "res/level/kinds-2.bin",$00BB,11
Kind23:
  ; $F72E kind 23: 24 x 16, flags $C0, path $F4BA, anim $F2E5, second path
  ;   $F654, anim $F273
  INCBIN "res/level/kinds-2.bin",$00C6,11
Kind24:
  ; $F739 kind 24: 24 x 4, flags $50, path $F57E, anim $F2C1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00D1,7
Kind25:
  ; $F740 kind 25: 24 x 4, flags $50, path $F587, anim $F2E9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00D8,7
Kind26:
  ; $F747 kind 26: 24 x 4, flags $50, path $F592, anim $F2E9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00DF,7
Kind27:
  ; $F74E kind 27: 24 x 16, flags $50, path $F59D, anim $F2F2 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00E6,7
Kind28:
  ; $F755 kind 28: 24 x 4, flags $50, path $F5A8, anim $F304 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00ED,7
Kind29:
  ; $F75C kind 29: 24 x 4, flags $50, path $F5B5, anim $F304 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00F4,7
Kind30:
  ; $F763 kind 30: 24 x 4, flags $50, path $F5C2, anim $F31A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00FB,7
Kind31:
  ; $F76A kind 31: 24 x 14, flags $50, path $F5CB, anim $F321 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0102,7
Kind32:
  ; $F771 kind 32: 6 x 21, flags $50, path $F5D6, anim $F32C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0109,7
Kind33:
  ; $F778 kind 33: 24 x 21, flags $50, path $F5DB, anim $F333, second path
  ;   $F5E2, anim $F333
  INCBIN "res/level/kinds-2.bin",$0110,11
Kind34:
  ; $F783 kind 34: 24 x 4, flags $50, path $F5E9, anim $F2CF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$011B,7
Kind35:
  ; $F78A kind 35: 8 x 21, flags $50, path $F624, anim $F3CD (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0122,7
Kind36:
  ; $F791 kind 36: 24 x 6, flags $10, path $F4BA, anim $F3E4, second path
  ;   $F663, anim $F341
  INCBIN "res/level/kinds-2.bin",$0129,11
Kind37:
  ; $F79C kind 37: 24 x 6, flags $10, path $F4BA, anim $F3F5, second path
  ;   $F663, anim $F34E
  INCBIN "res/level/kinds-2.bin",$0134,11
Kind38:
  ; $F7A7 kind 38: 16 x 21, flags $50, path $F4BA, anim $F339, second path
  ;   $F5F2, anim $F35B
  INCBIN "res/level/kinds-2.bin",$013F,11
Kind39:
  ; $F7B2 kind 39: 16 x 21, flags $50, path $F4BA, anim $F339, second path
  ;   $F601, anim $F3AA
  INCBIN "res/level/kinds-2.bin",$014A,11
Kind40:
  ; $F7BD kind 40: 24 x 4, flags $50, path $F60C, anim $F3B0, second path
  ;   $F4BA, anim $F33D
  INCBIN "res/level/kinds-2.bin",$0155,11
Kind41:
  ; $F7C8 kind 41: 24 x 8, flags $A0, path $F619, anim $F269 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0160,7
Kind42:
  ; $F7CF kind 42: 24 x 14, flags $50, path $F4BA, anim $F41C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0167,7
Kind43:
  ; $F7D6 kind 43: 24 x 8, flags $20, path $F4BA, anim $F269, second path
  ;   $F635, anim $F269
  INCBIN "res/level/kinds-2.bin",$016E,11
Kind44:
  ; $F7E1 kind 44: 24 x 4, flags $50, path $F63E, anim $F406, second path
  ;   $F4BA, anim $F33D
  INCBIN "res/level/kinds-2.bin",$0179,11
Kind45:
  ; $F7EC kind 45: 24 x 4, flags $50, path $F64B, anim $F31A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0184,7
Kind46:
  ; $F7F3 kind 46: 0 x 0, flags $00, path $F659, anim $F42F (7 bytes)
  INCBIN "res/level/kinds-2.bin",$018B,7
Kind47:
  ; $F7FA kind 47: 0 x 0, flags $00, path $F659, anim $F448 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0192,7
Kind48:
  ; $F801 kind 48: 0 x 0, flags $00, path $F4BA, anim $F461 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0199,7
Kind49:
  ; $F808 kind 49: 24 x 16, flags $D0, path $F4BA, anim $F2E5, second path
  ;   $F65E, anim $F2E5
  INCBIN "res/level/kinds-2.bin",$01A0,11

; 1261 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $04ED
