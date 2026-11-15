# Rex: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The case starts from ZXDB 4129 (Rex, aka Zenith, Martech Games, 1988; The Light: Neil Harris, John Anderson, Richard
Allen). ZXDB lists the Martech tape, the Winner, Erbe and EDOS re-releases, two TAPs, a +3 disk, the Your Sinclair
covertape demo, a POKE file and the instructions; the RZX archive holds `rex.zip` (two runs). The original is
`orig/Rex.tzx.zip` from ZXDB's `pub/sinclair/games/r/` (release 0, hashes in the [README](README.md)).

The release check (`tools/media_compare.py`, `work/stage1/media-compare.txt`): the Winner TZX and TOSEC's "(Side A)",
"(Side B)" and "(Winner)" files hold every data block byte for byte (only the pauses differ); "(Side B)[a]" is REX 2
alone, its blocks identical; "(Side A)[a]" is a re-save of REX 1 into a BASIC with headerless blocks of 288, 20 000,
20 536 and 1704 bytes; ZXDB's `REX1.TAP` and `REX2.TAP` keep the screen and code blocks and add `PAUSE 0` to the BASIC;
ZXDB's `RexDemo.tap` is side 2 byte for byte. The +3 disk, the snapshots and the conversions are not studied (the
owner's rule for non-standard versions). The table is in the README.

The tape is two sides of standard ROM blocks ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)):
side 1 holds REX 1 (a BASIC, the screen, 40 930 bytes at `$6018`, `USR 38010` = `$947A`) and then REX 2 (40 530
bytes at `$61A8`, `USR 38000` = `$9470`); side 2 holds DEMO, the instructions' "Tutor Mode" (40 530 bytes at `$61A8`,
`USR 35460` = `$8A84`). There is no loader of the game's own and no protection. REX 2 asks for the access code that
REX 1 shows at its end (in the RZX run `rex1.rzx`: "CODE-8883898669979809", the text at `$A88C` of the 64 K at RZX
frame 64 000, `work/stage1/rzx/p1/mem.bin`).

Other sources: the RZX archive's `rex1.rzx` (Spectaculator 0.52, 128K, 64 813 frames, part 1 to its code) and
`rex2.rzx` (SPIN 0.5, 128K, 41 776 frames, part 2 to the ending); the ZXDB instructions (spectrumcomputing.co.uk
`Rex.txt`) and POKE file. A SkoolKit disassembly exists on GitHub (`ultrabolido/skRex`); it is not used
(`work/stage1/NOTES.md`).

## 1. One recording from power-on

`c1`: the 128K from power-on, side 1 at ROM speed (the fast LD-BYTES trap and turbo tape off), `LOAD ""` typed,
REX 1 loaded (`tools/capture.py --media A --model 128K --record-load --load-frames 15000`, port base 37780), then
`tests/inputs/c1.txt` from frame 15 000: the menu with its roll call, 1 DEFINE (I, J, Q, W, O), Y, PHASE ONE, play
in rooms 0 and 1 (walk, jump, fire, a smart bomb, the pause; the shield key is pressed but the shield never comes on),
five deaths (TTD frames 16 542, 17 149, 17 911, 18 217 and 18 761), GAME OVER at 18 996, PHASE ONE again at 19 231.
20 470 frames. The stages (`$RS stages --work work/stage1/c1`): the ROM's `$5B00` at frame 53, the game's entry
`$947A` at frame 13 701 T 29 586, written `$6018-$FFF9` by the ROM's LD-BYTES and entered from the BASIC's `USR`
([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)). No code of the game runs before the entry.

The interrupts and the timing, a first look:

- **IM mode and handler.** None: the game has no handler. The entry `$947A` starts with `DI`, and no `EI` and no `IM`
  instruction run after it; the machine stays in the ROM's IM 1 with interrupts off. `c1`'s L1 counts 159
  interrupts, all in the ROM before the entry; the L1s of the 54 RZX segments count none (`$RS interrupts`). DEMO
  (`d1`, entry `$8A84`) is the same: 159 interrupts, all before its entry.
- **DI and EI.** One `DI`, at `$947A`; no `EI` runs in any recording.
- **The main loop.** Part 1: `$9583` calls `$A89D` (the room drawn), then the pass `$9586-$9678` ends `JP $9586`. In
  the pass ENTER (`$95D5`) restarts at `$9498`, H (`$95DF`) pauses at `$A4E7`, SPACE (`$95E9`) fires a smart bomb
  (`$9751`); `$9645-$966A` rotates four characters of the scenery in place. Part 2's pass is `$9588-$9660`, ENTER
  read at `$95DE`.
- **Frames per pass.** With no interrupt the pass runs as fast as its work allows. Measured on the RZX runs with
  SkoolKit's simulator (`tools/rzx_dump.py --pc-log`, the pass's ENTER read, `work/stage1/rzx-pass/p1` and `p2`):
  part 1, 14 096 passes in the window of RZX frames 395 to 63 704; the 14 044 passes shorter than 20 frames average
  4.40 frames (2 frames 3 times, 3: 3367, 4: 8839, 5: 1775, 6: 60). Part 2, 9644 passes in RZX frames 574 to
  40 869; the 9619 short ones average 4.13 (2: 6, 3: 4336, 4: 4702, 5: 533, 6: 42). On our instance the L1s of the
  RZX segments give the same order: part 1 14 137 passes in 64 813 frames (4.58), part 2 9795 in 41 776 (4.27).
- **The heaviest frame.** Every frame in play is full (the pass never waits for the frame). The heaviest pass draws
  a new room: 48 passes of 22 to 26 frames in part 1, 24.7 to 25.7 in part 2. Four part 1 passes of 43 to 102
  frames, open in stage 1, are the weapon panels (stage 2,
  [doc 4, 4.7](docs/04-game-loop.md#47-the-long-passes-the-weapon-stations)).

## 2. Static pass over the medium

`tools/tzxblocks.py` cut both sides into their blocks (`src/tape/side1.txt`, `side2.txt`, `work/stage1/blocks/`);
`tools/basic_list.py` listed the three BASIC programs and `tools/image.py` wrote the three code images (REX 1
`$6018-$FFF9`, REX 2 and DEMO `$61A8-$FFF9`) as LD-BYTES leaves them. Stage 2 wrote one `.ann` per part
(`src/game/game.ann`, `src/rex2/rex2.ann`, `src/demo/demo.ann`); REX 2 and DEMO were seeded from REX 1's names by
`tools/name_transfer.py` and each carried name read again by hand. `kit/mkgame.py` walked each part's code from its
entry and from every recording's L1 (`read_builds` in `case.json`) and wrote 23 modules for REX 1 and REX 2 and 20 for
DEMO ([stage 2 NOTES](work/stage2/NOTES.md)). The room format was read from DrawRoom and MakeObjects
([doc 7](docs/07-objects.md)); `tools/room_maps.py` and `tools/fig_worldmap.py` draw every room and both world maps from
`src/res/rooms/` alone ([doc 1, 1.4](docs/01-game-design.md#14-the-world)).

## 3. The stages and the packers

There are none: each part runs where the ROM's LD-BYTES put it, entered from its BASIC's `USR`
([doc 3, 3.8](docs/03-build-and-load.md#38-loaders-protection-and-packers-none)).

## 4. The medium from source

`tools/build.sh` assembles the three BASIC programs (`src/tape/basic.ann`), the three loading screens
(`src/screen/`) and the three code parts (REX 1 23 modules, REX 2 23, DEMO 20, with the resources of `src/res/`) and
writes `build/side1.tzx` and `build/side2.tzx`, identical to the two files of `orig/Rex.tzx.zip` byte for byte
([doc 3, 3.5](docs/03-build-and-load.md#35-the-build)); `tools/res_formats.py check` converts each of the 43 editable
resource files back to its bytes (0 bad).

```sh
python3 ../../kit/mkgame.py --case . --fix-witness --install                            # REX 1
python3 ../../kit/mkgame.py --case . --part src/rex2/rex2.json --fix-witness --install  # REX 2
python3 ../../kit/mkgame.py --case . --part src/demo/demo.json --fix-witness --install  # DEMO
python3 ../../kit/refdocs.py --case .                                                    # docs 11 and 12
rm -rf build && sh tools/build.sh $SJASMPLUS && python3 tools/res_formats.py check
```

## 5. Tool gaps found and fixed in unreal-ng

None in unreal-ng. The gaps found in the case's own tools and the kit (the stack low mark, `rzx_match` tolerance,
`rzx_dump --watch`, the tape seek, modal panels that eat a key, a `c` seed against a recorded read, the witness
report, input scripts without `END`) are rows of the Kit gaps table in `../../TODO.md`.

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| none | | |

## 6. The game

Rex as it plays (seen in the recordings below): a flip-screen run-and-gun. Rex walks, jumps and fires through rooms of a
cave; a shield (down) runs on the energy shown in the HUD's middle figure (`$A04D`), SPACE fires one of three smart
bombs (`$A06C`), weapon stations add the HUD's other weapons (`$A04F-$A053`). Four lives. Part 1 ("PHASE ONE: PROCEED ON
FOOT THROUGH UNDERGROUND COMPLEX") ends with a 16-digit access code; part 2 (REX 2, "PHASE TWO: ENTER THE LIVING TOWER
TO REACH ZENITH") asks for it and carries part 1's score, lives and weapons over. The menu: 1 DEFINE, 2 KEMPSTON, 3
CURSOR, 4 SINCLAIR, each confirmed with Y, beside the roll call of the enemies and their points. DEMO, on side 2, is a
tutor: play with panels that explain the weapons.

### 6.0 The recordings

All on unreal-ng's 128K, muted, port bases 37780 and 37785; each keeps its `session.ttd` (the TTD of the whole run),
`l1.json`, `capture.json` and `screens/` (one screen every 250 frames) in its folder, and its input script in
`tests/inputs/NAME.txt`. Stage 1's recordings use no POKE. The later ones start from a snapshot (said in the table)
and some poke the clone: every POKE is a line of the input script (`FRAME POKE ADDR VALUE`, frame 0 before the first
frame) and is said here. Every command runs from the case folder after `. work/env.sh`.

| Name | Folder | Start | Inputs | Frames | What it reached |
| --- | --- | --- | --- | --- | --- |
| `c1` | `work/stage1/c1` | power-on, `--record-load`, side 1 at ROM speed ([1](#1-one-recording-from-power-on)) | `tests/inputs/c1.txt` from frame 15 000 | 20 470 | the load (entry `$947A` at 13 701), the menu with its roll call, 1 DEFINE (I J Q W O), Y, PHASE ONE, play in rooms 0 and 1: walk, jump, fire, a smart bomb, the pause (the shield never on); five deaths, GAME OVER at TTD 18 996 with HI-SCORE and HUMANS KILLED, PHASE ONE again |
| `c2` | `work/stage1/c2` | power-on, `--record-load`, side 1 from tape block 6 (REX 2 alone, `SEEK=6`) at ROM speed | `tests/inputs/c2.txt` from frame 14 000 | 23 106 | the load (entry `$9470` at 13 567; 159 interrupts, all before it), INPUT YOUR CODE, a wrong code (16 x 1): INVALID CODE, which stays up until a key and takes that key; the code `rex1.rzx` ends with (8883898669979809): accepted, PHASE TWO and play in part 2's room 0 with part 1's score carried (HUD 0100300); 4 SINCLAIR, 2 KEMPSTON (Rex walks right through rooms on the Kempston inputs alone, screens 6000-8500), 3 CURSOR; ENTER in play restarts at PHASE TWO, and after the third the code screen comes back (screen 9250), where the script's last keys type a wrong code |
| `d1` | `work/stage1/d1` | power-on, `--record-load`, side 2 (DEMO) at ROM speed | `tests/inputs/d1.txt` from frame 14 200 | 22 142 | the load (entry `$8A84` at 13 224); no menu: play with the Sinclair keys at once, the tutor's panels on the weapons, a weapon pod |
| `rzx-p1-NNNNN` (33) | `work/stage1/rec/rzx-p1-NNNNN` | `work/stage1/rzx/p1/atNNNNNN.szx`: the state after NNNNN frames of `rex1.rzx` played in unreal-ng (`tools/rzx_log.py`, 0 desyncs; someone else's play) | `tests/inputs/rzx-p1-NNNNN.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys, frames NNNNN+1 to NNNNN+2000) | 2000 each (the last 813), 64 813 in all | part 1 from the menu through rooms 0 1 15 16 4 5 6 7 20 21 22 23 25 9 10 11 12 13 17 18 19 28 29 34 33 32 31 (the RZX's order, `work/stage2/roomwatch/p1`) to the end and the CODE panel; 10 segments leave the RZX's rooms before their end (`work/stage1/room-match.txt`) |
| `rzx-p2-NNNNN` (21) | `work/stage1/rec/rzx-p2-NNNNN` | `work/stage1/rzx/p2/atNNNNNN.szx` (`rex2.rzx`, which starts at the menu with the code accepted) | `tests/inputs/rzx-p2-NNNNN.txt` | 2000 each (the last 1776), 41 776 in all | part 2 from the menu, PHASE TWO, rooms 0 to 25 in order (room 20 only for the 147 RZX frames 29 311-29 458, `work/stage2/roomwatch/p2`), the last room's boss and the ending text; 13 segments leave the RZX's rooms before their end (`work/stage1/room-match.txt`) |
| `p1-room14`, `p1-room24`, `p1-room26`, `p1-room27` | `work/stage2/rec/NAME` | `work/stage1/rzx/p1/at012000.szx`, `at017000`, `at019000`, `at020000` | `tests/inputs/NAME.txt`; POKEs: infinite lives (40057 = 0), RoomRight `$A08D` (41101) and RoomLeft `$A090` (41104) = the room, RexX `$A0B6` (41142) = `$EE` | 754 each | Rex walks right into room 14, 24, 26 or 27, then fires, walks left and jumps there (Room `$A0B8` = the room from frame 250; the L1 reads its map) |
| `p1-room30` | `work/stage2/rec/p1-room30` | `work/stage1/rzx/p1/at054000.szx` | the RZX's keys of frames 54 001-55 300; POKEs: infinite lives, room 19's up exit `$B1A5` (45477) = 30 | 1300 | room 30 at frame 1250 |
| `p1-code` | `work/stage2/rec/p1-code` | `work/stage1/rzx/p1/at063000.szx` | the RZX's keys of frames 63 001-64 813; POKEs: infinite lives, room 31's four exits `$B1ED-$B1F0` (45549-45552) = 99 | 1813 | the RZX's own exit at its frame 63 705, CodePanel `$A7CE`, fire, a new game in room 0 |
| `p1-gameover` | `work/stage2/rec/p1-gameover` | `work/stage1/rzx/p1/at012000.szx` | no keys; POKEs: Lives `$A063` (41059) = 0, HumansKilled `$A089` (41097) = 37, SweepWidth `$A067` (41063) = 2 | 1510 | the sweep kills Rex, GAME OVER with HUMANS KILLED 00037 |
| `p1-cursor`, `p1-kempston`, `p1-define` | `work/stage2/rec/NAME` | `work/stage1/probe/128K/loaded.szx` (the menu after the load) | menu 3, 2 or 1 (DEFINE P, L, Z, X, M), Y, then each control; no POKE | 2542, 1553, 1723 | the readers' ports and `BIT`s per control method, play on each, H, SPACE and ENTER (`p1-cursor`) |
| `p2-room20` | `work/stage2/rec/p2-room20` | `work/stage1/rzx/p2/at029000.szx` | POKEs: infinite lives (40303 = 0), RoomRight `$A226` (41510) and RoomLeft `$A229` (41513) = 20, RexX `$A24F` (41551) = `$EE` | 794 | part 2's room 20 (its map read), a death back to room 17, the pause |
| `demo-cycle` | `work/stage2/rec/demo-cycle` | `work/stage1/d1/start.szx` | no keys for 30 000 frames, then SPACE twice; no POKE | 30 312 | the tutor's rooms 4, 1, 0 and 2 and the credits, then again; DemoPause |
| `menu-rollcall` | `work/docs/rxA/rec/menu-rollcall` | `work/stage1/probe/128K/loaded.szx` | no keys; no POKE | 5310 | the roll call's ten enemies, one each 520 frames, and the menu code `$DB6E-$DB85` run |
| `p1-rooms238` | `work/docs/rxA/rec/p1-rooms238` | `work/stage1/rzx/p1/at012000.szx` | right; POKEs: infinite lives, Immune `$A071` (41073) = 1, RoomRight = 2, RexX = `$EF`, later RoomRight = 8 in room 3 | 910 | rooms 2, 3 and 8, which no other recording enters |
| `p1-speedup` | `work/docs/integrate/rec/p1-speedup` | `work/stage1/rzx/p1/at050000.szx` | the RZX's keys to frame 1716, fire at 1736 on SPEED UP; from 1800 POKEs: infinite lives, Immune = 1; then right and left | 3210 | the bonus roulette (BonusRoll 3 at 1701, 0 at 1730), SPEED UP taken: SpeedUp 1 from 1740, RexSpeed 4 / -4 until the timer runs out at 2740, then 2 / -2; room 18 to 19 at 1950 |
| `p1-shots` | `work/docs/integrate/rec/p1-shots` | `work/stage1/rzx/p1/at012000.szx` | POKEs: infinite lives, Immune = 1, HasLaser `$A051` (41041) = 1, WeaponRank `$A06E` (41070) = 2, Weapon `$A013` (40979) = 2; fire three times; at 300 HasSpray `$A053` = 1, WeaponRank and Weapon = 4; fire three times | 610 | one laser and one spray volley (Weapon 2, then 4; the bullets at `$5B60` from frames 45 and 344): FireLaser and FireSpray run |
| `p1-poke41241` | `work/docs/integrate/rec/p1-poke41241` | `work/stage1/rzx/p1/at012000.szx` | no keys; POKEs: 41241 = 0 (the `DEC A` of HudSweep at `$A119` made a `NOP`), SweepWidth = 2, Immune = 1 | 3010 | the POKE of [doc 3, 3.6](docs/03-build-and-load.md#36-the-pokes): SweepWidth stays 2 while SweepCount `$A065` runs 5 .. 1 about 33 times; no death |

How they were made:

```sh
python3 tools/capture.py --work work/stage1/c1 --media A --model 128K --record-load --load-frames 15000 \
   --inputs tests/inputs/c1.txt --ranges 4000-FFFF --port-base 37780 --binary $BIN
SEEK=6 python3 tools/capture.py --work work/stage1/c2 --media A --model 128K --record-load --load-frames 14000 \
   --inputs tests/inputs/c2.txt --ranges 4000-FFFF --port-base 37780 --binary $BIN
python3 tools/capture.py --work work/stage1/d1 --media B --model 128K --record-load --load-frames 14200 \
   --inputs tests/inputs/d1.txt --ranges 4000-FFFF --port-base 37785 --binary $BIN
sh work/stage1/run_segments.sh 1 37780 0 2000 4000 ...    # tools/rzx_segment.sh per segment
sh work/stage2/rec2.sh 37780 p1-room14:work/stage1/rzx/p1/at012000.szx p1-room24:work/stage1/rzx/p1/at017000.szx \
   p1-room26:work/stage1/rzx/p1/at019000.szx p1-room27:work/stage1/rzx/p1/at020000.szx \
   p1-room30:work/stage1/rzx/p1/at054000.szx p1-code:work/stage1/rzx/p1/at063000.szx \
   p1-gameover:work/stage1/rzx/p1/at012000.szx p2-room20:work/stage1/rzx/p2/at029000.szx \
   p1-define:work/stage1/probe/128K/loaded.szx
sh work/stage2/rec2.sh 37785 p1-cursor:work/stage1/probe/128K/loaded.szx p1-kempston:work/stage1/probe/128K/loaded.szx \
   demo-cycle:work/stage1/d1/start.szx
python3 tools/capture.py --work work/docs/rxA/rec/menu-rollcall --snapshot work/stage1/probe/128K/loaded.szx \
   --model 128K --inputs tests/inputs/menu-rollcall.txt --ranges 4000-FFFF --port-base 37780 --binary $BIN
python3 tools/capture.py --work work/docs/rxA/rec/p1-rooms238 --snapshot work/stage1/rzx/p1/at012000.szx \
   --model 128K --inputs tests/inputs/p1-rooms238.txt --ranges 4000-FFFF --port-base 37780 --binary $BIN
sh work/docs/integrate/rec.sh 37780 p1-speedup:work/stage1/rzx/p1/at050000.szx \
   p1-shots:work/stage1/rzx/p1/at012000.szx p1-poke41241:work/stage1/rzx/p1/at012000.szx
python3 $RS stop --work FOLDER
```

`rec2.sh` and `rec.sh` run `tools/capture.py` as above (`--snapshot SNAP --model 128K --inputs tests/inputs/NAME.txt
--ranges 4000-FFFF`) one recording after the other, then stop the instance. A recording is opened again from its
`session.ttd` with `python3 ../../kit/rs.py open --work W --ttd FOLDER/session.ttd --model 128K --port-base 37780`;
the `work/docs/rxA/`, `rxB/` and `rxC/` folders that are no recordings (`p1-08000`, `r04`, `c1`, `pgo`, ...) are the
docs writers' trace windows over the recordings above, opened that way; the animations name them (6.2).

The RZX segments start on the RZX's course, but 23 of the 54 leave it before their end: by the room byte
(`kit/rzx_match.py --window 250 --room`, `work/stage1/room-match.txt`, which names them and the frame each leaves),
31 keep the RZX's rooms to their end, 10 of the 33 part 1 segments and 13 of the 21 part 2 segments are in another
room from a frame between 750 and 2000 on (`rzx-p1-02000` in room 0 from frame 750 while the RZX is in 15, `rzx-p2-16000` in
11 against 13). The game is not frame-locked and a key held per frame may land on another pass: within a room the
screens differ in sprites a few pixels apart, and the drift can take the run elsewhere. The rooms
listed in the table above are the RZX's (`work/stage2/roomwatch`); a segment that leaves the route ran other rooms
after that frame. Every segment is still a witness of what it ran (the L1's readers, writers and routines are its
own run), not of the RZX's route. A first try with 10 000-frame segments
drifted after 1500 to 7000 frames and was dropped. Their play is the RZX authors'; ours (`c1`, `c2`, `d1`) covers the
menu, every control method, a life lost, game over and the code entry.

Not reached in stage 1, reached later: part 1's rooms 14, 24, 26, 27 and 30 and part 2's room 20 (`p1-room*`,
`p2-room20`), rooms 2, 3 and 8 (`p1-rooms238`); each enemy, hazard and sound named one by one (stage 2 and docs 7, 9
and 10; the roll call names ten enemies, `menu-rollcall`). Known only from the code before the integration, now
recorded: SPEED UP from the roulette (`p1-speedup`), one laser and one spray volley (`p1-shots`) and POKE 41241
(`p1-poke41241`).

### 6.1 The screens

Every screen the documents link (a recording's `screens/NNNNNN.scr` by `tools/shot.py`, or drawn from its
`session.ttd`; `c1`, `c2` and `d1` frames are the inputs' frames, after the load; the RZX segments' are TTD frames):

| Recording, frame | Screen |
| --- | --- |
| `c1` 250 | [the menu with the roll call](docs/img/play/c1-000250-menu.png) |
| `c1` 750 | [DEFINE](docs/img/play/c1-000750-define.png) |
| `c1` 1000 | [PHASE ONE](docs/img/play/c1-001000-phase-one.png) |
| `c1` 1500 | [room 0 in play](docs/img/play/c1-001500-room0.png) |
| `c1` 4000 | [GAME OVER, HI-SCORE, HUMANS KILLED](docs/img/play/c1-004000-game-over.png) |
| `c2` 1750, 3250, 4250 | [INVALID CODE](docs/img/play/c2-001750-invalid-code.png), [the right code](docs/img/play/c2-003250-code.png), [part 2 with part 1's score](docs/img/play/c2-004250-part2.png) |
| `d1` 5500 | [DEMO's tutor](docs/img/play/d1-005500-tutor.png) |
| `rzx-p1-30000` 1000 | [part 1 later on](docs/img/play/rzx-p1-31000-play.png) |
| `rex1.rzx` 64 000 | [the access code at the end](docs/img/play/rex1-rzx-064000-code.png), [place by place](docs/img/play/access-code.png) |
| `rzx-p2-00000` 500, 1000 | [PHASE TWO](docs/img/play/rzx-p2-00500-phase-two.png), [part 2's room 0](docs/img/play/rzx-p2-01000-room0.png) |
| `rzx-p2-20000` 1000 | [the tower](docs/img/play/rzx-p2-21000-play.png) |
| `rzx-p2-40000` 1500 | [the ending](docs/img/play/rzx-p2-41500-ending.png) |
| `menu-rollcall` | [the roll call, ten enemies](docs/img/play/roll-call.png) |
| `c1` TTD 15 200, 15 400 | [the menu](docs/img/controls/menu.png) |
| `p1-define` 620 | [DEFINE done](docs/img/controls/define-confirm.png) |
| `c2` TTD 15 700, 17 200 | [REX 2's code screen](docs/img/controls/code-entry.png) |
| `p1-cursor` 1006 | [the HUD's fields](docs/img/hud/panel.png) |
| `rzx-p1-00000` 1400, `rzx-p1-10000` 590, `rzx-p1-18000` 400, `rzx-p1-26000` 200 | [the four weapon panels](docs/img/hud/weapon-panels.png) (`work/docs/integrate/ttdshot.py`) |
| `p1-speedup` 1734 | [the bonus roulette on SPEED UP](docs/img/hud/bonus-roulette.png) (`work/docs/integrate/ttdshot.py`) |
| `p1-gameover` 250, 500 | [the game over panel](docs/img/hud/game-over.png) |
| `p1-code` 800 | [the CODE panel](docs/img/hud/code.png) |
| every recording | the contact sheets: [part 1](docs/img/play/screens-part1.png), [part 2](docs/img/play/screens-part2.png), [DEMO](docs/img/play/screens-demo.png) |

Every room, drawn from the level data, is on the maps of [doc 1, 1.4](docs/01-game-design.md#14-the-world).

### 6.2 The animations

| File | Document | Recording | Frames |
| --- | --- | --- | --- |
| [MainLoop.gif](docs/img/routines/MainLoop.gif) | [doc 4](docs/04-game-loop.md) | `rzx-p1-08000` | 1161:58511-1165:60804 |
| [BuildRoom.gif](docs/img/routines/BuildRoom.gif) | doc 4 | `rzx-p1-08000` | 1177:66045-1198:45440 |
| [room-change-5-6.gif](docs/img/play/room-change-5-6.gif) | doc 4 | `rzx-p1-08000` | 1166-1206 |
| [MainKeys.gif](docs/img/routines/MainKeys.gif) | [doc 5](docs/05-controls.md) | `p1-cursor` | 865:28400-865:33000 |
| [ScanKey.gif](docs/img/routines/ScanKey.gif) | doc 5 | `p1-define` | 199:66000-200:14000 |
| [keys.gif](docs/img/play/keys.gif) | doc 5 | `p1-cursor` | 760-1480, every 6th |
| [DrawRoom.gif](docs/img/routines/DrawRoom.gif) | [doc 6](docs/06-rendering.md) | `p1-cursor` | 400:32000-421:6000 |
| [DrawAnimCells.gif](docs/img/routines/DrawAnimCells.gif) | doc 6 | `p1-cursor` | 1010:8600-1011:51100 |
| [ClearBuffer.gif](docs/img/routines/ClearBuffer.gif) | doc 6 | `p1-cursor` | 1013:5500-1013:40000 |
| [DrawSprite.gif](docs/img/routines/DrawSprite.gif) | doc 6 | `p1-cursor` | 1009:54600-1009:65400 |
| [DrawMirrored.gif](docs/img/routines/DrawMirrored.gif) | doc 6 | `rzx-p1-00000` | 603:42100-603:51000 |
| [MoveShots.gif](docs/img/routines/MoveShots.gif) | doc 6 | `rzx-p1-08000` | 1603:30500-1603:38700 |
| [UpdateDrones.gif](docs/img/routines/UpdateDrones.gif) | doc 6 | `rzx-p1-20000` | 603:8800-603:13960 |
| [SparkleUpdate.gif](docs/img/routines/SparkleUpdate.gif) | doc 6 | `rzx-p1-36000` | 1602:32100-1602:34600 |
| [OrChar.gif](docs/img/routines/OrChar.gif) | doc 6 | `rzx-p1-00000` | 1604:8000-1604:12000 |
| [BufferToScreen.gif](docs/img/routines/BufferToScreen.gif) | doc 6 | `p1-cursor` | 1011:51000-1013:5100 |
| [MakeObjects.gif](docs/img/routines/MakeObjects.gif) | [doc 7](docs/07-objects.md) | `c1` | TTD 16 957, T 8000-21 700 |
| [UpdateObjects.gif](docs/img/routines/UpdateObjects.gif) | doc 7 | `rzx-p1-04000` | 1415:70300-1416:43600 |
| [SpawnRandom.gif](docs/img/routines/SpawnRandom.gif) | doc 7 | `c1` | TTD 17 074, T 8900-31 400 |
| [rzx-p1-05376-launcher-killed.gif](docs/img/play/rzx-p1-05376-launcher-killed.gif) | doc 7 | `rzx-p1-04000` | 1376-1456, every 2nd |
| [PrintText.gif](docs/img/routines/PrintText.gif) | [doc 8](docs/08-hud-and-text.md) | `p1-cursor` | 335:9000-336:0 |
| [ShowScore.gif](docs/img/routines/ShowScore.gif) | doc 8 | `rzx-p1-24000` | 668:55500-668:60700 |
| [SoundStep.gif](docs/img/routines/SoundStep.gif) | [doc 9](docs/09-sound.md) | `c1` | TTD 16 979, T 66 700-68 700 |
| [c1-jump.gif](docs/img/play/c1-jump.gif) | [doc 10](docs/10-gameplay-logic.md) | `c1` | TTD 17 000-17 044, every 2nd |
| [c1-death.gif](docs/img/play/c1-death.gif) | doc 10 | `c1` | TTD 16 536-16 724, every 4th |
| [rzx-p1-04420-double-fire.gif](docs/img/play/rzx-p1-04420-double-fire.gif) | doc 10 | `rzx-p1-04000` | 420-476, every 2nd |
| [rzx-p1-05496-pod-taken.gif](docs/img/play/rzx-p1-05496-pod-taken.gif) | doc 10 | `rzx-p1-04000` | 1496-1540, every 2nd |
| [TakePowerPod.gif](docs/img/routines/TakePowerPod.gif) | doc 10 | `rzx-p1-04000` | 1528:17500-1528:19300 |
| [c1-smart-bomb.gif](docs/img/play/c1-smart-bomb.gif) | doc 10 | `c1` | TTD 17 340-17 400, every 2nd |

The `FRAME:T` windows are TTD frames and T states of the recording's `session.ttd`; each caption gives the command.

## 7. Review
