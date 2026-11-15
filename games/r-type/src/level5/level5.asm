; R-Type, Electric Dreams Software 1988: level 5, 8904 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 56).
; Written by kit/mkgame.py from src/level5/level5.ann and the recordings; edit level5.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
MapColumn      EQU $7A84
FrameCounter   EQU $7A89
DrawTag        EQU $7A9C
ShipColumn     EQU $7AA1
ShipRow        EQU $7AA2
Carriers       EQU $7AC1
Scratch        EQU $7ACF
LevelVars      EQU $7DF9
EnemySlots     EQU $8501
DrawSprite     EQU $8CFD
DrawSpriteMirrored EQU $8D65
DrawSpriteFlipped EQU $8DD3
DrawSpriteBoth EQU $8E29
LevelObject    EQU $8E85
CellMark       EQU $8EA2
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
EnemyDies      EQU $A599
GetCell        EQU $C0E4
StartWaveAt    EQU $C225
AddScore       EQU $C23F
  ORG $C4AE
  INCLUDE "level5data.asm"  ; Level 5

  SAVEBIN "level5.bin",$C4AE,$22C8
