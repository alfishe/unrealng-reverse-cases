; --------------------------------------------------------------------------------------------------------------------
; trails.asm: The six trails: the records, the object lists, the animated objects
;
; A trail is a record of three words (TrailRecords for trails 1-4, Trail5 $EE84, Trail6 $60AC copied from $F230 by
; GameEntry): list A (the ground and the obstacles the ATV rides over and hits), list B (the scenery behind: drawn
; after the ATV's ground test, so it never stops it), and the length; FinishDistance = the length - $48. A list is
; items of six bytes in order of distance: +0 the distance word, +2 y (0: the sprite's height, filled by
; InitListWidths), +3 the advance (filled by InitListWidths), +4 the sprite number and +5 the flags (bit 0 the sprite
; from the menu bank (MenuSprite) with its attributes (DeferAttrs); bits 1-3 shifted into ItemFlags bits 5-7: bit 1
; deferred to DeferredB (drawn before the ATV), bit 2 to DeferredA (after it), bit 3 masked); flags bits 4-7 set make
; +4/+5 the address of an animation record instead. $FF at +1 ends a list. List A scrolls with the distance (Distance
; $D789-$D78B, a step of speed x 128 a pass), list B at a quarter of it ($D78E-$D790, speed x 32).
; --------------------------------------------------------------------------------------------------------------------

  ORG $7C9C

; Trails 1-4: list A, list B, length
;
; Read by SelectTrail ($EC9C) as TrailRecords + 6 x Trail (c1: trail 1; trails:
; trails 1-2; warp: 3-4).
TrailRecords:
  INCBIN "res/trails/trails14.bin",$0000,24

; Trail 1's list A (the ground and obstacles)
Trail1ListA:
  INCBIN "res/trails/trails14.bin",$0018,128

; Trail 2's list A
Trail2ListA:
  INCBIN "res/trails/trails14.bin",$0098,236

; Trail 3's list A
Trail3ListA:
  INCBIN "res/trails/trails14.bin",$0184,224

; Trail 4's list A
Trail4ListA:
  INCBIN "res/trails/trails14.bin",$0264,128

; Trail 1's list B (the scenery)
Trail1ListB:
  INCBIN "res/trails/trails14.bin",$02E4,50

; Trail 2's list B
Trail2ListB:
  INCBIN "res/trails/trails14.bin",$0316,56

; Trail 3's list B
Trail3ListB:
  INCBIN "res/trails/trails14.bin",$034E,32

; Trail 4's list B
Trail4ListB:
  INCBIN "res/trails/trails14.bin",$036E,56

; The animation records of trails 1-4's animated objects
;
; An item whose flags have bits 4-7 set points here: +0 the sprite, +1 the
; flags, +2 the object's id (AnimObject keeps a list of 30 seen ids), then the
; record's own bytes (the frames and the motion), up to $FF.
AnimRecords:
  INCBIN "res/trails/trails14.bin",$03A6,57

; "REGROUND|": a text no code prints (a leftover of "FOREGROUND" or
; "BACKGROUND")
TrailsTextLeftover:
  DEFM "REGRO"

  ORG $EE84

; Trail 5 (TROPICANA): its record (list A $EE8A, list B $EF52, length $06B5),
; the lists and its animation records
Trail5:
  INCBIN "res/trails/trail5.bin",$0000,437

; 3 bytes after trail 5 (with the 33 before them, $F018-$F038, shaped as
; animation records no item points at: leftovers)
Trail5Tail:
  INCBIN "res/trails/trail5.bin",$01B5,3
