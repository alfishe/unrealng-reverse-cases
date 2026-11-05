; --------------------------------------------------------------------------------------------------------------------
; handlertables.asm: The jump tables of the object kinds, the weapons and the path interpreter, the sine table
;
; Word tables JumpTable $91E2 dispatches through (A an index, HL the table).
; --------------------------------------------------------------------------------------------------------------------

; The side weapon's routine per pass: $9C83 plasma, $9CCA homing, $9CFE seeker
; (index +8 - 2, $9B2E)
SideWeaponFrames:
  DEFW PlasmaFrame
  DEFW HomingFrame
  DEFW SeekerFrame

; The pod actions: $9D4C speed, $9D5D laser, $9D68 plasma, $9DA5 homing, $9DDD
; seeker (index = the selector; $A217, $B284)
PodActions:
  DEFW PodSpeedUp
  DEFW PodLaser
  DEFW PodPlasma
  DEFW PodHoming
  DEFW PodSeeker

; The object handlers by kind (+$07): 0 player, 1 laser, 2 enemy, 3 explosion,
; 4 pod, 5 enemy shot, 6 sight, 7 seeker, 8 lockable, 9 plasma, 10 missile, 11
; enemy, 12 big enemy
;
; RunObjects $946F/$9487 (48K c2: 6080 JumpTable entries in all).
KindHandlers:
  DEFW PlayerHandler
  DEFW LaserHandler
  DEFW EnemyHandler
  DEFW ExplosionStep
  DEFW PodStep
  DEFW EnemyShotStep
  DEFW SightHandler
  DEFW SeekerHandler
  DEFW LockableHandler
  DEFW PlasmaHandler
  DEFW MissileHandler
  DEFW EnemyHandler
  DEFW BigEnemyHandler

; The path commands 0-7 (bits 0-2 of a command): RunPath $94DC
PathOps:
  DEFW PathOpAccelerate
  DEFW PathOpSetLoop
  DEFW PathOpSetInterval
  DEFW PathOpBounce
  DEFW PathOpHomePlayer
  DEFW PathOpSetDirection
  DEFW PathOpHomeTarget
  DEFW PathOpExtended

; The 16 extended path ops (bits 3-6 of command 7): PathOpExtended $950F
PathExtOps:
  DEFW PathOpScroll
  DEFW PathOpStop
  DEFW PathOpRandomDirection
  DEFW PathOpLoop
  DEFW PathOpDriftMiddle
  DEFW PathOpAimPlayer
  DEFW PathOpScrollAlways
  DEFW PathOpMove
  DEFW PathOpHome
  DEFW PathOpToCentre
  DEFW PathOpLand
  DEFW PathOpRandomSpeed
  DEFW PathOpBounceArena
  DEFW PathOpDive
  DEFW PathOpMoveFragile
  DEFW PathOpWait

; A signed sine, 64 steps a turn ($20 = 1): SetVelocity $98F1 reads it (48K c2:
; 21 entries)
SineTable:
  DEFB $20,$1F,$1F,$1E,$1C,$1B,$19,$18,$16,$15,$13,$11,$0E,$0B,$08,$04
  DEFB $00,$FC,$F8,$F5,$F2,$EF,$ED,$EB,$EA,$E8,$E7,$E5,$E4,$E2,$E1,$E1
  DEFB $E0,$E1,$E1,$E2,$E4,$E5,$E7,$E8,$EA,$EB,$ED,$EF,$F2,$F5,$F8,$FC
  DEFB $00,$04,$08,$0B,$0E,$11,$13,$15,$16,$18,$19,$1B,$1C,$1E,$1F,$1F
