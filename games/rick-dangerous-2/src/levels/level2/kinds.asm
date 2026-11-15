; --------------------------------------------------------------------------------------------------------------------
; kinds.asm: The trap kinds: the kind table, the animation scripts, the paths and the kind records
; --------------------------------------------------------------------------------------------------------------------

; A word a kind (0-45): the address of its record
;
; LevelHeader+0 points here. SpawnMapObject $9D6C takes the word at KindTable +
; 2 x the map entry's kind (below $74) for a trap or pickup. Kind 0 is never
; used (its word is $0000); kinds 5, 12, 14, 15, 16 have records but no map
; entry uses them.
KindTable:
  INCBIN "res/level/kinds.bin",$0000,92
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

; The animation scripts of the trap kinds
;
; Read by AnimateTrap $A608 from a record's +$0A/+$0B: a byte below $80 is a
; frame (SpriteFrameMap: the sprite, bit 7 mirrored; frame $7F hides the
; object) shown one pass; $80 + n then a frame: that frame for n more passes;
; $FD n plays effect n; $FF and a word jumps there (every script ends in one).
; A kind record gives the first script (+5/+6) and the one after the switch
; (+9/+10).
TrapAnims:
  ; $F437 kind 1
  ; $F43C kinds 6, 12, 23, 28, 28 (second), 33, 33 (second), 41, 44, 45
  ; $F441 kinds 3, 4, 5, 7, 8, 9, 14, 15, 16, 17, 24
  ; $F445 kinds 4 (second), 9 (second), 14 (second), 17 (second)
  ; $F44C kinds 5 (second), 7 (second), 8 (second), 15 (second), 16
  ;   (second)
  ; $F453 kinds 10, 11, 20
  ; $F457 kind 10 (second)
  ; $F464 kind 11 (second)
  ; $F471 kind 13
  ; $F481 kinds 18, 43
  ; $F485 kinds 18 (second), 43 (second)
  ; $F492 kinds 19, 19 (second), 25, 25 (second), 40
  ; $F497 kind 20 (second)
  ; $F4A4 kind 21
  ; $F4AA kinds 13 (second), 35 (second)
  ; $F4AE kind 2
  ; $F4B8 kind 26
  ; $F4BD kind 27
  ; $F4C2 kind 22
  ; $F4EC kind 29
  ; $F4F0 kind 30
  ; $F4F4 kind 31
  ; $F4F8 kind 32
  ; $F4FE kind 35
  ; $F503 kind 34
  ; $F50A kind 36
  ; $F541 kind 37
  ; $F547 kind 38
  ; $F554 kind 39
  ; $F561 11 bytes no kind record points to (a script of an older build)
  ; $F56C kind 42
  INCBIN "res/level/anims.bin",$0000,318

; The paths of the trap kinds
;
; Read by UpdateTrap $A2F7 from a record's +$0F/+$10: pairs of a count and a
; step (the high nibble the x step, the low nibble the y step, each signed, 7
; meaning 8 pixels) applied once a pass count times; $FF n plays effect n; 0
; and a word jumps there (the loop point: a one-shot trap ends there, a waiting
; trap switches to its second path). A kind record gives the first path (+3/+4)
; and the second (+7/+8).
TrapPaths:
  ; $F575 kinds 1, 10, 11, 12, 13 (second), 18, 19, 20, 25, 28, 29, 30, 31,
  ;   33, 37, 43
  ; $F57A kind 3
  ; $F581 kind 4
  ; $F588 kinds 4 (second), 5 (second), 7 (second), 8 (second), 9 (second),
  ;   14 (second), 15 (second), 16 (second), 17 (second)
  ; $F58D kind 5
  ; $F594 kind 6
  ; $F5C1 kind 7
  ; $F5C8 kind 8
  ; $F5CF kind 9
  ; $F5D6 kind 10 (second)
  ; $F5DF kind 11 (second)
  ; $F5E8 kind 14
  ; $F5EF kind 15
  ; $F5F6 kind 16
  ; $F5FD kind 17
  ; $F604 kinds 18 (second), 43 (second)
  ; $F60B kind 19 (second)
  ; $F614 kind 2
  ; $F61B kind 20 (second)
  ; $F624 kind 21
  ; $F628 kind 32
  ; $F62F kind 23
  ; $F638 kind 24
  ; $F66D kind 25 (second)
  ; $F676 kind 26
  ; $F67B kind 27
  ; $F680 kind 13
  ; $F68F kind 22
  ; $F6B8 kind 28 (second)
  ; $F6C5 kind 33 (second)
  ; $F6CA kind 34
  ; $F6D7 kinds 35, 35 (second)
  ; $F6DC kind 36
  ; $F747 kind 38
  ; $F750 kind 39
  ; $F759 9 bytes no kind record points to (a path of an older build)
  ; $F762 kind 41
  ; $F78D kind 40
  ; $F79C kind 42
  ; $F7A9 kind 44
  ; $F7B2 kind 45
  INCBIN "res/level/paths.bin",$0000,582

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
  ; $F7BB kind 1: 24 x 21, flags $40, path $F575, anim $F437 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0000,7
Kind2:
  ; $F7C2 kind 2: 24 x 21, flags $50, path $F614, anim $F4AE (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0007,7
Kind3:
  ; $F7C9 kind 3: 6 x 6, flags $40, path $F57A, anim $F441 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$000E,7
Kind4:
  ; $F7D0 kind 4: 6 x 6, flags $40, path $F581, anim $F441, second path
  ;   $F588, anim $F445
  INCBIN "res/level/kinds-2.bin",$0015,11
Kind5:
  ; $F7DB kind 5: 6 x 6, flags $40, path $F58D, anim $F441, second path
  ;   $F588, anim $F44C
  INCBIN "res/level/kinds-2.bin",$0020,11
Kind6:
  ; $F7E6 kind 6: 24 x 21, flags $50, path $F594, anim $F43C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$002B,7
Kind7:
  ; $F7ED kind 7: 6 x 6, flags $40, path $F5C1, anim $F441, second path
  ;   $F588, anim $F44C
  INCBIN "res/level/kinds-2.bin",$0032,11
Kind8:
  ; $F7F8 kind 8: 6 x 6, flags $40, path $F5C8, anim $F441, second path
  ;   $F588, anim $F44C
  INCBIN "res/level/kinds-2.bin",$003D,11
Kind9:
  ; $F803 kind 9: 6 x 6, flags $40, path $F5CF, anim $F441, second path
  ;   $F588, anim $F445
  INCBIN "res/level/kinds-2.bin",$0048,11
Kind10:
  ; $F80E kind 10: 8 x 21, flags $D0, path $F575, anim $F453, second path
  ;   $F5D6, anim $F457
  INCBIN "res/level/kinds-2.bin",$0053,11
Kind11:
  ; $F819 kind 11: 8 x 21, flags $D0, path $F575, anim $F453, second path
  ;   $F5DF, anim $F464
  INCBIN "res/level/kinds-2.bin",$005E,11
Kind12:
  ; $F824 kind 12: 24 x 21, flags $C0, path $F575, anim $F43C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0069,7
Kind13:
  ; $F82B kind 13: 24 x 21, flags $50, path $F680, anim $F471, second path
  ;   $F575, anim $F4AA
  INCBIN "res/level/kinds-2.bin",$0070,11
Kind14:
  ; $F836 kind 14: 6 x 6, flags $40, path $F5E8, anim $F441, second path
  ;   $F588, anim $F445
  INCBIN "res/level/kinds-2.bin",$007B,11
Kind15:
  ; $F841 kind 15: 6 x 6, flags $40, path $F5EF, anim $F441, second path
  ;   $F588, anim $F44C
  INCBIN "res/level/kinds-2.bin",$0086,11
Kind16:
  ; $F84C kind 16: 6 x 6, flags $40, path $F5F6, anim $F441, second path
  ;   $F588, anim $F44C
  INCBIN "res/level/kinds-2.bin",$0091,11
Kind17:
  ; $F857 kind 17: 6 x 6, flags $40, path $F5FD, anim $F441, second path
  ;   $F588, anim $F445
  INCBIN "res/level/kinds-2.bin",$009C,11
Kind18:
  ; $F862 kind 18: 24 x 21, flags $C0, path $F575, anim $F481, second path
  ;   $F604, anim $F485
  INCBIN "res/level/kinds-2.bin",$00A7,11
Kind19:
  ; $F86D kind 19: 24 x 8, flags $A0, path $F575, anim $F492, second path
  ;   $F60B, anim $F492
  INCBIN "res/level/kinds-2.bin",$00B2,11
Kind20:
  ; $F878 kind 20: 8 x 21, flags $D0, path $F575, anim $F453, second path
  ;   $F61B, anim $F497
  INCBIN "res/level/kinds-2.bin",$00BD,11
Kind21:
  ; $F883 kind 21: 22 x 16, flags $50, path $F624, anim $F4A4 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00C8,7
Kind22:
  ; $F88A kind 22: 24 x 21, flags $50, path $F68F, anim $F4C2 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00CF,7
Kind23:
  ; $F891 kind 23: 24 x 21, flags $50, path $F62F, anim $F43C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00D6,7
Kind24:
  ; $F898 kind 24: 6 x 6, flags $50, path $F638, anim $F441 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00DD,7
Kind25:
  ; $F89F kind 25: 24 x 8, flags $A0, path $F575, anim $F492, second path
  ;   $F66D, anim $F492
  INCBIN "res/level/kinds-2.bin",$00E4,11
Kind26:
  ; $F8AA kind 26: 24 x 21, flags $50, path $F676, anim $F4B8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00EF,7
Kind27:
  ; $F8B1 kind 27: 24 x 21, flags $50, path $F67B, anim $F4BD (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00F6,7
Kind28:
  ; $F8B8 kind 28: 24 x 21, flags $F0, path $F575, anim $F43C, second path
  ;   $F6B8, anim $F43C
  INCBIN "res/level/kinds-2.bin",$00FD,11
Kind29:
  ; $F8C3 kind 29: 24 x 16, flags $50, path $F575, anim $F4EC (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0108,7
Kind30:
  ; $F8CA kind 30: 24 x 16, flags $50, path $F575, anim $F4F0 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$010F,7
Kind31:
  ; $F8D1 kind 31: 24 x 16, flags $50, path $F575, anim $F4F4 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0116,7
Kind32:
  ; $F8D8 kind 32: 22 x 14, flags $50, path $F628, anim $F4F8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$011D,7
Kind33:
  ; $F8DF kind 33: 24 x 21, flags $D0, path $F575, anim $F43C, second path
  ;   $F6C5, anim $F43C
  INCBIN "res/level/kinds-2.bin",$0124,11
Kind34:
  ; $F8EA kind 34: 24 x 21, flags $50, path $F6CA, anim $F503 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$012F,7
Kind35:
  ; $F8F1 kind 35: 24 x 16, flags $40, path $F6D7, anim $F4FE, second path
  ;   $F6D7, anim $F4AA
  INCBIN "res/level/kinds-2.bin",$0136,11
Kind36:
  ; $F8FC kind 36: 24 x 21, flags $50, path $F6DC, anim $F50A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0141,7
Kind37:
  ; $F903 kind 37: 24 x 16, flags $50, path $F575, anim $F541 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0148,7
Kind38:
  ; $F90A kind 38: 6 x 6, flags $50, path $F747, anim $F547 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$014F,7
Kind39:
  ; $F911 kind 39: 6 x 6, flags $50, path $F750, anim $F554 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0156,7
Kind40:
  ; $F918 kind 40: 24 x 8, flags $A0, path $F78D, anim $F492 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$015D,7
Kind41:
  ; $F91F kind 41: 24 x 21, flags $50, path $F762, anim $F43C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0164,7
Kind42:
  ; $F926 kind 42: 6 x 6, flags $50, path $F79C, anim $F56C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$016B,7
Kind43:
  ; $F92D kind 43: 24 x 21, flags $00, path $F575, anim $F481, second path
  ;   $F604, anim $F485
  INCBIN "res/level/kinds-2.bin",$0172,11
Kind44:
  ; $F938 kind 44: 24 x 21, flags $50, path $F7A9, anim $F43C (7 bytes)
  INCBIN "res/level/kinds-2.bin",$017D,7
Kind45:
  ; $F93F kind 45: 24 x 21, flags $50, path $F7B2, anim $F43C, second path
  ;   $0000, anim $0000
  INCBIN "res/level/kinds-2.bin",$0184,11

; 950 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $03B6
