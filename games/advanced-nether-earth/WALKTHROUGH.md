# Advanced Nether Earth: walkthrough

How the reverse was done, step by step, and which tool or recording answered each question. Terms:
[docs/README.md](docs/README.md). Standard: [GUIDE.md](../../GUIDE.md). Recipes: `../../recipes/`.

The case was done on 2026-11-04 in three stages, all of it by agents under one lead:

- **Stage 1** (one agent, about 45 minutes): the media, the load, the images, what the game shares with
  [Nether Earth](../nether-earth/WALKTHROUGH.md) (NE).
- **Stage 2** (one agent, about 70 minutes): the boot followed statically, the SCL built byte for byte, with the
  game as NE's source plus a patch file.
- **Stage 3** (13 agents, from 19:53): the owner rejected stage 2's source as "some patcher" and the documents as
  thin. Every part of the disk was reversed on its own, as annotated source and editable resources, bit for bit;
  then four doc agents rewrote the documents and the music was rendered to audio.

NE served as a reference twice: its names and descriptions seeded the game's `game.ann` (section 6.2), and its
documents set the depth and the figure standard (`../nether-earth/work/ann/BRIEF-FIG.md`). Each agent's command
log is in `work/` (local): `work/stage1/NOTES.md`, `work/stage2/NOTES.md`, `work/stage3/NOTES.md`, the coordination
log `work/stage3/SOURCE-STATE.md`, `work/docs/doc{S,L,P}-NOTES.md`.

Every recording below is named beside every frame number. In the stage 3 recordings from power-on,
**recording frame = input-script frame + 1602** (section 1.2).

## 0. The media

Two releases were found:

- **The owner's `anefc.zip`**: `ANE_FC.TRD`, label `ane_fc`, two files, `boot.B` and `ane_fc.B` (a BASIC of 174
  bytes, 56 sectors). zxart.ee lists it as "Advanced Nether Earth Final Cut (1998)(Eternity Industry)".
- **The TOSEC SCL** (TOSEC 2023-09, `Games.zip`, member
  `Games/Advanced Nether Earth/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl`): four files.

| File | Catalogue | Sectors | What |
| --- | --- | ---: | --- |
| `A_NETHER.B` | BASIC, 2795 bytes | 255 | the boot BASIC inside UltraXOR, then the loader and the boot's blocks |
| `a_nether.E` | 0 bytes | 182 | more blocks: bank 1, the game, Final Cut and the disk module, bank 7 |
| `nether.N` | CODE 55595 (`$D92B`), 9941 bytes | 39 | a saved game the authors left on the disk |
| `NETHER+.W` | CODE 38912, 9143 bytes | 36 | the authors' text, CP866 |

**Which file is the game.** Stage 1 booted both (section 1). The TRD holds no game: `tools/ne_match.py` on its
unpacked image finds 493 of NE's 563 entries absent. It is the win sequence alone: a new BASIC signed
"KALANTAJ KONSTANTIN. UKRAINE. KRIVOY ROG. 10.05.2017", one Hrust 1 block unpacked to `$6060-$F76C`, the Final Cut
sequence ([3.8](docs/03-build-and-load.md)). The SCL is the game. Both are in `orig/` with their hashes in the
[README](README.md).

**The two Final Cuts are one.** A live SCL instance with `EnemyBuildings` (`$FD42`) poked to 0 (an experiment, not a
recording, `tools/drive.py`, stage 1) wins at once and plays its Final Cut. Its memory equals the TRD's unpacked image
`fc-end-cpu.bin`: `$8000-$BFFF` and `$C000-$F76C` in full, `$6060-$7FFF` but 4 bytes. The 2017 disk is the 1998
block repacked (Hrust 1 instead of HRUM 3.5).

## 1. Recordings from power-on

### 1.1 Stage 1: the boot and a first game

**Used:** `kit/re_session.py capture` on an own instance (unreal-ng worktree `scratch/wt-ane-stage1`, branch
`ane-stage1` at `210f1fe24`, muted, port base 11110), Pentagon 128 + TR-DOS 5.04T, then `re_session.py stages` on
each.

| Work | Medium, script | What it showed |
| --- | --- | --- |
| `work/stage1/c0-short` | TRD, no keys, 4000 frames | the disk does not autostart on this set-up: the boot needs the 128 menu |
| `work/stage1/c1` | TRD, `inputs/boot.txt` (`cs 7` TR-DOS, ENTER, `R` ENTER), 15000 frames | the BASIC reads 55 sectors to `$61A8`, a Hrust 1 depacker at `$FE4C` unpacks `$6060-$F76C`, Final Cut plays to its end; no game |
| `work/stage1/s1`, `s2` | SCL, `inputs/scl-boot.txt` / `scl-play.txt`, 15000 / 10000 frames | `RUN "A_NETHER"`: the intro, the boot menu, key 1, the game menu and play by frame 7452 |

The input scripts write `ss` / `cs` in lower case: the kit's `SS` / `CS` become `symbol_shift` / `caps_shift`,
which `type_input` rejects (section 5).

### 1.2 Stage 3: one recording per part of the game

**Used:** `re_session.py capture --record-load` (ane3, port base 11710, the stage 1 worktree's unreal-qt), the
original SCL unless said; `kit/screen_shot.py` for the screens, `tools/ttd_dump.py` for memory.

`--record-load` runs 1500 idle frames at the 128 menu before the script starts, and the recording's first frame is
102. Hence the offset of 1602, checked on `r2`: the save prompt of script frame 6000 shows at recording frame 7652.

| Work | Script | What it holds |
| --- | --- | --- |
| `work/stage3/x0` | `inputs/x-boot.txt` + live `tools/drive.py` steps | exploration only, not evidence; the snapshots `gamemenu.szx`, `play.szx`, `deadend-start.szx` the later runs start from |
| `r1` | `inputs/r1-help.txt`, 20140 frames | power-on, UltraXOR, the intro to the scroller's wrap (frame 8000), SPACE (8202), the boot menu (8699), all 28 help pages (9429-19679), help item 7 (20239), key 1, the game menu (21600) |
| `r2` | `inputs/r2-save-load.txt`, 9200 frames | play (7202), key 5 = the disk module's save screen (7652), `test` saved (7947), back in play (8102), the load of `test` (8932-9202), the load of the disk's own `nether` (10167-10602) |
| `r2a` | an earlier take of r2, keys 1000 frames earlier | the same save |
| `r3` | `inputs/r3-dead-end.txt` from `x0/deadend-start.szx` | **a poke, not a lost game**: `PlayerBuildings` (`$FD3A`) = 0 on `play.szx`; Dead End (100-700), GAME OVER (900-1300), the game menu (1500). Frames from the snapshot |
| `r4` | `inputs/r4-final-cut.txt` from `r4/finalcut-start.szx` | a poke: `EnemyBuildings` (`$FD42`) = 0; Final Cut to "Victory is with U!!!" (5000-15900); it never returns |
| `r5` | `inputs/r5-damaged-load.txt`, medium `r5/ane-damaged-nether.scl` | `nether.N` with two bytes changed (day `$FD37` 29 -> 99, general `$FD22` 99 -> 7, the SCL's sum recomputed): it loads, day 99 and 7 on the panel (7600-8100) |

The part agents and the doc agents added their own (each on its own port base, muted):

| Work | By | What |
| --- | --- | --- |
| `work/stage3/aned/a`, `b` | aneD | a save and load as "aned", a load of "nofile" ("File not found !", frame 10250); `b`: `nether.N` with `$FD22-$FD28` and `$DD00-$DD0F` set to `$E5` (`tools/disk_damage.py`): it plays with every resource 229 |
| `work/intro/i1` | aneI | the intro: the logo (script frames 750, 1250), "Presents" (1750), the scroller (2000), the title picture (7000), the boot menu (7250) |
| `work/endings/de`, `fc` | aneE (port base 17110) | Dead End from frame 2 (SPACE 700, GAME OVER 707, the game menu 1503); Final Cut: HRUM at 6, `FinalCut` at 50, the PT3 tune from 55, `FcEnd` at 4955 |
| `work/docL/deep` | docL (14710) | the bot's game, 36009 frames, 11.9 game days (section 6.10) |
| `work/docP/tour` | docP (12910) | 8928 frames from the game menu: redefine, Kempston, a build, orders, the distance menu, direct control, FIRE CANNON, pause, a day; with `lose` and `win` (the two pokes) |
| `work/docR/d1` | docR (14110) | power-on to play, 12900 frames; its instruction traces and L1 are the beam and interrupt measurements of docs 04, 06, 09 |

## 2. Static pass

### 2.1 Stage 1: the images and the match with NE

**Used:** `tools/ttd_dump.py` (all eight pages and the Z80 view at a frame of a recording), `tools/ne_match.py`,
`tools/entry_diff.py`.

- The images: `c1` frame 2038 (`fc-unpacked`) and 16000 (`fc-end`), `s2` frames 5000 (`scl-intro`), 8400
  (`scl-menu`) and 11500 (`scl-play`), in `work/images/`.
- `tools/ne_match.py` cuts NE's image (`../nether-earth/work/mkgame/original.bin`) by the entries of NE's
  `game.ann` and the instruction boundaries of NE's listing, with absolute operands masked so that a moved routine
  still matches. Self-check on NE's own image: 551 same + 12 fill of 563.
- On `scl-play`: 427 same, 4 moved, 7 relocated, 14 changed, 12 fill, 99 absent (`work/stage1/match.tsv`). The game
  sits at NE's addresses; this table later seeded the game's annotation (6.2).

### 2.2 Stage 2: the boot on a simulator

**Used:** `tools/ane_sim.py` (SkoolKit 10.1's simulator with 128K paging, the 128 and TR-DOS 5.04T ROMs and a
WD1793 model reading the SCL; keys scripted), `tools/sim_reads.py`. No emulator ran in stage 2.

- From `RUN "A_NETHER"` to `GameEntry` in 15 s of host time: every sector read, every `$7FFD` write (PC, value,
  frame) and every HRUM depack logged (`work/stage2/tmp/log3.txt`), 12 depacked images written.
- The first try trapped the TR-DOS entry `$3D13` and failed: UltraXOR reads the disk through ROM gadgets, not
  through `$3D13`, so the real ROM and a controller model were needed.
- Every sector of the SCL got a reader and a destination ([3.1](docs/03-build-and-load.md)). The game block is split:
  16384 bytes in bank 4 and its last 914 bytes in bank 3, between Dead End and the music.
- Two questions stayed open: who starts the picture at `$9C40`, and how the intro puts a player into bank 6
  (`ane_sim.py` logs depacks and pages, not calls). Stage 3 answered both (3.1, 6.6).

## 3. The stages and the packers

### 3.1 UltraXOR and the sector reader

**Used:** `work/stage3/ultraxor/trace.py` (the SkoolKit simulator with a write hook, stopped at `$6221`): every write
to `$5D3B-$8D60` with its PC and R. Done by a fork of ane3, 19:56-20:06.

- **The BASIC.** Line 0 is code. Line 1 is `CLOSE # USR Eternity` (`Eternity` = 23959 = `$5D97`). `$5D3F`, where
  `RANDOMIZE USR 23871` would enter, is a trap: it clears `$4000-$5BFF` and jumps to `$0000`. Six junk bytes at
  `$5D91` put a disassembly out of step.
- **The entry** `$5D97`: `DI`, SP = `$7705`, a disguised `LDIR` of `$0A36` bytes to `$7705`, `JP (IX)`. There:
  "UltraXOR v1.2 (c) PARACELS", then `LD A,$2A; LD R,A`.
- **78 loops**, loop 0 at `$7721` plain. Each decrypts the next with `LD A,R`, a polymorphic mix and
  `XOR (HL); LD (HL),A`. The last (`$7FCA`) decrypts `$7FE9-$813A`; `$7FE9` is decrypted twice.
- **Why it can be rebuilt.** Interrupts are off, R starts at `$2A` and counts opcode fetches, no loop branches on
  data, and `(HL)` is read only by the `XOR`. The key stream depends on the code alone: five runs with random start
  registers gave identical bytes. `tools/ultraxor.py decrypt` matches the simulator (0 differences); `encrypt` gives
  the original (the first try differed at `$7FE9`, the byte decrypted twice).
- **The reader** (301 bytes copied to `$5D3F`): READ SECTOR through TR-DOS ROM gadgets, entered by pushing an address
  and jumping to TR-DOS's `RET` at `$3D2F`. Its order: the loader `$6161` (44 sectors), bank 7 `$DB00`, bank 4,
  `CALL $6221` (the intro, back on SPACE), 13 sectors to `$9C40` and **`CALL $9C40`: the title picture is started by
  UltraXOR's reader** (stage 2's first open question), then `$6060`, banks 3, 1 (`CALL $C000`, the boot tune), 4, 6,
  7 and `JP $6060`.

Figure: `tools/fig_ultraxor.py` ([3.2](docs/03-build-and-load.md)): 78 layers, 2515 of 2614 bytes differ cipher vs
plain.

### 3.2 HRUM 3.5

**Used:** `tools/hrum.py` (stage 2), the simulator's depacked bytes.

- The depacker was read instruction by instruction and written in Python: `hrum.py unpack` gives the simulator's
  output for all 12 blocks with 0 differences.
- The packer was guessed from the streams: greedy, the longest match, the nearest offset on a tie. `hrum.py pack`
  gives all 13 original streams byte for byte, with their 5-byte tails (Final Cut's block included, depacked from
  its stream at sector 348).
- Each block's 31-byte set-up (run address, depacker place, output, SP, DI / EI, the exit) was found by a search of
  the SCL for the depacker's first bytes `ED B8 16 03` and written as `src/sfx/blocks.asm`.
- docS measured the in-place margins: 2-4 bytes for every block (`tools/fig_hrum.py gaps`); the unpack animation is
  `tools/fig_hrum.py anim` ([3.6](docs/03-build-and-load.md)).

### 3.3 The other packers

| Packer | Where | Reproduced | By |
| --- | --- | --- | --- |
| Hrust 1 | the boot menu's 15 pictures | `tools/bootmenu_hrust.py`: all 15 streams byte for byte (the longest match within 8192 bytes, the nearest of that length) | aneM |
| Hrust 1 | Dead End's GAME OVER screen | `tools/endings_hrust.py` | aneE |
| the authors' screen LZ | the intro logo `$6783`, the title picture `$9D02` | the rule was not found: the best one left 74 tokens different. `src/res/intro/{logo,title}.parse` keep the authors' token parse; `tools/intro_screen.py pack` follows it while the screen allows and packs greedily past an edit | aneI |
| the same LZ | Dead End's picture, the game-menu picture | `tools/endings_lz.py` with `*.lzhints`: 23 + 25 original decisions no rule gives | aneE |
| Hrust 1 | the 2017 TRD | read only ([3.8](docs/03-build-and-load.md)); the TRD is not rebuilt | |

## 4. The medium from source

### 4.1 Stage 2: a patcher over NE

Stage 2 built the SCL byte for byte, but the game was not ANE's source:

- `tools/build.sh` built NE's source to NE's image; `tools/mkpatch.py` listed ANE's changes (90 runs, 3023 bytes);
  `src/game/ane-patches.asm` wrote them as ORG patches with reasons.
- The intro, the boot menu and help, Dead End, Final Cut, the disk module, bank 7, both music banks and UltraXOR were
  raw bytes in `src/res/img/` and `src/res/disk/`.
- `GameStop`'s typo was found on the way (6.11).

The owner rejected it: "some patcher ... you were to do a full reverse, lay out the sources and resources, split the
sources into modules and get a bit-for-bit result" (`work/stage3/BRIEF-SOURCE.md`). The owner also called the 8
documents (about 850 lines, no figure) hack work (`work/docs/BRIEF.md`).

### 4.2 Stage 3: every part on its own

Since stage 3 the build reads nothing of NE. `tools/build.sh`:

1. `tools/build_game.sh`: the game image `$6731-$D7D7` from `src/game/game.ann` and `src/res/game/`;
2. the part scripts, each writing `build/<part>/` and comparing with the bytes it replaced: `build_disk.sh`,
   `build_music.sh`, `build_intro.sh`, `build_endings.sh`, `build_bootmenu.sh`;
3. HRUM 3.5: the two blocks that sit inside other images first (`src/sfx/blocks.asm` with `INNER`, then
   `src/images.asm`), then every other block (`tools/packall.py`);
4. the loader, `src/loader.asm`;
5. the boot BASIC: `src/boot/a-nether.asm` assembled, then encrypted by `tools/ultraxor.py`;
6. the SCL by `tools/mkdisk.py` from `src/disk.txt`, then `cmp` with the original:
   `build: identical to orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl`.

Kept as bytes, with reasons in [src/res/disk/README.md](src/res/disk/README.md): the saved game `nether.N` (a file
on the disk, not a program) and the filler bytes no read reaches (HRUM's signature, older sector contents).
[src/res/README.md](src/res/README.md) lists every resource folder and its converter.

## 5. Tool gaps

No kit or unreal-ng file was changed in this case (the briefs forbade it): every gap was worked around in the case's
own `tools/` and the kit ones stay open for the lead.

| Gap | Seen by | Worked around | State |
| --- | --- | --- | --- |
| The kit's key names `SS` / `CS` become `symbol_shift` / `caps_shift`, which `type_input` rejects | stage 1 | the input scripts write `ss` / `cs` | open |
| `re_session.py capture --record-load` starts the script after 1500 idle frames and the recording at frame 102; the offset of 1602 is written nowhere | ane3 | measured on `r2`, stated in the notes and the docs | open |
| `kit/screen_shot.py` reads `$4000` of the CPU view, not the screen shown: while a program shows screen 7, the shot is the wrong page | ane3, docR ([9.9](docs/09-sound.md)) | intro screens taken from the bank; docP sampled bank 5 and bank 7 (`tools/fig_programs.py`) | open |
| mkgame takes one 64K image per case and its `work/*/l1.json` | stage 2, ane3, aneM, aneE, aneD | per-part wrappers over mkgame's functions: `tools/bootmenu_mkasm.py`, `disk_mkgame.py`, `endings_mkgame.py`, `intro_mkpart.py`, `game_mkgame.py` | closed: `kit/mkgame.py --part` / `--image` (part files `src/<part>/*.json`); `intro_mkpart.py` stays (phased traces with bank maps) |
| mkgame reads what ran only from L1 builds, not from a simulator trace | aneI, aneM | `tools/intro_trace.py` and `tools/bootmenu_sim.py` traces fed to the wrappers | closed for the boot menu (`"format": "trace"` sources); the intro keeps `intro_mkpart.py` |
| mkgame installs only into `src/game`, and its `--install` deletes every `src/game/*.asm` | aneM, aneG | the wrappers install into their own folders and delete nothing else | closed: a part's `dest`; install removes only the modules the old top file included |
| No banks: an address in another bank inside the image's range (`$C000` is bank 0's level data and also entries in banks 1, 4, 6) cannot be an `@equ`; the walk follows the call into bank 0's bytes | aneG | `# @bank` lines, `@isub`, patched sna2skool output | closed: the kit's `@bank` |
| No constant for another bank's address | aneM | `@const`, an aneM extension read by its wrapper | closed: the kit's `@const` |
| sna2skool's `*` reference marks land inside data rows | aneM | dropped by the wrapper | closed: `"drop_data_refs"` |
| `@isub` numbers come back in hex (skool2asm `-H`), not as the `.ann` writes them | aneM | the wrapper writes them in decimal | closed: `"isub_as_written"` |
| One run address per part: no segments, no `DISP`, no other part's source included in place; the head's ORG repeats the top's | aneE, aneD | `endings_mkgame.py` segments with their own run address and bank, `lines` segments, `external` names; aneD added `same_bytes` and `data_entries` keys | closed: part files with `segments` |
| `label_inner_addresses` writes `Label+offset` only for `LD (nn),r` / `LD rr,nn`, not `LD A,(nn)` or `LD BC,nn` | aneE | in the `.ann` | closed: `"operands": "wide"` |
| `load_l1` reads every `work/*/l1.json`, not only `case.json`'s `read_builds` | aneG | `game_mkgame.py` passes its builds | closed: `read_builds` + `code_builds` |
| sjasmplus has no file-size function | stage 2 | `tools/packall.py` writes `UN_NAME` / `PK_NAME` | worked around |
| A CPU read of `$C000-$FFFF` on a paused instance sees whatever bank is paged; the pause often falls inside the music handler with bank 1 in: the first bot read `MenuCursor` as 0 for ever, the first pokes landed in bank 1 | docL | `Bank0Reader` (`memory_at` space `ram`, page 0) in `tools/ane_bot.py`; pokes step `run_scanlines 60` until page 0 is back, then write and verify | worked around |
| `ane_sim.py` logs depacks and pages, not calls | stage 2 | stage 3's write trace (3.1) and aneS's reading of the intro (6.6) | closed |
| unreal-ng's audio capture returns the whole preallocated 30 s buffer padded with zeros after `stop` (`getBuffer().size()` instead of the samples taken, `analyzers_api.cpp` `audioCaptureResult`, `AudioCaptureAnalyzer::stopCapture`) | audio | cut by `captured_samples` | open in unreal-ng |
| A capture holds at most 30 s, and there is no long audio-only WAV recording (the video recorder gives AAC) | audio | re-armed every 1400 frames, joined | open in unreal-ng |
| TTD replay suppresses the analyzers, so no sound from a TTD recording | audio | snapshots, input scripts and deterministic bots | open in unreal-ng |
| The AY write log ring holds 32768 writes | audio | drained often | open in unreal-ng |

## 6. The game

### 6.1 The split: one agent per part

ane3 started stage 3 alone at 19:53: the recordings of 1.2, UltraXOR (a fork, 3.1) and the players (a second fork,
20:00-20:11, handed to aneS). At about 20:10 the lead split the source by part
(`work/stage3/BRIEF-SOURCE.md`). Each agent owned only its folders, wrote `tools/build_<part>.sh` that rebuilds the
bytes its part replaces, and appended its state and its stable labels to `work/stage3/SOURCE-STATE.md`. The lead
switched `tools/build.sh` to each part when it said "bit-exact" and deleted the raw file.

| Agent | Part | Folders | About |
| --- | --- | --- | --- |
| ane3 | the boot, UltraXOR, the loader, packing, the disk, `tools/build.sh`, the recordings | `src/boot/`, `src/loader.asm`, `src/sfx/`, `src/disk.txt`, `src/res/disk/` | 19:53-20:20 |
| aneG | the game image in play | `src/game/`, `src/res/game/` | 20:13-20:54 |
| aneI | the intro, "Presents", the scroller, the title picture | `src/intro/`, `src/res/intro/` | 20:13-20:47 |
| aneM | the boot menu and the help | `src/bootmenu/`, `src/res/bootmenu/` | 20:12-20:57 |
| aneE | Dead End and Final Cut | `src/endings/`, `src/res/endings/` | 20:13-20:56 |
| aneD | the disk module (bank 4), the game starter, bank 7 | `src/disk/`, `src/res/diskmod/` | 20:12-20:36 |
| aneS | the two players, the music banks, the tunes | `src/music/`, `src/res/music/` | 20:11-20:44 |

The times are the first and last files of each agent's work folders (local time); no agent logged its own.

The owner set one more rule the same evening: the source describes ANE on its own terms. NE's names are a seed, not
a reference ("as in NE" is not a description); the comparison comes later, from the two complete sources. Stage 3's
first brief had asked for a comparison article, doc 13; that was dropped.

### 6.2 The game image (aneG)

**Used:** `work/stage1/match.tsv`, NE's `game.ann` as a seed (`work/stage3/aneg/seed_ann.py`), the L1 builds of
`work/game` and `work/game-r2` (from `r2`), `tools/game_mkgame.py` (now `kit/mkgame.py`).

- The seed kept NE's lines for the entries whose bytes ANE kept, dropped the 17 entries ANE replaced and NE's
  view-buffer, font, world-state, map and music modules, and kept only `$6731-$D7D2`. From there `game.ann` was
  rewritten by hand in nine revisions (`work/stage3/aneg/ann.v1` ... `v9`).
- The result: `src/game/game.ann`, 526 entries, every one named and described; `kit/mkgame.py --install` writes
  `game.asm` and 23 modules (start, music, im2, disk, endings, robotmenu, gameturn, world, enemy, bases, ...) and
  installs them only when they assemble to the SCL's game block (`tools/game_image.py`).
- ANE's own modules: the music glue (`MusicInterrupt` `$6780`, `PlayMusic` `$67B1`, `SetGameBank` `$67DA`), the IM 2
  table at `$6800` and `ImHandler` `$696A`, the disk save and load (`GameSave` `$6905`, `GameLoad` `$A56A`,
  `LoadReturn` `$A590`), the restart (`GameEntry` `$A5DA`, `Restart` `$A5EF`), the endings' entries (`CheckGameEnd`
  `$AE6B`, `GameWon` `$AEB1`).
- Resources (`tools/game_res.py`, each round-trips): the Cyrillic font (`GameFont` `$C500`, 64 glyphs), 89 sprite
  blocks as PNG, the view edges, the map (`map/level.txt`), 44 `PrintInline` strings as UTF-8 Russian in the game's
  font encoding, the order names.
- The menu picture's depacker lives in bank 3 with Dead End: it is aneE's `menupicture` module, called as
  `MenuPictureCode` (`$E73B`), not duplicated.

### 6.3 The boot menu and the help (aneM)

**Used:** `tools/bootmenu_sim.py` (the boot program on SkoolKit's simulator: the traces `tour`, `extra`, `nofire` in
`work/stage3/bootmenu/`), `r1`, `tools/bootmenu_mkasm.py` (now `kit/mkgame.py --part src/bootmenu/bootmenu.json`).

- `src/bootmenu/bootmenu.ann`, 130 entries, 9 modules for `$6060-$F6D4`; 1167 of its 1175 instructions ran in the
  traces; the rest is mkgame's walk and the never-referenced ten-HALT `WaitFrames` `$AC3A`.
- **The traces are checked against the recording.** The 36 simulator shots of `tour` (script frame F) equal `r1`'s
  screens at frame F + 8702 pixel for pixel: the boot menu 8699, the help menu 9079, items 1-6 at 9429-19679.
- Resources: 15 Hrust 1 pictures as PNG (repacked byte for byte, 3.3), the two 4 x 8 fonts, the pointer sprite, the
  menu and the 28 pages as UTF-8 text (the authors' Latin-for-Cyrillic layout mapped).
- Findings: the help reads no Kempston, key 3 plays a sample, `ScreenDepack` relocates itself (6.11).

### 6.4 The disk module, the starter, bank 7 (aneD)

**Used:** its recordings `work/stage3/aned/a` and `b` (L1 windows `a-disk` 7600-11201, `a-start` 4550-5100),
`tools/disk_mkgame.py` (now `kit/mkgame.py --part src/disk/*.json`), `tools/disk_res.py`.

- Three outputs, each `identical`: the disk module (`src/disk/diskio.asm`: a set-up `$C000-$C064` run in bank 4 and
  the module at `$C065-$CD2B` assembled for `$4000`), the game starter and title picture (`src/disk/starter.asm`,
  `$9C40-$B78F`), bank 7 (`src/disk/bank7.asm`: the boot menu's sample at `$CE09-$FFFF`).
- Resources: the module's 64-column font (96 glyphs), the title picture as an indexed PNG whose index holds the cell
  attribute, the sample as `sample.wav` (8-bit mono, 11401 Hz).
- **The module drives the WD1793 through TR-DOS ROM instructions** (push an address, `JP $3D2F`): `$2A53`
  `OUT (C),A`, `$2090` READ SECTOR + `INI`, `$3FCA` `OUTI`. It pushes its own code address as the ROM's sector list:
  the first byte there is `$01`, which the ROM takes as the list's end.
- The load reads whole sectors: 39 x 256 = 9984 bytes from `$D92B` wrap past `$FFFF` to `$0000-$0030`, the ROM.
- Findings: no checksum, a duplicate catalogue entry on a second save (6.11); the write path does not reset its 14
  tries a sector (`NextWriteSector`) where the read path does (`NextSector`).

### 6.5 The music (aneS)

**Used:** the players' handover from ane3's fork (`work/stage3/players/handover/`), the zxart.ee collection,
ZXTune's `compiledpt2.cpp` signature, `tools/music_ptmodule.py`, `tools/build_music.sh`; `r1` checked with TTD
`memory_at` (space `ram`).

- **The players.** `src/music/stp-player.asm` is the compile player of Pro Tracker 2.40, Phantom Family's version
  ("New SoundTrack Player by PHANTOM FAMILY'1996"; ZXTune's signature: the same first 28 bytes, size `$A45`).
  `src/music/pt3-player.asm` is PT 3 Player v1.0 by Nick of GDC (`$E21` bytes, the module at player + `$E21`). Both
  are named routine by routine; no plain copy of either exists in the local collection (the trackers are packed).
- **The tunes**, found in the zxart collection by the name inside each module: MAD NIGHT (79143, the intro), TAIGA
  (83098, the game), NETHER EARTH (END) (79174, Dead End) as `.pt2`; TOMY (83087, the boot menu) and REM (83091,
  Final Cut) by X-Man as `.pt3`.
- **The compile rule** (6.11) explains every byte by which the tunes differ from zxart's files. The build compiles
  each `.pt2` for its address; the five outputs and bank 1's title cards (`src/music/title-cards.asm`, three PNG)
  are `identical`.
- In `r1`, the tune bytes of bank 1 (frames 20500, 21600) and of bank 6 (4000, 6000) equal the build; the player
  bytes differ only in their self-modified operands and the AY buffer.
- Dead End, Final Cut and the intro include these sources in place (aneE, aneI): one copy of each player in the tree.

### 6.6 The intro (aneI)

**Used:** `tools/intro_trace.py` (the simulator; phase frames in `work/intro/trace.json`: intro 52-859, "Presents"
1192-1230, scroller 1295-5807, title 5954-6019), its recording `work/intro/i1`, `tools/intro_mkpart.py`.

- Four `.ann` files (intro, title, presents, scroller) and a hand-written top, `src/intro/intro.asm`; five outputs
  `identical`, among them the plain title picture at `$9C40` and the intro image `intro-6600.bin`.
- Resources: the Eternity logo, the title picture, the "Presents" frames, the scroller's font, dither, star path and
  text (`tools/intro_screen.py`, `intro_presents.py`, `intro_scroller.py`); the screen LZ keeps the authors' parse
  (3.3).
- **How the intro puts the player into bank 6** (stage 2's second open question): the intro image holds the player and
  MAD NIGHT at `$7D2D-$A3AC`, and the `LDIR` at `$6626` copies `$2681` bytes to bank 6 `$C000`. The last byte
  (`$A3AD`, the tune's 7228th) is past the intro's block: it is 0 from the 128 ROM's reset clear (aneS).
- The scroller hooks the loader's interrupt (`TextInterrupt` `$6D24` patched into `LoaderHook` `$618A`); its text
  ends with "PRESS 'SPACE'" and starts again, about 4500 frames a cycle (`x0`).

### 6.7 Dead End and Final Cut (aneE)

**Used:** its recordings `work/endings/de` and `fc` (pokes by `tools/endings_poke.py`), `tools/endings_mkgame.py` (now `kit/mkgame.py --part src/endings/*.json`),
`tools/endings_res.py`.

- `src/endings/deadend.ann` (bank 3: modules deadend, lzscreen, gameover, menupicture, im2) and
  `finalcut-{main,bank7,screens}.ann` (Final Cut at `$6060`); both images `identical`.
- Resources: seven screens as indexed PNG (Dead End, the game menu, GAME OVER, the two alien pictures, the caption,
  Victory), the scroll font (16 x 16) and its text as UTF-8.
- Dead End waits for a key twice and returns to the game menu through `Restart`. Final Cut ignores every key and
  never returns: `FcEnd` (`$6238`) shows "Victory is with U!!!" to the end of `r4`.

### 6.8 Integration

The lead switched the parts in the order they were done: aneD, aneS, aneI, aneG with aneE, then aneM
(`work/stage3/SOURCE-STATE.md`, "Lead: integration"). After each switch: `build: identical`. Then the stage 2 path
went: `src/game/ane.asm`, `ane-patches.asm`, `tools/mkpatch.py`, the old `tools/res_formats.py`, the old font PNG and
every raw image; `src/res/img/` no longer exists. By the lead's mistake those deletions, staged before a Nether
Earth commit, went into it (`6f94056`); the rest of stage 3 came in the next Advanced Nether Earth commit.

### 6.9 The documents (four doc agents)

**Used:** the recordings of 1.2, the part sources as they were published (`<!-- snippet: Name -->` slots filled from
`src/*/*.asm` by `work/docL/fill_snippets.py` and `work/docR/fill_snippets.py`), the figure standard of NE's
`BRIEF-FIG.md`. Brief: `work/docs/BRIEF.md`; the old docs are in `work/docs/old/`.

| Agent | Docs | About | Figures and tools |
| --- | --- | --- | --- |
| docS | 02, 03, 11 | 20:10-20:37 | the memory maps (`tools/fig_banks.py`), the blocks (`fig_blocks.py`, a generated table), the boot timeline and the `$7FFD` writes (`fig_boot.py`), UltraXOR's layers, the HRUM animation, the save and load (`fig_save.py`); doc 11 generated (`fig_dataref.py`, 320 entries); no emulator |
| docL | 07, 10, 12 | 20:10-21:05 | the deep game and its experiments (`tools/ane_bot.py`, `fig_events.py`, `fig_objects.py`); doc 12 generated (`fig_routines.py` over `kit/refdocs.py`, with every code label of the other parts from their listings) |
| docP | 01, 05, 08 | 20:12-21:03 | the tour (`tools/fig_tour.py`), every program's screens (`fig_programs.py`), the fonts and the 49 game strings (`fig_text.py`); every text in full with English |
| docR | 04, 06, 09 | 20:09-21:10 | `d1`'s traces: the beam and the tear (`fig_beam_turn.py`, `fig_tear.py`), the interrupt (`fig_interrupt.py`), the states (`fig_states.py`), the tunes (`fig_tunes.py`, the players on the simulator by `tools/ay_play.py`), Final Cut's interlace, the unpack order |

The rewrite: 12 documents, 11826 lines (from 8 documents of about 850 lines), 85 figure links over 65 images in
`docs/img/`, and the index and terms in [docs/README.md](docs/README.md). docR left no notes file; its evidence is in
the opening lists of docs 04, 06 and 09.

### 6.10 The deep game and the experiments (docL)

**Used:** `tools/ane_bot.py` (NE's bot adapted: Pentagon 128, the handler word `ImHandler` `$696A`, `MusicInterrupt`
as the construction menu's handler, every read of `$C000-$FFFF` from RAM page 0), TTD `memory_at`, live instances
from the recording's snapshots ([10.12](docs/10-gameplay-logic.md) has every command).

- `work/docL/deep`: 36009 frames, 11.9 game days, 180 routines and 291 M instructions in its L1, 70 MB of TTD. The bot
  built 7 robots; the enemy outbuilt it (21 born, 16 at the end); 17 captures, all of neutral factories; the first
  shot at frame 20513; neither side lost a warbase ([10.13](docs/10-gameplay-logic.md)).
- The nuclear bomb, by a poke on a replay from `deep` frame 3000: point 4's owner `$04` -> `$80` at frame 4796, the
  flash 4804-5032.
- A destroyed base captured again, on the same instance: owner `$80` -> `$40` at frame 6640, our warbases 1 -> 2, +10
  general at midnight (a bug, [10.11](docs/10-gameplay-logic.md)).
- Both ends from `deep` frame 22000 with `$FD42` / `$FD3A` poked to 0: Final Cut / Dead End at the next turn.

### 6.11 Findings

| Finding | Witness |
| --- | --- |
| **The help reads no Kempston.** Its pointer takes Q / A / O / P and SPACE, the Sinclair keys 6-0, or the cursor keys with CAPS SHIFT; the stage 3 notes and the old doc 02 had said Kempston | `ReadControls` `$ADB3`, bits in `Controls` `$AE20`; `bootmenu_sim.py` trace `extra` (the cursor keys at frames 700-711); aneM |
| **Key 3 ("NOT used") plays a sample**: 12790 bytes of 4-bit AY volumes from bank 7 `$CE09` through registers 8-10, 307 T a sample (11401 Hz, about 1.1 s) | `PlaySample` `$6273`; trace `extra` frame 50 (aneM); the render `flow` presses it at frame 23700 (6.12) |
| **`ScreenDepack` relocates itself.** A `CALL` to a `RET` in the ROM leaves its own address under SP; it then writes `GetBit`'s real address over the operands of its eleven CALLs (`RelocTable` `$69AB`: the distances between them). The image holds them as the authors assembled it (`$62D5`) | `src/bootmenu/depack.asm`; the 15 pictures unpacked in `r1` and the traces |
| **`GameStop` writes `$6D6A`**, a typo for `ImHandler` `$696A`: it writes into the view buffer and leaves the handler. Harmless: nothing calls `GameStop` | `GameStop` `$AF00` (`tools/entry_diff.py`, stage 2; a search for `$AF00` as an operand); code only |
| **A second save of the same name adds a second catalogue entry**; the load finds the first | `SaveFile` `$47D9` and `WriteFile` `$480C` look for no existing entry (aneD); code only, no recording saved twice |
| **No checksum on a disk save.** `nether.N` is `$D92B-$FFFF` and nothing else; the tape path's sum test is NOPs and `LoadReturn` writes `$FFFF` over the word it compared | `r5` (day 99 and general 7 load, frames 7600-8200), `aned/b` (every resource 229) |
| **The disk's own `nether.N` is an advanced game**: day 29, 10.35, the enemy on 3 warbases, general 99 | `r2` frame 10602 |
| **PT3 effect 5 jumps to itself.** Channel B's on-off effect writes `LOW ChBOnOffJp` into `ChBOnOffJp`'s operand: a JP to itself, and the player hangs. Kept, commented BUG | `src/music/pt3-player.asm`; code only |
| **The PT2 compile rule.** Samples and ornaments no pattern names are dropped (ornament 0 kept), the rest moves down, every sample, ornament and channel pointer gets + the module's address (`$CA45`), the pattern table pointer stays an offset; a length word before the module | every byte of TAIGA (zxart's is the editor file, 126 bytes longer: 18 empty samples, 12 empty ornaments) and of MAD NIGHT; NE End and MAD NIGHT on zxart are already compiled (aneS) |
| **The title picture is started by UltraXOR's reader** (`CALL $9C40`) after the intro returns on SPACE | `work/stage3/ultraxor/trace.py` (3.1) |
| **The starter fades the title in** through the 8 paper colours, two frames each, before the picture's attributes | `src/disk/starter.asm`; aneD |
| **On the Pentagon only `$68FF-$6900` of the 257-byte IM 2 table is used** (the bus reads `$FF`) | `r2` L1 reads of every interrupt (docS) |
| **The game's own bugs** kept from the code: a full player side writes into the enemy's slot 24, the stray target pointer, values over 99 print a wrong tens digit, a loaded game keeps the menu's shots | [10.11](docs/10-gameplay-logic.md) |

### 6.12 The audio renders

**Used:** `tools/render_audio.py`: an own unreal-qt instance offscreen with the master muted, Pentagon 128 + TR-DOS with
one plain AY (AY-3-8910 curve, ABC stereo, 1.75 MHz), `run_frames`, unreal-ng's audio capture (`POST
/audio/capture`, re-armed every 1400 frames between two frames, the pieces joined), `lame` for the MP3s.

| Render | From | Frames |
| --- | --- | ---: |
| `flow` | power-on with `r1-help.txt`'s `RUN "A_NETHER"`: MAD NIGHT, SPACE (13486) and TOMY, key 3 (23700) the sample, key 1 (24104) the title cards and TAIGA | 33809 |
| `deadend` | `x0/deadend-start.szx`: Dead End with NETHER EARTH (END) | 1300 |
| `finalcut` | `r4/finalcut-start.szx`: Final Cut with REM | 15000 |
| `pokes` | `x0/play.szx` with `SoundFx` (`$FD53`) set to each effect: fire (10), miss (160), hit (190), kill (220); the beeper's buffer | 290 |
| `sfx` | the `tour`: the menus' beeps, the START ROBOT chirp and the cannon shot; the construction menu with the music under it | |

The result is in [docs/audio](docs/audio/README.md): the five tunes, one pass each and a fade (the pass length is
measured from the AY writes' period, the loop checked by the loudness correlation one period apart: 0.957-1.000), the
sample (1.12 s, cut by the AY write log) and 13 effects. Docs 01 and 09 link them. A whole run takes about 2
minutes. The renders found four gaps in unreal-ng's audio capture (5).

## 7. Review

What stands proved and what does not:

- **Bit for bit.** `tools/build.sh` builds the SCL from source; each part's `build_<part>.sh` also compares its own
  output with the bytes it replaced. The lead ran the whole build after each switch (6.8).
- **Kept as data, not derived.** `nether.N` and the unread fillers (4.2). The authors' LZ decisions in the `.parse`
  and `.lzhints` files (3.3). TOMY and REM as `.pt3` files: PT3.1 conversions of zxart's PT2 modules; no PT2 -> PT3
  converter was written.
- **Not built.** The 2017 TRD: read and recorded (`c1`), not rebuilt from source.
- **Reached only by POKE.** Dead End (`r3`, `de`, `lose`) and Final Cut (`r4`, `fc`, `win`): no recording lost or won a
  game. The nuclear bomb and the recapture of a destroyed base (6.10).
- **The boot parts ran on a simulator.** The boot menu, the help and the intro were annotated from SkoolKit traces.
  The help's traces equal `r1` pixel for pixel, but no emulator trace covers them: TOMY's cost in doc 09 is the
  simulator's, and their handler and tune counts in doc 04 come from `r1`'s L1.
- **Known only from the code**, collected from the docs' own lists:
  - the disk module's error paths: no disk, Retry / Abort, write protect, a full catalogue, a full disk
    ([3.7](docs/03-build-and-load.md), [8.6](docs/08-hud-and-text.md));
  - a second save of the same name (6.11);
  - `GameStop` and its typo; `UnusedTapeCode` `$AE29`, the tape path of the menu, `GameOverWait` `$AEEA` (never run);
  - the PT3 player's effect 5 on channel B (6.11);
  - the release limit, the order limit, the 50 % missile rule, the wall rule, the pile of wrecks
    ([1.13](docs/01-game-design.md));
  - a full player side (24 robots) writing into the enemy's slot ([10.11](docs/10-gameplay-logic.md));
  - a turn longer than 10 frames, the shot sound inside a traced interrupt (`SoundEffect` and `Beep` have no call
    in `d1`'s L1), a view with many robots ([4.9](docs/04-game-loop.md), [6.12](docs/06-rendering.md),
    [9.9](docs/09-sound.md));
  - the screen shown during the intro's 49 stray `$7FFD` writes ([9.7](docs/09-sound.md));
  - `LogoPicture` in the intro, not traced.
- **Not verified.** Where the game starter joins the two parts of the game block before its depack (docS).
- **Inferences.** "Likely" in a comment means a reading of the code with no run behind it.

## 8. Cost

### 8.1 Time

From the brief files, the work folders' file times and the commits (local time, 2026-11-04). Tokens were not
measured: no `tools/case_tokens.py` run was made for this case.

| Stage | Wall time | Agents | Evidence |
| --- | --- | --- | --- |
| 1 | 16:15-16:59, about 45 min | 1 | `work/BRIEF.md` 16:15, `work/stage1/` 16:19-16:54, commit `7955ee7` 16:59 |
| 2 | 16:59-18:10, about 70 min | 1 | `work/stage2/BRIEF.md` 16:59, `NOTES.md` 18:08, commit `675c7fe` 18:10 |
| the owner's review | 18:10-19:53 | | no work in this case |
| 3, source | 19:53-21:05, about 70 min | ane3, its 2 forks, 6 part agents | `work/stage3/BRIEF.md` 19:53, the part folders (6.1), `tools/build_game.sh` 21:05 |
| 3, documents | 20:06-21:10, about 65 min | 4 doc agents | `work/docs/old/` 20:06, the doc agents' folders (6.9) |
| 3, audio | 20:40-21:33, about 52 min | 1 audio agent (also Nether Earth's renders) | `work/audio/`, `docs/audio/*.mp3` 21:30-21:33 |

- **Agents:** 15 in all: one in each of stages 1 and 2; in stage 3 ane3 and its two forks, six part agents and four
  doc agents. About 11 at once around 20:15 (ane3, the six part agents and the four doc agents). One more agent
  rendered the audio.
- **Wall clock of work:** about 1 h 55 min for stages 1-2 and about 1 h 20 min for stage 3 up to 21:11, about 3.2 h
  in all.
- **Agent time:** not measured per agent; the folder times of 6.1 and 6.9 give about 25-55 minutes for each part
  agent and 27-60 minutes for each doc agent.

### 8.2 What came out

- **Source:** 75 `.asm` files, about 25000 lines: the game 10154, the boot and UltraXOR 1926, the boot menu 2103, the
  disk module 1671, the music 3887, the intro 2911, the endings 1869, the packing 280, the loader and the image
  glue; 14 `.ann` files where a part is generated.
- **Resources:** 167 files in `src/res/` ([README](src/res/README.md)).
- **Tools:** 68 scripts in `tools/`: the build scripts, the part converters and wrappers, 20 figure scripts, the
  simulator, the bot, the renderer.
- **Documents:** 12 and their index, 11826 lines, 85 figure links (65 images, 12 MB).
- **Recordings and work files:** 1.4 GB in `work/`.
