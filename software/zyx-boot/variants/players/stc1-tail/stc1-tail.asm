; ZYX boot variants: the Sound Tracker 1 compilation's tail (zyxtvmbt; tools/variants_music.py kind stc1).
; Written by kit/mkgame.py from variants/players/stc1-tail/stc1-tail.ann; edit stc1-tail.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $C495
  INCLUDE "stc1tail.asm"  ; The stop routine's end

  SAVEBIN "stc1-tail.bin",$C495,$0013
