; --------------------------------------------------------------------------------------------------------------------
; shipmotion.asm: The escape pod, the vectors, the ship loop and the motion: rotation, movement, tidying
;
; A ship slot is 39 bytes (ShipSlots $6048, slot 0 the station, slots 1-6 the other ships, slot 7 the player's missile
; and the title's ship). +$00, +$03, +$06: x, y, z, each three bytes (low, high, then the top bits with the sign in
; bit 7). +$09, +$0F, +$15: the three axes (nose, roof, side), three words each whose high byte is sign and magnitude,
; $7FFF one. +$1B speed, +$1C acceleration, +$1D and +$1E the roll and pitch counters (bits 0-3 the steps, bit 6 the
; direction, bit 7 for ever), +$20 the flags (bits 0-2 the ships it may launch, bit 3 fired, bits 4-5 the explosion,
; bit 6 tactics on, bit 7 an escape pod), +$21 the behaviour (bit 2 hostile, bits 5-6 protected), +$22 the energy (0 a
; free slot), +$23 the blueprint, +$25 the tactics state, +$26 the role (bit 0 a missile, 1 scoopable, 2 the station,
; 3 passive). The layout matches zx-elite's DATA-STRUCTURES; each field here is the one this code reads.
;
; The player never moves: every frame each ship is rotated about the origin by the player's roll and pitch and moved
; along z by the player's speed (MovePosition), then turned by its own counters (TurnShip) and moved along its own
; nose by its own speed (MoveShip). The axes drift from unit length and right angles and are tidied every frame
; (TidyAxis).
; --------------------------------------------------------------------------------------------------------------------

; Q with an escape pod, not in witch space (WitchSpace): the pod is launched
; and the cargo, the pod and the legal status lost
;
; Clears the cargo hold ($D06B, 17 bytes) and the fugitive bit of $D0B0,
; empties the hold to 20 tons free, 35 with the large cargo bay (FreeSpace
; $D07C), launches ship $17 (the pod as the player's ship) and counts 24 frames
; down to the arrival at the station (Arrived $71BA). m1 launched it at frame
; 2534 (Q), and m2 before its dock.
EscapePod:
  LD HL,MissileLaunchFlag
  LD A,(HL)
  AND A
  JR Z,EscapePodKey
  DEC A
  LD (HL),A
  JP Z,DockKeysCentre
  RET
EscapePodKey:
  LD A,(KeyCombat)
  BIT 6,A
  RET Z
  LD A,(Equipment+$0005)
  AND A
  RET Z
  LD A,(WitchSpace)
  AND A
  RET NZ
  LD A,$18
  LD (MissileLaunchFlag),A
  LD HL,$0010
  LD (SpeedControl),HL
  XOR A
  LD (LegalStatus),A
  LD (Equipment+$0005),A
  LD HL,CargoHold
  LD B,$11
EscapePodCargo:
  LD (HL),A
  INC HL
  DJNZ EscapePodCargo
  LD HL,MissionFlags
  LD A,(HL)
  AND $DF
  LD (HL),A
  LD HL,FreeSpace
  LD A,(Equipment)
  AND A
  LD A,$14
  JR Z,EscapePodHold
  LD A,$23
EscapePodHold:
  LD (HL),A
  LD A,$17
  CALL ShipActionVector
  LD A,(Seeds+$000B)
  LD (RecordTail+$0001),A
  LD A,(Seeds+$0009)
  LD (RecordTail+$0002),A
  RET

; EscapePodSpare
EscapePodSpare:
  DEFB $00,$00,$00,$00,$00

; The ship vectors: UpdateShips, MovePosition, SquareRoot, Divide16, DrawLine,
; Laser
;
; Used by the routine at FlightLoop.
UpdateShipsVector:
  JP ShipsAndLaser

; MovePositionVector
;
; Used by the routines at MoveSunPlanet and StationRunIn.
MovePositionVector:
  JP MovePosition

; SquareRootVector
;
; Used by the routines at VectorLengthShift and JumpDistance.
SquareRootVector:
  JP SquareRoot

; Divide16Vector
;
; Used by the routines at CompassDivideScale and DrawScanner.
Divide16Vector:
  JP Divide16

; DrawLineVector
DrawLineVector:
  JP DrawLine

; LaserVector
LaserVector:
  JP Gunsight

; ShipVarSpare
ShipVarSpare:
  DEFB $00

; Counts down every pass (UpdateShips); at 0 (every 256 passes) a new ship may
; come (SpawnShip)
JumpEncounter:
  DEFB $00

; Non-zero while a ship that is not passive is about (refuses the in-system
; jump)
ShipsAbout:
  DEFB $00

; Set by the energy bomb: UpdateShips destroys every ship but the station and
; Thargoids' motherships
BombKill:
  DEFB $00

; Non-zero while any slot is in use (the scanner is drawn)
ShipsPresent:
  DEFB $00

; The slot in the gunsight (the missile's lock)
SightTarget:
  DEFB $00

; ShipVarSpare2
ShipVarSpare2:
  DEFB $00

; Set when a protected ship turns hostile: every ship turns hostile while it
; (or the player's missile, slot 7) is about
AllHostile:
  DEFB $00

; Non-zero while docked
Docked:
  DEFB $00

; Non-zero while an ECM is on (the E indicator)
ECMActive:
  DEFB $00

; ShipAction: A = an action (low nibble) and its argument (high nibble)
;
; Used by the routines at Title, TitleNext, TunnelStart, MissileKeys and
; EscapePod.
ShipActionVector:
  JP ShipAction

; ResetShipsVector
;
; Used by the routine at FlightLoop.
ResetShipsVector:
  JP ShipsWreck

; The energy taken from the banks this frame
EnergyDrain:
  DEFB $00

; The hits on the front shield this frame
FrontHits:
  DEFB $00

; The hits on the aft shield this frame
AftHits:
  DEFB $00

; Vectors (known from the code only: nothing calls them)
;
; Used by the routine at HalfDifference.
HalveSignedVector:
  JP SubtractSigned

; UpdateShipVector
UpdateShipVector:
  JP UpdateShip

; TitleShipVector
TitleShipVector:
  JP TurnTitleShip

; Non-zero while a ship other than the station is about (the condition yellow)
NonStationPresent:
  DEFB $00

; The title's turning ship (TurnTitleShip $A28D)
;
; Used by the routines at TitleLoad and TitleNext.
DrawTitleShipVector:
  JP TurnTitleShip

; The cloak ship (an Asp, role bit 6, MissionFlags bit 1): 0 none, 1 about and
; cloaked (DrawShip draws only its laser), 2 hurt below $34 and seen, 3
; destroyed with its canister out (scooped: the cloaking device)
MissionShip:
  DEFB $00

; The ships in slots 1-6 with tactics on
ActiveShips:
  DEFB $00

; UpdateShips's slot counter (8 down to 1)
ShipLoopCount:
  DEFB $00

; UpdateShips, then the gunsight and the laser (Laser $B7B4)
;
; Used by the routine at UpdateShipsVector.
ShipsAndLaser:
  CALL UpdateShips
  JP Gunsight

; Every slot once a frame: spawn, count, tactics, move, tidy, collide, draw,
; explode
;
; Before the loop: the station hostile in mission state 4 ($D0AF), the line
; drawing patched to OR ($B1) or XOR ($A9) by $7120, JumpEncounter counted, and
; a new ship tried when it reaches 0 outside the safe zone and with no jump
; running and fewer than 4 ships about. 1106 runs; 8848 slot passes, 1288 on a
; ship.
UpdateShips:
  LD A,(MissionState)
  CP $04
  JR NZ,UpdateShipsLines
  LD HL,ShipSlots+$0021
  SET 2,(HL)
UpdateShipsLines:
  LD A,(SunLarge)
  AND A
  LD A,$B1
  JR Z,UpdateShipsPatch
  LD A,$A9
UpdateShipsPatch:
  LD (LineUpX+$0001),A
  LD (LineUpY+$0001),A
  LD (LineDownY+$0001),A
  LD (LineDownX+$0001),A
  LD A,(JumpEncounter)
  DEC A
  LD (JumpEncounter),A
  LD B,A
  LD A,(SafeZone)
  AND A
  JR NZ,UpdateShipsCount
  LD A,(WitchSpace)
  AND A
  JR NZ,UpdateShipsCount
  LD A,(ActiveShips)
  CP $04
  JR NC,UpdateShipsCount
  LD A,B
  AND A
  CALL Z,ShipAction
UpdateShipsCount:
  XOR A
  LD (EnergyDrain),A
  LD (AftHits),A
  LD (FrontHits),A
  LD (SightTarget),A
  LD (NonStationPresent),A
  LD (ShipsPresent),A
  LD (ShipsAbout),A
  LD C,A
  LD IX,ShipSlots
  LD DE,$0027
  LD B,$06
UpdateShipsCountLoop:
  ADD IX,DE
  LD A,(IX+$22)
  AND A
  JR Z,UpdateShipsCountNext
  BIT 6,(IX+$20)
  JR Z,UpdateShipsCountNext
  INC C
UpdateShipsCountNext:
  DJNZ UpdateShipsCountLoop
  LD A,C
  LD (ActiveShips),A
  LD IX,ShipSlots
  LD A,$08

; One slot: the flags, the bomb, the explosion's states, then tactics, moving,
; tidying, collisions and drawing
;
; A destroyed ship (+$20 bits 4-5 = 01 or 11) skips the move; state 10 frees
; the slot, requests the explosion sound, ends the mission ship, pays the
; bounty (AddCash $D0E7 with the blueprint's +$08) and the combat score ($D0EA
; with half of +$15), and a protected ship makes the player a fugitive ($D05F
; bit 6). k2 destroyed its missile, a Thargoid and a Thargon (AddCash 3 runs
; from frame 2612; the score 196560 to 197858); a protected ship is known from
; the code only.
UpdateSlot:
  PUSH AF
  LD B,A
  LD (ShipLoopCount),A
  LD A,(IX+$22)
  AND A
  JP Z,UpdateSlotNext
  LD (ShipsPresent),A
  BIT 2,(IX+$26)
  JR NZ,UpdateSlotJump
  LD (NonStationPresent),A
UpdateSlotJump:
  LD A,(JumpEncounter)
  LD C,A
  BIT 3,(IX+$26)
  JR NZ,UpdateSlotBomb
  LD A,$01
  LD (ShipsAbout),A
UpdateSlotBomb:
  LD A,(BombKill)
  AND A
  JR Z,UpdateSlotAngry
  BIT 2,(IX+$26)
  JR NZ,UpdateSlotAngry
  LD A,(IY+$06)
  CP $27
  JR Z,UpdateSlotAngry
  SET 4,(IX+$20)
UpdateSlotAngry:
  BIT 2,(IX+$21)
  JR Z,UpdateSlotHostile
  LD A,(IX+$21)
  AND $60
  JR Z,UpdateSlotHostile
  LD A,$01
  LD (AllHostile),A
UpdateSlotHostile:
  LD A,(Slot7+$0022)
  AND A
  JR NZ,UpdateSlotMakeHostile
  LD A,(AllHostile)
  AND A
  JR Z,UpdateSlotBlueprint
UpdateSlotMakeHostile:
  SET 2,(IX+$21)
UpdateSlotBlueprint:
  LD H,(IX+$24)
  LD L,(IX+$23)
  PUSH HL
  POP IY
  LD A,(IX+$20)
  AND $30
  JR Z,UpdateSlotAlive
  SUB $20
  JP NZ,UpdateSlotDraw
UpdateSlotExplode:
  RES 5,(IX+$20)
  LD (IX+$1E),A
  LD A,$C0
  LD (IX+$1D),A
  BIT 0,(IX+$26)
  JR NZ,UpdateSlotFree
  LD HL,SoundRequests
  SET 2,(HL)
  LD A,(MissionShip)
  AND A
  JR Z,UpdateSlotFree
  CP $03
  JR Z,UpdateSlotMission
  BIT 6,(IX+$26)
  JR Z,UpdateSlotFree
  JR UpdateSlotMissionDone
UpdateSlotMission:
  LD A,(IY+$01)
  CP $1E
  JR NZ,UpdateSlotFree
UpdateSlotMissionDone:
  XOR A
  LD (MissionShip),A
UpdateSlotFree:
  XOR A
  LD (IX+$22),A
  CALL RemoveShip
  LD D,(IY+$09)
  LD E,(IY+$08)
  CALL AddCashVector
  LD D,(IY+$16)
  LD E,(IY+$15)
  SRL D
  RR E
  CALL AddCombatVector
  LD A,(IX+$21)
  AND $60
  JR Z,UpdateSlotNext
  LD A,(LegalStatus)
  OR $40
  LD (LegalStatus),A
  JR UpdateSlotNext
UpdateSlotAlive:
  LD A,B                  ; tactics every fourth frame per slot (missiles every
                          ; frame), then the move
  XOR C
  AND $0F
  BIT 6,(IX+$20)
  JR Z,UpdateSlotMove
  BIT 0,(IX+$26)
  JR Z,UpdateSlotTactics
  CALL MissileHoming
  JR UpdateSlotMove
UpdateSlotTactics:
  AND $03
  CALL Z,Tactics
UpdateSlotMove:
  CALL UpdateShip
  CALL Orthogonalise
  PUSH IX
  LD DE,$0009
  ADD IX,DE
  CALL TidyAxis
  CALL TidyAxis
  CALL TidyAxis
  POP IX
UpdateSlotDraw:
  CALL Collide
  CALL DrawShip
  RES 3,(IX+$20)
  LD A,(IX+$20)
  AND $30
  CP $10
  JR NZ,UpdateSlotNext
  SET 5,(IX+$20)
  RES 4,(IX+$20)

; The next slot; after the last the bomb is off and the station's anger ends
; when no ship is about
;
; Used by the routine at UpdateSlot.
UpdateSlotNext:
  POP AF
  LD DE,$0027
  ADD IX,DE
  DEC A
  JP NZ,UpdateSlot
  XOR A
  LD (BombKill),A
  LD A,(ShipsAbout)
  AND A
  RET NZ
  LD (AllHostile),A
  RET

; Make a position vector (IX) a unit one: its length (SquareRoot of the sum of
; squares) and each part divided by it
;
; Used by the routine at TacticsAim.
Normalise:
  PUSH IX
  CALL SquareComponent
  PUSH HL
  CALL SquareComponent
  PUSH HL
  CALL SquareComponent
  POP DE
  ADD HL,DE
  POP DE
  ADD HL,DE
  POP IX
  CALL SquareRoot
  EX DE,HL
  PUSH IX
  CALL DivideComponent
  CALL DivideComponent
  CALL DivideComponent
  POP IX
  RET

; The square of one 16-bit part (sign bit off) through the squares table: HL
; low, IX high, IX += 2
;
; (256 b + c)² = 65536 b² + 512 b c + c²: b c by Multiply8 $AB34, b² and c²
; from the table at $BE00 (low bytes) and $BF00 (high bytes).
SquareComponent:
  LD B,(IX+$01)
  LD C,(IX+$00)
  RES 7,B
  PUSH IX
  LD IX,$0000
  CALL Multiply8
  XOR A
  LD D,A
  ADD HL,HL
  RL D
  LD E,H
  ADD IX,DE
  LD H,L
  LD L,A
  PUSH HL
  LD H,$BE
  LD L,B
  LD E,(HL)
  INC H
  LD D,(HL)
  DEC H
  ADD IX,DE
  LD L,C
  LD E,(HL)
  INC H
  LD D,(HL)
  POP HL
  ADD HL,DE
  JR NC,SquareComponentDone
  INC IX
SquareComponentDone:
  EX (SP),IX
  POP HL
  INC IX
  INC IX
  RET

; One part divided by the length (DE), halved, its sign put back
;
; Used by the routine at Normalise.
DivideComponent:
  LD H,(IX+$01)
  LD L,(IX+$00)
  PUSH HL
  RES 7,H
  CALL Divide16
  SRL B
  RR C
  POP HL
  BIT 7,H
  JR Z,DivideComponentStore
  SET 7,B
DivideComponentStore:
  LD (IX+$00),C
  LD (IX+$01),B
  INC IX
  INC IX
  RET

; HL = the square root of HL, scaled up or down to keep 12 bits of precision
;
; Below $1000 the value is shifted up by 8 (or 4) and the root down by 4 (or
; 2). Two steps of Newton's iteration (SquareRootCore).
SquareRoot:
  LD A,H
  CP $10
  JR NC,SquareRootCore
  AND A
  JR Z,SquareRootSmall
  LD B,$04
SquareRootLoop:
  ADD HL,HL
  DJNZ SquareRootLoop
  CALL SquareRootCore
  SRL H
  RR L
  SRL H
  RR L
  RET
SquareRootSmall:
  LD H,L
  LD L,A
  CALL SquareRootCore
  LD B,$04
SquareRootShift:
  SRL H
  RR L
  DJNZ SquareRootShift
  RET

; Two Newton steps from $8000: r = (r + n / r) / 2
;
; Used by the routine at SquareRoot.
SquareRootCore:
  XOR A
  PUSH HL
  PUSH HL
  SRL H
  RR L
  RRA
  LD DE,$8000
  CALL SquareRootAdd
  POP DE
  CALL SquareRootStep
  POP DE

; SquareRootStep
;
; Used by the routine at SquareRootCore.
SquareRootStep:
  RR H
  RR L
  EX DE,HL
  SRL H
  RR L
  RRA

; SquareRootAdd
;
; Used by the routine at SquareRootCore.
SquareRootAdd:
  PUSH DE
  CALL Divide16
  SRL B
  RR C
  XOR A
  POP HL
  ADD HL,BC
  RET

; Bring an axis back to unit length: each part times 1 - (x² + y² + z² - 1) / 2
; from the high bytes
;
; The correction is the sum of the three high bytes' squares (the table $BF00,
; index 2 x) / 4, negated with the sign in bit 7; TidyPart multiplies each high
; byte by it. 4650 runs: the three axes of each ship drawn.
TidyAxis:
  LD H,$BF
  LD L,(IX+$01)
  SLA L
  LD A,(HL)
  LD L,(IX+$03)
  SLA L
  ADD A,(HL)
  LD L,(IX+$05)
  SLA L
  ADD A,(HL)
  SRA A
  SRA A
  NEG
  XOR $80
  LD B,A
  CALL TidyPart
  CALL TidyPart
  CALL TidyPart
  RET

; One part times the correction (B), keeping its sign
;
; Used by the routine at TidyAxis.
TidyPart:
  LD C,(IX+$01)
  SLA C
  CALL Multiply8
  SLA H
  SLA (IX+$01)
  RR H
  LD (IX+$01),H
  INC IX
  INC IX
  RET

; The roll (low) and pitch (high) of the ship being turned
TurnRates:
  DEFB $00,$00

; Move one ship by the player, remove it when too far, turn it by its own
; counters and move it along its nose
;
; Too far: a high byte of x, y or z past 0 (z past $60 for anything but the
; station) frees the slot quietly (RemoveShip $B5DF). Roll steps are angle $0C,
; pitch steps 8; the counters count down unless bit 7 is set.
UpdateShip:
  CALL MovePosition
  BIT 2,(IX+$26)
  JR NZ,UpdateShipFar
  LD A,L
  CP $60
  JR NC,UpdateShipRemove
UpdateShipFar:
  LD A,H
  AND $7F
  JR Z,UpdateShipTurn
UpdateShipRemove:
  XOR A
  LD (IX+$22),A
  JP RemoveShip
UpdateShipTurn:
  LD A,(IX+$02)
  ADD A,A
  JR NZ,UpdateShipRemove
  LD A,(IX+$05)
  ADD A,A
  JR NZ,UpdateShipRemove
  LD HL,(RollRate)
  LD (TurnRates),HL
  PUSH IX
  LD DE,$0009
  ADD IX,DE
  CALL TurnAxis
  CALL TurnAxis
  CALL TurnAxis
  POP IX
  LD A,(IX+$1D)
  LD B,A
  BIT 7,A
  JR NZ,UpdateShipRollRate
UpdateShipRoll:
  AND $0F
  LD A,$00
  JR Z,UpdateShipPitch
  LD A,B
  DEC A
  LD (IX+$1D),A
UpdateShipRollRate:
  LD A,$0C
  BIT 6,(IX+$1D)
  JR Z,UpdateShipPitch
  ADD A,$80
UpdateShipPitch:
  LD (TurnRates),A
  LD A,(IX+$1E)
  LD B,A
  BIT 7,A
  JR NZ,UpdateShipPitchRate
  AND $0F
  LD A,$00
  JR Z,MoveShip
  LD A,B
  DEC A
  LD (IX+$1E),A
UpdateShipPitchRate:
  LD A,$08
  BIT 6,(IX+$1E)
  JR Z,MoveShip
  ADD A,$80

; The ship's own speed along its nose axis (three parts), then its axes turned
; by its own rates
;
; Used by the routines at UpdateShip and TurnTitleShip.
MoveShip:
  LD (TurnRates+$0001),A
  PUSH IX
  CALL TurnOwn
  CALL TurnOwn
  CALL TurnOwn
  POP IX
  LD A,(IX+$1C)
  AND A
  JR Z,MoveShipIfZero3
  LD B,(IX+$1B)
  ADD A,B
  BIT 7,A
  JR Z,MoveShipIfZero
  XOR A
  JR MoveShipJoin
MoveShipIfZero:
  LD C,(IY+$06)
  BIT 0,(IX+$21)
  JR Z,MoveShipIfZero2
  SLA C
  SLA C
MoveShipIfZero2:
  CP C
  JR C,MoveShipJoin
  LD A,C
MoveShipJoin:
  LD (IX+$1B),A
MoveShipIfZero3:
  PUSH IX
  PUSH IY
  LD C,(IX+$1B)
  PUSH IX
  POP IY
  CALL MoveAlongAxis
  CALL MoveAlongAxis
  CALL MoveAlongAxis
  POP IY
  POP IX
  RET

; One position part plus speed x the axis part
;
; Used by the routine at MoveShip.
MoveAlongAxis:
  PUSH BC
  LD D,(IX+$0A)
  LD E,(IX+$09)
  CALL MultiplySpeed
  LD A,(IY+$02)
  LD H,(IY+$01)
  LD L,(IY+$00)
  CALL AddSigned
  LD (IY+$02),B
  LD (IY+$01),H
  LD (IY+$00),L
  INC IY
  INC IY
  INC IY
  INC IX
  INC IX
  POP BC
  RET

; DE = speed (D) x the axis part's high byte (C), sign in D bit 7
;
; Used by the routine at MoveAlongAxis.
MultiplySpeed:
  SLA D
  RL C
  RL C
  SRL D
  LD HL,$0000
  LD B,$06
MultiplySpeedLoop:
  SRL D
  RR E
  SLA C
  JR NC,MultiplySpeedNext
  ADD HL,DE
MultiplySpeedNext:
  DJNZ MultiplySpeedLoop
  LD DE,$00FF
  ADD HL,DE
  LD E,H
  SLA C
  RR D
  RET

; HL (a sign and magnitude part, the sign in B) plus DE (signed): the result's
; sign in B
;
; Used by the routine at MoveAlongAxis.
AddSigned:
  LD B,A
  LD C,D
  XOR C
  RES 7,D
  JR NZ,AddSignedSub
  ADD HL,DE
  RET
AddSignedSub:
  SBC HL,DE
  RET NC
  ADD HL,DE
  EX DE,HL
  AND A
  SBC HL,DE
  LD B,C
  RET

; Turn one axis by the player's roll and pitch: the four small-angle rotations
; y-z, x-y, y-x, z-y
;
; Used by the routine at UpdateShip.
TurnAxis:
  LD A,(TurnRates+$0001)
  XOR $80
  SRA A
  RES 6,A
  LD C,A
  LD B,(IX+$03)
  LD D,(IX+$05)
  CALL RotatePart
  LD (IX+$05),A
  LD A,(TurnRates)
  XOR $80
  LD C,A
  LD B,(IX+$03)
  LD D,(IX+$01)
  CALL RotatePart
  LD (IX+$01),A
  LD A,(TurnRates)
  LD C,A
  LD B,(IX+$01)
  LD D,(IX+$03)
  CALL RotatePart
  LD (IX+$03),A
  LD A,(TurnRates+$0001)
  SRA A
  RES 6,A
  LD C,A
  LD B,(IX+$05)
  LD D,(IX+$03)
  CALL RotatePart
  LD (IX+$03),A
  LD DE,$0006
  ADD IX,DE
  RET

; A = D + B x C / 256, in sign and magnitude, clamped at $FF
;
; Used by the routines at TurnAxis and TurnOwn.
RotatePart:
  PUSH DE
  XOR B
  SLA B
  RES 7,C
  LD E,A
  CALL Multiply8High
  POP BC
  LD C,A
  LD A,E
  XOR B
  SLA B
  RR E
  SLA C
  RLA
  LD A,B
  JR C,RotatePartSub
RotatePartAdd:
  ADD A,C
  JR NC,RotatePartDone
  LD A,$FF
  JR RotatePartDone
RotatePartSub:
  SUB C
  JR NC,RotatePartDone
  NEG
  RL E
RotatePartDone:
  RL E
  RRA
  RET

; Turn the ship's axes by its own roll and pitch (the nose and the side about
; the roof)
;
; Used by the routine at MoveShip.
TurnOwn:
  LD A,(TurnRates+$0001)
  XOR $80
  LD C,A
  LD A,C
  LD B,(IX+$10)
  LD D,(IX+$0A)
  CALL RotatePart
  LD (IX+$0A),A
  LD A,(TurnRates)
  XOR $80
  LD C,A
  LD A,C
  LD B,(IX+$10)
  LD D,(IX+$16)
  CALL RotatePart
  LD (IX+$16),A
  LD A,(TurnRates)
  LD C,A
  LD B,(IX+$16)
  LD D,(IX+$10)
  CALL RotatePart
  LD (IX+$10),A
  LD A,(TurnRates+$0001)
  LD C,A
  LD A,C
  LD B,(IX+$0A)
  LD D,(IX+$10)
  CALL RotatePart
  LD (IX+$10),A
  INC IX
  INC IX
  RET

; Rotate a position about the origin by the player's roll and pitch, then move
; it along z by the player's speed
;
; x, y, z each three bytes; the four rotations use full precision
; (CombineParts). The speed step is 2 x (SpeedRate + 1) on the low byte of z,
; the far value clamped at $7FFF / $8000.
MovePosition:
  LD A,(PitchRate)
  XOR $80
  LD C,A
  LD DE,$0003
  LD HL,$0006
  CALL CombineParts
  LD A,(RollRate)
  XOR $80
  CALL RateBits
  LD DE,$0003
  LD H,D
  LD L,D
  CALL CombineParts
  LD A,(RollRate)
  CALL RateBits
  LD HL,$0003
  LD D,H
  LD E,H
  CALL CombineParts
  LD A,(PitchRate)
  LD C,A
  LD HL,$0003
  LD DE,$0006
  CALL CombineParts
  LD A,(SpeedRate)
  INC A
  ADD A,A
  LD B,A
  LD H,(IX+$08)
  LD L,(IX+$07)
  LD A,(IX+$06)
  BIT 7,H
  JR Z,MovePositionBehind
MovePositionAhead:
  ADD A,B
  LD (IX+$06),A
  JR NC,MovePositionReturn
  INC HL
  BIT 7,H
  JR NZ,MovePositionStore
  LD HL,$7FFF
  JR MovePositionClamp
MovePositionBehind:
  SUB B
  LD (IX+$06),A
  JR NC,MovePositionReturn
  DEC HL
  BIT 7,H
  JR Z,MovePositionStore
  LD HL,$8000
MovePositionClamp:
  NEG
  LD (IX+$06),A
MovePositionStore:
  LD (IX+$08),H
  LD (IX+$07),L
MovePositionReturn:
  RET

; part[HL] += part[DE] x rate (C), the 24-bit parts in sign and magnitude
;
; Used by the routine at MovePosition.
CombineParts:
  PUSH IX
  PUSH IX
  EX (SP),IY
  ADD IX,DE
  EX DE,HL
  ADD IY,DE
  LD A,(IX+$02)
  LD D,(IX+$01)
  LD E,(IX+$00)
  LD B,A
  XOR C
  AND $80
  PUSH AF
  RES 7,C
  RES 7,B
  PUSH DE
  CALL Multiply8
  POP DE
  PUSH HL
  LD B,D
  PUSH DE
  CALL Multiply8
  POP DE
  LD B,E
  LD A,L
  LD L,H
  LD H,$00
  POP DE
  ADD HL,DE
  LD E,A
  PUSH HL
  CALL Multiply8High
  ADD A,E
  POP HL
  JR NC,CombinePartsIfNotBelow
  INC HL
CombinePartsIfNotBelow:
  LD B,A
  LD A,H
  LD H,L
  LD L,B
  POP BC
  LD C,B
  LD B,(IY+$02)
  LD D,(IY+$01)
  LD E,(IY+$00)
  PUSH AF
  LD A,B
  XOR C
  RLC C
  RLC C
  RLA
  RR C
  RRC C
  SRL A
  LD B,A
  POP AF
  BIT 6,C
  JR NZ,CombinePartsIfNotZero
  ADD A,A
  SLA C
  RRA
  ADD A,B
  ADD HL,DE
  JR NC,CombinePartsJoin
  INC A
  JR CombinePartsJoin
CombinePartsIfNotZero:
  AND A
  EX DE,HL
  SBC HL,DE
  JR NC,CombinePartsIfNotBelow2
  INC A
CombinePartsIfNotBelow2:
  LD D,A
  LD A,B
  SUB D
  LD B,A
  JR NC,CombinePartsIfNotBelow3
  CPL
  LD B,A
  LD A,C
  XOR $80
  LD C,A
  EX DE,HL
  AND A
  LD HL,$0000
  SBC HL,DE
CombinePartsIfNotBelow3:
  LD A,B
  RLA
  SLA C
  RRA
  XOR $80
CombinePartsJoin:
  LD (IY+$02),A
  LD (IY+$01),H
  LD (IY+$00),L
  POP IY
  POP IX
  RET

; The pitch rate's bits shuffled into C for CombineParts
;
; Used by the routine at MovePosition.
RateBits:
  LD C,A
  RL C
  RRA
  RL C
  RLA
  RR C
  RET
