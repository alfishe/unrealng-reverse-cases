; R-Type, Electric Dreams Software 1988: level 1, 13228 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 40).
; Written by kit/mkgame.py from src/level1/level1.ann and the recordings; edit level1.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
MapColumn      EQU $7A84
FrameCounter   EQU $7A89
WavePtr        EQU $7A90
DrawTag        EQU $7A9C
ShipColumn     EQU $7AA1
ShipRow        EQU $7AA2
Carriers       EQU $7AC1
Scratch        EQU $7ACF
LevelVars      EQU $7DF9
EnemyShots     EQU $8386
EnemySlots     EQU $8501
MainLoopPatch  EQU $8656
SetDrawLimitA  EQU $8A40
DrawSprite     EQU $8CFD
DrawSpriteMirrored EQU $8D65
LevelObject    EQU $8E85
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveDrawA      EQU $916F
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
EnemyDies      EQU $A599
FreeExplosion  EQU $A5A5
AwardScore     EQU $A5B4
GetCell        EQU $C0E4
BossDestroyed  EQU $C19C
ClearCells     EQU $C20B
StartWaveAt    EQU $C225
AddScore       EQU $C23F
MoveByBits     EQU $C3D1
SoftCellsOn    EQU $C3E5
SoftCellsOff   EQU $C3EE
ClearCellsTag  EQU $C3F9
  ORG $C4AE
  INCLUDE "level1data.asm"  ; Level 1

  SAVEBIN "level1.bin",$C4AE,$33AC
