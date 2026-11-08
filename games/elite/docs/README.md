# Elite: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | Elite as a player meets it: the version, eight recorded screens, the keys, the Cobra and its equipment, the galaxies and the 19 blueprints, trading, jumping, the law, the missions, the rating, options, the protection |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map (a figure), the stages from the tape to play, the frame and the interrupt, the main loop's call graph, the state, where the time goes |
| [3. Build and load](03-build-and-load.md) | the tapes block by block, Softlock (the lying BASIC, the self-decrypting stub, the patched loader, the chunk reader, the decryptor), the kickoff, the fast-load trap gap, the source build, the crack |
| [4. Game loop](04-game-loop.md) | the state machine, FlightLoop, the frame schedule, the order of work inside a space pass, timing, the scenes outside the pass, the pause |
| [5. Controls](05-controls.md) | the ports, the keyboard scan in the interrupt, the key map, the joysticks, the steering accumulators, views, menus, hidden keys, what the recordings pressed |
| [6. Rendering](06-rendering.md) | the back buffer, one pass, ClearView's stack fill, lines, ships, circles, the stardust, the copy and the beam, the cost of drawing |
| [7. Objects](07-objects.md) | the eight slots, the ship record, the 19 blueprints, creation, moving, the player's death, tactics, spawning, collisions, the laser, the missiles |
| [8. HUD and text](08-hud-and-text.md) | where text goes, the font, the token printer, the planet descriptions, numbers and cash, messages, the dashboard |
| [9. Sound](09-sound.md) | one beeper and eleven effects (no music): requests, the ROM played as a pulse train, the sweep, the noise, the scene sounds, the click, every effect recorded, the cost |
| [10. Gameplay logic](10-gameplay-logic.md) | the galaxy from the seeds, distances, the market (checked against the snapshots), trading, the jump, bounties and the rating, missions, the commander, the course of the recordings |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |
| [Runtime analysis](runtime-analysis.md) | where the T-states go, per scene and frame by frame: the 3D pipeline, the scanner, the four random generators, the arithmetic, the beam, the interrupt and the sound, call graphs and flame graphs |
| [Lenslok](lenslok.md) | the lens and its optics, the picture the game draws (model against emulator), the code, every code it can ask (enumerated with the game's own code; the atlas of challenges, real ones from the emulator, a wrong and a right answer filmed), the answer computed from the seed, the history, the crack `ELITE48.TAP`; the full list in [lenslok-codes.md](lenslok-codes.md) |
| [The galaxy](galaxy.md) | the galaxy generator step by step: the seeds, the twist, the names, the system data, the descriptions, the eight galaxies, the BBC's |
| [The 3D engine](3d-engine.md) | from a ship's slot to the wireframe: the number formats, the universe rotation, the projection, the faces, the lines, the costs, the BBC's |
| [The scenes](scenes.md) | the gameplay recorded by the bot: docking, trading and saving, combat, the galactic hyperdrive, the missions, scooping, the joystick |
| [The ships](ships.md) | the 19 blueprints one by one: each turning, drawn by the game's code, with its numbers, what spawns it, where it is met, and the BBC differences |
| [Against the BBC](bbc-comparison.md) | the Spectrum game set against BBC Elite's source: the blueprints, the galaxy, the market, the arithmetic, the flight model, kills, missions; what is the same and what changed |
| [The trading course](trading-guide.md) | trading as a get-rich-quick course with real numbers: the price formula worked out, why only the economies matter, five schemes (agricultural, minerals, high-tech, illegal, mix) with their best routes, a league of 1000 simulated commanders from Lave, the pirate risk of contraband, the market's quirks |
| [Texts](texts/README.md) | the box's instructions, the manual and the Lenslok sheet as Markdown, checked against the code |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| pass | one run of the main loop |
| frame | one TV frame of the 48K, 69 888 T-states, 50 a second; a recording's frames count from its start |
| `F_T` | a TTD position: frame F, T-state T inside it (`1030_0-1130_0` is a trace from frame 1030 to 1130) |
| space pass | a pass with a 3D view on screen: the view cleared, drawn into the back buffer `$C000` and copied |
| slot | one of the eight ship records (7.1); slot 7 holds the title's ship and the player's missile |
| `c0` | power-on, Side A, the fast LD-BYTES trap on, 1500 frames with no input after the load: stuck at the Lenslok (3.9) |
| `c1` | power-on, Side A, the trap off (`tools/capture_real_rom.py`): the Softlock load at signal speed, ENTER, the code `si`, the title (`tests/inputs/c1-lenslok.txt`) |
| `k1` | the crack `ELITE48.TAP`, the trap off, ENTER, no code typed (`tests/inputs/k1-cracked.txt`) |
| `d1` | 2710 frames from `work/snaps/title-A.szx` (the title of `c1`): docked, the status, market, data and chart screens, the launch (`tests/inputs/d1-docked.txt`) |
| `f1` | 4856 frames from the same title: the launch, flight past the station, the jump from Lave to Diso, laser shots in empty space (`tests/inputs/f1-hyperspace.txt`) |
| `w1` | 6691 frames from the same title: the launch, the pause option F, the misjump into witch space, the fight with four Thargoids, the death (`tests/inputs/w1-witchspace.txt`) |
| `b1` | power-on, Side B (the Adder), the trap off: the Softlock load at signal speed, ENTER (`tests/inputs/b1-sideb.txt`); the Lenslok passed live with the code `1Q` by `tools/b1_live.py` |
| `t1` | a new game at Lave: buying, selling, equipping and the commander saved to tape (`tests/inputs/t1-trade.py`, [scenes](scenes.md) 2) |
| `dk` | the rich commander `rich.tap`: docking by hand, then by the computer (`tests/inputs/dk-dock.py`, [scenes](scenes.md) 1) |
| `k2` | FIGHTER (`k2.tap`) in witch space: a missile, the E.C.M., the energy bomb, kills and the rating (`tests/inputs/k2-combat.py`, [scenes](scenes.md) 3) |
| `gx` | the galactic hyperdrive to galaxy 2 and the commander GALAXY2 saved (`tests/inputs/gx-galactic.py`, [scenes](scenes.md) 4) |
| `m1` | NOVA (`nova.tap`): the 32nd jump and the nova mission (`tests/inputs/m1-nova.py`, [scenes](scenes.md) 5) |
| `m2` | MAYDAY (`mayday.tap`): the Thargoid mission (`tests/inputs/m2-mayday.py`, [scenes](scenes.md) 6) |
| `cs` | a plate of alloys scooped after a kill, from `work/snaps/cs-debris.szx` (`tests/inputs/cs-scoop.py`, [scenes](scenes.md) 7) |
| `j1` | the Kempston joystick and the options from the title (`tests/inputs/j1-joystick.py`, [scenes](scenes.md) 8) |
| `fs` | the fuel scoop tried at Diso's sun, never reached (`tests/inputs/fs-fuel.py`, [scenes](scenes.md) 9) |
| trace | an access trace of a window of a recording (`work/<rec>/traces/F_T-F_T.uatr`): every instruction with its T-state and every read, write and port access |
| L1 | unreal-ng's routine map of a recording (`work/<rec>/l1.json`): entries, calls, per-routine counts and T-states |
| *inference* | a claim the code suggests and no recording or document proves |
