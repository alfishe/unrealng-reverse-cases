# ATV Simulator: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

**What was looked for.** ZXDB (`zxdb.sqlite` v1.0.242, entry 9306), the collection index
`/Volumes/TB4-4Tb/Data/zx-spectrum/index/zx-image-locations.tsv` (`grep -i atv`), TOSEC 2023-09, zxart, the
collection's World of Spectrum mirror and the owner's archive. Every copy found is in `work/candidates/<source>/`
unchanged (git-ignored); the README lists them with what differs.

**The original.** ZXDB's release 0 is Code Masters' 1987 tape; ZXDB denies its file. The collection's World of
Spectrum mirror holds `ATVSimulator.tzx.zip` (25 601 bytes, another zip than ZXDB's 25 525): it is the case's
`orig/`, unchanged. Its TZX (47 124 bytes, md5 `ca7bb7957f69915fc965e81d49eb99a4`) is byte for byte TOSEC's `[a]`
dump and zxart's `[p 1987 Code Masters Ltd]` dump.

**The blocks** (`python3 ../../kit/tapblocks.py list "work/media/ATV Simulator.tzx"`; `work/media/` holds the TZX
from the zip): eight standard-speed blocks, a BASIC loader, a 34-byte machine-code loader at `$FFDC`, a 6912-byte
screen and a 40000-byte game at `$6338`, the last two without the headers that sit before them on the tape (the
loader asks LD-BYTES for flag `$FF` and reads each header as a failed block). 281.9 s, 14 096 frames, at signal
speed. The table and the loader: [doc 3, 3.1-3.2](docs/03-build-and-load.md#31-the-tape-block-by-block).

**The copies compared** (`python3 tools/media_compare.py "work/media/ATV Simulator.tzx" <copy>...`, the flagged
blocks byte for byte): TOSEC's main dump, `[a2]` and the `.tap` hold the same loader, screen and game (one header
byte differs in `[a2]` and the `.tap`, LINE 0); `[h Raf]` replaces the BASIC; zxart's `[p]` has 6 bytes of the game
changed (the POKEs). Nothing on the tape is protected or packed: the image at the jump to `$D6B0` equals blocks 5 and
7 byte for byte (`work/stage1/images.py`, recording c1 frame 14 100 T 17 980 against `work/stage1/media/tape64.bin`:
no byte differs from `$4000` to `$5AFF` and from `$6338` to `$FF77`).

**48K or 128K.** ZXDB: 48K. The image has no paging write (no `$7FFD`) and no AY register select (`LD BC,$FFFD`
occurs once, at `$572E`, inside the loading screen's pixels); the sound is `OUT ($FE),A` (15 sites). The case runs
the 48K.

**Other sources.** The ZXDB POKEs (`ATVSimulator.pok`): 60250,0 "Infinite Lives", 49433,81 "Infinite Fuel",
57318,201 "Infinite Time", 57276,201 "Infinite fuel"; checked by recordings fuel and pokes (6.0). No RZX run could
be fetched (ZXDB and World of Spectrum answer 404; rzxarchive marks Pavel Plíva's run "Distribution Denied"). An AY
rip of the title tune exists (`work/candidates/ay/`). A public disassembly: see `work/stage1/NOTES.md`.

**The binary.** `work/env.sh` points at the `wt-nezs-stage1` build (unreal-ng `e3d341d38`), which lacks f13cee7da;
`kit/rs.py open` warns. This tape does not need the fix: its last block is the game, and the game's entry runs
before the tape ends (c1: entry at frame 14 100, the tape stops at 14 182).

## 1. One recording from power-on

Recording c1 (`python3 tools/record.py c1 --work work/stage1/rec/c1`): a 48K from power-on, the tape inserted,
`LOAD ""` typed, PLAY once at signal speed (fast and turbo tape off). The ROM loads the BASIC and the loader
(frame 1 017: the loader at `$FFDC` runs, `kit/rs.py stages`), the loader reads the screen and the game by LD-BYTES;
the game's entry `$D6B0` runs at frame 14 100 T 17 980. The title and credits, the menu (frame 14 657), START with
the power-on controls (one player, Kempston), trail 1 from frame 14 821 with a jump every 66 frames: the rider
crashed at distance 876 and stood there until TIME OUT (clock 60, near frame 20 897), then the menu. 22 397 frames;
the L1 replay checked 896 frames, diverged 0.

`kit/rs.py stages` on c1 (code arrivals): `$FFDC` (the loader, frame 1 017), `$8080` (the IM 2 vector `JP $D9D2`,
14 114), `$D9D2` (the handler), `$F852` (the tune player, 14 639, after `$6E04` copies it from `$5B00` back to
`$F850`), `$FDFD` (the tune's own IM 2 vector, 14 640), `$7340` and `$F977` (the tune's handler and its hook).

### Interrupts and timing (first look)

- **Entry.** `$D6B0` `JP $D7D6`: `DI`, two copies (`$F850-$FDFA` to `$5B00`, 1 451 bytes; `$F230-$F4B9` to
  `$60AC`, 650 bytes; the L1's `dataflow.copies`, sites `$D7E0` and `$D7EB`), the old SP kept at `$D6BA`, its own
  stack (`LD SP,$FFDC`, under the loader), then `$D8ED`: `IM 2` with `I` = `$FE` and the table `$FE00-$FF00` filled
  with `$80` (`LDIR` at `$D90E`), so every vector is `$8080`, which holds `JP $D9D2`.
- **The outer loop** at `$D7FB`: the menu (`$69A6`), the game (`$D80D`), `$69F4` (after the game: the high-score entry when a score qualifies, recordings kb and warp), round again.
- **The handler** `$D9D2` (`kit/rs.py interrupts`: 6 766 entries in c1, exactly one a frame from frame 14 114 except
  the 1 517 frames of the title tune): it saves the registers; on the menu (`$D6BC` = `$FF`) it reads both players'
  controls (`$D911`, `$D942`) into `$8113` / `$8114`; in play it counts the frame (`INC ($D6BC)`) and calls `$8310`
  and `$D97C`; `EI`, `RET` at `$DA1D`. Its length in play: 2 555 T an entry, every entry the same
  (`kit/handler_time.py --work work/stage1/c1x --window 16000:0-16050:0`, 50 entries; 80 % in `$8500-$85FF`).
- **The title tune** runs with its own table: vector `$FDFD` to `$F961`, which calls `$7340` (1 517 entries in c1,
  4 760 T an entry by L1).
- **DI / EI.** `DI` at the entry (`$D7D6`); `EI` at `$D850` when a trail starts, at `$ED06` in the trail end (after
  the tune's call at `$ED00`) and at the handler's end; the other `DI` sites are for stage 2.
- **The game pass** `$D851-$D888`: clear `$D6BC`, read the controls (`$D911`, `$D942`), `$830D`, the clock's tick
  (`$EB53`), `$EC7F`, then wait `LD A,($D6BC)` / `CP $07` / `JR C` (`$D86B-$D870`) until 7 frames have passed. So a
  pass is at least 7 frames. Measured: the wait loop ran 600 times in c1 between frames 15 059 and 19 255 (its
  branch's first and last frame in the L1), (19 255 − 15 059) / 599 = 7.005 frames a pass: in c1's play every pass
  was exactly 7 frames, the work never overran.
- **The heaviest pass.** The wait spins 32 T a turn (13 + 7 + 12); the L1's loop record for `$D86B` gives 1 168 turns
  at the least and 10 351 at the most over the 600 passes. A pass is 7 × 69 888 = 489 216 T, so the work (handler
  entries included) took from about 158 000 T (2.3 frames) to about 452 000 T (6.5 frames) a pass: the game uses up
  to 92 % of its 7-frame budget. The heaviest pass's frame is not named yet (stage 2: a trace of the pass with the
  fewest turns).
- **The clock.** `$EB53` adds 1 to the tenths digit at `$D6CB` once a pass (ASCII digits `$D6C9-$D6CB`): one clock
  tenth is 7 frames, one clock unit 70 frames (1.4 s). A trail's 60 is 4 200 frames.


## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 The recordings

All on unreal-ng's TTD (`analysis start record=true`), muted, port base 37780 or 37785, each folder
`work/stage1/rec/<name>/` with `session.ttd`, `l1.json`, `record.json` (the moments, the POKEs, the frames) and
`screens/`; the input script is `tests/inputs/<name>.txt` (keys by frame, POKEs as `POKE address bytes`). Each was
made by `python3 tools/record.py <name> --work work/stage1/rec/<name>`, with `--start <Start>` where the start is a
state. 48K; the original TZX; the L1 of each built (`kit/rs.py` through record.py). Kempston keys are `KL KR KU KD KF`.

| Name | Start | Frames | How | What it reached |
| --- | --- | ---: | --- | --- |
| c1 | power-on | 22 397 | `LOAD ""`, the tape at signal speed; START; right with a jump every 66 frames | the BASIC (582), the loading screen, the entry (14 100), the title tune and credits, the menu (14 657), trail 1 (14 821), mounting (14 897), a crash at distance 876, TIME OUT, the menu |
| menu | c1 `menu.szx` (14 657) | 3 340 | ENTER moves, SPACE picks: TWO PLAYERS; CHOOSE CONTROL, PLAYER ONE, KEYBOARD, the key table redefined Q A O P M, EXIT; PLAYER TWO, KEYBOARD, H J K M B, EXIT (state `menu-two-kb.szx`); then player 1 KEMPSTON, player 2 SINCLAIR; 2 500 frames idle | every menu screen and control method; the key tables of both players; the idle menu stays (no attract mode) |
| kb | menu `menu-two-kb.szx` | 9 160 | two players on the keyboard; both right, jump on, the wheel keys and jumps | the split screen of two players, both through trail 1 into trail 2; TIME OUT; player 2's high-score name entry (3 260) |
| trail1 | c1 `menu.szx` | 9 970 | `ride_smart` (record.py): the pattern right / wheelie / wheel down / jump; on foot back to the ATV | a crash, the rider thrown and walking back; stuck behind a dune (on foot, the walk-back rule fails, 6.2); TIME OUT; the title |
| trails | c1 `menu.szx` | 7 441 | `tools/autoride.py` (a search bot on clones: per crash it tries jumps, wheelies, braking at distances before it) found a plan; replayed segment for segment | trail 1 ridden to its finish with no POKE (two jumps: at distance 766 and a wheelie at 1 148) and trail 2's start, then the bot's last crash on trail 2 (distance 898) |
| warp | c1 `menu.szx` | 17 756 | on each trail, mounted, 150 frames ridden, then POKE: the distance (`$D78A`, `$D726`) set to the finish less 40 (14 POKEs, in `record.json`) | all six trails (SAND DUNING, GRASSTRAKIN, ICEBERGS, PYRAMIDS, TROPICANA, SWAMP), each finish (EXTENDED PLAY, LAP TIME) and the trail-end tune; the loop back to trail 1 with max 30; TIME OUT; the high-score name entry (33 350, "BC") and the new table |
| fuel | c1 `menu.szx` | 9 175 | POKE 60250,0 (the clock stopped); ride_smart, the fuel `$D77D` watched | fuel from 32 down to 13 while riding; it stays when the rider is on foot |
| pokes | c1 `menu.szx` | 4 275 | the four ZXDB POKEs at START | the clock frozen at 00.0 (60250,0); the FUEL bar not redrawn (57276,201 and 57318,201, `RET` at `$DFBC` and `$DFE6`) while `$D77D` falls as in fuel; 49433,81: no change seen |

Not reached yet: fuel running out (the riders got stuck before; what an empty tank does is known only from the code,
stage 3); trail 2 onwards ridden without a POKE beyond distance 898 (the bot's actions all failed there).

### 6.1 The screens

From the recordings above, named `<recording>-<frame>-<moment>.png` in `docs/img/play/`.

**The load and the menu (c1, 48K, signal speed).**

| | |
| --- | --- |
| ![the BASIC loader, frame 582](docs/img/play/c1-000582-basic.png) | ![the loading screen, 3 282](docs/img/play/c1-003282-screen-loading.png) |
| ![the menu, 14 657](docs/img/play/c1-014657-menu.png) | ![trail 1, the start line, 14 821](docs/img/play/c1-014821-start-line.png) |
| ![trail 1 riding, 15 419](docs/img/play/c1-015419-c1.png) | ![after TIME OUT, the menu, 20 897](docs/img/play/c1-020897-c1.png) |

**The menu and the controls (menu).**

| | |
| --- | --- |
| ![TWO PLAYERS, 63](docs/img/play/menu-000063-two-players.png) | ![player one: KEYBOARD or KEMPSTON, 126](docs/img/play/menu-000126-player-one.png) |
| ![player one's key table, 160](docs/img/play/menu-000160-keyboard-table.png) | ![the table redefined Q A O P M, 305](docs/img/play/menu-000305-table-M.png) |
| ![player two: KEYBOARD or SINCLAIR, 339](docs/img/play/menu-000339-player-two.png) | ![player two's table H J K M B, 518](docs/img/play/menu-000518-p2-table-done.png) |

**Two players (kb).**

| | |
| --- | --- |
| ![the split screen, both mounted, 240](docs/img/play/kb-000240-mounted.png) | ![both on trail 2, 4 002](docs/img/play/kb-004002-ride.png) |
| ![player two's high-score entry, 8 260](docs/img/play/kb-008260-after.png) | ![trail 1: the rider walking back to the ATV (trail1), 1 967](docs/img/play/trail1-001967-ride.png) |

**The six trails (warp, the distance POKEd near each finish).**

| | |
| --- | --- |
| ![trail 1 SAND DUNING, 793](docs/img/play/warp-000793-trail1-ride.png) | ![trail 2 GRASSTRAKIN, 1 963](docs/img/play/warp-001963-trail2-ride.png) |
| ![trail 3 ICEBERGS, 3 215](docs/img/play/warp-003215-trail3-ride.png) | ![trail 4 PYRAMIDS, max 40, 4 445](docs/img/play/warp-004445-trail4-ride.png) |
| ![trail 5 TROPICANA, max 50, 6 200](docs/img/play/warp-006200-trail5-ride.png) | ![trail 6 SWAMP, max 50, 7 918](docs/img/play/warp-007918-trail6-ride.png) |
| ![the trail-number screen dissolving in, 1 295](docs/img/play/warp-001295-trail2-name.png) | ![trail 2's start line, 1 695](docs/img/play/warp-001695-trail2-start.png) |
| ![the finish of trail 6: EXTENDED PLAY, LAP TIME, 9 172](docs/img/play/warp-009172-trail6-end.png) | ![the second round: trail 1 with max 30, 9 946](docs/img/play/warp-009946-trail1-ride.png) |
| ![the name entry, "BC" entered, 16 589](docs/img/play/warp-016589-name-abc.png) | ![the new high-score table, 17 756](docs/img/play/warp-017756-after.png) |

**The POKEs (fuel and pokes, both frame 2 310, fuel 13).**

| | |
| --- | --- |
| ![no gauge POKE: the bar shows 13 (fuel)](docs/img/play/fuel-002310-fuel-13.png) | ![the gauge POKEs: the bar stays full (pokes)](docs/img/play/pokes-002310-fuel-13.png) |

### 6.2 Found while recording

- A crash throws the rider off; he gets up and walks; fire next to the ATV jumps him on (`work/stage1/mount.py`:
  from `x/crash1.szx` he mounts from x `$30` to `$48` and not from further right). On a dune he cannot walk up, and
  the walk-back rule of `ride_smart` (left while x > `$46`) leaves him stuck (trail1 from frame 1 967).
- Two players ride at once, not in turn: the screen is split (kb). How a pass serves both records is stage 3.
- ZXDB's POKE names do not match what the bytes do: 60250,0 ("Infinite Lives") stops the clock: it is the `$01`
  of `ADD A,$01` at `$EB59` in the tick `$EB53`; 57276,201 ("Infinite fuel") puts a `RET` at `$DFBC`, just after
  `LD A,($D77D)` (the fuel) at `$DFB9`, and 57318,201 ("Infinite Time") a `RET` at `$DFE6`, the first instruction of
  the routine after it; with both, the FUEL bar is no longer redrawn and stays full while `$D77D` still falls
  (recording pokes against fuel at frame 2 310). 49433,81 writes `$C119`, inside a buffer the game writes in play
  (`$BDEF-$C190`, 2.1): no effect was seen.

## 7. Review
