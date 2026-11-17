# kit: the scripts every case shares

The case standard is [GUIDE.md](../GUIDE.md), the steps are [recipes/](../recipes/README.md). These scripts do the
work that is the same in every game; what is particular to one game (its packer, its resource formats, its bot)
stays in the case's own `tools/`.

They need Python 3 with Pillow, and an unreal-ng checkout for the access trace reader and `re_session.py`
(`tools/verification/analysis/` of the checkout: the kit uses them from there, it keeps no copy).
`mkgame.py` also needs SkoolKit (a virtualenv) and sjasmplus. `toolpaths.py` finds the three, and no script holds
a path of one machine:

| Tool | Given by (first found) |
| --- | --- |
| unreal-ng | `--unreal`, `$UNREAL_NG`, the `unreal-ng` submodule, a checkout near this repository |
| sjasmplus | `--sjasmplus`, `$SJASMPLUS`, `PATH`, a `sjasmplus/build/release/sjasmplus` checkout near this repository |
| unreal-qt | `--binary`, `$UNREAL_BINARY`, `cmake-build-agent-release/bin/unreal-qt` of that checkout |
| SkoolKit | `--venv`, `$SKOOLKIT_VENV`, `$VIRTUAL_ENV`, `.venv` here, `sna2skool.py` on `PATH`, `$UNREAL_NG/scratch/venv-skoolkit` |

`python3 kit/toolpaths.py sjasmplus|venv|unreal|binary|re_session [HINT]` prints the path (the cases' shell scripts
use it).

`re_session.py` (open a recording in an instance, build L1, export a draft, stop) is unreal-ng's, not the kit's: it
imports `corpus.py`, `mm_session.py` and the MCP client beside it and drives the unreal-qt of the same checkout, so a
copy here would drift from the binary. `python3 kit/rs.py ARGS` runs it from the checkout `toolpaths.py` finds
(`--unreal U` first to give one), so a case's commands name `../../kit/rs.py`, not a path set on one machine; the
`$RS` of the docs is that script. For `capture --inputs` it reads the input scripts first: a word that is no key fails
there with the line and the reason (`a.txt:12: "W,O" is no key: the keys are A-Z 0-9 ENTER SPACE CS SS and the
Kempston KF KL KR KU KD, keys held together separated by spaces ("W O") or joined by "+" ("W+O") ...`), not in the
emulator's `Unknown key 'w,o'`; a chord `W+O` (zx-reaper's form, which `mm_session.py` does not take) goes over as a
copy of the script in `W/inputs/` with the keys separated by spaces (`kitlib.capture_inputs`, `input_script`,
`plain_input_script`; `input_vars.py` reads `W+O` as W and O too); a script with no `N END` line is warned about
(`WARNING: a.txt: no "FRAME END" line: the script ends at its last event, frame 2542 ...`: it stops there silently). The check is the kit's: a `python3 $RS capture`
that runs unreal-ng's `re_session.py` itself (a `work/env.sh` that sets `$RS` to it) bypasses it, and a case's
wrapper that imports `re_session` (one that replaces `corpus.load`, Deflektor's `tools/rs_capture.py`) gets it by
ending with `rs.main(['capture', ...])` instead of `re_session.main()`.

`capture` takes four options of the kit's own, which `rs.py` takes out before `re_session.py` sees the rest, and
reads one of re_session.py's: `--snapshot S` with no `--model` gets the snapshot's own model (`kitlib.snapshot_model`:
an SZX's machine id, a `.z80`'s version and hardware byte, a `.sna`'s length), printed as `rs.py: --model 128K from
S`; re_session.py's default is 48K, where a 128K state does not load. A `--model` that differs from the snapshot's
is kept with a warning (MASK III's RZX segments ran its 48K states on the 128K and drifted). A case wrapper that
calls `re_session.main` itself does the same with `kitlib.model_from_snapshot(argv)` (MASK III's `tools/capture.py`):

- `--stop`: the instance the capture launched is stopped when the capture is done (`re_session.py stop`). Without
  it the instance stays up, as `re_session.py` leaves it, for `build`, `call` and `export` on the live recording; a
  batch of captures on one port base needs `--stop` (or a `stop` after each).
- `--expect STATE[@FRAME]` (repeat for several): the replay check. STATE is the live run's saved state (an SZX
  snapshot, or a dump of 65536 or 49152 bytes: `kitlib.memory_image`), FRAME the count of frames into the input
  scripts at which the live run saved it (the scripts one after another from the first one's frame 0, as
  `re_session.py` plays them; without `@FRAME`, the scripts' end). The capture stops there, reads its 64 K and
  compares: `replay check: L21.szx at frame 2097: identical`, or
  `2765 bytes differ ($4041-$404C, ...; first $4041 live 00 replay 0F, ...)`. The results go to
  `W/replay-check.json`, and a difference makes `rs.py` exit with
  status 3 once the capture's files are written. A bot that saves the state at each event and writes its keys from
  the previous save as a script gives both (Deflektor's `tools/play_levels.py`: `LNN.szx` at a level's start,
  `LNN.txt` ending 50 frames after the next level's start, so `--expect L(N+1).szx@(END - 50)`; its level 19
  differs, level 20 is identical).
- `--expect-ranges LO-HI[,LO-HI ...]`: the addresses compared (hex, inclusive; default `4000-FFFF`).
- `--tape-seek N` (with `--media`, a tape): the head goes to block N (`POST /tape/seek`, the emulator's block index,
  a TZX's text block counted) as soon as the tape is inserted, before `LOAD ""` or the 128 menu's Tape Loader runs,
  so the capture loads a later program of the tape, with the fast LD-BYTES trap on or off (Rex: side 1
  `--tape-seek 6` loads REX 2 alone, its image identical to `tools/parts.py`'s). The answer is printed and kept in
  `W/capture.json` `tape_seek`; a case wrapper that replaces `corpus.load` gets it too when it ends with
  `rs.main(['capture', ...])`. The seek waits until the tape reports block N (`kitlib.tape_wait`): with a TTD
  recording running, unreal-ng puts a tape in at the next frame boundary and a seek before it answers "Block N out of
  range" (R-Type stage 1, [docs/unreal-ng-run-frames-faults.md](../docs/unreal-ng-run-frames-faults.md)); frames run
  for that are printed and kept as `tape_seek_wait_frames` (0 when the tape is in at once).
- `--binary`: `capture` and `open` with no `--binary` take `$UNREAL_BINARY` (a case's `work/env.sh` sets it to its
  `BIN`) and pass it on (`rs.py: --binary B (UNREAL_BINARY)`); re_session.py's own default, the checkout's
  `cmake-build-agent-release`, only when the variable is unset. A `--binary` given is kept.

A case's own lab that puts a tape into a running machine and winds it (a level recording from a state: R-Type's
`tools/record.py` `tape_at`) calls `kitlib.tape_insert(s, path, block=N[, play=True][, settle=F])`: fast and turbo
tape off, `POST /tape/load`, then `kitlib.tape_wait` (polls `GET /tape` until `block_count > N`, with no frame run,
then one frame at a time, at most 10) and `POST /tape/seek`; `settle=F` runs exactly F frames first (a timeline that
ran a fixed number, R-Type's 2). It returns the frames run, the seek's answer, the tape's state and block.

A menu with a highlighted line (the item under the cursor shown by its paper colour) is driven by reading the
attributes, not by counting keys: `kitlib.paper_rows(attributes, paper, lo=0, hi=24, cells=3, ink=None)` gives the
character rows whose first `cells` cells have paper P (attributes: the 768 bytes at `$5800` or a `read(addr, n)`),
and `kitlib.wait_paper(read, step, row, paper, tries=40)` calls `step()` (a key press and a frame or two) until row R
has paper P, returning the steps taken (Enduro Racer's `tools/record.py`).

`rs.py interrupts` prints, after re_session's table, the kit's own length an entry from the same L1 (the handler's
own T-states plus its call callees' inclusive ones): re_session's inclusive count runs on past a handler that
leaves by a patched `JP` (Enduro Racer `$643C`: 676 717 T an entry, "968.3 % of the CPU"; the kit 11 357 T), and
`handler_time.py` measures every entry exactly over a trace window.

`rs.py call --tool TOOL ACTION ['{...}']` sends to any MCP tool on W's instance (re_session.py's `call` only to
`analysis`): `rs.py call --work W --tool time_travel seek '{"frame": 14114, "tinframe": 0}'`. `rs.py seek --work W
--frame F [--t T] [--image OUT.bin] [--json OUT]` cuts an image at a moment of the loaded recording (the 64 K Z80
view and the registers there); `--first-pc LO-HI` bisects frame F for the first T at which PC lies in the range (a
program's entry: ATV Simulator's c1, frame 14 100 T 17 980, `$FFFB` -> `$D6B0`, work/stage1/entryimg.py).

```bash
python3 ../../kit/rs.py capture --work work/stage2/rec/L20 --snapshot work/stage2/lv/L20.szx \
    --inputs work/stage2/lv/L20.txt --ranges 4000-FFFF --port-base 37490 --stop --expect work/stage2/lv/L21.szx@2097
```

The annotation file these scripts read is described in [docs/ann-format.md](../docs/ann-format.md) (every directive,
what the generator does with it, the part files); every file of a case and the command that makes it in
[docs/case-files.md](../docs/case-files.md).

## A case

| Script | Does |
| --- | --- |
| `case-template/` | the skeleton of a new case: README, WALKTHROUGH sections, the twelve documents with their figure lists, `case.json`, `src/game/game.ann`, `src/res/README.md`, `tools/build.sh`, a bytes-only `tools/res_formats.py` |
| `tapblocks.py list FILE.tap` | the blocks of a tape: lengths, header fields, the play time at ROM speed, checksums |
| `tapblocks.py list FILE.tzx` | the same for a TZX (by the `ZXTape!` magic): every TZX 1.20 block (`10`-`19`, `20`-`28`, `2A`, `2B`, `30`-`35`, `40`, `5A`), the loop blocks `24`/`25` of MakeTZX dumps included, the play time; a damaged file prints what it read and `stopped: block id ... at offset ...` (exit 1); `parse_tzx`, `tzx_seconds`, `tzx_describe`, `tzx_block_data` for a case's tools (Enduro Racer's `tools/tzxblocks.py` is a wrapper) |
| `tapblocks.py FILE.tap N OUT` | one block's data (a TZX: the data block's bytes, flag and checksum included) |
| `tap.py` | writes a tape of standard ROM blocks (the build's last step); a `basic` header's program length is the program without its variables, found as SAVE writes it (or given: `basic:NAME:LINE:FILE:LENGTH`) |
| `mkgame.py --case C` | `src/game/*.asm` from `game.ann` (`src/main`, `main.ann` in a case whose `case.json` names `"main": "main"`) ([format](../docs/ann-format.md)), the recordings' `l1.json` and the image `case.json` names; refuses to install unless sjasmplus gives the image's bytes |
| `mkgame.py --part F.json` / `--image BIN --org A ...` | any other code image the same way: a loader, a menu, a bank, an image of several segments or pieces ([part files](../docs/ann-format.md#5-parts-banks-and-pieces)) |
| `resinc.py` (a module) | the `.inc` of an `@res NAME.bin include` resource: `lines(items)` writes `DB` / `DW` / label lines (a word may be a label's name), `symbols(case)` gives the `.ann`'s names and each resource's inner labels by offset; `Symbols(case).add(ann, lo, hi)` writes and reads an address of an editable form as a name (`word($CCDA)` is `SharedModels+591`, `value()` the address again); the case's `res_formats.py build` calls it |
| `sprite_bank.py` (a module; `export` / `build` / `check` from the command line) | a sprite bank of "header + pixel rows" pieces behind a word offset table (a count byte, an optional length word, a word a number for each kind: `sprite` pieces with a header of named fields, `width` and `height` among them, then width x height bytes; any other kind, an attribute block: width, height, the bytes) as a res format: `export(data, **spec)` gives `{".png", ".csv"}` (each sprite at a place of its own, index 0 paper, 1 ink, 2 no pixel; the CSV a row a piece in byte order: kind, offset, numbers, place, the header fields, the bytes of attribute blocks, `bytes` rows for what no word reaches and the leftovers after the length word's end), `build(files, **spec)` the bytes from the two files alone; the spec (`kinds`, `fields`, `count_at`, `length_at`, `table_at`, `sheet`, `gap`) is the case's. ATV Simulator's `sprites/game` and `sprites/menu` |
| `cells.py` (a module) | sprite cells of no fixed stride (an attribute and 8 lines, or one marker byte for an empty cell) as a res format: `export(data, pieces(objects, base))` gives `{".png", ".csv"}` (each piece the object table points at drawn at a place of its own, index 0 paper, 1 ink, 2 no pixel; the CSV a line a piece in byte order: place, size, object numbers, an attribute a cell or `-`, and `bytes` lines for what no piece holds), `build(files)` the bytes from the two files alone; `empty` (`$36`) and `attr` (`first` / `last`) are kept in the CSV's first line. R-Type's `graphics/sprites` and `levels/levelN/sprites` |
| `ctl2ann.py DRAFT.ctl --out F.ann` | a first `.ann` from `re_session.py`'s `draft.ctl` (or an L2 export JSON) |
| `toolpaths.py` | finds sjasmplus, the SkoolKit venv, unreal-ng and its `re_session.py` (above) |
| `toolpaths.py build [BINARY]` | which unreal-ng commit a binary holds (`kGitCommit` of the build dir's `buildinfo.h`; the worktree's HEAD when the binary is newer than that commit) and whether it holds the fixes a recipe needs (`FIXES`: f13cee7da, the ended tape's last edge, recipe 02); exit 2 when one is lacking. `rs.py open` / `capture` print the same warning. Then the features a kit tool can use (`FEATURES`: `section_timer`, the native `analyze_performance section_timer`, 8a72caa95), by the name among the binary's strings: "has" or "lacks" (no error; `toolpaths.has_feature(binary, name)`) |
| `pass_time.py --start ADDR --end ADDR (--trace F.uatr \| --work W --window F:T-F:T \| --live (--work W \| --port-base P \| --launch) [--snapshot S] [--passes N \| --frames N]) [--budget-frames N] [--top 10] [--json OUT]` | each pass of a main loop timed, START to the first END after it, interrupt entries inside included, in T and as a share of N frames: from a trace (the recording itself), or live on a running machine with `run_until_pc` twice a pass (for a binary without `section_timer`; `--launch` starts `$UNREAL_BINARY` muted on the port base and stops it). `PT.live_passes(session, start, end, before=...)` lets a case set its keys between passes. ATV Simulator's `tools/pass_trace.py` and `tools/pass_time.py` use it |
| `copies.py L1 [L1 ...] [--min N] [--at / --src / --dst LO-HI] [--group] [--top N] [--listing LST] [--json OUT]` | the copy loops of an L1 (`dataflow.copies`: LDIR / LDDR and byte loops) with their frames: the instruction, its routine, source -> destination, length, direction, count, the first and last frame the copying instruction ran (the L1 keeps no frame a copy) and the loop's trips; `--group` a line an instruction (copies, runs, bytes moved, spans). What moves where at a program's entry (ATV Simulator c1: `$D7E0` moves `$F850-$FDFA` to `$5B00`, frame 14 100) |
| `pattern_sheet.py --routine ADDR L1 [L1 ...] [--image IMG --out OUT.png] [--reg HL] [--width-at 0 --height-at 1 --data-at 2 \| --size WxH]` | the graphics a draw routine was given: the bases of its L1 `patterns` (every L1 merged, printed with the routines, registers and L1s), and with an image a first sprite sheet, each base read as a header (width, height at the given offsets) and its pixel lines, or a fixed size; bases that are no header left out. ATV Simulator's `tools/sprite_sheet.py` (`$865F`, data at +4) |
| `handler_time.py (--trace F.uatr \| --work W --window F:T-F:T) [--exit ADDR] [--ann F.ann] [--json OUT]` | the length of each interrupt entry in a trace window, however the handler leaves: it ends where the PC is back at the interrupted address with SP above the pushed word (RET, RETI, a patched `JP nn`: Enduro Racer `$643C` -> `JP $6523`); `--exit` ends it at an address instead; the mean, least, most and a per-routine split. `rs.py interrupts` prints the kit's estimate from L1 beside re_session's (wrong for a JP exit) |
| `last_frames.py --work W [--reset F] [--frames 100] [--into W2] [--dry-run]` | the last N frames before a reset: the frame the ROM's `$0000` ran (from W/l1.json, or `--reset`), `rs.py build` over the N frames before it, then the calls into `$0000`/`$0008`/`$0038` from the game, the code first run in the window (the crash's path) and what ran last; `--l1 L1` alone reports from a built L1 |
| `rs.py ARGS` | runs unreal-ng's `re_session.py` with ARGS (`open`, `build`, `stop`, ...; above); checks `capture --inputs` scripts and splits their `W+O` chords; `capture --stop` stops the instance after it, `capture --expect STATE[@FRAME]` checks that the replay reaches the live run's state; `call --tool TOOL` sends to any MCP tool, `seek --frame F [--t T] [--image OUT] [--first-pc LO-HI]` cuts an image at a moment (above) |
| `z80sim.py` (a module) | SkoolKit's simulator for a case's tools: `run(memory, start, stop, registers)` gives the memory after the run, `simulator(memory, registers)` one for several runs. `CSimulator` (SkoolKit's C one, about 50 times faster) works on its own copy of the memory: read and poke through `sim.memory`, never the bytearray passed in (`python3 kit/z80sim.py --self-test` shows it); the pure Python `Simulator` works in that bytearray itself. SkoolKit is found as `toolpaths.py` finds the venv |
| `ann_names.py --case C [--ann F] [--names FILE] ADDR=Name ...` | names labels inside entries of `game.ann` (or F); `--names FILE` reads the pairs from a file, `ADDR=Name` a line or several on a line, `#` comments (a list of 101 names is one word as `$(cat names.txt)` in zsh) |
| `input_lint.py [--allow TAPE,POKE] SCRIPT ...` | checks input scripts before a capture: every word a key, and an `N END` line (without one a script ends at its last event silently); `--allow` skips a case wrapper's own lines (Rex's `TAPE`, `POKE`); exits 1 on any problem (`rs.py capture` runs the same checks) |
| `rzx_dump.py RZX --out OUT [--every N] [--mem-every N] [--snap F,...] [--no-dump] [--watch A,...] [--snap-on-change A] [--pc-log PC] [--stop FRAMES]` | an RZX played in SkoolKit's simulator, no instance: screens and 64 K samples (`OUT/screens.bin`, `mem.bin`, `index.json`), Z80 snapshots at frames or where a byte changed, the frames where watched bytes changed (`watch.json`), the frame and T-state of each port read at a PC (`pclog.json`: a pass's length), the keys each frame ended with (`inputs.json`); `--no-dump` drops only the screens and memory samples (watch, pc-log and snapshots still work) |
| `rzx_match.py LOG FROM REC [--bytes N] [--attrs N] [--window F] [--room ADDR]` | how long a recording made from an RZX state keeps to the RZX: each saved screen against the RZX log's (a case's `rzx_log.py`: `screens.bin`, `mem.bin`, `log.json`); exact ("in step with the RZX up to frame N"), and by a tolerance: within N bytes (sprites a few pixels apart), N attribute bytes, the closest RZX screen within F frames, the same room (the game's room byte in the recording's `snapshots/` and the RZX's `mem.bin`, within F frames): "in step by the tolerance (...) up to frame N; K of M screens" |
| `input_vars.py --work W --inputs S --start F` | the bytes that follow the held directions and fire over a scripted recording: a first guess at the player's coordinates (a 16-bit coordinate, or one that moves only now and then, scores low: confirm in the code that reads the controls) |
| `refdocs.py --case C` | docs 11 and 12 from `game.ann`, the parts of `ref_parts` and the recordings (below); doc 12 links `docs/img/routines/<Label>.gif` and every `<Label>-<what>.gif` |
| `check_docs.py --case C` | mermaid renders (every diagram in one `mmdc` run: one headless browser, not one a diagram; each on its own only when that run fails, to name the broken one), links and `#anchors` resolve (GitHub slugs), no `$` in prose, every figure in `docs/img` and its subfolders is linked; the resource READMEs (`src/res/README.md`, `src/res/**/README.md`) are read for their links too: a figure they link counts, a broken link of theirs is a problem; a link to docs 11 / 12 before `refdocs.py` wrote them says so (`not generated yet`), and `--no-refdocs` (stages 1 and 2) skips those links and counts them in the last line |
| `check_docs.py --repo` | the same for the repository's own documents: README, GUIDE, recipes, docs, kit |
| `code_addresses.py FILE.md` | puts hex addresses in prose into code spans |

`case.json` (the template's is the example; where each file of a case comes from: [case-files.md](../docs/case-files.md)):

| Key | Meaning |
| --- | --- |
| `main` | the main part's name: `src/<main>/<main>.ann`, `<main>.asm`, `work/mkgame/<main>.ctl`; `game` when absent, `main` for a program that is not a game (`software/<name>`), optional |
| `image` / `image_cmd` | the 64 K image as the loader leaves it; the command (run in the case) that writes it |
| `lo`, `hi` | the bytes of the image that are the game (hex; `hi` exclusive) |
| `device` | sjasmplus `DEVICE` |
| `bases` | L1 page -> Z80 base of each bank of the image |
| `read_builds` | the `work/<build>` whose instructions and data reads count; the only recordings mkgame reads with `code_builds` |
| `code_builds` | the `work/<build>` whose instructions count but not the reads (over a depacker's input), optional; a build in both lists is read once, as a read build (its witness runs counted once) |
| `no_roots` | builds of `read_builds` / `code_builds` (globs) read as a part file's `{"roots": false}`: a routine that is only the recording's root (a snapshot start's PC) is no entry, optional |
| `no_entries` | `true` (no recording's routine entries), or a list of builds (globs) whose routines make no entries while their instructions and reads count: a recording started from a snapshot, whose returns and jumps out of the routine it began in look like routine starts (Rick Dangerous: its 45 zone, spot, ending, 48K and integration recordings), optional |
| `same_bytes`, `overwritten` | as a part file's, with per-build forms: `same_bytes` a list of builds (only their instructions need all bytes the image's), `overwritten` items `[LO, HI, BUILD or [BUILDS]]` (that build's start state holds other code bytes there: its instructions, entries and witness runs there do not count, the walk is free; Rick Dangerous `["ABD8", "ABDB", "stage1/ending"]`), optional |
| `built` | `{NAME: PATH}`: resources the build makes (a loader stage, a player): the game's `INCBIN "res/NAME"` is installed as `INCBIN "PATH"` and NAME is not installed, optional |
| `dest`, `work`, `res_install`, `operands`, `mode`, ... | any key of a part file ([ann-format.md 5.2](../docs/ann-format.md#52-part-files)), optional |
| `ref_builds` | `[key, text]` of the builds docs 11 and 12 report first (each its own Runs row); the other recordings count after them |
| `witness_skip` | builds of `read_builds` / `code_builds` left out of the `.ann`'s witness counts, optional; `--fix-witness` drops these from the witness lines, and any build no list names any more ("left the lists"); a listed build whose recording this run did not load is kept |
| `witness_builds` | recordings that count in the witness lines only (a fuel failure, an armour test), optional |
| `witness_names` | `{build: name}` for a witness list: a windowed copy of a recording under its recording's name (Battle Command `{"stage1/c1g": "c1"}`), optional |
| `ref_parts` | part files (`"src/bank3/bank3.json"` or `[path, title]`) docs 11 and 12 cover after the game, a section each (a part of segments a section a segment with an `.ann`, "Title: segment title"), optional; a part file's `ref_builds` (else the case's) are its first builds, its other `l1` sources the others (`other_builds` overrides them; `[]` for none) |
| `ref_skip_moves` | `true`: doc 11's readers and writers leave out the block moves, the bytes an L1 loop copies (a read and a write stride of step 1 or -1 over as many bytes, 16 or more in a range: `LDIR`, `LDDR`, an in-place decryption; not an `LDIR` fill, whose destination is its source a byte on) or loads (a write stride alone whose store wrote code a recording later ran, an L1 arrival's writer: a tape loader, a depacker of code); doc 12's Reads and Writes keep them. A part file's own key for a part. Optional |
| `ref_load_end` | `{build: frame}`: the frame from which a recording that loads the game (`stage1/c1`) runs the game's image; its routines first run before it (a loader at the game's addresses) write no entry's "Written by" (Switchblade: the tape loader at `$FF00`, whose block writes fell to DrawMeter `$FF7C`); for mkgame's walk, a read build with a frame here reads only the bytes it still accessed from that frame on (L1 `byte_counts` `last_frame`: the ROM's RAM test and the tape load read every byte before; a part file's source: `load_end`), so the recording can be a read build (Rick Dangerous 2: `c1` 13 998, `c48` 14 243); a byte whose last reader (L1 `byte_use`) is the load's, an instruction that first ran before the frame and last ran in it or before, is not read either: its later accesses were writes (Enduro Racer: Mover's `LDDR` and BikeRoadPlace's writes to `$9ADA`), optional |
| `ref_read_end` | `{build: frame}`: a recording that crashes into the ROM at that frame (the ROM's `$0000`; `last_frames.py` finds it): mkgame takes its reads first made before the frame (by a reader first run before it) and its instructions first run before it, so the RAM test and the crash's path through data count for nothing (Enduro Racer `reset3`: 6759); refdocs leaves the recording out of docs 11 and 12 (L1's profiles cannot be cut by frame); give it `witness_skip` too to keep the witness counts, optional |
| `res_comments` | `true`: the row comments inside `@res` entries stay in the sources as comment lines before their `INCBIN` slice (every part of the case; a part file may set its own), optional |
| `overlay` | a buffer laid over code once play starts (`lo`, `hi`, `name`, `why`), optional |
| `header`, `data_note` | the first comment lines of `game.asm`; a sentence for doc 11, optional |

Every run checks the `.ann`'s `Witness: L1 N (builds)` lines of the code entries against the recordings: N the runs
of the entry's first instruction summed over `ref_builds`, `read_builds`, `code_builds` and `witness_builds` (less
`witness_skip`; a `ref_builds` recording with a window counts only inside it; a `same_bytes` or `"mode": "blocks"`
part only the runs of its own bytes, a source's `lo`/`hi` window bounding them; builds of one name summed as one: frame
windows kept inside the recording's folder, `stage1/c1/load`, are `c1`), the list the builds that ran it (`c1,
hiscore, rzx x29`; numbered builds of one family by name, a run of three or more as a range: `c1-c4`, `c1, c2, c4`,
a family that would take more than four items as one, `rzx x29`), and prints each stale line
(`witness: src/game/game.ann:134 $8040 PrintGlyph: L1 90100 (c1, rzx x32), the builds give L1 90104 (...)`);
`--fix-witness` rewrites them in the `.ann` (a name a build had before `witness_names` renamed it, its own name or
its path, is that build's: printed as "renamed (witness_names): c1g is c1" and rewritten; a range it wrote is read
back whatever the family's prefix, `load-l2-load-l5`, `sec-l2-s10-sec-l2-s12`), keeps a line that names a
recording it did not load, prints each
name it drops (`menu, search ran no instruction there`; an entry no build ran stays `L1 0 ()` with no such
clause, so a data entry is not said to run no instruction), lists the code entries left at `L1 0 ()` after it
(`witness: src/rex2/rex2.ann: 24 code entries at L1 0 () (no build ran them): 128 $97D2 WaitFire, ...`: the line,
the address, the name; a witness line that is alone on its line, `> Witness: L1 0 ().`, becomes
`> Known only from the code: no recording runs it.` instead), gives a code entry with no witness line (a new one)
its `> Witness: L1 N (builds).` after its description when the builds ran it, in any `.ann`, a fresh one with no
witness line yet too (`no witness line, the builds run it: L1 1 (door3): written`), and one no build ran, whose text
does not say so yet ("Known only from the code", "no recording runs it", ...), its
`> Known only from the code: no recording runs it.` (printed as
`N code entries no build ran: "Known only ..." written: 65 $69AC JpFrameBox, ...`); that exact line, the kit's, becomes the witness line when a
build runs the entry later (`... the builds run it now: L1 1710 (...): written in its place`), a writer's own text is
left alone. Without `--fix-witness` a run prints `N code entries with no witness line (--fix-witness writes them)`
and `N code entries with no witness line that no build ran and no text says so (--fix-witness writes "Known only
...")`, only for an `.ann` that already holds witness lines; and writes the source again from the rewritten `.ann`, so
that with `--install` one run leaves the `.ann` and the `.asm` current
([ann-format.md 3.2](../docs/ann-format.md#32-a-description--text)). One L1 keeps one instruction an address (the
last bytes run there, the runs of all): mkgame prints the witnessed entries whose bytes changed in the recording, and
frame windows of it (`kit/rs.py build --from-frame F --to-frame G --into work/stage1/c1/load`, given as
`witness_builds`, the whole recording as `witness_skip`) keep two programs at one address apart (Myth's loader
pieces, its resident over the SpeedLock chain, its front under stage 1).

The summary line counts the entries of the control file mkgame writes, and says where they are not the `.ann`'s:
`entries 240 (233 from the .ann, 7 where code and data meet, a CALL lands or a recording enters: $8A12 ...)`. A
routine root that only a snapshot-started recording marks (its L1 `kinds` `root`, or a jump only from inside the
root's own routine: the loop of the routine the snapshot was taken in, cut in two) makes no entry where the code
before it falls into it; the `.ann` or a CALL still makes one there (Deflektor: `$842C`, `$890A`, `$890C`, `$AD80`,
`$ADE8`, 238 entries before, 233 now).

`--install` writes the modules, `game.asm` and the resources (through the json's `res_install`, else `case.json`'s,
else the case's `tools/res_formats.py`; a part with resources and none of these prints `WARNING: N resources not
installed`), and deletes only the modules the old `game.asm`
included that the `.ann` no longer has (a hand-written `.asm` beside them stays) and a resource's `src/res/NAME.bin`
left by an earlier install when the case's `res_formats.py` now writes its editable form (`NAME.png`, `NAME.txt`)
and not the bytes; a hook that returns `{resource: the file it wrote}` also gets the `NAME.bin` beside a file of
another name deleted (the `.bin` files a group's editable file replaces, in the hook's own folder: Rick Dangerous 2's
`tunes/patterns.txt`). `@res` names are the case's: a name another part also gives, its resources installed the same
way (one hook, one `res` folder), is printed at parse time (`WARNING: @res NAME is also named in ...`): the later
install would replace the earlier one. Each run also removes from its work folder (`work/mkgame`, a part's `work/...`, and its `top`
subfolder) the `.asm`, `.ctl`, `.skool` and `-image.bin` files an older run wrote and this one no longer does (a module
or an entry renamed: `removed work/stage2/mkmusic/code.asm (an older run's: this one no longer writes it)`).

What `mkgame.py` writes as a name and what it keeps a number:
[ann-format.md 3.4](../docs/ann-format.md#34-what-becomes-labeloffset). A port (`LD BC,nn` before `IN` / `OUT (C)`)
stays a number against a label, an `@equ` range and `Label+offset`, and mkgame prints the name it did not use:
`port: $7178 LD BC,$FEFE feeds IN / OUT (C): kept a number, not Im2Table+254`. An `@isub` stays as written even where
its number is a label's address, and a decimal number in it stays decimal (`LD DE,-10000`, not `-$2710`); a `w`
entry's labelled words inside an `@res` become `ASSERT` lines after its `INCBIN`s. A resource whose bytes hold
addresses can be assembled from source instead: `@res NAME.bin include` writes `INCLUDE "res/NAME.inc"`, and the
case's `res_formats.py build` writes that file from the editable form with `resinc.py` (`lines()`: `DB` lines, a
`DW Label` per address, inner labels; `symbols(case)`: the `.ann`'s names by address, name and resource offset), so a
text edit takes effect and a label that moves is followed (SimCity's menus). Several entries one after the other
may share one `.inc` (`@res NAME.bin include` on each): one `INCLUDE` at the first, the later entries' names and the
inner labels as labels inside, so the editable form may assemble to another size and the labels after it follow (ZYX
boot's tune, eight entries in `disco.inc`). `@variant NAME` puts an instruction under a name (inserted, or replacing
the instructions of a range), emitted as an `IFDEF NAME` block that a build selects with `sjasmplus -DNAME`; the
original stays the `ELSE` side, so the plain build is unchanged (ZYX boot's variants: `-DKempston`,
[ann-format.md 2](../docs/ann-format.md#2-directives)). A module named again further on
(`@module tasks` before the IM 2 handler and again before its vector table far above) is one file of several
stretches: the second starts with `ORG` at its address ([ann-format.md 2](../docs/ann-format.md#2-directives)).
Several part files may share one `.ann`: each keeps the entries inside its image, and a module wholly outside is
skipped with a note. A 128K game's `@bank` lines take their names from the banks' `.ann` files:
`@names 3 ../bank3/bank3.ann`, then `@bank $CA8B 3` ([ann-format.md 5.1](../docs/ann-format.md#51-the-part-directives)).

What `refdocs.py` writes, beside the names, titles and descriptions of the `.ann`:

- **Memory ranges** (doc 12, Reads / Writes) name the label at or below their first byte, inner labels included, as
  `Label+offset` (`$77D6` is `TrainOut`, not the record `TrainCell` that holds it); a range inside one entry then
  names the inner labels it covers, a longer one the entries it runs into. A range outside the image that is not
  the screen (below the game's image, once "(system)"; outside a part's image, once its numbers) is named by the
  `.ann`'s `@equ` lines: the one that holds its first byte (`NAME+offset`), then those that start inside it (Myth's
  stages: `$5D2E`-`$6AFA` is `PlayBuffer+558`, from `@equ $5B00 PlayBuffer 4415`; an `@equ ... at` names no
  range). With none, "(system)" or the numbers stay.
- **Block moves** (`ref_skip_moves`, doc 11 only): the bytes a routine copies or loads in a loop are moved, not
  used, so they make it no reader or writer of the entries there. Where two programs ran at one address in one
  recording (Myth's resident over the SpeedLock chain, whose in-place decryption L1 booked to the resident's
  routines), give the part a frame window of the recording as its `ref_builds` (`stage1/c1/run`): cutting the moves
  out of a shared L1 routine also cuts the later program's own accesses to those bytes.
- **The interrupt's acceptance** is the handler's. L1 books the IM 2 vector read and the return address the interrupt
  pushes to the instruction it interrupted; refdocs takes them from that routine and gives them to the handler (the
  callee of L1's `interrupt` edge): the read of a word holding the handler's address in the page the most interrupted
  routines read it in (the I page), or of a word pair at least half the routines an IM 2 interrupt entered read
  (without the image, a scratch case's; or a table the game fills at run time, Terramex's `$8EFF-$8F00`, whose
  image words are not the handler's address: with the image only a pair at `$xxFF`, the idle bus's `$FF`, so a
  variable some interrupted routines share stays theirs), and the writes of the interrupted routine to the stack's
  slots (L1 `byte_use`: pushed and popped, never
  run). The handler says "Entered by: the interrupt, N times in M routines" instead of a "Called from" list,
  and no routine "Calls" it.
- **Callers and callees** are the entries that hold the call's site (L1's `sites`), not the L1 routine's entry: an
  L1 routine runs on through the entries its code falls into and jumps to (Terramex's GameEntry, NewGame, ...
  MainLoop is one), so its entry would be named for a call MainLoop makes. A tail jump is marked "(tail)", running
  on into the next entry "(falls into)". An entry no L1 routine of a recording starts at (entered by a jump, a table
  jump or by running on; or an L1 "indirect" routine with no entries counted) gets the runs of its first instruction,
  as its witness line counts them: "Runs (c1: ...): 51 runs of its first instruction (entered by a jump or by running
  on, no routine of its own in the L1)", and in the other recordings "727 runs of its first instruction, entered by a
  jump (...)"; doc 12's header then says so (only then: a case without such an entry keeps its header). An entry
  known only by a call site in it, with no run of its first instruction, says "Runs: ran within another entry's
  routine ..., no runs of its own counted".
- **All the recordings.** Docs 11 and 12 read every recording of `case.json`: the `ref_builds` first, then
  `read_builds`, `code_builds` and `witness_builds` (a part: its `l1` sources and its `witness_builds`). Their runs,
  callers, callees and ports count, their reads and writes only from `ref_builds` and `read_builds` (a `code_builds`
  recording's reads may be a depacker's input; a `witness_builds` one counts as `code_builds`). A per-build
  `overwritten` range (`[LO, HI, BUILDS]`) is left out of that build's routines, and a per-build `same_bytes` counts
  its routines only where their first instruction has the image's bytes. A routine no
  `ref_builds` recording reached says "not reached in `c1`; in the other recordings 648 calls (`rec/growth` 600,
  ...)", one it reached gets a row "Runs (the other recordings)" beside its `ref_builds` rows; "not reached in the
  recordings" only when none ran it.
- **The parts.** `case.json` `ref_parts` adds a section a part after the game's (`## Bank 3 (`src/bank3`)`), each
  from the part's `.ann`, image and recordings (only the instructions inside the part's window, and for a
  `"mode": "blocks"` part only those whose bytes are the part's); a call into the game's pages names the game's
  routine, a bank's address its bank. A part of segments gets a section a segment with an `.ann` (`## Title: the
  tape loader`), at its run addresses, from the segment's own work files (`<ann>[-<piece>][-<RUN>].ctl`, `.skool`,
  `-image.bin`: mkgame adds the run address when two segments share an `.ann` and piece) and its `l1` sources.
- **The load.** A recording that loads the game runs the loader's code at addresses the game takes later, and L1
  keeps one routine an entry address: the loader's block writes would be the game entry's there. `case.json`
  `ref_load_end` `{build: frame}` leaves the writes of that recording's routines first run before the frame out of
  "Written by" (doc 11) and the Writes rows (doc 12). A routine that ran in the load and again in play loses that
  recording's writes; the other recordings still give them.
- **Doc 11** gives each inner label of a data entry (a field, a row) a row of its own under the entry, `Name`
  (`Entry`+k), its size up to the next label; the entry's row then gives its own bytes, up to its first inner label,
  of the whole entry's (`JumpFrames` 17 of 34, `JumpRise` the other 17), its comment, its readers and writers. The readers and writers are the
  `ref_builds`' routines, then those only another recording saw, with the first such build in brackets
  (`` `DrawCell` (`stage2/rzx04/cap`) ``), then, marked "(code)", the routines whose `LD r,(nn)` / `LD (nn),r`, or an
  access through `(HL)` / `(DE)` / `(BC)` after `LD HL,nn` (`DE`, `BC`) in the same block (no jump target, branch or
  call between, the pair changed only by `INC` / `DEC`: `LD HL,ExitOpen`, `LD (HL),$FF`), names the bytes in
  `game.skool` where no recording saw them do so. A "(code)" routine is named by the label at or below the
  instruction: `WalkIntoFire`, the label inside `UpSpecialCell` that the write belongs to; it is left out when a
  recording already names the routine it lies in.
- **Animations**: every `docs/img/routines/<Label>.gif` and `<Label>-<what>.gif`. A second document's animation of a
  routine another already shows gets its own `<Label>-<what>.gif` (SimCity's `SimTask-growth.gif` beside
  `SimTask.gif`); `routine_anim.py` and `memanim.py` print a note when they write over an existing GIF.

## The signature base

Known pieces (players, packers, protections, loaders, the cases' modules) in `signatures/`; the format is
[docs/signature-format.md](../docs/signature-format.md).

| Script | Does |
| --- | --- |
| `sig_scan.py IMAGE --base ADDR [--ann]` | names the known pieces in an image: exact, masked (with the base shift, the external addresses it uses, where a moved copy runs) or a candidate; runs the format detectors (PT2, PT3 modules); `--ann` prints the hits as `.ann` lines |
| `sig_add.py ann --case C ...` | one entry per module of a finished case, from `case.json`, the `.ann` and the build's listing |
| `sig_add.py lst --lst L --start A --end B ...` | one entry from a sjasmplus listing, label to label |
| `sig_add.py sources` | every addition in `signatures/sources.json`, in order: the whole base from the cases' builds |
| `sig_index.py [--check]` | checks every entry, writes `signatures/index.json` and `INDEX.md` |
| `siglib.py` | their shared code: masks, anchors, the match, the listing reader |

A new case starts with a scan of its images; when it is finished it adds its modules and the third-party pieces it
identified to `signatures/sources.json`.

## Figures

GUIDE.md 4 says which figure goes where. All share one palette (`kitlib.py`): executed green, read blue, written
yellow fading through red, trails dark.

| Script | Draws | From |
| --- | --- | --- |
| `routine_anim.py` | a routine at work: memory map lit by age, the screen or buffer it draws into, the listing window, the registers; the GIF records its command (`--title` in full; `routine_anim.py --command GIF` prints it; memanim and screen_anim too), check_docs compares captions with it and flags two captions writing one file | an access trace |
| `writers_map.py` | code vs screen: each byte of the screen or a buffer coloured by the routine (or instruction) that wrote it, the data it read, a zoom | an access trace |
| `beam_timeline.py` | code vs the beam: the routines along a frame's T-states (frame T, the INT marked), every screen write against the raster | an access trace |
| `memanim.py` | memory over a longer stretch (a load, an unpack, a level set-up) | `memory_at` samples |
| `screen_anim.py` | the screen over frames; `--scale N` (2: 512 px) or `--width W` (1050: the figure width, the largest whole scale resized to W, one palette, `kitlib.save_gif`) | `memory_at` samples |
| `screen_shot.py` | the screen at named moments | `memory_at` |
| `merge_l1.py OUT.json L1 ... [--stack LO-HI]` | several L1 builds summed into one for `heatmap.py` (pages 5, 2, 0; the frames summed); `--stack` prints each build's lowest SP in that range (the lowest byte a `PUSH`, `CALL`, `RST` or an interrupt wrote: the L1's `byte_use` stack-write flag; Rex `5C00-6017`: `$5FE2` to `$5FDA` over the object records) and its lowest data write (the low mark where the stack is also written as data, `LD SP` over a buffer: Switchblade `5B00-5BFF`, Myth `FF00-FFFF`); give play windows, a load's stack counts too | `l1.json` |
| `heatmap.py` | executed / read / written per byte over a build; `--panels` (any of `executed,read,written,composite`), `--columns` (2), `--regions` (a file of `START END NAME` lines, or inline `START-END:NAME,...`), TrueType text that reads at 900 px | `l1.json` |
| `fig_budget.py` | where the CPU time goes: each routine's (or module's) own T-states as a share of all the frames, coloured by module; several `.ann` parts (page, range), HALT and the ROM apart, a panel per state; the L1 may be a trace window instead (`FILE.uatr` or `W@F:T-F:T`: one pass's per-routine T-states from the trace's instruction times, cached in W/traces), OUT `-` prints the table only | `l1.json` or an access trace |
| `zxscreen.py` | a 6912-byte screen or a 64 K image to PNG | a file |

The access trace is unreal-ng's `analysis trace` (docs/emulator/analysis/analysis-layers.md, "Access trace"): one
replay of a window of a recording, every instruction with its registers and every bus cycle after it. The three
trace scripts take it as a file (`--trace`) or trace it themselves from the instance that holds the recording:

```bash
python3 kit/routine_anim.py --work $C/work/p2 --window 1001:5336-1001:45336 --listing $C/build/game.lst \
    --view buffer:8000:128x128:columns-up --pc EAE3-EBA9 --range 8000-FFFF \
    --out $C/docs/img/routines/DrawSprites.gif
```

A buffer view is `buffer:ADDR:WxH` (W bytes across, H lines) with its storage order: `:rows` (the default, a
linear bitmap), `:columns` (column by column, H bytes a column, top first), `:columns-up` (the same, bottom first:
the H.A.T.E. playfield's strips), `:screen` (whole thirds laid out like the screen's pixel lines, W 32: a
back buffer), `:hex` (a stack or a record as numbers: H lines of W bytes in hex, each line headed by its address) and
`:words` (the same as 16-bit words, W / 2 a line: pushed return addresses read as `$F75F`, not as bits). A byte
written in the picture is drawn in the write colours, one read in blue; in `:hex` and `:words`, a number written
earlier in the window keeps a dim rose trail after its fade (one only read, a dim blue one), as the memory map keeps
its trails. The GIFs share one palette and store each picture as its changes, so a routine
animation of 90 pictures stays near 1 MB (`kitlib.save_gif`: the unchanged pixels are the transparent index 255,
which no colour is ever quantized to; it was black once, and showed the page through every pure black pixel).

`--pc LO-HI` is the routine's code, the rest counts as "other"; several ranges (`--pc EAE3-EBA9,EC40-EC9F`, or
`--pc` repeated) follow a routine and the routines it calls elsewhere in memory.

128K pages (`routine_anim.py`, `beam_timeline.py`): `--page N=LISTING` names the code at `$C000-$FFFF` that runs
while RAM N is paged in from that page's listing (`UpdateChannel (RAM 6)`; routine_anim shows that listing's lines),
`--page-name N=NAME` gives the page one name (`the music player (RAM 6)`), `--listing` names the rest. Both for one
page combine: the listing names the code (routine_anim shows its lines) and NAME stands for `RAM N` after each name
(`--page 4=build/bank4.lst --page-name '4=bank 4: the AY player'` gives `WriteAy (bank 4: the AY player)`). The page is
the trace's start page, then each `OUT` to `$7FFD`. With either option a plain `--pc` range at `$C000-$FFFF` is RAM
0's and `--pc N:LO-HI` is RAM N's: `--listing build/game.lst --page 6=build/music.lst --pc 6:C000-CD60` follows
Terramex's music player in RAM 6 while the game's code at the same addresses counts as "other".

`writers_map.py --sources` names a source range by the nearest label or EQU name of the listing at or below it
(`Listing.data_name`): a variable past the image that the `.ann` gives with `@equ` is named by it (Deflektor's
DrawMarks `$E300-$E359`, not SpareCellColours+812, the image's last label plus an offset); `@bank` EQUs are left
out. A code address is still named by the nearest label (`Listing.name`, `routine`).

Several listings of one flat image (`routine_anim.py`, `beam_timeline.py`, `writers_map.py`): `--listing` given more
than once merges them by address, each naming its own code (where two give code at one address, the first wins):
`--listing build/main.lst --listing build/music.lst` names a 48K boot's menu and its music part at `$C000` (ZYX boot);
`--page` is for 128K pages only.

Loop names (`routine_anim.py`, `beam_timeline.py`, `writers_map.py`): `--label ADDR=NAME` (comma-separated or
repeated, hex) names the code at ADDR (the listing's label there renamed, or one added), and `--auto-labels owner`
names each of SkoolKit's `l_XXXX` labels (a branch target the `.ann` leaves unnamed) after the nearest named label
before it: R-Type's beam timeline gives ScrollRows' three loops as `ScrollRows_8846`, `ScrollRows_8881`,
`ScrollRows_88B3` from `build/game.lst` itself, the same PNG byte for byte as the `sed` copy of the listing it used
before. A name the source should keep goes into the `.ann` as an inner label (ann-format 3.3).

routine_anim's memory map is 256 bytes a row; a range too small to make 96 px that way (two rows of 2 px for
`$5B00-$5CFF`) is wrapped at 128, 64, 32 or 16 bytes a row, at a scale as many times larger, the label says how
many. `--row-bytes N` fixes the count, `--grid-height` caps the map's height (512; the listing beside it as tall).

`--window F:T-F:T` is in TTD units, as `time_travel` gives them; the trace is kept in `W/traces/` and read from
there the next time.

The animations and the budget are 1050 px wide by default, so that they stay readable shown at 900 px (AGENTS.md, the
figure check). `routine_anim.py` draws `--width` pixels (1050):
the memory map above the view on the left, each at the largest whole scale that fits, the listing on the right, a long
`--title` on two lines; a view wider than the left column at 1 x (a `:hex` view of 30 bytes a line) goes on a row of
its own under the map and the listing, its numbers a point or two smaller (down to 9) when even that row is too
narrow, so the picture stays `--width` wide; `--layout wide` is the older picture with the three panels side by side (up to 2566 px).
`memanim.py --screen` puts the screen under the grid when beside it the picture would pass `--width` (1050); with
`--layout wide` it stays beside the grid, at 1 x when 2 x would pass `--width`. `fig_budget.py` draws `--width` pixels
(1050) and wraps a long `--note`. `writers_map.py` keeps within `--width` (1050): the two views side by side at
`--scale` (2; two screens fit with narrower gaps) or the largest whole scale that fits, else stacked, the `--zoom`
insets on a row of their own enlarged as far as it allows. `beam_timeline.py` draws `--width` pixels (1050), the time
axis taking what the labels leave; no tick label is drawn within 60 px before the axis title "frame T" (the 70000 of a
128K or Pentagon frame); `--frames N` draws the trace's first N frames, `--frames A-B` its frames A to B (a window
from the middle of a long trace, no cut by hand). `heatmap.py` sets its text in the kit's TrueType font, 13 px up
to 1050 px wide and larger in proportion beyond (about 11 px or more shown at 900 px): its four panels are two rows
of two (`--columns`), `--panels composite` draws the composite alone, region labels that would overlap are pushed
apart and joined to their bracket by a leader. Both wrap a long `--title`. `writers_map.py --width 0` is its older one-row
picture (the zoom up to 2620 px), `memanim.py --layout wide --width 0` its older 1102 px one. `memanim.py --cell` is
the pixels a byte (2, too small to read at 900 px): for an address range of up to 64 pages (16 K) take `--cell 3`, the
compact picture is 830 px wide; `--cell fit` makes the grid as wide as `--width` allows (988 px at 1050, a byte 3 or 4
px; `--cell 4` would be 1086 px), a fraction (`--cell 3.5`) that size. A small range is wrapped at fewer bytes a row
(at least 96 px tall, `--row-bytes` fixes it), and its text is in the kit's font, as the other figures'.
`writers_map.py --sources` gives each source range its length, both ends included (`$86D0-$8718`
`(ItemSprites+720, 73 bytes)`: a 72-byte item and the byte after it, which the last row's outline reads). `fig_budget.py`,
`beam_timeline.py` and `writers_map.py` colour from 28 distinct colours (`kitlib.ROUTINE_COLOURS`), so up to 28
modules or routines repeat none; `fig_budget.py --colour MODULE=#RRGGBB` (repeatable) picks a module's colour.
