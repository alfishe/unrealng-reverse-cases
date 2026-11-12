; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 handler and the AY music call
; --------------------------------------------------------------------------------------------------------------------

  ORG $9491

; The IM 2 handler: the AY music from RAM 6 on a 128K
;
; Reached through the vector `JP $9491` at `$5F5F` on every interrupt (83616
; runs: one a frame in every build after GameEntry). On a 128K (Has128K `$5FFE`
; not 0) it pages RAM 6 in (`$7FFD` = `$16`), calls the music player at `$C000`
; and pages back the value in Last7FFD `$5FE5`; AF and BC are kept, the player
; keeps the rest. On a 48K it only enables the interrupts again: no music.
;
; Witness: L1 83616 (c1, explorers, gameover, rzx x31).
Im2Handler:
  PUSH AF
  LD A,(Has128K)
  OR A
  JR Z,Im2Done
  PUSH BC
  LD BC,$7FFD             ; RAM 6, ROM 1
  LD A,$16
  OUT (C),A
  CALL MusicFrame         ; the music player (part MUS)
  LD A,(Last7FFD)            ; the page the game had
  LD BC,$7FFD
  OUT (C),A
  POP BC
Im2Done:
  POP AF
  EI
  RET
