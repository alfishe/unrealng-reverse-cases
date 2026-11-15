; R-Type, Electric Dreams Software 1988: level 3, 13074 bytes loaded at $C4AE by LoadLevel $FE03 (tape TZX block 48).
; Written by kit/mkgame.py from src/level3/level3.ann and the recordings; edit level3.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
MetaColumn     EQU $7A83
MapColumn      EQU $7A84
FrameCounter   EQU $7A89
DrawTag        EQU $7A9C
ShipColumn     EQU $7AA1
ShipRow        EQU $7AA2
Carriers       EQU $7AC1
Scratch        EQU $7ACF
LevelVars      EQU $7DF9
DrawSprite     EQU $8CFD
DrawSpriteMirrored EQU $8D65
LevelObject    EQU $8E85
CellMark       EQU $8EA2
SlotFlags      EQU $8FCB
MoveStore      EQU $9168
MoveDraw       EQU $916E
MoveNext       EQU $9195
MoveScript     EQU $91A5
MoveDone       EQU $91B1
EnemyDies      EQU $A599
GetCell        EQU $C0E4
BossDestroyed  EQU $C19C
StartWaveAt    EQU $C225
AddScore       EQU $C23F
MoveByBits     EQU $C3D1
  ORG $C4AE
  INCLUDE "level3data.asm"  ; Level 3

  SAVEBIN "level3.bin",$C4AE,$3312
