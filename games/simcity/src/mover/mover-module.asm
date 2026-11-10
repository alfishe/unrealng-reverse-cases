; --------------------------------------------------------------------------------------------------------------------
; mover-module.asm: The mover: code2 from the screen to $5B00, then the game's entry
;
; LoadGame in src/loader jumps here once block 7 is in. c1: entered at frame 16 279, T 8372; the game's entry $5B1B at
; frame 16 280, T 51 501 (docs/03-build-and-load.md 3.4, 3.5).
; --------------------------------------------------------------------------------------------------------------------

; Copy $4000-$4FFF to $5B00-$6AFF and jump to the game's entry $5B1B
;
; Input: block 7 at $4000-$501F, the attributes black (LoadGame cleared them,
; so code2 in the pixel area is never seen). Output: code2 at its run address
; GameStart $5B00; the screen keeps code2's bytes until the game draws over
; them. c1: L1 1, the LDIR 4096 times.
MoveCode2:
  DI
  LD HL,Screen
  LD DE,GameStart
  LD BC,$1000
  LDIR
  JP GameEntry

; 17 zero bytes, the rest of the 32 the block carries; no code reads them
;
; c1: no L1 read. Kept as bytes.
MoverPadding:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
