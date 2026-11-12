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
`$RS` of the docs is that script.

The annotation file these scripts read is described in [docs/ann-format.md](../docs/ann-format.md) (every directive,
what the generator does with it, the part files); every file of a case and the command that makes it in
[docs/case-files.md](../docs/case-files.md).

## A case

| Script | Does |
| --- | --- |
| `case-template/` | the skeleton of a new case: README, WALKTHROUGH sections, the twelve documents with their figure lists, `case.json`, `src/game/game.ann`, `src/res/README.md`, `tools/build.sh`, a bytes-only `tools/res_formats.py` |
| `tapblocks.py list FILE.tap` | the blocks of a tape: lengths, header fields, the play time at ROM speed, checksums |
| `tapblocks.py FILE.tap N OUT` | one block's data |
| `tap.py` | writes a tape of standard ROM blocks (the build's last step); a `basic` header's program length is the program without its variables, found as SAVE writes it (or given: `basic:NAME:LINE:FILE:LENGTH`) |
| `mkgame.py --case C` | `src/game/*.asm` from `game.ann` (`src/main`, `main.ann` in a case whose `case.json` names `"main": "main"`) ([format](../docs/ann-format.md)), the recordings' `l1.json` and the image `case.json` names; refuses to install unless sjasmplus gives the image's bytes |
| `mkgame.py --part F.json` / `--image BIN --org A ...` | any other code image the same way: a loader, a menu, a bank, an image of several segments or pieces ([part files](../docs/ann-format.md#5-parts-banks-and-pieces)) |
| `resinc.py` (a module) | the `.inc` of an `@res NAME.bin include` resource: `lines(items)` writes `DB` / `DW` / label lines (a word may be a label's name), `symbols(case)` gives the `.ann`'s names and each resource's inner labels by offset; `Symbols(case).add(ann, lo, hi)` writes and reads an address of an editable form as a name (`word($CCDA)` is `SharedModels+591`, `value()` the address again); the case's `res_formats.py build` calls it |
| `ctl2ann.py DRAFT.ctl --out F.ann` | a first `.ann` from `re_session.py`'s `draft.ctl` (or an L2 export JSON) |
| `toolpaths.py` | finds sjasmplus, the SkoolKit venv, unreal-ng and its `re_session.py` (above) |
| `rs.py ARGS` | runs unreal-ng's `re_session.py` with ARGS (`open`, `build`, `stop`, ...; above) |
| `ann_names.py --case C ADDR=Name ...` | names labels inside entries of `game.ann` |
| `input_vars.py --work W --inputs S --start F` | the bytes that follow the held directions and fire over a scripted recording: a first guess at the player's coordinates (a 16-bit coordinate, or one that moves only now and then, scores low: confirm in the code that reads the controls) |
| `refdocs.py --case C` | docs 11 and 12 from `game.ann`, the parts of `ref_parts` and the recordings (below); doc 12 links `docs/img/routines/<Label>.gif` and every `<Label>-<what>.gif` |
| `check_docs.py --case C` | mermaid renders (every diagram in one `mmdc` run: one headless browser, not one a diagram; each on its own only when that run fails, to name the broken one), links and `#anchors` resolve (GitHub slugs), no `$` in prose, every figure in `docs/img` and its subfolders is linked; the resource READMEs (`src/res/README.md`, `src/res/**/README.md`) are read for their links too: a figure they link counts, a broken link of theirs is a problem |
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
| `code_builds` | the `work/<build>` whose instructions count but not the reads (over a depacker's input), optional |
| `dest`, `work`, `res_install`, `operands`, `no_entries`, ... | any key of a part file ([ann-format.md 5.2](../docs/ann-format.md#52-part-files)), optional |
| `ref_builds` | `[key, text]` of the builds docs 11 and 12 report first (each its own Runs row); the other recordings count after them |
| `witness_skip` | builds of `read_builds` / `code_builds` left out of the `.ann`'s witness counts, optional |
| `witness_builds` | recordings that count in the witness lines only (a fuel failure, an armour test), optional |
| `witness_names` | `{build: name}` for a witness list: a windowed copy of a recording under its recording's name (Battle Command `{"stage1/c1g": "c1"}`), optional |
| `ref_parts` | part files (`"src/bank3/bank3.json"` or `[path, title]`) docs 11 and 12 cover after the game, a section each (a part of segments a section a segment with an `.ann`, "Title: segment title"), optional; a part file's `ref_builds` (else the case's) are its first builds, its other `l1` sources the others (`other_builds` overrides them; `[]` for none) |
| `ref_load_end` | `{build: frame}`: the frame from which a recording that loads the game (`stage1/c1`) runs the game's image; its routines first run before it (a loader at the game's addresses) write no entry's "Written by" (Switchblade: the tape loader at `$FF00`, whose block writes fell to DrawMeter `$FF7C`), optional |
| `overlay` | a buffer laid over code once play starts (`lo`, `hi`, `name`, `why`), optional |
| `header`, `data_note` | the first comment lines of `game.asm`; a sentence for doc 11, optional |

Every run checks the `.ann`'s `Witness: L1 N (builds)` lines of the code entries against the recordings: N the runs
of the entry's first instruction summed over `ref_builds`, `read_builds`, `code_builds` and `witness_builds` (less
`witness_skip`; a `ref_builds` recording with a window counts only inside it), the list the builds that ran it (`c1,
hiscore, rzx x29`; numbered builds of one family by name, a run of three or more as a range: `c1-c4`, `c1, c2, c4`,
a family that would take more than four items as one, `rzx x29`), and prints each stale line
(`witness: src/game/game.ann:134 $8040 PrintGlyph: L1 90100 (c1, rzx x32), the builds give L1 90104 (...)`);
`--fix-witness` rewrites them in the `.ann`, keeps a line that names a recording it did not load, prints each
name it drops (`menu, search ran no instruction there`; an entry no build ran stays `L1 0 ()` with no such
clause, so a data entry is not said to run no instruction), and writes the source again from the rewritten `.ann`, so
that with `--install` one run leaves the `.ann` and the `.asm` current
([ann-format.md 3.2](../docs/ann-format.md#32-a-description--text)).

`--install` writes the modules, `game.asm` and the resources (through the json's `res_install`, else `case.json`'s,
else the case's `tools/res_formats.py`; a part with resources and none of these prints `WARNING: N resources not
installed`), and deletes only the modules the old `game.asm`
included that the `.ann` no longer has (a hand-written `.asm` beside them stays) and a resource's `src/res/NAME.bin`
left by an earlier install when the case's `res_formats.py` now writes its editable form (`NAME.png`, `NAME.txt`)
and not the bytes. Each run also removes from its work folder (`work/mkgame`, a part's `work/...`, and its `top`
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
  names the inner labels it covers, a longer one the entries it runs into.
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
  on into the next entry "(falls into)". An entry known only by a call site in it (reached by a jump or by running
  on, never an L1 routine of its own) says "Runs: ran within another entry's routine ..., no runs of its own
  counted".
- **All the recordings.** Docs 11 and 12 read every recording of `case.json`: the `ref_builds` first, then
  `read_builds` and `code_builds`. Their runs, callers, callees and ports count, their reads and writes only from
  `ref_builds` and `read_builds` (a `code_builds` recording's reads may be a depacker's input). A routine no
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
| `routine_anim.py` | a routine at work: memory map lit by age, the screen or buffer it draws into, the listing window, the registers | an access trace |
| `writers_map.py` | code vs screen: each byte of the screen or a buffer coloured by the routine (or instruction) that wrote it, the data it read, a zoom | an access trace |
| `beam_timeline.py` | code vs the beam: the routines along a frame's T-states (frame T, the INT marked), every screen write against the raster | an access trace |
| `memanim.py` | memory over a longer stretch (a load, an unpack, a level set-up) | `memory_at` samples |
| `screen_anim.py` | the screen over frames | `memory_at` samples |
| `screen_shot.py` | the screen at named moments | `memory_at` |
| `heatmap.py` | executed / read / written per byte over a build; `--panels` (any of `executed,read,written,composite`), `--columns` (2), TrueType text that reads at 900 px | `l1.json` |
| `fig_budget.py` | where the CPU time goes: each routine's (or module's) own T-states as a share of all the frames, coloured by module; several `.ann` parts (page, range), HALT and the ROM apart, a panel per state | `l1.json` |
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

Several listings of one flat image (`routine_anim.py`, `beam_timeline.py`, `writers_map.py`): `--listing` given more
than once merges them by address, each naming its own code (where two give code at one address, the first wins):
`--listing build/main.lst --listing build/music.lst` names a 48K boot's menu and its music part at `$C000` (ZYX boot);
`--page` is for 128K pages only.

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
