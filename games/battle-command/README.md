# Battle Command (Ocean Software, 1990)

State: complete 2026-11-11 (12 documents, 62 PNG figures, 100 mermaid diagrams, 30 animations, 15 WAVs and the title tune as MP3; counted on 2026-11-11).

| | |
| --- | --- |
| Machine | 128K only: ZXDB marks every tape 128K, the instructions name "Spectrum Tape +2/+3", and on a 48K the whole side 1 loads (the countdown reaches `0:02`) and the machine then restarts to the Sinclair copyright screen ([WALKTHROUGH 0.4](WALKTHROUGH.md#04-the-machine-128k-only)) |
| Profile (AGENTS.md 4.0) | [below](#profile) |
| Authors | Realtime Games Software for Ocean: Stephen Hey (Spectrum and Amstrad programming), Jonathan Dunn (music), D.C. Ward (producer), from the tape's instructions (`work/candidates/docs/BattleCommand.txt`, "CREDITS"); the AY rip says "Jonathan Dunn", "(c) 1991 Ocean Software Ltd", "Battle Command - Title (AY)" |
| Release | ZXDB 451: Ocean Software, 1990, a conversion of Realtime Games' Battle Command (Amiga, Atari ST); a two-sided tape (side 1 the program under SpeedLock 7, side 2 the mission tape); the Spanish re-release by Erbe Software (ZXDB release 1, 1991, D.L. M-26221-1991) |
| Original | `orig/BattleCommand.tzx.zip` (md5 `aa17a5185270dd247402ceac934db00d`, SHA-1 `fe75a9844897e79e1872a66c7c844755d067ef06`), ZXDB download 3059, protection "SpeedLock 7": `Battle Command - Side 1.tzx` (94 326 bytes, md5 `468d9bf8dfca1e5f907dce08d4f42e47`, SHA-1 `ffd14789942d0185d11a3e52b3c9dae085c97069`) and `Battle Command - Side 2.tzx` (78 235 bytes, md5 `51e87ff5d2d059df02d633998b71a6af`, SHA-1 `273762faf36482914651d90a46b50750605df872`), both "Created with Ramsoft MakeTZX". Side 1: a 4917-byte BASIC whose line 0 runs machine code in the program, two SpeedLock pulse blocks (196 bytes, then the 6144-byte bitmap) and 15 more data blocks at the SpeedLock speed, each after a 21-bit mark; side 2: the mission catalogue `DIRECTORY:` and ten missions, each a 17-byte `MISSHDR:n:` block and its data, all at ROM speed ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Profile

Picked in phase 0 from the first recordings (AGENTS.md 4.0), then settled by stage 2 and the documents.

| Row | What applies here |
| --- | --- |
| Genre: 3D (vector, filled) | one Mauler tank driven in first person through a filled-polygon landscape, the view above a cockpit panel. A pass (one picture) clears the back buffer, sorts the visible objects into a depth tree, runs each model's script (RunScript `$990F`: box generators, a vertex program, projection by logarithms, face tests, clipped fills in dithered patterns), and a blit in the interrupt copies it to the screen against the beam ([doc 6](docs/06-rendering.md)). The cost per view, in frames a pass: 7.5 in the front view of mission 1, 6.8 with the binoculars and the zoom, 8.0 in the Dragonfly's flight view, 12 in the rear view, 11.1 in the 3D view with the rear view left on ([doc 4, 4.6](docs/04-game-loop.md#46-frames-per-pass-in-every-view)); each face on the screen costs about 0.4 of a frame |
| Genre: strategy, mission game | ten missions on side 2, each a block loaded to bank 0 `$DBC5` with its world, objects, templates, models and its own code; each has a goal hook (header word `$DBE1`) that the pass calls from `$6A66` and that sets the goal flag `$68E8` (the ten hooks in [doc 10, 10.9](docs/10-gameplay-logic.md#109-goals-the-helicarrier-and-completion)). With the goal met, the key H calls the Helicarrier: it arrives and lands on the pad, and the tank's pickup ends the mission (recorded: m1complete, m4complete). Failure causes: the armour (UNIT DESTROYED, or FAILED TO MAKE PICKUP after the goal), desertion beyond the extent + 4, fuel, the bridge, the Helicarrier hit before the goal; one pointer `$7BF9` holds the text ([doc 10, 10.10](docs/10-gameplay-logic.md#1010-failure-and-its-causes)). The Grand Finale loads only when the nine flags `$6799-$67A1` are all set (LoadMissionIfAllowed `$759A`); missions 1-9 in any order, each once. The save code holds the score and the ten flags |
| Engine: multi-load, 128K paging | eight 16 KB banks: 5 and 2 fixed at `$4000` / `$8000`, the game's bank 0 at `$C000`, and banks 3 (raster), 4 (music), 6 (menus, stores, password, map) and 7 (pictures) paged in through one block in bank 5 `$7225-$72F3` ([doc 2](docs/02-architecture.md)). Side 2 is read by the game: the catalogue once, then one mission block per SELECT |
| Engine: copy protection (SpeedLock 7) | the BASIC's tail is a 103-layer decryption chain keyed by R (69 add, 22 dec, 12 sub layers), then the SpeedLock 7 loader with its timing marks between the blocks and its store cipher `(L XOR k) + a`, the keys rewritten by blocks 17 and 19 ([doc 3](docs/03-build-and-load.md)); the build re-protects the tape byte for byte |
| Timing: interrupts lost | the game never halts; the interrupt does the blit, the sound, the music, the clock and the input. The back-buffer clear, the radar's clear and OpVertexProgram run with interrupts off (`SP` used as a pointer), so 4 % of the interrupts are lost in the front view and 13 % in the rear view, and the mission clock, counted in interrupts taken, runs slow ([doc 4, 4.3](docs/04-game-loop.md#43-where-interrupts-are-off-and-the-interrupts-lost)) |
| Controls: the mouse reset | five readers (Sinclair, cursor keys, keyboard, Kempston joystick, Kempston mouse); the Kempston mouse never moves the pointer (ReadMouse writes its X delta over the new Y), and its reader's stores damage the 3D code until the game jumps into the middle of an instruction at `$7E79` and an `RST 0` restarts the machine: the game's own bug, not the emulator's ([doc 5, 5.5](docs/05-controls.md#55-the-kempston-mouse-no-movement-then-a-restart)) |
| Rendering: filled 3D view over a fixed panel | the back buffer `$8AF1-$96F0`, four blits (front, low, wide, narrow), the HUD fields written by their own routines, bank 7's packed pictures unpacked behind a black shadow screen ([doc 6](docs/06-rendering.md), [doc 8](docs/08-hud-and-text.md)) |
| Sound: AY, two drivers | the effect driver of the game (a register shadow, effect counters, the engine as an envelope) and the bank 4 tracker player of Jonathan Dunn's title tune, on one chip ([doc 9](docs/09-sound.md)) |

## Other releases and copies

Every copy found was copied unchanged into `work/candidates/<source>/` and compared block by block with the original
([WALKTHROUGH 0.2](WALKTHROUGH.md#02-the-release-check)): the ZXDB downloads, the NVG mirror, the TOSEC 2020-02-18
set. The local collection keeps its files on the `WDC14Tb-3` share, which was not mounted in this session (the
mount was refused), so the same files were fetched from their public URLs and matched to the collection's indexes
by SHA-256 (`software/zxdb/manifest.tsv`, `index/tape-images.tsv`, `index/members.tsv`).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| `zxdb/BattleCommand.tzx.zip` (ZXDB 3059); zxart `(EN)(128K, KM)(Tape 1 of 2, Side 1).tzx` and `(Tape 2 of 2, Side 2).tzx`; WoS `games.zip` (same md5s in the index) | the original Ocean tape | the file in `orig/` |
| `zxdb/BattleCommand(ErbeSoftwareS.A.).tzx.zip` (ZXDB 3061); zxart `[a 1991 Erbe Software S.A.]` | the Spanish re-release | side 1 without protection: a 123-byte BASIC "Battle C.", a 512-byte `loader` at `$B800`, the screen and seven headerless ROM-speed blocks (9472, 16 384, 16 384, 5120, 3584, 14 848, 16 384 bytes); side 2 equals the Ocean side 2 block for block except mission 2 (below) |
| `zxdb/BattleCommand.tap.zip` (ZXDB 3060) = `nvg-tapes/battle_command.zip` (md5 `6f33521e7c14c029049b75e5edda0c82`, 1993) | a crack, BASIC "BATTCOMMND" | both sides on one tape under standard headers: the screen `bcom$`, `bcomc0` (31 999 bytes at `$8301`), `bcomc1`-`bcomc5` (at `$C000`, one a bank), `bcomdi` (128 bytes at `$8617`), the catalogue `bcom-K` (`$CB64`) and the missions `bcom-A`-`bcom-J` (`$DBC5`); the catalogue and the missions equal the Erbe side 2 byte for byte |
| TOSEC `Battle Command (1991)(Ocean)(128K).tzx` (md5 `73149dcb585441a0bb99457ae0493eed`) | the crack as a TZX | the TAP's 40 blocks, 1000 ms pauses and stop marks between the missions |
| `nvg-snaps/battleco.zip` `BATTLECO.Z80` (128K, 1994) | a snapshot of the game | compared with the images in [WALKTHROUGH 0.2](WALKTHROUGH.md#02-the-release-check) |
| `nvg-demo/btcom128.zip` = TOSEC `Battle Command (demo) (1990)(Ocean - Sinclair User)(128K)[a].tzx` (md5 `6b60a1557666df8251e1b129c0c9ce70`) | the Sinclair User cover-tape demo | another program: a 128-byte BASIC "Bat 128", a 512-byte loader at `$8000`, six turbo blocks (TZX id `$11`, one-bit 1127 T) |
| `nvg-demo/bctank.zip` = `zxdb-demo/BattleCommandRealtime3DTankSimulator.z80.zip` (`BCTANK.Z80`, md5 `bc68f15320a57ac176f36cf27e2da904`) | ZXDB 7267, "Battle Command Realtime 3D Tank Simulator", a 128K demo snapshot | another entry; not compared |
| zxart `(EN)(KM)[h LAKS].scl`, `(demo)(EN).scl`, `(demo)(EN)[a Vasilyev Anton].scl`, `Battle Command Crack Intro` | TR-DOS conversions and a crack intro (zxart index only) | not copied: they sit on the unmounted share and are conversions |
| `docs/Battle Command (1990)(Ocean Software).pok` | the POKE file | nine cheats, checked against the code in [WALKTHROUGH 6.3](WALKTHROUGH.md#63-the-state-variables-and-the-pokes) |

**Side 2, mission 2.** The Ocean side 2 stores Missile Battery as a 6386-byte block (6384 data bytes, XOR check 0),
while its own `MISSHDR:2:` block says `$1906` = 6406 bytes; Erbe and the crack carry 6406. The first 3487 bytes agree,
the rest differs. The game does not take the Ocean block: SELECT reads it and the catalogue screen stays for 6000
frames with no stores screen, while the Erbe block loads and plays (recordings m2ocean and m2erbe,
[WALKTHROUGH 0.2](WALKTHROUGH.md#02-the-release-check)). Grand Finale (mission 10) is found by SEARCH but SELECT
leaves the catalogue on screen with no missions completed: it is locked until the other nine are done
([doc 10, 10.11](docs/10-gameplay-logic.md#1011-the-grand-finale)).

The original is the Ocean tape: ZXDB marks it the original release with SpeedLock 7, its side 1 carries the protected
loader that every other copy removes, and every other tape is the same program re-saved without protection (Erbe),
cracked (the TAP and its TZX), a demo or a snapshot.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```sh
source work/env.sh                                  # SJASMPLUS, SKOOLKIT_VENV
sh tools/mkasm_all.sh                               # the .ann files to the sources (kit/mkgame.py, every part)
rm -rf build && sh tools/build.sh $SJASMPLUS        # both sides, compared with the original
python3 tools/res_formats.py check                  # every resource builds to its original bytes
```

`tools/build.sh` prints `BattleCommand-Side1.tzx identical` and `BattleCommand-Side2.tzx identical`: both tape
sides are rebuilt byte for byte from `src/` (the game, the bank parts, the loader and its chain, the mission blocks
from `src/res/missions`). The editable resources are in [src/res](src/res/README.md).
