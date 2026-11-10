# SimCity: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game as played: the screens, menus and dialogs, starting a city (level, name, gene), the 14 tools with costs, the zone rules and score, taxes and the budget, the categories, the disasters, the evaluation and advice, a whole city, what the Spectrum leaves out of Maxis' original |
| [2. Architecture](02-architecture.md) | the machine budget, the 29 modules and the call graph of the two tasks, the memory map as stage 2 corrected it, the three images and the heatmap, the two stacks, the leftovers, the frame budget, the +3 disk release |
| [3. Build and load](03-build-and-load.md) | the tape as a picture, the BASIC, the two-layer protected loader (the R-keyed tail, LoadBlock's `received XOR key XOR E`) with worked bytes, the hang at `$FFA0`, the mover, the load in `c1`, the check that what loads is what runs, the build that encrypts it back |
| [4. Game loop](04-game-loop.md) | the two tasks and the IM 2 switcher `$F70B` with SwitchOff `$F705`, the state machine, a switch's cost, a beam timeline of four frames, the UI pass and its 2000-loop wait, the simulation pass step by step, the speed masks and the month, the passes per frame of each task in all eleven recordings, the heaviest pass |
| [5. Controls](05-controls.md) | one reader in the interrupt (keyboard, Kempston, Sinclair into KeyRows `$5B00`), the pointer (one step a pass, no acceleration), the click and its four regions, the tool shortcuts SYMBOL SHIFT + 1-0, CAPS SHIFT + 5-8 scrolling, the map click and the drag, the menus and the number fields (the only acceleration), the text line, the maps window keys, the input timing |
| [6. Rendering](06-rendering.md) | the screen layout, the map and its cell and building tiles, the 16-pass row sweep (DrawViewRowPass) and DrawView, building rows, the blink of unpowered zones, road traffic, the pointer and the tool box, the movers, the fire and flood animation, the overview maps and their eight layers, code against the screen, no graphs |
| [7. Objects](07-objects.md) | the objects of the city: the 90 cell codes and their CellFlags, buildings as runs of bytes (top row byte, `$C0` fillers, type = tile / 8), the zones and their state machines, the side arrays (cover, PowerMap, pollution, traffic), the counters and city variables, the movers (train, plane, tornado), the 31-byte save header and the map on tape, Random (period 65 536) |
| [8. HUD and text](08-hud-and-text.md) | the top third field by field (address, format, routine, beat), the ROM font made bold by PrintGlyph `$F754`, PrintInline `$5DEF` and its five codes, DrawBox's self-modified frames, PrintNumber24 with trailing-space padding, GameTexts and FindText's walk, the status panel rebuilt, the advice line, the menu engine (descriptions, DrawMenu, RunMenu, EditNumber) and all 18 menus and dialogs, the budget window recomputed live through MenuHook, the evaluation window, the city name edited in place, the data sheet of every string |
| [9. Sound](09-sound.md) | the two beeper routines: NoiseBurst `$5B48` (200 loops, random bits through a gate mask, DI ... EI) and the four disaster noises with their gate schedules, ToneBeep `$5B66` (500 cycles, 164 ms measured), cost and contention, the interrupt held by the noise, the SOUND-off bug that leaves interrupts off, five rendered WAVs, what else could sound |
| [10. Gameplay logic](10-gameplay-logic.md) | the rules: the pass step by step, the power flood with its cell budget, the ring, land value, crime, tax penalty and zone score, the R/C/I growth rules, population and demand, trips and traffic, the stamps and coverage, funding and the ApplyFunding fire-branch bug, the special buildings and the city's value, the category and the growth ceiling (10 624 at tax 0), the generator from the gene, every disaster, the tools' refusals |
| [11. Data reference](11-data-reference.md) | every data entry with its readers and writers (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its runs, time and animations (generated) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| area (maps window) | one of nine 48 x 48 cell squares of the map, 24 cells apart, chosen with SYMBOL SHIFT + 1-9 (MapArea `$9C2B`); docs 05, 06 |
| bit-7 string | a text whose last letter has bit 7 set; GameTexts `$5FC6` and MonthNames `$5F8A`, found by FindText `$6317` by counting ends; doc 08 |
| building row | a start byte (`$80-$BF`: width in bits 0-2, power bit 4, top-row bit 5) and continuation bytes holding the building's tile number n, then `$C0` fillers; doc 06, 6.5 and doc 07, 7.2 |
| demand | DemandOf `$8282`: 8 x the zone-count imbalance plus 4 per stadium (R), airport (C) or seaport (I), minus 26 (R) or 30 (C, I); doc 10, 10.5 |
| EntryJump | `$5B19`: `JR $5B1B`, never run from tape; the +3 disk's boot enters here; doc 02, 2.8 |
| flood budget | the cells one plant can power a pass: 1350 nuclear, 450 coal; spent, the fill exits through `LD SP,(FloodSP)` and Brownout + 1; doc 10, 10.2 |
| frame | one TV frame of 69 888 T (1/50 s) and its interrupt (Interrupt `$F70B`); every frame number in the case counts interrupts from the start of its recording. A task's frames are the ones the switch gives it: in play the simulation gets about one in three (32-34 % in `city`, `city2`, `metro`), in the menus 6-17 %; doc 04, 4.8 |
| gate mask | register E of NoiseBurst `$5B48`: a new random speaker bit only in the loops where D AND E is 0; doc 09, 9.2 |
| gene | the five-digit, 16-bit landscape seed the player types (Gene `$6A8C`, default 00003); NewLandscape `$6A8E` builds the map from it alone, so a gene always gives the same map; doc 01, 1.4 and doc 10, 10.11 |
| inline text | the codes after a `CALL PrintInline` `$5DEF`: `$FF` row column, `$FB` attribute, `$FD` box, `$FC` number, `$FE` end; any other byte a character; the routine returns after the `$FE`; doc 08, 8.3 |
| KeyRows | `$5B00-$5B07`: the eight keyboard half rows, written every frame by ReadInput `$F781`; the joysticks clear bits in them; doc 05, 5.1 |
| land value | LandValueOf `$7E1D`: 0 unless powered, with transport in the ring and a trip made (or traffic 50); else 127 - the distance to CityCentre + the ring's amenity; doc 10, 10.3 |
| layer (maps window) | one of eight colourings of an area (CITY, POLLUTN, POLICE, FIREDEP, TRAFFIC, POWER, TRANSPT, CRIME), chosen with Q / A (MapLayer `$9D43`); docs 05, 06 |
| LoadBlock | `$FEBD`: the ROM's LD-BYTES copied to RAM and changed: flag `$00`, stores `received XOR key XOR E` (key + 3 a byte, E the count's low byte); doc 03, 3.5 |
| LoadFailed | `$FFA0`: the endless border-stripe loop a bad tape block falls into; doc 03, 3.6 |
| menu description | the bytes DrawMenu `$67C3` draws and RunMenu `$6944` runs: a header row, then items (0 text, 1 toggle, 2 action, 3 separator, 4 end, 8 number); the edited values live inside it; doc 08, 8.9 |
| MenuHook | `$6942`: a routine RunMenu calls on entry and EditNumber after each Q / A: BudgetHook `$9346` or Evaluate `$9737`, which recompute and print the window's numbers; doc 08, 8.10 |
| month | MonthMask + 1 simulation passes: one at FAST, 2 at NORMAL, 4 at SLOW, 256 at PAUSED; it ends in MonthEnd `$8E94` and NextMonth (Month `$8F9B`, 0 = JAN). Measured at FAST: 371 wall frames (7.4 s) in `city2`, 483 (9.7 s) in `metro`; doc 04, 4.7 |
| MonthMask | `$8F6B`: a month ends when `SimPass AND MonthMask` is 0; `$00` FAST, `$01` NORMAL, `$03` SLOW, `$FF` PAUSED; doc 04, 4.7 |
| mover | the train, the plane or the tornado: a 16 x 16 sprite ORed over the view (no mask), wiped by the row redraw; doc 06, 6.9 and doc 07, 7.6 |
| pass | one turn of a task's loop. A UI pass is one turn of UiLoop `$8FCC`, counted by PassCount `$8F9F`: 1.6 UI frames in play (0.74 of them UiDelay), about 2.4 wall frames, some 21 a second. A simulation pass is one turn of SimTaskPass `$8362`: counters cleared, power flooded, every map byte scanned, decays, demand, then perhaps the month; 84-157 of the simulation's own frames in the recordings (180 the heaviest, doc 4.9), 242-471 wall frames. In docs 05, 06 and 08 a pass is a UI pass, in docs 07 and 10 a simulation pass; doc 04, 4.5, 4.6, 4.8 |
| R key | the loader's first layer: the byte at `$FE80 + k` is XORed with `(2 + 8 k) AND $7F`, the R register's value in the decryption loop; doc 03, 3.4 |
| ResTile | an R zone's target density, score / 2; the zone grows or declines one house a pass toward it; doc 10, 10.4 |
| ring | the 12 cells that touch a zone's sides (no corners), read by ScanRing `$7D34` for transport, parks, water and trees; doc 10, 10.3 |
| share | ApplyFunding's funded / (cost / 8), the index into DecayMasks and StrengthLevels; doc 10, 10.8 |
| SimFrame | `$F6EE`: the 20 zero bytes and SimEntry `$F702` that make the simulation start as if interrupted at SimTask; doc 04, 4.3 |
| simulation task | the program that runs the city: SimTask `$835F`, SimTaskPass `$8362`; its stack from `$F704` down (`$F6E8-$F703`, over SimFrame); doc 04 |
| SOUND | the OPTIONS toggle SoundOn `$A32D`; it gates NoiseBurst only, not ToneBeep, and NoiseBurst tests it after its DI, so with SOUND off the interrupts stay off; doc 09, 9.6 |
| SpeedTable | `$8F6C`: four rows of five bytes (GrowTries, IndChance, ComChance, a spare, MonthMask) for FAST, NORMAL, SLOW, PAUSED, copied by SetSpeed `$8F80`; doc 04, 4.7 |
| stamp | adding a source's strength through a kernel of shifts into a side array (pollution on Grid48, police and fire cover on Grid24), with no clipping at the map edge; doc 10, 10.7 |
| sweep | the 16 UI passes in which DrawViewRowPass `$6434` redraws the 16 view rows once each, row PassCount AND 15; about 38 frames; doc 06, 6.3 |
| switch | the interrupt handing the CPU to the other task: when SwitchOff is 0, Interrupt `$F70B` swaps SP between UiSP `$F707` and SimSP `$F709` and flips TaskNow. The switches come in pairs, so the simulation keeps each frame it gets for exactly one frame; the UI holds the rest while SwitchOff is set (its drawing, the menus). A switch costs about 400 T, the handler with the input read about 780 T a frame; doc 04, 4.3 and 4.8 |
| SwitchOff | `$F705`: while nonzero the interrupt does not switch tasks; the UI sets it around its drawing and while a menu or window is open, so the simulation is frozen there; doc 04, 4.3 |
| task | one of the two programs that share the CPU, each on its own stack, switched by the interrupt: the UI task and the simulation task; doc 04, 4.1 |
| TaskNow | `$F704`: 0 while the UI runs, 1 while the simulation runs; doc 04, 4.3 |
| tool box | the inverted rectangle under the pointer showing a tool's size, shown only during UiDelay; doc 06, 6.8 |
| trip | MakeTrip `$856A`: a random walk of up to 30 steps on one network from RouteStart to a neighbour of the wanted BuildingValue; road trips add traffic and smog; doc 10, 10.6 |
| UI task | the program that runs the pointer, the map window, the menus and dialogs: UiTask `$8FA0`, UiLoop `$8FCC`, UiPass `$8FDA`; its stack UiStack `$F682-$F6C1`, from `$F6C2` down; doc 04, 4.5 |
| UiDelay | `$8FD5`: the 2000-loop busy wait (51 995 T, 74 % of a frame) of every UI pass, about a third of all the CPU time, and where the simulation gets its frames; doc 04, 4.5 |
| zone score | ZoneScoreOf `$7EC4`: land value minus pollution, crime and tax penalty (each floored at 0), plus the kind's demand, clamped to 0-255; doc 10, 10.3 |
