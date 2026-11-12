# Switchblade: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number. The
recordings made from the tape load it at signal speed (fast and turbo tape off; the game's loader at `$FF00` is a
copy of LD-BYTES, not the ROM's, so the trap would not catch it). The menu and gameover recordings start from
`work/stage1/explore/loaded.szx`, the menu after c1's load (128K, frame 15 700 of a signal-speed load,
`work/stage1/explore1.py`). The rzx recordings play the RZX Archive run (48K) and load no tape.

## 0. The medium

### 0.1 The files

`orig/Switchblade.tzx.zip` is ZXDB download 31610, copied unchanged; its hashes and the member's are in the
[README](README.md). The member is unpacked in `work/stage1/media/switchblade.tzx`; the other copies sit in
`work/candidates/<source>/` (`x/` holds the unzipped ones). The instructions are
`work/candidates/docs/Switchblade.txt` (ZXDB's text, md5 as ZXDB gives it).

### 0.2 The release check

ZXDB 5089 (`zxdb.sqlite` v1.0.242: `entries`, `releases`, `downloads`, `authors`, `contents`) gives the authors
(Jeff Calder; John Smyth, graphics; Ben Daglish, music), Gremlin Graphics 1991 at £9.99 (tape) and £14.99 (disk), the
GBH re-release at £3.99, the machine "ZX-Spectrum 48K/128K", and the compilations that carry the demo (Your
Sinclair 63, MicroHobby 210). Each copy's blocks were listed with `python3 tools/tzxblocks.py list FILE` and compared
byte for byte with the original's (`work/stage1/bdiff.py`, `work/stage1/blocks.py`); the table is in the README:

- **The original**: the Gremlin TZX (ZXDB 31610 = WoS = TOSEC 45124, the same file).
- **GBH**: the same six blocks; the TZX files differ in 7 bytes, all pause lengths.
- **The TAP** (ZXDB 31611, TOSEC 45129): the loader patched to the ROM's edge loop (`JP $0562`), the data blocks
  unchanged.
- **TOSEC `(128K)[a]`**: 27 bytes of the 37 537-byte block differ from offset 5579: the high-score names.
- **TOSEC `(48K-128K)[a]`**: `$C9` for `$3A` at offset 10 958 of the same block (`$954A`), a cheat.
- **The hacks** (Ramsoft's trainer, Sorokin, Sukin, Nikitin, the Pokes trainer) re-save the original blocks with
  headers; Saposoftware and Atossoft re-pack them; the YS demo is another program (a 24 964-byte block).

A name search of the NAS (`WDC14Tb-3/Consoles/ZX Spectrum`, 300 s, `work/stage1/nas-find.txt`) found nothing.

### 0.3 The load

c1 loads the tape on a 128K with the 128K menu's Tape Loader at signal speed: the BASIC's code runs at frame 710,
stage 2 at 1345, the jump into the game (`JP $4000`) at frame 15 503, the menu is on screen by frame 16 008. The
blocks, the loader, the paging test and the bootstrap: [doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block).

### 0.4 The machine: 48K and 128K

One tape for both. Stage 2's `$618E` tests the paging; a 128K gets block 6 in bank 4, the bootstrap's hooks
(`$5CFD`, `$A6EF`, `$A76F`, `$A75C`, `$5C9A`) and the 162-byte music glue at `$853F` (doc 3.1). What bank 4 holds
(`work/mkgame/bank4.bin`): the AY music player (`LD BC,$FFFD` at `$D3C7`, `$DB27`, `$DC2D`, `$DD53`, `$DEC2`,
`$DF7C`; `OUT (C),A` at `$D3CD`) and its tunes, and the intro story's pages ("...THE NIGHT BLED CRIMSON",
"I AM HIRO, THE LAST OF THE BLADEKNIGHTS. I MUST REBUILD THE FIREBLADE, AND BRING THE DAWN...", `$D514-$D862`).

The RZX run is a 48K recording: its start snapshot (the menu, PC `$6A91`) equals c1's 128K memory at the menu except
322 bytes (`work/stage1/rzxprobe.py`), nearly all of them `$853F-$85E0` (the music glue: absent on the 48K), the
three hook sites `$A6F0`, `$A75C`, `$A770`, `$5B00` and the stack areas. The game program is the same on both.

## 1. Interrupts and timing

**The mode.** The bootstrap (doc 3.1) sets `I` = `$FE`, fills `$FE00-$FEFD` with `$FD`, puts `JP $8456` at `$FDFD`
and selects `IM 2`: every vector reads `$FDFD`. c1's play state (`work/stage1/c1/end.szx`, `snapinfo.py`) has IM 2,
`I` = `$FE`, interrupts on, `SP` = `$5BF6`.

**The handler** `$8456` (`sna2skool.py -H` over `c1/end.szx`, `work/stage1/dis/end.skool`):

| Address | What it does |
| --- | --- |
| `$8456` | `PUSH HL, DE, BC, AF, IX, IY` |
| `$845E` | `LD A,n` / `OR A` / `CALL Z,$8472`: the operand `$845F` is a flag; 0 in play (`$5CF4`), 1 on the high-score and game-over screens (`$A747`, `$A842`) |
| `$8464` | `CALL $853F`: the music (on a 128K the glue to bank 4) |
| `$8467` | `POP` the registers, `EI`, `RETI` |
| `$8472` | the game tick: a frame counter at `$8473`; for the ten actors (one 256-byte page each, `$5D00-$66FF`, `H` = `$5D` to `$66`) whose byte +`$02` has bit 0 set: the timer at +`$1D` counted down, and the 16-bit timer at +`$1E` counted down unless paused, setting bit 5 of +`$10` when it reaches 0; the P key (`IN` from `$DFFE`, bit 0) sets the pause flag `$664C` bit 7; then the input read `$8529` |

`python3 $RS interrupts --work work/stage1/c1` over c1's L1 (18 627 frames, most of them the load, under `DI`):
1075 + 1539 entries through `$FDFD` (two tails), 6680 and 5981 T an entry, 0.5 % and 0.7 % of the CPU; `$853F` on
all 2614 entries from frame 16 013 (the menu) on, `$8472` on 975 entries, every frame of play (frames 17 652 to
18 626).

**The main loop** `$8DFE` (entered by `JP $8DFE` at `$5CF7`):

| Address | What it does |
| --- | --- |
| `$8DFE` | `LD SP,$5C00`: the stack is reset on every pass |
| `$8E01` | for the nine actors `$5D00`-`$6500` (`B` = 9, `INC H`): if byte +`$02` bit 0 is set, `CALL $8E2B` (the actor's update) |
| `$8E0E` | `$6652` bit 7 (the game over or the end): `JP $5C45` |
| `$8E15` | `$664C` bit 7 (the pause): `CALL $6682` |
| `$8E1C` | `$79FF` non-zero: `CALL $66B6` |
| `$8E23` | `CALL $FF01`, `CALL $FF64` (the code copied over the loader), `JR $8DFE` |

There is no `HALT` in the loop: it runs free. c1's L1 counts 25 068 passes (block `$8DFE`) and 28 339 actor updates
(`$8E2B`) in the 975 frames of play (17 652-18 626): about 26 passes a frame. An actor's work in `$8E2B` waits on its
own state (`BIT 0,(IY+$20)` at `$8E30`), so most passes do little; the per-frame count over a long window of the RZX
run is measured by `tools/rzx_passes.py` (below).

`PYTHONPATH=$SKOOLKIT_VENV/lib/python3.12/site-packages python3 tools/rzx_passes.py work/candidates/rzxarchive/switchblade.rzx work/stage1/passes.tsv --stop 30000`
 counts the fetches of `$8DFE` in
every frame of the RZX run (48K; frames as the RZX counts them, one per interrupt). Over frames 1500-30 000 (play from
frame 1473): 362 027 passes in 28 500 frames, 12.7 a frame on average, from 0 to 49 in one frame. 8232 frames start
no pass: a pass then runs longer than a frame. Of the runs of frames with no pass, 3065 last one frame, 809 two, 258
three, and 44 last 10 frames or more, from 10 to 72: 31 of those 44 begin within 3 frames of a room change (the room
variable `$6BDD` in `work/stage1/rzxtrace/trace.tsv`): the room is built while the loop waits. **The heaviest frames**
are those room builds: 72 frames without a pass from frame 17 393 (the entry into room 31) and from 22 203; eleven room builds take 60 to
72 frames. The other 13 stalls of 10 frames or more (10 to 27) start away from a room change: not explained in
stage 1.

## 2. Static pass over the medium

Stage 2.

## 3. The stages and the packers

No packer: the stages are the BASIC's code, stage 2 and the bootstrap (doc 3.1).

## 4. The medium from source

Stage 4.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| `analysis build` of a session recorded during `rzx_playback` fails: "the recording did not load on the analysis instance: this machine cannot take the session: device rzxplayback" (rzx-a, rzx-b, rzx-c have a TTD but no L1) | open; worked around: the rzx recordings are read with `time_travel` and SkoolKit's rzxplay (`tools/rzx_trace.py`, `tools/rzx_passes.py`), the L1s come from the keyed recordings | |
| An `analysis build` call with `wait` 30000 on a 72 000-frame session outlived the HTTP timeout (120 s); `tools/rec_rzx.py` then closed the instance and the TTD of the first rzx-a was lost | the case's tools now dump the TTD before the build and poll the status | |
| `rzx_playback seek` to frame 130 000 timed out | unrecorded `run_frames` from the start instead | |

## 6. The game

### 6.0 The recordings

Every recording keeps `session.ttd`, `record.json` (its plan, moments, POKEs), `end.szx` and `screens/`; the keyed
ones (`tools/record.py PLAN`, input scripts `tests/inputs/NAME.txt`) also `l1.json`. The rzx ones (`tools/rec_rzx.py`,
`tests/inputs/rzx-*.txt`) have no L1 (section 5); they are read with `tools/rzx_trace.py` (rooms, lives, energy per
frame, `work/stage1/rzxtrace/trace.tsv`) and `tools/rzx_passes.py`. All are in `work/stage1/rec/` unless named.

| Name | Machine, start | Frames | POKEs | What it reaches |
| --- | --- | ---: | --- | --- |
| c1 (`work/stage1/c1/`) | 128K, power-on | 18 627 | none | the tape menu, a real load of the original (doc 3.1), the title and menu (16 008), the intro, play from 17 651 in room 4; `$8472` x 975 |
| c48 | 48K, power-on | 23 151 | none | the 48K load, the game entered at 13 278, the title and intro loop with the 48K effect player; play is not entered (the RZX covers 48K play) |
| menu | 128K, c1's menu | 18 060 | none | option 1 (keys), the title's music / FX toggle (left: the note, right: FX), play, pause (P), the quit, the high-score table and the title cycle; `$8472` x 3406 |
| opt2 | 128K, c1's menu | 2 435 | none | option 2 (Sinclair 1, 2, 4, 5), the intro, play: right, left, up, fire, the quit back to the title |
| opt3 | 128K, c1's menu | 2 435 | none | option 3 (Kempston), the same moves and the quit |
| opt4 | 128K, c1's menu | 2 435 | none | option 4 (Protek / cursor 5, 8, 7, 0), the same moves and the quit |
| deaths | 128K, c1's menu | 7 829 | two, fell into the intro and were reset by the game start | play with enemies and hazards: lives 05 to 04, 03, 01 on the status line (screens 2309, 2869, 3429, 3989); `$9615` x 39 |
| gameover | 128K, c1's menu | 9 849 | `$664D` = 0, `$6642` = 1 at frame 1869 | a death with no life left: GAME OVER (about frame 2429, `$5C42` x 1), the title, the high-score table without an entry, fire restarts the intro |
| rooms | 128K, `probe/play0.szx` (play, room 4) | 3 650 | 16: the map row, column and room (`$69DF`, `$69E0`, `$6BDD`) | walked left through rooms 3 and 2 into room 1; written into rooms 11, 14 and 18; the chain stopped at room 0 (a failed lookup) |
| rzx-a | 48K, the RZX Archive run, frames 0-48 000 | 48 000 | none | the run's first part: 35 rooms first entered (to RZX 47 000), lives 5 to 3 |
| rzx-b | 48K, RZX frames 47 000-95 000 | 48 000 | none | 36 more rooms (to 94 000), lives 3 to 2, the score (RZX 72 000: 00092060) |
| rzx-c | 48K, RZX frames 94 000-142 989 | 48 989 | none | 37 more rooms, EXTRA (lives 1 to 2 at 128 606), Havok in room 123 (135 605), the end text (about 140 000), the high-score entry (142 000), the title (142 500); finished with no desync |

Together the RZX run enters 108 rooms, the rooms recording adds 1, 2, 3, 11, 14 and 18: 114 of 127. Not entered:
12, 13, 19, 21, 36, 47-50, 52, 55, 91, 92 (doc 2.4). Sound: no audio was played; every 128K recording runs bank 4's
AY player (`OUT (C),A` at `$D3CD`: 165 607 times in menu, 86 052 in deaths, 108 268 in gameover, 40 150 in rooms,
26 714 in opt2, from the L1s) through the glue at `$853F`, called once a frame (`$853F` x 18 055 in menu's 18 060
frames); the title's toggle picks music or effects (menu). The 48K effect player at `$853F` runs in c48 and the RZX run.

### 6.1 Screens

[docs/img/play/screens.png](docs/img/play/screens.png) (`tools/fig_sheet.py`): c1's menu, title, intro and the first
room in play; from the RZX run (SkoolKit's `rzxplay.py --stop N`, `work/stage1/rzx/`) a room of the Undercity,
Havok in room 123, the end text "THE DAWN HAS COME AND MY WORLD IS SAFE, FOR NOW.....", the high-score entry and the
title after it. Every recording's own screens are in its `screens/` folder.

![The menu, the intro, play, Havok, the end](docs/img/play/screens.png)

The first map, [docs/img/maps/map-rzx.png](docs/img/maps/map-rzx.png), is drawn from the image's room tables, each
room as the RZX run last left it ([doc 2.4](docs/02-architecture.md#24-the-map)). The first sprite sheet,
[docs/img/sprites/from-screens.png](docs/img/sprites/from-screens.png), is cut from RZX screens (Hiro, Havok, a
shot): the graphics are not plain bitmaps in memory (the rooms are 3-bit codes, NOTES), so the sheet from the data
waits for stage 2.

![Hiro, Havok and a shot, cut from the RZX screens](docs/img/sprites/from-screens.png)

### 6.2 The images

`tools/image.py` gives the image as loaded (`work/mkgame/original.bin`, `bank4.bin`, at the `JP $4000`); c1's menu
(`work/stage1/explore/loaded.szx`, frame 15 700) and c1's end in play (`work/stage1/c1/end.szx`, frame 18 627) were
read with SkoolKit's `Snapshot` (banks 5, 2, 0 as the 64 K view):

| From, to | `$5B00-$FFFF` | Where | Screen | Bank 4 |
| --- | ---: | --- | ---: | ---: |
| as loaded, the menu | 4621 bytes | `$5B00-$5BA6` (the stack), `$5BCB-$6B4C` (the copy from `$4146`), `$83C6-$83C7`, `$853F-$85E0` (the music glue), the hooks `$A6F0`, `$A75C-$A75E`, `$A770`, `$FDFD-$FFFF` (the vectors, the code from `$5093`) | 4307 | 260 |
| the menu, play | 4564 bytes | `$5B01-$5BFF` (the stack), `$5D00-$7047` (the actor pages, the globals, the map buffers), self-modified operands (`$83C6`, `$8453-$845F`, `$8473-$8474`, `$850D-$853A`, `$88AE`, `$8C13`, `$8D27-$8D2E`, `$95B4`, `$9BA3`, `$A74B`, `$A7B5` and others) | 3780 | 181 |

Bank 4 changes a little in both (the AY player's variables). The levels: the map tables at `$7048-$70EE`, the rooms'
3-bit maps read from `$D5B4-$FB21` (`$8BC8`); the objects and the state variables in 6.3.

### 6.3 The state variables and the POKEs

| Variable | Address | Witness |
| --- | --- | --- |
| map row, column | `$69DF`, `$69E0` | `$9560-$95B0`: Hiro's Y (`$5D00`) at `$A0` or `$EC` steps the row, his X (`$5D01`) at `$9E` or `$FA` the column; walking right from `work/stage1/probe/play0.szx` takes `$69E0` from 3 to 4 |
| room | `$6BDD` (1-127) | written at `$95D8` from the lookup `$95F9`; play0 room 4, after the walk 5; the RZX trace (`tools/rzx_trace.py`) passes 108 rooms |
| Hiro | actor page `$5D00`: Y +0, X +1, flags +2 (bit 0: active), kind/state +`$1C`, timers +`$1D`, +`$1E` | the handler `$8472`, the main loop `$8E01`; the other actors at `$5E00`-`$6500` |
| energy | `$6642` (`$20` at the start) | `$9615`: `SUB C`; at zero or below, a life |
| lives | `$664D`, BCD | `$9649-$9651`: `SUB $01` / `DAA` / `JP M,$5C42`; the RZX trace: 5 at frame 1473, 4 at 20 649, 3 at 32 490, 2 at 65 132, 1 at 119 128, 2 at 128 606 (EXTRA), 1 at 132 358 |
| score | `$6653-$6656` BCD, `$665B-$6662` the digits as text | the RZX at frame 72 000 (`work/stage1/rec/rzx-a-lost/end.szx`): `00 09 20 60`, "00092060", on screen 00092060 |
| pause | `$664C` bit 7 | the handler reads P (`$84B1`) and sets it; the main loop calls `$6682` while it is set |
| end | `$6652` bit 7 | the main loop's `JP $5C45` (`$8E0E`) |

The POKE files (decimal addresses; two full files, `work/candidates/pokes/Switchblade (1991)(Gremlin Graphics).pok` and `work/candidates/zxdb-entry/*.pok`, and ZXDB 5089's one-line file), each checked against this release's code:

| Cheat (file) | POKE | At that address | Result |
| --- | --- | --- | --- |
| Invincibility (both full files) | 38421 (`$9615`) = 201 | the first instruction (`LD C,A`) of the energy loss | `RET`: no energy lost (from the code) |
| No interactions (both) | 38913 (`$9801`) = 201 / 46 | the first instruction (`LD L,$1C`) of a routine called from `$96F7`, `$96FC`, `$9856` | `RET` (on) or `LD L,n` back (off) |
| Infinite Lives (both) | 41501 (`$A21D`) = 0 | the operand of `LD A,($6BE1)` (`$A21C`) | does not fit this release |
| Infinite Energy (both) | 41469 (`$A1FD`) = 201 | the operand of `LD A,($6AE9)` (`$A1FB`) | does not fit |
| Infinite Lives (ZXDB 5089 `.pok`) | 38475 (`$964B`) = 0 | the high byte of `LD HL,$664D` (`$9649`) | does not fit; in this release `$964E` (the `$01` of `SUB $01`) = 0 does it (from the code) |

The gameover recording sets the variables instead (`$664D` = 0, `$6642` = 1), noted in its `record.json`. The deaths
recording witnesses the loss of lives without POKEs (6.0), the rooms recording the room variables: writing `$69DF`,
`$69E0` and `$6BDD` and walking out of the room builds the room named.

## 7. Review

Stage 1 ends here; the review comes with the documents.

