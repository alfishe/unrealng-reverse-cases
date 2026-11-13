; --------------------------------------------------------------------------------------------------------------------
; unxor-module.asm: Unxor: take the $DF XOR off the resident and jump to Boot
;
; Tape block 29 (row 7 of the second block table) lands over TimeCheck at $FE76 once the timing check is done; Sl1End
; jumps here when the load went well.
; --------------------------------------------------------------------------------------------------------------------

; XOR the 4096 bytes of $DB80-$EB7F with $DF, then JP Boot
;
; The resident's three pieces ($DB80, $DE80, $E300) come off the tape XORed
; with $DF on top of the loader's own key; this loop takes it off in place.
; Inputs: none. Side effects: $DB80-$EB7F plain. Then JP Boot.
;
; Witness: L1 1 (c1).
Unxor:
  LD HL,ResidentCipher
  LD BC,$1000
UnxorLoop:
  LD A,(HL)               ; one byte: c1 4096 passes
  XOR $DF
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,UnxorLoop
  JP Boot                ; JP Boot (src/loader/boot.asm)

; Bytes of block 29 no code runs: copies of Sl1End, Boot and the start of
; Sl1Start
;
; Not executed in any recording (c1 checked): Unxor jumps away at $FE86.
; $FE89-$FE97 are Sl1End's 15 bytes, $FE98-$FEC6 Boot's 47 bytes, $FEC7-$FEE8
; the first 34 bytes of Sl1Start, as the mastering tool left them in the block.
; Known only from the code ($FE89-$FEE8 against src/loader/sl1end.asm,
; boot.asm, sl1.asm).
UnxorLeftover:
  DEFB $3A,$E9,$FE,$B7,$CA,$76,$FE,$21
  DEFB $3D,$03,$2B,$36,$00,$18,$FB
  DEFB $21,$58,$27,$D9,$31,$87,$5E,$FD ; a copy of Boot
  DEFB $21,$3A,$5C,$01,$FD,$7F,$3E,$10
  DEFB $ED,$79,$FD,$CB,$01,$A6,$21,$7F
  DEFB $EB,$11,$FF,$FF,$01,$00,$20,$ED
  DEFB $B8,$21,$40,$F0,$11,$00,$5B,$AF
  DEFB $06,$2B,$12,$1C,$10,$FC,$E9
  DEFB $AF,$32,$FF,$82,$DD,$21,$00,$40 ; a copy of Sl1Start's first 34 bytes
  DEFB $11,$FF,$17,$21,$E9,$FD,$22,$E7
  DEFB $FD,$CD,$2C,$FD,$3A,$E9,$FE,$B7
  DEFB $C4,$0D,$FC,$21,$00,$40,$36,$00
  DEFB $23,$18
