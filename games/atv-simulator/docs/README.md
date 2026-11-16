# ATV Simulator: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the goal, the controls, every screen (an atlas of 20), the HUD, the six trails drawn from `src/res`, the rules (the clock in passes, the score, the bonus with its 8-bit wrap, EXTENDED PLAY, the second round), a crash and the walk back, fuel, two players, TIME OUT and the name entry |
| [2. Architecture](02-architecture.md) | the eight modules and their call graph, the memory map in three states (the tune player copied to `$5B00`, trail 6 to `$60AC`, the buffers `$F03C` / `$F71C`), the stages from the tape, the heatmap and the stack (54 bytes at most), the variables and the 50-byte records, the frame budget for one and two players, the leftovers (the Z80 source text in trail 6's tail) |
| [3. Build and load](03-build-and-load.md) | the tape (TZX 1.10, eight ROM blocks), the BASIC and the 34-byte loader at `$FFDC` that skips two headers by the flag test, the load at signal speed, GameEntry's copies, the sprites shifted in place, the build, the releases, the four ZXDB POKEs and their real effects |
| [4. Game loop](04-game-loop.md) | the state machine, IM 2 (`I` = `$FE`, `$8080` to `$D9D2`; the tune's `$FDFD` to `$F961`), the handler's cost by engines (2 555 to 12 603 T), the menu inside the tune's interrupt, the pass and its 7-frame wait on `$D6BC`, overruns with two players, the heaviest pass (91.3 % at `c1` 15 412; 89.7 % in the replay), a pass against the beam (a tear), the end tests and the timers |
| [5. Controls](05-controls.md) | the control methods (player 1 keyboard or Kempston, player 2 keyboard or Sinclair) and what an emulator must decode; ScanKeys in the interrupt and the key latch (only the scans after PassP1's ClearKeys count: 3 in a light one-player pass); the menu (SPACE, 0 or fire selects, not ENTER); CHOOSE CONTROL and the one-player SINCLAIR line that does nothing; redefining the keys; throttle, brake and the turn round; wheel up, wheel down, the jump and getting on; the walk back; two players on one pass; AbortKey on key 1, which no path reaches |
| [6. Rendering](06-rendering.md) | one sprite bank with 4-byte headers and the shift kept in the sprite (RotateSpriteLeft / Right); the 22 x 80 buffer at `$F03C` cleared by 880 pushes; the draw modes; the trail drawn from lists A and B with clip codes and a quarter-speed parallax; the order of a picture (DeferredB, the ATV, DeferredA); the measuring call that rotates sprites for nothing (15-29 % of a pass); the ATV and the rider, mirrored; CopyLines racing the beam; the split screen |
| [7. Objects](07-objects.md) | the trail record and its two lists, the 6-byte item and its flags (bit 0 the menu bank, the deferred draw modes, animation records), WalkList and PlaceItem with the five clip codes, a stretch of trail 1 decoded from the buffer, the draw order that decides what the wheels touch, the two scrolls, AnimObject's three triangle motions and the 29-entry SeenIds, the 50-byte player record |
| [8. HUD and text](08-hud-and-text.md) | Print and the font; the texts and their widths; the HUD drawn field by field; the clock in passes and TIME OUT on its hundreds; the score by XOR; the SPEED and FUEL bars; PrintShadow's cleared band; the finish, LAP TIME, EXTENDED PLAY and the bonus's lost byte; the trail intro in big print; the high score table and the name entry on a letter grid |
| [9. Sound](09-sound.md) | the beeper only: Click, Tone, Noise and the stuck Random; the engine (from the interrupt every frame and once from Update); the landing thud, the bonus tone; the tune data and the two-channel tune player on its own interrupt; the two tunes; the cost per pass |
| [10. Gameplay logic](10-gameplay-logic.md) | the rules as one call chain per pass; the ground read from the buffer's pixels; rise, fall and landing; the jump; the nose, slopes and wheelies; the three crash tests (the step, the nose test with its unsigned wrap, CrashIfAir) and the crash by speed; the 24-pass tumble; the throw, the rider on foot and MountCheck; the speed's ledger; fuel; the score, the clock, the finish and the bonus; WaitFrames, TIME OUT and the drop-out; the endless second round; the course of the `trails` bot game, the techniques and the quirks |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |

## Terms

Each term once, here; the documents use these names.

| Term | Meaning |
| --- | --- |
| AtvFrame | `$D775`, the ATV's sprite and angle: `$38` level, `$3A-$44` nose up, `$46-$4C` nose down, `$5C` turning round, `$7D-$87` tumbling; `$44` with Up held throws the rider off (ThrowOff) |
| BigPrint | `$78E3`, draw mode 8: a sprite scaled by BigScaleX x BigScaleY, ORed or cleared (the trail intro) |
| bonus | Bonus `$D79B`: ((MaxTime - lap) / 2 + 1, low byte only) x trail + 1, counted into the score at the trail's end a point and a tone at a time; a point shows as 10 |
| BufferP1 / BufferP2 | `$F03C` / `$F71C`, 22 x 80 bytes each, one per player's window; the picture is drawn there and copied to the screen (CopyLines) |
| clock | Clock `$D6C9-$D6CB`, three ASCII digits; ClockTick adds a tenth per pass, not per real tenth of a second |
| Controls1 / Controls2 | `$8113` / `$8114`, a player's control bits for the pass: 4 left, 3 right, 2 up, 1 down, 0 jump |
| crash tests | the three ways into Crash `$E94C`: the step test, the nose test and CrashIfAir; Crash takes 2 off the speed first, then under 10 stops, 10-14 stops and throws, 15 and up tumbles and throws |
| DeferredA / DeferredB | the deferred draws: DeferredB (`$81E9`, item flags bit 1) is drawn before the ATV, DeferredA (`$8146`, bit 2) after it, in front |
| draw mode | the routine a sprite draw jumps to: DrawModes `$69F7` for the screen (none, copy, OR, XOR, ...), ListModes `$836D` for the buffer (OR, OR clipped, masked, masked mirrored, ...) |
| EXTENDED PLAY | the text at the finish: the rider goes on to the next trail |
| FrameCount | `$D6BC`, frames since the pass began, counted by the interrupt; `$FF` in the front end, where the interrupt reads the controls instead |
| FuelBar / SpeedBarLen | `$D77F` / `$D77E`, the end x of the FUEL and SPEED bars (not the fuel or the speed) |
| GroundY | `$D6C4`, the higher of the ground lines under the two rear wheels, found in the buffer's pixels; `$D6C7` is the ground under the nose |
| Im2Jump / TuneVector | `$8080` / `$FDFD`, the `JP` the game's and the tune player's IM 2 tables point at |
| in-place shift | RotateSpriteLeft / RotateSpriteRight rewrite a sprite of the bank one bit a call when its pixel offset changes; the costliest work of a pass |
| item | 6 bytes of a trail list: the distance (a word), y, the advance, the sprite, the flags (bit 0 the menu bank, bits 1-3 the deferred and masked draws; bits 4-7 set: an animation record's address) |
| KeyStates | `$808B`, 40 bytes, 1 for a key held, filled by ScanKeys in the interrupt; a key held at any scan after PassP1's ClearKeys counts (3 in a light one-player pass, fewer in a heavy one) |
| list A / list B | a trail's two item lists: A the ground and what the wheels meet (TrackPos, speed x 128 a pass), B the scenery (Scenery `$D78E`, speed x 32, a quarter), never solid |
| MaxTime | `$D6CC`, the trail's limit; TIME OUT when the clock's first digit reaches its first digit |
| measuring call | PlaceItem's first draw in mode none, to learn an item's width; it shifts the sprite all the same |
| MountCheck | `$E46E`, the rider gets on only falling onto the seat: x AtvX - 12 to + 17, 4-24 above |
| nose test | `$E76D`: the ground under the nose less GroundY, as an unsigned byte, `$15` or more crashes: a wall 21 or more high, or by the wrap any nose ground lower than the wheels' |
| pass | one step of the game for both players (Pass `$D851` to the next): the controls, a clock tick, each riding player's update and copy, then the wait until FrameCount reaches 7; 7 frames while the work fits |
| Record | a player's 50-byte state: RecordP1 `$D70E`, RecordP2 `$D740`, copied to Record `$D772` for the pass |
| Riding / Finished | `$D6BE` / `$D7A5`, bit 0 player 1, bit 1 player 2; the trail ends when both speeds are 0 and Finished covers Riding |
| second round | SecondRound `$D7A6`: after trail 6, trails 1-6 again with 30 as every maximum |
| SeenIds | `$8124`, the ids of the animation records already moved this pass; 29 entries at most, the 30th new id hangs the game (ListOverflow, blue border) |
| step test | the step test in AtvPhysics `$E676` (`$E6E6`): a crash when GroundY - AtvHeight less the last pass's rise is 7 or more |
| stuck finish | a finished rider holding the throttle stays at speed 1 (SlowDown -2, Accelerate +1) and the trail waits for TIME OUT |
| ThrowSpeed | `$D799`, the thrown rider's vertical speed, `$F8` less speed / 8 |
| TrackPos | `$D78A`, the whole part of a player's 24-bit Distance `$D789-$D78B`; the finish is TrackPos reaching FinishDistance `$D6C0`, the trail's length less `$48` |
| TumbleCount | `$D797`, 1-24 through a tumble |
| TunePlayerCopy | `$5B00`, GameEntry's copy of the tune player, copied back to `$F850` before each tune |
| VSpeed | `$D773`, the vertical state: negative rising, 0 grounded, 1-5 falling (FallSteps `$E319`: 0, 1, 2, 4, 6, 6 lines a pass) |
| WalkList / PlaceItem | `$8DA3` / `$8E3C`: find a list's items in the 176-pixel window and draw them (clip codes 0-4) |
