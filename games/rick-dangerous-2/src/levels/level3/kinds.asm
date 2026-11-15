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
  ; $F38B kind 1
  ; $F390 kind 2
  ; $F395 kinds 3, 35
  ; $F39A kind 4
  ; $F39F kind 5
  ; $F3A4 kinds 6, 10
  ; $F3A9 kind 6 (second)
  ; $F3B4 kind 7
  ; $F3B9 kind 7 (second)
  ; $F3C0 kinds 8, 8 (second)
  ; $F3C5 kinds 9, 9 (second)
  ; $F3CA kinds 11, 11 (second), 12, 12 (second), 32, 32 (second), 38, 38
  ;   (second)
  ; $F3CF kinds 13, 15, 16, 18 (second), 19 (second), 25 (second), 40, 44,
  ;   46 (second)
  ; $F3D4 kind 14
  ; $F3D9 kind 14 (second)
  ; $F3DE kinds 18, 19, 25, 34, 34 (second), 46
  ; $F3E3 kinds 17, 28, 29, 47, 49
  ; $F3E7 kinds 17 (second), 28 (second), 29 (second), 36, 37, 42, 43, 47
  ;   (second), 49 (second)
  ; $F3EE kind 20
  ; $F3F3 kind 20 (second)
  ; $F3FE kind 21
  ; $F403 kind 21 (second)
  ; $F466 kind 22
  ; $F46B kinds 22 (second), 23, 24, 30, 31, 45
  ; $F472 kinds 26, 26 (second), 48, 48 (second), 50, 50 (second)
  ; $F477 kind 27
  ; $F47E kind 33
  ; $F4D1 kind 39
  ; $F4D8 kind 41
  ; $F4E5 kind 51
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
  ; $F4EA kinds 3, 4, 5, 6, 7, 8, 9, 11, 12, 14, 14 (second), 17, 18, 19,
  ;   20, 21, 22, 25, 26, 27, 28, 29, 32, 34, 38, 46, 47, 48, 49, 50, 51
  ; $F4EF kind 1
  ; $F4F6 kind 2
  ; $F4FD kinds 8 (second), 9 (second)
  ; $F4FF kinds 6 (second), 7 (second)
  ; $F50A kind 11 (second)
  ; $F519 kind 12 (second)
  ; $F528 kind 13
  ; $F533 kind 15
  ; $F53E kind 10
  ; $F547 kind 16
  ; $F552 kind 17 (second)
  ; $F567 kind 18 (second)
  ; $F574 kind 19 (second)
  ; $F57D kind 20 (second)
  ; $F58C kind 21 (second)
  ; $F597 kind 22 (second)
  ; $F5A6 kind 23
  ; $F5B3 kind 24
  ; $F616 kind 25 (second)
  ; $F61F kind 26 (second)
  ; $F628 kind 28 (second)
  ; $F637 kind 29 (second)
  ; $F658 kind 30
  ; $F69F kind 31
  ; $F6E6 kind 32 (second)
  ; $F6ED kind 33
  ; $F6F8 kind 34 (second)
  ; $F727 kind 35
  ; $F72C kind 36
  ; $F74D kind 37
  ; $F75A kind 38 (second)
  ; $F761 kind 39
  ; $F76A kind 44
  ; $F76C kind 40
  ; $F777 kind 41
  ; $F788 kind 42
  ; $F78F kind 43
  ; $F796 kind 45
  ; $F7B5 kind 46 (second)
  ; $F7BC kind 49 (second)
  ; $F7D7 kind 47 (second)
  ; $F7E6 kind 48 (second)
  ; $F7ED kind 50 (second)
  INCBIN "res/level/paths.bin",$0000,778

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
  ; $F7F4 kind 1: 24 x 5, flags $50, path $F4EF, anim $F38B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0000,7
Kind2:
  ; $F7FB kind 2: 24 x 5, flags $50, path $F4F6, anim $F390 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0007,7
Kind3:
  ; $F802 kind 3: 24 x 21, flags $50, path $F4EA, anim $F395 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$000E,7
Kind4:
  ; $F809 kind 4: 24 x 21, flags $50, path $F4EA, anim $F39A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0015,7
Kind5:
  ; $F810 kind 5: 24 x 21, flags $50, path $F4EA, anim $F39F (7 bytes)
  INCBIN "res/level/kinds-2.bin",$001C,7
Kind6:
  ; $F817 kind 6: 24 x 8, flags $80, path $F4EA, anim $F3A4, second path
  ;   $F4FF, anim $F3A9
  INCBIN "res/level/kinds-2.bin",$0023,11
Kind7:
  ; $F822 kind 7: 24 x 16, flags $C0, path $F4EA, anim $F3B4, second path
  ;   $F4FF, anim $F3B9
  INCBIN "res/level/kinds-2.bin",$002E,11
Kind8:
  ; $F82D kind 8: 24 x 8, flags $90, path $F4EA, anim $F3C0, second path
  ;   $F4FD, anim $F3C0
  INCBIN "res/level/kinds-2.bin",$0039,11
Kind9:
  ; $F838 kind 9: 24 x 8, flags $90, path $F4EA, anim $F3C5, second path
  ;   $F4FD, anim $F3C5
  INCBIN "res/level/kinds-2.bin",$0044,11
Kind10:
  ; $F843 kind 10: 24 x 8, flags $80, path $F53E, anim $F3A4 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$004F,7
Kind11:
  ; $F84A kind 11: 24 x 16, flags $50, path $F4EA, anim $F3CA, second path
  ;   $F50A, anim $F3CA
  INCBIN "res/level/kinds-2.bin",$0056,11
Kind12:
  ; $F855 kind 12: 24 x 16, flags $50, path $F4EA, anim $F3CA, second path
  ;   $F519, anim $F3CA
  INCBIN "res/level/kinds-2.bin",$0061,11
Kind13:
  ; $F860 kind 13: 24 x 16, flags $A0, path $F528, anim $F3CF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$006C,7
Kind14:
  ; $F867 kind 14: 24 x 16, flags $40, path $F4EA, anim $F3D4, second path
  ;   $F4EA, anim $F3D9
  INCBIN "res/level/kinds-2.bin",$0073,11
Kind15:
  ; $F872 kind 15: 24 x 16, flags $A0, path $F533, anim $F3CF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$007E,7
Kind16:
  ; $F879 kind 16: 24 x 8, flags $A0, path $F547, anim $F3CF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0085,7
Kind17:
  ; $F880 kind 17: 20 x 21, flags $D0, path $F4EA, anim $F3E3, second path
  ;   $F552, anim $F3E7
  INCBIN "res/level/kinds-2.bin",$008C,11
Kind18:
  ; $F88B kind 18: 24 x 8, flags $A0, path $F4EA, anim $F3DE, second path
  ;   $F567, anim $F3CF
  INCBIN "res/level/kinds-2.bin",$0097,11
Kind19:
  ; $F896 kind 19: 24 x 8, flags $A0, path $F4EA, anim $F3DE, second path
  ;   $F574, anim $F3CF
  INCBIN "res/level/kinds-2.bin",$00A2,11
Kind20:
  ; $F8A1 kind 20: 24 x 16, flags $10, path $F4EA, anim $F3EE, second path
  ;   $F57D, anim $F3F3
  INCBIN "res/level/kinds-2.bin",$00AD,11
Kind21:
  ; $F8AC kind 21: 24 x 21, flags $50, path $F4EA, anim $F3FE, second path
  ;   $F58C, anim $F403
  INCBIN "res/level/kinds-2.bin",$00B8,11
Kind22:
  ; $F8B7 kind 22: 16 x 16, flags $50, path $F4EA, anim $F466, second path
  ;   $F597, anim $F46B
  INCBIN "res/level/kinds-2.bin",$00C3,11
Kind23:
  ; $F8C2 kind 23: 16 x 16, flags $50, path $F5A6, anim $F46B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00CE,7
Kind24:
  ; $F8C9 kind 24: 16 x 16, flags $50, path $F5B3, anim $F46B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00D5,7
Kind25:
  ; $F8D0 kind 25: 24 x 8, flags $A0, path $F4EA, anim $F3DE, second path
  ;   $F616, anim $F3CF
  INCBIN "res/level/kinds-2.bin",$00DC,11
Kind26:
  ; $F8DB kind 26: 16 x 21, flags $50, path $F4EA, anim $F472, second path
  ;   $F61F, anim $F472
  INCBIN "res/level/kinds-2.bin",$00E7,11
Kind27:
  ; $F8E6 kind 27: 16 x 16, flags $00, path $F4EA, anim $F477 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00F2,7
Kind28:
  ; $F8ED kind 28: 20 x 21, flags $D0, path $F4EA, anim $F3E3, second path
  ;   $F628, anim $F3E7
  INCBIN "res/level/kinds-2.bin",$00F9,11
Kind29:
  ; $F8F8 kind 29: 20 x 21, flags $D0, path $F4EA, anim $F3E3, second path
  ;   $F637, anim $F3E7
  INCBIN "res/level/kinds-2.bin",$0104,11
Kind30:
  ; $F903 kind 30: 16 x 16, flags $50, path $F658, anim $F46B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$010F,7
Kind31:
  ; $F90A kind 31: 16 x 16, flags $50, path $F69F, anim $F46B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0116,7
Kind32:
  ; $F911 kind 32: 24 x 16, flags $50, path $F4EA, anim $F3CA, second path
  ;   $F6E6, anim $F3CA
  INCBIN "res/level/kinds-2.bin",$011D,11
Kind33:
  ; $F91C kind 33: 24 x 21, flags $50, path $F6ED, anim $F47E (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0128,7
Kind34:
  ; $F923 kind 34: 24 x 8, flags $A0, path $F4EA, anim $F3DE, second path
  ;   $F6F8, anim $F3DE
  INCBIN "res/level/kinds-2.bin",$012F,11
Kind35:
  ; $F92E kind 35: 24 x 16, flags $50, path $F727, anim $F395 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$013A,7
Kind36:
  ; $F935 kind 36: 20 x 21, flags $50, path $F72C, anim $F3E7 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0141,7
Kind37:
  ; $F93C kind 37: 20 x 21, flags $50, path $F74D, anim $F3E7 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0148,7
Kind38:
  ; $F943 kind 38: 24 x 16, flags $50, path $F4EA, anim $F3CA, second path
  ;   $F75A, anim $F3CA
  INCBIN "res/level/kinds-2.bin",$014F,11
Kind39:
  ; $F94E kind 39: 24 x 5, flags $50, path $F761, anim $F4D1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$015A,7
Kind40:
  ; $F955 kind 40: 24 x 8, flags $A0, path $F76C, anim $F3CF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0161,7
Kind41:
  ; $F95C kind 41: 24 x 16, flags $40, path $F777, anim $F4D8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0168,7
Kind42:
  ; $F963 kind 42: 20 x 21, flags $50, path $F788, anim $F3E7 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$016F,7
Kind43:
  ; $F96A kind 43: 20 x 21, flags $50, path $F78F, anim $F3E7 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0176,7
Kind44:
  ; $F971 kind 44: 24 x 8, flags $A0, path $F76A, anim $F3CF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$017D,7
Kind45:
  ; $F978 kind 45: 16 x 16, flags $50, path $F796, anim $F46B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0184,7
Kind46:
  ; $F97F kind 46: 24 x 8, flags $A0, path $F4EA, anim $F3DE, second path
  ;   $F7B5, anim $F3CF
  INCBIN "res/level/kinds-2.bin",$018B,11
Kind47:
  ; $F98A kind 47: 20 x 21, flags $D0, path $F4EA, anim $F3E3, second path
  ;   $F7D7, anim $F3E7
  INCBIN "res/level/kinds-2.bin",$0196,11
Kind48:
  ; $F995 kind 48: 16 x 21, flags $50, path $F4EA, anim $F472, second path
  ;   $F7E6, anim $F472
  INCBIN "res/level/kinds-2.bin",$01A1,11
Kind49:
  ; $F9A0 kind 49: 20 x 21, flags $D0, path $F4EA, anim $F3E3, second path
  ;   $F7BC, anim $F3E7
  INCBIN "res/level/kinds-2.bin",$01AC,11
Kind50:
  ; $F9AB kind 50: 20 x 21, flags $50, path $F4EA, anim $F472, second path
  ;   $F7ED, anim $F472
  INCBIN "res/level/kinds-2.bin",$01B7,11
Kind51:
  ; $F9B6 kind 51: 21 x 8, flags $C0, path $F4EA, anim $F4E5, second path
  ;   $0000, anim $0000
  INCBIN "res/level/kinds-2.bin",$01C2,11

; 831 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $033F
