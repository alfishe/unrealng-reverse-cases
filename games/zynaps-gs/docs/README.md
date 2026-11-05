# Zynaps GS: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the game and the machine, the play screen (annotated), the way in (boot, options menu, title pages), the controls in short, the ship, weapons, pods and fuel, scoring, lives and high scores, the twelve levels (a screenshot each), the two sound modes, the end of a round and of the game, what no recording reached |
| [2. Architecture](02-architecture.md) | the machine, the memory map (a figure), the other banks (driver, effects, loading screen), what the code touches in play and in a level load (heatmaps), the CPU budget in play (`r1-play`), the card's memory, from the disk to play |
| [3. Build and load](03-build-and-load.md) | the TRD and its covers, the disk map (2 174 sectors, a figure), the boot read by read (a timeline), the Trush packer (the unpack animated), the patch installer and its 31 places (a figure), what goes to the card and when, the source build and its checks |
| [4. Game loop](04-game-loop.md) | the states (a diagram), the main loop and a frame of play against the beam, the level load (464 frames, a figure), the end of a round and RoundWait, what the sound costs |
| [5. Controls](05-controls.md) | the options menu (the keys animated), SELECT LEVEL and INFINITE LIFE, the title keys and the play controls, the high-score initials, the developer switch `$FFD7` |
| [6. Rendering](06-rendering.md) | the loading screen and its fade, the options menu's printer, the playfield, who writes the screen in play, play in motion (GIFs of levels 1, 4, 11), the graphics in the image |
| [7. Objects](07-objects.md) | the 16 records and their fixed roles, the 44-byte record (a sheet), kinds and handlers, RunObjects (animated), the path bytecode, the collision grid, the wave launcher and the sprite cache, an enemy's explosion and pod, the big enemy, the object events that sound |
| [8. HUD and text](08-hud-and-text.md) | the panel part by part, PanelFrame (animated), the pod icon, the spinners, score and lives, the print codes, the split-bold font and the menu's bold font, the messages and pages, the menu's printer, every string |
| [9. Sound](09-sound.md) | the sound at a glance (a diagram), the GS commands, the media (13 modules and 22 effects, a figure each), the 28 sites and their hooks, a level as the card hears it (timelines, one play, the level change), the driver, the effects-only mode and the SATURNS bug, 128 KB against 512 KB, the silent beeper |
| [10. Gameplay logic](10-gameplay-logic.md) | the player record, weapons, pods and the selector (a bot's course), fuel, the homing missile and the big enemy on level 11, the level order (a figure), the hidden options as code patches |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `python3 tools/fig_routines.py`, the kit's refdocs) |
| [12. Routine reference](12-routine-reference.md) | every routine with its runs, the hook stubs and the driver entries (generated, as 11) |
| [13. Differences from Zynaps (48K)](13-differences-from-zynaps.md) | the verdict, the differences at a glance, the media and the load, memory and banks, the game image against the 48K's (87 bytes in 11 runs, a byte map), the installer's 31 places, the sound hook by hook (beeper effect against GS FX), the music, the options against the 48K's POKE, the level order, the cost and the pauses, bugs added and kept, the screens side by side |

## Texts

Every text of the disk as UTF-8 Markdown:

| File | What |
| --- | --- |
| [texts/disk.md](texts/disk.md) | the label, the catalogue, the BASIC line, the credits never shown, the packer's signature |
| [texts/menu.md](texts/menu.md) | the options menu: the title, items 1-7, the conversion's credits and the two hidden lines |
| [texts/game.md](texts/game.md) | the game's messages (title pages, selections, key definition, banner, high-score entry) and the high-score table; what the GS changed |
| [texts/modules.md](texts/modules.md) | the 13 modules' titles and sample names: the music credits |

## Recordings

All run on unreal-ng's Pentagon 128 with TR-DOS and a General Sound card (512 KB unless named), booted from
`work/media/trd/ZYNAP_GS.TRD`, muted, and kept in `work/` (git-ignored). Frame numbers in the documents are frames
of the named recording, counted from its own start.

| Name | Made by | Frames | What it holds | Used in |
| --- | --- | ---: | --- | --- |
| `x1`, `x2` | stage 1: `tools/gs_session.py steps` with the port history (`work/stage1`, GS 512 KB and 128 KB) | | the boot, both modes, the card's traffic (`digest.txt`), the stub counts of two plays | 03, 09 |
| `x3` | stage 2: card RAM read after loads on 128 KB (`work/stage2/x3`) | | the firmware's page list: 112 KB for data | 09 |
| `r1` | stage 2: a TTD recording from power-on (`work/stage2/r1/session.ttd`), opened as `work/zgsA/r1` | 4 724 | the boot, the menu (key 1), the title, the game start, level 1's load, 1 773 frames of level 1, one life lost at 3 296; the port journal (FDC, card, `$7FFD`) | 01-08 |
| `r1-play`, `r1-level`, `r1-boot` | `kit/re_session.py build` over `r1` | 2951-4724, 2469-2934, 150-812 | the L1 builds of play, the level load and the boot; `r1-play/start.bin` is the memory after the installer | 02, 04, 13 |
| `tour` | `tools/cap_tour.py level` (`work/zgsA/tour/L01`..`L12`) | 1 500 a level | one fresh boot per level: keys 0, 8, the level key, 1, fire; a capture every 2 frames | 01, 05, 06 |
| `menu` | `tools/cap_tour.py menu` (`work/zgsA/menu`) | | the option keys one by one, a capture every 2 frames | 05, 06 |
| `fx2` | `tools/cap_tour.py level --mode fx --mortal --no-select --ttd` (`work/zgsA/fx2`) | 62 931 | effects only, level 1, the ship mortal, INFINITE ROUNDS on: the lives went 2, 1, 0, 255, 254 | 01, 05 |
| `h2` | stage 2: `work/stage2/hooks2.py`, `POKE 65495,1`, the memory profiler on every stub (`work/stage2/h2`) | 60 000 | effects only, levels 1-9 and into 10 in that game's order; the stub counts per level (`summary.txt`) | 01, 07, 09 |
| `mortal`, `weapon02`-`04` | the same script, the ship mortal or one side weapon each (`work/stage2/h2`) | 4 000 a run | ShipHitHook and the ship's explosions (7 deaths); the side weapons' launches | 07, 09 |
| `e1` | `tools/gs_podbot.py --plan 0,1,2,2,3,4` (`work/zgsB/e1`), music mode, INFINITE LIFE | 10 000 | levels 1 and 2, every weapon taken, 592 plays, the level change; ports, stub counts | 07-10, 13 |
| `e2` | `tools/gs_podbot.py --plan 3` (`work/zgsB/e2`), effects only, INFINITE LIFE, SELECT LEVEL 11 | 12 000 | level 11 twice, the big enemy, homing missiles, SATURNS refused; ports, stub counts, card RAM | 07-10, 13 |
| `e3` | `tools/gs_podbot.py --plan 0,1,2,2,3,4` (`work/zgsB/e3`), GS 128 KB, effects only | 8 000 | levels 1 and 2; the 128 KB re-upload at the level change | 07, 09, 10, 13 |
| `f1` | `tools/gs_podbot.py --plan 4 --hold 8`, then `tools/obj_probe.py` (`work/zgsB/f1`) | about 6 100 | the seeker, the hit grid frame by frame, a TTD recording of one pass; the menu images | 07, 08 |
| shots | copies in `work/stage2/shots` (stage 1's screens, `work/stage2/menu`, the 48K case's `work/explore`) | | the frames of `docs/img/compare` | 01, 05, 13 |
| memory images | `work/images/options-menu`, `play-music-gs512`, `play-music-gs128`, `play-fx-gs512`, `play-fx-gs128`; `work/zgsB/menu-cpu.bin`, `e2/cpu-start.bin`, `e3/cpu-start.bin` | | the menu and the game start in each mode and card size | 02, 10, 13 |
| renders | `work/audio/fx/`, `work/zgsB/audio/` (the card alone, to WAV, never played aloud) | | each effect at its note; SATURNS handles 22 and 23 | 09 |

The 48K's own recordings (`c1`, `r1` and its effect captures) are the 48K case's; doc 13 names them "48K".

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| frame | one 50 Hz screen frame of the Pentagon 128: 71 680 T, 20.48 ms, one interrupt. The 48K's is 69 888 T |
| T, T-state | one Z80 clock cycle at 3.5 MHz |
| pass | one run of the game's work started by one play interrupt (PlayInterrupt `$A9ED`): the stars, the panel, the playfield, the objects and one chain step; about two frames. Some comments say "frame" for it |
| phase | PassPhase `$7F65`, 1-4: the part of the four-pass cycle a pass is. Phase 1 scrolls a column, phases 2-4 test the hit grid |
| job | a main-loop task posted as a bit of EventRequests `$81C5` and run by EventDispatch `$AC07` |
| count | one run of the level script, counted by ScriptWaitCount `$81E1`: once in four passes |
| Trush block | a self-unpacking block of "COMPRESSOR BY ALEXANDER TRUSH ODESSA" (`src/disk/trush.asm`); 38 on the disk ([3.4](03-build-and-load.md#34-the-trush-packer)) |
| block 4 | the Trush block unpacked to `$61A8-$FFFF`: the installer, the driver file (`$64B3`), the menu (`$6D60`) and Zynaps, its `$5C00-$73FF` parked at `$C800` |
| blob sector | a sector of the run read by position from track 1 sector 0: TRD sector n + 16 |
| level record | one entry of the level loader's table: a part of a module or of the effects-only set on the disk; 4 FX records and 45 module records |
| installer | Install `$61A8`: writes 31 places in Zynaps (28 operands, 10 with a `CALL` opcode, 3 `NOP` runs) and copies the stubs ([3.5](03-build-and-load.md#35-the-patch-installer)) |
| site | one of the installer's places in the game's code, named `Site...` in `src/disk/install.asm` |
| Mover | `$5BCC`: moves Zynaps's `$5C00-$73FF` into place, clears `$C800-$DFFF`, jumps to MainLoop `$B200` |
| hook stub | installer code at `$FF1C-$FFC3` (and ObjectSoundStub `$B2F0`, SlotGoneHook `$B47F`, WaitStub `$A6AE`) that a site calls: it does the instruction the site lost and calls a driver entry |
| trampolines | `$B446-$B4A7`, where the 48K's title tune was: KeyWait, the GS flags, CallDriver, SlotGoneHook, CallDriverFx |
| CallDriver, CallDriverFx | `$B466`, `$B482`: page bank 1 in, call the driver entry in HL, page bank 0 back; the Fx one only when EffectsOnly `$B486` is 1 |
| GS flags | `$B45F-$B486`: FxVolume, ModuleVolume, Level `$B461`, NextLevel `$B462`, LoadKind `$B463`, the menu's options, SoundOn `$B472`, EffectsOnly `$B486` |
| driver | the GS driver in bank 1 `$C000`: one entry a sound, the gate, PlayFx, the card control, LevelChange ([9.6](09-sound.md#96-the-driver-bank-1-c000)) |
| gate, EFFECTS TIMER | Gate `$C22A` with GateCountdown `$AA29`: the least number of passes between two gated sounds, the menu's EFFECTS TIMER (operand `$C237`) |
| LevelChange | bank 1 `$C385`: the level load. Reset the card, upload the jingle, the level's module and its effects; 450-464 frames in music mode |
| RoundWait | bank 1 `$C34C`, reached through WaitStub `$A6AE`: the wait between rounds; a delay of about 28 frames, or the module's fade on a level done in music mode |
| TitleStub | `$5B00`: shows the loading screen from bank 7 between the title pages |
| music mode, effects-only mode | the menu's key 1 ("music & effects": a module per level and FX 1-10) and key 2 ("only effects": no music, FX 1-21) |
| FX | an effect the card holds, numbered 1-21 as the driver asks for it; the jingle is uploaded on its own |
| handle | the card's number for an uploaded FX: the FX's number, but FX + 1 on 512 KB in effects-only mode (the load-once patch) |
| load-once patch | `$C303` and LoadOncePatch2 `$C863`: on a card of 7 or more pages in effects-only mode the effects are uploaded once, at the game start ([9.7](09-sound.md#97-the-effects-only-mode)) |
| module | a ProTracker `M.K.` file the card plays: one per level and one for the title |
| jingle | the 1.01 s sample played at PREPARE FOR COMBAT and at a level change |
| play | one effect sent to the card: `#2E` (the FX), `#40` (the note), `#80+c` (play in channel c) |
| RAMPG, NUMPG | the GS firmware's page list and page count; page 1 is the half page ([9.8](09-sound.md#98-128-kb-and-512-kb-the-cards-pages)) |
| SATURNS | the menu option (key 5) for FX 21 on path 1's enemies; never heard on 512 KB (the handle bug) |
| INFINITE LIFE, INFINITE ROUNDS, SELECT LEVEL | the menu's code patches: `RET` at `$9B50`, `JR` at `$B218`, `LD B,n` at `$B073` ([10.6](10-gameplay-logic.md#106-the-hidden-options)) |
| Invulnerable | `$FFD7`, the 48K's developer switch tested at `$9B4C` (`POKE 65495,1`) |
| explosion noise | the 48K's three beeper toggles (per playfield row RowBeep `$7F7E`, per object strip, per slot) whose masks open for 16 passes after an explosion; still run in the GS, always silent. Not an engine hum ([9.10](09-sound.md#910-the-beeper)) |
| span chain | a playfield row drawn as a chain of 8-byte nodes at NodePool `$F800` |
| glyph cache | `$C000-$DFFF`: 256 scenery glyphs in four copies shifted 0, 2, 4, 6 pixels; block 4 does not carry `$C800-$DFFF` |
| object record | one of the 16 records of 44 bytes at `$F36C`; the slot number is its index; the roles are fixed ([7.1](07-objects.md#71-sixteen-records-fixed-roles)) |
| kind | the record's `+7`: the index into KindHandlers `$80FA` |
| path | an enemy's movement bytecode, PathCode `$681C`, run by RunPath `$94CB` one command a pass ([7.5](07-objects.md#75-the-path-bytecode)) |
| hit grid | the bitmap at `$FC00` (X) and `$FD00` (Y) of the enemy boxes, marked and tested in the pass ([7.6](07-objects.md#76-the-collision-grid)) |
| sprite cache | the built enemy sprites, records at `$7EE2` / `$7EF2`, built by SpriteBuildJob `$ACA6` |
| big enemy | a kind 12 object, built by BuildBigSprite `$8F0C`, run by BigEnemyHandler `$A03E`; the levels' guardian |
| pod, selector | the weapon pick-up an explosion leaves; the selector is the player record's `+7`, stepped on by PodStep `$A1FD`; fire held 8 passes (FireHeld `$8184`) runs its action |
| side weapon | the player record's `+8`: 0 none, 2 plasma, 3 homing missiles, 4 seeker |
| fuel | Fuel `$80E6`, one step down every 16 frames; at 0 FuelOut `$9C03` |
| lock | the homing sight's capture: LockTarget `$80E0`, LockMask `$80E2` |
| level counter, LevelOrder | the player record's `+6`, 0-11; LevelOrder `$8003` maps it to a level, levels 4-9 drawn anew per game by ShuffleDraw `$AFFE` ([10.5](10-gameplay-logic.md#105-levels-and-their-order)) |
| weapon rating | `$80E7-$80E9`, from the laser, the side weapon and the speed: the enemy fire chance and the waves' colours |
| PanelFrame, burst | PanelFrame `$AB13`, the panel's per-frame attribute work; the burst PanelBurst `$7F77` marks a laser shot |
| split bold | PrintChar's form of a ROM letter: line 1 blank, the left nibble bold |
| print codes | the control bytes of a message: 0-6, `$1B` n (message n inside another), `$FF` the end |
| menu bold font | the options menu's font, made by MakeFont `$6FA2` into bank 7 `$FD00`, printed by PrintText `$6EE9` |
| L1 | the per-recording analysis build (`l1.json`): every routine, call and byte access with counts and T-states |
| TTD | time-travel debugging: seeking a recording to any frame and reading its memory |
| port journal | a recording's history of port writes and reads (`zxbus.1.ports`, `ports.jsonl`): the card's commands and data, the FDC, `$7FFD` |
| memory profiler | unreal-ng's per-address execution counts, used to count the stubs entered |
