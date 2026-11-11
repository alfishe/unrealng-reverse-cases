; --------------------------------------------------------------------------------------------------------------------
; final.asm: The loader's end: un-XOR the bank-5 block, jump to the bootstrap
;
; Block 37 lands over TimeCheck at $BE5D, block 39 over the end of the stage at $BF21, so the stage runs into TimeEnd
; when the table is done.
; --------------------------------------------------------------------------------------------------------------------

; XOR the 9472 bytes of $5B00-$7FFF with $AD, then JP Bootstrap
;
; The tape's block 23 holds the game's $5B00-$7FFF XORed with $AD on top of the
; loader's cipher: this loop takes it off. c1: the bank-5 bytes change in
; frames 23962-23969 (memory_at every quarter frame), the game is entered at
; frame 23974.
Unxor5B00:
  LD HL,Bank5Code
  LD BC,$2500
l_BE63:
  LD A,(HL)
  XOR $AD
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_BE63
  JP Bootstrap

; Bytes no code runs: a test of TimeFailed, a wipe and a copy of the bootstrap
;
; Never executed in c1. They look like an earlier version of TimeEnd and of the
; bootstrap at $8000 (the same LDIR of $3CFF bytes from bank 1 and JP $68F4);
; kept as bytes of the block.
FinalLeftover:
  DEFB $3A,$D0,$BE,$B7,$CA,$5D,$BE,$21
  DEFB $EE,$C3,$2B,$36,$00,$18,$FB,$21
  DEFB $58,$27,$D9,$31,$00,$82,$FD,$21
  DEFB $3A,$5C,$FD,$CB,$01,$A6,$21,$FF
  DEFB $AF,$11,$FF,$BF,$01,$10,$40,$21
  DEFB $00,$5B,$11,$01,$5B,$01,$FE,$0F
  DEFB $01,$FD,$7F,$3E,$11,$ED,$79,$21
  DEFB $01,$C3,$11,$01,$83,$01,$FF,$3C
  DEFB $ED,$B0,$01,$FD,$7F,$3E,$10,$ED
  DEFB $79,$21,$F4,$68,$11,$00,$80,$AF
  DEFB $06,$44,$E9,$AF,$32,$FF,$82,$DD
  DEFB $21,$00,$40,$11,$FF,$17,$21,$D0
