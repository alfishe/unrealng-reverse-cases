; Rick Dangerous 2, Micro Style 1990: level 5, 21 760 bytes at $A800-$FCFF as the game plays it (the maps'
; last 768 bytes deciphered); tools/mktape.py enciphers them for side B.
; Written by kit/mkgame.py from src/levels/levels.ann and the recordings; edit levels.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
PlayEffect     EQU $7A97  ; the game's effect start (A = the effect)
TrapRecords    EQU $7B8F  ; the six 24-byte trap records (table A, $FF at $7C1F); the Fat Guy takes the first five
EnemyRecords   EQU $7C20  ; the four 23-byte enemy records (table B); the Fat Guy's shot uses the first
AddScore       EQU $7ED3  ; adds the six digits at HL to the score
Points5000     EQU $7F05  ; 005000: the Fat Guy's points
LevelHookOn    EQU $8A24  ; nonzero: the level's own code runs (20 at the Fat Guy's exit; his hits left)
BulletHits     EQU $8C8D  ; C when the bullet lies in the box E, HL, C x B
BlastHits      EQU $8CAE  ; C when the detonator's blast overlaps the box
ProbePoint     EQU $8D0C  ; what lies at E, HL: 2 for a solid object, else the cell's flags
TouchesRick    EQU $8D53  ; C when the box E, HL, C x B overlaps Rick
KillRick       EQU $93D0  ; Rick dies
RickX          EQU $9BAC  ; Rick's x
RickY          EQU $9BAD  ; Rick's y (pixels from the view's top)
BulletRecord   EQU $9BB4  ; +0: the bullet flies
DetonatorFuse  EQU $9BC6  ; the detonator's fuse: the blast at 1-10
  ORG $A800
  INCLUDE "cells.asm"  ; The cells and the blocks: flags, pixels, attributes, 4 x 4 blocks
  INCLUDE "header.asm"  ; The level header, the level number and the sprite frame map
  INCLUDE "maps.asm"  ; The sections' maps: rows of 8 block numbers
  INCLUDE "sections.asm"  ; The section table, the exit lists and the map entry lists
  INCLUDE "kinds.asm"  ; The trap kinds: the kind table, the animation scripts, the paths and the kind records
  INCLUDE "fatguy.asm"  ; Level 5's own code: the Fat Guy

  SAVEBIN "level5.bin",$A800,$5500
