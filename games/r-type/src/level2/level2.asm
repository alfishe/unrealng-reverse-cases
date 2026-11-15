; R-Type, Electric Dreams Software 1988: level 2, 12856 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 44).
; Written by kit/mkgame.py from src/level2/level2.ann and the recordings; edit level2.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
FrameCounter   EQU $7A89
DrawTag        EQU $7A9C
Carriers       EQU $7AC1
LevelVars      EQU $7DF9
EnemyShots     EQU $8386
CellMark       EQU $8EA2
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveDrawA      EQU $916F
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
BossDestroyed  EQU $C19C
ClearCells     EQU $C20B
AddScore       EQU $C23F
SoftCellsOn    EQU $C3E5
SoftCellsOff   EQU $C3EE
ClearCellsTag  EQU $C3F9
  ORG $C4AE
  INCLUDE "level2data.asm"  ; Level 2

  SAVEBIN "level2.bin",$C4AE,$3238
