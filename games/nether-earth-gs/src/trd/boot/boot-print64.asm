; Nether Earth GS, TRD file boot: the boot menu's print64 part
; Written by kit/mkgame.py from src/trd/boot/print64.ann and the recordings; edit print64.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
OLD_CODE_815F      EQU $815F  ; the scrolls' CALL target in the package's older layout: here inside PrintInit's LD ($8461),A
OLD_CODE_88C4      EQU $88C4  ; a CALL target of the leftover code: inside the font here, a routine of the package's older layout

; The variables past the loaded image (game.ann @equ)
BEEPER         EQU $03B5  ; the 48 ROM's BEEPER (HL = the pitch, DE = the duration)
CHAN_OPEN      EQU $1601  ; the 48 ROM's CHAN-OPEN: A = the stream
Screen         EQU $4000  ; the screen's bitmap
ScreenRow23    EQU $50E0  ; the bitmap's character row 23 (its first pixel line)
Attrs          EQU $5800  ; the attribute file
ERR_SP         EQU $5C3D  ; the BASIC error stack pointer
ATTR_P         EQU $5C8D  ; the permanent attribute
ChannelSOutput EQU $5D2B  ; the output address of channel S in CHANS (TR-DOS moves CHANS to $5D25): PrintInit points it at ChannelOut
InputPosition  EQU $8DD8  ; InputLine's start column and row (past the copied bytes: the package's variables)
  ORG $8156
  INCLUDE "print64.asm"  ; the 64-column printer (relocated to $8156)

  SAVEBIN "build/trd/obj/boot-print64.bin",$8156,$08E0
