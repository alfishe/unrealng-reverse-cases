; --------------------------------------------------------------------------------------------------------------------
; errsptext.asm: ERR_SP's new value
;
; Loader $5EF3 loads this block with LD-BYTES (IX $5C3D, DE 2, flag $FF; c1 between frames 246 and 361).
; --------------------------------------------------------------------------------------------------------------------

; ERR_SP = 1: the ROM's error stack pointer
;
; Tape block 3, `01 00`. Nothing in the game writes ERR_SP again: it is a
; loading check. Every pass of MainLoop $9858 reads the word and, unless it is
; 1, hangs in a JR to itself at $985E, so a copy of the game block without this
; block (ERR_SP left at the ROM's value) freezes on its first game pass. The
; ROM never uses ERR_SP after the loader (the game never returns to BASIC and
; never makes an error). Witness: c1 L1, 14 873 212 reads of $5C3D over the
; eight builds (tools/l1count.py --reads 5C3D-5C3E), all by $9858.
ErrSpValue:
  DEFW $0001
