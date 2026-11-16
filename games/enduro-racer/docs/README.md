# Enduro Racer: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the premise, the controls, every screen, the HUD, the five courses from the track data, the rules (the timer, EXTENDED PLAY, the score and the time bonus, crashes, ramps), two players, the demo, game over and the high scores, the cheat key |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map, the heatmap and the stack, the images from the load to play, the state variables, the frame budget, the leftovers, the module map and the call graph, the ports on the 48K and the 128K |
| [3. Build and load](03-build-and-load.md) | the tape block by block, the two BASICs and their ERR_SP trick, SpeedLock 2's three decoders, the loader and its changing keys, Mover's `LDDR`, the build, the releases, the POKEs |
| [4. Game loop](04-game-loop.md) | the state machine, IM 2 and the handler with its own stack, the repair of the pushed word, the 128K test, the free-running race loop (8 frames a pass), the heavy passes, the timer and the delays, the stage 3 reset |
| [5. Controls](05-controls.md) | the five methods and ControlTable, ReadControls and PatchControls, the ports, the menu and MenuSelect, DEFINE KEYS (ScanKeys, KeyMap, GetKey), the lean and the steering, the throttle and the brakes with the exact speed arithmetic, the wheelie, pause and reset, the cheat key, two players |
| [6. Rendering](06-rendering.md) | the screen and the back buffer, RowTable, the road model (rows, bends, crests), DrawRoad's edges, GroundTexture, the horizons and their rotation, the shifted sprites, the riders, objects, bike, splash and dust, the order of one pass, CopyBuffer against the beam, who writes the buffer and the screen |
| [7. Objects](07-objects.md) | the data map, StageTable `$9E67` and StageParams `$A187`, the segment byte (bits 0-1 the bend, bits 2-3 the crest), the track commands byte by byte with a decode of stage 1's first 1 024 units, AdvanceTrack and TrackStep, the eight object types and DrawObject, the collision sizes, the six rider records, their ring of 256 rows, their jumps and poses, the game variables |
| [8. HUD and text](08-hud-and-text.md) | the printer and RowTable, the font and the big digits, every string, the HUD's fields and who reprints them, the score as text, the timer in passes, the speed, the countdown in attributes, the words printed into the road, the lap table, the high scores and the name entry, windows and the credits |
| [9. Sound](09-sound.md) | the sound map, the tune stream and the channel record, the two tunes rendered, the engine on the beeper and on the AY, the AY noise of falls and bounces and the skid noise, the beeps and the crash noise, the cost, 48K against 128K |
| [10. Gameplay logic](10-gameplay-logic.md) | the pass as the clock and the bike's states, SPEED's three bands, the brakes and the time-out's roll, steering against a bend's push and the road's edge, the wheelie, ramps and jumps, collisions with objects, riders and trucks, the crash and getting up, the timer, the score, the checkpoints, the time-out, the finish and the lap table, two players, the riders' AI, the techniques with their recordings, the cheat key, the bugs (the stage 3 reset), the notable features |
| [11. Data reference](11-data-reference.md) | every data entry of the game image and the tape parts, with its readers and writers in the recordings (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its callers, runs and figures (generated, as 11) |

## Terms

Each term once, here; the documents use these names and no others.

| Term | Meaning |
| --- | --- |
| back buffer | `$EB00-$FDFF`: the race picture's lines 40-191 (40-63 at `$EB00`, 32 bytes a line; 64-191 at `$EE00` in the screen's layout, `$A600` above it), drawn each pass and copied to the screen by CopyBuffer; its first rows lie over the track tables, which Init has copied to `$5E80` |
| bend | bits 0-1 of a segment byte (Bend `$5E2F`): one of three profiles (BendProfiles) shifts each row's centre sideways (BendRows), pushes the bike outward and scrolls the horizon; bit 4 (BendDir) is its side |
| big digit | a 16 x 15 digit of BigDigits `$7C54`, used for the stage and the timer |
| bounce | BounceTime passes of forced steering and SPEED x 250/256 after a side-on hit, a rider or a landing |
| CheatStep | the cheat's operand: CAPS SHIFT + Q fixes ScrollStep at `$1000` on stages 1-3 |
| crest | bits 2-3 of a segment byte (Crest `$5E31`): a column of CrestTable moves each row's screen line (RoadLines) up or down; a rise or a dip, the road straight |
| element | one track command `TL x`: type T (high nibble), a gap of L x 2 units from the previous element, and its x; doc 7 (7.4) |
| EXTENDED PLAY | the 50 seconds (at most 99) added to the timer at the end of stages 1-4 |
| FinishRider | the rider StageEnd puts beside the bike after stage 5 (of riders 0-3, the one with the largest row byte); its row 64 ends the game |
| frame | one TV frame, 1/50 s, 69 888 T on the 48K; an interrupt at its start |
| GetUp | the rider's walk back to the bike at a turn after a fall: 3 units a pass, the timer held, no collisions |
| line | a pixel line 0-191 of the screen from the top; the printer places text by line, not by character row |
| Mover | the `LDDR` at `$5B09` that moves the loaded game up by `$5E0` before `JP $8000` |
| pass | one turn of RaceLoop: the track moved, the back buffer drawn and copied, the controls read; 8.0 frames on average in `c1` |
| pattern call | `E0 ADDR LEN`: the track runs the pattern at ADDR and returns from the element that brings its count to LEN units, counted from the element before the call (that element is not placed); doc 7 (7.4) |
| PrintOrigin | the operand at `$8380`: a window's corner added to every print; DrawWindow sets it, Menu clears it |
| ramp tax | Ramp's SPEED x (192 + 8 x Wheelies) / 256: no wheelie keeps 3/4, 8 wheelie passes all |
| ring | the riders' one-byte rows: 256 rows around the bike, a rider overtaken wraps to 255; doc 7 (7.8) |
| row | a road row 0-127, 0 the nearest; RoadLines gives each row its line |
| RowTable | `$FE00-$FF7F`: the address of each of the 192 pixel lines; SetRowTable points lines 40-191 at the back buffer during the race, so every drawing routine and the printer draw there |
| segment | 128 distance units of the track, one byte of StageList: the bend (bits 0-1), the crest (2-3), the bend's side (4), the stage's last segment (5) |
| SpeedLock 2 | the tape protection: an R-keyed decoder chain and a loader with its own signal and changing store keys |
| technique run | one of doc 10's runs: c1's play start replayed with c1's keys and one change (`tools/play_techniques.py` for the samples and GIFs), recorded as `tech-ramp-wheelie`, `tech-land-wheelie`, `tech-brake-bend` and `tech-cheat` ([WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)) |
| time bonus | at a stage's end, the timer's tens and units as the score's 100 000s and 10 000s digits: 10 000 points a timer second left |
| timer second | one step of Timer `$5E1F`: 10 passes, about 80 frames (1.6 s) without falls; the timer is held while the rider gets up |
| unit | the track's distance unit; a pass moves SPEED x 14 / 256 units, a segment is 128 |
