; --------------------------------------------------------------------------------------------------------------------
; vehicle.asm: The ATV and its rider: the records, the controls, speed, steering, wheelies, jumps, the ground, crashes, tumbling, the rider on foot, mounting, fuel
;
; Each player has a record of 50 bytes (RecordP1 $D70E, RecordP2 $D740); the pass copies it to Record ($D772) and
; back. The ATV moves along the trail by Distance (speed x 128 a pass), never sideways: Left and Right are the
; throttle in the facing direction (Accelerate, up to speed level 21) and the brake against it (SlowDown by 2); at a
; standstill the brake turns the ATV round (the riderless frame $5C while it turns). Up lifts the nose (WheelieUp, 10
; passes of WheelieTimer), Down drops it; Jump sets an upward speed from $FD less the slope. GroundUnder scans the
; buffer's pixels under the wheels: the ground is whatever list A drew there. Three tests crash (Crash): a step up of
; 7 or more lines beyond the last pass's rise (AtvPhysics $E6E6; recording speedcrash), the nose test when the nose is
; in the ground ($E76D: the ground under the nose less GroundY, unsigned, $15 or more: a wall 21 or more above the
; wheels, or by the wrap any nose ground lower than GroundY; recording wallcrash, 7 lower, $F9), and a sharp nose lift
; in the air (CrashIfAir): Crash calls SlowDown first, so the thresholds apply to the speed less 2: under 10 the ATV
; stops, 10-14 (12-16 before) it stops and throws the rider (recording speedcrash, 15 at the step), 15 and up (17 and
; up before) it tumbles (Tumble, TumbleCount 1-24) and throws the rider (recording wallcrash, 21). The thrown rider
; lands lying ($77); Jump stands him up; on foot Left / Right walk him (3 pixels a pass) and Jump jumps; landing on
; the ATV from behind while facing its way remounts (MountCheck). Fuel ($2000 at each trail) drops by speed x 2 a
; moving pass; the FUEL bar loses 4 pixels each $400; under $400 the ATV is out of fuel (OutOfFuel: reached in empty,
; first at frame 732).
; --------------------------------------------------------------------------------------------------------------------

  ORG $D70E

; Player 1's record (50 bytes, Record's fields), copied in and out each pass
RecordP1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; Player 2's record
RecordP2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; The current player's record
Record:
RiderJump:
  DEFB $00                ; the rider's jump on foot: 0 on the ground, 1-7 its
                          ; phase (RiderJumpTable)
VSpeed:
  DEFB $00                ; the ATV's vertical speed: $FD-$F8 rising
                          ; (negative), 1-5 falling (FallSteps)
Mounted:
  DEFB $00                ; 1 the rider is on the ATV, 0 on foot
AtvFrame:
  DEFB $00                ; the ATV's sprite: $38-$45 nose up by steps of 2,
                          ; $46-$4E nose down, $5C riderless, $7D-$87 tumbling
Facing:
  DEFB $00                ; 0 right, 1 left
AtvX:
  DEFB $00                ; the ATV's x on screen
AtvHeight:
  DEFB $00                ; its height above the bottom line
PrevHeight:
  DEFB $00,$00            ; the height a pass ago ($D77A two passes ago)
Speed:
  DEFB $00                ; the speed level, 0-21
Fuel:
  DEFB $00,$00            ; the fuel word ($2000 full; empty under $400)
SpeedBarLen:
  DEFB $00                ; the SPEED bar's drawn length
FuelBar:
  DEFB $00                ; the FUEL bar's end x ($90 + the length)
JumpLatch:
  DEFB $00                ; 1 while jump is held (one jump a press)
TurnLeft:
  DEFB $00                ; 1 while the ATV turns round to the left
TurnRight:
  DEFB $00                ; 1 while it turns to the right
RiderFrame:
  DEFB $00                ; the rider's sprite: 0-8 walking, $18 jumping, $59
                          ; riding, $5E-$64 thrown, $77 lying
RiderFacing:
  DEFB $00                ; 0 right, 1 left
RiderX:
  DEFB $00                ; the rider's x
RiderHeight:
  DEFB $00                ; the rider's height
RiderSavedX:
  DEFB $00                ; the rider's x a pass ago (put back when he walks
                          ; into a step)
RiderSavedHeight:
  DEFB $00
Distance:
  DEFB $00                ; the distance along the trail, 24 bits ($D789 the
                          ; fraction)
TrackPos:
  DEFB $00,$00            ; the distance's whole part: list A's scroll;
                          ; FinishCheck compares it with FinishDistance
DistanceIndex:
  DEFB $00,$00            ; list A's index (WalkList)
Scenery:
  DEFB $00                ; list B's scroll, 24 bits
SceneryPos:
  DEFB $00,$00            ; its whole part
ScenIndex:
  DEFB $00,$00,$00,$00    ; list B's index
WheelieTimer:
  DEFB $00,$00            ; passes the nose stays up after Up or a jump
TumbleCount:
  DEFB $00                ; passes of tumbling (0 none)
FallPhase:
  DEFB $00                ; the rider's fall after ThrowOff (FallRider:
                          ; recording throwoff)
ThrowSpeed:
  DEFB $00                ; the thrown rider's flight: $F8 - speed / 8 up, then
                          ; down
EngineNote:
  DEFB $00                ; bit 7 the wheel flicker's phase (DrawAtv picks the
                          ; wheel sprite by it), bits 0-4 the passes to the
                          ; next flip (EngineTimer: 1 at speed 3 or more, 2
                          ; below)
Bonus:
  DEFB $00,$00            ; the time bonus, counted into the score at the
                          ; trail's end
LapTime:
  DEFB $00,$00,$00        ; the clock at the finish (three digits)
GroundBelowRider:
  DEFB $00,$00,$00,$00    ; the ground under the rider

; The last byte sent to port $FE (bit 4 the speaker), toggled by Click
BeeperByte:
  DEFB $00
Finished:
  DEFB $00                ; the players past the finish: bit 0 player 1, bit 1
                          ; player 2
SecondRound:
  DEFB $00                ; 1 after trail 6: the trails again with 30 as every
                          ; maximum
RecordTemplate:
  DEFB $00,$00,$00,$38,$00,$48,$00,$00 ; a new record (InitRecords): frame $38,
  DEFB $00,$00,$00,$20,$40,$90,$00,$00 ; x $48, fuel $2000, the bars, the
  DEFB $00,$00,$00,$18,$00,$18,$00,$00 ; engine 1, lap "000"; its last three
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; bytes are GameEntry's first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; instruction
  DEFB $01,$00,$00,$30,$30,$30,$00

  ORG $DA1E

; Step the engine note's timer: at speed, every 1 or 2 passes (speed under 3)
; flip the tone bit
;
; Witness: L1 6681 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
EngineTimer:
  LD A,(Speed)
  CP $00
  RET Z
  LD A,(EngineNote)
  AND $80
  LD E,A
  LD A,(EngineNote)
  AND $1F
  SUB $01
  JR Z,l_DA38
  OR E
  LD (EngineNote),A
  RET
l_DA38:
  LD A,(Speed)
  LD E,$01
  CP $03
  JR NC,l_DA43
  LD E,$02
l_DA43:
  LD A,(EngineNote)
  AND $80
  XOR $80
  OR E
  LD (EngineNote),A
  RET

; Player 1's pass: the top half (BufferP1 to $4021), the record in, the update,
; the copy, the record out
;
; ScreenBase $4021, BufferBase $F03C, AttrBase $5821, ClearBufferP1, HudY $BE,
; LoadRecordP1, SlowDown when finished, PassControls = Controls1, EngineTimer,
; Update, ClearKeys, Advance, CopyBufferP1, FlushAttrs, SaveRecordP1 (c1: 5081
; passes).
;
; Witness: L1 5868 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
PassP1:
  LD HL,Screen+33
  LD (ScreenBase),HL
  LD HL,BufferP1
  LD (BufferBase),HL
  LD HL,Attributes+33
  LD (AttrBase),HL
  CALL JpClearBufferP1
  LD A,$BE
  LD (HudY),A
  CALL LoadRecordP1
  LD A,(Finished)
  AND $01
  CALL NZ,SlowDown
  LD A,(Controls1)
  LD (PassControls),A
  CALL EngineTimer
  CALL Update
  CALL JpClearKeys
  CALL Advance
  CALL JpCopyBufferP1
  CALL JpFlushAttrs
  JP SaveRecordP1

; Player 2's pass: the bottom half (BufferP2 to $48A1)
;
; Witness: L1 813 (kb).
PassP2:
  LD HL,Screen+2209
  LD (ScreenBase),HL
  LD HL,BufferP2
  LD (BufferBase),HL
  LD HL,Attributes+417
  LD (AttrBase),HL
  LD A,$06
  LD (HudY),A
  CALL JpClearBufferP2
  CALL LoadRecordP2
  LD A,(Finished)
  AND $02
  CALL NZ,SlowDown
  LD A,(Controls2)
  LD (PassControls),A
  CALL EngineTimer
  CALL Update
  CALL Advance
  CALL JpCopyBufferP2
  CALL JpFlushAttrs
  JP SaveRecordP2

; A player's update: draw list A, the ATV's physics, the controls, the jump,
; the rider, the tumble, list B, the deferred sprites and the ATV, the finish
;
; Clears the deferred lists; WalkList over list A at Distance; EngineSound;
; AtvPhysics; Controls; unless riderless: JumpControl, RiderUpdate, Tumble;
; WalkList over list B at Scenery; FlushDeferredB, DrawAtvAndRider,
; FlushDeferredA; then the finish test (FinishCheck).
;
; Bonus = ((MaxTime - the clock) / 2 + 1) x (Trail + 1) + 1, the clock read as
; a number (DigitsValue). trail1: the finish at frame (see NOTES).
;
; Witness: L1 6681 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Update:
  XOR A
  LD (DeferredA+$0002),A
  LD (DeferredB+$0002),A
  LD (DeferredAttrs+$0002),A
  LD HL,$0000
  LD (DeferredA),HL
  LD (DeferredB),HL
  LD (DeferredAttrs),HL
  LD HL,(TrailListA)
  LD (ListBase),HL
  LD HL,DistanceIndex
  LD (ListIndexPtr),HL
  LD HL,(TrackPos)
  LD (ListScroll),HL
  CALL JpWalkList
  CALL EngineSound
  LD A,(RiderSavedHeight)
  LD (RiderHeight),A
  CALL AtvPhysics
  CALL Controls
  LD A,(AtvFrame)
  CP $5C
  JR Z,l_DB16
  CALL JumpControl
  CALL RiderUpdate
  CALL Tumble
l_DB16:
  LD HL,(TrailListB)
  LD (ListBase),HL
  LD HL,ScenIndex
  LD (ListIndexPtr),HL
  LD HL,(SceneryPos)
  LD (ListScroll),HL
  CALL JpWalkList
  CALL JpFlushDeferredB
  CALL DrawAtvAndRider
  CALL JpFlushDeferredA
FinishCheck:
  LD DE,(FinishDistance)  ; past FinishDistance: the Finished bit; the first
                          ; time the lap time and the bonus; "LAP TIME" and
                          ; "EXTENDED PLAY". INC L / LD E,L ($DB74) keep only
                          ; the low byte of (MaxTime - clock) / 2 + 1: a lap of
                          ; 09.0 or less on a "60" trail loses 256 (warp trail
                          ; 1: 15, not 271)
  LD HL,(TrackPos)
  XOR A
  SBC HL,DE
  RET C
  LD A,(Finished)
  LD E,A
  LD A,(PlayerIndex)
  ADD A,$01
  LD D,A
  OR E
  LD (Finished),A
  LD A,E
  AND D
  JR NZ,l_DB82
  LD HL,(Clock)
  LD (LapTime),HL
  LD A,(ClockUnits)
  LD (LapTime+$0002),A
  LD IX,Clock
  CALL DigitsValue
  PUSH HL
  LD IX,MaxTime
  CALL DigitsValue
  POP DE
  XOR A
  SBC HL,DE
  SRL H
  RR L
  INC L
  LD E,L
  LD A,(Trail)
  ADD A,$01
  CALL JpMultiply
  INC HL
  LD (Bonus),HL
l_DB82:
  LD HL,(LapTime)
  LD (LapText+$0009),HL
  LD A,(LapTime+$0002)
  LD (LapText+$000C),A
  LD A,$2B
  LD (SpriteX),A
  LD A,$37
  LD (SpriteY),A
  LD IX,LapText
  CALL PrintShadow
  LD A,$28
  LD (SpriteX),A
  LD A,$47
  LD (SpriteY),A
  LD IX,ExtendedText
  JP PrintShadow

  ORG $DE38

; The rider each pass: on foot (RiderOnFoot, RiderGround) or mounted
; (RiderMounted)
;
; Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderUpdate:
  LD A,(Mounted)
  CP $00
  JR NZ,RiderMounted
  LD DE,RiderSave
  PUSH DE
  LD A,(FallPhase)
  CP $00
  JP NZ,FallRider
  LD A,(ThrowSpeed)
  CP $00
  JP NZ,Thrown
  CALL RiderOnFoot
  JP RiderGround
RiderMounted:
  CALL RiderPose          ; the riding pose; a fall when the ground under the
                          ; rider is far below (no recording)
  CALL RiderGroundMounted
  LD A,(RiderHeight)
  LD E,A
  LD A,(GroundBelowRider)
  CP $4F
  RET Z
  SUB E
  RET C
  CP $0C
  RET C
  CP $1F
  RET NC
  LD A,(Speed)
  CP $04
  JP NC,ThrowOff
  RET

; The mounted rider's pose from the ATV's frame (RidePoses)
;
; Witness: L1 2325 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderPose:
  LD A,(AtvFrame)
  SUB $38
  JP NZ,l_DEAD
  LD E,$08
  LD A,(RiderFacing)
  CP $00
  JR Z,l_DE8D
  LD E,$04
l_DE8D:
  LD A,(AtvX)
  SUB $03
  ADD A,E
  LD (RiderX),A
  LD A,(AtvHeight)
  CALL RiderPoseY
  LD A,$59
  LD (RiderFrame),A
  LD A,(Speed)
  CP $02
  RET C
  LD A,$50
  LD (RiderFrame),A
  RET
l_DEAD:
  JR NC,l_DEB2
  CPL
  ADD A,$0E
l_DEB2:
  SLA A
  LD E,A
  LD D,$00
  LD HL,RidePoses
  ADD HL,DE
  LD A,(HL)
  LD (RiderFrame),A
  INC HL
  LD A,(RiderFacing)
  CP $00
  JR NZ,l_DED4
  LD A,(HL)
  LD E,A
  LD A,(AtvX)
  ADD A,E
  SUB $0C
  LD (RiderX),A
  JR l_DEDF
l_DED4:
  LD A,(HL)
  LD E,A
  LD A,(AtvX)
  SUB E
  ADD A,$14
  LD (RiderX),A
l_DEDF:
  INC HL
  LD A,(HL)
  LD E,A
  LD A,(AtvHeight)
  SUB $09
  ADD A,E
  CALL RiderPoseY
  RET

; The mounted rider's sprite for each ATV frame
RidePoses:
  INCBIN "res/tables/ridepose.bin",$0000,44

; The rider's height on the ATV
;
; Witness: L1 2325 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderPoseY:
  ADD A,$09
  CP $50
  JR C,l_DF23
  CP $A0
  RET NC
  LD A,$4F
l_DF23:
  PUSH AF
  LD A,(RiderHeight)
  LD E,A
  POP AF
  CP E
  JR NC,l_DF30
  LD (RiderSavedHeight),A
  RET
l_DF30:
  LD (RiderHeight),A
  LD (RiderSavedHeight),A
  RET

; The rider walks against a step: back to his last x; jumps or falls to the
; ground
;
; Witness: L1 4057 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderOnFoot:
  LD A,(RiderJump)
  CP $00
  JR Z,l_DF41
  CP $05
  RET C
l_DF41:
  LD A,(GroundBelowRider)
  LD E,A
  LD A,(RiderHeight)
  SUB E
  RET Z
  JR NC,l_DF66
  XOR $FF
  ADD A,$01
  CP $03
  JR NC,l_DF57
  JP RiderLand
l_DF57:
  LD A,(RiderSavedX)
  LD (RiderX),A
  XOR A
  LD (TurnLeft),A
  XOR A
  LD (TurnRight),A
  RET
l_DF66:
  LD E,A
  LD A,(RiderJump)
  CP $00
  RET NZ
  LD A,E
  CP $03
  JR NC,l_DF75
  JP RiderLand
l_DF75:
  LD A,$05
  LD (RiderJump),A
  RET
; This entry point is used by the routine at RiderJumpStart.
RiderLand:
  LD A,(GroundBelowRider) ; on the ground: RiderJump = 0, the standing frame
  LD (RiderHeight),A
  LD A,(RiderJump)
  CP $00
  RET Z
  XOR A
  LD (RiderJump),A
  LD A,$00
  LD (RiderFrame),A
  RET

; Fuel - speed x 2; the FUEL bar shrinks by a nibble each $400; under $400
; OutOfFuel
;
; fuel: the bar from $B0 down to $90 in 8 steps. Recording empty (the fuel's
; high byte POKEd to 5 at frame 567) runs out at frame 732 (OutOfFuel first,
; the text from 736): OutOfFuel ran 83 times, "OUT OF FUEL" is printed, the two
; SlowDowns a moving pass leave the ATV crawling forward while the throttle is
; held (screens 000939-after to 002269-end); only the clock ends the run. The
; first cell goes at the first moving pass ($2000 less anything has level $1C):
; the usable tank is $1C00.
;
; Witness: L1 1875 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
UseFuel:
  LD HL,(Fuel)
  LD A,(Speed)
  SLA A
  LD E,A
  LD D,$00
  XOR A
  SBC HL,DE
  JR NC,l_DFA4
  LD HL,$0000
l_DFA4:
  LD (Fuel),HL
  LD HL,Screen
  LD (ScreenBase),HL
  LD A,(HudY)
  LD (SpriteY),A
  LD A,(FuelBar)
  SUB $90
  LD E,A
  LD A,(Fuel+$0001)
FuelEmptyTest:
  AND $FC                 ; AND $FC, Z: out of fuel (the ZXDB POKE 57276 puts a
                          ; RET here)
  CP $00
  JP Z,OutOfFuel
  CP E
  RET Z
  ADD A,$90
  LD (FuelBar),A
  LD (SpriteX),A

; clear the bar's last 4 pixels (6 lines)
;
; Witness: L1 146 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
FuelBarStep:
  LD A,(SpriteX)
  LD C,$0F
  AND $04
  JR NZ,l_DFD8
  LD C,$F0
l_DFD8:
  CALL GfxTable
  LD B,$06
l_DFDD:
  LD A,C
  XOR $FF
  AND (HL)
  LD (HL),A
  INC H
  DJNZ l_DFDD
  RET
; This entry point is used by the routine at UseFuel.
OutOfFuel:
  LD A,$90                ; The bar at its start, SlowDown twice; once per
                          ; player: "OUT OF FUEL", every pass while the tank is
                          ; empty unless the player has finished (ZXDB POKE
                          ; 57318 puts a RET here: an empty tank no longer
                          ; brakes)
  LD (FuelBar),A
  LD (SpriteX),A
  CALL FuelBarStep
  CALL SlowDown
  CALL SlowDown
  LD A,(Finished)
  LD E,A
  LD A,(PlayerIndex)
  ADD A,$01
  AND E
  RET NZ
  LD A,$3C
  LD (SpriteX),A
  LD (SpriteY),A
  LD IX,OutOfFuelText
  JP PrintShadow

; Move along the trail by the speed in the facing direction, use fuel
;
; Speed under 2: no move. Forwards: Distance + speed x 128, Scenery + speed x
; 32 (ForwardList, ForwardScenery); backwards the same down. Each $1000 of
; Distance crossed scores a point up forwards, down backwards (ScoreStep).
;
; Witness: L1 6700 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Advance:
  LD A,(Speed)
  CP $02
  RET C
  LD A,(Facing)
  CP $00
  JR Z,l_E027
  CALL BackList
  CALL UseFuel
  JP BackScenery
l_E027:
  CALL ForwardList
  CALL UseFuel
  JP ForwardScenery

; Distance - speed x 128; at 0 the trail's start: stop
;
; Witness: L1 55 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash,
; warp).
BackList:
  LD A,(Speed)
  LD D,A
  LD E,$00
  SRL D
  RR E
  LD HL,(Distance)
  LD A,H
  AND $10
  LD C,A
  XOR A
  SBC HL,DE
  LD (Distance),HL
  PUSH AF
  LD A,H
  AND $10
  CP C
  CALL NZ,ScoreDown
  POP AF
  RET NC
  LD A,(TrackPos+$0001)
  SUB $01
  LD (TrackPos+$0001),A
  RET NC
  CALL ScoreStep
  PUSH DE
  LD HL,$0000
  LD (Distance),HL
  LD (TrackPos),HL
  LD (Scenery),HL
  LD (SceneryPos),HL
  CALL Stop
  POP DE
  RET

; One point off the current player's score
;
; Witness: L1 26 (fuel, kb, speedcrash, turn, wallcrash, warp).
ScoreDown:
  LD A,(PlayerIndex)
  CP $00
  JP Z,ScoreDownP1
  JP ScoreDownP2

; Scenery - speed x 32
;
; Witness: L1 55 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash,
; warp).
BackScenery:
  LD A,(Speed)
  LD D,A
  LD E,$00
  SRL D
  RR E
  SRL D
  RR E
  SRL D
  RR E
  LD HL,(Scenery)
  XOR A
  SBC HL,DE
  LD (Scenery),HL
  RET NC
  LD A,(SceneryPos+$0001)
  SUB $01
  RET C
  LD (SceneryPos+$0001),A
  RET

; Distance + speed x 128
;
; Witness: L1 1820 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ForwardList:
  LD A,(Speed)
  LD D,A
  LD E,$00
  SRL D
  RR E
  LD HL,(Distance)
  LD A,H
  AND $10
  LD C,A
  ADD HL,DE
  LD (Distance),HL
  PUSH AF
  LD A,H
  AND $10
  CP C
  CALL NZ,ScoreStep
  POP AF
  RET NC
  LD A,(TrackPos+$0001)
  ADD A,$01
  LD (TrackPos+$0001),A
  RET

; One point onto the current player's score (not after the finish): +1, shown
; as +10
;
; Witness: L1 811 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ScoreStep:
  LD A,(Finished)
  LD E,A
  LD A,(PlayerIndex)
  ADD A,$01
  AND E
  RET NZ
  LD A,(PlayerIndex)
  CP $00
  JP Z,ScoreUpP1
  JP ScoreUpP2

; Scenery + speed x 32 (Speed x 256 shifted right three times): a quarter of
; ForwardList's speed x 128
;
; Witness: L1 1820 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ForwardScenery:
  LD A,(Speed)
  LD D,A
  LD E,$00
  SRL D
  RR E
  SRL D
  RR E
  SRL D
  RR E
  LD HL,(Scenery)
  ADD HL,DE
  LD (Scenery),HL
  RET NC
  LD A,(SceneryPos+$0001)
  ADD A,$01
  RET C
  LD (SceneryPos+$0001),A
  RET

; The controls, unless the rider is falling or thrown: Left, Right, Up,
; MountCheck
;
; Witness: L1 6680 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Controls:
  LD A,(FallPhase)
  CP $00
  JR NZ,l_E11F
  LD A,(ThrowSpeed)
  CP $00
  JR NZ,l_E11F
  CALL ControlLeft
  CALL ControlRight
  CALL ControlUp
  CALL MountCheck
l_E11F:
  RET

; Left: riding, throttle facing left or brake facing right (a standstill turns
; round); on foot, walk left
;
; Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ControlLeft:
  LD A,(Mounted)
  CP $00
  JR Z,l_E14B
  LD A,(AtvFrame)
  CP $5C
  JR NZ,l_E14B
  LD A,(TurnLeft)
  CP $00
  JR Z,l_E14B
  LD A,(Facing)
  CP $01
  JR Z,l_E145
  LD A,$01
  LD (RiderFacing),A
  LD (Facing),A
  RET
l_E145:
  LD A,$38
  LD (AtvFrame),A
  RET
l_E14B:
  LD A,(PassControls)
  BIT 4,A
  JP Z,l_E1CA
  LD A,(Mounted)
  CP $01
  JP Z,l_E1A0
  LD A,(RiderJump)
  CP $00
  JR Z,l_E175
  LD A,(TurnRight)
  CP $01
  RET Z
  LD A,(RiderFacing)
  CP $00
  RET Z
  LD A,$01
  LD (TurnLeft),A
  JR l_E196
l_E175:
  LD A,(RiderFacing)
  CP $00
  JR NZ,l_E183
  LD A,$01
  LD (RiderFacing),A
  JR l_E1CA
l_E183:
  LD A,$01
  LD (RiderFacing),A
  LD A,(RiderFrame)
  ADD A,$01
  CP $08
  JR C,l_E193
  LD A,$01
l_E193:
  LD (RiderFrame),A
l_E196:
  LD A,(RiderX)
  SUB $03
  RET C
  LD (RiderX),A
  RET
l_E1A0:
  LD A,(Speed)
  CP $00
  JR Z,l_E1AB
  CALL OnGround
  RET NC
l_E1AB:
  LD A,(Facing)
  CP $00
  JR Z,l_E1B5
  JP Accelerate
l_E1B5:
  LD A,(Speed)
  SUB $01
  JR C,l_E1BF
  JP SlowDown
l_E1BF:
  LD A,$01
  LD (TurnLeft),A
  LD A,$5C
  LD (AtvFrame),A
  RET
l_E1CA:
  LD A,(RiderJump)
  CP $00
  JR Z,l_E1DA
  LD A,(TurnLeft)
  CP $00
  RET Z
  JP l_E196
l_E1DA:
  XOR A
  LD (TurnLeft),A
  LD A,(PassControls)
  BIT 3,A
  RET NZ
  LD A,(RiderFrame)
  CP $09
  RET NC
  LD A,$00
  LD (RiderFrame),A
  RET

; Right: the same the other way
;
; Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ControlRight:
  LD A,(Mounted)
  CP $00
  JR Z,l_E21B
  LD A,(AtvFrame)
  CP $5C
  JR NZ,l_E21B
  LD A,(TurnRight)
  CP $00
  JR Z,l_E21B
  LD A,(Facing)
  CP $00
  JR Z,l_E215
  LD A,$00
  LD (RiderFacing),A
  LD (Facing),A
  RET
l_E215:
  LD A,$38
  LD (AtvFrame),A
  RET
l_E21B:
  LD A,(PassControls)
  BIT 3,A
  JR Z,l_E297
  LD A,(Mounted)
  CP $01
  JR Z,l_E26D
  LD A,(RiderJump)
  CP $00
  JR Z,l_E243
  LD A,(TurnLeft)
  CP $01
  RET Z
  LD A,(RiderFacing)
  CP $01
  RET Z
  LD A,$01
  LD (TurnRight),A
  JR l_E25E
l_E243:
  LD A,(RiderFacing)
  CP $00
  JR Z,l_E250
  XOR A
  LD (RiderFacing),A
  JR l_E297
l_E250:
  LD A,(RiderFrame)
  ADD A,$01
  CP $08
  JR C,l_E25B
  LD A,$01
l_E25B:
  LD (RiderFrame),A
l_E25E:
  LD A,(RiderX)
  ADD A,$03
  CP $A0
  JR C,l_E269
  LD A,$9F
l_E269:
  LD (RiderX),A
  RET
l_E26D:
  LD A,(Speed)
  CP $00
  JR Z,l_E278
  CALL OnGround
  RET NC
l_E278:
  LD A,(Facing)
  CP $01
  JR Z,l_E282
  JP Accelerate
l_E282:
  LD A,(Speed)
  SUB $01
  JR C,l_E28C
  JP SlowDown
l_E28C:
  LD A,$01
  LD (TurnRight),A
  LD A,$5C
  LD (AtvFrame),A
  RET
l_E297:
  LD A,(RiderJump)
  CP $00
  JR Z,l_E2A6
  LD A,(TurnRight)
  CP $00
  RET Z
  JR l_E25E
l_E2A6:
  XOR A
  LD (TurnRight),A
  LD A,(PassControls)
  BIT 4,A
  RET NZ
  LD A,(RiderFrame)
  CP $09
  RET NC
  LD A,$00
  LD (RiderFrame),A
  RET

; Up: WheelieTimer = 10 and the nose up; at full nose-up ($44) the rider is
; thrown off backwards (ThrowOff: recording throwoff, frames 612-619)
;
; Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
ControlUp:
  LD A,(PassControls)
  BIT 2,A
  JR Z,WheelieCount
  LD A,(Mounted)
  CP $00
  RET Z
  LD A,$0A
  LD (WheelieTimer),A
  LD A,(AtvFrame)
  CP $5C
  RET Z
  LD A,(AtvFrame)
  CP $44
  JP NZ,WheelieUp
  LD A,(Mounted)
  CP $00
  RET Z
; This entry point is used by the routine at RiderUpdate.
ThrowOff:
  XOR A
  LD (Mounted),A
  LD A,$01
  LD (FallPhase),A
  LD E,$20
  LD A,(RiderFacing)
  CP $00
  JP Z,l_E2F7
  LD E,$00
l_E2F7:
  LD A,(RiderX)
  ADD A,$10
  SUB E
  LD (RiderX),A
  LD A,(RiderHeight)
  ADD A,$0A
  JP RiderHeightClamp
WheelieCount:
  LD A,(WheelieTimer)
  SUB $01
  RET C
  LD (WheelieTimer),A
  RET

; The rider's jump steps ($E314 on, rising $0A, $07, $04, $02, then falling
; $01...) and FallSteps ($E319: 0, 1, 2, 4, 6)
RiderJumpTable:
  INCBIN "res/tables/riderjump.bin",$0000,7
FallSteps:
  INCBIN "res/tables/riderjump.bin",$0007,6

; Lying after a throw: Jump stands the rider up (on foot)
;
; Witness: L1 294 (c1, fuel, kb, speedcrash, throwoff, trail1, trails,
; wallcrash, warp).
GetUp:
  LD A,(FallPhase)
  CP $05
  JP Z,l_E32D
  LD A,(RiderFrame)
  CP $77
  RET NZ
l_E32D:
  LD A,(PassControls)
  BIT 0,A
  RET Z
  LD A,$00
  LD (RiderFrame),A
  XOR A
  LD (Mounted),A
  LD (WheelieTimer),A
  LD (FallPhase),A
  LD (ThrowSpeed),A
  LD A,$01
  LD (JumpLatch),A
  RET

; Jump: riding on the ground, a jump (VSpeed $FD less the climb); on foot the
; rider's jump
;
; Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
JumpControl:
  LD A,(FallPhase)
  CP $00
  JP NZ,GetUp
  LD A,(ThrowSpeed)
  CP $00
  JP NZ,GetUp
  LD A,(PassControls)
  BIT 0,A
  JR NZ,l_E36E
  XOR A
  LD (JumpLatch),A
  LD A,(RiderJump)
  CP $00
  JR NZ,RiderJumpStep
  RET
l_E36E:
  LD A,(RiderJump)
  CP $00
  JR NZ,RiderJumpStep
  LD A,(VSpeed)
  CP $00
  RET NZ
  LD A,(JumpLatch)
  CP $01
  RET Z
  LD A,$01
  LD (JumpLatch),A
  LD A,(AtvFrame)
  CP $5C
  RET Z
  LD A,(Mounted)
  CP $00
  JR Z,RiderJumpStart
  LD A,$FD
  LD (VSpeed),A
  LD A,(PrevHeight)
  LD E,A
  LD A,(AtvHeight)
  SUB E
  JR C,l_E3B0
  CP $05
  JR C,l_E3A8
  LD A,$05
l_E3A8:
  LD E,A
  LD A,(VSpeed)
  SUB E
  LD (VSpeed),A
l_E3B0:
  CALL WheelieUp
  LD A,$03
  LD (WheelieTimer),A
  JP SlowDown

; A dismount no jump reaches: on foot at the ATV's height + 3
;
; Known only from the code.
DismountUnused:
  LD A,$05
  XOR A
  LD (RiderJump),A
  LD (Mounted),A
  LD A,$00
  LD (RiderFrame),A
  LD A,(AtvHeight)
  ADD A,$03
  JP RiderHeightClamp

; RiderHeight = A, at most $4F
;
; Known only from the code: no recording runs it.
;
; Witness: L1 1 (throwoff).
RiderHeightClamp:
  LD (RiderHeight),A
  CP $50
  RET C
  LD A,$4F
  LD (RiderHeight),A
  RET

; The rider's jump on foot
;
; Witness: L1 216 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderJumpStart:
  LD A,$01
  LD (RiderJump),A
  LD (JumpLatch),A
; This entry point is used by the routine at JumpControl.
RiderJumpStep:
  LD A,$18
  LD (RiderFrame),A
  LD A,(RiderJump)
  ADD A,$01
  LD (RiderJump),A
  CP $07
  JR C,l_E3FE
  LD A,$07
  LD (RiderJump),A
  JP l_E415
l_E3FE:
  CP $05
  JP NC,l_E415
  SUB $01
  LD E,A
  LD D,$00
  LD HL,RiderJumpTable+$0002
  ADD HL,DE
  LD E,(HL)
  LD A,(RiderHeight)
  ADD A,E
  LD (RiderHeight),A
  RET
l_E415:
  CP $07
  LD E,A
  JP C,l_E442
  LD A,(JumpLatch)
  CP $01
  JR Z,l_E442
  LD A,(PassControls)
  BIT 0,A
  JP Z,l_E442
  LD A,(GroundBelowRider)
  LD D,A
  LD A,(RiderHeight)
  CP D
  JP NC,l_E442
  LD A,$00
  LD (RiderFrame),A
  LD A,$02
  LD (RiderJump),A
  JP l_E3FE
l_E442:
  LD A,$09
  SUB E
  LD E,A
  LD D,$00
  LD HL,RiderJumpTable+$0002
  ADD HL,DE
  LD E,(HL)
  LD A,(RiderHeight)
  SUB E
  JR NC,l_E45A
  XOR A
  LD (GroundBelowRider),A
  JP RiderLand
l_E45A:
  LD (RiderHeight),A
  DEC HL
  LD E,(HL)
  INC E
  LD A,(GroundBelowRider)
  LD D,A
  LD A,(RiderHeight)
  SUB D
  RET C
  CP E
  RET NC
  JP RiderLand

; The rider lands on the ATV: within its x range and height, facing its way,
; falling, the ATV upright: mount
;
; Rider x in AtvX-12..AtvX+18 (8 less facing left), height AtvHeight+4..+25,
; RiderFacing = Facing, RiderJump >= 5, AtvFrame $38-$4D: Mounted = 1,
; RiderFrame $59 (c1: 20 mounts).
;
; Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
MountCheck:
  LD A,(AtvX)
  SUB $0C
  LD E,A
  ADD A,$1E
  LD D,A
  LD C,$00
  LD A,(RiderFacing)
  CP $00
  JR Z,l_E482
  LD C,$08
l_E482:
  LD A,(RiderX)
  SUB C
  CP E
  RET C
  CP D
  RET NC
  LD A,(AtvHeight)
  ADD A,$04
  LD E,A
  LD A,(AtvHeight)
  ADD A,$19
  LD D,A
  LD A,(RiderHeight)
  CP E
  RET C
  CP D
  RET NC
  LD A,(RiderFacing)
  LD E,A
  LD A,(Facing)
  CP E
  RET NZ
  LD A,(RiderJump)
  CP $05
  RET C
  LD A,(AtvFrame)
  CP $38
  RET C
  CP $4E
  RET NC
  XOR A
  LD (RiderJump),A
  LD (TurnLeft),A
  LD (TurnRight),A
  LD A,$01
  LD (Mounted),A
  LD A,$59
  LD (RiderFrame),A
  RET

; Both players' records from RecordTemplate
;
; Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
InitRecords:
  LD HL,RecordTemplate
  LD DE,RecordP1
  LD BC,$0032
  LDIR
  LD HL,RecordTemplate
  LD DE,RecordP2
  LD BC,$0032
  LDIR
  RET

; Record = RecordP1
;
; Witness: L1 9531 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
LoadRecordP1:
  LD HL,RecordP1
  LD DE,Record
  LD BC,$0032
  LDIR
  RET

; RecordP1 = Record
;
; Witness: L1 9519 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
SaveRecordP1:
  LD HL,Record
  LD DE,RecordP1
  LD BC,$0032
  LDIR
  RET

; Record = RecordP2
;
; Witness: L1 1017 (kb).
LoadRecordP2:
  LD HL,RecordP2
  LD DE,Record
  LD BC,$0032
  LDIR
  RET

; RecordP2 = Record
;
; Witness: L1 1016 (kb).
SaveRecordP2:
  LD HL,Record
  LD DE,RecordP2
  LD BC,$0032
  LDIR
  RET

; Speed 0 and the SPEED bar cleared
;
; Witness: L1 18 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).
Stop:
  LD HL,Screen
  LD (ScreenBase),HL
  LD A,$40
  LD (SpriteX),A
  LD A,(Speed)
  SRL A
  ADD A,$01
  LD B,A
l_E524:
  PUSH BC
  LD A,(HudY)
  LD (SpriteY),A
  CALL BarNibble
  LD A,(SpriteX)
  ADD A,$04
  LD (SpriteX),A
  POP BC
  DJNZ l_E524
  XOR A
  LD (Speed),A
  RET

; Speed - 2 (not under 0), the bar
;
; Witness: L1 1695 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
SlowDown:
  LD A,(Speed)
  SUB $02
  JR NC,l_E546
  XOR A
l_E546:
  LD (Speed),A
  JP SpeedBar

; Speed + 1, at most 21, the bar
;
; Witness: L1 2005 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Accelerate:
  LD A,(Speed)
  ADD A,$01
  CP $15
  JR C,l_E557
  LD A,$15
l_E557:
  LD (Speed),A
  JP SpeedBar

; Draw the SPEED bar to the speed
;
; Witness: L1 3700 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
SpeedBar:
  LD HL,Screen
  LD (ScreenBase),HL
  LD A,(HudY)
  LD (SpriteY),A
  LD A,(SpeedBarLen)
  LD (SpriteX),A
  LD E,A
  LD A,(Speed)
  SUB $01
  JR NC,l_E578
  XOR A
l_E578:
  SLA A
  AND $FC
  ADD A,$40
  CP E
  LD (SpeedBarLen),A
  JP C,BarNibble
  CP $40
  JP Z,BarNibble
  LD A,(SpriteX)
  LD C,$0E
  AND $04
  JR NZ,l_E595
  LD C,$E0
l_E595:
  CALL GfxTable
  LD B,$06
l_E59A:
  LD A,C
  OR (HL)
  LD (HL),A
  INC H
  DJNZ l_E59A
  RET

; A bar's 4-pixel step (6 lines)
;
; Witness: L1 2409 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
BarNibble:
  LD A,(SpriteX)
  LD C,$0F
  AND $04
  JR NZ,l_E5AC
  LD C,$F0
l_E5AC:
  CALL GfxTable
  LD B,$06
l_E5B1:
  LD A,C
  XOR $FF
  AND (HL)
  LD (HL),A
  INC H
  DJNZ l_E5B1
  RET

; Rising: VSpeed + 1 towards 0, the height up by FallSteps
;
; Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Rise:
  LD A,(VSpeed)
  BIT 7,A
  RET Z
  ADD A,$01
  JR NZ,l_E5CA
  LD A,$01
  LD (VSpeed),A
  RET
l_E5CA:
  LD (VSpeed),A
  XOR $FF
  ADD A,$01
  CP $06
  JR C,l_E5D7
  LD A,$05
l_E5D7:
  SUB $01
  LD E,A
  LD D,$00
  LD HL,FallSteps
  ADD HL,DE
  LD E,(HL)
  LD A,(AtvHeight)
  ADD A,E
  LD (AtvHeight),A
  RET

; Falling: VSpeed + 1 up to 5, the height down by FallSteps
;
; Witness: L1 510 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Fall:
  LD DE,l_E6F8
  PUSH DE
  LD A,(TumbleCount)
  CP $00
  RET NZ
  LD A,(VSpeed)
  ADD A,$01
  LD (VSpeed),A
  CP $06
  JR C,l_E601
  LD A,$05
l_E601:
  LD (VSpeed),A
  SUB $01
  LD E,A
  LD D,$00
  LD HL,FallSteps
  ADD HL,DE
  LD E,(HL)
  LD A,(AtvHeight)
  SUB E
  LD (AtvHeight),A
  RET NC
  XOR A
  LD (AtvHeight),A
  RET

; The wheels' x and y offsets for each ATV frame from $38 (pairs)
WheelOffsets:
  INCBIN "res/tables/wheeloffsets.bin",$0000,22

; SpriteX = the rear wheel's x
;
; Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RearX:
  LD A,(AtvX)
  ADD A,$07
  LD (SpriteX),A
  LD A,(Facing)
  CP $00
  RET Z
  LD A,(AtvX)
  SUB $07
  ADD A,$10
  LD (SpriteX),A
  RET

; SpriteX = the front wheel's x (B the frame's offset)
;
; Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
FrontX:
  LD A,(AtvX)
  ADD A,B
  ADD A,$01
  LD (SpriteX),A
  LD A,(Facing)
  CP $00
  RET Z
  LD A,(AtvX)
  SUB B
  ADD A,$16

; The left-facing tail of FrontX: LD (SpriteX),A; RET (run when the ATV faces
; left: recording turn)
;
; Witness: L1 43 (turn).
FrontXLeft:
  LD (SpriteX),A
  RET

; The thump of a landing: a tone and a noise, SlowDown
;
; Witness: L1 169 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Landing:
  XOR A
  LD (VSpeed),A
  LD C,$0A
  LD B,$05
  CALL Tone
  LD C,$0A
  CALL Noise
  JP SlowDown

; The ATV each pass: rise or fall, the ground under the wheels, landing, the
; slope, crash tests
;
; Not riderless. Rise; GroundUnder at the rear and the front wheel (GroundY the
; higher); above the ground Fall, else land (Landing when VSpeed was nonzero);
; a drop of 7 or more after a climb: Crash. Then the nose: the ground under the
; nose against the wheels gives the frame by SlopeFrames; a step of $15 or
; more: Crash; WheelieDown when the timer ran out or Down is held.
;
; Witness: L1 6680 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
AtvPhysics:
  LD A,(PrevHeight)
  LD (PrevHeight+$0001),A
  LD A,(AtvHeight)
  LD (PrevHeight),A
  LD A,(AtvFrame)
  CP $5C
  RET Z
  CALL Rise
  CALL RearX
  CALL GroundUnder
  LD A,B
  LD (GroundY+$0001),A
  PUSH AF
  LD A,(SpriteX)
  ADD A,$06
  LD (SpriteX),A
  CALL GroundUnder
  LD A,B
  LD (GroundY),A
  LD (GroundY+$0002),A
  POP AF
  CP B
  JR C,l_E6AF
  LD (GroundY),A
l_E6AF:
  LD A,(VSpeed)
  BIT 7,A
  JP NZ,l_E6F8
  LD A,(AtvHeight)
  LD E,A
  LD A,(GroundY)
  CP E
  JP C,Fall
  PUSH AF
  PUSH DE
  LD A,(VSpeed)
  CP $00
  CALL NZ,Landing
  XOR A
  LD (VSpeed),A
  POP DE
  POP AF
  JR Z,l_E6F8
  SUB E
  PUSH AF
  LD A,(PrevHeight+$0001)
  LD E,A
  LD A,(PrevHeight)
  SUB E
  JR NC,l_E6E1
  XOR A
l_E6E1:
  LD E,A
  POP AF
  SUB E
  JR C,l_E6F0
  CP $07
  JP C,l_E6F0
  CALL Crash
  JR l_E6F8
l_E6F0:
  LD A,(GroundY)
  LD (AtvHeight),A
  JR l_E6F8
l_E6F8:
  LD A,(AtvFrame)
  SUB $38
  LD E,A
  LD D,$00
  LD HL,WheelOffsets
  ADD HL,DE
  LD B,(HL)
  INC HL
  LD C,(HL)
  CALL FrontX
  LD A,(AtvHeight)
  ADD A,C
  CP $A0
  JP C,l_E714
  XOR A
l_E714:
  LD (GroundY+$0004),A
  ADD A,$08
  CP $50
  JR C,l_E71F
  LD A,$4F
l_E71F:
  LD (SpriteY),A
  CALL JpBufferAddr
  CALL GroundScan
  LD A,B
  LD (GroundY+$0003),A
  LD A,(GroundY+$0004)
  CP $00
  JR NZ,l_E741
  LD A,(AtvHeight)
  CP $03
  JP NC,NoseHigh
  LD A,$38
  LD (AtvFrame),A
  RET
l_E741:
  SUB B
  JP C,l_E75F
  CP $03
  RET C
  LD A,(WheelieTimer)
  CP $00
  JP Z,WheelieDown
  LD A,(AtvFrame)
  CP $5C
  RET Z
  LD A,(PassControls)
  BIT 1,A
  RET Z
  JP WheelieDown
l_E75F:
  LD A,(AtvFrame)
  CP $44
  RET Z
  LD A,(GroundY)
  LD B,A
  LD A,(GroundY+$0003)
  SUB B
  CP $15
  JR C,l_E774
  JP Crash
l_E774:
  LD E,A
  LD D,$00
  LD HL,SlopeFrames
  ADD HL,DE
  LD A,(AtvFrame)
  LD C,A
  SUB $46
  JR C,l_E788
  LD C,A
  LD A,$36
  SUB C
  LD C,A
l_E788:
  LD A,(HL)
  ADD A,$38
  SUB C
  RET C
  CP $06
  CALL NC,CrashIfAir
  ADD A,C
  LD (AtvFrame),A
  RET

; The frame offset for each line of slope (0-$14)
SlopeFrames:
  INCBIN "res/tables/slopeframes.bin",$0000,36

; Carry when falling at 5 lines a pass
;
; Witness: L1 60 (c1, fuel, kb, trail1, trails, turn, wallcrash, warp).
FastFall:
  LD A,(VSpeed)
  CP $80
  RET NC
  CP $05
  CCF
  RET

; The nose in the air: lift the frame
;
; Witness: L1 72 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash,
; warp).
NoseHigh:
  LD A,(AtvHeight)
  SUB $03
  CP $04
  JR C,l_E7D9
  CALL FastFall
  CALL C,CrashIfAir
  LD A,(AtvHeight)
  SUB $03
l_E7D9:
  LD E,A
  LD D,$00
  LD HL,SlopeFrames+$0015
  ADD HL,DE
  LD A,(AtvFrame)
  LD C,A
  LD A,(HL)
  ADD A,$38
  CP C
  RET NC
  LD (AtvFrame),A
  LD A,$07
  RET

; A table of multiples of 3 no code reads ($E7AC is read: SlopeFrames' tail)
SlopeTable2:
  INCBIN "res/tables/slopetable2.bin",$0000,12

; Carry when the ATV is within 4 lines of the ground
;
; Witness: L1 1928 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
OnGround:
  LD A,(GroundY)
  LD D,A
  LD A,(AtvHeight)
  SUB D
  CP $04
  RET

; Crash unless on the ground
;
; Witness: L1 9 (c1, trails).
CrashIfAir:
  LD E,A
  CALL OnGround
  LD A,E
  RET C
  POP AF
  JP Crash

; B = the height of the first ground pixel under SpriteX (a column scan of the
; buffer from the ATV's height + 8 down)
;
; Witness: L1 13352 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
GroundUnder:
  LD A,(AtvHeight)
  ADD A,$08
  CP $50
  JR C,l_E81B
  LD A,$4F
l_E81B:
  LD (SpriteY),A
  CALL JpBufferAddr

; The column scan from HL down (C the pixel mask, B lines)
;
; Witness: L1 26704 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
GroundScan:
  CALL JpPixelMask
  LD C,A
  LD A,(SpriteY)
  LD B,A
l_E829:
  PUSH BC
  LD A,C
  AND (HL)
  JR Z,l_E830
  POP BC
  RET
l_E830:
  LD DE,$0016
  ADD HL,DE
  POP BC
  DJNZ l_E829
  RET

; The nose up two frames (to $44)
;
; Witness: L1 394 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
WheelieUp:
  LD A,(AtvFrame)
  CP $46
  JR NC,l_E846
  ADD A,$02
  CP $46
  RET NC
  JR l_E84E
l_E846:
  SUB $02
  CP $46
  JR NC,l_E84E
  LD A,$38
l_E84E:
  LD (AtvFrame),A
  RET

; The nose down two frames
;
; Witness: L1 680 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
WheelieDown:
  LD A,(AtvFrame)
  CP $46
  JR C,l_E860
  ADD A,$02
  CP $4E
  RET NC
  JR l_E868
l_E860:
  SUB $02
  CP $38
  JR NC,l_E868
  LD A,$46
l_E868:
  LD (AtvFrame),A
  RET

; The tumble's frames ($7D-$87) and heights ($E884)
TumbleFrames:
  INCBIN "res/tables/tumbleframes.bin",$0000,24
TumbleHeights:
  INCBIN "res/tables/tumbleframes.bin",$0018,24

; The tumble: 24 passes of TumbleFrames, slowing; then upright ($44) on the
; ground, stopped
;
; Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
Tumble:
  LD A,(TumbleCount)
  CP $00
  RET Z
  CP $0A
  JR C,l_E8AC
  CALL SlowDown
  CALL SlowDown
l_E8AC:
  LD A,(TumbleCount)
  CP $18
  JR C,l_E8D2
  LD A,(GroundY)
  LD E,A
  LD A,(AtvHeight)
  SUB E
  JR C,l_E8C0
  CP $04
  RET NC
l_E8C0:
  XOR A
  LD (TumbleCount),A
  LD A,$44
  LD (AtvFrame),A
  LD A,(GroundY)
  LD (AtvHeight),A
  JP Stop
l_E8D2:
  ADD A,$01
  LD (TumbleCount),A
  CALL OnGround
  JR NC,l_E8E8
  LD A,$85
  LD (AtvFrame),A
  CALL SlowDown
  CALL SlowDown
  RET
l_E8E8:
  LD A,(TumbleCount)
  SUB $02
  LD E,A
  LD D,$00
  LD HL,TumbleFrames
  ADD HL,DE
  LD A,(HL)
  LD (AtvFrame),A
  LD HL,TumbleHeights
  ADD HL,DE
  LD E,(HL)
  SLA E
  LD A,(AtvHeight)
  ADD A,E
  CP $A0
  JR C,l_E908
  XOR A
l_E908:
  LD (AtvHeight),A
  RET

; RiderGround under the mounted rider
;
; Witness: L1 2325 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderGroundMounted:
  LD A,(RiderHeight)
  ADD A,$20
  CP $50
  JR C,l_E917
  LD A,$4F
l_E917:
  LD (SpriteY),A
  JR l_E92A

; RiderGround under the rider on foot
;
; Witness: L1 4351 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails,
; turn, wallcrash, warp).
RiderGround:
  LD A,(RiderHeight)
  ADD A,$07
  CP $50
  JR C,l_E927
  LD A,$4F
l_E927:
  LD (SpriteY),A
; This entry point is used by the routine at RiderGroundMounted.
l_E92A:
  LD A,(RiderX)
  ADD A,$0C
  LD (SpriteX),A
  LD A,(RiderFacing)
  CP $00
  JR Z,l_E941
  LD A,(RiderX)
  ADD A,$04
  LD (SpriteX),A
l_E941:
  CALL JpBufferAddr
  CALL GroundScan
  LD A,B
  LD (GroundBelowRider),A
  RET

; A crash: back one step, SlowDown; then under 10 stop, 10-14 stop and throw,
; 15 and up tumble and throw (the speed after the -2)
;
; c1: 19 crashes (trail1, fuel, trails: see NOTES).
;
; Witness: L1 21 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).
Crash:
  LD A,(Facing)
  XOR $01
  LD (Facing),A
  CALL Advance
  LD A,(Facing)
  XOR $01
  LD (Facing),A
  CALL SlowDown
  LD A,(Speed)
  CP $0A
  JP C,Stop
  CP $0F
  JR NC,l_E974
  CALL Stop
  JP Throw
l_E974:
  LD A,(TumbleCount)
  CP $00
  RET NZ
  LD A,(PrevHeight)
  LD (AtvHeight),A
  LD A,(AtvHeight)
  ADD A,$05
  LD (AtvHeight),A
  LD A,$01
  LD (TumbleCount),A
  CALL Throw
  RET

; The rider falling after ThrowOff (FallPhase 1-5; recording throwoff: 35 runs)
;
; Known only from the code.
;
; Witness: L1 35 (throwoff).
FallRider:
  CALL RiderGround
  XOR A
  LD (WheelieTimer),A
  CALL SlowDown
  CALL SlowDown
  LD A,(Speed)
  CP $00
  JR Z,l_E9B1
  SRL A
  LD E,A
  LD A,(RiderX)
  SUB E
  JR C,l_E9B1
  LD (RiderX),A
l_E9B1:
  LD A,(RiderHeight)
  LD E,A
  LD A,(GroundBelowRider)
  SUB E
  JR NZ,l_E9C1
  LD A,$77
  LD (RiderFrame),A
  RET
l_E9C1:
  LD A,$64
  LD (RiderFrame),A
  LD A,(FallPhase)
  ADD A,$01
  CP $06
  JR C,l_E9D6
  LD A,$64
  LD (RiderFrame),A
  LD A,$05
l_E9D6:
  LD (FallPhase),A
  SUB $02
  LD E,A
  LD D,$00
  LD HL,FallSteps
  ADD HL,DE
  LD E,(HL)

; RiderHeight - E, not below the ground
;
; Witness: L1 155 (c1, fuel, kb, speedcrash, throwoff, trail1, trails,
; wallcrash, warp).
RiderToGround:
  LD A,(GroundBelowRider)
  LD D,A
  LD A,(RiderHeight)
  SUB E
  JR NC,l_E9EE
  XOR A
l_E9EE:
  LD (RiderHeight),A
  CP D
  RET NC
  LD A,(GroundBelowRider)
  LD (RiderHeight),A
  RET

; Throw the rider off: ThrowSpeed $F8 - speed / 8, on foot
;
; Witness: L1 14 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).
Throw:
  LD A,(ThrowSpeed)
  CP $00
  RET NZ
  LD A,(Mounted)
  CP $00
  RET Z
  LD A,$F8
  LD (ThrowSpeed),A
  LD A,(Speed)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD A,(ThrowSpeed)
  SUB E
  LD (ThrowSpeed),A
  XOR A
  LD (Mounted),A
  RET

; The thrown rider's flight: forwards 4 a pass, up then down, the tumbling
; frames $5E-$64; lying ($77) when he lands
;
; Witness: L1 259 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).
Thrown:
  CALL RiderGround
  LD A,(RiderHeight)
  LD E,A
  LD A,(GroundBelowRider)
  CP E
  JR Z,l_EAA4
  LD A,(RiderX)
  ADD A,$04
  CP $88
  JR NC,l_EA3A
  LD (RiderX),A
l_EA3A:
  LD A,(ThrowSpeed)
  AND $01
  JR NZ,l_EA5C
  LD DE,l_EA5C
  PUSH DE
  LD A,(RiderFrame)
  CP $5E
  JR C,l_EA56
  CP $64
  JR NC,l_EA56
  ADD A,$02
  LD (RiderFrame),A
  RET
l_EA56:
  LD A,$5E
  LD (RiderFrame),A
  RET
l_EA5C:
  LD A,(ThrowSpeed)
  BIT 7,A
  JP Z,l_EA7F
  ADD A,$01
  JR NZ,l_EA6D
  LD (ThrowSpeed),A
  JR l_EA8B
l_EA6D:
  LD (ThrowSpeed),A
  XOR $FF
  ADD A,$01
  CALL FlightStep
  LD A,(RiderHeight)
  ADD A,E
  LD (RiderHeight),A
  RET
l_EA7F:
  LD A,(RiderHeight)
  LD E,A
  LD A,(GroundBelowRider)
  CP E
  JR C,l_EA8B
  JR l_EAA4
l_EA8B:
  LD A,(ThrowSpeed)
  ADD A,$01
  LD (ThrowSpeed),A
  CALL FlightStep
  CALL RiderToGround
  LD A,(RiderHeight)
  LD E,A
  LD A,(GroundBelowRider)
  CP E
  RET NZ
  JR l_EAA4
l_EAA4:
  LD A,$77
  LD (RiderFrame),A
  XOR A
  LD (ThrowSpeed),A
  RET

; E = FallSteps[min(A, 5) - 1]
;
; Witness: L1 259 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).
FlightStep:
  CP $06
  JR C,l_EAB4
  LD A,$05
l_EAB4:
  SUB $01
  LD E,A
  LD D,$00
  LD HL,FallSteps
  ADD HL,DE
  LD E,(HL)
  RET
