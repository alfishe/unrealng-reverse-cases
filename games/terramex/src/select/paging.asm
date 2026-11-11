; --------------------------------------------------------------------------------------------------------------------
; paging.asm: The paging stub
;
; The selector runs in RAM 1 at $C000, so it cannot page RAM 3 or 4 there itself: SelectorEntry $C0D2 copies
; PagedReadStub $C4A6 to PagingStub $5FE6, below $6000, and CopyExplorerSet $C134 calls it once a byte. Every OUT is
; preceded by a store to Last7FFD $5FE5, the value the game's IM 2 handler $9491 puts back after the music.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C4A6

; Read the byte at HL in RAM A, then page RAM 1 back (run as a copy at $5FE6)
;
; In: A = the RAM (3 or 4), HL = the address ($C000-$FFFF). Out: A = the byte;
; RAM 1 paged at $C000 again; BC = $7FFD. Port $7FFD gets A OR $10 (ROM 1, the
; 48 BASIC ROM), then $11. Never run here: SelectorEntry copies these 21 bytes
; to $5FE6 on every entry, and CopyExplorerSet $C134 calls $5FE6. On a 128K's
; first entry $5FE6-$5FE8 are patched to OUT (C),A; RET before the jump there.
;
; c1: $5FE6 runs 4609 times (4608 calls from $C165, one jump from $C0F9).
;
; Witness: L1 0 ().
PagedReadStub:
  LD BC,$7FFD
  OR $10
  LD (Last7FFD),A
  OUT (C),A
  LD A,(HL)
  EX AF,AF'
  LD A,$11
  LD (Last7FFD),A
  OUT (C),A
  EX AF,AF'
  RET
