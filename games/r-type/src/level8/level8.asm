; R-Type, Electric Dreams Software 1988: level 8, 11980 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 68).
; Written by kit/mkgame.py from src/level8/level8.ann and the recordings; edit level8.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
ScrollStep     EQU $7A82
MetaColumn     EQU $7A83
MapColumn      EQU $7A84
FrameCounter   EQU $7A89
WavePtr        EQU $7A90
ShipColumn     EQU $7AA1
ShipRow        EQU $7AA2
Carriers       EQU $7AC1
RandomPtr      EQU $7ACD
LevelVars      EQU $7DF9
EnemySlots     EQU $8501
DrawSprite     EQU $8CFD
LevelObject    EQU $8E85
CellMark       EQU $8EA2
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
NextRandom     EQU $C05D
BossDestroyed  EQU $C19C
ClearCells     EQU $C20B
StartWaveAt    EQU $C225
AddScore       EQU $C23F
  ORG $C4AE
  INCLUDE "level8data.asm"  ; Level 8

  SAVEBIN "level8.bin",$C4AE,$2ECC
