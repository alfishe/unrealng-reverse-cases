; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: the enemy handlers: the common enemy, the lockable enemy, the big enemy
;
; Every enemy handler: out of the columns of play (12-55 for the common and the lockable ones, 7-55 for the big one)
; the object escapes (EnemyEscaped, FreeEnemySlot); else RunPath, ClampRow and $A0EB (the animation and the aimed
; fire), then the hits: a bit in $80E5 (plasma, seeker) kills at once, a bit in $80BB (laser) takes one hit point
; (+$0D); a hit point count of $FF is invulnerable. At 0: EnemyKilled, the explosion ($A293) and the score of +$0C
; ($A489).
; --------------------------------------------------------------------------------------------------------------------

; kinds 2 and 11: a common enemy
;
; 1412 executions in c2.
EnemyHandler:
  LD A,(IY+$04)
  SUB $0C
  JP M,EnemyLeaves
  CP $2C
  JR C,EnemyMove
EnemyLeaves:
  CALL EnemyEscaped       ; out of the playfield: escaped
  CALL FreeEnemySlot
  RET
EnemyMove:
  CALL RunPath            ; path, clamp, $A0EB, hits
  CALL ClampRow
  CALL EnemyFire
  LD A,(IY+$0D)
  INC A
  RET Z
  LD C,(IY+$24)
  LD A,(PlasmaHitMask)
  AND C
  JR NZ,EnemyDies
  LD A,(LaserHitMask)
  AND C
  RET Z
  DEC (IY+$0D)
  RET NZ
EnemyDies:
  CALL EnemyKilled        ; destroyed: the wave, the explosion, the score
  CALL StartExplosion
  LD A,(IY+$0C)
  CALL AddScore
  RET

; kind 8: an enemy the homing sight can lock
;
; As EnemyHandler without the plasma kill; with no lock ($80E2 = 0) and its bit
; in the sight's mask $80E4 it becomes the lock ($80E0 = IY, $80E2 = its bit)
; and flashes ($7F79 x 8 + $40). The locked one dies of a missile hit ($80E3);
; lasers take hit points. Leaving play clears its lock bit. Not run in c1/c2;
; r1 (all levels) runs it.
LockableHandler:
  LD A,(IY+$04)
  SUB $0C
  JP M,LockableLeaves
  CP $2C
  JR C,LockableMove
LockableLeaves:
  LD A,(IY+$24)           ; its lock bit off, escaped
  CPL
  LD HL,LockMask
  AND (HL)
  LD (HL),A
  CALL EnemyEscaped
  CALL FreeEnemySlot
  RET
LockableMove:
  CALL RunPath            ; path, clamp, $A0EB, the lock
  CALL ClampRow
  CALL EnemyFire
  LD HL,LockMask
  LD A,(HL)
  AND A
  JR NZ,LockableFlash
  LD A,(SightMask)
  AND (IY+$24)
  JR Z,LockableFlash
  LD (LockTarget),IY
  LD A,(IY+$24)
  LD (HL),A
LockableFlash:
  AND (IY+$24)            ; locked: flash
  JR Z,LockableHits
  LD A,(SpinnerColour)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$40
  LD (IY+$25),A
LockableHits:
  LD C,(IY+$24)           ; a missile hit on the lock, or a laser hit
  LD A,(HL)
  AND C
  LD HL,MissileHitMask
  AND (HL)
  JR NZ,LockableDies
  LD A,(LaserHitMask)
  AND C
  RET Z
  DEC (IY+$0D)
  RET NZ
LockableDies:
  LD A,(IY+$24)           ; destroyed: the lock off, the wave, the explosion,
                          ; the score
  CPL
  LD HL,LockMask
  AND (HL)
  LD (HL),A
  CALL EnemyKilled
  CALL StartExplosion
  LD A,(IY+$0C)
  CALL AddScore
  RET

; kind 12: the big (boss) enemy
;
; Columns 7-55. Its row mask +$0B = $FE shifted left once per row below row 11
; (its lower rows out of the collision grid near the floor). Lockable as kind
; 8; a missile hit takes 4 hit points and the lock, a laser hit one with a
; colour flash. Every hit sets the sound pointers $7F80 = $FD00, $7F84 = $EDB2,
; $7F88 = $D6ED (the hit noise). Below 0 hit points: EnemyKilled, X + 2,
; ScatterDebris (the debris of a big explosion) and the score. Not run in
; c1/c2; r1 (all levels) runs it.
BigEnemyHandler:
  LD A,(IY+$04)
  SUB $07
  JP M,BigEnemyLeaves
  CP $31
  JR C,BigEnemyMove
BigEnemyLeaves:
  XOR A                   ; the lock off, escaped
  LD (LockMask),A
  CALL EnemyEscaped
  CALL FreeEnemySlot
  RET
BigEnemyMove:
  CALL RunPath            ; path, clamp
  CALL ClampRow
  LD C,$FE
  LD A,(IY+$06)
  SUB $0C
  JR C,BigEnemyRowSet
  INC A
  LD B,A
BigEnemyRowMask:
  SLA C                   ; one row less for each row below 11
  DJNZ BigEnemyRowMask
BigEnemyRowSet:
  LD (IY+$0B),C           ; the mask, $A0EB, the lock
  CALL EnemyFire
  LD HL,LockMask
  LD A,(HL)
  AND A
  JR NZ,BigEnemyFlash
  LD A,(SightMask)
  AND (IY+$24)
  JR Z,BigEnemyFlash
  LD (LockTarget),IY
  LD A,(IY+$24)
  LD (HL),A
BigEnemyFlash:
  AND (IY+$24)            ; locked: flash
  JR Z,BigEnemyHits
  LD A,(SpinnerColour)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$40
  LD (IY+$25),A
BigEnemyHits:
  LD C,(IY+$24)           ; a missile hit: - 4 and the lock off
  LD A,(HL)
  AND C
  LD HL,MissileHitMask
  AND (HL)
  JR Z,BigEnemyLaser
  LD A,(IY+$0D)
  SUB $04
  LD (IY+$0D),A
  XOR A
  LD (LockMask),A
  JR BigEnemyHitSound
BigEnemyLaser:
  LD A,(LaserHitMask)     ; a laser hit: - 1 and a flash
  AND (IY+$24)
  RET Z
  CALL CycleColour
  DEC (IY+$0D)
BigEnemyHitSound:
  LD HL,HitGridY          ; the hit sound; below 0: destroyed
  LD (SoundPattern1),HL
  LD HL,SpriteCacheImages+$066A
  LD (SoundPattern2),HL
  LD HL,GlyphCacheUpper+$0EED
  LD (SoundPattern3),HL
  LD A,(IY+$0D)
  AND A
  RET P
  XOR A
  LD (LockMask),A
  CALL EnemyKilled
  INC (IY+$04)
  INC (IY+$04)
  CALL ScatterDebris
  LD A,(IY+$0C)
  CALL AddScore
  RET
