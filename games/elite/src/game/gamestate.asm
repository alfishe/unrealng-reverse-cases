; --------------------------------------------------------------------------------------------------------------------
; gamestate.asm: The screen table and the vectors, the commander record, the dashboard messages, the full-page messages, cash, legal status and cargo
;
; The top part of the game is reached through the vectors at $D000-$D0F5: ScreenTable for the docked screens and the
; charts (CallScreen patches its CALL to $D000 + 3 x the screen), then the printer, the jump keys and the commander
; menu. The commander record $D054-$D0B9 (102 bytes, the block the tape saves and loads) is a copy of the default
; commander DefaultCommander $D232 after a new game; before that, at load time, its bytes are the kickoff code that
; started the game (docs/03-build-and-load.md 3.7). The fields: the name (10 letters), the legal status ($D05F), the
; combat score ($D060, three bytes), the galaxy, the cash, the cargo hold ($D06B, 17 commodities), the free space
; ($D07C), the lasers ($D07D, four views), the fuel ($D082), the missiles ($D083), the equipment flags ($D084-$D08D),
; the galaxy's and the system's seeds, the market's stock ($D09E), the mission state ($D0AF) and flags ($D0B0). The
; layout agrees with zx-elite's COMMANDER-STATE and DATA-STRUCTURES; the addresses here are this image's.
;
; The dashboard messages are ten slots at $D0BD (a byte with bit 7 the request, then an argument): the code sets a bit
; and ShowMessage prints it in the message line over a few frames.
; --------------------------------------------------------------------------------------------------------------------

; ScreenTable 0: buy cargo (the key 2 docked)
ScreenBuy:
  JP BuyCargo

; ScreenTable 1: sell cargo (3)
ScreenSell:
  JP SellCargo

; ScreenTable 2: equip the ship (4)
ScreenEquip:
  JP EquipShip

; ScreenTable 3: the galactic chart (I)
ScreenGalaxy:
  JP GalacticChart

; ScreenTable 4: the local chart (O)
ScreenLocal:
  JP ShortRangeChart

; ScreenTable 5: the data on a system (P)
ScreenData:
  JP DataScreen

; ScreenTable 6: the market prices (K)
ScreenMarket:
  JP MarketPrices

; ScreenTable 7: the commander's status (L), also after a dock
;
; Used by the routines at TitleNext and FlightLoop.
ScreenStatus:
  JP StatusScreen

; ScreenTable 8: the inventory (ENTER)
ScreenInventory:
  JP InventoryScreen

; ScreenTable 9-15: the chart keys (ChartCursorKeys): 9 left (N, KeySteer bit
; 0), the cursor one x less (ChartLeft)
CursorLeft:
  JP ChartLeft

; 10: right (M), ChartRight
CursorRight:
  JP ChartRight

; 11: down (X), two y more, ChartDown
CursorDown:
  JP ChartDown

; 12: up (S), ChartUp
CursorUp:
  JP ChartUp

; 13: B (KeyChart bit 4), the cursor back on the current system (ChartHome)
CursorHome:
  JP ChartHome

; 14: D (KeyChart bit 5), the nearest system's name and distance (ShowSelected)
CursorDistance:
  JP ShowSelected

; 15: R (KeyChart bit 6), PLANET NAME? (PlanetNamePrompt)
PlanetNameVector:
  JP PlanetNamePrompt

; ScreenTable 16: NextGalaxy: no key and no caller asks for 16 (CallScreen gets
; 0-15), so it is never reached
NextGalaxyVector:
  JP NextGalaxy

; NewGame $D298
;
; Used by the routine at TitleNext.
NewGameVector:
  JP NewGame

; ClearScreen $D61D: the page cleared, its frame drawn
;
; Used by the routines at TitleLoad and DashboardRestoreNow.
ClearScreenVector:
  JP ClearScreen

; PrintOther $D45F: the other token set
;
; Used by the routines at TitleTextPrint and FlightLoop.
PrintOtherVector:
  JP PrintOther

; ViewTexts $DA7A: the view's texts and the countdown
;
; Used by the routines at FlightLoop and TunnelFrameText.
ViewTextsVector:
  JP ViewTexts

; A launch or dock tunnel is running
TunnelOn:
  DEFB $00

; The tunnel's frames run inside one call; the views are locked meanwhile
TunnelLoop:
  DEFB $00

; Non-zero while the cloaking device is on (CloakKey): the view tinted blue,
; the energy drain one more; ENERGY LOW turns it off
CloakOn:
  DEFB $00

; JumpKeys $DBA2: the hyperspace keys (in the interrupt)
;
; Used by the routine at FlightLoop.
JumpKeysVector:
  JP JumpKeys

; The print position: the column and the row
TextColumn:
  DEFB $00

; TextRow
TextRow:
  DEFB $00

; 0 off, 1 armed, 2 locked
MissileState:
  DEFB $00

; PrintCode $D425: the standard token set
;
; Used by the routines at AddDigit, TitleElite, ConditionLight, DrawIndicators,
; PrintNext and DrawMissiles.
PrintCodeVector:
  JP PrintCode

; The address of the printer's plot byte ($D548): $A9 (XOR C) mixes a glyph
; into the screen, $00 (NOP) writes it over (the dashboard's indicators)
PrintTarget:
  DEFW $D548

; PrintSpare
PrintSpare:
  DEFB $00

; CommanderMenu $D90A: load or save a commander
;
; Used by the routines at TitleLoad and FlightLoop.
CommanderMenuVector:
  JP CommanderMenu

; The chart's crosshair: x, y and the circle's radius
CrossX:
  DEFB $00

; CrossY
CrossY:
  DEFB $00

; ChartRadius
ChartRadius:
  DEFB $00

; The commander record: the name, 10 letters and a zero
CommanderName:
  DEFM "          ",$00

; 0 clean, up to 49 an offender, 50 or more a fugitive; bit 6 set by a
; protected kill
LegalStatus:
  DEFB $DD

; The combat score (the rating): the low byte, then two
CombatScore:
  DEFB $21,$BA,$D0

; The jumps, the galaxy, the cash and the price fluctuation
CommanderRest:
  DEFB $11,$EE,$2E,$3E,$FF,$37,$CD,$02

; The tons (or kg, g) of each commodity
CargoHold:
  DEFB $08,$DD,$21,$00,$5B,$11,$48,$05,$3E,$FF,$37,$CD,$02,$08,$00,$00,$00

; The hold's free space in tons
FreeSpace:
  DEFB $CD

; The laser of each view: 0 none, 1 pulse, 2 beam, 3 military, 4 mining
LaserMounts:
  DEFB $13,$C2,$21,$00

; The record's +$2D: 1 in the system whose sun goes nova (JumpArrive after 32
; jumps), until the jump out; the red tint, the refugees' question
; (RefugeeQuestion)
NovaMission:
  DEFB $C8

; The fuel in tenths of a light year
Fuel:
  DEFB $11

; The missiles fitted (0-4)
Missiles:
  DEFB $00

; The equipment flags: the large cargo bay, ECM, two spare, the fuel scoop, the
; escape pod, the energy bomb, the energy unit, the docking computer, the
; galactic hyperdrive
Equipment:
  DEFB $C0,$01,$00,$08,$ED,$B0,$11,$00,$BE,$06

; The spare bytes, the galaxy's three seeds, the system's three seeds
Seeds:
  DEFB $00,$48,$60,$68,$7D,$12,$14,$7C,$12,$15,$1C,$09,$0C,$09,$20,$F4

; The station's stock of each commodity
MarketStock:
  DEFB $3E,$FD,$ED,$47,$ED,$5E,$C3,$E0,$70,$00,$00,$00,$00,$00,$00,$00,$00

; The Thargoid mission: 0 none, 1 the MAYDAY heard, 2 not yet answered, 3
; accepted, 4 in the galaxy's first system (the station a Thargoid base), $0C
; its station destroyed, 5 rewarded at the next dock
MissionState:
  DEFB $00

; Bit 0 the nova started (32 jumps), 1 the cloak ship due (128 jumps), 2 the
; Thargoid MAYDAY started (254 jumps), 3 the Thargoid mission done, 5 refugees
; aboard, 6 the cloaking device owned, 7 the Thargoid mission accepted (the ECM
; jammer)
MissionFlags:
  DEFB $00

; The record's last nine bytes: the system docked at ($D0B2, $D0B3) and the
; sun's place
RecordTail:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; Past the record: the sun's growth
SunGrows:
  DEFB $00

; The chart cursor (galaxy coordinates)
ChartCursorX:
  DEFB $00

; ChartCursorY
ChartCursorY:
  DEFB $00

; Ten message slots (MessageTick): a column (bit 7 the request) and a standard
; code each
;
; 0 MISSILE JAMMED, 1 INCOMING MISSILE, 2 TARGET LOST, 3 an item DESTROYED
; (DamageItem), 4 a bounty in CR (AddCash), 5 a scooped item's name (AddCargo
; writes the code), 6 RIGHT ON COMMANDER (a new rating), 9 FUEL LEAK
; (FuelLeak); slots 7 and 8 ($D0CB-$D0CE) are the number printer's work bytes
; and never requested.
Messages:
  DEFB $08,$C9
  DEFB $07,$78
  DEFB $09,$C8
  DEFB $02,$FD
  DEFB $0C,$E2
  DEFB $0B,$00
  DEFB $06,$65
  DEFB $00,$01
  DEFB $00,$00
  DEFB $0A,$1F

; The printer's case state: the mode, the capital-next flags, the word
; buffering
PrintCase:
  DEFB $00

; PrintCapital
PrintCapital:
  DEFB $01

; PrintCapitalNext
PrintCapitalNext:
  DEFB $00

; PrintBuffering
PrintBuffering:
  DEFB $00

; The printer's patched address
PrintPointer:
  DEFW $D508

; Vectors: a full-page message, the dashboard keys off, the mission question
;
; Used by the routine at PirateStation.
FullMessageVector:
  JP FullMessage

; ClearHighlightsVector
;
; Used by the routine at ResetFlight.
ClearHighlightsVector:
  JP ClearMessages

; MissionQuestionVector
;
; Used by the routine at ArrivalScreens.
MissionQuestionVector:
  JP MissionQuestion

; TradeDoneVector
TradeDoneVector:
  JP FuelLeak

; The slot the missile is locked on
MissileTarget:
  DEFB $00

; AddCargo $D190: a scooped item
;
; Used by the routine at Collide.
AddCargoVector:
  JP AddCargo

; AddCash $D1D9: a bounty
;
; Used by the routine at UpdateSlot.
AddCashVector:
  JP AddCash

; AddCombat $D1C7: the combat score
;
; Used by the routines at UpdateSlot and MissileHoming.
AddCombatVector:
  JP AddCombat

; MissionDone $D14D
;
; Used by the routine at ArrivalScreens.
MissionDoneVector:
  JP MissionDone

; VectorSpare
VectorSpare:
  DEFB $00,$00,$00

; DamageItem $D1E9: a hit that went through the shields
;
; Used by the routine at ShieldHit.
DamageVector:
  JP DamageItem

; A game over page: SHIP BOARDED BY (other $0B), other token A ($0D PIRATE, $D4
; THARGON) and S, THEY SHOW NO MERCY... (other $FF), a click, a key, the page
; cleared
;
; Used by the routine at FullMessageVector.
FullMessage:
  PUSH AF
  LD DE,$0B17
  LD HL,$0703
  CALL ColourPage
  POP AF
  CALL PrintOther
  LD A,$5D
  CALL PrintOther
  LD HL,$0B04
  LD (TextColumn),HL
  LD A,$FF
  CALL PrintOther
; This entry point is used by the routine at MissionText.
FullMessageWait:
  CALL Click
  CALL WaitKey
  CALL ClearScreen
  CALL Wait36
  JP ClearKeys4

; WANTED BY GALCOP: A BRAVE COMMANDER FOR A SPECIAL MISSION, ARE YOU INTERESTED
; (Y/N)? (other $DF); Y: state 3, flag bit 7 and the briefing (other $E0); any
; other key: state 0
;
; Used by the routine at MissionQuestionVector.
MissionQuestion:
  LD DE,$DF1F
  LD HL,$0405
  CALL ColourPage
  CALL WaitKey
  CP $59
  JR Z,MissionAccept
  XOR A
  LD (MissionState),A
  RET
MissionAccept:
  LD HL,MissionFlags
  SET 7,(HL)
  LD A,$03
  LD (MissionState),A
  LD DE,$E017
  LD HL,$0200

; MissionText
;
; Used by the routines at MissionDone and SellCargo.
MissionText:
  CALL ColourPage
  JR FullMessageWait

; The Thargoid mission's award: the combat score's high byte one more, state 0,
; flag bit 3, IN APPRECIATION OF YOUR EXCEPTIONAL COURAGE ... (other $0A)
;
; Used by the routine at MissionDoneVector.
MissionDone:
  LD HL,CombatScore+$0002
  INC (HL)
  XOR A
  LD (MissionState),A
  LD HL,MissionFlags
  SET 3,(HL)
  LD DE,$0A0F
  LD HL,$0300
  JR MissionText

; Clear the page, other token $5C (a capital next), all 768 attributes E, the
; position HL, then other token D
;
; Used by the routines at FullMessage, MissionQuestion, MissionText and
; BuyCargo.
ColourPage:
  PUSH HL
  PUSH DE
  CALL ClearScreen
  LD A,$5C
  CALL PrintOther
  POP DE
  POP HL
  LD (TextColumn),HL
  LD HL,$5800
  LD BC,$0300
ColourPageFill:
  LD (HL),E
  INC HL
  DEC C
  JR NZ,ColourPageFill
  DEC B
  JR NZ,ColourPageFill
  LD A,D
  JP PrintOther

; $FF: the cloak ship's canister: the cloaking device (flag bit 6), the combat
; score's high byte one more, CLOAKING DEVICE on the message line
;
; Used by the routine at AddCargo.
AddCargoSpecial:
  LD HL,MissionFlags
  SET 6,(HL)
  LD HL,CombatScore+$0002
  INC (HL)
  LD A,$7D
  JR AddCargoMessage

; One unit of commodity A into the hold (one less free space), the message, and
; the legal cost of the contraband
;
; Firearms ($0A) cost 2, slaves (3) and narcotics (6) cost 4 on LegalStatus, up
; to $FF.
AddCargo:
  PUSH AF
  CP $FF
  JR Z,AddCargoSpecial
  LD HL,FreeSpace
  DEC (HL)
  LD E,A
  LD D,$00
  LD HL,CargoHold
  ADD HL,DE
  INC (HL)
  ADD A,$D0
; This entry point is used by the routine at AddCargoSpecial.
AddCargoMessage:
  LD HL,Messages+$000A
  SET 7,(HL)
  INC HL
  LD (HL),A
  POP AF
  LD B,$01

; AddCargoContraband
;
; Used by the routine at BuyCheck.
AddCargoContraband:
  CP $0A                  ; The legal cost of commodity A (BuyCheck enters here
                          ; for each unit bought)
  JR Z,AddCargoLegal
  CP $03
  JR Z,AddCargoLegal4
  CP $06
  RET NZ
AddCargoLegal4:
  SLA B
AddCargoLegal:
  SLA B
  LD HL,LegalStatus
  LD A,(HL)
  ADD A,B
  JR NC,AddCargoStore
  LD A,$FF
AddCargoStore:
  LD (HL),A
  RET

; The combat score plus DE; a carry into the third byte flags the rating
; message ($D0C9)
;
; Used by the routine at AddCombatVector.
AddCombat:
  LD HL,CombatScore
  LD A,(HL)
  ADD A,E
  LD (HL),A
  INC HL
  LD A,(HL)
  ADC A,D
  LD (HL),A
  RET NC
  INC HL
  INC (HL)
  LD HL,Messages+$000C
  JR AddCashMessage

; The cash plus DE (a bounty) and the message ($D0C5)
;
; Used by the routine at AddCashVector.
AddCash:
  LD A,D
  OR E
  RET Z
  LD (MessageNumber),DE
  CALL AddCredits
  LD HL,Messages+$0008
; This entry point is used by the routine at AddCombat.
AddCashMessage:
  SET 7,(HL)
  RET

; A random loss: below 1 the fuel, 1-6 a piece of equipment, 7-16 a unit of
; cargo (StarSeed's bits)
;
; 25 runs in f1 and w1 (the ships' lasers), none lost anything: every random
; pick was empty or 17 and above.
DamageItem:
  LD A,(MessageToken)
  CP $FD
  RET Z
  LD A,(StarSeed)
  RRCA
  RRCA
  AND $3F
  JP Z,FuelLeak
  CP $11
  RET NC
  DEC A
  CP $06
  JR NC,DamageItemCargo
  LD HL,Equipment+$0001
  AND A
  JR Z,DamageItemEquip
  ADD A,$02
DamageItemEquip:
  CALL AddAToHL
  LD A,(HL)
  AND A
  RET Z
DamageItemLost:
  LD (HL),D
  LD A,E
  ADD A,$6C
DamageItemMessage:
  LD (MessageItem),A
  CALL AttrFillVector
  LD HL,Messages+$0006
  SET 7,(HL)
  RET
DamageItemCargo:
  LD HL,CommanderRest+$0004
  CALL AddAToHL
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  LD HL,FreeSpace
  INC (HL)
  LD A,$CC
  ADD A,E
  JR DamageItemMessage

; The new game's commander: JAMESON, 100.0 Cr, 7.0 light years of fuel, a pulse
; laser, 3 missiles, galaxy 1 at Lave
DefaultCommander:
  DEFB $4A,$41,$4D,$45,$53,$4F,$4E,$20
  DEFB $20,$20,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$E8,$03,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $14,$01,$00,$00,$00,$00,$46,$03
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$4A,$5A,$48,$02
  DEFB $53,$B7,$38,$AD,$9C,$14,$1D,$15
  DEFB $05,$03,$11,$12,$1A,$0E,$27,$08
  DEFB $00,$00,$0A,$19,$00,$00,$3D,$0E
  DEFB $11,$0C,$00,$00,$00

; The new game's sun and planet place
DefaultSun:
  DEFB $27,$08,$01,$2A,$4D,$8F,$F2,$88,$05

; The default commander copied in, the chart cursor on Lave, the prices made
; (MakeMarket with its stock store patched to a NOP: the stock is the
; record's), the sun placed
;
; Used by the routine at NewGameVector.
NewGame:
  CALL ClearMessages
  LD HL,DefaultCommander
  LD DE,CommanderName
  LD BC,$005D
  LDIR
  LD A,(Seeds+$000B)
  LD (ChartCursorX),A
  LD A,(Seeds+$0009)
  LD (ChartCursorY),A
  CALL FindNearestNow
  LD HL,MakeMarketPrice+$0012
  LD (HL),$00
  PUSH HL
  CALL MakeMarket
  POP HL
  LD (HL),$77
  LD HL,SelectedName
  LD DE,CurrentName
  LD BC,$0008
  LDIR
  LD HL,DefaultSun
  LD DE,SunPosition
  LD BC,$0009
  LDIR
  XOR A
  LD (JumpCountdown),A
  RET
