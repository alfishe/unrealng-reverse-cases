# Earth Shaker: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The case starts from ZXDB 1563 (Earth Shaker, Your Sinclair, 1990, Michael Batty). The game was never sold on its
own: it came on the Your Sinclair issue 63 covertape, so the original is that tape, `orig/YSIssue63-SixPack.tzx.zip`
from ZXDB's magazine folder (hashes in [README](README.md)). Its Side 1 holds Earth Shaker as TZX blocks 9-13.

Every other copy found locally (69 files: ZXDB, zxart, TOSEC 2020 and Knobchez 2026, the TOSEC MDR pack, Pardubak)
was copied unchanged into `work/candidates/<source>/` and compared with the two data blocks of the original by
`tools/media_compare.py` (block by block for tapes, the whole file for disks, `$6D42-$FFFF` for snapshots and the RZX
snapshots; `work/stage1/media-compare.txt`). Every TZX dump of the covertape and every cut-out copy holds the same
107-byte BASIC and the same 37 566-byte game block; the WoS TAP is a re-save (another BASIC and header names, the
same game block); the TR-DOS and Microdrive files are conversions, packed or relocated. The table is in the README.

The tape is plain: a BASIC loader and one CODE block, both at ROM speed, no loading screen
([doc 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)). `tools/image.py` builds the image as loaded
(`work/mkgame/original.bin`, the `case.json` image) from the side's blocks. One unreal-ng detail: its tape
catalogue lists the data blocks only, so the BASIC header that is TZX block 10 is catalogue block 7, the block
`tools/rs_capture.py` and `tools/lab.py` wind to (`/tape/seek`).

## 1. One recording from power-on

`c1` (`tools/rs_capture.py`, inputs `tests/inputs/c1.txt`, port base 37100): a 48K at power-on, the Side 1 TZX
inserted with the fast LD-BYTES trap and turbo off (`fast_tape` and `turbo_tape` PUT false, checked in
`/tape`), the TTD recording on from frame 0. With the recording on, the inserted tape appears in `/tape` only
after frames run, so the capture runs 200 frames first, then winds to catalogue block 7, types `LOAD ""`, plays
the tape and stops it at frame 11 800 (the side goes on with the Switchblade demo). The game's code runs first at
frame 11 225 (ROM speed; the first branch of `$6D42-$FFFF` in `c1/l1.json`): the menu. Then 3850 frames of input:
4 (joystick), 3 (keyboard), 2 and the five keys O P Q A M, 1 (start), ENTER at the password prompt (cave 1), play
with the keys, F (the map), H (quit the cave: a life lost), G (abort to the menu). `c1/screens.png` shows the menu,
cave 1, the intro screens with 5, 4 and 3 lives and the menu again. 15 650 frames, `c1/session.ttd`.

Interrupts, a first look (L1 of `c1`, `menu`, `lives`, `rzx-earth01`):

- IM 1 (`im 1`, I = `$3F` in the register reads of `rzx-earth01` at its end and of the replay probes; the only IM instruction that runs is the ROM's `IM 1` at `$122E`, at power-on and after 5 quits; the L1 lists hold no `ED 5E`), so the ROM's handler at `$0038` runs each frame while
  interrupts are on: it counts FRAMES and scans the keyboard (the RZX's port reads at PC `$0296` every frame).
- No HALT runs in any recording (the L1 instruction lists hold no `$76`; the `$76` bytes at `$9A22`, `$B7C5`,
  `$B7DD` and `$BF02` are graphics and never run), and no game code reads FRAMES (its reads equal the ROM
  handler's writes). The game never waits for the frame: a pass of the cave takes as long as its work.
- Interrupts go off only around sound: the tune player `$88CE` (DI at `$88CE`, `$88E2`, `$88F8`, EI at `$890E`
  when a key 1-5 ends the tune), the jingles and effects `$86AD-$86D1`, `$8702-$871A`, `$8736-$8757` (DI, the
  ROM's BEEPER `$03B5`, EI) and a few short ones (`$8DE3-$8DFD`, `$9072-$908F`, `$9207`, `$921A`, `$A713-$A749`,
  `$E740-$E77A`, `$E7A9-$E7E3`). So `rzx-earth01`'s 3803 frames took 2898 interrupts: the rest fell while a tune
  or a jingle held them off.
- The pass: the player's controls are read once a pass, the left key (or Kempston) at `$83C3`, right `$8437`, up
  `$84AD`, down `$84F9`, fire `$8759`, abort G `$93A8`, quit H `$872D`, each a self-modified
  `LD A,row; OUT ($FF),A; IN A,($FE); AND mask` whose row and mask the redefine menu writes. In the RZX archive's
  `earth01` the reads of `$83C3` come every 5 frames (247 passes), 6 (224), 7 (33) or 8 (5): a pass is 5 to 8
  frames of work in cave 1.

The pass in our own instance (`tools/passes.py`: 300 passes from one `$8759` to the next with `/skip_until`,
timed by `/video/beam`, no key held, from each state after its intro; `work/stage1/passes.json`):

| State | Median T a pass | Frames (median) | Heaviest pass | Frames |
| --- | --- | --- | --- | --- |
| cave 1 (`probe/level1.szx`) | 383 966 | 5.49 | 396 012 (pass 49) | 5.67 |
| cave 2 (`earth02` start) | 396 280 | 5.67 | 407 942 | 5.84 |
| cave 8 | 427 966 | 6.12 | 438 869 | 6.28 |
| cave 16 | 429 487 | 6.15 | 440 266 | 6.30 |
| cave 24 | 523 644 | 7.49 | 650 218 (pass 8) | 9.30 |
| cave 32 | 394 366 | 5.64 | 405 800 | 5.81 |

So a pass is 5.5 to 7.5 frames of work, more with more moving objects (cave 24 the slowest of these); the heaviest
pass measured is 9.3 frames, in cave 24. The spread of about 12 000 T between passes in one cave comes from the
interrupts that land in a pass and the objects that move.

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 The recordings

Every recording keeps its `session.ttd` in `work/stage1/<name>/`; the list with how each was made is in
`work/stage1/NOTES.md`.

| Recording | Start | Input | Frames | What it reaches |
| --- | --- | --- | --- | --- |
| `c1` | power-on, the tape at ROM speed | `tests/inputs/c1.txt` | 15 650 | the load, the menu, every menu key but 5, cave 1, the map, quit, abort |
| `menu` | `work/stage1/probe/after-load.szx` (the menu after `c1`'s load, ROM speed) | `tests/inputs/menu.txt` | 7915 | the title tune to its end, the hi-score table under the scroller, the menu again, 4, 3, 2 with the five keys, 5 (quit: `JP 0`, the ROM's copyright screen) |
| `lives` | the same | `tests/inputs/lives.txt` | 6975 | cave 1 and H again and again: five lives lost, the game over, the menu |
| `hiscore` | the RZX's `earth10` start snapshot (cave 10, score 009 835) | `tests/inputs/hiscore.txt` | 9688 | H until the lives are gone, the game over with the score, the hi-score entry (the table shows 009835 with the name "HH": the H presses after the last life went into the name), the table |
| `timer` | `probe/level1.szx` (cave 1 in play) | `tests/inputs/timer.txt` | 12 000 | F: the whole cave as a map; then no key: the time bar under the play window runs out and a life is lost (5 -> 4) |
| `rzx-earth01` | the RZX archive's `earth01.rzx` start snapshot (the menu) | `tests/inputs/rzx-earth01.txt` (`tools/rzx_align.py`) | 3803 | cave 1 played and finished by the RZX's player, cave 2's intro |
| `rzx-earth02` | `earth02` start snapshot | `tests/inputs/rzx-earth02.txt` | 7661 | cave 2 finished, cave 3's intro; score 002080, `$FD93` 5 |
| `rzx-earth03` | `earth03` start snapshot | `tests/inputs/rzx-earth03.txt` | 6395 | cave 3 finished, cave 4's intro; score 003412, `$FD93` 5 |
| `rzx-earth04` | `earth04` start snapshot | `tests/inputs/rzx-earth04.txt` | 6858 | cave 4 not finished: our replay parts from the RZX at frame 2344 and the player dies (`$FD8E` = `$FF`, lives 4 at the end); score 004355, `$FD93` 4 |
| `rzx-earth05` | `earth05` start snapshot | `tests/inputs/rzx-earth05.txt` | 8309 | cave 5 finished, cave 6's intro; score 006265, `$FD93` 5 |
| `rzx-earth06` | `earth06` start snapshot | `tests/inputs/rzx-earth06.txt` | 8283 | cave 6 finished, cave 7's intro; score 007116, `$FD93` 5 |
| `rzx-earth07` | `earth07` start snapshot | `tests/inputs/rzx-earth07.txt` | 8120 | cave 7 finished, cave 8's intro; score 008223, `$FD93` 5 |
| `rzx-earth08` | `earth08` start snapshot | `tests/inputs/rzx-earth08.txt` | 6892 | cave 8 finished, cave 9's intro; score 009190, `$FD93` 5 |
| `rzx-earth09` | `earth09` start snapshot | `tests/inputs/rzx-earth09.txt` | 6659 | cave 9 finished, cave 10's intro; score 009835, `$FD93` 6 |
| `rzx-earth10` | `earth10` start snapshot | `tests/inputs/rzx-earth10.txt` | 7530 | cave 10 finished, cave 11's intro; score 011091, `$FD93` 6 |
| `rzx-earth11` | `earth11` start snapshot | `tests/inputs/rzx-earth11.txt` | 7331 | cave 11 finished, cave 12's intro; score 012583, `$FD93` 6 |
| `rzx-earth12` | `earth12` start snapshot | `tests/inputs/rzx-earth12.txt` | 9351 | cave 12 finished, cave 13's intro; score 014043, `$FD93` 6 |
| `rzx-earth13` | `earth13` start snapshot | `tests/inputs/rzx-earth13.txt` | 3818 | cave 13 finished, cave 14's intro; score 014884, `$FD93` 6 |
| `rzx-earth14` | `earth14` start snapshot | `tests/inputs/rzx-earth14.txt` | 9244 | cave 14 finished, cave 15's intro; score 016488, `$FD93` 6 |
| `rzx-earth15` | `earth15` start snapshot | `tests/inputs/rzx-earth15.txt` | 9175 | cave 15 finished, cave 16's intro; score 017473, `$FD93` 7 |
| `rzx-earth16` | `earth16` start snapshot | `tests/inputs/rzx-earth16.txt` | 9728 | cave 16 finished, cave 17's intro; score 020425, `$FD93` 7 |
| `rzx-earth17` | `earth17` start snapshot | `tests/inputs/rzx-earth17.txt` | 5978 | cave 17 finished, cave 18's intro; score 021983, `$FD93` 7 |
| `rzx-earth18` | `earth18` start snapshot | `tests/inputs/rzx-earth18.txt` | 9517 | cave 18 finished, cave 19's intro; score 025514, `$FD93` 7 |
| `rzx-earth19` | `earth19` start snapshot | `tests/inputs/rzx-earth19.txt` | 6642 | cave 19 finished, cave 20's intro; score 026250, `$FD93` 8 |
| `rzx-earth20` | `earth20` start snapshot | `tests/inputs/rzx-earth20.txt` | 5728 | cave 20 finished, cave 21's intro; score 026936, `$FD93` 8 |
| `rzx-earth21` | `earth21` start snapshot | `tests/inputs/rzx-earth21.txt` | 7548 | cave 21 finished, cave 22's intro; score 027938, `$FD93` 8 |
| `rzx-earth22` | `earth22` start snapshot | `tests/inputs/rzx-earth22.txt` | 11551 | cave 22 finished, cave 23's intro; score 030219, `$FD93` 9 |
| `rzx-earth23` | `earth23` start snapshot | `tests/inputs/rzx-earth23.txt` | 8923 | cave 23 finished, cave 24's intro; score 031890, `$FD93` 9 |
| `rzx-earth24` | `earth24` start snapshot | `tests/inputs/rzx-earth24.txt` | 12620 | cave 24 finished, cave 25's intro; score 035238, `$FD93` 9 |
| `rzx-earth25` | `earth25` start snapshot | `tests/inputs/rzx-earth25.txt` | 10250 | cave 25 finished, cave 26's intro; score 037883, `$FD93` 9 |
| `rzx-earth26` | `earth26` start snapshot | `tests/inputs/rzx-earth26.txt` | 18581 | cave 26 finished, cave 27's intro; score 043900, `$FD93` 9 |
| `rzx-earth27` | `earth27` start snapshot | `tests/inputs/rzx-earth27.txt` | 6483 | cave 27 finished, cave 28's intro; score 044592, `$FD93` 9 |
| `rzx-earth28` | `earth28` start snapshot | `tests/inputs/rzx-earth28.txt` | 9773 | cave 28 finished, cave 29's intro; score 047343, `$FD93` 9 |
| `rzx-earth29` | `earth29` start snapshot | `tests/inputs/rzx-earth29.txt` | 14620 | cave 29 finished, cave 30's intro; score 050251, `$FD93` 9 |
| `rzx-earth30` | `earth30` start snapshot | `tests/inputs/rzx-earth30.txt` | 6154 | cave 30 finished, cave 31's intro; score 051525, `$FD93` 9 |
| `rzx-earth31` | `earth31` start snapshot | `tests/inputs/rzx-earth31.txt` | 10024 | cave 31 finished, cave 32's intro; score 054296, `$FD93` 9 |
| `rzx-earth32` | `earth32` start snapshot | `tests/inputs/rzx-earth32.txt` | 20931 | the win screen ("WELL DONE ... AND THANKS !"); score 061941, `$FD93` 9 |

The `rzx-earthNN` recordings replay someone else's play (the RZX archive, said so in the README): SkoolKit plays
each RZX and logs every port read and the state `$FD7E-$FFFF` each frame (`tools/rzx_inputs.py`); our instance then
runs one frame a call from the RZX's start snapshot with the keys of the RZX frame it matches, the state compared
each frame (`tools/rzx_align.py`; 31 of 32 caves match to the RZX's last frame, offsets of a frame or two where the
pass timing differs); the script has one line a frame so the capture splits the run the same way. No byte of the
image is patched; the RZX snapshots' key tests read the Kempston port because the RZX's player chose menu 4.
Cave 4 is the exception (NOTES.md): the next cave starts from its own RZX snapshot.

Not reached yet: a death by a falling boulder or a hazard in our own play (the lives at each cave's end never drop in the RZX's play of caves
1-32; `rzx-earth04`'s divergence ends in a death not yet classified), the jingles of each event separated, every
object's rule (doc 7 needs a recording per object).

### 6.1 The screens

The front end, cave 1, the map, the time running out, the game over and the hi-score entry (`tools/fig_play.py`,
each named with its recording and frame; one PNG each in `docs/img/play/`):

![Front-end screens](docs/img/play/front.png)

Every cave in play, half way through its `rzx-earthNN` recording, and the win screen at the end of `rzx-earth32`:

![The 32 caves in play and the win](docs/img/play/caves.png)

The caves drawn whole from their data are in [doc 2.3](docs/02-architecture.md#23-the-cells-and-their-graphics).

## 7. Review
