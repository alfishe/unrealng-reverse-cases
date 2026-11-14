# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage2/c1g` (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The BASIC "Rick", Rick1, the first loader stage, The second loader
stage, LoadGroup, the loader of groups 2 and 3, The AY player and tunes (RAM 1)) follow the game, each under its own
heading with its modules, its source, its annotations and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`loader`](11-data-reference.md#loader) | `$5B00`-`$6DFF` | 0 of 11 |
| [`screenwork`](11-data-reference.md#screenwork) | `$6E00`-`$70FF` | 0 of 6 |
| [`charsets`](11-data-reference.md#charsets) | `$7100`-`$82FF` | 0 of 4 |
| [`interrupt`](#interrupt) | `$8300`-`$8400`, `$A215`-`$A238`, `$FEFE`-`$FFFF` | 3 of 8 |
| [`sprites`](11-data-reference.md#sprites) | `$8401`-`$9E94` | 0 of 1 |
| [`font`](11-data-reference.md#font) | `$9E95`-`$9FEC` | 0 of 1 |
| [`sound`](#sound) | `$9FED`-`$A042`, `$A08D`-`$A102` | 5 of 6 |
| [`setup`](#setup) | `$A043`-`$A08C`, `$AB4D`-`$AB92` | 3 of 3 |
| [`controls`](#controls) | `$A103`-`$A214` | 9 of 11 |
| [`render`](#render) | `$A239`-`$A8BE`, `$ADB9`-`$AEBD`, `$AF18`-`$AF55` | 15 of 18 |
| [`hud`](#hud) | `$A8BF`-`$AB4C`, `$ABD8`-`$AC71`, `$AF56`-`$AF63`, `$E466`-`$E49A` | 16 of 34 |
| [`levels`](#levels) | `$AB93`-`$ABD7`, `$AC72`-`$ADB8`, `$E32C`-`$E359`, `$E4AE`-`$E4E4`, `$FD7D`-`$FEFD` | 12 of 17 |
| [`objects`](#objects) | `$AEBE`-`$AF17`, `$EA8E`-`$EC76`, `$ED43`-`$F4C7`, `$F4C8`-`$F850` | 37 of 44 |
| [`leveldata`](11-data-reference.md#leveldata) | `$AF64`-`$E218` | 0 of 8 |
| [`menu`](#menu) | `$E219`-`$E32B`, `$E35A`-`$E3AE` | 4 of 6 |
| [`mainloop`](#mainloop) | `$E3AF`-`$E465`, `$E49B`-`$E4AD` | 5 of 8 |
| [`text`](11-data-reference.md#text) | `$E4E5`-`$EA8D` | 0 of 8 |
| [`rick`](#rick) | `$EC77`-`$ED42`, `$F851`-`$FD53` | 21 of 29 |
| [`vars`](11-data-reference.md#vars) | `$FD54`-`$FD7C` | 0 of 2 |

## interrupt

`src/game/interrupt.asm`

### `SetUpInterrupts` (`$A215`)

**IM 2 with a 257-byte table of `$FE`: the handler at `$FEFE`**

Fills `$8300-$8400` with `$FE`, I = `$83`, IM 2, EI. Called once from Start (c1: 1 run).

Output: A, B, HL changed.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 call, 7,488 t-states own (0.00 %) |
| Called from | `Start` |
| Writes | `$8300`-`$8400` (`Im2Table`) |

### `WaitFrames` (`$A22A`)

**Wait until C frames have been counted since the last wait, then clear the count**

Input: C the number of frames. Enables interrupts, loops until FrameTicks >= C, then FrameTicks = 0. Output: A, F changed.

The frame loop waits for 1 (`$E41C`, after clearing FrameTicks at `$E411` behind a HALT); each scroll step waits for 4 (`$ADD5`, `$AE0C`).

Witness: L1 43086 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,095 calls, 35,192,992 t-states own (3.45 %) |
| Runs (the other recordings) | 41,991 calls (`stage1/level3` 2,926, `stage1/level2` 2,864, `stage1/level1` 2,166 and 48 more) |
| Called from | `ScrollViewDown`, `ScrollViewUp`, `CheckGameComplete` |
| Reads | `$83FF`-`$8400` (`Im2Table+255`); `$A237` (`FrameTicks`) |
| Writes | `$A237` (`FrameTicks`) |

### `Im2Handler` (`$FEFE`)

**The frame interrupt: frame counter, timers, music**

Saves AF, BC, DE, HL, IX, IY; `$A237` + 1; CALL `$E49B`; at `$FF11` three NOPs in the image, CALL `$A030` once

`$A081` has run; restores, EI, RET.

Witness: L1 113425 (beeper48, c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14,301 calls, 3,203,424 t-states own (0.31 %) |
| Runs (the other recordings) | 99,124 calls (`stage1/level3` 5,921, `stage1/level2` 5,870, `stage1/level1` 5,822 and 49 more) |
| Entered by | the interrupt, 113,395 times in 75 routines |
| Calls | `SoundTick`, `FrameTick` |
| Reads | `$69E1`-`$69FA` (`MusicImage+3041`); `$6CFF`-`$6D00` (`LowZeros+95`); `$6DFF`-`$6E00` (`LowZeros+351`, `CellFlagsRow16`); `$7723`-`$7726` (`CharSet0+1571`); `$7A50`-`$7A56` (`CharSet1+80`); `$7B70`-`$7B72` (`CharSet1+368`); 6 more ranges |
| Writes | `$A237` (`FrameTicks`); `$FFEC`-`$FFFF` (`UdgResidue+148`, `GameStack`) |

## sound

`src/game/sound.asm`

### `PlayEffect` (`$9FED`)

**Play sound effect A: on the AY (128K) or the beeper (48K)**

Input: A the effect number. On a 48K (Is48K not 0) calls BeeperEffect with A (and the effect number in C, which the beeper's first OUT uses as the port's low byte). On a 128K pages RAM 1 in (OUT `$7FFD` = 1), calls AyPlayEffect `$C685` with A, pages RAM 0 back (OUT `$7FFD` = 0) and enables interrupts.

Output: AF and C changed on the 128K path; HL, DE, BC preserved there. Interrupts enabled on return. 13 call sites, all in the game code from `$EC93` to `$FD44`.

Witness: L1 6022 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 158 calls, 33,101 t-states own (0.00 %) |
| Runs (the other recordings) | 5,864 calls (`stage1/level2` 539, `stage1/level3` 451, `stage1/level1` 311 and 47 more) |
| Called from | `DynamiteObj`, `AmmoBoxObj`, `TreasureObj`, `TrapTriggers`, `KillEnemy`, `BonusTrigger`, `LandRick`, `FireClearPokeLatch`, `NoFire`, `KillRickNow`, `ChooseRickFrame` |
| Calls | `BeeperEffect` |
| Reads | `$A08D` (`Is48K`) |
| Ports out | `$7FFD` |

### `StartTune` (`$A016`)

**Start tune A on the AY player (128K only)**

Input: A the tune number. Returns at once on a 48K. Else pages RAM 1, calls AyPlayTune `$C3E4`, pages RAM 0 back, enables interrupts.

The tunes the callers start: 5 the title (`$E220`), 0 the game start (`$E324`), 6 the game over (`$E386`), at a level's end the number of the next level, 1-4 (`$AC20`).

Output: AF, BC, D changed.

Witness: L1 34 (beeper48, c1, controls, ending, ending2, gameover, l1end, L3Z12, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4 calls, 491 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/controls` 12, `stage1/level1` 5, `stage1/ending` 3 and 5 more) |
| Called from | `LevelEnd`, `Menu`, `NewGame`, `GameOver`, `BonusCollect` |
| Reads | `$A08D` (`Is48K`) |
| Ports out | `$7FFD` |

### `SoundTick` (`$A030`)

**The AY player's frame tick, called by the interrupt handler**

Pages RAM 1, calls AyTick `$C46C`, pages RAM 0 back and enables interrupts. Called only from the slot at `$FF11` inside the interrupt handler (`$FEFE`), which CopyPlayerToRam1 fills with CALL `$A030` on a 128K: 50 times a second for the whole game (c1: 14 301 runs, one per frame from the entry, frame 19 012, to the end).

Output: AF, BC changed (the handler saves every register).

Witness: L1 111834 (c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14,301 calls, 1,287,090 t-states own (0.13 %) |
| Runs (the other recordings) | 97,533 calls (`stage1/level3` 5,921, `stage1/level2` 5,870, `stage1/level1` 5,822 and 48 more) |
| Called from | `Im2Handler` |
| Ports out | `$7FFD` |

### `BeeperEffect` (`$A08E`)

**Play a sound effect on the beeper (48K)**

Input: A the effect number, C its copy (PlayEffect). B = `$FE`, H = `$10` and L = 0: BeeperTone toggles port `$FE` bit 4 (the speaker) with a black border. The six patterns, E being the half period in loops of DEC C / JR NZ:

0: 50 tones, the period falling 50 ... 1 (a rising chirp). 2: a warble, tones alternating between E + `$32` and E, E climbing by 2 from `$B0` until it wraps to 0. 6: 30 tones from `$28`, the period stepping down by 30, 29 ... 1 (modulo 256). `$0B`: 32 tones, the period rising 1, 5 ... `$7D` (a falling note). 4: a single tone of period `$80`. Any other: a sweep up, periods 1, 9 ... `$F9`, then one tone of period 1 (the down loop adds `$F8` to 1, gets no carry and stops after one step).

The very first OUT of an effect goes to port `$FE00` + the effect number (C still holds it): for an odd effect (`$0B`) the ULA ignores that half wave; after it C is 0.

Output: AF, C, DE changed. Run in beeper48 only (98 effects: the chirp, the warble, the descending steps, the falling note, the click and the sweep branches all ran).

Witness: L1 98 (beeper48).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 98 calls (`stage2/beeper48` 98) |
| Called from | `PlayEffect` |
| Calls | `BeeperTone` (falls into) |

### `BeeperTone` (`$A0F6`)

**One square wave of the beeper: L out, wait E, H out, wait E**

Input: B = `$FE`, C the port's low byte for the first OUT, L and H the two port values, E the half period. Output: C = 0. Called by BeeperEffect only.

Witness: L1 999 (beeper48).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 999 calls (`stage2/beeper48` 999) |
| Called from | `BeeperEffect` (falls into) |
| Ports out | `$FE00`, `$FE02`, `$FE03`, `$FE04`, `$FE06`, `$FE0A`, `$FE0B` |

## setup

`src/game/setup.asm`

### `DetectPaging` (`$A043`)

**Tell a 128K from a 48K by paging RAM 1 in; on a 128K go on to copy the player**

Reads the byte E at `$C000` (RAM 0), pages RAM 1 in, writes E + 1 at `$C000`, pages RAM 0 back and reads `$C000` again. Still E: the write went to another page, the machine pages, and the routine goes on into CopyPlayerToRam1. E + 1: one RAM only (a 48K): the byte is put back and Is48K is set to `$FF`.

Input: none. Output: A, BC, DE changed. Interrupts left disabled. Called once from Start (c1: 1 run, the 128K path).

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 call, 87,923 t-states own (0.01 %) |
| Called from | `Start` |
| Reads | `$5E00`-`$6BA3` (`MusicImage`); `$C000` (`Level4Map4+156`) |
| Writes | `$FF11`-`$FF13` (`Im2MusicCall`) |
| Ports out | `$7FFD` |

### `CopyPlayerToRam1` (`$A069`)

**Copy the AY player and its tunes to RAM 1 and hook its tick into the interrupt handler**

Pages RAM 1, copies the `$0DA4` bytes `$5E00-$6BA3` to `$C000-$CDA3`, pages RAM 0 back, then writes CALL SoundTick (`$CD` `$30` `$A0`) over the three NOPs at `$FF11-$FF13` in the interrupt handler (`$FEFE`).

Entered from DetectPaging on a 128K only. Output: A, BC, DE, HL changed.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |

### `Start` (`$AB4D`)

**The game's entry: the 128K test, IM 2, the data moves, the mirror table, then the title**

Entered by a JP from the loader's second stage (`$5DBB`, c1 frame 19010). DI, SP = 0 (the stack below `$FFFF`), DetectPaging (on a 128K also the player's copy), SetUpInterrupts, then moves the 126 bytes at `$6BA4` to `$6A80` and the next 126 (`$6C22`) to `$7080` (126 bytes is the size of a sprite frame: 21 rows of 6), builds the mirror table, border 0, and jumps to the title at `$E219`.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 41,901 t-states own (0.00 %) |
| Calls | `DetectPaging`, `SetUpInterrupts`, `Menu` (tail) |
| Reads | `$6BA4`-`$6C9F` (`Kind16Frame`, `Kind19Frame`) |
| Writes | `$5B00`-`$5BFF` (`RomPagingRoutines`, `Rom128Variables`); `$6A80`-`$6AFD` (`MusicImage+3200`); `$7080`-`$70FD` (`GraphicSlot19`) |
| Ports out | `$00FE` |

## controls

`src/game/controls.asm`

### `Key1Pressed` (`$A103`)

**Z if the key 1 is held**

Reads port `$F7FE` (keys 1-5) and tests bit 0. Output: A, BC, F. Title only (`$E273`): selects the keyboard (method 0).

Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,724 calls, 228,960 t-states own (0.02 %) |
| Runs (the other recordings) | 1,017 calls (`stage1/controls` 268, `stage1/level1` 249, `stage1/gameover` 157 and 3 more) |
| Called from | `Menu` |
| Ports in | `$F7FE` |

### `Key2Pressed` (`$A10B`)

**Z if the key 2 is held**

Port `$F7FE` bit 1. Title (`$E289`): selects the Kempston (method 1).

Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,724 calls, 228,960 t-states own (0.02 %) |
| Runs (the other recordings) | 1,017 calls (`stage1/controls` 268, `stage1/level1` 249, `stage1/gameover` 157 and 3 more) |
| Called from | `Menu` |
| Ports in | `$F7FE` |

### `Key3Pressed` (`$A113`)

**Z if the key 3 is held**

Port `$F7FE` bit 2. Title (`$E2A1`): selects the cursor keys (method 2).

Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,724 calls, 228,960 t-states own (0.02 %) |
| Runs (the other recordings) | 1,017 calls (`stage1/controls` 268, `stage1/level1` 249, `stage1/gameover` 157 and 3 more) |
| Called from | `Menu` |
| Ports in | `$F7FE` |

### `Key4Pressed` (`$A11B`)

**Z if the key 4 is held**

Port `$F7FE` bit 3. Title (`$E2B9`): selects the Sinclair joystick (method 3).

Witness: L1 6741 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,724 calls, 228,960 t-states own (0.02 %) |
| Runs (the other recordings) | 1,017 calls (`stage1/controls` 268, `stage1/level1` 249, `stage1/gameover` 157 and 3 more) |
| Called from | `Menu` |
| Ports in | `$F7FE` |

### `StartPressed` (`$A123`)

**Z if ENTER, bit 7 of port `$FEFE` or the method's fire is held**

Tests ENTER (port `$BFFE` bit 0), then bit 7 of port `$FEFE` (no key: 1 on a standard machine), then calls ReadInput and tests fire (InputBits bit 4). Output: A, BC, F; InputBits updated when it gets that far.

Callers: the title (`$E219`, `$E2D1`, `$E2D7`), the level text (`$E327`, `$E32C`), the game over (`$E389`, `$E38E`) and the level's end (`$AC38`, `$AC3D`); each waits for the release first, then for the press.

Witness: L1 1340688 (beeper48, c1, controls, ending, ending2, gameover, l1end, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 57,833 calls, 6,930,203 t-states own (0.68 %) |
| Runs (the other recordings) | 1,282,854 calls (`docs/integrate/l1end` 410,192, `stage2/ending2` 236,745, `stage1/ending` 191,302 and 7 more) |
| Called from | `LevelEnd`, `Menu`, `NewGame`, `StartLevel`, `GameOver` |
| Calls | `ReadInput` |
| Reads | `$A14D` (`InputBits`) |
| Ports in | `$BFFE`, `$FEFE` |

### `QuitPressed` (`$A13C`)

**Z if Q is held**

Port `$FBFE` bit 0. Called once a game loop pass (`$E3C9`): Q ends the game (to the game over text at `$E35A`).

Witness: L1 43345 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,073 calls, 44,173 t-states own (0.00 %) |
| Runs (the other recordings) | 42,272 calls (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Called from | `MainLoop` |
| Ports in | `$FBFE` |

### `PausePressed` (`$A144`)

**Z if P is held**

Port `$DFFE` bit 0. The game loop (`$E3D7-$E3E9`): P held waits for its release, the next press and that release; the frame loop (`$E417`) calls it once more without using the result.

Witness: L1 244986 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 160,872 calls, 6,613,630 t-states own (0.65 %) |
| Runs (the other recordings) | 84,114 calls (`stage1/level3` 5,849, `stage1/level2` 5,687, `stage1/level1` 4,288 and 48 more) |
| Called from | `MainLoop`, `CheckGameComplete` |
| Ports in | `$DFFE` |

### `ReadInput` (`$A14E`)

**Read the selected control method into InputBits**

InputBits = `$FF`, then one RES per direction or fire found held. Method 0 (keyboard): O (`$DFFE` bit 1) up, else K (`$BFFE` bit 2) down; Z (`$FEFE` bit 1) left, else X (`$FEFE` bit 2) right; ENTER (`$BFFE` bit 0) fire. Methods 1-3 from InputKempston on.

Input: none. Output: A, BC, F; HL preserved. Called by StartPressed and by Rick's update (`$F86B`).

The keyboard ran in c1, controls, gameover and ending; the Kempston in controls (and 30 times in c1); the cursor keys in c1, controls and the four level recordings; the Sinclair in c1 and controls.

Witness: L1 1332994 (beeper48, c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

[Animation: `ReadInput` at work](img/routines/ReadInput.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 58,844 calls, 15,810,079 t-states own (1.55 %) |
| Runs (the other recordings) | 1,274,149 calls (`docs/integrate/l1end` 410,192, `stage2/ending2` 232,866, `stage1/ending` 187,306 and 49 more) |
| Called from | `StartPressed`, `MoveRick` |
| Calls | `InputKempston` (tail) |
| Reads | `$A14C`-`$A14D` (`ControlMethod`, `InputBits`) |
| Writes | `$A14D` (`InputBits`) |
| Ports in | `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FEFE` |

### `InputKempston` (`$A19F`)

**InputKempston**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 53,272 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 794,037 calls (`docs/integrate/l1end` 410,192, `stage2/ending2` 232,866, `stage1/level1` 118,103 and 45 more) |
| Called from | `ReadInput` (tail) |
| Reads | `$A14D` (`InputBits`) |
| Writes | `$A14D` (`InputBits`) |
| Ports in | `$EFFE`, `$F7FE` |

## render

`src/game/render.asm`

### `MarkAllDirty` (`$A239`)

**Set every cell flag of the screen to 1 (`$6C00-$6EFF`): the next draw redraws all**

Pushes `$0101` 384 times with SP = `$6F00`, interrupts off, then restores SP and enables interrupts.

Callers: LoadScreen (`$ACF7`), the level's end (`$ABD8`) and the end of the last level (`$AC4C`). Output: B, HL changed.

Witness: L1 443 (beeper48, c1, controls, ending, ending2, gameover, l1end, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 7 calls, 37,588 t-states own (0.00 %) |
| Runs (the other recordings) | 436 calls (`stage1/level4` 30, `stage2/zones/L3Z9` 26, `stage2/zones/L3Z7` 22 and 43 more) |
| Called from | `LevelEnd`, `LoadScreen` |
| Writes | `$A259`-`$A25A` (`MarkAllDirtySP+1`) |

### `DrawDirtyCells` (`$A25D`)

**Draw the flagged cells of the screen (no attributes): the per-frame update**

Sets the sentinel `$6F00` = `$FF`, calls MaskHudCells, then scans the flags from `$6C00`. Flag 1: draws the map's char (the map byte `$600` below the flag) from the charset at CharsetBase and clears the flag. Flag n >= 2: draws composed char n (`$5CF0` + 8n) and sets the flag to 1, so the cell is restored next frame. `$FF`: return.

The screen address follows from the flag's: the low byte is the cell's, the third is (H - `$6C`).

Callers: the frame loop (`$E41F`), the game over (`$E360`) and the end of each scroll (`$ADEC`, `$AE21`). Output: AF, BC, DE, HL changed.

Witness: L1 43014 (beeper48, c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,082 calls, 30,919,392 t-states own (3.03 %) |
| Runs (the other recordings) | 41,932 calls (`stage1/level3` 2,923, `stage1/level2` 2,852, `stage1/level1` 2,151 and 49 more) |
| Called from | `ScrollViewDown`, `ScrollViewUp`, `GameOver`, `CheckGameComplete` |
| Calls | `MaskHudCells` |
| Reads | `$5D00`-`$6087` (`LoaderStage2`, `LoaderStack`, `MusicImage`); `$6600`-`$68FF` (`MusicImage+2048`); `$6C00`-`$6F00` (`Kind16Frame+92`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 1 more); `$7100`-`$73BF` (`CharSet0`); `$73D8`-`$73F7` (`CharSet0+728`); `$7440`-`$7447` (`CharSet0+832`); 19 more ranges |
| Writes | `$4000`-`$57FF` (screen); `$6C00`-`$6F00` (`Kind16Frame+92`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 1 more) |

### `ComposeObject` (`$A2EC`)

**Draw the sprite of the object at IX into composed chars of the cells it covers**

Input: IX an object record: +1 x, +2/+3 y (from the map's `$6500` row; +3 is 0, or 1 with +2 below `$EB`, else nothing is drawn), +4/+5 the frame (0: no sprite, return), +6 bit 0 mirror.

Finds the first map cell HL = `$6500` + 32 (y / 8) + x / 8, then calls ComposeCell for every cell the sprite covers, column by column: 3 columns of 3 cells (y AND 7 below 4) or of 4 cells when aligned; 4 columns when x AND 7 is not 0 (ComposeShifted). The drawers' IY = the first composed buffer + (y AND 7); the next column's buffer is 24 or 32 bytes on.

The column offsets are written into the drawers' (IY+d) operands. Output: everything but IX; interrupts on at the end. Called by ComposeObjects only.

Witness: L1 225623 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

[Animation: `ComposeObject` at work](img/routines/ComposeObject.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4,101 calls, 30,339,764 t-states own (2.97 %) |
| Runs (the other recordings) | 221,522 calls (`stage1/level4` 16,596, `stage1/level2` 13,715, `stage1/level3` 12,532 and 48 more) |
| Called from | `ComposeObjects` |
| Calls | `ComposeCell` |
| Reads | `$5B00`-`$5BFF` (`RomPagingRoutines`, `Rom128Variables`); `$5D00`-`$6087` (`LoaderStage2`, `LoaderStack`, `MusicImage`); `$EA8F`-`$EB66` (`ObjectTable+1`, `RickObject`, `RickX`, `RickY` and 9 more); `$EB7F`-`$EB84` (`ZoneObjects+121`); `$EB9D`-`$EBA2` (`ZoneObjects+151`); `$EBBB`-`$EBC0` (`ZoneObjects+181`); 1 more ranges |
| Writes | `$5D00`-`$6087` (`LoaderStage2`, `LoaderStack`, `MusicImage`); `$A442`-`$A443` (`SpriteAlignedJump+1`); `$A458`-`$A459` (`SpriteAlignedPair+1`); `$A472`-`$A487` (`SpriteAlignedCol2In+2`, `SpriteAlignedCol2Out`, `SpriteAlignedCol3In`, `SpriteAlignedCol3Out` and 1 more); `$A605`-`$A606` (`SpriteShiftedJump+1`); `$A61B`-`$A61C` (`SpriteShiftedPair+1`); 2 more ranges |

### `ComposeCell` (`$A6D0`)

**Give the map cell at HL a new composed char holding what is drawn there now**

Input: HL a map cell. Output: DE the new buffer's end (the caller steps back to its start), HL, BC, AF changed. A new buffer is ComposeCount's number n, at `$5CF0` + 8n; ComposeCount goes up by one.

If the cell's char has any of bits 3-6 set in its property byte (`$5C00` + char): a scratch buffer, the flag unchanged (ComposeHidden: the sprite is hidden there). Else the flag (HL + `$600`) becomes n and the buffer gets the char's 8 bytes: from the charset (flag 0 or 1) or from the composed char the flag names (ComposeOverSprite: two sprites in one cell).

Called 9-16 times by ComposeObject per object. The most run routine of the range (level4: 148302 runs).

Witness: L1 1823882 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 31,048 calls, 12,692,610 t-states own (1.24 %) |
| Runs (the other recordings) | 1,792,834 calls (`stage1/level4` 148,302, `stage1/level3` 97,578, `stage1/level2` 78,132 and 48 more) |
| Called from | `ComposeObject` |
| Reads | `$5C00`-`$5F9F` (`SystemVariables`, `ChannelInfo`, `BasicLeft`, `LoaderStage2` and 2 more); `$6060`-`$6147` (`MusicImage+608`); `$6240`-`$6357` (`MusicImage+1088`); `$63F0`-`$63F7` (`MusicImage+1520`); `$6428`-`$64EF` (`MusicImage+1576`); `$650E`-`$6517` (`MusicImage+1806`); 12 more ranges |
| Writes | `$5D00`-`$6087` (`LoaderStage2`, `LoaderStack`, `MusicImage`); `$6B0E`-`$6B14` (`MusicImage+3342`); `$6B2B`-`$6FFB` (`MusicImage+3371`, `Kind16Frame`, `Kind19Frame`, `LowZeros` and 2 more); `$7018`-`$701B` (`Unused7001+23`); `$7039`-`$703B` (`Unused7001+56`); `$A73C` (`ComposeCount`) |

### `ComposeObjects` (`$A73F`)

**Compose the sprites of all objects for this frame**

ComposeCount = 2, then calls ComposeObject for every record of the object table `$EA8E` (30 bytes each) whose +0 is not 0, up to the record whose +0 is `$FF`.

Callers: the frame loop (`$E414`), the game over (`$E35A`) and ClearOffscreenFlags (`$AF52`). Output: everything, IX past the table.

Witness: L1 43008 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,082 calls, 1,093,811 t-states own (0.11 %) |
| Runs (the other recordings) | 41,926 calls (`stage1/level3` 2,924, `stage1/level2` 2,853, `stage1/level1` 2,152 and 48 more) |
| Called from | `ClearOffscreenFlags`, `Quit`, `CheckGameComplete` |
| Calls | `ComposeObject` |
| Reads | `$EA8E`-`$EB42` (`ObjectTable`, `RickObject`, `RickX`, `RickY` and 9 more); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`); `$EB9C` (`ZoneObjects+150`); `$EBBA` (`ZoneObjects+180`); `$EBD8` (`ZoneObjects+210`); 1 more ranges |
| Writes | `$A73C` (`ComposeCount`) |

### `UnusedBuildMirror` (`$A75D`)

**A callable copy of BuildMirrorTable: never called**

The same code as Start's `$AB6A-$AB8C` (fill `$5B00-$5BFF` with the bit-reversed bytes) and a RET. No instruction of the game calls or jumps here and no recording ran it: known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RedrawScreen` (`$A781`)

**Draw every flagged cell with its attribute, keeping the HUD row's flags**

Saves the sentinel byte `$6F00` (into RedrawSentinel) and the 30 flags `$6C21-$6C3E` of the HUD row (into SavedHudCells, 30 LDIs each way), calls DrawAllDirtyCells, then puts both back.

Callers: LoadScreen (`$ACFA`), the level's end (`$ABE8`) and each scroll step (`$ADD8`, `$AE0F`). Output: everything.

Witness: L1 614 (beeper48, c1, controls, ending, ending2, gameover, l1end, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 35 calls, 40,111 t-states own (0.00 %) |
| Runs (the other recordings) | 579 calls (`stage1/level1` 49, `stage1/level4` 34, `stage2/zones/L3Z9` 28 and 43 more) |
| Called from | `LevelEnd`, `LoadScreen`, `ScrollViewDown`, `ScrollViewUp` |
| Calls | `DrawAllDirtyCells` |
| Reads | `$6C21`-`$6C3E` (`Kind16Frame+125`, `Kind19Frame`); `$6F00` (`CellFlagsRow24`); `$A814`-`$A831` (`SavedHudCells`) |
| Writes | `$6C21`-`$6C3E` (`Kind16Frame+125`, `Kind19Frame`); `$6F00` (`CellFlagsRow24`); `$A80F`-`$A831` (`RedrawSentinel+1`, `SavedHudCells`) |

### `DrawAllDirtyCells` (`$A834`)

**Draw the flagged cells and their attributes**

Like DrawDirtyCells, and each cell's attribute is set from the attribute table (AttrTableHigh: `$79` or `$82`) by its map char. A flag of 1 is cleared after the draw; a composed char's flag is left. The sentinel `$FF` ends the scan.

Called by RedrawScreen only. Output: everything.

Witness: L1 614 (beeper48, c1, controls, ending, ending2, gameover, l1end, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 35 calls, 9,380,803 t-states own (0.92 %) |
| Runs (the other recordings) | 579 calls (`stage1/level1` 49, `stage1/level4` 34, `stage2/zones/L3Z9` 28 and 43 more) |
| Called from | `RedrawScreen` |
| Calls | `MaskHudCells` |
| Reads | `$5D00`-`$5FEF` (`LoaderStage2`, `LoaderStack`, `MusicImage`); `$6600`-`$68FF` (`MusicImage+2048`); `$6C00`-`$6F00` (`Kind16Frame+92`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 1 more); `$7100`-`$7627` (`CharSet0`); `$7680`-`$78EF` (`CharSet0+1408`); `$7900`-`$7C57` (`CharAttr0`, `CharSet1`); 3 more ranges |
| Writes | `$4000`-`$5AFF` (screen); `$6C00`-`$6F00` (`Kind16Frame+92`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 1 more) |

### `ScrollViewDown` (`$ADB9`)

**Scroll the view down by 8 rows, in two steps of 4**

ClearOffscreenFlags, then twice: ShiftMapUp, ShiftMarksUp, ShiftObjects by -32 (y), ViewTopRow + 4, WaitFrames 4, RedrawScreen. Then BuildScreenMap, the objects of the rows coming in (`$FD7D`, D = ViewTopRow + `$20`, E = 8) and DrawDirtyCells.

Called from the game loop when Rick's y is `$CC` or more (`$E432`).

Witness: L1 71 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z6, L3Z6, L3Z8, L3Z10, L4Z3, L4Z5, level1, level3, level4, spotL1Z4-43).

[Animation: `ScrollViewDown` at work](img/routines/ScrollViewDown.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14 calls, 6,286 t-states own (0.00 %) |
| Runs (the other recordings) | 57 calls (`stage1/level1` 15, `stage2/zones/L1Z6` 8, `stage1/gameover` 6 and 14 more) |
| Called from | `CheckGameComplete` |
| Calls | `WaitFrames`, `DrawDirtyCells`, `RedrawScreen`, `BuildScreenMap`, `ShiftMapUp`, `ShiftMarksUp`, `ShiftObjects`, `ClearOffscreenFlags`, `SpawnObjects` |
| Reads | `$ADB7` (`ViewTopRow`) |
| Writes | `$ADB7` (`ViewTopRow`) |

### `ScrollViewUp` (`$ADF0`)

**Scroll the view up by 8 rows, in two steps of 4**

The mirror of ScrollViewDown: ShiftMapDown, ShiftMarksDown, ShiftObjects by +32, ViewTopRow - 4; the objects of the top rows (`$FD7D`, D = ViewTopRow, E = 8). Called when Rick's y is below `$60` (`$E43B`). Scrolled up in L1Z4, L2Z2, L3Z8 and L3Z9 and in level2 (11 of the 16).

Witness: L1 16 (L1Z4, L2Z2, L3Z8, L3Z9, level2).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 16 calls (`stage1/level2` 11, `stage2/zones/L3Z8` 2, `stage2/zones/L1Z4` 1 and 2 more) |
| Called from | `CheckGameComplete` |
| Calls | `WaitFrames`, `DrawDirtyCells`, `RedrawScreen`, `BuildScreenMap`, `ShiftMapDown`, `ShiftMarksDown`, `ShiftObjects`, `ClearOffscreenFlags`, `SpawnObjects` |
| Reads | `$ADB7` (`ViewTopRow`) |
| Writes | `$ADB7` (`ViewTopRow`) |

### `ShiftMapUp` (`$AE25`)

**Move the map up 4 rows (`$6680` -> `$6600` ...), flagging every changed cell**

`$6A00` and `$6A80` hold `$FF` as the end. A cell that changes takes the char 4 rows below and, if its flag is 0 or 1, the flag 1.

Witness: L1 141 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z6, L3Z6, L3Z8, L3Z10, L4Z3, L4Z5, level1, level3, level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 28 calls, 2,047,720 t-states own (0.20 %) |
| Runs (the other recordings) | 113 calls (`stage1/level1` 30, `stage2/zones/L1Z6` 16, `stage1/gameover` 12 and 14 more) |
| Called from | `ScrollViewDown` |
| Reads | `$6600`-`$6A00` (`MusicImage+2048`); `$6C00`-`$6F7F` (`Kind16Frame+92`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 1 more) |
| Writes | `$6600`-`$697F` (`MusicImage+2048`); `$6A00` (`MusicImage+3072`); `$6A80` (`MusicImage+3200`); `$6C00`-`$6F7F` (`Kind16Frame+92`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 1 more) |

### `ShiftMapDown` (`$AE4D`)

**Move the map down 4 rows, from the bottom, flagging every changed cell**

The end markers at `$647F` and `$64FF`. Called by ScrollViewUp.

Witness: L1 32 (L1Z4, L2Z2, L3Z8, L3Z9, level2).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 32 calls (`stage1/level2` 22, `stage2/zones/L3Z8` 4, `stage2/zones/L3Z9` 2 and 2 more) |
| Called from | `ScrollViewUp` |
| Reads | `$64FF`-`$68FF` (`MusicImage+1791`); `$6B80`-`$6EFE` (`MusicImage+3456`, `Kind16Frame`, `Kind19Frame`, `LowZeros` and 1 more) |
| Writes | `$647F` (`MusicImage+1663`); `$64FF` (`MusicImage+1791`); `$6580`-`$68FE` (`MusicImage+1920`); `$6B80`-`$6EFE` (`MusicImage+3456`, `Kind16Frame`, `Kind19Frame`, `LowZeros` and 1 more) |

### `ShiftMarksUp` (`$AE76`)

**Move the composed-char flags (2 and up) 4 rows up, leaving a 1 behind**

The end `$FF` at `$7000`. Called by ScrollViewDown.

Witness: L1 141 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z6, L3Z6, L3Z8, L3Z10, L4Z3, L4Z5, level1, level3, level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 28 calls, 1,009,192 t-states own (0.10 %) |
| Runs (the other recordings) | 113 calls (`stage1/level1` 30, `stage2/zones/L1Z6` 16, `stage1/gameover` 12 and 14 more) |
| Called from | `ScrollViewDown` |
| Reads | `$6C01`-`$7000` (`Kind16Frame+93`, `Kind19Frame`, `LowZeros`, `CellFlagsRow16` and 2 more) |
| Writes | `$6B8E`-`$6EFB` (`MusicImage+3470`, `Kind16Frame`, `Kind19Frame`, `LowZeros` and 1 more); `$6F21`-`$6F7B` (`CellFlagsRow24+33`); `$6FA1`-`$7000` (`CellFlagsRow24+161`, `CellFlagsEnd`) |

### `ShiftMarksDown` (`$AE9A`)

**Move the composed-char flags 4 rows down, leaving a 1 behind**

The end `$FF` at `$6AFF`, scanning down from `$6EFF`. Called by ScrollViewUp.

Witness: L1 32 (L1Z4, L2Z2, L3Z8, L3Z9, level2).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 32 calls (`stage1/level2` 22, `stage2/zones/L3Z8` 4, `stage2/zones/L3Z9` 2 and 2 more) |
| Called from | `ScrollViewUp` |
| Reads | `$6AFF`-`$6EFF` (`MusicImage+3327`, `Kind16Frame`, `Kind19Frame`, `LowZeros` and 1 more) |
| Writes | `$6AFF` (`MusicImage+3327`); `$6B2B`-`$6B7B` (`MusicImage+3371`); `$6BA5`-`$6BFB` (`Kind16Frame+1`); `$6C25`-`$6E1A` (`Kind19Frame+3`, `LowZeros`, `CellFlagsRow16`); `$6E2D`-`$6E32` (`CellFlagsRow16+45`); `$6E4D`-`$6E9A` (`CellFlagsRow16+77`); 5 more ranges |

### `ClearOffscreenFlags` (`$AF18`)

**Clear the flags of the map rows above and below the view, then compose the objects**

Clears `$6B00-$6BFF` and `$6F00-$6FFF` with PUSHes (interrupts off), then ComposeObjects. Called at the start of both scrolls.

Witness: L1 87 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z2, L2Z6, L3Z6, L3Z8-L3Z10, L4Z3, L4Z5, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14 calls, 52,434 t-states own (0.01 %) |
| Runs (the other recordings) | 73 calls (`stage1/level1` 15, `stage1/level2` 11, `stage2/zones/L1Z6` 8 and 17 more) |
| Called from | `ScrollViewDown`, `ScrollViewUp` |
| Calls | `ComposeObjects` |
| Writes | `$AF4F`-`$AF50` (`ClearFlagsSP+1`) |

## hud

`src/game/hud.asm`

### `MaskHudCells` (`$A8BF`)

**Clear the cell flags under the score and the counters' icons**

Clears the six flags `$6C21-$6C26` (the score), then as many flags as each counter has icons (at most 6): `$6C29` bullets, `$6C31` dynamite, `$6C39` lives.

When Bullets is 0 the JP Z at `$A8CF` lands in the clearing loop with HL = 0 and B as the caller left it: it writes zeros at `$0000-$00FF` (the ROM: ignored) B times. Harmless; with Dynamite or Lives 0 the code skips properly. Seen in emptygun: from the sixth shot (frame 420) 139 of the 350 runs take that jump (MaskBullets runs 211 times).

Callers: DrawDirtyCells and DrawAllDirtyCells. Output: AF, B, HL changed.

Witness: L1 43628 (beeper48, c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,117 calls, 697,693 t-states own (0.07 %) |
| Runs (the other recordings) | 42,511 calls (`stage1/level3` 2,934, `stage1/level2` 2,879, `stage1/level1` 2,200 and 49 more) |
| Called from | `DrawDirtyCells`, `DrawAllDirtyCells` |
| Reads | `$A958`-`$A976` (`Lives`, `DrawDynamite`, `Dynamite`, `DrawBullets` and 1 more) |
| Writes | `$6C21`-`$6C3E` (`Kind16Frame+125`, `Kind19Frame`) |

### `UpdateHud` (`$A90F`)

**Redraw the counters that changed since the last call**

Compares Bullets, Dynamite and Lives with OldHudCounts and calls DrawBullets, DrawDynamite or DrawLives for each one that differs (keeping the new value).

Callers: the frame loop (`$E422`), the game over (`$E35D`) and the level's end (`$ABF3`). Output: everything.

Witness: L1 42932 (beeper48, c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

[Animation: `UpdateHud` at work](img/routines/UpdateHud.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,068 calls, 169,912 t-states own (0.02 %) |
| Runs (the other recordings) | 41,864 calls (`stage1/level3` 2,921, `stage1/level2` 2,841, `stage1/level1` 2,136 and 49 more) |
| Called from | `LevelEnd`, `GameOver`, `CheckGameComplete` |
| Calls | `DrawLives` (tail), `DrawDynamite`, `DrawBullets` |
| Reads | `$A93A`-`$A93C` (`OldHudCounts`, `OldDynamite`, `OldLives`); `$A958`-`$A976` (`Lives`, `DrawDynamite`, `Dynamite`, `DrawBullets` and 1 more) |
| Writes | `$A93A`-`$A93C` (`OldHudCounts`, `OldDynamite`, `OldLives`) |

### `DrawHud` (`$A93D`)

**Draw the score and the three counters**

Calls DrawScore, DrawBullets, DrawDynamite and DrawLives. Callers: the game start (`$E30E`) and a life lost (`$E3C6`).

Witness: L1 331 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4 calls, 312 t-states own (0.00 %) |
| Runs (the other recordings) | 327 calls (`stage1/level4` 29, `stage2/zones/L3Z9` 24, `stage2/zones/L3Z7` 16 and 40 more) |
| Called from | `NewGame`, `NewLife` |
| Calls | `DrawLives`, `DrawDynamite`, `DrawBullets`, `DrawScore` |

### `DrawLives` (`$A94A`)

**Draw the lives as icons at `$4039`**

DE = `$4039`, the icon `$26`, attribute `$47`, A = Lives, then DrawCounter. Output: everything.

Witness: L1 370 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 7 calls, 448 t-states own (0.00 %) |
| Runs (the other recordings) | 363 calls (`stage1/level4` 30, `stage1/level1` 27, `stage2/zones/L3Z9` 24 and 40 more) |
| Called from | `UpdateHud` (tail), `DrawHud` |
| Calls | `DrawCounter` |
| Reads | `$A958` (`Lives`) |

### `DrawDynamite` (`$A959`)

**Draw the sticks of dynamite as icons at `$4031`**

DE = `$4031`, the icon `$25` (glyph 37, a stick), attribute `$47`, A = Dynamite, then DrawCounter.

Witness: L1 393 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5 calls, 320 t-states own (0.00 %) |
| Runs (the other recordings) | 388 calls (`stage1/level4` 30, `stage2/zones/L3Z9` 24, `stage2/zones/L4Z2` 18 and 40 more) |
| Called from | `UpdateHud`, `DrawHud` |
| Calls | `DrawCounter` |
| Reads | `$A967` (`Dynamite`) |

### `DrawBullets` (`$A968`)

**Draw the bullets as icons at `$4029`**

DE = `$4029`, the icon `$24` (glyph 36, a bullet), attribute `$47`, A = Bullets, then DrawCounter.

Witness: L1 413 (beeper48, c1, controls, emptygun, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 10 calls, 640 t-states own (0.00 %) |
| Runs (the other recordings) | 403 calls (`stage1/level4` 34, `stage1/level1` 24, `stage2/zones/L3Z9` 24 and 41 more) |
| Called from | `UpdateHud`, `DrawHud` |
| Calls | `DrawCounter` |
| Reads | `$A976` (`Bullets`) |

### `DrawScore` (`$A977`)

**Draw the six score digits at `$4021` and colour them `$47`**

For each digit of Score: its 8 bytes from the font at `$9E95` + 8 digit, one pixel line per screen line. Then the attributes `$5821-$5826` = `$47`.

Callers: DrawHud and AddScore (a tail jump). Output: everything.

Witness: L1 370 (beeper48, c1, controls, ending, ending2, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14 calls, 33,017 t-states own (0.00 %) |
| Runs (the other recordings) | 354 calls (`stage1/level4` 31, `stage1/level1` 24, `stage2/zones/L3Z9` 24 and 40 more) |
| Called from | `DrawHud`, `AddScore` (tail) |
| Reads | `$9E95`-`$9EE4` (`Font`); `$A9BE`-`$A9C3` (`Score`) |
| Writes | `$4021`-`$4026` (screen); `$4121`-`$4126` (screen); `$4221`-`$4226` (screen); `$4321`-`$4326` (screen); `$4421`-`$4426` (screen); `$4521`-`$4526` (screen); 3 more ranges |

### `AddScore` (`$A9E8`)

**Add a five-digit award to the score and redraw it**

Input: DE the last (units) digit of the award. Adds the five digits to Score's last five (`$A9BF-$A9C3`) from the units up, carrying past 9, then the carry into the first digit (9 wraps to 0). Tail jump to DrawScore.

Callers: `$EDF6` (500), `$F190` (50), `$F52C` (the award at `$E49A`) and the end of the last level (`$AC35`). Output: everything.

Witness: L1 39 (c1, ending, ending2, L1Z3, L2Z6, L3Z2, L3Z6, L3Z11, L3Z12, L4Z2, level1, level2, level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 10 calls, 4,075 t-states own (0.00 %) |
| Runs (the other recordings) | 29 calls (`stage1/level1` 10, `stage1/level2` 5, `stage2/zones/L3Z6` 3 and 9 more) |
| Called from | `LevelEnd`, `TreasureObj`, `KillEnemy`, `BonusCollect` |
| Calls | `DrawScore` (tail) |
| Reads | `$9E95`-`$9E9C` (`Font`); `$9ECD`-`$9ED4` (`Font+56`); `$A9BE`-`$A9E7` (`Score`, `ScorePad`, `Award1`, `Award10` and 5 more); `$E496`-`$E49A` (`BonusDigits`) |
| Writes | `$4021`-`$4026` (screen); `$4121`-`$4126` (screen); `$4221`-`$4226` (screen); `$4321`-`$4326` (screen); `$4421`-`$4426` (screen); `$4521`-`$4526` (screen); 4 more ranges |

### `DrawCounter` (`$AA0E`)

**Draw a counter as up to six icons and give the rest of its six cells back to the map**

Input: A the count (above 6 shown as 6), DE the screen address, L the icon char, H its attribute. Draws the icon A times with its attribute (CounterAttr).

For the remaining 6 - A cells it sets the cell flag to 1 (`$6C00` + cell) and the attribute from the map's char (`$6600` + cell, the table `$7900` or `$8200`: CounterAttrTableHigh), so the next draw puts the map back there.

The LD A,(`$6B00`) / AND A at `$AA76` has no effect (A is reloaded, the flags are not tested). Callers: DrawLives, DrawDynamite, DrawBullets.

Witness: L1 1176 (beeper48, c1, controls, emptygun, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 22 calls, 47,596 t-states own (0.00 %) |
| Runs (the other recordings) | 1,154 calls (`stage1/level4` 94, `stage2/zones/L3Z9` 72, `stage1/level1` 66 and 41 more) |
| Called from | `DrawLives`, `DrawDynamite`, `DrawBullets` |
| Reads | `$6629`-`$663E` (`MusicImage+2089`); `$6B00` (`MusicImage+3328`); `$7900` (`CharAttr0`); `$792B`-`$7940` (`CharAttr0+43`); `$7952` (`CharAttr0+82`); `$79DB`-`$79F1` (`CharAttr0+219`); 4 more ranges |
| Writes | `$4029`-`$403E` (screen); `$4129`-`$413E` (screen); `$4229`-`$423E` (screen); `$4329`-`$433E` (screen); `$4429`-`$443E` (screen); `$4529`-`$453E` (screen); 5 more ranges |

### `PrintText` (`$AA8D`)

**Print a text from HL at the screen address DE in attribute C**

One char a cell, `$FF` ends. A space (`$20`) prints SpaceGlyph; any other byte b prints the font char b - `$37` from `$9E95`: 'A'-'Z' are the letters 10-35, and the digits 0-9 would be the bytes `$37-$40` ('7'-'@').

Output: HL on the `$FF`, DE past the text, AF changed. Callers: PrintLines and the game over text (`$E36B-$E381`).

Witness: L1 4941 (beeper48, c1, controls, ending, ending2, gameover, l1end, level1).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 30 calls, 197,108 t-states own (0.02 %) |
| Runs (the other recordings) | 276 calls (`stage1/controls` 120, `stage1/level1` 44, `stage1/gameover` 30 and 4 more) |
| Called from | `PrintLines`, `GameOver` |
| Reads | `$9E9D`-`$9EBC` (`Font+8`); `$9ED5`-`$9FB4` (`Font+64`, `FontLetters`); `$9FCD`-`$9FE4` (`FontPunctuation`); `$AAE1`-`$AAE8` (`SpaceGlyph`); `$E397`-`$E3AE` (`GameOverBlankText`, `GameOverText`); `$E4E5`-`$E708` (`SouthAmericaText`, `EgyptText`); 1 more ranges |
| Writes | `$4041`-`$405E` (screen); `$40A1`-`$40B5` (screen); `$40E1`-`$40FB` (screen); `$4141`-`$415E` (screen); `$41A1`-`$41B5` (screen); `$41E1`-`$41FB` (screen); 36 more ranges |

### `PrintLines` (`$AAE9`)

**Print texts on successive screen rows until `$FE`**

Input: HL the texts, each ending in `$FF`, the list ending in `$FE`; DE the first row's screen address. Each text in attribute `$47`; DE goes 32 on (8 more on D when E wraps: the next third).

Callers: the title (`$E22F-$E241`), the level texts (`$E31A`, `$AC1A`). Output: everything.

Witness: L1 315 (beeper48, c1, controls, ending, ending2, gameover, l1end, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4 calls, 2,980 t-states own (0.00 %) |
| Runs (the other recordings) | 35 calls (`stage1/controls` 16, `stage1/level1` 5, `stage1/gameover` 4 and 4 more) |
| Called from | `LevelEnd`, `Menu`, `NewGame` |
| Calls | `PrintText` |
| Reads | `$E4E5`-`$E4FD` (`SouthAmericaText`); `$E51C`-`$E539` (`SouthAmericaText+55`); `$E557`-`$E56B` (`SouthAmericaText+114`); `$E588` (`SouthAmericaText+163`); `$E5A7`-`$E5C2` (`SouthAmericaText+194`); `$E5E0`-`$E616` (`SouthAmericaText+251`, `EgyptText`); 15 more ranges |

### `ClearScreen` (`$AB03`)

**Clear the bitmap and set every attribute to `$47`**

Callers: the title (`$E223`) and the game start (`$E2DC`). Output: BC, DE, HL.

Witness: L1 18 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 2 calls, 368,684 t-states own (0.04 %) |
| Runs (the other recordings) | 16 calls (`stage1/controls` 8, `stage1/level1` 3, `stage1/gameover` 2 and 3 more) |
| Called from | `Menu`, `NewGame` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `CycleAttributes` (`$AB18`)

**Colour A attribute cells from DE with a table of 8, the phase moving on one each call**

Input: A the number of cells, HL the table (written into CycleTablePtr), DE the first attribute. CyclePhase counts up modulo 8; cell i gets table[(phase + i) AND 7]. The title highlights the chosen method's line with CycleColours and repaints the old one with PlainColours (`$E269-$E2CE`), once every two frames (two HALTs).

Output: AF, BC, DE, HL changed, AF' used.

Witness: L1 6749 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,728 calls, 4,120,896 t-states own (0.40 %) |
| Runs (the other recordings) | 1,021 calls (`stage1/controls` 271, `stage1/level1` 249, `stage1/gameover` 157 and 3 more) |
| Called from | `Menu` |
| Reads | `$AB3C`-`$AB4C` (`CyclePhase`, `CycleColours`, `PlainColours`) |
| Writes | `$58EE`-`$58F5` (screen); `$592E`-`$5935` (screen); `$596E`-`$5973` (screen); `$59AE`-`$59B5` (screen); `$AB2B`-`$AB3C` (`CycleTablePtr+1`, `CyclePhase`) |

### `LevelEnd` (`$ABD8`)

**The end of a level: the next level's text and first screen, or after the fourth the bonus and the end**

Falls in from CheckScreenExit when the exit points at `$FFFF`. MarkAllDirty, clears the map's screen rows `$6600-$68FF`, RedrawScreen, Bullets = Dynamite = 6, UpdateHud, LevelNumber `$E4AD` + 1 = n.

The level record at `$E4AE` + 11n (+0/+1 the text list, +2/+3 its screen address, +4 the attribute of char 0 at `$7900`): PrintLines, then StartTune n. After the fourth level (n = 4) the bonus: LevelBonus = Lives + 1, AddScore. Then waits for the start key's release and press (StartPressed).

n >= 4: ClearPlayArea, MarkAllDirty, `$E440` = `$FF` (the game loop's "over" flag: on to the game over at `$E35D`) and return. Else NextLevel.

Run once in ending2 (level 4's end exit from the L4Z9 warp, the door opened by the warp) and once in l1end (level 1's end: the L1Z6 warp with the right exit's flags set, tune 1); the ends of levels 2 and 3 are in no recording. Output: everything.

Witness: L1 2 (ending2, l1end).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 2 runs of its first instruction, entered by a jump (`docs/integrate/l1end` 1, `stage2/ending2` 1) |
| Calls | `StartTune`, `StartPressed`, `MarkAllDirty`, `RedrawScreen`, `UpdateHud`, `AddScore`, `PrintLines`, `ClearPlayArea` |

### `ClearPlayArea` (`$AF56`)

**Clear the map's screen rows `$6600-$68FF` (the char 0)**

Called once, after the last level (`$AC49`), before the game over.

Witness: L1 2 (ending, ending2).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 2 calls (`stage1/ending` 1, `stage2/ending2` 1) |
| Called from | `LevelEnd` |
| Reads | `$6600`-`$68FE` (`MusicImage+2048`) |
| Writes | `$6600`-`$68FF` (`MusicImage+2048`) |

### `BonusCountdown` (`$E466`)

**Count the bonus down while it runs**

Returns at once when `$FD6C` is 0. Else BonusDivider `$E495` counts passes; every `$1E` passes (the reload) it takes 1 from BonusDigits+3 with a decimal borrow (a digit going below 0 becomes 9 and borrows from the one before); at 0 0 0 0 0 it stops.

Run in c1, controls, gameover, level1 and level2; never in level3 / level4. Known only from the code: the digits are not drawn here.

Witness: L1 43339 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,072 calls, 40,840 t-states own (0.00 %) |
| Runs (the other recordings) | 42,267 calls (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Called from | `MainLoop` |
| Reads | `$E495`-`$E499` (`BonusDivider`, `BonusDigits`); `$FD6C` (`BonusActive`) |
| Writes | `$E495`-`$E499` (`BonusDivider`, `BonusDigits`) |

## levels

`src/game/levels.asm`

### `CheckScreenExit` (`$AB93`)

**Find the exit Rick takes and go to its screen (or end the level)**

C = Rick's map row (y `$EAAE` / 8 + ViewTopRow), B = the exit kind `$FD62`. Scans the exit table (the operand `$AB95` of its first instruction, LD IX, written by LoadScreen `$ACC3`: 5-byte entries) for one of kind B whose row is at most 2 above C; none: return. Found: the next screen record +2/+3; `$FFFF` falls into LevelEnd, else ExitToScreen with BC = ViewTopRow - (row - entry +4).

Called from the game loop (`$E403`). Output: everything.

Witness: L1 107 (c1, ending2, l1end, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z2-L4Z6, L4Z8, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3 calls, 279 t-states own (0.00 %) |
| Runs (the other recordings) | 104 calls (`stage2/zones/L2Z5` 8, `stage2/zones/L2Z2` 7, `stage2/zones/L4Z8` 6 and 27 more) |
| Called from | `MainLoop` |
| Calls | `ExitScan` (falls into) |
| Reads | `$6600`-`$68FE` (`MusicImage+2048`); `$A958` (`Lives`); `$ADB7` (`ViewTopRow`); `$D681`-`$D68B` (`Exits+55`); `$D6AD`-`$D6BC` (`Level2Exits+33`); `$D7A4`-`$D7BE` (`Level4Exits+11`); 5 more ranges |
| Writes | `$6600`-`$68FF` (`MusicImage+2048`); `$7900` (`CharAttr0`); `$A967`-`$A976` (`Dynamite`, `DrawBullets`, `Bullets`); `$A9E3` (`LevelBonus`); `$E440` (`GameComplete`); `$E4AD` (`Level`) |

### `ExitScan` (`$ABAA`)

**ExitScan**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5 calls, 672 t-states own (0.00 %) |
| Runs (the other recordings) | 145 calls (`stage2/zones/L3Z10` 15, `stage2/zones/L3Z7` 12, `stage2/zones/L2Z2` 11 and 21 more) |
| Called from | `CheckScreenExit` (falls into), `ExitNoMatch` (tail) |
| Calls | `ExitToScreen` (tail), `ExitNoMatch` (tail) |
| Reads | `$ADB7` (`ViewTopRow`); `$D64A`-`$D7D9` (`Exits`, `Level2Exits`, `Level3Exits`, `Level4Exits`) |

### `ExitToScreen` (`$AC72`)

**The tail of CheckScreenExit: IX = the next screen record, then LoadScreen**

Entered by jumps from CheckScreenExit only.

Witness: L1 104 (c1, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z2-L4Z6, L4Z8, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3 calls, 105 t-states own (0.00 %) |
| Runs (the other recordings) | 101 calls (`stage2/zones/L2Z5` 8, `stage2/zones/L2Z2` 7, `stage2/zones/L2Z7` 6 and 25 more) |
| Called from | `ExitScan` (tail) |
| Calls | `LoadScreen` (tail) |

### `ExitNoMatch` (`$AC78`)

**ExitNoMatch**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 2 calls, 94 t-states own (0.00 %) |
| Runs (the other recordings) | 53 calls (`stage2/zones/L3Z10` 9, `stage2/zones/L3Z8` 4, `stage2/zones/L2Z2` 4 and 20 more) |
| Called from | `ExitScan` (tail) |
| Calls | `ExitScan` (tail) |

### `LoadScreen` (`$AC83`)

**Install the screen record IX with the view's top row BC**

Saves IX in RestartScreenRecord, clears `$FD61`, chooses the charset by +0 (CharsetBase `$7100` and the attribute table `$79`, DE = `$F6C0`; or `$7A00`, `$82`, `$F6D0`), stores +1/+2 in MapBlockTable, BC in ViewTopRow, +3/+4 in CheckScreenExit's operand `$AB95`, +5/+6 at `$FD7E`.

Calls `$F6A9` (with DE), BuildScreenMap, `$EBF7`, then `$FD7D` three times (D = ViewTopRow + 8, E = `$18`; D = ViewTopRow, E = 8; D = ViewTopRow + `$20`, E = 8), MarkAllDirty, RedrawScreen and SaveRestartPoint.

Callers: the game start (`$E351`), ExitToScreen, NextLevel and RestartScreen. The other charset ran in level3 and level4 only. Output: everything.

Witness: L1 439 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

[Animation: `LoadScreen` at work](img/routines/LoadScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 7 calls, 4,023 t-states own (0.00 %) |
| Runs (the other recordings) | 432 calls (`stage1/level4` 30, `stage2/zones/L3Z9` 26, `stage2/zones/L3Z7` 22 and 40 more) |
| Called from | `ExitToScreen` (tail), `RestartScreen` (tail), `StartLevel` |
| Calls | `MarkAllDirty`, `RedrawScreen`, `SaveRestartPoint`, `BuildScreenMap`, `ResetObjects`, `BuildCharProps`, `SpawnObjects` |
| Reads | `$ADB7` (`ViewTopRow`); `$D55C`-`$D649` (`Zones`, `Level2Zones`, `Level3Zones`, `Level4Zones`) |
| Writes | `$A73D`-`$A73E` (`CharsetBase`); `$A853` (`DrawAllScan+19`); `$AA80` (`CounterAttrTableHigh+1`); `$AB95`-`$AB96` (`CheckScreenExit+2`); `$AD27`-`$AD28` (`RestartScreenRecord`); `$ADB5`-`$ADB8` (`MapBlockTable`, `ViewTopRow`); 2 more ranges |

### `SaveRestartPoint` (`$AD01`)

**Keep the screen's entry state in RestartPoint**

Copies `$FD5A`, Rick's x (`$EAAD`), y (`$EAAE`), byte +6 (`$EAB2`) and ViewTopRow to RestartPoint (LoadScreen has stored the screen record there).

Witness: L1 438 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 7 calls, 1,064 t-states own (0.00 %) |
| Runs (the other recordings) | 431 calls (`stage1/level4` 30, `stage2/zones/L3Z9` 26, `stage2/zones/L3Z7` 22 and 40 more) |
| Called from | `LoadScreen` |
| Reads | `$ADB7`-`$ADB8` (`ViewTopRow`); `$EAAD`-`$EAB2` (`RickX`, `RickY`, `RickMirror`); `$FD5A` (`Crawling`) |
| Writes | `$AD20`-`$AD26` (`RestartPoint`, `RestartX`, `RestartY`, `RestartFlags` and 1 more) |

### `RestartScreen` (`$AD29`)

**After a life lost: clear the 25 bytes `$FD54-$FD6C`, restore RestartPoint and load the screen again**

Restores `$FD5A`, Rick's x, y and +6, clears `$ECF1`, then jumps to LoadScreen with IX and BC from RestartPoint. Called from the game loop (`$E3C3`).

Witness: L1 323 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

[Animation: `RestartScreen` at work](img/routines/RestartScreen.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3 calls, 2,529 t-states own (0.00 %) |
| Runs (the other recordings) | 320 calls (`stage1/level4` 29, `stage2/zones/L3Z9` 24, `stage2/zones/L3Z7` 16 and 40 more) |
| Called from | `NewLife` |
| Calls | `LoadScreen` (tail) |
| Reads | `$AD20`-`$AD28` (`RestartPoint`, `RestartX`, `RestartY`, `RestartFlags` and 2 more) |
| Writes | `$EAAD`-`$EAB2` (`RickX`, `RickY`, `RickMirror`); `$ECF1` (`BlastOn`); `$FD54`-`$FD6C` (`RickVars`, `YFraction`, `YVelocity`, `Facing` and 17 more) |

### `BuildScreenMap` (`$AD5A`)

**Expand the map's blocks into the char map `$6500-$6A7F`**

Source: MapBlockTable + 2 (ViewTopRow AND `$FC`), one byte a block. For 11 rows of 8 blocks: block b's 16 chars (`$C31C` + 16b, read in RAM 0) go to a 4x4 square of the map. Interrupts off while it runs; SP saved and restored though it never changes.

Callers: LoadScreen and the end of both scrolls. Output: everything (the alternate registers too).

Witness: L1 525 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

[Animation: `BuildScreenMap` at work](img/routines/BuildScreenMap.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 21 calls, 1,184,936 t-states own (0.12 %) |
| Runs (the other recordings) | 504 calls (`stage1/level1` 34, `stage1/level4` 32, `stage2/zones/L3Z9` 27 and 40 more) |
| Called from | `LoadScreen`, `ScrollViewDown`, `ScrollViewUp` |
| Reads | `$ADB5`-`$ADB7` (`MapBlockTable`, `ViewTopRow`); `$AF74`-`$B1E3` (`LevelMaps+16`, `Level1Map2`, `Level1Map3`, `Level1Map4`); `$B214`-`$B323` (`Level1Map5+16`, `Level1Map6`); `$B334`-`$B48B` (`Level2Map+16`, `Level2Map2`); `$B4B4`-`$B583` (`Level2Map2+144`, `Level2Map3`, `Level2Map4`); `$B5A4`-`$B6B3` (`Level2Map4+64`, `Level2Map5`, `Level2Map6`); 14 more ranges |
| Writes | `$6500`-`$6A7F` (`MusicImage+1792`); `$ADA1`-`$ADB2` (`BuildMapSource+1`, `BuildMapSP`) |

### `StartLevel` (`$E32C`)

**Start the first level: wait for fire, place Rick, set up the first zone**

Waits for fire (`$A123` Z), then puts Rick at LevelTable's x and y (RickX `$EAAD`, RickY `$EAAE`), his size `$18` x `$15` (RickWidth `$EAB3`, RickHeight `$EAB4`), and sets up the zone with IX = the zone record and C = its count (`$AC83`).

With lives left (always, at a new game) it goes on to NewLife `$E3AF`; with none it falls into Quit `$E35A`.

Witness: L1 134127 (beeper48, c1, controls, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4,630 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 129,497 runs of its first instruction, entered by a jump (`stage1/controls` 52,491, `stage1/level1` 38,772, `stage2/beeper48` 23,388 and 4 more) |
| Calls | `StartPressed`, `LoadScreen` |
| Reads | `$A958` (`Lives`); `$E410` (`MainLoopHalt+1`); `$E4B3`-`$E4B8` (`LevelRickX`, `LevelRickY`, `LevelZone`, `LevelViewTop`); `$EAAE`-`$EAAF` (`RickY`); `$FD61`-`$FD69` (`ZoneChange`, `ExitSide`, `Poking`, `PokeX` and 4 more) |
| Writes | `$A237` (`FrameTicks`); `$A958`-`$A976` (`Lives`, `DrawDynamite`, `Dynamite`, `DrawBullets` and 1 more); `$EAAC`-`$EAB4` (`RickObject`, `RickX`, `RickY`, `RickMirror` and 2 more); `$FD68`-`$FD69` (`Dying`, `DeathDone`) |

### `SpawnObjects` (`$FD7D`)

**Start the objects of the spawn list in rows D to D + E - 1**

Inputs: the list at the operand `$FD7E` (set at `$ACCC` from the zone record), D = the first row, E = the count

(the zone setup calls it three times: rows top + 8 for 24, top for 8, top + `$20` for 8; also `$ADE9`, `$AE1E`).

A record: +0 row AND `$F8` (the low 3 bits are +3's), +1 kind (bit 7: none), +2 flags (bit 1: object 0, the solid

block `$EA8E`, if free; bit 2: active, bit 7 of +0), +3 X AND `$F8` and the row's low bits, +4 the trigger box's X

and row bits.

A kind below `$10` goes to one of the 3 slots from `$EB9C` (FindSlotLowKind `$FEB2`, not when a slot already holds

this record), else one of the 5 slots from `$EB06` (FindSlotHighKind `$FEA1`). The object: kind, X (+1, +F), Y =

(row - the zone top `$ADB7`) x 8 (+3 unless object 0; +2/+3, +10/+11), mirror 0, width, height, frames from the

kind's record at `$D31C` (8 bytes), the record pointer +9/+A and flags +B, the trigger box +C/+D/+E, +1D, and +18

to +1C cleared.

Outputs: none. Uses all registers, IX, IY.

Evidence: active spawns (`$FE54`) in level2-level4; object 0 spawned (`$FDB6`) in level2 and level3.

Witness: L1 1403 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

[Animation: `SpawnObjects` at work](img/routines/SpawnObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 35 calls, 59,450 t-states own (0.01 %) |
| Runs (the other recordings) | 1,368 calls (`stage1/level4` 92, `stage2/zones/L3Z9` 79, `stage1/level1` 72 and 40 more) |
| Called from | `LoadScreen`, `ScrollViewDown`, `ScrollViewUp` |
| Calls | `FindSlotHighKind`, `FindSlotLowKind` |
| Reads | `$ADB7` (`ViewTopRow`); `$D33C`-`$D429` (`ObjectKinds+32`); `$D43C`-`$D551` (`ObjectKinds+288`); `$D7FC`-`$D8B0` (`Objects`); `$D8D3`-`$DAAE` (`Objects+215`, `Level2Objects`); `$DAE5`-`$DEB4` (`Level3Objects`, `Level4Objects`); 6 more ranges |
| Writes | `$EA8E`-`$EAAB` (`ObjectTable`); `$EB06`-`$EBF5` (`ZoneObjects`) |

### `FindSlotHighKind` (`$FEA1`)

**HL = a free slot of the 5 at `$EB06`**

Outputs: Z and HL = the slot (+0 = 0); NZ (A = 1) when all 5 are in use. Uses B, DE.

Witness: L1 1386 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 21 calls, 1,549 t-states own (0.00 %) |
| Runs (the other recordings) | 1,365 calls (`stage1/level4` 150, `stage2/zones/L3Z9` 129, `stage2/zones/L2Z7` 73 and 40 more) |
| Called from | `SpawnObjects` |
| Reads | `$EB06` (`ZoneObjects`); `$EB24` (`ZoneObjects+30`); `$EB42` (`ZoneObjects+60`); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`) |

### `FindSlotLowKind` (`$FEB2`)

**HL = a free slot of the 3 at `$EB9C`, unless one holds this spawn record**

Input: IX = the spawn record. A slot in use whose +9/+A is IX: NZ (it is spawned already). Else Z and HL = the

first free slot, NZ when none.

Outputs: Z/NZ, HL. Uses B, DE, IY.

Witness: L1 734 (c1, spotL3Z7-51, L1Z2-L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 13 calls, 4,336 t-states own (0.00 %) |
| Runs (the other recordings) | 721 calls (`stage1/level4` 90, `stage2/zones/L3Z3` 66, `stage2/zones/L2Z5` 45 and 34 more) |
| Called from | `SpawnObjects` |
| Reads | `$EB9C`-`$EBA5` (`ZoneObjects+150`); `$EBBA`-`$EBC3` (`ZoneObjects+180`); `$EBD8`-`$EBE1` (`ZoneObjects+210`) |

## objects

`src/game/objects.asm`

### `ShiftObjects` (`$AEBE`)

**Move every object by BC in y and drop those that leave the map**

Input: BC = -32 or +32. Adds BC to +`$10`/+`$11`, +`$0D`/+`$0E` and +2/+3. Going up: an object whose y turns negative is emptied (+0 = 0); going down: one whose y reaches `$12C`. Callers: the scroll steps (`$ADC8`, `$ADFF`).

Witness: L1 172 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z2, L2Z6, L3Z6, L3Z8-L3Z10, L4Z3, L4Z5, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 28 calls, 55,949 t-states own (0.01 %) |
| Runs (the other recordings) | 144 calls (`stage1/level1` 30, `stage1/level2` 22, `stage2/zones/L1Z6` 16 and 17 more) |
| Called from | `ScrollViewDown`, `ScrollViewUp` |
| Reads | `$EA8E`-`$EBF6` (`ObjectTable`, `RickObject`, `RickX`, `RickY` and 10 more) |
| Writes | `$EA8E`-`$EABD` (`ObjectTable`, `RickObject`, `RickX`, `RickY` and 3 more); `$EB06`-`$EBE9` (`ZoneObjects`) |

### `ResetObjects` (`$EBF7`)

**Free every slot but Rick's; no blast, no stick**

Every slot whose type is not 1 gets type 0, up to the `$FF` end; BlastOn `$ECF1` and the stick flag `$FD63` are cleared. Called at each zone set-up (c1 7, level1 19, level4 30).

Witness: L1 439 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 7 calls, 5,833 t-states own (0.00 %) |
| Runs (the other recordings) | 432 calls (`stage1/level4` 30, `stage2/zones/L3Z9` 26, `stage2/zones/L3Z7` 22 and 40 more) |
| Called from | `LoadScreen` |
| Reads | `$EA8E`-`$EB24` (`ObjectTable`, `RickObject`, `RickX`, `RickY` and 9 more); `$EB42` (`ZoneObjects+60`); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`); `$EB9C` (`ZoneObjects+150`); `$EBBA` (`ZoneObjects+180`); 2 more ranges |
| Writes | `$EA8E`-`$EB24` (`ObjectTable`, `RickObject`, `RickX`, `RickY` and 9 more); `$EB42` (`ZoneObjects+60`); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`); `$EB9C` (`ZoneObjects+150`); `$EBBA` (`ZoneObjects+180`); 3 more ranges |

### `UpdateObjects` (`$EC11`)

**Run every object's handler once**

IX = ObjectTable `$EA8E`; UpdateObjectSlot `$EC15` per slot. Called once a pass by MainLoop `$E3C9`.

Witness: L1 43340 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,072 calls, 15,027 t-states own (0.00 %) |
| Runs (the other recordings) | 42,268 calls (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Called from | `MainLoop` |
| Calls | `UpdateObjectSlot` (falls into) |

### `UpdateObjectSlot` (`$EC15`)

**One slot: dispatch on its kind**

Type 0 is skipped, `$FF` ends. Else NextObject `$EC3B` is pushed as the return address and the kind (type AND `$7F`) chosen: `$47` DyingEnemyObj `$F1B7`, `$18` and up TrapObj `$EDFC`, else the word ObjectHandlers[kind].

Witness: L1 563418 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 13,936 calls, 950,253 t-states own (0.09 %) |
| Runs (the other recordings) | 549,482 calls (`stage1/level3` 38,051, `stage1/level2` 36,985, `stage1/level1` 27,976 and 48 more) |
| Called from | `UpdateObjects` (falls into), `NextObject` (tail) |
| Calls | `NextObject` (tail), `DynamiteObj`, `BulletObj`, `AmmoBoxObj`, `TreasureObj`, `TrapObj` (tail), `PatrolObj`, `TrackerObj`, `DyingEnemyObj` (tail), `ClimberObj`, `BonusTrigger`, `BonusCollect`, `RickHandler` |
| Reads | `$EA8E`-`$EB42` (`ObjectTable`, `RickObject`, `RickX`, `RickY` and 9 more); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`); `$EB9C` (`ZoneObjects+150`); `$EBBA` (`ZoneObjects+180`); `$EBD8` (`ZoneObjects+210`); 2 more ranges |

### `NextObject` (`$EC3B`)

**IX to the next slot, +30**

Witness: L1 520078 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 12,864 calls, 475,987 t-states own (0.05 %) |
| Runs (the other recordings) | 507,214 calls (`stage1/level3` 35,124, `stage1/level2` 34,140, `stage1/level1` 25,824 and 48 more) |
| Called from | `UpdateObjectSlot` (tail), `DynamiteObj`, `BulletObj`, `AmmoBoxObj`, `MarkObjectDone`, `TreasureObj`, `TrapObj`, `EnemyCommon`, `KillEnemy`, `DyingEnemyObj`, `ClimberObj`, `BonusTrigger`, `BonusCollect`, `KillRick`, `KillRickNow`, `ChooseRickFrame` |
| Calls | `UpdateObjectSlot` (tail) |

### `KillObject` (`$EC42`)

**Kind 0 with bit 7 set: free the slot**

ObjectHandlers `$EC47` entry 0. Only a type `$80` reaches it. Run by no recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AmmoBoxObj` (`$ED43`)

**Kinds 16 and 17: the dynamite and the bullet box**

Rick touching it (`$F6E0` Z): effect 8, the slot freed, dynamite `$A967` (kind 16) or bullets `$A976` (kind 17) back to 6, MarkObjectDone `$EDDC`. The stick, the bullet or the blast destroys it: type bit 7, MarkObjectDone, and BoxBlastFrame plays BlastFrames `$ECF6` for 9 passes, then the slot is freed.

The zone recordings run it wherever a box is in view; Rick takes the bullet box once in L1Z4 (`$ED76`, effect 8, 1 run) and a blast destroys a box in L4Z4 (BoxBlastFrame, 9 passes).

Witness: L1 5675 (spotL3Z7-51, spotL4Z8-69, L1Z4-L1Z6, L2Z5-L2Z7, L3Z2, L3Z3, L3Z8, L3Z10, L4Z4).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 5,675 runs of its first instruction, entered by a jump (`stage2/zones/L3Z2` 1,230, `stage2/zones/L2Z7` 957, `stage2/zones/L1Z4` 736 and 10 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `PlayEffect`, `NextObject`, `RickTouches`, `PointInObject`, `InBlast` |
| Reads | `$D87F` (`Objects+131`); `$DDAC` (`Level4Objects+166`); `$EACA` (`BulletObject`); `$EB06`-`$EB2E` (`ZoneObjects`); `$EB42` (`ZoneObjects+60`); `$EB7E` (`ZoneObjects+120`); 3 more ranges |
| Writes | `$A976` (`Bullets`); `$D87F` (`Objects+131`); `$DDAC` (`Level4Objects+166`); `$EACA` (`BulletObject`); `$EB06`-`$EB0B` (`ZoneObjects`); `$EB1E`-`$EB24` (`ZoneObjects+24`) |

### `MarkObjectDone` (`$EDDC`)

**Mark the object's level list entry done, so it does not come back**

Sets bit 7 of the byte after (+9/+10); NewGame `$E2DC` clears them all.

Witness: L1 15 (c1, L1Z3, L1Z4, L3Z6, L4Z4, level1, level2).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 11 runs of its first instruction, entered by a jump (`stage1/level1` 4, `stage2/zones/L3Z6` 3, `stage1/level2` 1 and 3 more) |
| Calls | `NextObject` |

### `TreasureObj` (`$EDE6`)

**Kinds 18-21: a bonus item; Rick takes it**

Rick touching it (`$F6E0` Z): effect 9, the slot freed, the score `$A9DD` added (`$A9E8`), MarkObjectDone `$EDDC`.

Taken 4 times in c1 and level1, once in level2 (the `$EDEC` effect counts).

Witness: L1 10293 (c1, L1Z2-L1Z5, L2Z1, L2Z5, L3Z5-L3Z7, L3Z9, L4Z1-L4Z3, level1, level2, level4, spotL1Z4-43, spotL1Z4-44).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 269 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,104 t-states own (0.00 %) |
| Runs (the other recordings) | 10,024 runs of its first instruction, entered by a jump (`stage1/level4` 1,887, `stage2/zones/L3Z5` 1,310, `stage2/zones/L2Z1` 987 and 15 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `PlayEffect`, `AddScore`, `NextObject`, `RickTouches` |
| Reads | `$D816` (`Objects+26`); `$D834` (`Objects+56`); `$D848` (`Objects+76`); `$D86B` (`Objects+111`); `$D965` (`Level2Objects+76`); `$DBDB`-`$DBEA` (`Level3Objects+246`); 4 more ranges |
| Writes | `$D816` (`Objects+26`); `$D834` (`Objects+56`); `$D848` (`Objects+76`); `$D86B` (`Objects+111`); `$D965` (`Level2Objects+76`); `$DBDB`-`$DBEA` (`Level3Objects+246`); 4 more ranges |

### `TrapObj` (`$EDFC`)

**Kinds 24 and up: a trap moving along its path; deadly with bit 7**

TrapMove `$EE0B`, then, if type bit 7 is set, `$F6E0` tests Rick and `$FBED` kills him on touch.

The busiest handler: c1 1299, level2 7377, level3 9162 passes.

Witness: L1 98254 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z3, L1Z5, L1Z6, L2Z1-L2Z4, L2Z6, L2Z7, L3Z1, L3Z2, L3Z4-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

[Animation: `TrapObj` at work](img/routines/TrapObj.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,299 calls, 70,660 t-states own (0.01 %) |
| Runs (the other recordings) | 96,955 calls (`stage1/level3` 9,162, `stage1/level4` 7,548, `stage1/level2` 7,377 and 45 more) |
| Called from | `UpdateObjectSlot` (tail) |
| Calls | `NextObject`, `TrapMove`, `RickTouches`, `KillRick` (tail) |
| Reads | `$EA8E` (`ObjectTable`); `$EB06` (`ZoneObjects`); `$EB24` (`ZoneObjects+30`); `$EB42` (`ZoneObjects+60`); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`) |

### `TrapMove` (`$EE0B`)

**Animate a trap and move it one step along its path**

Animation: the list at +18/19 holds a byte per frame (bit 7 mirror, bits 0-6 the frame number n, the frame at n x `$7E` + `$8383`; 0: no sprite; `$FF`: back to the start), indexed by +24.

Path (+22/23): 3-byte steps (count, dx, dy) each run for count passes; `$FF` ends it. Then a one-shot trap goes (unless Rick is dying); the others restart: type bit 7 from flag bit 2, the position from +15-17, and TrapTriggers `$EF2E` waits for a trigger.

x stays within 0-`$E7`, y below `$12A`; leaving ends the path.

Witness: L1 98404 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z3, L1Z5, L1Z6, L2Z1-L2Z4, L2Z6, L2Z7, L3Z1, L3Z2, L3Z4-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,299 calls, 655,192 t-states own (0.06 %) |
| Runs (the other recordings) | 96,955 calls (`stage1/level3` 9,162, `stage1/level4` 7,548, `stage1/level2` 7,377 and 45 more) |
| Called from | `TrapObj` |
| Calls | `TrapStepMove` (tail), `TrapTriggers` (tail) |
| Reads | `$DF1D`-`$DF98` (`AnimLists`, `ObjectScripts`); `$DFAF`-`$DFD6` (`ObjectScripts+44`); `$E01B`-`$E06E` (`ObjectScripts+152`); `$E082`-`$E08D` (`ObjectScripts+255`); `$E0AA`-`$E0AF` (`ObjectScripts+295`); `$E0E7`-`$E101` (`ObjectScripts+356`); 5 more ranges |
| Writes | `$EA8E`-`$EAA7` (`ObjectTable`); `$EB06`-`$EB97` (`ZoneObjects`) |

### `TrapStepMove` (`$EEE2`)

**One path step: move by dx, dy**

Witness: L1 10822 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1, L1Z5, L1Z6, L2Z1-L2Z3, L2Z6, L2Z7, L3Z1, L3Z7, L3Z8, L3Z10-L3Z12, L4Z x5, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 268 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,326 calls (`stage1/controls` 294, `stage2/zones/L2Z7` 288, `stage2/zones/L3Z8` 240 and 5 more) |
| Called from | `TrapMove` (tail) |
| Reads | `$DF99`-`$DF9A` (`ObjectScripts+22`); `$E01C`-`$E025` (`ObjectScripts+153`); `$E0F8`-`$E0F9` (`ObjectScripts+373`); `$EB07`-`$EB09` (`ZoneObjects+1`); `$EB25`-`$EB27` (`ZoneObjects+31`); `$EB61`-`$EB63` (`ZoneObjects+91`); 1 more ranges |
| Writes | `$EB07`-`$EB09` (`ZoneObjects+1`); `$EB1F`-`$EB27` (`ZoneObjects+25`); `$EB3D` (`ZoneObjects+55`); `$EB61`-`$EB63` (`ZoneObjects+91`); `$EB79`-`$EB81` (`ZoneObjects+115`); `$EB97` (`ZoneObjects+145`) |

### `TrapTriggers` (`$EF2E`)

**A waiting trap: start its path on a trigger**

Skipped while Rick is dying (`$FD68`). By flag +11: bit 7 Rick's centre (RickX + 12, RickY + 10) inside the trap's box (`$F7C3`); bit 6 the stick (`$FD63`, the point `$FD64` / `$FD65`); bit 5 the bullet (BulletObject alive, the point BulletHitX / BulletHitY; the bullet is used up); bit 4 the blast (BlastOn, BlastX / BlastY).

Triggered: type bit 7 = flag bit 3, +24 = 1, +25 = 0, the path pointer from +20/21, effect 3.

Witness: L1 87578 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z3, L1Z5, L1Z6, L2Z1-L2Z4, L2Z6, L2Z7, L3Z1, L3Z2, L3Z4-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,033 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 38,115 calls (`stage2/zones/L4Z9` 4,512, `stage2/zones/L3Z9` 4,458, `stage2/zones/L3Z8` 4,202 and 26 more) |
| Called from | `TrapMove` (tail) |
| Calls | `PlayEffect`, `PointInTrigger` |
| Reads | `$EA99` (`ObjectTable+11`); `$EAAD`-`$EAAE` (`RickX`, `RickY`); `$EACA` (`BulletObject`); `$EB06`-`$EB39` (`ZoneObjects`); `$EB4D` (`ZoneObjects+71`); `$EB60`-`$EB93` (`ZoneObjects+90`); 2 more ranges |
| Writes | `$EB06` (`ZoneObjects`); `$EB1C`-`$EB24` (`ZoneObjects+22`); `$EB3A`-`$EB3D` (`ZoneObjects+52`); `$EB60` (`ZoneObjects+90`); `$EB76`-`$EB7E` (`ZoneObjects+112`); `$EB94`-`$EB97` (`ZoneObjects+142`) |

### `PatrolObj` (`$EFCF`)

**Kinds 4, 7, 10, 13: an enemy walking to and fro**

Clears TracksRick `$F173` and goes to EnemyCommon `$EFDB`.

Witness: L1 25331 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2, L2Z4, L2Z5, L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1, level2, level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 693 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 18,711 t-states own (0.00 %) |
| Runs (the other recordings) | 24,638 runs of its first instruction, entered by a jump (`stage2/zones/L3Z10` 2,103, `stage1/level4` 1,887, `stage2/zones/L1Z2` 1,709 and 35 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `EnemyCommon` (tail) |
| Reads | `$EACA`-`$EACD` (`BulletObject`, `BulletX`, `BulletY`); `$ECF1` (`BlastOn`); `$ED3F` (`BulletDx`); `$FD63`-`$FD66` (`Poking`, `PokeX`, `PokeY`) |
| Writes | `$F173` (`TracksRick`) |

### `TrackerObj` (`$EFD6`)

**Kinds 5, 8, 11, 14: an enemy that turns towards Rick**

Sets TracksRick `$F173` = `$FF` and falls into EnemyCommon `$EFDB`.

Witness: L1 14644 (c1, L1Z3, L1Z4, L2Z5, L2Z6, L3Z2-L3Z4, L3Z6-L3Z9, L3Z11, L3Z12, L4Z2-L4Z8, level1, level2).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 178 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,560 t-states own (0.00 %) |
| Runs (the other recordings) | 14,466 runs of its first instruction, entered by a jump (`stage2/zones/L3Z12` 2,061, `stage2/zones/L2Z6` 1,619, `stage2/zones/L1Z3` 1,522 and 19 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `EnemyCommon` (falls into) |
| Reads | `$EACA` (`BulletObject`); `$ECF1` (`BlastOn`); `$FD63` (`Poking`) |
| Writes | `$F173` (`TracksRick`) |

### `EnemyCommon` (`$EFDB`)

**An enemy: fall and walk, die by the bullet or blast, stunned by the stick**

The patrollers and trackers (kinds 4, 5, 7, 8, 10, 11, 13, 14); the climbers run ClimberObj `$F233`. EnemyFall `$F02F`; `$F812` (HitsObstacle: object 0 or a deadly actor) Z kills it (KillEnemy `$F17C`). The bullet (the point BulletX, + `$18` when BulletDx is positive, and BulletY, `$F742`) kills it and is used up; the blast (`$F76F`) kills it. The stick (`$FD63`, `$F742` at `$FD64` / `$FD65`) stuns it: +29 = 20 passes.

Witness: L1 39975 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2, L2Z4-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1, level2, level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 871 calls, 113,160 t-states own (0.01 %) |
| Runs (the other recordings) | 25,797 calls (`stage2/zones/L3Z3` 2,394, `stage2/zones/L3Z12` 2,163, `stage2/zones/L4Z4` 2,035 and 18 more) |
| Called from | `PatrolObj` (tail), `TrackerObj` (falls into) |
| Calls | `NextObject`, `EnemyFall`, `KillEnemy` (tail), `PointInObject`, `InBlast`, `HitsObstacle` |
| Reads | `$EACA`-`$EACD` (`BulletObject`, `BulletX`, `BulletY`); `$ECF1` (`BlastOn`); `$ED3F` (`BulletDx`); `$FD63`-`$FD66` (`Poking`, `PokeX`, `PokeY`) |
| Writes | `$EACA` (`BulletObject`) |

### `EnemyFall` (`$F02F`)

**Fall under gravity until on a floor, then walk**

y += y speed (+27/28, 8.8, +`$80` a pass up to `$0800`); at `$12D` and below the enemy goes (EnemyGone). `$F5D5` probes the map at (x, y): its result `$F6A8` bits 4-7 a floor, bit 2 a deadly cell (KillEnemy `$F17C`). Falling: touching Rick kills him (`$FBED`), the frame is base + `$7E`.

On a floor: y snapped to 8n + 3, speed `$0080`, mirror by +24's sign, the walk frame EnemyWalkFrames[x bits 2-3]. A stunned enemy (+29) counts down and only kills Rick on touch. Else it steps +24 (2 or -2) along x within 0-`$E7`, turning at a wall or a ledge (`$F6A8`), after +12 / 2 steps, or (TracksRick) towards RickX when x AND `$1E` = `$10`.

Witness: L1 39975 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2, L2Z4-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1, level2, level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 871 calls, 699,587 t-states own (0.07 %) |
| Runs (the other recordings) | 39,104 calls (`stage2/zones/L3Z3` 2,394, `stage2/zones/L3Z12` 2,163, `stage2/zones/L3Z10` 2,103 and 36 more) |
| Called from | `EnemyCommon` |
| Calls | `ProbeBox`, `RickTouches`, `KillRick` (tail) |
| Reads | `$EAAD` (`RickX`); `$EB9D`-`$EBF5` (`ZoneObjects+151`); `$F173`-`$F17B` (`TracksRick`, `EnemyWalkFrames`); `$F6A8` (`ProbeResult`) |
| Writes | `$EB9C`-`$EBA2` (`ZoneObjects+150`); `$EBB4`-`$EBC0` (`ZoneObjects+174`); `$EBD2`-`$EBDE` (`ZoneObjects+204`); `$EBF0`-`$EBF5` (`ZoneObjects+234`) |

### `KillEnemy` (`$F17C`)

**An enemy is hit: it flies up and falls out of the zone**

Effect 11, type `$47`, y speed `$FC00` (up), the score `$A9D3` added (`$A9E8`), MarkObjectDone for a one-shot enemy, and the sideways drift +24 = 3, or -3 on the right half of the screen.

Run 5 times in c1 and level1, 4 in level2, 2 in level4 (the `$F17E` effect counts).

Witness: L1 21 (c1, L2Z6, L3Z2, L3Z11, L4Z2, level1, level2, level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5 calls, 1,039 t-states own (0.00 %) |
| Runs (the other recordings) | 16 calls (`stage1/level1` 5, `stage1/level2` 4, `stage1/level4` 2 and 4 more) |
| Called from | `EnemyCommon` (tail), `ClimberObj` (tail) |
| Calls | `PlayEffect`, `AddScore`, `NextObject` |
| Reads | `$DB0E` (`Level3Objects+41`); `$EB9D`-`$EBA7` (`ZoneObjects+151`); `$EBBB`-`$EBC5` (`ZoneObjects+181`); `$EBD9`-`$EBE3` (`ZoneObjects+211`) |
| Writes | `$DB0E` (`Level3Objects+41`); `$EB9C` (`ZoneObjects+150`); `$EBB4`-`$EBBA` (`ZoneObjects+174`); `$EBD2`-`$EBD8` (`ZoneObjects+204`); `$EBF0`-`$EBF4` (`ZoneObjects+234`) |

### `DyingEnemyObj` (`$F1B7`)

**Kind `$47`: a killed enemy tumbling out of the zone**

The frame base + `$17A`, mirrored every other pass; y += y speed (gravity `$80` a pass); x += the drift within 0-`$E8`. Gone when y leaves 0-`$FF`.

Witness: L1 582 (c1, L2Z6, L3Z2, L3Z11, L4Z2, level1, level2, level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 145 calls, 80,880 t-states own (0.01 %) |
| Runs (the other recordings) | 437 calls (`stage1/level1` 145, `stage1/level2` 132, `stage1/level4` 60 and 4 more) |
| Called from | `UpdateObjectSlot` (tail) |
| Calls | `NextObject` |
| Reads | `$EB9D`-`$EBF4` (`ZoneObjects+151`) |
| Writes | `$EB9C`-`$EBA2` (`ZoneObjects+150`); `$EBB5`-`$EBC0` (`ZoneObjects+175`); `$EBD3`-`$EBDE` (`ZoneObjects+205`); `$EBF1`-`$EBF4` (`ZoneObjects+235`) |

### `ClimberObj` (`$F233`)

**Kinds 6, 9, 12, 15: an enemy that climbs towards Rick**

ClimberMove `$F266`; touching Rick kills him; `$F812` Z kills it; the bullet kills it.

Run in every level, most in level4 (3517 passes), where it climbs (ClimberState).

Witness: L1 15799 (c1, L1Z3, L1Z4, L2Z2-L2Z6, L3Z2, L3Z5, L3Z11, L4Z1-L4Z8, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 89 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,818 t-states own (0.00 %) |
| Runs (the other recordings) | 15,710 runs of its first instruction, entered by a jump (`stage1/level4` 3,517, `stage2/zones/L2Z4` 2,175, `stage2/zones/L4Z1` 1,294 and 19 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `NextObject`, `KillEnemy` (tail), `ClimberMove`, `RickTouches`, `PointInObject`, `HitsObstacle`, `KillRick` |
| Reads | `$EACA`-`$EACD` (`BulletObject`, `BulletX`, `BulletY`); `$ED3F` (`BulletDx`) |

### `ClimberMove` (`$F266`)

**Climber: the blast and the stick, then climb or fall**

The blast kills it; the stick stuns it (+29 = 20); a stunned climber counts down and stays. +24 = 0: it falls (ClimberFall `$F362`). Else it climbs: frame base + `$1F8`, mirrored by y bit 2; level with RickY (even): one step of 2 towards RickX; else 2 up or down towards RickY while the map (`$F5D5`) allows; off the ladder +24 = 0.

The climb ran only in level4 (869 passes): known from the code and that recording.

Witness: L1 15799 (c1, L1Z3, L1Z4, L2Z2-L2Z6, L3Z2, L3Z5, L3Z11, L4Z1-L4Z8, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 89 calls, 10,680 t-states own (0.00 %) |
| Runs (the other recordings) | 15,710 calls (`stage1/level4` 3,517, `stage2/zones/L2Z4` 2,175, `stage2/zones/L4Z1` 1,294 and 19 more) |
| Called from | `ClimberObj` |
| Calls | `ClimberFall` (tail), `ProbeBox`, `PointInObject`, `InBlast` |
| Reads | `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$EB9D`-`$EBF5` (`ZoneObjects+151`); `$ECF1` (`BlastOn`); `$F174`-`$F17B` (`EnemyWalkFrames`); `$F6A8` (`ProbeResult`); `$FD63`-`$FD66` (`Poking`, `PokeX`, `PokeY`) |
| Writes | `$EB9D`-`$EBA2` (`ZoneObjects+151`); `$EBB4`-`$EBC0` (`ZoneObjects+174`); `$EBD2`-`$EBDE` (`ZoneObjects+204`); `$EBF0`-`$EBF5` (`ZoneObjects+234`) |

### `ClimberFall` (`$F362`)

**Climber: fall under gravity; on a ladder above Rick start climbing**

As EnemyFall: y speed with gravity, a deadly cell kills it, at `$12A` and below it goes. On a ladder cell (`$F6A8` bit 7) at x AND 7 = 4 and above RickY: +24 = 1, climbing. The rest of the routine is in the next fragment.

Witness: L1 11684 (c1, L1Z3, L1Z4, L2Z2-L2Z6, L3Z2, L3Z5, L3Z11, L4Z1-L4Z8, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 89 calls, 66,254 t-states own (0.01 %) |
| Runs (the other recordings) | 2,528 calls (`stage2/zones/L1Z3` 761, `stage1/level2` 548, `stage1/level1` 439 and 5 more) |
| Called from | `ClimberMove` (tail) |
| Calls | `Random`, `ProbeBox` |
| Reads | `$EAAE`-`$EAAF` (`RickY`); `$EB9D`-`$EBF5` (`ZoneObjects+151`); `$F174`-`$F17B` (`EnemyWalkFrames`); `$F6A8` (`ProbeResult`) |
| Writes | `$EB9D`-`$EBA2` (`ZoneObjects+151`); `$EBB5`-`$EBC0` (`ZoneObjects+175`); `$EBD3`-`$EBDE` (`ZoneObjects+205`); `$EBF1`-`$EBF4` (`ZoneObjects+235`) |

### `BonusTrigger` (`$F4C8`)

**Kind 22: Rick touches it, the timed bonus starts**

Handler of object kind 22 (the pointer at `$EC73` of the kind table). IX = the object. It hides the sprite (+4/+5 =

0) and tests the point (Rick X + 12, Rick Y + 10) against the object's trigger box (PointInTrigger `$F7C3`). Inside:

the object is freed (+0 = 0), BonusActive `$FD6C` = `$FF` (the countdown at `$E466` then runs), the bonus digits

`$E496-$E49A` are cleared and `$E497` = 2, and sound effect 10 plays (`$9FED`).

Outputs: none. Side effects: `$FD6C`, `$E496-$E49A`, the object.

Evidence: the bonus started (`$F4E2`) in c1 1, controls 7, gameover 6, level1 7, level2 3 times.

Witness: L1 5910 (beeper48, c1, controls, gameover, spotL2Z4-34, L1Z1, L1Z3, L1Z4, L2Z1, L2Z2, L2Z4, L2Z5, L3Z5, L3Z11, L3Z12, L4Z3, L4Z4, level1, level2).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 90 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 11,035 t-states own (0.00 %) |
| Runs (the other recordings) | 5,820 runs of its first instruction, entered by a jump (`stage1/level2` 1,189, `stage2/zones/L2Z2` 824, `stage2/zones/L1Z3` 761 and 15 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `PlayEffect`, `NextObject`, `PointInTrigger` |
| Reads | `$EAAD`-`$EAAE` (`RickX`, `RickY`) |
| Writes | `$E496`-`$E49A` (`BonusDigits`); `$EB06`-`$EB0B` (`ZoneObjects`); `$EB24`-`$EB29` (`ZoneObjects+30`); `$EB60`-`$EB65` (`ZoneObjects+90`); `$FD6C` (`BonusActive`) |

### `BonusCollect` (`$F502`)

**Kind 23: Rick reaches it while the bonus runs**

Handler of object kind 23 (the pointer at `$EC75`). IX = the object. The sprite is hidden; nothing more while

BonusActive `$FD6C` is 0. With the bonus running, Rick's point (X + 12, Y + 10) inside the trigger box

(PointInTrigger `$F7C3`) clears `$FD6C`, frees the object, adds the bonus digits at `$E49A` to the score (`$A9E8`,

DE = `$E49A`) and plays tune 7 (`$A016`).

Side effects: `$FD6C`, the score, the music.

Evidence: collected (`$F521`) once each in c1 and level1.

Witness: L1 5972 (c1, spotL2Z4-34, L1Z2-L1Z4, L2Z2-L2Z5, L2Z7, L3Z6, L3Z7, L3Z12, L4Z5, L4Z6, level1, level2, spotL1Z4-44).

[Animation: `BonusCollect` at work](img/routines/BonusCollect.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 226 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 25,556 t-states own (0.00 %) |
| Runs (the other recordings) | 5,746 runs of its first instruction, entered by a jump (`stage2/zones/L3Z6` 770, `stage2/zones/L1Z3` 761, `stage2/zones/L2Z4` 725 and 14 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `StartTune`, `AddScore`, `NextObject`, `PointInTrigger` |
| Reads | `$EAAD`-`$EAAE` (`RickX`, `RickY`); `$FD6C` (`BonusActive`) |
| Writes | `$EB06`-`$EB0B` (`ZoneObjects`); `$EB28`-`$EB29` (`ZoneObjects+34`); `$EB42`-`$EB47` (`ZoneObjects+60`); `$EB64`-`$EB65` (`ZoneObjects+94`); `$EB82`-`$EB83` (`ZoneObjects+124`); `$FD6C` (`BonusActive`) |

### `IsSolidAt` (`$F535`)

**Z when the point (A, L) is free: no wall char and not inside object 0**

Inputs: A = X, L = Y (pixels; row Y / 8 of the playfield map `$6500`, 32 columns). It reads the char at the point,

its property at `$5C00` + code, and returns NZ (A = `$40`) on bit 6 (wall). Else, with object 0 `$EA8E` present,

it tests the point against its box (PointInObject `$F742`): inside gives NZ (A = 1), outside Z (A = 0).

Outputs: Z/NZ, A, E = X. Preserves HL, D; uses BC.

Evidence: the object 0 test (`$F566`) ran only in level2 (6).

Witness: L1 542 (beeper48, c1, emptygun, L1Z5, L2Z1, L2Z6, L3Z x7, L4Z3, L4Z4, L4Z8, L4Z9, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 25 calls, 5,210 t-states own (0.00 %) |
| Runs (the other recordings) | 517 calls (`docs/integrate/emptygun` 150, `stage1/level3` 84, `stage1/level4` 48 and 17 more) |
| Called from | `BulletObj` |
| Calls | `PointInObject` |
| Reads | `$5C00`-`$5C54` (`SystemVariables`); `$5C7F`-`$5C80` (`SystemVariables+127`); `$5CCB`-`$5CF5` (`BasicLeft`); `$66CC` (`MusicImage+2252`); `$6740`-`$676C` (`MusicImage+2368`); `$6795`-`$6797` (`MusicImage+2453`); 3 more ranges |

### `ProbeLow` (`$F56D`)

**The probe of a crawling object: properties of the chars under its box, the top row apart**

The low twin of ProbeBox `$F5D5` (B = 1 row less: the box of a crawling Rick). Inputs: E = X, HL = Y of the box's

top (pixels). The box is 2 columns wide when X + 4 is a multiple of 8, else 3. The top row's properties (AND

`$F0`) go to ProbeLowResult `$F6A7`; then the rows below are scanned by ProbeBoxAligned `$F602` or

ProbeBoxUnaligned `$F654`, which leave the OR of all rows in ProbeResult `$F6A8` and add object 0 (ProbeBoxObject0

`$F624`).

Outputs: `$F6A7`, `$F6A8`, A. Preserves DE, HL.

Evidence: both widths ran (`$F59A` aligned, `$F5B4` unaligned) in c1 and level1-level4 (level2 1091).

Witness: L1 6062 (beeper48, c1, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 37 calls, 12,853 t-states own (0.00 %) |
| Runs (the other recordings) | 6,025 calls (`stage1/level2` 1,091, `stage2/zones/L4Z6` 448, `stage2/zones/L4Z7` 268 and 36 more) |
| Called from | `MoveRick`, `WalkRick` |
| Calls | `ProbeBoxAligned` (tail), `ProbeBoxUnaligned` (tail) |
| Reads | `$5C00`-`$5C68` (`SystemVariables`); `$5C92`-`$5C93` (`SystemVariables+146`); `$5CB2`-`$5CB5` (`SystemVariables+178`); `$5CCB`-`$5CF7` (`BasicLeft`); `$66A4`-`$66B4` (`MusicImage+2212`); `$6701`-`$6702` (`MusicImage+2305`); 4 more ranges |
| Writes | `$F6A7` (`ProbeLowResult`) |

### `ProbeBox` (`$F5D5`)

**The OR of the char properties under an object's box, into ProbeResult**

Inputs: E = X, HL = Y of the box's top (pixels; the box of Rick and the walkers: B = 2 rows above the bottom one, 3

when Y AND 4). X + 4 a multiple of 8: 2 columns (ProbeBoxAligned `$F602`), else 3 (ProbeBoxUnaligned `$F654`). The

upper rows count without bits 4 and 7 (platform, floor), the edge columns without bit 1 (ladder): a ladder counts

only under the middle, a floor or platform only under the feet.

Outputs: ProbeResult `$F6A8` = A, with bit 6 added when the box overlaps object 0 `$EA8E` (ProbeBoxObject0 `$F624`).

Preserves DE, HL. Callers: the walkers (`$F362`), MoveRick `$F85D`, WalkRick `$F903`, ClimbRick `$FB14`.

Witness: L1 142633 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3,257 calls, 642,755 t-states own (0.06 %) |
| Runs (the other recordings) | 139,376 calls (`stage1/level4` 10,104, `stage1/level1` 6,298, `stage1/level2` 5,902 and 47 more) |
| Called from | `EnemyFall`, `ClimberMove`, `ClimberFall`, `MoveRick`, `WalkRick`, `ClimbRick`, `ClimbSideProbe` |
| Calls | `ProbeBoxAligned` (falls into), `ProbeBoxUnaligned` (tail) |
| Reads | `$5C00`-`$5C03` (`SystemVariables`); `$5C15`-`$5C5B` (`SystemVariables+21`); `$5C70`-`$5C74` (`SystemVariables+112`); `$5C89`-`$5C90` (`SystemVariables+137`); `$5CAE`-`$5CFD` (`SystemVariables+174`, `ChannelInfo`, `BasicLeft`); `$65A9`-`$660E` (`MusicImage+1961`); 10 more ranges |
| Writes | `$F68A`-`$F68C` (`ProbeRecord+1`); `$F6A8` (`ProbeResult`) |

### `ProbeBoxAligned` (`$F602`)

**ProbeBox's rows for a box 2 columns wide**

Part of ProbeBox `$F5D5` and ProbeLow `$F56D`, reached by their jumps, not called. B rows of 2 chars AND `$6F`,

then the bottom row with every bit, into ProbeResult `$F6A8`; on into ProbeBoxObject0 `$F624`.

Witness: L1 105462 (beeper48, c1, controls, ending2, gameover, l1z1left, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 852 calls, 292,251 t-states own (0.03 %) |
| Runs (the other recordings) | 37,842 calls (`stage1/level4` 2,953, `stage1/level2` 2,370, `stage1/level3` 1,784 and 35 more) |
| Called from | `ProbeLow` (tail), `ProbeBox` (falls into) |
| Calls | `ProbeBoxObject0` (falls into) |
| Reads | `$5C00`-`$5CFD` (`SystemVariables`, `ChannelInfo`, `BasicLeft`); `$652D`-`$653B` (`MusicImage+1837`); `$654D`-`$655B` (`MusicImage+1869`); `$656D`-`$694D` (`MusicImage+1901`); `$696C`-`$696D` (`MusicImage+2924`); `$698C`-`$698D` (`MusicImage+2956`); 1 more ranges |
| Writes | `$F6A8` (`ProbeResult`) |

### `ProbeBoxObject0` (`$F624`)

**ProbeBox's tail: add object 0 as a wall**

Pops HL, DE. A wall already found (bit 6): return. With object 0 `$EA8E` present, its box against the probe's

(ProbeRecord `$F689` as the IY object, ObjectsOverlap `$F6E9`): an overlap sets bit 6 of ProbeResult `$F6A8`.

Outputs: A = `$F6A8`.

Evidence: object 0 overlapped the probe (`$F64E`) once, in level2; the test (`$F643`) ran in level2 and level3 only.

Witness: L1 148695 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3,294 calls, 184,786 t-states own (0.02 %) |
| Runs (the other recordings) | 138,655 calls (`stage1/level4` 10,258, `stage1/level2` 6,993, `stage1/level1` 6,361 and 36 more) |
| Called from | `ProbeBoxAligned` (falls into), `ProbeBoxUnaligned` (tail) |
| Calls | `ObjectsOverlap` |
| Reads | `$EA8E` (`ObjectTable`); `$F6A8` (`ProbeResult`) |
| Writes | `$F68A`-`$F68C` (`ProbeRecord+1`); `$F6A8` (`ProbeResult`) |

### `ProbeBoxUnaligned` (`$F654`)

**ProbeBox's rows for a box 3 columns wide**

B rows of 3 chars, the edges AND `$6D`, the middle AND `$6F`; the bottom row: edges AND `$7D`, the middle whole.

Into ProbeResult `$F6A8`, then JP ProbeBoxObject0 `$F624`.

Witness: L1 267099 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 2,442 calls, 1,218,468 t-states own (0.12 %) |
| Runs (the other recordings) | 99,614 calls (`stage1/level4` 7,305, `stage1/level1` 4,658, `stage1/level2` 4,623 and 36 more) |
| Called from | `ProbeLow` (tail), `ProbeBox` (tail) |
| Calls | `ProbeBoxObject0` (tail) |
| Reads | `$5C00`-`$5CFD` (`SystemVariables`, `ChannelInfo`, `BasicLeft`); `$652C`-`$693B` (`MusicImage+1836`); `$6974`-`$6976` (`MusicImage+2932`); `$6994`-`$6A1B` (`MusicImage+2964`) |
| Writes | `$F6A8` (`ProbeResult`) |

### `BuildCharProps` (`$F6A9`)

**Fill the char property table `$5C00` from 8 run-length pairs**

Input: DE = 8 pairs (count, property), 256 chars in all (CharPropsSet0 `$F6C0` or CharPropsSet1 `$F6D0`). Writes

`$5C00-$5CFF`, one property per char code (bits: this module's header). Called by the zone setup at `$ACCF`, which

picks the set from the zone record's byte +0 (0: `$F6C0` with the tiles at `$7100`; else `$F6D0`, tiles `$7A00`).

Outputs: none. Uses AF', B, C (shifted, unused), DE, HL.

Evidence: c1 7, controls 11, gameover 7, level1 19, level2 5, level3 7, level4 30 zone setups.

Witness: L1 439 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 7 calls, 46,926 t-states own (0.00 %) |
| Runs (the other recordings) | 432 calls (`stage1/level4` 30, `stage2/zones/L3Z9` 26, `stage2/zones/L3Z7` 22 and 40 more) |
| Called from | `LoadScreen` |
| Reads | `$F6C0`-`$F6DF` (`CharPropsSet0`, `CharPropsSet1`) |
| Writes | `$5C00`-`$5CFF` (`SystemVariables`, `ChannelInfo`, `BasicLeft`) |

### `RickTouches` (`$F6E0`)

**Does the IX object overlap Rick? Never while Rick dies**

Called by the object handlers with IX = the object. Rick dying (`$FD68` nonzero): NZ at once. Else IY = Rick

`$EAAC` and on into ObjectsOverlap `$F6E9`.

Outputs: Z = overlap. Uses IY, A, BC, DE, HL.

Witness: L1 113605 (beeper48, c1, controls, ending2, gameover, l1end, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,491 calls, 52,692 t-states own (0.01 %) |
| Runs (the other recordings) | 112,114 calls (`stage1/level4` 12,952, `stage2/zones/L4Z1` 4,529, `stage1/level2` 4,224 and 46 more) |
| Called from | `AmmoBoxObj`, `TreasureObj`, `TrapObj`, `EnemyFall`, `ClimberObj` |
| Calls | `ObjectsOverlap` (falls into) |
| Reads | `$EA8F`-`$EA95` (`ObjectTable+1`); `$EAAC`-`$EAAF` (`RickObject`, `RickX`, `RickY`); `$EB07`-`$EB0E` (`ZoneObjects+1`); `$EB25`-`$EB2C` (`ZoneObjects+31`); `$EB43`-`$EB4A` (`ZoneObjects+61`); `$EB61`-`$EB68` (`ZoneObjects+91`); 5 more ranges |

### `ObjectsOverlap` (`$F6E9`)

**Z when the IY object's body box overlaps the IX object's box**

IY's box (a Rick-sized body): X from IY+1 + 5 to IY+1 + 17, Y from IY+2/+3 (8 lower when IY is Rick, kind 1,

crawling: `$FD5A`) to IY+2/+3 + 20. IX's box: X from IX+1 to + width (+7), Y from IX+2/+3 to + height (+8) - 1.

Outputs: Z and A = 0 on overlap, NZ and A = 1 else. Uses BC, DE, HL.

Witness: L1 142755 (beeper48, c1, controls, ending2, gameover, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,447 calls, 189,298 t-states own (0.02 %) |
| Runs (the other recordings) | 120,508 calls (`stage1/level4` 22,594, `stage2/zones/L4Z1` 7,470, `stage2/zones/L4Z9` 7,275 and 28 more) |
| Called from | `ProbeBoxObject0`, `RickTouches` (falls into), `HitsObstacle` |
| Reads | `$EA8F`-`$EA96` (`ObjectTable+1`); `$EAAC`-`$EAAF` (`RickObject`, `RickX`, `RickY`); `$EB07`-`$EB0E` (`ZoneObjects+1`); `$EB25`-`$EB2C` (`ZoneObjects+31`); `$EB43`-`$EB4A` (`ZoneObjects+61`); `$EB61`-`$EB68` (`ZoneObjects+91`); 6 more ranges |

### `PointInObject` (`$F742`)

**Z when the point (E, HL) is inside the IX object's box**

X strictly between IX+1 and IX+1 + width (+7), Y from IX+2/+3 to that + height (+8).

Outputs: Z/NZ, A = 0 / 1. Uses BC, DE, HL.

Witness: L1 718 (c1, L1Z4, L2Z1, L3Z x7, L4Z3-L4Z6, L4Z9, level1, level2, level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 34 calls, 3,370 t-states own (0.00 %) |
| Runs (the other recordings) | 684 calls (`stage1/level4` 138, `stage2/zones/L3Z10` 88, `stage2/zones/L4Z3` 86 and 14 more) |
| Called from | `AmmoBoxObj`, `EnemyCommon`, `ClimberObj`, `ClimberMove`, `IsSolidAt` |
| Reads | `$EA8F`-`$EA96` (`ObjectTable+1`); `$EB07`-`$EB0E` (`ZoneObjects+1`); `$EB25`-`$EB2B` (`ZoneObjects+31`); `$EB43`-`$EB49` (`ZoneObjects+61`); `$EB9D`-`$EBA4` (`ZoneObjects+151`); `$EBBB`-`$EBC2` (`ZoneObjects+181`); 1 more ranges |

### `InBlast` (`$F76F`)

**Z when the IX object lies inside the dynamite's blast box**

The blast box: X from dynamite X (`$EAE9`) - 4 to that + 32, x + 28 (clamped to 0 and `$FF`), Y from dynamite Y (`$EAEA`) - 4

(clamped to 0) to that + 29, y + 25: 33 x 30 pixels. The object's box: IX+1 / +7, IX+2/+3 / +8.

Outputs: Z/NZ, A = 0 / 1. Uses BC, DE, HL.

Witness: L1 1181 (beeper48, L1Z1, L1Z2, L2Z1, L2Z2, L2Z6, L2Z7, L3Z2, L3Z6, L3Z11, L4Z x5, level2, level3).

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 1,181 calls (`stage2/zones/L2Z2` 153, `stage2/zones/L3Z2` 111, `stage2/zones/L4Z9` 108 and 14 more) |
| Called from | `DynamiteObj`, `AmmoBoxObj`, `EnemyCommon`, `ClimberMove` |
| Reads | `$EAAD`-`$EAB4` (`RickX`, `RickY`, `RickMirror`, `RickWidth` and 1 more); `$EAE9`-`$EAEB` (`DynamiteX`); `$EB07` (`ZoneObjects+1`); `$EB25`-`$EB2B` (`ZoneObjects+31`); `$EB43` (`ZoneObjects+61`); `$EB9D`-`$EBA4` (`ZoneObjects+151`); 2 more ranges |

### `PointInTrigger` (`$F7C3`)

**Z when the point (E, HL) is inside the IX object's trigger box**

The trigger box: X from IX+C, Y from IX+D/+E, its size from the kind's 8-byte record at `$D31C`: byte +6 the width

and +7 the height, in chars (x 8; `$D322` = `$D31C` + 6). Used with Rick's point (X + 12, Y + 10) by the traps

and BonusTrigger `$F4C8`, BonusCollect `$F502`.

Outputs: Z/NZ, A = 0 / 1. Uses BC, DE, HL.

Evidence: the Y half (`$F7EA`) ran in every game build (level3 1368).

Witness: L1 55292 (beeper48, c1, controls, emptygun, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1, L3Z2, L3Z5-L3Z12, L4Z1-L4Z8, level1-level4, spotL1Z4-43, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,200 calls, 185,581 t-states own (0.02 %) |
| Runs (the other recordings) | 54,092 calls (`stage1/level2` 7,238, `stage1/level3` 5,296, `stage2/zones/L4Z8` 3,238 and 42 more) |
| Called from | `TrapTriggers`, `BonusTrigger`, `BonusCollect` |
| Reads | `$D3D2`-`$D4CB` (`ObjectKinds+182`); `$D4E2`-`$D533` (`ObjectKinds+454`); `$D54A`-`$D553` (`ObjectKinds+558`); `$EA8E`-`$EA9C` (`ObjectTable`); `$EB06`-`$EB8C` (`ZoneObjects`) |

### `HitsObstacle` (`$F812`)

**Z when the IX object overlaps object 0 or an active object of the slots `$EB06`**

The IX object becomes IY; tested against object 0 `$EA8E` (when present) and the 5 slots from `$EB06` with bit 7

of +0 set, by ObjectsOverlap `$F6E9`. IX is restored. An enemy's hit test: does object 0 or a deadly actor overlap it (callers EnemyCommon `$EFDE`, ClimberObj `$F23C`).

Outputs: Z (A = 0) on a hit, NZ (A = 1) else. Uses BC, DE, HL, IY.

Evidence: a hit on object 0 (`$F824`) in level2 and level3; on a slot (`$F83B`) in c1, level1, level2, level4.

Witness: L1 55773 (c1, ending2, spotL3Z7-51, spotL4Z8-69, L1Z2-L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 960 calls, 543,288 t-states own (0.05 %) |
| Runs (the other recordings) | 54,813 calls (`stage1/level4` 5,404, `stage2/zones/L4Z7` 2,676, `stage2/zones/L2Z4` 2,412 and 38 more) |
| Called from | `EnemyCommon`, `ClimberObj` |
| Calls | `ObjectsOverlap` |
| Reads | `$EA8E` (`ObjectTable`); `$EB06` (`ZoneObjects`); `$EB24` (`ZoneObjects+30`); `$EB42` (`ZoneObjects+60`); `$EB60` (`ZoneObjects+90`); `$EB7E` (`ZoneObjects+120`) |

## menu

`src/game/menu.asm`

### `Menu` (`$E219`)

**The menu: title, control methods, credits; choose a method and start**

Waits until no key is pressed (`$A123` gives Z while fire or a key is down), plays tune 5 (`$A016`), clears the screen (`$AB03`) and prints three texts with `$AAE9`: ControlsText `$EA1B` at `$40EA`, TitleText `$E9FB` at `$4041`, CreditsText `$EA51` at `$5047`.

Then, every two frames, it lights the attribute row of the chosen method (DE the attribute address, C its width: `$58EE`/8, `$592E`/8, `$596E`/6, `$59AE`/8 for methods 0-3) by `$AB18` with the colour table `$AB3D`, and reads keys 1-4. A new method is stored in `$A14C` and its old row is put back with `$AB45`. Fire (`$A123` Z) leaves through MenuWaitRelease into NewGame `$E2DC`.

Seen in c1, controls (all four methods), gameover, level1 and ending; the menu screen is work/images/menu.*.bin. The `LD DE,$780A` at `$E229` is dead: the next instruction loads DE again.

Witness: L1 30069 (c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 call, 827,112,311 t-states own (81.07 %) |
| Runs (the other recordings) | 2 calls (`stage2/ending2` 1, `stage1/ending` 1) |
| Called from | `Start` (tail), `GameOver` (tail) |
| Calls | `StartTune`, `Key1Pressed`, `Key2Pressed`, `Key3Pressed`, `Key4Pressed`, `StartPressed`, `PrintLines`, `ClearScreen`, `CycleAttributes` |
| Reads | `$A14C` (`ControlMethod`); `$A958` (`Lives`); `$D7FD`-`$DF19` (`Objects+1`, `Level2Objects`, `Level3Objects`, `Level4Objects`); `$E268`-`$E269` (`MenuFrame+1`); `$E410` (`MainLoopHalt+1`); `$E440` (`GameComplete`); 3 more ranges |
| Writes | `$7900` (`CharAttr0`); `$A14C` (`ControlMethod`); `$A237` (`FrameTicks`); `$A958`-`$A976` (`Lives`, `DrawDynamite`, `Dynamite`, `DrawBullets` and 1 more); `$A9BE`-`$A9C3` (`Score`); `$D7FD`-`$DF19` (`Objects+1`, `Level2Objects`, `Level3Objects`, `Level4Objects`); 4 more ranges |

### `NewGame` (`$E2DC`)

**New game: reset the game state, print the first level's intro**

Clears the screen, then bit 7 (done) of `$016D` records of 5 bytes from `$D7FD` (the level object lists: a taken or killed one-shot object stays gone), Level `$E4AD`, GameComplete `$E440` and the score `$A9BE-$A9C3`. Lives `$A958`, bullets `$A976` and dynamite `$A967` = 6. `$A93D` draws the HUD.

LevelIntro prints LevelTable's first text (SouthAmericaText `$E4E5`) at its screen address with `$AAE9`, C = `$47`, sets `$7900` to the record's attribute, plays tune 0 and waits until fire is let go; StartLevel `$E32C` follows.

Run once per new game: c1 1, controls 4, gameover 1, level1 2 (the natural GAME OVER starts a new game).

Witness: L1 9 (beeper48, c1, controls, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8 runs of its first instruction, entered by a jump (`stage1/controls` 4, `stage1/level1` 2, `stage1/gameover` 1 and 1 more) |
| Calls | `StartTune`, `StartPressed`, `DrawHud`, `PrintLines`, `ClearScreen` |

### `Quit` (`$E35A`)

**Quit: Q in the main loop, or the last life lost**

Reached from MainLoop `$E3C9` when `$A13C` gives Z (the Q key), from CheckDeath when the lives reach 0, and from StartLevel with no lives. Calls `$A73F`, then GAME OVER.

Seen in c1 (Q), controls (Q after each method), gameover and level1 (six deaths).

Witness: L1 8 (beeper48, c1, controls, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 runs of its first instruction, entered by a jump (`stage1/controls` 4, `stage1/gameover` 1, `stage1/level1` 1 and 1 more) |
| Calls | `ComposeObjects` |

### `GameOver` (`$E35D`)

**GAME OVER: print it, tune 6, wait for a key, back to the menu**

Calls `$A90F` and `$A25D`, prints GameOverBlankText `$E397`, GameOverText `$E3A3` and GameOverBlankText again with `$AA8D` at `$484B`, `$486B`, `$488B` (attributes `$49`, `$4F`, `$49`), plays tune 6, waits until no key is down and then for a press, and jumps to Menu `$E219`.

Also the end of the game: CheckGameComplete `$E406` jumps here after the ending (the ending recording shows GAME OVER after the closing text).

Witness: L1 10 (beeper48, c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage1/ending` 1) |
| Called from | `CheckGameComplete` (tail) |
| Calls | `StartTune`, `StartPressed`, `DrawDirtyCells`, `UpdateHud`, `PrintText`, `Menu` (tail) |

## mainloop

`src/game/mainloop.asm`

### `NewLife` (`$E3AF`)

**A new life: Rick alive, ammo 6, back to the zone's restart point**

Clears the death flags `$FD69` (lose a life) and `$FD68` (Rick is dying), sets RickObject's type to 1, bullets `$A976` and dynamite `$A967` to 6, calls `$AD29` (Rick to the restart point of the zone) and `$A93D` (HUD), and falls into MainLoop `$E3C9`.

Run 3 times in c1, 12 in level1 (one per life and new game), 29 in level4.

Witness: L1 323 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 320 runs of its first instruction, entered by a jump (`stage1/level4` 29, `stage2/zones/L3Z9` 24, `stage2/zones/L3Z7` 16 and 40 more) |
| Calls | `DrawHud`, `RestartScreen` |
| Reads | `$A958` (`Lives`); `$E410` (`MainLoopHalt+1`); `$E440` (`GameComplete`); `$EAAE`-`$EAAF` (`RickY`); `$FD61`-`$FD69` (`ZoneChange`, `ExitSide`, `Poking`, `PokeX` and 4 more) |
| Writes | `$A237` (`FrameTicks`); `$A958`-`$A976` (`Lives`, `DrawDynamite`, `Dynamite`, `DrawBullets` and 1 more); `$EAAC` (`RickObject`); `$FD68`-`$FD69` (`Dying`, `DeathDone`) |

### `MainLoop` (`$E3C9`)

**The main loop, one pass every 2 frames in play**

Q (`$A13C` Z) quits to Quit `$E35A`. Then UpdateObjects `$EC11`, BonusCountdown `$E466` (HL = RickY, unused), and the pause: P (`$A144` Z) waits for P to be let go, pressed again and let go (only c1 paused: 9228 / 139455 / 10050 polls).

CheckDeath: when `$FD69` is set (Rick's death has played out, `$FC47`) one life `$A958` goes; none left: Quit `$E35A`, else NewLife `$E3AF`. The ZXDB infinite-lives POKE 58356,0 turns the `DEC A` at `$E3F4` into NOP (the warp recordings use it).

CheckZone: when `$FD61` is set (Rick left the zone, `$FBD1` / `$FBE0`), `$AB93` changes the zone or level and CheckGameComplete `$E406` follows; else MainLoopHalt.

Witness: L1 43345 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,073 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 42,272 runs of its first instruction, entered by a jump (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Calls | `QuitPressed`, `PausePressed`, `CheckScreenExit`, `BonusCountdown`, `UpdateObjects` |
| Reads | `$E410` (`MainLoopHalt+1`); `$EAAE`-`$EAAF` (`RickY`); `$FD61`-`$FD69` (`ZoneChange`, `ExitSide`, `Poking`, `PokeX` and 4 more) |
| Writes | `$A237` (`FrameTicks`) |

### `CheckGameComplete` (`$E406`)

**After a zone change: the game complete, or the frame's drawing**

GameComplete `$E440` set (`$AC52`, after the closing text of the ending) goes to GameOver `$E35D` (seen in ending); else back to MainLoop `$E3C9`.

MainLoopHalt is the frame's HALT, reached from CheckZone when no zone change is pending. After it: `$A237` = 0, `$A73F`, `$A144`, `$A22A` (C = 1), `$A25D`, `$A90F`, then the vertical scroll unless `$FD68` (Rick dying): RickY `$EAAE` >= `$CC`: `$ADB9` (c1 14, level1 15); RickY < `$60`: `$ADF0` (only level2, 11 times).

Witness: L1 107 (c1, ending, ending2, l1end, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z2-L4Z6, L4Z8, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 104 runs of its first instruction, entered by a jump (`stage2/zones/L2Z5` 8, `stage2/zones/L2Z2` 7, `stage2/zones/L2Z7` 6 and 28 more) |
| Calls | `PausePressed`, `WaitFrames`, `DrawDirtyCells`, `ComposeObjects`, `UpdateHud`, `ScrollViewDown`, `ScrollViewUp`, `GameOver` (tail) |
| Reads | `$83FF`-`$8400` (`Im2Table+255`); `$A958` (`Lives`); `$E410` (`MainLoopHalt+1`); `$E440` (`GameComplete`); `$EAAE`-`$EAAF` (`RickY`); `$FD61`-`$FD69` (`ZoneChange`, `ExitSide`, `Poking`, `PokeX` and 4 more) |
| Writes | `$A237` (`FrameTicks`); `$A958`-`$A976` (`Lives`, `DrawDynamite`, `Dynamite`, `DrawBullets` and 1 more); `$EAAC` (`RickObject`); `$FD68`-`$FD69` (`Dying`, `DeathDone`) |

### `Random` (`$E441`)

**A pseudo-random byte from the frame count**

HL = RandomState + FrameCount + `$0D` + FrameCountHigh (with carry); L = A XOR L XOR D XOR E XOR H (A the caller's), stored back to RandomState; returns that byte in A, HL and DE kept.

Called by `$F4AA`; run in c1 (3) and levels 1-4 (19, 32, 13, 137). Its one user is WalkerStepX `$F4AA`: bit 0 picks the direction of a climber walking on a floor (0 right, 1 left), at x AND `$1E` = 8. RandomState is `$0000` in the image and never reset, so the seed is the frame count since the load.

Witness: L1 519 (c1, L1Z3, L1Z4, L2Z2-L2Z5, L3Z2, L3Z5, L3Z11, L4Z1-L4Z3, L4Z5, L4Z7, L4Z8, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 3 calls, 573 t-states own (0.00 %) |
| Runs (the other recordings) | 516 calls (`stage1/level4` 137, `stage2/zones/L4Z1` 50, `stage2/zones/L4Z2` 44 and 16 more) |
| Called from | `ClimberFall` |
| Reads | `$E460`-`$E465` (`RandomState`, `FrameCount`, `FrameCountHigh`) |
| Writes | `$E460`-`$E461` (`RandomState`) |

### `FrameTick` (`$E49B`)

**The 32-bit frame count, from the IM 2 handler**

FrameCount `$E462` + 1, carried into FrameCountHigh `$E464`. Called by the IM 2 handler once a frame (its counts equal the handler's: c1 14301, ending 1499).

Witness: L1 113425 (beeper48, c1, controls, emptygun, ending, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14,301 calls, 815,157 t-states own (0.08 %) |
| Runs (the other recordings) | 99,124 calls (`stage1/level3` 5,921, `stage1/level2` 5,870, `stage1/level1` 5,822 and 49 more) |
| Called from | `Im2Handler` |
| Reads | `$E462`-`$E463` (`FrameCount`) |
| Writes | `$E462`-`$E463` (`FrameCount`) |

## rick

`src/game/rick.asm`

### `DynamiteObj` (`$EC77`)

**Kind 3: the dynamite's fuse and blast**

DynFuse `$ECED` counts down by 1 a pass from the value the drop `$FAB1` gives it. While 20 or more the stick of dynamite shows FuseFrames `$ECF2`, mirrored every other pass; at 20 effect 2 (the bang, `$EC93`); below 20 the blast: BlastX `$ECEE` = x + 12, BlastY `$ECEF` = y + 10, BlastOn `$ECF1` = `$FF`, the frame BlastFrames[fuse / 4]. While the fuse is 4 or more `$F76F` tests Rick (IX = RickObject) and kills him (`$FBED`) inside the blast. At 0 the slot and BlastOn are cleared.

Run in level2 (50 passes) and level3 (300): the dynamite used there. The blast kills enemies (EnemyCommon), destroys boxes and triggers traps with flag bit 4.

Witness: L1 1523 (beeper48, L1Z1, L1Z2, L2Z1, L2Z2, L2Z6, L2Z7, L3Z2, L3Z6, L3Z11, L3Z12, L4Z x5, level2, level3).

[Animation: `DynamiteObj` at work](img/routines/DynamiteObj.gif)

| | |
| --- | --- |
| Runs | not reached in `stage2/c1g`; in the other recordings 1,523 runs of its first instruction, entered by a jump (`stage1/level3` 300, `stage2/zones/L2Z2` 196, `stage2/zones/L2Z7` 150 and 15 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `PlayEffect`, `NextObject`, `InBlast`, `KillRick` (tail) |
| Reads | `$EAE9`-`$EAEB` (`DynamiteX`); `$ECED`-`$ECFF` (`DynFuse`, `BlastX`, `BlastY`, `BlastOn` and 1 more) |
| Writes | `$EAE8`-`$EAEE` (`DynamiteObject`, `DynamiteX`); `$ECED`-`$ECF1` (`DynFuse`, `BlastX`, `BlastY`, `BlastOn`) |

### `BulletObj` (`$ED00`)

**Kind 2: Rick's bullet flies until it hits a wall or leaves**

x += BulletDx `$ED3F` (signed: `$FA75` / `$FA83` set it when Rick fires); off the left edge or at `$E8` and up the bullet goes. BulletHitX `$ED40` = x (left) or x + `$17` (right), BulletHitY `$ED41` = y + 5. `$F535` probes the map there: a wall frees the slot. The enemies, boxes and traps test BulletX / BulletY or BulletHitX / BulletHitY with `$F742`.

Run in c1 and levels 1-4 (25 to 84 passes).

Witness: L1 546 (beeper48, c1, emptygun, L1Z5, L2Z1, L2Z6, L3Z x7, L4Z3, L4Z4, L4Z8, L4Z9, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 5,183 t-states own (0.00 %) |
| Runs (the other recordings) | 521 runs of its first instruction, entered by a jump (`docs/integrate/emptygun` 150, `stage1/level3` 84, `stage1/level4` 48 and 17 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `NextObject`, `IsSolidAt` |
| Reads | `$EACB`-`$EACD` (`BulletX`, `BulletY`); `$ED3F` (`BulletDx`) |
| Writes | `$EACA`-`$EACB` (`BulletObject`, `BulletX`); `$ED40`-`$ED42` (`BulletHitX`, `BulletHitY`) |

### `RickHandler` (`$F851`)

**Object kind 1: move Rick, then choose his frame**

Handler of kind 1 (the pointer at `$EC49`), IX = Rick `$EAAC`. MoveRick `$F85D`, then the crawl flag `$FD5A` is

kept in PrevCrawl `$FD5F`, then ChooseRickFrame `$FC60` (a jump: its RET returns from here).

Witness: L1 43340 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,072 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 56,816 t-states own (0.01 %) |
| Runs (the other recordings) | 42,268 runs of its first instruction, entered by a jump (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Called from | `UpdateObjectSlot` |
| Calls | `MoveRick`, `ChooseRickFrame` (tail) |
| Reads | `$FD5A` (`Crawling`) |
| Writes | `$FD5F` (`PrevCrawl`) |

### `MoveRick` (`$F85D`)

**One frame of Rick: fall, land, walk, climb, fire, die**

IX = Rick. Clears Poking `$FD63` and FireHeld `$FD67`. Dying (`$FD68`): DeathFall `$FC16`. Reads the controls

(`$A14E`, into `$A14D`). Climbing (`$FD59`): ClimbRick `$FB14`.

Else gravity: the new Y = Y + Y velocity (`$FD56`, 8.8, the fraction in `$FD55`), the box probed there

(ProbeLow `$F56D` while crawling, ProbeBox `$F5D5` else). A solid char in the way (bits 4-7 falling, 5-7 rising):

LandRick `$F95D`. Else Rick is airborne (`$FD5B` = `$FF`): deadly char: KillRick `$FBED`; Y stored; a ladder with up

or down held: climbing starts; the Y velocity grows by `$80` up to `$0800`; then WalkRick `$F903`.

Witness: L1 43340 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,072 calls, 428,664 t-states own (0.04 %) |
| Runs (the other recordings) | 42,268 calls (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Called from | `RickHandler` |
| Calls | `ReadInput`, `ProbeLow`, `ProbeBox`, `WalkRick` (falls into), `LandRick` (tail), `ClimbRick` (tail), `KillRick` (tail), `DeathFall` (tail) |
| Reads | `$A14D` (`InputBits`); `$A967`-`$A976` (`Dynamite`, `DrawBullets`, `Bullets`); `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$EACA` (`BulletObject`); `$EAE8` (`DynamiteObject`); `$F6A7`-`$F6A8` (`ProbeLowResult`, `ProbeResult`); 1 more ranges |
| Writes | `$A967`-`$A976` (`Dynamite`, `DrawBullets`, `Bullets`); `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$EACA`-`$EAD0` (`BulletObject`, `BulletX`, `BulletY`); `$EAE8`-`$EAEB` (`DynamiteObject`, `DynamiteX`); `$ECED` (`DynFuse`); `$ED3F` (`BulletDx`); 1 more ranges |

### `WalkRick` (`$F903`)

**Rick's horizontal step: 2 pixels left or right, or the zone edge**

Part of MoveRick `$F85D` (jumped to from MoveRick, LandRick `$F95D`, NoFire `$FAC3`, SetCrawl `$FB0E`). Neither left

nor right: AnimStep `$FD5C` = `$FF` (standing). Left: Facing `$FD58` = 1, X - 2, below 0: ExitLeft `$FBCF`. Right:

Facing = 0, X + 2, at `$E8` or more: ExitRight `$FBDE`. The box at the new X is probed (ProbeLow `$F56D` when

crawling, ProbeBox `$F5D5` else): bits 4-6 block; else X is stored, and a deadly char kills (KillRick `$FBED`).

Witness: L1 31458 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 919 calls, 224,209 t-states own (0.02 %) |
| Runs (the other recordings) | 22,044 calls (`stage1/level4` 878, `stage2/zones/L4Z6` 873, `stage2/zones/L2Z1` 860 and 40 more) |
| Called from | `MoveRick` (falls into), `LandRick` (tail), `NoFire` (tail) |
| Calls | `ProbeLow`, `ProbeBox`, `ExitLeft` (tail), `ExitRight` (tail), `KillRick` (tail) |
| Reads | `$A14D` (`InputBits`); `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$F6A8` (`ProbeResult`); `$FD5A` (`Crawling`) |
| Writes | `$EAAD` (`RickX`); `$FD58`-`$FD5C` (`Facing`, `Climbing`, `Crawling`, `Airborne` and 1 more) |

### `LandRick` (`$F95D`)

**Rick's box met a solid char: a ceiling bump, or the floor and the fire and jump controls**

Part of MoveRick `$F85D`. Rising (`$FD57` negative): a ceiling; Y to its row, the velocity 0, effect 6, WalkRick.

Falling: Y to the row + 3. A spring (bit 5) hit at a speed of 2 or more bounces back (up held: velocity `$F800`, a

big jump; else 254 - velocity); WalkRick. On the floor (velocity `$0100`): fire not held, or PrevCrawl `$FD5F`:

NoFire `$FAC3`. Fire with left or right: the stick poke (Poking `$FD63`, the point at PokeX `$FD64` / PokeY

`$FD65` = X + `$17` facing right or X facing left, Y + 14; effect 3 once per press, PokeLatch `$FD60`). Fire alone

or with up or down: FireNoStick `$FA1E`.

Evidence: the ceiling bump (`$F969`) ran in c1, controls and level1-level4. The spring bounce (`$F9AC`, `$F9B2`) ran in L2Z4 only (6 and 17). The stick poke (`$F9DC`) ran in controls, level1-level3 (level3 175).

Witness: L1 22412 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 610 calls, 126,168 t-states own (0.01 %) |
| Runs (the other recordings) | 15,352 calls (`stage2/zones/L4Z6` 774, `stage2/zones/L2Z1` 709, `stage2/zones/L2Z2` 649 and 40 more) |
| Called from | `MoveRick` (tail) |
| Calls | `PlayEffect`, `WalkRick` (tail), `FireNoStick` (tail), `NoFire` (tail) |
| Reads | `$A14D` (`InputBits`); `$A976` (`Bullets`); `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$EACA` (`BulletObject`); `$FD56`-`$FD60` (`YVelocity`, `Facing`, `Climbing`, `Crawling` and 5 more) |
| Writes | `$A976` (`Bullets`); `$EAAE` (`RickY`); `$EACA`-`$EAD0` (`BulletObject`, `BulletX`, `BulletY`); `$ED3F` (`BulletDx`); `$FD55`-`$FD67` (`YFraction`, `YVelocity`, `Facing`, `Climbing` and 12 more) |

### `FireNoStick` (`$FA1E`)

**Fire without left or right: clear the poke latch**

Part of LandRick `$F95D`. A = 0 into PokeLatch, then FireClearPokeLatch `$FA1F`.

Witness: L1 464 (beeper48, c1, emptygun, L1Z1, L1Z2, L1Z5, L2Z1, L2Z2, L2Z6, L2Z7, L3Z x7, L4Z2-L4Z5, L4Z7-L4Z9, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 34 calls, 5,042 t-states own (0.00 %) |
| Runs (the other recordings) | 141 calls (`stage1/level4` 34, `docs/integrate/emptygun` 32, `stage2/zones/L2Z1` 10 and 16 more) |
| Called from | `LandRick` (tail) |
| Reads | `$A967`-`$A976` (`Dynamite`, `DrawBullets`, `Bullets`); `$EAAD`-`$EAAE` (`RickX`, `RickY`); `$EACA` (`BulletObject`); `$EAE8` (`DynamiteObject`); `$FD58`-`$FD5E` (`Facing`, `Climbing`, `Crawling`, `Airborne` and 2 more) |
| Writes | `$A967`-`$A976` (`Dynamite`, `DrawBullets`, `Bullets`); `$EACA`-`$EAD0` (`BulletObject`, `BulletX`, `BulletY`); `$EAE8`-`$EAEB` (`DynamiteObject`, `DynamiteX`); `$ECED` (`DynFuse`); `$ED3F` (`BulletDx`); `$FD5C`-`$FD67` (`AnimStep`, `FireLatch`, `PrevCrawl`, `PokeLatch` and 6 more) |

### `FireClearPokeLatch` (`$FA1F`)

**Fire with up shoots, with down drops dynamite**

Part of LandRick `$F95D`. Up (bits 3-2 = 0-1): FireHeld `$FD67` = `$FF`; once per press (FireLatch `$FD5E`), and

only with no bullet out (`$EACA` = 0): no bullets left (`$A976` = 0) plays effect 1; else one bullet less, effect

0, and the bullet object starts: kind 2, Y = Rick Y + 6, X = Rick X, frame `$85F9`, X velocity `$ED3F` = 8 (`$F8`

facing left), `$EAD0` = 0 / 1 (mirror). Not up: FireNotUp `$FA8C`.

Evidence: shots (`$FA4B`) in c1 and level1-level4; the "no bullets" sound (`$FA45`) in emptygun only (frames 500 and 580, after six shots).

Witness: L1 464 (beeper48, c1, emptygun, L1Z1, L1Z2, L1Z5, L2Z1, L2Z2, L2Z6, L2Z7, L3Z x7, L4Z2-L4Z5, L4Z7-L4Z9, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 34 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 430 runs of its first instruction, entered by a jump (`stage1/level3` 161, `stage1/level2` 61, `stage1/level1` 50 and 24 more) |
| Calls | `PlayEffect`, `FireNotUp` (tail) |

### `FireNotUp` (`$FA8C`)

**Fire without up: release the fire latch; with down, drop a dynamite stick**

Part of LandRick `$F95D`. FireLatch `$FD5E` = 0, AnimStep `$FD5C` = 0. Down (bits 3-2 = 1-0): with no dynamite

out (`$EAE8` = 0) and sticks left (`$A967`): one less, the dynamite object starts (kind 3, fuse `$ECED` = `$32`

frames, X `$EAE9` and Y `$EAEA` = Rick's).

Evidence: a dynamite stick dropped (`$FAA6`) in level2 (1) and level3 (6).

Witness: L1 368 (beeper48, c1, emptygun, L1Z1, L1Z2, L2Z1, L2Z2, L2Z6, L2Z7, L3Z2, L3Z6, L3Z11, L3Z12, L4Z x5, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 27 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 27 calls (`stage2/zones/L2Z7` 7, `stage2/zones/L2Z2` 6, `stage2/zones/L4Z2` 5 and 4 more) |
| Called from | `FireClearPokeLatch` (tail) |
| Reads | `$A967` (`Dynamite`); `$EAAD`-`$EAAE` (`RickX`, `RickY`); `$EAE8` (`DynamiteObject`) |
| Writes | `$A967` (`Dynamite`); `$EAE8`-`$EAEB` (`DynamiteObject`, `DynamiteX`); `$ECED` (`DynFuse`); `$FD5C`-`$FD5E` (`AnimStep`, `FireLatch`) |

### `NoFire` (`$FAC3`)

**On the floor without fire: jump, climb, crawl or walk**

Part of LandRick `$F95D`. Up held: on a ladder (bit 1) climbing starts (`$FD59`); else a jump (velocity `$FA80`,

effect 6) and WalkRick. Down held: no floor under the middle (bit 7 clear): Rick crawls (SetCrawl); on a ladder

top (bits 0-1) with X AND `$1F` < `$0A`, X snaps to the ladder (X AND `$F0` + 4) and climbing starts; else crawl.

Neither: WalkRick.

Evidence: jumps (`$FAD3`) in every game build; crawls (`$FB0C`) in level1-level4; the ladder top snap (`$FAFC`) in level1 and level3.

Witness: L1 21348 (beeper48, c1, controls, emptygun, ending2, gameover, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 574 calls, 22,317 t-states own (0.00 %) |
| Runs (the other recordings) | 14,911 calls (`stage2/zones/L4Z6` 762, `stage2/zones/L2Z1` 686, `stage2/zones/L2Z2` 641 and 40 more) |
| Called from | `LandRick` (tail) |
| Calls | `PlayEffect`, `WalkRick` (tail) |
| Reads | `$EAAD` (`RickX`) |
| Writes | `$EAAD` (`RickX`); `$FD56`-`$FD5A` (`YVelocity`, `Facing`, `Climbing`, `Crawling`) |

### `ClimbRick` (`$FB14`)

**One frame on a ladder**

Part of MoveRick `$F85D`. No direction: AnimStep `$FD5C` = 0, stay. Up or down: Y - 2 or + 2, probed (ProbeBox

`$F5D5`). Free: Y moves (ClimbMove `$FB5E`). Blocked going down: climbing stops. Blocked going up: through a

platform (bit 4) it moves, else only sideways (ClimbSideways `$FB82`). After the move a deadly char kills; a ladder

or floor (bits 1, 7) keeps climbing; else Rick leaves the ladder, velocity `$0100` (down) or `$FD00` (up: a hop).

Evidence: climbing ran in level1-level4; a blocked climb up (`$FB58`) in level2; leaving at the end (`$FB6F`) in level2 and level3.

Witness: L1 1197 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z9, L3Z11, L3Z12, L4Z3, L4Z4, L4Z7, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 55 calls, 19,082 t-states own (0.00 %) |
| Runs (the other recordings) | 656 calls (`stage2/zones/L3Z8` 216, `stage2/zones/L2Z2` 113, `stage2/zones/L2Z3` 82 and 8 more) |
| Called from | `MoveRick` (tail) |
| Calls | `ProbeBox` |
| Reads | `$A14D` (`InputBits`); `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$F6A8` (`ProbeResult`) |
| Writes | `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$FD56`-`$FD5C` (`YVelocity`, `Facing`, `Climbing`, `Crawling` and 2 more) |

### `ClimbMove` (`$FB5E`)

**Store the new Y**

Part of ClimbRick `$FB14`.

Witness: L1 778 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z9, L3Z11, L3Z12, L4Z3, L4Z4, L4Z7, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 727 runs of its first instruction, entered by a jump (`stage1/level2` 221, `stage2/zones/L3Z8` 98, `stage1/level3` 78 and 11 more) |

### `ClimbSideways` (`$FB82`)

**On a ladder: left or right by 2**

Part of ClimbRick `$FB14`. As WalkRick, with the walls bits 5-6; the zone edges give ExitLeft `$FBCF` /

ExitRight `$FBDE`. Off the ladder (no bit 1 or 7): climbing stops, and with up held velocity `$FD00` (a hop).

Witness: L1 1004 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z9, L3Z11, L3Z12, L4Z3, L4Z4, L4Z7, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 950 runs of its first instruction, entered by a jump (`stage1/level2` 280, `stage2/zones/L3Z8` 180, `stage2/zones/L2Z2` 99 and 11 more) |

### `ClimbRight` (`$FB9A`)

**ClimbRight**

Part of ClimbSideways `$FB82`.

Witness: L1 236 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z12, L4Z3, L4Z4, L4Z7, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 231 runs of its first instruction, entered by a jump (`stage2/zones/L3Z8` 83, `stage2/zones/L2Z3` 56, `stage1/level2` 38 and 9 more) |

### `ClimbSideProbe` (`$FBA1`)

**ClimbSideProbe**

Part of ClimbSideways `$FB82`.

Witness: L1 297 (c1, L1Z5, L2Z2, L2Z3, L3Z8, L3Z12, L4Z3, L4Z4, L4Z7, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 287 runs of its first instruction, entered by a jump (`stage2/zones/L3Z8` 85, `stage1/level2` 64, `stage2/zones/L2Z3` 56 and 9 more) |
| Calls | `ProbeBox` |

### `ExitLeft` (`$FBCF`)

**Rick left the zone on the left**

ZoneChange `$FD61` = `$FF`, ExitSide `$FD62` = 0, X = `$E4` (the right edge of the next zone). The game loop

(`$E3FD`, `$ABA6`) moves to the next zone.

Evidence: in c1 and level1, the zone exits a recording reached.

Witness: L1 54 (c1, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z2-L4Z6, L4Z8, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1 call, 69 t-states own (0.00 %) |
| Runs (the other recordings) | 51 calls (`stage2/zones/L2Z2` 4, `stage2/zones/L2Z5` 4, `stage2/zones/L2Z7` 3 and 24 more) |
| Called from | `WalkRick` (tail) |
| Writes | `$EAAD` (`RickX`); `$FD61`-`$FD62` (`ZoneChange`, `ExitSide`) |

### `ExitRight` (`$FBDE`)

**Rick left the zone on the right**

ZoneChange `$FD61` = `$FF`, ExitSide `$FD62` = 1, X = 2.

Witness: L1 51 (c1, ending2, L1Z2-L1Z4, L1Z6, L2Z2, L2Z4-L2Z7, L3Z2-L3Z12, L4Z x5, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 2 calls, 138 t-states own (0.00 %) |
| Runs (the other recordings) | 46 calls (`stage2/zones/L2Z5` 4, `stage2/zones/L2Z2` 3, `stage2/zones/L2Z7` 3 and 23 more) |
| Called from | `WalkRick` (tail) |
| Writes | `$EAAD` (`RickX`); `$FD61`-`$FD62` (`ZoneChange`, `ExitSide`) |

### `KillRick` (`$FBED`)

**Rick dies (once)**

Already dying (`$FD68`): return. Else KillRickNow `$FBF2`. Called for a deadly char and by the objects that kill

Rick.

Witness: L1 400 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 2 calls, 304 t-states own (0.00 %) |
| Runs (the other recordings) | 398 calls (`stage1/level4` 29, `stage2/zones/L3Z9` 25, `stage2/zones/L2Z2` 22 and 40 more) |
| Called from | `DynamiteObj` (tail), `TrapObj` (tail), `EnemyFall` (tail), `ClimberObj`, `MoveRick` (tail), `WalkRick` (tail) |
| Calls | `NextObject` |
| Reads | `$EAAD` (`RickX`); `$FD68` (`Dying`) |
| Writes | `$FD56`-`$FD57` (`YVelocity`); `$FD68`-`$FD6A` (`Dying`, `DeathDone`, `DeathDrift`) |

### `KillRickNow` (`$FBF2`)

**Effect 11, Dying, a hop up, the drift towards the middle of the screen**

Part of KillRick `$FBED`. Effect 11, Dying `$FD68` = `$FF`, Y velocity `$FC00`, DeathDrift `$FD6A` = 3 (Rick X <

`$80`) or `$FD` (-3).

Evidence: deaths in every game build (level4 29).

Witness: L1 323 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

[Animation: `KillRickNow` at work](img/routines/KillRickNow.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 321 runs of its first instruction, entered by a jump (`stage1/level4` 29, `stage2/zones/L3Z9` 25, `stage2/zones/L3Z7` 16 and 40 more) |
| Calls | `PlayEffect`, `NextObject` |

### `DeathFall` (`$FC16`)

**The dying Rick: drift sideways, fall with gravity, off the bottom**

Part of MoveRick `$F85D`. X += DeathDrift `$FD6A`; Y += velocity, no collisions; past the bottom (the new Y's high

byte nonzero) the object is freed and DeathDone `$FD69` = `$FF` (read at `$E3EB`: a life lost). Else the velocity

grows by `$80`.

Evidence: DeathDone set (`$FC41`) in c1 2, controls 3, gameover 6, level1 11, level2 3, level3 5, level4 28 times.

Witness: L1 9927 (beeper48, c1, controls, gameover, l1end, spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 61 calls, 19,250 t-states own (0.00 %) |
| Runs (the other recordings) | 9,866 calls (`stage1/level4` 928, `stage2/zones/L3Z9` 768, `stage2/zones/L3Z1` 457 and 41 more) |
| Called from | `MoveRick` (tail) |
| Reads | `$EAAD`-`$EAAF` (`RickX`, `RickY`); `$FD55`-`$FD57` (`YFraction`, `YVelocity`); `$FD6A` (`DeathDrift`) |
| Writes | `$EAAC`-`$EAAF` (`RickObject`, `RickX`, `RickY`); `$FD55`-`$FD57` (`YFraction`, `YVelocity`); `$FD69` (`DeathDone`) |

### `ChooseRickFrame` (`$FC60`)

**Rick's sprite frame and mirror for this frame, and the step sounds**

Part of RickHandler `$F851`. The mirror +6 = Facing `$FD58`. Dying: frame `$857B`, the mirror flips every 4 frames

(AnimStep `$FD5C` counts). Poking: `$87F1`. Crawling: CrawlFrames `$FD75` by AnimStep 0-7 / 2, effect 4 at steps 1

and 4. Climbing: `$886F`, the mirror from (X XOR Y) AND 4 (the climbing wiggle), effect 4 every 2 moves. Airborne:

`$84FD`. Firing: `$8773`. Else walking: WalkFrames `$FD6D` by AnimStep 0-7 / 2 (standing, AnimStep = `$FF`, gives

0), effect 4 at steps 2 and 6.

Witness: L1 43340 (beeper48, c1, controls, emptygun, ending2, gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 1,072 calls, 355,202 t-states own (0.03 %) |
| Runs (the other recordings) | 42,268 calls (`stage1/level3` 2,927, `stage1/level2` 2,845, `stage1/level1` 2,152 and 48 more) |
| Called from | `RickHandler` (tail) |
| Calls | `PlayEffect`, `NextObject` |
| Reads | `$EAAD`-`$EAB2` (`RickX`, `RickY`, `RickMirror`); `$FD58`-`$FD7C` (`Facing`, `WalkFrames`) |
| Writes | `$EAB0`-`$EAB2` (`RickY+2`, `RickMirror`); `$FD5C` (`AnimStep`) |


## The BASIC "Rick" (`src/tape/basic.json`)

Rick Dangerous, Firebird 1989: TZX block 2, the BASIC program "Rick" (181 bytes at PROG `$5CCB`, LINE 10): it clears
to 50000, prints the title and loads and runs Rick1 at `$CD00`. Its entries are `src/tape/<module>.asm`, written
from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic.json`; the recordings: `work/stage2/c1g` (c1:
power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D`
(frame 19 010, T 70 483)), and `work/stage1/c1` (`$5CCB`-`$5D7F`).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](11-data-reference.md#the-basic-rick-basic) | `$5CCB`-`$5D7F` | 0 of 6 |


## Rick1, the first loader stage (`src/loader/rick1.json`)

Rick Dangerous, Firebird 1989 (Bleepload): TZX block 4, Rick1: the first loader stage, which the ROM loads at
`$CD00` (512 bytes). Its entries are `src/loader/<module>.asm`, written from `src/loader/rick1.ann` by
`kit/mkgame.py --part src/loader/rick1.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape at
ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`rick1`](#rick1-the-first-loader-stage-rick1) | `$CD00`-`$CEFF` | 20 of 26 |

### Rick1, the first loader stage: rick1

`src/loader/rick1-module.asm`

#### `Rick1Start` (`$CD00`)

**Rick1's entry: open the screen, print the colours and "Searching 00", then load group 1**

Entered by the BASIC's RANDOMIZE USR 52480. Opens stream 2 (ChanOpen), sets DfSz to 0, prints INK 9 PAPER 8 (PrintInline: contrasting ink, transparent paper), sets D, the block wanted, to 0, prints "Searching 00" (ShowSearching) and sets NextFiller to 8, the first block's filler length.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 1 call, 63 t-states own (0.00 %) |
| Calls | `PrintInline` |
| Writes | `$5C6B` (`DfSz`) |

#### `Rick1Begin` (`$CD11`)

**Rick1Start after its string: D = 0, "Searching 00", the first block's filler length**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 1 call, 44 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `NextBlock` (falls into), `ShowSearching` |
| Writes | `$FF15` (`NextFiller`) |

#### `NextBlock` (`$CD1B`)

**Load the next block of group 1, check it, store it and jump into its tail**

LoadBlock, then the marker: a block other than `$64` is skipped. A number other than D, or a checksum CheckBlock does not match: BadBlock, and the next block. A good block's payload is copied (StoreBlock) and "Loading NN" printed (ShowLoading).

Then the tail: HL steps over the N filler bytes to the block's last byte, the checksum, whose bits 0-2 + 1 are the next block's N (NextFiller); D + 1, and `JP (HL)` into the block's `JP` after the filler: `JP NextBlock` for blocks 0-45, `JP $5D00` (the second stage) for block 46. The filler's bytes are never run.

Witness: L1 47 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 47 calls, 15,778 t-states own (0.00 %) |
| Called from | `Rick1Begin` (falls into) |
| Calls | `StoreBlock`, `LoadBlock`, `CheckBlock`, `ShowLoading` |
| Reads | `$FE00` (`BlockBuffer`); `$FF01`-`$FF10` (`BlockNumber`, `BlockDest`, `BlockFiller`) |
| Writes | `$FF15` (`NextFiller`) |

#### `StoreBlock` (`$CD59`)

**Copy the block's 256-byte payload to its address; leave IX = the caller's return address**

LDIRs BlockPayload to the address in BlockDest. The payload is copied as it comes: group 1's cipher is undone later by the second stage. Last it pops the return address into IX and pushes it back, so IX = `$CD3E`, inside Rick1: the second stage keeps that IX and makes the key from Rick1's page (`$5D12`).

Witness: L1 47 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 47 calls, 260,583 t-states own (0.01 %) |
| Called from | `NextBlock` |
| Reads | `$FE01`-`$FF03` (`BlockPayload`, `BlockNumber`, `BlockDest`) |
| Writes | `$5D00`-`$5DE6`; `$5DFF`; `$C900`-`$C9FF`; `$CF00`-`$FBFF` |

#### `LoadBlock` (`$CD6E`)

**Read one Bleepload block from the tape into BlockBuffer: the ROM's LD-BYTES, changed**

DE = BlockLength (`$109` + N), IX = BlockBuffer, A' = `$FF` with carry set: load. C keeps the EAR level and the border colour: the leader stripes red and yellow (EdgeOne flips C with `XOR $24` from `$02`), the data blue and cyan (C `XOR 3` after the sync).

Against the ROM's LD-BYTES (`$0556`): the leader needs only 100 pulses (`LD H,$64` where the ROM counts 256); the flag byte is read but not checked (a NOP where the ROM has RET NZ); verify mode hangs (`JR NC,$`); the end has no parity test: EI, the registers back and RET. Its edge routines EdgeTwo and EdgeOne keep the ROM's timing constants and drop the BREAK test.

Witness: L1 48 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 48 calls, 8,409,018 t-states own (0.36 %) |
| Called from | `NextBlock` |
| Calls | `EdgeTwo`, `EdgeOne`, `BlockLength` |
| Writes | `$FE00`-`$FF10` (`BlockBuffer`, `BlockPayload`, `BlockNumber`, `BlockDest` and 1 more) |
| Ports in | `$0FFE` |
| Ports out | `$0FFE` |

#### `EdgeTwo` (`$CDFC`)

**Time two edges: the ROM's LD-EDGE-2**

B = the time counter. Carry set: both edges came in time; reset: time out.

Witness: L1 109221 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 109,221 calls, 2,402,862 t-states own (0.10 %) |
| Called from | `LoadBlock` |
| Calls | `EdgeOne` (falls into) |

#### `EdgeOne` (`$CE00`)

**Time one edge and flip the border colour: the ROM's LD-EDGE-1 without the BREAK test**

B = the time counter, +1 per pass of the sampling loop; C = the last level and the border colour. The ROM's `RET NC` after the `RRA` is a NOP, so BREAK does not stop the load. Each edge flips C's bits 2 and 5 (`XOR $24`) and writes the colour to the border.

Witness: L1 224652 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 224,652 calls, 294,552,267 t-states own (12.44 %) |
| Called from | `LoadBlock`, `EdgeTwo` (falls into) |
| Ports in | `$7FFE` |
| Ports out | `$09FE`, `$0AFE`, `$0DFE`, `$0EFE` |

#### `BlockLength` (`$CE1F`)

**DE = `$109` + NextFiller: the length of the next block**

Witness: L1 96 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 96 calls, 12,280 t-states own (0.00 %) |
| Called from | `LoadBlock`, `CheckBlock` |
| Reads | `$FF15` (`NextFiller`) |

#### `CheckBlock` (`$CE2A`)

**A = the XOR of the block's bytes but its last; HL = that last byte, for the caller's CP (HL)**

Witness: L1 48 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 48 calls, 608,766 t-states own (0.03 %) |
| Called from | `NextBlock` |
| Calls | `BlockLength` |
| Reads | `$FE00`-`$FF0F` (`BlockBuffer`, `BlockPayload`, `BlockNumber`, `BlockDest` and 1 more) |

#### `PrintBlockNumber` (`$CE3D`)

**Print BlockNumber in two hex digits (and add 1 to it in the buffer)**

Witness: L1 47 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 47 calls, 3,908 t-states own (0.00 %) |
| Called from | `ShowLoadingNumber` (tail), `ShowSearchingNumber` (tail) |
| Calls | `PrintHexDigit` (falls into) |
| Reads | `$FF01` (`BlockNumber`) |
| Writes | `$FF01` (`BlockNumber`) |

#### `PrintHexDigit` (`$CE4B`)

**Print A's low nibble as a hex digit (RST `$10`)**

Witness: L1 96 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 96 calls, 5,218 t-states own (0.00 %) |
| Called from | `PrintBlockNumber` (falls into) |

#### `ShowLoading` (`$CE57`)

**Clear row 10 (AT 10,10, twelve spaces), print "Loading NN" at AT 7,10**

NN is the block's number (PrintBlockNumber).

Witness: L1 47 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 47 calls, 1,833 t-states own (0.00 %) |
| Called from | `NextBlock` |
| Calls | `PrintInline` |

#### `ShowLoadingNumber` (`$CE79`)

**ShowLoading after its string: the block's number**

Witness: L1 47 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 47 calls, 1,410 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintBlockNumber` (tail) |

#### `BadBlock` (`$CE7E`)

**A block not wanted, or a bad checksum: print "Block ? NN" at AT 7,10**

A = the block's number (the XOR CheckBlock made, when the checksum failed), kept in E. After the string, BadBlockAhead prints the number and chooses the hint. Not run in c1: the TZX plays every block in order.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `BadBlockAhead` (`$CE92`)

**BadBlock's rest: the number, then "Rewind to NN" for a block past the one wanted, else "Searching NN"**

E (the block found) >= D (the block wanted): ShowRewind; else on into ShowSearching. Known only from the code: no recording loaded a block out of order.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowSearching` (`$CE9B`)

**Print "Searching NN" at AT 10,10: NN = D, the block wanted**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 1 call, 28 t-states own (0.00 %) |
| Called from | `Rick1Begin` |
| Calls | `PrintInline` |

#### `ShowSearchingNumber` (`$CEAD`)

**ShowSearching after its string: D, the block wanted**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 1 call, 24 t-states own (0.00 %) |
| Called from | `PrintInline` |
| Calls | `PrintBlockNumber` (tail) |

#### `ShowRewind` (`$CEB2`)

**Print "Rewind to NN" at AT 10,10: NN = D, the block wanted**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowRewindNumber` (`$CEC3`)

**ShowRewind after its string: D, the block wanted**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `PrintInline` (`$CEC8`)

**Print the bytes after the CALL up to `$FF` (RST `$10`) and return after them**

Witness: L1 49 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 49 calls, 69,750 t-states own (0.00 %) |
| Called from | `Rick1Start`, `ShowLoading`, `ShowSearching` |
| Calls | `Rick1Begin`, `ShowLoadingNumber`, `ShowSearchingNumber` |
| Reads | `$CD0C`-`$CD10` (`ColoursText`); `$CE5C`-`$CE78` (`LoadingText`); `$CE9F`-`$CEAC` (`SearchingText`) |


## The second loader stage (`src/loader/stage2.json`)

Rick Dangerous, Firebird 1989 (Bleepload): group 1's block 46: the second loader stage at `$5D00` (256 bytes,
deciphered, as the tape holds it). Its entries are `src/loader/<module>.asm`, written from `src/loader/stage2.ann`
by `kit/mkgame.py --part src/loader/stage2.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape
at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`stage2`](#the-second-loader-stage-stage2) | `$5D00`-`$5DFF` | 1 of 2 |

### The second loader stage: stage2

`src/loader/stage2-module.asm`

#### `Stage2Start` (`$5D00`)

**The second stage's entry: load and check group 1's last block, without storing it**

Entered from block 46's tail (`JP $5D00`) with IX = `$CD3E`, the address StoreBlock left (pushed for MakeKey). Loads block 47 by LoadBlock and checks it (CheckBlock; a bad one: BadBlock and again). The block is never stored: its payload and its tail's `JP $5D94` are decoys, and only KeyPagePtr, KeyedFrom and KeyedEnd in the buffer are read.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |


## LoadGroup, the loader of groups 2 and 3 (`src/loader/loadgroup.json`)

Rick Dangerous, Firebird 1989 (Bleepload): group 1's blocks 44-45: LoadGroup at `$FA00`, the loader of groups 2 and
3 (512 bytes, deciphered). Its entries are `src/loader/<module>.asm`, written from `src/loader/loadgroup.ann` by
`kit/mkgame.py --part src/loader/loadgroup.json`; the recordings: `work/stage1/c1` (c1: power-on, the original tape
at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`loadgroup`](#loadgroup-the-loader-of-groups-2-and-3-loadgroup) | `$FA00`-`$FBFF` | 25 of 35 |

### LoadGroup, the loader of groups 2 and 3: loadgroup

`src/loader/loadgroup-module.asm`

#### `LoadGroup` (`$FA00`)

**Load a group of blocks (A = its marker) to their addresses; BC, DE = AT positions of the two message lines**

A goes to GroupMarker, BC to StatusAt (C the row, B the column), DE to ErrorAt. D, the block wanted, = 0. Opens stream 2, DfSz = 0, prints INK 9 PAPER 8, clears the status line and prints "Searching 00" on the error line.

Then per block: LoadGroupBlock, the marker (another is skipped), the number (not D: GroupBadBlock), CheckPage (bad: GroupBadBlock); a good block is deciphered and stored (StorePage), "Loading NN" printed (ShowGroupLoading), D + 1. After the block whose address' high byte is GroupEnd - 1: DfSz = 2, and GroupGo, 0 in both groups, returns.

Group 2: 140 blocks, the lines at rows 19 and 20 under the picture. Group 3: 6 blocks on the cleared screen, rows 10 and 13.

Witness: L1 2 (c1).

[Animation: `LoadGroup` at work](img/routines/LoadGroup.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 2 calls, 254 t-states own (0.00 %) |
| Calls | `GroupPrintInline` |
| Writes | `$5C6B` (`DfSz`); `$FBE7`-`$FBF3` (`StatusAt`, `AtStatusEnd`, `AtError`, `ErrorAtText` and 2 more) |

#### `LoadGroupBegin` (`$FA1F`)

**LoadGroup after its string: clear the status line, "Searching 00", the first block**

Witness: L1 36 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `StorePage` (`$FA6C`)

**Copy the payload to its address, each byte XOR the address' high byte: the groups' cipher**

Group 3's pages are `$40-$45`, the screen's top third: its blocks show on the screen, deciphered, as they load.

Witness: L1 146 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 146 calls, 1,821 t-states own (0.00 %) |

#### `LoadGroupBlock` (`$FA85`)

**Read one block into BlockBuffer: Rick1's LoadBlock with DE = `$109`**

The ROM's LD-BYTES with a 100-pulse leader and no flag, BREAK or parity test, as Rick1's LoadBlock (`$CD6E`).

Witness: L1 146 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 146 calls, 1,672,858 t-states own (0.07 %) |
| Calls | `GroupEdgeOne` |

#### `GroupEdgeTwo` (`$FB0E`)

**Time two edges: the ROM's LD-EDGE-2**

Witness: L1 327022 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GroupEdgeOne` (`$FB12`)

**Time one edge and flip the border colour: LD-EDGE-1 without the BREAK test**

Witness: L1 677895 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 677,895 calls, 4,745,265 t-states own (0.20 %) |
| Called from | `LoadGroupBlock` |

#### `GroupSpareRet` (`$FB31`)

**A lone RET after GroupEdgeOne**

Known only from the code: no CALL or JP reaches it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CheckPage` (`$FB32`)

**A = the XOR of `$FE01-$FF07` (the payload and the fields); HL = `$FF08`, the block's check byte**

Witness: L1 198 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GroupPrintNumber` (`$FB45`)

**Print BlockNumber in two hex digits (and add 1 to it in the buffer)**

Witness: L1 198 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | run into, not called, 1,723 t-states own (0.00 %) |

#### `GroupPrintHexDigit` (`$FB53`)

**Print A's low nibble as a hex digit**

Witness: L1 297 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowGroupLoading` (`$FB5F`)

**Clear the error line, print "Loading NN" on the status line**

Witness: L1 146 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 146 calls, 3,575 t-states own (0.00 %) |

#### `ShowGroupLoadingNumber` (`$FB78`)

**ShowGroupLoading after its string: the block's number**

Witness: L1 146 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 146 calls, 5,194 t-states own (0.00 %) |

#### `GroupBadBlock` (`$FB7C`)

**A block not wanted, or a bad check byte: "Block ? NN" on the status line**

A = the block's number (the XOR CheckPage made, when the check failed), kept in E. Not run in c1.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GroupBadBlockAhead` (`$FB90`)

**GroupBadBlock's rest: the number, then "Rewind to NN" (E >= D) or "Searching NN"**

Known only from the code: no recording loaded a block out of order.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowGroupSearching` (`$FB99`)

**Print "Searching NN" on the error line: NN = D, the block wanted**

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 2 calls, 27 t-states own (0.00 %) |

#### `ShowGroupSearchingNumber` (`$FBAB`)

**ShowGroupSearching after its string: D, the block wanted**

Witness: L1 12 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowGroupRewind` (`$FBB0`)

**Print "Rewind to NN" on the error line: NN = D, the block wanted**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `ShowGroupRewindNumber` (`$FBC1`)

**ShowGroupRewind after its string: D, the block wanted**

Known only from the code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `GroupPrintInline` (`$FBC6`)

**Print the bytes after the CALL up to `$FF` and return after them**

Witness: L1 594 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 594 calls, 7,088 t-states own (0.00 %) |
| Called from | `LoadGroup`, `ClearMessage`, `AtError` |

#### `ClearMessage` (`$FBD2`)

**Print twelve spaces (at the line AtStatus or AtError set)**

Witness: L1 148 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 148 calls, 3,001 t-states own (0.00 %) |
| Calls | `GroupPrintInline` |

#### `ClearMessageEnd` (`$FBE2`)

**ClearMessage after its string: return**

Witness: L1 148 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 148 calls, 1,642 t-states own (0.00 %) |

#### `AtStatus` (`$FBE3`)

**Print AT row, column of the status line: StatusAt, set from BC by LoadGroup**

Witness: L1 150 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `AtStatusEnd` (`$FBEA`)

**AtStatus after its string: return**

Witness: L1 148 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 148 calls, 1,852 t-states own (0.00 %) |

#### `AtError` (`$FBEB`)

**Print AT row, column of the error line: ErrorAt, set from DE by LoadGroup**

Witness: L1 148 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the whole load (the loader runs in frames 0-19 010)) | 148 calls, 2,722 t-states own (0.00 %) |
| Calls | `GroupPrintInline` |

#### `AtErrorEnd` (`$FBF2`)

**AtError after its string: return**

Witness: L1 150 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |


## The AY player and tunes (RAM 1) (`src/music/music.json`)

Rick Dangerous, Firebird 1989: the AY music and effects player and its tunes, `$0DA4` bytes, assembled at `$C000` in
RAM 1 where the entry's CopyMusicToRam1 puts them on a 128K; the game image holds the same bytes at `$5E00`. Its
entries are `src/music/<module>.asm`, written from `src/music/music.ann` by `kit/mkgame.py --part
src/music/music.json`; the recordings: `work/stage2/c1g` (c1: power-on, the original tape at ROM speed on the 128K,
the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)), and `work/stage1/controls`,
`work/stage1/gameover`, `work/stage1/level1`, `work/stage1/level2`, `work/stage1/level3`, `work/stage1/level4`,
`work/stage1/ending`, `work/stage1/c1`, `work/stage2/zones/L1Z4`, `work/stage2/ending2`, `work/stage2/beeper48`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`player`](#the-ay-player-and-tunes-ram-1-player) | `$C000`-`$C353` | 12 of 18 |
| [`sequencer`](#the-ay-player-and-tunes-ram-1-sequencer) | `$C354`-`$C684` | 10 of 15 |
| [`effects`](#the-ay-player-and-tunes-ram-1-effects) | `$C685`-`$C6E4`, `$CD08`-`$CDA3` | 1 of 3 |
| [`tunes`](11-data-reference.md#the-ay-player-and-tunes-ram-1-tunes) | `$C6E5`-`$CD07` | 0 of 6 |

### The AY player and tunes (RAM 1): player

`src/music/player.asm`

#### `StartNote` (`$C0E2`)

**Start a note on channel IX: instrument IY, period HL, duration C**

Copies the instrument (IY: +0 attack step, +1 decay step, +2 sustain level, +3 release step, +4 peak volume, +5 vibrato delay, +6 vibrato length, +7/+8 vibrato step, +9 flags) into the channel record: period, duration, delay, half the vibrato length (at least 1), the step; the period offset is cleared. The flags go to +17: bit 0 turns the channel's tone on, bit 1 its noise, bit 2 a fixed volume (`$FF`, held for the duration) instead of the envelope (no instrument or effect sets it). Otherwise the envelope starts at AttackStep. Called by TrackStep for a tune's note and by AyPlayEffect `$C685` with an effect.

Starts with DI and has no EI: the callers run with interrupts off (the game's `$9FED`) or inside the IM 2 handler.

Witness: L1 5524 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 830 calls, 500,452 t-states own (0.05 %) |
| Runs (the other recordings) | 5,524 calls (`stage1/level1` 922, `stage1/c1` 830, `stage1/level2` 790 and 7 more) |
| Called from | `TrackStep` (tail), `AyPlayEffect` |
| Reads | `$C0AA`-`$C0D1` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC`); `$CCBD`-`$CCDF` (`Instruments+5`); `$CD0D`-`$CD11` (`EffectTable+5`); `$CD27`-`$CD45` (`Effect2+5`, `Effect3`, `Effect4`); `$CD5B`-`$CD5F` (`Effect6+5`); `$CD82`-`$CDA0` (`Effect9+5`, `Effect10`, `Effect11`) |
| Writes | `$C0AA`-`$C0E0` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC`) |

#### `SilenceAll` (`$C15E`)

**Silence the AY: all tone and noise off, volumes 0, the channels' volumes cleared**

Sets bits 0-5 of MixerShadow, writes register 7, zeroes registers 8-10, register 11 = 1 and 12-13 = 0 (the envelope), and the three channels' volumes. AyPlayTune `$C3E4` calls it before a tune starts.

Witness: L1 30 (c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4 calls, 1,714 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/controls` 12, `stage1/level1` 5, `stage1/c1` 4 and 3 more) |
| Called from | `AyPlayTune` |
| Calls | `SoundHookStart`, `SoundHookEnd` (tail), `WriteAy` |
| Reads | `$C0AA` (`MixerShadow`) |
| Writes | `$C0AA`-`$C0E0` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC`) |

#### `UpdateAy` (`$C19F`)

**Once a frame: step the three channels and write AY registers 7, 0-6 and 8-10**

Returns at once while MixerShadow has every channel off. Otherwise runs ChannelStep `$C25B` for channels A, B and C, then writes the mixer, each channel's period plus its vibrato offset, the noise period (NoisePeriod, from a channel with noise) and the volumes (+5 / 8).

Witness: L1 47434 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14,301 calls, 4,713,275 t-states own (0.46 %) |
| Runs (the other recordings) | 47,434 calls (`stage1/c1` 14,301, `stage1/level3` 5,921, `stage1/level2` 5,870 and 7 more) |
| Called from | `AyTick` |
| Calls | `ChannelStep`, `SoundHookStart`, `SoundHookEnd` (tail), `WriteAy` |
| Reads | `$C0AA`-`$C0E1` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC` and 1 more) |
| Writes | `$C0E1` (`NoisePeriod`) |

#### `ChannelStep` (`$C25B`)

**One channel's frame: count the duration down, step the vibrato, run the envelope phase**

Nothing while the channel is off in MixerShadow. The duration (+6) counts down unless 0 or `$FF`; VibratoStep `$C303` moves the period offset; then a fixed-volume instrument (flags bit 2) waits for the duration to end and goes to ReleaseOff, the others jump to the phase routine at +13/+14.

Witness: L1 99282 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 15,546 calls, 3,537,184 t-states own (0.35 %) |
| Runs (the other recordings) | 99,282 calls (`stage1/c1` 15,546, `stage1/level2` 15,357, `stage1/level1` 15,075 and 7 more) |
| Called from | `UpdateAy` |
| Calls | `AttackStep`, `DecayStep`, `SustainStep`, `ReleaseStep`, `VibratoStep` |
| Reads | `$C0AA`-`$C0DF` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC`); `$CCC1`-`$CCDF` (`Instruments+9`); `$CD11` (`EffectTable+9`); `$CD2B`-`$CD45` (`Effect2+9`, `Effect3`, `Effect4`); `$CD5F` (`Effect6+9`); `$CD86`-`$CDA0` (`Effect9+9`, `Effect10`, `Effect11`) |
| Writes | `$C0B1` (`ChannelA+6`); `$C0C3` (`ChannelB+6`); `$C0D5` (`ChannelC+6`) |

#### `AttackStep` (`$C28D`)

**Envelope phase 1: volume + attack step until the peak, then DecayStep**

Witness: L1 6357 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 867 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 139,887 t-states own (0.01 %) |
| Runs (the other recordings) | 6,357 runs of its first instruction, entered by a jump (`stage1/level1` 1,009, `stage1/level2` 883, `stage1/c1` 867 and 7 more) |
| Called from | `ChannelStep` |
| Reads | `$C0B0` (`ChannelA+5`); `$C0C2` (`ChannelB+5`); `$C0D4` (`ChannelC+5`); `$CCB8`-`$CCDA` (`Instruments`); `$CD08`-`$CD0C` (`EffectTable`); `$CD22`-`$CD40` (`Effect2`, `Effect3`, `Effect4`); 2 more ranges |
| Writes | `$C0B0`-`$C0DD` (`ChannelA+5`, `ChannelB`, `ChannelC`) |

#### `DecayStep` (`$C2AC`)

**Envelope phase 2: volume + decay step (negative) down to the sustain level, then SustainStep**

Witness: L1 37089 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,474 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 608,215 t-states own (0.06 %) |
| Runs (the other recordings) | 37,089 runs of its first instruction, entered by a jump (`stage1/level1` 5,966, `stage1/level2` 5,585, `stage1/c1` 5,474 and 7 more) |
| Called from | `ChannelStep` |
| Reads | `$C0B0` (`ChannelA+5`); `$C0C2` (`ChannelB+5`); `$C0D4` (`ChannelC+5`); `$CCB9`-`$CCD8` (`Instruments+1`); `$CD09`-`$CD0A` (`EffectTable+1`); `$CD23`-`$CD3E` (`Effect2+1`, `Effect3`, `Effect4`); 2 more ranges |
| Writes | `$C0B0`-`$C0DD` (`ChannelA+5`, `ChannelB`, `ChannelC`) |

#### `SustainStep` (`$C2CE`)

**Envelope phase 3: hold the volume until the duration (+6) is 0, then ReleaseStep**

Witness: L1 15122 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,747 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 224,882 t-states own (0.02 %) |
| Runs (the other recordings) | 15,122 runs of its first instruction, entered by a jump (`stage1/c1` 5,747, `stage1/controls` 1,811, `stage1/level1` 1,721 and 7 more) |
| Called from | `ChannelStep` |
| Reads | `$C0B1` (`ChannelA+6`); `$C0C3` (`ChannelB+6`); `$C0D5` (`ChannelC+6`) |
| Writes | `$C0B8`-`$C0B9` (`ChannelA+13`); `$C0CA`-`$C0CB` (`ChannelB+13`); `$C0DC`-`$C0DD` (`ChannelC+13`) |

#### `ReleaseStep` (`$C2DD`)

**Envelope phase 4: volume + release step (negative) down to 0, then the channel off and free**

At 0 the channel's tone and noise bits are set again in MixerShadow and +17 bit 7 is cleared, so a tune may use the channel again after an effect.

Witness: L1 7788 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 847 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 74,331 t-states own (0.01 %) |
| Runs (the other recordings) | 7,788 runs of its first instruction, entered by a jump (`stage1/level2` 1,725, `stage1/level3` 1,478, `stage1/level4` 1,215 and 7 more) |
| Called from | `ChannelStep` |
| Reads | `$C0AA`-`$C0E0` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC`); `$CCBB` (`Instruments+3`); `$CCCF`-`$CCD9` (`Instruments+23`); `$CD0B` (`EffectTable+3`); `$CD25`-`$CD3F` (`Effect2+3`, `Effect3`, `Effect4`); `$CD59` (`Effect6+3`); 1 more ranges |
| Writes | `$C0AA`-`$C0E0` (`MixerShadow`, `ChannelA`, `ChannelB`, `ChannelC`) |

#### `VibratoStep` (`$C303`)

**Add the step to the period offset after the delay; at the end of the length reverse the step**

+7 delays the start (`$FF`: never). Each frame the step (+11/+12) is added to the offset (+9/+10); when +8 counts to 0 the instrument's length +6 decides: 0 keeps the step going (a slide), bit 7 set stops it (+7 = `$FF`), else +8 = the length and the step is negated (a vibrato).

Witness: L1 66356 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 12,935 calls, 788,546 t-states own (0.08 %) |
| Runs (the other recordings) | 66,356 calls (`stage1/c1` 12,935, `stage1/level1` 9,848, `stage1/level2` 8,845 and 7 more) |
| Called from | `ChannelStep` |
| Reads | `$C0B2`-`$C0DB` (`ChannelA+7`, `ChannelB`, `ChannelC`); `$CD0E` (`EffectTable+6`); `$CD28`-`$CD35` (`Effect2+6`, `Effect3`); `$CD5C` (`Effect6+6`); `$CD83` (`Effect9+6`); `$CD9D` (`Effect11+6`) |
| Writes | `$C0B2`-`$C0DB` (`ChannelA+7`, `ChannelB`, `ChannelC`) |

#### `SoundHookStart` (`$C345`)

**A bare RET called before the AY writes: a hook left from another machine's player**

Witness: L1 33124 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,186 calls, 51,888 t-states own (0.01 %) |
| Runs (the other recordings) | 33,124 calls (`stage1/c1` 5,186, `stage1/level2` 5,119, `stage1/level1` 5,030 and 7 more) |
| Called from | `SilenceAll`, `UpdateAy` |

#### `SoundHookEnd` (`$C346`)

**A bare RET jumped to after the AY writes**

Witness: L1 33124 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 5,186 calls, 51,860 t-states own (0.01 %) |
| Runs (the other recordings) | 33,124 calls (`stage1/c1` 5,186, `stage1/level2` 5,119, `stage1/level1` 5,030 and 7 more) |
| Called from | `SilenceAll` (tail), `UpdateAy` (tail) |

#### `WriteAy` (`$C347`)

**Write A to AY register C (OUT `$FFFD` the register, OUT `$BFFD` the value)**

Witness: L1 364244 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 57,030 calls, 4,334,929 t-states own (0.42 %) |
| Runs (the other recordings) | 364,244 calls (`stage1/c1` 57,030, `stage1/level2` 56,309, `stage1/level1` 55,310 and 7 more) |
| Called from | `SilenceAll`, `UpdateAy` |
| Ports out | `$BFFD`, `$FFFD` |

### The AY player and tunes (RAM 1): sequencer

`src/music/sequencer.asm`

#### `OldEntries` (`$C354`)

**Not run: a jump table of an earlier build (JP `$A016`, JP AyTick, the flag, JP OldPlayEffect)**

Known only from the code. Nothing jumps here: the game calls AyPlayTune `$C3E4`, AyTick `$C46C` and AyPlayEffect `$C685` directly. The first jump goes to `$A016`, the game's own AyPlayTune in RAM 2, so the table was made for a build where this code sat elsewhere.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OldTick` (`$C357`)

**Not run: JP AyTick**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OldJumps` (`$C35B`)

**Not run: JP OldPlayEffect**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OldStopMusic` (`$C35E`)

**Not run: MusicOn = 0, then SilenceAll**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `OldPlayEffect` (`$C365`)

**Not run: an older AyPlayEffect, always on channel A**

Known only from the code. The same record address as AyPlayEffect (EffectTable + 13A), always channel A, and the channel marked busy (+17 bit 7) after StartNote; DI / EI round it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `AyPlayTune` (`$C3E4`)

**Start tune A (0-7): silence, point the three tracks at the tune's order lists, MusicOn = `$FF`**

Called from the game's AyPlayTune `$A016` (128K only) with A = the tune. Calls SilenceAll, reads the tune's three order list pointers from TuneTable + 6A, then for each track: repeats 1, transpose 0, pattern ended, the note's frames 1, active, ornament 0, instrument Instruments (0); InstrumentMap to 0, 10, ... 70. The tunes and their call sites: 0 `$E324` (a level's intro), 1-4 `$AC20` (a level's end, the number from `$E4AD`), 5 `$E220`, 6 `$E386`, 7 `$F531` (the bonus end marker).

Witness: L1 30 (c1, controls, ending, ending2, gameover, level1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 4 calls, 6,769 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/controls` 12, `stage1/level1` 5, `stage1/c1` 4 and 3 more) |
| Calls | `SilenceAll` |
| Reads | `$CA8F`-`$CA94` (`TuneTable`); `$CAA7`-`$CABE` (`TuneTable+24`) |
| Writes | `$C35A` (`MusicOn`); `$C38E`-`$C3E3` (`Track0+1`, `Track1`, `Track2`, `InstrumentMap`) |

#### `AyTick` (`$C46C`)

**Once a frame (the IM 2 handler, through `$A030`): UpdateAy, then step the three tracks while a tune plays**

UpdateAy runs every frame, for the effects too. While MusicOn is not 0 the three tracks' active bytes are ORed: all ended, MusicOn = 1 while a channel still sounds, then 0; else TrackStep for tracks 0, 1, 2 on channels A, B, C (the last falls into TrackStep).

Witness: L1 47434 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

[Animation: `AyTick` at work](img/routines/AyTick.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 14,301 calls, 1,366,721 t-states own (0.13 %) |
| Runs (the other recordings) | 47,434 calls (`stage1/c1` 14,301, `stage1/level3` 5,921, `stage1/level2` 5,870 and 7 more) |
| Calls | `UpdateAy`, `TrackStep` (falls into) |
| Reads | `$C0AA` (`MixerShadow`); `$C35A` (`MusicOn`); `$C39A` (`Track0+13`); `$C3AF` (`Track1+13`); `$C3C4` (`Track2+13`) |
| Writes | `$C35A` (`MusicOn`) |

#### `TrackStep` (`$C4B4`)

**One track's frame: count the note down; at its end read the next pattern bytes (and order list bytes)**

OrnamentStep first. While the note's frames last (+12), the pattern pointer is only moved past command bytes. At 0 the next pattern byte: `$80`-`$FF` commands (PatternCommand `$C5BB`), `$7F` a rest (the next byte: frames), `$7E` a period word then frames, else a note: PeriodTable[note + transpose + 12], the next byte its frames, and StartNote with the track's instrument unless an effect holds the channel.

At a pattern's `$FF` the repeat count runs down (the same pattern again), then the order list is read: under `$80` a pattern number (PatternLo / PatternHi), `$80`-`$BF` the repeats (bits 0-4) of the next pattern, `$C0`-`$FD` an InstrumentMap slot (bits 0-2) and its value, `$FE` a transpose, `$FF` the end (active = 0).

Witness: L1 43833 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 11,253 calls, 2,441,631 t-states own (0.24 %) |
| Runs (the other recordings) | 43,833 calls (`stage1/c1` 11,253, `stage1/controls` 7,464, `stage1/level1` 6,591 and 7 more) |
| Called from | `AyTick` (falls into) |
| Calls | `StartNote` (tail), `PatternCommand`, `OrnamentStep` |
| Reads | `$C016`-`$C087` (`PeriodTable+22`); `$C0BC` (`ChannelA+17`); `$C0CE` (`ChannelB+17`); `$C0E0` (`ChannelC+17`); `$C38E`-`$C3C6` (`Track0+1`, `Track1`, `Track2`); `$C6E5`-`$C7B8` (`Patterns`); 7 more ranges |
| Writes | `$C38E`-`$C3CB` (`Track0+1`, `Track1`, `Track2`) |

#### `PatternCommand` (`$C5BB`)

**A pattern command byte at DE: `$80`-`$87` instrument slot, `$88`-`$BF` ornament, `$FF` pattern end, `$C0`-`$FE` skipped**

`$80`-`$87`: the instrument = Instruments + InstrumentMap[track +0 + bits 0-2]. `$88`-`$BF`: the ornament number (bits 0-3) for the next notes. `$FF`: the track's pattern ended (+11 = `$FF`). `$C2` is skipped alone, the other `$C0`-`$FE` with three more bytes. The tunes use only `$80`-`$85` and `$FF`.

Witness: L1 1892 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 458 calls, 50,462 t-states own (0.00 %) |
| Runs (the other recordings) | 1,892 calls (`stage1/c1` 458, `stage1/level1` 335, `stage1/controls` 246 and 7 more) |
| Called from | `TrackStep` |
| Reads | `$C38D` (`Track0`); `$C3A2` (`Track1`); `$C3B7` (`Track2`); `$C3CC`-`$C3DE` (`InstrumentMap`); `$C6E5`-`$C709` (`Patterns`); `$C74A`-`$C793` (`Patterns+101`); 6 more ranges |
| Writes | `$C394`-`$C398` (`Track0+7`); `$C3A9`-`$C3AD` (`Track1+7`); `$C3BE`-`$C3C2` (`Track2+7`) |

#### `OrnamentStep` (`$C5F5`)

**Step the track's ornament (a per-note arpeggio): the period moves through table offsets**

Every note sets +20 = ornament | `$C0`, and with ornament 0 (every tune) OrnamentStep clears bit 7 and returns. Beyond that it is known only from the code: with a number N it would read bytes at OrnamentBase + 8N (bits 0-2 frames, bits 3-7 semitones over the note), which lie inside TrackStep's code: the ornament table of the original player was not kept.

Witness: L1 43833 (L1Z4, c1, controls, ending, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 11,253 calls, 736,491 t-states own (0.07 %) |
| Runs (the other recordings) | 43,833 calls (`stage1/c1` 11,253, `stage1/controls` 7,464, `stage1/level1` 6,591 and 7 more) |
| Called from | `TrackStep` |
| Reads | `$C0BC` (`ChannelA+17`); `$C0CE` (`ChannelB+17`); `$C0E0` (`ChannelC+17`); `$C3A1` (`Track0+20`); `$C3B6` (`Track1+20`); `$C3CB` (`Track2+20`) |
| Writes | `$C3A1` (`Track0+20`); `$C3B6` (`Track1+20`); `$C3CB` (`Track2+20`) |

### The AY player and tunes (RAM 1): effects

`src/music/effects.asm`

#### `AyPlayEffect` (`$C685`)

**Play effect A (0-11): its record from EffectTable on the next channel, as a note**

IY = EffectTable + 13A. Effect 4 goes to ChannelB; the others to the channel after the last one used (EffectChannel 0, 1, 2: A, B, C). StartNote with the record's period (+10/+11) and duration (+12). Keeps every register but A and F.

Witness: L1 2042 (L1Z4, c1, controls, ending2, gameover, level1-level4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the control menu and play on level 1; from the entry `$AB4D` (frame 19 010, T 70 483)) | 158 calls, 90,554 t-states own (0.01 %) |
| Runs (the other recordings) | 2,042 calls (`stage1/level2` 539, `stage1/level3` 451, `stage1/level1` 311 and 6 more) |
| Calls | `StartNote` |
| Reads | `$C6E4` (`EffectChannel`); `$CD12`-`$CD14` (`EffectTable+10`); `$CD2C`-`$CD48` (`Effect2+10`, `Effect3`, `Effect4`); `$CD60`-`$CD62` (`Effect6+10`); `$CD87`-`$CDA3` (`Effect9+10`, `Effect10`, `Effect11`) |
| Writes | `$C6E4` (`EffectChannel`) |
