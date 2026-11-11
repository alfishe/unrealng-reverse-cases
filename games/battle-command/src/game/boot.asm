; --------------------------------------------------------------------------------------------------------------------
; boot.asm: The entry: the IM 2 set-up and the jump to the title menu
; --------------------------------------------------------------------------------------------------------------------

; The game's entry from the bootstrap: stack, IM 2 table, border, then the
; title menu in bank 6
;
; Under `DI`: `SP` = `$81FF`, the 257-byte vector table `$8200-$8300` filled
; with `$83` (`I` = `$82`, every vector `$8383`), `JP $8383` at `$8181`, `IM
; 2`, `EI`; the border to black (`BorderBlack` `$6CEB`), bank 6 paged, `JP
; $C409` (the title menu). The eight `NOP`s at `$691A` are room left for a
; patch.
;
; Witness: c1 frame 23974 (the bootstrap's `JP $68F4`,
; docs/03-build-and-load.md); no recording after the entry runs it (L1 0).
Entry:
  DI
  LD SP,Stack+$007B
  LD HL,Im2Table
  LD DE,Im2Table+$0001
  LD BC,$0100
  LD (HL),$83
  LDIR
  LD A,$82
  LD I,A
  LD A,$C3
  LD (ImJump),A
  LD HL,InterruptHandler
  LD (ImJump+$0001),HL
  IM 2
  EI
  CALL BorderBlack
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL PageBank6
  JP TitleMenu

; Reset the collision tables of bank 0 before a mission: clear bit 7 of
; $C774-$C78A, fill $C648-$C773 with $FF, point the camera at the player
;
; Called from bank 6 `$CA8B` (the catalogue screen): pages bank 0, clears bit 7
; of `$C774-$C78A` (the slot list), sets the 300 bytes from `$C648`
; (CollisionTables) to `$FF`, calls CameraToPlayer `$C357` (bank 0: all three
; addresses are bank 0's, bank 6 holds code there), returns with bank 6 paged
; (`JP $7278`).
;
; Witness: L1 19 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ResetCollisionTables:
  CALL PageBank0
  LD B,$17
  LD HL,CollisionTables+$012C
l_6930:
  LD A,(HL)
  AND $7F
  LD (HL),A
  INC HL
  DJNZ l_6930
  LD HL,CollisionTables
  LD BC,$012C
l_693D:
  LD (HL),$FF
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_693D
  CALL CameraToPlayer
  JP PageBank6
