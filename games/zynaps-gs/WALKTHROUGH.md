# Zynaps GS: walkthrough

How the reverse was done, step by step, and which command or recording answered each question. Terms:
[docs/README.md](docs/README.md).

The case was done in two stages by agents:

- **Stage 1** (2026-11-05): the disk mapped, the 38 Trush blocks unpacked, the media cut and checked against the
  card's traffic, the sound path traced live on GS 512 KB and 128 KB. Drafts of docs 2, 3 and 9.
- **Stage 2** (2026-11-05): the full own source of the disk, bit for bit, the resources and media in editable form,
  every sound site named against the game event it marks, the open questions of stage 1, the screenshots against
  the 48K, the texts, the documents. The owner's rule for a derived case: the game is reversed on its own (its own
  `src/game/game.ann`, every routine named and described), never "the 48K's source plus patches".

The logs are in `work/` (local, not in the repository): `work/stage1/NOTES.md` and the stage 2 scripts and
recordings under `work/stage2/`. The instances were unreal-qt from an unreal-ng worktree (`scratch/wt-zgs-stage1`,
a binary built at `e3d341d38`), driven by `tools/gs_session.py` over the WebAPI, on port bases 14340-14440, muted at
launch, stopped after use; audio only to files.

## 1. Stage 1: the medium

The steps and what each proved: `work/stage1/NOTES.md`. In short:

| Command | Proved |
| --- | --- |
| `tools/disk_files.py`, `tools/basic_list.py` | 9 catalogue files cutting one run of sectors; the BASIC boots the code in its tail |
| `tools/trush.py --scan` | 38 Trush blocks, each unpacks to the length its depacker states |
| disassembly of the boot, the loader, block 4 | the boot order, the installer, its patched places (25 counted then; 31 in the documents stage: 28 operands and 3 `NOP` runs), the level table (4 FX records, 45 module records) |
| `gs_session.py steps` with `hist:zxbus.1.ports` and `tools/gs_digest.py` | what goes to the card and when; no byte written before the card took the one before |
| the memory profiler (`kinds=x`) on the stubs, a port watch on `$FE` | which stubs ran in two plays; the beeper silent |
| `tools/gs_media.py --check` | the 22 FX and 13 modules cut from the disk equal the live streams |
| a GS 128 KB instance (`--card-ram 128k`) and `gsram:` | FX 8 split, its tail and FX 9-10 at card RAM `$00000`: read in stage 1 as a wrap past the card's end |

## 2. Stage 2: the sources

| Step | Result |
| --- | --- |
| the game image from block 4 (`tools/game_image.py`) and kit/mkgame.py over `src/game/game.ann` with the 48K recordings `work/z48c2`, `work/z48r1` and the GS run `work/stage2/r1` | 50 modules, 546 entries, `src/game/*.asm`; every routine named and described for this image; the GS changes annotated at their addresses (`GS:` notes) |
| `tools/part_mkasm.py` over `src/disk/*.ann` (boot, screen block, loader, menu, driver) | the disk parts as annotated sources, each assembled and compared with the original's bytes before it is installed |
| `src/disk/install.asm`, `src/disk/trush.asm`, `tools/trush.py` (the packer) | the installer and the Trush block format; the packing rule recovered (`tools/mkdisk.py`: a record is packed when its in-place depack is safe and it saves a sector) |
| `src/res` and `tools/res_*.py`, `tools/disk_media.py` | the graphics, levels, fonts, texts, modules, FX and the loading screen as editable files, each with a README; `res_formats.py check` and `disk_media.py check` round-trip them |
| `tools/build.sh` (with a lock), `tools/regen.sh` | the TRD rebuilt byte-identical; regen writes every `.asm` again from its annotations and builds |

## 3. Stage 2: the open questions

| Question | How | Answer |
| --- | --- | --- |
| the game events of the 13 new hooks and the 12 never-fired places | `work/stage2/hooks2.py`: a fresh boot, POKE 65495,1 (the 48K's invulnerability switch), the level played to its end through ten levels, the memory profiler on every stub (`h2/summary.txt`); separate runs per side weapon and a mortal run | every site seen and named after its event ([9.4](docs/09-sound.md#94-where-the-game-makes-a-sound), [7](docs/07-objects.md)) |
| the 128 KB "overrun" | the firmware's RAM test and page list read in the GS ROM sources, card RAM read after loads (`work/stage2/x3`) | not an overrun: the firmware's page list on 128 KB is `[2, 3, 4, 1]` with page 1 only half usable (its upper half is the fixed `$4000` window), so `$00000-$03FFF` is the firmware's last half page. 112 KB for data; every level fits ([9.8](docs/09-sound.md#98-128-kb-and-512-kb-the-cards-pages)) |
| the hidden menu items | the menu's code (`src/disk/menu.ann`), then key 0 and 8, key 0 and T on a fresh boot (`work/stage2/menu`) | key 0 reveals INFINITE LIFE and SELECT LEVEL; key T started level 5 (`$B073` = `06 05`) ([5](docs/05-controls.md), [10.6](docs/10-gameplay-logic.md#106-the-hidden-options)) |
| the start-up and menu against the 48K | `tools/fig_compare.py` over real frames (`work/stage2/shots`) | `docs/img/compare/` |

## 4. Tool gaps

No unreal-ng change was made in this case. The gaps met (with their evidence in `work/stage1/NOTES.md`): no unplug
of a GS card (`slots_unplug` unknown), the port history stream buffered until it is switched off, the frame counter
reset by a snapshot load, the GS card's SZX approximate, no breakpoint counts without a stop (the memory profiler
was used), the signature base without Trush, MOD or GS entries. A snapshot loaded without its disk hangs in TR-DOS
(`$3FE7`): every stage 2 run boots the TRD fresh.

## 5. What stays open

Stage 2's open list was closed by the documents stage (6): FX 12 played 25 times on level 11 (`e2`); the homing
missile's launch at `$9CFA` ran 6 times (`e2`); the port journals of `e1`-`e3` count the FX the card was sent, not
only the stubs entered; the memory map, the disk map and the unpack animation are drawn (docs 2, 3). Still open,
read in the code only:

- two players, the high-score entry, the key definition and the pause (no stop is sent to the card: the module plays
  on, 13.9);
- a normal game through all twelve levels (`h2`, the furthest, ended in level 10; levels 3-12 in music mode were not
  streamed live);
- the music-mode branch of BigEnemyDestroyedSound (FX 8 alone), SATURNS on a 128 KB card;
- a missed pod halving the fuel, a ship lost with a side weapon armed.

## 6. The documents stage

Docs 01-12 were written by two agents, then merged and checked by an editor pass, which also wrote doc 13:

| Agent | Docs | Own instances | Notes |
| --- | --- | --- | --- |
| zgsA | 01 game design, 02 architecture, 03 build and load, 04 game loop, 05 controls, 06 rendering | 16600-16699 | `work/docs/zgsA-NOTES.md`, `zgsA-index.md`, `zgsA-diff-notes.md` |
| zgsB | 07 objects, 08 HUD and text, 09 sound, 10 gameplay logic, 11 and 12 (generated, `tools/fig_routines.py`) | 16850-16880 | `work/docs/zgsB-NOTES.md`, `zgsB-index.md`, `zgsB-diff-notes.md` |
| editor | the index, the terms, the contradictions, the comments, 13 differences from Zynaps (48K) | none | this section |

New recordings and experiments (all listed in [docs/README.md](docs/README.md#recordings)):

- `r1` opened read-only as `work/zgsA/r1`, its port journal exported, its L1 builds `r1-play`, `r1-level`, `r1-boot`;
- `tour` (one boot per level through SELECT LEVEL), `menu` (the option keys), `fx2` (a TTD recording of effects-only
  play with the ship mortal): `tools/cap_tour.py`;
- `e1`, `e2`, `e3` (zgsB, `tools/gs_podbot.py`): a bot that takes every weapon, in music mode on 512 KB, effects only
  on 512 KB with SELECT LEVEL 11, effects only on 128 KB; the GS ports recorded and the stubs counted;
- `f1` (zgsB, `tools/obj_probe.py`): the seeker, the hit grid frame by frame, a TTD recording of one pass;
- the card alone with the stubs poked to `RET`: SATURNS's handles 22 and 23 rendered (RMS 0.0206 against 0).

What the documents stage found against the stage 2 comments. Each was checked against the 48K case's fix of the same
comment (its commit `b92fa86`, WALKTHROUGH 9 there) or against a recording here, then fixed in the descriptions of
`src/game/game.ann` and the comments of `src/disk/install.asm`, never the bytes; `sh tools/regen.sh`: "assembled:
identical", "build: identical":

- a pass is one play interrupt and about two frames: comments that said "once a frame" now say "once a pass";
  `$AA74` covers phases 2-4; ScriptWaitCount counts script counts, once in four passes;
- the three beeper toggles are the explosion noise, not "the engine hum" or "the beeper crackle";
- PanelBurst `$7F77` marks a laser shot (FireLaser `$9C80`, `e1`), not a lost life; RequestEffect's call at `$9C75`
  is the laser;
- PodIconJob writes rows 20-21, not 16-17;
- WeaponRatingValue `$80E8` is the enemy fire chance, the kind's `+$18` the fire rate, `$80E9` the wave colours: not
  "how fast the next waves fly" or "the speed level";
- the installer writes 31 places (28 operands, 10 of them with a `CALL` opcode, 3 `NOP` runs), not 25
  (`src/disk/install.asm`, `README.md`, stage 1's table above);
- `tools/fig_routines.py`: WaitStub's only caller left is EndOfPlay (the other five callers of `$A6AE` are `HALT`
  loops); 11 and 12 regenerated.

Contradictions between the two halves, settled to the evidence:

- zgsA wrote that the installer's 17 other places were never reached; zgsB's `h2` and `e1`-`e3` ran every one of the
  22 stubs (docs 1.10, 3.5, 3.8);
- zgsA's "sending an effect costs almost nothing" rested on `r1-play`'s 6 effects; `e1`'s 592 plays cost 2.09 % of
  the CPU in music mode (docs 2.5, 4.5);
- zgsB wrote that no recording played FX 8 for the ship; `r1`, music mode, sent it at frame 3296 (`08 #2E`,
  `2D #40`, `08 #81` in `r1-gscmd.json`; docs 7, 9.4);
- the Invulnerable switch "did not work" in `fx2`: `h2` played ten levels with it; `$FFD7` lies in the `$C000` window,
  where bank 1 is paged while the driver runs (316 of 1600 frame ends in `f1`), so `fx2`'s write most likely met
  bank 1 (doc 5.6);
- a level change in effects-only mode uploads nothing on 512 KB but the jingle and 21 FX on 128 KB (doc 1.8).

Doc 13 compares the GS with the 48K case (`../zynaps`, read only). `tools/diff_zy.py` (from nether-earth-gs's
`diff_ne.py`) compares the two images byte by byte after the 48K's Start; `tools/fig_diff_memmap.py` and
`tools/fig_diff_sound.py` draw `docs/img/diff/`; `tools/fig_compare.py` gained `play-level1.png`. No emulator was
started for it. The task that asked for doc 13 took the level shuffle for the conversion's; the 48K's code and its
`r1` show the same shuffle (13.7).

Checks: `python3 ../../kit/check_docs.py --case games/zynaps-gs`: docs: ok; `sh tools/build.sh`: identical.
