# Tables

CSV with a header row (tools/res_formats.py). The first line is a `#` comment naming the table; a column marked
`(label)` is written from the row number (the tool, the speed, the category ...) and ignored when read. Numbers:
plain decimal, `$` hex, `%` binary. The terrain generator's tables are DiscShapes and Coast; the map itself is made
at run time from the seed (NewLandscape `$6A8E`) and is not in the image.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `DiscShapes.csv` | `$6AD3-$6ADA` | 8 | Discs `$6ADB` | The terrain's land discs: four pairs of shifts, the disc's two axes (round, flat, tall) |
| `Coast.csv` | `$6B21-$6BA4` | 132 | MakeCoast `$6BA5` (CPIR) | 66 masks of a water cell's eight neighbours (bit set = land) and the coast cell each turns the water into |
| `ToolSizes.csv` | `$6DAF-$6DCA` | 28 | ToolSize `$6DCB` | Width and height of each of the 14 tools' boxes |
| `ToolPrices.csv` | `$6E1E-$6E39` | 28 | ToolPrice `$6E3A` | The 14 tools' prices (16 bits) |
| `NetworkShapes.csv` | `$6ED3-$6EE2` | 16 | FixNetworkCell `$6EE3` | The shape offset of a road, rail or power line cell by its 4-bit neighbour mask |
| `CellFlags.csv` | `$6F9C-$6FF5` | 90 | CellFlagsOf `$7599` | The flags of the cells 0-`$59` (buildings give `$99` without the table) |
| `Crossings.csv` | `$7062-$7085` | 36 | CrossNetwork `$7086` (CPIR) | For each network the cells it may cross and the crossing cell that results |
| `BridgeDirs.csv` | `$71FF-$720E` | 16 | Bridge `$721E` | The bridge direction (1-4, 0 none) by the neighbour mask |
| `BridgeSteps.csv` | `$720F-$721D` | 15 | Bridge `$721E` | Per direction 0-4: row step, column step, the bridge cell's offset |
| `BulldozeCosts.csv` | `$7301-$7307` | 7 | BulldozeBuilding `$7308` | The price of clearing a building by its size: the size squared |
| `BuildingValues.csv` | `$7682-$768D` | 12 | BuildingValue `$768E` (TripArrived `$8660`) | The class a trip's end matches, by building routine |
| `CoverKernel.csv` | `$7BEF-$7C07` | 25 | StampFire `$7C09`, StampPolice `$7C32` | The 5 x 5 coverage kernel: the strength shifted right this many times (9: none) |
| `PollutionKernel.csv` | `$7C77-$7C9A` | 36 | StampPollution `$7CC0` | The 6 x 6 kernel of a source's pollution, as above |
| `TrafficKernel.csv` | `$7C9B-$7CBE` | 36 | AddTripTraffic `$8599` | The 6 x 6 kernel of the traffic's pollution |
| `BuildingKinds.csv` | `$8813-$8868` | 86 | BuildingStep `$886B`, BuildingValue `$768E` | Per building type: routine (BuildingRoutines), level, density; the `end` row (`$FF $FF`) stops the search |
| `ZoneFrame.csv` | `$8A08-$8A1F` | 24 | PickFrameCell `$8A20` | The eight cells round a zone centre and the empty frame cell (`$49-$50`) of each |
| `ComBuildings.csv` | `$8BBA-$8BC3` | 10 | ComBuildingStep `$8BE0` | By ComLevel - 1, the commercial building variant (0-3) |
| `SpeedTable.csv` | `$8F6C-$8F7F` | 20 | SetSpeed `$8F80` | Per speed: growth tries, the I and C chance masks, an unread byte, the month mask |
| `Funding.csv` | DecayMasks `$950A`, StrengthLevels `$951A` | 32 | ApplyFunding `$952A` | By the share funded (0-15): the roads' and rails' decay mask and the police and fire strength |
| `CategoryLimits.csv` | `$9750-$975E` | 15 | CategoryOf `$9760` | The population (24 bits) from which TOWN, CITY, CAPITAL, METROPOLIS, MEGALOPOLIS start |

Not tables here: the starting funds (20 000 / 10 000 / 5000) and the date (January 1902) are instruction operands
in StartSimulation `$830C`; the tax rate (7, maximum 20) and the three funding percentages (100) are values
inside the budget window's text (text/menus/Budget.txt, `{byte ...}`). Leftover: SpeedTable's fourth column; SetSpeed copies it
to SpeedSpare `$8F6A`, which no instruction reads (known from the code: no operand names it).
