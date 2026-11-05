; --------------------------------------------------------------------------------------------------------------------
; enemy.asm: the computer's side: the enemy commander, its robot builds and orders, and the nuclear blast
;
; The Insignians have no planner beyond EnemyCommander: once a game turn it looks at one random slot of its 24 robot
; records and either builds a robot there or reconsiders that robot's order. The nuclear blast that a robot with order
; 4 or 5 sets off at its target, or the player's NUCLEAR BOMB, lives here too (10.9).
;
; In calling order: EnemyCommander (first in every WorldTurn) picks the slot; a free slot goes through SpawnPickBase
; (a random enemy warbase), the door check, the random parts (SpawnCheckWeapons), the payment on a copy (SpawnPayPart,
; SpawnCheckGeneral), PlaceRobot and the start values, the height (SpawnHeightLoop), CountRobots and
; UpdateStatusPanel. A live robot goes to EnemyReplan, then EnemyChooseOrder (EnemyCaptureOrder, EnemySetCapture) and
; EnemyFindTarget (FindTargetBuilding).
;
; NuclearBlast (from SteerByOrder and the combat menu) looks for the first intact base in reach (BlastBaseLoop;
; DestroyWarbase / DestroyFactory of the bases module), then the 9 x 9 round area (BlastRow, BlastCell: robots freed,
; blocks $11-$14 to debris), the robot's own end, NuclearFlash (the attribute flicker) with NuclearRumble (the noise
; of ROM bytes), the radar rebuild and the recounts.
;
; Data it uses: the enemy's robot records EnemyRobots ($DB80, 24 x 16 bytes, the bases tables Warbases ($FD70) and
; Factories ($FD84) through their +3 owner bytes, EnemyResources ($FD4A) spent through the copy MenuResources and the
; construction menu's tables PartCosts (+8: the resource each part pays from) and PartHeights ($D7B4), EnemyRobotCount
; ($FD49), Side ($FD51) for the target searches. NuclearFlash saves the view's attributes in ViewBuffer ($5B00).
;
; Tricks: the enemy builds with one random byte as its whole design and simply gives up the turn when the byte breaks
; a rule, so its army grows by chance; the placing keeps the door's x / y in the alternate registers HL' / B' across
; the payment. NuclearRumble plays the bytes of the 48K ROM from $0090 as noise.
; --------------------------------------------------------------------------------------------------------------------

; once a game turn the computer looks at one of its 24 robot slots: builds a
; robot in a free one or re-thinks a robot's order
;
; Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a
; quarter of the turns) do nothing. Side = 1. The slot's record is $DB80 + 16 *
; n.
;
; A live robot goes to EnemyReplan: one with order 0 at once, any other with a
; 1/32 chance a turn, gets a new order (EnemyChooseOrder: a nuclear robot
; destroy factories or warbases, the others one of the capture orders; destroy
; robots when the order finds no target). Orders 4-8 are kept only while the
; target has changed owner and the robot stands on its door: the capture under
; way.
;
; A free slot tries a build at a random enemy warbase (owner $20 in the
; Warbases table) whose door and the three cells below it are free of bit 6:
; random parts (exactly one locomotion, at least one and not all four of the
; weapon / nuclear parts, at least 1, 2 or 3 of those parts while the computer
; has 0-7, 8-15 or 16-23 robots, EnemyRobotCount $FD49), paid from
; EnemyResources ($FD4A, through MenuResources and PartCosts like the
; player's), the shortfall of the other resources taken from the general one,
; at most half of it (at least 11). A refused design is not retried: the slot
; waits for another turn.
;
; The robot is set up facing down, 3 steps, order 0, strength $64, +$0A = $80,
; +$0E = $FF, +$0F = 1, height +$09 the sum of the part heights $D7B4 (bipod
; 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7,
; electronics 7; then CountRobots and UpdateStatusPanel. IY is left on the
; slot's record; A, BC, DE, HL and the alternate HL', B' lost.
EnemyCommander:
  CALL Random             ; a random slot...
  AND $1F                 ; 0-31
  CP $18                  ; ... of the computer's 24, or none this turn
  RET NC                  ; 24-31: nothing this turn
  ADD A,A                 ; * 16: the record's offset from $DB80
  ADD A,A                 ; * 4
  ADD A,A                 ; * 8
  LD L,A                  ; HL = slot * 8...
  LD H,$00                ; HL = slot * 16 (A = slot * 8)
  ADD HL,HL               ; ... * 2: slot * 16
  LD DE,EnemyRobots             ; the enemy's records begin at slot 24, $DB80
  ADD HL,DE               ; HL = the slot's record
  PUSH HL                 ; IY = it...
  POP IY                  ; ... the robot record from here on
  LD A,$01                ; ActingSide = 1: the target searches ($B3D5, $B36C)
                          ; look from the enemy's side
  LD (Side),A            ; Side = the enemy
  LD A,(IY+$01)           ; a live robot in the slot: re-plan its order instead
  OR A                    ; +$01 0: a free slot
  JP NZ,EnemyReplan       ; taken: its order instead
  LD B,$04                ; a free slot: try to build a robot, one try a
                          ; warbase: 4 in the image, all the warbases after
                          ; LOAD MAP (NELEV byte $1FE + 1)
  LD HL,Warbases+3             ; the owner byte (+3) of warbase 0 in the bases table
                          ; $FD70
SpawnPickBase:
  CALL Random             ; each warbase in turn is taken with chance 1/2
  AND $01                 ; this warbase at all?
  JR Z,SpawnNextBase      ; not this time: the next one
  LD A,(HL)               ; and only if its +3 is $20 exactly: the enemy's, not
                          ; destroyed
  CP $20                  ; the enemy's and intact?
  JR Z,SpawnAtBase        ; yes: build here
SpawnNextBase:
  LD A,$05                ; the next 5-byte base record
  CALL AddAToHL           ; HL = the next warbase's +3
  DJNZ SpawnPickBase      ; the four warbases
  RET                     ; no warbase taken: no robot this turn
SpawnAtBase:
  DEC HL                  ; B = the warbase's y, HL = its x: the door cell the
                          ; robot appears on
  LD B,(HL)               ; B = the door's row (+2)
  DEC HL                  ; the column's high byte (+1)
  LD A,(HL)               ; A = it
  DEC HL                  ; the low byte (+0)
  LD L,(HL)               ; L = it
  LD H,A                  ; HL = the door's column
  LD A,B                  ; A = the row, for MapCell
  PUSH HL                 ; x to HL' and y to B' for the placing at $B8D9
  EXX                     ; to the alternate set:
  POP HL                  ; HL' = the column
  LD B,A                  ; B' = the row
  EXX                     ; back to the main set
  CALL MapCell            ; HL = the door's map cell
  PUSH HL                 ; the door and the three cells in front of it (row
                          ; y+1, x-1 to x+1) must hold no robot or building
                          ; (bit 6)
  LD A,(HL)               ; the door cell
  INC H                   ; one row down...
  INC H                   ; ... (a row is $200 bytes): (x, y+1)
  OR (HL)                 ; its bits too
  DEC HL                  ; (x-1, y+1)
  OR (HL)                 ; its bits too
  INC HL                  ; ...
  INC HL                  ; (x+1, y+1)
  OR (HL)                 ; its bits too
  AND $40                 ; bit 6 on any of the four: an anchor there
  POP HL                  ; HL = the door cell again
  RET NZ                  ; blocked: wait for another turn
  CALL Random             ; the parts: a random mask (the second of two draws)
  CALL Random             ; the mask
  LD C,A                  ; C = the parts
  LD (IY+$07),A           ; +$07 = the parts, the robot's design (a refused one
                          ; is never used)
  AND $07                 ; the chassis bits 0-2: exactly one of bipod, tracks,
                          ; anti-grav
  CP $01                  ; bipod alone?
  JR Z,SpawnCheckWeapons  ; yes
  CP $02                  ; tracks alone?
  JR Z,SpawnCheckWeapons  ; yes
  CP $04                  ; anti-grav alone?
  RET NZ                  ; none or two chassis: no robot
SpawnCheckWeapons:
  LD A,C                  ; C = the weapons, bits 3-6 (cannon, missiles,
                          ; phasers, nuclear)
  RRCA                    ; bits 3-6...
  RRCA                    ; ...
  RRCA                    ; ... to bits 0-3
  AND $0F                 ; the four weapon bits
  RET Z                   ; no weapon: no robot
  CP $0F                  ; all four?
  RET Z                   ; all four weapons: no robot
  LD C,A                  ; C = the weapon bits, for CountDirections
  LD A,(EnemyRobotCount)            ; B = EnemyRobots / 8 + 1: 1 below 8 robots, 2 from
                          ; 8, 3 from 16
  RRCA                    ; the count / 2...
  RRCA                    ; / 4...
  RRCA                    ; / 8 (the count is at most 24)
  INC A                   ; + 1
  AND $03                 ; 1-3 (24 robots would give 0, but then no slot is
                          ; free)
  LD B,A                  ; B = the weapons needed
  CALL CountDirections    ; A = the number of weapons ($B505)
  CP B                    ; enough of them?
  RET C                   ; fewer weapons than B: no robot (a bigger army
                          ; builds only better-armed robots)
  LD HL,EnemyResources             ; spend on a copy: the enemy's resources into
                          ; MenuResources. MEDIUM and up: the start-up menu
                          ; writes CALL FillEnemyResources ($A5F2) over the LD
                          ; HL: the enemy's resources are 99 again before each
                          ; build, HL = $FD4A as before
  LD DE,MenuResources             ; the construction menu's scratch copy
  LD BC,$0007             ; 7 resources
  LDIR                    ; copy them
  LD C,(IY+$07)           ; D: the shortfall the general resource has to cover
  LD D,$00                ; no shortfall yet
  LD B,$08                ; 8 part bits
SpawnPayPart:
  RRC C                   ; for each part in the mask, bipod first
  JR NC,SpawnNextPart     ; this part not in the mask
  LD A,$08                ; A = the part's index 0-7
  SUB B                   ; 8 - B: 0 bipod... 7 electronics
  PUSH AF                 ; keep the index
  LD HL,PartCosts         ; E = its cost (PartCosts)
  CALL AddAToHL           ; HL = the part's cost entry
  LD E,(HL)               ; E = the cost
  POP AF                  ; A = the index again
  LD HL,PartCosts+$0008   ; the resource it takes first (PartCosts + 8)
  CALL AddAToHL           ; HL = the part's resource entry
  LD A,(HL)               ; A = the resource's index 0-6
  LD HL,MenuResources             ; the copy of the resources
  CALL AddAToHL           ; HL = that resource in the copy
  LD A,(HL)               ; A = what is left of it
  SUB E                   ; pay from that resource
  JP P,SpawnStoreResource ; enough: store what remains
  NEG                     ; not enough: the rest joins the shortfall, the
                          ; resource drops to 0
  ADD A,D                 ; + the shortfall so far
  LD D,A                  ; D = the new shortfall
  XOR A                   ; the resource is spent to 0
SpawnStoreResource:
  LD (HL),A               ; the resource's new value
SpawnNextPart:
  DJNZ SpawnPayPart       ; all 8 part bits
  LD HL,MenuResources             ; the general resource may cover a shortfall up to
                          ; max(general / 2, 11)
  LD A,(HL)               ; A = the general resource (the copy)
  SRL A                   ; half of it
  CP $0B                  ; at least 11?
  JR NC,SpawnCheckGeneral ; yes: that half is the limit
  LD A,$0B                ; else 11
SpawnCheckGeneral:
  CP D                    ; the limit against the shortfall D
  RET C                   ; the shortfall is too big: no robot, nothing spent
  LD A,(HL)               ; the general resource:
  SUB D                   ; minus the shortfall
  RET M                   ; the general resource cannot pay it: no robot
  LD (HL),A               ; the general resource pays it
  LD DE,EnemyResources             ; commit: the copy back to the enemy's resources
                          ; $FD4A
  LD BC,$0007             ; 7 resources
  LDIR                    ; the enemy has paid
  LD (IY+$0A),$80         ; +$0A = $80: an enemy robot
  EXX                     ; HL' = the column, B' = the row
  CALL PlaceRobot         ; place it on the door (x in HL', y in B'): +2 to +4,
                          ; the cell +0/+1, map bit 6, the radar dot
  EXX                     ; back to the main set
  LD (IY+$05),$04         ; the start values; the player's robots get the same
                          ; at $A6F3, except +6 = 5 there
  LD (IY+$08),$04         ; +$08 = 4: facing down
  LD (IY+$06),$03         ; +$06 = 3 steps on that course
  LD (IY+$0D),$00         ; +$0D = 0: the ground, set by its first step
  LD (IY+$0B),$00         ; order 0: the next visit of this slot chooses one
  LD (IY+$0F),$01         ; +$0F = 1: it moves at the next turn
  LD (IY+$0C),$64         ; +$0C = 100 (the strength a new robot starts with)
  LD (IY+$0E),$FF         ; no target yet
  LD C,(IY+$07)           ; the height +9: the sum of the parts' heights
  LD B,$08                ; 8 part bits
  LD D,$00                ; D = the height so far
SpawnHeightLoop:
  RRC C                   ; the next part bit, bipod first
  JR NC,SpawnHeightNext   ; not in the mask
  LD A,$08                ; the part's index:
  SUB B                   ; 8 - B, 0-7
  LD HL,PartHeights       ; the part heights at $D7B4: bipod 11, tracks 7,
                          ; anti-grav 8, cannon 6, missiles 6, phasers 7,
                          ; nuclear 7, electronics 7
  CALL AddAToHL           ; HL = its height entry
  LD A,(HL)               ; A = the part's height
  ADD A,D                 ; + the sum so far
  LD D,A                  ; D = the new sum
SpawnHeightNext:
  DJNZ SpawnHeightLoop    ; all 8 part bits
  LD (IY+$09),D           ; +$09 = the height
  CALL CountRobots        ; recount the robots, redraw the status panel
  CALL UpdateStatusPanel  ; the panel's ROBOTS line
  RET                     ; one robot more for the enemy
EnemyReplan:
  LD A,(IY+$0B)           ; a live enemy robot: order 0 is replaced at once
  OR A                    ; order 0 (stop, a new robot)?
  JR Z,EnemyChooseOrder   ; yes: choose one now
  LD B,A                  ; B = the order
  CALL Random             ; any other order is reconsidered once in 32 turns
  AND $1F                 ; 1 in 32
  RET NZ                  ; no: the order stays this turn
  LD A,B                  ; A = the order
  CP $04                  ; orders 1-3 (advance, retreat, destroy robots):
                          ; choose anew
  JR C,EnemyChooseOrder   ; yes: a new order
  LD A,(IY+$0B)           ; orders 4-8: HL = the target table's +3 bytes, E =
                          ; the owner bits the order looks for ($B3D5)
  CALL TargetBuildingTable ; HL = the order's table (+3 bytes), E = the owner
                           ; bits it wants
  LD A,(IY+$0E)           ; HL = the target's +3 byte (+$0E = the target's
                          ; index)
  LD B,A                  ; B = the index
  ADD A,A                 ; * 2
  ADD A,A                 ; * 4
  ADD A,B                 ; * 5, a record's size
  CALL AddAToHL           ; HL = the target record's +3
  LD A,(HL)               ; the target still has the owner the order looks for:
                          ; choose anew (again the nearest)
  AND $E0                 ; its owner bits 5-7
  CP E                    ; the owner the order wants?
  JR Z,EnemyChooseOrder   ; yes: re-chosen (usually the same nearest target)
  DEC HL                  ; the target changed hands (or was destroyed): keep
                          ; the order only while the robot stands on its door
  LD A,(IY+$04)           ; the robot's row
  SUB (HL)                ; - the target door's row
  JR NZ,EnemyChooseOrder  ; not on the door's row: choose anew
  DEC HL                  ; the column, high byte (+1)...
  LD D,(HL)               ; ... to D
  DEC HL                  ; low byte (+0)...
  LD E,(HL)               ; ... to E: DE = the door's column
  LD L,(IY+$02)           ; HL = the robot's column
  LD H,(IY+$03)           ; (+$03 the high byte)
  XOR A                   ; no borrow
  SBC HL,DE               ; the robot's column - the door's
  RET Z                   ; on the target's door: keep the order
EnemyChooseOrder:
  LD (IY+$0B),$03         ; 3 (destroy robots) unless a target is found below
  BIT 6,(IY+$07)          ; with nuclear: a demolition order
  JR Z,EnemyCaptureOrder  ; no nuclear: a capture order
  CALL Random             ; 5 (destroy warbases) with chance 3/4 (bit 0 or bit
                          ; 7 set), else 4 (destroy factories)
  LD B,A                  ; B = the random byte
  RLCA                    ; bit 7 to bit 0
  OR B                    ; bit 0 = bit 0 or bit 7
  AND $01                 ; 1 with chance 3/4
  ADD A,$04               ; 4 or 5
  LD (IY+$0B),A           ; +$0B = the demolition order
  JR EnemyFindTarget      ; on to its target
EnemyCaptureOrder:
  LD C,$00                ; without nuclear: a capture order
  CALL Random             ; a random byte
  RRCA                    ; bit 0: 6 (capture neutral factories, 1/2), bit 1: 7
                          ; (the player's factories, 1/4), else 8 (the player's
                          ; warbases, 1/4)
  JR C,EnemySetCapture    ; bit 0 set: C = 0, order 6
  INC C                   ; C = 1
  RRCA                    ; bit 1 into the carry
  JR C,EnemySetCapture    ; set: order 7
  INC C                   ; C = 2: order 8
EnemySetCapture:
  LD A,C                  ; the choice 0-2
  ADD A,$06               ; + 6: order 6-8
  LD (IY+$0B),A           ; +$0B = the capture order
EnemyFindTarget:
  LD L,(IY+$02)           ; the nearest target of the order from the robot's x
                          ; ($B34D): D its index, $FF none
  LD H,(IY+$03)           ; HL = the robot's column
  LD (IY+$0E),$FF         ; +$0E = none, so the search does not skip a target
                          ; as its own
  CALL FindTargetBuilding ; D = the nearest target, Z: none
  LD (IY+$0E),D           ; +$0E = the target's index
  RET NZ                  ; found: keep the order
  LD (IY+$0B),$03         ; no such target: destroy robots
  RET                     ; the order is set

; NuclearBlast
;
; Used by the routines at CombatMenuCode and SteerByOrder.
NuclearBlast:
  LD HL,Warbases+3             ; the blast of robot IY: order 4 / 5 at its target
                          ; (SteerByOrder) or NUCLEAR BOMB; first the bases
  LD C,$00                ; C = the base index 0-27 (0-3 warbases; D = the
                          ; reach in rows and in columns, E = in rows +
                          ; columns: 7, 10
  LD DE,$070A             ; D = 7, E = 10: the warbases' reach
BlastBaseLoop:
  PUSH HL                 ; keep the base's +3 address
  BIT 7,(HL)              ; a destroyed base (bit 7) is skipped
  JR NZ,BlastNextBase     ; destroyed: the next base
  DEC HL                  ; HL = the base's row (+2)
  LD A,C                  ; the base index:
  CP $04                  ; carry: a warbase (0-3)
  LD A,(IY+$04)           ; A = the robot's y, + 4 for a warbase
  JR NC,BlastRowDistance  ; a factory: the robot's y as it is
  ADD A,$04               ; a warbase: y + 4
BlastRowDistance:
  INC A                   ; dy = |robot y + 5 - y| for a warbase, |robot y + 1
                          ; - y| for a factory
  SUB (HL)                ; - the base's row
  JP P,BlastCheckRow      ; positive: that is dy
  NEG                     ; negative: |dy|
BlastCheckRow:
  LD B,A                  ; B = dy
  CP D                    ; dy below the row reach D?
  JR NC,BlastNextBase     ; dy out of reach
  PUSH DE                 ; keep the reach
  DEC HL                  ; the base's column, high byte (+1)...
  LD D,(HL)               ; ... to D
  DEC HL                  ; low byte (+0)...
  LD E,(HL)               ; ... to E: DE = the base's column
  LD L,(IY+$02)           ; HL = the robot's column
  LD H,(IY+$03)           ; (+$03 the high byte)
  CALL ColumnDistance     ; HL = dx = |robot x - base x| ($B3CA)
  POP DE                  ; D, E = the reach again
  LD A,H                  ; dx's high byte
  OR A                    ; not 0?
  JR NZ,BlastNextBase     ; dx of 256 or more
  LD A,L                  ; A = dx
  CP D                    ; dx below the column reach D?
  JR NC,BlastNextBase     ; dx out of reach
  ADD A,B                 ; dx + dy
  CP E                    ; below the sum reach E?
  JR C,BlastHitBase       ; inside: the first base found in reach goes
BlastNextBase:
  POP HL                  ; HL = the base's +3
  LD A,$05                ; the next 5-byte record
  CALL AddAToHL           ; HL = its +3
  INC C                   ; the next base index
  LD A,C                  ; A = it
  CP $04                  ; still a warbase?
  JR C,BlastBaseLoop      ; yes: the warbase reach
  LD DE,$0507             ; from base 4 on, the factories: reach 5, sum 7
  CP $1C                  ; all 28 bases?
  JR C,BlastBaseLoop      ; no: the next one
  JR BlastArea            ; no base in reach: only the area around is hit
BlastHitBase:
  POP HL                  ; the base's +3 off the stack
  LD A,C                  ; A = its index
  CP $04                  ; a warbase (0-3)?
  JR NC,BlastHitFactory   ; no: a factory
  CALL DestroyWarbase     ; a warbase: its buildings removed, its blocks turned
                          ; to debris
  JR BlastArea            ; on to the area
BlastHitFactory:
  SUB $04                 ; the factory's index 0-23
  CALL DestroyFactory     ; the factory: its buildings removed, its blocks
                          ; turned to debris
BlastArea:
  LD L,(IY+$00)           ; a round area of 9 x 9 cells centred on the robot
  LD H,(IY+$01)           ; HL = the robot's cell (+$00/+$01)
  PUSH IY                 ; keep the blasting robot's record (FindRobot moves
                          ; IY)
  LD DE,Map+6908             ; HL = the robot's cell 4 rows up and 4 columns left
  ADD HL,DE               ; HL = the area's top left cell
  LD BC,$0909             ; C = 9 rows, B = 9 cells a row
BlastRow:
  PUSH BC                 ; keep the row counters
  PUSH HL                 ; keep the row's first cell
  LD A,H                  ; only rows 1-15 (H $DF-$FC): row 0 and rows off the
                          ; map are skipped
  CP $DF                  ; above row 1 ($DF00)?
  JR C,BlastNextRow       ; skip the row
  CP $FD                  ; past row 15?
  JR NC,BlastNextRow      ; skip the row
  LD A,C                  ; round the corners: the first and last rows skip 2
                          ; cells at each side (5 cells), the second and eighth
                          ; skip 1 (7 cells)
  CP $01                  ; the last row (C counts 9 down to 1)?
  JR Z,BlastSkip2         ; 5 cells
  CP $02                  ; the eighth row?
  JR Z,BlastSkip1         ; 7 cells
  CP $08                  ; the second row?
  JR Z,BlastSkip1         ; 7 cells
  CP $09                  ; the first row?
  JR NZ,BlastCell         ; else all 9 cells
BlastSkip2:
  INC HL                  ; one cell right
  DEC B                   ; ...
  DEC B                   ; ... and two cells fewer (B - 2)
BlastSkip1:
  INC HL                  ; one cell right
  DEC B                   ; ...
  DEC B                   ; ... and two cells fewer
BlastCell:
  PUSH BC                 ; keep the cell counter B (FindRobot and PutBlock use
                          ; BC)
  LD A,(HL)               ; the cell
  BIT 6,A                 ; bit 6 and a robot on the cell: the robot is
                          ; destroyed (record freed, bit 6 cleared; a
                          ; building's bit 6 stays
  JR Z,BlastScenery       ; no anchor: only the scenery
  CALL FindRobot          ; a robot anchored here? (IY = it)
  JR NZ,BlastScenery      ; a building or a shot: only the scenery
  LD (IY+$01),$00         ; the robot's slot freed: it is gone at once, no
                          ; dying blink
  RES 6,(HL)              ; its anchor bit off the map
BlastScenery:
  LD A,(HL)               ; the first cell (bit 5 clear) of a block of tiles
                          ; $11-$14...
  BIT 5,A                 ; a block's other cell (bit 5)?
  JR NZ,BlastNextCell     ; yes: only the anchor cell turns a block
  AND $1F                 ; the block type
  CP $11                  ; below $11?
  JR C,BlastNextCell      ; not a breakable block
  CP $15                  ; $15 or more?
  JR NC,BlastNextCell     ; not a breakable block
  CALL Random             ; ... becomes a block of debris, tile 6 or 7 at
                          ; random
  AND $01                 ; 0 or 1
  ADD A,$06               ; tile 6 or 7
  CALL PutBlock           ; the 2 x 2 debris block
BlastNextCell:
  POP BC                  ; B = the cells left in the row
  INC HL                  ; the next cell
  DJNZ BlastCell          ; the rest of the row
BlastNextRow:
  POP HL                  ; the row below
  INC H                   ; one map row is $200...
  INC H                   ; ... bytes
  POP BC                  ; the row counters back
  DEC C                   ; one row less
  JR NZ,BlastRow          ; all 9 rows
  CALL ShipCell           ; the ship's cell keeps its bit 7 (the debris blocks
                          ; may have cleared it)
  SET 7,(HL)              ; the ship's mark again
  CALL DrawView           ; redraw the view
  POP IY                  ; IY = the blasting robot again
  LD (IY+$01),$00         ; the robot itself is gone
  CALL NuclearFlash       ; flash the view with the rumble
  LD A,$01                ; the radar map must be rebuilt
  LD (RadarDirty),A            ; RadarDirty = 1
  CALL CountRobots        ; recount the robots and the bases, redraw the status
                          ; panel
  CALL CountBases         ; the bases, some may be destroyed
  JP UpdateStatusPanel    ; the panel, return from there

; The nuclear blast's flash: the view's paper flickers through random colours
; with a fading rumble
;
; Called only by the blast ($BA76). Saves the 20 x 20 attributes of the view
; (from $5821, row 1 column 1) to $5B00-$5C8F, then 61 times: a burst of noise
; ($BAEE, 244 samples first, 4 fewer and a longer delay each time) and a new
; random paper colour (2-7, never the previous one) on every attribute of the
; view whose paper is not black. Restores the saved attributes at the end. The
; flash lasts 216 frames (4.3 s, measured; the game stands still meanwhile.
;
; $5B00 is free scratch at that time (the printer buffer and above, also the
; save checksum of $C2E8).
NuclearFlash:
  LD DE,ViewBuffer             ; copy the view's attributes to $5B00
  LD HL,$5821             ; the view's attributes, row 1 column 1
  LD BC,$1414             ; C = 20 rows, B = 20 columns
FlashSaveRow:
  PUSH BC                 ; keep the row counters
FlashSaveCell:
  LDI                     ; LDI counts BC down: INC C keeps B the column
                          ; counter
  INC C                   ; (LDI took one from C)
  DJNZ FlashSaveCell      ; the 20 attributes of the row
  LD A,$0C                ; the next attribute row: 32 - 20
  CALL AddAToHL           ; HL = the next row's first attribute
  POP BC                  ; the counters back
  DEC C                   ; one row less
  JR NZ,FlashSaveRow      ; all 20 rows
  LD BC,Map+5889             ; B = 244 samples, C = 1: the noise's length and
                          ; delay
FlashLoop:
  CALL NuclearRumble      ; one flash: noise, then the colours
  PUSH BC                 ; keep the burst's length and delay
  LD HL,$5821             ; the view's first attribute
  LD BC,$1414             ; C = 20 rows, B = 20 columns
FlashPickPaper:
  CALL Random             ; a random paper (bits 3-5) of colour 2 or more, not
                          ; the previous one (E)
  AND $38                 ; the paper bits
  CP $10                  ; paper 0 or 1 (black, blue)?
  JR C,FlashPickPaper     ; too dark: another
  CP E                    ; the paper of the last flash?
  JR Z,FlashPickPaper     ; the same: another
  LD E,A                  ; E = this flash's paper
FlashRow:
  PUSH BC                 ; keep the row counters
FlashCell:
  LD A,(HL)               ; repaint the paper of every attribute whose paper is
                          ; not black
  AND $38                 ; its paper
  JR Z,FlashNextCell      ; black (the view's empty ground): kept
  LD A,(HL)               ; the attribute again
  AND $C7                 ; ink, bright and flash kept
  OR E                    ; the new paper
  LD (HL),A               ; store it
FlashNextCell:
  INC HL                  ; the next attribute
  DJNZ FlashCell          ; the 20 columns
  LD A,$0C                ; 32 - 20
  CALL AddAToHL           ; HL = the next row's first attribute
  POP BC                  ; the row counters back
  DEC C                   ; one row less
  JR NZ,FlashRow          ; all 20 rows
  POP BC                  ; B, C = the next burst's length and delay
  DJNZ FlashLoop          ; B fell by 3 in $BAEE and 1 here: 61 flashes
  LD HL,ViewBuffer             ; put the attributes back
  LD DE,$5821             ; the view's first attribute
  LD BC,$1414             ; 20 rows of 20
RestoreRow:
  PUSH BC                 ; keep the row counters
RestoreCell:
  LDI                     ; one attribute back
  INC C                   ; (LDI took one from C)
  DJNZ RestoreCell        ; the 20 attributes of the row
  LD A,$0C                ; 32 - 20...
  ADD A,E                 ; ... added to DE
  LD E,A                  ; E = the low byte
  JR NC,RestoreNextRow    ; no carry: the same third
  INC D                   ; carry into D
RestoreNextRow:
  POP BC                  ; the counters back
  DEC C                   ; one row less
  JR NZ,RestoreRow        ; all 20 rows
  RET                     ; the view's colours are back

; One burst of the blast's noise: B samples of ROM bytes to the speaker, C the
; delay between
;
; Plays B samples: bit 4 (the speaker) of the ROM bytes from $0090 on, the
; border black, with a delay loop of C x 24 T-states after each. Returns B - 3
; and C + 3, so the next burst of NuclearFlash is shorter and lower: a dying
; rumble. Only NuclearFlash calls it.
NuclearRumble:
  PUSH BC                 ; keep the burst's length and delay
  LD HL,$0090             ; the ROM bytes as noise
RumbleSample:
  PUSH BC                 ; bit 4 to the speaker, border 0
  LD A,(HL)               ; the ROM byte
  AND $10                 ; its bit 4: the speaker; border bits 0-2 = 0
  OUT ($FE),A             ; to the ULA
  INC HL                  ; the next ROM byte
RumbleDelay:
  DEC C                   ; C counts the delay (C = 0 at the start of a later
                          ; sample: 256 loops)
  NOP                     ; padding of the delay
  NOP                     ; padding of the delay
  JR NZ,RumbleDelay       ; until C is 0
  POP BC                  ; B, C back
  DJNZ RumbleSample       ; B samples
  POP BC                  ; the next burst: 3 samples fewer, a longer delay
  DEC B                   ; B - 3...
  DEC B                   ; ...
  DEC B                   ; ... a shorter burst
  INC C                   ; C + 3...
  INC C                   ; ...
  INC C                   ; ... a longer delay, a lower sound
  RET                     ; back to NuclearFlash
