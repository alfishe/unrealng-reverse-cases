; --------------------------------------------------------------------------------------------------------------------
; sl1-module.asm: The second stage: the screen, the block table, the countdown digits
;
; LoaderMain loads this block over $FF26 and runs into it. Sl1Start points LoadStream's last-byte path at StoreLast,
; then reads the screen's bitmap and every block BlockTable names, each after its mark: the attributes to $8000, the
; resident's first piece to $DE80, the key patches at $FDB5 and $FDE9, then a new table over this one (block 23) whose
; rows load the rest of the resident and the loader's last pieces. The stream returns to $FF3A, which block 31 has
; replaced by then with Sl1End (src/loader/sl1end.asm).
;
; c1: the stage runs once (L1 1 on Sl1Start); the digits at CountdownDigits are the countdown on the screen (character
; row 20, columns 13-18, the last digit at $5092) while the blocks load.
; --------------------------------------------------------------------------------------------------------------------

; Load the screen and the table's blocks, then the end of the stage
;
; AttrRevealOff := 0 (the attributes are not on the screen yet: the hook only
; pads its time); IX = Screen, DE = $17FF (6144 bytes); LastStoreJump :=
; StoreLast, so the bitmap's last byte goes through StoreLast and the walk of
; BlockTable follows; CALL LoadStream. Outputs: the blocks in memory, FailFlag.
; Side effects: the screen drawn, the table rewritten by its own block.
;
; Witness: L1 1 (c1).
Sl1Start:
  XOR A
  LD (AttrRevealOff),A
  LD IX,Screen             ; IX = Screen, DE = 6144 - 1
  LD DE,$17FF
  LD HL,StoreLast             ; the last byte goes to StoreLast
  LD (LastStoreJump),HL
  CALL LoadStream              ; returns to $FF3A: by then Sl1End (block 31)

; The stage's own end, replaced by Sl1End before it runs: the reveal task on a
; failure, then a wipe
;
; If FailFlag is set, CALL AttrRevealStart; then LD (HL),0 / INC HL from Screen
; upwards for ever. Block 31 loads Sl1End over these bytes before LoadStream
; returns, so this form is not executed in any recording (c1 checked: the L1 at
; $FF3A counts Sl1End, which shares the first four bytes). Known only from the
; code ($FF3A-$FF48).
Sl1Tail:
  LD A,(FailFlag)
  OR A
  CALL NZ,AttrRevealStart
  LD HL,Screen
Sl1TailWipe:
  LD (HL),$00             ; LD (HL),0 / INC HL for ever
  INC HL
  JR Sl1TailWipe

; The first block table: five bytes a row, the address, the length less one,
; the $7FFD value
;
; Read by StoreLast's table walk (c1). Rows 0-4: $8000 768 bytes (the loading
; screen's attributes, revealed by AttrRevealStart), $DE80 1152 (the resident's
; piece $F300-$F77F, XORed with $DF), $FDB5 2 (the body key), $FDE9 4 (the
; last-byte key), $FF49 55 (this table again: block 23's rows 5-10 are $DB80
; 768, $E300 2176, $FE76 115 (Unxor), $FF3A 15 (Sl1End), $5B00 33 (Boot), the
; end). Rows 5-7 here ($6000 8192 page $13, $4000 6912 page $12, $FB00 512) are
; never read: block 23 rewrites them first. Row 8 is the end (a zero $7FFD
; value). src/tape/tape.txt has the blocks.
BlockTable:
  DEFB $00,$80,$FF,$02,$10
  DEFB $80,$DE,$7F,$04,$10 ; row 1: $DE80, the resident's first piece
  DEFB $B5,$FD,$01,$00,$10 ; row 2: $FDB5, the body key
  DEFB $E9,$FD,$03,$00,$10 ; row 3: $FDE9, the last-byte key
  DEFB $49,$FF,$36,$00,$10 ; row 4: $FF49, this table (block 23)
  DEFB $00,$60,$FF,$1F,$13,$00,$40,$FF ; rows 5-7: never read
  DEFB $1A,$12,$00,$FB,$FF,$01,$10
  DEFB $00,$00,$00,$00,$00 ; row 8: the end
BlockTablePad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; zeros up to the digits
  DEFB $00,$00

; The countdown's digits 0-9, 8 bytes each
;
; Read by the countdown in AttrRevealStart (src/loader/chain.asm, $FC73): a
; digit's glyph is $FF80 + 8 x digit, the four digit pointers at $FD07-$FD0A
; hold the glyphs' low bytes. c1: the digits on the loading screen at character
; row 20, columns 13-18 (the last digit at $5092) while the blocks load.
CountdownDigits:
  INCBIN "res/loader/countdown-digits.bin",$0000,80
