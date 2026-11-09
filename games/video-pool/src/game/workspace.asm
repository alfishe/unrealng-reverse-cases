; --------------------------------------------------------------------------------------------------------------------
; workspace.asm: The free space and the machine stack below the sprites
;
; $C600-$CFFF: 2496 zero bytes no recording reads or writes, then the 64 bytes the machine stack runs in (LD
; SP,StackTop at GameStart $8000 and BreakRestart $80B0, StackTop = $D000).
; --------------------------------------------------------------------------------------------------------------------

; Zeros up to the stack: never read or written in any recording
;
; 2496 bytes of zeros. tools/l1sum.py --reads C600-CFBF: no read in game, w1,
; f1, p2, v1, m1, j1. The loader's sum covers them (they are on the tape),
; nothing else touches them.
FreeSpace:
  DEFS $09C0

; The machine stack, 64 bytes below $D000
;
; The stack pointer is set to StackTop ($D000) by GameStart and BreakRestart.
; The loaded bytes here are zeros; no recording reads a byte before writing it
; (l1sum.py --reads CFC0-CFFF: none), the lowest byte w1 uses is $CFC4.
StackSpace:
  DEFS $40
