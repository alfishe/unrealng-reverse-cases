; --------------------------------------------------------------------------------------------------------------------
; sl1end-module.asm: Sl1End: the stage's new end at $FF3A
;
; Tape block 31 (row 8 of the second block table) lands here, over the end of the second stage, so LoadStream returns
; into it when the table is done.
; --------------------------------------------------------------------------------------------------------------------

; If the load failed, wipe memory down from the ROM; else Unxor
;
; FailFlag zero: JP Z,$FE76 (Unxor, src/loader/unxor.asm). Else HL = RomWipeTop
; and the loop at $FF44 clears memory downwards for ever: through the ROM (the
; writes do nothing), then from $FFFF down over the RAM, the loop's own bytes
; included: a crash with no message. Known only from the code ($FF41-$FF48).
;
; c1: LoadStream returned here once and Unxor ran (the L1 at $FE76, this JP its
; only way in). The L1 count at $FF3A itself (393 761) is the resident's turbo
; loader, which runs at the same address later in c1.
Sl1End:
  LD A,(FailFlag)
  OR A
  JP Z,$FE76              ; JP Z,$FE76: Unxor
  LD HL,RomWipeTop
Sl1EndWipe:
  DEC HL                  ; DEC HL / LD (HL),0 for ever: not executed in any
                          ; recording (c1 checked)
  LD (HL),$00
  JR Sl1EndWipe
