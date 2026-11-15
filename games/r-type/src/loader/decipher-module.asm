; --------------------------------------------------------------------------------------------------------------------
; decipher-module.asm: Decipher (TZX block 29)
;
; The last piece the countdown loader runs: it undoes the XOR over the whole game and hands over to the tail.
; --------------------------------------------------------------------------------------------------------------------

; XOR $92 over $7000-$C4AD (21678 bytes), then JP Tail
;
; Witness: L1 1 (c1).
Decipher:
  LD HL,$7000
  LD BC,$54AE
l_FE46:
  LD A,(HL)
  XOR $92
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_FE46
  JP $61A8

; The rest of the block: an older copy of the second stage's code (the store
; hook setup, the stack and IM settings), never run
DecipherLeftover:
  DEFB $3A,$B3,$FE,$B7,$C4,$CB,$FB,$FD
  DEFB $21,$3A,$5C,$ED,$56,$21,$58,$27
  DEFB $D9,$3E,$00,$D3,$FE,$3E,$00,$ED
  DEFB $4F,$3E,$3F,$ED,$47,$31,$FD,$6F
  DEFB $F3,$21,$00,$00,$11,$00,$00,$01
  DEFB $01,$00,$36,$00,$ED,$B0,$C3,$40
  DEFB $FE,$21,$58,$27,$D9,$31,$FE,$6F
  DEFB $FD,$21,$3A,$5C,$F3,$21,$CD,$E7
  DEFB $11,$A1,$FF,$01,$92,$22,$ED,$B8
  DEFB $3E,$30,$01,$FD,$7F,$ED,$79,$C3
  DEFB $FD,$85,$AF,$32,$FF,$82,$DD,$21
  DEFB $00,$40,$11,$FF,$17,$21,$B3,$FD
