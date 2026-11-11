# 11. Data reference

Every data entry of the game image `$5B00`-`$FE00`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B00` | `KeyRows` | 27 | The keyboard's eight half rows, as IN read them in the last interrupt (0 = pressed, bits 0-4). ReadInput `$F781` writes them every frame from ports `$FEFE`, `$FDFE`, `$FBFE`, `$F7FE`, `$EFFE`, `$DFFE`, `$BFFE`, `$7FFE` (in that order), then ReadKempston `$7A01` and ReadSinclair `$7A32` clear the Q, A, O, P and SPACE bits when a joystick is pushed, so every reader sees one keyboard. Row 0 bit 0 CAPS SHIFT, row 1 bit 0 A (down), row 2 bit 0 Q (up), row 5 bit 0 P (right) and bit 1 O (left), row 7 bit 0 SPACE (fire) and bit 1 SYMBOL SHIFT. L1: 3 264 254 writes (8 a frame), 5 764 078 reads with KeyNone and BitMasks. | `AnyKey`, `Click`, `MapClick`, `MapsWindow`, `MovePointer` +18 | `ReadInput`, `ReadKempston` (`stage1/rec/ports`), `ReadSinclair` (`stage1/rec/menus`) |
| `$5B01` | `KeyRowA` (`KeyRows`+1) | 1 | `$FDFE`: A S D F G | `AnyKey`, `MapClick`, `MovePointer`, `RunMenu`, `ScanKey` +6 | `ReadInput`, `ReadKempston` (`stage1/rec/ports`), `SincDown` (code) |
| `$5B02` | `KeyRowQ` (`KeyRows`+2) | 1 | `$FBFE`: Q W E R T | `AnyKey`, `MapClick`, `MovePointer`, `RunMenu`, `ScanKey` +6 | `ReadInput`, `ReadKempston` (`stage1/rec/ports`), `SincUp` (code) |
| `$5B03` | `KeyRow1` (`KeyRows`+3) | 1 | `$F7FE`: 1 2 3 4 5 | `AnyKey`, `ScanKey`, `ShiftScroll` (`stage1/rec/tools`) | `ReadInput` |
| `$5B04` | `KeyRow0` (`KeyRows`+4) | 1 | `$EFFE`: 0 9 8 7 6 | `AnyKey`, `PointerUp`, `ReadSinclair`, `ScanKey`, `ShiftScroll` (`stage1/rec/tools`) | `ReadInput` |
| `$5B05` | `KeyRowP` (`KeyRows`+5) | 1 | `$DFFE`: P O I U Y | `AnyKey`, `MapClick`, `MovePointer`, `ReadKempston` (`stage1/rec/ports`), `Refuse` (`stage1/rec/tools`) +4 | `ReadInput`, `ReadKempston` (`stage1/rec/ports`), `ReadSinclair` (code), `SincLeft` (code) |
| `$5B06` | `KeyRowEnter` (`KeyRows`+6) | 1 | `$BFFE`: ENTER L K J H | `AnyKey`, `UiTask`, `ScanKey` (`stage1/rec/menus`) | `ReadInput` |
| `$5B07` | `KeyRowSpace` (`KeyRows`+7) | 1 | `$7FFE`: SPACE SYMBOL SHIFT M N B | `AnyKey`, `Click`, `MapClick`, `MapsWindow`, `ReadSinclair` +10 | `ReadInput`, `ReadKempston` (`stage1/rec/ports`), `ReadSinclair` (`stage1/rec/menus`) |
| `$5B08` | `KeyNone` (`KeyRows`+8) | 1 | a ninth row, always `$FF`: ScanKey reads nine rows | `AnyKey`, `ScanKey` (`stage1/rec/menus`) | - |
| `$5B09` | `PortHighs` (`KeyRows`+9) | 8 | leftover: the eight port high bytes `$FE-$7F`; no code reads them (L1: 0 reads) | - | - |
| `$5B11` | `BitMasks` (`KeyRows`+17) | 8 | `$80`, `$40`, ... `$01`: the bit of a column, read by PowerBit `$75F1` (the power map's bit of a cell) (L1: 1 415 565 reads) | `PowerBitAt`, `PowerBit` (`stage1/rec/tools`) | - |
| `$5B19` | `EntryJump` (`KeyRows`+25) | 2 | JR `$5B1B`, two bytes no code of the tape version runs (L1: never executed): the tape's mover reaches the entry by JP `$5B1B`; the +3 disk's boot enters here (JP `$5B19`, work/stage2/NOTES.md 5.3) | - | - |

## input

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B7F` | `KempstonFound` | 1 | 1 when Entry found a Kempston interface (port `$1F` reads below `$1F`), else 0. Read by ReadPort1F `$5B80` every frame (L1 413 183 reads). | `ReadPort1F` | `Entry` |
| `$5B8A` | `KeyChars` | 41 | The character of each key, five a half row in ScanKey's order (CAPS SHIFT first), then the key found. Row `$FEFE` from bit 0: `$03` (CAPS SHIFT), Z X C V; `$FDFE` A S D F G; `$FBFE` Q W E R T; `$F7FE` 1-5; `$EFFE` 0 9 8 7 6; `$DFFE` P O I U Y; `$BFFE` `$08` (ENTER as delete), L K J H; `$7FFE` SPACE, ".", M N B (SYMBOL SHIFT reads as "."). KeyFound at `$5BB2` is ScanKey's result: the key's index, or `$FF` for none. Read by KeyToChar `$5BDF` (L1 1193 reads). | `KeyToChar` | `ScanKey` |
| `$5BB2` | `KeyFound` (`KeyChars`+40) | 1 | ScanKey's result: the index into KeyChars of the first key down, `$FF` for none | `KeyToChar` | `ScanKey` |
| `$5BDE` | `ScanSpare` | 1 | One byte no code reads (L1: 0 reads); kept as bytes | - | - |

## random

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CC4` | `RandomSeed` | 2 | The random seed, 16 bits; NewLandscape sets it to the gene (Gene `$6A8C`); read directly by RandomDisaster, RadiationCell, Poll and NewCityItem (the new gene) | `Random`, `RandomDisaster`, `ExitSimCity` (`stage1/rec/menus`), `Poll` (`stage1/rec/menus`), `RadiationCell` (`stage1/rec/disasters`) | `NewLandscape`, `Random` |

## cursor

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CEC` | `PointerShape` | 16 | The pointer: an arrow, 8 pixel rows ORed over the screen (src/res/graphics/Pointer.png). Read by DrawPointer `$5CFE` (L1 156 303 reads of each byte). | `DrawPointer` | - |
| `$5CF4` | `PointerMask` (`PointerShape`+8) | 8 | the mask ANDed with the screen before the arrow is ORed in | `DrawPointer` | - |
| `$5CFC` | `PointerX` | 2 | the pointer's column in half characters, 0-62 (stage 1's "cursor") | `Click`, `DrawPointer`, `OpenMenuAt`, `PointerDown`, `PointerLeft` +3 | `PointerDown`, `PointerLeft`, `PointerRight`, `PointerUp` |
| `$5CFD` | `PointerY` (`PointerX`+1) | 1 | the pointer's row in pixels, 0-184 in steps of 2 | `Click`, `DrawPointer`, `PointerDown`, `PointerUp`, `TrackBox` | `PointerDown`, `PointerUp` |
| `$5D34` | `PointerSave` | 10 | The 8 screen bytes under the pointer, and their address | `ErasePointer` | `DrawPointer` |
| `$5D3C` | `PointerAt` (`PointerSave`+8) | 2 | the display file address of the pointer's cell | `ErasePointer` | `DrawPointer` |
| `$5D4F` | `BoxSize` | 6 | The map cursor's box: width and height in cells (the tool's size, ToolSizes). Written by ShowTool `$6D90`; read by TrackBox (L1 81 184 reads). | `InvertBox`, `MapClick`, `TrackBox` | `ShowTool`, `TrackBox` |
| `$5D51` | `BoxCell` (`BoxSize`+2) | 2 | the pointer's cell in the view: column (0-31) and row (0-15) | - | `TrackBox` |
| `$5D53` | `PointerInView` (`BoxSize`+4) | 1 | nonzero when the pointer is on the map view (PointerY `$40` or more) | - | `TrackBox` |
| `$5D54` | `BoxShown` (`BoxSize`+5) | 1 | 1 when the box is drawn (it fits on the view) | `MapClick` | `TrackBox` |

## print

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5E31` | `PrintSpare` | 4 | Four bytes no code reads (LD (`$F751`),BC: a cut instruction of the source); kept as bytes | - | - |
| `$5E95` | `BoxDims` | 2 | DrawBox's box: width and height in characters | `DrawBox`, `DrawBoxRow` | `DrawBox`, `DrawMenu`, `DrawMenuSeparator` (code) |
| `$5ED2` | `BoxSpare` | 1 | One byte no code reads; kept as bytes | - | - |
| `$5F16` | `StatusBarText` | 42 | PrintInline codes: the menu bar (SYSTEM OPTIONS DISASTERS WINDOWS) | `PrintInline` | - |
| `$5F43` | `StatusBoxText` | 10 | PrintInline codes: the status box | `DrawBox`, `PrintInline` | - |
| `$5F63` | `CityNameAt` | 28 | PrintInline codes: attribute `$39`, row 5, column 1 (the name follows) | `PrintInline`, `SaveCity` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/levels`) | `InputLine` (`stage1/rec/levels`), `LoadMap` (`stage1/rec/menus`) |
| `$5F68` | `CityName` (`CityNameAt`+5) | 23 | the city's name, 12 letters, "HERESVILLE  " in the image; InputName edits only 11 and the 12th letter is not saved (SaveCityName holds 11) | `PrintInline`, `SaveCity` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/levels`) | `InputLine` (`stage1/rec/levels`), `LoadMap` (`stage1/rec/menus`) |
| `$5F8A` | `MonthNames` | 36 | The twelve months, three letters each, bit 7 on the last | `FindText`, `PrintPadded` | - |
| `$5FC6` | `GameTexts` | 831 | The tool names with prices, the levels, the six city classes, the 27 advice and disaster messages. 50 strings, bit 7 on each last letter, found by FindText `$6317` by index: 0-13 the tools ("BULLDOZE" with its price, 1 dollar, ... "AIRPORT", 10 000 dollars), 14-16 the levels (EASY, MEDIUM, HARD), 17-22 the classes (VILLAGE ... MEGALOPOLIS), 23 a space, 24-49 the advice and disasters ("MORE RESIDENTIAL ZONES NEEDED" ... "TORNADO DETECTED"). Read by PrintToolName, the level name, the class name and the advice (L1 1 602 984 reads, every byte). | `FindText`, `PrintPadded` | - |

## clicks

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$63C9` | `ClickCell` | 4 | The pointer's character cell when SPACE was pressed: column (0-31), row (0-23) | `ClickToMap`, `MapClick`, `MenuClick`, `ScrollClick`, `ToolClick` +1 | `Click` |
| `$63CB` | `ClickSpare` (`ClickCell`+2) | 2 | two bytes no code reads | - | - |

## renderer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6433` | `Blink` | 1 | Pass bit 4 at the start of the view row's draw: the blink phase | `RoadTraffic` (`stage1/rec/growth`) | `DrawOverview`, `DrawViewRowPass` |
| `$6462` | `TileIndex` | 2 | The tile number being drawn | `DrawCell`, `DrawIcon` | `DrawCell`, `DrawIcon`, `DrawBuildingTile` (`stage1/rec/growth`) |
| `$64D5` | `BuildingDummy` | 1 | A byte IX points at while a building row is drawn (no reader of its value) | `DrawBuildingTile` (`stage1/rec/city2`), `DrawCell` (`stage1/rec/tools`) | - |
| `$6505` | `CellAttrPtr` | 6 | The attribute table of the cell being drawn (CellAttrs or BuildingAttrs) | `ClickToMap`, `DrawCell`, `DrawView`, `DrawViewRowPass`, `LayerOf` +7 | `DrawOverview`, `DrawView`, `DrawBuildingTile` (`stage1/rec/growth`), `DrawCell` (`stage1/rec/tools`), `ScrollDown` (`stage1/rec/tools`) +3 |
| `$6507` | `ViewCol` (`CellAttrPtr`+2) | 1 | the view's left column on the map, 0-64 | `ClickToMap`, `DrawView`, `DrawViewRowPass`, `ClickToMapBC` (`stage1/rec/tools`), `DrawMover` (`stage1/rec/tools`) +2 | `ScrollLeft` (`stage1/rec/tools`), `ScrollRight` (`stage1/rec/tools`) |
| `$6508` | `ViewRow` (`CellAttrPtr`+3) | 1 | the view's top row, 0-80 | `ClickToMap`, `DrawView`, `DrawViewRowPass`, `ClickToMapBC` (`stage1/rec/tools`), `DrawMover` (`stage1/rec/tools`) +2 | `ScrollDown` (`stage1/rec/tools`), `ScrollUp` (`stage1/rec/tools`) |
| `$6509` | `ViewCellPtr` (`CellAttrPtr`+4) | 2 | the map address of the cell being drawn | `LayerOf`, `RoadTraffic` (`stage1/rec/tools`) | `DrawOverview`, `DrawView` |
| `$6558` | `BuildingLeft` | 3 | The cells left in the building row being drawn | `DrawCell`, `DrawOverview`, `DrawView`, `OverviewCell`, `DrawBuildingTile` (`stage1/rec/growth`) | `DrawOverview`, `DrawView`, `DrawCell` (`stage1/rec/tools`), `StartBuilding` (`stage1/rec/tools`), `DrawBuildingTile` (code) +1 |
| `$6559` | `BuildingTile` (`BuildingLeft`+1) | 2 | the tile number n of the next building cell (16 bits) | `DrawOverview`, `DrawView`, `DrawBuildingTile` (`stage1/rec/growth`), `DrawCell` (`stage1/rec/tools`), `OverviewBuilding` (code) | `DrawOverview`, `DrawView`, `StartBuilding` (`stage1/rec/tools`) |
| `$6592` | `BuildingBack` | 1 | FindBuildingStart's count | `FindBuildingStart` (`stage1/rec/growth`), `StartBuilding` (`stage1/rec/tools`) | `FindBuildingStart` (`stage1/rec/growth`), `StartBuilding` (`stage1/rec/tools`) |

## arith

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$65A3` | `NumberEnd` | 2 | PrintAddr after the last number printed | `PrintEvalFigures` (`stage1/rec/menus`) | `PrintNumber24` |
| `$664D` | `NumberFlags` | 2 | A digit printed already; the leading zeros left out | `Digit24`, `PrintNumber24`, `PrintDigitB` (`stage1/rec/menus`) | `Digit24`, `PrintNumberVar`, `PrintDigitB` (`stage1/rec/menus`), `PrintNumber24` (`stage1/rec/menus`) |

## menus

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$671F` | `FullFrameText` | 8 | PrintInline codes: a 32 x 24 frame, attribute `$47` | `DrawBox` (`stage1/rec/menus`), `PrintInline` (`stage1/rec/menus`) | - |
| `$673E` | `WindowAreaText` | 8 | PrintInline codes: a 32 x 16 frame at row 8, attribute `$44` | `DrawBox`, `PrintInline` | - |
| `$6747` | `MenuState` | 124 | The menu being shown: IX of its description, then its line counter and the item table. MenuItems (`$674A`, 3 bytes an item: the line, the item's address) up to `$6779`, MenuValues `$677A` (3 bytes a line: the column and the address of a number field), MenuCount `$67C2`. L1 6776 reads, 5161 writes. | `AddMenuItem`, `DrawMenu`, `MenuDown`, `PrintMenuText`, `RunMenu` +3 | `AddMenuItem`, `DrawMenu`, `MenuField` (`stage1/rec/menus`) |
| `$6749` | `MenuLine` (`MenuState`+2) | 1 | the line being drawn | `AddMenuItem`, `DrawMenu`, `PrintMenuText`, `MenuField` (`stage1/rec/menus`), `MenuTab` (`stage1/rec/tools`) | `DrawMenu` |
| `$674A` | `MenuItems` (`MenuState`+3) | 48 | the selectable items: line, address | `RunMenu`, `ToggleMenuLine` | `AddMenuItem`, `DrawMenu` |
| `$677A` | `MenuValues` (`MenuState`+51) | 72 | per line: the column of a number field and its address | `RunMenu` (`stage1/rec/menus`) | `MenuField` (`stage1/rec/menus`) |
| `$67C2` | `MenuCount` (`MenuState`+123) | 1 | the number of selectable items | `AddMenuItem`, `MenuDown`, `RunMenu` | `AddMenuItem`, `DrawMenu` |
| `$684B` | `ToggleValue` | 1 | The toggle's flag value while it is printed | `DrawMenu` (`stage1/rec/tools`), `DrawMenuToggle` (code) | `DrawMenu` (`stage1/rec/tools`), `DrawMenuToggle` (code) |
| `$686E` | `OnText` | 3 | "ON" for a toggle | `PrintInline` (`stage1/rec/tools`) | - |
| `$6879` | `OffText` | 4 | "OFF" | `PrintInline` (`stage1/rec/tools`) | - |
| `$6942` | `MenuHook` | 2 | A routine RunMenu calls on entry and EditNumber on every pass of its edit loop, key or not (0: none): BudgetHook `$9346` or Evaluate `$9737`, which recompute and print the window's numbers | `CallMenuHook` | `BudgetWindow` (`stage1/rec/menus`), `EvaluationWindow` (`stage1/rec/menus`) |
| `$6990` | `EditMax` | 6 | The number field being edited: the largest value, its address, its position, the key repeat | `EditDown` (`stage1/rec/city`), `EditUp` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintEditField` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) +1 | `NumberRepeat` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `EditNumber` (code) |
| `$6991` | `EditPtr` (`EditMax`+1) | 2 | - | `EditDown` (`stage1/rec/city`), `EditUp` (`stage1/rec/menus`), `PrintEditField` (`stage1/rec/menus`) | `RunMenu` (`stage1/rec/menus`), `EditNumber` (code) |
| `$6993` | `EditPos` (`EditMax`+3) | 2 | - | `PrintEditField` (`stage1/rec/menus`) | `RunMenu` (`stage1/rec/menus`), `EditNumber` (code) |
| `$6995` | `EditRepeat` (`EditMax`+5) | 1 | - | `NumberRepeat` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `EditNumberLoop` (code) | `NumberRepeat` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `EditNumber` (code) |
| `$6A7D` | `MenuSelected` | 1 | The selected item | `MenuDown`, `MenuUp`, `SelectedItem`, `SetLevel`, `PickDisaster` (`stage1/rec/disasters`) | `MenuDown`, `MenuUp`, `RunMenu`, `InputGene` (`stage1/rec/menus`) |

## landscape

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6A8C` | `Gene` | 2 | The landscape's gene, the seed of the generator (3 in the image: "00003") | `NewLandscape`, `InputGene` (`stage1/rec/menus`), `NumberDigits` (`stage1/rec/menus`), `SetLevel` (`stage1/rec/menus`) | `ExitSimCity` (`stage1/rec/menus`), `PutDigit` (`stage1/rec/menus`) |
| `$6AD3` | `DiscShapes` | 8 | Four pairs of shifts (4, 4), (5, 3), (3, 5), (4, 4): the disc's two axes (round, flat, tall) | `Discs` | - |
| `$6B21` | `CoastPatterns` | 132 | The coast: 66 masks of the eight land neighbours, then the 66 cell codes put on such water. Read by MakeCoast with CPIR (L1 426 157 compares). | `MakeCoast` | - |
| `$6B63` | `CoastCells` (`CoastPatterns`+66) | 66 | the cell code for each pattern | `MakeCoast` | - |
| `$6BDA` | `MapEdge` | 1 | Set to 0 when MapAddrChecked was given a cell off the map | - | `MapAddrChecked`, `MapAddrOff` (code) |
| `$6C02` | `DiscVars` | 7 | The disc being drawn: centre x, y, radius, cell, the cell it may replace (0 any), the two shifts | `Disc` | `Discs`, `NewLandscape` |
| `$6C03` | `DiscY` (`DiscVars`+1) | 1 | - | `Disc` | `Discs` |
| `$6C04` | `DiscRadius` (`DiscVars`+2) | 1 | - | `Disc` | `Discs` |
| `$6C05` | `DiscCell` (`DiscVars`+3) | 1 | - | `Disc` | `Discs`, `NewLandscape` |
| `$6C06` | `DiscOver` (`DiscVars`+4) | 1 | - | `Disc` | `NewLandscape` |
| `$6C07` | `DiscShift` (`DiscVars`+5) | 2 | - | `Disc` | `Discs` |

## tools

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6D50` | `CurrentTool` | 1 | The tool: 0 bulldozer, 1 road, 2 power line, 3 rail, 4 park, 5-7 R C I, 8 police, 9 fire, 10 stadium, 11 power station, 12 seaport, 13 airport | `CheckSite`, `CrossNetwork`, `MapClick`, `PrintToolName`, `ShowTool` +3 | `ToolKeys`, `ToolClick` (`stage1/rec/tools`) |
| `$6DAF` | `ToolSizes` | 28 | The 14 tools' box sizes, width and height: 1 x 1 for tools 0-4, 3 x 3 for 5-9, 4 x 4 for 10-12, 6 x 6 the airport | `ToolSize` | - |
| `$6E1E` | `ToolPrices` | 28 | The 14 tools' prices: 1, 10, 5, 20, 10, 100, 100, 100, 500, 500, 3000, 4000, 5000, 10 000 | `ToolPrice` | - |
| `$6E67` | `ClickMapCell` | 3 | The map cell of the last tool click: column, row | `ClickToMap`, `ClickToMapBC` (`stage1/rec/tools`) | `ClickMapAddr`, `FixNetworkAt` (code) |
| `$6E69` | `MapCoordsGiven` (`ClickMapCell`+2) | 1 | 1 while FixNetworkAt runs: ClickToMapBC takes BC as a map cell already | `ClickToMap`, `ClickToMapBC` (`stage1/rec/tools`) | `FixNetworkAt` (code) |
| `$6ED2` | `NetworkKind` | 1 | The network being laid: 7 road, `$14` rail, `$21` power line (`$30` in the image) | `FixNetworkCell` (`stage1/rec/tools`), `IsNetwork` (`stage1/rec/tools`), `NetworkBit` (`stage1/rec/tools`), `PlaceNetwork` (`stage1/rec/tools`), `Bridge` (code) | `Bulldoze` (`stage1/rec/tools`), `CrossNetwork` (`stage1/rec/growth`), `PlaceNetwork` (`stage1/rec/tools`) |
| `$6ED3` | `NetworkShapes` | 16 | the shape offset by the 4-bit neighbour mask (up, left, right, down) | `FixNetworkCell` (`stage1/rec/tools`) | - |
| `$6F10` | `NetworkFlag` | 2 | NetworkBit's result for this FixNetwork | `IsNetwork` (`stage1/rec/tools`) | `FixNetworkClick` (`stage1/rec/tools`), `Bridge` (code), `FixNetwork` (code) |
| `$6F11` | `BridgeMode` (`NetworkFlag`+1) | 1 | 1 while Bridge looks for the network to continue: only the kind's own cells count | `IsNetwork` (`stage1/rec/tools`) | `Bridge` (code) |
| `$6F5C` | `BridgeEnd` | 3 | The last water cell the bridge line covered | `BridgeLineWater` (code), `BridgeOffset` (code) | `Bridge` (code), `BridgeLineNext` (code), `BridgeOffset` (code) |
| `$6F5E` | `BridgeCell` (`BridgeEnd`+2) | 1 | the cell the bridge line writes (0 for the dry run) | `BridgeLineWater` (code) | `Bridge` (code), `BridgeOffset` (code) |
| `$6F9C` | `CellFlags` | 90 | The flags of the cells 0-`$59`: bit 0 not reshaped, 1 rail, 2 road, 3 conducts power, 4 zone, 5 set on the zone centres `$51-$56` only (no reader), 6 developed, 7 flammable. Read by CellFlagsOf (`$7599`; L1 11 343 551). Buildings (`$80` and up) give `$99` there. The bit meanings follow from the readers: bit 0 FixNetworkCell, bit 1 the train (`$77DC`) and the rail count (`$8898`), bit 2 the road count, bits 1-2 the traffic route (`$856A`), bit 3 the power flood (`$819A`), bits 4 and 6 BuildingValue and the pollution (`$7DEA`), bit 7 the fire (`$89BB`, `$79DE`). | `CellFlagsOf` | - |
| `$6FF6` | `ToolHandlers` | 28 | The 14 tools' click routines (MapClick calls ToolHandlers[CurrentTool]) | `MapClick` | - |
| `$7062` | `Crossings` | 36 | Three pairs of 6 bytes: the cells a network may cross, then the crossing cell for each. `$7062` power over road or rail; `$706E` road over power or rail; `$707A` rail over road or power. Read by CrossNetwork (CPIR, the result 6 bytes on). | `CrossNetwork` (`stage1/rec/tools`) | - |
| `$70FA` | `FreeCells` | 9 | The cells a building site takes at no cost: 2 land, 0 water | `CheckSite` | `CheckSite` |
| `$70FC` | `SiteCells` (`FreeCells`+2) | 6 | the cells a site may hold (cleared at `$1` each): 2, 3, 1, 5, 4, 6, then `$7102` | `CheckSite` | - |
| `$7102` | `SiteWater` (`FreeCells`+8) | 1 | the seventh: 0 (water) for the networks, 2 for the other tools; written by CheckSite | `CheckSite` (`stage1/rec/tools`) | `CheckSite` |
| `$71B8` | `NetPrice` | 4 | PlaceNetwork's price per cell on land | `PlaceNetwork` (`stage1/rec/tools`), `BridgeLineWater` (code) | `PlaceNetwork` (`stage1/rec/tools`) |
| `$71BA` | `BridgePrice` (`NetPrice`+2) | 2 | and per cell of bridge | `BridgeLineWater` (code) | `PlaceNetwork` (`stage1/rec/tools`) |
| `$71FF` | `BridgeDirs` | 16 | By the neighbour mask: the bridge direction (1-4; 0 none) | - | - |
| `$720F` | `BridgeSteps` | 15 | per direction 0-4: the row step, the column step, the bridge cell offset | - | - |
| `$726B` | `BulldozeKeep` | 11 | The bridge and coast-end cells: the bulldozer turns them back to water | `Bulldoze` (`stage1/rec/tools`), `SpreadTo` (`stage1/rec/disasters`) | - |
| `$7273` | `BulldozeNothing` (`BulldozeKeep`+8) | 3 | 0, 2, `$59`: nothing to clear (water, land, rubble ash) | `Bulldoze` (`stage1/rec/tools`) | - |
| `$7301` | `BulldozeCosts` | 7 | By the building's size: the price of clearing it, size squared (0, 1, 4, 9, 16, 25, 36) | - | - |
| `$737D` | `RubbleSteps` | 6 | The rubble's three steps: `$46` -> `$47` -> `$48` -> 2 (land) | - | - |
| `$73D3` | `ToolSpare` | 1 | One byte no code reads | - | - |
| `$73F1` | `ResidentialZone` | 9 | The 3 x 3 zone cells: the frame `$49-$50` round the centre `$54` (residential, unpowered) | `PutBuilding` (`stage1/rec/tools`) | - |
| `$740B` | `CommercialZone` | 9 | ... centre `$55` | `PutBuilding` (`stage1/rec/tools`) | - |
| `$7425` | `IndustrialZone` | 9 | ... centre `$56` | `PutBuilding` | - |
| `$743F` | `PoliceBuilding` | 9 | The police station, 3 x 3: building rows (`$A3` top, `$83`) with tile numbers `$C0`+ | `PutBuilding` (`stage1/rec/tools`) | - |
| `$7459` | `FireBuilding` | 9 | The fire station, 3 x 3 | `PutBuilding` (`stage1/rec/tools`) | - |
| `$7473` | `StadiumBuilding` | 16 | The stadium, 4 x 4 | `PutBuilding` (`stage1/rec/ports`) | - |
| `$7494` | `CoalPlant` | 32 | The coal power station, 4 x 4 | `PutBuilding` (`stage1/rec/tools`) | - |
| `$74A4` | `NuclearPlant` (`CoalPlant`+16) | 16 | the nuclear one | `PutBuilding` (`stage1/rec/tools`) | - |
| `$74E6` | `SeaportBuilding` | 16 | The seaport, 4 x 4 | `PutBuilding` (`stage1/rec/ports`) | - |
| `$7507` | `AirportBuilding` | 36 | The airport, 6 x 6 | `PutBuilding` (`stage1/rec/tools`) | - |

## cityaccess

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$753C` | `GridBase` | 2 | The array Grid48 and Grid24 read | `LayerOf`, `Grid24` (`stage1/rec/menus`), `Grid48` (`stage1/rec/tools`), `PoliceAt` (`stage1/rec/tools`), `PollutionAt` (`stage1/rec/ports`) | `LayerOf`, `FireAt` (`stage1/rec/growth`), `PoliceAt` (`stage1/rec/tools`), `PollutionAt` (`stage1/rec/tools`), `TrafficAt` (`stage1/rec/tools`) |
| `$75EF` | `PutBuildingSpare` | 2 | Two bytes no code reads | - | - |
| `$7657` | `DivLeftover` | 17 | Leftover: an older copy of a divide (LD C,H; LD A,L; LD HL,0 ... RET), no code runs it | - | - |
| `$7682` | `BuildingValues` | 12 | By building routine (BuildingKinds' second byte): the class TripArrived matches against TripTargets (9 R, 10 C, 11 I; police 0, fire 1, church 2, hospital 3) | `BuildingValue` (`stage1/rec/menus`) | - |
| `$76DC` | `Directions` | 8 | The four steps (column, row): up, right, down, left | `StepDir` (`stage1/rec/tools`) | - |
| `$76FD` | `CellStackCount` | 1 | The cells on CellStack (at `$801D`) | `AddTripTraffic` (`stage1/rec/menus`), `CellStackTop` (`stage1/rec/menus`), `PopCell` (`stage1/rec/menus`), `PushCell` (`stage1/rec/menus`), `TripWalk` (`stage1/rec/menus`) | `MakeTrip` (`stage1/rec/menus`), `PopCell` (`stage1/rec/menus`), `PushCell` (`stage1/rec/menus`), `TripWalk` (`stage1/rec/menus`) |

## movers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$77D3` | `TrainCell` | 9 | The train (`$77D3-$77DB`): its cell (column, row), sprite, out flag, the way it came, turn, tries, steps | `DrawMovers`, `MoveTrain`, `StartTrain` (`stage1/rec/tools`) | `InitSimulation`, `MoveTrain` (`stage1/rec/tools`), `StartTrain` (`stage1/rec/tools`) |
| `$77D5` | `TrainSprite` (`TrainCell`+2) | 1 | - | `DrawMovers` (`stage1/rec/tools`) | `MoveTrain` (`stage1/rec/tools`) |
| `$77D6` | `TrainOut` (`TrainCell`+3) | 1 | - | `DrawMovers`, `MoveTrain`, `StartTrain` (`stage1/rec/tools`) | `InitSimulation`, `StartTrain` (`stage1/rec/tools`), `MoveTrain` (code) |
| `$77D7` | `TrainBack` (`TrainCell`+4) | 1 | - | `MoveTrain` (`stage1/rec/tools`) | `MoveTrain` (`stage1/rec/tools`) |
| `$77D8` | `TrainTurn` (`TrainCell`+5) | 1 | - | `MoveTrain` (`stage1/rec/tools`) | `MoveTrain` (`stage1/rec/tools`) |
| `$77D9` | `TrainDir` (`TrainCell`+6) | 1 | - | `MoveTrain` (`stage1/rec/tools`) | `MoveTrain` (`stage1/rec/tools`) |
| `$77DA` | `TrainTries` (`TrainCell`+7) | 1 | - | `MoveTrain` (`stage1/rec/tools`) | `MoveTrain` (`stage1/rec/tools`) |
| `$77DB` | `TrainSteps` (`TrainCell`+8) | 1 | - | `MoveTrain` (`stage1/rec/tools`) | `MoveTrain` (`stage1/rec/tools`) |
| `$7879` | `PlaneOut` | 5 | The plane: out flag, cell (column, row), the column it crashes at, the crash timer | `DrawMovers`, `MovePlane`, `StartPlane` (code) | `InitSimulation`, `AirCrash` (code), `MovePlane` (code), `PlaneDone` (code), `StartPlane` (code) +2 |
| `$787A` | `PlaneCell` (`PlaneOut`+1) | 2 | - | `DrawMovers`, `MovePlane` (code) | `MovePlane` (code), `StartPlane` (code), `StartPlaneHere` (code) |
| `$787C` | `PlaneTarget` (`PlaneOut`+3) | 1 | - | `MovePlane` (code) | `StartPlane` (code), `StartPlaneHere` (code) |
| `$787D` | `PlaneTimer` (`PlaneOut`+4) | 1 | - | `MovePlane` (code) | `InitSimulation`, `AirCrash` (code) |
| `$7924` | `MeltdownPending` | 1 | Set by NuclearMeltdown; Meltdown runs at the next pass | `Meltdown` (`stage1/rec/tools`) | `InitSimulation`, `Meltdown` (`stage1/rec/disasters`), `NuclearMeltdown` (`stage1/rec/disasters`) |
| `$7995` | `TornadoCell` | 3 | The tornado: cell (column, row), out flag | `DrawMovers`, `MoveTornado` | `InitSimulation`, `MoveTornado` (`stage1/rec/disasters`), `StartTornado` (`stage1/rec/disasters`) |
| `$7997` | `TornadoOut` (`TornadoCell`+2) | 1 | - | `DrawMovers`, `MoveTornado` | `InitSimulation`, `MoveTornado` (`stage1/rec/disasters`), `StartTornado` (`stage1/rec/disasters`) |

## maps

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7AA4` | `MapsFrameText` | 101 | PrintInline codes of the frame and legend | `DrawBox`, `PrintInline` | - |
| `$7B0C` | `MapsKeysText` | 67 | PrintInline codes: the nine map choices | `PrintInline` | - |
| `$7B50` | `MapsCounter` | 1 | Counts the passes of the maps window | `MapsKeys` (`stage1/rec/menus`), `MapsWindow` (`stage1/rec/menus`) | `MapsWindow` (`stage1/rec/menus`) |

## simulation

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7BEF` | `CoverKernel` | 25 | The 5 x 5 coverage kernel: the shift count of each cell (9: none) | `AddFire` (`stage1/rec/growth`) | - |
| `$7C08` | `FireStrength` | 1 | the fire station's strength, 0-15 (`$0F` in the image; set by ApplyFunding) | `AddFire` (`stage1/rec/growth`), `Advise` (`stage1/rec/growth`) | `InitSimulation`, `ApplyFunding` (`stage1/rec/tools`) |
| `$7C31` | `PoliceStrength` | 1 | The police station's strength, `$0F` | `AddPolice` (`stage1/rec/growth`), `Advise` (`stage1/rec/growth`) | `InitSimulation`, `ApplyFunding` (`stage1/rec/tools`) |
| `$7C77` | `PollutionKernel` | 36 | The 6 x 6 kernel of the sources' pollution: the shift count of each cell (9: none) | `AddPollutionCell` (`stage1/rec/tools`) | - |
| `$7C9B` | `TrafficKernel` | 36 | The 6 x 6 kernel of the traffic's pollution | `AddPollutionCell` (`stage1/rec/menus`) | - |
| `$7CBF` | `PollutionStrength` | 1 | the source's strength | `AddPollutionCell` (`stage1/rec/tools`) | `AddTripTraffic` (`stage1/rec/menus`), `CoalStep` (`stage1/rec/tools`), `IndBuildingStep` (`stage1/rec/growth`), `NuclearStep` (`stage1/rec/tools`), `RadiationCell` (`stage1/rec/disasters`) +1 |
| `$7D2B` | `RouteStart` | 4 | The road or rail cell next to the zone a trip starts from (`$FFFF`: none) | `MakeTrip` (`stage1/rec/menus`), `PickRouteStart` (`stage1/rec/menus`), `ScanRing` (`stage1/rec/tools`) | `PickRouteStart` (`stage1/rec/menus`), `ScanRing` (`stage1/rec/tools`), `ScanRingSize` (`stage1/rec/city`) |
| `$7D2D` | `RingSize` (`RouteStart`+2) | 2 | the zone's size: width, height (3 x 3, or 4 x 4 and 6 x 6 for the big buildings) | `ScanRing` (`stage1/rec/tools`) | `ScanRing` (`stage1/rec/tools`), `ScanRingSize` (`stage1/rec/city`) |
| `$7E17` | `RingParks` | 6 | ScanRing's counts: parks, water, trees, transport, the amenity | `ComBuildingStep` (`stage1/rec/growth`), `CrimeOf` (`stage1/rec/tools`), `IndBuildingStep` (`stage1/rec/growth`), `LandValueOf` (`stage1/rec/menus`), `MakeTrip` (`stage1/rec/menus`) +7 | `CoalStep` (`stage1/rec/tools`), `LandValueOf` (`stage1/rec/tools`), `NuclearStep` (`stage1/rec/tools`), `ScanRing` (`stage1/rec/tools`), `ScanRingCell` (`stage1/rec/menus`) |
| `$7E18` | `RingWater` (`RingParks`+1) | 1 | - | `ScanRingCell` (`stage1/rec/city`), `SeaportStep` (code) | `ScanRing` (`stage1/rec/tools`), `ScanRingCell` (`stage1/rec/city`) |
| `$7E19` | `RingTrees` (`RingParks`+2) | 1 | - | `ScanRingCell` (`stage1/rec/menus`) | `ScanRing` (`stage1/rec/tools`), `ScanRingCell` (`stage1/rec/menus`) |
| `$7E1A` | `RingTransport` (`RingParks`+3) | 1 | - | `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `LandValueOf` (`stage1/rec/menus`), `MakeTrip` (`stage1/rec/menus`), `ResidentialStep` (`stage1/rec/tools`) +5 | `ScanRing` (`stage1/rec/tools`), `ScanRingCell` (`stage1/rec/menus`) |
| `$7E1B` | `RingAmenity` (`RingParks`+4) | 1 | - | `LandValueOf` (`stage1/rec/menus`), `ScanRingCell` (`stage1/rec/menus`) | `CoalStep` (`stage1/rec/tools`), `NuclearStep` (`stage1/rec/tools`), `ScanRing` (`stage1/rec/tools`), `ScanRingCell` (`stage1/rec/menus`) |
| `$7E1C` | `LandValue` (`RingParks`+5) | 1 | the zone's land value, LandValueOf's result | `CrimeOf` (`stage1/rec/tools`), `ZoneScoreOf` (`stage1/rec/tools`) | `LandValueOf` (`stage1/rec/tools`) |
| `$7E68` | `CrimeSpare` | 2 | One byte no code reads | `ZoneScoreOf` (`stage1/rec/menus`) | `CrimeOf` (`stage1/rec/tools`) |
| `$7E69` | `Crime` (`CrimeSpare`+1) | 1 | the zone's crime, CrimeOf's result | `ZoneScoreOf` (`stage1/rec/menus`) | `CrimeOf` (`stage1/rec/tools`) |
| `$7E9A` | `TaxPenalty` | 1 | TaxPenaltyOf's result | `TaxPenaltyOf` (`stage1/rec/bankrupt`), `ZoneScoreOf` (`stage1/rec/menus`) | `TaxPenaltyOf` (`stage1/rec/tools`) |
| `$7EBF` | `ZonePollutionMax` | 5 | The 2 x 2 maximum of Pollution at the zone | `CommercialScore` (`stage1/rec/growth`), `IndustrialScore` (`stage1/rec/growth`), `ResidentialScore` (`stage1/rec/tools`), `ZoneScoreOf` (`stage1/rec/tools`) | `CoalStep` (`stage1/rec/tools`), `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `NuclearStep` (`stage1/rec/tools`), `ResidentialStep` (`stage1/rec/tools`) +4 |
| `$7EC0` | `ZoneTrafficMax` (`ZonePollutionMax`+1) | 1 | ... of Traffic | - | `ZoneTraffic` (`stage1/rec/menus`) |
| `$7EC1` | `ZoneScore` (`ZonePollutionMax`+2) | 1 | ZoneScoreOf's result, 0-255 | `CommercialScore` (`stage1/rec/growth`), `IndustrialScore` (`stage1/rec/growth`), `ResidentialScore` (`stage1/rec/tools`) | `ZoneScoreOf` (`stage1/rec/tools`) |
| `$7EC2` | `ZoneDemand` (`ZonePollutionMax`+3) | 2 | the zone kind's demand (16 bits, signed), added to the score | `ZoneScoreOf` (`stage1/rec/menus`) | `CoalStep` (`stage1/rec/tools`), `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `NuclearStep` (`stage1/rec/tools`), `ResidentialStep` (`stage1/rec/tools`) +1 |
| `$7F10` | `ResLevel` | 2 | ResidentialScore's results: the level 0-7 and the building tile base | `ResidentialStep` (`stage1/rec/tools`), `ResBuildingScore` (code) | `ResidentialScore` (`stage1/rec/tools`) |
| `$7F11` | `ResTile` (`ResLevel`+1) | 1 | - | `ResidentialStep` (`stage1/rec/tools`) | `ResidentialScore` (`stage1/rec/tools`) |
| `$7F43` | `ComLevel` | 2 | CommercialScore's results: ZoneScore / 25 and 4 times it | `ComBuildingStep` (`stage1/rec/growth`) | `CommercialScore` (`stage1/rec/growth`) |
| `$7F44` | `ComTile` (`ComLevel`+1) | 1 | - | - | `CommercialScore` (`stage1/rec/growth`) |
| `$7F5D` | `IndLevel` | 2 | IndustrialScore's results: ZoneScore / 31 and 8 times it | `IndBuildingStep` (`stage1/rec/growth`) | `IndustrialScore` (`stage1/rec/growth`) |
| `$7F5E` | `IndTile` (`IndLevel`+1) | 1 | - | - | `IndustrialScore` (`stage1/rec/growth`) |
| `$7F78` | `PowerPlants` | 32 | The map addresses of the power stations found (FindPlants), 0 ended: room for 15 plants; FindPlants does not check the count, so a 16th plant puts the 0 over the DD 21 of its own LD IX,PowerPlants (`$7F98`) | `PowerFlood` | `FindPlants` |
| `$7FCC` | `Brownout` | 1 | Counts the power stations that ran out of capacity this pass (BROWNOUTS DETECTED) | `Advise` (`stage1/rec/menus`), `PowerCell` (code) | `PowerFlood`, `PowerCell` (code) |
| `$8015` | `FloodAbove` | 264 | The flood's span flags: the row above and below already queued | `FloodFill` (`stage1/rec/tools`), `FloodMark` (`stage1/rec/tools`), `FloodPop` (`stage1/rec/tools`), `PopCell` (`stage1/rec/menus`), `PowerCell` (`stage1/rec/tools`) | `FloodFill` (`stage1/rec/tools`), `FloodMark` (`stage1/rec/tools`), `FloodPush` (`stage1/rec/tools`), `PowerCell` (`stage1/rec/tools`), `PowerFlood` (`stage1/rec/tools`) +1 |
| `$8016` | `FloodBelow` (`FloodAbove`+1) | 1 | - | `FloodMark` (`stage1/rec/tools`) | `FloodFill` (`stage1/rec/tools`), `FloodMark` (`stage1/rec/tools`) |
| `$8017` | `FloodStart` (`FloodAbove`+2) | 2 | the station's cell (column, row) | `FloodFill` (`stage1/rec/tools`) | `PowerFlood` (`stage1/rec/tools`) |
| `$8019` | `FloodBudget` (`FloodAbove`+4) | 2 | the cells it may still power | `PowerCell` (`stage1/rec/tools`) | `PowerCell` (`stage1/rec/tools`), `PowerFlood` (`stage1/rec/tools`) |
| `$801B` | `FloodSP` (`FloodAbove`+6) | 2 | SP saved, to leave the flood at once | `PowerCell` (code) | `FloodFill` (`stage1/rec/tools`) |
| `$801D` | `CellStack` (`FloodAbove`+8) | 256 | 128 cell pairs: the flood's spans; also PushCell's stack | `FloodPop` (`stage1/rec/tools`), `PopCell` (`stage1/rec/menus`) | `FloodPush` (`stage1/rec/tools`), `PushCell` (`stage1/rec/menus`) |
| `$81DD` | `CityValue` | 6 | The city's assessed value (24 bits) and the last pass's (`$81E0`) | `AddValue`, `AssessCity`, `PrintNumberVar` (`stage1/rec/menus`) | `AddValue`, `AssessCity`, `InitSimulation` |
| `$81E0` | `CityValueLast` (`CityValue`+3) | 3 | - | `PrintNumberVar` (`stage1/rec/menus`) | `AssessCity`, `InitSimulation` |
| `$8265` | `PopBalance` | 2 | 4 (R - C - I): read by the evaluation | `Problems` (`stage1/rec/menus`) | `InitSimulation`, `PopBalanceOf` |
| `$827C` | `ResDemand` | 6 | The three demands (signed), read as ZoneDemand: R, C, I | `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `ResidentialStep` (`stage1/rec/tools`), `ResBuildingScore` (code) | `DemandOf`, `InitSimulation` |
| `$827E` | `ComDemand` (`ResDemand`+2) | 2 | - | `ComBuildingStep` (`stage1/rec/growth`) | `DemandOf`, `InitSimulation` |
| `$8280` | `IndDemand` (`ResDemand`+4) | 2 | - | `IndBuildingStep` (`stage1/rec/growth`) | `DemandOf`, `InitSimulation` |
| `$835D` | `SimPaused` | 2 | Nonzero: the zones are scanned but do not grow (the pause); never set: InitSimulation writes 0, ScanCityStep `$86F3` tests it, a second pause that is never used | `CoverStations`, `DecayPollution`, `ScanCity`, `SimTask` | `InitSimulation`, `SimTask` |
| `$835E` | `SimPass` (`SimPaused`+1) | 1 | the simulation pass counter | `CoverStations`, `DecayPollution`, `SimTask` | `InitSimulation`, `SimTask` |
| `$8443` | `Population` | 61 | The pass's counters, cleared by ClearCounters (`$8443-$847F`) | `Advise`, `AssessCity`, `Averages`, `Averages2`, `ClearCounters` +35 | `ClearCounters`, `CountPowered`, `IndustrialStep`, `AddPopulation` (`stage1/rec/tools`), `CellStep` (`stage1/rec/tools`) +25 |
| `$8446` | `ResPop` (`Population`+3) | 2 | (16 bits each from here) residential population | `Advise`, `ClearCounters`, `DemandOf`, `PopBalanceOf`, `ServiceNeeds` +2 | `ClearCounters`, `ResidentialStep` (`stage1/rec/tools`), `ResBuildingStep` (code) |
| `$8448` | `ComPop` (`Population`+5) | 2 | - | `Advise`, `ClearCounters`, `DemandOf`, `PopBalanceOf`, `ComBuildingStep` (`stage1/rec/growth`) +1 | `ClearCounters`, `ComBuildingStep` (`stage1/rec/growth`), `CommercialStep` (`stage1/rec/tools`) |
| `$844A` | `IndPop` (`Population`+7) | 2 | - | `Advise`, `ClearCounters`, `DemandOf`, `IndustrialStep`, `PopBalanceOf` +1 | `ClearCounters`, `IndustrialStep`, `IndBuildingStep` (`stage1/rec/growth`) |
| `$844C` | `PoliceCount` (`Population`+9) | 2 | - | `AssessCity`, `ClearCounters`, `Advise` (`stage1/rec/menus`), `PoliceStep` (`stage1/rec/growth`) | `ClearCounters`, `PoliceStep` (`stage1/rec/growth`) |
| `$844E` | `FireCount` (`Population`+11) | 2 | - | `AssessCity`, `ClearCounters`, `Advise` (`stage1/rec/menus`), `FireStep` (`stage1/rec/growth`) | `ClearCounters`, `FireStep` (`stage1/rec/growth`) |
| `$8450` | `ChurchCount` (`Population`+13) | 2 | - | `ClearCounters`, `ServiceNeeds`, `ChurchStep` (code) | `ClearCounters`, `ChurchStep` (code) |
| `$8452` | `HospitalCount` (`Population`+15) | 2 | - | `AssessCity`, `ClearCounters`, `ServiceNeeds`, `HospitalStep` (code) | `ClearCounters`, `HospitalStep` (code) |
| `$8454` | `NuclearCount` (`Population`+17) | 2 | - | `AssessCity`, `Averages`, `ClearCounters`, `Advise` (`stage1/rec/menus`), `NuclearStep` (`stage1/rec/tools`) | `ClearCounters`, `NuclearStep` (`stage1/rec/tools`) |
| `$8456` | `CoalCount` (`Population`+19) | 2 | - | `AssessCity`, `ClearCounters`, `Advise` (`stage1/rec/menus`), `CoalStep` (`stage1/rec/tools`) | `ClearCounters`, `CoalStep` (`stage1/rec/tools`) |
| `$8458` | `StadiumCount` (`Population`+21) | 2 | - | `AssessCity`, `ClearCounters`, `DemandOf`, `Advise` (`stage1/rec/menus`), `StadiumStep` (code) | `ClearCounters`, `StadiumStep` (code) |
| `$845A` | `AirportCount` (`Population`+23) | 2 | - | `AssessCity`, `Averages`, `ClearCounters`, `DemandOf`, `Advise` (`stage1/rec/menus`) +1 | `ClearCounters`, `AirportStep` (code) |
| `$845C` | `SeaportCount` (`Population`+25) | 2 | - | `AssessCity`, `ClearCounters`, `DemandOf`, `Advise` (`stage1/rec/menus`), `SeaportStep` (code) | `ClearCounters`, `SeaportStep` (code) |
| `$845E` | `UnpoweredZones` (`Population`+27) | 2 | - | `ClearCounters`, `CountPowered`, `Advise` (`stage1/rec/menus`), `Problems` (`stage1/rec/menus`) | `ClearCounters`, `CountPowered` |
| `$8460` | `PoweredZones` (`Population`+29) | 2 | - | `ClearCounters`, `CountPowered` (`stage1/rec/menus`) | `ClearCounters`, `CountPowered` (`stage1/rec/menus`) |
| `$8462` | `BuildingCount` (`Population`+31) | 2 | - | `Averages2`, `ClearCounters` | `ClearCounters` |
| `$8464` | `TransportUpkeep` (`Population`+33) | 2 | - | `ClearCounters`, `CellStep` (`stage1/rec/tools`), `MonthEnd` (`stage1/rec/tools`), `RailBridgeUpkeep` (code), `RailCellUpkeep` (code) +2 | `ClearCounters`, `CellStep` (`stage1/rec/tools`), `RailBridgeUpkeep` (code), `RailCellUpkeep` (code), `RoadBridgeUpkeep` (code) +1 |
| `$8466` | `PoliceUpkeep` (`Population`+35) | 2 | 100 per police station each pass (PoliceStep `$8D56`), powered or not; MonthEnd copies it to PoliceCost | `ClearCounters`, `MonthEnd` (`stage1/rec/tools`), `PoliceStep` (`stage1/rec/tools`) | `ClearCounters`, `PoliceStep` (`stage1/rec/tools`) |
| `$8468` | `FireUpkeep` (`Population`+37) | 2 | 100 per fire station (FireStep `$8D73`); MonthEnd copies it to FireCost | `ClearCounters`, `FireStep` (`stage1/rec/tools`), `MonthEnd` (`stage1/rec/tools`) | `ClearCounters`, `FireStep` (`stage1/rec/tools`) |
| `$846A` | `RoadCount` (`Population`+39) | 2 | - | `AssessCity`, `ClearCounters`, `Advise` (`stage1/rec/menus`), `CellStep` (`stage1/rec/tools`), `RoadCellCount` (code) | `ClearCounters`, `CellStep` (`stage1/rec/tools`), `RoadCellCount` (code) |
| `$846C` | `RailCount` (`Population`+41) | 2 | - | `AssessCity`, `ClearCounters`, `Advise` (`stage1/rec/menus`), `CellStep` (`stage1/rec/tools`), `RailCellCount` (code) | `ClearCounters`, `CellStep` (`stage1/rec/tools`), `RailCellCount` (code) |
| `$846E` | `CrimeSum` (`Population`+43) | 2 | - | `Averages2`, `ClearCounters`, `CrimeOf` (`stage1/rec/tools`) | `ClearCounters`, `CrimeOf` (`stage1/rec/tools`) |
| `$8470` | `CrimeCount` (`Population`+45) | 2 | - | `Averages2`, `ClearCounters`, `CrimeOf` (`stage1/rec/tools`) | `ClearCounters`, `CrimeOf` (`stage1/rec/tools`) |
| `$8472` | `LandValueSum` (`Population`+47) | 2 | - | `Averages2`, `ClearCounters`, `LandValueOf` (`stage1/rec/menus`) | `ClearCounters`, `LandValueOf` (`stage1/rec/menus`) |
| `$8474` | `LandValueCount` (`Population`+49) | 2 | - | `Averages2`, `ClearCounters`, `LandValueOf` (`stage1/rec/tools`) | `ClearCounters`, `LandValueOf` (`stage1/rec/tools`) |
| `$8476` | `TrafficSum` (`Population`+51) | 2 | - | `ClearCounters`, `DecayTraffic` | `ClearCounters`, `DecayTraffic` (`stage1/rec/menus`) |
| `$8478` | `TrafficCount` (`Population`+53) | 2 | - | `ClearCounters`, `DecayTraffic` | `ClearCounters`, `DecayTraffic` (`stage1/rec/menus`) |
| `$847A` | `PollutionSum` (`Population`+55) | 2 | - | `Averages`, `ClearCounters`, `DecayPollution`, `ZonePollution` (`stage1/rec/tools`) | `ClearCounters`, `ZonePollution` (`stage1/rec/tools`) |
| `$847C` | `PollutionCount` (`Population`+57) | 2 | - | `Averages`, `ClearCounters`, `DecayPollution`, `ZonePollution` (`stage1/rec/tools`) | `ClearCounters`, `ZonePollution` (`stage1/rec/tools`) |
| `$847E` | `FireCells` (`Population`+59) | 2 | - | `Averages`, `ClearCounters`, `FireCell` (`stage1/rec/disasters`) | `ClearCounters`, `FireCell` (`stage1/rec/disasters`) |
| `$849C` | `LastFireCells` | 8 | Copies of the last pass for the disasters: fires, airports, nuclear plants; the city centre | `AirCrash` (`stage1/rec/disasters`), `CentreDistance` (`stage1/rec/menus`), `NuclearMeltdown` (`stage1/rec/disasters`), `Problems` (`stage1/rec/menus`), `MoveTornadoStep` (code) | `Averages`, `InitSimulation` |
| `$849E` | `LastAirports` (`LastFireCells`+2) | 2 | - | `AirCrash` (`stage1/rec/disasters`) | `Averages`, `InitSimulation` |
| `$84A0` | `LastNuclear` (`LastFireCells`+4) | 2 | - | `NuclearMeltdown` (`stage1/rec/disasters`) | `Averages`, `InitSimulation` |
| `$84A2` | `CityCentre` (`LastFireCells`+6) | 2 | column, row | `CentreDistance` (`stage1/rec/menus`), `MoveTornadoStep` (code) | `Averages`, `InitSimulation` |
| `$84DD` | `AvgPollution` | 1 | Pollution's average | `Advise` (`stage1/rec/menus`), `Problems` (`stage1/rec/menus`) | `Averages`, `DecayPollution` |
| `$851A` | `AvgTraffic` | 1 | Traffic's average / 4 | `Advise` (`stage1/rec/menus`), `Problems` (`stage1/rec/menus`) | `DecayTraffic`, `InitSimulation` |
| `$8568` | `TripMade` | 2 | 1 when the zone's trip reached its destination | `AddTripTraffic` (`stage1/rec/menus`), `LandValueOf` (`stage1/rec/menus`), `TripStep` (`stage1/rec/menus`), `AirportStep` (code), `SeaportStep` (code) +1 | `CoalStep` (`stage1/rec/tools`), `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `MakeTrip` (`stage1/rec/menus`), `NuclearStep` (`stage1/rec/tools`) +5 |
| `$8569` | `TripMask` (`TripMade`+1) | 1 | the CellFlags bits the trip may travel (road 4, rail 2), from RouteStart's cell | `AddTripTraffic` (`stage1/rec/menus`), `TripStep` (`stage1/rec/menus`) | `MakeTrip` (`stage1/rec/menus`) |
| `$85C4` | `TripLeftover` | 18 | Leftover code no one calls (XOR A; LD (`$8568`),A; LD HL,(`$8462`); INC HL ...) | `TripStep` (`stage1/rec/menus`), `TripWalk` (`stage1/rec/menus`) | `TripStep` (`stage1/rec/menus`), `TripWalk` (`stage1/rec/menus`) |
| `$85D4` | `TripBack` (`TripLeftover`+16) | 1 | the direction the walk came from | `TripStep` (`stage1/rec/menus`) | `TripStep` (`stage1/rec/menus`), `TripWalk` (`stage1/rec/menus`) |
| `$85D5` | `TripSteps` (`TripLeftover`+17) | 1 | - | `TripStep` (`stage1/rec/menus`), `TripWalk` (`stage1/rec/menus`) | `TripWalk` (`stage1/rec/menus`) |
| `$8606` | `TripTurn` | 3 | TripStep's turn, direction and tries | `TripStep` (`stage1/rec/menus`) | `TripStep` (`stage1/rec/menus`) |
| `$8607` | `TripDir` (`TripTurn`+1) | 1 | - | `TripStep` (`stage1/rec/menus`) | `TripStep` (`stage1/rec/menus`) |
| `$8608` | `TripTries` (`TripTurn`+2) | 1 | - | `TripStep` (`stage1/rec/menus`) | `TripStep` (`stage1/rec/menus`) |
| `$865E` | `TripTargets` | 2 | The two BuildingValue kinds a trip may end at | `TripArrived` (`stage1/rec/menus`) | `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `ResidentialStep` (`stage1/rec/menus`), `AirportStep` (code), `ResBuildingPop` (code) +2 |
| `$86C5` | `ZonePowered` | 4 | ScanCity's state of the current cell: powered, kind (1 building, 2 zone), building type, zone centre | `CountPowered`, `IndustrialStep`, `ScanCity`, `ZoneStep`, `AirportStep` (`stage1/rec/tools`) +10 | `ScanCity`, `ZonePower`, `BuildingPower` (`stage1/rec/tools`) |
| `$86C6` | `CellKind` (`ZonePowered`+1) | 1 | - | `ScanCity`, `ZoneStep` | `ScanCity`, `ZonePower`, `BuildingPower` (`stage1/rec/tools`) |
| `$86C7` | `BuildingType` (`ZonePowered`+2) | 1 | - | `BuildingStep` (`stage1/rec/tools`) | `ScanCity`, `BuildingPower` (`stage1/rec/tools`) |
| `$86C8` | `ZoneCentre` (`ZonePowered`+3) | 1 | - | `ZoneStep`, `ZoneByKind` (code) | `ScanCity`, `ZonePower` |
| `$873B` | `ZoneCentreCell` | 1 | ZonePower's new centre cell | `ZonePower` | `ZonePower` |
| `$8785` | `CurCell` | 4 | The cell ScanCity is at: column, row; then its map address | `WidenExtent`, `CellStep` (`stage1/rec/tools`), `CentreCloseness` (`stage1/rec/menus`), `ComBuildingStep` (`stage1/rec/growth`), `CommercialStep` (`stage1/rec/growth`) +28 | `CellStep`, `ZoneStep`, `CommercialStep` (`stage1/rec/growth`), `CoverStations` (`stage1/rec/tools`), `IndustrialStep` (`stage1/rec/growth`) |
| `$8787` | `CurAddr` (`CurCell`+2) | 2 | - | `CellStep` (`stage1/rec/tools`), `FloodCell` (`stage1/rec/disasters`), `Meltdown` (`stage1/rec/disasters`), `ToRubble` (`stage1/rec/disasters`), `RailCellTrain` (code) +2 | `CellStep`, `ZoneStep` |
| `$87C8` | `ExtentCols` | 4 | The city's extent: greatest and least column, then row (ClearCounters sets 0, `$FF`); Averages puts its middle into CityCentre | `Averages`, `MinMax` | `ClearCounters`, `MinMax` |
| `$87CA` | `ExtentRows` (`ExtentCols`+2) | 2 | - | `Averages`, `MinMax` | `ClearCounters`, `MinMax` |
| `$87FB` | `BuildingRoutines` | 24 | The routines of the building kinds (BuildingKinds' second byte) | `BuildingStep` (`stage1/rec/tools`) | - |
| `$8813` | `BuildingKinds` | 86 | Per building type: type, routine (BuildingRoutines), level, density; `$FF` `$FF` ended | `BuildingStep` (`stage1/rec/tools`), `BuildingValue` (`stage1/rec/menus`) | - |
| `$8869` | `Density` | 2 | the current zone's density (ScanInsideCell) or the building's (BuildingKinds) | `ComBuildingStep` (`stage1/rec/growth`), `IndBuildingStep` (`stage1/rec/growth`), `ResidentialStep` (`stage1/rec/tools`), `ScanInsideCell` (`stage1/rec/menus`), `ResBuildingPop` (code) | `ZoneStep`, `BuildingStep` (`stage1/rec/tools`), `ScanInsideCell` (`stage1/rec/menus`), `ZoneByKind` (code) |
| `$886A` | `BuildingLevel` (`Density`+1) | 1 | the building's level (BuildingKinds' third byte) | - | `BuildingStep` (`stage1/rec/tools`) |
| `$88C5` | `RoadDecay` | 1 | The mask of the roads' decay (Random AND it = 0 crumbles a cell); `$FF` none | `Advise` (`stage1/rec/menus`), `CellStep` (`stage1/rec/tools`), `RoadCell` (code) | `InitSimulation`, `ApplyFunding` (`stage1/rec/tools`) |
| `$8902` | `RailDecay` | 1 | The same for the rails | `CellStep` (`stage1/rec/tools`), `RailCell` (code) | `InitSimulation`, `ApplyFunding` (`stage1/rec/tools`) |
| `$8985` | `FloodLeft` | 1 | The flood's spreads left (50) | `FloodCell` (`stage1/rec/disasters`) | `FloodCell` (`stage1/rec/disasters`), `StartFlood` (`stage1/rec/disasters`) |
| `$8998` | `SpreadCode` | 3 | Spread's cell (`$45` fire, `$44` flood), its kind (0 fire) and its neighbour count | `FillBuilding` (`stage1/rec/disasters`), `Spread` (`stage1/rec/disasters`), `SpreadTo` (`stage1/rec/disasters`) | `FireCell` (`stage1/rec/disasters`), `FloodCell` (`stage1/rec/disasters`), `Meltdown` (`stage1/rec/disasters`), `Spread` (`stage1/rec/disasters`) |
| `$8999` | `SpreadFlood` (`SpreadCode`+1) | 1 | - | `Spread` (`stage1/rec/disasters`), `SpreadTo` (`stage1/rec/disasters`) | `FireCell` (`stage1/rec/disasters`), `FloodCell` (`stage1/rec/disasters`) |
| `$899A` | `SpreadCount` (`SpreadCode`+2) | 1 | - | `Spread` (`stage1/rec/disasters`) | `Spread` (`stage1/rec/disasters`) |
| `$8A08` | `ZoneFrame` | 24 | The eight cells round a zone centre: row step, column step, the empty frame cell (`$49-$50`) | `DeclineCell` (`stage1/rec/tools`), `GrowCell` (`stage1/rec/menus`), `PickFrameCell` (`stage1/rec/tools`) | - |
| `$8B97` | `ResRevertZone` | 18 | The full R zone a block falls back to: houses `$40-$43` round the powered centre `$51` | - | - |
| `$8BA0` | `ResEmptyZone` (`ResRevertZone`+9) | 9 | the empty R zone, centre `$51`: a hospital or church falls back to it | - | - |
| `$8BBA` | `ComBuildings` | 10 | By ComLevel - 1: the commercial building variant (0-3) | `ComBuildingStep` (`stage1/rec/growth`) | - |
| `$8C41` | `ComEmptyZone` | 9 | The empty C zone, centre `$52` (powered) | `PutBuilding` (`stage1/rec/growth`) | - |
| `$8CF1` | `IndEmptyZone` | 9 | The empty I zone, centre `$53` (powered) | `PutBuilding` (`stage1/rec/growth`) | - |
| `$8E8A` | `LastPop` | 10 | The population at the last month's end; at the year's ends (`$8E8D` two years back, `$8E90` last year) | `MapsWindow`, `UiTask`, `Advise` (`stage1/rec/tools`), `CategoryOf` (`stage1/rec/menus`), `Evaluate` (`stage1/rec/menus`) +5 | `InitSimulation`, `MonthEnd`, `BudgetWindow` (`stage1/rec/menus`) |
| `$8E8D` | `PopYearBefore` (`LastPop`+3) | 3 | - | `PrintEvalFigures` (`stage1/rec/menus`) | `InitSimulation`, `MonthEnd` (`stage1/rec/tools`) |
| `$8E90` | `PopLastYear` (`LastPop`+6) | 3 | - | `CategoryOf` (`stage1/rec/menus`), `MonthEnd` (`stage1/rec/tools`), `PrintEvalFigures` (`stage1/rec/menus`), `TaxIncomeOf` (`stage1/rec/tools`) | `InitSimulation`, `MonthEnd` (`stage1/rec/tools`) |
| `$8E93` | `BudgetDue` (`LastPop`+9) | 1 | 1 while the UI task shows the budget (the year's end without the auto budget) | `MapsWindow`, `UiTask`, `MonthEnd` (`stage1/rec/menus`) | `InitSimulation`, `BudgetWindow` (`stage1/rec/menus`), `MonthEnd` (`stage1/rec/menus`) |
| `$8F01` | `AvgCrime` | 4 | Averages2's results: 2 x the crime average, the land value average / 8, the building count | `Advise` (`stage1/rec/menus`), `Problems` (`stage1/rec/menus`) | `Averages2`, `InitSimulation` |
| `$8F02` | `AvgLandValue` (`AvgCrime`+1) | 1 | - | `Problems` (`stage1/rec/menus`) | `Averages2`, `InitSimulation` |
| `$8F03` | `LastBuildings` (`AvgCrime`+2) | 2 | - | - | `Averages2`, `InitSimulation` |
| `$8F2F` | `HospitalNeed` | 2 | ServiceNeeds' results: ResPop / 18 - HospitalCount and ResPop / 20 - ChurchCount (0 when not positive) | `ResidentialBuild` (code) | `InitSimulation`, `ServiceNeeds`, `ResidentialBuildChurch` (code), `ResidentialBuildHospital` (code) |
| `$8F30` | `ChurchNeed` (`HospitalNeed`+1) | 1 | - | `ResidentialBuild` (code) | `InitSimulation`, `ServiceNeeds`, `ResidentialBuildChurch` (code) |
| `$8F67` | `GrowTries` | 5 | The speed's five values, copied from SpeedTable by SetSpeed: the growth tries, the I chance mask, the C chance mask, a fourth (no reader), the month mask; the image holds 8, 7, 7, 7, 1, a row SpeedTable does not have; SetSpeed overwrites it before any reader | `SimTask`, `ComBuildingStep` (`stage1/rec/growth`), `DeclineZone` (`stage1/rec/tools`), `GrowZone` (`stage1/rec/menus`), `IndBuildingStep` (`stage1/rec/growth`) +3 | `SetSpeed` |
| `$8F68` | `IndChance` (`GrowTries`+1) | 1 | - | `IndBuildingStep` (`stage1/rec/growth`), `ChurchCounted` (code), `HospitalCounted` (code), `ResBuildingScore` (code) | `SetSpeed` |
| `$8F69` | `ComChance` (`GrowTries`+2) | 1 | - | `ComBuildingStep` (`stage1/rec/growth`) | `SetSpeed` |
| `$8F6A` | `SpeedSpare` (`GrowTries`+3) | 1 | - | - | `SetSpeed` |
| `$8F6B` | `MonthMask` (`GrowTries`+4) | 1 | - | `SimTask` | `SetSpeed` |
| `$8F6C` | `SpeedTable` | 20 | four speeds of five: fast (8, 1, 15, 1, 0), normal (4, 3, 31, 3, 1), slow (3, 7, 63, 7, 3), paused (all `$FF`) | `SetSpeed` | - |

## uitask

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8F97` | `Funds` | 8 | The money (24 bits): 20 000 in the image | `FundsChanged`, `GreyUnaffordable`, `MonthEnd`, `NextMonth`, `PrintDate` +8 | `NextMonth`, `Spend`, `StartSimulation`, `CellFlagsOf` (`stage1/rec/city`), `CellStep` (`stage1/rec/metro`) +3 |
| `$8F9A` | `FundsSpare` (`Funds`+3) | 1 | - | `SaveCity` (`stage1/rec/menus`) | `LoadMap` (`stage1/rec/menus`) |
| `$8F9B` | `Month` (`Funds`+4) | 1 | 0-11 | `MonthEnd`, `NextMonth`, `PrintDate`, `SaveCity` (`stage1/rec/menus`) | `NextMonth`, `StartSimulation`, `LoadMap` (`stage1/rec/menus`) |
| `$8F9C` | `Year` (`Funds`+5) | 2 | 16 bits, 1902 in the image | `PrintDate`, `NextMonth` (`stage1/rec/tools`), `SaveCity` (`stage1/rec/menus`) | `StartSimulation`, `LoadMap` (`stage1/rec/menus`), `NextMonth` (`stage1/rec/tools`) |
| `$8F9E` | `PassSpare` (`Funds`+7) | 1 | - | - | - |
| `$8F9F` | `PassCount` | 1 | The UI task's pass counter (Periodic: the movers every 16, the advice every 32) | `AnimateFire`, `AnimateFlood`, `BlinkCell`, `DrawViewRowPass`, `Periodic` +5 | `UiTask`, `ScrollModeLoop` (code) |
| `$9056` | `LastFunds` | 2 | Funds' low 16 bits as last shown | `FundsChanged` | `FundsChanged` |

## disasters

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$916D` | `DisasterDue` | 1 | The disaster RunDisaster starts (0 none) | `RunDisaster` | `PickDisaster` (`stage1/rec/disasters`), `RunDisaster` (`stage1/rec/disasters`), `RandomDisasterSet` (code) |

## budget

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$91BC` | `BudgetWindowText` | 338 | The budget window's menu description: FISCAL BUDGET, the tax rate, the three fundings, the cash lines, GO WITH THESE FIGURES. The numbers live inside the text (menu codes 5, 6, 7, section DrawMenu): TaxRate and the three funding percentages are the bytes the player edits. | `Advise` (`stage1/rec/menus`), `DrawMenu` (`stage1/rec/menus`), `EditDown` (`stage1/rec/city`), `EditUp` (`stage1/rec/menus`), `FundFire` (`stage1/rec/tools`) +10 | `EditDown` (`stage1/rec/city`), `EditUp` (`stage1/rec/menus`) |
| `$91E4` | `TaxRate` (`BudgetWindowText`+40) | 114 | the tax rate, 0-20 (7 in the image): code 7's value byte | `Advise` (`stage1/rec/menus`), `DrawMenu` (`stage1/rec/menus`), `EditDown` (`stage1/rec/city`), `EditUp` (`stage1/rec/menus`), `PrintEditField` (`stage1/rec/menus`) +5 | `EditDown` (`stage1/rec/city`), `EditUp` (`stage1/rec/menus`) |
| `$9256` | `TransportPercent` (`BudgetWindowText`+154) | 25 | the transport funding, 0-100 % | `DrawMenu` (`stage1/rec/menus`), `FundTransport` (`stage1/rec/tools`), `PrintMenuText` (`stage1/rec/menus`) | - |
| `$926F` | `PolicePercent` (`BudgetWindowText`+179) | 25 | - | `DrawMenu` (`stage1/rec/menus`), `FundPolice` (`stage1/rec/tools`), `PrintMenuText` (`stage1/rec/menus`) | - |
| `$9288` | `FirePercent` (`BudgetWindowText`+204) | 134 | - | `DrawMenu` (`stage1/rec/menus`), `FundFire` (`stage1/rec/tools`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | - |
| `$930E` | `TaxIncome` | 27 | 24 bits: last year's population / 100 x TaxRate | `ApplyFunding` (`stage1/rec/tools`), `BudgetTotals` (`stage1/rec/tools`), `CapFire` (`stage1/rec/tools`), `CapPolice` (`stage1/rec/tools`), `CapTransport` (`stage1/rec/tools`) +7 | `InitSimulation`, `BudgetFigures` (`stage1/rec/tools`), `BudgetTotals` (`stage1/rec/tools`), `FundFire` (`stage1/rec/tools`), `FundPolice` (`stage1/rec/tools`) +6 |
| `$9311` | `TransportCost` (`TaxIncome`+3) | 2 | the year's requests (16 bits each): transport upkeep, police, fire | `ApplyFunding` (`stage1/rec/tools`), `FundTransport` (`stage1/rec/tools`), `PrintBudget` (`stage1/rec/menus`), `StartTrain` (`stage1/rec/tools`) | `InitSimulation`, `MonthEnd` (`stage1/rec/tools`) |
| `$9313` | `PoliceCost` (`TaxIncome`+5) | 2 | - | `ApplyFunding` (`stage1/rec/tools`), `FundPolice` (`stage1/rec/tools`), `PrintBudget` (`stage1/rec/menus`) | `InitSimulation`, `MonthEnd` (`stage1/rec/tools`) |
| `$9315` | `FireCost` (`TaxIncome`+7) | 2 | - | `ApplyFunding` (`stage1/rec/menus`), `FundFire` (`stage1/rec/tools`), `PrintBudget` (`stage1/rec/menus`) | `InitSimulation`, `MonthEnd` (`stage1/rec/tools`) |
| `$9317` | `TransportFunded` (`TaxIncome`+9) | 2 | what is granted: the request x percent / 100, capped by the money | `ApplyFunding` (`stage1/rec/menus`), `BudgetTotals` (`stage1/rec/tools`), `CapFire` (`stage1/rec/tools`), `CapPolice` (`stage1/rec/tools`), `CapTransport` (`stage1/rec/tools`) +1 | `InitSimulation`, `FundTransport` (`stage1/rec/tools`), `CapTransport` (code) |
| `$9319` | `PoliceFunded` (`TaxIncome`+11) | 2 | - | `ApplyFunding` (`stage1/rec/tools`), `BudgetTotals` (`stage1/rec/tools`), `CapFire` (`stage1/rec/tools`), `CapPolice` (`stage1/rec/tools`), `PrintBudget` (`stage1/rec/menus`) | `InitSimulation`, `FundPolice` (`stage1/rec/tools`), `CapPolice` (code) |
| `$931B` | `FireFunded` (`TaxIncome`+13) | 2 | - | `ApplyFunding` (`stage1/rec/menus`), `BudgetTotals` (`stage1/rec/tools`), `CapFire` (`stage1/rec/tools`), `PrintBudget` (`stage1/rec/menus`) | `InitSimulation`, `FundFire` (`stage1/rec/tools`), `CapFire` (code) |
| `$931D` | `FundedTotal` (`TaxIncome`+15) | 3 | 24 bits | `BudgetTotals` (`stage1/rec/tools`) | `BudgetTotals` (`stage1/rec/tools`) |
| `$9320` | `CashFlow` (`TaxIncome`+18) | 3 | 24 bits: TaxIncome - FundedTotal | `PrintNumberVar` (`stage1/rec/menus`) | `BudgetTotals` (`stage1/rec/tools`) |
| `$9323` | `FundsBefore` (`TaxIncome`+21) | 3 | 24 bits | `CapFire` (`stage1/rec/tools`), `CapPolice` (`stage1/rec/tools`), `CapTransport` (`stage1/rec/tools`), `PrintNumberVar` (`stage1/rec/menus`) | `BudgetFigures` (`stage1/rec/tools`) |
| `$9326` | `FundsAfter` (`TaxIncome`+24) | 3 | 24 bits: the new Funds | `MonthEnd` (`stage1/rec/tools`), `PrintNumberVar` (`stage1/rec/menus`) | `BudgetTotals` (`stage1/rec/tools`) |
| `$9357` | `HookSpare` | 1 | One byte no code reads | - | - |
| `$93F6` | `CapWork` | 3 | 24 bits: the money left for a funding | `CapFire` (code), `CapPolice` (code), `CapTransport` (code) | `CapFire` (`stage1/rec/tools`), `CapPolice` (`stage1/rec/tools`), `CapTransport` (`stage1/rec/tools`) |
| `$950A` | `DecayMasks` | 32 | By funded / (cost / 8), 0-15: the roads' and rails' decay mask (`$0F` crumbles most, `$FF` none) | `ApplyFunding` (`stage1/rec/tools`) | - |
| `$951A` | `StrengthLevels` (`DecayMasks`+16) | 16 | and the police and fire strength (0-15) | `ApplyFunding` (`stage1/rec/tools`) | - |

## evaluation

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$95D7` | `EvaluationText` | 352 | The evaluation window: the poll, the worst problems, population, migration, value, category, level, score | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$9750` | `CategoryLimits` | 15 | The five population limits (24 bits): 2000, 10 000, 50 000, 100 000, 500 000 | `CategoryOf` (`stage1/rec/menus`) | - |
| `$975F` | `Category` | 1 | 0 VILLAGE, 1 TOWN, 2 CITY, 3 CAPITAL, 4 METROPOLIS, 5 MEGALOPOLIS | `CategoryOf` (`stage1/rec/city`), `PrintEvalFigures` (`stage1/rec/menus`) | `CategoryOf` (`stage1/rec/menus`) |
| `$978F` | `Migration` | 3 | PopLastYear - PopYearBefore (24 bits) | `PrintNumberVar` (`stage1/rec/menus`) | `PrintEvalFigures` (`stage1/rec/menus`) |
| `$9801` | `ProblemSum` | 2 | The problems added up | `Problems` (`stage1/rec/menus`), `ScoreOf` (`stage1/rec/menus`) | `Problems` (`stage1/rec/menus`) |
| `$98FA` | `CityScore` | 2 | 0-1000 | `Poll` (`stage1/rec/menus`) | `ScoreOf` (`stage1/rec/menus`) |
| `$992F` | `PollYes` | 2 | The poll: of 100 Random draws (0-1023), how many are below CityScore (YES) and not (NO) | `Poll` (`stage1/rec/menus`) | `Poll` (`stage1/rec/menus`) |
| `$9930` | `PollNo` (`PollYes`+1) | 1 | - | `Poll` (`stage1/rec/menus`) | `Poll` (`stage1/rec/menus`) |
| `$9996` | `Advice` | 1 | The advice shown (0 none, 1-`$15`): GameTexts 23 + Advice | `ShowAdvice`, `Problems` (`stage1/rec/menus`) | `Advise`, `SetAdvice` |
| `$99AA` | `AdviceSpare` | 3 | One byte no code reads | `Advise` | `Advise` |
| `$99AB` | `AllZones` (`AdviceSpare`+1) | 2 | ResPop + ComPop + IndPop (16 bits) | `Advise` | `Advise` |

## overview

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9B4E` | `MapKeyCells` | 18 | The nine map keys' screen cells (row, column): the keys 1-9 of the maps window | `HighlightMapKey` | - |
| `$9BF8` | `OverviewSpare` | 1 | OverviewSpare | - | - |
| `$9C2B` | `MapArea` | 44 | The map area shown, 0-8 (the digit - 1) | `DrawOverview`, `HighlightMapKey`, `ShrinkLine`, `LayerOf` (`stage1/rec/menus`), `PatternMark` (code) | `DrawOverview`, `MapsKeysDigit` (code) |
| `$9C2C` | `OverviewSpare2` (`MapArea`+1) | 2 | - | - | - |
| `$9C2E` | `OverviewOrigin` (`MapArea`+3) | 2 | the area's top-left cell (column, row) | `DrawOverview` | `DrawOverview` |
| `$9C30` | `RightNibble` (`MapArea`+5) | 1 | 1 when the cell goes in the right half of the byte | `DrawOverview`, `ShrinkLine`, `PatternMark` (code) | `DrawOverview` |
| `$9C31` | `OverviewCellAt` (`MapArea`+6) | 2 | the cell drawn (column, row) | `DrawOverview`, `LayerOf` (`stage1/rec/menus`) | `DrawOverview` |
| `$9C33` | `MapAreaAddrs` (`MapArea`+8) | 18 | the nine areas' map addresses (48 x 48 cells, 24 apart) | `DrawOverview` | - |
| `$9C45` | `MapAreaCells` (`MapArea`+26) | 18 | their top-left (row, column) | `DrawOverview` | - |
| `$9CFA` | `LayerColours` | 8 | The attribute of each layer level 1-7 (paper colours) | - | - |
| `$9D43` | `MapLayer` | 1 | The layer: 0 city, 1 pollution, 2 police, 3 fire, 4 traffic, 5 power, 6 transport, 7 crime (6 in the image) | `HighlightLayer`, `LayerOf`, `MapsKeys` (`stage1/rec/menus`) | `MapsKeys` (`stage1/rec/menus`) |

## saveload

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9E77` | `SearchingText` | 18 | PrintInline codes: a box, SEARCHING | `DrawBox` (`stage1/rec/menus`), `PrintInline` (`stage1/rec/menus`) | - |
| `$9EC1` | `LoadingText` | 11 | PrintInline: LOADING | `PrintInline` (`stage1/rec/menus`) | - |
| `$9F1D` | `FoundText` | 13 | FoundText | `PrintInline` (`stage1/rec/menus`) | - |

## dialogs

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9F40` | `PlantChoice` | 1 | The power station menu's answer: 0 none, 1 nuclear, 2 coal | `PowerPlantTool` (`stage1/rec/tools`) | `ChooseNuclear` (`stage1/rec/tools`), `NoPlant` (code) |
| `$9F41` | `PlantMenu` | 125 | the menu: SELECT TYPE, NUCLEAR POWER STATION `$5000`, COAL POWER STATION `$3000`, NONE | `DrawMenu` (`stage1/rec/tools`), `NumberRepeat` (`stage1/rec/tools`), `PrintMenuText` (`stage1/rec/tools`), `RunMenu` (`stage1/rec/tools`) | - |
| `$9FD3` | `ConfirmMenu` | 84 | ConfirmMenu | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowInlineWindow` (`stage1/rec/levels`) +1 | - |
| `$A02B` | `SystemMenu` | 134 | SYSTEM: about, start new city, use old landscape, load, save, exit | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | - |
| `$A0CA` | `AboutText` | 297 | AboutText | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$A1F6` | `LoadMenuText` | 81 | LoadMenuText | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$A24A` | `SaveMenuText` | 80 | SaveMenuText | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$A29D` | `FileNameText` | 63 | FileNameText | `DrawMenu` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$A2DF` | `LoadErrorText` | 31 | LoadErrorText | `DrawMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$A30C` | `TapeText` | 31 | TapeText | `DrawMenu` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | - |
| `$A32B` | `AutoBulldoze` | 4 | the options (toggles): AUTO-BULLDOZE 1, AUTO-BUDGET 0, SOUND 1, ZONE DEMOLISH WAIT 1 | `CheckSite`, `DrawMenu` (`stage1/rec/tools`), `MonthEnd` (`stage1/rec/tools`), `NoiseBurst` (`stage1/rec/disasters`), `NumberRepeat` (`stage1/rec/tools`) +2 | `NumberRepeat` (`stage1/rec/tools`) |
| `$A32C` | `AutoBudget` (`AutoBulldoze`+1) | 1 | - | `DrawMenu` (`stage1/rec/tools`), `MonthEnd` (`stage1/rec/tools`), `NumberRepeat` (`stage1/rec/tools`), `PrintMenuText` (`stage1/rec/menus`) | `NumberRepeat` (`stage1/rec/tools`) |
| `$A32D` | `SoundOn` (`AutoBulldoze`+2) | 1 | - | `DrawMenu` (`stage1/rec/tools`), `NoiseBurst` (`stage1/rec/disasters`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`) | `NumberRepeat` (`stage1/rec/menus`) |
| `$A32E` | `DemolishWait` (`AutoBulldoze`+3) | 1 | - | `DrawMenu` (`stage1/rec/tools`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `ConfirmHold` (code) | `NumberRepeat` (`stage1/rec/menus`) |
| `$A32F` | `OptionsMenu` | 124 | OPTIONS: the four toggles, SIMULATION SPEED, EXIT MENU | `DrawMenu` (`stage1/rec/tools`), `NumberRepeat` (`stage1/rec/tools`), `PrintMenuText` (`stage1/rec/tools`), `RunMenu` (`stage1/rec/tools`) | - |
| `$A3AB` | `Speed` | 1 | 0 fast, 1 normal, 2 slow, 3 paused | `SetSpeed`, `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `SetSpeedItem` (`stage1/rec/menus`) |
| `$A3AF` | `SpeedMenuText` | 94 | SpeedMenuText | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | `SetSpeedItem` (`stage1/rec/menus`) |
| `$A3D0` | `SpeedMarkFast` (`SpeedMenuText`+33) | 11 | the asterisk places of the four items | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `SetSpeedItem` (`stage1/rec/menus`) |
| `$A3DB` | `SpeedMarkNormal` (`SpeedMenuText`+44) | 13 | - | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `SetSpeedItem` (`stage1/rec/menus`) |
| `$A3E8` | `SpeedMarkSlow` (`SpeedMenuText`+57) | 11 | - | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `SetSpeedItem` (`stage1/rec/menus`) |
| `$A3F3` | `SpeedMarkPaused` (`SpeedMenuText`+68) | 26 | - | `DrawMenu` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `SetSpeedItem` (`stage1/rec/menus`) |
| `$A43D` | `DisastersOff` | 1 | DISABLE ALL (a toggle): no random disasters | `RandomDisaster`, `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `NumberRepeat` (`stage1/rec/menus`) |
| `$A43E` | `DisasterMenu` | 124 | DISASTERS: fire, flood, earthquake, air crash, tornado, nuclear meltdown | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | - |
| `$A4C2` | `WindowsMenu` | 79 | WINDOWS: maps, budget, evaluation | `DrawMenu`, `NumberRepeat`, `PrintMenuText`, `RunMenu` | - |
| `$A511` | `MapsDue` | 1 | set by MAPS: the UI task opens the maps window | `UiTask`, `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `MapsItem`, `MapsWindow` |
| `$A518` | `Level` | 1 | 0 easy, 1 medium, 2 difficult | `StartSimulation`, `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintEvalFigures` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`) +2 | `SetLevel` |
| `$A51C` | `LevelMenuText` | 141 | LevelMenuText | `DrawMenu`, `NumberRepeat`, `PrintMenuText`, `RunMenu`, `ShowInlineWindow` (`stage1/rec/levels`) +1 | - |
| `$A5E5` | `OldLandscapeMenu` | 141 | OldLandscapeMenu | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`), `ShowWindow` (`stage1/rec/menus`) | `SetLevel` (`stage1/rec/menus`) |
| `$A61B` | `GeneShown` (`OldLandscapeMenu`+54) | 87 | the gene in the menu (code 6's value) | `DrawMenu` (`stage1/rec/menus`), `NumberRepeat` (`stage1/rec/menus`), `PrintMenuText` (`stage1/rec/menus`), `RunMenu` (`stage1/rec/menus`) | `SetLevel` (`stage1/rec/menus`) |
| `$A6A4` | `CreatingText` | 52 | CREATING LANDSCAPE, PLEASE WAIT | `DrawMenu`, `PrintMenuText` | - |
| `$A6D8` | `InputAt` | 33 | the line editor: row, column, the buffer, the cursor, the digits flag, the length, a buffer of 12, the key delay | `InputLine` (`stage1/rec/menus`), `InputName` (`stage1/rec/levels`), `InputToNumber` (`stage1/rec/menus`), `NumberDigits` (`stage1/rec/menus`), `NumberToInput` (`stage1/rec/menus`) +4 | `InputGene` (`stage1/rec/menus`), `InputLine` (`stage1/rec/menus`), `InputName` (`stage1/rec/menus`), `LoadCity` (`stage1/rec/menus`), `NumberToInput` (`stage1/rec/menus`) +3 |
| `$A6DA` | `InputBuffer` (`InputAt`+2) | 2 | - | `InputLine` (`stage1/rec/menus`), `NumberDigits` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/menus`), `InputBlank` (code) | `InputGene` (`stage1/rec/menus`), `LoadCity` (`stage1/rec/menus`), `NumberToInput` (`stage1/rec/menus`), `SaveCity` (`stage1/rec/menus`), `SetLevel` (`stage1/rec/levels`) |
| `$A6DC` | `InputCursor` (`InputAt`+4) | 1 | - | `InputLine` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/menus`), `InputBlank` (code) | `InputLine` (`stage1/rec/menus`), `InputName` (`stage1/rec/levels`) |
| `$A6DD` | `InputDigits` (`InputAt`+5) | 1 | - | `InputLine` (`stage1/rec/menus`), `InputName` (`stage1/rec/levels`), `PutDigit` (`stage1/rec/menus`) | `InputGene` (`stage1/rec/menus`), `InputName` (`stage1/rec/menus`) |
| `$A6DE` | `InputLength` (`InputAt`+6) | 1 | - | `InputLine` (`stage1/rec/menus`), `NumberDigits` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/menus`), `CursorRight` (code) | `InputGene` (`stage1/rec/menus`), `InputName` (`stage1/rec/menus`) |
| `$A6DF` | `InputText` (`InputAt`+7) | 16 | - | `InputToNumber` (`stage1/rec/menus`), `NumberToInput` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/menus`) | `InputLine` (`stage1/rec/menus`), `NumberToInput` (`stage1/rec/menus`), `PutDigit` (`stage1/rec/menus`) |
| `$A6EF` | `InputDelay` (`InputAt`+23) | 10 | - | `InputLine` (`stage1/rec/menus`) | `InputLine` (`stage1/rec/menus`) |
| `$A7EB` | `NumberAt` | 2 | NumberAt | `PutDigit` (`stage1/rec/menus`) | `NumberDigits` (`stage1/rec/menus`) |

## workspace

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A884` | `MoverSprites` | 160 | The movers' 16 x 16 sprites, 32 bytes each: the plane, two tornado frames, the train across and down | `DrawMover` (`stage1/rec/tools`) | - |
| `$A924` | `SaveName` | 12 | The name typed for LOAD and SAVE | `LoadHeader` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/menus`) | `InputLine` (`stage1/rec/menus`) |
| `$A930` | `SaveHeader` | 31 | The tape header (31 bytes): file name 12, Funds 3, a spare, Month, Year 2, a spare, the city name 11 (SaveCityName `$A944-$A94E`) | `LoadHeader` (`stage1/rec/menus`), `LoadMap` (`stage1/rec/menus`), `PrintFileName` (`stage1/rec/menus`), `ShowInput` (`stage1/rec/menus`) | `InputLine` (`stage1/rec/menus`), `SaveCity` (`stage1/rec/menus`) |
| `$A93C` | `SaveFunds` (`SaveHeader`+12) | 8 | - | `LoadMap` (`stage1/rec/menus`) | `SaveCity` (`stage1/rec/menus`) |
| `$A944` | `SaveCityName` (`SaveHeader`+20) | 11 | - | `LoadMap` (`stage1/rec/menus`) | `SaveCity` (`stage1/rec/menus`) |
| `$A94F` | `SaveSpare` | 1 | The city name's twelfth letter: SaveCity copies 12 letters to `$A944`, but the header block ends at `$A94E`, so this byte never reaches the tape; LoadCity copies it back from RAM | `LoadMap` (`stage1/rec/menus`) | `SaveCity` (`stage1/rec/menus`) |
| `$A950` | `FireCover` | 576 | The 24 x 24 fire coverage, 0-15 (zero in the image: built at run time) | `ClearCover`, `InitSimulation`, `AddFire` (`stage1/rec/growth`), `Grid24` (`stage1/rec/menus`) | `ClearCover`, `InitSimulation`, `AddFire` (`stage1/rec/growth`) |
| `$AB90` | `PoliceCover` | 576 | The 24 x 24 police coverage, 0-15 | `ClearCover`, `InitSimulation`, `AddFire` (`stage1/rec/growth`), `Grid24` (`stage1/rec/menus`), `PoliceAt` (`stage1/rec/tools`) | `ClearCover`, `InitSimulation`, `AddFire` (`stage1/rec/growth`) |
| `$ADD0` | `Pollution` | 2304 | The 48 x 48 pollution, 0-255 | `DecayPollution`, `InitSimulation`, `AddPollutionCell` (`stage1/rec/tools`), `Grid24` (`stage1/rec/disasters`), `Grid48` (`stage1/rec/tools`) +3 | `DecayPollution`, `InitSimulation`, `AddPollutionCell` (`stage1/rec/tools`) |
| `$B6D0` | `Traffic` | 2304 | The 48 x 48 traffic, 0-`$F0` | `DecayTraffic`, `InitSimulation`, `AddPollutionCell` (`stage1/rec/growth`), `AddTripTraffic` (`stage1/rec/menus`), `Grid24` (`stage1/rec/menus`) +3 | `DecayTraffic`, `InitSimulation`, `AddPollutionCell` (`stage1/rec/growth`), `AddTripTraffic` (`stage1/rec/menus`) |
| `$BFD0` | `PowerMap` | 1152 | The powered bit of each map cell, 12 bytes a row | `InitSimulation`, `PowerFlood`, `ZonePower`, `BuildingPower` (`stage1/rec/tools`), `IsConductive` (`stage1/rec/tools`) +2 | `InitSimulation`, `PowerFlood`, `PowerCell` (`stage1/rec/tools`) |
| `$C450` | `CityMap` | 9216 | The 96 x 96 map, all land (2) in the image: NewLandscape makes it | `CellStep`, `CheckSite`, `CoverStations`, `Disc`, `DrawOverview` +37 | `Disc`, `MakeCoast`, `NewLandscape`, `PutBuilding`, `BuildingPower` (`stage1/rec/tools`) +17 |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E850` | `IconTiles` | 536 | The 67 icon and frame tiles, 8 bytes each: the tool palette (2 x 2 each), the frames `$38-$3F`, the separators `$40-$42` | `DrawIcon`, `DrawIconHere`, `FindPlants` | - |
| `$EA68` | `CellTiles` | 752 | The 94 cell tiles of the map (cells 0-`$5D`; `$5A-$5D` the fire and flood frames AnimateFire and AnimateFlood copy) | `AnimateFire`, `AnimateFlood`, `DrawCell`, `ShrinkLine`, `Periodic` (`stage1/rec/levels`) | `AnimateFire`, `AnimateFlood`, `Periodic` (`stage1/rec/levels`) |
| `$ED58` | `BuildingTiles` | 1952 | The 244 building tiles (a building row's tile numbers n, n + 1, ...) | `DrawCell` (`stage1/rec/tools`) | - |
| `$F4F8` | `IconAttrs` | 56 | The attributes of icons 0-55 (DrawIcon reads IconAttrs + A; the frame tiles use PrintAttr) | `DrawIcon` | - |
| `$F530` | `CellAttrs` | 94 | The cells' attributes | `DrawCell` | - |
| `$F58E` | `BuildingAttrs` | 244 | The building tiles' attributes | `DrawCell` (`stage1/rec/tools`) | - |

## tasks

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F682` | `UiStack` | 64 | The UI task's stack: Entry sets SP = `$F6C2` (UiStack+`$40`); written down to `$F68A` (menus frame 3466), 8 bytes above BuildingAttrs | - | `InterruptJump` |
| `$F6C2` | `SimStack` | 44 | The simulation task's stack below SimFrame: it grows down from `$F704` into SimFrame and below; written down to `$F6D0` (menus frame 5498); `$F6C2-$F6CF` never written | - | `InterruptJump` (`stage1/rec/tools`) |
| `$F6EE` | `SimFrame` | 20 | The simulation task's first frame: 20 bytes of registers, then the entry | - | `InterruptJump` |
| `$F702` | `SimEntry` | 2 | SimTask: the first switch returns into it | - | `StartSimulation` |
| `$F704` | `TaskNow` | 1 | 0 the UI task runs, 1 the simulation | `Interrupt` | `Interrupt` |
| `$F705` | `SwitchOff` | 2 | Nonzero: the interrupt does not switch tasks (the UI's critical parts) | `Interrupt` | `Click`, `Entry`, `LayerOf`, `StartSimulation`, `UiTask` +2 |
| `$F706` | `SwitchSpare` (`SwitchOff`+1) | 1 | - | - | - |
| `$F707` | `UiSP` | 4 | the stacks of the two tasks while the other runs | `Interrupt` | `Interrupt`, `StartSimulation` |
| `$F709` | `SimSP` (`UiSP`+2) | 2 | - | `Interrupt` | `Interrupt`, `StartSimulation` |

## system

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F74E` | `PrintCharCode` | 6 | The print state: the character, the screen address, the column and row, the attribute. PrintCharCode is written by PrintDigit and read by nobody (PrintGlyph takes the code in A). | `DrawBox`, `DrawBoxRow`, `DrawIcon`, `DrawIconHere`, `NextColumn` +5 | `DrawBox`, `DrawBoxRow`, `DrawIcon`, `DrawMenu`, `NextColumn` +24 |
| `$F74F` | `PrintAddr` (`PrintCharCode`+1) | 2 | - | `DrawBoxRow`, `DrawIcon`, `DrawIconHere`, `NextColumn`, `PrintDigit` +2 | `DrawBoxRow`, `DrawIcon`, `NextColumn`, `PrintDigit`, `PrintInline` +11 |
| `$F751` | `PrintCol` (`PrintCharCode`+3) | 1 | - | `DrawBox`, `DrawBoxRow`, `NextColumn`, `MenuField` (`stage1/rec/menus`), `PrintNumberAt` (`stage1/rec/menus`) | `DrawBox`, `DrawBoxRow`, `DrawMenu`, `NextColumn`, `InputGene` (`stage1/rec/menus`) +2 |
| `$F752` | `PrintRow` (`PrintCharCode`+4) | 1 | - | `DrawBoxRow`, `PrintNumberAt` (`stage1/rec/menus`) | `DrawBox`, `DrawBoxRow`, `DrawMenu`, `InputGene` (`stage1/rec/menus`), `MenuTab` (`stage1/rec/tools`) +1 |
| `$F753` | `PrintAttr` (`PrintCharCode`+5) | 1 | - | `PrintGlyph` | `PrintInline`, `ShowMenu`, `UiTask`, `BudgetHook` (`stage1/rec/menus`), `PrintProblem` (`stage1/rec/menus`) +6 |
| `$F798` | `ReadInputLeftover` | 7 | Leftover: RET, JP `$FE0F`, JP `$FE0F` (no code runs them) | - | - |
| `$F7BB` | `E5Fill` | 1345 | Leftover: 1345 bytes of `$E5` (the byte a CP/M or +3DOS format writes); no stack or code touches them (L1: untouched) | - | - |
| `$FCFF` | `InterruptSpare` | 258 | InterruptSpare | `InterruptJump` | - |
| `$FD00` | `VectorTable` (`InterruptSpare`+1) | 257 | 257 bytes `$FC`: with I = `$FD` any vector reads `$FCFC` | `InterruptJump` | - |
