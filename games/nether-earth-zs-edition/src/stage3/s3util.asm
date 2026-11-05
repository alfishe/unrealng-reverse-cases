; --------------------------------------------------------------------------------------------------------------------
; s3util.asm: TR-DOS and tape loading, the string helpers
;
; The loaders and the print helpers of stage 3. Strings end with $FF (PrintFF counts them for the ROM's PR-STRING, so
; they may hold the ROM's controls: $16 AT, $10 INK, $11 PAPER, $12 FLASH, $13 BRIGHT, $0D new line). The TR-DOS calls
; go through the ROM's entry $3D13 and through TrdosRet ($3D2F, NOP RET in TR-DOS 5.03 and 5.04T): a routine PUSHes an
; address inside the TR-DOS ROM and jumps to $3D2F, which pages that ROM in and RETs to the address, so the TR-DOS
; ROM's own LDIR ($180D) or OUT (C),A ($2A53) runs with that ROM paged and returns to the caller.
; --------------------------------------------------------------------------------------------------------------------

; Copy the TR-DOS ROM's version text ($0365, 16 bytes) to TrdosVersion
;
; Through TrdosRet into TrdosLdir. Out: DE = TrdosVersion + 16, where
; Stage3Entry puts the $FF. Run in r99, r99-48 and s99 ("Using TR-DOS Ver
; 5.03", r99 frame 2300).
ReadTrdosVersion:
  LD HL,TrdosVersionRom
  LD DE,TrdosVersion
  LD BC,$0010
  LD IX,TrdosLdir
  PUSH IX
  JP TrdosRet

; Read B sectors from TrdosNextSector to HL, then print "O.k."
;
; TR-DOS command 5 (TrdosCommand) from the disk position after the last file
; read; the position moves on. Then LoadOk.
ReadSectors:
  LD C,$05
  LD DE,(TrdosNextSector)
  CALL TrdosCommand

; Interrupts off again (TR-DOS turns them on) and print "O.k." (OkText)
LoadOk:
  DI
  LD DE,OkText
  JP PrintFF

; Load a tape block: A = the flag, IX = the address, DE = the length; retry, or
; halt on an error
;
; LD-BYTES' own set-up (carry = load, the flag into A'), border 1, then
; RomLdBytesIn; NZ: again; NC: "Tape Error. System Halted." and DI, HALT. Known
; only from the code (the tape path).
LoadBlock:
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  LD A,$0F
  OUT ($FE),A
  CALL RomLdBytesIn
  JR NZ,LoadBlock
  JR NC,TapeHalt
  RET
TapeHalt:
  LD DE,TapeErrorText     ; the error: the message, then the machine stops
  CALL PrintFF
  DI
  HALT

; DE past B strings that end in $FF
;
; Used by the routine at FadeWait.
SkipStrings:
  LD A,(DE)
  INC DE
  CP $FF
  JR NZ,SkipStrings
  DJNZ SkipStrings
  RET

; B = the position of A's highest set bit, from the top (bit 7 gives 1)
;
; A must not be 0. A is shifted.
FirstSetBit:
  LD B,$00
FirstSetBitLoop:
  INC B
  RLA
  JR NC,FirstSetBitLoop
  RET

; Print the string at DE up to its $FF (not printed) through the ROM's
; PR-STRING
;
; BC = the length, DE the start, into RomPrString (which RETs to the caller).
PrintFF:
  PUSH DE
  LD BC,$FFFF
PrintFFCount:
  LD A,(DE)               ; BC counts the bytes before the $FF
  INC DE
  INC BC
  CP $FF
  JR NZ,PrintFFCount
  POP DE
  JP RomPrString
