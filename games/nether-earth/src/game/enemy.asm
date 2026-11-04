; once a game turn the computer looks at one of its 24 robot slots: builds a
; robot in a free one or re-thinks a robot's order
;
; Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a
; quarter of the turns) do nothing. Side = 1. The slot's record is $DB80 + 16 *
; n. A live robot goes to EnemyReplan (outside this range): one with order 0 at
; once, any other with a 1/32 chance a turn, gets a new order (a nuclear robot
; destroy factories or warbases, the others one of the capture orders; destroy
; robots when the order finds no target). A free slot tries a build at a random
; enemy warbase (owner $20 in the Warbases table): random parts (exactly one
; locomotion, at least one and not all four of the weapon / nuclear parts, at
; least 1, 2 or 3 of those parts while the computer has 0-7, 8-15 or 16-23
; robots, EnemyRobots $FD49), paid from EnemyResources ($FD4A, through
; MenuResources and PartCosts like the player's), the shortfall of the other
; resources taken from the general one, at most half of it (at least 11); the
; robot is set up facing down, order stop, strength $64, +$0A = $80, height
; +$09 the sum of the part heights $D7B4 (bipod 11, tracks 7, anti-grav 8,
; cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7). 3415 calls.
EnemyCommander:
  CALL Random             ; a random slot ...
  AND $1F
  CP $18                  ; ... of the computer's 24, or none this turn
  RET NC
  ADD A,A                 ; * 16: the record's offset from $DB80
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00                ; HL = slot * 16 (A = slot * 8)
  ADD HL,HL
  LD DE,EnemyRobots       ; the enemy's records begin at slot 24, $DB80
  ADD HL,DE
  PUSH HL
  POP IY
  LD A,$01                ; ActingSide = 1: the target searches ($B3D5, $B36C)
                          ; look from the enemy's side
  LD (Side),A
  LD A,(IY+$01)           ; a live robot in the slot: re-plan its order instead
  OR A
  JP NZ,EnemyReplan
  LD B,$04                ; a free slot: try to build a robot, four tries over
                          ; the four warbases
  LD HL,Warbases+3             ; the owner byte (+3) of warbase 0 in the bases table
                          ; $FD70
SpawnPickBase:
  CALL Random             ; each warbase in turn is taken with chance 1/2
  AND $01
  JR Z,SpawnNextBase
  LD A,(HL)               ; and only if its +3 is $20 exactly: the enemy's, not
                          ; destroyed
  CP $20
  JR Z,SpawnAtBase
SpawnNextBase:
  LD A,$05                ; the next 5-byte base record
  CALL AddAToHL
  DJNZ SpawnPickBase
  RET                     ; no warbase taken: no robot this turn
SpawnAtBase:
  DEC HL                  ; B = the warbase's y, HL = its x: the door cell the
                          ; robot appears on
  LD B,(HL)
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  LD A,B
  PUSH HL                 ; x to HL' and y to B' for the placing at $B8D9
  EXX
  POP HL
  LD B,A
  EXX
  CALL MapCell            ; HL = the door's map cell
  PUSH HL                 ; the door and the three cells in front of it (row
                          ; y+1, x-1 to x+1) must hold no robot or building
                          ; (bit 6)
  LD A,(HL)
  INC H
  INC H
  OR (HL)
  DEC HL
  OR (HL)
  INC HL
  INC HL
  OR (HL)
  AND $40
  POP HL
  RET NZ                  ; blocked: wait for another turn
  CALL Random             ; the parts: a random mask (the second of two draws)
  CALL Random
  LD C,A
  LD (IY+$07),A
  AND $07                 ; the chassis bits 0-2: exactly one of bipod, tracks,
                          ; anti-grav
  CP $01
  JR Z,SpawnCheckWeapons
  CP $02
  JR Z,SpawnCheckWeapons
  CP $04
  RET NZ                  ; none or two chassis: no robot
SpawnCheckWeapons:
  LD A,C                  ; C = the weapons, bits 3-6 (cannon, missiles,
                          ; phasers, nuclear)
  RRCA
  RRCA
  RRCA
  AND $0F
  RET Z                   ; no weapon: no robot
  CP $0F
  RET Z                   ; all four weapons: no robot
  LD C,A
  LD A,(EnemyRobotCount)            ; B = EnemyRobots / 8 + 1: 1 below 8 robots, 2 from
                          ; 8, 3 from 16
  RRCA
  RRCA
  RRCA
  INC A
  AND $03
  LD B,A
  CALL CountDirections    ; A = the number of weapons ($B505)
  CP B
  RET C                   ; fewer weapons than B: no robot (a bigger army
                          ; builds only better-armed robots)
  LD HL,EnemyResources             ; spend on a copy: the enemy's resources into
                          ; MenuResources
  LD DE,MenuResources
  LD BC,$0007
  LDIR
  LD C,(IY+$07)           ; D: the shortfall the general resource has to cover
  LD D,$00
  LD B,$08
SpawnPayPart:
  RRC C                   ; for each part in the mask, bipod first
  JR NC,SpawnNextPart
  LD A,$08                ; A = the part's index 0-7
  SUB B
  PUSH AF
  LD HL,PartCosts         ; E = its cost (PartCosts)
  CALL AddAToHL
  LD E,(HL)
  POP AF
  LD HL,PartCosts+$0008   ; the resource it takes first (PartCosts + 8)
  CALL AddAToHL
  LD A,(HL)
  LD HL,MenuResources
  CALL AddAToHL
  LD A,(HL)
  SUB E                   ; pay from that resource
  JP P,SpawnStoreResource
  NEG                     ; not enough: the rest joins the shortfall, the
                          ; resource drops to 0
  ADD A,D
  LD D,A
  XOR A
SpawnStoreResource:
  LD (HL),A               ; the resource's new value
SpawnNextPart:
  DJNZ SpawnPayPart
  LD HL,MenuResources             ; the general resource may cover a shortfall up to
                          ; max(general / 2, 11)
  LD A,(HL)
  SRL A
  CP $0B
  JR NC,SpawnCheckGeneral
  LD A,$0B
SpawnCheckGeneral:
  CP D
  RET C                   ; the shortfall is too big: no robot, nothing spent
  LD A,(HL)
  SUB D
  RET M                   ; the general resource cannot pay it: no robot
  LD (HL),A
  LD DE,EnemyResources             ; commit: the copy back to the enemy's resources
                          ; $FD4A
  LD BC,$0007
  LDIR
  LD (IY+$0A),$80         ; +$0A = $80: an enemy robot
  EXX
  CALL PlaceRobot         ; place it on the door (x in HL', y in B'): +2 to +4,
                          ; the cell +0/+1, map bit 6, the radar dot
  EXX
  LD (IY+$05),$04         ; the start values; the player's robots get the same
                          ; at $A6F3, except +6 = 5 there
  LD (IY+$08),$04
  LD (IY+$06),$03
  LD (IY+$0D),$00
  LD (IY+$0B),$00         ; order 0: the next visit of this slot chooses one
  LD (IY+$0F),$01
  LD (IY+$0C),$64         ; +$0C = 100 (the strength a new robot starts with)
  LD (IY+$0E),$FF         ; no target yet
  LD C,(IY+$07)           ; the height +9: the sum of the parts' heights
  LD B,$08
  LD D,$00
SpawnHeightLoop:
  RRC C
  JR NC,SpawnHeightNext
  LD A,$08
  SUB B
  LD HL,PartHeights       ; the part heights at $D7B4: bipod 11, tracks 7,
                          ; anti-grav 8, cannon 6, missiles 6, phasers 7,
                          ; nuclear 7, electronics 7
  CALL AddAToHL
  LD A,(HL)
  ADD A,D
  LD D,A
SpawnHeightNext:
  DJNZ SpawnHeightLoop
  LD (IY+$09),D
  CALL CountRobots        ; recount the robots, redraw the status panel
  CALL UpdateStatusPanel
  RET
EnemyReplan:
  LD A,(IY+$0B)           ; a live enemy robot: order 0 is replaced at once
  OR A
  JR Z,EnemyChooseOrder
  LD B,A
  CALL Random             ; any other order is reconsidered once in 32 turns
  AND $1F
  RET NZ
  LD A,B
  CP $04                  ; orders 1-3 (advance, retreat, destroy robots):
                          ; choose anew
  JR C,EnemyChooseOrder
  LD A,(IY+$0B)           ; orders 4-8: HL = the target table's +3 bytes, E =
                          ; the owner bits the order looks for ($B3D5)
  CALL TargetBuildingTable
  LD A,(IY+$0E)           ; HL = the target's +3 byte (+$0E = the target's
                          ; index)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL AddAToHL
  LD A,(HL)               ; the target still has the owner the order looks for:
                          ; choose anew (again the nearest)
  AND $E0
  CP E
  JR Z,EnemyChooseOrder
  DEC HL                  ; the target changed hands (or was destroyed): keep
                          ; the order only while the robot stands on its door
  LD A,(IY+$04)
  SUB (HL)
  JR NZ,EnemyChooseOrder
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE
  RET Z                   ; on the target's door: keep the order
EnemyChooseOrder:
  LD (IY+$0B),$03         ; 3 (destroy robots) unless a target is found below
  BIT 6,(IY+$07)          ; with nuclear: a demolition order
  JR Z,EnemyCaptureOrder
  CALL Random             ; 5 (destroy warbases) with chance 3/4 (bit 0 or bit
                          ; 7 set), else 4 (destroy factories)
  LD B,A
  RLCA
  OR B
  AND $01
  ADD A,$04
  LD (IY+$0B),A
  JR EnemyFindTarget
EnemyCaptureOrder:
  LD C,$00                ; without nuclear: a capture order
  CALL Random
  RRCA                    ; bit 0: 6 (capture neutral factories, 1/2), bit 1: 7
                          ; (the player's factories, 1/4), else 8 (the player's
                          ; warbases, 1/4)
  JR C,EnemySetCapture
  INC C
  RRCA
  JR C,EnemySetCapture
  INC C
EnemySetCapture:
  LD A,C
  ADD A,$06
  LD (IY+$0B),A
EnemyFindTarget:
  LD L,(IY+$02)           ; the nearest target of the order from the robot's x
                          ; ($B34D): D its index, $FF none
  LD H,(IY+$03)
  LD (IY+$0E),$FF
  CALL FindTargetBuilding
  LD (IY+$0E),D
  RET NZ                  ; found: keep the order
  LD (IY+$0B),$03         ; no such target: destroy robots
  RET

; NuclearBlast
;
; Used by the routines at CombatMenuCode and SteerByOrder.
NuclearBlast:
  LD HL,Warbases+3             ; a robot with order 4 or 5 has reached its target
                          ; (no step left): it detonates. IY = the robot
  LD C,$00                ; C = the base index 0-27 (0-3 warbases); D = the
                          ; reach in rows and in columns, E = in rows +
                          ; columns: 7, 10
  LD DE,$070A
BlastBaseLoop:
  PUSH HL
  BIT 7,(HL)              ; a destroyed base (bit 7) is skipped
  JR NZ,BlastNextBase
  DEC HL
  LD A,C
  CP $04
  LD A,(IY+$04)           ; A = the robot's y, + 4 for a warbase
  JR NC,BlastRowDistance
  ADD A,$04
BlastRowDistance:
  INC A                   ; dy = |robot y + 5 - y| for a warbase, |robot y + 1
                          ; - y| for a factory
  SUB (HL)
  JP P,BlastCheckRow
  NEG
BlastCheckRow:
  LD B,A
  CP D
  JR NC,BlastNextBase     ; dy out of reach
  PUSH DE
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL ColumnDistance     ; HL = dx = |robot x - base x| ($B3CA)
  POP DE
  LD A,H
  OR A
  JR NZ,BlastNextBase     ; dx of 256 or more
  LD A,L
  CP D
  JR NC,BlastNextBase     ; dx out of reach
  ADD A,B                 ; dx + dy
  CP E
  JR C,BlastHitBase       ; inside: the first base found in reach goes
BlastNextBase:
  POP HL
  LD A,$05
  CALL AddAToHL
  INC C
  LD A,C
  CP $04
  JR C,BlastBaseLoop
  LD DE,$0507             ; from base 4 on, the factories: reach 5, sum 7
  CP $1C
  JR C,BlastBaseLoop
  JR BlastArea            ; no base in reach: only the area around is hit
BlastHitBase:
  POP HL
  LD A,C
  CP $04
  JR NC,BlastHitFactory
  CALL DestroyWarbase     ; a warbase: its buildings removed, its blocks turned
                          ; to debris
  JR BlastArea
BlastHitFactory:
  SUB $04                 ; the factory's index 0-23
  CALL DestroyFactory
BlastArea:
  LD L,(IY+$00)           ; a round area of 9 x 9 cells centred on the robot
  LD H,(IY+$01)
  PUSH IY
  LD DE,-$0804            ; HL = the robot's cell 4 rows up and 4 columns left
  ADD HL,DE
  LD BC,$0909             ; C = 9 rows, B = 9 cells a row
BlastRow:
  PUSH BC
  PUSH HL
  LD A,H                  ; only rows 1-15 (H $DF-$FC): row 0 and rows off the
                          ; map are skipped
  CP $DF
  JR C,BlastNextRow
  CP $FD
  JR NC,BlastNextRow
  LD A,C                  ; round the corners: the first and last rows skip 2
                          ; cells at each side (5 cells), the second and eighth
                          ; skip 1 (7 cells)
  CP $01
  JR Z,BlastSkip2
  CP $02
  JR Z,BlastSkip1
  CP $08
  JR Z,BlastSkip1
  CP $09
  JR NZ,BlastCell
BlastSkip2:
  INC HL
  DEC B
  DEC B
BlastSkip1:
  INC HL
  DEC B
  DEC B
BlastCell:
  PUSH BC
  LD A,(HL)
  BIT 6,A                 ; bit 6 and a robot on the cell: the robot is
                          ; destroyed (record freed, bit 6 cleared); a
                          ; building's bit 6 stays
  JR Z,BlastScenery
  CALL FindRobot
  JR NZ,BlastScenery
  LD (IY+$01),$00
  RES 6,(HL)
BlastScenery:
  LD A,(HL)               ; the first cell (bit 5 clear) of a block of tiles
                          ; $11-$14 ...
  BIT 5,A
  JR NZ,BlastNextCell
  AND $1F
  CP $11
  JR C,BlastNextCell
  CP $15
  JR NC,BlastNextCell
  CALL Random             ; ... becomes a block of debris, tile 6 or 7 at
                          ; random
  AND $01
  ADD A,$06
  CALL PutBlock
BlastNextCell:
  POP BC
  INC HL
  DJNZ BlastCell
BlastNextRow:
  POP HL                  ; the row below
  INC H
  INC H
  POP BC
  DEC C
  JR NZ,BlastRow
  CALL ShipCell           ; the ship's cell keeps its bit 7 (the debris blocks
                          ; may have cleared it)
  SET 7,(HL)
  CALL DrawView           ; redraw the view
  POP IY
  LD (IY+$01),$00         ; the robot itself is gone
  CALL NuclearFlash       ; flash the view with the rumble
  LD A,$01                ; the radar map must be rebuilt
  LD (RadarDirty),A
  CALL CountRobots        ; recount the robots and the bases, redraw the status
                          ; panel
  CALL CountBases
  JP UpdateStatusPanel

; The nuclear blast's flash: the view's paper flickers through random colours
; with a fading rumble
;
; Called only by the blast ($BA76). Saves the 20 x 20 attributes of the view
; (from $5821, row 1 column 1) to $5B00-$5C8F, then 61 times: a burst of noise
; ($BAEE, 244 samples first, 4 fewer and a longer delay each time) and a new
; random paper colour (2-7, never the previous one) on every attribute of the
; view whose paper is not black. Restores the saved attributes at the end. The
; noise takes about 3.3 s of beeper time in total; the game stands still
; meanwhile.
;
; Verified by an experiment (own instance, PC set to $B99F with a poked nuclear
; robot): the run passes here after the bases and robots are hit. $5B00 is free
; scratch at that time (the printer buffer and above, also the save checksum of
; $C2E8).
NuclearFlash:
  LD DE,ViewBuffer        ; copy the view's attributes to $5B00
  LD HL,$5821
  LD BC,$1414
FlashSaveRow:
  PUSH BC
FlashSaveCell:
  LDI                     ; LDI counts BC down: INC C keeps B the column
                          ; counter
  INC C
  DJNZ FlashSaveCell
  LD A,$0C                ; the next attribute row: 32 - 20
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,FlashSaveRow
  LD BC,$F401             ; B = 244 samples, C = 1: the noise's length and
                          ; delay
FlashLoop:
  CALL NuclearRumble      ; one flash: noise, then the colours
  PUSH BC
  LD HL,$5821
  LD BC,$1414
FlashPickPaper:
  CALL Random             ; a random paper (bits 3-5) of colour 2 or more, not
                          ; the previous one (E)
  AND $38
  CP $10
  JR C,FlashPickPaper
  CP E
  JR Z,FlashPickPaper
  LD E,A
FlashRow:
  PUSH BC
FlashCell:
  LD A,(HL)               ; repaint the paper of every attribute whose paper is
                          ; not black
  AND $38
  JR Z,FlashNextCell
  LD A,(HL)
  AND $C7
  OR E
  LD (HL),A
FlashNextCell:
  INC HL
  DJNZ FlashCell
  LD A,$0C
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,FlashRow
  POP BC
  DJNZ FlashLoop          ; B fell by 3 in $BAEE and 1 here: 61 flashes
  LD HL,ViewBuffer        ; put the attributes back
  LD DE,$5821
  LD BC,$1414
RestoreRow:
  PUSH BC
RestoreCell:
  LDI
  INC C
  DJNZ RestoreCell
  LD A,$0C
  ADD A,E
  LD E,A
  JR NC,RestoreNextRow
  INC D
RestoreNextRow:
  POP BC
  DEC C
  JR NZ,RestoreRow
  RET

; One burst of the blast's noise: B samples of ROM bytes to the speaker, C the
; delay between
;
; Plays B samples: bit 4 (the speaker) of the ROM bytes from $0090 on, the
; border black, with a delay loop of C x 24 T-states after each. Returns B - 3
; and C + 3, so the next burst of NuclearFlash is shorter and lower: a dying
; rumble. Only NuclearFlash calls it.
NuclearRumble:
  PUSH BC
  LD HL,$0090             ; the ROM bytes as noise
RumbleSample:
  PUSH BC                 ; bit 4 to the speaker, border 0
  LD A,(HL)
  AND $10
  OUT ($FE),A
  INC HL
RumbleDelay:
  DEC C
  NOP
  NOP
  JR NZ,RumbleDelay
  POP BC
  DJNZ RumbleSample
  POP BC                  ; the next burst: 3 samples fewer, a longer delay
  DEC B
  DEC B
  DEC B
  INC C
  INC C
  INC C
  RET
