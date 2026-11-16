; --------------------------------------------------------------------------------------------------------------------
; race.asm: A stage: the start, the pass loop, the countdown, the collisions, the HUD, the timer, the stage's end and the finish
;
; StartRace (from PlayTurn, and again at each stage start) switches RowTable to the back buffer, sets the horizon and
; the stage's routines (StageParams patches the calls of RaceLoop and the off-road jump), colours the ground, places
; the riders (a new turn) and decodes the first segment; with Countdown bit 7 (after a fall) the bike resumes at FallX
; through GetUp.
;
; RaceLoop is one pass: the countdown (16 passes of digits 3, 2, 1, GO in attribute blocks, beeps), PassCount + 1,
; ScrollStep = SPEED * 14, the AY effect, AdvanceTrack, ScrollBends, the row builder, the road, the ground's dots,
; MoveRiders (after the countdown), DrawRiders, BikeControl and DrawBike, the dust and the splash, the horizon's
; rotation, the object walk (draw and collide), the rider collisions, the HUD's flashing words, the copy to the screen
; and the horizon, the finish run, the score (the speed's digits each pass), the controls (pause, reset), the speed,
; the timer every 10 passes. c1's passes take 8.0 frames on average (6-12; 648 passes over frames 14075-19265); the
; heaviest (12 frames at 17143, 18151, 18911, 13 at 15169 with the crash noise) are passes with many rows and objects
; on screen or a sound effect (doc 04 4.6, 4.7).
;
; The timer (Timer, BCD seconds) counts down once every 10 passes, so a "second" is 10 passes (about 80 frames); a
; stage's end adds 50 (at most 99) and shows EXTENDED PLAY; the time bonus puts the timer's tens and units as the 100
; 000s and 10 000s digits of the score: 10 000 points a second left. The stage's time (StageTime) is kept for the lap
; table. Game over is the timer at 0 with the bike stopped.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A143

; Draw an 8-line glyph at HL as attribute blocks ($52) at DE (C lines:
; CountGlyphC)
;
; Witness: L1 32 (c1, crash, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).
CountGlyph:
  LD C,$08

; The same with C preset (the digits' 10 lines)
;
; Witness: L1 616 (c1, crash, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, twoplayer).
CountGlyphC:
  LD A,$52
  LD B,$08
l_A149:
  RLC (HL)
  JR NC,l_A14E
  LD (DE),A
l_A14E:
  INC E
  DJNZ l_A149
  LD A,E
  ADD A,$18
  LD E,A
  JR NC,l_A158
  INC D
l_A158:
  INC HL
  DEC C
  JR NZ,CountGlyphC
  RET

; The AY effect's five pairs: 7 = $07 (noise on A, B, C), 6 = $1F, volumes 8,
; 9, 10 = 15
AyEffect:
  INCBIN "res/tables/ayeffect.bin",$0000,10

; Write E AY pairs from HL (as AyWrite, ports loaded each time)
;
; Witness: L1 1580 (c1, crash, fall5, m128, stages, tech-land-wheelie,
; tech-ramp-wheelie, truck, twoplayer).
AyPairs:
  LD A,(HL)
  LD BC,$FFFD
  OUT (C),A
  INC HL
  LD A,(HL)
  LD BC,$BFFD
  OUT (C),A
  INC HL
  DEC E
  JR NZ,AyPairs
  RET

; EffectTime = A (1 a fall, 2 a bounce or a landing), and the AY's noise on
; through AyEffect
;
; On the 48K the AY writes reach nothing; the 48K hears CrashSound instead.
;
; Witness: L1 316 (c1, crash, fall5, m128, stages, tech-land-wheelie,
; tech-ramp-wheelie, truck, twoplayer).
PlayEffect:
  LD (EffectTime),A
  EXX
  LD E,$05
  LD HL,AyEffect
  CALL AyPairs
  EXX
  RET

; The five stages' routines: road, row builder, off-road, the ground's
; attribute, the copy mode, 2 bytes unused
;
; Stage 1: DrawRoad, RoadRowsCrest, OffRoad, $20; 2: the same, $30; 3:
; DrawRoad, RoadRowsJump, OffRoadSand, $28; 4: as 1, $70; 5: RoadNone,
; RoadRowsCrest, OffRoadStage5, $30. Byte 7 (BlitMode's JR) is 0 on all.
; src/res/tables/stageparams.csv.
StageParams:
  INCBIN "res/tables/stageparams.bin",$0000,50

; Each object type's half width and height for the bike's collision (8 types):
; the ramp $20 x 1 ...
;
; Type 0 (ramp) 32 x 1, 1: 5 x 6, 2: 10 x 32, 3: 8 x 32, 4: 14 x 8, 5: 8 x 24,
; 6: 11 x 12, 7: 11 x 30. A hit within half the width is head-on (a fall at 35
; km/h or more), else side-on (a bounce).
CollisionSizes:
  INCBIN "res/tables/collisions.bin",$0000,16

  ORG $A1CC

; EXTENDED PLAY (13 characters, flashed after a stage's end)
ExtendedText:
  INCBIN "res/texts/extended.bin",$0000,13

  ORG $A45D

; A stage's start: RowTable to the back buffer, the horizon, the riders (a new
; turn), StageParams, the ground, the first segment
;
; EffectTime 0 / EffectStep 15; flags cleared; pose 3; SetHorizon,
; DrawHorizonAt 40. A demo or a new turn (Countdown nonzero): the riders
; cleared and set from RiderStarts (rider 4 from stage 2, rider 5 from stage 4,
; both in the demo); StageStart: TimerAtStart. Then StageParams patch the row
; builder's and the road's CALLs and the off-road JP, the HUD row's attributes
; $68 and the ground's (not stage 5); SplashOn and BendOp on stages 2 and 4;
; ClearBendRows, RoadRowsFlat, the first segment (SetBendDir, then
; SegmentDecode or, resuming, LateralX from FallX); the bend rows of a segment
; begun mid-bend.
;
; Witness: L1 25 (c1, crash, ctl, fall5, m128, stages, truck, twoplayer).
StartRace:
  LD HL,$0F00
  LD (EffectTime),HL
  LD DE,$A600
  CALL SetRowTable
  XOR A
  LD (CheatStep+$0001),A
  LD (ExtendedTime),A
  LD (FallTime),A
  LD (JumpHeight+$0001),A
  LD (LateralX+$0001),A
  LD (Lean),A
  LD A,$03
  LD (Pose),A
  CALL SetHorizon
  LD A,$28
  CALL DrawHorizonAt
  LD A,(HorizonBottom)
  LD (TopClip),A
  LD (DrawnTop),A
  LD A,(DemoMode)
  AND A
  JR NZ,l_A49F
  LD A,(Countdown)
  AND $7F
  JR Z,l_A4E0
l_A49F:
  LD HL,Riders
  PUSH HL
  POP IX
  LD DE,Riders+$0001
  LD BC,$0059
  LD (HL),B
  LDIR
  LD A,$C0
  LD (IX+$40),A
  LD (IX+$4F),A
  LD HL,RiderStarts
  LD BC,$0603
  LD DE,$000F
l_A4BF:
  LD A,(HL)
  INC HL
  LD (IX+$02),A
  LD A,(HL)
  INC HL
  LD (IX+$07),A
  LD A,(HL)
  INC HL
  LD (IX+$08),A
  LD A,(HL)
  INC HL
  LD (IX+$0A),A
  LD (IX+$09),C
  ADD IX,DE
  DJNZ l_A4BF
; This entry point is used by the routine at StageEnd.
StageStart:
  LD HL,(Timer)           ; each stage (StageEnd comes back here)
  LD (TimerAtStart),HL
l_A4E0:
  CALL SetHorizon
  CALL SetTune
  LD IX,StageParams
  LD A,(Stage)
  LD L,$0A
  CALL Multiply
  ADD IX,DE
  LD A,(IX+$07)
  LD (BlitMode+$0001),A
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (RoadCall+$0001),HL
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD (RowBuilderCall+$0001),HL
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD (OffRoadJump+$0001),HL
  LD HL,$58A0
  LD DE,$58A1
  LD BC,$011F
  LD (HL),$68
  LDIR
  INC DE
  INC HL
  LD A,(Stage)
  CP $04
  JR Z,l_A534
  LD BC,$013F
  LD A,(IX+$06)
  LD (HL),A
  LDIR
l_A534:
  XOR A
  LD L,A
  LD H,A
  LD (BounceTime),A
  LD (Wheelies),A
  LD (SkidLevel),A
  LD (InGap),A
  LD (GetUp),A
  LD (HeldKeys+$0001),A
  LD A,$08
  LD (RoadTopRow),A
  LD (BounceSpeed+$0001),HL
  LD (HorizonScrollStep+$0001),HL
  LD (JumpSpeed),HL
  LD (ScoreDigits+$0001),HL
  LD A,(Stage)
  LD B,A
  RRA
  LD A,$87
  JR C,l_A564
  XOR A
l_A564:
  LD (SplashOn),A
  LD (BendOp),A
  LD IX,Riders
  LD A,(DemoMode)
  AND A
  JR NZ,l_A575
  LD A,B
l_A575:
  LD BC,$8181
  INC A
  SRL A
  JR Z,l_A583
  LD B,$01
  DEC A
  JR Z,l_A583
  LD C,B
l_A583:
  LD (IX+$3C),B
  LD (IX+$4B),C
  CALL ClearBendRows
  CALL RoadRowsFlat
  LD HL,(StageListPtr)
  LD B,(HL)
  CALL SetBendDir
  LD A,(DemoMode)
  AND A
  JR NZ,l_A5C0
  LD A,(Countdown)
  RLA
  JR NC,l_A5C0
  LD (Countdown),A
  LD A,(FallX)
  ADD A,$80
  CP $5C
  JR NC,l_A5B0
  LD A,$5C
l_A5B0:
  CP $A4
  JR C,l_A5B6
  LD A,$A3
l_A5B6:
  SUB $80
  LD (GetUp),A
  LD (LateralX+$0001),A
  JR l_A5C3
l_A5C0:
  CALL SegmentDecode
l_A5C3:
  LD A,(BendPrev)
  AND A
  JR NZ,l_A5EB
  LD A,(Bend)
  AND A
  JR Z,RaceLoop
  ADD A,$FA
  LD H,A
  LD L,$00
  SRL H
  RR L
  LD A,(SegmentLeft+$0001)
  ADD A,$80
  JR C,RaceLoop
  LD E,A
  LD D,$5B
  LD B,$00
  NEG
  LD C,A
  LDIR
  JR RaceLoop
l_A5EB:
  ADD A,$FA
  LD H,A
  LD BC,$0080
  LD L,B
  SRL H
  RR L
  LD DE,BendRows
  LDIR
  CALL BlendBend
; This entry point is used by the routines at HudPlayer, RaceQuit and StageEnd.
RaceLoop:
  LD A,(Countdown)        ; one pass
  AND A
  JR Z,RaceCount
  DEC A
  LD (Countdown),A
  JR Z,l_A610
  AND $03
  CP $03
  JR NZ,RaceCount
l_A610:
  LD HL,$5900             ; the countdown's display: the attribute rows
                          ; cleared, then GO or the digit
  LD DE,$5901
  LD BC,$00BF
  LDIR
  INC L
  INC E
  LD C,$7F
  LDIR
  LD HL,CountGlyphs
  LD A,(Countdown)
  AND A
  JR Z,RaceCount
  AND $1C
  JR NZ,l_A63C
  LD DE,$5927
  CALL CountGlyph
  LD DE,$5931
  CALL CountGlyph
  JR RaceCount
l_A63C:
  AND $0C
  LD L,A
  RR L
  ADD A,A
  ADD A,L
  ADD A,$06
  LD L,A
  LD DE,$590C
  LD C,$0A
  CALL CountGlyphC
RaceCount:
  LD HL,PassCount         ; PassCount + 1; CAPS SHIFT held: CheatKey
  INC (HL)
  LD A,$FE
  IN A,($FE)
  RRA
  JR C,RaceStep

; CAPS SHIFT and Q: toggle CheatStep on every pass both read down (a fixed
; ScrollStep of $1000 on stages 1-3)
;
; A step of $1000 is SPEED 293, faster than the throttle gives; it also makes
; BikeControl read SteerTable at $8E7D, past its end, and BikeLateralPush push
; with $10. The recording tech-cheat holds CAPS SHIFT + Q at frame 126.
;
; Witness: L1 1 (tech-cheat).
CheatKey:
  LD A,$FB
  IN A,($FE)
  RRA
  JR C,RaceStep
  LD A,(CheatStep+$0001)
  CPL
  LD (CheatStep+$0001),A

; ScrollStep = SPEED * 14 (CheatStep: $1000)
;
; Witness: L1 5203 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
RaceStep:
  LD A,(Speed+$0001)
  LD L,$0E
  CALL Multiply
CheatStep:
  LD A,$00                ; LD A,n: n = 0 or $FF (CheatKey)
  AND A
  JR Z,RacePass

; Stages 1-3 with CheatStep: DE = $1000
;
; Witness: L1 51 (tech-cheat).
CheatFixedStep:
  LD A,(Stage)
  CP $03
  JR NC,RacePass
  LD DE,$1000

; ScrollStep stored; AyEffectTick, AdvanceTrack, ScrollBends, the row builder,
; the road, GroundTexture, MoveRiders, DrawRiders, the bike, dust, splash,
; horizon, BikeHitX
;
; Witness: L1 5203 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
RacePass:
  LD (ScrollStep),DE
  CALL AyEffectTick
  CALL AdvanceTrack
  CALL ScrollBends
RowBuilderCall:
  CALL RoadRowsJump       ; CALL nn: StageParams' row builder
RoadCall:
  CALL DrawRoad           ; CALL nn: StageParams' road routine
  CALL GroundTexture
  LD A,(Countdown)
  CP $08
  CALL C,MoveRiders
  CALL DrawRiders
  LD A,(Stage)
  CP $05
  JR Z,l_A6AC
  CALL BikeControl
  CALL DrawBike
l_A6AC:
  LD A,(SkidLevel)
  AND A
  CALL NZ,DrawDust
  LD A,(SplashOn)
  AND A
  CALL NZ,DrawSplash
  CALL HorizonScrollStep
  LD A,(LateralX+$0001)
  LD L,$C0
  BIT 7,A
  JR NZ,l_A6CE
  CALL Multiply
  LD A,D
  NEG
  JR l_A6D4
l_A6CE:
  NEG
  CALL Multiply
  LD A,D
l_A6D4:
  ADD A,$82
  LD (BikeHitX),A
ObjectWalk:
  LD A,(VarObject)        ; the drawing walk of the track from the bike:
                          ; DrawTrackPtr, DrawStack, JumpRows reset, GapMarks
                          ; $7F
  PUSH AF
  LD HL,JumpRows
  LD (JumpRowPtr),HL
  LD HL,StackArea+$007F
  LD (JumpRows),HL
  LD (JumpRows+$0002),HL
  LD H,$7F
  LD (GapMarks),HL
  LD HL,TrackStack
  LD DE,DrawStack
  LD BC,$000D
  LDIR
  LD HL,(ScrollStep)
  LD DE,(TrackDistance)
  ADD HL,DE
  LD C,H
  INC C
  LD A,D
  NEG
  LD B,A
  LD HL,(TrackPtr)
  JR l_A71A
; This entry point is used by the routine at RampSpeed.
ObjectNext:
  LD IX,DrawStack         ; TrackStep on the drawing walk
  LD HL,(DrawTrackPtr)
  CALL TrackStep
  POP BC
l_A71A:
  LD (DrawTrackPtr),HL
  LD A,(HL)
  AND $0F
  ADD A,A
  ADD A,B
  LD B,A
  CP $80
  JP NC,RiderHits
  LD A,(HL)               ; the element's type: its list from ObjectTypes; type
                          ; 0 rows to JumpRows; DrawObject
  RRA
  RRA
  RRA
  AND $1E
  CP $14
  JR NZ,l_A735
  LD A,(VarObject)
l_A735:
  LD E,A
  LD D,$00
  AND A
  LD A,B
  PUSH HL
  PUSH BC
  INC HL
  LD B,(HL)
  JR NZ,l_A748
  LD HL,(JumpRowPtr)
  LD (HL),A
  INC HL
  LD (JumpRowPtr),HL
l_A748:
  LD HL,ObjectTypes
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD IXH,D
  LD IXL,E
  CALL DrawObject
  POP BC
  POP HL
ObjectHit:
  PUSH BC                 ; the elements on the bike's row: collision with
                          ; CollisionSizes
  LD A,(TrackDistance+$0001)
  ADD A,B
  CP C
  JR NC,ObjectNext
  LD A,(Speed+$0001)
  AND A
  JR Z,ObjectNext
  LD A,(HL)
  INC HL
  RRA
  RRA
  RRA
  AND $1E
  CP $14
  JR NZ,l_A774
  LD A,(VarObject)
l_A774:
  LD E,A
  LD D,$00
  AND A
  EX AF,AF'
  LD IX,CollisionSizes
  ADD IX,DE
  LD A,(HL)
  ADD A,$80
  LD E,A
  LD A,(RoadLines)
  LD D,A
  LD A,(JumpHeight+$0001)
  AND A
  JR Z,l_A78E
  SUB D
l_A78E:
  CP (IX+$01)
  JP NC,ObjectNext
  LD A,(GetUp)
  AND A
  JP NZ,ObjectNext
  LD A,(BikeHitX)
  SUB E
  LD E,$08
  JR NC,l_A7A7
  LD E,$04
  NEG
l_A7A7:
  CP (IX+$00)
  JP NC,ObjectNext
  EX AF,AF'
  JR Z,Ramp
  LD A,(DemoMode)
  AND A
  JP NZ,ObjectNext
  EX AF,AF'
  ADD A,A
  CP (IX+$00)
  JR C,l_A7CF
Bounce:
  LD L,$03                ; side-on or slow: BounceTime 3, BounceDir,
                          ; PlayEffect 2, CrashSound
  LD H,E
  LD (BounceTime),HL
  LD A,$02
  CALL PlayEffect
  CALL CrashSound
  JP ObjectNext
l_A7CF:
  LD A,(Speed+$0001)      ; head-on: 35 km/h or more is a fall
  CP $23
  JR C,Bounce
  LD A,$01
  CALL PlayEffect
  CALL Crash
  JP ObjectNext
Ramp:
  LD A,D                  ; a ramp: JumpHeight from RoadLines[0], pose 1 (3 or
                          ; more wheelie passes) or 2, SPEED kept by the
                          ; wheelie, JumpSpeed = SPEED / 32 + $10
  CPL
  ADD A,$C2
  LD (JumpHeight+$0001),A
  LD A,(DemoMode)
  AND A
  JR NZ,l_A7F1
  LD A,(Wheelies)
l_A7F1:
  LD C,A
  CP $03
  LD A,$01
  JR NC,l_A7F9
  INC A
l_A7F9:
  LD (Pose),A
  LD A,(BounceTime)
  AND A
  LD A,C
  JR Z,l_A804
  XOR A
l_A804:
  CP $08
  JR C,RampSpeed

; Wheelies capped at 8
;
; The recording tech-ramp-wheelie holds WHEELIE 13 passes before the ramp at
; its frame 1 412.
;
; Witness: L1 1 (tech-ramp-wheelie).
RampCap:
  LD A,$08

; SPEED * (8 * Wheelies - $40 + 256) / 256 (8 or more: unchanged), JumpSpeed,
; PrintSpeed, PlayEffect 2, CrashSound
;
; Witness: L1 19 (c1, crash, m128, stages, tech-land-wheelie,
; tech-ramp-wheelie, truck).
RampSpeed:
  ADD A,A
  ADD A,A
  ADD A,A
  SUB $40
  LD L,A
  LD A,(Speed+$0001)
  JR Z,l_A81C
  CALL Multiply
  LD A,D
  LD (Speed+$0001),A
l_A81C:
  RLCA
  RLCA
  RLCA
  AND $07
  ADD A,$10
  LD (JumpSpeed+$0001),A
  CALL PrintSpeed
  LD A,$02
  CALL PlayEffect
  LD D,$C0
  CALL CrashSoundD
  CALL NC,AyEffectTick
  JP ObjectNext
; This entry point is used by the routine at RacePass.
RiderHits:
  POP AF                  ; the riders on the bike's row (not in the air, not
                          ; getting up, not in a demo): a truck closer than 9
                          ; is a fall, a rider closer than 5 a bounce and SPEED
                          ; - SPEED / 4
  LD (VarObject),A
  LD A,(JumpHeight+$0001)
  AND A
  JR NZ,HudFlash
  LD A,(GetUp)
  AND A
  JR NZ,HudFlash
  LD A,(DemoMode)
  AND A
  JR NZ,HudFlash
  LD IX,Riders
  LD B,$06
; This entry point is used by the routine at RiderBounce.
l_A855:
  BIT 7,(IX+$00)
  JR NZ,l_A8B4
  LD A,(ScrollStep+$0001)
  CP (IX+$04)
  JR C,l_A8B4
  CP (IX+$06)
  JR C,l_A8B4
  LD A,(IX+$0C)
  AND A
  JR NZ,l_A8B4
  LD A,(IX+$02)
  ADD A,$80
  LD D,A
  LD E,$08
  LD A,(BikeHitX)
  SUB D
  JR NC,l_A880
  NEG
  LD E,$04
l_A880:
  BIT 0,(IX+$00)
  JR Z,l_A894
  CP $09
  JR NC,l_A8B4
  LD A,$01
  CALL PlayEffect

; A truck head-on: Crash
;
; The trucks met in stages and reset3 were under the Immune To Trucks POKE,
; which turns this CALL into LD BC,nn (POKE 43151,1); the recording truck puts
; the byte back and meets a truck head-on at its frame 1 240.
;
; Witness: L1 5 (stages, truck).
TruckCrash:
  CALL Crash

; JR to the HUD
;
; Witness: L1 5 (stages, truck).
RiderBounce:
  JR HudFlash
; This entry point is used by the routine at RampSpeed.
l_A894:
  CP $05
  JR NC,l_A8B4
  LD L,$03
  LD H,E
  LD (BounceTime),HL
  LD HL,Speed+$0001
  LD A,(HL)
  RRA
  RRA
  AND $3F
  NEG
  ADD A,(HL)
  LD (HL),A
  LD A,$02
  CALL PlayEffect
  CALL CrashSound
  JR HudFlash
; This entry point is used by the routine at RampSpeed.
l_A8B4:
  LD DE,$000F
  ADD IX,DE
  DJNZ l_A855
; This entry point is used by the routine at RampSpeed.
HudFlash:
  LD A,(PassCount)        ; every 8 passes: DEMO, or nUP with two players, at
                          ; column 28
  AND $04
  JR NZ,ExtendedPlay
  LD BC,$1CB0
  LD A,(DemoMode)
  AND A
  JR Z,HudPlayer
  LD DE,$0420
  LD HL,DemoText
  CALL PrintString
  JR ExtendedPlay

; DEMO
DemoText:
  INCBIN "res/texts/demo.bin",$0000,4

; Two players: PlayerChar, U, P (the font's own glyphs for "UP")
;
; Witness: L1 2433 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
HudPlayer:
  LD A,(Players)
  DEC A
  JR Z,ExtendedPlay
  LD A,(PlayerChar)
  CALL PrintGlyph
  LD A,$55
  CALL PrintGlyph
  LD A,$50
  CALL PrintGlyph
; This entry point is used by the routine at RiderBounce.
ExtendedPlay:
  LD A,(ExtendedTime)     ; ExtendedTime: EXTENDED PLAY flashing and LAPTIME,
                          ; with a beep
  AND A
  JR Z,CountdownBeeps
  DEC A
  LD (ExtendedTime),A
  BIT 1,A
  JR Z,l_A91F
  CP $14
  JR C,l_A90B
  RRA
  JR C,l_A90B
  LD DE,$6080             ; the beep: D = $60 edges, E = $80 turns (not an
                          ; address)
  CALL BeepTone
l_A90B:
  LD BC,$0948
  LD HL,TopClip
  LD A,C
  CP (HL)
  JR NC,l_A916
  LD (HL),A
l_A916:
  LD HL,ExtendedText
  LD DE,$0D68
  CALL PrintString
l_A91F:
  LD HL,LapTexts+$0011
  LD DE,$0F68
  LD BC,$0858
  CALL PrintString
CountdownBeeps:
  LD A,(Countdown)        ; Countdown AND 3 = 2: a beep (64 x $E0 for 3-2-1,
                          ; 256 x $70 for GO)
  LD C,A
  AND $03
  CP $02
  JR NZ,l_A948
  LD A,C
  CP $04
  LD DE,$40E0
  JR NC,l_A940
  LD DE,$0070
l_A940:
  CALL BeepTone
  LD A,C
  CP $04
  JR NC,FinishCheck
l_A948:
  CALL CopyBuffer         ; CopyBuffer and DrawHorizon; DrawnTop, TopClip =
                          ; HorizonBottom
  CALL DrawHorizon
  LD A,(TopClip)
  LD (DrawnTop),A
  LD A,(HorizonBottom)
  LD (TopClip),A
FinishCheck:
  LD A,(Stage)            ; Stage 5 (after the finish): the leading rider's
                          ; distance below $40 ends the game
  CP $05
  JR NZ,ScoreAdd
FinishRider:
  LD IX,$0000             ; LD IX,nn: nn = the rider with the largest row byte
                          ; (StageEnd at the finish)
  LD A,(IX+$04)
  CP $40
  JP C,RaceLoop
  XOR A
  LD (Timer),A
  JP RaceEnd
ScoreAdd:
  LD A,(FallTime)         ; not falling: ScoreDigits = the speed's digits
                          ; (hundreds, tens, units; one place higher in the
                          ; air: SPEED x 10), AddScore
  AND A
  JR NZ,RaceControls
  LD (ScoreDigits+$0006),A
  LD HL,ScoreDigits+$0003
  LD (HL),A
  LD A,(JumpHeight+$0001)
  AND A
  JR NZ,l_A988
  INC HL
l_A988:
  LD A,(Speed+$0001)
  LD (HL),$00
  CP $64
  JR C,l_A994
  SUB $64
  INC (HL)
l_A994:
  INC HL
  LD (HL),$00
l_A997:
  CP $0A
  JR C,l_A9A0
  SUB $0A
  INC (HL)
  JR l_A997
l_A9A0:
  INC HL
  LD (HL),A
  LD HL,ScoreDigits+$0006
  CALL AddScore
RaceControls:
  LD A,(DemoMode)         ; the demo: a key ends it (Menu); else ReadControls
                          ; into HeldKeys; RESET: RaceEnd, Menu
  AND A
  JR Z,l_A9B9
  CALL KeyOrFire
  POP HL
  JR NZ,RaceQuit
  PUSH HL
  LD D,$03
  JR Throttle
l_A9B9:
  CALL ReadControls
  LD A,D
  LD (HeldKeys+$0001),A
  AND $40

; The $28 of JR Z,Pause; its operand $08 is EX AF,AF' at $A9C3, where a demo's
; key jumps
;
; L1 has $A9C2 executed in every recording and $A9C3 in c1, ctl and m128 (the
; demo ended by a key); the kit keeps $A9C2 as a byte because two instructions
; share $A9C3.
PauseJump:
  DEFB $28

; A key in the demo or RESET: RaceEnd, then Menu
;
; Witness: L1 3 (c1, ctl, m128).
RaceQuit:
  EX AF,AF'
  POP HL
  POP HL
  CALL RaceEnd
  JP Menu
Pause:
  BIT 5,D                 ; PAUSE: TuneRequest 0, GetKey, SetTune
  JR Z,Throttle
  XOR A
  LD (TuneRequest),A
  CALL GetKey
  CALL SetTune
  LD D,$00
; This entry point is used by the routine at HudPlayer.
Throttle:
  LD HL,(Speed)           ; SPEED from THROTTLE and BRAKES (not in the air, the
                          ; countdown or getting up); at Timer 0 the bike rolls
                          ; to a stop ($940 a pass)
  LD A,(JumpHeight+$0001)
  AND A
  JR NZ,l_AA3F
  LD A,(Countdown)
  CP $08
  JP NC,RaceLoop
  LD A,(GetUp)
  AND A
  JP NZ,RaceLoop
  LD A,(Timer)
  AND A
  JR NZ,l_AA03
  LD DE,$0940
  SBC HL,DE
  JR NC,l_AA3C
  JR l_AA39
l_AA03:
  BIT 0,D
  JR Z,l_AA2E
  LD A,H
  CP $14
  JR C,l_AA20
  CP $A0
  JR C,l_AA1B
  EX DE,HL
  LD HL,$C800
  SBC HL,DE
  EX DE,HL
  LD B,$04
  JR l_AA25
l_AA1B:
  LD DE,$0220
  JR l_AA2B
l_AA20:
  LD E,L
  LD D,H
  INC D
  LD B,$02
l_AA25:
  SRL D
  RR E
  DJNZ l_AA25
l_AA2B:
  ADD HL,DE
  JR l_AA3C
l_AA2E:
  BIT 4,D
  JR Z,l_AA3C
  LD DE,$0580
  SBC HL,DE
  JR NC,l_AA3C
l_AA39:
  LD HL,$0000
l_AA3C:
  LD (Speed),HL
l_AA3F:
  LD A,(JumpHeight+$0001) ; lean at full: SPEED * $FF / 256; a bounce: SPEED *
                          ; $FA / 256
  AND A
  JR NZ,l_AA69
  LD A,(BounceTime)
  LD L,$FA
  AND A
  JR NZ,l_AA61
  LD A,(Pose)
  CP $03
  JR NZ,l_AA69
  LD A,(Lean)
  LD L,$FF
  CP $03
  JR Z,l_AA61
  CP $FD
  JR NZ,l_AA69
l_AA61:
  LD A,H
  CALL Multiply
  LD A,D
  LD (Speed+$0001),A
l_AA69:
  CALL PrintSpeed         ; PrintSpeed; the timer (not in a demo)
  LD A,(DemoMode)
  AND A
  JP NZ,RaceLoop
TimerTick:
  LD A,(Tenths)           ; Tenths read first; at 0: Timer - 1 (BCD),
                          ; PrintTimer, 10; then Tenths - 1 stored (9..0)
  AND A
  JR NZ,l_AA89
  LD A,(Timer)
  AND A
  JR Z,l_AA84
  DEC A
  DAA
  LD (Timer),A
l_AA84:
  CALL PrintTimer
  LD A,$0A
l_AA89:
  DEC A
  LD (Tenths),A
  JP NZ,RaceLoop
  LD A,(Timer)            ; Timer 0 and SPEED 0: the game is over
  AND A
  JP NZ,RaceLoop
  LD A,(Speed+$0001)
  AND A
  JP NZ,RaceLoop
; This entry point is used by the routine at BikeControl.
RaceOver:
  CALL StageTime          ; StageTime, then RaceEnd

; TuneRequest 0, RowTable back to the screen (SetRowTable $5A00)
;
; Witness: L1 23 (c1, crash, ctl, fall5, m128, names, stages, truck,
; twoplayer).
RaceEnd:
  XOR A
  LD (TuneRequest),A
  LD DE,$5A00
  JP SetRowTable

; SPEED in decimal at column 27, line 24 (a blank before 2 and 1 digits)
;
; Witness: L1 4950 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
PrintSpeed:
  LD A,(Speed+$0001)
  LD H,A
  LD BC,$1818
  CP $64
  JR NC,l_AABC
  INC B
  CP $0A
  JR NC,l_AABC
  INC B
l_AABC:
  LD A,$20
  CALL PrintGlyph
  LD A,H
  LD B,$1B
  LD E,$68
  JP PrintNumber

; TuneRequest = (Stage AND 1) + 1: tune 1 on stages 1, 3, 5, tune 2 on 2 and 4
;
; Witness: L1 34 (c1, crash, ctl, fall5, m128, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
SetTune:
  LD A,(Stage)
  AND $01
  INC A
  LD (TuneRequest),A
  RET

; The stage's time into StageTimes: TimerAtStart - Timer seconds, and the
; tenths with PassCount's last digit as hundredths
;
; The seconds are the timer's (10 passes each), so a "time" is in timer
; seconds; the hundredths digit is PassCount's units (BCD), a filler.
;
; Witness: L1 19 (c1, crash, fall5, m128, names, stages, truck, twoplayer).
StageTime:
  LD A,(Stage)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,StageTimes
  ADD HL,BC
  LD A,(Tenths)
  LD C,A
  LD A,(TimerAtStart+$0001)
  SUB C
  JR Z,l_AAFC
  JR NC,l_AAED
  ADD A,$0A
  INC B
l_AAED:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD A,(PassCount)
  DEC A
  DAA
  AND $0F
  OR C
  RRC B
l_AAFC:
  INC HL
  LD (HL),A
  LD A,(Timer)
  LD C,A
  LD A,(TimerAtStart)
  SBC A,C
  DAA
  DEC HL
  LD (HL),A
  RET

; The stage's last segment passed: the time bonus (the timer's tens and units
; as the 100 000s and 10 000s digits: 10 000 points a second left, plus the
; last pass's speed points still in ScoreDigits+3..+6), StageTime, Stage + 1;
; the finish after stage 5
;
; Reached by NextSegment's JP NZ with its return address on the stack (POP HL).
; Stages 1-4: the big stage digit, ExtendedTime 32, Timer + 50 (at most 99),
; StageStart. After stage 5: SPEED 0, the rider of 0-3 with the largest row
; byte (unsigned: a rider just behind the bike, row $FF, beats one ahead) is
; put on row 0 at the bike's x with speed and top 2 (FinishRider) and the run
; goes on to FinishCheck.
;
; Recorded: stages (frames 3422, 5340, 7806, 10272, the finish 13012), reset3
; (stages 2 and 3).
;
; Witness: L1 5 (stages).
StageEnd:
  POP HL
  LD A,(Timer)
  LD H,A
  RRA
  RRA
  RRA
  RRA
  AND $0F
  LD L,A
  LD A,H
  AND $0F
  LD H,A
  LD (ScoreDigits+$0001),HL
  LD HL,ScoreDigits+$0006
  CALL AddScore
  CALL StageTime
  CALL FormatTime
  XOR A
  LD (Segments),A
  LD A,(Stage)
  INC A
  LD (Stage),A
  CP $05
  JR C,l_AB76
  LD IX,Riders
  LD IY,Riders
  LD DE,$000F
  LD B,$04
  XOR A
  LD (Speed+$0001),A
l_AB49:
  CP (IX+$04)
  JR NC,l_AB55
  LD A,(IX+$04)
  PUSH IX
  POP IY
l_AB55:
  ADD IX,DE
  DJNZ l_AB49
  LD (FinishRider+$0002),IY
  LD (IY+$04),B
  LD (IY+$0C),B
  LD A,(LateralX+$0001)
  NEG
  LD (IY+$02),A
  LD A,$02
  LD (IY+$06),A
  LD (IY+$08),A
  JP RaceLoop
l_AB76:
  INC A                   ; stages 1-4
  LD DE,$0718
  CALL BigDigit
  LD A,$20
  LD (ExtendedTime),A
  LD A,(Timer)
  ADD A,$50
  DAA
  JR NC,l_AB8C
  LD A,$99
l_AB8C:
  LD (Timer),A
  CALL PrintTimer
  JP StageStart

; D edges on the beeper, E loop turns apart (the countdown, EXTENDED PLAY)
;
; Witness: L1 73 (c1, crash, ctl, m128, names, stages, tech-brake-bend,
; tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck, twoplayer).
BeepTone:
  XOR A
l_AB96:
  OUT ($FE),A
  XOR $10
  LD B,E
l_AB9B:
  DJNZ l_AB9B
  DEC D
  JR NZ,l_AB96
  RET

; Step HL to the track's next element and run the commands before it: marks,
; pattern calls and returns, jumps, the variable object
;
; HL is a track pointer, IX a track stack (TrackStack for the bike, the drawing
; walk's own), B the element's row for the marks. An element byte is a command
; (high nibble) and a gap (low nibble * 2: the distance from the previous
; element, in ScrollStep's high-byte units). $F0: a gap mark, its row into
; GapMarks (D, then E; 0 over the gap). $E0 ADDR, LEN: call the pattern at ADDR
; (a frame of 6 bytes: return, length, distance done) until LEN distance is
; driven. $D0: return from the pattern (the depth in IX+0). $C0 d: jump by d
; (signed) in the track. $B0+n: VarObject = 2n. Any other high nibble: an
; element (its type), and the distance is added to every open pattern's count;
; a pattern whose count reaches its length returns to its caller from that
; element, which is not placed: a call covers its elements below its length.
;
; Witness: L1 82250 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
TrackStep:
  INC HL
l_ABA2:
  INC HL
l_ABA3:
  LD A,(HL)
  AND $F0
  CP $F0
  JR NZ,l_ABC8
  POP DE
  POP BC
  PUSH BC
  PUSH DE
  LD DE,(GapMarks)
  LD A,(InGap)
  AND A
  JR Z,l_ABBA
  LD E,$00
l_ABBA:
  BIT 7,E
  JR Z,l_ABC1
  LD E,B
  JR l_ABC2
l_ABC1:
  LD D,B
l_ABC2:
  LD (GapMarks),DE
  JR l_ABA2
l_ABC8:
  CP $E0
  JR NZ,l_ABFE
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,IXL
  LD A,(IX+$00)
  INC (IX+$00)
  AND A
  JR Z,l_ABE6
  LD A,C
  ADD A,$06
  LD IXL,A
l_ABE6:
  LD (IX+$01),L
  LD (IX+$02),H
  LD (IX+$03),E
  LD (IX+$04),D
  XOR A
  LD (IX+$05),A
  LD (IX+$06),A
  LD IXL,C
  POP HL
  JR l_ABA3
l_ABFE:
  CP $D0
  JR NZ,l_AC1D
  LD C,IXL
  LD A,(IX+$00)
  DEC (IX+$00)
  DEC A
  JR Z,l_AC12
  LD A,C                  ; a return with more than one frame open (not met:
                          ; the track nests one level)
  ADD A,$06
  LD IXL,A
l_AC12:
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD IXL,C
  JP l_ABA3
l_AC1D:
  CP $C0
  JR NZ,l_AC2F
  INC HL
  LD E,(HL)
  INC HL
  LD D,$00
  BIT 7,E
  JR Z,l_AC2B
  DEC D
l_AC2B:
  ADD HL,DE
  JP l_ABA3
l_AC2F:
  CP $B0
  JR NZ,l_AC3D
  LD A,(HL)
  AND $0F
  ADD A,A
  LD (VarObject),A
  JP l_ABA2
l_AC3D:
  LD A,(HL)               ; an element: the distance into the open patterns
  AND $0F
  ADD A,A
  LD D,A
  LD A,(IX+$00)
  LD B,A
  AND A
  RET Z
  LD E,IXL
  DEC A
  JR Z,l_AC52
  LD A,E
  ADD A,$06
  LD IXL,A
l_AC52:
  LD A,(IX+$05)
  ADD A,D
  LD (IX+$05),A
  JR NC,l_AC5E
  INC (IX+$06)
l_AC5E:
  LD A,(IX+$04)
  CP (IX+$06)
  JR C,l_AC70
  JR NZ,l_AC7F
  LD A,(IX+$05)
  CP (IX+$03)
  JR C,l_AC7F
l_AC70:
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD IXL,E
  DEC B
  LD (IX+$00),B
  JP l_ABA3
l_AC7F:
  LD A,IXL
  SUB $06
  LD IXL,A
  DJNZ l_AC52
  RET

; 48K only: 248 (or D) noise edges, the ROM's bytes at $03xx as bit 4 and the
; spacing; C set on return
;
; On the 128K (Beeper 0) it returns at once (NC): RampSpeed's CALL
; NC,AyEffectTick then steps the AY effect.
;
; Witness: L1 220 (c1, crash, fall5, m128, stages, tech-land-wheelie,
; tech-ramp-wheelie, truck, twoplayer).
CrashSound:
  LD D,$F8

; D edges
;
; Witness: L1 239 (c1, crash, fall5, m128, stages, tech-land-wheelie,
; tech-ramp-wheelie, truck, twoplayer).
CrashSoundD:
  LD A,(Beeper)
  AND A
  RET Z
  LD H,$03
l_AC91:
  LD A,(HL)
  INC L
  AND $10
  OUT ($FE),A
  LD A,(HL)
  INC L
  AND $1F
  ADD A,$30
  LD B,A
l_AC9E:
  DJNZ l_AC9E
  DEC D
  JR NZ,l_AC91
  SCF
  RET

; The AY effect each pass: EffectStep - 1 into the volumes of channels C, B, A
; (registers 10-8)
;
; EffectTime 2 (a bounce, a landing): two steps, then EffectTime 0 and
; EffectStep 15. EffectTime 1 (a fall): down to 0, then TuneRequest 0 and
; TuneMark 1: the tune stops until SetTune (the next StartRace or a pause's
; end).
;
; Witness: L1 5204 (c1, crash, ctl, fall5, m128, names, stages,
; tech-brake-bend, tech-cheat, tech-land-wheelie, tech-ramp-wheelie, truck,
; twoplayer).
AyEffectTick:
  LD HL,(EffectTime)
  LD A,L
  AND A
  RET Z
  LD A,H
  DEC A
  LD (EffectStep),A
  JR NZ,l_ACBC
  XOR A
  LD (TuneRequest),A
  INC A
  LD (TuneMark),A
  JR l_ACC3
l_ACBC:
  DEC L
  JR Z,l_ACCA
  CP $0D
  JR NZ,l_ACCA
l_ACC3:
  LD HL,$0F00
  LD (EffectTime),HL
  RET
l_ACCA:
  LD L,H
  LD H,$0A
l_ACCD:
  LD BC,$FFFD
  LD A,H
  OUT (C),A
  LD BC,$BFFD
  LD A,L
  OUT (C),A
  DEC H
  BIT 3,H
  JR NZ,l_ACCD
  RET
