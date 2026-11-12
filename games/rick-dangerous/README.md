# Rick Dangerous (Firebird, 1989)

State: in progress.

| | |
| --- | --- |
| Machine | 48K and 128K from one tape. At its entry `$AB4D` the game tests the paging (`$A043`): on a 128K it copies `$5E00-$6BA3` into RAM 1 at `$C000` (the AY music and effects) and hooks the music tick into the IM 2 handler (`CALL $A030` at `$FF11`); on a 48K it sets `$A08D` = `$FF` and plays its effects on the beeper (`$A08E`). This case runs the 128K |
| Profile (AGENTS.md 4.0) | a flip-screen platform game for one player (genre row "Arcade, platform, flip-screen"): Rick through four levels, each a run of screens the view scrolls between (South America, Egypt, Schwarzendumpf castle, the missile base: the level table `$E4AE`, 11 bytes a level, the intro texts at `$E4E5`, `$E5FC`, `$E70A`, `$E80E` and the closing text at `$E8F9`); six lives (`$A958`), six bullets (`$A976`) and six sticks of dynamite (`$A967`) a life; traps, boulders and enemies; a score. Rendering rows "Flip-screen" and "Sprites over a background". Engine rows "Multi-load, 128K paging" (RAM 1 holds the AY code on the 128K) and "Copy protection, cipher" (Firebird's Bleepload: 194 enciphered turbo blocks). Sound: AY music and effects on the 128K, beeper effects on the 48K. Controls: keyboard (O K Z X ENTER), Kempston, cursor, Sinclair, chosen on the menu; P pauses, Q quits |
| Authors | Core Design, from the menu ("C 1989 CORE DESIGN, C 1989 FIREBIRD", recording `c1`); ZXDB 4135 credits Terry Lloyd (Core Design) |
| Release | ZXDB 4135: Rick Dangerous, Firebird Software Ltd, 1989, £9.95 (disk £14.95), ZX-Spectrum 48K/128K; re-releases Erbe Software (Spain, 1992), IBSA (Spain, 1989), Kixx (1989), MCM Software (Spain, 1990); in the compilations Challengers and Six Appeal (Ubi Soft, 1991) |
| Original | `orig/RickDangerous.tzx.zip` (38 320 bytes, md5 `ac921526d9f3c64f624c987ee4f9db95`, SHA-1 `0140b1a3df95ae8a7e641001c860b4be9a59b907`; ZXDB `pub/sinclair/games/r/RickDangerous.tzx.zip`, release 0, Firebird, scheme "Firebird BleepLoad"): `Rick Dangerous.tzx` (56 605 bytes, md5 `685cf58aa8498b8b9c42d062befde83c`, SHA-1 `0587db0a1d070df60d28377bb19714d2fa6a1837`, "Created with Ramsoft MakeTZX"): a BASIC loader "Rick", the first loader stage "Rick1" (512 bytes at `$CD00`), then three groups of turbo blocks, 48 + 140 + 6 ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Other releases and copies

Every copy the collection index lists (ZXDB, TOSEC 2020 and MDR, the ULA+ pack, vtrd, zxart) was copied unchanged
into `work/candidates/<source>/` by `tools/fetch_copies.py` (`work/stage1/fetch-copies.txt`).
`tools/copy_blocks.py` compared the tapes with the original block by block (`work/stage1/copy-blocks.txt`). As the
turbo blocks are enciphered, a second search looked for the game image itself, in 562 pieces of 64 bytes of
`$6E00-$FFFF` (`tools/image.py`), inside every copy (`work/stage1/copy-image.txt`).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| `rickdan1.zip`: `RICKDAN1.TZX` (md5 `0975e1ad...`) | another dump of the Firebird tape | 150 of the 198 data blocks byte for byte; the 48 blocks of group 1 (the second loader stage) differ from byte 77 on; the game it loads on the 128K differs from ours in 19 bytes of variables and stack |
| ZXDB `RickDangerous.tap.zip`: `RICKDAN1.TAP` (md5 `1921e037...`) | the same dump as a TAP | 148 blocks byte for byte; a 774-byte BASIC that POKEs the first loader stage so that it loads from a TAP |
| ZXDB `RickDangerous.dsk.zip`: `Rick Dangerous.dsk` (+3) | the disk release | 558 of the 562 pieces of the game image whole |
| ZXDB Kixx, MCM, IBSA and Erbe TZX and TAP; TOSEC `[a2]` TAP | the re-releases | one 41 246-byte block behind a small loader (Kixx: 256 bytes at `$FF00`, its last block's checksum bad; the others: 24 bytes at `$FF80`); MCM, Erbe and the `[a2]` TAP hold 397 of the 562 pieces: a later build with its code moved (the RZX archive's run is on such a build, [WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| zxart and vtrd TR-DOS conversions and hacks | other people's conversions | packed or patched: from 0 to 527 of the 562 pieces |

## Build

The source is not written yet (stage 1). The game image: `python3 tools/image.py work/mkgame/original.bin`
(`case.json` `image_cmd`).
