; --------------------------------------------------------------------------------------------------------------------
; im2.asm: the interrupt: the tune's frame
;
; Dead End plays its tune from an interrupt of its own: interrupt mode 2 with I = Im2Table's page; the table is filled
; with $FD at run time (DeadEnd), so whatever byte the bus holds, the vector is $FDFD: Im2Handler. The bytes before
; the table and between it and the handler are free space, zero in the image.
; --------------------------------------------------------------------------------------------------------------------

; free space, zero
DeadEndSpare1:
  DEFS $0A12

; the vector table: 257 bytes of $FD (DeadEnd fills it), zero in the image
Im2Table:
  DEFS $0101

; free space, zero
DeadEndSpare2:
  DEFS $FC

; the interrupt: one frame of the tune
;
; Saves every register (both sets, IX, IY), calls the player's frame
; (nst.Play), restores them.
Im2Handler:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EXX
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL nst.Play
  POP HL
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  EXX
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RET
