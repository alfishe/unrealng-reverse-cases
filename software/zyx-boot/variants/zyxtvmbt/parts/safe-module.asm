; --------------------------------------------------------------------------------------------------------------------
; safe-module.asm: Read the catalogue with an error trap, then stop the drive
;
; The original Start and SPACE call TrdosEntry directly: a disk error drops to TR-DOS's error message. This routine
; first points ERR_SP at a return to itself, so an error comes back here, then reads the 8 sectors of track 0 to
; Catalogue $9D00, then writes the drive's system byte twice through the TR-DOS ROM (with bits 0-1 set, then as it
; was) to stop the motor and the head.
; --------------------------------------------------------------------------------------------------------------------

; Trap errors through ERR_SP, read the catalogue (8 sectors of track 0) to
; Catalogue $9D00, stop the drive
ReadCatalogueSafe:
  LD HL,ReadCatalogueSafe
  PUSH HL
  LD (ErrSP),SP
  LD A,$FF
  LD (ErrNr),A
  LD HL,Catalogue
  LD DE,$0000
  LD (TrdosErrorFlags),DE
  LD BC,$0805
  CALL TrdosEntry
  POP HL                  ; back here also after an error: drop the trap
  DI
  CALL DriveIdle
  RET

; Write the drive's system byte with bits 0-1 set, then as it was, through the
; ROM's $02B9
;
; Used by the routine at ReadCatalogueSafe.
DriveIdle:
  LD A,(TrdosSystemByte)
  PUSH AF
  OR $03
  CALL RomSystem
  POP AF

; Run the ROM's $02B9 with A, through TrdosRet
;
; Used by the routine at DriveIdle.
RomSystem:
  LD HL,TrdosMotorOff
  PUSH HL
  JP TrdosRet

; "READ": leftover text, not read
ReadText:
  DEFM "READ"
