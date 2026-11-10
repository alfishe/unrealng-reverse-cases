; SimCity, Infogrames 1990: tape block 5, the loading screen (6912 bytes at $4000), as LoadBlock stores it;
; tools/tape.py encrypts it for the tape. The picture is src/res/screen/LoadingScreen.png.
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $4000
  INCLUDE "screen-module.asm"  ; The loading screen: the Probe / Infogrames title picture by Simon Butler

  SAVEBIN "screen.bin",$4000,$1B00
