# TODO

The owner's plan for this repository: the games to reverse, in order, and the ports planned from them. How a case is
done is in [AGENTS.md](AGENTS.md); this file says only what is next.

## The reverse queue

| # | Game | Notes |
| --- | --- | --- |
| 1 | OCP Video Pool | complete 2026-11-09 ([case](games/video-pool/README.md), doc 14 the UKNC port) |
| 2 | Chuckie Egg | complete 2026-11-10 ([case](games/chuckie-egg/README.md)) |
| 3 | Tujad | stage 2 ([case](games/tujad/README.md)); ZXDB 33911 (the POKE file's 5448 is another id) |
| 4 | SimCity | |
| 5 | Earth Shaker | our own reverse; Bedazzle's disassembly (github.com/Bedazzle/Earth-shaker) is not a source of names, compare with it at the end at most |
| 6 | Battle Command | ZXDB 451 |

## Planned ports

| Game | Target | Document |
| --- | --- | --- |
| OCP Video Pool | UKNC; possibly BK-0010 / BK-0011M and Soyuz-Neon | `games/<case>/docs/14-porting-to-uknc.md` |

The porting document follows AGENTS.md section 4.0 "By port target". What it must address for each target (the machine facts here are leads from memory; the document checks each one against the machine's documentation or an emulator before it relies on it):

| Target | What the document must address |
| --- | --- |
| UKNC (Elektronika MS-0511) | the PDP-11 central CPU (K1801VM2) and the peripheral CPU that owns the video and sound; the three-plane video memory in the peripheral CPU's space, written through its ports or by a peripheral-CPU program; the channels between the two CPUs; which work runs on which CPU, and how they sync per frame |
| BK-0010 / BK-0011M | the K1801VM1 at 3-4 MHz, no multiply; the 256x256 two-bit or 512x256 one-bit screen in main memory; the 32K or paged 128K budget; the beeper or AY add-on; the timer |
| Soyuz-Neon (PK-11/16) | the CPU: N1806VM2, the CMOS version of the K1801VM2, functionally equivalent (not the K1801VM3 this lead first said; Wikipedia "1801 series CPU" <https://en.wikipedia.org/wiki/1801_series_CPU> and Cyclowiki "Союз-Неон ПК-11/16" <https://cyclowiki.org/wiki/%D0%A1%D0%BE%D1%8E%D0%B7-%D0%9D%D0%B5%D0%BE%D0%BD_%D0%9F%D0%9A-11/16>, Video Pool doc 14.9), so the UKNC's VM2 timings apply; the clock to verify (Cyclowiki 8 MHz, Wikipedia 5 MHz nominal); 1-4 MB of RAM; its video modes and palette; what of the BK or UKNC plan carries over |

## Kit gaps

Found by the cases and worked around there; the status says whether `kit/` fixes it now:

| Gap | Found by | Workaround | Status |
| --- | --- | --- | --- |
| `game_part` does not pass `no_entries` | Video Pool stage 2 | the game's `case.json` used `"mode": "blocks"` | fixed: `case.json` takes `no_entries` and `entries_in_code`; Video Pool's `case.json` says `"no_entries": true` (the same sources) |
| a data-line comment inside `@res` that wraps to its own line breaks the INCBIN substitution, the image shifts | Video Pool stage 2 | shorter comments | fixed: the wrapped lines go with the data lines. The shortened Video Pool comments are not recorded anywhere, so none was lengthened again; the stray wrapped tails in Moon Patrol (`hiscores.asm`) and the three Zynaps cases (`texts.asm`) are gone |
| `@equ` with a size is applied after `@isub` and rewrites its operands | Video Pool stage 2 | none needed yet; watch for it | fixed: `@equ` and `@var` names skip the `@isub` instructions. It had struck: Video Pool `@isub $94C5 LD HL,$4010` was written `Screen+16`, now `$4010` |
| a field label on a data entry's first address (`PocketTurn` on `PlayerVars $9F43`) never reaches an operand: the entry's label wins | Video Pool sources | `@alias PocketTurn PlayerVars` and one `@isub` per instruction (ten) | fixed: a second label after the entry's, and the `LD`s through memory at that address name the field (docs/ann-format.md 3.3); the workaround removed (it had missed an eleventh, `$9DB0`). New first-field labels in Exolon, Nether Earth GS, NE ZS Edition (`menu99`) and eight more in Video Pool |
| `kit/routine_anim.py --pc` takes one range: an animation cannot follow a routine and its callees elsewhere | Video Pool DrawBall | the callees left out (BallRedraw) | fixed: several ranges (`--pc A-B,C-D` or repeated); Video Pool's DrawBall animation redrawn with BallRedraw and RedrawBall |
| `tap.py basic` sets p2 to the whole block length (a BASIC block with a variables area gets the wrong header) | Chuckie Egg stage 2 | the case's `tools/tape.py` writes the header | fixed: `basic:NAME:LINE:FILE[:PROGRAM]` takes parameter 2 from the block itself, the lines up to the first byte that is no line number ($40 or more: the variables), with an optional override; Chuckie Egg's `tools/build.sh` writes the tape with `kit/tap.py` (program length 18, the string array `a$` after it), its `tools/tape.py` keeps only `--orig` |
| `LD BC,nn` operands are not turned into labels | Chuckie Egg stage 2 | none (the operand stays a number) | fixed: `LD BC,nn` into an entry is `Label+offset` when the next instructions read or write through `(BC)` (`bc_is_pointer`); ports, counts, offsets and byte pairs stay numbers, `"operands": "wide"` takes every one, `"narrow"` none (docs/ann-format.md 3.4). A pointer handed to a routine still needs `@isub` (Chuckie Egg keeps `$AA9A`; its three `@isub`s on labels' own addresses dropped, SkoolKit names those; Elite's `LD BC,ShipSlots+$001A` (hyperspace.asm, then `LD (BC),A`) is the one new name across the cases) |
| `@equ` applies to every operand in its range, not one instruction | Chuckie Egg stage 2 | narrow ranges | fixed: `@equ $ADDR NAME [N] at $I,$J` names the operands of those instructions only; an `at` address that is no instruction fails (docs/ann-format.md 2, 8) |
| the module name `game` is refused | Chuckie Egg stage 2 | another module name | fixed: `@module game` is written to `game-module.asm` (the top file keeps `game.asm`), in `mkgame.py` and `sig_add.py` |
| `kit/routine_anim.py` and `kit/memanim.py` set the picture width themselves: up to 2566 px (Chuckie Egg: all 25 `docs/img/routines/*.gif` are 1102-2566 px, `play/tape-block4.gif` 1102 px), wider than the 1050 px figure limit; the case cannot choose it | Chuckie Egg docs (ceA, ceD) | none: the animations stay at the kit's width | fixed: both draw `--width 1050` by default in a compact layout (memory map and view stacked on the left, the listing beside them; memanim puts the screen under the map), titles and labels wrapped; `--layout wide` is the old picture. Chuckie Egg's 25 `docs/img/routines/*.gif` and `play/tape-block4.gif` redrawn from their captions' commands, the `anim_compact.py` step dropped from the captions |
| `kit/fig_budget.py` draws 900 px wide, not 1050, and its `--note` line is cut at the bottom of the panel | Chuckie Egg doc 2 (ceA) | the note left out, the command in the caption | fixed: `--width` (1050 by default), the notes and summary lines wrapped, the height fitted to them; Chuckie Egg's `budget-modules.png` and `budget-routines.png` redrawn |
| a large `Label+offset` takes an `@equ` base before the data entries exist (`LD HL,data_96FE+Screen+1109` for `$DB53`) | Tujad stage 2 | the data entries written first | open |
| port constants inside an `@equ` range (`LD BC,$FEFE` became `Im2Table+254`) | Tujad stage 2 | `at` lists | open: warn when an `@equ` matches an `LD rr,nn` later used by `IN`/`OUT` |
| `mkgame --install` leaves a resource's stale `.bin` when the case's res_formats writes the editable form | Tujad stage 2 | the case's `install()` removes it | open |
| a `w` entry inside a shared `@res` loses its DEFW labels | Tujad stage 2 | none needed (relative offsets) | open |

## For unreal-ng

- Chuckie Egg: the game's state after K frames depends on how they are split into `control_execution run_frames` calls (two faults, reproduced with probes): [docs/unreal-ng-run-frames-faults.md](docs/unreal-ng-run-frames-faults.md) (the probe scripts stay in the case's untracked `work/stage2/`).
- Tujad: a TTD session cannot record an RZX playback, and an RZX's inputs replayed from its saved state drift from the game within frames (timing, the counter `$6366`, the random number): the stage-1 walkthrough was cut into 59 checked pieces (games/tujad/WALKTHROUGH.md section 5).
