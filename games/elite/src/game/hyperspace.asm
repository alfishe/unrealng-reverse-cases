; --------------------------------------------------------------------------------------------------------------------
; hyperspace.asm: The jump keys, the countdown, the arrival in a new system or in witch space, the galactic jump, the three missions' triggers
;
; H starts a hyperspace jump to the selected system, H with G held a galactic one (with the galactic hyperdrive). A
; countdown of 10 shows at the top left; at 0 JumpArrive makes the selected system the current one, places the sun,
; the planet and the station from its seeds, builds the market and runs the tunnel (TunnelLoop). Witch space comes
; instead with one chance in 256 (StarSeed $F9) or always with option bit 6 of the pause menu (F): the ship stops half
; way, with no sun, planet or station, among Thargoids (WitchSpace).
;
; Outside galaxy 1 the jump count ($D063) starts the missions: at 32 jumps the sun goes nova (NovaMission, a FUEL
; LEAK), at 128 the cloak ship may come (MissionFlags bit 1), at 254 the Thargoid MAYDAY (MissionState 1). An arrival
; may also leave the station pirate-held (PirateStation). The recordings jumped twice (f1 to a system, w1 into witch
; space); the galactic jump and the missions are known from the code only.
; --------------------------------------------------------------------------------------------------------------------

; H or G+H (KeyViews $FC0A bits 4, 5): a jump, unless one counts down; docked:
; DOCKED and the status screen
;
; Called each pass through JumpKeysVector (197283 runs, 4 with a key). The keys
; are cleared at once. A hyperspace needs the distance to the selected system
; (FindNearest, JumpDistance) above 0, below 25.6 light years and within the
; fuel, else HYPERSPACE RANGE ? (code $C1); a galactic jump needs the galactic
; hyperdrive ($D08D). Then TunnelOn 1 (a jump) or 2 (galactic), the countdown
; 21 and HYPERSPACE -- <system> (code $C0) or GALACTIC HYPERSPACE (code $74) on
; the message line, a click, and the front view if a space view was on.
JumpKeys:
  LD HL,KeyViews
  LD A,(HL)
  AND $30
  RET Z
  LD B,A
  LD A,(HL)
  AND $CF
  LD (HL),A
  LD A,(JumpCountdown)
  AND A
  RET NZ
  LD A,(Condition)
  AND A
  JR Z,JumpDocked
  BIT 5,B
  JR Z,JumpHyper
JumpGalactic:
  BIT 4,B
  RET Z
  LD A,(Equipment+$0009)
  AND A
  RET Z
  LD A,$02
  LD (TunnelOn),A
  LD BC,$7406
  JR JumpCount
JumpHyper:
  CALL FindNearest
  LD HL,(JumpRange)
  LD A,H
  AND A
  JR NZ,JumpOutOfRange
  LD A,L
  AND A
  RET Z
  LD B,A
  LD A,(Fuel)
  SUB B
  JR C,JumpOutOfRange
JumpStart:
  LD A,$01
  LD (TunnelOn),A
  LD BC,$C005
JumpCount:
  LD A,$15
  LD (JumpCountdown),A
  LD (MessageShown),A
  CALL MessageSet
  CALL Click
  LD A,(ViewIndex)
  CP $04
  RET NC
  XOR A
  LD (ViewIndex),A
  RET
JumpOutOfRange:
  LD BC,$C106
  JP MessageTickJoin
JumpDocked:
  CALL ClearScreen
  LD HL,$070B
  LD (TextColumn),HL
  LD A,$01
  LD (PrintCase),A
  LD A,$CD
  CALL PrintOther
  CALL Click
  CALL Wait36
  CALL ClearKeys4
  JP StatusScreen

; Each MessageTick: the countdown (shown halved, two digits at 1,1), and at 0
; the jump itself
;
; 1220 runs in c1, f1 and w1; 42 counted, 2 jumped. The jump: the message slots
; cleared; a galactic jump (TunnelOn 2) or any jump out of the nova system goes
; to the next galaxy (GalaxyJump); a hyperspace takes the fuel (the distance),
; sets the fuel's refill price ($7060 = 70 - the fuel left + 2 x the economy),
; halves the legal status, and either misjumps (JumpWitch) or arrives
; (JumpArrive).
JumpTick:
  LD HL,JumpCountdown
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  JR Z,JumpNow
JumpTickShow:
  LD B,A
  LD A,$02
  LD (Messages+$0011),A
  LD HL,$0101
  LD (TextColumn),HL
  LD A,B
  SRL A
  JP PrintByte
JumpNow:
  CALL ClearMessages
  LD A,(TunnelOn)
  SUB $02
  JR NZ,JumpHyperspace

; The next galaxy: the missions reset (the nova over, the Thargoids forgotten),
; the hyperdrive used up, the seeds twisted, the legal status clean, the system
; nearest the cursor
;
; The fuel price $7060 gets the galaxy number (1-8) here. Each of the six seed
; bytes is rotated left one bit (TwistSeed) as BBC Elite does; the galaxy
; number wraps from 8 to 1.
GalaxyJump:
  XOR A
  LD (MissionState),A
  LD A,(NovaMission)
  AND A
  JR Z,GalaxyJumpNext
  XOR A
  LD (NovaMission),A
  LD (SunGrows),A
GalaxyJumpNext:
  LD (Equipment+$0009),A
  LD A,(CommanderRest+$0002)
  INC A
  LD (EquipmentPrices+$0001),A
  AND $07
  LD (CommanderRest+$0002),A
  LD HL,Seeds+$0002
  CALL TwistSeed
  CALL TwistSeed
  CALL TwistSeed
  XOR A
  LD (LegalStatus),A
  CALL FindNearest
  JR JumpArrive

; The two bytes at HL rotated left one bit each, HL two on
;
; Used by the routine at GalaxyJump.
TwistSeed:
  LD E,(HL)
  RLC E
  LD (HL),E
  INC HL
  LD D,(HL)
  RLC D
  LD (HL),D
  INC HL
  RET
; This entry point is used by the routine at JumpTick.
JumpHyperspace:
  LD A,(NovaMission)
  AND A
  JR NZ,GalaxyJump
  LD A,(JumpRange)
  LD B,A
  LD A,(Fuel)
  SUB B
  LD C,A
  CALL SetFuel
  LD A,$46
  SUB C
  LD B,A
  LD A,(Economy)
  SLA A
  ADD A,B
  LD (EquipmentPrices+$0001),A
  LD HL,LegalStatus
  SRL (HL)
  LD A,(Options)
  BIT 6,A
  JR NZ,JumpWitch
  LD A,(StarSeed)
  CP $F9
  JR NZ,JumpArrive

; The misjump: WitchSpace on, the current system half way to the selected one,
; no safe zone, no system names
;
; The current system's coordinates ($D099, $D097) and the cursor become the mid
; points; the names of the current and the selected system are emptied ($DEE4,
; $DEED), so the status page shows none. w1: F of the pause menu (option bit 6)
; forced it.
JumpWitch:
  INC A
  LD (WitchSpace),A
  LD HL,Seeds+$000B
  LD DE,ChartCursorX
  LD A,(DE)
  ADD A,(HL)
  RR A
  LD (HL),A
  LD (DE),A
  LD HL,Seeds+$0009
  LD DE,ChartCursorY
  LD A,(DE)
  ADD A,(HL)
  RR A
  LD (HL),A
  LD (DE),A
  XOR A
  LD (SafeZone),A
  LD (CurrentName),A
  LD (SelectedName),A
  JP JumpEnd

; The arrival: the selected system becomes the current one; the sun, the planet
; and the station from its seeds; the market
;
; The seeds ($DEBA) go to the current system ($D096), the selected name to the
; current name, the tech level and the government to $D09C and $D09D, NewMarket
; with a fresh fluctuation byte, the sun and the planet cleared, StationLaunch
; $FF. The coordinates' top bytes come from the seeds: the sun's x and y (s1,
; s2 high bytes AND $83 OR 1: within ±3 pages, never 0) and z (s1 high OR low,
; AND 7, + 4, negative: behind), the planet's x and y the same way from s0 and
; s1's low bytes and z (s0 high OR low, AND 7, + 3) ahead. The station starts
; at the planet (slot 0 copied from PlanetPosition) and is moved about a page
; off along z or x (a seed bit picks; the middle byte's bit 7 set, the top byte
; one nearer or further), its axes set from the side it was moved to. f1: 1
; run.
JumpArrive:
  XOR A
  LD (WitchSpace),A
  LD HL,SelectedSeeds
  LD DE,Seeds+$0008
  LD BC,$0006
  LDIR
  LD HL,SelectedName
  LD DE,CurrentName
  LD BC,$0008
  LDIR
  LD A,(TechLevel)
  LD (Seeds+$000E),A
  LD A,(Government)
  LD (Seeds+$000F),A
  CALL NewMarket
  LD B,$12
  XOR A
  LD HL,SunPosition
JumpArriveLoop:
  LD (HL),A
  INC HL
  DJNZ JumpArriveLoop
  LD A,$FF
  LD (StationLaunch),A
  LD HL,(SelectedSeeds)
  LD DE,(SelectedSeeds+$0002)
  LD BC,(SelectedSeeds+$0004)
  LD A,B
  AND $83
  OR $01
  LD (SunPosition+$0002),A
  LD A,C
  AND $83
  OR $01
  LD (SunPosition+$0005),A
  LD A,D
  OR E
  AND $07
  ADD A,$04
  OR $81
  LD (SunPosition+$0008),A
  LD A,L
  AND $83
  OR $01
  LD (PlanetPosition+$0002),A
  LD A,E
  AND $83
  OR $01
  LD (PlanetPosition+$0005),A
  LD A,H
  OR L
  AND $07
  ADD A,$03
  LD (PlanetPosition+$0008),A
  PUSH BC
  LD BC,$0009
  LD HL,PlanetPosition
  LD DE,ShipSlots
  LDIR
  POP BC
JumpArriveStation:
  LD A,(PlanetPosition+$0008)
  LD HL,ShipSlots+$0007
  SRL C
  JR C,JumpArriveOffset
  LD A,(PlanetPosition+$0002)
  LD HL,ShipSlots+$0001
JumpArriveOffset:
  SET 7,(HL)
  LD B,A
  AND $7F
  SRL C
  JR C,JumpArriveFar
  CP $01
  JR NZ,JumpArriveNear
  LD D,A
  LD A,B
  XOR $80
  LD B,A
  LD A,D
  JR JumpArriveStep
JumpArriveNear:
  DEC A
JumpArriveStep:
  DEC A
  JR JumpArriveSide
JumpArriveFar:
  INC A
JumpArriveSide:
  SLA A
  SLA B
  RR A
  INC HL
  LD (HL),A
  XOR A
  LD HL,ShipSlots+$0009
  LD B,$12
JumpArriveLoop2:
  LD (HL),A
  INC HL
  DJNZ JumpArriveLoop2
  LD HL,PlanetPosition+$0007
  LD A,(ShipSlots+$0007)
  CP (HL)
  LD A,$7F
  LD (ShipSlots+$0012),A
  JR NZ,JumpArriveZ
JumpArriveX:
  LD BC,ShipSlots+$001A
  LD DE,ShipSlots+$000A
  LD (BC),A
  LD (DE),A
  LD HL,PlanetPosition+$0002
  LD A,(ShipSlots+$0002)
  CP (HL)
  LD A,$FF
  JR C,JumpArriveXFlip
  LD (DE),A
  JR JumpArriveCursor
JumpArriveXFlip:
  LD (BC),A
  JR JumpArriveCursor
JumpArriveZ:
  LD BC,$605E
  LD DE,ShipSlots+$000E
  LD HL,PlanetPosition+$0008
  LD A,(ShipSlots+$0008)
  CP (HL)
  JR C,JumpArriveZPlus
  LD A,$FF
  JR JumpArriveAxes
; This entry point is used by the routine at MissionTriggers.
MissionStationGone:
  LD A,$05                ; The Thargoid base was destroyed (the station's role
                          ; bit 7): MissionState 5, the award at the next dock
  JR MissionTriggersSetMissionState
JumpArriveZPlus:
  LD A,$7F
JumpArriveAxes:
  LD (BC),A
  LD (DE),A
JumpArriveCursor:
  LD A,(ChartCursorX)
  LD (Seeds+$000B),A
  LD A,(ChartCursorY)
  LD (Seeds+$0009),A
  LD A,(CommanderRest+$0002)
  AND A
  JR Z,JumpEnd

; Outside galaxy 1: the Thargoid mission's stage, the jump count, the three
; triggers, the pirate station's chance
;
; MissionState 1 becomes 2 (the MAYDAY left unanswered), 4 becomes 3 (left the
; base); arriving in the galaxy's first system (IsFirstSystem) with the mission
; on makes it 4. The jump count at 32 starts the nova (flag bit 0, NovaMission,
; the red tint, FuelLeak), at 128 the cloak ship (bit 1), at 254 the MAYDAY
; (bit 2, MissionState 1). With no trigger the station turns pirate-held when
; StarSeed is at most (7 - government) / 2: one chance in 256 for a corporate
; state, four for an anarchy.
MissionTriggers:
  LD HL,ShipSlots+$0026
  BIT 7,(HL)
  RES 7,(HL)
  JR NZ,MissionStationGone
  LD HL,MissionState
  LD A,(HL)
  AND A
  JR Z,MissionTriggersCount
  DEC A
  JR NZ,MissionTriggersLeft
  INC (HL)
  JR MissionTriggersBase
MissionTriggersLeft:
  CP $03
  JR NZ,MissionTriggersBase
  LD (HL),A
MissionTriggersBase:
  LD HL,Seeds+$0008
  CALL IsFirstSystem
  JR C,MissionTriggersCount
  LD A,$04
; This entry point is used by the routine at JumpArrive.
MissionTriggersSetMissionState:
  LD (MissionState),A
MissionTriggersCount:
  LD HL,(CommanderRest)
  INC HL
  LD (CommanderRest),HL
  LD DE,MissionFlags
  LD A,(DE)
  RRCA
  JR NC,MissionNova
  RRCA
  JR NC,MissionCloak
  RRCA
  JR NC,MissionThargoids

; The station pirate-held (its roll counter's bit 7 cleared) with a chance by
; the government
;
; Used by the routines at MissionNova, MissionCloak and MissionThargoids.
PirateChance:
  LD HL,StarSeed
  LD A,(Seeds+$000F)
  XOR $FF
  AND $07
  RRA
  CP (HL)
  JR C,JumpEnd
  LD HL,ShipSlots+$001D
  RES 7,(HL)

; The tunnel next (TunnelLoop 1), the front view, the cabin temperature,
; SunNear, MissileState and MissionShip 0, the altitude $A0
;
; Used by the routines at JumpWitch, JumpArrive, PirateChance, MissionNova,
; MissionCloak and MissionThargoids.
JumpEnd:
  LD A,$01
  LD (TunnelLoop),A
  XOR A
  LD (ViewIndex),A
  LD (BarCabinTemp),A
  LD (SunNear),A
  LD (MissileState),A
  LD (MissionShip),A
  LD A,$A0
  LD (BarAltitude),A
  RET

; 32 jumps: the sun goes nova: flag bit 0, NovaMission, the view red, a fuel
; leak
;
; Used by the routine at MissionTriggers.
MissionNova:
  LD A,L
  CP $20
  JR C,PirateChance
  EX DE,HL
  SET 0,(HL)
  LD A,$01
  LD (NovaMission),A
  LD L,$02
  CALL FillAttrsVector
  CALL FuelLeak
  JR JumpEnd

; 128 jumps: the cloak ship may come (flag bit 1)
;
; Used by the routine at MissionTriggers.
MissionCloak:
  LD A,L
  CP $80
  JR C,PirateChance
  EX DE,HL
  SET 1,(HL)
  JR JumpEnd

; 254 jumps: the Thargoid MAYDAY (flag bit 2, MissionState 1)
;
; Used by the routine at MissionTriggers.
MissionThargoids:
  LD A,L
  CP $FE
  JR C,PirateChance
  EX DE,HL
  SET 2,(HL)
  LD A,$01
  LD (MissionState),A
  JR JumpEnd

; All the fuel lost, FUEL LEAK on the message line (slot 9), when there was any
;
; Used by the routines at TradeDoneVector, DamageItem and MissionNova.
FuelLeak:
  LD A,(Fuel)
  AND A
  RET Z
  LD HL,Messages+$0012
  SET 7,(HL)
  XOR A

; The fuel = A, at most 70 (7.0 light years); the fuel bar 2.25 x A
;
; Used by the routines at MessagePeriodic, TwistSeed and EquipShip.
SetFuel:
  CP $47
  JR C,SetFuelStore
  LD A,$46
SetFuelStore:
  LD (Fuel),A
  SLA A
  LD B,A
  SRL A
  SRL A
  SRL A
  ADD A,B
  LD (BarFuel),A
  RET
