# Enduro Racer (Activision, 1987)

State: docs written, in review (2026-11-16): docs 01-10 by three writers, docs 11 and 12 generated, integrated; the
tape builds identical from the sources. 12 documents, 86 figures (PNG), 47 animations (GIF), 67 mermaid diagrams and
12 audio files (7 short WAV, the longest 3.5 s; 5 MP3 over 5 s: the two tunes, the two engines and the 128K race;
3.0 MB), 14 recordings (WALKTHROUGH 6.0; three tries kept out), counted on 2026-11-16 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs -name '*.mp3' | wc -l; find docs -name '*.wav' | wc -l; du -sh docs/audio
```

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

From the documents ([docs/README.md](docs/README.md)); each row names the document that holds the detail.

| Row (AGENTS.md 4.0) | Enduro Racer |
| --- | --- |
| Genre | a behind-the-bike pseudo-3D motorbike race: five stages one after the other against a timer (60 at stage 1, EXTENDED PLAY adds 50 at each stage's end, at most 99); time out ends the race; after stage 5 the lap table, then the high scores with a name entry on a letter grid; one or two players taking turns at each fall ([doc 1](docs/01-game-design.md)) |
| The track and the stages | five courses of 128-unit segments (4 096, 2 944, 3 328, 3 456 and 4 096 units; the finish at 17 920): each segment byte a bend (bits 0-1), a crest (bits 2-3) and the bend's side; the track a list of elements and pattern calls (type and gap), counted as TrackStep counts them; stage 3 alone has gap marks; maps in [doc 1](docs/01-game-design.md) and [doc 7](docs/07-objects.md), the data in `src/res/track` |
| The bike and its handling | THROTTLE, WHEELIE, LEFT, RIGHT, BRAKES; SPEED an 8.8 word in three bands (199 km/h the top); the lean a sideways speed against the bend's push; ramps tax SPEED by 3/4 unless the wheelie was held 8 passes; WHEELIE held at a landing saves the bounce; a fall and the walk back (GetUp) hold the timer ([doc 5](docs/05-controls.md), [doc 10](docs/10-gameplay-logic.md)) |
| Rivals and obstacles | six rider records on a ring of 256 rows: riders 0-3 and two trucks (rider 4 from stage 2, rider 5 from stage 4); a rider hit costs a quarter of SPEED and a bounce, a truck head-on a fall; eight object types (boulders, trees, conifers, rock spires, cacti, palms, bushes, ramps) with their collision sizes ([doc 7](docs/07-objects.md)) |
| Timer and score | the timer counts passes, 10 a timer second (about 80 frames); the score adds the km/h each pass, ten times in the air; the time bonus puts the timer's digits into the 100 000s and 10 000s (plus the last pass's speed points); TOP 1 000 000; five high scores with name and total time ([doc 8](docs/08-hud-and-text.md)) |
| Rendering | a back buffer at `$EB00-$FDFF` drawn each pass and copied by CopyBuffer against the beam; 128 road rows mapped to lines (RoadLines, the crest) and shifted (BendRows, the bend); roadside objects and riders scaled, byte-aligned near and shifted far; a horizon per stage rotated in the bends; GroundTexture from the ROM's bytes ([doc 6](docs/06-rendering.md)) |
| Engine | IM 2 with its own stack and a patched `JP` back; no `HALT`: a free-running pass of 8.0 frames on average; the stage 3 reset (two ramps close together throw the bike above the buffer's top and the row builder runs off its table); SpeedLock 2 on the tape, one load ([doc 2](docs/02-architecture.md), [doc 3](docs/03-build-and-load.md), [doc 4](docs/04-game-loop.md)) |
| Sound | two tunes from the interrupt (tune 1 on stages 1, 3, 5, tune 2 on 2 and 4) on the AY of a 128K, silent on a 48K; the engine on the beeper (48K) or AY tone (128K), picked by a ROM checksum; AY noise for falls, bounces and the skid; beeper beeps, the crash noise and the name entry's blip ([doc 9](docs/09-sound.md)) |
| Controls | five methods (KEYBOARD redefinable: Q A O P SPACE, H pause, R reset; KEMPSTON; SINCLAIR LEFT and RIGHT; CURSOR), patched into ReadControls; CAPS SHIFT + Q the cheat (a fixed track step on stages 1-3) ([doc 5](docs/05-controls.md)) |

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

## Sources and credits

- The game: Enduro Racer, Activision 1987 (ZXDB 1628); programmed by Giga Games (Alan Laird, Ian Morrison), graphics
  by Focus ("PROGRAMMED BY GIGA GAMES", "GRAPHICS BY FOCUS", "A SOFTWARE STUDIOS PRODUCTION" on its title screen); the
  arcade game by Sega (1986).
- The tape: the World of Spectrum mirror `games/e/EnduroRacer.tzx.zip`, the file in `orig/`; the TZX names no dumper.
  The recordings load TOSEC's `[SpeedLock 2]` dump, "Created with Ramsoft MakeTZX" (its text block), dumper not named.
- The POKE file: ZXDB, `work/candidates/`.

## Build

```bash
sh tools/build.sh [SJASMPLUS]          # builds the tape from src/ and compares it with orig/ byte for byte
python3 tools/res_formats.py check     # every resource against the bytes it stands for
```

The sources are written by `kit/mkgame.py` from the `.ann` files: the game `src/game/*.asm` from `src/game/game.ann`,
the loader `src/loader/` (`loader.json`, `tail.json`) and the BASIC `src/tape/` (`basic1.json`, `basic2.json`); the
resources are in `src/res/` (a README in every folder). The commands: `work/stage2/NOTES.md`.
