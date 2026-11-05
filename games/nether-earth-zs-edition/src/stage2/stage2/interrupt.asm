; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: the IM 2 handler: the tune each frame
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 handler: the tune's frame (MusicPlay), then the ROM's IM 1 handler
;
; Saves every register (main and alternate, IX, IY), calls MusicPlay, restores
; them and jumps to the ROM's $0038 (which scans the keyboard, counts FRAMES
; and returns with EI). Entered through $B1B1 1845 times (r99 frames 261-2114).
IM2Handler:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EXX
  PUSH BC
  PUSH DE
  PUSH HL
  EX AF,AF'
  PUSH AF
  CALL MusicPlay
  POP AF
  EX AF,AF'
  POP HL
  POP DE
  POP BC
  EXX
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  JP RomIM1
