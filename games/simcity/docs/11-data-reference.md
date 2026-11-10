# 11. Data reference

Every data entry of the game image `$5B00`-`$FE00`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository).
Written by `kit/refdocs.py`.

## entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B00` | `KeyRows` | 27 | The keyboard's eight half rows, as IN read them in the last interrupt (0 = pressed, bits 0-4). ReadInput `$F781` writes them every frame from ports `$FEFE`, `$FDFE`, `$FBFE`, `$F7FE`, `$EFFE`, `$DFFE`, `$BFFE`, `$7FFE` (in that order), then ReadKempston `$7A01` and ReadSinclair `$7A32` clear the Q, A, O, P and SPACE bits when a joystick is pushed, so every reader sees one keyboard. Row 0 bit 0 CAPS SHIFT, row 1 bit 0 A (down), row 2 bit 0 Q (up), row 5 bit 0 P (right) and bit 1 O (left), row 7 bit 0 SPACE (fire) and bit 1 SYMBOL SHIFT. L1: 3 264 254 writes (8 a frame), 5 764 078 reads with KeyNone and BitMasks. | `AnyKey`, `Click`, `MapClick`, `MapsWindow`, `MovePointer` +9 | `ReadInput` |

## input

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B7F` | `KempstonFound` | 1 | 1 when Entry found a Kempston interface (port `$1F` reads below `$1F`), else 0. Read by ReadPort1F `$5B80` every frame (L1 413 183 reads). | `ReadPort1F` | `Entry` |
| `$5B8A` | `KeyChars` | 41 | The character of each key, five a half row in ScanKey's order (CAPS SHIFT first), then the key found. Row `$FEFE` from bit 0: `$03` (CAPS SHIFT), Z X C V; `$FDFE` A S D F G; `$FBFE` Q W E R T; `$F7FE` 1-5; `$EFFE` 0 9 8 7 6; `$DFFE` P O I U Y; `$BFFE` `$08` (ENTER as delete), L K J H; `$7FFE` SPACE, ".", M N B (SYMBOL SHIFT reads as "."). KeyFound at `$5BB2` is ScanKey's result: the key's index, or `$FF` for none. Read by KeyToChar `$5BDF` (L1 1193 reads). | `KeyToChar` | `ScanKey` |
| `$5BDE` | `ScanSpare` | 1 | One byte no code reads (L1: 0 reads); kept as bytes | - | - |

## random

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CC4` | `RandomSeed` | 2 | The random seed, 16 bits; NewLandscape sets it to the gene (Gene `$6A8C`) | `Random`, `RandomDisaster` | `NewLandscape`, `Random` |

## cursor

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CEC` | `PointerShape` | 16 | The pointer: an arrow, 8 pixel rows ORed over the screen (src/res/graphics/Pointer.png). Read by DrawPointer `$5CFE` (L1 156 303 reads of each byte). | `DrawPointer` | - |
| `$5CFC` | `PointerX` | 2 | the pointer's column in half characters, 0-62 (stage 1's "cursor") | `Click`, `DrawPointer`, `OpenMenuAt`, `PointerDown`, `PointerLeft` +3 | `PointerDown`, `PointerLeft`, `PointerRight`, `PointerUp` |
| `$5D34` | `PointerSave` | 10 | The 8 screen bytes under the pointer, and their address | `ErasePointer` | `DrawPointer` |
| `$5D4F` | `BoxSize` | 6 | The map cursor's box: width and height in cells (the tool's size, ToolSizes). Written by ShowTool `$6D90`; read by TrackBox (L1 81 184 reads). | `InvertBox`, `MapClick`, `TrackBox` | `ShowTool`, `TrackBox` |

## print

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5E31` | `PrintSpare` | 4 | Four bytes no code reads (LD (`$F751`),BC: a cut instruction of the source); kept as bytes | - | - |
| `$5E95` | `BoxDims` | 2 | DrawBox's box: width and height in characters | `DrawBox`, `DrawBoxRow` | `DrawBox`, `DrawMenu` |
| `$5ED2` | `BoxSpare` | 1 | One byte no code reads; kept as bytes | - | - |
| `$5F16` | `StatusBarText` | 42 | PrintInline codes: the menu bar (SYSTEM OPTIONS DISASTERS WINDOWS) | `PrintInline` | - |
| `$5F43` | `StatusBoxText` | 10 | PrintInline codes: the status box | `DrawBox`, `PrintInline` | - |
| `$5F63` | `CityNameAt` | 28 | PrintInline codes: attribute `$39`, row 5, column 1 (the name follows) | `PrintInline` | - |
| `$5F8A` | `MonthNames` | 36 | The twelve months, three letters each, bit 7 on the last | `FindText`, `PrintPadded` | - |
| `$5FC6` | `GameTexts` | 831 | The tool names with prices, the levels, the six city classes, the 27 advice and disaster messages. 50 strings, bit 7 on each last letter, found by FindText `$6317` by index: 0-13 the tools ("BULLDOZE $1" ... "AIRPORT `$1000`0"), 14-16 the levels (EASY, MEDIUM, HARD), 17-22 the classes (VILLAGE ... MEGALOPOLIS), 23 a space, 24-49 the advice and disasters ("MORE RESIDENTIAL ZONES NEEDED" ... "TORNADO DETECTED"). Read by PrintToolName, the level name, the class name and the advice (L1 1 602 984 reads, every byte). | `FindText`, `PrintPadded` | - |

## clicks

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$63C9` | `ClickCell` | 4 | The pointer's character cell when SPACE was pressed: column (0-31), row (0-23) | `ClickToMap`, `MapClick`, `MenuClick`, `ScrollClick`, `ToolClick` | `Click` |

## renderer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6433` | `Blink` | 1 | Pass bit 4 at the start of the view row's draw: the blink phase | - | `DrawOverview`, `DrawViewRowPass` |
| `$6462` | `TileIndex` | 2 | The tile number being drawn | `DrawCell`, `DrawIcon` | `DrawCell`, `DrawIcon` |
| `$64D5` | `BuildingDummy` | 1 | A byte IX points at while a building row is drawn (no reader of its value) | - | - |
| `$6505` | `CellAttrPtr` | 6 | The attribute table of the cell being drawn (CellAttrs or BuildingAttrs) | `ClickToMap`, `DrawCell`, `DrawView`, `DrawViewRowPass`, `LayerOf` | `DrawOverview`, `DrawView` |
| `$6558` | `BuildingLeft` | 3 | The cells left in the building row being drawn | `DrawCell`, `DrawOverview`, `DrawView`, `OverviewCell` | `DrawOverview`, `DrawView` |
| `$6592` | `BuildingBack` | 1 | FindBuildingStart's count | - | - |

## arith

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$65A3` | `NumberEnd` | 2 | PrintAddr after the last number printed | - | `PrintNumber24` |
| `$664D` | `NumberFlags` | 2 | A digit printed already; the leading zeros left out | `Digit24`, `PrintNumber24` | `Digit24`, `PrintNumberVar` |

## menus

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$671F` | `FullFrameText` | 8 | PrintInline codes: a 32 x 24 frame, attribute `$47` | - | - |
| `$673E` | `WindowAreaText` | 8 | PrintInline codes: a 32 x 16 frame at row 8, attribute `$44` | `DrawBox`, `PrintInline` | - |
| `$6747` | `MenuState` | 124 | The menu being shown: IX of its description, then its line counter and the item table. MenuItems (`$674A`, 3 bytes an item: the line, the item's address) up to `$6779`, MenuValues `$677A` (3 bytes a line: the column and the address of a number field), MenuCount `$67C2`. L1 6776 reads, 5161 writes. | `AddMenuItem`, `DrawMenu`, `MenuDown`, `PrintMenuText`, `RunMenu` +1 | `AddMenuItem`, `DrawMenu` |
| `$684B` | `ToggleValue` | 1 | The toggle's flag value while it is printed | - | - |
| `$686E` | `OnText` | 3 | "ON" for a toggle | - | - |
| `$6879` | `OffText` | 4 | "OFF" | - | - |
| `$6942` | `MenuHook` | 2 | A routine the menu loop calls every pass (0: none): the graph windows' live drawing | `CallMenuHook` | - |
| `$6990` | `EditMax` | 6 | The number field being edited: the largest value, its address, its position, the key repeat | - | - |
| `$6A7D` | `MenuSelected` | 1 | The selected item | `MenuDown`, `MenuUp`, `SelectedItem`, `SetLevel` | `MenuDown`, `MenuUp`, `RunMenu` |

## landscape

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6A8C` | `Gene` | 2 | The landscape's gene, the seed of the generator (3 in the image: "00003") | `NewLandscape` | - |
| `$6AD3` | `DiscShapes` | 8 | Four pairs of shifts (4, 4), (5, 3), (3, 5), (4, 4): the disc's two axes (round, flat, tall) | `Discs` | - |
| `$6B21` | `CoastPatterns` | 132 | The coast: 66 masks of the eight land neighbours, then the 66 cell codes put on such water. Read by MakeCoast with CPIR (L1 426 157 compares). | `MakeCoast` | - |
| `$6BDA` | `MapEdge` | 1 | Set to 0 when MapAddrChecked was given a cell off the map | - | `MapAddrChecked` |
| `$6C02` | `DiscVars` | 7 | The disc being drawn: centre x, y, radius, cell, the cell it may replace (0 any), the two shifts | `Disc` | `Discs`, `NewLandscape` |

## tools

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6D50` | `CurrentTool` | 1 | The tool: 0 bulldozer, 1 road, 2 power line, 3 rail, 4 park, 5-7 R C I, 8 police, 9 fire, 10 stadium, 11 power station, 12 seaport, 13 airport | `CheckSite`, `CrossNetwork`, `MapClick`, `PrintToolName`, `ShowTool` +2 | `ToolKeys` |
| `$6DAF` | `ToolSizes` | 28 | The 14 tools' box sizes, width and height: 1 x 1 for tools 0-4, 3 x 3 for 5-9, 4 x 4 for 10-12, 6 x 6 the airport | `ToolSize` | - |
| `$6E1E` | `ToolPrices` | 28 | The 14 tools' prices: 1, 10, 5, 20, 10, 100, 100, 100, 500, 500, 3000, 4000, 5000, 10 000 | `ToolPrice` | - |
| `$6E67` | `ClickMapCell` | 3 | The map cell of the last tool click: column, row | `ClickToMap` | `ClickMapAddr` |
| `$6ED2` | `NetworkKind` | 1 | The network being laid: 7 road, `$14` rail, `$21` power line (`$30` in the image) | - | - |
| `$6ED3` | `NetworkShapes` | 16 | the shape offset by the 4-bit neighbour mask (up, left, right, down) | - | - |
| `$6F10` | `NetworkFlag` | 2 | NetworkBit's result for this FixNetwork | - | - |
| `$6F5C` | `BridgeEnd` | 3 | The last water cell the bridge line covered | - | - |
| `$6F9C` | `CellFlags` | 90 | The flags of the cells 0-`$59`: bit 0 not reshaped, 1 rail, 2 road, 3 conducts power, 4 zone, 6 developed, 7 flammable. Read by CellFlagsOf (`$7599`; L1 11 343 551). Buildings (`$80` and up) give `$99` there. The bit meanings follow from the readers: bit 0 FixNetworkCell, bit 1 the train (`$77DC`) and the rail count (`$8898`), bit 2 the road count, bits 1-2 the traffic route (`$856A`), bit 3 the power flood (`$819A`), bits 4 and 6 BuildingValue and the pollution (`$7DEA`), bit 7 the fire (`$89BB`, `$79DE`). | `CellFlagsOf` | - |
| `$6FF6` | `ToolHandlers` | 28 | The 14 tools' click routines (MapClick calls ToolHandlers[CurrentTool]) | `MapClick` | - |
| `$7062` | `Crossings` | 36 | Three pairs of 6 bytes: the cells a network may cross, then the crossing cell for each. `$7062` power over road or rail; `$706E` road over power or rail; `$707A` rail over road or power. Read by CrossNetwork (CPIR, the result 6 bytes on). | - | - |
| `$70FA` | `FreeCells` | 9 | The cells a building site takes at no cost: 2 land, 0 water | `CheckSite` | `CheckSite` |
| `$71B8` | `NetPrice` | 4 | PlaceNetwork's price per cell on land | - | - |
| `$71FF` | `BridgeDirs` | 16 | By the neighbour mask: the bridge direction (1-4; 0 none) | - | - |
| `$720F` | `BridgeSteps` | 15 | per direction 0-4: the row step, the column step, the bridge cell offset | - | - |
| `$726B` | `BulldozeKeep` | 11 | The bridge and coast-end cells: the bulldozer turns them back to water | - | - |
| `$7301` | `BulldozeCosts` | 7 | By the building's size: the price of clearing it, size squared (0, 1, 4, 9, 16, 25, 36) | - | - |
| `$737D` | `RubbleSteps` | 6 | The rubble's three steps: `$46` -> `$47` -> `$48` -> 2 (land) | - | - |
| `$73D3` | `ToolSpare` | 1 | One byte no code reads | - | - |
| `$73F1` | `ResidentialZone` | 9 | The 3 x 3 zone cells: the frame `$49-$50` round the centre `$54` (residential, unpowered) | - | - |
| `$740B` | `CommercialZone` | 9 | ... centre `$55` | - | - |
| `$7425` | `IndustrialZone` | 9 | ... centre `$56` | `PutBuilding` | - |
| `$743F` | `PoliceBuilding` | 9 | The police station, 3 x 3: building rows (`$A3` top, `$83`) with tile numbers `$C0`+ | - | - |
| `$7459` | `FireBuilding` | 9 | The fire station, 3 x 3 | - | - |
| `$7473` | `StadiumBuilding` | 16 | The stadium, 4 x 4 | - | - |
| `$7494` | `CoalPlant` | 32 | The coal power station, 4 x 4 | - | - |
| `$74E6` | `SeaportBuilding` | 16 | The seaport, 4 x 4 | - | - |
| `$7507` | `AirportBuilding` | 36 | The airport, 6 x 6 | - | - |

## cityaccess

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$753C` | `GridBase` | 2 | The array Grid48 and Grid24 read | `LayerOf` | `LayerOf` |
| `$75EF` | `PutBuildingSpare` | 2 | Two bytes no code reads | - | - |
| `$7657` | `DivLeftover` | 17 | Leftover: an older copy of a divide (LD C,L ... RET), no code runs it | - | - |
| `$7682` | `BuildingValues` | 12 | By building routine (BuildingKinds' second byte): the class TripArrived matches against TripTargets (9 R, 10 C, 11 I; police 0, fire 1, church 2, hospital 3) | - | - |
| `$76DC` | `Directions` | 8 | The four steps (column, row): up, right, down, left | - | - |
| `$76FD` | `CellStackCount` | 1 | The cells on CellStack (at `$801D`) | - | - |

## movers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$77D3` | `TrainCell` | 9 | The train (`$77D3-$77DB`): its cell (column, row), sprite, out flag, the way it came, turn, tries, steps | `DrawMovers`, `MoveTrain` | `InitSimulation` |
| `$7879` | `PlaneOut` | 5 | The plane: out flag, cell (column, row), the column it crashes at, the crash timer | `DrawMovers`, `MovePlane` | `InitSimulation` |
| `$7924` | `MeltdownPending` | 1 | Set by NuclearMeltdown; Meltdown runs at the next pass | - | `InitSimulation` |
| `$7995` | `TornadoCell` | 3 | The tornado: cell (column, row), out flag | `DrawMovers`, `MoveTornado` | `InitSimulation` |

## maps

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7AA4` | `MapsFrameText` | 101 | PrintInline codes of the frame and legend | `DrawBox`, `PrintInline` | - |
| `$7B0C` | `MapsKeysText` | 67 | PrintInline codes: the nine map choices | `PrintInline` | - |
| `$7B50` | `MapsCounter` | 1 | Counts the passes of the maps window | - | - |

## simulation

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7BEF` | `CoverKernel` | 25 | The 5 x 5 coverage kernel: the shift count of each cell (9: none) | - | - |
| `$7C08` | `FireStrength` | 1 | the fire station's strength, 0-15 (`$0F` in the image; set by ApplyFunding) | - | `InitSimulation` |
| `$7C31` | `PoliceStrength` | 1 | The police station's strength, `$0F` | - | `InitSimulation` |
| `$7C77` | `PollutionKernel` | 36 | The 6 x 6 kernel of the sources' pollution: the shift count of each cell (9: none) | - | - |
| `$7C9B` | `TrafficKernel` | 36 | The 6 x 6 kernel of the traffic's pollution | - | - |
| `$7CBF` | `PollutionStrength` | 1 | the source's strength | - | - |
| `$7D2B` | `RouteStart` | 4 | The road or rail cell next to the zone a trip starts from (`$FFFF`: none) | - | - |
| `$7E17` | `RingParks` | 6 | ScanRing's counts: parks, water, trees, transport, the amenity | - | - |
| `$7E68` | `CrimeSpare` | 2 | One byte no code reads | - | - |
| `$7E9A` | `TaxPenalty` | 1 | TaxPenaltyOf's result | - | - |
| `$7EBF` | `ZonePollutionMax` | 5 | The 2 x 2 maximum of Pollution at the zone | - | - |
| `$7F10` | `ResLevel` | 2 | ResidentialScore's results: the level 0-7 and the building tile base | - | - |
| `$7F43` | `ComLevel` | 2 | CommercialScore's results: ZoneScore / 25 and 4 times it | - | - |
| `$7F5D` | `IndLevel` | 2 | IndustrialScore's results: ZoneScore / 31 and 8 times it | - | - |
| `$7F78` | `PowerPlants` | 32 | The map addresses of the power stations found (FindPlants), 0 ended | `PowerFlood` | `FindPlants` |
| `$7FCC` | `Brownout` | 1 | Counts the power stations that ran out of capacity this pass (BROWNOUTS DETECTED) | - | `PowerFlood` |
| `$8015` | `FloodAbove` | 264 | The flood's span flags: the row above and below already queued | - | - |
| `$81DD` | `CityValue` | 6 | The city's assessed value (24 bits) and the last pass's (`$81E0`) | `AddValue`, `AssessCity` | `AddValue`, `AssessCity`, `InitSimulation` |
| `$8265` | `PopBalance` | 2 | 4 (R - C - I): read by the evaluation | - | `InitSimulation`, `PopBalanceOf` |
| `$827C` | `ResDemand` | 6 | The three demands (signed), read as ZoneDemand: R, C, I | - | `DemandOf`, `InitSimulation` |
| `$835D` | `SimPaused` | 2 | Nonzero: the zones are scanned but do not grow (the pause) | `CoverStations`, `DecayPollution`, `ScanCity`, `SimTask` | `InitSimulation`, `SimTask` |
| `$8443` | `Population` | 61 | The pass's counters, cleared by ClearCounters (`$8443-$847F`) | `Advise`, `AssessCity`, `Averages`, `Averages2`, `ClearCounters` +8 | `ClearCounters`, `CountPowered`, `IndustrialStep` |
| `$849C` | `LastFireCells` | 8 | Copies of the last pass for the disasters: fires, airports, nuclear plants; the city centre | - | `Averages`, `InitSimulation` |
| `$84DD` | `AvgPollution` | 1 | Pollution's average | - | `Averages`, `DecayPollution` |
| `$851A` | `AvgTraffic` | 1 | Traffic's average / 4 | - | `DecayTraffic`, `InitSimulation` |
| `$8568` | `TripMade` | 2 | 1 when the zone's trip reached its destination | - | - |
| `$85C4` | `TripLeftover` | 18 | Leftover code no one calls (XOR A; LD (`$8568`),A; LD HL,(`$8462`); INC HL ...) | - | - |
| `$8606` | `TripTurn` | 3 | TripStep's turn, direction and tries | - | - |
| `$865E` | `TripTargets` | 2 | The two BuildingValue kinds a trip may end at | - | - |
| `$86C5` | `ZonePowered` | 4 | ScanCity's state of the current cell: powered, kind (1 building, 2 zone), building type, zone centre | `CountPowered`, `IndustrialStep`, `ScanCity`, `ZoneStep` | `ScanCity`, `ZonePower` |
| `$873B` | `ZoneCentreCell` | 1 | ZonePower's new centre cell | `ZonePower` | `ZonePower` |
| `$8785` | `CurCell` | 4 | The cell ScanCity is at: column, row; then its map address | `WidenExtent` | `CellStep`, `ZoneStep` |
| `$87C8` | `ExtentCols` | 4 | The city's extent: least and greatest column, then row | `Averages`, `MinMax` | `ClearCounters`, `MinMax` |
| `$87FB` | `BuildingRoutines` | 24 | The routines of the building kinds (BuildingKinds' second byte) | - | - |
| `$8813` | `BuildingKinds` | 86 | Per building type: type, routine (BuildingRoutines), level, density; `$FF` `$FF` ended | - | - |
| `$8869` | `Density` | 2 | the current zone's density (ScanInsideCell) or the building's (BuildingKinds) | - | `ZoneStep` |
| `$88C5` | `RoadDecay` | 1 | The mask of the roads' decay (Random AND it = 0 crumbles a cell); `$FF` none | - | `InitSimulation` |
| `$8902` | `RailDecay` | 1 | The same for the rails | - | `InitSimulation` |
| `$8985` | `FloodLeft` | 1 | The flood's spreads left (50) | - | - |
| `$8998` | `SpreadCode` | 3 | Spread's cell (`$45` fire, `$44` flood), its kind (0 fire) and its neighbour count | - | - |
| `$8A08` | `ZoneFrame` | 24 | The eight cells round a zone centre: row step, column step, the empty frame cell (`$49-$50`) | - | - |
| `$8B97` | `ResRevertZone` | 18 | The full R zone a block falls back to: houses `$40-$43` round the powered centre `$51` | - | - |
| `$8BBA` | `ComBuildings` | 10 | By ComLevel - 1: the commercial building variant (0-3) | - | - |
| `$8C41` | `ComEmptyZone` | 9 | The empty C zone, centre `$52` (powered) | - | - |
| `$8CF1` | `IndEmptyZone` | 9 | The empty I zone, centre `$53` (powered) | - | - |
| `$8E8A` | `LastPop` | 10 | The population at the last month's end; at the year's ends (`$8E8D` two years back, `$8E90` last year) | `MapsWindow`, `UiTask` | `InitSimulation`, `MonthEnd` |
| `$8F01` | `AvgCrime` | 4 | Averages2's results: 2 x the crime average, the land value average / 8, the building count | - | `Averages2`, `InitSimulation` |
| `$8F2F` | `HospitalNeed` | 2 | ServiceNeeds' results: ResPop / 18 - HospitalCount and ResPop / 20 - ChurchCount (0 when not positive) | - | `InitSimulation`, `ServiceNeeds` |
| `$8F67` | `GrowTries` | 5 | The speed's five values, copied from SpeedTable by SetSpeed: the growth tries, the I chance mask, the C chance mask, a fourth (no reader), the month mask | `SimTask` | `SetSpeed` |
| `$8F6C` | `SpeedTable` | 20 | four speeds of five: fast (8, 1, 15, 1, 0), normal (4, 3, 31, 3, 1), slow (3, 7, 63, 7, 3), paused (all `$FF`) | `SetSpeed` | - |

## uitask

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8F97` | `Funds` | 9 | The money (24 bits): 20 000 in the image | `AnimateFire`, `AnimateFlood`, `BlinkCell`, `DrawViewRowPass`, `FundsChanged` +9 | `NextMonth`, `Spend`, `StartSimulation`, `UiTask` |
| `$9056` | `LastFunds` | 2 | Funds' low 16 bits as last shown | `FundsChanged` | `FundsChanged` |

## disasters

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$916D` | `DisasterDue` | 1 | The disaster RunDisaster starts (0 none) | `RunDisaster` | - |

## budget

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$91BC` | `BudgetWindowText` | 338 | The budget window's menu description: FISCAL BUDGET, the tax rate, the three fundings, the cash lines, GO WITH THESE FIGURES. The numbers live inside the text (menu codes 5, 6, 7, section DrawMenu): TaxRate and the three funding percentages are the bytes the player edits. | - | - |
| `$930E` | `TaxIncome` | 27 | 24 bits: last year's population / 100 x TaxRate | - | `InitSimulation` |
| `$9357` | `HookSpare` | 1 | One byte no code reads | - | - |
| `$93F6` | `CapWork` | 3 | 24 bits: the money left for a funding | - | - |
| `$950A` | `DecayMasks` | 32 | By funded / (cost / 8), 0-15: the roads' and rails' decay mask (`$0F` crumbles most, `$FF` none) | - | - |

## evaluation

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$95D7` | `EvaluationText` | 352 | The evaluation window: the poll, the worst problems, population, migration, value, category, level, score | - | - |
| `$9750` | `CategoryLimits` | 15 | The five population limits (24 bits): 2000, 10 000, 50 000, 100 000, 500 000 | - | - |
| `$975F` | `Category` | 1 | 0 VILLAGE, 1 TOWN, 2 CITY, 3 CAPITAL, 4 METROPOLIS, 5 MEGALOPOLIS | - | - |
| `$978F` | `Migration` | 3 | PopLastYear - PopYearBefore (24 bits) | - | - |
| `$9801` | `ProblemSum` | 2 | The problems added up | - | - |
| `$98FA` | `CityScore` | 2 | 0-1000 | - | - |
| `$992F` | `PollYes` | 2 | The poll: of 100 Random draws (0-1023), how many are below CityScore (YES) and not (NO) | - | - |
| `$9996` | `Advice` | 1 | The advice shown (0 none, 1-`$15`): GameTexts 23 + Advice | `ShowAdvice` | `Advise`, `SetAdvice` |
| `$99AA` | `AdviceSpare` | 3 | One byte no code reads | `Advise` | `Advise` |

## overview

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9B4E` | `MapKeyCells` | 18 | The nine map keys' screen cells (row, column): the keys 1-9 of the maps window | `HighlightMapKey` | - |
| `$9BF8` | `OverviewSpare` | 1 | OverviewSpare | - | - |
| `$9C2B` | `MapArea` | 44 | The map area shown, 0-8 (the digit - 1) | `DrawOverview`, `HighlightMapKey`, `ShrinkLine` | `DrawOverview` |
| `$9CFA` | `LayerColours` | 8 | The attribute of each layer level 1-7 (paper colours) | - | - |
| `$9D43` | `MapLayer` | 1 | The layer: 0 city, 1 pollution, 2 police, 3 fire, 4 traffic, 5 power, 6 transport, 7 crime (6 in the image) | `HighlightLayer`, `LayerOf` | - |

## saveload

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9E77` | `SearchingText` | 18 | PrintInline codes: a box, SEARCHING | - | - |
| `$9EC1` | `LoadingText` | 11 | PrintInline: LOADING | - | - |
| `$9F1D` | `FoundText` | 13 | FoundText | - | - |

## dialogs

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9F40` | `PlantChoice` | 1 | The power station menu's answer: 0 none, 1 nuclear, 2 coal | - | - |
| `$9F41` | `PlantMenu` | 125 | the menu: SELECT TYPE, NUCLEAR POWER STATION `$5000`, COAL POWER STATION `$3000`, NONE | - | - |
| `$9FD3` | `ConfirmMenu` | 84 | ConfirmMenu | - | - |
| `$A02B` | `SystemMenu` | 134 | SYSTEM: about, start new city, use old landscape, load, save, exit | - | - |
| `$A0CA` | `AboutText` | 297 | AboutText | - | - |
| `$A1F6` | `LoadMenuText` | 81 | LoadMenuText | - | - |
| `$A24A` | `SaveMenuText` | 80 | SaveMenuText | - | - |
| `$A29D` | `FileNameText` | 63 | FileNameText | - | - |
| `$A2DF` | `LoadErrorText` | 31 | LoadErrorText | - | - |
| `$A30C` | `TapeText` | 31 | TapeText | - | - |
| `$A32B` | `AutoBulldoze` | 4 | the options (toggles): AUTO-BULLDOZE 1, AUTO-BUDGET 0, SOUND 1, ZONE DEMOLISH WAIT 1 | `CheckSite` | - |
| `$A32F` | `OptionsMenu` | 124 | OPTIONS: the four toggles, SIMULATION SPEED, EXIT MENU | - | - |
| `$A3AB` | `Speed` | 1 | 0 fast, 1 normal, 2 slow, 3 paused | `SetSpeed` | - |
| `$A3AF` | `SpeedMenuText` | 94 | SpeedMenuText | - | - |
| `$A43D` | `DisastersOff` | 1 | DISABLE ALL (a toggle): no random disasters | `RandomDisaster` | - |
| `$A43E` | `DisasterMenu` | 124 | DISASTERS: fire, flood, earthquake, air crash, tornado, nuclear meltdown | - | - |
| `$A4C2` | `WindowsMenu` | 79 | WINDOWS: maps, budget, evaluation | `DrawMenu`, `NumberRepeat`, `PrintMenuText`, `RunMenu` | - |
| `$A511` | `MapsDue` | 1 | set by MAPS: the UI task opens the maps window | `UiTask` | `MapsItem`, `MapsWindow` |
| `$A518` | `Level` | 1 | 0 easy, 1 medium, 2 difficult | `StartSimulation` | `SetLevel` |
| `$A51C` | `LevelMenuText` | 141 | LevelMenuText | `DrawMenu`, `NumberRepeat`, `PrintMenuText`, `RunMenu` | - |
| `$A5E5` | `OldLandscapeMenu` | 141 | OldLandscapeMenu | - | - |
| `$A6A4` | `CreatingText` | 52 | CREATING LANDSCAPE, PLEASE WAIT | `DrawMenu`, `PrintMenuText` | - |
| `$A6D8` | `InputAt` | 33 | the line editor: row, column, the buffer, the cursor, the digits flag, the length, a buffer of 12, the key delay | - | - |
| `$A7EB` | `NumberAt` | 2 | NumberAt | - | - |

## workspace

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A884` | `MoverSprites` | 160 | The movers' 16 x 16 sprites, 32 bytes each: the plane, two tornado frames, the train across and down | - | - |
| `$A924` | `SaveName` | 43 | The name typed for LOAD and SAVE | - | - |
| `$A94F` | `SaveSpare` | 1 | SaveSpare | - | - |
| `$A950` | `FireCover` | 16128 | The 24 x 24 fire coverage, 0-15 (zero in the image: built at run time) | `CellStep`, `CheckSite`, `ClearCover`, `CoverStations`, `DecayPollution` +13 | `ClearCover`, `DecayPollution`, `DecayTraffic`, `Disc`, `InitSimulation` +4 |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E850` | `IconTiles` | 536 | The 67 icon and frame tiles, 8 bytes each: the tool palette (2 x 2 each), the frames `$38-$3F`, the separators `$40-$42` | `DrawIcon`, `DrawIconHere`, `FindPlants` | - |
| `$EA68` | `CellTiles` | 752 | The 94 cell tiles of the map (cells 0-`$5D`; `$5A-$5D` the fire and flood frames AnimateFire and AnimateFlood copy) | `AnimateFire`, `AnimateFlood`, `DrawCell`, `ShrinkLine` | `AnimateFire`, `AnimateFlood` |
| `$ED58` | `BuildingTiles` | 1952 | The 244 building tiles (a building row's tile numbers n, n + 1, ...) | - | - |
| `$F4F8` | `IconAttrs` | 56 | The attributes of icons 0-55 (DrawIcon reads IconAttrs + A; the frame tiles use PrintAttr) | `DrawIcon` | - |
| `$F530` | `CellAttrs` | 94 | The cells' attributes | `DrawCell` | - |
| `$F58E` | `BuildingAttrs` | 244 | The building tiles' attributes | - | - |

## tasks

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F682` | `SimStack` | 108 | The simulation task's stack (zeros) | - | `BlinkCell`, `ClearTopWhite`, `ClearViewArea`, `Digit24`, `Disc` +37 |
| `$F6EE` | `SimFrame` | 20 | The simulation task's first frame: 20 bytes of registers, then the entry | - | `AddValue`, `CellFlagsOf`, `CellStep`, `ClearCover`, `CoverStations` +7 |
| `$F702` | `SimEntry` | 2 | SimTask: the first switch returns into it | - | `StartSimulation` |
| `$F704` | `TaskNow` | 3 | 0 the UI task runs, 1 the simulation | `Interrupt` | `Click`, `Entry`, `Interrupt`, `LayerOf`, `StartSimulation` +1 |
| `$F707` | `UiSP` | 4 | the stacks of the two tasks while the other runs | `Interrupt` | `Interrupt`, `StartSimulation` |

## system

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F74E` | `PrintCharCode` | 6 | The print state: the character, the screen address, the column and row, the attribute | `DrawBox`, `DrawBoxRow`, `DrawIcon`, `DrawIconHere`, `NextColumn` +3 | `DrawBox`, `DrawBoxRow`, `DrawIcon`, `DrawMenu`, `NextColumn` +8 |
| `$F798` | `ReadInputLeftover` | 7 | Leftover: RET, JP `$FE0F`, JP `$FE0F` (no code runs them) | - | - |
| `$F7BB` | `UiStack` | 1345 | The UI task's stack, filled with `$E5` | - | - |
| `$FCFF` | `InterruptSpare` | 258 | InterruptSpare | `AddValue`, `BlinkCell`, `CellFlagsOf`, `CellStep`, `ClearCover` +48 | - |
