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
  ; $F1CC the end
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
  ; $F239 kind 8
  ; $F23D kind 1
  ; $F244 kinds 2, 2 (second), 4, 4 (second), 15, 15 (second), 24, 24
  ;   (second), 28, 28 (second), 32, 36, 36 (second), 38, 38 (second)
  ; $F248 kind 53
  ; $F24A kind 13
  ; $F24E kind 5
  ; $F255 kind 6
  ; $F25B kinds 39, 40, 41, 42, 43
  ; $F26A 32 bytes no kind record points to (a script of an older build)
  ; $F28A kind 7
  ; $F293 kind 8 (second)
  ; $F2A9 kinds 9, 9 (second), 10, 10 (second), 34, 35, 35 (second), 37,
  ;   54, 54 (second)
  ; $F2AD kind 11
  ; $F2B1 kind 12
  ; $F2C7 kind 14
  ; $F2CE kind 16
  ; $F2D2 kind 17
  ; $F2D9 kind 18
  ; $F2DD kinds 19, 46
  ; $F2E1 kind 20
  ; $F2E8 kind 21
  ; $F2EF kind 22
  ; $F2F6 kind 23
  ; $F2FD kind 25
  ; $F304 7 bytes no kind record points to (a script of an older build)
  ; $F30B kinds 26, 27
  ; $F314 kind 29
  ; $F31B kind 30
  ; $F324 kind 31
  ; $F32B kind 33
  ; $F330 kind 3
  ; $F340 kind 44
  ; $F359 kinds 19 (second), 46 (second)
  ; $F35E kind 45
  ; $F362 kind 47
  ; $F372 kind 48
  ; $F382 kind 49
  ; $F389 kind 50
  ; $F38D kind 51
  ; $F394 kind 52
  ; $F398 kind 52 (second)
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
  ; $F3A3 kinds 2, 4, 8, 9, 10, 13, 14, 15, 16, 17, 24, 28, 35, 36, 38, 44,
  ;   45, 52, 53
  ; $F3A8 kind 1
  ; $F3B3 kind 2 (second)
  ; $F3BE kind 4 (second)
  ; $F3CD kind 5
  ; $F3D4 kind 6
  ; $F3DF kind 7
  ; $F3EA kind 8 (second)
  ; $F3F9 kind 9 (second)
  ; $F408 kind 34
  ; $F413 kind 10 (second)
  ; $F434 kind 11
  ; $F43D kind 12
  ; $F44A kind 15 (second)
  ; $F451 kind 18
  ; $F468 kind 20
  ; $F473 kind 21
  ; $F480 kind 22
  ; $F48D kind 23
  ; $F49A kind 24 (second)
  ; $F4A1 kind 25
  ; $F4AC kind 26
  ; $F4B7 kind 27
  ; $F4C2 kind 28 (second)
  ; $F4C9 kind 29
  ; $F4D0 kind 30
  ; $F4D9 kind 31
  ; $F4E0 kind 32
  ; $F4E7 kind 33
  ; $F4EE kind 35 (second)
  ; $F4F5 kind 36 (second)
  ; $F4FC kind 37
  ; $F503 kind 38 (second)
  ; $F518 kind 3
  ; $F52B kind 39
  ; $F530 kind 40
  ; $F535 kind 41
  ; $F53A kind 42
  ; $F53F kind 43
  ; $F59E kinds 19 (second), 46 (second)
  ; $F5A3 kind 19
  ; $F5BE kind 46
  ; $F5C9 kind 47
  ; $F5DC kind 48
  ; $F5EF kind 49
  ; $F5FA kind 50
  ; $F601 kind 51
  ; $F60A kind 52 (second)
  ; $F60F kinds 54, 54 (second)
  INCBIN "res/level/paths.bin",$0000,653

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
  ; $F630 kind 1: 24 x 8, flags $A0, path $F3A8, anim $F23D (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0000,7
Kind2:
  ; $F637 kind 2: 24 x 16, flags $F0, path $F3A3, anim $F244, second path
  ;   $F3B3, anim $F244
  INCBIN "res/level/kinds-2.bin",$0007,11
Kind3:
  ; $F642 kind 3: 24 x 16, flags $50, path $F518, anim $F330 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0012,7
Kind4:
  ; $F649 kind 4: 24 x 16, flags $F0, path $F3A3, anim $F244, second path
  ;   $F3BE, anim $F244
  INCBIN "res/level/kinds-2.bin",$0019,11
Kind5:
  ; $F654 kind 5: 16 x 16, flags $50, path $F3CD, anim $F24E (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0024,7
Kind6:
  ; $F65B kind 6: 16 x 16, flags $50, path $F3D4, anim $F255 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$002B,7
Kind7:
  ; $F662 kind 7: 16 x 16, flags $50, path $F3DF, anim $F28A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0032,7
Kind8:
  ; $F669 kind 8: 6 x 21, flags $10, path $F3A3, anim $F239, second path
  ;   $F3EA, anim $F293
  INCBIN "res/level/kinds-2.bin",$0039,11
Kind9:
  ; $F674 kind 9: 24 x 8, flags $A0, path $F3A3, anim $F2A9, second path
  ;   $F3F9, anim $F2A9
  INCBIN "res/level/kinds-2.bin",$0044,11
Kind10:
  ; $F67F kind 10: 24 x 8, flags $A0, path $F3A3, anim $F2A9, second path
  ;   $F413, anim $F2A9
  INCBIN "res/level/kinds-2.bin",$004F,11
Kind11:
  ; $F68A kind 11: 24 x 6, flags $50, path $F434, anim $F2AD (7 bytes)
  INCBIN "res/level/kinds-2.bin",$005A,7
Kind12:
  ; $F691 kind 12: 16 x 16, flags $50, path $F43D, anim $F2B1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0061,7
Kind13:
  ; $F698 kind 13: 24 x 21, flags $50, path $F3A3, anim $F24A (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0068,7
Kind14:
  ; $F69F kind 14: 24 x 21, flags $50, path $F3A3, anim $F2C7 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$006F,7
Kind15:
  ; $F6A6 kind 15: 24 x 16, flags $F0, path $F3A3, anim $F244, second path
  ;   $F44A, anim $F244
  INCBIN "res/level/kinds-2.bin",$0076,11
Kind16:
  ; $F6B1 kind 16: 24 x 21, flags $50, path $F3A3, anim $F2CE (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0081,7
Kind17:
  ; $F6B8 kind 17: 24 x 21, flags $50, path $F3A3, anim $F2D2 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0088,7
Kind18:
  ; $F6BF kind 18: 6 x 21, flags $50, path $F451, anim $F2D9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$008F,7
Kind19:
  ; $F6C6 kind 19: 24 x 21, flags $00, path $F5A3, anim $F2DD, second path
  ;   $F59E, anim $F359
  INCBIN "res/level/kinds-2.bin",$0096,11
Kind20:
  ; $F6D1 kind 20: 16 x 16, flags $50, path $F468, anim $F2E1 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00A1,7
Kind21:
  ; $F6D8 kind 21: 16 x 16, flags $50, path $F473, anim $F2E8 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00A8,7
Kind22:
  ; $F6DF kind 22: 6 x 21, flags $50, path $F480, anim $F2EF (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00AF,7
Kind23:
  ; $F6E6 kind 23: 16 x 16, flags $50, path $F48D, anim $F2F6 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00B6,7
Kind24:
  ; $F6ED kind 24: 24 x 16, flags $F0, path $F3A3, anim $F244, second path
  ;   $F49A, anim $F244
  INCBIN "res/level/kinds-2.bin",$00BD,11
Kind25:
  ; $F6F8 kind 25: 24 x 6, flags $50, path $F4A1, anim $F2FD (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00C8,7
Kind26:
  ; $F6FF kind 26: 24 x 6, flags $50, path $F4AC, anim $F30B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00CF,7
Kind27:
  ; $F706 kind 27: 24 x 6, flags $50, path $F4B7, anim $F30B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00D6,7
Kind28:
  ; $F70D kind 28: 24 x 16, flags $F0, path $F3A3, anim $F244, second path
  ;   $F4C2, anim $F244
  INCBIN "res/level/kinds-2.bin",$00DD,11
Kind29:
  ; $F718 kind 29: 16 x 16, flags $50, path $F4C9, anim $F314 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00E8,7
Kind30:
  ; $F71F kind 30: 16 x 16, flags $50, path $F4D0, anim $F31B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00EF,7
Kind31:
  ; $F726 kind 31: 16 x 16, flags $50, path $F4D9, anim $F324 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00F6,7
Kind32:
  ; $F72D kind 32: 24 x 16, flags $F0, path $F4E0, anim $F244 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$00FD,7
Kind33:
  ; $F734 kind 33: 24 x 21, flags $A0, path $F4E7, anim $F32B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0104,7
Kind34:
  ; $F73B kind 34: 24 x 8, flags $A0, path $F408, anim $F2A9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$010B,7
Kind35:
  ; $F742 kind 35: 24 x 8, flags $A0, path $F3A3, anim $F2A9, second path
  ;   $F4EE, anim $F2A9
  INCBIN "res/level/kinds-2.bin",$0112,11
Kind36:
  ; $F74D kind 36: 24 x 16, flags $F0, path $F3A3, anim $F244, second path
  ;   $F4F5, anim $F244
  INCBIN "res/level/kinds-2.bin",$011D,11
Kind37:
  ; $F758 kind 37: 24 x 8, flags $A0, path $F4FC, anim $F2A9 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0128,7
Kind38:
  ; $F75F kind 38: 24 x 21, flags $F0, path $F3A3, anim $F244, second path
  ;   $F503, anim $F244
  INCBIN "res/level/kinds-2.bin",$012F,11
Kind39:
  ; $F76A kind 39: 24 x 21, flags $50, path $F52B, anim $F25B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$013A,7
Kind40:
  ; $F771 kind 40: 24 x 21, flags $50, path $F530, anim $F25B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0141,7
Kind41:
  ; $F778 kind 41: 24 x 21, flags $50, path $F535, anim $F25B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0148,7
Kind42:
  ; $F77F kind 42: 24 x 21, flags $50, path $F53A, anim $F25B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$014F,7
Kind43:
  ; $F786 kind 43: 24 x 21, flags $50, path $F53F, anim $F25B (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0156,7
Kind44:
  ; $F78D kind 44: 24 x 21, flags $00, path $F3A3, anim $F340 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$015D,7
Kind45:
  ; $F794 kind 45: 24 x 21, flags $50, path $F3A3, anim $F35E (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0164,7
Kind46:
  ; $F79B kind 46: 24 x 21, flags $00, path $F5BE, anim $F2DD, second path
  ;   $F59E, anim $F359
  INCBIN "res/level/kinds-2.bin",$016B,11
Kind47:
  ; $F7A6 kind 47: 24 x 16, flags $50, path $F5C9, anim $F362 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0176,7
Kind48:
  ; $F7AD kind 48: 24 x 16, flags $50, path $F5DC, anim $F372 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$017D,7
Kind49:
  ; $F7B4 kind 49: 16 x 16, flags $50, path $F5EF, anim $F382 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0184,7
Kind50:
  ; $F7BB kind 50: 24 x 6, flags $50, path $F5FA, anim $F389 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$018B,7
Kind51:
  ; $F7C2 kind 51: 16 x 16, flags $50, path $F601, anim $F38D (7 bytes)
  INCBIN "res/level/kinds-2.bin",$0192,7
Kind52:
  ; $F7C9 kind 52: 16 x 16, flags $00, path $F3A3, anim $F394, second path
  ;   $F60A, anim $F398
  INCBIN "res/level/kinds-2.bin",$0199,11
Kind53:
  ; $F7D4 kind 53: 24 x 16, flags $50, path $F3A3, anim $F248 (7 bytes)
  INCBIN "res/level/kinds-2.bin",$01A4,7
Kind54:
  ; $F7DB kind 54: 24 x 8, flags $A0, path $F60F, anim $F2A9, second path
  ;   $F60F, anim $F2A9
  INCBIN "res/level/kinds-2.bin",$01AB,11
