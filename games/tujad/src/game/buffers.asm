; --------------------------------------------------------------------------------------------------------------------
; buffers.asm: The exhaust, the blank graphic, the ED flags and the sprite save buffers
;
; The exhaust is a flicker of four three-byte patterns under the droid (DroidExhaust $8DD2); NewGame $7A44 zeroes
; $65E5-$668B (the exhaust rows, BlankGraphic and EdFlags). The image's bytes from $65E5 are Leftover text (the
; authors' source, src/res/leftover/Source3.txt): every one is written before it is read.
; --------------------------------------------------------------------------------------------------------------------

; The four exhaust rows' pattern records
;
; ExhaustStep $8E7E steps the four rows through ExhaustRow / ExhaustRowLeft
; with these (L1 18 571 passes). The image's values point at the first four
; ExhaustPatterns.
ExhaustPtrs:
  DEFW ExhaustPatterns,$65BA,$65BE,$65C2

; Eight exhaust pattern records: a life counter, three bytes of pixels
;
; ExhaustRow $8EC7 rotates a record's three bytes one pixel a pass; when its
; counter runs out ExhaustPick $8EAC takes a random record whose counter is 0
; and gives it 8-39 passes (Random $7DC9: L1 5 012 tries, 3 134 picks).
ExhaustPatterns:
  DEFB $08,$F0,$F0,$F0
  DEFB $08,$FC,$FC,$FC
  DEFB $08,$07,$07,$07
  DEFB $08,$18,$CA,$31
  DEFB $00,$FE,$FE,$FE
  DEFB $00,$EE,$EE,$EE
  DEFB $00,$F6,$F6,$F6
  DEFB $00,$BD,$BD,$BD

; The masks of the exhaust rows: $FF $00 (frames 11 and the walk), $0F $F0
; (frame 12)
;
; ExhaustMask $8F1B ANDs the three bytes of each row with (mask 1, $FF, mask
; 2): $65D6 for frame 11 and the walk, $65D8 for frame 12 (the droid seen from
; the front).
ExhaustMasks:
  DEFB $FF,$00
  DEFB $0F,$F0

; The attributes of the weapon items 1-3 (DrawItem $6E65)
;
; $43, $44, $46: the same attributes ShowWeapon $79D5 gives the HUD icons of
; weapons 1-3. DrawItem reads WeaponColours - 1 + the weapon number (L1 25
; reads).
WeaponColours:
  DEFB $43,$44,$46

; Weapon 0's shot: one byte, 8 rows (a short dash on the top row)
;
; FireBasic $8767 puts it in the shot (L1 734 shots); the interrupt XORs it as
; a 1 x 1 sprite.
ShotGraphic0:
  DEFB $3F,$00,$00,$00,$00,$00,$00,$00

; The exhaust's 8 rows of 3 bytes as drawn, then the four pattern rows ($65FD)
;
; ExhaustMask $8F1B writes the masked rows here; DroidExhaust $8DD2 XORs them
; under the droid twice a pass. Leftover text in the image.
ExhaustRows:
  INCBIN "res/leftover/Source3.bin",$0000,24
ExhaustRaw:
  INCBIN "res/leftover/Source3.bin",$0018,12

; 120 zero bytes: the frame of an empty or materialising sprite
;
; NewGame zeroes it; DrawRoom gives it to the waiting enemies ($6BB0), the
; droid starts with it (InitialVars), ShowWeapon $7A17 prints it to blank the
; ammunition.
BlankGraphic:
  INCBIN "res/leftover/Source3.bin",$0024,120

; The ED pieces taken: ten bytes, bits 0-4 of each, 50 pieces
;
; ProgressScreen $8F53, called by EdPickup $7703 with the piece number, sets
; the bit of a piece; WinTest $69E3 waits for all ten bytes to be $1F;
; ProgressScreen $8F53 shows them. NewGame zeroes them.
EdFlags:
  INCBIN "res/leftover/Source3.bin",$009C,10
EdFlagsEnd:
  INCBIN "res/leftover/Source3.bin",$00A6,1

; The droid's frame as last drawn: 120 bytes
;
; MoveDroid $72AD copies the frame graphic here each pass, so the interrupt can
; XOR the old image out with the same bytes it drew (L1 15 289).
DroidSave:
  INCBIN "res/leftover/Source3.bin",$00A7,120

; The enemy buffers in use: the draw buffer, the erase buffer
;
; MainLoop sets both before each MoveEnemy call ($6938-$6977). The image's four
; bytes are Leftover text ("l", 6, "lookup"), not addresses.
EnemyBufferPtrs:
  INCBIN "res/leftover/Source3.bin",$011F,4

; Four pairs of 48-byte buffers: an enemy's graphic shifted to its pixel x, as
; drawn and as to erase
;
; Enemy k uses $6708 + 96k and $6738 + 96k (MainLoop). MoveEnemy shifts the
; enemy's graphic into one (ShiftGraphic3 $7EBB) and hands both to the sprite
; list.
EnemyBuffers:
  INCBIN "res/leftover/Source3.bin",$0123,48
EnemyBuffer1B:
  INCBIN "res/leftover/Source3.bin",$0153,48
EnemyBuffer2A:
  INCBIN "res/leftover/Source3.bin",$0183,48
EnemyBuffer2B:
  INCBIN "res/leftover/Source3.bin",$01B3,48
EnemyBuffer3A:
  INCBIN "res/leftover/Source3.bin",$01E3,48
EnemyBuffer3B:
  INCBIN "res/leftover/Source3.bin",$0213,48
EnemyBuffer4A:
  INCBIN "res/leftover/Source3.bin",$0243,48
EnemyBuffer4B:
  INCBIN "res/leftover/Source3.bin",$0273,48
