; --------------------------------------------------------------------------------------------------------------------
; movers.asm: The moving objects: the train, the plane, the tornado; the meltdown
;
; The sprites over the view, the train on the rails, the plane and its crash, the tornado that walks to the centre,
; the meltdown of a nuclear station.
; --------------------------------------------------------------------------------------------------------------------

; Draw the 16 x 16 sprite A (MoverSprites $A884) at map cell (B, C), if it is
; in the view and its row is drawn this pass
;
; The sprite is ORed in. The "mask" computed from the screen byte, byte AND
; (byte OR byte shifted), is the byte itself, so nothing is cut. L1 2297.
DrawMover:
  LD HL,(ViewCol)
  LD E,A
  LD A,B
  CP H
  RET C
  LD A,H
  ADD A,$0E
  CP B
  RET C
  LD A,B
  SUB H
  ADD A,$08
  LD B,A
  LD A,C
  CP L
  RET C
  LD A,L
  ADD A,$1E
  CP C
  RET C
  LD A,C
  SUB L
  LD C,A
  LD A,(PassCount)
  AND $0F
  ADD A,$08
  CP B
  RET C
  LD L,E
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,MoverSprites
  ADD HL,DE
  EX DE,HL
  CALL ScreenAddr
  LD B,$10
DrawMoverLine:
  PUSH HL
  LD A,(HL)
  LD C,A
  SLA A
  OR C
  LD C,A
  LD A,(HL)
  AND C
  LD C,A
  LD A,(DE)
  OR C
  LD (HL),A
  INC DE
  INC L
  LD A,(HL)
  LD C,A
  SRA A
  OR C
  LD C,A
  LD A,(HL)
  AND C
  LD C,A
  LD A,(DE)
  OR C
  LD (HL),A
  INC DE
  POP HL
  CALL NextPixelLine
  DJNZ DrawMoverLine
  RET

; Each pass: the train (not under a rail bridge), the plane and the tornado, if
; they are out
;
; The plane is sprite 0, the train 3 or 4 (by its direction), the tornado 1 or
; 2 at random (LD A,R). L1 158 076.
DrawMovers:
  LD A,(TrainOut)
  AND A
  JR Z,DrawMoversPlane
  LD BC,(TrainCell)
  CALL MapAddrChecked
  LD A,(HL)
  CP $1F
  JR Z,DrawMoversPlane
  CP $20
  JR Z,DrawMoversPlane
  LD A,(TrainOut)
  AND A
  LD BC,(TrainCell)
  LD A,(TrainSprite)
  CALL NZ,DrawMover
DrawMoversPlane:
  LD A,(PlaneOut)
  AND A
  LD BC,(PlaneCell)
  LD A,$00
  CALL NZ,DrawMover
  LD A,R
  AND $01
  INC A
  LD D,A
  LD A,(TornadoOut)
  AND A
  LD BC,(TornadoCell)
  LD A,D
  CALL NZ,DrawMover
  RET

; The train ($77D3-$77DB): its cell (column, row), sprite, out flag, the way it
; came, turn, tries, steps
TrainCell:
  DEFB $1C,$18
TrainSprite:
  DEFB $03
TrainOut:
  DEFB $00
TrainBack:
  DEFB $00
TrainTurn:
  DEFB $00
TrainDir:
  DEFB $00
TrainTries:
  DEFB $00
TrainSteps:
  DEFB $00

; Move the train one cell along the rails (CellFlags bit 1), never straight
; back; gone when it finds none
;
; Called through MoveDisasters by Periodic on every 16th UI pass (PassCount AND
; $0F = 0; L1 9884 against 158 073 UI passes); it moved in c1 (L1 442 at
; MoveTrainTry). A stuck move adds 1 to TrainSteps, a good one does not clear
; it: every fifth stuck move sets TrainBack 5 so the train may reverse.
MoveTrain:
  LD A,(TrainOut)
  AND A
  RET Z
  LD BC,(TrainCell)
  CALL MapAddr
  LD A,(HL)
  CALL CellFlagsOf
  AND $02
  JR NZ,MoveTrainStart
  XOR A
  LD (TrainOut),A
  RET
MoveTrainStart:
  LD BC,(TrainCell)
  CALL Random
  AND $03
  LD (TrainTurn),A
  LD A,$04
  LD (TrainTries),A
MoveTrainTry:
  LD A,(TrainTurn)
  AND $03
  LD (TrainDir),A
  LD HL,TrainBack
  CP (HL)
  JR Z,MoveTrainNext
  LD A,(TrainDir)
  CALL NeighbourAddr
  LD A,(HL)
  CALL CellFlagsOf
  AND $02
  JR NZ,MoveTrainStep
MoveTrainNext:
  LD HL,TrainTurn
  INC (HL)
  LD HL,TrainTries
  DEC (HL)
  JR NZ,MoveTrainTry
  LD HL,TrainSteps
  LD A,(HL)
  INC A
  LD (HL),A
  CP $05
  RET NZ
  LD (HL),$00
  LD A,$05
  LD (TrainBack),A
  RET
MoveTrainStep:
  LD A,(TrainDir)
  CALL StepDir
  LD A,(TrainDir)
  ADD A,$02
  AND $03
  LD (TrainBack),A
  LD (TrainCell),BC
  LD C,$03
  AND $01
  JR NZ,MoveTrainSprite
  INC C
MoveTrainSprite:
  LD A,C
  LD (TrainSprite),A
  RET

; From a rail cell (RailCell $8903): when no train is out, 1 in 64 starts one
; there
;
; The $9312 compare's result is lost (AND A follows): a dead test. L1 134.
StartTrain:
  LD A,(TransportCost+$0001)
  CP $08                  ; CP $08: dead, the flags are replaced by the AND A
                          ; that follows
  LD A,(TrainOut)
  AND A
  RET NZ
  CALL Random
  AND $3F
  RET NZ
  LD HL,(CurCell)
  LD (TrainCell),HL
  LD A,$01
  LD (TrainOut),A
  RET

; The plane: out flag, cell (column, row), the column it crashes at, the crash
; timer
PlaneOut:
  DEFB $00
PlaneCell:
  DEFB $00
  DEFB $00
PlaneTarget:
  DEFB $00
PlaneTimer:
  DEFB $00

; Fly the plane a column left; when the timer runs out, crash: burn a 2 x 2
; (CrashCell) and the noise (CrashNoise)
;
; L1 9884; the crash L1 0 in the disaster recording? see NOTES.
MovePlane:
  LD A,(PlaneOut)
  AND A
  RET Z
  LD A,(PlaneCell)
  LD HL,PlaneTarget
  CP (HL)
  JR Z,PlaneDone
  LD HL,PlaneCell
  DEC (HL)
  LD HL,PlaneTimer
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  RET NZ
  LD BC,(PlaneCell)
  CALL CrashCell
  INC C
  CALL CrashCell
  DEC C
  INC B
  CALL CrashCell
  INC C
  CALL CrashCell
  CALL CrashNoise
PlaneDone:
  XOR A
  LD (PlaneOut),A
  RET

; Ignite ($90C4) at BC
;
; Used by the routine at MovePlane.
CrashCell:
  PUSH BC
  CALL MapAddr
  CALL Ignite
  POP BC
  RET

; 255 NoiseBurst calls with a rising gate: the disaster noise
;
; Used by the routines at MovePlane and NuclearMeltdown.
CrashNoise:
  LD B,$FF
  LD E,$00
CrashNoiseLoop:
  PUSH BC
  CALL NoiseBurst
  POP BC
  INC E
  DJNZ CrashNoiseLoop
  RET

; With no plane out, 1 in 2 (Random AND 1): a plane from the airport's row at
; the right edge (column $60) or at the airport
;
; Used by the routine at AirportStep.
StartPlane:
  LD A,(PlaneOut)
  AND A
  RET NZ
  CALL Random
  AND $01
  RET NZ
  CALL Random
  AND $01
  JR Z,StartPlaneHere
  LD BC,(CurCell)
  LD A,C
  LD (PlaneTarget),A
  LD C,$60
  LD (PlaneCell),BC
StartPlaneSet:
  LD A,$01
  LD (PlaneOut),A
  RET
StartPlaneHere:
  LD BC,(CurCell)
  XOR A
  LD (PlaneTarget),A
  LD (PlaneCell),BC
  JR StartPlaneSet

; The AIR CRASH disaster: with an airport ($849E), message $19 (AIR CRASH !!!)
; and a crash timer of 7-22
;
; Used by the routine at RunDisaster.
AirCrash:
  LD A,(LastAirports)
  AND A
  RET Z
  LD A,$19
  CALL SetAdvice
  CALL Random
  AND $0F
  ADD A,$07
  LD (PlaneTimer),A
  RET

; With a nuclear plant ($84A0): message $12 (NUCLEAR MELTDOWN),
; MeltdownPending, the noise
;
; Used by the routine at RunDisaster.
NuclearMeltdown:
  LD A,(LastNuclear)
  AND A
  RET Z
  LD A,$12
  CALL SetAdvice
  LD A,$01
  LD (MeltdownPending),A
  JR CrashNoise

; Set by NuclearMeltdown; Meltdown runs at the next pass
MeltdownPending:
  DEFB $00

; The plant catches fire (cell $45 over it all) and 1 in 16 of the 45 x 45
; cells round it turn to radiation $59
;
; L1 890 (the test).
Meltdown:
  LD A,(MeltdownPending)
  AND A
  RET Z
  XOR A
  LD (MeltdownPending),A
  LD A,$45
  LD (SpreadCode),A
  LD HL,(CurAddr)
  CALL FillBuilding
  LD HL,(CurCell)
  LD A,H
  SUB $14
  LD D,A
  LD A,L
  SUB $14
  LD E,A
  LD B,$2D
MeltdownRow:
  LD C,$2D
  PUSH DE
MeltdownCell:
  PUSH BC
  LD B,D
  LD C,E
  CALL Random
  AND $0F
  CALL Z,Irradiate
  POP BC
  INC E
  DEC C
  JR NZ,MeltdownCell
  POP DE
  INC D
  DJNZ MeltdownRow
  RET

; A non-water cell below $80 at BC becomes $59
;
; Used by the routine at Meltdown.
Irradiate:
  CALL MapAddrChecked
  RET NC
  LD A,(HL)
  BIT 7,A
  RET NZ
  CP $00
  RET Z
  LD (HL),$59
  RET

; The TORNADO disaster: message $1A, the tornado on a random land cell of rows
; and columns 16-79
;
; Used by the routine at RunDisaster.
StartTornado:
  LD A,$1A
  CALL SetAdvice
  LD A,$01
  LD (TornadoOut),A
StartTornadoFind:
  CALL Random
  AND $3F
  ADD A,$10
  LD B,A
  CALL Random
  AND $3F
  ADD A,$10
  LD C,A
  PUSH BC
  CALL MapAddr
  POP BC
  LD A,(HL)
  CP $02
  JR NZ,StartTornadoFind
  LD (TornadoCell),BC
  RET

; The tornado: cell (column, row), out flag
TornadoCell:
  DEFB $00,$00
TornadoOut:
  DEFB $00

; Move the tornado: 1 in 8 toward the city centre ($84A2), else a random step;
; off when Random gives 0
;
; The cell down and right of it is hit: a building burns (BurnBuilding), a
; flammable cell (CellFlags bit 7) becomes $3A. It stops at water. L1 9884; the
; work L1 27.
MoveTornado:
  LD A,(TornadoOut)
  AND A
  RET Z
  CALL Random
  AND A
  JR NZ,MoveTornadoStep
  XOR A
  LD (TornadoOut),A
MoveTornadoStep:
  LD BC,(TornadoCell)
  CALL Random
  AND $07
  JR NZ,MoveTornadoRandom
  LD HL,(CityCentre)
  LD A,H
  SUB B
  JR Z,MoveTornadoRow
  SBC A,A
  OR $01
  ADD A,B
  LD B,A
MoveTornadoRow:
  LD A,L
  SUB C
  JR Z,MoveTornadoCheck
  SBC A,A
  OR $01
  ADD A,C
  LD C,A
MoveTornadoCheck:
  PUSH BC
  CALL MapAddr
  POP BC
  LD A,(HL)
  CP $00
  RET Z
  LD (TornadoCell),BC
MoveTornadoHit:
  INC C
  INC B
  CALL MapAddrChecked
  RET NC
  LD A,(HL)
  CALL CellFlagsOf
  BIT 7,A
  RET Z
  LD A,(HL)
  BIT 7,A
  JP NZ,BurnBuilding
  LD (HL),$3A
  RET
MoveTornadoRandom:
  CALL Random
  AND $03
  CALL StepDir
  PUSH BC
  CALL MapAddr
  POP BC
  LD A,(HL)
  CP $00
  RET Z
  LD (TornadoCell),BC
  JR MoveTornadoHit
