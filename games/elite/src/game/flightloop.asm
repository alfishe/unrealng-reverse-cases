; --------------------------------------------------------------------------------------------------------------------
; flightloop.asm: The flight loop, the sun and the planet on screen, the division
;
; FlightLoop $7471 is the game's main loop from the title on: one pass every 5 to 6.5 frames in space, the same loop
; (with the screens) when docked or on a status screen. The sun and the planet are circles: their positions
; (SunPosition $7107, PlanetPosition $7110) are projected for the current view and drawn by the circle code
; (06-rendering.md).
; --------------------------------------------------------------------------------------------------------------------

; The main loop: the controls, the view, the pause, the jump keys, the ships,
; the screen
;
; A pass: CopyRates (unless HoldRates), SelectView, PauseMenu (1 there goes
; back to the title), JumpKeysVector $D042. Docked (Condition 0) it only reads
; the chart cursor and the menu key (KeySteer $FC09 bit 5: the commander load /
; save menu, CommanderMenuVector $D04E); in flight it runs DockKeys, the debug
; key ($7EDE), the sun and planet rotation, the station run-in, then for a
; space view: the dashboard, the 3D view cleared (ClearView $8080), the sun and
; the planet, the stardust, the screen texts, the ships (ShipsVector $9C80),
; the effects, the back buffer copied to the screen (CopyBackBuffer $7FBE), the
; debris, the bars, the flash, the dashboard keys and DashDistances. f1, w1,
; d1: 197283 passes. In space a pass takes 5.0 (no ships) to 6.5 frames (four
; Thargoids), its only wait the HALT in CloakKey every second pass; docked it
; spins with no HALT, about 91 passes a frame (d1 600-700: 9118 in 100 frames;
; runtime-analysis.md).
;
; TooClose set (the ship hit the sun or the planet, or a fatal hit) ends the
; game: 30 frames of other token 9 over the stardust, 50 frames' pause, then
; the title ($739E).
FlightLoop:
  LD A,(HoldRates)
  AND A
  JR NZ,FlightLoopView
  CALL CopyRates
FlightLoopView:
  CALL SelectView
  CALL PauseMenu
  JR NC,FlightLoopJumps
  XOR A
  LD (ViewIndex),A
  CALL DashboardRestore
  JP TitleNext
FlightLoopJumps:
  CALL JumpKeysVector
  LD A,(Condition)
  AND A
  JR NZ,FlightLoopSpace
  CALL ChartCursorKeys
  LD A,(KeySteer)
  BIT 5,A
  JR Z,FlightLoop
  CALL CommanderMenuVector
  JP NZ,TitleIfNotZero
  CALL ScreenStatus
  JR FlightLoop
FlightLoopSpace:
  LD A,(WitchSpace)
  AND A
  JR NZ,FlightLoopViews
  CALL DockKeys
  CALL InSystemJump
  CALL MoveSunPlanet
  CALL StationRunIn
FlightLoopViews:
  LD A,(ViewIndex)
  CP $04
  JR C,FlightLoopDraw
  CALL UpdateShipsVector
  LD A,(Condition)
  AND A
  JR Z,FlightLoopScreen
  CALL ConditionYellow
  CALL Damage
FlightLoopScreen:
  CALL SunGrowth
  CALL ViewTextsVector
  LD B,$08
FlightLoopScreenWait:
  PUSH BC
  CALL ChartCursorKeys
  HALT
  POP BC
  DJNZ FlightLoopScreenWait
  JR FlightLoopEnd
FlightLoopDraw:
  CALL DashboardRestore
  CALL ClearView
  LD A,(WitchSpace)
  AND A
  CALL Z,DrawSunPlanet
  CALL Stardust
  CALL ViewTextsVector
  CALL UpdateShipsVector
  CALL TunnelStart
  CALL HitFlash
  CALL CopyBackBuffer
  CALL DrawScanner
  CALL DrawBars
  CALL CloakKey
  CALL DashboardTick
FlightLoopEnd:
  CALL DashDistances
  LD A,(TooClose)
  AND A
  JP Z,FlightLoop
GameOver:
  XOR A
  LD (SpeedRate),A
  LD (SunLarge),A
  INC A
  LD (HoldRates),A
  LD L,$07
  CALL FillAttrsVector
  CALL ScannerRestore
  CALL ResetShipsVector
  CALL SoundGameOver
  CALL SoundLaunch
  CALL DashboardRestore
  LD B,$1E
GameOverFrame:
  PUSH BC
  CALL ClearView
  CALL Stardust
  CALL UpdateShipsVector
  LD HL,(PrintPointer)
  INC HL
  INC HL
  PUSH HL
  SET 7,(HL)
  LD HL,$070A
  LD (TextColumn),HL
  LD A,$09
  CALL PrintOtherVector
  POP HL
  RES 7,(HL)
  CALL CopyBackBuffer
  POP BC
  DJNZ GameOverFrame
  CALL ClearView
  CALL CopyBackBuffer
  CALL ClearShips
  LD B,$32
GameOverWait:
  HALT
  DJNZ GameOverWait
  XOR A
  LD (HoldRates),A
  LD (TooClose),A
  JP TitleNext

; The stack pointer the title was entered with (the game overs take it back:
; PirateStation)
TitleSP:
  DEFW $0000

; The position DrawSunPlanet projects: x, y, z, 3 bytes each
CircleVector:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00

; The sun's radius the frame before (SunGrowth)
LastSunRadius:
  DEFB $00

; Project and draw the sun and the planet for the view
;
; Each position is copied to CircleVector and projected (ProjectCircle); the
; sun is drawn by DrawCircleDI $86D0 (a sun radius of $28 or more sets
; SunLarge), the planet by DrawCircle $86DE. f1, w1, d1: 895 runs.
DrawSunPlanet:
  XOR A
  LD (SunLarge),A
  LD HL,SunPosition
  LD DE,CircleVector
  LD BC,$0009
  LDIR
  CALL ProjectCircle
  PUSH AF
  CALL SunGrowth
  POP AF
  AND A
  JR Z,DrawPlanet
  CALL DrawCircleDI
  LD A,(CircleRadius)
  CP $28
  JR C,DrawPlanet
  LD A,$01
  LD (SunLarge),A
DrawPlanet:
  LD HL,PlanetPosition
  LD DE,CircleVector
  LD BC,$0009
  LDIR
  CALL ProjectCircle
  AND A
  RET Z
  JP DrawCircle

; With SunGrows $D0BA set the sun's circle grows by 2 a frame; past 255
; TooClose ends the game
;
; Known from the code only past the first test: SunGrows was 0 in every
; recording. NovaSunGrows $726C sets it when NovaMission $D081 is set.
SunGrowth:
  LD A,(SunGrows)
  AND A
  RET Z
  LD A,(LastSunRadius)
  AND A
  JR NZ,SunGrowthStep
  LD A,(CircleRadius)
SunGrowthStep:
  ADD A,$02
  JR Z,SunGrowthEnd
  JR NC,SunGrowthStore
SunGrowthEnd:
  LD A,$01
  LD (TooClose),A
  XOR A
SunGrowthStore:
  LD (CircleRadius),A
  LD (LastSunRadius),A
  RET

; Project CircleVector for the view: the centre, the quadrant bits and the
; radius, A = 1 if seen
;
; The view picks the axes: front x/z and y/z, rear the same with z's sign
; flipped, left and right with x and z exchanged. Each screen coordinate is
; Divide24 of the coordinate by the depth; the quadrant bits go to
; CircleQuadrant $861C (bit 0 x positive, bit 1 y positive), the centre to
; CircleX $861B and CircleY $861A, the radius ($A000 / depth, DivideFraction)
; to CircleRadius $861D. A = 0 when the object is behind the view or too far
; (depth above $A000).
ProjectCircle:
  EXX
  LD BC,$0003
  EXX
  LD A,(ViewIndex)
  AND A
  JP NZ,ProjectCircleRear
  LD A,(CircleVector+$0008)
  BIT 7,A
  JP NZ,ProjectCircleNone
  AND $7F
  LD (CircleVector+$0008),A
  LD HL,(CircleVector+$0007)
  EX DE,HL
  LD HL,(CircleVector+$0001)
  LD A,(CircleVector+$0006)
  LD B,A
  LD A,(CircleVector)
  LD C,A
  LD A,H
  BIT 7,A
  JR NZ,ProjectCircleX
  EXX
  SET 0,B
  EXX
ProjectCircleX:
  AND $7F
  LD H,A
  CALL Divide24
  LD A,D
  LD (CircleX),A
  LD HL,(CircleVector+$0007)
  EX DE,HL
  LD HL,(CircleVector+$0004)
  LD A,(CircleVector+$0006)
  LD B,A
  LD A,(CircleVector+$0003)
  LD C,A
  LD A,H
  BIT 7,A
  JR NZ,ProjectCircleY
  EXX
  SET 1,B
  EXX
ProjectCircleY:
  AND $7F
  LD H,A
  CALL Divide24
  LD A,D
  LD (CircleY),A
  EXX
  LD A,B
  EXX
  LD (CircleQuadrant),A
  LD A,(CircleVector+$0008)
  AND A
  JR NZ,ProjectCircleRadius
  LD HL,$A000
  LD DE,(CircleVector+$0006)
  SBC HL,DE
  JR C,ProjectCircleRadius
  LD A,$FF
  JR ProjectCircleDone
ProjectCircleRadius:
  LD HL,$A000
  LD DE,(CircleVector+$0007)
  AND A
  SBC HL,DE
  JP C,ProjectCircleNone
  LD A,(CircleVector+$0008)
  AND A
  JR Z,ProjectCircleNear
  LD B,A
  LD A,(CircleVector+$0007)
  LD C,A
  XOR A
  LD E,$A0
ProjectCircleScale:
  SLA C
  RL B
  JR C,ProjectCircleDivide
  SLA E
  RLA
  JR ProjectCircleScale
ProjectCircleDivide:
  SCF
  RR B
  CALL DivideFractionE
  LD A,D
  JR ProjectCircleDone
ProjectCircleNear:
  LD A,(CircleVector+$0007)
  LD B,A
  LD A,$A0
  CALL DivideFraction
  LD A,D
ProjectCircleDone:
  JP ProjectCircleStore
ProjectCircleRear:
  DEC A
  JR NZ,ProjectCircleSide
  LD A,(CircleVector+$0008)
  BIT 7,A
  JP Z,ProjectCircleNone
  AND $7F
  LD (CircleVector+$0008),A
  LD HL,(CircleVector+$0007)
  EX DE,HL
  LD HL,(CircleVector+$0001)
  LD A,(CircleVector+$0006)
  LD B,A
  LD A,(CircleVector)
  LD C,A
  LD A,H
  BIT 7,A
  JR Z,ProjectCircleToProjectCircleX
  AND $7F
  LD H,A
  EXX
  SET 0,B
  EXX
ProjectCircleToProjectCircleX:
  JP ProjectCircleX
ProjectCircleSide:
  DEC A
  JP NZ,ProjectCircleRight
  LD A,(CircleVector+$0002)
  BIT 7,A
  JP Z,ProjectCircleNone
  AND $7F
  LD (CircleVector+$0002),A
  LD HL,(CircleVector+$0001)
  EX DE,HL
  LD HL,(CircleVector+$0007)
  LD A,(CircleVector)
  LD B,A
  LD A,(CircleVector+$0006)
  LD C,A
  LD A,H
  BIT 7,A
  JR NZ,ProjectCircleSideY
  EXX
  SET 0,B
  EXX
ProjectCircleSideY:
  AND $7F
  LD H,A
  CALL Divide24
  LD A,D
  LD (CircleX),A
  LD HL,(CircleVector+$0001)
  EX DE,HL
  LD HL,(CircleVector+$0004)
  LD A,(CircleVector)
  LD B,A
  LD A,(CircleVector+$0003)
  LD C,A
  LD A,H
  BIT 7,A
  JR NZ,ProjectCircleSideZ
  EXX
  SET 1,B
  EXX
ProjectCircleSideZ:
  AND $7F
  LD H,A
  CALL Divide24
  LD A,D
  LD (CircleY),A
  EXX
  LD A,B
  EXX
  LD (CircleQuadrant),A
  LD A,(CircleVector+$0002)
  AND A
  JR NZ,ProjectCircleSideRadius
  LD HL,$A000
  LD DE,(CircleVector)
  SBC HL,DE
  JR C,ProjectCircleSideRadius
  LD A,$FF
  JR ProjectCircleSideDone
ProjectCircleSideRadius:
  LD HL,$A000
  LD DE,(CircleVector+$0001)
  AND A
  SBC HL,DE
  JP C,ProjectCircleNone
  LD A,(CircleVector+$0002)
  AND A
  JR Z,ProjectCircleSideNear
  LD B,A
  LD A,(CircleVector+$0001)
  LD C,A
  XOR A
  LD E,$A0
ProjectCircleSideScale:
  SLA C
  RL B
  JR C,ProjectCircleSideDivide
  SLA E
  RLA
  JP ProjectCircleSideScale
ProjectCircleSideDivide:
  SCF
  RR B
  CALL DivideFractionE
  LD A,D
  JR ProjectCircleSideDone
ProjectCircleSideNear:
  LD A,(CircleVector+$0001)
  LD B,A
  LD A,$A0
  CALL DivideFraction
  LD A,D
ProjectCircleSideDone:
  JP ProjectCircleStore
ProjectCircleRight:
  LD A,(CircleVector+$0002)
  BIT 7,A
  JP NZ,ProjectCircleNone
  LD HL,(CircleVector+$0001)
  EX DE,HL
  LD HL,(CircleVector+$0007)
  LD A,(CircleVector)
  LD B,A
  LD A,(CircleVector+$0006)
  LD C,A
  LD A,H
  BIT 7,A
  JR Z,ProjectCircleRightX
  EXX
  SET 0,B
  EXX
ProjectCircleRightX:
  JP ProjectCircleSideY

; ProjectCircleStore
;
; Used by the routine at ProjectCircle.
ProjectCircleStore:
  LD (CircleRadius),A
  LD A,$01
  RET
; This entry point is used by the routine at Divide24.
DivideShort:
  LD H,L
  LD L,C
  LD D,E
  LD E,B
  JP Divide24Align

; D = HL:C / DE:B as a fraction (24-bit numbers): the screen offset of a
; coordinate at a depth
;
; Shift and subtract. The alternate C counts the two calls (one for x, one for
; y): the first sets bit 2 of the alternate B, the second bit 3 when the
; coordinate is smaller than the depth. The result is in D (and A).
Divide24:
  PUSH HL
  EXX
  DEC C
  EXX
  AND A
  SBC HL,DE
  JP C,Divide24Small
  JP Z,Divide24Equal
Divide24Big:
  POP HL
  LD A,H
  AND A
  JR Z,DivideShort
  LD A,$08
Divide24Shift:
  SLA C
  ADC HL,HL
  JP C,Divide24Over
  SLA B
  RL E
  RL D
  DEC A
  JR NZ,Divide24Shift
; This entry point is used by the routine at ProjectCircleStore.
Divide24Align:
  LD A,$08
Divide24AlignHigh:
  ADD HL,HL
  JP C,Divide24Over
  EX DE,HL
  ADD HL,HL
  EX DE,HL
  DEC A
  JR NZ,Divide24AlignHigh
  LD A,$08
Divide24AlignTop:
  SLA H
  JP C,Divide24Over
  SLA D
  DEC A
  JR NZ,Divide24AlignTop
  RET
Divide24Equal:
  PUSH BC
  LD A,C
  SUB B
  POP BC
  JR C,Divide24Small
  JR Z,Divide24Small
  JP Divide24Big
Divide24FirstSmall:
  SET 2,B
  JP Divide24SmallCount
Divide24Small:
  EXX
  DEC C
  JR NZ,Divide24FirstSmall
  SET 3,B
Divide24SmallCount:
  INC C
  EXX
  POP HL
  LD A,$17
Divide24SmallLoop:
  SLA C
  ADC HL,HL
  PUSH AF
  SLA B
  RL E
  RL D
  JR C,Divide24SmallOver
  POP AF
  DEC A
  JR NZ,Divide24SmallLoop
  RET
Divide24Over:
  SLA B
  RL E
  RL D
  PUSH AF
  SCF
  RR H
  RR L
  POP AF
  JR C,Divide24OverBit
  PUSH HL
  AND A
  SBC HL,DE
  JR NC,Divide24OverDone
  POP HL
Divide24OverBit:
  SCF
  RR D
  AND A
  SBC HL,DE
  JR Divide24Join
Divide24OverDone:
  POP HL
  POP AF

; ProjectCircleNone
;
; Used by the routine at ProjectCircle.
ProjectCircleNone:
  XOR A
  RET
Divide24Top:
  SCF
  RR H
  JR Divide24Finish
; This entry point is used by the routine at Divide24.
Divide24SmallOver:
  POP AF
  JR C,Divide24Top
  RR H
Divide24Finish:
  SCF
  RR D
; This entry point is used by the routine at Divide24.
Divide24Join:
  LD A,H
  LD B,D

; D = A * 256 / B: an 8-bit fraction, B > A
;
; Used by the routine at ProjectCircle.
DivideFraction:
  LD E,$00

; DivideFractionE
;
; Used by the routine at ProjectCircle.
DivideFractionE:
  LD D,$FE
DivideFractionLoop:
  SLA E
  RLA
  JR C,DivideFractionSub
  CP B
  JR NC,DivideFractionSub
  SLA D
  RET NC
  JR DivideFractionLoop
DivideFractionSub:
  SUB B
  SCF
  RL D
  RET NC
  JR DivideFractionLoop

; Rotate the sun's and the planet's positions by this frame's roll, pitch and
; speed
;
; Used by the routines at FlightLoop and SceneLaunch.
MoveSunPlanet:
  LD IX,SunPosition
  CALL MovePositionVector
  LD IX,PlanetPosition
  JP MovePositionVector

; After a launch: move slot 0 (the station) until it is behind the ship, then
; normal flight
;
; StationLaunch $711D set: slot 0 is moved (MoveShipVector $9C83) each frame
; until all three coordinates' top bytes are 0 (the station is at the ship);
; then StationLaunch is cleared and its energy $F0. Without it, a slot 0 whose
; energy is 0 is moved once with StationLaunch set to $FF.
StationRunIn:
  LD A,(StationLaunch)
  AND A
  LD IX,ShipSlots
  JR NZ,StationRunInMove
  LD A,(IX+$22)
  AND A
  RET NZ
  DEC A
  LD (StationLaunch),A
StationRunInMove:
  CALL MovePositionVector
  LD A,(IX+$02)
  AND $7F
  RET NZ
  LD A,(IX+$05)
  AND $7F
  RET NZ
  LD A,(IX+$08)
  AND $7F
  RET NZ
  BIT 7,(IX+$26)
  RET NZ
  XOR A
  LD (StationLaunch),A
  LD A,$F0
  LD (IX+$22),A
  RET
