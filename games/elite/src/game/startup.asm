; --------------------------------------------------------------------------------------------------------------------
; startup.asm: The vectors, the flight variables, the start, the pause menu and the title
;
; The game's code starts at $6FF2 with a few jump vectors other parts call by address, the variables the flight loop
; shares (the view, the control rates, the dashboard bar values, the planet and the sun), the pause menu and the title
; screen. Start $70E0 is where the kickoff enters (JP $70E0, 03-build-and-load.md 3.7).
; --------------------------------------------------------------------------------------------------------------------

; JP EnergyBomb (FlightLoop calls it every frame)
;
; Used by the routine at DashboardTick.
EnergyBombVector:
  JP EnergyBomb

; JP FlashScreen (known from the code only: no caller ran)
FlashVector:
  JP FlashScreen

; JP FillAttrs
;
; Used by the routines at CloakKey, FlightLoop, HitFlash, TunnelDone,
; MessagePeriodic and MissionNova.
FillAttrsVector:
  JP FillAttrs

; The four sizes of a system's dot on the local chart, 8x8 each
;
; DrawChartIcon $ED27 picks one (DE = $6FFB + 8 n) and ORs it onto the chart.
ChartIcons:
  DEFB $00,$38,$7C,$7C,$7C,$38,$00,$00
  DEFB $38,$7C,$FE,$FE,$FE,$7C,$38,$00
  DEFB $7C,$FE,$FE,$FE,$FE,$FE,$7C,$00
  DEFB $00,$38,$7C,$7C,$7C,$38,$00,$00

; The 17 commodities: 4 bytes each, the market generator's table
;
; MakeMarket $E148 (d1: the Lave market) reads the 68 bytes from $701B: the
; base price, the economy factor (bit 7 its sign) with the unit in its top
; bits, the base quantity and the fluctuation mask (10-gameplay-logic.md).
; Firearms is entry 11: ZeroFirearms $B7AC zeroes its price when the special
; cargo mission needs it.
Commodities:
  DEFB $13,$82,$06,$01
  DEFB $14,$81,$0A,$03
  DEFB $41,$83,$02,$07
  DEFB $28,$85,$E2,$1F
  DEFB $53,$85,$FB,$0F
  DEFB $C4,$08,$36,$03
  DEFB $EB,$1D,$08,$78
  DEFB $9A,$0E,$38,$03
  DEFB $75,$06,$28,$07
  DEFB $4E,$01,$11,$1F
  DEFB $7C,$0D,$1D,$07
  DEFB $B0,$89,$DC,$3F
  DEFB $20,$81,$35,$03
  DEFB $61,$A1,$42,$07
  DEFB $AB,$A2,$37,$1F
  DEFB $2D,$C1,$FA,$0F
  DEFB $35,$0F,$C0,$07

; The prices of the equipment the Equip screen sells
;
; Read by EquipShip $E973 through EquipPricePtr $EB2F (t1 bought a missile at
; frame 1474: EquipShip 1 run). The fuel price at $7060 is written by the
; hyperspace code ($DC66, $DCAA).
EquipmentPrices:
  DEFB $00,$00,$00
  DEFB $00,$2C,$01
  DEFB $00,$A0,$0F
  DEFB $00,$70,$17
  DEFB $00,$A0,$0F
  DEFB $01,$00,$00
  DEFB $00,$82,$14
  DEFB $01,$00,$00
  DEFB $00,$28,$23
  DEFB $01,$88,$13
  DEFB $01,$88,$13
  DEFB $05,$00,$00
  DEFB $06,$00,$00
  DEFB $00,$40,$1F

; Detonate the energy bomb when its key is down and one is fitted
;
; Every frame (f1, w1, d1: 1076 runs) from FlightLoop through EnergyBombVector.
; KeyCombat $FC0B bit 5 is the bomb key; EnergyBombFitted $D08A non-zero is a
; bomb on board. The bomb is used up, BombKill $9C95 = 1 makes UpdateShips
; destroy what it can, sound 0 is requested and the screen flashes 24 times
; (FlashScreen). k2 fired one at frame 3304 (FlashScreen 24 runs; the Thargoids
; unhurt), m1 and m2 one each.
EnergyBomb:
  LD A,(KeyCombat)
  BIT 5,A
  RET Z
  LD HL,Equipment+$0006
  LD A,(HL)
  AND A
  RET Z
  XOR A
  LD (HL),A
  INC A
  LD (BombKill),A
  LD HL,SoundRequests
  SET 0,(HL)
  LD C,$18
EnergyBombFlash:
  CALL FlashScreen
  DEC C
  JR NZ,EnergyBombFlash
  RET

; One flash: the 3D view's attributes $28, then $0F
;
; Used by the routines at FlashVector and EnergyBomb.
FlashScreen:
  LD L,$28
  CALL FillAttrsTinted
  LD L,$0F

; Fill the 3D view's attributes ($5800-$59FF) with L after the next interrupt
;
; L is the attribute; with CloakOn $D041 zero only its INK bits stay (AND 7).
; The entry FillAttrsTinted $70BA skips that step; with NovaMission $D081 set
; the attribute is ANDed with $3A. After a HALT the stack pointer is put at
; $59FF and 16 rows of 15 PUSHes write the 512 bytes; FillSP keeps the real SP.
FillAttrs:
  LD A,(CloakOn)
  AND A
  JR NZ,FillAttrsTinted
  LD A,L
  AND $07
  LD L,A

; FillAttrsTinted
;
; Used by the routines at FlashScreen and FillAttrs.
FillAttrsTinted:
  LD A,(NovaMission)
  AND A
  JR Z,FillAttrsNow
  LD A,L
  AND $3A
  LD L,A
FillAttrsNow:
  HALT
  LD (FillSP),SP
  LD H,L
  LD SP,$59FF
  LD A,$10
FillAttrsRow:
  LD B,$0F
FillAttrsPush:
  PUSH HL
  DJNZ FillAttrsPush
  DEC SP
  DEC SP
  DEC A
  JR NZ,FillAttrsRow
  LD SP,(FillSP)
  RET

; FillAttrs' saved stack pointer
FillSP:
  DEFW $0000

; The game's entry from the kickoff: JP Title
Start:
  JP Title

; The view: 0-3 the space views (front, rear, left, right), 4 and up the
; screens
;
; SelectView $80D3 sets it from the keys; below 4 the flight loop draws space,
; from 4 a status, market or chart screen is up (7 and 8 the charts:
; ChartCursorKeys $71F3).
ViewIndex:
  DEFB $00

; The roll rate this frame (bit 7 the sign), copied from the high byte of
; RollControl ($FF09)
RollRate:
  DEFB $00

; The pitch rate this frame, from the high byte of PitchControl ($FF0B)
PitchRate:
  DEFB $00

; The speed this frame, from the high byte of SpeedControl ($FF0D)
SpeedRate:
  DEFB $0A

; The dashboard bars: 13 pairs of the length last drawn and the value, the fore
; shield first
;
; DrawBars $84D9 compares each value with the byte before it and draws only a
; changed bar; a value is 0-$A0, a quarter of it the length in pixels. The
; first 11 are solid bars (the shields, the fuel, the cabin and laser
; temperatures, the altitude, the speed, the four energy banks), the last two
; the roll and pitch markers. ResetDashboard $9946 starts the shields, the
; altitude and the banks at $A0.
BarDrawn:
  DEFB $00
BarForeShield:
  DEFB $00                ; The fore shield
  DEFB $00                ; the aft shield's last length
BarAftShield:
  DEFB $00,$00            ; The aft shield
BarFuel:
  DEFB $A0,$00            ; The fuel
BarCabinTemp:
  DEFB $00,$00            ; The cabin temperature (zero at a reset)
BarLaserTemp:
  DEFB $00,$00            ; The laser temperature
BarAltitude:
  DEFB $A0,$00            ; The altitude above the planet
BarSpeed:
  DEFB $00,$FF            ; The speed: SpeedRate * 5 + 5
BarEnergy1:
  DEFB $00,$00            ; Energy bank 1
BarEnergy2:
  DEFB $00,$00            ; Energy bank 2
BarEnergy3:
  DEFB $A0,$00            ; Energy bank 3
BarEnergy4:
  DEFB $A0,$00            ; Energy bank 4
BarRoll:
  DEFB $00,$00            ; The roll marker: $15 +/- the roll rate
BarPitch:
  DEFB $00                ; The pitch marker: $15 +/- the pitch rate
  DEFB $00,$00            ; spare

; Non-zero in witch space after a misjump (the hyperspace arrival, JumpArrive):
; no sun, no planet, no station, four stars, Thargoids
WitchSpace:
  DEFB $00

; The condition light as an attribute: 0 docked, 4 green, 6 yellow, 2 red, $63
; red flashing
;
; ConditionLight $99A4 writes it to the dashboard's attributes ($5A28, $5A48)
; every frame and sets 4 again for the next: the distance code makes it 6 near
; the planet or the sun and $63 very near ($82D7), a shield at zero makes it 2,
; and $63 alternates between 0 and 2 (ConditionFlash $99A3).
Condition:
  DEFB $00

; The stardust generator's seed (StarRandom $7E86)
StarSeed:
  DEFW $4A37

; The sun's position: x, y, z, 3 bytes each (sign in bit 7 of the top byte)
;
; DashDistances $81A9 turns its distance into the cabin temperature
; (BarCabinTemp) and TooClose; DrawSunPlanet $7584 draws it first, as a filled
; circle.
SunPosition:
  DEFB $00,$00,$00
  DEFB $00,$80,$01
  DEFB $00,$10,$09

; The planet's position: x, y, z
;
; DashDistances turns its distance into the altitude (BarAltitude, $A0 -
; distance) and the safe zone (SafeZone, all three coordinates below $0200).
PlanetPosition:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$80,$01

; JP DrawChartCircle
;
; Used by the routines at BuyCargo, GalacticChart and ShortRangeChart.
DrawChartCircleVector:
  JP DrawChartCircle

; Non-zero inside the space station's safe zone: the planet's three coordinates
; below $0200
SafeZone:
  DEFB $00

; Non-zero while slot 0, the station, flies in after a launch
StationLaunch:
  DEFB $00

; Non-zero when the sun's distance is below $2000 (DashDistances $81EC)
SunNear:
  DEFB $00

; Non-zero when the ship has hit the planet or the sun
TooClose:
  DEFB $00

; Non-zero when the sun's circle radius is $28 or more (DrawSunPlanet $75A8)
SunLarge:
  DEFB $00

; JP ConditionLight
;
; Used by the routines at MessageTick, PageTitle and StatusScreen.
ConditionLightVector:
  JP ConditionLight

; Non-zero: FlightLoop keeps the control rates of the frame before
HoldRates:
  DEFB $00

; JP SoundTick (the interrupt handler calls it)
;
; Used by the routine at IM2Handler.
SoundTickVector:
  JP SoundTick

; The sound requests: one bit a sound, set by the game, served by SoundTick
SoundRequests:
  DEFB $00

; 1 when the docking computer docked the ship (DockKeys $71AE)
AutoDocked:
  DEFB $00

; JP AddDigit (known from the code only, like the next two)
;
; Used by the routine at QuantityKeys.
AddDigitVector:
  JP AddDigit

; JP DashAttrs $9974
;
; Used by the routine at DamageItem.
AttrFillVector:
  JP ResetFlightJoin

; (HL) = (HL) * 10 + B: one typed digit into a number
;
; Used by the routine at AddDigitVector.
AddDigit:
  LD A,(HL)
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  ADD A,B
  LD (HL),A
  LD A,D
  JP PrintCodeVector

; Copy the control rates the interrupt built to this frame's rates and the
; indicators
;
; Every pass of FlightLoop (197283 runs over f1, w1, d1). The high bytes of
; RollControl, PitchControl and SpeedControl ($FF09, $FF0B, $FF0D) are what
; ReadControls $FE01 accumulated in the interrupt: copied to RollRate,
; PitchRate and SpeedRate; the roll and pitch indicators get $15 plus or minus
; the rate (a sign-magnitude byte), the speed indicator 5 * speed + 5.
CopyRates:
  LD HL,RollControl+$0001
  LD A,(HL)
  LD (RollRate),A
  BIT 7,A
  JR NZ,CopyRatesRollNeg
  ADD A,$15
  JR CopyRatesRollBar
CopyRatesRollNeg:
  AND $7F
  LD C,A
  LD A,$15
  SUB C
CopyRatesRollBar:
  LD (BarRoll),A
  INC L
  INC L
  LD A,(HL)
  LD (PitchRate),A
  BIT 7,A
  JR NZ,CopyRatesPitchNeg
  ADD A,$15
  JR CopyRatesPitchBar
CopyRatesPitchNeg:
  AND $7F
  LD C,A
  LD A,$15
  SUB C
CopyRatesPitchBar:
  LD (BarPitch),A
  INC L
  INC L
  LD A,(HL)
  LD (SpeedRate),A
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  ADD A,$05
  LD (BarSpeed),A
  RET

; Dock: after the collision code docked the ship, or on the docking computer
; key in the safe zone
;
; Docked $9C9A is set by the collision code when the ship enters the station
; ($B591) and by the arrival code ($9466): cleared, and the docking sequence
; runs. Otherwise KeyCombat $FC0B bit 7 (the docking computer key, cleared
; here) docks when the ship is in the safe zone, DockingComputer $D08C is
; fitted, Condition is not 0, $D03F is 0 and slot 0's flag bit 2 is clear;
; AutoDocked is set. Then the front view, the dashboard, CentreMarkers and the
; docking scene (SceneDock $93ED). f1 and w1: 863 runs, no dock.
DockKeys:
  LD A,(Docked)
  AND A
  JR Z,DockKeysComputer
  XOR A
  LD (Docked),A
  JR DockKeysDock
DockKeysComputer:
  LD A,(KeyCombat)
  LD B,A
  AND $80
  RES 7,B
  LD A,B
  LD (KeyCombat),A
  RET Z
  LD A,(SafeZone)
  AND A
  RET Z
  LD A,(Equipment+$0008)
  AND A
  RET Z
  LD A,(Condition)
  AND A
  RET Z
  LD A,(TunnelOn)
  AND A
  RET NZ
  LD HL,ShipSlots+$0021
  BIT 2,(HL)
  RET NZ
  LD A,$01
  LD (AutoDocked),A
DockKeysDock:
  XOR A
  LD (ViewIndex),A
  CALL DashboardRestore
; This entry point is used by the routine at EscapePod.
DockKeysCentre:
  CALL CentreMarkers
  JP SceneLaunch

; Move the sun and the planet half way to slot 0's position (known from the
; code only)
;
; Used by the routine at DockKeys.
CentreMarkers:
  LD IY,SunPosition
  LD IX,ShipSlots
  CALL CentreMarker
  CALL CentreMarker

; CentreMarker
;
; Used by the routine at CentreMarkers.
CentreMarker:
  CALL HalfDifference
  ADD HL,HL
  JR NC,CentreMarkerStore
  SET 7,H
CentreMarkerStore:
  LD (IY+$02),H
  LD (IY+$01),L
  LD DE,$0003
  ADD IY,DE
  ADD IX,DE
  RET

; HL = half the difference between a marker coordinate (IY) and the slot's (IX)
;
; Used by the routine at CentreMarker.
HalfDifference:
  LD H,(IY+$02)
  LD L,(IY+$01)
  LD D,(IX+$02)
  LD E,(IX+$01)
  JP HalveSignedVector

; On the charts (ViewIndex 7, 8): a cursor key moves the cursor through the
; chart vector
;
; Used by the routine at FlightLoop.
ChartCursorKeys:
  LD A,(ViewIndex)
  CP $07
  RET C
  CP $09
  RET NC
  LD A,(TunnelOn)
  AND A
  RET NZ
  LD A,(KeySteer)
  AND $0F
  LD C,A
  LD A,(KeyChart)
  AND $70
  OR C
  RET Z
  LD B,$08
ChartCursorBit:
  INC B
  SRL A
  JR NC,ChartCursorBit
  LD A,B
  CALL CallScreen
  XOR A
  LD (KeyChart),A
  LD (KeySteer),A
  RET

; Counts the frames down to the next look at the cloak key (every second frame)
CloakKeyCount:
  DEFB $01

; Every second frame: Y (KeyScreens $FC08 bit 7) switches the cloaking device
; on or off once the mission has given it
;
; The device is MissionFlags bit 6 (AddCargoSpecial, the mission ship's
; canister). On: CloakOn = 1 while energy bank 3 ($70FA) is $28 or more, the
; station's hostile bit cleared, AllHostile 0 and the view's attributes $0F
; (blue paper: FillAttrs keeps the paper while CloakOn is set); off: attributes
; 7. With bank 3 below $28 the decrement leaves CloakOn at $FF, on but untinted
; (known from the code only). 1076 runs, the key never pressed with the device
; (no recording earned it, CloakOn 0 runs): the rest is known from the code
; only.
CloakKey:
  LD HL,CloakKeyCount
  DEC (HL)
  LD HL,KeyScreens
  RES 7,(HL)
  RET NZ
  LD A,$02
  LD (CloakKeyCount),A
  HALT
  BIT 7,(HL)
  RET Z
  LD HL,MissionFlags
  BIT 6,(HL)
  RET Z
  LD HL,CloakOn
  DEC (HL)
  JR Z,CloakPlain
  LD A,(BarEnergy3)
  CP $28
  RET C
  LD A,$01
  LD (HL),A
  LD HL,ShipSlots+$0021
  RES 2,(HL)
  XOR A
  LD (AllHostile),A
; This entry point is used by the routine at CloakRestore.
CloakTint:
  LD L,$0F
  JR CloakFill
CloakPlain:
  LD L,$07
; This entry point is used by the routine at NovaTint.
CloakFill:
  JP FillAttrsVector

; After the dashboard is redrawn (ClearView): the nova's red tint (attributes
; 2) again while NovaMission is set
;
; Used by the routine at DashboardRestoreNow.
NovaTint:
  LD A,(NovaMission)
  AND A
; This entry point is used by the routine at NovaSunGrows.
NovaTintFill:
  LD L,$02
  JR NZ,CloakFill
  RET

; After the dashboard is redrawn: the cloak's tint ($0F) again while CloakOn is
; set
;
; Used by the routine at DashboardRestoreNow.
CloakRestore:
  LD A,(CloakOn)
  AND A
  JR NZ,CloakTint
  RET

; At the launch (SceneLaunch): in the nova's system the sun starts to grow
; (SunGrows 1) and the view turns red
;
; Used by the routine at SceneLaunch.
NovaSunGrows:
  LD A,(NovaMission)
  AND A
  RET Z
  LD A,$01
  LD (SunGrows),A
  JR NovaTintFill

; At the dock: the mission page MissionState asks for: 1 or 2 the briefing
; (MissionQuestion), 5 the award (MissionDone), 6 SHIP BOARDED BY THARGONS and
; the title
;
; No code sets state 6: the Thargon boarding is unreachable (known from the
; code only). The routine ran at each dock: dk 2, gx 1, m1 2, m2 1 (the
; briefing, MissionQuestion, at frame 2926).
ArrivalScreens:
  LD A,(MissionState)
  DEC A
  JR Z,ArrivalScreensFirst
  DEC A
ArrivalScreensFirst:
  JP Z,MissionQuestionVector
  SUB $03
  JP Z,MissionDoneVector
  DEC A
  LD A,$D4
  JR Z,BackToTitleMessage
  RET

; At the dock: a station whose roll counter's bit 7 is clear is pirate-held:
; SHIP BOARDED BY PIRATES, THEY SHOW NO MERCY, the title
;
; TitleNext sets bit 7 of slot 0's +$1D (the station's roll counter, bit 7 the
; direction); an arrival clears it with a chance that grows as the government
; falls (JumpArrive), so the station spins the other way: the only warning.
; Known from the code only.
PirateStation:
  LD HL,ShipSlots+$001D
  BIT 7,(HL)
  RET NZ
  LD A,$0D
; This entry point is used by the routine at ArrivalScreens.
BackToTitleMessage:
  CALL FullMessageVector
  CALL DashboardRestore
  LD SP,(TitleSP)
  JP TitleShip

; The control method chosen on the title: 1 Kempston (left on port $1F, bit 5
; clear), 2 Cursor (5 held), 3 Sinclair (6 held)
ControlMethod:
  DEFB $00

; The pause: hold the game while the key's bit is set and run the option keys
;
; KeyViews $FC0A bit 7 is the pause key (the keyboard scan sets it). The game
; waits for the key to be released, then reads keys until SPACE (resume) or 1
; (back to the title, carry set): B reverse the joystick, D keyboard damping, F
; the option bit 6, K keyboard / joystick, Q sound off, R recentring, S sound
; on, Y the Y axis reversed; an unknown key beeps (ErrorBeep). Each toggles a
; bit of Options $FC0E (HL = $FC0E). w1 paused once and pressed F and SPACE.
PauseMenu:
  LD A,(KeyViews)
  AND $80
  RET Z
  LD HL,Options
PauseRelease:
  HALT
  LD A,(KeyCode)
  INC A
  JR NZ,PauseRelease
PauseKey:
  HALT
  LD A,(KeyCode)
  CP $FF
  JR Z,PauseKey
  CP $42
  CALL Z,OptionReverse
  CP $44
  CALL Z,OptionDamping
  CP $46
  CALL Z,OptionBit6
  CP $4B
  CALL Z,OptionKeyboard
  CP $51
  CALL Z,OptionSoundOff
  CP $52
  CALL Z,OptionRecentre
  CP $53
  CALL Z,OptionSoundOn
  CP $59
  CALL Z,OptionReverseY
  CP $31
  JR Z,PauseQuit
  CP $20
  JR Z,ClearKeys
  AND A
  CALL Z,ErrorBeep
  JR PauseRelease

; Zero the five key bytes $FC08-$FC0C
;
; Used by the routine at PauseMenu.
ClearKeys:
  LD HL,KeyScreens
  XOR A
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  RET
; This entry point is used by the routine at PauseMenu.
PauseQuit:
  CALL ClearKeys
  SCF
  RET

; Key B: Options bit 4
;
; Used by the routine at PauseMenu.
OptionReverse:
  LD A,(HL)
  XOR $10
  LD (HL),A
  XOR A
  RET

; Key D: Options bit 3
;
; Used by the routine at PauseMenu.
OptionDamping:
  LD A,(HL)
  XOR $08
  LD (HL),A
  XOR A
  RET

; Key F: Options bit 6
;
; Used by the routine at PauseMenu.
OptionBit6:
  LD A,(HL)
  XOR $40
  LD (HL),A
  XOR A
  RET

; Key Q: Options bit 7 off
;
; Used by the routine at PauseMenu.
OptionSoundOff:
  LD A,(HL)
  AND $7F
  LD (HL),A
  XOR A
  RET

; Key R: Options bit 2
;
; Used by the routine at PauseMenu.
OptionRecentre:
  LD A,(HL)
  XOR $04
  LD (HL),A
  XOR A
  RET

; Key S: Options bit 7 on, and the sound requests cleared
;
; Used by the routine at PauseMenu.
OptionSoundOn:
  LD A,(HL)
  OR $80
  LD (HL),A
  XOR A
  LD (SoundRequests),A
  RET

; Key Y: Options bit 5
;
; Used by the routine at PauseMenu.
OptionReverseY:
  LD A,(HL)
  XOR $20
  LD (HL),A
  XOR A
  RET

; Key K: between the keyboard and the control method chosen on the title
;
; Used by the routine at PauseMenu.
OptionKeyboard:
  LD A,(HL)
  LD D,A
  AND $03
  LD A,(ControlMethod)
  JR NZ,OptionKeyboardSwap
  AND A
  JR Z,OptionKeyboardDone
OptionKeyboardSwap:
  LD A,(ControlMethod)
  XOR D
  LD (HL),A
OptionKeyboardDone:
  XOR A
  RET

; A short beep: 6 frames of 4 rising tones on the speaker
;
; Used by the routine at PauseMenu.
ErrorBeep:
  LD B,$06
  LD E,$00
ErrorBeepFrame:
  PUSH BC
  HALT
  LD C,$04
ErrorBeepTone:
  LD A,E
  ADD A,A
  ADD A,$05
  LD E,A
  LD B,A
  LD A,$30
  OUT ($FE),A
ErrorBeepHigh:
  DJNZ ErrorBeepHigh
  LD A,E
  LD B,A
  XOR A
  OUT ($FE),A
ErrorBeepLow:
  DJNZ ErrorBeepLow
  DEC C
  JR NZ,ErrorBeepTone
  POP BC
  DJNZ ErrorBeepFrame
  RET

; The title: the rotating ship, "Load new commander", then the control method
;
; SP is kept in TitleSP $7578 for the game overs (PirateStation,
; ArrivalScreens). The ship action $79 (DoShipAction $9C9C) places the title
; Cobra; then the title loop draws it each frame (DrawTitleShip $9CAF) until a
; key: Y (KeyCode $FC0D + 1 = $5A) opens the commander load menu
; (CommanderMenuVector $D04E). The second loop shows "PRESS SPACE, COMMANDER"
; with the next title ship each pass (TitleShipCount) and reads a joystick held
; left (Kempston: port $1F bit 1 with bit 5 clear; Cursor: 5, KeyDigits bit 1;
; Sinclair: 6, KeyDigits bit 3) or SPACE (the keyboard); then the new game
; (NewGameVector $D033) and FlightLoop. c1, f1, w1 and d1 all start here (d1 at
; frame 784 of w1's title loop).
Title:
  LD (TitleSP),SP
  CALL ResetControls
  CALL DashboardRestoreNow
; This entry point is used by the routine at PirateStation.
TitleShip:
  LD A,$79
  CALL ShipActionVector
  CALL WhiteAttrs

; TitleLoad
TitleLoad:
  CALL ClearView
  CALL TitleTextLoad
  CALL DrawTitleShipVector
  CALL CopyBackBuffer
  LD A,(KeyCode)
  INC A
  JR Z,TitleLoad
  CP $5A
  JR NZ,TitleNext
  CALL DashboardSave
  CALL CommanderMenuVector
; This entry point is used by the routine at FlightLoop.
TitleIfNotZero:
  XOR A
  LD (ViewIndex),A
  CALL ClearScreenVector
  CALL DashboardRestore

; TitleNext
;
; Used by the routines at TitleLoad and FlightLoop.
TitleNext:
  LD HL,ShipSlots+$001D
  SET 7,(HL)
  CALL WhiteAttrs
  LD A,(KeyCode)
  INC A
  JR NZ,TitleNext
  LD HL,TitleShipCount
  INC (HL)
  LD A,(HL)
  AND $07
  INC A
  CP $06
  JR NC,TitleIfNotBelow
  ADD A,$0A
TitleIfNotBelow:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$09
  CALL ShipActionVector
TitleLoop:
  CALL ClearView
  CALL TitleTextPress
  CALL DrawTitleShipVector
  CALL CopyBackBuffer
  LD BC,$FF1F
  LD HL,KeyDigits
  HALT
  IN A,(C)
  BIT 5,A
  JR NZ,TitleKeys
  AND $02
  LD A,$01
  JR NZ,TitleMethod
TitleKeys:
  LD A,$02
  BIT 1,(HL)
  JR NZ,TitleMethod
  INC A
  BIT 3,(HL)
  JR NZ,TitleMethod
  LD A,(KeyCode)
  SUB $20
  JR NZ,TitleLoop
TitleKeyboard:
  LD B,A
  JR TitleStart
TitleMethod:
  LD (ControlMethod),A
  AND $03
  LD B,A
TitleStart:
  LD HL,Options
  LD A,(HL)
  AND $FC
  OR B
  LD (HL),A
  CALL NewGameVector
  XOR A
  LD (WitchSpace),A
  LD (Condition),A
  LD (SunGrows),A
  LD (SunNear),A
  LD (CloakOn),A
  LD (LastSunRadius),A
  CALL DashboardSave
  CALL ScreenStatus
  CALL ResetControls
  JR FlightLoop

; The title text and "LOAD NEW COMMANDER (Y/N)?" (other token 6, row 14, column
; 1)
;
; Used by the routine at TitleLoad.
TitleTextLoad:
  CALL TitleElite
  LD HL,$0E01
  LD A,$06
  JR TitleTextPrint

; The title text and "PRESS SPACE, COMMANDER" (other token 7, row 14, column 4)
;
; Used by the routine at TitleNext.
TitleTextPress:
  CALL TitleElite
  LD HL,$0E04
  LD A,$07

; TitleTextPrint
;
; Used by the routine at TitleTextLoad.
TitleTextPrint:
  LD (TextColumn),HL
  LD HL,(PrintPointer)
  INC HL
  INC HL
  SET 7,(HL)
  CALL PrintOtherVector
  JR PlainText

; "---- E L I T E ----" (code $1D: token $8F) at row 1, column 5, in the title
; colours
;
; Used by the routines at TitleTextLoad and TitleTextPress.
TitleElite:
  LD HL,$0105
  LD (TextColumn),HL
  LD A,$1D
  LD HL,(PrintPointer)
  INC HL
  INC HL
  SET 7,(HL)
  CALL PrintCodeVector

; Clear the title-colour bit the two title texts set
;
; Used by the routine at TitleTextPrint.
PlainText:
  LD HL,(PrintPointer)
  INC HL
  INC HL
  RES 7,(HL)
  RET

; The attributes of the top two thirds: white INK on black
;
; Used by the routines at Title and TitleNext.
WhiteAttrs:
  LD HL,$5800
  CALL FillAttrPage

; 256 attributes $07 from HL
;
; Used by the routine at WhiteAttrs.
FillAttrPage:
  LD B,$00
  LD A,$07
FillAttrPageLoop:
  LD (HL),A
  INC HL
  DJNZ FillAttrPageLoop
  RET

; The title ship counter: the next title ship's blueprint
TitleShipCount:
  DEFB $06
