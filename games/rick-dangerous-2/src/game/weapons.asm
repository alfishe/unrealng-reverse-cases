; --------------------------------------------------------------------------------------------------------------------
; weapons.asm: The gun and its bullet, the detonator and its blast, the punch
;
; Rick's weapons are three records beside his own: the bullet BulletRecord ($9BB4) and the detonator DetonatorRecord
; ($9BBD), 9 bytes each like RickRecord (+0 active, +1 x, +2/+3 y, +4/+5 the sprite, +6 the mirror bit), and the
; punch, which has no record: PunchX / PunchY and the 10-pass PunchTimer, read by the enemy test $8C6C. The keys with
; fire held (UpdateRick, RickFireActions): up shoots (FireBullet, one bullet at a time, released between shots), down
; drops a detonator (DropDetonator, one at a time), left or right punches.
;
; The detonator is thrown with Rick's sideways keys (-2, 0 or +2 pixels a pass), falls under gravity, slides with
; friction, lands on platforms and blocks, and burns 64 passes: 54 of physics, then 10 of blast (BurnFuse). During the
; blast passes 4-9 a 32 x 21 box round it kills Rick; a deadly cell sets it off at once.
; --------------------------------------------------------------------------------------------------------------------

  ORG $91B0

; Move the bullet 8 pixels a pass; it ends on a solid cell or the view's edge
;
; IX = BulletRecord (the object step $86B7, while BulletRecord +0 is set).
; Reads the cell flags at (x+4, y+4) through $8D0C: bit 1 (solid) ends the
; bullet (+0 = 0). Else x += BulletDx (+8 or -8): going left, x below 0 ends
; it; going right, a carry or x >= $F8 ends it. Hitting enemies and traps is
; tested elsewhere ($8BF3, $A528, $A69F read BulletRecord).
;
; Ran 755 times in 43 builds (c1 62, each control recording 1).
;
; Witness: L1 1479 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).
MoveBullet:
  LD A,(BulletX)
  ADD A,$04
  LD E,A
  LD HL,(BulletY)
  INC HL
  INC HL
  INC HL
  INC HL
  CALL ProbePoint
  AND $02
  JP Z,BulletStep
  XOR A
  LD (BulletRecord),A
  RET
BulletStep:
  LD A,(BulletX)          ; x += dx (dx's sign gives the direction)
  LD C,A
  LD A,(BulletDx)
  AND A
  JP P,BulletRight
  ADD A,C
  JP C,BulletStore
BulletGone:
  XOR A                   ; the bullet ends
  LD (BulletRecord),A
  RET
BulletRight:
  ADD A,C
  JP C,BulletGone
  CP $F8
  JP NC,BulletGone
BulletStore:
  LD (BulletX),A
  RET

; The detonator's pass: fall, land, slide, then burn the fuse
;
; IX = DetonatorRecord (the object step $86C5, while +0 is set). While
; DetonatorFuse >= 11: gravity adds 0.5 to DetonatorDy (at most 8), the 24-bit
; y (DetonatorY, DetonatorYFrac) moves by it, and $8E1C tests the detonator's
; cells and platforms. Deadly: DetonatorTouchDeadly. On a platform (bit 6): y =
; PlatformTop - 16, a second cell test (C = $80) carrying PlatformDx. Landed on
; a floor (bits 1 or 2) while falling: DetonatorOnFloor. In the air:
; DetonatorSlide. Always ends in BurnFuse.
;
; Ran 3401 times in 34 builds: 64 passes per detonator (c1 64, each control
; recording 64, the RZX pieces 64 or 128).
;
; Witness: L1 6866 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
UpdateDetonator:
  LD A,(DetonatorFuse)
  CP $0B
  JP C,BurnFuse
  LD HL,(DetonatorDy)
  LD B,$FF
  LD DE,$0080
  ADD HL,DE
  LD A,H
  AND A
  JP M,DetonatorGravityDone
  INC B
  CP $07
  JP C,DetonatorGravityDone
  LD HL,$0800
DetonatorGravityDone:
  LD (DetonatorDy),HL     ; DetonatorDy clamped to 8.0; B = its sign for the
                          ; 24-bit add
  LD C,H
  LD A,(DetonatorYFrac)
  LD E,A
  LD D,(IX+$02)
  LD A,(IX+$03)
  ADD HL,DE
  ADC A,B
  LD C,L
  LD L,H
  LD H,A
  PUSH HL
  PUSH BC
  LD E,(IX+$01)
  CALL ProbeGround
  POP BC
  POP HL
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,DetonatorTouchDeadly
  BIT 6,A
  JP Z,DetonatorNoPlatform
  LD HL,(PlatformTop)
  LD BC,-16
  ADD HL,BC
  LD (DetonatorY),HL
  LD E,(IX+$01)
  LD A,(PlatformDx)
  LD C,$80
  PUSH AF
  CALL ProbeGround
  POP AF
  LD HL,(DetonatorY)
  LD (PlatformDx),A
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,DetonatorTouchDeadly
  AND $02
  JP NZ,DetonatorHitCeiling
  JP DetonatorStopFall
DetonatorNoPlatform:
  AND $06
  JP NZ,DetonatorLanded
  LD A,C
  LD (DetonatorYFrac),A
  LD (DetonatorY),HL
  JP DetonatorSlide
DetonatorLanded:
  LD A,(DetonatorDy+$0001) ; on a floor: rising goes to DetonatorHitCeiling
                           ; (never ran), falling to DetonatorOnFloor
  AND A
  JP P,DetonatorOnFloor

; a rising detonator meets a solid cell, put it under the cell
;
; y = (y + 8) AND $F8, then on to DetonatorStoreY. Also the branch for a
; detonator on a platform whose cells are solid ($925B). Not executed in any
; recording: the detonator is never thrown upwards (DropDetonator starts it at
; +1.0). Kept as bytes for the reason given at BonusRunOut.
;
; Witness: L1 0 ().
DetonatorHitCeiling:
  LD DE,$0008             ; LD DE,$0008
  ADD HL,DE
  LD A,L
  AND $F8
  LD L,A
  JP DetonatorStoreY      ; JP DetonatorStoreY

; Put the falling detonator on the floor's cell edge; a special surface goes to
; DetonatorBounce
;
; y = (y - 1) AND $F8 (low byte), stored in DetonatorY. Ran 2632 times in 32
; builds.
;
; Witness: L1 5318 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke,
; rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48).
DetonatorOnFloor:
  DEC HL
  LD A,L
  AND $F8
  LD L,A
; This entry point is used by the routine at DetonatorHitCeiling.
DetonatorStoreY:
  LD (DetonatorY),HL
  LD A,(CollisionFlags)
  AND $01
  JP Z,DetonatorStopFall

; a detonator on a special surface, level 3 bounces it, level 5 launches it
;
; Level 3: when DetonatorDy >= 2.0 it becomes -DetonatorDy + $5F/256 (a bounce
; losing a little), kept unless it is weaker than -3.0 (high byte >= $FD), then
; to DetonatorSlide; else it stops (DetonatorStopFall). Level 5: DetonatorDy =
; -2175/256 (the launch pad's kick). Other levels: it stops. Not executed in
; any recording (no detonator fell on a special surface). Kept as bytes for the
; reason given at BonusRunOut.
;
; Witness: L1 0 ().
DetonatorBounce:
  LD A,(Level)            ; LD A,($7EF1): the level
  CP $03
  JP NZ,DetonatorLaunchPad ; JP NZ,DetonatorLaunchPad
  LD HL,(DetonatorDy)     ; LD HL,(DetonatorDy)
  LD A,H
  CP $02
  JP C,DetonatorStopFall  ; JP C,DetonatorStopFall: slower than 2.0, no bounce
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A                  ; LD L,A: HL = -DetonatorDy - 1
  LD DE,$0060
  ADD HL,DE
  LD A,H
  CP $FD
  JP NC,DetonatorStopFall ; JP NC,DetonatorStopFall: weaker than -3.0
  LD (DetonatorDy),HL     ; LD (DetonatorDy),HL
  JP DetonatorSlide       ; JP DetonatorSlide
DetonatorLaunchPad:
  CP $05                  ; CP $05: level 5
  JP NZ,DetonatorStopFall ; JP NZ,DetonatorStopFall
  LD HL,$F781             ; LD HL,-2175
  JP DetonatorStoreDy     ; JP DetonatorStoreDy

; The detonator rests: DetonatorDy = 1.0
;
; Ran 2726 times in 34 builds.
;
; Witness: L1 5506 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
DetonatorStopFall:
  LD HL,$0100
; This entry point is used by the routine at DetonatorBounce.
DetonatorStoreDy:
  LD (DetonatorDy),HL

; Friction on the sideways speed, then move x and test the cells
;
; BC = 8, DE = -8: the friction (1/32 pixel a pass every pass); a special
; surface goes to DetonatorSurfaceFriction first. Ran 2857 times in 34 builds.
;
; Witness: L1 5768 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
DetonatorSlide:
  LD BC,$0008
  LD DE,-8
  LD HL,(DetonatorDx)
  LD A,(CollisionFlags)
  AND $01
  JP Z,DetonatorFriction

; friction on a special surface, level 1 stops, level 2 (ice) none, level 4
; (mud) double
;
; Level 1: DetonatorStop. Level 2: DetonatorKeepDx (no friction). Level 4:
; friction 16. Others: 8. Not executed in any recording. Kept as bytes for the
; reason given at BonusRunOut.
;
; Witness: L1 0 ().
DetonatorSurfaceFriction:
  LD A,(Level)            ; LD A,($7EF1): the level
  CP $01
  JP Z,DetonatorStop      ; JP Z,DetonatorStop
  CP $02
  JP Z,DetonatorKeepDx    ; JP Z,DetonatorKeepDx
  CP $04
  JP NZ,DetonatorFriction ; JP NZ,DetonatorFriction
  LD BC,$0010
  LD DE,$FFF0             ; LD DE,-16

; Bring DetonatorDx towards 0
;
; Moving left (negative): add 8; a carry means it reached 0
; (DetonatorStopLeft). Ran 2857 times in 34 builds.
;
; Witness: L1 5768 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
DetonatorFriction:
  LD HL,(DetonatorDx)
  LD A,H
  AND A
  JP P,DetonatorSlowRight
  ADD HL,BC
  JP NC,DetonatorMoveX

; a detonator moving left reached speed 0
;
; JP DetonatorStop ($C3 $05 $93). Not executed in any recording: a detonator
; thrown left (-2.0) needs 64 passes to stop and its fuse lasts 53 ($9B7D ran 6
; times). Kept as bytes for the reason given at BonusRunOut.
;
; Witness: L1 0 ().
DetonatorStopLeft:
  JP DetonatorStop

; Moving right or still: subtract 8, at 0 or below stop
;
; Ran 2533 times in 32 builds; DetonatorStop 1188 times (mostly a detonator
; dropped standing still, speed 0).
;
; Witness: L1 5120 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-12000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1,
; c48).
DetonatorSlowRight:
  ADD HL,DE
  JP C,DetonatorMoveX
; This entry point is used by the routines at DetonatorSurfaceFriction and
; DetonatorStopLeft.
DetonatorStop:
  LD HL,$0000             ; DetonatorDx = 0
; This entry point is used by the routine at DetonatorFriction.
DetonatorMoveX:
  LD (DetonatorDx),HL     ; x (DetonatorX, DetonatorXFrac) += DetonatorDx, plus
                          ; PlatformDx in whole pixels; test with C = $FF
; This entry point is used by the routine at DetonatorSurfaceFriction.
DetonatorKeepDx:
  LD A,(DetonatorX)       ; level 2's ice: the speed unchanged
  LD D,A
  LD A,(DetonatorXFrac)
  LD E,A
  ADD HL,DE
  LD A,(PlatformDx)
  ADD A,H
  LD H,A
  PUSH HL
  LD E,H
  LD HL,(DetonatorY)
  LD C,$FF
  CALL ProbeGround
  POP HL
  LD A,(CollisionFlags)
  BIT 5,A
  JP NZ,DetonatorTouchDeadly
  AND $02
  JP Z,DetonatorStoreX
  LD A,(PlatformDx)       ; solid: snap x to the cell edge on the side it came
                          ; from
  LD C,A
  LD A,(DetonatorDx+$0001)
  ADD A,C
  AND A
  LD L,$00
  JP P,DetonatorSnapRight
  LD A,H
  ADD A,$08
  JP DetonatorAlignX
DetonatorSnapRight:
  LD A,H
DetonatorAlignX:
  AND $F8
  LD H,A
DetonatorStoreX:
  LD A,L
  LD (DetonatorXFrac),A
  LD A,H
  LD (DetonatorX),A

; Count the fuse down: the burning and blast sprites, the sounds, the blast
; against Rick
;
; DEC IX+9 (DetonatorFuse): at 0 the detonator ends (+0 = 0). Fuse 10 and up:
; the sprite is 18 while >= 20, 19 below (it flashes before the blast), effect
; 2 ($7A97) every 4 passes, effect 5 (the bang) at 10. Fuse 1-9: the blast
; sprite ExplosionFrames[fuse AND $FE] (24, 23, 22, 21, 20 as the fuse falls,
; two passes each). Fuse 4-9: the box test $8D53 of a box 32 wide (from x-4, at
; least 0) and 21 high at the detonator's y against Rick: a hit kills him
; (KillRick, from $93B4).
;
; Ran 3397 times in 34 builds; the bang (effect 5) 56 times; KillRick from the
; blast 8 times ($93B4 in the caller list of $93D0, c1 and the control
; recordings).
;
; Witness: L1 6858 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke,
; rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke,
; rzx-l5-22000-poke, rzx-l5-full, c1, c48).
BurnFuse:
  DEC (IX+$09)
  JP NZ,FuseFrame
  LD (IX+$00),$00
  RET
FuseFrame:
  LD A,(IX+$09)           ; fuse 1-9: a blast frame
  CP $0A
  JP NC,FuseBurning
  AND $FE
  LD C,A
  LD B,$00
  LD HL,ExplosionFrames
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP FuseStoreSprite
FuseBurning:
  JP NZ,FuseHiss          ; fuse >= 10
  PUSH AF
  LD A,$05
  CALL PlayEffect
  POP AF
FuseHiss:
  PUSH AF                 ; effect 2 every 4 passes
  AND $03
  JP NZ,FuseSprite
  LD A,$02
  CALL PlayEffect
FuseSprite:
  POP AF                  ; sprite 18 while the fuse >= 20, else 19
  LD HL,Sprites+18*128
  CP $14
  JP NC,FuseStoreSprite
  LD HL,Sprites+19*128
FuseStoreSprite:
  LD (DetonatorSprite),HL
  LD A,(DetonatorFuse)
  CP $04
  RET C
  CP $0A
  RET NC
  LD HL,(DetonatorY)
  LD A,(DetonatorX)
  SUB $04
  JP NC,BlastTestRick
  XOR A
BlastTestRick:
  LD E,A                  ; the blast box: x-4 (not below 0), 32 x 21
  LD BC,$1520
  CALL TouchesRick
  JP C,KillRick
  RET
; This entry point is used by the routines at UpdateDetonator and
; DetonatorSlowRight.
DetonatorTouchDeadly:
  LD A,$0A                ; a deadly cell: fuse = 10, the blast starts
                          ; (rzx-l5-12000-poke 1, rzx-l5-full 3)
  LD (DetonatorFuse),A
  JP FuseFrame

; The blast's sprites by fuse AND $FE: sprites 20-24 ($CC6D-$CE6D)
;
; Read by BurnFuse.
ExplosionFrames:
  INCBIN "res/tables/explosion-frames.bin",$0000,10

; The detonator's sideways speed, 8.8 pixels a pass (-2.0, 0 or +2.0 when
; thrown)
;
; Written by DropDetonator and the friction (DetonatorSlide ...); read by
; UpdateDetonator and PickRickSprite ($9A25: Rick shows the throw sprite while
; it is not 0).
DetonatorDx:
  DEFW $0000

; The detonator's vertical speed, 8.8 pixels a pass, down positive (+1.0 when
; dropped, gravity 0.5)
;
; Written by DropDetonator, UpdateDetonator and DetonatorStopFall.
DetonatorDy:
  DEFW $0000

; The fraction of DetonatorX
DetonatorXFrac:
  DEFB $00

; The fraction of DetonatorY
DetonatorYFrac:
  DEFB $00

  ORG $9593

; Fire the gun: one bullet less (none left: no shot), the shot sound, the
; bullet from Rick's chest
;
; Unless $8066 is set (no write to it in any recording: a cheat flag), the
; ammunition $8B3C is decremented and the HUD redrawn ($79D1); with none left,
; nothing happens. Effect 4 ($7A97). BulletRecord +0 = 1, BulletY = RickY + 8,
; BulletX = RickX; C's two key bits (active low) pick the direction: left (bit
; 1 low) or, with neither, the facing left: RickFacing = $80, BulletDx = -8;
; right: RickFacing = 0, BulletDx = +8. FireLatch = $FF (the fire key must be
; released before the next shot).
;
; Callers: ShootBullet ($9B21) 73, UpdateRide ($958F) 15. 88 shots in 43
; builds.
;
; Witness: L1 175 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke,
; rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).
FireBullet:
  LD A,(CheatInfinite)
  AND A
  JP NZ,FireBulletLaunch
  LD A,(Ammunition)
  AND A
  RET Z
  DEC A
  LD (Ammunition),A
  CALL DrawAmmo
FireBulletLaunch:
  LD A,$04
  CALL PlayEffect
  LD A,$01
  LD (BulletRecord),A
  LD HL,(RickY)
  LD DE,$0008
  ADD HL,DE
  LD (BulletY),HL
  LD A,C
  AND $03
  CP $01
  JP Z,FireLeft
  CP $02
  JP Z,FireRight
  LD A,(RickFacing)
  AND A
  JP M,FireLeft
FireRight:
  XOR A
  LD (RickFacing),A
  LD A,$08
  JP FireStoreDx
FireLeft:
  LD A,$80
  LD (RickFacing),A
  LD A,$F8
FireStoreDx:
  LD (BulletDx),A         ; BulletDx = +8 or -8: bit 7 also mirrors the
                          ; bullet's sprite
  LD A,(RickX)
  LD (BulletX),A
  LD A,$FF
  LD (FireLatch),A
  RET

  ORG $9AE8

; Fire with up: the shooting pose, and a bullet when the gun is free
;
; RickStep = $FF, ShootPose = $FF; unless FireLatch is set or a bullet flies,
; ShootBullet. Then RickActionDone.
;
; Ran 161 times in 39 builds.
;
; Witness: L1 304 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).
RickShootUp:
  LD C,A
  LD A,$FF
  LD (RickStep),A
  LD HL,Sprites+7*128
  LD (RickSprite),HL
  LD A,$FF
  LD (ShootPose),A
  LD A,(FireLatch)
  AND A
  JP NZ,RickActionDone
  LD A,(BulletRecord)
  AND A
  JP Z,ShootBullet

  ORG $9B21

; Call FireBullet with C = the keys, then RickActionDone
;
; Ran 73 times in 39 builds.
;
; Witness: L1 145 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke,
; rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).
ShootBullet:
  CALL FireBullet
  JP RickActionDone

; Fire with down: drop or throw a detonator when none burns
;
; DetonatorPose = $FF. With a detonator already out, nothing more. Unless $8066
; (the cheat flag) is set, one detonator less ($8B3D, none: nothing) and the
; HUD ($79DF). DetonatorX = RickX, DetonatorY = RickY + 5, DetonatorRecord +0 =
; 1, DetonatorFuse = 64, DetonatorDy = +1.0, DetonatorDx by the sideways keys:
; none 0, left -2.0, right +2.0.
;
; Ran 233 times in 33 builds; 56 detonators placed (DetonatorPlace), 24 dropped
; standing, 6 thrown left, 26 right.
;
; Witness: L1 471 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke,
; rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke,
; rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke,
; rzx-l5-full, c1, c48).
DropDetonator:
  LD A,$FF
  LD (DetonatorPose),A
  LD A,(DetonatorRecord)
  AND A
  JP NZ,RickActionDone
  LD A,(CheatInfinite)
  AND A
  JP NZ,DetonatorPlace
  LD A,(Detonators)
  AND A
  JP Z,RickActionDone
  DEC A
  LD (Detonators),A
  CALL DrawDetonators
DetonatorPlace:
  LD A,(RickX)
  LD (DetonatorX),A
  LD HL,(RickY)
  LD BC,$0005
  ADD HL,BC
  LD (DetonatorY),HL
  LD A,$01
  LD (DetonatorRecord),A
  LD A,$40
  LD (DetonatorFuse),A
  LD HL,$0100
  LD (DetonatorDy),HL
  LD A,(Controls)
  AND $03
  CP $03
  JP NZ,ThrowLeftCheck
  LD HL,$0000
  JP ThrowStoreDx
ThrowLeftCheck:
  CP $01
  JP NZ,ThrowRight
  LD HL,-2*256
  JP ThrowStoreDx
ThrowRight:
  LD HL,$0200
ThrowStoreDx:
  LD (DetonatorDx),HL
  JP RickActionDone
