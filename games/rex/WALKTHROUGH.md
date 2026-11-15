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
in rooms 1 and 2 (walk, jump, fire, the shield, a smart bomb, the pause), all four lives lost, GAME OVER, play again.
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
  frames are not identified yet (stage 2).

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

Rex as it plays (seen in the recordings below): a flip-screen run-and-gun. Rex walks, jumps and fires through rooms of a
cave; a shield (down) runs on the energy shown in the HUD's middle figure (`$A04D`), SPACE fires one of three smart
bombs (`$A06C`), weapon pods add the HUD's other weapons (`$A04F-$A053`). Four lives. Part 1 ("PHASE ONE: PROCEED ON FOOT
THROUGH UNDERGROUND COMPLEX") ends with a 16-digit access code; part 2 (REX 2, "PHASE TWO: ENTER THE LIVING TOWER TO
REACH ZENITH") asks for it and carries part 1's score, lives and weapons over. The menu: 1 DEFINE, 2 KEMPSTON, 3
CURSOR, 4 SINCLAIR, each confirmed with Y, beside the roll call of the enemies and their points. DEMO, on side 2, is a
tutor: play with panels that explain the weapons.

### 6.0 The recordings

All on unreal-ng's 128K, muted, port bases 37780 and 37785; each keeps its `session.ttd`, `l1.json` and `screens/`
(one screen every 250 frames) in its folder. No POKE was used. Every command runs from the case folder after
`. work/env.sh`.

| Name | Folder | Start | Inputs | Frames | What it reached |
| --- | --- | --- | --- | --- | --- |
| `c1` | `work/stage1/c1` | power-on, `--record-load`, side 1 at ROM speed ([1](#1-one-recording-from-power-on)) | `tests/inputs/c1.txt` from frame 15 000 | 20 470 | the load (entry `$947A` at 13 701), the menu with its roll call, 1 DEFINE (I J Q W O), Y, PHASE ONE, play in rooms 1 and 2: walk, jump, fire, the shield, a smart bomb, the pause; all four lives lost, GAME OVER with HI-SCORE and HUMANS KILLED, PHASE ONE again |
| `c2` | `work/stage1/c2` | power-on, `--record-load`, side 1 from tape block 6 (REX 2 alone, `SEEK=6`) at ROM speed | `tests/inputs/c2.txt` from frame 14 000 | 23 106 | the load (entry `$9470` at 13 567; 159 interrupts, all before it), INPUT YOUR CODE, a wrong code (16 x 1): INVALID CODE, which stays up until a key and takes that key; the code `rex1.rzx` ends with (8883898669979809): accepted, PHASE TWO and play in part 2's room 1 with part 1's score carried (HUD 0100300); 4 SINCLAIR, 2 KEMPSTON (Rex walks right through rooms on the Kempston inputs alone, screens 6000-8500), 3 CURSOR; ENTER in play restarts at PHASE TWO, and after the third the code screen comes back (screen 9250), where the script's last keys type a wrong code |
| `d1` | `work/stage1/d1` | power-on, `--record-load`, side 2 (DEMO) at ROM speed | `tests/inputs/d1.txt` from frame 14 200 | 22 142 | the load (entry `$8A84` at 13 224); no menu: play with the Sinclair keys at once, the tutor's panels on the weapons, a weapon pod |
| `rzx-p1-NNNNN` (33) | `work/stage1/rec/rzx-p1-NNNNN` | `work/stage1/rzx/p1/atNNNNNN.szx`: the state after NNNNN frames of `rex1.rzx` played in unreal-ng (`tools/rzx_log.py`, 0 desyncs; someone else's play) | `tests/inputs/rzx-p1-NNNNN.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys, frames NNNNN+1 to NNNNN+2000) | 2000 each (the last 813), 64 813 in all | part 1 from the menu through rooms 1 4 5 6 7 15 16 20 21 22 23 25 9 10 11 12 13 17 18 19 28 29 34 33 32 31 to the end and the CODE panel |
| `rzx-p2-NNNNN` (21) | `work/stage1/rec/rzx-p2-NNNNN` | `work/stage1/rzx/p2/atNNNNNN.szx` (`rex2.rzx`, which starts at the menu with the code accepted) | `tests/inputs/rzx-p2-NNNNN.txt` | 2000 each (the last 1776), 41 776 in all | part 2 from the menu, PHASE TWO, rooms 1 to 25 but 20, the last room's boss and the ending text |

How they were made:

```sh
python3 tools/capture.py --work work/stage1/c1 --media A --model 128K --record-load --load-frames 15000 --inputs tests/inputs/c1.txt --ranges 4000-FFFF --port-base 37780 --binary $BIN
SEEK=6 python3 tools/capture.py --work work/stage1/c2 --media A --model 128K --record-load --load-frames 14000 --inputs tests/inputs/c2.txt --ranges 4000-FFFF --port-base 37780 --binary $BIN
python3 tools/capture.py --work work/stage1/d1 --media B --model 128K --record-load --load-frames 14200 --inputs tests/inputs/d1.txt --ranges 4000-FFFF --port-base 37785 --binary $BIN
sh work/stage1/run_segments.sh 1 37780 0 2000 4000 ...    # tools/rzx_segment.sh per segment
python3 $RS stop --work FOLDER
```

The RZX segments keep to the RZX's course: each changes rooms in the RZX's order at about the RZX's frames
(`tools/rzx_match.py`, `work/stage1/rec-summary.txt`); the screens differ in sprites a few pixels apart, because the
game is not frame-locked and a key held per frame may land on another pass. A first try with 10 000-frame segments
drifted after 1500 to 7000 frames and was dropped. Their play is the RZX authors'; ours (`c1`, `c2`, `d1`) covers the
menu, every control method, a life lost, game over and the code entry.

Not reached in stage 1: part 1's rooms 14, 24, 26, 27 and 30 and part 2's room 20 (on the maps, off the RZX's route);
each enemy, hazard and sound named one by one (the AY and beeper writes are witnessed, `work/stage1/NOTES.md`; the
roll call names eight enemies, stage 2 ties each to its code).

### 6.1 Screens and levels

Every screen as captured (`tools/shot.py` from a recording's `screens/NNNNNN.scr`; the frame is the inputs' frame,
after the load; `--rzx` takes the RZX log's own screens):

- the menu with the roll call: [`c1` 250](docs/img/play/c1-000250-menu.png); DEFINE: [`c1` 750](docs/img/play/c1-000750-define.png);
- PHASE ONE: [`c1` 1000](docs/img/play/c1-001000-phase-one.png); room 1 in play: [`c1` 1500](docs/img/play/c1-001500-room1.png);
- GAME OVER, HI-SCORE, HUMANS KILLED: [`c1` 4000](docs/img/play/c1-004000-game-over.png);
- DEMO's tutor: [`d1` 5500](docs/img/play/d1-005500-tutor.png);
- part 1 later on: [`rzx-p1-30000` 1000](docs/img/play/rzx-p1-31000-play.png); the access code at the end:
  [`rex1.rzx` frame 64 000](docs/img/play/rex1-rzx-064000-code.png);
- the code screen: INVALID CODE after the wrong code [`c2` 1750](docs/img/play/c2-001750-invalid-code.png), the right code
  [`c2` 3250](docs/img/play/c2-003250-code.png), part 2 with part 1's score: [`c2` 4250](docs/img/play/c2-004250-part2.png);
- PHASE TWO: [`rzx-p2-00000` 500](docs/img/play/rzx-p2-00500-phase-two.png); part 2's room 1:
  [`rzx-p2-00000` 1000](docs/img/play/rzx-p2-01000-room1.png); the tower: [`rzx-p2-20000` 1000](docs/img/play/rzx-p2-21000-play.png);
- the ending: [`rzx-p2-40000` 1500](docs/img/play/rzx-p2-41500-ending.png).

Every room, drawn from the level data, is on the maps of [doc 2, 2.3](docs/02-architecture.md#23-the-levels-in-memory).

## 7. Review
