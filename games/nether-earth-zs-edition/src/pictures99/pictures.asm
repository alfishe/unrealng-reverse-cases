; Nether Earth ZS Edition'99: the pictures block, $7D87-$8A86: NEZSEd99.B sectors 19-31, not packed, read by
; stage 2 to $7D87: the RLE screen decoder and the packed pictures.
; Written by kit/mkgame.py from src/pictures99/pictures.ann and the recordings; edit pictures.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
RomRet         EQU $1792  ; a RET in the 48 BASIC ROM (the end of a ROM routine): called only to leave the return address below SP
Screen         EQU $4000  ; the screen's pixels: DecodeScreen's own target
Attrs          EQU $5800  ; the screen's attributes: DecodeScreen's own target

; the pictures block: $7D87-$8A86
  ORG $7D87
  INCLUDE "pictures/decoder.asm"  ; the RLE screen decoder
  INCLUDE "pictures/picture.asm"  ; the packed intro screen

  SAVEBIN "pictures-7d87.bin",$7D87,3328
