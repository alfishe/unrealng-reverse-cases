; --------------------------------------------------------------------------------------------------------------------
; tables.asm: The key sets, a leftover map row and the instructions page
;
; The first bytes of the game block. Only KeySets and InstructionsText are read; the rest is what the author's
; assembler left (no build reads it).
; --------------------------------------------------------------------------------------------------------------------

; Leftover: a piece of a map row (a ladder 01 02, the cage's codes $A8 $A9)
;
; Never read or written (L1 of the eight builds: no access). The bytes look
; like a row of a level map (LevelMaps $B3B0 codes: 1 and 2 a ladder, $A8-$A9
; the cage's top), left from an earlier layout of the image.
LeftoverMapRow:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01
  DEFB $02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$A8,$A9,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The three key sets: (mask, port row) for up, down, left, right, jump, jump
;
; SetupLevel $AE9C copies one set into KeyTable at every level start: type 1
; ($8250, KeyType 6, the default) 2 W 9 0 and jump Z or M; type 2 ($825C,
; KeyType 5) 7 6 5 8 (the cursor joystick) and jump 4 or 9; type 3 ($8268,
; KeyType 3) the set RedefineKeys $AA49 writes (Q A O P, jump M or 1 in the
; image). A key is down when (IN (row x 256 + $FE) AND $1F) OR mask is not $1F.
; The editable form is src/res/text/KeySets.txt.
;
; Witness: SetupLevel's copy runs 35 times in the eight builds
; (tools/l1count.py $B0B8); tour-type2 reads $825C, tour-redefine writes
; $8268-$8271 (RedefineKeys clears ten bytes, RedefineOne writes five keys).
KeySets:
  INCBIN "res/text/KeySets.bin",$0000,12
KeySet2:
  INCBIN "res/text/KeySets.bin",$000C,12
KeySet3:
  INCBIN "res/text/KeySets.bin",$0018,12

; 194 zeros
;
; Never read (L1: no access).
Zeros8274:
  DEFS $C2

; Leftover: three menu lines with zeros for spaces
;
; Never read (L1: no access). Text of an earlier menu
; (src/res/text/MenuLeftover.txt); the game's menu texts are MenuTexts $ABF2.
MenuLeftover:
  INCBIN "res/text/MenuLeftover.bin",$0000,90

; The instructions page: 11 rows of 32, the bottom row first
;
; InstructionsPage $A4C8 prints row k at character row 3 + 2k (from the
; bottom), so the page fills every other row of the screen; the editable form
; is src/res/text/InstructionsText.txt (top row first). RedefineKeys $AA49 and
; RedefineOne $AB19 write the new key names into row 3 of the page ($83F6,
; $83FB, $8400, $8405, $840A: up, down, left, right, jump), so the page shows
; the redefined set.
;
; Witness: InstructionsPage runs in c1, idle-1p, tour-type2 and tour-redefine;
; tour-redefine writes the five bytes.
InstructionsText:
  INCBIN "res/text/InstructionsText.bin",$0000,352
