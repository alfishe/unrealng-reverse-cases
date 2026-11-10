; --------------------------------------------------------------------------------------------------------------------
; stub.asm: The stub at $5B00: it loads the game block and jumps in; a save routine for the same block follows
;
; The CODE block's last 32 bytes land in the printer buffer, $5B00-$5B1F. BASIC line 10 calls $5B00 (RANDOMIZE USR
; 23296).
; --------------------------------------------------------------------------------------------------------------------

; Load tape block 5 (40 256 bytes) to $60C0 with the ROM's LD-BYTES and enter
; the game
;
; Entered once by BASIC line 10's USR 23296 (c1 frame 2908, T 8352). Carry set
; (LOAD, not VERIFY), A = $FF (a data block's flag), IX = GameBlock $60C0, DE =
; GameLength 40 256, then LD-BYTES. The carry LD-BYTES returns is not tested: a
; tape error runs into the game anyway. JP GameEntry $6300 (c1 frame 13580)
; never returns.
StubLoad:
  SCF
  LD A,$FF
  LD IX,GameBlock
  LD DE,GameLength
  CALL LD_BYTES
  JP GameEntry

; Save the same block with the ROM's SA-BYTES (not executed in any recording)
;
; A = $FF, IX = GameBlock $60C0, DE = GameLength, CALL SA_BYTES, RET: it writes
; the game block back to tape as a headerless data block. Nothing jumps here
; (StubLoad ends in JP GameEntry), and no recording runs it (c1 L1: no
; instruction executed in $5B10-$5B1F): the authors' mastering tool left in the
; block. Known only from the code.
StubSave:
  LD A,$FF
  LD IX,GameBlock
  LD DE,GameLength
  CALL SA_BYTES
  RET

; Three zero bytes to the block's end, $5B1F (no code reads them)
StubPadding:
  DEFB $00,$00,$00
