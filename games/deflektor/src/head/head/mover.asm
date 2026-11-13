; --------------------------------------------------------------------------------------------------------------------
; mover.asm: The mover: the decrypted game down to $6000 and into it
;
; Decrypted by Final16 with the game and jumped to by FinalSum. It copies $7D00-$FCFF to $6000-$DFFF (the game's
; place, src/game/game.ann), clears REPDEL / REPPER with BC = 0, sets SP = $FFFF, clears bit 7 of R and jumps to the
; game's entry. The game then clears $FD00-$FDFA for the level grid (LevelGrid $FD23), wiping the mover.
; --------------------------------------------------------------------------------------------------------------------

; $7D00-$FCFF to $6000-$DFFF, BC = 0 to $5C09, SP = $FFFF, bit 7 of R cleared,
; JP GameEntry $8382
;
; The game's own copy of these bytes is the decrypted block; the mover's last
; word (the `JP $8382` operand) is the word FinalSum adds `$7A3D` to, so the
; jump to `$FD00` and the game's entry are one word.
;
; c1: one run.
;
; Witness: L1 3 (c1).
MoveGame:
  LD HL,$7D00
  LD DE,GameBase
  LD BC,$8000
  LDIR
  LD ($5C09),BC           ; BC = 0 after the LDIR: REPDEL and REPPER zeroed
  LD SP,$FFFF
  LD A,R                  ; bit 7 of R cleared (FinalSum set it)
  RES 7,A
  LD R,A
  JP GameEntry
