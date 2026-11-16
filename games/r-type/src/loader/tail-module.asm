; --------------------------------------------------------------------------------------------------------------------
; tail-module.asm: The tail (TZX blocks 33 and 35)
;
; Run by Decipher: it puts the BASIC registers back, moves the game's top part into place and enters the game.
; --------------------------------------------------------------------------------------------------------------------

; HL' = $2758, SP = $6FFE, IY = $5C3A; LDDR $C53C-$E7CD to $DD10-$FFA1; OUT
; ($7FFD),$30 (128K paging locked, the 48K ROM); JP GameEntry
;
; Witness: L1 1 (c1).
Tail:
  LD HL,$2758
  EXX
  LD SP,$6FFE
  LD IY,$5C3A
  DI
  LD HL,$E7CD
  LD DE,$FFA1
  LD BC,$2292
  LDDR
  LD A,$30
  LD BC,$7FFD
  OUT (C),A
  JP GameEntry

; Bytes after the tail: a copy of the first 14 bytes of this tape's Stage2Start
; $FEE8 (XOR A / LD ($82FF),A / LD IX,$4000 / LD DE,$17FF / LD
; HL,SL7StoreHook), never run
TailLeftover:
  DEFB $AF,$32,$FF,$82,$DD,$21,$00,$40
  DEFB $11,$FF,$17,$21,$B3,$FD
