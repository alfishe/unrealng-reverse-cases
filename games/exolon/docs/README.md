# Exolon: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game, its nine screens on one sheet (the menu, define keys, play, GAME OVER, the name entry, the Hall of Fame, the zone end, CONGRATULATIONS, the bonus screen), the play screen, the player and the exoskeleton, what kills him, 125 screens in five zones (a sheet of 15), score, lives and bonuses, machines, the cheat and the difficulty, what no recording reached |
| [2. Architecture](02-architecture.md) | the machine budget (48K, DI throughout, no frame sync), the memory map at three stages (a figure) and the tables, the stages from the tape to play, the main loop's call graph, where the CPU time goes (`c1` play and menu), the memory heatmap of `c1` play, the 34 modules |
| [3. Build and load](03-build-and-load.md) | the tape as a picture, the BASIC, the Countdown II loader and its decryption (animated), the `picy` loading screen (the unpack animated), the stages in `c1`, the source build (a diagram) |
| [4. Game loop](04-game-loop.md) | the state machine (a diagram), MainLoop's 54 calls, one pass against the frame (about two frames, not frame-locked), the time pads, pass lengths over `c1`, the pause, the abort, a death and the zone end (the Delay of 0.4 s) |
| [5. Controls](05-controls.md) | the keys (a figure), control types and the control byte, the Kempston, Interface 2 and keyboard readers, define keys (a worked example) and the ZORBA cheat, the other keys, what the recordings pressed |
| [6. Rendering](06-rendering.md) | the screen, the three cell maps (a figure), the string interpreter (a worked example), the screen builder (animated, screen 0's layout), the sprites and DrawBigSprite (animated, the shift example), code against the screen (a writers map), the mirror (a worked example), the drawing against the beam |
| [7. Objects](07-objects.md) | the cell maps and the build, the 16 object kinds on their elements (a figure), a built screen as list records (screen 14 in `t1`), what each kind does, turret shells and gun shots, the traps (the counter's four bands), the six alien paths (model against `x2`; AliensStep animated), balls, mines, pods, teleports, missiles, blasts, debris and puffs, the two sprite sets |
| [8. HUD and text](08-hud-and-text.md) | the HUD (a writers map of `x1`), the string printer `$AF2B` and its codes (two strings through the model), five plot modes, the font, the logo and the tile area, the score as a 6-digit string, the eight text screens |
| [9. Sound](09-sound.md) | one image with two sound systems (the beeper on 48K, the AY on 128K), the two-voice beeper engine (96 T a step), the two beeper tunes (model against the render; PlayTune animated), the beeper effects, the AY title tune (794 notes, all found in the render), the 17 AY effects (six without a caller); all rendered to WAV files and shown as figures |
| [10. Gameplay logic](10-gameplay-logic.md) | the rules in one table, 125 screens in five zones (a figure), the zone's end (lives x 1000, bravery 10 000), the bonus screen, the jump, grenade and death-leap arcs (tables against recordings), deaths and lives (`x1`'s nine deaths; PlayerDeath animated), scoring (AddScore with a worked example), the course of `x2`, grenades, the idle missile, the Hall of Fame insert (`h1`), the ZORBA cheat |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |

## Recordings

All are kept in `work/` (git-ignored); WALKTHROUGH 1 and 6.0 say how each was made. Frame numbers in the
documents are frames of the named recording, counted from its own start. A clone is a run from a patched snapshot
(a POKE or a warp): it shows behaviour, and the code reading must confirm it.

| Name | Made by | What it holds | Used in |
| --- | --- | --- | --- |
| `c1` | `re_session.py capture --record-load` on 48K: power-on, `Exolon.tzx` (the ROM blocks fast, the Hewson blocks at signal speed), then 16 000 frames of seeded random play | the load and its stages (the game entered at 12 376), the menu (12 376-16 125), play on screen 0 (16 125-18 275), GAME OVER | 01-07, 09, 10 |
| `c1-play`, `c1-menu` | `re_session.py build` over `c1`, frames 16 125-18 275 and 12 378-16 125 | L1 of play and of the menu: the budget, the heatmap, the memory map's play row | 02 |
| `c128` | the same capture as `c1` on the 128K model | the AY path; the game pages nothing | 02, 04, 05, 09, 10 |
| `x1` | `tests/inputs/x1-right.txt` from the game's entry, no POKE | menu 5 then 1; nine deaths on screen 0, GAME OVER | 01, 05, 07, 08, 10 |
| `m1` | `tests/inputs/m1-menus.txt`, no POKE | define keys, the control types, nine deaths, GAME OVER, the menu again | 05, 07, 08 |
| `x2` | clone: `tests/inputs/x2-imm-right.txt` on `entry-imm.z80` (the ZXDB POKEs) | screens 0-5, 14 grenades, aliens on screen 5, the idle missiles; 23 110 frames | 01, 07, 08, 10 |
| `h1` | clone: `tests/inputs/h1-hall-of-fame.txt` on `entry-score.z80` (the score 009000) | GAME OVER, the Hall of Fame insert, the name entry, the table shown | 01, 04, 05, 07, 08, 10 |
| `w/NNN` | clones: `entry-imm.z80` with the screen number set to NNN (`tools/warp_snapshot.py`), 97 runs | screen NNN at frame 250; `w/024` and `w/124` the zone end, `w/124` CONGRATULATIONS and the bonus screen | 01, 02, 04, 07, 08, 10 |
| `t1` | clone, the annotation agent C's (`work/ann/exC/t1`) | screen 14: the traps, the list records | 01, 04, 05, 07 |
| `exA1` | clone, the annotation agent A's (`work/ann/exA`) | the ZORBA cheat turned on: ten deaths, no life lost | 10 |
| `i48`, `r128` | live 48K and 128K instances, the audio output captured to WAV through WebAPI (muted) | the beeper tunes and effects; the AY tune and the 17 AY effects | 09 |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| frame | one 50 Hz screen frame of the 48K: 69 888 T. The recordings count frames from their own start |
| T, T-state | one Z80 clock cycle at 3.5 MHz |
| pass | one run of MainLoop `$75BE`: 54 calls, about two frames; with interrupts off it is not locked to the frame, so its length changes with the work |
| time pad | a call that only burns time so that a pass costs about the same whatever is on screen: PadXorSprites `$9E85` (up to 16 blank small-sprite draws) and PadSlotSprites `$9E99` (always 6 blank 16x16 draws) |
| Delay | `$B0B7`, an `LDIR` of BC bytes from `$0000` to `$0000`; with BC = 65 536 it takes 1 376 256 T, about 20 frames (0.4 s). The panels and GAME OVER wait on it |
| screen | one of the 125 rooms, 0-124; the HUD's ZONES counter shows the screen number |
| zone | 25 screens; a zone ends at the zone-end marker on screen 24, 49, 74, 99 or 124: lives x 1000, a bravery bonus of 10 000 without the exoskeleton, the bonus screen, the refill |
| bonus screen | BonusScreen `$A8DB`: a `*` steps over eight lines until fire; the odd lines pay 1000-7000 |
| bonus tick | 25 points pending in BonusTicks `$9ED6`; PayBonusTick pays one a pass |
| OpenCells | `$5B00`, a 32 x 24 map laid out like the attributes: 0 where the screen builder printed scenery, so that the sprite drawers mask the sprite out there |
| AttrCopy | `$5E00`, a copy of the attributes after the build; a sprite colours only cells that are 0 here (black on black) |
| CellTypes | `$6100`, the kind of each cell: 0 empty, 1 scenery, 2-17 an object kind while a screen is built; the movement and shot tests read it (BlockMapCell `$80C1`) |
| object kind | the type 2-17 a cell gets in CellTypes while a screen is built; each kind has its list and its routine ([7.1](07-objects.md#71-three-cell-maps-and-the-build)) |
| DeathTimer | `$9CE2`: 46 passes of the death leap; a life is lost at 0 |
| ImmunityCount | `$768D`: 66 at a death, so 20 passes of safety after the restart |
| IdleTime | `$AC7B`: passes on the current screen; at 700 the idle missile comes |
| ZORBA | the cheat word typed in define keys; it toggles the lives' `DEC A` at `$9D1D` to `NOP` |
| step (beeper) | one round of PlayTwoTones `$803D`: 96 T; a voice flips the speaker every (256 - reload) steps |
| tick (AY) | one call of TuneTick `$B767`, every 4th DrawSparkle; about 1.54 a frame on the menu |
| render (sound) | a capture of the emulator's audio output to a WAV file through WebAPI, with the instance muted; the documents show it as figures |
| clone run | a recording made from a patched snapshot (a POKE or a warp): `h1`, `x2`, `w/NNN`, `t1`, `exA1`; exploration only, confirmed by the code |
| Countdown II | the Hewson loader at `$FC00`: an XOR-chain encrypted copy of LD-BYTES with a counter at the bottom right |
