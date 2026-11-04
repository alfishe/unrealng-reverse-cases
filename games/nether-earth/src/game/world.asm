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
  CALL EnemyCommander
  LD B,$30                ; the 48 robot records
  LD IY,Robots
WorldTurnRobotLoop:
  PUSH BC                 ; a live robot (+$01 = the high byte of its cell, 0 =
                          ; free)
  LD A,(IY+$01)
  OR A
  CALL NZ,UpdateRobot
  LD DE,$0010
  ADD IY,DE
  POP BC
  DJNZ WorldTurnRobotLoop
  LD IY,Shots             ; the 5 shot records
  LD B,$05
WorldTurnShotLoop:
  PUSH BC                 ; a live shot
  LD A,(IY+$01)
  OR A
  CALL NZ,UpdateShot
  LD DE,$0009
  ADD IY,DE
  POP BC
  DJNZ WorldTurnShotLoop
  RET

; one robot's game turn: dying, destroyed or a step of its AI
;
; IY = the robot record. Strength +$0C decides: positive, the robot acts
; (RobotStep); negative, the robot is dying: +$0C counts up from $FC (set by
; MoveShot's hit) and the object bit 6 of its cell is toggled each turn
; (cleared on even values, set on odd), so for four turns other robots and
; shots see it only every other turn; 0, the robot is destroyed
; (RobotDestroyed). 49165 calls.
UpdateRobot:
  LD A,(IY+$0C)
  OR A
  JR Z,RobotDestroyed     ; strength 0: destroyed
  JP P,RobotStep          ; strength positive: alive
  INC (IY+$0C)            ; dying: one turn closer to 0
  LD L,(IY+$00)
  LD H,(IY+$01)
  AND $01                 ; the old value's bit 0: the object bit flickers
  JR NZ,RobotDyingShow
  RES 6,(HL)
  RET
RobotDyingShow:
  SET 6,(HL)              ; odd: the object is there
  RET
RobotDestroyed:
  LD L,(IY+$00)           ; remove the robot: a wreck on bare ground, the dot,
                          ; the slot, the counts
  LD H,(IY+$01)
  RES 6,(HL)              ; no object on its cell any more
  LD A,(HL)               ; OR of the four footprint cells (X, Y), (X+1, Y),
                          ; (X+1, Y-1), (X, Y-1)
  INC HL
  OR (HL)
  DEC H
  DEC H
  OR (HL)
  DEC HL
  OR (HL)
  INC H
  INC H
  AND $3F                 ; bits 0-5: anything but bare type-0 ground?
  JR NZ,RobotRemove
  CALL Random             ; bare ground: a wreck, terrain type 6 or 7 at random
  AND $01
  ADD A,$06
  CALL PutBlock           ; PutBlock: a 2x2 terrain feature of type A at HL
                          ; (the anchor A, the other three cells A + $20)
RobotRemove:
  LD L,(IY+$02)           ; erase its radar dot: layer B = +$0A bit 7 (0 ours,
                          ; 1 the enemy's)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  CALL ToggleRadarDot
  LD (IY+$01),$00         ; the slot is free
  CALL CountRobots        ; recount: OurRobots $FD41, EnemyRobots $FD49
  CALL UpdateStatusPanel  ; and the status panel
  RET

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
  LD A,(IY+$0A)
  CP $01                  ; the player sits on it: frozen while the robot menu
                          ; is open
  RET Z
  RLCA                    ; Side: 0 ours, 1 the enemy's
  AND $01
  LD (Side),A
  DEC (IY+$0F)            ; the step delay
  RET NZ
  LD L,(IY+$00)           ; time to step: off the map
  LD H,(IY+$01)
  RES 6,(HL)
  PUSH HL
  LD L,(IY+$02)           ; erase its radar dot
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  CALL ToggleRadarDot
  POP HL
  CALL FreeDirections     ; C = the free directions from this cell
  LD A,(IY+$0A)
  CP $02                  ; under direct control?
  JP Z,RobotDirectControl
  PUSH BC
  CALL SpotEnemies        ; E = the directions with an opponent in sight
  POP BC
  LD A,E
  OR A
  JR Z,RobotNoEnemy       ; nobody in sight
  AND (IY+$08)            ; an opponent straight ahead?
  JR Z,RobotTurnToEnemy
  AND C                   ; move on ahead if free (else stand)
  LD (IY+$05),A
  PUSH IX
  PUSH IY
  PUSH IY                 ; IX = the shooter, IY = the free shot record
  POP IX
  CALL FindFreeShot
  JR NZ,RobotNoShot       ; both of our side's shots are flying
  CALL Random             ; each weapon (bits 3 cannon, 4 missiles, 5 phasers)
                          ; fires this turn at even odds
  AND $38
  AND (IX+$07)
  JR Z,RobotNoShot        ; no weapon chosen this turn
  LD C,$06                ; the highest chosen weapon: phasers 3, missiles 2,
                          ; cannon 1
RobotWeaponPick:
  DEC C                   ; count the rotations until the weapon bit leaves
  RLCA
  JR NC,RobotWeaponPick
  LD A,C
  CALL FireShot           ; launch the shot
  POP IY
  POP IX
  LD (IY+$05),$00         ; the shot costs the step: stand, decide again next
                          ; step
  LD (IY+$06),$01
  JR RobotMove
RobotNoShot:
  POP IY                  ; no shot: walk on ahead
  POP IX
  LD (IY+$06),$01
  JR RobotMove
RobotTurnToEnemy:
  LD C,E                  ; opponents to a side: face one of them
  LD B,C
  CALL CountDirections    ; several: one at random
  CALL NZ,PickOneDirection
  LD (IY+$05),C
  LD (IY+$06),$02
  JP RobotMove
RobotNoEnemy:
  DEC (IY+$06)            ; nobody in sight: keep the course while it lasts and
                          ; is free
  JP M,RobotNewCourse
  LD A,(IY+$05)
  AND C
  JR NZ,RobotMove
RobotNewCourse:
  CALL Random             ; a new course for 3-6 steps
  AND $03
  ADD A,$03
  LD (IY+$06),A
  CALL CountDirections    ; at least one free direction: ask the order
  CALL NC,SteerByOrder
  LD A,(IY+$01)           ; the robot blew itself up (a nuclear charge,
                          ; NuclearBlast)
  OR A
  RET Z
  LD (IY+$05),C
; This entry point is used by the routine at FindNearestOpponent.
RobotMove:
  LD A,(IY+$05)           ; turn or step in +$05, the new delay, back on the
                          ; map
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD B,(IY+$04)
  CALL TurnOrStep
  CALL SetStepDelay
  JP PlaceRobot           ; PlaceRobot: store x / y / the cell, set bit 6, plot
                          ; the dot

; C = the direction the robot's order wants, chosen among the free ones in C
;
; IY the robot, C the free directions (FreeDirections); out C a single
; direction bit, or 0 to stand. B keeps the free set. By the order +$0B:
;
; 0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo, a 3/4 chance
; to take that direction when free, else a random free one other than the
; opposite); RobotStepPos counts the distance +$0E.
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
; building's row. More than 7 columns away the robot leans horizontally like an
; advance (RobotLeanTo); closer, one of the free wanted directions at random, a
; horizontal one kept for |dx| - 1 steps (+$06). On the target (D = 0): the
; destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this
; range); the others turn the robot to face down and stand.
;
; Bug (experiment, breakpoint at $B2B8 after poking the target factory's
; owner): FindTargetBuilding leaves HL past the table, not on the new target,
; so the step right after a new building target aims at the bytes below $FDFF
; (the JP at $FDFD and Handler: row $66, column $C300): one step of a wrong
; course, corrected on the next decision.
SteerByOrder:
  LD B,C
  LD A,(IY+$0B)           ; the order
  OR A
  JR NZ,SteerMoveOrders
  LD C,A                  ; 0 stop: stand
  RET
SteerMoveOrders:
  CP $03                  ; orders 1-8: advance / retreat, destroy robots, the
                          ; building orders
  JP C,RobotLeanTo
  JR NZ,SteerBuildingOrder ; 4-8: the building orders
  LD A,(IY+$0E)           ; 3 destroy robots: a target already?
  OR A
  JP M,SteerNewRobotTarget
  CALL TargetRobotRecord  ; HL = the target robot's record
  INC HL
  LD A,(HL)               ; dead (its +$01 = 0)?
  OR A
  JR Z,SteerNewRobotTarget
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD E,(IY+$02)
  LD D,(IY+$03)
  CALL ColumnDistance     ; HL = |its column - ours|
  LD A,H
  OR A
  JR NZ,SteerNewRobotTarget
  LD A,L
  CP $32                  ; less than 50 columns: chase it
  JR C,SteerAtRobot
SteerNewRobotTarget:
  LD L,(IY+$02)           ; find the nearest live opponent
  LD H,(IY+$03)
  LD (IY+$0E),$FF
  PUSH BC
  CALL FindNearestOpponent
  POP BC
  LD (IY+$0E),D           ; +$0E = its index, $FF none
  JP Z,PickOneDirection   ; nobody: wander
SteerAtRobot:
  CALL TargetRobotRecord  ; DE = the target's column, B = our row - its row
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(IY+$04)
  SUB (HL)
  LD B,A
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE               ; HL = our column - its column
  LD D,A
  JR Z,RobotAimVertical
  JR RobotAim
SteerBuildingOrder:
  CALL TargetBuildingTable ; HL = the owner byte of the first record, E = the
                           ; owner the order wants
  LD A,(IY+$0E)           ; HL = the target record's owner byte (5 bytes a
                          ; record)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL AddAToHL
  LD A,(HL)
  AND $E0
  CP E                    ; still a building we want?
  JR Z,SteerAtBuilding
  LD A,(IY+$0B)           ; no: find another
  PUSH BC
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL FindTargetBuilding
  POP BC
  JR NZ,SteerNewBuilding  ; found one
  LD C,$00                ; none left: stand
  BIT 7,(IY+$0A)          ; ours: stand and wait
  RET Z
  LD (IY+$0B),$03         ; the enemy's: hunt robots instead
  RET
SteerNewBuilding:
  LD (IY+$0E),D           ; another target building found: +$0E = its index
SteerAtBuilding:
  DEC HL                  ; B = our row - the building's row, DE = its column
  LD A,(IY+$04)
  SUB (HL)
  LD B,A
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE               ; HL = our column - its column
  LD D,A
  JR Z,RobotAimVertical
  LD A,B                  ; columns differ: aim at the row 3 below it
  SUB $03
  LD B,A
RobotAim:
  LD A,H                  ; horizontal: 2 left when we are right of it, 1 right
                          ; when left
  RRCA
  AND $03
  XOR $02
  LD D,A
RobotAimVertical:
  LD A,B                  ; vertical: 8 up when we are below it, 4 down when
                          ; above
  OR A
  JR Z,RobotAimCheck
  RRCA
  RRCA
  AND $0C
  XOR $08
  OR D
  LD D,A
RobotAimCheck:
  LD A,D                  ; D = the wanted directions: 0 means on the target
  OR A
  JR NZ,RobotAimMove
  LD C,A                  ; on the target: stand
  LD A,(IY+$0B)
  CP $04
  JR C,RobotFaceDown
  CP $06                  ; destroy factories / warbases: the nuclear charge
  JP C,NuclearBlast
RobotFaceDown:
  LD A,(IY+$08)           ; on the target: face down and stand (destroy orders
                          ; blast first)
  CP $04
  RET Z
  LD C,$04                ; else turn down and stay so
  LD (IY+$06),$FF
  RET
RobotAimMove:
  LD A,L                  ; off the target: L = |the column difference|
  OR A
  JP P,RobotAimColumns
  NEG
  LD L,A
RobotAimColumns:
  CP $08                  ; 8 or more columns away: lean horizontally, else
                          ; pick among the free wanted directions
  LD B,C
  LD A,D
  JR NC,RobotLeanTo
  AND C                   ; the wanted directions that are free
  JR Z,PickOneDirection   ; none: any free direction
  LD B,A
  AND $03                 ; only vertical ones: pick one
  JR Z,PickOneDirection
  LD A,L                  ; the columns agree: pick one
  OR A
  JR Z,PickOneDirection
  DEC A                   ; keep a horizontal course for |dx| - 1 steps
  LD (IY+$06),A
  JR PickOneDirection
RobotLeanTo:
  AND $03                 ; D = the horizontal part (1 right, 2 left), E = all
                          ; but the opposite one
  LD D,A
  XOR $FC
  LD E,A
  LD A,C
  AND D                   ; wanted direction blocked: any free one
  JR Z,PickOneDirection
  LD C,D                  ; C = the wanted direction
  CALL Random             ; taken with a 3/4 chance (two random bits)
  AND D
  RET NZ
  CALL Random
  AND D
  RET NZ
  LD A,B                  ; else: among the free ones but the opposite
  AND E
  LD B,A

; C = one direction bit picked at random from the set in B
;
; Masks C with random bytes until exactly one bit is left (CountDirections);
; when nothing is left it starts again from B. B must not be 0. The common exit
; of SteerByOrder's branches and used by RobotTurnToEnemy for several
; opponents.
PickOneDirection:
  LD C,B
PickOneLoop:
  CALL Random             ; C AND a random byte
  AND C
  LD C,A
  CALL CountDirections
  RET Z                   ; exactly one: done
  JR NC,PickOneLoop       ; still several: narrow on
  LD C,B                  ; none left: from the whole set again
  JR PickOneLoop

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
  CP $03
  JP Z,FindNearestOpponent
  PUSH AF
  EX AF,AF'               ; A' = the order, for ConsiderBuilding
  POP AF
  CALL InitNearestSearch  ; the search: DE' = our column, BC' = the best
                          ; distance ($2000), C = the index, D = $FF
  CALL TargetBuildingTable ; HL = the first record's owner byte, B = the
                           ; records, E = the owner wanted
FindTargetLoop:
  LD A,(HL)               ; owner bits 5-7 the ones wanted?
  AND $E0
  CP E
  CALL Z,ConsiderBuilding
  LD A,L                  ; next record (L only: the tables sit inside page
                          ; $FD)
  ADD A,$05
  LD L,A
  INC C
  DJNZ FindTargetLoop
  LD A,D                  ; A = the index + 1: Z when none was found
  INC A
  RET

; offer building C to KeepNearest unless a teammate with the same order already
; targets it
;
; HL = the record's owner byte (+$03), C its index, A' the order. Scans the 24
; records of our side ($DA00 ours, $DB80 the enemy's by Side) for a live robot
; whose order +$0B is A' and whose target +$0E is C. None: the record's column
; (+$00/+$01) goes to KeepNearest. The robot that asks is in the list too; its
; +$0E holds its old target (or $FF).
ConsiderBuilding:
  PUSH IY
  PUSH BC
  PUSH DE
  EX AF,AF'
  LD E,A                  ; E = the order
  EX AF,AF'
  LD IY,Robots            ; our side's robots
  LD A,(Side)
  OR A
  JR Z,ConsiderBuildingStart
  LD IY,EnemyRobots
ConsiderBuildingStart:
  LD B,$18                ; IY = the side's 24 robot records
ConsiderBuildingLoop:
  LD A,(IY+$01)           ; a live robot ...
  OR A
  JR Z,ConsiderBuildingNext
  LD A,(IY+$0B)           ; ... with the same order ...
  CP E
  JR NZ,ConsiderBuildingNext
  LD A,(IY+$0E)           ; ... after the same building?
  CP C
  JR Z,ConsiderBuildingTaken
ConsiderBuildingNext:
  PUSH DE                 ; the next 16-byte robot record
  LD DE,$0010
  ADD IY,DE
  POP DE
  DJNZ ConsiderBuildingLoop
  POP DE
  POP BC
  POP IY
  PUSH HL                 ; nobody: HL = the building's column
  DEC HL
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  CALL KeepNearest
  POP HL
  RET
ConsiderBuildingTaken:
  POP DE                  ; taken: skip it
  POP BC
  POP IY
  RET

; keep candidate C when the column HL is nearer to DE' than the best BC'
;
; The comparison step of the nearest searches (InitNearestSearch sets it up):
; HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C.
; Only the column distance counts; rows are ignored.
KeepNearest:
  PUSH HL
  EXX
  POP HL
  CALL ColumnDistance     ; the distance
  LD A,H
  CP B
  JR C,KeepNearestNew
  JR NZ,KeepNearestDone
  LD A,L
  CP C
  JR NC,KeepNearestDone
KeepNearestNew:
  LD B,H                  ; nearer: BC = the new best distance, D = its index
  LD C,L
  EXX
  LD D,C
  RET
KeepNearestDone:
  EXX                     ; back to the main registers
  RET

; HL = |HL - DE|
;
; A 16-bit absolute difference (the sign of the 16-bit result decides); A = 0
; on the negative path.
ColumnDistance:
  XOR A
  SBC HL,DE
  RET P
  SUB L                   ; negative: 0 - HL
  LD L,A
  LD A,$00
  SBC A,H
  LD H,A
  RET

; HL, B, E = the building table, its size and the owner a building order wants
;
; A = the order. Orders 5 and 8 (destroy / capture warbases): HL = $FD73, the
; owner byte of the first of the 4 warbase records (Warbases $FD70, 5 bytes
; each), B = 4; the others: HL = $FD87, the owner byte of the first of 24
; factory records (Factories $FD84), B = 24. E = the owner bits sought: $20
; (the computer's) for our robots, $40 (ours) for the enemy's (Side = 1), 0
; (neutral) for order 6, capture neutral factories.
TargetBuildingTable:
  LD HL,Factories+3
  LD B,$18
  CP $05
  JR Z,TargetWarbaseTable
  CP $08
  JR NZ,TargetBuildingMark
TargetWarbaseTable:
  LD HL,Warbases+3             ; orders 5 and 8: the 4 warbase records
  LD B,$04
TargetBuildingMark:
  LD E,$20                ; E = the owner mark wanted: the opponent's
  PUSH AF
  LD A,(Side)
  OR A
  JR Z,TargetNeutralCheck
  RLC E                   ; ... $40 for the enemy
TargetNeutralCheck:
  POP AF                  ; order 6 (capture neutral): mark 0
  CP $06
  RET NZ
  LD E,$00                ; capture neutral: owner bits 0
  RET

; HL = the opponent robot record of index +$0E
;
; HL = $DB80 + 16 * (+$0E) for our robots, $DA00 + 16 * (+$0E) for the enemy's
; (Side). Used by SteerByOrder's destroy-robots branch.
TargetRobotRecord:
  LD DE,Robots
  LD A,(Side)            ; the enemy's robots for us, ours for the enemy
  OR A
  JR NZ,TargetRobotIndex
  LD DE,EnemyRobots
TargetRobotIndex:
  LD A,(IY+$0E)           ; HL = DE + 16 x (+$0E)
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  RET

; start a nearest-by-column search from column HL
;
; DE' = HL (our column), BC' = $2000 (no candidate yet), C = 0 (the first
; index), D = $FF (the result: none). Used by FindTargetBuilding and
; FindNearestOpponent with KeepNearest.
InitNearestSearch:
  PUSH HL
  EXX
  POP DE
  LD BC,$2000
  EXX
  LD C,$00
  LD D,$FF
  RET

; D = the index of the nearest live opponent robot by column; Z when none
;
; HL = our column, IY the robot, Side set. Runs KeepNearest over the 24
; opponent records ($DB80 the enemy's for us, $DA00 ours for the enemy) whose
; +$01 is not 0 (a dying robot counts). Out D = the slot within the side (or
; $FF), A = D + 1 (Z: none). 426 calls.
;
; Reached from RobotStep for +$0A = 2 (not run in the deep recording;
; experiment below).
FindNearestOpponent:
  CALL InitNearestSearch
  PUSH IY
  LD IY,Robots            ; the opponent's records
  LD A,(Side)
  OR A
  JR NZ,FindOpponentStart
  LD IY,EnemyRobots
FindOpponentStart:
  LD B,$18                ; IY = the opponent's 24 records
FindOpponentLoop:
  LD A,(IY+$01)           ; a live record: compare its column
  OR A
  JR Z,FindOpponentNext
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL KeepNearest
FindOpponentNext:
  PUSH DE                 ; the next 16-byte record, C its index
  LD DE,$0010
  ADD IY,DE
  POP DE
  INC C
  DJNZ FindOpponentLoop
  POP IY
  LD A,D                  ; A = the index + 1: Z when none
  INC A
  RET
; This entry point is used by the routine at RobotStep.
RobotDirectControl:
  PUSH BC                 ; direct control: the stick steers the robot
  CALL WaitKey            ; Input, with the pause on key 1
  POP BC
  LD B,C                  ; B = the free directions
  CP (IY+$08)             ; pushing the way it faces: go only if free (a turn
                          ; needs no free cell)
  JR NZ,DirectStepSet
  AND C
DirectStepSet:
  LD C,A                  ; C = the pushed direction (masked by the free ones
                          ; when it faces it)
  CALL CountDirections    ; exactly one direction?
  JR Z,DirectStepStore
  LD A,(IY+$05)           ; none or several: go on the way it went, if still
                          ; free
  AND B
  LD C,A
DirectStepStore:
  LD (IY+$05),C           ; +$05 and Input = the step, then RobotMove
  LD A,C
  LD (Input),A            ; Input = the step, so MoveShip carries the ship
                          ; along (TurnOrStep)
  JP RobotMove

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
  OR A
  RET Z
  CP (IY+$08)             ; already facing it: step
  JR Z,TurnOrStepStep
  LD C,A                  ; C = the new facing
  OR (IY+$08)
  CP $03                  ; right <-> left: turn down / up first
  JR NZ,TurnCheckVertical
  RLC C
  RLC C
  JR TurnFace
TurnCheckVertical:
  CP $0C                  ; down <-> up: turn right / left first
  JR NZ,TurnFace
  RRC C
  RRC C
TurnFace:
  LD (IY+$08),C           ; +$08 = the new facing, +$06 counts the turn
  INC (IY+$06)
  RET
TurnOrStepStep:
  CALL StepPosition       ; step: the new column / row in HL / B
  CALL GroundUnderFootprint ; the highest ground under the new footprint
  LD (IY+$0D),A
  LD A,(IY+$0A)           ; direct control?
  CP $02
  RET NZ
  PUSH BC
  PUSH HL
  PUSH IY
  CALL Z,MoveShip         ; the ship moves by the same Input
  POP IY
  POP HL
  POP BC
  LD A,(IY+$09)           ; and sits on the robot's top
  ADD A,(IY+$0D)
  LD (Altitude),A
  RET

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
  RRCA
  JR NC,StepLeft
  INC HL
  LD A,(IY+$0B)
  DEC A
  JR Z,OrderDistanceDown
  DEC A
  JR Z,OrderDistanceUp
  RET
StepLeft:
  RRCA                    ; left: column - 1, the distance order counted the
                          ; other way
  JR NC,StepDown
  DEC HL
  LD A,(IY+$0B)
  DEC A
  JR Z,OrderDistanceUp
  DEC A
  JR Z,OrderDistanceDown
  RET
StepDown:
  RRCA                    ; down: row + 1
  JR NC,StepUp
  INC B
  RET
StepUp:
  RRCA                    ; up: row - 1
  RET NC
  DEC B
  RET
OrderDistanceUp:
  LD A,(IY+$0A)           ; a column away from the order's aim: one more to go
                          ; (max 99)
  CP $02
  RET Z
  INC (IY+$0E)
  LD A,(IY+$0E)
  CP $64
  RET C
  LD (IY+$0E),$63
  RET
OrderDistanceDown:
  LD A,(IY+$0A)           ; a column toward it: one less; there: stop
  CP $02
  RET Z
  DEC (IY+$0E)
  RET NZ
  LD (IY+$0B),$00         ; arrived: the order becomes stop
  LD (IY+$06),$00
  RET

; flags of (the number of set bits in C's low nibble) - 1
;
; Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3
; of C, keeps BC.
CountDirections:
  PUSH BC
  LD B,$04
  XOR A
CountDirectionsLoop:
  RR C                    ; add each bit
  ADC A,$00
  DJNZ CountDirectionsLoop
  POP BC
  CP $01
  RET

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
  LD C,$00
  LD A,(Altitude)            ; the ship lower than our top?
  SUB (IY+$09)
  SUB (IY+$0D)
  AND $80                 ; then bit 7 (the ship's cell) blocks too
  OR $40                  ; objects always block
  LD E,A
  LD A,(IY+$07)
  LD D,$08                ; bipod: types below 8
  RRCA
  JR C,FreeDirRight
  LD D,$0C                ; tracks: types below $0C
  RRCA
  JR C,FreeDirRight
  LD D,$0F                ; anti-grav: types below $0F
FreeDirRight:
  PUSH HL                 ; D = the terrain limit of the locomotion; right
                          ; free?
  CALL CanMoveRight
  POP HL
  JR NZ,FreeDirLeft
  SET 0,C
FreeDirLeft:
  PUSH HL                 ; left free?
  CALL CanMoveLeft
  POP HL
  JR NZ,FreeDirDown
  SET 1,C
FreeDirDown:
  PUSH HL                 ; down free?
  CALL CanMoveDown
  POP HL
  JR NZ,FreeDirUp
  SET 2,C
FreeDirUp:
  PUSH HL                 ; up free?
  CALL CanMoveUp
  POP HL
  JR NZ,FreeDirDone
  SET 3,C
FreeDirDone:
  RET                     ; C = the free directions

; Z when the robot at HL can step right
;
; Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y); an
; object anchored at (X+2, Y+1) (its footprint would overlap) when that row
; exists.
CanMoveRight:
  INC HL
  INC HL
  DEC H
  DEC H
  CALL TestCell
  RET NZ
  INC H
  INC H
  CALL TestCell
  RET NZ
  INC H
  INC H
  LD A,H                  ; the row below only inside the map
  CP $FD
  JR NC,CellOffMapFree
  LD A,(HL)
  AND E
  RET

; Z when the robot at HL can step left
;
; Terrain and objects at (X-1, Y-1) and (X-1, Y); objects anchored at (X-2,
; Y-1), (X-2, Y) and (X-2, Y+1).
CanMoveLeft:
  DEC H
  DEC H
  DEC HL
  CALL TestCell
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  INC H
  INC H
  LD A,(HL)
  AND E
  RET NZ
  INC HL
  CALL TestCell
  RET NZ
  DEC HL
  INC H
  INC H
  LD A,H                  ; the row below only inside the map
  CP $FD
  JR NC,CellOffMapFree
  LD A,(HL)
  AND E
  RET

; Z when the robot at HL can step down
;
; Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1);
; objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.
CanMoveDown:
  INC H
  INC H
  LD A,H                  ; the bottom row: blocked
  CP $FD
  JR NC,CellBlocked
  CALL TestCell
  RET NZ
  INC HL
  CALL TestCell
  RET NZ
  INC H
  INC H
  LD A,H                  ; the row below only inside the map
  CP $FD
  JR NC,CellOffMapFree
  LD A,(HL)
  AND E
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET

; Z when the robot at HL can step up
;
; Blocked when Y-2 is above the map (the footprint already covers Y-1); an
; object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1,
; Y-2).
CanMoveUp:
  DEC H
  DEC H
  DEC H
  DEC H
  LD A,H                  ; Y-2 off the map: blocked
  CP $DD
  JR C,CellBlocked
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  INC HL
  CALL TestCell
  RET NZ
  INC HL
  CALL TestCell
  RET

; Z: a probe that runs past the bottom row finds the way free
;
; The shared exit of the probes for rows below the map.
CellOffMapFree:
  XOR A
  RET

; NZ: the way is blocked
;
; The shared exit for an unpassable terrain type or a map edge.
CellBlocked:
  OR $01
  RET

; Z when cell HL is passable: type below D and none of the bits E
;
; 67380 calls.
TestCell:
  LD A,(HL)
  AND $1F
  CP D
  JR NC,CellBlocked
  LD A,(HL)               ; an object (or the low ship) in it?
  AND E
  RET

; A = the highest ground under the 2x2 footprint anchored at (HL, B)
;
; HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1);
; HL and BC are kept. The robots' +$0D (the ground they stand on, added to
; their height for the ship) and the shots' wall test (MoveShot).
GroundUnderFootprint:
  PUSH HL
  PUSH BC
  LD A,B
  CALL MapCell
  EX DE,HL
  LD C,$00
  CALL TerrainTop
  INC DE
  CALL TerrainTop
  DEC D
  DEC D
  CALL TerrainTop
  DEC DE
  CALL TerrainTop
  LD A,C
  POP BC
  POP HL
  RET

; +$0F = the turns until the robot's next step, by the ground and its
; locomotion
;
; The ground class from +$0D: 0 flat, 1-3 low, 4 and more high; the column from
; the lowest set part bit of +$07: 0 bipod, 1 tracks, 2 anti-grav. StepDelays
; gives the turns. The recorded records agree (robot 0, a bipod on flat ground,
; counts 6 down).
SetStepDelay:
  PUSH BC
  PUSH HL
  LD A,(IY+$0D)
  LD C,$00
  OR A
  JR Z,SetStepDelayFind
  LD C,$03                ; low ground
  CP $04
  JR C,SetStepDelayFind
  LD C,$06                ; high ground
SetStepDelayFind:
  LD A,(IY+$07)           ; C = the ground class (0 flat, 3 low, 6 high); find
                          ; the locomotion part
  LD D,$FF
SetStepDelayPart:
  INC D                   ; D = the locomotion: the index of the first set part
                          ; bit
  RRCA
  JR NC,SetStepDelayPart
  LD A,C
  ADD A,D
  LD HL,StepDelays
  CALL AddAToHL
  LD A,(HL)
  LD (IY+$0F),A
  POP HL
  POP BC
  RET

; Game turns a robot step takes: rows flat, low, high ground; columns bipod,
; tracks, anti-grav
;
; 6 4 3 / 8 6 3 / 9 7 4. Read by SetStepDelay; a game turn is about 10 frames,
; so a bipod on flat ground steps every 60 frames.
StepDelays:
  DEFB $06,$04,$03
  DEFB $08,$06,$03
  DEFB $09,$07,$04

; E = the directions in which a live opponent robot is in sight
;
; IY the robot. For each direction (up, down, left, right: E's bits 3, 2, 1, 0
; as in Input) ScanLane looks from the robot's anchor up to 8 cells; in the
; facing direction +$08 the range is 10, 12 with electronics (+$07 bit 7), and
; three parallel lanes are scanned (the columns X-1, X, X+1 for up / down, the
; rows Y-1, Y, Y+1 for left / right). 9652 calls.
SpotEnemies:
  LD E,$00
  LD D,$08                ; D = the direction scanned: up first
SpotEnemiesLoop:
  RLC E                   ; the next result bit
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD B,$08                ; the range: 8 cells
  LD A,D
  CP (IY+$08)             ; the facing direction ...
  JR NZ,SpotEnemiesLane
  LD B,$0A                ; ... sees 10 cells ...
  BIT 7,(IY+$07)
  JR Z,SpotEnemiesThree
  LD B,$0C                ; ... 12 with electronics ...
SpotEnemiesThree:
  LD A,D                  ; B = the range; three lanes, columns for down / up,
                          ; rows for right / left
  AND $03
  JR NZ,SpotEnemiesRows
  LD C,B                  ; up / down: the columns X-1, X, X+1
  DEC HL
  CALL ScanLane
  LD B,C
  INC HL
  CALL ScanLane
  LD B,C
  INC HL
  JR SpotEnemiesLane
SpotEnemiesRows:
  LD C,B                  ; left / right: the rows Y-1, Y, Y+1
  DEC H
  DEC H
  CALL ScanLane
  LD B,C
  INC H
  INC H
  CALL ScanLane
  LD B,C
  INC H
  INC H
SpotEnemiesLane:
  CALL ScanLane           ; the (last) lane
  RRC D                   ; the next direction: down, left, right
  JR NC,SpotEnemiesLoop
  RET

; set E bit 0 when a live opponent's anchor lies within B cells from HL in
; direction D
;
; The step comes from LaneSteps by D's bit. The scan stops at the map's top or
; bottom edge and at the first cell with an object (bit 6): only a robot of the
; other side (+$0A bit 7 differs) with strength above 0 sets the bit.
; Buildings, shots and friends block the view. HL, DE are kept apart from E's
; bit 0.
ScanLane:
  PUSH HL
  PUSH DE
  PUSH HL
  LD HL,ScanLaneDone+$0001 ; LaneSteps - 2
  LD A,D
ScanLaneStep:
  INC HL                  ; the step word for D's bit
  INC HL
  RRCA
  JR NC,ScanLaneStep
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
ScanLaneLoop:
  ADD HL,DE               ; one cell on
  LD A,H                  ; off the map's rows: stop
  SUB $DD
  CP $20
  JR NC,ScanLaneDone
  BIT 6,(HL)              ; the first object stops the view
  JR NZ,ScanLaneObject
  DJNZ ScanLaneLoop
  JR ScanLaneDone
ScanLaneObject:
  PUSH IY                 ; a robot?
  CALL FindRobot
  LD A,(IY+$0A)
  LD B,(IY+$0C)
  POP IY
  JR NZ,ScanLaneDone
  XOR (IY+$0A)            ; same side: no
  JP P,ScanLaneDone
  DEC B                   ; dead or dying: no
  JP M,ScanLaneDone
  POP DE                  ; an opponent in sight
  LD A,E
  OR $01
  LD E,A
  PUSH DE
ScanLaneDone:
  POP DE                  ; back with E
  POP HL
  RET

; The map steps of the four directions: right +1, left -1, down +$200, up -$200
;
; Read by ScanLane (from LD HL,$B6AE and two INC HL a bit of D), in the Input
; bit order.
LaneSteps:
  DEFW $0001,$FFFF,$0200,$FE00

; IY = a free shot record of the shooter IX's side; Z when one is free
;
; Each side has two shot records of 9 bytes: ours $D7DC and $D7E5, the enemy's
; $D7EE and $D7F7 (by IX +$0A bit 7). Z with IY on the first one whose +$01 is
; 0; NZ when both fly. Record 0 ($D7D3) is not handed out here: it is the
; player's COMBAT MODE shot, launched from the robot menu (DirectControl, not
; in the recording).
FindFreeShot:
  LD IY,Shots+$0009
  BIT 7,(IX+$0A)
  JR Z,FindFreeShotSlot
  LD DE,$0012             ; the enemy's records
  ADD IY,DE
FindFreeShotSlot:
  LD A,(IY+$01)           ; IY = the side's first shot record; Z when free,
                          ; else the second
  OR A
  RET Z
  LD DE,$0009             ; the second record
  ADD IY,DE
  LD A,(IY+$01)
  OR A
  RET

; launch shot IY of weapon A from robot IX in its facing direction
;
; Called by RobotStep and by COMBAT MODE in the robot menu (DirectControl, IX =
; IY = the robot, record 0). Shot record (9 bytes): +$00/+$01 the map cell,
; +$02/+$03 the column, +$04 the row, +$05 the direction, +$06 the steps left,
; +$07 the weapon (1 cannon, 2 missiles, 3 phasers), +$08 the ground height
; that stops it ($0A). The range is 5 steps (7 for missiles), one more with
; electronics; each step goes 2 cells. The first step is taken at once
; (MoveShot); when the shot survives it, SoundFx ($FD53) = 1, the firing sound.
; Recording: an enemy missile at frame 18680, D7EE: 7B F3 7B 00 0B 08 06 02 0A
; (column $7B, row 11, up, 6 steps left after the first turn, missiles).
FireShot:
  LD (IY+$07),A
  LD C,$05
  CP $02                  ; missiles fly further
  JR NZ,FireShotElectronics
  LD C,$07
FireShotElectronics:
  BIT 7,(IX+$07)          ; electronics: the range one step more
  JR Z,FireShotStart
  INC C
FireShotStart:
  LD (IY+$06),C           ; +$06 the range, +$05 the robot's facing, +$08 the
                          ; wall height, the first step
  LD A,(IX+$08)           ; the robot's facing
  LD (IY+$05),A
  LD (IY+$08),$0A         ; ground of height 10 or more stops it
                          ; (TerrainHeights 15)
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD B,(IX+$04)
  CALL MoveShot           ; the first step
  LD A,(IY+$01)
  OR A
  JR Z,FireShotDone
  LD A,$01                ; it flies: the firing sound
  LD (SoundFx),A
FireShotDone:
  RET                     ; the shot ended at once: no sound

; one game turn of shot IY: off its cell, count its range, a step
;
; Clears the object bit of the shot's cell, counts +$06 down (0: the shot is
; gone, ShotGone) and goes on into MoveShot from its column / row. 90 calls in
; the deep recording.
UpdateShot:
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 6,(HL)              ; the shot leaves its cell
  DEC (IY+$06)            ; out of range: gone
  JP Z,ShotGone
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD B,(IY+$04)

; move shot IY 2 cells, then hit a wall, an object or fly on
;
; HL the column, B the row. Off the rows 0-15, or ground of height +$08 ($0A)
; or more under its 2x2 footprint (only the types $10 / $12, height 15; heights
; up to 7 let it pass): gone. Then the 3x3 cells around the new cell are tested
; for an object (bit 6); none: the shot marks its own cell with bit 6 and flies
; on. An object that is a live robot (either side: friendly fire is possible)
; takes damage ((60 - its top) / 4) * (weapon + 1), the top being +$09 + +$0D,
; so tall robots on high ground take less: strength 0 or below makes it $FC
; (dying, UpdateRobot) with SoundFx $C8, else SoundFx $FA. Any other object (a
; building, another shot, a dying robot) just ends the shot (SoundFx $FC). The
; recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 = 30, a
; cannon shell 10 * 2 = 20.
MoveShot:
  LD A,(IY+$05)
  RRCA                    ; right: 2 columns
  JR NC,MoveShotLeft
  INC HL
  INC HL
  JR MoveShotStore
MoveShotLeft:
  RRCA                    ; left: 2 columns
  JR NC,MoveShotDown
  DEC HL
  DEC HL
  JR MoveShotStore
MoveShotDown:
  RRCA                    ; down: 2 rows
  JR NC,MoveShotUp
  INC B
  INC B
  JR MoveShotRows
MoveShotUp:
  RRCA                    ; up: 2 rows
  JR NC,MoveShotStore
  DEC B
  DEC B
MoveShotRows:
  LD A,B                  ; past the map's rows: the shot is gone
  CP $10
  JP NC,ShotGone
MoveShotStore:
  LD (IY+$02),L           ; the new position
  LD (IY+$03),H
  LD (IY+$04),B
  CALL GroundUnderFootprint ; the ground under it
  CP (IY+$08)             ; too high: it hits the wall
  JP NC,ShotGone
  LD A,B
  CALL MapCell            ; the new cell
  LD (IY+$00),L
  LD (IY+$01),H
  PUSH HL                 ; the row above: Y-1, columns X-1 to X+1 (when inside
                          ; the map)
  DEC HL
  DEC H
  DEC H
  LD A,H
  CP $DD
  JR C,MoveShotRow
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  DEC HL
  DEC HL
MoveShotRow:
  INC H                   ; the shot's row
  INC H
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  DEC HL
  DEC HL
  INC H                   ; the row below (when inside the map)
  INC H
  LD A,H
  CP $FD
  JR NC,MoveShotFlies
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
MoveShotFlies:
  POP HL                  ; nothing near: the shot occupies its cell
  SET 6,(HL)
  RET
MoveShotHit:
  PUSH IY                 ; hit: E = the weapon, C = the sound for a miss
  LD E,(IY+$07)
  LD C,$FC
  CALL FindRobot          ; a robot anchored at the cell hit?
  JR NZ,MoveShotGone
  LD A,(IY+$0C)           ; alive?
  DEC A
  JP M,MoveShotGone
  LD A,$3C                ; (60 - its top) / 4 ...
  SUB (IY+$09)
  SUB (IY+$0D)
  SRL A
  SRL A
  LD D,A
  LD B,E                  ; ... times the weapon + 1
MoveShotDamage:
  ADD A,D                 ; one more multiple
  DJNZ MoveShotDamage
  LD B,A
  LD C,$FA                ; the hit sound
  LD A,(IY+$0C)
  SUB B                   ; the strength left
  JR Z,MoveShotKill
  JP P,MoveShotStrength
MoveShotKill:
  LD A,$FC                ; strength 0 or less: dying for 4 turns, the
                          ; explosion sound
  LD C,$C8
MoveShotStrength:
  LD (IY+$0C),A           ; +$0C = the strength left
MoveShotGone:
  POP IY                  ; the shot is gone
  POP HL
  LD (IY+$01),$00
  LD A,C
  LD (SoundFx),A
  RET

; ShotGone
;
; Used by the routines at UpdateShot and MoveShot.
ShotGone:
  LD (IY+$01),$00         ; out of range or off the map: the shot is gone with
                          ; the short sound
  LD A,$FC
  LD (SoundFx),A
  RET
