# Nether Earth ZS Edition (Sergey Zotov, 1998 / 1999)

State: source, resources and documents 01-12 complete (2026-11-05); both SCLs rebuild byte for byte from source.
The comparison with Nether Earth (doc 13) is not written yet.

| | |
| --- | --- |
| Machine | 128K with TR-DOS: Pentagon 128 (the disk's autostart; started from the boot menu's TR-DOS item the '99 hangs), Scorpion ZS-256. The '99 resets on a 48K + Beta 128 ([3.6](docs/03-build-and-load.md)) |
| Author | Sergey Zotov (ZS); the '98 dated 23.12.1998, the '99 28-30.01.1999 |
| '98 | `orig/NEZSED98.zip` (md5 d5e0b181c5323a9bc5459399f4c4953f, SHA-1 b2e91f69ff3b5579d48c70330f6b7f7b6d0548fc), holding `NEZSED98.SCL` (40 219 bytes, md5 f031101cee5ddb9b20d5ee6f99278161, SHA-1 9ba8536089b383347b396340c848eed9647f4158) |
| '99 | `orig/NEZSED.ZIP` (md5 24a13a6972ddfad4db560ec496799f2b, SHA-1 4a982e720b1e3be216d32674643888ac4b909ae5), holding `NEZSED.SCL` (61 705 bytes, md5 a39d18de215faccbf8c5bd193e5e2218, SHA-1 d1001dc48a278fe4958f020cb6e38dd86bf69b74) |

Two Russian editions of Nether Earth (1987).

- The '98 is one BASIC file: an intro with a PT3 tune and a scroller, a beeper menu tune, then the game.
  The enemy's robots are upgraded and its resources refilled every midnight; a warbase pays the player 8 a day.
  The built-in level has 28 capture points; LOAD NEW LEVEL crashes.
- The '99 is a disk of packed blocks: a photo intro with a Sound Tracker tune, a memory test over many paging
  schemes, and a silent start-up menu.
  The menu has four difficulty levels written into the game as code patches, enemy upgrades, controls, four texts
  and LOAD MAP for the twelve maps on the disk.
  The game has a new font, capture-point counts set by the map, and a built-in level that asks for a map.

The documents 01-12, the recordings and the terms: [docs/README.md](docs/README.md). The texts with English: [docs/texts](docs/texts/README.md). How
the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md). The authors' claims against the code:
[docs/01, 1.11](docs/01-game-design.md#111-the-authors-claims-against-the-code).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds both SCLs into build/ and compares them with orig/ byte for byte
```

One build at a time (`build/.lock`). It runs each part's build, then packs the five '99 blocks with the '99 LZ
packer (`tools/zspack.py`, the original streams byte for byte with `src/sfx/hints/`), assembles each block's set-up
and depacker (`src/sfx/zsblock.asm`), writes each block's slack and the disks (`tools/mkscl.py`, `src/disk98.txt`,
`src/disk99.txt`).

| Part | Source (`src/`) | Entries / modules | Resources (`src/res/`, [README](src/res/README.md)) | Build |
| --- | --- | ---: | --- | --- |
| '98 BASIC and REM loader | `basic98/basic.asm` | hand-written | `intro98/basic98-slack.bin` | `tools/build_intro98.sh` |
| '98 intro: PT3 player and tune, logo, robot, scroller | `intro98/intro.ann` | 107 / 7 | `intro98/` | `tools/build_intro98.sh` |
| '98 game | `game98/game.ann` | 553 / 21 | `game98/` | `tools/build_game98.sh` |
| '99 BASIC and sector reader | `basic99/basic.asm` | hand-written | | `tools/build_front99.sh` |
| '99 stage 2: the intro | `stage2/stage2.ann` | 33 / 5 | `stage2/` | `tools/build_front99.sh` |
| '99 RLE decoder and photo | `pictures99/pictures.ann` | 3 / 2 | `pictures99/` | `tools/build_front99.sh` |
| '99 Sound Tracker player and tune | `music99/music.ann` | 42 / 1 | `music99/` | `tools/build_front99.sh` |
| '99 stage 3: System checking, the loads | `stage3/stage3.ann` | 37 / 4 | | `tools/build_menu99.sh` |
| '99 start-up menu | `menu99/menu.ann` | 42 / 3 | `menu99/` | `tools/build_menu99.sh` |
| '99 game | `game99/game.ann` | 539 / 20 | `game99/`, `maps/builtin.txt` | `tools/build_game99.sh` |
| '99 patches: disk, tape, paging, 128K / 48K menus | `patches99/patches.ann` | 42 / 8 | | `tools/build_game99.sh` |
| '99 maps | | | `maps/NELEV_xx.txt` | `tools/build_game99.sh` (`tools/zs_level.py`) |
| '99 texts | | | `text/` | `tools/build_texts.sh` |
| '99 packed blocks | `sfx/zsblock.asm`, `sfx/blocks.txt`, `sfx/hints/` | | | `tools/build.sh` (`tools/zspack.py`) |

Each `.ann` becomes its `.asm` through its part's wrapper around `kit/mkgame.py`, which installs only when the
result assembles to the original bytes:

```bash
python3 tools/game99_mkgame.py all --install   # src/game99/*.asm and src/patches99/*.asm
python3 tools/game98_mkgame.py --install       # src/game98/*.asm
python3 ../../kit/check_docs.py --case .
```

The other wrappers: `tools/intro98_mkgame.py`, `tools/front99_mkgame.py` (stage2, pictures99, music99),
`tools/menu99_mkgame.py` (stage3, menu). `case.json` is the '99 game's config for the kit.

## Tools

| Tool | What |
| --- | --- |
| `tools/zs_media.py` | the SCLs' files and the '99's blocks unpacked into `work/media/` |
| `tools/zsdepack.py`, `tools/zspack.py` | the '99 backward LZ: unpack; pack bit-exact (`check` for all five blocks) |
| `tools/zs_level.py` | the maps: text to `.N`, previews, the tail fields derived and checked |
| `tools/texts_build.py` | the `.W` texts: UTF-8 to CP866 with the end mark and slack |
| `tools/mkscl.py`, `tools/scl.py` | write and list an SCL |
| `tools/fig_screens.py`, `tools/fig_compare.py` | the screenshots and the side-by-side figures against NE (real frames, nearest neighbour) |
| `tools/*_image.py`, `*_res.py`, `*_mkgame.py`, `build_*.sh` | per part: the image, the resources, the source, the build |
