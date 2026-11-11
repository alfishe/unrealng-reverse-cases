# Battle Command (Ocean Software, 1990)

State: in progress (stage 1, the capture).

| | |
| --- | --- |
| Machine | 128K only: ZXDB marks every tape 128K, the instructions name "Spectrum Tape +2/+3", and on a 48K the whole side 1 loads (the countdown reaches `0:02`) and the machine then restarts to the Sinclair copyright screen ([WALKTHROUGH 0.4](WALKTHROUGH.md#04-the-machine-128k-only)) |
| Profile (AGENTS.md 4.0) | [below](#profile) |
| Authors | Realtime Games Software for Ocean: Stephen Hey (Spectrum and Amstrad programming), Jonathan Dunn (music), D.C. Ward (producer), from the tape's instructions (`work/candidates/docs/BattleCommand.txt`, "CREDITS"); the AY rip says "Jonathan Dunn", "(c) 1991 Ocean Software Ltd", "Battle Command - Title (AY)" |
| Release | ZXDB 451: Ocean Software, 1990, a conversion of Realtime Games' Battle Command (Amiga, Atari ST); a two-sided tape (side 1 the program under SpeedLock 7, side 2 the mission tape); the Spanish re-release by Erbe Software (ZXDB release 1, 1991, D.L. M-26221-1991) |
| Original | `orig/BattleCommand.tzx.zip` (md5 `aa17a5185270dd247402ceac934db00d`, SHA-1 `fe75a9844897e79e1872a66c7c844755d067ef06`), ZXDB download 3059, protection "SpeedLock 7": `Battle Command - Side 1.tzx` (94 326 bytes, md5 `468d9bf8dfca1e5f907dce08d4f42e47`, SHA-1 `ffd14789942d0185d11a3e52b3c9dae085c97069`) and `Battle Command - Side 2.tzx` (78 235 bytes, md5 `51e87ff5d2d059df02d633998b71a6af`, SHA-1 `273762faf36482914651d90a46b50750605df872`), both "Created with Ramsoft MakeTZX". Side 1: a 4917-byte BASIC whose line 0 runs machine code in the program, two SpeedLock pulse blocks (194 bytes, then 6142 bytes) and 15 more data blocks at the SpeedLock speed, each after a 1-byte mark; side 2: the mission catalogue `DIRECTORY:` and ten missions, each a 17-byte `MISSHDR:n:` block and its data, all at ROM speed ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Profile

Picked in phase 0 from the first recordings (AGENTS.md 4.0). Each item is a lead until a stage proves it.

| Row | What applies here |
| --- | --- |
| Genre: 3D (vector, filled) | a 3D vehicle combat game: one Mauler tank driven in first person through a filled-polygon landscape (sky, ground, hills, buildings, enemy vehicles and aircraft), the view in the upper half of the screen above a cockpit panel ([WALKTHROUGH 6.1](WALKTHROUGH.md#61-screens)). The writers need the projection worked through on one object, the clipping, the polygon fill (dithered patterns), every model drawn from its data (the title's tank, the 13 stores spinning on the stores screen, the targets), the camera (normal, night sight, binoculars with zoom, rear view, the Dragonfly missile's view) and the frame rate against the scene load |
| Genre: strategy, mission game | ten missions on side 2 (Blast Em Mission, Missile Battery, Hostage Rescue, Railway Ambush, Night Moves, Escort Duty, Satellite Search, River Raid, Hideout, Grand Finale), each with briefing notes, a goal, a map (roads, rivers, the pickup point P, the target T) and a mission clock; a stores screen fits four weapon modules out of 13 stores under a 1000 kg payload; a save code (STATUS, then LOAD GAME). The writers need each mission's world drawn from its data as a map, the goals and the rules as code, the enemies' AI |
| Engine: multi-load, 128K paging | side 1 fills the 128K banks (the loader writes `$7FFD`); side 2 is read by the game: the catalogue once, then one mission block per SEARCH and SELECT ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)). Each load is a stage, with what stays resident and the memory map per stage ([doc 2](docs/02-architecture.md)) |
| Engine: copy protection (SpeedLock 7) | the BASIC's machine-code stage, the two pulse blocks and the 15 data blocks with their marks (data pulses 714 / 1428 T, marks 875 / 1750 T); every decryption with the full transform set is stage 2's |
| Rendering: filled 3D view over a fixed panel | the view rows above the fixed cockpit (weapon slots, message screen, radar, compass, damage lights); the writers need the draw order against the beam (a back buffer or direct), the dither patterns, the attributes (cyan sky, green ground) |
| Sound: AY tracker | Jonathan Dunn's title tune (the rip says "Title"), AY effects in play; the format, the player, the register chart and every tune exported |

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
while its own `MISSHDR:2:` block says `$1906` = 6406 bytes; Erbe and the crack carry 6406. The first 3488 bytes agree,
the rest differs. The game does not take the Ocean block: SELECT reads it and the catalogue screen stays for 6000
frames with no stores screen, while the Erbe block loads and plays (recordings m2ocean and m2erbe,
[WALKTHROUGH 0.2](WALKTHROUGH.md#02-the-release-check)). Grand Finale (mission 10) is found by SEARCH but SELECT
returns to the status screen with no missions completed: likely locked until the other nine are done.

The original is the Ocean tape: ZXDB marks it the original release with SpeedLock 7, its side 1 carries the protected
loader that every other copy removes, and every other tape is the same program re-saved without protection (Erbe),
cracked (the TAP and its TZX), a demo or a snapshot.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

Not yet: the source and the tape rebuild are stage 2 and later.
