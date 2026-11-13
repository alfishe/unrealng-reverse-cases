; --------------------------------------------------------------------------------------------------------------------
; rick.asm: Rick's bullet and dynamite as objects
;
; Rick's own moves (`$F851`), his firing (`$FA39`-`$FA83`), the stick (`$F9DE`-`$FA1A`) and the dynamite drop
; (`$FA9C`-`$FAB7`) lie in the next fragment; this one holds the bullet and the dynamite once they are out, and the
; variables the enemies and traps test.
;
; Rick is object 1 at $EAAC. RickHandler (kind 1, the pointer at $EC49) runs once per game frame: MoveRick reads
;
; the input byte $A14D (active low: bit 0 right, bit 1 left, bit 2 down, bit 3 up, bit 4 fire) and the probes of
;
; the objects module, then ChooseRickFrame picks the sprite frame. Fire with left or right pokes the stick, fire
;
; with up shoots, fire with down drops a dynamite stick; up jumps, down crawls; up or down on a ladder climbs.
;
; Walking off the left or right edge of the playfield (X < 2 or X >= $E8) flags a zone change ($FD61, $FD62).
; --------------------------------------------------------------------------------------------------------------------

  ORG $EC77

; Kind 3: the dynamite's fuse and blast
;
; DynFuse $ECED counts down by 1 a pass from the value the drop `$FAB1` gives
; it. While 20 or more the stick of dynamite shows FuseFrames $ECF2, mirrored
; every other pass; at 20 effect 2 (the bang, `$EC93`); below 20 the blast:
; BlastX $ECEE = x + 12, BlastY $ECEF = y + 10, BlastOn $ECF1 = `$FF`, the
; frame BlastFrames[fuse / 4]. While the fuse is 4 or more `$F76F` tests Rick
; (IX = RickObject) and kills him (`$FBED`) inside the blast. At 0 the slot and
; BlastOn are cleared.
;
; Run in level2 (50 passes) and level3 (300): the dynamite used there. The
; blast kills enemies (EnemyCommon), destroys boxes and triggers traps with
; flag bit 4.
;
; Witness: L1 1523 (beeper48, L1Z1, L1Z2, L2Z1, L2Z2, L2Z6, L2Z7, L3Z2, L3Z6,
; L3Z11, L3Z12, L4Z x5, level2, level3).
DynamiteObj:
  LD A,(DynFuse)
  DEC A
  JP NZ,DynamiteTick
  LD (IX+$00),A
  LD (BlastOn),A
  RET
DynamiteTick:
  LD (DynFuse),A
  LD HL,FuseFrames
  CP $14
  JP NZ,DynamiteFuseFrame
  PUSH AF
  LD A,$02
  CALL PlayEffect
  POP AF
DynamiteFuseFrame:
  JP C,DynamiteBlast
  AND $01
  LD (IX+$06),A
  JP DynamiteSetFrame
DynamiteBlast:
  SRL A
  SRL A
  LD C,A
  LD A,(IX+$01)
  ADD A,$0C
  LD (BlastX),A
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD DE,$000A
  ADD HL,DE
  LD (BlastY),HL
  LD A,$FF
  LD (BlastOn),A
  LD HL,BlastFrames
  LD A,C
DynamiteSetFrame:
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  LD (IX+$04),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  LD A,(BlastOn)
  AND A
  RET Z
  LD A,(DynFuse)
  CP $04
  RET C
  PUSH IX
  LD IX,RickObject
  CALL InBlast
  POP IX
  RET NZ
  JP KillRick

; the dynamite's fuse count (set by the drop `$FAB1`)
DynFuse:
  DEFB $00

; the blast's centre x
BlastX:
  DEFB $00

; the blast's centre y
BlastY:
  DEFW $0000

; $FF while the blast lasts; cleared by ResetObjects $EBF7, `$AD50` and
; DynamiteObj $EC77
BlastOn:
  DEFB $00

; the burning stick (twice), then BlastFrames
FuseFrames:
  DEFW DynamiteFuse
  DEFW DynamiteFuse
BlastFrames:
  DEFW Blast0             ; the five blast frames: small, large, larger, large,
  DEFW Blast1             ; small (also the boxes' explosion)
  DEFW Blast2
  DEFW Blast1
  DEFW Blast0

; Kind 2: Rick's bullet flies until it hits a wall or leaves
;
; x += BulletDx $ED3F (signed: `$FA75` / `$FA83` set it when Rick fires); off
; the left edge or at `$E8` and up the bullet goes. BulletHitX $ED40 = x (left)
; or x + `$17` (right), BulletHitY $ED41 = y + 5. `$F535` probes the map there:
; a wall frees the slot. The enemies, boxes and traps test BulletX / BulletY or
; BulletHitX / BulletHitY with `$F742`.
;
; Run in c1 and levels 1-4 (25 to 84 passes).
;
; Witness: L1 396 (beeper48, c1, L1Z5, L2Z1, L2Z6, L3Z x7, L4Z3, L4Z4, L4Z8,
; L4Z9, level1-level4).
BulletObj:
  LD A,(BulletDx)
  AND A
  JP P,BulletRight
  ADD A,(IX+$01)
  JP NC,BulletGone
  LD (IX+$01),A
BulletStore:
  LD (BulletHitX),A
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD BC,$0005
  ADD HL,BC
  LD (BulletHitY),HL
  CALL IsSolidAt
  RET Z
  JP BulletGone
BulletRight:
  ADD A,(IX+$01)
  JP C,BulletGone
  CP $E8
  JP NC,BulletGone
  LD (IX+$01),A
  ADD A,$17
  JP BulletStore
BulletGone:
  XOR A
  LD (IX+$00),A
  RET

; the bullet's step: negative left, positive right (`$FA75`, `$FA83`)
BulletDx:
  DEFB $02

; the bullet's front x (BulletObj $ED00)
BulletHitX:
  DEFB $00

; the bullet's y + 5 (BulletObj $ED00)
BulletHitY:
  DEFW $0000

  ORG $F851

; Object kind 1: move Rick, then choose his frame
;
; Handler of kind 1 (the pointer at `$EC49`), IX = Rick `$EAAC`. MoveRick
; `$F85D`, then the crawl flag `$FD5A` is
;
; kept in PrevCrawl `$FD5F`, then ChooseRickFrame `$FC60` (a jump: its RET
; returns from here).
;
; Witness: L1 42788 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
RickHandler:
  CALL MoveRick
  LD A,(Crawling)
  LD (PrevCrawl),A
  JP ChooseRickFrame

; One frame of Rick: fall, land, walk, climb, fire, die
;
; IX = Rick. Clears Poking `$FD63` and FireHeld `$FD67`. Dying (`$FD68`):
; DeathFall `$FC16`. Reads the controls
;
; (`$A14E`, into `$A14D`). Climbing (`$FD59`): ClimbRick `$FB14`.
;
; Else gravity: the new Y = Y + Y velocity (`$FD56`, 8.8, the fraction in
; `$FD55`), the box probed there
;
; (ProbeLow `$F56D` while crawling, ProbeBox `$F5D5` else). A solid char in the
; way (bits 4-7 falling, 5-7 rising):
;
; LandRick `$F95D`. Else Rick is airborne (`$FD5B` = `$FF`): deadly char:
; KillRick `$FBED`; Y stored; a ladder with up
;
; or down held: climbing starts; the Y velocity grows by `$80` up to `$0800`;
; then WalkRick `$F903`.
;
; Witness: L1 42788 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
MoveRick:
  XOR A
  LD (Poking),A
  LD (FireHeld),A
  LD A,(Dying)
  AND A
  JP NZ,DeathFall
  CALL ReadInput
  LD A,(Climbing)
  AND A
  JP NZ,ClimbRick
  XOR A                   ; not climbing: gravity
  LD (Airborne),A
  LD A,(YFraction)
  LD E,A
  LD D,(IX+$02)
  LD C,(IX+$03)
  LD HL,(YVelocity)
  XOR A
  BIT 7,H
  JP Z,MoveRickFall
  DEC A
MoveRickFall:
  ADD HL,DE               ; HL = the new Y, D = the new fraction
  ADC A,C
  LD D,L
  LD L,H
  LD H,A
  LD E,(IX+$01)
  LD A,(Crawling)
  AND A
  JP Z,MoveRickProbeStand
  CALL ProbeLow
  LD A,(ProbeLowResult)
  AND A
  JP NZ,MoveRickCheck     ; crawling with no low ceiling ($F6A7 = 0): stand up
  XOR A
  LD (Crawling),A
  JP MoveRickCheck
MoveRickProbeStand:
  CALL ProbeBox
MoveRickCheck:
  LD B,$F0                ; B = the solid mask: $F0 falling, $E0 rising (a
                          ; platform does not stop a jump)
  LD A,(YVelocity+$0001)
  AND A
  JP P,MoveRickAir
  LD B,$E0
MoveRickAir:
  LD A,(ProbeResult)
  LD C,A
  AND B
  JP NZ,LandRick
  LD A,$FF
  LD (Airborne),A
  BIT 2,C
  JP NZ,KillRick
  LD (IX+$02),L
  LD (IX+$03),H
  LD A,D
  LD (YFraction),A
  BIT 1,C                 ; a ladder here and up or down held: climb
  JP Z,MoveRickGravity
  LD A,(InputBits)
  AND $0C
  CP $0C
  JP Z,MoveRickGravity
  LD A,$FF
  LD (Climbing),A
  RET
MoveRickGravity:
  LD HL,(YVelocity)       ; Y velocity + $80, at most $0800
  LD BC,$0080
  ADD HL,BC
  LD A,H
  AND A
  JP M,MoveRickSetVel
  CP $08
  JP C,MoveRickSetVel
  LD HL,$0800
MoveRickSetVel:
  LD (YVelocity),HL

; Rick's horizontal step: 2 pixels left or right, or the zone edge
;
; Part of MoveRick `$F85D` (jumped to from MoveRick, LandRick `$F95D`, NoFire
; `$FAC3`, SetCrawl `$FB0E`). Neither left
;
; nor right: AnimStep `$FD5C` = `$FF` (standing). Left: Facing `$FD58` = 1, X -
; 2, below 0: ExitLeft `$FBCF`. Right:
;
; Facing = 0, X + 2, at `$E8` or more: ExitRight `$FBDE`. The box at the new X
; is probed (ProbeLow `$F56D` when
;
; crawling, ProbeBox `$F5D5` else): bits 4-6 block; else X is stored, and a
; deadly char kills (KillRick `$FBED`).
;
; Witness: L1 30940 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
WalkRick:
  LD A,(InputBits)
  AND $03
  CP $03
  JP NZ,WalkRickLeft
  LD A,$FF
  LD (AnimStep),A
  RET
WalkRickLeft:
  CP $01
  JP NZ,WalkRickRight
  LD A,$01
  LD (Facing),A
  LD A,(IX+$01)
  ADD A,$FE
  JP NC,ExitLeft
  JP WalkRickProbe
WalkRickRight:
  XOR A
  LD (Facing),A
  LD A,(IX+$01)
  ADD A,$02
  CP $E8
  JP NC,ExitRight
WalkRickProbe:
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD E,A
  LD A,(Crawling)
  AND A
  JP Z,WalkRickProbeStand
  CALL ProbeLow
  JP WalkRickApply
WalkRickProbeStand:
  CALL ProbeBox
WalkRickApply:
  LD A,(ProbeResult)
  LD C,A
  AND $70
  RET NZ
  LD (IX+$01),E
  BIT 2,C
  JP NZ,KillRick
  RET

; Rick's box met a solid char: a ceiling bump, or the floor and the fire and
; jump controls
;
; Part of MoveRick `$F85D`. Rising (`$FD57` negative): a ceiling; Y to its row,
; the velocity 0, effect 6, WalkRick.
;
; Falling: Y to the row + 3. A spring (bit 5) hit at a speed of 2 or more
; bounces back (up held: velocity `$F800`, a
;
; big jump; else 254 - velocity); WalkRick. On the floor (velocity `$0100`):
; fire not held, or PrevCrawl `$FD5F`:
;
; NoFire `$FAC3`. Fire with left or right: the stick poke (Poking `$FD63`, the
; point at PokeX `$FD64` / PokeY
;
; `$FD65` = X + `$17` facing right or X facing left, Y + 14; effect 3 once per
; press, PokeLatch `$FD60`). Fire alone
;
; or with up or down: FireNoStick `$FA1E`.
;
; Evidence: the ceiling bump (`$F969`) ran in c1, controls and level1-level4.
; The spring bounce (`$F9AC`, `$F9B2`) ran in L2Z4 only (6 and 17). The stick
; poke (`$F9DC`) ran in controls, level1-level3 (level3 175).
;
; Witness: L1 21862 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-44, spotL1Z4-47).
LandRick:
  LD A,(YVelocity+$0001)
  AND A
  JP P,LandRickDown
  LD A,$FF
  LD (Airborne),A
  LD A,(IX+$02)
  AND $F8
  LD (IX+$02),A
  XOR A
  LD (YFraction),A
  LD HL,$0000
  LD (YVelocity),HL
  LD A,$06
  CALL PlayEffect
  JP WalkRick
LandRickDown:
  LD A,(IX+$02)           ; falling onto a floor
  AND $F8
  OR $03
  LD (IX+$02),A
  XOR A
  LD (YFraction),A
  BIT 5,C
  JP Z,LandRickOnFloor
  LD DE,(YVelocity)
  LD A,D
  AND A
  JP M,LandRickOnFloor
  CP $02
  JP C,LandRickOnFloor
  LD A,(InputBits)
  BIT 3,A
  JP NZ,LandRickBounceLow
  LD HL,-2048             ; up held on the spring: the high bounce
  JP LandRickSetVel
LandRickBounceLow:
  LD HL,$00FE
  OR A
  SBC HL,DE
LandRickSetVel:
  LD (YVelocity),HL
  JP WalkRick
LandRickOnFloor:
  LD HL,$0100             ; standing: velocity $0100, then the controls
  LD (YVelocity),HL
  LD A,(InputBits)
  LD D,A
  LD A,(PrevCrawl)
  AND A
  LD A,D
  JP NZ,NoFire
  BIT 4,D
  JP NZ,NoFire
  AND $03                 ; fire held
  CP $03
  JP Z,FireNoStick
  LD A,$FF                ; fire with left or right: poke the stick
  LD (Poking),A
  LD A,(PokeLatch)
  AND A
  JP NZ,PokeSetPoint
  LD A,$FF
  LD (PokeLatch),A
  LD A,$03
  CALL PlayEffect
PokeSetPoint:
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD BC,$000E
  ADD HL,BC
  LD (PokeY),HL
  LD A,$01
  LD (Facing),A
  LD A,(IX+$01)
  BIT 0,D
  JP NZ,PokeSetX
  XOR A
  LD (Facing),A
  LD A,(IX+$01)
  ADD A,$17
PokeSetX:
  LD (PokeX),A
  LD A,$FF
  LD (Poking),A
  RET

; Fire without left or right: clear the poke latch
;
; Part of LandRick `$F95D`. A = 0 into PokeLatch, then FireClearPokeLatch
; `$FA1F`.
;
; Witness: L1 432 (beeper48, c1, L1Z1, L1Z2, L1Z5, L2Z1, L2Z2, L2Z6, L2Z7, L3Z
; x7, L4Z2-L4Z5, L4Z7-L4Z9, level1-level4).
FireNoStick:
  XOR A

; Fire with up shoots, with down drops dynamite
;
; Part of LandRick `$F95D`. Up (bits 3-2 = 0-1): FireHeld `$FD67` = `$FF`; once
; per press (FireLatch `$FD5E`), and
;
; only with no bullet out (`$EACA` = 0): no bullets left (`$A976` = 0) plays
; effect 1; else one bullet less, effect
;
; 0, and the bullet object starts: kind 2, Y = Rick Y + 6, X = Rick X, frame
; `$85F9`, X velocity `$ED3F` = 8 (`$F8`
;
; facing left), `$EAD0` = 0 / 1 (mirror). Not up: FireNotUp `$FA8C`.
;
; Evidence: shots (`$FA4B`) in c1 and level1-level4; the "no bullets" sound
; (`$FA45`) ran in no build: known only from the code.
;
; Witness: L1 432 (beeper48, c1, L1Z1, L1Z2, L1Z5, L2Z1, L2Z2, L2Z6, L2Z7, L3Z
; x7, L4Z2-L4Z5, L4Z7-L4Z9, level1-level4).
FireClearPokeLatch:
  LD (PokeLatch),A
  LD A,D
  AND $0C
  CP $04
  JP NZ,FireNotUp
  LD A,$FF
  LD (FireHeld),A
  LD A,(FireLatch)
  AND A
  RET NZ
  LD A,$FF
  LD (FireLatch),A
  LD A,(BulletObject)
  AND A
  RET NZ
  LD A,(Dynamite)
  AND A
  JP NZ,FireShoot
  LD A,$01
  CALL PlayEffect
  RET
FireShoot:
  DEC A
  LD (Dynamite),A
  XOR A
  CALL PlayEffect
  LD A,$02
  LD (BulletObject),A
  LD A,(IX+$02)
  ADD A,$06
  LD (BulletY),A
  XOR A
  LD (BulletY+$0001),A
  LD (BulletY+$0004),A
  LD A,(IX+$01)
  LD (BulletX),A
ShootSetFrame:
  LD HL,Frame4            ; The bullet's frame and direction
  LD (BulletY+$0002),HL
  LD A,$08
  LD (BulletDx),A
  XOR A
  LD (BulletY+$0004),A
  LD A,(Facing)
  AND A
  RET Z
  LD A,$F8
  LD (BulletDx),A
ShootLeft:
  LD A,$01                ; The bullet flies left: mirrored
  LD (BulletY+$0004),A
  RET

; Fire without up: release the fire latch; with down, drop a dynamite stick
;
; Part of LandRick `$F95D`. FireLatch `$FD5E` = 0, AnimStep `$FD5C` = 0. Down
; (bits 3-2 = 1-0): with no dynamite
;
; out (`$EAE8` = 0) and sticks left (`$A967`): one less, the dynamite object
; starts (kind 3, fuse `$ECED` = `$32`
;
; frames, X `$EAE9` and Y `$EAEA` = Rick's).
;
; Evidence: a dynamite stick dropped (`$FAA6`) in level2 (1) and level3 (6).
;
; Witness: L1 352 (beeper48, c1, L1Z1, L1Z2, L2Z1, L2Z2, L2Z6, L2Z7, L3Z2,
; L3Z6, L3Z11, L3Z12, L4Z x5, level1-level4).
FireNotUp:
  XOR A
  LD (FireLatch),A
FireSetAnim:
  LD (AnimStep),A
  LD A,D
  AND $0C
  CP $08
  JP Z,DropDynamite
  RET
DropDynamite:
  LD A,(DynamiteObject)
  AND A
  RET NZ
  LD A,(Bullets)
  AND A
  RET Z
  DEC A
  LD (Bullets),A
  LD A,$03
  LD (DynamiteObject),A
  LD A,$32
  LD (DynFuse),A
  LD A,(IX+$01)
  LD (DynamiteX),A
  LD L,(IX+$02)
  LD H,$00
  LD (DynamiteX+$0001),HL
  RET

; On the floor without fire: jump, climb, crawl or walk
;
; Part of LandRick `$F95D`. Up held: on a ladder (bit 1) climbing starts
; (`$FD59`); else a jump (velocity `$FA80`,
;
; effect 6) and WalkRick. Down held: no floor under the middle (bit 7 clear):
; Rick crawls (SetCrawl); on a ladder
;
; top (bits 0-1) with X AND `$1F` < `$0A`, X snaps to the ladder (X AND `$F0` +
; 4) and climbing starts; else crawl.
;
; Neither: WalkRick.
;
; Evidence: jumps (`$FAD3`) in every game build; crawls (`$FB0C`) in
; level1-level4; the ladder top snap (`$FAFC`) in level1 and level3.
;
; Witness: L1 20830 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-44, spotL1Z4-47).
NoFire:
  BIT 3,D
  JP NZ,NoFireDown
  BIT 1,C
  JP Z,Jump
  LD A,$FF
  LD (Climbing),A
  RET
Jump:
  LD HL,-1408
  LD (YVelocity),HL
  LD A,$06
  CALL PlayEffect
  JP WalkRick
NoFireDown:
  BIT 2,D
  JP NZ,WalkRick
DownFloorTest:
  BIT 7,C                 ; down held on the floor: a ladder top under Rick?
  JP Z,StartCrawl
  AND $03
  CP $03
  JP NZ,StartCrawl
  LD A,(IX+$01)
  AND $1F
  CP $0A
  JP NC,StartCrawl
  LD A,(IX+$01)
  AND $F0
  OR $04
  LD (IX+$01),A
  LD A,$FF
  LD (Climbing),A
  RET
StartCrawl:
  LD A,$FF
SetCrawl:
  LD (Crawling),A         ; Crawl flag `$FD5A` = A, then WalkRick
  JP WalkRick

; One frame on a ladder
;
; Part of MoveRick `$F85D`. No direction: AnimStep `$FD5C` = 0, stay. Up or
; down: Y - 2 or + 2, probed (ProbeBox
;
; `$F5D5`). Free: Y moves (ClimbMove `$FB5E`). Blocked going down: climbing
; stops. Blocked going up: through a
;
; platform (bit 4) it moves, else only sideways (ClimbSideways `$FB82`). After
; the move a deadly char kills; a ladder
;
; or floor (bits 1, 7) keeps climbing; else Rick leaves the ladder, velocity
; `$0100` (down) or `$FD00` (up: a hop).
;
; Evidence: climbing ran in level1-level4; a blocked climb up (`$FB58`) in
; level2; leaving at the end (`$FB6F`) in level2 and level3.
;
; Witness: L1 1197 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z9, L3Z11, L3Z12, L4Z3, L4Z4,
; L4Z7, level1-level4).
ClimbRick:
  LD A,(InputBits)
  AND $0F
  CP $0F
  JP NZ,ClimbVertical
  XOR A
  LD (AnimStep),A
  RET
ClimbVertical:
  AND $0C
  CP $0C
  JP Z,ClimbSideways
  LD L,(IX+$02)
  LD H,(IX+$03)
  CP $04
ClimbDir:
  JP NZ,ClimbDown
  LD DE,-2
  JP ClimbProbe
ClimbDown:
  LD DE,$0002
ClimbProbe:
  ADD HL,DE
  LD E,(IX+$01)
  CALL ProbeBox
ClimbTest:
  LD A,(ProbeResult)
  LD C,A
  AND $70
ClimbTestBlocked:
  JP Z,ClimbMove
  BIT 7,D
  JP NZ,ClimbUpBlocked
ClimbStop:
  XOR A                   ; Blocked going down: off the ladder
  LD (Climbing),A
  RET
ClimbUpBlocked:
  LD A,C
  AND $10
  JP Z,ClimbSideways

; Store the new Y
;
; Part of ClimbRick `$FB14`.
;
; Witness: L1 778 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z9, L3Z11, L3Z12, L4Z3, L4Z4,
; L4Z7, level1-level4).
ClimbMove:
  LD (IX+$02),L
ClimbMoveHigh:
  LD (IX+$03),H
  BIT 2,C
  JP NZ,KillRick
  LD A,C
  AND $82
  JP NZ,ClimbSideways
  LD HL,$0100
  BIT 7,D
  JP Z,ClimbLeave
  LD HL,-768
ClimbLeave:
  LD (YVelocity),HL
  XOR A
  LD (Climbing),A
  RET

; On a ladder: left or right by 2
;
; Part of ClimbRick `$FB14`. As WalkRick, with the walls bits 5-6; the zone
; edges give ExitLeft `$FBCF` /
;
; ExitRight `$FBDE`. Off the ladder (no bit 1 or 7): climbing stops, and with
; up held velocity `$FD00` (a hop).
;
; Witness: L1 1004 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z9, L3Z11, L3Z12, L4Z3, L4Z4,
; L4Z7, level1-level4).
ClimbSideways:
  LD A,(InputBits)
  AND $03
  CP $03
  RET Z
  CP $01
  LD A,(IX+$01)
  JP NZ,ClimbRight
  ADD A,$FE
  JP NC,ExitLeft
  JP ClimbSideProbe

; ClimbRight
;
; Part of ClimbSideways `$FB82`.
;
; Witness: L1 236 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z12, L4Z3, L4Z4, L4Z7,
; level1-level4).
ClimbRight:
  ADD A,$02
  CP $E8
  JP NC,ExitRight

; ClimbSideProbe
;
; Part of ClimbSideways `$FB82`.
;
; Witness: L1 297 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z12, L4Z3, L4Z4, L4Z7,
; level1-level4).
ClimbSideProbe:
  LD E,A
  LD L,(IX+$02)
  LD H,(IX+$03)
  CALL ProbeBox
ClimbSideTest:
  LD A,(ProbeResult)
  LD C,A
  AND $60
  RET NZ
  LD (IX+$01),E
  BIT 2,C
  JP NZ,KillRick
  LD A,C
  AND $82
  RET NZ
  XOR A
  LD (Climbing),A
  LD A,(InputBits)
  BIT 3,A
ClimbSideHop:
  RET NZ
  LD HL,-768
  LD (YVelocity),HL
  RET

; Rick left the zone on the left
;
; ZoneChange `$FD61` = `$FF`, ExitSide `$FD62` = 0, X = `$E4` (the right edge
; of the next zone). The game loop
;
; (`$E3FD`, `$ABA6`) moves to the next zone.
;
; Evidence: in c1 and level1, the zone exits a recording reached.
;
; Witness: L1 54 (c1, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z2-L4Z6, L4Z8,
; level1).
ExitLeft:
  LD A,$FF
ExitLeftSet:
  LD (ZoneChange),A
  LD A,$00
  LD (ExitSide),A
  LD (IX+$01),$E4
  RET

; Rick left the zone on the right
;
; ZoneChange `$FD61` = `$FF`, ExitSide `$FD62` = 1, X = 2.
;
; Witness: L1 51 (c1, ending2, L1Z2-L1Z4, L1Z6, L2Z2, L2Z4-L2Z7, L3Z2-L3Z12,
; L4Z x5, level1).
ExitRight:
  LD A,$FF
  LD (ZoneChange),A
ExitRightSet:
  LD A,$01
  LD (ExitSide),A
  LD (IX+$01),$02
  RET

; Rick dies (once)
;
; Already dying (`$FD68`): return. Else KillRickNow `$FBF2`. Called for a
; deadly char and by the objects that kill
;
; Rick.
;
; Witness: L1 400 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
KillRick:
  LD A,(Dying)
  AND A
  RET NZ

; Effect 11, Dying, a hop up, the drift away from the middle
;
; Part of KillRick `$FBED`. Effect 11, Dying `$FD68` = `$FF`, Y velocity
; `$FC00`, DeathDrift `$FD6A` = 3 (Rick X <
;
; `$80`) or `$FD` (-3).
;
; Evidence: deaths in every game build (level4 29).
;
; Witness: L1 323 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
KillRickNow:
  LD A,$0B
  CALL PlayEffect
  LD A,$FF
  LD (Dying),A
  LD HL,-1024
  LD (YVelocity),HL
  LD A,(RickX)
  CP $80
  JP NC,KillRickDriftLeft
  LD A,$03
  LD (DeathDrift),A
  RET
KillRickDriftLeft:
  LD A,$FD
  LD (DeathDrift),A
  RET

; The dying Rick: drift sideways, fall with gravity, off the bottom
;
; Part of MoveRick `$F85D`. X += DeathDrift `$FD6A`; Y += velocity, no
; collisions; past the bottom (the new Y's high
;
; byte nonzero) the object is freed and DeathDone `$FD69` = `$FF` (read at
; `$E3EB`: a life lost). Else the velocity
;
; grows by `$80`.
;
; Evidence: DeathDone set (`$FC41`) in c1 2, controls 3, gameover 6, level1 11,
; level2 3, level3 5, level4 28 times.
;
; Witness: L1 9925 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
DeathFall:
  LD A,(DeathDrift)
  ADD A,(IX+$01)
  LD (IX+$01),A
  LD C,(IX+$02)
  LD B,(IX+$03)
  LD A,(YFraction)
  LD E,A
  LD H,$00
  LD A,(YVelocity+$0001)
  AND A
  JP P,DeathFallAdd
  LD H,$FF
DeathFallAdd:
  LD L,A
  LD A,(YVelocity)
  ADD A,E
  ADC HL,BC
  LD E,A
  LD A,H
  AND A
  JP Z,DeathFallStore
  LD (IX+$00),$00
  LD A,$FF
  LD (DeathDone),A
  RET
DeathFallStore:
  LD (IX+$02),L
  LD (IX+$03),H
  LD A,E
  LD (YFraction),A
  LD HL,(YVelocity)
  LD BC,$0080
  ADD HL,BC
  LD (YVelocity),HL
  RET

; Rick's sprite frame and mirror for this frame, and the step sounds
;
; Part of RickHandler `$F851`. The mirror +6 = Facing `$FD58`. Dying: frame
; `$857B`, the mirror flips every 4 frames
;
; (AnimStep `$FD5C` counts). Poking: `$87F1`. Crawling: CrawlFrames `$FD75` by
; AnimStep 0-7 / 2, effect 4 at steps 1
;
; and 4. Climbing: `$886F`, the mirror from (X XOR Y) AND 4 (the climbing
; wiggle), effect 4 every 2 moves. Airborne:
;
; `$84FD`. Firing: `$8773`. Else walking: WalkFrames `$FD6D` by AnimStep 0-7 /
; 2 (standing, AnimStep = `$FF`, gives
;
; 0), effect 4 at steps 2 and 6.
;
; Witness: L1 42788 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ChooseRickFrame:
  LD A,(Facing)
  LD (IX+$06),A
  LD A,(Dying)
  AND A
  JP Z,FrameNotDying
  LD A,(AnimStep)
  INC A
  AND $03
  LD (AnimStep),A
  JP NZ,FrameDying
  LD A,$01
  XOR (IX+$06)
  LD (IX+$06),A
FrameDying:
  LD HL,RickDying
  LD (IX+$06),A
  LD (IX+$04),L
  LD (IX+$05),H
  RET
FrameNotDying:
  LD A,(Poking)
  AND A
  JP Z,FrameNotPoking
  LD HL,RickPoking
  LD (IX+$04),L
  LD (IX+$05),H
  RET
FrameNotPoking:
  LD A,(Crawling)
  AND A
  JP Z,FrameNotCrawling
  LD HL,CrawlFrames
  LD A,(AnimStep)
  CP $01
  JP Z,FrameCrawlSound
  CP $04
  JP NZ,FrameCrawlStep
FrameCrawlSound:
  LD A,$04
  CALL PlayEffect
FrameCrawlStep:
  LD A,(AnimStep)
  INC A
  CP $08
  JP C,FrameFromTable
  XOR A
FrameFromTable:
  LD (AnimStep),A         ; A = the step, HL = the table: frame = table[step /
                          ; 2]
  SRL A
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  LD (IX+$04),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  RET
FrameNotCrawling:
  LD A,(Climbing)
  AND A
  JP Z,FrameNotClimbing
  LD HL,RickClimbing
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$06),$00
  LD A,(IX+$01)
  XOR (IX+$02)
  AND $04
  RET Z
  LD (IX+$06),$01
  LD A,(AnimStep)
  INC A
  CP $02
  JP NC,FrameClimbSound
  LD (AnimStep),A
  RET
FrameClimbSound:
  XOR A
  LD (AnimStep),A
  LD A,$04
  CALL PlayEffect
  RET
FrameNotClimbing:
  LD A,(Airborne)
  AND A
  JP Z,FrameNotFalling
  LD HL,RickWalk2
  LD (IX+$04),L
  LD (IX+$05),H
  RET
FrameNotFalling:
  LD A,(FireHeld)
  AND A
  JP Z,FrameWalk
  LD HL,RickFiring
  LD (IX+$04),L
  LD (IX+$05),H
  RET
FrameWalk:
  LD A,(AnimStep)
  INC A
  PUSH AF
  CP $06
  JP Z,FrameWalkSound
  CP $02
  JP NZ,FrameWalkTable
FrameWalkSound:
  LD A,$04
  CALL PlayEffect
FrameWalkTable:
  POP AF
  LD HL,WalkFrames
  CP $08
  JP C,FrameFromTable
  XOR A
  JP FrameFromTable
