; --------------------------------------------------------------------------------------------------------------------
; player.asm: Hiro and the actors: movement, jump, fall, combat, pickups, weapons, Fireblade fragments
;
; The actor state machines of this range: the nine sequence slots +$30-$38 (scripts at $7A00-$7BFF), their start
; routines and step handlers (SequenceHandlers $73E7), and the state handlers the kind templates put at +$03/+$04
; (Hiro $9333 here; the enemy handlers in the enemies module).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8F01

; Hiro meets an invisible wall: stop his X step (D = 0) at the room's barrier X
;
; From MoveActor `$9B56` for Hiro only, D = his X step. BarrierFind `$8F28`
; looks the room `$6BDD` up in BarrierRooms `$76D2` (6 bytes: rooms `$7B` (123,
; Havok), `$5D`, `$3A`, 8, `$27`, and `$88`, which is no room) and returns if
; it is not there. With the room's flag (`$76D8`+i) bit 0 set, the barrier X
; (`$76DE`+i: `$34`, `$28`, `$30`, `$48`, `$88`, `$88`) and side (`$76E4`+i: 0,
; 0, 0, 1, 1, 1) apply: side 0 stops Hiro facing left, side 1 facing right
; (+`$1B` of `$5D00`, `$5D1B`), when his X (`$5D01`) equals the barrier X.
; BarrierOpen `$8F22` clears the flag.
;
; Witness: the RZX run's snapshot at frame 80 000 has the flags of rooms `$3A`
; and `$27` cleared (`work/stage2/rzx/snap-080000.z80`); deaths runs the test
; 95 times (in one of the rooms). Witness: L1 40810 (bossgate, deaths,
; gameover, havok, hiscore, menu, play48, rooms, throw, c x1, opt x3, poke-room
; x15, rzx x71, rzxroom x18).
RoomBarrier:
  CALL BarrierFind
  BIT 0,(HL)              ; no barrier up in this room
  RET Z
  INC C                   ; C = 6: the next parallel table
  ADD HL,BC
  LD A,(HL)
  ADD HL,BC
  BIT 0,(HL)
  LD C,A
  LD A,(Hiro+$001B)       ; Hiro's direction, bit 7 = left
  JR NZ,RoomBarrierRight  ; side 1: blocks moving right
  RLA
  RET NC
RoomBarrierAtX:
  LD HL,Hiro+$0001
  LD A,C
  CP (HL)
  RET NZ
  LD D,$00                ; at the barrier: no X step
  RET
RoomBarrierRight:
  RLA
  RET C
  JR RoomBarrierAtX

; Clear the current room's barrier flag (the wall goes away)
;
; BarrierFind `$8F28` (returns at once if the room has none), then (HL) = 0.
; Caller: `$97A8` (the routine at `$97A3`, outside this range). bossgate opens
; a giant's gate at frame 435 (its hit points POKEd to 1).
;
; Witness: L1 1 (bossgate).
BarrierOpen:
  CALL BarrierFind
  LD (HL),$00
  RET

; HL = the barrier flag of room $6BDD; returns from the caller too when the
; room has none
;
; CPIR over the six rooms at BarrierRooms `$76D2`; found: HL = the match + 6
; (`$76D8`+i, the flag) with BC = 5 and B = 0. Not found: `POP HL` drops the
; return address, so the `RET` leaves RoomBarrier `$8F01` or BarrierOpen
; `$8F22` as well.
;
; Witness: L1 40811 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
BarrierFind:
  LD A,(Room)
  LD HL,GateRooms
  LD BC,$0006
  CPIR
  JR NZ,BarrierNone
  LD C,$05
  ADD HL,BC
  RET
BarrierNone:
  POP HL                  ; drop the caller's return: no barrier here
  RET

  ORG $9023

; Up pressed: grab a ladder above, or start a jump (sequence +$30)
;
; From WalkStep `$9B05` when the Y step E is negative (Hiro's up; the enemies'
; walks never step up). HL = IY = the actor, D = the X step.
;
; Standing (D = 0): `$9CA7` tests the cell 20 above (one row up) against the
; two ladder codes at `$73C5` (`$55`, `$54`) with X at a multiple of 8; a
; ladder goes to GrabLadder `$906C`. Otherwise the jump script: `$7B00`
; straight up (11 steps), `$7A51` running (12 steps), `$7A7A` when the run
; counter +`$24` is 4 or more (16 steps, the long jump); SequenceHeader `$919C`
; with L = `$30`, then the first step JumpStep `$9225`.
;
; Witness: L1 885 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c
; x1, opt x3, rzx x64, rzxroom x9).
ActorJump:
  LD A,D
  OR A
  JR NZ,ActorJumpScript
  CALL LadderAbove        ; a ladder above?
  OR A
  JP NZ,GrabLadder
ActorJumpScript:
  LD BC,StandScript       ; the straight jump
  LD A,D
  OR A
  JR Z,ActorJumpStart
  LD BC,WalkScript        ; the running jump
  LD L,$24
  LD A,(HL)
  CP $04
  JR C,ActorJumpStart
  LD BC,RunScript         ; a run of 4 steps or more: the long jump
ActorJumpStart:
  LD L,$30                ; sequence +$30
  CALL SequenceHeader
  JP JumpMove

; +$10 bit 4 (hurt): the push-back sequence +$31; Hiro on a ladder leaves it
; (LeaveLadder)
;
; From StepActor `$9AD3`. Hiro: script low byte from `$69DC` (`$18`, set by
; `$9878`), E = 4; when he is on a ladder (+`$02` bit 3) LeaveLadder `$9078`
; instead (`$9058`; taken once, in the room-entry segment e102685). +`$10` bit
; 4 is the hurt flag (HurtHiro `$98A7` for Hiro); nothing below the feet never
; sets it. Other actors: the low byte from +`$08`. The page is +`$06`.
; SequenceHeader `$919C` with L = `$31`, then FallScriptStep `$9240`.
;
; Two entry points: GrabLadder `$906C` (from ActorJump `$902B` and `$9B1D`):
; +`$02` bit 3 (hanging), script `$7AAF` (2 frames) in sequence +`$36`;
; LeaveLadder `$9078` (here and `$9C9E`): bit 3 cleared, X + 2, script `$7AE8`
; in the pose sequence +`$32`.
;
; Witness: L1 797 (deaths, play48, rooms, rzx x58, rzxroom x5).
FallSequenceStart:
  LD A,H
  CP $5D
  JR NZ,StartFallOther
  LD A,(HiroFallScript)
  LD E,$04
  LD L,$02
  BIT 3,(HL)
  JP NZ,LeaveLadder
  LD C,A
  JR StartFallScript
StartFallOther:
  LD L,$08                ; the fall script's low byte from +$08
  LD C,(HL)
StartFallScript:
  LD L,$06                ; the scripts' page from +$06
  LD B,(HL)
  LD L,$31
  CALL SequenceHeader
  JP FallMove
; This entry point is used by the routines at ActorJump and MoveActor.
GrabLadder:
  LD L,$02                ; hang: +$02 bit 3, script $7AAF in +$36
  SET 3,(HL)
  LD BC,LadderGrabScript
  LD L,$36
  JP StartSequence
; This entry point is used by the routine at StopActor.
LeaveLadder:
  LD L,$02                ; leave the ladder: +$02 bit 3 off, script $7AE8 in
                          ; +$32, X + 2
  RES 3,(HL)
  LD BC,LadderLeaveScript
  LD L,$01
  LD A,(HL)
  ADD A,$02
  LD (HL),A
  JR StartPoseSeq

; The hold count +$28 ran out: face Hiro and play the +$0E script (sequence
; +$32)
;
; From StepActor `$9AB0` when +`$28` reaches 0 and +`$0E` is not 0. Direction
; +`$1B` = 2 when Hiro's X (`$5D2A` x 2, his box's first column) is at or right
; of the actor, else `$FE`; sound `$09` (`$8454`); the script `$7600` + +`$0E`
; in sequence +`$32` (StartPoseSeq `$90A1`).
;
; Witness: L1 242 (bossgate, rooms, poke-room x6, rzx x53, rzxroom x8).
TurnToHiro:
  LD A,(Hiro+$002A)
  ADD A,A
  LD L,$01
  CP (HL)
  LD A,$FE
  JR C,TurnToHiroSet
  NEG
TurnToHiroSet:
  LD L,$1B                ; +$1B = the direction toward Hiro
  LD (HL),A
  LD A,$09
  LD (EffectRequest),A
  LD B,$76
  LD L,$0E
  LD C,(HL)

; Start a script BC in the pose sequence +$32 (landing, climbing, turning to
; Hiro, the shake)
;
; L = `$32`, StartSequence `$917E`. Callers: LeaveLadder `$9078`, TurnToHiro
; `$9087`, HiroLanded `$90C3`, StalactiteShake `$9112`.
;
; Entry StartHurtSeq `$90A6` (from StepActor `$9ADD` when +`$10` bit 2 is set:
; Hiro touched the actor, `$9851`): the script +`$06`/+`$09` in the action
; sequence +`$34`.
;
; Witness: L1 1308 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x6, rzx x69, rzxroom x16).
StartPoseSeq:
  LD L,$32
  JP StartSequence
; This entry point is used by the routine at StepActor.
StartHurtSeq:
  LD L,$09                ; +$10 bit 2: the +$09 script in +$34
  LD C,(HL)
  LD L,$06
  LD B,(HL)
  LD L,$34
  JP StartSequence

; Reverse: the turn script +$06/+$07 in sequence +$33, the run counters cleared
;
; From WalkStep `$9B0C` when the wanted X step has the other sign than +`$1B`.
; Clears +`$24` and +`$25`, then StartSequence `$917E` with L = `$33`; TurnStep
; `$91E1` flips +`$1B` halfway.
;
; Witness: L1 1275 (bossgate, deaths, gameover, hiscore, play48, rooms, throw,
; c x1, opt x3, poke-room x2, rzx x69, rzxroom x11).
StartTurn:
  XOR A
  LD L,$24
  LD (HL),A
  LD L,$25
  LD (HL),A
  LD L,$07
  LD C,(HL)
  LD L,$06
  LD B,(HL)
  LD L,$33
  JP StartSequence

; Hiro lands: a crouch, or fall damage when he fell 20 steps or more
;
; From `$9D3B` (a falling actor of kind `$24` finds the floor). +`$26` (the
; fall steps, counted by `$9CE8`) is read and cleared. 0: return (Z). 1-19: the
; caller's return is dropped and the landing script `$7AB6` (1 frame) plays in
; +`$32`. 20 or more: the damage count = steps - 17, at most 14; sound 1; the
; script `$7ABC` (speed byte, frames `$31`/`$32`) in sequence +`$35` with that
; count (StartSequenceCount `$9180`): FallDamageStep `$920A` takes 2 energy
; each step (so 6 to 28 energy; full energy is `$20`).
;
; Witness: 157 landings in the keyed recordings, two of them hard (`$90CC` once
; in deaths, once in `play48`: 32 fall steps, 14 damage steps from frame 3016).
; Witness: L1 3091 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x16).
HiroLanded:
  LD L,$26
  LD A,(HL)
  LD (HL),$00
  CP $14
  JR C,HiroLandedSoft
  SUB $11
  LD E,$0E
  CP E
  JR C,HiroLandedHard
  LD A,E
HiroLandedHard:
  POP BC                  ; the damage count, at most 14
  EX AF,AF'
  LD A,$01
  LD (EffectRequest),A
  EX AF,AF'
  LD BC,HardLandScript    ; the hurt-on-landing frames, count in A
  LD L,$35
  JP StartSequenceCount
HiroLandedSoft:
  OR A
  RET Z
  POP BC
  LD BC,LandScript
  JR StartPoseSeq

; Fire without a weapon: the strike $6650 (1-3) in the action sequence +$34
;
; From HiroAttack `$9276` (`$664B` = 0). L = the strike (the fire key's hold
; time, set by the tick `$84FB`: under 9 frames 1, under 25 frames 2, else 3):
; 1 script `$7A46` (6 frames), 2 `$7ACE` (8), 3 `$7ADB` (8). +`$02` bit 4 arms
; the hit test (ActionStep `$91F4` calls `$9DCA` every step: blocks and enemies
; in reach, `$69E1` 3 reaches further).
;
; Entry StartActionSeq `$9104` (also from HiroAttack after a throw): `$6650` =
; 0 (the request taken), sound `$0A`, the script in sequence +`$34`. The `$0B`
; stored to `$8454` at `$90FD` is overwritten by the `$0A` at `$910A` before
; anything reads it, so effect 11 is never heard from a strike; its only
; audible source is TitleMovePiece `$A775` (a title piece arrives).
;
; Witness: L1 409 (bossgate, havok, menu, play48, c x1, opt x3, poke-room x15,
; rzx x56, rzxroom x8).
HiroMelee:
  LD BC,StrikeScript1
  DEC L
  JR Z,HiroMeleeArm
  LD BC,StrikeScript2
  DEC L
  JR Z,HiroMeleeArm
  LD BC,StrikeScript3
HiroMeleeArm:
  LD A,$0B                ; sound $0B (overwritten at $910A), +$02 bit 4: hit
                          ; test on
  LD (EffectRequest),A
  LD L,$02
  SET 4,(HL)
; This entry point is used by the routine at HiroAttack.
StartActionSeq:
  XOR A                   ; the fire request taken; sound $0A; sequence +$34
  LD (FireRequest),A
  LD A,$0A
  LD (EffectRequest),A
  LD L,$34
  JP StartSequence
; This entry point is used by the routine at StalactiteControl.
StalactiteShake:
  CALL FreezeAnim         ; kind $36 touched: $9D50, the shake $7BB5 in +$32
  LD BC,Script9115
  JR StartPoseSeq

; The death script ended with +$39 set: the actor becomes a bonus that rises 32
; pixels
;
; From DeathStep `$91BC`, HL at +`$39`. +`$39` = 0; +`$02` bit 7 (drawn on top)
; set, bit 5 cleared; frame +`$23` = the old +`$39` - 1; MarkSpawnKilled
; `$9137`; +`$0F` = `$5D`; the header of `$7B5D` (8 steps, speed 4) in sequence
; +`$38`, then RiseStep `$91DB` (4 pixels up a step).
;
; Witness: deaths 1 run. Witness: L1 16 (deaths, play48, rzx x12).
DeathLeavesBonus:
  LD (HL),$00
  LD L,$02
  SET 7,(HL)
  RES 5,(HL)
  LD L,$23
  DEC A
  LD (HL),A
  CALL MarkSpawnKilled
  LD L,$0F
  LD BC,Script911A
  LD (HL),C
  LD L,$38
  CALL SequenceHeader
  JP RiseMove

; The actor's room spawn slot +$29 is set in the room's kill mask $6EFE (not
; respawned)
;
; +`$29` (1-based slot in the room's spawn list, 0 none) is read and cleared;
; bit (`$6ADD` - slot) of the 16-bit mask at `$6EFE`/`$6EFF` (first byte the
; high bits) is set: the room spawner `$A59E` skips the slots whose bit is set.
; Callers: DeathLeavesBonus `$911A`, DeathStep `$91CE`.
;
; Entry DieOnLanding `$9159` (from `$9D44`: kinds `$20-$22` land): the caller's
; return is dropped, +`$0F` = `$37` (the death script `$7B37`) and +`$10` bit 5
; (ActorExpired runs it).
;
; Witness: L1 638 (bossgate, deaths, havok, play48, throw, rzx x67, rzxroom
; x7).
MarkSpawnKilled:
  LD L,$29
  LD A,(HL)
  OR A
  RET Z
  LD B,A
  LD DE,$0000
  LD (HL),E
  LD A,(EnemyCount)
  SUB B
  INC A
  SCF
MarkSpawnKilledShift:
  RR E
  RR D
  DEC A
  JR NZ,MarkSpawnKilledShift
  LD BC,GoneEnemies       ; the room's kill mask
  LD A,(BC)
  OR E
  LD (BC),A
  INC C
  LD A,(BC)
  OR D
  LD (BC),A
  RET
; This entry point is used by the routine at ProbeFloorCell.
DieOnLanding:
  POP BC                  ; kinds $20-$22 die where they land
  LD L,$0F
  LD (HL),$37
  LD L,$10
  SET 5,(HL)
  RET

; +$10 bit 5 (timer run out, or killed): the death script $7B00 + +$0F in
; sequence +$37
;
; From StepActor `$9AD8`. Kind `$25` (Havok) only moves on (MoveActor `$9B56`,
; his end is `$872B`). +`$0F` = `$58` (the bonus pick-up's script) sets +`$02`
; bit 5 at once. The death script `$7B00` + +`$0F` (Hiro: `$7B26`) in sequence
; +`$37`; DeathStep `$91A9` ends it.
;
; Witness: L1 1691 (bossgate, deaths, havok, play48, throw, rzx x68, rzxroom
; x9).
ActorExpired:
  LD L,$1C
  LD A,(HL)
  CP $25
  LD DE,$0000
  JP Z,ApplyMove
  LD L,$0F
  LD A,(HL)
  CP $58
  JR NZ,ActorExpiredScript
  LD L,$02
  SET 5,(HL)
ActorExpiredScript:
  LD C,A
  LD B,$7B
  LD L,$37

; Start the script at BC in the sequence slot L: count, timing, first frame
;
; HL = the actor at the slot (+`$30`-`$38`), BC = the script: [count][speed][X
; offset facing left][X offset facing right][size class] then one frame a step
; (three bytes a step in the jump and fall scripts: frame, Y step, X step). The
; count to the slot, then StartSequenceCount `$9180`.
;
; StartSequenceCount `$9180` (A = the count, BC at the speed byte; from
; HiroLanded `$90E1`): +`$22` = 0; SequenceTiming `$919F`; L = `$3B`;
; SequenceFrameAt `$9191`.
;
; Witness: L1 4906 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
StartSequence:
  LD A,(BC)
  INC BC

; Start a sequence with the count in A (BC at the script's speed byte)
;
; The tail of StartSequence `$917E`, and HiroLanded's entry (`$90E1`, the
; damage count). (HL) = A; +`$22` = 0; SequenceTiming `$919F`; L = `$3B` and
; SequenceFrameAt `$9191` (the first frame).
;
; Witness: L1 4920 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
StartSequenceCount:
  LD (HL),A
  LD L,$22
  LD (HL),$00
  CALL SequenceTiming
  LD L,$3B
  JR SequenceFrameAt

; A sequence step: the next frame from the script pointer +$3A/+$3B
;
; The common tail of the frame-list handlers (DeathStep, TurnStep, PoseStep,
; ActionStep, FallDamageStep, HangStep): BC = +`$3A`/+`$3B`, then
; SequenceFrameAt `$9191`.
;
; Witness: L1 11974 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
SequenceNextFrame:
  LD L,$3A
  LD C,(HL)
  INC L
  LD B,(HL)

; Frame +$23 = (BC), the pointer moves on to +$3A/+$3B; no move (MoveActor with
; DE = 0)
;
; Jumps to `$9B53` (DE = 0, MoveActor `$9B56`): the actor stands while the
; frame changes.
;
; Witness: L1 16894 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
SequenceFrameAt:
  LD A,(BC)
  INC BC
  LD (HL),B
  DEC L
  LD (HL),C
  LD L,$23
  LD (HL),A
  JP ApplyNoMove

; Script header: the count to (HL), then the timing and offset (SequenceTiming)
;
; HL = the slot. Callers: ActorJump `$9044`, FallSequenceStart `$9066`,
; DeathLeavesBonus `$9131`.
;
; Witness: L1 1695 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x69, rzxroom x11).
SequenceHeader:
  LD A,(BC)
  INC BC
  LD (HL),A

; Script header: the speed to +$1A/+$1D, the X offset for the facing, the size
; class
;
; The speed byte (frames a step) to +`$1A` and +`$1D` (`$9C32`); `$A6B1`: the X
; offset of the facing (the first byte facing left, +`$1B` bit 7, else the
; second) is added to X and kept in +`$3D` (`$A6A1` takes it back at the end);
; the size class to +`$14` and its five bytes from SizeClasses `$6082` to
; +`$15`-`$19`. Out: A = 0, BC past the header.
;
; Witness: L1 6615 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
SequenceTiming:
  LD A,(BC)
  INC BC
  CALL SetFrameDelay
  CALL ActorFrameStep
  XOR A
  RET

; Sequence +$37 (the death script): frames, then the end of the actor
;
; SequenceHandlers `$73F5`; HL = +`$37`. Counts down with a frame a step. At 0:
; first +`$02` bit 5 is set and one more still step is made; on the next:
; +`$39` set -> DeathLeavesBonus `$911A`; else +`$02` = 0 (the actor is free),
; kind `$48` (the shield) clears the invulnerable flag `$6651`, MarkSpawnKilled
; `$9137`, and `$A59B` (the room spawner may fill the page again).
;
; Witness: deaths 25 runs. Witness: L1 3660 (bossgate, deaths, havok, play48,
; throw, rzx x67, rzxroom x9).
DeathStep:
  DEC (HL)
  JP NZ,SequenceNextFrame
  LD L,$02                ; the last frame shown once more
  BIT 5,(HL)
  JR NZ,DeathStepEnd
  SET 5,(HL)
  JP ApplyNoMove
DeathStepEnd:
  XOR A
  LD L,$39
  OR (HL)
  JP NZ,DeathLeavesBonus
  LD L,$02                ; the page is free
  LD (HL),$00
  LD L,$1C
  LD A,(HL)
  CP $48                  ; the shield ends: Hiro can be hurt again
  JR NZ,DeathStepFree
  XOR A
  LD (Invulnerable),A
DeathStepFree:
  CALL MarkSpawnKilled
  JP SpawnRoomEnemies

; Sequence +$38 (the bonus rising): 4 pixels up a step
;
; SequenceHandlers `$73F7`. At 0 +`$02` bit 5 is set. RiseMove `$91DB` (DE =
; `$00FC`: Y - 4) -> MoveActor `$9B56`; also the first step from
; DeathLeavesBonus `$9134`.
;
; Witness: L1 115 (deaths, play48, rzx x12).
RiseStep:
  DEC (HL)
  JR NZ,RiseMove
  LD L,$02
  SET 5,(HL)

; Move the actor 4 pixels up (DE = $00FC): MoveActor
;
; From RiseStep `$91D4` and DeathLeavesBonus `$9134`.
;
; Witness: L1 131 (deaths, play48, rzx x12).
RiseMove:
  LD DE,$00FC
  JP ApplyMove

; Sequence +$33 (the turn): the facing +$1B flips when 2 steps are left
;
; SequenceHandlers `$73ED`; HL = +`$33`. At count 2: +`$1B` negated. Then
; PoseStep `$91EE`.
;
; Witness: L1 5090 (bossgate, deaths, gameover, hiscore, play48, rooms, throw,
; c x1, opt x3, poke-room x2, rzx x69, rzxroom x12).
TurnStep:
  LD A,(HL)
  CP $02
  JR NZ,PoseStep
  LD L,$1B
  LD A,(HL)
  NEG
  LD (HL),A
  LD L,$33

; Sequence +$32 (and the end of +$33): a frame a step, at 0 SequenceEndDrop
;
; SequenceHandlers `$73EB`.
;
; Witness: L1 7652 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x8, rzx x70, rzxroom x18).
PoseStep:
  DEC (HL)
  JR Z,SequenceEndDrop
  JP SequenceNextFrame

; Sequence +$34 (strike, throw, hurt): a frame a step, the hit test while +$02
; bit 4 is set
;
; SequenceHandlers `$73EF`. With +`$02` bit 4 (Hiro's strike armed by HiroMelee
; `$9102`): `$9DCA`, the reach test in front of him (it clears the bit on a
; hit). At 0: SequenceEndDrop `$9201`.
;
; Witness: L1 5395 (bossgate, havok, menu, play48, throw, c x1, opt x3,
; poke-room x15, rzx x69, rzxroom x13).
ActionStep:
  DEC (HL)
  JR Z,SequenceEndDrop
  LD L,$02
  BIT 4,(HL)
  CALL NZ,ProbeStrikeCell
  JP SequenceNextFrame

; A sequence ended: the X offset back, then the floor test (falling if nothing
; below)
;
; `$A6A1` takes the header's X offset +`$3D` back and restores the size class
; +`$3C`; DE = 0; `$9CD5` sets +`$02` bits 1 and 2: the next step tests the
; floor and falls or stands (the fall steps +`$26` start again).
;
; Witness: L1 3658 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
SequenceEndDrop:
  CALL ActorFrameBack
  LD DE,$0000
  JP StartFall

; Sequence +$35 (the hard landing): 2 energy lost a step
;
; SequenceHandlers `$73F1`. LoseEnergy `$9615` with A = 2 (it ignores the loss
; while the shield `$6651` is up, and takes a life at 0). At 0: ResumeState
; `$9AEC` (the state handler).
;
; Entry HangStep `$9215` (SequenceHandlers `$73F3`, sequence +`$36`, the ladder
; grab): the same count-down without the loss.
;
; Witness: deaths 14 runs. Witness: L1 129 (deaths, play48, rzx x8, rzxroom
; x1).
FallDamageStep:
  PUSH HL
  PUSH IY
  LD A,$02
  CALL LoseEnergy
  POP IY
  POP HL
HangStep:
  DEC (HL)                ; sequence +$36: count down, then the state handler
  JP Z,RunHandler
  JP SequenceNextFrame

; Sequence +$30 (the jump): a frame and a Y, X step a script step
;
; SequenceHandlers `$73E7`; HL = +`$30`. At 0: `$9CD1` (+`$30` = 0, the fall
; starts). Else BC = +`$3A`/+`$3B`, then JumpMove `$9225`: MotionStep `$9253`
; reads frame, Y step E and X step D; on a rising step (D was 0 in the script)
; the head test `$9DF1` (a ceiling ends the jump: `$9CD1`); `$9CF8` (the floor
; test when +`$10` bit 1), MoveActor `$9B56`.
;
; Witness: L1 6629 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x64, rzxroom x11).
JumpStep:
  DEC (HL)
  JP Z,StartFallEndJump
  LD L,$3A
  LD C,(HL)
  INC L
  LD B,(HL)

; A jump step from the script at BC: MotionStep, the head test on a rising
; step, the floor test, MoveActor
;
; From JumpStep `$921C` and ActorJump `$9047` (the first step). D = 0 from
; MotionStep (no X step, or a wall): the head test `$9DF1`; a ceiling ends the
; jump (`$9CD1`, the fall).
;
; Witness: L1 7241 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x64, rzxroom x11).
JumpMove:
  CALL MotionStep
  LD A,D
  OR A
  JR NZ,JumpMoveOn
  CALL ProbeCeiling
  JP Z,StartFallEndJump
JumpMoveOn:
  CALL ProbeVertical
  JP ApplyMove

; Sequence +$31 (the fall script): a frame and a step a script step; at 0 the
; fall goes on free
;
; SequenceHandlers `$73E9`. Like JumpStep with no head test. At 0 (FallSeqEnd
; `$9249`): `$A6A1`, +`$10` bit 4 cleared, `$9B53` (still).
;
; Witness: L1 4577 (deaths, play48, rooms, rzx x58, rzxroom x5).
FallScriptStep:
  DEC (HL)
  JR Z,FallSeqEnd
  LD L,$3A
  LD C,(HL)
  INC L
  LD B,(HL)

; A fall-script step from BC: MotionStep, the floor test, MoveActor
;
; From FallScriptStep `$9238` and FallSequenceStart `$9069` (the first step).
;
; Witness: L1 4585 (deaths, play48, rooms, rzx x58, rzxroom x5).
FallMove:
  CALL MotionStep
  CALL ProbeVertical
  JP ApplyMove
; This entry point is used by the routine at FallScriptStep.
FallSeqEnd:
  CALL ActorFrameBack     ; the X offset back; +$10 bit 4 cleared
  LD L,$10
  RES 4,(HL)
  JP ApplyNoMove

; Read a jump or fall script step: frame +$23, E = Y step, D = X step (mirrored
; when facing left)
;
; BC = the step; +`$3A`/+`$3B` = BC + 3; then `$9D8E` (the wall test when
; +`$10` bit 0: a wall clears D; it also stops the kinds `$40-$46` there,
; `$97A3`). Callers: JumpMove `$9225`, FallMove `$9240`.
;
; Witness: L1 11826 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x68, rzxroom x13).
MotionStep:
  LD A,(BC)
  LD L,$23
  LD (HL),A
  INC BC
  LD A,(BC)
  LD E,A
  INC BC
  LD A,(BC)
  LD L,$1B
  BIT 7,(HL)
  JR Z,MotionStepX
  NEG
MotionStepX:
  LD D,A
  INC BC
  LD L,$3A
  LD (HL),C
  INC L
  LD (HL),B
  JP ProbeWalls

; Hiro's fire (+$6650 set): throw the weapon $664B (actor $6600) or strike
;
; From StepActor `$9AE9` for Hiro when `$6650` (the fire request) is not 0.
; `$69E1` = the strike (1-3). `$664B` = 0 (no weapon): HiroMelee `$90EC`. After
; Havok (`$6652` set): ResumeState `$9AEC`. The weapon page `$6600` active
; (+`$02` bit 0): nothing, one in flight at a time.
;
; Else the weapon kind `$40` + `$664B` - 1: its 7-byte record (KindTemplates
; `$7200`, TemplateForKind `$A652`) is patched into the template `$64EE` (bytes
; 2-3, 8-9, 12, 16-17: the path, the step, the death script, the size),
; InitActor `$A65D` on page `$6600` at Hiro's Y + `$0A`, X + 6 (+ the
; template's byte 8 when facing left), its +`$1B` = Hiro's, +`$3F` = 0, then
; per kind: below `$43` the life +`$3F` = the hold time `$69E3` x 4; `$43`: the
; step delay +`$0C` = 5 - (hold time / 8 AND 7), a longer hold flies faster;
; `$44`: +`$05` = `$F3` + 2 x (strike - 1). A weapon spawned at X `$9C` or more
; expires at once (`$97A3`). Without a boss (`$9A59` = 0) the count `$6649`
; loses one. Then the throw script `$7AEF` (8 frames) in +`$34` (StartActionSeq
; `$9104`).
;
; Entry HiroEndWalk `$9321` (from HiroControl when `$6652` is set, the end
; after Havok): no input; with `$6652` bit 6 clear Hiro walks up (E = -1) and,
; at X `$58` or more, left: the end scene walks him.
;
; Witness: L1 650 (bossgate, havok, menu, play48, throw, c x1, opt x3,
; poke-room x15, rzx x66, rzxroom x10).
HiroAttack:
  LD (Strike),A
  LD L,A
  LD A,(Weapon)
  OR A
  JP Z,HiroMelee
  LD C,A
  LD A,(EndFlags)
  OR A
  JP NZ,RunHandler
  LD A,(WeaponActor+$0002) ; one weapon in flight at a time
  RRA
  RET C
  LD A,C                  ; the weapon kind $40 + $664B - 1
  PUSH HL
  DEC A
  ADD A,$40
  CALL TemplateForKind
  EX DE,HL
  LD DE,WeaponTemplate+$0002 ; patch the weapon template $64EE
  LDI
  LDI
  INC DE
  INC DE
  INC DE
  INC DE
  LDI
  LDI
  INC DE
  INC DE
  LDI
  INC DE
  INC DE
  INC DE
  LDI
  LDI
  LD E,A
  LD A,(Hiro+$001B)       ; facing left: the X offset from the template
  RLA
  LD A,$06
  JR NC,HiroAttackPlace
  LD A,(WeaponTemplate+$0008)
HiroAttackPlace:
  LD BC,(Hiro)            ; Y + $0A, X + the offset
  ADD A,B
  LD B,A
  LD A,C
  ADD A,$0A
  LD C,A
  LD A,E
  PUSH AF
  LD HL,WeaponActor
  LD DE,WeaponTemplate
  CALL InitActor          ; spawn on page $6600
  LD A,(Hiro+$001B)       ; the weapon flies Hiro's way
  LD E,$1B
  LD (DE),A
  LD E,$3F
  XOR A
  LD (DE),A
  POP AF
  CP $43
  JR C,HiroAttackLife
  JR Z,HiroAttackKind43
  CP $44
  JR Z,HiroAttackKind44
HiroAttackCount:
  LD E,$01
  LD A,(DE)
  CP $9C
  JR C,HiroAttackAmmo
  EX DE,HL
  CALL ExpireActor
  EX DE,HL
HiroAttackAmmo:
  LD A,(RunActorSteps+$000E) ; no boss: one weapon less ($6649)
  OR A
  JR NZ,HiroAttackThrow
  LD HL,WeaponCount
  DEC (HL)
HiroAttackThrow:
  LD BC,Script92F5        ; the throw frames, sequence +$34
  POP HL
  JP StartActionSeq
HiroAttackLife:
  LD A,(FireHeld)         ; kinds $40-$42: the life = hold time x 4
  ADD A,A
  ADD A,A
  LD (DE),A
  JR HiroAttackCount
HiroAttackKind43:
  LD A,(FireHeld)
  RRA
  RRA
  RRA
  AND $07
  NEG
  ADD A,$05
  LD E,$0C
  LD (DE),A
  JR HiroAttackCount
HiroAttackKind44:
  LD A,(FireRequest)
  DEC A
  ADD A,A
  ADD A,$F3
  LD E,$05
  LD (DE),A
  JR HiroAttackCount
; This entry point is used by the routine at HiroControl.
HiroEndWalk:
  AND $40                 ; the end: no keys, walk up and left
  LD DE,$0000
  JR NZ,HiroScriptMove
  DEC E
  LD A,(Hiro+$0001)
  CP $58
  JR C,HiroScriptMove
  DEC D
  JR HiroScriptMove

; Kind $24, Hiro's state handler: the directions read into a walk step
;
; The handler at +`$03` of Hiro (KindTemplates `$7200` entry `$24`, the
; template `$65CA`), from ResumeState `$9AEC` on each of his logic steps (every
; 3 frames: +`$1A` = 3). The end (`$6652` set): HiroEndWalk `$9321`. Else
; `ReadDirection` `$850C` (the input bits the tick left in `$850D`): none ->
; `$9C39` (stop: the run counters +`$24`/+`$25` cleared, no move); else the
; step D x 2, E x 4 (X 2 pixels, Y 4 pixels a step) -> `$9AFD` (hanging:
; `$9C4A`; else WalkStep `$9B05`).
;
; Witness: c1 260 logic steps in 975 frames; deaths 1458. Witness: L1 32891
; (bossgate, deaths, gameover, havok, hiscore, menu, play48, rooms, throw, c
; x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
HiroControl:
  LD A,(EndFlags)
  OR A
  JR NZ,HiroEndWalk
  CALL ReadDirection
  JP NC,StopActor
; This entry point is used by the routine at HiroAttack.
HiroScriptMove:
  SLA D                   ; X step x 2, Y step x 4
  SLA E
  SLA E
  JP HiroMove

  ORG $9514

; Kinds $40-$46, the thrown weapon on page $6600: fly at 2 x the facing until
; +$3F runs out
;
; +`$3F` (the life, from HiroAttack: hold time x 4) counts down; D = 2 x
; +`$1B`, E = 0 -> `$9B28` (the wall test and move). At 0 WeaponExpire `$9523`:
; `$97A3` (+`$10` bit 5), still. The handler word of the template `$6F3A`
; (copied to `$64EE`). The throw recording throws the spinblade and the blade
; from our own keys (Weapon and WeaponCount POKEd), frames 1893-3039.
;
; Witness: L1 2632 (bossgate, havok, throw, rzx x26, rzxroom x2).
WeaponControl:
  LD L,$3F
  DEC (HL)
  JR Z,WeaponExpire
  LD L,$1B
  LD A,(HL)
  ADD A,A
  LD D,A
  LD E,$00
  JP MoveProbeWalls
WeaponExpire:
  CALL ExpireActor
  JP ApplyNoMove

  ORG $965F

; Three spark actors (kind $47) at the cell $69E2 for 170 frames
;
; The cell last probed (`$69E2`, written by ProbeCell `$9E4F`) gives the
; position (`$8EC7`: Y = row x 16, X = column x 8, then X + 2), kept in the
; operand of `LD BC,nn` at `$9683`. Three times: the template `$6582` gets the
; bytes +5 to +7 from `$7B86-$7B88`, `$7B83-$7B85`, `$7B80-$7B82` (the
; animation `$7B89` and three different +7 bytes: `$A8`, `$9B`, `$8E`),
; FindFreeActor `$9F2C` looks for a free page among `$62-$65`, and InitActor
; `$A65D` puts a kind `$47` there with the 16-bit timer at 170 frames
; (`$9991`). The main registers are kept (EXX).
;
; Callers: BreakBlock `$9E98` (a block smashed), CollectFragment `$990D` (a
; Fireblade fragment taken), StrikeEnemy `$976B` (a boss other than kind `$25`
; hit). Ran in `play48` at frame 1458 (a block broken in room 6, its item
; revealed) and in bossgate (the giant struck, StrikeEnemy `$976B`); no
; fragment in the keyed recordings.
;
; Witness: L1 82 (bossgate, play48, throw, rzx x31, rzxroom x4).
SpawnSparks:
  EXX
  CALL LastCellPixel      ; DE = the cell's Y, X
  INC D
  INC D
  LD (SpawnSparksLoop+$0016),DE ; the position into LD BC,nn at $9683, X + 2
  LD HL,SpawnTriples+$0008 ; the three spark variants, read backwards
  LD B,$03
SpawnSparksLoop:
  PUSH BC
  LD DE,ActorPage9+$0086
  LD BC,$0003
  LDDR
  DEC DE
  PUSH HL
  LD B,$04
  LD HL,PrintGlyphsAddress+$0002 ; a free page among $62-$65?
  CALL FindFreeActor
  JR C,SpawnSparksNext
  LD BC,$0000             ; LD BC,nn: the position (written at $9665)
  LD A,$47                ; kind $47: a spark
  CALL InitActor
  EX DE,HL
  LD BC,$00AA             ; it lives 170 frames
  CALL SetActorTimer
SpawnSparksNext:
  POP HL
  POP BC
  DJNZ SpawnSparksLoop
  EXX
  RET

; The touches and strikes of actor H before it moves
;
; Called from ApplyMoveNoGate `$9B6A` before every move of every actor (5275
; runs). H = the actor's page.
;
; An actor hurt or expiring (+$10 bits 4, 5) does nothing.
;
; **Hiro** (H = `$5D`): only hand to hand (weapon `$664B` = 0; a shot strikes
; for itself), only while a combat move runs (+$34, the move's action slot) and
; before it has hit (+2 bit 4). His box is narrowed to the strike: the two
; columns at the side he faces (+$1B), one row: the second from the top, the
; third for the sweep (power 3, `$69E1`); StrikeAllActors `$96FF` tests it
; against the eight other actors; the box is put back. 48 strikes (c1, menu,
; opt2-4).
;
; **The others** (`$96EB`): a falling actor (+2 bit 2) goes to FallingTouch
; `$9854`; kind 0 nothing; the shots (kinds `$40-$46`) strike like Hiro (falls
; into StrikeAllActors); every other kind tests its touch with Hiro (TouchHiro
; `$9801`).
;
; Witness: L1 148167 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ActorInteractions:
  LD L,$10
  LD A,(HL)
  AND $30
  RET NZ
  LD A,H                  ; Hiro?
  CP $5D
  JR NZ,OtherInteractions
  LD A,(Weapon)           ; with a weapon the shot strikes, not Hiro
  OR A
  RET NZ
  LD L,$34                ; +$34: a combat move runs
  OR (HL)
  RET Z
  LD L,$02                ; +2 bit 4: the strike has not hit yet
  BIT 4,(HL)
  RET Z
  LD DE,(Hiro+$002A)      ; keep the box +$2A-+$2D
  LD BC,(Hiro+$002C)
  PUSH BC
  PUSH DE
  LD L,$1B                ; facing left?
  LD A,(HL)
  RLA
  JR C,HiroStrikeLeft
  LD L,$2B                ; facing right: the box = the right column and the
                          ; one before
  LD A,(HL)
  DEC A
  DEC L
  LD (HL),A
  JR HiroStrikeRow
HiroStrikeLeft:
  LD L,$2A                ; facing left: the left column and the one after
  LD A,(HL)
  INC A
  INC L
  LD (HL),A
HiroStrikeRow:
  LD L,$2C                ; the row: top + 1, + 2 for the sweep
  LD A,(Strike)
  CP $03
  JR NZ,HiroStrikeRowSet
  INC (HL)
HiroStrikeRowSet:
  INC (HL)
  LD A,(HL)
  INC L
  LD (HL),A
  CALL StrikeAllActors    ; strike the eight other actors
  POP DE                  ; the box back
  POP BC
  LD (Hiro+$002A),DE
  LD (Hiro+$002C),BC
  RET
OtherInteractions:
  BIT 2,(HL)              ; +2 bit 2: falling
  JP NZ,FallingTouch
  LD L,$1C                ; kind 0: nothing
  LD A,(HL)
  OR A
  RET Z
  CP $40                  ; kinds below $40 and from $47: the touch with Hiro
  JP C,TouchHiro
  CP $47
  JP NC,TouchHiro

; Test the strike or shot of actor H against the actors $5E-$65
;
; H = the striker (Hiro, or a shot of kinds `$40-$46` falling in from
; ActorInteractions `$96FC`); D steps the pages `$5E-$65` through StrikeActor
; `$970A`. A hit that ends the strike pops the return address of the loop
; (StrikeActor `$979F`), so one swing hits one actor; the scorchball (kind
; `$41`) goes on.
;
; Witness: L1 4718 (bossgate, havok, menu, play48, throw, c x1, opt x3,
; poke-room x15, rzx x66, rzxroom x8).
StrikeAllActors:
  LD B,$08
  LD D,$5E
StrikeAllLoop:
  CALL StrikeActor
  INC D
  DJNZ StrikeAllLoop
  RET

; The strike of actor H against actor D: shield transforms, damage, kills
;
; D = the target's page, H = the striker's. No hit when the target is inactive,
; in its hold count (+$28), of a kind with bit 7 set (a pickup that has just
; popped out of a block), hurt or expiring (+$10 bits 4, 5), or when the boxes
; do not overlap (BoxesOverlap `$9A27`). Kills in `play48` frames 1775 and 2219
; (patrollers, 50 each).
;
; **A pickup** (kind below `$23`): the power-up shield (kind `$19`) becomes the
; power-up reset shield (kind `$1C`, its frame and score from `$5ED6`), the
; speed-up shield (`$1A`) the speed-up reset shield (`$1D`, `$5EDA`): +$0A,
; +$0B, +$1C rewritten, +$10 bit 7 cleared, sound 6; the manual's rule. Other
; pickups are not hit.
;
; **A boss** (kinds `$25-$29`): `$97B5` = its kind (the operand KillActor
; reads); Hiro's own strikes do not reach it (only a shot), and a boss other
; than kind `$25` throws sparks (SpawnSparks `$965F`).
;
; **Damage** (`$976E`): the striker's +$13 (a shot's power), else the combat
; power `$69E1` (1 punch, 2 high kick, 3 sweep). A target with no hit points
; (+$13 = 0) cannot be hurt (the hazards). Hit points - damage; at zero or
; below KillActor `$97A8`; else sound `$0C` and, when the target has a hurt
; animation (+$08), +$10 bit 4 (it flinches, `$904A`).
;
; **After a hit** (`$9795`): the striker's +2 bit 4 is cleared (the strike is
; spent); the scorchball returns to the loop, every other striker pops the
; loop's return (one hit a swing), and a shot expires (ExpireActor `$97A3`).
;
; Witness: L1 36333 (bossgate, havok, menu, play48, throw, c x1, opt x3,
; poke-room x15, rzx x66, rzxroom x8).
StrikeActor:
  LD E,$02
  LD A,(DE)
  RRA
  RET NC
  LD E,$28                ; +$28: in its hold count
  LD A,(DE)
  OR A
  RET NZ
  LD E,$1C                ; kind bit 7: just popped out of a block
  LD A,(DE)
  RLA
  RET C
  LD E,$10                ; hurt or expiring: no hit
  LD A,(DE)
  AND $30
  RET NZ
  CALL BoxesOverlap       ; the boxes overlap?
  RET NC
  XOR A                   ; no boss struck yet
  LD (KillActor+$000D),A
  LD E,$1C
  LD A,(DE)
  CP $23                  ; kind below $23: a pickup
  JR NC,StrikeEnemy
  PUSH HL
  LD HL,IntroScript+$0089 ; the power-up shield becomes the reset shield (kind
                          ; $1C)
  CP $19
  JR Z,TransformShield
  LD HL,IntroScript+$008D ; the speed-up shield becomes its reset (kind $1D)
  CP $1A
  JR Z,TransformShield
  POP HL                  ; other pickups: no effect
  RET
TransformShield:
  PUSH BC                 ; +$10 bit 7 off, +$0A/+$0B and the kind from the
                          ; record
  LD E,$10
  LD A,(DE)
  AND $7F
  LD (DE),A
  LD E,$0A
  LDI
  LDI
  LD E,$1C
  LDI
  LD A,$06                ; sound 6
  LD (EffectRequest),A
  POP BC
  POP HL
  JR StrikeDone
StrikeEnemy:
  CP $25                  ; a boss (kinds $25-$29)?
  JR C,StrikeDamage
  CP $2A
  JR NC,StrikeDamage
  LD (KillActor+$000D),A  ; remember the boss kind for KillActor
  LD A,H                  ; Hiro's own strike: a boss takes none
  CP $5D
  RET Z
  LD A,(DE)               ; a boss other than kind $25 sparks
  CP $25
  CALL NZ,SpawnSparks
StrikeDamage:
  LD L,$13                ; the damage: the striker's +$13 ...
  LD A,(HL)
  OR A
  JR NZ,StrikeDamageC
  LD A,(Strike)           ; ... or the combat power 1-3
StrikeDamageC:
  LD C,A
  LD E,$13
  LD A,(DE)               ; no hit points: cannot be hurt
  OR A
  RET Z
  SUB C                   ; hit points - damage
  LD (DE),A
  DEC A
  JP M,KillActor          ; at zero or below: killed
  LD A,$0C                ; sound $0C: a hit
  LD (EffectRequest),A
  LD E,$08                ; a hurt animation? the target flinches
  LD A,(DE)
  OR A
  JR Z,StrikeDone
  LD L,$10                ; +$10 bit 4: hurt
; This entry point is used by the routine at ExpireActor.
SetTargetFlags:
  LD E,$10                ; the target's +$10 OR L
  LD A,(DE)
  OR L
  LD (DE),A
StrikeDone:
  LD L,$02                ; the strike is spent
  RES 4,(HL)
  LD L,$1C
  LD A,(HL)
  CP $41                  ; the scorchball goes on through the other actors
  RET Z
  POP DE                  ; drop the loop's return: one hit a swing
  CP $24                  ; Hiro: done; a shot expires
  RET Z

; Mark actor H expired: its next step runs its end
;
; Sets +$10 bit 5; the actor's next step (StepActor `$9A99`, `JP NZ,$9163`)
; runs its death or vanishing animation from +$0F. The IM 2 tick sets the same
; bit when the 16-bit timer +$1E runs out.
;
; Callers: TouchPickup `$98AD` (a pickup taken), KillActor `$97E2` (the boss
; gate), StrikeActor `$97A0` (a shot spent), ProbeWalls `$9DC7` (a shot at a
; wall), `$926E`, `$93EB`, `$947D`, `$9801` (deaths: 1 run).
;
; Witness: L1 300 (bossgate, deaths, havok, play48, throw, rzx x45, rzxroom
; x4). KillActor's boss branch `$97B9` ran in bossgate at frame 435 (a giant
; killed, OpenGate `$97E2`, sound 3; its hit points POKEd to 1) and in havok at
; frame 29 (no gate: the win `$97CA`, the life bonus, GameWonSound `$97DE`).
ExpireActor:
  LD L,$10
  SET 5,(HL)
  RET
; This entry point is used by the routine at StrikeActor.
KillActor:
  LD E,$00                ; the target's hit points are gone: score, sound, and
                          ; a boss's end
  PUSH IY
  PUSH DE
  PUSH HL
  PUSH BC
  PUSH DE                 ; IY = the target
  POP IY
  LD E,$02
  LD A,$00                ; LD A,n: n = the boss kind struck (StrikeActor
                          ; writes it), 0 none
  OR A
  JR Z,KillScore
  XOR A                   ; a boss: the boss fight is over
  LD (RunActorSteps+$000E),A
  LD B,$0A                ; look for the gate (kind $2A) in the ten pages
  LD HL,Hiro+$001C
  LD A,$2A
FindGateLoop:
  CP (HL)
  JR Z,OpenGate
  INC H
  DJNZ FindGateLoop
  LD A,$01                ; no gate: Havok is dead, the game is won
  LD (EndFlags),A
  LD A,(Lives)            ; 20000 for each life left (the low digit)
  AND $0F
  JR Z,GameWonSound
  LD B,A
LifeBonusLoop:
  LD E,$CA
  CALL AddScore
  DJNZ LifeBonusLoop
GameWonSound:
  LD E,$04                ; sound 4
  JR KillScore
OpenGate:
  CALL ExpireActor        ; the gate expires; its record in $76D2 cleared
  CALL BarrierOpen
  LD E,$03                ; sound 3
KillScore:
  LD A,E                  ; sound E
  LD (EffectRequest),A
  LD E,$0B                ; the target's +$0B: its score
  LD A,(DE)
  LD E,A
  CALL AddScore
  CALL PrintScore         ; print the score
  POP BC
  POP HL
  POP DE
  POP IY
  LD L,$20                ; the target's +$10 bit 5: expired
  JR SetTargetFlags

; Actor H touches Hiro: a pickup, a hurt, or a stand on it
;
; H = the actor's page (from ActorInteractions `$96F7`/`$96FC` and FallingTouch
; `$9856`): 2585 runs. The two POKE files' "No interactions" writes `RET` here
; (38913 = 201; 46 puts the `LD L,n` back).
;
; While Hiro's combat move runs (+$34) only kind `$2D` can touch him. Hiro's
; box is shrunk by his top row for the test (`$5D2C` + 1), BoxesOverlap `$9A27`
; with D = `$5D`; no overlap: done (2409 of 2585).
;
; **Kinds below `$23`, the pickups** (`$98AD`): ExpireActor `$97A3` (it
; vanishes), CollectPickup `$98B6`, `JP $8365` (the panel's numbers). The
; pickups are taken even with the energy ball on.
;
; **The others**: nothing while `$6651` is set (the energy ball or the death
; wait) or while Hiro is hurt (`$5D10` bit 4). Kinds below `$35` hurt Hiro
; (`$9860`); kind `$35` hurts; kind `$36` hurts when its +$32 is `$0D` or more
; (its phase); kinds `$37-$3D` (`$983B`) are objects Hiro stands on: both get
; +$10 bit 3, and when Hiro's Y - the object's Y is its +$11 or +$12 the
; object's +$10 bit 2 is set (the crush offset, read by FallingTouch `$9854`);
; kinds from `$3E` nothing.
;
; **HurtHiro** (`$9860`): the hurt animation `$69DC` = `$7A2F`'s low byte when
; Hiro and the attacker face the same way (+$1B), else `$18`; sound 0;
; LoseEnergy `$9615` with 4 (8 from kind `$2D`). When Hiro is in a jump or
; another action of slot +$30 (low 3 bits not 0) the slot is kept and `$5D02` =
; 3 (in the air: he drops); else `$5D10` bit 4 (hurt: StepActor runs `$904A`).
; The loop at `$9895` tests A = 0 with `AND $01` and can never branch: the
; slots +$31-$38 are never looked at. deaths: 27 hurts, 3 in the air.
;
; Witness: L1 98469 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; throw, c x1, poke-room x9, rzx x70, rzxroom x18).
TouchHiro:
  LD L,$1C
  LD A,(HL)
  CP $2D                  ; kind $2D touches even during a combat move
  JR Z,TouchHiroTest
  LD A,(Hiro+$0034)       ; Hiro's combat move runs: no touch
  OR A
  RET NZ
TouchHiroTest:
  LD DE,Hiro+$002C        ; Hiro's top + 1 for the test
  LD A,(DE)
  LD C,A
  INC A
  LD (DE),A
  CALL BoxesOverlap       ; the boxes overlap?
  LD A,C
  LD E,$2C                ; Hiro's top back
  LD (DE),A
  RET NC
  LD L,$1C                ; kind below $23: a pickup
  LD A,(HL)
  CP $23
  JP C,TouchPickup
  LD A,(Invulnerable)     ; the energy ball or the death wait: no harm
  OR A
  RET NZ
  LD E,$10                ; Hiro already hurt
  LD A,(DE)
  AND $10
  RET NZ
  LD A,(HL)               ; kinds below $35: harm
  CP $35
  JR C,HurtHiro
  CP $37                  ; kinds $35, $36: harm by phase
  JR C,TouchKind36
  CP $3E                  ; kinds $37-$3D: an object to stand on
  RET NC
  LD L,E                  ; both +$10 bit 3: Hiro is on the object
  SET 3,(HL)
  LD A,(DE)
  OR $08
  LD (DE),A
  LD L,$00                ; Hiro's Y - the object's Y
  LD E,L
  LD A,(DE)
  SUB (HL)
  LD L,$11                ; = +$11 or +$12: the crush offset
  CP (HL)
  JR Z,TouchSetFlag
  INC L
  CP (HL)
  RET NZ
TouchSetFlag:
  LD L,$10                ; the object's +$10 bit 2
  SET 2,(HL)
  RET
; This entry point is used by the routine at ActorInteractions.
FallingTouch:
  RES 2,(HL)              ; a falling actor: the touch, then its crush flag
  CALL TouchHiro          ; this routine's touch test first
  LD L,$10                ; +$10 bit 2 (set at the offset): crushes Hiro
  BIT 2,(HL)
  RES 2,(HL)
  RET Z
HurtHiro:
  LD E,$1B                ; the attacker's facing against Hiro's
  LD A,(DE)
  LD L,E
  XOR (HL)
  RLA
  JR C,HurtFacingOpposite
  LD A,$2F                ; the same way: hurt animation $7A2F
  JR HurtHiroSet
TouchKind36:
  CP $36                  ; kind $36 harms from phase $0D
  JR NZ,HurtFacingOpposite
  LD L,$32
  LD A,(HL)
  CP $0D
  RET C
HurtFacingOpposite:
  LD A,$18                ; facing each other: hurt animation $7A18
HurtHiroSet:
  LD (HiroFallScript),A   ; the low byte of Hiro's hurt animation
  LD A,$00                ; sound 0
  LD (EffectRequest),A
  LD L,$1C
  LD A,(HL)
  CP $2D
  LD A,$04                ; damage 4, 8 from kind $2D
  JR NZ,HurtHiroDamage
  ADD A,A
HurtHiroDamage:
  CALL LoseEnergy
  LD HL,Hiro+$0030        ; Hiro's slot +$30 (a jump) on?
  LD A,(HL)
  AND $07
  JR NZ,HurtKnockOff
  LD B,$08                ; A = 0 here: AND $01 never branches, the loop does
                          ; nothing
HurtSlotLoop:
  INC HL
  AND $01
  JR NZ,HurtKnockOff
  DJNZ HurtSlotLoop
  JR HurtHiroFlag
HurtKnockOff:
  LD (HL),A               ; in a jump: keep the slot, in the air (+2 = 3)
  LD A,$03
  LD (Hiro+$0002),A
  RET
HurtHiroFlag:
  LD HL,Hiro+$0010        ; +$10 bit 4: Hiro is hurt
  SET 4,(HL)
  RET
TouchPickup:
  CALL ExpireActor        ; the pickup vanishes, its effect, the panel
  CALL CollectPickup
  JP PrintScore

; The effect of the pickup of kind A (1-$22)
;
; A = the kind. Sound 8; `$A652` gives the kind's record (the table `$7200`, a
; word a kind) DE, 4 bytes: frame, score index (in the table at `$5D82`,
; AddScore `$99E7`), two bytes. In deaths 1 run (a kind below 7).
;
; | Kind | Pickup (the manual) | Record | Effect |
;
; | --- | --- | --- | --- |
;
; | 1-5 | gems | `$5DD2-$5DE2` | 50, 100, 200, 400, 700 |
;
; | 6 | the flask | `$5DE6` | 7000 (score index `$A2`; the manual says 700) |
;
; | 7-11 | the letters E X T R A | `$5EA6-$5EB6` | LetterPickup `$9997` |
;
; | 12-16 | the letters B O N U S | `$5EBA-$5ECA` | LetterPickup |
;
; | `$11-$17` | the weapon shields: fist, blade, scorchball, dart, spinblade,
; needle bolts, trispike | `$5DF6`, `$5DFA`, `$5E82`, `$5E92`, `$5E96`,
; `$5E8E`, `$5E86` | SetWeapon `$98F3`: weapon 0-6 |
;
; | `$18` | a Fireblade fragment | `$5E8A` | CollectFragment `$9908`: 10 000
; each; the sixteenth 10 000 + 50 000 = 60 000 and weapon 7 |
;
; | `$19` | the power-up shield | `$5ECE` | minimum power `$6647` + 2, at most
; `$10` (eight) |
;
; | `$1A` | the speed-up shield | `$5ED2` | the meter's rate `$6644` + 1, at
; most 3 |
;
; | `$1B` | the bullet shield | `$5E9A` | 16 bullets with a weapon, else 50 |
;
; | `$1C` | the power-up reset shield | `$5ED6` | `$6647` = 0, 400 |
;
; | `$1D` | the speed-up reset shield | `$5EDA` | `$6644` = 1, 400 |
;
; | `$1E` | vitality | `$5E9E` | `$6642` = `$20` |
;
; | `$1F` | invulnerability | `$5EA2` | SpawnShield `$9962` for `$355` frames
; (17 s) |
;
; | `$20-$22` | the orbs | `$5DEA-$5DF2` | 1000, 2000, 5000 |
;
; Witness: L1 51 (bossgate, deaths, play48, rzx x31, rzxroom x2).
CollectPickup:
  LD HL,EffectRequest
  LD (HL),$08             ; sound 8
  CALL TemplateForKind    ; DE = the kind's record (the table $7200)
  EX DE,HL
  INC HL
  CP $07                  ; kinds 1-6: the score only
  JR C,PickupScore
  CP $11                  ; kinds 7-$10: a letter
  JP C,LetterPickup
  CP $19                  ; kinds $11-$18: a weapon shield or a fragment
  JR C,PickupWeapon
  JR Z,PowerUpShield      ; $19: power-up
  CP $1A                  ; $1A: speed-up
  JR Z,SpeedUpShield
  CP $1B                  ; $1B: bullets
  JR Z,BulletShield
  CP $1C                  ; $1C: power-up reset
  JR Z,PowerResetShield
  CP $1D                  ; $1D: speed-up reset
  JR Z,SpeedResetShield
  CP $1E                  ; $1E: vitality
  JR Z,VitalityRefill
  LD BC,$0355             ; $1F: invulnerability for $355 frames
  CP $1F
  JR Z,SpawnShield
PickupScore:
  LD E,(HL)               ; the record's score index
  JR PickupAddScore
PickupWeapon:
  LD A,(HL)               ; a score (the fragment's)? CollectFragment
  OR A
  CALL NZ,CollectFragment
  INC HL

; Take the weapon of a shield record: the icon, the weapon, the bullets
;
; HL = the record + 2: the icon's first character (`$6671`, the second `$6672`
; = + 1: the weapon indicator's two characters), then the weapon `$664B`: 0
; fist, 1 blade, 2 scorchball, 3 dart, 4 spinblade, 5 needle bolts, 6 trispike,
; 7 the Fireblade. The bullets `$6649` = 16 with a weapon, 0 with the fist.
;
; Callers: PickupWeapon `$98F2` (a shield, or the 16th fragment: the Fireblade)
; and `$FF10` when the bullets run out (HL = `$5DF8`, the fist shield's record
; + 2): 12 runs, in c1 and c48 at the start of play.
;
; Witness: L1 102 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; throw, c x1, opt x3, rzx x51, rzxroom x2).
SetWeapon:
  LD A,(HL)
  LD DE,WeaponIcon        ; the icon: two characters
  LDI
  INC A
  LD (DE),A
  LD A,(HL)               ; the weapon
  LD (Weapon),A
  OR A
  JR Z,SetBullets
; This entry point is used by the routine at CollectFragment.
RefillBullets:
  LD A,$10                ; 16 bullets
SetBullets:
  LD (WeaponCount),A
  RET

; A Fireblade fragment: 10000, sparks, the count, at 16 the Fireblade
;
; A = the record's score index (`$C2`, 10000). AddScore `$99E7`, SpawnSparks
; `$965F`, the fragment count `$664E` + 1 (shown by `$FF3C`). Below 16 the
; return address is popped and the weapon is not changed; at 16 also AddScore
; `$C6` (50000; the sixteenth gives 10 000 + 50 000 = 60 000) and back to
; `$98F2`, where SetWeapon `$98F3` gives weapon 7, the Fireblade (the manual:
; "Hiro's weapon will automatically switch over to the Fireblade"). Not run in
; the keyed recordings.
;
; Witness: L1 4 (rzx x4). Not run in the keyed recordings.
CollectFragment:
  LD E,A
  CALL AddScore
  PUSH HL
  CALL SpawnSparks
  LD HL,Fragments         ; one more fragment
  INC (HL)
  BIT 4,(HL)              ; the 16th?
  POP HL
  JR Z,FragmentDone
  LD E,$C6                ; 50000 for the whole Fireblade
  JR PickupAddScore
FragmentDone:
  POP HL                  ; below 16: pop the return, the weapon stays
  RET
; This entry point is used by the routine at CollectPickup.
BulletShield:
  LD A,(Weapon)           ; with a weapon: 16 bullets
  OR A
  JR NZ,RefillBullets
  LD E,$82                ; with the fist: 50
; This entry point is used by the routine at CollectPickup.
PickupAddScore:
  JP AddScore
; This entry point is used by the routine at CollectPickup.
PowerUpShield:
  LD HL,ChargeReset       ; the minimum power + 2, up to $10
  LD A,$02
  ADD A,(HL)
  CP $11
  RET NC
  LD (HL),A
  LD (Charge),A           ; the power meter starts there
  RET
; This entry point is used by the routine at CollectPickup.
SpeedUpShield:
  LD HL,ChargeStep        ; the meter's rate + 1, up to 3
  LD A,$01
  ADD A,(HL)
  CP $04
  RET NC
  LD (HL),A
  RET
; This entry point is used by the routine at CollectPickup.
PowerResetShield:
  LD A,$00                ; the minimum power 0
  LD (ChargeReset),A
  LD (Charge),A
  JR ResetShieldScore
; This entry point is used by the routine at CollectPickup.
SpeedResetShield:
  LD A,$01                ; the rate 1
  LD (ChargeStep),A
ResetShieldScore:
  LD E,$8E                ; 400
  JR PickupAddScore
; This entry point is used by the routine at CollectPickup.
VitalityRefill:
  LD A,$20                ; vitality full ($20)
  LD (Vitality),A
  RET

; Put the energy ball back after a room change
;
; From EnterRoom `$95F4` when `$6651` is set: BC = the ball's 16-bit timer left
; (`$651E`), then SpawnShield `$9962`. deaths 2 runs.
;
; Witness: L1 16 (deaths, play48, rzx x8, rzxroom x1).
RestoreShield:
  LD HL,ActorPage9+$001E
  LD C,(HL)
  INC L
  LD B,(HL)

; The energy ball (kind $48) in page $65 for BC frames
;
; BC = the frames. The position: the ball's own (`$6500`) when it is already
; there, else Hiro's Y and X + 8. InitActor `$A65D` with the template `$6594`,
; kind `$48`; `$6651` = `$48` (LoseEnergy `$9615` and TouchHiro `$9824` ignore
; harm while it is set; the IM 2 tick clears it when the page-`$65` timer runs
; out, `$84AB`, and so does `$91CB`). Then the 16-bit timer (SetActorTimer
; `$9991`).
;
; Callers: LoseLife `$9632` (170 frames after a lost life), CollectPickup
; `$98E8` (the invulnerability pickup, `$355` = 853 frames, 17 s at 50 Hz: the
; manual's "sixteen second period"), RestoreShield `$995C`, `$872B`. deaths and
; gameover 7 runs.
;
; Witness: L1 113 (deaths, gameover, havok, hiscore, play48, rzx x53, rzxroom
; x2).
SpawnShield:
  PUSH BC
  LD HL,ActorPage9
  LD BC,(ActorPage9)
  LD A,(ActorPage9+$0002)
  RRA
  JR C,SpawnShieldPut
  LD BC,(Hiro)            ; no ball yet: at Hiro, X + 8
  LD A,B
  ADD A,$08
  LD B,A
SpawnShieldPut:
  LD DE,ActorPage9+$0094  ; kind $48 in page $65
  LD A,$48
  CALL InitActor
  LD (Invulnerable),A     ; $6651: harm is ignored
  EX DE,HL
  POP BC
  JR SetActorTimer

; A kind with bit 7 set starts its life: bit 7 off, 255 frames
;
; HL = the actor's page (from StepActor `$9AB3`, every step: 8195 runs). A
; pickup that pops out of a broken block is spawned with kind + `$80`
; (BreakReveal `$9F1D`): StrikeActor leaves it alone until its first step,
; which clears the bit and gives it 255 frames before it vanishes. deaths 1
; run.
;
; Witness: L1 272892 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
StartLifetime:
  LD L,$1C
  BIT 7,(HL)
  RET Z
  RES 7,(HL)
  LD BC,$00FF

; The 16-bit timer +$1E/+$1F of page H = BC
;
; The IM 2 tick counts it down and sets +$10 bit 5 at zero (`$8490-$84A3`).
;
; Witness: L1 364 (bossgate, deaths, gameover, havok, hiscore, play48, throw,
; poke-room x2, rzx x64, rzxroom x9).
SetActorTimer:
  LD L,$1E
  LD (HL),C
  INC L
  LD (HL),B
  RET
; This entry point is used by the routine at CollectPickup.
LetterPickup:
  INC HL                  ; an EXTRA or BONUS letter: its attribute lit
  LD A,$47                ; bright white
  INC HL
  LD L,(HL)               ; the record's last byte: the letter's attribute cell
                          ; in row $5AE0
  LD H,$5A
  LD (HL),A
  LD HL,ExtraBonusLit     ; EXTRA all lit? ($5AE9-$5AED against five $47)
  LD DE,Attributes+745
  CALL MatchLetters
  JR NZ,LetterBonus
  LD HL,ExtraBonusUnlit   ; yes: the five back to $42 (BC = 5 from
                          ; MatchLetters)
  LDIR
  LD HL,Lives             ; an extra life, $79FF = 1 (the main loop's EXTRA
                          ; announce)
  LD A,$01
  LD (MessageRequest),A
  ADD A,(HL)
  DAA
  LD (HL),A
  LD B,$01                ; the lives' digits
  LD DE,LivesDigits
  JR BcdToDigits
LetterBonus:
  LD HL,ExtraBonusLit     ; BONUS all lit? ($5AF2-$5AF6)
  LD DE,Attributes+754
  CALL MatchLetters
  RET NZ
  LD HL,ExtraBonusUnlit   ; yes: back to $42, $79FF = 2, 10000
  LDIR
  LD A,$02
  LD (MessageRequest),A
  LD E,$C2
  JR AddScore

; Do the five attributes at DE equal the five at HL?
;
; HL = `$5C3D` (five `$47`), DE = the word's attributes. Out: Z when all five
; match; DE kept; BC = 5 when they matched (B counted down, C = 5), the length
; the LDIR after it copies.
;
; Witness: L1 9 (rzx x4, rzxroom x1). Not run in the keyed recordings.
MatchLetters:
  LD BC,$0505
  PUSH DE
MatchLettersLoop:
  LD A,(DE)
  CP (HL)
  JR NZ,MatchLettersDone
  INC HL
  INC DE
  DJNZ MatchLettersLoop
MatchLettersDone:
  POP DE
  RET

  ORG $9A27

; Do the boxes of actors H and D overlap?
;
; The boxes are +$2A (left column), +$2B (right), +$2C (top row), +$2D
; (bottom), in cells (`$8F3B` writes them on every move). D's left - 1 must be
; below H's right and D's right not below H's left, the same for the rows; a D
; edge of 0 skips the first test of its axis. Out: carry set when they overlap.
; L and E changed. 134974 runs: TouchHiro, StrikeActor, `$8A90`.
;
; Witness: L1 694628 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
BoxesOverlap:
  LD L,$2B
  LD E,$2A
  LD A,(DE)               ; D's left - 1 ...
  DEC A
  JP M,BoxesOverlapX2
  CP (HL)                 ; ... at or past H's right: apart
  RET NC
BoxesOverlapX2:
  LD A,E                  ; D's right below H's left: apart
  LD E,L
  LD L,A
  LD A,(DE)
  CP (HL)
  JR C,BoxesOverlapDone
  LD L,$2D                ; the rows the same way
  LD E,$2C
  LD A,(DE)
  DEC A
  JP M,BoxesOverlapY2
  CP (HL)
  RET NC
BoxesOverlapY2:
  LD A,E
  LD E,L
  LD L,A
  LD A,(DE)
  CP (HL)
BoxesOverlapDone:
  CCF                     ; carry: they overlap
  RET

  ORG $9AFD

; Hiro's move from the input: on a ladder, or walk / jump / climb
;
; From Hiro's handler `$9333` with D = dX x 2, E = dY x 4 from the controls
; (`$850C`). On a ladder (+2 bit 3) ClimbMove `$9C4A`; else MoveActor `$9B05`.
; 1102 runs.
;
; Witness: L1 16670 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
HiroMove:
  XOR A
  LD L,$02
  BIT 3,(HL)
  JP NZ,ClimbMove

; Move actor HL by D, E: turn, jump or climb, walk, stand
;
; D = dX, E = dY (negative up). Used by Hiro (HiroMove) and the walkers'
; handlers (`$9348`, `$93AF`, ...): 2836 runs.
;
; A D against the facing (+$1B) turns (`JP M,$90B1`, the turn animation). E
; negative: `$9023`, the jump (D = 0: the ladder above first, LadderAbove
; `$9CA7`). E positive: with a D the down is ignored; without it the ladder
; below (LadderBelow `$9CA1`) starts the climb down (`$906C`), else the actor
; stands (`$9B4A`). E = 0: walk: ProbeVertical `$9CF8` (the floor under),
; ProbeWalls `$9D8E` (D = 0 at a wall); Hiro with no X move stands; else the
; walk counters +$24, +$25 count up (+$24 is the run-up: 4 steps give the long
; jump, `$9038`). When Hiro stands on an object (+$10 bit 3, TouchHiro) the
; flag is cleared, he is no longer in the air and does not move in X. Then
; ApplyMove `$9B56`.
;
; Witness: L1 37599 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
MoveActor:
  LD A,D
  OR A
  JR Z,MoveActorY
  LD L,$1B                ; against the facing: turn
  XOR (HL)
  JP M,StartTurn
MoveActorY:
  LD A,E                  ; up: the jump
  OR A
  JP M,ActorJump
  JR Z,MoveWalk
  LD A,D                  ; down: with a D, just walk
  OR A
  JR NZ,MoveDownWalk
  CALL LadderBelow        ; no D: a ladder below?
  JP NZ,GrabLadder
  LD E,D                  ; no: stand
  JR MoveStand
MoveDownWalk:
  LD E,$00
MoveWalk:
  CALL ProbeVertical      ; the floor under, the walls ahead
; This entry point is used by the routine at WeaponControl.
MoveProbeWalls:
  CALL ProbeWalls         ; the walls ahead (entry from WeaponControl)
  LD A,H                  ; Hiro not moving in X: stand
  CP $5D
  JR NZ,MoveWalkCount
  LD A,D
  OR A
  JR Z,MoveStand
MoveWalkCount:
  LD L,$24                ; the walk counters
  INC (HL)
  LD L,$25
  INC (HL)
  LD L,$10                ; on an object: not in the air, no X move
  BIT 3,(HL)
  JR Z,ApplyMove
  RES 3,(HL)
  LD L,$02
  RES 1,(HL)
  LD D,$00
  JR ApplyMove
MoveStand:
  XOR A

; +$24, +$25 = A, then ApplyMove
;
; Witness: L1 13601 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
SetWalkCounters:
  LD L,$24
  LD (HL),A
  LD L,$25
  LD (HL),A
  JR ApplyMove

; ApplyMove with D = E = 0
;
; Witness: L1 19343 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
ApplyNoMove:
  LD DE,$0000

; Move actor HL by D, E: the gate, the touches, the position, the frame
;
; The Y before the move goes to the operand at `$95B4` (CheckRoomExit undoes
; the step's vertical part at a column crossing). Hiro: `$8F01` (a gate of the
; room, the table `$76D2`: D = 0 at its X). Falls into ApplyMoveNoGate. 5141
; runs.
;
; Witness: L1 94606 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ApplyMove:
  LD L,$00
  LD A,(HL)
  LD (RoomExitSetX+$0005),A ; the old Y for CheckRoomExit
  LD A,H
  CP $5D
  JR NZ,ApplyMoveNoGate
  PUSH HL
  CALL RoomBarrier        ; Hiro: the room's gate
  POP HL

; The touches and strikes, then the move
;
; ActorInteractions `$9698` (IY, HL, DE kept), then AddMove.
;
; Witness: L1 148167 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ApplyMoveNoGate:
  PUSH IY
  PUSH HL
  PUSH DE
  CALL ActorInteractions
  POP DE
  POP HL
  POP IY

; Y + E, X + D, then the frame
;
; Also used by `$A73E`. 13932 runs.
;
; Witness: L1 159028 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
AddMove:
  LD A,E
  LD L,$00
  ADD A,(HL)
  LD (HL),A
  INC L
  LD A,D
  ADD A,(HL)
  LD (HL),A

; Keep the last move, animate, then Hiro's room test
;
; +$21 = E / 4 (signed), +$22 = D; AnimateActor `$9BB6`. Outside play (the
; handler's flag `$845F` set: the title and high-score screens) done. Hiro:
; FootstepSound `$9BA2` and `JP $955A` (CheckRoomExit). Other kinds below
; `$47`: +$20 bit 1. 13986 runs.
;
; Witness: L1 160342 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
AnimateAfterMove:
  LD A,E
  LD L,$21
  SRA A
  SRA A
  LD (HL),A
  LD L,$22
  LD (HL),D
; This entry point is used by the routines at DecorControl and TriggerControl.
MoveAnimate:
  CALL AnimateActor       ; animate the actor (entry from DecorControl,
                          ; TriggerControl)
  LD A,(InterruptHandler+$0009) ; not in play
  OR A
  RET NZ
  LD L,$1C
  LD A,(HL)
  CP $24
  JR NZ,MarkMoved
  CALL FootstepSound      ; Hiro: footsteps and the room edges
  JP CheckRoomExit
MarkMoved:
  CP $47                  ; kinds below $47: +$20 bit 1
  RET NC
  LD L,$20
  SET 1,(HL)
  RET

; Hiro's footstep: sound 7 on frames $26 and $28
;
; The operand at `$9BA3` is the effect's current level (written at `$8545`; on
; a 128K AY channel A's volume): no footstep while it is not 0, so never over
; an audible effect (a sustain of 0 does not stop it). Frames `$26`, `$28` are
; the walk frames with a foot down. 2348 runs, 10 footsteps (c1, deaths, menu).
;
; Witness: L1 42125 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
FootstepSound:
  LD A,$00                ; LD A,n: n = the effect's level (0: no effect
                          ; sounds)
  OR A
  RET NZ
  LD L,$23
  LD A,(HL)
  CP $26
  JR Z,FootstepPlay
  CP $28
  RET NZ
FootstepPlay:
  LD A,$07
  LD (EffectRequest),A
  RET

; Choose the frame +$23 and the frame delay
;
; An action slot that runs (`$8E89`: +$30-$38 not all 0) animates by itself:
; +$20 bit 0 stays set. Frozen (+$10 bit 7): nothing; bit 6 freezes after this
; frame (bit 7 set). No walk animation (+6 = 0): the frame +$0A, the delay
; +$0C. In the air: +$0A, delay 1. On a ladder: delay 4, the frame from the Y
; (`$7AFB`[1 + (Y / 4) mod 4]). Walking: the delay +$0C (x 2 + 1 when the flag
; at `$9BE9` is set: walking into a wall, ProbeWalls), the frame = the table at
; +5/+6 [1 + +$25], +$25 wrapping at the table's count. 13986 runs.
;
; Witness: L1 162563 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
AnimateActor:
  LD L,$20
  SET 0,(HL)
  CALL ActorInSequence    ; an action slot runs: it animates
  RET NZ
  LD L,$20
  RES 0,(HL)
  LD L,$10
  BIT 7,(HL)              ; frozen
  RET NZ
  BIT 6,(HL)              ; freeze after this frame
  JR Z,AnimateFrame
  SET 7,(HL)
  RES 6,(HL)
AnimateFrame:
  LD L,$20
  SET 0,(HL)
  XOR A
  LD L,$06                ; no walk animation: the still frame
  OR (HL)
  JR Z,StaticAnim
  LD L,$02                ; in the air
  BIT 1,(HL)
  JR NZ,AirAnim
  RES 2,(HL)              ; on a ladder?
  BIT 3,(HL)
  JR NZ,ClimbAnim
  LD L,$0C                ; the frame delay ...
  LD A,(HL)
  LD L,$00                ; LD L,n: n = $80 after a wall (ProbeWalls $9DBB), 0
                          ; (StepActor $9AB6)
  RL L
  JR NC,WalkAnimDelay
  RLA                     ; ... twice as long, + 1
WalkAnimDelay:
  CALL SetFrameDelay
  LD L,$05                ; the walk animation: a count, then the frames
  LD E,(HL)
  INC L
  LD D,(HL)
  LD A,(DE)
  LD C,A
  LD L,$25                ; the step +$25, wrapping at the count
  LD A,(HL)
  CP C
  JR C,WalkAnimFrame
  XOR A
  LD (HL),A
WalkAnimFrame:
  INC A                   ; the frame: table[1 + step]
  ADD A,E
  LD E,A
  LD A,(DE)
  LD L,$23
  LD (HL),A
  RET
ClimbAnim:
  LD A,$04                ; climbing: delay 4, the frame from (Y / 4) mod 4
  CALL SetFrameDelay
  LD DE,Script9C0E        ; the climb frames
  LD C,$04
  LD L,$00
  LD A,(HL)
  RRA
  RRA
  AND $0F
ClimbAnimMod:
  SUB C
  JP P,ClimbAnimMod
  ADD A,C
  JR WalkAnimFrame
StaticAnim:
  LD L,$0C                ; the delay +$0C
  LD A,(HL)
  JR FixedFrame
AirAnim:
  LD A,$01                ; in the air: delay 1
FixedFrame:
  CALL SetFrameDelay      ; the frame +$0A
  LD L,$0A
  LD A,(HL)
  LD L,$23
  LD (HL),A
  RET

; +$1A and the frame timer +$1D = A
;
; Witness: L1 92498 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
SetFrameDelay:
  LD L,$1A
  LD (HL),A
  LD L,$1D
  LD (HL),A
  RET

; No input: Hiro stops, the walk counters cleared, the still frame
;
; From Hiro's handler `$933C` when the controls give nothing: walking (+$24 not
; 0), the counters are cleared and AnimateAfterMove `$9B7A` runs with no move.
; 2835 runs, 54 stops.
;
; Witness: L1 16221 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x15).
StopActor:
  LD L,$24
  LD A,(HL)
  OR A
  RET Z
  LD (HL),$00
  LD L,$25
  LD (HL),$00
  LD DE,$0000
  JP AnimateAfterMove
; This entry point is used by the routine at HiroMove.
ClimbMove:
  LD A,E                  ; on a ladder: up or down?
  RLA
  JR NC,ClimbDown
  LD D,$00                ; up: no X; the ceiling
  CALL ProbeCeiling
  LD A,$10                ; the cell at Y + $10, X + 2: a ladder's top ($53,
                          ; plane $6A) stops the climb
  ADD A,(HL)
  INC L
  LD H,(HL)
  INC H
  INC H
  LD L,A
  CALL CellIndex
  LD L,A
  LD H,$6A
  LD A,(HL)
  PUSH IY
  POP HL
  CP $53
  JP NZ,ApplyMove
  LD E,$00
  JP ApplyMove
ClimbDown:
  PUSH DE                 ; down or none: the floor 4 below
  CALL ProbeBelow
  POP BC
  JP NZ,ApplyMove
  LD L,$16                ; the cell at the feet: $55 (plane $6A) keeps E = 4
  LD A,(HL)
  LD L,$00
  ADD A,(HL)
  INC L
  LD H,(HL)
  INC H
  INC H
  LD L,A
  CALL CellIndex
  LD L,A
  LD H,$6A
  LD A,(HL)
  LD H,$5D
  CP $55
  LD E,$00
  JR NZ,ClimbLeave
  LD E,$04
ClimbLeave:
  LD D,B                  ; a sideways push leaves the ladder ($9078)
  LD A,D
  OR A
  JP Z,ApplyMove
  LD L,$1B
  SRA D
  LD (HL),D
  JP LeaveLadder

; Is there a ladder to climb down under the actor?
;
; From MoveActor `$9B1A` (down pressed with no X). ProbeBelow `$9CEE`: on a
; floor, the cell under (B) is tested by LadderCellTest. Out: NZ when the cell
; holds a ladder top (`$55` or `$54` in plane `$6A`, the list `$73C5`) and X is
; on the ladder (X mod 16 = 0 or 8). c1, menu: 31 runs, none found.
;
; Witness: L1 1608 (bossgate, menu, play48, c x1, rzx x28).
LadderBelow:
  CALL ProbeBelow
  RET NZ
  JR LadderCellTest

; Is there a ladder to climb up above the actor?
;
; From the jump `$9027` with no X. ProbeVertical `$9CF8` with E = 0, then the
; cell one row up (B - `$14`) is tested as in LadderBelow. Out: NZ: climb (`JP
; NZ,$906C`). 10 runs.
;
; Witness: L1 484 (havok, play48, rooms, c x1, opt x3, rzx x40).
LadderAbove:
  LD E,$00
  CALL ProbeVertical
  RET NZ
  LD A,B
  SUB $14
  LD B,A
; This entry point is used by the routine at LadderBelow.
LadderCellTest:
  LD L,B                  ; the cell's tile in plane $6A
  LD H,$6A
  LD A,(HL)
  LD HL,SpecialTiles      ; a ladder top: $55 or $54
  LD BC,$0002
  CPIR
  PUSH IY
  POP HL
  JR NZ,LadderNo
  LD L,$01                ; on the ladder's column: X mod 16 = 0 or 8
  LD A,(HL)
  AND $0F
  JR Z,LadderYes
  CP $08
  JR Z,LadderYes
LadderNo:
  XOR A
  RET
LadderYes:
  INC A
  RET

; The jump slot ends: +$30 = 0, then StartFall
;
; From `$921C` and `$9225`: 50 runs.
;
; Witness: L1 884 (bossgate, deaths, gameover, havok, hiscore, play48, rooms, c
; x1, opt x3, rzx x64, rzxroom x11).
StartFallEndJump:
  LD L,$30
  LD (HL),$00

; In the air (+2 bit 1), then FallStep
;
; From `$9201`: 242 runs.
;
; Witness: L1 4542 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
StartFall:
  LD L,$02
  SET 1,(HL)

; One step of a fall: 4 pixels down, the fall counter
;
; From StepActor `$9ACC` while in the air: 615 runs. +2 bit 2 (falling);
; ProbeBelow `$9CEE` (4 down): on landing E = 0 and the landing runs from there
; (`$90C3` for Hiro: a fall of `$14` steps or more, 80 pixels, starts the fall
; damage, 2 x (steps - `$11`) up to `$0E` steps of 2 energy; the orbs shatter,
; `$9159`). The fall counter +$26: + 1 a step, 0 after a landing (`$FF` + 1).
; Then SetWalkCounters `$9B4B` with 1 and the move.
;
; Witness: L1 11152 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
FallStep:
  LD L,$02
  SET 2,(HL)
  CALL ProbeBelow
  LD L,$26
  LD A,E
  OR A
  JR NZ,FallCount
  LD (HL),$FF             ; landed: the counter back to 0
FallCount:
  INC (HL)
  LD A,$01
  JP SetWalkCounters

; ProbeVertical with E = 4 and C = the height - E
;
; Witness: L1 13043 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
ProbeBelow:
  LD DE,$0004
  LD A,(IY+$16)
  SUB E
  LD C,A
  JR ProbeVerticalC

; The floor under the actor's move: land, start a fall, or go on
;
; C = the height +$16 (the height - E from ProbeBelow), D, E = the move. Only
; for actors that stand on floors (+$10 bit 1, tested at `$9CFB`) and when E is
; not negative (ProbeFloorCell). Out: HL = IY; Z when the move goes on, NZ when
; it stopped or started a fall.
;
; Witness: L1 99089 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ProbeVertical:
  LD C,(IY+$16)

; +$10 bit 1: the actor stands on floors
;
; Witness: L1 112132 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ProbeVerticalC:
  BIT 1,(IY+$10)
  JR Z,ProbeVerticalDone
  LD A,E
  OR A
  CALL P,ProbeFloorCell
ProbeVerticalDone:
  PUSH IY
  POP HL
  RET

; At a cell boundary, the floor under the new position
;
; H = X + D, L = Y + E; only when Y + E + C is a multiple of 16 (the feet on a
; cell edge). FloorUnder `$9D58`; then returns to ProbeVertical's caller (the
; `POP HL`). No floor: on a ladder nothing, else +2 bits 1, 2 (in the air,
; falling). A floor (`$9D2B`): E = 0; when the actor was in the air the bits
; are cleared and it lands: Hiro `JP $90C3` (the landing, the fall damage), the
; orbs (kinds `$20-$22`) `JP $9159` (they shatter: the manual's "if they hit a
; floor, they will shatter"), the other kinds from `$23` nothing, the pickups
; (kinds below `$20`) stop turning (FreezeAnim `$9D50`) unless the cell is a
; breakable one (TestBreakable `$9EBB`).
;
; Witness: L1 64304 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ProbeFloorCell:
  LD A,D
  ADD A,(IY+$01)
  LD H,A
  LD A,E
  ADD A,(IY+$00)
  LD L,A
  ADD A,C                 ; the feet on a cell edge?
  AND $0F
  RET NZ
  CALL FloorUnder
  POP HL                  ; return to ProbeVertical's caller
  PUSH IY
  POP HL
  JR NZ,Landed
  LD L,$02                ; no floor: on a ladder, stay
  BIT 3,(HL)
  RET NZ
  LD A,$06                ; else in the air and falling
  OR (HL)
  LD (HL),A
  RET
Landed:
  LD E,$00                ; a floor: stop
  LD L,$02
  BIT 1,(HL)
  RET Z
  LD A,$F9                ; land: in the air and falling off
  AND (HL)
  LD (HL),A
  LD L,$1C
  LD A,(HL)
  CP $24                  ; Hiro: the landing
  JP Z,HiroLanded
  CP $20                  ; the orbs shatter
  JR C,LandedPickup
  CP $23
  JP C,DieOnLanding
  XOR A
  RET
LandedPickup:
  LD L,B                  ; a pickup: over a breakable cell keep turning
  PUSH HL
  CALL TestBreakable
  POP HL
  RET Z

; Stop the actor's animation after this frame
;
; +$10 bit 6 set, bit 7 cleared; A = 0. Also `$9112` (a hazard's trigger).
;
; Witness: L1 1531 (bossgate, deaths, play48, throw, poke-room x3, rzx x38,
; rzxroom x9).
FreezeAnim:
  LD L,$10
  SET 6,(HL)
  RES 7,(HL)
  XOR A
  RET

; Is there a solid cell under the actor's feet?
;
; HL = Y, X of the test; C = the height. Clipped at the left (+$20 bit 6): the
; column at + 0; at the right (bit 7): + 8; else the middle (width / 2 - 1),
; then width / 2 when that one is free. Out: NZ when solid (CellSolid `$9D7A`).
;
; Witness: L1 57081 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
FloorUnder:
  LD A,(IY+$20)
  BIT 6,A
  JR NZ,FloorUnderLeft
  BIT 7,A
  JR Z,FloorUnderMiddle
  LD B,$08
  JR CellSolid
FloorUnderLeft:
  LD B,$00
  JR CellSolid
FloorUnderMiddle:
  LD B,(IY+$15)
  SRL B
  DEC B
  CALL CellSolid
  RET NZ
  LD B,(IY+$15)
  SRL B

; Is the cell at Y + C, X + B solid?
;
; `$8EB5` gives the cell (the row from Y / 16 through the table `$7000`, the
; column X / 8). Out: B = A = the cell, NZ when plane `$67` bits 0-1 are set.
; HL kept.
;
; Witness: L1 59319 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
CellSolid:
  PUSH HL
  LD A,L
  ADD A,C
  LD L,A
  LD A,H
  ADD A,B
  LD H,A
  CALL CellIndex
  LD L,A
  LD B,A
  LD H,$67
  LD A,(HL)
  AND $03
  OR A
  POP HL
  RET

; Stop an X move at a wall
;
; Only for actors with +$10 bit 0 set, not at the room's right edge (X `$95` or
; more) or the left (X 5 or less going left), and with D not 0. Probes the side
; it moves to (X + 1 left, X + width - 2 right) at three heights (ProbeSide
; `$9E31`). A wall: D = 0, the walk animation slows (`$9BE9` = `$80`), and a
; shot (kinds `$40-$46`) expires (ExpireActor). 3252 runs, 190 walls.
;
; Witness: L1 50771 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ProbeWalls:
  PUSH IY
  POP HL
  LD L,$10
  BIT 0,(HL)
  RET Z
  LD L,$01
  LD A,(HL)
  CP $95
  RET NC
  LD C,A                  ; no X move: done
  LD A,D
  OR A
  RET Z
  RLA                     ; left: probe at X + 1
  JR NC,ProbeWallsRight
  LD A,$05
  CP C
  RET NC
  LD A,$01
  JR ProbeWallsTest
ProbeWallsRight:
  LD A,(IY+$15)           ; right: at X + width - 2
  DEC A
  DEC A
ProbeWallsTest:
  CALL ProbeSide
  PUSH IY
  POP HL
  RET NZ
  LD D,$00                ; a wall: no X move, slow walk
  LD A,$80
  LD (AnimateFrame+$001A),A
  LD L,$1C                ; a shot at a wall expires
  LD A,(HL)
  CP $40
  RET C
  CP $47
  RET NC
  JP ExpireActor

; The cell Hiro's combat move hits (a breakable block?)
;
; From the combat move's slot `$91FB` while the strike can still hit (+2 bit
; 4). The column in front: X + width - 1 (right) or X + 1 (left), + 1 more for
; the sweep (power 3: `$0203` for `$0102`); the height: Y + 8, the sweep at the
; feet. ProbeCell `$9E3E` and through it BreakOrBlock `$9E61` (Hiro's move
; breaks a block). 42 runs.
;
; Witness: L1 1774 (bossgate, havok, menu, play48, c x1, opt x3, poke-room x15,
; rzx x55, rzxroom x8).
ProbeStrikeCell:
  LD DE,$0000
  PUSH IY
  POP HL
  LD BC,$0102
  LD A,(Strike)           ; the sweep: one column further
  CP $03
  JR NZ,ProbeStrikeFacing
  LD BC,$0203
ProbeStrikeFacing:
  LD L,$1B
  LD A,(HL)
  RLA
  JR NC,ProbeStrikeRight
  LD A,B
  JR ProbeStrikeCall
ProbeStrikeRight:
  LD A,(IY+$15)
  SUB C
ProbeStrikeCall:
  CALL ProbeStrikeHeight
  PUSH IY
  POP HL
  RET

; Stop an upward move at a ceiling
;
; ProbeCeilingE, HL = IY. From `$9225` (the jump) and ClimbMove. 223 runs.
;
; Witness: L1 4780 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x64, rzxroom x11).
ProbeCeiling:
  CALL ProbeCeilingE
  PUSH IY
  POP HL
  RET

; E negative: probe the head's corners; blocked: E = 0
;
; Witness: L1 4780 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x64, rzxroom x11).
ProbeCeilingE:
  LD A,E
  OR A
  RET P
  CALL ProbeHead
  RET NZ
  LD E,$00
  RET

; Probe above the head: the left and right corners (or the one inside)
;
; Witness: L1 4307 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x64, rzxroom x11).
ProbeHead:
  LD A,(IY+$20)
  BIT 6,A
  JR NZ,ProbeHeadLeft
  BIT 7,A
  JR NZ,ProbeHeadRight
  CALL ProbeHeadLeft
  RET Z
ProbeHeadRight:
  LD A,(IY+$15)           ; X + width - 2
  DEC A
  DEC A
  JR ProbeAtTop

; X + 1
;
; Witness: L1 4283 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, opt x3, rzx x64, rzxroom x11).
ProbeHeadLeft:
  LD A,$01

; ProbeCell at X offset A, Y + 8
;
; Witness: L1 53015 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
ProbeAtTop:
  LD B,A
  LD A,$08
  JR ProbeCell

; ProbeCell at X offset A: Y + 8, or the feet for the sweep
;
; Witness: L1 1774 (bossgate, havok, menu, play48, c x1, opt x3, poke-room x15,
; rzx x55, rzxroom x8).
ProbeStrikeHeight:
  LD B,A
  LD A,(Strike)
  CP $03
  JR Z,ProbeAtFoot
  LD A,$08
  JR ProbeCell

; ProbeCell at Y + height / 2
;
; Witness: L1 40878 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
ProbeAtMiddle:
  LD A,(IY+$16)
  RRCA
  JR ProbeCell

; Probe a side at three heights: Y + 8, the middle, the feet
;
; B = the X offset. Out: Z when one of them is a wall.
;
; Witness: L1 44626 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
ProbeSide:
  CALL ProbeAtTop
  RET Z
  CALL ProbeAtMiddle
  RET Z

; ProbeCell at Y + height - 4
;
; Witness: L1 38556 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
ProbeAtFoot:
  LD A,(IY+$16)
  SUB $04

; Is the cell at Y + E + A, X + D + B a wall?
;
; A = the Y offset, B = the X offset. Off the room's bottom (Y `$E0` or more):
; no wall. The cell goes to `$69E2` (SpawnSparks's position); BreakOrBlock
; `$9E61` first; then plane `$68`: tiles 1-`$19` are walls. Out: Z = a wall.
; 8935 runs.
;
; Witness: L1 133377 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
ProbeCell:
  ADD A,E
  ADD A,(IY+$00)
  LD L,A
  CP $E0                  ; below the room: free
  RET NC
  LD A,D
  ADD A,(IY+$01)
  ADD A,B
  LD H,A
  CALL CellIndex
  LD (Strike+$0001),A     ; the last probed cell
  LD L,A
  CALL BreakOrBlock       ; a breakable block?
  LD H,$68                ; the tile: 1-$19 a wall
  LD A,(HL)
  CP $01
  RET C
  CP $1A
  RET NC
  CP A
  RET

; A breakable cell: broken by Hiro's move or a shot, else it may block
;
; L = the cell, IY = the actor. Hiro during a combat move (+$34) and the shots
; (kinds `$40-$46`) break: TestBreakable `$9EBB` finds the block, the strike is
; spent (+2 bit 4), sound `$0D`, BreakReveal `$9ED7` (a hidden pickup), the
; cell's tile is cleared (in the plane TestBreakable matched), the cell redrawn
; (`$8868`), sparks (SpawnSparks), 10 points (`$CE`), the panel; then the probe
; returns to its caller: free for the scorchball (it flies on), a wall for the
; others. The break ran in `play48` at frame 1458 (a block broken in room 6,
; its item revealed).
;
; The other actors (`$9EB3`): a cell that blocks (TestBreakable's C = 1) is a
; wall for them (the return to ProbeCell is popped); else ProbeCell goes on.
; 8892 runs, 20 blocked (deaths, rooms).
;
; Witness: L1 133232 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
BreakOrBlock:
  LD A,(IY+$1C)
  CP $24
  JR NZ,BreakByBullet
  LD C,A                  ; Hiro in a combat move: breaks
  LD A,(IY+$34)
  OR A
  JR NZ,BreakBlock
  LD A,C
BreakByBullet:
  CP $40                  ; the shots break
  JR C,BlockTest
  CP $47
  JR NC,BlockTest
BreakBlock:
  CALL TestBreakable      ; a breakable cell?
  RET NZ
  RES 4,(IY+$02)          ; the strike is spent
  LD A,$0D                ; sound $0D
  LD (EffectRequest),A
  PUSH BC
  PUSH DE
  PUSH IY
  PUSH HL
  CALL BreakReveal        ; the hidden pickup
  POP HL
  LD (HL),$00             ; the tile gone
  LD A,(RevealedZones)    ; redraw the cell when its block is revealed
  AND $FC
  CALL RedrawCellMask
  CALL SpawnSparks        ; sparks
  POP IY
  LD E,$CE                ; 10 points
  CALL AddScore
  CALL PrintScore
  POP DE
  POP BC
  POP AF                  ; drop the return into ProbeCell
  LD A,(IY+$1C)           ; the scorchball flies on (NZ), the rest stop (Z)
  CP $41
  JR Z,BreakPassThrough
  CP A
  RET
BreakPassThrough:
  INC A
  RET
BlockTest:
  CALL TestBreakable      ; other actors: a breakable cell that blocks is a
                          ; wall
  RET NZ
  DEC C
  RET NZ
  POP BC                  ; drop the return: Z, a wall
  RET

; Does the cell L hold a breakable block?
;
; Plane `$69` tile `$19` or `$1A`: Z, C = 1; plane `$69` or `$6A` tile `$8C`:
; Z, C = 0; plane `$6A` tile `$8D` or `$19`: Z, C = 1. Else NZ. Out: H = the
; plane matched (BreakOrBlock clears the tile there), C = 1 when the block also
; stops the actors that cannot break it.
;
; Witness: L1 133297 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
TestBreakable:
  LD C,$01
  LD H,$69
  LD A,(HL)
  CP $19
  RET Z
  CP $1A
  RET Z
  DEC C                   ; $8C: breakable, does not block
  CP $8C
  RET Z
  LD H,$6A                ; plane $6A
  LD A,(HL)
  CP $8C
  RET Z
  INC C                   ; $8D: blocks
  CP $8D
  RET Z
  CP $19
  RET

; A block broken: mark it, and drop the pickup hidden in it
;
; L = the cell. Plane `$67` bit 1 of the cell cleared. The room's hidden-item
; list at `$5B02` (pairs: the cell, the content before it) is searched for the
; cell; the item's number B gives the bit `$80` >> (B - 1) set in `$6DFE` (the
; room's taken bits, saved per room by `$A58A`). Content & `$1F` = 0: nothing.
; Else the kind is kept in the operand at `$9F1C`; its record (`$A652`) gives
; the frame and score copied into the pickup template `$65BF-$65C0` (`$65C1` =
; 1, `$65C2` = 0); a free page among `$5E-$64` (FindFreeActorAtCell `$9F29`);
; InitActor `$A65D` with kind + `$80` (StartLifetime gives it 255 frames at its
; first step) at the cell; +2 bits 1, 2: it drops. Ran in `play48` at frame
; 1458 (a block broken in room 6, its item revealed).
;
; Witness: L1 51 (bossgate, play48, throw, rzx x25, rzxroom x4).
BreakReveal:
  LD H,$67
  RES 1,(HL)
  LD A,L
  LD HL,RoomObjectList             ; the hidden-item list
  LD B,$01
FindHiddenLoop:
  INC HL
  CP (HL)
  JR Z,FoundHidden
  INC HL
  INC B
  JR FindHiddenLoop
FoundHidden:
  DEC HL                  ; DE = the content byte
  EX DE,HL
  LD HL,TakenItems        ; the item's taken bit
  XOR A
  SCF
HiddenBitLoop:
  RRA
  DJNZ HiddenBitLoop
  OR (HL)
  LD (HL),A
  LD A,(DE)               ; the content: 0 empty
  AND $1F
  RET Z
  LD (HiddenBitLoop+$002C),A ; the kind into the operand at $9F1C
  CALL TemplateForKind    ; its record: frame and score into the template
  EX DE,HL
  LD DE,SharedEnemyTemplate+$0007
  LDI
  LDI
  EX DE,HL
  LD (HL),$01
  INC HL
  LD (HL),$00
  LD B,$07                ; a free page among $5E-$64
  LD HL,IntroBox+$0007
  CALL FindFreeActorAtCell
  RET C
  LD C,E
  LD B,D
  LD DE,SharedEnemyTemplate
  LD A,$00                ; LD A,n: n = the pickup's kind
  OR $80                  ; kind + $80: StartLifetime at its first step
  CALL InitActor
  LD E,$02                ; it drops: in the air, falling
  LD A,(DE)
  OR $06
  LD (DE),A
  RET

; DE = the cell $69E2's Y, X; then FindFreeActor
;
; Witness: L1 26 (bossgate, play48, throw, rzx x16, rzxroom x1). Ran in
; `play48` at frame 1458 (a block broken in room 6, its item revealed).
FindFreeActorAtCell:
  CALL LastCellPixel

; The first inactive page among B pages from HL
;
; HL = page + 2 of the first. Out: carry clear and H = the free page; carry set
; when all B are active. Also used by `$A5BF`.
;
; Witness: L1 2441 (bossgate, deaths, gameover, hiscore, play48, rooms, throw,
; c x1, poke-room x13, rzx x64, rzxroom x18).
FindFreeActor:
  LD A,(HL)
  RRA
  RET NC
  INC H
  DJNZ FindFreeActor
  SCF
  RET
