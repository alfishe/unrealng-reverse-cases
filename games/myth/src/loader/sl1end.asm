; Myth: History in the Making, System 3 Software 1989: the SpeedLock loader's piece at $FF3A, tape block 31.
; Written by kit/mkgame.py from src/loader/pieces.ann and the recordings; edit pieces.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
RomWipeTop     EQU $033D  ; a ROM address taken as the top of the failure wipe
SysVars        EQU $5C3A  ; IY's value for the ROM: ERR_NR, the system variables' base
BootStack      EQU $5E87  ; the stack Boot sets
ResidentCipher EQU $DB80  ; the resident's pieces as loaded: $DB80-$EB7F, XORed with $DF
ResidentEntry  EQU $F040  ; the resident's entry (src/resident/resident.asm)
FailFlag       EQU $FEE9  ; non-zero when the timing check or a mark failed (src/loader/chain.asm)
  ORG $FF3A
  INCLUDE "sl1end-module.asm"  ; Sl1End: the stage's new end at $FF3A

  SAVEBIN "sl1end.bin",$FF3A,$000F
