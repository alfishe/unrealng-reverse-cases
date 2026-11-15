# MASK III: VENOM Strikes Back (Gremlin Graphics, 1988)

State: docs written, in review (2026-11-15): docs 01-10 by three writers, docs 11 and 12 generated, integrated; the
tape builds identical from the sources. 12 documents, 74 figures (PNG), 42 animations (GIF), 69 mermaid diagrams and 39
audio files (33 short WAV, the longest 4.6 s; 6 MP3: the three tunes and three effects over 5 s; 6.7 MB),
counted on 2026-11-15 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs -name '*.mp3' | wc -l; find docs -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K and 128K from one tape (ZXDB machine type "ZX-Spectrum 48K/128K"). The loader tests for the 128K (it writes a byte in RAM 0, pages RAM 4 through `$7FFD` and checks the two apart) and on a 128K loads one more block, the AY music and its player, into RAM 4 at `$C000`; the flag `$FFFE` (0 on a 128K) picks the AY player or the beeper in the interrupt handler ([doc 3, 3.3](docs/03-build-and-load.md#33-the-loader)). This case runs the 128K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 3045: Colin Dooley (code), Marco Duroe (graphics), Ben Daglish (music), Ian Naylor (inlay); the menu credits "PROGRAM FUNGUS", "GRAPHICS MARCOS DUROE", "MUSIC BENN" |
| Release | ZXDB 3045: MASK III: VENOM Strikes Back, Gremlin Graphics Software Ltd, 1988, £7.99; re-releases IBSA and Erbe Software ("Serie Leyenda", Spain), the compilation Space Ace (Gremlin, 1989) and Erbe's +3 disk "2 Por 1" with Northstar. Genre in ZXDB "Arcade Game: Platform" |
| Original | `orig/MASKIII-VENOMStrikesBack.tzx.zip` (md5 `a3e2ca1d5031d3e244972c32cb0fa737`, SHA-1 `c7863f5386ceeb72b5cc7ba2b1ac10752f1db3c6`; ZXDB `pub/sinclair/games/m/MASKIII-VENOMStrikesBack.tzx.zip`, the Gremlin release, a Ramsoft dump): `Mask III.tzx` (51 775 bytes, md5 `558163ec2f9b32b86f1d00e1378a1481`, SHA-1 `beb94c095027c0e2df39fcc5cc86873df8b19406`): a BASIC "MASK3", a 256-byte loader at `$FF00`, the screen, the code (40 448 bytes at `$6000`) and the 128K block (4000 bytes), all standard ROM blocks ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

Each row from the documents.

| Row (AGENTS.md 4.0) | MASK III |
| --- | --- |
| Genre | a flick-screen arcade platform shooter for one player: Matt Trakker walks, jumps and shoots through 16 rooms of six screens each in four zones (0 the surface, 1 the caverns, 2 the moon, 3 the base), linked by teleport pods, to find his son Scott in room 15 ("YOU HAVE FOUND SCOTT"); one energy bar and no lives, a game ends with MISSION TERMINATED; four password doors in room 0 ([doc 1](docs/01-game-design.md), [doc 7, 7.2](docs/07-objects.md#72-the-world-rooms-screens-and-the-room-table)) |
| Weapons and pick-ups | four mask slots chosen by the keys 1-4, each with BCD charges (99 when taken) and a level; ten masks: PENETRATOR (walk through walls), HEALER (energy), JACKRABBIT (a shot and the long jump), LIFTER, BLASTER, BACKLASH, LAVA SHOT, STREAMER (shots), ULTRA FLASH and MIRAGE (do nothing); LAVA SHOT, STREAMER, ULTRA FLASH and MIRAGE lie in no room; door 3 gives LIFTER; block items cost 25 energy ([doc 1, 1.6](docs/01-game-design.md#16-the-rules), [doc 10](docs/10-gameplay-logic.md)) |
| Enemies and bosses | one enemy kind a screen from 20 templates at EnemyTemplates `$BE3B` (flyer, faller, wave flyer, walker, chaser, guard, riser, the boss and its shot, the groups of kinds 6 and 10), the turrets built from the map's `$12` blocks; kinds 6 and 10 spawn only on two rooms and were run by POKE ([doc 1, 1.7](docs/01-game-design.md#17-the-enemies), [doc 7](docs/07-objects.md)) |
| Map | the room table at `$953B` (exits by the edges and pods, the zone, an enemy kind a screen), the maps at `$7600` (40 block bytes a screen), the blocks at `$8500`, four zone character sets swapped into `$E000` by SwapZone `$A198` ([doc 7](docs/07-objects.md)) |
| Rendering | flick-screen; the room drawn into a character map (CharMap `$F080`), sprites built each pass as fresh characters from the background and pre-shifted frames, a dirty map (`$F3C0`) that FlushDirty `$A1F0` scans to write only changed cells, one pass late for the erase; no wait for the beam ([doc 6](docs/06-rendering.md)) |
| Engine | IM 2 through a `$FF` table at `$FE00` and a `JR` at `$FFFF` that lands on `JP $9226`; the interrupt runs the music or the beeper, the cheat check, the message scroller and the BREAK test (2.4 % of the CPU in play on the 128K, 3.5 % on the 48K); the main loop runs free, 2.4 to 5.4 frames a pass; one 128K test in the loader picks the AY or the beeper ([doc 2](docs/02-architecture.md), [doc 4](docs/04-game-loop.md)) |
| Sound | Ben Daglish's three AY tunes and player in RAM 4 on a 128K (about 212 T a frame in play), 18 effects through effect slots on the AY, all of it on the beeper on a 48K ([doc 9](docs/09-sound.md)) |
| Controls | menu: 1 KEMPSTON, 2 INTERFACE 2, 3 CURSOR, 4 KEYBOARD, K DEFINE KEYS, P ENTER PASSWORD, FIRE START GAME; play: left/right walk, up jump, down take or enter, fire uses the slot, 1-4 the slot, BREAK aborts; the instructions' H pause and Q abort are not in the code; the JUDGE DREDD password is a cheat ([doc 5](docs/05-controls.md)) |

## Other releases and copies

Every copy the collection index lists (`index/zx-image-locations.tsv`, the regex in `tools/fetch_copies.py`) was
fetched unchanged into `work/candidates/<source>/` (55 copies, SHA-256 checked, `work/stage1/fetch-copies.txt`) and
compared block by block with the original and with the IBSA dump (`tools/media_compare.py`,
`work/stage1/copy-compare.txt`). There are two builds of the game:

- **Build A** (the original here): BASIC "MASK3" `CLEAR 24570: LOAD ""CODE: RANDOMIZE USR 65280`; the code block md5
  `2281f690ea020272d9552d3ce41169ed`, the 128K block md5 `a110a2b07a80945ddddaca724c9b5a02`. ZXDB's four POKEs
  (`$CC1E`, `$C315`, `$B220`, `$B3DD`) fit this build, and the ZXDB AY rip holds the 128K block byte for byte.
- **Build B** (IBSA and Erbe): BASIC "VENOM" with `VAL` strings and `9999 SAVE "VENOM" LINE SIN PI: LOAD "MASTER"`;
  the code differs from build A in 13 991 bytes from offset 3042 (`$6BE2`, a shift of the code after it), the 128K
  block in 101 bytes from offset 3083.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| TOSEC 2020 "Space Ace ... (Side B).tzx" and its `[m tzxtools].tap` | the Space Ace compilation (Gremlin, 1989) | screen, code and 128K block byte for byte (build A) |
| ZXDB `MASKIII-VENOMStrikesBack128.tap.zip` (`MASK3128.TAP`); TOSEC "(128K).tzx" and "(128K)[cr].tap" | a 128K crack "Venom SB" | the code and the 128K block byte for byte (build A); another loader and BASIC |
| zxart "[h]", "[h Bill Gilbert]", "[h Andrzej Staszewski]" TAPs; "Andrey Anoshkin" TAP | hacked loaders | screen and code byte for byte (build A); "[h]" and Anoshkin also the 128K block |
| ZXDB `MASKIII-VENOMStrikesBack(IBSA).tzx.zip`, TOSEC "(48K-128K).tzx", ZXDB "Erbe - Serie Leyenda" TZX | the IBSA / Erbe re-release | build B |
| ZXDB `MASKIII-VENOMStrikesBack48.tap.zip` (`MASK3.TAP`), TOSEC "[a2].tap" | a 48K TAP | build B without the 128K block |
| ZXDB `MASKIII-VENOMStrikesBack.dsk.zip`, "2 Por 1" disks | +3 disks | another layout (99 of 158 pieces of the code found) |
| TR-DOS SCL/TRD conversions (zxart, VTRD, TOSEC "[h Universal Company '94]"), TOSEC MDR and `$b`/`$c` files, LESHIJ TZX | conversions and hacks | most hold build A's code (the JK Soft SCL all 158 pieces); a few are translations or GS-music hacks |

The ZXDB documents (instructions, maps) are not in the local collection; the instructions were read on ZXDB's page.

## Sources and credits

- The game: MASK III: VENOM Strikes Back, Gremlin Graphics Software Ltd, 1988 (ZXDB 3045); ZXDB credits Colin Dooley
  (code), Marco Duroe (graphics), Ben Daglish (music) and Ian Naylor (inlay).
- The tape: ZXDB `pub/sinclair/games/m/MASKIII-VENOMStrikesBack.tzx.zip`, the file in `orig/`.
- The RZX run: ZXDB's `mask3.rzx` (`work/candidates/zxdb/mask3.rzx`, recorded with SPIN 0.5, 37 200 frames, the game to
  its ending), someone else's play cut into input scripts; the player is not named in the file.
- The instructions: ZXDB's page (spectrumcomputing.co.uk): the keys, the masks, the passwords.
- The music's AY rip on ZXDB (`MASKIII-VENOMStrikesBack.ay.zip`) holds the 128K block byte for byte; it was only
  compared, the tunes here are decoded from the game.

## Build

```bash
tools/build.sh [SJASMPLUS]     # build/mask3.tzx, compared with orig/MASKIII-VENOMStrikesBack.tzx.zip byte for byte
```

The sources are `src/tape/basic.asm`, `src/loader/loader.asm`, `src/screen/screen.asm`, `src/game/game.asm` and
`src/music/music.asm`, written by `kit/mkgame.py` from their `.ann` (`tools/regen.sh`); the resources are `src/res/`
(`src/res/README.md`; `python3 tools/res_formats.py check`). `python3 ../../kit/refdocs.py --case .` writes docs 11
and 12.
