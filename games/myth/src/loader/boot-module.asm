; --------------------------------------------------------------------------------------------------------------------
; boot-module.asm: Boot: the resident into place, then its entry
;
; Tape blocks 33 and 35 (the second table's row 9: 33 bytes, then 14 more with the check, read by the end-row path of
; StoreLast) load these 47 bytes at $5B00. Unxor jumps here.
; --------------------------------------------------------------------------------------------------------------------

; Set the 48K state, move the resident to $E000-$FFFF, wipe this piece, JP
; ResidentEntry
;
; HL' = $2758 (the ROM's value for the calculator), SP = BootStack, IY = $5C3A
; (the system variables), $7FFD := $10 (ROM 1, bank 0), RES 4,(FLAGS) (48K
; BASIC mode). LDDR copies $CB80-$EB7F to $E000-$FFFF (8192 bytes: the resident
; and its pieces at their own addresses). Then zeros over $5B00-$5B2A (this
; piece) and JP (HL) to ResidentEntry. Side effects: the loader at $FC00-$FFFF
; overwritten by the resident.
;
; Witness: L1 1 (c1).
Boot:
  LD HL,$2758
  EXX
  LD SP,BootStack
  LD IY,SysVars
  LD BC,$7FFD
  LD A,$10
  OUT (C),A
  RES 4,(IY+$01)
  LD HL,ResidentCipher+4095
  LD DE,$FFFF
  LD BC,$2000
BootCopy:
  LDDR                    ; LDDR: c1 8192 passes
  LD HL,ResidentEntry
  LD DE,Boot
  XOR A
  LD B,$2B
BootWipe:
  LD (DE),A               ; the self-wipe: c1 43 passes
  INC E
  DJNZ BootWipe
  JP (HL)                 ; JP (HL): HL = ResidentEntry
