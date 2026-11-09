# Exolon: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game, its nine screens on one sheet, the play screen, the controls as a player uses them, the hero and the exoskeleton, the hazards (a sheet: what kills, what destroys, points), 125 screens in five zones, the full map drawn from the image (all 125 checked against the game, compared with Pavero's 2002 map and the Sinclair User maps), 20 key moments (a sheet of named frames), a death and the respawn, score (every row witnessed), the zone end step by step (animated), no difficulty curve, the cheat, what no recording reached |
| [2. Architecture](02-architecture.md) | the machine budget (48K, DI throughout, no frame sync), the memory map at three stages (a figure), the stages from the tape to play, the call graphs in play and outside it, where the CPU time goes, the memory heatmap, the 34 modules, the state by lifetime (load, Start, game, screen, life) and its reset points, the 48K and the 128K (the model test, the five SoundIsAy readers), Start's tables, the self-modifying code, the foreign code (a CPC keyboard reader, a serial downloader) |
| [3. Build and load](03-build-and-load.md) | the tape as a picture, the BASIC byte by byte, the TAP copy and its patch, the Countdown II loader: Decrypt (flowchart, registers step by step, both directions, animated), LoadFile (flowchart, the type-42 check, the ROM's edge loop compared), the countdown (flowchart, nine frames of `c1`), MoveStub and why; the `picy` loading screen (format, flowchart, the first 24 bytes worked, the `$4000` self-locate, animated), the stages as a diagram with `c1`'s frames, the source build |
| [4. Game loop](04-game-loop.md) | the state machine with every trigger, MainLoop's 54 calls in order with their T-states, interrupts (IM 1 never taken, the IM 2 set-up that never runs, every DI / EI window, no frame sync, overruns), the time pads, pass lengths and beam timelines of a typical and the heaviest pass, the pause, the abort, a death, the zone end, the screen change as stages, the menu loop and its stars (the 85.5 s timeout on the 128K, about 92 s on the 48K) |
| [5. Controls](05-controls.md) | the keys, all 20 `IN` instructions and their bits (a figure), the devices it does not read, control types and the control byte (`c1`'s timeline), the readers, the path from the control bytes to the hero (a diagram), fire: a shot on the press, a grenade after 15 passes held (a state diagram, `x2`), ReadKey, define keys (worked on `m1`) and the ZORBA cheat, the menu, the name entry (worked on `d1`), the pause, the abort and the waits |
| [6. Rendering](06-rendering.md) | the screen and its addressing, the three cell maps, the string interpreter, one element decoded and all 62 (a sheet), the screen builder (animated) and the screen change, the stars (animated), DrawSprite, DrawSmallSprite and DrawBigSprite (animated, the shift worked), the mask worked on `x2` 388, ColourCells, the save buffers, the 25 player frames and the walk cycle, code against the screen, the mirror, a beam timeline, the cost table |
| [7. Objects](07-objects.md) | the cell maps and the build (a diagram), the 16 object kinds (a figure), each kind as a state machine with its asm and a worked example: turrets, turret shells and gun shots, the exoskeleton booth, the force field, the flashing pad, the zone-end marker, the traps, the aliens (AliensStep animated), balls, mines, pods, teleports, the homing missile, blasts, debris, puffs and sparkles; destructible scenery and the grenade blast, every collision test with its box and order, Random `$AD36` |
| [8. HUD and text](08-hud-and-text.md) | the HUD (a writers map), the number printers, the string printer and its codes, PrintChar and the five plot modes (the A of AMMO worked), the font, the logo and frame pieces decoded, the 22 glyph-set bases, the eight text screens, the menu stars (animated), GAME OVER and its 11.4 s timeout, the name entry, the Hall of Fame roll (animated) and its hidden row, the zone-end panel |
| [9. Sound](09-sound.md) | one image with two sound systems, the dispatcher and its cost, the two-voice beeper engine (96 T a step), the beeper tunes and effects, BeeperSweep, the speaker in play (the debris crackle), the AY title tune's format decoded byte by byte, its player (TuneTick, TuneChannelStep, envelopes), the 16-slot effect engine (channels, mixer, priority, the freed-slot quirk), all 17 AY effects, the AY registers over time (figures), 29 MP3 renders |
| [10. Gameplay logic](10-gameplay-logic.md) | the rules in one table, 125 screens in five zones, the zone end at its marker (`w/024` frame by frame), the bonus screen, the arcs, deaths and the restart point (`x1`), scoring (every awarding site), grenades and the hold repeat, the idle missile, the Hall of Fame insert, the hero's states (MovePlayer, the cell tests, the frames, the exoskeleton), the player's shots, 18 bugs and oddities, what is known only from the code |
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
| `c128` | the same capture as `c1` on the 128K model | the AY path; the game pages nothing | 02, 04, 05, 08, 09, 10 |
| `x1` | `tests/inputs/x1-right.txt` from the game's entry, no POKE | menu 5 then 1; nine deaths on screen 0, GAME OVER | 01, 05, 07, 08, 10 |
| `m1` | `tests/inputs/m1-menus.txt`, no POKE | define keys, the control types, nine deaths, GAME OVER, the menu again | 05, 07, 08 |
| `x2` | clone: `tests/inputs/x2-imm-right.txt` on `entry-imm.z80` (the ZXDB POKEs) | screens 0-5, 14 grenades, aliens on screen 5, the idle missiles; 23 110 frames | 01, 07, 08, 10 |
| `h1` | clone: `tests/inputs/h1-hall-of-fame.txt` on `entry-score.z80` (the score 009000) | GAME OVER, the Hall of Fame insert, the name entry, the table shown | 01, 04, 05, 07, 08, 10 |
| `w/NNN` | clones: `entry-imm.z80` with the screen number set to NNN (`tools/warp_snapshot.py`), 97 runs | screen NNN at frame 250; `w/024` and `w/124` the zone end, `w/124` CONGRATULATIONS and the bonus screen | 01, 02, 04, 07, 08, 10 |
| `w030` | clone: `entry-imm.z80` warped to screen 30 (`work/w030`) | screens 30-32: a mine fired, 8 grenades | 07, 10 |
| `t1` | clone, the annotation agent C's (`work/ann/exC/t1`) | screen 14: the traps, the list records | 01, 04, 05, 07 |
| `exA1` | clone, the annotation agent A's (`work/ann/exA/exa1`) | the ZORBA cheat turned on: ten deaths, no life lost; the pause | 05, 10 |
| `d1` | clone, the annotation agent D's (`work/ann/exD/d1`, from `entry-score.z80`) | the pause, the name entry's delete | 04, 05 |
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
| bonus screen | BonusScreen `$A8DB`: a pointer (character `$2A`, an arrow in the game's font) steps over eight lines until fire; the odd lines pay 1000-7000 |
| bonus tick | 25 points pending in BonusTicks `$9ED6`; PayBonusTick pays one a pass |
| OpenCells | `$5B00`, a 32 x 24 map laid out like the attributes: 0 where the screen builder printed scenery, so that the sprite drawers mask the sprite out there |
| AttrCopy | `$5E00`, a copy of the attributes after the build; a sprite colours only cells that are 0 here (black on black) |
| CellTypes | `$6100`, the kind of each cell: 0 empty, 1 scenery, 2-17 an object kind while a screen is built (kinds 3, the turret, and 13, the missile launcher, stay after it); the movement and shot tests read it (BlockMapCell `$80C1`) |
| object kind | the type 2-17 a cell gets in CellTypes while a screen is built; each kind has its list and its routine ([7.1](07-objects.md#71-three-cell-maps-and-the-build)) |
| DeathTimer | `$9CE2`: 46 passes of the death leap; a life is lost at 0 |
| ImmunityCount | `$768D`: 66 at a death, so 20 passes of safety after the restart |
| IdleTime | `$AC7B`: passes on the current screen; at 700 the idle missile comes |
| ZORBA | the cheat word typed in define keys; it toggles the lives' `DEC A` at `$9D1D` to `NOP` |
| step (beeper) | one round of PlayTwoTones `$803D`: 96 T; a voice flips the speaker every (256 - reload) steps |
| tick (AY) | one call of TuneTick `$B767` (every 4th DrawSparkle; about 1.54 a frame on the menu) or of SoundEffectsTick (three a main loop pass) |
| render (sound) | a capture of the emulator's audio output to a WAV file through WebAPI, with the instance muted; the documents show it as figures |
| clone run | a recording made from a patched snapshot (a POKE or a warp): `h1`, `x2`, `w/NNN`, `t1`, `exA1`, `d1`; exploration only, confirmed by the code |
| Countdown II | the Hewson loader at `$FC00`: an XOR-chain encrypted copy of LD-BYTES with a counter at the bottom right |
| unit | 2 pixels of X: the hero's and the objects' X is kept in units |
| menu pass | one run of MenuLoop: a MenuSparkles step and a key read, about 128 000 T; 2500 of them before the Hall of Fame ([4.8](04-game-loop.md)) |
| screen change | NextScreen `$8253`, ScreenChangeCheck `$8485` and BuildScreen `$8494` in one pass, about 12 frames ([4.7](04-game-loop.md)) |
| reset point | Start, StartGame, BuildScreen and DeathOver, each resetting its own variables ([2.8](02-architecture.md)) |
| save buffer | the fixed slot where DrawBigSprite or DrawSprite keeps a sprite's last image for the next erase ([6](06-rendering.md)) |
| FireHeld | `$83DC`: passes fire has been held; 1 on the press, stops at 255, 0 on release; ThrowGrenade throws at 15 |
| AbortIfDying | `$9D78`: returns to the main loop, dropping its caller's return, while DeathTimer is not 0 |
| key moment | one of the 20 screens of doc 01's key moments, each a named recording and frame |
| sparkle slot | one of the menu's 12 star slots at `$6F5E`: x, y, frames left |
| hidden staging row | row 23 of the Hall of Fame roll: its attributes are 0, so a new entry is printed out of sight and scrolls into view |
| slot (effects) | one of the 16 records of SfxSlots `$C5EB`; the first three active slots get AY channels A, B and C |
| order list | a tune channel's top stream: `$75 lo hi` pattern calls ending in `$FF` |
| pattern | a tune sub-stream of notes ending with `$76` |
| envelope (tune) | a table of segments (steps, step, ticks a step) the player applies to a note's volume or pitch; set by a `$8A` sub-stream |
| debris crackle | the 48K speaker clicks MoveDebris writes, bit 1 of each moved piece's X |
