; --------------------------------------------------------------------------------------------------------------------
; traps.asm: The traps and pickups: paths, animations, the deadly touch, triggers, the three pickups
;
; The traps live in the 24-byte records at $7B8F (to the $FF end mark), run once a pass by UpdateTrap from $865D: +0
; the kind (bit 0 alive, bit 1 path paused, bits 2-4 the trigger behaviour, bit 5, bit 6 deadly, bit 7 the detonator
; test), +1 x, +2/+3 y, +4/+5 the sprite (0: none), +6 flags (bit 7 mirror, 6 no trigger test, 5 freed at the path's
; end, 4 waiting for the path's end to switch, 3 one more wait), +7 width, +8 height, +9 the frame delay, +$0A/+$0B
; the animation script, +$0C/+$0D the map entry, +$0E the path step count, +$0F/+$10 the path, +$11/+$12 the second
; path, +$13/+$14 the second animation, +$15 the second kind, +$16 the last x step, +$17 the last y step.
;
; A path is a list of steps: a count and a byte of two signed nibbles (x step high, y step low; 7 means 8), done count
; times; $FF n plays effect n; 0 and an address goes on there (the loop point, where a waiting trap switches to its
; second path). An animation script is frame bytes (a frame number for SpriteFrameMap, $7F hidden), $80+delay then a
; frame (shown delay passes), $FD n an effect, $FF and an address a jump.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A2E1

; Play effect A when the record at IX is in the shown part (y $40-$FF)
;
; For the effects a path ($A327, 115 runs) or an animation script ($A631, 1239
; runs) asks for: off the shown part nothing is heard. Witness: 1354 runs in 47
; builds, c1 53; 258 times silent ($A2F5).
;
; Witness: L1 3183 (cheats, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l4,
; sec-l2-s7, sec-l3-s7, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TrapEffect:
  PUSH AF
  LD A,(IX+$03)
  AND A
  JP NZ,TrapEffectSkip
  LD A,(IX+$02)
  CP $40
  JP C,TrapEffectSkip
  POP AF
  JP PlayEffect
TrapEffectSkip:
  POP AF
  RET

; One pass of the trap or pickup at IX: path, animation, deadly touch, triggers
;
; The pickups ($21, $29, $2D) go to UpdatePickup with their sprite (Sprites 27,
; 25, 26). A paused trap (+0 bit 1) skips to the trigger test. Otherwise the
; path is read: effects played, a loop point followed (and there a one-shot
; trap is retired, a waiting trap switched to its second path by
; SwitchTrapPath, behaviour $14 marked to be freed at the next end), a step
; applied: x += the x step (a trap leaving 0-$E8 is freed), y += the y step
; (one leaving the view is freed), the step count moved on. Then AnimateTrap.
;
; A deadly trap (+0 bit 6) with a sprite: with bit 7 and the detonator's blast
; at phase 10 or more, the blast test ($A41C, not executed in any recording:
; effect 5, the phase set to 9); then every live enemy it overlaps is killed
; (KillEnemy, 111 times), and Rick, unless already dying ($9B9C), dies ($93D0
; at $A475) when it overlaps him ($8D53).
;
; Then the trap's own trigger boxes (TestTriggerBoxes with the map entry): see
; $A478.
;
; Evidence: 148 725 runs in 61 builds (c1 616), all from $867A; Rick's overlap
; test 83 559 runs (the CALL C at $A475, which the POKE file's trap immunity
; patches); behaviour $0C removed by its trigger 432 times ($A4C0), behaviour
; $1C on release 9 ($A4A7).
;
; Witness: L1 345924 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
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
; rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s
; x5, sec-l5-s3, sec-l5-s5).
UpdateTrap:
  LD A,(IX+$00)
  AND $3F
  LD HL,Sprites+27*128
  CP $21
  JP Z,UpdatePickup
  LD HL,Sprites+25*128
  CP $29
  JP Z,UpdatePickup
  LD HL,Sprites+26*128
  CP $2D
  JP Z,UpdatePickup
  BIT 1,A
  JP NZ,TrapTriggers
  LD L,(IX+$0F)
  LD H,(IX+$10)
TrapPathLoop:
  LD A,(HL)
  CP $FF
  JP NZ,TrapPathStep
  INC HL
  LD A,(HL)
  CALL TrapEffect         ; $FF n: effect n
  INC HL
  LD (IX+$0F),L
  LD (IX+$10),H
  JP TrapPathLoop
TrapPathStep:
  AND A
  JP NZ,TrapPathMove
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (IX+$0F),L
  LD (IX+$10),H
  LD A,(IX+$06)           ; the loop point: a one-shot trap ends here
  BIT 5,A
  JP NZ,RetireObject
  BIT 4,A                 ; not waiting: go on
  JP Z,TrapPathLoop
  BIT 3,A
  JP Z,TrapPathClearWait
  RES 3,(IX+$06)
  JP TrapPathSwitch
TrapPathClearWait:
  RES 4,(IX+$06)
TrapPathSwitch:
  LD A,(IX+$00)           ; behaviour $14: freed at the next end
  AND $1C
  CP $14
  JP NZ,SwitchTrapPath
  SET 5,(IX+$06)
  JP SwitchTrapPath
TrapPathMove:
  INC HL                  ; the step byte: x step in the high nibble
  LD A,(HL)
  SRA A
  SRA A
  SRA A
  SRA A
  CP $07
  JP NZ,TrapStoreDx
  INC A
TrapStoreDx:
  LD (IX+$16),A
  AND A
  JP P,TrapMoveRight
  ADD A,(IX+$01)
  JP C,TrapStoreX
  JP FreeObject           ; x stepped left past 0: freed

; TrapUnreachableJump
TrapUnreachableJump:
  DEFB $C3,$9F,$A3        ; JP $A39F after a JP: no path reaches it

; TrapMoveRight
;
; Used by the routine at UpdateTrap.
TrapMoveRight:
  ADD A,(IX+$01)
  JP C,FreeObject
  CP $E9
  JP NC,FreeObject
; This entry point is used by the routine at UpdateTrap.
TrapStoreX:
  LD (IX+$01),A
  LD B,$00
  LD A,(HL)
  AND $0F
  BIT 3,A
  JP Z,TrapDyPositive
  DEC B
  OR $F0
TrapDyPositive:
  CP $07
  JP NZ,TrapStoreDy
  INC A
TrapStoreDy:
  LD C,A
  LD (IX+$17),A
  EX DE,HL
  LD L,(IX+$02)
  LD H,(IX+$03)
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  CALL IsOffView
  JP NZ,FreeObject
  EX DE,HL
  DEC HL
  LD A,(HL)
  INC (IX+$0E)
  CP (IX+$0E)
  JP Z,TrapNextStep
  JP NC,TrapAnimate
TrapNextStep:
  LD (IX+$0E),$00
  INC HL
  INC HL
  LD (IX+$0F),L
  LD (IX+$10),H
TrapAnimate:
  CALL AnimateTrap
  BIT 6,(IX+$00)
  JP Z,TrapTriggers
  LD A,(IX+$04)
  OR (IX+$05)
  JP Z,TrapTriggers
  LD A,(DetonatorFuse)
  CP $0A
  JP C,TrapHitEnemies
  BIT 7,(IX+$00)
  JP Z,TrapHitEnemies
  LD HL,(DetonatorY)      ; the detonator's box: its y, x + 8, 16 x 8
  LD A,(DetonatorX)
  ADD A,$08
  LD E,A
  LD BC,$1008
  CALL BoxesOverlap
  JP NC,TrapHitEnemies
TrapBlastHit:
  LD A,$05                ; effect 5, $9BC6 = 9 (not executed in any recording)
  CALL PlayEffect
  LD A,$09
  LD (DetonatorFuse),A
TrapHitEnemies:
  PUSH IX                 ; the trap's box: y, x, width, height
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD E,(IX+$01)
  LD C,(IX+$07)
  LD B,(IX+$08)
  LD IX,SetupIm2+$0006

; TrapHitEnemiesLoop
TrapHitEnemiesLoop:
  LD A,(IX+$00)
  AND A
  JP Z,TrapHitEnemiesNext
  CP $FF
  JP Z,TrapHitRickTest
  LD A,(IX+$14)
  AND A
  JP NZ,TrapHitEnemiesNext
  PUSH BC                 ; a live enemy overlapping the trap dies
  PUSH DE
  PUSH HL
  CALL TouchesObject
  CALL C,KillEnemy
  POP HL
  POP DE
  POP BC
TrapHitEnemiesNext:
  PUSH BC
  LD BC,$0017
  ADD IX,BC
  POP BC
  JP TrapHitEnemiesLoop
TrapHitRickTest:
  LD A,(RickDying)
  AND A
  JP Z,TrapHitRick
  POP IX
  JP TrapTriggers
TrapHitRick:
  CALL TouchesRick
  POP IX
  CALL C,KillRick         ; Rick touches a deadly trap: he dies

; TrapTriggers
;
; Used by the routines at UpdateTrap, TrapMoveRight and TrapHitEnemiesLoop.
TrapTriggers:
  LD A,(IX+$06)           ; flags +6 bit 6: no trigger test; bit 4 with kind
                          ; bit 5: none either
  BIT 6,A
  RET NZ
  BIT 4,(IX+$06)
  JP Z,TrapTestBoxes
  BIT 5,(IX+$00)
  RET NZ
TrapTestBoxes:
  PUSH IX                 ; BC = this record, so the trap list skips it
  POP BC
  PUSH BC
  LD L,(IX+$0C)
  LD H,(IX+$0D)
  PUSH HL
  POP IX
  CALL TestTriggerBoxes
  POP IX
  JP C,TrapTriggered

; TrapNoTrigger
TrapNoTrigger:
  LD A,(IX+$00)           ; behaviour $1C: the trap lives only while its box is
                          ; held
  AND $1C
  CP $1C
  RET NZ
  JP RetireObject
; This entry point is used by the routine at TrapTriggers.
TrapTriggered:
  LD A,(IX+$00)           ; behaviour 0: pause or resume the path
  AND $1C
  JP NZ,TrapTriggerKind
  LD A,(IX+$00)
  XOR $02
  LD (IX+$00),A
  RET
TrapTriggerKind:
  CP $1C                  ; $0C: removed; bit 3 set: stop testing, switch now;
                          ; bit 3 clear: wait for the path's end
  RET Z
  CP $0C
  JP Z,RetireObject
  BIT 3,A
  JP Z,ArmTrapWait
  SET 6,(IX+$06)
  BIT 4,A
  JP Z,SwitchTrapPath
  SET 5,(IX+$06)

; Swap the trap's path, animation and kind for the second ones
;
; Swaps +$0F/+$10 with +$11/+$12, +$0A/+$0B with +$13/+$14, +0 with +$15, and
; restarts the frame delay and the step count: a trap that was waiting starts
; its second movement (a falling block falls, a door opens; the kinds per level
; to be named with the level data).
;
; Entered from UpdateTrap at a waiting trap's loop point ($A367, 135 runs in 22
; builds) and from the trigger test ($A4D1, 25 runs in 19 builds). Witness: 184
; runs in 42 builds.
;
; Witness: L1 370 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-10000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-20000-poke, rzx-l5-full, load-l4, sec-l2-s7).
SwitchTrapPath:
  LD E,(IX+$11)
  LD D,(IX+$12)
  LD L,(IX+$0F)
  LD H,(IX+$10)
  LD (IX+$11),L
  LD (IX+$12),H
  LD (IX+$0F),E
  LD (IX+$10),D
  LD E,(IX+$13)
  LD D,(IX+$14)
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (IX+$13),L
  LD (IX+$14),H
  LD (IX+$0A),E
  LD (IX+$0B),D
  LD (IX+$09),$00
  LD (IX+$0E),$00
  LD C,(IX+$00)
  LD B,(IX+$15)
  LD (IX+$00),B
  LD (IX+$15),C
  RET

; A trigger with behaviour bit 3 clear: switch at the path's end
;
; Sets +6 bit 4 (waiting); with kind bit 5, bit 3 too (one more loop before the
; switch, cleared by $A35C). Witness: 361 runs in 22 builds.
;
; Witness: L1 722 (rzx-l1-00000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke,
; rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l4-04000-poke,
; rzx-l5-00000-poke, rzx-l5-16000-poke, rzx-l5-full).
ArmTrapWait:
  SET 4,(IX+$06)
  BIT 5,(IX+$00)
  RET Z
  SET 3,(IX+$06)
  RET

; A pickup: a treasure ($21), ammunition ($29) or detonators ($2D)
;
; HL: its sprite. The record is set to 24 x 21 pixels. While Rick lives ($9B9C
; = 0) and overlaps it ($8DDF with Rick's x $9BAC + 4, y $9BAD, 16 x 21): a
; treasure gives 500 points (the digits at $7EFF through $7ED3, effect 7);
; ammunition sets the bullets $8B3C to 6 ($79D1 redraws them); detonators set
; $8B3D to 6 ($79DF); effect 6 for both; the pickup is retired.
;
; Not taken: an ammunition or detonator box hit by the bullet ($A5E4) or by the
; detonator's blast at phase 4-9 ($A5F7) bursts (effect 5, ten frames from the
; table $93C0 by the burst counter +$0E, PickupBurst, then retired): none of
; these ran in any recording.
;
; Evidence: 20 424 runs in 47 builds (from $A301 3685, $A309 1820, $A311 2825;
; c1 none); taken: a treasure 28 times ($A58D, 18 builds), ammunition 13 ($A59B
; 25 less $A5B0 12), detonators 12 ($A5B0, 11 builds).
;
; Witness: L1 48852 (cheats, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke,
; rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, load-l2, load-l5,
; sec-l2-s7, sec-l2-s10, sec-l2-s11, sec-l3-s5, sec-l3-s9, sec-l4-s2,
; sec-l5-s5).
UpdatePickup:
  LD (IX+$00),A
  LD (IX+$07),$18
  LD (IX+$08),$15
  LD A,(IX+$0E)
  AND A
  JP Z,PickupTouch
PickupBurst:
  DEC A                   ; burst counter -1, retired at 0, the sprite from
                          ; $93C0 (not executed in any recording)
  JP Z,RetireObject
  LD (IX+$0E),A
  AND $FE
  LD C,A
  LD B,$00
  LD HL,ExplosionFrames
  ADD HL,BC
  LD A,(HL)
  LD (IX+$04),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  RET
PickupTouch:
  LD A,(RickDying)
  AND A
  JP NZ,PickupShotTest
  LD (IX+$07),$18
  LD (IX+$08),$15
  LD (IX+$04),L           ; the sprite
  LD (IX+$05),H
  LD (IX+$07),$18
  LD (IX+$08),$15
  LD HL,(RickY)           ; Rick's box
  LD A,(RickX)
  ADD A,$04
  LD E,A
  LD BC,$1015
  CALL BoxesOverlap
  JP NC,PickupShotTest
  LD A,(IX+$00)
  AND $3C
  CP $20
  JP NZ,PickupNotTreasure
  LD A,$07                ; a treasure: effect 7, 500 points
  CALL PlayEffect
  LD HL,Points500
  CALL AddScore
  JP RetireObject
PickupNotTreasure:
  CP $28
  JP NZ,PickupDetonators
  LD A,$06
  CALL PlayEffect
  LD A,$06
  LD (Ammunition),A
  CALL DrawAmmo
  JP RetireObject
PickupDetonators:
  LD A,$06
  CALL PlayEffect
  LD A,$06
  LD (Detonators),A
  CALL DrawDetonators
  JP RetireObject
PickupShotTest:
  LD A,(IX+$00)           ; a treasure is never shot
  AND $3C
  CP $20
  RET Z
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD E,(IX+$01)
  LD C,(IX+$07)
  LD B,(IX+$08)
  LD A,(BulletRecord)
  AND A
  JP Z,PickupBlastTest
  CALL BulletHits
  JP NC,PickupBlastTest
PickupShot:
  XOR A                   ; BulletSpent = $FF, then the burst (not executed in
                          ; any recording)
  DEC A
  LD (BulletSpent),A
  JP PickupBurstStart
PickupBlastTest:
  LD A,(DetonatorRecord)
  AND A
  RET Z
  CP $0A
  RET NC
  CP $04
  RET C
PickupBlast:
  CALL BlastHits          ; $8CAE: the blast overlaps (not executed in any
                          ; recording)
  RET NC
PickupBurstStart:
  LD A,$05                ; effect 5, +$0E = 10
  CALL PlayEffect
  LD A,$0A
  LD (IX+$0E),A
  JP PickupBurst

; Advance the trap's animation script and set its sprite
;
; +9 counts the passes a frame stays. The script (+$0A/+$0B) is read: $FD n
; plays effect n (TrapEffect), $FF and an address jumps, $80+n then a frame
; shows the frame n passes, a byte below $80 is a frame. Frame $7F hides the
; trap (+4/+5 = 0); otherwise SpriteFrameMap[frame - 1] gives the sprite number
; (bit 7: mirrored, +6 bit 7; $7F: no sprite) and the sprite address Sprites +
; n x 128.
;
; A script address below $100 ($A61B: the frame is the low byte itself) is not
; executed in any recording. Witness: 127 532 runs in 60 builds (all from
; $A3E8); a new frame 76 384 times.
;
; Witness: L1 295451 (cheats, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke,
; rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke,
; rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s11, sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
AnimateTrap:
  LD A,(IX+$09)
  AND A
  JP Z,AnimTrapScript
  DEC A
  LD (IX+$09),A
  RET NZ
AnimTrapScript:
  LD A,(IX+$0B)
  AND A
  JP NZ,AnimTrapRead
AnimTrapFixedFrame:
  LD A,(IX+$0A)           ; no script: +$0A is the frame (not executed in any
                          ; recording)
  JP AnimTrapLookup
AnimTrapRead:
  LD H,A
  LD L,(IX+$0A)
AnimTrapLoop:
  LD A,(HL)
  AND A
  JP P,AnimTrapFrame
  CP $FD                  ; $FD n: effect n
  JP NZ,AnimTrapJumpTest
  INC HL
  LD A,(HL)
  CALL TrapEffect
  INC HL
  JP AnimTrapLoop
AnimTrapJumpTest:
  CP $FF
  JP NZ,AnimTrapDelay
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP AnimTrapLoop
AnimTrapDelay:
  AND $7F                 ; $80+n: n passes, then the frame
  LD (IX+$09),A
  INC HL
  LD A,(HL)
AnimTrapFrame:
  INC HL
  LD (IX+$0A),L
  LD (IX+$0B),H
  AND $7F
  CP $7F
  JP NZ,AnimTrapLookup
  LD (IX+$04),$00
  LD (IX+$05),$00
  RET
AnimTrapLookup:
  LD C,A
  LD B,$00
  LD A,(IX+$06)
  AND $7F
  LD (IX+$06),A
  LD HL,SpriteFrameMap-1     ; the frame map, frames counted from 1
  ADD HL,BC
  LD A,(HL)
  CP $7F
  JP NZ,AnimTrapSprite
  LD HL,$0000
  JP AnimTrapStore
AnimTrapSprite:
  LD H,A
  AND A
  JP P,AnimTrapAddress
  AND $7F
  LD H,A
  LD A,(IX+$06)
  OR $80
  LD (IX+$06),A
AnimTrapAddress:
  LD L,$00                ; Sprites + number x 128
  SRL H
  RR L
  LD BC,Sprites
  ADD HL,BC
AnimTrapStore:
  LD (IX+$04),L
  LD (IX+$05),H
  RET
