# Rick Dangerous 2 (Micro Style, 1990)

State: in progress (stage 1 done: the recordings, the images, the memory map, the timing; stage 2 next).

| | |
| --- | --- |
| Machine | 48K and 128K from one two-sided tape (ZXDB: "Multi-loader in 128K mode", "Multi-loader in 48K mode"). This case runs the 128K: there level 1 (Hyde Park) is in memory after side A and starts with no tape; each other level is read from side B ([WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium), [doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)). The 128K adds the AY music: RAM 1 holds 3219 non-zero bytes at the entry (`work/stage1/images/entry.ram.bin`) |
| Profile (AGENTS.md 4.0) | a platform game for one player (stage 1 view, to be confirmed in stage 2): Rick runs, jumps, climbs and crawls through five levels, each a set of sections one screen wide that scroll up and down in steps of 8 character rows, the next section entered at an edge ([doc 2, 2.2](docs/02-architecture.md#22-the-level-maps)): Hyde Park London, the Ice Caverns of Freezia, the Forests of Vegetablia, the Atomic Mud Mines and the Fat Guy's headquarters (the level menu `$7FC7`, the names at `$7FE1-$8063`). Objects: detonators (fire + down), the punch (fire + left or right), a ray gun with limited ammunition (fire + up), the anti-gravity bike. Enemies of each level and moving hazards that kill on touch; a boss at the end (the Fat Guy, level 5). A completed level gives a life and refills ammunition and detonators; the HUD shows the score (six digits), the lives, the ammunition and the detonators. The level menu offers levels 1-4; level 5 opens only after four levels completed in one game (`$8065`), otherwise level 4 ends the game with "CONGRATULATIONS ... TO COMPLETE THE GAME PROPERLY YOU MUST COMPLETE ALL LEVELS IN ONE GAME STARTING FROM LEVEL 1" (`$8754`, the text `$87A2`). After the Fat Guy the bonus tally and the ending text (`$883D`: "AND SO RICK SAVES THE DAY ..."). Controls: keyboard (Z X O K, SPACE or ENTER fire, P pause, E quit), Kempston, cursor, Sinclair (the menu `$8159`; the method byte `$7252`, read by `$7254` into `$7253`). Sound: AY music and effects on the 128K. The code: IM 2 (I = `$FD`, the table `$FD00-$FE00`, the vector `$FEFE` falls into `$FF00`); a self-decrypting tape loader that reads every byte in reversed bit order ([WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on)) |
| Authors | Core Design (the loading screen's logo; ZXDB 4137: creator Terry Lloyd). Music: Ben Daglish and David Pridmore, as the AY rips credit them (zxart.ee tunes 55079 and 61702-61713); not seen in the program yet |
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
| RZX archive `rick2-1.rzx` ... `rick2-5.rzx` (Jim Waterman, SPIN 0.5, 128K, "with rollback"; 26 688, 24 380, 11 739, 20 126 and 26 258 frames) | someone else's run, one file a level, to the ending | used, said so, to reach the levels and the ending ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)). Its memory is the Micro Style data except a 167-byte block at `$846A` (the level loader): the run was made from a TAP version |
| ZXDB `RickDangerous2.txt` (the Kixx instructions), the World of Spectrum maps of levels 1-5, the POKE file | documents | the keys, the levels, the items; POKEs such as infinite lives `35376,0` |

## Sources

- No SkoolKit disassembly or other reverse of the Spectrum version is known (GitHub searched on 2026-11-12:
  `pedlop01/rick2` is a remake, `Haltero-Abstract/Rick3D` a 3D game): every name here is ours.
- ZXDB 4137 (spectrumcomputing.co.uk): the releases, the authors, the instructions, the maps, the POKEs.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

Not written yet (stage 3): `tools/build.sh [SJASMPLUS]` will build the tape from `src/game/*.asm` (written by
`kit/mkgame.py` from `src/game/game.ann`) and the resources in `src/res/`, and compare it with the original byte for
byte.
