# Rick Dangerous (Firebird, 1989)

State: docs written, in review (integrated 2026-11-13). 12 documents, 54 figures (PNG), 23 animations (GIF), 47 mermaid
diagrams and 26 audio files (13 MP3, 13 short WAV; 5.8 MB), counted on 2026-11-13 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs/audio -name '*.mp3' | wc -l; find docs/audio -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K and 128K from one tape. At its entry `$AB4D` the game tests the paging (`$A043`): on a 128K it copies `$5E00-$6BA3` into RAM 1 at `$C000` (the AY music and effects) and hooks the music tick into the IM 2 handler (`CALL $A030` at `$FF11`); on a 48K it sets `$A08D` = `$FF` and plays its effects on the beeper (`$A08E`). This case runs the 128K |
| Profile (AGENTS.md 4.0) | a platform game for one player (genre row "Arcade, platform, flip-screen": the zone changes at a side exit; [doc 1](docs/01-game-design.md)): Rick through four levels of 34 zones in all (South America 6, Egypt 7, Schwarzendumpf castle 12, the missile base 9; LevelTable `$E4AE`, Zones `$D55C`), each zone a tall map the view scrolls 8 rows at a time (ScrollViewDown `$ADB9`, ScrollViewUp `$ADF0`), a level ending at an exit whose zone is `$FFFF`; six lives (Lives `$A958`), six bullets (Bullets `$A976`) and six sticks of dynamite (Dynamite `$A967`) a life; enemies, traps and the timed bonus as 12 object slots (ObjectTable `$EA8E`); a score, and the lives bonus after level 4. Rendering rows "Flip-screen", "Scrolling (pixel, character, attribute)" (by chars: the view moved 8 char rows, in two steps of 4) and "Sprites over a background" (sprites composed into chars at `$5CF0` + 8n, only the flagged cells redrawn: CellFlags `$6C00`, DrawDirtyCells `$A25D`; [doc 6](docs/06-rendering.md)). Engine rows "Script or bytecode interpreter" (the movement scripts `$DF83`, 3 bytes a step; [doc 7](docs/07-objects.md)), "Multi-load, 128K paging" (three groups of turbo blocks; RAM 1 holds the AY player) and "Copy protection, cipher, packer" (Firebird's Bleepload: 194 enciphered turbo blocks, [doc 3](docs/03-build-and-load.md)); one pass of MainLoop `$E3C9` every 2 frames ([doc 4](docs/04-game-loop.md)). Sound: on the 128K an AY player with eight tunes and twelve effects, on the 48K six beeper patterns ([doc 9](docs/09-sound.md)). Controls: keyboard (O K Z X ENTER), Kempston, cursor, Sinclair, chosen on the menu; P pauses, Q quits ([doc 5](docs/05-controls.md)) |
| Authors | Core Design, from the menu ("C 1989 CORE DESIGN, C 1989 FIREBIRD", recording `c1`); ZXDB 4135 credits Terry Lloyd (Core Design) |
| Release | ZXDB 4135: Rick Dangerous, Firebird Software Ltd, 1989, £9.95 (disk £14.95), ZX-Spectrum 48K/128K; re-releases Erbe Software (Spain, 1992), IBSA (Spain, 1989), Kixx (1989), MCM Software (Spain, 1990); in the compilations Challengers and Six Appeal (Ubi Soft, 1991) |
| Original | `orig/RickDangerous.tzx.zip` (38 320 bytes, md5 `ac921526d9f3c64f624c987ee4f9db95`, SHA-1 `0140b1a3df95ae8a7e641001c860b4be9a59b907`; ZXDB `pub/sinclair/games/r/RickDangerous.tzx.zip`, release 0, Firebird, scheme "Firebird BleepLoad"): `Rick Dangerous.tzx` (56 605 bytes, md5 `685cf58aa8498b8b9c42d062befde83c`, SHA-1 `0587db0a1d070df60d28377bb19714d2fa6a1837`, "Created with Ramsoft MakeTZX"): a BASIC loader "Rick", the first loader stage "Rick1" (512 bytes at `$CD00`), then three groups of turbo blocks, 48 + 140 + 6 ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Sources and credits

- The game: Rick Dangerous, Core Design for Firebird Software Ltd, 1989 (ZXDB 4135); ZXDB credits Terry Lloyd (Core
  Design); the menu says "C 1989 CORE DESIGN, C 1989 FIREBIRD" (recording `c1`). The loader is Firebird's Bleepload.
- The tape: ZXDB `pub/sinclair/games/r/RickDangerous.tzx.zip`, the file in `orig/`.
- The RZX run: the RZX archive's `rick1.rzx` (169 042 bytes, written by SPIN 0.5; neither the file nor the archive's
  index names the player), a full run on a re-release build, turned into input scripts for `level1`-`level4` and part
  of `c1`, and said so where it is a witness ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)).
- ZXDB 4135 (spectrumcomputing.co.uk): the releases and the copies listed below.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Other releases and copies

Every copy the collection index lists (ZXDB, TOSEC 2020 and MDR, the ULA+ pack, vtrd, zxart) was copied unchanged
into `work/candidates/<source>/` by `tools/fetch_copies.py` (`work/stage1/fetch-copies.txt`).
`tools/copy_blocks.py` compared the tapes with the original block by block (`work/stage1/copy-blocks.txt`). As the
turbo blocks are enciphered, a second search looked for the game image itself, in 562 pieces of 64 bytes of
`$6E00-$FFFF` (`tools/image.py`), inside every copy (`work/stage1/copy-image.txt`).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| `rickdan1.zip`: `RICKDAN1.TZX` (md5 `0975e1ad...`) | another dump of the Firebird tape | 150 of the 198 data blocks byte for byte; the 48 blocks of group 1 (the second loader stage) differ from byte 77 on and do not decipher with this case's cipher; groups 2 and 3 (`$6E00-$FFFF`) are ours byte for byte ([doc 3, 3.12](docs/03-build-and-load.md#312-the-releases-and-the-hacks)) |
| ZXDB `RickDangerous.tap.zip`: `RICKDAN1.TAP` (md5 `1921e037...`) | the same dump as a TAP | 148 blocks byte for byte; a 774-byte BASIC that POKEs the first loader stage so that it loads from a TAP |
| ZXDB `RickDangerous.dsk.zip`: `Rick Dangerous.dsk` (+3) | the disk release | 558 of the 562 pieces of the game image whole |
| ZXDB Kixx, MCM, IBSA and Erbe TZX and TAP; TOSEC `[a2]` TAP | the re-releases | one 41 246-byte block behind a small loader (Kixx: 256 bytes at `$FF00`, its last block's checksum bad; the others: 24 bytes at `$FF80`); MCM, Erbe and the `[a2]` TAP hold 397 of the 562 pieces: a later build with its code moved and the Kempston bug fixed ([doc 5, 5.3](docs/05-controls.md#53-the-kempston-bug)) (the RZX archive's run is on such a build, [WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| zxart and vtrd TR-DOS conversions and hacks | other people's conversions | packed or patched: from 0 to 527 of the 562 pieces |

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Rick Dangerous.tzx and compares it with the TZX in orig/RickDangerous.tzx.zip
python3 tools/res_formats.py check   # every editable resource converts back to its bytes
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the parts are the tape's
BASIC (`src/tape`), the two loader stages and LoadGroup (`src/loader`) and the AY player (`src/music`), each from its
own `.ann`; the resources are `src/res/` (`src/res/README.md`).
