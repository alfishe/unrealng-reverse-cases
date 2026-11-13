; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The enemy's hit test
;
; The enemies live in the 23-byte records at $7C20 (to the $FF end mark), run once a pass by UpdateEnemy from $865D:
; +0 the kind (bits 0-1: 0 and 3 wander, 1 patrols, 2 chases Rick; 3 also climbs ladders after Rick; bit 2 clear takes
; the second sprite set, 6 sprites on), +1 x, +2/+3 y, +4/+5 the sprite, +6 the x step (2 or -2; bit 7 the mirror), +9
; the walk frame counter, +$0A/+$0B a script nothing reads, +$0C/+$0D the map entry, +$0E/+$0F the vertical speed (8.8
; fixed point, pixels a pass), +$10 the y fraction, +$11 climbing ($FF), +$12 the patrol step count, +$13 the patrol
; length, +$14 dying ($FF), +$15 the dying drift, +$16 the stun timer.
;
; The sprites are fixed: walking Sprites 28-30 (EnemyWalkSprites), dying 31, climbing 32-33, each +6 for the other
; set. Gravity adds $80 a pass up to 8 pixels; $8FF9 probes the cell flags under the new place and leaves them in
; $915E (here: bit 5 kills, bits 1-2 floor or wall, bit 3 and 4 ladder, bit 6 a step with its y in $915F; the bits'
; names to be checked against $8FF9).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8BF3

; The enemy at IX against the bullet, the blast, the punch and Rick; C: the
; enemy is killed
;
; The enemy's box: x (IX+1) + 4, y (IX+2/+3), 16 x 21 pixels. In order: the
; bullet (record $9BB4 live) inside the box (BulletHits): the bullet is spent
; ($9BB4 = 0), return C. The detonator's blast at phase 4-9 ($9BC6) over the
; box widened to 24 (BlastHits): 500 points (the digits at $7EF3, $7ED3),
; return C. The punch ($9BA3 set) inside the box (PunchHits): stunned, (IX+$16)
; = 40, effect 9, play goes on. Last Rick: when the box touches him
; (TouchesRick) he dies ($93D0 at $8C67, the POKE file's immunity to enemies),
; return NC.
;
; Called for every live enemy by $9ECE. Witness: 37 761 runs in 55 builds: the
; bullet 43 kills, the blast 5, the punch 9 (rzx-l1-24000-poke,
; rzx-l5-12000-poke), Rick killed 413 times.
;
; Witness: L1 95909 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12,
; sec-l5-s3, sec-l5-s5).
TestEnemyHits:
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD A,(IX+$01)
  ADD A,$04
  LD E,A
  LD BC,$1510             ; B = 21 rows, C = 16 columns
  LD A,(BulletRecord)
  AND A
  JP Z,EnemyBlastTest
  PUSH HL
  PUSH DE
  CALL BulletHits
  POP DE
  POP HL
  JP NC,EnemyBlastTest
  XOR A                   ; the bullet is spent
  LD (BulletRecord),A
  SCF
  RET
EnemyBlastTest:
  LD A,(DetonatorFuse)    ; the blast hurts at phases 4-9
  CP $0A
  JP NC,EnemyPunchTest
  CP $04
  JP C,EnemyPunchTest
  PUSH HL
  PUSH DE
  LD BC,$1518
  CALL BlastHits
  POP DE
  POP HL
  JP NC,EnemyPunchTest
  LD HL,Points50          ; 500 points
  CALL AddScore
  SCF
  RET
EnemyPunchTest:
  LD A,(PunchTimer)
  AND A
  JP Z,EnemyTouchTest
  LD A,(IX+$01)
  ADD A,$04
  LD E,A
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD BC,$1510
  CALL PunchHits
  JP NC,EnemyTouchTest
  LD A,$09                ; effect 9, the enemy stunned for 40 passes
  CALL PlayEffect
  LD (IX+$16),$28
EnemyTouchTest:
  LD BC,$1510             ; Rick dies on contact
  CALL TouchesRick
  RET NC
  CALL KillRick
  XOR A
  RET

  ORG $9EAF

; One pass of the enemy at IX
;
; A dying enemy goes to EnemyFalling. Otherwise the step flags EnemyOnStep and
; EnemyOnGround are cleared and the behaviour (+0 bits 0-1) chosen: 1
; EnemyPatrol, 2 EnemyChaser, 0 and 3 EnemyWanderer.
;
; Evidence: 41 073 runs in 59 builds (load-l2 873, load-l3 558, load-l4 634,
; the rzx pieces; none in c1 or the controls-* recordings), all from $8695.
;
; Witness: L1 103099 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6,
; sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).
UpdateEnemy:
  LD A,(IX+$14)
  AND A
  JP NZ,EnemyFalling
  LD HL,$0000             ; EnemyOnStep and EnemyOnGround cleared
  LD (EnemyOnStep),HL
  LD A,(IX+$00)
  AND $03
  CP $01
  JP Z,EnemyPatrol
  CP $02
  JP Z,EnemyChaser
  JP EnemyWanderer

; Test what hits the enemy, then pick its sprite
;
; $8BF3 tests the bullet, the detonator's blast, the punch box (a stun: +$16 =
; 40 passes, effect 9) and Rick (Rick dies, $93D0); C (the bullet or the blast
; hit) kills the enemy (KillEnemy). A stunned enemy keeps its sprite. A
; climbing one alternates Sprites 32 and 33 every two passes; a walking one
; takes EnemyWalkSprites[(+9 / 4)] and +9 moves on by 2 (wrapping at 12): a new
; frame every second pass.
;
; The step 1 ($9F32) and step 4 ($9F3B) need EnemyAnimSlow or EnemyAnimFast,
; which nothing writes: not executed in any recording. Witness: 37 761 runs in
; 55 builds (from EnemyWanderer 6166, EnemyChaser 9107, EnemyPatrol 22 488);
; KillEnemy from here 7 times.
;
; Witness: L1 95909 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12,
; sec-l5-s3, sec-l5-s5).
EnemyHitsAndSprite:
  CALL TestEnemyHits
  JP C,KillEnemy          ; C: the bullet or the blast hit it
  LD A,(IX+$16)           ; stunned: keep the sprite
  AND A
  RET NZ
  LD A,(IX+$11)
  AND A
  JP Z,EnemyWalkSprite
  LD DE,Sprites+32*128      ; the two climbing sprites
  LD HL,Sprites+33*128
  LD A,(IX+$09)
  INC A
  AND $03
  LD (IX+$09),A
  AND $02
  JP Z,EnemyClimbSprite
  EX DE,HL
EnemyClimbSprite:
  BIT 2,(IX+$00)          ; bit 2 clear: the second set, 6 sprites on
  JP NZ,EnemyClimbSet
  LD BC,6*128
  ADD HL,BC
EnemyClimbSet:
  LD (IX+$04),L
  LD (IX+$05),H
  RET
EnemyWalkSprite:
  LD A,(IX+$09)           ; (+9 / 2) AND 6: a word of EnemyWalkSprites
  RRA
  AND $06
  LD C,A
  LD B,$00
  LD HL,EnemyWalkSprites
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  BIT 2,(IX+$00)
  JP NZ,EnemyWalkSet
  LD BC,6*128
  ADD HL,BC
EnemyWalkSet:
  LD (IX+$04),L
  LD (IX+$05),H
  LD C,$02
  LD A,(EnemyAnimSlow)
  AND A
  JP Z,EnemyAnimTestFast
EnemyAnimStep1:
  LD C,$01                ; LD C,1 (not executed in any recording)
EnemyAnimTestFast:
  LD A,(EnemyAnimFast)
  AND A
  JP Z,EnemyAnimAdvance
EnemyAnimStep4:
  LD C,$04                ; LD C,4 (not executed in any recording)
EnemyAnimAdvance:
  LD A,(IX+$09)           ; +9 += C, modulo 12
  ADD A,C
  CP $0C
  JP C,EnemyAnimStore
  SUB $0C
EnemyAnimStore:
  LD (IX+$09),A
  RET

; The enemy movement flags of the current pass
;
; +0 EnemyOnStep: $FF when EnemyVertical found a step (probe bit 6) under the
; enemy; +1 EnemyOnGround: $FF when the enemy stands (landed, or EnemyOnStep
; copied by EnemyWalk). Both cleared by UpdateEnemy, written by EnemyVertical,
; read by EnemyWalk. +2 EnemyAnimFast and +3 EnemyAnimSlow are read by
; EnemyHitsAndSprite and never written (always 0).
EnemyMoveFlags:
EnemyOnStep:
  DEFB $00
EnemyOnGround:
  DEFB $00
EnemyAnimFast:
  DEFB $00                ; never written: the walk frames' step 4 stays off
EnemyAnimSlow:
  DEFB $00                ; never written: the walk frames' step 1 stays off

; The three walking sprites: Sprites 28, 29, 30 ($D06D, $D0ED, $D16D)
;
; Read by EnemyHitsAndSprite ($9F10); +6 x 128 for the second set (Sprites
; 34-36).
EnemyWalkSprites:
  DEFW $D06D,$D0ED,$D16D

; An enemy is hit: score, effect, and it flies off
;
; When the enemy is in the shown part (y from $40 to $FF), effect 10 and 50
; points (the digits at $7EF3, 000050, through $7ED3). Then +$14 = $FF (dying),
; the speed -5 pixels a pass (upwards) and the drift +$15 = 2 when x < $74,
; else -2 (towards the screen's middle).
;
; Callers: EnemyHitsAndSprite ($9ED1, 7: the bullet or the blast),
; EnemyVertical ($A0E8, 34: a deadly cell) and UpdateTrap ($A454, 111: a deadly
; trap). Witness: 193 runs in 43 builds (load-l5 2, the rzx pieces).
;
; Witness: L1 602 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-16000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full,
; load-l5, sec-l2-s7, sec-l2-s12, sec-l5-s3, sec-l5-s5).
KillEnemy:
  LD A,(IX+$03)
  AND A
  JP NZ,KillEnemyFling
  LD A,(IX+$02)
  CP $40
  JP C,KillEnemyFling
  LD A,$0A
  CALL PlayEffect
  LD HL,Points50
  CALL AddScore
KillEnemyFling:
  LD (IX+$14),$FF
  LD HL,-5*256
  LD (IX+$0E),L
  LD (IX+$0F),H
  LD C,$02
  LD A,(IX+$01)
  CP $74
  JP C,KillEnemyDir
  LD C,$FE
KillEnemyDir:
  LD (IX+$15),C
  RET

; The killed enemy's fall: gravity, drift, a spinning sprite, freed below the
; view
;
; Speed += $80 a pass (to 8 pixels), y += speed; once y passes 255 (+3 not 0)
; the record is retired (RetireObject). x += the drift; the sprite is Sprites
; 31 (+6 for the second set), the mirror bit toggled every second pass.
;
; Evidence: 3308 runs in 47 builds, all from UpdateEnemy ($9EB3).
;
; Witness: L1 7182 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-16000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, load-l5, sec-l2-s7, sec-l2-s12, sec-l5-s3, sec-l5-s5).
EnemyFalling:
  LD L,(IX+$0E)
  LD H,(IX+$0F)
  LD DE,$0080
  LD B,$FF
  ADD HL,DE
  LD A,H
  AND A
  JP M,EnemyFallMove
  INC B
  CP $07
  JP C,EnemyFallMove
  LD HL,$0800
EnemyFallMove:
  LD (IX+$0E),L           ; B: the carry into y's high byte (-1 rising)
  LD (IX+$0F),H
  LD E,(IX+$10)
  LD D,(IX+$02)
  LD A,(IX+$03)
  ADD HL,DE
  ADC A,B
  LD (IX+$10),L
  LD (IX+$02),H
  LD (IX+$03),A
  AND A
  JP NZ,RetireObject
  LD A,(IX+$01)
  ADD A,(IX+$15)
  LD (IX+$01),A
  LD HL,Sprites+31*128
  LD A,(IX+$09)
  INC A
  AND $01
  LD (IX+$09),A
  JP NZ,EnemyFallSprite
  LD A,(IX+$06)
  XOR $80
  LD (IX+$06),A
EnemyFallSprite:
  BIT 2,(IX+$00)
  JP NZ,EnemyFallSet
  LD BC,6*128
  ADD HL,BC
EnemyFallSet:
  LD (IX+$04),L
  LD (IX+$05),H
  RET

; Behaviours 0 and 3: walk, and turn at random on the 16-pixel grid
;
; EnemyVertical, EnemyWalk with the step +6, EnemyHitsAndSprite; then, when not
; climbing and x AND 15 = 4, one chance in 4 ($81AF AND 3 = 0) of a new random
; direction (2 or -2).
;
; Evidence: 6166 runs in 18 builds (load-l2 582, load-l3 279, the rzx pieces);
; a new direction 197 times.
;
; Witness: L1 18465 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke,
; rzx-l1-08000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-12000-poke, c48, load-l2, load-l3, sec-l2-s7, sec-l2-s11, sec-l2-s12,
; sec-l3-s5, sec-l4-s12, sec-l5-s5).
EnemyWanderer:
  CALL EnemyVertical
  LD D,(IX+$06)
  CALL EnemyWalk
  CALL EnemyHitsAndSprite
  LD A,(IX+$11)
  AND A
  RET NZ
  LD A,(IX+$01)
  AND $0F
  CP $04
  RET NZ
  CALL Random
  AND $03
  RET NZ
  CALL Random
  LD D,$02
  AND A
  JP P,EnemyWanderTurn
  LD D,$FE
EnemyWanderTurn:
  LD (IX+$06),D
  RET

; Behaviour 2: walk; on the grid, at a floor, turn towards Rick or at random
;
; As EnemyWanderer, but the turn is tested only when the probe ($915E) shows
; floor (bits 1-2) and no step (bit 6), at x AND 15 = 4: half the time ($81AF
; negative) towards Rick's x $9BAC, otherwise a random direction.
;
; Evidence: 9108 runs in 32 builds; the turn branches only in rzx-l2-20000-poke
; and rzx-l4-02000/04000-poke (13 runs).
;
; Witness: L1 23917 (cheats, rzx-l1-02000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-full,
; load-l2, load-l5, sec-l2-s12, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12,
; sec-l5-s3, sec-l5-s5).
EnemyChaser:
  CALL EnemyVertical
  LD D,(IX+$06)
  CALL EnemyWalk
  CALL EnemyHitsAndSprite
  LD A,(CollisionFlags)
  BIT 6,A
  JP NZ,EnemyChaseDone
  AND $06
  JP Z,EnemyChaseDone
  LD A,(IX+$01)
  AND $0F
  CP $04
  JP NZ,EnemyChaseDone
  CALL Random
  AND A
  JP P,EnemyChaseRandom
  LD D,$FE
  LD A,(RickX)
  CP (IX+$01)
  JP C,EnemyChaseTurn
  LD D,$02
  JP EnemyChaseTurn
EnemyChaseRandom:
  CALL Random
  LD D,$02
  AND A
  JP P,EnemyChaseTurn
  LD D,$FE
EnemyChaseTurn:
  LD (IX+$06),D
EnemyChaseDone:
  RET

; Behaviour 1: walk +$13 pixels' worth of steps, turn, again
;
; EnemyVertical; then, unless the probe shows a step without floor, counts +$12
; up and turns (+6 negated) when it reaches the patrol length +$13; then
; EnemyWalk and EnemyHitsAndSprite.
;
; Evidence: 22 491 runs in 44 builds (load-l3, load-l4, the rzx pieces).
;
; Witness: L1 53535 (rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, load-l3, load-l4,
; sec-l2-s10, sec-l2-s12, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11,
; sec-l4-s12, sec-l5-s5).
EnemyPatrol:
  CALL EnemyVertical
  LD A,(CollisionFlags)
  AND $06
  JP NZ,EnemyPatrolCount
  LD A,(CollisionFlags)
  BIT 6,A
  JP NZ,EnemyPatrolWalk
EnemyPatrolCount:
  LD A,(IX+$12)
  INC A
  CP (IX+$13)
  JP C,EnemyPatrolStore
  LD A,(IX+$06)
  NEG
  LD (IX+$06),A
  XOR A
EnemyPatrolStore:
  LD (IX+$12),A
EnemyPatrolWalk:
  LD D,(IX+$06)
  CALL EnemyWalk
  CALL EnemyHitsAndSprite
  RET

; An enemy's vertical move: gravity, landing, ceilings, steps, ladders
;
; A climbing enemy goes to EnemyClimb. Otherwise speed += $80 (to 8 pixels a
; pass), the new y probed ($8FF9) at x. A deadly cell (bit 5) kills
; (KillEnemy). A step (bit 6): EnemyOnStep set, the enemy put on the step's y
; ($915F - 21), speed 1, probed again; a floor there lands it
; (EnemyHitCeiling's snap), else the probe bits $42 are forced. A ladder (bit
; 4) under a behaviour-3 enemy at x AND 15 = 4 with Rick above starts the climb
; (+$11 = $FF). A floor while falling (or bit 2) lands it (EnemyLand:
; EnemyOnGround, y snapped to the cell, speed 1); a ceiling while rising (bit 1
; only) stops the rise (EnemyHitCeiling); no floor: the new y stored, and an
; enemy that fell out of the view is freed (FreeObject).
;
; Evidence: 37 765 runs in 55 builds; the landing 34 085, the ceiling snap 16
; (rzx-l5-14000-poke only), the climb 786 (13 builds).
;
; Witness: L1 95917 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12,
; sec-l5-s3, sec-l5-s5).
EnemyVertical:
  LD A,(IX+$11)
  AND A
  JP NZ,EnemyClimb
  LD L,(IX+$0E)
  LD H,(IX+$0F)
  LD DE,$0080
  LD B,$FF
  ADD HL,DE
  LD A,H
  AND A
  JP M,EnemyGravityCapped
  INC B
  CP $07
  JP C,EnemyGravityCapped
  LD HL,$0800
EnemyGravityCapped:
  LD (IX+$0E),L           ; A:H:L = the new y (24 bits), C = its fraction
  LD (IX+$0F),H
  LD E,(IX+$10)
  LD D,(IX+$02)
  LD A,(IX+$03)
  ADD HL,DE
  ADC A,B
  LD C,L
  LD L,H
  LD H,A
  PUSH BC
  PUSH HL
  LD C,(IX+$0F)
  LD E,(IX+$01)
  CALL TestBodyBox
  POP HL
  POP BC
  LD A,(CollisionFlags)
  BIT 5,A                 ; bit 5: a deadly cell
  JP NZ,KillEnemy
  BIT 6,A
  JP Z,EnemyTestLadder
  LD A,$FF
  LD (EnemyOnStep),A
  LD HL,(PlatformTop)
  LD BC,-21               ; the step's y less 21
  ADD HL,BC
  PUSH HL
  LD E,(IX+$01)
  LD C,$80
  CALL TestBodyBox
  POP HL
  LD (IX+$0E),$00
  LD (IX+$0F),$01
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,KillEnemy
  AND $06
  JP NZ,EnemyHitCeiling
  LD A,(CollisionFlags)
  OR $42
  LD (CollisionFlags),A
  JP EnemyFallFree
EnemyTestLadder:
  BIT 4,A
  JP Z,EnemyTestFloor
  EX AF,AF'
  LD A,(IX+$00)
  AND $03
  CP $03
  JP NZ,EnemyNoClimb
  LD A,(IX+$01)
  AND $0F
  CP $04
  JP NZ,EnemyNoClimb
  PUSH HL
  LD HL,(RickY)
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  EX DE,HL
  SBC HL,DE
  POP HL                  ; Rick is above (his y $9BAD below the enemy's)
  JP NC,EnemyNoClimb
  LD (IX+$11),$FF
  JP EnemyClimb
EnemyNoClimb:
  EX AF,AF'
EnemyTestFloor:
  AND $06
  JP Z,EnemyFallFree
  AND $04
  JP NZ,EnemyLand
  BIT 7,(IX+$0F)
  JP Z,EnemyLand
EnemyHitCeiling:
  LD A,L                  ; y to the next cell boundary, speed 1 (falls)
  OR $07
  LD L,A
  INC HL
  LD (IX+$02),L
  LD (IX+$03),H
  LD (IX+$10),$00
  LD HL,$0100
  LD (IX+$0E),L
  LD (IX+$0F),H
  RET
EnemyLand:
  LD A,$FF
  LD (EnemyOnGround),A
  LD BC,$000C
  ADD HL,BC
  LD A,L
  OR $07
  LD L,A
  LD BC,-20
  ADD HL,BC
  LD (IX+$11),$00
  LD (IX+$02),L
  LD (IX+$03),H
  LD (IX+$10),$00
  LD HL,$0100
  LD A,(CollisionFlags)
  BIT 5,A
  JP Z,EnemySetSpeed
EnemyLandLevel5:
  LD A,(Level)            ; level 5 ($7EF1 = 5) with a deadly cell: speed $F781
                          ; (not executed in any recording)
  CP $05
  JP NZ,EnemySetSpeed
  LD HL,$F781
EnemySetSpeed:
  LD (IX+$0E),L
  LD (IX+$0F),H
  RET
EnemyFallFree:
  LD (IX+$02),L           ; no floor: keep falling
  LD (IX+$03),H
  LD (IX+$10),C
  CALL IsOffView
  JP NZ,FreeObject
  RET
EnemyClimb:
  LD HL,(RickY)           ; climbing: 2 pixels a pass towards Rick's y
  LD E,(IX+$02)
  LD D,(IX+$03)
  INC DE
  LD A,E
  AND $FE
  LD E,A
  LD (IX+$02),E
  OR A
  SBC HL,DE
  JP Z,EnemyClimbStep
  LD HL,-2
  JP C,EnemyClimbStep
  LD HL,$0002
EnemyClimbStep:
  LD (IX+$0E),L
  LD (IX+$0F),H
  ADD HL,DE
  LD E,(IX+$01)
  PUSH HL
  CALL TestBodyBox
  POP HL
  LD A,(CollisionFlags)
  BIT 3,A
  JP NZ,EnemyClimbOn
  LD (IX+$11),$00
  JP EnemyTestFloor
EnemyClimbOn:
  AND $E2                 ; the ladder goes on: test the floor bits only
  JP EnemyTestFloor

; An enemy's horizontal move: D = the x step
;
; A stunned enemy (+$16) counts down and stands. A climbing one does not walk.
; An enemy on a step walks with the push $9161 alone (D = 0); one standing on a
; moving thing with $9162 set stands (+9 = 0). An enemy in the air does not
; walk (+9 = 0). Otherwise x += D + the push $9161, turning at the edges 0 and
; $E8; the new x probed ($8FF9, C = $FF): a wall (bit 1) turns it and snaps x
; to the cell edge; at x AND 15 = 4 a ladder top (bit 3) under a behaviour-3
; enemy with Rick above starts the climb.
;
; Evidence: 37 763 runs in 55 builds; the wall turn on the right 144 runs (27
; builds).
;
; Witness: L1 95913 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke,
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12,
; sec-l5-s3, sec-l5-s5).
EnemyWalk:
  LD A,(IX+$16)
  AND A
  JP Z,EnemyWalkStart
  DEC A
  LD (IX+$16),A
  RET NZ
EnemyWalkStart:
  LD A,(IX+$11)
  AND A
  RET NZ
  LD A,(EnemyOnStep)
  AND A
  JP Z,EnemyWalkGroundTest
  LD (EnemyOnGround),A
  LD A,(PlatformDx)
  AND A
  JP Z,EnemyWalkStepTest
  LD D,$00
  JP EnemyWalkStepX
EnemyWalkStepTest:
  LD A,(PlatformDy)       ; on a step: $9162 set makes it stand
  AND A
  JP Z,EnemyWalkGroundTest
  LD (IX+$09),$00
  RET
EnemyWalkGroundTest:
  LD A,(EnemyOnGround)
  AND A
  JP NZ,EnemyWalkStepX
  LD (IX+$09),$00
  RET
EnemyWalkStepX:
  LD A,(PlatformDx)       ; D += the push $9161
  ADD A,D
  LD D,A
  LD A,(IX+$01)
  BIT 7,D
  JP Z,EnemyWalkRight
  ADD A,D
  JP C,EnemyWalkProbe
  LD A,(IX+$06)
  NEG
  LD (IX+$06),A
  XOR A
  JP EnemyWalkProbe
EnemyWalkRight:
  ADD A,D
  CP $E8
  JP C,EnemyWalkProbe
  LD A,(IX+$06)
  NEG
  LD (IX+$06),A
  LD A,$E8
EnemyWalkProbe:
  LD E,A
  PUSH DE
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD C,$FF
  CALL TestBodyBox
  POP DE
  LD A,(CollisionFlags)
  AND $02
  JP Z,EnemyWalkDone
  LD A,(IX+$06)
  NEG
  LD (IX+$06),A
  LD A,D
  AND A
  JP P,EnemyWallRight
  LD A,E
  ADD A,$0C
  AND $F8
  SUB $04
  LD (IX+$01),A
  RET
EnemyWallRight:
  LD A,E
  ADD A,$0B
  OR $07
  SUB $13
  LD (IX+$01),A
  RET
EnemyWalkDone:
  LD (IX+$01),E
  LD A,(CollisionFlags)
  AND $08
  RET Z
  LD A,E
  AND $0F
  CP $04
  RET NZ
  LD A,(IX+$00)
  AND $03
  CP $03
  RET NZ
  LD HL,(RickY)
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  RET NC
  LD (IX+$11),$FF
  RET
