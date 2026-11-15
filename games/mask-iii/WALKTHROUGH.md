# MASK III: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The release check ([README, Other releases and copies](README.md#other-releases-and-copies)):

1. `tools/fetch_copies.py` greps the collection index (`index/zx-image-locations.tsv`) for the title and copies every
   hit unchanged into `work/candidates/<source>/`, checking its SHA-256 (55 copies: ZXDB, TOSEC, zxart, VTRD, the RZX
   archive, the AY rip, the POKE file; `work/stage1/fetch-copies.txt`).
2. `tools/media_compare.py` compares the data blocks of every tape with the ZXDB TZX and with the IBSA dump
   (`work/stage1/copy-compare.txt`). Two builds come out: build A (Gremlin's own tape, the Space Ace compilation,
   the 128K crack, most TR-DOS conversions) and build B (IBSA and Erbe, the 48K TAP), whose code is shifted from
   offset 3042 and whose 128K block differs in 101 bytes.
3. The original is the ZXDB TZX of build A, a Ramsoft dump of the Gremlin tape: `orig/MASKIII-VENOMStrikesBack.tzx.zip`,
   copied unchanged. ZXDB's POKEs fit build A, and the ZXDB AY rip holds its 128K block byte for byte (at offset
   296).

The tape, block by block, the BASIC and the loader: [doc 3](docs/03-build-and-load.md). No turbo, no protection, no
multiload: five ROM-speed blocks, the last only on a 128K.

A public disassembly of the game exists on GitHub (Bedazzle/Mask-3-Venom); it was not opened or used. The ZXDB RZX
run (`work/candidates/zxdb/mask3.rzx`, 37 200 frames) is another player's; it is used to reach the rooms (6.0) and is
a witness only where said.

## 1. One recording from power-on

`c1` (`tools/capture.py --media A --model 128K --inputs tests/inputs/c1.txt --record-load`): power-on on the 128K,
the 128 menu's Tape Loader, the original tape at ROM speed (the fast LD-BYTES trap and turbo tape off), 22 300 frames
(17 500 for the load, then the 4800 frames of `c1.txt`), `session.ttd` 13.9 MB.

| Frame (c1, ROM-speed load) | What | Call |
| --- | --- | --- |
| 53 | the ROM's `$5B00` | `kit/rs.py stages` |
| 1094 T 37 200 | the loader at `$FF00`, then its copy at `$5E00` | `stages` |
| 15 019 T 60 034 | the game's entry `$9100` | `stages`; `tools/ttd_dump.py` the memory there |
| 15 021 | the `JR` at `$FFFF`, the handler `$9226` entered through it | `stages` |
| 17 750 | the menu (screen `docs/img/play/c1-17750-menu.png`) | the capture's screens |
| 18 250 | room 0, Matt in the teleport pod | the screens |

The memory at the entry equals the tape blocks: `$6000-$FDFF` = block 6 byte for byte, RAM 4 `$C000-$CF9F` = block 7,
`$FFFE` = 0, ROM 1 paged ([doc 2, 2.1](docs/02-architecture.md#21-the-machine-budget-and-the-images)).

### Interrupts and timing

The entry `$9100` (`DI`) copies the parked zone set's first part (2.1), sets `R` = `$FF`, `SP` = `$FFF0`, `I` = `$FE`,
fills `$FE00-$FF00` with `$FF`, writes `$18` (`JR`) at `$FFFF` and `JP $9226` at `$FFF4`, and sets `IM 2`. An
interrupt with `$FF` on the bus reads its vector at `$FEFF-$FF00`, `$FF` `$FF` (the table runs to `$FF00`, so any bus value gives the same), and jumps to `$FFFF`; there `$18` (`JR`) takes its offset from `$0000`, the ROM's `DI` = `$F3`, and lands at `$FFF4`: `JP $9226`. (`$0000` is `$F3` in both 128K ROMs and the 48K ROM, so the trick does not depend on the ROM paged.)

`kit/rs.py interrupts --work work/stage1/c1`: IM 2 `$FFFF` → `$9226`, 7279 entries in the 22 300 frames (one a frame
from frame 15 021), 30 032 T an entry, 13.8 % of the CPU over the whole recording (the load included). The handler
`$9226`:

1. pushes every register, `INC ($9224)` (a frame counter), sets the border from `$9225`;
2. in the menu (`$970E` not 0) calls `$9899`, in play `$BB4C` (the keys);
3. on a 128K (`$FFFE` = 0): pages RAM 4 (`$7FFD` = `$14`), calls `$C000` if `$9222` asks for a tune, `$C00A` for
   `$9223`, then `$946F`, `$9421` and `$C003` (the AY player, every frame), and pages RAM 0 back (`$10`);
   on a 48K: `$949F` and `$94C8`, the beeper;
4. calls `$AF82` when `$970D` is 0, and returns with `EI`.

Callees in c1: `$9421`, `$946F`, `$C003` x7279; `$BB4C` x4031; `$AF82` x3955; `$9899` x3248; `$C000` x2; `$C00A` x1.
In the RZX segments the beeper path runs instead: the RZX's memory has `$FFFE` = 1 (its player used a 48K or a
machine the test missed), and `rs.py interrupts --work work/stage1/rec/rzx-16000` gives 3999 entries in 4000 frames,
2600 T an entry, 3.7 % of the CPU, callees `$949F`, `$94C8`, `$AF82`, `$BB4C` each x3999. So the AY player costs about
27 000 T a frame on the 128K, the beeper's 2600 T on the 48K.

`DI` / `EI`: `DI` at the entry and around `$A198` (the zone swap, `$A19D`-`$A1EA` with `EI`), at `$915B` (the new-game
set-up, `EI` at `$9161`), `$9A15`, `$9B18`, `$9EA9`; `EI` at `$CBFC` (the game start). `HALT` only in the menu
(`$9780`, `$9852`), the screen wipe `$A049` and the message pauses `$BB1E-$BB34`.

The main loop `$CC03-$CC59` runs free beside the interrupt (no `HALT`): twelve calls, then `INC ($AF0C)`, the BCD
count `$CC5C`, `JP $CC03` ([doc 2, 2.6](docs/02-architecture.md#26-the-frame-and-the-main-loop)). Frames per pass,
measured:

| Window | Passes | Frames a pass |
| --- | ---: | ---: |
| the RZX, 63 windows of 500 frames in play (`$AF0C` every 500 frames of `work/stage1/rzx/dump`) | median 181 | 2.8 (2.0 to 4.6) |
| `rec/rzx-16000`, 4000 frames, all in step with the RZX (the count of `$CC03` in its L1) | 1600 | 2.5 |
| `rec/rzx-28000`, 4000 frames (a game over and a new game in it) | 736 | 5.4 |
| `rec/menu`, 9565 frames (menu, then 6000 frames standing in the pod) | 2488 | 3.8 |

The heaviest code in play: the room buffer's scan loop `$A1FE-$A200` (`OR (HL)`, `DEC HL`, `JP Z`; 7.6 % of all
T-states in `rec/rzx-16000`, 928 000 runs), then the beeper's wait `$94FC-$94FD` (2.0 %), the object draw `$A5CA-$A637`
and `$A735-$A75E`. The heaviest frames are those of a room change: `$A89D` draws the room into the buffer (4 x 4
characters for each of 40 blocks) and the next pass copies all of it; a per-frame trace of one change is for stage 2.

## 2. Static pass over the medium

`tools/tzxblocks.py list`, the BASIC, the loader: [doc 3](docs/03-build-and-load.md). `work/stage1/dis.skool` is a
plain `sna2skool` listing of block 6 at `$6000`, the reading copy for stage 1.

## 3. The stages and the packers

No packer. The stages: power-on, the BASIC, the loader at `$FF00` → `$5E00`, the game at `$9100` (doc 3, 3.4).

## 4. The medium from source

Stage 2.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 The recordings

Every recording keeps its `session.ttd` in its folder under `work/stage1/`.

| Recording | Made with | Frames | What it reached |
| --- | --- | ---: | --- |
| `c1` | `tools/capture.py --work work/stage1/c1 --media A --model 128K --inputs tests/inputs/c1.txt --record-load`: power-on, the original at ROM speed | 22 300 | the load, the menu, K DEFINE KEYS, 4 KEYBOARD, start, room 0: Matt walks, jumps, fires, takes the BL mask, the masks 1-4, H pause |
| `rec/menu` | `tools/capture.py --work work/stage1/rec/menu --snapshot work/stage1/probe/128K/loaded.szx --inputs tests/inputs/menu.txt` (the snapshot: the original loaded with the LD-BYTES trap on the 128K, the menu up) | 9565 | 1 KEMPSTON, 2 INTERFACE 2, 3 CURSOR (the chosen icon lit), K DEFINE KEYS ("PRESS FIRE", "PRESS UP", ...), P ENTER PASSWORD (16 places, "MASK" typed, ENTER: back to the menu), 4, start; 6000 frames with no key: Matt stays in the pod and nothing reaches him |
| `rec/rzx-00000` .. `rec/rzx-32000` | `tools/rzx_segment.sh FROM FROM+4000`: `kit/rzx_dump.py` writes the RZX's state at frame FROM (`snap-FROM.z80`), `tools/rzx_script.py` its keys for frames FROM..FROM+3999 (`tests/inputs/rzx-FROM.txt`), `capture.py --snapshot` replays them, `kit/rzx_match.py` compares the screens with the RZX's | 4000 each | the RZX's rooms from its own state at each start (below) |
| `rec/rzx-36000` | the same, frames 36 000-37 199 (the RZX's end) | 1200 | the RZX's last room 15, the ending and the menu |

The segments stay in step with the RZX (screens within 1500 bytes) for 500 to 4000 frames, then drift: the RZX's
player used the Interface 2 stick and the game's frame (a free main loop beside the interrupt, 2.8 frames a pass) does
not land the same keys on the same pass after a few hundred frames. Each segment still starts on the RZX's own state,
so together they reach every room; after the drift the play is the RZX's keys on a slightly different game, and in
some segments Matt dies and a new game starts.

| Segment | In step to | Rooms (from `$950A` in the RZX dump) | Also reached |
| --- | ---: | --- | --- |
| `rzx-00000` | 4000 | 0, the pod, 10 | the teleport effect |
| `rzx-04000` | 1500 | 10, 1 | |
| `rzx-08000` | 1000 | 2 | energy out, MISSION TERMINATED, the menu with the new HISCORE, a new game |
| `rzx-12000` | 3000 | 11, 4, 12 | the caverns, the lava guns, the pod effect |
| `rzx-16000` | 4000 | 12, 5 | |
| `rzx-20000` | 2000 | 6, 3 | |
| `rzx-24000` | 1500 | 3, 13 | |
| `rzx-28000` | 500 | 8, 7 | the moon, MISSION TERMINATED, a new game |
| `rzx-32000` | 1000 | 14, 9 | the menu with HISCORE 00019090 |
| `rzx-36000` | 1000 | 15 | the ending: "YOU HAVE FOUND SCOTT......" at frame 250 (RZX 36 250), then the menu |

The ending is reached in `rec/rzx-36000`: room 15's last screen (`$A89D` jumps to `$ADF6` there) and "YOU HAVE FOUND
SCOTT......", with 31 004 points, then the menu (its HISCORE shows 00000000). Not reached by a recording of ours yet: the password's effect (no password known), the Kempston and Cursor controls in play, every mask's use, the 48K's beeper
music on a 48K model (the RZX segments run the beeper path on the 128K).

### 6.1 The screens

The menu and its options ([doc 5](docs/05-controls.md) in stage 2):

- `c1` frame 17 750, the menu after the load: ![c1 frame 17750](docs/img/play/c1-17750-menu.png)
- `rec/menu` frame 750, 3 CURSOR chosen (its icon lit): ![rec/menu frame 750](docs/img/play/menu-0750-cursor-chosen.png)
- `rec/menu` frame 1250, K DEFINE KEYS asking for fire: ![rec/menu frame 1250](docs/img/play/menu-1250-define-keys.png)
- `rec/menu` frame 2750, P ENTER PASSWORD with "MASK" typed: ![rec/menu frame 2750](docs/img/play/menu-2750-password.png)

Play:

- `c1` frame 18 250, room 0 at the start, Matt in the pod: ![c1 frame 18250](docs/img/play/c1-18250-room0-start.png)
- `rec/rzx-00000` frame 500 (RZX 500), room 0 further right: ![rzx-00000 frame 500](docs/img/play/rzx-00000-0500-room0-bridge.png)
- `rec/rzx-00000` frame 1500 (RZX 1500), the pod's transfer between rooms: ![rzx-00000 frame 1500](docs/img/play/rzx-00000-1500-teleport.png)
- `rec/rzx-00000` frame 1750 (RZX 1750), room 10, the base: ![rzx-00000 frame 1750](docs/img/play/rzx-00000-1750-room10.png)
- `rec/rzx-12000` frame 250 (RZX 12 250), the caverns: ![rzx-12000 frame 250](docs/img/play/rzx-12000-0250-cavern.png)
- `rec/rzx-12000` frame 750, the caverns' lava and guns: ![rzx-12000 frame 750](docs/img/play/rzx-12000-0750-cavern-lava.png)
- `rec/rzx-12000` frame 1750, room 12, the base: ![rzx-12000 frame 1750](docs/img/play/rzx-12000-1750-room12.png)
- `rec/rzx-12000` frame 2750, the pod effect drawn over the screen: ![rzx-12000 frame 2750](docs/img/play/rzx-12000-2750-pod-effect.png)
- `rec/rzx-28000` frame 250, the moon: ![rzx-28000 frame 250](docs/img/play/rzx-28000-0250-moon.png)

The end of a game:

- `rec/rzx-36000` frame 250 (RZX 36 250), the ending: ![rzx-36000 frame 250](docs/img/play/rzx-36000-0250-found-scott.png)
- `rec/rzx-08000` frame 1000, the energy bar empty: ![rzx-08000 frame 1000](docs/img/play/rzx-08000-1000-energy-out.png)
- `rec/rzx-28000` frame 500, MISSION TERMINATED: ![rzx-28000 frame 500](docs/img/play/rzx-28000-0500-mission-terminated.png)
- `rec/rzx-32000` frame 750, the menu after a game with the HISCORE: ![rzx-32000 frame 750](docs/img/play/rzx-32000-0750-menu-hiscore.png)

### 6.2 The images and the state

[Doc 2, 2.1 and 2.4](docs/02-architecture.md#21-the-machine-budget-and-the-images): the image as loaded is the code at
the entry byte for byte; in play only the zone sets, the buffers, the IM 2 table and variables change. The state
variables were found by sampling the RZX's memory every 500 frames (`work/stage1/rzx/dump/mem.bin`) and reading the
code that writes them.

### 6.3 The first map and the sprites

[Doc 2, 2.5](docs/02-architecture.md#25-the-rooms-as-data-the-first-map): the room table at `$953B`, the maps at
`$7600`, the blocks at `$8500`, the zone sets swapped by `$A198`; `tools/roommap.py` draws all 16 rooms from these
bytes; `tools/spritesheet.py` the sprites at `$CD60`.

## 7. Review
