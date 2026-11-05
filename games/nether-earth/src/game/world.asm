; --------------------------------------------------------------------------------------------------------------------
; world.asm: the world turn: each robot's step (sight, fire, steering by order, movement) and each shot's flight
;
; The war itself: once a game turn WorldTurn lets the enemy commander act, then moves every live robot record and
; every flying shot. The player never fights directly; everything a robot does on its own is here. Docs: 07-objects.md
; 7.1-7.4 (the records, the step, the shots) and 10-gameplay-logic.md 10.4-10.6 (a robot's turn, the orders, shooting
; and damage).
;
; Robots, in calling order: WorldTurn -> UpdateRobot (dying blink, RobotDestroyed) -> RobotStep: the step delay,
; FreeDirections (the probes CanMoveRight / Left / Down / Up over TestCell), then RobotDirectControl, or SpotEnemies
; (ScanLane, LaneSteps) and fire (FindFreeShot, FireShot), or SteerByOrder (the targets: TargetRobotRecord,
; FindNearestOpponent, TargetBuildingTable, FindTargetBuilding, ConsiderBuilding; the shared InitNearestSearch /
; KeepNearest / ColumnDistance; the aim RobotAim, RobotLeanTo, PickOneDirection) -> RobotMove: TurnOrStep
; (StepPosition, GroundUnderFootprint, MoveShip under direct control), SetStepDelay (StepDelays), PlaceRobot.
;
; Shots: WorldTurn -> UpdateShot -> MoveShot (2 cells a turn, the wall test with GroundUnderFootprint, the 3x3 hit
; test, the damage); FireShot runs the first MoveShot at once. ShotGone / MoveShotGone free the record and set
; SoundFx.
;
; Data it works on, all outside the module: the robot records Robots $DA00 (ours, slots 0-23) and EnemyRobots $DB80
; (the computer's, 24-47), 16 bytes each (+$00/+$01 cell, +$02/+$03 X, +$04 Y, +$05 course, +$06 steps left, +$07
; parts, +$08 facing, +$09 height, +$0A control, +$0B order, +$0C strength, +$0D ground, +$0E target, +$0F delay);
; Shots $D7D3, 5 x 9 bytes; the capture points Warbases $FD70 / Factories $FD84 (5 bytes, read from the owner byte
; +3); the map $DD00 (16 rows of $200 cells: bits 0-4 the terrain type, 6 an object's anchor, 7 the ship). It owns
; only the tables StepDelays $B61D and LaneSteps $B6B0.
;
; Conventions: a direction is one Input bit (1 right, 2 left, 4 down, 8 up) and a set of directions is a nibble in C
; or E. Side $FD51 (0 ours, 1 the enemy's) is set by RobotStep and decides which tables the searches read. A robot is
; 2x2 cells but only its anchor (X, Y) carries bit 6, so the probes look for anchors one cell around the cells
; entered. The map is the only index: a robot or a shot that meets bit 6 asks FindRobot whose anchor it is.
;
; Tricks: ScanLane loads HL with LaneSteps - 2 (assembled as ScanLaneDone+1) and steps it by D's bit; the nearest
; searches keep the best distance and our column in the shadow registers (BC', DE'); a target index $FF read as a
; building record falls into the IM 2 table ($FD bytes, owner bits $E0) and so counts as "find another";
; FindTargetBuilding leaves HL past the table, which makes one wrong aim after a new building target (the bug at
; SteerByOrder).
; --------------------------------------------------------------------------------------------------------------------

; one game turn of the world: the enemy commander, every robot, every shot
;
; Called once a game turn by the play loop (PlayLoop) and by the menus
; (DirectControl, ListMenu), so robots fight and walk on while the player
; chooses: 3415 calls in 36046 frames, a turn is about 10 frames. First
; EnemyCommander (one enemy slot built or re-ordered), then UpdateRobot for
; each of the 48 robot records $DA00 whose +$01 is not 0, then UpdateShot for
; each of the 5 shot records of 9 bytes at $D7D3 whose +$01 is not 0. Robots
; and shots are taken in slot order, the player's slots 0-23 first. Shot record
; 0 ($D7D3) is the one the player fires from the robot menu's COMBAT MODE
; (DirectControl -> FireShot); the robots use records 1-4 (FindFreeShot).
WorldTurn:
  CALL EnemyCommander     ; first the computer: one of its slots built or
                          ; re-ordered
  LD B,$30                ; the 48 robot records
  LD IY,Robots            ; IY = the first record, slot 0 (ours; 24-47 the
                          ; enemy's follow at $DB80)
WorldTurnRobotLoop:
  PUSH BC                 ; a live robot (+$01 = the high byte of its cell, 0 =
                          ; free)
  LD A,(IY+$01)           ; +$01 = 0: a free slot
  OR A                    ; (test it)
  CALL NZ,UpdateRobot     ; a live robot takes its turn
  LD DE,$0010             ; the next 16-byte record
  ADD IY,DE               ; (IY on it)
  POP BC                  ; the record count back
  DJNZ WorldTurnRobotLoop ; all 48
  LD IY,Shots             ; the 5 shot records
  LD B,$05                ; record 0 the player's COMBAT MODE shot, 1-2 ours,
                          ; 3-4 the enemy's
WorldTurnShotLoop:
  PUSH BC                 ; a live shot
  LD A,(IY+$01)           ; +$01 = 0: no shot in this record
  OR A                    ; (test it)
  CALL NZ,UpdateShot      ; a flying shot takes its step
  LD DE,$0009             ; the next 9-byte record
  ADD IY,DE               ; (IY on it)
  POP BC                  ; the record count back
  DJNZ WorldTurnShotLoop  ; all 5
  RET                     ; the turn is over

; one robot's game turn: dying, destroyed or a step of its AI
;
; IY = the robot record. Strength +$0C decides: positive, the robot acts
; (RobotStep); negative, the robot is dying: +$0C counts up from $FC (set by
; MoveShot's hit) and the object bit 6 of its cell is toggled each turn
; (cleared on even values, set on odd), so for four turns other robots and
; shots see it only every other turn; 0, the robot is destroyed
; (RobotDestroyed). 49165 calls.
UpdateRobot:
  LD A,(IY+$0C)           ; A = the strength +$0C
  OR A                    ; zero, positive or negative (dying)?
  JR Z,RobotDestroyed     ; strength 0: destroyed
  JP P,RobotStep          ; strength positive: alive
  INC (IY+$0C)            ; dying: one turn closer to 0
  LD L,(IY+$00)           ; HL = the robot's anchor cell ...
  LD H,(IY+$01)           ; ... (high byte)
  AND $01                 ; the old value's bit 0: the object bit flickers
  JR NZ,RobotDyingShow    ; odd old value: show the robot this turn
  RES 6,(HL)              ; even: hidden from sight and shots this turn
  RET                     ; done: a dying robot does nothing else
RobotDyingShow:
  SET 6,(HL)              ; odd: the object is there
  RET                     ; done
RobotDestroyed:
  LD L,(IY+$00)           ; remove the robot: a wreck on bare ground, the dot,
                          ; the slot, the counts
  LD H,(IY+$01)           ; (the cell's high byte)
  RES 6,(HL)              ; no object on its cell any more
  LD A,(HL)               ; OR of the four footprint cells (X, Y), (X+1, Y),
                          ; (X+1, Y-1), (X, Y-1)
  INC HL                  ; (X+1, Y)
  OR (HL)                 ; (OR it in)
  DEC H                   ; one row up ...
  DEC H                   ; ... (rows are $200 apart): (X+1, Y-1)
  OR (HL)                 ; (OR it in)
  DEC HL                  ; (X, Y-1)
  OR (HL)                 ; (OR it in)
  INC H                   ; back down to the anchor row ...
  INC H                   ; ... HL = (X, Y) again for PutBlock
  AND $3F                 ; bits 0-5: anything but bare type-0 ground?
  JR NZ,RobotRemove       ; something there already (terrain or a block part):
                          ; no wreck
  CALL Random             ; bare ground: a wreck, terrain type 6 or 7 at random
  AND $01                 ; 0 or 1 ...
  ADD A,$06               ; ... + 6: the wreck types 6 / 7 (height 3)
  CALL PutBlock           ; PutBlock: a 2x2 terrain feature of type A at HL
                          ; (the anchor A, the other three cells A + $20)
RobotRemove:
  LD L,(IY+$02)           ; erase its radar dot: layer B = +$0A bit 7 (0 ours,
                          ; 1 the enemy's)
  LD H,(IY+$03)           ; HL = its column, C = its row ...
  LD C,(IY+$04)           ; (the row)
  LD A,(IY+$0A)           ; B = the radar layer: bit 7 of +$0A ...
  RLCA                    ; (to bit 0)
  AND $01                 ; (only it)
  LD B,A                  ; (B = 0 ours $D800, 1 the enemy's $D900)
  CALL ToggleRadarDot     ; XOR the dot away
  LD (IY+$01),$00         ; the slot is free
  CALL CountRobots        ; recount: OurRobots $FD41, EnemyRobots $FD49
  CALL UpdateStatusPanel  ; and the status panel
  RET                     ; the robot is gone

; a live robot: wait for its step delay, then look, fire, steer and move one
; step
;
; Entered from UpdateRobot with strength > 0 (JP P). A robot the player sits on
; (+$0A = 1, the robot menu is open) does nothing. Side ($FD51) = 0 ours / 1
; the enemy's (+$0A bit 7), read by the target searches. The step delay +$0F
; counts the turns down; at 0 the robot leaves its cell (bit 6 cleared, radar
; dot erased) and FreeDirections gives C, the directions it can step to (bit 0
; right, 1 left, 2 down, 3 up, the Input order).
;
; Direct control (+$0A = 2): the stick decides (RobotDirectControl). Otherwise
; SpotEnemies gives E, the directions with a live opponent in sight. An
; opponent ahead (E AND the facing +$08): the robot moves on if it can and
; fires when a shot record of its side is free and its weapons allow
; (FindFreeShot, FireShot; a shot stops it for this step). An opponent to a
; side: it turns to it (+$05 = that direction, one picked at random among
; several, +$06 = 2). No opponent: it keeps its direction +$05 for +$06 more
; steps while that direction stays free, else it takes a new course for 3-6
; steps from SteerByOrder (RobotNewCourse). RobotMove then turns or steps,
; reloads the delay (SetStepDelay) and puts the robot back on the map
; (PlaceRobot: the record's x/y/cell, bit 6, the dot).
;
; Recording: 9652 steps; the shot records and strengths at frames 18680-18850
; match FireShot and MoveShot (robot 2 hit twice by an enemy missile, 100 -> 70
; -> 40; robot 25 hit by our cannon, 100 -> 80 -> 60 -> 40).
RobotStep:
  LD A,(IY+$0A)           ; A = the control byte +$0A: 0 AI, 1 the player on
                          ; it, 2 direct control, $80 the enemy's
  CP $01                  ; the player sits on it: frozen while the robot menu
                          ; is open
  RET Z                   ; frozen: no delay counted, nothing moves
  RLCA                    ; Side: 0 ours, 1 the enemy's
  AND $01                 ; (bit 7 of +$0A now in bit 0)
  LD (Side),A            ; Side = 0 / 1, read by the target searches
  DEC (IY+$0F)            ; the step delay
  RET NZ                  ; not yet: wait another turn
  LD L,(IY+$00)           ; time to step: off the map
  LD H,(IY+$01)           ; (the cell's high byte)
  RES 6,(HL)              ; the anchor's object bit off: no one sees it during
                          ; the step (nor its own shot hits it)
  PUSH HL                 ; keep the cell for FreeDirections
  LD L,(IY+$02)           ; erase its radar dot
  LD H,(IY+$03)           ; (HL = its column)
  LD C,(IY+$04)           ; C = its row
  LD A,(IY+$0A)           ; B = the radar layer, +$0A bit 7 ...
  RLCA                    ; (to bit 0)
  AND $01                 ; (only it)
  LD B,A                  ; (0 ours, 1 the enemy's)
  CALL ToggleRadarDot     ; the old dot off (PlaceRobot plots the new one)
  POP HL                  ; HL = the anchor cell again
  CALL FreeDirections     ; C = the free directions from this cell
  LD A,(IY+$0A)           ; A = the control byte again
  CP $02                  ; under direct control?
  JP Z,RobotDirectControl ; yes: the player's stick steers
  PUSH BC                 ; keep C, the free directions
  CALL SpotEnemies        ; E = the directions with an opponent in sight
  POP BC                  ; C back
  LD A,E                  ; A = the directions with an opponent ...
  OR A                    ; ... none?
  JR Z,RobotNoEnemy       ; nobody in sight
  AND (IY+$08)            ; an opponent straight ahead?
  JR Z,RobotTurnToEnemy   ; no: only to a side
  AND C                   ; move on ahead if free (else stand)
  LD (IY+$05),A           ; +$05 = the facing if free, else 0: stand
  PUSH IX                 ; keep the caller's IX
  PUSH IY                 ; keep the robot record (IY)
  PUSH IY                 ; IX = the shooter, IY = the free shot record
  POP IX                  ; (IX = the robot)
  CALL FindFreeShot       ; IY = a free shot record of the robot's side, Z when
                          ; one is free
  JR NZ,RobotNoShot       ; both of our side's shots are flying
  CALL Random             ; each weapon (bits 3 cannon, 4 missiles, 5 phasers)
                          ; fires this turn at even odds
  AND $38                 ; (the three weapon bits of a random byte)
  AND (IX+$07)            ; (those the robot carries)
  JR Z,RobotNoShot        ; no weapon chosen this turn
  LD C,$06                ; the highest chosen weapon: phasers 3, missiles 2,
                          ; cannon 1
RobotWeaponPick:
  DEC C                   ; count the rotations until the weapon bit leaves
  RLCA                    ; (the next bit into carry)
  JR NC,RobotWeaponPick   ; until the first set bit (the highest weapon) leaves
  LD A,C                  ; A = the weapon: 1 cannon, 2 missiles, 3 phasers
  CALL FireShot           ; launch the shot
  POP IY                  ; IY = the robot again
  POP IX                  ; the caller's IX back
  LD (IY+$05),$00         ; the shot costs the step: stand, decide again next
                          ; step
  LD (IY+$06),$01         ; one step on this course: the next step decides
                          ; again
  JR RobotMove            ; (a standing robot: TurnOrStep does nothing)
RobotNoShot:
  POP IY                  ; no shot: walk on ahead
  POP IX                  ; the caller's IX back
  LD (IY+$06),$01         ; one step on: ahead (+$05 set above) or standing
                          ; when blocked
  JR RobotMove            ; walk
RobotTurnToEnemy:
  LD C,E                  ; opponents to a side: face one of them
  LD B,C                  ; B = the set to pick from
  CALL CountDirections    ; several: one at random
  CALL NZ,PickOneDirection ; (more than one: PickOneDirection)
  LD (IY+$05),C           ; +$05 = that side: TurnOrStep turns to face it (a
                          ; turn needs no free cell)
  LD (IY+$06),$02         ; two steps on that course
  JP RobotMove            ; turn
RobotNoEnemy:
  DEC (IY+$06)            ; nobody in sight: keep the course while it lasts and
                          ; is free
  JP M,RobotNewCourse     ; spent: a new course
  LD A,(IY+$05)           ; the course ...
  AND C                   ; ... still free?
  JR NZ,RobotMove         ; yes: on along it
RobotNewCourse:
  CALL Random             ; a new course for 3-6 steps
  AND $03                 ; (0-3 ...)
  ADD A,$03               ; (... + 3)
  LD (IY+$06),A           ; +$06 = the steps of the new course (SteerByOrder
                          ; may set its own)
  CALL CountDirections    ; at least one free direction: ask the order
  CALL NC,SteerByOrder    ; (carry: boxed in, C = 0: stand)
  LD A,(IY+$01)           ; the robot blew itself up (a nuclear charge,
                          ; NuclearBlast)
  OR A                    ; (+$01 = 0 when NuclearBlast freed the slot)
  RET Z                   ; gone: nothing to move or place
  LD (IY+$05),C           ; +$05 = the new course (0: stand)
; This entry point is used by the routine at RobotDirectControl.
RobotMove:
  LD A,(IY+$05)           ; turn or step in +$05, the new delay, back on the
                          ; map
  LD L,(IY+$02)           ; HL = the column ...
  LD H,(IY+$03)           ; ... (high byte)
  LD B,(IY+$04)           ; B = the row
  CALL TurnOrStep         ; a turn, a step or nothing
  CALL SetStepDelay       ; +$0F = the turns to the next step
  JP PlaceRobot           ; PlaceRobot: store x / y / the cell, set bit 6, plot
                          ; the dot

; C = the direction the robot's order wants, chosen among the free ones in C
;
; IY the robot, C the free directions (FreeDirections); out C a single
; direction bit, or 0 to stand. B keeps the free set. By the order +$0B:
;
; 0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo). When that
; direction is free: two random bits for it, else a random free one other than
; the opposite, which may be it again (0.835 with all four free, 0.88 with up
; or down blocked, 1.0 in a corridor; docs/13 13.3.2). When it is blocked: any
; free one, the opposite included. RobotStepPos counts the distance +$0E.
;
; 3 destroy robots: the target is the opponent robot of index +$0E
; (TargetRobotRecord). It is kept while it lives and is less than 50 columns
; away; else the nearest live opponent by column distance is taken
; (FindNearestOpponent), none: a random free direction.
;
; 4-8 the building orders: the target is record +$0E of the factory table $FD84
; or the warbase table $FD70 (TargetBuildingTable). It is kept while its owner
; bits are still the ones the order looks for; else the nearest such building
; nobody of the side is already after is taken (FindTargetBuilding). None: the
; robot stands, and an enemy robot falls back to destroy robots.
;
; The aim (RobotAim): D = the directions toward the target, horizontal from the
; sign of the column difference, vertical from the row difference; for a
; building, while the columns differ, the row aimed at is 3 below the
; building's row. More than 7 columns away (the low byte of the column
; difference only) the robot leans horizontally like an advance (RobotLeanTo):
; the target's row is ignored. Closer, one of the free wanted directions at
; random (none free: any free one); when a horizontal one is among them, +$06 =
; |dx| - 1 for whichever is picked, a vertical one too. On the target (D = 0):
; the destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this
; range); the others turn the robot to face down and stand.
;
; Bug (experiment, breakpoint at $B2B8 after poking the target factory's
; owner): FindTargetBuilding leaves HL past the table, not on the new target,
; so the step right after a new building target aims at the bytes below $FDFF
; (the JP at $FDFD and Handler: row $66, column $C300; the warbase orders read
; factory 0's door). The wrong decision lasts a whole course of 3-6 steps:
; right from column 256 on; a random free direction on columns 14-255, rows
; 1-8; on columns 14-255, rows 9-15 the aim is "on the target": the robot faces
; down and stands, and a nuclear robot with order 4 blows up where it stands
; (NuclearBlast; experiment in docs/13 13.3.6). The next decision aims right.
SteerByOrder:
  LD B,C                  ; B = the free directions, kept for the random picks
  LD A,(IY+$0B)           ; the order
  OR A                    ; 0 stop?
  JR NZ,SteerMoveOrders   ; no: an order that moves
  LD C,A                  ; 0 stop: stand
  RET                     ; C = 0
SteerMoveOrders:
  CP $03                  ; orders 1-8: advance / retreat, destroy robots, the
                          ; building orders
  JP C,RobotLeanTo        ; 1-2: lean right / left (A AND 3 is the direction)
  JR NZ,SteerBuildingOrder ; 4-8: the building orders
  LD A,(IY+$0E)           ; 3 destroy robots: a target already?
  OR A                    ; +$0E = $FF: none
  JP M,SteerNewRobotTarget ; none: find one
  CALL TargetRobotRecord  ; HL = the target robot's record
  INC HL                  ; HL = its +$01
  LD A,(HL)               ; dead (its +$01 = 0)?
  OR A                    ; (+$01 = 0?)
  JR Z,SteerNewRobotTarget ; dead (slot free): find another (a dying one is
                           ; still a target)
  INC HL                  ; HL = its +$02
  LD A,(HL)               ; its column (low)
  INC HL                  ; (+$03)
  LD H,(HL)               ; (high)
  LD L,A                  ; HL = its column
  LD E,(IY+$02)           ; DE = our column ...
  LD D,(IY+$03)           ; ... (high byte)
  CALL ColumnDistance     ; HL = |its column - ours|
  LD A,H                  ; 256 columns or more ...
  OR A                    ; (test the high byte)
  JR NZ,SteerNewRobotTarget ; ... too far: another target
  LD A,L                  ; A = the distance
  CP $32                  ; less than 50 columns: chase it
  JR C,SteerAtRobot       ; yes: aim at it
SteerNewRobotTarget:
  LD L,(IY+$02)           ; find the nearest live opponent
  LD H,(IY+$03)           ; (HL = our column)
  LD (IY+$0E),$FF         ; no target while the search runs
                          ; (FindNearestOpponent does not read it)
  PUSH BC                 ; keep B, the free set
  CALL FindNearestOpponent ; D = the nearest opponent's slot in its side ($FF
                           ; none), Z: none
  POP BC                  ; B back (the flags stay)
  LD (IY+$0E),D           ; +$0E = its index, $FF none
  JP Z,PickOneDirection   ; nobody: wander
SteerAtRobot:
  CALL TargetRobotRecord  ; DE = the target's column, B = our row - its row
  INC HL                  ; (+$01)
  INC HL                  ; HL = its +$02
  LD E,(HL)               ; E = its column (low) ...
  INC HL                  ; (+$03)
  LD D,(HL)               ; ... D (high)
  INC HL                  ; HL = its +$04, the row
  LD A,(IY+$04)           ; our row ...
  SUB (HL)                ; ... - its row
  LD B,A                  ; B = the row difference (positive: we are below it)
  LD L,(IY+$02)           ; HL = our column ...
  LD H,(IY+$03)           ; ... (high byte)
  XOR A                   ; A = 0 and no carry for SBC
  SBC HL,DE               ; HL = our column - its column
  LD D,A                  ; D = 0: no wanted direction yet (the flags stay)
  JR Z,RobotAimVertical   ; same column: only the vertical part
  JR RobotAim             ; else the horizontal part first
SteerBuildingOrder:
  CALL TargetBuildingTable ; HL = the owner byte of the first record, E = the
                           ; owner the order wants
  LD A,(IY+$0E)           ; HL = the target record's owner byte (5 bytes a
                          ; record)
  LD B,A                  ; B = the index
  ADD A,A                 ; (2 x)
  ADD A,A                 ; (4 x)
  ADD A,B                 ; (5 x)
  CALL AddAToHL           ; HL += 5 x index ($FF lands in the IM 2 table, $FD:
                          ; owner bits $E0, never wanted)
  LD A,(HL)               ; its owner byte ...
  AND $E0                 ; ... bits 5-7: $20 the enemy's, $40 ours, $80
                          ; destroyed, 0 neutral
  CP E                    ; still a building we want?
  JR Z,SteerAtBuilding    ; yes: aim at it
  LD A,(IY+$0B)           ; no: find another
  PUSH BC                 ; keep C, the free set
  LD L,(IY+$02)           ; HL = our column ...
  LD H,(IY+$03)           ; ... (high byte)
  CALL FindTargetBuilding ; D = the new target, NZ: found (HL is left past the
                          ; table)
  POP BC                  ; C back (B is no longer the free set; the aim
                          ; reloads it from C)
  JR NZ,SteerNewBuilding  ; found one
  LD C,$00                ; none left: stand
  BIT 7,(IY+$0A)          ; ours: stand and wait
  RET Z                   ; (our robot: the order stays)
  LD (IY+$0B),$03         ; the enemy's: hunt robots instead
  RET                     ; (C = 0: stands this step)
SteerNewBuilding:
  LD (IY+$0E),D           ; another target building found: +$0E = its index
SteerAtBuilding:
  DEC HL                  ; B = our row - the building's row, DE = its column
  LD A,(IY+$04)           ; our row ...
  SUB (HL)                ; ... - the record's row (the door's)
  LD B,A                  ; B = the row difference
  DEC HL                  ; HL = +$01
  LD D,(HL)               ; D = its column (high) ...
  DEC HL                  ; (+$00)
  LD E,(HL)               ; ... E (low)
  LD L,(IY+$02)           ; HL = our column ...
  LD H,(IY+$03)           ; ... (high byte)
  XOR A                   ; A = 0 and no carry for SBC
  SBC HL,DE               ; HL = our column - its column
  LD D,A                  ; D = 0: no wanted direction yet
  JR Z,RobotAimVertical   ; same column: go for the door's own row
  LD A,B                  ; columns differ: aim at the row 3 below it
  SUB $03                 ; (the row aimed at: the door's + 3)
  LD B,A                  ; B = the new row difference
RobotAim:
  LD A,H                  ; horizontal: 2 left when we are right of it, 1 right
                          ; when left
  RRCA                    ; (H's bits 1-2 to bits 0-1: H is $FF / $FE when we
                          ; are left of it, 0 / 1 when right)
  AND $03                 ; (3 when we are left of it, 0 when right)
  XOR $02                 ; (1 right, 2 left)
  LD D,A                  ; D = the horizontal wanted direction
RobotAimVertical:
  LD A,B                  ; vertical: 8 up when we are below it, 4 down when
                          ; above
  OR A                    ; same row?
  JR Z,RobotAimCheck      ; yes: no vertical part
  RRCA                    ; (B's bits 4-5, its sign for B in -16..15 ...)
  RRCA                    ; (... rotated to bits 2-3)
  AND $0C                 ; ($0C when we are above it, 0 below)
  XOR $08                 ; (4 down, 8 up)
  OR D                    ; with the horizontal part ...
  LD D,A                  ; ... D = the wanted directions
RobotAimCheck:
  LD A,D                  ; D = the wanted directions: 0 means on the target
  OR A                    ; any?
  JR NZ,RobotAimMove      ; yes: move toward it
  LD C,A                  ; on the target: stand
  LD A,(IY+$0B)           ; the order ...
  CP $04                  ; ... below 4 (only 3 gets here)?
  JR C,RobotFaceDown      ; destroy robots: just face down
  CP $06                  ; destroy factories / warbases: the nuclear charge
  JP C,NuclearBlast       ; 4-5: blow up here (the robot and what is around it)
RobotFaceDown:
  LD A,(IY+$08)           ; on the target: face down and stand (destroy orders
                          ; blast first)
  CP $04                  ; facing down already?
  RET Z                   ; yes: stand (C = 0)
  LD C,$04                ; else turn down and stay so
  LD (IY+$06),$FF         ; the turn's INC makes it 0: the next step decides
                          ; again
  RET                     ; C = 4: TurnOrStep turns it down
RobotAimMove:
  LD A,L                  ; off the target: L = |the column difference|
  OR A                    ; (L's sign: only the low byte of the difference is
                          ; used)
  JP P,RobotAimColumns    ; positive: A = L
  NEG                     ; negative: A = -L
  LD L,A                  ; L = |the difference| (modulo 256)
RobotAimColumns:
  CP $08                  ; 8 or more columns away: lean horizontally (the row
                          ; ignored), else pick among the free wanted
                          ; directions
  LD B,C                  ; B = the free directions again
  LD A,D                  ; A = the wanted directions
  JR NC,RobotLeanTo       ; far: lean as an advance does
  AND C                   ; the wanted directions that are free
  JR Z,PickOneDirection   ; none: any free direction
  LD B,A                  ; B = the free wanted ones
  AND $03                 ; only vertical ones: pick one
  JR Z,PickOneDirection   ; (no horizontal part)
  LD A,L                  ; the columns agree: pick one
  OR A                    ; (a column difference of 0 modulo 256)
  JR Z,PickOneDirection   ; (no horizontal course to keep)
  DEC A                   ; keep a horizontal course for |dx| - 1 steps
  LD (IY+$06),A           ; +$06 = the steps of that course
  JR PickOneDirection     ; pick one of the free wanted ones
RobotLeanTo:
  AND $03                 ; D = the horizontal part (1 right, 2 left), E = all
                          ; but the opposite one
  LD D,A                  ; D = right or left
  XOR $FC                 ; (1 -> $FD, 2 -> $FE: every bit but the opposite
                          ; one)
  LD E,A                  ; E = the directions allowed when the lean fails
  LD A,C                  ; the free directions ...
  AND D                   ; wanted direction blocked: any free one, the
                          ; opposite included
  JR Z,PickOneDirection   ; (blocked)
  LD C,D                  ; C = the wanted direction
  CALL Random             ; two random bits for it (0.74 together; with the
                          ; fall-back pick 0.835 when all four are free)
  AND D                   ; (its bit in a random byte)
  RET NZ                  ; set: take it (1/2)
  CALL Random             ; a second try ...
  AND D                   ; (its bit again)
  RET NZ                  ; set: take it (another 1/4)
  LD A,B                  ; else: among the free ones but the opposite (it may
                          ; be the wanted one again)
  AND E                   ; (the free set ...)
  LD B,A                  ; (... without the opposite: B is not 0, it holds D)

; C = one direction bit picked at random from the set in B
;
; Masks C with random bytes until exactly one bit is left (CountDirections);
; when nothing is left it starts again from B. B must not be 0. The common exit
; of SteerByOrder's branches and used by RobotTurnToEnemy for several
; opponents.
PickOneDirection:
  LD C,B                  ; C = the whole set
PickOneLoop:
  CALL Random             ; C AND a random byte
  AND C                   ; (C AND it)
  LD C,A                  ; C = the narrowed set
  CALL CountDirections    ; how many are left?
  RET Z                   ; exactly one: done
  JR NC,PickOneLoop       ; still several: narrow on
  LD C,B                  ; none left: from the whole set again
  JR PickOneLoop          ; try again

; D = the nearest building the order wants and no teammate is after; Z when
; none
;
; A = the order (3 goes to FindNearestOpponent), HL = the robot's column, IY
; the robot, Side set. The order picks the table and owner
; (TargetBuildingTable); every record with those owner bits is offered to
; ConsiderBuilding, which skips it when a robot of our side with the same order
; already has it as its +$0E, and keeps the nearest by column distance
; (KeepNearest). Out D = the record's index (or $FF), A = D + 1 (Z: none). HL
; is left past the table: the cause of the bug noted at SteerByOrder.
; Recording: 112 calls (also from the enemy's order choice at $B989 and
; SetOrder).
FindTargetBuilding:
  CP $03                  ; 3 destroy robots ...
  JP Z,FindNearestOpponent ; ... is a search for a robot
  PUSH AF                 ; (keep A and the flags ...)
  EX AF,AF'               ; A' = the order, for ConsiderBuilding
  POP AF                  ; (... A stays the order too)
  CALL InitNearestSearch  ; the search: DE' = our column, BC' = the best
                          ; distance ($2000), C = the index, D = $FF
  CALL TargetBuildingTable ; HL = the first record's owner byte, B = the
                           ; records, E = the owner wanted
FindTargetLoop:
  LD A,(HL)               ; owner bits 5-7 the ones wanted?
  AND $E0                 ; (bits 5-7)
  CP E                    ; (the owner the order wants?)
  CALL Z,ConsiderBuilding ; yes: a candidate unless a teammate has it
  LD A,L                  ; next record (L only: the tables sit inside page
                          ; $FD)
  ADD A,$05               ; (5 bytes a record)
  LD L,A                  ; HL = the next owner byte
  INC C                   ; C = its index
  DJNZ FindTargetLoop     ; all records of the table
  LD A,D                  ; A = the index + 1: Z when none was found
  INC A                   ; ($FF + 1 = 0: Z)
  RET                     ; D = the index, Z when none

; offer building C to KeepNearest unless a teammate with the same order already
; targets it
;
; HL = the record's owner byte (+$03), C its index, A' the order. Scans the 24
; records of our side ($DA00 ours, $DB80 the enemy's by Side) for a live robot
; whose order +$0B is A' and whose target +$0E is C. None: the record's column
; (+$00/+$01) goes to KeepNearest. The robot that asks is in the list too; its
; +$0E holds its old target (or $FF).
ConsiderBuilding:
  PUSH IY                 ; keep the asking robot ...
  PUSH BC                 ; ... the loop count and index ...
  PUSH DE                 ; ... and the search result D, the owner E
  EX AF,AF'               ; A = the order (from A')
  LD E,A                  ; E = the order
  EX AF,AF'               ; A' = the order again
  LD IY,Robots            ; our side's robots
  LD A,(Side)            ; Side ...
  OR A                    ; (0 ours?)
  JR Z,ConsiderBuildingStart ; ours: $DA00
  LD IY,EnemyRobots       ; the enemy's: $DB80
ConsiderBuildingStart:
  LD B,$18                ; IY = the side's 24 robot records
ConsiderBuildingLoop:
  LD A,(IY+$01)           ; a live robot ...
  OR A                    ; (+$01 = 0: a free slot)
  JR Z,ConsiderBuildingNext ; free: next
  LD A,(IY+$0B)           ; ... with the same order ...
  CP E                    ; (the same order?)
  JR NZ,ConsiderBuildingNext ; no: next
  LD A,(IY+$0E)           ; ... after the same building?
  CP C                    ; (the same target index?)
  JR Z,ConsiderBuildingTaken ; yes: someone is after it already
ConsiderBuildingNext:
  PUSH DE                 ; the next 16-byte robot record
  LD DE,$0010             ; (16 bytes a record)
  ADD IY,DE               ; IY = the next record
  POP DE                  ; (E = the order again)
  DJNZ ConsiderBuildingLoop ; all 24 of the side
  POP DE                  ; D, E back (the best so far, the owner)
  POP BC                  ; B, C back (count, index)
  POP IY                  ; IY = the asking robot
  PUSH HL                 ; nobody: HL = the building's column
  DEC HL                  ; (+$02)
  DEC HL                  ; (+$01: X high)
  LD A,(HL)               ; A = X high
  DEC HL                  ; (+$00)
  LD L,(HL)               ; L = X low
  LD H,A                  ; HL = the door's column
  CALL KeepNearest        ; nearer than the best: D = C
  POP HL                  ; HL = the owner byte again for the table walk
  RET                     ; back to FindTargetLoop
ConsiderBuildingTaken:
  POP DE                  ; taken: skip it
  POP BC                  ; B, C back
  POP IY                  ; IY = the asking robot
  RET                     ; not offered

; keep candidate C when the column HL is nearer to DE' than the best BC'
;
; The comparison step of the nearest searches (InitNearestSearch sets it up):
; HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C.
; Only the column distance counts; rows are ignored. A and HL' are lost; the
; main BC, E, HL and IY are kept. Called by ConsiderBuilding and
; FindNearestOpponent.
KeepNearest:
  PUSH HL                 ; the candidate's column ...
  EXX                     ; (the search registers: DE' our column, BC' the
                          ; best)
  POP HL                  ; ... into HL'
  CALL ColumnDistance     ; the distance
  LD A,H                  ; the high bytes first:
  CP B                    ; (below the best?)
  JR C,KeepNearestNew     ; yes: nearer
  JR NZ,KeepNearestDone   ; above: farther
  LD A,L                  ; equal: the low bytes
  CP C                    ; (below the best?)
  JR NC,KeepNearestDone   ; not below: keep the old best
KeepNearestNew:
  LD B,H                  ; nearer: BC = the new best distance, D = its index
  LD C,L                  ; (low byte)
  EXX                     ; back to the main registers
  LD D,C                  ; D = the candidate's index
  RET                     ; done
KeepNearestDone:
  EXX                     ; back to the main registers
  RET                     ; done

; HL = |HL - DE|
;
; HL, DE two columns (0-511). A 16-bit absolute difference: SBC HL,DE and, when
; the result's sign is set, 0 - HL. DE is kept; A = 0 on the positive path, the
; high byte's negation on the other. Used by KeepNearest and by SteerByOrder's
; 50-column test of a robot target.
ColumnDistance:
  XOR A                   ; A = 0, no borrow
  SBC HL,DE               ; HL - DE
  RET P                   ; not negative: done (columns are 0-511, so the sign
                          ; is the true one)
  SUB L                   ; negative: 0 - HL
  LD L,A                  ; (low byte of the negation)
  LD A,$00                ; (keeps the borrow)
  SBC A,H                 ; (0 - H - the borrow)
  LD H,A                  ; HL = DE - HL
  RET                     ; done

; HL, B, E = the building table, its size and the owner a building order wants
;
; A = the order. Orders 5 and 8 (destroy / capture warbases): HL = $FD73, the
; owner byte of the first of the 4 warbase records (Warbases $FD70, 5 bytes
; each), B = 4; the others: HL = $FD87, the owner byte of the first of 24
; factory records (Factories $FD84), B = 24. E = the owner bits sought: $20
; (the computer's) for our robots, $40 (ours) for the enemy's (Side = 1), 0
; (neutral) for order 6, capture neutral factories.
TargetBuildingTable:
  LD HL,Factories+3             ; the factories' first owner byte ($FD87) ...
  LD B,$18                ; ... 24 records
  CP $05                  ; 5 destroy warbases?
  JR Z,TargetWarbaseTable ; (yes)
  CP $08                  ; 8 capture warbases?
  JR NZ,TargetBuildingMark ; no: the factories
TargetWarbaseTable:
  LD HL,Warbases+3             ; orders 5 and 8: the 4 warbase records
  LD B,$04                ; ... 4 records
TargetBuildingMark:
  LD E,$20                ; E = the owner mark wanted: the opponent's
  PUSH AF                 ; keep the order
  LD A,(Side)            ; Side ...
  OR A                    ; (0 ours?)
  JR Z,TargetNeutralCheck ; ours: $20 (the computer's)
  RLC E                   ; ... $40 for the enemy
TargetNeutralCheck:
  POP AF                  ; order 6 (capture neutral): mark 0
  CP $06                  ; 6 capture neutral factories?
  RET NZ                  ; no: E stays the opponent's mark
  LD E,$00                ; capture neutral: owner bits 0
  RET                     ; done

; HL = the opponent robot record of index +$0E
;
; HL = $DB80 + 16 * (+$0E) for our robots, $DA00 + 16 * (+$0E) for the enemy's
; (Side). Used by SteerByOrder's destroy-robots branch.
TargetRobotRecord:
  LD DE,Robots            ; DE = our records ...
  LD A,(Side)            ; the enemy's robots for us, ours for the enemy
  OR A                    ; (0 ours?)
  JR NZ,TargetRobotIndex  ; the enemy's robot: our records
  LD DE,EnemyRobots       ; our robot: the computer's records
TargetRobotIndex:
  LD A,(IY+$0E)           ; HL = DE + 16 x (+$0E)
  ADD A,A                 ; (2 x)
  ADD A,A                 ; (4 x)
  ADD A,A                 ; (8 x: at most 23 x 8 = 184, still a byte)
  LD L,A                  ; (L)
  LD H,$00                ; HL = 8 x index
  ADD HL,HL               ; HL = 16 x index
  ADD HL,DE               ; HL = the record
  RET                     ; done (DE = the table)

; start a nearest-by-column search from column HL
;
; DE' = HL (our column), BC' = $2000 (no candidate yet), C = 0 (the first
; index), D = $FF (the result: none). Used by FindTargetBuilding and
; FindNearestOpponent with KeepNearest.
InitNearestSearch:
  PUSH HL                 ; our column ...
  EXX                     ; (the shadow registers)
  POP DE                  ; ... DE' = our column
  LD BC,$2000             ; BC' = $2000: farther than any real distance (at
                          ; most 511)
  EXX                     ; back
  LD C,$00                ; C = the first index
  LD D,$FF                ; D = $FF: none found yet
  RET                     ; done

; D = the index of the nearest live opponent robot by column; Z when none
;
; HL = our column, IY the robot, Side set. Runs KeepNearest over the 24
; opponent records ($DB80 the enemy's for us, $DA00 ours for the enemy) whose
; +$01 is not 0 (a dying robot counts). Out D = the slot within the side (or
; $FF), A = D + 1 (Z: none); IY is kept, B ends 0 and C 24 (the callers keep
; BC), DE' / BC' / HL' are the search's. Called by SteerByOrder (order 3) and,
; through FindTargetBuilding with A = 3, by EnemyFindTarget and SetOrder. 426
; calls.
FindNearestOpponent:
  CALL InitNearestSearch  ; DE' = our column, BC' = $2000, C = 0, D = $FF
  PUSH IY                 ; keep the asking robot
  LD IY,Robots            ; the opponent's records
  LD A,(Side)            ; Side ...
  OR A                    ; (0 ours?)
  JR NZ,FindOpponentStart ; the enemy's robot: our records
  LD IY,EnemyRobots       ; our robot: the computer's records
FindOpponentStart:
  LD B,$18                ; IY = the opponent's 24 records
FindOpponentLoop:
  LD A,(IY+$01)           ; a live record: compare its column
  OR A                    ; (+$01 = 0: free)
  JR Z,FindOpponentNext   ; free: next
  LD L,(IY+$02)           ; HL = its column ...
  LD H,(IY+$03)           ; ... (high byte)
  CALL KeepNearest        ; nearer than the best: D = C
FindOpponentNext:
  PUSH DE                 ; the next 16-byte record, C its index
  LD DE,$0010             ; (16 bytes a record)
  ADD IY,DE               ; IY = the next record
  POP DE                  ; (D = the best so far)
  INC C                   ; C = its index
  DJNZ FindOpponentLoop   ; all 24
  POP IY                  ; IY = the asking robot
  LD A,D                  ; A = the index + 1: Z when none
  INC A                   ; ($FF + 1 = 0: Z)
  RET                     ; D = the slot, Z when none

; direct control: the stick steers the robot
;
; Reached from RobotStep for +$0A = 2 (not run in the deep recording;
; experiment below).
RobotDirectControl:
  PUSH BC                 ; keep C, the free directions FreeDirections found
  CALL WaitKey            ; Input, with the pause on key 1
  POP BC                  ; C = the free directions again
  LD B,C                  ; B = the free directions
  CP (IY+$08)             ; pushing the way it faces: go only if free (a turn
                          ; needs no free cell)
  JR NZ,DirectStepSet     ; another direction: a turn, taken as it is
  AND C                   ; (ahead only when free, else 0)
DirectStepSet:
  LD C,A                  ; C = the pushed direction (masked by the free ones
                          ; when it faces it)
  CALL CountDirections    ; exactly one direction?
  JR Z,DirectStepStore    ; yes: that one
  LD A,(IY+$05)           ; none or several: go on the way it went, if still
                          ; free
  AND B                   ; (only if still free)
  LD C,A                  ; C = it, or 0: stand
DirectStepStore:
  LD (IY+$05),C           ; +$05 and Input = the step, then RobotMove
  LD A,C                  ; A = the step
  LD (Input),A            ; Input = the step, so MoveShip carries the ship
                          ; along (TurnOrStep)
  JP RobotMove            ; turn or step, the delay, back on the map

; turn the robot toward direction A, or step one cell when it faces it
;
; IY the robot, HL its column, B its row, A a direction bit (0: nothing).
; Facing +$08 not A: the robot turns, never by 180 degrees in one go (right <->
; left goes through down / up, down <-> up through right / left), and +$06 is
; incremented so the turn does not shorten the course. Facing A: StepPosition
; moves HL/B, GroundUnderFootprint sets +$0D, and under direct control (+$0A =
; 2) MoveShip moves the ship by the same Input and the ship sits on the robot's
; top (Altitude = +$09 + +$0D).
;
; Experiment (DIRECT CONTROL on a new bipod + cannon robot at (22,14)): holding
; right the robot turned from facing down (4) to right (1) in one step and
; moved one column a step (6 turns, about 60 frames); after the release it went
; on one more step in the same direction; the ship moved with it and Altitude
; stayed 17 (bipod 11 + cannon 6, ground 0).
TurnOrStep:
  OR A                    ; no direction?
  RET Z                   ; then nothing: the robot stands
  CP (IY+$08)             ; already facing it: step
  JR Z,TurnOrStepStep     ; (yes)
  LD C,A                  ; C = the new facing
  OR (IY+$08)             ; A = the new and the old facing together
  CP $03                  ; right <-> left: turn down / up first
  JR NZ,TurnCheckVertical ; (not right + left)
  RLC C                   ; (1 right -> 4 down, 2 left -> 8 up ...)
  RLC C                   ; (... two rotations)
  JR TurnFace             ; face that way this step
TurnCheckVertical:
  CP $0C                  ; down <-> up: turn right / left first
  JR NZ,TurnFace          ; (any other pair is a 90-degree turn already)
  RRC C                   ; (4 down -> 1 right, 8 up -> 2 left ...)
  RRC C                   ; (... two rotations)
TurnFace:
  LD (IY+$08),C           ; +$08 = the new facing, +$06 counts the turn
  INC (IY+$06)            ; +$06 one more: the turn does not use up the course
  RET                     ; the turn is the whole step
TurnOrStepStep:
  CALL StepPosition       ; step: the new column / row in HL / B
  CALL GroundUnderFootprint ; the highest ground under the new footprint
  LD (IY+$0D),A           ; +$0D = it: the robot is drawn on it, the ship sits
                          ; on it
  LD A,(IY+$0A)           ; direct control?
  CP $02                  ; (2?)
  RET NZ                  ; no: done
  PUSH BC                 ; keep the new row ...
  PUSH HL                 ; ... the new column ...
  PUSH IY                 ; ... and the robot (MoveShip uses them all)
  CALL Z,MoveShip         ; the ship moves by the same Input
  POP IY                  ; the robot back ...
  POP HL                  ; ... the new column ...
  POP BC                  ; ... the new row, for PlaceRobot
  LD A,(IY+$09)           ; and sits on the robot's top
  ADD A,(IY+$0D)          ; (+ the ground under it)
  LD (Altitude),A            ; Altitude = the robot's top
  RET                     ; done

; move HL (column) / B (row) one cell in direction A; advance / retreat count
; their distance
;
; A bit 0 right (HL+1), 1 left (HL-1), 2 down (B+1), 3 up (B-1). For the orders
; 1 advance and 2 retreat (not under direct control) +$0E is the distance still
; to go: a column in the order's direction (right for advance, left for
; retreat) takes one off and at 0 the order becomes 0 stop (+$06 = 0); a column
; the other way adds one, up to $63.
;
; Experiment: ADVANCE with 5 MILES (the robot menu stores miles * 2 into +$0E =
; 10): the robot went 4 columns right (+$0E 10 -> 6), 5 rows up round an
; obstacle (+$0E unchanged), 6 more columns right and then stood with order 0
; and +$0E = 0.
StepPosition:
  RRCA                    ; bit 0 into carry: right?
  JR NC,StepLeft          ; no
  INC HL                  ; right: column + 1
  LD A,(IY+$0B)           ; the order ...
  DEC A                   ; (1 advance?)
  JR Z,OrderDistanceDown  ; advance: right is its way, one column less to go
  DEC A                   ; (2 retreat?)
  JR Z,OrderDistanceUp    ; retreat: right is against it, one more
  RET                     ; other orders count nothing
StepLeft:
  RRCA                    ; left: column - 1, the distance order counted the
                          ; other way
  JR NC,StepDown          ; no
  DEC HL                  ; left: column - 1
  LD A,(IY+$0B)           ; the order ...
  DEC A                   ; (1 advance?)
  JR Z,OrderDistanceUp    ; advance: left is against it, one more
  DEC A                   ; (2 retreat?)
  JR Z,OrderDistanceDown  ; retreat: left is its way, one less
  RET                     ; other orders count nothing
StepDown:
  RRCA                    ; down: row + 1
  JR NC,StepUp            ; no
  INC B                   ; row + 1
  RET                     ; rows do not count for the distance
StepUp:
  RRCA                    ; up: row - 1
  RET NC                  ; no bit: no move
  DEC B                   ; row - 1
  RET                     ; done
OrderDistanceUp:
  LD A,(IY+$0A)           ; a column away from the order's aim: one more to go
                          ; (max 99)
  CP $02                  ; (direct control?)
  RET Z                   ; the player steers: no count
  INC (IY+$0E)            ; +$0E one more ...
  LD A,(IY+$0E)           ; ... up to 99 ...
  CP $64                  ; (100 or more?)
  RET C                   ; no: done
  LD (IY+$0E),$63         ; ... at most 99
  RET                     ; done
OrderDistanceDown:
  LD A,(IY+$0A)           ; a column toward it: one less; there: stop
  CP $02                  ; (direct control?)
  RET Z                   ; the player steers: no count
  DEC (IY+$0E)            ; +$0E one less ...
  RET NZ                  ; ... not there yet
  LD (IY+$0B),$00         ; arrived: the order becomes stop
  LD (IY+$06),$00         ; and its course is spent
  RET                     ; done

; flags of (the number of set bits in C's low nibble) - 1
;
; Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3
; of C, keeps BC.
CountDirections:
  PUSH BC                 ; keep the set
  LD B,$04                ; the four direction bits
  XOR A                   ; A = the count, carry clear
CountDirectionsLoop:
  RR C                    ; add each bit
  ADC A,$00               ; (+ the bit)
  DJNZ CountDirectionsLoop ; all four
  POP BC                  ; C back
  CP $01                  ; count - 1: Z one, carry none
  RET                     ; done

; C = the directions the robot at cell HL may step to
;
; IY the robot, HL its anchor cell. A robot covers 2x2 cells: its anchor (X, Y)
; carries the object bit 6, plus (X+1, Y), (X, Y-1), (X+1, Y-1). D = the first
; terrain type it cannot enter, by its locomotion: bipod 8 (types 0-7, ground
; heights 0-3), tracks $0C (also 8-$0B, height 6), anti-grav $0F (also $0C-$0E,
; height 0 in TerrainHeights); the types from $0F (heights 7 and 15) stop all.
; E = the bits that block: 6 (objects) always, 7 (the ship's cell) when the
; ship hangs lower than the robot's top. One probe a direction (CanMoveRight,
; CanMoveLeft, CanMoveDown, CanMoveUp); bit 0 right, 1 left, 2 down, 3 up. 9652
; calls.
FreeDirections:
  LD C,$00                ; C = no direction yet
  LD A,(Altitude)            ; the ship lower than our top?
  SUB (IY+$09)            ; (minus its height)
  SUB (IY+$0D)            ; (minus the ground under it: negative = the ship
                          ; hangs below the robot's top)
  AND $80                 ; then bit 7 (the ship's cell) blocks too
  OR $40                  ; objects always block
  LD E,A                  ; E = the blocking bits: $40, or $C0 under a low ship
  LD A,(IY+$07)           ; A = the parts: bit 0 bipod, 1 tracks, 2 anti-grav
  LD D,$08                ; bipod: types below 8
  RRCA                    ; (bit 0)
  JR C,FreeDirRight       ; a bipod
  LD D,$0C                ; tracks: types below $0C
  RRCA                    ; (bit 1)
  JR C,FreeDirRight       ; tracks
  LD D,$0F                ; anti-grav: types below $0F
FreeDirRight:
  PUSH HL                 ; D = the terrain limit of the locomotion; right
                          ; free?
  CALL CanMoveRight       ; Z when free
  POP HL                  ; HL = the anchor again
  JR NZ,FreeDirLeft       ; blocked
  SET 0,C                 ; bit 0: right
FreeDirLeft:
  PUSH HL                 ; left free?
  CALL CanMoveLeft        ; Z when free
  POP HL                  ; HL = the anchor again
  JR NZ,FreeDirDown       ; blocked
  SET 1,C                 ; bit 1: left
FreeDirDown:
  PUSH HL                 ; down free?
  CALL CanMoveDown        ; Z when free
  POP HL                  ; HL = the anchor again
  JR NZ,FreeDirUp         ; blocked
  SET 2,C                 ; bit 2: down
FreeDirUp:
  PUSH HL                 ; up free?
  CALL CanMoveUp          ; Z when free
  POP HL                  ; HL = the anchor again
  JR NZ,FreeDirDone       ; blocked
  SET 3,C                 ; bit 3: up
FreeDirDone:
  RET                     ; C = the free directions

; Z when the robot at HL can step right
;
; Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y); an
; object anchored at (X+2, Y+1) (its footprint would overlap) when that row
; exists.
CanMoveRight:
  INC HL                  ; X + 1 ...
  INC HL                  ; ... X + 2: the column it enters
  DEC H                   ; one row up ...
  DEC H                   ; ... (X+2, Y-1)
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  INC H                   ; down a row ...
  INC H                   ; ... (X+2, Y)
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  INC H                   ; down a row ...
  INC H                   ; ... (X+2, Y+1): an anchor there would overlap
  LD A,H                  ; the row below only inside the map
  CP $FD                  ; (past the last row: $FDxx or more?)
  JR NC,CellOffMapFree    ; off the map: free
  LD A,(HL)               ; the cell ...
  AND E                   ; ... objects only (an anchor's footprint reaches up
                          ; a row)
  RET                     ; Z when free

; Z when the robot at HL can step left
;
; Terrain and objects at (X-1, Y-1) and (X-1, Y); objects anchored at (X-2,
; Y-1), (X-2, Y) and (X-2, Y+1).
CanMoveLeft:
  DEC H                   ; one row up ...
  DEC H                   ; ... (X, Y-1)
  DEC HL                  ; (X-1, Y-1): the column it enters
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  DEC HL                  ; (X-2, Y-1) ...
  LD A,(HL)               ; (the cell)
  AND E                   ; ... objects only: an anchor there covers X-1
  RET NZ                  ; blocked
  INC H                   ; down a row ...
  INC H                   ; ... (X-2, Y)
  LD A,(HL)               ; (the cell)
  AND E                   ; objects only
  RET NZ                  ; blocked
  INC HL                  ; (X-1, Y)
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  DEC HL                  ; (X-2, Y)
  INC H                   ; down a row ...
  INC H                   ; ... (X-2, Y+1)
  LD A,H                  ; the row below only inside the map
  CP $FD                  ; (past the last row?)
  JR NC,CellOffMapFree    ; off the map: free
  LD A,(HL)               ; the cell ...
  AND E                   ; ... objects only
  RET                     ; Z when free

; Z when the robot at HL can step down
;
; Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1);
; objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.
CanMoveDown:
  INC H                   ; down a row ...
  INC H                   ; ... (X, Y+1): the row it enters
  LD A,H                  ; the bottom row: blocked
  CP $FD                  ; (past the last row?)
  JR NC,CellBlocked       ; yes: blocked
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  INC HL                  ; (X+1, Y+1)
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  INC H                   ; down a row ...
  INC H                   ; ... (X+1, Y+2): anchors whose footprint reaches Y+1
  LD A,H                  ; the row below only inside the map
  CP $FD                  ; (past the last row?)
  JR NC,CellOffMapFree    ; off the map: free
  LD A,(HL)               ; (the cell)
  AND E                   ; objects only
  RET NZ                  ; blocked
  DEC HL                  ; (X, Y+2)
  LD A,(HL)               ; (the cell)
  AND E                   ; objects only
  RET NZ                  ; blocked
  DEC HL                  ; (X-1, Y+2)
  LD A,(HL)               ; (the cell)
  AND E                   ; objects only
  RET                     ; Z when free

; Z when the robot at HL can step up
;
; Blocked when Y-2 is above the map (the footprint already covers Y-1); an
; object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1,
; Y-2).
CanMoveUp:
  DEC H                   ; up two rows ...
  DEC H                   ; (...)
  DEC H                   ; (...)
  DEC H                   ; ... (X, Y-2): the row it enters
  LD A,H                  ; Y-2 off the map: blocked
  CP $DD                  ; (above the first row, $DDxx?)
  JR C,CellBlocked        ; yes: blocked
  DEC HL                  ; (X-1, Y-2) ...
  LD A,(HL)               ; (the cell)
  AND E                   ; ... objects only: an anchor there covers X
  RET NZ                  ; blocked
  INC HL                  ; (X, Y-2)
  CALL TestCell           ; terrain and objects
  RET NZ                  ; blocked
  INC HL                  ; (X+1, Y-2)
  CALL TestCell           ; terrain and objects
  RET                     ; Z when free

; Z: a probe that runs past the bottom row finds the way free
;
; The shared exit of the probes for rows below the map.
CellOffMapFree:
  XOR A                   ; A = 0: Z, free
  RET                     ; back to FreeDirections

; NZ: the way is blocked
;
; The shared exit for an unpassable terrain type or a map edge.
CellBlocked:
  OR $01                  ; A not 0: NZ, blocked
  RET                     ; back to FreeDirections (or to TestCell's caller)

; Z when cell HL is passable: type below D and none of the bits E
;
; HL a map cell, D the first terrain type the locomotion cannot enter
; (FreeDirections), E the blocking bits ($40 objects, plus $80 the ship's cell
; when the ship hangs lower than the robot's top). NZ through CellBlocked when
; the type (bits 0-4) is D or more; else A = the cell AND E (Z: free). HL kept.
; Used by the four CanMove probes for the cells the footprint enters; the cells
; only checked for anchors use AND E directly. 67380 calls.
TestCell:
  LD A,(HL)               ; the cell ...
  AND $1F                 ; ... its terrain type (bits 0-4)
  CP D                    ; at or past the locomotion's limit D?
  JR NC,CellBlocked       ; yes: blocked
  LD A,(HL)               ; an object (or the low ship) in it?
  AND E                   ; (bit 6, and bit 7 when E has it)
  RET                     ; Z when free

; A = the highest ground under the 2x2 footprint anchored at (HL, B)
;
; HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1),
; the highest kept in C; HL and BC are kept, DE is lost (the last cell). The
; robots' +$0D (the ground they stand on: SetStepDelay's row, the drawing
; height, the ship's seat under direct control) and the shots' wall test
; (MoveShot against +$08 = $0A).
GroundUnderFootprint:
  PUSH HL                 ; keep the column ...
  PUSH BC                 ; ... and the row
  LD A,B                  ; A = the row
  CALL MapCell            ; HL = the cell (X, Y)
  EX DE,HL                ; DE = it (DE is lost)
  LD C,$00                ; C = the highest so far: 0
  CALL TerrainTop         ; (X, Y)
  INC DE                  ; (X+1, Y) ...
  CALL TerrainTop         ; (its height)
  DEC D                   ; one row up ...
  DEC D                   ; ... (X+1, Y-1)
  CALL TerrainTop         ; (its height)
  DEC DE                  ; (X, Y-1)
  CALL TerrainTop         ; (its height)
  LD A,C                  ; A = the highest
  POP BC                  ; the row back
  POP HL                  ; the column back
  RET                     ; done

; +$0F = the turns until the robot's next step, by the ground and its
; locomotion
;
; The ground class from +$0D: 0 flat, 1-3 low, 4 and more high; the column from
; the lowest set part bit of +$07: 0 bipod, 1 tracks, 2 anti-grav. StepDelays
; gives the turns. The recorded records agree (robot 0, a bipod on flat ground,
; counts 6 down).
SetStepDelay:
  PUSH BC                 ; keep the row ...
  PUSH HL                 ; ... and the column for PlaceRobot
  LD A,(IY+$0D)           ; A = the ground under it +$0D
  LD C,$00                ; C = the row of StepDelays: 0 flat ...
  OR A                    ; (flat?)
  JR Z,SetStepDelayFind   ; yes
  LD C,$03                ; low ground
  CP $04                  ; (below 4?)
  JR C,SetStepDelayFind   ; yes: low
  LD C,$06                ; high ground
SetStepDelayFind:
  LD A,(IY+$07)           ; C = the ground class (0 flat, 3 low, 6 high); find
                          ; the locomotion part
  LD D,$FF                ; D = -1, counted up to the part's index
SetStepDelayPart:
  INC D                   ; D = the locomotion: the index of the first set part
                          ; bit
  RRCA                    ; (the next part bit into carry)
  JR NC,SetStepDelayPart  ; until the first set one
  LD A,C                  ; the row ...
  ADD A,D                 ; ... + the column
  LD HL,StepDelays        ; the table ...
  CALL AddAToHL           ; ... HL = the entry
  LD A,(HL)               ; A = the turns
  LD (IY+$0F),A           ; +$0F = the step delay
  POP HL                  ; the column back
  POP BC                  ; the row back
  RET                     ; done

; Game turns a robot step takes: rows flat, low, high ground; columns bipod,
; tracks, anti-grav
;
; 6 4 3 / 8 6 3 / 9 7 4. Read by SetStepDelay; a game turn is about 10 frames,
; so a bipod on flat ground steps every 60 frames.
StepDelays:
  DEFB $06,$04,$03        ; flat ground (+$0D = 0): bipod 6, tracks 4,
                          ; anti-grav 3 turns a step
  DEFB $08,$06,$03        ; low ground (+$0D 1-3): bipod 8, tracks 6, anti-grav
                          ; 3
  DEFB $09,$07,$04        ; high ground (+$0D 4 and more): bipod 9, tracks 7,
                          ; anti-grav 4

; E = the directions in which a live opponent robot is in sight
;
; IY the robot. For each direction (up, down, left, right: E's bits 3, 2, 1, 0
; as in Input) ScanLane looks from the robot's anchor up to 8 cells; in the
; facing direction +$08 the range is 10, 12 with electronics (+$07 bit 7), and
; three parallel lanes are scanned (the columns X-1, X, X+1 for up / down, the
; rows Y-1, Y, Y+1 for left / right). 9652 calls.
SpotEnemies:
  LD E,$00                ; E = no opponent seen yet
  LD D,$08                ; D = the direction scanned: up first
SpotEnemiesLoop:
  RLC E                   ; the next result bit
  LD L,(IY+$00)           ; HL = the anchor cell ...
  LD H,(IY+$01)           ; ... (high byte)
  LD B,$08                ; the range: 8 cells
  LD A,D                  ; this direction ...
  CP (IY+$08)             ; the facing direction ...
  JR NZ,SpotEnemiesLane   ; no: one lane of 8
  LD B,$0A                ; ... sees 10 cells ...
  BIT 7,(IY+$07)          ; electronics?
  JR Z,SpotEnemiesThree   ; no: 10
  LD B,$0C                ; ... 12 with electronics ...
SpotEnemiesThree:
  LD A,D                  ; B = the range; three lanes, columns for down / up,
                          ; rows for right / left
  AND $03                 ; (right / left?)
  JR NZ,SpotEnemiesRows   ; yes: the rows
  LD C,B                  ; up / down: the columns X-1, X, X+1
  DEC HL                  ; (X-1)
  CALL ScanLane           ; the first lane
  LD B,C                  ; (the range again)
  INC HL                  ; (X)
  CALL ScanLane           ; the second lane
  LD B,C                  ; (the range again)
  INC HL                  ; (X+1), the last lane below
  JR SpotEnemiesLane      ; scan it
SpotEnemiesRows:
  LD C,B                  ; left / right: the rows Y-1, Y, Y+1
  DEC H                   ; one row up ...
  DEC H                   ; ... (Y-1)
  CALL ScanLane           ; the first lane
  LD B,C                  ; (the range again)
  INC H                   ; down a row ...
  INC H                   ; ... (Y)
  CALL ScanLane           ; the second lane
  LD B,C                  ; (the range again)
  INC H                   ; down a row ...
  INC H                   ; ... (Y+1), the last lane below
SpotEnemiesLane:
  CALL ScanLane           ; the (last) lane
  RRC D                   ; the next direction: down, left, right
  JR NC,SpotEnemiesLoop   ; until the bit leaves (after right)
  RET                     ; E: bit 0 right, 1 left, 2 down, 3 up

; set E bit 0 when a live opponent's anchor lies within B cells from HL in
; direction D
;
; The step comes from LaneSteps by D's bit. The scan stops at the map's top or
; bottom edge and at the first cell with an object (bit 6): only a robot of the
; other side (+$0A bit 7 differs) with strength above 0 sets the bit.
; Buildings, shots and friends block the view. HL, DE are kept apart from E's
; bit 0.
ScanLane:
  PUSH HL                 ; keep the start cell
  PUSH DE                 ; keep D (the direction) and E (the results)
  PUSH HL                 ; the start cell again, for the walk
  LD HL,ScanLaneDone+$0001 ; LaneSteps - 2
  LD A,D                  ; A = the direction bit
ScanLaneStep:
  INC HL                  ; the step word for D's bit
  INC HL                  ; (2 bytes a word)
  RRCA                    ; (the next bit into carry)
  JR NC,ScanLaneStep      ; until it
  LD E,(HL)               ; DE = the step ...
  INC HL                  ; (high byte)
  LD D,(HL)               ; ... +1, -1, +$200 or -$200
  POP HL                  ; HL = the start cell
ScanLaneLoop:
  ADD HL,DE               ; one cell on
  LD A,H                  ; off the map's rows: stop
  SUB $DD                 ; (row 0 is $DD)
  CP $20                  ; (16 rows of 2 pages)
  JR NC,ScanLaneDone      ; out of the map: nothing seen (left / right run on
                          ; into the next row's other end)
  BIT 6,(HL)              ; the first object stops the view
  JR NZ,ScanLaneObject    ; yes: whose?
  DJNZ ScanLaneLoop       ; B cells
  JR ScanLaneDone         ; nothing in range
ScanLaneObject:
  PUSH IY                 ; a robot?
  CALL FindRobot          ; Z: IY = the robot anchored here
  LD A,(IY+$0A)           ; its side bit (+$0A bit 7)
  LD B,(IY+$0C)           ; and its strength (both junk when NZ)
  POP IY                  ; IY = the looking robot
  JR NZ,ScanLaneDone      ; not a robot (a building, a shot): the view ends
  XOR (IY+$0A)            ; same side: no
  JP P,ScanLaneDone       ; (bit 7 0: the same side)
  DEC B                   ; dead or dying: no
  JP M,ScanLaneDone       ; (strength 0 or below: dying)
  POP DE                  ; an opponent in sight
  LD A,E                  ; (the saved results)
  OR $01                  ; (bit 0: this direction)
  LD E,A                  ; (E bit 0 set)
  PUSH DE                 ; the saved DE now carries it
ScanLaneDone:
  POP DE                  ; back with E
  POP HL                  ; the start cell back
  RET                     ; done

; The map steps of the four directions: right +1, left -1, down +$200, up -$200
;
; Read by ScanLane (from LD HL,$B6AE and two INC HL a bit of D), in the Input
; bit order.
LaneSteps:
  DEFW $0001,$FFFF,$0200,$FE00 ; Input bit 0 right +1, bit 1 left -1, bit 2
                               ; down +$200 (next row), bit 3 up -$200

; IY = a free shot record of the shooter IX's side; Z when one is free
;
; Each side has two shot records of 9 bytes: ours $D7DC and $D7E5, the enemy's
; $D7EE and $D7F7 (by IX +$0A bit 7). Z with IY on the first one whose +$01 is
; 0; NZ when both fly. Record 0 ($D7D3) is not handed out here: it is the
; player's COMBAT MODE shot, launched from the robot menu (DirectControl, not
; in the recording).
FindFreeShot:
  LD IY,Shots+$0009       ; IY = record 1 ($D7DC), our first
  BIT 7,(IX+$0A)          ; the shooter the enemy's?
  JR Z,FindFreeShotSlot   ; no: records 1-2
  LD DE,$0012             ; the enemy's records
  ADD IY,DE               ; IY = record 3 ($D7EE)
FindFreeShotSlot:
  LD A,(IY+$01)           ; IY = the side's first shot record; Z when free,
                          ; else the second
  OR A                    ; (+$01 = 0: free)
  RET Z                   ; free: take it
  LD DE,$0009             ; the second record
  ADD IY,DE               ; IY = record 2 or 4
  LD A,(IY+$01)           ; (+$01 ...)
  OR A                    ; (... 0: free)
  RET                     ; Z: free, NZ: both fly

; launch shot IY of weapon A from robot IX in its facing direction
;
; Called by RobotStep and by COMBAT MODE in the robot menu (DirectControl, IX =
; IY = the robot, record 0). Shot record (9 bytes): +$00/+$01 the map cell,
; +$02/+$03 the column, +$04 the row, +$05 the direction, +$06 the steps left,
; +$07 the weapon (1 cannon, 2 missiles, 3 phasers), +$08 the ground height
; that stops it ($0A). The range is 5 steps (7 for missiles), one more with
; electronics; each step goes 2 cells. The first step is taken at once
; (MoveShot), from the shooter's anchor: in RobotStep the shooter is already
; off the map (bit 6 cleared), so it cannot hit itself.
;
; When the shot survives the first step SoundFx ($FD53) = 1, the firing sound;
; when it ends at once, MoveShot's sound ($FC, $FA or $C8) stays. Recording: an
; enemy missile at frame 18680, D7EE: 7B F3 7B 00 0B 08 06 02 0A (column $7B,
; row 11, up, 6 steps left after the first turn, missiles).
FireShot:
  LD (IY+$07),A           ; +$07 = the weapon: 1 cannon, 2 missiles, 3 phasers
  LD C,$05                ; C = the range: 5 steps (10 cells) ...
  CP $02                  ; missiles fly further
  JR NZ,FireShotElectronics ; (no)
  LD C,$07                ; ... missiles 7
FireShotElectronics:
  BIT 7,(IX+$07)          ; electronics: the range one step more
  JR Z,FireShotStart      ; (no)
  INC C                   ; (+1)
FireShotStart:
  LD (IY+$06),C           ; +$06 the range, +$05 the robot's facing, +$08 the
                          ; wall height, the first step
  LD A,(IX+$08)           ; the robot's facing
  LD (IY+$05),A           ; +$05 = the direction it flies
  LD (IY+$08),$0A         ; ground of height 10 or more stops it
                          ; (TerrainHeights 15)
  LD L,(IX+$02)           ; HL = the robot's column ...
  LD H,(IX+$03)           ; ... (high byte)
  LD B,(IX+$04)           ; B = its row
  CALL MoveShot           ; the first step
  LD A,(IY+$01)           ; still flying?
  OR A                    ; (+$01 = 0: gone)
  JR Z,FireShotDone       ; gone already
  LD A,$01                ; it flies: the firing sound
  LD (SoundFx),A            ; SoundFx = 1
FireShotDone:
  RET                     ; the shot ended at once: MoveShot's miss / hit sound
                          ; stays

; one game turn of shot IY: off its cell, count its range, a step
;
; Clears the object bit of the shot's cell, counts +$06 down (0: the shot is
; gone, ShotGone) and goes on into MoveShot from its column / row. 90 calls in
; the deep recording.
UpdateShot:
  LD L,(IY+$00)           ; HL = the shot's cell ...
  LD H,(IY+$01)           ; ... (high byte)
  RES 6,(HL)              ; the shot leaves its cell
  DEC (IY+$06)            ; out of range: gone
  JP Z,ShotGone           ; (its last step was the turn before)
  LD L,(IY+$02)           ; HL = its column ...
  LD H,(IY+$03)           ; ... (high byte)
  LD B,(IY+$04)           ; B = its row; on into MoveShot

; move shot IY 2 cells, then hit a wall, an object or fly on
;
; IY the shot record, HL its column, B its row. One step: 2 cells in +$05. Off
; the rows 0-15 (only tested for down / up; the columns are not range-checked),
; or ground of height +$08 ($0A) or more under its 2x2 footprint (only the
; types $10 / $12, height 15; heights up to 7 let it pass): gone (ShotGone,
; SoundFx $FC). The new position and cell go into +$00-+$04.
;
; Then the 3x3 cells around the new cell are tested for an object (bit 6), row
; Y-1 and Y+1 only inside the map; none: the shot marks its own cell with bit 6
; and flies on. An object that is a live robot (either side: friendly fire is
; possible) takes damage ((60 - its top) / 4) * (weapon + 1), the top being
; +$09 + +$0D, so tall robots on high ground take less: strength 0 or below
; makes it $FC (dying, UpdateRobot) with SoundFx $C8, else SoundFx $FA. Any
; other object (a building, another shot, a dying robot) just ends the shot
; (SoundFx $FC). Either way the record is freed (+$01 = 0, the other bytes
; stay).
;
; The recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 =
; 30, a cannon shell 10 * 2 = 20. Entered from UpdateShot (falling through) and
; FireShot.
MoveShot:
  LD A,(IY+$05)           ; A = the direction +$05
  RRCA                    ; right: 2 columns
  JR NC,MoveShotLeft      ; (no)
  INC HL                  ; (+1)
  INC HL                  ; (+2; the columns are not range-checked)
  JR MoveShotStore        ; store it
MoveShotLeft:
  RRCA                    ; left: 2 columns
  JR NC,MoveShotDown      ; (no)
  DEC HL                  ; (-1)
  DEC HL                  ; (-2)
  JR MoveShotStore        ; store it
MoveShotDown:
  RRCA                    ; down: 2 rows
  JR NC,MoveShotUp        ; (no)
  INC B                   ; (+1)
  INC B                   ; (+2)
  JR MoveShotRows         ; check the row
MoveShotUp:
  RRCA                    ; up: 2 rows
  JR NC,MoveShotStore     ; (no direction: it stays)
  DEC B                   ; (-1)
  DEC B                   ; (-2; below 0 wraps to $FE / $FF)
MoveShotRows:
  LD A,B                  ; past the map's rows: the shot is gone
  CP $10                  ; (0-15?)
  JP NC,ShotGone          ; no: gone
MoveShotStore:
  LD (IY+$02),L           ; the new position
  LD (IY+$03),H           ; (column high)
  LD (IY+$04),B           ; (row)
  CALL GroundUnderFootprint ; the ground under it
  CP (IY+$08)             ; too high: it hits the wall
  JP NC,ShotGone          ; yes: gone
  LD A,B                  ; A = the row
  CALL MapCell            ; the new cell
  LD (IY+$00),L           ; +$00/+$01 = the cell ...
  LD (IY+$01),H           ; ... (high byte)
  PUSH HL                 ; the row above: Y-1, columns X-1 to X+1 (when inside
                          ; the map)
  DEC HL                  ; (X-1)
  DEC H                   ; one row up ...
  DEC H                   ; ... (X-1, Y-1)
  LD A,H                  ; above the map?
  CP $DD                  ; (row 0 is $DD)
  JR C,MoveShotRow        ; yes: skip the row
  BIT 6,(HL)              ; (X-1, Y-1)?
  JR NZ,MoveShotHit       ; an object: hit
  INC HL                  ; (X, Y-1)
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
  INC HL                  ; (X+1, Y-1)
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
  DEC HL                  ; back ...
  DEC HL                  ; ... to X-1
MoveShotRow:
  INC H                   ; the shot's row
  INC H                   ; ... (X-1, Y)
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
  INC HL                  ; (X, Y): its own cell, cleared by UpdateShot
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
  INC HL                  ; (X+1, Y)
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
  DEC HL                  ; back ...
  DEC HL                  ; ... to X-1
  INC H                   ; the row below (when inside the map)
  INC H                   ; ... (X-1, Y+1)
  LD A,H                  ; past the last row?
  CP $FD                  ; (row 15 is $FB/$FC)
  JR NC,MoveShotFlies     ; yes: nothing below
  BIT 6,(HL)              ; (X-1, Y+1)?
  JR NZ,MoveShotHit       ; hit
  INC HL                  ; (X, Y+1)
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
  INC HL                  ; (X+1, Y+1)
  BIT 6,(HL)              ; (an object there?)
  JR NZ,MoveShotHit       ; hit
MoveShotFlies:
  POP HL                  ; nothing near: the shot occupies its cell
  SET 6,(HL)              ; bit 6 on it: robots see it, other shots hit it
  RET                     ; it flies on next turn
MoveShotHit:
  PUSH IY                 ; hit: E = the weapon, C = the sound for a miss
  LD E,(IY+$07)           ; E = the weapon: 1-3
  LD C,$FC                ; C = $FC: no damage
  CALL FindRobot          ; a robot anchored at the cell hit?
  JR NZ,MoveShotGone      ; no (a building, a shot): the shot just ends
  LD A,(IY+$0C)           ; alive?
  DEC A                   ; (strength 0 or below?)
  JP M,MoveShotGone       ; dying: no damage
  LD A,$3C                ; (60 - its top) / 4 ...
  SUB (IY+$09)            ; (minus its height)
  SUB (IY+$0D)            ; (minus its ground)
  SRL A                   ; (/ 2)
  SRL A                   ; (/ 4)
  LD D,A                  ; D = the damage a point
  LD B,E                  ; ... times the weapon + 1
MoveShotDamage:
  ADD A,D                 ; one more multiple
  DJNZ MoveShotDamage     ; weapon times: A = D x (weapon + 1)
  LD B,A                  ; B = the damage
  LD C,$FA                ; the hit sound
  LD A,(IY+$0C)           ; A = its strength ...
  SUB B                   ; the strength left
  JR Z,MoveShotKill       ; exactly 0: destroyed
  JP P,MoveShotStrength   ; still above 0: it lives
MoveShotKill:
  LD A,$FC                ; strength 0 or less: dying for 4 turns, the
                          ; explosion sound
  LD C,$C8                ; C = $C8, the explosion
MoveShotStrength:
  LD (IY+$0C),A           ; +$0C = the strength left
MoveShotGone:
  POP IY                  ; the shot is gone
  POP HL                  ; drop the cell pushed above
  LD (IY+$01),$00         ; +$01 = 0: the shot record is free
  LD A,C                  ; the sound: $FC miss, $FA hit, $C8 destroyed
  LD (SoundFx),A            ; SoundFx = it
  RET                     ; done

; out of range or off the map: the shot is gone with the short sound
;
; Used by the routines at UpdateShot and MoveShot.
ShotGone:
  LD (IY+$01),$00         ; +$01 = 0: the shot record is free
  LD A,$FC                ; $FC: the short sound
  LD (SoundFx),A            ; SoundFx = it
  RET                     ; done
