; --------------------------------------------------------------------------------------------------------------------
; stage2end-module.asm: Stage2End (TZX block 31)
;
; The second stage's new end, loaded over $FEFC once the game's blocks are in.
; --------------------------------------------------------------------------------------------------------------------

; Wipe memory if a check failed; IY = $5C3A, IM 1, HL' = $2758, border 0, R =
; 0, I = $3F, SP = $6FFD, JP Decipher
;
; Witness: L1 1 (c1).
Stage2End:
  LD A,(SL7Pattern)
  OR A
  CALL NZ,SL7WipeTrap
  LD IY,$5C3A
  IM 1
  LD HL,$2758
  EXX
  LD A,$00
  OUT ($FE),A
  LD A,$00
  LD R,A
  LD A,$3F
  LD I,A
  LD SP,$6FFD
  DI
  LD HL,$0000
  LD DE,$0000
  LD BC,$0001
  LD (HL),$00
  LDIR
  JP $FE40
