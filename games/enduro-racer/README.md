# Enduro Racer (Activision, 1987)

State: in progress (stage 1: the capture).

| | |
| --- | --- |
| Machine | 48K and 128K (ZXDB machine type "ZX-Spectrum 48K/128K"): one tape, one load, no level loads. The image as the loader leaves it holds AY code (`LD BC,$FFFD` at six sites from `$65F4` to `$DA3C`, `LD BC,$BFFD` at `$A16F` and `$ACD3`) beside the beeper's `OUT ($FE),A`; what a 128K does with it: [WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on). This case runs the 48K |
| Profile (AGENTS.md 4.0) | see [Profile](#profile) below |
| Authors | ZXDB 1628: Alan Laird and Ian Morrison (both of the team Giga Games), Focus Creative Enterprises Ltd; ZXDB gives them no roles. The game's own title screen (recording c1): "PROGRAMMED BY GIGA GAMES", "GRAPHICS BY FOCUS", "A SOFTWARE STUDIOS PRODUCTION", "ENDURO RACER (c) SEGA", "THE COMPUTER GAME (c) 1987 ACTIVISION". Who wrote the sound is credited nowhere found |
| Release | ZXDB 1628: Enduro Racer, Activision Inc, 1987, £9.99; ZXDB genre "Arcade Game: Race 'n' Chase"; Sega's 1986 arcade game licensed. Re-releases: Proein Soft Line (Spain, 1987), IBSA (1989), The Hit Squad (1989, £2.99, "ARCADE COLLECTION 01"); in the compilations 6-Pak Vol 3, Big Box, Fists 'n' Throttles and Ikari Warriors + Enduro Racer + Thundercats. ZXDB denies the distribution of the tape files (`/denied/entries/0001628/EnduroRacer.tzx.zip`, 32 932 bytes, md5 `d149614fddba6872b161484850ea805f`): the files here come from the collection's World of Spectrum mirror |
| Original | `orig/EnduroRacer.tzx.zip` (33 021 bytes, md5 `d7fc097b7b4ccac7f7279a3b67d9dbf4`, SHA-1 `8c7d954b798e2daceb67a2cc93b1e67700577294`; World of Spectrum `games/e/EnduroRacer.tzx.zip`, the WoS file of ZXDB's release 0; its zip is not ZXDB's (another size), so the TZX inside could not be checked against ZXDB's md5): `Enduro Racer.tzx` (51 505 bytes, md5 `38001ddd8c6b922383d25689b37cc7a5`, SHA-1 `2af0f9f7a3eb83fd6e04aaf2f6bb255db7520caf`; byte for byte TOSEC's "Enduro Racer (1987)(Activision)(48K-128K).tzx"): two BASIC programs, then the SpeedLock 2 loader's pure-data blocks ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |
| Recorded from | `[SpeedLock 2].tzx` (TOSEC 2023-09, 50 199 bytes, md5 `8d034cc4ab094a697643e1457e073556`, SHA-1 `f7592a389affae6789e7906815f8239ac542142d`): the same data blocks byte for byte (`tools/media_compare.py`), only the two BASIC headers' names differ (`end` / `race` for `enduro` / `end2`). The case's unreal-ng binary predates commit f13cee7da (an ended tape holds its last edge): the original TZX ends with its last data block and no pause, that block does not load, and the machine resets to the ROM's copyright screen at the tape's end (`work/stage1/probe1`, frame 11 682); the TOSEC dump ends with a 2 ms pause and loads |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Profile

Stage 1's first picture of the game; each row is to be confirmed by the documents.

| Row (AGENTS.md 4.0) | Enduro Racer |
| --- | --- |
| Genre | racing, driving (a behind-the-bike pseudo-3D motorbike race, as it plays in c1 and stages): five stages one after the other, each against a timer that counts down from 60 (stage 1); a stage ends when its course is driven ("EXTENDED PLAY", the lap time), then the next; time out ends the race. After stage 5 a lap-time table (RECORD and PLAYER, each stage and the TOTAL), then the score table with a name entry on a letter grid. One or two players |
| The track and the stages | five courses (the WoS info: country road, desert, swamp causeway, arctic, seaside; on screen: green grass and trees, yellow sand with rock spires, cyan sand with dunes, yellow with cacti and trucks, yellow with palms): the curves, the logs and rocks, the jumps; each to be drawn from the game's data as a map with its curves, hills and hazards |
| The bike and its handling | throttle, wheelie, left, right, brakes; the speed in km/h on the HUD (199 the most seen); speed lost off the road, by obstacles, in turns and in bike collisions (the four stores the ZXDB POKEs name); the wheelie to jump; the crash and the restart |
| Rivals and obstacles | other riders on the road and trucks (stage 4); rocks, logs, trees, cacti and palms at the roadside; the ZXDB POKEs separate "obstacles" and "trucks" |
| Timer and score | TIME (BCD at `$5E1F`) counts down; SCORE grows with distance and speed; TOP 1 000 000; no lives: a fall costs time (the rider gets up, recording crash), with two players a fall hands the turn over (recording twoplayer); the score table holds five entries with a name and a total time ("ENDURO 3'00"00 800000") |
| Rendering | a pseudo-3D road: a road table, the curve and hill model, the roadside objects and the riders scaled, the horizon scenery (mountains, dunes) shifted with the curves; a HUD of two text rows on top |
| Engine | IM 2 (one `IM 2`, at `$8109`): the handler `$643C` (vector `$6464`) has its own stack and returns by a patched `JP`; no `HALT`, a game pass takes 6-12 frames (mean 8.0, [WALKTHROUGH 1](WALKTHROUGH.md#interrupts-and-timing-first-look)); SpeedLock 2 on the tape; one load, no multiload |
| Sound | the engine from the interrupt (`$6851`): the beeper on a 48K, the AY on a 128K, picked by a checksum of the ROM (`$7C2F`); beeper tones and noise (`$AB95`, `$AC8A`, `$8AF0`) and AY effects (`$6588`, `$6806`, `$A167`, `$ACA5`); which event each serves, and any tune, to be listed |
| Controls | five methods on the menu: KEYBOARD (redefinable: THROTTLE Q, WHEELIE A, LEFT O, RIGHT P, BRAKES SPACE, PAUSE H, RESET R), KEMPSTON, SINCLAIR RIGHT, SINCLAIR LEFT (the method at power-on), CURSOR; on the menu SPACE or fire executes, any other key advances |

## Other releases and copies

Each copy found is kept unchanged in `work/candidates/<source>/` (git-ignored). The data blocks were compared with
`tools/media_compare.py`; a re-release with another protection can only be compared by its loaded image (stage 2).

| Copy | Source | What differs |
| --- | --- | --- |
| `Enduro Racer.tzx` in `EnduroRacer.tzx.zip` | WoS `games/e`; TOSEC `(48K-128K).tzx` (the same bytes) | the original, `orig/` |
| `(48K-128K)[SpeedLock 2].tzx` | TOSEC 2023-09 | the same SpeedLock 2 data blocks, the BASIC header names `end` and `race`, a MakeTZX dump with loop blocks; recorded from it (above) |
| `Proein Soft Line (ES)(en)[re-release].tzx` | TOSEC 2023-09 | the Spanish re-release: the same SpeedLock 2 data blocks byte for byte, the BASIC header names `0` and `1` |
| `Enduro Racer (The Hit Squad).tzx` in `EnduroRacer(TheHitSquad).tzx.zip` | WoS `games/e` | the Hit Squad re-release: one BASIC of 3577 bytes, then "Speedlock 7" groups with blocks of other sizes (6142, 766, 4998, 14 998, 20 534, ...): another protection and layout |
| `(48K-128K)[a].tzx`, `[a2].tzx` | TOSEC 2023-09 | two dumps of the Hit Squad tape ("SpeedLock 4" in their group names, OmikroN 1997); `[a]` breaks off (an unknown block id at offset 31 702) |
| `(48K-128K)[SpeedLock 7].tzx`, the 6-Pak Vol 3 and Fists 'n' Throttles tapes | TOSEC, knobchez 2026 | the Elite compilations' version: a 155-byte BASIC, an 8071-byte code block, a decryption tone, SpeedLock 5 / 7 blocks (6142, 766, 10 132, 10 132, 3975, 16 289, ...) |
| `(48K-128K)[t].tzx`, `[t].tap`, `[t Pokes].tap` | TOSEC | trainers: a BASIC, the screen and one 40 758-byte block at `$5FB4` in standard ROM blocks |
| `.z80`, `.sna`, `.sp`, `(128K).z80` | TOSEC, WoS `EnduroRacer48.z80.zip` | snapshots |
| `[h ...]`, `[tr ru]`, `.scl` | TOSEC | hacks, Russian translations and TR-DOS conversions |
| `nvg_sinclair_tapes_e_enduro_racer.zip` | ZXDB's NVG scraps | `Enduro_Racer.tap` (47 983 bytes): "converted from my Hit Squad copy", with an infinite-time option (Adam Hodson) |
| `Enduro Racer (1987)(Activision Inc).pok` | ZXDB | seven POKEs (infinite time, immune to obstacles, immune to trucks, keep speed off road, by obstacles, by turns, by motorbike collisions) |

Other platforms' versions exist (Sega's arcade game, the Master System, Amstrad CPC, C64); none is used here.

## Build

Not yet: the source is stage 2's (`tools/build.sh`, `src/game/game.ann`, `src/res/`).
