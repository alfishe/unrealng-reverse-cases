# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: Tape BASIC and loader, The 128K setup and the explorer selector
(RAM 1), The AY music player (RAM 6), The explorer data sets, The loading screen) follow the game, each under its
own heading with its modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`sprites`](11-data-reference.md#sprites) | `$7200`-`$8CFF` | 0 of 3 |
| [`entry`](#entry) | `$8D00`-`$9017` | 3 of 6 |
| [`mainloop`](#mainloop) | `$9018`-`$90C5` | 3 of 3 |
| [`util`](#util) | `$90C6`-`$9169`, `$9390`-`$93AE` | 5 of 6 |
| [`ending`](#ending) | `$916A`-`$917B`, `$B0B6`-`$B164` | 2 of 2 |
| [`rooms`](#rooms) | `$917C`-`$935C`, `$9855`-`$9B21`, `$C600`-`$DEFF`, `$F800`-`$F9FF` | 20 of 30 |
| [`countdown`](#countdown) | `$935D`-`$938F` | 2 of 2 |
| [`menu`](#menu) | `$93AF`-`$9490`, `$94AF`-`$9854`, `$9F27`-`$9F6A` | 11 of 16 |
| [`interrupt`](#interrupt) | `$9491`-`$94AE` | 1 of 1 |
| [`render`](#render) | `$9B22`-`$9E5C`, `$E000`-`$EFFF`, `$FE00`-`$FFFF` | 27 of 33 |
| [`panel`](#panel) | `$9E5D`-`$9F26`, `$9F6B`-`$A0FD` | 11 of 12 |
| [`player`](#player) | `$A0FE`-`$A6CB`, `$AF09`-`$AF3A`, `$B87C`-`$B931` | 27 of 35 |
| [`status`](#status) | `$A6CC`-`$AF08` | 50 of 65 |
| [`roomscripts`](#roomscripts) | `$AF3B`-`$B0B5`, `$B165`-`$B87B`, `$BA97`-`$BB58`, `$BC73`-`$BCDD` | 36 of 48 |
| [`objects`](#objects) | `$B932`-`$BA96`, `$BB59`-`$BC72` | 10 of 12 |
| [`score`](#score) | `$BCDE`-`$BE23` | 8 of 9 |
| [`creatures`](#creatures) | `$BE24`-`$C4B1` | 20 of 24 |
| [`sound`](#sound) | `$C4B2`-`$C57F` | 10 of 12 |
| [`tiles`](11-data-reference.md#tiles) | `$C580`-`$C5FF`, `$DF00`-`$DFFF`, `$F000`-`$F7FF`, `$FA00`-`$FDFF` | 0 of 4 |

## entry

`src/game/entry.asm`

### `GameEntry` (`$8F00`)

**Game entry: the IM 2 table and vector, the stack, the 128K page, the life-loss patch**

The last tape block's loader jumps here (`JP $8F00` of the BASIC loader's code, c1 frame 21597). With interrupts off it writes `$10` to Last7FFD `$5FE5` (RAM 0 at `$C000`, ROM 1: the value the IM 2 handler `$9491` pages back after the music), fills the IM 2 table `$8E00-$8F00` (257 bytes) with `$5F`, puts `JP $9491` at `$5F5F` (the vector every interrupt reaches with I = `$8E`), sets SP to `$5E00`, I to `$8E`, IM 2 and EI.

Then: `$5FFF` = 1 (the selector, run again from NewGame `$8F47`, reads it: the game has been loaded), border 0, `$8D00` = 0, the high score `$5B78-$5B7B` = 0 (it is cleared only here, so it survives from game to game), and the life-loss patch: the opcode at `$A9FD` (the `DEC (HL)` on Lives in `$A9EE`) is written `$35` (`DEC (HL)`) or, when `$5B03` is not 0, `$B7` (`OR A`): lives are never lost. The BASIC loader sets `$5B03` to 1 when `$8000` held `$C9` before the load (doc 3, 3.2): a cheat hook for a front end that pokes `$8000`. In c1 `$5B03` is 0 (`$8F41` not executed in any recording).

Falls into NewGame `$8F47`.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 518,113 t-states own (0.03 %) |
| Calls | `RoomEffects`, `CountDown`, `DeviceMenu`, `SetUpRoom`, `SaveRespawnPoint`, `RenderPass`, `DrawPortrait`, `DrawSpareLives`, `DrawBearers`, `HeroUpdate`, `ResetItems`, `ItemsPass`, `AddScore`, `NewHiScore`, `RunCreatures` |
| Reads | `$5000`-`$57FF` (screen); `$5A00`-`$5B66` (screen); `$5B7C`-`$5B9E` (system); `$5BFA`-`$5C8C` (system); `$5FFE` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); 3 more ranges |
| Writes | `$5000`-`$57FF` (screen); `$5A00`-`$5BA0` (screen); `$5BFF`-`$5C8D` (system); `$5F5F`-`$5F61` (system); `$5FE5` (system); `$5FFF` (system); 6 more ranges |
| Ports in | `$FBFE`, `$FEFE` |
| Ports out | `$00FE`, `$7FFD` |

### `NewGame` (`$8F47`)

**Start a game: the device menu, the explorer selector, the set-up of a new game**

Reached from GameEntry `$8F00` (falls in) and from EndGame `$906D` (`JP $8F47`) after every game: c1 2 runs, explorers 5, gameover 1, rzx50000 1.

1. DeviceMenu `$93AF` until 0 is pressed.

2. On a 128K (Has128K `$5FFE` not 0): pages RAM 1 in (`$7FFD` = `$11`, kept in Last7FFD `$5FE5`) and calls `$C000` with BC = `$C000`: the explorer selector, which the 128K setup copied to RAM 1 and relocated there; it copies the chosen explorer's data set to `$6000-$71FF` and returns; then RAM 0 is paged back (`$10`). On a 48K the explorer was chosen during the load (the selector runs in place before the last block), so the same explorer plays every game.

3. The set-up (InitGame `$8F69`): clears `$5B04-$5B66` (the hero and party records and other state, 99 bytes); fills BearerLoads `$5B7C-$5B96` (27 bytes) with `$FF` (free); `$B932` clears the creature table's active bits and bit 7 of `$B9D9` is set again; copies the saved panel back to the screen (`$E000` -> `$5000`, 2048 bytes; `$E800` -> `$5A00`, 256 attributes: EndGame `$906D` saved it there, because play uses `$E000-$EFFF` as the background copy of the play window); the tile bitmap pointer `$5B72` = `$F000`; `$5C3C`, `$A6FD`, `$A700`, `$5B98`, `$5B9B` = `$FF`, `$A6F5` = 7, `$5B06` = 0; clears `$5BFA-$5C8D` (148 bytes: the countdown, GameOver, Room, PassCount, RoomEvent and the rest); `$BCF2` with DE = 0; the object at `$5C25-$5C27` = X `$70`, Y `$60`, room `$0F`; Room `$5C01` = `$14` and the room set-up `$9855`; `$9EBD`; Lives `$5B97` = 4 and `$9E96` (the lives in the panel); the hero at X `$0A` (`$5B04`), Y `$60` (`$5B05`); the lift (`$AF81`) in room `$2B` (`$5B9E`) at Y `$30` (`$5B9F`); the countdown 30 days 23:59 (`$5BFB` days = `$1E`, `$5BFC` hours = `$17`, `$5BFD` minutes = `$3B`); `$9AA1` copies the start into the respawn state `$5C2B-$5C33`; `$9E5D`. Falls into MainLoop `$9018`.

Witness: L1 9 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/gameover` 1, `stage1/rzx/r50000` 1) |
| Called from | `MainLoop` (tail) |
| Calls | `RoomEffects`, `CountDown`, `DeviceMenu`, `SetUpRoom`, `SaveRespawnPoint`, `RenderPass`, `DrawPortrait`, `DrawSpareLives`, `DrawBearers`, `HeroUpdate`, `ResetItems`, `ItemsPass`, `AddScore`, `NewHiScore`, `RunCreatures` |
| Reads | `$5000`-`$57FF` (screen); `$5A00`-`$5B66` (screen); `$5B7C`-`$5B9E` (system); `$5BFA`-`$5C8C` (system); `$5FFE` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); 3 more ranges |
| Writes | `$5000`-`$57FF` (screen); `$5A00`-`$5BA0` (screen); `$5BFA`-`$5C8D` (system); `$5FE5` (system); `$A6F5`-`$A700` (`ThinkHints+15`); `$B9D9` (`CrystalPlace`); 1 more ranges |
| Ports in | `$FBFE`, `$FEFE` |
| Ports out | `$7FFD` |

### `RunSelector` (`$8F4A`)

**The explorer selector on a 128K, then the new game (NewGame continued)**

The return point of NewGame's `CALL $93AF`: an entry of its own only because the explorers recording starts inside DeviceMenu, so its L1 sees the RET land here. Step 2 and 3 of NewGame `$8F47`: on a 128K the selector at `$C000` in RAM 1, then InitGame `$8F69`. Falls into MainLoop `$9018`.

Witness: L1 8 (c1, explorers, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r00000`) |
| Calls | `RoomEffects`, `CountDown`, `SetUpRoom`, `SaveRespawnPoint`, `RenderPass`, `DrawPortrait`, `DrawSpareLives`, `DrawBearers`, `HeroUpdate`, `ResetItems`, `ItemsPass`, `AddScore`, `RunCreatures` |
| Reads | `$5B04`-`$5B66` (system); `$5B7C`-`$5B9E` (system); `$5BFA`-`$5C8C` (system); `$5FFE` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B9D9` (`CrystalPlace`); 1 more ranges |
| Writes | `$5000`-`$57FF` (screen); `$5A00`-`$5BA0` (screen); `$5BFA`-`$5C8D` (system); `$5FE5` (system); `$A6F5`-`$A700` (`ThinkHints+15`); `$B9D9` (`CrystalPlace`) |
| Ports in | `$FBFE` |
| Ports out | `$7FFD` |

## mainloop

`src/game/mainloop.asm`

### `MainLoop` (`$9018`)

**The main loop: one pass of the game, no frame sync**

One pass: `$5BA0` = 1 (`$AF81` clears it on the lift); IX = the hero record `$5B04`; when Room `$5C01` equals the lift's room `$5B9E`, `$AF81` (the lift); `$A3E1` (the hero: input, movement, the RoomEvent handlers); when LifeLost `$5C2A` is set, Respawn `$9090`; else `$B9FA` (the items), RoomEffects `$91C0`, CountDown `$935D` (one minute a pass), `$BE98` (the creatures), `$9B22` (the sprites; it calls ShowCapsules `$92BD`); GameOver `$5BFF` set ends the game (EndGame `$906D`); PassCount `$5C02` + 1.

The keys at the end of a pass: Q held with CAPS SHIFT ends the game (the abort: c1 and explorers, 6 runs of `$9059`); Q held with A held freezes the game until A is let go (`$9062`, not executed in any recording); Q alone does nothing.

There is no HALT: a pass takes as long as its work. In the rzx segments the day rolls over (`$936B`, 13 runs, one in every segment of about 4000 frames) every 1440 passes, so a pass is about 2.8 frames (WALKTHROUGH 1: 2.4 to 3.3).

Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/gameover`, `stage1/rzx/r14000`, `stage1/rzx/r32000` and 28 more) |
| Calls | `NewGame` (tail), `RoomEffects`, `CountDown`, `SetUpRoom`, `RenderPass`, `HeroUpdate`, `LiftPlatform`, `ItemsPass`, `NewHiScore`, `RunCreatures` |
| Reads | `$5000`-`$57FF` (screen); `$5A00`-`$5AFF` (screen); `$5B9E` (system); `$5BFF`-`$5C02` (system); `$5C2A`-`$5C33` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); 1 more ranges |
| Writes | `$5B04`-`$5B07` (system); `$5B9B`-`$5BA0` (system); `$5C01`-`$5C07` (system); `$5C2A` (system); `$E000`-`$E8FF` (`BackBuffer`, `SavedPanelAttrs`) |
| Ports in | `$FBFE` |

### `EndGame` (`$906D`)

**End a game: the high score, the panel saved, the base tile set back, the menu**

Reached from MainLoop `$9018` when GameOver `$5BFF` is set (gameover frame 1962 after the space scene; rzx50000 frame 732 after the ending) or on CAPS SHIFT + Q (c1, explorers).

`$BD50` keeps the score as the high score when it is higher; then the panel (the screen's bottom third `$5000-$57FF` and its attributes `$5A00-$5AFF`) is saved to `$E000-$E7FF` and `$E800-$E8FF`, where DeviceMenu `$93AF` takes its frame pieces from and InitGame `$8F69` restores it; when the alternate tile set is in (AltTileset `$918C` not 0), SwapTileset `$918D` puts the base set back (not executed in any recording: every game ended in a base-set room); `JP $8F47`.

Witness: L1 8 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Respawn` (`$9090`)

**Restart after a lost life from the respawn state**

Reached from MainLoop `$9018` when LifeLost `$5C2A` is set (`$A9EE` sets it to `$32` when EventTimer `$5C07` reaches 50 and takes a life). gameover frame 1509 (the last life; `$A9EE` went on to LoseGame `$9372`, which put room `$28` and RoomEvent `$1D` in the respawn state, so this respawn starts the space scene), rzx 4 runs.

Clears LifeLost and `$5C05`; copies the respawn state back: RoomEvent `$5C06` from `$5C2B`, EventTimer `$5C07` from `$5C2C`, the hero record `$5B04-$5B07` from `$5C2E-$5C31`, Room `$5C01` from `$5C2D`, the lift `$5B9E-$5B9F` from `$5C32-$5C33` (`$9AA1` writes the state on every room entry); the room set-up `$9855`; `$5B9B` = `$FE`; back to MainLoop.

Witness: L1 5 (gameover, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

## util

`src/game/util.asm`

### `PrintChar` (`$90C6`)

**Print a character of the ROM font at a screen address**

A = the character code, HL = the screen address (top pixel row of a cell). Copies the 8 bytes of the ROM font (`$3C00` + 8A: `$3D00` is the space) down the cell (INC D). Out: HL + 1 (the next column); BC, DE kept.

Callers: PrintString `$94F9` (the menu), `$BD75`/`$BD78` (the score and high score), PrintDigitAt `$9136`.

Witness: L1 1933 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 371 calls, 172,131 t-states own (0.01 %) |
| Runs (the other recordings) | 1,562 calls (`stage1/explorers` 946, `stage1/gameover` 198, `stage1/rzx/r50000` 193 and 17 more) |
| Called from | `PrintString`, `PrintScore`, `PrintNumber` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$4808`-`$57B6` (screen) |

### `PrintByte` (`$90E1`)

**Print A in decimal, left-aligned in three columns**

A = 0-255, DE = the screen address. Builds three ASCII digits at `$5BA6-$5BA8` (hundreds, tens, units, by repeated subtraction), skips the leading zeros (the units digit always prints), prints the digits through PrintDigitAt `$9136` and then a space for each skipped zero, so the field is always three cells.

The only callers are at `$A7F4`, `$A7FD` and `$A806` (the countdown's days, hours and minutes after a text printed by PrintString `$94F9`): not executed in any recording (c1, explorers, gameover, rzx x31); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrintDigitAt` (`$9136`)

**Print the character at (HL) at screen DE**

HL = the character, DE = the screen address; PrintChar `$90C6`; HL and DE kept. Called three times by PrintByte `$90E1`; not executed in any recording; known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Near` (`$9140`)

**Are two objects within 16 (or 8) pixels on both axes?**

IX = the first object (X at +0, Y at +1, the sprite frame at +2), IY = the second (X, Y). The distance is 16, or 8 when IX's frame is `$5C-$5F` (`$914E`: rzx only, 3169 runs). Out: carry set when |X1 - X2| and |Y1 - Y2| are both below it. BC kept.

Callers: `$B44A`, `$B5E1`, `$B74D`/`$B765`, `$BB70` (52660 calls), `$C0E0`: the touch test of the hero against items and creatures. The SkoolKit title ("classify object type") names only its first lines.

Witness: L1 67291 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,322 calls, 549,334 t-states own (0.03 %) |
| Runs (the other recordings) | 63,969 calls (`stage1/explorers` 11,312, `stage1/rzx/r32000` 2,443, `stage1/rzx/r24000` 2,143 and 30 more) |
| Called from | `BasketScript`, `ProfessorScript`, `LeverRoom40`, `LeverRoom3E`, `LeverScript`, `PickUpItem`, `RiserCreature`, `AnimateCreature`, `HitExplorer` |
| Reads | `$5B04`-`$5B15` (system); `$5B80`-`$5B92` (system); `$5C0E`-`$5C14` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `Random` (`$9390`)

**A pseudo-random byte from R and a 16-bit linear congruential state**

RandomState `$93AD` = RandomState * 257 + 41 (mod 65536: HL + L * 256 + `$29`); then with HL = `$8F47` + the state's low byte, A = (R XOR H) + L. `$8F47` is only an odd constant: nothing is read there (the SkoolKit "stride table" is not one). Out: A; HL and DE kept, flags changed.

The only caller is `$BFA9` in `$BFA0` (382 calls over all builds).

Witness: L1 382 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 22 calls, 4,021 t-states own (0.00 %) |
| Runs (the other recordings) | 360 calls (`stage1/explorers` 76, `stage1/rzx/r32000` 24, `stage1/rzx/r22000` 23 and 22 more) |
| Called from | `CreatureTimer` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$93AD`-`$93AE` (`RandomState`) |
| Writes | `$93AD`-`$93AE` (`RandomState`) |

## ending

`src/game/ending.asm`

### `InvertPlayWindow` (`$916A`)

**Swap ink and paper in the play window's attributes**

XORs every attribute of `$5800-$59FF` (character rows 0-15, the play window) with `$3F`: ink 7-ink, paper 7-paper, BRIGHT and FLASH kept. Called twice it restores the screen.

The only callers are `JP $916A` at `$B1E8` and `CALL $916A` at `$B1EE`, in the ending's code after `$B0B6`: not executed in any recording (rzx50000 runs the ending from `$B0B6` to `$B169`); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SpaceScene` (`$B0B6`)

**The room handler of room `$28`: the asteroid falls on the Earth; deflected (the ending) or not (the loss) (SK "warp fanfare", renamed)**

IY = object 1 (`$5B08`). RoomStep `$5C41` steps: 0 sets the asteroid (object 1 at `$A2`, `$04`, frame `$75`), the Earth at the bottom (objects 2 and 3 at Y `$68`, frames `$72` and `$71`) and, when `$5BFE` is set (the deflector), object 4 at `$89`, `$5C`. 1: the asteroid moves 1 left, 4 down a pass to Y `$54`. With the deflector: object 4's frame + 1, sound 2, step 3: the asteroid goes back 4 left, 1 up a pass and vanishes at X 4. Without: the asteroid hidden, object 2 frame `$76`, then `$77` (the strike), sound 1. Then the step counts to `$80` and GameOver `$5BFF` = 1.

Evidence: gameover frames 1516-1959 (no deflector, the strike, after the last life); rzx50000 frames 194-729 (the deflector, GameOver at 729).

Witness: L1 327 (gameover, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r50000`, `stage1/gameover`) |
| Called from | `JumpThroughWord` |
| Calls | `PlaySound` (tail) |
| Reads | `$5B08`-`$5B16` (system); `$5BFE` (system); `$5C41` (system) |
| Writes | `$5B08`-`$5B17` (system); `$5BFF` (system); `$5C41` (system) |

## rooms

`src/game/rooms.asm`

### `ClearPartySlots` (`$917C`)

**Party slots 1-4: frame `$7F`, flags 0**

Writes `$007F` to the words `$5B0A`, `$5B0E`, `$5B12`, `$5B16`: bytes +2 (the sprite frame) and +3 of the four 4-byte records after the hero's (`$5B04`). Frame `$7F` is the blank sprite: `$6000 + $7F * 72` = `$83B8`, 72 zero bytes in the image. Called by the room set-up at `$990B` on every room entry (106 runs over all builds).

Witness: L1 106 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 109 t-states own (0.00 %) |
| Runs (the other recordings) | 105 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r14500` 6, `stage1/rzx/r06000` 6 and 27 more) |
| Called from | `SetUpRoomTiles` |
| Writes | `$5B0A`-`$5B17` (system) |

### `SwapTileset` (`$918D`)

**Exchange the base and the alternate tile set**

Swaps the 1024 bytes of `$F400-$F7FF` (the bitmaps of tiles `$80-$FF`) with `$FA00-$FDFF`, and the 128 attributes of those tiles `$DF80-$DFFF` with `$C580-$C5FF`; then AltTileset `$918C` = NOT its old value. A swap, not a copy: the set that goes out is kept for the way back.

Callers: the room set-up at `$9890`/`$9899` (6 runs: rzx18000 frame 1417, rzx20000 858, rzx26000 463 and 1075, rzx34000 1481, rzx50000 183), EndGame at `$908A`.

Witness: L1 6 (rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rzx/r26000` 2, `stage1/rzx/r50000` 1, `stage1/rzx/r34000` 1 and 2 more) |
| Called from | `SetUpRoomTiles` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$C580`-`$C5FF` (`AltTileAttrs`); `$DF80`-`$DFFF` (`TileAttrs+128`); `$F400`-`$F7FF` (`TilePixels+1024`); `$FA00`-`$FDFF` (`AltTilePixels`) |
| Writes | `$918C` (`AltTileset`); `$C580`-`$C5FF` (`AltTileAttrs`); `$DF80`-`$DFFF` (`TileAttrs+128`); `$F400`-`$F7FF` (`TilePixels+1024`); `$FA00`-`$FDFF` (`AltTilePixels`) |

### `RoomEffects` (`$91C0`)

**Animate the flames (base set), the beams and the capsules (alternate set)**

Called once a pass by MainLoop `$9018`. The lists are built by the room set-up `$9880` with `$9A8C` (a CPIR over the tile map `$F800`): `$9AD5` holds the map addresses of tile `$B5` in a base-set room, of tile `$DD` in an alternate-set room; `$9AE5` those of tile `$8C` (alternate set only); a 0 word ends a list.

Base set (AltTileset `$918C` = 0): for the first two entries of `$9AD5` (B = 2) the 8-byte frame PassCount AND 3 of FlameFrames `$933D` is copied into tile `$B5`'s bitmap (`$F5A8`), the cell is drawn again on the screen and in the background copy (`$9A52`), and its attribute (map address + `$6000` = `$5800 + offset`) gets BRIGHT flipped at random (bit 0 of R). The rooms with tile `$B5` (from the room data): `$1C`, `$21`, `$29`, `$2D`, `$2E`, `$2F`, `$33`, `$35`, `$36`, `$3F`, `$40`, `$41`, `$42`. gameover (room `$1C`) and 11 rzx segments run it (5256 runs of `$91D6`).

Alternate set (Beams `$9208`): `$9AD5` is read as pairs of tile `$DD` cells on one row: the two ends of an electric beam. Pixel rows 6 and 7 of each cell between them get random bytes (R rotated, XOR PassCount); the beam is redrawn every pass (rzx26000-rzx42000, 9538 runs of `$9266`). The hero is hit when his X is from the left end's X to below the right end's X minus 12 and |Y + 6 - the row's Y| < 12, while RoomEvent `$5C06` is below 4: RoomEvent = `$18` through `$AE85` (CreatureDeath `$A89E` in the table at `$A72E`). The hit (`$9260`) is not executed in any recording. A list that ends after an odd entry returns without the capsules. Rooms with tile `$DD`: `$20`, `$38` (two beams), `$39`, `$3A`, `$3C`, `$43`. rzx42000 frame 500 shows the beam of room `$3A` across row 13.

Then the capsules (Capsules `$9282`): the 16-byte frame of CapsuleFrames `$92FD` (PassCount AND 3, run backwards when bit 2 of PassCount is clear: 3 2 1 0 0 1 2 3) is copied into tiles `$8C`-`$8D` (`$F460`), and each cell of `$9AE5` gets tile `$8C` and the next cell `$8D` again in the map and the background copy (`$9A4D`); ShowCapsules `$92BD` copies them to the screen later in the pass. Rooms with tile `$8C`: `$12`, `$20`, `$2B`, `$2C`, `$38`, `$3A`, `$3B` (six: the lab, rzx46000 frame 500), `$3C`, `$44`.

Witness: L1 26513 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 347,643 t-states own (0.02 %) |
| Runs (the other recordings) | 25,243 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop` |
| Calls | `Capsules` (tail), `MapToPixels`, `SetTileBuffer`, `SetTile` |
| Reads | `$5808`-`$5810` (screen); `$5825`-`$583C` (screen); `$588C`-`$5898` (screen); `$58B8`-`$58BC` (screen); `$59B4` (screen); `$5B04`-`$5B05` (system); 5 more ranges |
| Writes | `$468D`-`$468E` (screen); `$46C5`-`$46D2` (screen); `$478D`-`$478E` (screen); `$47C5`-`$47D2` (screen); `$4E46`-`$4E4D` (screen); `$4EA9`-`$4EB6` (screen); 9 more ranges |

### `Capsules` (`$9282`)

**Animate the capsules, tiles `$8C-$8D` (RoomEffects continued)**

Reached only by `JP Z,$9282` at `$9212` when Beams `$9208` meets the 0 word that ends the list `$9AD5` (an entry of the cut because it is a jump target from another routine's L1 block). Described under RoomEffects `$91C0`: the frame of CapsuleFrames `$92FD` (3 2 1 0 0 1 2 3 over PassCount) into the bitmaps of tiles `$8C`-`$8D` (`$F460`), then tile `$8C` and `$8D` at each map address of `$9AE5` and the next, in the map and the background copy (`$9A4D`).

Witness: L1 5581 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,440 calls (`stage1/rzx/r44000` 660, `stage1/rzx/r46000` 631, `stage1/rzx/r48000` 629 and 3 more) |
| Called from | `RoomEffects` (tail) |
| Calls | `SetTileBuffer` |
| Reads | `$5C02` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$92FD`-`$933C` (`CapsuleFrames`); `$9AE5`-`$9AF2` (`EffectCellsB`) |
| Writes | `$F460`-`$F46F` (`TilePixels+1120`) |

### `ShowCapsules` (`$92BD`)

**Copy the capsule cells from the background copy to the screen**

Called by `$9B22` at `$9BE4` every pass. Returns at once in a base-set room (AltTileset `$918C` = 0). Else, for each map address in the list `$9AE5`, copies the cell and the one to its right from the background copy (`$E000`) to the screen through CopyBackCell `$92D6` (33546 calls, rzx18000-rzx50000).

Witness: L1 26510 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 37,002 t-states own (0.00 %) |
| Runs (the other recordings) | 25,240 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `RenderPass` |
| Calls | `CopyBackCell` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$9AE5`-`$9AF2` (`EffectCellsB`) |

### `CopyBackCell` (`$92D6`)

**Copy one cell of the play window from the background copy to the screen**

HL = a tile map address (`$F800-$F9FF`). The cell's screen address is (H AND 3) * 8 + `$40` : L, its background copy the same OR `$E0`; 8 bytes down the cell. HL and DE kept. The SkoolKit note ("menu border strip") does not fit: the only caller is ShowCapsules `$92BD`.

Witness: L1 33546 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33,546 calls (`stage1/rzx/r44000` 7,920, `stage1/rzx/r46000` 7,572, `stage1/rzx/r48000` 7,548 and 9 more) |
| Called from | `ShowCapsules` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E0B1`-`$EABA` (`BackBuffer+177`, `SavedPanelAttrs`, `BackBufferLeftover`); `$EB45`-`$EBBA` (`BackBufferLeftover+581`); `$EC45`-`$ECBA` (`BackBufferLeftover+837`); `$ED45`-`$EDBA` (`BackBufferLeftover+1093`); `$EE45`-`$EEBA` (`BackBufferLeftover+1349`); 1 more ranges |
| Writes | `$40B1`-`$4ABA` (screen); `$4B45`-`$4BBA` (screen); `$4C45`-`$4CBA` (screen); `$4D45`-`$4DBA` (screen); `$4E45`-`$4EBA` (screen); `$4F45`-`$4FBA` (screen) |

### `MapToPixels` (`$92F0`)

**A tile map address as pixel coordinates**

HL = a tile map address (`$F800` + row * 32 + column). Out: H = row * 8 (the Y), L = column * 8 (the X), the units of the hero's X and Y at `$5B04`/`$5B05`. Called twice by Beams `$9208` (3646 calls). The SkoolKit title ("attribute address") does not fit what it returns.

Witness: L1 3646 (rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,646 calls (`stage1/rzx/r40000` 1,008, `stage1/rzx/r36000` 812, `stage1/rzx/r42000` 724 and 3 more) |
| Called from | `RoomEffects` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `SetUpRoom` (`$9855`)

**Set up room A: the room-entry specials, the respawn point, then the room proper (SK)**

A = the new room (level * 12 + column). Called right after every change of Room `$5C01`: GameInit at `$8FE5`, the respawn `$9090` at `$90BB`, the game-over path `$9372` at `$937C`, the room exits `$A640`/`$A671`/`$A69B`/`$A6AE` (tail jumps at `$A669`, `$A691`, `$A6AB`, `$A6BF`), `$A8EA` at `$A94E` and `$B5DD` at `$B6F3`.

First CALL `$BE42` (the room's creature decode, A kept). Room `$2C` sets the word `$5C34` to `$FF02`: `$5C34` is the pair C = dx, B = dy that `$A34B` moves the hero by (each kept in -3..3 there), so the room starts the hero with dx = +2, dy = -1; r18000 is the only build that entered room `$2C`. Then the room is looked up in CheckpointRooms `$9AF5`: when it is listed and FallCount `$5C05` is 0 (the hero is not falling), SaveRespawnPoint `$9AA1` records this room as the place a lost life restarts. Last the per-room set-up SetUpRoomTiles `$9880`, with IX preserved around it.

Evidence: 105 entries over all 31 play builds, SaveRespawnPoint called from `$9874` 71 times (27 builds), so 34 room entries were in rooms not listed or while falling.

Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 501 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r40000` 6, `stage1/rzx/r06000` 6 and 27 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop`, `LoseGame`, `HeroUpdate` (tail), `ExitLeft` (tail), `ExitRight` (tail), `ExitUp` (tail), `ExitDown` (tail), `Teleport` (tail), `ProfessorScript` |
| Calls | `SetUpRoomTiles`, `SaveRespawnPoint`, `DecodeRoomCreatures` |
| Reads | `$5C05` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$9AF5`-`$9B21` (`CheckpointRooms`) |
| Writes | `$5C34`-`$5C35` (system) |

### `SetUpRoomTiles` (`$9880`)

**Per-room set-up: the tile set, the tile map, the effect cells, the room's counters, the screen**

A = the room. The tile set: when the room is in AltTilesetRooms `$9AC6` and the alternate set is not loaded (flag `$918C` = 0), or not in it and the set is loaded, `$918D` swaps the tiles `$80-$FF` (`$F400` with `$FA00`, their attributes `$DF80` with `$C580`). Witness: `$918D` called 6 times in 5 builds over 105 set-ups.

Then WellCell `$5BA2` = 0, BuildTileMap `$9914` expands the room into the tile map `$F800`, the two effect lists `$9AD5-$9AF4` are cleared (32 bytes) and filled by FindTileCells `$9A8C`: EffectCellsA `$9AD5` with every cell of tile `$B5` (the base set) or `$DD` (the alternate set), and with the alternate set EffectCellsB `$9AE5` with every cell of tile `$8C`. `$91C0` and `$9282`/`$92BD` animate those cells each pass.

Then `$5C0C`, `$5C41` and `$5BA1` are cleared and `$B072` set to 1 (counters of other modules); room `$10` sets the byte `$A6F5` (the room-`$0F` byte of the per-room table `$A6E6`) to 6 (it starts at 7, `$8F47` area); room `$1C` with `$5C24` non-zero writes the tile pair `$98`, `$99` into columns 8-9 of rows 0-11 of the tile map (`$5C24` counts the column that `$BC73` raises cell by cell while item `$0C` is used there). `$5C24` is cleared in every room. Last `$917C` parks actor slots 1-4 (frame `$7F`, the blank sprite), DrawRoom `$99A4` draws the whole play window and `$B93F` (tail jump) places the room's floor items.

Evidence: 105-106 runs in 31 builds; the room-`$10` branch ran in gameover, r10000 and r14500; the room-`$1C` column (`$98F7-$9906`) did not run in any of the 34 builds (no build entered room `$1C` with `$5C24` set).

Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 1,585 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r06000` 6, `stage1/rzx/r40000` 6 and 27 more) |
| Called from | `SetUpRoom` |
| Calls | `ClearPartySlots`, `SwapTileset`, `BuildTileMap`, `DrawRoom`, `FindTileCells`, `SpawnRoomItems` (tail) |
| Reads | `$5C24` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$9AC6`-`$9AF3` (`AltTilesetRooms`, `EffectCellsA`, `EffectCellsB`) |
| Writes | `$5BA1`-`$5BA3` (system); `$5C0C` (system); `$5C24` (system); `$5C41` (system); `$9AD5`-`$9AF4` (`EffectCellsA`, `EffectCellsB`); `$A6F5` (`ThinkHints+15`); 1 more ranges |

### `BuildTileMap` (`$9914`)

**Expand room A's 8 x 4 back-tiles into the 32 x 16 tile map `$F800` (SK)**

A = the room. The room's 32 back-tile indices sit at `$D600` + 32 * room, 4 rows of 8; each back-tile is 16 tile indices at `$C600` + 16 * index, 4 rows of 4, written to the tile map at `$F800` + 128 * row + 4 * column (IX), the 16 stores unrolled. Back-tile `$10` (the well) is also recorded by WellRecord `$99F0` before it is copied. Out: the tile map; IX, HL, DE, BC changed.

Called only by SetUpRoomTiles at `$98A4`. Room `$0C` is the only room using back-tile `$10` (index 26: row 3, column 2), drawn in docs/img/maps/rooms.png as the well; WellRecord ran 3 times, in r06000 and r12000.

Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 23,212 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r40000` 6, `stage1/rzx/r06000` 6 and 27 more) |
| Called from | `SetUpRoomTiles` |
| Calls | `WellRecord` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$C600`-`$CF3F` (`BackTiles`); `$CF70`-`$D4FF` (`BackTiles+2416`); `$D510`-`$D54F` (`BackTiles+3856`); `$D600`-`$D61F` (`RoomGrids`); `$D660`-`$D69F` (`RoomGrids+96`); 6 more ranges |
| Writes | `$F800`-`$F9FF` (`TileMap`) |

### `DrawRoom` (`$99A4`)

**Draw the whole play window from the tile map: attributes, screen and back buffer (SK)**

For each of the 512 cells n of the tile map `$F800` (32 x 16): the attribute `$5800` + n = `$DF00`[tile], and the tile's 8 bytes at (TileBitmaps `$5B72`, `$F000`) + 8 * tile go to the screen cell (the top two thirds, `$4000-$4FFF`) and to the same cell of the back buffer (`$E000-$EFFF`, the screen address OR `$A000`), so the buffer starts each room as a clean copy of the background.

Called only by SetUpRoomTiles at `$990E` (106 runs, 31 builds). Stops when n reaches 512 (BIT 1,H).

Witness: L1 106 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `DrawRoom` at work](img/routines/DrawRoom.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 433,367 t-states own (0.02 %) |
| Runs (the other recordings) | 105 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r06000` 6, `stage1/rzx/r40000` 6 and 27 more) |
| Called from | `SetUpRoomTiles` |
| Reads | `$5B72`-`$5B73` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$DF01`-`$DFFF` (`TileAttrs+1`); `$F008`-`$F9FF` (`TilePixels+8`, `TileMap`) |
| Writes | `$4000`-`$4FFF` (screen); `$5800`-`$59FF` (screen); `$E000`-`$EFFF` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |

### `WellRecord` (`$99F0`)

**Note the well (back-tile `$10`): the cell under its top row and its middle tile rows**

Called by BuildTileMap at `$993D` when the back-tile is `$10`. IX = the back-tile's first cell in the tile map, HL = its 16 tile indices. WellCell `$5BA2` = IX + `$6020`: the same cell one row down, written in the attribute-file form (`$5800` + offset: only bits 0-1 of the high byte and the low byte are used by DrawTileAt `$9A64`); WellTiles `$5BA4` = HL + 4: the back-tile's rows 1 and 2 (tiles `$34-$37` and `$3F-$42`, the well's front wall). DrawWellFront `$9A2F` redraws exactly those 2 x 4 cells. All registers kept.

Witness: 3 runs (r06000, r12000), the room-`$0C` set-ups.

Witness: L1 3 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3 calls (`stage1/rzx/r06000` 2, `stage1/rzx/r12000` 1) |
| Called from | `BuildTileMap` |
| Writes | `$5BA2`-`$5BA5` (system) |

### `WellFront` (`$9A09`)

**Draw the well's front wall over the hero while he climbs into or out of the well**

Called by RenderPass `$9B22` at `$9BB7` right after the hero (actor slot 0) is drawn into the back buffer, once a pass (26 517 calls over the 34 builds). `$AF22` returns carry when the room has no well (WellCell `$5BA2` = 0) or the hero's X (`$5B04`) is not within the 8 pixels of the well's column; otherwise, when RoomEvent `$5C06` is 2 with EventTimer `$5C07` >= 8, or RoomEvent is 3 with EventTimer < 8, DrawWellFront `$9A2F` paints the wall's 2 x 4 cells over the hero in the buffer, so the hero is hidden behind the well's rim. RoomEvent 3 is set at `$A508` when the hero climbs up out of room `$18` into room `$0C` (the room above it, Y = `$60`); RoomEvent 2 at `$AD2D` (`$AD17`, the climb). BC, HL, DE kept.

Evidence: the wall was drawn 11 times (r06500, r12000); RoomEvent 2 reached `$9A1F` in r06500, RoomEvent 3 in r12000. What the screen shows is not yet checked (run request R1).

Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 41,048 t-states own (0.00 %) |
| Runs (the other recordings) | 25,247 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `RenderPass` |
| Calls | `DrawWellFront`, `OverHole` |
| Reads | `$5C06`-`$5C07` (system) |

### `DrawWellFront` (`$9A2F`)

**Redraw the well's front wall: 2 rows of 4 cells into the back buffer**

HL = WellCell `$5BA2` (returns at once when 0), DE = WellTiles `$5BA4`. Two rows of four cells through DrawTileBuffer `$9A62`, the second row 32 cells on. Called only by WellFront at `$9A28` (11 runs, r06500 and r12000).

Witness: L1 11 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage1/rzx/r12000` 8, `stage1/rzx/r06500` 3) |
| Called from | `WellFront` |
| Calls | `DrawTileBuffer` |
| Reads | `$5BA2`-`$5BA5` (system) |

### `SetTileBuffer` (`$9A4D`)

**Write tile A into tile-map cell HL and draw it into the back buffer only**

HL = a cell of the tile map (`$F800-$F9FF`), A = the tile. (HL) = A, DE = HL, then DrawTileBuffer `$9A62` (a tail jump at `$9A50`). Out: L + 1, DE + 1. Callers: the alternate set's effect `$9282` at `$92B0` and `$92B7`, and `$B7A8` at `$B7D4` (25 904 and 5312 calls).

Witness: L1 38860 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 38,860 calls (`stage1/rzx/r44000` 7,920, `stage1/rzx/r46000` 7,572, `stage1/rzx/r48000` 7,548 and 9 more) |
| Called from | `RoomEffects`, `Capsules`, `FlickerFloor` |
| Calls | `DrawTileBuffer` (tail) |
| Reads | `$5B72`-`$5B73` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$F460`-`$F46F` (`TilePixels+1120`); `$F8B1`-`$F8B2` (`TileMap+177`); `$F8C5`-`$F8DE` (`TileMap+197`); `$F945`-`$F95A` (`TileMap+325`); 1 more ranges |
| Writes | `$E0B1`-`$E7DE` (`BackBuffer+177`); `$E845`-`$EABA` (`SavedPanelAttrs+69`, `BackBufferLeftover`); `$EB45`-`$EBBA` (`BackBufferLeftover+581`); `$EC45`-`$ECBA` (`BackBufferLeftover+837`); `$ED45`-`$EDBA` (`BackBufferLeftover+1093`); `$EE45`-`$EEBA` (`BackBufferLeftover+1349`); 5 more ranges |

### `SetTile` (`$9A52`)

**Write tile A into tile-map cell HL and draw it on the screen and in the back buffer**

HL = a cell of the tile map, A = the tile. (HL) = A; DrawTileAt `$9A64` with C = `$40` draws the cell on the screen, the cell is stepped back and the routine runs on into DrawTileBuffer `$9A62` for the buffer. Out: HL = the cell + 1 in the attribute-file form (`$58`xx), DE = HL; callers push what they keep. Callers: the base set's effect `$91C0` at `$91F3` (5256 calls, tile `$B5`), `$BA97` at `$BB19`, and the room-`$1C` column `$BC73` (tiles `$98`, `$99`; not reached in any build).

Witness: L1 5349 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 5,349 calls (`stage1/rzx/r16000` 774, `stage1/rzx/r32000` 771, `stage1/rzx/r30000` 745 and 12 more) |
| Called from | `RoomEffects`, `BridgeEffect` |
| Calls | `DrawTileBuffer`, `DrawTileAt` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$F808`-`$F810` (`TileMap+8`); `$F825`-`$F83C` (`TileMap+37`); `$F88C`-`$F898` (`TileMap+140`); `$F8B8`-`$F8BC` (`TileMap+184`); `$F968`-`$F977` (`TileMap+360`); `$F9B4` (`TileMap+436`) |

### `DrawTileBuffer` (`$9A62`)

**Draw the tile of cell (DE) at cell HL of the back buffer**

C = `$E0` (the back buffer's page), then DrawTileAt `$9A64`. Entered by SetTileBuffer, by SetTile (running on) and called by DrawWellFront at `$9A3F`.

Witness: L1 44297 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,659 calls (`stage1/rzx/r20000` 7,120, `stage1/rzx/r42000` 4,517, `stage1/rzx/r18000` 1,638 and 3 more) |
| Called from | `DrawWellFront`, `SetTileBuffer` (tail), `SetTile` |
| Calls | `DrawTileAt` |
| Reads | `$5B72`-`$5B73` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$C704`-`$C70B` (`BackTiles+260`); `$F1A0`-`$F1BF` (`TilePixels+416`); `$F1F8`-`$F217` (`TilePixels+504`) |
| Writes | `$E8A8`-`$E8CB` (`SavedPanelAttrs+168`); `$E9A8`-`$E9CB` (`BackBufferLeftover+168`); `$EAA8`-`$EACB` (`BackBufferLeftover+424`); `$EBA8`-`$EBCB` (`BackBufferLeftover+680`); `$ECA8`-`$ECCB` (`BackBufferLeftover+936`); `$EDA8`-`$EDCB` (`BackBufferLeftover+1192`); 2 more ranges |

### `DrawTileAt` (`$9A64`)

**Draw tile (DE) into the cell HL of the screen page C (`$40`) or the back buffer (`$E0`)**

HL = a cell address of which only L (the cell in the third) and bits 0-1 of H (the third) are used, so tile-map (`$F8`xx) and attribute (`$58`xx) forms both work; DE points to the tile index; C = the page. The tile's 8 bytes at (TileBitmaps `$5B72`) + 8 * tile go to the 8 pixel rows of the cell. Out: L + 1 (the next cell), DE + 1; BC kept.

Witness: L1 49646 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 22,904 calls (`stage1/rzx/r20000` 7,804, `stage1/rzx/r42000` 4,554, `stage1/rzx/r18000` 2,256 and 12 more) |
| Called from | `SetTile`, `DrawTileBuffer` |
| Reads | `$5B72`-`$5B73` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$C704`-`$C70B` (`BackTiles+260`); `$F038`-`$F03F` (`TilePixels+56`); `$F1A0`-`$F1BF` (`TilePixels+416`); `$F1F8`-`$F217` (`TilePixels+504`); 14 more ranges |
| Writes | `$4008`-`$4AB4` (screen); `$4B68`-`$4B77` (screen); `$4BB4` (screen); `$4C68`-`$4C77` (screen); `$4CB4` (screen); `$4D68`-`$4D77` (screen); 6 more ranges |

### `FindTileCells` (`$9A8C`)

**List the tile-map cells holding tile A, as words from DE on**

A = the tile, DE = the list. CPIR over `$F800-$F9FE` (BC = `$1FF`: the last cell, `$F9FF`, is never searched); each match is stored as its tile-map address (low byte first). The list's end is the zero word left by the clearing in SetUpRoomTiles. Out: DE past the last word.

Called by SetUpRoomTiles at `$98C2` (tile `$B5` or `$DD` into EffectCellsA `$9AD5`) and `$98D0` (tile `$8C` into EffectCellsB `$9AE5`): 124 calls, a match in 17 builds (70 words stored). Each list has room for 8 words; the most any room holds is 4 tiles `$DD` (room `$38`) and 6 tiles `$8C` (room `$3B`), counted from the room data, so neither list overflows.

Witness: L1 124 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 10,764 t-states own (0.00 %) |
| Runs (the other recordings) | 123 calls (`stage1/rzx/r40000` 12, `stage1/rzx/r00000` 8, `stage1/rzx/r20000` 7 and 27 more) |
| Called from | `SetUpRoomTiles` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$F800`-`$F9FE` (`TileMap`) |
| Writes | `$9AD5`-`$9AF0` (`EffectCellsA`, `EffectCellsB`) |

### `SaveRespawnPoint` (`$9AA1`)

**Record the room, the event state and the hero as the place a lost life restarts (SK)**

Copies Room `$5C01` to `$5C2D`, RoomEvent `$5C06` to `$5C2B`, EventTimer `$5C07` to `$5C2C`, the hero's X and Y (`$5B04`) to `$5C2E`, his frame and flags (`$5B06`) to `$5C30` and the word `$5B9E` to `$5C32`. The respawn `$9090` copies them all back and calls SetUpRoom.

Callers: GameInit at `$9012` (the start room) and SetUpRoom at `$9874` (a room listed in CheckpointRooms entered while FallCount `$5C05` = 0). 78 runs in 27 builds. A life lost in an unlisted room restarts in the last listed room entered.

Witness: L1 78 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 368 t-states own (0.00 %) |
| Runs (the other recordings) | 76 calls (`stage1/explorers` 10, `stage1/rzx/r00000` 8, `stage1/rzx/r40000` 5 and 23 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `SetUpRoom` |
| Reads | `$5B04`-`$5B07` (system); `$5B9E`-`$5B9F` (system); `$5C01`-`$5C07` (system) |
| Writes | `$5C2B`-`$5C33` (system) |

## countdown

`src/game/countdown.asm`

### `CountDown` (`$935D`)

**One minute off the countdown; when it runs out, the game is lost**

Called once a pass by MainLoop `$9018`. The countdown is three plain binary bytes: days `$5BFB`, hours `$5BFC`, minutes `$5BFD` (InitGame sets 30, 23, 59; c1 frame 23500 holds 30, 23, 11). Minutes - 1; below 0 it is 59 and the hours - 1 (440 runs of `$9364`); below 0, 23 and the days - 1 (`$936B`, 13 runs in rzx: about every 4000 frames); below 0 the time is up: falls into LoseGame `$9372` (not executed in any recording: the rzx run ended with 18 days left).

Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 65,373 t-states own (0.00 %) |
| Runs (the other recordings) | 25,244 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop` |
| Reads | `$5BFB`-`$5BFD` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5BFB`-`$5BFD` (system) |

### `LoseGame` (`$9372`)

**The game is lost: the hero in room `$28` for the space scene**

Reached by falling in from CountDown `$935D` (the time is up) and by `JP Z,$9372` at `$A9FE` in `$A9EE` when the last life is lost (gameover frame 1502).

The hero's frame `$5B06` = `$7F` (the blank sprite), Room `$5C01` = `$28` and the room set-up `$9855`; the respawn state too: room `$28` (`$5C2D`), EventTimer 0 (`$5C2C`), RoomEvent `$1D` (`$5C2B`); `JP $AE85` with A = `$1D`: RoomEvent = `$1D`, EventTimer = 0. Status `$1D` is Frozen `$A90E`, which only holds; SpaceScene `$B0B6`, room `$28`'s script, plays the asteroid striking (gameover frames 1509-1961) and sets GameOver; EndGame `$906D` follows (frame 1962). After the last life the respawn (`$9090`, LifeLost still set) restores the same room and event.

The time running out, on a clone (work/stage2/probe_points.py A: the RZX state at 44000 in room `$3B`, the countdown poked to 0 days 0 hours 2 minutes): the pass after 0/0/0 falls in here (days wrap to 255, the clock goes on counting: 255/23/59), Room `$28` 10 frames after the poke, status 29 from frame 20, GameOver `$5BFF` at frame 430: the same space scene as the last life's (no other end for the time running out).

Witness: L1 1 (gameover).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/gameover` 1) |
| Called from | `LoseLifeWait` (tail) |
| Calls | `SetUpRoom`, `SetStatus` (tail) |
| Writes | `$5B06` (system); `$5C01` (system); `$5C2B`-`$5C2D` (system) |

## menu

`src/game/menu.asm`

### `DeviceMenu` (`$93AF`)

**The title and device menu: the frame, the logo, the options, the credits; keys 1-3 and 0**

Called by NewGame `$8F47` before every game (c1 2, explorers 5, gameover 1, rzx50000 1). Clears the screen, attributes `$44` (green ink), a 6 x 6 block of `$45` at `$5937` and a 3 x 3 block of `$47` at `$5942` (FillAttrs `$9526`).

The frame is cut from the panel kept at `$E000-$E7FF` (the panel's screen third as loaded; after a game the one EndGame `$906D` saved): the panel's top row `$E000` to row 0, its bottom row `$E0E0` to row 23 (CopyCharRow `$94B0`), and the left and right edge cells of panel rows 1 and 2 (`$E020`, `$E040`) alternately down rows 1-22 (CopyEdgeCells `$94C2`, 11 times).

The TERRAMEX logo TitleLogo `$95FD`, 3 rows of 25 cells at `$4063` (row 3, column 3), attribute `$46` (yellow); `$9F27` (the menu's pictures); the options MenuText `$9540` at row 8 column 8 (attribute `$44`) and the credits CreditsText `$9579` at row 17 column 2 (attribute `$47`) through PrintString `$94F9`.

The loop (MenuLoop `$9440`), once a frame: the option box (rows 8-12, columns 8-21) gets attribute `$43` (magenta), the row of the chosen device (InputDevice `$94AF`: row 8 + 2 * device) `$47` (white); HALT; keys 1, 2, 3 (half row `$F7FE`) choose keyboard, Kempston, Sinclair (explorers: all three); key 0 (half row `$EFFE`) returns. IY = 0 at every turn is never used here.

Witness: L1 9 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 66,591,546 t-states own (3.53 %) |
| Runs (the other recordings) | 7 calls (`stage1/explorers` 5, `stage1/gameover` 1, `stage1/rzx/r50000` 1) |
| Called from | `GameEntry`, `NewGame` |
| Calls | `CopyCharRow`, `CopyEdgeCells`, `PrintMenuText`, `PrintString`, `FillAttrs`, `ScreenToAttr`, `DrawMenuGlobes` |
| Reads | `$4000`-`$5AFE` (screen); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$9469` (`MenuKeys+1`); `$94AF` (`InputDevice`); `$95FD`-`$9854` (`TitleLogo`) |
| Writes | `$4000`-`$5AFF` (screen); `$94AF` (`InputDevice`) |
| Ports in | `$EFFE`, `$F7FE` |

### `MenuLoop` (`$9440`)

**The device menu's loop: the option box and the chosen device's bar (DeviceMenu continued)**

Reached by falling in from DeviceMenu `$93AF` and from MenuKeys `$9468` (`JR $9440`) once a frame; an entry of the cut because the explorers recording starts inside the menu. The box (5 rows x 14 columns at row 8, column 8) gets attribute `$43`, the row of the chosen device (InputDevice `$94AF`; row 8 + 2 * device) `$47` on its 14 columns. IY = 0 here is never used. Falls into MenuKeys.

Witness: L1 6835 (c1, explorers, gameover, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,266 calls (`stage1/explorers` 1,266) |
| Called from | `MenuKeys` (tail) |
| Calls | `MenuKeys`, `FillAttrs` |
| Reads | `$5908`-`$5914` (screen); `$5948`-`$5954` (screen); `$5988`-`$5994` (screen); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$9469` (`MenuKeys+1`); `$94AF` (`InputDevice`) |
| Writes | `$5908`-`$5915` (screen); `$5948`-`$5955` (screen); `$5988`-`$5995` (screen); `$94AF` (`InputDevice`) |
| Ports in | `$EFFE`, `$F7FE` |

### `MenuKeys` (`$9468`)

**The device menu's keys: 1-3 choose the device, 0 starts (DeviceMenu continued)**

HALT (one turn a frame), then half row `$F7FE`: a lone 1, 2 or 3 sets InputDevice `$94AF` to 0 (keyboard), 1 (Kempston), 2 (Sinclair); half row `$EFFE` bit 0, the key 0, returns from DeviceMenu `$93AF` to NewGame; else `JR $9440`. explorers chooses all three devices; c1 1, 3, 2 then 0.

Witness: L1 6836 (c1, explorers, gameover, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,271 calls (`stage1/explorers` 1,271) |
| Called from | `MenuLoop` |
| Calls | `MenuLoop` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$9469` (`MenuKeys+1`) |
| Writes | `$94AF` (`InputDevice`) |
| Ports in | `$EFFE`, `$F7FE` |

### `CopyCharRow` (`$94B0`)

**Copy a character row of 32 cells (8 pixel rows)**

HL = the source, DE = the destination, both at a cell's top pixel row in a screen-like layout. 32 bytes a pixel row, INC H and INC D between rows. Callers: DeviceMenu `$93E4`, `$93ED`.

Witness: L1 18 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 4 calls, 33,832 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/explorers` 10, `stage1/rzx/r50000` 2, `stage1/gameover` 2) |
| Called from | `DeviceMenu` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E000`-`$E21F` (`BackBuffer`); `$E2E0`-`$E31F` (`BackBuffer+736`); `$E3E0`-`$E41F` (`BackBuffer+992`); `$E4E0`-`$E51F` (`BackBuffer+1248`); `$E5E0`-`$E61F` (`BackBuffer+1504`); 2 more ranges |
| Writes | `$4000`-`$471F` (screen); `$50E0`-`$52FF` (screen); `$53E0`-`$53FF` (screen); `$54E0`-`$54FF` (screen); `$55E0`-`$55FF` (screen); `$56E0`-`$56FF` (screen); 1 more ranges |

### `CopyEdgeCells` (`$94C2`)

**Copy the left and right edge cells of a row; DE to the next character row**

HL = the source row (the left cell), DE = the destination row. Copies the cell at column 0, then the cell at column 31 of both (L OR `$1F`, E OR `$1F`), through CopyCell `$94E4`. Out: DE = the next character row's column 0 (into the next screen third after row 7 of one); HL unchanged. Called 22 times a menu by DeviceMenu.

Witness: L1 198 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 44 calls, 9,488 t-states own (0.00 %) |
| Runs (the other recordings) | 154 calls (`stage1/explorers` 110, `stage1/rzx/r50000` 22, `stage1/gameover` 22) |
| Called from | `DeviceMenu` |
| Calls | `CopyCell` |

### `CopyCell` (`$94E4`)

**Copy one cell, 8 pixel rows**

HL = the source, DE = the destination; INC H and INC D between rows. BC kept. Called by CopyEdgeCells `$94C2`.

Witness: L1 396 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 88 calls, 29,796 t-states own (0.00 %) |
| Runs (the other recordings) | 308 calls (`stage1/explorers` 220, `stage1/rzx/r50000` 44, `stage1/gameover` 44) |
| Called from | `CopyEdgeCells` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E020`-`$E05F` (`BackBuffer+32`); `$E120`-`$E15F` (`BackBuffer+288`); `$E220`-`$E25F` (`BackBuffer+544`); `$E320`-`$E35F` (`BackBuffer+800`); `$E420`-`$E45F` (`BackBuffer+1056`); 3 more ranges |
| Writes | `$4020`-`$50DF` (screen); `$5100`-`$51DF` (screen); `$5200`-`$52DF` (screen); `$5300`-`$53DF` (screen); `$5400`-`$54DF` (screen); `$5500`-`$55DF` (screen); 2 more ranges |

### `PrintMenuText` (`$94EF`)

**Print the device options at row 8, column 8, attribute `$44`**

DE = MenuText `$9540`, HL = `$4808`, A' = `$44`; falls into PrintString `$94F9`. Called by DeviceMenu `$9430`.

Witness: L1 9 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 70 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/explorers` 5, `stage1/gameover` 1, `stage1/rzx/r50000` 1) |
| Called from | `DeviceMenu` |
| Calls | `PrintString` |

### `PrintString` (`$94F9`)

**Print a text with an attribute: 0 ends, `$0D` a new line**

DE = the text, HL = the screen address of the first cell, A' = the attribute. Each character goes through PrintChar `$90C6` and its cell's attribute (ScreenToAttr `$9536`) is A'. `$0D` starts the next character row under the line's first cell: the line start is kept in the operand at `$9517` (written here, so the image after a menu holds `$50A2`, the credits' last line); 0 ends. `$7F` is the ROM font's copyright sign.

Callers: PrintMenuText `$94EF` (falls in), DeviceMenu `$943D`, and `$A7EB` (the countdown text, not executed in any recording).

Witness: L1 108 (c1, explorers, gameover, rzx).

[Animation: `PrintString` at work](img/routines/PrintString.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 4 calls, 66,172 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/explorers` 10, `stage1/gameover` 2, `stage1/rzx/r50000` 2) |
| Called from | `DeviceMenu`, `PrintMenuText` |
| Calls | `PrintChar`, `ScreenToAttr` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$9540`-`$95FC` (`MenuText`, `CreditsText`) |
| Writes | `$5908`-`$5913` (screen); `$5948`-`$5953` (screen); `$5988`-`$5993` (screen); `$59C8`-`$59D5` (screen); `$5A22`-`$5AB6` (screen); `$9517`-`$9518` (`PrintNewLine+1`) |

### `FillAttrs` (`$9526`)

**Fill a block of B rows by C bytes with A, rows 32 bytes apart**

HL = the top-left address (an attribute in every caller), B = the rows, C = the bytes a row, A = the value. Out: HL = the address below the block; BC changed. Callers: DeviceMenu `$93D0`, `$93DB` and MenuLoop `$944D` (once a frame on the menu).

Witness: L1 34256 (c1, explorers, gameover, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,026 calls, 2,446,815 t-states own (0.13 %) |
| Runs (the other recordings) | 5,827 calls (`stage1/gameover` 4,032, `stage1/explorers` 1,281, `stage1/rzx/r50000` 410 and 1 more) |
| Called from | `DeviceMenu`, `MenuLoop` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5908`-`$5915` (screen); `$5928`-`$599C` (screen); `$59B7`-`$59BC` (screen); `$59D7`-`$59DC` (screen) |

### `ScreenToAttr` (`$9536`)

**The attribute address of a cell's screen address**

HL = a screen address at a cell's top row. Out: H = `$58` + the screen third, L unchanged: the cell's attribute. Callers: DeviceMenu `$941B`, PrintString `$950B`.

Witness: L1 2268 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 504 calls, 23,095 t-states own (0.00 %) |
| Runs (the other recordings) | 1,764 calls (`stage1/explorers` 1,260, `stage1/gameover` 252, `stage1/rzx/r50000` 252) |
| Called from | `DeviceMenu`, `PrintString` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `DrawMenuGlobes` (`$9F27`)

**Draw the Earth and the Moon on the device menu**

Frames `$71-$74` counted from `$6000` (the image's `$7FC8-$80E7`) are the Earth, a 48 x 48 picture: the first 6 columns at `$4837` (rows 9-11, columns 23-28), the next 6 at `$4897` (rows 12-14). Frame `$75` (`$80E8`) is the Moon at `$4842` (rows 10-12, columns 2-4). menu.png shows both there.

Called by the menu `$93AF` at `$942D`: 9 runs (c1, explorers, gameover, r50000).

Witness: L1 9 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 1,205 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/explorers` 5, `stage1/rzx/r50000` 1, `stage1/gameover` 1) |
| Called from | `DeviceMenu` |
| Calls | `BlitColumns` (tail), `SpriteAddress`, `AddColumnPointers` |

## interrupt

`src/game/interrupt.asm`

### `Im2Handler` (`$9491`)

**The IM 2 handler: the AY music from RAM 6 on a 128K**

Reached through the vector `JP $9491` at `$5F5F` on every interrupt (83616 runs: one a frame in every build after GameEntry). On a 128K (Has128K `$5FFE` not 0) it pages RAM 6 in (`$7FFD` = `$16`), calls the music player at `$C000` and pages back the value in Last7FFD `$5FE5`; AF and BC are kept, the player keeps the rest. On a 48K it only enables the interrupts again: no music.

Witness: L1 83616 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 5,029 calls, 809,669 t-states own (0.04 %) |
| Runs (the other recordings) | 78,587 calls (`stage1/explorers` 15,190, `stage1/gameover` 6,000, `stage1/rzx/r00000` 2,000 and 30 more) |
| Reads | `$5FE5` (system); `$5FFE` (system) |
| Ports out | `$7FFD` |

## render

`src/game/render.asm`

### `RenderPass` (`$9B22`)

**Draw the five actors and the items of one main-loop pass and update the screen**

Called once a pass by the main loop at `$9040` (26 517 calls over the 34 builds). The actor slots ActorSlots `$5B04` hold 5 records of 4 bytes (X, Y, frame, flags; slot 0 the hero).

1. For each slot BufferAddress `$9CEE` gives the back-buffer address of (X, Y) and the row plotter for X mod 8; both go to the slot's record in ActorRects `$5B44` (slot + `$40`: the address, slot + `$42`: the plotter).

2. Each slot's sprite, frame F at `$6000` + 72 * F, is drawn into the back buffer in three columns of 24 rows (DrawSpriteColumn `$9C6A`). Flags bit 7 set (facing right: the stored graphics face left) patches the two MirrorPatch points `$9C82`/`$9C87` to LD L,A / LD A,(HL), so each byte is bit-reversed through the table at `$FE00`, and draws the columns right to left; bit 7 clear patches them to two NOPs. The L1 arrivals record these writes in 21 builds (`$9B82`/`$9B85` or `$9B9C`/`$9B9F`). After slot 0 WellFront `$9A09` may paint the well over the hero.

3. DrawItems `$9DE3` draws the floor items into the buffer and the screen at once. 4. CopyRects `$9BEB` copies the 4-byte by 24-row rectangles of last pass's positions (PrevActorRects `$5B24`, through IX = `$5AE4`) and of this pass's (`$5B44`) from the buffer to the screen: the old places get their background back and the new ones the sprites, with no flicker. 5. `$5B44` is saved to `$5B24`, the alternate set's effects run (`$92BD`) and RestoreActorBackgrounds `$9D3C` repaints the buffer under the five actors from the tile map, ready for the next pass.

Witness: L1 26515 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `RenderPass` at work](img/routines/RenderPass.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 6,663,848 t-states own (0.35 %) |
| Runs (the other recordings) | 25,245 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop` |
| Calls | `ShowCapsules`, `WellFront`, `CopyRects`, `DrawSpriteColumn`, `BufferAddress`, `RestoreActorBackgrounds`, `DrawItems` |
| Reads | `$5B04`-`$5B17` (system); `$5B44`-`$5B63` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B24`-`$5B57` (system); `$9C82`-`$9C88` (`MirrorPatch1`, `MirrorPatch2`) |

### `CopyRects` (`$9BEB`)

**Copy five 4 x 24-byte rectangles from the back buffer to the screen**

IX = a 4-byte record array whose +`$40`/+`$41` holds each rectangle's back-buffer address (`$5B04` for ActorRects `$5B44`, `$5AE4` for PrevActorRects `$5B24`). The screen address is the buffer address AND `$5FFF`. Each rectangle is 24 pixel rows of 4 bytes, copied with LDI and LDD on alternate rows (a serpentine, so the pointers never step back); NextCharRow `$9DBF` follows the character-row and third boundaries. B counts the rectangles; the entry CopyRect `$9BF3` copies one (B = 1) from HL.

Called by RenderPass at `$9BCB` and `$9BD2` (53 020 calls).

Witness: L1 53020 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `CopyRects` at work](img/routines/CopyRects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2,540 calls, 17,780 t-states own (0.00 %) |
| Runs (the other recordings) | 50,480 calls (`stage1/explorers` 8,524, `stage1/rzx/r14000` 1,704, `stage1/rzx/r32000` 1,542 and 30 more) |
| Called from | `RenderPass` |
| Calls | `CopyRectsLoop`, `NextCharRow` |
| Reads | `$5B24`-`$5B55` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E000`-`$EFF4` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |
| Writes | `$4000`-`$4FF4` (screen) |

### `CopyRectsLoop` (`$9BED`)

**CopyRects: the next record's rectangle**

The loop head of CopyRects `$9BEB` (the tail jump at `$9C66` comes back here for each record).

Witness: L1 265094 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 12,700 calls, 506,414 t-states own (0.03 %) |
| Runs (the other recordings) | 146,542 calls (`stage1/explorers` 42,620, `stage1/rzx/r32000` 7,708, `stage1/rzx/r30000` 7,452 and 13 more) |
| Called from | `CopyRects`, `CopyRect` (tail) |
| Calls | `CopyRect` |
| Reads | `$5B24`-`$5B55` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `CopyRect` (`$9BF3`)

**Copy the 4 x 24-byte rectangle at back-buffer address HL to the screen**

HL = the buffer address, B = the rectangles to go (1 from EraseItem `$9D21` at `$9D39`), IX the record (stepped by 4 at the end).

Witness: L1 265129 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 12,701 calls, 33,289,643 t-states own (1.76 %) |
| Runs (the other recordings) | 146,576 calls (`stage1/explorers` 42,625, `stage1/rzx/r32000` 7,709, `stage1/rzx/r30000` 7,453 and 13 more) |
| Called from | `CopyRectsLoop`, `EraseItem` (tail) |
| Calls | `CopyRectsLoop` (tail), `NextCharRow` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E000`-`$EFF4` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |
| Writes | `$4000`-`$4FF4` (screen) |

### `DrawSpriteColumn` (`$9C6A`)

**Draw one 24-row sprite column into the back buffer with its outline mask**

In: the main set DE = the column's 24 bytes, H = `$FE` (the bit-reverse page, used when MirrorPatch is in); the alternate set BC = the buffer address, IY = the row plotter from BufferAddress `$9CEE`. C (main set) = 0: the byte above the first row. The nested calls DrawSprite12Rows `$9C72`, DrawSprite6Rows `$9C75`, DrawSprite3Rows `$9C78` run DrawSpriteRow `$9C7E` 24 times. Called by RenderPass 6 call sites, 397 715 calls (three a slot a pass).

Witness: L1 397715 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `DrawSpriteColumn` at work](img/routines/DrawSpriteColumn.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 19,050 calls, 696,778 t-states own (0.04 %) |
| Runs (the other recordings) | 378,665 calls (`stage1/explorers` 63,930, `stage1/rzx/r14000` 12,790, `stage1/rzx/r32000` 11,565 and 30 more) |
| Called from | `RenderPass` |
| Calls | `DrawSprite12Rows` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `DrawSprite12Rows` (`$9C72`)

**DrawSpriteColumn: 12 rows (twice 6)**

Witness: L1 795428 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 38,100 calls, 727,744 t-states own (0.04 %) |
| Runs (the other recordings) | 757,321 calls (`stage1/explorers` 127,860, `stage1/rzx/r14000` 25,579, `stage1/rzx/r32000` 23,130 and 30 more) |
| Called from | `DrawSpriteColumn`, `NextBufferRow` |
| Calls | `DrawSprite6Rows` |

### `DrawSprite6Rows` (`$9C75`)

**DrawSpriteColumn: 6 rows (twice 3)**

Witness: L1 1590856 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 76,200 calls, 1,477,552 t-states own (0.08 %) |
| Runs (the other recordings) | 1,514,642 calls (`stage1/explorers` 255,720, `stage1/rzx/r14000` 51,158, `stage1/rzx/r32000` 46,260 and 30 more) |
| Called from | `DrawSprite12Rows`, `NextBufferRow` |
| Calls | `DrawSprite3Rows` |

### `DrawSprite3Rows` (`$9C78`)

**DrawSpriteColumn: 3 rows**

Witness: L1 3181707 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 152,400 calls, 5,939,916 t-states own (0.31 %) |
| Runs (the other recordings) | 3,029,280 calls (`stage1/explorers` 511,440, `stage1/rzx/r14000` 102,315, `stage1/rzx/r32000` 92,520 and 30 more) |
| Called from | `DrawSprite6Rows`, `NextBufferRow` |
| Calls | `DrawSpriteRow` |

### `DrawSpriteRow` (`$9C7E`)

**One sprite row: the outline mask from the bytes above, at and below, then the plotter**

The mask: OutlineMasks at `$FF00` indexed by the OR of the sprite bytes of the row above, this row and the row below; the table is NOT (v OR v<<1 OR v>>1) (`$FF01` = `$FC`, `$FF02` = `$F8`: the image), so every sprite gets a one-pixel clear border round its set pixels (horizontally within the byte). The row below is the next byte, so the column's last row reads the first byte of the next column. Out to the plotter (alternate set): L = the sprite byte, D = the mask, A = `$FF` and H = 0 for the shift, BC = the buffer address; JP (IY).

Witness: L1 9545126 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 457,200 calls, 51,157,945 t-states own (2.71 %) |
| Runs (the other recordings) | 9,087,867 calls (`stage1/explorers` 1,534,320, `stage1/rzx/r14000` 306,944, `stage1/rzx/r32000` 277,560 and 30 more) |
| Called from | `DrawSprite3Rows`, `NextBufferRow` |
| Calls | `PlotRowShift1`, `PlotRowShift2`, `PlotRowShift3`, `PlotRowShift4`, `PlotRowShift5`, `PlotRowShift6`, `PlotRowShift7`, `PlotRowAligned` |
| Reads | `$6000`-`$6798` (system); `$67E0`-`$6870` (system); `$6900`-`$6E10` (system); `$7008`-`$7D40` (`CreatureSprites`); `$7E18`-`$8400` (`CreatureSprites+3096`, `BlankSprite`, `ItemSprites`); `$8838`-`$8880` (`ItemSprites+1080`); 6 more ranges |

### `PlotRowShift1` (`$9C9B`)

**Plot one masked sprite row shifted right 1 pixel (7 shift steps) into the back buffer**

The plotters `$9C9B-$9CB3` are one chain of seven steps (ADD HL,HL / SLL D / RLA); entering at X mod 8 = k runs 8 - k steps, so H:L = the sprite byte moved right k pixels over two bytes and A:D the mask moved with 1s filled in. Then (BC) = (BC) AND A OR H and (BC + 1) = (BC + 1) AND D OR L, and NextBufferRow `$9CC2`. Entered by JP (IY) from DrawSpriteRow (73 368 times in 7 builds for k = 1).

Witness: L1 73368 (gameover, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r50000`, `stage1/gameover`, `stage1/rzx/r28000` and 4 more) |
| Called from | `DrawSpriteRow` |
| Calls | `PlotRowShift2` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PlotRowShift2` (`$9C9F`)

**Plot one sprite row shifted right 2 pixels (6 steps)**

Witness: L1 1334322 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | run into, not called, 791,796 t-states own (0.04 %) |
| Runs (the other recordings) | 73,368 calls (`stage1/rzx/r50000` 39,096, `stage1/gameover` 21,384, `stage1/rzx/r28000` 5,616 and 4 more) |
| Called from | `DrawSpriteRow`, `PlotRowShift1` |
| Calls | `PlotRowShift3`, `PlotRowShift4` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PlotRowShift3` (`$9CA3`)

**Plot one sprite row shifted right 3 pixels (5 steps)**

Witness: L1 1368305 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 324,288 calls (`stage1/rzx/r20000` 74,160, `stage1/rzx/r28000` 59,328, `stage1/rzx/r50000` 55,440 and 6 more) |
| Called from | `DrawSpriteRow`, `PlotRowShift2` |
| Calls | `PlotRowShift4` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PlotRowShift4` (`$9CA7`)

**Plot one sprite row shifted right 4 pixels (4 steps)**

Witness: L1 3338410 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 17,208 calls, 2,895,657 t-states own (0.15 %) |
| Runs (the other recordings) | 1,351,097 calls (`stage1/explorers` 105,696, `stage1/rzx/r04000` 90,894, `stage1/rzx/r46000` 84,534 and 30 more) |
| Called from | `DrawSpriteRow`, `PlotRowShift2`, `PlotRowShift3` |
| Calls | `PlotRowShift5`, `PlotRowShift6` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PlotRowShift5` (`$9CAB`)

**Plot one sprite row shifted right 5 pixels (3 steps)**

Witness: L1 3350866 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 657,493 calls (`stage1/rzx/r20000` 137,592, `stage1/rzx/r28000` 111,384, `stage1/rzx/r34000` 107,442 and 4 more) |
| Called from | `DrawSpriteRow`, `PlotRowShift4` |
| Calls | `PlotRowShift6` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PlotRowShift6` (`$9CAF`)

**Plot one sprite row shifted right 6 pixels (2 steps)**

Witness: L1 4967450 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 62,928 calls, 16,866,346 t-states own (0.89 %) |
| Runs (the other recordings) | 3,287,937 calls (`stage1/explorers` 259,272, `stage1/rzx/r46000` 167,694, `stage1/rzx/r36000` 161,294 and 30 more) |
| Called from | `DrawSpriteRow`, `PlotRowShift4`, `PlotRowShift5` |
| Calls | `PlotRowShift7`, `NextBufferRow` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E008`-`$EFE7` (`BackBuffer+8`, `SavedPanelAttrs`, `BackBufferLeftover`) |
| Writes | `$E008`-`$EFE7` (`BackBuffer+8`, `SavedPanelAttrs`, `BackBufferLeftover`) |

### `PlotRowShift7` (`$9CB3`)

**Plot one sprite row shifted right 7 pixels (1 step), then the two buffer bytes**

Witness: L1 5146153 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,326,075 calls (`stage1/rzx/r36000` 186,998, `stage1/rzx/r28000` 183,932, `stage1/rzx/r34000` 180,504 and 7 more) |
| Called from | `DrawSpriteRow`, `PlotRowShift6` |
| Calls | `NextBufferRow` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E00D`-`$EFF4` (`BackBuffer+13`, `SavedPanelAttrs`, `BackBufferLeftover`) |
| Writes | `$E00D`-`$EFF4` (`BackBuffer+13`, `SavedPanelAttrs`, `BackBufferLeftover`) |

### `NextBufferRow` (`$9CC2`)

**Step the back-buffer address BC one pixel row down, over character rows and thirds**

B = the high byte (`$E0-$EF`), C = the low. Within a character cell B + 1; past its 8th row C + `$20` (the next character row), or past the third's last character row C AND `$1F` and B to the next third; below the second third (`$F0`) B is set to `$E0`, so a sprite past row 127 would wrap to the top (known only from the code). Returns to the DrawSpriteRow call chain.

Witness: L1 9545124 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 457,200 calls, 16,413,915 t-states own (0.87 %) |
| Runs (the other recordings) | 9,087,926 calls (`stage1/explorers` 1,534,320, `stage1/rzx/r14000` 306,944, `stage1/rzx/r32000` 277,560 and 30 more) |
| Called from | `PlotRowShift6`, `PlotRowShift7`, `PlotRowAligned` (tail) |
| Calls | `DrawSprite12Rows`, `DrawSprite6Rows`, `DrawSprite3Rows`, `DrawSpriteRow` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PlotRowAligned` (`$9CE7`)

**Plot one masked sprite row at a byte-aligned X: (BC) = (BC) AND D OR L**

Witness: L1 4398977 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | run into, not called, 9,342,981 t-states own (0.49 %) |
| Runs (the other recordings) | run into, not called (`stage1/explorers`, `stage1/rzx/r14000`, `stage1/rzx/r08000` and 30 more) |
| Called from | `DrawSpriteRow` |
| Calls | `NextBufferRow` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$E000`-`$EFEB` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |
| Writes | `$E000`-`$EFEB` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |

### `BufferAddress` (`$9CEE`)

**Back-buffer address BC of pixel (L = X, H = Y) and the row plotter IY for X mod 8**

Y 0-127 (bit 7 ignored): B = `$E0` + (Y AND 7) + 8 * (Y bit 6), C = 32 * ((Y >> 3) AND 7) + X >> 3, the screen layout of the play window at `$E000`. IY = PlotRowAligned `$9CE7` when X mod 8 = 0, else `$9C97` + 4 * (X mod 8) (PlotRowShift1-7). DE changed.

Callers: RenderPass at `$9B2F` (132 575 calls), DrawItem `$9DF8` at `$9E0C`, EraseItem `$9D21` at `$9D2B`.

Witness: L1 136425 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 6,402 calls, 1,239,564 t-states own (0.07 %) |
| Runs (the other recordings) | 130,023 calls (`stage1/explorers` 22,100, `stage1/rzx/r14000` 4,265, `stage1/rzx/r16000` 3,969 and 30 more) |
| Called from | `RenderPass`, `EraseItem`, `DrawItem` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `EraseItem` (`$9D21`)

**Remove a floor item (frame `$FE`): mark it gone, repaint its cells, copy them to the screen**

IX = the item record (DrawItem `$9DF8` jumps here when +2 = `$FE`). +2 = `$FF`; BufferAddress gives the address of (X, Y); RestoreRect `$9D48` repaints the cells under it in the back buffer from the tile map and CopyRect `$9BF3` puts the rectangle on the screen. IX ends 8 on (both loops step it); DrawItems reloads it.

Evidence: 35 runs in 17 builds (an item picked up; the respawn's `$FE` in `$5B9B` at `$90BE`).

Witness: L1 35 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `EraseItem` at work](img/routines/EraseItem.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 157 t-states own (0.00 %) |
| Runs (the other recordings) | 34 calls (`stage1/explorers` 5, `stage1/rzx/r02000` 4, `stage1/gameover` 3 and 13 more) |
| Called from | `DrawItem` (tail) |
| Calls | `CopyRect` (tail), `BufferAddress`, `RestoreRect` |
| Reads | `$5B99`-`$5B9A` (system); `$5C0E`-`$5C14` (system) |
| Writes | `$5B9B` (system); `$5C10`-`$5C15` (system) |

### `RestoreActorBackgrounds` (`$9D3C`)

**Repaint the back buffer under the five actors from the tile map (SK)**

IX = ActorSlots `$5B04`, B = 5. For each actor: its rectangle from ActorRects (`$5B44`), the cells under it, 3 columns and 3 rows, one more column when X mod 8 is not 0 and one more row when Y mod 8 is not 0; each cell's tile index from the tile map (`$F800` + 256 * third + the low byte of the address), its 8 bytes from TileBitmaps `$5B72` into the buffer. This removes the sprites drawn this pass, after CopyRects has shown them. Called by RenderPass at `$9BE7` (26 510 calls).

Witness: L1 26510 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `RestoreActorBackgrounds` at work](img/routines/RestoreActorBackgrounds.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 26,670 t-states own (0.00 %) |
| Runs (the other recordings) | 25,240 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `RenderPass` |
| Calls | `RestoreActorsLoop` |
| Reads | `$5B04`-`$5B15` (system); `$5B44`-`$5B55` (system); `$5B72`-`$5B73` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$F008`-`$F2BF` (`TilePixels+8`); `$F2E8`-`$F397` (`TilePixels+744`); 4 more ranges |
| Writes | `$E000`-`$EFF9` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |

### `RestoreActorsLoop` (`$9D42`)

**RestoreActorBackgrounds: the next actor's rectangle**

Witness: L1 132558 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 6,350 calls, 255,000 t-states own (0.01 %) |
| Runs (the other recordings) | 73,267 calls (`stage1/explorers` 21,310, `stage1/rzx/r32000` 3,855, `stage1/rzx/r30000` 3,725 and 13 more) |
| Called from | `RestoreActorBackgrounds`, `RestoreRect` (tail) |
| Calls | `RestoreRect` |
| Reads | `$5B44`-`$5B55` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `RestoreRect` (`$9D48`)

**Repaint the 3-4 x 3-4 cells under the record IX at back-buffer address HL**

Entry of RestoreActorBackgrounds for one record (EraseItem `$9D21` calls it with B = 1).

Witness: L1 132593 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 6,351 calls, 28,078,247 t-states own (1.49 %) |
| Runs (the other recordings) | 73,301 calls (`stage1/explorers` 21,315, `stage1/rzx/r32000` 3,856, `stage1/rzx/r30000` 3,726 and 13 more) |
| Called from | `EraseItem`, `RestoreActorsLoop` |
| Calls | `RestoreActorsLoop` (tail) |
| Reads | `$5B04`-`$5B15` (system); `$5B72`-`$5B73` (system); `$5B99`-`$5B9A` (system); `$5C0E`-`$5C14` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$F008`-`$F6B7` (`TilePixels+8`); 3 more ranges |
| Writes | `$E000`-`$EFFE` (`BackBuffer`, `SavedPanelAttrs`, `BackBufferLeftover`) |

### `NextCharRowDE` (`$9DB9`)

**NextCharRow for the address in DE**

Called by DrawItem `$9DF8` at `$9E50` (34 342 calls). Out: DE the fixed address, HL the screen counterpart.

Witness: L1 34342 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 459 calls, 18,751 t-states own (0.00 %) |
| Runs (the other recordings) | 33,883 calls (`stage1/explorers` 7,065, `stage1/rzx/r00000` 3,699, `stage1/rzx/r02000` 3,436 and 15 more) |
| Called from | `DrawItem` |
| Calls | `NextCharRow` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `NextCharRow` (`$9DBF`)

**Fix address HL after INC H crossed a character row: the next character row or third**

Called when INC H made H AND 7 = 0. DEC H, then L + `$20` with H AND `$F8` (the next character row), or past the third's last row L AND `$1F` and H AND `$F8` + 8 (the next third). Out: HL, and DE = H AND `$5F`, L: the screen address of a back-buffer address (a screen address stays itself). Callers: CopyRects (6 sites, 795 385 calls), BlitColumns `$9F86` at `$9F9A`, NextCharRowDE.

Witness: L1 893376 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 39,255 calls, 3,446,045 t-states own (0.18 %) |
| Runs (the other recordings) | 854,120 calls (`stage1/explorers` 138,180, `stage1/rzx/r16000` 32,253, `stage1/rzx/r48000` 27,726 and 30 more) |
| Called from | `CopyRects`, `CopyRect`, `NextCharRowDE`, `SpareLivesShow`, `BlitColumns` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `DrawItems` (`$9DE3`)

**Draw the room's two floor items and the third item record**

DrawItem `$9DF8` for FloorItem1 `$5C0E`, FloorItem2 `$5C13` (placed by `$B93F` from the table `$B99D`) and, running on, for the record `$5B99` (X, Y, frame; `$5B9B` = `$FE` set by the respawn at `$90BE`). Called by RenderPass at `$9BC4` (26 510 calls).

Witness: L1 26510 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 221,137 t-states own (0.01 %) |
| Runs (the other recordings) | 25,240 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 852, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `RenderPass` |
| Calls | `DrawItem` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `DrawItem` (`$9DF8`)

**Draw the item record IX (X, Y, item) into the back buffer and the screen**

+2 = `$FF`: none, return; `$FE`: EraseItem `$9D21`. Else the item sprite `$8400` + 72 * item at X AND `$F8` (byte-aligned, so no plotter) and Y: three columns of 24 rows, each byte masked like a sprite row (OutlineMasks at `$FF00` on the OR of the bytes above, at and below) and written to the back buffer and, the same byte, to the screen (RES 5 and RES 7 of the high byte: `$E0`xx -> `$40`xx). The items are drawn after the actors, so they stand in front of them, and are not repainted by RestoreActorBackgrounds: they stay in the buffer.

Witness: L1 79532 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,810 calls, 817,582 t-states own (0.04 %) |
| Runs (the other recordings) | 75,722 calls (`stage1/explorers` 12,786, `stage1/rzx/r14000` 2,556, `stage1/rzx/r32000` 2,313 and 30 more) |
| Called from | `DrawItems` |
| Calls | `BufferAddress`, `EraseItem` (tail), `NextCharRowDE` |
| Reads | `$5B9B` (system); `$5C0E`-`$5C15` (system); `$8400`-`$8838` (`ItemSprites`); `$8880`-`$8B08` (`ItemSprites+1152`); `$8B98`-`$8BE0` (`ItemSprites+1944`); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); 2 more ranges |
| Writes | `$4034`-`$4FDA` (screen); `$E034`-`$EFDA` (`BackBuffer+52`, `SavedPanelAttrs`, `BackBufferLeftover`) |

## panel

`src/game/panel.asm`

### `DrawPortrait` (`$9E5D`)

**Draw the explorer's portrait and the held item in the panel**

The explorer's frame 9 (`$6288`, the front view) at screen `$5092` (character row 20, columns 18-20) and the held item (`$5B98`, the item sprite at `$8400`; BlankIcon `$5C46` when `$FF`) at `$5032` (row 17, columns 18-20), through the column list PanelColumns `$5BD6` and BlitColumns `$9F86`. The screenshot start-room-14.png shows the explorer at row 20, column 18 and no held item.

Callers: GameInit at `$9015`, `$A851` at `$A862`, `$B370` at `$B403`, `$B5DD` at `$B5FB`, `$B735` at `$B759` (tail), `$B9FA` at `$BA30` and `$BA71`, `$BB6C` at `$BC0A`: 81 runs in 30 builds.

Witness: L1 81 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `DrawPortrait` at work](img/routines/DrawPortrait.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 428 t-states own (0.00 %) |
| Runs (the other recordings) | 79 calls (`stage1/explorers` 10, `stage1/rzx/r14500` 5, `stage1/rzx/r00000` 5 and 26 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `Room43Anim`, `CricketBallScript`, `ProfessorScript`, `LeverScript` (tail), `ItemsPass`, `ItemsKeys`, `PickUpItem` |
| Calls | `BlitColumns` (tail), `SpriteAddress`, `AddColumnPointers` |
| Reads | `$5B98` (system) |

### `DrawSpareLives` (`$9E96`)

**Draw the spare lives in the panel: up to three explorer figures**

Lives `$5B97` = 0 returns. Otherwise three icons, frames 2, 3 and 4 of the explorer's set, the k-th (k = 1-3) shown when Lives - 1 >= k, else BlankIcon `$5C46`; drawn at `$5081` (row 20, columns 1-9) by SpareLivesShow `$9F1E`. With the 4 lives of the start three figures show (start-room-14.png).

Callers: GameInit at `$8FF0`, `$A9EE` at `$AA01` (tail, the life lost): 11 runs in 7 builds; the blank icon ran in r06000, r10000, r24000, r32000.

Witness: L1 11 (c1, explorers, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 385 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/explorers` 5, `stage1/rzx/r32000` 1, `stage1/rzx/r24000` 1 and 3 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `LoseLifeWait` (tail) |
| Calls | `SpareLivesShow` (tail), `SpriteAddress`, `AddColumnPointers` |
| Reads | `$5B97` (system) |

### `DrawBearers` (`$9EBD`)

**Draw the bearer row of the panel: the four carried items and the bearers under them**

DrawBearerItems `$9EE3` draws the items first. Then four bearer figures from BearerFigures `$9FDE`, figure (log index AND 3) for the bearers BearerIndex `$5C23` to +3 (wrapping at 27), at `$5096` (row 20, columns 22-30) through BearerRowShow `$9F6B`. Only 9 of the 12 columns show, from column BearerPhase `$5C22` (0-3), so the keys 1 and 2 (bearers left, right) scroll the row a character at a time.

Callers: GameInit at `$8FE8`, `$B9FA` at `$BA6E`, `$BB6C` at `$BC1C` (tail), `$BC1F` at `$BC50`, `$BC64`, `$BC69`, `$BC70` (scroll): 1139 runs in 29 builds.

Witness: L1 1139 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `DrawBearers` at work](img/routines/DrawBearers.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 10 calls, 4,732 t-states own (0.00 %) |
| Runs (the other recordings) | 1,129 calls (`stage1/rzx/r48000` 163, `stage1/rzx/r16000` 137, `stage1/rzx/r28000` 91 and 25 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `ItemsPass`, `ItemsKeys`, `PickUpItem` (tail), `BearerKeys` (tail) |
| Calls | `DrawBearerItems`, `BearerRowShow` (tail), `SpriteAddress`, `AddColumnPointers` |
| Reads | `$5C23` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `DrawBearerItems` (`$9EE3`)

**Draw the four carried items from the inventory log, row 17 of the panel**

The entries BearerLoads `$5B7C` + BearerIndex `$5C23` on (4, wrapping at 27): the item sprite (`$8400` + 72 * item), or BlankIcon `$5C46` for a free entry (`$FF`); drawn at `$5036` (row 17, columns 22-30) by BearerItemsShow `$9F70`. The wrap ran in c1, explorers, r16000 and r34000.

Witness: L1 1139 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 10 calls, 6,334 t-states own (0.00 %) |
| Runs (the other recordings) | 1,129 calls (`stage1/rzx/r48000` 163, `stage1/rzx/r16000` 137, `stage1/rzx/r28000` 91 and 25 more) |
| Called from | `DrawBearers` |
| Calls | `ShowScrolled`, `SpriteAddress`, `AddColumnPointers` |
| Reads | `$5B7C`-`$5B96` (system); `$5C23` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `SpareLivesShow` (`$9F1E`)

**DrawSpareLives: blit the 9 columns at `$5081`**

Witness: L1 11 (c1, explorers, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 36 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/explorers` 5, `stage1/rzx/r06000` 1, `stage1/rzx/r32000` 1 and 3 more) |
| Called from | `DrawSpareLives` (tail) |
| Calls | `NextCharRow`, `Blit9Columns` (tail) |
| Reads | `$5BD6`-`$5BE7` (system); `$5C46`-`$5C8D` (system); `$6090`-`$611F` (system) |
| Writes | `$5081`-`$50C9` (screen); `$5181`-`$51C9` (screen); `$5281`-`$52C9` (screen); `$5381`-`$53C9` (screen); `$5481`-`$54C9` (screen); `$5581`-`$55C9` (screen); 2 more ranges |

### `BearerRowShow` (`$9F6B`)

**DrawBearers: the bearer figures at `$5096`, scrolled by BearerPhase**

Witness: L1 1139 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 10 calls, 220 t-states own (0.00 %) |
| Runs (the other recordings) | 1,129 calls (`stage1/rzx/r48000` 163, `stage1/rzx/r16000` 137, `stage1/rzx/r28000` 91 and 25 more) |
| Called from | `DrawBearers` (tail) |
| Calls | `ShowScrolled` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `ShowScrolled` (`$9F73`)

**Skip BearerPhase `$5C22` columns of the column list, then blit 9**

Witness: L1 2278 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 20 calls, 1,632 t-states own (0.00 %) |
| Runs (the other recordings) | 2,258 calls (`stage1/rzx/r48000` 326, `stage1/rzx/r16000` 274, `stage1/rzx/r28000` 182 and 25 more) |
| Called from | `DrawBearerItems`, `BearerRowShow` (tail) |
| Calls | `Blit9Columns`, `BlitColumns` |
| Reads | `$5C22` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `Blit9Columns` (`$9F84`)

**Blit 9 columns of the column list**

Witness: L1 2289 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 21 calls, 147 t-states own (0.00 %) |
| Runs (the other recordings) | 266 calls (`stage1/explorers` 105, `stage1/rzx/r10000` 83, `stage1/rzx/r24000` 71 and 1 more) |
| Called from | `SpareLivesShow` (tail), `ShowScrolled` |
| Calls | `BlitColumns` |

### `BlitColumns` (`$9F86`)

**Blit B 24-row columns from the pointer list IY to the screen at HL**

Each column: the 24 bytes at the next word of the list, one a pixel row down from HL (NextCharRow `$9DBF` past each character row), then HL one cell right. The panel's 24 x 24 icons go through it. Callers: DrawPortrait, DrawMenuGlobes, and the shows above (63 594 NextCharRow calls).

Witness: L1 21217 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 31 calls, 398,377 t-states own (0.02 %) |
| Runs (the other recordings) | 2,445 calls (`stage1/rzx/r48000` 332, `stage1/rzx/r16000` 280, `stage1/rzx/r28000` 188 and 26 more) |
| Called from | `DrawPortrait` (tail), `DrawMenuGlobes` (tail), `ShowScrolled`, `Blit9Columns` |
| Calls | `NextCharRow`, `ItemsKeys` |
| Reads | `$5BD6`-`$5BED` (system); `$5C46`-`$5C8D` (system); `$6090`-`$6167` (system); `$6288`-`$62CF` (system); `$7FC8`-`$812F` (`CreatureSprites+3528`); `$8400`-`$87EF` (`ItemSprites`); 6 more ranges |
| Writes | `$4837`-`$57DE` (screen) |

### `SpriteAddress` (`$9FAA`)

**HL = DE + 72 * A: sprite A of the table at DE**

Witness: L1 8130 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 54 calls, 8,945 t-states own (0.00 %) |
| Runs (the other recordings) | 8,076 calls (`stage1/rzx/r16000` 1,058, `stage1/rzx/r48000` 1,010, `stage1/rzx/r28000` 671 and 28 more) |
| Called from | `DrawPortrait`, `DrawSpareLives`, `DrawBearers`, `DrawBearerItems`, `DrawMenuGlobes` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `AddColumnPointers` (`$9FBA`)

**Add the three column pointers HL, HL + 24, HL + 48 of a sprite to the list at IY**

Out: IY 6 on, HL + 48. Builds PanelColumns `$5BD6` for BlitColumns.

Witness: L1 9352 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 97 calls, 22,055 t-states own (0.00 %) |
| Runs (the other recordings) | 9,255 calls (`stage1/rzx/r48000` 1,310, `stage1/rzx/r16000` 1,102, `stage1/rzx/r28000` 734 and 28 more) |
| Called from | `DrawPortrait`, `DrawSpareLives`, `DrawBearers`, `DrawBearerItems`, `DrawMenuGlobes` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5BD6`-`$5BED` (system) |

## player

`src/game/player.asm`

### `HeroTileChecks` (`$A102`)

**Probe the tiles around the hero: deadly tile, floor distance, mud, walls (SK, renamed)**

IX = the hero (`$5B04`). Clears the probe record `$A0FE` (IY) and fills it: +3 the rows down to a floor (FloorDistance `$A1F4`), +0 / +1 a wall at the left / right edge (LeftWallCheck `$A2AC`, RightWallCheck `$A2FA`). While the status `$5C06` is 0 and the normal tile set is in (`$918C` = 0) it first reads the two tiles under the feet (DeadlyTileProbe `$A176`): tile `$A5` under either sets status `$1A` (the fall death, FallDeath `$A888`). Standing (+3 = 0) on tile `$BC` or `$BD` with the normal set stores the tile in `$5C28` and counts passes in `$5C29`; at 50 passes status `$11` (SinkInMud `$AA04`). Off it, `$5C29` = 0. When `$5BA0` is 0 (the hero stands on the lift, LiftPlatform `$AF81`) +3 is forced to 0.

Out: `$A0FE` filled, IY = `$A0FE`; DE kept. Called from HeroUpdate `$A3E1` (`$A50E`, `$A576`), FloatInRoom2C `$A34B`, BalloonRide `$AC35`, BalloonCrash `$AC1A`, BounceUp `$AD17`, JumpArc `$ADAC` and JumpStepY `$AE37`.

Evidence: the `$A5` test never matched in any recording (`$A126` / `$A12B`: 11772 tests, no match); `$BC` / `$BD` matched 26 passes in one rzx segment, the 50-pass sink never came (`$A15A` not executed).

Witness: L1 21714 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 52 calls, 23,847 t-states own (0.00 %) |
| Runs (the other recordings) | 21,662 calls (`stage1/rzx/r30000` 920, `stage1/rzx/r08000` 914, `stage1/rzx/r14000` 868 and 30 more) |
| Called from | `FloatInRoom2C`, `HeroUpdate`, `BalloonRide`, `BounceUp`, `JumpArc`, `JumpStepY` |
| Calls | `DeadlyTileProbe`, `FloorDistance`, `LeftWallCheck`, `RightWallCheck` |
| Reads | `$5BA0` (system); `$5C06` (system); `$5C29` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$A101` (`HeroProbes+3`); 1 more ranges |
| Writes | `$5C28`-`$5C29` (system); `$A0FE`-`$A101` (`HeroProbes`) |

### `DeadlyTileProbe` (`$A176`)

**Read the two tiles under the hero's feet**

IX = the hero. C = the tile at (X + 8, Y + 23), B = the tile at (X + 16, Y + 23), both read from the tile map `$F800` through PixelToTileMap `$A293`. Called only from HeroTileChecks `$A102`, which compares both with `$A5`.

Witness: L1 11772 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 52 calls, 9,408 t-states own (0.00 %) |
| Runs (the other recordings) | 11,720 calls (`stage1/explorers` 790, `stage1/rzx/r14000` 648, `stage1/rzx/r12000` 617 and 22 more) |
| Called from | `HeroTileChecks` |
| Calls | `PixelToTileMap` |
| Reads | `$5B04`-`$5B05` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$F849`-`$F84A` (`TileMap+73`); `$F861`-`$F9FD` (`TileMap+97`) |

### `OnLadder` (`$A193`)

**Is the tile under the middle of the hero's feet a ladder tile? (SK, renamed)**

IX = the hero. Reads the tile at (X + 12, Y + 23). Out: Z set when it is a climbing tile: `$98` or `$99` in every room, also `$92` and `$95` in rooms below `$0C`; with the other tile set (`$918C` not 0) `$C6`, `$C7`, `$CE` or `$CF` instead. X + 12 past `$FF` returns NZ (A = 1).

Called from HeroUpdate `$A3E1` for down (`$A4BA`), up (`$A4D5`) and every pass (`$A52E`: on a ladder the hero neither falls nor lands). Witness of the names: down and up move the hero 2 pixels a pass only while it is Z, with the frames `$20-$23` (ClimbFrame `$A4E8`): 439 climbing passes in 8 rzx segments.

Witness: L1 16548 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 52 calls, 10,783 t-states own (0.00 %) |
| Runs (the other recordings) | 16,496 calls (`stage1/explorers` 790, `stage1/rzx/r40000` 690, `stage1/rzx/r42000` 674 and 30 more) |
| Called from | `HeroUpdate` |
| Calls | `PixelToTileMap` |
| Reads | `$5B04`-`$5B05` (system); `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$F849`-`$F9FD` (`TileMap+73`) |

### `HeadroomRows` (`$A1D3`)

**Rows from the hero's head down to a floor tile, the probe record kept (SK, renamed)**

IX = the hero, IY = `$A0FE`. Runs the floor scan FloorScanFrom `$A208` from (X + 12, Y - 1) instead of under the feet and returns the row count in A (0 = a floor or ceiling tile at the head), Z set when 0. (IY+3) is saved and put back. Called only from FloatInRoom2C `$A34B` (`$A3B4`): a rising hero bounces off a tile at its head.

Witness: L1 69 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 69 calls (`stage1/rzx/r20000` 38, `stage1/rzx/r18000` 31) |
| Called from | `FloatInRoom2C` |
| Calls | `FloorScanFrom` |
| Reads | `$5B04`-`$5B05` (system); `$A101` (`HeroProbes+3`) |
| Writes | `$A101` (`HeroProbes+3`) |

### `FloorDistance` (`$A1F4`)

**Count the tile rows from under the hero's feet down to a floor tile (SK, renamed)**

IX = the hero, IY = `$A0FE`. From the row under the feet (X + 12, Y + 24) each row's tile at that column is looked up in FloorTiles `$A234` (AltFloorTiles `$A264` with the other set); the list runs on into the solid tiles to its `$00` end. (IY+3) = the rows passed before a match: 0 = standing on a floor. When the scan or the start reaches Y `$80` (the bottom of the play window) (IY+3) = 5. Out: HL points at the matched list entry, Z set on a match.

HeroUpdate `$A3E1` reads (IY+3): 0 stand or land, 1-4 fall, 5 or more refuse the drop (RefuseDrop `$A545`) unless the umbrella is in use.

Witness: L1 21714 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 52 calls, 80,129 t-states own (0.00 %) |
| Runs (the other recordings) | 21,662 calls (`stage1/rzx/r30000` 920, `stage1/rzx/r08000` 914, `stage1/rzx/r14000` 868 and 30 more) |
| Called from | `HeroTileChecks` |
| Calls | `FloorScanFrom` (tail), `PixelToTileMap` |
| Reads | `$5B04`-`$5B05` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$A101` (`HeroProbes+3`); `$A234`-`$A292` (`FloorTiles`, `SolidTiles`, `AltFloorTiles`, `AltSolidTiles`); `$F864`-`$F9FE` (`TileMap+100`) |
| Writes | `$A101` (`HeroProbes+3`) |

### `FloorScanFrom` (`$A208`)

**The floor scan from a given point**

A = the start Y, L = the X; IY+3 counts the rows. Entered from FloorDistance `$A1F4` and HeadroomRows `$A1D3`. BC keeps the current point.

Witness: L1 21782 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,611 calls (`stage1/rzx/r18000` 865, `stage1/rzx/r20000` 746) |
| Called from | `HeadroomRows`, `FloorDistance` (tail) |
| Calls | `PixelToTileMap` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$A101` (`HeroProbes+3`); `$A234`-`$A292` (`FloorTiles`, `SolidTiles`, `AltFloorTiles`, `AltSolidTiles`); `$F808` (`TileMap+8`); `$F825`-`$F828` (`TileMap+37`); 5 more ranges |
| Writes | `$A101` (`HeroProbes+3`) |

### `PixelToTileMap` (`$A293`)

**Turn a pixel point into its tile map address (SK)**

L = X, H = Y (pixels). Out: HL = `$F800` + (Y / 8) * 32 + X / 8, the room's tile map (32 x 16). DE kept. The one lookup of every probe here and of the creatures' probes. 241661 calls in all recordings.

Witness: L1 241661 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2,698 calls, 345,296 t-states own (0.02 %) |
| Runs (the other recordings) | 238,963 calls (`stage1/explorers` 15,724, `stage1/rzx/r04000` 10,903, `stage1/rzx/r08000` 9,906 and 30 more) |
| Called from | `DeadlyTileProbe`, `OnLadder`, `FloorDistance`, `FloorScanFrom`, `WallColumnCheck`, `SolidTileAt` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `LeftWallCheck` (`$A2AC`)

**Is there a solid tile in the column of the object's left edge? (SK, renamed)**

IX = the object (the hero or a creature), IY = its probe record. Takes (X, Y) and runs WallColumnCheck `$A2B2`: (IY+0) = 1 when a solid tile is there. Called from HeroTileChecks `$A102` and the creature code `$C0FD`.

Witness: L1 26266 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 778 calls, 31,199 t-states own (0.00 %) |
| Runs (the other recordings) | 25,488 calls (`stage1/explorers` 3,398, `stage1/rzx/r04000` 1,089, `stage1/rzx/r14000` 943 and 30 more) |
| Called from | `HeroTileChecks`, `TestBelow` |
| Calls | `WallColumnCheck` |
| Reads | `$5B04`-`$5B11` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `WallColumnCheck` (`$A2B2`)

**Look for a solid tile in a column 3 or 4 rows high**

HL = the top point (L = X, H = Y). (IY+0) = 0, then each of 3 tile rows from H down (4 when H is not on a row boundary) is compared with SolidTiles `$A24B` (AltSolidTiles `$A271` with the other set); from room `$18` on the list starts at ExtraSolidTiles `$A242` (AltExtraSolidTiles `$A268`). Any match sets (IY+0) = 1.

Witness: L1 49704 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 830 calls, 3,077,127 t-states own (0.16 %) |
| Runs (the other recordings) | 48,874 calls (`stage1/explorers` 4,188, `stage1/rzx/r04000` 2,133, `stage1/rzx/r14000` 1,921 and 30 more) |
| Called from | `LeftWallCheck`, `RightWallCheck` |
| Calls | `PixelToTileMap` |
| Reads | `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$A242`-`$A292` (`ExtraSolidTiles`, `SolidTiles`, `AltFloorTiles`, `AltSolidTiles`); `$F800`-`$F9FE` (`TileMap`) |
| Writes | `$A0FE`-`$A0FF` (`HeroProbes`); `$C12D`-`$C12E` (`TileScanFlags`) |

### `RightWallCheck` (`$A2FA`)

**Is there a solid tile in the column of the object's right edge? (SK, renamed)**

IX = the object, IY = its probe record. WallColumnCheck `$A2B2` at (X + 23, Y) with IY moved up one: the result goes to (IY+1). Called from HeroTileChecks `$A102` and the creature code `$C109`.

Witness: L1 23438 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 52 calls, 5,251 t-states own (0.00 %) |
| Runs (the other recordings) | 23,386 calls (`stage1/rzx/r24000` 1,069, `stage1/rzx/r04000` 1,044, `stage1/rzx/r14000` 978 and 30 more) |
| Called from | `HeroTileChecks`, `TestRight` |
| Calls | `WallColumnCheck` |
| Reads | `$5B04`-`$5B11` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `CreatureFloorBelow` (`$A30B`)

**Is the tile under the middle of the object's feet solid? Result in (IY+1)**

IX = the object, IY = its record. SolidTileAt `$A328` at (X + 12, Y + 24) with IY moved up one. Called only from the creature code `$C121` (3402 calls, 21 rzx segments).

Witness: L1 3402 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,402 calls (`stage1/rzx/r08000` 427, `stage1/rzx/r12000` 379, `stage1/rzx/r22000` 375 and 18 more) |
| Called from | `TestBelowRight` |
| Calls | `SolidTileAt` |
| Reads | `$5B08`-`$5B11` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `CreatureSolidAt` (`$A31F`)

**Is the tile at the middle of the object's top row solid? Result in (IY+0)**

IX = the object, IY = its record. SolidTileAt `$A328` at (X + 12, Y). Called only from the creature code `$C115`.

Witness: L1 138 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 138 calls (`stage1/rzx/r36000` 67, `stage1/rzx/r34000` 38, `stage1/rzx/r40000` 33) |
| Called from | `TestAhead` |
| Calls | `SolidTileAt` |
| Reads | `$5B08`-`$5B09` (system) |

### `SolidTileAt` (`$A328`)

**Compare one tile with the solid list from ExtraSolidTiles**

HL = the pixel point. (IY+0) = 1 when the tile is in ExtraSolidTiles `$A242` (AltExtraSolidTiles `$A268` with the other set) or the solid list after it, else 0.

Witness: L1 3540 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,540 calls (`stage1/rzx/r08000` 427, `stage1/rzx/r34000` 388, `stage1/rzx/r12000` 379 and 18 more) |
| Called from | `CreatureFloorBelow`, `CreatureSolidAt` |
| Calls | `PixelToTileMap` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$918C` (`AltTileset`); `$A242`-`$A292` (`ExtraSolidTiles`, `SolidTiles`, `AltFloorTiles`, `AltSolidTiles`); `$F86A`-`$F9F7` (`TileMap+106`) |
| Writes | `$C131`-`$C132` (`TileScanSecond`) |

### `FloatInRoom2C` (`$A34B`)

**The hero's update in room `$2C`: floating with momentum, bouncing off walls (SK, renamed)**

The room handler of room `$2C` (RoomHandlers `$B7EC`, reached through `$B7DD` and JumpThroughWord `$A6DD` from HeroUpdate `$A3E1`). POP AF drops the return into HeroUpdate, so this replaces the whole update in that room. Status 0 (ClearStatus `$AE84`), frame `$1A`, the probes (HeroTileChecks `$A102`).

The input (`$B87D`) steps the velocity `$5C34` (C = X, B = Y) by 1 a pass towards the held direction, each kept within -3..3. A wall at the leading edge ((IY+1) going right, (IY+0) going left), a floor under the feet going down, or a tile at the head going up (HeadroomRows `$A1D3`) negates that component: the hero bounces. The facing follows the sign of C; X and Y move by the velocity. X below 4 leaves by the left exit (ExitLeft `$A640`); this routine has no right or vertical exit.

Evidence: rzx18000 frames 1769-1997 and rzx20000 frames 0-312 (149 passes); the screen there shows the hero floating in a lab of floating objects. Reached only through the room handler table.

Witness: L1 149 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r20000`, `stage1/rzx/r18000`) |
| Called from | `JumpThroughWord` |
| Calls | `HeroTileChecks`, `HeadroomRows`, `ExitLeft` (tail), `ClearStatus`, `ReadControls` |
| Reads | `$5B04`-`$5B07` (system); `$5C34`-`$5C35` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A0FE`-`$A101` (`HeroProbes`) |
| Writes | `$5B04`-`$5B07` (system); `$5C34`-`$5C35` (system) |

### `HeroUpdate` (`$A3E1`)

**The hero's update, once a main-loop pass: room handler, status, walk, jump, climb, fall, exits (SK)**

Called from the main loop `$9018` (`$902B`) every pass, IX = the hero. In order:

1. The room handler of the current room (`$B7DD`: RoomHandlers `$B7EC` through JumpThroughWord `$A6DD`). A handler that starts with POP (FloatInRoom2C `$A34B`) replaces the rest.

2. IY = `$A0FE`, SP saved in SavedSP `$AF39` (JumpHoleCheck `$AF09` unwinds to it). A frame list in progress (FrameListPtr `$AEED` not 0) plays one frame (FrameListPlay `$AEB9`) and nothing else happens.

3. E = the input (`$B87D`: bit 0 right, 1 left, 2 down, 3 up, 4 fire). Status 0: StatusZeroTriggers `$AF3B` (enter the balloon, the barrel spot of room `$1D`). The position is saved in `$5C09` / `$5C0A`.

4. StatusDispatch `$A6CC`: a status other than 0 runs its handler, which drops the return and ends the update.

5. TeleportPadCheck `$B03B`; standing (probe +3 = 0 from the last pass): ThinkKey `$B02E` (T). With item `$0A` in use (`$5B98`) in room `$14` or `$08`: status 4 (Hover `$AD32`), frame `$1D`, Y - 8.

6. While falling (`$5C04` not 0) the input is ignored. Fire starts a jump (StartJump `$A465`) when the hero stands, is not on the lift (`$5BA0`), not on the unicycle (`$5BFA` = 0) and, in room `$1A`, Y >= `$3A`: status 2, `$5C03` = `$82`, `$5C08` = the input, sound 6 (`$C4B2`).

7. Right / left: X +- 2 and the facing; X >= `$E8` leaves right (ExitRight `$A671`), X < 4 left (ExitLeft `$A640`). Down / up on a ladder tile (OnLadder `$A193`): Y +- 2, the climb frames `$20-$23`; Y >= `$67` leaves down (ExitDown `$A6AE`), above 0 up (ExitUp `$A69B`; in room `$18` the hero hops out of the ladder top with status 3).

8. The probes (HeroTileChecks `$A102`). A wall at the leading edge puts X back. Then: on a ladder nothing more (HeroWalkFrames `$A5E3`); standing: land (`$A5B9`); a drop of 1-4 rows: fall 4 pixels a pass (`$A570`); 5 or more: refuse (RefuseDrop `$A545`).

Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `HeroUpdate` at work](img/routines/HeroUpdate.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 341,015 t-states own (0.02 %) |
| Runs (the other recordings) | 25,247 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 772 and 30 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop` |
| Calls | `SetUpRoom` (tail), `HeroTileChecks`, `OnLadder`, `HeroWalkFrames` (tail), `ExitLeft` (tail), `ExitRight` (tail), `ExitUp` (tail), `ExitDown` (tail), `StatusDispatch`, `SetStatus` (tail), `StartFrameList` (tail), `FrameListPlay` (tail), `RoomToLevelColumn`, `LevelColumnToRoom`, `StatusZeroTriggers`, `ThinkKey`, `TeleportPadCheck`, `RunRoomScript`, `ReadControls`, `PlaySound` (tail) |
| Reads | `$5B04`-`$5B07` (system); `$5B70` (system); `$5B98`-`$5BA0` (system); `$5BFA`-`$5C0A` (system); `$5C28` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); 3 more ranges |
| Writes | `$5B04`-`$5B07` (system); `$5C01`-`$5C0A` (system); `$AF39`-`$AF3A` (`SavedSP`) |

### `HeroWalkFrames` (`$A5E3`)

**End of the hero update: the walk cycle and the item frames**

Clears the refusal count `$5C03` and the falling flag `$5C04`, then (from HeroWalkAnim `$A5EA`, where a fall also comes) sets the frame: a held direction steps the walk cycle 0-3 on every other pass (PassCount `$5C02` bit 0), no direction gives frame 2. On the unicycle (`$5BFA` not 0) the frames are `$3C-$3F`; with item `$0C` in use (`$5B98`) frames 0-3 become `$10-$13`; falling with the umbrella (item 5) 4 rows or more above the floor gives frame `$0B`.

Status 6 enters at Status6Entry `$A5F0` (StatusHandlers `$A72E`): the hero stays in place and only animates; it is set by `$BCB4` (GD).

Witness: L1 15541 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,642 calls (`stage1/rzx/r40000` 621, `stage1/rzx/r38000` 545, `stage1/rzx/r36000` 476) |
| Called from | `HeroUpdate` (tail) |
| Reads | `$5B06` (system); `$5B98` (system); `$5BFA`-`$5C04` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B06` (system); `$5C03`-`$5C04` (system) |

### `ExitLeft` (`$A640`)

**Leave the room by the left edge (SK, renamed)**

The room to the left: same level, column - 1, column 0 wrapping to 11 (RoomToLevelColumn `$AEEF`, LevelColumnToRoom `$AEFD`). From room `$29` the room is ExplorerRooms `$A66C`[Explorer `$5B70`] instead. X = `$E6`, then the room is set up (`$9855`). Called from HeroUpdate `$A3E1`, FloatInRoom2C `$A34B` and JumpArc `$ADAC`. Evidence: 30 exits in 17 rzx segments, 3 of them wrapping; the room `$29` path once (rzx, explorer 0).

Witness: L1 30 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 12 calls (`stage1/rzx/r20000` 4, `stage1/rzx/r06000` 3, `stage1/rzx/r40000` 2 and 2 more) |
| Called from | `FloatInRoom2C` (tail), `HeroUpdate` (tail), `JumpArc` |
| Calls | `SetUpRoom` (tail), `RoomToLevelColumn`, `LevelColumnToRoom` |
| Reads | `$5C01` (system) |
| Writes | `$5B04` (system) |

### `ExitRight` (`$A671`)

**Leave the room by the right edge (SK, renamed)**

From a room of ExplorerRooms `$A66C` the hero goes to room `$29`; else same level, column + 1, 11 wrapping to 0. X = 2, then the room is set up (`$9855`). Called from HeroUpdate `$A3E1`, JumpArc `$ADAC` and BarrelBigRide `$AABA`. Evidence: 38 exits in gameover and 18 rzx segments; the explorer room path once.

Witness: L1 38 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rzx/r08000` 4, `stage1/rzx/r40000` 3, `stage1/rzx/r00000` 2 and 5 more) |
| Called from | `HeroUpdate` (tail), `JumpArc` |
| Calls | `SetUpRoom` (tail), `RoomToLevelColumn`, `LevelColumnToRoom` |
| Reads | `$5C01` (system); `$A66C`-`$A670` (`ExplorerRooms`) |
| Writes | `$5B04` (system) |

### `ExitUp` (`$A69B`)

**Leave the room by the top: the room one level up (SK, renamed)**

Level - 1; on level 0 the hero is put back to `$5C09` / `$5C0A` (ExitBlocked `$A6C2`). Y = `$66`, then the room is set up (`$9855`). Called from HeroUpdate `$A3E1`, BalloonRide `$AC35`, BounceUp `$AD17`, Hover `$AD32`, JumpStepY `$AE37` and LiftUp `$A96B`. Evidence: 13 calls, 5 of them blocked.

Witness: L1 13 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13 calls (`stage1/rzx/r04000` 4, `stage1/rzx/r00000` 2, `stage1/rzx/r02000` 1 and 6 more) |
| Called from | `HeroUpdate` (tail), `BalloonRide`, `BounceUp` (tail), `Hover` (tail), `JumpStepY` |
| Calls | `SetUpRoom` (tail), `RoomToLevelColumn`, `LevelColumnToRoom` |
| Reads | `$5C09`-`$5C0A` (system) |
| Writes | `$5B04`-`$5B05` (system) |

### `ExitDown` (`$A6AE`)

**Leave the room by the bottom: the room one level down (SK, renamed)**

Level + 1; level 6 does not exist, so from level 5 the hero is put back (ExitBlocked `$A6C2`). Y = 2, then the room is set up (`$9855`). Called from HeroUpdate `$A3E1`, BalloonRide `$AC35`, Hover `$AD32`, LiftDown `$A9C4`, JumpHoleCheck `$AF09` and ExitDownSaved `$AE6A`.

Witness: L1 13 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13 calls (`stage1/rzx/r36000` 3, `stage1/rzx/r14500` 2, `stage1/rzx/r23250` 1 and 7 more) |
| Called from | `HeroUpdate` (tail), `LiftDown`, `JumpHoleCheck` (tail) |
| Calls | `SetUpRoom` (tail), `RoomToLevelColumn`, `LevelColumnToRoom` |
| Writes | `$5B05` (system) |

### `JumpHoleCheck` (`$AF09`)

**On the jump's last step over the hole of `$5BA2`: fall to the room below**

A = the step; only step `$10`. OverHole `$AF22` with status 2: SP back to SavedSP `$AF39` and ExitDown `$A6AE`. Evidence: once in an rzx segment.

Witness: L1 2366 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,366 calls (`stage1/rzx/r06500` 225, `stage1/rzx/r30000` 204, `stage1/rzx/r22000` 198 and 21 more) |
| Called from | `JumpStepY` |
| Calls | `ExitDown` (tail), `OverHole` |
| Reads | `$5C06` (system); `$AF39`-`$AF3A` (`SavedSP`) |

### `OverHole` (`$AF22`)

**Is the hero over the hole whose tile map address is `$5BA2`?**

`$5BA2` = 0: carry. Else its column x 8 against the hero's X: no carry when X is within 8 pixels right of it. Also called by `$9A09` (GB).

Witness: L1 26583 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 56,228 t-states own (0.00 %) |
| Runs (the other recordings) | 25,313 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 854, `stage1/rzx/r32000` 773 and 30 more) |
| Called from | `WellFront`, `JumpHoleCheck` |
| Reads | `$5B04` (system); `$5BA2`-`$5BA3` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `ReadControls` (`$B87D`)

**Read the controls; both left and right, or both up and down, read as nothing**

Out: A = the InputBits of ReadDevice `$B894`, or 0 when bits 0 and 1 or bits 2 and 3 are both set. Called by `$A3E1` every pass (`$A3F4`), by `$A34B` and by `$AF81`.

Witness: L1 26612 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The cancel branches (`$B887`, `$B890`) are not executed in any recording (c1, explorers, gameover, the 31 rzx builds).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 119,693 t-states own (0.01 %) |
| Runs (the other recordings) | 25,342 calls (`stage1/explorers` 4,262, `stage1/rzx/r36000` 916, `stage1/rzx/r14000` 853 and 30 more) |
| Called from | `FloatInRoom2C`, `HeroUpdate`, `LiftPlatform` |
| Calls | `ReadDevice` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `ReadDevice` (`$B894`)

**Read the chosen device into InputBits: keyboard, Kempston or Sinclair**

Device `$94AF` (the device menu: 0 keyboard, 1 Kempston, 2 Sinclair). Keyboard (ReadKeyboard `$B8FE`): SPACE fire, Z left, X right, O up, K down (the Help page of the selector: "Z=Left X=Right O=Up K=Down <SPACE> -Jump"). Kempston: IN (`$1F`) AND `$1F`, already in the InputBits order. Sinclair (port `$EFFE`, keys 6-0): 0 fire, 6 left, 7 right, 9 up, 8 down. Out: A = InputBits `$B87C`.

Witness: explorers reads all three (keyboard 849 and Sinclair 853 passes, Kempston in every build).

Witness: L1 26612 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 124,517 t-states own (0.01 %) |
| Runs (the other recordings) | 25,342 calls (`stage1/explorers` 4,262, `stage1/rzx/r36000` 916, `stage1/rzx/r14000` 853 and 30 more) |
| Called from | `ReadControls` |
| Calls | `InputBitsOut` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$94AF` (`InputDevice`); `$B87C` (`InputBits`) |
| Writes | `$B87C` (`InputBits`) |
| Ports in | `$001F`, `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$FEFE` |

### `ReadCursorKeys` (`$B8D4`)

**A Cursor joystick reader no device reaches: 5 left, 8 right, 7 up, 6 down, 0 fire**

The same form as the other readers (HL = InputBits): port `$F7FE` bit 4 (5) left; port `$EFFE` bit 0 (0) fire, bit 2 (8) right, bit 3 (7) up, bit 4 (6) down; then JP `$B930`, but a released 6 returns at once (RET NZ at `$B8F8`) with A = the port byte instead of InputBits. ReadDevice `$B894` sends every device but 0 and 1 to the Sinclair reader, and no instruction of the image refers to `$B8D4`: a fourth device left out of the menu. Not executed in any recording (c1, explorers, gameover, the 31 rzx builds); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadKeyboard` (`$B8FE`)

**The keyboard: SPACE fire, Z left, X right, O up, K down**

Reached from ReadDevice `$B894` when Device `$94AF` is 0. Witness: explorers, 849 passes.

Witness: L1 849 (explorers).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `InputBitsOut` (`$B930`)

**A = InputBits: the end of every reader**

Witness: L1 26612 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 27,519 t-states own (0.00 %) |
| Runs (the other recordings) | 21,080 calls (`stage1/rzx/r36000` 916, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 772 and 29 more) |
| Called from | `ReadDevice` (tail) |
| Reads | `$B87C` (`InputBits`) |

## status

`src/game/status.asm`

### `StatusDispatch` (`$A6CC`)

**Run the handler of the hero's status `$5C06` (SK, renamed)**

Status 0: return. Else the word StatusHandlers `$A72E`[status - 1] is jumped to with C = `$FF` and the return into HeroUpdate `$A3E1` still on the stack: every handler starts with POP (or ends without returning there), so the rest of the update is skipped. Called only from HeroUpdate (`$A40C`): 9430 dispatches in c1, explorers, gameover and 26 rzx segments.

Witness: L1 26144 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `StatusDispatch` at work](img/routines/StatusDispatch.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 102,545 t-states own (0.01 %) |
| Runs (the other recordings) | 24,874 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 772 and 30 more) |
| Called from | `HeroUpdate` |
| Calls | `JumpThroughWord` |
| Reads | `$5C06` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `JumpThroughWord` (`$A6DD`)

**Jump to the word at HL, if it is not 0**

HL = a table entry, DE on the stack. Pops DE, returns when the word is 0, else jumps to it. Shared by StatusDispatch `$A6CC` and the room handler dispatch `$B7DD`.

Witness: L1 35947 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2,487 calls, 138,282 t-states own (0.01 %) |
| Runs (the other recordings) | 33,460 calls (`stage1/explorers` 7,729, `stage1/rzx/r14000` 1,057, `stage1/rzx/r16000` 1,010 and 30 more) |
| Called from | `StatusDispatch`, `RunRoomScript` (tail) |
| Calls | `FloatInRoom2C`, `Room2DAnim`, `Room43Anim`, `FallDeath`, `Room1ADeath`, `CreatureDeath`, `Teleport`, `Frozen`, `RideObject4`, `LiftDown`, `LoseLifeWait`, `BarrelSpot`, `BarrelRide`, `BalloonRide`, `BounceUp`, `Hover`, `JumpArc`, `BalloonRoom`, `SpaceScene`, `CricketBallScript`, `BasketScript`, `SilverCrossScript`, `SnakesRoom17`, `SnakesRoom1A`, `ProfessorScript`, `SilverLiningScript`, `LeverRoom40`, `LeverRoom3E`, `RadiationScript`, `FloorRoom36`, `FloorRoom35` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A72E`-`$A767` (`StatusHandlers`); `$B7EC`-`$B877` (`RoomScripts`) |

### `FlashPose` (`$A770`)

**Status 33: hold frame `$3F` for 64 passes, then the next step of room `$47`**

Set by ExplorerRoom47 `$B18A` when the hero uses item 1 at its spot. `$5C07` counts; at bit 6 RoomStep `$5C41` + 1 and status 0. Not executed in any recording (c1, explorers, gameover, rzx x31); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrinkPose` (`$A783`)

**Status 32: cycle the frames `$3D-$3F` (room `$2E`, item 4 used)**

Set by ExplorerRoom2E `$B263`. Frame `$3D` + (a 0, 1, 2, 2, 1, 0 pattern of `$5C07`); it never ends the status itself: ExplorerRoom2E does after its creature's frame list. Not executed in any recording; known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TelescopeView` (`$A7B9`)

**Status 31: the asteroid in space and the time left to the collision**

Set by LookIntoTelescope `$A822`. On the first pass: the hero hidden (frame `$7F`), room `$28` (the space background) set up (`$9855` with A = `$28`), object 4 (`$5B14`) = the asteroid at X `$75`, Y = 2 x (40 - days), frame `$75`: the fewer the days (`$5BFB`) the lower it stands. CollisionText `$B07C` is printed at `$48A2` (`$94F9`, colour `$0F`), the days, hours and minutes (`$5BFB`, `$5BFC`, `$5BFD`) at `$48C7`, `$48D0` and `$48DB` (`$90E1`). Each later pass reprints the numbers, until `$5C07` reaches `$80`: then room `$12` again and status 0.

Evidence of the countdown order: the text puts DAYS at column 2 and the first number (`$5BFB`) at column 7; c1 frame 23500 holds `$1E`, `$17`, `$0B` at `$5BFB-$5BFD` (30 days, 23 hours, 11 minutes). Not executed in any recording; known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LookIntoTelescope` (`$A822`)

**Status 30: the hero bends to the telescope, then the view**

Set by TelescopeRoom `$B16A`. Plays TelescopeFrames `$A79F` (Status28Anim's tail `$A82C`); at the end status 31 (TelescopeView `$A7B9`). Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Room2DAnim` (`$A828`)

**Status 28: the frame list of room `$2D`, then frozen**

Set by the room `$2D` handler (`$B3A8`, GD). Plays Room2DFrames `$A83B`; at its end the status steps to 29 (Frozen `$A90E`) and the timer is cleared. Evidence: rzx16000 frames 1721-1821 (43 passes, once to the end).

Witness: L1 43 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r16000`) |
| Called from | `JumpThroughWord` |
| Calls | `ClearStatusTimer` (tail), `SetHeroFrame` (tail), `NextFrame` |
| Reads | `$5C06` (system) |
| Writes | `$5C06` (system) |

### `Room43Anim` (`$A851`)

**Status 27: a frame list, then item `$1D` in use and points**

Set by the room `$43` handler (`$B720`, GD). Plays Room43Frames `$A86E`; at the end `$5B98` = `$1D`, `$9E5D`, `$BCF2` with DE = `$004B` (75), status 0. Evidence: rzx38000 frames 2-135 (50 passes).

Witness: L1 50 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r38000`) |
| Called from | `JumpThroughWord` |
| Calls | `DrawPortrait`, `SetHeroFrame` (tail), `NextFrame`, `ClearStatus` (tail), `AddScore` |
| Writes | `$5B98` (system) |

### `FallDeath` (`$A888`)

**Status 26: the fall death: frame `$1C`, sound 0, then dying**

Set when the hero lands after 20 fall passes or more (HeroLand `$A5B9`), on tile `$A5` (HeroTileChecks `$A102`), when the balloon lands falling (BalloonCrash `$AC1A`) and by the creatures of room `$2E` (ExplorerRoom2E `$B2C5`). FallDeathFrames `$A8BF`, then sound 0 and status 18 (StartDying `$AAF0`). Evidence: gameover frames 1363-1371 (the last life), rzx10000, rzx24000.

Witness: L1 9 (gameover, rzx, rzx).

[Animation: `FallDeath` at work](img/routines/FallDeath.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/gameover`, `stage1/rzx/r24000`, `stage1/rzx/r10000`) |
| Called from | `JumpThroughWord` |
| Calls | `DeathFrames` (tail), `StartDying` (tail), `SetHeroFrame` (tail), `NextFrame`, `PlaySound` |

### `Room1ADeath` (`$A88F`)

**Status 25: the death in room `$1A`; the thought for rooms `$17` and `$1A` becomes item `$0C`**

Set by the room `$1A` handler (`$B5CE`, GD). ThinkHints `$A6E6` of rooms `$17` and `$1A` = `$0C`, then Room1ADeathFrames `$A8E6`, sound 4, status 18. Evidence: rzx10000 frames 1943-1958.

Witness: L1 7 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r10000`) |
| Called from | `JumpThroughWord` |
| Calls | `DeathFrames` (tail) |
| Writes | `$A6FD`-`$A700` (`ThinkHints+23`) |

### `CreatureDeath` (`$A89E`)

**Status 24: the death by a creature's touch, sound 3 every pass**

Set by HitExplorer `$C0F9` (a creature's touch, not standing) and by the beam hit `$9262` (RoomEffects: within the beam's X span and 12 rows, status below 4). CreatureDeathFrames `$A8E0` with sound 3 each pass, then status 18. Evidence: rzx06000, rzx22000, rzx32000 (33 passes).

Witness: L1 33 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r32000`, `stage1/rzx/r22000`, `stage1/rzx/r06000`) |
| Called from | `JumpThroughWord` |
| Calls | `StartDying` (tail), `SetHeroFrame` (tail), `NextFrame`, `PlaySound` |

### `SilentDeath` (`$A8A8`)

**Status 23: a death with no sound: the teleport pad of room `$20`, the radiation of room `$3C`, the creature of room `$39`**

Set by Teleport `$A8EA` in room `$20`, by room `$3C`'s script without the pills (`$B796`) and by room `$39`'s creature without the Silver Cross (`$B518`). SilentDeathFrames `$A8C1` with no sound (C = `$FF` from StatusDispatch), then status 18. Not executed in any recording; a clone probe (work/stage2/probe_points.py C: the RZX state at 44000, PillsTaken `$5C3F` = 0, room `$3C` entered from `$3D`) shows it: status 23 at frame 70 (RoomStage `$5C41` = `$15`), status 18 at 225, Lives 3 -> 2 and the restart in room `$3B` (the last checkpoint) at 355.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DeathFrames` (`$A8AB`)

**Play a death's frame list; at its end sound C (none for `$FF`) and status 18**

DE = the list, C = the sound. Shared by statuses 23-26.

Witness: L1 49 (gameover, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/rzx/r10000` 10) |
| Called from | `FallDeath` (tail), `Room1ADeath` (tail) |
| Calls | `StartDying` (tail), `SetHeroFrame` (tail), `NextFrame`, `PlaySound` |

### `Teleport` (`$A8EA`)

**Status 22: the teleport pads of rooms `$30` and `$3D`; the pad of room `$20` kills**

Set by TeleportPadCheck `$B03B`. First pass (`$5C07` = 0): the lift is reset to room `$1F`, Y `$50` (`$5B9E`, `$5B9F`). Room `$30` sends to room `$3D`, room `$3D` to room `$20`, each only while `$5C44` is not 0 (else nothing happens and the status stays); the destination goes into TeleportDest `$A959`. Room `$20`: status 23 (SilentDeath `$A8A8`).

Witness: L1 36 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r34000`, `stage1/rzx/r24750`) |
| Called from | `JumpThroughWord` |
| Calls | `SetUpRoom` (tail), `NextFrame`, `ClearStatus` (tail) |
| Reads | `$5C01`-`$5C07` (system); `$5C44` (system); `$B073`-`$B078` (`TeleportPads`) |
| Writes | `$5B04`-`$5B06` (system); `$5B9E`-`$5B9F` (system); `$5C01`-`$5C07` (system); `$A959` (`TeleportDest`); `$B072` (`PadLatch`) |

### `Frozen` (`$A90E`)

**Status 29: nothing; the hero waits for a room handler**

POP HL, RET: the update ends. Set by GameOver's path `$938D` (GB: the last life, the space scene), the room `$2D` handler (`$B6FB`) and ExplorerRoom46 `$B2EB`; Room2DAnim `$A828` steps into it. Evidence: 413 passes in gameover and 3 rzx segments.

Witness: L1 413 (gameover, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r50000`, `stage1/gameover`, `stage1/rzx/r16000` and 1 more) |
| Called from | `JumpThroughWord` |

### `TeleportStep` (`$A910`)

**Teleport, continued: the pad's frame list with the jump to the other room**

Reached from Teleport `$A8EA` (`$A901`, `$A907`, `$A8EE`). Plays TeleportFrames `$A955`; the byte with bit 7 set is the room: `$5C07` skips it, the room is looked up in TeleportPads `$B073` for the arrival Y and X, PadLatch `$B072` = X (no new trigger on arrival) and the room is set up (`$9855`). The list's `$FF` ends the status. Evidence: two teleports (rzx24750 frames 732-780, rzx34000 frames 1461-1512). The cut puts an entry here so that Frozen `$A90E` holds only its two instructions.

Witness: L1 2 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RideObject4` (`$A95F`)

**Status 21: the hero takes object 4's place, frame `$2D`**

Set by the room `$3F` handler (`$B45A`, GD). The hero's X, Y = object 4's (`$5B14`) every pass. Evidence: 418 passes (rzx28000, rzx32750, rzx34000).

Witness: L1 418 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r28000`, `stage1/rzx/r32750`, `stage1/rzx/r34000`) |
| Called from | `JumpThroughWord` |
| Reads | `$5B14`-`$5B15` (system) |
| Writes | `$5B04`-`$5B06` (system) |

### `LiftUp` (`$A96B`)

**Status 19: the lift up, 2 pixels a pass**

Set by LiftPlatform `$AF81` (up on the platform). In room `$1F` it stops at its stop (LiftAtStop `$A9A9`) and calls `$9AA1` (GB). Y - 2; above the top the room above (ExitUp `$A69B`) and the lift's Y and room (`$5B9F`, `$5B9E`) follow; `$5B9F` = Y + 8. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LiftSetRoom` (`$A99A`)

**The lift is in the hero's room (`$5B9E` = `$5C01`)**

Witness: L1 4 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LiftAtStop` (`$A9A9`)

**Is the lift at its stop in this room? Then status 0**

LiftStops `$A9E6` gives a stop Y for rooms `$1F`, `$2B`, `$37`, `$43`: when the room is listed and `$5B9F` equals it, status 0 (Z); not listed returns NZ.

Witness: L1 263 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 200 calls (`stage1/rzx/r36000` 200) |
| Called from | `LiftDown` |
| Calls | `ClearStatus` (tail) |
| Reads | `$5B9F` (system); `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A9E6`-`$A9ED` (`LiftStops`) |

### `LiftDown` (`$A9C4`)

**Status 20: the lift down, 2 pixels a pass**

Set by LiftPlatform `$AF81` (down on the platform). In room `$43` it stops at Y `$68`. Y + 2; at `$62` the room below (ExitDown `$A6AE`). Evidence: rzx20000 frames 628-805, rzx36000 frames 334-937 (220 passes).

Witness: L1 220 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r36000`, `stage1/rzx/r20000`) |
| Called from | `JumpThroughWord` |
| Calls | `ExitDown`, `LiftAtStop`, `ClearStatus` (tail) |
| Reads | `$5B05` (system); `$5B9F` (system); `$5C01` (system); `$A9E6`-`$A9EB` (`LiftStops`) |
| Writes | `$5B05` (system); `$5B9E`-`$5B9F` (system) |

### `LoseLifeWait` (`$A9EE`)

**Status 18: wait 50 passes, then a life is lost: game over or the respawn (SK)**

`$5C07` counts; at 50: `$5C2A` = `$32` (the main loop's `$902E` sees it and runs the respawn `$9090`), Lives `$5B97` - 1; 0 goes to `$9372` (game over: the space scene), else `$9E96`. Set by StartDying `$AAF0`. Evidence: gameover frames 1374-1502 (the last life), 5 rzx segments. The POKE 43517,182 (SK, the "infinite lives" POKE) changes DEC (HL) at `$A9FD`.

Witness: L1 292 (gameover, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r10000`, `stage1/rzx/r32000`, `stage1/rzx/r24000` and 3 more) |
| Called from | `JumpThroughWord` |
| Calls | `LoseGame` (tail), `DrawSpareLives` (tail) |
| Reads | `$5B97` (system); `$5C07` (system) |
| Writes | `$5B97` (system); `$5C07` (system); `$5C2A` (system) |

### `SinkInMud` (`$AA04`)

**Status 17: sink one row into the mud**

Set by HeroTileChecks `$A102` after 50 passes on tile `$BC` or `$BD`. SinkFrames `$AA22`, then `$5C03` = 3, Y onto the next row down (+8) and status 0. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BarrelSpot` (`$AA3C`)

**Status 13: at the barrel spot of room `$1D`; the barrel item chooses the ride**

Set by StatusZeroTriggers `$AF3B` (room `$1D`, left at the spot). Frame `$17`, facing left; right gives up (status 0). After 5 passes: item 9 in use gives status 14, item `$1C` status 15, item `$1B` status 16 (sound 1); any other item waits. Evidence: rzx16000 frames 479-491 (item 9).

Witness: L1 6 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r16000`) |
| Called from | `JumpThroughWord` |
| Calls | `SetStatus`, `PlaySound` (tail) |
| Reads | `$5B07` (system); `$5B98` (system); `$5C07` (system) |
| Writes | `$5B06`-`$5B07` (system); `$5C07` (system) |

### `BarrelRide` (`$AA6F`)

**Status 14: the ride in barrel item 9: 84 passes along BarrelArc**

X + 2 a pass, Y - BarrelArc `$AAFA`[`$5C07`], facing right, the frame up to `$19`, from pass 40 frame `$1A`. At pass 84 status 0. Evidence: rzx16000 frames 508-745.

Witness: L1 85 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r16000`) |
| Called from | `JumpThroughWord` |
| Calls | `ClearStatus` (tail) |
| Reads | `$5B04`-`$5B07` (system); `$5C07` (system); `$AAFA`-`$AB4D` (`BarrelArc`) |
| Writes | `$5B04`-`$5B07` (system); `$5C07` (system) |

### `BarrelRideShort` (`$AAA7`)

**Status 15: the ride in item `$1C`: BarrelShortArc, fatal after 32 passes**

As BarrelRide `$AA6F` with BarrelShortArc `$AB4E`; at pass 32 frame `$1C` and status 18. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BarrelRideLong` (`$AABA`)

**Status 16: the ride in item `$1B`: on to the next room, fatal**

X + 2 a pass, Y - 1 on every other pair of passes; after 100 passes the room to the right (ExitRight `$A671`) at X 8, Y 8, frame `$1B`, then status 18. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StartDying` (`$AAF0`)

**Status 18: the hero dies (LoseLifeWait counts down)**

Witness: L1 7 (gameover, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rzx/r10000` 2, `stage1/gameover` 1, `stage1/rzx/r24000` 1 and 3 more) |
| Called from | `FallDeath` (tail), `CreatureDeath` (tail), `DeathFrames` (tail) |
| Writes | `$5C06`-`$5C07` (system) |

### `ClearStatusTimer` (`$AAF5`)

**`$5C07` = 0**

Witness: L1 8 (gameover, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx/r16000` 1) |
| Called from | `Room2DAnim` (tail) |
| Writes | `$5C07` (system) |

### `Think` (`$AB6E`)

**Status 10: the hero thinks; ThinkHints decides the idea**

Set by ThinkKey `$B02E` (T). ThinkFrames `$ABEB`; at the end the thought's place: `$5B9A` = Y (- `$18` when Y >= `$18`), `$5B99` = X - `$18` or + `$18` (the side the hero faces; turned at the edges), `$5B9B` = ThinkHints `$A6E6`[room]; status 12 (NoIdea) for `$FF`, else 11 (BrightIdea). Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetHeroFrame` (`$ABC3`)

**(IX+2) = A**

Witness: L1 133 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 133 calls (`stage1/rzx/r38000` 49, `stage1/rzx/r16000` 42, `stage1/rzx/r22000` 10 and 5 more) |
| Called from | `Room2DAnim` (tail), `Room43Anim` (tail), `FallDeath` (tail), `CreatureDeath` (tail), `DeathFrames` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B06` (system) |

### `BrightIdea` (`$ABC7`)

**Status 11: the idea frames, then `$5B9B` = `$FE` and status 0**

IdeaFrames `$ABF4`. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NoIdea` (`$ABD9`)

**Status 12: the no-idea frames (head shaking), then `$5B9B` = `$FE` and status 0**

NoIdeaFrames `$AC0D`. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NextFrame` (`$ABDE`)

**The next frame of the list at DE, timed by `$5C07` (SK, renamed)**

A = DE[`$5C07` / 2], `$5C07` + 1: each frame lasts 2 passes; the lists end with `$FF`.

Witness: L1 178 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 178 calls (`stage1/rzx/r38000` 50, `stage1/rzx/r16000` 43, `stage1/rzx/r24750` 18 and 7 more) |
| Called from | `Room2DAnim`, `Room43Anim`, `FallDeath`, `CreatureDeath`, `DeathFrames`, `Teleport` |
| Reads | `$5C07` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A83B`-`$A850` (`Room2DFrames`); `$A86E`-`$A887` (`Room43Frames`); `$A8BF`-`$A8C0` (`FallDeathFrames`); `$A8E0`-`$A8E9` (`CreatureDeathFrames`, `Room1ADeathFrames`); 1 more ranges |
| Writes | `$5C07` (system) |

### `NextFrameAt` (`$ABE1`)

**The same with the counter at HL**

Called by `$B638` (GD) with its own counter.

Witness: L1 2050 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,872 calls (`stage1/rzx/r44000` 557, `stage1/rzx/r48000` 517, `stage1/rzx/r46000` 508 and 2 more) |
| Called from | `ProfessorScript` |
| Reads | `$B6C1`-`$B6ED` (`ProfFrames`, `LabStep`) |
| Writes | `$B6ED` (`LabStep`) |

### `BalloonCrash` (`$AC1A`)

**Status 9: the balloon falls; landing kills**

Set by BalloonRide `$AC35` at the top of room 3 with item 7. Sinks as BalloonRide does (`$ACC4`); on the ground object 3 (the envelope) is hidden and status 26 (FallDeath `$A888`). Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BalloonRide` (`$AC35`)

**Statuses 7 and 8: in the balloon: rise with item 6 or 7, else sink and step out**

Set by StatusZeroTriggers `$AF3B` (the hero at the balloon), status 8 here. `$5C27` = the room (the balloon goes with the hero), frame `$7F` (the hero is drawn inside the basket by BalloonRoom `$AFD7`). In the air (probe +3 not 0) left and right move 2 pixels (right not in status 7). Item 6 in use: status 8, item 7: status 7; both rise 1 pixel a pass; at the top the room above, in room 3 status 8 hovers and status 7 becomes 9 (BalloonCrash `$AC1A`). Other items: the balloon sinks 2 pixels a pass (the room below at `$66`) and on the ground left or right steps out (status 0). `$5C25` / `$5C26` keep the balloon's X and Y. Evidence: rzx14000 frames 696-1104 (452 passes, item 6); the screen of rzx14000 frame 750 shows the balloon.

Witness: L1 452 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r14500`, `stage1/rzx/r14000`) |
| Called from | `JumpThroughWord` |
| Calls | `HeroTileChecks`, `ExitUp`, `ClearStatus` (tail) |
| Reads | `$5B04`-`$5B05` (system); `$5B98` (system); `$5C01`-`$5C06` (system); `$A0FF`-`$A101` (`HeroProbes+1`) |
| Writes | `$5B04`-`$5B06` (system); `$5C06` (system); `$5C25`-`$5C27` (system) |

### `BounceUp` (`$AD17`)

**Status 5: rise 4 pixels a pass; on a floor the jump arc**

Set by `$BBD5` (GD), which puts the hero on top of an object, frame `$0F`. Y - 4; above the top the room above. When the probes find a floor under the feet: status 2 (JumpArc `$ADAC`). Evidence: gameover, rzx10000, rzx22000 (67 passes).

Witness: L1 67 (gameover, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/gameover`, `stage1/rzx/r10000`, `stage1/rzx/r22000`) |
| Called from | `JumpThroughWord` |
| Calls | `HeroTileChecks`, `ExitUp` (tail), `SetStatus` (tail) |
| Reads | `$5B05` (system); `$A101` (`HeroProbes+3`) |
| Writes | `$5B05` (system) |

### `Hover` (`$AD32`)

**Status 4: hover with item `$0A`, four directions (rooms `$14` and `$08`)**

Set by HeroUpdate `$A3E1` (StartHover `$A42B`). While `$5B98` is `$0A`: frame `$1D`, right / left 2 pixels within 4..`$E6`, up 2 pixels (the room above at the top, except in room `$08`), down 2 pixels (room `$14`: not below Y `$57`; elsewhere the room below at `$67`). Another item ends it (`$5C03` = 2, status 0). Evidence: 4908 passes in c1, explorers and rzx00000, starting near the beginning of play in room `$14` (explorers frame 963); the frames are known from the code, what `$1D` shows needs the screen.

Witness: L1 4908 (c1, explorers, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | run into, not called, 231,133 t-states own (0.01 %) |
| Runs (the other recordings) | run into, not called (`stage1/explorers`, `stage1/rzx/r00000`, `stage1/rzx/r02000`) |
| Called from | `JumpThroughWord` |
| Calls | `ExitUp` (tail), `ClearStatus` (tail) |
| Reads | `$5B04`-`$5B07` (system); `$5B98` (system); `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B04`-`$5B07` (system); `$5C03` (system) |

### `JumpArc` (`$ADAC`)

**Statuses 1, 2, 3: the jump: 17 passes of JumpFrames and JumpRise (SK, renamed)**

The frame is JumpFrames `$AE8D`[`$5C07`]; at step 17 Y goes onto the row and status 0. Else JumpStepY `$AE37` moves Y, then the direction `$5C08` moves X 2 pixels (right: the room to the right at `$E7`; left: the room to the left at X 2 or 1); a wall at the leading edge puts the position back. Status 2 is fire (StartJump `$A465`), 1 the jump off an edge after three refusals, 3 the hop out of room `$18`'s ladder top (no direction). Evidence: 2391 passes in gameover and 23 rzx segments.

Witness: L1 2391 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `JumpArc` at work](img/routines/JumpArc.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r06500`, `stage1/rzx/r22000`, `stage1/rzx/r30000` and 21 more) |
| Called from | `JumpThroughWord` |
| Calls | `HeroTileChecks`, `ExitLeft`, `ExitRight`, `JumpStepY`, `FrameFromTable`, `ClearStatus` (tail) |
| Reads | `$5B04`-`$5B05` (system); `$5C07`-`$5C08` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A0FE`-`$A0FF` (`HeroProbes`) |
| Writes | `$5B04`-`$5B05` (system); `$5C07` (system) |

### `JumpStepY` (`$AE37`)

**One step of the jump's height**

A = the step. JumpHoleCheck `$AF09` first (the last step over a hole falls through). Y - JumpRise `$AE9E`[step]; above the top the room above, at `$68` the room below (ExitDownSaved `$AE6A`). Then the probes: a floor under the feet ends the jump early (frame 2, status 0).

Witness: L1 2366 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,366 calls (`stage1/rzx/r06500` 225, `stage1/rzx/r30000` 204, `stage1/rzx/r22000` 198 and 21 more) |
| Called from | `JumpArc` |
| Calls | `HeroTileChecks`, `ExitUp`, `ClearStatus` (tail), `SetStatus`, `JumpHoleCheck` |
| Reads | `$5B05` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A101` (`HeroProbes+3`); `$AE9E`-`$AEAE` (`JumpRise`) |
| Writes | `$5B05`-`$5B06` (system); `$5C06`-`$5C07` (system) |

### `ExitDownSaved` (`$AE6A`)

**ExitDown with IX and IY kept**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FrameFromTable` (`$AE76`)

**(IX+2) = DE[`$5C07`]**

Witness: L1 2391 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,391 calls (`stage1/rzx/r06500` 230, `stage1/rzx/r30000` 206, `stage1/rzx/r22000` 200 and 21 more) |
| Called from | `JumpArc` |
| Reads | `$5C07` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$AE8D`-`$AE9E` (`JumpFrames`, `JumpRise`) |
| Writes | `$5B06` (system) |

### `ClearStatus` (`$AE84`)

**Status 0 (SK, renamed)**

Witness: L1 332 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 304 calls (`stage1/rzx/r20000` 98, `stage1/rzx/r18000` 73, `stage1/rzx/r06000` 16 and 18 more) |
| Called from | `FloatInRoom2C`, `Room43Anim` (tail), `Teleport` (tail), `LiftAtStop` (tail), `LiftDown` (tail), `BarrelRide` (tail), `BalloonRide` (tail), `Hover` (tail), `JumpArc` (tail), `JumpStepY` (tail), `CricketBallScript` (tail), `BasketScript` (tail) |
| Calls | `SetStatus` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5C06`-`$5C07` (system) |

### `SetStatus` (`$AE85`)

**Status = A, the status timer `$5C07` = 0 (SK)**

Every status change but a few direct writes (`$A15C`, `$A42D`, `$A476`, `$A564`, `$AC90`, `$AC97`, `$ACC0`, `$AF60`, `$AF7D` and some in GD) goes through here.

Witness: L1 360 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 203 calls (`stage1/rzx/r20000` 101, `stage1/rzx/r06000` 17, `stage1/rzx/r22000` 15 and 10 more) |
| Called from | `LoseGame` (tail), `HeroUpdate` (tail), `BarrelSpot`, `BounceUp` (tail), `JumpStepY`, `ClearStatus`, `LiftPlatform`, `TeleportPadCheck` (tail), `CricketBallScript` (tail), `SnakesRoom1A` (tail), `ProfessorScript`, `HitExplorer` (tail) |
| Writes | `$5C06`-`$5C07` (system) |

### `StartFrameList` (`$AEAF`)

**FrameListPtr = HL: a frame list replaces the hero's update until `$FF`**

Witness: L1 7 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/rzx/r00000` 4, `stage1/rzx/r22000` 2, `stage1/rzx/r02000` 1) |
| Called from | `HeroUpdate` (tail) |
| Writes | `$AEED`-`$AEEE` (`FrameListPtr`) |

### `FrameListStep` (`$AEB3`)

**A frame list step if one is running (an entry no code uses)**

HeroUpdate `$A3E1` makes the same test inline (`$A3EC`) and jumps to FrameListPlay `$AEB9`. No reference to `$AEB3` in the code; not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FrameListPlay` (`$AEB9`)

**One frame of the list at HL; `$FF` ends it**

Witness: L1 224 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 224 calls (`stage1/rzx/r00000` 128, `stage1/rzx/r22000` 64, `stage1/rzx/r02000` 32) |
| Called from | `HeroUpdate` (tail) |
| Reads | `$AECD`-`$AEEC` (`RefuseFrames`) |
| Writes | `$5B06` (system); `$AEED`-`$AEEE` (`FrameListPtr`) |

### `RoomToLevelColumn` (`$AEEF`)

**B = room / 12 (the level), C = room mod 12 (the column) (SK)**

Witness: L1 92 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 92 calls (`stage1/rzx/r04000` 8, `stage1/rzx/r00000` 7, `stage1/rzx/r40000` 6 and 25 more) |
| Called from | `HeroUpdate`, `ExitLeft`, `ExitRight`, `ExitUp`, `ExitDown` |
| Reads | `$5C01` (system) |

### `LevelColumnToRoom` (`$AEFD`)

**Room = B * 12 + C (SK)**

Witness: L1 87 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 87 calls (`stage1/rzx/r00000` 7, `stage1/rzx/r40000` 6, `stage1/rzx/r20000` 5 and 25 more) |
| Called from | `HeroUpdate`, `ExitLeft`, `ExitRight`, `ExitUp`, `ExitDown` |
| Writes | `$5C01` (system) |

## roomscripts

`src/game/roomscripts.asm`

### `StatusZeroTriggers` (`$AF3B`)

**In status 0: enter the balloon; room `$1D`'s barrel spot**

Room `$1D`: left held at Y `$48` with X `$1C-$1F`: X = `$1E`, status 13 (BarrelSpot `$AA3C`). Else in the balloon's room `$5C27` within 2 pixels of `$5C25` / `$5C26`: status 7.

Witness: L1 16719 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 53 calls, 3,591 t-states own (0.00 %) |
| Runs (the other recordings) | 16,666 calls (`stage1/explorers` 795, `stage1/rzx/r40000` 692, `stage1/rzx/r42000` 675 and 30 more) |
| Called from | `HeroUpdate` |
| Reads | `$5B04`-`$5B05` (system); `$5C01` (system); `$5C25`-`$5C27` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B04` (system); `$5C06` (system) |

### `LiftPlatform` (`$AF81`)

**The lift: object 4 at X `$24`, Y `$5B9F`; up or down on it starts a ride**

Called by the main loop (`$9028`) when the room is the lift's (`$5B9E`). On the platform (Y = `$5B9F` - 8, X `$12-$37`) `$5BA0` = 0; at X `$1A-$2F`, status 0, 19 or 20, down gives status 20, up 19. Object 4 frame `$9F`. Evidence: 1406 calls in 6 rzx segments.

Witness: L1 1406 (rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,406 calls (`stage1/rzx/r36000` 684, `stage1/rzx/r38000` 235, `stage1/rzx/r20000` 183 and 3 more) |
| Called from | `MainLoop` |
| Calls | `SetStatus`, `ReadControls` |
| Reads | `$5B04`-`$5B05` (system); `$5B9F` (system); `$5C06` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B16` (system); `$5BA0` (system) |

### `BalloonRoom` (`$AFD7`)

**The room handler of rooms 3 and `$0F`: draw the balloon**

In the balloon's room (`$5C27`), unless the hero is dying (status 18 or 26): object 4 (the basket) at `$5C25` / `$5C26`, object 3 (the envelope) 16 pixels above. Frames: `$99` empty, `$24` with the hero (statuses 7-9, facing as the hero); the envelope `$9A`, hidden (`$7F`) in status 9. Evidence: rzx14000, rzx14500 (1017 passes).

Witness: L1 1017 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r14000`, `stage1/rzx/r14500`) |
| Called from | `JumpThroughWord` |
| Reads | `$5B07` (system); `$5C01`-`$5C06` (system); `$5C25`-`$5C27` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B10`-`$5B17` (system) |

### `ThinkKey` (`$B02E`)

**T held: status 10 (think)**

Port `$FBFE` is the half row Q W E R T; bit 4 is T (the instructions' Think). SK took it for ENTER. Not taken in any recording.

Witness: L1 16037 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 53 calls, 2,298 t-states own (0.00 %) |
| Runs (the other recordings) | 15,984 calls (`stage1/explorers` 795, `stage1/rzx/r40000` 692, `stage1/rzx/r42000` 673 and 30 more) |
| Called from | `HeroUpdate` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports in | `$FBFE` |

### `TeleportPadCheck` (`$B03B`)

**On a teleport pad: status 22**

TeleportPads `$B073`: room, Y, X; the hero at that Y with X in X..X+7 sets status 22 (Teleport `$A8EA`) unless PadLatch `$B072` is set; off every pad PadLatch = 0.

Witness: L1 16714 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 53 calls, 10,023 t-states own (0.00 %) |
| Runs (the other recordings) | 16,661 calls (`stage1/explorers` 795, `stage1/rzx/r40000` 692, `stage1/rzx/r42000` 675 and 30 more) |
| Called from | `HeroUpdate` |
| Calls | `SetStatus` (tail) |
| Reads | `$5B04`-`$5B05` (system); `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B072`-`$B07B` (`PadLatch`, `TeleportPads`) |
| Writes | `$B072` (`PadLatch`) |

### `KeyRoomDoneFlag` (`$B165`)

**A = `$5C00`, Z when 0**

Called by the room `$2D` handler `$B370`.

Witness: L1 346 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 346 calls (`stage1/rzx/r16000` 245, `stage1/rzx/r18000` 101) |
| Called from | `CricketBallScript` |
| Reads | `$5C00` (system) |

### `TelescopeRoom` (`$B16A`)

**The room handler of room `$12`: right at the telescope starts status 30**

Status 0, the hero at X `$C0`, Y `$40`, right held: status 30. Not executed in any recording (room `$12` not reached).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExplorerRoom47` (`$B18A`)

**Room `$47` (explorer 4): item 1 at the creature, or be eaten**

`$5C00` set: nothing. RoomStep `$5C41` 0: object 4 at `$80`, `$60`, frame `$64`. 1: its frames `$64-$67`; with the hero left of X `$B4`: at Y `$60` with item 1 in use status 33 (FlashPose `$A770`), else touching it: eaten (step 4, status 18). 2-3: two screen flashes (`$916A`), then `$5C00` is set. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExplorerRoom2F` (`$B22D`)

**Room `$2F` (explorer 2): with item 0 the hero rides the unicycle across**

At Y `$48` with X `$54-$B3`: item 0 in use sets `$5BFA` = `$3C` (the unicycle frames, no jump); else left of `$96` frame `$3B`, Y `$4E`, status 18. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExplorerRoom2E` (`$B263`)

**Room `$2E` (explorer 1): item 4 at the creature, or it kills**

Object 4 at `$A0`, `$48`. Left of `$B2`: touching it status 26. At X `$B2`, Y `$48` with item 4: status 32 (DrinkPose `$A783`), its frame list Room2EFrames `$B2D7`, then status 0. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExplorerRoom46` (`$B2EB`)

**Room `$46` (explorer 3): item 3 rides the creature to the left, else death**

Object 4 at `$C8`, `$48`. Left of `$DC` without item 3: status 18. With it: the hero hidden, status 29, object 4 walks to X `$A0`, the hero at `$94`, `$3E` and status 1. Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CricketBallScript` (`$B370`)

**Room `$2D`: throw the Cricket Ball, and the Formula falls into the explorer's hands**

The room script of room `$2D` (RoomScripts `$B7EC`). Does nothing once BallThrown `$5C00` is set (TestBallThrown `$B165`). Stage 0 (RoomStage `$5C41` = 0) puts an object in slot `$5B10` (X `$64`, Y `$48`, frame `$4F`; the target) every pass and waits for the explorer to stand at X `$DC`, Y `$48` holding the Cricket Ball (HeldItem `$5B98` = 2); then clears the explorer's facing bit (IX+3 bit 7), goes to stage 1 and sets status `$1C` (Room2DAnim `$A828` through the status table `$A72E`; stage 1 then waits for the throw frame).

Stage 1 waits for the explorer's frame `$3E` (the throw pose), then puts the ball in slot `$5B14` (X `$C8`, Y `$39`, frame `$39`). Stage 2 flies the ball 4 pixels left and 1 down a pass until Y `$52`, then steps the target's frame (`$4F` to `$50`) and drops the Formula from the top: slot `$5B14` X `$DC`, Y `$08`, frame `$8F` (`$80` + 15; frames `$80` + n show item n, as the professor's bubble does too: inferred from the two uses, a run request). Stage 3 lowers it 1 pixel a pass to Y `$48` (the explorer's hands), then sets BallThrown, hides the slot, makes the Formula (`$0F`) the held item, redraws the hand icon (`$9E5D`) and clears the status (`$AE84`).

Witness: rzx16000 runs stages 0-2 (the throw at `$B3A1` once, the hit at `$B3DB` once), rzx18000 stage 3 (`$B3F5` once): the RZX run gets the Formula here.

Witness: L1 346 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r16000`, `stage1/rzx/r18000`) |
| Called from | `JumpThroughWord` |
| Calls | `DrawPortrait`, `ClearStatus` (tail), `SetStatus` (tail), `KeyRoomDoneFlag` |
| Reads | `$5B04`-`$5B15` (system); `$5B98` (system); `$5C41` (system) |
| Writes | `$5B07`-`$5B17` (system); `$5B98` (system); `$5C00` (system); `$5C41` (system) |

### `BasketScript` (`$B409`)

**Room `$3F`: the basket that carries the explorer across the room**

The room script of room `$3F`. The basket is slot `$5B14` (frame `$9E`: item sprite `$80` + 30, SK "Busket"). Stage 0 places it at the side away from the explorer: X `$D8` (the right end) with BasketSide `$5C40` = 1 when the explorer is left of X `$C8`, else X `$08` with BasketSide 0; Y `$30`.

Stage 1: the basket travels toward the explorer one pixel a pass, only while the lever of rooms `$3E` and `$40` allows it: from the right end (BasketSide 1) while LeverState `$5C42` is not 0 (BasketToLeft `$B4B0`), from the left end (BasketSide 0) while LeverState is 0 (BasketToRight `$B47E`); a blocked move leaves E as the caller had it (known only from the code). At the end of its way (E = 0) it waits for the explorer to come near (`$9140`); then stage 2, BasketSide flipped, status `$15` (RideObject4 `$A95F`). Stage 2 carries it to the other end whatever the lever (BasketRight `$B483` / BasketLeft `$B4B5`); at the end the explorer is set 8 pixels higher (IX+1 - 8), stage 3 (the script then does nothing until the room is entered again) and the status is cleared (`$AE84`).

Witness: rzx28000 and rzx32750 each run stage 0 and the ride (`$B44E` once each), rzx28000 and rzx34000 the arrival (`$B471`).

Witness: L1 870 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r28000`, `stage1/rzx/r32750`, `stage1/rzx/r34000`) |
| Called from | `JumpThroughWord` |
| Calls | `Near`, `ClearStatus` (tail), `BasketToRight`, `BasketRight`, `BasketToLeft`, `BasketLeft` |
| Reads | `$5B04`-`$5B05` (system); `$5C40`-`$5C41` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B05`-`$5B16` (system); `$5C06` (system); `$5C40`-`$5C41` (system) |

### `BasketToRight` (`$B47E`)

**Move the basket right one pixel if the lever selects the right end**

Returns at once (E unchanged) when LeverState `$5C42` is not 0; else BasketRight `$B483`. Called by BasketScript `$B409` in stage 1.

Witness: L1 209 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 209 calls (`stage1/rzx/r32750` 209) |
| Called from | `BasketScript` |
| Reads | `$5B14`-`$5B15` (system); `$5C42` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B15` (system) |

### `BasketRight` (`$B483`)

**Move the basket right one pixel, along the track's profile**

IY = the basket slot `$5B14`. Out: E = 0 when it is already at the right end (X `$D8`), else E = 1 and X + 1. The track: while X is below `$38` the basket also rises 2 pixels a pass (Y - 2, not above Y 8); from X `$C8` on it sinks 2 a pass back to Y `$30` (BasketRightTail `$B4A3`); between them it keeps its height.

Witness: L1 418 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 209 calls (`stage1/rzx/r28000` 209) |
| Called from | `BasketScript` |
| Reads | `$5B14`-`$5B15` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B15` (system) |

### `BasketRightTail` (`$B4A3`)

**The right end of the track: from X `$C8` sink 2 pixels a pass to Y `$30`**

Entered from BasketRight `$B483` with A = the new X, B = Y.

Witness: L1 322 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BasketToLeft` (`$B4B0`)

**Move the basket left one pixel if the lever selects the left end**

Returns at once when LeverState `$5C42` is 0; else BasketLeft `$B4B5`.

Witness: L1 209 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 209 calls (`stage1/rzx/r28000` 209) |
| Called from | `BasketScript` |
| Reads | `$5B14`-`$5B15` (system); `$5C42` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B15` (system) |

### `BasketLeft` (`$B4B5`)

**Move the basket left one pixel, along the track's profile**

Out: E = 0 at the left end (X 8), else E = 1 and X - 1. While X is below `$1C` the basket sinks 2 pixels a pass (Y + 2, below `$30`); from X `$7B` down to `$1C` it rises 2 a pass, not above Y 8 (BasketLeftTail `$B4D5`); above `$7B` it keeps its height.

Witness: L1 418 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 209 calls (`stage1/rzx/r32750` 148, `stage1/rzx/r34000` 61) |
| Called from | `BasketScript` |
| Reads | `$5B14`-`$5B15` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B15` (system) |

### `BasketLeftTail` (`$B4D5`)

**From X `$7B` down to `$1C` rise 2 pixels a pass, not above Y 8**

Entered from BasketLeft `$B4B5` with A = the new X, B = Y.

Witness: L1 376 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SilverCrossScript` (`$B4E2`)

**Room `$39`: the creature that flees from the Silver Cross**

The room script of room `$39`. The creature is slot `$5B10` (X `$A4`, Y `$40`, frame `$40`, placed at stage 0). CrossState `$5C45`: 0 waiting, 1 fleeing, `$FF` gone. Waiting, it does nothing until the explorer's Y is below `$48` and his X `$62` or more; then if he holds the Silver Cross (HeldItem `$5B98` = `$1D`) it starts to flee, else it turns to him (IX+3 bit 7 set, frame `$44`) and, if the status is below 4, sets status `$17` (SilentDeath `$A8A8`).

Fleeing: X + 2 a pass, frames `$41-$44` by PassCount (`$5C02` / 2 & 3); at X `$E6` it is gone: +150 score (AddScore `$BCF2`) and frame `$7F` every pass after.

Witness: rzx40000 runs it 273 times: the placing (`$B4ED`) once, the flight (`$B540`) 33 times, the score (`$B538`) once. The attack branch (`$B518`) is not executed in any recording (c1, explorers, gameover, the 31 rzx builds).

Witness: L1 273 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r40000`) |
| Called from | `JumpThroughWord` |
| Calls | `AddScore` |
| Reads | `$5B04`-`$5B13` (system); `$5B98` (system); `$5C02` (system); `$5C41`-`$5C45` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B10`-`$5B13` (system); `$5C41`-`$5C45` (system) |

### `SnakesRoom17` (`$B55A`)

**Room `$17`: the two snakes that strike unless charmed by the Flute**

The room script of room `$17`: RunSnakes `$B57C` over two objects from slot `$5B0C` (the room's two still creatures, frames `$51`, RoomCreatures `$C266`). Witness: rzx04000 and rzx06000 run it 297 times.

Witness: L1 297 (rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r06000`, `stage1/rzx/r04000`) |
| Called from | `JumpThroughWord` |
| Reads | `$5B0E`-`$5B12` (system); `$5B98` (system); `$5C01`-`$5C02` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B0E`-`$5B12` (system) |

### `SnakesRoom1A` (`$B562`)

**Room `$1A`: three snakes that strike unless charmed by the Flute**

The room script of room `$1A`. Stage 0 copies SnakeTemplate `$B5D1` into the slots `$5B0C`, `$5B10`, `$5B14` (X `$44`, `$70`, `$94`, Y `$60`, frames `$51-$53`). Then every pass, for each of the 3 (2 in room `$17`, from SnakesRoom17 `$B55A`): frame `$7F` (gone) is skipped; frame `$55` (struck the pass before) becomes `$7F` and sets status `$19` (Room1ADeath `$A88F`); else the frame steps through `$51-$54` (+ PassCount bit 0, back to `$51` after `$54`), and the snake strikes (frame `$55`) when its X equals the explorer's X rounded down to 4 pixels. The Flute (HeldItem `$5B98` = `$0C`) stops the strike: in room `$17` always, in room `$1A` only while the explorer's Y is below `$3A` (at Y `$3A` or more the alignment test runs without it).

Witness: rzx08000, rzx10000, rzx12000 run it 437 times; the strike (`$B5C2`) and the bite (`$B5C8`) once each, in rzx10000.

Witness: L1 437 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r08000`, `stage1/rzx/r10000`, `stage1/rzx/r12000`) |
| Called from | `JumpThroughWord` |
| Calls | `SetStatus` (tail) |
| Reads | `$5B04`-`$5B16` (system); `$5B98` (system); `$5C01`-`$5C02` (system); `$5C41` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B5D1`-`$B5DC` (`SnakeTemplate`) |
| Writes | `$5B0C`-`$5B17` (system); `$5C41` (system) |

### `ProfessorScript` (`$B5DD`)

**Room `$3B`, the lab: Professor Eyestrain asks for six items, the sixth ends the game**

The room script of room `$3B` (the lab). The professor is slot `$5B14`, his speech bubble slot `$5B10` (its frame `$80` + the item he wants: an item sprite). Every pass: when the explorer is near him (`$9140`) holding WantedItem `$5C3C`, the item is given: HeldItem = `$FF`, LastGift `$5C3E` = the item, the items of the room are scanned again (`$B93F`), the hand icon redrawn (`$9E5D`), +150 score, GiftCount `$5C3D` + 1; the sixth gift ends the game (ProfessorEnding `$B6EE`).

ProfState `$5BA1` (0 on room entry): 0 places him (X `$1A`, Y `$48`, the bubble at Y `$30`) and sets 1; 1 (bits 0-6) he walks (ProfWalk `$B676`) with bit 7 the direction; 2 he plays the frames of ProfFrames `$B6C1` one a pass through `$ABE1` (step LabStep `$B6ED`) and goes back to 1 at their end mark `$FF`; while bit 7 is clear (he walks right) the first frame `$4D` ends the sequence instead, so he asks only on his way left. Each new frame `$4D` (his asking pose) shows the bubble: WantedItem = WantedItems[GiftCount] (`$B6BB`), the bubble frame `$80` + that item. InitGame writes `$FF` at `$8FA6`, but its clear of `$5BFA-$5C8D` (`$8FBE`) runs after and zeroes `$5C3C`: WantedItem is 0 (the Unicycle) until he first asks (rzx44000 frames 0-415 and rzx24750 frame 613: `$5C3C` = 0). WantedItem is not reset after a gift (rzx44000 frames 460-723: `$0F` kept).

Witness: rzx42000-rzx50000 run it 2293 times; the bubble (`$B65E`) 11 times, the gifts (`$B5EF`) 6 times (rzx44000 2, rzx46000 2, rzx48000 1, rzx50000 1), the ending once (rzx50000).

Witness: L1 2293 (rzx, rzx, rzx, rzx, rzx).

[Animation: `ProfessorScript` at work](img/routines/ProfessorScript.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r44000`, `stage1/rzx/r46000`, `stage1/rzx/r48000` and 2 more) |
| Called from | `JumpThroughWord` |
| Calls | `Near`, `SetUpRoom`, `DrawPortrait`, `NextFrameAt`, `SetStatus`, `SpawnRoomItems`, `AddScore` |
| Reads | `$5B14`-`$5B17` (system); `$5B98`-`$5BA1` (system); `$5C02` (system); `$5C3C`-`$5C3D` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B6BB`-`$B6C0` (`WantedItems`) |
| Writes | `$5B06`-`$5B17` (system); `$5B98`-`$5BA1` (system); `$5BFE`-`$5C01` (system); `$5C3C`-`$5C3E` (system); `$B6ED` (`LabStep`) |

### `ProfessorEnding` (`$B6EE`)

**The sixth gift: on to room `$28` and the ending**

Room = `$28`, the room set up (`$9855`), GameWon `$5BFE` = `$1D`, status `$1D` (Frozen `$A90E`); SpaceScene `$B0B6`, room `$28`'s script, plays the ending (and sets GameOver `$5BFF`), `$5B06` = `$7F`. Called by ProfessorScript `$B5DD`. Witness: rzx50000 runs it once, before the ending at frame 729.

Witness: L1 1 (rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SilverLiningScript` (`$B704`)

**Room `$43`: stand at one spot holding the Silver Lining**

The room script of room `$43`. When the explorer stands at Y `$20` with X from `$76` to `$83`, holds the Silver Lining (HeldItem `$5B98` = `$0D`) and the status is 0, sets status `$1B` (Room43Anim `$A851`). Witness: rzx36000-rzx40000 run it 737 times; the explorer stands there with another item 100 times (rzx38000); the trigger (`$B71E`) is not executed in any recording (c1, explorers, gameover, the 31 rzx builds).

Witness: L1 737 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r36000`, `stage1/rzx/r38000`, `stage1/rzx/r40000`) |
| Called from | `JumpThroughWord` |
| Reads | `$5B04`-`$5B05` (system); `$5B98` (system); `$5C06` (system) |

### `LeverRoom40` (`$B723`)

**Room `$40`: the lever at X 8**

The room script of room `$40`: slot `$5B14` at X 8, then LeverScript `$B735`. Witness: rzx28000-rzx32750 run it 1036 times.

Witness: L1 1036 (rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r32000`, `stage1/rzx/r32750`, `stage1/rzx/r30000` and 1 more) |
| Called from | `JumpThroughWord` |
| Calls | `Near`, `LeverScript` (tail), `LeverMirror` |
| Reads | `$5C40`-`$5C43` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B16` (system); `$5C40`-`$5C42` (system) |

### `LeverRoom3E` (`$B72D`)

**Room `$3E`: the lever at X `$DC`**

The room script of room `$3E`: slot `$5B14` at X `$DC`, then LeverScript `$B735`. Witness: rzx26000, rzx28000, rzx34000 run it 571 times.

Witness: L1 571 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r34000`, `stage1/rzx/r26000`, `stage1/rzx/r28000`) |
| Called from | `JumpThroughWord` |
| Calls | `Near`, `LeverScript`, `LeverMirror` |
| Reads | `$5B98` (system); `$5C42`-`$5C43` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B14`-`$5B16` (system); `$5C40` (system) |

### `LeverScript` (`$B735`)

**The lever of rooms `$3E` and `$40`: fit the Switch, then pull it to send the basket**

IY = slot `$5B14`, Y `$12`. Frame `$56` before the Switch is fitted, `$57` after (SwitchFitted `$5C43` not 0). Not fitted: when the explorer comes near (`$9140`) holding the Switch (HeldItem `$5B98` = `$10`) it is fitted: HeldItem = `$FF`, SwitchFitted = `$FF`, the hand icon redrawn. Fitted (in both rooms: one flag): the lever's mirror bit (IY+3 bit 7) shows LeverState `$5C42` (set when 0), and each new touch (LeverDebounce `$5C40` from 0 to 1) flips LeverState; away from the explorer LeverDebounce is 0 again. LeverState chooses the end of room `$3F` the basket waits at (BasketScript `$B409`).

Witness: the Switch is fitted once (`$B751`, rzx28000), the lever pulled twice (`$B770`, rzx28000 and rzx32750).

Witness: L1 1607 (rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 279 calls (`stage1/rzx/r28000` 279) |
| Called from | `LeverRoom40` (tail), `LeverRoom3E` |
| Calls | `Near`, `DrawPortrait` (tail), `LeverMirror` |
| Reads | `$5B98` (system); `$5C40`-`$5C43` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B15`-`$5B16` (system); `$5B98` (system); `$5C40`-`$5C43` (system) |

### `LeverMirror` (`$B779`)

**Set the lever's mirror bit when A = 0, clear it otherwise**

A = LeverState `$5C42`, IY = the lever slot. Out: IY+3 bit 7 set when A = 0. Called from LeverScript `$B735` (`$B75F`) and fallen into after a flip (`$B778`).

Witness: L1 1338 (rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,338 calls (`stage1/rzx/r32000` 701, `stage1/rzx/r34000` 274, `stage1/rzx/r28000` 141 and 2 more) |
| Called from | `LeverRoom40`, `LeverRoom3E`, `LeverScript` |
| Reads | `$5B17` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B17` (system) |

### `RadiationScript` (`$B784`)

**Room `$3C`: without the Anti Radiation Pills the explorer dies**

The room script of room `$3C`. RoomStage `$5C41` counts the passes in the room to `$14`; at `$14`, if PillsTaken `$5C3F` is 0 (the pills, item `$16`, never picked up: PickUpItem `$BB96` sets it), stage `$15` and status `$17` (SilentDeath `$A8A8`); with the pills it stays at `$14`. Witness: rzx26000 runs it 214 times, PillsTaken set (rzx14500 picks the pills up, `$BB96` once); the death branch (`$B796`) is not executed in any recording (c1, explorers, gameover, the 31 rzx builds).

Witness: L1 214 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r26000`) |
| Called from | `JumpThroughWord` |
| Reads | `$5C3F`-`$5C41` (system) |
| Writes | `$5C41` (system) |

### `FloorRoom36` (`$B79C`)

**Room `$36`: the flickering hazard floor, 21 tiles of row 10 from column 0**

B = 21 tiles from the tile map's `$F940` (row 10), then FlickerFloor `$B7A8`. Witness: rzx20000 runs it 155 times.

Witness: L1 155 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r20000`) |
| Called from | `JumpThroughWord` |
| Calls | `FlickerFloor` (tail) |

### `FloorRoom35` (`$B7A3`)

**Room `$35`: the flickering hazard floor, 11 tiles of row 10 from column 20**

B = 11 tiles from `$F954`, then FlickerFloor `$B7A8`. Witness: rzx20000 runs it 187 times.

Witness: L1 187 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r20000`) |
| Called from | `JumpThroughWord` |
| Calls | `FlickerFloor` |

### `FlickerFloor` (`$B7A8`)

**Write the hazard tiles `$BC` / `$BD` along the floor, alternating, and keep slot `$5B14` on the explorer**

B = the tile count, HL = the first tile map byte. For each tile (the loop runs the whole body again): Y of the creature slots `$5B09`, `$5B0D`, `$5B11` = 0, slot `$5B14` at the explorer's X and 8 pixels below him (not below Y `$5A`), then the tile `$BC` + (B & 1) XOR (PassCount / 2 & 1) written through `$9A4D`. So the floor alternates `$BC` / `$BD` tile by tile and swaps every second pass; `$BC` and `$BD` are the tiles `$A102` counts when stood on (SK: 50 of them set status `$11`, SinkInMud `$AA04`; GC's range). What slot `$5B14` shows here is known only from the code (a run request).

Witness: L1 5312 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 342 calls (`stage1/rzx/r20000` 342) |
| Called from | `FloorRoom36` (tail), `FloorRoom35` |
| Calls | `SetTileBuffer` |
| Reads | `$5B04`-`$5B05` (system); `$5C02` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5B09`-`$5B15` (system) |

### `RunRoomScript` (`$B7DD`)

**Run the script of the room: the word of RoomScripts `$B7EC`**

HL = RoomScripts + 2 x Room (`$5C01`), then `$A6DD` jumps to the word (none when 0), with DE kept. Called every pass by `$A3E1` with IX = the explorer object `$5B04`.

Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 102,767 t-states own (0.01 %) |
| Runs (the other recordings) | 25,247 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 772 and 30 more) |
| Called from | `HeroUpdate` |
| Calls | `JumpThroughWord` (tail) |
| Reads | `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `BridgeEffect` (`$BA97`)

**Rooms `$19` and `$3A`: the expanding bridge across the tile map's row 11**

A = the room. BridgeState `$5C0C` (0 on room entry, `$9880`): 0 idle; bits 0-6 the tile being drawn (1-`$10`); bit 7 the second half. Idle, the bridge starts when the explorer stands at the left end (X `$2C-$35`) or the right end (X `$B2-$B7`) holding the ACME Expanding Bridge (HeldItem `$5B98` = `$0B`) in room `$19`; in room `$3A` it starts once the professor has an item (LastGift `$5C3E` not 0) or with the Formula in hand (`$0F`). From the left end BridgeState = 1 and BridgeReverse `$5C0D` = 0; from the right end (X `$7A` or more) BridgeState = `$10` and BridgeReverse = 1.

Every fourth pass (PassCount & 3 = 0) one tile is written into the tile map at `$F968` + (BridgeState & `$7F`) - 1 (row 11, from column 8) through `$9A52`: the bridge tile `$07` (room `$19`) or `$BF` (room `$3A`), or in the bit-7 half a tile of BridgeTiles `$BB51` (`$BB55` in room `$3A`) by the column (& 3). Forward (BridgeReverse 0): BridgeState + 1 up to `$10`; there it waits until the explorer reaches X `$BA`, then `$81` runs a second sweep and ends at 0. Reverse: BridgeState - 1 down to 1, waits for the explorer below X `$30`, then `$90` and back to 0.

Witness: the bridge starts 3 times (`$BACC`: rzx08000, rzx12000, rzx42000); rzx08000 and rzx42000 cross forward (`$BB37`), rzx12000 in reverse (`$BB4E`).

Witness: L1 857 (rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 857 calls (`stage1/rzx/r42000` 362, `stage1/rzx/r08000` 267, `stage1/rzx/r12000` 206 and 1 more) |
| Called from | `ItemsPass` |
| Calls | `SetTile`, `AlwaysZero` |
| Reads | `$5B04` (system); `$5B98` (system); `$5C01`-`$5C0D` (system); `$5C3E` (system); `$BB51`-`$BB58` (`BridgeTiles`, `BridgeTiles3A`) |
| Writes | `$5C0C`-`$5C0D` (system) |

### `RopeTrick` (`$BC73`)

**Room `$10`: play the Flute at one spot and a rope grows down through the floor**

Called by ItemsPass in room `$10`, IX = the explorer. Does nothing when RopeCount `$5C24` is `$0D` (the rope is whole) or the Flute is not in hand (HeldItem `$5B98` = `$0C`). With the explorer at Y `$48` or `$46` and X `$28-$33`: his facing bit set, Y rocks between `$46` and `$48` by PassCount bit 0, and every fourth pass status 6 (Status6Entry `$A5F0`) and RopeCount + 1; from count 6 on the rope tiles `$98`, `$99` (columns 8 and 9) are written into the tile map at `$F928` + 32 x (12 - count) through `$9A52`: rows 15 up to 10, the rope growing up; at count `$0C` the status is cleared (`$AE84`). The room set-up (`$98ED`) reads RopeCount when room `$1C` is entered and writes the rope tiles `$98`, `$99` into columns 8 and 9 of rows 0-11 of room `$1C`'s tile map (`$F808` on); every room entry then clears RopeCount (`$9907`), so room `$1C` must be the next room entered.

Witness: rzx10000 and gameover stand at Y `$46` / `$48` with the Flute (`$BC8A`, once each) but never at X `$28-$33`: the rope (`$BC91` on) is not executed in any recording (c1, explorers, gameover, the 31 rzx builds). SK called it a seesaw.

Witness: L1 674 (gameover, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 674 calls (`stage1/gameover` 324, `stage1/rzx/r10000` 324, `stage1/rzx/r14500` 26) |
| Called from | `ItemsPass` |
| Reads | `$5B04`-`$5B05` (system); `$5B98` (system); `$5C24` (system) |

## objects

`src/game/objects.asm`

### `ResetItems` (`$B932`)

**Put every item back: clear the taken bit of all 31 ItemPlaces records**

Called by GameInit at `$8F83` (a new game); GameInit then marks the Energy Crystal of room `$30` taken (`$8F86`). Witness: c1 once, explorers 5 times, rzx00000 once (the new games).

Witness: L1 7 (c1, explorers, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 1,448 t-states own (0.00 %) |
| Runs (the other recordings) | 6 calls (`stage1/explorers` 5, `stage1/rzx/r00000` 1) |
| Called from | `GameEntry`, `NewGame`, `RunSelector` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B99D`-`$B9F7` (`ItemPlaces`, `CrystalPlace`) |
| Writes | `$B99D`-`$B9F7` (`ItemPlaces`, `CrystalPlace`) |

### `SpawnRoomItems` (`$B93F`)

**Fill the two item slots with the items of this room**

Both item slots `$5C0E` and `$5C13` emptied (item `$FF`: IX+2 and IX+7), then the 31 ItemPlaces `$B99D` records are scanned for Room (`$5C01`) and each match goes to PlaceItem `$B95F`, C counting the matches. Taken items carry bit 7 in their room byte and never match. Called on every room entry (`$9911`, the end of the room set-up), after a gift to the professor (`$B5F8`) and after the crystal is placed (`$BA27`).

Witness: L1 113 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `SpawnRoomItems` at work](img/routines/SpawnRoomItems.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 1,589 t-states own (0.00 %) |
| Runs (the other recordings) | 112 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r14500` 6, `stage1/rzx/r06000` 6 and 30 more) |
| Called from | `SetUpRoomTiles` (tail), `ProfessorScript`, `ItemsPass` |
| Calls | `PlaceItem` |
| Reads | `$5C01` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B99D`-`$B9F7` (`ItemPlaces`, `CrystalPlace`) |
| Writes | `$5C10`-`$5C15` (system) |

### `PlaceItem` (`$B95F`)

**Put the item of an ItemPlaces record into the next free item slot**

HL = the record, C = the slots used so far (0, 1; 2 and more: the record is ignored). The slot (`$5C0E` for C = 0, `$5C13` for C = 1) gets X, Y and the item (byte 1 & `$1F`) decoded from the record (ItemPlaces `$B99D`) and the record's address in its bytes +3 and +4, for PickUpItem `$BB6C` to mark it taken. Out: C + 1; HL, AF, B kept.

Witness: L1 42 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The second slot (`$B96A`) is used 3 times (gameover, rzx10000, rzx14500).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 334 t-states own (0.00 %) |
| Runs (the other recordings) | 41 calls (`stage1/rzx/r00000` 6, `stage1/explorers` 5, `stage1/gameover` 4 and 14 more) |
| Called from | `SpawnRoomItems` |
| Reads | `$B99E`-`$B9ED` (`ItemPlaces+1`, `CrystalPlace`) |
| Writes | `$5C0E`-`$5C17` (system) |

### `ItemsPass` (`$B9FA`)

**The items of a pass: pick up, the crystal of room `$30`, the bearer keys, the swap, the bridges, the rope**

Called by the main loop every pass (`$9034`), IX = the explorer `$5B04`. In room `$30` the pickup is skipped (the return address is set to ItemsKeys `$BA36`) and the Energy Crystal is placed instead: holding it (HeldItem `$5B98` = `$18`) with the explorer at Y `$60`, X `$40-$4B`, the crystal's ItemPlaces record (CrystalPlace `$B9D9`) loses its taken bit so the crystal lies in its place, HeldItem = `$FF`, CrystalPlaced `$5C44` = `$FF` (read by `$A910`), the room's items spawned again (`$B93F`), +75 score, the hand icon redrawn. In every other room PickUpItems `$BB5D` runs.

Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The crystal is placed once (`$BA1A`, rzx24750).

[Animation: `ItemsPass` at work](img/routines/ItemsPass.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 350,667 t-states own (0.02 %) |
| Runs (the other recordings) | 25,244 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop` |
| Calls | `DrawPortrait`, `DrawBearers`, `SpawnRoomItems`, `ItemsKeys`, `BridgeEffect`, `PickUpItems`, `BearerKeys`, `RopeTrick`, `AddScore` |
| Reads | `$5B04`-`$5B05` (system); `$5B7C`-`$5B98` (system); `$5C01`-`$5C06` (system); `$5C22`-`$5C23` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B9D9` (`CrystalPlace`); 1 more ranges |
| Writes | `$5B7C`-`$5B98` (system); `$5C44` (system); `$B9D9` (`CrystalPlace`); `$BA96` (`SwapLatch`) |
| Ports in | `$FDFE` |

### `ItemsKeys` (`$BA36`)

**The bearer keys 1 and 2, the swap key S, then the room effects of rooms `$19`, `$3A` and `$10`**

BearerKeys `$BC1F` with Z set when no scroll runs (BearerPhase `$5C22` = 0). Then the S key (port `$FDFE` bit 1; the Help page: "S=Swap item with another nearest"): on a new press (SwapLatch `$BA96` = 0), unless the status is `$1B`, `$1C` or `$1D`, the held item and the load of the bearer at BearerIndex `$5C23` change places (either may be `$FF`, nothing), both icon rows are redrawn (`$9EBD`, `$9E5D`) and SwapLatch is set until S is released. Then BridgeEffect `$BA97` in rooms `$19` and `$3A` (A = the room) and RopeTrick `$BC73` in room `$10`.

Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). The swap runs 34 times in 21 builds (`$BA5B`).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 184 calls (`stage1/rzx/r24750` 184) |
| Called from | `BlitColumns`, `ItemsPass` |
| Calls | `DrawPortrait`, `DrawBearers`, `BearerKeys` |
| Reads | `$5B8B`-`$5B98` (system); `$5C01`-`$5C06` (system); `$5C22`-`$5C23` (system); `$BA96` (`SwapLatch`) |
| Writes | `$5B8B`-`$5B98` (system); `$BA96` (`SwapLatch`) |
| Ports in | `$FDFE` |

### `AlwaysZero` (`$BB59`)

**PUSH HL, CP A, POP HL, RET: returns with Z set, nothing else**

Called by BridgeEffect `$BA97` (`$BA9F`) before its start test, which returns when Z is clear: never. A test left empty (known only from the code).

Witness: L1 489 (rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 489 calls (`stage1/rzx/r42000` 217, `stage1/rzx/r08000` 143, `stage1/rzx/r12000` 107 and 1 more) |
| Called from | `BridgeEffect` |

### `PickUpItems` (`$BB5D`)

**Pick up the items the explorer touches: both item slots**

IX = the explorer `$5B04`; PickUpItem `$BB6C` for slot `$5C0E`, then for slot `$5C13` (fallen into). Called by ItemsPass `$B9FA` every pass except in room `$30`.

Witness: L1 26330 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 79,626 t-states own (0.00 %) |
| Runs (the other recordings) | 25,060 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `ItemsPass` |
| Calls | `PickUpItem` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `PickUpItem` (`$BB6C`)

**Pick up the item of slot IY if the explorer touches it**

IY = the item slot. When the explorer is near (`$9140`) an item there (below `$FE`): the first free bearer is found (BearerLoads `$5B7C`, 27 bytes, `$FF` free: the "invisible bearers" of the Help page; with none free nothing happens, not executed in any recording). Item `$16` (the Anti Radiation Pills) also sets PillsTaken `$5C3F`. The Cannon (8) is never picked up. The Spring (`$0E`) and the Trampoline (`$14`) are not picked up either: when the explorer touches one in status 2 with `$5C07` at least 10 and X within 5 pixels of it he is set on top of it (X = its X, Y = its Y - `$17`, frame `$0F`, status 5: the bounce, BounceUp `$AD17`).

Any other item is taken: the held item, if any, goes to the free bearer (and BearerIndex `$5C23` is moved to show it: C - 2, not below 0), +50 score, sound 2, HeldItem = the item, the slot emptied (item `$FE`) and its ItemPlaces record marked taken (bit 7 of the room byte through slot +3, +4). The icon rows are redrawn (`$9E5D`, `$9EBD`).

Witness: L1 52660 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). 30 pickups in 15 builds (`$BBDA`), 22 of them with an item in hand (`$BBE4`); the bounce 3 times (`$BBC1`: gameover, rzx10000, rzx22000).

[Animation: `PickUpItem` at work](img/routines/PickUpItem.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2,540 calls, 277,372 t-states own (0.01 %) |
| Runs (the other recordings) | 50,120 calls (`stage1/explorers` 8,524, `stage1/rzx/r14000` 1,706, `stage1/rzx/r32000` 1,542 and 30 more) |
| Called from | `PickUpItems` |
| Calls | `Near`, `DrawPortrait`, `DrawBearers` (tail), `PickUpRedraw` (tail), `AddScore`, `PlaySound` |
| Reads | `$5B04` (system); `$5B7C`-`$5B98` (system); `$5C06`-`$5C17` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$B99D`-`$B9EB` (`ItemPlaces`, `CrystalPlace`) |
| Writes | `$5B04`-`$5B06` (system); `$5B7D`-`$5B98` (system); `$5C06`-`$5C23` (system); `$5C3F` (system); `$B99D`-`$B9EB` (`ItemPlaces`, `CrystalPlace`) |

### `PickUpRedraw` (`$BC07`)

**Redraw the hand icon (D not 0) and the bearers (E not 0) after PickUpItem**

D, E as PickUpItem `$BB6C` leaves them; C = the bearer the held item went to: BearerIndex `$5C23` = C - 2 (0 for C 0 and 1), then the bearer row is drawn (`$9EBD`).

Witness: L1 52660 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23,828 calls (`stage1/rzx/r14000` 1,706, `stage1/rzx/r32000` 1,542, `stage1/rzx/r08000` 1,512 and 16 more) |
| Called from | `PickUpItem` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `BearerKeys` (`$BC1F`)

**The bearer keys: 1 moves the bearers right, 2 moves them left, with a 4-step scroll**

Z set on entry when no scroll runs (BearerPhase `$5C22` = 0). Then key 1 (port `$F7FE` bit 0) sets BearerScrollDir `$5C21` = 1, BearerPhase = 4 and BearerIndex `$5C23` - 1 (from 0 to `$1A`: the 27 bearers wrap); key 2 (bit 1) clears BearerScrollDir and BearerPhase. No key: nothing (both at once count as key 1). While a scroll runs (and after key 2): with BearerScrollDir 0 the phase counts up 1 a call and at 4 BearerIndex + 1 (from `$1A` to 0) and the phase is 0; with BearerScrollDir 1 it counts down from 4. Every step redraws the bearer row (`$9EBD`: four bearers from BearerIndex, shifted by BearerPhase). The Help page: "1=Move bearers and objects right 2=Move bearers and objects left".

Witness: c1 presses 1 and 2 (tests/inputs/c1.txt); key 1 runs 128 times in 21 builds (`$BC2F`), key 2 113 times in 21 (`$BC43`).

Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `BearerKeys` at work](img/routines/BearerKeys.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 74,033 t-states own (0.00 %) |
| Runs (the other recordings) | 25,244 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `ItemsPass`, `ItemsKeys` |
| Calls | `DrawBearers` (tail) |
| Reads | `$5C21`-`$5C23` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Writes | `$5C21`-`$5C23` (system) |
| Ports in | `$F7FE` |

## score

`src/game/score.asm`

### `NegateNumber` (`$BCDE`)

**Negate the 32-bit number at HL-3..HL (two's complement) for the printer**

CPL on the four bytes from HL down, then + 1 through AddToNumber (`$BD15` with DE = 1, IX the number). Called by PrintNumber `$BD78` when the number is negative (`$BD9D`); not executed in any recording (c1, explorers, gameover, the 31 rzx builds). No minus sign is printed: known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AddScore` (`$BCF2`)

**Add DE (signed) to the score and print it, every register kept**

DE = the points (+50 a pickup `$BBE9`, +75 the crystal `$BA2A`, +150 the Silver Cross `$B538` and each gift `$B5FE`, from GameInit `$8FCC`, `$A851` +75). Saves IX, IY, HL, BC, AF and the alternate HL, BC, DE; AddToScore `$BD11`, PrintScore `$BD75`.

Witness: L1 46 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `AddScore` at work](img/routines/AddScore.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 488 t-states own (0.00 %) |
| Runs (the other recordings) | 44 calls (`stage1/explorers` 10, `stage1/rzx/r02000` 4, `stage1/rzx/r00000` 3 and 17 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `Room43Anim`, `SilverCrossScript`, `ProfessorScript`, `ItemsPass`, `PickUpItem` |
| Calls | `AddToScore`, `PrintScore` |

### `AddToScore` (`$BD11`)

**Score `$5C18` (32 bits) + DE, sign-extended**

IX = Score `$5C18`, then AddToNumber `$BD15`: BC = `$FFFF` when DE is negative, else 0; the low word + DE, the high word + BC with the carry. Out: HL the new high word.

Witness: L1 46 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 474 t-states own (0.00 %) |
| Runs (the other recordings) | 44 calls (`stage1/explorers` 10, `stage1/rzx/r02000` 4, `stage1/rzx/r00000` 3 and 17 more) |
| Called from | `AddScore` |
| Reads | `$5C18`-`$5C1B` (system) |
| Writes | `$5C18`-`$5C1B` (system) |

### `PrintHiScore` (`$BD3B`)

**Print HiScore `$5B78` at screen `$5049` (row 18, column 9)**

The printer's source operand PrintNumberSource+1 (`$BD89`) is pointed at HiScore `$5B78` for one PrintNumber `$BD78` call, then restored. Reached by JP from NewHiScore `$BD72` only; split off as its own entry here (the cut ran it on from AddToScore's RET at `$BD3A`).

Witness: L1 4 (c1, explorers, gameover, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NewHiScore` (`$BD50`)

**Take the score as the high score if it is higher, and print it**

Compares Score `$5C18` with HiScore `$5B78` from the top byte (`$5C1B`, `$5B7B`) down; a negative score (bit 7 of `$5C1B`) never counts. Higher: the 4 bytes are copied and PrintHiScore `$BD3B` prints it. Called at the end of a game by `$906D`.

Witness: L1 8 (c1, explorers, gameover, rzx). c1, explorers, gameover and rzx50000 each set a high score once (`$BD67`).

[Animation: `NewHiScore` at work](img/routines/NewHiScore.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 516 t-states own (0.00 %) |
| Runs (the other recordings) | 7 calls (`stage1/explorers` 5, `stage1/rzx/r50000` 1, `stage1/gameover` 1) |
| Called from | `GameEntry`, `NewGame`, `MainLoop` |
| Calls | `PrintNumber` |
| Reads | `$5B78`-`$5B7B` (system); `$5C18`-`$5C1B` (system); `$BD89`-`$BD8A` (`PrintNumberSource+1`) |
| Writes | `$5B78`-`$5B7B` (system); `$BD89`-`$BD8A` (`PrintNumberSource+1`) |

### `PrintScore` (`$BD75`)

**Print Score `$5C18` at screen `$5029` (row 17, column 9)**

HL = `$5029`, then PrintNumber `$BD78`.

Witness: L1 46 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 44 calls (`stage1/explorers` 10, `stage1/rzx/r02000` 4, `stage1/rzx/r00000` 3 and 17 more) |
| Called from | `AddScore` |
| Calls | `PrintChar`, `PrintNumber`, `DivideNumber` |
| Reads | `$5C18`-`$5C20` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE18`-`$BE23` (`PlaceValues`) |
| Writes | `$5C1C`-`$5C20` (system) |

### `PrintNumber` (`$BD78`)

**Print a 32-bit number as four digits at HL, no leading zeros**

HL = the screen address. Four spaces are printed first (`$90C6`), then the number (Score `$5C18`, or the address in PrintNumberSource+1) is copied to NumberWork `$5C1C` and divided by 1000, 100, 10 and 1 (PlaceValues `$BE18`, DivideNumber `$BDDF`); each quotient is printed as the character '0' + q, the leading zeros as nothing (DigitShown `$5C20`), a last 0 always. A thousands quotient above 9 prints the character after '9' (known only from the code).

Witness: L1 50 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3 calls, 3,907 t-states own (0.00 %) |
| Runs (the other recordings) | 16 calls (`stage1/explorers` 11, `stage1/gameover` 3, `stage1/rzx/r50000` 2) |
| Called from | `NewHiScore`, `PrintScore` |
| Calls | `PrintChar`, `DivideNumber` |
| Reads | `$5B78`-`$5B7B` (system); `$5C18`-`$5C20` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE18`-`$BE23` (`PlaceValues`) |
| Writes | `$5C1C`-`$5C20` (system) |

### `DivideNumber` (`$BDDF`)

**C = how many times the 24-bit B:DE goes into the 32-bit number at IX**

Subtracts B:DE from IX+0..+3 until it goes below 0, then restores the last value. Out: C + the count (C = 0 on entry from PrintNumber), the number at IX the remainder.

Witness: L1 501 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 12 calls, 7,154 t-states own (0.00 %) |
| Runs (the other recordings) | 188 calls (`stage1/explorers` 44, `stage1/rzx/r02000` 16, `stage1/gameover` 12 and 17 more) |
| Called from | `PrintScore`, `PrintNumber` |
| Reads | `$5C1C`-`$5C1F` (system) |
| Writes | `$5C1C`-`$5C1F` (system) |

## creatures

`src/game/creatures.asm`

### `DecodeRoomCreatures` (`$BE42`)

**Unpack the room's three creature records of RoomCreatures into CreatureRecords**

A = the room (kept). CreatureRecords `$BE24` cleared (30 bytes), then for each 4-byte record at `$C152` + 12 x A: +0 and +1 = byte0 & `$0F`, +2 = byte0 & `$80`, +3 = byte0 >> 4 & 7, +4 = byte1, +5 = byte2, +6 = byte3 & `$7F`, +7 = byte3 & `$80`. Called by `$9855` (the room set-up) on every room entry.

Witness: L1 105 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `DecodeRoomCreatures` at work](img/routines/DecodeRoomCreatures.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 1,751 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`stage1/rzx/r00000` 8, `stage1/rzx/r40000` 6, `stage1/rzx/r06000` 6 and 27 more) |
| Called from | `SetUpRoom` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE24`-`$BE40` (`CreatureRecords`, `CreatureRecord2`, `CreatureRecord3`); `$C152`-`$C15D` (`RoomCreatures`); `$C176`-`$C18D` (`RoomCreatures+36`); `$C1A6`-`$C21D` (`RoomCreatures+84`); `$C236`-`$C301` (`RoomCreatures+228`); 2 more ranges |
| Writes | `$BE24`-`$BE41` (`CreatureRecords`, `CreatureRecord2`, `CreatureRecord3`) |

### `RunCreatures` (`$BE98`)

**Run the room's three creatures: the handler of each record's type**

IX = the slots `$5B08`, `$5B0C`, `$5B10` in turn, IY = CreatureRecords `$BE24` + 10k; the handler is word +0 of CreatureHandlers `$BECA`, called through JumpHL `$BEC9`. Called by the main loop every pass (`$903D`); IX kept.

Witness: L1 26514 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `RunCreatures` at work](img/routines/RunCreatures.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,270 calls, 1,000,582 t-states own (0.05 %) |
| Runs (the other recordings) | 25,244 calls (`stage1/explorers` 4,262, `stage1/rzx/r14000` 853, `stage1/rzx/r32000` 771 and 30 more) |
| Called from | `GameEntry`, `NewGame`, `RunSelector`, `MainLoop` |
| Calls | `JumpHL` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE24`-`$BE38` (`CreatureRecords`, `CreatureRecord2`, `CreatureRecord3`); `$BECA`-`$BEDB` (`CreatureHandlers`) |

### `JumpHL` (`$BEC9`)

**JP (HL): the call into a creature handler**

Witness: L1 79544 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,810 calls, 15,240 t-states own (0.00 %) |
| Runs (the other recordings) | 75,734 calls (`stage1/explorers` 12,786, `stage1/rzx/r14000` 2,559, `stage1/rzx/r32000` 2,313 and 30 more) |
| Called from | `RunCreatures` |
| Calls | `NoCreature`, `WalkerCreature`, `ClimberCreature`, `LeftFlier`, `RightFlier`, `DropCreature`, `StillCreature`, `RiserCreature`, `PlaceCreature` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `NoCreature` (`$BEDC`)

**Type 0: an empty record, RET**

Witness: L1 41598 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | run into, not called, 16,445 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/explorers`, `stage1/rzx/r14000`, `stage1/rzx/r42000` and 30 more) |
| Called from | `JumpHL` |

### `WalkerCreature` (`$BEDD`)

**Type 1: walk 2 pixels a pass along X, turn at walls and the room edges**

Placed at the first call (PlaceCreature `$C135`). Direction bit 7 of +7 set: X + 2 up to `$E6`, the tiles right of it tested (TestRight `$C109`); clear: X - 2 down to 0, the ground under it tested (TestBelow `$C0FD`). A test flag not 0, or the edge, turns it (+7 bit 7 flipped). Then AnimateCreature `$C0AC`.

Witness: L1 2454 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r04000`, `stage1/rzx/r38000`, `stage1/rzx/r36000` and 8 more) |
| Called from | `JumpHL` |
| Calls | `AnimateCreature` (tail), `TestBelow`, `TestRight`, `PlaceCreature` |
| Reads | `$5B08`-`$5B10` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE2B`-`$BE40` (`CreatureRecords+7`, `CreatureRecord2`, `CreatureRecord3`); `$C12D`-`$C12E` (`TileScanFlags`) |
| Writes | `$5B08`-`$5B10` (system); `$BE2B`-`$BE3F` (`CreatureRecords+7`, `CreatureRecord2`, `CreatureRecord3`) |

### `ClimberCreature` (`$BF22`)

**Type 2: move 2 pixels a pass along Y, turn at the floor, the ceiling and the room's top and bottom**

As WalkerCreature `$BEDD` along Y: bit 7 set: Y + 2 up to `$66`, tested by TestBelowRight `$C121`; clear: Y - 2 down to 0, tested by TestAhead `$C115`. Then AnimateCreature `$C0AC`.

Witness: L1 266 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r36000`, `stage1/rzx/r34000`, `stage1/rzx/r40000`) |
| Called from | `JumpHL` |
| Calls | `AnimateCreature` (tail), `TestAhead`, `TestBelowRight`, `PlaceCreature` |
| Reads | `$5B09` (system); `$BE2B`-`$BE2C` (`CreatureRecords+7`); `$C131`-`$C132` (`TileScanSecond`) |
| Writes | `$5B09` (system); `$BE2B` (`CreatureRecords+7`) |

### `LeftFlier` (`$BF67`)

**Type 3: wait a random time unseen, then fly left 2 pixels a pass across the room**

CreatureTimer `$BFA0` (C = 1); while it runs the frame is `$7F` (unseen). Then X - 2 a pass (direction bit cleared); X below 0: unseen again, the timer 0 (a new random wait, the place again) and the type restored from +1. A TestBelow `$C0FD` flag not 0 adds 1 to the record's type (+0): it becomes a RightFlier until it leaves the room (not executed in any recording). Then AnimateCreature `$C0AC`.

Witness: L1 5796 (c1, explorers, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | run into, not called, 168,803 t-states own (0.01 %) |
| Runs (the other recordings) | run into, not called (`stage1/explorers`, `stage1/rzx/r00000`, `stage1/rzx/r12000`) |
| Called from | `JumpHL` |
| Calls | `CreatureTimer`, `AnimateCreature` (tail), `TestBelow` |
| Reads | `$5B0C` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE2F`-`$BE35` (`CreatureRecord2+1`); `$C12D` (`TileScanFlags`) |
| Writes | `$5B0C`-`$5B0E` (system); `$BE2E`-`$BE36` (`CreatureRecord2`) |

### `CreatureTimer` (`$BFA0`)

**Count down the creature's timer +8; a new random wait when it is 0**

IY = the record, C = bits that are ORed into a new wait. Timer 0: PlaceCreature `$C135`, then a random 0-`$7F` (`$9390`) OR C as the new wait. Then the timer - 1: out Z set (and the timer left at 1) when it has run out, else the new value stored, Z clear. So after the wait the creature acts every pass until its handler clears the timer.

Witness: L1 31152 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2,540 calls, 219,061 t-states own (0.01 %) |
| Runs (the other recordings) | 28,612 calls (`stage1/explorers` 8,524, `stage1/rzx/r22000` 1,659, `stage1/rzx/r12000` 1,634 and 22 more) |
| Called from | `LeftFlier`, `RightFlier`, `DropCreature`, `RiserCreature` |
| Calls | `Random`, `PlaceCreature` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE2C`-`$BE40` (`CreatureRecords+8`, `CreatureRecord2`, `CreatureRecord3`) |
| Writes | `$BE2C`-`$BE40` (`CreatureRecords+8`, `CreatureRecord2`, `CreatureRecord3`) |

### `RightFlier` (`$BFBB`)

**Type 4: wait a random time unseen, then fly right 2 pixels a pass across the room**

As LeftFlier `$BF67`, rightwards: X + 2 to `$E6`, the direction bit set, tested by TestRight `$C109` (a flag not 0 subtracts 1 from the type: it becomes a LeftFlier; not executed in any recording).

Witness: L1 989 (rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r24000`, `stage1/rzx/r00000`, `stage1/rzx/r24750` and 1 more) |
| Called from | `JumpHL` |
| Calls | `CreatureTimer`, `AnimateCreature` (tail), `TestRight` |
| Reads | `$5B08`-`$5B0C` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE25`-`$BE35` (`CreatureRecords+1`, `CreatureRecord2`); `$C12E` (`TileScanFlags+1`) |
| Writes | `$5B08`-`$5B0E` (system); `$BE24`-`$BE36` (`CreatureRecords`, `CreatureRecord2`) |

### `DropCreature` (`$BFF6`)

**Type 5: a drop that waits, falls 2 pixels a pass, splashes and starts again**

CreatureTimer `$BFA0` (C = 1): the drop is unseen (frame `$7F`) while it waits, at its start place. Then DropFall `$C000`.

Witness: L1 12834 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r08000`, `stage1/rzx/r22000`, `stage1/rzx/r12000` and 17 more) |
| Called from | `JumpHL` |
| Calls | `CreatureTimer`, `HitExplorer` (tail), `TestBelowRight`, `PlaySound` (tail) |
| Reads | `$5B09`-`$5B11` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE28`-`$BE3F` (`CreatureRecords+4`, `CreatureRecord2`, `CreatureRecord3`); `$C132` (`TileScanSecond+1`) |
| Writes | `$5B09`-`$5B12` (system); `$BE2B`-`$BE40` (`CreatureRecords+7`, `CreatureRecord2`, `CreatureRecord3`) |

### `DropFall` (`$C000`)

**The drop's fall: Y + 2 until the ground or Y `$66`, then the splash**

The second half of DropCreature `$BFF6`, an entry of the cut because `$C000` is also the address the IM 2 handler calls with RAM 6 paged in (the music player, `$94A0`); here, in RAM 0, it is only the drop. Y + 2 a pass; at Y `$67` the drop is gone (frame `$7F`, the timer 0: a new wait). Falling, +7 counts the passes and the frame is +4, then +4 + 1 from the third pass on ((+7 & 6) / 2 held at 1). The ground below (TestBelowRight `$C121`): Y - 1, the splash frames (+7 stepped, frame +4 + 1, 2, 3) and at the end the timer 0, frame `$7F` and sound 5 (PlaySound `$C4B2`). The drop always tests the explorer (HitExplorer `$C0DA`), with no hit flag.

Witness: L1 3288 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). 105 splashes with sound 5 in 18 builds (`$C04F`).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `StillCreature` (`$C054`)

**Type 6: placed once, then animated in place until its frame is `$55` or `$7F`**

The frames `$55` and `$7F` are the ones the snake scripts set (SnakeStrike `$B5C2`, SnakeBite `$B5C8`): a still creature they have struck or removed stops. Else AnimateCreature `$C0AC`.

Witness: L1 2107 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx/r06000`, `stage1/gameover`, `stage1/rzx/r10000` and 7 more) |
| Called from | `JumpHL` |
| Calls | `AnimateCreature` (tail), `PlaceCreature` |
| Reads | `$5B0A`-`$5B12` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE2C`-`$BE40` (`CreatureRecords+8`, `CreatureRecord2`, `CreatureRecord3`) |

### `RiserCreature` (`$C069`)

**Type 7: rise and sink through 4 frames, 16 steps, then a random pause**

CreatureTimer `$BFA0` with C = `$11` (a wait of at least `$11`, odd). One step a pass, +7 + 1: the frame index (+7 & `$0E`) / 2 folded at 4 runs 0 1 1 2 2 3 3 3 3 2 2 1 1 0 0, the frame +4 + index; after 16 steps (+7 bit 4) +7 keeps only its direction bit and the timer is cleared (a new pause). With the hit flag (+2 bit 7) the explorer is tested (HitExplorer `$C0DA`) at the frame index +3 (3: the riser fully up), or at every frame when +3 is 4 or more.

Witness: L1 11533 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | run into, not called, 100,998 t-states own (0.01 %) |
| Runs (the other recordings) | run into, not called (`stage1/explorers`, `stage1/rzx/r32000`, `stage1/rzx/r16000` and 16 more) |
| Called from | `JumpHL` |
| Calls | `Near`, `CreatureTimer`, `HitExplorer` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE26`-`$BE3F` (`CreatureRecords+2`, `CreatureRecord2`, `CreatureRecord3`) |
| Writes | `$5B0A`-`$5B12` (system); `$BE2B`-`$BE40` (`CreatureRecords+7`, `CreatureRecord2`, `CreatureRecord3`) |

### `AnimateCreature` (`$C0AC`)

**Step the creature's animation (frames +4 to +4 + 3) and test the explorer if it can hit**

+7 + 1, kept to bit 7 and bits 0-2; frame = +4 + (+7 & 6) / 2; the object flag byte IX+3 = +7 (the direction bit mirrors the sprite). With the hit flag (+2 bit 7): the explorer is tested (HitExplorer `$C0DA`) at every frame when the hit frame +3 is 4 or more, else only at frame index +3 (no room record has a hit frame below 4 for these types: not executed in any recording).

Witness: L1 8663 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 726 calls, 145,856 t-states own (0.01 %) |
| Runs (the other recordings) | 7,937 calls (`stage1/explorers` 2,608, `stage1/rzx/r36000` 737, `stage1/rzx/r06000` 696 and 17 more) |
| Called from | `WalkerCreature` (tail), `ClimberCreature` (tail), `LeftFlier` (tail), `RightFlier` (tail), `StillCreature` (tail) |
| Calls | `Near`, `HitExplorer` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE26`-`$BE3F` (`CreatureRecords+2`, `CreatureRecord2`, `CreatureRecord3`) |
| Writes | `$5B0A`-`$5B13` (system); `$BE2B`-`$BE3F` (`CreatureRecords+7`, `CreatureRecord2`, `CreatureRecord3`) |

### `HitExplorer` (`$C0DA`)

**A creature that touches the explorer: status `$18` (or `$1A`)**

IX = the creature's object. The explorer (`$5B04` as IY) near it (`$9140`: within `$10` pixels both ways, 8 for the drop's frames `$5C-$5F`): when the status is below `$0F`, status `$18` (CreatureDeath `$A89E`); if the status is 0 and the flag `$A101` is 0, status `$1A` (FallDeath `$A888`) instead. During the statuses `$0F` and above (the scripted events) creatures do not hit.

Witness: L1 10981 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx). 23 contacts in 4 builds (`$C0E6`), 4 of them set a status (`$C0F9`: rzx06000, rzx22000, rzx24000, rzx32000), `$1A` once (rzx24000).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 782 calls, 62,458 t-states own (0.00 %) |
| Runs (the other recordings) | 9,135 calls (`stage1/explorers` 2,788, `stage1/rzx/r24000` 685, `stage1/rzx/r04000` 653 and 19 more) |
| Called from | `DropCreature` (tail), `RiserCreature` (tail), `AnimateCreature` (tail) |
| Calls | `Near`, `SetStatus` (tail) |
| Reads | `$5C06` (system); `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$A101` (`HeroProbes+3`) |

### `TestBelow` (`$C0FD`)

**Test the tiles under the creature with `$A2AC` (SK: under the feet), the flag in TileScanFlags+0**

Witness: L1 4553 (c1, explorers, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 726 calls, 57,148 t-states own (0.00 %) |
| Runs (the other recordings) | 3,827 calls (`stage1/explorers` 2,608, `stage1/rzx/r04000` 334, `stage1/rzx/r38000` 262 and 10 more) |
| Called from | `WalkerCreature`, `LeftFlier` |
| Calls | `LeftWallCheck` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |

### `TestRight` (`$C109`)

**Test the tiles right of the creature with `$A2FA` (SK: X + 23), the flag in TileScanFlags+1**

Witness: L1 1724 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,724 calls (`stage1/rzx/r38000` 309, `stage1/rzx/r24000` 303, `stage1/rzx/r04000` 289 and 11 more) |
| Called from | `WalkerCreature`, `RightFlier` |
| Calls | `RightWallCheck` |

### `TestAhead` (`$C115`)

**Test a tile with `$A31F` (SK: X + 12, the special tiles), the flag in TileScanFlags+4**

Witness: L1 138 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 138 calls (`stage1/rzx/r36000` 67, `stage1/rzx/r34000` 38, `stage1/rzx/r40000` 33) |
| Called from | `ClimberCreature` |
| Calls | `CreatureSolidAt` |

### `TestBelowRight` (`$C121`)

**Test a tile with `$A30B` (SK: X + 12, Y + 24), the flag in TileScanFlags+5**

Witness: L1 3402 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,402 calls (`stage1/rzx/r08000` 427, `stage1/rzx/r12000` 379, `stage1/rzx/r22000` 375 and 18 more) |
| Called from | `ClimberCreature`, `DropCreature` |
| Calls | `CreatureFloorBelow` |

### `PlaceCreature` (`$C135`)

**Put the creature in its start place: X, Y, frame and flags from its record**

IX = the object slot, IY = the record: timer bit 0 set (placed), X = +5, Y = +6, frame = +4, IX+3 = +7. The type 8 handler (scenery: placed every pass, so it never moves or animates), and called by the other handlers at their first pass.

Witness: L1 2377 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 22 calls, 4,180 t-states own (0.00 %) |
| Runs (the other recordings) | 388 calls (`stage1/explorers` 76, `stage1/rzx/r22000` 25, `stage1/rzx/r12000` 24 and 25 more) |
| Called from | `JumpHL`, `WalkerCreature`, `ClimberCreature`, `CreatureTimer`, `StillCreature` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`); `$BE28`-`$BE40` (`CreatureRecords+4`, `CreatureRecord2`, `CreatureRecord3`) |
| Writes | `$5B08`-`$5B13` (system); `$BE2C`-`$BE40` (`CreatureRecords+8`, `CreatureRecord2`, `CreatureRecord3`) |

## sound

`src/game/sound.asm`

### `PlaySound` (`$C4B2`)

**Play beeper sound A (0-6), HL, DE, BC kept**

Calls SoundDispatch `$C4BC`. The callers and their sounds: PickUpItem `$BBF2` (2), DropFall `$C051` (5), `$A3E1` (`$A484`, 6), CreatureDeath `$A89E` (`$A8A3`, 3 every pass), DeathFrames `$A8AB` (`$A8B7`, the sound in C at the end of a death's frames: 0 for FallDeath `$A888`, 4 for Room1ADeath `$A88F`), `$B0B6`, `$AA3C`. The players are busy loops with the interrupts on: the L1 builds record 58 interrupts inside SoundChirp's loop (`$C4D5-$C4D9`, 16 builds), so the AY music of the IM 2 handler goes on and stretches the beeps: the half-wave the interrupt falls in grows by about 3700 T (the chirp's 7914 T to 11 679 T in c1 frame 23 509), and in the paper area the ULA's contention adds about 23 % (`EX (SP),HL` on the stack in RAM 5, `OUT ($FE)`); doc 9, 9.11.

Witness: L1 339 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 90 t-states own (0.00 %) |
| Runs (the other recordings) | 338 calls (`stage1/rzx/r22000` 36, `stage1/rzx/r06000` 31, `stage1/rzx/r32000` 26 and 25 more) |
| Called from | `HeroUpdate` (tail), `FallDeath`, `CreatureDeath`, `DeathFrames`, `BarrelSpot` (tail), `SpaceScene` (tail), `PickUpItem`, `DropCreature` (tail) |
| Calls | `SoundDispatch` |

### `SoundDispatch` (`$C4BC`)

**Jump to the player of sound A through SoundEffects `$C55B`, E = `$10` (the speaker bit)**

A of 7 and more: nothing. The player's address is pushed and RET jumps to it.

Witness: L1 339 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 96 t-states own (0.00 %) |
| Runs (the other recordings) | 338 calls (`stage1/rzx/r22000` 36, `stage1/rzx/r06000` 31, `stage1/rzx/r32000` 26 and 25 more) |
| Called from | `PlaySound` |
| Calls | `SoundChirp`, `SoundRomFall`, `SoundRise`, `SoundHiss`, `SoundBeepLow`, `SoundBeepHigh`, `SoundRomBurst` |
| Reads | `$C55B`-`$C568` (`SoundEffects`) |

### `SoundChirp` (`$C4CE`)

**Sound 2, the pickup: four bursts of 10 half-waves, each shorter (H `$7F`, `$1F`, 7, 1)**

Half-wave length H loop turns of OUT (`$FE`) with two EX (SP),HL of delay; H / 4 after each burst. Played by PickUpItem `$BBF2` (and 1 more, 31 runs in 16 builds).

Witness: L1 31 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 121,323 t-states own (0.01 %) |
| Runs (the other recordings) | 30 calls (`stage1/explorers` 5, `stage1/rzx/r02000` 4, `stage1/rzx/r06500` 2 and 12 more) |
| Called from | `SoundDispatch` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundRomFall` (`$C4E9`)

**Sound 1: 2250 bytes of ROM from `$0000` to the speaker at a falling pitch, then sound 0**

HL = `$0000`, BC = 9000 counted down by 4: each byte of the ROM (AND E: the speaker bit) is sent after a delay of `$23` - B loop turns, so the pitch falls as B does; then SoundRise `$C506`. Witness: gameover and rzx16000 play it once each.

Witness: L1 2 (gameover, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/rzx/r16000` 1, `stage1/gameover` 1) |
| Called from | `SoundDispatch` |
| Calls | `SoundRise` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundRise` (`$C506`)

**Sound 0: six bursts of 10 half-waves, each longer**

As SoundChirp `$C4CE`, H shifted up with a 1 bit after each burst: 6 bursts, H 3, 7, `$0F`, `$1F`, `$3F`, `$7F`. Played alone and at the end of SoundRomFall `$C4E9`. Witness: gameover (twice), rzx10000, rzx16000, rzx24000.

Witness: L1 5 (gameover, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/gameover` 2, `stage1/rzx/r10000` 1, `stage1/rzx/r24000` 1) |
| Called from | `SoundDispatch`, `SoundRomFall` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundHiss` (`$C521`)

**Sound 3: 100 bits from the ROM bytes `$0000-$003F` picked by R**

Witness: rzx06000, rzx22000, rzx32000 play it 11 times each (the status `$18` handler CreatureDeath `$A89E`).

Witness: L1 33 (rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33 calls (`stage1/rzx/r06000` 11, `stage1/rzx/r32000` 11, `stage1/rzx/r22000` 11) |
| Called from | `SoundDispatch` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundBeepLow` (`$C532`)

**Sound 6: 3 square waves of `$C8` loop turns a half**

HL = `$03C8` (H the waves, L the half-wave), then SoundTone `$C53A`. Played by `$A3E1` at `$A484` (164 runs in 24 builds).

Witness: L1 164 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 164 calls (`stage1/rzx/r06000` 18, `stage1/rzx/r06500` 14, `stage1/rzx/r22000` 13 and 21 more) |
| Called from | `SoundDispatch` |
| Calls | `SoundTone` (tail) |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundBeepHigh` (`$C537`)

**Sound 5, the drop's splash: 5 square waves of `$64` loop turns a half**

HL = `$0564`, then SoundTone `$C53A` (fallen into). Played by DropFall `$C051`, 105 times.

Witness: L1 105 (rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 105 calls (`stage1/rzx/r34000` 16, `stage1/rzx/r26000` 12, `stage1/rzx/r22000` 10 and 15 more) |
| Called from | `SoundDispatch` |
| Calls | `SoundTone` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundTone` (`$C53A`)

**H square waves of 2 x L loop turns on the speaker (E the speaker bit)**

Witness: L1 1017 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 239 calls (`stage1/rzx/r22000` 23, `stage1/rzx/r06000` 20, `stage1/rzx/r06500` 20 and 14 more) |
| Called from | `SoundBeepLow` (tail), `SoundBeepHigh` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |

### `SoundRomBurst` (`$C54A`)

**Sound 4: 1280 bytes of ROM from `$0000` to the speaker, no delay**

HL = `$0000` (LD HL,`$0000`: SK took its operand for NOPs), B = 0: 256 x 5 bytes, each AND E sent. Witness: rzx10000 plays it once.

Witness: L1 1 (rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx/r10000` 1) |
| Called from | `SoundDispatch` |
| Reads | `$8EFF`-`$8F00` (`Im2Table+255`, `GameEntry`) |
| Ports out | `$00FE`, `$10FE` |


## Tape BASIC and loader (`src/tape/basic.json`)

Terramex, Grandslam 1987: TZX block 2, the BASIC program "TERRAMEX" (302 bytes at PROG `$5CCB`, LINE 0, the program
58 bytes): line 0 and, in the variables area at VARS `$5D05`, the machine-code loader entered at `$5D08`. Its
entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part
src/tape/basic.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 128K,
the menu, the selector and play).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](#tape-basic-and-loader-basic) | `$5CCB`-`$5DF8` | 2 of 6 |

### Tape BASIC and loader: basic

`src/tape/basic-module.asm`

#### `LoaderEntry` (`$5D08`)

**The loader: break trap, clear, cheat test, load the screen and block 4, the setup, load the game**

Entered by line 0's USR with BC = `$5D08` (its own address) and interrupts off by its DI. Position independent: it adds BC to three offsets: BreakMessage's address is patched into BreakHandler's LD HL operand (`$5DA6`), SP = `$5FE6` and BreakHandler's address is pushed and ERR_SP pointed at it, so an error report (BREAK in LD-BYTES: "D BREAK - CONT repeats") lands in BreakHandler `$5D83`.

The screen and attributes `$4000-$5AFF` cleared, border 0. Has128K `$5FFE` and GameLoaded `$5FFF` set to 0. InfiniteLives `$5B03` = 1 when the byte at `$8000` is `$C9` (RET), else 0: memory before the load, so a POKE 32768,201 typed before LOAD "" gives the cheat; GameEntry `$8F00` then writes OR A (`$B7`) over the DEC (HL) of the lives at `$A9FD` instead of keeping `$35`.

LD-BYTES (flag `$FF`) the loading screen to `$4000` (`$1B00` bytes, TZX block 3) and block 4 to `$6000` (`$96F8` bytes, TZX block 4); the carry (a load error) is not tested. CALL `$7200` with BC = `$7200`: the setup (src/select). On a 128K it returns through the paging stub at once; on a 48K after the explorer is chosen. Then KeyReleaseWait `$5D64`, LD-BYTES of block 5 to `$7200` (`$8E00` bytes) and JP `$8F00` (GameEntry).

c1: one run from frame 696: the screen loads, block 4, the setup at frame 11841, the game block, GameEntry at frame 21597.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 187,512 t-states own (0.01 %) |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5B03` (screen); `$5C3D`-`$5C3E`; `$5DA6`-`$5DA7` (`BreakMessagePtr+1`); `$5FFE`-`$5FFF` |
| Ports in | `$00FE` |
| Ports out | `$00FE`, `$05FE` |

#### `BreakHandler` (`$5D83`)

**BREAK during the load: "User pressed break-reload!" on a blue screen, for ever**

ERR_SP points at this address (LoaderEntry `$5D08`), so the ROM's error report on BREAK in LD-BYTES comes here. Bitmap cleared, attributes `$0F` (blue paper, white ink), border 1, stream 2 opened, BreakMessage `$5DB7` printed by RST `$10` up to its `$FF`; then back to the start, clearing and printing again with no way out but a reset. Not executed in any recording (c1 loads without BREAK); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |


## The 128K setup and the explorer selector (RAM 1) (`src/select/select.json`)

Terramex, Grandslam 1987: TZX block 4 `$7200-$9CF7`, the 128K setup and the explorer selector, assembled at `$C000`
as the setup's relocation pass leaves them in RAM 1; tools/mktape.py undoes the relocation for the tape. Its entries
are `src/select/<module>.asm`, written from `src/select/select.ann` by `kit/mkgame.py --part
src/select/select.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 128K,
the menu, the selector and play), and `work/stage1/explorers`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`setup`](#the-128k-setup-and-the-explorer-selector-ram-1-setup) | `$C000`-`$C0A9` | 2 of 3 |
| [`relocation`](#the-128k-setup-and-the-explorer-selector-ram-1-relocation) | `$C0AA`-`$C0D1`, `$EA0F`-`$EA96` | 2 of 3 |
| [`selector`](#the-128k-setup-and-the-explorer-selector-ram-1-selector) | `$C0D2`-`$C3BC`, `$C4A2`-`$C4A5`, `$CD8F`-`$EA0E` | 15 of 20 |
| [`input`](#the-128k-setup-and-the-explorer-selector-ram-1-input) | `$C3BD`-`$C4A1` | 5 of 6 |
| [`paging`](#the-128k-setup-and-the-explorer-selector-ram-1-paging) | `$C4A6`-`$C4BA` | 1 of 1 |
| [`print`](#the-128k-setup-and-the-explorer-selector-ram-1-print) | `$C4BB`-`$C535` | 4 of 4 |
| [`help`](#the-128k-setup-and-the-explorer-selector-ram-1-help) | `$C536`-`$CD8E` | 2 of 7 |
| [`leftovers`](11-data-reference.md#the-128k-setup-and-the-explorer-selector-ram-1-leftovers) | `$EA97`-`$EAF7` | 0 of 1 |

### The 128K setup and the explorer selector (RAM 1): setup

`src/select/setup.asm`

#### `SelectorStart` (`$C000`)

**The block's first bytes: the relocated flag, a jump over the table offset**

The NOP at `$C000` is also a flag: the tape holds 0, RelocateSelector `$C0AB` writes `$2F` (CPL) once the words are relocated, so every later entry runs CPL; JR (harmless) and Setup `$C005` sees a nonzero byte. Entered with BC = the block's address: by the loader at `$7200` (CALL `$7200` at `$5D61`), by Setup at `$C000` in RAM 1 (JP at `$C0A7`), and by the game's menu (CALL `$C000` at `$8F5E` with RAM 1 paged, Last7FFD = `$11`).

c1: entered twice (the load at frame 11841, the game's menu at frame 22215); explorers: six times (the menu after each abort).

Witness: L1 8 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 51,108,413 t-states own (2.71 %) |
| Runs (the other recordings) | 6 calls (`stage1/explorers` 6) |
| Calls | `RestoreUnderCursor`, `DrawSelectorPicture`, `MoveCursor`, `DrawCursor`, `ClearScreen`, `ShowHelp` (tail) |
| Reads | `$C000`-`$C004` (`SelectorStart`, `RelocTableOffset`); `$C0D3`-`$C131` (`SelectorEntry+1`, `SelectorRun`, `SelectorRestart`, `SelectorLoop` and 1 more); `$C190`-`$C1DB` (`CopySetLdir+11`, `RestoreUnderCursor`, `DrawSelectorPicture`, `MoveCursor`); `$C207`-`$C208` (`ClassifyCursor+1`); `$C280`-`$C2A2` (`StoreExplorer+10`, `ShowStopTape`); `$C315`-`$C356` (`DrawCursor+1`, `DrawColumn16`, `DrawColumn8`, `DrawColumn4` and 1 more); 5 more ranges |
| Writes | `$C000` (`SelectorStart`); `$C0D3`-`$C131` (`SelectorEntry+1`, `SelectorRun`, `SelectorRestart`, `SelectorLoop` and 1 more); `$C190`-`$C1DB` (`CopySetLdir+11`, `RestoreUnderCursor`, `DrawSelectorPicture`, `MoveCursor`); `$C207`-`$C208` (`ClassifyCursor+1`); `$C280`-`$C2A2` (`StoreExplorer+10`, `ShowStopTape`); `$C315`-`$C356` (`DrawCursor+1`, `DrawColumn16`, `DrawColumn8`, `DrawColumn4` and 1 more); 4 more ranges |

#### `Setup` (`$C005`)

**Dispatch on the relocated flag and the run address; on a 128K the paging test and the copies**

In: BC = the block's address. HL = BC; a nonzero first byte (relocated) goes to SelectorEntry `$C0D2`. With B = `$C0` (the unrelocated copy in RAM 1) it goes to RelocateSelector `$C0AB`. Otherwise (run at `$7200` by the loader) the paging test, using the alternate registers for the port so that BC and HL keep the address: Has128K `$5FFE` = 0; RAM 0 at `$C000` (`$7FFD` = `$10`, ROM 1), its byte at `$C000` kept in E and `$AA` written; RAM 1 (`$11`), `$55` written and read; RAM 0 again and compared; the byte restored. Equal: a 48K, RelocateInPlace `$C0AA`.

128K: RAM 1 paged, the `$2EE0` bytes from `$7200` copied to `$C000` (the block's 11 000 and 1000 bytes of set 0 after it, unused there); the 3 x `$1200` bytes from `$9CF8` to RAM 4 `$C000` a byte at a time (RAM 0 paged to read, since the source runs past `$C000`, RAM 4 to write), the 2 x `$1200` bytes after them to RAM 3 `$C000` the same way, Has128K = `$11`, the music player `$6000-$71FF` (`$1200` bytes) to RAM 6 `$C000`, RAM 1 paged again, and JP `$C000` with BC = `$C000`.

c1: one run at frame 11841: 13 824 bytes to RAM 4 (`$724E` loop), 9216 to RAM 3 (`$7272` loop), 4608 to RAM 6 (`$729B`). explorers starts from a snapshot after the load: only the relocated path (`$C009` to `$C068`).

Witness: L1 8 (c1, explorers).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### The 128K setup and the explorer selector (RAM 1): relocation

`src/select/relocation.asm`

#### `RelocateInPlace` (`$C0AA`)

**The 48K path: back to the main registers, relocate at `$7200`**

Reached from Setup `$C005` (JR Z at `$C033`) when the paging test found one RAM: EXX brings back HL = BC = `$7200` and falls into RelocateSelector. Known only from the code (the 48K path is not recorded).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RelocateSelector` (`$C0AB`)

**Add the run address to every word RelocTable lists, mark the block relocated**

In: HL = BC = the block's address. Writes `$2F` at the first byte, reads RelocTableOffset `$C003` (+3), then for each nonzero offset in RelocTable adds BC to the word at block + offset. Falls into SelectorEntry `$C0D2` at the zero word.

c1: run once at `$C000` in RAM 1 (frame 11841): 68 table words read, 67 words relocated.

Witness: L1 1 (c1).

[Animation: `RelocateSelector` at work](img/routines/RelocateSelector.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

### The 128K setup and the explorer selector (RAM 1): selector

`src/select/selector.asm`

#### `SelectorEntry` (`$C0D2`)

**Copy the paging stub to `$5FE6`; on a 128K's first entry page RAM 0 and return to the loader**

Copies the 21 bytes of PagedReadStub `$C4A6` to PagingStub `$5FE6` on every entry. Has128K `$5FFE` nonzero and GameLoaded `$5FFF` zero: the first entry, from the loader through Setup and RelocateSelector. Then `$5FE6-$5FE7` = `$ED`,`$79` (OUT (C),A) and `$5FE8` = `$C9` (RET), BC = `$7FFD`, A = `$10` and JP `$5FE6`: RAM 0 at `$C000`, ROM 1, and the RET returns to the loader's CALL `$7200` (to `$5D64`), whose stack still holds that address. Otherwise SelectorRun `$C0FC`.

c1: the first entry at frame 11841 takes the patch (`$C0E9-$C0F9` once; `$5FE6` then runs OUT and RET once); the second (frame 22215, from the game) runs the selector. explorers: six entries, all to the selector.

Witness: L1 8 (c1, explorers).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CopyExplorerSet` (`$C134`)

**Copy the chosen explorer's data set (`$1200` bytes) to ExplorerSet `$6000`**

Reached from SelectorLoop `$C112` with FIRE on an explorer (Explorer `$5B70` = 0-4). 128K: the set's bank and address: 0 RAM 4 `$C000`, 1 RAM 4 `$D200`, 2 RAM 4 `$E400`, 3 RAM 3 `$C000`, 4 RAM 3 `$D200` (where Setup `$C005` put them); each byte is read through PagingStub `$5FE6` (A = the bank, HL = the address; RAM 1 is paged back after each byte) and stored at `$6000` up. RET returns to the game's menu (`$8F61`), which starts the game.

48K (CopySet48K `$C175`): the set at `$9CF8` + `$1200` x Explorer, where the tape put it, copied by LDIR; then stream 2 opened and StartTapeText `$C2E8` printed by RST `$10` up to its `$0D`, and RET to the loader at `$5D64` with interrupts on. Known only from the code.

c1: explorer 1 (Herr Krusche), 4608 stub calls; explorers: all five, each branch of the bank and address chain `$C13F-$C159` taken.

Witness: L1 6 (c1, explorers).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `RestoreUnderCursor` (`$C1A2`)

**Put back the picture's bytes under the cursor (3 bytes x 16 rows)**

From CursorScreen `$C4A4` (the screen address DrawCursor `$C314` stored), each of 16 pixel rows: the 3 bytes at the same place in SelectorPicture `$CF0F` (address - `$4000` + `$CF0F`) copied to the screen, then one row down (PixelDown `$C35F`). Called by SelectorWait `$C12A` after the HALT, before the next DrawCursor.

c1: 1126 calls (frames 22225-23350).

Witness: L1 3452 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,126 calls, 3,603,200 t-states own (0.19 %) |
| Runs (the other recordings) | 2,326 calls (`stage1/explorers` 2,326) |
| Called from | `SelectorStart` |
| Calls | `PixelDown` |
| Reads | `$C4A4`-`$C4A5` (`CursorScreen`); `$CFBB`-`$DFC7` (`SelectorPicture+172`); `$E011`-`$E0C7` (`SelectorPicture+4354`); `$E111`-`$E1C7` (`SelectorPicture+4610`); `$E211`-`$E2C7` (`SelectorPicture+4866`); `$E311`-`$E3C7` (`SelectorPicture+5122`); 3 more ranges |

#### `DrawSelectorPicture` (`$C1C9`)

**Copy SelectorPicture (6912 bytes) to the screen**

LDIR of SelectorPicture `$CF0F` to `$4000-$5AFF`. Called by SelectorRestart `$C106`. c1: once, frame 22221.

Witness: L1 7 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 190,280 t-states own (0.01 %) |
| Runs (the other recordings) | 6 calls (`stage1/explorers` 6) |
| Called from | `SelectorStart` |
| Reads | `$CF0F`-`$EA0E` (`SelectorPicture`, `SelectorAttributes`) |

#### `MoveCursor` (`$C1D5`)

**Read the devices, move the cursor 2 pixels, set Explorer from its place**

Out: E = the device bits (ReadAnyDevice `$C3BF`: bit 0 right, 1 left, 2 down, 3 up, 4 FIRE); CursorXY `$C4A2` moved 2 pixels a step within x 0-`$E8` and y 0-`$A8` (L = x, H = y: the cursor's top left); Explorer `$5B70` set: 0 Fortisque-Smithe (y < `$4D`, `$4C` <= x < `$91`), 1 Herr Krusche (`$0C` <= y < `$57`, x >= `$BC`), 2 Henri Beaucoup (`$6E` <= y < `$A9`, `$B0` <= x < `$DB`), 3 Big John Caine (x < `$36`, `$3C` <= y < `$7D`), 4 Wu Pong (`$52` <= x < `$7F`, y >= `$86`), `$FE` Help (`$0A` <= x < `$22`, y >= `$8C`), else `$FF`; the tests in that order, the first that holds. Then three calls to ShowCoords `$C4D6` (Explorer at `$4040`, x at `$4000`, y at `$4020`), which returns at once.

c1: 1127 calls; explorers: every region reached (`$C219`, `$C22A`, `$C23F`, `$C250`, `$C261`, `$C273` taken).

Witness: L1 3459 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,127 calls, 862,979 t-states own (0.05 %) |
| Runs (the other recordings) | 2,332 calls (`stage1/explorers` 2,332) |
| Called from | `SelectorStart` |
| Calls | `ReadAnyDevice`, `ShowCoords` |
| Reads | `$C4A2`-`$C4A3` (`CursorXY`) |
| Writes | `$C4A2`-`$C4A3` (`CursorXY`) |

#### `ShowStopTape` (`$C295`)

**The 48K's first screen: STOP THE TAPE / THEN PRESS SPACE KEY, wait for SPACE**

Opens stream 2, sets Chars `$5C36` to `$3C00` (the ROM font), prints StopTapeText `$C2B8` by RST `$10` up to its `$0D`, then waits until SPACE (port `$7FFE` bit 0) is down. Called by SelectorRun `$C0FC` only when Has128K `$5FFE` = 0: not executed in any recording (c1, explorers: 128K). Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `DrawCursor` (`$C314`)

**Draw the hand cursor at CursorXY, masked, from the frame for its pixel shift**

PixelToScreen `$C39C` gives BC = the screen address of CursorXY `$C4A2` and A = x AND 6; BC is kept in CursorScreen `$C4A4` for RestoreUnderCursor `$C1A2`. The frame: CursorSprites `$CD8F` + `$60` x (A / 2), four frames pre-shifted 0, 2, 4, 6 pixels. Three columns of 16 rows (DrawColumn16 `$C34B`): screen = (screen AND mask) OR graphic, the graphic the frame's first 48 bytes, the mask the next 48.

c1: 1127 calls; explorers: all four frames (`$C333` taken 43 times).

Witness: L1 3459 (c1, explorers).

[Animation: `DrawCursor` at work](img/routines/DrawCursor.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,127 calls, 486,587 t-states own (0.03 %) |
| Runs (the other recordings) | 2,332 calls (`stage1/explorers` 2,332) |
| Called from | `SelectorStart` |
| Calls | `DrawColumn16`, `PixelToScreen` |
| Reads | `$C4A2`-`$C4A3` (`CursorXY`) |
| Writes | `$C4A4`-`$C4A5` (`CursorScreen`) |

#### `DrawColumn16` (`$C34B`)

**Draw 16 rows of one cursor column: two DrawColumn8**

The chain `$C34B`, `$C34E`, `$C351`, `$C354` each call the next and fall into it, so PlotCursorByte `$C357` runs 16, 8, 4, 2 times from each entry. c1: 3381 calls (1127 x 3 columns).

Witness: L1 10377 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,381 calls, 57,546 t-states own (0.00 %) |
| Runs (the other recordings) | 6,996 calls (`stage1/explorers` 6,996) |
| Called from | `DrawCursor` |
| Calls | `DrawColumn8` |

#### `DrawColumn8` (`$C34E`)

**8 rows: two DrawColumn4**

Witness: L1 20754 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 6,762 calls, 115,121 t-states own (0.01 %) |
| Runs (the other recordings) | 13,992 calls (`stage1/explorers` 13,992) |
| Called from | `DrawColumn16`, `PixelDown` |
| Calls | `DrawColumn4` |

#### `DrawColumn4` (`$C351`)

**4 rows: two DrawColumn2**

Witness: L1 41508 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 13,524 calls, 230,167 t-states own (0.01 %) |
| Runs (the other recordings) | 27,984 calls (`stage1/explorers` 27,984) |
| Called from | `DrawColumn8`, `PixelDown` |
| Calls | `DrawColumn2` |

#### `DrawColumn2` (`$C354`)

**2 rows: two PlotCursorByte**

Witness: L1 83016 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 27,048 calls, 460,308 t-states own (0.02 %) |
| Runs (the other recordings) | 55,968 calls (`stage1/explorers` 55,968) |
| Called from | `DrawColumn4`, `PixelDown` |
| Calls | `PlotCursorByte` |

#### `PlotCursorByte` (`$C357`)

**One cursor byte: (BC) = (BC) AND (DE) OR (HL), then a row down**

HL = the graphic, DE = the mask, BC = the screen; HL and DE step on and the code falls into PixelDown `$C35F`. c1: 54 096 runs (3381 x 16).

Witness: L1 166032 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 54,096 calls, 2,598,988 t-states own (0.14 %) |
| Runs (the other recordings) | 111,936 calls (`stage1/explorers` 111,936) |
| Called from | `DrawColumn2`, `PixelDown` |
| Calls | `PixelDown` |
| Reads | `$CD8F`-`$CF0E` (`CursorSprites`, `CursorMask0`, `CursorFrame2`, `CursorMask2` and 4 more) |

#### `PixelDown` (`$C35F`)

**BC = the screen address one pixel row down**

The usual display-file walk: B + 1; across a character row back to its top and C + `$20`; across a third (C's top three bits all set) C AND `$1F` and B + 8. Used by PlotCursorByte `$C357` and RestoreUnderCursor `$C1A2`.

Witness: L1 221264 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 72,112 calls, 2,417,447 t-states own (0.13 %) |
| Runs (the other recordings) | 149,152 calls (`stage1/explorers` 149,152) |
| Called from | `RestoreUnderCursor`, `PlotCursorByte` |
| Calls | `DrawColumn8`, `DrawColumn4`, `DrawColumn2`, `PlotCursorByte` |

#### `ClearScreen` (`$C37F`)

**Black border, the bitmap cleared, attributes `$47` (bright white on black)**

Called by SelectorRun `$C0FC` and SelectorRestart `$C106`. c1: twice (frames 22215-22221).

Witness: L1 14 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 417,711 t-states own (0.02 %) |
| Runs (the other recordings) | 12 calls (`stage1/explorers` 12) |
| Called from | `SelectorStart` |
| Ports out | `$00FE` |

#### `PixelToScreen` (`$C39C`)

**Pixel x (L), y (H) to the screen address BC and the pixel shift A**

Out: BC = `$4000` + the display-file address of the byte holding pixel (x, y); A = x AND 6 (x is always even); flags from the AND. Used by DrawCursor `$C314`.

Witness: L1 3459 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,127 calls, 163,415 t-states own (0.01 %) |
| Runs (the other recordings) | 2,332 calls (`stage1/explorers` 2,332) |
| Called from | `DrawCursor` |

### The 128K setup and the explorer selector (RAM 1): input

`src/select/input.asm`

#### `ReadAnyDevice` (`$C3BF`)

**Poll the keyboard, a Kempston (when present), then Sinclair; A = the first nonzero reading**

Out: A = the bits (0 right, 1 left, 2 down, 3 up, 4 FIRE), NZ when any; InputDevice `$C3BE` = the device read last. Kempston presence: port `$1F` ORed over 256 reads, bits 5-7 must stay 0. After the Sinclair read InputBits is cleared (A keeps the reading). Called by MoveCursor `$C1D5`.

c1: 1127 calls, 796 reach Sinclair (the Kempston moved the cursor there); explorers: keyboard FIRE and right (`$C477`, `$C488`), Sinclair left and FIRE (`$C424`, `$C41E`) taken.

Witness: L1 3459 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1,127 calls, 12,885,148 t-states own (0.68 %) |
| Runs (the other recordings) | 2,332 calls (`stage1/explorers` 2,332) |
| Called from | `MoveCursor` |
| Calls | `ReadDeviceFiltered` |
| Writes | `$C3BD`-`$C3BE` (`InputBits`, `InputDevice`) |
| Ports in | `$001F`, `$011F`, `$021F`, `$041F`, `$081F`, `$101F`, `$111F` |

#### `ReadDeviceFiltered` (`$C3EC`)

**ReadDevice, with left+right or up+down taken as nothing**

Out: A = E = the bits, or A = 0 when bits 0 and 1 or bits 2 and 3 are both set.

Witness: L1 9690 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,050 calls, 380,682 t-states own (0.02 %) |
| Runs (the other recordings) | 6,640 calls (`stage1/explorers` 6,640) |
| Called from | `ReadAnyDevice` |
| Calls | `ReadDevice` |

#### `ReadDevice` (`$C403`)

**Read InputDevice's keys or port into InputBits; A = the bits**

HL = InputBits `$C3BD`, cleared, then by InputDevice `$C3BE`: 0 ReadKeyboard `$C46E`, 1 ReadKempston `$C43C` (port `$1F` AND `$1F`, already in this order), 2 the Sinclair keys on half row `$EFFE`: 0 FIRE, 6 left, 7 right, 8 down, 9 up. All end at InputDone `$C4A0` (A = InputBits).

Witness: L1 9690 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,050 calls, 705,734 t-states own (0.04 %) |
| Runs (the other recordings) | 6,640 calls (`stage1/explorers` 6,640) |
| Called from | `ReadDeviceFiltered` |
| Reads | `$C3BD`-`$C3BE` (`InputBits`, `InputDevice`) |
| Writes | `$C3BD` (`InputBits`) |
| Ports in | `$001F`, `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$FEFE` |

#### `ReadCursorKeys` (`$C444`)

**The cursor keys 5 6 7 8 and 0 to InputBits: no path reaches it**

Port `$F7FE` bit 4 (5) left; port `$EFFE` bit 0 (0) FIRE, bit 2 (8) right, bit 3 (7) up, bit 4 (6) down; ends at InputDone `$C4A0`. ReadDevice `$C403` has no device number for it and nothing jumps here (the bytes after ReadKempston's JP); its JP operand `$C46C` is in RelocTable, so it was assembled as live code. Not executed in any recording (c1, explorers); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ReadKeyboard` (`$C46E`)

**The keyboard to InputBits: SPACE FIRE, Z left, X right, O up, K down**

Ports `$7FFE` (SPACE), `$FEFE` (Z, X), `$DFFE` (O), `$BFFE` (K); a pressed key reads 0. InputDone `$C4A0` returns A = InputBits; ReadSinclair, ReadKempston and ReadCursorKeys jump there too.

Witness: L1 3459 (c1, explorers).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### The 128K setup and the explorer selector (RAM 1): paging

`src/select/paging.asm`

#### `PagedReadStub` (`$C4A6`)

**Read the byte at HL in RAM A, then page RAM 1 back (run as a copy at `$5FE6`)**

In: A = the RAM (3 or 4), HL = the address (`$C000-$FFFF`). Out: A = the byte; RAM 1 paged at `$C000` again; BC = `$7FFD`. Port `$7FFD` gets A OR `$10` (ROM 1, the 48 BASIC ROM), then `$11`. Never run here: SelectorEntry copies these 21 bytes to `$5FE6` on every entry, and CopyExplorerSet `$C134` calls `$5FE6`. On a 128K's first entry `$5FE6-$5FE8` are patched to OUT (C),A; RET before the jump there.

c1: `$5FE6` runs 4609 times (4608 calls from `$C165`, one jump from `$C0F9`).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### The 128K setup and the explorer selector (RAM 1): print

`src/select/print.asm`

#### `PrintGlyph` (`$C4BB`)

**Print the ROM-font glyph of A at screen address HL; HL + 1**

The 8 bytes at `$3C00` + 8 x A copied down the character cell (D + 1 a row). BC, DE kept; HL returns + 1. Called by PrintPage `$C574` for each character, and by PrintNumber3 `$C4D7` and PrintDigit `$C52C` (never executed).

explorers: 3878 calls (the Help pages).

Witness: L1 3878 (explorers).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,878 calls (`stage1/explorers` 3,878) |
| Called from | `PrintPage` |

#### `ShowCoords` (`$C4D6`)

**RET: the coordinate read-out switched off**

MoveCursor `$C1D5` calls it three times a pass with A = Explorer, x, y and DE = `$4040`, `$4000`, `$4020`. The RET stops it in front of PrintNumber3 `$C4D7`, which would print A in decimal at DE.

c1: 3381 runs (1127 x 3).

Witness: L1 10377 (c1, explorers).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 3,381 calls, 52,369 t-states own (0.00 %) |
| Runs (the other recordings) | 6,996 calls (`stage1/explorers` 6,996) |
| Called from | `MoveCursor` |

#### `PrintNumber3` (`$C4D7`)

**Print A (0-255) as three decimal digits at DE, leading zeros as spaces after the number**

DigitBuffer `$5BA6-$5BA8` gets the hundreds, tens and units as ASCII by repeated subtraction; the leading "0" digits are skipped (B counts them) and as many spaces printed after the digits (PrintGlyph `$C4BB`), so the field is always three characters. AF kept. Its CALL operands are in RelocTable, so it was live code once; ShowCoords' RET at `$C4D6` cuts it off. Not executed in any recording (c1, explorers); known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintDigit` (`$C52C`)

**Print the digit at (HL) at screen address DE**

PrintGlyph `$C4BB` with HL and DE kept. Called only by PrintNumber3 `$C4D7`: not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### The 128K setup and the explorer selector (RAM 1): help

`src/select/help.asm`

#### `ShowHelp` (`$C536`)

**Show the Help pages until ENTER, then back to the selector**

Reached by JP from SelectorLoop `$C112` with FIRE on the Help box (Explorer `$5B70` = `$FE`). Has128K `$5FFE` = 0: Help48KText `$C5F9` first, then the keyboard must be released. Then the title and page 1, page 2, page 3 in a loop while SPACE answers; ENTER at any page jumps to SelectorRestart `$C106`.

explorers: once (frames 13 750-15 190): the title and page 1 three times, pages 2 and 3 twice each.

Witness: L1 1 (explorers).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/explorers` 1) |
| Called from | `SelectorStart` (tail) |
| Calls | `PrintPage` |

#### `PrintPage` (`$C574`)

**Clear the screen to blue and print a page of text bytes; A = 1 for SPACE, 0 for ENTER**

In: HL = the page. Border 1, bitmap `$4000-$57FF` cleared, attributes `$0F`; B = row, C = column from 0, 0. The byte codes: `$16` c r position, `$0D` next row, `$01` pause and return (A = 0), `$00` wait for SPACE or ENTER and return, else PrintGlyph `$C4BB` at H = `$40` OR (B AND `$18`), L = (B x 32 AND `$E0`) OR C, the column wrapping at 32. Out: A = 1 (NZ) for SPACE, 0 (Z) for ENTER or after a pause.

explorers: 10 calls, 3878 glyphs, 3 pauses.

Witness: L1 10 (explorers).

[Animation: `PrintPage` at work](img/routines/PrintPage.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 10 calls (`stage1/explorers` 10) |
| Called from | `ShowHelp` |
| Calls | `PrintGlyph` |
| Reads | `$C708`-`$CD8E` (`HelpTitle`, `HelpPage1`, `HelpPage2`, `HelpPage3`) |
| Ports in | `$7FFE`, `$BFFE` |
| Ports out | `$01FE` |


## The AY music player (RAM 6) (`src/music/music.json`)

Terramex, Grandslam 1987: TZX block 4 `$6000-$71FF`, the AY music player and its tunes, which the 128K setup copies
to RAM 6, where the IM 2 handler calls it at `$C000` every frame. Its entries are `src/music/<module>.asm`, written
from `src/music/music.ann` by `kit/mkgame.py --part src/music/music.json`; the recordings: `work/stage1/c1` (c1:
power-on, the original tape at ROM speed on the 128K, the menu, the selector and play), and `work/stage1/explorers`,
`work/stage1/gameover`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`player`](#the-ay-music-player-ram-6-player) | `$C000`-`$C026`, `$C1E4`-`$C28F`, `$C780`-`$C7D0` | 5 of 5 |
| [`state`](11-data-reference.md#the-ay-music-player-ram-6-state) | `$C027`-`$C1E3` | 0 of 14 |
| [`ay`](#the-ay-music-player-ram-6-ay) | `$C290`-`$C2E3`, `$CD56`-`$CD5C` | 3 of 3 |
| [`channel`](#the-ay-music-player-ram-6-channel) | `$C2E4`-`$C554`, `$C7D1`-`$C82C` | 15 of 18 |
| [`effects`](#the-ay-music-player-ram-6-effects) | `$C555`-`$C77F` | 5 of 5 |
| [`tunes`](11-data-reference.md#the-ay-music-player-ram-6-tunes) | `$C82D`-`$CD55`, `$CD5D`-`$D1FF` | 0 of 46 |

### The AY music player (RAM 6): player

`src/music/player.asm`

#### `MusicFrame` (`$C000`)

**Play one frame of music: the IM 2 handler's call**

Saves AF (in AF'), AF', DE, HL, IX and IY around MusicTick `$C014` and returns with them. BC is not saved: the caller, the IM 2 handler `$9491`, saves it (PUSH BC at `$9498`) and pages RAM 6 before the CALL `$C000` at `$94A0` and the old page (`$5FE5` Last7FFD) after it.

Called once a frame: c1 runs it 5029 times in the 5029 frames from 21599 to 26627; explorers 15 190 of 15 190, gameover 6000 of 6000.

Witness: L1 83616 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

[Animation: `MusicFrame` at work](img/routines/MusicFrame.gif)

[Animation: `MusicFrame` at work, frames](img/routines/MusicFrame-frames.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 5,029 calls, 784,524 t-states own (0.04 %) |
| Runs (the other recordings) | 21,190 calls (`stage1/explorers` 15,190, `stage1/gameover` 6,000) |
| Calls | `MusicTick` |

#### `MusicTick` (`$C014`)

**Start tune 0 if no tune is playing, else play one frame of it**

PlayerState `$C027` = 0: JP StartTune `$C79F` with A = 0 (the tune number), which returns to MusicFrame. Else UpdateTune `$C1E4` with IY saved.

c1 runs StartTune once (frame 21599, the first call after GameEntry); explorers and the rzx pieces once after each EndTune.

Witness: L1 83616 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 5,029 calls, 487,743 t-states own (0.03 %) |
| Runs (the other recordings) | 21,190 calls (`stage1/explorers` 15,190, `stage1/gameover` 6,000) |
| Called from | `MusicFrame` |
| Calls | `UpdateTune`, `StartTune` (tail) |
| Reads | `$C027` (`PlayerState`) |

#### `UpdateTune` (`$C1E4`)

**Play one frame of the tune: end the expiring notes, update channels A, B and C, write the AY**

Called by MusicTick `$C014` while PlayerState `$C027` is 1 (the RET Z at `$C1E8` is a second guard: it never returns there in any recording).

First, for each channel whose note timer (+`$03`) is 1: the timer becomes 0 and NoteEndFlag `$C14D` goes up, so the note lasts exactly its duration in frames and the channel reads its next event this frame. Then for each channel n = 0, 1, 2: ChannelIndex `$C1E3` = n, SlotRowOp+1 = 8n, IX = the channel's record, the word n of the tune's entry (TunePointer `$C14B`) into the operands of OrderListOp1 `$C315`, OrderListOp2 `$C7D6`, OrderListOp3 `$C7E9` and OrderListOp4 `$C807`, DE = PatternPointers[n]; CALL UpdateChannel `$C2E4`. Last, H = `$FF` and L = `$BF` (the high bytes of the AY ports `$FFFD` and `$BFFD`), C = `$FD`, and WriteAY `$C290` unless NoteEndFlag is up.

Out: the channel records, PatternPointers and the AY registers updated, NoteEndFlag 0. When channel A meets its order list's end, EndTune `$C780` drops UpdateChannel's return, so channels B and C are not updated that frame.

Witness: L1 83609 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 5,028 calls, 5,644,739 t-states own (0.30 %) |
| Runs (the other recordings) | 21,189 calls (`stage1/explorers` 15,189, `stage1/gameover` 6,000) |
| Called from | `MusicTick` |
| Calls | `WriteAY`, `EndFrame` (tail), `UpdateChannel`, `AYWrite` |
| Reads | `$C027` (`PlayerState`); `$C14B`-`$C156` (`TunePointer`, `NoteEndFlag`, `MixerImage`, `PlayerSpare` and 1 more); `$C170`-`$C172` (`ChannelAPeriod`, `ChannelAVolume`); `$C183` (`ChannelBTimer`); `$C19D`-`$C19F` (`ChannelBPeriod`, `ChannelBVolume`); `$C1B0` (`ChannelCTimer`); 2 more ranges |
| Writes | `$C14D`-`$C156` (`NoteEndFlag`, `MixerImage`, `PlayerSpare`, `ChannelA`); `$C183` (`ChannelBTimer`); `$C1B0` (`ChannelCTimer`); `$C1E3` (`ChannelIndex`); `$C316`-`$C317` (`OrderListOp1+1`); `$C3DB` (`SlotRowOp+1`); 3 more ranges |

#### `EndTune` (`$C780`)

**The order list's `$FF`: silence, PlayerState 0, the AY written, the frame over**

From ReadOrderList `$C31F`. The three volumes (+`$1F`) 0 (each written twice), PlayerState `$C027` = 0, UpdateChannel's return dropped (POP AF: the channels after this one are not updated), then WriteAY `$C290` with H = `$FF`, L = `$BF`, C = `$FD`, whatever NoteEndFlag. MusicTick's next call starts tune 0 again (StartTune `$C79F`): the frame after.

Ran at frame 9581 in explorers and once in r08000, r18000, r28000, r38000 and r48000, 9698 frames apart.

Witness: L1 6 (explorers, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/explorers` 1) |
| Called from | `ReadOrderList` (tail) |
| Calls | `WriteAY` (tail) |
| Writes | `$C027` (`PlayerState`); `$C172` (`ChannelAVolume`); `$C19F` (`ChannelBVolume`); `$C1CC` (`ChannelCVolume`) |

#### `StartTune` (`$C79F`)

**Start tune A: its entry, the empty patterns, the channel records cleared, PlayerState 1**

A = the tune (0-3; always 0: MusicTick's JP Z at `$C018` is the only way in). TuneNumberOp+1 = A (channel C is written only for tune 0); TunePointer `$C14B` = TuneTable `$C967` + 6A; PatternPointers `$C1DA` = EmptyPattern `$C82D` for all three; ChannelA-ChannelC (`$C153-$C1D9`) zero; PlayerState `$C027` = 1. A is kept. SlotTable, MixerImage and the AY are not touched; nothing sounds this frame.

Ran once in c1 (frame 21599), once in explorers (9582) and after each EndTune in the rzx pieces.

Witness: L1 7 (c1, explorers, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 1 call, 3,035 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/explorers` 1) |
| Called from | `MusicTick` (tail) |
| Reads | `$C153`-`$C1D8` (`ChannelA`, `ChannelB`, `ChannelC`) |
| Writes | `$C027` (`PlayerState`); `$C14B`-`$C1DF` (`TunePointer`, `NoteEndFlag`, `MixerImage`, `PlayerSpare` and 4 more); `$C2AF` (`TuneNumberOp+1`) |

### The AY music player (RAM 6): ay

`src/music/ay.asm`

#### `WriteAY` (`$C290`)

**Write the periods, the mixer and the volumes to the AY**

In: H = `$FF`, L = `$BF`, C = `$FD` (the ports for AYWrite `$CD56`). Reached from UpdateTune `$C1E4` when NoteEndFlag `$C14D` is 0, and from EndTune `$C780` (the silence at the tune's end; it jumps here whatever the flag). Falls into EndFrame `$C2DF`.

explorers: 13 411 writes in 15 190 frames (the other 1778 frames a note ended).

Witness: L1 73906 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13,411 calls (`stage1/explorers` 13,411) |
| Called from | `UpdateTune`, `EndTune` (tail) |
| Calls | `AYWrite` |
| Reads | `$C14E` (`MixerImage`); `$C170`-`$C172` (`ChannelAPeriod`, `ChannelAVolume`); `$C19D`-`$C19F` (`ChannelBPeriod`, `ChannelBVolume`); `$C1CA`-`$C1CC` (`ChannelCPeriod`, `ChannelCVolume`) |

#### `EndFrame` (`$C2DF`)

**Clear NoteEndFlag: the frame's update is over**

Reached by WriteAY `$C290` falling in and by UpdateTune's JR NZ at `$C28E` (a frame with no AY write). Returns to MusicTick `$C014`, UpdateTune's caller (after EndTune too, which dropped UpdateChannel's return).

Witness: L1 83609 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,778 calls (`stage1/explorers` 1,778) |
| Called from | `UpdateTune` (tail) |
| Writes | `$C14D` (`NoteEndFlag`) |

#### `AYWrite` (`$CD56`)

**Write A to AY register D**

In: D = the register, A = the value, H = `$FF`, L = `$BF`, C = `$FD`. OUT (`$FFFD`),D selects the register, OUT (`$BFFD`),A writes it; B is left `$BF`. Called by WriteAY `$C290` 10 times a frame (7 for a tune other than 0).

The recordings' only AY writer after the 128K ROM's power-on set-up (ports_out `$FFFD`, `$BFFD` in all 34). explorers: 134 110 calls in 13 411 writes (10 each).

Witness: L1 739060 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 43,950 calls, 1,845,900 t-states own (0.10 %) |
| Runs (the other recordings) | 186,870 calls (`stage1/explorers` 134,110, `stage1/gameover` 52,760) |
| Called from | `UpdateTune`, `WriteAY` |
| Ports out | `$BFFD`, `$FFFD` |

### The AY music player (RAM 6): channel

`src/music/channel.asm`

#### `UpdateChannel` (`$C2E4`)

**Play one frame of the channel IX: the next event when its note is over, else the effects**

In: IX = the channel record, DE = its pattern (PatternPointers), the order-list operands and SlotRowOp set by UpdateTune `$C1E4`. Timer (+`$03`) not 0: CheckGateOff `$C555` (the effects). Timer 0: a slide whose count is not `$FF` ends (+`$11` = 0), then ReadPatternEvent `$C2F6`.

Called 3 times a frame by UpdateTune (explorers: 45 565 = 3 x 15 189 less 2, the frame of EndTune).

Witness: L1 250815 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 15,084 calls, 547,744 t-states own (0.03 %) |
| Runs (the other recordings) | 63,565 calls (`stage1/explorers` 45,565, `stage1/gameover` 18,000) |
| Called from | `UpdateTune` |
| Calls | `ReadPatternEvent`, `CheckGateOff` (tail) |
| Reads | `$C156`-`$C164` (`ChannelATimer`); `$C183`-`$C191` (`ChannelBTimer`); `$C1B0`-`$C1BE` (`ChannelCTimer`) |
| Writes | `$C164` (`ChannelATimer+14`); `$C191` (`ChannelBTimer+14`); `$C1BE` (`ChannelCTimer+14`) |

#### `ReadPatternEvent` (`$C2F6`)

**Read the byte at the channel's pattern position: an event, or the pattern's end**

HL = DE + the pattern position (+`$02`). Not `$FF`: PatternEvent `$C36D`. `$FF`: repeats left (+`$04` not 0): one less, the position 0, read again; else ReadOrderList `$C310`. Reached from UpdateChannel `$C2E4` and, after each event that takes no time, from PatternEvent's handlers and StartPattern `$C34A`.

Witness: L1 21280 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 993 calls, 875,745 t-states own (0.05 %) |
| Runs (the other recordings) | 4,072 calls (`stage1/explorers` 2,879, `stage1/gameover` 1,193) |
| Called from | `UpdateChannel`, `ReadOrderList` (tail) |
| Calls | `ReadOrderList` (tail), `ChannelEffects` (tail), `FetchPatternByte` |
| Reads | `$C02A`-`$C08A` (`Instruments+2`); `$C11B`-`$C132` (`SlotTable`); `$C14E`-`$C1E3` (`MixerImage`, `PlayerSpare`, `ChannelA`, `ChannelB` and 5 more); `$C82D`-`$C882` (`EmptyPattern`, `PeriodLo`); `$C8A8`-`$C8EE` (`PeriodHi+14`); `$C906` (`VibratoTable`); 3 more ranges |
| Writes | `$C14E`-`$C1D8` (`MixerImage`, `PlayerSpare`, `ChannelA`, `ChannelB` and 1 more) |

#### `ReadOrderList` (`$C310`)

**Read the channel's next order-list byte: a pattern, a command or the tune's end**

The byte at the order list (the self-modified operand of OrderListOp1) + the position (+`$00`), the position one on. `$FF`: EndTune `$C780`. `$00-$7F`: StartPattern `$C34A`. `$80-$FE`: CommandParam `$C1E0` = the low 5 bits; bits 5-6 x 4 into the JR offset at OrderCommandJump+1: `$80-$9F` SetTranspose `$C7E4`, `$A0-$BF` SetRepeat `$C81B` (OrderJumpRepeat `$C33F`), `$C0-$DF` SetDetune `$C7D1` (OrderJumpDetune `$C343`), `$E0-$FE` SetSlot `$C7F7` (OrderJumpSlot `$C347`). Each handler comes back here for the next byte.

Witness: L1 873 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 64 calls, 15,616 t-states own (0.00 %) |
| Runs (the other recordings) | 231 calls (`stage1/explorers` 165, `stage1/gameover` 66) |
| Called from | `ReadPatternEvent` (tail), `SetDetune` (tail), `SetTranspose` (tail), `SetSlot` (tail), `SetRepeat` (tail) |
| Calls | `ReadPatternEvent` (tail), `EndTune` (tail), `SetDetune` (tail), `SetTranspose` (tail), `SetSlot` (tail), `SetRepeat` (tail) |
| Reads | `$C153` (`ChannelA`); `$C180` (`ChannelB`); `$C1AD` (`ChannelC`); `$C1E3` (`ChannelIndex`); `$C97F`-`$CA03` (`Tune0OrderA`, `Tune0OrderB`, `Tune0OrderC`); `$CA37`-`$CA6C` (`PatternLo`, `PatternHi`) |
| Writes | `$C153`-`$C155` (`ChannelA`); `$C180`-`$C182` (`ChannelB`); `$C1AD`-`$C1AF` (`ChannelC`); `$C1DA`-`$C1E0` (`PatternPointers`, `CommandParam`); `$C33A` (`OrderCommandJump+1`) |

#### `OrderJumpRepeat` (`$C33F`)

**d = 4, `$A0-$BF`: SetRepeat**

Witness: L1 123 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OrderJumpDetune` (`$C343`)

**d = 8, `$C0-$DF`: SetDetune**

Witness: L1 17 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OrderJumpSlot` (`$C347`)

**d = 12, `$E0-$FE`: SetSlot**

Witness: L1 21 (explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `StartPattern` (`$C34A`)

**Start pattern A on the channel**

A = the pattern number (0-26, from ReadOrderList `$C310`). PatternPointers[ChannelIndex] = DE = PatternLo[A] + 256 x PatternHi[A]; the pattern position (+`$02`) = 0; ReadPatternEvent `$C2F6`. A new entry: the cut had it inside OrderJumpSlot's block; it is ReadOrderList's JP Z target at `$C324`.

Witness: L1 479 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PatternEvent` (`$C36D`)

**Act on pattern byte A: a note, a rest, an instrument, an arpeggio or a slide**

A = the byte (not `$FF`), from ReadPatternEvent `$C2F6`. `$00-$7F`: StartNote `$C4C9`. `$A0` d: a rest: the rest timer (+`$16`) and the note timer = d, the period 0, then ChannelEffects `$C55E` counts the first frame. `$80-$8F`: SetInstrument `$C3D8`. `$90-$BE` (but `$A0`): the arpeggio record 8 x (A & `$0F`) into +`$10`; `$BF`: the slide count 0. `$C0-$FE`: the slide: +`$15` = A, its delay +`$14` = A & `$1F`, then the step low (+`$12`), high (+`$13`) and the count (+`$11`). Each but the note and the rest goes on to the next byte (ReadPatternEvent). A new entry: the cut had it inside OrderJumpSlot's block; it is ReadPatternEvent's JR NZ target at `$C2FF`.

The slide and the slide-off code (`$C397-$C3C8`) was not executed in any of the 34 recordings: only patterns 1 and 4 hold a slide, and tune 0 plays neither.

Witness: L1 19804 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SetInstrument` (`$C3D8`)

**Instrument slot A & `$0F`: set the channel's mixer bits, envelope, gate-off time and vibrato**

A = `$80-$8F` (from PatternEvent `$C36D`). IY = Instruments + SlotTable[8 x channel + (A & `$0F`)] (SlotRowOp: the channel's 8 x n). The peak volume (+`$2B`) = record +8. MixerImage `$C14E`: record +2 bit 7 set: the channel's noise on, tone off; clear: tone on, noise off. The attack (step +`$24`, rate +`$25`) from the high nibble of +3 through AttackRates `$CD36`, the decay (+`$21`, +`$22`) from its low nibble, the sustain level (+`$20`) from the high nibble of +4, the release (+`$27`, +`$28`) from its low nibble, the last three through DecayRates `$CD46`; a rate byte with bit 7 is "one step every (byte & `$7F`) frames", the step 1, else "the byte's steps every frame"; nibble 0 is the step 15 every frame. +5 the gate-off time (+`$06`), +7 the vibrato record (+`$0B`). Then the next pattern byte (ReadPatternEvent `$C2F6`). A new entry, for the cut's l_C3D8 inside OrderJumpSlot's block (PatternEvent's JR C at `$C391`).

The slow attack (`$C452`) and the release with a step table entry below `$80` (`$C4A9`) was not executed in any of the 34 recordings: no instrument has them.

Witness: L1 2250 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `StartNote` (`$C4C9`)

**Start note A: its period, the gate and the envelope, its duration, the vibrato, the arpeggio and the slide delay**

A = the note (0-`$7F`), DE = the pattern, from PatternEvent `$C36D`. The period-table index (+`$1C`) = A + 20 + the transpose (+`$01`); the period (+`$1D`/+`$1E`) = PeriodLo/PeriodHi[index] + the detune (+`$09`). The gate on, the volume and the envelope counters 0, the done bits of attack, decay and release clear. The next byte is the duration: the note timer (+`$03`). With a vibrato (+`$0B` not 0): its delay or cycles (+`$0A`) = the record's first byte, the step (+`$0C`) 1. With an arpeggio (+`$10` not 0): the first hold (+`$18`) = ((header & `$78`) >> 3) + 1, the step (+`$17`) 1. The slide delay (+`$14`) again from the slide command (+`$15`). Returns to UpdateChannel's caller: no effects on a note's first frame.

A new entry, for the cut's l_C4C9 inside OrderJumpSlot's block (PatternEvent's JP Z at `$C36F`).

Witness: L1 15424 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SetDetune` (`$C7D1`)

**Order command `$C0`: the next byte is the channel's detune (+`$09`)**

Then ReadOrderList `$C310`. Tune 0's channel B: `$C0` 10 at its start, `$C0` 0 after the intro (pattern 5); a constant added to every period (and so a lower pitch, a little, for the 10).

Witness: L1 17 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 2 calls, 212 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/explorers` 3, `stage1/gameover` 1) |
| Called from | `ReadOrderList` (tail) |
| Calls | `ReadOrderList` (tail) |
| Reads | `$C180` (`ChannelB`); `$C9B3`-`$C9BE` (`Tune0OrderB+1`) |
| Writes | `$C180`-`$C189` (`ChannelB`, `ChannelBTimer`) |

#### `SetTranspose` (`$C7E4`)

**Order command `$80`: the next byte is the channel's transpose (+`$01`, signed semitones)**

Then ReadOrderList `$C310`. Reached by OrderCommandJump `$C339` with offset 0.

Witness: L1 227 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 19 calls, 2,014 t-states own (0.00 %) |
| Runs (the other recordings) | 65 calls (`stage1/explorers` 45, `stage1/gameover` 20) |
| Called from | `ReadOrderList` (tail) |
| Calls | `ReadOrderList` (tail) |
| Reads | `$C153` (`ChannelA`); `$C180` (`ChannelB`); `$C1AD` (`ChannelC`); `$C983`-`$C9CD` (`Tune0OrderA+4`, `Tune0OrderB`); `$C9DF`-`$C9FD` (`Tune0OrderC+5`) |
| Writes | `$C153`-`$C154` (`ChannelA`); `$C180`-`$C181` (`ChannelB`); `$C1AD`-`$C1AE` (`ChannelC`) |

#### `SetSlot` (`$C7F7`)

**Order command `$E0`+n: the next byte is the record offset of the channel's instrument slot n**

SlotTable[8 x channel + n] = the byte (SlotRowOp+1 gives 8 x channel, CommandParam `$C1E0` n), through the self-modified SlotIndexOp. Then ReadOrderList `$C310`. Tune 0 uses it three times on channel B: slot 0 = `$48` (record 8), slot 6 = `$51` (record 9), then `$5A` (record 10); the change outlives the tune (StartTune does not reset SlotTable).

Witness: L1 21 (explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/explorers` 3, `stage1/gameover` 1) |
| Called from | `ReadOrderList` (tail) |
| Calls | `ReadOrderList` (tail) |
| Reads | `$C180` (`ChannelB`); `$C1E0` (`CommandParam`); `$C3DB` (`SlotRowOp+1`); `$C9C4`-`$C9D5` (`Tune0OrderB+18`) |
| Writes | `$C123`-`$C129` (`SlotTable+8`); `$C180` (`ChannelB`); `$C810` (`SlotIndexOp+1`) |

#### `SetRepeat` (`$C81B`)

**Order command `$A0`+n: play the next pattern n times**

The repeats left (+`$04`) = n - 1 (n 0: 255, so 256 plays); ReadPatternEvent `$C2F6` replays the pattern while it is not 0. Then ReadOrderList `$C310`.

Witness: L1 123 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 11 calls, 506 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/explorers` 23, `stage1/gameover` 10) |
| Called from | `ReadOrderList` (tail) |
| Calls | `ReadOrderList` (tail) |
| Reads | `$C1E0` (`CommandParam`) |
| Writes | `$C157` (`ChannelATimer+1`); `$C184` (`ChannelBTimer+1`); `$C1B1` (`ChannelCTimer+1`) |

#### `FetchPatternByte` (`$C825`)

**A = the byte at the channel's pattern position: DE + (+`$02`)**

Called by PatternEvent `$C36D` for a rest's duration and a slide's three bytes.

Witness: L1 76 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 4 calls, 216 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/explorers` 16, `stage1/gameover` 8) |
| Called from | `ReadPatternEvent` |
| Reads | `$C182` (`ChannelB+2`); `$C1AF` (`ChannelC+2`); `$CAF2`-`$CAF4` (`Pattern6+48`); `$CBCD` (`Pattern12+1`); `$CD34` (`Pattern26+1`) |

### The AY music player (RAM 6): effects

`src/music/effects.asm`

#### `CheckGateOff` (`$C555`)

**Gate off when the note timer reaches the gate-off time; then the effects**

A = the note timer (from UpdateChannel `$C2E4`). A = +`$06`: the gate bit (+`$2A` bit 0) clear: the release. Falls into ChannelEffects.

Witness: L1 235309 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 14,123 calls, 455,039 t-states own (0.02 %) |
| Runs (the other recordings) | 59,617 calls (`stage1/explorers` 42,776, `stage1/gameover` 16,841) |
| Called from | `UpdateChannel` (tail) |
| Calls | `ChannelEffects` |
| Reads | `$C159` (`ChannelATimer+3`); `$C17D`-`$C186` (`ChannelAVolume+11`, `ChannelB`); `$C1AA`-`$C1B3` (`ChannelBVolume+11`, `ChannelC`); `$C1D7` (`ChannelCVolume+11`) |
| Writes | `$C17D` (`ChannelAVolume+11`); `$C1AA` (`ChannelBVolume+11`); `$C1D7` (`ChannelCVolume+11`) |

#### `ChannelEffects` (`$C55E`)

**The rest timer, the note timer and the envelope, then the vibrato, the arpeggio and the slide**

A rest (timer +`$16` not 0): one less; at 0 the note timer 0 (the next event next frame); no effects. Else the note timer one less; NoteEndFlag `$C14D` up: return. Gate on: the attack (every rate frames, the volume + the step, to the peak), then the decay (to the sustain level). Gate off: the release (to 0). Then VibratoEffect `$C609` (fall through).

Witness: L1 235385 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, the selector and play) | 14,127 calls, 7,553,416 t-states own (0.40 %) |
| Runs (the other recordings) | 59,641 calls (`stage1/explorers` 42,792, `stage1/gameover` 16,849) |
| Called from | `ReadPatternEvent` (tail), `CheckGateOff` |
| Reads | `$C14D`-`$C1E0` (`NoteEndFlag`, `MixerImage`, `PlayerSpare`, `ChannelA` and 4 more); `$C854`-`$C88E` (`PeriodLo+38`); `$C8C0`-`$C90D` (`PeriodHi+38`, `VibratoTable`); `$C92F`-`$C958` (`ArpeggioTable+8`) |
| Writes | `$C156` (`ChannelATimer`); `$C172`-`$C1E0` (`ChannelAVolume`, `ChannelB`, `ChannelC`, `PatternPointers` and 1 more) |

#### `VibratoEffect` (`$C609`)

**The vibrato: after its delay, the next of 7 period deltas, its sign flipped every other pass**

A new entry: the end of the envelope, where all its paths join (10 jumps to `$C609` and the fall from `$C606`), and the start of the vibrato. No vibrato (+`$0B` = 0): ArpeggioEffect `$C694`. The delay or cycles byte (+`$0A`): bit 7 clear and not 0: one less, no step this frame; 0: step; bit 7 set: step until its low 7 bits are 0. A step: delta = (VibratoTable-8)[+`$0B` + (step & `$7F`)] (CommandParam `$C1E0` holds its size): the period + delta while the step's bit 7 is clear, the period - delta while it is set. After step 7 the step becomes `$81` (bit 7 flipped, step 1); after the flipped pass's step 7, 1 again: a cycle done, and a cycles count one less.

Records 4, 5 and 7 use it (VibratoTable's only record: delay 40). The cycles form (`$C61A`), and a delta that carries or borrows in the period (`$C654`, `$C670`) was not executed in any of the 34 recordings.

Witness: L1 208864 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ArpeggioEffect` (`$C694`)

**The arpeggio: when the hold ends, the next step's note and hold**

No arpeggio (+`$10` = 0): SlideEffect `$C72F`. The hold (+`$18`) one less; not 0: SlideEffect. Step (+`$17`) 1-7: the byte at ArpeggioTable + 8n + step: the hold = its bits 0-2, the period = the note (+`$1C`) + its bits 3-7 + the detune. Step 0 (a looped arpeggio's restart): the header's bits 3-5 as the hold of the base note (when not 0). After the last step (the header's bits 0-2): 0 when the header's bit 7 is set (loop), else `$FF`; `$FF` at the hold's end: the base note again and `$FE`, after which nothing.

Arpeggios 1-6 ran (patterns 2, 7-9, 13, 16, 18, 19). The end (`$C70E`) was not executed in any of the 34 recordings: arpeggio 1, the only one with no loop, plays on 9-frame notes, which end first.

Witness: L1 208864 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SlideEffect` (`$C72F`)

**The slide: after its delay, the period up or down by half the step, for the count**

A new entry: ArpeggioEffect's paths join here (5 jumps to `$C72F` and the fall from `$C72C`). The delay (+`$14`) not 0: one less. Else with a count (+`$11` not 0; `$FF` endless, else one less): the step (+`$12`/+`$13`) halved; the slide command's bit 5 (+`$15`) set: the period + step/2 (the pitch falls); clear: the period - step/2 - the step's bit 0 (SBC with the carry RR C left). Returns to UpdateTune `$C1E4`.

Ran in no recording past the delay test: tune 0 has no slide (`$C735-$C77C` not executed in any of the 34 recordings).

Witness: L1 208864 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).

| | |
| --- | --- |
| Runs | not reached in the recordings |


## The explorer data sets (`src/explorers/explorers.json`)

Terramex, Grandslam 1987: TZX block 4 `$9CF8-$F6F7`, the five explorer data sets of `$1200` bytes, which the
selector copies to `$6000-$71FF` for the explorer chosen (on the 128K from RAM 4 and 3). Its entries are
`src/explorers/<module>.asm`, written from `src/explorers/explorers.ann` by `kit/mkgame.py --part
src/explorers/explorers.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the
128K, the menu, the selector and play).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`explorers`](11-data-reference.md#the-explorer-data-sets-explorers) | `$9CF8`-`$F6F7` | 0 of 5 |


## The loading screen (`src/screen/screen.json`)

Terramex, Grandslam 1987: TZX block 3, the loading screen, loaded by the loader's LD-BYTES at `$4000`. Its entries
are `src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part
src/screen/screen.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 128K,
the menu, the selector and play).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`screen`](11-data-reference.md#the-loading-screen-screen) | `$4000`-`$5AFF` | 0 of 1 |
