; Myth: History in the Making, System 3 Software 1989: the SpeedLock loader's second stage, tape block 7, run at $FF26.
; Written by kit/mkgame.py from src/loader/sl1.ann and the recordings; edit sl1.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
Screen         EQU $4000  ; the bitmap, the first block of the stream loads straight into it
AttrRevealOff  EQU $82FF  ; zero: AttrRevealStart pads its time and leaves the attributes alone
AttrRevealStart EQU $FC0D  ; the edge loop's task: the attribute reveal, then the countdown (src/loader/chain.asm)
LoadStream     EQU $FD2C  ; the block reader (src/loader/chain.asm)
LastStoreJump  EQU $FDE7  ; the operand of LoadStream's JP after a block's bytes: where the last byte goes
StoreLast      EQU $FDE9  ; the last-byte store and the table walk (src/loader/chain.asm)
FailFlag       EQU $FEE9  ; non-zero when the timing check or a mark failed (src/loader/chain.asm)
  ORG $FF26
  INCLUDE "sl1-module.asm"  ; The second stage: the screen, the block table, the countdown digits

  SAVEBIN "sl1.bin",$FF26,$00AA
