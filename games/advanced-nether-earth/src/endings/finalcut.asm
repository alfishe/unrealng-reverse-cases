; Advanced Nether Earth (Eternity Industry, 1998): Final Cut, the win sequence, as HRUM unpacks it
; ($6060-$F76C; GameWon copies the packed block from bank 6 to $6060 and jumps there).
; Written by kit/mkgame.py from the annotations (src/endings/finalcut-main.ann, src/endings/finalcut-bank7.ann, src/endings/finalcut-screens.ann) and the recordings; edit the annotations,
; not the .asm.

  DEVICE ZXSPECTRUM48

; the sequence's code, texts and font (bank 5): $6060-$70F4
  ORG $6060
  INCLUDE "finalcut/fcmain.asm"  ; Final Cut: the sequence, its scroll text and font

; the block copied to bank 7, its first part: the green alien screen: $70F5-$8BF4, run at $C000
  ORG $70F5
Bank7Block:
  DISP $C000
  INCLUDE "finalcut/fcbank7.asm"  ; the shadow screen (bank 7)
  ENT

  ORG $8BF5
; $8BF5-$A66C, run at $DB00 in bank 7: the PT3 player and X-Man's REM, aneS's sources (src/music/pt3-player.asm,
; Pt3Init $DB00, Pt3PlayEntry $DB05; the tune src/res/music/rem.pt3 as it is: the player relocates it at its init)
  DISP $DB00
  MODULE pt3
  INCLUDE "src/music/pt3-player.asm"
  ENDMODULE
  INCBIN "src/res/music/rem.pt3"
  ENT
  ASSERT $ == $A66D

; the screens: $A66D-$F76C
  ORG $A66D
  INCLUDE "finalcut/fcscreens.asm"  ; the screens

  SAVEBIN "finalcut-6060.bin",$6060,38669
