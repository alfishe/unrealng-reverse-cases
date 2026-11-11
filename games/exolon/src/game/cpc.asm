; --------------------------------------------------------------------------------------------------------------------
; cpc.asm: The Amstrad CPC keyboard scan, never run on the Spectrum, and the sound effects' empty channel
; --------------------------------------------------------------------------------------------------------------------

; The Amstrad CPC keyboard scan, never run on the Spectrum
;
; The CPC's standard matrix read through its PPI (ports $F4xx / $F6xx / $F7xx)
; and the AY's register 14: DI, select PSG register 14, the PPI port A to input
; ($92), then rows 0-9 (bits 0-3 of port C, $40 the PSG read) each read from
; port A into CpcKeyMatrix $C7AB-$C7B4; the PPI back to output ($82); row 9's
; bits 5-6 forced to 1; EI. On a Spectrum these ports are nothing the game
; uses, and no code of the image calls it: 0 of its 62 bytes ran in any
; recording. Left from the Amstrad CPC version (the AY sound engine around it
; is shared by both).
CpcReadKeyboard:
  DI
  LD HL,CpcKeyMatrix-1
  LD BC,$F40E
  OUT (C),C
  LD B,$F6
  IN A,(C)
  AND $30
  LD C,A
  OR $C0
  OUT (C),A
  OUT (C),C
  INC B
  LD A,$92
  OUT (C),A
  PUSH BC
  SET 6,C
CpcReadKeyboardRow:
  LD B,$F6                ; one row: the line select, port A read into the next
                          ; byte
  OUT (C),C
  LD B,$F4
  IN A,(C)
  INC HL
  LD (HL),A
  INC C
  LD A,C
  AND $0F
  CP $0A
  JR NZ,CpcReadKeyboardRow
  POP BC
  LD A,$82
  OUT (C),A
  DEC B
  OUT (C),C
  LD A,(HL)
  OR $60
  LD (HL),A
  EI
  RET

; A RET: SfxChannelWriters' entry for the fourth and later active slots
;
; 9023 indirect entries from $C076 in the runs.
SfxNoChannel:
  RET
