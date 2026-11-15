; R-Type, Electric Dreams Software 1988: level 7, 12997 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 64).
; Written by kit/mkgame.py from src/level7/level7.ann and the recordings; edit level7.ann, not the .asm.

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
DrawSprite     EQU $8CFD
LevelObject    EQU $8E85
CellMark       EQU $8EA2
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
EnemyDies      EQU $A599
FreeExplosion  EQU $A5A5
AwardScore     EQU $A5B4
NextRandom     EQU $C05D
GetCell        EQU $C0E4
BossDestroyed  EQU $C19C
ClearCells     EQU $C20B
StartWaveAt    EQU $C225
AddScore       EQU $C23F
SoftCellsOn    EQU $C3E5
SoftCellsOff   EQU $C3EE
  ORG $C4AE
  INCLUDE "level7data.asm"  ; Level 7

  SAVEBIN "level7.bin",$C4AE,$32C5
