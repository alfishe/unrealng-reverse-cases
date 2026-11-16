; --------------------------------------------------------------------------------------------------------------------
; loader-module.asm: The machine-code loader: the screen and the game by LD-BYTES, the headers before them skipped
;
; Entered by the BASIC's RANDOMIZE USR 65500 (c1, frame 1017). It asks the ROM's LD-BYTES ($0556) for a block of flag
; $FF twice: 6912 bytes to the screen, then 40000 bytes to $6338. A standard header (flag $00) before each fails the
; flag test, LD-BYTES returns with carry clear, and the loader asks again: so the two headers on the tape (blocks 4
; and 6) are read and dropped. It never returns: the game takes over at $D6B0 (c1, frame 14 100 T 17 980). The game's
; 40000 bytes end at $FF77, below this code, so the load does not overwrite the loader while it runs.
; --------------------------------------------------------------------------------------------------------------------

; Drop USR's return, load the screen and the game, enter the game
;
; USR leaves the address of the ROM's statement return on the stack; POP AF
; drops it, the game never returns to BASIC.
;
; Witness: L1 1 (c1).
Loader:
  POP AF
LoadScreen:
  LD IX,Screen             ; IX = $4000, DE = 6912, A = $FF (a data block),
                          ; carry set (load): LD-BYTES
  LD DE,$1B00
  LD A,$FF
  SCF
  CALL LdBytes
  JR NC,LoadScreen
LoadGame:
  LD IX,GameStart             ; IX = $6338, DE = 40000: LD-BYTES again, again until
                          ; it succeeds
  LD DE,$9C40
  LD A,$FF
  SCF
  CALL LdBytes
  JR NC,LoadGame
EnterGame:
  JP EntryJumps                ; JP $D6B0: the game's entry (EntryJumps)
