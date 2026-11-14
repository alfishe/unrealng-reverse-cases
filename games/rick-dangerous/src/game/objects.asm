; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The object table's scroll
;
; The object table at $EA8E: 30-byte records, +0 0 empty or $FF the end; +1 x, +2/+3 y, +4/+5 the sprite frame, +6 bit
; 0 mirror; +$0D/+$0E and +$10/+$11 two more y positions. Rick's record is at $EAAC.
;
; ObjectTable $EA8E has 12 slots of 30 bytes and an `$FF` end. Slot 0 is read apart by `$F556`, `$F629` and `$F812`;
; slot 1 is Rick (RickObject $EAAC, kind 1, `$F851`), slot 2 his bullet (BulletObject $EACA, kind 2), slot 3 his
; dynamite (DynamiteObject $EAE8, kind 3); slots 4-11 (ZoneObjects $EB06) take the zone's objects (`$AC83`).
;
; A record: +0 type (bit 7: a trap is deadly, or a box was hit; bits 0-6 the kind; 0 a free slot), +1 x (0-`$E8`),
; +2-3 y (16-bit), +4-5 the sprite frame, +6 mirror (`$FF` / 0), +7 width, +8 height, +9-10 the level object list
; entry (bit 7 of the byte after it: done), +11 flags, +12 the patrol length, +15 x and +16-17 y of the path start,
; +18-19 the frame base or the animation list, +20-21 the path start, +22-23 the path pointer, +24 the animation step
; or the walk step, +25 the path step count or the patrol count, +26 y fraction, +27-28 y speed (8.8, `$80` gravity a
; pass, at most `$0800`), +29 the stun count.
;
; +11 flags: bit 0 one-shot (MarkObjectDone $EDDC when killed or ended), bit 2 the restarted path is deadly, bit 3 a
; triggered path is deadly, bit 4 the dynamite's blast triggers it, bit 5 the bullet, bit 6 the stick, bit 7 Rick's
; centre inside its box (`$F7C3`). +13 and +14 are not read in this fragment.
;
; UpdateObjects $EC11 dispatches each slot's kind: `$47` DyingEnemyObj $F1B7, `$18` and up TrapObj $EDFC, else
; ObjectHandlers $EC47: 0 KillObject, 1 Rick, 2 BulletObj, 3 DynamiteObj, 4/7/10/13 PatrolObj $EFCF, 5/8/11/14
; TrackerObj $EFD6, 6/9/12/15 ClimberObj $F233, 16/17 AmmoBoxObj $ED43, 18-21 TreasureObj $EDE6, 22/23 the bonus
; markers `$F4C8` / `$F502`.
;
; Object kinds 22 and 23 (the timed bonus), the char-map probes every moving object uses (ProbeBox, ProbeLow,
;
; IsSolidAt), the box tests between two objects (ObjectsOverlap, PointInObject, PointInTrigger, InBlast,
;
; HitsObstacle), and the char property table: BuildCharProps fills $5C00 with one property byte per char code
;
; from the run-length pairs CharPropsSet0 / CharPropsSet1.
;
; An object record is 30 bytes: +0 kind (bit 7 active for the slots from $EB06), +1 X (pixels), +2/+3 Y (pixels,
;
; map coordinates), +4/+5 sprite frame, +6 mirror, +7 width, +8 height, +9/+A the spawn record, +B its flags,
;
; +C X and +D/+E Y of the trigger box, +F, +10/+11 home X and Y, +12/+13 base frame, +18 state, +19 X velocity,
;
; +1A Y fraction, +1B/+1C Y velocity (8.8), +1D. Rick is at $EAAC, the bullet at $EACA, the dynamite at $EAE8,
;
; object 0 (a moving solid block) at $EA8E.
;
; Char property bits (CharPropsSet0, CharPropsSet1): bit 1 ladder, bit 2 deadly, bit 3 not tested by this code,
;
; bit 4 platform (stops a fall, not a jump), bit 5 spring (always with bit 6), bit 6 wall, bit 7 floor.
; --------------------------------------------------------------------------------------------------------------------

  ORG $AEBE

; Move every object by BC in y and drop those that leave the map
;
; Input: BC = -32 or +32. Adds BC to +$10/+$11, +$0D/+$0E and +2/+3. Going up:
; an object whose y turns negative is emptied (+0 = 0); going down: one whose y
; reaches $12C. Callers: the scroll steps ($ADC8, $ADFF).
;
; Witness: L1 172 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z2, L2Z6,
; L3Z6, L3Z8-L3Z10, L4Z3, L4Z5, level1-level4, spotL1Z4-43).
ShiftObjects:
  LD IX,ObjectTable
ShiftObjectsLoop:
  LD A,(IX+$00)
  CP $FF
  RET Z
  AND A
  JP Z,ShiftObjectsNext
  LD L,(IX+$10)
  LD H,(IX+$11)
  ADD HL,BC
  LD (IX+$10),L
  LD (IX+$11),H
  LD L,(IX+$0D)
  LD H,(IX+$0E)
  ADD HL,BC
  LD (IX+$0D),L
  LD (IX+$0E),H
  LD L,(IX+$02)
  LD H,(IX+$03)
  BIT 7,B
  JP NZ,ShiftObjectsUp
  ADD HL,BC
  LD A,H
  AND A
  JP Z,ShiftObjectsStore
  LD A,L
  CP $2C
  JP C,ShiftObjectsStore
ShiftObjectsDrop:
  LD (IX+$00),$00
  JP ShiftObjectsNext
ShiftObjectsUp:
  ADD HL,BC
  BIT 7,H
  JP NZ,ShiftObjectsDrop
ShiftObjectsStore:
  LD (IX+$02),L
  LD (IX+$03),H
ShiftObjectsNext:
  LD DE,$001E
  ADD IX,DE
  JP ShiftObjectsLoop

  ORG $EA8E

; 12 object slots of 30 bytes, all 0 at the load
;
; The record format is in the module header. In play (work/images/play.*.bin)
; slot 1 is `01 8E A5 00 FD 84 01 18 15`: Rick, x `$8E`, y `$00A5`, frame
; `$84FD`, width `$18`, height `$15`.
ObjectTable:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
RickObject:
  DEFB $00                ; slot 1: Rick
RickX:
  DEFB $00
RickY:
  DEFB $00,$00,$00,$00    ; 16-bit
RickMirror:
  DEFB $00                ; +6
RickWidth:
  DEFB $00
RickHeight:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
BulletObject:
  DEFB $00                ; slot 2: Rick's bullet
BulletX:
  DEFB $00
BulletY:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
DynamiteObject:
  DEFB $00                ; slot 3: Rick's dynamite
DynamiteX:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
ZoneObjects:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slots
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 4-11: the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; zone's
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; objects
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
ObjectTableEnd:
  DEFB $FF                ; $FF

; Free every slot but Rick's; no blast, no stick
;
; Every slot whose type is not 1 gets type 0, up to the `$FF` end; BlastOn
; $ECF1 and the stick flag `$FD63` are cleared. Called at each zone set-up (c1
; 7, level1 19, level4 30).
;
; Witness: L1 439 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
ResetObjects:
  LD HL,ObjectTable
  LD DE,$001E
  XOR A
  LD C,A
  LD (BlastOn),A
  LD (Poking),A
ResetObjectsLoop:
  LD A,(HL)
  CP $FF
  RET Z
  CP $01
  JR Z,ResetObjectsNext
  LD (HL),C
ResetObjectsNext:
  ADD HL,DE
  JR ResetObjectsLoop

; Run every object's handler once
;
; IX = ObjectTable $EA8E; UpdateObjectSlot $EC15 per slot. Called once a pass
; by MainLoop $E3C9.
;
; Witness: L1 43340 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
UpdateObjects:
  LD IX,ObjectTable

; One slot: dispatch on its kind
;
; Type 0 is skipped, `$FF` ends. Else NextObject $EC3B is pushed as the return
; address and the kind (type AND `$7F`) chosen: `$47` DyingEnemyObj $F1B7,
; `$18` and up TrapObj $EDFC, else the word ObjectHandlers[kind].
;
; Witness: L1 563418 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
UpdateObjectSlot:
  LD A,(IX+$00)
  AND A
  JR Z,NextObject
  CP $FF
  RET Z
  LD HL,NextObject
  PUSH HL
  AND $7F
  CP $47
  JP Z,DyingEnemyObj
  CP $18
  JP NC,TrapObj
  ADD A,A
  LD L,A
  LD H,$00
  LD BC,ObjectHandlers
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP (HL)

; IX to the next slot, +30
;
; Witness: L1 520078 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
NextObject:
  LD BC,$001E
  ADD IX,BC
  JR UpdateObjectSlot

; Kind 0 with bit 7 set: free the slot
;
; ObjectHandlers $EC47 entry 0. Only a type `$80` reaches it. Run by no
; recording.
;
; Witness: L1 0 ().
KillObject:
  LD (IX+$00),$00
  RET

; Handler of each kind 0-23
;
; Indexed by UpdateObjectSlot $EC15 with type AND `$7F` below `$18`.
ObjectHandlers:
  DEFW KillObject
  DEFW RickHandler
  DEFW BulletObj
  DEFW DynamiteObj
  DEFW PatrolObj
  DEFW TrackerObj
  DEFW ClimberObj
  DEFW PatrolObj
  DEFW TrackerObj
  DEFW ClimberObj
  DEFW PatrolObj
  DEFW TrackerObj
  DEFW ClimberObj
  DEFW PatrolObj
  DEFW TrackerObj
  DEFW ClimberObj
  DEFW AmmoBoxObj
  DEFW AmmoBoxObj
  DEFW TreasureObj
  DEFW TreasureObj
  DEFW TreasureObj
  DEFW TreasureObj
  DEFW BonusTrigger
  DEFW BonusCollect

  ORG $ED43

; Kinds 16 and 17: the dynamite and the bullet box
;
; Rick touching it (`$F6E0` Z): effect 8, the slot freed, dynamite `$A967`
; (kind 16) or bullets `$A976` (kind 17) back to 6, MarkObjectDone $EDDC. The
; stick, the bullet or the blast destroys it: type bit 7, MarkObjectDone, and
; BoxBlastFrame plays BlastFrames $ECF6 for 9 passes, then the slot is freed.
;
; The zone recordings run it wherever a box is in view; Rick takes the bullet
; box once in L1Z4 (`$ED76`, effect 8, 1 run) and a blast destroys a box in
; L4Z4 (BoxBlastFrame, 9 passes).
;
; Witness: L1 5675 (spotL3Z7-51, spotL4Z8-69, L1Z4-L1Z6, L2Z5-L2Z7, L3Z2, L3Z3,
; L3Z8, L3Z10, L4Z4).
AmmoBoxObj:
  LD A,(IX+$00)
  AND A
  JP P,BoxActive
  LD A,(IX+$18)
  INC A
  CP $0A
  JP C,BoxBlastFrame
  LD (IX+$00),$00
  RET
BoxBlastFrame:
  LD (IX+$18),A
  AND $1E
  LD C,A
  LD B,$00
  LD HL,BlastFrames
  ADD HL,BC
  LD A,(HL)
  LD (IX+$04),A
  INC HL
  LD A,(HL)
  LD (IX+$05),A
  RET
BoxActive:
  CALL RickTouches
  JP NZ,BoxTestStick
  LD A,$08
  CALL PlayEffect
  LD A,(IX+$00)
  LD (IX+$00),$00
  CP $10
  LD A,$06
  JP Z,BoxGiveDynamite
  LD (Bullets),A
  JP MarkObjectDone
BoxGiveDynamite:
  LD (Dynamite),A
  JP MarkObjectDone
BoxTestStick:
  LD A,(Poking)
  AND A
  JP Z,BoxTestBullet
  LD A,(PokeX)
  LD E,A
  LD A,(PokeY)
  LD L,A
  LD H,$00
  CALL PointInObject
  JP NZ,BoxTestBullet
BoxDestroy:
  SET 7,(IX+$00)
  LD (IX+$18),$00
  JP MarkObjectDone
BoxTestBullet:
  LD A,(BulletObject)
  AND A
  JP Z,BoxTestBlast
  LD A,(BulletHitX)
  LD E,A
  LD HL,(BulletHitY)
  CALL PointInObject
  JP NZ,BoxTestBlast
  XOR A
  LD (BulletObject),A
  JP BoxDestroy
BoxTestBlast:
  LD A,(BlastOn)
  AND A
  RET Z
  CALL InBlast
  RET NZ
  JP BoxDestroy

; Mark the object's level list entry done, so it does not come back
;
; Sets bit 7 of the byte after (+9/+10); NewGame $E2DC clears them all.
;
; Witness: L1 15 (c1, L1Z3, L1Z4, L3Z6, L4Z4, level1, level2).
MarkObjectDone:
  LD L,(IX+$09)
  LD H,(IX+$0A)
  INC HL
  SET 7,(HL)
  RET

; Kinds 18-21: a bonus item; Rick takes it
;
; Rick touching it (`$F6E0` Z): effect 9, the slot freed, the score `$A9DD`
; added (`$A9E8`), MarkObjectDone $EDDC.
;
; Taken 4 times in c1 and level1, once in level2 (the `$EDEC` effect counts).
;
; Witness: L1 10293 (c1, L1Z2-L1Z5, L2Z1, L2Z5, L3Z5-L3Z7, L3Z9, L4Z1-L4Z3,
; level1, level2, level4, spotL1Z4-43, spotL1Z4-44).
TreasureObj:
  CALL RickTouches
  RET NZ
  LD A,$09
  CALL PlayEffect
  LD (IX+$00),$00
  LD DE,Award500+$0004
  CALL AddScore
  JP MarkObjectDone

; Kinds 24 and up: a trap moving along its path; deadly with bit 7
;
; TrapMove $EE0B, then, if type bit 7 is set, `$F6E0` tests Rick and `$FBED`
; kills him on touch.
;
; The busiest handler: c1 1299, level2 7377, level3 9162 passes.
;
; Witness: L1 98254 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z3, L1Z5,
; L1Z6, L2Z1-L2Z4, L2Z6, L2Z7, L3Z1, L3Z2, L3Z4-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
TrapObj:
  CALL TrapMove
  BIT 7,(IX+$00)
  RET Z
  CALL RickTouches
  JP Z,KillRick
  RET

; Animate a trap and move it one step along its path
;
; Animation: the list at +18/19 holds a byte per frame (bit 7 mirror, bits 0-6
; the frame number n, the frame at n x `$7E` + `$8383`; 0: no sprite; `$FF`:
; back to the start), indexed by +24.
;
; Path (+22/23): 3-byte steps (count, dx, dy) each run for count passes; `$FF`
; ends it. Then a one-shot trap goes (unless Rick is dying); the others
; restart: type bit 7 from flag bit 2, the position from +15-17, and
; TrapTriggers $EF2E waits for a trigger.
;
; x stays within 0-`$E7`, y below `$12A`; leaving ends the path.
;
; Witness: L1 98404 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z3, L1Z5,
; L1Z6, L2Z1-L2Z4, L2Z6, L2Z7, L3Z1, L3Z2, L3Z4-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
TrapMove:
  LD A,(IX+$18)
  LD C,A
  LD B,$00
  LD L,(IX+$12)
  LD H,(IX+$13)
  LD E,L
  LD D,H
  ADD HL,BC
  LD A,(HL)
  CP $FF
  JP NZ,TrapFrame
  LD L,E
  LD H,D
  LD A,(HL)
TrapFrame:
  AND A
  JP NZ,TrapFrameSet
  LD HL,$0000
  JP TrapFrameStore
TrapFrameSet:
  LD C,$00
  RLA
  RL C
  LD (IX+$06),C
  SRL A
  LD H,A
  LD L,$00
  SRL H
  RR L
  ADD A,A
  LD B,$FF
  NEG
  JP NZ,TrapFrameAdd
  LD B,$00
TrapFrameAdd:
  LD C,A
  ADD HL,BC
  LD BC,$8383
  ADD HL,BC
TrapFrameStore:
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$18)
  AND A
  JP Z,TrapTriggers
  LD C,A
  LD B,$00
  LD L,E
  LD H,D
  ADD HL,BC
  LD A,(HL)
  CP $FF
  JP NZ,TrapAnimNext
  LD (IX+$18),$01
  JP TrapPath
TrapAnimNext:
  INC C
  LD (IX+$18),C
  LD B,$00
  LD L,E
  LD H,D
  ADD HL,BC
  LD A,(HL)
  CP $FF
  JP NZ,TrapPath
  LD (IX+$18),$01
TrapPath:
  LD L,(IX+$16)
  LD H,(IX+$17)
  LD A,(IX+$19)
TrapPathStep:
  CP (HL)
  JP C,TrapStepMove
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  CP $FF
  JP NZ,TrapNextStep
; This entry point is used by the routine at TrapStepMove.
TrapPathEnd:
  LD A,(Dying)
  AND A
  JP NZ,TrapRestart
  BIT 0,(IX+$0B)
  JP Z,TrapRestart
  LD (IX+$00),$00
  RET
TrapRestart:
  LD A,(IX+$00)
  AND $7F
  BIT 2,(IX+$0B)
  JP Z,TrapRestartType
  OR $80
TrapRestartType:
  LD (IX+$00),A
  LD (IX+$18),$00
  LD A,(IX+$0F)
  LD (IX+$01),A
  LD A,(IX+$10)
  LD (IX+$02),A
  LD A,(IX+$11)
  LD (IX+$03),A
  JP TrapMove
TrapNextStep:
  LD (IX+$16),L
  LD (IX+$17),H
  LD A,$00
  LD (IX+$19),A
  JP TrapPathStep

; One path step: move by dx, dy
;
; Witness: L1 10822 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1, L1Z5,
; L1Z6, L2Z1-L2Z3, L2Z6, L2Z7, L3Z1, L3Z7, L3Z8, L3Z10-L3Z12, L4Z x5,
; level1-level4).
TrapStepMove:
  INC A
  LD (IX+$19),A
  INC HL
  LD A,(HL)
  AND A
  JP P,TrapMoveRight
  ADD A,(IX+$01)
  JP NC,TrapPathEnd
  JP TrapStoreX
TrapMoveRight:
  ADD A,(IX+$01)
  JP C,TrapPathEnd
  CP $E8
  JP NC,TrapPathEnd
TrapStoreX:
  LD (IX+$01),A
  INC HL
  LD C,(HL)
  LD L,(IX+$02)
  LD H,(IX+$03)
  BIT 7,C
  LD B,$00
  JP Z,TrapMoveY
  DEC B
TrapMoveY:
  ADD HL,BC
  LD A,H
  AND A
  JP Z,TrapStoreY
  JP M,TrapPathEnd
  CP $01
  JP NZ,TrapPathEnd
  LD A,L
  CP $2A
  JP NC,TrapPathEnd
TrapStoreY:
  LD (IX+$02),L
  LD (IX+$03),H
  RET

; A waiting trap: start its path on a trigger
;
; Skipped while Rick is dying (`$FD68`). By flag +11: bit 7 Rick's centre
; (RickX + 12, RickY + 10) inside the trap's box (`$F7C3`); bit 6 the stick
; (`$FD63`, the point `$FD64` / `$FD65`); bit 5 the bullet (BulletObject alive,
; the point BulletHitX / BulletHitY; the bullet is used up); bit 4 the blast
; (BlastOn, BlastX / BlastY).
;
; Triggered: type bit 7 = flag bit 3, +24 = 1, +25 = 0, the path pointer from
; +20/21, effect 3.
;
; Witness: L1 87578 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z3, L1Z5,
; L1Z6, L2Z1-L2Z4, L2Z6, L2Z7, L3Z1, L3Z2, L3Z4-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
TrapTriggers:
  LD A,(Dying)
  AND A
  RET NZ
  LD A,(IX+$0B)
  BIT 7,A
  JP Z,TrapTestStick
  LD A,(RickX)
  ADD A,$0C
  LD E,A
  LD A,(RickY)
  ADD A,$0A
  LD L,A
  LD H,$00
  CALL PointInTrigger
  JP Z,TrapTriggered
  LD A,(IX+$0B)
TrapTestStick:
  BIT 6,A
  JP Z,TrapTestBullet
  LD A,(Poking)
  AND A
  JP Z,TrapReloadFlags
  LD A,(PokeX)
  LD E,A
  LD HL,(PokeY)
  CALL PointInTrigger
  JP Z,TrapTriggered
TrapReloadFlags:
  LD A,(IX+$0B)
TrapTestBullet:
  BIT 5,A
  JP Z,TrapTestBlast
  LD A,(BulletObject)
  AND A
  JP Z,TrapReloadFlags2
  LD A,(BulletHitX)
  LD E,A
  LD HL,(BulletHitY)
  CALL PointInTrigger
  JP NZ,TrapReloadFlags2
  XOR A
  LD (BulletObject),A
  JP TrapTriggered
TrapReloadFlags2:
  LD A,(IX+$0B)
TrapTestBlast:
  BIT 4,A
  RET Z
  LD A,(BlastOn)
  AND A
  RET Z
  LD A,(BlastX)
  LD E,A
  LD HL,(BlastY)
  CALL PointInTrigger
  RET NZ
TrapTriggered:
  LD A,(IX+$00)
  AND $7F
  BIT 3,(IX+$0B)
  JP Z,TrapSetType
  OR $80
TrapSetType:
  LD (IX+$00),A
  LD (IX+$18),$01
  LD (IX+$19),$00
  LD A,(IX+$14)
  LD (IX+$16),A
  LD A,(IX+$15)
  LD (IX+$17),A
  LD A,$03
  CALL PlayEffect
  RET

; Kinds 4, 7, 10, 13: an enemy walking to and fro
;
; Clears TracksRick $F173 and goes to EnemyCommon $EFDB.
;
; Witness: L1 25331 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2,
; L2Z4, L2Z5, L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1, level2, level4, spotL1Z4-43,
; spotL1Z4-44, spotL1Z4-47).
PatrolObj:
  XOR A
  LD (TracksRick),A
  JP EnemyCommon

; Kinds 5, 8, 11, 14: an enemy that turns towards Rick
;
; Sets TracksRick $F173 = `$FF` and falls into EnemyCommon $EFDB.
;
; Witness: L1 14644 (c1, L1Z3, L1Z4, L2Z5, L2Z6, L3Z2-L3Z4, L3Z6-L3Z9, L3Z11,
; L3Z12, L4Z2-L4Z8, level1, level2).
TrackerObj:
  OR $FF
  LD (TracksRick),A

; An enemy: fall and walk, die by the bullet or blast, stunned by the stick
;
; The patrollers and trackers (kinds 4, 5, 7, 8, 10, 11, 13, 14); the climbers
; run ClimberObj $F233. EnemyFall $F02F; `$F812` (HitsObstacle: object 0 or a
; deadly actor) Z kills it (KillEnemy $F17C). The bullet (the point BulletX, +
; `$18` when BulletDx is positive, and BulletY, `$F742`) kills it and is used
; up; the blast (`$F76F`) kills it. The stick (`$FD63`, `$F742` at `$FD64` /
; `$FD65`) stuns it: +29 = 20 passes.
;
; Witness: L1 39975 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2,
; L2Z4-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1, level2, level4, spotL1Z4-43,
; spotL1Z4-44, spotL1Z4-47).
EnemyCommon:
  CALL EnemyFall
  CALL HitsObstacle
  JP Z,KillEnemy
  LD A,(BulletObject)
  AND A
  JP Z,EnemyTestBlast
  LD A,(BulletX)
  LD E,A
  LD A,(BulletDx)
  AND A
  LD A,$00
  JP M,EnemyBulletPoint
  LD A,$18
EnemyBulletPoint:
  ADD A,E
  LD E,A
  LD HL,(BulletY)
  CALL PointInObject
  JP NZ,EnemyTestBlast
  XOR A
  LD (BulletObject),A
  JP KillEnemy
EnemyTestBlast:
  LD A,(BlastOn)
  AND A
  JP Z,EnemyTestStick
  CALL InBlast
  JP Z,KillEnemy
EnemyTestStick:
  LD A,(Poking)
  AND A
  RET Z
  LD A,(PokeX)
  LD E,A
  LD HL,(PokeY)
  CALL PointInObject
  RET NZ
  LD A,$14
  LD (IX+$1D),A
  RET

; Fall under gravity until on a floor, then walk
;
; y += y speed (+27/28, 8.8, +`$80` a pass up to `$0800`); at `$12D` and below
; the enemy goes (EnemyGone). `$F5D5` probes the map at (x, y): its result
; `$F6A8` bits 4-7 a floor, bit 2 a deadly cell (KillEnemy $F17C). Falling:
; touching Rick kills him (`$FBED`), the frame is base + `$7E`.
;
; On a floor: y snapped to 8n + 3, speed `$0080`, mirror by +24's sign, the
; walk frame EnemyWalkFrames[x bits 2-3]. A stunned enemy (+29) counts down and
; only kills Rick on touch. Else it steps +24 (2 or -2) along x within 0-`$E7`,
; turning at a wall or a ledge (`$F6A8`), after +12 / 2 steps, or (TracksRick)
; towards RickX when x AND `$1E` = `$10`.
;
; Witness: L1 39975 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2,
; L2Z4-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1, level2, level4, spotL1Z4-43,
; spotL1Z4-44, spotL1Z4-47).
EnemyFall:
  LD L,(IX+$1A)
  LD H,(IX+$02)
  LD D,(IX+$03)
  LD C,(IX+$1B)
  LD B,(IX+$1C)
  XOR A
  BIT 7,B
  JP Z,EnemyFallAdd
  DEC A
EnemyFallAdd:
  ADD HL,BC
  ADC A,D
  LD D,L
  LD L,H
  LD H,A
  LD A,H
  AND A
  JP Z,EnemyFallProbe
  LD A,L
  CP $2D
  JP NC,EnemyGone
EnemyFallProbe:
  LD E,(IX+$01)
  CALL ProbeBox
  LD A,(ProbeResult)
  AND $F0
  JP NZ,EnemyOnFloor
  LD A,(ProbeResult)
  AND $04
  JP NZ,KillEnemy
  LD (IX+$02),L
  LD (IX+$03),H
  LD (IX+$1A),D
  LD L,(IX+$1B)
  LD H,(IX+$1C)
  LD BC,$0080
  ADD HL,BC
  LD A,H
  CP $08
  JP C,EnemyFallStoreSpeed
  LD HL,$0800
EnemyFallStoreSpeed:
  LD (IX+$1B),L
  LD (IX+$1C),H
  CALL RickTouches
  JP Z,KillRick
  LD L,(IX+$12)
  LD H,(IX+$13)
  LD BC,$007E
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  RET
EnemyOnFloor:
  LD HL,EnemyWalkFrames
  LD (IX+$06),$00
  BIT 7,(IX+$18)
  JP Z,EnemyWalkFrame
  LD (IX+$06),$FF
EnemyWalkFrame:
  LD A,(IX+$01)
  AND $0C
  SRL A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD L,(IX+$12)
  LD H,(IX+$13)
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$1B),$80
  LD (IX+$1C),$00
  LD A,(IX+$02)
  AND $F8
  OR $03
  LD (IX+$02),A
  LD A,(IX+$1D)
  AND A
  JP Z,EnemyWalk
  DEC A
  LD (IX+$1D),A
  CALL RickTouches
  JP Z,KillRick
  RET
EnemyWalk:
  LD A,(IX+$18)
  AND A
  JP NZ,EnemyWalkDir
  LD A,$02
  LD (IX+$18),A
EnemyWalkDir:
  AND A
  JP P,EnemyWalkRight
  ADD A,(IX+$01)
  JP C,EnemyWalkProbe
  JP EnemyTurn
EnemyWalkRight:
  ADD A,(IX+$01)
  CP $E8
  JP NC,EnemyTurn
EnemyWalkProbe:
  LD E,A
  LD L,(IX+$02)
  LD H,(IX+$03)
  CALL ProbeBox
  LD A,(ProbeResult)
  AND $F0
  JP NZ,EnemyTurn
  LD A,(ProbeResult)
  BIT 2,A
  JP NZ,KillEnemy
  LD (IX+$01),E
  CALL RickTouches
  CALL Z,KillRick
  LD A,(TracksRick)
  AND A
  JP Z,EnemyPatrolCount
  LD A,(IX+$01)
  LD C,A
  AND $1E
  CP $10
  RET NZ
  LD A,(RickX)
  CP C
  LD (IX+$18),$FE
  RET C
  LD (IX+$18),$02
  RET
EnemyPatrolCount:
  LD A,(IX+$0C)
  SRL A
  LD C,A
  LD A,(IX+$19)
  INC A
  LD (IX+$19),A
  CP C
  RET C
EnemyTurn:
  LD (IX+$19),$00
  LD A,(IX+$18)
  NEG
  LD (IX+$18),A
  RET

; $FF: the enemy turns towards Rick (TrackerObj $EFD6); 0: it patrols
; (PatrolObj $EFCF)
TracksRick:
  DEFB $01

; walk frames, offsets from the frame base, by x bits 2-3
EnemyWalkFrames:
  DEFW $0000
  DEFW $007E
  DEFW $0000
  DEFW $00FC

; An enemy is hit: it flies up and falls out of the zone
;
; Effect 11, type `$47`, y speed `$FC00` (up), the score `$A9D3` added
; (`$A9E8`), MarkObjectDone for a one-shot enemy, and the sideways drift +24 =
; 3, or -3 on the right half of the screen.
;
; Run 5 times in c1 and level1, 4 in level2, 2 in level4 (the `$F17E` effect
; counts).
;
; Witness: L1 21 (c1, L2Z6, L3Z2, L3Z11, L4Z2, level1, level2, level4).
KillEnemy:
  LD A,$0B
  CALL PlayEffect
  LD (IX+$00),$47
  LD (IX+$1B),$00
  LD (IX+$1C),$FC
  LD DE,Award50+$0004
  CALL AddScore
  BIT 0,(IX+$0B)
  JP Z,KillEnemyDrift
  LD L,(IX+$09)
  LD H,(IX+$0A)
  INC HL
  SET 7,(HL)
KillEnemyDrift:
  LD (IX+$18),$03
  LD A,(IX+$01)
  CP $80
  RET C
  LD (IX+$18),$FD
  RET
; This entry point is used by the routine at EnemyFall.
EnemyGone:
  LD (IX+$00),$00
  RET

; Kind $47: a killed enemy tumbling out of the zone
;
; The frame base + `$17A`, mirrored every other pass; y += y speed (gravity
; `$80` a pass); x += the drift within 0-`$E8`. Gone when y leaves 0-`$FF`.
;
; Witness: L1 582 (c1, L2Z6, L3Z2, L3Z11, L4Z2, level1, level2, level4).
DyingEnemyObj:
  LD BC,$017A
  LD A,(IX+$19)
  CPL
  LD (IX+$19),A
  AND A
  LD (IX+$06),$00
  JP P,DyingFrame
  LD (IX+$06),$FF
DyingFrame:
  LD L,(IX+$12)
  LD H,(IX+$13)
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  LD L,(IX+$1A)
  LD H,(IX+$02)
  LD D,(IX+$03)
  LD C,(IX+$1B)
  LD B,(IX+$1C)
  XOR A
  BIT 7,B
  JP Z,DyingFall
  DEC A
DyingFall:
  ADD HL,BC
  ADC A,D
  AND A
  JP Z,DyingStore
  LD (IX+$00),$00
  RET
DyingStore:
  LD (IX+$1A),L
  LD (IX+$02),H
  LD (IX+$03),A
  LD L,(IX+$1B)
  LD H,(IX+$1C)
  LD BC,$0080
  ADD HL,BC
  LD (IX+$1B),L
  LD (IX+$1C),H
  LD A,(IX+$18)
  AND A
  JP P,DyingRight
  ADD A,(IX+$01)
  LD (IX+$01),A
  RET C
  LD (IX+$01),$00
  RET
DyingRight:
  ADD A,(IX+$01)
  LD (IX+$01),A
  RET NC
  LD (IX+$01),$E8
  RET

; Kinds 6, 9, 12, 15: an enemy that climbs towards Rick
;
; ClimberMove $F266; touching Rick kills him; `$F812` Z kills it; the bullet
; kills it.
;
; Run in every level, most in level4 (3517 passes), where it climbs
; (ClimberState).
;
; Witness: L1 15799 (c1, L1Z3, L1Z4, L2Z2-L2Z6, L3Z2, L3Z5, L3Z11, L4Z1-L4Z8,
; level1-level4).
ClimberObj:
  CALL ClimberMove
  CALL RickTouches
  CALL Z,KillRick
  CALL HitsObstacle
  JP Z,KillEnemy
  LD A,(BulletObject)
  AND A
  RET Z
  LD A,(BulletX)
  LD E,A
  LD A,(BulletDx)
  AND A
  LD A,$00
  JP M,ClimberBulletPoint
  LD A,$18
ClimberBulletPoint:
  ADD A,E
  LD E,A
  LD HL,(BulletY)
  CALL PointInObject
  RET NZ
  XOR A
  LD (BulletObject),A
  JP KillEnemy

; Climber: the blast and the stick, then climb or fall
;
; The blast kills it; the stick stuns it (+29 = 20); a stunned climber counts
; down and stays. +24 = 0: it falls (ClimberFall $F362). Else it climbs: frame
; base + `$1F8`, mirrored by y bit 2; level with RickY (even): one step of 2
; towards RickX; else 2 up or down towards RickY while the map (`$F5D5`)
; allows; off the ladder +24 = 0.
;
; The climb ran only in level4 (869 passes): known from the code and that
; recording.
;
; Witness: L1 15799 (c1, L1Z3, L1Z4, L2Z2-L2Z6, L3Z2, L3Z5, L3Z11, L4Z1-L4Z8,
; level1-level4).
ClimberMove:
  LD A,(BlastOn)
  AND A
  JP Z,ClimberTestStick
  CALL InBlast
  JP Z,KillEnemy
ClimberTestStick:
  LD A,(Poking)
  AND A
  JP Z,ClimberStunned
  LD A,(PokeX)
  LD E,A
  LD HL,(PokeY)
  CALL PointInObject
  JP NZ,ClimberStunned
  LD A,$14
  LD (IX+$1D),A
ClimberStunned:
  LD A,(IX+$1D)
  AND A
  JP Z,ClimberState
  DEC (IX+$1D)
ClimberState:
  LD A,(IX+$18)
  AND A
  JP Z,ClimberFall
  LD A,(IX+$1D)
  AND A
  RET NZ
  LD BC,$01F8
  LD (IX+$06),$00
  LD A,(IX+$02)
  XOR (IX+$01)
  AND $04
  JP Z,ClimberFrame
  LD (IX+$06),$FF
ClimberFrame:
  LD L,(IX+$12)
  LD H,(IX+$13)
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  LD HL,(RickY)
  LD A,L
  AND $FE
  LD L,A
  LD A,(IX+$02)
  AND $FE
  LD E,A
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  JP NZ,ClimberVertical
  EX DE,HL
ClimberSideStep:
  LD E,(IX+$01)
  LD A,(RickX)
  CP E
  LD A,$02
  JP NC,ClimberSideStore
  NEG
ClimberSideStore:
  LD (IX+$19),A
  ADD A,E
  LD E,A
  CALL ProbeBox
  LD A,(ProbeResult)
  AND $70
  RET NZ
  LD A,(ProbeResult)
  AND $04
  JP NZ,KillEnemy
  LD (IX+$01),E
  LD A,(ProbeResult)
  AND $82
  RET NZ
  JP ClimberStop
ClimberVertical:
  LD HL,$0002
  JP NC,ClimberVStep
  LD HL,-2
ClimberVStep:
  PUSH HL
  ADD HL,DE
  LD A,H
  AND A
  JP Z,ClimberVProbe
  DEC A
  JP Z,ClimberLowEdge
ClimberGone:
  LD (IX+$00),$00
  RET
ClimberLowEdge:
  LD A,L
  CP $2A
  JP NC,ClimberGone
ClimberVProbe:
  LD E,(IX+$01)
  CALL ProbeBox
  POP BC
  LD A,(ProbeResult)
  AND $70
  JP Z,ClimberVStore
  BIT 7,B
  JP NZ,ClimberVBlocked
  LD (IX+$18),$00
  JP ClimberFall
ClimberVBlocked:
  LD L,(IX+$02)
  LD H,(IX+$03)
  JP ClimberSideStep
ClimberVStore:
  LD A,(ProbeResult)
  LD (IX+$02),L
  LD (IX+$03),H
  AND $82
  RET NZ
ClimberStop:
  LD (IX+$18),$00
  JP ClimberFall

; Climber: fall under gravity; on a ladder above Rick start climbing
;
; As EnemyFall: y speed with gravity, a deadly cell kills it, at `$12A` and
; below it goes. On a ladder cell (`$F6A8` bit 7) at x AND 7 = 4 and above
; RickY: +24 = 1, climbing. The rest of the routine is in the next fragment.
;
; Witness: L1 11684 (c1, L1Z3, L1Z4, L2Z2-L2Z6, L3Z2, L3Z5, L3Z11, L4Z1-L4Z8,
; level1-level4).
ClimberFall:
  LD L,(IX+$1A)
  LD H,(IX+$02)
  LD D,(IX+$03)
  LD C,(IX+$1B)
  LD B,(IX+$1C)
  XOR A
  BIT 7,B
  JP Z,ClimberFallAdd
  DEC A
ClimberFallAdd:
  ADD HL,BC
  ADC A,D
  LD D,L
  LD L,H
  LD H,A
  LD E,(IX+$01)
  CALL ProbeBox
  LD A,(ProbeResult)
  AND $70
  JP NZ,WalkerOnFloor
  LD A,(ProbeResult)
  AND $04
  JP NZ,KillEnemy
  LD A,H
  AND A
  JP Z,ClimberFallLand
  LD A,L
  CP $2A
  JP C,ClimberFallLand
  LD (IX+$00),$00
  RET
ClimberFallLand:
  LD A,(ProbeResult)
  AND $80
  JP Z,ClimberFallStore
  LD A,(IX+$01)
  AND $07
  CP $04
  JP NZ,WalkerOnFloor
  LD DE,(RickY)
  OR A
  SBC HL,DE
  JP NC,WalkerOnFloor
  LD (IX+$18),$01
  RET
ClimberFallStore:
  LD (IX+$02),L
  LD (IX+$03),H
  LD (IX+$1A),D
  LD L,(IX+$1B)
  LD H,(IX+$1C)
  LD BC,$0080
  ADD HL,BC
  LD A,H
  CP $08
  JP C,ClimberFallStoreSpeed
  LD HL,$0800
ClimberFallStoreSpeed:
  LD (IX+$1B),L
  LD (IX+$1C),H
  LD (IX+$06),$00
  LD A,(IX+$19)
  LD BC,$007E
  AND A
  JP P,ClimberFallFrame
  LD (IX+$06),$FF
ClimberFallFrame:
  LD L,(IX+$12)
  LD H,(IX+$13)
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  RET
WalkerOnFloor:
  LD A,(IX+$02)           ; landed: Y to the row + 3, Y velocity $0100; +$1D
                          ; nonzero: stay
  AND $F8
  OR $03
  LD (IX+$02),A
  LD (IX+$1B),$00
  LD (IX+$1C),$01
  LD A,(IX+$1D)
  AND A
  RET NZ
  LD A,(ProbeResult)      ; on a ladder (probe bit 1) at X AND $0E = 4 with
                          ; Rick above: +$18 = 1 (go up the ladder)
  AND $02
  JP Z,WalkerWalk
  LD A,(IX+$01)
  AND $0E
  CP $04
  JP NZ,WalkerWalk
  LD HL,(RickY)
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  JP NC,WalkerWalk
  LD (IX+$18),$01
  RET
WalkerWalk:
  LD A,(IX+$01)           ; frame from the speed table $F174 by X AND 6; facing
                          ; from the sign of +$19
  AND $06
  LD C,A
  LD B,$00
  LD HL,EnemyWalkFrames
  LD (IX+$06),$00
  BIT 7,(IX+$19)
  JP Z,WalkerFrame
  LD (IX+$06),$FF
WalkerFrame:
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD L,(IX+$12)
  LD H,(IX+$13)
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$19)           ; X velocity 0: start walking right (+2)
  AND A
  JP NZ,WalkerStepX
  LD (IX+$19),A
  LD A,$02
WalkerStepX:
  AND A
  JP P,WalkerStepRight
  ADD A,(IX+$01)
  JP C,WalkerTryStep
  JP WalkerTurn
WalkerStepRight:
  ADD A,(IX+$01)          ; X + velocity >= $E8: turn
  CP $E8
  JP NC,WalkerTurn
WalkerTryStep:
  LD E,A                  ; probe the new X; a solid char ($F0 bits): turn
  LD L,(IX+$02)
  LD H,(IX+$03)
  CALL ProbeBox
  LD A,(ProbeResult)
  AND $F0
  JP NZ,WalkerTurn
  LD (IX+$01),E
  LD A,E
  AND $1E
  CP $08
  RET NZ
  CALL Random             ; X AND $1E = 8: a random new direction (bit 0 of
                          ; $E441)
  AND $01
  LD E,$02
  JP Z,WalkerSetDir
  LD E,$FE
WalkerSetDir:
  LD (IX+$19),E
  RET
WalkerTurn:
  LD A,(IX+$19)           ; X velocity negated (0 becomes +2)
  NEG
  JP NZ,WalkerSetVel
  LD A,$02
WalkerSetVel:
  LD (IX+$19),A
  RET

; Kind 22: Rick touches it, the timed bonus starts
;
; Handler of object kind 22 (the pointer at `$EC73` of the kind table). IX =
; the object. It hides the sprite (+4/+5 =
;
; 0) and tests the point (Rick X + 12, Rick Y + 10) against the object's
; trigger box (PointInTrigger `$F7C3`). Inside:
;
; the object is freed (+0 = 0), BonusActive `$FD6C` = `$FF` (the countdown at
; `$E466` then runs), the bonus digits
;
; `$E496-$E49A` are cleared and `$E497` = 2, and sound effect 10 plays
; (`$9FED`).
;
; Outputs: none. Side effects: `$FD6C`, `$E496-$E49A`, the object.
;
; Evidence: the bonus started (`$F4E2`) in c1 1, controls 7, gameover 6, level1
; 7, level2 3 times.
;
; Witness: L1 5910 (beeper48, c1, controls, gameover, spotL2Z4-34, L1Z1, L1Z3,
; L1Z4, L2Z1, L2Z2, L2Z4, L2Z5, L3Z5, L3Z11, L3Z12, L4Z3, L4Z4, level1,
; level2).
BonusTrigger:
  LD (IX+$04),$00
  LD (IX+$05),$00
  LD A,(RickX)
  ADD A,$0C
  LD E,A
  LD A,(RickY)
  ADD A,$0A
  LD L,A
  LD H,$00
  CALL PointInTrigger
  RET NZ
  LD (IX+$00),$00
  LD A,$FF
  LD (BonusActive),A
  LD HL,$0000
  LD (BonusDigits),HL
  LD (BonusDigits+$0002),HL
  LD (BonusDigits+$0003),HL
  LD A,$02
  LD (BonusDigits+$0001),A
  LD A,$0A
  CALL PlayEffect
  RET

; Kind 23: Rick reaches it while the bonus runs
;
; Handler of object kind 23 (the pointer at `$EC75`). IX = the object. The
; sprite is hidden; nothing more while
;
; BonusActive `$FD6C` is 0. With the bonus running, Rick's point (X + 12, Y +
; 10) inside the trigger box
;
; (PointInTrigger `$F7C3`) clears `$FD6C`, frees the object, adds the bonus
; digits at `$E49A` to the score (`$A9E8`,
;
; DE = `$E49A`) and plays tune 7 (`$A016`).
;
; Side effects: `$FD6C`, the score, the music.
;
; Evidence: collected (`$F521`) once each in c1 and level1.
;
; Witness: L1 5972 (c1, spotL2Z4-34, L1Z2-L1Z4, L2Z2-L2Z5, L2Z7, L3Z6, L3Z7,
; L3Z12, L4Z5, L4Z6, level1, level2, spotL1Z4-44).
BonusCollect:
  LD (IX+$04),$00
  LD (IX+$05),$00
  LD A,(BonusActive)
  AND A
  RET Z
  LD A,(RickX)
  ADD A,$0C
  LD E,A
  LD A,(RickY)
  ADD A,$0A
  LD L,A
  LD H,$00
  CALL PointInTrigger
  RET NZ
  XOR A
  LD (BonusActive),A
  LD (IX+$00),$00
  LD DE,BonusDigits+$0004
  CALL AddScore
  LD A,$07
  CALL StartTune
  RET

; Z when the point (A, L) is free: no wall char and not inside object 0
;
; Inputs: A = X, L = Y (pixels; row Y / 8 of the playfield map `$6500`, 32
; columns). It reads the char at the point,
;
; its property at `$5C00` + code, and returns NZ (A = `$40`) on bit 6 (wall).
; Else, with object 0 `$EA8E` present,
;
; it tests the point against its box (PointInObject `$F742`): inside gives NZ
; (A = 1), outside Z (A = 0).
;
; Outputs: Z/NZ, A, E = X. Preserves HL, D; uses BC.
;
; Evidence: the object 0 test (`$F566`) ran only in level2 (6).
;
; Witness: L1 542 (beeper48, c1, emptygun, L1Z5, L2Z1, L2Z6, L3Z x7, L4Z3,
; L4Z4, L4Z8, L4Z9, level1-level4).
IsSolidAt:
  PUSH HL
  LD E,A
  PUSH DE
  LD A,L
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  SRL E
  SRL E
  SRL E
  LD A,E
  OR L
  LD L,A
  LD BC,$6500
  ADD HL,BC
  LD B,$5C
  LD C,(HL)
  LD A,(BC)
  AND $40
  POP DE
  POP HL
  RET NZ
  LD A,(ObjectTable)
  AND A
  RET Z
  PUSH IX
  LD IX,ObjectTable
  CALL PointInObject
  POP IX
  JP Z,IsSolidAtYes
  XOR A
  RET
IsSolidAtYes:
  INC A
  RET

; The probe of a crawling object: properties of the chars under its box, the
; top row apart
;
; The low twin of ProbeBox `$F5D5` (B = 1 row less: the box of a crawling
; Rick). Inputs: E = X, HL = Y of the box's
;
; top (pixels). The box is 2 columns wide when X + 4 is a multiple of 8, else
; 3. The top row's properties (AND
;
; `$F0`) go to ProbeLowResult `$F6A7`; then the rows below are scanned by
; ProbeBoxAligned `$F602` or
;
; ProbeBoxUnaligned `$F654`, which leave the OR of all rows in ProbeResult
; `$F6A8` and add object 0 (ProbeBoxObject0
;
; `$F624`).
;
; Outputs: `$F6A7`, `$F6A8`, A. Preserves DE, HL.
;
; Evidence: both widths ran (`$F59A` aligned, `$F5B4` unaligned) in c1 and
; level1-level4 (level2 1091).
;
; Witness: L1 6062 (beeper48, c1, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4).
ProbeLow:
  PUSH DE
  PUSH HL
  XOR A
  LD (ProbeLowResult),A
  LD A,$04
  ADD A,E
  LD E,A
  LD B,$01
  BIT 2,L
  JP Z,ProbeLowRowAddr
  INC B
ProbeLowRowAddr:
  LD A,L                  ; HL = $6500 + (Y AND $F8) * 4 + (X + 4) / 8
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,E
  SRL A
  SRL A
  SRL A
  OR L
  LD L,A
  LD A,H
  ADD A,$65
  LD H,A
  LD C,$00
  LD A,E
  AND $07
  JP NZ,ProbeLowUnaligned
  LD D,$5C
  LD E,(HL)
  LD A,(DE)
  AND $F0
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $F0
  OR C
  LD (ProbeLowResult),A
  LD C,$00
  LD DE,$001F
  ADD HL,DE
  JP ProbeBoxAligned
ProbeLowUnaligned:
  LD D,$5C                ; X + 4 not a multiple of 8: 3 columns
  LD E,(HL)
  LD A,(DE)
  AND $F0
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $F0
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $F0
  OR C
  LD (ProbeLowResult),A
  LD C,$00
  LD DE,$001E
  ADD HL,DE
  JP ProbeBoxUnaligned

; The OR of the char properties under an object's box, into ProbeResult
;
; Inputs: E = X, HL = Y of the box's top (pixels; the box of Rick and the
; walkers: B = 2 rows above the bottom one, 3
;
; when Y AND 4). X + 4 a multiple of 8: 2 columns (ProbeBoxAligned `$F602`),
; else 3 (ProbeBoxUnaligned `$F654`). The
;
; upper rows count without bits 4 and 7 (platform, floor), the edge columns
; without bit 1 (ladder): a ladder counts
;
; only under the middle, a floor or platform only under the feet.
;
; Outputs: ProbeResult `$F6A8` = A, with bit 6 added when the box overlaps
; object 0 `$EA8E` (ProbeBoxObject0 `$F624`).
;
; Preserves DE, HL. Callers: the walkers (`$F362`), MoveRick `$F85D`, WalkRick
; `$F903`, ClimbRick `$FB14`.
;
; Witness: L1 142633 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ProbeBox:
  PUSH DE
  PUSH HL
  XOR A
  LD (ProbeResult),A
  LD A,$04
  ADD A,E
  LD E,A
  LD B,$02
  BIT 2,L
  JP Z,ProbeBoxRowAddr
  INC B
ProbeBoxRowAddr:
  LD A,L
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,E
  SRL A
  SRL A
  SRL A
  OR L
  LD L,A
  LD A,H
  ADD A,$65
  LD H,A
  LD C,$00
  LD A,E
  AND $07
  JP NZ,ProbeBoxUnaligned

; ProbeBox's rows for a box 2 columns wide
;
; Part of ProbeBox `$F5D5` and ProbeLow `$F56D`, reached by their jumps, not
; called. B rows of 2 chars AND `$6F`,
;
; then the bottom row with every bit, into ProbeResult `$F6A8`; on into
; ProbeBoxObject0 `$F624`.
;
; Witness: L1 105462 (beeper48, c1, controls, ending2, gameover, l1z1left,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ProbeBoxAligned:
  LD D,$5C
  LD E,(HL)
  LD A,(DE)
  AND $6F
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $6F
  OR C
  LD C,A
  LD DE,$001F
  ADD HL,DE
  DJNZ ProbeBoxAligned
  LD D,$5C
  LD E,(HL)
  LD A,(DE)
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  OR C
  LD (ProbeResult),A

; ProbeBox's tail: add object 0 as a wall
;
; Pops HL, DE. A wall already found (bit 6): return. With object 0 `$EA8E`
; present, its box against the probe's
;
; (ProbeRecord `$F689` as the IY object, ObjectsOverlap `$F6E9`): an overlap
; sets bit 6 of ProbeResult `$F6A8`.
;
; Outputs: A = `$F6A8`.
;
; Evidence: object 0 overlapped the probe (`$F64E`) once, in level2; the test
; (`$F643`) ran in level2 and level3 only.
;
; Witness: L1 148695 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ProbeBoxObject0:
  POP HL
  POP DE
  BIT 6,A
  RET NZ
  LD A,(ObjectTable)
  AND A
  RET Z
  PUSH HL
  PUSH DE
  PUSH IX
  LD IY,ProbeRecord
  LD (IY+$01),E
  LD (IY+$02),L
  LD (IY+$03),H
  LD IX,ObjectTable
  CALL ObjectsOverlap
  POP IX
  POP DE
  POP HL
  LD A,(ProbeResult)
  RET NZ
  OR $40
  LD (ProbeResult),A
  RET

; ProbeBox's rows for a box 3 columns wide
;
; B rows of 3 chars, the edges AND `$6D`, the middle AND `$6F`; the bottom row:
; edges AND `$7D`, the middle whole.
;
; Into ProbeResult `$F6A8`, then JP ProbeBoxObject0 `$F624`.
;
; Witness: L1 267099 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ProbeBoxUnaligned:
  LD D,$5C
  LD E,(HL)
  LD A,(DE)
  AND $6D
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $6F
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $6D
  OR C
  LD C,A
  LD DE,$001E
  ADD HL,DE
  DJNZ ProbeBoxUnaligned
  LD D,$5C
  LD E,(HL)
  LD A,(DE)
  AND $7D
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  OR C
  LD C,A
  INC HL
  LD E,(HL)
  LD A,(DE)
  AND $7D
  OR C
  LD (ProbeResult),A
  JP ProbeBoxObject0

; The probe's box as an object record (IY) for ObjectsOverlap
;
; ProbeBoxObject0 `$F624` writes +1 (X) and +2/+3 (Y) and hands it to
; ObjectsOverlap `$F6E9` as IY; the other fields
;
; are never read (0 in the image).
ProbeRecord:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00    ; +4-+$1D: not used
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00
ProbeLowResult:
  DEFB $00                ; ProbeLow's top row (AND $F0); MoveRick reads it
                          ; while crawling
ProbeResult:
  DEFB $00                ; the OR of the properties under the box (+ bit 6 for
                          ; object 0)

; Fill the char property table $5C00 from 8 run-length pairs
;
; Input: DE = 8 pairs (count, property), 256 chars in all (CharPropsSet0
; `$F6C0` or CharPropsSet1 `$F6D0`). Writes
;
; `$5C00-$5CFF`, one property per char code (bits: this module's header).
; Called by the zone setup at `$ACCF`, which
;
; picks the set from the zone record's byte +0 (0: `$F6C0` with the tiles at
; `$7100`; else `$F6D0`, tiles `$7A00`).
;
; Outputs: none. Uses AF', B, C (shifted, unused), DE, HL.
;
; Evidence: c1 7, controls 11, gameover 7, level1 19, level2 5, level3 7,
; level4 30 zone setups.
;
; Witness: L1 439 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
BuildCharProps:
  LD HL,SystemVariables
  LD A,$08
BuildCharPropsPair:
  EX AF,AF'
  LD A,(DE)
  LD B,A
  INC DE
  LD A,(DE)
BuildCharPropsFill:
  LD (HL),A
  INC L
  DJNZ BuildCharPropsFill
  SLA C
  INC DE
  EX AF,AF'
  DEC A
  JP NZ,BuildCharPropsPair
  RET

; Char properties of the first tile set: (count, property) x 8
;
; Chars 0-76 nothing, 77-90 ladder, 91-94 deadly, 95-181 bit 3, 182-189
; platform, 190-192 spring + wall, 193-251
;
; wall, 252-255 floor (bit 7: also a ladder top, DownFloorTest $FAE6).
CharPropsSet0:
  INCBIN "res/levels/charprops.bin",$0000,16

; Char properties of the second tile set: 0-54 nothing, 55-58 ladder, 59-62
; deadly, 63-206 bit 3, 207-215 platform, 216 spring + wall, 217-249 wall,
; 250-255 floor (also a ladder top)
CharPropsSet1:
  INCBIN "res/levels/charprops.bin",$0010,16

; Does the IX object overlap Rick? Never while Rick dies
;
; Called by the object handlers with IX = the object. Rick dying (`$FD68`
; nonzero): NZ at once. Else IY = Rick
;
; `$EAAC` and on into ObjectsOverlap `$F6E9`.
;
; Outputs: Z = overlap. Uses IY, A, BC, DE, HL.
;
; Witness: L1 113605 (beeper48, c1, controls, ending2, gameover, l1end,
; spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12,
; L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
RickTouches:
  LD A,(Dying)
  AND A
  RET NZ
  LD IY,RickObject

; Z when the IY object's body box overlaps the IX object's box
;
; IY's box (a Rick-sized body): X from IY+1 + 5 to IY+1 + 17, Y from IY+2/+3 (8
; lower when IY is Rick, kind 1,
;
; crawling: `$FD5A`) to IY+2/+3 + 20. IX's box: X from IX+1 to + width (+7), Y
; from IX+2/+3 to + height (+8) - 1.
;
; Outputs: Z and A = 0 on overlap, NZ and A = 1 else. Uses BC, DE, HL.
;
; Witness: L1 142755 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34,
; spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9,
; level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ObjectsOverlap:
  LD A,(IY+$01)
  ADD A,$11
  LD C,(IX+$01)
  CP C
  JP C,OverlapNo
  SUB $0C
  LD B,A
  LD A,C
  ADD A,(IX+$07)
  CP B
  JP C,OverlapNo
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD BC,$0014
  ADD HL,BC
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  JP C,OverlapNo
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD A,(IY+$00)
  CP $01
  JP NZ,OverlapY
  LD A,(Crawling)
  AND A
  JP Z,OverlapY
  LD BC,$0008
  ADD HL,BC
OverlapY:
  EX DE,HL
  LD C,(IX+$08)
  LD B,$00
  DEC BC
  ADD HL,BC
  OR A
  SBC HL,DE
  JP C,OverlapNo
  XOR A
  RET
OverlapNo:
  XOR A
  INC A
  RET

; Z when the point (E, HL) is inside the IX object's box
;
; X strictly between IX+1 and IX+1 + width (+7), Y from IX+2/+3 to that +
; height (+8).
;
; Outputs: Z/NZ, A = 0 / 1. Uses BC, DE, HL.
;
; Witness: L1 718 (c1, L1Z4, L2Z1, L3Z x7, L4Z3-L4Z6, L4Z9, level1, level2,
; level4).
PointInObject:
  LD A,(IX+$01)
  CP E
  JP NC,PointInObjectNo
  ADD A,(IX+$07)
  CP E
  JP C,PointInObjectNo
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  JP C,PointInObjectNo
  ADD HL,DE
  EX DE,HL
  LD C,(IX+$08)
  LD B,$00
  ADD HL,BC
  OR A
  SBC HL,DE
  JP C,PointInObjectNo
  XOR A
  RET
PointInObjectNo:
  XOR A
  INC A
  RET

; Z when the IX object lies inside the dynamite's blast box
;
; The blast box: X from dynamite X (`$EAE9`) - 4 to that + 32, x + 28 (clamped
; to 0 and `$FF`), Y from dynamite Y (`$EAEA`) - 4
;
; (clamped to 0) to that + 29, y + 25: 33 x 30 pixels. The object's box: IX+1 /
; +7, IX+2/+3 / +8.
;
; Outputs: Z/NZ, A = 0 / 1. Uses BC, DE, HL.
;
; Witness: L1 1181 (beeper48, L1Z1, L1Z2, L2Z1, L2Z2, L2Z6, L2Z7, L3Z2, L3Z6,
; L3Z11, L4Z x5, level2, level3).
InBlast:
  LD A,(DynamiteX)
  SUB $04
  JP NC,InBlastRight
  XOR A
InBlastRight:
  LD C,A
  ADD A,$20
  JP NC,InBlastX
  LD A,$FF
InBlastX:
  LD B,(IX+$01)
  CP B
  JP C,InBlastNo
  LD D,A
  LD A,(IX+$07)
  ADD A,B
  CP C
  JP C,InBlastNo
  LD HL,(DynamiteX+$0001)
  LD BC,$FFFC
  ADD HL,BC
  BIT 7,H
  JP Z,InBlastY
  LD HL,$0000
InBlastY:
  PUSH HL
  LD BC,$001D
  ADD HL,BC
  LD E,(IX+$02)
  LD D,(IX+$03)
  OR A
  SBC HL,DE
  POP HL
  JP C,InBlastNo
  EX DE,HL
  LD C,(IX+$08)
  LD B,$00
  ADD HL,BC
  OR A
  SBC HL,DE
  JP C,InBlastNo
  XOR A
  RET
InBlastNo:
  XOR A
  INC A
  RET

; Z when the point (E, HL) is inside the IX object's trigger box
;
; The trigger box: X from IX+C, Y from IX+D/+E, its size from the kind's 8-byte
; record at `$D31C`: byte +6 the width
;
; and +7 the height, in chars (x 8; `$D322` = `$D31C` + 6). Used with Rick's
; point (X + 12, Y + 10) by the traps
;
; and BonusTrigger `$F4C8`, BonusCollect `$F502`.
;
; Outputs: Z/NZ, A = 0 / 1. Uses BC, DE, HL.
;
; Evidence: the Y half (`$F7EA`) ran in every game build (level3 1368).
;
; Witness: L1 55292 (beeper48, c1, controls, emptygun, gameover, l1z1left,
; spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1, L3Z2,
; L3Z5-L3Z12, L4Z1-L4Z8, level1-level4, spotL1Z4-43, spotL1Z4-47).
PointInTrigger:
  LD A,(IX+$0C)
  CP E
  JP NC,PointInTriggerNo
  PUSH HL
  LD D,A
  LD A,(IX+$00)
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,$D322
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD C,(HL)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,D
  JP NC,PointInTriggerY
  LD A,$FF
PointInTriggerY:
  CP E
  POP HL
  JP C,PointInTriggerNo
  LD E,(IX+$0D)
  LD D,(IX+$0E)
  OR A
  SBC HL,DE
  JP C,PointInTriggerNo
  ADD HL,DE
  EX DE,HL
  LD B,$00
  SLA C
  RL B
  SLA C
  RL B
  SLA C
  RL B
  ADD HL,BC
  OR A
  SBC HL,DE
  JP C,PointInTriggerNo
  XOR A
  RET
PointInTriggerNo:
  XOR A
  INC A
  RET

; Z when the IX object overlaps object 0 or an active object of the slots $EB06
;
; The IX object becomes IY; tested against object 0 `$EA8E` (when present) and
; the 5 slots from `$EB06` with bit 7
;
; of +0 set, by ObjectsOverlap `$F6E9`. IX is restored. An enemy's hit test:
; does object 0 or a deadly actor overlap it (callers EnemyCommon `$EFDE`,
; ClimberObj `$F23C`).
;
; Outputs: Z (A = 0) on a hit, NZ (A = 1) else. Uses BC, DE, HL, IY.
;
; Evidence: a hit on object 0 (`$F824`) in level2 and level3; on a slot
; (`$F83B`) in c1, level1, level2, level4.
;
; Witness: L1 55773 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6,
; L2Z2-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44,
; spotL1Z4-47).
HitsObstacle:
  PUSH IX
  POP IY
  LD A,(ObjectTable)
  AND A
  JP Z,HitsEnemyScan
  LD IX,ObjectTable
  CALL ObjectsOverlap
  JP Z,HitsYes
HitsEnemyScan:
  LD B,$05
  LD IX,ZoneObjects
HitsEnemyLoop:
  PUSH BC
  BIT 7,(IX+$00)
  JP Z,HitsEnemyNext
  CALL ObjectsOverlap
  JP NZ,HitsEnemyNext
  POP BC
HitsYes:
  PUSH IY
  POP IX
  XOR A
  RET
HitsEnemyNext:
  LD BC,$001E
  ADD IX,BC
  POP BC
  DJNZ HitsEnemyLoop
  PUSH IY
  POP IX
  XOR A
  INC A
  RET
