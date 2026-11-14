# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit), `work/stage1/load-l2` (load-l2: level 2 read from side B at ROM speed and started), `work/stage1/load-l3` (load-l3: level 3 read from side B at ROM speed and started), `work/stage1/load-l4` (load-l4: level 4 read from side B at ROM speed and started), `work/stage1/load-l5` (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)), `work/stage1/controls-kempston` (controls-kempston: the Kempston method in play), `work/stage1/rec/rzx-l5-full` (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus), `work/stage1/rec/rzx-l5-22000-poke` (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy), `work/stage1/rec/rzx-l5-23000` (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending), `work/docs/rec/fatguy-hits` (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls. An entry no routine of a recording starts at (entered by a jump, a table jump or
by running on: L1 books its time to the routine it runs in) gives the runs of its first instruction, as its witness
line counts them.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`hud`](#hud) | `$7080`-`$71BF`, `$796F`-`$7A52`, `$7F23`-`$7F43` | 9 of 11 |
| [`controls`](#controls) | `$71C0`-`$7328` | 14 of 16 |
| [`render`](#render) | `$7329`-`$796E`, `$7A61`-`$7A75`, `$7EB3`-`$7EC7`, `$85FA`-`$865C`, `$88B1`-`$88CE` | 30 of 31 |
| [`interrupt`](#interrupt) | `$7A53`-`$7A60`, `$7A76`-`$7ABE`, `$7C39`-`$7C7C`, `$81AF`-`$81E5` | 7 of 13 |
| [`sound`](#sound) | `$7ABF`-`$7B8E` | 3 of 6 |
| [`setup`](#setup) | `$7B8F`-`$7C38` | 4 of 4 |
| [`mainloop`](#mainloop) | `$7C7D`-`$7EB2`, `$7EF1`-`$7EF2` | 15 of 18 |
| [`ending`](#ending) | `$7EC8`-`$7ED2`, `$86E0`-`$88B0` | 9 of 12 |
| [`score`](#score) | `$7ED3`-`$7EF0`, `$7EF3`-`$7F22`, `$8B3B`-`$8B3D`, `$9163`-`$917C` | 3 of 14 |
| [`menu`](#menu) | `$7F44`-`$81AE`, `$81E6`-`$8373`, `$83CE`-`$840B` | 15 of 21 |
| [`level`](#level) | `$8374`-`$83B7`, `$88CF`-`$88D3`, `$88D4`-`$894D`, `$8969`-`$8B3A` | 10 of 16 |
| [`objects`](#objects) | `$83B8`-`$83CD`, `$865D`-`$86DF`, `$8B3E`-`$8BF2`, `$917D`-`$91AF`, `$9BC7`-`$9C56`, `$9C57`-`$9EAE`, `$A69F`-`$A7FF` | 27 of 35 |
| [`levelload`](#levelload) | `$840C`-`$85F9`, `$894E`-`$8968` | 9 of 11 |
| [`enemies`](#enemies) | `$8BF3`-`$8C6B`, `$9EAF`-`$A2E0` | 10 of 12 |
| [`collision`](#collision) | `$8C6C`-`$8F28` | 19 of 19 |
| [`rick`](#rick) | `$8F29`-`$9162`, `$93D0`-`$9592`, `$95ED`-`$9AE7`, `$9B07`-`$9B20`, `$9B8C`-`$9BC6` | 21 of 53 |
| [`weapons`](#weapons) | `$91B0`-`$93CF`, `$9593`-`$95EC`, `$9AE8`-`$9B06`, `$9B21`-`$9B8B` | 16 of 21 |
| [`traps`](#traps) | `$A2E1`-`$A69E` | 8 of 9 |

## hud

`src/game/hud.asm`

### `DrawHud` (`$796F`)

**Clear the HUD row, colour it and draw the detonators, ammunition, lives and score**

Clears the 8 lines of screen row 0 with PUSH (interrupts off, SP saved at `$7991`), colours it (columns 0-6 `$47` white, 7-14 `$42` red, 15-22 `$43` magenta, 23-31 `$44` green, bright), then DrawDetonators, DrawAmmo, DrawLives, DrawScore. Called by the section start `$8B16` (97) and `$8767` (once): 98 runs in 44 builds.

Witness: L1 283 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 18,839 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 8,543 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 2,822 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 7,258 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 2,461 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 5,764 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 14 calls, 42,073 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 3,569 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 4,922 t-states own (0.01 %) |
| Runs (the other recordings) | 119 calls (`stage1/rec/rzx-l3-04000-poke` 7, `stage1/rec/rzx-l4-10000-poke` 6, `stage2/rec/c48` 6 and 56 more) |
| Called from | `ShowEndText`, `SetupSection` |
| Calls | `DrawLives`, `DrawAmmo`, `DrawDetonators`, `DrawScore` |
| Reads | `$5800`-`$581E` (screen) |
| Writes | `$5800`-`$581F` (screen); `$7991`-`$7992` (`ClearHudEnd+1`) |

### `DrawLives` (`$79C3`)

**Draw the lives `$8B3B` as Rick's heads at columns 25-30**

Up to six GlyphLife, the rest blank (DrawIconRow). Callers: DrawHud `$79BC`, the life loss `$8A34`, the ending's tally `$8739`.

Witness: L1 351 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 11 calls, 1,006 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 5 calls, 372 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 64 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3 calls, 279 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 64 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 3 calls, 307 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 25 calls, 2,320 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 6 calls, 384 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 4 calls, 342 t-states own (0.00 %) |
| Runs (the other recordings) | 132 calls (`stage2/rec/c48` 10, `stage1/rec/rzx-l3-04000-poke` 9, `stage1/rec/rzx-l4-10000-poke` 6 and 56 more) |
| Called from | `DrawHud`, `TallyLives`, `LoseLife` |
| Calls | `DrawIconRow` |
| Reads | `$8B3B` (`Lives`) |

### `DrawAmmo` (`$79D1`)

**Draw the ammunition `$8B3C` as bolts at columns 17-22**

Callers: DrawHud `$79B9`, `$95A3`, `$A5AA`.

Witness: L1 490 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 8 calls, 681 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 246 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 108 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 197 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 64 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 3 calls, 273 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 25 calls, 2,096 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 64 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 3 calls, 192 t-states own (0.00 %) |
| Runs (the other recordings) | 209 calls (`stage1/rec/rzx-l3-04000-poke` 10, `stage1/rec/rzx-l4-10000-poke` 8, `stage2/rec/c48` 7 and 68 more) |
| Called from | `DrawHud`, `FireBullet`, `UpdatePickup` |
| Calls | `DrawIconRow` |
| Reads | `$8B3C` (`Ammunition`) |

### `DrawDetonators` (`$79DF`)

**Draw the detonators `$8B3D` at columns 9-14**

Callers: DrawHud `$79B6`, `$9B45`, `$A5BA`.

Witness: L1 418 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 7 calls, 616 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 255 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 122 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 161 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 64 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 3 calls, 192 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 24 calls, 1,983 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 64 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 97 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 128 t-states own (0.00 %) |
| Runs (the other recordings) | 175 calls (`stage2/rec/c48` 8, `stage1/rec/rzx-l3-04000-poke` 7, `stage1/rec/rzx-l4-10000-poke` 7 and 67 more) |
| Called from | `DrawHud`, `DropDetonator`, `UpdatePickup` |
| Calls | `DrawIconRow` |
| Reads | `$8B3D` (`Detonators`) |

### `DrawIconRow` (`$79ED`)

**Draw B copies of the glyph at HL from DE, then 6 - B blanks**

B = the count (0-6: more would draw 256 - (B - 6) blanks), HL = the glyph, DE = the screen address in row 0.

Witness: L1 1259 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 26 calls, 2,592 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 11 calls, 1,097 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 286 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 7 calls, 692 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3 calls, 234 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 9 calls, 930 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 74 calls, 7,339 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 86 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 8 calls, 572 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 9 calls, 723 t-states own (0.00 %) |
| Runs (the other recordings) | 516 calls (`stage1/rec/rzx-l3-04000-poke` 26, `stage2/rec/c48` 25, `stage1/rec/rzx-l4-10000-poke` 21 and 74 more) |
| Called from | `DrawLives`, `DrawAmmo`, `DrawDetonators` |
| Calls | `DrawGlyphs` (falls into) |

### `DrawGlyphs` (`$79FF`)

**Draw the glyph at HL B times from DE rightwards**

Witness: L1 7554 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 39 calls, 18,464 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 calls, 7,791 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 2,264 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 9 calls, 5,341 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3 calls, 1,797 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 13 calls, 6,401 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 117 calls, 52,488 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 2 calls, 604 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 12 calls, 5,003 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 10 calls, 5,591 t-states own (0.01 %) |
| Runs (the other recordings) | 707 calls (`stage2/rec/c48` 37, `stage1/rec/rzx-l3-04000-poke` 31, `stage1/rec/rzx-l4-10000-poke` 30 and 74 more) |
| Called from | `DrawIconRow` (falls into) |
| Calls | `DrawGlyph` |

### `DrawScore` (`$7A0C`)

**Draw the six score digits `$7F1D-$7F22` at columns 1-6**

Each digit 0-9 is a glyph number. Callers: DrawHud `$79BF`, the score adder `$7EED` (149).

Witness: L1 599 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 7,097 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 3,928 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 1,427 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 2,816 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3 calls, 3,210 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 2,511 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 44 calls, 52,756 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 1,070 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 6 calls, 6,420 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 2,140 t-states own (0.00 %) |
| Runs (the other recordings) | 240 calls (`stage1/rec/rzx-l3-04000-poke` 11, `stage1/rec/rzx-l4-02000-poke` 8, `stage1/rec/rzx-l5-06000-poke` 7 and 71 more) |
| Called from | `DrawHud`, `AddScore` |
| Calls | `DrawGlyph` |
| Reads | `$7F1D`-`$7F22` (`Score`) |

### `DrawGlyph` (`$7A2C`)

**Copy the 8 bytes at HL to the screen cell at DE**

DE = the cell's top line; DE ends on its last line (D + 7). Callers: DrawGlyphs `$7A02`, DrawScore `$7A21` and the text printer `$7F3B` (the texts at rows 9-10). 4852 runs in 65 builds.

Witness: L1 11888 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 200 calls, 52,652 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 140 calls, 37,823 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 98 calls, 27,626 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 146 calls, 41,919 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 146 calls, 39,474 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 66 calls, 17,590 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 724 calls, 186,934 t-states own (0.01 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 12 calls, 2,496 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 84 calls, 17,987 t-states own (0.01 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 66 calls, 14,434 t-states own (0.02 %) |
| Runs (the other recordings) | 4,724 calls (`stage1/rec/rzx-l3-04000-poke` 222, `stage2/rec/c48` 194, `stage1/rec/rzx-l4-10000-poke` 162 and 77 more) |
| Called from | `DrawGlyphs`, `DrawScore`, `PrintText` |
| Reads | `$7080`-`$70EF` (`Glyphs`, `GlyphBolt`, `GlyphDetonator`, `GlyphLife` and 1 more); `$7100`-`$712F` (`GlyphLetters+24`); `$7148`-`$719F` (`GlyphLetters+96`); `$7A4B`-`$7A52` (`BlankGlyph`) |
| Writes | `$4001`-`$401E` (screen); `$4101`-`$411E` (screen); `$4201`-`$421E` (screen); `$4301`-`$431E` (screen); `$4401`-`$441E` (screen); `$4501`-`$451E` (screen); 18 more ranges |

### `PrintText` (`$7F23`)

**Print a text on the screen: HL the text (`$FF` the end), DE the screen address**

Each character: `$FF` ends, a space moves on a column, else the glyph `$7080` + 8 x (code - `$34`) is drawn at DE by `$7A2C`; DE + 1. So the digits are stored 4 higher ("4" is the glyph 0). Out: HL on the `$FF`.

Evidence: 512 runs in 9 builds (callers `$7E94` x4 GAME OVER, `$8415` x20 and `$8430` x18 the tape messages, a run a character).

Witness: L1 976 (controls-keyboard, rzx-l3-10000-poke, rzx-l4-20000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 1,653 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 13,964 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 4 calls, 18,838 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 5 calls, 23,719 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 6 calls, 29,332 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 3,306 t-states own (0.00 %) |
| Runs (the other recordings) | 21 calls (`stage1/rec/rzx-l3-10000-poke` 1, `stage1/rec/rzx-l4-20000-poke` 1, `stage2/rec/c48` 1 and 18 more) |
| Called from | `MainLoopPause`, `LoadLevel` |
| Calls | `DrawGlyph` |
| Reads | `$7EC8`-`$7ED2` (`GameOverText`); `$843A`-`$8469` (`TapeTexts`, `StopTapeText`) |

## controls

`src/game/controls.asm`

### `TestInfiniteLivesKeys` (`$71C0`)

**Z when C, S and 3 are held together (and no other key of their half rows)**

Reads the half rows `$FEFE` (C alone: AND `$1F` = `$17`), `$FDFE` (S alone: `$1D`) and `$F7FE` (3 alone: `$1B`); returns NZ at the first that does not match, Z when all three do. The main loop `$7D33` then plays tune 1 and toggles `$8066` (XOR `$FF`), the flag the life loss `$8A26` tests before it takes a life (and `$9593`, `$95ED`, `$96B4`, `$9B27` read): an infinite-lives cheat.

`$71CA-$71DB` (the S and 3 tests) ran only in cheats (stage 2: the chord at frame 50): LD B,`$FD` / IN A,(C) / AND `$1F` / CP `$1D` / RET NZ / LD B,`$F7` / IN A,(C) / AND `$1F` / CP `$1B` / RET.

Witness: L1 120436 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,113 calls, 76,357 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 calls, 17,043 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 calls, 18,605 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 calls, 18,572 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 calls, 17,416 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 486 calls, 33,457 t-states own (0.04 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 calls, 596,172 t-states own (0.03 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 47,166 t-states own (0.03 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 calls, 17,139 t-states own (0.03 %) |
| Runs (the other recordings) | 49,125 calls (`stage2/rec/c48` 1,206, `stage1/rec/rzx-l1-14000-poke` 917, `stage1/rec/rzx-l1-06000-poke` 830 and 78 more) |
| Called from | `MainLoop` |
| Ports in | `$F7FE`, `$FDFE`, `$FEFE` |

### `TestSectionCheatKeys` (`$71DC`)

**Z when SPACE+N, ENTER+J and Y are held together**

Reads `$7FFE` (SPACE and N: AND `$1F` = `$16`), `$BFFE` (ENTER and J: `$16`) and `$DFFE` (Y: `$0F`); NZ at the first mismatch. The main loop `$7D49`: when `$8065` is set (the four levels completed in one game, which opens level 5) it plays tune 1 and sets `$8067` = `$FF`, whose bit 7 the section test `$8993` reads (`$89D9`): a cheat that only works after the game is finished.

`$71E6-$71F8` (the ENTER+J and Y tests) ran only in cheats (stage 2: the chord at frame 200): LD BC,`$BFFE` / IN A,(C) / AND `$1F` / CP `$16` / RET NZ / LD B,`$DF` / IN A,(C) / AND `$1F` / CP `$0F` / RET.

Witness: L1 120436 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,113 calls, 66,038 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 calls, 17,781 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 calls, 16,663 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 calls, 21,082 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 calls, 20,379 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 486 calls, 28,974 t-states own (0.03 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 calls, 569,172 t-states own (0.03 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 59,259 t-states own (0.04 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 calls, 16,570 t-states own (0.03 %) |
| Runs (the other recordings) | 49,125 calls (`stage2/rec/c48` 1,206, `stage1/rec/rzx-l1-14000-poke` 917, `stage1/rec/rzx-l1-06000-poke` 830 and 78 more) |
| Called from | `MainLoopCheatB` |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE` |

### `TestKey0` (`$71F9`)

**Z when 0 is held**

One of six menu key tests, all called by the menu reader `$8087` (`$71F9-$7219` every pass of the menus, `$7221` only when level 5 is open): IN from the half row, BIT n, RET; Z = held.

Witness: L1 199122 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,805 calls, 108,812 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 255 calls, 15,788 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 255 calls, 15,788 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 255 calls, 15,788 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 255 calls, 15,817 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 315 calls, 18,638 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 46,945 calls, 2,039,706 t-states own (0.11 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 45,603 t-states own (0.02 %) |
| Runs (the other recordings) | 51,059 calls (`stage1/rec/rzx-l1-00000-poke` 37,177, `stage2/rec/c48` 2,013, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `ScanNumberKeys` |
| Ports in | `$EFFE` |

### `TestKey1` (`$7201`)

**Z when 1 is held**

Half row `$F7FE` bit 0. Called by `$808D`.

Witness: L1 147360 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,787 calls, 93,762 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 251 calls, 13,591 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 251 calls, 13,591 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 251 calls, 13,591 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 251 calls, 13,566 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 311 calls, 17,579 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 21,165 calls, 1,186,592 t-states own (0.06 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 40,364 t-states own (0.02 %) |
| Runs (the other recordings) | 50,970 calls (`stage1/rec/rzx-l1-00000-poke` 37,177, `stage2/rec/c48` 1,995, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `ScanNumberKeys` |
| Ports in | `$F7FE` |

### `TestKey2` (`$7209`)

**Z when 2 is held**

Half row `$F7FE` bit 1. Called by `$8093`.

Witness: L1 146928 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,761 calls, 98,631 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 251 calls, 12,788 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 251 calls, 12,788 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 251 calls, 12,788 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 251 calls, 12,833 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 310 calls, 15,921 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 21,165 calls, 944,538 t-states own (0.05 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 42,110 t-states own (0.02 %) |
| Runs (the other recordings) | 50,755 calls (`stage1/rec/rzx-l1-00000-poke` 37,176, `stage2/rec/c48` 1,969, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `ScanNumberKeys` |
| Ports in | `$F7FE` |

### `TestKey3` (`$7211`)

**Z when 3 is held**

Half row `$F7FE` bit 2. Called by `$8099`.

Witness: L1 146874 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,736 calls, 100,712 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 250 calls, 15,399 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 251 calls, 15,461 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 251 calls, 15,461 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 251 calls, 15,543 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 300 calls, 18,252 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 21,165 calls, 1,019,072 t-states own (0.05 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 44,319 t-states own (0.02 %) |
| Runs (the other recordings) | 50,751 calls (`stage1/rec/rzx-l1-00000-poke` 37,176, `stage2/rec/c48` 1,969, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `ScanNumberKeys` |
| Ports in | `$F7FE` |

### `TestKey4` (`$7219`)

**Z when 4 is held**

Half row `$F7FE` bit 3. Called by `$809F`.

Witness: L1 146816 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,711 calls, 88,345 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 250 calls, 12,678 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 250 calls, 12,678 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 251 calls, 12,718 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 251 calls, 12,623 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 300 calls, 15,660 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 21,165 calls, 1,139,897 t-states own (0.06 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 39,317 t-states own (0.02 %) |
| Runs (the other recordings) | 50,735 calls (`stage1/rec/rzx-l1-00000-poke` 37,176, `stage2/rec/c48` 1,969, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `ScanNumberKeys` |
| Ports in | `$F7FE` |

### `TestKey5` (`$7221`)

**Z when 5 is held (the level menu's level 5)**

Half row `$F7FE` bit 4. Called by `$80AC` after `$80A5` has found `$8065` set (level 5 open): it ran only in load-l5 (its POKE of `$8065`) and the RZX level 5 recordings.

Witness: L1 46269 (rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, load-l5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 251 calls, 16,506 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 21,165 calls, 1,049,065 t-states own (0.06 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 47,829 t-states own (0.02 %) |
| Runs (the other recordings) | 1,008 calls (`stage2/rec/sec-l5-s5` 504, `stage2/rec/sec-l5-s3` 503, `stage1/rec/rzx-l5-24000-poke` 1) |
| Called from | `ScanNumberKeys` |
| Ports in | `$F7FE` |

### `TestFireKeys` (`$7229`)

**Z when ENTER, SPACE or the chosen method's fire is held**

ENTER (`$BFFE` bit 0) and SPACE (`$7FFE` bit 0) return Z at once; otherwise it calls ReadControls `$7254` and tests bit 4 (fire) of Controls `$7253`. Used to wait for a key: the tape loader's message `$8433` (over a million runs in load-l2 ... load-l5), the GAME OVER wait `$7EA0` and the end text `$8787`.

Witness: L1 1278933 (controls-keyboard, end-congrats, life-up, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 501 calls, 59,118 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 156,279 calls, 23,098,655 t-states own (2.34 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 229,472 calls, 33,895,513 t-states own (2.37 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 307,334 calls, 45,425,946 t-states own (2.41 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 370,188 calls, 54,715,294 t-states own (2.35 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2,688 calls, 380,584 t-states own (0.02 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 2,255 calls, 266,099 t-states own (0.12 %) |
| Runs (the other recordings) | 102,888 calls (`stage1/rec/rzx-l2-00000-poke` 5,654, `stage2/rec/sec-l2-s10` 4,753, `stage2/rec/sec-l2-s11` 4,753 and 24 more) |
| Called from | `MainLoopPause`, `LoadLevelWaitFire`, `EndTextWait` |
| Calls | `ReadControls` |
| Reads | `$7253` (`Controls`) |
| Ports in | `$7FFE`, `$BFFE` |

### `TestPauseKey` (`$7242`)

**Z when P is held**

`$DFFE` bit 0. The main loop `$7D5D`: P held waits for its release, then for a second press and its release (the pause); c1 and controls-keyboard press P (95 582 and 129 946 runs: the waiting loops).

Witness: L1 575194 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 95,582 calls, 4,606,501 t-states own (0.34 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 calls, 13,837 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 calls, 15,566 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 calls, 14,698 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 calls, 13,865 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 486 calls, 27,823 t-states own (0.03 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 calls, 482,765 t-states own (0.03 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 43,814 t-states own (0.03 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 calls, 14,373 t-states own (0.02 %) |
| Runs (the other recordings) | 279,932 calls (`stage1/controls-keyboard` 129,946, `stage2/rec/c48` 102,531, `stage1/rec/rzx-l1-14000-poke` 917 and 78 more) |
| Called from | `MainLoopPause` |
| Ports in | `$DFFE` |

### `TestQuitKey` (`$724A`)

**Z when E is held**

`$FBFE` bit 2. The main loop `$7D2D` jumps to the game's end `$7E1E` on Z (c1 presses E at its end).

Witness: L1 120474 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,114 calls, 56,388 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 calls, 14,649 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 calls, 13,891 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 calls, 16,257 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 calls, 16,136 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 486 calls, 24,596 t-states own (0.03 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 calls, 460,740 t-states own (0.02 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 53,226 t-states own (0.04 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 calls, 14,210 t-states own (0.02 %) |
| Runs (the other recordings) | 49,144 calls (`stage2/rec/c48` 1,207, `stage1/rec/rzx-l1-14000-poke` 917, `stage1/rec/rzx-l1-06000-poke` 830 and 78 more) |
| Called from | `MainLoop` |
| Ports in | `$FBFE` |

### `ReadControls` (`$7254`)

**Read the chosen control method into Controls**

Called by the IM 2 handler (`$FF11`) every interrupt and by TestFireKeys `$7229`. Sets Controls `$7253` to `$FF`, then per ControlMethod `$7252`: 0 the keyboard (O up, else K down; Z left, else X right; ENTER and SPACE fire), 1 Kempston (IN (`$1F`) AND `$1F`, complemented: the joystick's bits are already right 0, left 1, down 2, up 3, fire 4), 2 the cursor keys (0 fire, 8 right, 7 up, else 6 down, 5 left unless right), 3 Sinclair (0 fire, 6 left, else 7 right, 9 up, else 8 down). Keeps HL; changes A, BC, F.

The recordings: 1 211 807 runs in 68 builds; Kempston `$72B1` in controls-kempston (1255), cursor `$72BE` in controls-cursor and every RZX piece (the RZX run used CAPS SHIFT + 5-8, read here without the shift), Sinclair `$72FA` in controls-sinclair (1255) and c1 (85, its menu tour). ENTER as fire (`$72A1`) was never pressed.

Witness: L1 1607150 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `ReadControls` at work](img/routines/ReadControls.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 5,207 calls, 1,636,081 t-states own (0.12 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 158,420 calls, 61,730,921 t-states own (6.26 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 232,160 calls, 90,514,743 t-states own (6.32 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 310,738 calls, 121,143,701 t-states own (6.42 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 374,032 calls, 145,835,861 t-states own (6.25 %) |
| Runs (controls-kempston: the Kempston method in play) | 1,306 calls, 171,838 t-states own (0.18 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 23,092 calls, 1,362,962 t-states own (0.07 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,745 calls, 101,210 t-states own (0.07 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 5,508 calls, 319,521 t-states own (0.14 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 594 calls, 34,452 t-states own (0.05 %) |
| Runs (the other recordings) | 233,854 calls (`stage2/rec/sec-l3-s3` 7,188, `stage2/rec/sec-l3-s4` 7,188, `stage2/rec/sec-l2-s10` 7,188 and 80 more) |
| Called from | `TestFireKeys` |
| Calls | `ReadKempston` (tail) |
| Reads | `$7252`-`$7253` (`ControlMethod`, `Controls`) |
| Writes | `$7253` (`Controls`) |
| Ports in | `$011F`, `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FEFE` |

### `ReadKempston` (`$72B1`)

**ReadKempston**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 255 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 1,255 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 23,092 calls, 4,938,712 t-states own (0.27 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,745 calls, 361,467 t-states own (0.25 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 5,508 calls, 1,156,751 t-states own (0.50 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 594 calls, 123,372 t-states own (0.19 %) |
| Runs (the other recordings) | 220,796 calls (`stage2/rec/sec-l2-s10` 7,188, `stage2/rec/sec-l3-s3` 7,188, `stage2/rec/sec-l3-s4` 7,188 and 74 more) |
| Called from | `ReadControls` (tail) |
| Calls | `ReadCursorDone` (falls into) |
| Reads | `$7253` (`Controls`) |
| Writes | `$7253` (`Controls`) |
| Ports in | `$EFFE`, `$F7FE` |

### `ReadCursorDone` (`$72F8`)

**ReadCursorDone**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 85 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 23,093 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,745 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 5,508 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 594 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,990 calls (`stage1/rec/rzx-l2-00000-poke` 6,990) |
| Called from | `ReadKempston` (falls into) |

## render

`src/game/render.asm`

### `ComposeSprite` (`$7329`)

**Mask the sprite of the object record at IX into spare copies of the cells under it**

IX = an object record: +1 x in pixels, +2/+3 y in pixels from the top of the view buffer (64 = the screen's top), +4/+5 the sprite's address (0: nothing drawn), +6 bit 7 mirrored. The sprite (in Sprites `$C26D`) is: a byte added to the strip offset (the sprite's top line), a byte of rows, then 6 bytes a row: data 2, data 1, data 0, mask 0, mask 2, mask 1 (popped as HL, BC, DE). Returns at once when y >= 299 (`$012B`: below the buffer) or the sprite address is 0.

The view cell under the top left is ViewCells + (y AND `$F8`) x 4 + x / 8; the first spare cell SpareCells + 8 x (SpareCount + 1). x AND 7 = 0 (aligned): 3 columns, of 4 cells when y AND 4 (else 3), each through ComposeCell `$7755`, then the rows are masked in at IY = the strip + (y AND 7) + the sprite's first byte, columns w = 32 (or 24) bytes apart, the displacements patched into `$7495-$74AC`. Otherwise (shifted, ComposeShifted `$74B7`): 4 columns, each row shifted right by x AND 7 through the chain `$7637` entered at `$7637` + 14 x (x AND 7), a fourth byte of data (0) and mask (`$FF`) shifted in. A mirrored sprite swaps its outer bytes and reverses every byte through MirrorTable `$6500` (`$7471`, `$760B`).

Interrupts are off while SP walks the sprite (`$7442-$74B5`, `$75DC-$76D2`): an interrupt that falls there is lost. SP is put back from the copy stored at `$74B3` / `$76D0`.

Callers: the object drawer `$85FA` (`$860A`, `$8618`, `$8626`, `$8639`, `$8652`) and the menu's `$814B`. 250 504 runs in 65 builds; aligned 118 841 (3 rows 113 446, 4 rows 5395), shifted 108 333 (3 rows 96 247, 4 rows 13 402); mirrored rows 232 085 aligned, 551 698 shifted.

Witness: L1 599916 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `ComposeSprite` at work](img/routines/ComposeSprite.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 2,514 calls, 26,327,042 t-states own (1.96 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,806 calls, 21,333,584 t-states own (2.16 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,166 calls, 15,732,111 t-states own (1.10 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,629 calls, 17,889,465 t-states own (0.95 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,597 calls, 12,315,272 t-states own (0.53 %) |
| Runs (controls-kempston: the Kempston method in play) | 661 calls, 7,158,024 t-states own (7.71 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 45,183 calls, 338,924,548 t-states own (18.20 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 2,633 calls, 25,865,285 t-states own (18.24 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 1,895 calls, 20,974,535 t-states own (32.87 %) |
| Runs (the other recordings) | 246,805 calls (`stage1/rec/rzx-l5-02000-poke` 5,398, `stage1/rec/rzx-l5-18000-poke` 5,297, `stage1/rec/rzx-l1-24000-poke` 5,255 and 78 more) |
| Called from | `ControlMenuLoop`, `DrawSprites` |
| Calls | `ComposeAligned3Rows` (tail), `ComposeAlignedBlit` (tail), `ComposeShifted` (tail), `ComposeCell` |
| Reads | `$5E00`-`$61B7` (`SpareCells+24`); `$6500`-`$65FF` (`MirrorTable`); `$77B0` (`SpareCount`); `$7B90`-`$7BAD` (`Entry+1`); `$7BC0`-`$7BC5` (`CopyMusic+1`); `$7BD8`-`$7BDD` (`CopyMusicLoop+8`); 6 more ranges |
| Writes | `$5E00`-`$61B7` (`SpareCells+24`); `$746F`-`$7470` (`ComposeAlignedRowJump+1`); `$7485`-`$7486` (`MirrorAlignedSaved+1`); `$749F`-`$74B4` (`MaskAlignedCol1+2`, `MaskAlignedCol2`, `MaskAlignedCol2Or`, `ComposeAlignedNext` and 1 more); `$7609`-`$760A` (`ComposeShiftedRowJump+1`); `$761F`-`$7620` (`MirrorShiftedSaved+1`); 2 more ranges |

### `ComposeAligned3Rows` (`$73EB`)

**ComposeAligned3Rows**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,430 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 993 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 496 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,027 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,207 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 443 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 30,284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 836 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 548 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 14 calls (`stage1/rec/rzx-l4-20000-poke` 7, `stage2/rec/end-congrats` 7) |
| Called from | `ComposeSprite` (tail) |
| Calls | `ComposeAlignedBlit` (falls into), `ComposeCell` |
| Reads | `$5E03`-`$5E47` (`SpareCells+27`); `$5E82`-`$5EC6` (`SpareCells+154`); `$7C3B`-`$7C3D` (`Im2HandlerSource+2`); `$9BAF`-`$9BB1` (`RickSprite`, `RickFacing`); `$C2ED`-`$C2EE` (`work space $C2ED+`); `$C36D`-`$C36E` (`work space $C36D+`); 4 more ranges |
| Writes | `$5E03`-`$5E47` (`SpareCells+27`); `$5E82`-`$5EC6` (`SpareCells+154`); `$746F`-`$7470` (`ComposeAlignedRowJump+1`); `$749F`-`$74B4` (`MaskAlignedCol1+2`, `MaskAlignedCol2`, `MaskAlignedCol2Or`, `ComposeAlignedNext` and 1 more) |

### `ComposeAlignedBlit` (`$743F`)

**ComposeAlignedBlit**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,578 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,010 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 509 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,044 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,225 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 473 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 30,751 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,182 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 836 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,988 calls (`stage1/rec/rzx-l1-22000-poke` 1,988) |
| Called from | `ComposeSprite` (tail), `ComposeAligned3Rows` (falls into) |
| Reads | `$5E00`-`$605C` (`SpareCells+24`); `$6500`-`$65FF` (`MirrorTable`); `$7B93`-`$7B95` (`Entry+4`); `$7BAB`-`$7BAD` (`Entry+28`); `$7BC3`-`$7BC5` (`CopyMusic+4`); `$7BDB`-`$7BDD` (`CopyMusicLoop+11`); 11 more ranges |
| Writes | `$5E00`-`$605C` (`SpareCells+24`); `$746F`-`$7470` (`ComposeAlignedRowJump+1`); `$7485`-`$7486` (`MirrorAlignedSaved+1`); `$74B3`-`$74B4` (`ComposeAlignedEnd+1`) |

### `ComposeShifted` (`$74B7`)

**ComposeShifted**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 936 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 796 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 657 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 585 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 372 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 188 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 13,473 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,449 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 1,058 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,475 calls (`stage1/rec/rzx-l2-12000-poke` 1,627, `stage1/rec/rzx-l4-06000-poke` 1,476, `stage1/rec/rzx-l1-22000-poke` 1,256 and 2 more) |
| Called from | `ComposeSprite` (tail) |
| Calls | `ComposeShiftedRow` (falls into), `ComposeCell` |
| Reads | `$5E00`-`$60BF` (`SpareCells+24`); `$6500`-`$65FF` (`MirrorTable`); `$7B91`-`$7BAD` (`Entry+2`); `$7BC1`-`$7BC5` (`CopyMusic+2`); `$7BD9`-`$7BDD` (`CopyMusicLoop+9`); `$7BF1`-`$7BF5` (`BuildMirrorTable+1`, `BitReverseLoop`); 18 more ranges |
| Writes | `$5E00`-`$60BF` (`SpareCells+24`); `$7609`-`$760A` (`ComposeShiftedRowJump+1`); `$761F`-`$7620` (`MirrorShiftedSaved+1`); `$7635`-`$7636` (`ShiftRowJump+1`); `$76B2`-`$76D1` (`MaskShiftedCol1+2`, `MaskShiftedCol1Mask`, `MaskShiftedCol2`, `MaskShiftedCol3` and 3 more) |

### `ComposeShiftedRow` (`$7604`)

**ComposeShiftedRow**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 19,656 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 16,716 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 13,797 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 12,161 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 6,676 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 3,948 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 241,614 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 29,092 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 20,321 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 266,514 calls (`stage1/rec/rzx-l4-18000-poke` 60,534, `stage1/rec/rzx-l5-12000-poke` 44,658, `stage1/rec/rzx-l2-06000-poke` 38,442 and 4 more) |
| Called from | `ComposeShifted` (falls into), `ShiftRight7` (tail) |
| Calls | `ShiftRight7` (falls into) |
| Reads | `$5E00`-`$612F` (`SpareCells+24`); `$6500`-`$65FF` (`MirrorTable`) |
| Writes | `$5E00`-`$6117` (`SpareCells+24`); `$761F`-`$7620` (`MirrorShiftedSaved+1`) |

### `ShiftRight7` (`$7699`)

**ShiftRight7**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 19,656 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 16,716 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 13,797 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 12,161 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 6,676 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 3,948 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 241,614 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 29,092 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 20,321 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 37,820 calls (`stage1/rec/rzx-l4-14000-poke` 37,820) |
| Called from | `ComposeShiftedRow` (falls into) |
| Calls | `ComposeShiftedRow` (tail) |
| Reads | `$5E00`-`$6122` (`SpareCells+24`) |
| Writes | `$5E00`-`$612F` (`SpareCells+24`) |

### `DrawChangedCells` (`$76D4`)

**Draw the cells DirtyMap marks: the spare cells, and the level cells the sprites left**

Scans DirtyMap from `$6720` (screen row 1) to the sentinel `$FF` it puts at `$6A00`: 0 is skipped; 1 draws the level cell (ViewCells at the same index, its 8 bytes from CellGraphics) and sets 0; n >= 2 draws spare cell n (SpareCells + 8 x (n + 1)) and sets 1, so the cell is restored on the next pass unless a sprite covers it again. Draws only the bitmap: a cell keeps its attribute. The screen address is ((H x 8 + 8) AND `$FF`, L) of the DirtyMap address.

The graphics base at `$772F` is CellGraphics in play and the font Glyphs `$7080` under the text printer `$88B1` (patched by `$7EB3`, `$7FB2`, `$88B1`).

Callers: the main loop `$7D8E` after the frame wait (50 140), the scrolls `$7901` / `$7961`, RedrawView `$7968`, `$8153`, `$82E7`, `$8319`, `$8AE0`, `$8B30`, `$8B37`. 57 658 runs in 67 builds; spare cells drawn 1 689 139 times, level cells restored 196 595.

Witness: L1 156350 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `DrawChangedCells` at work](img/routines/DrawChangedCells.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 2,948 calls, 80,775,059 t-states own (6.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 557 calls, 21,931,212 t-states own (2.22 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 541 calls, 17,410,141 t-states own (1.22 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 581 calls, 20,261,286 t-states own (1.07 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 548 calls, 18,962,780 t-states own (0.81 %) |
| Runs (controls-kempston: the Kempston method in play) | 812 calls, 19,889,761 t-states own (21.41 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 10,635 calls, 398,903,304 t-states own (21.43 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 30,894,542 t-states own (21.79 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 840 calls, 25,835,201 t-states own (11.19 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 292 calls, 15,766,111 t-states own (24.71 %) |
| Runs (the other recordings) | 63,765 calls (`stage2/rec/c48` 3,249, `stage2/rec/sec-l2-s10` 1,224, `stage2/rec/sec-l3-s3` 1,224 and 79 more) |
| Called from | `ScrollDown`, `ScrollUp`, `RedrawView`, `MainLoopPause`, `ControlMenuLoop`, `DropTextWait`, `SetupSection` |
| Calls | `DrawChangedNext` (falls into) |
| Reads | `$5E00`-`$61BF` (`SpareCells+24`); `$6720`-`$6A00` (`DirtyMap+288`); `$6C20`-`$6EFF` (`ViewCells+288`); `$7080`-`$71BF` (`Glyphs`, `GlyphBolt`, `GlyphDetonator`, `GlyphLife` and 2 more); `$A900`-`$B0FF` (`work space $A900+`); `$FDFF`-`$FE00` (`work space $FDFF+`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 3 more ranges |

### `DrawChangedNext` (`$76DC`)

**DrawChangedNext**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 43,294 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 22,478 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 13,596 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 17,576 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 16,445 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 8,536 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 377,889 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 29,101 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 18,870 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 20,185 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 237,087 calls (`stage1/rec/rzx-l5-20000-poke` 39,124, `stage1/rec/rzx-l5-10000-poke` 36,251, `stage1/rec/rzx-l5-04000-poke` 32,428 and 7 more) |
| Called from | `DrawChangedCells` (falls into), `DrawLevelCell` (tail) |
| Calls | `DrawLevelCell` (tail) |
| Reads | `$5E00`-`$619F` (`SpareCells+24`); `$6720`-`$6A00` (`DirtyMap+288`); `$6C20`-`$6EFF` (`ViewCells+288`); `$7088`-`$70A7` (`Glyphs+8`); `$70E8`-`$71BF` (`GlyphLetters`, `GlyphBlank`); `$A900`-`$AC17` (`work space $A900+`); 4 more ranges |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 3 more ranges |

### `DrawLevelCell` (`$7722`)

**DrawLevelCell**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 8,808 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3,367 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,533 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,535 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,776 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,102 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 31,077 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,465 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 2,196 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2,119 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7,841 calls (`stage1/rec/rzx-l5-10000-poke` 3,918, `stage1/rec/rzx-l1-16000-poke` 2,491, `stage1/rec/rzx-l1-06000-poke` 1,432) |
| Called from | `DrawChangedNext` (tail) |
| Calls | `DrawChangedNext` (tail) |
| Reads | `$6C20`-`$6EFF` (`ViewCells+288`); `$A900`-`$AA87` (`work space $A900+`); `$ABF8`-`$AD7F` (`work space $ABF8+`); `$ADB8`-`$AEE7` (`work space $ADB8+`); `$AF48`-`$B00F` (`work space $AF48+`); `$B030`-`$B07F` (`work space $B030+`); 1 more ranges |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 3 more ranges |

### `ComposeCell` (`$7755`)

**Copy the cell at HL in ViewCells into the next spare cell at DE for a sprite**

HL = a ViewCells address, DE = the next spare cell. C = the cell number; when CellFlags bit 7 is set the cell is in front of sprites: only SpareCount `$77B0` and DE advance (`$77A2`), the spare cell is masked but never shown. Otherwise the DirtyMap byte (HL - `$500`) becomes SpareCount (then incremented), and the spare cell gets the level cell's 8 bytes (CellGraphics + 8C) or, when DirtyMap already held a spare cell n >= 2 (another sprite there this pass), that cell's bytes: overlapping sprites stack. DE advances by 8.

The front test at `$775A` is JP M,`$77A2` in play; the game's end `$7E1E` and the text printer `$88B1` write it to three NOPs (every cell takes sprites), `$7EB3` and `$7FB2` put it back; the graphics base at `$7776` is patched with `$772F`'s.

Callers: ComposeSprite `$7329` (9 to 16 times a sprite) and `$8321` (`$8340`, `$8352`: 2 cells). 2 497 317 runs; front cells 272 993, stacked 551 496.

Witness: L1 6196803 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 43,817 calls, 17,152,541 t-states own (1.28 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 22,027 calls, 8,833,595 t-states own (0.90 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 15,786 calls, 6,536,401 t-states own (0.46 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 19,533 calls, 7,084,000 t-states own (0.38 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 18,701 calls, 7,561,100 t-states own (0.32 %) |
| Runs (controls-kempston: the Kempston method in play) | 9,893 calls, 3,498,443 t-states own (3.77 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 458,197 calls, 175,548,935 t-states own (9.43 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 30,292 calls, 11,912,930 t-states own (8.40 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 22,248 calls, 9,764,293 t-states own (4.23 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 23,048 calls, 8,944,479 t-states own (14.02 %) |
| Runs (the other recordings) | 2,520,187 calls (`stage1/rec/rzx-l5-10000-poke` 50,833, `stage2/rec/c48` 50,791, `stage1/rec/rzx-l1-16000-poke` 47,505 and 79 more) |
| Called from | `ComposeSprite`, `ComposeAligned3Rows`, `ComposeShifted`, `ComposeLetter` |
| Calls | `CopyCellGraphics` (falls into), `ComposeCellStack` (tail), `ComposeCellSkip` (tail) |
| Reads | `$5E00`-`$61AF` (`SpareCells+24`); `$65E8`-`$65EF` (`MirrorTable+232`); `$6604`-`$6FFF` (`DirtyMap+4`, `ViewCells`); `$7080`-`$71BF` (`Glyphs`, `GlyphBolt`, `GlyphDetonator`, `GlyphLife` and 2 more); `$77B0` (`SpareCount`); `$A800`-`$B0FF` (`work space $A800+`); 1 more ranges |
| Writes | `$5E00`-`$61BF` (`SpareCells+24`); `$6604`-`$6AFF` (`DirtyMap+4`); `$77B0` (`SpareCount`) |

### `CopyCellGraphics` (`$777A`)

**CopyCellGraphics**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 35,343 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 20,421 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 15,786 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 16,037 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 17,876 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 6,315 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 432,309 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 29,424 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 22,248 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 21,989 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 84,078 calls (`stage1/rec/rzx-l5-18000-poke` 41,422, `stage1/rec/rzx-l5-08000-poke` 28,034, `stage1/rec/rzx-l1-14000-poke` 14,622) |
| Called from | `ComposeCell` (falls into), `ComposeCellStack` (tail) |
| Reads | `$5E00`-`$6037` (`SpareCells+24`); `$A900`-`$AA87` (`work space $A900+`); `$AB78`-`$AB9F` (`work space $AB78+`); `$ABB8`-`$ABBF` (`work space $ABB8+`); `$ABD8`-`$ABDF` (`work space $ABD8+`); `$ACD0`-`$AD1F` (`work space $ACD0+`); 6 more ranges |
| Writes | `$5E00`-`$60CF` (`SpareCells+24`) |

### `ComposeCellStack` (`$778C`)

**ComposeCellStack**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 3,726 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,655 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 4,142 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,485 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3,662 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 689 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 94,272 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 2,531 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 6,387 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 4,091 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 12,591 calls (`stage1/rec/rzx-l5-08000-poke` 5,492, `stage1/rec/rzx-l5-18000-poke` 5,482, `stage1/rec/rzx-l1-14000-poke` 1,617) |
| Called from | `ComposeCell` (tail) |
| Calls | `CopyCellGraphics` (tail) |
| Reads | `$77B0` (`SpareCount`) |
| Writes | `$660A`-`$671B` (`DirtyMap+10`); `$67A3`-`$67FC` (`DirtyMap+419`); `$681A`-`$6916` (`DirtyMap+538`); `$692A`-`$6934` (`DirtyMap+810`); `$694A` (`DirtyMap+842`); `$696A` (`DirtyMap+874`); 3 more ranges |

### `ComposeCellSkip` (`$77A2`)

**ComposeCellSkip**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 8,474 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,606 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3,496 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 825 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 3,578 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 25,888 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 1,059 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 6,712 calls (`stage1/rec/rzx-l1-14000-poke` 3,550, `stage1/rec/rzx-l5-18000-poke` 2,752, `stage1/rec/rzx-l5-08000-poke` 410) |
| Called from | `ComposeCell` (tail) |
| Reads | `$77B0` (`SpareCount`) |
| Writes | `$77B0` (`SpareCount`) |

### `RedrawScrolledView` (`$77B1`)

**Redraw screen rows 1-23 from a view moved by some rows, only the cells that change**

HL = ViewCells at the new view's screen row 1, HL' = ViewCells at the old one (what the screen shows), DE = DirtyMap at HL - `$500`. Per cell, DirtyMap 0: drawn only when the new cell differs from the old (`$77D0`); 1: drawn (`$77CB`); n >= 2: spare cell n drawn (`$7827`). Each cell drawn gets its attribute from CellAttrs. 7 rows to the first third's end, then 8 and 8.

Called three times by each scroll (ScrollDown `$78C3`, `$78D5`, `$78E7`: 96, 97, 98 runs; ScrollUp `$7923`, `$7935`, `$7947`: 88, 89, 89): 557 runs in 52 builds, the RZX pieces and sec-l4-*; a piece that starts inside a scroll counts its later steps only (c1 never scrolls).

Witness: L1 1114 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 12 calls, 3,941,414 t-states own (0.21 %) |
| Runs (the other recordings) | 545 calls (`stage1/rec/rzx-l5-08000-poke` 30, `stage1/rec/rzx-l1-10000-poke` 27, `stage1/rec/rzx-l4-06000-poke` 21 and 48 more) |
| Called from | `RedrawSkip` (tail), `ScrollDown`, `ScrollUp` |
| Calls | `RedrawSkip` (falls into), `RedrawLevelCell` (tail), `RedrawSpareCell` (tail) |
| Reads | `$5E00`-`$6167` (`SpareCells+24`); `$6620`-`$6AFF` (`DirtyMap+32`); `$6B20`-`$6FFF` (`ViewCells+32`); `$A900`-`$B1FF` (`work space $A900+`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 3 more ranges |

### `RedrawSkip` (`$77D6`)

**RedrawSkip**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,832 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 17,499 calls (`stage1/rec/rzx-l4-08000-poke` 8,113, `stage1/rec/rzx-l5-06000-poke` 5,242, `stage1/rec/rzx-l4-16000-poke` 4,144) |
| Called from | `RedrawScrolledView` (falls into), `RedrawCopyCell` (tail) |
| Calls | `RedrawScrolledView` (tail) |

### `RedrawLevelCell` (`$77F2`)

**RedrawLevelCell**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 6,485 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 13,688 calls (`stage1/rec/rzx-l4-08000-poke` 6,619, `stage1/rec/rzx-l5-06000-poke` 3,906, `stage1/rec/rzx-l4-16000-poke` 3,163) |
| Called from | `RedrawScrolledView` (tail) |
| Calls | `RedrawCopyCell` (falls into) |
| Reads | `$B100`-`$B1FC` (`work space $B100+`) |
| Writes | `$5820`-`$5AFF` (screen) |

### `RedrawCopyCell` (`$7803`)

**RedrawCopyCell**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 6,909 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 14,518 calls (`stage1/rec/rzx-l4-08000-poke` 6,924, `stage1/rec/rzx-l5-06000-poke` 4,193, `stage1/rec/rzx-l4-16000-poke` 3,401) |
| Called from | `RedrawLevelCell` (falls into), `RedrawSpareCell` (tail) |
| Calls | `RedrawSkip` (tail) |
| Reads | `$5E00`-`$6097` (`SpareCells+24`); `$A900`-`$B0E7` (`work space $A900+`) |
| Writes | `$4020`-`$40FF` (screen); `$4120`-`$41FF` (screen); `$4220`-`$42FF` (screen); `$4320`-`$43FF` (screen); `$4420`-`$44FF` (screen); `$4520`-`$45FF` (screen); 2 more ranges |

### `RedrawSpareCell` (`$7827`)

**RedrawSpareCell**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 424 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 830 calls (`stage1/rec/rzx-l4-08000-poke` 305, `stage1/rec/rzx-l5-06000-poke` 287, `stage1/rec/rzx-l4-16000-poke` 238) |
| Called from | `RedrawScrolledView` (tail) |
| Calls | `RedrawCopyCell` (tail) |
| Reads | `$6B35`-`$6B57` (`ViewCells+53`); `$6B77`-`$6B90` (`ViewCells+119`); `$6BAF`-`$6BF9` (`ViewCells+175`); `$6C31`-`$6CFA` (`ViewCells+305`); `$6D28`-`$6EB0` (`ViewCells+552`); `$6EC3`-`$6EE6` (`ViewCells+963`); 10 more ranges |
| Writes | `$5828`-`$5AF4` (screen) |

### `SetViewAttrs` (`$783F`)

**Set the attributes of screen rows 1-23 from the view's cells**

ScreenAttrs + 32 onwards = CellAttrs[ViewCells from `$6C20`], 736 cells (224 + 256 + 256 in three loops on A'). Called by RedrawView `$7965` only: 97 runs in 43 builds.

Witness: L1 279 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 302,887 t-states own (0.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 143,745 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 47,458 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 95,494 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 52,619 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 99,451 t-states own (0.11 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 14 calls, 702,437 t-states own (0.04 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 103,350 t-states own (0.16 %) |
| Runs (the other recordings) | 118 calls (`stage1/rec/rzx-l3-04000-poke` 7, `stage2/rec/c48` 6, `stage1/rec/rzx-l4-10000-poke` 6 and 55 more) |
| Called from | `RedrawView` |
| Reads | `$6C20`-`$6EFF` (`ViewCells+288`); `$B100`-`$B1FF` (`work space $B100+`) |
| Writes | `$5820`-`$5AFF` (screen) |

### `MarkScrollCells` (`$786B`)

**Before a scroll: mark for restoring the cells the sprites' copies will lie on**

DE = +32 (down) or -32 (up); the caller's HL (ScrollUp loads DirtyMap + 256) is dead: the routine starts with LD HL,DirtyMap. For each of the 1024 DirtyMap bytes from `$6600` >= 2 (a spare cell on the screen) it sets to 1 the bytes 2, 6 and 8 rows on, when 0: the screen positions of that cell after each step of the scroll, so RedrawScrolledView redraws the level cell there. Going up, a spare cell in view rows 0-7 marks below `$6600`, in MirrorTable; only its 0 byte `$6500` can be written (from row 0, column 0), and no recording writes it.

Called by ScrollDown `$78B1` and ScrollUp `$7911`: 183 runs in 52 builds (95 + 88).

Witness: L1 366 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 4 calls, 335,309 t-states own (0.02 %) |
| Runs (the other recordings) | 179 calls (`stage1/rec/rzx-l5-08000-poke` 10, `stage1/rec/rzx-l1-10000-poke` 9, `stage1/rec/rzx-l3-00000-poke` 7 and 48 more) |
| Called from | `ScrollDown`, `ScrollUp` |
| Calls | `MarkScrollScan` (falls into) |
| Reads | `$6504`-`$6AFB` (`MirrorTable+4`, `DirtyMap`) |
| Writes | `$6600`-`$6AFB` (`DirtyMap`) |

### `MarkScrollScan` (`$7872`)

**MarkScrollScan**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 4,096 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,536 calls (`stage1/rec/rzx-l2-14000-poke` 4,536) |
| Called from | `MarkScrollCells` (falls into), `MarkScrollNext` (tail) |
| Calls | `MarkScrollNext` (falls into), `MarkScrollCell` (tail) |
| Reads | `$6600`-`$69FF` (`DirtyMap`) |

### `MarkScrollNext` (`$7876`)

**MarkScrollNext**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 4,096 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,537 calls (`stage1/rec/rzx-l2-14000-poke` 4,537) |
| Called from | `MarkScrollScan` (falls into), `MarkScrollCell` (tail) |
| Calls | `MarkScrollScan` (tail) |

### `MarkScrollCell` (`$787E`)

**MarkScrollCell**

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2,854 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,682 calls (`stage1/rec/rzx-l2-14000-poke` 2,682) |
| Called from | `MarkScrollScan` (tail) |
| Calls | `MarkScrollNext` (tail) |
| Reads | `$6664`-`$66B7` (`DirtyMap+100`); `$66E4`-`$67B2` (`DirtyMap+228`); `$67E3`-`$68BB` (`DirtyMap+483`); `$68E3` (`DirtyMap+739`); `$68F4`-`$6AB7` (`DirtyMap+756`); `$6AD5`-`$6AD7` (`DirtyMap+1237`) |
| Writes | `$6672`-`$66B7` (`DirtyMap+114`); `$66E4`-`$67B2` (`DirtyMap+228`); `$67E3`-`$6812` (`DirtyMap+483`); `$6823`-`$68BB` (`DirtyMap+547`); `$68F4`-`$6923` (`DirtyMap+756`); `$6934`-`$6AB7` (`DirtyMap+820`); 1 more ranges |

### `ScrollDown` (`$78A5`)

**Move the view 8 cell rows down the section in three steps**

The main loop `$7E06` calls it when Rick's y (`$9BAD`) >= 204 and the view's top `$88CF` < its limit `$88D2`. Clears the marks (`$8985`), composes the sprites (`$85FA`), marks their cells (MarkScrollCells), then redraws the screen from 2, 6 and 8 rows lower (RedrawScrolledView), each after a frame wait (C = 1). Then `$88CF` += 8, the view is rebuilt (`$88D4`), every object moved 64 pixels up (`$9E31`, BC = -64), and the sprites composed and drawn again. So a scroll is three steps; measured, it takes 16 frames (rzx-l1-04000-poke frames 111-127, ScrollUp): the steps are 265 696 to 296 920 T apart, each RedrawScrolledView about four frames, so each one-count frame wait returns at once.

95 runs in 34 builds (81 in 30 RZX pieces, 14 in sec-l4-*).

Witness: L1 190 (rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-18000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 95 calls (`stage1/rec/rzx-l4-06000-poke` 7, `stage1/rec/rzx-l1-10000-poke` 7, `stage2/rec/sec-l4-s11` 6 and 31 more) |
| Called from | `MainLoopPause` |
| Calls | `DrawChangedCells`, `RedrawScrolledView`, `MarkScrollCells`, `WaitFrames`, `DrawSprites`, `BuildView`, `ClearRedraw`, `ShiftObjects` |
| Reads | `$88CF` (`ViewTopRow`) |
| Writes | `$88CF` (`ViewTopRow`) |

### `ScrollUp` (`$7905`)

**Move the view 8 cell rows up the section in three steps**

As ScrollDown, the other way: the main loop `$7DEB` calls it when Rick's y (`$9BAD`) < 96 and `$88CF` > 0; redraws from 2, 6 and 8 rows higher, `$88CF` -= 8, the objects moved 64 pixels down (`$9E31`, BC = 64). 88 runs in 34 builds.

Witness: L1 176 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full).

[Animation: `ScrollUp` at work](img/routines/ScrollUp.gif)

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 4 calls, 2,210 t-states own (0.00 %) |
| Runs (the other recordings) | 84 calls (`stage1/rec/rzx-l3-00000-poke` 7, `stage1/rec/rzx-l2-02000-poke` 5, `stage1/rec/rzx-l2-20000-poke` 5 and 30 more) |
| Called from | `MainLoopPause` |
| Calls | `DrawChangedCells`, `RedrawScrolledView`, `MarkScrollCells`, `WaitFrames`, `DrawSprites`, `BuildView`, `ClearRedraw`, `ShiftObjects` |
| Reads | `$88CF` (`ViewTopRow`) |
| Writes | `$88CF` (`ViewTopRow`) |

### `RedrawView` (`$7965`)

**Draw the whole view: mark every cell, draw, set the attributes**

`$8969` (marks the DirtyMap for a full redraw), DrawChangedCells `$76D4`, SetViewAttrs `$783F`. Called by the section start (`$8B2D`, `$8B34`): 97 runs in 43 builds, a few per recording (c1 6).

Witness: L1 279 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 418 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 239 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 84 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 135 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 61 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 169 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 14 calls, 1,015 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 122 t-states own (0.00 %) |
| Runs (the other recordings) | 118 calls (`stage1/rec/rzx-l3-04000-poke` 7, `stage1/rec/rzx-l4-10000-poke` 6, `stage2/rec/c48` 6 and 55 more) |
| Called from | `SetupSection` |
| Calls | `DrawChangedCells`, `SetViewAttrs`, `RedrawAll` |

### `ClearScreen` (`$7A61`)

**Clear the bitmap and set every attribute to `$47` (bright white on black)**

Callers: the level menu `$7F47`, the tape loader `$840C`, `$8427`, `$84FF` and the text printer `$88C4`. 47 runs in 13 builds.

Witness: L1 180 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l3-10000-poke, rzx-l4-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 3 calls, 561,059 t-states own (0.04 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 5 calls, 935,587 t-states own (0.09 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 6 calls, 1,117,336 t-states own (0.08 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 7 calls, 1,299,194 t-states own (0.07 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 8 calls, 1,477,443 t-states own (0.06 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 376,625 t-states own (0.41 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 6 calls, 1,136,255 t-states own (0.06 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 191,115 t-states own (0.08 %) |
| Runs (the other recordings) | 68 calls (`stage2/rec/sec-l4-s1` 3, `stage2/rec/sec-l4-s12` 3, `stage2/rec/sec-l2-s7` 3 and 23 more) |
| Called from | `LevelMenu`, `LoadLevel`, `LdBytes` (tail), `FontCellsMode` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `LevelCellsMode` (`$7EB3`)

**The cell drawer back to the level's cells**

Writes `$A900` (CellGraphics) to the drawer's two bases `$7730` and `$7777` and JP M,`$77A2` back at `$775A`. The same code ends LevelMenu (`$7FB2`).

Evidence: 3 runs in 2 builds (controls-keyboard 1, rzx-l5-full 2): after GAME OVER (`$7EAD`).

Witness: L1 40 (controls-keyboard, rzx-l5-full, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 196 t-states own (0.00 %) |
| Runs (the other recordings) | 18 calls (`stage1/controls-keyboard` 1, `stage2/rec/sec-l2-s10` 1, `stage2/rec/sec-l2-s11` 1 and 15 more) |
| Called from | `MainLoopPause` |
| Writes | `$7730`-`$7731` (`DrawLevelCellBase+1`); `$775A`-`$775C` (`ComposeCellFrontTest`); `$7777`-`$7778` (`ComposeCellBase+1`) |

### `DrawSprites` (`$85FA`)

**Compose every sprite of the pass into the view**

The composed cells from 2 (`$77B0`). The blitter `$7329` for the record `$9BB4` when its +0 is set, for Rick (`$9BAB`), for `$9BBD`, then for every used record of table B (from `$7C20`, 23 bytes each) and of table A (from `$7B8F`, 24 bytes each), until their end marks.

Evidence: called by MainLoopPause every pass, by the scrolls `$78A5` and `$7905` and the section setup `$8A6D`.

Witness: L1 121734 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,125 calls, 1,089,092 t-states own (0.08 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 294 calls, 329,131 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 280 calls, 292,772 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 319 calls, 343,732 t-states own (0.02 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 286 calls, 308,550 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 490 calls, 467,646 t-states own (0.50 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,953 calls, 9,552,371 t-states own (0.51 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 869 calls, 872,555 t-states own (0.62 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 290 calls, 323,133 t-states own (0.51 %) |
| Runs (the other recordings) | 49,722 calls (`stage2/rec/c48` 1,218, `stage1/rec/rzx-l1-14000-poke` 921, `stage1/rec/rzx-l1-06000-poke` 832 and 78 more) |
| Called from | `ScrollDown`, `ScrollUp`, `MainLoopPause`, `SetupSection` |
| Calls | `ComposeSprite` |
| Reads | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 6 more ranges |
| Writes | `$77B0` (`SpareCount`) |

### `FontCellsMode` (`$88B1`)

**The cell drawer on the font; screen and buffers cleared**

Writes `$7080` (the font) to the drawer's bases `$7730` and `$7777` and three zeros (NOPs) over the JP M at `$775A`, then `$7A61`, `$8985`, `$8977`. HL kept.

Evidence: 16 runs in 11 builds (callers LevelMenu, ControlMenu, ShowEndText).

Witness: L1 102 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 2 calls, 362 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 174 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 174 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 174 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 174 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 176 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 4 calls, 699 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 166 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage2/rec/c48` 2, `stage2/rec/sec-l4-s1` 2, `stage2/rec/sec-l4-s12` 2 and 21 more) |
| Called from | `LevelMenu`, `ControlMenu`, `ShowEndText` |
| Calls | `ClearScreen`, `BlankView`, `ClearRedraw` |
| Writes | `$7730`-`$7731` (`DrawLevelCellBase+1`); `$775A`-`$775C` (`ComposeCellFrontTest`); `$7777`-`$7778` (`ComposeCellBase+1`) |

## interrupt

`src/game/interrupt.asm`

### `WaitFrames` (`$7A53`)

**Enable interrupts, wait until FrameCounter >= C, clear it**

C = the frames: 2 the main loop `$7D8B` (51 600), 1 the scroll steps, 10, 15, 20 the menus and texts (`$7E9D`, `$8150`, `$82E4`, `$8743`, `$8784`). 63 583 runs in 68 builds.

Witness: L1 187571 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 3,419 calls, 161,335,977 t-states own (12.03 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 542 calls, 10,945,003 t-states own (1.11 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 532 calls, 25,446,496 t-states own (1.78 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 569 calls, 16,303,701 t-states own (0.86 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 537 calls, 26,496,088 t-states own (1.14 %) |
| Runs (controls-kempston: the Kempston method in play) | 800 calls, 46,555,309 t-states own (50.12 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 11,000 calls, 681,971,767 t-states own (36.63 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 869 calls, 61,329,892 t-states own (43.25 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 3,097 calls, 155,340,485 t-states own (67.26 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 285 calls, 14,292,572 t-states own (22.40 %) |
| Runs (the other recordings) | 76,796 calls (`stage2/rec/c48` 3,722, `stage2/rec/end-congrats` 2,454, `stage1/rec/rzx-l5-24000-poke` 2,001 and 80 more) |
| Called from | `ScrollDown`, `ScrollUp`, `MainLoopPause`, `ControlMenuLoop`, `DropTextWait`, `TallyLives`, `EndTextWait` |
| Reads | `$7A60` (`FrameCounter`); `$FDFF`-`$FE00` (`work space $FDFF+`) |
| Writes | `$7A60` (`FrameCounter`) |

### `CallRam1` (`$7A77`)

**Call HL in RAM 1 with A, interrupts off; nothing on a 48K**

Stores A and HL into its own LD A,n and CALL nn, returns at once when Machine48K is set, else DI, port `$7FFD` = `$11` (RAM 1 at `$C000`, ROM 1), the call, `$7FFD` = `$10` (RAM 0). Interrupts stay off: the IM 2 handler's EI or the next WaitFrames puts them back. 133 677 runs in 68 builds: MusicFrameCall 127 035, PlayEffect 6585, StartTune 57.

Witness: L1 336977 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 4,872 calls, 728,192 t-states own (0.05 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,165 calls, 319,536 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2,709 calls, 398,467 t-states own (0.03 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3,429 calls, 505,015 t-states own (0.03 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3,868 calls, 568,642 t-states own (0.02 %) |
| Runs (controls-kempston: the Kempston method in play) | 1,341 calls, 199,296 t-states own (0.21 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 21,349 calls, 3,170,599 t-states own (0.17 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,821 calls, 270,462 t-states own (0.19 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 3,259 calls, 479,073 t-states own (0.21 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 601 calls, 88,749 t-states own (0.14 %) |
| Runs (the other recordings) | 131,598 calls (`stage2/rec/end-congrats` 2,584, `stage2/rec/sec-l2-s10` 2,439, `stage2/rec/sec-l3-s4` 2,439 and 80 more) |
| Called from | `PlayEffect`, `StartTune`, `MusicFrameCall` |
| Reads | `$7A76` (`Machine48K`) |
| Writes | `$7A8B`-`$7A8E` (`CallRam1Arg+1`, `CallRam1Call`) |
| Ports out | `$7FFD` |

### `PlayEffect` (`$7A97`)

**Start sound effect A: the RAM 1 music's effect, or the beeper's on a 48K**

Keeps AF, HL, BC. On a 128K CallRam1 with MusicEffect `$CCC8`; on a 48K SelectBeeperEffect `$7ADA` (effects 0-10). Callers: `$937A`, `$9386`, `$93E7`, `$95A8`, `$9AA5` (4445), `$9F67`, `$A2F2`, `$A58F`, `$A5A2`, `$A5B2`, `$8C59`, the ending's tally `$873E`, and level 5's own code (`$F956`, `$F969`, `$F96E`). 6585 runs in 66 builds.

Witness: L1 13756 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s12, sec-l3-s7, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 163 calls, 28,626 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 22 calls, 3,436 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 19 calls, 2,595 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 23 calls, 3,425 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 22 calls, 2,970 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 34 calls, 6,154 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 937 calls, 144,619 t-states own (0.01 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 76 calls, 11,280 t-states own (0.01 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 5 calls, 675 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 7 calls, 1,077 t-states own (0.00 %) |
| Runs (the other recordings) | 5,773 calls (`stage1/rec/rzx-l1-10000-poke` 168, `stage1/rec/rzx-l1-00000-poke` 165, `stage1/rec/rzx-l1-04000-poke` 161 and 71 more) |
| Called from | `TallyLives`, `TestEnemyHits`, `BurnFuse`, `KillRick`, `FireBullet`, `PickRickSprite`, `KillEnemy`, `TrapEffect` (tail), `UpdatePickup` |
| Calls | `CallRam1`, `SelectBeeperEffect` (tail) |
| Reads | `$7A76` (`Machine48K`) |

### `StartTune` (`$7AAD`)

**Start tune A in the RAM 1 music**

CallRam1 with MusicStartTune `$CA27`, keeps HL. The tunes: 0 the menu (`$80B9`) and the CONGRATULATIONS end (`$875D`), 1 a signal (the time bonus `$9CC6` / `$9CDB`, both cheats), 2 GAME OVER (`$7E20`), 4 the tape load (`$7CD2`), 5-9 levels 1-5 (LevelTune `$7CE3`: Level + 4), 10 the Fat Guy's end (`$874B`). Callers: the level start (`$7CD2`, `$7CE3`), the game's end `$7E20` (A = 2), the menu `$80B9`, the ending `$874B`, `$9CC6`, `$9CDB`, and the cheat keys (`$7D3B`, `$7D55`: A = 1). 57 runs in 34 builds.

Witness: L1 263 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, rzx-l1-00000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 3 calls, 217 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 128 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2 calls, 122 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 142 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 180 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 58 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8 calls, 640 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 58 t-states own (0.00 %) |
| Runs (the other recordings) | 118 calls (`stage2/rec/cheats` 6, `stage2/rec/sec-l4-s6` 4, `stage2/rec/sec-l4-s12` 4 and 46 more) |
| Called from | `LevelStart`, `LevelTune`, `CheatInfiniteKeys`, `CheatExitsKeys`, `MainLoopPause`, `ControlMenu`, `TallyLives`, `Congratulations`, `SpawnFromMap` |
| Calls | `CallRam1` |

### `MusicFrameCall` (`$7AB6`)

**Run the RAM 1 music player for this frame**

CallRam1 with MusicFrame `$CAAF`, keeps HL. Called by the IM 2 handler `$FF14` every interrupt: 127 035 runs in 68 builds (c1 4706).

Witness: L1 323115 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 4,706 calls, 272,948 t-states own (0.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,141 calls, 124,178 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2,688 calls, 155,904 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3,404 calls, 197,432 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3,844 calls, 222,952 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 1,306 calls, 75,748 t-states own (0.08 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 20,404 calls, 1,183,432 t-states own (0.06 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,745 calls, 101,230 t-states own (0.07 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 3,253 calls, 188,674 t-states own (0.08 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 594 calls, 34,452 t-states own (0.05 %) |
| Runs (the other recordings) | 125,864 calls (`stage2/rec/end-congrats` 2,579, `stage2/rec/sec-l2-s10` 2,435, `stage2/rec/sec-l3-s3` 2,435 and 79 more) |
| Calls | `CallRam1` |

### `Random` (`$81AF`)

**A pseudo-random byte from the tick count: A and RandomValue**

HL = RandomValue + Ticks (low word) + 13 + Ticks (high word) with the carry; A (as given) XOR L XOR D XOR E XOR H becomes L; HL stored in RandomValue; A is the result. HL and DE kept.

Evidence: 1018 runs in 21 builds (callers `$A010` x999, `$A016` x995, `$A048` x19, `$A05F` x18).

Witness: L1 3010 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, c48, load-l2, load-l3, sec-l2-s7, sec-l2-s12, sec-l3-s5, sec-l4-s12, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 85 calls, 16,235 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 31 calls, 5,921 t-states own (0.00 %) |
| Runs (the other recordings) | 1,453 calls (`stage2/rec/sec-l3-s5` 234, `stage1/rec/rzx-l4-18000-poke` 173, `stage1/rec/rzx-l1-24000-poke` 164 and 22 more) |
| Called from | `EnemyWanderer`, `EnemyChaser` |
| Reads | `$81CE`-`$81D3` (`RandomValue`, `Ticks`) |
| Writes | `$81CE`-`$81CF` (`RandomValue`) |

### `CountTicks` (`$81D4`)

**Ticks + 1 (32 bits); called by the IM 2 handler**

The low word + 1; when it wraps to 0 the high word + 1.

Evidence: 127 035 runs in 68 builds, every call from `$FF0E` (the handler at `$FEFE`: the copy of `$7C49`); c1 4706.

Witness: L1 328217 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 4,706 calls, 268,242 t-states own (0.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,141 calls, 122,037 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2,688 calls, 153,216 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3,404 calls, 194,028 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3,844 calls, 219,108 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 1,306 calls, 74,442 t-states own (0.08 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 20,404 calls, 1,163,028 t-states own (0.06 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,745 calls, 99,465 t-states own (0.07 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 3,253 calls, 185,421 t-states own (0.08 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 594 calls, 33,858 t-states own (0.05 %) |
| Runs (the other recordings) | 130,966 calls (`stage2/rec/c48` 5,102, `stage2/rec/end-congrats` 2,579, `stage2/rec/sec-l2-s10` 2,435 and 80 more) |
| Reads | `$81D0`-`$81D3` (`Ticks`) |
| Writes | `$81D0`-`$81D3` (`Ticks`) |

## sound

`src/game/sound.asm`

### `ReadMusicByte` (`$7ABF`)

**Read the RAM 1 music's byte `$C9CF` (A, flags of AND A); nothing on a 48K**

Not executed in any recording and called from nowhere in the image (`$6000-$FEFD` holds no CALL or JP to `$7ABF`). Pages RAM 1 in like CallRam1 and returns the byte `$C9CF` of the music (perhaps "a tune is playing"), interrupts left off.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SelectBeeperEffect` (`$7ADA`)

**48K: PlayEffect's other half, the note pointer at `$7B67` = BeeperEffectTable[A] for A < 11**

Reached from PlayEffect `$7AA0` when Machine48K is set; ends with PlayEffect's POP BC, POP HL, POP AF, RET.

Evidence: c48 (the 48K load and play, stage 2) 157 runs: every effect the play started.

Witness: L1 157 (c48).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 157 calls (`stage2/rec/c48` 157) |
| Called from | `PlayEffect` (tail) |

### `PlayBeeperStep` (`$7B66`)

**48K: play the next note of the current beeper effect, if any**

Called by the main loop `$7D86` each pass when Machine48K is set. The note pointer (the LD HL operand at `$7B67`, set by SelectBeeperEffect) is 0 at the start: the first passes on a 48K would play the ROM's bytes at `$0000` (`$F3`, `$AF`, `$11`) until its `$FF` at `$0003`. The note: C = the byte, then port `$FE` = `$08` / `$00` (MIC bit, black border) toggled every C turns of a DE = `$600` countdown, about 49 000 T: most of a frame per pass. c48 runs it: 1206 runs (docs/09-sound.md 9.11).

Evidence: c48 1206 runs, one a main loop pass after the game started (no other recording is a 48K).

Witness: L1 1206 (c48).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 1,206 calls (`stage2/rec/c48` 1,206) |
| Called from | `MainLoopPause` |
| Ports out | `$00FE`, `$08FE` |

## setup

`src/game/setup.asm`

### `Entry` (`$7B8F`)

**The game's entry: SP, the IM 2 handler, the 128K test (later the first object table)**

Called by the loader (`$FF2A`, JP) once, with the interrupts on (the loader's EI at `$FF29`); its first DI turns them off. SP = 0 (the stack grows down over the loader's tail), SetupIm2 copies the handler and sets IM 2. Then the 128K test: E = the byte at `$C000` with RAM 0 paged in; RAM 1 is paged in (port `$7FFD` = `$11`: ROM 1, RAM 1), E + 1 written to `$C000`, RAM 0 paged back (`$10`) and `$C000` read again. The same value as before means the write went to another bank: a 128K, go to CopyMusic. Otherwise the machine has one bank there: Entry48K puts the byte back, sets `$7A76` = `$FF` (no music) and skips the copy.

From `$83B8` on, the bytes from here are the object table A (six 24-byte records, updated by `$A2F7` from UpdateObjects, drawn by `$7329` from DrawSprites, +0 = 0 a free record, `$FF` at `$7C1F` the end) and the falling letters of DropText (8-byte records, see BuildLetters).

Evidence: c1 runs it once at frame 13 998 (the L1: reads `$C000` and `$6000-$707F`, writes `$C000-$D07F` in RAM 1, `$FF14-$FF16`, `$6500-$65FF`, ports `$7FFD` and `$FE`). The 48K branch Entry48K is not executed in any recording (every recording is a 128K).

Witness: L1 2 (c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 596,149 t-states own (0.04 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/c48` 1) |
| Calls | `SetupIm2` |
| Reads | `$6000`-`$707F` (`MirrorTable`, `DirtyMap`, `ViewCells`); `$C000` (`work space $C000+`) |
| Writes | `$6500`-`$65FF` (`MirrorTable`); `$FF14`-`$FF16` (`work space $FF14+`) |
| Ports out | `$00FE`, `$7FFD` |

### `Entry48K` (`$7BB3`)

**The 48K branch of the entry**

The code bytes of the 48K case: LD A,E / LD (`$C000`),A puts the test byte back (on a 48K the write went to the only bank), LD A,`$FF` / LD (`$7A76`),A turns the music off (the RAM 1 calls at `$7A77` return at once), JP `$7BF0` skips the music copy and the handler patch (the handler keeps its three NOPs at `$FF14`) and goes on with the bit-reverse table. Kept as bytes: no recording ran it, and the object tables write over it, so the walk takes it for data. A 48K run would settle it.

Evidence: c48 once, at the entry after side A (the 48K load).

Witness: L1 1 (c48).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 1 run of its first instruction, entered by a jump (`stage2/rec/c48` 1) |

### `CopyMusic` (`$7BBF`)

**128K: copy the music to RAM 1, patch the handler to call the player, build the mirror table**

Copies the 4224 bytes `$6000-$707F` (the AY music as loaded) to `$C000-$D07F` in RAM 1, one byte at a time: the byte read with RAM 0 in, RAM 1 paged in (`$7FFD` = `$11`) for the write, RAM 0 back (`$10`); the source and destination pointers and the port are kept in the alternate registers. Then writes CALL `$7AB6` over the three NOPs at `$FF14-$FF16` of the IM 2 handler, so every interrupt runs the music player (through `$7A77`, which pages RAM 1 in). The 48K path joins at `$7BF0`: the 256-byte table at `$6500`, entry n = n with its bits reversed (the sprite blitter `$7329` mirrors sprites through it, LD H,`$65`). Border black, EI, then the control menu (NewGame).

Evidence: c1, once (writes `$C000-$D07F` in page 1, `$FF14-$FF16`, `$6500-$65FF`).

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Calls | `NewGame` (tail) |

### `SetupIm2` (`$7C1A`)

**Copy the IM 2 handler to `$FEFE`, fill the vector table, IM 2**

Copies the 35 bytes of Im2HandlerSource (`$7C39`) to `$FEFE-$FF20`, fills `$FD00-$FE00` (257 bytes) with `$FE`, sets I = `$FD` and IM 2: whatever byte the bus holds, the vector read is `$FEFE`. Returns with interrupts off (DI); Entry enables them at the end of CopyMusic.

Evidence: c1, once, called from `$7B93` (reads `$7C39-$7C5B`, writes `$FD00-$FE00` and `$FEFE-$FF20`).

Witness: L1 2 (c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 8,823 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage2/rec/c48` 1) |
| Called from | `Entry` |
| Reads | `$7C39`-`$7C5B` (`Im2HandlerSource`) |
| Writes | `$FD00`-`$FE00` (`work space $FD00+`); `$FEFE`-`$FF20` (`work space $FEFE+`) |

## mainloop

`src/game/mainloop.asm`

### `NewGame` (`$7C7D`)

**A new game: the control menu, then the level menu**

Shows the control menu (ControlMenu) and returns when 0 (START GAME) is pressed; falls into ChooseLevel. Reached from CopyMusic once after the load and from GAME OVER (`$7EB0`) after every game.

Evidence: c1 1, controls-keyboard 1, rzx-l5-full 2 (the start and the two GAME OVERs of the RZX level 5 run).

Witness: L1 42 (controls-keyboard, rzx-l5-full, c1, c48, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 112 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 192 t-states own (0.00 %) |
| Runs (the other recordings) | 19 calls (`stage2/rec/sec-l5-s3` 1, `stage2/rec/sec-l4-s11` 1, `stage2/rec/sec-l3-s5` 1 and 16 more) |
| Called from | `CopyMusic` (tail), `MainLoopPause` (tail) |
| Calls | `ControlMenu` |

### `ChooseLevel` (`$7C80`)

**The level menu**

LevelMenu: the level chosen goes to Level (`$7EF1`). Falls into StartGame.

Evidence: 11 runs in 10 builds (c1, the four controls-*, the four load-*, rzx-l5-full 2).

Witness: L1 56 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 106 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 106 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 86 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 124 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 104 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 23 runs of its first instruction, entered by a jump (`docs/rec/box-shot` 1, `stage1/controls-cursor` 1, `stage1/controls-keyboard` 1 and 20 more) |
| Calls | `LevelMenu` |

### `StartGame` (`$7C83`)

**Clear the object tables, reset the sections' objects, start the game**

ClearObjectTables, ResetSectionObjects (bit 7 of every object record of every section cleared), then ResetGame, which runs the levels to GAME OVER and never returns.

Evidence: 12 runs in 11 builds.

Witness: L1 58 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 24 runs of its first instruction, entered by a jump (`docs/rec/box-shot` 1, `stage1/controls-cursor` 1, `stage1/controls-keyboard` 1 and 21 more) |
| Calls | `ResetGame`, `ResetSectionObjects`, `ClearObjectTables` |

### `RestartJump` (`$7C8C`)

**JP NewGame after ResetGame**

JP `$7C7D`, back to the control menu: ResetGame never returns (GAME OVER jumps to NewGame itself), so this is not executed in any recording; the static walk takes it as the code after StartGame's CALL.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ResetGame` (`$7CAD`)

**A new game's state: score 0, levels done 0, six lives; then the levels**

Score (`$7F1D-$7F22`) = 0, LevelsDone (`$7EF2`) = 0, `$8A24` = 0 (the level 5 code hooks off), lives (`$8B3B`) = 6. Falls into LevelStart and the main loop; never returns (GAME OVER goes to NewGame).

Evidence: 12 runs in 11 builds, called from StartGame (`$7C89`).

Witness: L1 58 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 4,055,585 t-states own (0.30 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 152,550 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 157,002 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 170,809 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 159,262 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 315,009 t-states own (0.34 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 446 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/controls-keyboard` 1, `stage2/rec/c48` 1, `stage1/rec/rzx-l1-00000-poke` 1 and 21 more) |
| Called from | `StartGame` |
| Reads | `$486A`-`$48B4` (screen); `$496A`-`$49B4` (screen); `$4A6A`-`$4AB4` (screen); `$4B6A`-`$4BB4` (screen); `$4C6A`-`$4CB4` (screen); `$4D6A`-`$4DB4` (screen); 14 more ranges |
| Writes | `$486A`-`$48B5` (screen); `$496A`-`$49B5` (screen); `$4A6A`-`$4AB5` (screen); `$4B6A`-`$4BB5` (screen); `$4C6A`-`$4CB5` (screen); `$4D6A`-`$4DB5` (screen); 15 more ranges |

### `LevelStart` (`$7CC5`)

**Start the level in Level: from tape when another is in memory**

When Level (`$7EF1`) differs from LevelNumber (`$C20C`, the level in memory): tune 4 (`$7AAD`), `$9BEB`, LoadLevel (the tape messages and side B until the wanted level's block is in), then DecryptLevel. Reached from ResetGame and from MainLoop after a level's end (`$7DD0`).

Evidence: 14 runs in 13 builds; the tape branch in the load-l2 ... load-l5 recordings and rzx-l3-10000-poke, rzx-l4-20000-poke (the RZX run's own loader, a TAP version at `$846A`).

Witness: L1 62 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l3-10000-poke, rzx-l4-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 calls (`stage1/rec/rzx-l4-20000-poke` 1, `stage1/rec/rzx-l3-10000-poke` 1) |
| Called from | `MainLoopPause` (tail) |
| Calls | `StartTune`, `LevelTune` (tail), `LoadLevel`, `FreeAllObjects` |
| Reads | `$7EF1` (`Level`); `$C20C` (`work space $C20C+`) |

### `DecryptLevel` (`$7CDB`)

**Decrypt the new level's last 768 bytes of maps**

CALL `$894E` (the maps' cipher). Then LevelTune.

Evidence: 9 runs in 9 builds (load-l2 ... load-l5, rzx-l2/l3/l4/l5-00000-poke, rzx-l5-full).

Witness: L1 50 (life-up, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 17 t-states own (0.00 %) |
| Runs (the other recordings) | 22 runs of its first instruction, entered by a jump (`docs/rec/life-up` 1, `stage1/rec/rzx-l2-00000-poke` 1, `stage1/rec/rzx-l3-00000-poke` 1 and 19 more) |
| Calls | `DecryptMaps` |
| Reads | `$7A76` (`Machine48K`); `$7C95`-`$7CAC` (`LevelStarts+6`); `$7EF1` (`Level`); `$88CF`-`$88D3` (`ViewTopRow`, `ViewMap`, `ViewLastRow`, `ExitDirection`); `$8B3B` (`Lives`); `$9B9B`-`$9B9C` (`DeathFallOver`, `RickDying`); 1 more ranges |
| Writes | `$88D3` (`ExitDirection`); `$8B3B`-`$8B3D` (`Lives`, `Ammunition`, `Detonators`); `$945D` (`RideMode`); `$9B98`-`$9B99` (`RickCrawling`, `RickClimbing`); `$9BB1` (`RickFacing`) |

### `LevelTune` (`$7CDE`)

**The level's tune; a life back when fewer than six**

Tune Level + 4 (`$7AAD`: 5 to 9). When lives (`$8B3B`) are not 6, AddLife adds one.

Evidence: 17 runs in 15 builds; lives were 6 at every level start of the recordings (c1 starts a game, the RZX pieces have the infinite lives POKE), so AddLife is not executed in any recording.

Witness: L1 104 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, life-up, rzx-l1-00000-poke, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 5,124,103 t-states own (0.28 %) |
| Runs (the other recordings) | 17 calls (`stage2/rec/sec-l3-s3` 1, `stage2/rec/sec-l3-s4` 1, `stage2/rec/sec-l2-s10` 1 and 14 more) |
| Called from | `LevelStart` (tail) |
| Calls | `StartTune` |
| Reads | `$486A`-`$48B4` (screen); `$496A`-`$49B4` (screen); `$4A6A`-`$4AB4` (screen); `$4B6A`-`$4BB4` (screen); `$4C6A`-`$4CB4` (screen); `$4D6A`-`$4DB4` (screen); 13 more ranges |
| Writes | `$486A`-`$48B5` (screen); `$496A`-`$49B5` (screen); `$4A6A`-`$4AB5` (screen); `$4B6A`-`$4BB5` (screen); `$4C6A`-`$4CB5` (screen); `$4D6A`-`$4DB5` (screen); 12 more ranges |

### `AddLife` (`$7CEE`)

**INC A / LD (`$8B3B`),A: one life more at a level start**

The code bytes INC A / LD (`$8B3B`),A: lives + 1 when they are below 6. Only life-up runs it (1 run): a POKE, said so, of Lives = 3 at the RZX's level 5 "STOP TAPE AND PRESS FIRE", then fire; the level starts with 4 lives. Every other level start had six lives.

Witness: L1 2 (life-up).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 1 run of its first instruction, entered by a jump (`docs/rec/life-up` 1) |

### `LevelSetup` (`$7CF2`)

**Ammunition and detonators 6, Rick's start record, the first section**

Ammunition (`$8B3C`) and detonators (`$8B3D`) = 6, `$945D`, `$9B99`, `$9B98` = 0. IX = LevelStarts + 6 x (Level - 1): `$9BB1` = +5; A = +0 the section, C = +1 the top row, E = +2 x, HL = +3/+4 y, then the section setup `$8A6D`. Falls into MainLoop.

Evidence: 17 runs in 15 builds.

Witness: L1 104 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, life-up, rzx-l1-00000-poke, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 46 runs of its first instruction, entered by a jump (`stage2/rec/sec-l2-s10` 2, `stage2/rec/sec-l2-s11` 2, `stage2/rec/sec-l2-s12` 2 and 26 more) |
| Calls | `SetupSection` |

### `MainLoop` (`$7D2D`)

**The main loop: quit, cheats, pause, the pass's work, the frame wait, scroll, death**

The quit key E (`$724A`, Z when pressed) goes to GameOver. `$71C0` is Z when C, S and 3 are held together: CheatInfiniteKeys toggles CheatInfinite (`$8066`). Then MainLoopCheatB.

Evidence: 50 163 runs in 65 builds (c1 1114, controls-keyboard 465, ...). E in c1 and controls-keyboard went to GAME OVER. The chord C+S+3: cheats (stage 2).

Witness: L1 120474 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,114 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 486 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 489,838 t-states own (0.35 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 148,542 t-states own (0.23 %) |
| Runs (the other recordings) | 49,144 runs of its first instruction, entered by a jump (`stage2/rec/c48` 1,207, `stage1/rec/rzx-l1-14000-poke` 917, `stage1/rec/rzx-l1-06000-poke` 830 and 78 more) |
| Calls | `TestInfiniteLivesKeys`, `TestQuitKey` |
| Reads | `$7A76` (`Machine48K`); `$7EF1`-`$7EF2` (`Level`, `LevelsDone`); `$8065`-`$8066` (`Level5Open`, `CheatInfinite`); `$88CF`-`$88D3` (`ViewTopRow`, `ViewMap`, `ViewLastRow`, `ExitDirection`); `$8B3B` (`Lives`); `$9B9B`-`$9B9C` (`DeathFallOver`, `RickDying`); 1 more ranges |
| Writes | `$7EF1`-`$7EF2` (`Level`, `LevelsDone`); `$8065`-`$8067` (`Level5Open`, `CheatInfinite`, `CheatExits`); `$88D3` (`ExitDirection`) |

### `CheatInfiniteKeys` (`$7D39`)

**C+S+3: toggle CheatInfinite**

The code bytes LD A,1 / CALL `$7AAD` (tune 1, the signal) / LD A,(`$8066`) / XOR `$FF` / LD (`$8066`),A. CheatInfinite then stops the loss of lives (`$8A26`), ammunition (`$9593`) and detonators (`$9B27`, the reads of `$8066`).

A toggle once a pass while the chord is held: a hold of an odd number of passes leaves it on (cheats: on, off, on in frames 50-60, 3 runs).

Evidence: cheats (stage 2: C, S and 3 held at frame 50 on the RZX run's level 5) 3 runs: the chord held 10 frames toggles three times in its first passes.

Witness: L1 6 (cheats).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 3 runs of its first instruction, entered by a jump (`stage2/rec/cheats` 3) |
| Calls | `StartTune` |

### `MainLoopCheatB` (`$7D46`)

**The second cheat chord: SPACE, N, ENTER, J and Y**

`$71DC` is Z when SPACE, N, ENTER, J and Y are held together; then CheatExitsKeys. Then MainLoopPause.

Evidence: 50 161 runs in 65 builds; the chord: cheats (stage 2).

Witness: L1 120436 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,113 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 486 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 49,125 runs of its first instruction, entered by a jump (`stage2/rec/c48` 1,206, `stage1/rec/rzx-l1-14000-poke` 917, `stage1/rec/rzx-l1-06000-poke` 830 and 78 more) |
| Calls | `TestSectionCheatKeys` |

### `CheatExitsKeys` (`$7D4C`)

**The chord with level 5 open: CheatExits on**

The code bytes LD A,(`$8065`) / AND A / JP Z,`$7D5D` / LD A,1 / CALL `$7AAD` / LD A,`$FF` / LD (`$8067`),A: only when Level5Open is set, tune 1 and CheatExits (`$8067`) = `$FF`. The section exit test `$8993` reads CheatExits (bit 7) before it tests bit 4 of an exit's kind (`$89D9`): a level-end exit without bit 4 becomes a passage (long-l4: level 4 section 7 into section 10, `$89E0`). cheats runs it 3 times with the chord held (CheatExits = `$FF` at frame 204).

Evidence: cheats (stage 2: SPACE, N, ENTER, J and Y held at frame 200, Level5Open set by the RZX run) 3 runs; long-l4 (POKE CheatExits = `$FF` on the RZX run's level 4 end) shows what it opens: LongLevelsTest sends the level-ending exit `$82` of level 4 section 7 on to section 10.

Witness: L1 6 (cheats).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 3 runs of its first instruction, entered by a jump (`stage2/rec/cheats` 3) |
| Calls | `StartTune` |

### `MainLoopPause` (`$7D5D`)

**The pause, the pass's work, the frame wait, the level's end, scroll, death; GAME OVER**

P (`$7242`, Z when pressed): wait for its release, a press and a release (the game stands still, the interrupt goes on with the music and the controls). Then the pass: `$8B42` (Rick from the controls), ExitDirection (`$88D3`) = 0, UpdateObjects, DrawSprites; on a 48K (`$7A76` not 0) CALL `$7B66`; the frame wait `$7A53` with C = 2 (the pass takes at least two frames); the cells redrawn (`$76D4`).

The level's end: when a routine set ExitDirection, the section exit test `$8993`; its result negative (M) is the level's end. LevelsDone (`$7EF2`) + 1; when it was 3 (the fourth level done in this game), Level5Open (`$8065`) = `$FF`. LevelsDone = 5 goes to BonusTally (the Fat Guy's end); Level 5 ended otherwise goes to Congratulations; level 4 goes to Congratulations unless Level5Open is set, then to level 5; levels 1-3 to the next. Then LevelStart.

The scroll: unless `$9B9C` is set, Rick's y (`$9BAD`) below `$60` with the view not at the top (`$88CF`) scrolls up (`$7905`); y at `$CC` or more with the top row below ViewLastRow (`$88D2`) scrolls down (`$78A5`).

The death: when `$9B9B` is set, the last life (lives = 1) is GAME OVER, else `$8A26` (a life off, the section again).

GameOver (`$7E1E`): tune 2, the cell drawer's JP M at `$775A` turned into NOPs, `$8985`, the view buffer `$6D60-$6DDF` cleared, a 12 x 3 box at column 10, rows 11-13 of the screen: attributes `$47`, pixels 0; "GAME  OVER" falls into place (DropText at row `$A0`, column 11) and is printed on the screen (`$7F23` at `$488B`); wait 512 frames or fire, SPACE, ENTER (`$7229`); LevelCellsMode, NewGame.

Evidence: the pass 50 161 runs in 65 builds. The pause in c1 (7476 runs of PauseWaitRelease) and controls-keyboard. The level's end: `$7DA6` (level 5 opened) once in rzx-l4-20000-poke, the next level (`$7DCC`) in rzx-l3-10000-poke and rzx-l4-20000-poke; BonusTally and Congratulations not from this code in any recording (the RZX run's ending, rzx-l5-23000, starts inside TallyLives). GameOver 4 runs: c1 1 and controls-keyboard 1 (the key E), rzx-l5-full 2 (the lives lost).

Witness: L1 120436 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,113 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 288 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 278 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 315 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 486 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,917 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 49,125 runs of its first instruction, entered by a jump (`stage2/rec/c48` 1,206, `stage1/rec/rzx-l1-14000-poke` 917, `stage1/rec/rzx-l1-06000-poke` 830 and 78 more) |
| Calls | `TestFireKeys`, `TestPauseKey`, `DrawChangedCells`, `ScrollDown`, `ScrollUp`, `WaitFrames`, `StartTune`, `PlayBeeperStep`, `NewGame` (tail), `LevelStart` (tail), `LevelCellsMode`, `PrintText`, `DropText`, `DrawSprites`, `UpdateObjects`, `Congratulations` (tail), `ClearRedraw`, `CheckSectionExit`, `LoseLife`, `ScanMapObjects` |

## ending

`src/game/ending.asm`

### `BonusTally` (`$86E0`)

**The Fat Guy's end: 100 000, then the bullets and detonators counted**

The code bytes: LD HL,`$7F11` / CALL `$7ED3` (Points100000); then while ammunition (`$8B3C`) is not 0: one off, Points5000 (`$7F05`), effect 4 (`$7A97`), the HUD's ammunition (`$79D1`), 10 frames (`$7A53`); then while detonators (`$8B3D`) are not 0: one off, Points10000 (`$7F0B`), the HUD's detonators (`$79DF`), effect 5, 15 frames; then TallyLives. Jumped to from MainLoopPause (`$7DB3`). Not executed in the L1 builds: the RZX run went through it before frame 23 000, and rzx-l5-23000 starts in TallyLives.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TallyLives` (`$8728`)

**Each life left: 100 000 points, an effect, 20 frames; then the Fat Guy's end text**

While lives (`$8B3B`) are not 0: one off, Points100000 (AddScore), the HUD's lives (`$79C3`), effect 10 (`$7A97`), 20 frames. Then tune 10 (`$7AAD`) and ShowEndText with FatGuyEndText.

Evidence: rzx-l5-23000 6 runs (5 lives counted, the 6th pass to TallyDone), the ending text on its screens (stage 1: the RZX run's level 5, frames 23 200-26 500).

Witness: L1 12 (rzx-l5-23000).

| | |
| --- | --- |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 6 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 217,763 t-states own (0.09 %) |
| Calls | `DrawLives`, `WaitFrames`, `PlayEffect`, `StartTune`, `AddScore` |
| Reads | `$883D`-`$883E` (`FatGuyEndText`); `$8859`-`$885A` (`FatGuyEndText+28`); `$8878`-`$8879` (`FatGuyEndText+59`); `$8897`-`$8898` (`FatGuyEndText+90`); `$88B0` (`FatGuyEndText+115`); `$8B3B` (`Lives`) |
| Writes | `$8B3B` (`Lives`) |

### `Congratulations` (`$8754`)

**The other end: the level's digit into the text, tune 0**

The code bytes LD A,(`$7EF1`) / ADD A,`$34` / LD (`$87CD`),A (the level as a text digit, stored 4 higher) / XOR A / CALL `$7AAD` (tune 0) / LD HL,`$87A0` (CongratulationsText), falling into ShowEndText. Jumped to from MainLoopPause at `$7DBB` (level 5 done before five levels in this game) and `$7DC7` (level 4 done with level 5 closed). Not executed in any recording: complete level 4 in a game that has not opened level 5 (from level 2, 3 or 4) to run it.

Evidence: end-congrats (stage 2: the RZX run's level 4 end with POKE LevelsDone (`$7EF2`) = 0, so Level5Open stays clear) once: "CONGRATULATIONS ... YOU HAVE COMPLETED LEVEL 4" on its screens.

Witness: L1 2 (end-congrats).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 1 call (`stage2/rec/end-congrats` 1) |
| Called from | `MainLoopPause` (tail) |
| Calls | `StartTune` |
| Reads | `$7EF1` (`Level`); `$87A0`-`$87A1` (`CongratulationsText`); `$87B2`-`$87B3` (`CongratulationsText+18`); `$87CF`-`$87D0` (`CompletedLevelDigit+2`); `$87EE`-`$87EF` (`CompletedLevelDigit+33`); `$880F`-`$8810` (`CompletedLevelDigit+66`); 1 more ranges |
| Writes | `$87CD` (`CompletedLevelDigit`) |

### `ShowEndText` (`$8763`)

**An end text: the view cleared, then each line falls into place**

HL = the list (CongratulationsText or FatGuyEndText). FontCellsMode, `$796F` (HL kept), then ShowEndTextLoop.

Evidence: rzx-l5-23000 once.

Witness: L1 4 (end-congrats, rzx-l5-23000).

| | |
| --- | --- |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 run of its first instruction, entered by a jump (`stage2/rec/end-congrats` 1) |
| Calls | `DrawHud`, `FontCellsMode` |

### `ShowEndTextLoop` (`$876B`)

**A line of the end text: column, row, text**

A record: +0 the column (E), +1 the row in pixels (D), the text to `$FF`; DropText with A = `$FF`. A record starting with `$FF` ends the list: EndTextPause.

Evidence: 6 runs in 2 builds (rzx-l5-23000 5, rzx-l5-24000-poke 1).

Witness: L1 26 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke).

| | |
| --- | --- |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage1/rec/rzx-l5-24000-poke` 1) |
| Called from | `ShowEndTextNext` (tail) |
| Calls | `DropText`, `EndTextPause` (tail) |
| Reads | `$88B0` (`FatGuyEndText+115`) |

### `ShowEndTextNext` (`$877A`)

**Past the line's `$FF` to the next record**

HL + 1, then ShowEndTextLoop.

Evidence: rzx-l5-23000 (the four lines).

Witness: L1 22 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke).

| | |
| --- | --- |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7 runs of its first instruction, entered by a jump (`stage2/rec/end-congrats` 6, `stage1/rec/rzx-l5-24000-poke` 1) |
| Calls | `ShowEndTextLoop` (tail) |

### `EndTextPause` (`$877E`)

**2500 frames or fire**

BC = 2500, then EndTextWait.

Evidence: 2 runs in 2 builds (rzx-l5-23000, rzx-l5-24000-poke).

Witness: L1 6 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke).

| | |
| --- | --- |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage1/rec/rzx-l5-24000-poke` 1) |
| Called from | `ShowEndTextLoop` (tail) |

### `EndTextWait` (`$8781`)

**A frame; fire, SPACE or ENTER ends the wait**

Frame wait (C = 1), `$7229`; a key or BC = 0: EndTextExit.

Evidence: 4512 runs in 3 builds (rzx-l5-23000 2256, rzx-l5-24000-poke 2000, rzx-l5-26000-poke 256): no recording reaches the end of the wait or a key.

Witness: L1 11612 (end-congrats, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-26000-poke).

| | |
| --- | --- |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 2,256 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,550 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l5-24000-poke` 2,000, `stage2/rec/end-congrats` 1,294, `stage1/rec/rzx-l5-26000-poke` 256) |
| Calls | `TestFireKeys`, `WaitFrames` |

### `EndTextExit` (`$8794`)

**After an end text: GAME OVER and the control menu**

The code bytes CALL `$88B1` (FontCellsMode) / CALL `$7EB3` (LevelCellsMode) / CALL `$796F` / JP `$7E1E` (GameOver: the "GAME  OVER" box, then the control menu). Not executed in any recording (rzx-l5-26000-poke ends inside EndTextWait).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

## score

`src/game/score.asm`

### `AddScore` (`$7ED3`)

**Add six decimal digits at HL to the score, draw it**

HL = a points record (six digits, the most significant first). From the last digit back: score digit + record digit + carry; 10 or more takes 10 off with the carry set. Then `$7A0C` draws the score. Changes A, B, DE, HL.

The callers: `$8C36` and `$9F6D` (Points50), `$A595` (Points500), `$9CD6` (TimeBonus), TallyLives (Points100000) and level 5's own code at `$F964`; BonusTally (not run) adds Points100000, then Points5000 per bullet and Points10000 per detonator.

Evidence: 149 runs in 47 builds (callers `$8736` x5, `$8C36` x5, `$9CD6` x9, `$9F6D` x101, `$A595` x28, `$F964` x1); the RZX memory at level 5, frame 1000 holds 00 04 01 03 08 00 with "041380" on the screen (stage 1).

Witness: L1 316 (box-shot, cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000, rzx-l5-full, load-l5, sec-l2-s7, sec-l2-s12, sec-l5-s3).

[Animation: `AddScore` at work](img/routines/AddScore.gif)

| | |
| --- | --- |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 939 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 30 calls, 15,751 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 477 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 5 calls, 2,310 t-states own (0.00 %) |
| Runs (the other recordings) | 121 calls (`stage1/rec/rzx-l4-02000-poke` 6, `stage1/rec/rzx-l5-06000-poke` 5, `stage1/rec/rzx-l4-08000-poke` 5 and 46 more) |
| Called from | `TallyLives`, `TestEnemyHits`, `SpawnFromMap`, `KillEnemy`, `UpdatePickup` |
| Calls | `DrawScore` |
| Reads | `$7EF3`-`$7F22` (`Points50`, `Points100`, `Points500`, `Points5000` and 4 more) |
| Writes | `$7F1D`-`$7F22` (`Score`) |

### `CountBonus` (`$9163`)

**Count the bonus down: 10 points every 25 passes**

Called by the object step (`$86DB`) every pass while BonusRunning is set (a map entry of kind `$78` starts it, `$9C97`). BonusPrescaler counts 25 passes; then the digits `$7F1B`, `$7F1A`, `$7F19`, `$7F18` (0-9 each, the bonus number `$9C97` sets to 2000 with `$7F19` = 2) are decremented with a borrow: the bonus loses 10 every 25 passes (one a second at 25 passes a second; the value the HUD shows is for a run to confirm).

Ran 12 127 times in 29 builds (levels 1, 2 and others; the borrow loop CountBonusDigitLoop 548 times). The bonus never ran out in any recording: from 0000 the borrow would leave 9999 and end at BonusRunOut.

Witness: L1 24953 (cheats, rzx-l1-00000-poke, rzx-l1-06000-poke, rzx-l1-18000-poke, rzx-l1-24000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 183 calls, 7,979 t-states own (0.00 %) |
| Runs (the other recordings) | 12,361 calls (`stage1/rec/rzx-l1-24000-poke` 727, `stage1/rec/rzx-l1-18000-poke` 698, `stage1/rec/rzx-l5-04000-poke` 688 and 27 more) |
| Called from | `UpdateObjects` |
| Reads | `$7F19`-`$7F1B` (`TimeBonus+2`); `$9BAA` (`BonusPrescaler`) |
| Writes | `$7F19`-`$7F1B` (`TimeBonus+2`); `$9BAA` (`BonusPrescaler`) |

### `BonusRunOut` (`$917C`)

**RET the end of CountBonus when all four digits borrowed (the bonus wrapped)**

A lone RET (`$C9`), reached only when the four digits `$7F18-$7F1B` all wrapped from 0 to 9. The bonus is then 099 990: a stop mark reached after 201 s pays nearly 100 000. Not executed in any recording; a data entry because c1's power-on RAM test (`$11CB`) reads every byte, so the static walk does not take it as code.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

## menu

`src/game/menu.asm`

### `LevelMenu` (`$7F44`)

**The level menu: levels 1-4, level 5 when open; Level = the key pressed**

FontCellsMode, `$7A61`, `$8985`, `$8977`, then the texts with DropText (A = `$FF` the first time, then what it returns): "PRESS KEY TO" at row `$70` column 10, "START  LEVEL" at `$78`/10, the four levels at rows `$90`, `$A0`, `$B0`, `$C0` column 2, and "THE FAT GUYS HEADQUARTERS" at `$D0` only when Level5Open is set. A key 1-5 pressed during the fall is taken at once; else LevelMenuWait waits for one. Level = the key; LevelCellsMode's code inline; return to StartGame.

Evidence: 11 runs in 10 builds; the menu after side A lists levels 1-4 (load-l5's first frames before its POKE was added, stage 1), load-l5 with the POKE `$8065` = `$FF` shows level 5 and plays it.

Witness: L1 56 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 551 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 687 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 687 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 602 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 757 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 795 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 2,768,304 t-states own (0.15 %) |
| Runs (the other recordings) | 23 calls (`stage2/rec/sec-l5-s3` 1, `stage2/rec/sec-l5-s5` 1, `stage1/controls-cursor` 1 and 20 more) |
| Called from | `ChooseLevel` |
| Calls | `ClearScreen`, `DropText`, `FontCellsMode`, `BlankView`, `ClearRedraw` |
| Reads | `$8065` (`Level5Open`) |
| Writes | `$7730`-`$7731` (`DrawLevelCellBase+1`); `$775A`-`$775C` (`ComposeCellFrontTest`); `$7777`-`$7778` (`ComposeCellBase+1`); `$7EF1` (`Level`) |

### `LevelMenuWait` (`$7F9D`)

**Wait for a level key**

ReadMenuKey until it gives 1-5 (0 and none go round again).

Evidence: 82 475 runs in 2 builds (rzx-l1-00000-poke 37 177, rzx-l5-full 45 298: the RZX states sit in the level menu).

Witness: L1 164950 (rzx-l1-00000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 45,298 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 37,177 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l1-00000-poke` 37,177) |
| Calls | `ReadMenuKey` |
| Writes | `$7730`-`$7731` (`DrawLevelCellBase+1`); `$775A`-`$775C` (`ComposeCellFrontTest`); `$7777`-`$7778` (`ComposeCellBase+1`); `$7EF1` (`Level`) |

### `ReadMenuKey` (`$8068`)

**A number key 0-5 once per press: A = the key, or `$FF`**

ScanNumberKeys; none: MenuKeyHeld = 0 and A = `$FF`. A key while MenuKeyHeld is set (still held from the last time): A = `$FF`. Else MenuKeyHeld = `$FF` and A = the key. Out: A.

Evidence: 89 436 runs in 13 builds (callers LevelMenuWait, ControlMenuLoop, DropTextWait).

Witness: L1 199122 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,805 calls, 119,432 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 255 calls, 16,688 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 255 calls, 16,688 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 255 calls, 16,688 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 255 calls, 16,688 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 315 calls, 20,772 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 46,945 calls, 3,581,521 t-states own (0.19 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 54,378 t-states own (0.02 %) |
| Runs (the other recordings) | 51,059 calls (`stage1/rec/rzx-l1-00000-poke` 37,177, `stage2/rec/c48` 2,013, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `LevelMenuWait`, `ControlMenuLoop`, `DropTextWait` |
| Calls | `ScanNumberKeys` |
| Reads | `$81AE` (`MenuKeyHeld`) |
| Writes | `$81AE` (`MenuKeyHeld`) |

### `ScanNumberKeys` (`$8087`)

**The number key held: A = 0-5 (5 only with level 5 open), else `$FF`**

Tests 0 (`$71F9`), 1-4 (`$7201-$7219`) and, when Level5Open is set, 5 (`$7221`); the first found is returned in A, with Z. None: A = `$FF`.

Evidence: 89 436 runs in 13 builds.

Witness: L1 199122 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,805 calls, 330,098 t-states own (0.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 255 calls, 47,483 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 255 calls, 47,512 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 255 calls, 47,541 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 255 calls, 54,847 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 315 calls, 57,834 t-states own (0.06 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 46,945 calls, 5,458,103 t-states own (0.29 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 182,305 t-states own (0.08 %) |
| Runs (the other recordings) | 51,059 calls (`stage1/rec/rzx-l1-00000-poke` 37,177, `stage2/rec/c48` 2,013, `stage2/rec/end-congrats` 1,139 and 23 more) |
| Called from | `ReadMenuKey` |
| Calls | `TestKey0`, `TestKey1`, `TestKey2`, `TestKey3`, `TestKey4`, `TestKey5` |
| Reads | `$8065` (`Level5Open`) |

### `ControlMenu` (`$80B5`)

**The control menu: START GAME or a control method; returns when 0 is pressed**

FontCellsMode, tune 0 (`$7AAD`), MenuKeyHeld = `$FF` (a key held from before does not count). The texts fall: "RICK DANGEROUS II" at row `$68` column 7, "0   START GAME" at `$80`/9, "1   KEYBOARD", "2   KEMPSTON", "3   CURSOR", "4   SINCLAIR" at `$98`, `$A8`, `$B8`, `$C8` (the digits stored 4 higher); the key 0 during any of them returns at once. Then the pointer: Rick's record gets the sprite at Sprites + 12 x 128 (`$9BAF`), x 0 (`$9BAC`), y `$2A` (`$9BAD`), `$9BB1`, `$9B95-$9B97` = 0, and ControlMenuLoop runs.

Evidence: 4 runs in 3 builds (c1 1, controls-keyboard 1, rzx-l5-full 2); c1 chooses 2, 3, 4, 1 and 0 in turn (tests/inputs/c1.txt), the menu from about frame 15 000 (WALKTHROUGH 1).

Witness: L1 42 (controls-keyboard, rzx-l5-full, c1, c48, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 137,222 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 188,310 t-states own (0.01 %) |
| Runs (the other recordings) | 19 calls (`stage2/rec/c48` 1, `stage2/rec/sec-l5-s5` 1, `stage2/rec/sec-l5-s3` 1 and 16 more) |
| Called from | `NewGame` |
| Calls | `StartTune`, `DropText`, `FontCellsMode` |
| Reads | `$7252` (`ControlMethod`) |
| Writes | `$7252` (`ControlMethod`); `$77B0` (`SpareCount`); `$81AE` (`MenuKeyHeld`); `$9B95`-`$9B97` (`RickDy`, `RickYFrac`); `$9BAC`-`$9BB1` (`RickX`, `RickY`, `RickSprite`, `RickFacing`) |

### `ControlMenuLoop` (`$8127`)

**Choose the control method, move the pointer, until 0**

ReadMenuKey: 0 returns (start the game); 1-4 set the method `$7252` = key - 1 (0 keyboard, 1 Kempston, 2 cursor, 3 Sinclair). Then the composed cells from 2 (`$77B0`), MoveMenuRick toward the method's row (`$94` + 16 x method), the sprite drawn (`$7329`, IX = `$9BAB`), a frame wait, the cells redrawn, again.

Evidence: 2230 runs in 10 builds; c1 sets each method in turn, controls-* each one (stage 1).

Witness: L1 8614 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 669 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,369 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,369 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,369 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 51 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 10,206 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 111 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 22,708 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 913 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,285 runs of its first instruction, entered by a jump (`stage2/rec/c48` 877, `docs/rec/box-shot` 111, `stage1/controls-cursor` 111 and 20 more) |
| Calls | `ComposeSprite`, `DrawChangedCells`, `WaitFrames`, `ReadMenuKey`, `MoveMenuRick` |
| Reads | `$7252` (`ControlMethod`) |
| Writes | `$7252` (`ControlMethod`); `$77B0` (`SpareCount`) |

### `MoveLetters` (`$81E6`)

**Move every falling letter one frame and compose it into the view**

The composed cells from 2 (`$77B0`); for each 8-byte record from `$7B8F` until `$FF`: MoveLetter, ComposeLetter.

Evidence: 4731 runs in 11 builds (from DropTextFrame).

Witness: L1 25558 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `MoveLetters` at work](img/routines/MoveLetters.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,136 calls, 1,198,523 t-states own (0.09 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 204 calls, 219,914 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 204 calls, 219,914 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 204 calls, 219,914 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 204 calls, 219,750 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 204 calls, 219,937 t-states own (0.24 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 734 calls, 847,673 t-states own (0.05 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 calls, 1,854,882 t-states own (0.80 %) |
| Runs (the other recordings) | 10,597 calls (`stage2/rec/end-congrats` 1,139, `stage2/rec/c48` 1,136, `stage1/controls-keyboard` 597 and 21 more) |
| Called from | `DropText` |
| Reads | `$7B8F`-`$7C5F` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |
| Writes | `$77B0` (`SpareCount`) |

### `MoveLettersLoop` (`$81EF`)

**The next letter record**

Ends at a record whose +0 is `$FF`; IX + 8.

Evidence: the loop of MoveLetters (reads `$7B8F-$7C4F`).

Witness: L1 334490 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 12,241 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,244 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2,244 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,244 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2,244 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,244 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,645 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 18,721 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 133,147 runs of its first instruction, entered by a jump (`stage2/rec/end-congrats` 25,357, `stage2/rec/c48` 12,241, `stage1/controls-keyboard` 7,075 and 22 more) |
| Calls | `MoveLetter`, `ComposeLetter` |
| Reads | `$7BBF`-`$7C1F` (`CopyMusic`, `SetupIm2`) |

### `MoveLetter` (`$8203`)

**One letter's fall: delay, gravity, a bounce at its row**

IX = the record (BuildLetters): +0 glyph, +1 column, +2/+3 y (+2 the pixel row, +3 the fraction), +4/+5 the speed (+4 low), +6 the delay in frames, +7 the row it stops at. While the delay is not 0 it counts down (the letters start one after the other, 6 frames apart). Then speed + `$60` (the gravity), y + speed; past the row: y = the row, speed = - speed / 2 (a bounce), 0 when its high byte is 0 or `$FF` (the letter stops).

Evidence: 57 671 runs in 12 builds.

Witness: L1 308930 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 11,105 calls, 2,643,685 t-states own (0.20 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,040 calls, 477,076 t-states own (0.05 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2,040 calls, 477,076 t-states own (0.03 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,040 calls, 477,076 t-states own (0.03 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2,040 calls, 477,085 t-states own (0.02 %) |
| Runs (controls-kempston: the Kempston method in play) | 2,040 calls, 477,049 t-states own (0.51 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 7,911 calls, 1,787,497 t-states own (0.10 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 17,885 calls, 4,153,490 t-states own (1.80 %) |
| Runs (the other recordings) | 122,549 calls (`stage2/rec/end-congrats` 24,218, `stage2/rec/c48` 11,105, `stage1/controls-keyboard` 6,478 and 22 more) |
| Called from | `MoveLettersLoop` |
| Reads | `$7B91`-`$7C5E` (`Entry+2`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |
| Writes | `$7B91`-`$7C5D` (`Entry+2`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |

### `BuildLetters` (`$8258`)

**One falling-letter record per character of a text, from `$7B8F`**

HL = the text (`$FF` the end), D = the row it falls to (pixels), E = the column. Each non-space character: +0 the glyph (code - `$34`), +1 the column, +2/+3 y = `$4000` (row 64), +4/+5 speed = `$0900` (9 pixels a frame down), +6 the delay C (1, then 6 more for every character, spaces too), +7 the row D. The record after the last gets `$FF` at +0. Out: HL on the text's `$FF`.

Evidence: 41 runs in 11 builds (writes `$7B8F-$7C4F`).

Witness: L1 230 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 9 calls, 31,889 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 7,287 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2 calls, 7,287 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 7,287 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 7,287 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 7,297 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 9 calls, 37,193 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 4 calls, 30,381 t-states own (0.01 %) |
| Runs (the other recordings) | 96 calls (`stage2/rec/c48` 9, `stage2/rec/end-congrats` 6, `stage1/controls-keyboard` 5 and 21 more) |
| Called from | `DropText` |
| Reads | `$7EC8`-`$7ED2` (`GameOverText`); `$7FC7`-`$7FF4` (`LevelMenuText`, `StartLevelText`, `Level1Name`); `$8159`-`$81AD` (`ControlMenuText`, `KeyboardText`, `KempstonText`, `CursorText` and 2 more); `$87A2`-`$88AF` (`CongratulationsText+2`, `FatGuyEndText`) |
| Writes | `$7B8F`-`$7C5F` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |

### `PutTextCells` (`$82A1`)

**Put a text's glyph numbers into the view buffer, marked for redraw**

HL = the text, DE = the view buffer address (`$6B00` + 32 x row + column). Each non-space character: the glyph number (code - `$34`) at DE and 1 at DE - `$500` (the old buffer at `$6600`, so the drawer sees a change).

Evidence: 97 runs in 12 builds (writes `$67A7-$695D` and `$6CA7-$6E5D`).

Witness: L1 651 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 13 calls, 21,851 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 6 calls, 12,836 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 6 calls, 12,791 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 6 calls, 12,802 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 7 calls, 15,690 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 6 calls, 12,808 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 28 calls, 49,414 t-states own (0.00 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 4 calls, 10,748 t-states own (0.00 %) |
| Runs (the other recordings) | 275 calls (`stage2/rec/sec-l5-s3` 14, `stage2/rec/sec-l5-s5` 14, `stage2/rec/c48` 13 and 22 more) |
| Called from | `DropTextWait` |
| Reads | `$7EC8`-`$7ED2` (`GameOverText`); `$7FC7`-`$8064` (`LevelMenuText`, `StartLevelText`, `Level1Name`, `Level2Name` and 3 more); `$8159`-`$81AD` (`ControlMenuText`, `KeyboardText`, `KempstonText`, `CursorText` and 2 more); `$87A2`-`$88AF` (`CongratulationsText+2`, `FatGuyEndText`) |
| Writes | `$67A7`-`$6918` (`DirtyMap+423`); `$6929`-`$695D` (`DirtyMap+809`); `$6CA7`-`$6E18` (`ViewCells+423`); `$6E29`-`$6E5D` (`ViewCells+809`) |

### `DropText` (`$82BD`)

**Show a text in the view: A = `$FF` letters fall into place, else at once**

HL = the text, D = the row in pixels, E = the column, A = `$FF` to animate. Stores the text and its view buffer address (`$6B00` + 4 x (D AND `$F8`) + E) into DropTextFinish's operands. A = `$FF`: BuildLetters, then DropTextWait's frames until every letter has stopped or a number key is pressed. Then (and at once when A is not `$FF`) DropTextFinish puts the text into the view buffer and redraws it. Out: A = the key pressed during the fall (ReadMenuKey: 0-5), `$FF` when none, or A as given when not animated; HL on the text's `$FF` (the end pointer of the last animated text). The callers chain A: after a key the later texts of the menu are put at once, and the key is the menu's choice.

Evidence: 97 runs in 11 builds (callers: LevelMenu, ControlMenu, GameOver `$7E8B`, ShowEndTextLoop `$8777`).

Witness: L1 651 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 13 calls, 548,218 t-states own (0.04 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 6 calls, 96,107 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 6 calls, 96,107 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 6 calls, 96,107 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 7 calls, 96,636 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 6 calls, 96,122 t-states own (0.10 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 28 calls, 378,505 t-states own (0.02 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 4 calls, 889,128 t-states own (0.39 %) |
| Runs (the other recordings) | 275 calls (`stage2/rec/sec-l5-s5` 14, `stage2/rec/sec-l5-s3` 14, `stage2/rec/c48` 13 and 21 more) |
| Called from | `MainLoopPause`, `LevelMenu`, `ControlMenu`, `ShowEndTextLoop` |
| Calls | `MoveLetters`, `BuildLetters` |
| Reads | `$7B8F`-`$7C5F` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |
| Writes | `$8311`-`$831F` (`DropTextFinish+2`) |

### `DropTextWait` (`$82E2`)

**Wait a frame, redraw, stop at a key or when every letter has stopped**

Frame wait (C = 1), the cells redrawn (`$76D4`), ReadMenuKey: a key goes to DropTextFinish with A = the key. Else, a letter with a delay or a speed left (+6 or +5 not 0) means another frame (DropTextFrame); all still: DropTextFinish.

Evidence: 4732 runs in 12 builds.

Witness: L1 25560 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,136 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 204 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 204 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 204 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 204 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 204 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 734 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 836 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,598 runs of its first instruction, entered by a jump (`stage2/rec/end-congrats` 1,139, `stage2/rec/c48` 1,136, `stage1/controls-keyboard` 597 and 22 more) |
| Calls | `DrawChangedCells`, `WaitFrames`, `ReadMenuKey`, `PutTextCells` |
| Reads | `$7B8F`-`$7C1F` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2`) |

### `ComposeLetter` (`$8321`)

**Compose a falling letter into spare cells of the view**

The next spare cell is `$5DF0` + 8 x `$77B0` (the composed cells `$5DE8` + 8n). The view cell under the letter (row (y AND `$F8`) / 8, its column) and, when y is not on a cell boundary, the one below are copied into spare cells by `$7755` (which puts the spare cells' numbers into the view buffer). Then the glyph `$7080` + 8 x (+0) is ORed in from the row y AND 7 of the first spare cell on (eight rows over the two cells).

Evidence: 57 671 runs in 12 builds (reads the glyphs `$7080-$71AF`, writes `$5E00-$5F0E`).

Witness: L1 308930 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 11,105 calls, 8,588,232 t-states own (0.64 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,040 calls, 1,580,503 t-states own (0.16 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2,040 calls, 1,580,503 t-states own (0.11 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,040 calls, 1,580,503 t-states own (0.08 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2,040 calls, 1,580,597 t-states own (0.07 %) |
| Runs (controls-kempston: the Kempston method in play) | 2,040 calls, 1,580,079 t-states own (1.70 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 7,911 calls, 6,097,958 t-states own (0.33 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 17,885 calls, 13,552,454 t-states own (5.87 %) |
| Runs (the other recordings) | 122,549 calls (`stage2/rec/end-congrats` 24,218, `stage2/rec/c48` 11,105, `stage1/controls-keyboard` 6,478 and 22 more) |
| Called from | `MoveLettersLoop` |
| Calls | `ComposeCell` |
| Reads | `$5E00`-`$5F17` (`SpareCells+24`); `$7080`-`$70A7` (`Glyphs`); `$70E8`-`$71AF` (`GlyphLetters`); `$77B0` (`SpareCount`); `$7B8F`-`$7C59` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 1 more) |
| Writes | `$5E00`-`$5F17` (`SpareCells+24`) |

### `MoveMenuRick` (`$83CE`)

**The control menu's Rick: y toward the row C, x swinging about 24**

y (`$9BAD`) moves 2 toward C. The x speed `$9B95` (a word) gets + `$30` while x (`$9BAC`) is below `$18`, - `$30` when it is at or above; x and its fraction (`$9B97`) + speed: Rick sways sideways.

Evidence: 2219 runs in 10 builds (from ControlMenuPointer).

Witness: L1 8558 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 668 calls, 165,802 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 50 calls, 12,240 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 50 calls, 12,240 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 50 calls, 12,240 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 50 calls, 12,240 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 110 calls, 27,100 t-states own (0.03 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 911 calls, 226,429 t-states own (0.01 %) |
| Runs (the other recordings) | 3,262 calls (`stage2/rec/c48` 876, `stage1/controls-sinclair` 110, `stage1/controls-cursor` 110 and 20 more) |
| Called from | `ControlMenuLoop` |
| Reads | `$9B95`-`$9B97` (`RickDy`, `RickYFrac`); `$9BAC`-`$9BAE` (`RickX`, `RickY`) |
| Writes | `$9B95`-`$9B97` (`RickDy`, `RickYFrac`); `$9BAC`-`$9BAE` (`RickX`, `RickY`) |

## level

`src/game/level.asm`

### `ResetSectionObjects` (`$8379`)

**Clear bit 7 (used) in every object record of every section of the level**

B = SectionCounts[Level]; for each section's 8-byte record from (`$C202`) + 6: the list at (`$C202`) + the big-endian word at +6; each 4-byte record until a kind 0: its byte +0 AND `$7F`, then skip as many more 4-byte records as +3 AND 3 says.

Evidence: 12 runs in 11 builds (level 1: reads `$ECF3-$ED2C` and the lists `$ED32-$F1FE`, writes `$ED32-$F1EC`).

Witness: L1 58 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 15,210 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 15,857 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 15,386 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 15,857 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 15,053 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 15,229 t-states own (0.02 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 35,740 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage2/rec/sec-l4-s1` 1, `stage2/rec/sec-l4-s11` 1, `stage2/rec/sec-l4-s12` 1 and 21 more) |
| Called from | `StartGame` |
| Reads | `$7EF1` (`Level`); `$8374`-`$8378` (`SectionCounts`); `$C202`-`$C203` (`work space $C202+`); `$EAF3`-`$F3DA` (`work space $EAF3+`) |
| Writes | `$EB62`-`$F3D6` (`work space $EB62+`) |

### `BuildView` (`$88D4`)

**Build ViewCells: 11 rows of 8 blocks from the section's map, from the view's top row**

The map row is ViewTop `$88CF` / 4, rounded down to an even row ((ViewTop x 2) AND `$FFF0`, ViewTop being a multiple of 8): the bytes from the section's map `$88D0` plus that offset. Each map byte is a block number; the block's 16 cell numbers (Blocks + 16 x n, four rows of four) go to ViewCells as a 4 x 4 square, 8 blocks a row, 11 rows: 32 x 44 cells, `$6B00-$707F`.

Runs with the interrupts off and SP borrowed: SP points at the block and POP DE takes two cell numbers at a time; the caller's SP is stored into the LD SP,n at `$8946` and put back there (an interrupt in between is lost, NOTES). Then FindFirstMapEntry sets the map entry scan's start for the new view.

Callers: the scroll down `$78F2` (83 runs), the scroll up `$7952` (89), SetupSection `$8AE6` (97). Witness: 269 runs in 62 builds; reads the maps only (`$E1ED-$E9D4` over all recordings), writes `$6B00-$707F`.

Witness: L1 651 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 242,480 t-states own (0.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 119,108 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 40,335 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 80,702 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 40,358 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 79,115 t-states own (0.09 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 18 calls, 714,599 t-states own (0.04 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 79,533 t-states own (0.12 %) |
| Runs (the other recordings) | 300 calls (`stage1/rec/rzx-l4-10000-poke` 11, `stage1/rec/rzx-l3-06000-poke` 10, `stage1/rec/rzx-l5-08000-poke` 10 and 74 more) |
| Called from | `ScrollDown`, `ScrollUp`, `SetupSection` |
| Calls | `FindFirstMapEntry` |
| Reads | `$88CF`-`$88D1` (`ViewTopRow`, `ViewMap`); `$E1ED`-`$EAC4` (`work space $E1ED+`); `$EB5D`-`$EBF4` (`work space $EB5D+`); `$EC5D`-`$ECF4` (`work space $EC5D+`) |
| Writes | `$6B00`-`$707F` (`ViewCells`); `$88F0`-`$88F1` (`BuildViewDest+1`); `$8947`-`$8948` (`BuildViewSP+1`) |

### `RedrawAll` (`$8969`)

**Fill DirtyMap with 1: every screen cell is drawn on the next redraw**

1280 bytes `$6600-$6AFF` set to 1, the mark `$77B1` reads as "draw this cell whatever it held". Called by `$7965` (the full redraw after a section setup and at the level start).

Evidence: 97 runs in 43 builds, all from `$7965`.

Witness: L1 279 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 206,737 t-states own (0.02 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 107,967 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 36,966 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 67,992 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 34,831 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 73,701 t-states own (0.08 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 14 calls, 478,771 t-states own (0.03 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 73,069 t-states own (0.11 %) |
| Runs (the other recordings) | 118 calls (`stage1/rec/rzx-l3-04000-poke` 7, `stage2/rec/c48` 6, `stage1/rec/rzx-l4-10000-poke` 6 and 55 more) |
| Called from | `RedrawView` |
| Reads | `$6600`-`$6AFE` (`DirtyMap`) |
| Writes | `$6600`-`$6AFF` (`DirtyMap`) |

### `BlankView` (`$8977`)

**Fill the first 1280 bytes of ViewCells with cell `$27`**

`$6B00-$6FFF` set to cell 39 (the last 128 bytes of the 1408 stay). Called by the level menu `$7F4D` and `$88B1` (the text screens: the menus, the endings), which draw on a blank view.

Evidence: 27 runs in 11 builds (callers `$7F4D` 11, `$88CA` 16).

Witness: L1 158 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 3 calls, 92,711 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 71,285 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2 calls, 71,285 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 71,285 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 71,285 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 70,869 t-states own (0.08 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 6 calls, 205,581 t-states own (0.01 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 39,070 t-states own (0.02 %) |
| Runs (the other recordings) | 66 calls (`stage1/controls-keyboard` 3, `stage2/rec/c48` 3, `stage2/rec/sec-l4-s1` 3 and 21 more) |
| Called from | `LevelMenu`, `FontCellsMode` |
| Reads | `$6B00`-`$6FFE` (`ViewCells`) |
| Writes | `$6B00`-`$6FFF` (`ViewCells`) |

### `ClearRedraw` (`$8985`)

**Fill DirtyMap with 0: the next redraw draws only the cells that changed**

1280 bytes `$6600-$6AFF` set to 0. Called around every scroll step (`$78A5`, `$78FB`, `$7905`, `$795B`), by the game over `$7E2C`, the level menu `$7F4A`, `$88C7` and SetupSection (`$8B0B`).

Evidence: 469 runs in 63 builds.

Witness: L1 1217 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 10 calls, 358,010 t-states own (0.03 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 5 calls, 160,714 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 98,205 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 137,472 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 3 calls, 102,628 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 4 calls, 138,231 t-states own (0.15 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 30 calls, 998,942 t-states own (0.05 %) |
| Runs (rzx-l5-23000: the RZX run's level 5 at 23000, no POKE: the ending) | 1 call, 27,546 t-states own (0.01 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 70,780 t-states own (0.11 %) |
| Runs (the other recordings) | 564 calls (`stage1/rec/rzx-l5-08000-poke` 20, `stage1/rec/rzx-l1-10000-poke` 18, `stage2/rec/sec-l4-s11` 18 and 75 more) |
| Called from | `ScrollDown`, `ScrollUp`, `MainLoopPause`, `LevelMenu`, `FontCellsMode`, `SetupSection` |
| Reads | `$6600`-`$6AFE` (`DirtyMap`) |
| Writes | `$6600`-`$6AFF` (`DirtyMap`) |

### `CheckSectionExit` (`$8993`)

**Rick left the view at a side: find the exit and set up the next section, or end the level**

Called by the main loop (`$7D98`) when the exit request `$88D3` is set (1: Rick left at the left edge, 2: at the right; set by `$9531`, `$9545`, `$9955`, `$9966`). Rick's feet row in the section is L = ViewTop + (y `$9BAD` + 20) / 8. The exit list (its address stored into the LD IX,n here by SetupSection `$8ACB`) is scanned for the first record whose bits 0, 1, 3 equal the request and whose +1 equals L. None: return Z, A = 0 (positive), and nothing happens.

Found: `$945D` = 0, then the flags (bits 4-7). Bit 7 set: return with A negative, the level is done (the main loop goes to `$7D9E`). Bit 5: `$945D` = `$FF`. Bit 6: LevelHookOn = 20. Then TakeExit: the new view top = +3 - (L - ViewTop), so Rick keeps his place on the screen; x = `$E8` when he went out at the left (bits 0-1 = 1), else 0; y stays; SetupSection for section +2; return A = 0 (positive).

The long-levels switch: when `$8067` has bit 7 set, the bytes at `$89E0` (BIT 4,C / JP Z,`$89E8`) skip the level-end test for an exit whose bit 4 is clear, so the exits `$82` (level 2 section 7, level 3 section 6, level 4 section 7) lead on into the sections no recording shows (level 2 10-12, level 3 7-9, level 4 10-12) instead of ending the level; the exits `$91` / `$92` (bit 4 set) still end it. `$8067` is set only by `$7D4C` (a key combination tested at `$71DC`, while level 5 is open `$8065`); no recording ran it. Known only from the code.

Evidence: 1225 runs in 34 builds (all from `$7D98`); a matching exit 51 times (TakeExit), the flag test 12 times (`$89E5`), a level end 2 times (rzx-l3-10000-poke: level 3 section 6's exit `$82`; rzx-l4-20000-poke: level 4 section 7's `$82`, the `$7D9E` runs).

Witness: L1 2431 (end-congrats, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-20000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2, load-l4, sec-l2-s11, sec-l2-s12, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 30 calls, 7,620 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 35 calls, 8,890 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 41 calls, 17,507 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 734 calls, 186,455 t-states own (0.01 %) |
| Runs (the other recordings) | 449 calls (`stage1/rec/rzx-l3-02000-poke` 169, `stage1/rec/rzx-l5-18000-poke` 87, `stage1/rec/rzx-l5-20000-poke` 66 and 39 more) |
| Called from | `MainLoopPause` |
| Reads | `$8067` (`CheatExits`); `$88CF`-`$88D3` (`ViewTopRow`, `ViewMap`, `ViewLastRow`, `ExitDirection`); `$9BAD`-`$9BAE` (`RickY`); `$EB55`-`$EB61` (`work space $EB55+`); `$EC5D`-`$EC6F` (`work space $EC5D+`); `$EC95`-`$ECBB` (`work space $EC95+`); 21 more ranges |
| Writes | `$8A24` (`LevelHookOn`); `$945D` (`RideMode`) |

### `LongLevelsTest` (`$89E0`)

**BIT 4,C / JP Z,`$89E8`: with the switch on, an exit without bit 4 never ends the level**

Reached from `$89DD` only when `$8067` is negative. A bit-4 exit goes on to the level-end test at `$89E5`; any other skips it (`$89E8`).

Evidence: long-l4 (stage 2, POKE CheatExits = `$FF`) once: the exit `$82` at the end of level 4 section 7 took the JP Z and the level went on into section 10.

Witness: L1 2 (long-l4).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 1 run of its first instruction, entered by a jump (`stage2/rec/long-l4` 1) |

### `CheckExitFlags` (`$89E5`)

**CheckSectionExit, continued: the exit's flags**

C: the exit's flags (bits 4-7). Bit 7: return with A = C (negative): the level is done. Else `$945D` = 0, or `$FF` with bit 5 (a state of Rick's, read by `$95ED`; restored after a death through `$9B91`); bit 6: LevelHookOn = 20 (only level 5 section 6's exit `$42` into section 7, the Fat Guy: rzx-l5-20000-poke, once).

Evidence: 12 runs in 7 builds; bit 5 9 times (level 2 section 5 and 7, level 4 sections 3-5, level 5 section 1), bit 6 once.

Witness: L1 26 (end-congrats, rzx-l2-20000-poke, rzx-l3-10000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-20000-poke, rzx-l5-06000-poke, rzx-l5-20000-poke).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 13 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l4-10000-poke` 4, `stage1/rec/rzx-l4-12000-poke` 3, `stage1/rec/rzx-l2-20000-poke` 1 and 5 more) |
| Calls | `SetupSection` |

### `LoseLife` (`$8A26`)

**Rick died: a life off, the bullets and detonators back to 6, restart where he entered the section**

Called by the main loop (`$7E18`) when Rick's death is over (`$9B9B` set) and more than one life is left. Lives `$8B3B` - 1 unless the cheat flag `$8066` is set (toggled by `$7D39`, a key combination at `$71C0`; no recording ran it), the lives redrawn (`$79C3`); the word `$9B95` = `$0100` (the death sets `$FB00` there, `$93EA`); Ammunition and Detonators = 6.

Then the restart point `$9B8C-$9B94` that SetupSection saved when Rick came into the section is put back: the facing `$9BB1`, `$9B99`, the crawl flag `$9B98`, `$945D`, then x, y, the view top and the section for SetupSection, into which it falls.

Evidence: 29 runs in 13 builds (all from `$7E18`), from c1 (5) on; the life taken 33 times over the builds (the POKE `$8A30` of the RZX pieces makes the lives infinite).

Witness: L1 58 (controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2, load-l4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 5 calls, 1,540 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 616 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 308 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 308 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 11 calls, 3,388 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 2,572 t-states own (0.00 %) |
| Runs (the other recordings) | 13 calls (`stage2/rec/c48` 4, `stage1/rec/rzx-l3-04000-poke` 2, `stage1/rec/rzx-l3-02000-poke` 1 and 6 more) |
| Called from | `MainLoopPause` |
| Calls | `DrawLives`, `SetupSection` (falls into) |
| Reads | `$8066` (`CheatInfinite`); `$88D3` (`ExitDirection`); `$8A24` (`LevelHookOn`); `$8B3B` (`Lives`); `$945D` (`RideMode`); `$9B8C`-`$9B99` (`RestartPoint`, `RickDy`, `RickYFrac`, `RickCrawling` and 1 more); 4 more ranges |
| Writes | `$86DF` (`SectionBusy`); `$88CF`-`$88D3` (`ViewTopRow`, `ViewMap`, `ViewLastRow`, `ExitDirection`); `$8995`-`$8996` (`CheckSectionExit+2`); `$8B3B`-`$8B3F` (`Lives`, `Ammunition`, `Detonators`, `SectionEntries`); `$8BC0` (`SpawnWholeView`); `$945D` (`RideMode`); 1 more ranges |

### `SetupSection` (`$8A6D`)

**Set up section A: Rick at (E, HL), the view top C; the map, the exits and the entries from the table**

Inputs: A the section, E Rick's x, HL Rick's y (pixels from the view's top), C the view's top row. The section into `$9B93`, Rick's x and y into `$9BAC` / `$9BAD`, the dying flags `$9B9B` / `$9B9C` cleared, the view top into `$88CF`; a restart point is saved in `$9B8C-$9B94` (x, y, the crawl flag `$9B98`, `$9B99`, `$945D`, the view top, the section, the facing `$9BB1`), which LoseLife puts back.

The section table entry LevelHeader+2 + 8 x A: +0/+1 (big-endian) + the maps' base into `$88D0`, the section's map (`$8AB8`); +3 into `$88D2` (`$8ABE`), the last top row the main loop scrolls down to (`$7DFB`); +4/+5 + the table's address into the LD IX,n of CheckSectionExit (`$8ACB`); +6/+7 + the table's address into SectionEntries (`$8AD5`). +2 is not read.

Then Rick's record off (`$9BAB` = 0), `$85FA`, `$76D4`, the objects freed (`$9BEB`), BuildView, and the entries in the view spawned (ScanMapObjects with SpawnWholeView = `$FF` and `$86DF` = `$FF`), or LevelHookA when LevelHookOn is set; then `$865D`, ClearRedraw, Rick's record on (`$9BAB` = 1), `$85FA`, `$796F`, the bonus countdown stopped (`$9BA9` = `$9BAA` = 0), the exit request `$88D3` cleared, the full redraw (`$7965`, `$76D4`). The test of `$88D3` = 1 at `$8B23` leads to two identical tails.

Callers: the level start `$7D2A` (17), TakeExit `$8A1F` (51), LoseLife (falls in, 27). Witness: 97 runs in 43 builds; LevelHookA called twice (rzx-l5-20000-poke).

Witness: L1 279 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 5,808 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 2,904 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 968 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 1,936 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 968 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 1,936 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 14 calls, 13,552 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 116 calls (`stage1/rec/rzx-l3-04000-poke` 7, `stage1/rec/rzx-l4-10000-poke` 6, `stage2/rec/c48` 6 and 53 more) |
| Called from | `LevelSetup`, `CheckExitFlags`, `LoseLife` (falls into) |
| Calls | `DrawChangedCells`, `RedrawView`, `DrawHud`, `DrawSprites`, `UpdateObjects`, `BuildView`, `ClearRedraw`, `ScanMapObjects`, `FreeAllObjects` |
| Reads | `$88D3` (`ExitDirection`); `$8A24` (`LevelHookOn`); `$945D` (`RideMode`); `$9B98`-`$9B99` (`RickCrawling`, `RickClimbing`); `$9BB1` (`RickFacing`); `$C202`-`$C205` (`work space $C202+`); 4 more ranges |
| Writes | `$86DF` (`SectionBusy`); `$88CF`-`$88D3` (`ViewTopRow`, `ViewMap`, `ViewLastRow`, `ExitDirection`); `$8995`-`$8996` (`CheckSectionExit+2`); `$8B3E`-`$8B3F` (`SectionEntries`); `$8BC0` (`SpawnWholeView`); `$9B8C`-`$9BAE` (`RestartPoint`, `RickDy`, `RickYFrac`, `RickCrawling` and 18 more) |

## objects

`src/game/objects.asm`

### `ClearObjectTables` (`$83B8`)

**Clear `$7B8F-$7C7C` and put the end marks of the two tables**

`$7B8F-$7C7C` = 0 (238 bytes), `$FF` at `$7C1F` (the end of table A) and at `$7C7C` (the end of table B).

Evidence: 12 runs in 11 builds, from StartGame.

Witness: L1 58 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1 call, 5,075 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 5,726 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 5,726 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 5,726 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 7,451 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 6,027 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 calls, 10,131 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage2/rec/sec-l5-s5` 1, `stage2/rec/sec-l5-s3` 1, `stage1/controls-sinclair` 1 and 21 more) |
| Called from | `StartGame` |
| Reads | `$7B8F`-`$7C7B` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |
| Writes | `$7B8F`-`$7C7C` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more) |

### `UpdateObjects` (`$865D`)

**Update the objects of both tables, then Rick and the records `$9BB4` and `$9BBD`**

With `$8A24` set (level 5's Fat Guy part) CALL `$C209` (LevelHookB: level 5's own code, JP `$F8D0`) instead of the tables. Else table A: `$A2F7` for every used record; table B: `$9EAF`. Then, unless SectionBusy is set: `$95ED` for Rick (`$9BAB`), `$91B0` for `$9BB4` when used, `$91EB` for `$9BBD` when used; `$A7F0` set: it and `$9BB4`'s +0 cleared; `$9BA9` set: `$9163` (the TimeBonus countdown).

Evidence: called by MainLoopPause every pass and by `$8A6D`; the hook `$C209` in rzx-l5-22000-poke (stage 1).

Witness: L1 120723 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,119 calls, 1,159,642 t-states own (0.09 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 341,404 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 310,588 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 317 calls, 361,018 t-states own (0.02 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 calls, 330,004 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 488 calls, 496,706 t-states own (0.53 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,931 calls, 10,231,635 t-states own (0.55 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 792,884 t-states own (0.56 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 288 calls, 62,797 t-states own (0.10 %) |
| Runs (the other recordings) | 49,247 calls (`stage2/rec/c48` 1,212, `stage1/rec/rzx-l1-14000-poke` 918, `stage1/rec/rzx-l1-06000-poke` 831 and 78 more) |
| Called from | `MainLoopPause`, `SetupSection` |
| Calls | `CountBonus`, `MoveBullet`, `UpdateDetonator`, `UpdateRick`, `UpdateEnemy`, `UpdateTrap` |
| Reads | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 9 more ranges |
| Writes | `$9BB4` (`BulletRecord`); `$A7F0` (`BulletSpent`) |

### `ScanMapObjects` (`$8B42`)

**Spawn the map entries that come into the view or whose trigger boxes fire**

Returns at once while LevelHookOn is set or the list is empty. From ScanStart, entry by entry (4 bytes and +3 bits 0-1 boxes of 4 bytes after it), until the 0 end or an entry whose row is ViewTop + 40 or more: an entry already alive (+0 bit 7) is skipped. With +2 bit 7 set the entry spawns when its row is in the view's first 8 rows or above the top or 32 rows or more below it (the rows the scroll brings in; every row while SpawnWholeView is set); the rows between are skipped. With +2 bit 7 clear its trigger boxes are tested (`$A69F` with BC = 0) and it spawns when one fires. A spawn is `$9C97` with IX at the entry.

Called each pass by the main loop (`$7D75`, 50 161) and by SetupSection (`$8AFE`, 95). Witness: 50 256 runs in 65 builds; 1982 spawns (`$8B96`).

Witness: L1 120707 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `ScanMapObjects` at work](img/routines/ScanMapObjects.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,119 calls, 2,129,387 t-states own (0.16 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 202,636 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 212,022 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 317 calls, 597,135 t-states own (0.03 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 calls, 378,636 t-states own (0.02 %) |
| Runs (controls-kempston: the Kempston method in play) | 488 calls, 972,096 t-states own (1.05 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,931 calls, 12,376,303 t-states own (0.66 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 868 calls, 198,349 t-states own (0.14 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 286 calls, 8,008 t-states own (0.01 %) |
| Runs (the other recordings) | 49,241 calls (`stage2/rec/c48` 1,212, `stage1/rec/rzx-l1-14000-poke` 918, `stage1/rec/rzx-l1-06000-poke` 831 and 78 more) |
| Called from | `MainLoopPause`, `SetupSection` |
| Calls | `ScanEntry` (falls into) |
| Reads | `$88CF` (`ViewTopRow`); `$8A24` (`LevelHookOn`); `$8B40`-`$8B41` (`ScanStart`); `$8BC0` (`SpawnWholeView`); `$EB62`-`$F21F` (`work space $EB62+`); `$F298`-`$F321` (`work space $F298+`); 1 more ranges |

### `ScanEntry` (`$8B56`)

**ScanMapObjects: the next entry; stop at the end or below the view**

HL: an entry's +0, C: ViewTop + 40, DE: 4. An entry alive (+0 bit 7) goes to ScanSkipEntry, else ScanDeadEntry.

Evidence: 447 209 runs in 65 builds.

Witness: L1 1040401 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 7,833 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,746 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,395 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,853 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2,280 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 3,416 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 72,660 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,442 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 12,359 calls (`stage1/rec/rzx-l2-22000-poke` 7,095, `stage1/rec/rzx-l3-04000-poke` 5,264) |
| Called from | `ScanMapObjects` (falls into), `ScanSkipBoxes` (tail) |
| Calls | `ScanSkipEntry` (falls into), `ScanDeadEntry` (tail) |
| Reads | `$EC8A`-`$ECAA` (`work space $EC8A+`); `$ED1C`-`$ED61` (`work space $ED1C+`); `$F0C6`-`$F147` (`work space $F0C6+`) |

### `ScanSkipEntry` (`$8B64`)

**ScanMapObjects: from +2 on to +3**

Evidence: 267 846 runs in 61 builds.

Witness: L1 610223 (box-shot, cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 588 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,440 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 834 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,260 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,704 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 54,126 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 720 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 7,950 calls (`stage1/rec/rzx-l2-22000-poke` 4,268, `stage1/rec/rzx-l3-04000-poke` 3,682) |
| Called from | `ScanEntry` (falls into), `ScanEdgeRows` (tail) |
| Calls | `ScanSkipBoxes` (falls into) |

### `ScanSkipBoxes` (`$8B65`)

**ScanMapObjects: past +3 and the entry's boxes (+3 bits 0-1 of them)**

Evidence: 397 475 runs in 65 builds.

Witness: L1 921310 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6,714 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,455 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,116 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,536 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,995 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,928 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 63,729 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 721 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 11,007 calls (`stage1/rec/rzx-l2-22000-poke` 6,413, `stage1/rec/rzx-l3-04000-poke` 4,594) |
| Called from | `ScanSkipEntry` (falls into), `ScanNextEntry` (tail) |
| Calls | `ScanEntry` (tail) |
| Reads | `$EC8D`-`$ECA9` (`work space $EC8D+`); `$ED1F`-`$ED5B` (`work space $ED1F+`); `$F0C9`-`$F141` (`work space $F0C9+`) |

### `ScanDeadEntry` (`$8B74`)

**ScanMapObjects: an entry not alive; HL on to +2**

Evidence: 174 646 runs in 65 builds.

Witness: L1 404091 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6,126 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 282 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 733 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,928 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 25,490 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 5,003 calls (`stage1/rec/rzx-l2-22000-poke` 3,577, `stage1/rec/rzx-l3-04000-poke` 1,426) |
| Called from | `ScanEntry` (tail) |
| Calls | `ScanSpawnRule` (falls into) |
| Reads | `$88CF` (`ViewTopRow`); `$8BC0` (`SpawnWholeView`); `$ECA0`-`$ECA8` (`work space $ECA0+`); `$ED1E`-`$ED5A` (`work space $ED1E+`) |

### `ScanSpawnRule` (`$8B75`)

**ScanMapObjects: +2 bit 7 set: spawn at the view's edge rows; clear: test the trigger boxes**

Evidence: 174 647 runs in 65 builds.

Witness: L1 404093 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6,126 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 282 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,284 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 733 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,928 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 25,490 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3,577 calls (`stage1/rec/rzx-l2-22000-poke` 3,577) |
| Called from | `ScanDeadEntry` (falls into) |
| Calls | `ScanEdgeRows` (falls into), `ScanSpawnHere` (tail), `ScanTriggerTest` (tail) |
| Reads | `$88CF` (`ViewTopRow`); `$8BC0` (`SpawnWholeView`); `$F0C7`-`$F124` (`work space $F0C7+`); `$F140` (`work space $F140+`) |

### `ScanEdgeRows` (`$8B85`)

**ScanMapObjects: the entry's row less the view's top: 0-7 or 32 up spawn, 8-31 skip**

Evidence: 46 215 runs in 54 builds.

Witness: L1 95612 (cheats, end-congrats, life-up, long-l4, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, load-l4, load-l5, sec-l2-s7, sec-l2-s12, sec-l4-s2, sec-l4-s11, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 442 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 15,902 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 514 calls (`stage1/rec/rzx-l3-04000-poke` 514) |
| Called from | `ScanSpawnRule` (falls into) |
| Calls | `ScanSkipEntry` (tail) |
| Reads | `$EC9F`-`$ECA3` (`work space $EC9F+`); `$ED1D` (`work space $ED1D+`); `$ED45` (`work space $ED45+`) |

### `ScanSpawnHere` (`$8B93`)

**ScanMapObjects: HL back to the entry's +0**

Evidence: 1540 runs in 57 builds.

Witness: L1 3643 (box-shot, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 6 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 94 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 33 calls (`stage1/rec/rzx-l3-04000-poke` 33) |
| Called from | `ScanSpawnRule` (tail) |
| Calls | `ScanSpawn` (falls into) |

### `ScanSpawn` (`$8B96`)

**ScanMapObjects: spawn the entry (`$9C97`, IX = the entry)**

Evidence: 1982 runs in 59 builds (from `$8B95` and `$8BBD`).

Witness: L1 4621 (box-shot, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 28 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 6 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 107 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 35 calls (`stage1/rec/rzx-l3-04000-poke` 35) |
| Called from | `ScanSpawnHere` (falls into), `ScanTriggerTest` (tail) |
| Calls | `ScanNextEntry` (falls into), `SpawnFromMap` |

### `ScanNextEntry` (`$8B9D`)

**ScanMapObjects: HL to +3, C and DE again, on past the boxes**

Evidence: 129 629 runs in 64 builds.

Witness: L1 311087 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6,126 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 282 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,276 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,928 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 9,603 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 912 calls (`stage1/rec/rzx-l3-04000-poke` 912) |
| Called from | `ScanSpawn` (falls into), `ScanTriggerTest` (tail) |
| Calls | `ScanSkipBoxes` (tail) |
| Reads | `$88CF` (`ViewTopRow`) |

### `ScanTriggerTest` (`$8BAC`)

**ScanMapObjects: test the entry's trigger boxes (`$A69F`, BC = 0); C: spawn**

Evidence: 128 087 runs in 62 builds; a fire 442 times (`$8BBC`).

Witness: L1 307440 (cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l3-load-l5, sec-l2-s10-sec-l2-s12, sec-l3-s3, sec-l3-s4, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6,126 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,268 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 2,928 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 9,509 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 879 calls (`stage1/rec/rzx-l3-04000-poke` 879) |
| Called from | `ScanSpawnRule` (tail) |
| Calls | `ScanSpawn` (tail), `ScanNextEntry` (tail), `TestTriggerBoxes` |

### `FindFirstMapEntry` (`$8BC1`)

**ScanStart = the first entry of SectionEntries whose row is ViewTop or more**

Skips an entry and its boxes while its row (+1) is above the view's top `$88CF`. An empty list (0) leaves ScanStart 0. Called at the end of BuildView (`$894A`).

Evidence: 269 runs in 62 builds.

Witness: L1 651 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 954 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 3 calls, 477 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 3,846 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 calls, 318 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 3,226 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 318 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 18 calls, 55,300 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 318 t-states own (0.00 %) |
| Runs (the other recordings) | 300 calls (`stage1/rec/rzx-l4-10000-poke` 11, `stage1/rec/rzx-l5-08000-poke` 10, `stage1/rec/rzx-l3-06000-poke` 10 and 74 more) |
| Called from | `BuildView` |
| Reads | `$88CF` (`ViewTopRow`); `$8B3E`-`$8B3F` (`SectionEntries`); `$EB62`-`$EC27` (`work space $EB62+`); `$EC66`-`$EC9F` (`work space $EC66+`); `$ECBC`-`$EDE3` (`work space $ECBC+`); `$EDFA`-`$EF03` (`work space $EDFA+`); 5 more ranges |
| Writes | `$8B40`-`$8B41` (`ScanStart`) |

### `DispatchByKind` (`$917D`)

**jump through KindHandlers by A AND 15**

A AND 15 indexes KindHandlers; the word is written into DispatchJump's operand and jumped to: 0 to `$0000` (a reset), 1 to `$A2F7` (the trap and pickup update), 2-14 to NoHandler (15 to `$3AC9`, the bytes after the table). Nothing calls or jumps here (no word `$917D` in the image) and no recording ran it: a dispatcher from an earlier design, kept in the code. Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NoHandler` (`$91AF`)

**RET the handler of kinds 2-14 in KindHandlers**

Not executed in any recording.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FindFreeTrapRecord` (`$9BC7`)

**Find a free 24-byte record in the `$7B8F` list**

Out: Z set and HL = the free record (+0 = 0); NZ when the list's `$FF` end comes first. Called by `$9D6C` (a map entry becomes a trap or a pickup). Ran 1471 times in 59 builds.

Witness: L1 3268 (box-shot, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 28 calls, 1,848 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 6 calls, 387 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 46 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 268 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 4 calls, 447 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 68 calls, 7,272 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 262 t-states own (0.00 %) |
| Runs (the other recordings) | 1,555 calls (`stage1/rec/rzx-l1-16000-poke` 471, `stage1/rec/rzx-l5-04000-poke` 179, `stage1/rec/rzx-l2-06000-poke` 71 and 68 more) |
| Called from | `SpawnMapObject` |
| Reads | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 1 more ranges |

### `FindFreeEnemyRecord` (`$9BD9`)

**Find a free 23-byte record in the `$7C20` list**

As FindFreeTrapRecord for the enemies' list. Called by `$9CDF`. Ran 474 times in 49 builds.

Witness: L1 1276 (life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 9 calls, 811 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2 calls, 134 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 271 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 135 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 38 calls, 2,577 t-states own (0.00 %) |
| Runs (the other recordings) | 592 calls (`stage1/rec/rzx-l5-10000-poke` 167, `stage2/rec/sec-l5-s5` 114, `stage1/rec/rzx-l2-14000-poke` 44 and 55 more) |
| Called from | `SpawnFromMap` |
| Reads | `$7C20` (`SetupIm2+6`); `$7C37` (`FillIm2TableLoop+12`); `$7C4E` (`Im2HandlerSource+21`); `$7C65` (`EntryDebris+9`); `$7C7C` (`ObjectTableBEnd`) |

### `FreeAllObjects` (`$9BEB`)

**Free every live record of both lists, and end the bullet and the detonator**

Calls `$9C57` (free the record, re-arm its map entry) for every record whose +0 is neither 0 nor `$FF`, in `$7B8F` (24 bytes) then `$7C20` (23 bytes); then BulletRecord +0 = DetonatorRecord +0 = 0. Called by the level start (`$7CD5`) and the section setup (`$8AE3`). Ran 103 times in 44 builds.

Witness: L1 287 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6 calls, 5,015 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 4 calls, 3,432 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 2 calls, 1,536 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3 calls, 2,406 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 1,567 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 2 calls, 1,606 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 14 calls, 12,540 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2 calls, 1,955 t-states own (0.00 %) |
| Runs (the other recordings) | 120 calls (`stage1/rec/rzx-l3-04000-poke` 7, `stage1/rec/rzx-l4-10000-poke` 6, `stage2/rec/c48` 6 and 56 more) |
| Called from | `LevelStart`, `SetupSection` |
| Calls | `FreeObject` |
| Reads | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 5 more ranges |
| Writes | `$9BB4`-`$9BBD` (`BulletRecord`, `DetonatorRecord`) |

### `RearmSectionList` (`$9C29`)

**clear bit 7 of the entries of one section's object list (an old form)**

IX = the section table (`$C202`'s word): HL = the word at IX+6/IX+7 read little-endian and absolute, then for each 4-byte entry RES 7 of +0 and skip +3 AND 3 boxes of 4 bytes; returns with IX on the next section's 8-byte entry. The live code (`$8AD0`) reads that word big-endian as an offset from the section table, and the loop's end test (JP Z after LD A,(HL)) uses stale flags, so it would stop after the first entry. Nothing calls it (no word `$9C29` in the image); not executed in any recording. Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FreeObject` (`$9C57`)

**Free the object record at IX and re-arm its map entry**

Clears bit 7 of the map entry the record points to (+`$0C`/+`$0D`; none when the word is 0) so the entry can spawn again, and clears +0, which frees the record. Called for every record when a section is set up (`$9BEB`), and when an object leaves the view (ShiftObjects, EnemyVertical, UpdateTrap).

Input IX: an enemy or trap record. Witness: 476 runs in 56 builds (callers `$9BFE` 239, `$9C19` 206, `$9E54` 124, `$9E7F` 100, `$A1CC` 13, `$A38E` 44, `$A39C` 39, `$A3CA` 69).

Witness: L1 1055 (fatguy-hits, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2, load-l4, sec-l2-s11, sec-l2-s12, sec-l4-s6, sec-l4-s11, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 8 calls, 824 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 10 calls, 1,022 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 419 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 52 calls, 5,414 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 3 calls, 310 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 12 calls, 1,248 t-states own (0.00 %) |
| Runs (the other recordings) | 452 calls (`stage1/rec/rzx-l3-04000-poke` 30, `stage1/rec/rzx-l3-06000-poke` 17, `stage1/rec/rzx-l4-08000-poke` 16 and 55 more) |
| Called from | `FreeAllObjects`, `ShiftObjects`, `EnemyVertical` (tail), `UpdateTrap` (tail), `TrapMoveRight` (tail) |
| Reads | `$7B9B`-`$7B9C` (`Entry+12`); `$7BB3`-`$7BB4` (`Entry48K`); `$7BCB`-`$7BCC` (`CopyMusic+12`); `$7BE3`-`$7BE4` (`CopyMusicLoop+19`); `$7BFB`-`$7BFC` (`BitReverseLoop+7`); `$7C13`-`$7C14` (`BitReverseLoop+31`); 15 more ranges |
| Writes | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 15 more ranges |

### `RetireObject` (`$9C69`)

**Free the record at IX; re-arm its map entry unless the entry is one-shot**

As FreeObject, but leaves bit 7 of the map entry set when the entry's +3 has bit 6 (the one-shot flag): the object never comes back. Used when an object is used up: an enemy that fell out of the view after it was killed (`$9FC2`), a trap at the end of a one-shot path (`$A348`) or removed by its trigger (`$A4A7`, `$A4C0`), a pickup taken (`$A598`, `$A5AD`, `$A5BD`).

Evidence: 548 runs in 57 builds.

Witness: L1 1408 (box-shot, cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l5, sec-l2-s7, sec-l2-s12, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 20 calls, 3,260 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 316 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 43 calls, 6,884 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 3 calls, 485 t-states own (0.00 %) |
| Runs (the other recordings) | 655 calls (`stage2/rec/sec-l5-s5` 122, `stage1/rec/rzx-l2-14000-poke` 45, `stage1/rec/rzx-l5-18000-poke` 33 and 63 more) |
| Called from | `EnemyFalling` (tail), `UpdateTrap` (tail), `TrapTriggers` (tail), `UpdatePickup` (tail) |
| Reads | `$7B9B`-`$7B9C` (`Entry+12`); `$7BB3`-`$7BB4` (`Entry48K`); `$7BCB`-`$7BCC` (`CopyMusic+12`); `$7BE3`-`$7BE4` (`CopyMusicLoop+19`); `$7BFB`-`$7BFC` (`BitReverseLoop+7`); `$7C13`-`$7C14` (`BitReverseLoop+31`); 22 more ranges |
| Writes | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 28 more ranges |

### `IsOffView` (`$9C86`)

**NZ when the y in HL lies outside the view**

HL: a y in pixels from the view's top. Z (A = 0) for 0-`$138`, NZ (A = 1) for a negative y or one from `$139` (313) up. Called after every y change (127 574 runs from UpdateTrap's `$A3C7` alone, 132 289 in all).

Witness: L1 306917 (cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 596 calls, 11,324 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 412 calls, 7,828 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 372 calls, 7,068 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 629 calls, 11,951 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 909 calls, 17,271 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 27,889 calls, 550,512 t-states own (0.03 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 820 calls, 16,363 t-states own (0.01 %) |
| Runs (the other recordings) | 123,708 calls (`stage1/rec/rzx-l5-14000-poke` 4,043, `stage1/rec/rzx-l1-12000-poke` 3,161, `stage1/rec/rzx-l5-02000-poke` 3,140 and 70 more) |
| Called from | `ShiftObjects`, `EnemyVertical`, `TrapMoveRight` |

### `SpawnFromMap` (`$9C97`)

**Bring the map entry at IX to life: an enemy, a trap or pickup, or the bonus countdown**

Called by the map scan at `$8B96` for an entry that came into the view or whose trigger box fired. Kinds below `$74` go to SpawnMapObject; `$78` starts the countdown bonus, `$7C` stops it and pays it; every other kind becomes an enemy. A full list (no free record) spawns nothing, and the entry stays unspawned (bit 7 clear) so the next scan tries again.

Evidence: 1982 runs in 59 builds (all from `$8B99`); SpawnMapObject 1471 of them, the enemy branch 474, the bonus start 18 (`$9CAC`, rzx-l1-00000-poke and 14 pieces of levels 2-5) and stop 19 (`$9CCA`).

Witness: L1 4621 (box-shot, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 28 calls, 1,008 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 15 calls, 13,879 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 2,692 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 8 calls, 7,529 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 6 calls, 5,991 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 107 calls, 104,669 t-states own (0.01 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 36 t-states own (0.00 %) |
| Runs (the other recordings) | 2,185 calls (`stage1/rec/rzx-l1-16000-poke` 473, `stage1/rec/rzx-l5-10000-poke` 189, `stage1/rec/rzx-l5-04000-poke` 181 and 68 more) |
| Called from | `ScanSpawn` |
| Calls | `StartTune`, `AddScore`, `FindFreeEnemyRecord`, `SpawnMapObject` (tail) |
| Reads | `$7C20` (`SetupIm2+6`); `$7C37` (`FillIm2TableLoop+12`); `$7C4E` (`Im2HandlerSource+21`); `$7C65` (`EntryDebris+9`); `$88CF` (`ViewTopRow`); `$9BA9` (`BonusRunning`); 12 more ranges |
| Writes | `$7B8F`-`$7C79` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2` and 2 more); `$7F19`-`$7F1B` (`TimeBonus+2`); `$9BA9`-`$9BAA` (`BonusRunning`, `BonusPrescaler`); `$EB62`-`$ECFC` (`work space $EB62+`); `$ED1C`-`$F09C` (`work space $ED1C+`); `$F0B0`-`$F1E4` (`work space $F0B0+`); 3 more ranges |

### `SpawnMapObject` (`$9D6C`)

**Spawn a trap or pickup from a map entry (kind below `$74`)**

Takes a free 24-byte record at `$7B8F` (`$9BC7`; none: return) and fills it from the level's kind table, the word at LevelHeader (11 bytes a kind, addressed by kind x 2 through the table of pointers there): +7 width, +8 height, +2 bits 6-7 into +0 and bits 0-5 x 4 (with the new kind's bits 0-5) into +`$15` (the kind to switch to), +3/+4 the path (+`$0F`/+`$10`), +5/+6 the animation (+`$0A`/+`$0B`), +7/+8 the second path (+`$11`/+`$12`), +9/+10 the second animation (+`$13`/+`$14`).

+0 = 1 OR bits 2-5 of the entry's +3 OR the kind table's bits 6-7: bit 0 alive, bit 1 path paused, bits 2-4 the trigger behaviour (UpdateTrap `$A4AA`), bit 5 a round trip (ArmTrapWait then sets +6 bit 3: switch at the loop point and back at the next; `$21`, `$29`, `$2D` in bits 0-5 are the pickups), bit 6 deadly to Rick and enemies, bit 7 an object to stand on (ObjectScanTest `$90C7`: a platform; with bit 6 a solid block, which also sets off a lit detonator it touches, `$A403`). Behaviour `$10` starts with +6 = `$60` (bit 6: no trigger test; bit 5: freed at the path's end), and with the one-shot bit (+3 bit 6) the record keeps no map entry (+`$0C`/+`$0D` = 0), so the entry is never re-armed. x = column x 8 (+4), y = (row - `$88CF`) x 8 (+3).

Evidence: 1471 runs in 59 builds, from c1 (28) on; the behaviour-`$10` branch 722 runs.

Witness: L1 3268 (box-shot, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 28 calls, 30,167 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 6 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 68 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1 call, 1,013 t-states own (0.00 %) |
| Runs (the other recordings) | 177 calls (`stage1/rec/rzx-l2-06000-poke` 71, `stage1/rec/rzx-l4-14000-poke` 16, `stage1/rec/rzx-l2-08000-poke` 16 and 10 more) |
| Called from | `SpawnFromMap` (tail) |
| Calls | `FindFreeTrapRecord` |
| Reads | `$88CF` (`ViewTopRow`); `$C200`-`$C201` (`work space $C200+`); `$EC70`-`$EC8F` (`work space $EC70+`); `$EDFA`-`$EE25` (`work space $EDFA+`); `$EE48`-`$EE63` (`work space $EE48+`); `$EE7C`-`$EEC1` (`work space $EE7C+`); 32 more ranges |
| Writes | `$7B8F`-`$7C1C` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2`); `$EC70`-`$EC8C` (`work space $EC70+`); `$EDFA`-`$EE22` (`work space $EDFA+`); `$EE48`-`$EE60` (`work space $EE48+`); `$EE7C`-`$EEBE` (`work space $EE7C+`); `$EEDE`-`$EF3E` (`work space $EEDE+`); 10 more ranges |

### `ShiftObjects` (`$9E31`)

**Shift every object's y by BC pixels after the view scrolled**

BC: the shift (signed). Adds it to the y of every live trap (`$7B8F`, 24 bytes a record) and enemy (`$7C20`, 23 bytes), to Rick's y `$9BAD`, the bullet's `$9BB6` and the detonator's `$9BBF`. A trap or enemy pushed out of the view is freed (FreeObject), a bullet or detonator switched off (`$9BB4`, `$9BBD` = 0); Rick is never tested.

Callers: the scroll routines `$78A5` (`$78F8`, 97 runs) and `$7905` (`$7958`, 89 runs): 186 runs in 52 builds (rzx pieces and sec-l4-*; not in c1, where Rick never leaves the first screen).

Witness: L1 372 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 4 calls, 6,252 t-states own (0.00 %) |
| Runs (the other recordings) | 182 calls (`stage1/rec/rzx-l5-08000-poke` 10, `stage1/rec/rzx-l1-10000-poke` 9, `stage1/rec/rzx-l3-00000-poke` 7 and 48 more) |
| Called from | `ScrollDown`, `ScrollUp` |
| Calls | `FreeObject`, `IsOffView` |
| Reads | `$7B8F`-`$7B92` (`Entry`); `$7BA7`-`$7BAA` (`Entry+24`); `$7BBF`-`$7BC2` (`CopyMusic`); `$7BD7`-`$7BDA` (`CopyMusicLoop+7`); `$7BEF`-`$7BF2` (`CopyMusicLoop+31`, `BuildMirrorTable`); `$7C07`-`$7C0A` (`BitReverseLoop+19`); 6 more ranges |
| Writes | `$7B91`-`$7B92` (`Entry+2`); `$7BA9`-`$7BAA` (`Entry+26`); `$7BC1`-`$7BC2` (`CopyMusic+2`); `$7BD9`-`$7BDA` (`CopyMusicLoop+9`); `$7BF1`-`$7BF2` (`BuildMirrorTable+1`); `$7C09`-`$7C0A` (`BitReverseLoop+21`); 5 more ranges |

### `TestTriggerBoxes` (`$A69F`)

**Test the trigger boxes after the map entry at IX: C when one fires**

IX: a map entry; its +3 bits 0-1 give the number of 4-byte boxes after it. BC: the record to leave out of the trap test (UpdateTrap's own record; 0 from the map scan), kept in the alternate set (EXX). For each box in turn: its rows are clipped to the view (a box above the view or 32 rows below ends the test with NC), then, as its +3 bits ask, tested against Rick (`$8D53`, skipped while he dies), the bullet (`$8C8D`; a hit sets BulletSpent so `$865D` removes the bullet), the detonator's blast at phase 5-10 (`$8CAE`), the punch box `$9BA3` (`$8C6C`), each live enemy (`$8DA3`) and each other trap (`$8DDF`).

A box that hits and has bit 7 clear fires: returns C with IX at the box, and sets bit 7 unless bit 6 asks it to fire on every pass. A box that hits with bit 7 set is passed over; one that misses has bit 7 cleared. No box fired: NC.

Callers: the map scan `$8BAC` (`$8BB5`, 128 087: spawns the entry on C) and UpdateTrap (`$A497`, 105 179). Witness: 233 266 runs in 64 builds (all recordings); a fire 2030 times; the enemy test only in rzx-l3-00000/02000/04000-poke.

Witness: L1 554196 (cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 6,126 calls, 5,561,339 t-states own (0.41 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 169,904 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 329,210 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,823 calls, 1,096,668 t-states own (0.06 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,140 calls, 480,225 t-states own (0.02 %) |
| Runs (controls-kempston: the Kempston method in play) | 2,928 calls, 2,561,271 t-states own (2.76 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 35,798 calls, 15,080,127 t-states own (0.81 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 722 calls, 755,014 t-states own (0.53 %) |
| Runs (the other recordings) | 236,153 calls (`stage1/rec/rzx-l5-16000-poke` 9,677, `stage1/rec/rzx-l5-18000-poke` 7,216, `stage2/rec/c48` 6,944 and 75 more) |
| Called from | `ScanTriggerTest`, `TrapTriggers` |
| Calls | `PunchHits`, `BulletHits`, `BlastHits`, `TouchesRick`, `TouchesObject`, `BoxesOverlap` |
| Reads | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 14 more ranges |
| Writes | `$A7F0` (`BulletSpent`); `$EB71`-`$EBF5` (`work space $EB71+`); `$EC0D`-`$EC99` (`work space $EC0D+`); `$ECAD`-`$ECEB` (`work space $ECAD+`); `$ED03`-`$F08D` (`work space $ED03+`); `$F0A1`-`$F219` (`work space $F0A1+`); 6 more ranges |

## levelload

`src/game/levelload.asm`

### `LoadLevel` (`$840C`)

**Read side B until the wanted level is in, then wait for fire**

`$7A61`, "START TAPE ON SIDE TWO" at `$4845` (PrintText), LoadLevelBlock; LevelNumber not equal to Level: again (the blocks before the wanted one are read and dropped). Then `$7A61`, "STOP TAPE AND PRESS FIRE" at `$4843` and LoadLevelWaitFire.

Evidence: 16 runs in 6 builds (load-l2 2, load-l3 3, load-l4 4, load-l5 5: one more than the level's block number, side B holding levels 1-5 in order; rzx-l3-10000-poke 1, rzx-l4-20000-poke 1 run the RZX run's version).

Witness: L1 18 (rzx-l3-10000-poke, rzx-l4-20000-poke, load-l2-load-l5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 4,219,838 t-states own (0.43 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 6,203,217 t-states own (0.43 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 8,298,564 t-states own (0.44 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 9,995,741 t-states own (0.43 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/rzx-l3-10000-poke` 1, `stage1/rec/rzx-l4-20000-poke` 1) |
| Called from | `LevelStart` |
| Calls | `ClearScreen`, `PrintText`, `LoadLevelBlock`, `LdBytes` |
| Reads | `$7EF1` (`Level`); `$C20C` (`work space $C20C+`) |

### `LoadLevelWaitFire` (`$8433`)

**Wait for fire, SPACE or ENTER after the load**

`$7229` until Z.

Evidence: 1 078 823 runs in 9 builds.

Witness: L1 1247039 (life-up, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 156,279 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 229,472 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 307,334 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 370,188 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2,262 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 61,094 t-states own (0.00 %) |
| Runs (the other recordings) | 89,621 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l2-00000-poke` 5,654, `docs/rec/life-up` 4,241, `stage2/rec/sec-l2-s10` 4,241 and 19 more) |
| Calls | `TestFireKeys` |

### `LoadLevelBlock` (`$846A`)

**Load one bit-reversed block of 21 760 bytes into `$A800`**

IX = `$A800`, DE = 21 760, A = `$FF` (the flag of a data block), carry set (load): LdBytes, then EI (the loader leaves interrupts off).

Evidence: 16 runs in 6 builds.

Witness: L1 18 (rzx-l3-10000-poke, rzx-l4-20000-poke, load-l2-load-l5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 132 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 198 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 264 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 5 calls, 330 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/rzx-l3-10000-poke` 1, `stage1/rec/rzx-l4-20000-poke` 1) |
| Called from | `LoadLevel` |
| Calls | `LdBytes` |
| Reads | `$7EF1` (`Level`); `$841B` (`LoadLevel+15`) |
| Writes | `$8510` (`LdSample+4`) |

### `LdBytes` (`$8479`)

**LD-BYTES with the bits reversed: IX the address, DE the length, A the flag**

The ROM's `$0556` step for step: DI, border 7 (`$0F`), LdBytesEnd pushed as the return, the leader, the sync, the flag byte, then the bytes. The differences from the ROM: each byte is shifted in from the top (L = `$80`, RR L), so the tape's bytes are stored bit-reversed; the verify branch is gone (every byte is stored); the end test is LD A,H / CPL / CP 1: carry when the XOR of the block was `$FF`. SPACE breaks (carry clear).

Evidence: 14 runs in 4 builds (load-l2 ... load-l5; writes `$A800-$FCFF`; port `$FE` in and out).

Witness: L1 14 (load-l2-load-l5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 32,363,421 t-states own (3.28 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 48,537,944 t-states own (3.39 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 64,714,046 t-states own (3.43 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 5 calls, 80,888,366 t-states own (3.47 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/rzx-l3-10000-poke`, `stage1/rec/rzx-l4-20000-poke`) |
| Called from | `LoadLevel`, `LoadLevelBlock` |
| Calls | `ClearScreen` (tail), `LdEdge2`, `LdEdge1`, `LdBytesEnd` |
| Reads | `$841B` (`LoadLevel+15`) |
| Writes | `$A800`-`$FCFF` (`work space $A800+`) |
| Ports in | `$0FFE` |
| Ports out | `$0FFE` |

### `LdEdge2` (`$8502`)

**Two edges (the ROM's LD-EDGE-2)**

LdEdge1 twice.

Evidence: 2 440 942 runs in 4 builds.

Witness: L1 2440942 (load-l2-load-l5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 348,706 calls, 7,671,532 t-states own (0.78 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 523,059 calls, 11,507,298 t-states own (0.80 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 697,412 calls, 15,343,064 t-states own (0.81 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 871,765 calls, 19,178,830 t-states own (0.82 %) |
| Called from | `LdBytes` |
| Calls | `LdEdge1` (falls into) |

### `LdEdge1` (`$8506`)

**One edge (the ROM's LD-EDGE-1): B counts the time, the border flashes**

A delay of `$16` loops, then B + 1 per sample of port `$FE` until the EAR bit changes; carry set on an edge (the border colour changed: (C AND 7) OR 8), clear on a time out (B wraps) or SPACE.

Evidence: 4 899 114 runs in 4 builds (port `$7FFE` in, `$FE` out).

Witness: L1 4899114 (load-l2-load-l5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 700,075 calls, 778,038,850 t-states own (78.93 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,049,877 calls, 1,162,559,933 t-states own (81.16 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,399,683 calls, 1,551,568,119 t-states own (82.26 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,749,479 calls, 1,942,126,797 t-states own (83.25 %) |
| Called from | `LdBytes`, `LdEdge2` (falls into) |
| Ports in | `$7FFE` |
| Ports out | `$09FE`, `$0AFE`, `$0DFE`, `$0EFE` |

### `LdBytesEnd` (`$8524`)

**The loader's return: black border, or the load error**

Carry (a good block): border 0, return to LoadLevelBlock. No carry: LoadError.

Evidence: 14 runs in 4 builds, every load good.

Witness: L1 14 (load-l2-load-l5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2 calls, 66 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3 calls, 98 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 132 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 5 calls, 164 t-states own (0.00 %) |
| Called from | `LdBytes` |
| Ports out | `$00FE` |

### `LoadError` (`$852A`)

**POP HL / JP `$8452`: a load error**

The code bytes POP HL (the return to LoadLevelBlock dropped) and JP `$8452`, an address inside "STOP TAPE AND PRESS FIRE" (`$8451`): it would run the text as code. Probably an address from an earlier layout. Not executed in any recording (no load failed); a bad block would run it.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DecryptMaps` (`$894E`)

**Decipher the last 768 bytes of the level's maps**

The 768 bytes from the maps' base (LevelHeader+4) + `$600`: each byte XOR a key that starts at 0 and becomes (key XOR the byte's address low byte) + 1 after each byte. Run once per loaded level, by the level start `$7CDB` after the tape load `$840C` (not for level 1 from side A, which is stored plain).

Evidence: 9 runs in 9 builds (load-l2 ... load-l5 and the RZX level starts 2-5, rzx-l5-full), each over `$E7ED-$ED6C` for levels with the base `$E1ED` (level 4) and the same 768 bytes above each base; the deciphered bytes equal the RZX run's memory (NOTES).

Witness: L1 50 (life-up, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `DecryptMaps` at work](img/routines/DecryptMaps.gif)

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1 call, 49,235 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1 call, 49,235 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 49,235 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1 call, 49,235 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1 call, 49,216 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`docs/rec/life-up` 1, `stage1/rec/rzx-l2-00000-poke` 1, `stage1/rec/rzx-l3-00000-poke` 1 and 19 more) |
| Called from | `DecryptLevel` |
| Reads | `$C204`-`$C205` (`work space $C204+`); `$E7ED`-`$ED6C` (`work space $E7ED+`) |
| Writes | `$E7ED`-`$ED6C` (`work space $E7ED+`) |

## enemies

`src/game/enemies.asm`

### `TestEnemyHits` (`$8BF3`)

**The enemy at IX against the bullet, the blast, the punch and Rick; C: the enemy is killed**

The enemy's box: x (IX+1) + 4, y (IX+2/+3), 16 x 21 pixels. In order: the bullet (record `$9BB4` live) inside the box (BulletHits): the bullet is spent (`$9BB4` = 0), return C. The detonator's blast at phase 4-9 (`$9BC6`) over the box widened to 24 (BlastHits): 50 points (Points50 `$7EF3`, AddScore `$7ED3`), return C; KillEnemy adds 50 more when the enemy is in the shown part of the view, so a blast kill gives 100. The punch (`$9BA3` set) inside the box (PunchHits): stunned, (IX+`$16`) = 40, effect 9, play goes on. Last Rick: when the box touches him (TouchesRick) he dies (`$93D0` at `$8C67`, the POKE file's immunity to enemies), return NC.

Called for every live enemy by `$9ECE`. Runs (l1q index): 49 093 in 69 builds: the bullet 43 kills (`$8C13`), the blast 5 (`$8C33`), the punch 9 stuns (`$8C57`: rzx-l1-24000-poke, rzx-l5-12000-poke); Rick touched 624 times (`$8C67` reached, nearly all in the immunity-POKE builds, whose POKE replaces the call), killed 18 times (KillRick's callers).

Witness: L1 96049 (cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 873 calls, 191,805 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 123,950 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 634 calls, 138,843 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 70 calls, 15,295 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,536 calls, 340,868 t-states own (0.02 %) |
| Runs (the other recordings) | 45,492 calls (`stage1/rec/rzx-l5-02000-poke` 1,885, `stage1/rec/rzx-l4-18000-poke` 1,675, `stage2/rec/sec-l3-s5` 1,446 and 62 more) |
| Called from | `EnemyHitsAndSprite` |
| Calls | `PlayEffect`, `AddScore`, `PunchHits`, `BulletHits`, `BlastHits`, `TouchesRick`, `KillRick` |
| Reads | `$7C21`-`$7C23` (`SetupIm2+7`); `$7C38`-`$7C3A` (`FillIm2TableLoop+13`, `Im2HandlerSource`); `$7C4F`-`$7C51` (`Im2HandlerSource+22`); `$7C66`-`$7C68` (`EntryDebris+10`); `$93D0` (`KillRick`); `$9BA3` (`PunchTimer`); 2 more ranges |
| Writes | `$7C4D` (`Im2HandlerSource+20`); `$7C64` (`EntryDebris+8`); `$9BB4` (`BulletRecord`) |

### `UpdateEnemy` (`$9EAF`)

**One pass of the enemy at IX**

A dying enemy goes to EnemyFalling. Otherwise the step flags EnemyOnStep and EnemyOnGround are cleared and the behaviour (+0 bits 0-1) chosen: 1 EnemyPatrol, 2 EnemyChaser, 0 and 3 EnemyWanderer.

Evidence (l1q index): 52 717 runs in 75 builds (load-l2 873, load-l3 558, load-l4 634, the rzx pieces, c48, cheats; none in c1 or the controls-* recordings), all from `$8695`.

Witness: L1 103355 (cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

[Animation: `UpdateEnemy` at work](img/routines/UpdateEnemy.gif)

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 873 calls, 111,029 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 67,011 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 634 calls, 65,610 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 128 calls, 10,379 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2,383 calls, 214,970 t-states own (0.01 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 35 calls, 1,194 t-states own (0.00 %) |
| Runs (the other recordings) | 48,234 calls (`stage1/rec/rzx-l5-02000-poke` 1,920, `stage1/rec/rzx-l4-18000-poke` 1,675, `stage1/rec/rzx-l1-24000-poke` 1,454 and 67 more) |
| Called from | `UpdateObjects` |
| Calls | `EnemyFalling` (tail), `EnemyWanderer` (tail), `EnemyChaser` (tail), `EnemyPatrol` (tail) |
| Reads | `$7C20` (`SetupIm2+6`); `$7C34`-`$7C37` (`FillIm2TableLoop+9`); `$7C4B`-`$7C4E` (`Im2HandlerSource+18`); `$7C62`-`$7C65` (`EntryDebris+6`); `$7C79` (`EntryDebris+29`) |
| Writes | `$9F4C`-`$9F4D` (`EnemyMoveFlags`, `EnemyOnGround`) |

### `EnemyHitsAndSprite` (`$9ECE`)

**Test what hits the enemy, then pick its sprite**

`$8BF3` tests the bullet, the detonator's blast, the punch box (a stun: +`$16` = 40 passes, effect 9) and Rick (Rick dies, `$93D0`); C (the bullet or the blast hit) kills the enemy (KillEnemy). A stunned enemy keeps its sprite. A climbing one alternates Sprites 32 and 33 every two passes; a walking one takes EnemyWalkSprites[(+9 / 4)] and +9 moves on by 2 (wrapping at 12): a new frame every second pass.

The step 1 (`$9F32`) and step 4 (`$9F3B`) need EnemyAnimSlow or EnemyAnimFast, which nothing writes: not executed in any recording. Runs (l1q index): 49 093 in 69 builds (from EnemyWanderer 9734, EnemyChaser 12 139, EnemyPatrol 27 224); KillEnemy from here 48 times (the bullet 43, the blast 5).

Witness: L1 96049 (cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 873 calls, 318,727 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 213,629 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 634 calls, 238,723 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 70 calls, 26,347 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,536 calls, 581,178 t-states own (0.03 %) |
| Runs (the other recordings) | 45,492 calls (`stage1/rec/rzx-l5-02000-poke` 1,885, `stage1/rec/rzx-l4-18000-poke` 1,675, `stage2/rec/sec-l3-s5` 1,446 and 62 more) |
| Called from | `EnemyWanderer`, `EnemyChaser`, `EnemyPatrol` |
| Calls | `TestEnemyHits`, `KillEnemy` (tail) |
| Reads | `$7C20`-`$7C7B` (`SetupIm2+6`, `Im2HandlerSource`, `EntryDebris`); `$9F4E`-`$9F55` (`EnemyAnimFast`, `EnemyWalkSprites`) |
| Writes | `$7C24`-`$7C6E` (`SetupIm2+10`, `Im2HandlerSource`, `EntryDebris`) |

### `KillEnemy` (`$9F56`)

**An enemy is hit: score, effect, and it flies off**

When the enemy is in the shown part (y from `$40` to `$FF`), effect 10 and 50 points (the digits at `$7EF3`, 000050, through `$7ED3`). Then +`$14` = `$FF` (dying), the speed -5 pixels a pass (upwards) and the drift +`$15` = 2 when x < `$74`, else -2 (towards the screen's middle).

Callers: EnemyHitsAndSprite (`$9ED1`, 48: the bullet 43 and the blast 5), EnemyVertical (`$A0E8`, 34: a deadly cell) and UpdateTrap (`$A454`, 220: a deadly trap, 102 of them in sec-l5-s5). Witness: 302 runs in 48 builds (the jumps taken: the runs of `$9ED1` less those of `$9ED4`, and so on); 50 points (Points50) when the enemy's y is `$40-$FF`, so a blast kill gives 100 with TestEnemyHits' 50.

Witness: L1 606 (cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, load-l5, sec-l2-s7, sec-l2-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 2 calls, 532 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 29 calls, 7,841 t-states own (0.00 %) |
| Runs (the other recordings) | 232 calls (`stage2/rec/sec-l5-s5` 102, `stage1/rec/rzx-l2-14000-poke` 43, `stage1/rec/rzx-l3-08000-poke` 16 and 21 more) |
| Called from | `EnemyHitsAndSprite` (tail), `EnemyVertical` (tail), `TrapMoveRight` |
| Calls | `PlayEffect`, `AddScore` |
| Reads | `$7C21`-`$7C23` (`SetupIm2+7`); `$7C38`-`$7C3A` (`FillIm2TableLoop+13`, `Im2HandlerSource`); `$7C4F`-`$7C51` (`Im2HandlerSource+22`); `$7C66`-`$7C68` (`EntryDebris+10`) |
| Writes | `$7C2E`-`$7C7A` (`FillIm2TableLoop+3`, `Im2HandlerSource`, `EntryDebris`) |

### `EnemyFalling` (`$9F8D`)

**The killed enemy's fall: gravity, drift, a spinning sprite, freed below the view**

Speed += `$80` a pass (to 8 pixels), y += speed; once y passes 255 (+3 not 0) the record is retired (RetireObject). x += the drift; the sprite is Sprites 31 (+6 for the second set), the mirror bit toggled every second pass.

Evidence: 3308 runs in 47 builds, all from UpdateEnemy (`$9EB3`).

Witness: L1 7298 (cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-16000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, load-l5, sec-l2-s7, sec-l2-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 58 calls, 30,058 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 847 calls, 434,734 t-states own (0.02 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 35 calls, 19,281 t-states own (0.01 %) |
| Runs (the other recordings) | 2,738 calls (`stage1/rec/rzx-l5-12000-poke` 147, `stage1/rec/rzx-l2-02000-poke` 144, `stage1/rec/rzx-l2-20000-poke` 132 and 49 more) |
| Called from | `UpdateEnemy` (tail) |
| Calls | `RetireObject` (tail) |
| Reads | `$7C20`-`$7C7A` (`SetupIm2+6`, `Im2HandlerSource`, `EntryDebris`) |
| Writes | `$7C21`-`$7C75` (`SetupIm2+7`, `Im2HandlerSource`, `EntryDebris`) |

### `EnemyWanderer` (`$9FF7`)

**Behaviours 0 and 3: walk, and turn at random on the 16-pixel grid**

EnemyVertical, EnemyWalk with the step +6, EnemyHitsAndSprite; then, when not climbing and x AND 15 = 4, one chance in 4 (`$81AF` AND 3 = 0) of a new random direction (2 or -2).

Evidence (l1q index): 9734 runs in 25 builds (c48 142, load-l2 582, load-l3 279, the rzx pieces); a new direction 317 times (`$A021`).

Witness: L1 18465 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, c48, load-l2, load-l3, sec-l2-s7, sec-l2-s11, sec-l2-s12, sec-l3-s5, sec-l4-s12, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 582 calls, 83,156 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 38,014 t-states own (0.00 %) |
| Runs (the other recordings) | 8,873 calls (`stage2/rec/sec-l3-s5` 1,446, `stage2/rec/sec-l2-s7` 1,098, `stage1/rec/rzx-l4-18000-poke` 1,088 and 20 more) |
| Called from | `UpdateEnemy` (tail) |
| Calls | `Random`, `EnemyHitsAndSprite`, `EnemyVertical`, `EnemyWalk` |
| Reads | `$7C21`-`$7C76` (`SetupIm2+7`, `Im2HandlerSource`, `EntryDebris`) |
| Writes | `$7C26` (`SetupIm2+12`); `$7C3D` (`Im2HandlerSource+4`); `$7C54` (`Im2HandlerSource+27`); `$7C6B` (`EntryDebris+15`) |

### `EnemyChaser` (`$A025`)

**Behaviour 2: walk; on the grid, at a floor, turn towards Rick or at random**

As EnemyWanderer, but the turn is tested only when the probe (`$915E`) shows floor (bits 1-2) and no step (bit 6), at x AND 15 = 4: half the time (`$81AF` negative) towards Rick's x `$9BAC`, otherwise a random direction.

Evidence (l1q index): 12 139 runs in 40 builds; the turn branches only in rzx-l2-20000-poke and rzx-l4-02000/04000-poke (13 runs).

Witness: L1 24057 (cheats, life-up, rzx-l1-02000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-full, load-l2, load-l5, sec-l2-s12, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 37,516 t-states own (0.00 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 70 calls, 8,979 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,536 calls, 197,997 t-states own (0.01 %) |
| Runs (the other recordings) | 10,312 calls (`stage1/rec/rzx-l5-02000-poke` 1,366, `stage1/rec/rzx-l2-00000-poke` 664, `stage2/rec/cheats` 566 and 35 more) |
| Called from | `UpdateEnemy` (tail) |
| Calls | `Random`, `EnemyHitsAndSprite`, `EnemyVertical`, `EnemyWalk` |
| Reads | `$7C21`-`$7C26` (`SetupIm2+7`); `$7C38`-`$7C3D` (`FillIm2TableLoop+13`, `Im2HandlerSource`); `$7C4F`-`$7C54` (`Im2HandlerSource+22`); `$7C66`-`$7C6B` (`EntryDebris+10`); `$915E` (`CollisionFlags`); `$9BAC` (`RickX`) |
| Writes | `$7C26` (`SetupIm2+12`); `$7C3D` (`Im2HandlerSource+4`); `$7C6B` (`EntryDebris+15`) |

### `EnemyPatrol` (`$A06E`)

**Behaviour 1: walk +`$13` passes (2 pixels each), turn, again**

EnemyVertical; then, unless the probe shows a step without floor, counts +`$12` up and turns (+6 negated) when it reaches the patrol length +`$13`; then EnemyWalk and EnemyHitsAndSprite.

Evidence (l1q index): 27 224 runs in 52 builds (load-l3, load-l4, the rzx pieces).

Witness: L1 53535 (rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, load-l3, load-l4, sec-l2-s10, sec-l2-s12, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 53,072 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 634 calls, 118,714 t-states own (0.01 %) |
| Runs (the other recordings) | 26,311 calls (`stage1/rec/rzx-l3-10000-poke` 1,402, `stage1/rec/rzx-l4-00000-poke` 1,317, `stage1/rec/rzx-l5-18000-poke` 1,171 and 47 more) |
| Called from | `UpdateEnemy` (tail) |
| Calls | `EnemyHitsAndSprite`, `EnemyVertical`, `EnemyWalk` |
| Reads | `$7C26`-`$7C78` (`SetupIm2+12`, `Im2HandlerSource`, `EntryDebris`); `$915E` (`CollisionFlags`) |
| Writes | `$7C26`-`$7C77` (`SetupIm2+12`, `Im2HandlerSource`, `EntryDebris`) |

### `EnemyVertical` (`$A0A1`)

**An enemy's vertical move: gravity, landing, ceilings, steps, ladders**

A climbing enemy goes to EnemyClimb. Otherwise speed += `$80` (to 8 pixels a pass), the new y probed (`$8FF9`) at x. A deadly cell (bit 5) kills (KillEnemy). A step (bit 6): EnemyOnStep set, the enemy put on the step's y (`$915F` - 21), speed 1, probed again; a floor there lands it (EnemyHitCeiling's snap), else the probe bits `$42` are forced. A ladder (bit 4) under a behaviour-3 enemy at x AND 15 = 4 with Rick above starts the climb (+`$11` = `$FF`). A floor while falling (or bit 2) lands it (EnemyLand: EnemyOnGround, y snapped to the cell, speed 1); a ceiling while rising (bit 1 only) stops the rise (EnemyHitCeiling); no floor: the new y stored, and an enemy that fell out of the view is freed (FreeObject).

Evidence: 37 765 runs in 55 builds; the landing 34 085, the ceiling snap 16 (rzx-l5-14000-poke only), the climb 786 (13 builds).

Witness: L1 96057 (cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 873 calls, 617,690 t-states own (0.06 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 400,201 t-states own (0.03 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 634 calls, 469,309 t-states own (0.02 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 70 calls, 48,690 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,536 calls, 1,089,377 t-states own (0.06 %) |
| Runs (the other recordings) | 45,496 calls (`stage1/rec/rzx-l5-02000-poke` 1,885, `stage1/rec/rzx-l4-18000-poke` 1,675, `stage2/rec/sec-l3-s5` 1,446 and 62 more) |
| Called from | `EnemyWanderer`, `EnemyChaser`, `EnemyPatrol` |
| Calls | `TestBodyBox`, `FreeObject` (tail), `IsOffView`, `KillEnemy` (tail) |
| Reads | `$7C20`-`$7C76` (`SetupIm2+6`, `Im2HandlerSource`, `EntryDebris`); `$915E`-`$9160` (`CollisionFlags`, `PlatformTop`); `$9BAD`-`$9BAE` (`RickY`) |
| Writes | `$7C22`-`$7C76` (`SetupIm2+8`, `Im2HandlerSource`, `EntryDebris`); `$915E` (`CollisionFlags`); `$9F4C`-`$9F4D` (`EnemyMoveFlags`, `EnemyOnGround`) |

### `EnemyWalk` (`$A213`)

**An enemy's horizontal move: D = the x step**

A stunned enemy (+`$16`) counts down and stands. A climbing one does not walk. An enemy on a step walks with the push `$9161` alone (D = 0); one standing on a moving thing with `$9162` set stands (+9 = 0). An enemy in the air does not walk (+9 = 0). Otherwise x += D + the push `$9161`, turning at the edges 0 and `$E8`; the new x probed (`$8FF9`, C = `$FF`): a wall (bit 1) turns it and snaps x to the cell edge; at x AND 15 = 4 a ladder top (bit 3) under a behaviour-3 enemy with Rick above starts the climb.

Evidence: 37 763 runs in 55 builds; the wall turn on the right 144 runs (27 builds).

Witness: L1 96053 (cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s8, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 873 calls, 284,563 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 180,697 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 634 calls, 227,261 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 70 calls, 24,028 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,536 calls, 530,938 t-states own (0.03 %) |
| Runs (the other recordings) | 45,494 calls (`stage1/rec/rzx-l5-02000-poke` 1,885, `stage1/rec/rzx-l4-18000-poke` 1,675, `stage2/rec/sec-l3-s5` 1,446 and 62 more) |
| Called from | `EnemyWanderer`, `EnemyChaser`, `EnemyPatrol` |
| Calls | `TestBodyBox` |
| Reads | `$7C20`-`$7C7B` (`SetupIm2+6`, `Im2HandlerSource`, `EntryDebris`); `$915E`-`$9162` (`CollisionFlags`, `PlatformTop`, `PlatformDx`, `PlatformDy`); `$9BAD`-`$9BAE` (`RickY`); `$9F4C`-`$9F4D` (`EnemyMoveFlags`, `EnemyOnGround`) |
| Writes | `$7C21`-`$7C6E` (`SetupIm2+7`, `Im2HandlerSource`, `EntryDebris`); `$9F4D` (`EnemyOnGround`) |

## collision

`src/game/collision.asm`

### `PunchHits` (`$8C6C`)

**C when the punch's point (`$9BA5`, `$9BA6`) lies in the box (E, HL, C x B)**

Inside when 0 <= x - E < C and 0 <= y - HL < B. Callers: TestEnemyHits (`$8C51`, 386), `$A76C` (the trigger boxes, 271). Witness: 657 runs in 34 builds.

Witness: L1 1314 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l3-00000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 77 calls, 4,076 t-states own (0.00 %) |
| Runs (the other recordings) | 580 calls (`stage1/rec/rzx-l1-08000-poke` 66, `stage1/rec/rzx-l1-24000-poke` 65, `stage1/rec/rzx-l5-12000-poke` 36 and 30 more) |
| Called from | `TestEnemyHits`, `TestTriggerBoxes` |
| Reads | `$9BA5`-`$9BA7` (`PunchX`, `PunchY`) |

### `PunchHitsFar` (`$8C8B`)

**XOR A / RET: the punch 256 or more pixels below**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BulletHits` (`$8C8D`)

**C when the bullet's point (`$9BB5`, `$9BB6`) lies in the box (E, HL, C x B)**

As PunchHits. Callers: TestEnemyHits (`$8C0B`, 717), `$A5DE` (pickups, 123), `$A729` (trigger boxes, 43). Witness: 883 runs in 33 builds.

Witness: L1 1824 (box-shot, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 36 calls, 1,596 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 19 calls, 868 t-states own (0.00 %) |
| Runs (the other recordings) | 857 calls (`stage1/rec/rzx-l1-02000-poke` 93, `stage1/rec/rzx-l2-22000-poke` 90, `stage1/rec/rzx-l5-12000-poke` 69 and 30 more) |
| Called from | `TestEnemyHits`, `UpdatePickup`, `TestTriggerBoxes` |
| Reads | `$9BB5`-`$9BB7` (`BulletX`, `BulletY`) |

### `BulletHitsFar` (`$8CAC`)

**XOR A / RET: the bullet 256 or more pixels below**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BlastHits` (`$8CAE`)

**C when the detonator's blast (24 x 29 from `$9BBE`, `$9BBF` - 4) overlaps the box (E, HL, C x B)**

Overlap when -24 < x - E < C and -29 < (y - 4) - HL < B. Callers: TestEnemyHits (`$8C2B`, 173), `$A755` (trigger boxes, 194), level 5's `$F938` (14). Witness: 381 runs in 26 builds.

Witness: L1 762 (rzx-l1-00000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 50 calls, 4,993 t-states own (0.00 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 8 calls, 1,248 t-states own (0.00 %) |
| Runs (the other recordings) | 323 calls (`stage1/rec/rzx-l5-06000-poke` 54, `stage1/rec/rzx-l4-18000-poke` 36, `stage1/rec/rzx-l2-00000-poke` 24 and 21 more) |
| Called from | `TestEnemyHits`, `TestTriggerBoxes` |
| Reads | `$9BBE`-`$9BC0` (`DetonatorX`, `DetonatorY`) |

### `BlastBorrow` (`$8CCD`)

**DEC H: the bomb's y - 4 borrowing from its high byte**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BlastCompareY` (`$8CCE`)

**BlastHits, continued: the y overlap**

Evidence: 105 runs in 21 builds.

Witness: L1 210 (rzx-l1-00000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 20 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 8 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 77 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l1-12000-poke` 10, `stage1/rec/rzx-l5-12000-poke` 10, `stage1/rec/rzx-l5-10000-poke` 9 and 16 more) |

### `BlastHitsFar` (`$8CE6`)

**XOR A / RET: 256 or more pixels apart**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PointInObject` (`$8CE8`)

**C when the point (E, HL) lies in the record at IX: (IX+1) < E <= (IX+1) + (IX+7), 0 <= HL - y < (IX+8)**

Called by ProbePoint for the solid objects. Witness: 336 runs in 18 builds; a hit twice.

Witness: L1 672 (rzx-l1-00000-poke, rzx-l1-12000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l4-02000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l5-02000-poke, rzx-l5-08000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 146 calls, 8,446 t-states own (0.00 %) |
| Runs (the other recordings) | 190 calls (`stage1/rec/rzx-l5-08000-poke` 29, `stage1/rec/rzx-l3-02000-poke` 21, `stage1/rec/rzx-l2-02000-poke` 18 and 14 more) |
| Called from | `ProbePoint` |
| Reads | `$7B90`-`$7B97` (`Entry+1`); `$7BA8`-`$7BAF` (`Entry+25`); `$7BC0`-`$7BC7` (`CopyMusic+1`); `$7BD8`-`$7BDE` (`CopyMusicLoop+8`); `$7BF0`-`$7BF6` (`BuildMirrorTable`, `BitReverseLoop`) |

### `ProbePoint` (`$8D0C`)

**What lies at the point (E, HL): 2 for a solid object, else the flags of the view cell there**

The 24-byte records at `$7B8F` up to the `$FF` end: one whose +0 has bits 7 and 6 set and holds the point (PointInObject) gives A = 2. Else A = CellFlags[ViewCells[(HL / 8) x 32 + E / 8]] (bit 1: a wall).

Callers: the bullet's flight `$91BD` (755) and level 5's `$FAD0` (335). Witness: 1090 runs in 44 builds; a solid object twice (rzx-l2-12000-poke, rzx-l4-10000-poke).

Witness: L1 2485 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 62 calls, 45,958 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 746 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 146 calls, 115,376 t-states own (0.01 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 83 calls, 60,809 t-states own (0.04 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 157 calls, 115,364 t-states own (0.18 %) |
| Runs (the other recordings) | 840 calls (`stage1/rec/rzx-l5-20000-poke` 258, `stage1/rec/rzx-l1-02000-poke` 54, `stage1/rec/rzx-l2-22000-poke` 41 and 39 more) |
| Called from | `MoveBullet` |
| Calls | `PointInObject` |
| Reads | `$6CC3`-`$6CDC` (`ViewCells+451`); `$6CFA`-`$6D08` (`ViewCells+506`); `$6D27`-`$6D94` (`ViewCells+551`); `$6DA7`-`$6DDC` (`ViewCells+679`); `$6DED`-`$6E6B` (`ViewCells+749`); `$6E87`-`$6E8A` (`ViewCells+903`); 10 more ranges |

### `TouchesRick` (`$8D53`)

**C when the box (E, HL, C x B) overlaps Rick's box**

Overlap when -16 < (`$9BAC` + 4) - E < C and -B < HL - Rick's y <= 20 (15 crawling; his y 5 lower then). Callers: TestEnemyHits (`$8C63`, 37 713), `$93B1` (the blast, 324), the traps `$A470` (83 559), the trigger boxes `$A6FE` (99 544), level 5's `$F943` and `$FAC8`. Witness: 222 000 runs in 64 builds.

Witness: L1 535245 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 2,289 calls, 167,994 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 1,355 calls, 96,609 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,338 calls, 105,828 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2,073 calls, 145,566 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,210 calls, 87,768 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 936 calls, 66,360 t-states own (0.07 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 36,093 calls, 2,898,566 t-states own (0.16 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,634 calls, 198,850 t-states own (0.14 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 426 calls, 35,134 t-states own (0.06 %) |
| Runs (the other recordings) | 226,023 calls (`stage1/rec/rzx-l5-18000-poke` 8,579, `stage1/rec/rzx-l5-16000-poke` 7,769, `stage2/rec/sec-l5-s5` 5,984 and 76 more) |
| Called from | `TestEnemyHits`, `BurnFuse`, `TrapMoveRight`, `TestTriggerBoxes` |
| Reads | `$9B98` (`RickCrawling`); `$9BAC`-`$9BAE` (`RickX`, `RickY`) |

### `TouchRickFar` (`$8D95`)

**XOR A / RET: 256 or more pixels apart**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TouchRickAbove` (`$8D97`)

**TouchesRick, continued: the box's top above Rick's**

Evidence: 18 534 runs in 57 builds.

Witness: L1 42082 (cheats, fatguy-hits, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l3-load-l5, sec-l2-s11, sec-l4-s x5, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 57 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 98 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 27 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,950 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 752 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 41 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 18,240 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l5-18000-poke` 1,165, `stage1/rec/rzx-l5-14000-poke` 1,120, `stage1/rec/rzx-l2-20000-poke` 770 and 58 more) |

### `TouchesObject` (`$8DA3`)

**C when the box (E, HL, C x B) overlaps the 16 x 21 box of the record at IX (x (IX+1) + 4)**

Callers: the traps `$A451` (62 770, the enemies against a trap), `$A79A` (the trigger boxes, 683). Witness: 63 453 runs in 52 builds.

Witness: L1 164733 (cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s11, sec-l2-s12, sec-l3-s5, sec-l4-s2, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 873 calls, 68,925 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 558 calls, 45,703 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,250 calls, 126,999 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 210 calls, 23,193 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 3,822 calls, 414,335 t-states own (0.02 %) |
| Runs (the other recordings) | 77,190 calls (`stage2/rec/sec-l2-s12` 4,118, `stage1/rec/rzx-l4-18000-poke` 3,931, `stage1/rec/rzx-l5-18000-poke` 3,857 and 57 more) |
| Called from | `TrapMoveRight`, `TestTriggerBoxes` |
| Reads | `$7C21`-`$7C23` (`SetupIm2+7`); `$7C38`-`$7C3A` (`FillIm2TableLoop+13`, `Im2HandlerSource`); `$7C4F`-`$7C51` (`Im2HandlerSource+22`); `$7C66`-`$7C68` (`EntryDebris+10`) |

### `TouchObjSameY` (`$8DDD`)

**SCF / RET: the same y, a hit**

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `BoxesOverlap` (`$8DDF`)

**C when the box (E, HL, C x B) overlaps the record at IX's own box (+7 wide, +8 tall)**

Callers: ProbeGround (`$8ED8`, `$8F18`), `$90E6` and `$912B` (109 000 each), `$A416`, `$A57D`, `$A7D7`. Witness: 196 030 runs in 59 builds.

Witness: L1 460108 (box-shot, cheats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7, sec-l3-s9, sec-l4-s x5, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,898 calls, 192,210 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,344 calls, 181,454 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,542 calls, 108,690 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3,593 calls, 322,180 t-states own (0.02 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 977 calls, 82,603 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 25,538 calls, 2,430,700 t-states own (0.13 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 699 calls, 64,732 t-states own (0.05 %) |
| Runs (the other recordings) | 199,639 calls (`stage1/rec/rzx-l4-14000-poke` 10,089, `stage1/rec/rzx-l4-04000-poke` 9,877, `stage1/rec/rzx-l5-02000-poke` 9,563 and 67 more) |
| Called from | `ProbeObjectsScan`, `ObjectScanTest`, `TestSolidObject`, `TrapMoveRight`, `UpdatePickup`, `TestTriggerBoxes` |
| Reads | `$7B90`-`$7B97` (`Entry+1`); `$7BA8`-`$7BAF` (`Entry+25`); `$7BC0`-`$7BC7` (`CopyMusic+1`); `$7BD8`-`$7BDF` (`CopyMusicLoop+8`); `$7BF0`-`$7BF7` (`BuildMirrorTable`, `BitReverseLoop`); `$7C08`-`$7C0F` (`BitReverseLoop+20`) |

### `ProbeGround` (`$8E1C`)

**What the bomb at (E, HL) touches: the flags of its cells and the one below, and the objects; into `$915E`**

The probe is 8 pixels wide from x + 8 and 16 tall from y. The cells it covers (1 or 2 rows, 1 or 2 columns, from ViewCells) give CellFlags bits 1 and 5; the row under it gives bits 1, 2 and 5. Then the records at `$7B8F` (the alive ones, +0 bit 7): with +0 bit 6 (solid) one overlapping the probe (16 x 8 box) sets bit 1; without bit 6, while the fall speed `$93CD` is not negative, one whose top (its +8 set to 8 + `$93CD`) holds the probe's bottom row sets bit 6 and gives its y (`$915F`) and +`$16` (`$9161`): a platform to stand on.

The result `$915E`: bit 1 solid, bit 2 floor, bit 5 deadly (the bomb's code goes to `$93B8`), bit 6 an object platform. The probe's coordinates are stored into the instructions at `$8ECC-$8ED3` and `$8F10-$8F13`.

A platform lower than the one already found jumps to `$9113` (`$8EEA`), the tail of another scan (`$9090`'s loop): not taken in any recording (94 tests); a copy slip, it seems.

Callers: the bomb's fall `$91EB` (`$9222` 5704, `$9247` 202), `$9320` (5610). Witness: 5812 runs in 34 builds: 108 for each bomb dropped (c1, controls-*).

Witness: L1 11948 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 108 calls, 87,803 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 108 calls, 88,083 t-states own (0.09 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 995 calls, 1,005,932 t-states own (0.05 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 144 calls, 123,611 t-states own (0.09 %) |
| Runs (the other recordings) | 4,781 calls (`stage1/rec/rzx-l4-04000-poke` 216, `stage1/rec/rzx-l1-12000-poke` 216, `stage1/rec/rzx-l2-10000-poke` 216 and 29 more) |
| Called from | `UpdateDetonator`, `DetonatorSlowRight` |
| Reads | `$6C4F`-`$6C50` (`ViewCells+335`); `$6C6F`-`$6C70` (`ViewCells+367`); `$6C8F` (`ViewCells+399`); `$6CC7`-`$6F27` (`ViewCells+455`); `$6F46`-`$6F47` (`ViewCells+1094`); `$6F66`-`$6F67` (`ViewCells+1126`); 15 more ranges |
| Writes | `$7B97` (`Entry+8`); `$7BAF` (`Entry+32`); `$7BC7` (`CopyMusic+8`); `$7BDF` (`CopyMusicLoop+15`); `$7BF7` (`BitReverseLoop+3`); `$7C0F` (`BitReverseLoop+27`); 3 more ranges |

### `ProbeRising` (`$8E9D`)

**LD A,(`$915E`) / AND `$FB` / LD (`$915E`),A: no floor bit while rising**

Reached from `$8E9A` when `$93CD` is negative; no recording ran it. The code after it (`$8EA5`) then adds 8 to the flags, not to the speed.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ProbeObjectsScan` (`$8EA5`)

**ProbeGround, continued: the objects at `$7B8F`**

A = the fall speed's high byte `$93CD`: the platform test's height is 8 + it.

Evidence: 5812 runs in 34 builds.

Witness: L1 11948 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 108 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 108 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 995 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 144 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 4,781 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l1-04000-poke` 216, `stage1/rec/rzx-l1-12000-poke` 216, `stage1/rec/rzx-l2-00000-poke` 216 and 29 more) |
| Calls | `BoxesOverlap` |

## rick

`src/game/rick.asm`

### `TestCrawlBox` (`$8F29`)

**Test a crawling Rick's box at (E, HL) against the map cells, then the platforms**

Input: HL = the box's top y (whole pixels, from the view's top), E = its left x, C = the vertical speed's high byte (`$80`: cells only, no objects; `$FF`: a sideways probe; negative: rising). Stores HL at BodyBoxY+1 and HL+20 (the feet line) at FeetLineY+1, E+4 at BodyBoxX+1 and FeetLineX+1 (the operands of the object tests that follow). The top row of the box only feeds CeilingOverCrawl (bit 1 of its 2 or 3 cells: something solid over the crawling Rick, so he cannot stand up); then 1 or 2 body rows (2 when y AND 7 >= 4) and the feet row go into A, masked as in TestBodyBox but for the middle column of the body rows (`$15`: bits 0, 2, 4). 3 columns when (E+4) AND 7 is not 0, else 2. Ends in TestBoxObjects with A.

Callers: UpdateRick (`$9654`, `$9693`) and RickMoveX (`$9979`), when RickCrawling is set. Ran 7666 times in 43 builds (c1 40, the RZX level pieces).

Witness: L1 15400 (rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-18000-poke, rzx-l5-full, sec-l1-s8, c1).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 40 calls, 30,548 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,211 calls, 889,378 t-states own (0.05 %) |
| Runs (the other recordings) | 6,469 calls (`stage1/rec/rzx-l3-08000-poke` 598, `stage1/rec/rzx-l1-02000-poke` 478, `stage1/rec/rzx-l1-22000-poke` 473 and 39 more) |
| Called from | `UpdateRick`, `RickLandOrFall`, `RickMoveX` |
| Calls | `TestBoxObjects` (tail) |
| Reads | `$6C65`-`$6C66` (`ViewCells+357`); `$6C85`-`$6C86` (`ViewCells+389`); `$6CA0`-`$6EA2` (`ViewCells+416`); `$6EC0`-`$6EC2` (`ViewCells+960`); `$6EE0`-`$6EE2` (`ViewCells+992`); `$A800`-`$A8FE` (`work space $A800+`) |
| Writes | `$8FF8` (`CeilingOverCrawl`); `$90DF`-`$90E2` (`FeetLineY+1`, `FeetLineX`); `$9124`-`$9127` (`BodyBoxY+1`, `BodyBoxX`) |

### `TestBodyBox` (`$8FF9`)

**Test a standing body's box at (E, HL) against the map cells, then the platforms**

Input and output as TestCrawlBox: HL = the box's top y, E = its left x, C = the vertical speed's high byte (`$80` no objects, `$FF` a sideways probe, negative rising); out: CollisionFlags (and A) with the cells' flags, PlatformTop, PlatformDx, PlatformDy from TestBoxObjects. The box is 2 or 3 body rows (3 when y AND 7 >= 4) and the feet row below them, 2 or 3 columns from x+4. Body rows mask the cells' flags with `$22` (solid, deadly) at the sides and `$2A` (and the ladder) in the middle, or `$3A` each when only 2 columns are touched; the feet row with `$27`, `$3F`, `$27` (adding the special surface and the floor one jumps through), or every bit.

Used by Rick (UpdateRick `$965E`, `$9699`; RickMoveX `$997F`; ClimbLadder `$9ADF`; UpdateRide `$94CB`, `$9550`) and by the enemies (`$A0DE`, `$A102`, `$A1FB`, `$A289`): 166 811 runs in 65 builds, the routine every recording runs most in this range.

Witness: L1 414834 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,915 calls, 1,428,418 t-states own (0.11 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,106 calls, 1,851,165 t-states own (0.19 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,544 calls, 1,368,261 t-states own (0.10 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,846 calls, 1,640,042 t-states own (0.09 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 730 calls, 635,422 t-states own (0.03 %) |
| Runs (controls-kempston: the Kempston method in play) | 915 calls, 1,119,405 t-states own (1.21 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 19,692 calls, 14,183,380 t-states own (0.76 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,777 calls, 2,355,104 t-states own (1.66 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 460 calls, 558,589 t-states own (0.88 %) |
| Runs (the other recordings) | 181,711 calls (`stage1/rec/rzx-l5-02000-poke` 5,725, `stage1/rec/rzx-l4-18000-poke` 4,369, `stage1/rec/rzx-l1-24000-poke` 4,197 and 78 more) |
| Called from | `UpdateRide`, `UpdateRick`, `RickLandOrFall`, `RickMoveX`, `ClimbLadder`, `EnemyVertical`, `EnemyWalk` |
| Calls | `TestBoxObjects` (falls into) |
| Reads | `$6B23`-`$7039` (`ViewCells+35`); `$7058`-`$7059` (`ViewCells+1368`); `$7B8F`-`$7B92` (`Entry`); `$7BA5`-`$7BAA` (`Entry+22`); `$7BBD`-`$7BBF` (`Entry48K+10`, `CopyMusic`); `$7BD7`-`$7BDA` (`CopyMusicLoop+7`); 5 more ranges |
| Writes | `$7B97` (`Entry+8`); `$7BAF` (`Entry+32`); `$7BC7` (`CopyMusic+8`); `$7BDF` (`CopyMusicLoop+15`); `$7BF7` (`BitReverseLoop+3`); `$7C0F` (`BitReverseLoop+27`); 3 more ranges |

### `TestBoxObjects` (`$9090`)

**Store the cells' flags, then test the box against the platforms and blocks of the `$7B8F` list**

A = the cells' flags, C' = the vertical speed's high byte given to the box test. Stores A in CollisionFlags and returns when C' = `$80`. Else sets the platforms' tested height (SetPlatformHeight's operand) to C' + 8, so that a fast fall cannot pass through a platform, clears bit 2 of the flags while rising (C' negative), sets PlatformTop = `$FFFF` and PlatformDx = PlatformDy = 0, and walks the records at `$7B8F` (24 bytes each, the end a `$FF` byte) through ObjectScanLoop.

Ran 174 475 times in 65 builds (callers `$8FB8`, `$8FF5`, `$906A`, `$908E`: the four ends of the two box tests).

Witness: L1 430228 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,955 calls, 933,004 t-states own (0.07 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,106 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,544 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1,846 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 730 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 915 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 20,903 calls, 13,037,980 t-states own (0.70 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 1,777 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 460 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 108,854 calls (`stage1/rec/rzx-l4-18000-poke` 4,513, `stage1/rec/rzx-l1-24000-poke` 4,227, `stage1/rec/rzx-l1-08000-poke` 4,185 and 39 more) |
| Called from | `TestCrawlBox` (tail), `TestBodyBox` (falls into) |
| Calls | `ObjectScanLoop` (falls into) |
| Reads | `$7B8F`-`$7B92` (`Entry`); `$7BA5`-`$7BAA` (`Entry+22`); `$7BBD`-`$7BC2` (`Entry48K+10`, `CopyMusic`); `$7BD5`-`$7BDA` (`CopyMusicLoop+5`); `$7BED`-`$7BF2` (`CopyMusicLoop+29`, `BuildMirrorTable`); `$7C05`-`$7C0A` (`BitReverseLoop+17`); 2 more ranges |
| Writes | `$7B97` (`Entry+8`); `$7BAF` (`Entry+32`); `$7BC7` (`CopyMusic+8`); `$7BDF` (`CopyMusicLoop+15`); `$7BF7` (`BitReverseLoop+3`); `$7C0F` (`BitReverseLoop+27`); 2 more ranges |

### `ObjectScanLoop` (`$90BE`)

**Skip the records whose +0 has bit 7 clear (free or a plain trap or pickup)**

Part of TestBoxObjects: HL steps through the `$7B8F` records 24 bytes at a time (BC = 24) until one whose kind byte +0 is negative.

Witness: L1 2945010 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 13,685 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 14,721 calls, 322,151 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 10,794 calls, 242,129 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 12,922 calls, 277,920 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 4,844 calls, 103,712 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 6,405 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 138,313 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 12,124 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 3,220 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 420,538 calls (`stage1/rec/rzx-l2-00000-poke` 27,986, `stage2/rec/sec-l3-s5` 26,950, `stage1/rec/rzx-l5-18000-poke` 26,201 and 24 more) |
| Called from | `TestBoxObjects` (falls into), `ObjectScanNext` (tail) |
| Calls | `ObjectScanNext` (falls into), `ObjectScanTest` (tail) |
| Reads | `$7B8F` (`Entry`); `$7BA7` (`Entry+24`); `$7BBF` (`CopyMusic`); `$7BD7` (`CopyMusicLoop+7`); `$7BEF` (`CopyMusicLoop+31`); `$7C07` (`BitReverseLoop+19`); 1 more ranges |

### `ObjectScanNext` (`$90C3`)

**Step to the next 24-byte record**

Part of TestBoxObjects; also the way back from PlatformScanNext and SolidScanNext.

Witness: L1 2524296 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 11,730 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 12,618 calls, 265,244 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 9,252 calls, 194,292 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 11,076 calls, 233,033 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 4,152 calls, 87,249 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 5,490 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 118,554 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 10,392 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 2,760 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 360,462 calls (`stage1/rec/rzx-l2-00000-poke` 23,988, `stage2/rec/sec-l3-s5` 23,100, `stage1/rec/rzx-l5-18000-poke` 22,458 and 24 more) |
| Called from | `ObjectScanLoop` (falls into), `TestSolidObject` (tail) |
| Calls | `ObjectScanLoop` (tail) |

### `ObjectScanTest` (`$90C7`)

**A record with bit 7: the end, a block (bit 6) or a platform to stand on**

+0 = `$FF` ends the scan (RET). Bit 6 set: TestSolidObject. Else a platform: skipped while rising (C' negative); else its height +8 is set to C' + 8 and the box test `$8DDF` checks the line of Rick's feet (y+20, x+4, 1 high, 16 wide) against the record (+1 x, +2/+3 y, +7 width, +8 height). On a hit whose top (+2/+3) is higher than PlatformTop: PlatformTop = that y, PlatformDx/PlatformDy = the record's +`$16`/+`$17` (its motion, carried to what stands on it), CollisionFlags bit 6 set.

Ran 360 933 times in 65 builds.

Witness: L1 858411 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,955 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 4,206 calls, 92,627 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 3,084 calls, 67,848 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 5,156 calls, 119,364 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,384 calls, 30,448 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 915 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 39,775 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 3,174 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 460 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 98,181 calls (`stage2/rec/sec-l3-s5` 7,700, `stage1/rec/rzx-l5-18000-poke` 7,486, `stage2/rec/sec-l4-s12` 7,316 and 24 more) |
| Called from | `ObjectScanLoop` (tail) |
| Calls | `BoxesOverlap`, `TestSolidObject` (tail) |

### `TestSolidObject` (`$911E`)

**A block object (bits 7 and 6): test the whole body box against it**

The box test `$8DDF` with the body's box (top y, x+4, 21 high, 16 wide) against the record. On a hit whose top is higher than PlatformTop: PlatformTop = that y, no motion carried (PlatformDx = PlatformDy = 0), CollisionFlags bits 6 and 1 set (stands on it, and it is solid).

Ran 86 440 times in 41 builds (levels 2-5 and level 1's RZX pieces: the levels with block objects).

Witness: L1 208417 (life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s11, sec-l2-s12, sec-l3-s5, sec-l3-s7, sec-l3-s9, sec-l4-s1, sec-l4-s6, sec-l4-s11, sec-l4-s12, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 2,103 calls, 321,911 t-states own (0.03 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 1,542 calls, 235,926 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 3,310 calls, 506,753 t-states own (0.03 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 692 calls, 112,275 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 18,205 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 38,105 calls (`stage2/rec/sec-l3-s5` 3,850, `stage1/rec/rzx-l5-18000-poke` 3,743, `stage2/rec/sec-l2-s7` 3,691 and 24 more) |
| Called from | `ObjectScanTest` (tail) |
| Calls | `BoxesOverlap`, `ObjectScanNext` (tail) |
| Reads | `$7B91`-`$7B92` (`Entry+2`); `$7BA9`-`$7BAA` (`Entry+26`); `$7BC1`-`$7BC2` (`CopyMusic+2`); `$7BD9`-`$7BDA` (`CopyMusicLoop+9`); `$7C09`-`$7C0A` (`BitReverseLoop+21`); `$915E`-`$9160` (`CollisionFlags`, `PlatformTop`) |
| Writes | `$915E`-`$9162` (`CollisionFlags`, `PlatformTop`, `PlatformDx`, `PlatformDy`) |

### `KillRick` (`$93D0`)

**Rick dies: the cry, a jump up and a fall off the view**

Returns at once while RickDying is set. Else RickDying = `$FF`; when `$8A24` is not 0 (level 5's own code is running) it becomes 20; effect 10 (`$7A97`, the death sound); RickDy = -5.0 (a jump up); DeathDrift = -2 when Rick's x >= `$74` (right half), else +2 (he drifts to the middle); then the first DeathFall pass.

Callers (`$93D0` in l1q): `$8C67` (an enemy touch) 18, `$9668` (a deadly cell) 13, `$93B4` (the detonator's blast) 8, `$A475` (a trap) 6, `$9988` (a deadly cell met sideways) 3, `$FACB` (level 5's code) 1 (l1q's caller counts, 49 in all). The entry ran 75 times in 15 builds: c1 8, c48 10, each control recording 4, load-l2 12, load-l3 6, load-l4 1, rzx-l3-02000/04000/06000-poke 4, rzx-l5-18000-poke and rzx-l5-20000-poke 1 each, rzx-l5-full 16. The level 5 branch ran once (rzx-l5-20000-poke).

Witness: L1 121 (controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2-load-l4).

[Animation: `KillRick` at work](img/routines/KillRick.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 8 calls, 1,004 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 12 calls, 632 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 6 calls, 316 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 1 call, 176 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 16 calls, 2,482 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 4 calls, 458 t-states own (0.00 %) |
| Runs (the other recordings) | 16 calls (`stage2/rec/c48` 10, `stage1/rec/rzx-l3-04000-poke` 2, `stage1/rec/rzx-l5-20000-poke` 1 and 3 more) |
| Called from | `TestEnemyHits`, `BurnFuse` (tail), `RickLandOrFall` (tail), `RickMoveX` (tail), `TrapMoveRight` |
| Calls | `PlayEffect`, `DeathFall` (falls into) |
| Reads | `$8A24` (`LevelHookOn`); `$9B9C`-`$9BAC` (`RickDying`, `RickOnGround`, `RickIceSlide`, `MudStep` and 11 more) |
| Writes | `$8A24` (`LevelHookOn`); `$945C` (`DeathDrift`); `$9B95`-`$9B9C` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 3 more) |

### `DeathFall` (`$9405`)

**One pass of the death fall: gravity, drift, the two death sprites**

From KillRick, then from UpdateRick every pass while RickDying is set (863 times). RickDy += 0.5 (no limit), the 24-bit y moves by it, x moves by DeathDrift; when y passes 255 (high byte not 0) DeathFallOver is set (the main loop `$7D2D` ends the life there). The sprite alternates 15 and 16 every two passes (RickStep AND 3, bit 1).

Ran 895 times in 14 builds; DeathFallOver set 35 times.

Witness: L1 1778 (controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2-load-l4).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 124 calls, 43,933 t-states own (0.00 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 54 calls, 19,151 t-states own (0.00 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 21 calls, 7,423 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 27 calls, 9,556 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 24 calls, 8,505 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 384 calls, 135,909 t-states own (0.01 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 58 calls, 20,540 t-states own (0.03 %) |
| Runs (the other recordings) | 359 calls (`stage2/rec/c48` 98, `stage1/rec/rzx-l3-04000-poke` 64, `stage1/rec/rzx-l3-02000-poke` 36 and 6 more) |
| Called from | `KillRick` (falls into), `UpdateRick` (tail) |
| Reads | `$945C` (`DeathDrift`); `$9B95`-`$9B9A` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 1 more); `$9BAC`-`$9BAE` (`RickX`, `RickY`) |
| Writes | `$9B95`-`$9B9B` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 2 more); `$9BAC`-`$9BB0` (`RickX`, `RickY`, `RickSprite`) |

### `UpdateRide` (`$945E`)

**Rick in the vehicle: thrust up and down, move 4 pixels sideways, fire with fire alone**

Gravity 0.25 a pass, the speed kept within -4.0..+4.0; neither up nor down: only gravity; up: -0.75 a pass (net -0.5); down: +0.5. The 24-bit y moves by RickDy and TestBodyBox checks the new box: solid or floor stops it (RickDy = 0), rising under the cell edge or landing on it ((y + 12) OR 7 - 20). Left or right moves x by 4 (and the facing); x below 0 sets the exit `$88D3` = 1, x above `$E8` sets 2; a solid cell snaps x as RickMoveX does. The sprite is 12. Fire (released between shots, one bullet at a time) calls FireBullet: no up key needed here.

Ran 3045 times in 6 builds: rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke.

Witness: L1 6090 (rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 3,045 calls (`stage1/rec/rzx-l4-12000-poke` 706, `stage1/rec/rzx-l2-22000-poke` 683, `stage1/rec/rzx-l5-08000-poke` 669 and 3 more) |
| Called from | `UpdateRick` (tail) |
| Calls | `TestBodyBox`, `FireBullet` |
| Reads | `$7253` (`Controls`); `$915E` (`CollisionFlags`); `$9B95`-`$9B97` (`RickDy`, `RickYFrac`); `$9BA8`-`$9BB4` (`FireLatch`, `BonusRunning`, `BonusPrescaler`, `RickRecord` and 1 more) |
| Writes | `$88D3` (`ExitDirection`); `$9B95`-`$9B97` (`RickDy`, `RickYFrac`); `$9BA8`-`$9BB1` (`FireLatch`, `BonusRunning`, `BonusPrescaler`, `RickRecord`) |

### `UpdateRick` (`$95ED`)

**Rick's pass: death fall, ride or climb, else gravity, the vertical move and its test**

IX = RickRecord (the object step `$86A9`, every pass, 50 260 times in 65 builds). RickDying: DeathFall. RideMode: UpdateRide. RickClimbing: ClimbLadder. Else clears RickOnGround, RickIceSlide, MudStep, IceStep, ShootPose and DetonatorPose, counts PunchTimer down to 0, adds the gravity 0.5 to RickDy (at most 8.0), moves the 24-bit y by it and tests the new box (TestCrawlBox when crawling, else TestBodyBox, with C = RickDy's high byte); then RickLandOrFall.

Witness: L1 120719 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `UpdateRick` at work](img/routines/UpdateRick.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,119 calls, 551,403 t-states own (0.04 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 132,748 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 142,500 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 317 calls, 160,544 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 calls, 156,358 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 488 calls, 255,655 t-states own (0.28 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,931 calls, 13,966,066 t-states own (0.75 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 869 calls, 1,186,770 t-states own (0.84 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 288 calls, 128,880 t-states own (0.20 %) |
| Runs (the other recordings) | 49,244 calls (`stage2/rec/c48` 1,212, `stage1/rec/rzx-l1-14000-poke` 918, `stage1/rec/rzx-l1-06000-poke` 831 and 78 more) |
| Called from | `UpdateObjects` |
| Calls | `TestCrawlBox`, `TestBodyBox`, `DeathFall` (tail), `UpdateRide` (tail), `RickLandOrFall` (falls into), `ClimbLadder` (tail) |
| Reads | `$7253` (`Controls`); `$7EF1` (`Level`); `$8066` (`CheatInfinite`); `$8B3D` (`Detonators`); `$8FF8` (`CeilingOverCrawl`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); 4 more ranges |
| Writes | `$88D3` (`ExitDirection`); `$8B3D` (`Detonators`); `$9161` (`PlatformDx`); `$93CA`-`$93CD` (`DetonatorDx`, `DetonatorDy`); `$9B95`-`$9BC6` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 19 more) |

### `RickLandOrFall` (`$9663`)

**Deadly: die; on a platform: stand on it; else RickCellCollision**

Deadly cell (bit 5): KillRick. On a platform or block (bit 6): y = PlatformTop - 21, fraction 0, RickOnGround = `$FF`, and the cells at that place are tested again (C = `$80`, PlatformDx kept): deadly kills, solid or floor goes to RickHeadBump, else RickDy = 1.0 (standing) and on to RickStoreRestDy. Also the end of ClimbLadder (`$9AE5`).

Ran 46 352 times in 62 builds.

Witness: L1 112914 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,000 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 239 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 259 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 465 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,560 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 869 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 232 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 10,385 calls (`stage1/rec/rzx-l1-06000-poke` 831, `stage1/rec/rzx-l1-00000-poke` 727, `stage1/rec/rzx-l5-18000-poke` 705 and 13 more) |
| Called from | `UpdateRick` (falls into), `ClimbLadder` (tail) |
| Calls | `TestCrawlBox`, `TestBodyBox`, `KillRick` (tail), `RickCellCollision` (tail) |
| Reads | `$7253` (`Controls`); `$8FF8` (`CeilingOverCrawl`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$9B96`-`$9B99` (`RickDy+1`, `RickYFrac`, `RickCrawling`, `RickClimbing`); `$9BAC` (`RickX`) |
| Writes | `$9161` (`PlatformDx`); `$9B95`-`$9BAE` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 17 more) |

### `RickCellCollision` (`$96B4`)

**React to the cells: land, bump the head, start a climb down, or keep falling**

One-way floor (bit 2): RickLanded. No solid (bit 1 clear): RickInAir. Solid while rising: RickHeadBump. Solid while falling: RickLanded.

Ran 43 705 times in 62 builds.

Witness: L1 107620 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,000 calls, 1,102,293 t-states own (0.08 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 239 calls, 104,064 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 259 calls, 286,859 t-states own (0.02 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 291 calls, 328,446 t-states own (0.02 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 calls, 320,861 t-states own (0.01 %) |
| Runs (controls-kempston: the Kempston method in play) | 465 calls, 503,706 t-states own (0.54 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,015 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 824 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 232 calls, 100,713 t-states own (0.16 %) |
| Runs (the other recordings) | 24,302 calls (`stage2/rec/c48` 1,118, `stage1/rec/rzx-l1-06000-poke` 831, `stage1/rec/rzx-l2-18000-poke` 732 and 44 more) |
| Called from | `RickLandOrFall` (tail) |
| Calls | `RickInAir` (tail) |
| Reads | `$7253` (`Controls`); `$7EF1` (`Level`); `$8066` (`CheatInfinite`); `$8B3D` (`Detonators`); `$8FF8` (`CeilingOverCrawl`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); 3 more ranges |
| Writes | `$88D3` (`ExitDirection`); `$8B3D` (`Detonators`); `$93CA`-`$93CD` (`DetonatorDx`, `DetonatorDy`); `$9B95`-`$9BC6` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 19 more) |

### `WeakJumpLevel1` (`$9799`)

**level 1's special surface, the jump speed -2.0**

HL = -2.0 (the speed an up key would give), then RickCrouchCheck. Not executed in any recording: level 1's cell flags have bit 0 in one cell kind only. Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LaunchPadLevel5` (`$979F`)

**Level 5's special surface throws Rick up at -2175/256 a pass**

Level 5: RickDy = -2175/256 (about -8.5), without a key, then RickWalk. Other levels (2, 4): RickCrouchCheck with the jump speed -6.0. Ran 719 times in 10 builds (levels 2 and 4 mostly); the launch 5 times (rzx-l5-16000-poke).

Witness: L1 4062 (long-l4, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-14000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-16000-poke, rzx-l5-16000-poke, sec-l4-s1, sec-l4-s6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`, `stage1/load-l2`, `stage1/load-l3`, `stage1/load-l4`, `stage1/load-l5`, `stage1/controls-kempston`, `stage1/rec/rzx-l5-full`, `stage1/rec/rzx-l5-22000-poke`, `stage1/rec/rzx-l5-23000`, `docs/rec/fatguy-hits`; in the other recordings 2,031 runs of its first instruction, entered by a jump (`stage2/rec/sec-l4-s1` 510, `stage2/rec/long-l4` 411, `stage2/rec/sec-l4-s6` 391 and 10 more) |
| Calls | `RickWalk` (tail), `RickShootUp` (tail), `RickActionDone` (tail), `DropDetonator` (tail) |

### `RickInAir` (`$985F`)

**Store the new y; stand up when the ceiling allows; grab a ladder with up or down**

Ran 13 698 times in 61 builds.

Witness: L1 27940 (controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l3-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 97 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 23 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 14 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 36 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 1,580 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 69 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,613 calls (`stage1/rec/rzx-l4-14000-poke` 466, `stage1/rec/rzx-l5-18000-poke` 432, `stage1/rec/rzx-l5-04000-poke` 225 and 7 more) |
| Called from | `RickCellCollision` (tail) |
| Calls | `RickWalk` (tail) |
| Reads | `$7253` (`Controls`); `$8FF8` (`CeilingOverCrawl`); `$915E` (`CollisionFlags`); `$9B98` (`RickCrawling`) |
| Writes | `$9B97`-`$9B99` (`RickYFrac`, `RickCrawling`, `RickClimbing`); `$9BAD`-`$9BAE` (`RickY`) |

### `RickWalk` (`$988F`)

**Leave a climb without a ladder; the sideways keys and the special surfaces**

Climbing with no ladder cell (bit 3) left: the climb ends, and while rising RickDy = -2.0 (a hop off the ladder's top, 33 times). Left: facing left, step -2; right: facing right, step +2; level 4's special surface (mud) makes the step 1 (MudStep), level 2's (ice) speeds the walk animation (IceStep = 2). Neither key: RickNoWalk.

Ran 45 590 times in 62 builds; the mud branch 34 + 253 times (level 4), the ice 133 + 104 (level 2).

Witness: L1 111389 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 955 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 239 calls, 173,685 t-states own (0.02 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 259 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 450 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,443 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 863 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 228 calls, 92,913 t-states own (0.15 %) |
| Runs (the other recordings) | 5,987 calls (`stage1/rec/rzx-l3-08000-poke` 797, `stage1/rec/rzx-l5-18000-poke` 704, `stage1/rec/rzx-l2-04000-poke` 697 and 11 more) |
| Called from | `LaunchPadLevel5` (tail), `RickInAir` (tail), `RickActionDone` (tail) |
| Calls | `RickMoveX` (tail) |
| Reads | `$7253` (`Controls`); `$7EF1` (`Level`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$9AA9`-`$9AB6` (`WalkFrames`, `CrawlFrames`); `$9B96`-`$9BB1` (`RickDy+1`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 17 more) |
| Writes | `$88D3` (`ExitDirection`); `$9B95`-`$9BB1` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 17 more) |

### `RickMoveX` (`$9941`)

**Move x by the step plus PlatformDx; the view's side edges; walls and deadly cells**

x + step: below 0 sets x = 0 and the exit `$88D3` = 1 (to the section on the left), above `$E8` sets x = `$E8` and `$88D3` = 2. The box test (C = `$FF`) at the new x: deadly kills (KillRick from `$9988`); solid snaps x to the cell's edge ((x + 12) AND `$F8` - 4 going left, (x + 3) AND `$F8` - 4 going right); else x is stored, and a climb ends where no ladder cell is left.

Ran 45 592 times in 62 builds; the left edge 1230 times, the right edge 33.

Witness: L1 111393 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 955 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 239 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 259 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 450 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,443 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 863 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 228 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 42 calls (`stage1/rec/rzx-l4-20000-poke` 21, `stage2/rec/end-congrats` 21) |
| Called from | `RickWalk` (tail) |
| Calls | `TestCrawlBox`, `TestBodyBox`, `KillRick` (tail), `PickRickSprite` (tail) |
| Reads | `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$9AA9`-`$9AB2` (`WalkFrames`); `$9B98`-`$9BAE` (`RickCrawling`, `RickClimbing`, `RickStep`, `DeathFallOver` and 15 more) |
| Writes | `$88D3` (`ExitDirection`); `$9B9A` (`RickStep`); `$9BAC`-`$9BB0` (`RickX`, `RickY`, `RickSprite`) |

### `PickRickSprite` (`$99C5`)

**Choose Rick's sprite from his state**

Climbing: 13 or 14 by (x XOR y) bit 2. In the air: 8 (crawling: the crawl frames). On the ground: punching 1, or 10 while PunchTimer runs (the stick out); shooting 9; a detonator dropped: 0, or 11 while DetonatorDx is not 0 (a throw); sliding on ice 0; else RickWalkCycle. The address goes to RickSprite.

Ran 46 336 times in 62 builds.

Witness: L1 112880 (box-shot, cheats, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, end-congrats, fatguy-hits, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 1,000 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 239 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 259 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 465 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 8,549 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 869 calls, 249,017 t-states own (0.18 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 232 calls, 63,664 t-states own (0.10 %) |
| Runs (the other recordings) | 9,564 calls (`stage1/rec/rzx-l1-06000-poke` 831, `stage1/rec/rzx-l1-00000-poke` 727, `stage1/rec/rzx-l2-04000-poke` 702 and 13 more) |
| Called from | `RickMoveX` (tail), `RickActionDone` (tail) |
| Calls | `PlayEffect` |
| Reads | `$93CA`-`$93CB` (`DetonatorDx`); `$9AA9`-`$9AB6` (`WalkFrames`, `CrawlFrames`); `$9B98`-`$9BAD` (`RickCrawling`, `RickClimbing`, `RickStep`, `DeathFallOver` and 15 more) |
| Writes | `$9B9A` (`RickStep`); `$9BAF`-`$9BB0` (`RickSprite`) |

### `ClimbLadder` (`$9AB7`)

**Climb: up or down 2 pixels a pass on an even y, then the common tests**

y's lowest bit cleared; up: -2; down alone: +2; neither: 0; RickDy = that step (its sign is all the box test reads). TestBodyBox with C = the step's low byte (+2 or -2), then RickLandOrFall (deadly, platforms, landing at the foot) and the rest of the pass.

Ran 3737 times in 38 builds.

Witness: L1 7474 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-06000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 148 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,405 calls (`stage1/rec/rzx-l4-14000-poke` 347, `stage1/rec/rzx-l5-18000-poke` 238, `stage1/rec/rzx-l4-06000-poke` 168 and 13 more) |
| Called from | `UpdateRick` (tail) |
| Calls | `TestBodyBox`, `RickLandOrFall` (tail) |
| Reads | `$7253` (`Controls`); `$9BAC`-`$9BAE` (`RickX`, `RickY`) |
| Writes | `$9B95`-`$9B96` (`RickDy`) |

### `RickActionDone` (`$9B07`)

**After a fire action: carried by a platform, slide on ice, or only the sprite**

PlatformDx not 0: RickNoWalk (the platform carries him). On level 2's special surface (ice): RickWalk. Else PickRickSprite: no sideways step while an action key is held.

Ran 767 times in 52 builds.

Witness: L1 1535 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 45 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 15 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 106 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 6 calls, 342 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 4 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 165 calls (`stage1/rec/rzx-l4-16000-poke` 24, `stage1/rec/rzx-l2-00000-poke` 21, `stage1/rec/rzx-l2-04000-poke` 16 and 11 more) |
| Called from | `LaunchPadLevel5` (tail), `RickShootUp` (tail), `ShootBullet` (tail), `DropDetonator` (tail) |
| Calls | `RickWalk` (tail), `PickRickSprite` (tail) |
| Reads | `$7EF1` (`Level`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`) |

## weapons

`src/game/weapons.asm`

### `MoveBullet` (`$91B0`)

**Move the bullet 8 pixels a pass; it ends on a solid cell or the view's edge**

IX = BulletRecord (the object step `$86B7`, while BulletRecord +0 is set). Reads the cell flags at (x+4, y+4) through `$8D0C`: bit 1 (solid) ends the bullet (+0 = 0). Else x += BulletDx (+8 or -8): going left, x below 0 ends it; going right, a carry or x >= `$F8` ends it. Hitting enemies and traps is tested elsewhere (`$8BF3`, `$A528`, `$A69F` read BulletRecord).

Ran 755 times in 43 builds (c1 62, each control recording 1).

Witness: L1 1539 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 62 calls, 12,160 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 183 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 146 calls, 28,034 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 19 calls, 3,724 t-states own (0.01 %) |
| Runs (the other recordings) | 588 calls (`stage1/rec/rzx-l1-02000-poke` 54, `stage1/rec/rzx-l2-22000-poke` 41, `stage1/rec/rzx-l2-18000-poke` 32 and 39 more) |
| Called from | `UpdateObjects` |
| Calls | `ProbePoint` |
| Reads | `$9BB5`-`$9BBA` (`BulletX`, `BulletY`, `BulletSprite`, `BulletDx`) |
| Writes | `$9BB4`-`$9BB5` (`BulletRecord`, `BulletX`) |

### `UpdateDetonator` (`$91EB`)

**The detonator's pass: fall, land, slide, then burn the fuse**

IX = DetonatorRecord (the object step `$86C5`, while +0 is set). While DetonatorFuse >= 11: gravity adds 0.5 to DetonatorDy (at most 8), the 24-bit y (DetonatorY, DetonatorYFrac) moves by it, and `$8E1C` tests the detonator's cells and platforms. Deadly: DetonatorTouchDeadly. On a platform (bit 6): y = PlatformTop - 16, a second cell test (C = `$80`) carrying PlatformDx. Landed on a floor (bits 1 or 2) while falling: DetonatorOnFloor. In the air: DetonatorSlide. Always ends in BurnFuse.

Ran 3401 times in 34 builds: 64 passes per detonator (c1 64, each control recording 64, the RZX pieces 64 or 128).

Witness: L1 6994 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 64 calls, 59,390 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 64 calls, 59,650 t-states own (0.06 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 599 calls, 553,165 t-states own (0.03 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 92 calls, 80,457 t-states own (0.06 %) |
| Runs (the other recordings) | 2,774 calls (`stage1/rec/rzx-l2-00000-poke` 128, `stage1/rec/rzx-l1-04000-poke` 128, `stage1/rec/rzx-l1-12000-poke` 128 and 29 more) |
| Called from | `UpdateObjects` |
| Calls | `ProbeGround`, `DetonatorStopFall` (tail), `DetonatorSlide` (tail), `BurnFuse` (tail) |
| Reads | `$8A24` (`LevelHookOn`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$93C0`-`$93D0` (`ExplosionFrames`, `DetonatorDx`, `DetonatorDy`, `DetonatorXFrac` and 2 more); `$9B9C`-`$9BAC` (`RickDying`, `RickOnGround`, `RickIceSlide`, `MudStep` and 11 more); `$9BBE`-`$9BC6` (`DetonatorX`, `DetonatorY`, `DetonatorSprite`, `DetonatorFlags` and 3 more) |
| Writes | `$9161` (`PlatformDx`); `$93CA`-`$93CF` (`DetonatorDx`, `DetonatorDy`, `DetonatorXFrac`, `DetonatorYFrac`); `$945C` (`DeathDrift`); `$9B95`-`$9B9C` (`RickDy`, `RickYFrac`, `RickCrawling`, `RickClimbing` and 3 more); `$9BBD`-`$9BC6` (`DetonatorRecord`, `DetonatorX`, `DetonatorY`, `DetonatorSprite` and 4 more) |

### `DetonatorHitCeiling` (`$9277`)

**a rising detonator meets a solid cell, put it under the cell**

y = (y + 8) AND `$F8`, then on to DetonatorStoreY. Also the branch for a detonator on a platform whose cells are solid (`$925B`). Not executed in any recording: the detonator is never thrown upwards (DropDetonator starts it at +1.0). Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DetonatorOnFloor` (`$9282`)

**Put the falling detonator on the floor's cell edge; a special surface goes to DetonatorBounce**

y = (y - 1) AND `$F8` (low byte), stored in DetonatorY. Ran 2632 times in 32 builds.

Witness: L1 5426 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 470 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 72 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,144 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l1-04000-poke` 108, `stage1/rec/rzx-l1-12000-poke` 108, `stage1/rec/rzx-l2-00000-poke` 108 and 27 more) |

### `DetonatorBounce` (`$9292`)

**a detonator on a special surface, level 3 bounces it, level 5 launches it**

Level 3: when DetonatorDy >= 2.0 it becomes -DetonatorDy + `$5F`/256 (a bounce losing a little), kept unless it is weaker than -3.0 (high byte >= `$FD`), then to DetonatorSlide; else it stops (DetonatorStopFall). Level 5: DetonatorDy = -2175/256 (the launch pad's kick). Other levels: it stops. Not executed in any recording (no detonator fell on a special surface). Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DetonatorStopFall` (`$92C3`)

**The detonator rests: DetonatorDy = 1.0**

Ran 2726 times in 34 builds.

Witness: L1 5614 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 470 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 72 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 94 calls (`stage1/rec/rzx-l2-02000-poke` 54, `stage1/rec/rzx-l5-16000-poke` 40) |
| Called from | `UpdateDetonator` (tail) |
| Calls | `DetonatorSlide` (falls into) |
| Reads | `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$93CA`-`$93CE` (`DetonatorDx`, `DetonatorDy`, `DetonatorXFrac`); `$9BBE`-`$9BC0` (`DetonatorX`, `DetonatorY`) |
| Writes | `$93CA`-`$93CE` (`DetonatorDx`, `DetonatorDy`, `DetonatorXFrac`); `$9BBE` (`DetonatorX`) |

### `DetonatorSlide` (`$92C9`)

**Friction on the sideways speed, then move x and test the cells**

BC = 8, DE = -8: the friction (1/32 pixel a pass every pass); a special surface goes to DetonatorSurfaceFriction first. Ran 2857 times in 34 builds.

Witness: L1 5876 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 496 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 72 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 54 calls (`stage1/rec/rzx-l5-16000-poke` 54) |
| Called from | `UpdateDetonator` (tail), `DetonatorStopFall` (falls into) |
| Reads | `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$93CA`-`$93CE` (`DetonatorDx`, `DetonatorDy`, `DetonatorXFrac`); `$9BBE`-`$9BC0` (`DetonatorX`, `DetonatorY`) |
| Writes | `$93CA`-`$93CE` (`DetonatorDx`, `DetonatorDy`, `DetonatorXFrac`); `$9BBE` (`DetonatorX`) |

### `DetonatorSurfaceFriction` (`$92DA`)

**friction on a special surface, level 1 stops, level 2 (ice) none, level 4 (mud) double**

Level 1: DetonatorStop. Level 2: DetonatorKeepDx (no friction). Level 4: friction 16. Others: 8. Not executed in any recording. Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DetonatorFriction` (`$92F2`)

**Bring DetonatorDx towards 0**

Moving left (negative): add 8; a carry means it reached 0 (DetonatorStopLeft). Ran 2857 times in 34 builds.

Witness: L1 5876 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 496 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 72 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,343 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l1-04000-poke` 108, `stage1/rec/rzx-l1-12000-poke` 108, `stage1/rec/rzx-l2-00000-poke` 108 and 29 more) |

### `DetonatorStopLeft` (`$92FE`)

**a detonator moving left reached speed 0**

JP DetonatorStop (`$C3` `$05` `$93`). Not executed in any recording: a detonator thrown left (-2.0) needs 64 passes to stop and its fuse lasts 53 (`$9B7D` ran 6 times). Kept as bytes for the reason given at BonusRunOut.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DetonatorSlowRight` (`$9301`)

**Moving right or still: subtract 8, at 0 or below stop**

Ran 2533 times in 32 builds; DetonatorStop 1188 times (mostly a detonator dropped standing still, speed 0).

Witness: L1 5228 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 388 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 72 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2,127 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l1-04000-poke` 108, `stage1/rec/rzx-l2-00000-poke` 108, `stage1/rec/rzx-l2-08000-poke` 108 and 27 more) |
| Calls | `ProbeGround`, `BurnFuse` (falls into) |

### `BurnFuse` (`$9351`)

**Count the fuse down: the burning and blast sprites, the sounds, the blast against Rick**

DEC IX+9 (DetonatorFuse): at 0 the detonator ends (+0 = 0). Fuse 10 and up: the sprite is 18 while >= 20, 19 below (it flashes before the blast), effect 2 (`$7A97`) every 4 passes, effect 5 (the bang) at 10. Fuse 1-9: the blast sprite ExplosionFrames[fuse AND `$FE`] (24, 23, 22, 21, 20 as the fuse falls, two passes each). Fuse 4-9: the box test `$8D53` of a box 32 wide (from x-4, at least 0) and 21 high at the detonator's y against Rick: a hit kills him (KillRick, from `$93B4`).

Ran 3397 times in 34 builds; the bang (effect 5) 56 times; KillRick from the blast 8 times (`$93B4` in the caller list of `$93D0`, c1 and the control recordings).

Witness: L1 6986 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

[Animation: `BurnFuse` at work](img/routines/BurnFuse.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 64 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 64 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 596 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 92 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 128 calls (`stage1/rec/rzx-l2-02000-poke` 64, `stage1/rec/rzx-l5-16000-poke` 64) |
| Called from | `UpdateDetonator` (tail), `DetonatorSlowRight` (falls into) |
| Calls | `PlayEffect`, `TouchesRick`, `KillRick` (tail) |
| Reads | `$93C0`-`$93D0` (`ExplosionFrames`, `DetonatorDx`, `DetonatorDy`, `DetonatorXFrac` and 2 more); `$9BBE`-`$9BC6` (`DetonatorX`, `DetonatorY`, `DetonatorSprite`, `DetonatorFlags` and 3 more) |
| Writes | `$9BBD`-`$9BC6` (`DetonatorRecord`, `DetonatorX`, `DetonatorY`, `DetonatorSprite` and 4 more) |

### `FireBullet` (`$9593`)

**Fire the gun: one bullet less (none left: no shot), the shot sound, the bullet from Rick's chest**

Unless `$8066` is set (no write to it in any recording: a cheat flag), the ammunition `$8B3C` is decremented and the HUD redrawn (`$79D1`); with none left, nothing happens. Effect 4 (`$7A97`). BulletRecord +0 = 1, BulletY = RickY + 8, BulletX = RickX; C's two key bits (active low) pick the direction: left (bit 1 low) or, with neither, the facing left: RickFacing = `$80`, BulletDx = -8; right: RickFacing = 0, BulletDx = +8. FireLatch = `$FF` (the fire key must be released before the next shot).

Callers: ShootBullet (`$9B21`) 73, UpdateRide (`$958F`) 15. 88 shots in 43 builds.

Witness: L1 179 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 2 calls, 710 t-states own (0.00 %) |
| Runs (controls-kempston: the Kempston method in play) | 1 call, 348 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 11 calls, 3,863 t-states own (0.00 %) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 1 call, 355 t-states own (0.00 %) |
| Runs (the other recordings) | 76 calls (`stage1/rec/rzx-l2-22000-poke` 6, `stage1/rec/rzx-l1-02000-poke` 4, `stage1/rec/rzx-l2-18000-poke` 4 and 39 more) |
| Called from | `UpdateRide`, `ShootBullet` |
| Calls | `DrawAmmo`, `PlayEffect` |
| Reads | `$8066` (`CheatInfinite`); `$8B3C` (`Ammunition`); `$9BAC`-`$9BB1` (`RickX`, `RickY`, `RickSprite`, `RickFacing`) |
| Writes | `$8B3C` (`Ammunition`); `$9BA8`-`$9BBA` (`FireLatch`, `BonusRunning`, `BonusPrescaler`, `RickRecord` and 1 more) |

### `RickShootUp` (`$9AE8`)

**Fire with up: the shooting pose, and a bullet when the gun is free**

RickStep = `$FF`, ShootPose = `$FF`; unless FireLatch is set or a bullet flies, ShootBullet. Then RickActionDone.

Ran 161 times in 39 builds.

Witness: L1 318 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 25 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 23 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 4 calls, 670 t-states own (0.00 %) |
| Runs (the other recordings) | 27 calls (`stage1/rec/rzx-l2-20000-poke` 4, `stage1/rec/rzx-l1-00000-poke` 4, `stage1/rec/rzx-l1-06000-poke` 4 and 9 more) |
| Called from | `LaunchPadLevel5` (tail) |
| Calls | `RickActionDone` (tail), `ShootBullet` (tail) |
| Reads | `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$9BA8`-`$9BB4` (`FireLatch`, `BonusRunning`, `BonusPrescaler`, `RickRecord` and 1 more) |
| Writes | `$9B9A`-`$9BB0` (`RickStep`, `DeathFallOver`, `RickDying`, `RickOnGround` and 13 more) |

### `ShootBullet` (`$9B21`)

**Call FireBullet with C = the keys, then RickActionDone**

Ran 73 times in 39 builds.

Witness: L1 149 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, fatguy-hits, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l5-02000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 11 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (fatguy-hits: the RZX run's level 5 at 21000 with POKEs: the Fat Guy's touch and a bullet hit) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 13 calls (`stage1/rec/rzx-l2-20000-poke` 2, `stage1/rec/rzx-l3-00000-poke` 2, `docs/rec/box-shot` 1 and 8 more) |
| Called from | `RickShootUp` (tail) |
| Calls | `FireBullet`, `RickActionDone` (tail) |

### `DropDetonator` (`$9B27`)

**Fire with down: drop or throw a detonator when none burns**

DetonatorPose = `$FF`. With a detonator already out, nothing more. Unless `$8066` (the cheat flag) is set, one detonator less (`$8B3D`, none: nothing) and the HUD (`$79DF`). DetonatorX = RickX, DetonatorY = RickY + 5, DetonatorRecord +0 = 1, DetonatorFuse = 64, DetonatorDy = +1.0, DetonatorDx by the sideways keys: none 0, left -2.0, right +2.0.

Ran 233 times in 33 builds; 56 detonators placed (DetonatorPlace), 24 dropped standing, 6 thrown left, 26 right.

Witness: L1 473 (box-shot, controls-cursor, controls-kempston, controls-keyboard, controls-sinclair, rzx-l1-00000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-20000-poke, rzx-l4-00000-poke, rzx-l4-04000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 10 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (controls-kempston: the Kempston method in play) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 43 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 3 calls, 464 t-states own (0.00 %) |
| Runs (the other recordings) | 82 calls (`stage1/rec/rzx-l2-00000-poke` 14, `stage1/rec/rzx-l4-16000-poke` 11, `stage1/rec/rzx-l5-20000-poke` 10 and 9 more) |
| Called from | `LaunchPadLevel5` (tail) |
| Calls | `DrawDetonators`, `RickActionDone` (tail) |
| Reads | `$7253` (`Controls`); `$8066` (`CheatInfinite`); `$8B3D` (`Detonators`); `$915E`-`$9161` (`CollisionFlags`, `PlatformTop`, `PlatformDx`); `$9BAC`-`$9BBD` (`RickX`, `BulletRecord`, `DetonatorRecord`) |
| Writes | `$8B3D` (`Detonators`); `$93CA`-`$93CD` (`DetonatorDx`, `DetonatorDy`); `$9BA2` (`DetonatorPose`); `$9BBD`-`$9BC6` (`DetonatorRecord`, `DetonatorX`, `DetonatorY`, `DetonatorSprite` and 4 more) |

## traps

`src/game/traps.asm`

### `TrapEffect` (`$A2E1`)

**Play effect A when the record at IX is in the shown part (y `$40-$FF`)**

For the effects a path (`$A327`, 115 runs) or an animation script (`$A631`, 1239 runs) asks for: off the shown part nothing is heard. Witness: 1354 runs in 47 builds, c1 53; 258 times silent (`$A2F5`).

Witness: L1 3183 (cheats, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-18000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l4, sec-l2-s7, sec-l3-s7, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 53 calls, 5,428 t-states own (0.00 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 4 calls, 411 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 26 calls, 2,641 t-states own (0.00 %) |
| Runs (the other recordings) | 1,560 calls (`stage1/rec/rzx-l2-22000-poke` 114, `stage1/rec/rzx-l5-04000-poke` 100, `stage2/rec/sec-l3-s7` 96 and 53 more) |
| Called from | `UpdateTrap`, `AnimateTrap` |
| Calls | `PlayEffect` (tail) |
| Reads | `$7B91`-`$7B92` (`Entry+2`); `$7BA9`-`$7BAA` (`Entry+26`); `$7BC1`-`$7BC2` (`CopyMusic+2`); `$7BD9`-`$7BDA` (`CopyMusicLoop+9`); `$7BF1`-`$7BF2` (`BuildMirrorTable+1`); `$7C09`-`$7C0A` (`BitReverseLoop+21`) |

### `UpdateTrap` (`$A2F7`)

**One pass of the trap or pickup at IX: path, animation, deadly touch, triggers**

The pickups (`$21`, `$29`, `$2D`) go to UpdatePickup with their sprite (Sprites 27, 25, 26). A paused trap (+0 bit 1) skips to the trigger test. Otherwise the path is read: effects played, a loop point followed (and there a one-shot trap is retired, a waiting trap switched to its second path by SwitchTrapPath, behaviour `$14` marked to be freed at the next end), a step applied: x += the x step (a trap leaving 0-`$E8` is freed), y += the y step (one leaving the view is freed), the step count moved on. Then AnimateTrap.

A deadly trap (+0 bit 6) with a sprite: with +0 bit 7 (a solid block), a lit detonator (fuse `$9BC6` 10 or more, not yet exploding) whose box (its y, x + 8, 16 x 8) it overlaps is set off at once (`$A41C`, not executed in any recording: effect 5, the fuse set to 9; nothing happens to the trap); then every live enemy it overlaps, not already dying (+`$14` = 0, `$A447`), is killed (KillEnemy: 220 calls from `$A454`, 102 of them in sec-l5-s5), and Rick, unless already dying (`$9B9C`), dies (`$93D0` at `$A475`) when it overlaps him (`$8D53`).

Then the trap's own trigger boxes (TestTriggerBoxes with the map entry): see `$A478`.

Evidence: 148 725 runs in 61 builds (c1 616), all from `$867A`; Rick's overlap test 83 559 runs (the CALL C at `$A475`, which the POKE file's trap immunity patches); behaviour `$0C` removed by its trigger 432 times (`$A4C0`), behaviour `$1C` on release 9 (`$A4A7`).

Witness: L1 347342 (box-shot, cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

[Animation: `UpdateTrap` at work](img/routines/UpdateTrap.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 616 calls, 871,891 t-states own (0.07 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 582 calls, 681,369 t-states own (0.07 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 608,584 t-states own (0.04 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 626 calls, 1,318,668 t-states own (0.07 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 1,140 calls, 1,541,584 t-states own (0.07 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 32,201 calls, 49,370,772 t-states own (2.65 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 824 calls, 595,761 t-states own (0.42 %) |
| Runs (the other recordings) | 139,412 calls (`stage1/rec/rzx-l5-14000-poke` 3,961, `stage1/rec/rzx-l5-04000-poke` 3,537, `stage1/rec/rzx-l1-16000-poke` 3,393 and 72 more) |
| Called from | `UpdateObjects` |
| Calls | `FreeObject` (tail), `RetireObject` (tail), `TrapEffect`, `SwitchTrapPath` (tail), `UpdatePickup` (tail) |
| Reads | `$7B8F`-`$7C20` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2`); `$7C34`-`$7C37` (`FillIm2TableLoop+9`); `$7C4B`-`$7C4E` (`Im2HandlerSource+18`); `$7C62`-`$7C65` (`EntryDebris+6`); `$7C79`-`$7C7C` (`EntryDebris+29`, `ObjectTableBEnd`); `$93D0` (`KillRick`); 5 more ranges |
| Writes | `$7B8F`-`$7C1E` (`Entry`, `Entry48K`, `CopyMusic`, `SetupIm2`); `$8B3C`-`$8B3D` (`Ammunition`, `Detonators`) |

### `TrapMoveRight` (`$A394`)

**TrapMoveRight**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 572 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 563 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 575 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 18,264 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 779 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 104,334 runs of its first instruction, entered by a jump (`stage1/rec/rzx-l5-14000-poke` 3,261, `stage1/rec/rzx-l1-24000-poke` 2,963, `stage1/rec/rzx-l1-16000-poke` 2,694 and 69 more) |
| Calls | `TouchesRick`, `TouchesObject`, `BoxesOverlap`, `KillRick`, `FreeObject` (tail), `IsOffView`, `KillEnemy`, `TrapTriggers` (tail), `AnimateTrap` |
| Reads | `$7C34`-`$7C37` (`FillIm2TableLoop+9`); `$7C4B`-`$7C4E` (`Im2HandlerSource+18`); `$7C65` (`EntryDebris+9`); `$7C7C` (`ObjectTableBEnd`); `$93D0` (`KillRick`); `$9B9C` (`RickDying`) |

### `TrapTriggers` (`$A478`)

**TrapTriggers**

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 596 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 625 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 855 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 26,966 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 819 calls, 193,590 t-states own (0.14 %) |
| Runs (the other recordings) | 2,359 calls (`stage1/rec/rzx-l2-02000-poke` 1,780, `stage2/rec/sec-l3-s8` 467, `stage1/rec/rzx-l1-14000-poke` 66 and 1 more) |
| Called from | `TrapMoveRight` (tail) |
| Calls | `RetireObject` (tail), `SwitchTrapPath` (falls into), `ArmTrapWait` (tail), `TestTriggerBoxes` |
| Reads | `$7B8F`-`$7BE4` (`Entry`, `Entry48K`, `CopyMusic`); `$7BF5` (`BitReverseLoop+1`); `$7C07`-`$7C14` (`BitReverseLoop+19`) |
| Writes | `$7B95` (`Entry+6`) |

### `SwitchTrapPath` (`$A4D5`)

**Swap the trap's path, animation and kind for the second ones**

Swaps +`$0F`/+`$10` with +`$11`/+`$12`, +`$0A`/+`$0B` with +`$13`/+`$14`, +0 with +`$15`, and restarts the frame delay and the step count: a trap that was waiting starts its second movement (a falling block falls, a door opens; the kinds per level to be named with the level data).

Entered from UpdateTrap at a waiting trap's loop point (`$A367`, 135 runs in 22 builds) and from the trigger test (`$A4D1`, 25 runs in 19 builds). Witness: 184 runs in 42 builds.

Witness: L1 370 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-10000-poke, rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-20000-poke, rzx-l5-full, load-l4, sec-l2-s7).

| | |
| --- | --- |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 5 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 3 calls (`stage1/rec/rzx-l2-02000-poke` 3) |
| Called from | `UpdateTrap` (tail), `TrapTriggers` (falls into) |
| Reads | `$7B8F`-`$7BA4` (`Entry`) |
| Writes | `$7B8F`-`$7BA4` (`Entry`) |

### `ArmTrapWait` (`$A51A`)

**A trigger with behaviour bit 3 clear: switch at the path's end**

Sets +6 bit 4 (waiting); with +0 bit 5, bit 3 too: at the loop point `$A350` bit 3 set is cleared (`$A355`) and the trap switches with bit 4 kept, so at the next loop point it switches back and clears bit 4 (`$A35C`): a round trip, path 1 -> path 2 -> path 1. While it waits so, TrapTriggers (`$A485`) skips the box tests. The first switch of a round trip ran 58 times (`$A355`), the set of bit 3 59 (`$A523`). Witness: 361 runs in 22 builds.

Witness: L1 722 (rzx-l1-00000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l4-04000-poke, rzx-l5-00000-poke, rzx-l5-16000-poke, rzx-l5-full).

| | |
| --- | --- |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1 call (`stage1/rec/rzx-l2-02000-poke` 1) |
| Called from | `TrapTriggers` (tail) |
| Reads | `$7B8F`-`$7B95` (`Entry`) |
| Writes | `$7B95` (`Entry+6`) |

### `UpdatePickup` (`$A528`)

**A pickup: a treasure (`$21`), ammunition (`$29`) or detonators (`$2D`)**

HL: its sprite. The record is set to 24 x 21 pixels. While Rick lives (`$9B9C` = 0) and overlaps it (`$8DDF` with Rick's x `$9BAC` + 4, y `$9BAD`, 16 x 21): a treasure gives 500 points (the digits at `$7EFF` through `$7ED3`, effect 7); ammunition sets the bullets `$8B3C` to 6 (`$79D1` redraws them); detonators set `$8B3D` to 6 (`$79DF`); effect 6 for both; the pickup is retired.

Not taken: an ammunition or detonator box hit by the bullet (`$A5E4`) or by the detonator's blast at phase 4-9 (`$A5F7`) bursts (effect 5, ten frames from the table `$93C0` by the burst counter +`$0E`, PickupBurst, then retired). box-shot (POKEs, said so: level 1 starts in section 3 beside the boxes) runs the bullet's branch: PickupShot 1 run, PickupBurst 10 runs; the blast's branch (`$A5F7`) ran in no recording.

Evidence: 20 424 runs in 47 builds (from `$A301` 3685, `$A309` 1820, `$A311` 2825; c1 none); taken: a treasure 28 times (`$A58D`, 18 builds), ammunition 13 (`$A59B` 25 less `$A5B0` 12), detonators 12 (`$A5B0`, 11 builds).

Witness: L1 49532 (box-shot, cheats, life-up, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, load-l2, load-l5, sec-l2-s7, sec-l2-s10, sec-l2-s11, sec-l3-s5, sec-l3-s9, sec-l4-s2, sec-l5-s5).

| | |
| --- | --- |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 95,409 t-states own (0.01 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 285 calls, 106,821 t-states own (0.00 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 5,219 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 8,337 calls (`stage1/rec/rzx-l1-06000-poke` 1,166, `stage2/rec/sec-l4-s2` 858, `stage2/rec/sec-l2-s10` 693 and 18 more) |
| Called from | `UpdateTrap` (tail) |
| Calls | `DrawAmmo`, `DrawDetonators`, `PlayEffect`, `AddScore`, `BulletHits`, `BoxesOverlap`, `RetireObject` (tail) |
| Reads | `$7B8F`-`$7C15` (`Entry`, `Entry48K`, `CopyMusic`); `$93C0`-`$93C9` (`ExplosionFrames`); `$9B9C`-`$9BBD` (`RickDying`, `RickOnGround`, `RickIceSlide`, `MudStep` and 13 more) |
| Writes | `$7B8F`-`$7C0F` (`Entry`, `Entry48K`, `CopyMusic`); `$8B3C`-`$8B3D` (`Ammunition`, `Detonators`); `$A7F0` (`BulletSpent`) |

### `AnimateTrap` (`$A608`)

**Advance the trap's animation script and set its sprite**

+9 counts the passes a frame stays. The script (+`$0A`/+`$0B`) is read: `$FD` n plays effect n (TrapEffect), `$FF` and an address jumps, `$80`+n then a frame shows the frame n passes, a byte below `$80` is a frame. Frame `$7F` hides the trap (+4/+5 = 0); otherwise SpriteFrameMap[frame - 1] gives the sprite number (bit 7: mirrored, +6 bit 7; `$7F`: no sprite) and the sprite address Sprites + n x 128.

A script address below `$100` (`$A61B`: the frame is the low byte itself) is not executed in any recording. Witness: 127 532 runs in 60 builds (all from `$A3E8`); a new frame 76 384 times.

Witness: L1 296189 (cheats, end-congrats, life-up, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s11, sec-l2-s12, sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).

| | |
| --- | --- |
| Runs (c1: power-on, the original tape at ROM speed on the 128K, the menu, level 1 and quit) | 596 calls, 144,107 t-states own (0.01 %) |
| Runs (load-l2: level 2 read from side B at ROM speed and started) | 291 calls, 143,318 t-states own (0.01 %) |
| Runs (load-l3: level 3 read from side B at ROM speed and started) | 279 calls, 139,495 t-states own (0.01 %) |
| Runs (load-l4: level 4 read from side B at ROM speed and started) | 625 calls, 295,921 t-states own (0.02 %) |
| Runs (load-l5: level 5 read from side B at ROM speed and started (POKE `$8065` = `$FF` opens level 5)) | 855 calls, 308,592 t-states own (0.01 %) |
| Runs (rzx-l5-full: the RZX run's level 5 replayed, no POKE: deaths, game over, the menus) | 26,966 calls, 9,636,403 t-states own (0.52 %) |
| Runs (rzx-l5-22000-poke: the RZX run's level 5 at 22000 with POKEs: the Fat Guy) | 819 calls, 342,395 t-states own (0.24 %) |
| Runs (the other recordings) | 119,366 calls (`stage1/rec/rzx-l5-14000-poke` 3,961, `stage1/rec/rzx-l1-12000-poke` 3,129, `stage1/rec/rzx-l1-24000-poke` 3,059 and 69 more) |
| Called from | `TrapMoveRight` |
| Calls | `TrapEffect` |
| Reads | `$7B95`-`$7B9A` (`Entry+6`); `$7BAD`-`$7BB2` (`Entry+30`); `$7BC5`-`$7BCA` (`CopyMusic+6`); `$7BDD`-`$7BE2` (`CopyMusicLoop+13`); `$7BF5`-`$7BFA` (`BitReverseLoop+1`); `$7C0D`-`$7C12` (`BitReverseLoop+25`); 5 more ranges |
| Writes | `$7B93`-`$7B9A` (`Entry+4`); `$7BAB`-`$7BB2` (`Entry+28`); `$7BC3`-`$7BCA` (`CopyMusic+4`); `$7BDB`-`$7BE2` (`CopyMusicLoop+11`); `$7BF3`-`$7BFA` (`BuildMirrorTable+3`, `BitReverseLoop`); `$7C0B`-`$7C12` (`BitReverseLoop+23`) |
