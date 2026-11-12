; ZYX boot variants: the Sound Tracker 1 compilation's head (zyxtvmbt; tools/variants_music.py kind stc1).
; Written by kit/mkgame.py from variants/players/stc1-head/stc1-head.ann; edit stc1-head.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
Init           EQU $C062  ; the Sound Tracker player's Init (variants/players/stc), assembled at $C059
Play           EQU $C19D  ; the player's Play
StopEnd        EQU $C495  ; the rest of Stop (variants/players/stc1-tail)
Module         EQU $C4A8  ; the STC module after the player
  ORG $C000
  INCLUDE "stc1head.asm"  ; The Sound Tracker 1 compilation's head: entries, title, stop

  SAVEBIN "stc1-head.bin",$C000,$0059
