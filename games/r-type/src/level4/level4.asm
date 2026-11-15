; R-Type, Electric Dreams Software 1988: level 4, 12998 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 52).
; Written by kit/mkgame.py from src/level4/level4.ann and the recordings; edit level4.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
ScoreDirty     EQU $71D0
MapColumn      EQU $7A84
FrameCounter   EQU $7A89
DrawTag        EQU $7A9C
ShipColumn     EQU $7AA1
ShipRow        EQU $7AA2
Carriers       EQU $7AC1
Scratch        EQU $7ACF
LevelVars      EQU $7DF9
EnemySlots     EQU $8501
SetDrawLimitA  EQU $8A40
DrawSprite     EQU $8CFD
LevelObject    EQU $8E85
GameObject     EQU $8E8C
CellMark       EQU $8EA2
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
DrawGame       EQU $99FE
DrawGameFlipped EQU $9A06
DrawGameMirrored EQU $9A0E
DrawGameBoth   EQU $9A16
DrawPrepare    EQU $9A1E
ProcessHits    EQU $A495
EnemyDies      EQU $A599
GetCell        EQU $C0E4
StartWaveAt    EQU $C225
AddScore       EQU $C23F
SoftCellsOn    EQU $C3E5
SoftCellsOff   EQU $C3EE
ClearCellsTag  EQU $C3F9
  ORG $C4AE
  INCLUDE "level4data.asm"  ; Level 4

  SAVEBIN "level4.bin",$C4AE,$32C6
