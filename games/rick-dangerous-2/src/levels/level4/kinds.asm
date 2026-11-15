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
  ; $F22E the end
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
  ; $F2B7 kinds 14, 21
  ; $F2BB kind 1
  ; $F2C1 kind 1 (second)
  ; $F2C8 kind 2
  ; $F2CD kinds 44, 68
  ; $F2D1 kinds 3, 9, 42, 43, 44 (second), 68 (second)
  ; $F2D8 kinds 5, 6, 7, 11, 12, 19, 20, 27, 32, 55, 60, 66, 67
  ; $F2DC kinds 5 (second), 66 (second)
  ; $F2E5 kind 12 (second)
  ; $F2F8 kinds 6 (second), 7 (second), 18, 19 (second), 20 (second), 55
  ;   (second), 60 (second), 63, 67 (second)
  ; $F2FC kinds 33, 34
  ; $F303 kinds 4, 15, 59, 62
  ; $F308 kinds 4 (second), 15 (second), 35, 36, 56, 59 (second), 62
  ;   (second), 64
  ; $F30F kind 10
  ; $F31E 106 bytes no kind record points to (a script of an older build)
  ; $F388 kinds 13, 29
  ; $F38C kind 13 (second)
  ; $F394 kind 14 (second)
  ; $F3B9 kind 21 (second)
  ; $F3C0 42 bytes no kind record points to (a script of an older build)
  ; $F3EA kind 17
  ; $F3F9 kind 22
  ; $F41E kind 23
  ; $F431 kind 24 (second)
  ; $F437 kind 25
  ; $F43D kind 27 (second)
  ; $F456 kind 28
  ; $F463 kind 29 (second)
  ; $F46F kind 16
  ; $F474 kind 30
  ; $F47D kind 31
  ; $F490 kind 37
  ; $F4B3 kind 38
  ; $F4C4 kind 39
  ; $F4CD kind 40
  ; $F4D6 kind 41
  ; $F507 kind 32 (second)
  ; $F53A 4 bytes no kind record points to (a script of an older build)
  ; $F53E kind 24
  ; $F542 kind 26
  ; $F555 kind 11 (second)
  ; $F55D kind 45
  ; $F570 kind 46 (second)
  ; $F591 kind 47
  ; $F59A kind 48
  ; $F5A3 kind 46
  ; $F5A7 2 bytes no kind record points to (a script of an older build)
  ; $F5A9 kinds 8, 65, 65 (second)
  ; $F5AD kind 52
  ; $F5EA kind 54
  ; $F5F3 kind 57
  ; $F616 kind 58
  ; $F639 kind 61
  ; $F646 kind 49
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
  ; $F64D kinds 1, 1 (second), 4, 5, 6, 7, 11, 12, 13, 14, 15, 16, 19, 20,
  ;   21, 25, 27, 29, 32, 44, 46, 55, 59, 60, 62, 65, 66, 67, 68
  ; $F652 kind 2
  ; $F65B kinds 3, 30
  ; $F660 kind 5 (second)
  ; $F66D kind 6 (second)
  ; $F67C kind 4 (second)
  ; $F681 kind 7 (second)
  ; $F690 kind 8
  ; $F69B kind 9
  ; $F6A0 kind 10
  ; $F6AF kind 11 (second)
  ; $F6E8 kind 12 (second)
  ; $F793 kind 13 (second)
  ; $F7A0 kind 14 (second)
  ; $F7B3 9 bytes no kind record points to (a path of an older build)
  ; $F7BC kind 21 (second)
  ; $F7C9 kind 15 (second)
  ; $F7D6 kind 24
  ; $F7DD kind 18
  ; $F7E8 kind 19 (second)
  ; $F7FF kind 20 (second)
  ; $F816 kind 23
  ; $F82D kind 27 (second)
  ; $F836 kind 28
  ; $F83F kind 29 (second)
  ; $F846 5 bytes no kind record points to (a path of an older build)
  ; $F84B kind 31
  ; $F85E kind 35
  ; $F86D kind 36
  ; $F878 kind 37
  ; $F88B kind 38
  ; $F894 kind 39
  ; $F89D kind 40
  ; $F8A6 kind 41
  ; $F8C1 kind 33
  ; $F8EE kind 32 (second)
  ; $F911 kind 34
  ; $F938 kind 24 (second)
  ; $F93F kind 17
  ; $F944 kind 26
  ; $F95B kind 42
  ; $F964 kind 43
  ; $F969 kind 44 (second)
  ; $F972 kind 22
  ; $F977 kind 45
  ; $F98A kind 46 (second)
  ; $F997 kind 47
  ; $F9A0 kind 48
  ; $F9A9 kind 49
  ; $F9B4 kind 52
  ; $F9C9 kind 54
  ; $F9D2 kind 55 (second)
  ; $F9DB kind 56
  ; $FA06 kind 57
  ; $FA19 kind 58
  ; $FA2C kind 59 (second)
  ; $FA39 kind 60 (second)
  ; $FA46 kind 61
  ; $FA53 kind 62 (second)
  ; $FA66 kind 63
  ; $FA85 kind 64
  ; $FA90 kind 65 (second)
  ; $FA99 kind 66 (second)
  ; $FAA2 kind 67 (second)
  ; $FAC3 kind 68 (second)
  INCBIN "res/level/paths.bin",$0000,1151

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
  ; $FACC kind 1: 24 x 21, flags $C0, path $F64D, anim $F2BB, second path
  ;   $F64D, anim $F2C1
  INCBIN "res/level/kinds-2.bin",$0000,11
Kind2:
  ; $FAD7 kind 2: 24 x 12, flags $50, path $F652, anim $F2C8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$000B,7
Kind3:
  ; $FADE kind 3: 24 x 21, flags $F0, path $F65B, anim $F2D1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0012,7
Kind4:
  ; $FAE5 kind 4: 24 x 8, flags $A0, path $F64D, anim $F303, second path
  ;   $F67C, anim $F308
  INCBIN "res/level/kinds-2.bin",$0019,11
Kind5:
  ; $FAF0 kind 5: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $F660, anim $F2DC
  INCBIN "res/level/kinds-2.bin",$0024,11
Kind6:
  ; $FAFB kind 6: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $F66D, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$002F,11
Kind7:
  ; $FB06 kind 7: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $F681, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$003A,11
Kind8:
  ; $FB11 kind 8: 16 x 16, flags $A0, path $F690, anim $F5A9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0045,7
Kind9:
  ; $FB18 kind 9: 24 x 21, flags $F0, path $F69B, anim $F2D1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$004C,7
Kind10:
  ; $FB1F kind 10: 16 x 16, flags $50, path $F6A0, anim $F30F (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0053,7
Kind11:
  ; $FB26 kind 11: 16 x 16, flags $F0, path $F64D, anim $F2D8, second path
  ;   $F6AF, anim $F555
  INCBIN "res/level/kinds-2.bin",$005A,11
Kind12:
  ; $FB31 kind 12: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $F6E8, anim $F2E5
  INCBIN "res/level/kinds-2.bin",$0065,11
Kind13:
  ; $FB3C kind 13: 24 x 21, flags $D0, path $F64D, anim $F388, second path
  ;   $F793, anim $F38C
  INCBIN "res/level/kinds-2.bin",$0070,11
Kind14:
  ; $FB47 kind 14: 24 x 21, flags $10, path $F64D, anim $F2B7, second path
  ;   $F7A0, anim $F394
  INCBIN "res/level/kinds-2.bin",$007B,11
Kind15:
  ; $FB52 kind 15: 24 x 8, flags $A0, path $F64D, anim $F303, second path
  ;   $F7C9, anim $F308
  INCBIN "res/level/kinds-2.bin",$0086,11
Kind16:
  ; $FB5D kind 16: 24 x 8, flags $40, path $F64D, anim $F46F (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0091,7
Kind17:
  ; $FB64 kind 17: 16 x 16, flags $50, path $F93F, anim $F3EA (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0098,7
Kind18:
  ; $FB6B kind 18: 16 x 16, flags $F0, path $F7DD, anim $F2F8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$009F,7
Kind19:
  ; $FB72 kind 19: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $F7E8, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$00A6,11
Kind20:
  ; $FB7D kind 20: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $F7FF, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$00B1,11
Kind21:
  ; $FB88 kind 21: 24 x 21, flags $00, path $F64D, anim $F2B7, second path
  ;   $F7BC, anim $F3B9
  INCBIN "res/level/kinds-2.bin",$00BC,11
Kind22:
  ; $FB93 kind 22: 24 x 21, flags $50, path $F972, anim $F3F9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00C7,7
Kind23:
  ; $FB9A kind 23: 4 x 6, flags $50, path $F816, anim $F41E (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00CE,7
Kind24:
  ; $FBA1 kind 24: 24 x 8, flags $10, path $F7D6, anim $F53E, second path
  ;   $F938, anim $F431
  INCBIN "res/level/kinds-2.bin",$00D5,11
Kind25:
  ; $FBAC kind 25: 24 x 8, flags $50, path $F64D, anim $F437 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00E0,7
Kind26:
  ; $FBB3 kind 26: 4 x 8, flags $50, path $F944, anim $F542 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00E7,7
Kind27:
  ; $FBBA kind 27: 16 x 16, flags $F0, path $F64D, anim $F2D8, second path
  ;   $F82D, anim $F43D
  INCBIN "res/level/kinds-2.bin",$00EE,11
Kind28:
  ; $FBC5 kind 28: 24 x 8, flags $50, path $F836, anim $F456 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00F9,7
Kind29:
  ; $FBCC kind 29: 24 x 21, flags $D0, path $F64D, anim $F388, second path
  ;   $F83F, anim $F463
  INCBIN "res/level/kinds-2.bin",$0100,11
Kind30:
  ; $FBD7 kind 30: 16 x 21, flags $50, path $F65B, anim $F474 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$010B,7
Kind31:
  ; $FBDE kind 31: 24 x 8, flags $50, path $F84B, anim $F47D (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0112,7
Kind32:
  ; $FBE5 kind 32: 16 x 16, flags $F0, path $F64D, anim $F2D8, second path
  ;   $F8EE, anim $F507
  INCBIN "res/level/kinds-2.bin",$0119,11
Kind33:
  ; $FBF0 kind 33: 16 x 16, flags $50, path $F8C1, anim $F2FC (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0124,7
Kind34:
  ; $FBF7 kind 34: 16 x 16, flags $50, path $F911, anim $F2FC (7 bytes)
  INCBIN "res/level/kinds-2.bin",$012B,7
Kind35:
  ; $FBFE kind 35: 24 x 8, flags $A0, path $F85E, anim $F308 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0132,7
Kind36:
  ; $FC05 kind 36: 24 x 8, flags $A0, path $F86D, anim $F308 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0139,7
Kind37:
  ; $FC0C kind 37: 24 x 12, flags $50, path $F878, anim $F490 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0140,7
Kind38:
  ; $FC13 kind 38: 24 x 21, flags $50, path $F88B, anim $F4B3 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0147,7
Kind39:
  ; $FC1A kind 39: 24 x 21, flags $50, path $F894, anim $F4C4 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$014E,7
Kind40:
  ; $FC21 kind 40: 24 x 21, flags $50, path $F89D, anim $F4CD (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0155,7
Kind41:
  ; $FC28 kind 41: 24 x 12, flags $50, path $F8A6, anim $F4D6 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$015C,7
Kind42:
  ; $FC2F kind 42: 24 x 21, flags $F0, path $F95B, anim $F2D1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0163,7
Kind43:
  ; $FC36 kind 43: 24 x 21, flags $F0, path $F964, anim $F2D1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$016A,7
Kind44:
  ; $FC3D kind 44: 24 x 21, flags $F0, path $F64D, anim $F2CD, second path
  ;   $F969, anim $F2D1
  INCBIN "res/level/kinds-2.bin",$0171,11
Kind45:
  ; $FC48 kind 45: 4 x 6, flags $50, path $F977, anim $F55D (7 bytes)
  INCBIN "res/level/kinds-2.bin",$017C,7
Kind46:
  ; $FC4F kind 46: 24 x 12, flags $50, path $F64D, anim $F5A3, second path
  ;   $F98A, anim $F570
  INCBIN "res/level/kinds-2.bin",$0183,11
Kind47:
  ; $FC5A kind 47: 24 x 21, flags $50, path $F997, anim $F591 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$018E,7
Kind48:
  ; $FC61 kind 48: 24 x 21, flags $50, path $F9A0, anim $F59A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0195,7
Kind49:
  ; $FC68 kinds 49, 50, 51: 24 x 8, flags $50, path $F9A9, anim $F646 (7
  ;   bytes)
  INCBIN "res/level/kinds-2.bin",$019C,7
Kind52:
  ; $FC6F kinds 52, 53: 24 x 12, flags $50, path $F9B4, anim $F5AD (7
  ;   bytes)
  INCBIN "res/level/kinds-2.bin",$01A3,7
Kind54:
  ; $FC76 kind 54: 24 x 21, flags $50, path $F9C9, anim $F5EA (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01AA,7
Kind55:
  ; $FC7D kind 55: 16 x 16, flags $F0, path $F64D, anim $F2D8, second path
  ;   $F9D2, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$01B1,11
Kind56:
  ; $FC88 kind 56: 24 x 8, flags $A0, path $F9DB, anim $F308 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01BC,7
Kind57:
  ; $FC8F kind 57: 24 x 12, flags $50, path $FA06, anim $F5F3 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01C3,7
Kind58:
  ; $FC96 kind 58: 24 x 12, flags $50, path $FA19, anim $F616 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01CA,7
Kind59:
  ; $FC9D kind 59: 24 x 8, flags $A0, path $F64D, anim $F303, second path
  ;   $FA2C, anim $F308
  INCBIN "res/level/kinds-2.bin",$01D1,11
Kind60:
  ; $FCA8 kind 60: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $FA39, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$01DC,11
Kind61:
  ; $FCB3 kind 61: 16 x 16, flags $50, path $FA46, anim $F639 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01E7,7
Kind62:
  ; $FCBA kind 62: 24 x 8, flags $A0, path $F64D, anim $F303, second path
  ;   $FA53, anim $F308
  INCBIN "res/level/kinds-2.bin",$01EE,11
Kind63:
  ; $FCC5 kind 63: 16 x 16, flags $D0, path $FA66, anim $F2F8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01F9,7
Kind64:
  ; $FCCC kind 64: 24 x 8, flags $A0, path $FA85, anim $F308 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0200,7
Kind65:
  ; $FCD3 kind 65: 24 x 8, flags $A0, path $F64D, anim $F5A9, second path
  ;   $FA90, anim $F5A9
  INCBIN "res/level/kinds-2.bin",$0207,11
Kind66:
  ; $FCDE kind 66: 16 x 16, flags $F0, path $F64D, anim $F2D8, second path
  ;   $FA99, anim $F2DC
  INCBIN "res/level/kinds-2.bin",$0212,11
Kind67:
  ; $FCE9 kind 67: 16 x 16, flags $D0, path $F64D, anim $F2D8, second path
  ;   $FAA2, anim $F2F8
  INCBIN "res/level/kinds-2.bin",$021D,11
Kind68:
  ; $FCF4 kind 68: 24 x 21, flags $F0, path $F64D, anim $F2CD, second path
  ;   $FAC3, anim $F2D1
  INCBIN "res/level/kinds-2.bin",$0228,11

; 1 zero bytes to the block's end $FCFF
;
; Read by no code.
FreeTail:
  DEFS $01
