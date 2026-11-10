; --------------------------------------------------------------------------------------------------------------------
; droid.asm: The droid: moving, the exits, the touch test, the pickups, the teleporter, the turn-round
;
; MoveDroid runs once a pass between MainLoop's two HALTs. It takes Controls, moves the droid by a column or two pixel
; rows, leaves the room at an edge, queues the old and new images for the interrupt's XOR, and tests what the droid's
; cells hold. The droid graphic is 3 bytes wide (2 for the front frames) and 40 rows high.
; --------------------------------------------------------------------------------------------------------------------

; One step of the droid: the teleporter, the fall, the controls, the exits, the
; sprites, the touch test, the pickups
;
; On the floor it acts every second pass (MoveDelay reloads 2); in the air
; (DroidFlags bit 2: no wall under the feet; the droid hovers and moves
; vertically only with up or down) every pass (L1 6 522 waits). A droid on a
; teleporter's $FF $FF cells with TeleportLatch 0 teleports (MoveDroidTeleport:
; L1 8 teleports). The cell under its feet (the cell 5 rows below, $A0 on)
; decides a fall: when it and the next one or two are not walls the droid is in
; the air (bit 2), else it stands (L1 15 289). The old image goes to the sprite
; list (DroidSave, flag pointer 0). Then, unless it is turning round (bit 1:
; TurnRound $7866), fire calls Fire $861C, and the directions move it: right
; (bit 0) and left (bit 1) a column a few frames apart through the walk frames
; 0-7 (DroidFrame 3, 4, 7, 8 step the x; StepBlockedLeft $76A1 /
; StepBlockedRight $76D1 undo a step into a wall); up and down two pixel rows
; (bit 3 up, bit 2 down, CellBlockedRow $7CF2 tests the wall). A direction
; against the facing starts the turn-round (frame 8). Down held alone while
; standing raises the shield (DroidFlags bit 4, FlagPointer $0000 so the touch
; test sees nothing, EnergyReload and EnergyTimer $0A); no control or another
; one lowers it (FlagPointer = DroidFlags again, the reload 250). The exits: x
; = $1D east (Room + 1, x = 0: L1 87), x = 0 west (Room - 1, x = $1D: 32), y =
; $98 south (Room + 8, y = $32: 26), y = $30 north (Room - 8, y = $96: 26);
; each saves the objects and calls DrawRoom with A = 0. Then the new frame
; (DroidFrames, DroidWidths) goes to the sprite list with FlagPointer, and the
; attributes under it are set to $45 where the cell is not a wall and holds no
; item. The touch test: when the interrupt found the droid's sprite on ink (bit
; 7 of DroidFlags), the cells under it are ORed (OrCells $7DAE into TouchBits):
; an enemy (bit 1) starts the fast drain (EnergyReload $0A, TouchTimer 50: L1
; 222); any other mark kills (HazardDeath: 309 tests reach it). Last the item
; test (FoundItem).
;
; Witness: L1 18 557 calls.
MoveDroid:
  LD A,(DroidFlags)
  BIT 2,A
  JR NZ,MoveDroidCell
  LD HL,MoveDelay
  DEC (HL)
  RET NZ
  LD (HL),$02
MoveDroidCell:
  LD HL,$0000
  LD (FoundItem),HL
  LD BC,(DroidVars)
  CALL CellAddr
  LD A,(HL)
  CP $FF
  JR NZ,MoveDroidNoTeleport
  INC L
  LD A,(HL)
  CP $FF
  JR NZ,MoveDroidNoTeleport
  LD A,(TeleportLatch)
  CP $00
  JP Z,Teleport
  JR MoveDroidFloor
MoveDroidNoTeleport:
  XOR A
  LD (TeleportLatch),A
MoveDroidFloor:
  LD DE,$00A0
  LD A,(DroidY)
  AND $07
  JR Z,MoveDroidFloorTest
  CP $07
  JR NZ,MoveDroidFloorTest
  LD DE,$00C0
MoveDroidFloorTest:
  LD BC,(DroidVars)
  CALL CellAddr
  ADD HL,DE
  LD A,H
  CP $6B
  JR NC,MoveDroidStand
  LD A,(HL)
  CP $01
  JR Z,MoveDroidStand
  INC L
  LD A,(HL)
  CP $01
  JR Z,MoveDroidStand
  LD A,(DroidWidth)
  CP $02
  JR Z,MoveDroidFall
  INC L
  LD A,(HL)
  CP $01
  JR Z,MoveDroidStand
MoveDroidFall:
  LD A,(DroidFlags)
  BIT 6,A
  JR NZ,MoveDroidFallSet
  LD A,$0B
  LD (DroidFrame),A
  LD A,(DroidFlags)
  SET 6,A
MoveDroidFallSet:
  BIT 2,A
  JR NZ,MoveDroidOldImage
  RES 6,A
  SET 2,A
  JR MoveDroidOldImage
MoveDroidStand:
  LD A,(DroidFlags)
  BIT 6,A
  JR NZ,MoveDroidStandSet
  BIT 4,A
  JR NZ,MoveDroidStandSet
  LD A,$02
  LD (DroidFrame),A
  LD A,(DroidFlags)
  SET 6,A
MoveDroidStandSet:
  BIT 2,A
  JR Z,MoveDroidOldImage
  RES 6,A
  RES 2,A
MoveDroidOldImage:
  LD (DroidFlags),A       ; the old image to the sprite list
  LD HL,(DroidGraphic)
  LD DE,DroidSave
  LD BC,$0078
  LDIR
  LD DE,DroidSave
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD A,(DroidWidth)
  LD (HL),A
  INC HL
  LD (HL),$05
  INC HL
  LD BC,(DroidVars)
  CALL ScreenAddr
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD HL,DroidFlags
  BIT 1,(HL)
  JP NZ,TurnRound
  LD A,(KeyLatches)
  BIT 7,A
  JR NZ,MoveDroidNoKeys
  LD A,(Controls)
  BIT 4,A
  JR Z,MoveDroidFireUp
  PUSH HL
  CALL Fire
  POP HL
  JR MoveDroidDirections
MoveDroidFireUp:
  LD A,(KeyLatches)
  RES 6,A
  LD (KeyLatches),A
MoveDroidDirections:
  LD A,(Controls)
  AND $03
  CP $03
  JR Z,MoveDroidNoKeys
  LD A,(Controls)
  AND $0F
  JR NZ,MoveDroidKeys
MoveDroidNoKeys:
  BIT 4,(HL)
  JR Z,MoveDroidStop
  RES 4,(HL)
  LD HL,DroidFlags
  LD (FlagPointer),HL
  LD A,$FA
  LD (EnergyTimer),A
  LD (EnergyReload),A
MoveDroidStop:
  BIT 3,(HL)
  JP Z,MoveDroidNewImage
  BIT 2,(HL)
  JR NZ,MoveDroidStopFall
  LD A,(DroidFrame)
  CP $02
  JR Z,MoveDroidStopFront
  CP $06
  JR NZ,MoveDroidRight
MoveDroidStopFront:
  RES 3,(HL)
  LD A,$08
  LD (DroidFrame),A
  BIT 0,(HL)
  JP NZ,MoveDroidNewImage
  LD HL,DroidVars
  INC (HL)
  JP MoveDroidNewImage
MoveDroidStopFall:
  RES 3,(HL)
  LD A,$0B
  LD (DroidFrame),A
  JP MoveDroidNewImage
MoveDroidKeys:
  LD (ControlsLatch),A
  BIT 2,(HL)
  JR NZ,MoveDroidUpDown
  CP $04
  JR NZ,MoveDroidUpDown
  BIT 4,(HL)
  JP NZ,MoveDroidNewImage
  SET 4,(HL)
  LD HL,$0000
  LD (FlagPointer),HL
  LD A,$0A
  LD (EnergyReload),A
  LD (EnergyTimer),A
  JP MoveDroidNewImage
MoveDroidUpDown:
  BIT 4,(HL)
  JR Z,MoveDroidMoving
  RES 4,(HL)
  LD HL,DroidFlags
  LD (FlagPointer),HL
  LD A,$FA
  LD (EnergyTimer),A
  LD (EnergyReload),A
  JP MoveDroidNewImage
MoveDroidMoving:
  BIT 3,(HL)
  JR NZ,MoveDroidRight
  SET 3,(HL)
  BIT 2,(HL)
  JR Z,MoveDroidStartWalk
  LD A,$0B
  LD (DroidFrame),A
  JR MoveDroidRight
MoveDroidStartWalk:
  LD A,$02
  LD (DroidFrame),A
  BIT 0,(HL)
  JR NZ,MoveDroidRight
  LD HL,DroidVars
  DEC (HL)
MoveDroidRight:
  LD A,(ControlsLatch)
  BIT 0,A
  JR Z,MoveDroidLeft
  LD HL,DroidFlags
  BIT 0,(HL)
  JR Z,MoveDroidWalkRight
  SET 1,(HL)
  LD A,$08
  LD (DroidFrame),A
  JP MoveDroidNewImage
MoveDroidWalkRight:
  LD HL,DroidVars
  LD A,(DroidFrame)
  INC A
  LD (DroidFrame),A
  CP $03
  JR NZ,MoveDroidRight4
  INC (HL)
  CALL StepBlockedRight
MoveDroidRight4:
  CP $04
  JR NZ,MoveDroidRight7
  INC (HL)
  CALL StepBlockedRight
MoveDroidRight7:
  CP $07
  JR NZ,MoveDroidRight8
  INC (HL)
  CALL StepBlockedRight
MoveDroidRight8:
  CP $08
  JR NZ,MoveDroidRight13
  INC (HL)
  CALL StepBlockedRight
  XOR A
  LD (DroidFrame),A
MoveDroidRight13:
  CP $0D
  JR NZ,MoveDroidEastExit
  INC (HL)
  LD A,$0B
  LD (DroidFrame),A
  CALL StepBlockedRight
MoveDroidEastExit:
  LD A,$1D                ; x = $1D: Room + 1
  LD HL,DroidVars
  CP (HL)
  JR NZ,MoveDroidLeftTest
  LD (HL),$00
  CALL SaveRoomObjects
  LD A,(Room)
  INC A
  LD (Room),A
  XOR A
  CALL DrawRoom
MoveDroidLeftTest:
  LD A,(ControlsLatch)
MoveDroidLeft:
  BIT 1,A
  JR Z,MoveDroidDown
  LD HL,DroidFlags
  BIT 0,(HL)
  JR NZ,MoveDroidWalkLeft
  SET 1,(HL)
  LD A,$08
  LD (DroidFrame),A
  BIT 2,(HL)
  JP NZ,MoveDroidNewImage
  LD HL,DroidVars
  INC (HL)
  JP MoveDroidNewImage
MoveDroidWalkLeft:
  LD HL,DroidVars
  LD A,(DroidFrame)
  INC A
  LD (DroidFrame),A
  CP $03
  JR NZ,MoveDroidLeft4
  DEC (HL)
  CALL StepBlockedLeft
MoveDroidLeft4:
  CP $04
  JR NZ,MoveDroidLeft7
  DEC (HL)
  CALL StepBlockedLeft
MoveDroidLeft7:
  CP $07
  JR NZ,MoveDroidLeft8
  DEC (HL)
  CALL StepBlockedLeft
MoveDroidLeft8:
  CP $08
  JR NZ,MoveDroidLeft13
  DEC (HL)
  CALL StepBlockedLeft
  XOR A
  LD (DroidFrame),A
MoveDroidLeft13:
  CP $0D
  JR NZ,MoveDroidWestExit
  DEC (HL)
  LD A,$0B
  LD (DroidFrame),A
  CALL StepBlockedLeft
MoveDroidWestExit:
  LD A,$00                ; x = 0: Room - 1
  LD HL,DroidVars
  CP (HL)
  JR NZ,MoveDroidDownTest
  LD (HL),$1D
  CALL SaveRoomObjects
  LD A,(Room)
  DEC A
  LD (Room),A
  XOR A
  CALL DrawRoom
MoveDroidDownTest:
  LD A,(ControlsLatch)
MoveDroidDown:
  BIT 2,A
  JR Z,MoveDroidUp
  LD BC,(DroidVars)
  LD A,(DroidY)
  AND $07
  JR Z,MoveDroidDownCell
  CP $07
  JR NZ,MoveDroidSouthExit
  INC B
MoveDroidDownCell:
  CALL CellAddr
  LD DE,$00A0
  ADD HL,DE
  LD A,H
  CP $6B
  JR NC,MoveDroidSouthExit
  LD A,$02
  LD DE,$0001
  CALL CellBlockedRow
  CP $00
  JR NZ,MoveDroidUpTest
MoveDroidSouthExit:
  LD HL,DroidY            ; y = $98: Room + 8
  LD A,$98
  INC (HL)
  INC (HL)
  CP (HL)
  JR NZ,MoveDroidUpTest
  LD (HL),$32
  CALL SaveRoomObjects
  LD A,(Room)
  ADD A,$08
  LD (Room),A
  XOR A
  CALL DrawRoom
MoveDroidUpTest:
  LD A,(ControlsLatch)
MoveDroidUp:
  BIT 3,A
  JR Z,MoveDroidNewImage
  LD A,(DroidY)
  AND $07
  JR Z,MoveDroidUpCell
  CP $01
  JR NZ,MoveDroidNorthExit
MoveDroidUpCell:
  LD BC,(DroidVars)
  CALL CellAddr
  LD DE,$0020
  SCF
  CCF
  SBC HL,DE
  LD A,H
  CP $60
  JR NZ,MoveDroidUpBlocked
  LD A,L
  CP $C0
  JR C,MoveDroidNorthExit
MoveDroidUpBlocked:
  LD A,$02
  LD DE,$0001
  CALL CellBlockedRow
  CP $00
  JR NZ,MoveDroidNewImage
MoveDroidNorthExit:
  LD HL,DroidY            ; y = $30: Room - 8
  LD A,$30
  DEC (HL)
  DEC (HL)
  CP (HL)
  JR NZ,MoveDroidNewImage
  LD (HL),$96
  CALL SaveRoomObjects
  LD A,(Room)
  SUB $08
  LD (Room),A
  XOR A
  CALL DrawRoom
; This entry point is used by the routine at TurnRound.
MoveDroidNewImage:
  LD A,(DroidFrame)       ; the frame to the sprite list
  LD HL,DroidWidths
  LD D,$00
  LD E,A
  ADD HL,DE
  LD C,(HL)
  SLA E
  LD HL,DroidFrames
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (DroidGraphic),DE
  LD A,C
  LD (DroidWidth),A
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD DE,(FlagPointer)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),C
  INC HL
  LD (HL),$05
  INC HL
  LD BC,(DroidVars)
  CALL ScreenAddr
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD A,B
  AND $07
  LD B,$05
  JR Z,MoveDroidAttrs
  INC B
MoveDroidAttrs:
  LD A,(DroidWidth)
  LD C,A
  PUSH BC
  PUSH HL
  LD A,H
  XOR $38
  LD D,A
  LD E,L
MoveDroidAttrRow:
  PUSH BC
  PUSH DE
  PUSH HL
  LD B,C
MoveDroidAttrCell:
  LD A,(DE)
  CP $FF
  JR Z,MoveDroidAttrSet
  BIT 7,A
  JR NZ,MoveDroidAttrNext
  CP $01
  JR Z,MoveDroidAttrNext
MoveDroidAttrSet:
  LD (HL),$45
MoveDroidAttrNext:
  INC L
  INC E
  DJNZ MoveDroidAttrCell
  POP HL
  POP DE
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,MoveDroidAttrRowNext
  INC H
MoveDroidAttrRowNext:
  LD A,E
  ADD A,$20
  LD E,A
  JR NC,MoveDroidAttrRowDone
  INC D
MoveDroidAttrRowDone:
  POP BC
  DJNZ MoveDroidAttrRow
  POP HL
  POP BC
MoveDroidTouch:
  LD A,(DroidFlags)       ; the touch test
  BIT 7,A
  JR Z,MoveDroidPickup
  RES 7,A
  LD (DroidFlags),A
  LD A,H
  AND $03
  OR $60
  LD H,A
  LD DE,TouchBits
  XOR A
  LD (DE),A
  CALL OrCells
  LD A,(DE)
  BIT 1,A
  JR Z,MoveDroidHazard
  LD A,$0A
  LD (EnergyReload),A
  LD (EnergyTimer),A
  LD A,$32
  LD (TouchTimer),A
  JR MoveDroidPickup
MoveDroidHazard:
  AND $FD
  JP NZ,HazardDeath
MoveDroidPickup:
  LD HL,(FoundItem)       ; an item under the droid
  LD A,H
  OR L
  RET Z
  LD A,(HL)
  CP $FF
  RET Z
  LD (DrawMode),A
  LD A,(Room)
  LD HL,AlienMap
  LD D,$00
  LD E,A
  SLA E
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,AlienMap
  ADD HL,DE
  LD B,(HL)
  INC HL
  LD A,(DrawMode)
  CP (HL)
  JR Z,MoveDroidPickupFound
  INC HL
  LD B,(HL)
  INC HL
MoveDroidPickupFound:
  RES 7,(HL)
  LD A,B
  LD HL,CellTable
  CALL ItemCell
  CALL CellToScreen
  PUSH DE
  LD DE,$001F
  LD (HL),$00
  INC L
  LD (HL),$00
  ADD HL,DE
  LD (HL),$00
  INC L
  LD (HL),$00
  POP DE
  CALL PickupErase
  LD A,(DrawMode)
  CP $80
  JR Z,MoveDroidPickupGen
  CP $81
  JR Z,MoveDroidPickupEnergy
  BIT 6,A
  JP Z,EdPickup
  AND $3F
  CP $01
  JR NZ,MoveDroidPickupWeapon2
  LD A,(Ammo)
  ADD A,$01
  DAA
  LD (Ammo),A
  JR MoveDroidPickupStored
MoveDroidPickupWeapon2:
  CP $02
  JR NZ,MoveDroidPickupWeapon3
  LD A,(Ammo+$0001)
  ADD A,$01
  DAA
  LD (Ammo+$0001),A
  JR MoveDroidPickupStored
MoveDroidPickupWeapon3:
  LD A,(Ammo+$0002)
  ADD A,$01
  DAA
  LD (Ammo+$0002),A
MoveDroidPickupStored:
  CALL ShowWeapon
  LD HL,MsgWeaponStored
  CALL QueueMessage
  RET
MoveDroidPickupGen:
  LD HL,MsgGenCollected   ; GEN 19: a life
  CALL QueueMessage
  LD A,(Lives)
  ADD A,$01
  DAA
  LD (Lives),A
  LD HL,Screen+133
  CALL PrintBcd
  RET
MoveDroidPickupEnergy:
  LD HL,MsgEnergyAbsorbed ; an energy source: energy 99
  CALL QueueMessage
  LD A,(EnergyReload)
  LD B,A
  LD A,$99
  LD (Energy),A
  LD HL,EnergyTimer
  LD (HL),B
  LD HL,Screen+136
  CALL PrintBcd
  RET

; Undo a step left into a wall
;
; In: HL DroidX after the step. When the column left of the droid holds a wall
; over its 5 rows (CellBlockedColumn $7CBB), x goes back and the frame back one
; (L1 1 426 tests, 246 undone).
StepBlockedLeft:
  PUSH AF
  PUSH HL
  LD BC,(DroidVars)
  CALL CellAddr
  LD A,L
  AND $1F
  CP $00
  JR Z,StepBlockedLeftClear
  LD A,$05
  LD DE,DroidY
  CALL CellBlockedColumn
  CP $00
  JR Z,StepBlockedLeftClear
  POP HL
  INC (HL)
  LD A,(DroidFrame)
  CP $0B
  JR NZ,StepBlockedLeftFrame
  LD A,$0D
StepBlockedLeftFrame:
  DEC A
  LD (DroidFrame),A
  JR StepBlockedLeftDone
StepBlockedLeftClear:
  POP HL
StepBlockedLeftDone:
  POP AF
  RET

; Undo a step right into a wall
;
; The same on the right, the column x + 2 (L1 1 742 tests, 373 undone).
StepBlockedRight:
  PUSH AF
  PUSH HL
  LD BC,(DroidVars)
  CALL CellAddr
  LD A,L
  AND $1F
  CP $1D
  JR Z,StepBlockedRightClear
  INC L
  INC L
  LD A,$05
  LD DE,DroidY
  CALL CellBlockedColumn
  CP $00
  JR Z,StepBlockedRightClear
  POP HL
  DEC (HL)
  LD A,(DroidFrame)
  CP $0B
  JR NZ,StepBlockedRightFrame
  LD A,$0D
StepBlockedRightFrame:
  DEC A
  LD (DroidFrame),A
  JR StepBlockedRightDone
StepBlockedRightClear:
  POP HL
StepBlockedRightDone:
  POP AF
  RET

; An ED piece taken: the progress screen, then the room again
;
; In: A the item's kind ($82-$B3). ProgressScreen $8F53 with A = the piece
; number (it sets the piece's EdFlags bit and shows the picture), DroidGraphic
; = BlankGraphic, SaveRoomObjects, DrawRoom with A = $FF. L1 35 pieces (the win
; recording holds the last).
EdPickup:
  RES 7,A
  DEC A
  CALL ProgressScreen
  LD DE,BlankGraphic
  LD (DroidGraphic),DE
  CALL SaveRoomObjects
  LD A,$FF
  CALL DrawRoom
  RET

; Through the teleporter: the beam, TRANSPORTING, the target room
;
; The droid's image is replaced by the beam frame ($A0A0, frame 10) in the
; sprite list, one HALT; TRANSPORTING; BeamDown $7F9C (a falling tone),
; TeleportFlash $8051; SaveRoomObjects; Room = TeleportRoom; DrawRoom; BeamDown
; with a rising start; the droid placed at TeleportColumn + 1, TeleportRow, the
; beam frame with attribute $45; BeamUp $8005; TeleportLatch = $FF so it does
; not teleport straight back. L1 8.
Teleport:
  LD DE,(DroidGraphic)
  LD A,(DroidWidth)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$05
  INC HL
  LD BC,(DroidVars)
  CALL ScreenAddr
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD DE,DroidFront
  LD (DroidGraphic),DE
  LD A,$0A
  LD (DroidFrame),A
  LD A,$02
  LD (DroidWidth),A
  LD A,(DroidFlags)
  AND $01
  SET 6,A
  LD (DroidFlags),A
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$02
  INC HL
  LD (HL),$05
  INC HL
  LD BC,(DroidVars)
  CALL ScreenAddr
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  EI
  HALT
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD HL,MsgTransporting
  CALL QueueMessage
  LD DE,$1388
  LD (BeamScreen),DE
  CALL BeamDown
  CALL TeleportFlash
  CALL SaveRoomObjects
  LD A,(TeleportRoom)
  LD (Room),A
  DI
  CALL DrawRoom
  LD DE,$0001
  LD (BeamScreen),DE
  CALL BeamDown
  LD BC,(TeleportColumn)
  INC C
  LD (DroidVars),BC
  LD DE,DroidFront
  LD (DroidGraphic),DE
  LD A,$0A
  LD (DroidFrame),A
  LD A,$02
  LD (DroidWidth),A
  LD A,(DroidFlags)
  AND $01
  SET 6,A
  LD (DroidFlags),A
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$02
  INC HL
  LD (HL),$05
  INC HL
  CALL ScreenAddr
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD L,E
  LD A,B
  AND $07
  LD B,$05
  JR Z,TeleportArrive
  INC B
TeleportArrive:
  LD A,(DroidWidth)
  LD C,A
  LD A,$45
  CALL FillAttr
  EI
  NOP
  HALT
  DI
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  EI
  LD DE,$1388
  LD (BeamScreen),DE
  CALL BeamUp
  LD A,$FF
  LD (TeleportLatch),A
  DI
  RET

; Erase a taken item: the tone, then its 16 pixel rows
;
; In: DE the item's screen address. PickupTone, then 16 rows of two zero bytes.
; L1 50.
PickupErase:
  CALL PickupTone
  EX DE,HL
  LD B,$10
PickupEraseRow:
  LD (HL),$00
  INC L
  LD (HL),$00
  DEC L
  INC H
  LD A,H
  AND $07
  JR NZ,PickupEraseNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,PickupEraseNext
  LD A,H
  SUB $08
  LD H,A
PickupEraseNext:
  DJNZ PickupEraseRow
  RET

; The pickup's tone: 256 beeper toggles $21 loops apart
;
; L1 50 (12 859 toggles counted: one build stopped mid-tone).
PickupTone:
  XOR A
  LD B,$00
PickupToneLoop:
  PUSH BC
  OUT ($FE),A
  XOR $10
  LD B,$21
PickupToneDelay:
  DJNZ PickupToneDelay
  POP BC
  DJNZ PickupToneLoop
  RET

; One step of the turn-round: the next frame, and part of the droid's graphics
; mirrored in place
;
; TurnStep walks TurnSequence (8, 9, 10, 9, 8). At frame 10 (the droid seen
; from the front) the 2-byte front frames ($9C40 on, TurnGraphic) are mirrored
; 80 rows a step (TurnMirror2); at the other steps the 3-byte frames 160 rows a
; step (TurnMirror3): each row's bytes are swapped and bit-reversed through
; BitReverse $9A4C, so after the turn every walk frame faces the other way. At
; the $FF end the facing bit flips, the turn bit clears, and the frame is 8
; (moving) or 11 (falling). L1 538 steps, 90 turns.
TurnRound:
  LD HL,(TurnStep)
  LD A,(HL)
  INC HL
  LD (TurnStep),HL
  LD (DroidFrame),A
  CP $0A
  JR Z,TurnMirror2
  CP $FF
  JR NZ,TurnMirror3
  LD HL,TurnSequence
  LD (TurnStep),HL
  LD HL,DroidGraphics
  LD (TurnGraphic),HL
  LD A,(DroidFlags)
  XOR $01
  RES 1,A
  BIT 2,A
  JR NZ,TurnRoundFalling
  RES 3,A
  LD (DroidFlags),A
  LD A,$08
  JR TurnRoundFrame
TurnRoundFalling:
  LD (DroidFlags),A
  LD A,$0B
TurnRoundFrame:
  LD (DroidFrame),A
  JP MoveDroidNewImage
TurnMirror3:
  LD HL,(TurnGraphic)
  LD B,$A0
TurnMirror3Row:
  LD A,(HL)
  LD DE,BitReverse
  ADD A,E
  LD E,A
  JR NC,TurnMirror3Left
  INC D
TurnMirror3Left:
  LD A,(DE)
  LD C,A
  INC HL
  LD A,(HL)
  LD DE,BitReverse
  ADD A,E
  LD E,A
  JR NC,TurnMirror3Middle
  INC D
TurnMirror3Middle:
  LD A,(DE)
  LD (HL),A
  INC HL
  LD A,(HL)
  LD DE,BitReverse
  ADD A,E
  LD E,A
  JR NC,TurnMirror3Right
  INC D
TurnMirror3Right:
  LD A,(DE)
  LD (HL),C
  DEC HL
  DEC HL
  LD (HL),A
  INC HL
  INC HL
  INC HL
  DJNZ TurnMirror3Row
  LD (TurnGraphic),HL
  JP MoveDroidNewImage
TurnMirror2:
  LD HL,(TurnGraphic)
  LD B,$50
TurnMirror2Row:
  LD A,(HL)
  LD DE,BitReverse
  ADD A,E
  LD E,A
  JR NC,TurnMirror2Left
  INC D
TurnMirror2Left:
  LD A,(DE)
  LD C,A
  INC HL
  LD A,(HL)
  LD DE,BitReverse
  ADD A,E
  LD E,A
  JR NC,TurnMirror2Right
  INC D
TurnMirror2Right:
  LD A,(DE)
  LD (HL),C
  DEC HL
  LD (HL),A
  INC HL
  INC HL
  DJNZ TurnMirror2Row
  LD DE,$0050
  ADD HL,DE
  LD (TurnGraphic),HL
  JP MoveDroidNewImage
