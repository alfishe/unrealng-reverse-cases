# Advanced Nether Earth (Eternity Industry, 1998)

State: source, resources and documents complete (2026-11-04); the SCL rebuilds byte for byte from source.

| | |
| --- | --- |
| Machine | Pentagon 128 with TR-DOS |
| Authors | Eternity Industry, 1998; the 2017 Final Cut disk is signed by Kalantaj Konstantin, Krivoy Rog. Not in ZXDB |
| The game | `orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl` (TOSEC 2023-09; md5 81a6278d05f539d25d64dd3c5a5c9337, SHA-1 5e12a67de4582f8f42fa3c0e07d7c160b6bb98f5) |
| "Final Cut" disk | `orig/anefc.zip` (md5 f4317f485fdc3267ca576a1413003441, SHA-1 bfe700feaa2cfc1ec278d5bea69cb87e4d2e78ec), holding `orig/ANE_FC.TRD` (md5 87478117f81e142f0190764e6f3d4b82, SHA-1 caa100b86ae2770ce13cc3fa9a7d0f0fee1c4360) |

A Russian 128K remake of the 1987 robot strategy game. It has the play itself and AY music in the interrupt from
the boot to the end. It also has a disk save, Russian texts with a Cyrillic font, an intro, and a boot menu with a
28-page help program. There are two endings: "Dead End" on a loss and "Final Cut" on a win. The SCL is the game.
The 2017 TRD holds only the Final Cut win sequence, repacked with Hrust 1 ([3](docs/03-build-and-load.md)).

The documents: [docs/README.md](docs/README.md). The five tunes, the sample and the effects as mp3, rendered from
the machine state: [docs/audio](docs/audio/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).
What this game changed in Nether Earth, why, and what for, with illustrations:
[docs/13](docs/13-differences-from-nether-earth.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds the SCL into build/ and compares it with the original byte for byte
```

Each part has its own source, resources and build script. `tools/build.sh` runs them all, then:

- packs the 13 blocks with HRUM 3.5 (`tools/hrum.py`, the original streams byte for byte);
- assembles the loader and the boot;
- encrypts the boot with UltraXOR's 78 layers (`tools/ultraxor.py`);
- writes the SCL (`tools/mkdisk.py`, `src/disk.txt`).

| Part | Source | Resources (`src/res/`, [README](src/res/README.md)) | Build |
| --- | --- | --- | --- |
| the game, `$6731-$D7D7` | `src/game/*.asm`, 24 modules from `src/game/game.ann` (526 entries) | `game/`: font, sprites, view edges, map, texts | `tools/build_game.sh` |
| the boot menu and help, `$6060-$F6D4` | `src/bootmenu/*.asm`, 9 modules from `bootmenu.ann` (130 entries) | `bootmenu/`: 15 pictures, fonts, pointer, 28 help pages | `tools/build_bootmenu.sh` |
| the disk module (bank 4), the starter, bank 7 | `src/disk/` from `module.ann`, `starter.ann`, `setup.ann`, `bank7.ann` | `diskmod/` | `tools/build_disk.sh` |
| the music: two players, five tunes, the title cards | `src/music/` (`stp-player.asm`, the compiled Pro Tracker 2 player; `pt3-player.asm`) | `music/`: the tunes as `.pt2` / `.pt3`, the cards as PNG | `tools/build_music.sh` |
| the intro: logo, title, "Presents", scroller | `src/intro/` from four `.ann` files | `intro/` | `tools/build_intro.sh` |
| Dead End (bank 3) and Final Cut | `src/endings/` from `deadend.ann`, `finalcut-*.ann` | `endings/` | `tools/build_endings.sh` |
| the boot BASIC and UltraXOR | `src/boot/a-nether.asm`, `ultraxor-layers.asm` | | `tools/build.sh` |
| the loader and the packed blocks | `src/loader.asm`, `src/sfx/`, `src/images.asm` | `disk/`, `text/` | `tools/build.sh` |

Each part's build script header says how to write its source again from its annotations. For the game:

```bash
python3 ../../kit/mkgame.py --install                                   # src/game/*.asm from game.ann
python3 ../../kit/mkgame.py --part src/bootmenu/bootmenu.json --install  # a part: its src/<part>/*.json
python3 ../../kit/check_docs.py --case .
```
