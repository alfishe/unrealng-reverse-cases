# Rick Dangerous 2 (Micro Style, 1990)

State: docs written, in review (2026-11-14: docs 01-10 by the writer, integrated; docs 11 and 12 generated; two review
rounds next). 12 documents, 77 figures (PNG), 30 animations (GIF), 67 mermaid diagrams and 50 audio files (9 MP3, 41
short WAV; 5.6 MB, 5 610 330 bytes; `du -sh` prints 5.4M), counted on 2026-11-14 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs/audio -name '*.mp3' | wc -l; find docs/audio -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K and 128K from one two-sided tape (ZXDB: "Multi-loader in 128K mode", "Multi-loader in 48K mode"). The entry `$7B8F` tests the paging: on a 128K it copies the AY music to RAM 1 at `$C000` and hooks its frame into the IM 2 handler; on a 48K it sets `Machine48K` `$7A76` = `$FF` and plays eleven beeper effects from the main loop ([doc 2](docs/02-architecture.md#128k-against-48k), recording `c48`). Level 1 (Hyde Park) is in memory after side A; each other level is read from side B at its start, on both machines ([doc 3, 3.4](docs/03-build-and-load.md#34-side-b-and-the-map-cipher)). This case runs the 128K, and the 48K in `c48` |
| Profile (AGENTS.md 4.0) | genre "Arcade, platform, flip-screen": Rick through five levels of 53 sections in all (9, 13, 10, 13, 8; `SectionCounts` `$8374`), each section one screen wide and up to 44 cell rows tall, left and entered at its exits, with every section drawn from the level data and the room graph per level ([doc 1, 1.7](docs/01-game-design.md#17-the-levels)); lives, bolts (the ray gun) and detonators, six of each, the punch, the anti-gravity bike in four sections; the Fat Guy at the end of level 5, which opens only after four levels done in one game (`Level5Open` `$8065`), else CONGRATULATIONS ([doc 10](docs/10-gameplay-logic.md)). Rendering rows "Flip-screen", "Scrolling (character)" (the view moves 8 cell rows in three redraws, 16 frames: [doc 6, 6.6](docs/06-rendering.md#66-the-scroll)) and "Sprites over a background" (sprites composed into spare cells, only the changed cells drawn: `DrawChangedCells` `$76D4`). Engine rows "Script or bytecode interpreter" (the traps' path and animation scripts, [doc 7, 7.6](docs/07-objects.md#76-the-traps)), "Multi-load, 128K paging" (side B's level blocks at `$A800`, RAM 1 for the music) and "Copy protection, cipher, packer" (the loader at `$FF00` deciphers itself, every block is stored bit-reversed, each level's last 768 map bytes are enciphered: [doc 3](docs/03-build-and-load.md)). One pass of `MainLoop` `$7D2D` every 2 frames or more, IM 2 ([doc 4](docs/04-game-loop.md)). Sound rows "AY tracker (own)" (eleven tunes and 28 effects in RAM 1) and "Beeper in the loop" on the 48K ([doc 9](docs/09-sound.md)). Controls: keyboard Z X O K and SPACE or ENTER, Kempston, cursor, Sinclair; P pause, E quit, two cheat chords ([doc 5](docs/05-controls.md)) |
| Authors | Core Design (the loading screen's logo; ZXDB 4137 credits Terry Lloyd). Music: Ben Daglish and David Pridmore, as the AY rips credit them (zxart.ee tunes 55079 and 61702-61713); the program names no one (levels 1-4 hold "CORE  DESIGN" at `$C206`, [doc 10, 10.15](docs/10-gameplay-logic.md#1015-notable-features)) |
| Release | ZXDB 4137: Rick Dangerous 2 (aka Rick Dangerous II), Micro Style (USA/UK), 1990, £9.99 (disk £14.99); re-releases Erbe Software (Spain), Kixx (UK), MCM Software (Spain). Golden Joystick 1990 "Computer Game of the Year 8-bit", Crash Smash (issue 82), Your Sinclair Megagame (issue 59) |
| Original | `orig/RickDangerous2.tzx.zip` (md5 `9f534e1d75b657e46e1bd75617abf8a5`, SHA-1 `7bf50462cb7cbe6dda285a577ef1b14e3a930549`; ZXDB `pub/sinclair/games/r/RickDangerous2.tzx.zip`, the md5 ZXDB lists; "TZXed by Mikie & Andy Barker"): `Rick Dangerous 2 - Side A.tzx` (48 193 bytes, md5 `3481ff6dbe9c6727ca3e6b89b032ae7b`, SHA-1 `9d31820ab4a250b5fb5411aca829fda03ef0b3c9`): a BASIC "RICK-II", a "loader" of 256 bytes at `$FF00`, then two headerless blocks in the loader's bit-reversed form (the screen, 6912 bytes, and the code, 40 702 bytes at `$6000`); `Rick Dangerous 2 - Side B.tzx` (109 007 bytes, md5 `80cb5c4df33634b75324431d5975b4ed`, SHA-1 `f2ab4ef2218bc65717cae902b106107a6dae11e8`): five headerless level blocks of 21 760 bytes in the same form |

## Other releases and copies

Every copy the collection index lists (`index/zx-image-locations.tsv`, the regex `rick.?dangerous.?(2|ii)`) was
copied unchanged into `work/candidates/<source>/` by `tools/fetch_copies.py` (`work/stage1/fetch-copies.txt`);
`tools/tape_compare.py` compared the tapes block by block with sides A and B (`work/stage1/tape-compare.txt`), and the
plain-order copies were compared again after undoing the bit reversal ([WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| ZXDB `Rick Dangerous 2 (Kixx) - Side A.tzx`, `- Side B.tzx` | the Kixx re-release | side A: 32 bytes of the 256-byte loader block differ from offset 223 (the tail the stack overwrites); the screen and code blocks byte for byte. Side B byte for byte |
| ZXDB `Rick Dangerous 2.tap` (md5 `c17a9e36...`) | a decoded re-save of the Micro Style tape | a new 333-byte BASIC that patches its loader (245 of 256 bytes differ); the screen and code in plain bit order, equal to the original's decoded code except 13 bytes at `$8479-$8485` (the level loader); the five level blocks are the Erbe ones |
| ZXDB `Rick Dangerous 2 - Side 1 (Erbe).tzx`, `- Side 2 (Erbe).tzx`, `Rick Dangerous 2 (Erbe).tap` | the Spanish Erbe re-release | another build: standard ROM blocks (a 160-byte BASIC, a `"$"` screen, a "code" block at `$6000`), the code shifted (its POKEs are 24 lower). Side 2 keeps the bit-reversed form; its level 2 differs in 8 bytes (`$E2AE-$E2B5`), its level 5 in 64 bytes (`$F7F0-$FAE5`: it addresses a table at `$7B7E` where side B uses `$7B8F`, the address side A's code uses 14 times) |
| ZXDB `RickDangerous2.tap` (md5 `047420f8...`), TOSEC `Rick Dangerous 2 (Europe).tzx` | re-saves | new BASICs (1256 and 285 bytes); the ZXDB one has "SCREEN" and "CODE" blocks, the TOSEC one packed blocks RICK_II.1 (3975 bytes) and RICK_II.2 (35 421 bytes); both have level blocks " rd2blck A-E" in plain bit order (A, C and D equal the Erbe TAP's) |
| ZXDB `Rick Dangerous 2.dsk` (md5 `2e1fc1f2...`) | the +3 disk | a disk version: not studied (the owner's rule: no non-standard versions for now) |
| zxart hacks: Andy Chernikov 1991, Vasilyev Anton 1991, Himself 1992, Shrsoft 1993, Softstar 1993 and undated, Silicon Brains 1994, Diamond Soft 1997, Power of Sound 1997, MiS Studio 1999, Atossoft, Evgeniy Tsalapov, Fanatic Stas, New Group, Rajsoft (two), Ruslan Filippov, Ticklish Jim | cracks and TR-DOS conversions | not studied (the owner's rule: no disk conversions for now); the Atossoft TAP holds none of the original's blocks |
| zxart "Rick Dangerous 2 Crack Intro" (three SCL, one TRD) | crack intros | not the game |
| RZX archive `rick2-1.rzx` ... `rick2-5.rzx` (Jim Waterman, SPIN 0.5, 128K, "with rollback"; 26 688, 24 380, 11 739, 20 126 and 26 258 frames) | someone else's run, one file a level, to the ending | used, said so, to reach the levels and the ending ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)). Its memory is the Micro Style data except its level loader (`$846A-$8510`), `$840D-$840E` and the page bytes at `$7A81` and `$7AC6` (`LD A,$16`: its RAM 1 calls page RAM 6): the run was made from a TAP version |
| ZXDB `RickDangerous2.txt` (the Kixx instructions), the World of Spectrum maps of levels 1-5, the POKE file | documents | the keys, the levels, the items; POKEs such as infinite lives `35376,0` |

## Sources and credits

- The game: Rick Dangerous 2, Core Design for Micro Style, 1990 (ZXDB 4137); ZXDB credits Terry Lloyd (Core Design);
  the AY rips credit the music to Ben Daglish and David Pridmore (zxart.ee 55079, 61702-61713).
- The tape: ZXDB `pub/sinclair/games/r/RickDangerous2.tzx.zip` ("TZXed by Mikie & Andy Barker"), the file in `orig/`.
- The RZX run: the RZX archive's `rick2-1.rzx` ... `rick2-5.rzx`, played by Jim Waterman (SPIN 0.5, 128K), someone
  else's run on a TAP build, cut into input scripts for the `rzx-*` recordings and said so where it is a witness
  ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)).
- ZXDB 4137 (spectrumcomputing.co.uk): the releases, the Kixx instructions, the World of Spectrum maps, the POKEs.
- No SkoolKit disassembly or other reverse of the Spectrum version is known (GitHub searched on 2026-11-12:
  `pedlop01/rick2` is a remake, `Haltero-Abstract/Rick3D` a 3D game): every name here is ours.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]           # build/side-a.tzx and side-b.tzx, compared with orig/RickDangerous2.tzx.zip
python3 tools/res_formats.py check   # every editable resource converts back to its bytes
```

The sources are written by `kit/mkgame.py` from their `.ann` (`tools/mkasm_all.sh`): the game `src/game/game.ann`,
the AY music `src/music`, the five levels `src/levels`, the loader, the screen and the tape's BASIC; the resources
are `src/res/` ([src/res/README.md](src/res/README.md), [doc 3, 3.6](docs/03-build-and-load.md#36-the-build)).
