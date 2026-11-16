; --------------------------------------------------------------------------------------------------------------------
; tail-module.asm: The loader's new end: start the game through Mover
;
; Block 12 (row 6 of BlockTable) writes $FF63-$FF79: the same start as LoaderStart's original tail but JP $A000. Block
; 14 (row 8) writes $FF7A-$FF86: the end that runs after the check byte, which jumps to Mover at $5B00 (block 15) when
; the XOR of the stream is 0.
; --------------------------------------------------------------------------------------------------------------------

; LoadFailed set: Crash; else IY = $5C3A, IM 1, HL' = $2758, R = 0, JP $A000
;
; Reached when LoadBlock returns after the last block (the return address
; LoadBlock left). The JP $A000 enters the decoy area block 5 filled; in c1 the
; game never got here: LoadEnd's JP $5B00 comes first (c1 frame 11632).
TailStart:
  LD A,($FF36)
  OR A
  CALL NZ,$FD20
  LD IY,$5C3A
  IM 1
  LD HL,$2758
  EXX
  XOR A
  LD R,A
  JP $A000

; Border black; H (the XOR of the stream) 0: JP Mover ($5B00), else JP $0000
;
; POP DE drops the return into ByteLoop; XOR A / OUT ($FE) black border; LD A,H
; / CP 1 / JP C,$5B00 when H = 0, JP $0000 (a reset) otherwise.
;
; Witness: L1 2 (c1).
TailEnd:
  POP DE
  XOR A
  OUT ($FE),A
  LD A,H
  CP $01
  JP C,$5B00
  JP $0000
