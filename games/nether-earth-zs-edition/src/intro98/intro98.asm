; Nether Earth ZS Edition '98 (ZS, 23.12.1998): the intro block, $C000-$E9FF, as the REM loader reads it
; (NEZSEd.B sectors 2-43). PT 3 Player v1.0 by Nick of GDC + "COOL WINTER" (KLIM/OHG '97) at $C000-$D88E,
; the intro (entered at $D88F by CALL from the REM loader) and its data at $D88F-$E9FF.
; Written by tools/intro98_mkgame.py (kit/mkgame.py) from src/intro98/intro.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $C000
  INCLUDE "pt3player.asm"  ; PT 3 Player v1.0 by Nick of GDC: the compiled tune's player
  INCLUDE "pt3tune.asm"  ; "COOL WINTER" by KLIM / OHG '97: the Pro Tracker 3.3 module
  INCLUDE "intromain.asm"  ; the intro: logo, robot, AY bars and the scroller over the tune
  INCLUDE "introtext.asm"  ; the scroller's text
  INCLUDE "intrologo.asm"  ; the ZS logo's cells and the robot box's header
  INCLUDE "robot.asm"  ; the robot animation: its depacker and its four frames
  INCLUDE "introfont.asm"  ; the scroller's font and the bytes after it

  SAVEBIN "intro-c000.bin",$C000,$2A00
