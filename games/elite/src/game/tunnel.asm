; --------------------------------------------------------------------------------------------------------------------
; tunnel.asm: The ring tunnel of the launch, the dock and the hyperspace jump; the launch and dock sequences
;
; The tunnel is a row of concentric outlined circles at the view's centre ($0F, $0000 in the circle's variables). Each
; ring has a distance that one frame takes one from; its radius is 256 / distance (TunnelDivide) and only a ring of
; radius 4 or more is drawn, so the rings come out of the centre and grow to the edge. Two flags at $D03F: TunnelOn (a
; launch or dock tunnel is running) and TunnelLoop ($D040, the frames run inside one call). The launch, the dock and
; the jump patch three bytes of TunnelFrame for their shape: the jump of JR Z at $9317 (its own loop or one frame a
; call), the last frame (CP at $9325) and where the loop ends (JR C at $932A).
; --------------------------------------------------------------------------------------------------------------------

; The view's texts (ViewTexts), then a tunnel frame while TunnelOn is set
;
; The flight loop's and the scenes' per-frame call. 1220 runs over f1, w1, d1.
TunnelFrameText:
  CALL ViewTextsVector
  LD A,(TunnelOn)
  AND A
  RET Z
  JR TunnelFrame

; Start the hyperspace tunnel when TunnelLoop is set: the controls and the
; ships reset, 16 rings
;
; In witch space (WitchSpace non-zero) slot 0's energy is cleared and ship
; action 1 runs first. Then the view cleared, TunnelTop $42, the jump sound
; (SoundJump), the 16 rings of TunnelRings, the last frame at 1 and the end at
; TunnelStop: $42 frames in one call. 2 runs (the jumps of f1 and w1).
TunnelStart:
  LD A,(TunnelLoop)
  AND A
  RET Z
  CALL ResetControls
  CALL ClearShips
  LD A,(WitchSpace)
  AND A
  JR Z,TunnelStartRings
  LD IX,ShipSlots
  XOR A
  LD (IX+$22),A
  INC A
  CALL ShipActionVector
TunnelStartRings:
  CALL ClearView
  CALL CopyBackBuffer
  LD A,$42
  LD (TunnelTop),A
  CALL SoundJump
  LD HL,TunnelRings
  LD (TunnelFrameStart+$0001),HL
  LD A,$10
  LD (TunnelRingCount),A
  LD A,$01
  LD (TunnelFrameShow+$0008),A
  LD A,$15
  LD (TunnelFrameShow+$000D),A

; Draw the tunnel: every ring one step nearer, then show the frame
;
; With TunnelLoop set (the jump, the first frames of the launch and the dock)
; the frames loop here until TunnelTop passes the last frame; without it each
; call draws one frame and TunnelCount counts it.
TunnelFrame:
  LD A,(TunnelLoop)
  AND A
  JR NZ,TunnelFrameLoop
  LD A,$1E
  LD (TunnelFrameNext+$0005),A
  JR TunnelFrameRings
TunnelFrameLoop:
  LD A,$05
  LD (TunnelFrameNext+$0005),A
TunnelFrameRings:
  LD A,$0F
  LD (CircleQuadrant),A
  LD HL,$0000
  LD (CircleY),HL
  LD A,(TunnelRingCount)
  LD (TunnelRingsLeft),A
TunnelFrameStart:
  LD HL,TunnelRings       ; the ring table (patched: TunnelRings or
                          ; LaunchRings)
TunnelFrameRing:
  LD A,(HL)
  DEC A
  LD (HL),A
  INC HL
  LD B,A
  LD A,$01
  CALL TunnelDivide
  LD A,C
  CP $04
  JR C,TunnelFrameNext
  LD (CircleRadius),A
  PUSH HL
  CALL DrawCircleOutline
  POP HL
TunnelFrameNext:
  LD A,(TunnelRingsLeft)  ; the JR Z's offset at $9318 is patched: $05 the
                          ; loop, $1E one frame a call
  DEC A
  JR Z,TunnelFrameShow
  LD (TunnelRingsLeft),A
  JR TunnelFrameRing
TunnelFrameShow:
  CALL CopyBackBuffer     ; the CP's value at $9326 (the last frame) and the JR
                          ; C's offset at $932B (the end) are patched
  LD A,(TunnelTop)
  DEC A
  CP $30
  LD (TunnelTop),A
  JR C,TunnelOver
  LD A,(TunnelRingCount)
  LD (TunnelRingsLeft),A
  CALL ClearView
  JR TunnelFrameStart

; One frame of a tunnel drawn a frame a call: TunnelEnd when TunnelTop reaches
; 0
TunnelCount:
  LD A,(TunnelTop)
  DEC A
  LD (TunnelTop),A
  JR Z,TunnelEnd
  RET

; The jump's tunnel over: both flags off, the 16 rings moved back by $BE, the
; view cleared and shown
TunnelStop:
  XOR A
  LD (TunnelLoop),A
  LD (TunnelOn),A
  LD A,$10
  LD B,A
  LD HL,TunnelRings
TunnelStopRings:
  LD A,(HL)
  SUB $BE
  LD (HL),A
  INC HL
  DJNZ TunnelStopRings
  CALL ClearView
  CALL CopyBackBuffer
  JP TunnelDone

; The launch's first frames over: TunnelLoop off, the stardust made again
;
; Used by the routine at TunnelFrame.
TunnelOver:
  XOR A
  LD (TunnelLoop),A
  JR StarsRenew

; The dock's first frames over: TunnelLoop off (reached by a jump: dk, gx, m1,
; m2 docked)
TunnelOff:
  XOR A
  LD (TunnelLoop),A
  RET

; TunnelOn off and the 8 launch rings moved back by $C0 for the next time
;
; Used by the routine at TunnelCount.
TunnelEnd:
  XOR A
  LD (TunnelOn),A
  LD A,$08
  LD B,A
  LD HL,LaunchRings
TunnelEndRings:
  LD A,(HL)
  SUB $C0
  LD (HL),A
  INC HL
  DJNZ TunnelEndRings
  RET

; Make all 16 dots again ahead of the ship (StarRespawnFront patched for it),
; speed 7
;
; StarRespawnFront's two range bytes become $83 (from $BF and $9F) and the RET
; at its tail ($7E0E) replaces the JP, so each call places one dot from
; StarSeed; the bytes go back after the 16 dots.
StarsRenew:
  LD A,$83
  LD (StarRespawnFront+$0001),A
  LD (StarRespawnFront+$0006),A
  LD A,$C9
  LD (StarRespawnLoop+$000B),A
  LD A,$07
  LD (SpeedRate),A
  LD HL,(StarSeed)
  LD DE,StarDots
  LD B,$10
StarsRenewDot:
  PUSH BC
  CALL StarRespawnFront
  POP BC
  DJNZ StarsRenewDot
  LD A,$BF
  LD (StarRespawnFront+$0001),A
  LD A,$9F
  LD (StarRespawnFront+$0006),A
  LD A,$C3
  LD (StarRespawnLoop+$000B),A
  RET

; C = A * 256 / B (A < B): a ring's radius from its distance
;
; A restoring division, eight bits of quotient; C starts at $FE so the carry
; out of RL C after eight bits ends it. 3648 runs.
TunnelDivide:
  LD C,$FE
TunnelDivideLoop:
  ADD A,A
  JR C,TunnelDivideSub
  CP B
  JR NC,TunnelDivideSub
  SLA C
  RET NC
  JR TunnelDivideLoop
TunnelDivideSub:
  SUB B
  SCF
  RL C
  RET NC
  JR TunnelDivideLoop

; After the jump: the attributes white unless in the nova system (NovaMission
; $D081), LastSunRadius 0, the arrival sound
;
; Used by the routine at TunnelStop.
TunnelDone:
  LD A,(NovaMission)
  AND A
  LD L,$07
  CALL Z,FillAttrsVector
  XOR A
  LD (LastSunRadius),A
  JP SoundArrive

; The number of rings (16 for the jump, 8 for the launch and the dock)
TunnelRingCount:
  DEFB $08

; TunnelRingsLeft
TunnelRingsLeft:
  DEFB $00

; The frames left
TunnelTop:
  DEFB $00

; The 16 ring distances of the jump tunnel, 2.5 apart
TunnelRings:
  DEFB $1E,$21,$23,$26,$28,$2B,$2D,$30
  DEFB $32,$35,$37,$3A,$3C,$3F,$41,$44

; The 8 ring distances of the launch and dock tunnel, and two spare bytes
LaunchRings:
  DEFB $10,$10,$10,$18,$20,$28,$30,$38
  DEFB $00,$00

; The launch from the station (Condition 0) or the dock (in flight), with the
; tunnel
;
; Both: the 8 launch rings, TunnelTop $40, the last frame $30, TunnelOn and
; TunnelLoop set.
;
; The launch (d1 at Lave, 3 runs over f1, w1, d1): Condition green, the views
; reset, the dashboard drawn and reset (ResetFlight $9946), the planet ahead
; ($80 at z+1 of PlanetPosition, the sun's sign flipped), slot 0 the station
; just behind the ship (z = -$F0, its three axes the unit ones, $7F) with
; energy $F0, the bars, 16 frames in the first call (TunnelOver), 36 frames of
; the tunnel over the stardust and 11 with the sun and the planet.
;
; The dock (dk docked by hand at frame 2190 and by the computer at 3408; gx,
; m1, m2 docked too): speed $0C, no roll or pitch, the controls held, the first
; call's frames end at TunnelOff, then 47 frames, Condition docked, the
; dashboard saved, the controls cleared, the mission screens (ArrivalScreens),
; PirateStation and the status screen (CallScreen 7).
SceneLaunch:
  LD A,(WitchSpace)
  AND A
  RET NZ
  LD HL,LaunchRings
  LD (TunnelFrameStart+$0001),HL
  LD A,$08
  LD (TunnelRingCount),A
  LD A,$30
  LD (TunnelFrameShow+$0008),A
  LD A,$40
  LD (TunnelTop),A
  LD HL,$0101
  LD (TunnelOn),HL
  LD A,(Condition)
  AND A
  JR Z,SceneLaunchNow
SceneDock:
  LD A,$38
  LD (TunnelFrameShow+$000D),A
  LD A,$0C
  LD (SpeedRate),A
  XOR A
  LD (PitchRate),A
  LD (RollRate),A
  LD (ECMActive),A
  INC A
  LD (HoldRates),A
  LD HL,Equipment+$0001
  RES 7,(HL)
  CALL ClearView
  CALL TunnelFrameText
  LD B,$2F
SceneDockFrame:
  PUSH BC
  CALL ClearView
  CALL TunnelFrameText
  CALL CopyBackBuffer
  POP BC
  DJNZ SceneDockFrame
  CALL SoundLaunch
  XOR A
  LD (Condition),A
  CALL DashboardSave
  CALL ResetControls
  CALL ArrivalScreens
  CALL PirateStation
  LD A,$07
  JP CallScreen
SceneLaunchNow:
  LD A,$04
  LD (Condition),A
  CALL SoundLaunch
  XOR A
  LD (Docked),A
  LD (ViewIndex),A
  LD (StationLaunch),A
  LD (CloakOn),A
  LD A,$32
  LD (TunnelFrameShow+$000D),A
  CALL DashboardRestore
  CALL ResetFlight
  CALL NovaSunGrows
  LD HL,PlanetPosition
  LD B,$07
  CALL ZeroBytes
  LD (HL),$80
  INC HL
  LD (HL),$01
  LD A,(SunPosition+$0008)
  XOR $80
  LD (SunPosition+$0008),A
  LD HL,ShipSlots
  LD B,$1B
  CALL ZeroBytes
  LD IX,ShipSlots
  LD A,$F0
  LD (IX+$06),A
  LD A,$80
  LD (IX+$08),A
  DEC A
  LD (IX+$0E),A
  LD (IX+$12),A
  LD (IX+$16),A
  LD A,$F0
  LD (IX+$22),A
  CALL ClearShips
  CALL DrawBars
  CALL ClearView
  CALL TunnelFrameText
  LD B,$24
SceneLaunchTunnel:
  PUSH BC
  CALL ClearView
  CALL Stardust
  CALL TunnelFrameText
  CALL CopyBackBuffer
  POP BC
  DJNZ SceneLaunchTunnel
  LD B,$0B
SceneLaunchFlight:
  PUSH BC
  CALL ClearView
  CALL MoveSunPlanet
  CALL Stardust
  CALL TunnelFrameText
  CALL DrawSunPlanet
  CALL CopyBackBuffer
  POP BC
  DJNZ SceneLaunchFlight
  XOR A
  LD (HoldRates),A

; The control accumulators $FF08-$FF0C zeroed, SpeedControl $0C00, then the
; keys
;
; Used by the routines at Title, TitleNext, TunnelStart and SceneLaunch.
ResetControls:
  LD B,$05
  LD HL,RollControl
  CALL ZeroBytes
  LD (HL),$0C

; Zero the five key bytes $FC08-$FC0C
;
; Used by the routines at DashboardRestore and CallScreenCall.
ClearKeyBytes:
  LD B,$05
  LD HL,KeyScreens

; Zero B bytes from HL
;
; Used by the routines at SceneLaunch and ResetControls.
ZeroBytes:
  XOR A
ZeroBytesLoop:
  LD (HL),A
  INC HL
  DJNZ ZeroBytesLoop
  RET
