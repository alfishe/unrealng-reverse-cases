; --------------------------------------------------------------------------------------------------------------------
; droidtables.asm: The droid's frame tables and the animation tables of the sprites
;
; The frame tables of the droid, the turn-round, the enemies, the explosions and the weapon-3 shot.
; --------------------------------------------------------------------------------------------------------------------

; The droid's 14 frame graphics
;
; MoveDroid $752D: DroidGraphic = DroidFrames[DroidFrame], DroidWidth =
; DroidWidths[DroidFrame] (L1 15 293). The graphics are DroidGraphics
; $9C40-$A257.
DroidFrames:
  DEFW DroidGraphics,DroidWalk1,DroidWalk2,DroidWalk3,DroidWalk4,DroidWalk5,DroidWalk6
  DEFW DroidWalk7,DroidTurn1,DroidTurn2,DroidFront,DroidFly1,DroidFly2,DroidFly3

; The width in bytes of each frame
DroidWidths:
  DEFB $03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$03,$03,$03

; The frames of the turn-round: 8, 9, 10, 9, 8, then $FF
;
; TurnRound $7866 plays it (L1 538 steps).
TurnSequence:
  DEFB $08,$09,$0A,$09,$08,$FF

; The frames of each of the nine enemy kinds
;
; EnemyKind $90C8 reads EnemyFrameCounts - 1 + the kind (1-9): 4, 3, then 4 for
; kinds 3-9.
EnemyFrameCounts:
  DEFB $04,$03,$04,$04,$04,$04,$04,$04,$04

; The graphics of the nine enemy kinds ($A74E-$AEC4)
;
; EnemyKind returns HL = EnemyGraphics - 2 + 2 x kind. Each frame is 49 bytes:
; the shift byte, then 16 rows of 3 bytes (ShiftGraphic3).
EnemyGraphics:
  DEFW EnemyGraphicsData,EnemyKind2,EnemyKind3,EnemyKind4,EnemyKind5,EnemyKind6,EnemyKind7,EnemyKind8,EnemyKind9

; The four frames of an enemy's explosion
ExplosionFrames:
  DEFW EnemyExplosion,EnemyExplosion2,EnemyExplosion3,EnemyExplosion4

; The four frames of an enemy's materialising
MaterialiseFrames:
  DEFW MaterialiseGraphics,Materialise2,Materialise3,Materialise4

; The four frames of an object's death
;
; The first word (ObjectDeath $B6BA) is never read: the dying states (state AND
; $0C = $04, $08, $0C) select offsets 2, 4, 6; $00 ends the death first
; (MoveObjectDying $8236).
ObjectDeathFrames:
  DEFW ObjectDeath,ObjectDeath2,ObjectDeath3,ObjectDeath4

; The four frames of weapon 3's shot
Weapon3Frames:
  DEFW ProbeExplosion,ProbeExplosion2,ProbeExplosion3,ProbeExplosion4
