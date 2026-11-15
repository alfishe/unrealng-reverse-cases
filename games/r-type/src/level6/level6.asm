; R-Type, Electric Dreams Software 1988: level 6, 8849 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 60).
; Written by kit/mkgame.py from src/level6/level6.ann and the recordings; edit level6.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
FrameCounter   EQU $7A89
DrawTag        EQU $7A9C
Carriers       EQU $7AC1
Scratch        EQU $7ACF
EnemySlots     EQU $8501
DrawSprite     EQU $8CFD
DrawSpriteMirrored EQU $8D65
LevelObject    EQU $8E85
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
  ORG $C4AE
  INCLUDE "level6data.asm"  ; Level 6

  SAVEBIN "level6.bin",$C4AE,$2291
