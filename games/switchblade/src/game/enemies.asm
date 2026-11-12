; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: Enemies and hazards
; --------------------------------------------------------------------------------------------------------------------

  ORG $9348

; Kinds $2C, $37-$3D: walk toward Hiro, a few random steps when level with him
;
; The state handler of the walking enemies. +`$27` > 0: one step less, the same
; direction +`$1B`. Else Hiro's X (`$5D2A` x 2) against the actor's X: to his
; side, D = 2 or `$FE` toward him; level: a random direction from the frame
; counter `$8473` (bit 6) and +`$27` = 0-7 steps of it. The step goes to
; WalkStep `$9B05` (which also turns them: StartTurn `$90B1`).
;
; Witness: rooms 82 runs (`$9348` only in rooms). Witness: L1 17816 (bossgate,
; rooms, poke-room x8, rzx x55, rzxroom x10).
ChaserControl:
  LD L,$27
  XOR A
  LD E,A
  OR (HL)
  JR Z,ChaserTowardHiro
  DEC (HL)
  JR ChaserStep
ChaserRandom:
  LD A,(GameTick+$0001)   ; level with Hiro: a random direction and run
  ADD A,A
  ADD A,A
  LD D,$02
  JR C,ChaserSetDir
  LD D,$FE
ChaserSetDir:
  LD L,$1B
  LD (HL),D
  AND $07
  LD L,$27
  LD (HL),A
ChaserStep:
  LD L,$1B
  LD D,(HL)
  JP MoveActor
ChaserTowardHiro:
  LD A,(Hiro+$002A)
  RLA
  LD L,$01
  CP (HL)
  JR Z,ChaserRandom
  LD D,$02
  JP NC,MoveActor
  LD D,$FE
  JP MoveActor

; Kinds $00-$23, $2A (pickups and objects): no step, only the floor test
;
; DE = 0; `$9CF8` (the floor test when +`$10` bit 1); `$9B66` (the move and the
; room-edge test without the barrier test). The items carry their number in the
; kind (bit 7 set: `$9987` starts a 255-frame life +`$1E` and clears it).
;
; Witness: deaths 134 runs. Witness: L1 53561 (bossgate, deaths, play48, throw,
; poke-room x5, rzx x45, rzxroom x8).
StillControl:
  LD DE,$0000
  CALL ProbeVertical
  JP ApplyMoveNoGate

; Kind $3E: no move, +$25 counts the steps (the animation)
;
; DE = 0, +`$25` + 1, then `$9B85` (the redraw and room test without a move).
; Template `$64DC`, from `$6F28` of the image. Not run in the keyed recordings
; (the RZX run has it).
;
; Witness: L1 738 (rzx x5).
DecorControl:
  LD DE,$0000
  LD L,$25
  INC (HL)
  JP MoveAnimate

; Kind $3F: when Hiro enters its zone, +$0A = 1 and +$10 bit 6 (shown)
;
; HiroInZone `$9529` (zone +`$11` of TouchZones `$5FAC`). Hiro inside: the
; still frame +`$0A` = 1, `$9D50` (+`$10` bit 6 set, bit 7 cleared), `$9B85`.
; Outside: `$9B85` while +`$10` bit 7 is clear, else nothing. Template `$64CA`,
; from `$6F16`. Not run in the keyed recordings; the RZX snapshots hold kind
; `$3F` on pages `$5E-$63`.
;
; Witness: L1 104705 (poke-room x1, rzx x17, rzxroom x5).
TriggerControl:
  CALL HiroInZone
  JR C,TriggerTouched
  LD L,$10
  BIT 7,(HL)
  JP Z,MoveAnimate
  RET
TriggerTouched:
  LD L,$0A
  LD A,$01
  LD (HL),A
  CALL FreezeAnim
  JP MoveAnimate

; Kind $36: Hiro below it (zone 5) shakes it ($7BB5, 30 frames) and lets it
; fall
;
; HiroInZone `$9529` with zone 5 (Hiro 16 above to 31 below, within 16 pixels
; either side). Inside: StalactiteShake `$9112` (in StartPoseSeq): `$9D50` and
; the script `$7BB5` (speed 7, frames `$23`-`$26`) in +`$32`; at its end
; SequenceEndDrop `$9201` drops it (+`$02` bits 1, 2: the fall).
;
; Witness: rooms 84 runs. Witness: L1 2693 (rooms, rzx x10).
StalactiteControl:
  CALL HiroInZone
  JP C,StalactiteShake
  RET

; Kind $2B: N steps right, N steps left (N = +$12, 16)
;
; First step: +`$12` moves to +`$3E` (cleared). +`$3F` counts the right steps
; (D = 2) down past 0, then +`$40` (N + 1) the left steps (D = `$FE`), then
; both are reloaded. WalkStep `$9B05`.
;
; Witness: L1 3637 (deaths, gameover, hiscore, play48, rooms, c x1, rzx x3,
; rzxroom x5).
PatrolControl:
  XOR A
  LD E,A
  LD L,$12
  OR (HL)
  JR Z,PatrolStep
  LD (HL),E
  LD L,$3E
  LD (HL),A
PatrolReload:
  LD L,$3F
  LD (HL),A
  INC A
  INC L
  LD (HL),A
PatrolStep:
  LD D,$02
  LD L,$3F
  DEC (HL)
  JP P,MoveActor
  INC L
  DEC (HL)
  JR Z,PatrolTurnBack
  LD D,$FE
  JP MoveActor
PatrolTurnBack:
  LD L,$3E
  LD A,(HL)
  JR PatrolReload

; Kinds $2E-$31, $34: wait until Hiro enters zone +$11, then run the path
;
; +`$1B` = +`$12` (the direction). HiroInZone `$9529`: no zone (+`$11` = 0):
; PathControl `$93FB`; Hiro outside: no move (TrapStill `$93EB`); inside:
; +`$27` = +`$11`, +`$11` = 0, so it runs its path from the next step;
; PathRestart's end puts the zone back (TrapRearm `$93EE`). Templates `$62DC`,
; `$63EE`, `$6482`, `$6494`, `$64A6` (from `$6E2C`, `$6EBC`-`$6EF2`). Not run
; in the keyed recordings.
;
; Witness: L1 1982 (rzx x5, rzxroom x4).
TrapControl:
  LD L,$12
  LD A,(HL)
  LD L,$1B
  LD (HL),A
  CALL HiroInZone
  JR Z,PathControl
  JR NC,TrapStill
  LD L,$11
  LD E,(HL)
  LD (HL),$00
  LD L,$27
  LD (HL),E

; No move this step (the waiting trap): `JP $9B53`
;
; From TrapControl `$93E1` (Hiro outside its zone) and its tails TrapRearm
; `$93EE` and ShotPathEnd `$93F6`. Not run in the keyed recordings.
;
; Witness: L1 1100 (bossgate, havok, rzx x13, rzxroom x4).
TrapStill:
  JP ApplyNoMove
; This entry point is used by the routine at PathControl.
TrapRearm:
  LD L,$27                ; the path ended: the zone back
  LD A,(HL)
  LD L,$11
  LD (HL),A
  JR TrapStill
; This entry point is used by the routine at PathControl.
ShotPathEnd:
  CALL ExpireActor        ; the boss shot's path ended: it expires
  JR TrapStill

; Kinds $25-$29, $32, $33, $35, $47, $48 and the boss shot $2D: follow the path
; +$06/+$07
;
; +`$1B` = 1 when +`$05` is `$46`, else +`$12` (the direction). Entry
; PathControlShot `$940A` (kind `$2D`, its direction already copied). The path
; (page +`$06`, offset +`$07`): a header (bits 0-5 the segment count to +`$40`,
; the whole to +`$3F`: bit 6 a random step delay +`$0C` per segment, bit 7 one
; per step, RandomSpeed `$9505`), then segments of [steps][Y step][X step].
; +`$3E` counts a segment's steps, +`$3A`/+`$3B` points at its Y step. The X
; step is mirrored when +`$12` bit 7 is set. At a segment's start the bosses
; (kinds `$25-$29`) may fire (BossFire `$947D`). When the last segment ends:
; the traps `$93D6` re-arm, the shot `$940A` expires, the rest start the path
; again.
;
; Each step: kind `$48` (the shield) steers to Hiro (ShieldFollow `$94E1`);
; +`$25` + 1; the shot (kind `$2D`) gets the wall test `$9D8E`; MoveActor
; `$9B56`.
;
; Witness: L1 12290 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, opt x3, rzx x66, rzxroom x9).
PathControl:
  LD L,$05
  LD A,(HL)
  CP $46
  LD A,$01
  JR Z,PathControlDir
  LD L,$12
  LD A,(HL)
PathControlDir:
  LD L,$1B                ; +$1B = the direction
  LD (HL),A
PathControlShot:
  XOR A                   ; kind $2D enters here
  LD L,$3E
  OR (HL)
  JR Z,PathRestart
  LD L,$3A
  LD C,(HL)
  INC L
  LD B,(HL)
  JR PathStep
PathEnd:
  LD L,$03                ; the last segment ended
  LD A,(HL)
  CP $D6
  JR Z,TrapRearm
  CP $0A
  JR Z,ShotPathEnd
PathRestart:
  LD L,$07                ; header: +$3F, +$40
  LD C,(HL)
  LD L,$06
  LD B,(HL)
  LD L,$3F
  LD A,(BC)
  LD (HL),A
  INC C
  INC L
  AND $3F
  LD (HL),A
  JR PathSegmentStart
PathSegmentEnd:
  LD L,$40
  DEC (HL)
  JP M,PathRestart
  JR Z,PathEnd
  INC C                   ; the next segment: past the Y and X step
  INC C
PathSegmentStart:
  CALL BossFire           ; a boss may fire; +$3E = the steps
  LD A,(BC)
  INC A
  INC C
  LD L,$3E
  LD (HL),A
  LD L,$3A
  LD (HL),C
  INC L
  LD (HL),B
  LD A,$40
  CALL RandomSpeed
PathStep:
  LD L,$3E
  DEC (HL)
  JR Z,PathSegmentEnd
  LD A,$80
  CALL RandomSpeed
  LD A,(BC)
  INC C
  LD E,A
  LD A,(BC)
  LD L,$12
  BIT 7,(HL)
  JR Z,PathStepX
  NEG
PathStepX:
  LD D,A
  LD L,$1C
  LD A,(HL)
  CP $48
  CALL Z,ShieldFollow
  LD L,$25
  INC (HL)
  LD L,$1C
  LD A,(HL)
  CP $2D
  CALL Z,ProbeWalls
  JP ApplyMove

; A boss (kinds $25-$29) at the start of a path segment fires its shot (kind
; $2D on page $6000)
;
; D = the segments left +`$40`; HL = the actor; BC = the path. The boss's fire
; table lies in the path's page at +`$11`: [n] then n pairs [segment][shot path
; offset]. A match: the shot's path offset to `$61E0` (the template `$61DC`,
; its +`$07`); a shot still on page `$6000` is expired (`$97A3`) and run
; (ActorUpdate) until its page is free; the new one is spawned (SpawnActor
; `$A65D`, kind `$2D`) at the boss's Y + +`$09`, X + +`$0A`, facing as the boss
; (+`$1B` copied); sound 6. BC, HL kept.
;
; Called at every segment start of every path mover (209 calls in deaths,
; gameover, menu, rooms, opt2-4), and the kind test passes in bossgate (3
; shots) and havok (1): the fire itself is `$9487` on. The RZX run's snapshot
; at frame 136 000 has Havok (kind `$25`) on page `$5E` and a shot (kind `$2D`,
; handler PathControlShot `$940A`) on `$6000`.
;
; Witness: L1 4894 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, opt x3, rzx x66, rzxroom x9).
BossFire:
  LD D,(HL)
  LD L,$1C
  LD A,(HL)
  CP $25
  RET C
  CP $2A
  RET NC
  LD L,$09
  PUSH BC
  PUSH HL
  LD A,D
  LD E,(HL)
  INC L
  LD D,(HL)
  LD L,$11
  LD L,(HL)
  LD H,B
  LD B,(HL)
  INC L
BossFireFind:
  CP (HL)
  JR Z,BossFireMatch
  INC L
  INC L
  DJNZ BossFireFind
  POP HL
  POP BC
  RET
BossFireMatch:
  INC L
  LD A,(HL)
  LD (SizeClasses+$015E),A
  LD HL,HavokRoomEnter+$002E
  LD A,(HL)
  RRA
  JR NC,BossFireSpawn
  PUSH DE
  PUSH IY
  CALL ExpireActor
  LD L,$02
BossFireClearOld:
  CALL ActorUpdate        ; run the old shot to its end
  LD A,(HL)
  RRA
  JR C,BossFireClearOld
  POP IY
  POP DE
BossFireSpawn:
  POP HL
  PUSH HL
  LD L,$00
  LD A,(HL)
  ADD A,E
  LD C,A
  INC L
  LD A,(HL)
  ADD A,D
  LD B,A
  LD HL,HavokRoomEnter+$002E
  LD DE,SizeClasses+$015A
  LD A,$2D
  CALL InitActor
  POP HL
  LD A,$06
  LD (EffectRequest),A
  LD L,$1B
  LD A,(HL)
  LD E,L
  LDI
  POP BC
  RET

; Kind $48: steer toward Hiro, E = +-4 and D = +-2 when outside a 32 x 8 window
;
; E = 4 (down) or `$FC` when Hiro's Y - Y + 16 is outside 0-31; D = 2 or `$FE`
; when his X - X + 4 is outside 0-7. The shield (kind `$48`, page `$6500`,
; spawned by `$9978` with `$6651` set) follows him until its life (+`$1E`) ends
; (the tick clears `$6651`).
;
; Witness: L1 2516 (deaths, havok, play48, rzx x53, rzxroom x2).
ShieldFollow:
  LD A,(Hiro)
  LD L,$00
  SUB (HL)
  ADD A,$10
  CP $20
  JR C,ShieldFollowX
  LD E,$04
  JP P,ShieldFollowX
  LD E,$FC
ShieldFollowX:
  LD A,(Hiro+$0001)
  LD L,$01
  SUB (HL)
  ADD A,$04
  CP $08
  RET C
  LD D,$02
  RET P
  LD D,$FE
  RET

; With the path header +$3F AND A set: +$0C (the step delay) = a random 0-7
;
; A = `$40` (per segment) or `$80` (per step); `$A632` (15 rounds of the
; generator at `$8473`), AND 7. +`$0C` is the walk delay `$9BE5` puts into
; +`$1A`/+`$1D` after each move (frames to the next step): the mover changes
; speed at random. Callers: PathControl `$944D`, `$9457`.
;
; Witness: L1 19642 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, opt x3, rzx x66, rzxroom x9).
RandomSpeed:
  LD L,$3F
  AND (HL)
  RET Z
  EXX
  CALL Random
  EXX
  AND $07
  LD L,$0C
  LD (HL),A
  RET

  ORG $9529

; Is Hiro inside the proximity zone of actor H?
;
; H = the actor's page. Its byte +$11 picks a zone record (1-based, 0 = no
; zone: returns with carry clear) in the 4-byte table that starts at `$5FAC`
; (`$5FA8` + 4 x index): dY low, dY high, dX low, dX high. dY = Hiro's Y
; (`$5D00`) - the actor's Y passes when dY >= low or dY < high (a range that
; may wrap below zero: `$F0`, `$01` is -16..0), the same for dX with the X
; bytes (`$5D01`). Out: carry set when both pass.
;
; The only caller is the hazard handler at `$93A8` (`CALL $9529` / `JP
; C,$9112`): when Hiro comes close the hazard starts its animation `$7BB5`, the
; manual's proximity-sensing floor spikes. Run 84 times in the rooms recording;
; 3 tests reached the X bytes and none passed.
;
; The table sits in actor page `$5F` above its record (bytes `$5FA8-$5FCB` in
; the play snapshots `c1/end.szx`).
;
; Witness: L1 109380 (rooms, poke-room x1, rzx x28, rzxroom x6).
HiroInZone:
  XOR A
  LD L,$11                ; +$11: the zone number, 0 none
  OR (HL)
  RET Z
  LD B,A
  LD IX,IntroScript+$015B ; IX = $5FA8 + 4 x zone
  LD DE,$0004
HiroInZoneIndex:
  ADD IX,DE
  DJNZ HiroInZoneIndex
  LD L,$00
  LD A,(Hiro)             ; dY = Hiro's Y - the actor's Y
  SUB (HL)
  CP (IX+$00)             ; dY >= low: pass
  JR NC,HiroInZoneX
  CP (IX+$01)             ; dY < high: pass, else out (carry clear)
  RET NC
HiroInZoneX:
  LD L,$01                ; the same with dX = Hiro's X - the actor's X
  LD A,(Hiro+$0001)
  SUB (HL)
  CP (IX+$02)
  JR NC,HiroInZoneYes
  CP (IX+$03)
  RET NC
HiroInZoneYes:
  SCF                     ; carry: inside
  RET

  ORG $A59B

; Start the enemies standing in revealed zones
;
; A = RevealedZones `$6DFF` (callers `$8A90`, `$91A9`, `$95C3`); `$A59E` with A
; = a zone mask (from `$955A`, the zone just revealed).
;
; For each of the `$6ADD` enemy records at (`$6ADE`), the 16 bits `$6EFE` /
; `$6EFF` shifted left give one bit an enemy: clear (not gone) calls SpawnEnemy
; `$A5BF`. 27 + 109 runs.
;
; Witness: L1 830 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
SpawnRoomEnemies:
  LD A,(RevealedZones)

; SpawnZoneEnemies
;
; Used by the routine at CheckRoomExit.
SpawnZoneEnemies:
  LD C,A
  LD A,(EnemyCount)
  OR A
  RET Z
  LD B,A
  LD IX,(EnemyListPtr)
  LD DE,(GoneEnemies)
SpawnRoomEnemiesLoop:
  PUSH BC
  RL D
  RL E
  PUSH DE
  CALL NC,SpawnEnemy
  INC IX
  INC IX
  POP DE
  POP BC
  DJNZ SpawnRoomEnemiesLoop
  RET

; Put an enemy into a free actor page when its zone is revealed
;
; IX = the enemy record (kind, cell), B = its number (counting down), C = the
; zone mask. Nothing when the cell's zone is not in C, or the slot `$68DB` + B
; is already set (the enemy is on), or none of the 7 pages `$5E00-$6400` is
; free (`$9F2C`).
;
; The slot gets B; `$8ECA` turns the cell into the X and Y; TemplateForKind
; `$A652` gives the 18-byte template; kinds below `$20` and `$20-$22` use the
; shared template `$65B8` with its first two bytes copied from the kind's
; template to `$65BF` and `$65C1`/`$65C2` = `$03`/`$1F` (kinds below `$20`) or
; `$04`/`$3F` (`$20-$22`); InitActor `$A65D`; +`$29` = the enemy number; kinds
; with bit 7 or `$40` and up get +`$28` = Random `$A632` AND +`$0D`.
;
; 468 runs, 21 spawns (`$A5D0`).
;
; Witness: L1 3701 (bossgate, deaths, gameover, havok, hiscore, play48, rooms,
; c x1, poke-room x14, rzx x68, rzxroom x17).
SpawnEnemy:
  LD L,(IX+$01)
  LD H,$67
  LD A,C
  AND (HL)
  RET Z
  LD HL,TitleColours+$01E1 ; the enemy's slot in $68DC-$68EB
  LD A,L
  ADD A,B
  LD L,A
  XOR A
  OR (HL)
  RET NZ
  PUSH BC
  EX DE,HL
  LD B,$07
  LD HL,IntroBox+$0007    ; a free actor page among $5E00-$6400
  CALL FindFreeActor
  POP BC
  RET C
  LD A,B
  LD (DE),A
  EX AF,AF'
  PUSH HL
  LD A,(IX+$01)
  CALL CellPixel
  LD B,D
  LD C,E
  PUSH BC
  LD A,(IX+$00)
  CALL TemplateForKind
  CP $20
  LD BC,$1F03
  JR C,SpawnEnemySharedTemplate
  CP $23
  JR NC,SpawnEnemyInit
  LD BC,$3F04
SpawnEnemySharedTemplate:
  EX DE,HL
  LD DE,SharedEnemyTemplate+$0007
  LDI
  LDI
  EX DE,HL
  LD DE,SharedEnemyTemplate
  LD (HL),C
  INC L
  LD (HL),B
SpawnEnemyInit:
  POP BC
  POP HL
  LD L,$00
  PUSH HL
  LD A,(IX+$00)
  CALL InitActor
  EX AF,AF'
  LD E,$29
  LD (DE),A
  LD A,(IX+$00)
  RLA
  JR C,SpawnEnemyRandom
  CP $40
  JR C,SpawnEnemyDone
SpawnEnemyRandom:
  CALL Random             ; +$28 = Random AND +$0D
  POP HL
  LD L,$0D
  AND (HL)
  LD L,$28
  LD (HL),A
  RET
SpawnEnemyDone:
  POP HL
  RET

; Stir the 16-bit counter at $8473 fifteen times; A = its new low byte
;
; The seed is the operand of the tick's `LD HL,n` (`$8472`, the frame counter).
; One step: HL = HL + swap(HL) + bytes, x 4, + DE, x 8, + DE; 15 steps.
; Callers: `$9505`, SpawnEnemy `$A5BF`. 92 runs.
;
; Witness: L1 2482 (bossgate, deaths, gameover, hiscore, play48, rooms, c x1,
; poke-room x13, rzx x55, rzxroom x17).
Random:
  LD B,$0F
RandomLoop:
  LD HL,(GameTick+$0001)
  LD E,H
  LD D,L
  ADD HL,DE
  LD A,(GameTick+$0002)
  ADD A,L
  LD E,A
  LD A,(GameTick+$0001)
  ADD A,H
  LD D,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD (GameTick+$0001),HL
  LD A,L
  DJNZ RandomLoop
  RET
