; --------------------------------------------------------------------------------------------------------------------
; timeend.asm: The stage's new end at $BF21
;
; Tape block 39 lands here, over the stage's own end; the stage runs into it when the table is done.
; --------------------------------------------------------------------------------------------------------------------

; The stage's end: if TimeFailed, wipe the memory below $C3EE; else Unxor5B00
;
; c1: L1 1, TimeFailed zero, so JP Unxor5B00.
TimeEnd:
  LD A,(TimeFailed)
  OR A
  JP Z,$BE5D
  LD HL,$C3EE
TimeWipe:
  DEC HL                  ; DEC HL / LD (HL),0 for ever
  LD (HL),$00
  JR TimeWipe
