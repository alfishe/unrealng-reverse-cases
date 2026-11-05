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
| disassembly of the boot, the loader, block 4 | the boot order, the installer, the 25 patched places, the level table (4 FX records, 45 module records) |
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
| the 128 KB "overrun" | the firmware's RAM test and page list read in the GS ROM sources, card RAM read after loads (`work/stage2/x3`) | not an overrun: the firmware's page list on 128 KB is `[2, 3, 4, 1]` with page 1 only half usable (its upper half is the fixed `$4000` window), so `$00000-$03FFF` is the firmware's last half page. 112 KB for data; every level fits ([9.5](docs/09-sound.md#95-card-sizes)) |
| the hidden menu items | the menu's code (`src/disk/menu.ann`), then key 0 and 8, key 0 and T on a fresh boot (`work/stage2/menu`) | key 0 reveals INFINITE LIFE and SELECT LEVEL; key T started level 5 (`$B073` = `06 05`) ([5](docs/05-controls.md), [10.3](docs/10-gameplay-logic.md#103-the-menus-options-as-code)) |
| the start-up and menu against the 48K | `tools/fig_compare.py` over real frames (`work/stage2/shots`) | `docs/img/compare/` |

## 4. Tool gaps

No unreal-ng change was made in this case. The gaps met (with their evidence in `work/stage1/NOTES.md`): no unplug
of a GS card (`slots_unplug` unknown), the port history stream buffered until it is switched off, the frame counter
reset by a snapshot load, the GS card's SZX approximate, no breakpoint counts without a stop (the memory profiler
was used), the signature base without Trush, MOD or GS entries. A snapshot loaded without its disk hangs in TR-DOS
(`$3FE7`): every stage 2 run boots the TRD fresh.

## 5. What stays open

- FX 12 played once (level 7); its other level, 11, was not reached.
- The homing missile's launch (MissileLaunchHook at `$9CFA`) was not seen; the seeker's was.
- The counts are of the stubs entered, not of the FX the card played (the gate and the mode drop some).
- Figures still to make: the memory map (2), the disk map and the unpack animations (3, 9).
