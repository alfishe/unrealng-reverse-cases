# Terramex (Grandslam Entertainments, 1987)

State: in progress (stage 1).

| | |
| --- | --- |
| Machine | 48K and 128K from one tape. On a 128K the game uses RAM 1 (the AY music player, called by the IM 2 handler `$9491`), RAM 3 and 4 (the five explorers' data sets) and RAM 6 (the explorer selector); on a 48K the tape stops after the selector and the last block loads over the sets ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)). This case runs the 128K |
| Profile (AGENTS.md 4.0) | arcade adventure, a flick-screen platform game for one player (to be confirmed by stage 2): one of five explorers (Fortisque-Smithe, Herr Krusche, Henri Beaucoup, Big John Caine, Wu Pong; the selector also offers Help) walks, jumps and climbs through 70 rooms numbered level * 12 + column on six levels, each room 32 x 16 cells built from back-tiles (`$D600` rows of 32 back-tile indices, `$C600` back-tiles, `$F000` tiles; [doc 2, 2.5](docs/02-architecture.md#25-the-rooms-in-the-data)); 32 objects (72-byte sprites at `$8400`) picked up, carried by the invisible bearers (keys 1 and 2), swapped (5) and used, logged at `$5B7C`; creatures and hazards per room (`$C152`, 12 bytes a room); four lives (`$5B97`), a score, a high score, a countdown of 30 days 23:59 (`$5BFB`); a game ends with the last life (a space scene, then the menu) or with the ending sequence `$B0B6` in room `$28`; the main loop `$9018` never waits for the frame (2.4 to 3.3 frames a pass, [WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on)); IM 2 (table `$8E00-$8F00`, vector `$5F5F`); sound: Ben Daglish's AY music on the 128K, effects through `$C4BC`; controls: keyboard (Z X 0 K SPACE), Kempston, Sinclair; no packer, a ROM-speed tape, a BASIC loader hidden in the variables area |
| Authors | Teque Software Development: Shaun Hollingworth (program), Pete Harrap, Ben Daglish (128K music), from the menu ("BY TEQUE SOFTWARE DEV. LTD, (C) ARGUS PRESS SOFTWARE LTD, PROGRAM SHAUN HOLLINGWORTH, PETE HARRAP, +2 MUSIC BEN DAGLISH", [menu](docs/img/play/menu.png)); ZXDB 5195 adds Steinar Lund (art) |
| Release | ZXDB 5195: Terramex, Grandslam Entertainments Ltd, 1987, £8.95; re-releases Bug-Byte Premier (1987), EDOS, Zafiro Software Division (Spain, 1988). ZXDB labels the Quicksilva TZX "Original Big Box Release" |
| Original | `orig/Terramex.tzx.zip` (md5 `df641423f9205d7154dbff10dba78a54`, SHA-1 `ae3ae51b0de756fa895bcf0136908135fe849b53`; ZXDB `pub/sinclair/games/t/Terramex.tzx.zip`, downloaded from World of Spectrum and checked against ZXDB's SHA-256 `1f08f5a0...`): `Terramex.tzx` (82 306 bytes, md5 `520af78bf4878c76d3ebdc7b8d63d535`, SHA-1 `e3e8e33b07eeda3594f124932b1345b1f06aff3f`), five standard-speed blocks: a BASIC "TERRAMEX", the loading screen, `$6000-$F6F7` and `$7200-$FFFF` |

## Other releases and copies

The ZXDB files were first downloaded (World of Spectrum) while the share was not mounted; once it was, the share's
copies (`software/zxdb/files/pub/sinclair/games/t/`, the RZX, the NVG snapshot, the POKE file) proved the same by
SHA-256. Every other copy the collection index lists (`index/zx-image-locations.tsv`: zxart, the TOSEC 2005, 2012 and
2020 packs, the TOSEC MDR pack, vtrd, zxaaa, the World of Spectrum FTP mirror, the ULA+ pack) was copied unchanged
into `work/candidates/<source>/` by `tools/fetch_copies.py` (SHA-256 checked, `work/stage1/fetch-copies.txt`; one
Fatality hobeta inside a rar could not be extracted, its SCL is compared). `tools/media_compare.py` compared the tapes
block by block (`work/stage1/media-compare.txt`) and `tools/copy_compare.py` every copy by the share of the
original's blocks it holds in 256-byte pieces (`work/stage1/copy-compare.tsv`; [WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| ZXDB `Terramex(QuicksilvaLtd).tzx.zip`: `Terramex (Quicksilva).tzx` (md5 `4ecc10cf...`; archive info "Argus Press Software Ltd/Grandslam Entertainment; Teque Software Development Ltd ... 1988; TZXed by Andrew Barker") | another dump of the Grandslam tape ("Original Big Box Release") | the five data blocks byte for byte; a TZX block `$2A` ("stop the tape if in 48K mode") before the last block |
| ZXDB `Terramex(Bug-BytePremier).tzx.zip` (md5 `4039c474...`) | the Bug-Byte Premier re-release | the five data blocks byte for byte; the `$2A` block as in Quicksilva's |
| ZXDB `Terramex(ZafiroSoftwareDivision).tzx.zip` (md5 `baa40382...`) | the Spanish re-release | the five data blocks byte for byte |
| ZXDB `Terramex.tap.zip`: `TERRAMEX.TAP` (md5 `32dd91c1...`) | a re-save | the BASIC block differs in 13 bytes from offset 182: after the last load it waits for a key (`CALL $028E` in a loop) before `JP $8F00`; the other blocks byte for byte |
| WoS FTP mirror `TERRAMEX.TAP` (1 byte longer than ZXDB's), TOSEC 2005 `Terramex (Europe).TZX` (= Quicksilva's size) | other dumps | all five blocks of the original found whole |
| ULA+ pack `Terramex.tap` | a ULA+ palette version | an extra first block, the WoS TAP's BASIC, then the three data blocks byte for byte |
| zxart `(EN)[h Omega Ltd].tap` | a re-save with a new loader | a 198-byte BASIC and headers before each block; the three data blocks byte for byte |
| TOSEC 2012 `Astemex (1988)(Load 'n' Run)(it)` (two dumps); TOSEC 2005 `Terramex (1987)(Argus Press Software).tzx`, whose headers say "ASTEMEX", "aste1", "aste2" | Astemex, the unauthorized Italian version from Load 'n' Run (ZXDB) | another layout: a BASIC and two CODE blocks, 34 600 bytes at `$60EB` and 1968 at `$4050`; 44 of the 142 pieces of the `$7200` block and 9 of 150 of the `$6000` block: a 48K-only cut, not the original |
| zxart `(EN)[h Specman].tap`, `[h2 Specman]`, `[h Gryzor]` | hacks of Astemex | Astemex's two CODE blocks under new headers |
| zxart `(EN)[h Atossoft].tap` | a hack | a 42 240-byte block holding 121 of the 142 pieces of the `$7200` block |
| zxart `(EN)(128K)[h 1995 I.Boneman].scl` | a TR-DOS conversion | the screen and the `$6000` block whole, 140 of 142 pieces of the `$7200` block |
| TR-DOS conversions: TOSEC 2020 HorrorSoft / CyberPunks Unity '99, Werewolf Group '95, AmoNik / Welcome Corporation '01; zxart Eldar Agaev 1994, n-Discovery / Newart 2003 (General Sound), Alx, Andrew Strikes, Fatality (vtrd), AIG 1994 (vtrd), tiboh / Slider 2023 (vtrd); zxaaa `TERRAMEX.SCL`, `terramex.$z` | re-releases on disk | packed: at most one 256-byte piece of the original's blocks |
| TOSEC MDR `(128K).mdr`, `(128K)[a].mdr` | Microdrive conversions | packed: one piece |
| NVG `terramex_48k.zip`, `terramex_128.zip`: `TERRAMEX.Z80` | snapshots | compressed: about a quarter of the pieces |
| zxart and zxaaa crack intros (1992, 1994, Werewolf 1995, HorrorSoft 1999), "Soundtrack from Terramex (Pentagon Fix)", zxaaa demos `terramex_kol`, `terramex_act2026` | not the game | none of the game blocks |
| RZX archive `terramex.rzx` (Bobby Lequay, Spectaculator 0.60.1, 128K, 51 148 frames) | someone else's run to the ending | used, said so, to reach the rooms and the ending ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| ZXDB `Terramex (1987)(Grandslam Entertainments).pok` | "Infinite Lives": POKE 43517,182 (`$A9FD`) | a POKE file |
| ZXDB `Terramex.ay.zip`, the local `Ben_Daglish_-_Terramex_(1987).ay`; `Davos_-_TERRAMEX_(1998).pt3` | the AY rip; a later cover | not programs of the tape |

## Sources

- The SkoolKit disassembly by nzeemin, <https://github.com/nzeemin/skoolkit-game-revs> folder `terramex-zx`
  (a shallow clone at commit `6a328b3b9ebbf895eeb3f696bff6a3759ea75199` in `work/candidates/skoolkit-game-revs`):
  the starting point for names and structure. Every name taken from it is said so in the documents and checked
  against the code and our recordings; where we differ is in `work/stage1/NOTES.md`.
- ZXDB 5195 (spectrumcomputing.co.uk): the releases, the authors, the instructions (Bug-Byte, typed by Blughes), the
  maps.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # stage 3: builds the tape and compares it with orig/Terramex.tzx byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
