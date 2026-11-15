; --------------------------------------------------------------------------------------------------------------------
; stage2-module.asm: The second stage
;
; Loaded to $FEE8 by SL7Main. It loads the loading screen (6143 bytes to $4000 through the deciphering store hook),
; wipes memory when a check failed, sets IM 2 and jumps to the countdown loader at $7530 (loaded with the screen's
; blocks).
; --------------------------------------------------------------------------------------------------------------------

; Load the screen with the store hook, check the flag, IM 2, SP = $752F, JP
; $7530
;
; Witness: L1 1 (c1).
Stage2Start:
  XOR A
  LD ($82FF),A
  LD IX,$4000
  LD DE,$17FF
  LD HL,SL7StoreHook
  LD (SL7StorePtr),HL
  CALL SL7LoadBlock
  LD A,(SL7Pattern)
  OR A
  CALL NZ,SL7WipeTrap
  LD IY,$5C3A
  IM 2
  LD HL,$2758
  EXX
  EI
  XOR A
  LD R,A
  LD SP,$752F
  JP $7530

; Zeros, the first block table at $FF4A (5-byte records: address, length, the
; $7FFD bank) and the countdown digits 0-9 (8 bytes each from $FF60)
Stage2Data:
  INCBIN "res/loader/stage2-data.bin",$0000,185
